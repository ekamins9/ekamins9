# Updated scripts: Deadvault rebuilt after Dark and Darker

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

---

## Before that: loot for your own class; an easier Depths; guides to what's worth walking to

- **Your own class's loot**: nobody sees another class's things.
  - A tome only teaches one of your class's powers (no Storm Arrow for a Knight).
  - A relic with a `class` only rolls for that class: the Eagle Feather (draw) for Archers, the Mana Pearl (cast) for Mages.
  - Deadvault's elite drops are fitted to whoever felled the monster.
- **An easier Depths**:
  - fewer monsters in a room, starting at 80% health and damage on the first floor;
  - how well they fight is capped by the floor (Squires on the first, Knights on the second; the boss never better than a Knight);
  - elites rarer (5% a floor past the first, from 8%); the boss at 75% of its health pool;
  - every boss move hits at 85% (`BossMoves.DAMAGE`);
  - a cleared room mends 40% (from 25%).
- **Guides** (Adventure.client): a marker over what's worth walking to (OPEN CHEST, PRAY, DRINK, DESCEND, a find's name; EXTRACT, TAKE THE CROWN), an arrow at the screen's edge to the nearest one off screen (one behind you points to a side), an UP NEXT line under the run panel, a gift on the map's rooms with a chest.
- **A weapon from a chest** with both hands full swaps out the one in your hand, and that one drops at your feet instead of vanishing (The Depths; Crownfall and Deadvault drop it too).
- **Chests** in a room with a centrepiece (the start's brazier, an altar, a fountain) stand on open floor, not inside it.
- **Checked in Play**:
  - 300 tomes and relics rolled per class: Knights only Knight powers and no class relic, Archers only Archer powers + the Eagle Feather, Mages only Mage powers + the Mana Pearl;
  - a first-floor room: 2 monsters at Squire skill, ~60 health; a third-floor room: 5;
  - markers on a chest, the fountain and a find; a find swapped out the held weapon and the old one lay on the floor;
  - compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Loot.lua](ReplicatedStorage/Catalog/Loot.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `class` on the Eagle Feather and Mana Pearl |
| [Loot.lua](ServerScriptService/Game/Loot.lua) | ServerScriptService ▸ Game | ModuleScript | tomes and relics for the finder's class; `toolItem`; `giveWeapon` returns what it swapped out |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | difficulty; chests off centrepieces; the old weapon drops; the shrine's relics for your class; `hasChest` on the map |
| [Crownfall.lua](ServerScriptService/Game/Modes/Crownfall.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | drops the weapon `giveWeapon` swapped out |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | same; elite drops for the killer's class |
| [Monsters.lua](ServerScriptService/Combat/Monsters.lua) | ServerScriptService ▸ Combat | ModuleScript | `opts.skillCap` |
| [BossMoves.lua](ServerScriptService/Combat/BossMoves.lua) | ServerScriptService ▸ Combat | ModuleScript | `Moves.DAMAGE` |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | guides, edge arrow, UP NEXT, chest rooms on the map |
| [README.md](README.md) | | doc | |
| [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | a relic's `class` |

---

## Before that: a shield slings onto your back for a two-hander

- **Shields and two-handers**: picking up (or switching to) a weapon that can't go beside a shield used to leave the shield on your arm, half working and fighting the two-hander's animations.
  - Now a two-hander, a polearm, a bow or a staff in your hand slings the shield onto your back, face out, all of its effects off.
  - A one-hander back in your hand puts it back on your arm, block and all.
- **Checked in Play**: a Buckler with an Arming Sword (on the arm), a Zweihander equipped (on the back, the shield's block off), back to the Arming Sword (on the arm again).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Shields.lua](ServerScriptService/Combat/Shields.lua) | ServerScriptService ▸ Combat | ModuleScript | `sling`, watching what's in your hand |
| [Powers.client.lua](StarterPlayerScripts/Powers.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | leaves a slung shield's weld alone |
| [README.md](README.md) | | doc | |
