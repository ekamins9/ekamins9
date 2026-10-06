# Updated scripts: Siege, Frostgate, battle votes, and the ground fixed on every map

- **Nothing sinks into the ground any more, on any map.** Roblox draws a terrain surface 2 studs
  above where a fill ends, so every map's ground stood at y = 2 and everything built at y = 0 sat
  2 studs deep: walls, the bard, barrels, posts, feet. MapKit's terrain brush now lowers every
  fill by those 2 studs. All maps were rebuilt; in game the ground measures 0.00–0.02 everywhere.
  The Training Yard's sand and Millfield's paths and fields were also thin layers on top (a few
  tenths more); they're whole rows now. Millfield's hill is written voxel by voxel
  (`brush:Mound`) so its top is exactly the windmill's foot.
- **Siege** (after Chivalry 2's Team Objective): attackers push a battering ram up the road; it
  rolls while they outnumber the defenders around it and batters the gate when it gets there.
  Then they take the bailey, storm the great hall, and kill the Jarl, a Champion bot in heavy
  armour, at his throne. Each stage taken adds time, sides swap every round, and the front spawns
  move forward. Reinforcements come in waves. Being at an objective when it falls pays Marks and
  XP.
- **Frostgate**, a snowbound castle for Siege: the camp and road, the gatehouse, the bailey with
  stables, a forge and a well, the great hall with its throne, pines, ruins, a frozen pond, and
  falling snow.
- **Siege HUD:** ATTACK / DEFEND, the stage, a progress bar with what's happening (PUSHING 3 v 1 /
  CONTESTED / BATTERING · GATE 4/10 / CAPTURING 63%), stage pips, a marker over the objective, and
  a banner when a stage falls.
- **The Warfront votes battles:** three cards at the intermission, each a mode on a map (SIEGE ·
  Frostgate, TDM · Millfield…). The round's pay now shows on the board under the result instead
  of a card over the vote.
- **Your old maps are retired:** Arena, Village and Bridge left every mode and moved to
  `ServerStorage ▸ _RetiredMaps`. Every map in play is built from code now: the Courtyard, the
  Training Yard, Sandpit, Highbridge, Millfield and Frostgate.
- Bots fight the other side only (a defenders' champion leaves defenders alone).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Siege | ModuleScript | **new**: ram, gate, capture, champion; stage time; spawns by stage |
| [MapFrostgate.lua](ServerScriptService/Build/MapFrostgate.lua) | ServerScriptService ▸ Build ▸ MapFrostgate | ModuleScript | **new**: the siege castle |
| [MapKit.lua](ServerScriptService/Build/MapKit.lua) | ServerScriptService ▸ Build ▸ MapKit | ModuleScript | the 2-stud terrain fix; `brush:Mound`; `K.objective`, `K.zone`, `K.path`, `K.ram`, `K.gate` |
| [Maps.lua](ServerScriptService/Build/Maps.lua), [MapTraining.lua](ServerScriptService/Build/MapTraining.lua) | ServerScriptService ▸ Build | ModuleScript | Frostgate; flush sand, paths and fields; the mound through the brush |
| [Objectives.client.lua](StarterPlayerScripts/Objectives.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Objectives | LocalScript | **new**: the siege HUD, the marker, the stage banner |
| [Game.lua](ServerScriptService/Game/Game.lua) | ServerScriptService ▸ Game ▸ Game | ModuleScript | rounds remember their start; `waveWait` (reinforcement waves) |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | battle cards (mode + map) on the Warfront; modes can add time |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua), [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | ServerScriptService ▸ Loadout, StarterPlayerScripts | Script / LocalScript | wait for your wave; "REINFORCEMENTS IN n" |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | vote cards; your pay under the result |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | no pay card over a match's intermission |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua), [Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ServerScriptService, ReplicatedStorage ▸ Catalog | Script / ModuleScript | `objective` pay; `_G.RoundBump` |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | bots pick targets on the other side |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua), [SoundConfig.lua](ReplicatedStorage/SoundConfig.lua) | ReplicatedStorage | ModuleScript | Siege; maps without Arena / Village / Bridge; map titles; ram and gate sounds |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | Siege, battle votes, waves, the terrain rules |

**Studio-only:** every map in `ServerStorage ▸ Maps` was rebuilt (and Frostgate is new); Arena,
Village and Bridge are in `_RetiredMaps`. Save the place.
