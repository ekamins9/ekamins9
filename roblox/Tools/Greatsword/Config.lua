--[[ GREATSWORD — weapon config (ModuleScript inside the Tool).

     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here (e.g. PARRY_WINDOW = 0.5 for a parry-friendly
     weapon, or KEYS = {...} for a different keymap). Both the server and
     client read this same module. ]]

return {
	-- shown on the loadout menu
	Name        = "Greatsword",
	Description = "Six feet of steel swung in great arcs. Every hit lands like a hammer, but it takes both hands and a wide stance.",

	-- animations
	IDLE_ID  = "rbxassetid://132465214430348",
	BLOCK_ID = "rbxassetid://72812411957933",

	-- feel
	SPEED_MULT = 0.4,   -- whole-weapon tempo; scales windup/release/recovery of every attack
	REACH      = 9.0,   -- studs from attacker root to a valid hit point (long weapon)
	TWO_HANDED = true,  -- losing either arm drops it
	SECONDARY  = false, -- true = can also be carried in the SECONDARY slot (a greatsword is primary-only)

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

	-- phase times are seconds at speed 1.0; all three divide by (speed * SPEED_MULT)
	-- kind: "stab" — a lethal face hit skewers the head on the blade;
	--       "slash" — a lethal hit severs the limb struck (or decapitates)
	ATTACKS = {
		Stab       = {anim="rbxassetid://108978202248647", kind="stab",  damage=30, windup=0.14, active=0.16, recovery=0.15, blockCost=20, staminaCost=8, speed=1.0},
		LeftSwing  = {anim="rbxassetid://89557792743992",  kind="slash", damage=30, windup=0.14, active=0.16, recovery=0.15, blockCost=20, staminaCost=8, speed=1.0},
		RightSwing = {anim="rbxassetid://113017879607829", kind="slash", damage=30, windup=0.14, active=0.16, recovery=0.15, blockCost=20, staminaCost=8, speed=1.0},
		Overhead   = {anim="rbxassetid://125963745291088", kind="slash", damage=30, windup=0.14, active=0.16, recovery=0.15, blockCost=20, staminaCost=8, speed=1.0},
	},
	CYCLE_ORDER = {"Stab", "LeftSwing", "RightSwing", "Overhead"},
}
