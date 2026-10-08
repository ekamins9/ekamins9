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
	-- turned in the fist so a hand held low and forward stands it upright beside you, its
	-- foot near the ground, like a walking staff (RigPose.staff tips it forward to cast)
	GRIP        = CFrame.Angles(math.rad(35), 0, 0),
	-- where spells leave from on the server: the orb in the casting stance, body frame
	CAST_FROM   = Vector3.new(1, 2, -2.1),
}
