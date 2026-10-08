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
only if you stop running the script. A weapon row's `speedMult` is its walk speed while held
(heavier = a little slower, never faster than 1.04), and `PEN` (next to the table) gives a
weapon its `ARMOR_PEN`, the share of armor it ignores (blunt heads and armor-piercing points).
The Armory reads every weapon's numbers from `ReplicatedStorage ▸ WeaponStats`, which
`LoadoutServer` fills from the Configs at startup: nothing to add for a new weapon.

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
	Covers      = {"Hair"},       -- what the helmet hides: "Hair", "Face" (face and beard), "Beard" (beard only), or {}
	HelmName = "Crow Sallet", TopName = "Crow Hauberk", LegsName = "Crow Chausses",  -- optional
	Description = "Black iron, worn by the Crow company.",
}
```

**A crate set** (never sold; its pieces drop one at a time out of a crate, each a tradable copy,
`"armor:" .. pieceId`): add `Crate = "Forge"` and `Pack = "Forge"`, and give it a finish of its own
with `Finish = "Emberforged"` (it keeps the set's metal and cloth, and only lights the trims and
brings the aura; worn with the set's TOP unless the class picked a finish). Its models can come from
a blueprint in `Build ▸ Armor` (`A_.<SetName> = set(helm, torso, armFn, legFn)`) until hand-made
ones exist. The Forge's four: Dragonscale (Heavy), Frostwarden (Medium), Shadowveil (Light), Seraph
(Medium, Mythic: wings of light). The War Chest's six (`Crate = "WarChest"`): Ranger, Berserker,
Corsair, Deathless, Lionheart, Obsidian. Give a crate set **its own colours** with
`Colors = {Metal = Color3.fromRGB(…), Accent = …, Secondary = …}`: those slots ignore the
player's paint (team colours still win in team modes), so the set always looks like itself.

**A spell** (`ReplicatedStorage ▸ MagicSpells`): `S.MySpell = {name, glyph, kind, mana, cast,
cooldown, color, glow, desc, …its numbers}` with `kind` one of `bolt` (speed, range, radius, damage,
headMult, burn = {dps, time}, splash, splashDamage), `chain` (range, width, damage, chain,
chainRange, chainDamage), `nova` (radius, damage, slow, slowTime) or `heal` (range, width, heal,
healTime). A staff casts the ones its Config lists (`SPELLS`, in the spell bar's order); a new
`kind` needs a resolver in `Combat ▸ MagicServer` (`RESOLVE.<kind>`) and a look in `MagicFX`.
A new staff: a Tool folder like `Tools/Staff` (its Config: `SPELLS`, `ORB`, `GRIP`), a blueprint in
`Build ▸ Weapons` and a `magic = true` line in `Catalog ▸ Weapons`.

**An armor finish** (`Catalog ▸ ArmorFX`): `{id, name, rarity, crate, description, look = {metal,
metalMaterial, accent, glow, tint, body, aura, light, pulse | flicker | radiant}}`: the plates
recoloured, the trims lit, an aura from `SkinFX` off the shoulders, arms and legs. It goes on any
set of any weight, one per class (LOADOUT › FINISH), looks only, a tradable copy
(`"finish:" .. id`). The rarer, the more alive: Rares recolour, Epics glow and shed something,
Legendaries crackle, Mythics walk the rainbow or burn. The rarity also brings, with no config
(`StarterPlayerScripts ▸ ArmorFX`): glints on the plates and a flare on every kill (all), footprints
of the aura's element (Epic +), light streaks off the limbs and a surge ring (Legendary +), orbiting
motes and a glowing rim (Mythic). Any crate can carry a finish: `crate = "Ossuary"`.

Stats come from the **weight only** (`Catalog ▸ Weights`): every Heavy piece gives the same
health / speed / protection, so looks never buy power. A set may skip slots (no
`HeadClothing` → no helm piece). A weight's row: `health` (added to 100), `prot` (damage
removed on covered limbs), `speed` (walk), `sprint` (sprint multiplier), `stamina` (× the 100
bar), `regen` (× stamina regen), `cost` (× every stamina cost: swings, feints, kicks, blocks),
`dodgeCost` and `dodgeReach` (× the dodge's cost and distance),
`clunk` (footsteps). Keep the trade honest: what a weight gains in health and armor it pays
in speed, stamina and footwork (see the README's *Classes* section for the current numbers).

**Color blocks.** Give any part in the models an attribute `ColorSlot` (string) =
`Primary`, `Secondary`, `Accent` or `Metal`. The player's four colors paint those parts;
parts without the attribute keep their own color. In team modes `Primary` becomes the
team color and `Secondary` a darker shade of it, and the tabard is not added.

**What shows through the gaps.** The limb under a torso / arm / leg model is painted a shade
of the garment, so no skin peeks between plates. It takes the model's `Under` attribute if
it has one (a `ColorSlot` name such as `"Secondary"` for the cloth under the plates, or a
Color3), else the colour of its biggest painted part. A garment that leaves the hand (or any
end of the limb) bare gets a skin-coloured sleeve there automatically — nothing to set.
Meshes built by `scripts/build_armor.py` get `Under` from their blueprint.

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
4. **Its sounds** come from `ReplicatedStorage ▸ SoundBank` by itself: a heavy whoosh if its
   family is `TwoHanded` or `Polearm`, sword swishes otherwise; a cut, or a thud and crack if
   its id is in `SoundBank.BLUNT` (add a mace-like weapon there). To give it a sound of its
   own, name the slot in its `Config.SOUNDS` (`Swing`, `Hit`, `Block`, `Parry`, `Wall`…).

**Sounds in general** (`SoundBank.POOLS`): each pool is a list of takes — add an id (or
`{id, vol = 0.8, speed = 1.1, cut = 0.6}`) and it joins the rotation. Use sounds the game may
play: Roblox's licensed library (Pro Sound Effects, APM) or your own uploads.

## 5. A weapon skin

`Catalog ▸ Skins` is generated: edit the tables in `scripts/gen_content.py` (`LOOK`,
`DROP_SKINS`, `TINTS`, `SHOP_STYLES`, `TASK_SKINS`, `PASS_SKINS`) or the hand-written lines in
`scripts/skins_handmade.part`, then run `python scripts/gen_content.py skins`. A drop skin
looks like this (every weapon already has a free "Default"):

```lua
{weapon = "Executioner", name = "The Marrow King", rarity = "Mythic", crate = "Ossuary",
 drop = "Bonewright", look = "marrowking", fx = "toxic"},
```

**Rarity:** Common, Rare, Epic, Legendary, **Mythic** (crates only: every crate has one, at its
lowest odds), **Unique** (one of one: `unique = true, who = "…"`; never in a crate or the shop;
`gen_content.py` `UNIQUE_SKINS`; give it as a season champion's reward or from F2 ▸ item). The
rarer, the more it gets: Mythics and Uniques wear two trims (`trim2`) and an aura of their own
(`celestial inferno sovereign phoenix`); a Unique's colours walk through the rainbow. New crate
Mythics go in `gen_content.py` `MYTHIC_SKINS`.

**The daily shelf** (`Catalog ▸ Store`): `epicChance` / `legendaryChance` decide the headliner;
the rest are Commons and Rares. Mythics, Uniques, earned, pass and task skins never show there.

**Where it comes from. Skins are never sold at will:**
- `crate = "Ossuary"`: rolled from that crate, only while the crate is in rotation
  (`Catalog ▸ Calendar ▸ crates`). When the crate leaves, the skin is VAULTED; if the crate is
  `retire = true` (event crates) it is a RELIC and never comes back.
- `drop = "Bonewright"`: hidden everywhere until that drop goes live.
- `limited = 2026` (with `crowns`): only that many are ever made, each numbered; the shop
  shows the stock and SOLD OUT. Feature it with a Calendar `features` line.
- `claim = "JacksGrin"`: a free numbered gift to everyone who plays while that Calendar claim
  is open. `founder = true`: the same for the Founders' window.
- `crate = "earned", kills = 100` / `unlock = {…}` / `pass = true` / `pack = …` / shelf
  `marks` / `crowns`: as before (kills, tasks, the pass, a pack on its day, the WEAPONS shelf).

**How it looks: the Forge.** `look = "<theme>"` names a theme in `blender/themes.py`. The Forge
(`blender/forge.py`) builds the weapon's own recipe under the theme: a new edge (serrated,
jagged, nicked, waved, barbed — axe heads too), a new guard and pommel, a new grip wrap,
ornaments (a serpent, chains, candles, feathers, a web, thorns, a tassel), a pattern painted into
the steel (damascus, rust, blued, frost, scales, stripes, stars, filigree, embers, bark, knotwork,
waves, camo) and Neon inlays raycast onto the flats (runes, cracks, lightning veins, a core
line, stars, a halo, crystals). One theme fits all 26 weapons.

To make or change skins:
1. Add / edit a theme in `blender/themes.py` (see the header for every option). Preview it:
   `blender -b --python blender/forge.py -- --preview out.png Longsword:mytheme Mace:mytheme`.
2. Name it on skins with `look = "mytheme"` (the generator's `LOOK` table by name, or the line).
3. Build the meshes: `blender -b --python blender/forge.py -- --manifest` (every skin) or
   `-- Longsword:"My Skin":mytheme` (one). They land in `blender/out/skins` (gitignored).
4. Upload: `python scripts/upload_skins.py` (only what changed; ids stay in the gitignored
   `blender/out/skins/uploads.json`).
5. Assemble in Studio: `python scripts/skin_entries.py` writes the gitignored
   `Build/_SkinUploads.lua`; then in Studio
   `require(game.ServerScriptService.Build.SkinModels).build(require(game.ServerScriptService.Build._SkinUploads), 1, 40)`
   (and 41, 80, …). Delete `_SkinUploads.lua` afterwards and **save the place**: the models live
   in `ReplicatedStorage ▸ Cosmetics ▸ Skins ▸ <weapon> ▸ <skin>`.

Without its model in Studio a skin falls back to the old tints (`blade` / `grip`) and trim.
**Effects (`SkinFX`):** Epic and up leave a swing trail; `fx` adds an aura
(`embers frost holy shadow storm toxic petals gold blood`).
**Arrows (`ArrowFX`):** on a Bow or Crossbow skin, `arrow = "<kind>"` dresses its arrows: a
coloured trail, a glowing head, particles and a light in flight, a burst where they land, and a
stuck arrow that smoulders for 3 s (`fire frost shadow holy storm toxic gold blood void spirit`), each with
its own impact (`IMPACT`) and release / impact sounds (`snd`). A new kind
is one row in `ArrowFX.KINDS`. A bow or crossbow skin's `trim` comes from the ranged set
(`SkinTrims` `RT`, fitted to the limbs / prod: bands fletch horn thorn crystal wing ember frost
runic skull gilded storm venom blood void dragon halo). The ranged skins are hand-written lines in
`scripts/skins_handmade.part`; most roll from the Fletcher crate.
**Finishes:** every copy out of a crate rolls Masterwork (5%: a gold glint) or Radiant (1%: its
glow, trail and aura cycle through colours) — `Catalog ▸ Economy ▸ variants`.

## 6. A crate

Add a key in `Catalog ▸ Crates`, a line in `Catalog ▸ Calendar ▸ crates` saying when it is in
rotation, and point skins at it:

```lua
Ossuary = {name = "Ossuary Crate", description = "Bone blades. Mythic: The Marrow King.",
           cost = 75, odds = {Common = 50, Rare = 30, Epic = 14, Legendary = 5.5, Mythic = 0.5},
           pity = 20, refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000, Mythic = 6000}},
-- Calendar:  Ossuary = {windows = {{from = "Bonewright", to = "Ironclad"}}},
```

`odds` must sum to 100 and every rarity in them needs an item (the server warns). Every crate
has a **Mythic** at the lowest odds (0.3–0.5%) and a long `pity` (20–40): rare must feel rare.
`refund` is only what a spare copy scraps for when its owner chooses: duplicates are kept, never
paid back. They are
shown before every open, with the finish chances; `pity` guarantees a **Legendary or better**
within that many opens (when it is due the odds on screen switch to say so). A crate opens for
`cost` Crowns or `keys` Keys (default 1). Keys are earned only (level-ups, the first win of the
day, events). **Roblox's paid-random-item rules:** where `PolicyService` restricts paid random
items, Crowns can't open crates (Keys still can), eggs aren't sold, and a crate or egg inside
something bought (the premium pass) becomes Marks. Don't remove those checks.

A crate can also hold **kill effects and emotes** (`crate = "Relic"` on the line in
`Catalog ▸ KillFX` / `Catalog ▸ Emotes`).

**Its chest.** Every crate is a 3D chest in the menu (`ReplicatedStorage ▸ CrateModels`, built
from parts, no art needed): the gallery the CRATES page opens on, the corner of its page, and the
burst-open before the reel. Give it a look with `look = {wood = Color3, metal = Color3, emblem =
"skull", glow = Color3}` on the crate (or a line in `CrateModels.LOOKS`); with none it takes its
`accent` and a star. Emblems: sword · axe · hammer · gem · arrow · skull · crown · star · anchor · flame.

## 6a. A drop (a weekly release) — the whole recipe

Everything rides on `Catalog ▸ Calendar`. A drop goes live **by itself** at its `at` time (UTC)
on every server: no restart, no update on the day.
1. Add the drop: `{id = "Krakens", at = "2027-01-16 16:00", name = "…", tag = "NEW CRATE",
   color = …, blurb = "…", headline = "Messer:Davy's Locker", crate = "BlackSails", egg = "Tide"}`.
2. Its skins: rows in `DROP_SKINS` (gen_content.py) with `drop = "Krakens"` and a `look`;
   regenerate, then Forge → upload → assemble (section 5).
3. Its crate (section 6) with a Calendar window; its egg and companions (section 10c) with
   `drop = "Krakens"` and an `eggs` window.
4. An event? An `events` line (`from`, `to`, `earn = {xp = 2}` for a double-XP weekend,
   `modes = {"Horde"}` to limit it). A free numbered gift? A `claims` line.
5. **Publish the place before `at`.** Test it first in Studio: `/clock 2027-01-16 17:00` jumps
   the clock there (`/clock reset` comes back); `/drop now Krakens` releases it early.
6. On live servers staff can release a drop early or hold one back from the admin panel
   (F2 ▸ server ▸ DROPS), on every server at once.

**What stays and what rotates:** Bladesmith, Hafted and Relic crates and the Speckled, Mossy,
Ember and Royal eggs are always there. Each drop's crate and egg rotate in for 2–3 weeks, then
are vaulted (they may return: give them another window). Event crates and eggs (`retire = true`)
never return: their items become RELICS, which is what makes them worth something.

## 6f. Season rewards

`Catalog ▸ Economy ▸ seasonRewards`: `Warfront` and `Lists` are lists of `{top = n, reward = …}`
(best line reached is paid; a reward is like a pass reward: marks, crowns, keys, title, skin…),
`tiers` pays by the ranked tier finished in. `champions` = {[season id] = {[board] = skin id}}:
rank 1 on that board also gets that Unique (one of one). The season's end is `Catalog ▸ Pass` `ends`; a new
season (a new `season` id) gets fresh boards automatically.

## 6e. Ranged weapons

A bow or crossbow is a Tool under `Tools/<Name>` with `Config.lua` (ranged keys: `KIND` "bow" |
"crossbow", `DRAW_TIME`, `NOCK_TIME`, `RELOAD`, `SPEED_MIN/MAX`, `GRAVITY`, `DAMAGE`, `HEAD_MULT`,
`ARMOR_PEN`, `QUIVER`, `REGEN`, `SWAY_*`, `STRING` = the string's tips and rest in Handle space),
a `Server.server.lua` calling `RangedServer.attach` and a `Client.client.lua` calling
`RangedClient.attach`; its body is a blueprint in `Build ▸ Weapons` (a bow's limbs along ±Y, bowed
toward +Z; a crossbow's tiller along -Z). List it in `Catalog ▸ Weapons` with `family = "Ranged",
ranged = true` (and in `RANGED` in `scripts/gen_content.py`, so a regeneration keeps it). Only a
class with `ranged = true` can carry it.

## 6d. Bot fill and the newcomer's course

- How many fighters a Warfront mode fills to: `botFill` on the mode in `GameConfig.MODES`
  (remove it and that mode gets no bots). Skill mix, weapons and names: `BotFill.CONFIG`.
- Basic training's steps: `basic = true` on a lesson in `Catalog ▸ Drills` (in their order there).
- A class's starting weapons: `primary` / `secondary` on the class in `GameConfig.CLASSES` (free
  weapons; a secondary must have `secondary = true` in `Catalog ▸ Weapons`).

## 6b. Kill effects and emotes

**Kill effects** (`Catalog ▸ KillFX`): what the body does when *you* land the killing blow,
seen by everyone. One is equipped at a time (ARMORY ▸ KILL FX). A line:

```lua
{id = "Inferno", name = "Inferno", rarity = "Epic", crate = "Relic", description = "A column of fire...",
 remains = "ash", remainsAt = 1.9},
```

`remains` is what the effect leaves on the field (`Combat ▸ Corpses`): `body` (the default),
`skeleton`, `ash` (a charred skeleton in ash), `charred`, `gold` (a statue with a crown), `rubble`,
`coins`, `confetti`, `shards`, `rift`, `light`, `none`, `grave` (a headstone over a mound), `flat`
(squashed into a dent), `stone` (a statue), `mound` (sand), `puddle` (dark water and a tentacle
tip), `garden` (a mossy mound in flower), `crater` (charred in a crater) or `bones` (a picked
pile, the skull on top); `remainsAt` is how many seconds into the effect they take the body's
place — when the effect has hidden the body. A new kind of remains is a builder in `Corpses`
(`KIND.<name> = function(model, body) … end`); one that doesn't copy the body itself also goes in
`AFTER_BODY`, so it still comes on time when a player respawns before it is due.

The `id` must match a builder in `ReplicatedStorage ▸ KillFX` (`Shatter Confetti GoldRush
CrowSwarm Inferno Frozen ShadowRift Thunderstrike Ascension RoyalDecree`, and the Grim Crate's
`Poof Tombstone Anvil Petrify Quicksand Kraken Overgrown Meteor SerpentsMaw HeavensHand
BlackHole`). A builder makes parts that fly, spin, grow and fade around the body (so the same
effect plays in the world and in the menu preview) and can hide or tint the body locally. To
move the body itself, take its puppet (`puppet(folder, origin, opts)`) and pose, squash or fade
that. Particles and lights are world-only extras.

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

**Its effects** (`ReplicatedStorage ▸ EmoteFX.DEF[id]`): a list of cues on the emote's clock, e.g.
`{"ring", t = 0.8, d = 0.7, at = "feet", color = GOLD, r0 = 0.6, r1 = 4}`. Kinds: ring, pillar,
burst, motes, orbit, bolt, spark, glint, wings, halo, cloud, scorch, confetti, notes, and in the
world only light, sound (`{id, vol, speed, cut}`) and trail. `at` = feet · chest · head · tip · hand
· lhand · sky. They're built from glowing parts, so the menu's previews show them. **The rarer the
emote, the more it does**: a Common glints, a Mythic calls down the sky.

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
locked with its requirement until it is met. `skins` are skin-tone Color3s. Helmets hide hair
when their `covers` has `"Hair"`, beard and face when it has `"Face"`.

**Faces are built from layers** (`faceParts`): `eyes` (each with its iris, tinted with the eye
colour, and its pupil; `noIris = true` for closed shapes), `brows` (tinted with the hair colour),
`mouth`, `mark` (scars, freckles, an eyepatch…) and `paint` (war paint, tinted with the paint
colour), plus `eyeColors` and `paintColors` (`crowns` = premium). Each layer is a Decal in
`Cosmetics ▸ Body ▸ FaceParts ▸ <layer>_<id>` (iris / pupil: `iris_<eyes>`, `pupil_<eyes>`), drawn
by `blender/face_parts.py` (tinted layers drawn white) and previewed with `blender/face_preview.py`.
A new part: draw it there, render, upload as a Decal, put it in FaceParts, list it here. `faces`
are now **presets** (`parts = {eyes, brows, mouth, mark, paint}`); the old single-texture faces in
`Cosmetics ▸ Body ▸ Face` are only a fallback.

New hair from a blueprint: `Build ▸ Body` (`Body.Hair.<id>` specs), then `scripts/build_armor.py
Body/Hair/<id>` (Blender → meshes → upload → `assemble_armor.lua`, run in Studio).

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
player can claim once per UTC day. A missed day doesn't start the run over (the next visit gives
the next day's gift), and after day 7 it loops. The pop-up shows itself on the first menu open
of the day.

A reward anywhere (pass, login, gifts) can also be `{egg = "Mossy"}` or
`{companion = "IronHound"}`.

## 10c. Playtime gifts, eggs and companions

**Playtime gifts:** `Catalog ▸ Gifts`: `gifts = {{minutes = 10, reward = {...}}, ...}`, in
order. Minutes count on every server and reset at 00:00 UTC. `wishes` is the Courtyard
fountain's daily wish: `{weight, reward}` entries, drawn by weight.

**Eggs:** `Catalog ▸ Eggs`.
- `nests` (how many incubate at once), `boost` (how many times as fast by the Hatchery),
  `radius`, and `spot` (where the Hatchery stands in a hub map, as an offset from the map's
  Floor; a part named `HatcherySpot` in the map wins).
- `skipCrowns` / `skipMin` set the HATCH NOW price. `stars` caps a duplicate's stars, and
  `refund` is the Marks paid once a companion has all its stars.
- An egg: `{id, name, rarity, minutes, marks | crowns (on the shelf; neither = gifts / pass /
  login only), odds = {Common = 64, ...} (sum 100), shell, spots, glow, look}`.
- `look` is how the shell is drawn (`ReplicatedStorage ▸ Companions`, in the `spots` colour):
  `speckled` (the default), `mossy` (moss and a sprout), `ember` (glowing cracks; with
  `glow` it smoulders) or `royal` (gold bands, gems and a little crown; with `glow` it
  sparkles).

**Companions:** `Catalog ▸ Companions`: `{id, name, rarity, body, size, main, second,
accent, glow, style, fx, egg, pass, description}`.
- `body` is a builder in `ReplicatedStorage ▸ Companions`: `bird` (flies; `style = "walker"`
  walks), `beast` (four legs; styles `mane`, `antlers`, `crown`, `spines` (a hedgehog), `horn` (a
  unicorn)), `hopper` (`longears`), `wisp`, `drake` (`style = "beak"` makes a griffin), `snake`
  (slithers and flicks its tongue; `hood` makes a cobra), `turtle` (`grove` grows a tree on its
  shell) or `crab`.
- `fx`: `embers`, `frost`, `spirit` or `sparkle` (world-only particles).
- `egg = "Royal"`: the egg that hatches it. **Every companion names its egg** and every egg is
  `exclusive`: nothing hatches from every egg (a companion with no egg would hatch from none of
  them). `pass = true` means only a reward gives it.
- Each egg must have a companion of every rarity it can roll (the catalog warns when one is
  missing).

**Eggs in rotation:** `Catalog ▸ Calendar ▸ eggs` decides when an egg is on the shelf (like
crates). A drop's egg sets `exclusive = true` and only hatches companions with `egg = "<id>"`,
which carry `drop = "<drop id>"` so they stay hidden until it is out. Every hatch is a copy of
its own (tradable) and rolls a finish: Golden (4%) or Spectral (1%) — `Catalog ▸ Eggs ▸ variants`.
Mythic companions (one per event egg) are numbered. New body styles: `bat` (a drake), `pumpkin`
and `kraken` (wisps), `bones`, `tusks`, `reindeer`, `round` (beasts).

## 10e. What a blade sounds like on the world

`ReplicatedStorage ▸ SoundBank`: `WALL[family]` lists the pools a blade striking that family
plays (Stone, Wood, Metal, Ground, Glass, Ice), and `WALL[material]` gives one material its own
(Marble rings longer than other stone). Families per material: `CombatServer ▸ WALL_FAMILY`.
A `ClangSounds` folder in SoundService only speaks for a material in no family. Licensed
library sounds only.

## 10d. Skin sounds

`ReplicatedStorage ▸ SkinFX`: `SWING` (from each aura's `swing`) plays once per real swing;
`HUM` = {[aura] = {sound, pitch, volume}} is the loop while it's held. Keep a hum under ~0.1 volume:
it should be heard standing next to someone, never across the yard. Licensed library sounds only.

## 10b. The newcomer's intro

- **The name and the line** on the intro's title card: `GameConfig.GAME_NAME`, `GameConfig.TAGLINE`.
- **The class a new player starts as**: `GameConfig.DEFAULT_CLASS` (its `primary` is their weapon).
- **The recruit's gift** (once, after the menu tour): `Catalog ▸ Economy ▸ starterGift`, a reward like
  a pass reward. Keep a Key in it: the gift card sends them straight to the crates.
- **The cinematic's lines, the welcome's words, the first battle's tips**: `StarterPlayerScripts ▸
  Intro` (`LINES`, `showWelcome`, `BRIEF`, the `tip(...)` calls). Its shots are the Courtyard map's
  own camera shots (`K.camera` in `Build ▸ MapCourtyard`).
- **The menu tour's stops**: `StarterPlayerScripts ▸ MenuTour ▸ STEPS` (a target is a name inside the
  HubMenu: `Play`, `Dock_<TILE>`, `Wallet`, `ProfileChip`, `LobbyLeft`, `LobbyRight`).
- **Find Your Feet's controls**: `Catalog ▸ Drills` (the `basics` lesson's `controls`), the words for
  each in `Training.client` (`FEET`).
- **The intro's score**: `MusicConfig ▸ TRACKS.Intro` (and `MOOD_VOLUME`).

## 11. Maps, modes, doors

- **A themed map in one line (`Build ▸ MapForge`):** add a row to `F.MAPS`:
  `Name = {title = "…", layout = "arena", theme = "winterNight", seed = 210}` (a siege also takes
  `champion = {name = "…", weapon = "Greatsword"}`), add the name to `F.ORDER`, to
  `GameConfig.MAP_TITLES`, `GameConfig.MAP_FIGHTERS` (below) and to the modes' `maps`, then in Studio
  `require(game.ServerScriptService.Build.Maps).build("Name")`, shoot its picture (below), **save
  the place**. Layouts: `arena bailey village bridge ruins clearing siege`. Themes (time of day,
  season, palette, trees, weather): `summer autumn winter winterNight desert desertDusk swamp
  stormNight ember spring dawnMist ash nightForest`; a new theme is one table in `F.THEMES`
  (`weather`: snow rain ash leaves petals embers fireflies dust mist). Every forge map has team,
  free, Siege (siege layout) and Horde markers and a hill, so it fits every mode its size suits.
- **Map:** a Model in `ServerStorage ▸ Maps ▸ <Name>` with a `Spawns` folder (parts; attribute
  `Team = "A"/"B"` for team spawns), optional `Zones ▸ Hill`, and optional `Spots` (named marker
  parts the mode scripts look for; `K.spot` makes them). Add its name to a mode's `maps` in
  `GameConfig.MODES`, and its on-screen name to `GameConfig.MAP_TITLES`. Maps built from code
  live in `Build ▸ Maps` (newer ones in `Build ▸ Map<Name>`).
- **How many a map suits:** `GameConfig.MAP_FIGHTERS.Name = {fewest, most}` (players and bots
  together). A match picks among the maps that suit the players there and the bots its mode
  brings, then among maps that at least fit the players; bots never fill a map past its most, and
  a public server's room is the smaller of the mode's `maxPlayers` and its map's most. Rough guide:
  a walled court ~50 across `{2, 6}` (1v1 to 3v3), a 46-radius arena `{2, 12}`, a bailey or a
  bridge `{6, 24}`, an open field ~240 across `{8, 32}`, a siege `{8, 40}`. Unlisted: suits anything.
- **Terrain:** `K.terrain(ctx, corner, size, paint)` paints inside that box and stores it with the
  map. Whatever a brush paints *outside* the box is undone when the build finishes (so a build can
  never leave hills behind in the place), so make the box big enough to hold every hill whole.
  Ground is at y = 0; `mound(T, centre, top, plateau, foot, material)` in `Build ▸ Maps` makes a
  flat-topped hill whose top is exactly `top` studs up (stand buildings on it at that height).
  Roblox draws a terrain surface 2 studs above where a fill ends; the brush `K.terrain` hands
  you is lowered by those 2 studs, so fill to y = 0 and the ground stands at y = 0 (checked in
  game). **Paint surface materials as whole voxel rows that end at y = 0**, e.g. a sand yard is
  `T:FillBlock(CFrame.new(x, -2, z), Vector3.new(w, 4, l), Enum.Material.Sand)`: a thin layer laid
  *on top* lifts the ground, and a thin one *inside* a full row doesn't change its material. For
  a hill use `T:Mound(centre, top, plateau, foot, material)` (exact top height), not stacked
  thin fills (they round each part-filled voxel up to full).
- **Painting ground by area:** for a road through grass, a clearing, a track, write the
  materials straight onto the voxels (`Terrain:ReadVoxels` → set each solid voxel's material by
  where its column is → `Terrain:WriteVoxels`), as `Build ▸ MapWildwood` does: a fill only changes
  a voxel's material where it *adds* to it, so a road filled over a full row of grass stays grass.
- **Light and haze:** `K.lighting(ctx, {ClockTime = …, Brightness = …, Ambient = …})` sets
  Lighting while the map is up; `K.atmosphere(ctx, {Density, Offset, Color, Decay, Glare, Haze})`
  sets the Atmosphere (with an Atmosphere in Lighting Roblox ignores FogEnd, so close fog is
  made here). Every map starts from the place's own lighting, so nothing carries over.
- **Spawns inside props:** `K.finish` moves any spawn standing inside something solid (a
  wagon, a tent) out until a body fits, and says how many it moved.
- **Horde maps:** give the Horde ways in: `K.spot(ctx, "HordeGate1", CFrame.lookAt(outside,
  middle))` a dozen studs outside each opening, with the ground from there to the middle clear
  enough to walk (bots steer round trees, wagons and walls, but not through a maze).
- **Bots don't climb steps:** a 1-stud step stops them. Anything a bot must reach, such as a KOTH
  hill on a platform, needs a ramp (an invisible WedgePart over the steps does it) or a rise of
  half a stud at most. Terrain `FillCylinder` / `FillBlock` thinner than a voxel row (4 studs)
  can write nothing at all.
- **Water you can fall into:** give the map an attribute `DrownY` (a height a little above the
  water's surface, e.g. -13 over water at -16): anyone below it for 1.2 s drowns.
- **Its picture on the vote:** put a StringValue (or Decal / ImageLabel) named after the map in
  `ReplicatedStorage ▸ MapShots`, holding the image (`rbxassetid://…`): a screenshot of the map
  from its menu view, uploaded as a Decal. Without one the vote card is plain, in its mode's colour.
- **Seats:** a `Seat` faces its front (`LookVector`); the sitter's back is to the seat's back.
  The Jump key stands you up and steps you off the front.
- **Footstep sounds:** `ReplicatedStorage ▸ Footsteps`: `SOUNDS[material name] = sound id`;
  `LIKE` sends other materials to one of those (`Slate = "Rock"`); `PITCH` / `VOLUME` tune a
  material. Or drop Sounds named after materials into a `FootstepSounds` folder in SoundService.
- **Peaceful mode:** `pvp = false` on a mode means players can't hurt each other there (dummies
  and bots still can be hit).
- **Lessons:** `Catalog ▸ Drills ▸ lessons`. Each is `{id, title, text, goal, event, kind,
  setup}`. The `text` may name key binds as `{Swing}`, `{Stab}`, `{Kick}` and so on, and the
  events are listed at the top of the file. `spar` sets what a win in the ring pays at each
  level.
- **A siege map:** stages in order with `K.objective(ctx, n, kind, {Label, AddTime, …})` and
  their pieces inside: a Ram stage gets `K.path(ctx, stage, points)`, `K.ram(ctx, stage, frame)`
  (facing down the road) and `K.gate(ctx, stage, frame, w, h, hits)`; a Capture stage gets
  `K.zone(ctx, stage, "Zone", pos, radius, height)`; a Slay stage gets a Part named `At` (where
  the champion rises; attribute `ArenaRadius`). Spawns get attributes `Side` ("Attack" /
  "Defend") and `Stage`. See `Build ▸ MapFrostgate`, and the Siege section of the README for
  every attribute.
- **Mode:** a ModuleScript in `ServerScriptService ▸ Game ▸ Modes ▸ <Id>` built on
  `Game.Mode`, plus an entry in `GameConfig.MODES`; list it in `GameConfig.DOORS.Warfront.modes`
  to put it in the Warfront vote (the battle cards). `waveSpawn = 10` gives it reinforcement
  waves; setting `self.bonusTime` adds seconds to the clock.
- **Door:** `GameConfig.DOORS` + `DOOR_ORDER` (the four cards on PLAY).
- **Class:** `GameConfig.CLASSES` — a name, a `weight`, optional weapon list.

## 11b. Staff roles

`ServerScriptService ▸ Admin ▸ Roles`: `roles = {Name = {rank, color, perms}}` (perms `"*"` or a
list from the file's header), `order` (how the panel lists them), `owners` (more owner user ids;
the creator is one already), `TEMPBAN_HOURS` (the longest ban a `tempban` role may give). People
get roles in the panel's STAFF tab.

## 12. The first release

[RELEASE_CONTENT.md](RELEASE_CONTENT.md) lists every model the shipped catalog expects, with
its Studio location, price and unlock.

## 13. Checking your work

Run the place once with the Output open. `Catalog` warns about every piece without models,
every skin naming an unknown weapon or crate, every weapon with a bad unlock. The menu
lists pieces "with no model" too, so you can see the catalog before the models exist.
