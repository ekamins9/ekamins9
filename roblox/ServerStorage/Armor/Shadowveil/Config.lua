-- ServerStorage/Armor/Shadowveil/Config  (ModuleScript inside the armor set)
-- A FORGE CRATE set: never sold, its pieces drop one at a time out of the Forge
-- Crate, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX).
-- Its clothing models are built from Build ▸ Armor ▸ Shadowveil until hand-made ones exist.
return {
	Name        = "Shadowveil",
	Description = "A deep hood, a black half-mask and two eyes that burn in it. Runes on the leathers nobody can read.",
	Type        = "Light",
	Pack        = "Forge",
	Rarity      = "Legendary",
	Crate       = "Forge",
	Finish      = "Voidtouched",
	Covers      = {"Hair", "Beard"},
	HelmName = "Veil of Night", TopName = "Shadowveil Leathers", LegsName = "Shadowveil Hose",
}
