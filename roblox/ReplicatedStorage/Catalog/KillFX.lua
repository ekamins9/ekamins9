--[[ KILL EFFECTS — what the body does when YOU land the killing blow. One
     equipped at a time (ARMORY ▸ KILL FX); looks only, never stats. The
     visuals live in ReplicatedStorage ▸ KillFX under the same id.
       id, name, rarity, description
       remains     what the effect leaves on the field (Combat ▸ Corpses): body ·
                   skeleton · ash (a charred skeleton in ash) · charred · gold (a
                   golden statue) · rubble · coins · confetti · shards · rift · light ·
                   none · grave · flat · stone · mound · puddle · garden · crater · bones
       remainsAt   seconds into the effect when the remains take the body's place
     WHERE IT COMES FROM: free = true · crate = "Relic" · pass (Catalog ▸ Pass
     names it) · unlock = {...} (earned). Nobody starts with one: a new player's
     kills are plain falls until they earn an effect. ]]
return {
	{id = "Shatter",       name = "Shatter",        rarity = "Common",    crate = "Relic", description = "The body bursts into blocks of its own colours.", remains = "rubble", remainsAt = 1.0},
	{id = "Confetti",      name = "Confetti Pop",   rarity = "Rare",      crate = "Relic", description = "A pop and a cloud of spinning confetti. Party's over.", remains = "confetti", remainsAt = 1.2},
	{id = "GoldRush",      name = "Gold Rush",      rarity = "Rare",      crate = "Relic", description = "Out spill the coins. They were worth it.", remains = "coins", remainsAt = 1.2},
	{id = "CrowSwarm",     name = "Crow Swarm",     rarity = "Epic",      crate = "Relic", description = "A burst of black feathers drifting down.", remains = "skeleton", remainsAt = 1.6},
	{id = "Inferno",       name = "Inferno",        rarity = "Epic",      crate = "Relic", description = "A column of fire; the body chars and crumbles.", remains = "ash", remainsAt = 1.9},
	{id = "Frozen",        name = "Frozen Solid",   rarity = "Epic",      crate = "Relic", description = "Encased in ice, then shattered to shards.", remains = "shards", remainsAt = 1.3},
	{id = "ShadowRift",    name = "Shadow Rift",    rarity = "Epic",      pass = true,     description = "A rift opens underfoot and swallows the fallen.", remains = "rift", remainsAt = 1.8},
	{id = "Thunderstrike", name = "Thunderstrike",  rarity = "Legendary", crate = "Relic", description = "A bolt from a clear sky. Nothing personal.", remains = "charred", remainsAt = 0.9},
	{id = "Ascension",     name = "Ascension",      rarity = "Legendary", crate = "Relic", description = "A pillar of light, wings, and gone.", remains = "light", remainsAt = 2.0},
	{id = "RoyalDecree",   name = "Royal Decree",   rarity = "Legendary", pass = true,     description = "Gold rays and a crown for the fallen. By order of the king.", remains = "gold", remainsAt = 1.9},

	-- THE GRIM CRATE: finishers from below and above
	{id = "Poof",          name = "Poof",              rarity = "Common",    crate = "Grim", description = "A puff of smoke and a few stars. Where'd they go?", remains = "none", remainsAt = 0.3},
	{id = "Tombstone",     name = "Tombstone",         rarity = "Common",    crate = "Grim", description = "The ground opens and a headstone rises over a fresh grave.", remains = "grave", remainsAt = 2.3},
	{id = "Anvil",         name = "Anvil Drop",        rarity = "Rare",      crate = "Grim", description = "A whistle, a shadow, an anvil. Flat.", remains = "flat", remainsAt = 0.7},
	{id = "Petrify",       name = "Petrify",           rarity = "Rare",      crate = "Grim", description = "Stone creeps up from the feet. A statue, cracked.", remains = "stone", remainsAt = 1.6},
	{id = "Quicksand",     name = "Quicksand",         rarity = "Rare",      crate = "Grim", description = "The ground turns to sand and swirls them under.", remains = "mound", remainsAt = 2.2},
	{id = "Kraken",        name = "Kraken's Grasp",    rarity = "Epic",      crate = "Grim", description = "Dark water underfoot. Arms reach up out of it and drag them down.", remains = "puddle", remainsAt = 2.4},
	{id = "Overgrown",     name = "Overgrown",         rarity = "Epic",      crate = "Grim", description = "Vines spiral up, leaves open, flowers bloom. Gone to seed.", remains = "garden", remainsAt = 2.45},
	{id = "Meteor",        name = "Meteor",            rarity = "Epic",      crate = "Grim", description = "A burning rock from a clear sky. Leaves a crater.", remains = "crater", remainsAt = 0.9},
	{id = "SerpentsMaw",   name = "Serpent's Maw",     rarity = "Legendary", crate = "Grim", description = "A great serpent bursts from the ground, swallows them whole, and spits out the bones.", remains = "bones", remainsAt = 3.1},
	{id = "HeavensHand",   name = "Hand of the Heavens", rarity = "Legendary", crate = "Grim", description = "The clouds part and a giant hand comes down. Flat.", remains = "flat", remainsAt = 1.8},
	{id = "BlackHole",     name = "Black Hole",        rarity = "Legendary", crate = "Grim", description = "A point of nothing opens at the chest. Everything goes in.", remains = "rift", remainsAt = 2.3},
}
