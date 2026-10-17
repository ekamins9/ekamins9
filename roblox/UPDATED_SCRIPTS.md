# Updated scripts: your breath shows in the cold

- **Cold breath**: on snowy and winter maps (Frostgate, Ironvale, Rimeholt, War's Frostmere, the Frozen Depths…) a small white puff from every player's mouth every few seconds, quicker when running.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Weather.client.lua](StarterPlayerScripts/Weather.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | cold breath |

---

## Before that: sentries on the Courtyard's walls

- **The Courtyard is a garrison**: Crown sentries walk the battlements, stopping at the ends of their stretch to look out over the walls.
- **Checked in Play** in the Courtyard.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CourtyardGuards.client.lua](StarterPlayerScripts/CourtyardGuards.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `sentry` |
| [README.md](README.md) | | doc | |

---

## Before that: two more battlefield duel maps

- **Sunfall** (desert dunes at dusk, a huge moon) and **Ravenfield** (night, storm and lightning, the ring lit by torches): the duel ring in the middle of the battle, now five maps in The Lists. Vote pictures shot with the battle running.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapForge.lua](ServerScriptService/Build/MapForge.lua) | ServerScriptService ▸ Build | ModuleScript | Sunfall, Ravenfield |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | in The Lists; titles, sizes, Ravenfield's storm |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ServerStorage ▸ Maps ▸ Sunfall, Ravenfield; ReplicatedStorage ▸ MapShots ▸ Sunfall, Ravenfield.
