-- ServerStorage/Armor/PeasantSkin/Config  (ModuleScript inside the armor set)
-- The free Light starter set. Its models (straw hat, tunic, hose with shin
-- wraps) are meshes made from Build ▸ Armor.PeasantSkin. Stats come from the
-- weight (Catalog ▸ Weights ▸ Light), never from the set.
return {
	Name        = "Peasant",
	Description = "A straw hat, a rope-belted tunic and wrapped shins. Nothing between you and the blade but nerve, and nobody in plate will ever catch you.",
	Type        = "Light",
	Covers      = {"Hair"},
	HelmName = "Straw Hat", TopName = "Rope-belted Tunic", LegsName = "Wrapped Hose",
}
