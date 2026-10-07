--[[ CRATES — a named loot table of weapon skins. A skin joins a crate by
     naming it (crate = "Bladesmith" in Skins) or by being listed in `skins`.
       name, description   shown on the card
       cost      Crowns per open (paid: Roblox's paid-random-item rules apply —
                 the odds below are shown before every open, and players whose
                 region restricts paid random items can only open with Keys)
       keys      Keys per open instead (Keys are earned only: level-ups, the
                 first win of the day, tasks; never bought), default 1
       odds      per-rarity percentages, must sum to 100 (shown to the player)
       pity      a Legendary OR BETTER is guaranteed within this many opens
                 (the odds shown switch to it when it is due)
       refund    Marks paid back for a duplicate, per rarity (and the duplicate
                 counts toward forging the skin up: Masterwork, Radiant)
       accent    the crate's colour on its card
     WHEN a crate is in rotation: Catalog ▸ Calendar ▸ crates (featured weekly,
     event crates, permanent ones). Add a crate: a key here, a line in the
     Calendar, and skins that name it. That's it. ]]
local C = Color3.fromRGB
local DROP_ODDS = {Common = 50, Rare = 30, Epic = 14, Legendary = 5.5, Mythic = 0.5}
local DROP_REFUND = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000, Mythic = 6000}
local EVENT_ODDS = {Rare = 55, Epic = 32, Legendary = 12, Mythic = 1}
local NO_COMMON = {Rare = 58, Epic = 30, Legendary = 11.5, Mythic = 0.5}
return {
	Bladesmith = {
		name = "Bladesmith's Crate", description = "Sword skins: every blade from dagger to zweihander.",
		cost = 60, odds = {Common = 55, Rare = 30, Epic = 12, Legendary = 3}, pity = 20,
		refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000}, accent = C(170, 180, 200),
	},
	Hafted = {
		name = "Hafted Crate", description = "Axe, hammer, mace and polearm skins.",
		cost = 60, odds = {Common = 55, Rare = 30, Epic = 12, Legendary = 3}, pity = 20,
		refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000}, accent = C(170, 130, 90),
	},
	Relic = {
		name = "Relic Crate", description = "Kill effects and emotes: thunder, fire, ice, a blade toss, a jig.",
		cost = 80, odds = {Common = 40, Rare = 35, Epic = 19, Legendary = 6}, pity = 15,
		refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000}, accent = C(150, 120, 255),
	},
	Fletcher = {
		name = "Fletcher's Crate", description = "Bow and crossbow skins. The Epics and Legendaries change the arrows: fire, frost, shadow, sunlight.",
		cost = 70, odds = {Common = 50, Rare = 32, Epic = 14, Legendary = 4}, pity = 20,
		refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000}, accent = C(120, 170, 80),
	},
	Grim = {
		name = "Grim Crate", description = "Kill effects only: a serpent from the ground, a hand from the sky, an anvil, a black hole.",
		cost = 80, odds = {Common = 40, Rare = 35, Epic = 19, Legendary = 6}, pity = 15,
		refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000}, accent = C(110, 200, 120),
	},
	Royal = {
		name = "Royal Armoury", description = "No Commons. Heraldic steel for every weapon and the crown jewels. Comes and goes.",
		cost = 120, odds = {Rare = 50, Epic = 38, Legendary = 12}, pity = 10,
		refund = {Rare = 500, Epic = 1200, Legendary = 3000}, accent = C(232, 184, 74),
	},
	-- THE DROPS (Catalog ▸ Calendar): each in rotation for a few weeks, then vaulted
	Ossuary = {
		name = "Ossuary Crate", description = "Bone blades, skull pommels, vertebrae grips. Mythic: The Marrow King.",
		cost = 75, odds = DROP_ODDS, pity = 20, refund = DROP_REFUND, accent = C(222, 210, 182),
	},
	Hollow = {
		name = "Hollow Crate", description = "Halloween 2026 only. Pumpkins, candles, witchlight. Mythic: The Hollow Headsman.",
		cost = 80, odds = EVENT_ODDS, pity = 15, refund = DROP_REFUND, accent = C(255, 140, 40),
	},
	Foundry = {
		name = "Foundry Crate", description = "Riveted plate, slag and sparks. Mythic: The Forgefather.",
		cost = 75, odds = NO_COMMON, pity = 20, refund = DROP_REFUND, accent = C(255, 150, 70),
	},
	WildHunt = {
		name = "Hunter's Crate", description = "Antlers, fur and thorn. Mythic: The Horned King.",
		cost = 75, odds = NO_COMMON, pity = 20, refund = DROP_REFUND, accent = C(150, 230, 120),
	},
	Longship = {
		name = "Longship Crate", description = "Rune-carved steel and dragon pommels from the north. Mythic: Jarl's Bane.",
		cost = 75, odds = NO_COMMON, pity = 20, refund = DROP_REFUND, accent = C(120, 200, 255),
	},
	Rime = {
		name = "Rime Crate", description = "Ice from Frostgate. Mythic: Rimeheart.",
		cost = 75, odds = NO_COMMON, pity = 20, refund = DROP_REFUND, accent = C(170, 230, 255),
	},
	Yule = {
		name = "Yule Crate", description = "Yuletide 2026 only. Candy canes, holly, starlight. Mythic: Krampus' Chain.",
		cost = 80, odds = EVENT_ODDS, pity = 15, refund = DROP_REFUND, accent = C(230, 60, 60),
	},
	BlackSails = {
		name = "Black Sails Crate", description = "Cutlasses, salt and sea-green brass. Mythic: Davy's Locker.",
		cost = 75, odds = NO_COMMON, pity = 20, refund = DROP_REFUND, accent = C(90, 255, 210),
	},
}
