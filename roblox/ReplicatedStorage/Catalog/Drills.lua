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

     THREE TEACHERS (tracks): Sir Aldric teaches steel (no `track`); Wren the
     Bowmaster teaches the bow at the archery range (track = "archer"); Magister
     Orrin teaches magic at the arcane circle (track = "mage"). A track's class
     (tracks ▸ class) must be open to you (GameConfig.CLASSES unlock: level 5),
     and its lessons dress you as that class. Their events:
       arrow     an arrow lands on a target (full = at full draw · head = in the
                 head · far = from at least that many studs away)
       charge    a bot of `skill` comes down the range at you: bring it down
       spell     a spell lands on a target · cast (that many DIFFERENT spells cast)
       meditate  that much mana won back meditating (you start low)
       ward      a blow turned by your Ward · chain (one Chain Lightning strikes
                 two targets) · staffhit (a hit with the staff's melee self)
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

		-- WREN THE BOWMASTER, at the archery range
		{id = "loose", track = "archer", title = "Nock and Loose", goal = 3, event = "arrow",
			text = "Hold {Swing} to draw, let go to loose. Put three arrows into the straw targets down the range."},
		{id = "fulldraw", track = "archer", title = "Full Draw", goal = 2, event = "arrow", full = true,
			text = "Hold the draw until the bow creaks: a full-draw arrow flies flatter and hits far harder. Two hits at full draw!"},
		{id = "headshot", track = "archer", title = "Between the Eyes", goal = 1, event = "arrow", head = true,
			text = "An arrow to the head is worth half again. Put one in a target's head."},
		{id = "longshot", track = "archer", title = "The Long Shot", goal = 1, event = "arrow", far = 40,
			text = "Back to the far line! Arrows drop over distance: aim a little high. Hit a target from forty paces."},
		{id = "holdline", track = "archer", title = "Hold the Line", goal = 1, event = "charge", skill = "Squire",
			text = "A Squire is charging down the range at you! Shoot him down before he reaches you (and if he does, your sidearm is on 2)."},

		-- MAGISTER ORRIN, at the arcane circle
		{id = "firstfire", track = "mage", title = "First Fire", goal = 2, event = "spell",
			text = "{Swing} casts the spell you hold. A Firebolt flies slowly: lead your target. Burn the straw dummies twice."},
		{id = "arsenal", track = "mage", title = "Your Arsenal", goal = 3, event = "cast",
			text = "You carry several spells: {Stab} and {Overhead} pick the next one along the bar. Cast three DIFFERENT spells."},
		{id = "meditate", track = "mage", title = "Breathe", goal = 40, event = "meditate",
			text = "Mana only comes back when you meditate. Stand still and hold {Reload}. Win back forty mana."},
		{id = "ward", track = "mage", title = "The Ward", goal = 2, event = "ward", setup = "attacker",
			text = "Your staff can shield you: hold {Block} to raise a Ward. It turns blows from the front, for mana. Ward off two of the drill dummy's blows."},
		{id = "leap", track = "mage", title = "Lightning Leaps", goal = 1, event = "chain",
			text = "Chain Lightning jumps from one foe to the next. Strike one of the dummies standing together so it leaps to another."},
		{id = "bonk", track = "mage", title = "Staff and Steel", goal = 2, event = "staffhit",
			text = "Too close for spells? Press {Stance}: your staff fights like a quarterstaff. Hit a straw dummy twice with it, then {Stance} back."},
		{id = "spellbound", track = "mage", title = "Spellbound", goal = 1, event = "charge", skill = "Squire",
			text = "A Squire is charging at you! Bring him down with your spells: Frost Nova if he gets close. Then stand still and breathe."},
	},
	-- the teachers: who teaches each track, where (Map ▸ Spots), and the class it's for
	tracks = {
		knight = {master = "Sir Aldric, Drill Master", short = "DRILL MASTER", spot = "DrillMaster"},
		archer = {master = "Wren, Bowmaster", short = "BOWMASTER", spot = "Bowmaster", class = "Archer", where = "THE ARCHERY RANGE"},
		mage   = {master = "Magister Orrin", short = "MAGISTER", spot = "Magister", class = "Mage", where = "THE ARCANE CIRCLE"},
	},
	spar = {
		Squire   = {first = 100, again = 15},
		Knight   = {first = 250, again = 30},
		Champion = {first = 600, again = 60},
	},
	-- the Gauntlet: each wave cleared past your best pays perWave Marks (up to wave payTo)
	gauntlet = {perWave = 25, payTo = 20},
}
