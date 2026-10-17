# Updated scripts: Siege's attackers get a proper siege camp; bigger volleys

- **Siege**: siege towers, ballistae and a pavilion stand round the attackers' first spawns (where the ground is open and level), facing the castle.
- **Bigger volleys**: the engines' volleys are 120 arrows now (70 before), the distant ones on War's flanks 70 (40): the arrows cost almost nothing since they moved out of the physics world.
- **One prop placer** (new Game ▸ WarProps) shared by War's battlefields and Siege.
- **Checked in Play**: Siege on Frostgate (a tower and two ballistae placed, the uneven spots skipped); every touched script compiled.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarProps.lua](ServerScriptService/Game/WarProps.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | uses WarProps |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the attackers' siege camp |
| [Engines.lua](ServerScriptService/Game/Engines.lua) | ServerScriptService ▸ Game | ModuleScript | 120-arrow volleys |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | bigger distant volleys |
| [README.md](README.md) | | doc | |

---

## Before that: War's camps get made siege towers, ballistae, pavilions and barricades; two more battlefields

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
