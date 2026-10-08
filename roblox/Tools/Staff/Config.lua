--[[ ARCANE STAFF — the Mage's first weapon (ModuleScript inside the Tool). Both
     MagicServer and MagicClient read it; the spells' numbers are in
     ReplicatedStorage ▸ MagicSpells. The Tool's body is built from
     Build ▸ Weapons.Staff if it has no Handle.

     THE STAFF vs THE GRIMOIRE: the staff is the fighter's — full power, the WARD
     (right mouse: frontal blows cost mana instead of health), and a MELEE SELF
     (the Stance bind, H: it fights like a quarterstaff, with every melee swing).
     The grimoire casts faster and cheaper and carries a fifth spell, but has no
     ward, no melee, and its spells hit a little softer. ]]

return {
	Name        = "Arcane Staff",
	Description = "Blackwood shod in iron, four claws holding a light that never goes out. Four spells, a ward for when steel comes at you, and a stout length of wood when it does (H).",
	KIND        = "staff",
	STANCE      = 3,         -- RigPose: planted on the ground, lifted to cast

	SLOTS       = 4,         -- spells it carries (LOADOUT ▸ SPELLS)
	SPELLS      = {"Firebolt", "ChainLightning", "FrostNova", "Mend"},   -- (with no loadout yet)
	POWER       = 1.0,       -- × spell damage and healing
	CAST_MULT   = 1.0,       -- × cast times
	MANA_MULT   = 1.0,       -- × mana costs
	WALK        = 1.0,       -- × MagicSpells.CAST_WALK while casting
	WARD        = true,
	TWIN        = "StaffMelee",   -- its melee self (the Stance bind swaps them: LoadoutServer)

	-- where spells leave from: the orb, in the Handle's space; and on the server (which doesn't
	-- see the stance), where the orb is with the staff lifted, in the body's frame
	ORB         = Vector3.new(0, 3.55, 0),
	CAST_FROM   = Vector3.new(1, 3.4, -1.7),
}
