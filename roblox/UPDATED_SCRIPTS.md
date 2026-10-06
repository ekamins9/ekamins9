# Updated scripts: smarter bots, real class tradeoffs, weapon stats, the Rose Court

- **Bots play by your rules.** They move at a player's speed for their armor and weapon (slower
  sideways and backwards, a sprint only to close distance; they used to strafe twice as fast as
  you could), turn no faster than you while swinging, and use the same stamina.
- **Bots are smarter.** They time a parry so your blade lands mid-window and learn how long each
  of your attacks takes to land; riposte after their own parries; feint or morph when you raise
  your guard early; combo after a hit; kick a guard held too long; punish whiffs; press you when
  you're low on stamina; keep stamina in reserve and back off to get it back. Disarmed, they draw a
  spare or go and pick a weapon up. Each rank has its own armor: levy cloth for Squires, mail and
  surcoats for Knights, black-and-blood plate for Champions.
- **Classes trade real things.** Heavy keeps its armor edge, but at about 1.4× a Light's staying
  power instead of 2×, and it pays for it: slower, a weaker sprint, less stamina that comes back
  slower, dear and short dodges. Light is fastest, has the most stamina and long cheap dodges.
  The class cards show HP / ARMOR / SPEED / STAMINA.
- **Stamina:** a clean hit gives its swing's stamina back (a blocked or parried one doesn't); a
  whiff costs half again (was 75%); a held guard pays 80% of the block cost; regen is 17/s from
  1.3 s (was 15/s from 1.8 s).
- **Weapons:** big two-handers no longer make you *faster*; armor penetration gives blunt weapons
  and armor-piercing points their niche against plate; the Shortsword is quicker. The Armory shows
  every weapon's stats as bars against the rest.
- **Armory:** an OWNED ONLY filter (on by default; tap to see everything you can get).
- **Hatchery:** SET AN EGG opens your egg inventory to pick from (buy a missing one right there);
  YOUR EGGS shows every kind and how many you hold. Eggs already ripen while you're offline.
- **Kill effects** wait 1.2 s: the body falls (and a cut-off head rolls) first; the effect plays
  upright over the body.
- **First person:** your arm armor (sleeves, gauntlets) shows; a piece swung into the camera
  hides until it's clear.
- **Training countdowns:** you're held on your mark (no walking, swings, kicks, dodges or hops)
  with full stamina until FIGHT, and the bots start on the same tick. Gauntlet waves put you back
  on your mark and refill your stamina; Horde breaks refill stamina and a quarter of your health.
- **The Rose Court:** a walled rose garden for 1v1–3v3 duels (the Lists and the Duel Yard).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Combat/Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | rewritten: player speed rules, turn cap, reflexes (learned parry timing, ripostes, feints, morphs, combos, chambers), stamina reserve, spacing, re-arming, rank looks |
| [Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | stamina ledger (full refund on a clean hit, whiff 0.5×, regen 17 from 1.3 s, `BLOCK_COST_MULT`), `ARMOR_PEN`, stamina bar × the weight's `StaminaMult` / `RegenMult`, snapshot timings |
| [Combat/Pickup.lua](ServerScriptService/Combat/Pickup.lua) | ServerScriptService ▸ Combat ▸ Pickup | ModuleScript | `takeNpc`, `nearest` (bots pick weapons up) |
| [Catalog/Weights.lua](ReplicatedStorage/Catalog/Weights.lua) | ReplicatedStorage ▸ Catalog ▸ Weights | ModuleScript | the rebalance: health, armor, speed, sprint, stamina, regen, dodges |
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | publishes the weight's StaminaMult / RegenMult / SprintMult / DodgeCost / DodgeReach |
| [MovementServer.server.lua](ServerScriptService/MovementServer.server.lua) | ServerScriptService ▸ MovementServer | Script | sprint and dodge cost by weight |
| [Movement.client.lua](StarterCharacterScripts/Movement.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ Movement | LocalScript | dodge reach by weight; no hop / dodge / kick while held |
| [Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | no attacks while held on your mark |
| [CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | ServerScriptService ▸ CharacterSystems | Script | unarmed regen defaults (17 / 1.3 s) |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | publishes `ReplicatedStorage ▸ WeaponStats` |
| [Tools/*/Config.lua](Tools) (26) | ServerStorage ▸ Weapons ▸ * ▸ Config | ModuleScript | walk speed while held, `ARMOR_PEN`, Shortsword tempo (generated) |
| [../scripts/gen_content.py](../scripts/gen_content.py) | — | generator | the weapon table's speeds, `PEN` |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | Armory OWNED ONLY filter and STATS card; class bars and weight lines; egg picker and egg grid |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | class descriptions; the Rose Court in the Lists and the Duel Yard |
| [Hub/Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua) | ServerScriptService ▸ Hub ▸ Cosmetics | Script | kill effect 1.2 s after the death |
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Cosmetics | LocalScript | kill effect upright over the fallen body |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | arm armor in first person |
| [Game/Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game ▸ Training | ModuleScript | countdown hold, bots on FIGHT, stamina between waves |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | 3-2-1 counted to the server's start time |
| [Game/Modes/Horde.lua](ServerScriptService/Game/Modes/Horde.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Horde | ModuleScript | stamina and a quarter of health back between waves |
| [Build/MapRoseCourt.lua](ServerScriptService/Build/MapRoseCourt.lua) | ServerScriptService ▸ Build ▸ MapRoseCourt | ModuleScript | **new**: the Rose Court |
| [Build/Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | the Rose Court |

`.gitignore`: `build/` is now `/build/` (it matched the `Build` scripts folder on Windows, so new
map files there were silently left out).

**Studio-only:** `ServerStorage ▸ Maps ▸ RoseCourt` is new. Save the place.
