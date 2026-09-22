-- ServerStorage/Armor/PeasantSkin/Config  (ModuleScript inside the armor set)
-- No helmet, no shoes: this set has no HeadClothing or leg models, so hits
-- to the head and legs take full damage while the cloth on the torso and
-- arms still gets the (small) Protection.
return {
	Name        = "Peasant",
	Description = "Rough-spun clothes and bare feet. Nothing between you and the blade but nerve — but you'll outrun anyone in plate.",
	Type        = "Light",
	Health      = 0,
	SpeedMult   = 1.1,
	ClunkMult   = 0.8,
	Protection  = 0.05,
}
