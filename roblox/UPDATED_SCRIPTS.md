# Updated scripts — mesh orientation fix (hair backwards)

The FBX import turns every pipeline mesh 180° about Y (front/back and
left/right swapped inside each MeshPart). Hair showed it most (fringe at the
back, LongTied's tail over the face); axe heads sat reversed on the haft.
The assemblers now turn each region back, and the meshes already in the
place were turned in Studio (309 MeshParts, each marked `Turned = true` so
the fix never applies twice).

| File | Studio location | Type | Change |
|---|---|---|---|
| [MeshArmor.lua](ServerScriptService/Build/MeshArmor.lua) | ServerScriptService ▸ Build ▸ MeshArmor | ModuleScript | regions placed `* TURN` (180° about Y), marked `Turned` |
| [MeshTool.lua](ServerScriptService/Build/MeshTool.lua) | ServerScriptService ▸ Build ▸ MeshTool | ModuleScript | regions and their MeshWeld offsets `* TURN`, marked `Turned` |

Studio-only (already done, saved by Team Create): ServerStorage ▸ Armor,
ReplicatedStorage ▸ Cosmetics ▸ Pieces / Body, ServerStorage ▸ Weapons
region meshes turned in place.
