-- ServerStorage/Armor/Frostwarden/Config  (ModuleScript inside the armor set)
-- A FORGE CRATE set: never sold, its pieces drop one at a time out of the Forge
-- Crate, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Its clothing models are built from Build ▸ Armor ▸ Frostwarden until hand-made ones exist.
return {
	Name        = "Frostwarden",
	Description = "The wardens of the high passes wear plate grown over with ice that never melts, and furs against the wind.",
	Type        = "Medium",
	Pack        = "Forge",
	Rarity      = "Legendary",
	Crate       = "Forge",
	Finish      = "Frostbound",
	Colors      = {Metal = Color3.fromRGB(226, 232, 240), Accent = Color3.fromRGB(176, 220, 255)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Crown of Icicles", TopName = "Warden's Rimeplate", LegsName = "Warden's Greaves",
}
