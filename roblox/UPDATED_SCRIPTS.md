# Updated scripts: key art on the loading and travel screens; a world round the Courtyard

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

---

## Before that: cheaper bots far from players; War fields 32

- **Stress test** (War, 46 bots held): Studio's shared server fell to about 24 fps; with the cap free, it stepped itself down 46 → 38 → 34 → 30 as designed. War now fields 32 by default for headroom.
- **Bots no player is near** (90 studs) watch for parries every third frame and think five times a second instead of ten: nobody sees those fights, and both sides are treated the same.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat | ModuleScript | far bots cheaper |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | War botFill 32 |
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | default cap 32 |
| [README.md](README.md) | | doc | |
