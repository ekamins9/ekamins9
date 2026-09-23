# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** the fencing layer — chambers, morphs, feint key, windup animations fitted to the
phase times, mouse-side attack input (8 sided attacks), flinch-only-in-windup, per-region damage,
miss cost / hit refund / dodge refund, hit-reaction on the rig, sparks + parry edge flash, voice
folders, kick miss recovery, spawn protection, and the round loop.

## New files (create these)

| File | Roblox Studio location | Type |
|---|---|---|
| [ServerScriptService/RoundServer.server.lua](ServerScriptService/RoundServer.server.lua) | `ServerScriptService` → `RoundServer` | Script |

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ReplicatedStorage/ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | `ReplicatedStorage` → `ClientSettings` | ModuleScript | New binds: Feint Q, Swing E, Stab X, Overhead F, Underhand R (side from mouse) |
| [ReplicatedStorage/MovementConfig.lua](ReplicatedStorage/MovementConfig.lua) | `ReplicatedStorage` → `MovementConfig` | ModuleScript | `DODGE_REFUND`, `DODGE_REFUND_RANGE` |
| [ReplicatedStorage/RigPose.lua](ReplicatedStorage/RigPose.lua) | `ReplicatedStorage` → `RigPose` | ModuleScript | `hitX/hitZ` jolt inputs (11-number packet) |
| [ReplicatedStorage/Sounds.lua](ReplicatedStorage/Sounds.lua) | `ReplicatedStorage` → `Sounds` | ModuleScript | `Sounds.voice(kind)` random pick from `SoundService.Voice/<kind>` |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | Windup/release anim fitting, Morph/Retime/Chambered, mouse-side input, feint |
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | Re-arming phase timers, morphs, chambers, feint, miss cost/hit refund, per-region damage, flinch rule, kick miss, spawn protection, voice |
| [ServerScriptService/Combat/Injury.lua](ServerScriptService/Combat/Injury.lua) | `ServerScriptService` → `Combat` → `Injury` | ModuleScript | `Injury.sparks` |
| [ServerScriptService/MovementServer.server.lua](ServerScriptService/MovementServer.server.lua) | `ServerScriptService` → `MovementServer` | Script | `LastDodgeAt` stamp, unarmed kick miss recovery, drops spawn protection |
| [ServerScriptService/CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | `ServerScriptService` → `CharacterSystems` | Script | Death voice |
| [ServerScriptService/Loadout/LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | `ServerScriptService` → `Loadout` → `LoadoutServer` | Script | Spawn protection ForceField, round gating, damage tables in the catalog |
| [StarterPlayerScripts/LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript | SPAWN waits out the intermission |
| [StarterPlayerScripts/Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `Scoreboard` | LocalScript | Round timer, winner banner, board forced open in intermission |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | Hit-reaction jolt fed into the relayed pose |
| [StarterCharacterScripts/InjuryFX.client.lua](StarterCharacterScripts/InjuryFX.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `InjuryFX` | LocalScript | Screen-edge flash: white on your parry/chamber, red when yours gets caught |
| [Tools/Greatsword/Config.lua](Tools/Greatsword/Config.lua) | Greatsword Tool → `Config` | ModuleScript | Docs for `windupAnim`, `damage = {…}`, sided attack names (no behaviour change) |
| [Tools/Pitchfork/Config.lua](Tools/Pitchfork/Config.lua) | Pitchfork Tool → `Config` | ModuleScript | Same |
| [README.md](README.md) | not a Studio object | — | Combat rules 2, rounds, voice |

## Other Studio steps

- [ ] Add your new attacks to each weapon `Config.ATTACKS` with the names `LeftStab`, `RightStab`, `LeftOverhead`, `RightOverhead`, `LeftUnderhand`, `RightUnderhand` (plus the existing `LeftSwing` / `RightSwing`), each with `anim` (release), optional `windupAnim`, `kind`, `damage`, timings
- [ ] Optional: `SoundService` → Folder `Voice` → Folders `Swing`, `Hurt`, `Death`, `Kick`, `Parry` with Sounds inside
- [ ] Round length / intermission: top of `RoundServer`. Spawn protection: `SPAWN_PROTECT` in `LoadoutServer`
