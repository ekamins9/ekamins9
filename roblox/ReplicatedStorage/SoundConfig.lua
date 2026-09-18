-- ReplicatedStorage/SoundConfig  (ModuleScript)
-- Global sound slots (not weapon-specific). Weapon sounds live in each
-- Tool's Config under SOUNDS. Leave "rbxassetid://0" to keep a slot silent.
return {
	Footstep  = "rbxassetid://0",   -- client: each clunk step (CameraRig)
	Heartbeat = "rbxassetid://0",   -- client: loop while bleeding / low HP (InjuryFX)
	Death     = "rbxassetid://0",   -- server: at the head on death
	Dismember = "rbxassetid://0",   -- server: limb severed
	Impale    = "rbxassetid://0",   -- server: lethal stab leaves the weapon in the body
	Bleed     = "rbxassetid://0",   -- server: bleed-out begins
	Disarm    = "rbxassetid://0",   -- server: weapon flies out of a hand
	BodyFall  = "rbxassetid://0",   -- server: ragdoll knockdown
}
