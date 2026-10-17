# Updated scripts: the dungeon game feels part of the main game; one clear way back

- **◀ MAIN MENU** top left of the dungeon lobby (and on the Gilded Rat's walking-about bar) replaces the red TO THE COURTYARD: one question (your stash, kit and gold stay safe), then you're home and the main menu opens by itself.
- **The main game's numbers in the lobby**: your level, Marks and Crowns beside the vault's gold, so a run reads as part of your progress.
- **Fixes found while testing**: coming home in the same session left the main menu shut (it only reopened after a death), and the dungeon lobby stayed drawn over the main menu; both fixed. A dungeon lobby at the 200-locals limit, folded.
- **Checked in Play**: into the Gilded Rat (the new top bar), home again (the lobby shut, the main menu up).

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMenu.client.lua](StarterPlayerScripts/DungeonMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ◀ MAIN MENU, the wallet, shuts outside the Gilded Rat |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | opens by itself on coming home |
| [README.md](README.md) | | doc | |

---

## Before that: siege engines in Siege too, a cinematic opening for every battle

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
