# Updated scripts: the field before the castle is littered

- **Siege**: arrows stuck in the ground thick under the walls, shields and broken spears along the road, fallen banners and helmets before the castle (set on the real ground, looks only).
- A shared `Game ▸ Litter` module does it.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Litter.lua](ServerScriptService/Game/Litter.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | litters the field |
| [README.md](README.md) | | doc | |

---

## Before that: War's fields littered with fighting; boss entrances in focus; duels open with a flight

- **War**: every battlefield is littered with earlier fighting (dropped shields, broken spears, arrow clusters stuck in the ground, fallen banners, helmets), thickest round the banners; looks only.
- **Boss entrance**: the boss sharp and the room behind it softly blurred (depth of field).
- **Warfield duels** open with the cinematic flight over the battle down into the ring, once a match.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | the debris |
| [BossIntro.lua](ReplicatedStorage/BossIntro.lua) | ReplicatedStorage | ModuleScript | depth of field |
| [MatchIntro.client.lua](StarterPlayerScripts/MatchIntro.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | warfield duels |
| [README.md](README.md) | | doc | |

---

## Before that: arrows whistle overhead

- **A volley passing over you** (not landing on you) now whistles and hisses as it goes over, from the sky above, in every mode with volleys (War, Siege, the warfields, the battle beyond team fights, the Prologue). A new generated sound.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | the flyby |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ReplicatedStorage ▸ WarAudio ▸ ArrowsOver.
