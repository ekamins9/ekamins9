--[[ WAND — the Mage's sidearm (ModuleScript inside the Tool): it casts one thing, a
     Spark (ReplicatedStorage ▸ MagicSpells.Spark), quickly, and costs no mana. Weak:
     it's what you have when you're dry and they're coming. No ward, no arsenal.
     The Tool's body is built from Build ▸ Weapons.Wand if it has no Handle. ]]

return {
	Name        = "Wand",
	Description = "A rod of pale ash with a crystal at the end. A spark at a time, as fast as you like, for nothing.",
	KIND        = "wand",
	STANCE      = 5,         -- RigPose: low at your side, pointed to cast

	FIXED       = {"Spark"},
	SLOTS       = 1,
	POWER       = 1.0,
	CAST_MULT   = 1.0,
	MANA_MULT   = 1.0,
	WALK        = 3.5,       -- (barely slows you)
	WARD        = false,

	ORB         = Vector3.new(0, 1.05, 0),
	CAST_FROM   = Vector3.new(1.0, 0.6, -2.2),
}
