# Updated scripts: the bow flipped, a ready stance, no arm jolt; a warning before leaving a battle

- **The bow is in the right hand and the left draws.** With the camera over your right shoulder, the body now turns away from the view instead of across it, and the bow stands next to the crosshair.
- **A ready stance** when not drawing: the bow held low across the body, the string hand by it. It blends into the full draw.
- **No zombie arm, no jolt:**
  - Roblox's "holding a tool" arm (stuck straight out) is gone with a bow or crossbow in hand.
  - The walk animation's arm swing is gone too: the arms no longer jump up as you start walking and drop as you stop.
  - Everyone sees it the same way.
- **First person:** the bow arm stays visible, out in front; the string arm is hidden. With a crossbow, both arms are hidden.
- **Leaving a battle mid-round asks first:**
  - It says what you'd give up: the pay for finishing (win or lose), the win bonus, and your kills so far.
  - Losers still get paid for finishing a round; winners get double.

| File | Studio location | Type | Change |
|---|---|---|---|
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | bow mirrored to the right hand; `BOW_READY` stance |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | the bow stays in the right hand |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | rest pose is the ready stance |
| [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RangedFX | LocalScript | string to the left hand; Roblox arm animations off the shoulders |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | first person: the bow arm shows |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | leave-battle warning |

---

## Before that: bots on the board, bots that fight, an easier Siege, the result screen

- **Bots are on the scoreboard** (Tab, and during the intermission):
  - Each bot shows its kills and deaths, tagged BOT, sorted and team-coloured with the players.
  - A fallen bot comes back under the same name with the same score.
  - A bot's row goes when a player takes its place.
- **Bots fight the other side now:**
  - A crowd of bots used to cut its own side down and almost never kill an enemy.
  - A bot's swing now passes through bots on its own side.
  - It won't swing while a player on its side stands in the way.
- **A wrong-map bug is fixed:** a round could start on a map from the last vote that its mode doesn't use (Team Deathmatch behind Frostgate's shut gate). Now a round only loads a map its mode lists.
- **Siege is easier to attack:**
  - 5 minutes to start (was 4), and taking a stage adds 30% more time.
  - The ram is 30% faster, and creeps forward on a tie.
  - The gate takes 20% fewer blows.
  - Zones fill 25% faster, and outnumbering the defenders still fills them.
  - The final champion has 25% less health.
- **A big VICTORY / DEFEAT / DRAW screen** when a round ends, in the winning side's colour, with who won and why.

| File | Studio location | Type | Change |
|---|---|---|---|
| [BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game ▸ BotFill | ModuleScript | bot seats (ReplicatedStorage ▸ BotScores) |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ServerScriptService ▸ Scoreboard | Script | counts bots' kills and deaths |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | bot rows |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | `LastHitBySeat`; `botFriends`: bot blades pass through their own side |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | no swinging through a teammate player |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | a round only loads a map its mode lists |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Siege | ModuleScript | attacker easing, numbers win ground |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | Siege 5 min, `attack` table |
| [RoundResult.client.lua](StarterPlayerScripts/RoundResult.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RoundResult | LocalScript | **new**: the result screen |

---

## Before that: bows in first person, sounds, ranged skins with arrow effects

- **A new bow stance:**
  - The bow is held out in the left hand, and the torso turns side-on.
  - Drawing turns the torso further while the right arm pulls back along the arrow, not up.
  - In first person your own arms are hidden while a bow or crossbow is up, so only the bow, the string and the arrow show. The string is thinner.
- **Sounds:**
  - The draw creaks.
  - A new release: a low string thump plus a short whoosh, both louder the fuller the draw. The crossbow gets a click plus a whoosh.
  - Arrows hitting things sound like what they hit: stone and metal ring, wood thunks, earth thuds, flesh gets a stab.
  - **Arrows whiz by** you when someone else's shot passes within 9 studs of your head.
- **The Armory has a RANGED · ARCHER section** with the bow and the crossbow.
- **18 ranged skins** (12 bows, 6 crossbows). The Epics and Legendaries change the arrows: fire, frost, shadow, holy, storm, venom, gilded, blood. Each one gets:
  - in flight: a trail, a glowing head, particles and a light
  - where it lands: a burst
  - stuck in something: a smoulder
- **Where the skins come from:**
  - A new **Fletcher's Crate**, always in rotation.
  - Earned by kills: Venomstring, Heartseeker, Glacier.
  - The Royal crate: Stormcaller, Thunderbolt.
  - The shelf: the Gilded Longbow.
- **Fixes:**
  - A skinned arrow that stuck in something errored on the server.
  - In the Hub, the training script's "infinite yield" warning is gone.

| File | Studio location | Type | Change |
|---|---|---|---|
| [ArrowFX.lua](ReplicatedStorage/ArrowFX.lua) | ReplicatedStorage ▸ ArrowFX | ModuleScript | **new**: arrow effects by kind |
| [ArrowFlight.lua](ReplicatedStorage/ArrowFlight.lua) | ReplicatedStorage ▸ ArrowFlight | ModuleScript | arrow effects in flight, whiz-by |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | release / creak / impact sounds, effect kind on every shot, smouldering stuck arrows, thinner string |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | your own arrow wears the skin's effect |
| [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RangedFX | LocalScript | effects on everyone's arrows |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | the side-on bow stance, pulling back |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | arms hidden in first person with a bow up |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | `Skin` / `ArrowFx` on the Tool |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua), [scripts/skins_handmade.part](../scripts/skins_handmade.part), [scripts/gen_content.py](../scripts/gen_content.py) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | 18 ranged skins, the `arrow` field |
| [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | ReplicatedStorage ▸ Catalog ▸ Crates | ModuleScript | Fletcher's Crate |
| [Catalog/Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua) | ReplicatedStorage ▸ Catalog ▸ Calendar | ModuleScript | Fletcher always in rotation |
| [SkinFX.lua](ReplicatedStorage/SkinFX.lua) | ReplicatedStorage ▸ SkinFX | ModuleScript | describes the arrow effect |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | Armory RANGED section |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | quiet wait for its remote |

---

## Before that: bows toned down

- **Longbow:**
  - Slower to draw: 1.6 s to full, walking at 20%.
  - Slower arrows that drop more: 45–120 studs/s, more gravity.
  - Weaker: a full draw does 30 to the body and 60 to the head, never a one-shot.
  - A shakier aim: always wandering a little, more while pulling, and more after 0.6 s held.
  - Slower nock: 1.5 s. Fewer arrows: 16.
- **Crossbow:** 160 studs/s, 42 to the body and 84 to the head, a 5 s reload at 8% walking speed.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Tools/Bow/Config.lua](Tools/Bow/Config.lua), [Tools/Crossbow/Config.lua](Tools/Crossbow/Config.lua) | ServerStorage ▸ Weapons ▸ Bow / Crossbow ▸ Config | ModuleScript | the numbers |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | defaults, draw slowdown 20% |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | shakier while pulling |

---

## Before that: the Archer

- **A new class, the Archer:** a bow or a crossbow plus a one-handed sidearm, and nothing big. It's the lightest class: 85 health, no armor protection, a bit faster.
- **Longbow** (free, held in the left hand):
  - Hold left mouse to draw. A full draw takes 1.2 s; meanwhile you walk at 35% and can't sprint.
  - Let go to loose. Letting go too early lets the string down without a shot.
  - Holding a full draw too long shakes the aim and costs stamina.
  - After every shot the archer reaches back and nocks the next arrow (1.3 s).
  - About 2.5–3 s between shots.
- **Crossbow** (level 3):
  - Click to loose: a steady aim, a hard hit.
  - Then a 4.5 s windlass reload at 10% walking speed. About 5 s between shots.
- **Arrows are real:**
  - Gravity, and the server decides every hit.
  - Headshots ×2.4. A full-draw headshot kills a Light or Medium; a bolt to the head kills anyone.
  - Armor resists by type. A raised guard facing the arrow blocks it.
  - Arrows stick in bodies and the world. The kill feed says "shot" / "shot through the head".
- **Everyone sees it:**
  - The bow string pulled back to your hand with an arrow on it.
  - The stances: side-on draw, reaching for the quiver, crossbow shouldered, the windlass crank.
  - Arrows in flight. The reticle shakes and closes as you draw.
- Phones: hold a SWING button to draw, BLOCK lets it down.

| File | Studio location | Type | Change |
|---|---|---|---|
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | **new** |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | **new** |
| [ArrowFlight.lua](ReplicatedStorage/ArrowFlight.lua) | ReplicatedStorage ▸ ArrowFlight | ModuleScript | **new** |
| [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RangedFX | LocalScript | **new** |
| [Tools/Bow](Tools/Bow), [Tools/Crossbow](Tools/Crossbow) | ServerStorage ▸ Weapons ▸ Bow / Crossbow | Tool (Config, Server, Client) | **new** |
| [Build/Weapons.lua](ServerScriptService/Build/Weapons.lua) | ServerScriptService ▸ Build ▸ Weapons | ModuleScript | bow and crossbow bodies |
| [Catalog/Weapons.lua](ReplicatedStorage/Catalog/Weapons.lua), [scripts/gen_content.py](../scripts/gen_content.py) | ReplicatedStorage ▸ Catalog ▸ Weapons | ModuleScript | Bow, Crossbow (`ranged`) |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `Catalog.weaponFits` |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | the Archer |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | bow / crossbow stances (new inputs) |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | ranged pose inputs, aim zoom |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | slots by `weaponFits` |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | class health / prot / speed |
| [Holsters.server.lua](ServerScriptService/Loadout/Holsters.server.lua) | ServerScriptService ▸ Loadout ▸ Holsters | Script | bows on the back |
| [MovementServer.server.lua](ServerScriptService/MovementServer.server.lua) | ServerScriptService ▸ MovementServer | Script | no sprint while drawing / winding |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | weapon slots by class, bows to the Archer |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | "shot" |
| [TouchControls.client.lua](StarterPlayerScripts/TouchControls.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ TouchControls | LocalScript | held SWING |

---

## Before that: newcomer path, bot fill, touch controls, class loadouts

- **A brand-new player never sees a menu first.**
  - The Courtyard sends them straight into **Basic Training**: 7 steps (swing, stab, overhead, block, parry, kick, beat a Squire).
  - For each step they're placed right in front of its dummy, facing it.
  - The lesson dummies' blows land and flinch, but don't hurt.
  - **SKIP TRAINING** is top right.
  - Then it's straight into a battle. After that first round they come back to the Courtyard with the full menu.
  - Studio: set `GameConfig.STUDIO_NEWCOMER = true` to test the path (Studio can't load saves, so it's off by default).
- **Bots fill every Warfront match.**
  - Fill targets: FFA 8, Duel 4, TDM 12, LTS 8, KOTH 10, Siege 12. Players take bots' places as they join.
  - Bots fight players and each other, head for the hill or the ram, and use pathfinding.
  - They cost tickets, count on objectives and pay like kills for the round, but stay off the lifetime kill count and the leaderboard.
  - Only Squires while a newcomer is on the server.
- **Phones and tablets get on-screen fight controls:** BLOCK, both SWING sides, STAB, OVERHEAD, KICK, FEINT, DODGE, SPRINT, JUMP and MENU. Dragging the screen turns the camera.
- **Each class starts with its own pair:**
  - Knight: Greatsword + War Hammer
  - Footman: Spear + Shortsword
  - Vanguard: Arming Sword + Shortsword

  Old saves with the lone Shortsword get them.

| File | Studio location | Type | Change |
|---|---|---|---|
| [BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game ▸ BotFill | ModuleScript | **new** |
| [TouchInput.lua](ReplicatedStorage/TouchInput.lua) | ReplicatedStorage ▸ TouchInput | ModuleScript | **new** |
| [TouchControls.client.lua](StarterPlayerScripts/TouchControls.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ TouchControls | LocalScript | **new** |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | fight bots, objective goal, pathfinding |
| [Game.lua](ServerScriptService/Game/Game.lua) | ServerScriptService ▸ Game ▸ Game | ModuleScript | onBotDeath, spawnCFrameForTeam, fielded |
| [Teams.lua](ServerScriptService/Game/Teams.lua) | ServerScriptService ▸ Game ▸ Teams | ModuleScript | object, botsAlive, fighters |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | starts BotFill; an asked-for mode isn't voted away |
| [TDM.lua](ServerScriptService/Game/Modes/TDM.lua), [LTS.lua](ServerScriptService/Game/Modes/LTS.lua), [KOTH.lua](ServerScriptService/Game/Modes/KOTH.lua), [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | count bots |
| [Tiltyard.lua](ServerScriptService/Game/Modes/Tiltyard.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Tiltyard | ModuleScript | Studio can switch out of it |
| [Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game ▸ Training | ModuleScript | basic training, placing, skip, harmless dummies |
| [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ReplicatedStorage ▸ Catalog ▸ Drills | ModuleScript | `basic` steps, shorter goals |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | `Harmless` attackers |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | touch buttons |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | newcomer routing, first battle, `_G.HubTravel` |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | newcomers spawn at once |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | tutorial, class pairs, setTutorial |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ServerScriptService ▸ Scoreboard | Script | bot kills pay |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | botFill, class pairs, STUDIO_NEWCOMER |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | step card, skip, banners, button names |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | first battle note, `_G.HubMenuToggle` |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | FaceYaw, touch look |
| [Movement.client.lua](StarterCharacterScripts/Movement.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ Movement | LocalScript | touch buttons |

---

## Before that: new finishers, more pets, everyone sees kill effects

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
