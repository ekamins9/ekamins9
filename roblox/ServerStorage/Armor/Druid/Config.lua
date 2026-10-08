-- ServerStorage/Armor/Druid/Config  (ModuleScript inside the armor set)
-- A MAGE'S ROBE out of the ARCANA CRATE: never sold, its pieces drop one at a time, each a
-- tradable copy.
-- Weight "Robe": only a Mage wears it. Its clothing models are built from Build ▸ Armor ▸ Druid
-- until hand-made ones exist.
return {
	Name        = "Druid",
	Description = "An antlered hood crowned with leaves, a mantle of leaves over the shoulders and a living vine for a belt.",
	Type        = "Robe",
	Pack        = "Arcana",
	Rarity      = "Rare",
	Crate       = "Arcana",
	Colors      = {Secondary = Color3.fromRGB(96, 72, 46), Accent = Color3.fromRGB(96, 160, 64)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Druid's Antlers", TopName = "Druid's Robe", LegsName = "Druid's Hem",
}
