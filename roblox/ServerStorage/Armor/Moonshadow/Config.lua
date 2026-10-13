-- ServerStorage/Armor/Moonshadow/Config  (ModuleScript inside the armor set)
-- A FLETCHER'S CRATE set: never sold, its pieces drop one at a time out of the Fletcher's
-- Crate, each a tradable copy, and it wears its own finish (Catalog ▸ ArmorFX: Moonlit).
-- Its clothing models are built from Build ▸ Armor ▸ Moonshadow until hand-made ones exist.
return {
	Name        = "Moonshadow",
	Description = "The rangers who hunt by moonlight: a deep hood with a crescent on the brow, a cloak edged in silver leaves, arrows fletched with light. You are seen when you choose to be.",
	Type        = "Light",
	Pack        = "Fletcher",
	Rarity      = "Legendary",
	Crate       = "Fletcher",
	Finish      = "Moonlit",
	Colors      = {Metal = Color3.fromRGB(214, 222, 236), Accent = Color3.fromRGB(200, 230, 255)},
	Covers      = {"Hair"},
	HelmName = "Moonshadow Hood", TopName = "Moonshadow Cloak", LegsName = "Moonshadow Greaves",
}
