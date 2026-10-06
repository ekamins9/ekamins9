--[[ CLEAVER — weapon config (ModuleScript inside the Tool).
     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here. Both the server and client read this module.
     The Tool's body is built from Build ▸ Weapons.Cleaver if it has no Handle. ]]

return {
	Name        = "Cleaver",
	Description = "Taken from a butcher's block. Heavy chop, no point to speak of.",

	HIT_ID   = "rbxassetid://0",
	IDLE_ID  = "rbxassetid://135659407369438",
	BLOCK_ID = "rbxassetid://72812411957933",

	SPEED_MULT = 0.52,
	TYPE_SPEED = {Swing = 1.0, Stab = 0.8, Overhead = 1.0, Underhand = 1.0},
	WINDUP     = 0.15,
	RECOVERY   = 0.15,
	REACH      = 4.0,
	TWO_HANDED = false,
	SECONDARY  = true,

	SpeedMult = 1.0,
	ClunkMult = 1.0,

	ATTACKS = {
		LeftSwing      = {anim="rbxassetid://133334061889126", kind="slash", damage=24, blockCost=18, staminaCost=7},
		RightSwing     = {anim="rbxassetid://73820534240915", kind="slash", damage=24, blockCost=18, staminaCost=7},
		LeftStab       = {anim="rbxassetid://94684673453479", kind="stab", damage=8, blockCost=6, staminaCost=4},
		RightStab      = {anim="rbxassetid://108978202248647", kind="stab", damage=8, blockCost=6, staminaCost=4},
		LeftOverhead   = {anim="rbxassetid://127511139053596", kind="slash", damage=24, blockCost=18, staminaCost=7},
		RightOverhead  = {anim="rbxassetid://81289899270401", kind="slash", damage=24, blockCost=18, staminaCost=7},
		LeftUnderhand  = {anim="rbxassetid://0", kind="slash", damage=24, blockCost=18, staminaCost=7},
		RightUnderhand = {anim="rbxassetid://0", kind="slash", damage=24, blockCost=18, staminaCost=7},
	},
}
