--[[ RONDEL DAGGER — weapon config (ModuleScript inside the Tool).
     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here. Both the server and client read this module.
     The Tool's body is built from Build ▸ Weapons.Dagger if it has no Handle. ]]

return {
	Name        = "Rondel Dagger",
	Description = "A hand's breadth of steel. Useless at range, deadly inside it: the stab goes through mail.",

	HIT_ID   = "rbxassetid://0",
	IDLE_ID  = "rbxassetid://135659407369438",
	BLOCK_ID = "rbxassetid://72812411957933",

	SPEED_MULT = 0.75,
	TYPE_SPEED = {Swing = 1.0, Stab = 1.15, Overhead = 1.0, Underhand = 1.0},
	WINDUP     = 0.15,
	RECOVERY   = 0.15,
	REACH      = 3.2,
	TWO_HANDED = false,
	SECONDARY  = true,

	SpeedMult = 1.04,
	ClunkMult = 0.9,
	ARMOR_PEN = 0.35,   -- the share of a target's armor protection it ignores

	ATTACKS = {
		LeftSwing      = {anim="rbxassetid://133334061889126", kind="slash", damage=14, blockCost=10, staminaCost=4},
		RightSwing     = {anim="rbxassetid://73820534240915", kind="slash", damage=14, blockCost=10, staminaCost=4},
		LeftStab       = {anim="rbxassetid://94684673453479", kind="stab", damage=18, blockCost=14, staminaCost=5},
		RightStab      = {anim="rbxassetid://108978202248647", kind="stab", damage=18, blockCost=14, staminaCost=5},
		LeftOverhead   = {anim="rbxassetid://127511139053596", kind="slash", damage=14, blockCost=10, staminaCost=4},
		RightOverhead  = {anim="rbxassetid://81289899270401", kind="slash", damage=14, blockCost=10, staminaCost=4},
		LeftUnderhand  = {anim="rbxassetid://0", kind="slash", damage=14, blockCost=10, staminaCost=4},
		RightUnderhand = {anim="rbxassetid://0", kind="slash", damage=14, blockCost=10, staminaCost=4},
	},
}
