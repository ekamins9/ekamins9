# Updated scripts: cheaper bots far from players; War fields 32

- **Stress test** (War, 46 bots held): Studio's shared server fell to about 24 fps; with the cap free, it stepped itself down 46 → 38 → 34 → 30 as designed. War now fields 32 by default for headroom.
- **Bots no player is near** (90 studs) watch for parries every third frame and think five times a second instead of ten: nobody sees those fights, and both sides are treated the same.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat | ModuleScript | far bots cheaper |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | War botFill 32 |
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | default cap 32 |
| [README.md](README.md) | | doc | |

---

## Before that: ballistae you man in War; the engines' kills on the feed

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
