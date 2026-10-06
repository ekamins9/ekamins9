# Updated scripts: an epic training yard, and the training offer for new players

- **You always know where to go:** a light beam and a bobbing arrow stand over your next stop
  (the straw dummy, the drill dummy, the ring, the Drill Master). An arrow at the edge of the
  screen points to it when it's out of view, and the lesson card says GO TO › STRAW DUMMY.
- **The Drill Master has a menu** (E): carry on, start over (walk the whole course again), all
  lessons (pick any to learn or redo), spar in the ring, practice bots, the Gauntlet.
- **The ring lesson's Squire comes to you:** step into the ring and the fight starts. Before,
  nothing happened unless you pressed E at the sign.
- **Drill dummies come and go:** they show up when a lesson needs them and leave (in a puff of
  dust) when nobody's lesson does. The footwork lesson now has a dummy to dodge.
- **The Gauntlet:** wave after wave of bots in the ring, harder each time, until you fall. Your
  best wave is kept, and each new best wave pays 25 Marks (up to wave 20).
- **The practice ground** (north-east, by the ring): call up one to three Squires, Knights or
  Champions at once, as often as you like. There's a sign there too.
- **New players** heading to the Warfront or the Lists (from the menu or the Courtyard's war
  gate) are asked once: "Would you like to complete the training first?"

| File | Studio location | Type | Change |
|---|---|---|---|
| [Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game ▸ Training | ModuleScript | guidance targets, drill dummies on demand, the menu, ring auto-start, the Gauntlet, practice bots |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | the beacon and edge arrow, the menu, practice and gauntlet boards and banners |
| [MapTraining.lua](ServerScriptService/Build/MapTraining.lua) | ServerScriptService ▸ Build ▸ MapTraining | ModuleScript | the practice ground and its sign |
| [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ReplicatedStorage ▸ Catalog ▸ Drills | ModuleScript | the dodge lesson's dummy, the ring lesson's words, `gauntlet` pay |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | `gauntlet`, `askedTraining` |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | `AskedTraining` |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua), [Courtyard.client.lua](StarterPlayerScripts/Courtyard.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the one-time training offer; the war gate goes through the menu |
| [README.md](README.md) | — | docs | the training yard |

**Studio-only:** `ServerStorage ▸ Maps ▸ TrainingYard` was rebuilt (the practice ground). Save the
place.
