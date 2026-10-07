# Handoff — read this first

You are picking up a long-running build of a Roblox R6 melee game (Mordhau / Chivalry style)
that started in a cloud session. That session could not reach Roblox Studio or Blender, so
work continues here, locally, in the Claude Code desktop app. This file is the context the
cloud session would have had. Read it, then `CLAUDE.md`, `roblox/README.md` and
`roblox/UPDATED_SCRIPTS.md`.

## 1. Setup checklist (do this with the user, once)

1. **Repo.** This folder, branch `claude/r6-unified-camera-0cpfm0`. `git pull` before any work.
2. **Rojo.** Installed at `~/.local/bin/rojo.exe` (7.7.1). Run
   `~/.local/bin/rojo.exe serve default.project.json` from the repo root, Studio ▸ Rojo ▸ Connect.
   Every file edit then lands in Studio live (edits made during a Play session show up on the
   next Play). See `roblox/ROJO_SETUP.md`.
3. **Roblox Studio MCP.** In Studio: Assistant ▸ "…" ▸ Manage MCP Servers ▸ turn on "Enable
   Studio as MCP server"; under Quick connect switch on Claude Code. Studio must stay open.
   Use it to run Luau in edit or play mode, read the Output, start / stop play tests.
4. **Blender.** 5.2 is installed; the pipelines run it headless (`blender -b --python …`), no
   MCP needed. The Blender MCP (`uvx blender-mcp`, `uv` now installed; add-on copied to Blender's
   user add-ons as `blender_mcp_addon.py` — enable it in Preferences ▸ Add-ons, N ▸ BlenderMCP ▸
   Connect) is optional.
5. **Check:** both servers show as connected in the app's MCP list.
6. **Mesh uploads.** `scripts/upload_asset.py` uses the Open Cloud Assets API with
   `ROBLOX_API_KEY` from the repo's `.env` (gitignored). **Never commit it.** Uploaded FBX =
   a Model asset; `InsertService:LoadAsset` in edit mode yields the MeshPart (see
   `Build ▸ MeshTool` / `MeshArmor`). Asset ids live only in `blender/out/*.json` (gitignored).

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

## 4. State after the first local session (2026-10-06)

Done and verified in Studio (Output clean on Play):
- Catalog crash fixed; grips fixed (blueprint Handles are boxes, blade on +Y); UI glyphs; side bar.
- **All 26 weapons are Blender meshes** in the place (`blender/weapons.py` →
  `scripts/build_weapons.py` → `Build ▸ MeshTool`). Vertex colours, Blade / Grip regions, skins tint.
- **Armor / hair / beards / faces as meshes**: `blender/parts2mesh.py` converts the Lua blueprints
  (export them from Studio to `blender/out/blueprints.json`, see the script's docstring);
  `scripts/build_armor.py` uploads and writes `blender/out/armor/assemble_armor.lua`; run it in
  edit mode (through the Studio MCP) — `Build ▸ MeshArmor.build{}`. Road Levy was in; the rest
  were being uploaded when this was written: check `ServerStorage ▸ Armor ▸ <Set>` for
  MeshParts, else re-run the snippet.
- Faces: full compact faces, decal hidden. Roster: 5 free starters. Daily store rotation
  (`Catalog ▸ Store`). New SHOP (store / crates / armory / colors), class cards, HUD.
- Maps: `Build ▸ MapKit` + `Build ▸ Maps` (Sandpit, Highbridge, Millfield) built into
  `ServerStorage ▸ Maps`, terrain pasted by MapLoader. `Maps.build("Sandpit")` rebuilds one.
- Testing cheats `/marks /crowns /xp /level`. Crown bundles link to Developer Products by name.

Not verified visually (Studio screen capture timed out for most of the session — keep the
Studio window visible / not minimized): the look of the mesh armor on a character, faces, the
new shop screens, the maps. Everything was checked structurally (part counts, no errors).

Still to do:
- Create the four Developer Products on the Creator Dashboard (`100 Crowns` 99 R$, `550 Crowns`
  499, `1200 Crowns` 999, `2600 Crowns` 1999). Enable *Allow Studio access to API services*.
- Hand-tune weapon looks (crossguards, pommels) in `blender/weapons.py`; sculpt nicer helmets in
  `Build ▸ Armor` (the converter makes meshes of whatever the blueprints say).
- Matchmaking, reserved servers, Robux products: need a published game.

## 4c. State after the second session (2026-10-06, later)

Verified in Studio with screenshots (the 3D view must stay visible for `screen_capture`):

- **Meshes face the right way.** The FBX import turns every pipeline mesh 180° about Y.
  `MeshArmor` / `MeshTool` turn each region back, and parts already in the place carry
  `Turned = true`. This fixed backwards hair and reversed axe heads.
- **Faces are decal textures** (`blender/faces.py`, `Cosmetics ▸ Body ▸ Face`). They sit
  correctly on the round R6 head; the wardrobe shows them as a picture grid.
- **Skins are never sold at will.** A skin comes from a crate, is earned (kills, tasks), comes
  with its pack on that pack's shop days, is one of the daily WEAPONS shelf offers
  (`Catalog ▸ Store`), or is a season pass reward. `Economy.buy` enforces all of it.
- **Skins change the weapon's shape**: `ReplicatedStorage ▸ SkinTrims` has 19 trim builders,
  and every skin in `Catalog ▸ Skins` names one.
- **The menu is a lobby** (`HubMenu`): party stage, PLAY → MODES board with posed 3D scenes,
  a 7-tile dock, LOADOUT with try-on, ARMORY (weapons + armor), SHOP (daily + crates + crowns +
  colors), TASKS, PASS, WARDROBE, SERVERS, SETTINGS. Test hooks: ScreenGui attributes
  `Tab`, `ShopTab`, `ArmoryTab`, `OpenCrowns`.
- **Season Pass** (`Catalog ▸ Pass`) and **login rewards** (`Catalog ▸ Login`) work end to end
  in Play: claim, claim-all, premium purchase. Studio cheats: `/marks /crowns /xp /level /passxp`.
- **Maps rebuilt**: cone spires, round arches, Sandpit gate and pit stairs, Highbridge gatehouse
  walls, per-map terrain colours (`TerrainColor_*`, applied by MapLoader).

Studio tips:
- Edit-mode `require` caches modules, so require a clone for fresh code.
- A `require` from the MCP's Server context gets its own module copies (its own Profile
  cache). Test economy changes through the chat cheats (`TextChannel:SendAsync` in a
  `task.spawn`) or the remotes.
- `user_mouse_input` y is 58 px above GUI y (the top bar inset).

Still to do:
- Enable *Allow Studio access to API services* (profiles don't save in Studio without it).
- Uninstall the counterfeit Studio Build Suite plugin (section 4b).
- Season 2: a new `season` id and tier list in `Catalog ▸ Pass`, plus its skins in
  `scripts/gen_content.py` (`PASS_SKINS`).

## 4b. Security: the counterfeit "Studio Build Suite" plugin

Plugin **6542422966** (shows up as *Studio Build Suite* / SBS) injects a Script
`require(6523905017).weld()` into a random Workspace descendant every time Studio
opens a place. That is a backdoor: it stays inert only while the required asset is
taken down. The user was asked to uninstall it (Plugins ▸ Manage Plugins) on
2026-10-06. If `require(…)`-style "Downloading asset failed" errors show up in the
Output again, check the plugin list, then clean the place in edit mode:

```lua
for _, d in ipairs(game:GetDescendants()) do
	if d:IsA("LuaSourceContainer") and d.Source:find("6523905017", 1, true) then d:Destroy() end
end
```

Any other place the user opened in Studio while the plugin was installed has the
same injected scripts.

## 4d. The look pass (2026-10-06, late)

Every armor set and piece, all 26 weapons, every hairstyle and beard and the companions were
redesigned so each reads differently (see `roblox/README.md` ▸ *What each set looks like*).
The loop that made it possible, worth reusing for any new look:
- **Preview before uploading.** `blender/preview_armor.py` renders blueprints on an R6
  mannequin (sheets of heads, torsos, legs, full figures, hair; or one set front / side / back);
  `blender/preview_weapons.py` renders weapons in a row. Read the PNG, fix, re-render.
- **Blueprints come out of Studio** through `scripts/export_blueprints.lua` (run via the MCP;
  the result is cut at 100k characters, so fetch it in slices) and
  `scripts/join_blueprints.py`. The MCP caches `require` per session: export from a fresh clone
  of the folder (the script does) or you get the old module.
- **The R6 head is round** (a 1.2-wide drum with rounded rims, not a cube): closed helms are a
  drum + dome round it; torso / limb wraps must be rounded boxes (an oval leaves the box's
  corners poking out).
- **Uploads are slow** (~3 a minute through Open Cloud); `build_armor.py --upload-only`
  resumes and `--reverse` lets a second uploader work from the other end.

## 5. Suggested order of work

1. `~/.local/bin/rojo.exe serve default.project.json`, connect the plugin, press Play, read the Output.
2. Finish / verify the mesh armor (section 4), look at every set on the mannequin, fix fits.
3. Polish: weapon and helmet shapes, menu screens against `docs/reference/`, the maps' cover.
4. Only one session should push to the branch at a time.

## 6. Conventions (also in CLAUDE.md)

- Rojo naming: `*.server.lua` Script, `*.client.lua` LocalScript, `*.lua` ModuleScript,
  `Folder/init.lua` ModuleScript with children, `init.meta.json` with `ignoreUnknownInstances`.
- Weapons need a part named `Hitbox` (longest axis = the blade) and a `Handle`; skin-tintable
  parts carry attribute `SkinPart` = "Blade" | "Grip". Armor models are built around a part
  named `Middle` the size of the limb; color blocks carry `ColorSlot`.
- Server-authoritative economy and loadouts; the client only asks.
- Syntax-check Luau before committing (Studio MCP or `luau-compile`).
- No model identifiers in code, comments or commit messages.
