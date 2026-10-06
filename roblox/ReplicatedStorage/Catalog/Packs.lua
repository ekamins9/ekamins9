-- PACKS — a named release of pieces (and usually a skin). Pieces name their
-- pack in Pieces (or an armor set's Config.Pack). Fields:
--   name      shown in the shop            weight   Light | Medium | Heavy
--   free      true = the starter pack       featured true = this week's shop headline
--   color     Color3 for the shop card      bundle   discount when buying all pieces (0.15 = 15% off)
-- Starter_Light / Starter_Medium / Starter_Heavy are the packs auto-imported
-- sets land in by default (Woodsman, Gambeson, Knight, Peasant).
return {
	Starter_Light  = {name = "Peasant & Woodsman", weight = "Light",  free = true, color = Color3.fromRGB(90, 75, 60)},
	Starter_Medium = {name = "Mail & Gambeson",    weight = "Medium", free = true, color = Color3.fromRGB(70, 65, 58)},
	Starter_Heavy  = {name = "Plate & Mail",       weight = "Heavy",  free = true, color = Color3.fromRGB(80, 80, 85)},

	MarshWardens = {name = "Marsh Wardens",    weight = "Light",  bundle = 0.15, color = Color3.fromRGB(42, 106, 77)},
	Outlaws      = {name = "The Outlaws",      weight = "Light",  bundle = 0.15, color = Color3.fromRGB(120, 40, 40)},
	GildedCourt  = {name = "The Gilded Court", weight = "Medium", bundle = 0.15, color = Color3.fromRGB(138, 122, 42)},
	Garrison     = {name = "The Garrison",     weight = "Medium", bundle = 0.15, color = Color3.fromRGB(70, 80, 100)},
	IronCrow     = {name = "The Iron Crow",    weight = "Heavy",  featured = true, bundle = 0.15, color = Color3.fromRGB(50, 50, 58)},
	HolyOrder    = {name = "The Holy Order",   weight = "Heavy",  bundle = 0.15, color = Color3.fromRGB(170, 60, 60)},
	RoyalGuard   = {name = "The Royal Guard",  weight = "Heavy",  bundle = 0.2,  color = Color3.fromRGB(60, 90, 200)},
}
