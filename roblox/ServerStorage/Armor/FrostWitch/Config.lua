-- ServerStorage/Armor/FrostWitch/Config  (ModuleScript inside the armor set)
-- A MAGE'S ROBE out of the ARCANA CRATE: never sold, its pieces drop one at a time, each a
-- tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Weight "Robe": only a Mage wears it. Its clothing models are built from Build ▸ Armor ▸ FrostWitch
-- until hand-made ones exist.
return {
	Name        = "Frost Witch",
	Description = "A pale pointed hat hung with icicles, a white fur collar and shards of ice growing off the shoulders.",
	Type        = "Robe",
	Pack        = "Arcana",
	Rarity      = "Epic",
	Crate       = "Arcana",
	Finish      = "Frostbound",
	Colors      = {Secondary = Color3.fromRGB(200, 226, 246), Accent = Color3.fromRGB(150, 214, 255)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Frost Witch's Hat", TopName = "Frost Witch's Robe", LegsName = "Frost Witch's Hem",
}
