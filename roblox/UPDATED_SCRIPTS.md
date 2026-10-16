# Updated scripts: The Gilded Rat, the dungeon game's own world

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

---

## Before that: The Depths' monsters wait, perceive, and can be caught asleep

- **The Depths' monsters wait in their rooms** before the gates drop (some asleep, the rest standing about), with the same senses as Deadvault's (Combat ▸ Perception): they come when they see or hear you, and the gates drop the moment one does.
- **Sneak attacks**: a blow on a monster that hasn't noticed you lands double (×2.5 on a sleeper), and says so on your screen. Kill a whole room in its sleep and it's yours.
- Going down a floor takes the monsters of the rooms you passed by with it. The boss still comes with its fight.
- **Checked in Play**: a floor with 4 rooms waiting (11 monsters, 4 asleep); walking into a doorway, its monsters noticed and the room sealed in half a second; compile of both scripts.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `prepare`, `roomOpts`, the waiting rooms' trigger |
| [Perception.lua](ServerScriptService/Combat/Perception.lua) | ServerScriptService ▸ Combat | ModuleScript | the sneak attack hook, `Perceives` |
| [README.md](README.md) | | doc | |
