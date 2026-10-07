# Updated scripts: every armor set, weapon, hairstyle and companion redesigned

- **Armor:** all 15 sets and 9 earned pieces rebuilt with real shapes (rounded and tapered
  plates, drums, cones, eggs, rings, trim laid along curves). No two helms share a shape: the
  Tourney Knight's frog-mouth helm and the Champion's crowned sugarloaf, the Blackguard's horns,
  the Iron Crow's beaked hounskull, the Sun Knights' crown of rays, the starter close helm, a
  barbute, an aventail bascinet, a burgonet, a steel wolf's head, coifs, a hood, a sea-cap, a
  head-wrap with a half-mask, a straw hat, a wolf pelt, a bloodied kettle, a long-tailed sallet.
  Legs differ per set too (waders, cavalier boots, striped stockings, cross-gartering, pointed,
  bear-paw and talon sabatons, spiked knees…). Shoulders sit over the arm; closed helms wrap
  the whole round head.
- **Weapons:** all 26 rebuilt in Blender: beveled blades with bright edges and dark fullers,
  shaped guards and pommels, a flamberge Zweihander, a swept-hilt Rapier, a rondel dagger, a
  Kriegsmesser with a nagel, axes cut from real outlines and ground to an edge, langets,
  rondels, crowned hammers and beaks, tassels. Sizes and hitboxes unchanged.
- **Hair and beards:** a bowl spun to the round head's profile with locks, fringes, tails, buns,
  braids and curls; beards with moustaches, braids and beads, forks.
- **Companions:** beasts and drakes rounded out, glints in every eye.
- **Helmet covers:** a helmet can now hide only the beard (`Covers = {"Hair", "Beard"}`) so the
  eyes still show over a mask or out of a coif. Set names and descriptions match the new looks.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Build/Armor.lua](ServerScriptService/Build/Armor.lua) | ServerScriptService ▸ Build ▸ Armor | ModuleScript | every set and piece redesigned; surface helpers (lay trim / slits / studs along curves) |
| [Build/Body.lua](ServerScriptService/Build/Body.lua) | ServerScriptService ▸ Build ▸ Body | ModuleScript | every hairstyle and beard redesigned |
| [Build/Builder.lua](ServerScriptService/Build/Builder.lua) | ServerScriptService ▸ Build ▸ Builder | ModuleScript | new shapes: egg, cone, torus, lathe; rounded and tapered boxes |
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | helmet cover "Beard" |
| [Companions.lua](ReplicatedStorage/Companions.lua) | ReplicatedStorage ▸ Companions | ModuleScript | rounded beasts and drakes, eye glints |
| [Catalog/Pieces.lua](ReplicatedStorage/Catalog/Pieces.lua) | ReplicatedStorage ▸ Catalog ▸ Pieces | ModuleScript | two descriptions; the covers note |
| `ServerStorage/Armor/<Set>/Config.lua` (Blackguard, CoastHarriers, GambesonSkin, GildedCourt, IronCrow, KnightSkin, NightHunters, RiverGuard, RoadLevy, Sellswords, TourneyKnight) | ServerStorage ▸ Armor ▸ <Set> ▸ Config | ModuleScript | names, descriptions, covers |
| [scripts/export_blueprints.lua](../scripts/export_blueprints.lua) | — (run through the Studio MCP) | tool | **new**: the blueprints as JSON, fetched in slices |
| [scripts/join_blueprints.py](../scripts/join_blueprints.py) | — | tool | **new**: joins the slices into blender/out/blueprints.json |
| [blender/preview_armor.py](../blender/preview_armor.py) | — | tool | **new**: renders sets, heads, torsos, legs, hair on an R6 mannequin |
| [blender/preview_weapons.py](../blender/preview_weapons.py) | — | tool | **new**: renders every weapon in a row |
| [blender/weapons.py](../blender/weapons.py) | — | tool | every weapon redesigned |
| [blender/parts2mesh.py](../blender/parts2mesh.py) | — | tool | cone, torus, lathe, rounded / tapered boxes, fewer facets on small parts |
| [scripts/build_armor.py](../scripts/build_armor.py) | — | tool | `--upload-only` (resume), `--reverse` |
| [scripts/build_weapons.py](../scripts/build_weapons.py) | — | tool | `--upload-only`; only weapon blueprints count as weapons |
| [scripts/upload_asset.py](../scripts/upload_asset.py) | — | tool | waits out rate limits and retries |

**Studio-only changes (save the place):** `ServerStorage ▸ Armor ▸ <Set>` clothing models,
`ReplicatedStorage ▸ Cosmetics ▸ Pieces`, `Cosmetics ▸ Body ▸ Hair / Beard` and every Tool in
`ServerStorage ▸ Weapons` (with its display copy in `Cosmetics ▸ Weapons`) rebuilt as MeshParts
from the new meshes (`blender/out/armor/assemble_armor.lua`, `blender/out/assemble.lua`).
