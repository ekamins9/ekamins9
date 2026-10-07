--[[ KILL EFFECTS — what the body does when YOU land the killing blow. One
     equipped at a time (ARMORY ▸ KILL FX); looks only, never stats. The
     visuals live in ReplicatedStorage ▸ KillFX under the same id.
       id, name, rarity, description
       remains     what the effect leaves on the field (Combat ▸ Corpses): body ·
                   skeleton · ash (a charred skeleton in ash) · charred · gold (a
                   golden statue) · rubble · coins · confetti · shards · rift · light
       remainsAt   seconds into the effect when the remains take the body's place
     WHERE IT COMES FROM: free = true · crate = "Relic" · pass (Catalog ▸ Pass
     names it) · unlock = {...} (earned) ]]
return {
	{id = "Shatter",       name = "Shatter",        rarity = "Common",    free = true,     description = "The body bursts into blocks of its own colours.", remains = "rubble", remainsAt = 1.0},
	{id = "Confetti",      name = "Confetti Pop",   rarity = "Rare",      crate = "Relic", description = "A pop and a cloud of spinning confetti. Party's over.", remains = "confetti", remainsAt = 1.2},
	{id = "GoldRush",      name = "Gold Rush",      rarity = "Rare",      crate = "Relic", description = "Out spill the coins. They were worth it.", remains = "coins", remainsAt = 1.2},
	{id = "CrowSwarm",     name = "Crow Swarm",     rarity = "Epic",      crate = "Relic", description = "A burst of black feathers drifting down.", remains = "skeleton", remainsAt = 1.6},
	{id = "Inferno",       name = "Inferno",        rarity = "Epic",      crate = "Relic", description = "A column of fire; the body chars and crumbles.", remains = "ash", remainsAt = 1.9},
	{id = "Frozen",        name = "Frozen Solid",   rarity = "Epic",      crate = "Relic", description = "Encased in ice, then shattered to shards.", remains = "shards", remainsAt = 1.3},
	{id = "ShadowRift",    name = "Shadow Rift",    rarity = "Epic",      pass = true,     description = "A rift opens underfoot and swallows the fallen.", remains = "rift", remainsAt = 1.8},
	{id = "Thunderstrike", name = "Thunderstrike",  rarity = "Legendary", crate = "Relic", description = "A bolt from a clear sky. Nothing personal.", remains = "charred", remainsAt = 0.9},
	{id = "Ascension",     name = "Ascension",      rarity = "Legendary", crate = "Relic", description = "A pillar of light, wings, and gone.", remains = "light", remainsAt = 2.0},
	{id = "RoyalDecree",   name = "Royal Decree",   rarity = "Legendary", pass = true,     description = "Gold rays and a crown for the fallen. By order of the king.", remains = "gold", remainsAt = 1.9},
}
