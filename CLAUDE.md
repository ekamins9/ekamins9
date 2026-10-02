# R6 Mordhau-style melee game (Roblox)

All game code lives under `roblox/`, mirroring Studio locations. The repo is a Rojo project
(`default.project.json`): with `rojo serve` running and the Rojo plugin connected, every file
edit lands in the open Studio place live. Models (weapon Tools, armor sets, maps, sounds) live
only in Studio; the repo holds scripts and config.

## Read first
- `roblox/README.md` — every system, Studio placement table, conventions.
- `roblox/CONTENT_GUIDE.md` — adding sets, pieces, packs, weapons, skins, crates, body
  models, colors, products, contracts, maps: config only, never code.
- `roblox/UPDATED_SCRIPTS.md` — what the last change touched (rewrite it after every change).
- `roblox/ROJO_SETUP.md` — the Studio sync.
- `docs/courtyard-menu-prototype.html` — the interactive menu prototype the Hub menu was
  ported from (open in a browser; vanilla JS, the UI reference for PLAY / APPEARANCE /
  CLASSES / SHOP / SERVERS).
- Design docs are claude.ai artifacts in this account's gallery (claude.ai/code/artifacts):
  the menu / economy plan doc, the "flow book" of screens, and the prototype
  (https://claude.ai/artifact/X4TeEVZKLWh2zGfMtmknD8).

## Conventions
- File names follow Rojo: `*.server.lua` = Script, `*.client.lua` = LocalScript, `*.lua` =
  ModuleScript, `Folder/init.lua` = ModuleScript with children. Folders get an
  `init.meta.json` with `ignoreUnknownInstances` so Studio-only instances survive.
- Architecture: ONE place. Public servers are the Hub (Courtyard); every match is a reserved
  server identified by its first arrival's TeleportData (`Game.identify`); a server never
  changes mode. Studio has no teleports: PLAY switches the mode locally.
- Everything a player can buy/equip/roll is in `ReplicatedStorage/Catalog/*` (config
  modules) and models in `ReplicatedStorage/Cosmetics`. Armor sets auto-import as pieces.
  Stats come from weight only (`Catalog/Weights`), never from looks.
- Server-authoritative: prices, odds, awards, loadout validation (`Profile.validateLoadout`)
  are decided on the server; the client only asks.
- `Dresser` dresses both real spawns (server) and menu mannequins (client) so previews match.
- M is the menu key everywhere (Escape belongs to Roblox).

## Before committing
- Syntax-check every touched Lua file with a real Luau compiler if one is available
  (`luau-compile --target=a64 -O0 <file>`); otherwise at least `luau-analyze` or a careful read.
- Rewrite `roblox/UPDATED_SCRIPTS.md` (links to each changed file, Studio location, type).
- Never put model identifiers in code, comments or commit messages.
- Studio errors are worth reading directly: Studio writes logs to
  `%LOCALAPPDATA%\Roblox\logs` (Windows) / `~/Library/Logs/Roblox` (Mac).

## Branch
Work happens on `claude/r6-unified-camera-0cpfm0`; commit and push there.
