-- ServerStorage/Armor/NightHunters/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "Night Hunters",
	Description = "Black leather, black mail, a half-mask. Nobody sees them until the blade is in.",
	Type        = "Light",       -- Light | Medium | Heavy
	Pack        = "NightHunters",
	Rarity      = "Legendary",
	PriceCrowns = 90,
	Covers      = {"Hair", "Face"},
	HelmName = "Hunter's Mask", TopName = "Hunter's Black Jack", LegsName = "Hunter's Black Hose",
}
