# Updated scripts: War's camps get made siege towers, ballistae, pavilions and barricades; two more battlefields

- **Made props in every War battlefield** (generated models, Studio-only): a striped command pavilion in each camp, siege towers parked before the camps with their ramps towards the enemy, ballistae at the camps' corners, spiked barricades before the camps and as cover beside banners 2 and 4.
- **Nightfall**: a moonlit battle, torches lining the field, a burning watchtower, standing stones. **Sunreach**: a desert valley with a ruined sandstone temple, obelisks and dunes. Both with vote pictures.
- **Fixes**: the banner plinths and the battle-mages' sigils stood on edge (a cylinder turned twice); the match intro no longer repeats the FIGHT! banner's mode and map, and the HUD steps aside while it plays (Celebrate, MatchIntro: the last commit).
- **Checked in Play**: Nightfall and Sunreach built and shot; each prop seen in place (top-down for which way it faces).

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | made props, Nightfall, Sunreach, fixes |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | War's maps |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the new banners' names |
| [MatchIntro.client.lua](StarterPlayerScripts/MatchIntro.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | (last commit) |
| [Celebrate.client.lua](StarterPlayerScripts/Celebrate.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | (last commit) `_G.FightBannerAt` |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ServerStorage ▸ WarProps (Pavilion, SiegeTower, Ballista, Barricade); ReplicatedStorage ▸ MapShots ▸ Nightfall, Sunreach.

---

## Before that: the dungeon game feels part of the main game; one clear way back

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
