--[[ LOOT — what a dungeon, a battle royale or a raid can hand you (Game ▸ Loot rolls it, gives
     it, and runs its effects). Config only: a new affix, relic, potion or armor is a new line.

     Nothing here touches your collection: it's the run's own gear (The Depths, Crownfall),
     or your VAULT's (Deadvault: kept only if you get out alive).

       RARITIES   in order: weight (how often, before luck), affixes (on a weapon), power (a
                  weapon's damage bonus), color, skin (which skin rarities its looks come from)
       AFFIXES    a weapon's: id, name (shown as a prefix or a `suffix`), roll {min, max}, text
                  (%s = the rolled value, already formatted)
                  kinds: burn, chill, poison, lifesteal, damage, storm, execute, giant, holy,
                  speed, thirst, stagger
       LEGENDARY_NAMES   a Legendary weapon's own name
       RELICS     carried, never held (`class`: only that class finds it): mods (Powers.addMods: speed, taken, dealt, stamina,
                  dodgeCost, dodgeCooldown, draw, cast), health (+max), or an effect (burn,
                  chill, lifesteal, storm, thorns, regen, berserk, rise, luck, thirst)
       POTIONS    drunk where you stand: heal (of your whole), or mods for `time` s
       ARMOR      worn over your class's (Crownfall, Deadvault): taken ×, health +
       TOMES      one of your own class's powers: a tome teaches it for the run (Catalog ▸ Powers)
       TREASURES  Deadvault's valuables: no use but their worth (`value`, gold at the Treasurer):
                  what fills your bag, and what you choose to carry out
       CONTAINERS what Deadvault's crates, barrels, urns, racks, shelves, sarcophagi, remains and
                  chests hold: `count` {min, max} things, `luck` (rarer the higher), `empty`
                  (the chance there's nothing), `loot` (weights of each kind) ]]

local C = Color3.fromRGB

local L = {}

L.RARITIES = {
	{id = "Common",    weight = 52, affixes = 0, power = 0.00, color = C(190, 196, 206), skin = {"Common"}},
	{id = "Uncommon",  weight = 28, affixes = 1, power = 0.06, color = C(90, 210, 100),  skin = {"Common", "Rare"}},
	{id = "Rare",      weight = 13, affixes = 2, power = 0.12, color = C(70, 150, 255),  skin = {"Rare"}},
	{id = "Epic",      weight = 5,  affixes = 3, power = 0.18, color = C(180, 90, 255),  skin = {"Epic"}},
	{id = "Legendary", weight = 1.5, affixes = 3, power = 0.26, color = C(255, 170, 40), skin = {"Legendary", "Mythic"}},
}
L.RANK = {}
for i, r in ipairs(L.RARITIES) do L.RANK[r.id] = i; L[r.id] = r end

L.AFFIXES = {
	{id = "Blazing",     kind = "burn",      roll = {4, 9},       text = "Sets them burning (%s a second)"},
	{id = "Frostbitten", kind = "chill",     roll = {0.2, 0.4},   text = "Chills them (%s slower)", pct = true},
	{id = "Venomous",    kind = "poison",    roll = {3, 7},       text = "Poisons them (%s a second)"},
	{id = "Vampiric",    kind = "lifesteal", roll = {0.05, 0.14}, text = "%s of every hit heals you", pct = true},
	{id = "Brutal",      kind = "damage",    roll = {0.06, 0.18}, text = "+%s damage", pct = true},
	{id = "Thundering",  kind = "storm",     roll = {0.15, 0.3},  text = "%s chance a bolt strikes them (+18)", pct = true},
	{id = "Executioner", kind = "execute",   roll = {0.3, 0.6},   text = "+%s damage to anyone under a third of their health", pct = true, suffix = "of the Executioner"},
	{id = "Giants",      kind = "giant",     roll = {0.15, 0.35}, text = "+%s damage to elites and bosses", pct = true, suffix = "of Giants"},
	{id = "Dawn",        kind = "holy",      roll = {0.25, 0.5},  text = "+%s damage to the undead", pct = true, suffix = "of the Dawn"},
	{id = "Wolf",        kind = "speed",     roll = {0.05, 0.1},  text = "+%s speed while you hold it", pct = true, suffix = "of the Wolf"},
	{id = "Thirst",      kind = "thirst",    roll = {8, 18},      text = "A kill heals you %s", suffix = "of Thirst"},
	{id = "Ruin",        kind = "stagger",   roll = {0.08, 0.15}, text = "%s chance to stagger them", pct = true, suffix = "of Ruin"},
}
L.AFFIX = {}
for _, a in ipairs(L.AFFIXES) do L.AFFIX[a.id] = a end

L.LEGENDARY_NAMES = {"Emberfang", "Gravecleaver", "Stormwrought", "Kingsbane", "Oathbinder", "Wyrmtooth", "Starhollow",
	"Thornheart", "Mournsteel", "Brightvow", "Hollowsong", "Sunsplitter", "Nightwarden", "Ironwake", "Duskreaver"}

L.RELICS = {
	{id = "IronBand",     name = "Iron Band",          glyph = "💍", rarity = "Common",    mods = {taken = 0.9},                  text = "You take 10% less damage"},
	{id = "HareFoot",     name = "Hare's Foot",        glyph = "🐇", rarity = "Common",    mods = {speed = 1.1},                  text = "10% faster on your feet"},
	{id = "WarHorn",      name = "War Horn",           glyph = "📯", rarity = "Common",    mods = {dealt = 1.08},                 text = "8% more damage"},
	{id = "OxHeart",      name = "Ox Heart",           glyph = "❤️", rarity = "Uncommon",  health = 25,                          text = "+25 health"},
	{id = "WindBoots",    name = "Boots of the Wind",  glyph = "👢", rarity = "Uncommon",  mods = {dodgeCooldown = 0.7, dodgeCost = 0.75}, text = "Dodge sooner, and for less wind"},
	{id = "BellowsLung",  name = "Bellows Lung",       glyph = "💨", rarity = "Uncommon",  mods = {stamina = 1.3},                text = "Your stamina comes back 30% faster"},
	{id = "LuckyCoin",    name = "Lucky Coin",         glyph = "🍀", rarity = "Uncommon",  effect = "luck",                       text = "Chests are kinder to you"},
	{id = "ManaPearl",    class = "Mage", name = "Mana Pearl",         glyph = "🔮", rarity = "Uncommon",  mods = {cast = 0.85},                  text = "Spells come 15% quicker"},
	{id = "EagleFeather", class = "Archer", name = "Eagle Feather",      glyph = "🦅", rarity = "Uncommon",  mods = {draw = 0.8},                   text = "Draw your bow 20% quicker"},
	{id = "EmberCharm",   name = "Ember Charm",        glyph = "🔥", rarity = "Rare",      effect = "burn",                       text = "Your blows set them burning"},
	{id = "FrostShard",   name = "Frost Shard",        glyph = "❄️", rarity = "Rare",      effect = "chill",                      text = "Your blows chill them"},
	{id = "CountessFang", name = "Fang of the Countess", glyph = "🦇", rarity = "Rare",    effect = "lifesteal",                  text = "8% of every hit heals you"},
	{id = "TrollHeart",   name = "Troll Heart",        glyph = "💚", rarity = "Rare",      effect = "regen",                      text = "Out of a fight, you mend quickly"},
	{id = "GiantsBelt",   name = "Giant's Belt",       glyph = "🥋", rarity = "Rare",      mods = {taken = 0.85, speed = 0.96},   health = 15, text = "15% less damage and +15 health, a little slower"},
	{id = "SaintsTear",   name = "Saint's Tear",       glyph = "💧", rarity = "Rare",      effect = "thirst",                     text = "Every kill heals you 15"},
	{id = "BerserkTotem", name = "Berserker's Totem",  glyph = "🗿", rarity = "Epic",      effect = "berserk",                    text = "Under half health: 25% more damage, 10% faster"},
	{id = "ThornMantle",  name = "Thorned Mantle",     glyph = "🌵", rarity = "Epic",      effect = "thorns",                     text = "Whoever hits you takes a fifth of it back"},
	{id = "StormRing",    name = "Ring of Storms",     glyph = "⚡", rarity = "Epic",      effect = "storm",                      text = "A fifth of your blows call a bolt down (+18)"},
	{id = "PhoenixPlume", name = "Phoenix Plume",      glyph = "☀️", rarity = "Legendary", effect = "rise",                       text = "Once, you rise again where you fell"},
	{id = "CrownShard",   name = "Shard of the Crown", glyph = "👑", rarity = "Legendary", mods = {dealt = 1.15, taken = 0.9, speed = 1.06}, health = 20, text = "15% more damage, 10% less taken, faster, +20 health"},
}
L.RELIC = {}
for _, r in ipairs(L.RELICS) do L.RELIC[r.id] = r end

L.POTIONS = {
	{id = "Healing",  name = "Healing Draught",  glyph = "🧪", rarity = "Common",   heal = 0.5,                                     text = "Heals half your health"},
	{id = "Greater",  name = "Greater Healing",  glyph = "🧪", rarity = "Rare",     heal = 1.0,                                     text = "Heals you whole"},
	{id = "Fury",     name = "Elixir of Fury",   glyph = "💢", rarity = "Uncommon", mods = {dealt = 1.3}, time = 30,                 text = "30% more damage for 30 seconds"},
	{id = "Stone",    name = "Elixir of Stone",  glyph = "⛰", rarity = "Uncommon", mods = {taken = 0.7}, time = 30,                 text = "30% less damage taken for 30 seconds"},
	{id = "Swift",    name = "Swiftness Tonic",  glyph = "🍃", rarity = "Uncommon", mods = {speed = 1.3, stamina = 1.5}, time = 30,  text = "Faster, quicker breath, for 30 seconds"},
}
L.POTION = {}
for _, p in ipairs(L.POTIONS) do L.POTION[p.id] = p end

-- (`set`: the armour set it looks like when worn in a raid: ServerStorage ▸ Armor ▸ <set>)
L.ARMOR = {
	{id = "Padded",     name = "Padded Jack",       rarity = "Common",    taken = 0.95, health = 0,  set = "RoadLevy"},
	{id = "Mail",       name = "Mail Hauberk",      rarity = "Uncommon",  taken = 0.9,  health = 5,  set = "Sellswords"},
	{id = "Brigandine", name = "Brigandine",        rarity = "Rare",      taken = 0.85, health = 10, set = "IronCrow"},
	{id = "Plate",      name = "Plate Harness",     rarity = "Epic",      taken = 0.8,  health = 15, set = "Blackguard"},
	{id = "Kingsguard", name = "Kingsguard Plate",  rarity = "Legendary", taken = 0.74, health = 25, set = "Lionheart"},
}
L.ARMOR_BY = {}
for _, a in ipairs(L.ARMOR) do L.ARMOR_BY[a.id] = a end

-- a power's tome: its rarity by the level its class learns it at
L.TOME_RARITY = function(level)
	if level >= 25 then return "Legendary" elseif level >= 15 then return "Epic" elseif level >= 8 then return "Rare" elseif level >= 3 then return "Uncommon" end
	return "Common"
end

-- WHAT A CHEST HOLDS, by where it is: weights of each kind
L.CHESTS = {
	depths   = {weapon = 40, relic = 34, tome = 14, potion = 0, gold = 12},
	elite    = {weapon = 45, relic = 45, tome = 10},
	boss     = {weapon = 50, relic = 50},
	crownfall = {weapon = 34, armor = 22, potion = 28, tome = 8, relic = 8},
	vault    = {weapon = 34, armor = 18, potion = 18, relic = 10, gold = 20},
}

-- what an item is worth to Deadvault's merchant (vault gold), by rarity
L.VALUE = {Common = 12, Uncommon = 30, Rare = 75, Epic = 180, Legendary = 450}

-- DEADVAULT'S VALUABLES (worth `value` gold to the Treasurer, half to anyone else)
L.TREASURES = {
	{id = "BronzeBell",  name = "Bronze Bell",        glyph = "🔔", rarity = "Common",    value = 14},
	{id = "SilverCup",   name = "Silver Cup",         glyph = "🏆", rarity = "Common",    value = 18},
	{id = "Candelabra",  name = "Brass Candelabra",   glyph = "🕯️", rarity = "Common",    value = 16},
	{id = "CoinPurse",   name = "Purse of Old Coins", glyph = "💰", rarity = "Common",    value = 22},
	{id = "SilverRing",  name = "Silver Ring",        glyph = "💍", rarity = "Uncommon",  value = 40},
	{id = "OldMap",      name = "Faded Map",          glyph = "📜", rarity = "Uncommon",  value = 38},
	{id = "JadeFigure",  name = "Jade Figurine",      glyph = "🗿", rarity = "Uncommon",  value = 46},
	{id = "GoldGoblet",  name = "Golden Goblet",      glyph = "🏆", rarity = "Rare",      value = 95},
	{id = "Sapphire",    name = "Sapphire",           glyph = "💎", rarity = "Rare",      value = 110},
	{id = "GildedUrn",   name = "Gilded Urn",         glyph = "⚱️", rarity = "Rare",      value = 90},
	{id = "RubyCirclet", name = "Ruby Circlet",       glyph = "👑", rarity = "Epic",      value = 240},
	{id = "GoldenIdol",  name = "Golden Idol",        glyph = "🗿", rarity = "Epic",      value = 260},
	{id = "DragonPearl", name = "Dragon's Pearl",     glyph = "🔮", rarity = "Legendary", value = 600},
	{id = "KingsSigil",  name = "The King's Sigil",   glyph = "🔱", rarity = "Legendary", value = 650},
}
L.TREASURE = {}
for _, t in ipairs(L.TREASURES) do L.TREASURE[t.id] = t end

-- WHAT DEADVAULT'S CONTAINERS HOLD (Game ▸ Loot.container)
L.CONTAINERS = {
	crate   = {name = "Crate",        count = {1, 2}, luck = 0,   empty = 0.25, loot = {gold = 30, treasure = 35, potion = 25, weapon = 10}},
	barrel  = {name = "Barrel",       count = {1, 1}, luck = 0,   empty = 0.3,  loot = {potion = 45, gold = 35, treasure = 20}},
	sack    = {name = "Sack",         count = {1, 2}, luck = 0,   empty = 0.2,  loot = {gold = 40, potion = 30, treasure = 30}},
	urn     = {name = "Urn",          count = {1, 1}, luck = 0.3, empty = 0.2,  loot = {gold = 50, treasure = 50}},
	rack    = {name = "Weapon Rack",  count = {1, 2}, luck = 0.4, empty = 0.1,  loot = {weapon = 100}},
	stand   = {name = "Armour Stand", count = {1, 1}, luck = 0.4, empty = 0.1,  loot = {armor = 100}},
	shelf   = {name = "Bookshelf",    count = {1, 2}, luck = 0.5, empty = 0.3,  loot = {tome = 40, treasure = 40, gold = 20}},
	coffin  = {name = "Sarcophagus",  count = {1, 3}, luck = 0.8, empty = 0.1,  loot = {treasure = 40, relic = 20, weapon = 20, armor = 10, gold = 10}},
	remains = {name = "Remains",      count = {1, 2}, luck = 0.2, empty = 0.15, loot = {gold = 35, potion = 25, weapon = 15, armor = 10, treasure = 15}},
	chest   = {name = "Chest",        count = {2, 3}, luck = 0.6, empty = 0,    loot = {weapon = 25, armor = 15, relic = 15, potion = 15, treasure = 20, gold = 10}},
	ornate  = {name = "Ornate Chest", count = {3, 4}, luck = 1.6, empty = 0,    loot = {weapon = 25, armor = 15, relic = 25, treasure = 25, tome = 10}},
	hoard   = {name = "The Hoard",    count = {5, 6}, luck = 2.6, empty = 0,    loot = {weapon = 25, armor = 15, relic = 30, treasure = 30}},
}

return L
