--[[ SPEAR — weapon config (ModuleScript inside the Tool).
     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here. Both the server and client read this module.
     The Tool's body is built from Build ▸ Weapons.Spear if it has no Handle. ]]

return {
	Name        = "Spear",
	Description = "The oldest weapon there is. Keep the point between you and them.",

	HIT_ID   = "rbxassetid://0",
	IDLE_ID  = "rbxassetid://132465214430348",
	BLOCK_ID = "rbxassetid://72812411957933",

	SPEED_MULT = 0.5,
	TYPE_SPEED = {Swing = 1.0, Stab = 1.15, Overhead = 1.0, Underhand = 1.0},
	WINDUP     = 0.15,
	RECOVERY   = 0.15,
	REACH      = 10.5,
	TWO_HANDED = true,
	SECONDARY  = false,

	SpeedMult = 0.98,
	ClunkMult = 1.0,
	ARMOR_PEN = 0.15,   -- the share of a target's armor protection it ignores

	ATTACKS = {
		LeftSwing      = {anim="rbxassetid://133334061889126", kind="slash", damage=12, blockCost=9, staminaCost=4},
		RightSwing     = {anim="rbxassetid://73820534240915", kind="slash", damage=12, blockCost=9, staminaCost=4},
		LeftStab       = {anim="rbxassetid://94684673453479", kind="stab", damage=26, blockCost=20, staminaCost=8},
		RightStab      = {anim="rbxassetid://108978202248647", kind="stab", damage=26, blockCost=20, staminaCost=8},
		LeftOverhead   = {anim="rbxassetid://127511139053596", kind="slash", damage=12, blockCost=9, staminaCost=4},
		RightOverhead  = {anim="rbxassetid://81289899270401", kind="slash", damage=12, blockCost=9, staminaCost=4},
		LeftUnderhand  = {anim="rbxassetid://0", kind="slash", damage=12, blockCost=9, staminaCost=4},
		RightUnderhand = {anim="rbxassetid://0", kind="slash", damage=12, blockCost=9, staminaCost=4},
	},
}
