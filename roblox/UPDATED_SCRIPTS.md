# Updated scripts: new finishers, more pets, everyone sees kill effects

- **Executions are gone** (the R finisher, its menu tab, clips and catalog), and half-sword was dropped. Armor-vs-damage-type from the same change stays.
- **Everyone sees everyone's kill effect.**
  - With streaming on, a client that hadn't streamed the dead body in got nothing, and the effect was lost.
  - The server now sends the body's id, where the effect stands and the body's colours. Without the body, the effect plays there in its colours.
- **Effects now move the body instead of fading it.** Each client hides the real body and moves a local copy of it. The server's ragdoll is never touched.
  - Dragged under by the kraken or a shadow rift
  - Sunk into quicksand or a grave
  - Carried off in the serpent's jaws
  - Sucked piece by piece into the black hole
  - Squashed flat by the anvil or the hand
  - Lifted into the light by Ascension
- **The Grim Crate** (permanent, 80 Crowns) holds 11 new kill effects, each with Pro Sound Effects sounds and its own remains:

  | Rarity | Kill effects |
  |---|---|
  | Common | Poof, Tombstone |
  | Rare | Anvil Drop, Petrify, Quicksand |
  | Epic | Kraken's Grasp, Overgrown, Meteor |
  | Legendary | Serpent's Maw (it spits out the bones), Hand of the Heavens, Black Hole |

- **New remains:** a headstone, a squashed body, a stone statue, a sand mound, a puddle, a flowering mound, a crater, a bone pile. Remains that don't need the body keep their timing even when a player respawns first.
- **16 new companions** with three new bodies (snake, tortoise, crab) and new looks (hedgehog spines, unicorn horn, cobra hood, a tree on a tortoise's shell):
  - Common: Duckling, Tortoise, Shore Crab, Grass Snake, Hedgehog
  - Rare: Corgi, Adder, Snapping Turtle, Red Panda
  - Epic: Royal Cobra, Ember Toad, Coral Crab
  - Legendary: Jade Serpent, Grove Tortoise, Unicorn Foal, and the Basilisk (Royal Egg only)

| File | Studio location | Type | Change |
|---|---|---|---|
| [KillFX.lua](ReplicatedStorage/KillFX.lua) | ReplicatedStorage ▸ KillFX | ModuleScript | 11 new effects, the body puppet, colours fallback |
| [Catalog/KillFX.lua](ReplicatedStorage/Catalog/KillFX.lua) | ReplicatedStorage ▸ Catalog ▸ KillFX | ModuleScript | the Grim Crate's effects |
| [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | ReplicatedStorage ▸ Catalog ▸ Crates | ModuleScript | Grim Crate |
| [Catalog/Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua) | ReplicatedStorage ▸ Catalog ▸ Calendar | ModuleScript | Grim always in rotation |
| [Catalog/Companions.lua](ReplicatedStorage/Catalog/Companions.lua) | ReplicatedStorage ▸ Catalog ▸ Companions | ModuleScript | 16 companions |
| [Companions.lua](ReplicatedStorage/Companions.lua) | ReplicatedStorage ▸ Companions | ModuleScript | snake, turtle, crab bodies; spines, horn, hood, grove |
| [Corpses.lua](ServerScriptService/Combat/Corpses.lua) | ServerScriptService ▸ Combat ▸ Corpses | ModuleScript | new remains; on-time remains after a respawn |
| [Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua) | ServerScriptService ▸ Hub ▸ Cosmetics | Script | kill effect sent by id, spot and colours |
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Cosmetics | LocalScript | finds the body by id, plays without it |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | executions removed (armor vs damage type kept) |
| Catalog/init, Catalog/Crates, ClientSettings, RigPose, CombatClient, Profile, Economy, HubServer, AdminServer, AdminPanel, HubMenu, RigReplicator, CameraRig, Scoreboard | (as before) | | back to before executions |
| Catalog/Executions, ExecuteRule, Executions.client, Build/ExecutionAnims | | | **deleted** |

In Studio: `ReplicatedStorage ▸ ExecutionAnims` and `ServerStorage ▸ ExecutionAnims` were deleted too. **Save the place.**

---

## Before that: armor vs damage type

- Cuts glance off plate (Heavy ×1.35 protection, with sparks), blunt weapons go through it (Heavy ×0.55), stabs pierce (×0.85–0.9), axes and polearms chop. `CombatServer.ARMOR_VS`; a weapon can set `DAMAGE_TYPE`.

---

## Before that: holstered weapons

- **The weapons you carry are worn on you**, so everyone sees your kit:
  - two-handed swords across the back, hilt over the right shoulder
  - polearms head-up behind the left shoulder
  - one-handers at the left hip, hilt forward
  - a dagger at the right hip
- Each one is a look-only copy, skin included, with no scripts or hitbox.
- Drawing a weapon takes it off the body with a sword-draw sound; putting it away hangs it back on, with a softer sheathe.
- Positions: `SPOTS` in the script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Holsters.server.lua](ServerScriptService/Loadout/Holsters.server.lua) | ServerScriptService ▸ Loadout ▸ Holsters | Script | **new** |

---

## Before that: smaller themed crates, egg previews, "what's coming" timers

- **Crates are small and themed again.**
  - The permanent crates were finish × every-weapon grids: Hafted had 65 items with 12 legendaries, Bladesmith 46, Royal 24 with 14 legendaries.
  - Each now carries its finishes on a picked few weapons (`CRATE_PICKS` in `scripts/gen_content.py`):

    | Crate | Items | Commons | Rares | Epics | Legendaries |
    |---|---|---|---|---|---|
    | Bladesmith | 18 | 6 | 8 | 3 | 1 |
    | Hafted | 18 | 6 | 6 | 4 | 2 |
    | Royal | 12 | — | 4 | 3 | 5 |

  - The same finishes on other weapons moved to the daily WEAPONS shelf (priced by rarity), so nothing is lost. Skin ids are unchanged, so owned skins stay owned.
  - Every crate is now 11–18 items.
- **Eggs: WHAT'S INSIDE.** Each shelf egg opens a preview of everyone it can hatch: each companion's own chance, whether you have it, and the finish odds.
- **What's coming:** the crates list says "NEW CRATE IN 2d 21h · ROYAL ARMOURY", and the egg shelf "NEW EGG IN … · GRAVE EGG". These count down to the next weekly drop that brings one (`Drops.nextWith`). "Leaves in" timers were already there.

| File | Studio location | Type | Change |
|---|---|---|---|
| [scripts/gen_content.py](../scripts/gen_content.py) | — | Python | `CRATE_PICKS`, `SHELF_PRICE` |
| [Skins.lua](ReplicatedStorage/Catalog/Skins.lua) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | regenerated |
| [Drops.lua](ReplicatedStorage/Drops.lua) | ReplicatedStorage ▸ Drops | ModuleScript | `nextWith` |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | egg WHAT'S INSIDE, next crate / egg lines |

---

## Before that: music, menu sounds, crate and egg openings

- **Music** (`StarterPlayerScripts ▸ Music`, tracks in `ReplicatedStorage ▸ MusicConfig`, all APM licensed):
  - calm courtly pieces in the Courtyard
  - a low underscore between rounds
  - battle cues in matches
  - frantic strings and drums when a horde wave comes, tense underscore in the breaks
  - a dark chant while a boss lives
  - a win or lose sting when a round ends
  - Moods crossfade, and each list shuffles. A track that won't load is skipped.
- **Menu sounds** (`ReplicatedStorage ▸ UIFX`, every id in one table):
  - every button clicks when pressed and ticks softly on hover (`UIClicks`); close / back has its own sound
- **Crate opening:** a snare roll under the spin and a tick per card that passes (rising as it slows). Then a beat of suspense, a flash in the rarity's colour, a banner ("LEGENDARY!") and a stinger that grows with the rarity.
  - Legendary / Mythic get a first low flash, a bigger banner and a screen shake.
  - A finish shows its own banner, and duplicates add coins.
- **Egg hatching:**
  - Menu: the egg on a dark stage rocks, cracks three times (harder each time, cracks spreading over it), bursts in a white flash, then the rarity reveal.
  - Courtyard Hatchery: the same three cracks, then shell bits fly, the rarity's light flashes and its sting plays.
- **Settings:** new "Music volume" and "Menu sounds" sliders.

| File | Studio location | Type | Change |
|---|---|---|---|
| [UIFX.lua](ReplicatedStorage/UIFX.lua) | ReplicatedStorage ▸ UIFX | ModuleScript | **new**: menu sounds, flash, banner, shake, ticker |
| [MusicConfig.lua](ReplicatedStorage/MusicConfig.lua) | ReplicatedStorage ▸ MusicConfig | ModuleScript | **new**: tracks by mood |
| [Music.client.lua](StarterPlayerScripts/Music.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Music | LocalScript | **new**: the score |
| [UIClicks.client.lua](StarterPlayerScripts/UIClicks.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ UIClicks | LocalScript | **new**: button sounds |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | crate spin sounds + reveal, hatch sequence |
| [Pastimes.client.lua](StarterPlayerScripts/Pastimes.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Pastimes | LocalScript | Courtyard hatch: cracks, burst, sting |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | Music / Menu sounds sliders |

---

## Before that: reeling after a clean hit

- **Reeling:** after a clean hit the victim can't attack or kick for 0.5 s (`HIT_STUN`), the same for every weapon.
  - They can still block and parry.
  - Example: you land a Zweihander stab, and they can't counter-swing while your sword is still coming back round. Your guard is up before their swing can reach you.
  - Bosses ignore it.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | `HIT_STUN`, `ReelUntil` gate on attacks and kicks |
| [README.md](README.md) | — | docs | reeling |

---

## Before that: back to the original animations; real sword clangs

- **Your original animations and combat code are back:**
  - The combat client and server, RigPose, CameraRig, NpcAnimator and Bots are restored from the backup (`combat-backup-2026-10-07`).
  - The new animations, arm aiming, hip counter-turn and the AnimSets / BladeSamples modules are gone. (`Build ▸ AnimForge` stays as an unused tool; the Studio folder `ReplicatedStorage ▸ Animations` is no longer read and can be deleted.)
- **Kept, because you asked for them:**
  - First hit wins: a clean hit interrupts the windup or the strike, but not the recovery.
  - Bosses don't flinch.
  - The zero-stamina error fix.
  - The KOTH / Siege rings and the training-ring fix.
- **Better clangs:** parries, blocks and chambers now use real sword-on-sword recordings (two sabres clashing, sword impacts) from the licensed library, instead of crowbar, railroad-hammer and skillet recordings.
  - Parry: bright and sharp.
  - Block: lower and heavier.
  - Chamber: a clash with the blades scraping along.
- **Two-handed swords swing like big blades:** Longsword, Greatsword, Zweihander, Estoc and Executioner use the sword swish (the rapier's family), deeper and fuller, instead of the generic heavy whoosh. Axes, mauls and polearms keep the whoosh.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua), [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua), [RigPose.lua](ReplicatedStorage/RigPose.lua), [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua), [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua), [Bots.lua](ServerScriptService/Combat/Bots.lua) | Combat / StarterCharacterScripts / StarterPlayerScripts | Module / LocalScript | restored; first-hit / boss rules re-applied |
| AnimSets.lua, BladeSamples.lua | ReplicatedStorage ▸ Combat | ModuleScript | **removed** |
| [SoundBank.lua](ReplicatedStorage/SoundBank.lua) | ReplicatedStorage ▸ SoundBank | ModuleScript | sword clangs; `SwingGreat` for two-handed swords |
| [README.md](README.md) | — | docs | animation sections removed |

---

## Before that (partly undone above)

**Arms stay on, swings across, smooth finish (newest; all 66 clips rebuilt):**
- **Arms never detach:**
  - They turn with your view about their own shoulders, not your eyes.
  - Their reach is held to a few hundredths of a stud. Measured in play: at most 0.07 from the socket.
  - Two-handers nudge both hands (up to 0.45 studs) so the left hand stays on the grip without stretching an arm.
- **Arms follow the camera** up and down. There's no exact crosshair convergence any more; it's close and natural.
- **Horizontal swings** run at shoulder height, arms straight across the body, perfectly level.
- **No drop at the end of a swing:** the follow-through stays nearly level and plays at its natural pace, then settles exactly into the idle pose.

**Attacks go where you aim (newest; all 66 clips rebuilt at 40 fps):**
- **Swings are level:** the blade cuts a flat plane at crosshair height, with the hands at 1.15.
- **Thrusts drive at the crosshair**, and **overheads chop straight down the middle**.
- **Aiming:**
  - With a forged weapon out, the arms and weapon turn with your view about your eyes (`RigPose.aimArms`), in pitch and yaw.
  - The target point is on the crosshair ray, 7 studs past you (`AIM_DIST`): in first person that's simply your look, and in third person (camera over the shoulder) it brings the attack onto the crosshair.
  - Relayed to other players (new `aim` / `aimP` / `aimY` inputs). Bots aim at their target's chest.
- **Measured in play (third person):** right swing 0.4°, stab 0.7°, left swing 2.6°, overhead 3.3° from the crosshair.

**Animation pass 3 (newest; all 66 clips rebuilt):**
- **Overhead:** the hands go up above the head (y 2.1), in front of it, never through it; the blade lies back over the top and chops down.
- **Stab:** the whole body coils to the right with the head on the target, then unwinds as the arms drive the point out.
  - The hips and legs now follow 30% of every torso turn (`AnimSets.HIP_FOLLOW`); feet stay planted.
  - Measured in play: swing torso −49°…+38°, legs ±15°, head ±7°.
- **Block:** a diagonal guard across the body, hands low to the right and the tip up to the left. It covers you without filling your own view.
- **No spin when going back to idle:** every attack starts and ends exactly on the idle pose.
- **Smoother:**
  - All hand motion interpolates through one continuous path. Thrusts used to jump between two hand rules.
  - The fades into, between and out of attacks are longer again: 0.08–0.24 s in, about 0.12 s or more out.

**Objective indicators and Training (newest):**
- **KOTH, Siege ram and capture zones:** a glowing ring on the ground that you can see from inside it.
  - The rim is the holder's colour and flashes when contested.
  - Segments show who's holding it, split by team; a capture fills as it's taken.
  - Dashes spin faster while it's moving or being taken.
  - A light pillar marks it from across the map (hidden while you're in it). The ring rolls with the ram.
  - The KOTH capture area is now the hill's real disc (it was a square box), and the marker reads TAKE / HOLD THE HILL or CONTESTED.
- **Training ring:** a bot you beat now ragdolls with its kill effect, instead of freezing (it was cleared away the moment it died).

| File | Studio location | Type | Change |
|---|---|---|---|
| [AnimForge.lua](ServerScriptService/Build/AnimForge.lua), [AnimSets.lua](ReplicatedStorage/Combat/AnimSets.lua), [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua), [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | Build / Combat | ModuleScript | animation pass 3 (above) |
| [RigPose.lua](ReplicatedStorage/RigPose.lua), [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua), [Bots.lua](ServerScriptService/Combat/Bots.lua) | ReplicatedStorage / StarterCharacterScripts / Combat | Module / LocalScript | attacks aim at the crosshair |
| [ObjectiveFX.client.lua](StarterPlayerScripts/ObjectiveFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ ObjectiveFX | LocalScript | **new**: the ground rings |
| [KOTH.lua](ServerScriptService/Game/Modes/KOTH.lua) | ServerScriptService ▸ Game ▸ Modes ▸ KOTH | ModuleScript | disc capture, publishes the hill's state |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Siege | ModuleScript | publishes the objective's radius; capture box hidden |
| [Objectives.client.lua](StarterPlayerScripts/Objectives.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Objectives | LocalScript | KOTH marker |
| [Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game ▸ Training | ModuleScript | fallen ring bots die normally |
| [README.md](README.md) | — | docs | objective indicators |

---

## Before that: forged combat animations, first hit wins, sharper hit sampling

**Follow-up fixes (all 66 clips rebuilt and re-uploaded):**
- **Guard:** blades held upright (swords ~75°, polearms ~62°, daggers ~55°) and the hands low, at chest or belly, instead of a sword levelled at the enemy with the arms raised.
- **Legs:** they move again with a weapon out. The idle and block no longer key the legs, so Roblox's walk cycle drives them, and the hips still counter the torso's turn.
- **No more choppy turning:**
  - The weapon's roll is carried along its path frame to frame, then turned toward the leading edge at a capped rate. Swords lead with whichever edge is nearer.
  - The arms take the smallest turn from frame to frame (no flips) and are rate-limited.
  - Measured worst case per frame: roll 18°, right arm 40°, left arm 38°. Before: up to 170°.

- **New animations for every weapon class.**
  - Six classes, each with its own clips: one-handed blades, one-handed blunt, dagger, two-handed swords, heavy two-handers, polearms.
  - Each class has an idle, a block, a hit flinch, and eight attacks. Underhands now exist for every weapon.
  - The blade travels a real arc round the body, edge first. The left hand holds two-handed grips. The head stays on the target while the torso turns. The legs stay planted.
- **Each swing is timed in three parts.**
  - The windup plays over the real windup.
  - The strike plays over the active phase: 0.3 s at speed 1, the same as before, so balance is unchanged.
  - The follow-through returns to guard over the recovery.
  - Checked in play: the live blade follows the designed arc to within a few degrees.
- **Switch back any time.**
  - Studio: set `ReplicatedStorage ▸ Animations` attribute `Style` = `"Classic"`.
  - The repo backup is branch `backup/combat-before-overhaul` (tag `combat-backup-2026-10-07`).
- **First hit wins.**
  - A clean hit interrupts the target's windup *or* strike, and their own late hit is thrown away.
  - A hit during their recovery doesn't cancel it.
  - **Bosses** (Horde / Siege warlords) don't flinch at all.
- **Hit sampling:** the sweep traces the whole blade every ~0.45 studs. On wide heads (axes, halberds, mauls) it also traces the outer faces, so a hit lands when the leading steel arrives.
- **Fixed:** an error every frame at zero stamina (`InjuryFX`).

| File | Studio location | Type | Change |
|---|---|---|---|
| [AnimForge.lua](ServerScriptService/Build/AnimForge.lua) | ServerScriptService ▸ Build ▸ AnimForge | ModuleScript | **new**: the animations as data, solver, builder, preview; upright guard, frame-to-frame continuity |
| [AnimSets.lua](ReplicatedStorage/Combat/AnimSets.lua) | ReplicatedStorage ▸ Combat ▸ AnimSets | ModuleScript | **new**: weapon → class, Forged / Classic, timing marks, hip counter |
| [BladeSamples.lua](ReplicatedStorage/Combat/BladeSamples.lua) | ReplicatedStorage ▸ Combat ▸ BladeSamples | ModuleScript | **new**: hitbox sample points |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | forged playback (windup / strike / follow-through), sampling |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | forged NPC playback, strike-span timing, hit flinch for NPCs, first hit wins, bosses don't flinch |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | hips counter the animated torso turn |
| [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ NpcAnimator | LocalScript | same for bots |
| [InjuryFX.client.lua](StarterCharacterScripts/InjuryFX.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ InjuryFX | LocalScript | zero-stamina error fixed |
| [scripts/anim_extract.py](../scripts/anim_extract.py), [scripts/upload_anims.py](../scripts/upload_anims.py), [scripts/anim_receiver.py](../scripts/anim_receiver.py), [scripts/upload_asset.py](../scripts/upload_asset.py) | — | Python | export → upload → Studio entries (ids stay out of git) |
| [README.md](README.md) | — | docs | forged animations, first hit wins, sampling |

**Save the place:** the 66 animations (`ReplicatedStorage ▸ Animations`) and the new map pictures (`ReplicatedStorage ▸ MapShots`) exist only in Studio.
