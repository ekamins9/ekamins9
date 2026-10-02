-- ServerStorage/Armor/GildedCourt/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "The Gilded Court",
	Description = "Gilt-studded brigandine for the king's own household. Fights as well as it looks.",
	Type        = "Medium",       -- Light | Medium | Heavy
	Pack        = "GildedCourt",
	Rarity      = "Epic",
	PriceCrowns = 45,
	Covers      = {"Hair"},
	HelmName = "Courtier's Sallet", TopName = "Courtier's Brigandine", LegsName = "Courtier's Hose",
}
