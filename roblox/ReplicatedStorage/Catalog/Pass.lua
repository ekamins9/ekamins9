--[[ SEASON PASS — tiers of rewards, climbed with pass XP: every round's XP
     counts, and every finished daily task adds `taskXP` (a weekly task, three
     times that). The FREE track is everyone's; the PREMIUM track opens when
     the pass is bought with Crowns, and covers the tiers already reached.
       season   the season's id: a new id starts everyone at tier 0 again
       name     shown on the PASS screen       ends   UTC date it closes (countdown)
       price    Crowns for the premium track   tierXP pass XP per tier
       taskXP   pass XP per finished daily task (weekly: x3)
       tiers    {free = reward, premium = reward}, a reward being
                {marks = n} · {crowns = n} · {skin = "Weapon:Name"} · {title = "…"}
                · {crate = "Royal"} (one free open of that crate)
                · {killfx = "ShadowRift"} · {emote = "WarCry"} (Catalog ▸ KillFX / Emotes)
     Rewards are granted when claimed (server-side). Skins named here are pass
     skins (Catalog ▸ Skins: pass = true), so nothing else sells them; the
     same goes for kill effects and emotes marked pass = true. ]]
return {
	season = "S1",
	name = "Season 1  ·  The Iron Crown",
	ends = "2026-11-17",
	price = 600,
	tierXP = 1000,
	taskXP = 400,
	tiers = {
		{free = {marks = 150},                    premium = {skin = "ArmingSword:Ironclad"}},
		{free = {marks = 150},                    premium = {crowns = 20}},
		{free = {crate = "Bladesmith"},           premium = {marks = 400}},
		{free = {marks = 200},                    premium = {skin = "Spear:Crownspike"}},
		{free = {skin = "Shortsword:Iron Oath"},  premium = {crate = "Royal"}},
		{free = {marks = 200},                    premium = {marks = 500}},
		{free = {crowns = 10},                    premium = {skin = "WarAxe:Ironbark"}},
		{free = {marks = 250},                    premium = {killfx = "ShadowRift"}},
		{free = {crate = "Hafted"},               premium = {marks = 600}},
		{free = {marks = 250},                    premium = {skin = "Longsword:Crownguard"}},
		{free = {marks = 250},                    premium = {crate = "Royal"}},
		{free = {emote = "WarCry"},               premium = {marks = 700}},
		{free = {marks = 300},                    premium = {skin = "Mace:Iron Lion"}},
		{free = {crate = "Bladesmith"},           premium = {crowns = 40}},
		{free = {skin = "Pitchfork:Iron Tines"},  premium = {marks = 800}},
		{free = {marks = 300},                    premium = {crate = "Royal"}},
		{free = {marks = 350},                    premium = {skin = "Halberd:Kingsguard"}},
		{free = {crowns = 15},                    premium = {emote = "Windmill"}},
		{free = {crate = "Hafted"},               premium = {marks = 900}},
		{free = {title = "Ironsworn"},            premium = {skin = "Greatsword:Last Light"}},
		{free = {marks = 400},                    premium = {crate = "Royal"}},
		{free = {marks = 400},                    premium = {marks = 1000}},
		{free = {crowns = 20},                    premium = {skin = "Maul:Anvil of Kings"}},
		{free = {crate = "Bladesmith"},           premium = {crowns = 60}},
		{free = {skin = "Dagger:Crown's Fang"},   premium = {crate = "Royal"}},
		{free = {marks = 500},                    premium = {marks = 1200}},
		{free = {marks = 500},                    premium = {crowns = 80}},
		{free = {crowns = 25},                    premium = {killfx = "RoyalDecree"}},
		{free = {crate = "Royal"},                premium = {title = "Crowned"}},
		{free = {marks = 1000},                   premium = {skin = "Zweihander:The Iron Crown"}},
	},
}
