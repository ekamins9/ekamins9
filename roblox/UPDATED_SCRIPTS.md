# Updated scripts: the hill task works; War's banners in the daily tasks

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

---

## Before that: War's banners pay; War's kills on the season board

- **Taking a banner pays**: everyone of your side at a banner when it falls to you earns 20 Marks and 45 XP (paid with the round), so the objective is worth chasing.
- **War counts on the season's kill board**, like Warfront.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | war_banner on a capture |
| [Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | war_banner |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ServerScriptService | Script | War's kills on the board |
| [README.md](README.md) | | doc | |
