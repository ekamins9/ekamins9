# Updated scripts: map pictures on the vote, a wider river under Highbridge

- **The vote has its pictures.** Each match map (Millfield, Highbridge, the Sandpit, the
  Colosseum, the Rose Court, Frostgate) was photographed in Studio from its menu view (the
  Colosseum and Highbridge from higher up, where the whole map reads), uploaded as a Decal, and
  its image put in `ReplicatedStorage ▸ MapShots ▸ <map>` (Studio-only; the ids stay out of the
  repo). The vote cards show them.
- **Highbridge's river runs on past the fog.** Its terrain was 416 studs across and its edge
  (a wall of water) showed inside the fog; it is now 640 × 544 with more hills and rocks, so
  the river and banks fade out into the fog with no edge.
- **Class cards**: the fighters are framed a little closer.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Build/Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | Highbridge terrain 640 × 544, more hills and rocks |
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ LoadoutMenu | LocalScript | preview camera closer |

**Studio-only changes (save the place):** `ReplicatedStorage ▸ MapShots` (six StringValues with
the map pictures; each keeps its Decal id in a `Decal` attribute) and `ServerStorage ▸ Maps ▸
Highbridge` rebuilt with the wider river.
