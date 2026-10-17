# Updated scripts: arrows whistle overhead

- **A volley passing over you** (not landing on you) now whistles and hisses as it goes over, from the sky above, in every mode with volleys (War, Siege, the warfields, the battle beyond team fights, the Prologue). A new generated sound.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | the flyby |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ReplicatedStorage ▸ WarAudio ▸ ArrowsOver.

---

## Before that: two new Siege castles

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
