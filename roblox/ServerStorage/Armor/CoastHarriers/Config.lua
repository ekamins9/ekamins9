-- ServerStorage/Armor/CoastHarriers/Config  (ModuleScript inside the armor set)
-- FIRST RELEASE set: build the clothing Models (HeadClothing, TorsoClothing,
-- LeftArmClothing, RightArmClothing, LeftLegClothing, RightLegClothing, each
-- around a part named Middle) inside this Model in Studio. Until they exist
-- the set lists nothing; a set may skip slots. Stats come from Type only.
return {
	Name        = "Harriers of the Coast",
	Description = "A sea-cap, a striped shirt and a salt-stained vest: raiders who come in off the sea at dawn.",
	Type        = "Light",       -- Light | Medium | Heavy
	Pack        = "CoastHarriers",
	Rarity      = "Epic",
	PriceCrowns = 45,
	Covers      = {"Hair"},
	HelmName = "Harrier's Sea-Cap", TopName = "Harrier's Vest", LegsName = "Harrier's Breeches",
}
