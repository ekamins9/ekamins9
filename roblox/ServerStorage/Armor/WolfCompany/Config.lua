-- ServerStorage/Armor/WolfCompany/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "Wolf Company",
	Description = "A snarling helm and a pelt over grey mail: the free company no lord admits to hiring.",
	Type        = "Medium",       -- Light | Medium | Heavy
	Pack        = "WolfCompany",
	Rarity      = "Legendary",
	PriceCrowns = 90,
	Covers      = {"Hair", "Face"},
	HelmName = "Wolf Helm", TopName = "Wolf Pelt Hauberk", LegsName = "Wolf Company Greaves",
}
