# Updated scripts: shell-shocked

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
