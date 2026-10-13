-- ServerStorage/Armor/Bowman/Config  (ModuleScript inside the armor set)
-- THE ARCHER'S OWN (GameConfig.CLASSES.Archer starter): it comes with the class at level 5
-- (Unlock), and an Archer starts out in it. Any Light class may wear it once it's yours.
-- A class's starter is never another class's default (ClassStarter). Its clothing models
-- are built from Build ▸ Armor ▸ Bowman until hand-made ones exist.
return {
	Name         = "The Bowman",
	Description  = "A hood with a long tail and a dagged capelet in your colours, a leather jerkin, a quiver over the shoulder, a bracer on the bow arm and a glove on the draw hand. Comes with the Archer.",
	Type         = "Light",
	Pack         = "Bowman",
	Rarity       = "Common",
	ClassStarter = "Archer",
	Unlock       = {level = 5},
	Covers       = {"Hair"},
	HelmName = "Bowman's Hood", TopName = "Bowman's Jerkin", LegsName = "Bowman's Boots",
}
