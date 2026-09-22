-- ReplicatedStorage/MovementConfig  (ModuleScript)
-- Single source of truth for movement numbers, shared by the server
-- (WalkSpeedGovernor, MovementServer) and the client (CameraRig, Movement)
-- so they can never drift out of sync with each other.
return {
	BASE_SPEED = 10,     -- full-health, no-armor, no-modifiers WalkSpeed

	-- sprint: forward / forward-diagonal only (published as SpeedMult_Sprint).
	-- Blocking, crouching, attacking, a stun or a ragdoll all end it.
	SPRINT_MULT    = 1.45,
	SPRINT_MIN_DOT = 0.5,  -- MoveDirection · LookVector must be at least this (≈ 60° cone)

	-- moving any way but forward is slower (published as SpeedMult_Facing);
	-- to reposition fast sideways or backwards you dodge
	BACKPEDAL_MULT = 0.65, -- MoveDirection · LookVector < -BACKPEDAL_DOT
	STRAFE_MULT    = 0.80, -- …anything else that isn't forward
	BACKPEDAL_DOT  = 0.35,
	FORWARD_DOT    = 0.5,  -- at/above this is "forward", full speed

	-- dodge: a burst to the side or backwards, never forward
	DODGE_COST     = 20,   -- stamina (the BlockMeter)
	DODGE_COOLDOWN = 1.0,
	DODGE_SPEED    = 42,   -- studs/s during the burst…
	DODGE_TIME     = 0.18, -- …for this long (≈ 7.5 studs)
	DODGE_LEAN     = 0.35, -- body lean into the dodge (RigPose lean input impulse)

	-- jumping is disabled: JumpPower 0 on the server, Jumping state off on the client
	NO_JUMP = true,
}
