# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Now synced with Rojo:** `git pull` + `rojo serve` on your PC puts all of this into Studio by itself — see [ROJO_SETUP.md](ROJO_SETUP.md).

**Last change: the parry–riposte rhythm.** Being parried never stuns; for `PARRIED_GUARD_WINDOW`
(0.8 s) after it your guard comes up at once with a fresh parry window, cooldown or not — the
riposte can be parried back, and that one back again. The riposte is the NEXT swing only
(`RIPOSTE_DURATION` 3 → 1.2 s, windup 1.6× quicker). `PARRY_WINDOW` 0.35 → 0.4 s.

## Changed files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `PARRIED_GUARD_WINDOW`, `ParriedAt`, riposte 1.2 s, parry window 0.4 |
| [README.md](README.md) | — | doc | fencing layer |

## Studio

Nothing to paste (Rojo). Stop and re-run Play so the server scripts restart.
