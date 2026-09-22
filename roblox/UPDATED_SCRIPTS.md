# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** armor sets + pre-spawn loadout menu (commit `40506bb`).

## New files (create these)

| File | Roblox Studio location | Type |
|---|---|---|
| [ServerScriptService/Loadout/Armor.lua](ServerScriptService/Loadout/Armor.lua) | `ServerScriptService` → new Folder `Loadout` → `Armor` | ModuleScript |
| [ServerScriptService/Loadout/LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | `ServerScriptService` → `Loadout` → `LoadoutServer` | Script |
| [StarterPlayerScripts/LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript |
| [ServerStorage/Armor/KnightSkin/Config.lua](ServerStorage/Armor/KnightSkin/Config.lua) | `ServerStorage` → `Armor` → `KnightSkin` → `Config` | ModuleScript |
| [ServerStorage/Armor/GambesonSkin/Config.lua](ServerStorage/Armor/GambesonSkin/Config.lua) | `ServerStorage` → `Armor` → `GambesonSkin` → `Config` | ModuleScript |
| [ServerStorage/Armor/PeasantSkin/Config.lua](ServerStorage/Armor/PeasantSkin/Config.lua) | `ServerStorage` → `Armor` → `PeasantSkin` → `Config` | ModuleScript |

The three `Config` modules are examples — rename to match your real armor set folders (the folder
name is the armor id), or copy one into any set that has none. Drop the `.lua` / `.server.lua` /
`.client.lua` suffix when naming the object in Studio.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | `ServerScriptService` → `Combat` → `CombatServer` | ModuleScript | Damage reduced by the armor set's Protection on covered limbs |
| [ServerScriptService/Combat/Injury.lua](ServerScriptService/Combat/Injury.lua) | `ServerScriptService` → `Combat` → `Injury` | ModuleScript | Severed limbs take their armor; skewered head takes its helmet |
| [ServerScriptService/TestDummies.server.lua](ServerScriptService/TestDummies.server.lua) | `ServerScriptService` → `TestDummies` | Script | Weapons found in `ServerStorage.Weapons`; dummies wear your armor; `/spawn <mode> [Weapon] [ArmorId]` |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | Helmets (`HeadClothing`) hidden in first person |
| [Tools/Pitchfork/Config.lua](Tools/Pitchfork/Config.lua) | inside the Pitchfork Tool → `Config` | ModuleScript | Added `Name` / `Description`; removed the silent `SOUNDS` overrides |
| [README.md](README.md) | not a Studio object | — | Armor folder layout + loadout flow documented |

## Other Studio steps

- [ ] Create Folder `ServerStorage` → `Weapons` and move every weapon Tool out of `StarterPack` into it (leave StarterPack empty, or you spawn with two weapons)
- [ ] Create Folder `ServerStorage` → `Armor` if it doesn't exist; each set inside needs a `Config` ModuleScript
- [ ] Each set's clothing models keep the exact names `HeadClothing`, `TorsoClothing`, `LeftArmClothing`, `RightArmClothing`, `LeftLegClothing`, `RightLegClothing`, each with a Part named `Middle`
- [ ] Press Play — the loadout menu should appear before you spawn
