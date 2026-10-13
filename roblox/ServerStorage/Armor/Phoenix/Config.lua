-- ServerStorage/Armor/Phoenix/Config  (ModuleScript inside the armor set)
-- THE FLETCHER'S CRATE MYTHIC: never sold, its pieces drop one at a time, each a tradable
-- copy, and it burns with its own finish (Catalog ▸ ArmorFX: Phoenixfire).
-- Its clothing models are built from Build ▸ Armor ▸ Phoenix until hand-made ones exist.
return {
	Name        = "Phoenixborn",
	Description = "Out of the ashes: a golden mask under a crest of burning feathers, folded wings of fire down the back, a sun on the breast and a quiver of arrows that never stop burning.",
	Type        = "Light",
	Pack        = "Fletcher",
	Rarity      = "Mythic",
	Crate       = "Fletcher",
	Finish      = "Phoenixfire",
	Colors      = {Metal = Color3.fromRGB(232, 184, 74), Accent = Color3.fromRGB(255, 196, 80)},
	Covers      = {"Hair"},
	HelmName = "Phoenix Mask", TopName = "Phoenix Wings", LegsName = "Phoenix Greaves",
}
