-- FS25_NoDriveByFill
-- Version 1.0.2.0

-- Blocks FillTrigger/proximity filling for player-controlled:
-- - sowing machines / planters with SEEDS
-- - fertilizer spreaders with FERTILIZER
-- - lime spreaders with LIME

-- Physical filling through normal discharge into a fill unit is not blocked.
-- Liquid fill types are not affected.

-- v1.0.2.0:
-- - hides the proximity refill activatable ("R") for blocked dry fill types
-- - prevents automatic cover opening caused by blocked fill triggers
-- - keeps manual cover control intact

NoDriveByFill = {}

NoDriveByFill.MOD_NAME = g_currentModName or "FS25_NoDriveByFill"
NoDriveByFill.SPEC_NAME = string.format("spec_%s.noDriveByFill", NoDriveByFill.MOD_NAME)

function NoDriveByFill.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
        and (
            SpecializationUtil.hasSpecialization(SowingMachine, specializations)
            or SpecializationUtil.hasSpecialization(Sprayer, specializations)
        )
end

function NoDriveByFill.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(
        vehicleType,
        "getAllowLoadTriggerActivation",
        NoDriveByFill.getAllowLoadTriggerActivation
    )

    SpecializationUtil.registerOverwrittenFunction(
        vehicleType,
        "setFillUnitIsFilling",
        NoDriveByFill.setFillUnitIsFilling
    )

    SpecializationUtil.registerOverwrittenFunction(
        vehicleType,
        "updateFillUnitTriggers",
        NoDriveByFill.updateFillUnitTriggers
    )

    -- registerOverwrittenFunction() simply does nothing if the vehicle type
    -- does not have this function, so this is safe for machines without Cover.
    SpecializationUtil.registerOverwrittenFunction(
        vehicleType,
        "setCoverState",
        NoDriveByFill.setCoverState
    )
end

function NoDriveByFill.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", NoDriveByFill)
end

function NoDriveByFill:onLoad(savegame)
    local spec = self[NoDriveByFill.SPEC_NAME]

    if spec ~= nil then
        spec.lastBlockedTrigger = nil
        spec.fillActivatableSuppressed = false
    end
end

function NoDriveByFill.isPlayerControlled(vehicle)
    if vehicle == nil or g_localPlayer == nil then
        return false
    end

    local rootVehicle = vehicle.rootVehicle

    if rootVehicle == nil and vehicle.getRootVehicle ~= nil then
        rootVehicle = vehicle:getRootVehicle()
    end

    if rootVehicle == nil then
        return false
    end

    local currentVehicle = g_localPlayer:getCurrentVehicle()

    if currentVehicle == nil or rootVehicle ~= currentVehicle then
        return false
    end

    -- Do not interfere with an AI worker.
    if rootVehicle.getIsAIActive ~= nil and rootVehicle:getIsAIActive() then
        return false
    end

    return true
end

function NoDriveByFill.isBlockedFillType(fillTypeIndex)
    if fillTypeIndex == nil then
        return false
    end

    return fillTypeIndex == FillType.SEEDS
        or fillTypeIndex == FillType.FERTILIZER
        or fillTypeIndex == FillType.LIME
end

-- Returns the trigger which FillUnit currently treats as the preferred one.
-- triggers[1] is deliberately checked first: updateFillUnitTriggers() sorts
-- the list and raises onFillUnitTriggerChanged BEFORE assigning selectedTrigger,
-- so selectedTrigger may briefly still point at the previous source.
function NoDriveByFill.getSelectedTrigger(vehicle)
    local fillUnitSpec = vehicle ~= nil and vehicle.spec_fillUnit or nil

    if fillUnitSpec == nil or fillUnitSpec.fillTrigger == nil then
        return nil
    end

    local fillTrigger = fillUnitSpec.fillTrigger

    if fillTrigger.triggers ~= nil and #fillTrigger.triggers > 0 then
        return fillTrigger.triggers[1]
    end

    if fillTrigger.selectedTrigger ~= nil then
        return fillTrigger.selectedTrigger
    end

    if fillTrigger.currentTrigger ~= nil then
        return fillTrigger.currentTrigger
    end

    return nil
end

function NoDriveByFill.getSelectedTriggerFillType(vehicle)
    local trigger = NoDriveByFill.getSelectedTrigger(vehicle)

    if trigger ~= nil and trigger.getCurrentFillType ~= nil then
        return trigger:getCurrentFillType(), trigger
    end

    return nil, trigger
end

function NoDriveByFill.shouldBlockTriggerFill(vehicle)
    if not NoDriveByFill.isPlayerControlled(vehicle) then
        return false, nil, nil
    end

    local fillTypeIndex, trigger = NoDriveByFill.getSelectedTriggerFillType(vehicle)

    if NoDriveByFill.isBlockedFillType(fillTypeIndex) then
        return true, fillTypeIndex, trigger
    end

    return false, fillTypeIndex, trigger
end

-- Keep the base permission check blocked as a first line of defence.
function NoDriveByFill:getAllowLoadTriggerActivation(superFunc, rootVehicle)
    local block = NoDriveByFill.shouldBlockTriggerFill(self)

    if block then
        return false
    end

    return superFunc(self, rootVehicle)
end

-- Main filling guard.
function NoDriveByFill:setFillUnitIsFilling(superFunc, isFilling, noEventSend)
    if isFilling then
        local block, fillTypeIndex, trigger = NoDriveByFill.shouldBlockTriggerFill(self)

        if block then
            local spec = self[NoDriveByFill.SPEC_NAME]

            if spec ~= nil and spec.lastBlockedTrigger ~= trigger then
                spec.lastBlockedTrigger = trigger

                local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
                local fillTypeName = fillType ~= nil and fillType.name or tostring(fillTypeIndex)

                Logging.info(
                    "[%s] Blocked proximity filling: vehicle='%s', fillType='%s'",
                    NoDriveByFill.MOD_NAME,
                    self:getName(),
                    fillTypeName
                )
            end

            return
        end
    else
        local spec = self[NoDriveByFill.SPEC_NAME]

        if spec ~= nil then
            spec.lastBlockedTrigger = nil
        end
    end

    return superFunc(self, isFilling, noEventSend)
end

-- Hide the normal "R - refill" activatable while the preferred trigger
-- contains one of our blocked dry fill types.
--
-- FillUnit itself adds its FillActivatable to activatableObjectsSystem when
-- the first fill trigger appears and removes it when the last one disappears.
-- We temporarily do the same in between, remembering our own suppression state
-- so an allowed trigger can restore the action.
function NoDriveByFill:updateFillUnitTriggers(superFunc)
    superFunc(self)

    local modSpec = self[NoDriveByFill.SPEC_NAME]
    local fillUnitSpec = self.spec_fillUnit

    if modSpec == nil
        or fillUnitSpec == nil
        or fillUnitSpec.fillTrigger == nil
        or g_currentMission == nil
        or g_currentMission.activatableObjectsSystem == nil then
        return
    end

    local fillTrigger = fillUnitSpec.fillTrigger
    local hasTriggers = fillTrigger.triggers ~= nil and #fillTrigger.triggers > 0
    local block = hasTriggers and NoDriveByFill.shouldBlockTriggerFill(self)

    if block then
        if not modSpec.fillActivatableSuppressed then
            g_currentMission.activatableObjectsSystem:removeActivatable(
                fillTrigger.activatable
            )

            modSpec.fillActivatableSuppressed = true
        end
    elseif modSpec.fillActivatableSuppressed then
        -- If triggers are still present, FillUnit itself will not re-add the
        -- activatable because it only does that when the first trigger arrives.
        if hasTriggers then
            g_currentMission.activatableObjectsSystem:addActivatable(
                fillTrigger.activatable
            )
        end

        modSpec.fillActivatableSuppressed = false
    end
end

-- Cover:autoReactToTrigger opens a cover by calling setCoverState(..., true).
-- Block only that automatic opening while a blocked dry FillTrigger is the
-- current source. Manual cover operation calls setCoverState without
-- noEventSend=true, so the player remains fully in control.
function NoDriveByFill:setCoverState(superFunc, state, noEventSend)
    if noEventSend == true and state ~= nil and state > 0 then
        local block = NoDriveByFill.shouldBlockTriggerFill(self)

        if block then
            return
        end
    end

    return superFunc(self, state, noEventSend)
end
