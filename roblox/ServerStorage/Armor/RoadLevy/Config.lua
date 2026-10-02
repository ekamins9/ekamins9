-- ServerStorage/Armor/RoadLevy/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "Road Levy",
	Description = "Padded jack and a leather cap: what the roads give a man who must fight for them.",
	Type        = "Light",       -- Light | Medium | Heavy
	Pack        = "RoadLevy",
	Rarity      = "Common",
	PriceMarks  = 250,
	Covers      = {"Hair"},
	HelmName = "Levy Cap", TopName = "Levy Jack", LegsName = "Levy Hose",
}
