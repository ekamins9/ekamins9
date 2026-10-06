--[[ EMOTES — played from the emote wheel (B, rebindable). Up to 6 equipped
     (ARMORY ▸ EMOTES). The motions live in ReplicatedStorage ▸ Emotes under the
     same id; a weapon in hand joins in (the Flourish spins it).
       id, name, rarity, description
     WHERE IT COMES FROM: free = true · crate = "Relic" · pass · unlock = {...} ]]
return {
	{id = "Salute",    name = "Salute",      rarity = "Common",    free = true,     description = "Blade to the brow."},
	{id = "Bow",       name = "Bow",         rarity = "Common",    free = true,     description = "A courteous bow before the bout."},
	{id = "Cheer",     name = "Cheer",       rarity = "Common",    free = true,     description = "Weapon to the sky."},
	{id = "Flourish",  name = "Flourish",    rarity = "Rare",      free = true,     description = "Two spins of the blade and a salute."},
	{id = "Wave",      name = "Wave",        rarity = "Common",    crate = "Relic", description = "Hello there."},
	{id = "Shrug",     name = "Shrug",       rarity = "Common",    crate = "Relic", description = "Could have gone either way."},
	{id = "Beckon",    name = "Beckon",      rarity = "Rare",      crate = "Relic", description = "Come on, then."},
	{id = "Kneel",     name = "Kneel",       rarity = "Rare",      crate = "Relic", description = "Take a knee, sword planted."},
	{id = "Laugh",     name = "Laugh",       rarity = "Rare",      crate = "Relic", description = "Doubled over. Was it that funny?"},
	{id = "Jig",       name = "Jig",         rarity = "Epic",      crate = "Relic", description = "A tavern jig, arms and legs flying."},
	{id = "WarCry",    name = "War Cry",     rarity = "Epic",      pass = true,     description = "Arms up, head back, a roar."},
	{id = "BladeToss", name = "Blade Toss",  rarity = "Epic",      crate = "Relic", description = "Toss the blade, let it spin, catch it."},
	{id = "Windmill",  name = "Windmill",    rarity = "Legendary", pass = true,     description = "The blade whirls overhead, faster and faster."},
	{id = "Champion",  name = "Champion",    rarity = "Legendary", crate = "Relic", description = "Plant the blade, rest on the pommel, look victorious."},
}
