# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change: the whole menu / cosmetics / economy system.** Doors (Courtyard · Tiltyard ·
Warfront · The Lists), parties of 3 with **ready-up**, matchmaking queue + ranked ratings,
appearance (hair / beard / face / skin / hair color / title), weight-based classes with
helmet / top / bottom pieces and color blocks, weapon unlocks + skins, the shop (crates with
odds / pity / duplicate refunds, packs, premium colors, GET CROWNS with Robux products and
Crowns → Marks), custom servers with every setting (cheats → host commands, no rewards), end-of-
round pay, daily / weekly contracts, mode votes on the Warfront. **Adding content is config
only — read [CONTENT_GUIDE.md](CONTENT_GUIDE.md).**

## Studio setup (once)

1. `ReplicatedStorage` → make a ModuleScript **`Catalog`** (paste `Catalog.lua`), then make
   these ModuleScripts **as children of it**: `Weights`, `Packs`, `Pieces`, `Weapons`, `Skins`,
   `Body`, `Palette`, `Crates`, `Economy`, `Contracts` (from `ReplicatedStorage/Catalog/*.lua`).
2. `ReplicatedStorage` → ModuleScript **`Dresser`**.
3. `ServerScriptService` → Folder **`Economy`** with ModuleScripts `Economy`, `Stats` and Script
   `EconomyServer`.
4. `ServerScriptService` → `Hub` → add ModuleScript **`Matchmaker`** and Script **`Cheats`**.
5. `ServerScriptService` → `Game` → `Modes` → add ModuleScripts **`Lists`** and **`Tiltyard`**.
6. Replace every file in the table below. Delete `ServerScriptService` → `Loadout` → `Armor` if
   you like (`Dresser` replaced it; `TestDummies` still works either way).
7. Give your weapons' blade / grip parts an attribute `SkinPart` = `"Blade"` / `"Grip"` so skins
   tint them, and put a display copy of each weapon in `ReplicatedStorage` → `Cosmetics` →
   `Weapons` → `<ToolName>` (a Model with a `Handle`) for the menu mannequin. `Cosmetics` and
   its folders are created by the server on first run.
8. For Robux Crowns: make Developer Products and paste the ids into `Catalog ▸ Economy`.

Profiles move to DataStore `Profiles_v2`; old v1 saves migrate on first load.

## New files

| File | Roblox Studio location | Type | What it is |
|---|---|---|---|
| [ReplicatedStorage/Catalog.lua](ReplicatedStorage/Catalog.lua) | `ReplicatedStorage` → `Catalog` | ModuleScript | the content catalog (auto-imports armor sets as pieces) |
| [ReplicatedStorage/Catalog/Weights.lua](ReplicatedStorage/Catalog/Weights.lua) | `Catalog` → `Weights` | ModuleScript | Light / Medium / Heavy stats |
| [ReplicatedStorage/Catalog/Packs.lua](ReplicatedStorage/Catalog/Packs.lua) | `Catalog` → `Packs` | ModuleScript | packs |
| [ReplicatedStorage/Catalog/Pieces.lua](ReplicatedStorage/Catalog/Pieces.lua) | `Catalog` → `Pieces` | ModuleScript | explicit pieces (usually empty) |
| [ReplicatedStorage/Catalog/Weapons.lua](ReplicatedStorage/Catalog/Weapons.lua) | `Catalog` → `Weapons` | ModuleScript | weapons + unlocks |
| [ReplicatedStorage/Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua) | `Catalog` → `Skins` | ModuleScript | weapon skins |
| [ReplicatedStorage/Catalog/Body.lua](ReplicatedStorage/Catalog/Body.lua) | `Catalog` → `Body` | ModuleScript | hair, beards, faces, skin, hair colors, titles |
| [ReplicatedStorage/Catalog/Palette.lua](ReplicatedStorage/Catalog/Palette.lua) | `Catalog` → `Palette` | ModuleScript | armor colors |
| [ReplicatedStorage/Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | `Catalog` → `Crates` | ModuleScript | crates |
| [ReplicatedStorage/Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | `Catalog` → `Economy` | ModuleScript | earn table, products, exchange, levels, ranks |
| [ReplicatedStorage/Catalog/Contracts.lua](ReplicatedStorage/Catalog/Contracts.lua) | `Catalog` → `Contracts` | ModuleScript | contracts |
| [ReplicatedStorage/Dresser.lua](ReplicatedStorage/Dresser.lua) | `ReplicatedStorage` → `Dresser` | ModuleScript | dresses a character / mannequin: pieces, colors, body, skins |
| [ServerScriptService/Economy/Economy.lua](ServerScriptService/Economy/Economy.lua) | `ServerScriptService` → `Economy` (Folder) → `Economy` | ModuleScript | awards, buying, crates, exchange, products |
| [ServerScriptService/Economy/Stats.lua](ServerScriptService/Economy/Stats.lua) | `ServerScriptService` → `Economy` → `Stats` | ModuleScript | counters, contracts, earned skins |
| [ServerScriptService/Economy/EconomyServer.server.lua](ServerScriptService/Economy/EconomyServer.server.lua) | `ServerScriptService` → `Economy` → `EconomyServer` | Script | Robux receipts (`ProcessReceipt`) |
| [ServerScriptService/Hub/Matchmaker.lua](ServerScriptService/Hub/Matchmaker.lua) | `ServerScriptService` → `Hub` → `Matchmaker` | ModuleScript | The Lists queue (MemoryStore), pairing, match records |
| [ServerScriptService/Hub/Cheats.server.lua](ServerScriptService/Hub/Cheats.server.lua) | `ServerScriptService` → `Hub` → `Cheats` | Script | host commands on cheat servers |
| [ServerScriptService/Game/Modes/Lists.lua](ServerScriptService/Game/Modes/Lists.lua) | `ServerScriptService` → `Game` → `Modes` → `Lists` | ModuleScript | arena matches: sides from the matchmaker, best of 5, forfeit |
| [ServerScriptService/Game/Modes/Tiltyard.lua](ServerScriptService/Game/Modes/Tiltyard.lua) | `…` → `Modes` → `Tiltyard` | ModuleScript | the training yard |
| [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | doc | **how to add sets, pieces, packs, weapons, skins, crates, body models, colors, products, contracts, maps** |

## Replaced files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ReplicatedStorage/GameConfig.lua](ReplicatedStorage/GameConfig.lua) | `ReplicatedStorage` → `GameConfig` | ModuleScript | `DOORS`, `DOOR_ORDER`, `PARTY_MAX`, modes `Tiltyard` + `Lists`, classes have `weight`, `CUSTOM_DEFAULTS` |
| [ServerScriptService/Loadout/Profile.lua](ServerScriptService/Loadout/Profile.lua) | `ServerScriptService` → `Loadout` → `Profile` | ModuleScript | profile v2: wallet, level, appearance, owned, piece loadouts, ratings, crates, contracts; validation |
| [ServerScriptService/Loadout/LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | `ServerScriptService` → `Loadout` → `LoadoutServer` | Script | mirrors sets into Cosmetics, dresses through `Dresser`, weapon skins, no-respawn servers |
| [ServerScriptService/Hub/HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | `ServerScriptService` → `Hub` → `HubServer` | Script | doors, party **ready-up** (`PartyReady` / `PartyKick`), queue, custom settings, shop ops, leaderboards, profile pushes, match-over send-home |
| [ServerScriptService/Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | `ServerScriptService` → `Scoreboard` | Script | round-end pay (`Economy.award` → "Rewards"), stats + contracts, ranked Elo + `LB_<bracket>` / `LB_Warfront` boards, ranked queue lock on leave |
| [ServerScriptService/Game/Game.lua](ServerScriptService/Game/Game.lua) | `ServerScriptService` → `Game` → `Game` | ModuleScript | server identity: door, bracket, ranked, sides, custom settings; no-respawn rule; `roundLength` |
| [ServerScriptService/Game/GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | `ServerScriptService` → `Game` → `GameServer` | Script | Warfront **mode vote** (`ModeVote1..3`), `VoteRemote ("mode"|"map", i)`, per-round attributes (`FriendlyFire`, `NoRewards`, `Door`, `Bracket`, `Ranked`, `ServerName`), `MatchOver` |
| [ServerScriptService/Game/Teams.lua](ServerScriptService/Game/Teams.lua) | `ServerScriptService` → `Game` → `Teams` | ModuleScript | no tabard when the armor is team-painted |
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | friendly fire off on custom servers; reports parries / chambers to `_G.StatHook` |
| [StarterPlayerScripts/HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `HubMenu` | LocalScript | **the whole new menu** (PLAY · APPEARANCE · CLASSES · SHOP · SERVERS · SETTINGS, mannequins, ready-up, queue, crates drum, custom panel) |
| [StarterPlayerScripts/Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `Scoreboard` | LocalScript | mode vote buttons, bracket / ranked / no-rewards strip, match over |
| [StarterPlayerScripts/LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript | class cards show helm · top · legs · weapon (skin) |
| [README.md](README.md) | — | doc | classes / pieces / Dresser, the new menu, money + ranked, armor sets, placement table |

## Remotes (for reference)

`HubRemote` ops: `State`, `Servers`, `Friends`, `Leaderboard(which)`, `Play(door, {bracket, ranked, mode})`,
`Hub`, `Custom(settings)`, `Join(jobId)`, `JoinFriend(userId)`, `QueueCancel`, `PartyCreate`,
`PartyInvite(id)`, `PartyAccept`, `PartyLeave`, `PartyReady(bool)`, `PartyKick(id)`,
`SaveClass(classId, loadout)`, `SetActive(classId)`, `SaveAppearance(app)`,
`Buy(kind, id, currency)`, `OpenCrate(crateId)`, `Exchange(tier)`, `BuyCrowns(index)`.
`HubEvent` to the client: `Party`, `Toast`, `Invite`, `Profile`, `Travel`, `TravelFailed`,
`MatchFound`, `Rewards`.
