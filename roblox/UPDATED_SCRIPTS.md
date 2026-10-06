# Updated scripts: a peaceful Courtyard, bots, the new training yard

- **No fighting in the Courtyard.** The Hub and the training yard are peaceful
  (`GameConfig.MODES.<id>.pvp = false`): one player's hits and kicks can't touch another's.
  Dummies and bots can still be hit, and a bot can hit you. Swinging at someone in the Courtyard
  shows a short notice once in a while.
- **Bots** (`Combat ▸ Bots`): AI fighters on the real combat system (a normal weapon in NPC mode).
  They close in, circle at sword's length, swing, stab and do overheads, step in to land, block
  and parry your windups (better at higher skill), feint and morph (Knight, Champion), and kick a
  turtle. Squire / Knight / Champion, plus two training dummies. Clients animate their walk
  (`NpcAnimator`). Studio: `/bot Knight Longsword`, `/bot clear`.
- **The Training Yard** — a new map (built from code; it replaces the old Tiltyard map): a
  palisaded field below a castle wall. It has the Drill Master's platform and a lesson circle with
  log benches, six straw dummies, pells, a roped sparring ring with a challenge sign, tents, a
  weapon cart, racks, archery butts and torches.
- **The Drill Master** (Sir Aldric): 13 lessons (`Catalog ▸ Drills`), from the swing, stab and
  overhead to both sides, the block, parry, riposte, feint, morph, kick, dodge and chamber, ending
  with a first win in the ring. They're checked from the combat signals; a card shows each lesson
  in your own key binds and he says it aloud. Each first finish pays a drill (Marks + XP), which
  counts for tasks and the Drill Master title.
- **The sparring ring:** challenge a Squire, Knight or Champion bot. After a 3-2-1 it's a fight to
  the death, and leaving the ring forfeits. A first win at each level pays 100 / 250 / 600 Marks,
  later wins pay a little, and wins are kept.
- **Readable names on screen:** the mode reads "Training Yard" and maps get titles
  (`GameConfig.MAP_TITLES`, Round attribute `MapName`).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | **new**: AI fighters |
| [R6.lua](ServerScriptService/Combat/R6.lua) | ServerScriptService ▸ Combat ▸ R6 | ModuleScript | **new**: a plain R6 rig from parts |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | `peaceful()`; LastHitAttack, FeintTick, MorphTick, KickTick for the lessons |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | the Courtyard's no-fighting notice |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | `pvp = false` for the Hub and the yard; the yard's map and name; `MAP_TITLES` |
| [Game.lua](ServerScriptService/Game/Game.lua), [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game | ModuleScript / Script | Round `Peaceful` and `MapName` |
| [Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game ▸ Training | ModuleScript | **new**: dummies, the Drill Master, lessons, the sparring ring |
| [Tiltyard.lua](ServerScriptService/Game/Modes/Tiltyard.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Tiltyard | ModuleScript | starts and stops Training |
| [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ReplicatedStorage ▸ Catalog ▸ Drills | ModuleScript | **new**: the lessons and ring rewards |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua), [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ReplicatedStorage ▸ Catalog, ServerScriptService ▸ Loadout | ModuleScript | `DRILLS`; profile `drills`, `spars` |
| [MapKit.lua](ServerScriptService/Build/MapKit.lua), [Maps.lua](ServerScriptService/Build/Maps.lua), [MapTraining.lua](ServerScriptService/Build/MapTraining.lua) | ServerScriptService ▸ Build | ModuleScript | `K.spot`, `K.palisade`, `K.rope`, `K.rack`, `K.torchPost`; **new** map module |
| [Cheats.server.lua](ServerScriptService/Hub/Cheats.server.lua) | ServerScriptService ▸ Hub ▸ Cheats | Script | `/bot` |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | **new**: lesson card, lesson board, his bubble, ring board, banners |
| [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ NpcAnimator | LocalScript | **new**: bots' walk |
| [HubMenu](StarterPlayerScripts/HubMenu.client.lua), [LoadoutMenu](StarterPlayerScripts/LoadoutMenu.client.lua), [Scoreboard](StarterPlayerScripts/Scoreboard.client.lua), [TravelScreen](StarterPlayerScripts/TravelScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | show `MapName` |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | (docs) | | the training yard, bots, peaceful modes, spots |

Studio-only: `ServerStorage ▸ Maps ▸ TrainingYard` (built by `Build ▸ Maps.build("TrainingYard")`).
Save the place so it stays.
