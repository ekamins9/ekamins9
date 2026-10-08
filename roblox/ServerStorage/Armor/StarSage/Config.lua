-- ServerStorage/Armor/StarSage/Config  (ModuleScript inside the armor set)
-- A MAGE'S ROBE out of the ARCANA CRATE: never sold, its pieces drop one at a time, each a
-- tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Weight "Robe": only a Mage wears it. Its clothing models are built from Build ▸ Armor ▸ StarSage
-- until hand-made ones exist.
return {
	Name        = "Star Sage",
	Description = "A hood of night with a crescent moon hung over it, and constellations glowing across a robe cut from the sky itself.",
	Type        = "Robe",
	Pack        = "Arcana",
	Rarity      = "Mythic",
	Crate       = "Arcana",
	Finish      = "Celestial",
	Colors      = {Primary = Color3.fromRGB(26, 22, 64), Secondary = Color3.fromRGB(12, 10, 34), Accent = Color3.fromRGB(255, 240, 180)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Star Sage's Hood", TopName = "Star Sage's Robe", LegsName = "Star Sage's Hem",
}
