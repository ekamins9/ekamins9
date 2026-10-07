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
| `StarterPlayerScripts/AdminPanel.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `AdminPanel` | LocalScript |
| `ReplicatedStorage/Defight.lua` | `ReplicatedStorage` → `Defight` | ModuleScript |
| `ServerScriptService/Game/Modes/Siege.lua` | `ServerScriptService` → `Game` → `Modes` → `Siege` | ModuleScript |
| `ServerScriptService/Build/MapFrostgate.lua` | `ServerScriptService` → `Build` → `MapFrostgate` | ModuleScript |
| `ServerScriptService/Build/MapColosseum.lua` | `ServerScriptService` → `Build` → `MapColosseum` | ModuleScript |
| `ServerScriptService/Build/MapRoseCourt.lua` | `ServerScriptService` → `Build` → `MapRoseCourt` | ModuleScript |
| `ServerScriptService/Game/Modes/Horde.lua` | `ServerScriptService` → `Game` → `Modes` → `Horde` | ModuleScript |
| `ServerScriptService/Economy/Pastimes.lua` | `ServerScriptService` → `Economy` → `Pastimes` (gifts, eggs, hatching, companions) | ModuleScript |
| `ServerScriptService/Hub/Pastimes.server.lua` | `ServerScriptService` → `Hub` → `Pastimes` (playtime clock, the Hatchery) | Script |
| `ReplicatedStorage/Companions.lua` | `ReplicatedStorage` → `Companions` (creatures and eggs built from parts) | ModuleScript |
| `StarterPlayerScripts/Pastimes.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Pastimes` (companions following, the gift chip, your eggs in the nests) | LocalScript |
| `ServerScriptService/Economy/EconomyServer.server.lua` | `ServerScriptService` → `Economy` → `EconomyServer` | Script |
| `ServerScriptService/Build/<Name>.lua` | `ServerScriptService` → `Build` (Folder) → `Builder`, `Weapons`, `Armor`, `Body`, `Blueprints` | ModuleScript each |
| `ReplicatedStorage/Theme.lua` | `ReplicatedStorage` → `Theme` | ModuleScript |
| `ServerScriptService/Loadout/Profile.lua` | `ServerScriptService` → `Loadout` → `Profile` | ModuleScript |
| `ReplicatedStorage/Catalog/init.lua` | `ReplicatedStorage` → `Catalog` | ModuleScript |
| `ReplicatedStorage/Catalog/<Name>.lua` | `ReplicatedStorage` → `Catalog` → `Weights`, `Packs`, `Pieces`, `Weapons`, `Skins`, `Body`, `Palette`, `Crates`, `Economy`, `Contracts`, `Store`, `Pass`, `Login`, `KillFX`, `Emotes` (children of the Catalog ModuleScript) | ModuleScript each |
| `ReplicatedStorage/Dresser.lua` | `ReplicatedStorage` → `Dresser` | ModuleScript |
| `ReplicatedStorage/SkinTrims.lua`, `SkinFX.lua` | `ReplicatedStorage` → `SkinTrims`, `SkinFX` (a skin's trim parts; its trail and aura) | ModuleScript each |
| `ReplicatedStorage/KillFX.lua`, `Emotes.lua` | `ReplicatedStorage` → `KillFX`, `Emotes` (the effects and motions) | ModuleScript each |
| `ServerScriptService/Hub/Cosmetics.server.lua` | `ServerScriptService` → `Hub` → `Cosmetics` | Script |
| `StarterPlayerScripts/Cosmetics.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Cosmetics` (kill effects, emotes, the emote wheel) | LocalScript |
| `StarterPlayerScripts/HubMenu.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `HubMenu` | LocalScript |
| `StarterPlayerScripts/TravelScreen.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `TravelScreen` | LocalScript |
| `StarterPlayerScripts/Scoreboard.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Scoreboard` | LocalScript |
| `StarterPlayerScripts/NameTags.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `NameTags` | LocalScript |
| `StarterPlayerScripts/SkinFX.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `SkinFX` | LocalScript |
| `ServerScriptService/Loadout/Armor.lua` | `ServerScriptService` → `Loadout` (Folder) → `Armor` | ModuleScript |
| `ServerScriptService/Loadout/LoadoutServer.server.lua` | `ServerScriptService` → `Loadout` → `LoadoutServer` | Script |
| `ServerStorage/Armor/<Set>/Config.lua` | `ServerStorage` → `Armor` (Folder) → each set → `Config` | ModuleScript |
| `StarterPlayerScripts/LoadoutMenu.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript |
| `StarterPlayerScripts/RigReplicator.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `RigReplicator` | LocalScript |
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

**The weights trade real things** (`Catalog ▸ Weights`; the class cards show HP / ARMOR / SPEED /
STAMINA bars and the full line under each class):
- **Light (Vanguard):** 100 HP, 3% armor, 106% walk speed, the fastest sprint (×1.55), 115 stamina
  coming back 25% faster, dodges that cost 70% and go 25% further. One mistake from death.
- **Medium (Footman):** 106 HP, 12% armor, 96% speed, ×1.45 sprint, 100 stamina: the all-rounder.
- **Heavy (Knight):** 112 HP, 22% armor on covered limbs, 87% speed, ×1.32 sprint, 85 stamina
  coming back 20% slower, dodges that cost 140% and go 20% shorter. About 1.4× a Light's
  staying power (it was 2×): a Light that keeps moving and keeps the pressure on runs it dry.
  Blunt weapons and armor-piercing points ignore part of the armor (`ARMOR_PEN`, below).
Dresser publishes them as `StaminaMult`, `RegenMult`, `SprintMult`, `DodgeCost`, `DodgeReach`;
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
  ARMORY, SHOP (a NEW badge when the day turns), TASKS (open tasks counted), WARDROBE,
  SETTINGS. The big green **PLAY** opens the MODES board. Party members get **READY UP**
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
- **ARMORY**: a **✔ OWNED ONLY** filter (on by default) shows what you have in every tab; tap it
  to see everything there is to get and how. **WEAPONS** shows every weapon turning on a stage with
  its skin strip, a **STATS** card (reach, damage and head damage, stab, wind-up, stamina a swing,
  guard break, armor pierce, walk speed: bars against every other weapon, from
  `ReplicatedStorage ▸ WeaponStats`), and for
  each skin exactly where it comes from (crate, task, pack, the shop shelf) and its effects
  (trail, aura), plus EQUIP / AS SECONDARY. **ARMOR** shows every set worn by you, piece by
  piece. You can toggle pieces, see the stats of its weight, and BUY (on the days its pack is in
  the shop) or EQUIP on a class of that weight. **KILL FX** plays each kill effect on you, over
  and over, with EQUIP. **EMOTES** loops each emote on you and edits the six-slot wheel.
- **SHOP**: **DAILY** has the packs plus the **WEAPONS shelf** (single skins, a headliner and
  three more, new every day; `Catalog ▸ Store`). **CRATES** has the chosen item on a big stage
  (a skin turning on its weapon, a kill effect or emote played on you), the strip, odds, pity
  and the spinning drum. The **Relic Crate** holds kill effects and emotes. **CROWNS** has the Robux bundles and Crowns →
  Marks. **COLORS** has the premium colours.
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
  as silhouettes, stars, and TAKE IT ALONG / SEND IT HOME.
- **Playtime gifts** in the lobby's left column: the next gift, a live countdown and CLAIM.
- **WARDROBE**: faces as a picture grid, hair, hair colour, beard, skin, title.
- **SERVERS**: the browser with filters and **CREATE CUSTOM**: door, mode, map, player limit,
  round length, who may join, friendly fire, respawns, ground weapons, and cheats. A cheat
  server gives the host `/god /heal /speed /tp /bring /give /kick` and pays nobody.
- **SETTINGS**: camera feel, attack side, keybinds.

Every teleport puts up the **travel screen** (`TravelScreen`). `HubServer` answers all of it
(`HubRemote` / `HubEvent`), heartbeats this server into a MemoryStore `Servers` map for the
browser, and teleports through `TeleportService` — both need a published game; in Studio the
browser shows only this server and PLAY switches this server's mode locally.

**Money.** Marks are earned (`Catalog ▸ Economy ▸ earn`: round, win, kills, parries, chambers,
drills, first win of the day; paid by `Scoreboard` at round end through `Economy.award`, with a
pay card on screen) or exchanged from Crowns; Crowns come from Robux Developer Products
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
- **The Hatchery** (west), the stone circle (east), the tavern with a bard (south-east).

## Name tags and titles

Roblox's own overhead names are off (players: `LoadoutServer`; bots: `Bots`). `NameTags` (client)
draws ours, and only when it makes sense: someone within 9 studs, or your aim (the middle of the
screen, or the mouse when it's free) on their body within 45 studs with a clear line of sight;
in the Courtyard everyone within 24 studs shows too. Names fade in fast and out slowly.
- **The look:** a level badge, a staff badge (OWNER · ADMIN · MOD · HELPER in their role's colour),
  a gold crown and a gold shimmering name for **season pass** holders; team colours in team modes;
  bots in their rank's colour with their rank under the name (a Warlord in gold).
- **Titles** (picked in APPEARANCE; free, earned in battle or from the pass) show under your name
  tag, after your name on the Tab board, and after yours in the kill feed when you get a kill (the
  free *Recruit* is left out). The board and the feed crown pass holders too.
- The server publishes `Title`, `Level` and `PassHolder` on each player (`Hub ▸ Pastimes`, every
  second); `StaffRole` comes from the admin panel.

## Pastimes: playtime gifts, the Hatchery, companions (looks only)

Things to do between fights, so the Courtyard is a place to hang out. None of them touch combat.
- **Playtime gifts** (`Catalog ▸ Gifts`): six a day for minutes played on any server (the
  Courtyard and every match). A chip at the top left counts down to the next gift and claims it
  with a click; the lobby shows it too. Reset at 00:00 UTC.
- **The Hatchery** (`Catalog ▸ Eggs`): a thatched pavilion in the Courtyard with three nests,
  built by `Hub ▸ Pastimes`. Set an egg in a nest and it incubates in real time, even while you
  are away or in a match. Standing within 20 studs makes your eggs incubate twice as fast, and
  a line at the top says so. Your own eggs sit in the nests, wobbling when ready, with timers;
  press E to hatch or to open the menu. Nests keep real time (`started` = `os.time()` in the
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
  rate, the sparks fly, the light swells (a storm flickers) and the swing makes its sound.
- **Kill effects** (`KillFX` + `Catalog ▸ KillFX`): `Scoreboard` (and the training dummies) call
  `_G.KillFxHook(killer, victimCharacter)`; `Hub ▸ Cosmetics` checks the killer owns the equipped
  effect and fires `FxEvent "Kill"` to everyone **1.2 s after the death** (`KILL_FX_DELAY`), so the
  body falls first and a head that came off rolls away; each client (`Cosmetics.client`) builds it
  upright over the body, at a standing torso's height above the floor under it, in
  `workspace.LocalFX`, and hides the body locally. **Every effect has its sounds**, timed to it
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
    (Bow, Kneel, Jig, Windmill, Champion) need you standing still and end when you move.
  - **Fighting ends emotes:** attacking, blocking, kicking or dodging ends any emote at once (the
    keys locally, the character's `Acting` / `Blocking` flags for everyone), and no emote starts
    mid-fight.
  - **Feet stay planted:** a bend at the `waist` pivots on the hip line, and the legs are posed
    back to exactly where they were.
  - **The weapon:** it is steered by where the blade should point in the grip's own frame, so a
    dagger and a greatsword both salute upright, and a planted tip just meets the ground for any
    blade length. The animation (the weapon's idle guard) fades out and back in over 0.2 s, so
    nothing snaps.

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
names them. Inside a map: `Spawns` (Folder of parts; attribute `Team = "A"` / `"B"` on team
spawns, none = anyone; made invisible on load), optional `Zones` → `Hill` (a Part; KOTH capture
volume), and the geometry. Nothing to author for the menu camera: it measures the map's bounding
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

Every attack is `<Side><Type>` (Left/Right × Swing/Stab/Overhead/Underhand) with **one clip**:
`anim`, the swing. Its first frame is the loaded pose. **The windup is a blend**: the clip fades
in frozen on that first frame over `WINDUP` seconds — from idle, from a block, from another
windup on a morph — and that fade *is* the wind-up motion. No windup clips to make. Then the
clip runs: the active phase is its length (the server reads it with
`KeyframeSequenceProvider`, so a client can't lie). Windup, active and `RECOVERY` all divide by

    speed  ×  TYPE_SPEED[type]  ×  SPEED_MULT      (× RIPOSTE_SPEED after a parry)

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
- **Flinch only in windup** (`FLINCH_ONLY_WINDUP`): a hit stops a swing that hasn't committed;
  one already in release finishes. Trading is a choice now. Kicks still stop anything.
- **Stamina ledger** (Mordhau-style): the windup always costs `staminaCost`; **every enemy a
  swing hits refunds** `HIT_REFUND` (cut through three = three refunds); a whiff costs
  `MISS_COST_MULT` × the cost extra; a blade that hits a **wall / floor** stops there (clang,
  `WALL_RECOVERY`) with no penalty and no refund. Kick: land = `KICK_REFUND` back, whiff =
  `KICK_MISS_COST` + longer recovery, kick a wall = neither. A dodge that makes a swing miss you
  refunds `DODGE_REFUND`.
- **Parries are free and pay out** (`PARRY_COST_MULT` 0): each parry refunds the attacker's swing
  cost (at least `PARRY_REFUND`), growing by `PARRY_STREAK_STEP` (50 %) per parry within
  `PARRY_STREAK_WINDOW` (2 s) up to `PARRY_STREAK_MAX` — 1vX parry-parry-parry is 10, 15, 20…; the
  HUD word and the sparks grow with it. Holding block pays the full `blockCost` every hit **and**
  `BLOCK_HOLD_DRAIN` (3/s) while it is up (the turtle tax), and can't attack while up.
- **Exhausted**: a swing needs its `staminaCost` in the bank and a kick needs `KICK_COST`; at 0
  stamina you can only guard and walk (the HUD says EXHAUSTED). No more stabbing on empty.
- **Health regen**: `CharacterSystems` heals 2.5/s once stamina is full, you are not blocking,
  attacking or sprinting, and nothing has happened for 5 s. Health never slows you
  (`WalkSpeedGovernor` `MIN_HEALTH_F` 1): clutch at 5 HP at full speed.
- **Being parried doesn't stun you** (`PARRY_PUNISH_STUN` 0): your swing dies and eases back
  (`RECOIL`), and for `PARRIED_GUARD_WINDOW` (0.8 s) your guard comes up at once with a fresh parry
  window, cooldown or not — so the riposte can be parried or chambered right back. The riposte is
  the parrier's edge: for `RIPOSTE_DURATION` (1.2 s, i.e. the next swing) windups are `RIPOSTE_SPEED`
  (1.6×) quicker; a parry is a `PARRY_WINDOW` (0.4 s) guard.
- **Parry chain**: after a *successful* parry you can re-guard instantly with a fresh parry window
  for `PARRY_CHAIN_WINDOW` (1.5 s) — no `BLOCK_COOLDOWN`, no `PARRY_RETRY`. A guard that comes
  down without having parried **breaks the chain** (and the streak): back to the normal cooldown. Riposte (`FastUntil`) makes your **windup** `RIPOSTE_SPEED`× quicker; the swing
  itself plays at normal speed.
- **Walls**: hits are rejected when the line from your head to the hit point passes through solid
  geometry (`WALL_CHECK`), so nobody gets stabbed through a wall.
- **Per-region damage**: `damage` is a number (× `HEAD_DAMAGE_MULT` / `LEG_DAMAGE_MULT`) or
  `{head=, body=, legs=}`.
- **Animations fit the rules** (`FIT_ANIMS`): each attack's optional `windupAnim` is stretched to
  its windup, the release anim to active+recovery — so a morph, riposte or chamber re-times what
  you see. Attack names are `<Side><Type>` (see a weapon Config).
- A whiffed kick recovers `KICK_MISS_EXTRA` longer. Spawn protection: a `ForceField` for
  `SPAWN_PROTECT` s (LoadoutServer); attacking, kicking or blocking ends it early.

## Siege (Team Objective, after Chivalry 2)

The attackers take a castle stage by stage; the defenders hold until the clock runs out. Every
stage taken adds time (`AddTime`), sides swap each round, and the scores count rounds won. A map
lists its stages in `Map ▸ Objectives` (MapKit `K.objective`), each with a `Label` for the HUD:
- **Ram:** push the ram (`K.ram`) along its `Path` (`K.path`). It rolls while more attackers than
  defenders stand within `Radius` (13) of it, faster with more (up to 1.75×), and stops when
  they're even. At the gate it swings its log every `Interval` s while the attackers hold it,
  `Hits` blows break the `Gate` (`K.gate`) and the doors burst inward.
- **Capture:** stand in the `Zone` (`K.zone`): attackers with no defender in it fill it in
  `Time` s (faster with more), defenders alone push it back, both = contested. The disc turns
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

The HORDE door (PLAY board): you and your party against waves of bots, in a Friends server like
the Training Yard. A short breather, then wave 1 pours in through the map's gates (`Spots ▸
HordeGate1..n`): each wave bigger and better trained (Knights from wave 3, Champions from 6), a
**Warlord** every fifth wave. At most 10 bots are on the field at once; the rest wait their turn.
The fallen spawn again between waves (12 s), and the standing get all their stamina and a quarter
of their health back; when everyone is down at once the horde wins and the round ends. Players
can't hurt each other and bots don't hurt each other. Each wave beaten pays
everyone `wave` (15 Marks, 30 XP), each bot killed pays `kill`, and your best wave is kept
(`stats.hordeBest`). The HUD shows the wave, the foes left and the countdown between waves.

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

## Rounds

See *Game modes, maps, places* above. The top-centre strip shows the mode, the map, the
clock, the mode's objective line and (team modes) both scores. At the end everyone is pulled
out, the board comes up with the result, your pay for the round and the vote, then the class
screen returns.

## Voice

Put a folder `Voice` in `SoundService` with subfolders `Swing`, `Hurt`, `Death`, `Kick`, `Parry`,
each holding any number of `Sound`s — one is picked at random (its own Volume/PlaybackSpeed are
the baseline). Missing folders are silent.

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
V) in `workspace.DroppedWeapons`, for `DESPAWN` seconds. Slots: **one primary + one secondary**
(a weapon whose `Config` has `SECONDARY = true`), `MAX_WEAPONS` total; taking a weapon for a full
slot drops what was in it right there. The loadout menu offers a secondary list from the same
flag. Switch weapons with the Roblox backpack (1 / 2).

## Skewered heads

A **lethal** face stab (no more auto-execute — `STAB_HEAD_EXECUTE` is off) hangs the victim's
head on your blade, sitting exactly on its axis. It stays there until your next swing, then flies
off forward at `HEAD_THROW_SPEED`: `HEAD_THROW_DAMAGE` and a `HEAD_THROW_STUN` on whoever it
hits (it can finish someone low). Unequipping just drops it.

## Kill feed + leaderboard

`Scoreboard` keeps `leaderstats` (Kills, Deaths) per player and fires a kill-feed entry on every
death. Credit: CombatServer stamps `LastHitBy` / `LastHitWith` / `LastHitKind` on a character
each time it hurts it (swings, kicks, thrown heads); a death within `CREDIT_WINDOW` (15 s) of
the last hit counts for that attacker, a bleed-out included. **Hold Tab** for the board (kills,
deaths, K/D, sorted by kills, team-coloured in team modes; replaces Roblox's list). Dummies show
in the feed, not the board. Every player death also goes to `Game.onDeath` (tickets, lives,
round kills) and into the player's `Profile` stats; the board resets each round.

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
your chest front, legs and feet, never the top surface of your chest. Stored in
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
- **Sir Aldric, the Drill Master**: E opens his menu: carry on, start over, all lessons (pick any
  to learn or redo), spar in the ring, practice bots, the Gauntlet. There are 13 lessons
  (`Catalog ▸ Drills`), from the swing, stab and overhead to both sides, blocks, parries,
  ripostes, feints, morphs, kicks, dodges and chambers, then a first win in the ring. Each lesson
  watches the combat system's own signals (which attack landed, GuardTick, ParryTick, FeintTick,
  MorphTick, KickTick, LastDodgeAt, a CHAMBER guard). The first finish of each pays a drill
  (`earn.drill`, the drill stat for tasks and the Drill Master title). A card on the right shows
  the lesson in your own key binds, and he says it over his head.
- **Drill dummies** for the guard lessons (and footwork): one swings slowly at you, the other
  never drops its guard (so you can learn to kick it). They arrive with a lesson that needs them
  and leave when nobody's lesson does.
- **The sparring ring**: press E at the sign (or the menu) and pick a Squire, Knight or Champion
  bot. After a 3-2-1 it's a fight to the death; leaving the ring forfeits. **The countdown holds
  you on your mark** (`Training` `hold`: `SpeedMult_Hold` = 0, `HoldUntil` for the client,
  `StunnedUntil` for the server) with a full stamina bar, and the bots start on the same tick as
  FIGHT (the client counts to the server time it's sent). A first win at each
  level pays (`Catalog ▸ Drills ▸ spar`); wins are kept per level. The last lesson's Squire
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
- **Brain** (10 Hz): hold just out of the foe's reach, step in to swing (the blade lands at
  about 0.72 × `REACH`), punish whiffs and parried swings, press a foe low on stamina or stunned,
  kick a guard held up too long; keep `reserve` stamina and back off to get it back.
- **Reflexes** (every frame, from the foe's controller `snapshot`): a parry timed so the blade
  arrives mid-window, learning how long each of your attacks takes to land (`learned`); `bait` is
  the chance it guards early, which a late feint catches; a riposte after its own parry; feints
  and morphs when you raise your guard early against its swing; combos after a hit; chambers.
- **Disarmed:** it draws its spare (`spare`: a secondary) or goes and picks a weapon up
  (`Pickup.takeNpc`), facing where it walks.
- **Skill presets** (`Bots.SKILLS`): Squire / Knight / Champion. Drill and Guard are the training dummies.
- **Look:** each rank has its own sets and colours (`LOOKS`): levy cloth in umber and moss for
  Squires, mail and surcoats in navy and white for Knights, full plate in black and blood for
  Champions. Clients draw their walk (`NpcAnimator`: hips swing from how far the root moved each
  frame) and play their footsteps.
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

- **Phases**: windup → release (blade live) → recovery. All scale with `SPEED_MULT`.
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
  A swing that cuts someone cleanly gives its whole cost back (at least `HIT_REFUND`); a
  blocked or parried one gives nothing; a whiff costs half again (`MISS_COST_MULT` 0.5). A held
  guard pays `BLOCK_COST_MULT` (0.8) × the attack's blockCost; a timed parry pays nothing.
  Regen: 17/s (× the weight's `RegenMult`) from 1.3 s after the last combat event.
- **Armor**: protection on a covered limb × (1 − the weapon's `ARMOR_PEN`).
- **Head**: `HEAD_DAMAGE_MULT` × damage (2× by default) — no automatic kill.
- **Kills**: a lethal **slash** severs the limb it hit (arm, leg, or head → decapitation);
  with `BLEED_OUT_CHANCE` an arm/leg victim survives on `BLEED_HP` and bleeds out instead.
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

## Sound slots

Per weapon, in `Config.SOUNDS`: `Equip`, `Swing`, `Hit`, `Block`, `Parry`, `Kick`, `KickHit`, `Wall` —
these default to shared ids in `CombatServer.DEFAULTS.SOUNDS` so combat is audible immediately.
**Clangs by material:** when the blade hits the world, CombatServer looks in a `ClangSounds`
folder (`SoundService` or `ReplicatedStorage`) for a `Sound` named after the `Enum.Material`
hit (`Slate`, `Wood`, `Metal`…) or its family — `Stone`, `Metal`, `Wood`, `Ground`, `Glass` —
with no folder the `Wall` slot is re-pitched per family (`WALL_FEEL`), so stone rings, metal
rings higher, wood knocks, dirt thuds — but `Wall` ships as `rbxassetid://0`, i.e. wall hits are
silent until you either give `Wall` an id or fill the folder. A material in no family (`WALL_FAMILY` in CombatServer —
`Plastic` and `SmoothPlastic` are deliberately not in it) is **silent**, no sparks, unless the
folder has a Sound with that exact material name. Stone and metal spark; nothing pops up on the
HUD for a wall hit.
Only list slots you've filled: an `rbxassetid://0` entry overrides the default with silence.
Global, in `SoundConfig`: `Footstep`, `Heartbeat`, `Death`, `Dismember`, `Impale`,
`Bleed`, `Disarm`, `Pickup`, `Dodge`, `HeadThrow`, `BodyFall` (these are still mostly `rbxassetid://0`, i.e. silent).

**Footsteps by material** (`ReplicatedStorage ▸ Footsteps`): one sound per step, picked by
what's underfoot. `SOUNDS` holds Grass, Metal/DiamondPlate, Pebble, Wood/WoodPlanks,
Plastic/SmoothPlastic, Sand and Rock; `LIKE` sends every other material to the closest one
(Slate, Cobblestone, Brick, Marble… sound like Rock; Ground and Mud like Grass; Snow like a
lower Sand). Each step is cut after `MAX_LENGTH` (0.45 s), so a clip that holds a run of steps
can't patter on after you stop. Your own steps are timed by `CameraRig` on the step bob; everyone
else's (other players, bots) by `StarterPlayerScripts ▸ Footsteps`, from how far their root
moved, heard within 70 studs. A `FootstepSounds` folder in `SoundService` (one `Sound` per
material name, plus `Default`) still overrides the table. Roblox's own looping `Running` and
`Climbing` sounds are muted on every character.

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
