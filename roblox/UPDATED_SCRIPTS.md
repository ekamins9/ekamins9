# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** a guard that comes down without parrying breaks the parry chain (no more
spamming right click off one successful parry).

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `guardStart`; `doBlockStop` clears `LastParryAt` / `ParryStreak` when the guard didn't parry |
