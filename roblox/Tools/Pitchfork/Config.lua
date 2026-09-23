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
	-- type (Stab, Overhead) when it has no sides. The client picks the side from
	-- the mouse flick on press. Each attack may also have:
	--   windupAnim = "rbxassetid://…"   separate windup animation, stretched to `windup`
	--                                   (the release anim is stretched to active+recovery)
	--   damage = {head = 40, body = 20, legs = 14}   exact per-region numbers, instead
	--                                   of one number × HEAD/LEG_DAMAGE_MULT
	-- phase times are seconds at speed 1.0; all three divide by (speed * SPEED_MULT)
	-- kind: "stab" kills leave the weapon run through the body; "slash" kills sever the limb hit
	ATTACKS = {
		Stab       = {anim="rbxassetid://119395054343039", kind="stab",  damage=18, windup=0.12, active=0.14, recovery=0.14, blockCost=20, staminaCost=8,  speed=1.0},
		LeftSwing  = {anim="rbxassetid://89500144760778",  kind="slash", damage=15, windup=0.14, active=0.16, recovery=0.15, blockCost=18, staminaCost=8,  speed=1.0},
		RightSwing = {anim="rbxassetid://82652664048008",  kind="slash", damage=15, windup=0.14, active=0.16, recovery=0.15, blockCost=18, staminaCost=8,  speed=1.0},
		Overhead   = {anim="rbxassetid://101285628758246", kind="slash", damage=30, windup=0.20, active=0.18, recovery=0.20, blockCost=40, staminaCost=12, speed=0.8},
	},
	CYCLE_ORDER = {"Stab", "LeftSwing", "RightSwing", "Overhead"},
}
