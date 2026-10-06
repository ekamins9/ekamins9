-- ServerStorage/Armor/Sellswords/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "Sellswords",
	Description = "Mismatched mail and a dented kettle hat. Paid by the week, loyal by the hour.",
	Type        = "Medium",       -- Light | Medium | Heavy
	Pack        = "Sellswords",
	Rarity      = "Common",
	PriceMarks  = 250,
	Covers      = {"Hair"},
	HelmName = "Sellsword's Kettle", TopName = "Sellsword's Brigandine", LegsName = "Sellsword's Chausses",
}
