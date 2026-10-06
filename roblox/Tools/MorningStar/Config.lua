--[[ MORNING STAR — weapon config (ModuleScript inside the Tool).
     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here. Both the server and client read this module.
     The Tool's body is built from Build ▸ Weapons.MorningStar if it has no Handle. ]]

return {
	Name        = "Morning Star",
	Description = "A spiked ball on a haft. Blunt and sharp at once; nobody blocks it comfortably.",

	HIT_ID   = "rbxassetid://0",
	IDLE_ID  = "rbxassetid://135659407369438",
	BLOCK_ID = "rbxassetid://72812411957933",

	SPEED_MULT = 0.44,
	TYPE_SPEED = {Swing = 1.0, Stab = 0.9, Overhead = 1.0, Underhand = 1.0},
	WINDUP     = 0.15,
	RECOVERY   = 0.15,
	REACH      = 5.0,
	TWO_HANDED = false,
	SECONDARY  = false,

	SpeedMult = 1.0,
	ClunkMult = 1.1,
	ARMOR_PEN = 0.45,   -- the share of a target's armor protection it ignores

	ATTACKS = {
		LeftSwing      = {anim="rbxassetid://133334061889126", kind="slash", damage=28, blockCost=21, staminaCost=8},
		RightSwing     = {anim="rbxassetid://73820534240915", kind="slash", damage=28, blockCost=21, staminaCost=8},
		LeftStab       = {anim="rbxassetid://94684673453479", kind="stab", damage=16, blockCost=12, staminaCost=5},
		RightStab      = {anim="rbxassetid://108978202248647", kind="stab", damage=16, blockCost=12, staminaCost=5},
		LeftOverhead   = {anim="rbxassetid://127511139053596", kind="slash", damage=28, blockCost=21, staminaCost=8},
		RightOverhead  = {anim="rbxassetid://81289899270401", kind="slash", damage=28, blockCost=21, staminaCost=8},
		LeftUnderhand  = {anim="rbxassetid://0", kind="slash", damage=28, blockCost=21, staminaCost=8},
		RightUnderhand = {anim="rbxassetid://0", kind="slash", damage=28, blockCost=21, staminaCost=8},
	},
}
