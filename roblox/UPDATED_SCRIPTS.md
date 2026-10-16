# Updated scripts: Plague Night rebuilt, a King everyone hunts, royal caches, darker raids

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

---

## Before that: the dungeon game's own lobby, perks, the belt, looting bodies

- **A lobby of its own** (new DungeonMenu.client on new ReplicatedStorage ▸ DarkUI), after Dark and Darker: dark gold-lined panels, Merriweather, every item in 3D (no emoji).
  - Play: your party at a candle-lit tavern table.
  - Class: faces, you as the class, its story, its skill, its perks.
  - Stash: you in your kit, your stats, the kit and the belt, the stash, drag and drop.
  - Merchants: their faces and wares, your stash to sell from.
- **Perks** (new Catalog ▸ Perks, Game ▸ Perks): two per class go in with you (Iron Will, Second Wind, Pack Mule, Light Step, Ambusher, Eagle Eye, Arcane Flow…).
- **The belt**: four draughts on keys 3–6, always on screen; drinking takes a moment and slows you; healing comes over four seconds.
- **Bodies are looted**: a raid's monster leaves its corpse to search (no more things spilling on the floor).
- **No markers or prompts through walls** in the dungeon modes; no edge arrow in a raid.
- Loot armour now has a set's look (Catalog ▸ Loot ARMOR `set`); item cards carry their item's id for the icons.
- The Courtyard menu's Depths and Deadvault tiles open the lobby; HubMenu exports `_G.HubDressed`, `_G.HubMenuHide`, and steps aside while the lobby is up. The old VaultMenu is gone.
- **Checked in Play**: every lobby tab on screen (stash with 19 test items, class, merchants, the tavern scene); a raid: a monster's corpse searched (its gold), the belt with its draught; compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DarkUI.lua](ReplicatedStorage/DarkUI.lua) | ReplicatedStorage | ModuleScript | new |
| [DungeonMenu.client.lua](StarterPlayerScripts/DungeonMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| VaultMenu.client.lua | StarterPlayer ▸ StarterPlayerScripts | LocalScript | removed |
| [RaidInventory.client.lua](StarterPlayerScripts/RaidInventory.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | rebuilt in DarkUI, the belt |
| [Perks.lua](ReplicatedStorage/Catalog/Perks.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | new |
| [init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | PERKS, `perkFits` |
| [Loot.lua (catalog)](ReplicatedStorage/Catalog/Loot.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | armour sets |
| [Perks.lua](ServerScriptService/Game/Perks.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Loot.lua](ServerScriptService/Game/Loot.lua) | ServerScriptService ▸ Game | ModuleScript | `drinkSlow`, card ids, perk luck, `los` |
| [Vault.lua](ServerScriptService/Game/Vault.lua) | ServerScriptService ▸ Game | ModuleScript | perks in the view |
| [Containers.lua](ServerScriptService/Game/Containers.lua) | ServerScriptService ▸ Game | ModuleScript | corpses, line of sight |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the belt, perks, bodies, line of sight |
| [Perception.lua](ServerScriptService/Combat/Perception.lua) | ServerScriptService ▸ Combat | ModuleScript | Quiet, Ambusher |
| [VaultServer.server.lua](ServerScriptService/Hub/VaultServer.server.lua) | ServerScriptService ▸ Hub | Script | Perk |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the lobby's hooks |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | markers behind walls |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | |
