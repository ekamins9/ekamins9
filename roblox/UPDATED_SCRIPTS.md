# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Now synced with Rojo:** `git pull` + `rojo serve` on your PC puts all of this into Studio by itself — see [ROJO_SETUP.md](ROJO_SETUP.md).

**Last change: no stun when you get parried.** `PARRY_PUNISH_STUN` is 0: a parried swing just
dies and eases back (`RECOIL`), and you can raise guard at once, so the riposte can be parried or
chambered back. The parrier keeps the riposte (quicker windup for `RIPOSTE_DURATION`) and the
stamina refund. Being blocked never stunned. Set the constant above 0 to bring a stun back.

## Changed files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `PARRY_PUNISH_STUN = 0`, stun only applied when > 0 |
| [README.md](README.md) | — | doc | fencing layer note |

## Studio

Nothing to paste (Rojo). Stop and re-run Play so the server scripts restart.
