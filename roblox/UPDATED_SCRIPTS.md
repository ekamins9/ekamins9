# Updated scripts: a charge kicks up dust

- **Running regiments raise a trail of dust** behind them in the ground's colour (white on snow, tan on sand, dark on mud): the opening charge in War, the surges, the Siege sally, the warfields.
- **Checked in Play** on Redfield.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | dust behind running regiments |
| [README.md](README.md) | | doc | |

---

## Before that: banners move in the wind

- **Every banner on every map sways** from its top edge in the wind (its tips and trims with it), each on its own rhythm, harder in rain and storms. Only near the camera; nothing sent to the server.
- **Checked in Play** in the Courtyard.

| File | Studio location | Type | Change |
|---|---|---|---|
| [BannerWind.client.lua](StarterPlayerScripts/BannerWind.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [README.md](README.md) | | doc | |

---

## Before that: bats in the dungeons

- **Bats**: now and then a swarm bursts out of the dark ahead of you and flits past over your head, wings beating, with a generated flutter-and-squeak sound.
- **Checked in Play** in the Bone Crypt.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | `WarFX.bats` |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | bats now and then |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ReplicatedStorage ▸ WarAudio ▸ Bats.
