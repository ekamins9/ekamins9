-- ServerStorage/Armor/Battlemage/Config  (ModuleScript inside the armor set)
-- A MAGE'S ROBE out of the ARCANA CRATE: never sold, its pieces drop one at a time, each a
-- tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Weight "Robe": only a Mage wears it. Its clothing models are built from Build ▸ Armor ▸ Battlemage
-- until hand-made ones exist.
return {
	Name        = "Battlemage",
	Description = "A circlet with a glowing stone, the hood thrown back, and steel over the robe cut with runes: a Mage who expects to be hit.",
	Type        = "Robe",
	Pack        = "Arcana",
	Rarity      = "Legendary",
	Crate       = "Arcana",
	Finish      = "Runecarved",
	Colors      = {Secondary = Color3.fromRGB(50, 40, 70), Accent = Color3.fromRGB(140, 200, 255)},   -- (its own colours: the player's picks don't repaint these)
	HelmName = "Battlemage's Circlet", TopName = "Battlemage's Robe", LegsName = "Battlemage's Greaves",
}
