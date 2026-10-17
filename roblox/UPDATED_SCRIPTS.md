# Updated scripts: siege engines in Siege too, a cinematic opening for every battle

- **Siege goes to war**: the attackers' trebuchets beyond the walls lob fire onto the defenders at the objective (a red ring first), and both sides' archers loose volleys at each other near it (raise your guard or get under a roof). War's engines became a shared module so any mode can have them.
- **Every battle opens like a film**: your first spawn of a round in Siege, Team Deathmatch, King of the Hill, Free-for-All, Last Team Standing or Horde flies the camera from the map's own shot down behind you, with the mode, the map and what you're there to do (TAKE THE CASTLE / HOLD THE CASTLE…), a horn, black bars. Any key skips.
- **Checked in Play**: Siege on Frostgate: the engines set up from the map's spawns (two trebuchets and two archer companies for the attackers, a company on the walls for the defenders) and fired at knots of the other side near the objective; every touched script compiled.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Engines.lua](ServerScriptService/Game/Engines.lua) | ServerScriptService ▸ Game | ModuleScript | new: trebuchets, volleys, barrages for any mode |
| [Engines.client.lua](StarterPlayerScripts/Engines.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new: draws them, warns you |
| [MatchIntro.client.lua](StarterPlayerScripts/MatchIntro.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | uses Engines |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the armies' part only |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the war round it |
| [README.md](README.md) | | doc | |

---

## Before that: WAR, the massive battle

- **A new mode on the Play screen's first tile: WAR.** Two armies, players and 36 bots side by side, on a battlefield built fresh each round: five banners to take one by one as a front, reinforcements that bleed away, trebuchets with red warning rings, archer volleys (raise your guard or get under a roof), battle-mages' meteor storms, chain lightning and frost, and cavalry charges.
- **The rest of both armies clash on the flanks**: hundreds of soldiers in regiments (foot, pikes, archers, battle-mages) marching to the front and fighting there, drawn on your screen only, so the server never pays for them.
- **Five battlefields**: Redfield, Ironridge, Frostmere, Ashvale, Kingsbridge, each with its own place in the middle (a village and windmill, a ruined fort, a frozen lake, burning farmsteads, a river with bridges and a ford), weather and light. Vote pictures for each.
- **The HUD**: reinforcements, the clock, the banners as chips, what's happening at your banner, big calls and warnings; an opening flight over the field the first time you spawn in a round.
- **Optimized**: the crowds live under the camera, outside the physics world, and only move when they must. Measured: from 13 fps to 53 fps in the heaviest view. The bot count follows the server's frame rate.
- **Horde moved to the Adventures page** (WAR took its place); Powers.client: a swirling zone's inverted speed range fixed.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | new |
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | armies, strikes, frost, weather, the crowd folder |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | DOORS / MODES War, maps, titles, fighters |
| [BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game | ModuleScript | a mode's botTarget |
| [MapKit.lua](ServerScriptService/Build/MapKit.lua) | ServerScriptService ▸ Build | ModuleScript | K.terrain `fast` |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the WAR tile and scene; Horde to the adventures |
| [Powers.client.lua](StarterPlayerScripts/Powers.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | range fix |
| [README.md](README.md) | | doc | War |

Studio-only (save the place): ReplicatedStorage ▸ MapShots ▸ Redfield, Ironridge, Frostmere, Ashvale, Kingsbridge.

---

## Before that: the Siege of Stormwatch, a new player's first battle

- **A brand-new player starts in a battle**: a dark, stormy night, the Iron Host at the gate of Stormwatch. They learn every move in the middle of it: swing, stab and overhead on raiders over the wall, dodging trebuchet fire, block / parry / riposte against a raider through the breach, kicking a brute's guard open, running the gauntlet of arrows to the gate, holding the gate beside the garrison, and a duel with Lord Varg, the Host's champion.
- **Cutscenes**: the opening (the storm, the camp, a fireball into a tower, Captain Hale), the ram breaking the gate, Lord Varg's entrance, dawn and the King's riders. Black bars, a flying camera, subtitles, title cards; any of them can be skipped.
- **The war all round you** (new WarFX): rain that stops under a roof, lightning and thunder, volleys of arrows arcing over the walls and sticking in the cobbles, trebuchet fire and its blasts, war cries, the battle's roar and its own score.
- **The screen**: a lesson card in your own controls, the captain's lines, a beacon over where to go (and an edge arrow when it's behind you), M to pause or skip, an end card with a welcome purse (300 Marks, 250 XP, once).
- **Fixes found while testing**: the over-the-shoulder camera pressed against a wall showed the inside of your own helmet (it now hides the head, CameraRig); a dungeon panel showed empty in other modes with their own HUD; the scoreboard strip doubled up over a mode's own top.
- **Checked in Play**: the whole story start to finish (each lesson's signal, the bombardment hurting and knocking back, the breach, the battle with the garrison, Varg's boss bar, dawn, the end card and its purse); every touched script compiled in Studio.
- **Studio-only (save the place)**: ReplicatedStorage ▸ WarAudio (the sounds), ServerStorage ▸ PrologueProps ▸ Trebuchet.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Prologue.lua](ServerScriptService/Game/Modes/Prologue.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | new |
| [StormwatchMap.lua](ServerScriptService/Game/StormwatchMap.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Prologue.client.lua](StarterPlayerScripts/Prologue.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | new |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | DOORS / MODES Prologue, Stormwatch |
| [Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | the prologue's purse |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub | Script | a newcomer's training is the Prologue |
| [Intro.client.lua](StarterPlayerScripts/Intro.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | a newcomer goes straight to the siege |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts | LocalScript | no helmet-inside view against walls |
| [Music.client.lua](StarterPlayerScripts/Music.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `_G.OwnScore` |
| [Hotbar.client.lua](StarterPlayerScripts/Hotbar.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | hides for a cutscene |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `OwnTop` |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | its panel only in the dungeon |
| [README.md](README.md) | | doc | the Siege of Stormwatch |
