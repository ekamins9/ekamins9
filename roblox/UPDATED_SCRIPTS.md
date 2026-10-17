# Updated scripts: the cavalry are real knights

- **Cavalry riders** (War's charges, the warfields, the Prologue's dawn riders) are now real armoured knights of their side sitting in the saddle with their lances, instead of a coat and a helmet block.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | riders from WarCrowd (`opts.side`) |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `figure`, the riding pose |
| [War.client.lua](StarterPlayerScripts/War.client.lua), [Warfield.client.lua](StarterPlayerScripts/Warfield.client.lua), [Prologue.client.lua](StarterPlayerScripts/Prologue.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | pass the riders' side |

---

## Before that: your breath shows in the cold

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
