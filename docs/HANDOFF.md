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

## 4e. Publishing (checked 2026-10-08)

Verified in Studio before the first publish:
- **Maps:**
  - All 36 maps are in `ServerStorage ▸ Maps`, and every mode lists 10 or more (Siege 10, Lists 10, Duel 11, FFA 12, TDM 12, LTS 12, KOTH 11, Horde 10).
  - Every map passes the structural check: spawns for its modes, a hill, Horde gates, Siege stages, menu cameras, terrain.
  - Every map voted on has its picture in `ReplicatedStorage ▸ MapShots` (Decal ids in `blender/out/mapshots/decals.txt`).
- **Played:** Siege on Emberkeep (bots push the ram), KOTH on Cinderfall (the hill gets taken), TDM on Moonring. No script errors.
- **Test leftovers removed:** `workspace.PoseTest` and `ReplicatedStorage.FxTmp`. Workspace is empty (maps are cloned in at runtime). `/spawn` dummies only work in Studio or for the host of a cheat server.

Left to the owner:
1. **Save, then File ▸ Publish to Roblox.** The maps and pictures live only in the place.
2. **Game settings:**
   - avatar type R6
   - genre, age rating, thumbnails and icon
   - Developer Products: the 4 Crown bundles are already linked by name
3. **Persistence:** test it once in a private server (or turn on Studio API access). Nothing persistent can be checked in Studio with API access off: profiles, settings, boards, season grants, the admin queue.
4. **Season 1 ends 2026-11-17** (`Catalog ▸ Pass ends`). Before then, plan Season 2: a new `season` id gives fresh boards and payouts.

## 4f. The epic pass (2026-10-16/17, autonomous)

The user's direction: "insanely immersive", massive battles that look real, burning sieges,
creepy dungeons, arrows overhead, combat that feels like swinging the sword. What came of it
(every system has its section in `roblox/README.md`; `roblox/UPDATED_SCRIPTS.md` lists each
step):
- **`ReplicatedStorage ▸ WarCrowd`** — the armies on every screen: copies of the game's own
  dressed soldiers, posed limb by limb, LOD by rank and distance, staggered clocks and a per-frame
  budget. Regiments (march, clash, charge with `lane()`, loose, cheer, rout, fall, flung by
  blasts), ladders with climbers, audiences (arena stands), sentries, apparitions (`ghost`).
- **Where the armies are:** War (`War.client`), Siege (`SiegeEpic.client`: wall archers,
  ladders, flank battles, burning towers; the server describes the castle on the Map:
  `Siege.describeCastle`), the Prologue's Iron Host (`Prologue.client`), the Lists' warfield maps
  (`Warfield.client` + MapForge `warfield`: Redmeadow, Ironvale, Grimfield, Sunfall, Ravenfield),
  arena stands (`ArenaCrowd.client`), the Horde's host past the gates (`HordeHost.client`), the
  Courtyard's sentries (`CourtyardGuards.client`).
- **`ReplicatedStorage ▸ WarFX`** — volleys, fire, blasts (`scorch`/`floor` options), smoke
  columns, haze, positional loops, crows (`crows`), weather. `BattleAmbience.client`: the battle
  beyond a TDM/KOTH/LTS fight.
- **Dungeons:** dark floors with torch pools (`Game ▸ Dungeon`), `DungeonMood.client` (lanterns,
  dust, grade, vignette, drone and whispers, grave-dust arrivals, apparitions), boss entrances
  (`ReplicatedStorage ▸ BossIntro`; the Depths through `Adventure.client`, Siege's champion and
  the Horde's Warlord through `BossEntrance.client`).
- **The dungeons, later the same night:** second waves that burst up through cracked floors and a
  boss's servants (`Depths:wave`); trapped corridors (`Game ▸ Traps` + `Traps.client`: spike
  grates, pendulum blades on the server's clock, dart plates, fire grates; the builder now lists
  `layout.corridors`); Deadvault's sarcophagi can wake (`Deadvault:waken`, `Containers`); the
  sleeping dead lie among the bones and get up (`DungeonMood` "the dead lie"); rats and drips;
  the score is quiet until a fight (`Music.client` Dread / Battle; a dungeon lord's theme only
  near its lair). Footprints in snow, sand, mud and earth everywhere (`Footsteps.client`). The sun
  moves over War, Siege and Horde; War's weather can turn mid-battle (Round ▸ WarSky). The Gilded
  Rat sounds lived in (`TavernAmbience.client`). A sixth dungeon theme, the Drowned Halls (its
  bestiary and its king). Secret rooms behind cracked walls (`Game ▸ Secrets`, `opts.secrets`, the
  `CombatServer.worldHitHooks` list for blades that hit the world). Corridor ambushes, torches that
  gutter out as the gates slam, footsteps behind you, the sleeping dead lying down; Deadvault
  denser. War: a champion for the side behind (his name over his head, a boss bar), the
  line-breaking call, Mistmarsh (a tenth field). Every boss falls with a pillar of light
  (`BossIntro.falls`, the dragon too). A What's new card in the Courtyard once per update
  (`WhatsNew.client`: edit its NEWS for the next update). Phone caps on prints and the lying dead.
  Note: every procedural map carries the Generated attribute (War, the caldera, the Crownlands,
  the Tavern, dungeon floors): test the mode, not Generated, to mean "a dungeon".
- **The morning of 10-17:** every house in the game is half-timbered (`MapKit` K.house); castle
  walls and towers are rubble stone with shingled spires (K.wall / K.tower defaults; the saved maps
  in ServerStorage ▸ Maps were converted in Studio and their 30 old houses rebuilt in place); a
  filmic grade and fair-weather clouds over the open-air maps (`CinematicGrade.client`, yielding
  to WarFX weather); shell-shock (`ReplicatedStorage ▸ Hearing`: every world sound routed through
  SoundService ▸ World, muffled by a near blast); spiders on threads and light shafts through
  ceiling grates in the dungeons; Amberwood, an eleventh War field (autumn); Settings ▸ Start in
  (first person); the review fixes (traps stream Atomic and spare calm patrols, woken coffins
  locked, secret walls kept clear of furnishing, late joiners get WarSky). Later the same day:
  night windows (`NightWindows.client`); real spider enemies (Cave Spider, Broodmother: body
  "spider" in `Combat ▸ Monsters`, a hidden fighter under a jointed spider walked by
  `SpiderLegs.client`, the `Beast` bot profile, `NoDrop` fangs, `Rigid` joints through the
  ragdoll) and their nests (`Dungeon` A.nest); mimics (Deadvault's chests and the Depths'
  treasure chests: body "mimic", `Deadvault:mimic` / `Depths:mimic`); skeletons fall apart into
  bone heaps and wraiths vanish (Monsters, Corpses "bones"/"none"). The What's new card is at
  version 2026-10-17b. Then: the Silk Caverns (an eighth dungeon theme, its Spider Queen boss,
  its lair a nest; admin next-map now accepts a procedural mode's themes); web traps (`Traps`
  BUILD.web); boiling oil over Siege's gate (`SiegeEpic.client` oil); the Banshee and the `wail`
  boss move (deafens through `Hearing`); a glyph/emoji sweep (fonts lack ♛ ➤ ✦ ▸ ▾ ✕ and Unicode
  13 emoji; ✔ became ✓); the class picker's selected tag colour. Then: gargoyles stand as statues
  until they wake (`DungeonMood` petrify); the Abbey's ghost procession; Kingsbridge's ploughed
  plots; pigeons in the Courtyard (`Pigeons.client`); the `web` boss move (Spider Queen,
  Broodmother: roots through Powers.addMods, BossFX "Webbed").
- **Combat feel:** the swing's weight on the camera (`CameraRig` reads `LocalWindAt` /
  `LocalReleaseAt` from `CombatClient`), on top of the existing hit-stop, flinch and FOV punch.
- **Studio-only, needs a save:** the five warfield maps and the Duskwall and Mournhold castles,
  their MapShots (and Stormvale's, Duskmoor's, Mistmarsh's and Amberwood's, War's new themes, and DrownedHalls, SilkCaverns
  and HollowAbbey, the sixth and seventh dungeon themes'), WarAudio ▸ Drums, Roar,
  Melee, Fire, Drone, Whisper, Groan, Growl, Bats, ArrowsOver, Dread (the dungeons' quiet score),
  Squeak, Drip, Tavern (the Gilded Rat's tune), TavernRoom (its murmur), AbbeyBell, Chant, Splash, ArmorMail,
  ArmorPlate, Fountain, EarRing, Skitter, Wail, Pigeons; and the 10-17 material pass over ServerStorage ▸ Maps
  (stone walls, shingled spires, rebuilt houses).
- **Testing notes** (also in the roblox-dev skill's gotchas): a sleeping display stops Studio
  rendering (hold it on with `SetThreadExecutionState`); script tabs in front of the viewport do
  too; a wedged `start_stop_play` can be bypassed with `StudioTestService:ExecutePlayModeAsync`;
  TMP Scripts made in the Server context during Play share the game's `require` cache.
- **Tried and dropped:** a victory camera on the round's winner (the server swaps the winner's
  body as the round ends; it would need a change to the round flow).
- **Recommended to the owner:** Lighting ▸ Technology = Future (the torch pools, fire and
  lanterns are made for it; the MCP can't read or set it).

## 5. Suggested order of work

1. `~/.local/bin/rojo.exe serve default.project.json`, connect the plugin, press Play, read the Output.
   **Save the place first** if it's been open since the 2026-10-16/17 run: its maps, MapShots and
   WarAudio sounds are Studio-only (section 4f). Remove the test scaffolding (ServerScriptService ▸
   TMP_Go, ServerStorage ▸ TMP_MapPick / TMP_Map / TMP_WarTheme) before publishing.
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
