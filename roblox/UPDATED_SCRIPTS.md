# Updated scripts: two new War battlefields

- **Stormvale**: a storm over a ruined abbey (broken nave walls, a standing arch, pillars), a graveyard either side of the road, mud on the flanks.
- **Duskmoor**: purple heather at golden hour, a ring of cairns, a beacon burning on the tallest.
- Both in War's rotation (9 battlefields now), with banner names and vote pictures shot in Play.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | Stormvale, Duskmoor |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | War's maps, titles, sizes |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | their banner names |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ReplicatedStorage ▸ MapShots ▸ Stormvale, Duskmoor.

---

## Before that: the fight inside the bailey

- **Siege, inside the walls**: once the gate falls, crowd melees break out on each side of the yard being captured (only where the ground is clear and level, away from the buildings); when the yard is taken, its defenders are cut down and the attackers cheer.
- **Checked in Play** on Frostgate: the two melees beside the zone, then the yard falling (no errors).

| File | Studio location | Type | Change |
|---|---|---|---|
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the bailey fight |
| [README.md](README.md) | | doc | |

---

## Before that: Plague Night gets the dungeon's dread

- **Plague Night** now has the dungeons' atmosphere: a cold sickly grade and dark screen edges, the low drone, whispers and groans in the dark, bats, apparitions crossing ahead. (Its own lantern glow and grave-mist arrivals stay as they were.)
- **Checked in Play** on Millfield: no errors.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | Plague Night too |
| [README.md](README.md) | | doc | |
