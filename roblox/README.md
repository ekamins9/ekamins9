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
| `ServerScriptService/Economy/EconomyServer.server.lua` | `ServerScriptService` → `Economy` → `EconomyServer` | Script |
| `ServerScriptService/Loadout/Profile.lua` | `ServerScriptService` → `Loadout` → `Profile` | ModuleScript |
| `ReplicatedStorage/Catalog/init.lua` | `ReplicatedStorage` → `Catalog` | ModuleScript |
| `ReplicatedStorage/Catalog/<Name>.lua` | `ReplicatedStorage` → `Catalog` → `Weights`, `Packs`, `Pieces`, `Weapons`, `Skins`, `Body`, `Palette`, `Crates`, `Economy`, `Contracts` (children of the Catalog ModuleScript) | ModuleScript each |
| `ReplicatedStorage/Dresser.lua` | `ReplicatedStorage` → `Dresser` | ModuleScript |
| `StarterPlayerScripts/HubMenu.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `HubMenu` | LocalScript |
| `StarterPlayerScripts/TravelScreen.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `TravelScreen` | LocalScript |
| `StarterPlayerScripts/Scoreboard.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `Scoreboard` | LocalScript |
| `ServerScriptService/Loadout/Armor.lua` | `ServerScriptService` → `Loadout` (Folder) → `Armor` | ModuleScript |
| `ServerScriptService/Loadout/LoadoutServer.server.lua` | `ServerScriptService` → `Loadout` → `LoadoutServer` | Script |
| `ServerStorage/Armor/<Set>/Config.lua` | `ServerStorage` → `Armor` (Folder) → each set → `Config` | ModuleScript |
| `StarterPlayerScripts/LoadoutMenu.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `LoadoutMenu` | LocalScript |
| `StarterPlayerScripts/RigReplicator.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `RigReplicator` | LocalScript |
| `StarterCharacterScripts/CameraRig.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript |
| `StarterCharacterScripts/InjuryFX.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `InjuryFX` | LocalScript |
| `StarterCharacterScripts/HUD.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `HUD` | LocalScript |
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

## Hub menu (M)

`HubMenu` is the front door: **M** anywhere (Escape belongs to Roblox). It opens by itself
when you have no body in the Courtyard, over the cinematic camera; in a match M pauses with the
same menu (RESUME · RETURN TO COURTYARD). The side bar holds the four **doors**
(`GameConfig.DOORS`): **Courtyard** (the hub, public servers), **Tiltyard** (a friends-only
reserved server for you and your party), **Warfront** (public battle servers; the mode is voted
between rounds from `DOORS.Warfront.modes`, then the map), **The Lists** (1v1 · 2v2 · 3v3,
casual or ranked, through the matchmaker). Tabs — **PLAY**: your party on the stage — you stand
up front in the middle, teammates and open slots (shadows) around you; the leader clicks a
shadow to invite and the ✕ over a teammate to remove them — with **ready-up** (every member
readies, the leader's PLAY only goes when all are ready; a party is at most `PARTY_MAX` = 3 and
always travels together; friends in other servers can be invited too — the invite crosses
servers by MessagingService and accepting teleports them to the leader). In a courtyard, the Courtyard card's button spawns you instead of
travelling, the leaderboard (ranked ratings per
bracket, Warfront kills), daily contracts, friends; on The Lists the bracket / casual-ranked
card with FIND MATCH and the queue. **APPEARANCE**: hair, beard, face, skin, hair color, title.
**CLASSES**: the loadout editor with a live mannequin and TEAM PREVIEW. **SHOP**: crates (the
drum shows each skin on its weapon in 3D — a display model in Cosmetics ▸ Weapons ▸ <id>,
flat colors until one exists — with odds, pity, duplicate refunds), packs, weapons, premium colors; **GET CROWNS** opens the
Robux bundles and the Crowns → Marks exchange. **SERVERS**: the browser with filters and
**CREATE CUSTOM** (door, mode, map, player limit, round length, who may join, friendly fire,
respawns, ground weapons, cheats — a cheat server gives the host `/god /heal /speed /tp
/bring /give /kick` and pays nobody). **SETTINGS**: camera feel, attack side, keybinds.
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
`FFA`, `Duel`, `TDM` (tickets), `LTS` (one life per round, first to `roundsToWin`), `KOTH`
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
ticks, clock, early end) → result → intermission with the board up and a 3-map vote
(Round `Vote1..3` / `Votes1..3`, `VoteRemote`). State is on `ReplicatedStorage.Round`
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
`PriceCrowns`, `Covers` (`{"Hair"}`, `{"Hair", "Face"}`), per-piece names and a description;
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
Space dodge (a ~2-stud sidestep, side or back, 10 stamina) · LeftControl/C crouch · **Z first /
third person** (no scroll zoom any more) · V pick up a weapon · Tab leaderboard. **There is no
jumping.** Walking backwards is 35% slower and sideways 20% slower — dodge to reposition fast.

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

## Rounds

See *Game modes, maps, places* above. The top-centre strip shows the mode, the map, the
clock, the mode's objective line and (team modes) both scores. At the end everyone is pulled
out, the board comes up with the result and the map vote, then the class screen returns.

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

**Footsteps by material:** put a folder named `FootstepSounds` in `SoundService`
(or `ReplicatedStorage`) containing one `Sound` per `Enum.Material` name — `Grass`,
`Slate`, `Metal`, `Wood`, `Sand`, … plus an optional `Default`. `CameraRig` fires one
of these per step (the stepped clunk drives the timing, so they're one-shots rather
than loops) and falls back to `SoundConfig.Footstep` if the folder isn't there. Each
sound's own `Volume` and `PlaybackSpeed` are used as the baseline, then scaled by
step weight. Roblox's built-in looping `Running` sound is removed automatically.

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
