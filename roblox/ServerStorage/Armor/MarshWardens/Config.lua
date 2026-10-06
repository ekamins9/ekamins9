-- ServerStorage/Armor/MarshWardens/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "Marsh Wardens",
	Description = "Green hoods and oiled leather, from the fen companies that hunt in the reeds.",
	Type        = "Light",       -- Light | Medium | Heavy
	Pack        = "MarshWardens",
	Rarity      = "Rare",
	PriceMarks  = 450,
	PriceCrowns = 25,
	Covers      = {"Hair"},
	HelmName = "Warden's Hood", TopName = "Warden's Jerkin", LegsName = "Warden's Waders",
}
