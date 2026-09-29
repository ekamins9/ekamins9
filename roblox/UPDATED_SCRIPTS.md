# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** damage numbers — you see what you dealt (`30`, `HEAD 60` gold, `KILL 60` red)
to the right of the crosshair and what you took (`-30`, red) to the left. Swings, kicks and
thrown heads all report.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `CombatServer.showDamage` → `DealtText/Tick`, `TakenText/Tick` attributes |
| [StarterCharacterScripts/HUD.client.lua](StarterCharacterScripts/HUD.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `HUD` | LocalScript | Damage popups (dealt right, taken left); `HIT` word replaced by the number |
