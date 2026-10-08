-- ServerStorage/Armor/Archmage/Config  (ModuleScript inside the armor set)
-- A MAGE'S ROBE out of the ARCANA CRATE: never sold, its pieces drop one at a time, each a
-- tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Weight "Robe": only a Mage wears it. Its clothing models are built from Build ▸ Armor ▸ Archmage
-- until hand-made ones exist.
return {
	Name        = "Archmage",
	Description = "A towering hat of stars with a silver moon, a stiff high collar, a mantle of midnight and sleeves wide enough to hide a library in.",
	Type        = "Robe",
	Pack        = "Arcana",
	Rarity      = "Legendary",
	Crate       = "Arcana",
	Finish      = "Stormborn",
	Colors      = {Secondary = Color3.fromRGB(30, 34, 84), Accent = Color3.fromRGB(222, 228, 240)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Archmage's Hat", TopName = "Archmage's Robe", LegsName = "Archmage's Hem",
}
