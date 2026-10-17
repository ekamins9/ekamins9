# Updated scripts: arrows in the shield

- **Every fight with bows, and War's volleys**: an arrow you catch on a raised shield stays standing in the board, five at most, each for 20 seconds. After a volley your shield bristles. Never in a body: the game stays Mild.

| File | Studio location | Type | Change |
|---|---|---|---|
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat | ModuleScript | `shieldFace`, `onBoard` (in the board's own frame: only clients raise the shield), `SHIELD_ARROWS`, `RangedServer.shieldCatch`; arrows on a body weightless, not catchable, and held by a Weld with its offset (a WeldConstraint's offset is worked out on each client, against a shield only the client has raised) |
| [Engines.lua](ServerScriptService/Game/Engines.lua) | ServerScriptService ▸ Game | ModuleScript | a War volley that falls on a raised shield leaves an arrow or two in it (`opts.arrows`) |
| [README.md](README.md) | | doc | |

---

## Before that: wanderers in the Depths

- **The Depths**: from the second floor, a pair of the floor's monsters (two pairs on the third) walk the halls from room to room, to be met in a corridor. Their own fight, no gates; they go with the floor.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `wanderers`, `WANDER`; called on each new floor |
| [README.md](README.md) | | doc | |

---

## Before that: your heart and your breath

- **Every fight**: low on health, your heart pounds (quicker the worse it is); out of stamina, you pant. Both were silent before (their SoundConfig slots were empty); they now use the game's own sounds.

| File | Studio location | Type | Change |
|---|---|---|---|
| [InjuryFX.client.lua](StarterCharacterScripts/InjuryFX.client.lua) | StarterPlayer ▸ StarterCharacterScripts | LocalScript | `loopOf`: a silent slot falls back to WarAudio ▸ Heartbeat / Breathing |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Breathing (a Sound; save the place).

---

## Before that: life in the Courtyard

- **The Courtyard** has life about it now. A smithy in the north-east corner, its forge glowing and smoking. A market row on the west wall: two stalls under striped awnings, with fruit and vegetables, onions, cloth and pots. A wagon, hay and a trough by the gate, washing on a line, firewood stacked, and bunting strung between the oaks round the fountain.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapCourtyard.lua](ServerScriptService/Build/MapCourtyard.lua) | ServerScriptService ▸ Build | ModuleScript | "LIFE ABOUT THE PLACE"; SmithSpot |
| [Pastimes.client.lua](StarterPlayerScripts/Pastimes.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the Hatchery: only the nearest empty nest says EMPTY NEST (three piled into one unreadable label) |
| [README.md](README.md) | | doc | |

Studio-only: ServerStorage ▸ Maps ▸ Courtyard was rebuilt from the code (`require(game.ServerScriptService.Build.Maps).build("Courtyard")`; a fresh build of the old code matched the saved map exactly first). Save the place. The old one is kept as ServerStorage ▸ TMP_CourtyardBackup until then; delete it once saved.

---

## Before that: the portraits watch

- **The dungeons**: the paintings are portraits now, a pale sitter in dark clothes in a gilt frame, hung flat against the wall. Their eyes follow you about the room, and now and then, with your back to one, they burn red and something whispers.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | `P.painting`: a portrait model, hung against the wall facing the room |
| [Portraits.client.lua](StarterPlayerScripts/Portraits.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | **new**: the eyes follow; the red-eyed moment |
| [README.md](README.md) | | doc | |

---

## Before that: shouts in the fight

- **Every fight**: the soldiers and monsters round you call out, in a short shout over their heads in their side's colour. They cry "FOR THE CROWN!" as they charge, "SHIELDS UP!" in the thick of it, "I'M HIT!" when hurt, "NEXT!" over a fallen foe, "AVENGE THEM!" when a friend falls. Goblins, orcs, elves and bandits have their own lines; the undead stay silent.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Shouts.client.lua](StarterPlayerScripts/Shouts.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | **new** |
| [README.md](README.md) | | doc | |

---

## Before that: look up

- **The Depths and Deadvault**: now and then some of a waiting room's climbers (spiders, ghouls, goblins, vampires, wraiths) cling to the ceiling, upside down in the dark. Walk under one, or wake the room, and they drop on you: grit sifts down, a shriek, a thud and dust.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Clingers.lua](ServerScriptService/Game/Clingers.lua) | ServerScriptService ▸ Game | ModuleScript | **new**: `can`, `cling`, `drop`, `under` (shared) |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `cling`, `drop`, `CLING_CHANCE`; the walk-under trigger |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | a third of its rooms have clingers; each drops when it notices you or you're under it |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the drop: grit, a cry, a thud |
| [README.md](README.md) | | doc | |

---

## Before that: the Shade in Deadvault

- **Deadvault**: three minutes before the collapse the dark stirs, and the Shade rises about 110 studs from the nearest raider and hunts whoever is still inside. It can't be fought; get out.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Shade.lua](ServerScriptService/Game/Shade.lua) | ServerScriptService ▸ Game | ModuleScript | `shade:stir()`, `manual`, `near`, banner `words` |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `SHADE_AT`; runs the Shade |
| [README.md](README.md) | | doc | |

---

## Before that: the Shade

- **The Depths: don't linger.** Dawdle on a floor (300 / 260 / 220 s away from any fight) and every torch sputters as THE DARK STIRS. 40 s later THE SHADE COMES: a tall hooded thing with two pale eyes and long grey claws, drifting through the walls after the nearest of you. It can't be fought, only outpaced. Its touch is cold (30, halved by armour), and then it sinks away and comes again. It waits outside the room while you fight, and goes when you take the stairs. Near it, the torches gutter, the world drains of colour, your heart pounds and its breath and whispers close in.
- **Chests**: `Loot.chest` keeps any chest whose facing is no facing at all (NaN), so none can be lost below the map again.
- What's new card: version 2026-10-17c.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Shade.lua](ServerScriptService/Game/Shade.lua) | ServerScriptService ▸ Game | ModuleScript | **new**: the count, the stir, the hunt, the touch |
| [Shade.client.lua](StarterPlayerScripts/Shade.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | **new**: the figure, its breath, the drained colour, the heartbeat |
| [TorchFlicker.client.lua](StarterPlayerScripts/TorchFlicker.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | sputters as the dark stirs; gutters near the Shade |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | runs the Shade (start, tick, descend, stop) |
| [Loot.lua](ServerScriptService/Game/Loot.lua) | ServerScriptService ▸ Game | ModuleScript | NaN facing guard in `Loot.chest` |
| [WhatsNew.client.lua](StarterPlayerScripts/WhatsNew.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | 2026-10-17c |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ ShadeBreath and Heartbeat (Sounds; save the place).

---

## Before that: treasure vaults, and the lost chests

- **The Depths**: a treasure room is now always a vault: its chest gilded (Rare) on a dais under a chandelier, gold piled round it, stone guardians and urns by the walls. It is the room the treasure-room mimic waits in, and now it actually can.
- **Fixed**: a chest set in a room's very middle (a treasure room's, a boss's hoard) was turned to face that same point. That gave it no facing at all and lost it far below the map. It now faces the way in.
- **Fixed**: the treasure room's chest was the plain kind, so its mimic never came. It now rolls as the treasure kind.
- A vault's chandelier, right over the chest, hangs fast and never falls.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | treasure rooms are `vault`s; `P.chandelier` returns its model; the vault's is `Secure` |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `placeChest` facing in a room's middle; treasure room's chest kind |
| [Traps.lua](ServerScriptService/Game/Traps.lua) | ServerScriptService ▸ Game | ModuleScript | skips `Secure` chandeliers |
| [README.md](README.md) | | doc | |

---

## Before that: the Depths' rooms dressed

- **The Depths**: most fight rooms are now something, as a Deadvault raid's are: a great hall with pillars and chandeliers, a crypt of sarcophagi, the cells, a library, a chapel with its altar and pews, a cavern, a nest. Each theme leans its own way. Every floor reads as a place rather than a run of bare rooms.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | Depths room types, `DEPTHS_ARCH`, non-raid `keep` |
| [README.md](README.md) | | doc | |

---

## Before that: chandeliers fall

- **Deadvault**: about a third of the chandeliers in the raid's halls, libraries and vaults hang loose. Walk under one and its chain creaks, grit sifts down, it shudders, and a second later it crashes to the floor. Get clear, or it hurts. It stays down with its candles out.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Traps.lua](ServerScriptService/Game/Traps.lua) | ServerScriptService ▸ Game | ModuleScript | `BUILD.chandelier`, `Traps.CHANDELIER`; chandeliers kept on re-arm |
| [Traps.client.lua](StarterPlayerScripts/Traps.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the creak, the fall, the crash |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | a chandelier is one model |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Creak (a Sound; save the place).

---

## Before that: bones underfoot

- **The dungeons**: walk through a pile of bones and they clatter aside from your feet, the skull rolling away.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `underfoot` |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ BoneCrunch (a Sound; save the place).

---

## Before that: battle wear on phones

- **Phones** keep fewer battle marks (4 to a fighter rather than 12, within 40 studs), so a War brawl stays light.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Scuffs.client.lua](StarterPlayerScripts/Scuffs.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | phone caps |
| [README.md](README.md) | | doc | |

---

## Before that: the blade nicks the walls

- **A blade that hits the world leaves its mark**: a dark groove with pale chipped edges in stone, a dark gash in wood, a bright scratch on metal. Each fades after a minute and a half.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Scuffs.client.lua](StarterPlayerScripts/Scuffs.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | world nicks |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat | ModuleScript | ScuffEvent on a wall hit |
| [README.md](README.md) | | doc | |

---

## Before that: battle wear

- **A fight shows on you**: every clean blow leaves its mark where it landed, a bright scratch on plate and mail or a dark scuff on cloth and leather, laid along the blade's path. There are a dozen at most to a fighter, and they're gone when you respawn. It's drawn on each screen near the fight and costs no network traffic beyond the hit itself.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Scuffs.client.lua](StarterPlayerScripts/Scuffs.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat | ModuleScript | ScuffEvent on a clean hit |
| [README.md](README.md) | | doc | |

---

## Before that: a wraith's last breath

- **A wraith's death**: instead of simply vanishing, it comes apart in a burst of its own pale mist.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Monsters.lua](ServerScriptService/Combat/Monsters.lua) | ServerScriptService ▸ Combat | ModuleScript | mist burst |
| [README.md](README.md) | | doc | |

---

## Before that: Web Spit

- **The Spider Queen and the Broodmother spit webs**: a pale ring lights under you, and a moment later a web lands there. Still in it, you're stuck fast for a moment, silk over your feet and legs. Dodge out of the ring.
- A new boss move kind any monster can use: `web`.

| File | Studio location | Type | Change |
|---|---|---|---|
| [BossMoves.lua](ServerScriptService/Combat/BossMoves.lua) | ServerScriptService ▸ Combat | ModuleScript | `K.web` |
| [Bestiary.lua](ReplicatedStorage/Catalog/Bestiary.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | Queen and Broodmother get it |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | BossFX "Webbed" |
| [README.md](README.md) | | doc | |

---

## Before that: pigeons in the Courtyard

- **The Courtyard** has a flock of pigeons pecking about the fountain. Run through them and they all go up at once in a clatter of wings, off over the walls, and drift back down a while later.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Pigeons.client.lua](StarterPlayerScripts/Pigeons.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Pigeons (a Sound; save the place).

---

## Before that: Kingsbridge's fields

- **War: Kingsbridge** has plots of dark ploughed earth on its flanks (farmland seen from the hills), and its mud is a darker, earthier brown.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | `ploughed`, Kingsbridge mud |
| [README.md](README.md) | | doc | |

---

## Before that: the Abbey's procession

- **The Hollow Abbey**: sometimes the pale figure crossing the dark ahead of you is a whole procession of the abbey's dead brothers, five to seven of them filing slowly across in step, with a faint chant going with them.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | procession |

---

## Before that: gargoyles that stand as statues

- **The dungeons**: a sleeping Gargoyle stands as a stone statue on a plinth, eyes dead, until it notices you. Then its stone shell bursts off in tumbling shards and it comes for you.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `petrify` / `wake` |
| [README.md](README.md) | | doc | |

---

## Before that: the Banshee

- **A new champion: the Banshee**, a pale wraith in the Bone Crypt, the Crimson Manor and the Hollow Abbey. Now and then it throws its head back as a ring fills round it, then screams. Anyone in the ring is hurt a little, thrown a step, slowed a moment, and left half deaf for a few seconds with their ears ringing. Get out of the ring.
- A new boss move kind any monster can use: `wail`.

| File | Studio location | Type | Change |
|---|---|---|---|
| [BossMoves.lua](ServerScriptService/Combat/BossMoves.lua) | ServerScriptService ▸ Combat | ModuleScript | `K.wail` |
| [Bestiary.lua](ReplicatedStorage/Catalog/Bestiary.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | Banshee |
| [Dungeons.lua](ReplicatedStorage/Catalog/Dungeons.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | elite pools |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | BossFX "Wail" |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Wail (a Sound; save the place).

---

## Before that: the chosen class's armour reads

- **Choose your class**: on the selected (bright blue) card, the armour line (HEAVY ARMOR in red, and the rest) is lifted towards white so it reads; the other cards keep their colours.

| File | Studio location | Type | Change |
|---|---|---|---|
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | selected card's tag colour |

---

## Before that: every emoji draws

- **Fixed: six emoji too new for the game's emoji font showed as boxes**:
  - Lucky Coin 🪙 is now 🍀.
  - Eagle Feather 🪶 is now 🦅.
  - Elixir of Stone 🪨 is now ⛰.
  - Second Wind 🫁 is now 💨.
  - Mirror Image 🪞 is now 🎭.
  - Levitate 🪶 is now ☁.
  - The bolas 🪢 are now ⛓.
- The What's new card's spider 🕷 drew almost black on the dark card, so it's now 🕸.
- Every other emoji the game uses was rendered and checked.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Loot.lua](ReplicatedStorage/Catalog/Loot.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | glyphs |
| [Powers.lua](ReplicatedStorage/Catalog/Powers.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | glyphs |
| [Powers.client.lua](StarterPlayerScripts/Powers.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | bolas glyph |
| [WhatsNew.client.lua](StarterPlayerScripts/WhatsNew.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | 🕸 |

---

## Before that: every symbol draws

- **Fixed: symbols the game's fonts can't draw** (they showed as boxes or nothing). A sweep rendered every non-ASCII character the UI uses in both fonts (GothamBold, FredokaOne) and replaced the failures:
  - The tutorial's guide arrows (the Prologue's, the training yard's) were ➤ and are now ▶.
  - The magic stance hint and a threat's default mark were ✦ and are now ✨.
  - The showcase's MAPS dropdown was ▾ and is now ▼.
  - The PlayStation cross in controller hints was ✕ and is now ×.
- **"OWNED ✔", "READY ✔", "DONE ✔" and the rest** (28 places): ✔ draws as a dark emoji that ignores the text's colour, nearly invisible on the dark panels. ✓ draws in the text's own colour (the green of "owned").

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ✓ |
| [AdminPanel.client.lua](StarterPlayerScripts/AdminPanel.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ✓ |
| [Pastimes.client.lua](StarterPlayerScripts/Pastimes.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ✓ |
| [Showcase.client.lua](StarterPlayerScripts/Showcase.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ✓, ▼ |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ✓, ▶ |
| [Prologue.client.lua](StarterPlayerScripts/Prologue.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ▶ |
| [StanceSwap.client.lua](StarterPlayerScripts/StanceSwap.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ✨ |
| [Threats.client.lua](StarterPlayerScripts/Threats.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ✨ |
| [InputHints.lua](ReplicatedStorage/InputHints.lua) | ReplicatedStorage | ModuleScript | × |
| [UIClicks.client.lua](StarterPlayerScripts/UIClicks.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | × is a close button too |

---

## Before that: the pass crown shows

- **Fixed**: the season pass holder's crown before a name (the scoreboard, the round's result, the dungeon lobby, name tags) was a chess-piece glyph the game's font lacks, so it showed as a box. It's now the crown emoji, which renders everywhere.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | 👑 |
| [DungeonMenu.client.lua](StarterPlayerScripts/DungeonMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | 👑 |
| [NameTags.client.lua](StarterPlayerScripts/NameTags.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | 👑 |

---

## Before that: boiling oil over the gate

- **Siege**: while the gate holds, the defenders now and then tip a cauldron over the edge of the gatehouse. A column of smoking oil pours down onto the gate's foot, steam rolls off the ground with a hiss, and the men massed there scatter. It's for looks only and hurts no player.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `oil` |
| [README.md](README.md) | | doc | |

---

## Before that: what a blow knocks off spiders and mimics

- **Hitting a spider** knocks flecks of dark shell off it; **hitting a mimic**, wood splinters (the game stays Mild: no blood).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Injury.lua](ServerScriptService/Combat/Injury.lua) | ServerScriptService ▸ Combat | ModuleScript | `chitin`, `wood` sheds |
| [README.md](README.md) | | doc | |

---

## Before that: the Spider Queen's lair

- **The Silk Caverns' boss room** is dressed as the Queen's nest: webs strung across its corners, egg sacs heaped by the walls, cocoons hanging about her dais.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | lair nest |
| [README.md](README.md) | | doc | |

---

## Before that: clouds spared on phones

- **Phones** skip the fair-weather clouds (they cost about a tenth of the frame in War); the weather's own clouds still come.
- The Depths' header comment lists the Silk Caverns.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CinematicGrade.client.lua](StarterPlayerScripts/CinematicGrade.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | no fair clouds on phones |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | header |
| [README.md](README.md) | | doc | |

---

## Before that: the Silk Caverns, an eighth dungeon

- **The Silk Caverns**: a new dungeon theme for The Depths and Deadvault. Rough caves in sickly light, mostly spiders' nests, corridors strung with webs, spiders dropping on threads every little while, and the Cave Spiders, Broodmothers and risen cocooned dead that live there.
- **Its boss, Arachnessa, Queen of the Silk**: a spider the size of a cart. She pounces, rushes, bursts venom and spits web; at half health the brood awakens and she calls her spiders about her while the ceiling crawls.
- **Staff**: the admin "next map" can now pick a procedural mode's theme (a dungeon theme, a War field), not only a saved map.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeons.lua](ReplicatedStorage/Catalog/Dungeons.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | SilkCaverns |
| [Bestiary.lua](ReplicatedStorage/Catalog/Bestiary.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | SpiderQueen |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | Depths and Deadvault maps, title |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | rooms, odds, nests, light |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | wave line |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | wakers |
| [Traps.lua](ServerScriptService/Game/Traps.lua) | ServerScriptService ▸ Game | ModuleScript | web-heavy weights |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | grade, echo, colours, more dangling spiders |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game | Script | admin next map: procedural themes |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ MapShots ▸ SilkCaverns (its vote picture; save the place).

---

## Before that: web traps

- **A new corridor trap**: a sheet of web strung across the passage (the Warrens and the Crypt mostly). Walk into it and it clings, slowing you as it tears, and half the time its spider drops in for you. Cut it with your blade first and it falls harmlessly.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Traps.lua](ServerScriptService/Game/Traps.lua) | ServerScriptService ▸ Game | ModuleScript | `BUILD.web`, `Traps.WEB`, weights |
| [README.md](README.md) | | doc | |

---

## Before that: mimics in the Depths too

- **The Depths**: a treasure room's chest is now and then a mimic (gilded from the third floor). Kill it and the chest is back, and everyone gets their pick as before.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `Depths:mimic`, `MIMIC_CHANCE` |
| [README.md](README.md) | | doc | |

---

## Before that: mimics

- **Deadvault**: now and then the chest you open was never a chest. A MIMIC! It stands up on four stubby legs, its lid a mouth of teeth over a tongue, eyes glowing inside, and comes for you, snapping. An ornate chest is a bigger, harder Gilded Mimic. Kill it and the chest is back where it stood, open, with its hoard to search.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `Deadvault:mimic`, `MIMIC_CHANCE` |
| [Containers.lua](ServerScriptService/Game/Containers.lua) | ServerScriptService ▸ Game | ModuleScript | a chest's first look may be a mimic |
| [Monsters.lua](ServerScriptService/Combat/Monsters.lua) | ServerScriptService ▸ Combat | ModuleScript | `buildMimic` |
| [Bestiary.lua](ReplicatedStorage/Catalog/Bestiary.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | Mimic, GildedMimic |
| [SpiderLegs.client.lua](StarterPlayerScripts/SpiderLegs.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the mimic's lid and legs |
| [README.md](README.md) | | doc | |

---

## Before that: skeletons fall to bones

- **Monsters' deaths**: a skeleton falls apart into a heap of its bones with the skull on top (one about to stand back up doesn't), and a wraith simply vanishes. A player's kill effect still overrides both.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Monsters.lua](ServerScriptService/Combat/Monsters.lua) | ServerScriptService ▸ Combat | ModuleScript | remains by body |
| [README.md](README.md) | | doc | |

---

## Before that: a spider on the Depths card

- **The Play menu's Depths card** shows a Cave Spider among its skeletons (its still copy is published with the others at start).

| File | Studio location | Type | Change |
|---|---|---|---|
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game | Script | CaveSpider display |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | Depths scene |

---

## Before that: spiders' nests

- **The dungeons** (the Goblin Warrens, the Bone Crypt): some rooms are spiders' nests, with webs strung across the corners, egg sacs heaped on silk, cocoons hanging on threads from the ceiling, and the bones of what was caught. In The Depths, a nest's fighters are mostly Cave Spiders; in a Deadvault raid, the remains there can be searched.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | `A.nest`, `NESTS`, nest in the raids' rooms |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | a nest's roster |
| [README.md](README.md) | | doc | |

---

## Before that: spiders that fight

- **New monsters: spiders.** The **Cave Spider** is small, quick and comes in numbers, in the Goblin Warrens and the Bone Crypt (and their Deadvault raids). The **Broodmother** is an elite of the Warrens, huge and red-marked, and calls up cave spiders. Both come straight at you with lunging bites: no guard, no parries. Their eight legs walk in a real gait, they rear as they bite, they skitter as they run, and their legs curl when they die.
- Built on the existing monster system: the body is a hidden fighter (`body = "spider"`), the fangs are a hidden blade that never drops, and a new `Beast` bot profile drives it.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Monsters.lua](ServerScriptService/Combat/Monsters.lua) | ServerScriptService ▸ Combat | ModuleScript | `buildSpider`, `hideBody`, Beast minions |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat | ModuleScript | `SKILLS.Beast` |
| [Pickup.lua](ServerScriptService/Combat/Pickup.lua) | ServerScriptService ▸ Combat | ModuleScript | `NoDrop` |
| [Ragdoll.lua](ServerScriptService/Combat/Ragdoll.lua) | ServerScriptService ▸ Combat | ModuleScript | skips `Rigid` joints |
| [Bestiary.lua](ReplicatedStorage/Catalog/Bestiary.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | CaveSpider, Broodmother |
| [Dungeons.lua](ReplicatedStorage/Catalog/Dungeons.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | Warrens and Crypt rosters |
| [SpiderLegs.client.lua](StarterPlayerScripts/SpiderLegs.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [Footsteps.client.lua](StarterPlayerScripts/Footsteps.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | spiders leave no steps |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | spiders skitter in the dark |
| [README.md](README.md) | | doc | |

---

## Before that: windows lit at night

- **After dark** (the Prologue's Stormwatch, Plague Night, the Invasion, the night warfields), about two in three of the houses' and towers' windows glow with warm light, spilling a little onto the ground outside. They go dark again at dawn.

| File | Studio location | Type | Change |
|---|---|---|---|
| [NightWindows.client.lua](StarterPlayerScripts/NightWindows.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [README.md](README.md) | | doc | |

---

## Before that: what's new, again

- **The What's new card** comes back once (version `2026-10-17b`) with today's additions: Amberwood; stone, timber and sky; shell-shock; spiders and light shafts; starting in first person. It also keeps the new dungeons and the traps.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WhatsNew.client.lua](StarterPlayerScripts/WhatsNew.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | NEWS |

---

## Before that: start in first person

- **Settings ▸ Start in**: choose whether each spawn begins over the shoulder or through your own eyes, blade in hand. The View key still switches any time.

| File | Studio location | Type | Change |
|---|---|---|---|
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage | ModuleScript | `StartView` choice |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts | LocalScript | reads it at spawn |
| [README.md](README.md) | | doc | |

---

## Before that: Amberwood, an eleventh War field

- **War: Amberwood**, an autumn wood's edge in the late gold light. Red, rust and gold oaks line both flanks, fallen leaves drift down and lie in drifts across golden grass, and there's an orchard, a half-timbered hunting lodge and a woodcutters' camp. Its sky can turn to rain mid-battle. Its five banners are the South Woods, the Orchard, the Hunting Lodge, the Woodpile and the North Woods.
- Autumn oaks are a `K.oak` palette; drifting leaves are a new WarFX weather, `leaves`.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | Amberwood theme, feature, paint; `autumn` trees |
| [MapProps.lua](ServerScriptService/Build/MapProps.lua) | ServerScriptService ▸ Build | ModuleScript | `K.oak` palette |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | `leaves` weather |
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | leaves can turn to rain |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | War maps, title, fighters |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | banner names |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ MapShots ▸ Amberwood (its vote picture; save the place).

---

## Before that: light from above

- **The dungeons**: in a few rooms a floor, an iron grate in the ceiling glows with pale light from somewhere above, and the light falls through in a soft column to a pool on the floor, dust turning slowly in it. The Drowned Halls' light is sea-green and the Abbey's violet-white; the Ember Forge has none.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | `shaft` |
| [README.md](README.md) | | doc | |

---

## Before that: castle walls in rubble stone

- **Castle walls, towers and the Courtyard's keep** are rubble masonry (Cobblestone) instead of this morning's brick, which came out pinkish on white and grey castles. The saved maps were switched too (save the place).

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapKit.lua](ServerScriptService/Build/MapKit.lua) | ServerScriptService ▸ Build | ModuleScript | `K.wall` / `K.tower` default Cobblestone |
| [MapCourtyard.lua](ServerScriptService/Build/MapCourtyard.lua) | ServerScriptService ▸ Build | ModuleScript | keep |
| [README.md](README.md) | | doc | |

---

## Before that: spiders

- **The dungeons** (the Bone Crypt, the Goblin Warrens, the Crimson Manor, the Hollow Abbey): now and then a spider lets itself down on its thread from the ceiling ahead of you. It hangs at the height of your face, turning, legs working, red eyes catching your lantern, then whips back up into the dark with a skitter. It goes sooner if you walk up to it.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | spiders |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Skitter (a Sound; save the place).

---

## Before that: shell-shocked

- **A blast right by you** (a trebuchet stone, a battle-mage's fireball) leaves you half deaf for a few seconds: the battle goes muffled and far away, your ears ring, your eyes swim, and then it all comes back. Turning screen shake off turns this off too.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Hearing.lua](ReplicatedStorage/Hearing.lua) | ReplicatedStorage | ModuleScript | new |
| [Hearing.client.lua](StarterPlayerScripts/Hearing.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | `blast` rings it |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ EarRing (a Sound; save the place).

---

## Before that: clouds over the open-air maps

- **The sky**: fair-weather clouds drift over every open-air map (the Courtyard, War, Siege, the arenas, the Lists...). A storm, rain or snow takes the sky over while it lasts and gives it back after. None over the caldera or indoors.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CinematicGrade.client.lua](StarterPlayerScripts/CinematicGrade.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | clouds |
| [README.md](README.md) | | doc | |

---

## Before that: the Courtyard's keep in stone; the Hatchery's labels

- **The Courtyard**: the keep is coursed stone on a cobbled footing like the walls; the Rest Inn is plastered under clay tiles. The saved Courtyard was converted too (save the place).
- **Fixed**: from across the Courtyard, the Hatchery's three nest labels ("EMPTY NEST", "[E] GET EGGS") piled into one garbled line. They now show only from close by (28 studs).

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapCourtyard.lua](ServerScriptService/Build/MapCourtyard.lua) | ServerScriptService ▸ Build | ModuleScript | keep / inn materials |
| [Pastimes.client.lua](StarterPlayerScripts/Pastimes.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | nest labels' range |

---

## Before that: castle stone in courses, shingled spires

- **Castle walls and towers** (the Courtyard, every castle, Frostgate, the arenas' towers, the Crownlands, Stormwatch, the Gilded Rat) are coursed stone instead of smooth slate: dressed blocks on rough cobbled footings. Tower spires are shingled instead of cloth.
- **The saved maps** (ServerStorage ▸ Maps, Studio-only) were converted the same way. Their 30 old box houses (Millfield, Marshfen, Frosthollow, HollowGrove, Harvestvale, Pinewatch) were rebuilt in place as half-timbered cottages. **Save the place** to keep this.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapKit.lua](ServerScriptService/Build/MapKit.lua) | ServerScriptService ▸ Build | ModuleScript | `K.wall` / `K.tower` materials, `opts.roofMaterial` |
| [README.md](README.md) | | doc | |

---

## Before that: half-timbered villages, a filmic grade

- **Every house in the game** is now a half-timbered cottage: plaster on a stone plinth, a dark timber frame (posts, studs, braces), shuttered windows on three sides, a framed door on a step, clay-tiled roofs with a ridge beam, and on about half a smoking chimney. War's villages, the Crownlands, Stormwatch, the Horde's town and the Courtyard's backdrop all change at once. The new trim doesn't collide, so nobody's path changes.
- **The open-air maps' grade**: the colour is pulled back from Roblox's lime greens and bright blues, with more contrast and warm light, for a painted, sunlit-field look.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapKit.lua](ServerScriptService/Build/MapKit.lua) | ServerScriptService ▸ Build | ModuleScript | `K.house` rebuilt |
| [CinematicGrade.client.lua](StarterPlayerScripts/CinematicGrade.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | filmic values |
| [README.md](README.md) | | doc | Houses section |

Maps saved in Studio from MapForge (the Lists' warfields) keep their old houses until rebuilt; every procedural map gets the new ones.

---

## Before that: review fixes (traps, wakers, secrets, late joiners)

A pass over last night's new systems, fixing what a review turned up:

- **Traps** stream to a screen whole, so a blade or a spike grate is never half there on a phone with streaming. They no longer kill a Deadvault raid's calm patrols; a monster on the hunt still blunders into them.
- **Not every dead rests**: a woken sarcophagus can't be searched until its dead is down.
- **Secret walls**: a room's furnishing (pillars, skirting, sconces, damp, cavern rocks, its quiet-wall props) keeps clear of the stretch a secret is walled up behind, as it does of a doorway.
- **The Undead invasion**: its lord comes in with the full boss entrance.
- **War**: a champion's name comes up low on the screen and nothing else is touched (no bars, no hidden HUD, no camera). A player who joins after the sky has turned sees the storm, not the morning's weather.
- **Footsteps**: the puddle list is built once per map and kept up as the map streams in, not rebuilt every 10 seconds.
- **What's new**: pressing Enter to send a chat message no longer closes the card.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Traps.lua](ServerScriptService/Game/Traps.lua) | ServerScriptService ▸ Game | ModuleScript | Atomic streaming; calm monsters spared |
| [Traps.client.lua](StarterPlayerScripts/Traps.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | waits for each trap's key part |
| [Containers.lua](ServerScriptService/Game/Containers.lua) | ServerScriptService ▸ Game | ModuleScript | woken coffin locked |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the waker guards its coffin |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | `opening(r, d)`: secret walls count as doorways |
| [Invasion.lua](ServerScriptService/Game/Modes/Invasion.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | lord intro |
| [BossIntro.lua](ReplicatedStorage/BossIntro.lua) | ReplicatedStorage | ModuleScript | name-only entrance |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | WarSky for late joiners |
| [Footsteps.lua](ReplicatedStorage/Footsteps.lua) | ReplicatedStorage | ModuleScript | wet list per map |
| [WhatsNew.client.lua](StarterPlayerScripts/WhatsNew.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | Enter respects chat |
| [README.md](README.md) | | doc | |

---

## Before that: the fountain trickles; each floor its own mood

- **The Depths**: a fountain room's water trickles into its basin, louder as you come to it.
- **Fixed**: going down to a floor of the same theme kept the last floor's mood running. Its lying dead and its sounds stayed at the old floor's positions. Each new floor now starts its mood fresh.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | fountains, per-floor restart |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Fountain (a Sound; save the place).

---

## Before that: petals from the stands

- **The arenas** (the Colosseum, the forge arenas, the Sandpit, the Bloodpit): when a round is won, the stands throw petals down onto the sand for a few seconds as they roar.

| File | Studio location | Type | Change |
|---|---|---|---|
| [ArenaCrowd.client.lua](StarterPlayerScripts/ArenaCrowd.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | petals |
| [README.md](README.md) | | doc | |

---

## Before that: eyes in the dark

- **The dungeons**: now and then a pair of eyes watches you out of the dark far ahead. They glow in the theme's colour, blink once, and are gone when you come closer.
- **What's new**: a seventh line, "Hear it, feel it" (armour, splashes, echoes, crates).

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | eyes |
| [README.md](README.md) | | doc | |

---

## Before that: every place has its echo

- **Dungeons**: every sound (blades, footsteps, groans, the bell) rings off the stone, in each theme's own acoustic: the crypt's stone corridors, the warrens' and the ice's caves, the manor's halls, the forge's iron halls, the drowned halls' wet tunnels, the abbey's great nave.
- **The Gilded Rat** has a warm room's echo; **the arenas** an arena's. Elsewhere, none, as before.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | reverb by theme |
| [TavernAmbience.client.lua](StarterPlayerScripts/TavernAmbience.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | a room's |
| [ArenaCrowd.client.lua](StarterPlayerScripts/ArenaCrowd.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | an arena's |
| [README.md](README.md) | | doc | |

---

## Before that: out into the day

- **Deadvault**: getting out floods your screen with warm daylight as the dread's drone falls away, then it eases back under the YOU GOT OUT card.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the daylight |
| [README.md](README.md) | | doc | |

---

## Before that: crates and barrels break

- **Every map's crates and barrels** (war camps, the Courtyard, the dungeons' storerooms): strike one with a blade and it bursts. Planks or staves fly, wood crunches, dust puffs, and anything stacked on it comes down too. It's back 90 seconds later. Deadvault's searchable containers are untouched.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Breakables.lua](ServerScriptService/Game/Breakables.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game | Script | starts it |
| [README.md](README.md) | | doc | |

---

## Before that: a cinematic grade over the open air

- **Every open-air map**: a gentle film look. A touch more contrast and colour, the light a shade warm, and the sun's rays visible through the haze by day. It's off in the dungeons (they have their own grade) and the Gilded Rat.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CinematicGrade.client.lua](StarterPlayerScripts/CinematicGrade.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [README.md](README.md) | | doc | |

---

## Before that: armour you can hear

- **Everyone in armour**: mail jingles and plate clanks with each step, a little under the footstep. Your own steps always; others' only close by (28 studs), so a battle doesn't drown in it.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Footsteps.lua](ReplicatedStorage/Footsteps.lua) | ReplicatedStorage | ModuleScript | armour steps |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ ArmorMail, ArmorPlate (Sounds; save the place).

---

## Before that: splashing through water

- **Everywhere there's standing water** (the Drowned Halls, Mistmarsh's pools, every dungeon puddle): a step into it splashes, and a ripple spreads on the water. This applies to everyone's steps, yours too.
- The Hollow Abbey's bell and chant sounds are now in place.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Footsteps.lua](ReplicatedStorage/Footsteps.lua) | ReplicatedStorage | ModuleScript | water steps |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Splash, AbbeyBell, Chant (Sounds; save the place).

---

## Before that: the abbey's bell and chant

- **The Hollow Abbey**: now and then a bell tolls far off through the stone, or a faint wordless chant drifts from another room.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the abbey's sounds |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ AbbeyBell, Chant (Sounds; save the place).

---

## Before that: a seventh dungeon, the Hollow Abbey

- **The Depths and Deadvault** have a new theme in the vote: **the Hollow Abbey**. A desecrated monastery in violet candlelight, with chapels, libraries and crypts.
- **Its dead** (new Bestiary lines): Hollow Monks, Penitents, Abbey Guards and Cultists. Its champions are the Wraith and the Gargoyle.
- **Its lord**: Malachai, the Black Abbot, a crowned shadow with violet eyes. He has six moves, a second phase (THE ABBEY RINGS ITS BELLS), and tolling bells.
- It joins every per-theme system (waves, wakers, the lying dead, traps, the mood, raid rooms), and the What's new card names both new dungeons.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeons.lua](ReplicatedStorage/Catalog/Dungeons.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | the theme |
| [Bestiary.lua](ReplicatedStorage/Catalog/Bestiary.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | the abbey's dead |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | both modes' maps, the title |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | raid rooms, odd containers |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | its wave line |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | its wakers |
| [Traps.lua](ServerScriptService/Game/Traps.lua) | ServerScriptService ▸ Game | ModuleScript | its traps |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | grade, ghosts, glow, the dead lie |
| [WhatsNew.client.lua](StarterPlayerScripts/WhatsNew.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | both dungeons |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ MapShots ▸ HollowAbbey (the vote picture; save the place).

---

## Before that: blows knock off what monsters are made of

- **Every monster** (the game stays Mild: no blood): a clean hit sheds what the thing is made of instead of the plain white-gold flash. Bone chips off skeletons, grave dust off ghouls, ice off frost things, embers off fire creatures, stone off golems, a wisp off wraiths. Players and human foes keep the flash.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Injury.lua](ServerScriptService/Combat/Injury.lua) | ServerScriptService ▸ Combat | ModuleScript | `hitFlash` by kind |
| [README.md](README.md) | | doc | |

---

## Before that: something walks overhead

- **The dungeons**: now and then, while nothing's coming for you, something heavy walks across the floor above you. Five slow deep thuds pass over, grit sifts down from the ceiling and your lantern trembles with each.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | overhead |
| [README.md](README.md) | | doc | |

---

## Before that: a boss falls

- **Every boss** (the Depths' lords, Deadvault's lair boss, War's and Siege's champions, the Horde's Warlord): when one dies near you, a deep boom and the ground shaking, a pillar of light where it stood, a ring of force rolling out, dust, and the world washing white for a moment.
- **Cindermaw** (Dragonfall) falls the same way, three times the size. The effect now lives in `BossIntro.falls`, shared.

| File | Studio location | Type | Change |
|---|---|---|---|
| [BossIntro.lua](ReplicatedStorage/BossIntro.lua) | ReplicatedStorage | ModuleScript | `falls` |
| [BossEntrance.client.lua](StarterPlayerScripts/BossEntrance.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | calls it for every boss |
| [Dragon.client.lua](StarterPlayerScripts/Dragon.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | calls it for the dragon |
| [README.md](README.md) | | doc | |

---

## Before that: the champion's name over his head; the card puts itself away

- **War**: the champion carries his name over his head in his side's colour, seen from up to 400 studs, on top of his boss health bar.
- **Fixed**: the What's new card stayed over the match if you left the Courtyard before closing it. It now goes away by itself and comes back next time, still unread.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the champion's mark |
| [WhatsNew.client.lua](StarterPlayerScripts/WhatsNew.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | away on leaving |
| [README.md](README.md) | | doc | |

---

## Before that: a tenth War battlefield, Mistmarsh

- **War**: Mistmarsh, a fog-bound marsh at dawn. A broken stone causeway runs down the middle, with standing water and reed beds, a chapel half sunk into the bog with its tower leaning, and mossy stones. The banners: the South Causeway, the Reeds, the Sunken Chapel, the Bog, the North Causeway. It has a vote picture.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarMap.lua](ServerScriptService/Game/WarMap.lua) | ServerScriptService ▸ Game | ModuleScript | the theme, its paint and features |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | War's maps, title, fighters |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the banner names |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ MapShots ▸ Mistmarsh (the vote picture; save the place).

---

## Before that: lighter on a phone

- **Footprints**: on a phone, at most 100 on the ground (220 elsewhere) and no puffs when running.
- **The dead lie**: at most 8 lying copies at once on a phone (24 elsewhere); the rest just sleep standing.
- A three-minute soak of the Depths with everything from today (waves, ambush checks, snuffed torches, traps, secrets, the lying dead, the score) ran with no errors at about 59 fps.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Footsteps.client.lua](StarterPlayerScripts/Footsteps.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | phone caps |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | phone caps |

---

## Before that: a "What's new" card

- **The Courtyard**: once per update, a WHAT'S NEW card shows what's new (the Drowned Halls; the dead that don't stay down; traps and secrets; the living dark; War's champions; the turning sky). It shows only for players past the welcome and the menu tour, and is remembered with their settings so it never repeats.
- To announce the next update, change `NEWS` at the top of the script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WhatsNew.client.lua](StarterPlayerScripts/WhatsNew.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage | ModuleScript | `SeenNews` |
| [README.md](README.md) | | doc | |

---

## Before that: the crowd shouts for a fine parry

- **Arenas** (the Colosseum, the forge arenas, the Sandpit): a parry or a chamber in the arena brings a third of the stands up with a shout.
- **The warfields** (the Lists): a parry or a chamber in the ring brings a shout from the parrier's army. At most once every 3.5 s.

| File | Studio location | Type | Change |
|---|---|---|---|
| [ArenaCrowd.client.lua](StarterPlayerScripts/ArenaCrowd.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | parries |
| [Warfield.client.lua](StarterPlayerScripts/Warfield.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | parries |
| [README.md](README.md) | | doc | |

---

## Before that: the dark falls as the gates slam

- **The Depths**: one fight in five, as the gates slam, a cold gust puts out the room's torches. The fight starts by lantern light alone, and the torches sputter back one by one a few seconds later.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the cue (AdventureEvent "Snuff") |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the torches out and back |
| [README.md](README.md) | | doc | |

---

## Before that: ambushes in the Depths' corridors

- **The Depths**: the corridors aren't safe. Walking one, now and then (twice a floor at most) the floor cracks open at both ends and the dead climb out on either side of you: AMBUSH! with 2 to 4 of the floor's commons, more with a party.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `ambushCheck`, `ambush`, `clearAmbushers` |
| [README.md](README.md) | | doc | |

---

## Before that: Sir Aldric takes the field; a sweep of the modes

- **War**: the Crown's champion, Sir Aldric the Unbroken, is the Training Yard's own master of steel (a comment and the README say so).
- Soaked with today's changes, no errors in any: Depths (2½ min), Deadvault, War (Redfield, Frostmere, Kingsbridge, Nightfall), Siege, Horde, Invasion, Plague, Dragonfall, Crownfall, TDM, KOTH, Kingslayer, the Tiltyard, the Courtyard, the Prologue, the Gilded Rat.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | a comment |
| [README.md](README.md) | | doc | |

---

## Before that: more in the dark of Deadvault

- **Deadvault**: fewer empty rooms (28% of fight rooms now, was 42%), more holding two, now and then a pack of three; more pairs on patrol (four, plus one for every two raiders). A raid holds about 44 monsters; server and client both hold about 60 fps in Studio.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | population |
| [README.md](README.md) | | doc | |

---

## Before that: the line is breaking

- **War**: the first time a side's tickets fall under 60, a horn sounds, the war drums quicken, and every screen calls it: IRON IS BREAKING with ONE LAST PUSH! for the side winning, HOLD THE LINE! for the side breaking.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the call |
| [README.md](README.md) | | doc | |

---

## Before that: footsteps behind you

- **The dungeons** (and Plague Night): now and then, while nothing's coming for you, slow footsteps sound somewhere behind you, a little closer each, then they stop.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the steps |
| [README.md](README.md) | | doc | |

---

## Before that: a champion takes the field in War

- **War**: five to seven minutes in, the side that's behind sends its champion (Sir Aldric the Unbroken / Grimwald Ironhand): heavy plate, a great blade, a head taller, a boss's health. His name comes up on every screen without taking the camera. Cut him down and his side loses 25 tickets (THE CHAMPION FALLS).

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `War:champion` |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the fall's call |
| [BossEntrance.client.lua](StarterPlayerScripts/BossEntrance.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | War's champions: name only |
| [README.md](README.md) | | doc | |

---

## Before that: secret rooms in the dungeons

- **The Depths and Deadvault**: some rooms hide a walled-up cache behind a cracked stretch of wall with a draft of dust seeping through. Three blows bring it down in a crash of stone and dust. Behind it is a short passage to the cache: gold, bones, candles, and a gilded chest (the Depths, one card each) or an ornate container (Deadvault). One a floor in the Depths (sometimes two deeper down), three a raid.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Secrets.lua](ServerScriptService/Game/Secrets.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | builds them (`opts.secrets`) |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat | ModuleScript | `worldHitHooks` |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | a floor's secrets, the chest |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | a raid's secrets, the container |
| [README.md](README.md) | | doc | |

---

## Before that: the weather turns in a War battle

- **War**: on a clear or rainy field, 4 in 10 battles see the sky open partway through. Clear turns to rain, rain to a storm, with a long roll of thunder, a flash, the rain thickening in, and THE HEAVENS OPEN / THE STORM BREAKS on screen.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | decides it (Round ▸ WarSky) |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | draws it |
| [README.md](README.md) | | doc | |

---

## Before that: a sixth dungeon, the Drowned Halls

- **The Depths and Deadvault** have a new theme in the vote: **the Drowned Halls**. Flooded catacombs with wet stone, rust-green iron and pale teal flames, standing water and puddles everywhere, and water dripping all the time.
- **Its dead** (new Bestiary lines): the Drowned, Drowned Bones, Deep Guards, Drowned Archers, Tide Callers, the Drowned Knight and the Brine Hulk.
- **Its lord**: Thalassar, the Drowned King, with a glaive, six moves, a second phase (THE DEEP RISES), and a weeping roof.
- It slots into everything per theme: second waves (THE DEEP GIVES UP ITS DEAD), sarcophagi that wake, the dead that lie, traps, the mood's grade and ghosts, raid rooms.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dungeons.lua](ReplicatedStorage/Catalog/Dungeons.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | the theme, `wet` |
| [Bestiary.lua](ReplicatedStorage/Catalog/Bestiary.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | the drowned |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | in both modes' maps, its title |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | raid rooms, odd containers, the water |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | its wave line |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | its wakers |
| [Traps.lua](ServerScriptService/Game/Traps.lua) | ServerScriptService ▸ Game | ModuleScript | its traps |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | grade, ghosts, glow, the dead lie, drips |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ MapShots ▸ DrownedHalls (the vote picture; save the place).

---

## Before that: the Gilded Rat sounds lived in; the dungeon dread only in dungeons

- **The Tavern (the Gilded Rat)**: a murmur of patrons over the hall, the hearth crackling where it stands, and a lute-and-fiddle tune by the hearth.
- **Fixed**: the Tavern played battle music. It now gets its own tune (or the Courtyard's).
- **Fixed**: the dungeons' dread (drone, cold grade, dark edge, lanterns, whispers, apparitions, bats, rats) ran on every procedural map: War's battlefields, Dragonfall's caldera, Crownfall's island, the Prologue and the Tavern. Every built-fresh map is flagged Generated, not only dungeon floors. It now runs only in The Depths and Deadvault (and, as before, Plague Night and the Undead invasion).

| File | Studio location | Type | Change |
|---|---|---|---|
| [TavernAmbience.client.lua](StarterPlayerScripts/TavernAmbience.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [Music.client.lua](StarterPlayerScripts/Music.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the Tavern mood |
| [MusicConfig.lua](ReplicatedStorage/MusicConfig.lua) | ReplicatedStorage | ModuleScript | `Tavern` |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | not in the Tavern |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Tavern (the tune), TavernRoom (the murmur) (Sounds; save the place).

---

## Before that: the sun moves over a War battle, a siege, a horde's defence

- **War**: the day goes on while you fight. A morning field brightens; an afternoon one wears on towards golden hour, with long shadows and a warm sky by the bell. Dusk and night themes keep their tuned light.
- **Siege**: the same over the assault, gentler (afternoon towards evening, the fires showing brighter).
- **Horde**: the sun goes down on the defence wave by wave (dusk by the tenth wave).
- Soaked Invasion (Undead Night) with today's changes: no errors.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.lua](ServerScriptService/Game/Modes/War.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the sun's drift |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the sun's drift |
| [Horde.lua](ServerScriptService/Game/Modes/Horde.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the sun, wave by wave |
| [README.md](README.md) | | doc | |

---

## Before that: the class picker's mode line

- **Fixed**: on CHOOSE YOUR CLASS, the mode's line ("Crownfall on The Crownlands" and its description) spilled up over the title. It now reads from the top down under it, two lines at most, and the class cards sit a little lower.
- Soaked Dragonfall and Crownfall with today's changes: no errors (60 / 55 fps in Studio).

| File | Studio location | Type | Change |
|---|---|---|---|
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | mode line layout |

---

## Before that: Deadvault comes down; the boss cinematic only for entrances

- **Deadvault's last minute**: deep rumbles closer and closer together, the ground shaking harder, grit pouring from the ceiling and stones dropping round you, your lantern stuttering.
- **Fixed**: every red ("boss") banner played the boss cinematic. Deadvault's IT IS COLLAPSING and YOU FELL, Crownfall's ring closing and Dragonfall's warnings all took the camera for 3 s. Now only a boss's entrance does it (the Depths' lord, the dragon: `intro = true` on the banner).

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the collapse |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | intro only on `intro` |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the boss banner's `intro` |
| [Dragonfall.lua](ServerScriptService/Game/Modes/Dragonfall.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the dragon's banner's `intro` |
| [README.md](README.md) | | doc | |

---

## Before that: the dead lie among the bones

- **The Depths, Deadvault**: a sleeping skeleton or ghoul now lies on its back among the bones like the dead it is (no "z z" over it). The moment it notices anything it gets up, tipping up off the floor in a puff of grave-dust with a groan. Sneak attacks still land where it lies.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the dead lie, and rise |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | no sign over one lying |
| [README.md](README.md) | | doc | |

---

## Before that: footprints in the snow, sand and mud

- **Everywhere**: every body near you (yours too) leaves prints in snow, sand, mud and bare earth, fading over a while (snow keeps them longest); running kicks up a little puff of snow, sand or dust. A trampled road in the snow fills with them.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Footsteps.client.lua](StarterPlayerScripts/Footsteps.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | prints, puffs |
| [README.md](README.md) | | doc | |

---

## Before that: rats and drips in the dark

- **Every dungeon floor** (and Plague Night): now and then a few rats squeak and scurry across the floor ahead of you, wall to wall, through your light; water drips somewhere close (not in the Ember Forge).

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | rats, drips |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Squeak, Drip (Sounds; save the place).

---

## Before that: the dungeons' score follows the fight

- **The Depths and Deadvault**: no battle music while you creep through the dark. The dungeon's dread plays low (a new Studio-only WarAudio ▸ Dread track), and the battle score swells in only when a fight is on: a room's gates shut, a blow struck or taken, or something near has seen you. It eases back out after.
- Fixed: Deadvault played the boss theme the whole raid (its lord is alive from the start). A dungeon boss's score now plays only near its lair.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Music.client.lua](StarterPlayerScripts/Music.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | dread / battle, boss nearby |
| [MusicConfig.lua](ReplicatedStorage/MusicConfig.lua) | ReplicatedStorage | ModuleScript | the Dread mood |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ WarAudio ▸ Dread (a Sound; save the place).

---

## Before that: not every dead rests

- **Deadvault**: the first search of a sarcophagus sometimes (30%) throws the lid off towards you and its dead climbs out of the far side, already coming for you (IT WAKES). Search it once it's dealt with.
- A sliding sarcophagus lid now takes the effigy carved on it along (it was left floating).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Containers.lua](ServerScriptService/Game/Containers.lua) | ServerScriptService ▸ Game | ModuleScript | the thrown lid, the effigy |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | `waken` |
| [README.md](README.md) | | doc | |

---

## Before that: traps in the dungeons' corridors

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
