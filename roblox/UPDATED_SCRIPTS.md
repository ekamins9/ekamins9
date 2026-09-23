# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** no more windup clips — the windup is the blend from wherever the body is into
the swing clip's first frame, over `WINDUP / speed`. Blocked / parried swings ease back to idle
(`RECOIL`); an optional `HIT_ID` flinch clip blends in when you're hit.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `WINDUP` seconds instead of a windup clip, `RECOIL`, `HIT_ID`, `Flinch` tell, NPC playback on the blend model |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | Swing clip fades in frozen on frame 0 over the windup, then runs; recoil on clang; flinch clip; blended block on/off |
| [Tools/Greatsword/Config.lua](Tools/Greatsword/Config.lua) · [Pitchfork](Tools/Pitchfork/Config.lua) · [Hammer](Tools/Hammer/Config.lua) · [Shortsword](Tools/Shortsword/Config.lua) | each Tool → `Config` | ModuleScript | `windupAnim` removed, `WINDUP = 0.25`, `HIT_ID` slot |
| [README.md](README.md) | not a Studio object | — | Animation / timing section |

## Other Studio steps

- [ ] Your swing clips should START on the loaded pose (arm back, blade cocked) — frame 0 is what the windup blends into
- [ ] Optional: make one short flinch clip and put its id in each Config's `HIT_ID`
