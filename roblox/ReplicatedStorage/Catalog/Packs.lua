-- PACKS — a named release of pieces (and usually a skin). Pieces name their
-- pack in Pieces (or an armor set's Config.Pack); skins name it with `pack`.
-- Fields:
--   name      shown in the shop            weight   Light | Medium | Heavy
--   free      true = the starter pack       featured true = this week's shop headline
--   color     Color3 for the shop card      bundle   discount when buying all of it (0.15 = 15% off)
-- Starter_Light / Starter_Medium / Starter_Heavy are the packs auto-imported
-- sets land in; keep them (rename freely). `Earned` holds the pieces that are
-- won by kills / wins / levels (never sold; the shop lists them under EARNED).
--
-- FIRST RELEASE — one armor set per pack (ServerStorage ▸ Armor ▸ <Pack>):
--   tier       price per piece         who
--   Common     250 Marks               Road Levy · Sellswords · Tourney Knight
--   Rare       450 Marks or 25 Crowns  Marsh Wardens · River Guard · The Iron Crow
--   Epic       45 Crowns               Harriers of the Coast · The Gilded Court · The Blackguard
--   Legendary  90 Crowns               Night Hunters · Wolf Company · Knights of the Sun
return {
	Starter_Light  = {name = "Peasant",         weight = "Light",  free = true, color = Color3.fromRGB(90, 75, 60)},
	Starter_Medium = {name = "Mail & Gambeson", weight = "Medium", free = true, color = Color3.fromRGB(70, 65, 58)},
	Starter_Heavy  = {name = "Plate & Mail",    weight = "Heavy",  free = true, color = Color3.fromRGB(80, 80, 85)},
	Earned         = {name = "Earned in battle", free = true, earned = true, color = Color3.fromRGB(60, 50, 40)},
	-- crate-only sets (never sold: their pieces come out of the Forge Crate, one at a time)
	Forge          = {name = "The Forge", crate = true, color = Color3.fromRGB(150, 70, 30)},
	WarChest       = {name = "The War Chest", crate = true, color = Color3.fromRGB(150, 40, 34)},

	-- LIGHT (Vanguard)
	RoadLevy      = {name = "Road Levy",            weight = "Light",  bundle = 0.15, color = Color3.fromRGB(104, 92, 70)},
	MarshWardens  = {name = "Marsh Wardens",        weight = "Light",  bundle = 0.15, color = Color3.fromRGB(42, 106, 77)},
	CoastHarriers = {name = "Harriers of the Coast", weight = "Light", bundle = 0.15, color = Color3.fromRGB(46, 96, 128)},
	NightHunters  = {name = "Night Hunters",        weight = "Light",  bundle = 0.20, color = Color3.fromRGB(38, 34, 56)},

	-- MEDIUM (Footman)
	Sellswords    = {name = "Sellswords",           weight = "Medium", bundle = 0.15, color = Color3.fromRGB(110, 84, 58)},
	RiverGuard    = {name = "River Guard",          weight = "Medium", bundle = 0.15, color = Color3.fromRGB(58, 92, 110)},
	GildedCourt   = {name = "The Gilded Court",     weight = "Medium", bundle = 0.15, color = Color3.fromRGB(138, 122, 42)},
	WolfCompany   = {name = "Wolf Company",         weight = "Medium", bundle = 0.20, color = Color3.fromRGB(84, 84, 92)},

	-- HEAVY (Knight)
	TourneyKnight = {name = "Tourney Knight",       weight = "Heavy",  bundle = 0.15, color = Color3.fromRGB(128, 58, 58)},
	IronCrow      = {name = "The Iron Crow",        weight = "Heavy",  featured = true, bundle = 0.15, color = Color3.fromRGB(106, 77, 42)},
	Blackguard    = {name = "The Blackguard",       weight = "Heavy",  bundle = 0.15, color = Color3.fromRGB(28, 28, 30)},
	SunKnights    = {name = "Knights of the Sun",   weight = "Heavy",  bundle = 0.20, color = Color3.fromRGB(196, 150, 70)},
}
