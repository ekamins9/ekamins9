# Updated scripts: the menu, rebuilt as a lobby

The Hub menu is rewritten from scratch as a lobby, built like the big Roblox shooters but
for this game. Your party stands on glowing platforms in the middle. Daily tasks and friends
are on the left, the leaderboard and today's shop on the right. A dock of 3D icons runs along
the bottom, and the big green **PLAY** opens the **MODES** board of 3D-scene tiles: Warfront,
Training, Courtyard, 1v1 / 2v2 / 3v3, and Ranked.

New screens:
- **ARMORY** has WEAPONS (each weapon on a stage with its skins, and where each skin comes
  from) and ARMOR (every set worn by you, piece by piece, buy / equip).
- **TASKS** has the daily and weekly tasks, the task-skin track, and mastery.
- **SHOP DAILY** gains the WEAPONS shelf.
- **LOADOUT** lets you try on anything locked.

The crates screen keeps its stage, strip and spinning drum. M closes a pop-up, then a screen,
then the menu. Everything is drawn on a 1600×900 canvas that a UIScale fits to the screen.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | **rewritten**: lobby, MODES, LOADOUT (try-on), ARMORY (weapons + armor), SHOP (daily + shelf, crates, crowns, colors), TASKS, WARDROBE (face grid), SERVERS, SETTINGS; posed 3D scenes; test hooks `Tab` / `ShopTab` / `ArmoryTab` / `OpenCrowns` |
| [Theme.lua](ReplicatedStorage/Theme.lua) | ReplicatedStorage ▸ Theme | ModuleScript | dark-glass palette; GLASS / GLASS2 / OUTLINE / GREEN / BLUE / RED / YELLOW / PURPLE; GO is green |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | auto pieces carry `setName` (the ARMOR tab's set names) |
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ LoadoutMenu | LocalScript | its menu buttons open MENU / LOADOUT / SETTINGS |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | the round strip hides while the menu is up |
| [HUD.client.lua](StarterCharacterScripts/HUD.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ HUD | LocalScript | the bars and weapon chip hide while the menu is up |
| [README.md](README.md) | (docs) | | the menu and the look |

Studio-only (already in the place): the dock icons in `ReplicatedStorage ▸ Cosmetics ▸ Icons`
(Loadout, Armory, Shop, Tasks, Wardrobe, Settings), rendered by `blender/ui_icons.py`.
