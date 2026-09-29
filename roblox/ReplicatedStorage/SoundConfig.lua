-- ReplicatedStorage/SoundConfig  (ModuleScript)
-- Global sound slots (not weapon-specific). Weapon sounds live in each
-- Tool's Config under SOUNDS. Leave "rbxassetid://0" to keep a slot silent.
return {
	-- Fallback only: CameraRig prefers a per-material Sound from a
	-- FootstepSounds folder in SoundService (one Sound per Enum.Material name).
	Footstep  = "rbxasset://sounds/action_footsteps_plastic.mp3",
	Heartbeat = "rbxassetid://0",   -- client: loop while bleeding / low HP (InjuryFX)
	Death     = "rbxassetid://0",   -- server: at the head on death
	Dismember = "rbxassetid://0",   -- server: limb severed
	Impale    = "rbxassetid://0",   -- server: lethal face stab skewers the head on the blade
	Bleed     = "rbxassetid://0",   -- server: bleed-out begins
	Disarm    = "rbxassetid://0",   -- server: weapon flies out of a hand
	Pickup    = "rbxasset://sounds/unsheath.wav",   -- server: a weapon picked up off the floor
	Dodge     = "rbxassetid://0",   -- client: dodge burst
	Breathing = "rbxassetid://0",   -- client: looped heavy breathing while stamina is low (louder at 0)
	HeadThrow = "rbxassetid://0",   -- server: skewered head launched off the blade
	BodyFall  = "rbxassetid://0",   -- server: a body hitting the ground (Ragdoll.knockdown callers)
}
