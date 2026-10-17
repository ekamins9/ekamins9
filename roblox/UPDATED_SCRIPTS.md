# Updated scripts: siege towers roll up to the walls

- **Siege**: two siege towers roll slowly up to the castle's side walls during the ram stage, pushed by their crews; they dock with a crash and men climb up inside and over onto the walls. Only on your screen (nothing solid).
- **Checked in Play** on Greenhollow: rolled from 32 studs out (the fields beside these castles are narrow), docked against the wall with the drawbridge over the battlements.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the rolling towers |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | side walls described; a tower model for clients |
| [README.md](README.md) | | doc | |

---

## Before that: War's armies roar when a banner falls

- **A banner taken in War**: every regiment of the side that took it raises its weapons, and the roar of the army rolls over the field.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the army's cheer on a capture |

---

## Before that: a boss darkens the room

- **Dungeon boss fights**: while a boss is alive near you the colours turn darker, blood-tinged and harder; they ease back when it falls.
- **Checked in Play** with the Lich King.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the boss grade |
| [README.md](README.md) | | doc | |
