-- ServerStorage/Armor/IronCrow/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "The Iron Crow",
	Description = "Black iron, worn by the Crow company. The beak-visored sallet is known on every field.",
	Type        = "Heavy",       -- Light | Medium | Heavy
	Pack        = "IronCrow",
	Rarity      = "Rare",
	PriceMarks  = 450,
	PriceCrowns = 25,
	Covers      = {"Hair", "Face"},
	HelmName = "Crow Sallet", TopName = "Crow Hauberk", LegsName = "Crow Chausses",
}
