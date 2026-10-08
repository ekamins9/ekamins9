-- ServerStorage/Armor/Necromancer/Config  (ModuleScript inside the armor set)
-- A MAGE'S ROBE out of the ARCANA CRATE: never sold, its pieces drop one at a time, each a
-- tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Weight "Robe": only a Mage wears it. Its clothing models are built from Build ▸ Armor ▸ Necromancer
-- until hand-made ones exist.
return {
	Name        = "Necromancer",
	Description = "A black hood crowned with a little skull, ribs of bone across the chest, skulls on the shoulders and the hem in tatters.",
	Type        = "Robe",
	Pack        = "Arcana",
	Rarity      = "Epic",
	Crate       = "Arcana",
	Finish      = "Voidtouched",
	Colors      = {Secondary = Color3.fromRGB(30, 28, 34), Accent = Color3.fromRGB(150, 255, 140)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Necromancer's Hood", TopName = "Necromancer's Robe", LegsName = "Necromancer's Rags",
}
