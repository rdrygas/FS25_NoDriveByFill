# FS25_NoDriveByFill — v1.1.0.0

Script mod for Farming Simulator 25.

## Scope

The specialization is attached to **all vehicle types with `FillUnit`**.
This avoids relying on store categories such as `trailers`, `trailersSemi`
or `augerWagons` and also supports compatible modded equipment.

The block is active only when the equipment belongs to the vehicle currently
controlled by the player. AI-controlled equipment is not changed.

## Blocked proximity filling

The mod blocks nearby `FillTrigger` filling for dry/bulk materials, including:

- `SEEDS`
- `FERTILIZER`
- `LIME`
- `ROADSALT` / `ROAD_SALT`
- `WHEAT`
- `BARLEY`
- `OAT`
- `CANOLA`
- `SUNFLOWER`
- `SOYBEAN`
- `MAIZE`
- `SORGHUM`
- `POTATO`
- `SUGARBEET`
- `SUGARCANE`
- `CARROT`
- `PARSNIP`
- `BEETROOT`
- `PEAS`
- `GREENBEAN`
- `SPINACH`
- `RICE`
- `LONG_GRAIN_RICE`
- `PIGFOOD`
- `FORAGE`
- `FORAGE_MIXING`
- `GRASS`
- `GRASS_WINDROW`
- `DRYGRASS`
- `DRYGRASS_WINDROW`
- `STRAW`
- `SILAGE`
- `CHAFF`
- `MINERAL_FEED`
- `WOODCHIPS`
- `MANURE`

Additionally, other fill types assigned to the game's `BULK` category are
blocked automatically. This also improves compatibility with modded maps and
custom bulk materials.

## Liquids are unchanged

Known liquid fill types are explicitly allowed and the mod also recognizes
the `LIQUID`, `SPRAYER` and `SLURRYTANK` fill-type categories.

Examples which remain unchanged:

- water
- milk
- liquid fertilizer
- herbicide
- liquid manure
- digestate
- fuel / diesel
- DEF
- other compatible liquid materials

Explicit blocked dry materials have priority, so solid `FERTILIZER` remains
blocked even if a broad equipment category overlaps.

## Other behaviour

For a blocked proximity source:

- the normal `R` refill action is hidden;
- filling cannot be started;
- the cover does not open automatically.

Still allowed:

- manual cover operation;
- physically tipping material into an open hopper/trailer;
- normal discharge from loaders, trailers, augers and other discharge sources;
- liquid filling;
- loading-station mechanisms not using this proximity FillTrigger path.

## Expected startup log

`[FS25_NoDriveByFill] Added specialization to N FillUnit vehicle types.`

The number will be considerably higher than in v1.0.2.0 because trailers,
auger wagons and other FillUnit-based vehicle types are now included.

## Blocking log examples

`[FS25_NoDriveByFill] Blocked proximity filling: vehicle='...', fillType='WHEAT'`

`[FS25_NoDriveByFill] Blocked proximity filling: vehicle='...', fillType='PIGFOOD'`

`[FS25_NoDriveByFill] Blocked proximity filling: vehicle='...', fillType='ROADSALT'`

## Suggested tests

1. Trailer + nearby wheat/oat/pig-food big bag:
   - no proximity filling;
   - no `R` refill prompt;
   - no automatic cover opening.
2. Auger wagon + compatible nearby dry-material source:
   - same result.
3. Physically lift/tip the bag into the trailer:
   - filling should work.
4. Fill a trailer at a normal silo/loading station:
   - verify that normal station loading is unchanged.
5. Test liquid fertilizer/water/fuel:
   - filling should remain unchanged.
