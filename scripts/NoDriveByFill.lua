-- FS25_NoDriveByFill
-- Version 1.0.1.0
--
-- Blocks FillTrigger/proximity filling for player-controlled:
-- - sowing machines / planters with SEEDS
-- - fertilizer spreaders with FERTILIZER
-- - lime spreaders with LIME
--
-- Physical filling through normal discharge into a fill unit is not blocked.
-- Liquid fill types are not affected.

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
end

function NoDriveByFill.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", NoDriveByFill)
end

function NoDriveByFill:onLoad(savegame)
    local spec = self[NoDriveByFill.SPEC_NAME]
    if spec ~= nil then
        spec.lastBlockedTrigger = nil
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

function NoDriveByFill.getSelectedTrigger(vehicle)
    local fillUnitSpec = vehicle ~= nil and vehicle.spec_fillUnit or nil
    if fillUnitSpec == nil or fillUnitSpec.fillTrigger == nil then
        return nil
    end

    local fillTrigger = fillUnitSpec.fillTrigger

    if fillTrigger.selectedTrigger ~= nil then
        return fillTrigger.selectedTrigger
    end

    if fillTrigger.currentTrigger ~= nil then
        return fillTrigger.currentTrigger
    end

    if fillTrigger.triggers ~= nil and #fillTrigger.triggers > 0 then
        return fillTrigger.triggers[1]
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

-- FillActivatable asks the vehicle whether a nearby load trigger may be activated.
function NoDriveByFill:getAllowLoadTriggerActivation(superFunc, rootVehicle)
    local block = NoDriveByFill.shouldBlockTriggerFill(self)

    if block then
        return false
    end

    return superFunc(self, rootVehicle)
end

-- Additional guard against starting the FillTrigger filling path directly.
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
