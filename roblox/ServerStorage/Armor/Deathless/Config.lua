-- ServerStorage/Armor/Deathless/Config  (ModuleScript inside the armor set)
-- A WAR CHEST set: never sold, its pieces drop one at a time out of the War
-- Chest, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Its clothing models are built from Build ▸ Armor ▸ Deathless until hand-made ones exist.
return {
	Name        = "Deathless",
	Description = "A knight who died and didn't stop. A skull for a helm, green fire where the eyes were, a rusted crown.",
	Type        = "Medium",
	Pack        = "WarChest",
	Rarity      = "Legendary",
	Crate       = "WarChest",
	Finish      = "Gravelight",
	Colors      = {Metal = Color3.fromRGB(44, 46, 52), Accent = Color3.fromRGB(110, 255, 140)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair", "Face", "Beard"},
	HelmName = "Deathless Skull", TopName = "Deathless Ribcage", LegsName = "Deathless Greaves",
}
