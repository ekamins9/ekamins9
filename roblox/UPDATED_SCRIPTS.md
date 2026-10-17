# Updated scripts: the arena stands are packed

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

---

## Before that: the Prologue's Iron Host is a real army

- **The first thing a new player sees** is now an army: the Iron Host drawn up in the rain among its torches before Stormwatch (foot, pikes, knights, archers), the garrison's archers on the north walls. Volleys cut men down on both sides, the Host roars, closes on the gate as the story goes on, and at dawn turns and runs while the walls cheer.
- **Cleanup**: the old block-figure armies in WarFX (replaced by WarCrowd everywhere) are gone.
- **Checked in Play**: the Prologue's opening, from the walls and from over the Host.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Prologue.client.lua](StarterPlayerScripts/Prologue.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the Host and the garrison |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | old armies removed |
| [README.md](README.md) | | doc | |
