-- ServerStorage/Armor/Ranger/Config  (ModuleScript inside the armor set)
-- A WAR CHEST set: never sold, its pieces drop one at a time out of the War
-- Chest, each a tradable copy.
-- Its clothing models are built from Build ▸ Armor ▸ Ranger until hand-made ones exist.
return {
	Name        = "Ranger",
	Description = "A forest hood with a red feather, a quiver on your back and boots that don't make a sound.",
	Type        = "Light",
	Pack        = "WarChest",
	Rarity      = "Rare",
	Crate       = "WarChest",
	Colors      = {Accent = Color3.fromRGB(200, 56, 44)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Ranger's Hood", TopName = "Ranger's Jerkin", LegsName = "Ranger's Boots",
}
