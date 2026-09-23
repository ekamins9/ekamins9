# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** windup 0.25 → 0.15 (at speed 1); the swing clip now plays all the way out and
fades from its last frame instead of being cut into the fade.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | Clip fitted to exactly `active`; hold last frame, then fade |
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | Same for NPC playback; default `WINDUP` 0.15 |
| [Tools/Greatsword/Config.lua](Tools/Greatsword/Config.lua) · [Pitchfork](Tools/Pitchfork/Config.lua) · [Hammer](Tools/Hammer/Config.lua) · [Shortsword](Tools/Shortsword/Config.lua) | each Tool → `Config` | ModuleScript | `WINDUP = 0.15` (one number — just edit yours) |
