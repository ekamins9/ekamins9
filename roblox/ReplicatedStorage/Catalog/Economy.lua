--[[ ECONOMY — the two currencies and what feeds them.
     Marks: earned by playing, or bought with Crowns.  Crowns: Robux only.
       earn       Marks and XP per event (server-paid at round end; never trusted from a client)
       products   Developer Products (Creator Dashboard ▸ Monetization): paste the ids;
                  0 = not set up yet (the button says so)
       exchange   Crowns → Marks tiers, one way
       levels     XP needed for each level-up (index = level reached); past the list, the last value repeats
       levelMarks Marks paid per level-up
       weaponLevels   handy reference for Weapons unlock = {level = n}
       premiumColor / premiumBody   default Crown prices when a Palette or Body entry sets crowns = true ]]
return {
	earn = {
		round   = {marks = 60,  xp = 120},   -- played a round to the end
		win     = {marks = 60,  xp = 120},   -- your side won / top of FFA
		kill    = {marks = 10,  xp = 30},
		parry   = {marks = 2,   xp = 5},
		chamber = {marks = 3,   xp = 8},
		drill   = {marks = 50,  xp = 60},    -- Tiltyard drill finished (once each)
		firstWinOfDay = {marks = 200, xp = 0},
	},
	products = {
		{crowns = 100,  robux = 99,  id = 0},
		{crowns = 550,  robux = 499, id = 0, bonus = "+10%"},
		{crowns = 1200, robux = 999, id = 0, bonus = "+20%"},
	},
	exchange = {
		{marks = 500,  crowns = 30},
		{marks = 1200, crowns = 60},
		{marks = 3000, crowns = 120},
	},
	levels = {0, 500, 1200, 2000, 3000, 4200, 5600, 7200, 9000, 11000, 13500, 16500, 20000},
	levelMarks = 200,
	seasonDays = 42,
	rankTiers = {"Peasant", "Levy", "Squire", "Knight", "Banneret", "Champion"},  -- each with III, II, I
	rankStep = 250,        -- rating points per tier (from 1000)
	ratingStart = 1500,
	placementMatches = 10,
	queueLockMinutes = 10, -- after abandoning a ranked match
}
