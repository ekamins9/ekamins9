# Roblox scripts

Folder layout mirrors where each script lives in Studio.

**Syncing to Studio:** the repo is a [Rojo](https://rojo.space) project (`default.project.json`); see [ROJO_SETUP.md](ROJO_SETUP.md). `git pull` + `rojo serve` puts every script into the open place live.

| File | Studio location | Type |
|---|---|---|
| `ReplicatedStorage/MovementConfig.lua` | `ReplicatedStorage` → `MovementConfig` | ModuleScript |
| `ReplicatedStorage/DebugFlags.lua` | `ReplicatedStorage` → `DebugFlags` | ModuleScript |
| `ReplicatedStorage/Modifiers.lua` | `ReplicatedStorage` → `Modifiers` | ModuleScript |
| `ReplicatedStorage/Sounds.lua` | `ReplicatedStorage` → `Sounds` | ModuleScript |
| `ReplicatedStorage/SoundConfig.lua` | `ReplicatedStorage` → `SoundConfig` | ModuleScript |
| `ReplicatedStorage/SoundBank.lua` | `ReplicatedStorage` → `SoundBank` (the fight's sound pools and voices) | ModuleScript |
| `ReplicatedStorage/RigPose.lua` | `ReplicatedStorage` → `RigPose` | ModuleScript |
| `ReplicatedStorage/Combat/CombatClient.lua` | `ReplicatedStorage` → `Combat` (Folder) → `CombatClient` | ModuleScript |
| `ServerScriptService/WalkSpeedGovernor.server.lua` | `ServerScriptService` → `WalkSpeedGovernor` | Script |
| `ServerScriptService/CharacterSystems.server.lua` | `ServerScriptService` → `CharacterSystems` | Script |
| `ServerScriptService/PoseRelay.server.lua` | `ServerScriptService` → `PoseRelay` | Script |
| `ServerScriptService/TestDummies.server.lua` | `ServerScriptService` → `TestDummies` | Script |
| `ServerScriptService/Combat/CombatServer.lua` | `ServerScriptService` → `Combat` (Folder) → `CombatServer` | ModuleScript |
| `ServerScriptService/Combat/Injury.lua` | `ServerScriptService` → `Combat` → `Injury` | ModuleScript |
| `ServerScriptService/Combat/Ragdoll.lua` | `ServerScriptService` → `Combat` → `Ragdoll` | ModuleScript |
| `ServerScriptService/Combat/Pickup.lua` | `ServerScriptService` → `Combat` → `Pickup` | ModuleScript |
| `ServerScriptService/Combat/Bots.lua`, `R6.lua` | `ServerScriptService` → `Combat` → `Bots`, `R6` (AI fighters; a plain R6 rig) | ModuleScript each |
| `ServerScriptService/Combat/Janitor.lua` | `ServerScriptService` → `Combat` → `Janitor` (clears corpses, severed limbs, heads, dropped weapons) | ModuleScript |
| `ServerScriptService/Combat/Corpses.lua` | `ServerScriptService` → `Combat` → `Corpses` (lays out the dead; a kill effect's remains) | ModuleScript |
| `ServerScriptService/Game/Training.lua` | `ServerScriptService` → `Game` → `Training` (the training yard's dummies, Drill Master, lessons, ring) | ModuleScript |
| `ServerScriptService/Build/MapTraining.lua` | `ServerScriptService` → `Build` → `MapTraining` (the training yard map) | ModuleScript |
| `StarterPlayerScripts/Training.client.lua`, `NpcAnimator.client.lua`, `Footsteps.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Training`, `NpcAnimator`, `Footsteps` | LocalScript each |
| `ReplicatedStorage/Footsteps.lua` | `ReplicatedStorage` → `Footsteps` | ModuleScript |
| `ServerScriptService/MovementServer.server.lua` | `ServerScriptService` → `MovementServer` | Script |
| `ServerScriptService/SettingsServer.server.lua` | `ServerScriptService` → `SettingsServer` | Script |
| `ReplicatedStorage/ClientSettings.lua` | `ReplicatedStorage` → `ClientSettings` | ModuleScript |
| `StarterCharacterScripts/Movement.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `Movement` | LocalScript |
| `ServerScriptService/Scoreboard.server.lua` | `ServerScriptService` → `Scoreboard` | Script |
| `ReplicatedStorage/GameConfig.lua` | `ReplicatedStorage` → `GameConfig` | ModuleScript |
| `ServerScriptService/Game/Game.lua` | `ServerScriptService` → `Game` (Folder) → `Game` | ModuleScript |
| `ServerScriptService/Game/MapLoader.lua` | `ServerScriptService` → `Game` → `MapLoader` | ModuleScript |
| `ServerScriptService/Game/Teams.lua` | `ServerScriptService` → `Game` → `Teams` | ModuleScript |
| `ServerScriptService/Game/GameServer.server.lua` | `ServerScriptService` → `Game` → `GameServer` | Script |
| `ServerScriptService/Game/Modes/<Id>.lua` | `ServerScriptService` → `Game` → `Modes` (Folder) → `Hub`, `Tiltyard`, `FFA`, `Duel`, `TDM`, `LTS`, `KOTH`, `Lists` | ModuleScript each |
| `ServerScriptService/Hub/HubServer.server.lua` | `ServerScriptService` → `Hub` (Folder) → `HubServer` | Script |
| `ServerScriptService/Hub/Matchmaker.lua` | `ServerScriptService` → `Hub` → `Matchmaker` | ModuleScript |
| `ServerScriptService/Hub/Cheats.server.lua` | `ServerScriptService` → `Hub` → `Cheats` | Script |
| `ServerScriptService/Economy/Economy.lua` | `ServerScriptService` → `Economy` (Folder) → `Economy` | ModuleScript |
| `ServerScriptService/Economy/Stats.lua` | `ServerScriptService` → `Economy` → `Stats` | ModuleScript |
| `ServerScriptService/Hub/Courtyard.server.lua`, `Leaderboards.lua` | `ServerScriptService` → `Hub` → `Courtyard` (Script), `Leaderboards` (ModuleScript) | Script / ModuleScript |
| `ServerScriptService/Build/MapCourtyard.lua` | `ServerScriptService` → `Build` → `MapCourtyard` (the hub map) | ModuleScript |
| `StarterPlayerScripts/Courtyard.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Courtyard` | LocalScript |
| `StarterPlayerScripts/Objectives.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Objectives` | LocalScript |
| `ServerScriptService/Admin/AdminServer.server.lua`, `Roles.lua` | `ServerScriptService` → `Admin` (Folder) → `AdminServer` (Script), `Roles` (ModuleScript) | Script / ModuleScript |
| `ServerScriptService/Safety/TextFilter.lua`, `Erasure.lua` | `ServerScriptService` → `Safety` (Folder) → `TextFilter` (Roblox's filter for anything typed that others read: server names, staff text), `Erasure` (a right-to-erasure request: every trace of a player) | ModuleScript each |
| `ServerScriptService/Safety/Stores.lua` | `ServerScriptService` → `Safety` → `Stores` (every data store is opened through it; Studio gets `Studio_` copies so tests never touch live saves) | ModuleScript |
| `ServerScriptService/Hub/Reminders.server.lua` | `ServerScriptService` → `Hub` → `Reminders` (Roblox notifications: a weekend event starting, the next daily gift; setup in docs/LAUNCH.md §8) | Script |
| `ReplicatedStorage/Rules.lua` | `ReplicatedStorage` → `Rules` (the game's own rules and their consequences: the Courtyard board, MENU › SETTINGS › THE RULES, kick and ban messages) | ModuleScript |
| `StarterPlayerScripts/AdminPanel.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `AdminPanel` | LocalScript |
| `ReplicatedStorage/Defight.lua` | `ReplicatedStorage` → `Defight` | ModuleScript |
| `ServerScriptService/Game/Modes/Siege.lua` | `ServerScriptService` → `Game` → `Modes` → `Siege` | ModuleScript |
| `ServerScriptService/Build/MapFrostgate.lua` | `ServerScriptService` → `Build` → `MapFrostgate` | ModuleScript |
| `ServerScriptService/Build/MapColosseum.lua` | `ServerScriptService` → `Build` → `MapColosseum` | ModuleScript |
| `ServerScriptService/Build/MapRoseCourt.lua` | `ServerScriptService` → `Build` → `MapRoseCourt` | ModuleScript |
| `ServerScriptService/Build/MapProps.lua` | `ServerScriptService` → `Build` → `MapProps` (wagons, trees, campfires, braziers, graves, longships…) | ModuleScript |
| `ServerScriptService/Build/MapWildwood.lua`, `MapRavenhold.lua`, `MapStormbreak.lua` | `ServerScriptService` → `Build` → `MapWildwood` / `MapRavenhold` / `MapStormbreak` | ModuleScript |
| `ServerScriptService/Game/Modes/Horde.lua` | `ServerScriptService` → `Game` → `Modes` → `Horde` | ModuleScript |
| `ServerScriptService/Combat/Powers.lua`, `Throwing.lua`, `Shields.lua` | `ServerScriptService` → `Combat` → `Powers` / `Throwing` / `Shields` (powers, throwables, shields) | ModuleScript each |
| `ServerScriptService/Build/ArsenalBlueprints.lua` | `ServerScriptService` → `Build` → `ArsenalBlueprints` (shields' and throwables' bodies) | ModuleScript |
| `ReplicatedStorage/Heraldry.lua` | `ReplicatedStorage` → `Heraldry` (arms painted on shields) | ModuleScript |
| `ReplicatedStorage/Catalog/Powers.lua`, `Arsenal.lua`, `ArsenalSkins.lua`, `PowerSkins.lua`, `Mastery.lua` | `ReplicatedStorage` → `Catalog` → … | ModuleScript each |
| `StarterPlayerScripts/Powers.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Powers` (the orb, the Power key, every power's FX, thrown things, shields raised) | LocalScript |
| `StarterPlayerScripts/StatusFX.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `StatusFX` (burning, frozen, poisoned, rooted, dazed, shocked bodies) | LocalScript |
| `Tools/<Shield or Throwable>` (18) | `ServerStorage` → `Weapons` → `<id>` (a Tool with a Config; Blueprints builds the body) | Tool |
| `ServerScriptService/Game/HordeObjective.lua` | `ServerScriptService` → `Game` → `HordeObjective` (the campfire, the caravan, the villagers) | ModuleScript |
| `ServerScriptService/Economy/Pastimes.lua` | `ServerScriptService` → `Economy` → `Pastimes` (gifts, eggs, hatching, companions) | ModuleScript |
| `ServerScriptService/Hub/Pastimes.server.lua` | `ServerScriptService` → `Hub` → `Pastimes` (playtime clock, the Hatchery) | Script |
| `ReplicatedStorage/Companions.lua` | `ReplicatedStorage` → `Companions` (creatures and eggs built from parts) | ModuleScript |
| `StarterPlayerScripts/Pastimes.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Pastimes` (companions following, the gift chip, your eggs in the nests) | LocalScript |
| `ServerScriptService/Economy/EconomyServer.server.lua` | `ServerScriptService` → `Economy` → `EconomyServer` | Script |
| `ServerScriptService/Economy/Pulls.lua` | `ServerScriptService` → `Economy` → `Pulls` (big pulls: banners, the feed, how many exist) | ModuleScript |
| `ServerScriptService/Economy/Gifting.lua` | `ServerScriptService` → `Economy` → `Gifting` (the gift box: send anything to anyone, buy as a gift) | ModuleScript |
| `ServerScriptService/Build/<Name>.lua` | `ServerScriptService` → `Build` (Folder) → `Builder`, `Weapons`, `Armor`, `Body`, `Blueprints` | ModuleScript each |
| `ReplicatedStorage/Theme.lua` | `ReplicatedStorage` → `Theme` | ModuleScript |
| `ServerScriptService/Loadout/Profile.lua` | `ServerScriptService` → `Loadout` → `Profile` | ModuleScript |
| `ReplicatedStorage/Catalog/init.lua` | `ReplicatedStorage` → `Catalog` | ModuleScript |
| `ReplicatedStorage/Catalog/<Name>.lua` | `ReplicatedStorage` → `Catalog` → `Weights`, `Packs`, `Pieces`, `Weapons`, `Skins`, `Body`, `Palette`, `Crates`, `Economy`, `Contracts`, `Store`, `Pass`, `Login`, `KillFX`, `Emotes` (children of the Catalog ModuleScript) | ModuleScript each |
| `ReplicatedStorage/Dresser.lua` | `ReplicatedStorage` → `Dresser` | ModuleScript |
| `ReplicatedStorage/PreviewRig.lua` | `ReplicatedStorage` → `PreviewRig` (a dressed mannequin for menus) | ModuleScript |
| `ReplicatedStorage/SkinTrims.lua`, `SkinFX.lua`, `StaffHeads.lua` | `ReplicatedStorage` → `SkinTrims`, `SkinFX`, `StaffHeads` (a skin's trim parts; its trail and aura; a staff skin's head) | ModuleScript each |
| `ReplicatedStorage/KillFX.lua`, `Emotes.lua`, `PowerPoses.lua`, `PowerAuras.lua` | `ReplicatedStorage` → `KillFX`, `Emotes`, `PowerPoses`, `PowerAuras` (the effects and motions; a power's gesture; a lasting power's look on you) | ModuleScript each |
| `ServerScriptService/Hub/Cosmetics.server.lua` | `ServerScriptService` → `Hub` → `Cosmetics` | Script |
| `StarterPlayerScripts/Cosmetics.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Cosmetics` (kill effects, emotes, the emote wheel) | LocalScript |
| `StarterPlayerScripts/HubMenu.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `HubMenu` | LocalScript |
| `StarterPlayerScripts/TravelScreen.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `TravelScreen` | LocalScript |
| `ReplicatedFirst/Loading.client.lua` | `ReplicatedFirst` → `Loading` (the first thing anyone sees: the name while the game loads, or the travel screen carried over) | LocalScript |
| `StarterPlayerScripts/DeathScreen.client.lua`, `Celebrate.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `DeathScreen` (the fall and the way back), `Celebrate` (FIGHT!, LEVEL UP, a class unlocked, spawn embers) | LocalScript each |
| `StarterPlayerScripts/RiposteCue.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `RiposteCue` (the riposte window: your HUD, everyone's gold blade) | LocalScript |
| `StarterPlayerScripts/OffHand.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `OffHand` (a one-handed weapon's free arm keeps still: the left shoulder's animated turn taken out each frame) | LocalScript |
| `StarterPlayerScripts/LocaleText.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `LocaleText` (English readers skip automatic translation: cheaper screens) | LocalScript |
| `ReplicatedStorage/Ballistics.lua` | `ReplicatedStorage` → `Ballistics` (the arc that lands an arrow on its aim) | ModuleScript |
| `StarterPlayerScripts/Intro.client.lua`, `MenuTour.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Intro`, `MenuTour` (a newcomer's welcome, first battle and menu tour) | LocalScript each |
| `StarterPlayerScripts/Scoreboard.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Scoreboard` | LocalScript |
| `StarterPlayerScripts/NameTags.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `NameTags` | LocalScript |
| `StarterPlayerScripts/SkinFX.client.lua`, `TrimAnim.client.lua`, `DrawFX.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `SkinFX`, `TrimAnim`, `DrawFX` | LocalScript each |
| `ServerScriptService/Loadout/Armor.lua` | `ServerScriptService` → `Loadout` (Folder) → `Armor` | ModuleScript |
| `ServerScriptService/Loadout/LoadoutServer.server.lua` | `ServerScriptService` → `Loadout` → `LoadoutServer` | Script |
| `ServerStorage/Armor/<Set>/Config.lua` | `ServerStorage` → `Armor` (Folder) → each set → `Config` | ModuleScript |
| `StarterPlayerScripts/LoadoutMenu.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript |
| `StarterPlayerScripts/Spectate.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Spectate` (watch the fight while dead) | LocalScript |
| `StarterPlayerScripts/CleanView.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `CleanView` (Ctrl+H hides all UI, the game's and Roblox's, for filming; again to bring it back) | LocalScript |
| `ServerScriptService/Game/Showcase.lua`, `StarterPlayerScripts/Showcase.client.lua` | `ServerScriptService` → `Game` → `Showcase` (staff stage bot matches, the Courtyard tour, the armor parade for filming); `StarterPlayerScripts` → `Showcase` (the director's camera) | ModuleScript, LocalScript |
| `StarterPlayerScripts/RigReplicator.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `RigReplicator` | LocalScript |
| `StarterPlayerScripts/War.client.lua`, `SiegeEpic.client.lua`, `Warfield.client.lua`, `Engines.client.lua`, `MatchIntro.client.lua`, `BattleAmbience.client.lua`, `ArenaCrowd.client.lua`, `HordeHost.client.lua`, `CourtyardGuards.client.lua`, `BossEntrance.client.lua`, `DungeonMood.client.lua`, `BannerWind.client.lua`, `Weather.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → each by its name (the battles, the crowds, the dark, the wind) | LocalScript each |
| `ReplicatedStorage/WarFX.lua`, `WarCrowd.lua`, `BossIntro.lua` | `ReplicatedStorage` → `WarFX`, `WarCrowd`, `BossIntro` | ModuleScript each |
| `ServerScriptService/Game/WarMap.lua`, `WarProps.lua`, `Engines.lua`, `Litter.lua`, `Traps.lua`, `Secrets.lua`, `Breakables.lua` | `ServerScriptService` → `Game` → each by its name | ModuleScript each |
| `StarterPlayerScripts/Traps.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Traps` | LocalScript |
| `StarterPlayerScripts/TavernAmbience.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `TavernAmbience` | LocalScript |
| `StarterPlayerScripts/WhatsNew.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `WhatsNew` | LocalScript |
| `StarterPlayerScripts/CinematicGrade.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `CinematicGrade` | LocalScript |
| `ReplicatedStorage/Hearing.lua` | `ReplicatedStorage` → `Hearing` | ModuleScript |
| `StarterPlayerScripts/NightWindows.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `NightWindows` | LocalScript |
| `StarterPlayerScripts/SpiderLegs.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `SpiderLegs` | LocalScript |
| `StarterPlayerScripts/Hearing.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Hearing` | LocalScript |
| `StarterCharacterScripts/CameraRig.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript |
| `StarterCharacterScripts/InjuryFX.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `InjuryFX` | LocalScript |
| `StarterCharacterScripts/HUD.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `HUD` | LocalScript |
| `Tools/<Weapon>/Config.lua`, `Server.server.lua`, `Client.client.lua` | `ServerStorage` → `Weapons` → each Tool (26 weapons: Shortsword, Pitchfork, Greatsword, Hammer, ArmingSword, Dagger, Longsword, Mace, Cleaver, Falchion, BattleAxe, MorningStar, Halberd, Messer, Maul, Billhook, Estoc, Rapier, Glaive, Poleaxe, Bardiche, Zweihander, Executioner, WarAxe, Spear, Quarterstaff) | ModuleScript, Script, LocalScript |
| `Tools/Pitchfork/Config.lua` | inside the Tool → `Config` | ModuleScript |
| `Tools/Pitchfork/Server.server.lua` | inside the Tool → `Server` | Script |
| `Tools/Pitchfork/Client.client.lua` | inside the Tool → `Client` | LocalScript |
| `Tools/Greatsword/Config.lua` | inside the Greatsword Tool → `Config` | ModuleScript |
| `Tools/Greatsword/Server.server.lua` | inside the Tool → `Server` | Script |
| `Tools/Greatsword/Client.client.lua` | inside the Tool → `Client` | LocalScript |
| `Tools/Hammer/Config.lua` | inside the Hammer Tool → `Config` | ModuleScript |
| `Tools/Hammer/Server.server.lua` | inside the Tool → `Server` | Script |
| `Tools/Hammer/Client.client.lua` | inside the Tool → `Client` | LocalScript |
| `Tools/Shortsword/Config.lua` | inside the Shortsword Tool → `Config` | ModuleScript |
| `Tools/Shortsword/Server.server.lua` | inside the Tool → `Server` | Script |
| `Tools/Shortsword/Client.client.lua` | inside the Tool → `Client` | LocalScript |

Nothing gets inserted into a Tool automatically — create `Config`, `Server` and `Client`
inside each weapon by hand. `CombatServer` / `CombatClient` live once, in the folders above.
Note `RigReplicator`, `LoadoutMenu`, `HubMenu` and `Scoreboard` go in **StarterPlayerScripts**
(not StarterCharacterScripts): they must survive your respawns. The old `RoundServer` is gone —
delete it; `Game/GameServer` replaced it.

**Weapons now live in `ServerStorage` → `Weapons` (Folder)**, not StarterPack. The loadout
menu clones the chosen one into your Backpack when you spawn. Empty StarterPack, or
you'll spawn with two.

## A newcomer's first minutes

**Key art** (ReplicatedFirst ▸ KeyArt, a Studio-only StringValue holding the image: a generated
painting of the two armies, trebuchets and a battle-mage) sits behind the loading screen (faded in
once it has loaded) and the travel screen, darkened round the middle so the words read. Both screens
layer globally: the art is at ZIndex 1 over their backdrop, the words and bars above it.

A brand-new player (profile `tutorial` 0; the player attribute `Tutorial` mirrors it) never sees
a menu first. The game's name and line are `GameConfig.GAME_NAME` / `TAGLINE` (**Steel & Glory**).
0. **Loading** (`ReplicatedFirst ▸ Loading`): from the very first frame, the game's name on a dark
   field with embers and a sweeping bar (never Roblox's blank screen) until there's something to
   show — the welcome film (`_G.IntroCinematic`), a menu or a body. Arriving by teleport, the
   travel screen you left on stays up instead (`_G.ArrivingTravelGui`) until you have a body or
   the class screen (`TravelScreen`).
1. **THE SIEGE OF STORMWATCH** (the Prologue, below): a newcomer goes straight from the loading
   screen into a battle of their own (`Intro` asks `HubServer`'s `"Intro"` op for `Train`, which is
   the Prologue now) and learns to fight in the middle of it. When it ends (or they skip it) they
   are at tutorial 2 and in the Courtyard, where the menu tour (5) follows. Steps 1 to 4 below are
   the older path, still there if the Prologue is ever missing (`GameConfig.DOORS.Prologue`).

   **The old welcome** (`Intro`): a ~12 s cinematic over the Courtyard (letterbox bars sliding in,
   embers, the map's own camera shots as slow dollies with a line each, then the name slamming
   down with a flash, a shake, a horn and a boom; any key skips),
   to its own score (`MusicConfig` `Intro`). Then the card: **WELCOME, SOLDIER!** with **BEGIN
   TRAINING** (recommended; Enter) or **SKIP TO BATTLE**, which asks *ARE YOU SURE?* first. The
   answer goes to `HubServer` (`"Intro"` op) and the travel screen comes up at once. While it runs
   the menu stays shut and its camera holds off (`_G.IntroActive` / `_G.IntroCamera`). If the
   welcome ever fails it lets go of the screen at once (the menu and the trip carry on); a client
   that never shows the card is sent to training after 30 s.
2. **Basic training** (a Tiltyard server of their own): they spawn at once as a **Knight with a
   Greatsword** (`GameConfig.DEFAULT_CLASS`; no class screen: `LoadoutServer` spawns anyone with
   tutorial < 2) and walk a fourteen-step course (`Catalog ▸ Drills`, `basic = true`: every move
   Sir Aldric teaches): **Find Your Feet** first (a checklist of the camera, sprint, crouch, hop,
   dodge and freeing the mouse, in their own binds, ticking as they press each), then swing, stab,
   overhead, both sides, block, parry, riposte, feint, morph, kick, footwork (dodges), the chamber,
   and a Squire in the ring. For each step they're **placed right in front of its dummy, facing it**
   (`Training`, `FaceYaw` / `FaceTick` turn the camera with them). The lesson dummies' blows are
   **harmless** (attribute `Harmless`). The card up top says STEP n / 14; **SKIP TRAINING · M**: the
   button, or the menu key (a newcomer may not know how to free the mouse yet), asks *SKIP
   TRAINING?* first (`_G.MenuKeyOverride`).
3. **Trained (or skipped): tutorial 1, straight into a battle** (`_G.HubTravel` → a Warfront
   server with room in Team Deathmatch, Free-for-All or King of the Hill, never a siege first; or
   a new Team Deathmatch). Bots fill it, and a server with a newcomer in it fields only Squires.
   `Intro` shows a briefing card as they arrive and a few tips, once each, as things happen: the
   first wound (block / parry), running out of breath, the first kill (FIRST KILL!), the first fall.
4. **The first battle's round ends: tutorial 2.** The travel screen comes up **at once** with how
   it went (FIRST BATTLE COMPLETE · kills · deaths · Marks · XP) instead of the vote, and the trip
   to the Courtyard follows 5.5 s later.
5. **Back in the Courtyard** (`MenuTour`, profile `menuTour`): *WELCOME TO THE COURTYARD* offers a
   half-minute tour of the menu: a spotlight on PLAY, the dock (loadout, armory, shop, tasks,
   trade), the wallet, friends and **Settings (every key rebinds there)**, then the menu key. Either
   way the **recruit's gift** follows once (`Catalog ▸ Economy ▸ starterGift`: 500 Marks and a Key)
   with **OPEN A CRATE**, straight to the crates. (Studio: the player attribute `TourAutoplay`
   clicks through the tour for a test.)

### The Siege of Stormwatch (`Game ▸ Modes ▸ Prologue`, `Game ▸ StormwatchMap`, `Prologue.client`, `ReplicatedStorage ▸ WarFX`, `WarCrowd`)
A dark, stormy night; the Iron Host is at Stormwatch's gate, and you are a soldier of its garrison.
A server of your own (`DOORS.Prologue`, `MODES.Prologue`: hidden, ownSpawn, one map built fresh).
- **The castle** (`StormwatchMap.build`): curtain walls with crenels and a breach in the east wall,
  a gatehouse of two towers and an oak-and-iron gate (its own `Gate` model, which bursts apart),
  corner towers (one burning), the keep, the barracks, an armoury of racks, a burning smithy,
  stables, stakes, braziers, banners, puddles, spent arrows in the cobbles; outside, a field of mud,
  the Host's tents and fires, rank on rank of torches, their trebuchets (ServerStorage ▸
  PrologueProps ▸ Trebuchet, a generated model; a timber one is built if it's missing), the ram
  under its hide roof, ladders on the walls, hills on the horizon. The story's places are map
  attributes `P_<name>` (wake, armory, raiders, breach, gate, ram, yard, army…), the trebuchets'
  throwing arms `T_1…`. Night and storm lighting, heavy atmosphere.
- **The story** (`Prologue.STEPS`): a cutscene (the storm, the Host, a tower hit, Captain Hale
  wakes you) → run to the armoury → raiders over the wall (swing, stab, overhead on a staggering
  raider) → the trebuchets find the yard (a red ring under you: dodge out of it, or take the blast)
  → a raider through the breach (block, parry, riposte: his blows teach, `Harmless`) → a brute
  behind his guard (kick, then cut him down) → run for the gatehouse through falling arrows →
  cutscene: the ram, the gate bursts, the Host pours in → hold the gate beside the garrison (six
  of the Host) → cutscene: **Lord Varg** → the duel (a boss bar; every fall weakens him) →
  cutscene: dawn, horns, the King's riders, **STORMWATCH STANDS**. Before the battle you can't
  fall (30 % health always left); in it you come back at the gatehouse.
- **The Host and the garrison** (`Prologue.client`, `ReplicatedStorage ▸ WarCrowd`): the Iron Host
  drawn up in the field among its torches (two blocks of foot, pikes, knights behind, archers
  before), the garrison's archers along the north walls; the garrison's volleys cut men down in
  the Host's lines and the Host's archers loose back over the wall; its war cries; the Host closes
  on the gate as the night goes on (the gatehouse, the hold, the champion), and at dawn it turns
  and runs into the dark while the walls cheer.
- **On your screen** (`Prologue.client`): the lesson card (STEP n / 13, what to do in your own
  controls, a progress bar, a tick when done), Captain Hale's lines, a beacon of light over where to
  go with an arrow at the screen's edge, the cutscenes (black bars, a flying camera, subtitles,
  title cards; SPACE / ENTER / tap / Ⓐ skips one), M: RESUME / SKIP THE TUTORIAL (asked once),
  and the end card (the welcome purse, `Catalog ▸ Economy ▸ prologue`: 300 Marks and 250 XP once,
  TO THE COURTYARD). The siege plays its own score (`_G.OwnScore` quiets Music), cutscenes hide the
  hotbar (`_G.CinematicUp`), and its own top (`OwnTop`) hides the scoreboard's strip.
- **The war all round** (`ReplicatedStorage ▸ WarFX`, client only, nothing replicated): rain round
  the camera (gone under a roof), lightning with thunder a moment later, heavy cloud; the
  garrison's volleys off the walls and the Host's answering ones arcing into the yard and sticking
  in the cobbles; trebuchet fire on high arcs and its blasts (flash, fire, smoke, flying stones, a
  scorch, a shake by distance); war cries from the camp. Arrows are pooled and moved in bulk.
- **Sounds** live in ReplicatedStorage ▸ WarAudio (Studio-only; generated): Thunder, Rain,
  Battle, Impact, Incoming, Arrows, Horn, Gate, Charge, Music. Anything missing is just quiet.

Someone with no body (the menu, the intro) still sees the map: `GameServer` points their
`ReplicationFocus` at the map's middle (`MapLoader.focus`), and the map carries its camera shots,
middle and size as attributes (`Shot1…`, `Centre`, `Radius`) for scripts that need them before its
parts have streamed in.

Anyone who played before (level above 1, or asked about training already) starts at 2. Studio
can't load saved profiles, so there every Play counts as a returning player unless
`GameConfig.STUDIO_NEWCOMER` is true (test the path with it on).

Every class now starts with its own pair of free weapons (`GameConfig.CLASSES` primary /
secondary): **Knight** Greatsword + War Hammer, **Footman** Spear + Shortsword, **Vanguard**
Arming Sword + Shortsword. Older saves whose class still had the lone default Shortsword get the
pair (profile `loadoutV`).

## Leaderboards, the season, profiles, privacy

**LEADERBOARDS** (menu: the **RANKS** tile in the dock, the lobby board's **VIEW ALL** / **FULL
LEADERBOARD · TOP 100**, the LEADERBOARDS button on your own profile; the screen `RANKS`):
the Warfront (kills this season) and the three ranked brackets (rating), top 100 each
(`HubRemote "Board"` → `Leaderboards.top(which, 100)`). It shows where you stand (or "not in the
top 100 yet", with your value), a search over the top 100 by name, and the season: its name, the
time left, and every reward line (yours lit up). It says up front that **tapping anyone opens
their profile**, and every row ends in "›". **Profiles**: tap a name on a board, your own card
(top left: pointing at it says VIEW PROFILE), PROFILE beside someone in PLAYERS HERE, or look at
a player and press the Profile key (P) — their name tag shows **[P] PROFILE** when you're looking
straight at them (a keyboard). Your own profile has **CHANGE TITLE** and **LEADERBOARDS**.

**Season rewards** (`Catalog ▸ Economy ▸ seasonRewards`; `Economy ▸ Season`): when the season ends
(00:00 UTC on `Catalog ▸ Pass` `ends`), one server takes the payout job (a lease in `Season_v1`),
reads the boards (Warfront to 1000, each bracket to 100) and writes each rewarded player's line
into `SeasonGrants_v1`; the player is paid (`Economy.grantReward`) and told the next time they
join. The ranked tier you finished in (best bracket, placements done) pays once on your first
join after the end. Boards are per season: `Leaderboards.key(which)` is `LB_<which>` in Season 1,
`LB_<season>_<which>` after; the Warfront value is `Leaderboards.seasonKills` (kills since the
season began).

**PROFILE** (`HubRemote "PlayerProfile"`, here or offline from their saved profile): headshot,
name, level, title, whether they're here; their record (kills, deaths, K/D, rounds, wins, win
rate, parries, season kills and place); their ranked tiers; **each class dressed as they wear
it**; their collection (counts and finest skins). Buttons: **TRADE** (here), **INVITE TO PARTY**,
**ADD FRIEND** (Roblox's friend request; FRIENDS ✓ when you are). Ways in: any leaderboard row,
PLAYERS HERE (the lobby's invite list: PROFILE on each), and in the world, **look at someone and
press P** (`Profile` bind).

**Privacy** (SETTINGS): *Party invites from* and *Trade requests from*: Everyone, Friends,
Nobody (`ClientSettings.PRIVACY`). SettingsServer puts them on the player (`Priv_PartyInvites`,
`Priv_TradeRequests`); HubServer's invites (here and from other servers) and `Trading.request`
refuse what they don't allow.

## Custom servers: bots and the host's panel (`Hub ▸ HostServer`)

Making a custom server (SERVERS → CREATE) also sets its **bots**: on/off, how many fighters in all
(players + bots, 2–24), their skill (Mixed, Squire, Knight, Champion), in `GameConfig.CUSTOM_DEFAULTS`
and checked by `HubServer.cleanSettings`. BotFill fills a custom server by those (never a ranked one).
A fixed map (`settings.map`) is honoured; "weapons on the ground" off means a dropped weapon falls but
can't be picked up and goes in 4 s (Round `GroundWeapons`, `Pickup.drop`).

**The host** (who made it; if they leave, whoever has been there longest; Round `HostId`) gets a
**YOUR SERVER** card in the lobby and a **SERVER PANEL**. Everything is decided by `HostServer`
(`HostRemote`), only for the host:
- **Players:** each one's team and K/D; **KICK** (with a confirm; kept out while the server runs),
  **MAKE HOST**.
- **Bots:** fill on/off, how many, what skill (live); **practice bots** where you stand (+1, +3,
  pick their skill; 12 at most; they fight everyone) and **CLEAR**.
- **The round:** next mode (this server's door's modes), next map (that mode's maps), **END ROUND NOW**.
- **Rules (live):** friendly fire, respawns, weapons on the ground, round length (next round),
  player limit, who can join.

## Bot fill (`Game ▸ BotFill`)

A Warfront match is never empty: while a round runs, bots make up the numbers to the mode's
`botFill` (players + bots on the field; half a side in team modes): FFA 8, Duel 4, TDM 12, LTS 8,
KOTH 10, Siege 12. A player who joins takes a bot's place (the one farthest from any player
leaves); a fallen bot's place fills again after 5 s (Last Team Standing: one life a round, bots
too, all in at the start). Skills: 60% Squire, 33% Knight, 7% Champion (Squires only with a
newcomer on the server). One in seven fights as an **Archer** and one in ten as a **Mage**
(`CLASS_MIX`; never against a newcomer): `Combat ▸ Bots` `opts.class`. An archer bot keeps its
distance, draws (a good one to the full), leads you and looses — a Champion goes for the head — and,
caught close, draws the sword on its hip and goes back to the bow at range. A mage bot, in robes
for its rank, keeps back and casts what fits (Mend when hurt, Frost Nova up close, lightning, a
meteor, fire), holds a spell charged until it has you, wards a blow coming in and meditates when
nobody's near. Both work the weapon through its controller's `npc()` (RangedServer, MagicServer),
by the players' rules. Horde sends archers from wave 3 and mages from wave 5. Studio:
`/bot <rank> Archer` · `/bot <rank> Mage` (chat); the admin panel's bots take a `class`. Bots carry a team (`Team`, tabard, team colours) and the attribute
`FillBot`. Never more than the map suits (`GameConfig.MAP_FIGHTERS`: Rose Court 6, the arenas
12, Sandpit 16, Highbridge 20, the baileys and bridges 24, the open fields 32, the sieges 40);
the map vote offers maps sized to who's there and the bots the mode brings, and a public
server's room shrinks to its map's most. (Horde skips the size rule: the horde is its own crowd,
so all its maps take turns. Each vote offers three maps the last one didn't.)
- They fight **everyone not on their side**, players and bots (`Bots.spawn{fightBots = true}`),
  and with nobody within ~38 studs they **head for the objective** (`goal`: Round `ObjPos`, the
  hill or the ram). Long trips use **pathfinding** (`Bot:pathDir`, PathfindingService, worked out
  again every few seconds), so spawn rooms and walls don't trap them.
- They **count**: a fallen bot costs its side a TDM ticket and gives its killer the kill
  (`Game.onBotDeath`); they stand on KOTH's hill and push or block Siege's ram
  (`Teams.fighters`); Last Team Standing counts them alive (`Teams.botsAlive`, `Game.fielded`).
- A kill on a bot pays like a kill for the round, but stays off the lifetime kill count and the
  season leaderboard. Not on custom servers, ranked (The Lists), Horde or the hubs.
- **On the board (Tab):** every bot holds a **seat** (`ReplicatedStorage ▸ BotScores ▸ <id>`, a
  Configuration: `Name`, `Team`, `Kills`, `Deaths`), listed with the players, tagged BOT, sorted
  and team-coloured like them. A fallen bot comes back in its own seat (same name, same score);
  the seat goes when a player takes the place. Seats stay through the intermission and clear at
  the next round. Scoreboard counts them: bots carry `BotSeat`, a hit stamps `LastHitBySeat`.
- **A bot's blade passes through the bots on its own side** (`CombatServer.botFriends`: swings
  and kicks), so a crowd of them fights the other side instead of cutting each other down.
  Players keep friendly fire, and a bot won't swing while a player on its side stands in the
  arc (`friendInTheWay`).

## Touch screens (phones, tablets)

On a touch screen with no keyboard, `TouchControls` puts the fight under the right thumb, few
buttons, out of the fight's way:
- **ATTACK** (big, in the corner): a tap swings (the sides take turns); a **swipe** from it picks
  the blow: ↑ overhead, ↓ stab, ← → a swing from that side (arrows round it light up). A bow or a
  crossbow: held to draw, let go to loose. A staff: held to cast, swiped ↑ ↓ for the spell.
- **BLOCK** (held) beside it, **DODGE**, **KICK** (it turns into **FEINT** while your own swing is
  coming; with a staff, **MEDITATE**), **LOCK**, and the **POWER** and **THROW** orbs in the arc
  (Powers.client moves them into TouchControls' PowerSlot / ThrowSlot).
- **SPRINT** (on until you stop) and **JUMP** above Roblox's movement stick.
- **MENU** and **⋯** top left (⋯: EMOTE, VIEW, CROUCH, SCORES, and STAFF ⇄ with a staff); the gift
  chip beside them.
- The health and energy bars move to the top, smaller; the weapon chip's key hints hide.
- A drag on open screen (right of the stick) turns the camera (SETTINGS ▸ Touch look speed).
- **LOCK-ON** (`ReplicatedStorage ▸ LockOn`, `LockOn.client`): LOCK locks onto the foe nearest the
  middle of your view; your camera and body keep them in front of you (CameraRig, under the
  swing's turn cap); a red reticle marks them; a swipe across the screen moves the lock to the next
  foe. It lets go when they fall, hide or get away. **AIM ASSIST** (SETTINGS ▸ Aim assist, on by
  default; touch and controllers only): as you attack, the foe close in front of you draws your aim
  a little. Anyone can lock on: middle mouse (rebindable), a controller's right-stick click.
- **Sizes** (`ReplicatedStorage ▸ Device`): every game screen is drawn smaller on a phone (`UIFit`
  puts a UIScale on each ScreenGui: Device.hudScale), the buttons by Device.touchScale ×
  SETTINGS ▸ Touch button size; the class picker gives its fighters the room on a phone; the
  third-person camera sits a little further back on a phone.

Buttons go through `ReplicatedStorage ▸ TouchInput` (the action bus), so each does exactly what its
key does. Roblox's own jump button is hidden.

**The menu on a phone** (`HubMenu`, `LAYOUT.compact`: a screen under 560 px tall). The design
canvas shrinks to 1300×600 (everything is drawn bigger), text of 16 and under is 1.22× larger,
the lobby rearranges (the dock in two columns down the left, PLAY bottom right, the leaderboard
and today's shop above it, no tasks panel: they're behind TASKS), screens keep their full height
and scroll (a **▼ MORE BELOW** chip until you do), screens that scroll inside themselves (the egg
shop, the inventory, the crate gallery) fit the screen instead (`HX.fitScreen`), and pop-ups shrink
until they fit. To look at it in Studio: set the attribute `PhoneSim = true` on ReplicatedStorage
before pressing Play: the menu letterboxes to a phone's 19.5:9 and everything else (Device) treats
this client as a phone 390 points tall, the touch controls on — **and clear it before saving**.

## Controllers (Xbox, PlayStation)

`StarterPlayerScripts ▸ GamepadControls` sends a controller's buttons down the same action bus,
so the fight code needs nothing of its own. The layout lives in `InputHints.PAD`:

| Button | Does |
|---|---|
| RT / R2 | swing — aim it with the right stick: ← → a side, ↑ overhead, ↓ underhand; centred, the sides alternate |
| RB / R1 · LB / L1 | stab · overhead |
| LT / L2 | block (hold; a bow's let-down, a crossbow's aim) |
| A / ✕ · B / ○ | jump · dodge |
| X / □ · Y / △ | kick (or pick up, when a prompt shows) · feint |
| LS click | sprint (on until you stop) |
| RS click | tap: **lock on** (flick the right stick to move to the next foe) · hold: first / third person |
| D-pad ↑ | tap: your power · hold: the emote wheel (aim with the right stick, let go) |
| D-pad ↓ | tap: crouch (toggle) · hold: aim your throwable, let go to throw |
| D-pad ← → | weapons |
| VIEW / TOUCHPAD | tap: the menu · hold: the scoreboard |
| right stick | look (SETTINGS ▸ Controller look speed) |

Anywhere the game frees the mouse (the menu, the class screen, the vote, a pop-up), Roblox's
virtual cursor turns on: the left stick moves it, A clicks. In the menu **B goes back** (a pop-up,
then a screen, then the menu) and **LB / RB step through its screens** (`_G.HubMenuCycle`). Aim
assist and lock-on as on a touch screen (above). On a TV (Roblox's ten-foot interface) every game
screen is drawn a little bigger (Device.hudScale). Every hint on screen asks
`ReplicatedStorage ▸ InputHints` what to call a control: your key bind, the controller's button
(Xbox letters or PlayStation shapes) or the touch button, and it switches the moment you pick
up a different device (the tutorial, the intro's tips, the travel screen's tips, the menu tour,
the emote wheel).

## The Archer, bows and crossbows (`Combat ▸ RangedServer`, `Combat ▸ RangedClient`)

The **Archer** (`GameConfig.CLASSES.Archer`, `ranged = true`) carries a **bow or a crossbow** as
the primary and a **one-handed sidearm** as the secondary: no big weapons (`Catalog.weaponFits`
decides every slot, for every class, in the menu and on the server). The lightest of all: Light
pieces, then **85 health, no armor protection, 4% faster** (`health` / `prot` / `speed` on the
class, applied by `LoadoutServer`).

**The longbow** (free) is held in the right hand; the left draws the string. **Hold** the Swing bind (left mouse) to draw: 1.6 s
to full, walking at 20% and no sprinting. **Let go** to loose; let go before 40% of the draw and
the string is let down, no shot. The power is the draw the **server** timed: a part draw is weak
and arcs high; a full draw flies at 180 studs/s (about 800 studs at the longest lob). **The arrow lands on the point under the
reticle** at any range it can reach: it's loosed on the arc that carries it there at its speed (`Ballistics`: the client sends
the point, the server solves with the speed it timed; out of reach, the 45° lob that carries furthest; aimed at the sky, it flies
along the look). The aim always wanders a little,
more while you're pulling; held at full draw past 0.6 s it costs stamina and shakes more and more (more on the move or winded, less crouched); out of breath, the draw drops.
After a shot the archer **nocks the next arrow** (1.5 s: the hand goes back to the quiver). Right
mouse lets a draw down. A shot every ~3.5 s at best.

**The crossbow** (level 3) is carried at ease in both hands, low across the body. **Hold right mouse**
to raise it to the shoulder (it follows where you look, and the view zooms down the tiller);
**click** looses it, only while raised (steady aim, 160 studs/s, a hard hit, more armor pierce; it lands under the reticle too).
Then it stays **empty until you span it**: the **Reload** bind (R), or a click while empty, starts
a **5 s haul** at 8% walking speed: bent over, the nose down in the stirrup at your right foot,
pulling the string up in three strokes (everyone sees the string follow: Round `ReloadAt`).

**Arrows are the server's**: stepped raycasts with gravity decide what they hit. Damage × power ×
region (a full-draw bow 30 to the body, **head ×2**: 60, never a one-shot; a bolt 42, 84 to the head;
legs ×0.7, arms ×0.8), less the struck limb's armor (pierce against its
class, the weapon's `ARMOR_PEN`). A hit flinches and interrupts like a blade (and breaks a draw);
credit `arrow` / `headshot` ("shot", "shot through the head"). **A raised guard facing the arrow
blocks it** (a parry takes nothing, a block some stamina). Arrows **stick** where they land: in
bodies (welded, they fall with the body) and the world (20 s). Quiver: 16 arrows / 14 bolts, one
back every 6 / 8 s, full every life. Kick works with a bow in hand.

What everyone sees (`RangedFX`): arrows in flight (`ArrowFlight`; your own fly the moment you
loose), every bow's **string drawn back to the hand with an arrow on it**, a crossbow's string at
the nut while spanned and the bolt in its groove. The **stances** are `RigPose.ranged` (inputs
`ranged`, `aim`, `draw`, `reload`, relayed like the rest of the pose).
- **At the ready** (not drawing, `BOW_READY`): the bow low and slanted across the body in the
  right hand, the left hand across on the string.
- **Drawing:** the body turns side-on (`BOW_TWIST`, further as it comes back: `BOW_TWIST_DRAW`),
  the bow arm straight out at the target, the left hand pulling back along the arrow. With the
  bow in the right hand the body turns *off* the over-the-shoulder camera's line, so nothing
  crosses the view.
- **Nocking:** the left hand reaches back to the quiver.
- **Crossbow** (`XBOW`): at ease low across the body; raised to the shoulder, a little side-on, the
  left hand under the stock; spanning bent over the stirrup, the back straightening with each pull.
- **Roblox's own arm animations are taken off the shoulders** while a bow or crossbow is in hand
  (`RangedFX`, every client): no "holding a tool" arm stuck straight out, and no jolt as the walk
  animation starts and stops.
- **In first person** with a bow up, the string arm is hidden and the bow arm stays out in front;
  with a crossbow, both arms are hidden (`CameraRig`).

**Sounds.**
- The draw creaks as the bow bends.
- The release is a low string thump plus a short whoosh, both louder the fuller the draw.
- The crossbow gives a click plus a whoosh.
- What an arrow lands in sounds like itself (`SoundBank.WALL` by material): stone and metal
  ring, wood thunks, earth thuds; flesh gets a stab.
- Someone else's arrow passing within 9 studs of your camera **whizzes by** (`ArrowFlight`;
  louder the closer, once per arrow).

**Skins and arrow effects.** Every bow and crossbow skin changes the silhouette with a ranged trim
(`SkinTrims` `RT`, fitted to the limbs and the prod: flame tongues, horn curls, thorns, crystal
clusters, wings, ice spikes, a skull, gilded caps, storm zig-zags, obsidian shards, a dragon's
ridge). Its arrows (`ArrowFX`) wear a two-layer trail, particles and a light in flight, the kind's
own touch (a halo, a flicker, smoke, wisps), land with the kind's own impact (a fire that keeps
burning, ice shards, a lightning bolt from the sky, a pillar of light, an implosion, a splash, a
lingering cloud, a fountain of gold, rising spirits) and have their own release and impact sounds
(`ArrowFX.sound`, played by RangedServer). Bows and crossbows have their own section in the Armory
(**RANGED · ARCHER**) and skins like any weapon. The Epics and Legendaries change the arrows
(`arrow = "<kind>"` → `ArrowFX`): fire, frost, shadow, holy, storm, venom, gilded, blood — a trail,
a glowing head, particles, a light, a burst where it lands, a smoulder where it sticks. The Tool
carries `Skin` and `ArrowFx` attributes (`LoadoutServer`); the server passes the kind with every
"Shot" so everyone sees it. Most roll from the **Fletcher's Crate** (in the daily rotation); Venomstring,
Heartseeker and Glacier are earned by kills; Stormcaller and Thunderbolt come from the Royal crate;
the Gilded Longbow is on the shelf. The reticle shows the shake and closes as you draw; full
draw zooms a little. On a touch screen, hold a SWING button to draw, BLOCK lets down. Bows hang
across the back when not in hand (`Holsters`: every weapon you carry is on you from the moment you
spawn; the script watches every Backpack the player is given, since a respawn hands out a new one
after the body arrives). Tuning: each Tool's `Config` over
`RangedServer.DEFAULTS` / `RangedClient.DEFAULTS`.

## The Mage: staffs, grimoires, wands, an arsenal of spells (`Combat ▸ MagicServer`, `Combat ▸ MagicClient`, `MagicSpells`)

The **Mage** (`GameConfig.CLASSES.Mage`, `magic = true`, opens at **level 5** with the Archer:
`unlock`): 65 health, no protection, robes (the free **Apprentice Robes**: the class's `starter`
set), and no blade: the only sidearm a magic class carries is a wand (`Catalog.weaponFits`), and
the staff's melee self is all its steel. A **mana bar** (100) sits over the
spell bar, and **mana comes back only by meditating**: hold **R** (a controller's **Y**, the
touch FEINT) standing still; after 0.7 s it returns 16 a second; moving, casting, warding or a
hit ends it (`Meditating`, `MagicSpells.MEDITATE`). A Mage fights from behind the line, then has
to stop.

**The weapons** (Tools ▸ <id> ▸ Config; a magic weapon only for a magic class, and a magic
class carries one: `Catalog.weaponFits`):

| Weapon | Slot | Spells | Power | Casts | Mana | While casting | Also |
|---|---|---|---|---|---|---|---|
| Arcane Staff (free) | primary | 4 | 100% | normal | normal | 20% walk | the **Ward** (right mouse), a **melee self** (H) |
| Grimoire (level 6) | primary | 5 | 85% | 25% faster | 20% cheaper | 35% walk | nothing between you and a sword |
| Wand (free) | sidearm | 2 wand spells | | quick | a sip | 70% walk | for when you're low and they're close |

**The staff's melee self** (`Tools ▸ StaffMelee`, the Tool's `Twin`): the Stance bind (**H**,
D-pad ←) swaps it in (`LoadoutServer`: StanceSwap) and it fights with every quarterstaff swing,
its clips and rules (CombatClient / CombatServer), lighter. Only the one in your hand is on the
weapon bar (`TwinHidden`).

**The arsenal** (LOADOUT ▸ SPELLS: the Tool's `Spells` attribute, `Profile.validateLoadout`):
as many spells as the weapon carries, from every spell you have. **The wand's own** (LOADOUT ▸
SPELLS ▸ WAND, the loadout's `wandSpells`; `wand = true` spells, which nothing else carries): two of
Spark (free) · Mote (free: a homing wisp) · Ember (6: a flick of fire, a burn) · Frost Dart (8: a
slowing sliver) · Zap (10: short lightning) · Gust (12: wind that throws everyone close away, a
held push). Each costs 3–10 mana and comes off the wand in a moment.

| Spell | Unlock | Mana | Cast | Cooldown | What it does |
|---|---|---|---|---|---|
| Firebolt | free | 20 | 0.7 | 1.1 | a dodgeable bolt: 15, burns 2/s for 3 s, splashes 4 |
| Ice Lance | level 2 | 16 | 0.5 | 1.3 | a fast shard: 10, slows 30% for 1.5 s |
| Chain Lightning | free | 30 | 0.85 | 5 | 12 to the aimed, leaps for 7 |
| Arcane Missiles | level 4 | 24 | 0.8 | 3.5 | three curving bolts of 6 |
| Meteor | level 8 | 45 | 1.5 | 16 | lands where you aim after 1.1 s: 30 in the middle, 12 at the edge, a shove |
| Miasma | level 6 | 32 | 0.9 | 11 | a cloud where you aim: 3/s and a slow for 5 s |
| Frost Nova | free | 35 | 0.4 | 10 | 6 round you and a heavy slow |
| Mend | free | 40 | 1.1 | 12 | 25 over 2 s, you or the ally aimed at |
| Haste | level 3 | 20 | 0.5 | 14 | a quarter faster for 6 s, you or an ally |
| Barrier | level 7 | 30 | 0.6 | 16 | a shell that soaks 25 for 6 s, you or an ally |
| Hex | level 9 | 26 | 0.75 | 13 | the cursed deal a quarter less and take 15% more for 5 s |
| Blink | level 10 | 25 | 0.2 | 10 | 18 studs where you look, stopping short of walls |

**Casting** (Swing; scroll / RB-LB picks; Q / Y cancels): **hold** to wind it up (the server
times it: `Casting`, `CastStart`, `CastTime`); at full it **holds there, charged** (`CastReady`)
until you **let go** ("Release"), and only then goes off and is paid for; a quick tap goes off the
moment it's ready. You walk at a crawl and can't sprint the whole time, and **a hit breaks it**
(the server tells your screen: "Cancelled"). The aim is the crosshair as you let go; the crosshair says what the spell wants (someone, the
ground, an ally, nothing) and turns red past its reach. **The Ward** (a staff, right mouse):
a blow from the front (within 75°) is **stopped outright**, like a block (the clang, sparks,
WARDED, the swing cancelled), paid half a mana a point of damage (`MagicSpells.WARD`); without
the mana it breaks and the rest gets through. It is asked before a head-stab finisher. The ward
shows a soft pane of light.
Every blow — blades, arrows, spells — asks `Combat ▸ Ward` (wards, **barriers** soak first,
**hexes** weaken the attacker and open the target).

**What everyone sees** (`ReplicatedStorage ▸ MagicFX`): the magic circle at the orb, bolts
(an orb, a lance of ice, wisps, a spark), lightning, a nova's ice, a heal's light, a meteor's
warning ring and its fall, a choking cloud, a barrier's shell, a hex's mark over the head, wind
at a hasted runner's heels, a blink's streak, a meditation's turning circle. **The stance**
(`RigPose.staff`, `ranged` 3 / 4 / 5): the staff planted on the ground, rising slowly as you
cast, ward or meditate and sinking when you stop; the grimoire open at your waist, lifted to
read from; the wand at your side, pointed to cast. Each screen holds a staff upright and a book
open in the hand (MagicFX: the grip's C0), and Roblox's own "holding a tool" arm is stopped
(MagicClient). With a magic weapon in hand the walk's lean and the step's bob are mostly let go
(`RigPose` MAGIC_STEADY), so what you hold doesn't wobble. Put away, the staff hangs down your
back, a grimoire at the hip, the wand at the right hip; a staff and its melee self are one weapon
on you (`Holsters`). Bots never play Mage.

**The Mage's weapon skins** (the Arcana Crate; Commons on the WEAPONS shelf): fourteen staffs
(Emberwood, Stormcaller, Bonecaller, Dragonbone, Voidstaff… the Mythic Staff of the Cosmos), ten
grimoires (Necronomicon, Book of Flames, Celestial Atlas… the Mythic Burning Book) and ten wands
(Phoenix Feather, Unicorn Hair, Thunderrod… the Mythic Starfall Wand). A skin colours the orb /
rune / crystal (`blade`), the wood or the cover (`grip`) and the brass and silver fittings
(`metal`, SkinPart "Metal": Dresser.applySkin), with an aura from Epic up.

**Spell skins** (`Catalog ▸ SpellSkins`, the **Arcana Crate**: always in the shop): a look for one
spell, never its numbers. One Mage's Firebolt is a ball of fire, another's a **dragon's head**
roaring across the field (Dragonfire), a phoenix, a burning skull, blue fire; lightning red and
forked, or golden with the sky striking whoever it touches (Godstrike); stars, moon-crescents,
crystal novas, halos, shadowsteps, a falling moon; the Mythic, **Wyrmfall**, dives a dragon of
violet fire out of the sky. Each is a copy of its own (`"spell:" .. id`: trade it, scrap it), worn
per spell in LOADOUT ▸ SPELLS ▸ LOOKS (the class's `spellSkins`, kept for a spell out of the
arsenal too), carried on the weapon (`SpellSkins` attribute) and passed with every spell's event,
so everyone sees it; the spell bar and crosshair take its colours. Menus show a still model of it
(`MagicFX.preview`) on cards, the crate page, inspect, inventory and trades.

## Magic for every class: a power and a throwable, shields, class levels

**Every class carries a POWER and a THROWABLE**, each on its own key, besides its weapons:
1 the primary · 2 a sidearm, or a **SHIELD** beside a one-handed primary (then a sidearm can ride
on 3). The loadout's `power` and `throwable` / `throwableSkin` (a loadout saved when the two
shared a third slot, `thirdKind` "power" / "throwable", is read into its own: Profile, Powers.equip,
the class screen); `thirdKind` is only the shield's sidearm now. New loadouts get the class's first
power and the free Throwing Knives.
- **POWER: E** (a controller's D-pad ↑ tap, a hold is still the emote wheel; on a phone, tap its
  orb): used at once, aimed at your crosshair (`Powers.client` → `PowerRemote` "Use" →
  `Combat ▸ Powers`).
- **THROW: hold C** (a controller: hold D-pad ↓, a tap still crouches; a phone: hold its orb):
  the arm draws back (`PowerPoses` AIM, on every screen) and you walk slower (SpeedMult_Throw);
  a dotted arc shows the flight the server will fly (the same `Ballistics.launch`), drawing out
  from the hand as the wind-up fills (`Catalog.throwWindup`: knives 0.3 s, axes and darts 0.4,
  bombs 0.45, the javelin 0.6), and a ring where it lands: a burst's own radius flat on the ground
  under it (a firebomb's pool, a smoke cloud), a small mark on whoever it hits. Gold when ready,
  the element's colour for a bomb or flask, red on a foe. Let go and it flies (once the wind-up
  is done); block (right mouse) puts it away; held 10 s it's put away. `PowerRemote` "ThrowAim" /
  "Throw" / "ThrowCancel" → `Throwing.aim / release / cancel`.
- Two orbs right of the energy bar, POWER and THROWABLE: symbols, cooldowns wiping down, the
  seconds, an enchantment's arrows, a throwable's charges. Powers work in battle and the Training
  Yard, not in the Courtyard.

**Powers** (`Catalog ▸ Powers`, config only; `Combat ▸ Powers` runs them): ten a class, each
opened by **class level** (1, 2, 4, 6, 8, 10, 13, 16, 19, 22 — the tenth an ultimate):
- KNIGHT · OATHS: Flameblade, Iron Skin, Shield of Faith, War Cry, Juggernaut, Holy Smite, Consecrate, Charge, Thunder Slam, **Avatar of War**
- FOOTMAN · GAMBITS: Quickstep, Second Wind, Windstep, Gale Lunge, Cyclone Edge, Mirage, Tailwind, Whirlwind, Skybound, **Tempest**
- VANGUARD · TRICKS: Venom Edge, Shadowstep, Smoke Veil, Bloodlust, Marked for Death, Phantom Blades, Vanish, Ambush, Shadow Chain, **Nightfall**
- ARCHER · ENCHANTMENTS: Flame / Frost Arrows, Storm Arrow, Volley, Blast Arrow, Hunter's Mark, Seeker Arrows, Vine Snare, Eagle Eye, **Rain of Arrows**
- MAGE · RITUALS: Arcane Familiar, Mana Surge, Time Warp, Mirror Image, Ward Dome, Spellsurge, Gravity Well, Levitate, Soul Siphon, **Starfall**

The kinds: **imbue** (the weapon burns, freezes, poisons, shocks, drinks, shoves: `Powers.onMelee`
from CombatServer's clean hit; **a guard stops the steel, not the magic**: on a block, a shield or
a knocked-away guard the power's own damage, its burn / venom / frost / hex / lightning, its heal
and a shove that staggers (Holy Smite, Cyclone Edge) all land; on a parry the magic lands at
half and nothing shoves; the sword's damage never gets through: `Powers.onGuarded`), **buff** (modifiers summed into SpeedMult_Power, TakenMult,
DealtMult, StaminaRegenMult, DodgeCostMult, DodgeCooldownMult, Unflinching, DrawMult,
CastMult_Power, ManaFree — Ward, the movement, CharacterSystems, MovementServer, RangedServer
and MagicServer read them; a barrier; an instant), **spell** (a Mage's kinds cast free by
`MagicServer.cast`: every power is registered in MagicSpells as `Pw_<id>`, `power = true`, so its
look and skins work like a spell's), **shout**, **dash**, **leap** (a slam where you land, or a
slow float), **zone** (at you or where you aim: heal, shield, burn, slow, pull, smoke that bots
can't see into, a dome, a rain of arrows), **summon** (a familiar that shoots), **stealth** (you
fade; bots lose you beyond 6 studs; a blow out of it ambushes: Ward), **arrows** (the next N
arrows: RangedServer `Powers.takeArrow` / `arrowHit` — fire, frost, storm, splits, bursts,
marks, homing, roots). A player's cooldowns outlive their body. Everyone sees it: imbue
flames on the blade (flaring up as it catches), auras, wings, familiars, ghostly stealth,
circles on the ground, an ultimate's shockwave and column of light (`PowerFX`), and an imbued
blow's burst where it lands (`Strike`: fire, frost shards, a gust, venom, a pillar of light; a
draining blow's life flowing back to the striker).

**On you while it lasts** (`ReplicatedStorage ▸ PowerAuras`, from the Aura / AuraUntil attributes):
every power that lasts shows on the body, with a glowing outline and tint in its colour (a
Highlight, a few at a time) seen at any distance. **Iron Skin**: granite plates grow over the
shoulders (spiked), chest, forearms and shins, boulders orbit you, and it all cracks off and
falls when it ends. **Juggernaut**: the same, darker, molten cracks glowing, burning rocks.
**Holy** (Shield of Faith, Eagle Eye): a golden halo, motes rising. **Wind** (Quickstep,
Windstep, Tailwind's allies): streaks from hands and feet, gusts. **Tempest**: wind and lightning
crawling over you. **Nightfall**: a shroud of dark smoke, burning violet eyes, the body darkened.
**Spellsurge**: runes orbiting the chest. **Avatar of War**: wings, a crown of light, embers.
**War Cry's allies**: embers rising from the feet, a red-gold pulse on the ground (its foes are
**cowed**: a red mark over the head, not frozen any more). **Second Wind**: green motes, breath
steaming. An archer's enchanted arrows make the bow glow while any are left.

**Gestures** (`ReplicatedStorage ▸ PowerPoses`): every power moves the body as it goes off —
the blade raised overhead as it ignites, a war cry's arms flung wide, a slam's blade driven into
the ground, a whirlwind's spin, a lunge, an archer reaching to the quiver, a mage's hand thrust
at the target, a throw's fling. They are procedural motions registered with `Emotes`
(`Emotes.define`, `gesture = true`), so every screen draws them on players and bots, the blade
turned in the hand; arms-only, short, they ride dashes and leaps, and an attack, a block or a
hit cuts them off. Imbues wind up 0.35 s (the blade goes up before it catches), ultimates
0.45 s. The combat clips are untouched.

**What powers do to a body** (`StatusFX.client`, every screen): **Burning** — flames pouring
off the whole body, embers, smoke, a flickering firelight and an orange tint; **Frosted** — the
feet locked in ice, crystals on the shins, forearms and shoulders, cold mist and steaming
breath, shattering off when it ends; **Poisoned** — green bubbles, drips and haze; **Snared** —
vines bursting from the ground round the legs; **DazedUntil** — stars round the head (a power's
stun, a shield bash); **ShockedUntil** — lightning crawling over the body (Storm Arrow, a shock
imbue). One tint Highlight per body, at most 10.

**Class levels** (`Catalog ▸ Mastery`): every XP you earn also goes to the class you're
fighting as (`Economy.addClassXP`, `p.classXP`), 250 XP to level 2, rising to 2,600 a level,
30 levels. Each level can open a power, a title (10 / 20 / 30: Oathsworn, Paladin,
Knight-Commander…), a mastery power skin (15, 25; bound) and a Key every 5. A banner says what
opened. The class screen shows the level, the bar and what's next.

**Shields** (`Catalog ▸ Arsenal` shields; `Combat ▸ Shields`): strapped to the LEFT ARM (welded to
it, against its armor, so it goes wherever the arm goes); blocking brings the arm across the chest
(`RigPose` SHIELD_RAISE / SHIELD_ACROSS) and the shield turns upright on it, just in front of you
(the weld's IdleC0 / BlockC0, in the arm's frame); the weapon keeps its guard (no block clip with a
shield, CombatClient). **Their skins are things of their own** (`Catalog ▸ ArsenalSkins`): a board
material and a rim material, arms raised and outlined (`Heraldry`), and ornaments built onto the
shield following its outline (`ReplicatedStorage ▸ ShieldDress`: studs, a gilded edge, a glowing
edge, a boss, a gem, a spike, thorns, wings, a crown, a sunburst behind it, horns, hanging
feathers, vines, runes, iron bands, ribbons, battlements, flames). Buckler, Targe, Round Shield,
Heater, Spiked Shield, Kite, Scutum, Tower Pavise, unlocked by level or bought with Marks like
any weapon. Worn on the left arm (a copy of the Tool's body), raised in front of you on every
screen while you block; a GuardHull in front of you is there to blades only while you block.
Each widens the guard (ShieldCone), cheapens blocks (ShieldBlock), changes the parry window
(ShieldParry), stops arrows, bolts and thrown things from the front (ShieldArrows:
RangedServer, MagicServer, Throwing ask `Shields.stops`), makes the kick a bash (ShieldBash /
ShieldStun), and the big ones slow you (SpeedMult_Shield). Not for the Archer or the Mage.
**A two-hander in hand slings it onto your back** (`Shields.sling`: a Zweihander picked up off
the floor, a looted polearm, a bow): it hangs there face out and does nothing (no shield block,
cone, bash or arrows: ShieldSlung) until a one-handed weapon is back in your hand, when it's back on
the arm.

**Throwables** (`Catalog ▸ Arsenal` throwables; `Combat ▸ Throwing`): Throwing Knives (free),
Throwing Axe, War Darts, Javelin (pierces armour), Firebomb, Frost Flask, Smoke Bomb,
Caltrops, Bolas (roots), Holy Water (heals your side). Charges come back one at a time;
flown on an arc by the server, drawn on every screen (`ThrowFX`); bursts are power zones.

**Bodies**: shields and throwables are Tools in ServerStorage ▸ Weapons (`Tools/<id>`, Config
only), their bodies from `Build ▸ ArsenalBlueprints`, so Blueprints builds them and their menu
displays like any weapon's. **Skins**: power skins are spell skins (`Catalog ▸ PowerSkins`,
appended to SpellSkins; the **Spellforge Crate**, Mythic *Seraph*); shield and throwable skins
are weapon skins (`Catalog ▸ ArsenalSkins`): the **Heraldry Crate** paints arms on shields
(`ReplicatedStorage ▸ Heraldry`: cross, saltire, chevron, pale, fess, bend, quarterly, bordure,
chief, sun, star, lion, tower; Mythic *Aegis of the First King*) and the **Quartermaster's
Crate** dresses throwables (Mythic *Phoenix Feathers*). All three are in the daily rotation
(4 of 11 a day).

## Classes that open later: the Archer and the Mage (level 5)

`GameConfig.CLASSES` `unlock = {level = 5}` (and `tutor`, the Training Yard track that teaches it):
before then the class can't be made active (`Profile.setActive`, HubServer `SetActive`), the class
screens veil it ("🔒 LEVEL 5"), the spawn falls back to the default class and a saved active class
that's locked resets on load. Reaching it in a fight: a toast at once (`Economy.addXP`); the next
time the menu opens, the **ARCHER & MAGE UNLOCKED!** pop-up (once: profile `unlockSeen`) with a
button for each class's teacher. Picking one you've never been taught offers its lessons once.
"Learn" travels to the Training Yard with `opts.track` (profile `trainTrack`, or
`_G.TrainingTrack` when you're already there) and you arrive dressed as the class on its first
lesson.

## Classes, pieces, the Dresser

`LoadoutServer` turns off `Players.CharacterAutoLoads`; nobody has a body until they pick a
**class** and press SPAWN. A class (`GameConfig.CLASSES`) is a **weight** — `Knight` = Heavy,
`Footman` = Medium, `Vanguard` = Light — and every piece of a weight gives the same stats
(`Catalog ▸ Weights`: health, speed, footstep weight, protection on covered limbs), so looks
never buy power. You save **one loadout per class**: a helmet, a top and a bottom of that
weight, four **color blocks** (Primary / Secondary / Accent / Metal — parts with attribute
`ColorSlot`; Primary turns team-colored in team modes), a primary weapon with a skin, an
optional secondary. `Profile.validateLoadout` is the only thing that decides what you may
wear (owned pieces, unlocked weapons, owned colors / skins); `Dresser.dress` puts it on —
on the server for real spawns and on the client for every menu mannequin, so what you see is
what spawns. Profiles are DataStore `Profiles_v2` (v1 saves migrate: armor set → its three
pieces). **Adding content is config only: see [CONTENT_GUIDE.md](CONTENT_GUIDE.md).**

**Saving is one server at a time** (`Profile`, the session lock): a profile is claimed as it loads
(UpdateAsync stamps `_lockJob` / `_lockAt`) and let go as its player leaves; a server finding it
claimed waits up to 14 s for the other to let go (it's saving them on their way over), then takes
it (a lock older than 200 s, its server dead, at once), and a save never writes over a profile
another server has taken (that session ends: the player is told). Every player is saved every 60 s
(which keeps their lock fresh) and on the way out; a closing server saves everyone at once.
**A load that fails never becomes a fresh profile saved over the real one:** the session is
unsafe (never saved) and the player is asked to rejoin (in Studio with its data stores off: a
fresh profile, unsaved, at once). A Crowns purchase is only reported granted once its save has
landed (`Profile.save` returns whether it did; the receipt id stops a double credit).

**Analytics** (`Economy ▸ Analytics`, AnalyticsService: Creator Dashboard ▸ Analytics): the
newcomer's funnel (Joined → Basic training begun → Ready for battle → First battle fought →
First crate opened → Level 2 → Level 5 → Level 10; each step once per player, profile `funnel`;
players from before it are counted past it), every Marks / Crowns / Keys source and sink (rounds,
level-ups, tasks, the ring, the Gauntlet, rewards, purchases; the shop, crates, the pass, the
exchange: `Economy.spend(…, why)`), and the custom events RoundPlayed (mode, won/lost, server
type), CrateOpened (crate, rarity, kind) and Trade.

**Badges** (`Economy ▸ Badges`): Welcome, Graduate, First Blood, First Victory, Bow and Staff
(level 5), Veteran (25), Champion Slayer, Iron Will (Gauntlet wave 10), Touched by Legend (a
Mythic), Beta Tester. Their ids live only in the place: `ServerStorage ▸ BadgeIds ▸ <key>`
IntValues (0 = not made yet: skipped). Earned ones are awarded on join too (`Badges.check`).

**The weights trade real things** (`Catalog ▸ Weights`; the class cards show HP / ARMOR / SPEED /
STAMINA bars and the full line under each class):
- **Light (Vanguard):** 100 HP, 3% armor, 106% walk speed, the fastest sprint (×1.55), 120 stamina
  coming back 30% faster, everything 10% cheaper, dodges that cost 70% and go 25% further. One
  mistake from death.
- **Medium (Footman):** 106 HP, 12% armor, 96% speed, ×1.45 sprint, 100 stamina: the all-rounder.
- **Heavy (Knight):** 112 HP, 22% armor on covered limbs, 87% speed, ×1.32 sprint, 75 stamina
  coming back 35% slower, **everything 20% dearer** (swings, feints, kicks, blocks, a held guard:
  `cost` → `StaminaCostMult`), dodges that cost 160% and go 20% shorter. It takes the hits, but
  a long exchange leaves it gasping: a Light that keeps moving and keeps the pressure on runs it dry.
  Blunt weapons and armor-piercing points ignore part of the armor (`ARMOR_PEN`, below).
Dresser publishes them as `StaminaMult`, `RegenMult`, `StaminaCostMult`, `SprintMult`, `DodgeCost`, `DodgeReach`;
CombatServer scales `BlockMax` / `StaminaRegen` (and rescales if you're re-dressed),
MovementServer the sprint and the dodge's cost, Movement the dodge's reach.

## Look (`Theme`)

Every screen reads its colors and fonts from `ReplicatedStorage ▸ Theme`: dark glass cards,
white text with a dark outline, chunky glossy buttons (green for the action you should press,
blue for what is selected, gold for Crowns, red to close or leave), FredokaOne headings. The
dock icons and currency marks are rendered 3D icons (`blender/ui_icons.py`, `blender/icons.py`)
kept as Decals in `Cosmetics ▸ Icons`. Change a value there and the Hub menu, class screen, scoreboard, travel
screen and HUD all follow.

## Hub menu (M)

`HubMenu` is the front door, built like a modern lobby: **M** anywhere (Escape belongs to
Roblox). It opens by itself when you have no body in the Courtyard, over the cinematic camera;
in a match M pauses with the same lobby (RESUME · LEAVE MATCH where PLAY was). M closes a
pop-up first, then a screen, then the menu. The whole layout is drawn once on a 1600×900 canvas
and a UIScale fits it to any screen.

- **LOBBY**: your party stands on glowing platforms in the middle. You are up front; teammates
  and open slots (shadows with a green **+**) stand around you, and the leader's red **X** over
  a teammate removes them. **Daily tasks** and **friends** are on the left; the **leaderboard**
  and **today's shop** are on the right. Along the bottom runs the **dock** of 3D icons: LOADOUT,
  ARMORY, INVENTORY, SHOP (a NEW badge when the day turns), PASS, PETS, TRADE, TASKS (a green
  **+N** for tasks finished since you last looked: tasks pay by themselves, nothing waits to be
  claimed), **RANKS** (the leaderboards; a trophy), SETTINGS. Pointing at a tile says what's behind
  it (`HX.DOCK_TIPS`). Tap the **player card** (top left) for **your profile** (CHANGE TITLE is
  there). The big green **PLAY** opens the MODES board. Party members get **READY UP**
  instead. A search shows **SEARCHING 0:42** with CANCEL. With no body in the Courtyard, a blue
  **ENTER COURTYARD** spawns you.
- **MODES** (`GameConfig.DOORS`): big tiles, each with a small 3D scene of posed, dressed
  fighters. **Warfront** (public battle servers; the mode is voted between rounds), **Training**
  (the Tiltyard: a friends-only server for you and your party), **Courtyard** (the hub),
  **The Lists** casual **1v1 · 2v2 · 3v3**, and the **Ranked** card (your rank, rating,
  placements, bracket, FIND RANKED). Tiles lock when the party is too big or you are not the
  leader. **SERVER BROWSER** and **CREATE CUSTOM** sit underneath. A party is at most
  `PARTY_MAX` = 3 and always travels together. Friends in other servers can be invited: the
  invite crosses servers by MessagingService, and accepting teleports them to the leader.
- **LOADOUT**: one loadout per class (weight → stats), with a live mannequin and TEAM PREVIEW.
  **Anything locked can be tried on**: it shows on you, with where it comes from and a buy
  button when it is in today's shop.
- **🔒 LOCKED: SHOWN / HIDDEN** (the Loadout and the Armory; Settings ▸ *Locked items in menus*,
  saved): everything there is to get with how to get it (the default), or only what you own —
  every list at once (armor, finishes, weapons, skins, spells and their looks, kill effects,
  emotes, titles still to earn). Something you're wearing or trying on always shows.
- **ARMORY**: everything there is (or only yours, with the 🔒 switch). **WEAPONS** shows every weapon turning on a stage with
  its skin strip, a **STATS** card (reach, damage and head damage, stab, wind-up, stamina a swing,
  guard break, armor pierce, walk speed: bars against every other weapon, from
  `ReplicatedStorage ▸ WeaponStats`), and for
  each skin exactly where it comes from (crate, task, pack, the shop shelf) and its effects
  (trail, aura), plus EQUIP / AS SECONDARY. **ARMOR** shows every set worn by you, piece by
  piece. You can toggle pieces, see the stats of its weight, and BUY (on the days its pack is in
  the shop) or EQUIP on a class of that weight. **KILL FX** plays each kill effect on you, over
  and over, with EQUIP. **EMOTES** loops each emote on you and edits the six-slot wheel.
- **SHOP**: **DAILY** has the packs plus the **WEAPONS shelf** (single skins, a headliner and
  three more, new every day; `Catalog ▸ Store`). Rare is rare there: mostly Commons and Rares, an
  Epic headliner on about half the days, a Legendary on about one day in eight (Legendaries mostly
  come out of crates), never a Mythic or a Unique, never an earned, pass or task skin. **CRATES** has the chosen item on a big stage
  (a skin turning on its weapon, a kill effect or emote played on you), the strip, odds, pity
  and the spinning drum. Opening one plays **the reel** (`HX.crateReel`, CS-style): the stage goes grey
  (a big ?), a long strip of cards (filler drawn by the crate's own odds) rushes under a gold
  marker ticking card by card, creeps the last stretch, stops somewhere on the winner and bursts. The **Relic Crate** holds kill effects and emotes; the **Grim Crate** only kill effects (a
  serpent from the ground, a hand from the sky, an anvil, a black hole and more). **CROWNS** has the Robux bundles and Crowns →
  Marks. (No COLORS tab: every armor colour is free; the premium look is a finish.)
- **TASKS**: today's three, the weekly, the **task-skin track** (skins earned by finishing
  tasks), and **mastery** (kill-count skins, earned armor, earned titles) with progress bars.
- **PASS**: the season pass (`Catalog ▸ Pass`), 30 tiers climbed with every round's XP plus a
  bonus per finished task. The free track is everyone's; the premium track (Crowns) adds
  exclusive skins and a title, and covers the tiers already reached. Rewards can be claimed one
  at a time or with CLAIM ALL. The dock's PASS badge counts what is waiting.
- **Login rewards**: a pop-up on the first open of each day with a seven-day run
  (`Catalog ▸ Login`). A missed day pauses the run instead of starting it over.
- **HATCHERY** (dock tile, with a badge for eggs ready to hatch): **NESTS** shows your three
  nests, each egg turning on a stage with its countdown. A ready egg can be hatched (HATCH!), or
  hatched early for Crowns (HATCH NOW, after a confirm). There is SET AN EGG for empty nests,
  your eggs, and the egg shelf (Marks / Crowns; the Royal Egg only comes from gifts, login days
  and the pass). **COMPANIONS** is the collection: the ones you have found on stages, the rest
  as silhouettes, stars, and TAKE IT ALONG / SEND IT HOME. **Every egg has its own companions**
  (Speckled: farm and shore; Mossy: woods and marsh; Ember: fire and night; Royal: the crown's
  beasts): nothing hatches from every egg. WHAT'S INSIDE scrolls, and any companion in it inspects.
- **The weapon bar** (`Hotbar`, in place of Roblox's): a slot per weapon (the primary 1, the
  sidearm 2, pickups after), each a 3D picture of the weapon in its skin edged in the skin's
  rarity, its key and name; the one in your hands lifts, glows and turns; a bow or crossbow shows
  its arrows left. 1–9 / a click / a tap take one out, the same again puts it away; D-pad steps.
- **INVENTORY** (dock tile): everything you own in one grid (skins, kill effects, emotes,
  companions, armor, titles), with SEARCH, the kinds as chips, SORT (rarity · newest · name · most
  copies), ×N for copies and the best copy's finish and number. Any card opens **INSPECT**.
  **Armor shows as sets**, never a lone piece: one card per set ("complete" or "2 of 3 pieces"),
  which opens the Armory on that set. The cards come at once and each 3D thumbnail is built as it
  scrolls into view (a few a frame), so a big collection opens without a hitch.
- **INSPECT** (`HX.inspect`, anywhere: the inventory, pass and login rewards, both sides of a
  trade, an egg's contents): the thing big and alive (the weapon turning, the effect playing, the
  creature walking), its rarity (a Unique's frame walks the rainbow), effects, where it comes
  from, THIS COPY (from a trade) and YOUR COPIES (number, finish, story, times traded, kills), and
  EQUIP · OPEN THE CRATE · TRADE IT. The little round **i** on a card opens it; M closes it.
  Clicks on it never reach the cards behind (a full-size catcher button). **Stages** (inspect,
  the Loadout): the knight breathes and glances about (`Stage.idle`, only while on screen), and
  **SHOWING: PRIMARY ⇄** swaps the weapon in their hands for the loadout's secondary.
- **The Courtyard is for showing off**: change your active class, a piece, a colour, a skin, your
  title or your look in the menu and the body you're standing in changes at once, no respawn
  (`_G.CourtyardRedress`, LoadoutServer; a match waits for your next spawn).
- **Playtime gifts** in the lobby's left column: the next gift, a live countdown and CLAIM.
- **You, under the armor** (`Loadout ▸ Avatars`): every player is their own Roblox avatar under
  their armor: its hair and face accessories, its face, its skin colours. When you join, the
  server builds your avatar (`GetHumanoidDescriptionFromUserId` → an R6 model) and keeps the kit
  in `ReplicatedStorage ▸ Avatars ▸ <UserId>`; the Dresser puts it on your spawn and on every
  menu mannequin of you (`appearance.avatar`; the HubMenu's `HX.myLook`). Hats and anything worn
  on the body stay off (armor goes there). A helmet hides what it covers. Bots and NPCs keep the
  made-up looks of `Catalog ▸ Body`. There is no wardrobe any more; the **title** is picked on
  your profile (CHANGE TITLE: `HX.titlePicker`).
- **Bareheaded**: LOADOUT ▸ HELMET ▸ "No helmet" shows your face and hair in battle; your head has
  no armor then (a helmet's protection only covers the head when you wear one). What a helmet
  hides stays on, hidden (`Covered`), so taking it off shows it (`Dresser.setHelmet`).
- **The Helmet Toss** (only with a helmet on): off it comes and your hair and face show; thrown, it
  clangs and stings whoever it hits, then lies there for a minute. Walk up and put it back on (E),
  or anyone without a helmet can wear it, colours, finish and all (`Dresser.wearHelmet`). A thrown
  helmet doesn't protect anyone's head (`Off`).
- **SERVERS**: the browser with filters and **CREATE CUSTOM**: door, mode, map, player limit,
  round length, who may join, friendly fire, respawns, ground weapons, and cheats. A cheat
  server gives the host `/god /heal /speed /tp /bring /give /kick` and pays nobody.
- **SETTINGS**: camera feel, attack side, keybinds.

**Keeping the menu quick.** A tab you leave lets go of what it built (its 3D previews and their
loops) a moment later (`HX.sleep`); the Loadout list and the Pass track are drawn off screen a few
milliseconds a frame and swapped in whole (`HX.draw` / `HX.slice`: the old one stays up, no
half-drawn frame); the Armory and the daily shop are drawn off screen too. A dressed mannequin
is dressed once per look and copied after (`PreviewRig`), a weapon on display built once per
skin, the class cards keep their mannequin while the look holds. Previews, spinning weapons and a
finish's glow only animate on screen (`HX.onScreen`; `ArmorFX` skips mannequins nobody can see).
An English-reading player's screens skip Roblox's automatic translation (`LocaleText`: building a
label is several times cheaper); everyone else's are translated as before.

Every teleport puts up the **travel screen** (`TravelScreen`). `HubServer` answers all of it
(`HubRemote` / `HubEvent`), heartbeats this server into a MemoryStore `Servers` map for the
browser, and teleports through `TeleportService` — both need a published game; in Studio the
browser shows only this server and PLAY switches this server's mode locally.

**Money.** Marks are earned (`Catalog ▸ Economy ▸ earn`: round, win, kills, parries, chambers,
drills, first win of the day; paid by `Scoreboard` at round end through `Economy.award`, with a
pay card on screen) or exchanged from Crowns. **No farming bots:** a player's kill pays 8 Marks, a
match's bot only 1 / 2 / 4 by its rank (`kill_Squire` / `kill_Knight` / `kill_Champion`; the Horde's
too), the training yard pays only firsts (a lesson, a rank beaten in the ring, a best Gauntlet
wave), and past 2500 battle Marks in a day (UTC) the rest of the day's rounds pay 40% (`daily`;
the pay card says A LONG DAY; the first win of the day's bonus always pays in full); Crowns come from Robux Developer Products
(`EconomyServer` handles receipts once each). Contracts (`Catalog ▸ Contracts`, three dailies
+ one weekly drawn per date) and weapon unlocks (level or kill counts) come from `Stats`.
**Ranked.** The Lists queue is a MemoryStore ticket per party and bracket; one server at a time
pairs tickets within a rating window that widens while you wait, reserves a server, and each
server teleports its own players with the sides in the teleport data (`Matchmaker`). Matches
are `Locked` (only those user ids), best of 5, forfeited by a leaver; ratings are Elo
(`Scoreboard`, `LB_<bracket>` OrderedDataStores), ranks from `Economy.rankTiers`, leaving a
ranked match early locks the queue for `queueLockMinutes`.

## Staff: the admin panel (F2)

`Admin ▸ AdminServer` decides everything; `StarterPlayerScripts ▸ AdminPanel` only asks.
**Roles** are in `Admin ▸ Roles` (edit it to change them): **Owner** (the game's creator, always;
everything), **Admin**, **Moderator**, **Helper**, each with a rank and a list of permissions
(view, kick, tempban, ban, teleport, health, announce, announce_all, rounds, bots, currency,
items, unlock, progress, reset, staff, shutdown, log). A role acts only on players and staff below
it and gives only roles below it. Staff see an **ADMIN · F2** button (top right); F2 opens:
- **PLAYERS:** everyone here, or look anyone up by name or id: kick, ban (hours, or for good),
  unban, go to, bring, freeze, heal, kill, give / take Marks and Crowns, set level, give / take any
  item (pieces, skins, weapons, emotes, kill effects, companions, eggs, crates, titles, colours),
  unlock everything, wipe saved data (the last two ask twice).
- **SERVER:** end the round now, the next mode and map, announce (this server or every server),
  spawn / clear bots, shut the server down.
- **STAFF** (give and take roles) · **BANS** (who, until when, why; unban) · **LOG** (every staff
  action, newest first).
Changes to a player who isn't in your server wait in a queue and land in whichever server has
them (right away through MessagingService, or when they next join). Bans are checked as players
join and kick across servers. Saved in DataStores Staff_v1, Bans_v1, AdminQueue_v1, AdminLog_v1.
If a store can't be reached (Studio without API access), roles, bans and the log still work for
that server and the panel says so.

## The Courtyard (the hub)

**The world round its walls** (`Game ▸ HubBackdrop`, built when the Hub starts into workspace ▸
MapBackdrop, beside the map so the menu still frames the castle; the Hub clears it when it ends):
grassland to the horizon, hills all round, the road out of the gate through a village with a
windmill and fields, woods, and far to the east a war camp with its trebuchets, which now and then
lob fire further off still (`HubAmbience.client`: scenery only, never near anyone).

A castle courtyard built from code (`Build ▸ MapCourtyard`); the old free-model Courtyard was
moved to `ServerStorage ▸ _RetiredMaps`. It's peaceful: players can't fight here.
`Hub ▸ Courtyard` (server) and `StarterPlayerScripts ▸ Courtyard` (client) run its places from
the map's `Spots`:
- **The Hall of Champions** (north, before the keep): statues of the season's top three in
  Warfront kills, wearing their own armor and weapon, larger than life and cast in gold, silver
  and bronze, with plaques. Two boards list the most kills and the Lists' ranked brackets.
  `Hub ▸ Leaderboards` reads the boards and a player's saved look.
- **The wishing fountain** (middle): one free wish a day (`Catalog ▸ Gifts ▸ wishes`). A coin
  arcs into the water and the wisher's luck floats over their head for everyone. Benches round
  it.
- **The Gates of War** (south): Training Yard, Warfront and The Lists. E travels, or opens the
  mode board for the Lists.
- **The Merchant's Stall** (south-west): today's packs on two mannequins and today's skins on
  the rack; E opens the SHOP.
- **The Notice Board** (where you arrive): your own daily and weekly tasks with progress, the
  next playtime gift and your pass tier, written on the parchment for you; E opens TASKS.
- **The Hatchery** (west), the stone circle (east), the inn (the Hearth & Hound) with a bard (south-east).

## Name tags and titles

Roblox's own overhead names are off (players: `LoadoutServer`; bots: `Bots`; the map's characters:
the training yard's teachers, the Courtyard's bard). `NameTags` (client)
draws ours, and only when it makes sense: someone within 9 studs, or your aim (the middle of the
screen, or the mouse when it's free) on their body within 45 studs with a clear line of sight;
in the Courtyard everyone within 24 studs shows too. Names fade in fast and out slowly.
- **The look:** a level badge, a staff badge (OWNER · ADMIN · MOD · HELPER in their role's colour),
  a gold crown and a gold shimmering name for **season pass** holders; team colours in team modes;
  bots in their rank's colour with their rank under the name (a Warlord in gold); a map's
  character (a Model in `workspace ▸ Map` with `TagName`) in gold with what they do under it
  (`TagTitle`: DRILL MASTER, BOWMASTER, MAGISTER, THE BARD).
- **Titles** (picked in APPEARANCE; free, earned in battle or from the pass) show under your name
  tag, after your name on the Tab board, and after yours in the kill feed when you get a kill (the
  free *Recruit* is left out). The board and the feed crown pass holders too.
- The server publishes `Title`, `Level` and `PassHolder` on each player (`Hub ▸ Pastimes`, every
  second); `StaffRole` comes from the admin panel.

## Pastimes: playtime gifts, the Hatchery, companions (looks only)

The menu calls it **PETS** (the dock tile, the screen): three tabs, nothing below the fold —
**EGG SHOP** (every egg on sale as a big card: it turns, its odds as a bar, WHAT'S INSIDE, BUY;
a bought egg offers to go straight into a free nest; it opens here for someone with no eggs),
**MY NESTS** (the nests and the eggs you hold, and a way back to the shop) and **MY PETS**.

Things to do between fights, so the Courtyard is a place to hang out. None of them touch combat.
- **Playtime gifts** (`Catalog ▸ Gifts`): six a day for minutes played on any server (the
  Courtyard and every match). A chip at the top left counts down to the next gift and claims it
  with a click; the lobby shows it too. Reset at 00:00 UTC.
- **The Hatchery** (`Catalog ▸ Eggs`): a thatched pavilion in the Courtyard with three nests,
  built by `Hub ▸ Pastimes`. Set an egg in a nest and it incubates in real time, even while you
  are away or in a match. Standing within 20 studs makes your eggs incubate twice as fast, and
  a line at the top says so. Your own eggs sit in the nests, wobbling when ready, with timers;
  press E to hatch or to open the menu. Each egg is egg-shaped (a round lower half, a taller
  narrower top) and drawn in its `look`: speckled; mossy (moss and a sprout); ember (glowing
  cracks, smouldering in the world); royal (gold bands, gems, a little crown, sparkling).
  Nests keep real time (`started` = `os.time()` in the
  profile), so eggs ripen while you're offline too (Studio can't save, so there they last a session).
  In the menu: **SET AN EGG** opens your egg inventory as cards (count, hatch time; a missing one
  can be bought right there if the shelf sells it), and **YOUR EGGS** shows every kind with how
  many you hold.
- **Companions** (`Catalog ▸ Companions`, 21 to find): a hatched egg rolls one by the egg's
  odds. A duplicate adds a star (up to 5, and five stars sparkle); past that it pays Marks.
  Your companion follows you around (built from parts by `Companions`, drawn locally for every
  player). Every body is made of rounded sphere-mesh shapes: four-legged beasts have round
  bodies, cheeks, snouts, paws and a segmented tail, drakes a rounded neck and head, nostrils,
  wing claws and back spines, and every eye has a white glint. SETTINGS ▸ Companions: All / Mine / None.
- Testing in Studio: `/egg Royal 2`, `/ripen` (every nest ready), `/playtime 30`.

## Skin effects, kill effects, emotes (looks only)

- **Skin effects** (`SkinFX`, applied by the `Dresser` after the tint and trim): Epic and
  Legendary skins leave a double swing trail (a bright core and a wide soft glow; Legendary
  trails shimmer). Skins with `fx` wear an aura: three layers of particles off the blade, a light
  on it, sparks thrown off the tip and a sound for the swing (`SkinFX.SWING`). The client's
  `SkinFX` driver brings them to life: while a blade moves the aura flares up to four times its
  rate, the sparks fly, the light swells (a storm flickers) and the swing makes its sound —
  only for a real swing (the tip's speed is measured against the body, so walking and running
  never set it off), quieter than before, once per swing: it starts as the tip passes 40 studs/s
  and can't start again until the tip has stayed under 14 studs/s for 0.3 s. While it's held at
  all an aura **hums** (`SkinFX.HUM`, Pro Sound Effects loops): a crackle of fire, an electric hum, a
  shimmer, a low pulse, only heard up close and swelling a little as it swings (a windup turning into its release is one swing), and a
  sound with a `cut` fades out over 0.18 s instead of snapping off.
- **Staff heads** (`StaffHeads`): a Mage's staff skin is a whole new head, never a recolour. Each
  staff skin names a design (`Catalog ▸ Skins head = "…"`); `SkinTrims` hides the plain claws and
  orb (`SkinHidden`, shown again on the next skin) and builds the head, `SkinFX` adds its lights,
  particles, lightning beams and trails and moves the spell's tip (`TrailTip`) to the head's core
  (`HeadTip`). The rarer, the wilder: Commons get their own shape and a breathing stone (Ashwood's
  crook, Oaken's amber); Rares an aura and something moving (Emberwood's coal and circling embers,
  Frostbranch's ice burst, Gilt Spire's floating gem, Bloodroot's beating heart); Epics machinery
  (Verdant Bough's turning leaves round a flower, Stormcaller's lightning between the prongs,
  Bonecaller's skull with circling ghosts, Sunspire's wheeling rays); Legendaries a living head
  (the Archmage's gyroscope of three rings, Dragonbone's skull with fire in its jaws and beating
  wings, the Voidstaff's black hole drawing light in); the Mythic Staff of the Cosmos a star with
  three worlds in orbit, a moon round the ringed one, dust paths and a wheel of constellations.
  The moving parts carry `Anim` attributes (rotations about a centre, innermost first; `osc`,
  `bob`, `pulse`) and the Trim folder the tag `TrimAnim`; `StarterPlayerScripts ▸ TrimAnim` turns
  them on every client (weld C0s in the world, CFrames in previews; only on screen; still past 140
  studs, or 60 on a phone, where they also turn at half the frame rate) and makes
  the heads' lights breathe, flicker or walk the rainbow and their lightning jump.
- **Drawing a weapon** (`DrawFX`, client): taking a weapon in hand, the arm reaches to where it
  hangs (over the right shoulder for a two-hander, a bow or a staff; across to the left hip for a
  one-hander or a grimoire; the right hip for a dagger or a wand) and sweeps it out into the
  weapon's idle, laid over the animation for 0.4 s (two-handers 0.52 s) on everyone's screen
  (players and bots); a staff turning into its melee self doesn't count. Settings ▸ Draw animation.
- **Kill effects** (`KillFX` + `Catalog ▸ KillFX`): nobody starts with one (profile `killfx` "" = a
  plain fall; ARMORY ▸ KILL FX ▸ *No effect* goes back to it). `Scoreboard` (and the training dummies) call
  `_G.KillFxHook(killer, victimCharacter)`; `Hub ▸ Cosmetics` checks the killer owns the equipped
  effect and fires `FxEvent "Kill"` to everyone **1.2 s after the death** (`KILL_FX_DELAY`), so the
  body falls first and a head that came off rolls away. **Everyone sees everyone's effect**: the
  event carries the body's `CorpseId`, where the effect stands and the body's colours, never the
  body itself (with streaming on, a client that hasn't streamed the body in would get nil and
  drop the effect). Each client (`Cosmetics.client`) finds the body by its id and builds the effect
  upright over it, at a standing torso's height above the floor under it, in `workspace.LocalFX`,
  and hides the body locally; without the body it plays at the server's spot in its colours.
  Effects that **move the body** (dragged under by the kraken or the rift, sunk in sand or a grave,
  swallowed by the serpent, sucked into the black hole, squashed by the anvil or the hand, lifted
  by Ascension) hide the real body and move a *puppet*: anchored local copies of what can be seen
  of it (`puppet`, `posePuppet`, `squashPuppet`, `fadePuppet` in `KillFX`), so the server's ragdoll
  is never touched. **Every effect has its sounds**, timed to it
  (ice that creaks then shatters, a zap and a thunderclap, a choir, a fanfare, a raven and wing
  bursts…), from Roblox's licensed libraries (Pro Sound Effects, APM Music) so they play in any
  game; the menu's preview plays them once, flat, on its first loop. Bots and dummies get their
  kill effect from `Scoreboard` (which watches `workspace.NPCs`) and nothing else, so it plays once.
- **Emotes** (`Emotes` + `Catalog ▸ Emotes`): hold **B**, point the mouse at an emote and let go
  (or tap B and click one). There are no number keys, because 1–9 are the backpack's weapon slots.
  The client starts the emote at once and asks `EmoteRemote "Play"`. The server checks ownership,
  that you are alive and that you are not mid-fight, then relays `FxEvent "Emote"` with its start
  time to everyone. The pose is layered over `RigPose` (`Emotes.modify`), so every player sees it
  the way they see the combat pose.
  - **Arms-only emotes** (`upper = true`: Salute, Cheer, Flourish, Wave, Shrug, Beckon, Laugh,
    War Cry, Blade Toss) play while you walk; the legs keep the walk animation. **Whole-body ones**
    (Bow, Kneel, Jig, Windmill, Champion, Thunderlord, Ascension) need you standing still and end
    when you move.
  - **The rarer, the more it does** (`EmoteFX`, cues on the emote's own clock, so every client sees
    them in step and the menu's previews show them too):
    - **Common:** a glint, a puff of dust, confetti.
    - **Rare:** trails, rings, rising dust and embers.
    - **Epic:** shockwaves, a war horn, music notes and coloured stamps.
    - **Legendary:** a whirlwind with crackling steel, or a pillar of light from the planted sword.
    - **Mythic:** **Thunderlord** (a storm gathers, three bolts strike the raised blade, it's driven into the ground in a blast) and **Ascension** (rising into the air on wings of light, a halo, a choir).
    The motions have weight: a small move the other way first, a hair past the pose and back, a follow-through.
  - **Fighting ends emotes:** attacking, blocking, kicking or dodging ends any emote at once (the
    keys locally, the character's `Acting` / `Blocking` flags for everyone), and no emote starts
    mid-fight.
  - **Feet stay planted:** a bend at the `waist` pivots on the hip line, and the legs are posed
    back to exactly where they were.
  - **The weapon:** it is steered by where the blade should point in the grip's own frame, so a
    dagger and a greatsword both salute upright, and a planted tip just meets the ground for any
    blade length. The animation (the weapon's idle guard) fades out and back in over 0.2 s, so
    nothing snaps.

## Drops, rarity, collections, trading, gifts (`Catalog ▸ Calendar`, `Drops`, `Economy ▸ Collection`, `Economy ▸ Pulls`, `Economy ▸ Trading`, `Economy ▸ Gifting`)

**The Forge.** Every weapon skin is its own mesh (`blender/forge.py` + `blender/themes.py`: new
edges, guards, pommels, grips, ornaments, painted patterns, Neon inlays), welded on from
`Cosmetics ▸ Skins ▸ <weapon> ▸ <skin>` by `Dresser.applySkin`. Built, uploaded and assembled by
`blender/forge.py → scripts/upload_skins.py → scripts/skin_entries.py → Build ▸ SkinModels`
(see CONTENT_GUIDE §5). Without the model a skin falls back to its tints + trim.

**The calendar.** `Catalog ▸ Calendar`: **the Beta is on now** (the drop "The Proving Grounds"):
everyone who plays before the launch is a **Beta Tester**, numbered in the order they came — the
title *Beta Tester* and **Trailblazer**, a Mythic armor finish nobody else will ever have (white-hot
steel, trims that walk the rainbow, starlight; bound, never sold, in no crate; `Calendar.beta`,
`Collection.checkClaims`). Everything after it is **TBD, waiting for the launch date**: the
Founders' Forge and the 12 weekly drops after it (Bonewright, the Hollow Night, All Hallows' Eve,
Ironclad, the Wild Hunt, Northmen, Sea-Wolves, Frostfall, Yuletide, Twelfth Night, Midwinter, Black
Sails) have no `at`, so they never come out by themselves (the board says "at launch"; staff can
still force one). Their events and claims carry `after = <drop>` and wait for it too. When the
date's known: give the Founders' Forge its `at` (the beta closes, and the Founders' window opens
for 30 days: the Founder's Oath, numbered, and the title Founder), then the weekly drops theirs. `ReplicatedStorage ▸
Drops` reads it with the server's clock, so a drop appears on every server at the same second;
nothing with `drop = "<id>"` shows before then. Staff: F2 ▸ DROPS releases one early or holds
one back (every server; remembered in DataStore `AdminDrops_v1`). Studio: `/clock 2026-10-31`,
`/clock +3d`, `/clock reset`, `/drop now <id>`.

**Rarity and scarcity.** Six tiers: Common, Rare, Epic, Legendary, **Mythic** (crates only, the
lowest odds in every crate (0.3–0.5%), numbered, two trims, an aura of its own and starry glints)
and **Unique** (one of one, EVER: a serial with a limit of 1; never in a crate or the shop; the
season's rank-1 champions get that season's Unique (`seasonRewards.champions`) and staff can give
one (F2 ▸ item); it has everything a Mythic has and its colours walk through the rainbow; it
trades, it can't be scrapped). The Mythics: Starforged (Bladesmith), Worldbreaker (Hafted), The
Sovereign (Royal), Phoenix (Fletcher), and the kill effects Reaper's Toll (Grim) and Supernova
(Relic). The Uniques: Crown of the First Season, The Undefeated, Bloodmoon, Stormbringer
(Season 1's champions), Kingslayer and Aetherwind (staff). The reasons something is rare are
shown on it: VAULTED (its crate is out of rotation, may return), RELIC
(gone for good: event crates, past claims, the Founders' window), LIMITED (a fixed number made,
e.g. the Frostgift: 2,026, with the stock live in the shop), a serial number (#12: every Mythic,
limited, claim and Founder copy; counted globally in DataStore `Serials_v1`).

**Copies.** Every skin out of a crate or the shop and every hatched companion is a COPY of its own
(`Profile.copies`), and so is every kill effect and emote out of a crate (`fx:` / `emote:` keys):
its number, its finish, when and where it came from, how many times it has been traded.
**Duplicates are never paid back**: they're kept, to trade, to **scrap** a spare for Marks if you
choose, or (skins) to **forge** three into one with the next finish. Finishes: Masterwork (5%, a gold glint), Radiant (1%, its glow, trail
and aura cycle through colours); companions Golden (4%) or Spectral (1%). Each skin counts its
kills (shown on its card). Earned, pass, pack, claim and Founder items are BOUND (never traded).
The **Armoury rating** (`Collection.rating`) adds it all up: rarity × finish × relic / limited /
low-number bonuses.

**Nothing is for sale for good** (`Calendar ▸ rotations`, `crates`, `eggs`; `Drops.crateLive`
returns how a crate is in: `daily` / `featured` / `event` / `vault`). The eight armoury crates are
a **daily rotation**: 3 a day (each is in 3 days in 8), the window sliding through
`rotations.crates.order` every UTC midnight; the four core eggs likewise, 2 a day. A drop's crate is
**featured** for its weeks, then **vaulted**; a **From the Vault** weekend (`weekends.rotation`,
`vault = true`) brings one vaulted crate back until Monday, each in turn (none vaulted yet: that
weekend is skipped). Event crates (`retire = true`) never return: their items become RELICS.
Every card says how long it has and when it's back ("TODAY ONLY · 6h LEFT", "LAST CHANCE",
"BACK IN 2d 4h", "BACK FROM THE VAULT"), the crates page and the Hatchery say what's in tomorrow,
and an item's "drops from the …" line says whether its crate is in today (`HX.rotationText`,
`HX.tomorrow`). Packs and shelf skins already rotate daily (`Catalog ▸ Store`); the season pass
lasts its season. Only weapons (Marks, gameplay) and Crowns are always there.

**Big pulls** (`Economy ▸ Pulls`). A Legendary or better out of a crate, a top finish (Radiant; a
Spectral companion), or a Legendary+ hatch: a banner slides down for everyone in the server, 8
seconds after the open (so the opener's own reel lands first). A Mythic, a Unique or a Radiant
Legendary goes to **every server** (MessagingService "Pulls", a 🌍 banner and a war horn) and, in
the Courtyard, a **pillar of light** rises where the player stands; the opener gets "Every server
just saw your MYTHIC". The crates page has a **BIG PULLS** feed (the last 24 game-wide, MemoryStore
"RecentPulls", 3 days) and each crate a **PULLED FROM IT LATELY** list. A Mythic's page says how
many exist ("ONLY 37 EXIST · EACH ONE NUMBERED", or "NOBODY HAS PULLED ONE YET": its serial
counter, `Collection.count`). SETTINGS › **Name on big pulls**: Hide shows "Someone" instead.
**The kill feed** names the killer's skin when it's Epic or better (or has a finish), in its
rarity's colour (`Scoreboard`: the Tool's `Skin` / `SkinVariant`).

**Crates.** Only crates in rotation can be opened (events first, then one back from the vault, then
the drop's, then today's). Open with **Keys** (earned only: a Key per level-up,
one for the first win of the day, more from events) or Crowns. The odds (with the finish
chances) are on screen before every open, and when the pity is due they say so (Legendary or
better; the pity is long, 20–40 opens, so a Legendary is a moment). A crate opened anywhere
else (the pass, a daily or playtime gift) **spins on the crate screen** like any other
(`HX.spinCrate`). **Short of Crowns or Marks** anywhere in the menu: a pop-up offers the Crown
bundles (one click buys) or the Crowns › Marks exchange right there (`HX.shortOf`).
**Roblox's paid-random-item rules:** where `PolicyService` restricts paid random items
(`ArePaidRandomItemsRestricted`), Crowns don't open crates (Keys do), eggs aren't sold, early
hatching is off, and crates or eggs inside a purchase (the premium pass) become Marks. Every
crate's **ODDS OF EVERY ITEM** lists each item's own chance (each rarity's share split evenly),
the finish chances and the pity, and shows the pity's odds when it is due (Roblox's rule: each
outcome's odds, as percentages, before the purchase).

**Weekends** (`Catalog ▸ Calendar ▸ weekends`, `Drops.events`): every Friday 16:00 to Monday
08:00 UTC the next of the rotation runs, like a dated event (the crier, the DAILY tab, the pay):
Double XP Weekend, **From the Vault** (a vaulted crate is back), **Armory Roulette** (`rule = "roulette"`: every spawn in battle hands you a
random weapon pair your class can carry, your own skin for it if you have one; never in the
Courtyard, the yard or ranked; +25% XP), Raid Weekend (the Horde pays double Marks), War Chest
Weekend (battles pay half again as many Marks). A dated event (Halloween…) takes the weekend
instead. `Drops.rule(name)` asks whether a rule is on.

**Trading** (TRADE in the dock). Same server, level 5 and up, only where Roblox allows trading paid
items (`IsPaidItemTradingAllowed`). **Armor goes only as a full set**: one copy of every piece of
its set, together, counting as one item (`Trading.offer` refuses anything less), so nobody is
ever left holding half a set; the picker shows only the sets you hold whole, each as one card.
Both sides put up to 8 items up, both press READY, a
5-second countdown runs (any change un-readies both), both CONFIRM; the server re-checks every
copy, swaps them in one step and saves both profiles at once. Each side shows its worth (rating
points). Logged in DataStore `TradeLog_v1`.

**Gifts** (GIFTS in the dock; `Economy ▸ Gifting`). One way, to anyone, by Roblox username, whether
they're playing or not: Marks, Crowns, items (the copies that trade, armor as full sets), or
anything in today's shop **bought for them** (a 🎁 button by every purchase: shelf skins, packs and
their pieces, weapons, the pass, a Crowns bundle with Robux). A gift goes into their **gift box**
(DataStore `Gifts_v1`, key `u<id>`) and is opened the moment they're here: in this server at once,
in another on a MessagingService nudge, offline when they next join (and a Roblox notification,
`Hub ▸ Reminders`). Something they already own comes as what was paid for it; a skin is a copy of
its own. Rules: level 5 and up, where Roblox allows trading paid items (sender, and the recipient
as it arrives: where they can't receive it, it goes back to the sender whole), their privacy
(SETTINGS › Gifts from), and a daily cap (`ECONOMY.gifting.perDay`: 25,000 Marks, 5,000 Crowns, 20
items, 30 gifts). A gift carries a card picked from `ECONOMY.gifting.notes`, never typed. Never:
crates, eggs, Keys. The sender's save lands before anything leaves; every gift is logged
(`GiftLog_v1`). Received gifts pop up as cards (from whom, the note, what was in it).

**The shop.** The DAILY tab opens with this week's drop (name, blurb, its headliner, the events
running, NEXT DROP IN … · ???) and the menu shows it once a session. The WEAPONS shelf's headliner
can be a Calendar feature (a limited skin until it sells out).

## Game modes, maps, places (`GameConfig`)

**One place, many servers, and a server never changes mode.** Every *public* server (what
Roblox puts you in from the game page) is the **Hub**. Every match is a **reserved server** of
the same place (`TeleportService:ReserveServer`): HubServer reserves it, and the teleport data
of its first arrival tells it its mode, access level and name (`Game.identify`), which it keeps
forever. PLAY joins a public match server of that mode with room for your party, or reserves a
fresh one; RETURN TO HUB teleports with no code, which lands in a public server, i.e. the Hub.
Reserved servers can only be entered with their access code, which lives in HubServer's
MemoryStore registry and never reaches a client or the Roblox page, so **access is ours**:
`Public` (listed, anyone), `Friends` (unlisted custom lobbies; friends of someone inside may
join), `Locked` (only the user ids the server was made for — ranked matches; `Game.mayJoin`
kicks anyone else). One place means one set of scripts to update. Studio has no teleports, so it
runs `STUDIO_MODE` (Hub) and PLAY switches the mode locally. `GameConfig.MODES`: `Hub` (courtyard, no clock),
`Siege` (below), `FFA`, `Duel`, `TDM` (tickets), `LTS` (one life per round, first to `roundsToWin`), `KOTH`
(`Zones/Hill`, `pointsToWin`) — each with `maps`, `roundLength`, `intermission`,
`respawnDelay`, `teams` (0 or 2), `maxPlayers`, a `category` (the browser's *type of
gameplay*). Every place is an empty world with a skybox: the map is cloned in at runtime.
A mode is a ModuleScript in `Game/Modes/<Id>` built on `Game.Mode` — override
`start / tick / onKill / onDeath / canSpawn / spawnCFrame / isOver / objective / result`.

**Maps** are Models in `ServerStorage` → `Maps` (Folder) → `<Name>`; a mode's `maps` list
names them. Every mode has 10 or more: the hand-built ones (`Build ▸ Maps`, `Build ▸ Map<Name>`)
and 32 themed ones from **`Build ▸ MapForge`**, each a layout in a theme:
- **Siege:** Emberkeep (ember night), Sunspire (desert noon), Thornwall (autumn), Mistmoor
  (swamp mist), Greenhollow (summer), Stormhold (storm night), Ashenford (ash), Rimeholt (moonlit
  snow), Blossomgate (spring), Duskwall (desert dusk, a great moon), Mournhold (dawn mist). Each is a castle to take: the ram up the road, the bailey, the great
  hall, and its own champion on the throne.
- **Arenas:** the Bloodpit, Moonring, the Dustbowl, Thornpit, Mirepit.
- **Castle courtyards:** Abbeyfield, Blackwater.
- **Villages:** Harvestvale, Frosthollow, Marshfen.
- **Bridges:** Redgorge (a dry gorge), Mistbridge.
- **Ruins:** Cinderfall, Duneshrine.
- **Clearings:** Hollow Grove (fireflies at night), Pinewatch.
- **Warfields** (The Lists, 1v1 to 3v3): Redmeadow (autumn wheat), Ironvale (snow), Grimfield
  (ash and embers), Sunfall (desert dunes at dusk), Ravenfield (night, storm). A duel ring of pavises and planted spears in the middle of a battle: two
  armies fight all round it on every screen (`StarterPlayerScripts ▸ Warfield`, with
  `ReplicatedStorage ▸ WarCrowd` and `WarFX`; the map's `Warfield` attribute, the ring's radius,
  turns it on): three lanes a side meet either side of the ring (foot, pikes, knights), charging
  together after 5 s with horns and drums, wavering, pulling apart and charging again; each side's
  archers stand straight behind the ring, so their volleys arc over it onto the enemy's lines; the
  battle-mages' fire crosses the sky; the cavalry rides down a flank now and then; reserves,
  standards, burning wagons, dust and the din. A duelist down in the ring brings a roar from the
  other side's army; a fine parry (or chamber) there, a shout from the parrier's (at most every
  3.5 s); the winners of a round cheer. About 13,700 crowd
  parts, 1.8–3.5 ms a frame, 52–56 fps in Studio play.

Every forge map carries its weather (snow, rain, ash, leaves, petals, embers, fireflies, dust or
mist, an emitter inside it) and everything every mode needs (team and free spawns, a hill,
Horde gates, Siege stages on the castles). The loader hides `Zones` parts; KOTH draws its own ring. Inside a map: `Spawns` (Folder of parts; attribute `Team = "A"` / `"B"` on team
spawns, none = anyone; made invisible on load), optional `Zones` → `Hill` (a Part; KOTH capture
volume: a Cylinder's disc, or the circle inside a block's footprint — hidden in play), and the geometry.
**Objective indicators** (`StarterPlayerScripts ▸ ObjectiveFX`): the KOTH hill, the Siege ram and a
Siege capture zone are drawn on the ground as a glowing ring every client sees, visible from inside
it: a soft floor glow, a rim in the holder's colour (flashing between the two sides when contested),
48 segments split by how many of each side stand on it (a capture: filled as it's taken), spinning
dashes (faster while it's moving or being taken), a light pillar to find it from across the map
(hidden while you stand in it), and a ground light. It rolls with the ram. Data: Round attributes
`ObjKind` (`Hill` / `Ram` / `Capture`), `ObjPos`, `ObjRadius`, `ObjState`, plus `ObjOwner` /
`ObjCountA` / `ObjCountB` (KOTH) or `Attackers` / `ObjAttack` / `ObjDefend` / `ObjProgress` (Siege). Nothing to author for the menu camera: it measures the map's bounding
box and circles above its edge, looking down and wandering its gaze across the ground. A public
server is the Hub and loads its map the moment it starts, so there is a courtyard to look at
before anyone has spawned. `MapLoader` clones one into `workspace.Map` per round
and picks the spawn farthest from enemies; no such map → whatever is in workspace, and
`SpawnLocation`s. `GameServer` runs the loop: mode → map (vote or rotation) → round (mode
ticks, clock, early end) → result → intermission with the board up and a vote on three cards
(Round `Vote1..3` maps, `VoteMode1..3` modes, `Votes1..3` counts, `VoteRemote`). On the
**Warfront** each card is a *battle*, a mode on one of its maps (three different modes, not the
map just played if it can help it); elsewhere the cards are maps for the same mode. A tie goes to
one of the tied cards at random. A mode can add time to the clock (`mode.bonusTime`), and
**reinforcement waves** come with a mode's `waveSpawn` (seconds): after the first `waveGrace`
(12 s) of a round you spawn with your side's next wave, the two sides half a beat apart (the class
screen counts it down). State is on `ReplicatedStorage.Round`
(`State`, `TimeLeft`, `Number`, `Mode`, `ModeName`, `Category`, `Map`, `Teams`, `ScoreA/B`,
`Objective`, `Winner`, `WinnerKills`, `NextMode`).

**Teams** (`GameConfig.TEAMS`: Crown blue / Iron red) sit on Roblox `Teams`; a character
carries a `Team` attribute and a coloured tabard. Friendly fire deals
`GameConfig.FRIENDLY_FIRE` (0.5) of the damage, shows TEAMMATE on your HUD, gives no kill
credit and reads TEAMKILLED in the feed.

## Armor sets

**Armor is collectable now, like skins.** The **Forge Crate** (in the daily rotation) drops:
- **finishes** (`Catalog ▸ ArmorFX`, `ReplicatedStorage ▸ ArmorFX`), one per class in LOADOUT ›
  FINISH, on any set of any weight. Rare: Gilded, Blackened, Bloodsteel, Verdigris. Epic:
  Emberforged, Frostbound, Verdant, Rosewarden. Legendary: Stormborn, Voidtouched, Sunblessed.
  Mythic: Celestial, Infernal. They recolour the plates, light the trims (pulse, crackle or
  rainbow: `StarterPlayerScripts ▸ ArmorFX`), and wrap you in an aura and a glow in the world.
- **four crate-only sets**, each coming out whole (every piece at once): Dragonscale (Heavy, Legendary), Frostwarden
  (Medium, Legendary), Shadowveil (Light, Legendary), Seraph (Medium, Mythic). Each wears its own
  finish.

**Mage robes** (weight **"Robe"**, `Catalog ▸ Weights`: only a Mage wears them, and a Mage wears
nothing else). The free Apprentice Robes, and seven more out of the **Arcana Crate**, a piece at a
time: Druid (Rare: antlers and leaves), Necromancer (Epic: a skull-crowned hood, ribs of bone,
rags), Pyromancer (Epic: a crest of flame, flames up every hem), Frost Witch (Epic: icicles, fur
and ice), Archmage (Legendary: a towering starred hat, a silver moon), Battlemage (Legendary: steel
and runes over the robe) and the Star Sage (Mythic: a robe of night with glowing constellations
and a crescent moon over the hood); each but the Druid wears its own finish. **A finish on a robe**
(no metal to take it) goes into the cloth: the robe takes its `robe` colour (else its metal), the
lining a deeper shade, the trims its accent, glowing (`ArmorFX.apply`). The Arcana Crate's own
finishes are made for cloth: Spellwoven, Moonthread, Hexweave, Starweave.

**Archers' outfits** (Light: any Light class may wear them). **The Bowman** is the Archer's own
(the class's `starter`, Config `ClassStarter` + `Unlock = {level = 5}`): a hood with a long tail and
a dagged capelet in your colours, a leather jerkin, a quiver over the right shoulder, a bracer on
the bow arm and a shooting glove; it comes with the class at level 5 (the unlock pop-up says so),
an Archer starts out in it, and the Armory lists it under CLASS OUTFITS ("WITH THE ARCHER") with
the Apprentice's robes. Old saves: an Archer still in the plain Light defaults was dressed in it
(Profile `loadoutV` 3). Four more come out of the **Fletcher's Crate**, each whole: the
Greenwood Outlaws (Rare: a feathered cap, Lincoln green, a hunting horn), the Falcon Wardens (Epic:
a beaked hood, a feather mantle, a falcon on the shoulder), Moonshadow (Legendary: a crescent on
the brow, a cloak edged in silver leaves, glowing fletchings; its finish Moonlit) and Phoenixborn
(Mythic: a golden mask under a crest of burning feathers, folded wings of fire; its finish
Phoenixfire). The Fletcher's own finishes, Moonlit and Phoenixfire, drop on their own too.

The **War Chest** (in the daily rotation too) is the second armor crate: six more crate-only sets,
Ranger (Light, Rare), Berserker (Light, Epic: a bear for a hood), Corsair (Medium, Epic: a
tricorn and a captain's coat), Deathless (Medium, Legendary: a skull helm, a ribcage), Lionheart
(Heavy, Legendary: a crowned great helm with a mane), Obsidian (Heavy, Mythic: volcanic glass),
and five finishes (Moonsilver, Oxblood, Bloodrage, Gravelight, Lionsmane). Every drop crate
(Ossuary, Hollow, Foundry, Hunter's, Longship, Rime, Yule, Black Sails, Royal Armoury) also
carries one finish in its own colours. A crate set keeps **its own colours** (Config `Colors`):
the player's paint doesn't repaint them, except team colours in team modes. The shop's crate
cards say what's inside (ARMOR · SKINS · FINISHES · KILL FX · EMOTES).

**What a finish does, by rarity** (`StarterPlayerScripts ▸ ArmorFX`, on menu mannequins too):
every finish's plates glint now and then, and a kill flares it (a ring, a burst of its aura, a
flash of the trims; a Mythic adds a pillar of light). Epic and up leave footprints in their
element (frost, fire, sparks, petals, smoke…). Legendary and up streak light off the arms and
legs while you sprint or swing, and roll a surge ring off you every few seconds. A Mythic has
three motes of it circling you and a rim of its light round your outline (the nearest eight).

Everything out of them is a copy of its own (`"armor:"`, `"finish:"`): trade it, scrap it, keep
it. Looks only: stats still come from the weight. The shop never sells a crate piece.

```
ServerStorage
└─ Armor (Folder)
   └─ KnightSkin (Model or Folder — its name is the set id)
      ├─ Config            ModuleScript (Type = "Heavy" is the only required key)
      ├─ HeadClothing      Model  ┐ each has a Part named Middle, the same size as
      ├─ TorsoClothing     Model  │ the limb it dresses, plus any other parts built
      ├─ LeftArmClothing   Model  │ around it. Any slot may be missing.
      ├─ RightArmClothing  Model  │
      ├─ LeftLegClothing   Model  │
      └─ RightLegClothing  Model  ┘
```

The server mirrors the folder into `ReplicatedStorage ▸ Cosmetics ▸ Armor` and the catalog
auto-imports every set as three **pieces** — `<Set>_Helm`, `<Set>_Top`, `<Set>_Legs` — of the
weight in `Config.Type`. `Config` may also set `Name`, `Pack`, `Rarity`, `PriceMarks`,
`PriceCrowns`, `Covers` (`{"Hair"}`, `{"Hair", "Face"}`, `{"Hair", "Beard"}` for a mask or a coif the eyes look out of), per-piece names and a description;
stats never come from a set (`Catalog ▸ Weights`). Color blocks are parts with attribute
`ColorSlot` = `Primary` / `Secondary` / `Accent` / `Metal`. Full details and every other kind
of content: [CONTENT_GUIDE.md](CONTENT_GUIDE.md).

On dress, `Middle` is welded exactly onto the limb and every other part is welded at the
offset it had from `Middle` in the template — build the set on a dummy in place and it
lands the same way on the player. All pieces end up massless, non-colliding, `Middle`
invisible, inside `Character.Armor`; each clothing model gets a `Limb` attribute so the
per-limb protection check finds it. Rules the pieces play by:
- **Protection is per limb.** A hit only gets the reduction if that limb has a clothing
  model on it. No helmet = full head damage (and heads already take `HEAD_DAMAGE_MULT`).
- A face-stab execute still kills through any helmet.
- Severed limbs take their armor with them; a skewered head takes its helmet onto the blade.
- Helmets (`HeadClothing`) are hidden in first person like hats.
- **No skin through the gaps.** R6 limbs are boxes and the armor is rounded, so the box's
  corners and edges peek out between plates. A limb under a garment is painted a shade (60%)
  of the garment instead of skin: the model's `Under` attribute (a `ColorSlot` name, or a
  colour; `scripts/build_armor.py` sets it to the colour of the model's biggest part, the base
  garment), else its biggest painted part. Where a garment stops short of the limb's end (a
  bare hand under a cuff, a forearm under a rolled sleeve) the Dresser adds a skin-coloured
  sleeve (`Skin`, inside the garment's model) over that stretch, so bare stays bare.
- In first person your arm pieces show; one hides only while the camera is inside (or within
  0.1 studs of) its own box, and shows again once 0.3 studs clear.
- Test dummies still wear whole sets: `/spawn attack Pitchfork PeasantSkin`.

### What each set looks like

No two helms share a shape, and the weight reads at a glance: light sets are cloth, leather and
mail hoods; medium sets mix mail and half plate; heavy sets are full plate with broad, layered
shoulders.

| Set | Helm | Body | Legs |
|---|---|---|---|
| Peasant | wide straw hat | linen tunic, rope belt, pouch | rolled trousers, wrapped shins |
| Road Levy | mail coif, cloth band | padded jack, bedroll, waterskin | hose, knee patches, garters |
| Marsh Wardens | hood with liripipe, dagged cowl | laced jerkin, cloak, quiver | thigh-high waders |
| Harriers of the Coast | sailor's cap, red kerchief, earring | striped shirt, open vest, sash, bandolier | breeches, striped stockings |
| Night Hunters | head-wrap, black half-mask | high-collared jack, shoulder cape, throwing knives | soft strapped boots, thigh knife |
| Gambeson | steel cap over a padded coif | quilted gambeson, mail hem | quilted chausses, knee pads |
| Sellswords | battered barbute (T face) | studded brigandine, one iron shoulder | one leg mail, one leather and iron |
| River Guard | open bascinet, mail aventail | quilted surcoat with waves, baldric | padded cuisses, greaves |
| Gilded Court | burgonet: gold comb, peak, cheek plates | velvet brigandine, gold chain, half-cape | cavalier boots, gold knee discs |
| Wolf Company | steel wolf's head with fangs | grey mail, fur mantle, wolf teeth | cross-gartered leather, fur boots |
| Knight | close helm, comb, beaked visor | plain plate | plain plate |
| Tourney Knight | frog-mouth helm, plumes, mantling | grand guard, lance rest, quartered tabard | gothic plate, pointed toes |
| Iron Crow | hounskull (beak visor), crow feathers | black plate under a feather mantle | talon sabatons |
| Blackguard | horned great helm | spiked shoulders, red cords, tattered cape | spiked knees |
| Knights of the Sun | armet under a crown of rays | fluted plate, sunburst, sun-disc shoulders | fluted plate, bear-paw toes |

Earned pieces stand apart the same way: the Champion's sugarloaf helm with its crown, the
Duelist's long-tailed sallet, the Bloodied Kettle, the Wolf Pelt Hood, the Banneret's chevron
surcoat with a livery collar, the Hunter's fur-collared cloak and horn, the Sergeant's banded
surcoat, the Runner's crossed wraps, the Veteran's strapped mail and iron.

**How the meshes are made.** `Build ▸ Armor` is the source: spec lists of boxes (rounded,
tapered), drums, cones, eggs and rings, and helpers that lay slits, studs and trim along a
curved surface. The pipeline (Studio MCP + Blender + Open Cloud):
1. In Studio, run `scripts/export_blueprints.lua` through the MCP, fetch the JSON in slices
   and join them: `python scripts/join_blueprints.py <slices…>` → `blender/out/blueprints.json`.
2. Look before you upload: `blender.exe -b --python blender/preview_armor.py -- blender/out/blueprints.json --sheet figures`
   (or `--sheet heads | torsos | legs`, `--sets IronCrow,Blackguard` for front / side / back) on
   an R6 mannequin with the starter colors.
3. `python scripts/build_armor.py <sets / piece ids>` bakes one mesh per color region and uploads
   it (`--upload-only` resumes); asset ids stay in `blender/out` (gitignored).
4. Run `blender/out/armor/assemble_armor.lua` in Studio edit mode (`Build ▸ MeshArmor`), then save.

**Hoods and helmets never let the head through.** A solid egg round the head always has the face
(or a cheek) poking out of it, so a hood is an **open hood** (`openHood` in `Build ▸ Armor`, the
Builder's `"cowl"`): a hollow egg the head sits *inside*, the face showing through its opening, a
dark lining in its shadow, and `rim()` points round the opening for a trim, a roll or a crown of
leaves. A bandana or an arming cap is a `skullcap`, which follows the head with a clean hem. Check
any head piece before baking: `blender.exe -b --python blender/audit_heads.py -- blender/out/blueprints.json`
lists every piece where the head shows through (cloth or steel just under the skin), worst first,
and `preview_armor.py --heads A,B` renders close-ups (front, three-quarter, side, back, from below).

## Weapons (26) and blueprints

The roster covers the Mordhau / Chivalry armory: swords (Shortsword, Arming Sword, Longsword,
Greatsword, Zweihander, Executioner's Sword, Estoc, Rapier, Falchion, Kriegsmesser, Cleaver,
Rondel Dagger), blunt (War Hammer, Flanged Mace, Morning Star, Maul), axes (War Axe, Battle
Axe, Bardiche) and polearms (Spear, Pitchfork, Halberd, Poleaxe, Glaive, Billhook,
Quarterstaff). Each Tool holds only its three scripts in the repo; its BODY (Handle, Hitbox,
blade / haft / head, skin-tintable parts) is built from `Build ▸ Weapons` when the Tool has no
Handle, and a display copy lands in `Cosmetics ▸ Weapons` for the menu mannequin. Stats
(speed, reach, damage per attack, one- or two-handed, weight) live in each Tool's `Config`;
unlocks and prices in `Catalog ▸ Weapons`; both are generated from `scripts/gen_content.py`.
**Every weapon has a niche:** heavier weapons slow you a little while held (`SpeedMult` 0.90–1.04;
two-handers used to *speed you up*), and `ARMOR_PEN` is the share of the target's armor a weapon
ignores: War Hammer and Maul 60%, Mace 50%, Morning Star 45%, Poleaxe and Estoc 40%, Rondel
Dagger 35%… edges 0. The Shortsword is the quick sidearm (`SPEED_MULT` 0.55). At startup
`LoadoutServer` publishes every weapon's numbers to `ReplicatedStorage ▸ WeaponStats ▸ <id>`
(attributes: Reach, Swing/Stab/Overhead Damage · Windup · Cost · Block (what a held guard pays),
HeadMult, Move, ArmorPen, TwoHanded, Secondary, Description) and the Armory shows them as
bars against every other weapon.
**Every weapon has its own look** (`blender/weapons.py`, previewed with `blender/preview_weapons.py`,
built with `python scripts/build_weapons.py all`): blades are beveled with bright ground edges
and dark fullers; the Longsword has flared quillons and a scent-stopper pommel, the Arming Sword
a wire grip and a wheel pommel, the Greatsword parrying lugs, the Zweihander a flamberge blade,
parrying hooks and side rings, the Executioner's Sword a square end pierced with three holes,
the Estoc a ring guard, the Rapier a swept hilt with a knuckle bow, the Rondel Dagger its two
discs, the Falchion a swelling clipped blade, the Kriegsmesser a nagel and riveted grip scales,
the Cleaver a butcher's chopper. Axes are cut from real outlines (a bearded War Axe, a crescent
Battle Axe, the Bardiche's long blade on two sockets) and ground to an edge; hafts carry
langets, rivets and butt spikes; the War Hammer and Poleaxe have crowned faces and curved beaks,
the Mace gothic flanges, the Morning Star a ring of spikes, the Maul an iron-banded block; the
Spear and Glaive wear tassels. Every weapon keeps the size its Hitbox was tuned for.
Armor sets work the same way: `Build ▸ Armor` has a blueprint for every release set in
`ServerStorage ▸ Armor` (Road Levy, Marsh Wardens, Harriers of the Coast, Night Hunters ·
Sellswords, River Guard, Gilded Court, Wolf Company · Tourney Knight, Iron Crow, Blackguard,
Knights of the Sun), for the nine earned pieces (Wolf Pelt Hood, Champion's Great Helm…) and
for Knight, Gambeson and Peasant. They are the source of the armor meshes (see *What each set
looks like* above) and the fallback wherever a set has no model; `Build ▸ Body` has every hair
and beard in `Catalog ▸ Body`, baked the same way (`python scripts/build_armor.py Hair Beard`):
hair is a bowl spun to the round head's own profile (`Builder.lathe`) with locks, a fringe, a
tied tail, a topknot, a monk's ring, a crest, a curly mane or a crown of braids laid on it;
beards hang below the mouth and climb the cheeks, with a moustache, braids and brass beads or a
forked point. See [CONTENT_GUIDE.md](CONTENT_GUIDE.md) §0 and [RELEASE_CONTENT.md](RELEASE_CONTENT.md).

## Making a new weapon

Duplicate any weapon's three scripts into the new Tool and edit **only `Config`**:
animations, `ATTACKS` (sided, each with `kind = "slash"` or `"stab"`), `REACH`, `SPEED_MULT`,
`TYPE_SPEED`, `RECOVERY`, `TWO_HANDED`, `SECONDARY`, its weight (`SpeedMult` / `ClunkMult`,
1 = no effect) and `SOUNDS`. Any key from `CombatServer.DEFAULTS` or `CombatClient.DEFAULTS` can be overridden
there too (e.g. `PARRY_WINDOW`, `HEAD_DAMAGE_MULT`, `KEYS`, `TRAIL_COLOR`).

The Tool needs a box `Part` named `Hitbox` whose longest axis runs along the blade.
Optional: a `workspace.NPCs` folder of humanoid models — kicks, ragdoll, and bleeding
work on them too.

## Controls (all rebindable in the ⚙ on the spawn menu; right mouse is always block)

**LMB swing · scroll up stab · scroll down overhead · X underhand** — hold **LeftAlt** for the
left-side version (default side Right; both are settings) · **Q feint** · RMB block (feint-to-parry
during windup) · G kick (works unarmed too) · LeftShift sprint (forward / forward-diagonal only) ·
**F dodge** (or double-tap A / D / S; a ~2-stud sidestep, side or back, 10 stamina) · **Space
jump** (a short ~2-stud hop, 6 stamina; also stands you up from a seat) · LeftControl/C crouch ·
**Z first / third person** (no scroll zoom any more) · V pick up a weapon · Tab leaderboard ·
**B emote wheel** · **T frees the mouse** (toggle: click the screen, the gift, the boards; the
camera holds still and you turn the way you walk; any attack, block, kick or dodge locks it again
with the camera swung behind you, so a free mouse can't whip a swing round). Walking backwards is
35% slower and sideways 20% slower — dodge to reposition fast. Settings saved before the jump existed had dodge on Space; they move to F on load.

Binds take keys, left / middle mouse, scroll up / down. Roblox does not expose Mouse 4 / 5 to
games — bind them to a key in your mouse software (e.g. Mouse4 → X) and bind that key here.

## Attack input: sides, modifier, scroll wheel

Four inputs — **Swing, Stab, Overhead, Underhand** — each with a left and a right version. Which
side you get is a setting (⚙ → Keybinds → *Attack side*):

- **Modifier** (default): always your *Default side* (Right); hold the *Opposite side* key
  (LeftAlt) for the other.
- **Mouse**: the way your mouse was moving when you pressed. Still mouse = alternate. The
  Opposite-side key flips whatever the flick gave you.

## Attack animations, timing, morphs and combos

**Drawing takes a moment** (`CombatServer` `DRAW_TIME` 0.35 s, `DRAW_TIME_2H` 0.5 s): a weapon just
taken in hand can't strike until it's out, and the recovery a swing owes follows you to the next
weapon (the character's `ActionLock`, set as a weapon leaves the hand), so switching weapons is
never a way round a recovery. A press in a draw's last 0.3 s goes off the moment it's out.

Every attack is `<Side><Type>` (Left/Right × Swing/Stab/Overhead/Underhand) with **one clip**:
`anim`, the swing. Its first frame is the loaded pose. **The windup is a blend**: the clip fades
in frozen on that first frame over `WINDUP` seconds — from idle, from a block, from another
windup on a morph — and that fade *is* the wind-up motion. No windup clips to make. Then the
clip runs: the active phase is its length (the server reads it with
`KeyframeSequenceProvider`, so a client can't lie). Windup, active and `RECOVERY` all divide by

    speed  ×  TYPE_SPEED[type]  ×  SPEED_MULT  ×  GameConfig.TEMPO.swing (1.12)      (× RIPOSTE_SPEED after a parry)

so morph / feint / chamber windows are the **real** windup at that weapon's tempo. `INPUT_GRACE`
(0.08 s) lets a morph/feint that arrives just after the windup ended still count if the blade
hit nothing yet. An attack whose `anim` is still `rbxassetid://0` can't be selected.

- **Morph** — a different attack pressed during the **windup**: the current loaded pose blends
  into the new one over a full `WINDUP` at normal speed (the morph's cost is that time). Not into
  the mirror of the same attack (RightSwing → LeftSwing), nor between overhead and underhand —
  too far (`MORPH_NO_MIRROR`, `MORPH_FORBID`).
- **Combo** — a different attack pressed during the **swing**: when it ends, the next swing
  fades straight in over `BLEND / speed` — no wind-up, no recovery between.
- **Blocked / parried / chambered** — the blade freezes for the clang, then eases back to idle
  over `RECOIL` instead of swinging through.
- **Hit** — when a hit interrupts you (or lands while you're idle / blocking) the optional
  `HIT_ID` flinch clip blends in from wherever the sword is and back out.
- **Feint** — eases back to idle over a blend. Same attack twice is denied.

## Combat rules 2 (the fencing layer)

- **Morph**: press a different attack during your windup (right swing → stab…) to switch to it.
  `MORPH_COST` stamina, `MORPHS_PER_SWING` per swing, not past `MORPH_CUTOFF` of the windup; the
  new attack keeps at least `MORPH_MIN_WINDUP` × its own windup. The windup animation swaps too.
- **Chamber**: be in the **windup of the mirror of their attack** while theirs is in its swing —
  same type, opposite side (their `RightOverhead` → your `LeftOverhead`, their `LeftSwing` →
  your `RightSwing`); any stab chambers any stab; an unsided attack matches either side. Facing
  them, windup started within `CHAMBER_WINDOW`. Their swing dies (no stun — for `CHAMBER_PARRY_WINDOW` they can
  guard instantly and parry or re-chamber your counter), your
  windup is cut to `CHAMBER_RELEASE` (0.2 s) — and you may **morph the chamber** into anything
  in that time, whatever the cutoff (`CHAMBER_MORPH_FREE` also resets your morph count). Sparks
  + the white edge flash mean you got it.
- **First hit wins** (`FLINCH_ONLY_WINDUP` false): a clean hit stops the target's swing in its
  windup *or* its release — their swing's token dies, so their own hit a moment later is thrown
  away. A hit during their recovery leaves it alone (cancelling it would give them their turn
  back sooner). Kicks stop anything. **Bosses** (attribute `Boss`: Horde / Siege warlords) shrug
  off hits and kicks and swing straight through: read them and parry. Set `FLINCH_ONLY_WINDUP`
  true for the old rule (committed swings trade).
- **Reeling** (`HIT_STUN`, 0.5 s, the same for every weapon): after a clean hit the victim can't
  attack or kick for that long (they can still block and parry). A slow weapon that lands is back
  on guard before a counter-swing can reach it; a quick one can't lock anyone down. Bosses ignore it.
- **Stamina ledger: fighting well pays, flailing and turtling cost — and a long fight wears
  everyone down.** The windup always costs `staminaCost` (× the armor's `StaminaCostMult`);
  **every enemy a swing hits refunds the cost plus `HIT_BONUS` (2)** — a landed blow about breaks
  even (cut through three = three refunds); **a kill gives back `KILL_REFUND` (20 %) of your
  max** (the HUD says KILL +N); a whiff costs `MISS_COST_MULT` (0.6) × the cost extra; a blade that hits
  a **wall / floor** stops there (clang, `WALL_RECOVERY`) with no penalty and no refund. Kick: land =
  `KICK_REFUND` back, whiff = `KICK_MISS_COST` + longer recovery, kick a wall = neither. A dodge
  that makes a swing miss you refunds `DODGE_REFUND`. Regen (13/s × the weight's `RegenMult`)
  runs at full rate 1.6 s after the last combat event and at `COMBAT_REGEN` (20 %) inside that:
  misses, held blocks and feints drain you, and even clean fighting slowly does.
- **Parries are free and pay out** (`PARRY_COST_MULT` 0): each parry refunds the attacker's swing
  cost (at least `PARRY_REFUND`, 5), growing by `PARRY_STREAK_STEP` (50 %) per parry within
  `PARRY_STREAK_WINDOW` (2 s) up to `PARRY_STREAK_MAX` — 1vX parry-parry-parry grows each time; the
  HUD word and the sparks grow with it. Holding block pays the full `blockCost` every hit **and**
  `BLOCK_HOLD_DRAIN` (5/s) while it is up (the turtle tax), and can't attack while up.
- **Exhausted**: a swing needs its `staminaCost` in the bank and a kick needs `KICK_COST`; at 0
  stamina you can only guard and walk (the HUD says EXHAUSTED). No more stabbing on empty.
- **Health regen**: `CharacterSystems` heals 2.5/s once stamina is full, you are not blocking,
  attacking or sprinting, and nothing has happened for 5 s — never while bleeding out. Roblox's
  own 1 %/s regen is switched off (an empty `StarterCharacterScripts ▸ Health`). Health never slows you
  (`WalkSpeedGovernor` `MIN_HEALTH_F` 1): clutch at 5 HP at full speed.
- **Being parried doesn't stun you** (`PARRY_PUNISH_STUN` 0): your swing dies and eases back
  (`RECOIL`), and for `PARRIED_GUARD_WINDOW` (0.8 s) your guard comes up at once with a fresh parry
  window, cooldown or not — so the riposte can be parried or chambered right back. The riposte is
  the parrier's edge: for `RIPOSTE_DURATION` (1.2 s, i.e. the next swing) windups are `RIPOSTE_SPEED`
  (1.6×) quicker; a parry is a `PARRY_WINDOW` (0.4 s) guard.
- **Perfect parry**: a guard raised within `PERFECT_PARRY` (0.12 s) of the blade landing pays
  `PERFECT_BONUS` (6) more stamina, throws bigger sparks, reads PERFECT PARRY, punches the parrier's
  camera (`PerfectParryAt`), and takes away the attacker's instant re-guard (no
  `PARRIED_GUARD_WINDOW`): the riposte bites. Reading the swing late beats guessing early.
- **Contact feel** (client, `CombatClient` + `CameraRig`): every hit holds the swing for a beat
  (`HITSTOP_HIT`), two-handers and polearms `HEAVY_HITSTOP` (1.6×) longer; the killing blow
  (`KillConfirm`) holds longest (`HITSTOP_KILL`) and snaps the view in (`FOV_PUNCH`, scaled by the
  Shake setting). The victim's HUD flashes a red arc toward where the blow came from (`HitArcs`).
- **Parry chain**: after a *successful* parry you can re-guard instantly with a fresh parry window
  for `PARRY_CHAIN_WINDOW` (1.5 s) — no `BLOCK_COOLDOWN`, no `PARRY_RETRY`. A guard that comes
  down without having parried **breaks the chain** (and the streak): back to the normal cooldown. Riposte (`FastUntil`) makes your **windup** `RIPOSTE_SPEED`× quicker; the swing
  itself plays at normal speed. A riposte **costs no stamina** and, if it lands, hits
  `RIPOSTE_DAMAGE` (1.25×) harder; the window is `RIPOSTE_DURATION` 1.5 s. **You can see it** (`RiposteCue.client`, from `RiposteUntil` /
  `RiposteLen` / `RiposteSpeed` in the shared clock and `RiposteTick`): a gold flash round the
  screen as it opens, RIPOSTE · STRIKE NOW under the crosshair with how much quicker and a bar
  running out with the window, RIPOSTE! and a gold trail as you swing into it, RIPOSTE LANDED +25% (and
  a flash) held a moment when it lands (`RiposteHitTick`); anyone's blade
  (bots too) glows gold while their window's open, so you know to guard.
- **Walls**: hits are rejected when the line from your head to the hit point passes through solid
  geometry (`WALL_CHECK`), so nobody gets stabbed through a wall.
- **Per-region damage**: `damage` is a number (× `HEAD_DAMAGE_MULT` / `LEG_DAMAGE_MULT`) or
  `{head=, body=, legs=}`.
- **Animations fit the rules** (`FIT_ANIMS`): each attack's optional `windupAnim` is stretched to
  its windup, the release anim to active+recovery — so a morph, riposte or chamber re-times what
  you see. Attack names are `<Side><Type>` (see a weapon Config).
- A whiffed kick recovers `KICK_MISS_EXTRA` longer. Spawn protection: a `ForceField` for
  `SPAWN_PROTECT` s (LoadoutServer); attacking, kicking or blocking ends it early.

## War: the massive battle (`Game ▸ Modes ▸ War`, `Game ▸ WarMap`, `War.client`, `ReplicatedStorage ▸ WarFX`)

The Play screen's first tile (DOORS.War, matchmade public servers, 24 players). Two armies on a
battlefield built fresh each round, players and bots side by side (`botFill` 32, `fillAnywhere`),
siege engines, archers and battle-mages, and the rest of both armies clashing out on the flanks.
- **The line**: five banners between the two camps. A side takes a banner by standing at it with
  more of its own than the enemy (up to three more count: faster together), but only the banner
  next to its line, so the fight moves along the field as a front (`War:canTake`, `frontFor`).
- **Reinforcements**: each side starts with `tickets` (300); every fall costs one, players and bots
  alike; holding more banners bleeds the other side a ticket per banner more every 4 s (all five:
  faster). None left: lost. At the bell, more left wins (15 minutes).
- **The day goes on** (`War:start` / `tick`): the sun moves over the battle. A morning field
  (ClockTime 6–10) brightens an hour and a half; an afternoon one wears on towards golden hour
  (up to 2.2 hours, never past 17.1), long shadows and a warm sky by the bell. A dusk or a night
  theme stays as it was tuned.
- **The line is breaking** (`War.client`): the first time a side's tickets fall under 60, a horn
  and the call on every screen (IRON IS BREAKING: ONE LAST PUSH! for the side winning, HOLD THE
  LINE! for the side breaking), and the war drums quicken.
- **A champion takes the field** (`War:champion`, five to seven minutes in): the side that's behind
  (a coin toss when even) sends its champion from its camp: Sir Aldric the Unbroken for the Crown (the Training Yard's own master of steel),
  Grimwald Ironhand for Iron, a Champion bot in heavy plate with a great blade, a head taller than
  the rest, 900 health and 120 more for each enemy player; he pushes the front with his army, his
  name over his head in his side's colour (up to 400 studs) and his health on the boss bar. Every
  screen puts his name up on the bars (`BossEntrance.client`: YOUR / THEIR CHAMPION TAKES THE FIELD;
  the camera stays yours in a battle). Cut him down and his side loses 25 tickets (Round ▸
  WarChampFell: THE CHAMPION FALLS, a roar).
- **The weather turns** (`War:start` / `tick`, `War.client`): on a clear or rainy field (not
  Sunreach's desert, Frostmere's snow or Ashvale's ash), 40% of battles see the sky open partway
  through (4 to 9 minutes in): clear to rain, rain to a storm. Round ▸ WarSky carries it; every
  screen hears a long roll of thunder (a flash of lightning for a storm), the new weather thickens
  in over 8 seconds, and THE HEAVENS OPEN / THE STORM BREAKS comes up big.
- **Coming in**: at your foremost banner nobody's attacking, else at the camp, in waves
  (`waveSpawn` 8). Bots: most push for the banner their side is taking, some hold one under attack
  (`War:botOpts` goal). Their number follows the server's frame rate (`War:botTarget`, read by
  BotFill): fewer when frames run long, back up when they're quick.
- **The engines** (`Game ▸ Engines`, shared with Siege; drawn by `Engines.client`; each side on its
  own beat after the first 20 s):
  **trebuchets** (two a side, behind the camps: a red ring where the shot lands, then the blast:
  heavy damage and thrown back); **archers** (a company on each flank: a volley into a knot of
  enemies; a raised guard or a roof overhead saves you); **battle-mages** (a barrage now and then:
  a line of meteors across the enemy's front, chain lightning onto their fighters, or a frost
  that slows them). Engines only hurt the other side.
- **Ballistae you man**: two a side behind its second banner (WarMap `layout.ballistae`, the made
  Ballista or one of timber). Hold E: it swings onto the nearest knot of enemies in front of it
  and looses a bolt that goes through up to three of them (85 / 70 / 55, thrown back; the kills
  yours); six seconds to wind. Its prompt shows only to its own side, and to nobody while it winds
  (Prompts.client: a prompt's `Team` and `Ready` attributes).
- **Pay**: everyone of a side standing at a banner when it falls to them earns `war_banner`
  (Catalog ▸ Economy: 20 Marks, 45 XP each), on top of the round's usual (round, win, kills);
  War's kills count on the season's kill board like Warfront's.
- **The engines' kills on the feed**: "Crown Trebuchet", "Iron Archers", "Crown Battle-Mages"
  (Engines sets LastHitByName / LastHitWith on whoever it hurts).
- **On your screen** (`War.client`): reinforcements (number and bar) and the clock, the five
  banners as chips in their holder's colour filling as they swing, the one your side is fighting
  for ringed in gold; at a banner: TAKING · HOLDING · LOSING IT! · CAN'T TAKE IT YET; big calls
  when a banner falls; warnings when something's coming down on you (VOLLEY: raise your guard ·
  TREBUCHET · METEORS · LIGHTNING · FROST). On the field: each flag in its holder's colour, a ring,
  a beam over the banners being fought for. Your first spawn of a round: a few seconds' flight
  over the field with THE BATTLE OF … (any key skips).
- **The battle's end**: the camera rises and circles slowly over the field, the winners' horns
  sound and their regiments loose and cheer; the result board and the class screen hold back five
  seconds for it (`_G.BoardHoldUntil`, read by Scoreboard and LoadoutMenu).
- **The armies on the flanks** (`ReplicatedStorage ▸ WarCrowd`, client only: never fighters,
  nothing replicated). Every soldier is a copy of the game's own dressed soldier (Dresser through
  PreviewRig: a real armour set per side and kind, the side's colours, a real weapon and shield),
  moved limb by limb: they stand, march, run at a charge, fight face to face along the line (swing,
  guard, lunge), loose and cast, cheer, fall, and are thrown through the air by blasts; the fallen
  stay where they fell (a dozen to a regiment, then the oldest stands up as a fresh man).
  Three lanes a flank (foot, pikes, knights; the first just past the stakes), archer companies,
  battle-mages, deep reserves behind each side, and each army's host drawn up in great blocks on
  the flanks by its camp (`still`: never marching, each man on the ground under him; placed once,
  they cost nothing a frame). Levels of detail by rank: full (every piece,
  ~25 parts: the front rank of the nearest lane), lite (helmet and body armour, the main piece on
  each limb, weapon, shield), mass (shell, helmet, bare limbs, weapon). Every limb is posed only
  near the camera; further off men move as one piece in a cached pose; out of sight they only
  march; a small drift isn't a march (hysteresis, 2.6 studs); mid regiments update ~6 times a
  second, far ones ~3. Each regiment keeps its own clock (they don't all land on one frame) and a
  frame that has moved `WarCrowd.BUDGET` parts (900 × SCALE) puts the rest off a frame or two, so
  a whole army advancing never spikes. The second rank is lite behind a full front, mass behind a
  lite one. Measured on Redfield with the camera on the player: about 15,500 crowd parts, 1.1–3.3
  ms a frame (before the budget: spikes of 12–15 ms on a surge), 45–48 fps in Studio play (server
  and client in one process; a phone gets 60 % of the men). In a heavy frame the crowd folder's
  `Busy` attribute lists which regiments were moving and why.
- **Night battles**: on a night map (Lighting's clock, `WarCrowd.night()`) every fourth man of the
  second rank holds a burning torch up (`torches = true`), so the lines show as firelight in the
  dark (War, Siege, the warfields), and every volley is fire arrows, streaks of flame across the
  dark (`WarFX.volley`'s `fire`, by default at night: the engines' volleys too).
- **Arrows overhead**: a volley whose arc passes over you (and isn't coming down on you) whistles
  and hisses as it goes over (`WarFX.volley`, WarAudio ▸ ArrowsOver), in every mode with volleys.
- **The steel up close**: within ~55 studs of a fighting line, the men fighting in its front rank
  ring out a few times a second (a clash, a parry, a block, a blow on plate: the fight's own
  SoundBank) from where they stand, on top of the din of the melee; a man going down within 50
  studs cries out and hits the ground with an armoured thud.
- **A war cry answered**: do the War Cry or Cheer emote in any battle with armies (War, Siege, the
  warfields, the Horde's host) and your side's regiments within 140 studs raise their weapons and
  roar back (`WarCrowd.answer`, from `Cosmetics.client`).
- **A banner taken**: every regiment of the side that took it raises its weapons and the army's
  roar rolls over the field.
- **Dust**: a regiment at a run kicks up a trail of dust behind it in the ground's own colour (snow,
  sand, mud, earth).
- **The set-pieces**: the opening CHARGE (horns, drums, both lines run and crash, dust, a shake,
  men knocked flying); every 40–90 s a lane pulls apart and charges again; trebuchet fire on the
  flanks throws men through the air; volleys drop them; the cavalry ploughs through a flank.
- **The atmosphere**: dust haze drifting over each lane's melee, columns of smoke (a burning wagon
  at each camp, villages burning beyond the hills), the din of each flank's melee from where it is
  (WarFX.loop3D), the roar of both armies, war drums (WarAudio: Melee, Roar, Drums).
- **The battlefields** (`WarMap.THEMES`, each with its own lighting, atmosphere and weather):
  **Redfield** (wheat fields, a farming village and windmill), **Ironridge** (a ruined fort on a
  rise, outcrops, rain), **Frostmere** (a frozen lake, snowy pines, snow), **Ashvale** (burning
  farmsteads, cracks of fire, embers at dusk), **Kingsbridge** (a river across the field, two
  stone bridges and a ford, a chapel), **Nightfall** (a moonlit battle: torches lining the field,
  a burning watchtower, standing stones), **Sunreach** (a desert valley: a ruined temple of
  sandstone columns, obelisks, dunes), **Stormvale** (a storm over a ruined abbey: broken nave
  walls and arch, pillars, a graveyard on both sides of the road), **Duskmoor** (purple heather at
  golden hour: a ring of cairns, a beacon burning on the tallest), **Mistmarsh** (a fog-bound
  marsh at dawn, you see 40 studs clear: a broken stone causeway down the middle, standing water
  and reed beds, a chapel half sunk into the bog with its tower leaning, mossy stones),
  **Amberwood** (an autumn wood's edge in the late gold light: a line of red, rust and gold oaks
  down each flank, fallen leaves drifting down and lying in drifts, an orchard round the second
  banner, a half-timbered hunting lodge round the third, a woodcutters' camp of stacked logs and
  stumps round the fourth; its sky can turn to rain).
- **The litter of earlier fighting** on every field (`debris` in WarMap): dropped shields in both
  sides' colours, broken spears, clusters of arrows stuck in the ground leaning the way they came,
  fallen banners, helmets; thickest round the banners; nothing solid or queryable (looks only).
- **Made props** (ServerStorage ▸ WarProps, Studio-only, generated): **Pavilion** (each camp's
  command tent), **SiegeTower** (two parked before each camp, ramps towards the enemy),
  **Ballista** (two at each camp's corners), **Barricade** (spiked logs before the camps, and cover
  beside banners 2 and 4). `Game ▸ WarProps.place` scales each to a height, sets it on the ground
  and turns it by its own `Yaw` attribute (degrees); a missing one is left out. Terrain ground (`K.terrain` with `fast`: no read-back of
  the surroundings), a corridor 210 wide fenced with stakes (and an unseen wall), banners named
  for the theme (THE VILLAGE, THE OLD FORT, THE FORD…). Vote pictures: ReplicatedStorage ▸ MapShots.
- **Performance**: the crowds (arrows, raindrops, soldiers, horsemen, flying stones) live under the
  camera (WarFXCrowd: drawn, never in the physics world) and are moved in one bulk move; a
  regiment's men move only when they must (all while it marches, the front two ranks while it
  fights, none while it stands; out of sight it only marches; far ones 5 times a second).
  Measured in Studio: about 600 soldiers on the flanks, 34 bots and the engines at 53–59 fps.
  Bots are the server's cost (a humanoid each, reflexes every frame): War fields 32 by default and
  lets the frame rate take it down (a stress test at 46 brought Studio's shared server to ~24 fps;
  the cap stepped 46 → 38 → 34 → 30 on its own). A bot no player is within 90 studs of watches
  every third frame and thinks five times a second, not ten (Combat ▸ Bots).

## Siege engines, volleys and battle-mages for any mode (`Game ▸ Engines`, `Engines.client`)
`Engines.new{sides = {A = {trebs, archers, mages}, B = …}, target = fn(side), beats, grace, power,
alive}` and `:tick()` from the mode: each side fires on its own beat, only ever at the other side.
Trebuchet: a red ring (3.4 s) then the blast (thrown back). Volley: a raised guard (`Blocking`) or a
roof overhead spares you. Barrage: meteors across the enemy's front, chain lightning onto their
fighters, or a frost that slows (`SpeedMult_Frost`). A mode's `target` returning nil holds fire.
`Engines.client` draws every shot (ReplicatedStorage ▸ WarEvent) and warns you when one's coming
down on you (TREBUCHET / VOLLEY: raise your guard / METEORS / LIGHTNING / FROST); `_G.EngineShout`.
Used by War (everything) and Siege (below: power 0.6).

## Crates and barrels break (`Game ▸ Breakables`)
A map's crates and barrels (MapKit's `crate` / `barrel`: the war camps, the Courtyard, the
dungeons' storerooms) give way to a blade: a blow that hits the world on one
(`CombatServer.worldHitHooks`) bursts it, planks or staves flung out and tumbling, a crunch of
wood, a puff of dust; a crate stacked on it comes down with it; its bands and hoops go too. Ninety
seconds later it's back where it was (if the map's still the same). Not Deadvault's searchable
containers (those live in workspace ▸ LootDrops). Started once by `GameServer`.

## The cinematic grade (`CinematicGrade.client`)
Over every open-air map, on your screen only, a film look: more contrast (+0.13), the colour
pulled back (-0.12) from Roblox's toy greens and blues, a breath darker (-0.02), the light warm,
and the sun's rays visible through the haze by day (SunRays 0.06, spread 0.3). Fair-weather clouds
drift over every open-air map (one `Clouds` under the Terrain: Cover 0.5, Density 0.55), eased in
a little at a time and left alone while a weather has the sky (`WarFX.weatherKind()`; the weather
puts back what it found when it ends). None over the caldera (Dragonfall) or indoors. Off in the dungeons (DungeonMood grades those: The Depths, Deadvault,
Plague Night, the Undead invasion) and the Gilded Rat, where the place's own rays come back.

## Shell-shocked (`ReplicatedStorage ▸ Hearing`, rung by `WarFX.blast`)
A trebuchet stone or a battle-mage's fireball landing right by you (within 34 studs of a big blast,
20 of a small one) leaves you half deaf for a few seconds: the world goes muffled and quieter, a
thin ringing fills your ears (`WarAudio ▸ EarRing`, Studio-only), your eyes swim, and it all comes
back. The harder the blast, the longer (2 to 5 seconds). The score plays on. Every sound in
workspace is routed through `SoundService ▸ World` (a SoundGroup, set up by `Hearing.client`) so
its equaliser can do it; sounds already in a group stay in theirs. Scaled by the Screen shake
setting: shake off, deafness off.

## Houses and castle stone (`Build ▸ MapKit` K.house, K.wall, K.tower)
Every cottage in the game (War's villages, the Crownlands, Stormwatch, the Horde's town, the
Courtyard's backdrop) is half-timbered: plaster walls on a cobbled plinth, the dark frame standing
proud of them (corner posts, studs bay by bay, a brace in each end bay and either side of the
door, the plates), shuttered windows, a framed door on a stone step, a clay-tiled roof (snow where
its colour is snow-white) under a ridge beam, and on about half of them a chimney with a thread of
smoke. Only the walls, roof and gables collide; the rest is dressing (no collision, no queries, no
shadows), about 45 parts a house.

Castle stone is rubble masonry (`K.wall` and `K.tower` default to Cobblestone in the wall's colour,
the footing the same in its darker stone), and towers' spires are shingled (RoofShingles;
`opts.roofMaterial` to change it). The maps saved in Studio (ServerStorage ▸ Maps) were converted
by the same rules on 2026-10-17, and their old houses rebuilt in place.

## Night windows (`NightWindows.client`)
After dark (ClockTime before 5.8 or after 18.6), about two in three of the map's windows (parts named
`Window`: K.house's and K.tower's) glow with warm light, picked by where each stands so every
screen agrees, each spilling a little light onto the ground (a PointLight; not on phones). They go
dark again at dawn (Plague Night's sunrise). The Prologue's Stormwatch, Plague Night, the Invasion
and the night warfields.

## Weather (`Weather.client`, `GameConfig.MAP_WEATHER` / `MODE_WEATHER`, drawn by WarFX)
Rain, storms (rain, lightning, heavy cloud), snow, embers and petals on the maps that have them:
snow on Frostgate, Rimeholt and Frosthollow; storms on Stormhold and Stormbreak; rain on Mistmoor,
Marshfen, Mistbridge, Blackwater; embers on Emberkeep, Ashenford, Cinderfall; petals on Blossomgate
and the Rose Court; Plague Night is always a storm, the Undead invasion rain. A mode's own wins
over its map's; War and the Prologue draw their own; none in the Hub or the dungeon game. Drops
stop under a roof. One table to change it, no Studio work.
**Banners in the wind** (`BannerWind.client`): every banner, pennant and standard on a map sways
from its top edge on its own rhythm, its tips and trims swinging with it, harder in rain and
storms; only cloth within 160 studs, a dozen times a second.
**Cold breath:** where it's cold (snow falling, a winter-themed map, War's Frostmere, the Frozen
Depths) every player's breath shows, a small white puff from the mouth every few seconds,
quicker when running.

## The opening of a battle (`MatchIntro.client`)
Your first body of a round in Siege, TDM, KOTH, FFA, LTS or Horde: black bars, the camera flies from
the map's Shot1 down to just behind you, the mode and the map as a title and what you're there to
do (Siege: TAKE THE CASTLE or HOLD THE CASTLE by your side), a horn. About four seconds; any key
skips; never for a newcomer's first battle. War flies its own (THE BATTLE OF …). A duel on a
warfield gets it once a match: the flight over the battle down into the ring ("A DUEL IN THE
MIDDLE OF A BATTLE · WIN IT").

## The Courtyard's garrison (`CourtyardGuards.client`)
In the hub, on your screen only: sentries in the Crown's colours walk the Courtyard's battlements
(a stretch of each `Walk` part each, a long walk shared by two; spearmen and now and then an
archer), stopping at the end of their stretch to look out over the walls a while
(`WarCrowd:sentry`). Outside the walls, on the east field two companies of the garrison drill
against each other (charge, crash, fight it out, pull apart: `WarCrowd:lane`); on the west field
an archery range, a line of archers loosing at straw butts every 7–11 s. About 1,100 parts. The
training yard (Tiltyard) gets the sentries on its walls too.

## The rest of the horde (`HordeHost.client`)
In the Horde, on your screen only: out past each of the map's gates (`Spots ▸ HordeGate<n>`) and
past its edge (never where anyone can walk up to them), a block of the horde's soldiers stands
facing the camp (`WarCrowd:audience`: real armour in the attackers' colours, weapons in hand; at
night a few hold torches up). When a wave comes they roar and raise their weapons, a horn sounds
and the war drums beat until the break; every three waves beaten, the blocks grow deeper.

## The crowd in the stands (`ArenaCrowd.client`)
On any map with `Stand` parts (the Colosseum, the forge arenas, the Sandpit), in any mode but the
hubs, the stands are full on your screen: a row of unarmed commoners along the top of every
Stand part, facing the middle of the map (`WarCrowd:audience`), blue at one end and red at the
other with strays mixed in (up to 420; 180 on a phone). Anyone going down in the arena brings
most of them to their feet, arms up, with a roar (`WarCrowd:roar`); a fine parry or chamber there
(the parrier's ParryTick), a third of them with a shout (at most every 3.5 s); a round won, the whole crowd,
and petals thrown down onto the sand for six seconds (if the sky was clear);
between, the murmur of the stands and now and then a few of them shouting. Arms and all near the
camera; further off a cheering man is a cached arms-up pose bobbing. Measured in the Colosseum
(FFA, bots): 56–60 fps in Studio play, the crowd ~0 ms idle and ~2 ms in a roar.

## The battle beyond a team fight (`BattleAmbience.client`)
In Team Deathmatch, King of the Hill, Last Team Standing, Free-for-all and Kingslayer your fight is one corner of a bigger
battle, on your screen only: crows wheeling high over the field (`WarFX.crows`; War, Siege and the
warfields have their flocks too), columns of smoke rising beyond the map's edge (one with its fire
showing), the din of the battle beyond and an army's roar off to one side, a volley now and then
arcing high over the whole field to land far beyond it, a trebuchet's fire streaking across, a
distant horn. It reads the Map's `Centre` and `Radius` (MapLoader). War, Siege and the warfields
draw their own.

## Siege (Team Objective, after Chivalry 2)

**The war round it** (`Siege:startEngines`, from the map's spawns): the attackers' trebuchets far
back beyond their first spawns lob fire onto defenders near the objective; the attackers' archers
and the defenders' (up by their keep) loose volleys at knots of the other side near it. Gentler
than War's (power 0.6, trebuchets every 14–20 s, volleys every 16–24 s, after 25 s).
The attackers' camp is dressed for it (`Game ▸ WarProps`): siege towers, ballistae and a pavilion
round their first spawns, wherever the ground is open and level (into the map, so they go with it).
The field before the walls is littered with the fighting of the days before (`Game ▸ Litter`):
arrows thick under the walls, shields and spears along the road, a fallen banner or two, helmets.

**The day goes on** (`Siege:start` / `tick`, as War's): over the assault a morning brightens (up
to 0.8 h), an afternoon wears on towards evening (up to 1.2 h, never past 17.0) so the fires show
brighter as it goes; a dusk or a night keeps its tuned light.

**The battle round the castle, on every screen** (`SiegeEpic.client`, with `ReplicatedStorage ▸
WarCrowd` and `WarFX`; never fighters, nothing replicated):
- **The walls**: the defenders' archers line every open stretch of the front walk and loose on the
  field (on the men under the walls, on the attackers' line on a flank); the attackers' archers
  loose back at them.
- **The ladders**: under each stretch (clear of the defenders' spawns) a block of attackers waits
  with shields raised over their heads, two ladders against the wall and men swarming up them:
  at the top they go over (and fight on the walk a moment), now and then one is thrown off; every
  8–15 s the defenders hurl a pot of burning pitch down onto the shields.
- **The siege towers**: a tower rolls slowly up to each side wall (from 12–22 s into the round,
  about 50 s), pushed by its crew, docks with a crash and dust, and men climb up inside it and over
  onto the walk (a WarCrowd ladder through the tower). The server keeps one tower model under the
  map for the clients to copy (`Map ▸ TowerModel`, always streamed) and publishes where the side
  walls are (`C_SideX`, `C_SideY`, `C_SideZ`, `C_TowerYaw`).
- **The bailey**: once the gate is down, a melee breaks out on each side of the yard being fought
  over (defenders against attackers, 18 a side, wherever the ground beside the zone is clear and
  level: the stables, forges and stairs are kept out of it); when the yard falls its defenders are
  cut down and the attackers cheer.
- **The ram's crew**: six of the attackers under the ram's roof walk it up the road and lean into it
  when it stops (`WarCrowd:crew`, riding along with the ram's body); they cheer when the gate falls.
- **The flanks**: on both sides of the castle the defenders' sally fights the attackers' lines
  (foot against foot, pikes against knights): a charge with horns after 8 s, the crash, the lines
  wavering, pulling apart and charging again. The attackers' reserves wait beside their camp.
- **The castle burning**: two towers on fire at their peaks with smoke rising high, villages
  burning beyond the castle, stones and fire falling on its towers and walls every 9–17 s
  (blowing men off the ladders), dust over the melee and before the gate, the din of each flank,
  the roar of the armies, fire crackling.
- **The story follows the objective**: when the gate falls it bursts in a cloud of dust and
  splinters with a crash that shakes the ground under you (more the nearer you are), the attackers
  cheer, the archers on the
  walls are cut down (`WarCrowd:rout`), every ladder goes over, the reserves run for the walls and
  the sally is driven back under them; when the great hall is stormed its roof catches fire; at
  the round's end horns sound, the winners cheer and the camera rises and circles slowly over the
  castle a few seconds before the board (`_G.FinaleCamera` keeps the menu's cinematic off it, as
  War's finale does); once the fight is inside the walls, smoke from the burning castle
  drifts through the yard being fought over. The server's own engines land on the crowds too.
- **How it knows the castle**: a client streams the map in bit by bit, so the server reads it
  once (`Siege.describeCastle`) and puts it on the Map as attributes (`C_Gate`, `C_Spans`,
  `C_Span<i>`, `C_Towers`, `C_Roof`…; the header of `Modes ▸ Siege`). Any castle facing along z
  with a gate in `Objectives` and `Walk` / `Wall` / `Tower` parts in `Geometry` gets it.
- Measured: about 9,700 crowd parts, the crowd 1–2.5 ms a frame, 45 fps in Studio play (server
  and client in one process, 40 bots fighting).

The attackers take a castle stage by stage; the defenders hold until the clock runs out
(5 minutes to start). The mode's `attack` table (`GameConfig.MODES.Siege`) eases the map's stage
numbers for the attackers: `addTime` ×1.3, `ramSpeed` ×1.3, `gateHits` ×0.8, `captureTime`
×0.75, `champion` health ×0.75. Every
stage taken adds time (`AddTime`), sides swap each round, and the scores count rounds won. A map
lists its stages in `Map ▸ Objectives` (MapKit `K.objective`), each with a `Label` for the HUD:
- **Ram:** push the ram (`K.ram`) along its `Path` (`K.path`). It rolls while more attackers than
  defenders stand within `Radius` (13) of it, faster with more (up to 1.75×), and creeps (35%)
  when they're even. At the gate it swings its log every `Interval` s while the attackers hold it,
  `Hits` blows break the `Gate` (`K.gate`) and the doors burst inward.
- **Capture:** stand in the `Zone` (`K.zone`): attackers with no defender in it fill it in
  `Time` s (faster with more); attackers OUTNUMBERING the defenders in it still fill it, at the
  share they hold; a tie stops it; defenders alone push it back. The disc turns
  from the defenders' colour to the attackers'.
- **Slay:** the defenders' champion, a Champion bot in heavy armour (`Name`, `Weapon`, `Health`
  + `PerAttacker` × attackers), rises at `At` and fights inside `ArenaRadius`; kill him.
- **Spawns** carry `Side` (Attack / Defend) and `Stage`: a side spawns at its highest stage that
  isn't past the current one, so the front moves forward. Reinforcements come in waves (10 s).
- **Pay:** everyone of the attackers at an objective when it falls earns `objective`
  (25 Marks, 50 XP) at round end, as does the champion's killer.
- **HUD** (`StarterPlayerScripts ▸ Objectives`): ATTACK / DEFEND, the stage, a bar in the
  attackers' colour with what's happening there (PUSHING 3 v 1, CONTESTED, BATTERING · GATE 4 / 10,
  CAPTURING 63%), a pip per stage, a marker over the objective with its distance, and a banner
  when a stage falls ("THE GATE IS BROKEN · +2:30 ON THE CLOCK").
- **Frostgate** (`Build ▸ MapFrostgate`): a snowbound castle. Stage 1 pushes the ram from the
  camp up the road to the gatehouse, stage 2 takes the bailey (stables, forge, well), stage 3
  storms the great hall, stage 4 slays Jarl Hrolf at his throne. Snow falls; pines, ruins and a
  frozen pond on the field.

## Horde (after Mordhau's Horde)

**The sun goes down on the defence** (`Horde:start` / `startWave` / `tick`): on a morning or
afternoon map each wave carries the clock on towards dusk (up to 3 hours, never past 18.2, there by
the tenth wave), drifting over a few seconds as it starts; a dusk or night map keeps its light.

The HORDE door (PLAY board): you and your party against waves of bots, in a Friends server like
the Training Yard, **defending something** (`Game ▸ HordeObjective`): the camp's fire, the
caravan, or four villagers round a well, picked per map (`GameConfig.MODES.Horde.objectives`;
a map's own `Spots ▸ HordeObjective` part, with a `Kind` attribute, wins) and built from parts on
the clearest open ground near the middle (the centre of the Horde gates; at ground level, never
on a roof). It has `objectiveHealth` (1,500); a blow takes 12 (Squire), 18 (Knight), 26
(Champion), 60 (the Warlord) or 10 (an archer or a mage), and it's mended by 30% of its whole
between waves. **When it falls the horde has won.** You can see it wear: the fire sinks and
smokes, then goes out; the wagon smokes, burns, loses its canvas and slumps; the villagers fall
one by one (and get back up as it's mended). A bar floats over it ("DEFEND THE CAMPFIRE"), the
HUD shows its health while a wave is on, and a marker over it says DEFEND, or UNDER ATTACK! in
red, with how far it is. Alarms: when it's first hit after a quiet spell, and at half and a
quarter.
**Who the bots go for** (`Horde:engage`, through `Bots` `opts.engage` / `goal` / `sack`): a
player in a bot's face (within 12 studs), or one by the objective (within 55 of it) that the bot
can get to (40 studs; an archer or a mage 70). Anyone else (off round the map, or up on a roof
more than 7 studs above it, though archers and mages still shoot up) it leaves be and goes to
wreck the objective: it walks to its own place round it and strikes it every second and a half.
So kiting the horde round the map or camping on something saves nobody. A short breather, then wave 1 pours in through the map's gates (`Spots ▸
HordeGate1..n`): each wave bigger and better trained (Knights from wave 3, Champions from 6), a
**Warlord** every fifth wave. At most 10 bots are on the field at once; the rest wait their turn.
The fallen spawn again between waves (12 s), and nobody misses a wave for not pressing SPAWN:
when the break runs out, whoever is still on the class screen goes in as the class card they're
on (LoadoutServer `_G.AutoSpawn`, the screen's "Pick"). The standing are made whole for the next
one (`_G.MakeWhole`): full health, stamina and mana, burns and frost gone, and a body that lost a
limb, is bleeding or had its weapon knocked away is rebuilt where it stands. When everyone is
down at once the horde wins too. Players
can't hurt each other and bots don't hurt each other. Each wave beaten pays
everyone `wave` (15 Marks, 30 XP), each bot killed pays `kill`, and your best wave is kept
(`stats.hordeBest`). The HUD shows the wave, what you're defending and how it's holding, the foes
left and the countdown between waves.

Horde's maps are built for it: each has several ways in, and the horde walks in from a
little way outside (no one appears in the middle of the fight). Bots steer round trees, wagons
and walls in their way (`Bots ▸ Bot:steer`: a short look ahead at knee height, then the open side).
Rising ground isn't a wall: they walk up hills and ramps. Something low (under ~2.3 studs: a rock,
a log, a low wall) they hop over. Stuck for a second (`Bot:unstick`), they hop, then step aside
and work out a fresh path; paths (agent radius 1.5) go to open ground beside a goal that sits
inside something (a hill's middle under a windmill).

**The Wildwood** (`Build ▸ MapWildwood`, Horde): a clearing in a dark forest at dusk, a muddy
road through it and a merchant caravan that didn't make it: one wagon on its side, one on a
broken wheel, cargo and arrows everywhere, a campfire still going, fireflies over the grass. The
horde comes out of the trees down six trails and along the road both ways (8 gates).

**Ravenhold** (`Build ▸ MapRavenhold`, Horde): a ruined keep under the moon. The main gate's
doors lie smashed under a jammed portcullis, three breaches are knocked through the curtain wall
and the south-west corner has fallen in (5 gates, mist outside each). Inside: a roofless chapel
with its altar candles lit, a well, a gibbet on a dead oak, a little graveyard, a broken
colonnade and braziers.

**Stormbreak** (`Build ▸ MapStormbreak`, Horde): a palisade camp above a beach in a storm.
Three longships are run up on the sand and their crews come in at the sea gate between two
watchtowers, through the two beach-side gaps and round to the land gate (4 gates). Tents, a
smithy, a command tent and a bonfire inside; rain over everything.

**The Colosseum** (`Build ▸ MapColosseum`): a round sand arena behind a podium wall, four tiers of
stands, a two-storey arcade of arches with red and white awnings, and four gates where the horde
comes in. A dais in the middle is the King of the Hill's hill, and broken columns give cover.
Used by Horde, the Lists, Last Team Standing, FFA and King of the Hill.

**The Rose Court** (`Build ▸ MapRoseCourt`): a walled rose garden for duels, 46 × 46 studs inside
warm sandstone walls too tall to get over, its four arched gates barred with iron grilles. A
heraldic rose (red, white, gold, green barbs) is laid in the marble floor inside a ring of eight
columns under a pergola of roses; flowerbeds and climbing roses run along the walls, little
fountains and rose trees stand in the corners, a tower with a rose-red spire at each corner;
fountains, cypresses and trees on the lawns outside. Terrain under the court is paving (grass
blades grow up through thin floor parts). Used by the Lists and the Duel Yard.

## The adventures (the Play screen's second page)

PLAY has two pages now: the battles (page 1, as before) and **ADVENTURES** (the gold button in
the bottom strip; `GameConfig.ADVENTURE_ORDER`, `DOORS` with `party` or `matchmade`). A door that
isn't built yet shows COMING SOON. A `party` door reserves your party's own server (like the
Horde); a `matchmade` one finds a public server for that mode with room, else reserves one
(`HubServer` ▸ play). Studio has no teleports: PLAY switches the mode here, as always.

### Down in the dark: every dungeon floor (`Game ▸ Dungeon`, `DungeonMood.client`)
(Plague Night and the Undead invasion get the same dread: the grade, the edge, the drone, the whispers and groans, the
bats and apparitions; not the lanterns, which it gives its living itself, or the arrivals.)

The floors are dark: no daylight, a low ambient, close fog; the light is the torches' (pools on the
walls, 12 studs, darkness between; a raid's rooms have more of them guttered, a wisp of smoke over
cold embers) and the lantern every adventurer carries (`DungeonMood.client`: a warm light on each
player's chest, drawn on every screen). Dust drifts through the light round you, the colours go
cold (each theme its own grade), the screen's edges darken, a low drone sits under everything, and
now and then, somewhere in the dark behind or beside you, a whisper, an iron clank, a deep thud
from far below (WarAudio: Drone, Whisper, Gate, Impact). The monsters near you (within 70
studs) groan or growl now and then from where they stand: the dead groan, the rest growl
(WarAudio: Groan, Growl; a big one lower). A monster doesn't pop in: it takes shape out of the
dark over most of a second as grave-dust bursts up round it (some of the dead whisper as they
come); one of a second wave climbs out of a pit cracked in the floor (The Depths: More come).
**The dead lie**: a sleeping skeleton or ghoul isn't stood about with "z z" over it; on your screen
it lies on its back among the bones like the dead it is (its body hidden, a laid-down copy in its
place, its middle over where it really stands so a sneak attack still lands), and the moment it
notices anything it gets up, tipping up off the floor from its feet in a puff of grave-dust with a
groan. A fountain room's water trickles into its basin, louder as you come to it (WarAudio ▸ Fountain,
from its spout). **Every sound echoes** down here (`SoundService.AmbientReverb` by theme: the crypt's stone corridors,
the warrens' and the ice's caves, the manor's halls, the forge's iron halls, the drowned halls' wet
tunnels, the abbey's great nave; Plague Night an open plain); the Gilded Rat has a warm room's,
an arena's stands an arena's (`TavernAmbience`, `ArenaCrowd`); everywhere else, none.
**Getting out of Deadvault** floods the screen with warm daylight as the dread's drone falls
away, then it eases back. **Deadvault's last minute** comes down round you: deep rumbles coming closer together, the
ground shaking harder, grit pouring from the ceiling and stones dropping, your lantern stuttering;
in the last seconds, without a break.
Now and then, well ahead of you in the dark, a pale glowing see-through figure walks a few steps across your
path with a whisper and is gone (`WarCrowd.ghost`; never a fighter, only on your screen); or a
swarm of bats bursts out of the dark ahead and flits past over your head (`WarFX.bats`, WarAudio ▸
Bats). While a
boss lives within 90 studs, the grade turns darker, blood-tinged and harder, easing back when it
falls. Now and then a pair of eyes watches you out of the dark far ahead (35 to 70 studs, the
theme's colour), blinks, and is gone when you come within 22 studs. Now and then something heavy walks across the floor above you: five slow deep thuds
passing over, grit sifting down from the ceiling and your lantern trembling with each. Now and then, while nothing's coming for you, slow footsteps sound somewhere behind you on
whatever's underfoot, a little closer each, and stop. Now and then a few rats squeak and scurry across the floor ahead of you, wall to wall,
through your light (WarAudio ▸ Squeak), and water drips somewhere close (WarAudio ▸ Drip; not in
the Ember Forge). Now and then a spider lets itself down on its thread from the ceiling ahead of
you to the height of your face, hangs there turning, legs working, eyes red in your light, and whips
back up into the dark, sooner if you walk up to it (WarAudio ▸ Skitter; the crypt, the warrens,
the manor, the abbey). **The score** (`Music.client`) is quiet down here: only the dungeon's dread (`Dread`:
ReplicatedStorage ▸ WarAudio ▸ Dread, a Studio-only Sound; silence without it) until a fight is on
(a Depths room's gates shut, a blow struck or taken in the last 8 s, something within 60 studs
has seen you and is coming: Alert "!"), when the battle score swells in, easing back out 10 s
after; a lord's score only near its lair (110 studs). **A boss's
entrance** (`ReplicatedStorage ▸ BossIntro`; the Depths' lords and the dragon on their entrance banner (`intro = true`; other red banners are only banners) through
`Adventure.client`, Siege's champion and the Horde's Warlord through `BossEntrance.client` when a
bot becomes a `Boss`): black bars close in and the rest of the HUD steps aside, the camera finds
the boss and creeps towards it while its name comes up big on the bars, a deep boom and the ground
shaking; about three seconds, then back to you. **A boss falls** (`BossIntro.falls`, called by
`BossEntrance.client` for any boss in workspace ▸ NPCs in any mode and by `Dragon.client` for
Cindermaw, three times the size; within 200 studs of you): a deep boom and the ground
shaking, a pillar of light where it stood fading up into the dark, a ring of force rolling out
over the floor, a cloud of dust, the world washing white for a moment.

**Light from above** (`Dungeon.build`, `shaft`): in up to three rooms a floor (four in a raid),
an iron grate in the ceiling glows pale with the light beyond it, and the light falls through in a
soft column (a camera-facing Beam) to a pool on the floor (a SpotLight with shadows), dust turning
slowly in it. Cool moonlight; sea-green in the Drowned Halls, violet-white in the Abbey; none in
the Ember Forge.

### Traps (`Game ▸ Traps`, `Traps.client`)
The corridors of a generated floor are trapped (`Traps.arm(map, layout, opts)` once the map is
loaded; the builder lists its corridors in `layout.corridors`). The Depths: two corridors on the
first floor, a corridor more each floor down, the first floor's start clear; Deadvault: a third
of its corridors, none by a haven. Each theme has its favourites (the module's WEIGHTS: the Ember Forge breathes fire, the Warrens shoot darts, the Manor swings blades).
- **Spike grate**: iron slots in the floor; step on it and it clicks, and half a second later iron
  points punch up through it (26) and throw you up. Step off fast, keep to the wall beside it,
  or jump it.
- **Pendulum blade**: a crescent on an iron arm swinging across the corridor from a slot in the
  ceiling (two in a long one, out of step); it hits for 30 and throws you the way it swings.
  Time it: cross when it's on the far side.
- **Dart plate**: a plate right across the corridor, holes in one wall; step on it and darts hiss
  across (18). Jump it.
- **Fire grates**: two side by side breathing fire in turn (a glow, then the jet: 9 every half
  second). Cross on the cool side.
- **Web**: a sheet of web strung right across the corridor, wall to wall and up into the dark
  (the Warrens, the Crypt, now and then the Manor and the Abbey). Walk into it and it clings
  (CAUGHT IN A WEB: slowed to 45% for 2.2 s) as it tears, and half the time its spider comes down
  for whoever tore it. A blow that lands in it (`CombatServer.worldHitHooks`) cuts it harmlessly:
  cut first. Spiders pass through their own webs.
They hurt anyone, monsters on the hunt too (a calm one, walking its patrol or waiting in its room,
knows its own dungeon and steps round them); armour turns half of what it would turn from a blade, a dodge
slips them, spawn protection too. The server decides every hit (20 times a second); every screen
draws the moving parts (`StarterPlayerScripts ▸ Traps.client`): a blade swings on the server's
clock (`workspace:GetServerTimeNow()`), so every screen sees it where the server judges it, with a
heavy whoosh each pass; the spikes rise on a trap's `FiredAt`; the darts fly from the holes. Each
trap streams to a screen whole (`ModelStreamingMode` Atomic).

### Secrets (`Game ▸ Secrets`, built by `Game ▸ Dungeon` opts.secrets)
Now and then a room has a stretch of wall newer than the rest: paler, cracked, a draft of dust
seeping through it into the room. Strike it with a blade (`CombatServer.worldHitHooks`): it
shudders and sheds grit; the **third blow** brings it down, the stones tumbling into the room in a
cloud of dust with a crash the dark hears (`Perception.noise`), settling out of anyone's way. Behind
it a short passage to a walled-up cache (gold piles, someone who never got out, candles burnt low)
and the mode's reward: **The Depths** a gilded Epic chest (one card each, a treasure room's luck
+0.8; one secret a floor, sometimes two deeper down), **Deadvault** an ornate container (three a
raid). A SECRET! for whoever broke it. Only a room side with no door and no room beyond it can
hide one (the builder's `r.secret`, its wall `Map ▸ Secrets ▸ SecretWall<room id>`).

### The Depths (`Game ▸ Modes ▸ Depths`, `Game ▸ Dungeon`)
A party of 1–4 crawls a dungeon **built fresh every run**, in the theme the vote picked (the Bone
Crypt, Goblin Warrens, Crimson Manor, the Frozen Depths, the Ember Forge, the Drowned Halls, the
Hollow Abbey: `Catalog ▸ Dungeons`). Three floors; floor 3 ends in the theme's boss.
- **The Hollow Abbey**: a desecrated monastery where the monks kept praying after they died:
  violet candlelight, chapels, libraries and crypts, statues and banners. Its dead: Hollow Monks
  (hooded skeletons that reassemble), Penitents (quick ghouls in rags), Abbey Guards in mail;
  Cultists cast Dark Litany; champions the Wraith and the Gargoyle; its lord **Malachai, the Black
  Abbot** (a crowned shadow with violet eyes: Black Psalm, Vespers, Through the Cloister, Graves
  Open, then The Last Rite and Falling Bells as THE ABBEY RINGS ITS BELLS, and the bells toll on
  you). Now and then a bell tolls far off through the stone (WarAudio ▸ AbbeyBell) or a faint
  wordless chant drifts from another room (WarAudio ▸ Chant). Vote picture: MapShots ▸ HollowAbbey.
- **The Drowned Halls** (the newest): flooded catacombs where the sea came in and the dead stayed:
  wet stone, rust-green corroded iron, pale teal flames, standing water across the floors and
  puddles everywhere (the theme's `wet` flag), water dripping close by all the time. Its dead: the
  Drowned (ghouls, quick, mending), Drowned Bones and Drowned Archers (they reassemble), Deep
  Guards in corroded mail, Tide Callers (mages: Brine Fall); champions the Drowned Knight (Undertow,
  Breaking Wave) and the Brine Hulk (Tide Smash, Swell); its lord **Thalassar, the Drowned King**
  (a glaive; Riptide, The Tide Rolls In, Grasping Deep, Breaker, then Crashing Wave and Falling Sea
  as THE DEEP RISES, and the roof weeps on you). Vote picture: MapShots ▸ DrownedHalls.
- **The generator** (`Dungeon.build`): rooms on a grid (a spanning tree plus a loop), typed by
  how deep they are: start · combat · elite · treasure (dead ends) · shrine · fountain · stairs ·
  boss. Walls, ceilings, corridors, door frames, sconces in the theme's light, and the theme's
  props (coffins, cobwebs, mushrooms, gold, bookcases, chandeliers, icicles, lava…). Every
  doorway has a portcullis (Map ▸ Gates). It lands in ServerStorage ▸ Maps like any map; the
  mode gets the layout. `GameServer` asks a `procedural` mode to build the voted theme
  (`mode:buildMap(theme)`) before loading it.
- **Its monsters wait** in their rooms (`Depths:prepare`, Combat ▸ Perception), some asleep, the rest
  standing about: they come when they **see or hear** you (crouch to stay quiet), and the gates
  drop the moment one does. A blow on one that hasn't noticed you is a **SNEAK ATTACK** (×2, ×2.5
  on a sleeper); kill a whole room in its sleep and it's yours. The boss still comes with its fight.
- **A room seals** when you're well inside (or seen): its gates drop, stragglers are drawn in, its monsters
  come. Kill them all and the gates rise; the fallen are back on their feet in the room; everyone
  mends 40%. A cleared room sometimes leaves a chest (an elite room always does; in a room with a
  centrepiece, the start's brazier, an altar, the fountain, it stands on open floor).
- **More come** (`Depths:wave`): a fight down to its last few (a third of its most) can bring a
  second wave, decided as the gates drop (30% on the first floor, 50% on the second, 70% on the
  third; a fight's room or the stairs', never a champion's, never a room killed in its sleep). The
  floor cracks where each will come (AdventureEvent `Rise`: on every screen a dark pit opens, its
  cracks running out glowing the theme's colour, flagstones heaving up round the rim, the ground
  trembling), then a second later they burst up out of it (the `Rising` attribute: stone flung up,
  a bigger cloud of grave-dust) under a banner in the theme's words (THE DEAD RISE, MORE POUR IN,
  THE HOUSE STIRS, THE ICE CRACKS, THE FORGE WAKES). A boss in its second phase calls its servants
  the same way, once (THEY ANSWER), a moment after its fury's roar. Those coming count as foes left.
- **The dark falls** (`Depths:engage`, `SNUFF_CHANCE` 20%): as a fight's (or a champion's) gates
  slam, a cold gust puts out the room's torches (AdventureEvent `Snuff`, drawn by `DungeonMood`):
  three or four seconds by lantern light alone, then they sputter back one by one.
- **Ambush** (`Depths:ambushCheck` / `ambush`): the corridors aren't safe. Walking one (18 studs or
  longer, no fight on), each second there's a small chance (2.5%) that the floor cracks open at both
  ends of it, either side of you, and the floor's commons climb out (the same Rise as a second
  wave; AMBUSH! for whoever set it off): 2 on the first floor, 3 on the second, 4 on the third,
  more with a party. At most two a floor, 70 s apart, none in a floor's first 70 s; no gates (it's
  their own fight), and they go with the floor.
- **Difficulty** (`Depths:engage`): gentle first floors. Monsters start at 80% health and damage
  and grow with each floor; how well they fight is capped by the floor (Squires on the first,
  Knights on the second; the boss never fights better than a Knight); elites come from the second
  floor; the boss has 75% of its health pool. Every boss move hits at `BossMoves.DAMAGE` (85%).
- **Chests** are per player: each opens it once and gets **three cards** (`Game ▸ Loot`): a weapon
  your class carries with a skin and affixes, a relic, a tome (one of **your class's** powers, for
  the run), gold. A weapon find with both hands full swaps out the one in your hand: it drops at
  your feet (you or a friend can take it back). The shrine offers three relics; the fountain makes you whole once a floor; the stairs room,
  cleared, leads down (anyone starts a 5 s countdown; everyone goes).
- Your **run** (looted weapons, relics, tome, gold) survives respawns: the mode's
  `adjustLoadout` / `noteSpawn` hooks in `LoadoutServer` put it back on every new body.
- Down in a fight, you watch until the room is cleared. The whole party down at once ends the run.
  The **Phoenix Plume** relic brings you back where you fell, once.
- **Pay** (under the daily cap): monster kills by rank (`kill_<rank>`), `depths_room` per cleared
  room, `depths_floor`, `depths_boss` (Catalog ▸ Economy). Stats: `depthsBest`, `depthsClears`.
- **On screen** (`StarterPlayerScripts ▸ Adventure.client`, any mode with Round ▸ OwnHud): the run
  panel (floor, what's happening, gold), your relics (hover / tap for what they do), a fog-of-war
  minimap with what each room is, the chest cards (1 / 2 / 3, a controller's A, LEAVE IT), the
  boss bar (any Boss near you, the Horde's Warlord too), banners and the fade going down. **Guides**:
  a marker over what's worth walking to (OPEN CHEST, PRAY, DRINK, DESCEND, a find's name; EXTRACT and
  TAKE THE CROWN in the other adventures), an arrow at the screen's edge to the nearest one off
  screen, an UP NEXT line under the run panel, a gift on the map's rooms with a chest. Objectives
  steps aside for an OwnHud mode.

### What's new (`WhatsNew.client`)
Once per update, back in the Courtyard, a card of what's new (the script's `NEWS`: a `version`, a
title, lines of an icon, a heading and a line). Only for someone past the welcome and the menu
tour (Tutorial ≥ 2, no intro, tour or cinematic running), over the Hub menu; TO BATTLE! (or
Escape, Enter, a controller's B) puts it away and the version is kept with your settings (leaving
for a match before that puts it away unread, for next time)
(`ClientSettings` ▸ `SeenNews`, not shown in the settings panel and never reset), so the same update
never shows it twice. Scaled to fit a short screen. A new update: change `NEWS.version` and its lines.

### The Gilded Rat: the dungeon game's world (`Game ▸ Modes ▸ Tavern`, `Game ▸ TavernMap`)
The Depths and Deadvault start somewhere of their own: **The Gilded Rat**, an adventurers' lodge
at the top of the stairs to the dark (GameConfig.DOORS.Tavern, MODES.Tavern: public servers of
their own, like the Courtyard's). The Courtyard's PLAY ▸ ADVENTURES ▸ Deadvault / The Depths take
you (and your party) there; leaving a raid brings you back there (HubServer's goHub and
Deadvault's extraction); its door goes home to the Courtyard.
- **It sounds lived in** (`TavernAmbience.client`): the low murmur of the place over the whole hall
  (WarAudio ▸ TavernRoom: talk you can't make out, a laugh, mugs), the hearth crackling from its
  mouth (WarAudio ▸ Fire), and a lute and fiddle tune by the hearth (Music's `Tavern` mood:
  WarAudio ▸ Tavern, else the Courtyard's score). None of the dungeon's dread here: the lodge is
  built fresh (Generated) like a floor, but `DungeonMood` runs only for The Depths and Deadvault (and
  Plague Night, the Undead invasion): every procedural map is Generated, War's fields included.
- **The lodge** (built fresh when its server starts): a long timbered hall, candle-lit tables
  under iron chandeliers, a great hearth, banners, torches; the Treasurer's counter (coin, scales),
  Hrothgar the Smith's forge (glowing coals, anvil, racks), Old Brenna's armour stands, Wendel the
  Alchemist's shelves of coloured bottles and his bubbling cauldron, your stash's iron-bound chest
  by a strongroom door, the notice board, the **Dungeon Gate** (a stone arch over stairs down into
  the dark, cold torches, mist) and the door home (daylight). No ale: the lodge serves bread and
  stew.
- **You walk in** as your class (no fighting there; anyone without a body is walked back in).
  M opens the dungeon game's lobby (below; the Courtyard's menu has no place there), and it opens
  by itself as you arrive. Its places open it where you stand: a merchant (TRADE: their wares),
  the chest (STASH), the board (CLASS and perks), the gate (PLAY), the door (the Courtyard).

### The dungeon game's lobby (`DungeonMenu.client`, `ReplicatedStorage ▸ DarkUI`)
The Depths and Deadvault are a game of their own, after Dark and Darker, with a lobby of their own.
It wears **the rest of the game's look** (DarkUI on Theme: FredokaOne headings, Gotham type,
outlined white text, dark-glass rounded panels, chunky glossy buttons, the blue pill under the
chosen tab), warmed for the dungeon (a gold line under each panel's title, gold for what's
chosen, rarity glowing up from a slot's floor), with Dark and Darker's layouts, and every item
shown as itself in 3D (DarkUI.icon: the weapon in its skin, armour's coat, a corked bottle, a
goblet, a ring, a gem, a tome, coin; never an emoji). Mannequins are never naked: an empty armour
slot takes the class's plain piece (HubMenu `_G.HubDressed`). Tabs (Q / E step through them):
- **Play**: your party standing before a candle-lit table in a tavern's back room, facing you (a
  scene built on your screen, lit warm), the dungeon (The Depths or Deadvault, its picture), READY
  (the leader: ENTER), Invite (online friends), Exit Party.
- **Class**: the class list (their faces), you as that class, its story, its skill, and its
  **perks** (Catalog ▸ Perks: two go into the dungeon with you; Game ▸ Perks puts them on: less
  damage, more health, a bigger bag, quiet steps, harder sneak attacks, a second wind, luck…).
- **Stash**: you in your kit (its weapon in hand, its armour's set on you), what you are
  (health, damage taken and dealt, speed, perks), the kit (weapon, sidearm, armour, three relics,
  the **belt**'s four draughts) and the stash (60). Drag a thing onto a slot, or click it: EQUIP,
  TAKE OFF, SELL, the Smith's REFORGE and TEMPER.
- **Merchants**: their faces, their wares (BUY), your stash beside them to sell from.
It opens from PLAY ▸ ADVENTURES (The Depths, Deadvault) and over the Courtyard's menu, which steps
aside while it's up (`_G.DungeonMenuUp`). `_G.OpenDungeon(tab, mode)`, `_G.OpenVault()`. It shuts
itself when a raid starts.
- **Part of the main game, one way out**: top right, a big red **◀ MAIN MENU** (not top left: on a
  wide screen Roblox's own menu, chat and mic buttons sit there;
  asked once, MAIN MENU / STAY; your stash, kit and gold stay in the Gilded Rat) takes you home and
  the main menu opens there by itself; top right, your level, Marks and Crowns (what every run pays
  into) beside the vault's gold. WALK AROUND [M] shuts the lobby and you're on your feet in the
  Gilded Rat (a small bar at the top: LOBBY [M] / ◀ MAIN MENU). Signs over the Dungeon Gate, the
  door home and your stash (Tavern:sign). The lobby shuts itself whenever you're no longer in the
  Gilded Rat (a raid, or home).
- **No battle class screen in the dungeon game** (a mode's `ownSpawn`: the Tavern, Deadvault, the
  Depths): LoadoutServer never shows it there; you go in as the class chosen in the lobby. When
  you can't come back mid-round its own screen says why: **YOU FELL** (Deadvault: your pack lies
  where you fell) or **DOWN** (the Depths: back when the room is cleared), with SPECTATE (the
  spectate bar's BACK returns here) and BACK TO THE GILDED RAT / LEAVE THE DUNGEON.
- **When a raid or a run ends**: no map vote; the end screen is yours (YOU GOT OUT / YOU FELL /
  VICTORY / DEFEAT, RoundResult.client reads `RaidFate`) and everyone goes back to the Gilded Rat,
  each party together (HubServer `toTavern`: no "everyone ready" gate to go home).

### Prompts (`Prompts.client`)
Every ProximityPrompt is drawn in the game's own look instead of Roblox's default box: a
dark-glass card, a key cap (your pickup key, E, a gamepad button, or TAP), the action in big
outlined type and the thing under it, a bar along the bottom that fills while you hold. Loot (a
model with `Rarity`: chests, drops, containers) tints the cap and bar its rarity. Each prompt is
set to `Style = Custom` on the client only; the cards live straight in PlayerGui with
ResetOnSpawn off (a respawn empties PlayerGui of anything else).

### Deadvault (`Game ▸ Modes ▸ Deadvault`, `Game ▸ Vault`, `Game ▸ Containers`, `DungeonMenu.client`, `RaidInventory.client`)
An extraction raid after Dark and Darker, for up to 12 raiders in parties. Go in with your party
and the kit you dare to risk, search a great dark dungeon, keep quiet past what sleeps there, and
get out with what you found, or lose it all.
- **The dungeon** (`Dungeon.build` with `raid = true`): 30 rooms on a 7 × 6 grid, each one
  something before the dark took it (`r.arch`): a GREAT HALL (pillar rows, a runner, chandeliers,
  banners, braziers, taller), a CRYPT (rows of sarcophagi, skulls in wall niches), THE CELLS
  (barred cells along a wall, chains, what's left of their prisoners), a LIBRARY (aisles of
  shelves, reading tables), an ARMOURY (racks, stands, an anvil), a STOREROOM, a CHAPEL (an altar
  under coloured glass, statues, pews), a CAVERN (rough rock, stalagmites, an old camp), a
  TREASURE VAULT, THE LAIR (the theme's lord and its hoard). Each theme has its own mix
  (`ARCH_W`). Pilasters and skirting on the walls, fewer torches: the dark is the point.
- **Darker than the Depths, and lived-in** (`grime`, every room but the ways out; the Depths' floors
  get it too): cracks across
  the flags, rubble fallen into the corners, cobwebs up the walls, damp streaks down them, a puddle,
  chains or a hanging cage (`P.cage`), someone's bones, now and then guttering candles (a pool of
  light), and dust drifting in the torchlight. None of it collides. The raid's light is the
  theme's, dimmer (ambient ×0.62, brightness ≤ 0.4, a thicker haze): the torches are what you see
  by, and they **flicker** (`TorchFlicker.client`: any PointLight named "Flicker" wavers about how
  it was built; the dungeons' sconces, braziers and candles and the Gilded Rat's fires are named so).
- **Its monsters** keep to their rooms (a fight's room: 28% none, 40% one, 24% two, 8% a pack of
  three), some **asleep**, pairs **on patrol** (four, and one more for every two raiders)
  between rooms; they come when they **see or hear** you (`Combat ▸ Perception`: a run is loud, a
  fight louder, a crouch is quiet and half as visible), shout for those near, hunt where they
  last saw you and go back. Over a monster's head: **!** (it knows), **?** (looking), **z z**
  (asleep; a sleeping skeleton or ghoul shows nothing: it lies among the bones like the dead,
  `DungeonMood`). Opening a chest is loud. The lair's lord fights whoever comes in.
- **Containers** (`Game ▸ Containers`, Catalog ▸ Loot CONTAINERS): crates, barrels, sacks, urns,
  weapon racks, armour stands, bookshelves, sarcophagi, remains, chests (plain, ornate, the
  hoard). Search one (V) and a **loot window** shows what's in it, rolled for the first opener's
  class and shared: TAKE one, or TAKE ALL (Y). **Valuables** (`TREASURES`: cups, rings, idols,
  gems) only sell, at their full worth to the Treasurer. **Not every dead rests**: the first look
  into a sarcophagus now and then (`Deadvault.WAKE_CHANCE`, 30%) throws its lid off towards you
  (the effigy carved on it with it) and its dead climbs out of the far side, already coming for
  you (IT WAKES; the crypt's skeletons and ghouls, the manor's vampires, the ice's frozen dead;
  `Deadvault:waken`). Deal with it, then search: the coffin won't open while its dead is up.
  **A mimic**: the first look into a chest now and then (`Deadvault.MIMIC_CHANCE`, 12%) finds it
  was never a chest (A MIMIC!): it vanishes and a mimic stands a step out from where it stood,
  facing you, on four stubby legs, its lid a mouth of teeth over a tongue, eyes glowing inside it;
  an ornate chest is a Gilded Mimic, bigger and harder. Its hoard can't be searched while it lives;
  when it's dead the chest is back where it stood, open (`Deadvault:mimic`, body `mimic` in
  `Combat ▸ Monsters`, walked by `SpiderLegs`: the lid breathes, chatters as it scuttles, snaps wide
  as it bites, hangs open in death). The Depths have them too: a treasure room's chest is now and
  then a mimic (`Depths.MIMIC_CHANCE`, 15%; gilded from the third floor), and dead, its chest gives
  everyone their pick as before (`Depths:mimic`).
- **Your gear** (I, or the Bag button): what you wear (a weapon, a sidearm, armour, a tome's power,
  three relics), your **belt** (four draughts: keys **3 – 6**, on screen bottom left; drinking takes
  a moment and slows you, then a healing draught mends over four seconds) and your **bag** (20;
  Pack Mule +6): EQUIP, TAKE OFF, DRINK, DROP; what you carry is worth (to the vault) at the top. A
  find goes on if there's room on you, else into the bag.
- **Bodies**: a monster's corpse stays where it fell; **loot it** (its gold, and what it carried:
  a valuable, a draught, an elite's weapon, the lord's hoard) the way you search a chest.
- **Nothing through walls**: a chest's or a way out's marker hides behind walls, its prompt wants
  you to see it, and there's no arrow at the screen's edge in a raid. Find your way (the map).
- **In**: your kit leaves the vault with you; an empty weapon slot goes in as the **free kit**
  (your class's plain weapons and a draught: never lost, never sold, never banked). Your class's
  own power comes too (a tome replaces it). A **party** comes in together at one haven and fights
  side by side (Team: their blows barely touch each other); other parties at havens far apart.
- **Out**: the two **escape stairs** (on the map from the start: up the steps to a door of
  daylight) open after 2 minutes; **blue portals** open in waves at 5, 9 and 12 minutes in rooms
  about the dungeon (on the map). Hold your pickup key (4 s / 3 s); struck while you hold: not
  yet. Everything you carry and your gold go into the vault (no room: sold); `vault_extract` pays
  a little Marks (once a raid, under the daily cap; stats.vaultOut).
- **Fall**, and everything you carried lies in your **pack** where you fell, for whoever finds it.
  Still inside when it collapses (15 minutes): lost. Everyone out or down ends it early.
- **The vault** (PLAY ▸ ADVENTURES ▸ DEADVAULT ▸ YOUR VAULT; Profile ▸ vault): KIT & STASH (a
  stash of 60; the kit: weapon, sidearm, armour, 3 relics, 4 draughts; the class you raid as)
  and MERCHANTS: **Hrothgar the Smith** (four weapons for your class, new each day, each sold
  once; his work on any weapon: REFORGE its powers, TEMPER it a rarity higher), **Old Brenna** the
  armourer, **Wendel the Alchemist**, **the Treasurer** (your valuables at their full worth). The
  server decides (Hub ▸ VaultServer, VaultRemote).

### Crownfall (`Game ▸ Modes ▸ Crownfall`, `Game ▸ Realm`)
A battle royale for up to 16, bots filling the rest (`fillAnywhere`). **The island is built fresh
every match** (`Realm.build`): terrain (grass on a beach in a sea, round hills, dirt roads to the
middle), the Crown Keep (walls, towers, arched gates, a hall, banners), villages, a mill, watchtowers,
camps, a chapel with graves, ruins, each with a name and chests; forests and rocks between.
- **The drop**: a few seconds in, everyone comes down out of the sky under a canopy (steer where
  you land) as their class with only a plain weapon (no power, no throwable). Bots wait for it.
- **Chests** spill three things for whoever opens them (`Catalog ▸ Loot` CHESTS.crownfall, rolled for
  the opener's class): weapons (rarity, skin, affixes), armour (`Loot.setArmor`: less damage taken,
  more health), potions (drunk on the spot), tomes (a power), relics. A new weapon or armour takes
  its slot and drops the old one. Whoever falls drops what they found.
- **The ring of fire** closes in phases (`RING`: wait, shrink, tighter, hotter); outside it you burn
  (the Burning look). Bots head into the next ring when they're outside it (`botOpts`, BotFill's hook).
- **Royal caches**: as each of the first three rings starts to close, a gilded chest comes down out
  of the sky under a canopy inside the next ring (`Crownfall:cache`), a gold flare over it the whole
  way and till it's opened: four things rolled with a king's luck (4.5). Worth fighting over.
- No respawns; the last one standing wins (`stats.crownfallWins`).
- HUD: how many are left, the ring's clock, the island map (its places, the ring, the next ring,
  you), the place you're in. Vote picture: MapShots ▸ Crownlands.

### Invasions (`Game ▸ Modes ▸ Invasion`, on the Horde's rules)
Four themed hordes behind one door (the tile asks which army): `InvGoblin`, `InvElf`, `InvUndead`,
`InvOrc` in `GameConfig.MODES`, all `impl = "Invasion"` (Game.load takes a mode's module from
`impl`). Each brings its own army (the Bestiary's monsters), its own objective (HordeObjective's
new kinds) and a lord every fifth wave with its big moves:
- **Goblin Raid** — THE HOARD. Goblin Thieves don't fight: they grab a sack of gold and run for
  their gate. Kill a carrier and the gold comes back; let it through and it's gone. Bombers lob
  fire-pots. Lord: the Goblin King.
- **The Elven Host** — THE LOGGING CAMP. Mostly archers and rangers, more of them shooting at once
  than any horde; blademasters, spellweavers, wardens. Lord: Sylvara, Queen of the Wood.
- **Undead Night** — THE HOLY FLAME (a wayside chapel). It's night. Skeletons stand back up,
  necromancers raise more, wraiths blink. Lords: the Lich King, the Bone Colossus.
- **The Orc Warband** — THE VILLAGERS. War-Drummers make every orc 15% faster and harder while they
  live (a beat you can see): kill them first. Lord: Gorzak the Warchief.
Pay and stats as the Horde; your best wave per army is `stats.invasionBest_<army>`. The Horde
gained hooks for this (`roster`, `aliveCount`, `removeLive`, a forced `objective`).
- **Spoils of war** (`Invasion:spoils`, `takeSpoils`): every third wave beaten, a gilded chest
  stands by what you defend, one for each of you (`perPlayer`): a relic rolled for your class
  (luck and the chest's rarity grow with the wave) that stays yours for the run (`noteSpawn`
  puts it back on after a fall), and a healing draught. A run gets stronger as it goes.

### Dragonfall (`Game ▸ Modes ▸ Dragonfall`, `Combat ▸ Dragon`, `Game ▸ CalderaMap`, `Dragon.client`)
You and your party (1 – 6, a party door like the Depths) against **Cindermaw, the Ashen Wyrm**.
- **The Ashen Caldera** (`CalderaMap.build`, fresh each match): a floor of cracked basalt with
  glowing seams and scorch marks round an ancient paved ring, black cliffs all round with lava
  running down them into pools, lava pools out on the floor (they burn), six **ward stones** with
  glowing runes, four **ballistae** on platforms near the rim, the bones of something huge, the
  swords and shields of those who came before, ash drifting down, a burning dusk.
- **The dragon** (`Combat ▸ Dragon`): a body of its own (parts on Motor6Ds, no person's rig: the
  `CustomBody` attribute keeps ragdolls, corpses and kill effects off it), held where the server
  says by AlignPosition/AlignOrientation; a Humanoid in NPCs, so every weapon hits it; its blows are
  the bosses' (telegraphed rings, arcs and lanes: Combat ▸ BossMoves). On the ground: bite, claw,
  tail sweep (behind it), wing buffet (when crowded), stomp, a charge (into the cliffs: it reels),
  fire breath swept across the ground. At **two thirds** it takes to the sky: strafing runs of fire
  and fireballs, and its **brood** (Cinderlings) climbs out of the lava pools. **Ballistae** (hold to
  fire, 6 s to wind; guides over them while it's up there): 3 bolts (one more for every two of you
  past the first) and it **crashes**, downed for 9 s (it takes 50% more). Under **a third** it's
  **enraged**: quicker, fire rains, and every 40 s it rises over the middle for an **Inferno**:
  whoever its fire can see is burned; behind a ward stone you're sheltered (the stones light up
  and are marked while it winds up). At **a fifth** left it takes to the sky one last time: the
  ballistae again.
- **Its look on your screen** (`Dragon.client`): the server only moves its root and sets
  attributes (`DragonState`, `Fly`, `Jaw`, `Rear`, `Look`, `Breath`, `BreathYaw`, the `Snap` /
  `Swipe` / `Tail` / `Buffet` counters, `Reel`, `Downed`, `Enraged`, `Dead`); the client turns its
  joints to match (walk off its speed, wings beating, the tail whipping, the head tracking you)
  and streams fire off its mouth. The model streams whole (`ModelStreamingMode` Atomic).
- **Win**: everyone there is paid `dragon_slain` (Catalog ▸ Economy) and counted
  (`stats.dragonsSlain`, your fastest `stats.dragonBest`); its health is 3000 + 1800 a player. The
  clock (14 min) runs out first: it holds the caldera. You come back at the south rim (8 s).
- The Play menu's tile shows its still copy (`Dragon.publishDisplay`: MonsterDisplays ▸ Dragon).

### Kingslayer (`Game ▸ Modes ▸ Kingslayer`)
A free-for-all with bots (`fillAnywhere`: BotFill fills it like the Warfront). A few seconds in, the
crown appears on open ground in the middle: whoever takes it is the King, crowned and glowing gold
through walls, taking 60% of the damage, +150 health, unflinching, a little harder hitting and
slower. A point a second as King, 5 for a kill as King; killing the King makes you the King (+10).
A King who falls to a bot or the world drops the crown for anyone. First to 150, or the most at
the end. HUD: Adventure.client (who's King, the leader, your points on your chip).
- **Everyone against the King** (`Kingslayer:botOpts`, BotFill's hook): a bot within 110 studs of
  the King goes for them (anyone else only when they're in its way); the crown on the ground draws
  the bots to it, so taking it back means a fight.
- **A long reign burns brighter**: every 30 seconds of one the King's glow deepens and the field
  is told (THE KING HAS REIGNED 1:00 · BRING THEM DOWN).

### Plague Night (`Game ▸ Modes ▸ Plague`)
Two sides, at night: THE LIVING (A) and THE PLAGUE (B). Patient zero turns after a few seconds (one
in six players; with fewer than four, only the dark's ghouls), and ghouls (PlagueGhoul) come out
of the dark, more as the night deepens. Anyone of the living who falls rises as a ghoul: green and
clawed (`Monsters.decorate`), a cleaver, Bloodlust, more health, a quicker step, the dead's mending
(the Troll Heart relic). With few players, villager bots stand with the living, and rise as
ghouls when they fall. Dawn with anyone living: the living win; nobody left: the plague takes the
town. A ghoul sees the living near it outlined through walls.
- **Out of the ground, all round you** (`Plague:darkSpot`): the dead never come from one place.
  Each one claws up (a breath of grave-mist, broken earth: `emerge`) on open ground 45–80 studs
  from someone living (nearer none than 38), at their level (not a roof), inside the town (the
  map's spawns and zones and a margin), never inside anything. A turned player rises **where they
  fell**; the plague's others come up out of the dark the same way.
- **The dead surge** every 70 seconds: several at once (more with more players, more as the night
  deepens), from all sides, with a banner.
- **Worse things as the night deepens** (`pickKind`, Catalog ▸ Bestiary): Plague Runners from the
  first (quick, frail), Bloaters after a fifth of the night (slow, fat; they burst in a green blast
  when they fall: stand clear), Plague Brutes after two fifths (huge, mending, enraged; a few at once).
- **The living carry a lantern's glow**; the last of them **stands alone** (mended, +50 health,
  quicker, and everyone's told).
- **Dawn**: when the clock runs out with anyone living, the sun comes up and the dead burn away
  where they stand.
- **Toward dawn**: the clock is the night. The sky pales, the mist thins, the fog lifts (the map's
  Atmosphere too: it's thickened to a night mist at the start and put back at the end).

### Monsters (`Combat ▸ Monsters`, `Catalog ▸ Bestiary`)
Every monster is a combat bot (it blocks, parries, feints like anyone), dressed and **built into its
shape** with welded parts: skeletons (the limbs hidden, bones in their place), wraiths (a robe
that thins to mist), golems, goblins, orcs, elves, vampires, trolls, cinder-men; crowns, capes,
horns, antlers, wings, tusks, fur, loincloths, crystals, glowing cracks, auras; and scaled to size.
A set worn as clothes can drop its helmet (`noHelm`) and dye its plain cloth (`cloth`). Traits:
reassemble (a skeleton stands back up once), lifesteal, frostbite, burning, enrage (under half
health), explode, summon, regen. An **elite** (`opts.elite`) gets an affix (Blazing, Frozen, Swift,
Vampiric, Stoneskin, Savage, Undying), more health, a glow, and a big move if its kind has none.
`Monsters.display(id)` is a still copy for screens: the menu's tiles show them
(ReplicatedStorage ▸ MonsterDisplays, made by GameServer at start). What a monster leaves when it
falls: a skeleton falls apart into a heap of its bones, the skull on top (Corpses "bones"; not one
that will stand back up), a wraith is simply gone ("none"); the rest leave their body as anyone
does. The killer's own kill effect, if it has one, has the last word.

**Spiders** (`body = "spider"`: the **Cave Spider**, small and quick, in the Goblin Warrens and the
Bone Crypt; the **Broodmother**, an elite of the Warrens twice a man's width that calls up cave
spiders): the body it was dressed as is hidden (it still fights with it: its bites are a hidden
blade's reach, its fangs a weapon that never drops, `NoDrop`) and a spider stands in its place, a
thorax and a great marked abdomen on a `SpiderBody` joint, a cluster of red eyes, fangs, and eight
legs each on a `SpiderHip_n` and a `SpiderKnee_n` joint (kept rigid when it falls: `Rigid`).
`StarterPlayerScripts ▸ SpiderLegs` walks them on every screen: the legs step in two sets of four,
twitch when it stands, the body rears and thrusts as it bites (read from how fast its hidden arm
turns), the legs curl when it dies; it skitters as it runs (WarAudio ▸ Skitter), leaves no boot
steps or prints (`Skitters`). It fights as a **Beast** (`Bots.SKILLS.Beast`): no guard, no parries,
ripostes, feints or kicks; quick, low lunging bites (stabs and underhands). Their **nests**
(`Dungeon` A.nest, "The Nest"): webs strung across the corners up into the dark, egg sacs heaped on
silk by the walls, cocoons hanging on threads from the ceiling, the bones of what was caught (and,
in a raid, its remains to search). A Deadvault raid's Warrens and Crypt have them among their rooms;
in The Depths a fight room there is a nest now and then (`NESTS`: 25% in the Warrens, 15% in the
Crypt), its fighters mostly cave spiders.

### Boss moves (`Combat ▸ BossMoves`)
Bosses (and elites, and a few casters) fight with **telegraphed big moves** on top of their blade,
souls-style: the ground lights up where it will land and fills; the body winds up and glows; every
move has a way out. Kinds: slam · shockwave (a rolling wall of force: **jump it**) · charge (a lane;
into a wall it's **staggered** and takes more damage) · leap (lands where you stood) · sweep (a wide
arc: block it or get behind) · spin · eruption (a line of bursts racing at you) · rain (rings all
over the arena) · nova (a ring under each of you) · blink (vanishes, comes out behind you swinging)
· barrage (a fan of bolts) · beam (a lance sweeping the room) · roar. A **dodge** passes through any
of them (its first moment is untouchable); sweeps, charges and spins can be **blocked** (it costs a
lot of stamina; out of stamina, the guard breaks). Under half health a boss enters its **second
phase**: a roar, a banner, faster moves, new ones, and its arena turns on you (its `hazard`).
Every screen draws the wind-up poses, flashes and camera shake (BossFX, Adventure.client).

### Loot (`Game ▸ Loot`, `Catalog ▸ Loot`)
Rarities Common · Uncommon · Rare · Epic · Legendary (a damage bonus and 0–3 affixes; a Legendary
has its own name). Weapon affixes: burn, chill, poison, lifesteal, damage, storm (a bolt from the
sky), execute, giant (elites and bosses), holy (the undead), speed, thirst (a kill heals), stagger.
Relics (passive, carried): armour, speed, damage, health, dodges, stamina, luck, on-hit fire and
frost, lifesteal, regen, a kill's heal, the Berserker's Totem, the Thorned Mantle, the Ring of
Storms, the Phoenix Plume, the Shard of the Crown. A relic with a `class` (the Eagle Feather's draw,
the Mana Pearl's cast) only rolls for that class, and a tome only teaches the finder's own class's
powers: nobody sees another class's things. Potions, armour tiers and gold for the other
adventures. Loot never touches anyone's collection: a skin on a looted blade is the run's. In the
world: `Loot.drop` (a turning thing in a beam of its rarity's colour), `Loot.chest` (per player or
shared). Prompts use your pickup key (V).

## Rounds

See *Game modes, maps, places* above. The top-centre strip shows the mode, the map, the
clock, the mode's objective line and (team modes) both scores. At the end everyone is pulled
out, the board comes up wide with the result, your pay for the round and **the vote: three big
cards, each with a picture of its map** (`ReplicatedStorage ▸ MapShots ▸ <map>`: a StringValue,
Decal or ImageLabel holding the image — made in Studio from each map's menu view; a map without
one gets a card in its mode's colour), the votes so far in a badge. The class screen keeps out
of the way while the vote is up and comes back when the round starts.

**The class screen** (`LoadoutMenu`): a card per class showing **your fighter in that class's
loadout** — the armour, colours, hair and weapon you saved for it, dressed by the Dresser like a
real spawn (`ReplicatedStorage ▸ PreviewRig`, shared with the Hub menu's stages) — the chosen
one turning slowly, with the class's line and loadout underneath.

**Spectating** (`StarterPlayerScripts ▸ Spectate`): dead in a match, SPECTATE on the class
screen hands the screen over to watching the fight. The camera follows a fighter still standing —
your killer first, then teammates, then everyone else, bots last — from behind and above, easing
after them and stopping short of walls; when they fall it watches a moment, then moves on. The bar
at the bottom shows who it is (name in their team's colour, class · weapon · kills, health), with
◀ ▶ (or Q / E) to switch, scroll to zoom and the right mouse to look round them; SPAWN puts you
straight back in as your chosen class (it reads like the class screen's button: the next wave, the
next round) and CLASS brings the class screen back. The dead body's HUD is put away and the Hub
menu's cinematic camera holds off while it's up; it ends when you spawn or the round ends.

**Water** (`DrownY` on a map, e.g. Highbridge's river): a fighter who stays below that height
for 1.2 s drowns (`CharacterSystems`); a knock-off still credits the last one to hit them.

## Voice

Fighters grunt as they swing (40 % of light swings, 60 % of heavy ones), cry out when cut (90 %),
grunt as they kick or parry now and then, and give a last cry when they die (not without a head),
then their body thuds down (plate clanks). Each fighter keeps one voice (a pitch from their name,
`SoundBank.VOICE_PITCH`) and never grunts twice inside `VOICE_GAP` (0.45 s). The takes are the
`Voice…` pools in `ReplicatedStorage ▸ SoundBank`. To use your own: a folder `Voice` in
`SoundService` with subfolders `Swing`, `Hurt`, `Death`, `Kick`, `Parry` of `Sound`s overrides
that kind (one picked at random; its own Volume / PlaybackSpeed are the baseline).

## Movement (MovementServer + Movement)

Numbers live in `ReplicatedStorage.MovementConfig`. The server publishes `SpeedMult_Sprint`
and `SpeedMult_Facing` from replicated state (MoveDirection, attributes), so the client can
only ever *ask*. Sprint ends the moment you block, crouch, attack, get stunned or ragdoll.
Dodge: the client pushes itself (it owns its physics, `DODGE_SPEED` for `DODGE_TIME`) and the
server validates and charges `DODGE_COST` stamina; forward input is stripped, no input = hop back.
The armor weight scales the sprint (`SprintMult`), the dodge's cost (`DodgeCost`) and its reach
(`DodgeReach`). A fighter held on their mark for a countdown (`HoldUntil`, server time) can't hop,
dodge, kick or swing until it runs out.

## Weapons on the floor (Pickup)

A weapon that leaves a hand — disarm, death, or a swap — lands as a pickup with a prompt (hold
V) in `workspace.DroppedWeapons`, for `DESPAWN` (25) seconds. Only what you can hold is offered:
without a right arm nothing, with one arm only one-handed weapons (`Pickup.canHold`, the
weapon Config's `TWO_HANDED`), and only what your class carries (`Pickup.fitsClass`: a Knight
can't take up a bow or a wand, a Mage a sword; bots take up steel only); the prompt is hidden on your screen and the server refuses it
(bots don't go for them either). **Any two weapons**, a primary or a sidearm alike: picking one up
with a hand free puts it in the free slot; with both full, the one in your hand is dropped and the
new one takes its place on the bar. Loot in the adventures works the same way (`Loot.slotFor`).

**Corpses (`Combat ▸ Corpses`).** The dead stay on the field: 2.8 s after a death the body is
laid out where it fell — a still copy of everything you could see of it (armor, hair, face), the
limbs it lost joining it — and the real body is hidden (kept for the death camera until the
respawn). A kill effect decides what is left instead (`Catalog ▸ KillFX` `remains`, laid
`remainsAt` seconds in, as the effect hides the body): Crow Swarm a **skeleton** picked clean among
black feathers, Inferno a **charred skeleton** in a smoking heap of ash, Thunderstrike a
**blackened, smoking body**, Royal Decree a **golden statue** with a crown, Shatter **rubble** in the
body's colours, Gold Rush a **heap of coins**, Confetti Pop **confetti**, Frozen **ice shards**, Shadow
Rift a **scorched ring**, Ascension **a few glowing feathers**. With anything but a body or a statue
the severed limbs go with it (bones for a skeleton). A body and its limbs fade together.

**Clean-up (`Combat ▸ Janitor`).** What a fight leaves behind lies around a while and then fades
out: corpses (30 s, at most 8), severed limbs on their own (15 s, at most 10), thrown heads (18 s,
at most 6), dropped weapons (25 s, at most 8 — one somebody picks up is theirs). Past the cap the
oldest fade first, and the field is swept clean when a round ends and when the next begins.
Corpses, limbs and heads lie in `workspace ▸ Remains`. Slots: **one primary + one secondary**
(a weapon whose `Config` has `SECONDARY = true`), `MAX_WEAPONS` total; taking a weapon for a full
slot drops what was in it right there. The loadout menu offers a secondary list from the same
flag. Switch weapons with the Roblox backpack (1 / 2).

## Skewered heads

A **lethal** face stab (no more auto-execute — `STAB_HEAD_EXECUTE` is off) hangs the victim's
head on your blade, sitting exactly on its axis. It stays there until your next swing, then flies
off forward at `HEAD_THROW_SPEED`: `HEAD_THROW_DAMAGE` and a `HEAD_THROW_STUN` on whoever it
hits (it can finish someone low). Unequipping just drops it.

## The result screen (`RoundResult`)

The moment a round ends: **VICTORY** (gold), **DEFEAT** (red) or **DRAW** big across the middle,
on a band in the winning side's colour, then who won ("IRON WINS", or the FFA winner and their
kills) and why (the mode's result line: "FROSTGATE HAS FALLEN"; "THE MATCH IS YOURS" when a
match is over). Five seconds, then the board and the vote. It remembers the side you fought on
(teams can clear as the round ends). Not in the Courtyard, the Tiltyard or Horde. Embers rise
behind it (gold for a win, ash for a loss) and sparks fly off the word as it lands; a win flashes.

## The big moments (`DeathScreen`, `Celebrate`, `UIFX`)

The intro's fire, wherever a moment deserves it (`UIFX.embers` / `sparks` / `vignette` /
`camShake` / `fadeOut`; the sounds `Fallen`, `Rise`, `Horn`, `LevelUp` from licensed ids):
- **Dying** (`DeathScreen`; the ScreenGui is still `DeathFade`): the world drains of colour, red
  closes in at the edges, a low boom, and the word lands — YOU HAVE FALLEN, or BEHEADED, SHOT
  THROUGH THE HEAD, YOU BLED OUT, BETRAYED! — with who and with what (the kill feed's own entry).
  After 2.2 s a dark veil with embers and what comes next, with a countdown bar: BACK IN THE
  FIGHT IN 3 (the mode's respawn delay) · BACK TO THE COURTYARD · BACK ON YOUR FEET · THE NEXT
  WAVE BRINGS YOU BACK · OUT FOR THIS ROUND. A new body lifts it with a golden flash and a blade
  drawn; the class screen or the menu opening lifts it too (LoadoutMenu sets `Lift`, and waits
  for `HoldUntil` so the fall is always seen). CameraRig holds the camera in the head as you fall,
  and then the **kill cam** (Settings ▸ Kill cam): 0.75 s in, the head turns over 0.55 s to the
  one who did it (a player by `LastHitBy`, a bot by `LastHitByName`, the nearest of that name)
  and the view closes in on them (the field of view narrowed to frame them, near or far) until
  the veil comes down.
- **The round begins** (`Celebrate`): FIGHT! slams down under the round's number (or the mode and
  the map), a war horn, sparks, a shudder. Not in the Courtyard or the training yard.
- **Level up**: LEVEL 7 lands in gold on a dark band, a brass flourish, sparks and embers — after
  the round's result and any travel screen.
- **Spawning** in a match: a burst of embers and a flash of light at the feet (everyone sees it).
- **Embers** also drift behind the class screen, across the travel screen, and gently over the
  lobby; objective banners (a gate falls, a wave comes) throw sparks.

## Kill feed + leaderboard

`Scoreboard` keeps `leaderstats` (Kills, Deaths) per player and fires a kill-feed entry on every
death. Credit: CombatServer stamps `LastHitBy` / `LastHitWith` / `LastHitKind` on a character
each time it hurts it (swings, kicks, thrown heads); a death within `CREDIT_WINDOW` (15 s) of
the last hit counts for that attacker, a bleed-out included. **Hold Tab** for the board (kills,
deaths, K/D, sorted by kills, team-coloured in team modes; replaces Roblox's list). Dummies show
in the feed, not the board. Every player death also goes to `Game.onDeath` (tickets, lives,
round kills) and into the player's `Profile` stats; the board resets each round. **In team modes
every name in the feed wears its team's colour** — players and bots alike (`killerTeam` /
`victimTeam`: CombatServer stamps the attacker's team as `LastHitByTeam`); yours is underlined and
a row you're in has a gold edge; the verb is neutral, a teamkill orange.

## Low stamina

Below 35% stamina a dark vignette, a little blur and a looped `SoundConfig.Breathing` ramp in
(InjuryFX); at 0 the vignette pulses and the breathing peaks.

## Settings (M → SETTINGS)

Camera feel sliders (head bob, weapon sway, camera roll, impact shake, breathing, first-person
clunk boost, FP FOV — 0 turns an effect off, for competitive play; the FOV dial 70..110 maps to
a real 116..120° plus an eye pull-back of up to `EYE_PULL_MAX` so the whole sword stays in frame,
and nudges third person too) and keybinds. **Looking down** in first person: the pull-back fades
out over `LOOKDOWN_ANGLE` and the eye slides `LOOKDOWN_FWD` studs forward past the chest, and the
torso, tabard and torso armor fade in between `TORSO_SHOW_FROM` and `TORSO_SHOW_TO` — so you see
your chest front, legs and feet, never the top surface of your chest. **Start in** (Third person /
First person) is the view each spawn begins in (CameraRig reads it as it starts); the View key
switches any time. Stored in
`ReplicatedStorage.ClientSettings`, read live by CameraRig / CombatClient / Movement, and
saved per player by `SettingsServer` (DataStore; in Studio enable *Allow Studio access to API
services* or it just lasts the session).

## The training yard (Tiltyard mode) and bots

The training yard is a peaceful map: players can't hurt each other, but dummies and bots can be
hit (`GameConfig.MODES.Tiltyard.pvp = false`, the same as the Courtyard). `Game ▸ Training` runs
it from the map's `Spots`:
- **Straw dummies** on six posts: they take hits, never strike back, and pop back up.
- **Where to go:** a light beam and a bobbing arrow stand over your next stop (the straw dummy,
  the drill dummy, the ring, the Drill Master), with an arrow at the edge of the screen when it's
  out of view; the lesson card says GO TO › … (`DrillTarget` / `DrillTargetName` on the player).
- **Sir Aldric, the Drill Master**: E opens his menu: carry on, **stop the lessons** (no lesson,
  no beacon, until you ask again), **THE FULL COURSE** (the first day's course again, the same
  way: placed in front of each step's dummy, the card up top with STEP n / 14 and STOP THE COURSE,
  ending in the yard with COURSE COMPLETE: course `replay`), all lessons (pick any to learn or
  redo; you're put at its dummy too), spar in the ring, practice bots, the Gauntlet. There are 14 lessons
  (`Catalog ▸ Drills`), from the swing, stab and overhead to both sides, blocks, parries,
  ripostes, feints, morphs, kicks, dodges and chambers, then a first win in the ring. Each lesson
  watches the combat system's own signals (which attack landed, GuardTick, ParryTick, FeintTick,
  MorphTick, KickTick, LastDodgeAt, a CHAMBER guard). The first finish of each pays a drill
  (`earn.drill`, the drill stat for tasks and the Drill Master title). A card on the right shows
  the lesson in your own key binds, and he says it over his head.
- **Wren, the Bowmaster** (the archery range down the north-west wall: straw targets before
  straw butts, a near line and a far line) and **Magister Orrin** (the arcane circle in the yard's
  east end, open ground of its own past the ring: rune stones, banners, torches, three dummies
  standing close beyond it): each class's own lessons (`Catalog ▸ Drills`,
  `track = "archer"` / `"mage"`), fought dressed as that class (`_G.Respawn`, in place) and with
  the weapon they're taught with (`Drills ▸ tracks ▸ weapon`: a Bow for the Bowmaster even if your
  Archer carries a crossbow, the Arcane Staff for the Magister instead of a grimoire; your own skin
  for it if a loadout of yours has one; for that body only). No lesson on, no beacon: the guide's
  pillar of light used to stand on Sir Aldric for good once you'd finished. The
  Bowmaster's: loose, full draw (`LastHitPower`), a headshot, a hit from the far line, then a Squire
  charging down the range. The Magister's: a spell on a dummy, three different spells cast
  (`CastTick`), forty mana won back meditating, two blows warded (`WardHit`), one Chain Lightning
  striking two, two hits with the staff's melee self, then a charging Squire. A class still locked
  can't be taught: its teacher says "Come back when the ARCHER is unlocked. Unlock it by reaching
  LEVEL 5" (every way into its lessons checks it). They also have STOP THE LESSONS.
- **A class unlocked**: the level-up that opens it is followed by a card, ARCHER & MAGE UNLOCKED,
  naming their teachers in the Training Yard (`Celebrate.client`); in the Courtyard the menu then
  offers the trip to each.
- **Nobody gets stuck in basic training:** a step you've been at for 75 seconds, Sir Aldric
  waves you past (`ASSIST`); two lost fights in the ring and the last step counts anyway
  (`ASSIST_SPARS`); on a controller or a touch screen Find Your Feet has a GOT IT button. The trip
  to the first battle is tried again if the teleport fails on its way (HubServer:
  TeleportInitFailed, twice), then sent to a fresh server rather than leaving you in the yard.
- **Changes apply at once**, as in the Courtyard: save a loadout or pick a class in the menu and
  you're rebuilt where you stand (`_G.CourtyardRedress`).
- **Drill dummies** for the guard lessons (and footwork): one swings slowly at you, the other
  never drops its guard (so you can learn to kick it). They arrive with a lesson that needs them
  and leave when nobody's lesson does.
- **The sparring ring**: press E at the sign (or the menu) and pick a Squire, Knight or Champion
  bot. After a 3-2-1 it's a fight to the death; leaving the ring forfeits. **The countdown holds
  you on your mark** (`Training` `hold`: `SpeedMult_Hold` = 0, `HoldUntil` for the client,
  `StunnedUntil` for the server) with a full stamina bar, and the bots start on the same tick as
  FIGHT (the client counts to the server time it's sent). The first win at each
  level pays (`Catalog ▸ Drills ▸ spar`), once; the wins after are for the glory (kept per level). The last lesson's Squire
  comes out the moment you step into the ring.
- **The Gauntlet** (in the ring): waves of bots, each harder (Squire, two Squires, a Knight… then
  Champions), a breath, some health and all your stamina back between waves (and you're put back
  on your mark for the next 3-2-1), until you fall. Your best wave is
  kept (profile `gauntlet`); each wave past your best pays `Drills ▸ gauntlet.perWave` Marks.
- **The practice ground** (north-east, by the ring): call up one, two or three Squires, Knights
  or Champions at once and fight them, as often as you like (no pay).
- **New players** (no lessons, no rounds) heading for the Warfront or the Lists are asked once:
  *Would you like to complete the training first?* (profile `askedTraining`).

**Bots** (`Combat ▸ Bots`) fight on the real combat system: they carry a normal weapon Tool whose
controller runs in NPC mode.
- **The players' rules:** the same walk speed (`MovementConfig` × the armor's and weapon's
  `SpeedMult` × 0.8 sideways / 0.65 backwards, a sprint to close distance), the players' 400°/s
  turn cap while swinging (720°/s otherwise), the same stamina.
- **Tempers** (`Bots.TEMPERS`, one each at random): a *brute* presses more and barely waits its
  turn, a *duelist* plays it straight, a *wary* one hangs back and watches, a *flanker* works its
  way round behind you.
- **The crowd takes turns:** round each foe only the nearest two (a brute: three) fight; the
  rest keep a ring 10–15 studs out, circling, and step in when a gap opens or you leave yourself
  wide open. Six bots on one player is a fight, not a blender.
- **Brain** (10 Hz): footwork in moods that last a second or two — press in, circle at the
  edge of reach, stand and watch (`hesitate`), or give ground — weighted by `aggression`, its
  temper and its stamina, instead of one perfect spacing; it eases from one heading into the next (momentum),
  walks a beat before it chases (0.6–1.4 s) and then sprints only in bursts (2.6 s of every 4,
  not when winded). It steps in to swing (the blade lands at about 0.72 × `REACH`), punishes
  whiffs and parried swings, presses a foe low on stamina or stunned, kicks a guard held up too
  long; keeps `reserve` stamina and backs off to get it back.
- **A swing it doesn't parry**: `step` is the chance it steps back and aside — after its
  reaction time, for half a second, not a retreat — else it stands its ground and trades or eats
  the blow.
- **Reflexes** (every frame, from the foe's controller `snapshot`): a parry timed so the blade
  arrives mid-window, learning how long each of your attacks takes to land (`learned`); `bait` is
  the chance it guards early, which a late feint catches — and `fooled` the chance a feint gets
  it: its guard drops when the swing never comes, and your real one finds it in its re-guard
  cooldown. `miss` is the chance it doesn't read a swing at all, and its timing is off by up to
  `jitter`; winded (under 30 stamina) it misses more and times worse. A riposte after its own parry; feints
  and morphs when you raise your guard early against its swing; combos after a hit; chambers.
- **Disarmed:** it draws its spare (`spare`: a secondary) or goes and picks a weapon up
  (`Pickup.takeNpc`), facing where it walks.
- **Skill presets** (`Bots.SKILLS`): Squire / Knight / Champion. Drill and Guard are the training dummies.
- **Look:** each rank has its own sets and colours (`LOOKS`): levy cloth in umber and moss for
  Squires, mail and surcoats in navy and white for Knights, full plate in black and blood for
  Champions. Clients draw their walk (`NpcAnimator`: the hips swing with the root's replicated
  velocity, or the distance it covered over 0.15 s — frame-to-frame jumps made a sprinting bot
  read as standing still) and play their footsteps. The swing is written on `PreSimulation`,
  after the Animator: written any earlier, the weapon's idle pose wiped it before the legs moved.
  **Archer and Mage bots stand like players**: `NpcAnimator` poses them with `RigPose` from what
  the server publishes on the bot (`DrawAt` / `DrawTime` from `RangedServer`, `Aiming`, `AimPitch`,
  `Reloading`, the casts, `Warded`, `Meditating`), the bow drawn, the crossbow shouldered, the
  staff held in its stance.
- `Combat ▸ R6` builds a plain R6 rig from parts for bots, dummies and NPCs.
- Studio: `/bot Knight Longsword`, `/bot clear`.

## Test dummies (chat)

`/spawn idle` · `/spawn block` · `/spawn parry` · `/spawn attack` · `/spawn clear` — spawns an
R6 dummy holding the `Greatsword` (from `ServerStorage.Weapons`) 8 studs in front of you,
facing you, wearing your armor. `/spawn <mode> <WeaponName> [ArmorId|none]` picks
different gear. Attack dummies really hit and parry dummies really parry: their weapon
runs the combat module in NPC mode (server-side animation + server-side blade sweep).
Change `WEAPON_NAME` in `TestDummies` for another default weapon.

## Combat rules (Mordhau-ish)

- **Phases**: windup → release (blade live) → recovery. All scale with `SPEED_MULT` and the
  game's tempo (`GameConfig.TEMPO.swing`, 1.12). The base walk speed is `MovementConfig.BASE_SPEED` (11).
- **Physical blocking**: while holding RMB your weapon's `GuardHull` is raycast-visible.
  The incoming blade must touch it *before* a body part (a body hit whose point lies inside
  the hull also counts), and you must face the attacker within `BLOCK_CONE_DEG`.
  From behind / off-side / under the guard = clean hit.
- **Parry**: block raised within `PARRY_WINDOW` → attacker stunned, you get a riposte
  (`RIPOSTE_SPEED` tempo for `RIPOSTE_DURATION`). Re-tapping block spams no new windows.
- **Feint**: RMB during windup cancels the attack into a block (`FEINT_COST`).
- **Combo**: press a *different* attack during release/recovery to chain it, skipping recovery.
- **Kick (G)**: unblockable, staggers a held block. Needs your right leg.
- **Leg hits** deal damage only — they no longer knock you down.
- **Crouch (LeftControl)**: torso drops `CROUCH_DROP`, `SpeedMult_Crouch` slows you. Other
  players see it, so ducking under a high swing or leaning back from a stab is a real dodge.
- **Stamina** (`BlockMeter`): attacks, feints, kicks, blocks drain it. Hits 0 from a
  block → guard break stun. Guard hit while already at 0 → **weapon flies out of your hand**.
  A swing that cuts someone cleanly gives its whole cost back plus `HIT_BONUS` (2); a kill
  gives 20 % of your max; a blocked or parried one gives nothing; a whiff costs 0.6 again
  (`MISS_COST_MULT`). A held guard pays `BLOCK_COST_MULT` (0.8) × the attack's blockCost; a
  timed parry or a chamber pays nothing and a parry refunds. Every cost × the armor's
  `StaminaCostMult`. Regen: 13/s (× the weight's `RegenMult`) from 1.6 s after the last combat
  event, 20 % of that before it.
- **Armor**: protection on a covered limb × (1 − the weapon's `ARMOR_PEN`), × how well that
  armor stands up to the blow's damage type (`CombatServer.ARMOR_VS`). The type is the weapon's
  `DAMAGE_TYPE` if it sets one; otherwise every stab is **pierce**, hammers, maces, mauls and
  staves are **blunt**, axes and polearm heads **chop**, and swords **cut**. Cuts glance off plate
  (Heavy ×1.35, with sparks), pierce finds the gaps (×0.85–0.9), blunt hits go through plate
  (Heavy ×0.55) and chops sit in between. Light armor takes every type about the same.
- **Head**: `HEAD_DAMAGE_MULT` × damage (2× by default) — no automatic kill.
- **Rated Mild (all ages): `GameConfig.GORE = false`.** A killing blow just drops them, with
  the hit's white-and-gold flash (on a monster, what it's made of instead: bone chips off the
  dead, grave dust off ghouls, ice off the frost, embers off fire things, stone off golems, a wisp
  off a wraith: `Injury.hitFlash`, by its Bestiary body and Faction), the hitstop and the
  ragdoll, then the body fades within seconds
  (`Corpses.BODY_LIFE`; kill-effect remains keep their time). Off, there's no blood, nothing is
  severed or skewered, nobody bleeds out, arrows don't stay in bodies, there are no bone
  crunches, and the death screen and kill feed use clean words. The rest of this bullet list is
  what `GORE = true` brings back, and that makes the honest questionnaire answer Strong:
  Restricted (18+), which can never be changed back. See docs/LAUNCH.md for the answers.
- **Kills** (GORE): a lethal **slash** severs the limb it hit (arm, leg, or head → decapitation);
  with `BLEED_OUT_CHANCE` an arm/leg victim survives on `BLEED_HP` and bleeds out instead,
  screaming (`VoiceScream`, every `SCREAM_GAP` seconds, weaker as the blood runs out, gasps at
  the end: `VoiceGasp`), with no health coming back.
  A lethal **stab** leaves the weapon run through the body (`IMPALE`) until the corpse despawns.
  Lose the right arm → weapon dropped, can't wield. Lose the left arm → dropped only if
  `TWO_HANDED`. Trying to block one-armed flings the weapon. Each lost leg multiplies speed
  by `LEG_SPEED` and clunk by `LEG_CLUNK`.
- **Ragdoll**: leg hits knock you down for `KNOCKDOWN_TIME`; death ragdolls for good.
- **Death cam**: first person from inside your head wherever it rolls, then fade to black.
- **Disarmed weapons** land as real pickups; walk over one to grab it (after 2s).

## Pose replication

`CameraRig` computes your body pose (aim bend, lean, bob, kick, crouch, arm sway) with
`RigPose` and sends the 9 inputs ~20×/s over `PoseRemote` (an UnreliableRemoteEvent).
`PoseRelay` forwards them to every other player; their `RigReplicator` runs the same
`RigPose` math on your character, smoothed. Nothing is applied on the server. Pose shape
constants (`NECK_PITCH`, `CROUCH_DROP`, `KICK_ANGLE`, …) live in `RigPose.CONFIG` so
everyone renders the same body.

## Debug flags (live, no code changes)

Attributes on `ReplicatedStorage.Debug` — created automatically at startup. Toggle in
Studio via Properties → Attributes, or from the F9 console:

```lua
-- Server tab: everyone sees it. Client tab: only you (fine for Rays).
game.ReplicatedStorage.Debug:SetAttribute("Rays", true)
```

| Flag | Default | Effect |
|---|---|---|
| `Logs` | true | `print()` chatter from combat scripts |
| `Rays` | false | draw blade sweep rays (green miss / red hit) |
| `GuardHull` | true | show the block hull around weapons (brighter while blocking) |
| `Hitbox` | false | show weapon `Hitbox` parts |
| `TurnCap` | false | print when the camera turn cap engages |
| `Spectate` | — | client tab, dead in a match: true starts spectating, false stops it |

## Sound slots

**The fight's sounds come from `ReplicatedStorage ▸ SoundBank`**: pools of takes from Roblox's
licensed library (Pro Sound Effects — free in any experience). `Sounds.bank(pool, part)` plays a
random take (never the same one twice running), pitch-spread so repeats don't sound canned; a
take may be `cut` (faded out at a mark: the first hit of a file with several, a long ring
trimmed). What plays when:
- **Swing**: `SwingLight` (sword swishes) for one-handed weapons, `SwingHeavy` (deep whooshes,
  pitched down) for two-handers and polearms (`Catalog ▸ Weapons` family); `SwingKick` for kicks.
- **A blow that lands** (layered): `HitCut` (an edge through flesh: a sword-slice body chop and
  wet slices) or `HitBlunt` (a heavy thud, for `SoundBank.BLUNT`: Hammer, Mace, Morning Star,
  Maul, Quarterstaff) or `HitStab` (a point going in) by the attack's kind; `HitBone` (bones
  giving way) on half of blunt blows and every killing blow; `HitPlate` when the limb struck is
  covered by heavy armor, `HitMail` (mail jingling) under medium; then the victim's grunt.
- **Steel on steel**: `Parry` (a bright, ringing clash), `Block` (a duller clang: the guard soaks
  it), a chamber is the clash plus `Clash` (blades scraping).
- **The blade meets the world**, in two layers by the material's family (`SoundBank.WALL`,
  `WALL_FAMILY` in CombatServer): stone is steel striking stone (`WallStone`, a hard strike and a
  short ring) over a knock of grit (`WallGrit`); wood is iron biting oak (`WallWood`, solid thunks)
  and a chop (`WallWoodChip`); ground is a hard chop into earth (`WallGround`); metal clangs
  (`WallMetal`); glass rings high. Stone and metal spark. A material in no family (`Plastic`,
  `SmoothPlastic`) is silent.
- **Bodies**: `KickHit`, `BodyFall` / `BodyFallArmor` (a corpse hitting the ground, plate
  clanking), `Dismember`, `Impale`, `Disarm` (the weapon clattering away); dodges whoosh.
- **Voices**: see *Voice*.

A weapon's `Config.SOUNDS` may still name its own `Equip`, `Swing`, `Hit`, `Block`, `Parry`, `Kick`,
`KickHit` or `Wall` — a slot it names is used instead of the bank (a `Wall` it names is re-pitched
per family, `WALL_FEEL`). A `ClangSounds` folder (`SoundService` or `ReplicatedStorage`) with a
`Sound` named after a material or family overrides the wall sound too. Kill effects' sounds play
at `KillFX.VOLUME` (55 %). Global, in `SoundConfig`: `Footstep`, `Heartbeat`, `Death`, `Dismember`,
`Impale`, `Bleed`, `Disarm`, `Pickup`, `Dodge`, `HeadThrow`, `BodyFall`, `Breathing` — single ids
that play alongside the bank (`rbxassetid://0` = silent).

**Footsteps by material** (`ReplicatedStorage ▸ Footsteps`): one sound per step, picked by
what's underfoot. `SOUNDS` holds Grass, Metal/DiamondPlate, Pebble, Wood/WoodPlanks,
Plastic/SmoothPlastic, Sand and Rock; `LIKE` sends every other material to the closest one
(Slate, Cobblestone, Brick, Marble… sound like Rock; Ground and Mud like Grass; Snow like a
lower Sand). Each step is cut after `MAX_LENGTH` (0.45 s), so a clip that holds a run of steps
can't patter on after you stop. Your own steps are timed by `CameraRig` on the step bob; everyone
else's (other players, bots) by `StarterPlayerScripts ▸ Footsteps`, from how far their root
moved, heard within 70 studs. A `FootstepSounds` folder in `SoundService` (one `Sound` per
material name, plus `Default`) still overrides the table. Roblox's own looping `Running` and
`Climbing` sounds are muted on every character. **Water**: a step onto a puddle, standing water
or a marsh pool (the thin sheets `Puddle`, `StandingWater`, `Marshwater`, which nothing queries)
splashes instead (WarAudio ▸ Splash) with a ripple spreading on the water (`Footsteps.play`,
yours and everyone's). **Armour**: a body in mail (ArmorType Medium) jingles with each step, one
in plate (Heavy) clanks (WarAudio ▸ ArmorMail / ArmorPlate), a little under the step: yours
always, others' within 28 studs of the camera.

**Prints on the ground** (`StarterPlayerScripts ▸ Footsteps`, every body within 70 studs, yours
too): a step into snow, sand, salt, mud or bare earth presses an oval print there (left, right,
along the way it walks; darker than the ground, half see-through: an impression), fading over
its life (snow 40 s, sand 24, mud 26, earth 10); a run (over 17 studs a second) kicks up a little
puff of snow, sand or dust. At most 220 prints at once (100 on a phone, and no puffs), the oldest
reused first (workspace ▸ GroundMarks, on your screen only).

## Movement modifiers (composable)

Anything that scales speed or footstep clunk writes **one attribute per source** on the
character and clears it (`nil`) when done. Consumers multiply every attribute with the
prefix, so sources stack and never overwrite each other:

```lua
character:SetAttribute("SpeedMult_Armor", 0.7)   -- plate armor: 30% slower
character:SetAttribute("ClunkMult_Armor", 1.8)   -- …and 80% heavier steps
character:SetAttribute("SpeedMult_Armor", nil)   -- unequip
```

| Attribute | Set by |
|---|---|
| `SpeedMult_Weapon`, `ClunkMult_Weapon` | CombatServer (from the weapon `Config`) |
| `SpeedMult_Swing` | CombatServer while attacking or kicking |
| `SpeedMult_Crouch` | PoseRelay while crouched |
| `SpeedMult_Limbs`, `ClunkMult_Limbs` | Injury, per lost leg |
| `SpeedMult_Armor`, `ClunkMult_Armor` | Loadout `Armor` (from the set's `Config`) |
| `SpeedMult_Sprint`, `SpeedMult_Facing` | MovementServer (sprint; backpedal/strafe penalty) |
| bare `SpeedMult` / `ClunkMult` | you, by hand in Properties, for testing |

## Other character attributes

| Attribute | Set by | Read by | Meaning |
|---|---|---|---|
| `Blocking`, `BlockStoppedAt`, `ParryUntil`, `BlockMeter`, `BlockMax`, `StunnedUntil`, `FastUntil` | CombatServer | CombatServer (other players' tools), HUD | combat state; `BlockMeter` is stamina |
| `Crouching` | PoseRelay | anything | holding crouch |
| `Acting` | CombatServer / MovementServer | MovementServer, CharacterSystems | mid-attack or mid-kick (no dodge, no sprint, no regen) |
| `StaminaRegen`, `StaminaRegenDelay` | CombatServer (weapon `Config`) | CharacterSystems | stamina regen now runs per character, weapon or not |
| `Dropped` (on a Tool) | Pickup | Pickup | the weapon is on the floor |
| `LocalDodgeAt`, `LocalDodgeX/Z` | Movement | CameraRig | dodge lean/roll |
| `LastDodgeAt`, `DodgeRefundTick` | MovementServer / CombatServer | CombatServer, HUD | dodge timing (server clock); refund cue |
| `ParryTick` | CombatServer | InjuryFX | you parried / chambered (white edge flash) |
| `LastHitBy/ByName/With/Kind/At` | CombatServer | Scoreboard | kill credit |
| `ArmorId`, `ArmorType`, `ArmorProtection`, `BaseMaxHealth` | Loadout `Armor` | CombatServer, TestDummies | worn set; protection applies only to covered limbs |
| `LimbLost_LeftArm` … `LimbLost_Head`, `Bleeding`, `BleedDPS` | Injury | CombatServer, InjuryFX, HUD | injuries; a bandage system clears `Bleeding` |
| `KnockedDownUntil` | Ragdoll | Ragdoll | knockdown timer |
| `HitTick`, `HitDir` | CombatServer | CameraRig, InjuryFX | victim feedback (flinch, flash) |
| `TurnCapUntil` | CombatServer | server only | **server clock** — never compare on the client |
| `LocalTurnCapUntil` | CombatClient | CameraRig | turn cap deadline on the **client clock** |
| `LocalKickAt`, `LocalKickRise` | CombatClient | CameraRig | procedural leg kick |
| `LocalImpactAt`, `LocalImpactKind` | CombatClient | CameraRig | attacker feedback (impact kick) |
| `LocalWindAt`, `LocalReleaseAt` (+ `LocalAttackName`) | CombatClient | CameraRig | the weight of your swing: the view leans against the wind-up, then is dragged along the blade's path (side swing: turn and roll; overhead: a nod; stab: a punch in), scaled by the Shake setting |
