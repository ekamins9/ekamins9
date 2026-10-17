# Updated scripts: ballistae you man in War; the engines' kills on the feed

- **Man a ballista**: two a side behind your second banner. Hold E: it swings onto the nearest knot of enemies ahead and looses a bolt that goes through up to three of them; the kills are yours; six seconds to wind. Only your side sees its prompt (and nobody while it winds). Works the same on keyboard, controller and touch.
- **The kill feed names the engines**: "Crown Trebuchet", "Iron Archers", "Crown Battle-Mages".
- **Checked in Play**: War on Redfield: four ballistae rigged, one loosed (it turned onto its target, the bolt flew, it wound and came ready again); every touched script compiled.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | ballistae |
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | where they stand |
| [Engines.lua](ServerScriptService/Game/Engines.lua) | ServerScriptService ▸ Game | ModuleScript | kills on the feed |
| [Engines.client.lua](StarterPlayerScripts/Engines.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the bolt |
| [Prompts.client.lua](StarterPlayerScripts/Prompts.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | a side's own prompt |
| [README.md](README.md) | | doc | |

---

## Before that: Siege's attackers get a proper siege camp; bigger volleys

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
