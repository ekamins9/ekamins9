-- ServerStorage/Armor/Greenwood/Config  (ModuleScript inside the armor set)
-- A FLETCHER'S CRATE set: never sold, its pieces drop one at a time out of the Fletcher's
-- Crate, each a tradable copy. An archer's outfit (Light).
-- Its clothing models are built from Build ▸ Armor ▸ Greenwood until hand-made ones exist.
return {
	Name        = "Greenwood Outlaws",
	Description = "Lincoln green and a feathered cap: the outlaws of the greenwood, who never miss and never pay the toll. A hunting horn at the hip, a quiver behind it.",
	Type        = "Light",
	Pack        = "Fletcher",
	Rarity      = "Rare",
	Crate       = "Fletcher",
	Colors      = {Primary = Color3.fromRGB(58, 98, 50), Secondary = Color3.fromRGB(96, 70, 44), Accent = Color3.fromRGB(176, 40, 36)},   -- (its own colours: the player's picks don't repaint these)
	Covers      = {"Hair"},
	HelmName = "Outlaw's Cap", TopName = "Outlaw's Tunic", LegsName = "Outlaw's Boots",
}
