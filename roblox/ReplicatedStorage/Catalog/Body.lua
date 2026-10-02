--[[ BODY — the person under the armor. Models for hair and beards go in
     Cosmetics ▸ Body ▸ Hair ▸ <id> and Cosmetics ▸ Body ▸ Beard ▸ <id>: a
     Model with a part named Middle the size of the Head (like a HeadClothing
     model) plus the hair parts around it; or an Accessory with a Handle and a
     HairAttachment / FaceFrontAttachment. An id with no model still works
     (nothing is shown) so you can list the catalog before the models exist.
       hair / beards   {id, name, crowns}   crowns = 0 is free
       faces           {id, name, texture}  texture = a decal id ("rbxassetid://…") or "" to keep the rig's face
       skins           Color3 tones, free
       hairColors      {name, color, crowns}
       titles          free titles everyone has
       earnedTitles    {title, unlock} — unlock like Pieces: {level=} {kills=, family=} {wins=, bracket=} {stat=, n=}
     Helmets hide hair when their covers list has "Hair", beard + face when it has "Face". ]]
return {
	hair = {
		{id = "Cropped",     name = "Cropped"},
		{id = "SweptBack",   name = "Swept back"},
		{id = "LongTied",    name = "Long, tied"},
		{id = "Bald",        name = "Bald", none = true},
		{id = "BowlCut",     name = "Bowl cut"},
		{id = "Tonsure",     name = "Tonsure"},
		{id = "ShavedSides", name = "Shaved sides"},
		{id = "Topknot",     name = "Topknot"},
		{id = "WildMane",    name = "Wild mane", crowns = 40},
		{id = "BraidedCrown", name = "Braided crown", crowns = 40},
	},
	beards = {
		{id = "None",       name = "None", none = true},
		{id = "Stubble",    name = "Stubble"},
		{id = "Full",       name = "Full"},
		{id = "Goatee",     name = "Goatee"},
		{id = "MuttonChops", name = "Mutton chops"},
		{id = "Braided",    name = "Braided", crowns = 40},
		{id = "Forked",     name = "Forked", crowns = 40},
	},
	faces = {
		{id = "Stern",   name = "Stern",   texture = ""},
		{id = "Grin",    name = "Grin",    texture = ""},
		{id = "Scarred", name = "Scarred", texture = ""},
		{id = "Weary",   name = "Weary",   texture = ""},
		{id = "Fierce",  name = "Fierce",  texture = ""},
		{id = "OneEyed", name = "One-eyed", texture = ""},
	},
	skins = {Color3.fromRGB(233, 201, 164), Color3.fromRGB(217, 180, 138), Color3.fromRGB(200, 154, 110), Color3.fromRGB(169, 123, 85), Color3.fromRGB(123, 82, 54), Color3.fromRGB(75, 50, 34)},
	hairColors = {
		{name = "Black",    color = Color3.fromRGB(42, 42, 42)},
		{name = "Brown",    color = Color3.fromRGB(58, 42, 26)},
		{name = "Chestnut", color = Color3.fromRGB(96, 56, 30)},
		{name = "Auburn",   color = Color3.fromRGB(122, 74, 26)},
		{name = "Blond",    color = Color3.fromRGB(200, 160, 96)},
		{name = "Ashen",    color = Color3.fromRGB(168, 160, 140)},
		{name = "Grey",     color = Color3.fromRGB(138, 138, 138)},
		{name = "White",    color = Color3.fromRGB(232, 232, 232), crowns = 40},
		{name = "Red",      color = Color3.fromRGB(168, 58, 42),   crowns = 40},
		{name = "Copper",   color = Color3.fromRGB(190, 100, 50),  crowns = 40},
		{name = "Raven Blue", color = Color3.fromRGB(30, 36, 60),  crowns = 40},
	},
	titles = {"Recruit"},
	earnedTitles = {
		{title = "Levyman",               unlock = {level = 5}},
		{title = "Man-at-Arms",           unlock = {level = 10}},
		{title = "Veteran",               unlock = {level = 20}},
		{title = "Warlord",               unlock = {level = 35}},
		{title = "Swordsman",             unlock = {kills = 300, family = "OneHanded"}},
		{title = "Headsman",              unlock = {kills = 300, family = "TwoHanded"}},
		{title = "Pikeman",               unlock = {kills = 300, family = "Polearm"}},
		{title = "Butcher",               unlock = {kills = 500}},
		{title = "Unbroken",              unlock = {stat = "parry", n = 500}},
		{title = "Duelist",               unlock = {wins = 10, bracket = "1v1"}},
		{title = "Champion of the Lists", unlock = {wins = 50, bracket = "1v1"}},
		{title = "Drill Master",          unlock = {stat = "drill", n = 10}},
	},
	defaults = {skin = 2, hair = "SweptBack", hairColor = "Brown", beard = "None", face = "Stern", title = "Recruit"},
}
