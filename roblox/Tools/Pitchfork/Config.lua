--[[ PITCHFORK — weapon config (ModuleScript inside the Tool).

     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here (e.g. PARRY_WINDOW = 0.5 for a parry-friendly
     weapon, or KEYS = {...} for a different keymap). Both the server and
     client read this same module. ]]

return {
	-- shown on the loadout menu
	Name        = "Pitchfork",
	Description = "A farmer's tool with a long reach and a nasty point. Slow, two-handed, and it will go straight through a face.",

	-- animations
	IDLE_ID  = "rbxassetid://135659407369438",
	BLOCK_ID = "rbxassetid://130536914016941",

	-- feel
	SPEED_MULT = 0.5,   -- whole-weapon tempo; scales windup/release/recovery of every attack
	REACH      = 9.0,   -- studs from attacker root to a valid hit point (long weapon)
	TWO_HANDED = true,  -- a polearm: losing either arm drops it
	SECONDARY  = false, -- true = can also be carried in the SECONDARY slot (a polearm is primary-only)

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

	-- ATTACK NAMES: <Side><Type> — LeftSwing / RightSwing / LeftStab / RightStab /
	-- LeftOverhead / RightOverhead / LeftUnderhand / RightUnderhand — or just the
	-- type (Stab, Overhead) when it has no sides. Swing / Stab / Overhead / Underhand
	-- are the four inputs; the side comes from the mouse flick or the modifier key.
	--
	-- ANIMATIONS: `anim` is ONE clip of windup + swing (yours: 0.1 s wind-up then
	-- 0.3 s swing) and is stretched to `windup + active`, so its wind-up part IS
	-- the windup phase. Recovery is a hold after it ends. Optional two-clip form:
	--   windupAnim  idle → "loaded" pose, stretched to `windup`
	--   anim        the swing only, stretched to `active`
	-- Morph (new attack during windup): the new clip's wind-up plays over the
	-- windup that's left. Combo (new attack during the swing): once this swing
	-- ends the next clip starts at its swing part — no second wind-up.
	--
	--   damage      one number (× HEAD_DAMAGE_MULT / LEG_DAMAGE_MULT by region)
	--               or {head = 40, body = 20, legs = 14} for exact per-region numbers
	--   kind        "stab" (lethal face hit skewers) | "slash" (lethal hit severs)
	-- phase times are seconds at speed 1.0; all three divide by (speed * SPEED_MULT)
	ATTACKS = {
		-- the four you have (sides for the swing; the stab and overhead resolve without one)
		Stab       = {anim="rbxassetid://119395054343039", windupAnim=nil, kind="stab",  damage=18, windup=0.12, active=0.14, recovery=0.14, blockCost=20, staminaCost=8,  speed=1.0},
		LeftSwing  = {anim="rbxassetid://89500144760778",  windupAnim=nil, kind="slash", damage=15, windup=0.14, active=0.16, recovery=0.15, blockCost=18, staminaCost=8,  speed=1.0},
		RightSwing = {anim="rbxassetid://82652664048008",  windupAnim=nil, kind="slash", damage=15, windup=0.14, active=0.16, recovery=0.15, blockCost=18, staminaCost=8,  speed=1.0},
		Overhead   = {anim="rbxassetid://101285628758246", windupAnim=nil, kind="slash", damage=30, windup=0.20, active=0.18, recovery=0.20, blockCost=40, staminaCost=12, speed=0.8},
		-- the sided set: uncomment and fill as you make the animations. Once a
		-- sided version exists it wins over the plain one (RightStab beats Stab).
		-- LeftStab       = {anim="rbxassetid://0", windupAnim="rbxassetid://0", kind="stab", damage=30, windup=0.14, active=0.16, recovery=0.15, blockCost=20, staminaCost=8, speed=1.0},
		-- RightStab      = {anim="rbxassetid://0", windupAnim="rbxassetid://0", kind="stab", damage=30, windup=0.14, active=0.16, recovery=0.15, blockCost=20, staminaCost=8, speed=1.0},
		-- LeftOverhead   = {anim="rbxassetid://0", windupAnim="rbxassetid://0", kind="slash", damage=34, windup=0.18, active=0.16, recovery=0.18, blockCost=26, staminaCost=10, speed=0.9},
		-- RightOverhead  = {anim="rbxassetid://0", windupAnim="rbxassetid://0", kind="slash", damage=34, windup=0.18, active=0.16, recovery=0.18, blockCost=26, staminaCost=10, speed=0.9},
		-- LeftUnderhand  = {anim="rbxassetid://0", windupAnim="rbxassetid://0", kind="slash", damage=26, windup=0.13, active=0.16, recovery=0.15, blockCost=18, staminaCost=8, speed=1.1},
		-- RightUnderhand = {anim="rbxassetid://0", windupAnim="rbxassetid://0", kind="slash", damage=26, windup=0.13, active=0.16, recovery=0.15, blockCost=18, staminaCost=8, speed=1.1},
	},
	CYCLE_ORDER = {"Stab", "LeftSwing", "RightSwing", "Overhead"},   -- only used by weapons with no *Swing attacks
}
