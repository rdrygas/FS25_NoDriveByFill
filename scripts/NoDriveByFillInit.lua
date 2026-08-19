-- Global specialization injector for FS25_NoDriveByFill.
-- Version 1.1.0.0
--
-- Attach the specialization to every vehicle type that has FillUnit.
-- The actual decision whether to block filling is made later from the
-- selected fillType and whether the vehicle is controlled by the player.

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

                local hasFillUnit =
                    SpecializationUtil.hasSpecialization(FillUnit, specializations)

                local alreadyAdded =
                    SpecializationUtil.hasSpecialization(NoDriveByFill, specializations)

                if hasFillUnit and not alreadyAdded then
                    g_vehicleTypeManager:addSpecialization(typeName, specName)
                    addedCount = addedCount + 1
                end
            end

            Logging.info(
                "[%s] Added specialization to %d FillUnit vehicle types.",
                modName,
                addedCount
            )
        end

        return originalValidateTypes(self, ...)
    end
end
