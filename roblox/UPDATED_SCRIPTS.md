# Updated scripts: forged combat animations, first hit wins, sharper hit sampling

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
| [AnimForge.lua](ServerScriptService/Build/AnimForge.lua) | ServerScriptService ▸ Build ▸ AnimForge | ModuleScript | **new**: the animations as data, solver, builder, preview |
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
