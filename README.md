# FS25 No Drive-By Fill

Script mod for Farming Simulator 25.

## What it changes

For **player-controlled** equipment, the mod disables proximity / "drive-by"
filling through `FillTrigger` for:

- `SEEDS` in sowing machines and planters;
- `FERTILIZER` (solid fertilizer) in fertilizer equipment;
- `LIME` in lime spreaders.

The machine must instead be filled by **physically discharging material into
its open hopper**, e.g. with a front-loader bucket, trailer, auger or another
discharge-capable source supported by the machine.

## What it does not change

- liquid fertilizer;
- herbicide;
- water;
- fuel;
- liquid manure / digestate;
- other liquid fill types;
- AI-controlled equipment.

The mod intentionally does **not** overwrite `FillUnit:addFillUnitFillLevel()`.
It only prevents activation/start of the nearby `FillTrigger` filling path, so
normal physical discharge into the fill unit remains available.

## Installation

Copy `FS25_NoDriveByFill.zip` to:

`Documents/My Games/FarmingSimulator2025/mods`

Enable the mod for the savegame.

## Suggested test

1. Attach a seeder and drive next to a seed big bag.
   The normal proximity filling action should not become usable.
2. Lift seed material above the open hopper and discharge it.
   The seeder should fill normally.
3. Repeat with solid fertilizer and lime.
4. Check a liquid-fertilizer sprayer.
   Its normal filling behaviour should be unchanged.

The game log should contain an entry beginning with:

`[FS25_NoDriveByFill] Loaded.`

