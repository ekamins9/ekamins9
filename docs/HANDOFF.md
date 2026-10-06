# Handoff — read this first

You are picking up a long-running build of a Roblox R6 melee game (Mordhau / Chivalry style)
that started in a cloud session. That session could not reach Roblox Studio or Blender, so
work continues here, locally, in the Claude Code desktop app. This file is the context the
cloud session would have had. Read it, then `CLAUDE.md`, `roblox/README.md` and
`roblox/UPDATED_SCRIPTS.md`.

## 1. Setup checklist (do this with the user, once)

1. **Repo.** This folder, branch `claude/r6-unified-camera-0cpfm0`. `git pull` before any work.
2. **Rojo.** `rojo serve` from the repo root (version pinned in `rokit.toml`), Studio ▸ Rojo ▸
   Connect. Every file edit then lands in Studio live. See `roblox/ROJO_SETUP.md`.
3. **Roblox Studio MCP.** In Studio: Assistant ▸ "…" ▸ Manage MCP Servers ▸ turn on "Enable
   Studio as MCP server"; under Quick connect switch on Claude Code. Studio must stay open.
   Use it to run Luau in edit or play mode, read the Output, start / stop play tests.
4. **Blender MCP.** `.mcp.json` in the repo root already registers `uvx blender-mcp` (needs
   `uv` installed). In Blender: install the add-on `addon.py` from
   github.com/ahujasid/blender-mcp (Edit ▸ Preferences ▸ Add-ons ▸ Install), then in the 3D view
   press N ▸ BlenderMCP ▸ Connect. Approve the server when the app asks.
5. **Check:** both servers show as connected in the app's MCP list.
6. **Mesh uploads (later).** Blender meshes reach Studio as MeshParts through the Roblox Open
   Cloud Assets API. The user creates an API key on the Creator Dashboard (Assets read + write)
   and keeps it in an environment variable, e.g. `ROBLOX_API_KEY`. **Never commit it.**

## 2. Who the user is and how they like to work

- Solo developer, builds in Studio, wants big chunks of work done end to end ("keep running
  until done"). Casual tone, short messages, often with screenshots.
- **Adding content must be config only**: armor sets, weapons, skins, crates, packs, hair…
  are rows in `ReplicatedStorage/Catalog/*` plus models. Never make them edit core scripts.
- **Escape belongs to Roblox. M is the menu key everywhere.**
- Wants the UI **bright and friendly** like the reference screenshots in `docs/reference/`
  (navy panels, white bold text, yellow action buttons, star rarity, 3D characters on cards),
  while keeping the core concepts: doors on PLAY, party of 3 with ready-up on a 3D stage,
  server browser, custom servers, shop with crates.
- Wants real **3D models made for every cosmetic** (armor packs, weapons, skins, hair, beards,
  faces), historically grounded, with correct `Hitbox` parts in weapons. Blender is the tool now.
- After every change: rewrite `roblox/UPDATED_SCRIPTS.md`, commit, push to the branch.

## 3. What exists (as of the handoff)

Read `roblox/README.md` for the full system list. Highlights:

- **One place, many servers.** Public servers are the Courtyard hub; every match is a reserved
  server that learns its mode from its first arrival's TeleportData (`Game.identify`). Doors:
  Courtyard, Tiltyard (friends-only training), Warfront (public battles, mode vote), The Lists
  (1v1/2v2/3v3 casual or ranked via a MemoryStore matchmaker, Elo).
- **Party** of max 3 with ready-up; travels together; cross-server invites.
- **Catalog** (`ReplicatedStorage/Catalog/*`): weights (the only stats source), 12 release armor
  sets + 9 earned pieces, 26 weapons, ~180 skins across Bladesmith / Hafted / Royal Armoury
  crates, palette, hair / beards / faces / titles, economy (Marks earned, Crowns from Robux,
  exchange), contracts. `roblox/RELEASE_CONTENT.md` lists every model the catalog expects.
- **Dresser** dresses real spawns and menu mannequins the same way (Middle-welded clothing,
  `ColorSlot` color blocks, team colors, hair / beard / face models, weapon skins).
- **Blueprints** (`ServerScriptService/Build/*`): every weapon body, armor set, earned piece,
  hair, beard and face also exists as a list of parts. At server start
  `Blueprints.ensureAll()` builds whatever has no hand-made model. These are blocky
  placeholders. **The next big job is replacing them with real Blender meshes**, one at a time;
  a hand-made model with the same name always wins over the blueprint.
- **Theme** (`ReplicatedStorage/Theme.lua`): colors + fonts for every screen.
- **Generator** `scripts/gen_content.py`: writes the 22 generated weapon Tool folders and
  `Catalog/Weapons.lua` + `Catalog/Skins.lua` (the 40 hand-written skins for the four
  original weapons live in `scripts/skins_handmade.part`). Edit its tables and re-run.

## 4. Not verified yet (nobody has run these in Studio)

- The 22 blueprint weapons: grip orientation (business end along the Handle's +Y), Hitbox
  length vs `REACH`, feel of each Config. Swing every one.
- The 12 armor set and 9 earned piece blueprints on the mannequin and on a spawned character.
- Hair / beard / face overlays sitting on the head; helmets hiding them via `Covers`.
- The new Theme on every screen (HubMenu, class screen, scoreboard, travel screen, HUD).
- Matchmaking, reserved servers, Robux products: need a published game.

## 5. Suggested order of work

1. Setup checklist above; press Play; read the Output through the Studio MCP; fix errors.
2. Verify section 4 with Studio MCP (run code, screenshots if available), fix grips / fits.
3. Blender pipeline: model one weapon (Longsword) properly, export FBX, upload through Open
   Cloud, build the Tool from the MeshPart + an invisible `Hitbox`, confirm it swings. Then
   write that as a repeatable script and work through `RELEASE_CONTENT.md`.
4. UI pass toward `docs/reference/`: rarity stars and colored card frames, 3D character
   thumbnails on class / unit cards, chunky FredokaOne titles.
5. Only one session should push to the branch at a time. The cloud session that wrote this
   is retiring.

## 6. Conventions (also in CLAUDE.md)

- Rojo naming: `*.server.lua` Script, `*.client.lua` LocalScript, `*.lua` ModuleScript,
  `Folder/init.lua` ModuleScript with children, `init.meta.json` with `ignoreUnknownInstances`.
- Weapons need a part named `Hitbox` (longest axis = the blade) and a `Handle`; skin-tintable
  parts carry attribute `SkinPart` = "Blade" | "Grip". Armor models are built around a part
  named `Middle` the size of the limb; color blocks carry `ColorSlot`.
- Server-authoritative economy and loadouts; the client only asks.
- Syntax-check Luau before committing (Studio MCP or `luau-compile`).
- No model identifiers in code, comments or commit messages.
