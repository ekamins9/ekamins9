-- ServerStorage/Armor/FalconWardens/Config  (ModuleScript inside the armor set)
-- A FLETCHER'S CRATE set: never sold, its pieces drop one at a time out of the Fletcher's
-- Crate, each a tradable copy. An archer's outfit (Light).
-- Its clothing models are built from Build ▸ Armor ▸ FalconWardens until hand-made ones exist.
return {
	Name        = "Falcon Wardens",
	Description = "The king's falconers: a hood with a golden beak and amber eyes, a mantle of feathers, a falconer's gauntlet, and a falcon of their own riding on the shoulder.",
	Type        = "Light",
	Pack        = "Fletcher",
	Rarity      = "Epic",
	Crate       = "Fletcher",
	Colors      = {Accent = Color3.fromRGB(232, 184, 74)},
	Covers      = {"Hair"},
	HelmName = "Falcon Hood", TopName = "Falconer's Mantle", LegsName = "Talon Boots",
}
