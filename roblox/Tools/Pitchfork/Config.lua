--[[ PITCHFORK — weapon config (ModuleScript inside the Tool).

     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here (e.g. PARRY_WINDOW = 0.5 for a parry-friendly
     weapon, or KEYS = {...} for a different keymap). Both the server and
     client read this same module. ]]

return {
	-- animations
	IDLE_ID  = "rbxassetid://135659407369438",
	BLOCK_ID = "rbxassetid://130536914016941",

	-- feel
	SPEED_MULT = 0.5,   -- whole-weapon tempo; scales windup/release/recovery of every attack
	REACH      = 9.0,   -- studs from attacker root to a valid hit point (long weapon)
	TWO_HANDED = true,  -- a polearm: losing either arm drops it

	-- sound slots (any you leave out fall back to CombatServer.DEFAULTS.SOUNDS)
	SOUNDS = {
		Equip = "rbxassetid://0",
		Swing = "rbxassetid://0",
		Hit   = "rbxassetid://0",
		Block = "rbxassetid://0",
		Parry = "rbxassetid://0",
		Kick  = "rbxassetid://0",
	},

	-- weight: published as SpeedMult_Weapon / ClunkMult_Weapon while equipped
	-- and composed with armor etc. (1 = no effect). A heavier weapon = lower
	-- SpeedMult, higher ClunkMult.
	SpeedMult = 1.0,
	ClunkMult = 1.0,

	-- phase times are seconds at speed 1.0; all three divide by (speed * SPEED_MULT)
	ATTACKS = {
		Stab       = {anim="rbxassetid://119395054343039", damage=18, windup=0.12, active=0.14, recovery=0.14, blockCost=20, staminaCost=8,  speed=1.0},
		LeftSwing  = {anim="rbxassetid://89500144760778",  damage=15, windup=0.14, active=0.16, recovery=0.15, blockCost=18, staminaCost=8,  speed=1.0},
		RightSwing = {anim="rbxassetid://82652664048008",  damage=15, windup=0.14, active=0.16, recovery=0.15, blockCost=18, staminaCost=8,  speed=1.0},
		Overhead   = {anim="rbxassetid://101285628758246", damage=30, windup=0.20, active=0.18, recovery=0.20, blockCost=40, staminaCost=12, speed=0.8},
	},
	CYCLE_ORDER = {"Stab", "LeftSwing", "RightSwing", "Overhead"},
}
