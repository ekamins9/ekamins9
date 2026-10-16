# Updated scripts: Dragonfall, a dragon raid for you and your party

- **Dragonfall** (new mode, a party door on the Play menu's Adventures page, 1 – 6): **Cindermaw, the Ashen Wyrm**, in its burning caldera.
  - **The Ashen Caldera** (new CalderaMap, built fresh): cracked basalt with glowing seams round an old paved ring, black cliffs with lava running down them into pools, lava pools on the floor (they burn), six ward stones with glowing runes, four ballistae on platforms, the bones of something huge, the swords and shields of those who came before, ash falling, a burning dusk. Vote picture: MapShots ▸ Caldera.
  - **The fight**: on the ground it bites, claws, sweeps its tail, beats its wings, stomps, charges and breathes fire across the ground. At two thirds it **takes to the sky** (strafing fire, fireballs) and its **brood** climbs out of the lava; **man the ballistae** (hold to fire; guides over them) and three bolts bring it **crashing down**, open to everyone. Under a third it's **enraged**, fire rains, and its **Inferno** burns whoever it can see: get behind a **ward stone** (they light up and are marked as it winds up).
  - **Win**: everyone there is paid (`dragon_slain`), counted, and your fastest kill kept. The clock (14 min) runs out first: it holds the caldera.
- **The dragon's body on your screen** (new Dragon client script): its walk, wingbeats, tail whips, jaw, head tracking you, and fire streaming from its mouth, all from what the server says it's doing. Ragdolls, corpses and kill effects leave it alone.
- **The Depths' floors get the dungeon grime too** (cracks, rubble, cobwebs, damp, cages, candles, dust).
- **Checked in Play**: the caldera built (561 parts); the dragon came down, walked, charged, took to the sky at two thirds, its brood came out of the lava, three ballista bolts crashed it, it lay downed, enraged at a third, rose for an Inferno with the ward stones marked, died, and the fight was won; the Play menu's Dragonfall tile opens it (no longer "coming soon"); compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dragonfall.lua](ServerScriptService/Game/Modes/Dragonfall.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | new |
| [CalderaMap.lua](ServerScriptService/Game/CalderaMap.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Dragon.lua](ServerScriptService/Combat/Dragon.lua) | ServerScriptService ▸ Combat | ModuleScript | new: the dragon |
| [Dragon.client.lua](StarterPlayerScripts/Dragon.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new: its joints and fire |
| [CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | ServerScriptService | Script | a CustomBody gets no ragdoll setup |
| [Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua) | ServerScriptService ▸ Hub | Script | no kill effect on a CustomBody |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game | Script | the dragon's still copy for the menu |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | DOORS / MODES Dragonfall, its map title, the Adventures order |
| [Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `dragon_slain` |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | guides over Map ▸ Ballistae / Wards (GuideText) |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the Dragonfall tile's scene |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | grime on every floor |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ MapShots ▸ Caldera (the vote picture) — save the place to keep it.

---

## Before that: Plague Night rebuilt, a King everyone hunts, royal caches, darker raids

- **Plague Night: the dead never come from one place.** Each ghoul claws up out of the ground (grave-mist, broken earth) on open ground 45–80 studs from someone living, inside the town, never on a roof or inside anything; a turned player rises where they fell. Before, every ghoul and every turned player came in at the plague side's spawns, all in one spot.
  - **The dead surge** every 70 seconds from all sides at once.
  - **Worse things as the night deepens**: Plague Runners (quick), Bloaters (they burst green when they fall), Plague Brutes (huge). New Bestiary entries; a monster's `burst` colours its blast.
  - **Lanterns** on the living; the last of them **stands alone** (mended, +50 health, quicker).
  - **Toward dawn**: the sky pales and the mist lifts as the clock runs (the map's Atmosphere too, put back at the end).
- **Kingslayer: everyone against the King.** Bots within 110 studs of the King go for them; the crown on the ground draws the bots. A long reign burns brighter and the field hears of it every 30 seconds.
- **Crownfall: royal caches.** As each of the first three rings closes, a gilded chest falls out of the sky under a canopy inside the next ring, with a gold flare over it till it's opened: four things rolled with a king's luck.
- **Deadvault: darker and lived-in.** Every raid room gets cracks, rubble, cobwebs strung where wall meets ceiling, damp streaks, puddles, chains or a hanging cage, bones, guttering candles and dust drifting in the torchlight. The raid's light is dimmer (less ambient and sky light, a thicker haze). Fire lights now **flicker** (new TorchFlicker client script), in the dungeons and the Gilded Rat.
- **Checked in Play**: Plague on Millfield (ghouls came up 45–120 studs out on all sides, villagers fought them, a Bloater turned up, the night lightened on schedule); Kingslayer (with the player crowned, the bots within reach closed from 64 studs to 3–7 in 20 seconds); Crownfall (a cache fell from 130 studs in 9 seconds and became an openable Royal cache); Deadvault (raid built in about 6 seconds, every room dressed); compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Plague.lua](ServerScriptService/Game/Modes/Plague.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | spawns out of the ground round the living, surges, kinds, lanterns, last stand, dawn |
| [Bestiary.lua](ReplicatedStorage/Catalog/Bestiary.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | Plague Runner, Bloater, Plague Brute; `burst` |
| [Monsters.lua](ServerScriptService/Combat/Monsters.lua) | ServerScriptService ▸ Combat | ModuleScript | an explode's colour from `burst` |
| [Kingslayer.lua](ServerScriptService/Game/Modes/Kingslayer.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | bots hunt the King; a long reign burns brighter |
| [Crownfall.lua](ServerScriptService/Game/Modes/Crownfall.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | royal caches |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | raid grime, hanging cages, new cobwebs, darker raid light, flickering fire lights |
| [MapLoader.lua](ServerScriptService/Game/MapLoader.lua) | ServerScriptService ▸ Game | ModuleScript | resets the sky light scales between maps |
| [TavernMap.lua](ServerScriptService/Game/TavernMap.lua) | ServerScriptService ▸ Game | ModuleScript | its fires flicker |
| [TorchFlicker.client.lua](StarterPlayerScripts/TorchFlicker.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [README.md](README.md) | | doc | |

---

## Before that: The Gilded Rat, the dungeon game's own world

- **A world of its own** for The Depths and Deadvault: **The Gilded Rat**, an adventurers' lodge (new Tavern mode, its own public servers).
  - The Courtyard's Deadvault and Depths tiles take you there; leaving a raid brings you back there; its door goes home to the Courtyard.
- **The lodge** (new TavernMap, built fresh): a long timbered hall, candle-lit tables, chandeliers, a great hearth, the Treasurer's counter, the Smith's forge, the Armourer's stands, the Alchemist's bottles and cauldron, your stash's chest, the notice board, the Dungeon Gate, the door home.
- **The merchants stand at their stalls** as dressed people with names over their heads; TRADE opens their wares in the lobby. The chest opens the stash, the board the class tab, the gate PLAY.
- **You walk in** as your class; the lobby opens on arrival; M is the lobby there.
- **Checked in Play**: switched to the Tavern: the lodge built (431 parts), a body walked in, the lobby opened by itself on PLAY; the hall on screen with its merchants; compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Tavern.lua](ServerScriptService/Game/Modes/Tavern.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | new |
| [TavernMap.lua](ServerScriptService/Game/TavernMap.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | DOORS.Tavern, MODES.Tavern, its title |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub | Script | out of a raid: to the Tavern |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | extraction: to the Tavern |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the tiles go to the Tavern; M there is the lobby's |
| [DungeonMenu.client.lua](StarterPlayerScripts/DungeonMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | opened by the lodge's places and on arrival |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | no clock in the Tavern |
| [README.md](README.md) | | doc | |
