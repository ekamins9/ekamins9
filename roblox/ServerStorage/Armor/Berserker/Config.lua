-- ServerStorage/Armor/Berserker/Config  (ModuleScript inside the armor set)
-- A WAR CHEST set: never sold, its pieces drop one at a time out of the War
-- Chest, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Its clothing models are built from Build ▸ Armor ▸ Berserker until hand-made ones exist.
return {
	Name        = "Berserker",
	Description = "A whole bear for a hood, its paws hanging down your chest. You don't wear it so much as you become it.",
	Type        = "Light",
	Pack        = "WarChest",
	Rarity      = "Epic",
	Crate       = "WarChest",
	Finish      = "Bloodrage",
	Colors      = {Metal = Color3.fromRGB(130, 136, 146), Accent = Color3.fromRGB(222, 150, 44)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Bear Hood", TopName = "Berserker's Pelt", LegsName = "Berserker's Wraps",
}
