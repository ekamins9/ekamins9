# Updated scripts: the new Courtyard

The hub is rebuilt from code (`Build ▸ MapCourtyard`). The old free-model Courtyard was moved to
`ServerStorage ▸ _RetiredMaps` and is no longer used. It's still peaceful, with new places to visit:

- **The Hall of Champions** (north, before the keep): statues of the season's top three in
  Warfront kills. Each wears the player's own armor and weapon and strikes an emote pose (war cry,
  salute, champion). They're cast in gold, silver and bronze, larger than life, with plaques.
  Beside them, two boards list the most kills (top 10) and the top three of each ranked Lists
  bracket. Refreshes every 3 minutes.
- **The wishing fountain** (middle): hold E for one free wish a day (`Catalog ▸ Gifts ▸ wishes`:
  Marks, eggs, a few Crowns). A coin arcs into the water with a splash, and everyone sees the luck
  float over the wisher's head. A second wish tells you when to come back.
- **The Gates of War** (south): three arches. E at Training Yard or Warfront travels there; E at
  The Lists opens PLAY's mode board to pick a bracket.
- **The Merchant's Stall**: today's packs on two mannequins and today's skins on the weapon rack,
  updated each day. E opens the SHOP.
- **The Notice Board** (where you arrive): your own daily and weekly tasks with progress bars,
  the next playtime gift and your pass tier, written on the parchment for you alone. E opens
  TASKS.
- **The tavern and a bard** who plays the lute; benches round the fountain you can sit on; the
  Hatchery moved to the west side (`HatcherySpot`); a stone circle to the east.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapCourtyard.lua](ServerScriptService/Build/MapCourtyard.lua) | ServerScriptService ▸ Build ▸ MapCourtyard | ModuleScript | **new**: the hub map (walls, towers, gatehouse, keep, hall, fountain, gates, stall, tavern, notice board, spots) |
| [Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | `Maps.Courtyard()`; built with the others |
| [Courtyard.server.lua](ServerScriptService/Hub/Courtyard.server.lua) | ServerScriptService ▸ Hub ▸ Courtyard | Script | **new**: statues, plaques, boards, the stall, gates, the wish, the bard |
| [Leaderboards.lua](ServerScriptService/Hub/Leaderboards.lua) | ServerScriptService ▸ Hub ▸ Leaderboards | ModuleScript | **new**: board rows, names, a player's saved look |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | the menu's leaderboard reads `Leaderboards` |
| [Courtyard.client.lua](StarterPlayerScripts/Courtyard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Courtyard | LocalScript | **new**: gate/stall/board prompts, your notice board, the wish's coin and splash |
| [Pastimes.lua](ServerScriptService/Economy/Pastimes.lua) | ServerScriptService ▸ Economy ▸ Pastimes | ModuleScript | `Pastimes.wish` (once per UTC day) |
| [Catalog/Gifts.lua](ReplicatedStorage/Catalog/Gifts.lua) | ReplicatedStorage ▸ Catalog ▸ Gifts | ModuleScript | `wishes` (weighted rewards) |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | `wishDay` |
| [Emotes.lua](ReplicatedStorage/Emotes.lua) | ReplicatedStorage ▸ Emotes | ModuleScript | the render loop only runs on clients (statues pose on the server) |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | the Courtyard; wishes |

**Studio-only:** `ServerStorage ▸ Maps ▸ Courtyard` is the built map (rebuild with
`require(ServerScriptService.Build.Maps).Courtyard()` in the command bar). Save the place so it
stays.
