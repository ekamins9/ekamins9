--[[ ECONOMY — the two currencies and what feeds them.
     Marks: earned by playing, or bought with Crowns.  Crowns: Robux only.
       earn       Marks and XP per event (server-paid at round end; never trusted from a client)
       products   Robux bundles. Make a Developer Product on the Creator Dashboard
                  (Monetization ▸ Developer Products) named exactly `product`; the
                  server links it by name at start (or paste its id as `id`)
       exchange   Crowns → Marks tiers, one way
       levels     XP needed for each level-up (index = level reached); past the list, the last value repeats
       levelMarks Marks paid per level-up
       weaponLevels   handy reference for Weapons unlock = {level = n}
       premiumColor / premiumBody   default Crown prices when a Palette or Body entry sets crowns = true
       keys       Keys (open any crate, earned only, never sold): per level-up, for the first
                  win of the day, every `perContracts` daily tasks finished
       variants   every skin out of a crate rolls a finish at these percent chances
                  (shown with the odds): Masterwork (gold inlay, a shimmer) and Radiant
                  (its glow shifts through colours, an aura); three copies forge one up
       trading    who may trade (level), how many items a side, the countdown before confirming ]]
return {
	earn = {
		round   = {marks = 60,  xp = 120},   -- played a round to the end
		win     = {marks = 60,  xp = 120},   -- your side won / top of FFA
		kill    = {marks = 10,  xp = 30},
		parry   = {marks = 2,   xp = 5},
		chamber = {marks = 3,   xp = 8},
		drill   = {marks = 50,  xp = 60},    -- Tiltyard drill finished (once each)
		objective = {marks = 25, xp = 50},   -- there when a siege stage fell (ram, gate, zone, champion)
		wave    = {marks = 15,  xp = 30},    -- a Horde wave beaten (everyone in the server)
		firstWinOfDay = {marks = 200, xp = 0},
	},
	products = {
		{crowns = 100,  robux = 99,  id = 0, product = "100 Crowns"},
		{crowns = 550,  robux = 499, id = 0, product = "550 Crowns", bonus = "+10%"},
		{crowns = 1200, robux = 999, id = 0, product = "1200 Crowns", bonus = "+20%"},
		{crowns = 2600, robux = 1999, id = 0, product = "2600 Crowns", bonus = "+30%"},
	},
	exchange = {
		{marks = 500,  crowns = 30},
		{marks = 1200, crowns = 60},
		{marks = 3000, crowns = 120},
	},
	levels = {0, 500, 1200, 2000, 3000, 4200, 5600, 7200, 9000, 11000, 13500, 16500, 20000},
	levelMarks = 200,
	seasonDays = 42,
	-- SEASON REWARDS (Economy ▸ Season): paid when the season ends (Catalog ▸ Pass `ends`) to
	-- everyone at or above a place on a board; you get the best line you reached on each board.
	-- Warfront = the season's kills; Lists = each ranked bracket's rating (1v1, 2v2, 3v3).
	-- `tiers`: the ranked tier you finished the season in (your best bracket), for everyone.
	seasonRewards = {
		Warfront = {
			{top = 1,    reward = {title = "Warlord", crowns = 500, marks = 20000}},
			{top = 10,   reward = {title = "Bloodied Banner", crowns = 200, marks = 8000}},
			{top = 100,  reward = {title = "Hundred Slayer", crowns = 60, marks = 3000}},
			{top = 1000, reward = {marks = 1000, keys = 2}},
		},
		Lists = {
			{top = 1,   reward = {title = "Champion of the Lists", crowns = 500, marks = 15000}},
			{top = 10,  reward = {title = "Grand Duelist", crowns = 200, marks = 6000}},
			{top = 100, reward = {title = "Listed", crowns = 60, marks = 2500}},
		},
		tiers = {
			Knight   = {marks = 1000, keys = 1},
			Banneret = {marks = 2000, keys = 2, title = "Banneret"},
			Champion = {marks = 4000, crowns = 50, title = "Champion"},
		},
	},
	rankTiers = {"Peasant", "Levy", "Squire", "Knight", "Banneret", "Champion"},  -- each with III, II, I
	rankStep = 250,        -- rating points per tier (from 1000)
	ratingStart = 1500,
	placementMatches = 10,
	queueLockMinutes = 10, -- after abandoning a ranked match
	keys = {levelUp = 1, firstWin = 1, perContracts = 5},
	variants = {Masterwork = 5, Radiant = 1},
	trading = {minLevel = 5, maxItems = 8, countdown = 5},   -- (Economy ▸ Trading)
}
