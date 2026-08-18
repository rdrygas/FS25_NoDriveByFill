-- FS25_NoDriveByFill
--
-- Blocks "remote" / proximity filling from FillTriggers for:
-- - seeds (SEEDS) in sowing machines / planters
-- - solid fertilizer (FERTILIZER) in sprayers/spreaders
-- - lime (LIME) in sprayers/spreaders
--
-- Direct physical filling (e.g. tipping material from a loader bucket,
-- trailer or other discharge source into an open hopper) is NOT blocked.
--
-- Liquid fill types are NOT affected.
--
-- Intended for player-controlled machines.

NoDriveByFill = {}

NoDriveByFill.MOD_NAME = g_currentModName or "FS25_NoDriveByFill"

NoDriveByFill.BLOCKED_FILL_TYPE_NAMES = {
    "SEEDS",
    "FERTILIZER",
    "LIME"
}

NoDriveByFill.blockedFillTypes = {}

NoDriveByFill.originalGetAllowLoadTriggerActivation = nil
NoDriveByFill.originalSetFillUnitIsFilling = nil
NoDriveByFill.wrappedGetAllowLoadTriggerActivation = nil
NoDriveByFill.wrappedSetFillUnitIsFilling = nil

-- Returns true only for implements relevant to this mod.
-- SowingMachine covers seeders/planters.
-- Sprayer is also the base specialization used by fertilizer/lime spreaders.
function NoDriveByFill.isTargetMachine(vehicle)
    if vehicle == nil then
        return false
    end

    return vehicle.spec_sowingMachine ~= nil
        or vehicle.spec_sprayer ~= nil
end

-- The base game itself uses g_localPlayer:getCurrentVehicle() when deciding
-- whether a FillUnit may activate a nearby loading trigger.
-- We keep the same concept and additionally reject AI-controlled root vehicles.
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

-- Returns the fill type offered by the FillTrigger currently selected by FillUnit.
function NoDriveByFill.getTriggerFillType(vehicle)
    if vehicle == nil or vehicle.spec_fillUnit == nil then
        return nil
    end

    local fillTrigger = vehicle.spec_fillUnit.fillTrigger

    if fillTrigger == nil then
        return nil
    end

    local trigger = fillTrigger.currentTrigger or fillTrigger.selectedTrigger

    if trigger == nil then
        -- Normally updateFillUnitTriggers() has already selected a trigger.
        -- This fallback helps during the short interval immediately after
        -- a trigger is added.
        if fillTrigger.triggers ~= nil and #fillTrigger.triggers > 0 then
            trigger = fillTrigger.triggers[1]
        end
    end

    if trigger ~= nil and trigger.getCurrentFillType ~= nil then
        return trigger:getCurrentFillType()
    end

    return nil
end

function NoDriveByFill.shouldBlockTriggerFill(vehicle)
    if not NoDriveByFill.isTargetMachine(vehicle) then
        return false
    end

    if not NoDriveByFill.isPlayerControlled(vehicle) then
        return false
    end

    local fillTypeIndex = NoDriveByFill.getTriggerFillType(vehicle)

    return fillTypeIndex ~= nil
        and NoDriveByFill.blockedFillTypes[fillTypeIndex] == true
end

-- First line of defence:
-- suppress activation of proximity/load triggers for the selected dry material.
function NoDriveByFill.getAllowLoadTriggerActivation(vehicle, superFunc, rootVehicle)
    if NoDriveByFill.shouldBlockTriggerFill(vehicle) then
        return false
    end

    return superFunc(vehicle, rootVehicle)
end

-- Second line of defence:
-- even if another script/input path tries to start trigger filling directly,
-- do not allow it for the blocked dry fill types while the player controls
-- the machine.
function NoDriveByFill.setFillUnitIsFilling(vehicle, superFunc, isFilling, noEventSend)
    if isFilling and NoDriveByFill.shouldBlockTriggerFill(vehicle) then
        return
    end

    return superFunc(vehicle, isFilling, noEventSend)
end

function NoDriveByFill:loadMap(mapNode, mapFile)
    self.blockedFillTypes = {}

    if g_fillTypeManager ~= nil then
        for _, fillTypeName in ipairs(self.BLOCKED_FILL_TYPE_NAMES) do
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

            if fillTypeIndex ~= nil then
                self.blockedFillTypes[fillTypeIndex] = true
            else
                Logging.warning(
                    "[%s] Fill type '%s' was not found.",
                    self.MOD_NAME,
                    fillTypeName
                )
            end
        end
    end

    if FillUnit == nil then
        Logging.error("[%s] FillUnit specialization is not available.", self.MOD_NAME)
        return
    end

    self.originalGetAllowLoadTriggerActivation = FillUnit.getAllowLoadTriggerActivation
    self.originalSetFillUnitIsFilling = FillUnit.setFillUnitIsFilling

    self.wrappedGetAllowLoadTriggerActivation = Utils.overwrittenFunction(
        self.originalGetAllowLoadTriggerActivation,
        NoDriveByFill.getAllowLoadTriggerActivation
    )

    self.wrappedSetFillUnitIsFilling = Utils.overwrittenFunction(
        self.originalSetFillUnitIsFilling,
        NoDriveByFill.setFillUnitIsFilling
    )

    FillUnit.getAllowLoadTriggerActivation = self.wrappedGetAllowLoadTriggerActivation
    FillUnit.setFillUnitIsFilling = self.wrappedSetFillUnitIsFilling

    Logging.info(
        "[%s] Loaded. Proximity filling blocked for SEEDS, FERTILIZER and LIME on player-controlled sowing/spreading equipment.",
        self.MOD_NAME
    )
end

function NoDriveByFill:deleteMap()
    -- Restore only if nobody wrapped these functions after this mod.
    -- This avoids accidentally removing another mod's later wrapper.
    if FillUnit ~= nil then
        if FillUnit.getAllowLoadTriggerActivation == self.wrappedGetAllowLoadTriggerActivation then
            FillUnit.getAllowLoadTriggerActivation = self.originalGetAllowLoadTriggerActivation
        end

        if FillUnit.setFillUnitIsFilling == self.wrappedSetFillUnitIsFilling then
            FillUnit.setFillUnitIsFilling = self.originalSetFillUnitIsFilling
        end
    end

    self.blockedFillTypes = {}
end

function NoDriveByFill:update(dt)
end

function NoDriveByFill:draw()
end

function NoDriveByFill:keyEvent(unicode, sym, modifier, isDown)
end

function NoDriveByFill:mouseEvent(posX, posY, isDown, isUp, button)
end

addModEventListener(NoDriveByFill)
