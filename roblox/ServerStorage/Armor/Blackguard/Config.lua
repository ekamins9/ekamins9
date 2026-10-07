-- ServerStorage/Armor/Blackguard/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "The Blackguard",
	Description = "Jet plate with red cords. The usurper's own guard, hated and never beaten.",
	Type        = "Heavy",       -- Light | Medium | Heavy
	Pack        = "Blackguard",
	Rarity      = "Epic",
	PriceCrowns = 45,
	Covers      = {"Hair", "Face"},
	HelmName = "Blackguard Horned Helm", TopName = "Blackguard Plate", LegsName = "Blackguard Legs",
}
