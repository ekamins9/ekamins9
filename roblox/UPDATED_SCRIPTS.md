# Updated scripts: something walks in the dark

- **Apparitions in the dungeons**: every minute or two, sometimes, a pale glowing see-through figure walks a few steps across the dark well ahead of you, with a whisper, and fades away. Only on your screen, never a fighter.
- **Checked in Play** in the Bone Crypt (Deadvault).

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `WarCrowd.ghost` |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | apparitions |
| [README.md](README.md) | | doc | |

---

## Before that: the arena stands are packed

- **Crowds in the stands** of the Colosseum, the forge arenas and the Sandpit: hundreds of spectators, blue fans at one end and red at the other, on their feet with arms up and a roar whenever someone falls, a long roar when a round is won, a murmur and a few shouts in between.
- **Checked in Play**: the Colosseum in FFA with bots: 56–60 fps in Studio play.

| File | Studio location | Type | Change |
|---|---|---|---|
| [ArenaCrowd.client.lua](StarterPlayerScripts/ArenaCrowd.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | audience, roar, unarmed men, held poses |
| [README.md](README.md) | | doc | |

---

## Before that: the armies no longer stutter when they move

- **Smoother battles**: when whole lines charged or the front moved, every regiment used to update on the same frame (spikes of 12–15 ms). Now each regiment keeps its own clock and each frame has a budget; worst frame measured 3.3 ms, 45–48 fps in Studio play on War (was 36–40 with dips to the 20s).
- **Lighter soldiers**: the second rank behind a lite front is mass, and lite men carry a little less armour (unnoticeable at that distance).
- **Debug aids**: the crowd folder reports `Busy` (which regiments moved in a heavy frame), `MovedFlying`, `Flying`.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | staggered clocks, frame budget, lighter ranks |
| [README.md](README.md) | | doc | |
