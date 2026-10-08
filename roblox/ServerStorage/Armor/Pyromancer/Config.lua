-- ServerStorage/Armor/Pyromancer/Config  (ModuleScript inside the armor set)
-- A MAGE'S ROBE out of the ARCANA CRATE: never sold, its pieces drop one at a time, each a
-- tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Weight "Robe": only a Mage wears it. Its clothing models are built from Build ▸ Armor ▸ Pyromancer
-- until hand-made ones exist.
return {
	Name        = "Pyromancer",
	Description = "A cowl crested with flame, ember gems that never cool, and fire licking up every hem.",
	Type        = "Robe",
	Pack        = "Arcana",
	Rarity      = "Epic",
	Crate       = "Arcana",
	Finish      = "Emberforged",
	Colors      = {Secondary = Color3.fromRGB(42, 32, 30), Accent = Color3.fromRGB(255, 140, 40)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Pyromancer's Cowl", TopName = "Pyromancer's Robe", LegsName = "Pyromancer's Hem",
}
