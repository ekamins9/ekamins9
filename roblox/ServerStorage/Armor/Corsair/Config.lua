-- ServerStorage/Armor/Corsair/Config  (ModuleScript inside the armor set)
-- A WAR CHEST set: never sold, its pieces drop one at a time out of the War
-- Chest, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Its clothing models are built from Build ▸ Armor ▸ Corsair until hand-made ones exist.
return {
	Name        = "Corsair",
	Description = "A black tricorn with a white plume, a captain's coat with gold to spare, and boots made for a rolling deck.",
	Type        = "Medium",
	Pack        = "WarChest",
	Rarity      = "Epic",
	Crate       = "WarChest",
	Finish      = "Brineshell",
	Colors      = {Secondary = Color3.fromRGB(150, 36, 36), Accent = Color3.fromRGB(232, 184, 74)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Captain's Tricorn", TopName = "Captain's Coat", LegsName = "Captain's Boots",
}
