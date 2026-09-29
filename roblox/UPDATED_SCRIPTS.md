# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** a chamber can be answered — getting chambered no longer stuns you, and for
0.8 s your guard comes up instantly with a fresh parry window (no cooldown), so you can parry
the counter or chamber it back.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `CHAMBER_STUN` 0, `CHAMBER_PARRY_WINDOW`, `ChamberedAt` attribute bypasses the block cooldown |
