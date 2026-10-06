--[[ ESTOC — weapon config (ModuleScript inside the Tool).
     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here. Both the server and client read this module.
     The Tool's body is built from Build ▸ Weapons.Estoc if it has no Handle. ]]

return {
	Name        = "Estoc",
	Description = "A blade with no edge, only a point, meant to find the gaps in plate. Thrust, don't swing.",

	HIT_ID   = "rbxassetid://0",
	IDLE_ID  = "rbxassetid://132465214430348",
	BLOCK_ID = "rbxassetid://72812411957933",

	SPEED_MULT = 0.46,
	TYPE_SPEED = {Swing = 1.0, Stab = 1.1, Overhead = 1.0, Underhand = 1.0},
	WINDUP     = 0.15,
	RECOVERY   = 0.15,
	REACH      = 7.0,
	TWO_HANDED = true,
	SECONDARY  = false,

	SpeedMult = 1.0,
	ClunkMult = 1.0,

	ATTACKS = {
		LeftSwing      = {anim="rbxassetid://133334061889126", kind="slash", damage=14, blockCost=10, staminaCost=4},
		RightSwing     = {anim="rbxassetid://73820534240915", kind="slash", damage=14, blockCost=10, staminaCost=4},
		LeftStab       = {anim="rbxassetid://94684673453479", kind="stab", damage=32, blockCost=24, staminaCost=10},
		RightStab      = {anim="rbxassetid://108978202248647", kind="stab", damage=32, blockCost=24, staminaCost=10},
		LeftOverhead   = {anim="rbxassetid://127511139053596", kind="slash", damage=14, blockCost=10, staminaCost=4},
		RightOverhead  = {anim="rbxassetid://81289899270401", kind="slash", damage=14, blockCost=10, staminaCost=4},
		LeftUnderhand  = {anim="rbxassetid://0", kind="slash", damage=14, blockCost=10, staminaCost=4},
		RightUnderhand = {anim="rbxassetid://0", kind="slash", damage=14, blockCost=10, staminaCost=4},
	},
}
