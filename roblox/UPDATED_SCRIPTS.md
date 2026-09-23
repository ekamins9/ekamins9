# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** timing now comes from the animation clips × the speed stack (`speed ×
TYPE_SPEED[type] × SPEED_MULT`), so morph / feint / chamber windows are the real windup at each
weapon's tempo; `INPUT_GRACE` for latency; all attacks sided (no more plain `Stab` / cycle);
all four weapon configs rebuilt on the shared animation set.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | Clip-length timing (`KeyframeSequenceProvider`), `TYPE_SPEED`, `RECOVERY`, `INPUT_GRACE`, `MORPH_CUTOFF` 1.0, sided-only attacks, `usable()` |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | Sided-only input (falls back to the other side if a clip is missing), no cycle, morph ends a live sweep |
| [Tools/Greatsword/Config.lua](Tools/Greatsword/Config.lua) | Greatsword Tool → `Config` | ModuleScript | Your ids (two `rbxassetid:/` typos fixed), no phase numbers, `TYPE_SPEED` / `RECOVERY` |
| [Tools/Pitchfork/Config.lua](Tools/Pitchfork/Config.lua) | Pitchfork Tool → `Config` | ModuleScript | Same animation set; stab 18 / swings 15; stabs 15% faster, overheads 10% slower |
| [Tools/Hammer/Config.lua](Tools/Hammer/Config.lua) | Hammer Tool → `Config` | ModuleScript | Same animation set; your 20 dmg / 18 / 4 numbers |
| [Tools/Shortsword/Config.lua](Tools/Shortsword/Config.lua) | Shortsword Tool → `Config` | ModuleScript | Same; stabs and underhands 10% faster |
| [README.md](README.md) | not a Studio object | — | Timing model section |

## Other Studio steps

- [ ] Underhand clips are still `rbxassetid://0` in every config — those two attacks stay unselectable until you paste ids
- [ ] The server reads clip lengths with `KeyframeSequenceProvider`; in Studio that needs the animations to be yours (or your group's). If the Output shows "can't read animation length", the `DEFAULT_WINDUP 0.1 / DEFAULT_ACTIVE 0.3` fallbacks are used
