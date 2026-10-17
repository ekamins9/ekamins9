# Updated scripts: the rest of the horde waits on the hills

- **The Horde's host**: beyond each gate and past the map's edge, blocks of the horde's soldiers stand facing your camp (torches at night). Each wave starts with their roar, a horn and war drums; they grow deeper as you survive. Only on your screen; never inside the play area, so nobody takes them for the wave.
- **Not shipped**: a victory camera on the round's winner (the server swaps the winner's body the moment the round ends, so there's nobody to film without changing the round flow).
- **Checked in Play**: the Horde on Wildwood.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HordeHost.client.lua](StarterPlayerScripts/HordeHost.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [README.md](README.md) | | doc | |

---

## Before that: crows over the battlefields; the Siege gate bursts

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
