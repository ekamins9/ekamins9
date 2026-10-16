--[[ ARSENAL SKINS — skins for the shields (the HERALDRY CRATE) and the throwables (the
     QUARTERMASTER'S CRATE). They're weapon skins like any other (Catalog ▸ Skins: same
     fields, appended to Catalog.SKINS), so they roll, trade, preview and equip the same way.
     A shield's skin can also paint arms on it:
       heraldry = {pattern, color}   pattern: cross saltire chevron pale fess bend quarterly
                                     bordure chief sun star lion tower (ReplicatedStorage ▸
                                     Heraldry: raised, outlined); color = the charge's colour
                                     (the field is `blade`, the rim and boss `grip`)
     and dress it (ReplicatedStorage ▸ ShieldDress): field / rim (materials), accent, glow,
     adorn = {studs gilded glowedge boss gem spike thorns wings crown rays horns feathers vines
     runes bands tassels merlons flames} ]]

local C = Color3.fromRGB
local GOLD, SILVER, BLACK, WHITE = C(232, 184, 74), C(214, 218, 226), C(28, 28, 32), C(240, 240, 236)
local RED, BLUE, GREEN, PURPLE = C(170, 30, 40), C(36, 70, 160), C(40, 110, 60), C(100, 40, 140)

local S = {}
local function sh(weapon, name, rarity, blade, grip, pattern, color, extra)
	local t = {weapon = weapon, name = name, rarity = rarity, crate = "Heraldry", blade = blade, grip = grip,
		heraldry = pattern and {pattern = pattern, color = color} or nil}
	for k, v in pairs(extra or {}) do t[k] = v end
	table.insert(S, t)
end
local function th(weapon, name, rarity, blade, grip, extra)
	local t = {weapon = weapon, name = name, rarity = rarity, crate = "Quartermaster", blade = blade, grip = grip}
	for k, v in pairs(extra or {}) do t[k] = v end
	table.insert(S, t)
end

--------------------------------------------------------------------
--  SHIELDS (the Heraldry Crate): each its own board (field), its own metal (trim) and its own
--  ornaments (adorn: ReplicatedStorage ▸ ShieldDress), so no two look alike; the rarer, the
--  more of a thing it is
--------------------------------------------------------------------
local ROSE, EMBER, LEAF = C(220, 60, 100), C(255, 150, 60), C(150, 255, 150)
sh("Buckler", "Polished", "Common", C(226, 230, 236), C(120, 90, 60), nil, nil,
	{field = "Metal", accent = C(190, 196, 206), adorn = {"studs"}})
sh("Buckler", "Gilt Boss", "Rare", C(200, 206, 214), GOLD, "sun", GOLD,
	{field = "Metal", rim = "Foil", adorn = {"gilded", "boss", "studs"}})
sh("Buckler", "Duelist's Rose", "Epic", C(40, 40, 46), C(200, 40, 70), "star", C(230, 50, 80),
	{fx = "petals", field = "Fabric", rim = "Foil", accent = ROSE, glow = C(255, 90, 130), adorn = {"gilded", "thorns", "gem"}})

sh("Targe", "Clan Tartan", "Common", C(40, 90, 50), C(120, 84, 50), "quarterly", C(160, 40, 40),
	{field = "Fabric", accent = C(200, 160, 80), adorn = {"studs"}})
sh("Targe", "Highlander", "Rare", C(90, 60, 40), GOLD, "saltire", WHITE,
	{field = "Leather", rim = "Metal", accent = C(200, 200, 210), adorn = {"studs", "boss", "spike"}})
sh("Targe", "Thistle Crown", "Epic", PURPLE, SILVER, "star", C(200, 150, 255),
	{fx = "holy", field = "Fabric", rim = "Foil", accent = C(210, 190, 255), glow = C(200, 150, 255), adorn = {"vines", "crown", "gem"}})

sh("RoundShield", "Raven Banner", "Common", BLACK, C(110, 80, 50), "pale", RED,
	{field = "WoodPlanks", adorn = {"bands", "feathers"}, feather = C(26, 26, 32)})
sh("RoundShield", "Sea-Wolf", "Rare", C(30, 70, 120), C(150, 150, 160), "sun", WHITE,
	{field = "WoodPlanks", rim = "Metal", adorn = {"studs", "horns"}, horn = C(236, 226, 200)})
sh("RoundShield", "Jarl's Wheel", "Epic", RED, GOLD, "cross", GOLD,
	{fx = "embers", field = "Wood", rim = "Foil", glow = EMBER, adorn = {"gilded", "studs", "flames"}})
sh("RoundShield", "Yggdrasil", "Legendary", C(30, 60, 40), GOLD, "lion", C(140, 255, 160),
	{fx = "holy", glow = LEAF, field = "Wood", rim = "Foil", adorn = {"vines", "runes", "glowedge", "gem"}})

sh("Heater", "Azure Chevron", "Common", BLUE, SILVER, "chevron", WHITE,
	{field = "Fabric", accent = SILVER, adorn = {"studs"}})
sh("Heater", "Crusader", "Rare", WHITE, C(160, 160, 170), "cross", RED,
	{field = "Fabric", rim = "Metal", accent = SILVER, ribbon = RED, glow = C(255, 220, 160), adorn = {"gilded", "tassels"}})
sh("Heater", "Lionheart", "Epic", RED, GOLD, "lion", GOLD,
	{fx = "gold", field = "Fabric", rim = "Foil", glow = C(255, 70, 70), adorn = {"gilded", "crown", "studs"}})
sh("Heater", "Sunguard", "Legendary", C(250, 240, 220), GOLD, "sun", GOLD,
	{fx = "holy", glow = C(255, 230, 150), field = "Marble", rim = "Foil", adorn = {"rays", "gilded", "gem", "glowedge"}})

sh("SpikedShield", "Blackthorn", "Rare", BLACK, C(150, 30, 30), "bordure", C(150, 30, 30),
	{field = "Slate", rim = "Metal", accent = C(170, 40, 40), adorn = {"thorns", "bands"}})
sh("SpikedShield", "Wyvern", "Epic", GREEN, C(40, 40, 40), "bend", C(180, 255, 120),
	{fx = "toxic", field = "Slate", rim = "Metal", accent = C(60, 70, 50), glow = C(180, 255, 120), wing = C(46, 80, 46), wingMaterial = "Slate",
		horn = C(70, 76, 60), adorn = {"wings", "horns", "thorns", "glowedge"}})

sh("Kite", "Norman", "Common", C(200, 170, 120), C(110, 80, 50), "fess", RED,
	{field = "Wood", accent = C(160, 150, 140), adorn = {"studs", "bands"}})
sh("Kite", "Two Lions", "Rare", RED, GOLD, "lion", GOLD,
	{field = "Fabric", rim = "Foil", adorn = {"gilded"}})
sh("Kite", "Templar", "Epic", WHITE, BLACK, "cross", RED,
	{fx = "holy", field = "Fabric", rim = "Metal", accent = GOLD, ribbon = RED, glow = C(255, 236, 190), adorn = {"gilded", "tassels", "gem"}})

sh("Scutum", "Legionary", "Common", C(160, 30, 30), GOLD, "fess", GOLD,
	{field = "Wood", rim = "Foil", adorn = {"bands"}})
sh("Scutum", "Thunderbolt", "Rare", C(160, 30, 30), GOLD, "star", GOLD,
	{field = "Wood", rim = "Foil", glow = C(255, 220, 120), adorn = {"bands", "glowedge"}})
sh("Scutum", "Imperial Eagle", "Legendary", PURPLE, GOLD, "sun", GOLD,
	{fx = "gold", glow = C(255, 220, 120), field = "Fabric", rim = "Foil", wing = GOLD, adorn = {"wings", "crown", "gilded", "gem", "glowedge"}})

sh("Pavise", "Town Watch", "Common", C(40, 90, 160), C(130, 100, 70), "chief", GOLD,
	{field = "WoodPlanks", ribbon = C(40, 90, 160), glow = GOLD, adorn = {"bands", "tassels"}})
sh("Pavise", "Castellan", "Rare", C(120, 120, 128), BLACK, "tower", WHITE,
	{field = "Slate", rim = "Metal", accent = C(150, 150, 160), adorn = {"merlons", "bands", "studs"}})
sh("Pavise", "Bulwark of Dawn", "Epic", C(250, 200, 120), C(150, 100, 60), "sun", C(255, 120, 60),
	{fx = "embers", field = "Sandstone", rim = "Foil", accent = GOLD, glow = EMBER, adorn = {"rays", "flames", "gilded"}})

-- THE MYTHIC: one shield everyone stops to look at: a sunburst behind it, white-gold wings,
-- a crown, a burning gem, a rim of light
sh("Heater", "Aegis of the First King", "Mythic", C(250, 245, 230), GOLD, "lion", GOLD,
	{fx = "sovereign", glow = C(255, 220, 120), trail = true, field = "Marble", rim = "Foil", wing = GOLD, wingMaterial = "Foil",
		adorn = {"rays", "wings", "crown", "gilded", "studs", "gem", "glowedge"}})

--------------------------------------------------------------------
--  THROWABLES (the Quartermaster's Crate)
--------------------------------------------------------------------
th("ThrowingKnives", "Blued Steel", "Common", C(110, 130, 170), C(40, 40, 50))
th("ThrowingKnives", "Viper Fang", "Rare", C(60, 140, 60), C(30, 30, 30), {fx = "toxic", trail = true})
th("ThrowingKnives", "Frostfang", "Epic", C(170, 220, 255), C(220, 240, 255), {fx = "frost", trail = true})
th("ThrowingKnives", "Starshards", "Legendary", C(240, 240, 255), GOLD, {fx = "holy", trail = true, glow = C(255, 240, 180)})

th("ThrowingAxe", "Bearded", "Common", C(150, 150, 140), C(100, 70, 40))
th("ThrowingAxe", "Ember Francisca", "Rare", C(220, 110, 50), C(60, 40, 30), {fx = "embers", trail = true})
th("ThrowingAxe", "Stormcleaver", "Epic", C(140, 170, 220), C(40, 50, 70), {fx = "storm", trail = true})

th("Plumbata", "Lead Grey", "Common", C(110, 110, 116), C(170, 150, 110))
th("Plumbata", "Hawk Feathers", "Rare", C(200, 200, 200), C(140, 90, 50), {trail = true})
th("Plumbata", "Thunderdarts", "Epic", C(255, 220, 80), C(60, 60, 90), {fx = "storm", trail = true})

th("Javelin", "Ash Shaft", "Common", C(200, 200, 196), C(210, 190, 150))
th("Javelin", "Sunspear", "Epic", GOLD, C(250, 240, 220), {fx = "holy", trail = true})
th("Javelin", "Wyrmtooth", "Legendary", C(240, 230, 210), C(120, 30, 30), {fx = "inferno", trail = true, glow = C(255, 120, 50)})

th("Firebomb", "Greek Fire", "Rare", C(120, 200, 80), C(160, 120, 70), {fx = "toxic"})
th("Firebomb", "Dragon's Breath", "Epic", C(200, 40, 30), GOLD, {fx = "embers", trail = true})

th("FrostFlask", "Winter's Kiss", "Rare", C(200, 230, 255), SILVER, {fx = "frost"})
th("FrostFlask", "Glacial Heart", "Epic", C(60, 140, 255), C(220, 240, 255), {fx = "frost", trail = true})

th("SmokeBomb", "Ash Grey", "Common", C(90, 90, 96), C(60, 50, 40))
th("SmokeBomb", "Night Pouch", "Rare", BLACK, PURPLE, {fx = "shadow"})

th("Caltrops", "Rusty", "Common", C(140, 90, 60), C(90, 70, 50))
th("Caltrops", "Thornbriar", "Rare", C(60, 120, 50), C(80, 60, 40), {fx = "toxic"})

th("Bolas", "Braided Hide", "Common", C(150, 110, 70), C(90, 60, 40))
th("Bolas", "Starweights", "Epic", C(200, 210, 255), GOLD, {fx = "holy", trail = true})

th("HolyWater", "Cathedral Glass", "Rare", C(220, 240, 255), GOLD, {fx = "holy"})
th("HolyWater", "Saint's Tears", "Legendary", C(255, 250, 230), GOLD, {fx = "holy", trail = true, glow = C(255, 245, 200)})

-- THE MYTHIC
th("ThrowingKnives", "Phoenix Feathers", "Mythic", C(255, 140, 40), GOLD, {fx = "phoenix", trail = true, glow = C(255, 200, 90)})

return S
