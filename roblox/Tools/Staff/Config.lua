--[[ ARCANE STAFF — the Mage's weapon (ModuleScript inside the Tool). Both
     MagicServer and MagicClient read it; the spells' numbers are in
     ReplicatedStorage ▸ MagicSpells. The Tool's body is built from
     Build ▸ Weapons.Staff if it has no Handle. ]]

return {
	Name        = "Arcane Staff",
	Description = "Blackwood shod in iron, four claws holding a light that never goes out. Fire, lightning, frost and mending; a ward for when steel comes at you.",
	KIND        = "staff",

	-- what it casts, in the spell bar's order (scroll / RB-LB to pick)
	SPELLS      = {"Firebolt", "ChainLightning", "FrostNova", "Mend"},
	-- where spells leave from: the orb, in the Handle's space
	ORB         = Vector3.new(0, 3.55, 0),
	-- held across the fist, not along the arm: an arm held out stands the staff upright
	-- (RigPose.staff tips it forward to cast)
	GRIP        = CFrame.Angles(math.rad(90), 0, 0),
}
