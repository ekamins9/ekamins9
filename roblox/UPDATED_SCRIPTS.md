# Updated scripts: the maps, fixed

Sandpit, Highbridge and Millfield are rebuilt (already in `ServerStorage ▸ Maps`).

- **Roofs and pines are real cones now.** The old four-wedge "cones" had their wedges facing
  the wrong way and read as boxes. `K.cone` builds a 12-sided spire from wedges whose tall faces
  meet at the axis, with a gold finial on towers. Pines use three 8-sided tiers.
- **Gates are open round arches.** `K.arch` is two piers, a ring of voussoirs with a keystone,
  stepped fill in the corners and a lintel course. The old solid disc and fill box looked like
  a closed gate. `K.archRing` (the ring alone) puts real arches under Highbridge's deck.
- **Sandpit:**
  - The gate arch now runs along the wall, which closes in from both towers.
  - The pit stairs start on the floor and climb out to the rim, through gaps in the rim blocks.
  - The terrain box is big enough that no dune is cut off or left behind.
  - The sand is a warm colour.
- **Highbridge:** the bridge-side gatehouse wall is open at the gate (it was solid), both flanks
  are walled (one side used to drop into the void), and the torches are moved off the piers.
- **Millfield:** the windmill has a cone cap, house gables are real triangles (two mirrored
  wedges), the terrain box is bigger, and the field and path colours are set.
- **Terrain colours per map:** `K.terrainColors` stores `TerrainColor_<Material>` attributes.
  MapLoader applies them on load and restores the old colours on unload.
- **Smaller fixes:** banner tips point down, and `K.terrain` clears its box even if painting
  fails.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapKit.lua](ServerScriptService/Build/MapKit.lua) | ServerScriptService ▸ Build ▸ MapKit | ModuleScript | `K.cone`, `K.archRing`, round `K.arch`, cone spires + finials, cone pines, gables, banner tips, `K.terrainColors`, safe `K.terrain` |
| [Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | Sandpit gate / stairs / rim / terrain box / colours; Highbridge gate walls, flanks, under-deck arches; Millfield cone cap, terrain box, colours |
| [MapLoader.lua](ServerScriptService/Game/MapLoader.lua) | ServerScriptService ▸ Game ▸ MapLoader | ModuleScript | applies and restores `TerrainColor_*` |
