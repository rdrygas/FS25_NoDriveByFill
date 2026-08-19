-- FS25_NoDriveByFill
-- Version 1.1.0.0
--
-- Blocks FillTrigger/proximity filling for player-controlled vehicles with
-- FillUnit when the selected source contains dry/bulk material.
--
-- This includes:
-- - sowing machines / planters
-- - fertilizer and lime spreaders
-- - road salt spreaders
-- - trailers / semitrailers
-- - auger wagons
-- - other FillUnit-based vehicles
--
-- Physical filling through normal discharge into a fill unit is not blocked.
-- Loading stations that use the game's separate loading-station mechanism are
-- not intentionally changed.
--
-- Liquid fill types are explicitly left unchanged.
--
-- v1.1.0.0:
-- - specialization is injected into ALL vehicle types with FillUnit
-- - adds grain, feed, road salt and other dry/bulk fill types
-- - supports BULK fillType category for base-game and modded materials

NoDriveByFill = {}

NoDriveByFill.MOD_NAME = g_currentModName or "FS25_NoDriveByFill"
NoDriveByFill.SPEC_NAME = string.format("spec_%s.noDriveByFill", NoDriveByFill.MOD_NAME)

NoDriveByFill.BLOCKED_FILL_TYPE_NAMES = {
    SEEDS = true,
    FERTILIZER = true,
    LIME = true,

    ROADSALT = true,
    ROAD_SALT = true,

    WHEAT = true,
    BARLEY = true,
    OAT = true,
    CANOLA = true,
    SUNFLOWER = true,
    SOYBEAN = true,
    MAIZE = true,
    SORGHUM = true,
    POTATO = true,
    SUGARBEET = true,
    SUGARCANE = true,
    CARROT = true,
    PARSNIP = true,
    BEETROOT = true,
    PEAS = true,
    GREENBEAN = true,
    SPINACH = true,
    RICE = true,
    LONG_GRAIN_RICE = true,

    PIGFOOD = true,
    FORAGE = true,
    FORAGE_MIXING = true,
    GRASS = true,
    GRASS_WINDROW = true,
    DRYGRASS = true,
    DRYGRASS_WINDROW = true,
    STRAW = true,
    SILAGE = true,
    CHAFF = true,
    MINERAL_FEED = true,

    WOODCHIPS = true,
    MANURE = true
}

NoDriveByFill.LIQUID_FILL_TYPE_NAMES = {
    WATER = true,
    MILK = true,
    LIQUIDFERTILIZER = true,
    HERBICIDE = true,
    LIQUIDMANURE = true,
    DIGESTATE = true,
    FUEL = true,
    DIESEL = true,
    DEF = true,
    METHANE = true,
    AIR = true
}

function NoDriveByFill.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
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

    if g_localPlayer:getCurrentVehicle() ~= rootVehicle then
        return false
    end

    if rootVehicle.getIsAIActive ~= nil and rootVehicle:getIsAIActive() then
        return false
    end

    return true
end

function NoDriveByFill.getFillTypeName(fillTypeIndex)
    if fillTypeIndex == nil
        or g_fillTypeManager == nil
        or g_fillTypeManager.getFillTypeNameByIndex == nil then
        return nil
    end

    return g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
end

function NoDriveByFill.isLiquidFillType(fillTypeIndex)
    if fillTypeIndex == nil or g_fillTypeManager == nil then
        return false
    end

    local fillTypeName = NoDriveByFill.getFillTypeName(fillTypeIndex)

    if fillTypeName ~= nil
        and NoDriveByFill.LIQUID_FILL_TYPE_NAMES[fillTypeName] == true then
        return true
    end

    if g_fillTypeManager.getIsFillTypeInCategory ~= nil then
        if g_fillTypeManager:getIsFillTypeInCategory(fillTypeIndex, "LIQUID")
            or g_fillTypeManager:getIsFillTypeInCategory(fillTypeIndex, "SLURRYTANK")
            or g_fillTypeManager:getIsFillTypeInCategory(fillTypeIndex, "SPRAYER") then
            return true
        end
    end

    return false
end

function NoDriveByFill.isBlockedFillType(fillTypeIndex)
    if fillTypeIndex == nil or g_fillTypeManager == nil then
        return false
    end

    local fillTypeName = NoDriveByFill.getFillTypeName(fillTypeIndex)

    if fillTypeName ~= nil
        and NoDriveByFill.BLOCKED_FILL_TYPE_NAMES[fillTypeName] == true then
        return true
    end

    if NoDriveByFill.isLiquidFillType(fillTypeIndex) then
        return false
    end

    if g_fillTypeManager.getIsFillTypeInCategory ~= nil
        and g_fillTypeManager:getIsFillTypeInCategory(fillTypeIndex, "BULK") then
        return true
    end

    return false
end

-- updateFillUnitTriggers() sorts triggers before selectedTrigger is updated,
-- therefore the first trigger is the most reliable current source here.
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

function NoDriveByFill:getAllowLoadTriggerActivation(superFunc, rootVehicle)
    local block = NoDriveByFill.shouldBlockTriggerFill(self)

    if block then
        return false
    end

    return superFunc(self, rootVehicle)
end

function NoDriveByFill:setFillUnitIsFilling(superFunc, isFilling, noEventSend)
    if isFilling then
        local block, fillTypeIndex, trigger = NoDriveByFill.shouldBlockTriggerFill(self)

        if block then
            local spec = self[NoDriveByFill.SPEC_NAME]

            if spec ~= nil and spec.lastBlockedTrigger ~= trigger then
                spec.lastBlockedTrigger = trigger

                local fillTypeName = NoDriveByFill.getFillTypeName(fillTypeIndex)
                    or tostring(fillTypeIndex)

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
        -- FillUnit normally adds the activatable only when the first trigger appears.
        if hasTriggers then
            g_currentMission.activatableObjectsSystem:addActivatable(
                fillTrigger.activatable
            )
        end

        modSpec.fillActivatableSuppressed = false
    end
end

function NoDriveByFill:setCoverState(superFunc, state, noEventSend)
    if noEventSend == true and state ~= nil and state > 0 then
        local block = NoDriveByFill.shouldBlockTriggerFill(self)

        if block then
            return
        end
    end

    return superFunc(self, state, noEventSend)
end
