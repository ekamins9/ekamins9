# Content guide — adding stuff without touching code

Everything the game sells, equips, rolls or pays lives in **config ModuleScripts** under
`ReplicatedStorage` → `Catalog` and in **model folders** under `ReplicatedStorage` → `Cosmetics`.
You add content by editing those modules and dropping models in; no script changes.

```
ReplicatedStorage
├─ Catalog               ModuleScript  (the aggregator — never edit; `Catalog/init.lua` in the repo)
│  ├─ Weights            Light / Medium / Heavy stats (the ONLY place armor stats live)
│  ├─ Packs              named releases of pieces (starter packs are free)
│  ├─ Pieces             helmets / tops / bottoms — usually empty: sets auto-import
│  ├─ Weapons            which Tools exist and how each unlocks
│  ├─ Skins              weapon skins (crate / earned / task / pack / daily shelf), generated
│  ├─ Body               hair, beards, faces, skin tones, hair colors, titles
│  ├─ Palette            armor colors (premium ones cost Crowns)
│  ├─ Crates             loot tables, odds, pity, duplicate refunds
│  ├─ Economy            earn table, Robux products, Crowns→Marks, levels, ranks
│  └─ Contracts          daily / weekly goals that pay Marks
└─ Cosmetics             (made by the server if missing)
   ├─ Armor/<Set>/…      mirrored from ServerStorage ▸ Armor — your sets
   ├─ Pieces/<id>/…      one-off pieces that are not a whole set
   ├─ Skins/<Weapon>/<Skin>   optional skin models
   ├─ Weapons/<Weapon>   a display copy of each weapon (menu mannequin)
   ├─ Body/Hair/<id>     hair models
   ├─ Body/Beard/<id>    beard models
   └─ Rig                optional: your own R6 mannequin for the menu
```

Reload the place (or restart the server) after editing a config module: the server reads
them once at start.

## 0. Blueprints — models you don't have to build (yet)

Nothing in the catalog needs a hand-made model to work. `ServerScriptService ▸ Build` holds
**blueprints** (lists of parts with sizes, colors and attributes) for every shipped weapon,
armor set, hair, beard and face. When the server starts, `Build ▸ Blueprints.ensureAll()`
builds whatever is missing:

- a weapon Tool with scripts but **no Handle** gets its body (Handle, Hitbox with the right
  long axis, blade / haft / head parts with `SkinPart` attributes, all welded to the Handle)
- an armor set folder with a Config but **no clothing models** gets them (Middle-based,
  `ColorSlot` color blocks)
- `Cosmetics ▸ Body ▸ Hair / Beard / Face` get every id from `Catalog ▸ Body`
- `Cosmetics ▸ Weapons` gets a display copy of every Tool for the menu mannequin

Hand-made models always win: the builder only fills gaps, never overwrites. To **edit a built
model by hand**, open Studio, press Run or type in the command bar
`require(game.ServerScriptService.Build.Blueprints).ensureAll()`, then stop — the models are
now real instances you can reshape, save, and keep. To **replace** one, delete the built one
and put yours in its place with the same name.

Adding a new weapon or set with a blueprint: write `W.MyWeapon = function() … end` in
`Build ▸ Weapons` using the sub-assemblies (`sword{}`, `axeBit`, `spearhead`, `haft`, `grip`…)
or `A_.MySet = {HeadClothing = …, TorsoClothing = …}` in `Build ▸ Armor` (`plateTorso`,
`gambeson`, `hood`, `greatHelm`, `vambrace`…). Sizes are studs on an R6 body.

**Generator.** `scripts/gen_content.py` (run from the repo root) writes the weapon Tool folders
(`Tools/<id>/Config, Server, Client`), the armor set folders (`ServerStorage/Armor/<Set>/Config`)
and `Catalog ▸ Weapons` + `Catalog ▸ Skins` from the tables at the top of the script. Add a row
to `WEAPONS` or `SETS` (or a tint to `TINTS`) and re-run it; edit those four outputs by hand
only if you stop running the script.

---

## 1. An armor set (helmet + top + bottom)

Drop the set into `ServerStorage` → `Armor` → `<SetName>` exactly like your existing sets
(`HeadClothing`, `TorsoClothing`, `LeftArmClothing`, `RightArmClothing`, `LeftLegClothing`,
`RightLegClothing`, each built around a part named `Middle`). The server mirrors it into
`Cosmetics ▸ Armor` and the catalog turns it into **three pieces**: `<SetName>_Helm`,
`<SetName>_Top`, `<SetName>_Legs`. The set's `Config` decides the rest:

```lua
return {
	Type        = "Heavy",        -- Light | Medium | Heavy — REQUIRED (which classes may wear it)
	Name        = "Iron Crow",    -- pieces are named "Iron Crow Helm / Top / Legs"
	Pack        = "IronCrow",     -- a key in Catalog ▸ Packs (default: the free starter pack of that weight)
	Rarity      = "Rare",         -- Common | Rare | Epic | Legendary (label only)
	PriceMarks  = 700,            -- 0 or missing = free
	PriceCrowns = 35,             -- 0 or missing = not sold for Crowns
	Covers      = {"Hair"},       -- what the helmet hides: "Hair", "Face", both, or {}
	HelmName = "Crow Sallet", TopName = "Crow Hauberk", LegsName = "Crow Chausses",  -- optional
	Description = "Black iron, worn by the Crow company.",
}
```

Stats come from the **weight only** (`Catalog ▸ Weights`): every Heavy piece gives the same
health / speed / protection, so looks never buy power. A set may skip slots (no
`HeadClothing` → no helm piece).

**Color blocks.** Give any part in the models an attribute `ColorSlot` (string) =
`Primary`, `Secondary`, `Accent` or `Metal`. The player's four colors paint those parts;
parts without the attribute keep their own color. In team modes `Primary` becomes the
team color and `Secondary` a darker shade of it, and the tabard is not added.

## 2. A single piece that is not a whole set

Make a folder `Cosmetics ▸ Pieces ▸ <id>` holding only the models that slot wears
(helmet: `HeadClothing` · top: `TorsoClothing`, `LeftArmClothing`, `RightArmClothing` ·
bottom: `LeftLegClothing`, `RightLegClothing`) and add a line to `Catalog ▸ Pieces`:

```lua
PIECES = {
	{id = "Sallet", name = "Sallet", slot = "helmet", pack = "IronCrow", rarity = "Epic",
	 marks = 900, crowns = 45, covers = {"Hair"}, description = "A visored helm."},
}
```

An entry with the same id as an auto piece (e.g. `KnightSkin_Helm`) overrides that
piece's fields — the way to reprice one piece of a set.

**Earned pieces.** Give the entry `unlock` instead of a price and put it in pack `"Earned"`:
`{level = 10}`, `{kills = 100}`, `{kills = 100, family = "Polearm"}`, `{kills = 50, weapon = "Hammer"}`,
`{wins = 25}`, `{wins = 10, bracket = "1v1"}` or `{stat = "parry", n = 200}`. It is never sold;
the shop's EARNED IN BATTLE panel shows the progress and the CLASSES list shows a 🔒 with the
requirement until it is met.

## 3. A pack

A pack is just a key in `Catalog ▸ Packs`; pieces (or a set's `Config.Pack`) name it:

```lua
IronCrow = {name = "The Iron Crow", weight = "Heavy", featured = true, bundle = 0.15,
            color = Color3.fromRGB(106, 77, 42)},
```

`featured` puts it first in the shop, `bundle` is the discount for buying the rest of the
pack at once, `color` is the card. A pack that only exists through auto pieces gets a
default entry, so you can skip this step for free sets.

## 4. A weapon

1. Build the Tool like the others (copy the three scripts, edit only its `Config`) and put
   it in `ServerStorage ▸ Weapons`.
2. Add it to `Catalog ▸ Weapons`:
   ```lua
   {id = "Falchion", name = "Falchion", family = "OneHanded", secondary = true,
    unlock = {level = 8}, marks = 1200},
   ```
   `unlock` is `{free = true}`, `{level = n}` or `{kills = n, family = "OneHanded"}`;
   `marks` lets it be bought outright (0 = cannot). `weights = {"Heavy", "Medium"}` limits
   who may carry it.
3. For the menu mannequin put a **display copy** in `Cosmetics ▸ Weapons ▸ Falchion`: a
   Model with a part named `Handle` (the Tool's visible parts, copied, work).

## 5. A weapon skin

`Catalog ▸ Skins` is generated: edit the tables in `scripts/gen_content.py` (`TINTS`,
`SHOP_STYLES`, `TASK_SKINS`) or the hand-written lines in `scripts/skins_handmade.part`, then
run `python scripts/gen_content.py --skins`. A line looks like this (every weapon already has
a free "Default"):

```lua
{weapon = "Falchion", name = "Bluesteel", rarity = "Rare", crate = "Bladesmith",
 blade = Color3.fromRGB(138, 168, 216), grip = Color3.fromRGB(42, 42, 74),
 trim = "fuller", accent = Color3.fromRGB(70, 120, 220)},
```

**Where it comes from. Skins are never sold at will:**
- `crate = "Bladesmith"`: rolled from that crate, and from nowhere else.
- `crate = "earned", kills = 100`: unlocked by 100 kills with that weapon.
- `unlock = {stat = "contract", n = 20}`: unlocked by finishing 20 daily tasks. Any unlock
  works here, e.g. `{level = 10}` or `{stat = "parry", n = 500}`.
- `pack = "IronCrow"` plus `marks` / `crowns`: sold with that pack, on the days the pack is in the
  store. It counts toward the bundle price.
- `marks` / `crowns` alone: a **WEAPONS shelf** skin. It is sold only on the days the store offers
  it. That is `skinSlots` offers a day, drawn by the date, one weapon and one style each, the first
  an Epic or Legendary headliner. Pin a day's lineup with `skinPins` in `Catalog ▸ Store`, or take
  a skin off the shelf for good with `skinRetired`.

**How it looks:**
- **Tints:** parts in the Tool with attribute `SkinPart` = `"Blade"` or `"Grip"` are recolored
  with `blade` / `grip`. Put that attribute on your weapons' parts once.
- **Trim (the shape change):** `trim` names a builder in `ReplicatedStorage ▸ SkinTrims`. The
  builders are `wrap rivets rings fuller studs notch laurel feather spikes flame frost runes royal
  crown halo bone serpent wave thunder`. The trim adds parts around the weapon (winged guards,
  gems, thorns, flames, a halo, a crown…), fitted from the weapon's own Blade / Grip boxes, so
  one trim fits every weapon. `accent` colors its metal (default: gold on Epic / Legendary, steel
  below) and `glow` its Neon. Add a new trim by writing a builder in `SkinTrims` and naming it in
  a skin.
- **Effects (`ReplicatedStorage ▸ SkinFX`):** Epic and Legendary skins leave a swing **trail**
  in the colour of their `glow` (else `accent`, else the rarity). `trail = false` turns it off,
  `trail = true` gives one to a lower rarity. `fx = "embers"` adds an **aura** of particles
  around the blade: `embers frost holy shadow storm toxic petals gold blood` (every Legendary
  has one; `FX_BY_NAME` in the generator picks them by skin name). Trails and particles only
  show in the world, so the menu names them on the skin ("Trail · Embers").
- **Models:** for a full re-model, put a Model in `Cosmetics ▸ Skins ▸ <Weapon> ▸ <SkinName>`
  with its own `Handle`. Its parts replace the Tool's visible ones (welded by their offset from
  the model's Handle). Hitbox and guard parts stay as they are.

## 6. A crate

Add a key in `Catalog ▸ Crates` and point skins at it:

```lua
Siege = {name = "Siege Crate", description = "Hammer and polearm skins.",
         cost = 60, odds = {Common = 60, Rare = 28, Epic = 10, Legendary = 2}, pity = 20,
         refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000}},
```

`odds` must sum to 100 (they are shown to the player). `pity` guarantees a Legendary within
that many opens. `refund` is the Marks paid for a duplicate. A crate can also list skins
directly: `skins = {"Greatsword:Gilded", "Hammer:Bronze"}`.

A crate can hold **kill effects and emotes** too (the `Relic` crate holds only those): give the
line in `Catalog ▸ KillFX` or `Catalog ▸ Emotes` `crate = "Relic"`. The strip, the stage and
the prize pop-up show each kind its own way (a skin on its weapon, an effect or emote on you).

## 6b. Kill effects and emotes

**Kill effects** (`Catalog ▸ KillFX`): what the body does when *you* land the killing blow,
seen by everyone. One is equipped at a time (ARMORY ▸ KILL FX). A line:

```lua
{id = "Inferno", name = "Inferno", rarity = "Epic", crate = "Relic", description = "A column of fire..."},
```

The `id` must match a builder in `ReplicatedStorage ▸ KillFX` (the ten there: `Shatter Confetti
GoldRush CrowSwarm Inferno Frozen ShadowRift Thunderstrike Ascension RoyalDecree`). A builder
makes parts that fly, spin, grow and fade around the body (so the same effect plays in the world
and in the menu preview) and can hide or tint the body locally. Particles and lights are
world-only extras.

**Emotes** (`Catalog ▸ Emotes`): played from the emote wheel (hold **B**, point, let go;
rebindable), up to six on the wheel (ARMORY ▸ EMOTES). The `id` must match a motion in
`ReplicatedStorage ▸ Emotes`: a duration and keyframes `{time, pose}`. A pose is in degrees, each
joint turned in its parent's frame:
- `rs` / `ls` / `neck`: x+ swings an arm forward; z+ lifts the right arm out (z- the left).
- `waist`: a bend at the hips that keeps the feet planted.
- `rh` / `lh`: the legs, for dances and kneels.
- `root`: the whole body turns (a spin). `rootY`: the body sinks or rises, in studs. `hopY`: a hop
  that only plays while standing.
- The weapon: `blade = {x, y, z}` (where it points, in the body's frame), `plantW = 1` (tip to the
  ground ahead), `twirl` (a wheel beside the body) and `rotor` (flat overhead), plus `toss` (it
  flies).

Mark arms-only emotes `upper = true` so they play while walking. Attacking, blocking, kicking or
dodging ends any emote; moving ends a whole-body one. Start and end on the resting pose
(`{blade = {0, 0, -1}}`) so it blends in and out.

**Where they come from** (both lists): `free = true` (everyone has it) · `crate = "Relic"` ·
`pass = true` (a season-pass reward names it: `{killfx = "ShadowRift"}` / `{emote = "WarCry"}`)
· `unlock = {...}` (earned, like a skin). Neither ever changes damage, speed or anything else:
looks only.

## 7. Hair, beards, faces, skin, hair colors, titles

All in `Catalog ▸ Body`. Hair and beards are `{id, name, crowns}` (`crowns` = premium,
bought once). Models go in `Cosmetics ▸ Body ▸ Hair ▸ <id>` and `Cosmetics ▸ Body ▸ Beard ▸ <id>`:
either a Model with a part named `Middle` the size of the Head (like a `HeadClothing`), or
an Accessory-style Model with a `Handle` and a `HairAttachment` / `FaceFrontAttachment`.
Hair parts are recolored with the hair color unless a part has attribute `KeepColor = true`.
An id with no model still lists (nothing shows) so you can set up the catalog first.
`earnedTitles` are `{title, unlock}` with the same `unlock` forms as pieces; a title shows
locked with its requirement until it is met. Faces are `{id, name, texture}` with a decal id (`"rbxassetid://…"`) or `""` to keep the
rig's face. `skins` are skin-tone Color3s. Helmets hide hair when their `covers` has `"Hair"`,
beard and face when it has `"Face"`.

## 8. Colors

`Catalog ▸ Palette`: `{name, color}` is free; add `crowns = 60` for a premium color (bought
once, usable on every slot of every class). Order = menu order.

## 9. Money: products, exchange, pay, levels, ranks

`Catalog ▸ Economy`:
- `products` — Crown bundles. Create Developer Products in the Creator Dashboard
  (Monetization) and paste their ids into `id` (0 = the button says "not set up yet").
  Receipts are handled by `EconomyServer` and credited once per receipt.
- `exchange` — Crowns → Marks tiers (one way).
- `earn` — Marks and XP per event (round, win, kill, parry, chamber, drill, first win of the day).
  A custom server with cheats on pays nothing.
- `levels` — XP per level-up, `levelMarks` the Marks each level pays.
- `rankTiers`, `rankStep`, `ratingStart`, `placementMatches`, `queueLockMinutes`, `seasonDays`.

## 10. Contracts

`Catalog ▸ Contracts`: `{id, text, stat, goal, pay, weekly}`. Three dailies and one weekly
are drawn from the pool per date (everyone gets the same ones). `stat` is any counter the
server keeps: `kill`, `parry`, `chamber`, `win`, `round`, `drill`, `kill_<Family>`,
`win_<bracket>`.

## 10b. The season pass and login rewards

**Season pass:** `Catalog ▸ Pass`.
- `season` is the id; a new id starts everyone at tier 0. `name` and `ends` (a UTC date) are
  shown on the PASS screen.
- `price` is the premium track in Crowns. `tierXP` is the pass XP per tier. Every round's XP
  counts as pass XP, and each finished daily task adds `taskXP` (three times that for the weekly).
- `tiers` is a list of `{free = reward, premium = reward}`. A reward is `{marks = n}`,
  `{crowns = n}`, `{skin = "Weapon:Name"}`, `{title = "..."}`, `{crate = "Royal"}`,
  `{killfx = "ShadowRift"}` or `{emote = "WarCry"}`. A crate reward is one free open, rolled on
  the server.
- Skins a pass gives should carry `pass = true` in `Catalog ▸ Skins` (`PASS_SKINS` in
  `scripts/gen_content.py`), so nothing else sells them.
- Testing in Studio: `/passxp 5000`.

**Login rewards:** `Catalog ▸ Login`. `days` holds one reward per day, seven in a row. A
player can claim once per UTC day. A missed day restarts the streak at day 1, and after day 7
it loops. The pop-up shows itself on the first menu open of the day.

## 11. Maps, modes, doors

- **Map:** a Model in `ServerStorage ▸ Maps ▸ <Name>` with a `Spawns` folder (parts; attribute
  `Team = "A"/"B"` for team spawns), optional `Zones ▸ Hill`; add its name to a mode's `maps`
  in `GameConfig.MODES`.
- **Mode:** a ModuleScript in `ServerScriptService ▸ Game ▸ Modes ▸ <Id>` built on
  `Game.Mode`, plus an entry in `GameConfig.MODES`; list it in `GameConfig.DOORS.Warfront.modes`
  to put it in the Warfront vote.
- **Door:** `GameConfig.DOORS` + `DOOR_ORDER` (the four cards on PLAY).
- **Class:** `GameConfig.CLASSES` — a name, a `weight`, optional weapon list.

## 12. The first release

[RELEASE_CONTENT.md](RELEASE_CONTENT.md) lists every model the shipped catalog expects, with
its Studio location, price and unlock.

## 13. Checking your work

Run the place once with the Output open. `Catalog` warns about every piece without models,
every skin naming an unknown weapon or crate, every weapon with a bad unlock. The menu
lists pieces "with no model" too, so you can see the catalog before the models exist.
