# Updated scripts: combat feel (perfect parries, kill confirm, weight, hit direction)

- **Perfect parry.** A guard raised in the last 0.12 s before the blade lands:
  - pays 6 more stamina and throws bigger sparks
  - reads "PERFECT PARRY" and punches the parrier's camera
  - takes away the attacker's instant re-guard, so the riposte lands unless they read it
- **Kill confirm.** The killing blow holds the swing longest and snaps the killer's view in for a moment.
- **Weight.** Two-handers and polearms hold every hit 1.6× longer, with a bigger camera kick.
- **Hit direction.** Taking a hit flashes a red arc at the screen edge toward the attacker.
- The camera punches follow the **Shake** setting (0 turns them off).

| File | Studio location | Type | Change |
|---|---|---|---|
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | `PERFECT_PARRY`, `PERFECT_BONUS`, `PerfectParryAt`; `KillConfirm` on lethal hits |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | `HITSTOP_KILL`, `HEAVY_HITSTOP`; KillConfirm handler |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | `heavy` / `kill` / `perfect` kicks; FOV punch spring |
| [HUD.client.lua](StarterCharacterScripts/HUD.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ HUD | LocalScript | hit-direction arcs |
| [README.md](README.md) | — | docs | perfect parry, contact feel |
