-- ServerStorage/Armor/Lionheart/Config  (ModuleScript inside the armor set)
-- A WAR CHEST set: never sold, its pieces drop one at a time out of the War
-- Chest, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Its clothing models are built from Build ▸ Armor ▸ Lionheart until hand-made ones exist.
return {
	Name        = "Lionheart",
	Description = "A crowned great helm with a lion's mane for a crest, gilt lions on the shoulders. Roar optional.",
	Type        = "Heavy",
	Pack        = "WarChest",
	Rarity      = "Legendary",
	Crate       = "WarChest",
	Finish      = "Lionsmane",
	Colors      = {Metal = Color3.fromRGB(206, 212, 222), Secondary = Color3.fromRGB(120, 24, 30), Accent = Color3.fromRGB(232, 184, 74)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair", "Face", "Beard"},
	HelmName = "Lionheart Helm", TopName = "Lionheart Plate", LegsName = "Lionheart Greaves",
}
