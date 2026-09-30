# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change (follow-up):** ONE PLACE. No more `PLACES`: public servers are the Hub, every
match is a **reserved server** of the same place that gets its mode from the teleport data and
never changes it. PLAY joins a match server with room or reserves a fresh one, **RETURN TO HUB**
teleports to a public server, **CUSTOM** servers are LISTED (public) or FRIENDS ONLY, and every
server has an access level — Public / Friends / Locked — enforced on arrival (`Game.mayJoin`
kicks), so a locked 1v1 can't be crashed through Join Friend. Access codes never reach a
client. Parties carry through teleports; the Hub mode reads HUB. Studio can't teleport, so
there PLAY still switches the mode locally. Files touched: GameConfig, Game, GameServer,
HubServer, HubMenu, README.

**Previous change:** the game around the combat — a **Hub menu (M)** with PLAY / SERVERS (browser
with filters + friends) / ARMORY (one saved loadout per class) / PARTY / SETTINGS, a **class
screen** replacing the old armor+weapon spawn menu, **game modes** (Hub, FFA, Duel, TDM, LTS,
KOTH) with **maps in `ServerStorage/Maps`** configured per mode in `GameConfig`, **teams** with
tabards and friendly fire, map votes, profiles, and the **FOV** dial: the 70 setting now looks
like the old 110 in first person and 110 goes wider still.

## Studio setup (once)

1. Delete `ServerScriptService` → `RoundServer` (replaced by `Game` → `GameServer`).
2. Create folders `ServerScriptService` → `Game`, `Game` → `Modes`, `ServerScriptService` → `Hub`.
3. Create `ServerStorage` → `Maps` (Folder). Each map is a **Model** named as in
   `GameConfig.MODES[...].maps` (`Courtyard`, `Arena`, `Village`, `Bridge` — rename to taste in
   `GameConfig`). Inside: a `Spawns` folder of parts (attribute `Team` = `A` / `B` for team
   spawns, none for anyone), an optional `MenuCamera` part (menu camera sits there, looks along
   its front), for KOTH a `Zones` folder with a `Hill` part, and the geometry. No map yet → the
   game plays on whatever is in workspace (your current place), so nothing breaks meanwhile.
4. One place is all you need: an empty world with a skybox. Publish it; matches are reserved
   servers of it. In Studio PLAY switches the mode locally (no teleports there); custom servers
   and the browser need the published game with API access.

## New files

| File | Roblox Studio location | Type | What it is |
|---|---|---|---|
| [ReplicatedStorage/GameConfig.lua](ReplicatedStorage/GameConfig.lua) | `ReplicatedStorage` → `GameConfig` | ModuleScript | places, modes + their maps, teams, classes, friendly fire |
| [ServerScriptService/Game/Game.lua](ServerScriptService/Game/Game.lua) | `ServerScriptService` → `Game` (Folder) → `Game` | ModuleScript | mode runner + `Game.Mode` base class, Round attributes |
| [ServerScriptService/Game/MapLoader.lua](ServerScriptService/Game/MapLoader.lua) | `ServerScriptService` → `Game` → `MapLoader` | ModuleScript | loads `ServerStorage/Maps/<Name>` into `workspace.Map`, spawns, MenuCamera, zones |
| [ServerScriptService/Game/Teams.lua](ServerScriptService/Game/Teams.lua) | `ServerScriptService` → `Game` → `Teams` | ModuleScript | Crown / Iron, party-aware balance, `Team` attribute + tabard |
| [ServerScriptService/Game/GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | `ServerScriptService` → `Game` → `GameServer` | Script | the round loop, map vote (`VoteRemote`), intermissions |
| [ServerScriptService/Game/Modes/Hub.lua](ServerScriptService/Game/Modes/Hub.lua) | `ServerScriptService` → `Game` → `Modes` (Folder) → `Hub` | ModuleScript | courtyard: no clock, ends when a mode is picked |
| [ServerScriptService/Game/Modes/FFA.lua](ServerScriptService/Game/Modes/FFA.lua) | `…` → `Modes` → `FFA` | ModuleScript | free-for-all |
| [ServerScriptService/Game/Modes/Duel.lua](ServerScriptService/Game/Modes/Duel.lua) | `…` → `Modes` → `Duel` | ModuleScript | duel yard |
| [ServerScriptService/Game/Modes/TDM.lua](ServerScriptService/Game/Modes/TDM.lua) | `…` → `Modes` → `TDM` | ModuleScript | team deathmatch, tickets |
| [ServerScriptService/Game/Modes/LTS.lua](ServerScriptService/Game/Modes/LTS.lua) | `…` → `Modes` → `LTS` | ModuleScript | last team standing, one life, rounds to win |
| [ServerScriptService/Game/Modes/KOTH.lua](ServerScriptService/Game/Modes/KOTH.lua) | `…` → `Modes` → `KOTH` | ModuleScript | king of the hill (`Zones/Hill`) |
| [ServerScriptService/Hub/HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | `ServerScriptService` → `Hub` (Folder) → `HubServer` | Script | browser registry (MemoryStore), friends, party, play/join teleports, class saving |
| [ServerScriptService/Loadout/Profile.lua](ServerScriptService/Loadout/Profile.lua) | `ServerScriptService` → `Loadout` → `Profile` | ModuleScript | saved classes + stats per player (DataStore) |
| [StarterPlayerScripts/HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `HubMenu` | LocalScript | the menu (M): PLAY · SERVERS · ARMORY · PARTY · SETTINGS, cinematic camera, toasts, invites |

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [StarterPlayerScripts/LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript | now the **class screen**: three class cards with saved loadouts, SPAWN, MENU / ARMORY / SETTINGS buttons; settings moved to the Hub menu |
| [ServerScriptService/Loadout/LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | `ServerScriptService` → `Loadout` → `LoadoutServer` | Script | spawns by class through the game mode (may you spawn, where, which team), tabard, spawn protection, intermission pull-out |
| [StarterPlayerScripts/Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `Scoreboard` | LocalScript | mode · map · clock strip, objective line, team scores, map vote buttons, team colours on the board, TEAMKILLED in the feed |
| [ServerScriptService/Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | `ServerScriptService` → `Scoreboard` | Script | reports deaths to the game mode, profile stats, teamkills get no credit, board resets per round |
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | friendly fire (`GameConfig.FRIENDLY_FIRE`) on swings and kicks, TEAMMATE damage text |
| [StarterCharacterScripts/HUD.client.lua](StarterCharacterScripts/HUD.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `HUD` | LocalScript | TEAMMATE damage number (orange) |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | FOV dial remapped: 70 = the old 110 look, 110 wider still (more FOV + eye pull-back) |
| [ReplicatedStorage/ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | `ReplicatedStorage` → `ClientSettings` | ModuleScript | FOV slider hint/default for the new range |
| [README.md](README.md) | — | doc | placement table + new sections: classes, hub menu, modes / maps / places, teams |

## Removed

| File | Roblox Studio location |
|---|---|
| `ServerScriptService/RoundServer.server.lua` | `ServerScriptService` → `RoundServer` — **delete it** |
