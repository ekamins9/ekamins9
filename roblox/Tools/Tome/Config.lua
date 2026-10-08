--[[ GRIMOIRE — the Mage's other weapon (ModuleScript inside the Tool): a spellbook held
     open before you. Against the staff (Tools ▸ Staff ▸ Config): FIVE spells, casts a
     quarter faster, a fifth cheaper, and you walk faster while casting; but no ward,
     no melee, and every spell hits 15% softer. A Mage who wants options, not a fight.
     The Tool's body is built from Build ▸ Weapons.Tome if it has no Handle. ]]

return {
	Name        = "Grimoire",
	Description = "Pages of spells in a hand you can't read, bound in iron. Five spells, quick and cheap to cast; nothing between you and a sword.",
	KIND        = "tome",
	STANCE      = 4,         -- RigPose: held open before you

	SLOTS       = 5,
	SPELLS      = {"Firebolt", "IceLance", "ChainLightning", "FrostNova", "Mend"},
	POWER       = 0.85,
	CAST_MULT   = 0.75,
	MANA_MULT   = 0.8,
	WALK        = 1.75,      -- (0.35 of your speed while casting, against the staff's 0.2)
	WARD        = false,

	ORB         = Vector3.new(0, 0.7, 0.5),        -- spells leave from the open pages
	CAST_FROM   = Vector3.new(0.6, 1.0, -2.0),
}
