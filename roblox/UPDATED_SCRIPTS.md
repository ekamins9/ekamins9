# Updated scripts: objective rings, training ring deaths, combat animations

**Arms stay on, swings across, smooth finish (newest; all 66 clips rebuilt):**
- **Arms never detach:**
  - They turn with your view about their own shoulders, not your eyes.
  - Their reach is held to a few hundredths of a stud. Measured in play: at most 0.07 from the socket.
  - Two-handers nudge both hands (up to 0.45 studs) so the left hand stays on the grip without stretching an arm.
- **Arms follow the camera** up and down. There's no exact crosshair convergence any more; it's close and natural.
- **Horizontal swings** run at shoulder height, arms straight across the body, perfectly level.
- **No drop at the end of a swing:** the follow-through stays nearly level and plays at its natural pace, then settles exactly into the idle pose.

**Attacks go where you aim (newest; all 66 clips rebuilt at 40 fps):**
- **Swings are level:** the blade cuts a flat plane at crosshair height, with the hands at 1.15.
- **Thrusts drive at the crosshair**, and **overheads chop straight down the middle**.
- **Aiming:**
  - With a forged weapon out, the arms and weapon turn with your view about your eyes (`RigPose.aimArms`), in pitch and yaw.
  - The target point is on the crosshair ray, 7 studs past you (`AIM_DIST`): in first person that's simply your look, and in third person (camera over the shoulder) it brings the attack onto the crosshair.
  - Relayed to other players (new `aim` / `aimP` / `aimY` inputs). Bots aim at their target's chest.
- **Measured in play (third person):** right swing 0.4°, stab 0.7°, left swing 2.6°, overhead 3.3° from the crosshair.

**Animation pass 3 (newest; all 66 clips rebuilt):**
- **Overhead:** the hands go up above the head (y 2.1), in front of it, never through it; the blade lies back over the top and chops down.
- **Stab:** the whole body coils to the right with the head on the target, then unwinds as the arms drive the point out.
  - The hips and legs now follow 30% of every torso turn (`AnimSets.HIP_FOLLOW`); feet stay planted.
  - Measured in play: swing torso −49°…+38°, legs ±15°, head ±7°.
- **Block:** a diagonal guard across the body, hands low to the right and the tip up to the left. It covers you without filling your own view.
- **No spin when going back to idle:** every attack starts and ends exactly on the idle pose.
- **Smoother:**
  - All hand motion interpolates through one continuous path. Thrusts used to jump between two hand rules.
  - The fades into, between and out of attacks are longer again: 0.08–0.24 s in, about 0.12 s or more out.

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
| [AnimForge.lua](ServerScriptService/Build/AnimForge.lua), [AnimSets.lua](ReplicatedStorage/Combat/AnimSets.lua), [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua), [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | Build / Combat | ModuleScript | animation pass 3 (above) |
| [RigPose.lua](ReplicatedStorage/RigPose.lua), [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua), [Bots.lua](ServerScriptService/Combat/Bots.lua) | ReplicatedStorage / StarterCharacterScripts / Combat | Module / LocalScript | attacks aim at the crosshair |
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
