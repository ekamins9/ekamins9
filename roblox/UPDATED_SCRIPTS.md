# Updated scripts: phones and controllers, PETS, 3D crates, sounds that behave, swings that cut through

- **Phones:** the whole menu is bigger on a phone.
  - The dock moves to two columns on the left.
  - Screens scroll, with a "more below" chip until you do.
  - The egg shop, inventory and crate gallery fit the screen.
  - Pop-ups shrink to fit.
  - New touch buttons: EMOTE, VIEW, CROUCH and SCORES.
- **Controllers:** full Xbox / PlayStation support.
  - Triggers attack (aim with the right stick), bumpers stab and overhead, face buttons move you, the D-pad does emotes, crouch and weapons.
  - VIEW opens the menu (hold it for the scoreboard), and a cursor appears in every menu.
  - Every hint names your button (keyboard, controller or touch), including the tutorial.
- **PETS** replaces HATCHERY, with three tabs:
  - EGG SHOP: big egg cards with BUY and WHAT'S INSIDE. A bought egg goes straight into a nest.
  - MY NESTS and MY PETS. No more scrolling to find the shelf.
- **Crates are 3D chests:**
  - A gallery to pick one.
  - Its chest turns on its page.
  - Opening it, the chest thumps down, shakes and bursts open before the reel.
- **Own icons** for TRADE (two arrows round a coin and a gem) and INVENTORY (a satchel).
- **Weapon sounds:** swing sounds only play for real attacks, never from a weapon on your hip or back or from turning. The hum only plays from a weapon in your hands, and you hear your own in third person.
- **Wall hits:** wood, grass, marble, ice and the rest use the library sounds. An old folder was drowning them out. Marble rings, ice crackles.
- **Swings cut through:** a kill no longer freezes and resets the swing. The blade bites and carries on, and every hit lets the swing finish.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | phone layout (`LAYOUT`, `HX.fitScreen`), PETS tabs + egg shop, crate gallery / burst (`HX.crateView`, `HX.crateGallery`, `HX.crateBurst`), new icons |
| [GamepadControls.client.lua](StarterPlayerScripts/GamepadControls.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ GamepadControls | LocalScript | **new**: controllers |
| [InputHints.lua](ReplicatedStorage/InputHints.lua) | ReplicatedStorage ▸ InputHints | ModuleScript | **new**: control names per device, the controller layout |
| [CrateModels.lua](ReplicatedStorage/CrateModels.lua) | ReplicatedStorage ▸ CrateModels | ModuleScript | **new**: 3D chests |
| [TouchControls.client.lua](StarterPlayerScripts/TouchControls.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | EMOTE, VIEW, CROUCH, SCORES |
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua), [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua), [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayerScripts · StarterCharacterScripts | LocalScript | the action bus: emote wheel, board, view, crouch |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua), [Intro.client.lua](StarterPlayerScripts/Intro.client.lua), [MenuTour.client.lua](StarterPlayerScripts/MenuTour.client.lua), [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua), [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | hints from InputHints |
| [SkinFX.client.lua](StarterPlayerScripts/SkinFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ SkinFX | LocalScript | sounds only for real swings / held weapons; yours carries to the camera |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | hitstop no longer cuts a swing short; a kill slices through |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua), [SoundBank.lua](ReplicatedStorage/SoundBank.lua) | ServerScriptService ▸ Combat · ReplicatedStorage | ModuleScript | wall-hit sounds: bank first, Ice family, Marble |
| [UIFX.lua](ReplicatedStorage/UIFX.lua), [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua), [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ReplicatedStorage | ModuleScript | Thud / Boom sounds; Controller look speed; basics text |

**Studio-only (save the place):** two new Decals in `ReplicatedStorage ▸ Cosmetics ▸ Icons`: **Trade** and **Inventory**.

---

## Before that: our own weapon bar, CS-style crate reel, a tidy first-battle screen

- **The weapon bar** replaces Roblox's backpack bar:
  - a card per weapon: primary 1, sidearm 2, pickups after
  - each card shows a 3D picture of the weapon in its skin, edged in the skin's rarity colour, with its key and name
  - the weapon in your hands lifts, glows gold and slowly turns; a bow or crossbow shows its arrows left
  - 1–9, a click or a tap takes one out, and the same again puts it away; the D-pad steps through on a gamepad
  - hidden while you're dead, in a menu or travelling
- **The crate reel:**
  - the stage greys out to a big "?" while it rolls
  - a long strip of cards (filler drawn by the crate's own odds) rushes under a gold marker, ticking card by card
  - it creeps the last stretch, stops somewhere on the winner (never dead centre), then BOOM: the winner pops and glows, a flash, the rarity sting
  - crates from the pass and gifts get the same reel
- **The first-battle screen:** the stats line no longer runs across the loading bar.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Hotbar.client.lua](StarterPlayerScripts/Hotbar.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Hotbar | LocalScript | **new**: the weapon bar |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | weapons carry their `Slot` and `SkinId` |
| [HUD.client.lua](StarterCharacterScripts/HUD.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ HUD | LocalScript | the bars sit above the weapon bar |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | `HX.crateReel`; a `Spin` test hook (attribute = crate id) |
| [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ TravelScreen | LocalScript | first-battle stats below the bar |

---

## Before that: every Horde map in the vote again

- **Horde votes showed only The Wildwood, Ravenhold and Stormbreak.** The map-size rule counted a solo player and no bots, so the three Horde-only maps (which have no size rating) always ranked first. Horde now skips the size rule (the horde is its own crowd), so all 10 of its maps take turns: Colosseum, Hollow Grove, Pinewatch, Marshfen, Cinderfall, Bloodpit, Frosthollow and the rest.
- **Every vote (any mode) offers three maps the last one didn't**, instead of repeating two.

| File | Studio location | Type | Change |
|---|---|---|---|
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | Horde skips the map-size rule; the vote's rotation steps by three |

---

## Before that: the inventory, inspect everywhere, eggs of their own, quieter skins, showing off in the Courtyard

- **Eggs:** every egg has its own companions, nothing hatches from every egg (the dragon only comes out of the Ember Egg). Speckled is farm and shore, Mossy woods and marsh, Ember fire and night, Royal the crown's beasts. WHAT'S INSIDE scrolls instead of running off the screen.
- **INVENTORY** (a new dock tile): everything you own (skins, kill effects, emotes, companions, armor, titles), with search, kind filters, four sorts, copy counts and finishes.
- **INSPECT** anything, anywhere: the inventory, pass and login rewards, both sides of a trade, an egg's contents. It shows:
  - a big live look at it, its rarity, effects and where it comes from
  - this copy and all your copies (number, finish, story, times traded, kills)
  - Equip, Open the crate and Trade it buttons
- **Skin sounds:** a swing sound only for a real swing, measured against your body, so walking never triggers it, and quieter. While held, a soft hum: fire crackles, storm hums like a lightsaber, holy shimmers. Only heard up close.
- **Showing off in the Courtyard:** change your class, armor, colours, skin, title or look and your character changes at once, no respawn.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | INVENTORY screen, `HX.inspect`, inspect buttons, a 10-tile dock, scrolling egg contents |
| [Catalog/Companions.lua](ReplicatedStorage/Catalog/Companions.lua), [Catalog/Eggs.lua](ReplicatedStorage/Catalog/Eggs.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | every companion in one egg; every egg exclusive |
| [SkinFX.lua](ReplicatedStorage/SkinFX.lua), [SkinFX.client.lua](StarterPlayerScripts/SkinFX.client.lua) | ReplicatedStorage ▸ SkinFX · StarterPlayerScripts ▸ SkinFX | ModuleScript · LocalScript | `HUM` loops; swings measured against the body |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua), [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService | Script | `_G.CourtyardRedress` after SaveClass / SetActive / SaveAppearance |

---

## Before that: rare is rare — the daily shop, Mythics in every crate, Uniques, duplicates kept

- **The daily shop:** mostly Commons and Rares. An Epic headliner on about half the days, a Legendary on about one day in eight, never a Mythic or a Unique. Earned, pass and task skins never show there. Over 60 days: 109 Common, 91 Rare, 34 Epic, 6 Legendary.
- **Mythic in every crate**, at the lowest odds (0.3–0.5%), numbered. Odds and pity were rebalanced so a Legendary is a moment. New Mythics:
  - **Starforged** (Bladesmith): starlight aura.
  - **Worldbreaker** (Hafted): inferno aura.
  - **The Sovereign** (Royal): sovereign light.
  - **Phoenix** (Fletcher): a bow with phoenix fire and fire arrows.
  - Kill effects **Reaper's Toll** (Grim: a giant spectral scythe, souls rising) and **Supernova** (Relic: they collapse into a star that bursts).
- **Unique** (one of one, ever): never in a crate or the shop.
  - Season 1's rank-1 champions get **Crown of the First Season** (Warfront), **The Undefeated** (1v1), **Bloodmoon** (2v2) and **Stormbringer** (3v3).
  - Staff can give **Kingslayer** and **Aetherwind** (F2 ▸ item).
  - Two trims, an aura, and colours that walk through the rainbow. They trade; they can't be scrapped.
- **Duplicates are kept, never paid back:** kill effects and emotes out of crates are copies now too, and they trade.
- **Every crate spins:** a crate from the pass, a daily or a playtime gift opens on the crate screen with the drum and the reveal.
- **Short of Crowns or Marks:** a pop-up offers the Crown bundles (one click) or the Crowns › Marks exchange right there.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua), [Catalog/Store.lua](ReplicatedStorage/Catalog/Store.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | Unique tier, the shelf's rarity rules |
| [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | ReplicatedStorage ▸ Catalog ▸ Crates | ModuleScript | Mythic odds everywhere, longer pity |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua), [scripts/gen_content.py](../scripts/gen_content.py) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | Mythics, Uniques, `trim2`; bows keep their own looks |
| [Catalog/KillFX.lua](ReplicatedStorage/Catalog/KillFX.lua), [KillFX.lua](ReplicatedStorage/KillFX.lua) | ReplicatedStorage | ModuleScript | Reaper's Toll, Supernova |
| [Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ReplicatedStorage ▸ Catalog ▸ Economy | ModuleScript | season champions' Uniques |
| [SkinFX.lua](ReplicatedStorage/SkinFX.lua), [SkinTrims.lua](ReplicatedStorage/SkinTrims.lua), [UIFX.lua](ReplicatedStorage/UIFX.lua) | ReplicatedStorage | ModuleScript | Mythic auras and glints, Unique prism, two trims |
| [Collection.lua](ServerScriptService/Economy/Collection.lua), [Economy.lua](ServerScriptService/Economy/Economy.lua), [Season.server.lua](ServerScriptService/Economy/Season.server.lua) | ServerScriptService ▸ Economy | ModuleScript · Script | one-of-one serials, fx/emote copies, no refunds, champion payouts, amounts in "not enough" |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua), [AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua), [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService | ModuleScript · Script | copies count as owned; no Uniques in unlock-all |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua), [Pastimes.client.lua](StarterPlayerScripts/Pastimes.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `HX.spinCrate`, `HX.shortOf`, Unique colours, fx/emote trade cards |

---

## Before that: arrows land where you aim, and the bow shoots 1.5x farther

- **Arrows land on the point under the reticle**, near or far: they're loosed on the arc that carries them there at their speed.
  - The client sends the point; the server solves with the speed it timed itself, so the real arrow and the one you see agree.
  - Tested through the real server: shots at 73, 157, 305 and 504 studs all hit their target.
  - Out of reach, a shot lobs at the angle that carries furthest. Aimed at the open sky, it flies along your look.
  - The crossbow lands under its reticle too.
- **The longbow shoots 1.5x farther**: a full draw is 180 studs/s (was 147), about 800 studs at the longest lob. Arrows may fly 9 s.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Ballistics.lua](ReplicatedStorage/Ballistics.lua) | ReplicatedStorage ▸ Ballistics | ModuleScript | **new**: the arc that lands an arrow on its aim |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | sends the aimed point; your arrow flies the arc |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | solves the arc at the server's speed |
| [Bow/Config.lua](Tools/Bow/Config.lua) | the Bow Tool ▸ Config | ModuleScript | 67–180 studs/s, 9 s flights |
| [ArrowFlight.lua](ReplicatedStorage/ArrowFlight.lua) | ReplicatedStorage ▸ ArrowFlight | ModuleScript | a lost arrow lasts 10 s |

---

## Before that: the newcomer's intro, no starting kill effect, the vote's cursor for good

- **The game has a name: Steel & Glory** (`GameConfig.GAME_NAME`).
- **The welcome** (new `Intro`):
  - A ~12 s cinematic over the Courtyard (any key skips), to its own heroic score.
  - Then WELCOME, SOLDIER! with BEGIN TRAINING (recommended) or SKIP TO BATTLE, which asks ARE YOU SURE? first.
  - The travel screen comes up the moment they choose.
- **Training:**
  - New players are a **Knight with a Greatsword**.
  - Training starts with **Find Your Feet**: a checklist of the camera (Z), sprint, crouch, hop, dodge and freeing the mouse (T), in their own binds, ticking as they press each.
  - **M** (or the button) asks SKIP TRAINING? first.
- **The first battle:**
  - It's always Team Deathmatch, Free-for-All or King of the Hill, never a siege.
  - A briefing card on arrival, then one-time tips: the first wound (block / parry), out of breath, FIRST KILL!, the first fall.
  - When the round ends, the travel screen appears **at once** with how it went (kills, deaths, Marks, XP), instead of a few seconds of the vote.
- **Back in the Courtyard** (new `MenuTour`):
  - A spotlight tour of the menu that ends on Settings (rebind any key) and the menu key.
  - Then the **recruit's gift** (500 Marks + a Key) with OPEN A CRATE, straight to the crates.
- **No kill effect to start with:** plain falls. Shatter moves to the Relic crate (whoever has it on keeps it), and ARMORY ▸ KILL FX has a *No effect* choice.
- **The vote's cursor:** forced on and free every frame of the vote, after everything else that touches the mouse.
- **No body, still a world:** players without a character stream the map's middle, so the menu's and the intro's camera see the Courtyard (it was empty haze before).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Intro.client.lua](StarterPlayerScripts/Intro.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Intro | LocalScript | **new**: the welcome, the first battle's briefing and tips |
| [MenuTour.client.lua](StarterPlayerScripts/MenuTour.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ MenuTour | LocalScript | **new**: the Courtyard welcome, the tour, the gift |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | Find Your Feet, the skip question, M |
| [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ TravelScreen | LocalScript | `_G.ShowTravel`, the first battle's summary |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | intro hooks, tour names, `_G.HubMenuGo`, *No effect* |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | the vote's cursor, bound last |
| [Music.client.lua](StarterPlayerScripts/Music.client.lua), [MusicConfig.lua](ReplicatedStorage/MusicConfig.lua) | StarterPlayerScripts ▸ Music · ReplicatedStorage ▸ MusicConfig | LocalScript · ModuleScript | the Intro mood |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | the Intro and TourDone ops, first-battle modes, the trip home sooner, equip no kill effect |
| [Training.lua](ServerScriptService/Game/Training.lua), [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ServerScriptService ▸ Game ▸ Training · ReplicatedStorage ▸ Catalog ▸ Drills | ModuleScript | Find Your Feet |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | `menuTour`, `starterGift`, no starting kill effect, Knight |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua), [MapLoader.lua](ServerScriptService/Game/MapLoader.lua) | ServerScriptService ▸ Game | Script · ModuleScript | streaming focus for the bodiless, map shot attributes |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua), [Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua), [Catalog/KillFX.lua](ReplicatedStorage/Catalog/KillFX.lua) | ReplicatedStorage | ModuleScript | name, Knight default, the gift, Shatter in the Relic crate |

---

## Before that: the vote's cursor, bots that climb and hop, maps sized to the numbers

- **The cursor is back on the vote screen.** Players stay alive through the intermission and the camera kept locking and hiding the mouse every frame; it lets go while the vote is up, and the board keeps the cursor on for the dead and the spectating too.
- **Bots:**
  - They walk up hills and ramps. Their look-ahead used to take rising ground for a wall and turn away; Millfield's hill is the case that showed it.
  - They hop over anything low (under ~2.3 studs: rocks, logs, low walls).
  - Stuck for a second, they hop, then step aside and work out a fresh path.
  - Paths are narrower (agent radius 1.5, so they get out between a hay bale and a barn wall). When the goal itself is unreachable (the hill's middle is under the windmill), the path goes to open ground beside it.
- **Maps sized to the player count:**
  - Every map has a fighter range, players and bots together (`GameConfig.MAP_FIGHTERS`). Rose Court is 2–6 (1v1 to 3v3), the arenas 2–12, Sandpit 2–16, Highbridge 4–20, the baileys and bridges 6–24, the open fields 8–32 and the sieges 8–40.
  - The vote offers maps that suit the players there and the bots the mode brings.
  - Bots never fill a map past its most.
  - A public server's room shrinks to its map's most, so matchmaking won't pour 16 people into a garden.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | frees the mouse during the vote |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | keeps the cursor on while the vote is up |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | slopes, hops, `unstick`, path fixes |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | `MAP_FIGHTERS`, `mapFighters`, `mapFit` |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | map candidates sized to the numbers |
| [BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game ▸ BotFill | ModuleScript | caps bots at the map's most; `BotFill.wanted(def)` |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | a public server's room is its map's most |

---

## Before that: bow and crossbow skins that look and sound different

- **Every bow and crossbow skin changes its silhouette.** A new ranged trim set is fitted to the limbs and the prod:
  - flame tongues, horn curls, thorns, crystal clusters, wings, feathers, ice spikes
  - a skull, gilded caps, storm zig-zags, venom drops, blood barbs, obsidian shards and a void core
  - a dragon's horns and dorsal ridge, a halo
- **Arrows look better:**
  - In flight: a wide colour trail with a hot core, particles, a light, and the kind's own touch (a halo, a flicker, smoke, wisps).
  - On landing, each kind has its own impact: a fire that keeps burning, ice shards, a lightning bolt from the sky, a pillar of light, an implosion, a splash of blood, a lingering poison cloud, a fountain of gold, rising spirits.
  - Two new kinds: **Void** and **Spirit**.
- **Arrows sound different:** each kind has its own release and impact sound (licensed library sounds) layered over the bow's own.
- **5 new skins in the Fletcher's Crate:** Seraph's Wing, Crystalline, Voidcaller (bows); Soulreaper, Runecaster (crossbows).

| File | Studio location | Type | Change |
|---|---|---|---|
| [SkinTrims.lua](ReplicatedStorage/SkinTrims.lua) | ReplicatedStorage ▸ SkinTrims | ModuleScript | the ranged trim set (`RT`) |
| [ArrowFX.lua](ReplicatedStorage/ArrowFX.lua) | ReplicatedStorage ▸ ArrowFX | ModuleScript | richer flight, impacts per kind, sounds, void / spirit |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | plays each kind's release / impact sounds |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua), [scripts/skins_handmade.part](../scripts/skins_handmade.part), [scripts/gen_content.py](../scripts/gen_content.py) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | trims on every ranged skin, 5 new skins |

---

## Before that: the crossbow — aim to shoot, reload yourself, new poses

- **Controls:**
  - Hold right mouse to raise the crossbow and aim; it zooms down the tiller. Click fires, but only while it's raised; otherwise a hint says to hold right mouse.
  - After a shot it **stays empty**. Press **R** (rebindable) or click to reload. The reticle says "EMPTY · R TO RELOAD".
  - Phones: hold BLOCK to aim, SWING fires or reloads.
- **Poses** (both hands, always):
  - **At ease:** carried low and diagonal across the body.
  - **Aimed:** shouldered, a little side-on, pointing where you look, the left hand under the stock.
  - **Reloading:** bent over, the nose down at the right foot in the stirrup, hauling the string up in three strokes.
  - Everyone sees the string follow the haul.
- **Fixes:** putting the crossbow away mid-reload no longer leaves you stuck at reload walking speed. A refilled bolt no longer loads it by itself.

| File | Studio location | Type | Change |
|---|---|---|---|
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | "Reload" action; no auto reload; `ReloadAt` |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | hold to aim, click to fire / reload, R, hints |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | crossbow at ease / aimed / spanning (`XBOW`) |
| [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RangedFX | LocalScript | others' string follows the haul |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | Reload bind (R) |
| [Tools/Crossbow/Config.lua](Tools/Crossbow/Config.lua) | ServerStorage ▸ Weapons ▸ Crossbow ▸ Config | ModuleScript | description |

---

## Before that: the longbow shoots 1.5× farther

- **Longbow arrows fly faster:** a full draw goes from 120 to 147 studs/s, and a snap shot from 45 to 55. Gravity is the same, and range goes with speed squared, so every shot carries about 1.5× as far and hits a bit sooner.
- **Arrows may fly for up to 6 s** (was 4), so long lobs aren't dropped mid-air. The arrow everyone sees lasts 7 s.
- Damage is unchanged, and so is the crossbow.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Tools/Bow/Config.lua](Tools/Bow/Config.lua) | ServerStorage ▸ Weapons ▸ Bow ▸ Config | ModuleScript | SPEED_MIN 55, SPEED_MAX 147, MAX_FLIGHT 6 |
| [ArrowFlight.lua](ReplicatedStorage/ArrowFlight.lua) | ReplicatedStorage ▸ ArrowFlight | ModuleScript | a lost arrow lasts 7 s |

---

## Before that: the whole game a touch quicker

- **Swings are 12% quicker:** every weapon's windup, swing and recovery (`GameConfig.TEMPO.swing` = 1.12, on top of each weapon's own speed). Bots, feints, morphs and parry windows follow, since they're all timed from the same numbers. The menu's windup figures match.
- **Movement is 10% quicker:** base walk speed 11 (was 10). Sprint, armor and weapon weight, the slow-downs while swinging and blocking, bots and footstep cadence all scale from it.
- Bows and crossbows are unchanged (they stay slow on purpose).

| File | Studio location | Type | Change |
|---|---|---|---|
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | `TEMPO.swing` |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | attack times × the tempo |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | menu windups × the tempo |
| [MovementConfig.lua](ReplicatedStorage/MovementConfig.lua) | ReplicatedStorage ▸ MovementConfig | ModuleScript | BASE_SPEED 11 |

---

## Before that: maps verified, ready to publish

- **Every map checked:**
  - All 36 maps exist, and every mode has 10 or more.
  - Each map has what its modes need.
  - All 25 new maps have vote pictures.
- **Map fixes found while checking:**
  - Redgorge's gorge floor sat below its stored terrain and showed the void.
  - The forest clearings' ponds had no water.
  - Round fills thinner than a voxel row wrote nothing: the arena floors and the village squares.
  - Bots couldn't climb the 1-stud temple steps, so nobody ever reached the KOTH hill on the ruins maps. Invisible ramps now run along all four sides, and the arena dais and village platform are a low step.
  - The obelisk tips rendered as forked V shapes.
- **Played:** Siege on Emberkeep, KOTH on Cinderfall, TDM on Moonring, with no script errors.
- **Before publishing:** test rigs left in the place were removed. `/spawn` test dummies no longer work on live servers (only in Studio, or for the host of a cheat server).

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapForge.lua](ServerScriptService/Build/MapForge.lua) | ServerScriptService ▸ Build ▸ MapForge | ModuleScript | the fixes above |
| [TestDummies.server.lua](ServerScriptService/TestDummies.server.lua) | ServerScriptService ▸ TestDummies | Script | Studio / cheat-server host only |
| [../docs/HANDOFF.md](../docs/HANDOFF.md) | (docs) | | publishing checklist |

---

## Before that: 25 new maps, every mode has 10 or more

- **A map forge:** each new map is one line, a layout in a theme.
  - **Layouts:** arena, castle courtyard, village, bridge, ruins, forest clearing, siege castle.
  - **Themes:** summer, autumn, winter, moonlit snow, desert noon, desert dusk, swamp mist, storm night, ember night, spring, dawn mist, ash, firefly forest.
  - Each theme sets the time of day, haze, colours, trees and weather (snow, rain, ash, falling leaves, petals, embers, fireflies, dust, mist).
- **25 new maps:**
  - **Siege:** Emberkeep, Sunspire, Thornwall, Mistmoor, Greenhollow, Stormhold, Ashenford, Rimeholt, Blossomgate. Each castle has its own champion.
  - **Arenas:** the Bloodpit, Moonring, the Dustbowl, Thornpit, Mirepit.
  - **Courtyards:** Abbeyfield, Blackwater.
  - **Villages:** Harvestvale, Frosthollow, Marshfen.
  - **Bridges:** Redgorge, Mistbridge.
  - **Ruins:** Cinderfall, Duneshrine.
  - **Clearings:** Hollow Grove, Pinewatch.
- **Every mode now lists 10 or more maps:** Siege 10, Lists 10, Duel 11, FFA 12, TDM 12, LTS 12, KOTH 11, Horde 10.
- **Fix:** the KOTH hill showed as a yellow drum in every other mode. The loader now hides it.
- **In Studio:** build them with `require(game.ServerScriptService.Build.Maps).buildForge()`, then **save the place**. The maps and their vote pictures live in the place.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapForge.lua](ServerScriptService/Build/MapForge.lua) | ServerScriptService ▸ Build ▸ MapForge | ModuleScript | **new**: themes, layouts, the 25 maps |
| [Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | builds forge maps, `buildForge()` |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | map titles; every mode's maps |
| [MapLoader.lua](ServerScriptService/Game/MapLoader.lua) | ServerScriptService ▸ Game ▸ MapLoader | ModuleScript | zones hidden on load |

---

## Before that: leaderboards, season rewards, player profiles, privacy

- **A LEADERBOARDS screen** (open it from the lobby board's "TOP 100 · SEASON REWARDS"):
  - The Warfront and each ranked bracket, top 100 each.
  - Where you stand, and a search by name.
  - The season's rewards and how long is left, with your current line lit up.
- **Season rewards are real now:**
  - When the season ends, the top of each board is paid (titles, Crowns, Marks, Keys), and so is the ranked tier you finished in.
  - You're paid the next time you join.
  - A new season gets fresh boards.
- **Player profiles:** click anyone on a leaderboard, use PROFILE in the players-here list, or look at someone in the world and press P. A profile shows:
  - their record (kills, deaths, K/D, rounds, wins, win rate, parries, season kills)
  - their ranked tiers
  - every class dressed as they wear it
  - their collection and finest skins
  - buttons to trade, invite to your party, or send a Roblox friend request
- **Privacy settings:** who can send you party invites and trade requests (everyone, friends, nobody). The server enforces both.
- **Fix:** a cached board could be stuck at 10 rows.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | LEADERBOARDS and PROFILE screens, ways in, the P key |
| [Season.server.lua](ServerScriptService/Economy/Season.server.lua) | ServerScriptService ▸ Economy ▸ Season | Script | **new**: the season's end and its payout |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | "Board", "PlayerProfile"; party invite privacy |
| [Leaderboards.lua](ServerScriptService/Hub/Leaderboards.lua) | ServerScriptService ▸ Hub ▸ Leaderboards | ModuleScript | season boards, places, saved profiles, cache fix |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ServerScriptService ▸ Scoreboard | Script | writes the season's boards |
| [SettingsServer.server.lua](ServerScriptService/SettingsServer.server.lua) | ServerScriptService ▸ SettingsServer | Script | privacy onto the player |
| [Trading.lua](ServerScriptService/Economy/Trading.lua) | ServerScriptService ▸ Economy ▸ Trading | ModuleScript | trade request privacy |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | privacy choices, the Profile bind |
| [Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ReplicatedStorage ▸ Catalog ▸ Economy | ModuleScript | `seasonRewards` |

---

## Before that: custom server bots and the host's server panel

- **Custom servers have bots:**
  - Set them when you make the server: on or off, how many fighters in all (players plus bots), and their skill (Mixed, Squire, Knight or Champion).
  - Ranked never has bots.
- **The host's SERVER PANEL:** the host gets a YOUR SERVER card in the lobby. The panel:
  - **Players:** kick someone (they stay out while the server runs), or hand the server over.
  - **Bots:** fill on/off, how many and how good, changed live. Spawn practice bots where you stand (+1 / +3, pick their skill), or clear them.
  - **The round:** pick the next mode and map, or end the round now.
  - **Rules, changed live:** friendly fire, respawns, weapons on the ground, round length, player limit, who can join.
  - If the host leaves, whoever has been there longest takes over.
- **Fixes:**
  - A custom server's chosen map is now used (it always rotated).
  - "Weapons on the ground" now does something: off means a dropped weapon can't be picked up and goes in a few seconds.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HostServer.server.lua](ServerScriptService/Hub/HostServer.server.lua) | ServerScriptService ▸ Hub ▸ HostServer | Script | **new**: the host's controls (HostRemote) |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | host card + SERVER PANEL; bot settings when creating |
| [BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game ▸ BotFill | ModuleScript | custom servers by their settings |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | bot settings checked |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | custom map used; Round GroundWeapons |
| [Pickup.lua](ServerScriptService/Combat/Pickup.lua) | ServerScriptService ▸ Combat ▸ Pickup | ModuleScript | no pickups when ground weapons are off |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | bot defaults, `BOT_SKILLS` |

---

## Before that: the bow flipped, a ready stance, no arm jolt; a warning before leaving a battle

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
