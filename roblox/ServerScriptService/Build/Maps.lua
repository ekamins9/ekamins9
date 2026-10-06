--[[ MAPS — three maps described with Build ▸ MapKit. Studio edit mode:

       local Maps = require(game.ServerScriptService.Build.Maps)
       Maps.build("Sandpit")        -- or Maps.buildAll()

     Sandpit    a sun-bleached desert arena: a sunken fighting pit, stands,
                red and blue awnings on poles, a gatehouse. Lists / Duel / FFA.
     Highbridge a long stone bridge in blue fog between two gatehouses, with
                a wrecked cart and barrels for cover. TDM / LTS.
     Millfield  a village: windmill on the hill (the KOTH zone), farmhouses,
                hay, fences, a stream with a plank bridge. KOTH / TDM / FFA.
     GameConfig.MODES names them in each mode's `maps`. ]]

local K = require(script.Parent:WaitForChild("MapKit"))
local C, M = K.C, K.M
local V3, cf = Vector3.new, K.cf

local Maps = {}

-- a terrain mound: a flat top `top` studs high and `plateau` wide, sloping to
-- the ground at `foot`. Whatever stands on the plateau sits at y = top.
-- (MapKit's brush writes it voxel by voxel: see K.terrain.)
local function mound(T, at, top, plateau, foot, mat)
	T:Mound(at, top, plateau, foot, mat)
end
-- props kept off a mound: pushed out to `r` from its middle
local function offMound(p, r)
	local flat = Vector3.new(p.X, 0, p.Z)
	if flat.Magnitude >= r then return p end
	local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(1, 0, 0)
	return Vector3.new(dir.X * r, p.Y, dir.Z * r)
end

--------------------------------------------------------------------
--  SANDPIT
--------------------------------------------------------------------
function Maps.Sandpit()
	local ctx = K.new("Sandpit")
	-- ground: sand terrain with dunes around the edge
	K.terrain(ctx, V3(-176, -48, -176), V3(352, 96, 352), function(T)
		T:FillBlock(CFrame.new(0, -6, 0), V3(300, 12, 300), Enum.Material.Sand)
		local r = Random.new(3)
		-- dunes well outside the walls (R = 70): they never reach in over them
		for i = 1, 26 do
			local a = i / 26 * 2 * math.pi
			local d = 132 + r:NextNumber(-6, 14)
			T:FillBall(V3(math.cos(a) * d, -10 + r:NextNumber(0, 5), math.sin(a) * d), r:NextNumber(16, 26), Enum.Material.Sand)
		end
		-- the pit: a bowl in the middle
		T:FillBall(V3(0, 5, 0), 22, Enum.Material.Air)
		T:FillBlock(CFrame.new(0, -5.5, 0), V3(44, 3, 44), Enum.Material.Sandstone)
	end)
	-- the pit floor and a low ring wall
	K.terrainColors(ctx, {Sand = Color3.fromRGB(214, 182, 122), Sandstone = Color3.fromRGB(190, 152, 104)})
	K.cyl(ctx, "PitFloor", 42, 1, V3(0, -4.5, 0), C.SANDDARK, M.Sandstone)
	-- the rim: a ring of low blocks, open where the four stairs come up
	for i = 1, 16 do
		if i % 4 ~= 0 then
			local a = i / 16 * 2 * math.pi
			K.box(ctx, "PitRim", V3(2.2, 1.4, 8.4), CFrame.new(math.cos(a) * 22, 0.7, math.sin(a) * 22) * CFrame.Angles(0, -a, 0), C.SANDSTONE, M.Sandstone)
		end
	end
	-- stairs up out of the pit on four sides: they start on the floor and climb outward to the rim
	for _, ang in ipairs({0, 90, 180, 270}) do
		K.stairs(ctx, CFrame.Angles(0, math.rad(ang), 0) * CFrame.new(0, -4.5, -14.2), 6, 6, 0.75, 1.3, C.SANDSTONE, M.Sandstone)
	end
	-- outer yard walls with a gatehouse to the north
	local R = 70
	for i = 0, 7 do
		local a0, a1 = i / 8 * 2 * math.pi, (i + 1) / 8 * 2 * math.pi
		local a = V3(math.cos(a0) * R, 0, math.sin(a0) * R)
		local b = V3(math.cos(a1) * R, 0, math.sin(a1) * R)
		if i ~= 5 then K.wall(ctx, a, b, 7, 2.4, {color = C.SANDSTONE, material = M.Sandstone, crenels = true, base = true, baseColor = C.SANDDARK}) end
	end
	-- gate (the missing segment, south-west) with an arch and two towers
	local ga = V3(math.cos(5 / 8 * 2 * math.pi) * R, 0, math.sin(5 / 8 * 2 * math.pi) * R)
	local gb = V3(math.cos(6 / 8 * 2 * math.pi) * R, 0, math.sin(6 / 8 * 2 * math.pi) * R)
	local gmid = (ga + gb) / 2
	local look = CFrame.lookAt(gmid, V3(0, 0, 0))
	local along = (gb - ga).Unit
	K.arch(ctx, look, 8, 9, 2.4, C.SANDSTONE, M.Sandstone)
	-- the wall closes in from both towers to the gate
	K.wall(ctx, ga, gmid - along * 5.9, 7, 2.4, {color = C.SANDSTONE, material = M.Sandstone, crenels = true, base = true, baseColor = C.SANDDARK})
	K.wall(ctx, gmid + along * 5.9, gb, 7, 2.4, {color = C.SANDSTONE, material = M.Sandstone, crenels = true, base = true, baseColor = C.SANDDARK})
	K.tower(ctx, ga, 4, 12, {color = C.SANDSTONE, material = M.Sandstone, roof = true, roofColor = C.RED})
	K.tower(ctx, gb, 4, 12, {color = C.SANDSTONE, material = M.Sandstone, roof = true, roofColor = C.BLUE})
	-- stands: tiered benches on the east and west
	for _, s in ipairs({-1, 1}) do
		for t = 1, 3 do
			K.box(ctx, "Stand", V3(5, 1.2, 36), V3(s * (34 + t * 5), 0.6 + (t - 1) * 1.2, 0), C.SANDSTONE, M.Sandstone)
		end
		K.awning(ctx, V3(s * 42, 0, 0), 14, 40, 9, s < 0 and C.RED or C.BLUE)
	end
	-- market corner: awnings, crates, barrels
	K.awning(ctx, V3(30, 0, 42), 12, 12, 7, C.RED)
	K.awning(ctx, V3(-32, 0, 44), 12, 12, 7.5, C.BLUE)
	K.awning(ctx, V3(0, 0, -50), 16, 10, 8, C.WHITE)
	local r = Random.new(11)
	for i = 1, 10 do K.crate(ctx, V3(r:NextNumber(-50, 50), 0, r:NextNumber(28, 56)), r:NextNumber(2.5, 3.5), r:NextNumber(0, 90)) end
	for i = 1, 8 do K.barrel(ctx, V3(r:NextNumber(-56, 56), 0, -r:NextNumber(30, 56))) end
	for i = 1, 10 do K.rock(ctx, V3(r:NextNumber(-60, 60), -0.5, r:NextNumber(-60, 60)), r:NextNumber(2, 4), C.SANDDARK) end
	-- banners around the rim
	for i = 1, 8 do
		local a = i / 8 * 2 * math.pi + math.pi / 8
		K.banner(ctx, V3(math.cos(a) * 27, 0, math.sin(a) * 27), 9, i % 2 == 0 and C.RED or C.BLUE)
	end
	-- torches on the wall
	for i = 0, 7 do
		local a = (i + 0.5) / 8 * 2 * math.pi
		if i ~= 5 then K.torch(ctx, V3(math.cos(a) * (R - 1.6), 5, math.sin(a) * (R - 1.6)), math.deg(-a)) end
	end
	-- spawns: team A north rim, team B south rim, free ones around
	for i = -2, 2 do
		K.spawn(ctx, V3(i * 5, 1, -30), "A", V3(0, 0, 0))
		K.spawn(ctx, V3(i * 5, 1, 30), "B", V3(0, 0, 0))
	end
	for i = 1, 8 do
		local a = i / 8 * 2 * math.pi
		K.spawn(ctx, V3(math.cos(a) * 48, 1, math.sin(a) * 48), nil, V3(0, 0, 0))
	end
	K.camera(ctx, V3(-70, 26, -70), V3(0, 2, 0))
	K.camera(ctx, V3(55, 18, 30), V3(0, -2, 0))
	K.camera(ctx, V3(0, 14, 60), V3(0, 0, -20))
	K.lighting(ctx, {ClockTime = 13.5, FogEnd = 900, FogColor = Color3.fromRGB(230, 214, 180), Brightness = 2.6, OutdoorAmbient = Color3.fromRGB(150, 140, 120), Ambient = Color3.fromRGB(90, 85, 75)})
	return K.finish(ctx)
end

--------------------------------------------------------------------
--  HIGHBRIDGE
--------------------------------------------------------------------
function Maps.Highbridge()
	local ctx = K.new("Highbridge")
	local L, W = 150, 16   -- bridge length (along Z) and width
	-- the deck, with a low parapet and piers down into the fog
	K.box(ctx, "Deck", V3(W, 2, L), V3(0, -1, 0), C.BLUESTONE, M.Slate)
	K.box(ctx, "DeckTrim", V3(W + 1, 0.4, L), V3(0, 0.1, 0), C.STONE, M.Slate).CanCollide = false
	for _, s in ipairs({-1, 1}) do
		K.box(ctx, "Parapet", V3(1.2, 2.4, L), V3(s * (W / 2 + 0.6), 1.2, 0), C.BLUESTONE, M.Slate)
		for i = 0, 10 do K.box(ctx, "Merlon", V3(1.2, 1.2, 2), V3(s * (W / 2 + 0.6), 3.0, -L / 2 + i * L / 10), C.BLUESTONE, M.Slate) end
	end
	for i = 0, 5 do
		local z = -L / 2 + 15 + i * (L - 30) / 5
		K.box(ctx, "Pier", V3(W + 4, 40, 6), V3(0, -22, z), C.STONEDARK, M.Slate)
		-- an arch between this pier and the next, its crown under the deck
		if i < 5 then
			local z2 = z + (L - 30) / 10
			local span = (L - 30) / 5 - 6
			K.archRing(ctx, CFrame.new(0, 0, z2) * CFrame.Angles(0, math.rad(90), 0), span / 2, 1.6, -8 - span / 2 - 1.6, W + 4, C.STONEDARK, M.Slate)
		end
	end
	K.box(ctx, "Underside", V3(W + 2, 6, L), V3(0, -5, 0), C.STONEDARK, M.Slate)
	-- gatehouses at both ends
	for _, s in ipairs({-1, 1}) do
		local z = s * (L / 2 + 10)
		K.box(ctx, "GateFloor", V3(44, 2, 24), V3(0, -1, z), C.BLUESTONE, M.Slate)
		-- the bridge side is open at the gate; the far side and both flanks are closed
		local zb, zf = z - s * 12, z + s * 12
		K.wall(ctx, V3(-22, 0, zb), V3(-6.9, 0, zb), 10, 3, {color = C.BLUESTONE, crenels = true})
		K.wall(ctx, V3(6.9, 0, zb), V3(22, 0, zb), 10, 3, {color = C.BLUESTONE, crenels = true})
		K.wall(ctx, V3(-22, 0, zf), V3(22, 0, zf), 10, 3, {color = C.BLUESTONE, crenels = true})
		K.wall(ctx, V3(-22, 0, z - 12), V3(-22, 0, z + 12), 10, 3, {color = C.BLUESTONE, crenels = true})
		K.wall(ctx, V3(22, 0, z - 12), V3(22, 0, z + 12), 10, 3, {color = C.BLUESTONE, crenels = true})
		K.tower(ctx, V3(-22, 0, z - 12), 5, 20, {color = C.BLUESTONE, roof = true, roofColor = C.BLUE, windows = true})
		K.tower(ctx, V3(22, 0, z - 12), 5, 20, {color = C.BLUESTONE, roof = true, roofColor = C.BLUE, windows = true})
		K.tower(ctx, V3(-22, 0, z + 12), 5, 20, {color = C.BLUESTONE, roof = true, roofColor = C.BLUE, windows = true})
		K.tower(ctx, V3(22, 0, z + 12), 5, 20, {color = C.BLUESTONE, roof = true, roofColor = C.BLUE, windows = true})
		-- the gate onto the bridge
		K.arch(ctx, CFrame.new(0, 0, z - s * 12), 10, 9, 3, C.BLUESTONE, M.Slate)
		for i = -1, 1 do K.banner(ctx, V3(i * 8, 0, z + s * 11), 9, s < 0 and C.BLUE or C.RED) end
		K.torch(ctx, V3(-9, 5, z - s * 13.8), 0); K.torch(ctx, V3(9, 5, z - s * 13.8), 0)
	end
	-- cover on the deck: a wrecked cart, barrels, crates, a fallen merlon
	K.box(ctx, "Cart", V3(5, 2.5, 8), CFrame.new(-3, 1.6, 10) * CFrame.Angles(0, math.rad(25), math.rad(12)), C.WOOD, M.WoodPlanks)
	K.cyl(ctx, "Wheel", 3, 0.5, CFrame.new(-6, 1.5, 7) * CFrame.Angles(0, math.rad(25), 0) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(0, math.rad(90), 0), C.DARKWOOD, M.Wood)
	for i = 1, 6 do K.barrel(ctx, V3((i % 2 == 0 and 5 or -5), 0, -20 - i * 6)) end
	for i = 1, 4 do K.crate(ctx, V3(i % 2 == 0 and 4 or -4, 0, 30 + i * 7), 3, i * 20) end
	K.box(ctx, "FallenMerlon", V3(1.2, 1.2, 2), CFrame.new(2, 0.6, 50) * CFrame.Angles(0, math.rad(30), 0), C.BLUESTONE, M.Slate)
	-- far scenery: faint towers in the fog (no collision)
	local r = Random.new(5)
	for i = 1, 12 do
		local x, z = r:NextNumber(-140, 140), r:NextNumber(-120, 120)
		if math.abs(x) > 40 then
			local h = r:NextNumber(30, 70)
			K.cyl(ctx, "FarTower", r:NextNumber(8, 16), h, V3(x, h / 2 - 20, z), C.BLUESTONE, M.Slate).CanCollide = false
		end
	end
	-- spawns
	for i = -2, 2 do
		K.spawn(ctx, V3(i * 6, 1, -(L / 2 + 10)), "A", V3(0, 0, 0))
		K.spawn(ctx, V3(i * 6, 1, (L / 2 + 10)), "B", V3(0, 0, 0))
	end
	for i = 1, 6 do K.spawn(ctx, V3(r:NextNumber(-6, 6), 1, -60 + i * 20), nil, V3(0, 0, 0)) end
	K.camera(ctx, V3(-40, 22, -110), V3(0, 2, 0))
	K.camera(ctx, V3(30, 12, 20), V3(0, 0, -60))
	K.camera(ctx, V3(0, 30, 120), V3(0, 0, 0))
	K.lighting(ctx, {ClockTime = 7.2, FogEnd = 260, FogStart = 40, FogColor = Color3.fromRGB(120, 160, 215), Brightness = 1.4, OutdoorAmbient = Color3.fromRGB(110, 140, 190), Ambient = Color3.fromRGB(60, 80, 120), ColorShift_Top = Color3.fromRGB(150, 180, 230)})
	return K.finish(ctx)
end

--------------------------------------------------------------------
--  MILLFIELD
--------------------------------------------------------------------
function Maps.Millfield()
	local ctx = K.new("Millfield")
	K.terrain(ctx, V3(-192, -64, -192), V3(384, 128, 384), function(T)
		T:FillBlock(CFrame.new(0, -6, 0), V3(340, 12, 340), Enum.Material.Grass)
		-- the hill in the middle: a plateau 8 studs up (the windmill's foot), sloping out to 38
		mound(T, V3(0, 0, 0), 8, 17, 38, Enum.Material.Grass)
		-- a stream across the south, cut into the ground
		T:FillBlock(CFrame.new(0, -2, 70) * CFrame.Angles(0, math.rad(8), 0), V3(300, 5, 12), Enum.Material.Air)
		T:FillBlock(CFrame.new(0, -4, 70) * CFrame.Angles(0, math.rad(8), 0), V3(300, 2, 12), Enum.Material.Water)
		T:FillBlock(CFrame.new(0, -5, 70) * CFrame.Angles(0, math.rad(8), 0), V3(300, 1, 14), Enum.Material.Mud)
		-- dirt paths
		T:FillBlock(CFrame.new(0, -2, 62), V3(6, 4, 46), Enum.Material.Ground)
		T:FillBlock(CFrame.new(0, -2, -62), V3(6, 4, 46), Enum.Material.Ground)
		T:FillBlock(CFrame.new(80, -2, 0) * CFrame.Angles(0, math.rad(90), 0), V3(6, 4, 80), Enum.Material.Ground)
		-- wheat fields: sand-coloured patches (flush with the ground: every fill ends at y = 0)
		T:FillBlock(CFrame.new(-70, -2, -30), V3(50, 4, 40), Enum.Material.Sand)
		T:FillBlock(CFrame.new(70, -2, -50), V3(40, 4, 40), Enum.Material.Sand)
	end)
	K.terrainColors(ctx, {Sand = Color3.fromRGB(214, 186, 112), Grass = Color3.fromRGB(104, 146, 72), Ground = Color3.fromRGB(120, 96, 70)})
	-- the windmill on the hill (its plateau is 8 up): a stone base, a wooden cap, four sails
	K.cyl(ctx, "MillBase", 12, 14, V3(0, 7 + 8, 0), C.STONE, M.Cobblestone)
	K.cyl(ctx, "MillCap", 13, 3, V3(0, 7 + 15.5, 0), C.DARKWOOD, M.WoodPlanks)
	K.cone(ctx, "CapRoof", V3(0, 7 + 17, 0), 7, 6, C.RED, M.Fabric)
	K.cyl(ctx, "Axle", 1, 4, CFrame.new(0, 7 + 16, -7.5) * CFrame.Angles(math.rad(90), 0, 0), C.DARKWOOD, M.Wood)
	for i = 0, 3 do
		-- (13 long: the lowest tip clears the plateau)
		local s = K.box(ctx, "Sail", V3(2.6, 13, 0.3), CFrame.new(0, 7 + 16, -9.5) * CFrame.Angles(0, 0, math.rad(90 * i + 20)) * CFrame.new(0, 6.5, 0), C.WHITE, M.Fabric)
		s.CanCollide = false
		K.box(ctx, "SailFrame", V3(0.4, 13.4, 0.5), s.CFrame * CFrame.new(-1.2, 0, 0), C.DARKWOOD, M.Wood).CanCollide = false
	end
	K.box(ctx, "MillDoor", V3(2.4, 3.6, 0.3), V3(0, 8 + 1.8, 6.05), C.DARKWOOD, M.Wood).CanCollide = false
	K.hill(ctx, V3(0, 8, 0), 16, 10)
	-- farmhouses around the hill
	K.house(ctx, CFrame.new(-50, 0, 40) * CFrame.Angles(0, math.rad(30), 0), 14, 18, 7, C.WHITE, C.DARKWOOD)
	K.house(ctx, CFrame.new(55, 0, 35) * CFrame.Angles(0, math.rad(-40), 0), 12, 16, 6.5, Color3.fromRGB(226, 212, 190), C.THATCH)
	K.house(ctx, CFrame.new(-55, 0, -60) * CFrame.Angles(0, math.rad(100), 0), 16, 20, 8, C.WHITE, C.DARKWOOD)
	K.house(ctx, CFrame.new(60, 0, -70) * CFrame.Angles(0, math.rad(200), 0), 12, 14, 6, Color3.fromRGB(226, 212, 190), C.THATCH)
	-- barn with an open front
	K.box(ctx, "BarnWall", V3(0.6, 9, 24), V3(-96, 4.5, 0), C.RED, M.WoodPlanks)
	K.box(ctx, "BarnWall", V3(0.6, 9, 24), V3(-74, 4.5, 0), C.RED, M.WoodPlanks)
	K.box(ctx, "BarnBack", V3(22, 9, 0.6), V3(-85, 4.5, 12), C.RED, M.WoodPlanks)
	K.box(ctx, "BarnRoof", V3(24, 0.5, 26), CFrame.new(-85, 10.5, 0), C.DARKWOOD, M.WoodPlanks)
	for i = 1, 6 do K.hay(ctx, V3(-92 + (i % 3) * 6, 0, -6 + math.floor(i / 3) * 6)) end
	-- fences along the fields, a plank bridge over the stream, trees, rocks
	K.fence(ctx, V3(-95, 0, -10), V3(-45, 0, -10)); K.fence(ctx, V3(-45, 0, -10), V3(-45, 0, -50)); K.fence(ctx, V3(50, 0, -30), V3(90, 0, -30))
	K.box(ctx, "Bridge", V3(8, 0.6, 20), CFrame.new(0, 0.3, 70) * CFrame.Angles(0, math.rad(8), 0), C.WOOD, M.WoodPlanks)
	for _, s in ipairs({-1, 1}) do K.box(ctx, "Rail", V3(0.3, 1.2, 20), CFrame.new(0, 0.9, 70) * CFrame.Angles(0, math.rad(8), 0) * CFrame.new(s * 4, 0, 0), C.DARKWOOD, M.Wood).CanCollide = false end
	local r = Random.new(21)
	for i = 1, 30 do
		local a = r:NextNumber(0, 2 * math.pi)
		local d = r:NextNumber(110, 160)
		K.tree(ctx, V3(math.cos(a) * d, 0, math.sin(a) * d), r:NextNumber(10, 18))
	end
	for i = 1, 8 do K.tree(ctx, V3(r:NextNumber(-100, 100), 0, r:NextNumber(85, 120)), r:NextNumber(10, 16)) end
	-- (nothing small on the hill's slope: rocks and crates keep to the flat)
	for i = 1, 10 do K.rock(ctx, offMound(V3(r:NextNumber(-90, 90), 0, r:NextNumber(-90, 50)), 42), r:NextNumber(2, 5)) end
	for i = 1, 5 do K.crate(ctx, offMound(V3(r:NextNumber(-60, 60), 0, r:NextNumber(20, 50)), 42), 3, r:NextNumber(0, 90)) end
	-- a well, at the foot of the hill
	K.cyl(ctx, "Well", 5, 2.4, V3(44, 1.2, 22), C.STONE, M.Cobblestone)
	K.cyl(ctx, "WellHole", 3.4, 2.5, V3(44, 1.3, 22), Color3.fromRGB(20, 25, 30), M.SmoothPlastic).CanCollide = false
	K.box(ctx, "WellRoof", V3(6, 0.4, 6), V3(44, 6, 22), C.DARKWOOD, M.WoodPlanks)
	K.pole(ctx, V3(41.5, 2.4, 19.5), 3.6); K.pole(ctx, V3(46.5, 2.4, 24.5), 3.6)
	-- spawns: A west, B east, free around
	for i = -2, 2 do
		K.spawn(ctx, V3(-110, 1, i * 8), "A", V3(0, 7, 0))
		K.spawn(ctx, V3(110, 1, i * 8), "B", V3(0, 7, 0))
	end
	for i = 1, 8 do
		local a = i / 8 * 2 * math.pi
		K.spawn(ctx, V3(math.cos(a) * 80, 1, math.sin(a) * 80), nil, V3(0, 7, 0))
	end
	K.camera(ctx, V3(-120, 40, 90), V3(0, 14, 0))
	K.camera(ctx, V3(70, 20, 60), V3(-20, 8, 0))
	K.camera(ctx, V3(10, 12, -110), V3(0, 18, 0))
	K.lighting(ctx, {ClockTime = 16.8, FogEnd = 700, FogColor = Color3.fromRGB(210, 200, 170), Brightness = 2.2, OutdoorAmbient = Color3.fromRGB(140, 130, 110), Ambient = Color3.fromRGB(80, 78, 70)})
	return K.finish(ctx)
end

-- the newer maps live in their own modules (Build ▸ Map<Name>)
function Maps.TrainingYard() return require(script.Parent:WaitForChild("MapTraining"))(K) end
function Maps.Courtyard() return require(script.Parent:WaitForChild("MapCourtyard"))(K) end
function Maps.Frostgate() return require(script.Parent:WaitForChild("MapFrostgate"))(K) end
function Maps.Colosseum() return require(script.Parent:WaitForChild("MapColosseum"))(K) end

function Maps.build(name)
	local fn = Maps[name]
	if type(fn) ~= "function" then error("no map called " .. tostring(name)) end
	return fn()
end
function Maps.buildAll()
	for _, n in ipairs({"Sandpit", "Highbridge", "Millfield", "TrainingYard", "Courtyard", "Frostgate", "Colosseum"}) do Maps.build(n) end
end

return Maps
