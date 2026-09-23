# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** feint fixes — feint / feint-to-parry / morph are windup-only and say why when
denied (F9 with `Logs` on); a feint-to-parry is no longer eaten by the re-guard cooldown; feints
now have a swoosh + a small camera dip so you can tell they happened.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | Feint-to-parry bypasses `BLOCK_COOLDOWN`; feint / morph denials logged; `Feinted` tell |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | `Feinted` → camera dip |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | `feint` / `chamber` impact kicks |
