--[[ ARSENAL SKINS — skins for the shields (the HERALDRY CRATE) and the throwables (the
     QUARTERMASTER'S CRATE). They're weapon skins like any other (Catalog ▸ Skins: same
     fields, appended to Catalog.SKINS), so they roll, trade, preview and equip the same way.
     A shield's skin can also paint arms on it:
       heraldry = {pattern, color}   pattern: cross saltire chevron pale fess bend quarterly
                                     bordure chief sun star lion tower (ReplicatedStorage ▸
                                     Heraldry: raised, outlined); color = the charge's colour
                                     (the field is `blade`, the rim and boss `grip`)
     paint its face (ReplicatedStorage ▸ ShieldPaint): emblem (a lion, a dragon, a tower…:
     emblemColor, emblemEdge, emblemGlow, emblemSize, emblemY, emblemCount), division (the field
     split: pale fess quarterly bend saltire chevron gyronny paly barry checky chief bordure
     pile cross, in divisionColor), wear (how battered), keepBoss
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
--  SHIELDS (the Heraldry Crate): each its own board (field), its own metal (trim), its own
--  painted face (an emblem, the field split, the scratches: ReplicatedStorage ▸ ShieldPaint) and
--  its own ornaments (adorn: ReplicatedStorage ▸ ShieldDress), so no two look alike; the rarer,
--  the more of a thing it is
--------------------------------------------------------------------
local ROSE, EMBER, LEAF = C(220, 60, 100), C(255, 150, 60), C(150, 255, 150)
-- (an emblem's paint: gold leaf and silver leaf catch the light a little brighter than paint)
local GILT, SILVERLEAF = Color3.new(1.1, 0.86, 0.38), Color3.new(1, 1, 1.04)
local BONE, INK, NAVY, BLOOD = C(232, 222, 200), C(22, 20, 22), C(22, 34, 78), C(120, 18, 26)

-- BUCKLER: a fist-sized round of steel for duellists
sh("Buckler", "Polished", "Common", C(226, 230, 236), C(120, 90, 60), nil, nil,
	{field = "Metal", accent = C(190, 196, 206), keepBoss = true, division = "bordure", divisionColor = C(150, 156, 168), adorn = {"studs"}})
sh("Buckler", "Gilt Boss", "Rare", C(200, 206, 214), GOLD, nil, nil,
	{field = "Metal", rim = "Foil", keepBoss = true, emblem = "sun", emblemColor = GILT, emblemSize = 1.2, adorn = {"gilded"}})
sh("Buckler", "Serpent's Coil", "Rare", C(30, 52, 40), C(150, 150, 160), nil, nil,
	{field = "Leather", rim = "Metal", division = "gyronny", divisionColor = C(18, 26, 22), emblem = "serpent", emblemColor = C(190, 240, 150),
		emblemSize = 1.25, adorn = {"studs"}})
sh("Buckler", "Duelist's Rose", "Epic", C(40, 40, 46), C(200, 40, 70), nil, nil,
	{fx = "petals", field = "Fabric", rim = "Foil", accent = ROSE, glow = C(255, 90, 130), emblem = "rose", emblemColor = ROSE, emblemEdge = GOLD,
		emblemSize = 1.1, adorn = {"gilded", "thorns"}})
sh("Buckler", "Moonlit Duelist", "Legendary", C(16, 22, 48), C(200, 210, 230), nil, nil,
	{fx = "frost", field = "Fabric", rim = "Foil", accent = C(210, 220, 240), glow = C(170, 200, 255), emblem = "moon", emblemColor = SILVERLEAF,
		emblemGlow = 1.2, emblemSize = 1.15, adorn = {"gilded", "glowedge"}})

-- TARGE: the highlanders' studded leather round
sh("Targe", "Clan Tartan", "Common", C(40, 90, 50), C(120, 84, 50), nil, nil,
	{field = "Fabric", accent = C(200, 160, 80), division = "checky", divisionColor = C(130, 34, 34), keepBoss = true, adorn = {"studs"}})
sh("Targe", "Highlander", "Rare", C(28, 52, 120), GOLD, "saltire", WHITE,
	{field = "Leather", rim = "Metal", accent = C(200, 200, 210), emblem = "stag", emblemColor = GILT, emblemSize = 0.85, adorn = {"studs"}})
sh("Targe", "Stag Lord", "Rare", C(34, 70, 44), C(150, 120, 70), nil, nil,
	{field = "Leather", rim = "Metal", division = "chief", divisionColor = C(200, 160, 70), emblem = "stag", emblemColor = BONE, emblemY = -0.08,
		accent = C(190, 160, 100), adorn = {"studs"}})
sh("Targe", "Bear Clan", "Epic", C(70, 44, 30), C(60, 50, 44), nil, nil,
	{fx = "embers", field = "Leather", rim = "Metal", division = "pale", divisionColor = C(26, 22, 20), emblem = "bear", emblemColor = BONE,
		emblemEdge = C(150, 30, 30), accent = C(200, 190, 170), horn = C(230, 220, 196), glow = EMBER, adorn = {"studs", "horns"}})
sh("Targe", "Thistle Crown", "Epic", PURPLE, SILVER, nil, nil,
	{fx = "holy", field = "Fabric", rim = "Foil", accent = C(210, 190, 255), glow = C(200, 150, 255), emblem = "fleur", emblemColor = C(214, 190, 255),
		emblemGlow = 1.1, adorn = {"vines", "crown"}})

-- ROUND SHIELD: the planked war-board of the northmen
sh("RoundShield", "Knotwork", "Common", C(150, 112, 74), C(110, 80, 50), nil, nil,
	{field = "WoodPlanks", keepBoss = true, emblem = "knot", emblemColor = C(226, 200, 150), emblemEdge = INK, emblemSize = 1.15, adorn = {"bands"}})
sh("RoundShield", "Raven Banner", "Common", BLACK, C(110, 80, 50), nil, nil,
	{field = "WoodPlanks", emblem = "raven", emblemColor = BONE, adorn = {"bands", "feathers"}, feather = C(26, 26, 32)})
sh("RoundShield", "Sea-Wolf", "Rare", C(30, 70, 120), C(150, 150, 160), nil, nil,
	{field = "WoodPlanks", rim = "Metal", division = "bordure", divisionColor = WHITE, emblem = "wolf", emblemColor = WHITE, emblemSize = 0.95,
		adorn = {"studs", "horns"}, horn = C(236, 226, 200)})
sh("RoundShield", "Wolf of the North", "Rare", C(220, 224, 228), C(80, 84, 92), nil, nil,
	{field = "WoodPlanks", rim = "Metal", division = "pale", divisionColor = C(26, 28, 34), emblem = "wolf", emblemColor = C(150, 160, 176),
		emblemEdge = INK, adorn = {"studs"}})
sh("RoundShield", "Jarl's Wheel", "Epic", RED, GOLD, nil, nil,
	{fx = "embers", field = "Wood", rim = "Foil", glow = EMBER, division = "gyronny", divisionColor = C(32, 20, 16), keepBoss = true,
		adorn = {"gilded", "studs", "flames"}})
sh("RoundShield", "Kraken's Maw", "Epic", C(16, 64, 74), C(70, 110, 110), nil, nil,
	{fx = "storm", field = "WoodPlanks", rim = "Metal", division = "barry", divisionColor = C(12, 44, 54), emblem = "kraken", emblemColor = C(150, 240, 220),
		emblemGlow = 1.15, accent = C(120, 170, 160), glow = C(120, 255, 230), adorn = {"studs", "glowedge"}})
sh("RoundShield", "Yggdrasil", "Legendary", C(30, 60, 40), GOLD, nil, nil,
	{fx = "holy", glow = LEAF, field = "Wood", rim = "Foil", emblem = "tree", emblemColor = C(150, 255, 160), emblemGlow = 1.25, emblemSize = 1.1,
		adorn = {"vines", "runes", "glowedge"}})

-- HEATER: the knight's shield, flat-topped and pointed
sh("Heater", "Saint's Cross", "Common", WHITE, C(150, 150, 158), nil, nil,
	{field = "Fabric", accent = SILVER, division = "cross", divisionColor = C(176, 28, 36), adorn = {"studs"}})
sh("Heater", "Azure Chevron", "Common", BLUE, SILVER, nil, nil,
	{field = "Fabric", accent = SILVER, division = "chevron", divisionColor = WHITE, adorn = {"studs"}})
sh("Heater", "Crusader", "Rare", WHITE, C(160, 160, 170), nil, nil,
	{field = "Fabric", rim = "Metal", accent = SILVER, ribbon = RED, glow = C(255, 220, 160), emblem = "cross", emblemColor = C(186, 26, 36),
		emblemEdge = GOLD, adorn = {"gilded", "tassels"}})
sh("Heater", "Fleur Royale", "Rare", NAVY, GOLD, nil, nil,
	{field = "Fabric", rim = "Foil", ribbon = C(36, 60, 150), glow = GOLD, division = "bordure", divisionColor = C(200, 160, 70),
		emblem = "fleur", emblemColor = GILT, adorn = {"tassels"}})
sh("Heater", "Lionheart", "Epic", RED, GOLD, nil, nil,
	{fx = "gold", field = "Fabric", rim = "Foil", glow = C(255, 70, 70), emblem = "lion", emblemColor = GILT, adorn = {"gilded", "crown", "studs"}})
sh("Heater", "Griffin Guard", "Epic", INK, GOLD, nil, nil,
	{fx = "gold", field = "Fabric", rim = "Foil", division = "quarterly", divisionColor = C(206, 160, 64), emblem = "griffin",
		emblemColor = C(190, 28, 38), emblemEdge = C(250, 220, 140), adorn = {"gilded", "studs"}})
sh("Heater", "Black Knight", "Epic", C(22, 22, 26), C(60, 60, 66), nil, nil,
	{fx = "shadow", field = "Slate", rim = "Metal", division = "bend", divisionColor = C(70, 10, 16), emblem = "skull", emblemColor = BONE,
		emblemEdge = INK, accent = C(70, 70, 78), adorn = {"thorns", "studs"}})
sh("Heater", "Sunguard", "Legendary", C(30, 56, 132), GOLD, nil, nil,
	{fx = "holy", glow = C(255, 230, 150), field = "Fabric", rim = "Foil", division = "bordure", divisionColor = C(214, 170, 70), emblem = "sun", emblemColor = GILT, emblemGlow = 1.15,
		adorn = {"rays", "gilded", "glowedge"}})
sh("Heater", "Phoenix Ascendant", "Legendary", C(110, 20, 16), GOLD, nil, nil,
	{fx = "embers", trail = true, glow = EMBER, field = "Fabric", rim = "Foil", division = "pile", divisionColor = C(230, 120, 30),
		emblem = "phoenix", emblemColor = C(255, 190, 80), emblemGlow = 1.2, emblemEdge = C(60, 10, 6), adorn = {"flames", "gilded", "glowedge"}})

-- SPIKED SHIELD: a round with a spike to punch with (its face stays clear round the spike)
sh("SpikedShield", "Boar Tusk", "Common", C(120, 86, 56), C(70, 60, 52), nil, nil,
	{field = "WoodPlanks", rim = "Metal", division = "pale", divisionColor = C(40, 30, 24), horn = BONE, adorn = {"horns", "studs"}})
sh("SpikedShield", "Blackthorn", "Rare", BLACK, C(150, 30, 30), nil, nil,
	{field = "Slate", rim = "Metal", accent = C(170, 40, 40), division = "gyronny", divisionColor = C(96, 16, 20), adorn = {"thorns", "bands"}})
sh("SpikedShield", "Sunspike", "Epic", C(200, 150, 60), C(120, 70, 30), nil, nil,
	{fx = "gold", field = "Foil", rim = "Metal", emblem = "sun", emblemColor = C(150, 30, 20), emblemEdge = C(255, 220, 140), emblemSize = 1.15,
		glow = C(255, 200, 110), adorn = {"rays"}})
sh("SpikedShield", "Wyvern", "Epic", GREEN, C(40, 40, 40), nil, nil,
	{fx = "toxic", field = "Slate", rim = "Metal", accent = C(60, 70, 50), glow = C(180, 255, 120), wing = C(46, 80, 46), wingMaterial = "Slate",
		horn = C(70, 76, 60), emblem = "serpent", emblemColor = C(180, 255, 120), emblemGlow = 1.15, emblemSize = 1.15,
		adorn = {"wings", "horns", "thorns", "glowedge"}})
sh("SpikedShield", "Dragonscale", "Legendary", C(30, 44, 34), C(30, 30, 30), nil, nil,
	{fx = "embers", trail = true, field = "Slate", rim = "Metal", division = "checky", divisionColor = C(16, 24, 18), glow = EMBER,
		horn = C(40, 40, 40), accent = C(60, 50, 40), adorn = {"flames", "horns", "thorns", "glowedge"}})

-- KITE: the long Norman board that covers you from cheek to shin
sh("Kite", "Norman", "Common", C(200, 170, 120), C(110, 80, 50), nil, nil,
	{field = "Wood", accent = C(160, 150, 140), emblem = "dragon", emblemColor = C(160, 34, 30), adorn = {"studs"}})
sh("Kite", "Silver Horse", "Rare", C(30, 80, 46), SILVER, nil, nil,
	{field = "Fabric", rim = "Metal", division = "bordure", divisionColor = C(200, 204, 212), emblem = "horse", emblemColor = SILVERLEAF,
		emblemEdge = INK, adorn = {"studs"}})
sh("Kite", "Two Lions", "Rare", RED, GOLD, nil, nil,
	{field = "Fabric", rim = "Foil", emblem = "lion", emblemColor = GILT, emblemCount = 2, emblemY = -0.2, adorn = {"gilded"}})
sh("Kite", "Crossed Blades", "Rare", C(120, 124, 132), C(60, 60, 66), nil, nil,
	{field = "Metal", rim = "Metal", division = "chief", divisionColor = C(150, 24, 32), emblem = "swords", emblemColor = C(236, 238, 244),
		emblemEdge = INK, emblemY = -0.25, adorn = {"bands"}})
sh("Kite", "Templar", "Epic", WHITE, BLACK, nil, nil,
	{fx = "holy", field = "Fabric", rim = "Metal", accent = GOLD, ribbon = RED, glow = C(255, 236, 190), division = "chief", divisionColor = INK,
		emblem = "cross", emblemColor = C(186, 26, 36), emblemEdge = INK, emblemY = -0.25, adorn = {"gilded", "tassels"}})
sh("Kite", "Dragon Knight", "Legendary", C(18, 16, 18), GOLD, nil, nil,
	{fx = "embers", trail = true, field = "Fabric", rim = "Foil", division = "bordure", divisionColor = C(200, 150, 60), glow = EMBER,
		emblem = "dragon", emblemColor = C(255, 96, 40), emblemGlow = 1.2, emblemEdge = C(255, 210, 120), wing = C(40, 30, 30),
		wingMaterial = "Slate", adorn = {"wings", "flames", "gilded"}})

-- SCUTUM: the legion's tall curved board
sh("Scutum", "Legionary", "Common", C(160, 30, 30), GOLD, nil, nil,
	{field = "Wood", rim = "Foil", division = "bordure", divisionColor = C(214, 168, 70), keepBoss = true, adorn = {"bands"}})
sh("Scutum", "Thunderbolt", "Rare", C(160, 30, 30), GOLD, nil, nil,
	{field = "Wood", rim = "Foil", glow = C(255, 220, 120), emblem = "thunderbolt", emblemColor = GILT, emblemSize = 1.15, adorn = {"gilded"}})
sh("Scutum", "Praetorian", "Epic", C(70, 14, 70), GOLD, nil, nil,
	{fx = "gold", field = "Fabric", rim = "Foil", division = "barry", divisionColor = C(50, 10, 50), emblem = "swords", emblemColor = GILT,
		emblemEdge = INK, emblemSize = 1.15, glow = C(255, 220, 120), adorn = {"gilded", "studs"}})
sh("Scutum", "Imperial Eagle", "Legendary", PURPLE, GOLD, nil, nil,
	{fx = "gold", glow = C(255, 220, 120), field = "Fabric", rim = "Foil", wing = GOLD, emblem = "eagle", emblemColor = GILT, emblemGlow = 1.1,
		emblemSize = 1.15, adorn = {"wings", "crown", "gilded", "glowedge"}})

-- PAVISE: the crossbowman's wall
sh("Pavise", "Town Watch", "Common", C(40, 90, 160), C(130, 100, 70), nil, nil,
	{field = "WoodPlanks", ribbon = C(40, 90, 160), glow = GOLD, division = "chief", divisionColor = C(214, 170, 70), emblem = "tower",
		emblemColor = C(236, 232, 222), emblemSize = 0.75, emblemY = -0.35, adorn = {"bands", "tassels"}})
sh("Pavise", "Castellan", "Rare", C(120, 120, 128), BLACK, nil, nil,
	{field = "Slate", rim = "Metal", accent = C(150, 150, 160), division = "barry", divisionColor = C(96, 96, 104), emblem = "tower",
		emblemColor = C(236, 232, 222), emblemEdge = INK, adorn = {"merlons", "studs"}})
sh("Pavise", "Rose Wall", "Rare", WHITE, C(130, 100, 70), nil, nil,
	{field = "WoodPlanks", division = "paly", divisionColor = C(170, 28, 44), emblem = "rose", emblemColor = C(196, 30, 50),
		emblemEdge = C(236, 196, 90), adorn = {"bands"}})
sh("Pavise", "Bulwark of Dawn", "Epic", C(250, 200, 120), C(150, 100, 60), nil, nil,
	{fx = "embers", field = "Sandstone", rim = "Foil", accent = GOLD, glow = EMBER, division = "pile", divisionColor = C(230, 130, 50),
		emblem = "sun", emblemColor = C(255, 128, 40), emblemGlow = 1.1, emblemEdge = C(90, 30, 10), adorn = {"rays", "flames", "gilded"}})
sh("Pavise", "Sentinel's Moon", "Legendary", C(14, 20, 44), SILVER, nil, nil,
	{fx = "frost", trail = true, field = "Fabric", rim = "Metal", division = "bordure", divisionColor = C(190, 200, 220), glow = C(160, 200, 255),
		emblem = "moon", emblemColor = SILVERLEAF, emblemGlow = 1.2, accent = C(200, 210, 230), adorn = {"merlons", "glowedge", "studs"}})

-- THE MYTHIC: one shield everyone stops to look at: a sunburst behind it, white-gold wings, a
-- crown, a burning golden lion on a field bordered in gold, a rim of light
sh("Heater", "Aegis of the First King", "Mythic", C(232, 226, 210), GOLD, nil, nil,
	{fx = "sovereign", glow = C(255, 220, 120), trail = true, field = "Marble", rim = "Foil", wing = GOLD, wingMaterial = "Foil",
		division = "bordure", divisionColor = C(214, 170, 70), emblem = "lion", emblemColor = GILT, emblemGlow = 1.15, emblemEdge = C(90, 50, 10),
		adorn = {"rays", "wings", "crown", "gilded", "studs", "glowedge"}})

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
