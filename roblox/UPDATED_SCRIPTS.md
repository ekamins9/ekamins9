# Updated scripts: sentries on the Courtyard's walls

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

---

## Before that: the rest of the horde waits on the hills

- **The Horde's host**: beyond each gate and past the map's edge, blocks of the horde's soldiers stand facing your camp (torches at night). Each wave starts with their roar, a horn and war drums; they grow deeper as you survive. Only on your screen; never inside the play area, so nobody takes them for the wave.
- **Not shipped**: a victory camera on the round's winner (the server swaps the winner's body the moment the round ends, so there's nobody to film without changing the round flow).
- **Checked in Play**: the Horde on Wildwood.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HordeHost.client.lua](StarterPlayerScripts/HordeHost.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [README.md](README.md) | | doc | |
