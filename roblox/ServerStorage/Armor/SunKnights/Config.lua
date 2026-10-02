-- ServerStorage/Armor/SunKnights/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "Knights of the Sun",
	Description = "Gilt plate with a sunburst on the breast: the old order of the high kings.",
	Type        = "Heavy",       -- Light | Medium | Heavy
	Pack        = "SunKnights",
	Rarity      = "Legendary",
	PriceCrowns = 90,
	Covers      = {"Hair", "Face"},
	HelmName = "Sunburst Helm", TopName = "Sunburst Plate", LegsName = "Sunburst Legs",
}
