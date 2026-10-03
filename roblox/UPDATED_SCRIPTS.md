# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Now synced with Rojo:** `git pull` + `rojo serve` on your PC puts all of this into Studio by itself — see [ROJO_SETUP.md](ROJO_SETUP.md).

**Last change: the balance pass.**
- **Exhausted:** a swing needs its stamina cost in the bank, a kick needs `KICK_COST`; at 0 you can
  only guard and walk, and the HUD says EXHAUSTED. (The pitchfork-stab-on-empty knight is gone.)
- **Weights:** Heavy +35 health / 35 % protection (was +50 / 50 %), Medium +20 / 20 %, Light 0 / 5 %.
- **Parry refund = the attacker's swing cost** (min 6), +50 % per parry in a row; the PARRY word and
  the sparks grow with the streak. `FEINT_COST` 16. Stamina regen starts after 1.8 s (was 2.5).
- **Holding block drains 3 stamina / s** (`BLOCK_HOLD_DRAIN`); a timed parry stays free.
- **Health regen** 2.5 / s when stamina is full, idle, out of combat 5 s. **No low-health slow.**
- **Animations:** every weapon uses the greatsword's idle and block clips (the attack clips were
  already shared). **First equip** no longer misses the idle: the client asks for Setup again.
- **No-respawn rounds (The Lists, Last Team Standing) spawn everyone as their active class at
  round start** instead of skipping the round when nobody pressed SPAWN in time.

## Changed files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | exhausted gate, refund formula, hold drain, feint / regen constants, `Ready` resend |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | sends `Ready` on start |
| [ServerScriptService/CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | `ServerScriptService` → `CharacterSystems` | Script | block hold drain, health regen |
| [ServerScriptService/WalkSpeedGovernor.server.lua](ServerScriptService/WalkSpeedGovernor.server.lua) | `ServerScriptService` → `WalkSpeedGovernor` | Script | `MIN_HEALTH_F` 1 |
| [ServerScriptService/Loadout/LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | `ServerScriptService` → `Loadout` → `LoadoutServer` | Script | auto-spawn at round start in no-respawn modes |
| [StarterCharacterScripts/HUD.client.lua](StarterCharacterScripts/HUD.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `HUD` | LocalScript | EXHAUSTED popup, streak-sized PARRY |
| [ReplicatedStorage/Catalog/Weights.lua](ReplicatedStorage/Catalog/Weights.lua) | `ReplicatedStorage` → `Catalog` → `Weights` | ModuleScript | rebalanced |
| `Tools/<Pitchfork, Shortsword, Hammer>/Config.lua` | `ServerStorage` → `Weapons` → `<Tool>` → `Config` | ModuleScript | greatsword idle + block ids |
| [README.md](README.md) | — | doc | fencing layer |

## Studio

Nothing to paste (Rojo). Stop and re-run Play so the server scripts restart.
