# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** animation fitting matches your clips (one clip = wind-up + swing, fitted to
`windup + active`; recovery is a hold), and combos skip the windup — the next attack goes
straight into its swing part when the current swing ends.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | Combo = `startAttack(name, true)`: windup 0, clip skip fraction sent to the client; NPC playback matches |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | Clip fitted to windup+active (or windup / active for two clips); combo starts the clip at its swing part |
| [Tools/Greatsword/Config.lua](Tools/Greatsword/Config.lua) · [Pitchfork](Tools/Pitchfork/Config.lua) · [Hammer](Tools/Hammer/Config.lua) · [Shortsword](Tools/Shortsword/Config.lua) | each Tool → `Config` | ModuleScript | Comment block only — keep your own numbers, no need to re-paste |
| [README.md](README.md) | not a Studio object | — | Animations / morph / combo section |
