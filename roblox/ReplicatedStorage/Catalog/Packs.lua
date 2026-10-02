-- PACKS — a named release of pieces (and usually a skin). Pieces name their
-- pack in Pieces (or an armor set's Config.Pack). Fields:
--   name      shown in the shop            weight   Light | Medium | Heavy
--   free      true = the starter pack       featured true = this week's shop headline
--   color     Color3 for the shop card      bundle   discount when buying all pieces (0.15 = 15% off)
-- Starter_Light / Starter_Medium / Starter_Heavy are the packs auto-imported
-- sets land in; keep them (rename freely).
return {
	Starter_Light  = {name = "Peasant",        weight = "Light",  free = true, color = Color3.fromRGB(90, 75, 60)},
	Starter_Medium = {name = "Mail & Gambeson", weight = "Medium", free = true, color = Color3.fromRGB(70, 65, 58)},
	Starter_Heavy  = {name = "Plate & Mail",   weight = "Heavy",  free = true, color = Color3.fromRGB(80, 80, 85)},

	-- examples of paid packs: delete or rename once you have models for them
	IronCrow     = {name = "The Iron Crow",   weight = "Heavy",  featured = true, bundle = 0.15, color = Color3.fromRGB(106, 77, 42)},
	GildedCourt  = {name = "The Gilded Court", weight = "Medium", bundle = 0.15, color = Color3.fromRGB(138, 122, 42)},
	MarshWardens = {name = "Marsh Wardens",   weight = "Light",  bundle = 0.15, color = Color3.fromRGB(42, 106, 77)},
}
