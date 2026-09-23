# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** attack-side modes (mouse flick / modifier key + default side), scroll-wheel and
middle-mouse binds, Hammer config, all three weapon configs templated with the sided attack set
and `windupAnim` slots.

## New files (create these)

| File | Roblox Studio location | Type |
|---|---|---|
| [Tools/Hammer/Config.lua](Tools/Hammer/Config.lua) | `ServerStorage` → `Weapons` → `Hammer` (Tool) → `Config` | ModuleScript |
| [Tools/Hammer/Server.server.lua](Tools/Hammer/Server.server.lua) | inside the Hammer Tool → `Server` (skip if you already have it) | Script |
| [Tools/Hammer/Client.client.lua](Tools/Hammer/Client.client.lua) | inside the Hammer Tool → `Client` (skip if you already have it) | LocalScript |

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ReplicatedStorage/ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | `ReplicatedStorage` → `ClientSettings` | ModuleScript | `SideMode` / `DefaultSide` choices, `SideFlip` bind (LeftAlt), wheel + middle-mouse bind names |
| [ReplicatedStorage/Combat/CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | `ReplicatedStorage` → `Combat` → `CombatClient` | ModuleScript | Side from mode/modifier, wheel + MMB attack input |
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | `windupAnim = "rbxassetid://0"` treated as none |
| [StarterPlayerScripts/LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript | Choice rows in settings; rebinding accepts wheel / middle mouse |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | Wheel zoom only while the wheel is unbound |
| [StarterCharacterScripts/Movement.client.lua](StarterCharacterScripts/Movement.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `Movement` | LocalScript | Dodge / kick / sprint accept any bind type |
| [Tools/Greatsword/Config.lua](Tools/Greatsword/Config.lua) | Greatsword Tool → `Config` | ModuleScript | `windupAnim` slots, sided attack template, docs |
| [Tools/Pitchfork/Config.lua](Tools/Pitchfork/Config.lua) | Pitchfork Tool → `Config` | ModuleScript | Same |
| [README.md](README.md) | not a Studio object | — | Attack input + windup animation sections |

## Other Studio steps

- [ ] In each weapon `Config`, uncomment the sided attacks as you finish their two clips and paste the ids (`windupAnim` = idle → loaded pose, `anim` = loaded pose → swing → idle)
- [ ] The pasted config said `HAMMER` but `Name = "Shortsword"` — I saved it as Hammer; fix `Name` if it's the shortsword
