--[[ PERKS — the dungeon game's class perks (the Deadvault lobby's CLASS tab): PICK of your
     class's perks go into The Depths and Deadvault with you (Game ▸ Perks puts them on).
     Config only: a new perk is a new line.

       id, name, class (a class id, a list of them, or "any"), text, look (its icon: a relic's or
       a valuable's look, DarkUI), and what it does —
         mods        Powers.addMods (taken, dealt, speed, stamina, draw, cast, dodgeCost…)
         health      + max health
         quiet       half the noise you make (Combat ▸ Perception)
         ambush      a sneak attack hits ×3 (×3.5 on a sleeper)
         secondWind  once a raid, falling under a quarter of your health mends this much of it
         bag         more room in a raid's bag
         luck        every container you open is kinder ]]

return {
	PICK = 2,
	list = {
		{id = "SecondWind", class = "any", name = "Second Wind", look = {kind = "relic", relic = "TrollHeart"}, secondWind = 0.4,
			text = "Once a raid, when you fall under a quarter of your health, you catch your breath: 40% of it back."},
		{id = "Scavenger", class = "any", name = "Scavenger", look = {kind = "relic", relic = "LuckyCoin"}, luck = 0.6,
			text = "Every chest, crate and corpse you open is kinder to you."},
		{id = "IronWill", class = "Knight", name = "Iron Will", look = {kind = "relic", relic = "IronBand"}, mods = {taken = 0.9},
			text = "You take 10% less damage from everything."},
		{id = "Unshaken", class = "Knight", name = "Unshaken", look = {kind = "relic", relic = "OxHeart"}, health = 20,
			text = "Twenty more health."},
		{id = "Crusher", class = {"Knight", "Footman"}, name = "Crusher", look = {kind = "relic", relic = "WarHorn"}, mods = {dealt = 1.08},
			text = "Your blows land 8% harder."},
		{id = "PackMule", class = {"Footman", "Knight"}, name = "Pack Mule", look = {kind = "relic", relic = "GiantsBelt"}, bag = 6,
			text = "Your bag holds six more things."},
		{id = "Drilled", class = "Footman", name = "Drilled", look = {kind = "relic", relic = "WindBoots"}, mods = {stamina = 1.25},
			text = "Your wind comes back 25% faster."},
		{id = "Steadfast", class = "Footman", name = "Steadfast", look = {kind = "treasure", treasure = "BronzeBell"}, mods = {taken = 0.94, speed = 1.03},
			text = "6% less damage taken, and a little quicker on your feet."},
		{id = "LightStep", class = {"Vanguard", "Archer", "Mage"}, name = "Light Step", look = {kind = "relic", relic = "HareFoot"}, quiet = true,
			text = "You make half the noise: the dark hears you from half as far."},
		{id = "Ambusher", class = "Vanguard", name = "Ambusher", look = {kind = "relic", relic = "CountessFang"}, ambush = true,
			text = "A sneak attack lands three times as hard (three and a half on a sleeper)."},
		{id = "Fleet", class = "Vanguard", name = "Fleet", look = {kind = "relic", relic = "PhoenixPlume"}, mods = {speed = 1.08},
			text = "8% faster on your feet."},
		{id = "EagleEye", class = "Archer", name = "Eagle Eye", look = {kind = "relic", relic = "EagleFeather"}, mods = {draw = 0.85},
			text = "You draw your bow 15% quicker."},
		{id = "Deadeye", class = "Archer", name = "Deadeye", look = {kind = "treasure", treasure = "Sapphire"}, mods = {dealt = 1.1},
			text = "10% more damage with everything."},
		{id = "ArcaneFlow", class = "Mage", name = "Arcane Flow", look = {kind = "relic", relic = "ManaPearl"}, mods = {cast = 0.85},
			text = "Your spells come 15% quicker."},
		{id = "WardWise", class = "Mage", name = "Ward-Wise", look = {kind = "relic", relic = "FrostShard"}, mods = {taken = 0.92},
			text = "8% less damage taken."},
	},
}
