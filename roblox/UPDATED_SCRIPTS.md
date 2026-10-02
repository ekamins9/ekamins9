# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Now synced with Rojo:** `git pull` + `rojo serve` on your PC puts all of this into Studio by itself — see [ROJO_SETUP.md](ROJO_SETUP.md).

**Last change: parry / chamber text and sound were missing.** The parry and chamber branches
in CombatServer count the stat through `_G.StatHook` before showing the HUD text, playing the
clang and cancelling the swing. That hook (Economy ▸ Stats) built its weekly contract key with
`os.date("%V")`, which Roblox does not support and errors on — so the branch died right there
(blocks never touch it, which is why BLOCK still worked), and daily contracts never loaded either.
Fixed both ways: the week key uses `%U`, and CombatServer now runs the hook deferred inside a
pcall, so nothing in the stats path can abort or delay a hit again (a failure warns instead).

## Changed files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `statHook` helper: deferred + pcall for parry / chamber stats |
| [ServerScriptService/Economy/Stats.lua](ServerScriptService/Economy/Stats.lua) | `ServerScriptService` → `Economy` → `Stats` | ModuleScript | weekly key `%U` instead of unsupported `%V` |

## Studio

Nothing to paste (Rojo). Stop and re-run Play so the server scripts restart.
