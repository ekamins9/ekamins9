# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** feints and every other cancel ease out at the weapon's tempo (no snap, and
feinting straight back into the same attack just turns around); swing/underhand → stab morphs
always go to the opposite-side stab; morph windup 1.3×; breathing loop can't get stuck after a
respawn and is much quieter.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | `CANCEL_BLEND` scaled by attack speed; no `Stop(0)` anywhere; flinch/block fades |
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `MORPH_STAB_OPPOSITE`, `MORPH_WINDUP` 1.3, NPC fades |
| [StarterCharacterScripts/InjuryFX.client.lua](StarterCharacterScripts/InjuryFX.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `InjuryFX` | LocalScript | Breathing / heartbeat loops parented to the per-life ScreenGui, killed on death, volume 0.35; sweeps any stray loop off the camera |
