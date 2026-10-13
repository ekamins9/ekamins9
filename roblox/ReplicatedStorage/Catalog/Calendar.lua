--[[ CALENDAR — the release schedule: weekly DROPS, EVENTS, which CRATES and EGGS
     are in rotation when, free CLAIMS (numbered gifts), the FOUNDERS window and
     the shop FEATURES. Config only; ReplicatedStorage ▸ Drops reads it.

     HOW A RELEASE HAPPENS
       Everything for a drop (its skins with drop = "<id>", its crate, its egg)
       sits in the place already, hidden. At the drop's `at` time (UTC) every
       server shows it at once: no restart, no update needed. So: build the drop,
       publish the place any time before `at`, and it goes live by itself.
       Staff can release one early, or hold one back, from the admin panel (or
       /drop now <id> · /drop hold <id> · /drop clear), on every server at once.
       In Studio, /clock 2026-10-31 (or /clock +3d) pretends it is another day.

     drops    {id, at = "YYYY-MM-DD HH:MM" (UTC), name, tag, blurb, color = {r, g, b},
              headline = "<skin id>" (the picture on the board), crate, egg,
              see = {text, inspect = "kind|id"} (the announcement's button: by default
              SEE IT IN THE SHOP, to its crate)}
              Its announcement shows once per player, ever (profile dropSeen).
              A drop is the newest one from its `at` until the next drop's `at`.
              No `at` = TBD: it never comes out by itself (staff can still force it);
              the board says "at launch" instead of a countdown.
     events   {id, name, from, to, color, blurb, earn = {event = multiplier},
              modes = {mode ids the earn bonus is for (nil = all)}, after = dropId
              (never before that drop is out, whatever the dates say)}
     crates   per crate: windows = {{from = dropId|time, to = dropId|time|nil}},
              event = eventId (in rotation for the event), always = true
              (permanent), retire = true (once its last window ends its items
              are RELICS: never coming back). Not listed = always in rotation.
     eggs     the same, per egg
     claims   {id, from, to, reward = {skin | title | marks | keys | egg | crate}, note, after}
              everyone who plays while it is open gets it, once (numbered when
              it is a skin)
     founders {from = dropId, to = time | days = N, skin = "<skin id>", title = "Founder"}:
              everyone who plays between the two is a Founder, numbered in the order
              they came (days: N days after the drop comes out)
     beta     {from = dropId, to = dropId, title, finish = "<finish id>"}: everyone who
              plays in the beta is a Beta Tester, numbered: the title and the finish,
              bound, never sold, never in a crate (Collection.checkClaims)
     features {item = "<skin id>", from, to}: the WEAPONS shelf's headliner
     weekends {from = dropId, rotation = {event…}}: every weekend (Friday 16:00 to Monday
              08:00 UTC) the next event of the rotation runs, like any event above (earn,
              modes) plus `rule` (a change to play: "roulette" = Armory Roulette, a random
              weapon pair every spawn in battle). Skipped when a dated event is on. ]]

local C = Color3.fromRGB

-- THE BETA is on now. Every drop after it waits for the launch date (TBD: give the
-- Founders' Forge its `at` when it's known, and the weekly drops after it theirs).
local drops = {
	{id = "Beta", at = "2026-10-01 00:00", name = "The Proving Grounds", tag = "BETA", color = C(140, 230, 255),
		blurb = "You're here before the gates open. Everyone who plays in the beta is a Beta Tester, numbered for ever: the title, and Trailblazer, an armor finish nobody else will ever wear.",
		crate = "Royal", see = {text = "SEE YOUR TRAILBLAZER", inspect = "armorfx|Trailblazer"}},
	{id = "Founders", name = "The Founders' Forge", tag = "LAUNCH", color = C(255, 214, 140),
		blurb = "Every skin re-forged: new blades, new guards, glowing runes. Play in the first month and the Founder's Oath is yours, numbered for ever.",
		headline = "Longsword:Founder's Oath", crate = "Royal"},
	{id = "Bonewright", name = "Bonewright", tag = "NEW CRATE", color = C(222, 210, 182),
		blurb = "The Ossuary Crate: bone blades, skull pommels, vertebrae grips. One Mythic: The Marrow King.",
		headline = "Executioner:The Marrow King", crate = "Ossuary"},
	{id = "HollowNight", name = "The Hollow Night", tag = "EVENT", color = C(255, 140, 40),
		blurb = "Halloween comes to the keep. The Hollow Crate and the Grave Egg are here for two weeks only, then they are gone for good.",
		headline = "Halberd:The Hollow Headsman", crate = "Hollow", egg = "Grave"},
	{id = "AllHallows", name = "All Hallows' Eve", tag = "ONE NIGHT", color = C(255, 120, 30),
		blurb = "Play on Halloween and Jack's Grin is yours, numbered. Double XP all weekend.",
		headline = "Dagger:Jack's Grin"},
	{id = "Ironclad", name = "Ironclad", tag = "NEW CRATE", color = C(255, 150, 70),
		blurb = "The Foundry Crate: riveted plate, slag and sparks. One Mythic: The Forgefather.",
		headline = "Maul:The Forgefather", crate = "Foundry"},
	{id = "WildHunt", name = "The Wild Hunt", tag = "NEW CRATE", color = C(150, 230, 120),
		blurb = "Antlers, fur and thorn from the Wildwood. The Hunter's Crate and the Stag Egg.",
		headline = "Bardiche:The Horned King", crate = "WildHunt", egg = "Stag"},
	{id = "Northmen", name = "Northmen", tag = "SEASON 2", color = C(120, 200, 255),
		blurb = "The longships have landed at Stormbreak. Rune-carved axes, dragon pommels and the Fjord Egg.",
		headline = "BattleAxe:Jarl's Bane", crate = "Longship", egg = "Fjord"},
	{id = "SeaWolves", name = "Sea-Wolves", tag = "RAID WEEKEND", color = C(120, 200, 220),
		blurb = "Raid weekend: Horde pays double. The Royal Armoury is back for one week.",
		headline = "Longsword:Gilded", crate = "Royal"},
	{id = "Frostfall", name = "Frostfall", tag = "NEW CRATE", color = C(170, 230, 255),
		blurb = "Ice comes down from Frostgate. The Rime Crate and the Frost Egg.",
		headline = "Greatsword:Rimeheart", crate = "Rime", egg = "Frost"},
	{id = "Yuletide", name = "Yuletide", tag = "EVENT", color = C(230, 60, 60),
		blurb = "Snow in the Courtyard. The Yule Crate, the Yule Egg, and a gift every day until Christmas.",
		headline = "MorningStar:Krampus' Chain", crate = "Yule", egg = "Yule"},
	{id = "TwelfthNight", name = "Twelfth Night", tag = "LIMITED", color = C(150, 220, 255),
		blurb = "The Frostgift: only 2,026 will ever be made, each one numbered. When they are gone, they are gone.",
		headline = "Zweihander:Frostgift"},
	{id = "Midwinter", name = "Midwinter", tag = "NEW YEAR", color = C(255, 236, 180),
		blurb = "Last week of Yule. Play on New Year's Eve or Day for First Light, numbered.",
		headline = "Longsword:First Light"},
	{id = "BlackSails", name = "Black Sails", tag = "NEXT SEASON", color = C(90, 255, 210),
		blurb = "Pirates are coming. The Black Sails Crate, cutlasses and the Davy's Locker Mythic. Season 3 on 9 January.",
		headline = "Messer:Davy's Locker", crate = "BlackSails", egg = "Tide"},
}

local events = {
	{id = "Hollow2026", name = "The Hollow Night", from = "2026-10-24 16:00", to = "2026-11-08 16:00", after = "HollowNight", color = C(255, 140, 40),
		blurb = "Halloween event: the Hollow Crate and the Grave Egg, two weeks only."},
	{id = "HallowsXP", name = "Double XP Weekend", from = "2026-10-30 16:00", to = "2026-11-02 08:00", after = "AllHallows", color = C(255, 120, 30),
		blurb = "Everything pays double XP.", earn = {xp = 2}},
	{id = "RaidWeekend", name = "Raid Weekend", from = "2026-11-28 16:00", to = "2026-11-30 16:00", after = "SeaWolves", color = C(120, 200, 220),
		blurb = "Horde pays double Marks.", earn = {marks = 2}, modes = {"Horde"}},
	{id = "Yule2026", name = "Yuletide", from = "2026-12-12 16:00", to = "2027-01-03 16:00", after = "Yuletide", color = C(230, 60, 60),
		blurb = "Christmas event: the Yule Crate, the Yule Egg and a gift a day until the 24th."},
}

local claims = {
	{id = "JacksGrin", from = "2026-10-31 00:00", to = "2026-11-01 08:00", after = "AllHallows", reward = {skin = "Dagger:Jack's Grin"}, note = "for playing on Halloween"},
	{id = "FirstLight", from = "2026-12-31 00:00", to = "2027-01-02 00:00", after = "Midwinter", reward = {skin = "Longsword:First Light"}, note = "for seeing in the New Year"},
}
-- the Yule advent: a gift a day from the 13th to the 24th (play that day to get it)
local advent = {
	{marks = 300}, {keys = 1}, {marks = 400}, {egg = "Yule"}, {keys = 1}, {marks = 500},
	{crate = "Yule"}, {keys = 2}, {egg = "Yule"}, {marks = 800}, {keys = 2}, {crate = "Yule", title = "Yulekeeper"},
}
for i, r in ipairs(advent) do
	local day = 12 + i
	table.insert(claims, {id = "Advent" .. day, from = string.format("2026-12-%02d 00:00", day), to = string.format("2026-12-%02d 00:00", day + 1),
		reward = r, note = "Yule gift, " .. day .. " December", after = "Yuletide"})
end

return {
	drops = drops,
	events = events,
	claims = claims,
	-- (open for a month from the launch drop; `to = "YYYY-MM-DD HH:MM"` pins an exact end)
	founders = {from = "Founders", days = 30, skin = "Longsword:Founder's Oath", title = "Founder"},
	-- everyone who plays before the launch: numbered, the title and a finish of their own
	beta = {from = "Beta", to = "Founders", title = "Beta Tester", finish = "Trailblazer"},
	features = {
		{item = "Zweihander:Frostgift", from = "TwelfthNight", to = "BlackSails"},
	},
	-- a reason to come back every weekend: one of these, in turn
	weekends = {from = "Beta", rotation = {
		{id = "XP", name = "Double XP Weekend", color = C(120, 200, 255), blurb = "Every battle pays double XP all weekend.", earn = {xp = 2}},
		{id = "Roulette", name = "Armory Roulette", color = C(255, 196, 80),
			blurb = "Every time you spawn in battle you're handed a random weapon pair. Master them all! (+25% XP)", earn = {xp = 1.25}, rule = "roulette"},
		{id = "Raid", name = "Raid Weekend", color = C(120, 200, 220), blurb = "The Horde pays double Marks all weekend.", earn = {marks = 2}, modes = {"Horde"}},
		{id = "Marks", name = "War Chest Weekend", color = C(232, 184, 74), blurb = "Every battle pays half again as many Marks all weekend.", earn = {marks = 1.5}},
	}},
	crates = {
		Bladesmith = {always = true},
		Forge      = {always = true},
		WarChest   = {always = true},
		Arcana     = {always = true},
		Hafted     = {always = true},
		Relic      = {always = true},
		Grim       = {always = true},
		Fletcher   = {always = true},
		Royal      = {windows = {{from = "Beta", to = "HollowNight"}, {from = "SeaWolves", to = "Frostfall"}}},
		Ossuary    = {windows = {{from = "Bonewright", to = "Ironclad"}}},
		Hollow     = {event = "Hollow2026", retire = true},
		Foundry    = {windows = {{from = "Ironclad", to = "Northmen"}}},
		WildHunt   = {windows = {{from = "WildHunt", to = "Frostfall"}}},
		Longship   = {windows = {{from = "Northmen", to = "Yuletide"}}},
		Rime       = {windows = {{from = "Frostfall", to = "BlackSails"}}},
		Yule       = {event = "Yule2026", retire = true},
		BlackSails = {windows = {{from = "BlackSails"}}},
	},
	eggs = {
		Speckled = {always = true},
		Mossy    = {always = true},
		Ember    = {always = true},
		Royal    = {always = true},
		Grave    = {event = "Hollow2026", retire = true},
		Stag     = {windows = {{from = "WildHunt", to = "Northmen"}}},
		Fjord    = {windows = {{from = "Northmen", to = "Frostfall"}}},
		Frost    = {windows = {{from = "Frostfall", to = "Yuletide"}}},
		Yule     = {event = "Yule2026", retire = true},
		Tide     = {windows = {{from = "BlackSails"}}},
	},
}
