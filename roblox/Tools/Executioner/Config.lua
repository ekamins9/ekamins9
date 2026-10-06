--[[ EXECUTIONER'S SWORD — weapon config (ModuleScript inside the Tool).
     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here. Both the server and client read this module.
     The Tool's body is built from Build ▸ Weapons.Executioner if it has no Handle. ]]

return {
	Name        = "Executioner's Sword",
	Description = "Broad, flat-tipped, built for one job. No point, all edge.",

	HIT_ID   = "rbxassetid://0",
	IDLE_ID  = "rbxassetid://132465214430348",
	BLOCK_ID = "rbxassetid://72812411957933",

	SPEED_MULT = 0.38,
	TYPE_SPEED = {Swing = 1.0, Stab = 0.6, Overhead = 1.0, Underhand = 1.0},
	WINDUP     = 0.15,
	RECOVERY   = 0.15,
	REACH      = 8.0,
	TWO_HANDED = true,
	SECONDARY  = false,

	SpeedMult = 0.94,
	ClunkMult = 1.15,
	ARMOR_PEN = 0,   -- the share of a target's armor protection it ignores

	ATTACKS = {
		LeftSwing      = {anim="rbxassetid://133334061889126", kind="slash", damage=36, blockCost=27, staminaCost=11},
		RightSwing     = {anim="rbxassetid://73820534240915", kind="slash", damage=36, blockCost=27, staminaCost=11},
		LeftStab       = {anim="rbxassetid://94684673453479", kind="stab", damage=10, blockCost=8, staminaCost=4},
		RightStab      = {anim="rbxassetid://108978202248647", kind="stab", damage=10, blockCost=8, staminaCost=4},
		LeftOverhead   = {anim="rbxassetid://127511139053596", kind="slash", damage=36, blockCost=27, staminaCost=11},
		RightOverhead  = {anim="rbxassetid://81289899270401", kind="slash", damage=36, blockCost=27, staminaCost=11},
		LeftUnderhand  = {anim="rbxassetid://0", kind="slash", damage=36, blockCost=27, staminaCost=11},
		RightUnderhand = {anim="rbxassetid://0", kind="slash", damage=36, blockCost=27, staminaCost=11},
	},
}
