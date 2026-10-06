# Updated scripts: a free-mouse toggle

- **T frees the mouse** (rebindable: Free the mouse). The over-the-shoulder lock lets go so you
  can click the screen (the playtime gift, boards, anything) and a hint says how to lock it again.
  While it's free the camera holds still and your character turns the way you walk.
- **Fighting locks it again:** any swing, stab, overhead, underhand, feint, kick, dodge, block or
  pickup snaps the camera round behind your character, and your character doesn't spin to the
  camera. Pressing the move keys fast with a free mouse can't whip a swing round, because the
  swing turns the free mouse off and the usual turn cap applies.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | the free mouse: toggle, hint, re-lock on any fight input |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | the Cursor bind (T) |
| [README.md](README.md) | — | docs | controls |
