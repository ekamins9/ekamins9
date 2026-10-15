--[[ ARSENAL — SHIELDS (the secondary slot, beside a one-handed primary) and THROWABLES
     (the third slot). Both join Catalog.WEAPONS (family "Shield" / "Throwable"), so they're
     unlocked, bought, skinned, crated and traded like any weapon; a Tool of each name in
     ServerStorage ▸ Weapons gives the body (built from Build ▸ Weapons when there's no
     hand-made one). Combat ▸ Shields and Combat ▸ Throwing use the numbers. Config only.

     SHIELDS — worn on the left arm, up in front of you while you block:
       block    × the stamina a block costs (lower: cheaper)
       cone     extra degrees a guard covers either side (it catches blows from wider)
       parry    × the parry window
       arrows   a raised shield stops arrows, bolts and thrown things from the front
       speed    × your walk (a big shield is heavy)
       bash     extra damage on a kick (a shield bash), stun = extra seconds it staggers
     THROWABLES — the Power key (E) throws one; charges come back one at a time:
       charges, recharge (s a charge), gap (s between throws), speed, gravity (studs/s²),
       damage, headMult, pierce (share of armor it ignores)
       snare    roots whoever it hits for that long
       burst    where it lands: {radius, time, dps, slow, heal, smoke, fire, frost, ground}
       look     how it flies: blade (spins end over end), axe, spear, dart, flask, bomb, bolas ]]

local SHIELDS = {
	{id = "Buckler", name = "Buckler", unlock = {free = true},
		block = 0.85, cone = 10, parry = 1.6, arrows = false, speed = 1.0, bash = 4,
		desc = "A fist-sized steel shield. It turns blows rather than stopping them: a far longer parry, but arrows get round it."},
	{id = "Targe", name = "Targe", unlock = {level = 2}, marks = 300,
		block = 0.75, cone = 15, parry = 1.2, arrows = true, speed = 1.0, bash = 4,
		desc = "A round leather-faced shield with a brass boss. Light, quick, and it stops an arrow."},
	{id = "RoundShield", name = "Round Shield", unlock = {level = 4}, marks = 700,
		block = 0.7, cone = 20, parry = 1.0, arrows = true, speed = 0.98, bash = 5,
		desc = "Planks of linden under a painted face and an iron rim, the northmen's shield."},
	{id = "Heater", name = "Heater Shield", unlock = {level = 6}, marks = 1100,
		block = 0.6, cone = 25, parry = 1.0, arrows = true, speed = 0.97, bash = 5,
		desc = "The knight's shield: a flat iron-bound heater that wears your colours."},
	{id = "SpikedShield", name = "Spiked Shield", unlock = {level = 9}, marks = 1400,
		block = 0.7, cone = 15, parry = 1.0, arrows = true, speed = 0.97, bash = 12, stun = 0.4,
		desc = "A round shield with a spike through the boss. Your kick becomes a bash that hurts."},
	{id = "Kite", name = "Kite Shield", unlock = {level = 11}, marks = 1600,
		block = 0.55, cone = 25, parry = 0.9, arrows = true, speed = 0.96, bash = 5,
		desc = "Long and pointed, it covers you from shoulder to shin."},
	{id = "Scutum", name = "Scutum", unlock = {level = 13}, marks = 1800,
		block = 0.5, cone = 30, parry = 0.85, arrows = true, speed = 0.94, bash = 7,
		desc = "The legion's curved wall of a shield. Blows from almost anywhere in front die on it."},
	{id = "Pavise", name = "Tower Pavise", unlock = {level = 16}, marks = 2200,
		block = 0.4, cone = 40, parry = 0.75, arrows = true, speed = 0.88, bash = 8,
		desc = "A door of oak and iron. Next to nothing gets past it, and you won't get anywhere fast."},
}

local THROWABLES = {
	{id = "ThrowingKnives", name = "Throwing Knives", unlock = {free = true}, look = "blade",
		charges = 3, recharge = 14, gap = 0.45, speed = 140, gravity = 22, damage = 16, headMult = 1.6,
		desc = "Three balanced knives, flat and fast. A quick 16 at range, more in the face."},
	{id = "ThrowingAxe", name = "Throwing Axe", unlock = {level = 3}, marks = 400, look = "axe",
		charges = 2, recharge = 18, gap = 0.7, speed = 100, gravity = 42, damage = 24, headMult = 1.5,
		desc = "A francisca that tumbles end over end. Two of them, and they hit hard."},
	{id = "Plumbata", name = "War Darts", unlock = {level = 4}, marks = 500, look = "dart",
		charges = 3, recharge = 16, gap = 0.5, speed = 85, gravity = 62, damage = 12, headMult = 1.5,
		desc = "Lead-weighted darts lobbed high: over a shield wall and down on their heads."},
	{id = "Javelin", name = "Javelin", unlock = {level = 5}, marks = 700, look = "spear",
		charges = 1, recharge = 20, gap = 1.0, speed = 115, gravity = 36, damage = 38, headMult = 1.4, pierce = 0.4,
		desc = "One heavy throwing spear, meant for armour: 38 damage, and it punches through plate."},
	{id = "Firebomb", name = "Firebomb", unlock = {level = 6}, marks = 900, look = "flask",
		charges = 1, recharge = 26, gap = 1.0, speed = 70, gravity = 60, damage = 4,
		burst = {radius = 6, time = 4, dps = 4, fire = true},
		desc = "A clay flask of oil and pitch. It bursts into a pool of fire that burns for 4 seconds."},
	{id = "FrostFlask", name = "Frost Flask", unlock = {level = 7}, marks = 900, look = "flask",
		charges = 1, recharge = 24, gap = 1.0, speed = 70, gravity = 60, damage = 2,
		burst = {radius = 6, time = 3, dps = 1, slow = 0.5, frost = true},
		desc = "Shatters into a cloud of hoarfrost: everyone caught in it moves at half speed."},
	{id = "SmokeBomb", name = "Smoke Bomb", unlock = {level = 8}, marks = 800, look = "bomb",
		charges = 1, recharge = 30, gap = 1.0, speed = 70, gravity = 60, damage = 0,
		burst = {radius = 10, time = 6, smoke = true},
		desc = "A thick grey cloud where it lands for 6 seconds. Archers can't see through it, and bots lose you in it."},
	{id = "Caltrops", name = "Caltrops", unlock = {level = 9}, marks = 800, look = "bomb",
		charges = 1, recharge = 26, gap = 1.0, speed = 60, gravity = 60, damage = 0,
		burst = {radius = 5, time = 9, dps = 2, slow = 0.35, ground = true},
		desc = "A spill of iron spikes. Whoever walks through them for the next 9 seconds limps and bleeds."},
	{id = "Bolas", name = "Bolas", unlock = {level = 10}, marks = 1000, look = "bolas",
		charges = 2, recharge = 20, gap = 0.8, speed = 90, gravity = 30, damage = 5, headMult = 1, snare = 1.5,
		desc = "Weighted cords that wrap round the legs: whoever they hit can't move for a moment and a half."},
	{id = "HolyWater", name = "Holy Water", unlock = {level = 12}, marks = 1100, look = "flask",
		charges = 1, recharge = 28, gap = 1.0, speed = 70, gravity = 60, damage = 0,
		burst = {radius = 6, time = 0, heal = 20, dps = 0, holyDamage = 8},
		desc = "Blessed water in a glass phial. Where it breaks your side heals 20, and foes are scalded."},
}

for _, s in ipairs(SHIELDS) do s.family = "Shield"; s.shield = true; s.secondary = false end
for _, t in ipairs(THROWABLES) do t.family = "Throwable"; t.throwable = true; t.secondary = false end

return {shields = SHIELDS, throwables = THROWABLES}
