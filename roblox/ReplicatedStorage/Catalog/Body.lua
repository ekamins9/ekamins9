--[[ BODY — the person under the armor. Models for hair and beards go in
     Cosmetics ▸ Body ▸ Hair ▸ <id> and Cosmetics ▸ Body ▸ Beard ▸ <id>: a
     Model with a part named Middle the size of the Head (like a HeadClothing
     model) plus the hair parts around it; or an Accessory with a Handle and a
     HairAttachment / FaceFrontAttachment. An id with no model still works
     (nothing is shown) so you can list the catalog before the models exist.
       hair / beards   {id, name, crowns}   crowns = 0 is free
       faces           {id, name}  the texture is a Decal in Cosmetics ▸ Body ▸ Face ▸ <id>
                       (drawn by blender/faces.py); optional texture = an image id instead
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
		-- the second wave
		{id = "Spiky",       name = "Spiky"},
		{id = "Swoop",       name = "Swoop"},
		{id = "Curtains",    name = "Curtains"},
		{id = "Ponytail",    name = "Ponytail"},
		{id = "TwinTails",   name = "Twin tails"},
		{id = "ManBun",      name = "Man bun"},
		{id = "Afro",        name = "Afro"},
		{id = "Mohawk",      name = "Mohawk"},
		{id = "LongFlowing", name = "Long & flowing", crowns = 40},
		{id = "VikingBraids", name = "Viking braids", crowns = 40},
		{id = "Dreadlocks",  name = "Dreadlocks", crowns = 40},
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
	-- FACE PRESETS: a whole face in one click (the builder's parts below); the old single-texture
	-- faces (Cosmetics ▸ Body ▸ Face ▸ <id>) are only a fallback where no FaceParts exist
	faces = {
		{id = "Smile",     name = "Smile",      parts = {eyes = "Round", brows = "Soft", mouth = "Smile"}},
		{id = "Grin",      name = "Grin",       parts = {eyes = "Round", brows = "Raised", mouth = "Grin"}},
		{id = "Calm",      name = "Calm",       parts = {eyes = "Kind", brows = "Soft", mouth = "Smile"}},
		{id = "Happy",     name = "Happy",      parts = {eyes = "Happy", brows = "Raised", mouth = "Open"}},
		{id = "Cheeky",    name = "Cheeky",     parts = {eyes = "Wink", brows = "Raised", mouth = "Tongue", mark = "Blush"}},
		{id = "Smirk",     name = "Smirk",      parts = {eyes = "Determined", brows = "Soft", mouth = "Smirk"}},
		{id = "Stern",     name = "Stern",      parts = {eyes = "Narrow", brows = "Thick", mouth = "Flat"}},
		{id = "Weary",     name = "Weary",      parts = {eyes = "Sleepy", brows = "Worried", mouth = "Flat"}},
		{id = "Scarred",   name = "Scarred",    parts = {eyes = "Narrow", brows = "Scarred", mouth = "Flat", mark = "EyeScar"}},
		{id = "Fierce",    name = "Fierce",     parts = {eyes = "Fierce", brows = "Angry", mouth = "Toothy", paint = "Stripes"}},
		{id = "BattleCry", name = "Battle cry", parts = {eyes = "Fierce", brows = "Angry", mouth = "Shout"}},
		{id = "OneEyed",   name = "One-eyed",   parts = {eyes = "Round", brows = "Thick", mouth = "Smirk", mark = "Eyepatch"}},
		{id = "Warpaint",  name = "Warpaint",   parts = {eyes = "Determined", brows = "Angry", mouth = "Flat", paint = "Band"}},
	},
	-- THE FACE BUILDER: layers on the head, bottom to top: paint · mark · mouth · brows · eyes (and
	-- its iris, tinted with the eye colour, and its pupil). Decals in Cosmetics ▸ Body ▸ FaceParts ▸
	-- <layer>_<id> (drawn by blender/face_parts.py). Brows take the hair colour, paint the paint
	-- colour. crowns = premium, bought once. noIris = an eye shape with no iris (closed).
	faceParts = {
		eyes = {
			{id = "Round", name = "Round"}, {id = "Big", name = "Big"}, {id = "Kind", name = "Kind"}, {id = "Lashes", name = "Lashes"},
			{id = "Narrow", name = "Narrow"}, {id = "Determined", name = "Determined"}, {id = "Fierce", name = "Fierce"},
			{id = "Sleepy", name = "Sleepy"}, {id = "Wide", name = "Wide"}, {id = "Happy", name = "Happy", noIris = true}, {id = "Wink", name = "Wink"},
		},
		brows = {
			{id = "None", name = "None", none = true}, {id = "Soft", name = "Soft"}, {id = "Thick", name = "Thick"}, {id = "Thin", name = "Thin"},
			{id = "Angry", name = "Angry"}, {id = "Raised", name = "Raised"}, {id = "Worried", name = "Worried"},
			{id = "Scarred", name = "Scarred"}, {id = "Unibrow", name = "Unibrow"},
		},
		mouth = {
			{id = "Smile", name = "Smile"}, {id = "Grin", name = "Grin"}, {id = "Open", name = "Open"}, {id = "Smirk", name = "Smirk"},
			{id = "Flat", name = "Flat"}, {id = "Frown", name = "Frown"}, {id = "Shout", name = "Shout"}, {id = "Toothy", name = "Toothy"},
			{id = "Grimace", name = "Grimace"}, {id = "Tongue", name = "Tongue"}, {id = "Whistle", name = "Whistle"}, {id = "Fangs", name = "Fangs", crowns = 40},
		},
		mark = {
			{id = "None", name = "None", none = true}, {id = "Freckles", name = "Freckles"}, {id = "Blush", name = "Blush"}, {id = "Mole", name = "Mole"},
			{id = "CheekScar", name = "Cheek scar"}, {id = "EyeScar", name = "Eye scar"}, {id = "Stitches", name = "Stitches"},
			{id = "Bandage", name = "Bandage"}, {id = "Bruise", name = "Bruise"}, {id = "Eyepatch", name = "Eyepatch"},
		},
		paint = {
			{id = "None", name = "None", none = true}, {id = "Stripes", name = "Stripes"}, {id = "Band", name = "Band"}, {id = "Tears", name = "Tears"},
			{id = "Chevron", name = "Chevrons"}, {id = "Woad", name = "Woad", crowns = 40}, {id = "Skull", name = "Skull", crowns = 40}, {id = "Tribal", name = "Tribal", crowns = 40},
		},
	},
	eyeColors = {
		{name = "Brown",   color = Color3.fromRGB(92, 56, 30)},
		{name = "Hazel",   color = Color3.fromRGB(130, 100, 50)},
		{name = "Green",   color = Color3.fromRGB(60, 140, 70)},
		{name = "Blue",    color = Color3.fromRGB(60, 120, 220)},
		{name = "Grey",    color = Color3.fromRGB(130, 140, 150)},
		{name = "Amber",   color = Color3.fromRGB(220, 150, 40)},
		{name = "Violet",  color = Color3.fromRGB(150, 80, 220), crowns = 40},
		{name = "Crimson", color = Color3.fromRGB(210, 40, 40),  crowns = 40},
		{name = "Gold",    color = Color3.fromRGB(240, 200, 60), crowns = 40},
		{name = "Ice",     color = Color3.fromRGB(170, 230, 255), crowns = 40},
	},
	paintColors = {
		{name = "Red",    color = Color3.fromRGB(200, 30, 30)},
		{name = "Blue",   color = Color3.fromRGB(30, 90, 200)},
		{name = "Black",  color = Color3.fromRGB(26, 24, 30)},
		{name = "White",  color = Color3.fromRGB(240, 240, 240)},
		{name = "Ochre",  color = Color3.fromRGB(210, 150, 50)},
		{name = "Green",  color = Color3.fromRGB(50, 150, 70)},
		{name = "Purple", color = Color3.fromRGB(130, 60, 200)},
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
	defaults = {skin = 2, hair = "SweptBack", hairColor = "Brown", beard = "None", face = "Smile", title = "Recruit",
		eyes = "Round", eyeColor = "Brown", brows = "Soft", mouth = "Smile", mark = "None", paint = "None", paintColor = "Red"},
}
