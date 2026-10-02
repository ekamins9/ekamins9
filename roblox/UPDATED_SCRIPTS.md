# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Now synced with Rojo:** `git pull` + `rojo serve` on your PC puts all of this into Studio by itself — see [ROJO_SETUP.md](ROJO_SETUP.md).

**Last change: menu fixes.**
- **Party stage:** you stand up front in the middle, teammates and open slots (shadows) around
  you. The leader clicks a shadow's **+** to invite and the **✕** over a teammate to remove them;
  READY UP / LEAVE PARTY sit under your own name. The row of cards under the stage is gone.
- **Blank popup fixed:** every buy / crowns / invite popup drew its contents *under* its own
  backdrop (the menu's ScreenGuis used the old global ZIndex rule). They now show, have a CLOSE
  button, and clicking the dark area around one closes it too.
- **Courtyard:** already in a courtyard → the Courtyard card's button says ENTER THE COURTYARD
  and spawns you (BACK TO THE COURTYARD resumes if you're alive) instead of "you're in the Courtyard".
- **Weapons:** Shortsword, Pitchfork, Greatsword and War Hammer are all free. Nothing is locked.
- **Crates:** each drum card and the win popup show the skin **on the weapon in 3D** (a
  ViewportFrame of `Cosmetics ▸ Weapons ▸ <id>` with the skin applied). Until a weapon has a
  display model there, the card falls back to the flat blade/grip colors.

## Changed files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [StarterPlayerScripts/HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `HubMenu` | LocalScript | stage overlay + layout, ZIndex fix, Courtyard button, 3D crate cards |
| [ReplicatedStorage/Catalog/Weapons.lua](ReplicatedStorage/Catalog/Weapons.lua) | `ReplicatedStorage` → `Catalog` → `Weapons` | ModuleScript | all four weapons `unlock = {free = true}` |
| [README.md](README.md) | — | doc | Hub menu paragraph |

## Studio

Nothing to paste (Rojo). For the 3D crate cards, put a display copy of each weapon in
`ReplicatedStorage` → `Cosmetics` → `Weapons` → `<ToolName>` (a Model with a `Handle`); blade /
grip parts with attribute `SkinPart` = `"Blade"` / `"Grip"` take the skin tints.
