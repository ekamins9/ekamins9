# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** sprint · dodge · no jumping · weapon pickup · secondary weapons · settings menu
(camera feel + keybinds) · stab/skewer rework (no auto-execute, head on the blade axis, thrown
on your next swing) · disarm stamina/animation fix + unarmed kick · mouse hidden in game · only
leg clothing shown in first person.

## New files (create these)

| File | Roblox Studio location | Type |
|---|---|---|
| [ReplicatedStorage/ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | `ReplicatedStorage` → `ClientSettings` | ModuleScript |
| [ServerScriptService/MovementServer.server.lua](ServerScriptService/MovementServer.server.lua) | `ServerScriptService` → `MovementServer` | Script |
| [ServerScriptService/SettingsServer.server.lua](ServerScriptService/SettingsServer.server.lua) | `ServerScriptService` → `SettingsServer` | Script |
| [ServerScriptService/Combat/Pickup.lua](ServerScriptService/Combat/Pickup.lua) | `ServerScriptService` → `Combat` → `Pickup` | ModuleScript |
| [StarterCharacterScripts/Movement.client.lua](StarterCharacterScripts/Movement.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `Movement` | LocalScript |

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ReplicatedStorage/MovementConfig.lua](ReplicatedStorage/MovementConfig.lua) | `ReplicatedStorage` → `MovementConfig` | ModuleScript | Sprint / facing / dodge numbers, `NO_JUMP` |
| [ReplicatedStorage/SoundConfig.lua](ReplicatedStorage/SoundConfig.lua) | `ReplicatedStorage` → `SoundConfig` | ModuleScript | `Pickup`, `Dodge`, `HeadThrow` slots |
| [ReplicatedStorage/RigPose.lua](ReplicatedStorage/RigPose.lua) | `ReplicatedStorage` → `RigPose` | ModuleScript | `DODGE_LEAN` |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | Keys from ClientSettings; survives pickup restarts |
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `STAB_HEAD_EXECUTE` off, head thrown on next swing, shared kick for unarmed use, regen moved out, `Acting` attr, `SECONDARY` flag, no Backspace drop |
| [ServerScriptService/Combat/Injury.lua](ServerScriptService/Combat/Injury.lua) | `ServerScriptService` → `Combat` → `Injury` | ModuleScript | Disarm drops a pickup; head sits on the blade axis; `launchSkewer` |
| [ServerScriptService/CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | `ServerScriptService` → `CharacterSystems` | Script | Stamina regen for every character (the disarm fix), weapons drop on death, JumpPower 0 |
| [ServerScriptService/TestDummies.server.lua](ServerScriptService/TestDummies.server.lua) | `ServerScriptService` → `TestDummies` | Script | `/spawn clear` also sweeps dropped weapons |
| [ServerScriptService/Loadout/LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | `ServerScriptService` → `Loadout` → `LoadoutServer` | Script | Secondary weapon slot |
| [StarterPlayerScripts/LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript | Secondary list + SETTINGS panel (sliders, keybinds) |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | Settings multipliers, sprint FOV, dodge lean/roll, mouse hidden, no jump, FP shows leg clothing only |
| [Tools/Pitchfork/Config.lua](Tools/Pitchfork/Config.lua) | Pitchfork Tool → `Config` | ModuleScript | `SECONDARY = false` |
| [Tools/Greatsword/Config.lua](Tools/Greatsword/Config.lua) | Greatsword Tool → `Config` | ModuleScript | `SECONDARY = false` |
| [README.md](README.md) | not a Studio object | — | Controls, movement, pickup, skewer, settings sections |

## Other Studio steps

- [ ] Set `SECONDARY = true` in the `Config` of any weapon that should be allowed as a secondary (daggers, hatchets…) — until one has it, the SECONDARY list only offers "None"
- [ ] For settings to save between sessions: Game Settings → Security → *Allow Studio access to API services* (otherwise they last the session, no errors)
- [ ] Optional: fill the new `SoundConfig` slots `Pickup`, `Dodge`, `HeadThrow`
