# Updated scripts: weather on the battle maps

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

---

## Before that: the hill task works; War's banners in the daily tasks

- **Fixed: "Hold the hill for 2 minutes" could never be finished**: nothing counted time on the hill. King of the Hill now counts every second each player of the holding side spends on it (checked in Play: 6 s on the hill, 6 counted).
- **New tasks**: Take 3 banners in War (220 Marks), Take 8 banners in War (420), and weekly Take 25 banners in War (1200).

| File | Studio location | Type | Change |
|---|---|---|---|
| [KOTH.lua](ServerScriptService/Game/Modes/KOTH.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | counts the hill stat |
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | counts the banner stat |
| [Contracts.lua](ReplicatedStorage/Catalog/Contracts.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | War tasks |
| [Stats.lua](ServerScriptService/Economy/Stats.lua) | ServerScriptService ▸ Economy | ModuleScript | (doc) |
