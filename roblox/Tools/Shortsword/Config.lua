--[[ SHORTSWORD — weapon config (ModuleScript inside the Tool).

     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here (e.g. PARRY_WINDOW = 0.5 for a parry-friendly
     weapon). Both the server and client read this same module. ]]

return {
	-- shown on the loadout menu
	Name        = "Shortsword",
	Description = "Quick, light and always at hand. Won't win a reach contest — so don't have one.",

	-- animations
	IDLE_ID  = "rbxassetid://135659407369438",
	BLOCK_ID = "rbxassetid://72812411957933",

	-- feel
	SPEED_MULT = 0.45,   -- whole-weapon tempo (every phase of every attack divides by it)
	TYPE_SPEED = {Swing = 1.0, Stab = 1.1, Overhead = 1.0, Underhand = 1.1},   -- per attack type, on top of SPEED_MULT
	RECOVERY   = 0.14,  -- seconds (at speed 1) of hold after the swing clip ends
	REACH      = 4.0,   -- studs from attacker root to a valid hit point
	TWO_HANDED = false,  -- one hand: losing the LEFT arm doesn't drop it
	SECONDARY  = true, -- true = can also be carried in the SECONDARY slot

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
	-- Left and Right. Every attack has TWO clips: `windupAnim` (idle → loaded
	-- pose) and `anim` (the swing). TIMING COMES FROM THE CLIPS: the windup phase
	-- is the windupAnim's length and the active phase the swing clip's length,
	-- each divided by the attack's effective speed
	--     speed  ×  TYPE_SPEED[type]  ×  SPEED_MULT     (× RIPOSTE_SPEED after a parry)
	-- so morph / feint / chamber windows are the real windup at this weapon's
	-- tempo. RECOVERY is the hold after the swing (seconds at speed 1). An attack
	-- whose `anim` is still rbxassetid://0 can't be selected yet.
	--   damage   one number (× HEAD_DAMAGE_MULT / LEG_DAMAGE_MULT by region) or
	--            {head = 40, body = 20, legs = 14} for exact per-region numbers
	--   kind     "stab" (lethal face hit skewers) | "slash" (lethal hit severs)
	--   speed    optional per-attack multiplier (default 1)
	ATTACKS = {
		LeftSwing      = {anim="rbxassetid://133334061889126", windupAnim="rbxassetid://82159833969249", kind="slash", damage=20, blockCost=18, staminaCost=4},
		RightSwing     = {anim="rbxassetid://73820534240915", windupAnim="rbxassetid://98861449576171", kind="slash", damage=20, blockCost=18, staminaCost=4},
		LeftStab       = {anim="rbxassetid://94684673453479", windupAnim="rbxassetid://83482986790732", kind="stab", damage=20, blockCost=18, staminaCost=4},
		RightStab      = {anim="rbxassetid://108978202248647", windupAnim="rbxassetid://107986596699833", kind="stab", damage=20, blockCost=18, staminaCost=4},
		LeftOverhead   = {anim="rbxassetid://127511139053596", windupAnim="rbxassetid://82372263541812", kind="slash", damage=20, blockCost=18, staminaCost=4},
		RightOverhead  = {anim="rbxassetid://81289899270401", windupAnim="rbxassetid://73513400956855", kind="slash", damage=20, blockCost=18, staminaCost=4},
		LeftUnderhand  = {anim="rbxassetid://0", windupAnim="rbxassetid://0", kind="slash", damage=20, blockCost=18, staminaCost=4},
		RightUnderhand = {anim="rbxassetid://0", windupAnim="rbxassetid://0", kind="slash", damage=20, blockCost=18, staminaCost=4},
	},
}
