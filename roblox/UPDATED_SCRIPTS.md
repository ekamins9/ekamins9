# Updated scripts: War's rounds end on a flight over the field

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

---

## Before that: key art on the loading and travel screens; a world round the Courtyard

- **Key art** (generated: the two armies, trebuchets, a battle-mage's lightning) behind the loading screen and every travel screen, darkened so the words read.
- **The Courtyard isn't a floating island any more**: hills to the horizon, the road out of the gate through a village and fields, woods, and a war camp far to the east whose trebuchets lob fire now and then over the far hills (a tease for WAR).
- **Fixes**: the travel screen's embers were drawn under its backdrop and never seen.
- **Checked in Play**: the menu still frames the castle (the world sits beside the map, not in it: inside it the menu's camera pulled back a mile); the travel screen with the art; the art loads.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubBackdrop.lua](ServerScriptService/Game/HubBackdrop.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Hub.lua](ServerScriptService/Game/Modes/Hub.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | builds / clears it |
| [HubAmbience.client.lua](StarterPlayerScripts/HubAmbience.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [Loading.client.lua](ReplicatedFirst/Loading.client.lua) | ReplicatedFirst | LocalScript | key art |
| [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | key art; embers seen |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ReplicatedFirst ▸ KeyArt.
