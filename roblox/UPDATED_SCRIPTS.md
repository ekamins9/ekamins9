# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** Mordhau-style stamina ledger (refund per enemy hit, whiff cost, walls neutral,
kick land/miss/wall), free parries with streak refunds and instant re-guard after a successful
parry, riposte speeds the windup only, through-wall hit rejection + blade-meets-wall stop,
low-stamina breathing/vignette/blur, backpedal clunk fix, smooth + widened FP FOV, scoreboard
above the menu at round end.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | Stamina ledger, parry streak + chain, riposte windup-only, `throughWall` / `wallAhead`, `Wall` action, kick ledger |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | Sweep reports a wall contact and stops the swing |
| [ServerScriptService/MovementServer.server.lua](ServerScriptService/MovementServer.server.lua) | `ServerScriptService` → `MovementServer` | Script | Unarmed kick refund / miss cost / wall |
| [ReplicatedStorage/SoundConfig.lua](ReplicatedStorage/SoundConfig.lua) | `ReplicatedStorage` → `SoundConfig` | ModuleScript | `Breathing` slot |
| [StarterCharacterScripts/InjuryFX.client.lua](StarterCharacterScripts/InjuryFX.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `InjuryFX` | LocalScript | Low-stamina vignette, blur, breathing loop |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | Clunk weight from gear only (backpedal fix), smooth FOV, `FP_FOV_HIDDEN` +10, settings-change log |
| [StarterPlayerScripts/Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `Scoreboard` | LocalScript | DisplayOrder above the loadout menu during the intermission |
| [README.md](README.md) | not a Studio object | — | Stamina / parry / walls / low stamina |

## Other Studio steps

- [ ] Put a looped breathing sound id in `SoundConfig.Breathing`
- [ ] Settings check: with `Logs` on, dragging a slider prints `[CameraRig] setting Bob = …` in the Output — if that line appears the value is reaching the camera; if not, the CameraRig in Studio is an old copy
