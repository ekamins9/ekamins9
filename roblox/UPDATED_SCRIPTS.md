# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Now synced with Rojo:** `git pull` + `rojo serve` on your PC puts all of this into Studio by itself — see [ROJO_SETUP.md](ROJO_SETUP.md).

**Last change: Rojo setup fixes — no game code touched.** The CLI pin moved to Rojo 7.7.1 to
match the auto-updating Creator Store plugin (the 7.4.4 server could not talk to the 7.7 plugin),
and the three armor sets are now declared as **Models** so Rojo syncs `Config` into the existing
set Models instead of creating duplicate Folders beside them.

## Changed files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [../rokit.toml](../rokit.toml) | — (PC toolchain) | config | Rojo pin 7.4.4 → 7.7.1 |
| [ROJO_SETUP.md](ROJO_SETUP.md) | — (docs) | doc | version, Model note, plugin-mismatch note |
| [ServerStorage/Armor/GambesonSkin/init.meta.json](ServerStorage/Armor/GambesonSkin/init.meta.json) | `ServerStorage` → `Armor` → `GambesonSkin` | Rojo meta | `className: Model` |
| [ServerStorage/Armor/KnightSkin/init.meta.json](ServerStorage/Armor/KnightSkin/init.meta.json) | `ServerStorage` → `Armor` → `KnightSkin` | Rojo meta | `className: Model` |
| [ServerStorage/Armor/PeasantSkin/init.meta.json](ServerStorage/Armor/PeasantSkin/init.meta.json) | `ServerStorage` → `Armor` → `PeasantSkin` | Rojo meta | `className: Model` |

## Studio

Nothing to paste. If a stray `GambesonSkin` / `KnightSkin` / `PeasantSkin` **Folder** (holding
only a `Config`) sits next to the set Model in `ServerStorage` → `Armor`, delete the Folder.
