# Updated scripts: objective rings, training ring deaths, combat animations

**Objective indicators and Training (newest):**
- **KOTH, Siege ram and capture zones:** a glowing ring on the ground that you can see from inside it.
  - The rim is the holder's colour and flashes when contested.
  - Segments show who's holding it, split by team; a capture fills as it's taken.
  - Dashes spin faster while it's moving or being taken.
  - A light pillar marks it from across the map (hidden while you're in it). The ring rolls with the ram.
  - The KOTH capture area is now the hill's real disc (it was a square box), and the marker reads TAKE / HOLD THE HILL or CONTESTED.
- **Training ring:** a bot you beat now ragdolls with its kill effect, instead of freezing (it was cleared away the moment it died).

| File | Studio location | Type | Change |
|---|---|---|---|
| [ObjectiveFX.client.lua](StarterPlayerScripts/ObjectiveFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ ObjectiveFX | LocalScript | **new**: the ground rings |
| [KOTH.lua](ServerScriptService/Game/Modes/KOTH.lua) | ServerScriptService ▸ Game ▸ Modes ▸ KOTH | ModuleScript | disc capture, publishes the hill's state |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Siege | ModuleScript | publishes the objective's radius; capture box hidden |
| [Objectives.client.lua](StarterPlayerScripts/Objectives.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Objectives | LocalScript | KOTH marker |
| [Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game ▸ Training | ModuleScript | fallen ring bots die normally |
| [README.md](README.md) | — | docs | objective indicators |

---

## Before that: forged combat animations, first hit wins, sharper hit sampling

**Follow-up fixes (all 66 clips rebuilt and re-uploaded):**
- **Guard:** blades held upright (swords ~75°, polearms ~62°, daggers ~55°) and the hands low, at chest or belly, instead of a sword levelled at the enemy with the arms raised.
- **Legs:** they move again with a weapon out. The idle and block no longer key the legs, so Roblox's walk cycle drives them, and the hips still counter the torso's turn.
- **No more choppy turning:**
  - The weapon's roll is carried along its path frame to frame, then turned toward the leading edge at a capped rate. Swords lead with whichever edge is nearer.
  - The arms take the smallest turn from frame to frame (no flips) and are rate-limited.
  - Measured worst case per frame: roll 18°, right arm 40°, left arm 38°. Before: up to 170°.

- **New animations for every weapon class.**
  - Six classes, each with its own clips: one-handed blades, one-handed blunt, dagger, two-handed swords, heavy two-handers, polearms.
  - Each class has an idle, a block, a hit flinch, and eight attacks. Underhands now exist for every weapon.
  - The blade travels a real arc round the body, edge first. The left hand holds two-handed grips. The head stays on the target while the torso turns. The legs stay planted.
- **Each swing is timed in three parts.**
  - The windup plays over the real windup.
  - The strike plays over the active phase: 0.3 s at speed 1, the same as before, so balance is unchanged.
  - The follow-through returns to guard over the recovery.
  - Checked in play: the live blade follows the designed arc to within a few degrees.
- **Switch back any time.**
  - Studio: set `ReplicatedStorage ▸ Animations` attribute `Style` = `"Classic"`.
  - The repo backup is branch `backup/combat-before-overhaul` (tag `combat-backup-2026-10-07`).
- **First hit wins.**
  - A clean hit interrupts the target's windup *or* strike, and their own late hit is thrown away.
  - A hit during their recovery doesn't cancel it.
  - **Bosses** (Horde / Siege warlords) don't flinch at all.
- **Hit sampling:** the sweep traces the whole blade every ~0.45 studs. On wide heads (axes, halberds, mauls) it also traces the outer faces, so a hit lands when the leading steel arrives.
- **Fixed:** an error every frame at zero stamina (`InjuryFX`).

| File | Studio location | Type | Change |
|---|---|---|---|
| [AnimForge.lua](ServerScriptService/Build/AnimForge.lua) | ServerScriptService ▸ Build ▸ AnimForge | ModuleScript | **new**: the animations as data, solver, builder, preview; upright guard, frame-to-frame continuity |
| [AnimSets.lua](ReplicatedStorage/Combat/AnimSets.lua) | ReplicatedStorage ▸ Combat ▸ AnimSets | ModuleScript | **new**: weapon → class, Forged / Classic, timing marks, hip counter |
| [BladeSamples.lua](ReplicatedStorage/Combat/BladeSamples.lua) | ReplicatedStorage ▸ Combat ▸ BladeSamples | ModuleScript | **new**: hitbox sample points |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | forged playback (windup / strike / follow-through), sampling |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | forged NPC playback, strike-span timing, hit flinch for NPCs, first hit wins, bosses don't flinch |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | hips counter the animated torso turn |
| [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ NpcAnimator | LocalScript | same for bots |
| [InjuryFX.client.lua](StarterCharacterScripts/InjuryFX.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ InjuryFX | LocalScript | zero-stamina error fixed |
| [scripts/anim_extract.py](../scripts/anim_extract.py), [scripts/upload_anims.py](../scripts/upload_anims.py), [scripts/anim_receiver.py](../scripts/anim_receiver.py), [scripts/upload_asset.py](../scripts/upload_asset.py) | — | Python | export → upload → Studio entries (ids stay out of git) |
| [README.md](README.md) | — | docs | forged animations, first hit wins, sampling |

**Save the place:** the 66 animations (`ReplicatedStorage ▸ Animations`) and the new map pictures (`ReplicatedStorage ▸ MapShots`) exist only in Studio.
