# Updated scripts: the Siege is a real siege now

- **Defenders' archers line the castle walls** and loose on the field; the attackers' archers loose back.
- **Ladders against the walls** with men swarming up them under a block of raised shields: some go over the top and fight on the walk, some are thrown off.
- **Battles on both flanks** of the castle: the defenders' sally against the attackers' lines, with a charge, the crash, and fresh charges.
- **The castle burns**: towers on fire with smoke rising high, villages burning beyond, stones and fire falling on the towers and walls.
- **It follows the fight**: the gate falls → the attackers cheer, the wall archers are cut down, the ladders all go over, the reserves charge the walls; the great hall stormed → its roof catches fire; the winners cheer.
- **Fixed**: the "split arrow" power crashed its extra arrows (they left after the draw had ended), so they never flew. Fireballs that hit a roof no longer leave a burn mark hanging in the air.
- **Checked in Play** on Frostgate: from the spawn, from the wall, the gate breaking, the hall burning. About 45 fps in Studio play with 40 bots.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | describes the castle on the map |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | ladders, shields overhead, rout, men on walls |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | blasts without a burn mark |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat | ModuleScript | split-arrow fix |
| [README.md](README.md) | | doc | |

---

## Before that: War's armies are real soldiers now

- **The background armies look real**: every soldier on the flanks is a copy of the game's own armoured soldier (real armour sets, the side's colours, real weapons and shields), animated limb by limb: marching, charging, fighting face to face, falling, flung by blasts. The fallen stay on the field.
- **Set-pieces**: an opening charge with horns and drums where both lines crash together; lanes that pull back and charge again; trebuchet fire throwing men through the air; volleys cutting men down; cavalry ploughing through a flank.
- **Atmosphere**: dust over each melee, columns of smoke, the din of each flank coming from its own side, the roar of the armies, war drums (new generated sounds).
- **Performance**: 16,400 crowd parts at 59 fps in Studio, the crowd costing about 1 ms a frame (levels of detail by rank, full posing only near the camera, cached poses further off, culling). First try ran at 18 fps; the fix was not re-posing men for small drifts.
- The flank lanes moved in, right up to the stakes, so the battle is close.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | new |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | smoke columns, haze, positional loops |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the crowds, charges, atmosphere |
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | lanes nearer |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ReplicatedStorage ▸ WarAudio ▸ Drums, Roar, Melee, Fire, Drone, Whisper.

---

## Before that: weather on the battle maps

- **Snow, rain, storms, embers and petals** on the maps that suit them (Frostgate snows, Stormhold storms, Emberkeep's air is full of embers, Blossomgate's of petals…), and Plague Night is always a storm. One table in GameConfig sets it.
- **Checked in Play**: Siege on Frostgate: snow falling, heavier cloud.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Weather.client.lua](StarterPlayerScripts/Weather.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | MAP_WEATHER, MODE_WEATHER |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | petals; weatherKind() |
| [README.md](README.md) | | doc | |
