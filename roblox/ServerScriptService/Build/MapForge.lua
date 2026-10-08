--[[ MAP FORGE — themed maps from one line each: a LAYOUT (what stands where) in
     a THEME (time of day, season, weather, palette, trees), with a seed. Built
     like every other map (Build ▸ Maps):

       require(game.ServerScriptService.Build.Maps).build("Emberkeep")
       require(game.ServerScriptService.Build.Maps).buildForge()   -- all of them

     LAYOUTS
       arena     a walled ring with stands, two gates, a dais in the middle
       bailey    a castle courtyard: curtain walls, towers, two gatehouses, a keep
       village   houses round a market square, fences, a chapel, fields
       bridge    a fortified bridge over a river (or a dry gorge), a plank
                 crossing downstream, camps on both banks (DrownY below)
       ruins     a broken temple on its steps, fallen columns, broken walls
       clearing  a forest clearing round a stone circle, a woodcutter's hut
       siege     a castle to take (Siege): the ram up the road to the gate, the
                 bailey, the great hall, its champion on the throne
     Every map carries what every mode wants: team spawns A / B, free spawns,
     a KOTH hill (Zones ▸ Hill), Horde gates (Spots ▸ HordeGate1..8), three menu
     cameras, lighting and atmosphere, and its weather (an emitter in the map).
     A siege map also has Map ▸ Objectives and Side / Stage spawns.

     THEMES: summer autumn winter winterNight desert desertDusk swamp stormNight
     ember spring dawnMist ash nightForest. Weather: snow rain embers ash leaves
     petals fireflies dust mist. ]]

local F = {}
local V3 = Vector3.new
local DEG = math.rad
local RGB = Color3.fromRGB
local Mat = Enum.Material

--------------------------------------------------------------------
--  THEMES
--------------------------------------------------------------------
F.THEMES = {
	summer = {
		ground = Mat.Grass, groundColor = RGB(92, 142, 62), path = Mat.Ground, pathColor = RGB(124, 100, 72), cliff = Mat.Rock, cliffColor = RGB(118, 114, 104),
		stone = RGB(168, 164, 154), stoneDark = RGB(118, 114, 106), stoneMat = Mat.Slate, floor = Mat.Cobblestone, floorColor = RGB(140, 136, 128),
		wood = RGB(124, 86, 52), woodDark = RGB(84, 58, 34), roof = RGB(152, 64, 46), plaster = RGB(232, 224, 204),
		tree = "oak", leaf = RGB(74, 134, 58), leaf2 = RGB(56, 110, 48), trees = 34,
		house = RGB(40, 110, 70), house2 = RGB(232, 210, 120), tent = RGB(196, 176, 140),
		light = {ClockTime = 13.2, Brightness = 2.4, OutdoorAmbient = RGB(150, 150, 140), Ambient = RGB(90, 90, 86), FogEnd = 900, FogColor = RGB(200, 215, 230), ColorShift_Top = RGB(255, 244, 224)},
		atmo = {Density = 0.28, Offset = 0.1, Color = RGB(199, 210, 226), Decay = RGB(106, 112, 125), Glare = 0.2, Haze = 1},
	},
	autumn = {
		ground = Mat.Grass, groundColor = RGB(150, 124, 62), path = Mat.Ground, pathColor = RGB(120, 92, 64), cliff = Mat.Rock, cliffColor = RGB(120, 108, 96),
		stone = RGB(170, 156, 136), stoneDark = RGB(120, 106, 90), stoneMat = Mat.Slate, floor = Mat.Cobblestone, floorColor = RGB(138, 124, 108),
		wood = RGB(120, 80, 48), woodDark = RGB(78, 52, 32), roof = RGB(120, 52, 38), plaster = RGB(226, 210, 180),
		tree = "oak", leaf = RGB(206, 96, 34), leaf2 = RGB(232, 156, 42), leaf3 = RGB(150, 52, 30), trees = 34,
		house = RGB(130, 40, 36), house2 = RGB(236, 196, 96), tent = RGB(176, 140, 100),
		light = {ClockTime = 17.0, Brightness = 2, OutdoorAmbient = RGB(160, 130, 100), Ambient = RGB(92, 74, 60), FogEnd = 800, FogColor = RGB(220, 170, 120), ColorShift_Top = RGB(255, 190, 120)},
		atmo = {Density = 0.32, Offset = 0.12, Color = RGB(230, 190, 150), Decay = RGB(140, 100, 80), Glare = 0.3, Haze = 1.6},
		weather = "leaves",
	},
	winter = {
		ground = Mat.Snow, groundColor = RGB(238, 242, 250), path = Mat.Ground, pathColor = RGB(112, 98, 86), cliff = Mat.Rock, cliffColor = RGB(96, 102, 114),
		stone = RGB(150, 156, 166), stoneDark = RGB(104, 110, 122), stoneMat = Mat.Slate, floor = Mat.Cobblestone, floorColor = RGB(128, 128, 132),
		wood = RGB(110, 78, 50), woodDark = RGB(70, 50, 34), roof = RGB(70, 56, 46), plaster = RGB(214, 214, 220),
		tree = "pine", leaf = RGB(40, 70, 52), leaf2 = RGB(52, 86, 62), trees = 30, snow = true,
		house = RGB(46, 62, 92), house2 = RGB(214, 220, 230), tent = RGB(176, 150, 112),
		light = {ClockTime = 14.2, Brightness = 1.7, OutdoorAmbient = RGB(160, 170, 190), Ambient = RGB(96, 104, 120), FogEnd = 600, FogColor = RGB(206, 214, 228), ColorShift_Top = RGB(196, 210, 236)},
		atmo = {Density = 0.4, Offset = 0.1, Color = RGB(210, 220, 235), Decay = RGB(150, 160, 180), Glare = 0.1, Haze = 2},
		weather = "snow",
	},
	winterNight = {
		ground = Mat.Snow, groundColor = RGB(214, 224, 244), path = Mat.Ground, pathColor = RGB(92, 84, 80), cliff = Mat.Rock, cliffColor = RGB(80, 88, 104),
		stone = RGB(132, 140, 156), stoneDark = RGB(90, 96, 112), stoneMat = Mat.Slate, floor = Mat.Cobblestone, floorColor = RGB(110, 112, 122),
		wood = RGB(100, 72, 48), woodDark = RGB(62, 44, 30), roof = RGB(56, 46, 42), plaster = RGB(190, 194, 206),
		tree = "pine", leaf = RGB(30, 56, 46), leaf2 = RGB(40, 70, 56), trees = 30, snow = true, night = true,
		house = RGB(120, 30, 40), house2 = RGB(220, 200, 150), tent = RGB(150, 128, 100),
		light = {ClockTime = 0.4, Brightness = 1.2, ExposureCompensation = 0.35, OutdoorAmbient = RGB(100, 114, 156), Ambient = RGB(60, 70, 98), FogEnd = 500, FogColor = RGB(40, 50, 80), ColorShift_Top = RGB(150, 170, 230)},
		atmo = {Density = 0.38, Offset = 0.1, Color = RGB(70, 84, 124), Decay = RGB(30, 36, 60), Glare = 0, Haze = 1.4},
		weather = "snow",
	},
	desert = {
		ground = Mat.Sand, groundColor = RGB(222, 190, 130), path = Mat.Sandstone, pathColor = RGB(196, 160, 110), cliff = Mat.Sandstone, cliffColor = RGB(184, 142, 98),
		stone = RGB(216, 190, 140), stoneDark = RGB(176, 148, 104), stoneMat = Mat.Sandstone, floor = Mat.Sandstone, floorColor = RGB(200, 170, 120),
		wood = RGB(140, 100, 62), woodDark = RGB(96, 66, 40), roof = RGB(176, 82, 52), plaster = RGB(232, 216, 184),
		tree = "palm", leaf = RGB(92, 142, 64), leaf2 = RGB(70, 120, 52), trees = 14, flatTowers = true,
		house = RGB(176, 42, 42), house2 = RGB(236, 200, 90), tent = RGB(220, 196, 150),
		light = {ClockTime = 12.6, Brightness = 3, OutdoorAmbient = RGB(170, 150, 120), Ambient = RGB(100, 90, 74), FogEnd = 800, FogColor = RGB(230, 210, 170), ColorShift_Top = RGB(255, 236, 200)},
		atmo = {Density = 0.3, Offset = 0.05, Color = RGB(230, 210, 170), Decay = RGB(180, 150, 110), Glare = 0.5, Haze = 2.2},
		weather = "dust",
	},
	desertDusk = {
		ground = Mat.Sand, groundColor = RGB(214, 170, 116), path = Mat.Sandstone, pathColor = RGB(180, 138, 96), cliff = Mat.Sandstone, cliffColor = RGB(168, 112, 80),
		stone = RGB(206, 168, 124), stoneDark = RGB(160, 122, 88), stoneMat = Mat.Sandstone, floor = Mat.Sandstone, floorColor = RGB(184, 146, 104),
		wood = RGB(130, 88, 56), woodDark = RGB(86, 56, 36), roof = RGB(150, 64, 44), plaster = RGB(224, 196, 160),
		tree = "palm", leaf = RGB(84, 120, 60), leaf2 = RGB(66, 100, 48), trees = 12, flatTowers = true,
		house = RGB(60, 70, 150), house2 = RGB(236, 190, 90), tent = RGB(200, 160, 120),
		light = {ClockTime = 18.2, Brightness = 1.6, OutdoorAmbient = RGB(170, 110, 90), Ambient = RGB(96, 60, 52), FogEnd = 700, FogColor = RGB(220, 140, 100), ColorShift_Top = RGB(255, 150, 90)},
		atmo = {Density = 0.34, Offset = 0.05, Color = RGB(240, 160, 110), Decay = RGB(120, 60, 60), Glare = 1, Haze = 2.4},
		weather = "dust",
	},
	swamp = {
		ground = Mat.Mud, groundColor = RGB(76, 74, 52), path = Mat.Mud, pathColor = RGB(66, 58, 44), cliff = Mat.Rock, cliffColor = RGB(80, 84, 74),
		accent = Mat.LeafyGrass, accentColor = RGB(78, 96, 52),
		stone = RGB(120, 124, 110), stoneDark = RGB(84, 88, 78), stoneMat = Mat.Cobblestone, floor = Mat.Ground, floorColor = RGB(92, 84, 66),
		wood = RGB(90, 68, 46), woodDark = RGB(56, 42, 30), roof = RGB(62, 72, 52), plaster = RGB(160, 156, 132),
		tree = "willow", leaf = RGB(70, 92, 50), leaf2 = RGB(56, 74, 42), trees = 30, puddles = true,
		house = RGB(70, 90, 60), house2 = RGB(190, 180, 120), tent = RGB(120, 110, 80),
		light = {ClockTime = 7.4, Brightness = 1.2, OutdoorAmbient = RGB(110, 124, 100), Ambient = RGB(70, 80, 64), FogEnd = 400, FogColor = RGB(130, 150, 120), ColorShift_Top = RGB(200, 220, 180)},
		atmo = {Density = 0.42, Offset = 0.25, Color = RGB(150, 170, 140), Decay = RGB(90, 110, 90), Glare = 0, Haze = 2.2},
		weather = "mist",
	},
	stormNight = {
		ground = Mat.Grass, groundColor = RGB(58, 82, 50), path = Mat.Mud, pathColor = RGB(70, 60, 46), cliff = Mat.Rock, cliffColor = RGB(70, 72, 78),
		stone = RGB(116, 118, 124), stoneDark = RGB(80, 82, 90), stoneMat = Mat.Slate, floor = Mat.Cobblestone, floorColor = RGB(90, 92, 98),
		wood = RGB(96, 68, 44), woodDark = RGB(58, 42, 28), roof = RGB(56, 60, 70), plaster = RGB(170, 168, 160),
		tree = "pine", leaf = RGB(34, 58, 40), leaf2 = RGB(44, 70, 48), trees = 30, night = true, puddles = true,
		house = RGB(40, 40, 46), house2 = RGB(200, 60, 50), tent = RGB(110, 100, 86),
		light = {ClockTime = 21.6, Brightness = 1.3, ExposureCompensation = 0.55, OutdoorAmbient = RGB(112, 120, 146), Ambient = RGB(70, 76, 94), FogEnd = 500, FogColor = RGB(40, 46, 60), ColorShift_Top = RGB(120, 140, 180)},
		atmo = {Density = 0.38, Offset = 0.1, Color = RGB(90, 100, 124), Decay = RGB(46, 50, 64), Glare = 0, Haze = 2},
		weather = "rain",
	},
	ember = {
		ground = Mat.Basalt, groundColor = RGB(56, 46, 44), path = Mat.Ground, pathColor = RGB(74, 58, 50), cliff = Mat.Basalt, cliffColor = RGB(44, 38, 38),
		accent = Mat.CrackedLava, accentColor = RGB(255, 96, 34),
		stone = RGB(74, 64, 62), stoneDark = RGB(44, 38, 38), stoneMat = Mat.Basalt, floor = Mat.Basalt, floorColor = RGB(64, 54, 50),
		wood = RGB(70, 46, 34), woodDark = RGB(40, 28, 22), roof = RGB(110, 30, 26), plaster = RGB(120, 100, 90),
		tree = "dead", leaf = RGB(40, 30, 26), leaf2 = RGB(30, 24, 20), trees = 22, night = true,
		house = RGB(150, 30, 26), house2 = RGB(240, 150, 50), tent = RGB(110, 80, 60),
		light = {ClockTime = 19.6, Brightness = 2, ExposureCompensation = 0.25, OutdoorAmbient = RGB(176, 100, 80), Ambient = RGB(100, 54, 42), FogEnd = 600, FogColor = RGB(90, 40, 30), ColorShift_Top = RGB(255, 110, 60)},
		atmo = {Density = 0.45, Offset = 0.1, Color = RGB(200, 90, 60), Decay = RGB(90, 30, 20), Glare = 0.6, Haze = 2.4},
		weather = "embers",
	},
	spring = {
		ground = Mat.Grass, groundColor = RGB(112, 172, 72), path = Mat.Ground, pathColor = RGB(132, 108, 78), cliff = Mat.Rock, cliffColor = RGB(128, 124, 114),
		stone = RGB(190, 184, 172), stoneDark = RGB(136, 130, 120), stoneMat = Mat.Limestone, floor = Mat.Cobblestone, floorColor = RGB(160, 154, 142),
		wood = RGB(130, 92, 58), woodDark = RGB(88, 62, 38), roof = RGB(170, 92, 62), plaster = RGB(242, 234, 216),
		tree = "blossom", leaf = RGB(244, 172, 204), leaf2 = RGB(252, 214, 228), trees = 30,
		house = RGB(120, 70, 160), house2 = RGB(250, 230, 140), tent = RGB(224, 214, 190),
		light = {ClockTime = 9.0, Brightness = 2.4, OutdoorAmbient = RGB(160, 160, 150), Ambient = RGB(96, 96, 92), FogEnd = 900, FogColor = RGB(220, 225, 235), ColorShift_Top = RGB(255, 240, 230)},
		atmo = {Density = 0.25, Offset = 0.1, Color = RGB(220, 220, 235), Decay = RGB(120, 130, 150), Glare = 0.2, Haze = 0.8},
		weather = "petals",
	},
	dawnMist = {
		ground = Mat.Grass, groundColor = RGB(96, 140, 80), path = Mat.Ground, pathColor = RGB(118, 100, 80), cliff = Mat.Rock, cliffColor = RGB(124, 120, 120),
		stone = RGB(176, 172, 170), stoneDark = RGB(124, 120, 120), stoneMat = Mat.Slate, floor = Mat.Cobblestone, floorColor = RGB(146, 142, 140),
		wood = RGB(120, 86, 56), woodDark = RGB(80, 58, 38), roof = RGB(96, 70, 80), plaster = RGB(226, 220, 214),
		tree = "birch", leaf = RGB(150, 176, 80), leaf2 = RGB(120, 156, 66), trees = 32,
		house = RGB(60, 90, 140), house2 = RGB(230, 220, 200), tent = RGB(200, 190, 176),
		light = {ClockTime = 6.4, Brightness = 1.6, OutdoorAmbient = RGB(150, 140, 150), Ambient = RGB(90, 84, 92), FogEnd = 500, FogColor = RGB(220, 200, 210), ColorShift_Top = RGB(255, 190, 170)},
		atmo = {Density = 0.42, Offset = 0.2, Color = RGB(230, 210, 220), Decay = RGB(150, 130, 150), Glare = 0.4, Haze = 2.2},
		weather = "mist",
	},
	ash = {
		ground = Mat.Ground, groundColor = RGB(92, 88, 84), path = Mat.Ground, pathColor = RGB(70, 66, 62), cliff = Mat.Rock, cliffColor = RGB(84, 82, 80),
		stone = RGB(130, 126, 120), stoneDark = RGB(90, 86, 82), stoneMat = Mat.Slate, floor = Mat.Cobblestone, floorColor = RGB(100, 96, 92),
		wood = RGB(70, 54, 42), woodDark = RGB(40, 32, 26), roof = RGB(60, 56, 52), plaster = RGB(150, 144, 136),
		tree = "dead", leaf = RGB(50, 44, 40), leaf2 = RGB(40, 36, 32), trees = 22, burnt = true,
		house = RGB(90, 30, 30), house2 = RGB(180, 160, 120), tent = RGB(110, 100, 90),
		light = {ClockTime = 16.2, Brightness = 1.3, OutdoorAmbient = RGB(130, 120, 110), Ambient = RGB(76, 70, 64), FogEnd = 500, FogColor = RGB(120, 110, 100), ColorShift_Top = RGB(230, 180, 140)},
		atmo = {Density = 0.5, Offset = 0.1, Color = RGB(150, 140, 130), Decay = RGB(90, 80, 70), Glare = 0.2, Haze = 3},
		weather = "ash",
	},
	nightForest = {
		ground = Mat.LeafyGrass, groundColor = RGB(52, 82, 46), path = Mat.Ground, pathColor = RGB(80, 66, 50), cliff = Mat.Rock, cliffColor = RGB(70, 74, 72),
		stone = RGB(120, 126, 124), stoneDark = RGB(80, 86, 84), stoneMat = Mat.Slate, floor = Mat.Ground, floorColor = RGB(86, 74, 58),
		wood = RGB(96, 70, 46), woodDark = RGB(60, 44, 30), roof = RGB(56, 70, 52), plaster = RGB(170, 170, 156),
		tree = "oak", leaf = RGB(40, 72, 44), leaf2 = RGB(30, 58, 36), trees = 44, night = true,
		house = RGB(40, 80, 60), house2 = RGB(200, 210, 140), tent = RGB(120, 110, 90),
		light = {ClockTime = 21.2, Brightness = 1.2, ExposureCompensation = 0.35, OutdoorAmbient = RGB(90, 112, 124), Ambient = RGB(52, 66, 76), FogEnd = 450, FogColor = RGB(30, 44, 50), ColorShift_Top = RGB(120, 150, 190)},
		atmo = {Density = 0.4, Offset = 0.1, Color = RGB(60, 80, 90), Decay = RGB(30, 40, 46), Glare = 0, Haze = 1.8},
		weather = "fireflies",
	},
}

--------------------------------------------------------------------
--  THE MAPS (name → layout, theme, seed, and a siege's champion)
--------------------------------------------------------------------
F.MAPS = {
	-- SIEGE
	Emberkeep   = {title = "Emberkeep",    layout = "siege", theme = "ember",       seed = 101, champion = {name = "The Cinder Lord", weapon = "Greatsword"}},
	Sunspire    = {title = "Sunspire",     layout = "siege", theme = "desert",      seed = 102, champion = {name = "The Sun Warden", weapon = "Halberd"}},
	Thornwall   = {title = "Thornwall",    layout = "siege", theme = "autumn",      seed = 103, champion = {name = "Lord Thorne", weapon = "Longsword"}},
	Mistmoor    = {title = "Mistmoor",     layout = "siege", theme = "swamp",       seed = 104, champion = {name = "The Bog King", weapon = "WarAxe"}},
	Greenhollow = {title = "Greenhollow",  layout = "siege", theme = "summer",      seed = 105, champion = {name = "Baron Ashby", weapon = "Mace"}},
	Stormhold   = {title = "Stormhold",    layout = "siege", theme = "stormNight",  seed = 106, champion = {name = "The Storm Marshal", weapon = "Glaive"}},
	Ashenford   = {title = "Ashenford",    layout = "siege", theme = "ash",         seed = 107, champion = {name = "The Ashen Knight", weapon = "BattleAxe"}},
	Rimeholt    = {title = "Rimeholt",     layout = "siege", theme = "winterNight", seed = 108, champion = {name = "Queen Ylva", weapon = "Spear"}},
	Blossomgate = {title = "Blossomgate",  layout = "siege", theme = "spring",      seed = 109, champion = {name = "Prince Aurel", weapon = "Messer"}},
	-- ARENAS
	Bloodpit    = {title = "The Bloodpit", layout = "arena", theme = "ember",       seed = 201},
	Moonring    = {title = "Moonring",     layout = "arena", theme = "winterNight", seed = 202},
	Dustbowl    = {title = "The Dustbowl", layout = "arena", theme = "desertDusk",  seed = 203},
	Thornpit    = {title = "Thornpit",     layout = "arena", theme = "autumn",      seed = 204},
	Mirepit     = {title = "Mirepit",      layout = "arena", theme = "swamp",       seed = 205},
	-- CASTLE COURTYARDS
	Abbeyfield  = {title = "Abbeyfield",   layout = "bailey", theme = "autumn",     seed = 301},
	Blackwater  = {title = "Blackwater",   layout = "bailey", theme = "stormNight", seed = 302},
	-- VILLAGES
	Harvestvale = {title = "Harvestvale",  layout = "village", theme = "summer",    seed = 401},
	Frosthollow = {title = "Frosthollow",  layout = "village", theme = "winter",    seed = 402},
	Marshfen    = {title = "Marshfen",     layout = "village", theme = "swamp",     seed = 403},
	-- BRIDGES
	Redgorge    = {title = "Redgorge",     layout = "bridge", theme = "desertDusk", seed = 501, dry = true},
	Mistbridge  = {title = "Mistbridge",   layout = "bridge", theme = "dawnMist",   seed = 502},
	-- RUINS
	Cinderfall  = {title = "Cinderfall",   layout = "ruins", theme = "ash",         seed = 601},
	Duneshrine  = {title = "Duneshrine",   layout = "ruins", theme = "desert",      seed = 602},
	-- CLEARINGS
	HollowGrove = {title = "Hollow Grove", layout = "clearing", theme = "nightForest", seed = 701},
	Pinewatch   = {title = "Pinewatch",    layout = "clearing", theme = "winter",   seed = 702},
}
F.ORDER = {"Emberkeep", "Sunspire", "Thornwall", "Mistmoor", "Greenhollow", "Stormhold", "Ashenford", "Rimeholt", "Blossomgate",
	"Bloodpit", "Moonring", "Dustbowl", "Thornpit", "Mirepit", "Abbeyfield", "Blackwater", "Harvestvale", "Frosthollow", "Marshfen",
	"Redgorge", "Mistbridge", "Cinderfall", "Duneshrine", "HollowGrove", "Pinewatch"}

--------------------------------------------------------------------
--  SHARED PIECES
--------------------------------------------------------------------
local K, C, M   -- set by build

-- terrain: the theme's ground, a rough ring of hills past `edge`, then `extra(brush)`
local function ground(ctx, T, r, edge, extra)
	K.terrain(ctx, V3(-208, -64, -208), V3(416, 160, 416), function(B)
		B:FillBlock(CFrame.new(0, -6, 0), V3(408, 12, 408), T.ground)
		for i = 1, 34 do
			local a = i / 34 * 2 * math.pi
			local d = edge + 26 + r:NextNumber(0, 16)
			B:FillBall(V3(math.cos(a) * d, -10 + r:NextNumber(0, 10), math.sin(a) * d), r:NextNumber(24, 34), T.cliff)
		end
		if T.accent then
			for i = 1, 14 do
				local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(30, edge - 8)
				B:FillBlock(CFrame.new(math.cos(a) * d, -1.6, math.sin(a) * d) * CFrame.Angles(0, a, 0), V3(r:NextNumber(6, 14), 2, r:NextNumber(4, 10)), T.accent)
			end
		end
		if T.puddles then
			for i = 1, 8 do
				local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(30, edge - 10)
				B:FillBlock(CFrame.new(math.cos(a) * d, -1.2, math.sin(a) * d), V3(r:NextNumber(6, 12), 1.6, r:NextNumber(6, 12)), Mat.Water)
			end
		end
		if extra then extra(B) end
	end)
	local colors = {[T.ground.Name] = T.groundColor, [T.path.Name] = T.pathColor, [T.cliff.Name] = T.cliffColor, [T.floor.Name] = T.floorColor}
	if T.accent then colors[T.accent.Name] = T.accentColor end
	K.terrainColors(ctx, colors)
end

-- invisible walls round the playable square (|x|, |z| ≤ e), tall
local function bounds(ctx, ex, ez)
	ez = ez or ex
	for _, w in ipairs({{V3(0, 40, -ez), V3(ex * 2 + 8, 80, 4)}, {V3(0, 40, ez), V3(ex * 2 + 8, 80, 4)}, {V3(-ex, 40, 0), V3(4, 80, ez * 2 + 8)}, {V3(ex, 40, 0), V3(4, 80, ez * 2 + 8)}}) do
		local p = K.box(ctx, "Bound", w[2], w[1], C.STONE, M.SmoothPlastic)
		p.Transparency, p.CanQuery, p.CanTouch, p.CastShadow = 1, false, false, false
	end
end

-- a thin cap of snow on a part's top (snow themes)
local function snowOn(ctx, T, p, inset)
	if not T.snow or not p then return end
	local s = K.box(ctx, "Snow", V3(math.max(0.4, p.Size.X - (inset or 0.1)), 0.25, math.max(0.4, p.Size.Z - (inset or 0.1))), p.CFrame * CFrame.new(0, p.Size.Y / 2 + 0.12, 0), T.groundColor, M.Snow)
	s.CanCollide = false
end

-- a tree in the theme's style
local function tree(ctx, T, pos, h, r)
	local style = T.tree
	local P = ctx.Props
	if style == "pine" then
		K.cyl(ctx, "Trunk", 1, h * 0.3, pos + V3(0, h * 0.15, 0), T.woodDark, M.Wood, P)
		for i = 0, 2 do
			local rad = h * (0.3 - i * 0.075)
			local y = h * (0.22 + i * 0.22)
			K.cone(ctx, "Leaves", pos + V3(0, y, 0), rad, h * 0.34, i == 0 and T.leaf or T.leaf2, M.Grass, P, true, 8)
			if T.snow then K.cone(ctx, "SnowCap", pos + V3(0, y + h * 0.18, 0), rad * 0.62, h * 0.17, T.groundColor, M.Snow, P, true, 8) end
		end
	elseif style == "palm" then
		local lean = r:NextNumber(-12, 12)
		local top = pos
		for i = 0, 4 do
			local seg = CFrame.new(top) * CFrame.Angles(0, 0, DEG(lean * (i / 4)))
			local s = K.cyl(ctx, "Trunk", 1.1 - i * 0.08, h * 0.2, seg * CFrame.new(0, h * 0.1, 0), T.wood, M.Wood, P)
			top = (seg * CFrame.new(0, h * 0.2, 0)).Position
		end
		for i = 0, 6 do
			local a = i / 7 * 2 * math.pi
			local fr = K.wedge(ctx, "Frond", V3(0.3, 1.2, h * 0.42), CFrame.new(top) * CFrame.Angles(0, a, 0) * CFrame.Angles(DEG(28), 0, 0) * CFrame.new(0, 0, -h * 0.2), i % 2 == 0 and T.leaf or T.leaf2, M.Grass, P)
			fr.CanCollide = false
		end
		K.ball(ctx, "Coconut", 1.2, top + V3(0, -0.6, 0), T.woodDark, M.Wood, P).CanCollide = false
	elseif style == "dead" or style == "willow" then
		K.cyl(ctx, "Trunk", 1.3, h * 0.6, pos + V3(0, h * 0.3, 0), T.woodDark, M.Wood, P)
		for i = 1, 4 do
			local a = r:NextNumber(0, 2 * math.pi)
			local br = K.cyl(ctx, "Branch", 0.5, h * 0.35, CFrame.new(pos + V3(0, h * (0.35 + i * 0.08), 0)) * CFrame.Angles(0, a, 0) * CFrame.Angles(DEG(r:NextNumber(35, 60)), 0, 0) * CFrame.new(0, h * 0.17, 0), T.woodDark, M.Wood, P)
			br.CanCollide = false
			if style == "willow" then
				local tip = (br.CFrame * CFrame.new(h * 0.17, 0, 0)).Position
				local moss = K.box(ctx, "Moss", V3(0.3, h * 0.3, 1.6), CFrame.new(tip - V3(0, h * 0.15, 0)) * CFrame.Angles(0, a, 0), i % 2 == 0 and T.leaf or T.leaf2, M.Grass, P)
				moss.CanCollide = false
			end
		end
		if style == "willow" then K.ball(ctx, "Canopy", h * 0.5, pos + V3(0, h * 0.72, 0), T.leaf, M.Grass, P).CanCollide = false end
	else
		-- oak, blossom, birch: a trunk and a crown of leaf balls
		local trunk = style == "birch" and RGB(226, 224, 214) or T.woodDark
		K.cyl(ctx, "Trunk", style == "birch" and 0.9 or 1.4, h * 0.5, pos + V3(0, h * 0.25, 0), trunk, M.Wood, P)
		local crown = style == "birch" and 3 or 4
		for i = 1, crown do
			local off = V3(r:NextNumber(-h * 0.14, h * 0.14), r:NextNumber(-h * 0.06, h * 0.08), r:NextNumber(-h * 0.14, h * 0.14))
			local leafC = T.leaf3 and (i % 3 == 0 and T.leaf3 or (i % 2 == 0 and T.leaf2 or T.leaf)) or (i % 2 == 0 and T.leaf2 or T.leaf)
			K.ball(ctx, "Leaves", h * (style == "birch" and 0.32 or 0.42), pos + V3(0, h * 0.62, 0) + off, leafC, style == "blossom" and M.SmoothPlastic or M.Grass, P).CanCollide = false
		end
	end
end

-- trees scattered between radius a and b, kept out of the boxes in `keep` ({center, halfSize})
local function forest(ctx, T, r, n, a, b, keep)
	local placed = 0
	for _ = 1, n * 4 do
		if placed >= n then break end
		local ang, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(a, b)
		local p = V3(math.cos(ang) * d, 0, math.sin(ang) * d)
		local ok = true
		for _, k in ipairs(keep or {}) do
			if math.abs(p.X - k[1].X) < k[2].X and math.abs(p.Z - k[1].Z) < k[2].Z then ok = false; break end
		end
		if ok then tree(ctx, T, p, r:NextNumber(14, 24), r); placed += 1 end
	end
end

-- the theme's weather: one emitter over the field (or at the ground, for what rises or drifts)
local WEATHER = {
	snow = {tex = "rbxasset://textures/particles/sparkles_main.dds", color = {RGB(255, 255, 255)}, size = 0.28, life = {9, 12}, speed = {6, 8}, rate = 260, high = true},
	rain = {tex = "rbxasset://textures/particles/sparkles_main.dds", color = {RGB(190, 205, 230)}, size = 0.18, life = {1.1, 1.3}, speed = {62, 70}, rate = 1100, high = true, streak = true},
	ash = {tex = "rbxasset://textures/particles/smoke_main.dds", color = {RGB(120, 116, 110), RGB(70, 66, 62)}, size = 0.35, life = {16, 20}, speed = {2.5, 3.5}, rate = 160, high = true, drift = V3(1.2, 0, 0.6)},
	leaves = {tex = "rbxasset://textures/particles/sparkles_main.dds", color = {RGB(214, 110, 40), RGB(236, 170, 50)}, size = 0.5, life = {14, 18}, speed = {3, 4.5}, rate = 70, high = true, drift = V3(2.2, 0, 1), spin = true},
	petals = {tex = "rbxasset://textures/particles/sparkles_main.dds", color = {RGB(255, 190, 214), RGB(255, 236, 244)}, size = 0.4, life = {14, 18}, speed = {2.5, 3.5}, rate = 70, high = true, drift = V3(1.6, 0, 0.8), spin = true},
	embers = {tex = "rbxasset://textures/particles/sparkles_main.dds", color = {RGB(255, 170, 60), RGB(255, 80, 30)}, size = 0.3, life = {6, 9}, speed = {3, 6}, rate = 110, glow = true, drift = V3(1, 0.6, 0.4)},
	fireflies = {tex = "rbxasset://textures/particles/sparkles_main.dds", color = {RGB(220, 255, 120)}, size = 0.3, life = {4, 7}, speed = {0.4, 1}, rate = 60, glow = true, spread = 180, low = 4},
	dust = {tex = "rbxasset://textures/particles/smoke_main.dds", color = {RGB(226, 196, 150)}, size = 5, life = {8, 12}, speed = {1, 2}, rate = 22, drift = V3(4, 0, 1.5), fade = 0.86, low = 2},
	mist = {tex = "rbxasset://textures/particles/smoke_main.dds", color = {RGB(230, 232, 236)}, size = 16, life = {14, 20}, speed = {0.3, 0.8}, rate = 16, drift = V3(0.6, 0, 0.3), fade = 0.9, low = 1},
}
local function weather(ctx, T, sx, sz)
	local w = T.weather and WEATHER[T.weather]
	if not w then return end
	local y = w.high and 70 or (w.low or 1.5)
	local holder = K.box(ctx, "Weather", V3(sx, 1, sz), V3(0, y, 0), C.WHITE, M.SmoothPlastic)
	holder.Transparency, holder.CanCollide, holder.CanQuery, holder.CanTouch, holder.CastShadow = 1, false, false, false, false
	local e = Instance.new("ParticleEmitter")
	e.Texture = w.tex
	e.Color = #w.color > 1 and ColorSequence.new(w.color[1], w.color[2]) or ColorSequence.new(w.color[1])
	e.Size = NumberSequence.new(w.size)
	local fade = w.fade or 0.2
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, w.high and fade or 1), NumberSequenceKeypoint.new(0.15, fade), NumberSequenceKeypoint.new(0.85, fade), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(w.life[1], w.life[2])
	e.Speed = NumberRange.new(w.speed[1], w.speed[2])
	e.EmissionDirection = w.high and Enum.NormalId.Bottom or Enum.NormalId.Top
	e.SpreadAngle = Vector2.new(w.spread or 14, w.spread or 14)
	e.Rate = w.rate
	e.Acceleration = w.drift or Vector3.zero
	e.LightInfluence = w.glow and 0 or 1
	e.LightEmission = w.glow and 1 or 0
	if w.streak then e.Orientation = Enum.ParticleOrientation.VelocityParallel; e.Squash = NumberSequence.new(-3) end
	if w.spin then e.Rotation = NumberRange.new(0, 360); e.RotSpeed = NumberRange.new(-120, 120) end
	e.Parent = holder
end

-- what every mode needs: spawns, the hill, Horde gates, cameras
-- o = {a = {pos...}, b = {pos...}, free = {pos...}, hill = {pos, r}, gates = {pos...}, cams = {{pos, look}...}}
local function markers(ctx, o)
	local mid = o.center or V3(0, 1, 0)
	for _, p in ipairs(o.a) do K.spawn(ctx, p, "A", V3(mid.X, p.Y, mid.Z)) end
	for _, p in ipairs(o.b) do K.spawn(ctx, p, "B", V3(mid.X, p.Y, mid.Z)) end
	for _, p in ipairs(o.free) do K.spawn(ctx, p, nil, V3(mid.X, p.Y, mid.Z)) end
	if o.hill then K.hill(ctx, o.hill[1], o.hill[2], 8) end
	for i, p in ipairs(o.gates or {}) do K.spot(ctx, "HordeGate" .. i, CFrame.lookAt(p, V3(mid.X, p.Y, mid.Z))) end
	for _, c in ipairs(o.cams) do K.camera(ctx, c[1], c[2]) end
end
local function ring(n, rad, y, phase)
	local out = {}
	for i = 1, n do
		local a = (i - 1) / n * 2 * math.pi + (phase or 0)
		table.insert(out, V3(math.cos(a) * rad, y or 1, math.sin(a) * rad))
	end
	return out
end
local function line(x0, x1, z, n, y)
	local out = {}
	for i = 0, n - 1 do table.insert(out, V3(x0 + (x1 - x0) * (n == 1 and 0.5 or i / (n - 1)), y or 1, z)) end
	return out
end
local function lineX(x, z0, z1, n, y)
	local out = {}
	for i = 0, n - 1 do table.insert(out, V3(x, y or 1, z0 + (z1 - z0) * (n == 1 and 0.5 or i / (n - 1)))) end
	return out
end

-- a campfire with a ring, logs, fire and a light
local function campfire(ctx, T, p)
	K.cyl(ctx, "FireRing", 4, 0.6, p + V3(0, 0.3, 0), T.stoneDark, M.Slate)
	local fire = K.box(ctx, "Campfire", V3(1.8, 0.8, 1.8), p + V3(0, 0.8, 0), RGB(255, 120, 40), M.Neon)
	fire.CanCollide = false
	local f = Instance.new("Fire"); f.Size = 3.5; f.Heat = 6; f.Parent = fire
	local l = Instance.new("PointLight"); l.Color = RGB(255, 150, 70); l.Range = 18; l.Brightness = 1.6; l.Parent = fire
	for k = 0, 3 do K.cyl(ctx, "Log", 0.7, 3, CFrame.new(p + V3(0, 0.4, 0)) * CFrame.Angles(0, DEG(k * 45), DEG(90)), T.woodDark, M.Wood).CanCollide = false end
end
-- lights: braziers on posts (more at night)
local function lamps(ctx, T, pts, h)
	for _, p in ipairs(pts) do K.torchPost(ctx, p, h or 6) end
end
-- scattered cover: crates, barrels, hay (not inside keep-out boxes)
local function clutter(ctx, T, r, n, a, b)
	for i = 1, n do
		local ang, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(a, b)
		local p = V3(math.cos(ang) * d, 0, math.sin(ang) * d)
		local k = i % 3
		if k == 0 then K.crate(ctx, p, 3, r:NextNumber(0, 90)) elseif k == 1 then K.barrel(ctx, p) else K.hay(ctx, p) end
	end
end
local function burntMarks(ctx, T, r, n, rad)
	if not T.burnt then return end
	for _ = 1, n do
		local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(10, rad)
		local s = K.cyl(ctx, "Scorch", r:NextNumber(5, 10), 0.1, V3(math.cos(a) * d, 0.06, math.sin(a) * d), RGB(30, 28, 26), M.SmoothPlastic)
		s.CanCollide = false
	end
end
local function finishLook(ctx, T)
	K.lighting(ctx, T.light)
	K.atmosphere(ctx, T.atmo)
end

--------------------------------------------------------------------
--  LAYOUT: ARENA — a walled ring, stands, two gates, a dais
--------------------------------------------------------------------
local function arena(ctx, T, r)
	local A = 46
	ground(ctx, T, r, 120, function(B)
		B:FillCylinder(CFrame.new(0, -2, 0), 4, A, T.path)   -- (a whole voxel row: a thinner fill writes nothing)
	end)
	local stone, dark, sm = T.stone, T.stoneDark, T.stoneMat
	local SEG = 28
	for i = 0, SEG - 1 do
		local a0, a1 = i / SEG * 2 * math.pi, (i + 1) / SEG * 2 * math.pi
		local am = (a0 + a1) / 2
		local gate = math.abs(math.cos(am)) < 0.12 and true or false    -- the gaps north and south
		if not gate then
			local p0, p1 = V3(math.cos(a0) * (A + 2), 0, math.sin(a0) * (A + 2)), V3(math.cos(a1) * (A + 2), 0, math.sin(a1) * (A + 2))
			K.wall(ctx, p0, p1, 7, 3, {color = stone, material = sm, base = true, baseH = 1, baseColor = dark})
			-- the stands outside: three tiers
			for t = 1, 3 do
				local rad = A + 4 + t * 3.4
				local q0, q1 = V3(math.cos(a0) * rad, 0, math.sin(a0) * rad), V3(math.cos(a1) * rad, 0, math.sin(a1) * rad)
				local mid, len = (q0 + q1) / 2, (q1 - q0).Magnitude + 0.6
				K.box(ctx, "Stand", V3(3.6, 7 + t * 2.4, len), CFrame.lookAt(mid, q1) * CFrame.new(0, (7 + t * 2.4) / 2, 0), t % 2 == 0 and dark or stone, sm)
			end
			if i % 4 == 0 then
				local bp = V3(math.cos(am) * (A + 2), 7, math.sin(am) * (A + 2))
				K.banner(ctx, bp, 8, i % 8 == 0 and T.house or T.house2)
			end
			if T.night and i % 3 == 0 then K.torch(ctx, V3(math.cos(am) * (A + 0.4), 5.2, math.sin(am) * (A + 0.4)), -math.deg(am) + 90) end
		end
	end
	-- the two gates: arches out to the world
	for _, z in ipairs({-1, 1}) do
		local top = K.arch(ctx, CFrame.new(0, 0, z * (A + 2)), 16, 12, 4, stone, sm)
		snowOn(ctx, T, K.box(ctx, "GateCap", V3(18, 1, 5), V3(0, top + 0.5, z * (A + 2)), dark, sm))
		K.torchPost(ctx, V3(-8, 0, z * (A + 7)), 6); K.torchPost(ctx, V3(8, 0, z * (A + 7)), 6)
	end
	-- the dais in the middle (the hill), braziers round it
	K.cyl(ctx, "Dais", 18, 0.5, V3(0, 0.25, 0), dark, sm)          -- (low enough to walk onto)
	K.cyl(ctx, "DaisTop", 16, 0.2, V3(0, 0.6, 0), stone, sm)
	for i = 0, 3 do
		local a = i / 4 * 2 * math.pi + math.pi / 4
		K.torchPost(ctx, V3(math.cos(a) * 11, 0, math.sin(a) * 11), 4)
	end
	-- pillars for cover, some broken
	for i = 0, 5 do
		local a = i / 6 * 2 * math.pi + math.pi / 6
		local h = (i % 2 == 0) and 12 or r:NextNumber(4, 7)
		local p = K.cyl(ctx, "Pillar", 3.2, h, V3(math.cos(a) * 27, h / 2, math.sin(a) * 27), stone, sm)
		K.cyl(ctx, "PillarBase", 4.2, 1, V3(math.cos(a) * 27, 0.5, math.sin(a) * 27), dark, sm)
		if h > 10 then K.cyl(ctx, "PillarCap", 4.2, 1, V3(math.cos(a) * 27, h + 0.5, math.sin(a) * 27), dark, sm) end
	end
	-- weapon racks by the gates, a few barrels
	K.rack(ctx, CFrame.new(-14, 0, A - 4) * CFrame.Angles(0, DEG(180), 0))
	K.rack(ctx, CFrame.new(14, 0, -A + 4))
	for _, p in ipairs({V3(-34, 0, -20), V3(34, 0, 18), V3(-30, 0, 26), V3(30, 0, -26)}) do K.barrel(ctx, p) end
	-- the world outside
	forest(ctx, T, r, T.trees, A + 24, 118, nil)
	for i = 1, 10 do local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(70, 115); K.rock(ctx, V3(math.cos(a) * d, -0.4, math.sin(a) * d), r:NextNumber(3, 6), T.cliffColor) end
	burntMarks(ctx, T, r, 6, A - 6)
	bounds(ctx, 124)
	weather(ctx, T, 260, 260)
	markers(ctx, {
		a = line(-10, 10, -36, 5), b = line(-10, 10, 36, 5), free = ring(8, 32, 1, math.pi / 8),
		hill = {V3(0, 0.7, 0), 9}, gates = {V3(0, 3, -(A - 4)), V3(0, 3, A - 4), V3(-(A - 4), 3, 0), V3(A - 4, 3, 0),
			V3(-30, 3, -30), V3(30, 3, 30), V3(-30, 3, 30), V3(30, 3, -30)},
		cams = {{V3(-60, 34, 60), V3(0, 4, 0)}, {V3(20, 8, -30), V3(-6, 4, 10)}, {V3(0, 70, 0.1), V3(0, 0, 0)}},
	})
	finishLook(ctx, T)
end

--------------------------------------------------------------------
--  LAYOUT: BAILEY — a castle courtyard: walls, towers, gatehouses, a keep
--------------------------------------------------------------------
local function bailey(ctx, T, r)
	local W, D = 60, 72
	ground(ctx, T, r, 130, function(B)
		B:FillBlock(CFrame.new(0, -2, 0), V3(W * 2, 4, D * 2), T.floor)
		B:FillBlock(CFrame.new(0, -2, 0), V3(12, 4, 240), T.path)
	end)
	local stone, dark, sm = T.stone, T.stoneDark, T.stoneMat
	local WALL = {crenels = true, base = true, baseH = 2.2, baseW = 1.6, color = stone, baseColor = dark, material = sm}
	K.wall(ctx, V3(-W, 0, -D), V3(-9, 0, -D), 16, 4, WALL); K.wall(ctx, V3(9, 0, -D), V3(W, 0, -D), 16, 4, WALL)
	K.wall(ctx, V3(-W, 0, D), V3(-9, 0, D), 16, 4, WALL); K.wall(ctx, V3(9, 0, D), V3(W, 0, D), 16, 4, WALL)
	K.wall(ctx, V3(-W, 0, -D), V3(-W, 0, D), 16, 4, WALL); K.wall(ctx, V3(W, 0, -D), V3(W, 0, D), 16, 4, WALL)
	for _, x in ipairs({-W, W}) do
		for _, z in ipairs({-D, D}) do K.tower(ctx, V3(x, 0, z), 7, 22, {roof = not T.flatTowers, roofColor = T.roof, windows = true, color = stone, base = 3, baseColor = dark, material = sm}) end
	end
	-- the gatehouses: an arch through each end wall, towers either side
	for _, z in ipairs({-D, D}) do
		K.arch(ctx, CFrame.new(0, 0, z), 14, 13, 5, stone, sm)
		for _, x in ipairs({-11, 11}) do K.tower(ctx, V3(x, 0, z), 5, 20, {roof = not T.flatTowers, roofColor = T.roof, color = stone, base = 2, baseColor = dark, material = sm}) end
		for _, x in ipairs({-22, 22}) do
			K.box(ctx, "WallBanner", V3(4.2, 10, 0.2), V3(x, 9, z + (z < 0 and -2.2 or 2.2)), z < 0 and T.house or T.house2, M.Fabric).CanCollide = false
		end
	end
	-- stairs up to the wall walks in two corners
	K.stairs(ctx, CFrame.new(-W + 4.5, 0, D - 24), 4, 11, 1.5, 2, dark, sm)
	K.stairs(ctx, CFrame.new(W - 4.5, 0, -D + 24) * CFrame.Angles(0, DEG(180), 0), 4, 11, 1.5, 2, dark, sm)
	-- the keep on the east side: solid, tall, a door and banners
	local keep = K.box(ctx, "Keep", V3(22, 26, 30), V3(W - 15, 13, 0), stone, sm)
	K.box(ctx, "KeepFooting", V3(24, 3, 32), V3(W - 15, 1.5, 0), dark, sm)
	for i = -3, 3 do K.box(ctx, "Crenel", V3(1.8, 2, 1.8), V3(W - 26.2, 27, i * 4.2), stone, sm) end
	K.box(ctx, "KeepDoor", V3(0.4, 8, 6), V3(W - 26.1, 4, 0), T.woodDark, M.WoodPlanks).CanCollide = false
	for _, z in ipairs({-9, 9}) do K.box(ctx, "KeepBanner", V3(0.2, 12, 4), V3(W - 26.2, 15, z), T.house, M.Fabric).CanCollide = false end
	snowOn(ctx, T, keep, 0.4)
	-- the well in the middle (the hill)
	K.cyl(ctx, "Well", 5, 2.4, V3(0, 1.2, 0), dark, sm)
	K.cyl(ctx, "WellHole", 3.6, 2.5, V3(0, 1.3, 0), RGB(20, 24, 30), M.SmoothPlastic).CanCollide = false
	K.pole(ctx, V3(-2.6, 2.4, 0), 3.8); K.pole(ctx, V3(2.6, 2.4, 0), 3.8)
	snowOn(ctx, T, K.box(ctx, "WellRoof", V3(6, 0.4, 6), V3(0, 6.2, 0), T.woodDark, M.WoodPlanks))
	-- market stalls along the west wall, carts, a forge corner
	for i = -2, 2 do K.awning(ctx, V3(-W + 9, 0, i * 14), 7, 9, 6, i % 2 == 0 and T.house or T.house2) end
	for _, p in ipairs({V3(-W + 9, 0, -36), V3(-W + 9, 0, 36)}) do K.crate(ctx, p, 3, r:NextNumber(0, 90)) end
	K.box(ctx, "Cart", V3(5, 2.4, 8), CFrame.new(-16, 1.9, -30) * CFrame.Angles(0, DEG(30), 0), T.wood, M.WoodPlanks)
	K.box(ctx, "Cart", V3(5, 2.4, 8), CFrame.new(18, 1.9, 34) * CFrame.Angles(0, DEG(-24), 0), T.wood, M.WoodPlanks)
	clutter(ctx, T, r, 12, 14, 40)
	K.rack(ctx, CFrame.new(24, 0, -44)); K.rack(ctx, CFrame.new(-24, 0, 44) * CFrame.Angles(0, DEG(180), 0))
	lamps(ctx, T, {V3(-30, 0, -50), V3(30, 0, 50), V3(-30, 0, 50), V3(30, 0, -50), V3(-14, 0, 0), V3(14, 0, 0)}, T.night and 7 or 6)
	-- outside: the road and the world
	forest(ctx, T, r, T.trees, 96, 126, {{V3(0, 0, 0), V3(70, 0, 200)}})
	burntMarks(ctx, T, r, 6, 40)
	bounds(ctx, W + 40, D + 40)
	weather(ctx, T, 240, 260)
	markers(ctx, {
		a = line(-10, 10, D - 10, 5), b = line(-10, 10, -D + 10, 5), free = ring(8, 30, 1),
		hill = {V3(0, 0, 0), 9}, gates = {V3(0, 3, D + 12), V3(0, 3, -D - 12), V3(-W + 6, 3, -D + 6), V3(W - 6, 3, D - 6),
			V3(-W + 6, 3, D - 6), V3(W - 6, 3, -D + 6), V3(-W + 6, 3, 0), V3(-30, 3, -D + 6)},
		cams = {{V3(-20, 46, 120), V3(0, 0, 0)}, {V3(-30, 8, 50), V3(10, 6, -10)}, {V3(40, 30, -110), V3(0, 8, -20)}},
	})
	finishLook(ctx, T)
end

--------------------------------------------------------------------
--  LAYOUT: VILLAGE — houses round a square, fences, a chapel, fields
--------------------------------------------------------------------
local function village(ctx, T, r)
	local R = 100
	ground(ctx, T, r, 120, function(B)
		B:FillBlock(CFrame.new(0, -2, 0), V3(200, 4, 10), T.path)
		B:FillBlock(CFrame.new(0, -2, 0), V3(10, 4, 200), T.path)
		B:FillCylinder(CFrame.new(0, -2, 0), 4, 18, T.floor)
	end)
	-- the square: a raised market platform (the hill), a market cross
	K.cyl(ctx, "Platform", 22, 0.5, V3(0, 0.25, 0), T.stoneDark, T.stoneMat)
	K.cyl(ctx, "PlatformTop", 20, 0.2, V3(0, 0.6, 0), T.stone, T.stoneMat)
	K.cyl(ctx, "Cross", 1.2, 12, V3(0, 6.7, 0), T.stone, T.stoneMat)
	K.box(ctx, "CrossArm", V3(4.4, 1, 1), V3(0, 10.3, 0), T.stone, T.stoneMat)
	for i = 0, 3 do
		local a = i / 4 * 2 * math.pi
		K.awning(ctx, V3(math.cos(a) * 20, 0, math.sin(a) * 20), 6, 7, 6, i % 2 == 0 and T.house or T.house2)
	end
	-- houses in a ring round the square, facing it; the chapel to the north
	local spots = {}
	for i = 0, 9 do
		local a = i / 10 * 2 * math.pi + r:NextNumber(-0.12, 0.12) + 0.31
		local d = r:NextNumber(46, 66)
		local p = V3(math.cos(a) * d, 0, math.sin(a) * d)
		if math.abs(p.X) > 8 and math.abs(p.Z) > 8 then
			local frame = CFrame.lookAt(p, 2 * p)   -- (-Z away from the square: the door, +Z, faces it)
			local w, len, h = r:NextNumber(9, 13), r:NextNumber(11, 15), r:NextNumber(6, 8)
			K.house(ctx, frame, w, len, h, T.plaster, T.roof)
			table.insert(spots, p)
			if T.snow then
				for _, d2 in ipairs(ctx.Geometry:GetChildren()) do if d2.Name == "Roof" and (d2.Position - p).Magnitude < 12 and not d2:GetAttribute("Snowed") then d2:SetAttribute("Snowed", true); snowOn(ctx, T, d2, 0.2) end end
			end
			if i % 3 == 0 then K.fence(ctx, p + (p.Unit:Cross(V3(0, 1, 0))) * 10, p + (p.Unit:Cross(V3(0, 1, 0))) * 10 + p.Unit * 12, 2.4) end
		end
	end
	do
		local cp = V3(0, 0, -78)
		K.box(ctx, "Chapel", V3(16, 12, 26), V3(cp.X, 6, cp.Z), T.plaster, M.Concrete)
		for _, s in ipairs({-1, 1}) do
			K.box(ctx, "ChapelRoof", V3(11, 0.5, 28), CFrame.new(cp.X + s * 4.6, 15, cp.Z) * CFrame.Angles(0, 0, DEG(-s * 40)), T.roof, M.WoodPlanks)
		end
		K.box(ctx, "ChapelTower", V3(7, 22, 7), V3(cp.X, 11, cp.Z + 15), T.stone, T.stoneMat)
		K.cone(ctx, "Spire", V3(cp.X, 22, cp.Z + 15), 5, 10, T.roof, M.WoodPlanks, nil, false, 4)
		K.box(ctx, "ChapelDoor", V3(4, 7, 0.3), V3(cp.X, 3.5, cp.Z + 18.6), T.woodDark, M.Wood).CanCollide = false
	end
	-- fields of hay, carts, wells, barrels
	for i = 1, 10 do local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(70, 92); K.hay(ctx, V3(math.cos(a) * d, 0, math.sin(a) * d)) end
	clutter(ctx, T, r, 14, 24, 80)
	K.box(ctx, "Cart", V3(5, 2.4, 8), CFrame.new(30, 1.9, 8) * CFrame.Angles(0, DEG(70), 0), T.wood, M.WoodPlanks)
	K.box(ctx, "Cart", V3(5, 2.4, 8), CFrame.new(-34, 1.9, -10) * CFrame.Angles(0, DEG(-50), 0), T.wood, M.WoodPlanks)
	lamps(ctx, T, ring(T.night and 10 or 6, 34, 0, 0.2), 6)
	forest(ctx, T, r, T.trees, 88, 118, {{V3(0, 0, 0), V3(8, 0, 200)}, {V3(0, 0, 0), V3(200, 0, 8)}})
	burntMarks(ctx, T, r, 10, 80)
	bounds(ctx, 122)
	weather(ctx, T, 260, 260)
	markers(ctx, {
		a = lineX(-92, -12, 12, 5), b = lineX(92, -12, 12, 5), free = ring(10, 60, 1, 0.1), center = V3(0, 1, 0),
		hill = {V3(0, 0.7, 0), 10}, gates = ring(8, 100, 3, 0.2),
		cams = {{V3(-90, 44, 90), V3(0, 6, 0)}, {V3(30, 10, 24), V3(-10, 6, -10)}, {V3(0, 60, 110), V3(0, 4, -20)}},
	})
	finishLook(ctx, T)
end

--------------------------------------------------------------------
--  LAYOUT: BRIDGE — a fortified bridge over a river (or a dry gorge)
--------------------------------------------------------------------
local function bridge(ctx, T, r, def)
	local HALF = 40               -- the river runs along X, |z| < HALF
	local floorY = def.dry and -46 or -40   -- (inside the terrain region, whose foot is at -64)
	ground(ctx, T, r, 120, function(B)
		B:FillBlock(CFrame.new(0, (floorY - 6) / 2, 0), V3(408, -floorY + 6, HALF * 2), Mat.Air)
		B:FillBlock(CFrame.new(0, floorY - 4, 0), V3(408, 8, HALF * 2 + 8), def.dry and T.cliff or Mat.Rock)
		-- rock faces lining the banks
		for _, s in ipairs({-1, 1}) do
			for i = -10, 10 do
				B:FillBall(V3(i * 20 + r:NextNumber(-4, 4), floorY / 2, s * (HALF + 6)), r:NextNumber(10, 14), T.cliff)
			end
		end
		if not def.dry then B:FillBlock(CFrame.new(0, floorY + 10, 0), V3(408, 20, HALF * 2), Mat.Water) end
		B:FillBlock(CFrame.new(0, -2, 0), V3(10, 4, 260), T.path)
	end)
	ctx.model:SetAttribute("DrownY", def.dry and -24 or (floorY + 22))
	local stone, dark, sm = T.stone, T.stoneDark, T.stoneMat
	-- the deck, its parapets, the piers
	local L = HALF * 2 + 16
	K.box(ctx, "Deck", V3(22, 2, L), V3(0, -1, 0), stone, sm)
	K.wall(ctx, V3(-11, 0, -L / 2), V3(-11, 0, L / 2), 3.6, 1.4, {crenels = true, color = stone, material = sm})
	K.wall(ctx, V3(11, 0, -L / 2), V3(11, 0, L / 2), 3.6, 1.4, {crenels = true, color = stone, material = sm})
	for _, z in ipairs({-20, 0, 20}) do
		K.box(ctx, "Pier", V3(16, -floorY, 8), V3(0, floorY / 2 - 1, z), dark, sm)
	end
	-- the middle bay: wider, a shrine (the hill)
	K.box(ctx, "Bay", V3(34, 2, 14), V3(0, -1, 0), stone, sm)
	K.box(ctx, "Shrine", V3(3, 6, 3), V3(0, 3, 0), dark, sm)
	K.ball(ctx, "ShrineLamp", 1.6, V3(0, 6.8, 0), RGB(255, 200, 120), M.Neon).CanCollide = false
	for _, x in ipairs({-16, 16}) do K.torchPost(ctx, V3(x, 0, 0), 5) end
	-- the gatehouses at both ends
	for _, z in ipairs({-L / 2 - 4, L / 2 + 4}) do
		K.arch(ctx, CFrame.new(0, 0, z), 14, 12, 6, stone, sm)
		for _, x in ipairs({-12, 12}) do K.tower(ctx, V3(x, 0, z), 5.5, 20, {roof = not T.flatTowers, roofColor = T.roof, color = stone, base = 2, baseColor = dark, material = sm}) end
	end
	-- a plank crossing downstream, rope rails
	local px = 64
	K.box(ctx, "Planks", V3(6, 0.6, L), V3(px, -0.3, 0), T.wood, M.WoodPlanks)
	for _, s in ipairs({-1, 1}) do K.rope(ctx, V3(px + s * 3, 2.6, -L / 2), V3(px + s * 3, 2.6, L / 2), C.ROPE) end
	for _, z in ipairs({-L / 2, -L / 4, 0, L / 4, L / 2}) do for _, s in ipairs({-1, 1}) do K.pole(ctx, V3(px + s * 3, -0.4, z), 3.2, T.woodDark) end end
	-- ruined towers in the water upstream
	for _, p in ipairs({V3(-50, floorY, 10), V3(-78, floorY, -14)}) do K.tower(ctx, p, 6, -floorY - 6 + r:NextNumber(2, 8), {color = dark, material = sm}) end
	-- the two camps, one on each bank
	for _, s in ipairs({-1, 1}) do
		for i = 0, 3 do
			local tf = CFrame.new(-36 + i * 22, 0, s * (HALF + 40)) * CFrame.Angles(0, DEG(r:NextNumber(-20, 20)), 0)
			K.tent(ctx, tf, 8, 10, 6, s < 0 and T.tent or T.house2)
		end
		campfire(ctx, T, V3(r:NextNumber(-20, 20), 0, s * (HALF + 24)))
		K.banner(ctx, V3(-16, 0, s * (HALF + 14)), 10, s < 0 and T.house or T.house2)
		K.banner(ctx, V3(16, 0, s * (HALF + 14)), 10, s < 0 and T.house or T.house2)
	end
	clutter(ctx, T, r, 10, HALF + 14, 100)
	forest(ctx, T, r, T.trees, 56, 120, {{V3(0, 0, 0), V3(220, 0, HALF + 12)}, {V3(0, 0, 0), V3(30, 0, 200)}})
	bounds(ctx, 124)
	weather(ctx, T, 260, 260)
	local nearA, nearB = -(HALF + 34), HALF + 34
	markers(ctx, {
		a = line(-16, 16, nearA, 5), b = line(-16, 16, nearB, 5),
		free = {V3(-30, 1, nearA + 8), V3(30, 1, nearA + 8), V3(-30, 1, nearB - 8), V3(30, 1, nearB - 8), V3(0, 1, -26), V3(0, 1, 26), V3(px, 1, -20), V3(px, 1, 20)},
		hill = {V3(0, 0, 0), 8}, gates = {V3(-60, 3, nearA), V3(60, 3, nearA), V3(-60, 3, nearB), V3(60, 3, nearB), V3(0, 3, nearA - 30), V3(0, 3, nearB + 30), V3(-90, 3, nearA), V3(90, 3, nearB)},
		cams = {{V3(-90, 40, -70), V3(0, 0, 0)}, {V3(14, 8, 30), V3(-4, 4, -10)}, {V3(80, 26, 70), V3(0, -6, 0)}},
	})
	finishLook(ctx, T)
end

--------------------------------------------------------------------
--  LAYOUT: RUINS — a broken temple on its steps, columns, broken walls
--------------------------------------------------------------------
local function ruins(ctx, T, r)
	ground(ctx, T, r, 120, function(B)
		for i = 1, 12 do
			local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(50, 95)
			B:FillBall(V3(math.cos(a) * d, -6, math.sin(a) * d), r:NextNumber(8, 12), T.ground)
		end
	end)
	local stone, dark, sm = T.stone, T.stoneDark, T.stoneMat
	-- the temple: three steps up to a floor, columns round it, an altar
	for i = 0, 2 do K.box(ctx, "Step", V3(36 - i * 3, 1, 36 - i * 3), V3(0, 0.5 + i, 0), i % 2 == 0 and dark or stone, sm) end
	local Y = 3
	for i = 0, 11 do
		local a = i / 12 * 2 * math.pi
		local p = V3(math.cos(a) * 13, 0, math.sin(a) * 13)
		local h = (i % 3 == 0) and r:NextNumber(2, 5) or r:NextNumber(10, 14)
		K.cyl(ctx, "Column", 2.4, h, V3(p.X, Y + h / 2, p.Z), stone, sm)
		if h > 9 then K.box(ctx, "Capital", V3(3.2, 1, 3.2), V3(p.X, Y + h + 0.5, p.Z), dark, sm) end
		if h < 6 then
			-- the rest of it on the ground
			local fall = CFrame.new(p.X * 1.9, 1.2, p.Z * 1.9) * CFrame.Angles(0, a, DEG(90))
			K.cyl(ctx, "Fallen", 2.4, r:NextNumber(6, 9), fall, stone, sm)
		end
	end
	K.box(ctx, "Altar", V3(5, 2.4, 3), V3(0, Y + 1.2, 0), dark, sm)
	local slab = K.box(ctx, "RoofSlab", V3(20, 1.4, 8), CFrame.new(-6, Y + 6, 4) * CFrame.Angles(DEG(14), DEG(20), DEG(28)), stone, sm)
	snowOn(ctx, T, slab, 0.4)
	for _, s in ipairs({-1, 1}) do K.stairs(ctx, CFrame.new(0, 0, s * 20) * CFrame.Angles(0, s > 0 and 0 or math.pi, 0), 8, 3, 1, 1.4, stone, sm) end
	-- an invisible ramp along every side, so the steps never stop anyone (bots included)
	for i = 0, 3 do
		local w = K.wedge(ctx, "StepRamp", V3(36, 3, 9), CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 1.5, 19.5) * CFrame.Angles(0, math.pi, 0), stone, sm)
		w.Transparency, w.CastShadow = 1, false
	end
	-- broken walls (L-shapes) and obelisks scattered round
	for i = 1, 11 do
		local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(34, 86)
		local p = V3(math.cos(a) * d, 0, math.sin(a) * d)
		local dir = V3(math.cos(a + math.pi / 2), 0, math.sin(a + math.pi / 2))
		K.wall(ctx, p, p + dir * r:NextNumber(10, 18), r:NextNumber(3, 9), 2.4, {color = i % 2 == 0 and stone or dark, material = sm})
		if i % 2 == 0 then K.wall(ctx, p, p + p.Unit * r:NextNumber(6, 10), r:NextNumber(3, 6), 2.4, {color = dark, material = sm}) end
	end
	for i = 1, 3 do
		local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(40, 80)
		local p = V3(math.cos(a) * d, 0, math.sin(a) * d)
		K.box(ctx, "Obelisk", V3(3, 16, 3), V3(p.X, 8, p.Z), dark, sm)
		K.box(ctx, "ObeliskCap", V3(2.2, 1.2, 2.2), V3(p.X, 16.6, p.Z), dark, sm)
		K.box(ctx, "ObeliskTip", V3(1.2, 1, 1.2), V3(p.X, 17.7, p.Z), T.stone, sm)
	end
	do
		local p = V3(0, 0, 60)
		K.arch(ctx, CFrame.new(p) * CFrame.Angles(0, DEG(r:NextNumber(-20, 20)), 0), 10, 10, 3, stone, sm)
	end
	for i = 1, 16 do local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(20, 100); K.rock(ctx, V3(math.cos(a) * d, -0.4, math.sin(a) * d), r:NextNumber(2, 5), dark) end
	lamps(ctx, T, ring(T.night and 8 or 4, 24, 0, 0.4), 5)
	forest(ctx, T, r, math.floor(T.trees * 0.7), 90, 118, nil)
	burntMarks(ctx, T, r, 12, 90)
	bounds(ctx, 122)
	weather(ctx, T, 260, 260)
	markers(ctx, {
		a = lineX(-88, -12, 12, 5), b = lineX(88, -12, 12, 5), free = ring(10, 56, 1, 0.3),
		hill = {V3(0, Y, 0), 9}, gates = ring(8, 96, 3, 0.4),
		cams = {{V3(-70, 36, 70), V3(0, 6, 0)}, {V3(16, 9, 26), V3(-4, 6, 0)}, {V3(60, 20, -80), V3(0, 4, 0)}},
	})
	finishLook(ctx, T)
end

--------------------------------------------------------------------
--  LAYOUT: CLEARING — a stone circle in a forest clearing
--------------------------------------------------------------------
local function clearing(ctx, T, r)
	local CR = 56
	ground(ctx, T, r, 120, function(B)
		B:FillBlock(CFrame.new(0, -2, 0), V3(8, 4, 240), T.path)
		B:FillBlock(CFrame.new(0, -2, 0), V3(240, 4, 8), T.path)
		B:FillCylinder(CFrame.new(-28, -4, 34), 8, 10, Mat.Air)
		B:FillCylinder(CFrame.new(-28, -5, 34), 8, 10, Mat.Water)
	end)
	local stone, dark, sm = T.stone, T.stoneDark, T.stoneMat
	-- the stone circle and its altar (the hill)
	for i = 0, 9 do
		local a = i / 10 * 2 * math.pi
		local h = (i % 4 == 1) and 4 or r:NextNumber(8, 11)
		local s = K.box(ctx, "Standing", V3(3.2, h, 1.8), CFrame.new(math.cos(a) * 15, h / 2, math.sin(a) * 15) * CFrame.Angles(0, -a, DEG(r:NextNumber(-4, 4))), i % 2 == 0 and stone or dark, sm)
		snowOn(ctx, T, s, 0.2)
	end
	K.cyl(ctx, "AltarStone", 8, 1.6, V3(0, 0.8, 0), dark, sm)
	-- the woodcutter's hut, log piles, a campfire
	K.house(ctx, CFrame.lookAt(V3(34, 0, -30), V3(68, 0, -60)), 10, 12, 6, T.plaster, T.roof)
	for i = 0, 2 do K.cyl(ctx, "LogPile", 1.6, 10, CFrame.new(24, 0.8 + (i % 2) * 1.4, -16 + i * 1.6) * CFrame.Angles(0, DEG(90), DEG(90)), T.wood, M.Wood) end
	K.box(ctx, "ChoppingBlock", V3(2.4, 2, 2.4), V3(20, 1, -24), T.woodDark, M.Wood)
	campfire(ctx, T, V3(-20, 0, -20))
	for _, p in ipairs({V3(-26, 0, -26), V3(-14, 0, -28)}) do K.box(ctx, "LogSeat", V3(6, 1.2, 1.4), CFrame.new(p + V3(0, 0.6, 0)) * CFrame.Angles(0, DEG(r:NextNumber(0, 60)), 0), T.wood, M.Wood) end
	-- stepping stones over the pond
	for i = -2, 2 do K.cyl(ctx, "SteppingStone", 2.6, 1.6, V3(-28 + i * 3.2, -0.5, 34 + (i % 2) * 1.4), dark, sm) end
	-- fallen trunks for cover, rocks
	for i = 1, 6 do
		local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(24, CR - 6)
		K.cyl(ctx, "FallenTrunk", 2.2, r:NextNumber(9, 14), CFrame.new(math.cos(a) * d, 1.1, math.sin(a) * d) * CFrame.Angles(0, a + math.pi / 2, DEG(90)), T.woodDark, M.Wood)
	end
	for i = 1, 10 do local a, d = r:NextNumber(0, 2 * math.pi), r:NextNumber(20, CR); K.rock(ctx, V3(math.cos(a) * d, -0.4, math.sin(a) * d), r:NextNumber(2, 4), dark) end
	lamps(ctx, T, ring(T.night and 8 or 4, 26, 0, 0.3), 5)
	-- the forest: thick all round, open along the four paths
	forest(ctx, T, r, T.trees + 16, CR + 4, 120, {{V3(0, 0, 0), V3(7, 0, 200)}, {V3(0, 0, 0), V3(200, 0, 7)}})
	bounds(ctx, 122)
	weather(ctx, T, 240, 240)
	markers(ctx, {
		a = line(-10, 10, -46, 5), b = line(-10, 10, 46, 5), free = ring(8, 36, 1, 0.2),
		hill = {V3(0, 0, 0), 10}, gates = {V3(0, 3, -90), V3(0, 3, 90), V3(-90, 3, 0), V3(90, 3, 0), V3(-50, 3, -50), V3(50, 3, 50), V3(-50, 3, 50), V3(50, 3, -50)},
		cams = {{V3(-50, 30, 50), V3(0, 4, 0)}, {V3(14, 6, -8), V3(-6, 5, 6)}, {V3(0, 60, 70), V3(0, 0, 0)}},
	})
	finishLook(ctx, T)
end

--------------------------------------------------------------------
--  LAYOUT: SIEGE — a castle to take, stage by stage (after Frostgate)
--------------------------------------------------------------------
local function siege(ctx, T, r, def)
	ground(ctx, T, r, 170, function(B)
		B:FillBlock(CFrame.new(0, -2, 70), V3(16, 4, 196), T.path)
		B:FillBlock(CFrame.new(0, -2, -98), V3(132, 4, 132), T.floor)
	end)
	local stone, dark, sm = T.stone, T.stoneDark, T.stoneMat
	local WX, ZF, ZB = 70, -30, -172
	local WALL = {crenels = true, base = true, baseH = 2.4, baseW = 2, color = stone, baseColor = dark, material = sm}
	K.wall(ctx, V3(-WX, 0, ZF), V3(-16, 0, ZF), 18, 4, WALL)
	K.wall(ctx, V3(16, 0, ZF), V3(WX, 0, ZF), 18, 4, WALL)
	K.wall(ctx, V3(-WX, 0, ZF), V3(-WX, 0, ZB), 18, 4, WALL)
	K.wall(ctx, V3(WX, 0, ZF), V3(WX, 0, ZB), 18, 4, WALL)
	K.wall(ctx, V3(-WX, 0, ZB), V3(WX, 0, ZB), 18, 4, WALL)
	local towerOpts = {roof = not T.flatTowers, roofColor = T.roof, windows = true, color = stone, base = 3, baseColor = dark, material = sm}
	for _, x in ipairs({-WX, WX}) do for _, z in ipairs({ZF, ZB}) do K.tower(ctx, V3(x, 0, z), 8, 26, towerOpts) end end
	for _, x in ipairs({-16, 16}) do K.tower(ctx, V3(x, 0, ZF), 7, 28, towerOpts) end
	K.box(ctx, "GateArch", V3(22, 6, 7), V3(0, 19, ZF), stone, sm)
	K.box(ctx, "GateArchTrim", V3(18.6, 0.8, 7.6), V3(0, 16.4, ZF), dark, sm)
	K.box(ctx, "GateChamber", V3(24, 6, 9), V3(0, 25, ZF), stone, sm)
	for i = -3, 3 do K.box(ctx, "Crenel", V3(1.6, 1.6, 1.6), V3(i * 2.6, 28.8, ZF + 4), stone, sm) end
	K.box(ctx, "GateCrest", V3(4, 4, 0.4), V3(0, 25, ZF + 4.7), T.house, M.Fabric).CanCollide = false
	K.stairs(ctx, CFrame.new(-WX + 4.5, 0, ZF - 30), 4, 12, 1.5, 2, dark, sm)
	K.stairs(ctx, CFrame.new(WX - 4.5, 0, ZF - 30), 4, 12, 1.5, 2, dark, sm)
	if T.snow then for _, d in ipairs(ctx.Geometry:GetChildren()) do if d:IsA("BasePart") and (d.Name == "Walk" or d.Name == "Crenel") then snowOn(ctx, T, d, 0.1) end end end
	for _, x in ipairs({-16, 16}) do K.box(ctx, "WallBanner", V3(4.4, 12, 0.2), V3(x, 14, ZF + 7.2), T.house, M.Fabric).CanCollide = false end
	if T.night then for _, x in ipairs({-24, 24, -44, 44}) do K.torch(ctx, V3(x, 12, ZF + 2.3), 0) end end

	-- stage 1: the ram up the road to the gate
	local s1 = K.objective(ctx, 1, "Ram", {Label = "Push the ram to the gate", Speed = 2.6, Radius = 13, AddTime = 150, Interval = 2.4})
	local w1, w2, w3 = r:NextNumber(-8, 8), r:NextNumber(-8, 8), r:NextNumber(-6, 6)
	local path = {V3(0, 0, 128), V3(w1, 0, 92), V3(w2, 0, 54), V3(w3, 0, 16), V3(0, 0, -16.6)}
	K.path(ctx, s1, path)
	K.ram(ctx, s1, CFrame.lookAt(path[1], path[2]))
	K.gate(ctx, s1, CFrame.new(0, 0, ZF), 18, 16, 10)
	for _, x in ipairs({-9.6, 9.6}) do K.box(ctx, "Passage", V3(1.2, 16, 8), V3(x, 8, ZF - 4.5), dark, sm) end
	K.box(ctx, "PassageRoof", V3(20.4, 1.4, 8), V3(0, 16.7, ZF - 4.5), dark, sm)

	-- stage 2: the bailey (a well, stables, a forge, carts)
	local s2 = K.objective(ctx, 2, "Capture", {Label = "Take the bailey", Time = 22, AddTime = 150})
	K.zone(ctx, s2, "Zone", V3(0, 0, -72), 13, 12)
	K.cyl(ctx, "Well", 5, 2.4, V3(0, 1.2, -72), dark, sm)
	K.cyl(ctx, "WellHole", 3.6, 2.5, V3(0, 1.3, -72), RGB(20, 24, 30), M.SmoothPlastic).CanCollide = false
	snowOn(ctx, T, K.box(ctx, "WellRoof", V3(6, 0.4, 6), V3(0, 6.2, -72), T.woodDark, M.WoodPlanks))
	K.pole(ctx, V3(-2.6, 2.4, -72), 3.8); K.pole(ctx, V3(2.6, 2.4, -72), 3.8)
	do
		local base = CFrame.new(-56, 0, -76)
		K.box(ctx, "StableBack", V3(1, 9, 40), base * CFrame.new(-6, 4.5, 0), T.woodDark, M.WoodPlanks)
		for i = -2, 2 do K.box(ctx, "StablePost", V3(0.8, 8, 0.8), base * CFrame.new(5, 4, i * 10), T.woodDark, M.Wood) end
		for i = -1, 2 do K.box(ctx, "StableStall", V3(10, 4, 0.5), base * CFrame.new(0, 2, -15 + i * 10), T.wood, M.WoodPlanks) end
		snowOn(ctx, T, K.box(ctx, "StableRoof", V3(14, 0.5, 42), base * CFrame.new(-0.5, 9, 0) * CFrame.Angles(0, 0, DEG(-12)), T.woodDark, M.WoodPlanks), 0.4)
		for i = 1, 5 do K.hay(ctx, (base * CFrame.new(-1, 0, -18 + i * 7)).Position) end
	end
	do
		local base = CFrame.new(54, 0, -64)
		K.box(ctx, "ForgeHearth", V3(8, 3.4, 6), base * CFrame.new(0, 1.7, 0), dark, sm)
		local coals = K.box(ctx, "ForgeCoals", V3(6, 0.4, 4), base * CFrame.new(0, 3.6, 0), RGB(255, 120, 40), M.Neon)
		coals.CanCollide = false
		local f = Instance.new("Fire"); f.Size = 4; f.Heat = 6; f.Color = RGB(255, 140, 40); f.Parent = coals
		local l = Instance.new("PointLight"); l.Color = RGB(255, 150, 70); l.Range = 22; l.Brightness = 2; l.Parent = coals
		K.box(ctx, "ForgeChimney", V3(4, 14, 4), base * CFrame.new(0, 10, 2), dark, sm)
		K.rack(ctx, base * CFrame.new(-2, 0, -9) * CFrame.Angles(0, DEG(180), 0))
		snowOn(ctx, T, K.box(ctx, "ForgeRoof", V3(16, 0.5, 14), base * CFrame.new(-3, 8.5, -2) * CFrame.Angles(0, 0, DEG(10)), T.woodDark, M.WoodPlanks), 0.4)
		for _, p in ipairs({V3(-10, 0, 5), V3(-10, 0, -9)}) do K.pole(ctx, (base * CFrame.new(p)).Position, 8.6) end
	end
	K.box(ctx, "Cart", V3(5, 2.4, 8), CFrame.new(-22, 1.9, -50) * CFrame.Angles(0, DEG(30), 0), T.wood, M.WoodPlanks)
	for _, p in ipairs({V3(-30, 0, -96), V3(-26, 0, -98), V3(28, 0, -46), V3(34, 0, -100)}) do K.barrel(ctx, p) end
	for _, p in ipairs({V3(24, 0, -96), V3(26, 0, -92), V3(-40, 0, -46)}) do K.crate(ctx, p, 3, p.X) end
	lamps(ctx, T, {V3(-36, 0, -60), V3(36, 0, -80), V3(-14, 0, -108), V3(14, 0, -108)}, 7)

	-- stage 3: the great hall; stage 4: its champion
	local HZ0, HZ1, HW, hallH = -116, -162, 26, 16
	K.box(ctx, "HallWall", V3(2.4, hallH, HZ0 - HZ1), V3(-HW, hallH / 2, (HZ0 + HZ1) / 2), stone, sm)
	K.box(ctx, "HallWall", V3(2.4, hallH, HZ0 - HZ1), V3(HW, hallH / 2, (HZ0 + HZ1) / 2), stone, sm)
	K.box(ctx, "HallWall", V3(HW * 2 + 2.4, hallH, 2.4), V3(0, hallH / 2, HZ1), stone, sm)
	K.box(ctx, "HallFront", V3(HW - 5, hallH, 2.4), V3(-(HW + 5) / 2, hallH / 2, HZ0), stone, sm)
	K.box(ctx, "HallFront", V3(HW - 5, hallH, 2.4), V3((HW + 5) / 2, hallH / 2, HZ0), stone, sm)
	K.box(ctx, "HallLintel", V3(10.4, 5, 2.4), V3(0, hallH - 2.5, HZ0), stone, sm)
	local pitch = DEG(32)
	local run = HW + 1.5
	local slope = run / math.cos(pitch)
	local ridgeY = 15.5 + run * math.tan(pitch)
	for _, s in ipairs({-1, 1}) do
		snowOn(ctx, T, K.box(ctx, "HallRoof", V3(slope, 1, HZ0 - HZ1 + 6), CFrame.new(s * run / 2, (15.5 + ridgeY) / 2, (HZ0 + HZ1) / 2) * CFrame.Angles(0, 0, -s * pitch), T.roof, M.WoodPlanks), 1)
	end
	K.box(ctx, "HallRidge", V3(1.4, 1.4, HZ0 - HZ1 + 7), V3(0, ridgeY + 0.5, (HZ0 + HZ1) / 2), T.woodDark, M.Wood)
	for _, z in ipairs({HZ0, HZ1}) do
		local layers = 7
		local lh = (ridgeY - hallH) / layers
		for i = 1, layers do
			local w = (HW * 2) * (1 - (i - 0.5) / layers)
			K.box(ctx, "HallGable", V3(w, lh, 2.4), V3(0, hallH + (i - 0.5) * lh, z), stone, sm)
		end
	end
	K.box(ctx, "HallFloor", V3(HW * 2, 0.4, HZ0 - HZ1), V3(0, 0.2, (HZ0 + HZ1) / 2), T.wood, M.WoodPlanks)
	K.box(ctx, "Hearth", V3(5, 0.8, 14), V3(0, 0.8, -140), dark, sm)
	local embers = K.box(ctx, "HearthFire", V3(3.6, 0.3, 12), V3(0, 1.35, -140), RGB(255, 110, 40), M.Neon)
	embers.CanCollide = false
	local hf = Instance.new("Fire"); hf.Size = 5; hf.Heat = 4; hf.Parent = embers
	local hl = Instance.new("PointLight"); hl.Color = RGB(255, 160, 80); hl.Range = 30; hl.Brightness = 2.2; hl.Parent = embers
	for _, x in ipairs({-11, 11}) do
		K.box(ctx, "LongTable", V3(4, 0.5, 22), V3(x, 2.8, -134), T.wood, M.WoodPlanks)
		for _, z in ipairs({-124, -144}) do K.box(ctx, "TableLeg", V3(3, 2.6, 0.6), V3(x, 1.5, z), T.woodDark, M.Wood) end
	end
	for _, x in ipairs({-18, 18}) do for _, z in ipairs({-124, -138, -152}) do K.cyl(ctx, "HallPillar", 2, hallH, V3(x, hallH / 2, z), T.woodDark, M.Wood) end end
	local s3 = K.objective(ctx, 3, "Capture", {Label = "Storm the great hall", Time = 26, AddTime = 120})
	K.zone(ctx, s3, "Zone", V3(0, 0.4, -124.5), 8.5, 12)
	K.box(ctx, "Dais", V3(22, 1.6, 10), V3(0, 0.8, -154), dark, sm)
	K.stairs(ctx, CFrame.new(0, 0, -147.2), 10, 2, 0.8, 0.8, dark, sm)
	K.box(ctx, "Throne", V3(5, 2, 4), V3(0, 2.6, -156), T.woodDark, M.Wood)
	K.box(ctx, "ThroneBack", V3(5, 8, 1), V3(0, 6, -157.6), T.woodDark, M.Wood)
	for _, x in ipairs({-2.8, 2.8}) do K.ball(ctx, "ThroneKnob", 1.2, V3(x, 10.4, -157.6), C.GOLD, M.Metal) end
	for _, x in ipairs({-8, 8}) do K.box(ctx, "HallBanner", V3(4, 10, 0.2), V3(x, 9, HZ1 + 1.4), T.house, M.Fabric).CanCollide = false end
	for _, x in ipairs({-9, 9}) do K.torchPost(ctx, V3(x, 1.6, -152), 4) end
	local champ = def.champion or {name = "The Lord", weapon = "Greatsword"}
	local s4 = K.objective(ctx, 4, "Slay", {Label = "Slay " .. champ.name, Name = champ.name, Weapon = champ.weapon, Health = 220, PerAttacker = 70})
	local at = Instance.new("Part"); at.Name = "At"; at.Size = V3(1, 1, 1); at.Transparency = 1; at.Anchored = true; at.CanCollide = false; at.CanQuery = false
	at.CFrame = CFrame.lookAt(V3(0, 4.6, -152), V3(0, 4.6, -120)); at.Parent = s4
	at:SetAttribute("ArenaRadius", 26)

	-- the attackers' camp (south)
	for i, t in ipairs({{-34, 156, 20}, {-18, 172, -10}, {22, 164, 15}, {38, 150, -20}, {-44, 178, 5}, {44, 178, -5}}) do
		local tf = CFrame.new(t[1], 0, t[2]) * CFrame.Angles(0, DEG(t[3]), 0)
		K.tent(ctx, tf, 8, 10, 6, i % 2 == 0 and T.tent or T.house2)
	end
	for _, p in ipairs({V3(0, 0, 176), V3(-26, 0, 140), V3(28, 0, 136)}) do campfire(ctx, T, p) end
	for i = 0, 2 do
		local lf = CFrame.new(-16 + i * 1.6, 0.3, 112) * CFrame.Angles(0, DEG(8), 0)
		for _, x in ipairs({-1, 1}) do K.box(ctx, "LadderRail", V3(0.4, 0.4, 16), lf * CFrame.new(x, i * 0.4, 0), T.wood, M.Wood) end
		for rr = -7, 7, 1.6 do K.box(ctx, "LadderRung", V3(2, 0.25, 0.25), lf * CFrame.new(0, i * 0.4, rr), T.woodDark, M.Wood) end
	end
	for _, p in ipairs({V3(-10, 0, 150), V3(12, 0, 154), V3(-30, 0, 120)}) do K.crate(ctx, p, 3, p.X * 3) end
	for _, x in ipairs({-8, 8}) do K.banner(ctx, V3(x, 0, 140), 10, T.tent) end
	for i = -5, 5 do
		if math.abs(i) > 1 then K.cyl(ctx, "Stake", 1, 6, CFrame.new(V3(i * 7, 2.4, 132 - math.abs(i) * 1.5)) * CFrame.Angles(DEG(-30), 0, 0), T.wood, M.Wood) end
	end
	-- the field between: trees, rocks, old ruins for cover
	forest(ctx, T, r, T.trees + 10, 84, 176, {{V3(0, 0, -100), V3(84, 0, 84)}, {V3(0, 0, 60), V3(16, 0, 140)}, {V3(0, 0, 160), V3(56, 0, 30)}})
	for i = 1, 14 do
		local x = (i % 2 == 0 and 1 or -1) * r:NextNumber(18, 70)
		local z = r:NextNumber(0, 120)
		if math.abs(x) > 14 then K.rock(ctx, V3(x, -0.4, z), r:NextNumber(3, 6), T.cliffColor) end
	end
	for _, w in ipairs({{V3(-30, 0, 66), V3(-30, 0, 80)}, {V3(-30, 0, 66), V3(-42, 0, 66)}, {V3(32, 0, 40), V3(44, 0, 40)}, {V3(32, 0, 40), V3(32, 0, 50)}}) do
		K.wall(ctx, w[1], w[2], 6, 2, {color = dark, material = sm})
	end
	burntMarks(ctx, T, r, 14, 120)
	bounds(ctx, 176, 212)
	weather(ctx, T, 300, 380)

	-- spawns: Side / Stage (Siege), plus plain team spawns (any other mode)
	local function sp(pos, side, stage, look)
		local p = K.spawn(ctx, pos, nil, look)
		p:SetAttribute("Side", side); p:SetAttribute("Stage", stage)
		return p
	end
	for i = -3, 3 do sp(V3(i * 5, 1, 166), "Attack", 1, V3(0, 1, 0)) end
	for i = -3, 3 do sp(V3(i * 5, 1, 28 + math.abs(i) * 2), "Attack", 2, V3(0, 1, -60)) end
	for i = -3, 3 do sp(V3(i * 6, 1, -42), "Attack", 3, V3(0, 1, -120)) end
	for i = 1, 4 do sp(V3(-20 - i * 4, 1, -20), "Defend", 1, V3(0, 1, 60)); sp(V3(20 + i * 4, 1, -20), "Defend", 1, V3(0, 1, 60)) end
	for i = -3, 3 do sp(V3(i * 9, 1, -104), "Defend", 2, V3(0, 1, -40)) end
	for i = 1, 3 do sp(V3(-40 - i * 4, 1, -150), "Defend", 3, V3(0, 1, -120)); sp(V3(40 + i * 4, 1, -150), "Defend", 3, V3(0, 1, -120)) end
	for i = -2, 2 do K.spawn(ctx, V3(i * 6, 1, 160), "A", V3(0, 1, 0)); K.spawn(ctx, V3(i * 6, 1, -96), "B", V3(0, 1, 0)) end
	K.camera(ctx, V3(-30, 26, 170), V3(0, 10, -30))
	K.camera(ctx, V3(26, 10, 4), V3(0, 12, -30))
	K.camera(ctx, V3(-16, 8, -110), V3(0, 6, -156))
	finishLook(ctx, T)
end

local LAYOUTS = {arena = arena, bailey = bailey, village = village, bridge = bridge, ruins = ruins, clearing = clearing, siege = siege}

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
function F.build(kit, name)
	K, C, M = kit, kit.C, kit.M
	local def = F.MAPS[name]
	if not def then error("no forge map called " .. tostring(name)) end
	local T = F.THEMES[def.theme]
	local layout = LAYOUTS[def.layout]
	if not (T and layout) then error("forge map " .. name .. ": bad theme or layout") end
	local ctx = K.new(name)
	ctx.model:SetAttribute("Theme", def.theme)
	ctx.model:SetAttribute("Layout", def.layout)
	layout(ctx, T, Random.new(def.seed or 1), def)
	return K.finish(ctx)
end

return F
