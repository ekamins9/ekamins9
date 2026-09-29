# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** on-screen combat text — defender sees `PARRY ×2 +12` (gold) / `BLOCK −20`
(grey) / `CHAMBER` / `GUARD BROKEN`; attacker sees `PARRIED` / `CHAMBERED` (red) / `BLOCKED` /
`HIT` / `FEINT`. Parry sparks are big and white, block sparks small and orange.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `GuardText` / `GuardTick` attributes on the defender; parry sparks at scale 2 |
| [ServerScriptService/Combat/Injury.lua](ServerScriptService/Combat/Injury.lua) | `ServerScriptService` → `Combat` → `Injury` | ModuleScript | `Injury.sparks(pos, scale)` |
| [StarterCharacterScripts/HUD.client.lua](StarterCharacterScripts/HUD.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `HUD` | LocalScript | Combat text popups |
