--[[ GREATSWORD — weapon config (ModuleScript inside the Tool).

     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here (e.g. PARRY_WINDOW = 0.5 for a parry-friendly
     weapon). Both the server and client read this same module. ]]

return {
	-- shown on the loadout menu
	Name        = "Greatsword",
	Description = "Six feet of steel swung in great arcs. Every hit lands like a hammer, but it takes both hands and a wide stance.",

	-- animations
	HIT_ID   = "rbxassetid://0",   -- optional flinch clip when a hit interrupts you (blended in and out)
	IDLE_ID  = "rbxassetid://132465214430348",
	BLOCK_ID = "rbxassetid://72812411957933",

	-- feel
	SPEED_MULT = 0.4,   -- whole-weapon tempo (every phase of every attack divides by it)
	TYPE_SPEED = {Swing = 1.0, Stab = 1.0, Overhead = 1.0, Underhand = 1.0},   -- per attack type, on top of SPEED_MULT
	WINDUP     = 0.15,  -- seconds (at speed 1) of blend into the loaded pose — the wind-up
	RECOVERY   = 0.15,  -- seconds (at speed 1) of hold after the swing clip ends
	REACH      = 9.0,   -- studs from attacker root to a valid hit point
	TWO_HANDED = true,  -- losing either arm drops it
	SECONDARY  = false, -- true = can also be carried in the SECONDARY slot

	-- sounds: all weapons share CombatServer.DEFAULTS.SOUNDS. To give this one its
	-- own, add SOUNDS = {Swing = "rbxassetid://…", …} (only the slots you fill).

	-- weight: published as SpeedMult_Weapon / ClunkMult_Weapon while equipped
	-- and composed with armor etc. (1 = no effect). A heavier weapon = lower
	-- SpeedMult, higher ClunkMult.
	SpeedMult = 1.1,
	ClunkMult = 1.1,

	-- ATTACKS: one entry per <Side><Type> — Swing / Stab / Overhead / Underhand,
	-- Left and Right. ONE clip each: `anim` is the SWING; its first frame is the
	-- loaded pose. The windup is a BLEND: the clip fades in frozen on that first
	-- frame over WINDUP seconds (from idle, from a block, from another windup on
	-- a morph) — that fade is the wind-up motion. Then it runs: active = its
	-- length. Windup, active and RECOVERY all divide by
	--     speed  ×  TYPE_SPEED[type]  ×  SPEED_MULT     (× RIPOSTE_SPEED after a parry)
	-- so morph / feint / chamber windows are the real windup at this tempo.
	-- An attack whose `anim` is still rbxassetid://0 can't be selected yet.
	--   damage   one number (× HEAD_DAMAGE_MULT / LEG_DAMAGE_MULT by region) or
	--            {head = 40, body = 20, legs = 14} for exact per-region numbers
	--   kind     "stab" (lethal face hit skewers) | "slash" (lethal hit severs)
	--   speed    optional per-attack multiplier (default 1);  windup  optional override
	ATTACKS = {
		LeftSwing      = {anim="rbxassetid://133334061889126", kind="slash", damage=30, blockCost=20, staminaCost=10},
		RightSwing     = {anim="rbxassetid://73820534240915", kind="slash", damage=30, blockCost=20, staminaCost=10},
		LeftStab       = {anim="rbxassetid://94684673453479", kind="stab", damage=30, blockCost=20, staminaCost=10},
		RightStab      = {anim="rbxassetid://108978202248647", kind="stab", damage=30, blockCost=20, staminaCost=10},
		LeftOverhead   = {anim="rbxassetid://127511139053596", kind="slash", damage=30, blockCost=20, staminaCost=10},
		RightOverhead  = {anim="rbxassetid://81289899270401", kind="slash", damage=30, blockCost=20, staminaCost=10},
		LeftUnderhand  = {anim="rbxassetid://0", kind="slash", damage=30, blockCost=20, staminaCost=10},
		RightUnderhand = {anim="rbxassetid://0", kind="slash", damage=30, blockCost=20, staminaCost=10},
	},
}
