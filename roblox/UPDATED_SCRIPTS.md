# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Synced with Rojo:** `rojo serve` on your PC (binary at `~/.local/bin/rojo.exe`, see
[ROJO_SETUP.md](ROJO_SETUP.md)) puts all of this into Studio live. Stop and re-run Play after a
pull so the server scripts restart.

**Last change: the first local session.** Studio and Blender are wired up, the game runs
without errors, every weapon is a real mesh, the first armor set is a mesh, and the shop is a
rotating store. In order:

1. **Fixes found by pressing Play.** `Catalog ▸ Skins` called `C()` without defining it, which
   broke the whole Catalog (menu, economy, loadouts). Blueprint weapon Handles were cylinders
   (a Roblox cylinder's axis is X, so blades stuck out sideways from the fist) — Handles are
   boxes now. Glyphs Gotham can't draw (`▸ ✕ ✓ ♛ ◀ ▶ ↻ × − ±`) swapped for ones every UI font
   has. The Hub side bar's spacer went negative on short viewports (doors covered the tabs).
   Stale `MomentumLean` / duplicate `RigReplicator` moved to `ServerStorage ▸ Legacy`.
   Free-model weld scripts in the stamped castle models (`require(<dead asset>).weld()`) are
   removed by `Sanitize` at start and whenever one appears.
2. **Mesh weapons.** `blender/weapons.py` builds all 26 weapons procedurally in headless
   Blender (two meshes each: Blade + Grip, vertex-coloured), `scripts/upload_asset.py` pushes
   them through Open Cloud (key in `.env`, gitignored), `scripts/build_weapons.py` runs the lot
   and writes an assembly snippet, `Build ▸ MeshTool.build{}` turns the meshes into a Tool
   (invisible box Handle at the fist, blade along +Y, Hitbox, `SkinPart` attributes, white
   MeshParts so vertex colors and skin tints show). All 26 Tools in `ServerStorage ▸ Weapons`
   are mesh Tools now, including the four originals.
3. **Mesh armor / hair / beards / faces.** `blender/parts2mesh.py` converts the Lua blueprints
   (exported from Studio as JSON) into beveled single meshes per colour region;
   `scripts/build_armor.py` uploads and writes the snippet; `Build ▸ MeshArmor.build{}` builds
   the clothing / body Models (Middle box + MeshParts carrying `ColorSlot` / `KeepColor`).
   Road Levy is in; the rest were uploading when this was written (run the snippet in
   `blender/out/armor/assemble_armor.lua`).
4. **Roster.** Free: Shortsword, Arming Sword, Greatsword, War Hammer, Spear. Everything else
   by level or Marks (Pitchfork lvl 2, War Axe / Quarterstaff lvl 3).
5. **Faces** are whole faces now (eyes, brows, mouth, compact around the middle of the head)
   and the Roblox face decal hides under them.
6. **Daily store.** `Catalog ▸ Store` (slots, queue, pins, retired, always, epoch) decides
   which packs are on sale each UTC day; Economy only sells what is on sale; the Hub state
   carries today's packs and the countdown.
7. **Shop rebuilt.** TODAY'S STORE (hero cards with a dressed 3D mannequin per pack, countdown,
   coming-up, earned ledger) · CRATES (chosen skin on a turning stage, scrolling skin strip
   that spins on open, odds + pity) · ARMORY (every weapon with owned-skin counts, stage, skin
   strip, unlock / buy / equip on the active class) · COLORS.
8. **Testing cheats** (Studio): `/marks 5000` `/crowns 500` `/xp 1000` `/level 3`.
9. **Crown bundles** link themselves to Developer Products **by name** at server start: make
   products on the Creator Dashboard named `100 Crowns`, `550 Crowns`, `1200 Crowns`,
   `2600 Crowns` (prices 99 / 499 / 999 / 1999 R$) and nothing needs pasting.

## Studio notes

- Enable **Game Settings ▸ Security ▸ Allow Studio access to API services** so profiles and
  settings save in Studio (every Play currently logs `StudioAccessToApisNotAllowed`).
- Meshes live in the place (ServerStorage ▸ Weapons Tools, ServerStorage ▸ Armor models,
  Cosmetics ▸ Body); their asset ids are in `blender/out/*.json` (gitignored), never in code.
- The menu has test hooks: set attribute `Tab` (PLAY / SHOP / …) or `ShopTab`
  (store / crates / weapons / colors) on `PlayerGui ▸ HubMenu` to switch screens.

## New files

| File | Roblox Studio location | Type | What it is |
|---|---|---|---|
| [ServerScriptService/Build/MeshTool.lua](ServerScriptService/Build/MeshTool.lua) | `ServerScriptService` → `Build` → `MeshTool` | ModuleScript | assembles a weapon Tool from uploaded meshes |
| [ServerScriptService/Build/MeshArmor.lua](ServerScriptService/Build/MeshArmor.lua) | `Build` → `MeshArmor` | ModuleScript | assembles clothing / hair / beard / face Models from meshes |
| [ServerScriptService/Sanitize.server.lua](ServerScriptService/Sanitize.server.lua) | `ServerScriptService` → `Sanitize` | Script | removes free-model weld scripts |
| [ReplicatedStorage/Catalog/Store.lua](ReplicatedStorage/Catalog/Store.lua) | `Catalog` → `Store` | ModuleScript | the daily pack rotation |
| [blender/weapons.py](../blender/weapons.py) · [blender/parts2mesh.py](../blender/parts2mesh.py) · [blender/render.py](../blender/render.py) | — | python (Blender) | procedural weapons; blueprint → mesh converter; preview render |
| [scripts/upload_asset.py](../scripts/upload_asset.py) · [scripts/build_weapons.py](../scripts/build_weapons.py) · [scripts/build_armor.py](../scripts/build_armor.py) | — | python | Open Cloud upload; whole pipelines |

## Replaced files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ReplicatedStorage/Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | `ReplicatedStorage` → `Catalog` | ModuleScript | `STORE`, `storeFor(day)`, `onSale(pack)` |
| [ReplicatedStorage/Catalog/Weapons.lua](ReplicatedStorage/Catalog/Weapons.lua) · [Skins.lua](ReplicatedStorage/Catalog/Skins.lua) · [Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | `Catalog` → … | ModuleScript | roster; `local C`; product names |
| [ReplicatedStorage/Dresser.lua](ReplicatedStorage/Dresser.lua) | `ReplicatedStorage` → `Dresser` | ModuleScript | decal hidden under a Face model |
| [ServerScriptService/Build/Weapons.lua](ServerScriptService/Build/Weapons.lua) · [Body.lua](ServerScriptService/Build/Body.lua) · [Blueprints.lua](ServerScriptService/Build/Blueprints.lua) | `Build` → … | ModuleScript | box Handles; full compact faces; display copies keep the Handle |
| [ServerScriptService/Economy/Economy.lua](ServerScriptService/Economy/Economy.lua) · [EconomyServer.server.lua](ServerScriptService/Economy/EconomyServer.server.lua) | `ServerScriptService` → `Economy` | ModuleScript / Script | store gating; products linked by name |
| [ServerScriptService/Hub/HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) · [Cheats.server.lua](ServerScriptService/Hub/Cheats.server.lua) | `ServerScriptService` → `Hub` | Script | `store` in State + `"Store"` op; `/marks /crowns /xp /level` |
| [StarterPlayerScripts/HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) · [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) · [StarterCharacterScripts/HUD.client.lua](StarterCharacterScripts/HUD.client.lua) | `StarterPlayer` → … | LocalScript | new SHOP; side bar spacer; glyphs; test hooks |
| `Tools/<Weapon>/…` (26) | `ServerStorage` → `Weapons` → each Tool | Config / Server / Client | all generated by `scripts/gen_content.py` (the four originals too) |
