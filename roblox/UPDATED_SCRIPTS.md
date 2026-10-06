# Updated scripts: Season Pass and login rewards

- **Season Pass** ("Season 1 · The Iron Crown"): 30 tiers, climbed with every round's XP plus
  400 pass XP per finished daily task (1,200 for the weekly). The free track is everyone's.
  The premium track costs 600 Crowns, applies to tiers already reached, and holds 9 exclusive
  trimmed skins and the title "Crowned". Claim tier by tier or with CLAIM ALL; free crate
  opens are rolled on the server. There is a PASS dock tile with a badge for waiting rewards.
- **Login rewards**: a pop-up on the first open of each day, seven days in a row, with the
  streak broken by a missed day.
- 12 new pass skins (`pass = true`), which can't be bought.
- Testing cheat (Studio only): `/passxp <n>`.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Catalog/Pass.lua](ReplicatedStorage/Catalog/Pass.lua) | ReplicatedStorage ▸ Catalog ▸ Pass | ModuleScript | **new**: the season, price, XP and 30 tiers |
| [Catalog/Login.lua](ReplicatedStorage/Catalog/Login.lua) | ReplicatedStorage ▸ Catalog ▸ Login | ModuleScript | **new**: the seven daily gifts |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `Catalog.PASS` / `Catalog.LOGIN`; skin source "pass"; reward checks |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | regenerated with the 12 pass skins |
| [Economy.lua](ServerScriptService/Economy/Economy.lua) | ServerScriptService ▸ Economy ▸ Economy | ModuleScript | `grantReward`, pass state / XP / claim / claim-all / buy, login status / claim, free crate opens; round XP climbs the pass |
| [Stats.lua](ServerScriptService/Economy/Stats.lua) | ServerScriptService ▸ Economy ▸ Stats | ModuleScript | a finished task adds pass XP |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | `pass` and `login` records |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | State carries pass + login; ops PassClaim, PassClaimAll, PassBuy, LoginClaim |
| [Cheats.server.lua](ServerScriptService/Hub/Cheats.server.lua) | ServerScriptService ▸ Hub ▸ Cheats | Script | `/passxp <n>` |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | PASS screen, login pop-up, PASS dock tile + badge, pass skins' source text |
| [gen_content.py](../scripts/gen_content.py) | (repo only) | script | `PASS_SKINS` |
| [ui_icons.py](../blender/ui_icons.py) | (repo only) | Blender script | the PASS icon (a crowned banner) |
| [CONTENT_GUIDE.md](CONTENT_GUIDE.md), [README.md](README.md) | (docs) | | the pass and the login gifts |

Studio-only: `ReplicatedStorage ▸ Cosmetics ▸ Icons ▸ Pass` (the dock icon decal).
