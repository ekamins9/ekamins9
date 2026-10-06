# Updated scripts: no more flickering surfaces (z-fighting)

- **Where two parts' faces lie flush and overlap** (the path stones round the fountain, a glove
  as wide as its sleeve), the renderer can't tell which is in front and the surface flickers.
  The new `Defight` module finds every such pair and grows the smaller part a hair (0.02 per side
  per notch) so its face sits just in front. Parts of the same size in a row (path stones, planks,
  crenels) get alternating notches, like colours on a map, so no two neighbours end up level
  again. Nothing moves more than a few hundredths of a stud.
- **Every map** runs it on build (MapKit): Sandpit 116 faces, Highbridge 245, Millfield 29,
  Training Yard 51, Courtyard 367, Frostgate 180. A second run on each map finds none left
  (bar 4 wall bottoms on the ground in Sandpit that nobody can see). Faces pointing down onto the
  ground are left alone.
- **The armor and weapons:** the stored clothing models were fixed once (the mesh armor sets 57,
  the part-built pieces 7, weapons 2), and Dresser runs it on every dressed character too, which
  catches clashes between pieces.
- The fountain ring's stones now alternate in height, its edging sits well below and the roads
  run over the ring. Wall footing caps stop short of the wall ends.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Defight.lua](ReplicatedStorage/Defight.lua) | ReplicatedStorage ▸ Defight | ModuleScript | **new**: finds flush faces and nudges them apart |
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | runs it on a dressed character's armor |
| [MapKit.lua](ServerScriptService/Build/MapKit.lua), [Builder.lua](ServerScriptService/Build/Builder.lua) | ServerScriptService ▸ Build | ModuleScript | run it on every map / blueprint model; footing caps inset |
| [MapCourtyard.lua](ServerScriptService/Build/MapCourtyard.lua) | ServerScriptService ▸ Build ▸ MapCourtyard | ModuleScript | the ring stones, edging and roads at distinct heights |

**Studio-only:** every map in `ServerStorage ▸ Maps` was rebuilt, and the armor (`ServerStorage ▸
Armor`, `Cosmetics ▸ Pieces`) and weapons (`ServerStorage ▸ Weapons`) were fixed in place. Save
the place.
