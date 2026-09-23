# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** clips cross-fade instead of snapping (fade time = `BLEND / speed`, so it scales
with the weapon's tempo), and a morph's windup plays in full at normal speed (it was being
squeezed into the time left, which is why it looked fast).

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `MORPH_WINDUP` (replaces `MORPH_MIN_WINDUP`), `BLEND`; NPC playback fades |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | `Play(fade)` / `Stop(fade)` cross-fades on every clip change, sized by speed |
| [README.md](README.md) | not a Studio object | — | Morph / blending notes |
