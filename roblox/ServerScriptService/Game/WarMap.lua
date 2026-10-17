--[[ WAR MAP — the War mode's battlefields (Game ▸ Modes ▸ War), built fresh each round from a theme:
     GameConfig.MODES.War's maps are themes (THEMES below). One layout under every theme:

        z = -380                                                                  z = +380
        [A's camp, trebuchets]   banner 1   2   3   4   banner 5   [B's camp, trebuchets]

     A corridor 210 studs wide (x ±105) where the real fight is, fenced by stakes and an unseen wall;
     beyond it on both flanks, open fields where the armies clash (drawn on each screen by
     War.client with WarFX regiments: never real fighters); each side's archers and battle-mages
     stand out there too; hills all round. The ground is terrain (K.terrain, fast), the rest parts.

     WarMap.build(theme) -> name, layout
       layout.banners     {{id = 1..5, pos}, …} from A's end to B's   layout.radius   a banner's ring
       layout.camps       {A = Vector3, B = Vector3}
       layout.trebuchets  {A = {arm positions}, B = {…}}
       layout.archers     {A = {Vector3, Vector3}, B = {…}}   (one company on each flank)
       layout.mages       {A = Vector3, B = Vector3}
       layout.bounds      {x = 105, z = 372}: the playable corridor
       layout.ballistae   {{model, side}, …}: the ballistae players man (War rigs them)
     The client reads the same off the Map: W_Banner1…5, W_Radius, W_CampA/B, W_TrebA1/2, W_TrebB1/2,
     W_ArchA1/2, W_ArchB1/2, W_MageA/B, W_Lane1…3 (the flank lanes' |x|), W_Weather, W_Theme.

     Made props (ServerStorage ▸ WarProps, Studio-only; each scaled to a height and set on the ground,
     its own Yaw attribute turning it to face the right way; missing ones are simply left out):
     Pavilion (each camp's command tent), SiegeTower (two parked before each camp), Ballista (two at
     each camp's corners), Barricade (spiked logs before the camps, and cover beside banners 2 and 4). ]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local K = require(ServerScriptService:WaitForChild("Build"):WaitForChild("MapKit"))
local WarProps = require(script.Parent:WaitForChild("WarProps"))
if not K.campfire then require(ServerScriptService.Build:WaitForChild("MapProps"))(K) end

local WarMap = {}
local V3, CF, DEG = Vector3.new, CFrame.new, math.rad
local CW, END = 105, 372                 -- the corridor's half-width (x), its ends (z)
local BANNER_Z = {-250, -125, 0, 125, 250}
local CAMP_Z = 330
local RADIUS = 18
local LANES = {134, 180, 226}            -- the flank lanes (|x|) where the armies march (the first just past the stakes)
local TEAM = {A = Color3.fromRGB(56, 92, 206), B = Color3.fromRGB(190, 50, 44)}
local WOOD = Color3.fromRGB(104, 74, 48)
local DARK = Color3.fromRGB(62, 44, 30)
local STONE = Color3.fromRGB(128, 126, 122)
local IRON = Color3.fromRGB(60, 62, 68)
local made = 0
local rnd = Random.new()

--------------------------------------------------------------------
--  THE THEMES
--------------------------------------------------------------------
local M = Enum.Material
local THEMES = {
	Redfield = {
		ground = M.Grass, field = M.LeafyGrass, path = M.Ground, trees = "oak", weather = "",
		colors = {Grass = Color3.fromRGB(104, 142, 64), LeafyGrass = Color3.fromRGB(198, 170, 82), Ground = Color3.fromRGB(122, 98, 70)},
		slab = Color3.fromRGB(104, 142, 64), hill = Color3.fromRGB(88, 126, 58),
		light = {ClockTime = 15.4, Brightness = 2.6, Ambient = Color3.fromRGB(120, 112, 100), OutdoorAmbient = Color3.fromRGB(150, 140, 124),
			FogColor = Color3.fromRGB(214, 204, 182), FogEnd = 1500, FogStart = 200, ExposureCompensation = 0.1, EnvironmentDiffuseScale = 0.7},
		atmo = {Density = 0.3, Offset = 0.2, Haze = 1.6, Glare = 0.5, Color = Color3.fromRGB(222, 206, 178), Decay = Color3.fromRGB(170, 146, 110)},
	},
	Ironridge = {
		ground = M.Grass, field = M.Ground, path = M.Rock, trees = "pine", weather = "rain",
		colors = {Grass = Color3.fromRGB(76, 98, 64), Ground = Color3.fromRGB(96, 88, 76), Rock = Color3.fromRGB(104, 104, 106)},
		slab = Color3.fromRGB(76, 98, 64), hill = Color3.fromRGB(92, 92, 96), rocky = true,
		light = {ClockTime = 13, Brightness = 2, Ambient = Color3.fromRGB(118, 122, 130), OutdoorAmbient = Color3.fromRGB(146, 150, 158),
			FogColor = Color3.fromRGB(170, 176, 186), FogEnd = 1200, FogStart = 160, ExposureCompensation = 0.1, EnvironmentDiffuseScale = 0.6},
		atmo = {Density = 0.32, Offset = 0.15, Haze = 1.5, Glare = 0.1, Color = Color3.fromRGB(184, 190, 200), Decay = Color3.fromRGB(130, 136, 148)},
	},
	Frostmere = {
		ground = M.Snow, field = M.Snow, path = M.Ground, trees = "snowpine", weather = "snow",
		colors = {Snow = Color3.fromRGB(232, 238, 246), Glacier = Color3.fromRGB(170, 210, 236), Ground = Color3.fromRGB(110, 100, 92)},
		slab = Color3.fromRGB(226, 232, 240), hill = Color3.fromRGB(214, 222, 234),
		light = {ClockTime = 9.5, Brightness = 2, Ambient = Color3.fromRGB(130, 140, 158), OutdoorAmbient = Color3.fromRGB(160, 172, 190),
			FogColor = Color3.fromRGB(206, 216, 230), FogEnd = 1000, FogStart = 120, ExposureCompensation = 0, EnvironmentDiffuseScale = 0.7},
		atmo = {Density = 0.4, Offset = 0.15, Haze = 2, Glare = 0.3, Color = Color3.fromRGB(214, 224, 238), Decay = Color3.fromRGB(160, 176, 200)},
	},
	Ashvale = {
		ground = M.Ground, field = M.Mud, path = M.Basalt, trees = "dead", weather = "embers",
		colors = {Ground = Color3.fromRGB(64, 54, 48), Mud = Color3.fromRGB(52, 44, 40), Basalt = Color3.fromRGB(40, 38, 40), CrackedLava = Color3.fromRGB(255, 110, 40)},
		slab = Color3.fromRGB(60, 50, 44), hill = Color3.fromRGB(54, 46, 42),
		light = {ClockTime = 17.4, Brightness = 2.2, Ambient = Color3.fromRGB(136, 100, 84), OutdoorAmbient = Color3.fromRGB(160, 116, 92),
			FogColor = Color3.fromRGB(176, 108, 74), FogEnd = 1300, FogStart = 160, ExposureCompensation = 0.15, EnvironmentDiffuseScale = 0.6},
		atmo = {Density = 0.3, Offset = 0.2, Haze = 1.4, Glare = 0.5, Color = Color3.fromRGB(214, 150, 108), Decay = Color3.fromRGB(150, 84, 58)},
	},
	Kingsbridge = {
		ground = M.Grass, field = M.Grass, path = M.Cobblestone, trees = "oak", weather = "",
		colors = {Grass = Color3.fromRGB(90, 150, 70), Cobblestone = Color3.fromRGB(130, 126, 118), Mud = Color3.fromRGB(84, 62, 42)},
		slab = Color3.fromRGB(90, 150, 70), hill = Color3.fromRGB(80, 136, 62),
		light = {ClockTime = 8.2, Brightness = 2.2, Ambient = Color3.fromRGB(116, 118, 124), OutdoorAmbient = Color3.fromRGB(150, 150, 150),
			FogColor = Color3.fromRGB(200, 210, 220), FogEnd = 1300, FogStart = 150, ExposureCompensation = 0.05, EnvironmentDiffuseScale = 0.7},
		atmo = {Density = 0.34, Offset = 0.2, Haze = 1.8, Glare = 0.3, Color = Color3.fromRGB(206, 214, 224), Decay = Color3.fromRGB(150, 160, 176)},
	},
	Nightfall = {
		ground = M.Grass, field = M.Ground, path = M.Ground, trees = "pine", weather = "",
		colors = {Grass = Color3.fromRGB(54, 74, 52), Ground = Color3.fromRGB(70, 62, 54)},
		slab = Color3.fromRGB(46, 62, 44), hill = Color3.fromRGB(40, 50, 46),
		light = {ClockTime = 23.6, Brightness = 0.9, Ambient = Color3.fromRGB(70, 80, 112), OutdoorAmbient = Color3.fromRGB(84, 96, 130),
			FogColor = Color3.fromRGB(30, 36, 58), FogEnd = 800, FogStart = 120, ExposureCompensation = 0.35, EnvironmentDiffuseScale = 0.5},
		atmo = {Density = 0.34, Offset = 0.1, Haze = 1.4, Glare = 0, Color = Color3.fromRGB(86, 98, 140), Decay = Color3.fromRGB(42, 48, 76)},
	},
	Sunreach = {
		ground = M.Sand, field = M.Sandstone, path = M.Ground, trees = "dead", weather = "",
		colors = {Sand = Color3.fromRGB(222, 192, 136), Sandstone = Color3.fromRGB(198, 160, 110), Ground = Color3.fromRGB(166, 128, 90)},
		slab = Color3.fromRGB(216, 186, 132), hill = Color3.fromRGB(196, 150, 100), rocky = true,
		light = {ClockTime = 12.8, Brightness = 3, Ambient = Color3.fromRGB(140, 122, 104), OutdoorAmbient = Color3.fromRGB(176, 154, 128),
			FogColor = Color3.fromRGB(232, 210, 172), FogEnd = 1500, FogStart = 220, ExposureCompensation = 0, EnvironmentDiffuseScale = 0.7},
		atmo = {Density = 0.28, Offset = 0.2, Haze = 1.2, Glare = 0.4, Color = Color3.fromRGB(236, 210, 166), Decay = Color3.fromRGB(196, 150, 104)},
	},
	-- STORMVALE: a ruined abbey in a storm, its arches and graves on a wet green
	Stormvale = {
		ground = M.Grass, field = M.Mud, path = M.Cobblestone, trees = "oak", weather = "storm",
		colors = {Grass = Color3.fromRGB(70, 104, 62), Mud = Color3.fromRGB(78, 66, 52), Cobblestone = Color3.fromRGB(110, 110, 112)},
		slab = Color3.fromRGB(68, 100, 60), hill = Color3.fromRGB(60, 88, 58),
		light = {ClockTime = 16.6, Brightness = 1.4, Ambient = Color3.fromRGB(96, 104, 116), OutdoorAmbient = Color3.fromRGB(118, 126, 140),
			FogColor = Color3.fromRGB(110, 118, 132), FogEnd = 900, FogStart = 120, ExposureCompensation = 0.2, EnvironmentDiffuseScale = 0.5},
		atmo = {Density = 0.42, Offset = 0.1, Haze = 2.2, Glare = 0, Color = Color3.fromRGB(128, 136, 150), Decay = Color3.fromRGB(80, 86, 100)},
	},
	-- DUSKMOOR: purple heather under a red sunset, a ring of cairns, a beacon burning
	Duskmoor = {
		ground = M.Grass, field = M.LeafyGrass, path = M.Ground, trees = "dead", weather = "",
		colors = {Grass = Color3.fromRGB(104, 84, 96), LeafyGrass = Color3.fromRGB(122, 86, 120), Ground = Color3.fromRGB(96, 76, 62)},
		slab = Color3.fromRGB(100, 80, 92), hill = Color3.fromRGB(88, 70, 84),
		light = {ClockTime = 17.35, Brightness = 2.6, Ambient = Color3.fromRGB(140, 110, 112), OutdoorAmbient = Color3.fromRGB(176, 132, 122),
			FogColor = Color3.fromRGB(214, 140, 110), FogEnd = 1400, FogStart = 200, ExposureCompensation = 0.25, EnvironmentDiffuseScale = 0.7},
		atmo = {Density = 0.33, Offset = 0.2, Haze = 1.8, Glare = 0.8, Color = Color3.fromRGB(230, 150, 120), Decay = Color3.fromRGB(150, 70, 80)},
	},
	-- MISTMARSH: a fog-bound marsh at dawn, a stone causeway across it, reeds and standing water,
	-- a chapel half sunk into the bog
	Mistmarsh = {
		ground = M.Grass, field = M.Mud, path = M.Cobblestone, trees = "dead", weather = "",
		colors = {Grass = Color3.fromRGB(86, 102, 74), Mud = Color3.fromRGB(70, 66, 52), Cobblestone = Color3.fromRGB(112, 112, 106)},
		slab = Color3.fromRGB(80, 96, 70), hill = Color3.fromRGB(74, 88, 68),
		light = {ClockTime = 7.2, Brightness = 1.5, Ambient = Color3.fromRGB(110, 118, 120), OutdoorAmbient = Color3.fromRGB(140, 146, 146),
			FogColor = Color3.fromRGB(176, 186, 184), FogEnd = 420, FogStart = 40, ExposureCompensation = 0.25, EnvironmentDiffuseScale = 0.5},
		atmo = {Density = 0.55, Offset = 0.05, Haze = 3, Glare = 0.2, Color = Color3.fromRGB(196, 204, 200), Decay = Color3.fromRGB(120, 132, 130)},
	},
	-- AMBERWOOD: an autumn wood's edge in the late gold light, the field between two lines of red and
	-- gold oaks, fallen leaves drifting down, an orchard, a hunting lodge, a woodcutters' camp
	Amberwood = {
		ground = M.Grass, field = M.LeafyGrass, path = M.Ground, trees = "autumn", weather = "leaves",
		colors = {Grass = Color3.fromRGB(124, 120, 62), LeafyGrass = Color3.fromRGB(172, 98, 46), Ground = Color3.fromRGB(112, 86, 60)},
		slab = Color3.fromRGB(120, 114, 60), hill = Color3.fromRGB(132, 96, 54),
		light = {ClockTime = 16.4, Brightness = 2.4, Ambient = Color3.fromRGB(132, 112, 92), OutdoorAmbient = Color3.fromRGB(164, 138, 108),
			FogColor = Color3.fromRGB(226, 180, 130), FogEnd = 1300, FogStart = 180, ExposureCompensation = 0.15, EnvironmentDiffuseScale = 0.7},
		atmo = {Density = 0.34, Offset = 0.2, Haze = 1.9, Glare = 0.6, Color = Color3.fromRGB(236, 190, 140), Decay = Color3.fromRGB(180, 110, 70)},
	},
}
WarMap.THEMES = THEMES

--------------------------------------------------------------------
--  PIECES
--------------------------------------------------------------------
local function nocol(p) p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; return p end
local debris   -- (the litter of earlier fighting: below)

-- a line of sharpened stakes leaning out (cheap: one part a stake)
local function stakes(ctx, a, b, gap, lean)
	local d = b - a
	local n = math.max(1, math.floor(d.Magnitude / (gap or 5)))
	local out = d.Unit:Cross(Vector3.yAxis)
	for i = 0, n do
		local p = a + d * (i / n)
		K.box(ctx, "Stake", V3(0.6, 5.5, 0.6), CFrame.lookAt(p, p + out) * CF(0, 2.2, 0) * CFrame.Angles(DEG(lean or -30), 0, 0), DARK, M.Wood, ctx.Props)
	end
end

-- an unseen wall (the corridor's edge, the field's ends)
local function wall(ctx, cf, size)
	local w = K.box(ctx, "Bound", size, cf, Color3.new(), M.SmoothPlastic, ctx.Geometry)
	w.Transparency = 1
	w.CastShadow = false
	return w
end

-- a timber trebuchet, if the made one is missing (ServerStorage ▸ PrologueProps ▸ Trebuchet)
local function timberTrebuchet(ctx, pos, yaw)
	local f = CF(pos) * CFrame.Angles(0, yaw, 0)
	for _, s in ipairs({-1, 1}) do
		K.box(ctx, "TrebBase", V3(1.4, 1.4, 16), f * CF(s * 4, 0.7, 0), DARK, M.Wood, ctx.Props)
		K.box(ctx, "TrebA", V3(1.2, 16, 1.2), f * CF(s * 3, 7.5, 2) * CFrame.Angles(DEG(14), 0, 0), WOOD, M.Wood, ctx.Props)
		K.box(ctx, "TrebA", V3(1.2, 16, 1.2), f * CF(s * 3, 7.5, -2) * CFrame.Angles(DEG(-14), 0, 0), WOOD, M.Wood, ctx.Props)
	end
	K.box(ctx, "TrebAxle", V3(8, 1, 1), f * CF(0, 15, 0), IRON, M.Metal, ctx.Props)
	K.box(ctx, "TrebArm", V3(1.2, 1.2, 26), f * CF(0, 17, 4) * CFrame.Angles(DEG(-30), 0, 0), WOOD, M.Wood, ctx.Props)
	K.box(ctx, "TrebWeight", V3(5, 5, 5), f * CF(0, 11, -6), DARK, M.WoodPlanks, ctx.Props)
end
local function trebuchet(ctx, pos, yaw)
	local props = ServerStorage:FindFirstChild("PrologueProps")
	local tpl = props and props:FindFirstChild("Trebuchet")
	if not tpl then timberTrebuchet(ctx, pos, yaw); return pos + V3(0, 22, 0) end
	local m = tpl:Clone()
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
	m.Parent = ctx.Props
	local cf, size = m:GetBoundingBox()
	m:PivotTo(CF(pos + V3(0, size.Y / 2 - (cf.Position.Y - m:GetPivot().Position.Y), 0)) * CFrame.Angles(0, yaw, 0))
	return pos + V3(0, size.Y * 0.85, 0)
end

local AUTUMN = {Color3.fromRGB(206, 112, 40), Color3.fromRGB(172, 60, 36), Color3.fromRGB(214, 166, 58), Color3.fromRGB(150, 92, 42)}
local function tree(ctx, kind, pos)
	if kind == "oak" then K.oak(ctx, pos, 12 + rnd:NextNumber(0, 8))
	elseif kind == "autumn" then
		-- (red, rust and gold; now and then one already bare)
		if rnd:NextNumber() < 0.12 then K.deadTree(ctx, pos, 10 + rnd:NextNumber(0, 6))
		else
			local i = rnd:NextInteger(1, #AUTUMN)
			K.oak(ctx, pos, 12 + rnd:NextNumber(0, 9), {AUTUMN[i], AUTUMN[i % #AUTUMN + 1], AUTUMN[i]})
		end
	elseif kind == "pine" then K.pine2(ctx, pos, 16 + rnd:NextNumber(0, 10), 3, 5)
	elseif kind == "snowpine" then K.pine2(ctx, pos, 16 + rnd:NextNumber(0, 10), 3, 5, Color3.fromRGB(196, 210, 206))
	else K.deadTree(ctx, pos, 10 + rnd:NextNumber(0, 8)) end
end

-- a made prop (Game ▸ WarProps): nil when there's none
local function prop(ctx, name, cf, height, collide) return WarProps.place(name, cf, height, ctx.Props, collide) end

-- A BANNER: a stone plinth, a tall pole, a flag the clients colour for its holder (WarFlag_n),
-- a ring of stones marking how near you must stand
local function banner(ctx, i, pos)
	K.cyl(ctx, "Plinth", 7, 1.4, CF(pos + V3(0, 0.7, 0)), STONE, M.Slate, ctx.Props)
	K.cyl(ctx, "BannerPole", 0.7, 26, pos + V3(0, 13, 0), DARK, M.Wood, ctx.Props)
	K.ball(ctx, "BannerFinial", 1.4, pos + V3(0, 26.5, 0), Color3.fromRGB(222, 180, 70), M.Metal, ctx.Props)
	local flag = K.box(ctx, "WarFlag_" .. i, V3(0.2, 7, 10), CF(pos + V3(0, 21.5, 5.4)), Color3.fromRGB(226, 222, 210), M.Fabric, ctx.Props)
	nocol(flag)
	for k = 1, 12 do
		local a = k / 12 * math.pi * 2
		local r = K.ball(ctx, "RingStone", 1.6 + rnd:NextNumber(0, 0.8), pos + V3(math.cos(a) * RADIUS, 0.3, math.sin(a) * RADIUS), Color3.fromRGB(150, 146, 138), M.Slate, ctx.Props)
		r.Size = V3(r.Size.X, r.Size.Y * 0.6, r.Size.Z)
		nocol(r)
	end
end

-- A CAMP: tents in rows, fires, racks, the side's banners, stakes behind
local function camp(ctx, side)
	local f = side == "A" and -1 or 1          -- which end of the field
	local z0 = f * CAMP_Z
	local col = TEAM[side]
	local face = CFrame.lookAt(V3(0, 0, z0), V3(0, 0, 0))
	for row = 0, 1 do
		for i = -3, 3 do
			if i ~= 0 then
				local at = V3(i * 22 + rnd:NextNumber(-3, 3), 0, z0 + f * (24 + row * 18))
				K.tent(ctx, CF(at) * CFrame.Angles(0, (row == 0 and 0 or math.pi / 2) + rnd:NextNumber(-0.2, 0.2), 0), 9, 11, 7,
					(i + row) % 2 == 0 and col:Lerp(Color3.new(1, 1, 1), 0.55) or Color3.fromRGB(214, 204, 184))
			end
		end
	end
	-- the command tent (the made pavilion, else a big tent in the side's colour)
	if not prop(ctx, "Pavilion", CFrame.lookAt(V3(0, 0, z0 + f * 30), V3(0, 0, 0)), 18) then
		K.tent(ctx, CF(V3(0, 0, z0 + f * 30)), 14, 18, 10, col)
	end
	-- siege towers parked before the camp, ballistae at its corners, a line of barricades
	for _, x in ipairs({-46, 46}) do prop(ctx, "SiegeTower", CFrame.lookAt(V3(x, 0, z0 - f * 34), V3(x, 0, 0)), 32) end
	for _, x in ipairs({-88, 88}) do prop(ctx, "Ballista", CFrame.lookAt(V3(x, 0, z0 - f * 12), V3(x * 0.5, 0, 0)), 7) end
	for _, x in ipairs({-72, -24, 24, 72}) do prop(ctx, "Barricade", CFrame.lookAt(V3(x, 0, z0 - f * 52), V3(x, 0, z0 - f * 60)), 4.5) end
	for _, x in ipairs({-30, 30}) do pcall(K.campfire, ctx, V3(x, 0, z0 + f * 8)) end
	for _, x in ipairs({-48, 48}) do pcall(K.rack, ctx, CF(x, 0, z0 + f * 2) * CFrame.Angles(0, math.pi / 2, 0)) end
	for _, x in ipairs({-64, -22, 22, 64}) do K.banner(ctx, V3(x, 0, z0 - f * 6), 16, col) end
	for _ = 1, 8 do K.crate(ctx, V3(rnd:NextNumber(-80, 80), 0, z0 + f * rnd:NextNumber(10, 46)), 2.4 + rnd:NextNumber(0, 1.2), rnd:NextNumber(0, 90)) end
	for _ = 1, 6 do K.barrel(ctx, V3(rnd:NextNumber(-80, 80), 0, z0 + f * rnd:NextNumber(10, 46))) end
	-- stakes across the back, and before the camp a gap-toothed line
	stakes(ctx, V3(-CW + 4, 0, z0 + f * 48), V3(CW - 4, 0, z0 + f * 48), 4, f > 0 and 30 or -30)
	for _, x in ipairs({-80, -50, 50, 80}) do stakes(ctx, V3(x - 10, 0, z0 - f * 22), V3(x + 10, 0, z0 - f * 22), 3, f > 0 and -30 or 30) end
	-- where they come in
	for i = -3, 3 do K.spawn(ctx, V3(i * 12, 1, z0 - f * 4), side, V3(i * 12, 1, 0)) end
	return V3(0, 0, z0)
end

-- A MAGE CIRCLE: standing stones, glowing runes between them
local function mageCircle(ctx, pos, col)
	for k = 1, 7 do
		local a = k / 7 * math.pi * 2
		local h = 9 + rnd:NextNumber(0, 5)
		K.box(ctx, "Monolith", V3(2.6, h, 1.6), CF(pos + V3(math.cos(a) * 14, h / 2 - 0.5, math.sin(a) * 14)) * CFrame.Angles(0, -a, DEG(rnd:NextNumber(-4, 4))), Color3.fromRGB(96, 96, 102), M.Slate, ctx.Props)
		local rune = nocol(K.box(ctx, "Rune", V3(0.2, 2.4, 0.8), CF(pos + V3(math.cos(a) * 13.1, 4, math.sin(a) * 13.1)) * CFrame.Angles(0, -a, 0), col:Lerp(Color3.new(1, 1, 1), 0.4), M.Neon, ctx.Props))
		rune.Transparency = 0.2
	end
	local core = nocol(K.cyl(ctx, "Sigil", 18, 0.15, CF(pos + V3(0, 0.1, 0)), col:Lerp(Color3.new(1, 1, 1), 0.3), M.Neon, ctx.Props))
	core.Transparency = 0.6
	local l = Instance.new("PointLight"); l.Color = col; l.Range = 30; l.Brightness = 2; l.Parent = core
end

--------------------------------------------------------------------
--  EACH THEME'S OWN PLACE (round banner 3, the middle of the field)
--------------------------------------------------------------------
-- THE LITTER OF EARLIER FIGHTING, on every field: dropped shields, broken spears, arrows stuck in
-- the ground in clusters, a fallen banner or two, a helmet; thickest round the banners, nothing
-- solid (only looks: nobody trips on it)
local SHIELD = {Color3.fromRGB(56, 92, 206), Color3.fromRGB(190, 50, 44), Color3.fromRGB(120, 92, 62)}
function debris(ctx)
	local function spot()
		-- (round a banner, or anywhere down the corridor)
		if rnd:NextNumber(0, 1) < 0.55 then
			local bz = BANNER_Z[rnd:NextInteger(1, #BANNER_Z)]
			local a, d = rnd:NextNumber(0, math.pi * 2), rnd:NextNumber(RADIUS + 2, RADIUS + 40)
			return V3(math.cos(a) * d, 0, bz + math.sin(a) * d)
		end
		return V3(rnd:NextNumber(-CW + 8, CW - 8), 0, rnd:NextNumber(-END + 60, END - 60))
	end
	for _ = 1, 26 do
		local at = spot()
		local col = SHIELD[rnd:NextInteger(1, #SHIELD)]
		nocol(K.cyl(ctx, "DroppedShield", rnd:NextNumber(2.4, 3), 0.3, CF(at + V3(0, 0.12, 0)) * CFrame.Angles(DEG(rnd:NextNumber(-10, 10)), rnd:NextNumber(0, 6), DEG(rnd:NextNumber(-10, 10))), col, M.Wood, ctx.Props))
	end
	for _ = 1, 22 do
		local at = spot()
		local len = rnd:NextNumber(3, 7)
		nocol(K.cyl(ctx, "BrokenSpear", 0.25, len, CF(at + V3(0, 0.15, 0)) * CFrame.Angles(0, rnd:NextNumber(0, 6), 0) * CFrame.Angles(DEG(88), 0, 0), DARK, M.Wood, ctx.Props))
	end
	for _ = 1, 18 do
		-- a cluster of arrows stuck in the ground, all leaning the way they came
		local at = spot()
		local lean = CFrame.Angles(DEG(rnd:NextNumber(20, 35)), rnd:NextNumber(0, 6), 0)
		for _ = 1, rnd:NextInteger(4, 9) do
			local p = at + V3(rnd:NextNumber(-3, 3), 0, rnd:NextNumber(-3, 3))
			local cf = CF(p) * lean * CF(0, 1.2, 0)
			nocol(K.box(ctx, "SpentArrow", V3(0.12, 2.6, 0.12), cf, Color3.fromRGB(96, 74, 52), M.Wood, ctx.Props))
			nocol(K.box(ctx, "SpentFletch", V3(0.05, 0.6, 0.3), cf * CF(0, 1.1, 0), Color3.fromRGB(226, 220, 206), M.SmoothPlastic, ctx.Props))
		end
	end
	for _ = 1, 6 do
		local at = spot()
		local col = SHIELD[rnd:NextInteger(1, 2)]
		nocol(K.box(ctx, "FallenBanner", V3(2.6, 0.1, 3.8), CF(at + V3(0, 0.06, 0)) * CFrame.Angles(0, rnd:NextNumber(0, 6), 0), col, M.Fabric, ctx.Props))
		nocol(K.cyl(ctx, "FallenPole", 0.3, 9, CF(at + V3(0, 0.2, 0)) * CFrame.Angles(0, rnd:NextNumber(0, 6), 0) * CFrame.Angles(DEG(89), 0, 0), DARK, M.Wood, ctx.Props))
	end
	for _ = 1, 10 do
		local at = spot()
		nocol(K.ball(ctx, "DroppedHelm", 1.3, CF(at + V3(0, 0.4, 0)) * CFrame.Angles(rnd:NextNumber(-1, 1), rnd:NextNumber(0, 6), rnd:NextNumber(-1, 1)), Color3.fromRGB(150, 152, 158), M.Metal, ctx.Props))
	end
end

local FEATURE = {}
-- REDFIELD: a farming village, a windmill, haystacks, wagons, fences
function FEATURE.Redfield(ctx)
	local houses = {{-62, 30, 0}, {-70, -36, 90}, {58, 44, -90}, {66, -28, 0}, {-36, 70, 90}, {40, -72, 0}, {-30, -78, 90}}
	for _, h in ipairs(houses) do
		K.house(ctx, CF(h[1], 0, h[2]) * CFrame.Angles(0, DEG(h[3]), 0), 14, 18, 9, Color3.fromRGB(226, 214, 190), Color3.fromRGB(150, 96, 56))
	end
	-- the windmill
	local mill = V3(-78, 0, 92)
	K.cyl(ctx, "MillBody", 14, 26, mill + V3(0, 13, 0), Color3.fromRGB(214, 204, 186), M.Concrete, ctx.Props)
	for k = 0, 3 do
		K.box(ctx, "MillSail", V3(1, 22, 4), CF(mill + V3(0, 24, 7.6)) * CFrame.Angles(0, 0, DEG(k * 90 + 20)) * CF(0, 11, 0), Color3.fromRGB(224, 216, 196), M.Fabric, ctx.Props)
	end
	for _ = 1, 16 do K.hay(ctx, V3(rnd:NextNumber(-90, 90), 0, rnd:NextNumber(-200, 200))) end
	pcall(K.wagon, ctx, CF(24, 0, 36) * CFrame.Angles(0, DEG(30), 0))
	pcall(K.wagon, ctx, CF(-20, 0, -40) * CFrame.Angles(0, DEG(-60), 0))
	K.fence(ctx, V3(-100, 0, 110), V3(-40, 0, 110))
	K.fence(ctx, V3(40, 0, -110), V3(100, 0, -110))
	K.fence(ctx, V3(30, 0, 150), V3(90, 0, 160))
	-- the well
	K.cyl(ctx, "Well", 5, 3, V3(14, 1.5, -18), STONE, M.Slate, ctx.Props)
end
-- IRONRIDGE: a ruined fort on a rise in the middle, rocks everywhere
function FEATURE.Ironridge(ctx)
	local h = 7
	local half = 32
	local function seg(a, b) K.wall(ctx, a + V3(0, h, 0), b + V3(0, h, 0), 9 + rnd:NextNumber(0, 5), 4, {color = Color3.fromRGB(112, 110, 106), material = M.Slate}) end
	-- (broken: gaps in every face)
	seg(V3(-half, 0, -half), V3(-10, 0, -half)); seg(V3(12, 0, -half), V3(half, 0, -half))
	seg(V3(-half, 0, half), V3(-14, 0, half)); seg(V3(8, 0, half), V3(half, 0, half))
	seg(V3(-half, 0, -half), V3(-half, 0, -6)); seg(V3(-half, 0, 10), V3(-half, 0, half))
	seg(V3(half, 0, -half), V3(half, 0, -12)); seg(V3(half, 0, 6), V3(half, 0, half))
	K.tower(ctx, V3(half, h, half), 7, 18, {crenels = true})
	K.tower(ctx, V3(-half, h, -half), 7, 12, {crenels = true})
	for _ = 1, 30 do
		local s = 1 + rnd:NextNumber(0, 2.5)
		K.box(ctx, "Rubble", V3(s, s * 0.7, s * 1.2), CF(rnd:NextNumber(-44, 44), h + s * 0.3, rnd:NextNumber(-44, 44)) * CFrame.Angles(rnd:NextNumber(0, 1), rnd:NextNumber(0, 6), rnd:NextNumber(0, 1)), Color3.fromRGB(108, 106, 102), M.Slate, ctx.Props)
	end
	for _ = 1, 26 do K.rock(ctx, V3(rnd:NextNumber(-95, 95), 0, rnd:NextNumber(-340, 340)), 3 + rnd:NextNumber(0, 5), Color3.fromRGB(98, 98, 100)) end
end
-- FROSTMERE: a frozen lake in the middle, a fishing hut on it, snowy rocks
function FEATURE.Frostmere(ctx)
	K.house(ctx, CF(-40, 0, 14) * CFrame.Angles(0, DEG(20), 0), 8, 10, 6, Color3.fromRGB(120, 92, 70), Color3.fromRGB(226, 232, 240))
	for _ = 1, 18 do K.rock(ctx, V3(rnd:NextNumber(-95, 95), 0, rnd:NextNumber(-340, 340)), 3 + rnd:NextNumber(0, 4), Color3.fromRGB(196, 204, 214)) end
	for _ = 1, 10 do tree(ctx, "snowpine", V3(rnd:NextNumber(-95, 95), 0, rnd:NextNumber(-340, 340))) end
end
-- ASHVALE: burnt farmsteads still burning, dead trees, cracks of fire in the ground
function FEATURE.Ashvale(ctx)
	for _, h in ipairs({{-60, 24, 10}, {64, -30, -20}, {-40, -70, 80}, {50, 80, 0}}) do
		K.house(ctx, CF(h[1], 0, h[2]) * CFrame.Angles(0, DEG(h[3]), 0), 14, 16, 8, Color3.fromRGB(70, 60, 54), Color3.fromRGB(34, 28, 26))
		local f = nocol(K.box(ctx, "Blaze", V3(12, 2, 14), CF(h[1], 9, h[2]), Color3.fromRGB(255, 120, 40), M.Neon, ctx.Props))
		f.Transparency = 0.75
		local fire = Instance.new("Fire"); fire.Size = 14; fire.Heat = 12; fire.Color = Color3.fromRGB(255, 130, 40); fire.SecondaryColor = Color3.fromRGB(190, 40, 10); fire.Parent = f
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 120, 50); l.Range = 40; l.Brightness = 2; l.Parent = f
	end
	for _ = 1, 22 do K.rock(ctx, V3(rnd:NextNumber(-95, 95), 0, rnd:NextNumber(-340, 340)), 2 + rnd:NextNumber(0, 3), Color3.fromRGB(46, 42, 42)) end
end
-- KINGSBRIDGE: a river across the middle, two stone bridges and a ford, a chapel by the bank
function FEATURE.Kingsbridge(ctx)
	for _, x in ipairs({-56, 56}) do
		local b = CF(x, 0, 0)
		K.box(ctx, "BridgeDeck", V3(16, 1.2, 44), b * CF(0, 1.2, 0), Color3.fromRGB(134, 130, 122), M.Cobblestone)
		for _, s in ipairs({-1, 1}) do
			K.box(ctx, "BridgeRail", V3(1.2, 2.4, 44), b * CF(s * 7.4, 3, 0), Color3.fromRGB(120, 116, 110), M.Slate, ctx.Props)
			K.wedge(ctx, "BridgeRamp", V3(16, 1.8, 8), b * CF(0, 0.9, s * 26) * CFrame.Angles(0, s > 0 and math.pi or 0, 0), Color3.fromRGB(134, 130, 122), M.Cobblestone)
		end
		for _, z in ipairs({-10, 10}) do K.box(ctx, "BridgePier", V3(12, 6, 3), b * CF(0, -2.4, z), Color3.fromRGB(110, 106, 100), M.Slate, ctx.Props) end
	end
	-- the chapel on the far bank
	K.house(ctx, CF(-86, 0, 60) * CFrame.Angles(0, DEG(90), 0), 14, 24, 12, Color3.fromRGB(214, 206, 190), Color3.fromRGB(70, 74, 86))
	K.tower(ctx, V3(-86, 0, 76), 5, 24, {roof = true})
	for _ = 1, 12 do K.bush(ctx, V3(rnd:NextNumber(-100, 100), 0, (rnd:NextNumber(0, 1) < 0.5 and -1 or 1) * rnd:NextNumber(24, 40)), 3 + rnd:NextNumber(0, 2)) end
end

-- NIGHTFALL: a watchtower burning in the middle, torches lining the field, standing stones
function FEATURE.Nightfall(ctx)
	K.tower(ctx, V3(-30, 0, 18), 6, 22, {crenels = true})
	local blaze = nocol(K.box(ctx, "Blaze", V3(10, 2, 10), CF(-30, 23, 18), Color3.fromRGB(255, 120, 40), M.Neon, ctx.Props))
	blaze.Transparency = 0.7
	local fire = Instance.new("Fire"); fire.Size = 16; fire.Heat = 14; fire.Color = Color3.fromRGB(255, 130, 40); fire.SecondaryColor = Color3.fromRGB(190, 40, 10); fire.Parent = blaze
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 130, 60); l.Range = 60; l.Brightness = 2.5; l.Parent = blaze
	for z = -330, 330, 44 do
		for _, x in ipairs({-98, 98}) do K.torchPost(ctx, V3(x, 0, z), 7) end
	end
	for _, z in ipairs({-125, 0, 125}) do pcall(K.campfire, ctx, V3(rnd:NextNumber(-20, 20), 0, z + (rnd:NextNumber(0, 1) < 0.5 and -26 or 26))) end
	for k = 1, 9 do
		local a = k / 9 * math.pi * 2
		local h = 8 + rnd:NextNumber(0, 5)
		K.box(ctx, "Stone", V3(2.4, h, 1.6), CF(60 + math.cos(a) * 14, h / 2 - 0.5, -60 + math.sin(a) * 14) * CFrame.Angles(0, -a, 0), Color3.fromRGB(96, 98, 104), M.Slate, ctx.Props)
	end
end
-- STORMVALE: a ruined abbey in the middle (broken walls and arches, a roofless nave), its
-- graveyard, a lychgate, toppled stones
function FEATURE.Stormvale(ctx)
	local STONE2 = Color3.fromRGB(120, 118, 114)
	local function seg(a, b, h) K.wall(ctx, a, b, h, 3, {color = STONE2, material = M.Slate}) end
	-- the nave: two long walls with gaps, the east end with its arch standing
	seg(V3(-14, 0, -40), V3(-14, 0, -12), 14); seg(V3(-14, 0, 4), V3(-14, 0, 30), 11)
	seg(V3(14, 0, -40), V3(14, 0, -22), 9); seg(V3(14, 0, -6), V3(14, 0, 30), 14)
	pcall(K.arch, ctx, CF(0, 0, 32), 22, 20, 3, STONE2, M.Slate)
	seg(V3(-14, 0, -40), V3(-4, 0, -40), 16); seg(V3(4, 0, -40), V3(14, 0, -40), 12)
	for k = 0, 4 do
		local z = -32 + k * 14
		for _, x in ipairs({-7, 7}) do
			local h = (k + (x > 0 and 1 or 0)) % 3 == 0 and rnd:NextNumber(3, 6) or rnd:NextNumber(12, 16)
			K.cyl(ctx, "Pillar", 2.4, h, V3(x, h / 2, z), STONE2, M.Slate)
		end
	end
	for _ = 1, 24 do
		local s = 1 + rnd:NextNumber(0, 2.2)
		K.box(ctx, "Rubble", V3(s, s * 0.7, s * 1.2), CF(rnd:NextNumber(-30, 30), s * 0.3, rnd:NextNumber(-50, 44)) * CFrame.Angles(rnd:NextNumber(0, 1), rnd:NextNumber(0, 6), rnd:NextNumber(0, 1)), STONE2, M.Slate, ctx.Props)
	end
	-- the graveyard on both sides of the road, headstones leaning
	for _, s in ipairs({-1, 1}) do
		for row = 0, 3 do
			for col = 0, 4 do
				local at = V3(s * (36 + col * 6), 0, 60 + row * 7 + rnd:NextNumber(-1, 1))
				K.box(ctx, "Headstone", V3(2, 3 + rnd:NextNumber(0, 1), 0.6), CF(at + V3(0, 1.4, 0)) * CFrame.Angles(DEG(rnd:NextNumber(-12, 12)), 0, DEG(rnd:NextNumber(-8, 8))), Color3.fromRGB(128, 128, 126), M.Slate, ctx.Props)
			end
		end
	end
	for _ = 1, 16 do K.rock(ctx, V3(rnd:NextNumber(-95, 95), 0, rnd:NextNumber(-340, 340)), 2 + rnd:NextNumber(0, 4), Color3.fromRGB(100, 102, 104)) end
end
-- DUSKMOOR: a ring of cairns on a rise, a beacon burning on the tallest, wind-bent trees
function FEATURE.Duskmoor(ctx)
	for k = 1, 8 do
		local a = k / 8 * math.pi * 2
		local at = V3(math.cos(a) * 30, 0, math.sin(a) * 30)
		local h = 0
		for tier = 0, 3 do
			local s = 6 - tier * 1.3
			K.box(ctx, "Cairn", V3(s, 1.6, s), CF(at + V3(0, h + 0.8, 0)) * CFrame.Angles(0, rnd:NextNumber(0, 6), 0), Color3.fromRGB(110, 102, 98), M.Slate, ctx.Props)
			h += 1.6
		end
	end
	-- the beacon: a tall cairn with a fire on top
	local bh = 0
	for tier = 0, 6 do
		local s = 9 - tier * 1.1
		K.box(ctx, "Cairn", V3(s, 2, s), CF(0, bh + 1, -70) * CFrame.Angles(0, tier * 0.4, 0), Color3.fromRGB(104, 96, 92), M.Slate, ctx.Props)
		bh += 2
	end
	local blaze = nocol(K.box(ctx, "Blaze", V3(4, 2, 4), CF(0, bh + 1, -70), Color3.fromRGB(255, 120, 40), M.Neon, ctx.Props))
	blaze.Transparency = 0.6
	local fire = Instance.new("Fire"); fire.Size = 12; fire.Heat = 14; fire.Color = Color3.fromRGB(255, 130, 40); fire.SecondaryColor = Color3.fromRGB(190, 40, 10); fire.Parent = blaze
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 130, 60); l.Range = 50; l.Brightness = 2.2; l.Parent = blaze
	for _ = 1, 20 do K.rock(ctx, V3(rnd:NextNumber(-95, 95), 0, rnd:NextNumber(-340, 340)), 2 + rnd:NextNumber(0, 4), Color3.fromRGB(96, 88, 86)) end
end
-- MISTMARSH: a raised causeway of old stone down the middle, standing water and reed beds on the
-- flanks, a chapel half sunk into the bog (its tower leaning), dead trees, mossy stones
function FEATURE.Mistmarsh(ctx)
	local STONE = Color3.fromRGB(112, 112, 106)
	local WATER = Color3.fromRGB(52, 64, 60)
	-- the causeway: a low stone road with kerbs, broken in places
	for z = -330, 330, 22 do
		if rnd:NextNumber() > 0.12 then
			K.box(ctx, "Causeway", V3(12, 1, 20), CF(0, 0.5, z), STONE, M.Cobblestone)
			for _, s in ipairs({-1, 1}) do
				if rnd:NextNumber() > 0.25 then K.box(ctx, "Kerb", V3(1, 1.4, 20), CF(s * 6.5, 0.9, z) * CFrame.Angles(0, 0, s * rnd:NextNumber(-0.05, 0.05)), Color3.fromRGB(96, 98, 92), M.Slate, ctx.Props) end
			end
		end
	end
	-- standing water on the flanks: still sheets over the mud (walkable: they're only the surface)
	for _ = 1, 26 do
		local s = rnd:NextNumber(10, 26)
		local x = (rnd:NextNumber() < 0.5 and -1 or 1) * rnd:NextNumber(20, 110)
		local pool = nocol(K.box(ctx, "Marshwater", V3(s, 0.08, s * rnd:NextNumber(0.6, 1)), CF(x, 0.06, rnd:NextNumber(-330, 330)) * CFrame.Angles(0, rnd:NextNumber(0, 6), 0), WATER, M.Glass, ctx.Props))
		pool.Transparency, pool.Reflectance = 0.2, 0.25
	end
	-- reed beds round the water
	local REED = Color3.fromRGB(150, 140, 92)
	for _ = 1, 60 do
		local c = V3((rnd:NextNumber() < 0.5 and -1 or 1) * rnd:NextNumber(16, 115), 0, rnd:NextNumber(-340, 340))
		for _ = 1, rnd:NextInteger(5, 9) do
			local h = rnd:NextNumber(2.5, 5)
			nocol(K.box(ctx, "Reed", V3(0.18, h, 0.18), CF(c + V3(rnd:NextNumber(-2, 2), h / 2, rnd:NextNumber(-2, 2))) * CFrame.Angles(rnd:NextNumber(-0.2, 0.2), 0, rnd:NextNumber(-0.2, 0.2)), REED, M.Grass, ctx.Props))
		end
	end
	-- the sunken chapel: tilted walls, a leaning tower, its door half under the mud
	local base = CF(-34, -2.5, 30) * CFrame.Angles(DEG(4), DEG(18), DEG(-6))
	local CH = Color3.fromRGB(150, 146, 136)
	K.box(ctx, "ChapelWall", V3(2, 14, 30), base * CF(-8, 7, 0), CH, M.Slate)
	K.box(ctx, "ChapelWall", V3(2, 12, 22), base * CF(8, 6, 4), CH, M.Slate)
	K.box(ctx, "ChapelWall", V3(18, 14, 2), base * CF(0, 7, -15), CH, M.Slate)
	K.box(ctx, "ChapelRoof", V3(20, 1.4, 14), base * CF(0, 14.5, -8) * CFrame.Angles(0, 0, DEG(12)), Color3.fromRGB(64, 66, 72), M.Slate, ctx.Props)
	local tower = CF(-50, -3, 14) * CFrame.Angles(DEG(-7), 0, DEG(9))
	K.box(ctx, "ChapelTower", V3(7, 30, 7), tower * CF(0, 15, 0), CH, M.Slate)
	K.wedge(ctx, "ChapelSpire", V3(7, 8, 7), tower * CF(0, 34, 0), Color3.fromRGB(64, 66, 72), M.Slate, ctx.Props)
	-- mossy standing stones, half sunk
	for _ = 1, 14 do
		local h = rnd:NextNumber(4, 9)
		K.box(ctx, "MossStone", V3(2.4, h, 1.6), CF((rnd:NextNumber() < 0.5 and -1 or 1) * rnd:NextNumber(20, 100), h / 2 - 1.5, rnd:NextNumber(-320, 320)) * CFrame.Angles(rnd:NextNumber(-0.25, 0.25), rnd:NextNumber(0, 6), rnd:NextNumber(-0.25, 0.25)), Color3.fromRGB(92, 108, 86), M.Slate, ctx.Props)
	end
	for _ = 1, 18 do K.rock(ctx, V3(rnd:NextNumber(-100, 100), 0, rnd:NextNumber(-340, 340)), 1.5 + rnd:NextNumber(0, 3), Color3.fromRGB(92, 100, 90)) end
end
-- AMBERWOOD: the wood's edge down both flanks, an orchard round the second banner, a hunting lodge
-- round the third, a woodcutters' camp round the fourth, fallen leaves in drifts
function FEATURE.Amberwood(ctx)
	-- the wood's edge: a line of oaks along each flank, just outside the fighting
	for _, s in ipairs({-1, 1}) do
		for z = -360, 360, 15 do
			tree(ctx, "autumn", V3(s * rnd:NextNumber(110, 128), 0, z + rnd:NextNumber(-5, 5)))
			if rnd:NextNumber() < 0.5 then tree(ctx, "autumn", V3(s * rnd:NextNumber(132, 160), 0, z + rnd:NextNumber(-7, 7))) end
		end
	end
	-- the orchard: small trees in rows either side of the second banner
	for _, s in ipairs({-1, 1}) do
		for row = 0, 2 do
			for col = 0, 3 do
				local at = V3(s * (34 + row * 14), 0, -170 + col * 26 + rnd:NextNumber(-2, 2))
				local i = rnd:NextInteger(1, #AUTUMN)
				K.oak(ctx, at, 8 + rnd:NextNumber(0, 3), {AUTUMN[3], AUTUMN[i], AUTUMN[1]})
			end
		end
	end
	-- the hunting lodge: two long houses of dark timber by the third banner, fences, a cart
	local WOOD, ROOF = Color3.fromRGB(150, 116, 82), Color3.fromRGB(88, 56, 40)
	K.house(ctx, CF(-46, 0, -8) * CFrame.Angles(0, DEG(90), 0), 14, 22, 10, WOOD, ROOF)
	K.house(ctx, CF(48, 0, 14) * CFrame.Angles(0, DEG(-90), 0), 12, 16, 8, WOOD, ROOF)
	K.fence(ctx, V3(-70, 0, 22), V3(-30, 0, 30))
	K.fence(ctx, V3(30, 0, -26), V3(72, 0, -30))
	pcall(K.wagon, ctx, CF(-22, 0, -30) * CFrame.Angles(0, DEG(40), 0))
	-- the woodcutters' camp round the fourth banner: stacked logs, stumps
	local LOG, CUT = Color3.fromRGB(104, 76, 50), Color3.fromRGB(196, 160, 112)
	for _, at in ipairs({V3(-36, 0, 110), V3(40, 0, 140), V3(-52, 0, 160), V3(30, 0, 98)}) do
		local yaw = rnd:NextNumber(0, 6.28)
		for layer = 0, 2 do
			for k = 0, 3 - layer do
				local log = K.cyl(ctx, "Log", 1.5, 9, CF(at) * CFrame.Angles(0, yaw, 0) * CF((k - (3 - layer) / 2) * 1.5, 0.75 + layer * 1.3, 0) * CFrame.Angles(DEG(90), 0, 0), LOG, M.Wood, ctx.Props)
				log.CanCollide = layer == 0
			end
		end
	end
	for _ = 1, 22 do
		local at = V3((rnd:NextNumber() < 0.5 and -1 or 1) * rnd:NextNumber(18, 100), 0, rnd:NextNumber(60, 220))
		local h = rnd:NextNumber(0.8, 1.6)
		K.cyl(ctx, "Stump", rnd:NextNumber(1.6, 2.4), h, at + V3(0, h / 2, 0), LOG, M.Wood, ctx.Props)
		nocol(K.cyl(ctx, "StumpTop", 1.4, 0.06, at + V3(0, h + 0.03, 0), CUT, M.Wood, ctx.Props))
	end
	-- fallen leaves in drifts, rust and gold
	for _ = 1, 46 do
		local p = nocol(K.box(ctx, "LeafDrift", V3(1, 1, 1), CF((rnd:NextNumber() < 0.5 and -1 or 1) * rnd:NextNumber(10, 104), 0.1, rnd:NextNumber(-340, 340)) * CFrame.Angles(0, rnd:NextNumber(0, 6.28), 0), AUTUMN[rnd:NextInteger(1, #AUTUMN)], M.Grass, ctx.Props))
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Scale = V3(rnd:NextNumber(4, 9), rnd:NextNumber(0.5, 0.9), rnd:NextNumber(3, 7))
		m.Parent = p
	end
	for _ = 1, 12 do K.rock(ctx, V3(rnd:NextNumber(-100, 100), 0, rnd:NextNumber(-340, 340)), 1.5 + rnd:NextNumber(0, 2.5), Color3.fromRGB(120, 112, 100)) end
end
-- SUNREACH: a ruined temple of sandstone in the middle, obelisks, rocks
function FEATURE.Sunreach(ctx)
	local SAND = Color3.fromRGB(214, 180, 128)
	for k = 1, 12 do
		local a = k / 12 * math.pi * 2
		local h = (k % 3 == 0) and rnd:NextNumber(4, 7) or rnd:NextNumber(12, 18)
		K.cyl(ctx, "Column", 3.2, h, V3(math.cos(a) * 34, h / 2, math.sin(a) * 34), SAND, M.Sandstone)
		if h > 10 and k % 2 == 0 then
			K.box(ctx, "Lintel", V3(4, 1.6, 16), CF(math.cos(a) * 34, h + 0.8, math.sin(a) * 34) * CFrame.Angles(0, -a, 0), SAND, M.Sandstone)
		end
	end
	K.cyl(ctx, "TempleFloor", 74, 1, CF(0, 0.2, 0), Color3.fromRGB(200, 170, 124), M.Sandstone, ctx.Props)
	for _, at in ipairs({V3(-70, 0, -60), V3(72, 0, 64), V3(-60, 0, 190), V3(66, 0, -200)}) do
		K.box(ctx, "Obelisk", V3(5, 26, 5), CF(at + V3(0, 13, 0)), SAND, M.Sandstone, ctx.Props)
		K.wedge(ctx, "ObeliskTip", V3(5, 4, 5), CF(at + V3(0, 28, 0)), Color3.fromRGB(226, 190, 90), M.Metal, ctx.Props)
	end
	for _ = 1, 22 do K.rock(ctx, V3(rnd:NextNumber(-95, 95), 0, rnd:NextNumber(-340, 340)), 3 + rnd:NextNumber(0, 5), Color3.fromRGB(186, 140, 96)) end
end

-- the terrain under each theme
local PAINT = {}
-- a new surface on the ground without lifting it: the top layer's material swapped in a box
local function surface(x0, z0, x1, z1, from, to)
	local lo = V3(math.min(x0, x1), -12, math.min(z0, z1))
	local hi = V3(math.max(x0, x1), 8, math.max(z0, z1))
	workspace.Terrain:ReplaceMaterial(Region3.new(lo, hi):ExpandToGrid(4), 4, from, to)
end
-- a round patch of it (in strips)
local function disc(cx, cz, r, from, to)
	for z = -r, r, 8 do
		local w = math.sqrt(math.max(r * r - z * z, 0))
		if w > 2 then surface(cx - w, cz + z - 4, cx + w, cz + z + 4, from, to) end
	end
end
-- swells out past the armies' lanes (the corridor stays level: it's where the fight is)
local function rolling(T, theme)
	-- (low and wide: a swell, not a table; in the fields' own stuff)
	local mat = theme.field or theme.ground
	for _, s in ipairs({-1, 1}) do
		for _ = 1, 7 do
			T:Mound(V3(s * rnd:NextNumber(276, 282), 0, rnd:NextNumber(-350, 350)), rnd:NextNumber(3, 6), 2, rnd:NextNumber(34, 38), mat)
		end
	end
end
function PAINT.Redfield(T, th)
	-- wheat fields on the flanks, a dirt road down the middle, a green round the village
	for _, s in ipairs({-1, 1}) do surface(s * 126, -400, s * 300, 400, th.ground, M.LeafyGrass) end
	surface(-7, -400, 7, 400, th.ground, th.path)
	rolling(T, th)
end
function PAINT.Ironridge(T, th)
	-- the rise the fort stands on, outcrops of rock, a stony track
	T:Mound(V3(0, 0, 0), 7, 46, 84, M.Grass)
	for _ = 1, 16 do T:FillBall(V3(rnd:NextNumber(-90, 90), -6, rnd:NextNumber(-330, 330)), rnd:NextNumber(6, 12), M.Rock) end
	for _, s in ipairs({-1, 1}) do surface(s * 126, -400, s * 300, 400, th.ground, M.Ground) end
	surface(-5, -400, 5, 400, th.ground, M.Ground)
	rolling(T, th)
end
function PAINT.Frostmere(T, th)
	-- the frozen lake in the middle, flush with the snow
	disc(0, 0, 66, th.ground, M.Glacier)
	surface(-5, -400, 5, -70, th.ground, M.Ground)
	surface(-5, 70, 5, 400, th.ground, M.Ground)
	rolling(T, th)
end
function PAINT.Ashvale(T, th)
	-- cracks of fire, black rock, the burnt road
	for _ = 1, 26 do
		local x, z = rnd:NextNumber(-280, 280), rnd:NextNumber(-340, 340)
		if rnd:NextNumber(0, 1) < 0.5 then surface(x - 3, z - 22, x + 3, z + 22, th.ground, M.CrackedLava)
		else surface(x - 22, z - 3, x + 22, z + 3, th.ground, M.CrackedLava) end
	end
	for _ = 1, 20 do
		local x, z = rnd:NextNumber(-280, 280), rnd:NextNumber(-340, 340)
		surface(x - 16, z - 16, x + 16, z + 16, th.ground, M.Basalt)
	end
	for _, s in ipairs({-1, 1}) do surface(s * 126, -400, s * 300, 400, th.ground, M.Mud) end
	surface(-6, -400, 6, 400, th.ground, M.Basalt)
	rolling(T, th)
end
function PAINT.Stormvale(T, th)
	-- muddy flanks churned by the rain, a cobbled road through the abbey
	for _, s in ipairs({-1, 1}) do surface(s * 126, -400, s * 300, 400, th.ground, th.field) end
	surface(-6, -400, 6, 400, th.ground, th.path)
	rolling(T, th)
end
function PAINT.Duskmoor(T, th)
	-- heather on the flanks and round the cairns, a peat track
	for _, s in ipairs({-1, 1}) do surface(s * 126, -400, s * 300, 400, th.ground, th.field) end
	disc(0, 0, 40, th.ground, th.field)
	surface(-5, -400, 5, 400, th.ground, th.path)
	rolling(T, th)
end
function PAINT.Mistmarsh(T, th)
	-- bog on the flanks, mud round the causeway, grass hummocks between
	for _, s in ipairs({-1, 1}) do surface(s * 126, -400, s * 300, 400, th.ground, th.field) end
	surface(-14, -400, 14, 400, th.ground, th.field)
	for _ = 1, 16 do disc(rnd:NextNumber(-110, 110), rnd:NextNumber(-330, 330), rnd:NextNumber(8, 18), th.ground, th.field) end
	rolling(T, th)
end
function PAINT.Amberwood(T, th)
	-- fallen leaves carpeting the flanks and lying in drifts across the field, a track down the middle
	for _, s in ipairs({-1, 1}) do surface(s * 104, -400, s * 300, 400, th.ground, th.field) end
	for _ = 1, 22 do disc(rnd:NextNumber(-100, 100), rnd:NextNumber(-340, 340), rnd:NextNumber(8, 20), th.ground, th.field) end
	surface(-5, -400, 5, 400, th.ground, th.path)
	rolling(T, th)
end
function PAINT.Nightfall(T, th)
	for _, s in ipairs({-1, 1}) do surface(s * 126, -400, s * 300, 400, th.ground, th.field) end
	surface(-6, -400, 6, 400, th.ground, th.path)
	rolling(T, th)
end
function PAINT.Sunreach(T, th)
	-- dunes on the flanks, sandstone underfoot round the temple, a beaten track
	for _, s in ipairs({-1, 1}) do surface(s * 126, -400, s * 300, 400, th.ground, th.field) end
	disc(0, 0, 44, th.ground, M.Sandstone)
	surface(-6, -400, 6, -44, th.ground, th.path)
	surface(-6, 44, 6, 400, th.ground, th.path)
	rolling(T, th)
end
-- PLOUGHED FIELDS: a few plots of turned earth out on the flanks (painted as furrows; at the
-- terrain's grain they read as plots of dark earth, a patchwork seen from the hills)
local function ploughed(T, th, mat, plots)
	for _, s in ipairs({-1, 1}) do
		for _ = 1, plots or 3 do
			-- (on the terrain's grid, so each furrow is one 4-stud row and the green rows between stay)
			local function snap(v) return math.floor(v / 8 + 0.5) * 8 end
			local cx, cz = snap(s * rnd:NextNumber(150, 270)), snap(rnd:NextNumber(-330, 330))
			local w, d = snap(rnd:NextNumber(40, 70)), snap(rnd:NextNumber(50, 90))
			local alongX = rnd:NextNumber() < 0.5
			local n = math.floor((alongX and d or w) / 8)
			for i = 0, n - 1 do
				local o = -((alongX and d or w) / 2) + i * 8
				-- (a hair inside the row, so growing it to the grid doesn't reach the next)
				if alongX then surface(cx - w / 2, cz + o + 0.5, cx + w / 2, cz + o + 3.5, th.ground, mat)
				else surface(cx + o + 0.5, cz - d / 2, cx + o + 3.5, cz + d / 2, th.ground, mat) end
			end
		end
	end
end
function PAINT.Kingsbridge(T, th)
	ploughed(T, th, M.Mud, 3)
	rolling(T, th)
	-- the river: a shallow channel right across the field (wade it, or take a bridge)
	T:FillBlock(CF(0, 2, 0), V3(640, 8, 34), M.Air)
	T:FillBlock(CF(0, -4, 0), V3(640, 4, 38), M.Mud)
	T:FillBlock(CF(0, -0.5, 0), V3(640, 3, 34), M.Water)
	-- the cobbled roads down to each bridge
	for _, x in ipairs({-56, 56}) do
		surface(x - 6, -400, x + 6, -20, th.ground, th.path)
		surface(x - 6, 20, x + 6, 400, th.ground, th.path)
	end
end

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
function WarMap.build(themeName)
	local th = THEMES[themeName] or THEMES.Redfield
	themeName = THEMES[themeName] and themeName or "Redfield"
	made += 1
	local name = "Gen_War_" .. themeName .. "_" .. made
	local ctx = K.new(name)
	local L = {banners = {}, camps = {}, trebuchets = {A = {}, B = {}}, archers = {A = {}, B = {}}, mages = {}, radius = RADIUS, bounds = {x = CW, z = END}, ballistae = {}}

	-- THE GROUND: terrain over the field, a slab under the far country
	K.terrainColors(ctx, th.colors)
	-- (the region reaches well up: its empty air, pasted over the field, clears any terrain another
	-- map left standing there)
	local okT, errT = pcall(K.terrain, ctx, V3(-320, -24, -420), V3(640, 96, 840), function(T)
		T:FillBlock(CF(0, -6, 0), V3(640, 12, 840), th.ground)
		local paint = PAINT[themeName]
		if paint then paint(T, th) end
	end, {fast = true})
	if not okT then
		warn("[WarMap] terrain:", errT)
		K.box(ctx, "Field", V3(640, 2, 840), CF(0, -1, 0), th.slab, M.Grass)
	end
	K.box(ctx, "FarCountry", V3(1600, 1, 1800), CF(0, -1.6, 0), th.slab, M.Grass)

	-- THE BANNERS
	for i, z in ipairs(BANNER_Z) do
		local pos = V3(0, 0, z)
		banner(ctx, i, pos)
		table.insert(L.banners, {id = i, pos = pos})
		ctx.model:SetAttribute("W_Banner" .. i, pos)
	end
	ctx.model:SetAttribute("W_Radius", RADIUS)

	-- THE BALLISTAE players man: two a side, behind the banner second from their end, facing the
	-- enemy (the made one, else one of timber)
	for _, side in ipairs({"A", "B"}) do
		local f = side == "A" and -1 or 1
		for _, x in ipairs({-62, 62}) do
			local at = V3(x, 0, f * 186)
			local cf = CFrame.lookAt(at, at + V3(0, 0, -f))
			local m = prop(ctx, "Ballista", cf, 7)
			if not m then
				m = Instance.new("Model")
				K.box(ctx, "Base", V3(3, 1.4, 5), cf * CF(0, 0.7, 0), DARK, M.Wood, m)
				K.box(ctx, "Arms", V3(8, 0.6, 0.8), cf * CF(0, 2.4, -1.6), WOOD, M.Wood, m)
				K.box(ctx, "Stock", V3(0.8, 0.8, 6), cf * CF(0, 2.2, 0), WOOD, M.Wood, m)
				m.Parent = ctx.Props
			end
			m.Name = "PlayerBallista"
			m:SetAttribute("Side", side)
			table.insert(L.ballistae, {model = m, side = side})
		end
	end

	-- cover beside the second and fourth banners: barricades to fight round
	for _, i in ipairs({2, 4}) do
		local z = BANNER_Z[i]
		for _, x in ipairs({-46, 46}) do
			prop(ctx, "Barricade", CFrame.lookAt(V3(x, 0, z + rnd:NextNumber(-12, 12)), V3(x + 1, 0, z + rnd:NextNumber(-12, 12))), 4.5)
		end
	end

	-- THE CAMPS, THEIR ENGINES
	for _, side in ipairs({"A", "B"}) do
		local f = side == "A" and -1 or 1
		L.camps[side] = camp(ctx, side)
		ctx.model:SetAttribute("W_Camp" .. side, L.camps[side])
		for k, x in ipairs({-58, 58}) do
			local arm = trebuchet(ctx, V3(x, 0, f * 394), side == "A" and math.pi or 0)
			L.trebuchets[side][k] = arm
			ctx.model:SetAttribute("W_Treb" .. side .. k, arm)
		end
		-- the archers out on both flanks, behind their side's half of the field
		for k, s in ipairs({-1, 1}) do
			local at = V3(s * 178, 0, f * 210)
			L.archers[side][k] = at
			ctx.model:SetAttribute("W_Arch" .. side .. k, at)
		end
		-- the battle-mages' circle on a flank, near their camp
		local mpos = V3((side == "A" and -1 or 1) * 284, 0, f * 300)
		mageCircle(ctx, mpos, TEAM[side])
		L.mages[side] = mpos
		ctx.model:SetAttribute("W_Mage" .. side, mpos)
	end
	for k, x in ipairs(LANES) do ctx.model:SetAttribute("W_Lane" .. k, x) end

	-- THE CORRIDOR'S EDGES: stakes, and a wall nobody sees; the field's ends
	for _, s in ipairs({-1, 1}) do
		stakes(ctx, V3(s * (CW + 4), 0, -END), V3(s * (CW + 4), 0, END), 6, s > 0 and -28 or 28)
		wall(ctx, CF(s * (CW + 9), 30, 0), V3(2, 80, END * 2 + 40))
	end
	for _, f in ipairs({-1, 1}) do wall(ctx, CF(0, 30, f * (END + 8)), V3(CW * 2 + 20, 80, 2)) end

	-- THE THEME'S OWN PLACE
	local feat = FEATURE[themeName]
	if feat then
		local okF, errF = pcall(feat, ctx)
		if not okF then warn("[WarMap] feature:", errF) end
	end
	pcall(debris, ctx)

	-- TREES along the far edges of the flanks and round the camps, a few in the field
	for _ = 1, 46 do
		local s = rnd:NextNumber(0, 1) < 0.5 and -1 or 1
		tree(ctx, th.trees, V3(s * rnd:NextNumber(298, 330), 0, rnd:NextNumber(-400, 400)))
	end
	for _ = 1, 10 do tree(ctx, th.trees, V3(rnd:NextNumber(-98, 98), 0, rnd:NextNumber(-300, 300))) end
	-- THE WAR'S MARKS: spent arrows in the ground, a broken cart
	for _ = 1, 70 do
		local at = V3(rnd:NextNumber(-100, 100), 0.9, rnd:NextNumber(-300, 300))
		nocol(K.box(ctx, "SpentArrow", V3(0.12, 0.12, 2.6), CF(at) * CFrame.Angles(DEG(-50 - rnd:NextNumber(0, 25)), rnd:NextNumber(0, 6.28), 0), Color3.fromRGB(110, 84, 54), M.Wood, ctx.Props))
	end
	-- HILLS all round, half sunk
	for i = 1, 30 do
		local a = i / 30 * math.pi * 2
		local d = 260 + rnd:NextNumber(0, 160)
		local r = 520 + rnd:NextNumber(0, 120)
		local c = V3(math.cos(a) * r * 0.85, -d * (0.32 + rnd:NextNumber(0, 0.12)), math.sin(a) * r * 1.05)
		K.ball(ctx, "Hill", d, CF(c), th.hill, th.rocky and M.Rock or M.Grass, ctx.Props)
	end

	-- the shots (the vote's picture, the opening flight)
	K.camera(ctx, V3(150, 90, -380), V3(0, 0, -40))
	K.camera(ctx, V3(-120, 40, 60), V3(0, 6, -40))
	K.camera(ctx, V3(0, 120, 420), V3(0, 0, 60))

	K.lighting(ctx, th.light)
	K.atmosphere(ctx, th.atmo)
	ctx.model:SetAttribute("W_Weather", th.weather or "")
	ctx.model:SetAttribute("W_Theme", themeName)
	ctx.model:SetAttribute("Generated", true)
	local ok, err = pcall(K.finish, ctx)
	if not ok then
		warn("[WarMap] finish:", err)
		local maps = ServerStorage:FindFirstChild("Maps") or Instance.new("Folder")
		maps.Name = "Maps"; maps.Parent = ServerStorage
		ctx.model.Parent = maps
	end
	return name, L
end

return WarMap
