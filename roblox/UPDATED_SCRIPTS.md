# Updated scripts: two new Siege castles

- **Duskwall** (a desert castle at dusk under a great moon; champion: the Dune Khan) and **Mournhold** (a castle in the dawn mist; champion: Lady Morwen). 12 Siege castles now; both get the whole siege battle (archers on the walls, ladders, towers, flank battles, fires). Vote pictures shot with the battle running.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapForge.lua](ServerScriptService/Build/MapForge.lua) | ServerScriptService ▸ Build | ModuleScript | Duskwall, Mournhold |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | Siege maps, titles, sizes |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ServerStorage ▸ Maps ▸ Duskwall, Mournhold; ReplicatedStorage ▸ MapShots ▸ Duskwall, Mournhold.

---

## Before that: two new War battlefields

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
