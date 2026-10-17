# Updated scripts: crows over the battlefields; the Siege gate bursts

- **Crows** wheel high over every battlefield (War's front, the Siege castle, the warfields, the team fights): black wings beating, gliding, beating again.
- **The Siege gate bursts** in a cloud of dust and splinters with a crash that shakes the ground (more the nearer you are).
- **Checked in Play** on Frostgate: the flock over the castle, the gate breaking.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | `WarFX.crows` |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | crows over the front |
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | crows; the gate's burst |
| [Warfield.client.lua](StarterPlayerScripts/Warfield.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | crows |
| [BattleAmbience.client.lua](StarterPlayerScripts/BattleAmbience.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | crows |
| [README.md](README.md) | | doc | |

---

## Before that: something walks in the dark

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
