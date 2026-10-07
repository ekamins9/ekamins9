-- ServerStorage/Armor/TourneyKnight/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "Tourney Knight",
	Description = "Jousting plate: a frog-mouthed helm under a crest of plumes, a grand guard on the left. The armor a young knight is given, not the one he earns.",
	Type        = "Heavy",       -- Light | Medium | Heavy
	Pack        = "TourneyKnight",
	Rarity      = "Common",
	PriceMarks  = 250,
	Covers      = {"Hair", "Face"},
	HelmName = "Tourney Helm", TopName = "Tourney Plate", LegsName = "Tourney Legs",
}
