# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** fix black screen after death — the loadout menu now lifts the death fade and comes back.

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [StarterPlayerScripts/LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript | Clears `DeathFade`, releases the death cam, draws above it (DisplayOrder 2000) |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | Death cam stops steering the camera once fully black |
