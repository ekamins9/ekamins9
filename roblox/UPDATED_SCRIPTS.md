# Updated scripts: burning pitch from the walls

- **Siege**: the defenders hurl pots of burning pitch down from the walls onto the shield blocks at the ladders (men fall under them).
- **Checked in Play** on Thornwall.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | pitch pots |
| [README.md](README.md) | | doc | |

---

## Before that: the steel of the battle lines, up close

- **Near a fighting line you hear the blows**: the men fighting in the front rank ring out with clashes, parries, blocks and blows on plate from where they stand (the same sounds as the real fights), a few times a second.
- **Men falling near you** cry out and hit the ground with an armoured thud.
- **Checked in Play** on Redmeadow: ~2.5 a second next to a line, no errors.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | close-up steel |
| [README.md](README.md) | | doc | |

---

## Before that: fire arrows at night

- **At night every volley is fire arrows**: streaks of flame arcing across the dark (the armies' volleys and the engines' alike).
- **Checked in Play** on Ravenfield.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | fire arrows (`opts.fire`, by default at night) |
| [README.md](README.md) | | doc | |
