-- Global specialization injector for FS25_NoDriveByFill.
-- The specialization is attached while vehicle types are being validated.

local modName = g_currentModName
local specName = modName .. ".noDriveByFill"
local guardName = modName .. "_noDriveByFillSpecInjected"

if not _G[guardName] then
    _G[guardName] = true

    local originalValidateTypes = TypeManager.validateTypes

    TypeManager.validateTypes = function(self, ...)
        if self.typeName == "vehicle" then
            local vehicleTypes = g_vehicleTypeManager:getTypes()
            local addedCount = 0

            for typeName, typeEntry in pairs(vehicleTypes) do
                local specializations = typeEntry.specializations

                local hasFillUnit = SpecializationUtil.hasSpecialization(FillUnit, specializations)
                local isSowingMachine = SpecializationUtil.hasSpecialization(SowingMachine, specializations)
                local isSprayer = SpecializationUtil.hasSpecialization(Sprayer, specializations)
                local alreadyAdded = SpecializationUtil.hasSpecialization(NoDriveByFill, specializations)

                if hasFillUnit
                    and (isSowingMachine or isSprayer)
                    and not alreadyAdded then

                    g_vehicleTypeManager:addSpecialization(typeName, specName)
                    addedCount = addedCount + 1
                end
            end

            Logging.info(
                "[%s] Added specialization to %d sowing/spraying vehicle types.",
                modName,
                addedCount
            )
        end

        return originalValidateTypes(self, ...)
    end
end
