# FS25_NoDriveByFill — v1.0.2.0

Script mod for Farming Simulator 25.

## Behaviour

For **player-controlled** sowing/spreading equipment the mod blocks proximity
filling from nearby FillTriggers for:

- `SEEDS`
- `FERTILIZER` (solid fertilizer)
- `LIME`

The dry material must instead be physically discharged into the machine,
for example by tipping a lifted big-bag or pallet with a loader.

Liquid filling remains unchanged.

## v1.0.2.0

In addition to the working filling block from v1.0.1.0:

- the normal proximity refill activatable (`R`) is temporarily removed while
  the selected nearby source contains SEEDS, FERTILIZER or LIME;
- it is restored automatically when the blocked source is left or an allowed
  source becomes selected;
- automatic cover opening caused by the blocked FillTrigger is suppressed;
- manual cover opening/closing remains available.

## Expected startup log

`[FS25_NoDriveByFill] Added specialization to N sowing/spraying vehicle types.`

## Expected blocking log

Examples:

`[FS25_NoDriveByFill] Blocked proximity filling: vehicle='...', fillType='SEEDS'`

`[FS25_NoDriveByFill] Blocked proximity filling: vehicle='...', fillType='FERTILIZER'`

`[FS25_NoDriveByFill] Blocked proximity filling: vehicle='...', fillType='LIME'`

## Suggested regression test

1. Drive a seeder next to a seed big-bag:
   - no proximity refill should be possible;
   - the `R` refill prompt should not be displayed;
   - the cover should not open automatically.
2. Open the cover manually and tip seed into the hopper with a loader:
   - physical filling should work.
3. Repeat for solid fertilizer and lime.
4. Test a lime/fertilizer loading station:
   - behaviour that worked in v1.0.1.0 should remain unchanged.
5. Test liquid fertilizer/water/fuel:
   - liquid filling should remain unchanged.
