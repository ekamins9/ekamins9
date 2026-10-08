--[[ EGGS — the Hatchery in the Courtyard. Set an egg in one of your nests and
     it incubates in real time, even while you're away or in a match. Standing
     by the Hatchery makes your eggs incubate `boost` times as fast. A hatched
     egg gives a companion (Catalog ▸ Companions) rolled by the egg's odds.
       nests      how many eggs can incubate at once
       boost      how many times as fast while you stand by the Hatchery
       radius     studs from the Hatchery's middle that count as "by it"
       spot       where the Hatchery stands in a hub map: an offset from the
                  map's Floor part, per map name (a part named HatcherySpot in
                  the map wins)
       skipCrowns HATCH NOW: Crowns per hour still to go (rounded up, at least skipMin)
       stars      a duplicate companion adds a star, up to this many; past
                  that a duplicate pays `refund` Marks for its rarity
       eggs       id, name, rarity, minutes to hatch, marks / crowns (the
                  Hatchery's shelf; no price = not sold: gifts, the pass, login),
                  odds {Rarity = %} (sum 100), shell / spots colours, glow,
                  look (speckled · mossy · ember · royal: how the shell is drawn)
       variants   every hatch rolls one: Golden (gilded, sparkling) or Spectral (a
                  glowing ghost), at these percent chances (shown in the Hatchery);
                  the rest are ordinary
       exclusive  this egg hatches only its own companions (egg = "<id>"): every egg
                  is, so what's inside one is never inside another
     WHEN an egg is on the Hatchery's shelf: Catalog ▸ Calendar ▸ eggs (permanent
     eggs, the drops' eggs for a few weeks, event eggs for the event). An egg's
     own companions (egg = "<id>") only ever hatch from it.
     Paid random items: an egg bought with Marks or Crowns shows its odds first,
     and players whose region restricts paid random items get eggs only as gifts.
     Looks only: a companion never touches combat. ]]
return {
	nests = 3,
	boost = 2,
	radius = 20,
	spot = {Courtyard = Vector3.new(-39, 0, 4), default = Vector3.new(-39, 0, 4)},
	skipCrowns = 10,
	skipMin = 3,
	stars = 5,
	refund = {Common = 150, Rare = 400, Epic = 1000, Legendary = 2500, Mythic = 8000},
	variants = {Golden = 4, Spectral = 1},
	eggs = {
		{id = "Speckled", exclusive = true, name = "Speckled Egg", look = "speckled", rarity = "Common", minutes = 30, marks = 400,
			odds = {Common = 64, Rare = 28, Epic = 7, Legendary = 1},
			shell = Color3.fromRGB(238, 228, 206), spots = Color3.fromRGB(150, 118, 86)},
		{id = "Mossy", exclusive = true, name = "Mossy Egg", look = "mossy", rarity = "Rare", minutes = 120, marks = 1200,
			odds = {Common = 30, Rare = 46, Epic = 19, Legendary = 5},
			shell = Color3.fromRGB(128, 166, 100), spots = Color3.fromRGB(66, 98, 54)},
		{id = "Ember", exclusive = true, name = "Ember Egg", look = "ember", rarity = "Epic", minutes = 360, crowns = 60,
			odds = {Rare = 38, Epic = 46, Legendary = 16},
			shell = Color3.fromRGB(190, 70, 40), spots = Color3.fromRGB(255, 186, 70), glow = true},
		{id = "Royal", exclusive = true, name = "Royal Egg", look = "royal", rarity = "Legendary", minutes = 720,
			odds = {Epic = 55, Legendary = 45},
			shell = Color3.fromRGB(72, 62, 150), spots = Color3.fromRGB(255, 204, 80), glow = true},
		-- THE DROPS' EGGS: in the Hatchery only while the Calendar says so
		{id = "Grave", exclusive = true, name = "Grave Egg", look = "ember", rarity = "Epic", minutes = 90, marks = 1500, drop = "HollowNight",
			odds = {Common = 45, Rare = 35, Epic = 16, Legendary = 3, Mythic = 1},
			shell = Color3.fromRGB(46, 40, 56), spots = Color3.fromRGB(255, 140, 40), glow = true},
		{id = "Stag", exclusive = true, name = "Stag Egg", look = "mossy", rarity = "Rare", minutes = 120, marks = 1300, drop = "WildHunt",
			odds = {Common = 45, Rare = 38, Epic = 13, Legendary = 4},
			shell = Color3.fromRGB(150, 120, 80), spots = Color3.fromRGB(90, 120, 60)},
		{id = "Fjord", exclusive = true, name = "Fjord Egg", look = "speckled", rarity = "Rare", minutes = 120, marks = 1300, drop = "Northmen",
			odds = {Common = 45, Rare = 38, Epic = 13, Legendary = 4},
			shell = Color3.fromRGB(200, 214, 226), spots = Color3.fromRGB(60, 90, 120)},
		{id = "Frost", exclusive = true, name = "Frost Egg", look = "royal", rarity = "Epic", minutes = 180, marks = 1600, drop = "Frostfall",
			odds = {Common = 42, Rare = 38, Epic = 15, Legendary = 5},
			shell = Color3.fromRGB(200, 230, 255), spots = Color3.fromRGB(255, 255, 255), glow = true},
		{id = "Yule", exclusive = true, name = "Yule Egg", look = "royal", rarity = "Epic", minutes = 90, marks = 1500, drop = "Yuletide",
			odds = {Common = 45, Rare = 35, Epic = 16, Legendary = 3, Mythic = 1},
			shell = Color3.fromRGB(180, 30, 40), spots = Color3.fromRGB(60, 160, 80), glow = true},
		{id = "Tide", exclusive = true, name = "Tide Egg", look = "speckled", rarity = "Rare", minutes = 120, marks = 1300, drop = "BlackSails",
			odds = {Common = 45, Rare = 38, Epic = 13, Legendary = 4},
			shell = Color3.fromRGB(60, 140, 140), spots = Color3.fromRGB(240, 220, 160)},
	},
}
