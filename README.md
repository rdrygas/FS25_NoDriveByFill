# FS25 No Drive-By Fill

### Description

FS25_NoDriveByFill disables proximity ("drive-by") filling of dry and bulk
materials for vehicles and implements controlled by the player.

In the base game, many machines can be filled simply by driving next to a
compatible big bag, pallet or similar source and pressing the refill key. This
mod removes that shortcut for dry and bulk materials. The material must instead
be physically loaded into the receiving machine, for example by lifting a bag
with a loader or tipping material into an open hopper or trailer.

Liquid filling is intentionally left unchanged.

### Design assumptions

The mod follows these rules:

- it affects only equipment belonging to the vehicle currently controlled by
  the player;
- AI-controlled equipment is not modified;
- it works with every vehicle type that uses the `FillUnit` specialization,
  instead of relying on store categories such as `trailers`, `trailersSemi` or
  `augerWagons`;
- dry and bulk materials are blocked;
- liquids remain unaffected;
- normal physical discharge into a receiving fill unit remains available;
- normal loading stations and silos remain available where they use the game's
  loading-station mechanism rather than the blocked proximity-filling path;
- manual cover control remains available.

### How it works

The mod is implemented as a global vehicle specialization.

`NoDriveByFillInit.lua` attaches the specialization to every registered vehicle
type that uses `FillUnit`. `NoDriveByFill.lua` then checks the fill type offered
by the currently selected nearby fill trigger.

For blocked materials the mod:

1. prevents activation of the nearby refill trigger;
2. prevents `setFillUnitIsFilling(true)` from starting proximity filling;
3. removes the refill activatable, so the normal `R` prompt is not displayed;
4. prevents the cover from opening automatically because of the blocked source.

The regular fill-level/discharge mechanism is not replaced, so material can
still be physically tipped or discharged into the receiving machine.

### Blocked materials

The mod explicitly recognizes common dry/bulk materials, including:

- seeds, solid fertilizer and lime;
- road salt;
- wheat, barley, oats, canola, sunflower, soybean, maize and sorghum;
- potatoes, sugar beet, sugar cane and supported vegetable crops;
- pig food, forage, grass, hay, straw, silage, chaff and mineral feed;
- wood chips and manure.

In addition, any compatible fill type assigned to the game's `BULK` category
is blocked automatically. This also improves compatibility with modded maps and
custom bulk materials.

Known liquid fill types and the `LIQUID`, `SPRAYER` and `SLURRYTANK`
categories are excluded from the block.

### Behaviour table

| Situation | Result |
|---|---|
| Seeder next to a seed big bag/pallet | Proximity filling blocked |
| Fertilizer spreader next to solid fertilizer | Proximity filling blocked |
| Lime spreader next to lime | Proximity filling blocked |
| Salt spreader next to road salt | Proximity filling blocked |
| Trailer/semitrailer next to compatible dry bulk material | Proximity filling blocked |
| Auger wagon next to compatible dry bulk material | Proximity filling blocked |
| `R` refill prompt for a blocked source | Hidden |
| Automatic cover opening for a blocked source | Disabled |
| Manual cover opening/closing | Available |
| Loading by tipping a lifted bag/pallet into the machine | Available |
| Loading with a loader bucket or another discharge source | Available |
| Loading from a compatible silo/loading station | Available |
| Liquid fertilizer, herbicide, water, fuel and other liquids | Unchanged |
| AI-controlled equipment | Unchanged |

### Configuration

There is no in-game configuration menu.

The behaviour can be adjusted directly in:

`FS25_NoDriveByFill/scripts/NoDriveByFill.lua`

The two relevant tables are:

- `NoDriveByFill.BLOCKED_FILL_TYPE_NAMES` — explicitly blocked dry materials;
- `NoDriveByFill.LIQUID_FILL_TYPE_NAMES` — explicitly allowed liquid materials.

Other fill types in the `BULK` category are blocked automatically.

To add an explicit dry material, add its fill type name:

```lua
CUSTOM_MATERIAL = true,
```

To protect an additional liquid fill type from blocking, add it to
`LIQUID_FILL_TYPE_NAMES` in the same way.

### Installation

Copy the ZIP file to:

`Documents/My Games/FarmingSimulator2025/mods`

Enable **No Drive-By Fill** when loading the savegame.

### Log entries

At startup the mod writes a message similar to:

```text
Info: [FS25_NoDriveByFill] Added specialization to 123 FillUnit vehicle types.
```

When proximity filling is blocked, the log may contain:

```text
Info: [FS25_NoDriveByFill] Blocked proximity filling: vehicle='...', fillType='WHEAT'
```

### Change history

#### 1.0.0.0

- initial implementation.

#### 1.0.1.0

- replaced the initial global-function approach with a vehicle specialization;
- correctly intercepted the functions registered for individual vehicle types;
- added reliable proximity-filling blocking for seeds, solid fertilizer and
  lime.

#### 1.0.2.0

- hid the `R` refill prompt for blocked sources;
- prevented automatic cover opening near blocked sources;
- preserved manual cover control.

#### 1.1.0.0

- expanded support from sowing/spreading equipment to all vehicle types using
  `FillUnit`;
- added trailers, semitrailers, auger wagons and compatible modded equipment;
- added grain, feed, road salt and other dry materials;
- added automatic support for the `BULK` fill type category;
- preserved liquid filling.
