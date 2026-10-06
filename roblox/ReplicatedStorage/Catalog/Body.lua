--[[ BODY — the person under the armor. Models for hair, beards and faces go
     in Cosmetics ▸ Body ▸ Hair / Beard / Face ▸ <id>: a Model with a part named
     Middle the size of the Head (like a HeadClothing model) plus the parts
     around it; or an Accessory with a Handle and a HairAttachment /
     FaceFrontAttachment. Every id below has a built-in blueprint (Build ▸
     Body) that the server materializes when no hand-made model exists, so
     replace them one at a time whenever you like.
       hair / beards   {id, name, crowns}   crowns = 0 is free;  none = true shows nothing
       faces           {id, name, texture}  texture = a decal id ("rbxassetid://…") for the whole
                       face, or "" to keep the rig's face; a Face MODEL (Build ▸ Body) is an
                       overlay on top of it (brows, mouth, paint)
       skins           Color3 tones, free
       hairColors      {name, color, crowns}
       titles          free titles everyone has; others come from levels, ranks, sets
     Helmets hide hair when their covers list has "Hair", beard + face when it has "Face". ]]
return {
	hair = {
		{id = "Cropped",   name = "Cropped"},
		{id = "SweptBack", name = "Swept back"},
		{id = "LongTied",  name = "Long, tied"},
		{id = "Curly",     name = "Curly"},
		{id = "Braids",    name = "Braids"},
		{id = "Topknot",   name = "Topknot"},
		{id = "Tonsure",   name = "Tonsure"},
		{id = "Mohawk",    name = "Mohawk", crowns = 40},
		{id = "Bald",      name = "Bald", none = true},
	},
	beards = {
		{id = "None",     name = "None", none = true},
		{id = "Stubble",  name = "Stubble"},
		{id = "Goatee",   name = "Goatee"},
		{id = "Mustache", name = "Mustache"},
		{id = "Full",     name = "Full"},
		{id = "Braided",  name = "Braided", crowns = 40},
	},
	faces = {
		{id = "Calm",     name = "Calm",     texture = ""},
		{id = "Stern",    name = "Stern",    texture = ""},
		{id = "Grin",     name = "Grin",     texture = ""},
		{id = "Angry",    name = "Angry",    texture = ""},
		{id = "Cheeky",   name = "Cheeky",   texture = ""},
		{id = "Scarred",  name = "Scarred",  texture = ""},
		{id = "Warpaint", name = "Warpaint", texture = ""},
	},
	skins = {Color3.fromRGB(233, 201, 164), Color3.fromRGB(217, 180, 138), Color3.fromRGB(200, 154, 110), Color3.fromRGB(169, 123, 85), Color3.fromRGB(123, 82, 54), Color3.fromRGB(75, 50, 34)},
	hairColors = {
		{name = "Black",  color = Color3.fromRGB(42, 42, 42)},
		{name = "Brown",  color = Color3.fromRGB(58, 42, 26)},
		{name = "Auburn", color = Color3.fromRGB(122, 74, 26)},
		{name = "Blond",  color = Color3.fromRGB(200, 160, 96)},
		{name = "Grey",   color = Color3.fromRGB(138, 138, 138)},
		{name = "White",  color = Color3.fromRGB(232, 232, 232), crowns = 40},
		{name = "Red",    color = Color3.fromRGB(168, 58, 42),   crowns = 40},
	},
	titles = {"Recruit"},
	defaults = {skin = 2, hair = "SweptBack", hairColor = "Brown", beard = "None", face = "Calm", title = "Recruit"},
}
