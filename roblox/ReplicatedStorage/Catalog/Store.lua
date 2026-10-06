--[[ STORE — the daily rotation of packs (Valorant-style: a few packs on sale
     at a time, the rest wait their turn or never come back). Config only.
       slots      how many packs are on sale each day
       queue      the order packs come up, as pack keys (Catalog ▸ Packs). Each
                  day the window of `slots` packs slides forward through this
                  list and wraps; edit the order to decide what comes next.
       pins       a lineup for a specific UTC date ("YYYY-MM-DD" = {pack, …}):
                  overrides the queue that day (holiday drops, launches)
       retired    pack keys that never appear again (still owned if bought)
       always     pack keys that are on sale every day regardless of the window
       epoch      the UTC day the rotation counts from (any date; shifts the window)
     WEAPONS — the second shelf: single weapon skins on sale today.
       skinSlots    how many skin offers a day (the first is a big Epic /
                    Legendary headliner when there is one)
       skinPins     a lineup for a UTC date ("YYYY-MM-DD" = {"Longsword:Duelist", …})
       skinRetired  skin ids that never come back
     The pool is every priced skin with no crate, pack or unlock (Catalog ▸
     Skins); everyone sees the same offers, drawn by the date.
     The server decides the day; Economy only sells pieces / packs / skins
     that are on sale today, always, or free. ]]
return {
	slots = 3,
	epoch = "2026-10-05",
	queue = {
		"IronCrow", "RoadLevy", "Sellswords",
		"MarshWardens", "TourneyKnight", "RiverGuard",
		"CoastHarriers", "GildedCourt", "Blackguard",
		"NightHunters", "WolfCompany", "SunKnights",
	},
	pins = {
		-- ["2026-10-31"] = {"NightHunters", "Blackguard", "WolfCompany"},
	},
	retired = {},
	always = {},

	skinSlots = 4,
	skinPins = {
		-- ["2026-10-31"] = {"Zweihander:Nightfall", "Spear:Thornguard", "Mace:Hunter", "Rapier:Duelist"},
	},
	skinRetired = {},
}
