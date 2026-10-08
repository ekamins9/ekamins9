-- ServerStorage/Armor/Seraph/Config  (ModuleScript inside the armor set)
-- A FORGE CRATE set: never sold, its pieces drop one at a time out of the Forge
-- Crate, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Its clothing models are built from Build ▸ Armor ▸ Seraph until hand-made ones exist.
return {
	Name        = "Seraph",
	Description = "White-gold plate under a halo, and on its back two great wings of light. Nobody has seen more than a handful.",
	Type        = "Medium",
	Pack        = "Forge",
	Rarity      = "Mythic",
	Crate       = "Forge",
	Finish      = "Sunblessed",
	Colors      = {Metal = Color3.fromRGB(250, 244, 226), Accent = Color3.fromRGB(232, 184, 74)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair", "Face"},
	HelmName = "Winged Helm", TopName = "Seraph Plate", LegsName = "Seraph Greaves",
}
