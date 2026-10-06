-- ServerStorage/Armor/RiverGuard/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "River Guard",
	Description = "Blue surcoats over mail, the toll-bridge guard of the river towns.",
	Type        = "Medium",       -- Light | Medium | Heavy
	Pack        = "RiverGuard",
	Rarity      = "Rare",
	PriceMarks  = 450,
	PriceCrowns = 25,
	Covers      = {"Hair"},
	HelmName = "Guard's Bascinet", TopName = "Guard's Surcoat", LegsName = "Guard's Greaves",
}
