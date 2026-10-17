# Updated scripts: traps in the dungeons' corridors

- **The Depths and Deadvault**: the corridors are trapped. Spike grates punch up when stepped on; pendulum blades swing across (two out of step in a long corridor); dart plates fire across from one wall; fire grates breathe in turn. Each shows itself and has a way past (the wall beside it, a jump, timing, the cool side).
- They hurt anyone, monsters too. The server decides every hit; every screen draws the motion on the server's clock.
- The Depths: two trapped corridors on floor 1, one more each floor down. Deadvault: a third of its corridors.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Traps.lua](ServerScriptService/Game/Traps.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Traps.client.lua](StarterPlayerScripts/Traps.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | lists its corridors |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | sets the traps |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | sets the traps |
| [README.md](README.md) | | doc | |

---

## Before that: more come in the Depths

- **The Depths**: a fight down to its last few can bring a second wave (likelier each floor down). The floor cracks where each will come, glowing the dungeon's colour, flagstones heaving, the ground trembling, then they burst up out of it under a banner in the dungeon's words (THE DEAD RISE, MORE POUR IN…).
- A boss in its second phase calls its servants the same way, once.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | second waves, a boss's servants |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the floor cracking, the burst |
| [README.md](README.md) | | doc | |

---

## Before that: the field before the castle is littered

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
