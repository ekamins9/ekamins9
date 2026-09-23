--[[ PITCHFORK — weapon config (ModuleScript inside the Tool).

     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here (e.g. PARRY_WINDOW = 0.5 for a parry-friendly
     weapon). Both the server and client read this same module. ]]

return {
	-- shown on the loadout menu
	Name        = "Pitchfork",
	Description = "A farmer's tool with a long reach and a nasty point. Slow, two-handed, and it will go straight through a face.",

	-- animations
	HIT_ID   = "rbxassetid://0",   -- optional flinch clip when a hit interrupts you (blended in and out)
	IDLE_ID  = "rbxassetid://135659407369438",
	BLOCK_ID = "rbxassetid://130536914016941",

	-- feel
	SPEED_MULT = 0.5,   -- whole-weapon tempo (every phase of every attack divides by it)
	TYPE_SPEED = {Swing = 1.0, Stab = 1.15, Overhead = 0.9, Underhand = 1.0},   -- per attack type, on top of SPEED_MULT
	WINDUP     = 0.25,  -- seconds (at speed 1) of blend into the loaded pose — the wind-up
	RECOVERY   = 0.15,  -- seconds (at speed 1) of hold after the swing clip ends
	REACH      = 9.0,   -- studs from attacker root to a valid hit point
	TWO_HANDED = true,  -- losing either arm drops it
	SECONDARY  = false, -- true = can also be carried in the SECONDARY slot

	-- sound slots (any you leave out fall back to CombatServer.DEFAULTS.SOUNDS).
	-- Never put "rbxassetid://0" here — that overrides a default with silence.
	SOUNDS = {
		Equip   = "rbxassetid://80636916996187",
		Swing   = "rbxassetid://135315310485417",
		Hit     = "rbxassetid://135119591308242",
		Block   = "rbxassetid://105287234173928",
		Parry   = "rbxassetid://79514980676418",
		Kick    = "rbxassetid://135708425496510",
		KickHit = "rbxassetid://105287234173928",   -- reusing Block until you have a boot-on-body sound
	},

	-- weight: published as SpeedMult_Weapon / ClunkMult_Weapon while equipped
	-- and composed with armor etc. (1 = no effect). A heavier weapon = lower
	-- SpeedMult, higher ClunkMult.
	SpeedMult = 1.0,
	ClunkMult = 1.0,

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
		LeftSwing      = {anim="rbxassetid://133334061889126", kind="slash", damage=15, blockCost=18, staminaCost=8},
		RightSwing     = {anim="rbxassetid://73820534240915", kind="slash", damage=15, blockCost=18, staminaCost=8},
		LeftStab       = {anim="rbxassetid://94684673453479", kind="stab", damage=18, blockCost=18, staminaCost=8},
		RightStab      = {anim="rbxassetid://108978202248647", kind="stab", damage=18, blockCost=18, staminaCost=8},
		LeftOverhead   = {anim="rbxassetid://127511139053596", kind="slash", damage=15, blockCost=18, staminaCost=8},
		RightOverhead  = {anim="rbxassetid://81289899270401", kind="slash", damage=15, blockCost=18, staminaCost=8},
		LeftUnderhand  = {anim="rbxassetid://0", kind="slash", damage=15, blockCost=18, staminaCost=8},
		RightUnderhand = {anim="rbxassetid://0", kind="slash", damage=15, blockCost=18, staminaCost=8},
	},
}
