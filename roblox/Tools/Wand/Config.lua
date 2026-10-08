--[[ WAND — the Mage's sidearm (ModuleScript inside the Tool): it carries two WAND
     SPELLS of your choosing (MagicSpells: wand = true — Spark, Mote, Ember, Frost Dart,
     Zap, Gust; LOADOUT ▸ SPELLS ▸ WAND), quick and cheap (a sip of mana each). Weak:
     it's what you have when you're nearly dry and they're coming. No ward, no melee.
     The Tool's body is built from Build ▸ Weapons.Wand if it has no Handle. ]]

return {
	Name        = "Wand",
	Description = "A rod of pale ash with a crystal at the end. Two little spells, as fast as you like, for a sip of mana.",
	KIND        = "wand",
	STANCE      = 5,         -- RigPose: low at your side, pointed to cast

	WAND        = true,      -- carries wand spells (and only those)
	SLOTS       = 2,
	POWER       = 1.0,
	CAST_MULT   = 1.0,
	MANA_MULT   = 1.0,
	WALK        = 3.5,       -- (barely slows you)
	WARD        = false,

	ORB         = Vector3.new(0, 1.05, 0),
	CAST_FROM   = Vector3.new(1.0, 0.6, -2.2),
}
