# FS25_NoDriveByFill — v1.0.1.0

Corrected test version for Farming Simulator 25.

## Important change from 1.0.0.0

Version 1.0.0.0 replaced functions in the global `FillUnit` table after
vehicle types had already registered their own copies of these functions.
As a result, the mod loaded without errors but did not actually intercept
the filling functions used by seeders/spreaders.

Version 1.0.1.0 uses a real vehicle specialization and injects it into
vehicle types during `TypeManager.validateTypes`.

## Blocked proximity filling

For a player-controlled machine:

- `SEEDS` — sowing machines / planters
- `FERTILIZER` — solid fertilizer spreaders
- `LIME` — lime spreaders

Liquid fill types remain unchanged.

Physical discharge into the machine is not blocked because the mod does
not overwrite `addFillUnitFillLevel()` or the normal discharge system.

## Expected log entries

On game startup:

`[FS25_NoDriveByFill] Added specialization to N sowing/spraying vehicle types.`

When the blocked proximity refill path is actually attempted:

`[FS25_NoDriveByFill] Blocked proximity filling: vehicle='...', fillType='...'`
