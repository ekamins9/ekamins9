# Updated scripts: three Horde maps the horde walks into

- **The Wildwood**: a dusk forest clearing, a muddy road, an ambushed merchant caravan (a wagon
  on its side, one sagging on a broken wheel, cargo and arrows everywhere, a campfire, lanterns,
  fireflies). The horde comes out of the trees down six trails and along the road (8 gates).
- **Ravenhold**: a ruined keep at night. Smashed main gate under a jammed portcullis, three
  breaches and a fallen corner (5 gates, mist outside each); a roofless chapel, a well, a gibbet,
  graves, a broken colonnade, braziers.
- **Stormbreak**: a palisade camp above a stormy beach, three longships run up on the sand,
  raiders in at the sea gate, two beach gaps and the land gate (4 gates); tents, a smithy, a
  command tent, a bonfire, rain.
- **Horde** now plays the Wildwood, the Colosseum, Ravenhold and Stormbreak. The Sandpit stays
  in the other modes.
- **Bots walk round things**: a tree, a wagon or a wall in the way turns a bot to the open side
  (all maps).
- **Each map's own haze**: maps can set the Atmosphere (`K.atmosphere`); every map starts from
  the place's lighting, so one map's dusk no longer carries into the next.
- **Spawns** that a build put inside a prop are moved out until a body fits (5 on the
  Wildwood, 3 on Stormbreak).

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapWildwood.lua](ServerScriptService/Build/MapWildwood.lua) | ServerScriptService ▸ Build ▸ MapWildwood | ModuleScript | **new** |
| [MapRavenhold.lua](ServerScriptService/Build/MapRavenhold.lua) | ServerScriptService ▸ Build ▸ MapRavenhold | ModuleScript | **new** |
| [MapStormbreak.lua](ServerScriptService/Build/MapStormbreak.lua) | ServerScriptService ▸ Build ▸ MapStormbreak | ModuleScript | **new** |
| [MapProps.lua](ServerScriptService/Build/MapProps.lua) | ServerScriptService ▸ Build ▸ MapProps | ModuleScript | **new**: wagons, wheels, trees, campfire, lantern, brazier, grave, arrow, sack, longship |
| [Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | registers the three maps |
| [MapKit.lua](ServerScriptService/Build/MapKit.lua) | ServerScriptService ▸ Build ▸ MapKit | ModuleScript | `K.atmosphere`; `K.clearSpawns` (run by `K.finish`) |
| [MapLoader.lua](ServerScriptService/Game/MapLoader.lua) | ServerScriptService ▸ Game ▸ MapLoader | ModuleScript | Atmo_* attributes; lighting reset per map |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | `Bot:steer` round obstacles |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | Horde's maps; map titles |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | the maps; painting ground, haze, Horde gates |

The built maps live in `ServerStorage ▸ Maps` in Studio: **save the place** to keep them.
