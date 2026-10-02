--[[ WEAPONS — every Tool in ServerStorage ▸ Weapons that players may carry,
     and how it is unlocked. (Combat stats stay in the Tool's own Config.)
       id        the Tool's name
       name      shown in menus
       family    "OneHanded" | "TwoHanded" | "Polearm"   (kill counts and crates group by it)
       secondary true = may be carried as the secondary (the Tool's Config SECONDARY must also be true)
       unlock    {free = true} | {level = 5} | {kills = 40, family = "OneHanded"}
       marks     price to buy it outright instead of unlocking (0 = cannot be bought)
       weights   optional list of weights that may carry it, e.g. {"Heavy", "Medium"}; nil = any
     For the menu mannequin, put a visual copy in Cosmetics ▸ Weapons ▸ <id>
     (a Model with a part named Handle; the Tool's handle + blade parts work). ]]
return {
	{id = "Shortsword", name = "Shortsword",  family = "OneHanded", secondary = true,  unlock = {free = true}},
	{id = "Pitchfork",  name = "Pitchfork",   family = "Polearm",   secondary = false, unlock = {free = true}},
	{id = "Greatsword", name = "Greatsword",  family = "TwoHanded", secondary = false, unlock = {level = 5},  marks = 1500},
	{id = "Hammer",     name = "War Hammer",  family = "OneHanded", secondary = true,  unlock = {kills = 40, family = "OneHanded"}, marks = 1500},
}
