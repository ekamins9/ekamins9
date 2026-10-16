# Updated scripts: loot for your own class; an easier Depths; guides to what's worth walking to

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

---

## Before that: any two weapons; no more monsters stuck outside a Depths room

- **Weapons**: you can carry any two, a primary or a sidearm alike.
  - Picking one up (off the floor, or as loot in The Depths, Crownfall and Deadvault) with a free slot puts it there.
  - With both full, it swaps for the one in your hand (that one drops; in Deadvault it goes into your bag).
  - Before, a "secondary" could only replace your secondary: a Rapier sidearm and a Zweihander meant a Falchion could never come in.
- **The Depths**: a monster could end up outside its room, behind the shut gates, and the room never cleared.
  - Summons now always appear inside the room's walls.
  - A blink never lands through a wall.
  - The room puts back any monster it finds outside its walls.
- **Checked in Play**:
  - a find going into the free slot, then swapping for the held weapon;
  - a Zweihander off the floor swapping out a held Rapier;
  - compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Pickup.lua](ServerScriptService/Combat/Pickup.lua), [Monsters.lua](ServerScriptService/Combat/Monsters.lua), [BossMoves.lua](ServerScriptService/Combat/BossMoves.lua) | ServerScriptService ▸ Combat | ModuleScript | any two weapons; summons in the room; blinks not through walls |
| [Loot.lua](ServerScriptService/Game/Loot.lua), [Modes/Depths.lua](ServerScriptService/Game/Modes/Depths.lua), [Modes/Crownfall.lua](ServerScriptService/Game/Modes/Crownfall.lua), [Modes/Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game | ModuleScript | `Loot.slotFor`; the room's watchdog |
| [README.md](README.md) | | doc | |
