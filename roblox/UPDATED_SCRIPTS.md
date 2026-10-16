# Updated scripts: the dungeon game's own lobby, perks, the belt, looting bodies

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

---

## Before that: Deadvault rebuilt after Dark and Darker

- **A vast, quiet, detailed dungeon** (Dungeon `raid = true`): 30 rooms, each something it once was (great halls, crypts, cells, libraries, armouries, storerooms, chapels, caverns, treasure vaults, the lair), furnished to match, with pilasters, skirting and fewer torches.
- **Monsters that perceive** (new Combat ▸ Perception): they see (in front, in range, nothing in the way) and hear (running, fighting; crouching is quiet), shout for friends, hunt where they last saw you and go back. Many rooms are empty, some monsters sleep, pairs patrol. **!**, **?** and **z z** over their heads.
- **Search everything** (new Game ▸ Containers): crates, barrels, sacks, urns, racks, stands, shelves, sarcophagi, remains and chests, with a loot window (TAKE / TAKE ALL). New **valuables** to carry out and sell.
- **Your gear** (new RaidInventory.client, I): worn gear and a 20-slot bag; equip, take off, drink, drop.
- **Ways out on the map**: two escape stairs (open at 2:00) and blue portals in waves (5:00, 9:00, 12:00); hold to extract, interrupted if struck. 15-minute raids.
- **Parties** come in together and fight side by side; a **free kit** for your class (never lost); your class power comes along; a fallen raider leaves a **pack**.
- **The vault**: a 60-slot stash, a kit with 4 draughts, the class you raid as, and **merchants**: the Smith (daily weapons, REFORGE, TEMPER), the Armourer, the Alchemist, the Treasurer.
- **Checked in Play**:
  - a raid built in 9 s: 30 rooms, 55 containers, 39 monsters (11 asleep), 2 escape stairs, 4 havens;
  - a skeleton noticed and hunted the test character;
  - containers opened and emptied into the bag; a find equipped (the held weapon went to the bag); extraction banked everything but the free kit;
  - the loot window, the gear screen, the vault and the Smith's wares on screen;
  - compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | raid rooms, havens, escape stairs, containers |
| [Containers.lua](ServerScriptService/Game/Containers.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | rebuilt |
| [Vault.lua](ServerScriptService/Game/Vault.lua) | ServerScriptService ▸ Game | ModuleScript | merchants, stock, the Smith's work, class |
| [Loot.lua](ServerScriptService/Game/Loot.lua) | ServerScriptService ▸ Game | ModuleScript | treasure, containers, reforge |
| [Perception.lua](ServerScriptService/Combat/Perception.lua) | ServerScriptService ▸ Combat | ModuleScript | new |
| [VaultServer.server.lua](ServerScriptService/Hub/VaultServer.server.lua) | ServerScriptService ▸ Hub | Script | Buy, Work, Class |
| [Loot.lua](ReplicatedStorage/Catalog/Loot.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | TREASURES, CONTAINERS |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | Deadvault 15 min, its text |
| [RaidInventory.client.lua](StarterPlayerScripts/RaidInventory.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [VaultMenu.client.lua](StarterPlayerScripts/VaultMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | rebuilt |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | alert signs, known exits, raid guides |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | Deadvault's text |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | |
