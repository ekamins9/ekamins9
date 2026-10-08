--[[ DRILLS — the Drill Master's lessons in the training yard (Game ▸ Training),
     in the order he teaches them, and the sparring ring's rewards.
       lessons   id, title, text (what he says; {Swing} … become your own key
                 binds), goal (how many times), event (what counts):
                   hit (kind = "Swing" / "Stab" / "Overhead": an attack of
                   that kind lands on a dummy) · sides (a hit from each side)
                   · guard · parry · riposte · feint · morph · kick · dodge ·
                   chamber · spar (skill = a win in the ring at that level) ·
                   basics (each of `controls` tried once: the client reports the
                   key presses, Training.client; goal = how many)
                 setup: "attacker" (a drill dummy swings at you) or "blocker"
                 (a dummy that never drops its guard)
                 basic: part of BASIC TRAINING, the short course every newcomer
                 is put through on their first visit (they're placed in front of
                 each step's dummy; then it's off to their first battle)
     A lesson finished for the first time pays Catalog ▸ Economy ▸ earn.drill
     and counts as a drill (daily tasks, the Drill Master title).
       spar      per skill: first (Marks for your first win) and again (each win after)
       gauntlet  perWave (Marks for each wave past your best), payTo (no pay past this wave) ]]
return {
	lessons = {
		{id = "basics", title = "Find Your Feet", goal = 6, event = "basics", basic = true,
			controls = {"View", "Sprint", "Crouch", "Jump", "Dodge", "Cursor"},
			text = "Before the steel, your feet. Try each control on the list: the camera, a sprint, a crouch, a hop and a dodge (and with a mouse, setting it free)."},
		{id = "swing", title = "The Swing", goal = 3, event = "hit", kind = "Swing", basic = true,
			text = "Every fight starts with a good swing. Strike a straw dummy with {Swing}. Three times!"},
		{id = "stab", title = "The Stab", goal = 2, event = "hit", kind = "Stab", basic = true,
			text = "A stab is quick and narrow: aim it at the body. Thrust with {Stab}."},
		{id = "overhead", title = "The Overhead", goal = 2, event = "hit", kind = "Overhead", basic = true,
			text = "Bring it down from above with {Overhead}. Slow, but it crushes a guard that isn't ready."},
		{id = "sides", title = "Both Sides", goal = 2, event = "sides",
			text = "Hold {SideFlip} to strike from your other side. Land one hit from the left and one from the right."},
		{id = "block", title = "Raise Your Guard", goal = 2, event = "guard", setup = "attacker", basic = true,
			text = "This dummy swings at you. Hold {Block} to block. Stop two blows."},
		{id = "parry", title = "The Parry", goal = 1, event = "parry", setup = "attacker", basic = true,
			text = "Raise your guard at the last moment, just before the blow lands: that's a parry, and it costs you nothing. Parry once!"},
		{id = "riposte", title = "The Riposte", goal = 1, event = "riposte", setup = "attacker",
			text = "After a parry your next strike comes faster. Parry the dummy, then hit it straight back!"},
		{id = "feint", title = "The Feint", goal = 2, event = "feint",
			text = "Start a swing, then press {Feint} before it lands to pull it back. Make them flinch at nothing. Feint twice."},
		{id = "morph", title = "The Morph", goal = 2, event = "morph",
			text = "Start one attack and press another during its windup to switch: swing, then {Stab}. Twice."},
		{id = "kick", title = "Break the Guard", goal = 1, event = "kick", setup = "blocker", basic = true,
			text = "Some fighters hide behind their guard. That dummy never drops it, so kick it with {Kick}!"},
		{id = "dodge", title = "Footwork", goal = 3, event = "dodge", setup = "attacker",
			text = "Sidestep my drill dummy's blows: press {Dodge} with a direction (or double-tap one). Dodge three times."},
		{id = "chamber", title = "The Chamber", goal = 1, event = "chamber", setup = "attacker",
			text = "The masters' trick: as the dummy swings, start the SAME attack from your mirrored side. Its blow dies and yours lands. Once!"},
		{id = "spar", title = "First Blood", goal = 1, event = "spar", skill = "Squire", basic = true,
			text = "Enough dummies. A Squire meets you in the ring: use what you learned and beat him!"},
	},
	spar = {
		Squire   = {first = 100, again = 15},
		Knight   = {first = 250, again = 30},
		Champion = {first = 600, again = 60},
	},
	-- the Gauntlet: each wave cleared past your best pays perWave Marks (up to wave payTo)
	gauntlet = {perWave = 25, payTo = 20},
}
