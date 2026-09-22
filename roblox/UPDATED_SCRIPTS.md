# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** kill feed + hold-Tab leaderboard (kills / deaths / K/D); dodge is now a short
sidestep (¼ the distance, 10 stamina instead of 20).

## New files (create these)

| File | Roblox Studio location | Type |
|---|---|---|
| [ServerScriptService/Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | `ServerScriptService` → `Scoreboard` | Script |
| [StarterPlayerScripts/Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `Scoreboard` | LocalScript |

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ReplicatedStorage/MovementConfig.lua](ReplicatedStorage/MovementConfig.lua) | `ReplicatedStorage` → `MovementConfig` | ModuleScript | `DODGE_COST` 10, `DODGE_SPEED` 19, `DODGE_TIME` 0.10 |
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | Stamps kill credit (`LastHitBy/With/Kind`) on every swing, kick and thrown head |
| [ServerScriptService/Combat/Injury.lua](ServerScriptService/Combat/Injury.lua) | `ServerScriptService` → `Combat` → `Injury` | ModuleScript | Bleed-out deaths keep the credit, marked "bleed" |
| [README.md](README.md) | not a Studio object | — | Kill feed / leaderboard section |
