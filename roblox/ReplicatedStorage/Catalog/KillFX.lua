--[[ KILL EFFECTS — what the body does when YOU land the killing blow. One
     equipped at a time (ARMORY ▸ KILL FX); looks only, never stats. The
     visuals live in ReplicatedStorage ▸ KillFX under the same id.
       id, name, rarity, description
     WHERE IT COMES FROM: free = true · crate = "Relic" · pass (Catalog ▸ Pass
     names it) · unlock = {...} (earned) ]]
return {
	{id = "Shatter",       name = "Shatter",        rarity = "Common",    free = true,     description = "The body bursts into blocks of its own colours."},
	{id = "Confetti",      name = "Confetti Pop",   rarity = "Rare",      crate = "Relic", description = "A pop and a cloud of spinning confetti. Party's over."},
	{id = "GoldRush",      name = "Gold Rush",      rarity = "Rare",      crate = "Relic", description = "Out spill the coins. They were worth it."},
	{id = "CrowSwarm",     name = "Crow Swarm",     rarity = "Epic",      crate = "Relic", description = "A burst of black feathers drifting down."},
	{id = "Inferno",       name = "Inferno",        rarity = "Epic",      crate = "Relic", description = "A column of fire; the body chars and crumbles."},
	{id = "Frozen",        name = "Frozen Solid",   rarity = "Epic",      crate = "Relic", description = "Encased in ice, then shattered to shards."},
	{id = "ShadowRift",    name = "Shadow Rift",    rarity = "Epic",      pass = true,     description = "A rift opens underfoot and swallows the fallen."},
	{id = "Thunderstrike", name = "Thunderstrike",  rarity = "Legendary", crate = "Relic", description = "A bolt from a clear sky. Nothing personal."},
	{id = "Ascension",     name = "Ascension",      rarity = "Legendary", crate = "Relic", description = "A pillar of light, wings, and gone."},
	{id = "RoyalDecree",   name = "Royal Decree",   rarity = "Legendary", pass = true,     description = "Gold rays and a crown for the fallen. By order of the king."},
}
