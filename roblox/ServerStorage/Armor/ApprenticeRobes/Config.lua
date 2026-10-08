-- ServerStorage/Armor/ApprenticeRobes/Config  (ModuleScript inside the armor set)
-- The Mage's starter (GameConfig.CLASSES.Mage starter): free, a Robe. A class's starter set
-- is never another class's default (ClassStarter). Its clothing models are built from
-- Build ▸ Armor ▸ ApprenticeRobes until hand-made ones exist.
return {
	Name         = "Apprentice Robes",
	Description  = "A wizard's hat with its tip flopped over, a long robe in your colours, bell sleeves and a stole of gold stars. Robes, not armor: nothing in them will stop a blade.",
	Type         = "Robe",
	Pack         = "Starter_Robe",
	Rarity       = "Common",
	ClassStarter = "Mage",
	Covers       = {"Hair"},
	HelmName = "Apprentice's Hat", TopName = "Apprentice's Robe", LegsName = "Apprentice's Hem",
}
