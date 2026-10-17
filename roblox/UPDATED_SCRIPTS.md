# Updated scripts: War's armies are real soldiers now

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

---

## Before that: War's rounds end on a flight over the field

- **The battle's end**: the camera rises and circles over the field, the winners' horns sound and their regiments loose and cheer; the result board and the class screen wait five seconds for it.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the finale |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `_G.BoardHoldUntil` |
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `_G.BoardHoldUntil` |
| [README.md](README.md) | | doc | |
