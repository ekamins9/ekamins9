# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** new default binds (LMB swing, scroll up stab, scroll down overhead, X underhand,
LeftAlt opposite side, Modifier side mode), left-mouse bindable, no scroll zoom — Z toggles
first/third person — and the third-person camera sits higher and further over the right shoulder.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ReplicatedStorage/ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | `ReplicatedStorage` → `ClientSettings` | ModuleScript | New defaults, `MouseButton1` binds, `View` action |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | Swing goes through the bind (LMB by default), not Tool.Activated |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | Wheel zoom removed, View key toggle, shoulder offset (2.2 right, 0.9 up, dist 9) |
| [StarterCharacterScripts/Movement.client.lua](StarterCharacterScripts/Movement.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `Movement` | LocalScript | Accepts left-mouse binds |
| [StarterPlayerScripts/LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript | Rebind capture takes left mouse; Mouse 4/5 note |
| [README.md](README.md) | not a Studio object | — | Controls rewritten |

## Other Studio steps

- [ ] If you already saved settings in an earlier test, press **RESET DEFAULTS** in ⚙ once to pick up the new layout (saved binds win over defaults)
- [ ] Mouse 4 for underhand: Roblox can't see side buttons — set Mouse4 → `X` in your mouse's software (Logitech G Hub / Razer Synapse / etc.); Underhand is already X
