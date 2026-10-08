-- ServerStorage/Armor/Dragonscale/Config  (ModuleScript inside the armor set)
-- A FORGE CRATE set: never sold, its pieces drop one at a time out of the Forge
-- Crate, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Its clothing models are built from Build ▸ Armor ▸ Dragonscale until hand-made ones exist.
return {
	Name        = "Dragonscale",
	Description = "Plate hammered from a dragon's scales: a skull of a helm with burning eyes, spined shoulders, talons. It still remembers the fire.",
	Type        = "Heavy",
	Pack        = "Forge",
	Rarity      = "Legendary",
	Crate       = "Forge",
	Finish      = "Emberforged",
	Colors      = {Metal = Color3.fromRGB(96, 28, 24), Accent = Color3.fromRGB(232, 184, 74)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair", "Face"},
	HelmName = "Dragon's Skull", TopName = "Dragonscale Plate", LegsName = "Dragonscale Greaves",
}
