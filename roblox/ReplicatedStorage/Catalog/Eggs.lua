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
                  odds {Rarity = %} (sum 100), shell / spots colours, glow
     Looks only: a companion never touches combat. ]]
return {
	nests = 3,
	boost = 2,
	radius = 20,
	spot = {Courtyard = Vector3.new(-39, 0, 4), default = Vector3.new(-39, 0, 4)},
	skipCrowns = 10,
	skipMin = 3,
	stars = 5,
	refund = {Common = 150, Rare = 400, Epic = 1000, Legendary = 2500},
	eggs = {
		{id = "Speckled", name = "Speckled Egg", rarity = "Common", minutes = 30, marks = 400,
			odds = {Common = 64, Rare = 28, Epic = 7, Legendary = 1},
			shell = Color3.fromRGB(238, 228, 206), spots = Color3.fromRGB(150, 118, 86)},
		{id = "Mossy", name = "Mossy Egg", rarity = "Rare", minutes = 120, marks = 1200,
			odds = {Common = 30, Rare = 46, Epic = 19, Legendary = 5},
			shell = Color3.fromRGB(128, 166, 100), spots = Color3.fromRGB(66, 98, 54)},
		{id = "Ember", name = "Ember Egg", rarity = "Epic", minutes = 360, crowns = 60,
			odds = {Rare = 38, Epic = 46, Legendary = 16},
			shell = Color3.fromRGB(190, 70, 40), spots = Color3.fromRGB(255, 186, 70), glow = true},
		{id = "Royal", name = "Royal Egg", rarity = "Legendary", minutes = 720,
			odds = {Epic = 55, Legendary = 45},
			shell = Color3.fromRGB(72, 62, 150), spots = Color3.fromRGB(255, 204, 80), glow = true},
	},
}
