-- ServerStorage/Armor/Obsidian/Config  (ModuleScript inside the armor set)
-- A WAR CHEST set: never sold, its pieces drop one at a time out of the War
-- Chest, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Its clothing models are built from Build ▸ Armor ▸ Obsidian until hand-made ones exist.
return {
	Name        = "Obsidian",
	Description = "Black volcanic glass split by molten seams, a crown of shards and a visor of fire. It walked out of the volcano still hot.",
	Type        = "Heavy",
	Pack        = "WarChest",
	Rarity      = "Mythic",
	Crate       = "WarChest",
	Finish      = "Infernal",
	Colors      = {Metal = Color3.fromRGB(26, 22, 30), Accent = Color3.fromRGB(255, 110, 30)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair", "Face", "Beard"},
	HelmName = "Obsidian Crown", TopName = "Obsidian Plate", LegsName = "Obsidian Greaves",
}
