# Updated scripts: bats in the dungeons

- **Bats**: now and then a swarm bursts out of the dark ahead of you and flits past over your head, wings beating, with a generated flutter-and-squeak sound.
- **Checked in Play** in the Bone Crypt.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | `WarFX.bats` |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | bats now and then |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ReplicatedStorage ▸ WarAudio ▸ Bats.

---

## Before that: a Siege ends over the castle; War's finale fixed

- **Siege's finale**: when a round ends, horns sound, the winners' army cheers, and the camera rises and circles slowly over the castle (walls, ladders, burning towers) for a few seconds before the scoreboard.
- **Fixed**: War's finale flight was being overridden by the menu's overview camera as soon as your character was gone; both finales now hold it off (`_G.FinaleCamera`).
- **Checked in Play** on Thornwall.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the finale |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | sets `_G.FinaleCamera` |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | its cinematic yields to a finale |
| [README.md](README.md) | | doc | |

---

## Before that: fix — Siege's crowd stalled whenever a climber reached the top

- **Fixed**: men made for ladders, crews and sentries had no swing timing, so when a ladder's climber reached the top of the wall and fought, the whole crowd's update errored every frame for a few seconds (the armies froze in place and frames were lost). Every soldier now gets his own beat when he's made. Siege on Greenhollow: no errors in a 60 s soak, 47 fps in Studio play (36 with the bug).

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | every soldier's swing timing set when he's made |
