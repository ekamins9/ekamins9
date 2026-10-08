-- ReplicatedStorage/MovementConfig  (ModuleScript)
-- Single source of truth for movement numbers, shared by the server
-- (WalkSpeedGovernor, MovementServer) and the client (CameraRig, Movement)
-- so they can never drift out of sync with each other.
return {
	BASE_SPEED = 11,     -- full-health, no-armor, no-modifiers WalkSpeed (was 10: the game's tempo, a touch quicker)

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
	DODGE_COST     = 10,   -- stamina (the BlockMeter)
	DODGE_COOLDOWN = 1.0,
	DODGE_SPEED    = 19,   -- studs/s during the burst…
	DODGE_TIME     = 0.10, -- …for this long (≈ 2 studs: a sidestep, not a leap)
	DODGE_LEAN     = 0.35, -- body lean into the dodge (RigPose lean input impulse)
	DODGE_REFUND   = 8,    -- stamina back when a dodge makes a swing miss you (CombatServer decides)
	DODGE_REFUND_RANGE = 2.5, -- …if the swing's reach came within this of you

	-- dodge keys: the Dodge bind (F) with a direction, or double-tap A / D / S
	-- (setting DodgeTap) within DODGE_TAP seconds
	DODGE_TAP      = 0.25,

	-- jump: a short hop on the Jump bind (Space), not a leap. Roblox's own jump
	-- stays switched off so holding the key can't bunny-hop; Movement turns it on
	-- for one hop at a time. Not while attacking, blocking, crouched or down.
	-- The same key stands you up from a seat.
	JUMP_POWER     = 28,   -- ≈ 2 studs up (height = power² / (2 × gravity))
	JUMP_COST      = 6,    -- stamina
	JUMP_COOLDOWN  = 0.9,
}
