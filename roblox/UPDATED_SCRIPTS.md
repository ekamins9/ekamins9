# Updated scripts: fix — Siege's crowd stalled whenever a climber reached the top

- **Fixed**: men made for ladders, crews and sentries had no swing timing, so when a ladder's climber reached the top of the wall and fought, the whole crowd's update errored every frame for a few seconds (the armies froze in place and frames were lost). Every soldier now gets his own beat when he's made. Siege on Greenhollow: no errors in a 60 s soak, 47 fps in Studio play (36 with the bug).

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | every soldier's swing timing set when he's made |

---

## Before that: siege towers roll up to the walls

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
