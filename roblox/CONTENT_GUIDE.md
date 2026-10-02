# Content guide — adding stuff without touching code

Everything the game sells, equips, rolls or pays lives in **config ModuleScripts** under
`ReplicatedStorage` → `Catalog` and in **model folders** under `ReplicatedStorage` → `Cosmetics`.
You add content by editing those modules and dropping models in; no script changes.

```
ReplicatedStorage
├─ Catalog               ModuleScript  (the aggregator — never edit)
│  ├─ Weights            Light / Medium / Heavy stats (the ONLY place armor stats live)
│  ├─ Packs              named releases of pieces (starter packs are free)
│  ├─ Pieces             helmets / tops / bottoms — usually empty: sets auto-import
│  ├─ Weapons            which Tools exist and how each unlocks
│  ├─ Skins              weapon skins (crate / earned / shop)
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

Add a line to `Catalog ▸ Skins` (every weapon already has a free "Default"):

```lua
{weapon = "Falchion", name = "Bluesteel", rarity = "Rare", crate = "Bladesmith",
 blade = Color3.fromRGB(138, 168, 216), grip = Color3.fromRGB(42, 42, 74)},
```

- `crate = "Bladesmith"` → rolled from that crate · `crate = "earned", kills = 100` → earned by
  kills with that weapon · no `crate` + `marks` / `crowns` → sold in the shop.
- **Tints:** parts in the Tool with attribute `SkinPart` = `"Blade"` or `"Grip"` are recolored
  with `blade` / `grip`. Put that attribute on your weapons' parts once.
- **Models:** for a real re-model, put a Model in `Cosmetics ▸ Skins ▸ <Weapon> ▸ <SkinName>`
  with its own `Handle`; its parts replace the Tool's visible ones (welded by their offset
  from the model's Handle). Hitbox and guard parts stay as they are.

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

## 7. Hair, beards, faces, skin, hair colors, titles

All in `Catalog ▸ Body`. Hair and beards are `{id, name, crowns}` (`crowns` = premium,
bought once). Models go in `Cosmetics ▸ Body ▸ Hair ▸ <id>` and `Cosmetics ▸ Body ▸ Beard ▸ <id>`:
either a Model with a part named `Middle` the size of the Head (like a `HeadClothing`), or
an Accessory-style Model with a `Handle` and a `HairAttachment` / `FaceFrontAttachment`.
Hair parts are recolored with the hair color unless a part has attribute `KeepColor = true`.
An id with no model still lists (nothing shows) so you can set up the catalog first.
Faces are `{id, name, texture}` with a decal id (`"rbxassetid://…"`) or `""` to keep the
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

## 11. Maps, modes, doors

- **Map:** a Model in `ServerStorage ▸ Maps ▸ <Name>` with a `Spawns` folder (parts; attribute
  `Team = "A"/"B"` for team spawns), optional `Zones ▸ Hill`; add its name to a mode's `maps`
  in `GameConfig.MODES`.
- **Mode:** a ModuleScript in `ServerScriptService ▸ Game ▸ Modes ▸ <Id>` built on
  `Game.Mode`, plus an entry in `GameConfig.MODES`; list it in `GameConfig.DOORS.Warfront.modes`
  to put it in the Warfront vote.
- **Door:** `GameConfig.DOORS` + `DOOR_ORDER` (the four cards on PLAY).
- **Class:** `GameConfig.CLASSES` — a name, a `weight`, optional weapon list.

## 12. Checking your work

Run the place once with the Output open. `Catalog` warns about every piece without models,
every skin naming an unknown weapon or crate, every weapon with a bad unlock. The menu
lists pieces "with no model" too, so you can see the catalog before the models exist.
