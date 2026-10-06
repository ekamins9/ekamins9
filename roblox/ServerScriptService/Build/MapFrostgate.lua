--[[ FROSTGATE — a snowbound castle for SIEGE. Built by
     Build ▸ Maps:   require(game.ServerScriptService.Build.Maps).build("Frostgate")

     South (+Z): the attackers' camp on the snowfield, tents and fires. A road
     runs north to the castle's gatehouse; the ram waits at the camp's edge.
     The castle (-Z): a curtain wall with a gatehouse and four towers, the
     bailey inside (stables, a forge, a well), and the great hall at the north
     end with the Jarl's throne. Cliffs and pines all round.

     Stages (Map ▸ Objectives, read by Game ▸ Modes ▸ Siege):
       1 Ram      push the ram up the road and break the gate
       2 Capture  take the bailey
       3 Capture  storm the great hall
       4 Slay     the Jarl rises from his throne: kill him
     Spawns carry Side = Attack / Defend and Stage: each side spawns at its
     highest Stage that is not past the current one. ]]

return function(K)
	local C, M = K.C, K.M
	local V3 = Vector3.new
	local DEG = math.rad
	local ctx = K.new("Frostgate")

	local FROST = Color3.fromRGB(150, 156, 166)      -- castle stone
	local FROSTDARK = Color3.fromRGB(104, 110, 122)
	local SNOW = Color3.fromRGB(238, 242, 250)
	local HOUSE = Color3.fromRGB(46, 62, 92)         -- Frostgate's own colours (neither team's)
	local HOUSE2 = Color3.fromRGB(214, 220, 230)
	local CAMP = Color3.fromRGB(150, 118, 78)

	----------------------------------------------------------------
	-- ground: a snowfield, a muddy road, cliffs behind the castle
	----------------------------------------------------------------
	K.terrain(ctx, V3(-220, -48, -260), V3(440, 140, 500), function(T)
		T:FillBlock(CFrame.new(0, -6, -5), V3(430, 12, 490), Enum.Material.Snow)
		-- the road from the camp to the gate, and the bailey's packed yard
		T:FillBlock(CFrame.new(0, -2, 70), V3(16, 4, 196), Enum.Material.Ground)
		T:FillBlock(CFrame.new(0, -2, -98), V3(132, 4, 132), Enum.Material.Cobblestone)
		-- banks either side of the snowfield, and the cliffs behind the castle
		for i = 0, 6 do
			local z = 200 - i * 52
			T:FillBall(V3(-180 - (i % 2) * 4, -14, z), 34, Enum.Material.Snow)
			T:FillBall(V3(180 + (i % 3) * 2, -14, z - 20), 34, Enum.Material.Snow)
		end
		for i = -4, 4 do
			T:FillBall(V3(i * 46, -6, -222 - (i % 2) * 6), 34, Enum.Material.Rock)
			T:FillBall(V3(i * 46 + 10, 6, -232), 24, Enum.Material.Snow)
		end
	end)
	K.terrainColors(ctx, {Snow = SNOW, Ground = Color3.fromRGB(112, 98, 86), Cobblestone = Color3.fromRGB(128, 128, 132), Rock = Color3.fromRGB(96, 102, 114)})

	-- snow on top of a part: a thin white slab
	local function snowOn(p, inset)
		local s = K.box(ctx, "Snow", V3(math.max(0.4, p.Size.X - (inset or 0.1)), 0.25, math.max(0.4, p.Size.Z - (inset or 0.1))), p.CFrame * CFrame.new(0, p.Size.Y / 2 + 0.12, 0), SNOW, M.Snow)
		s.CanCollide = false
		return s
	end
	local function snowPine(pos, h)
		K.cyl(ctx, "Trunk", 1, h * 0.3, pos + V3(0, h * 0.15, 0), C.DARKWOOD, M.Wood, ctx.Props)
		for i = 0, 2 do
			local r = h * (0.3 - i * 0.075)
			local y = h * (0.22 + i * 0.22)
			K.cone(ctx, "Leaves", pos + V3(0, y, 0), r, h * 0.34, i == 0 and Color3.fromRGB(40, 70, 52) or Color3.fromRGB(52, 86, 62), M.Grass, ctx.Props, true, 8)
			K.cone(ctx, "SnowCap", pos + V3(0, y + h * 0.18, 0), r * 0.62, h * 0.17, SNOW, M.Snow, ctx.Props, true, 8)
		end
	end

	----------------------------------------------------------------
	-- the castle
	----------------------------------------------------------------
	local WX, ZF, ZB = 70, -30, -172                 -- half width, front wall, back wall
	local WALL = {crenels = true, base = true, baseH = 2.4, baseW = 2, color = FROST, baseColor = FROSTDARK}
	-- the front wall leaves the gatehouse between x = ±13
	K.wall(ctx, V3(-WX, 0, ZF), V3(-16, 0, ZF), 18, 4, WALL)
	K.wall(ctx, V3(16, 0, ZF), V3(WX, 0, ZF), 18, 4, WALL)
	K.wall(ctx, V3(-WX, 0, ZF), V3(-WX, 0, ZB), 18, 4, WALL)
	K.wall(ctx, V3(WX, 0, ZF), V3(WX, 0, ZB), 18, 4, WALL)
	K.wall(ctx, V3(-WX, 0, ZB), V3(WX, 0, ZB), 18, 4, WALL)
	for _, x in ipairs({-WX, WX}) do
		for _, z in ipairs({ZF, ZB}) do K.tower(ctx, V3(x, 0, z), 8, 26, {roof = true, roofColor = HOUSE, windows = true, color = FROST, base = 3, baseColor = FROSTDARK}) end
	end
	-- the gatehouse: two big towers, the arch over the gate, a chamber on top
	for _, x in ipairs({-16, 16}) do K.tower(ctx, V3(x, 0, ZF), 7, 28, {roof = true, roofColor = HOUSE, windows = true, color = FROST, base = 3, baseColor = FROSTDARK}) end
	K.box(ctx, "GateArch", V3(22, 6, 7), V3(0, 19, ZF), FROST, M.Slate)
	K.box(ctx, "GateArchTrim", V3(18.6, 0.8, 7.6), V3(0, 16.4, ZF), FROSTDARK, M.Slate)
	K.box(ctx, "GateChamber", V3(24, 6, 9), V3(0, 25, ZF), FROST, M.Slate)
	for i = -3, 3 do K.box(ctx, "Crenel", V3(1.6, 1.6, 1.6), V3(i * 2.6, 28.8, ZF + 4), FROST, M.Slate) end
	K.box(ctx, "GateCrest", V3(4, 4, 0.4), V3(0, 25, ZF + 4.7), HOUSE, M.Fabric).CanCollide = false
	K.box(ctx, "GateCrestStar", V3(1.6, 1.6, 0.5), V3(0, 25, ZF + 4.8), HOUSE2, M.Metal).CanCollide = false
	-- the walls' walks are reached from inside by stairs in the corners
	K.stairs(ctx, CFrame.new(-WX + 4.5, 0, ZF - 30), 4, 12, 1.5, 2, FROSTDARK, M.Slate)
	K.stairs(ctx, CFrame.new(WX - 4.5, 0, ZF - 30), 4, 12, 1.5, 2, FROSTDARK, M.Slate)
	-- snow along the wall tops
	for _, d in ipairs(ctx.Geometry:GetChildren()) do
		if d:IsA("BasePart") and (d.Name == "Walk" or d.Name == "Crenel") then snowOn(d, 0.1) end
	end
	-- banners down the gate towers
	for _, x in ipairs({-16, 16}) do
		local b = K.box(ctx, "WallBanner", V3(4.4, 12, 0.2), V3(x, 14, ZF + 7.2), HOUSE, M.Fabric)
		b.CanCollide = false
		K.box(ctx, "WallBannerStar", V3(1.6, 1.6, 0.25), V3(x, 16, ZF + 7.32), HOUSE2, M.Metal).CanCollide = false
	end

	----------------------------------------------------------------
	-- stage 1: the ram and the gate
	----------------------------------------------------------------
	local s1 = K.objective(ctx, 1, "Ram", {Label = "Push the ram to the gate", Speed = 2.6, Radius = 13, AddTime = 150, Interval = 2.4})
	local path = {V3(0, 0, 128), V3(6, 0, 92), V3(-5, 0, 54), V3(2, 0, 16), V3(0, 0, -16.6)}
	K.path(ctx, s1, path)
	K.ram(ctx, s1, CFrame.lookAt(path[1], path[2]))
	K.gate(ctx, s1, CFrame.new(0, 0, ZF), 18, 16, 10)
	-- the gate passage behind the doors
	for _, x in ipairs({-9.6, 9.6}) do K.box(ctx, "Passage", V3(1.2, 16, 8), V3(x, 8, ZF - 4.5), FROSTDARK, M.Slate) end
	K.box(ctx, "PassageRoof", V3(20.4, 1.4, 8), V3(0, 16.7, ZF - 4.5), FROSTDARK, M.Slate)

	----------------------------------------------------------------
	-- the bailey (stage 2): stables, a forge, a well, carts
	----------------------------------------------------------------
	local s2 = K.objective(ctx, 2, "Capture", {Label = "Take the bailey", Time = 22, AddTime = 150})
	K.zone(ctx, s2, "Zone", V3(0, 0, -72), 13, 12)
	-- the well in the middle of the zone
	K.cyl(ctx, "Well", 5, 2.4, V3(0, 1.2, -72), FROSTDARK, M.Slate)
	K.cyl(ctx, "WellHole", 3.6, 2.5, V3(0, 1.3, -72), Color3.fromRGB(20, 24, 30), M.SmoothPlastic).CanCollide = false
	K.box(ctx, "WellRoof", V3(6, 0.4, 6), V3(0, 6.2, -72), C.DARKWOOD, M.WoodPlanks)
	snowOn(K.box(ctx, "WellRoofTop", V3(5.6, 0.2, 5.6), V3(0, 6.5, -72), C.DARKWOOD, M.WoodPlanks))
	K.pole(ctx, V3(-2.6, 2.4, -72), 3.8); K.pole(ctx, V3(2.6, 2.4, -72), 3.8)
	-- stables along the west wall
	do
		local base = CFrame.new(-56, 0, -76)
		K.box(ctx, "StableBack", V3(1, 9, 40), base * CFrame.new(-6, 4.5, 0), C.DARKWOOD, M.WoodPlanks)
		for i = -2, 2 do K.box(ctx, "StablePost", V3(0.8, 8, 0.8), base * CFrame.new(5, 4, i * 10), C.DARKWOOD, M.Wood) end
		for i = -1, 2 do K.box(ctx, "StableStall", V3(10, 4, 0.5), base * CFrame.new(0, 2, -15 + i * 10), C.WOOD, M.WoodPlanks) end
		local roof = K.box(ctx, "StableRoof", V3(14, 0.5, 42), base * CFrame.new(-0.5, 9, 0) * CFrame.Angles(0, 0, DEG(-12)), C.DARKWOOD, M.WoodPlanks)
		snowOn(roof, 0.4)
		for i = 1, 5 do K.hay(ctx, (base * CFrame.new(-1, 0, -18 + i * 7)).Position) end
	end
	-- the forge along the east wall: a hearth that glows, an anvil, racks
	do
		local base = CFrame.new(54, 0, -64)
		K.box(ctx, "ForgeHearth", V3(8, 3.4, 6), base * CFrame.new(0, 1.7, 0), FROSTDARK, M.Slate)
		local coals = K.box(ctx, "ForgeCoals", V3(6, 0.4, 4), base * CFrame.new(0, 3.6, 0), Color3.fromRGB(255, 120, 40), M.Neon)
		coals.CanCollide = false
		local f = Instance.new("Fire"); f.Size = 4; f.Heat = 6; f.Color = Color3.fromRGB(255, 140, 40); f.Parent = coals
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 150, 70); l.Range = 22; l.Brightness = 2; l.Parent = coals
		K.box(ctx, "ForgeChimney", V3(4, 14, 4), base * CFrame.new(0, 10, 2), FROSTDARK, M.Slate)
		K.box(ctx, "Anvil", V3(1.4, 1.2, 3), base * CFrame.new(-7, 1.9, -4), C.IRON, M.Metal)
		K.box(ctx, "AnvilBlock", V3(1.6, 1.4, 1.6), base * CFrame.new(-7, 0.7, -4), C.DARKWOOD, M.Wood)
		K.rack(ctx, base * CFrame.new(-2, 0, -9) * CFrame.Angles(0, DEG(180), 0))
		local roof = K.box(ctx, "ForgeRoof", V3(16, 0.5, 14), base * CFrame.new(-3, 8.5, -2) * CFrame.Angles(0, 0, DEG(10)), C.DARKWOOD, M.WoodPlanks)
		snowOn(roof, 0.4)
		for _, p in ipairs({V3(-10, 0, 5), V3(-10, 0, -9)}) do K.pole(ctx, (base * CFrame.new(p)).Position, 8.6) end
	end
	-- carts, barrels, crates
	K.box(ctx, "Cart", V3(5, 2.4, 8), CFrame.new(-22, 1.9, -50) * CFrame.Angles(0, DEG(30), 0), C.WOOD, M.WoodPlanks)
	for _, p in ipairs({V3(-30, 0, -96), V3(-26, 0, -98), V3(28, 0, -46), V3(34, 0, -100)}) do K.barrel(ctx, p) end
	for _, p in ipairs({V3(24, 0, -96), V3(26, 0, -92), V3(-40, 0, -46)}) do K.crate(ctx, p, 3, p.X) end
	for _, p in ipairs({V3(-36, 0, -60), V3(36, 0, -80), V3(-14, 0, -108), V3(14, 0, -108)}) do K.torchPost(ctx, p, 7) end

	----------------------------------------------------------------
	-- the great hall (stage 3) and the Jarl's throne (stage 4)
	----------------------------------------------------------------
	local HZ0, HZ1, HW = -116, -162, 26       -- front, back, half width
	local hallH = 16
	-- walls with a big door in the front
	K.box(ctx, "HallWall", V3(2.4, hallH, HZ0 - HZ1), V3(-HW, hallH / 2, (HZ0 + HZ1) / 2), FROST, M.Slate)
	K.box(ctx, "HallWall", V3(2.4, hallH, HZ0 - HZ1), V3(HW, hallH / 2, (HZ0 + HZ1) / 2), FROST, M.Slate)
	K.box(ctx, "HallWall", V3(HW * 2 + 2.4, hallH, 2.4), V3(0, hallH / 2, HZ1), FROST, M.Slate)
	K.box(ctx, "HallFront", V3(HW - 5, hallH, 2.4), V3(-(HW + 5) / 2, hallH / 2, HZ0), FROST, M.Slate)
	K.box(ctx, "HallFront", V3(HW - 5, hallH, 2.4), V3((HW + 5) / 2, hallH / 2, HZ0), FROST, M.Slate)
	K.box(ctx, "HallLintel", V3(10.4, 5, 2.4), V3(0, hallH - 2.5, HZ0), FROST, M.Slate)
	for _, x in ipairs({-HW, HW}) do K.box(ctx, "HallFooting", V3(4.2, 2.4, HZ0 - HZ1 + 1.8), V3(x, 1.2, (HZ0 + HZ1) / 2), FROSTDARK, M.Slate) end
	-- the roof: two long slopes, a ridge beam, snow on top
	-- eaves at x = ±27.5, 15.5 up; a 32° pitch puts the ridge at about 32.7
	local pitch = DEG(32)
	local run = HW + 1.5
	local slope = run / math.cos(pitch)
	local ridgeY = 15.5 + run * math.tan(pitch)
	for _, s in ipairs({-1, 1}) do
		local roof = K.box(ctx, "HallRoof", V3(slope, 1, HZ0 - HZ1 + 6), CFrame.new(s * run / 2, (15.5 + ridgeY) / 2, (HZ0 + HZ1) / 2) * CFrame.Angles(0, 0, -s * pitch), Color3.fromRGB(70, 56, 46), M.WoodPlanks)
		snowOn(roof, 1)
	end
	K.box(ctx, "HallRidge", V3(1.4, 1.4, HZ0 - HZ1 + 7), V3(0, ridgeY + 0.5, (HZ0 + HZ1) / 2), C.DARKWOOD, M.Wood)
	-- gable ends, closed: stepped up to the ridge
	for _, z in ipairs({HZ0, HZ1}) do
		local layers = 7
		local lh = (ridgeY - hallH) / layers
		for i = 1, layers do
			local w = (HW * 2) * (1 - (i - 0.5) / layers)
			K.box(ctx, "HallGable", V3(w, lh, 2.4), V3(0, hallH + (i - 0.5) * lh, z), FROST, M.Slate)
		end
	end
	-- carved dragon posts at the door
	for _, x in ipairs({-6.4, 6.4}) do
		K.box(ctx, "DoorPost", V3(1.6, 13, 1.6), V3(x, 6.5, HZ0 + 1.6), C.DARKWOOD, M.Wood)
		K.box(ctx, "DoorPostHead", V3(1.2, 2, 3), CFrame.new(x, 13.4, HZ0 + 2.4) * CFrame.Angles(DEG(-25), 0, 0), C.DARKWOOD, M.Wood)
	end
	K.box(ctx, "HallFloor", V3(HW * 2, 0.4, HZ0 - HZ1), V3(0, 0.2, (HZ0 + HZ1) / 2), Color3.fromRGB(96, 74, 54), M.WoodPlanks)
	-- inside: the long hearth, two long tables, pillars, braziers
	K.box(ctx, "Hearth", V3(5, 0.8, 14), V3(0, 0.8, -140), FROSTDARK, M.Slate)
	local embers = K.box(ctx, "HearthFire", V3(3.6, 0.3, 12), V3(0, 1.35, -140), Color3.fromRGB(255, 110, 40), M.Neon)
	embers.CanCollide = false
	local hf = Instance.new("Fire"); hf.Size = 5; hf.Heat = 4; hf.Parent = embers
	local hl = Instance.new("PointLight"); hl.Color = Color3.fromRGB(255, 160, 80); hl.Range = 30; hl.Brightness = 2.2; hl.Parent = embers
	for _, x in ipairs({-11, 11}) do
		K.box(ctx, "LongTable", V3(4, 0.5, 22), V3(x, 2.8, -134), C.WOOD, M.WoodPlanks)
		for _, z in ipairs({-124, -144}) do K.box(ctx, "TableLeg", V3(3, 2.6, 0.6), V3(x, 1.5, z), C.DARKWOOD, M.Wood) end
		for _, dx in ipairs({-3.4, 3.4}) do K.box(ctx, "LongBench", V3(1.4, 0.4, 22), V3(x + dx, 1.8, -134), C.WOOD, M.WoodPlanks) end
	end
	for _, x in ipairs({-18, 18}) do
		for _, z in ipairs({-124, -138, -152}) do
			K.cyl(ctx, "HallPillar", 2, hallH, V3(x, hallH / 2, z), C.DARKWOOD, M.Wood)
		end
	end
	-- the hall's capture zone, between the tables
	local s3 = K.objective(ctx, 3, "Capture", {Label = "Storm the great hall", Time = 26, AddTime = 120})
	K.zone(ctx, s3, "Zone", V3(0, 0.4, -124.5), 8.5, 12)
	-- the dais and the throne
	K.box(ctx, "Dais", V3(22, 1.6, 10), V3(0, 0.8, -154), FROSTDARK, M.Slate)
	K.stairs(ctx, CFrame.new(0, 0, -147.2), 10, 2, 0.8, 0.8, FROSTDARK, M.Slate)
	K.box(ctx, "Throne", V3(5, 2, 4), V3(0, 2.6, -156), C.DARKWOOD, M.Wood)
	K.box(ctx, "ThroneBack", V3(5, 8, 1), V3(0, 6, -157.6), C.DARKWOOD, M.Wood)
	K.box(ctx, "ThroneFur", V3(4.6, 0.3, 3.6), V3(0, 3.7, -155.8), Color3.fromRGB(226, 220, 206), M.Fabric).CanCollide = false
	for _, x in ipairs({-2.8, 2.8}) do K.ball(ctx, "ThroneKnob", 1.2, V3(x, 10.4, -157.6), C.GOLD, M.Metal) end
	for _, x in ipairs({-8, 8}) do
		local b = K.box(ctx, "HallBanner", V3(4, 10, 0.2), V3(x, 9, HZ1 + 1.4), HOUSE, M.Fabric)
		b.CanCollide = false
		K.box(ctx, "HallBannerStar", V3(1.4, 1.4, 0.3), V3(x, 11, HZ1 + 1.56), HOUSE2, M.Metal).CanCollide = false
	end
	for _, x in ipairs({-9, 9}) do K.torchPost(ctx, V3(x, 1.6, -152), 4) end
	local s4 = K.objective(ctx, 4, "Slay", {Label = "Slay the Jarl", Name = "Jarl Hrolf", Weapon = "Greatsword", Health = 220, PerAttacker = 70})
	local at = Instance.new("Part"); at.Name = "At"; at.Size = V3(1, 1, 1); at.Transparency = 1; at.Anchored = true; at.CanCollide = false; at.CanQuery = false
	at.CFrame = CFrame.lookAt(V3(0, 4.6, -152), V3(0, 4.6, -120)); at.Parent = s4
	at:SetAttribute("ArenaRadius", 26)

	----------------------------------------------------------------
	-- the attackers' camp (south)
	----------------------------------------------------------------
	for i, t in ipairs({{-34, 156, 20}, {-18, 172, -10}, {22, 164, 15}, {38, 150, -20}, {-44, 178, 5}, {44, 178, -5}}) do
		local tf = CFrame.new(t[1], 0, t[2]) * CFrame.Angles(0, DEG(t[3]), 0)
		K.tent(ctx, tf, 8, 10, 6, i % 2 == 0 and CAMP or Color3.fromRGB(176, 150, 112))
		snowOn(K.box(ctx, "TentSnow", V3(1.2, 0.2, 10.4), tf * CFrame.new(0, 6.1, 0), SNOW, M.Snow))
	end
	for _, p in ipairs({V3(0, 0, 176), V3(-26, 0, 140), V3(28, 0, 136)}) do
		K.cyl(ctx, "FireRing", 4, 0.6, p + V3(0, 0.3, 0), FROSTDARK, M.Slate)
		local fire = K.box(ctx, "Campfire", V3(1.8, 0.8, 1.8), p + V3(0, 0.8, 0), Color3.fromRGB(255, 120, 40), M.Neon)
		fire.CanCollide = false
		local f = Instance.new("Fire"); f.Size = 3.5; f.Heat = 6; f.Parent = fire
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 150, 70); l.Range = 18; l.Brightness = 1.6; l.Parent = fire
		for k = 0, 3 do K.cyl(ctx, "Log", 0.7, 3, CFrame.new(p + V3(0, 0.4, 0)) * CFrame.Angles(0, DEG(k * 45), DEG(90)), C.DARKWOOD, M.Wood).CanCollide = false end
	end
	-- siege ladders and a stack of timber waiting by the road
	for i = 0, 2 do
		local lf = CFrame.new(-16 + i * 1.6, 0.3, 112) * CFrame.Angles(0, DEG(8), 0)
		for _, x in ipairs({-1, 1}) do K.box(ctx, "LadderRail", V3(0.4, 0.4, 16), lf * CFrame.new(x, i * 0.4, 0), C.WOOD, M.Wood) end
		for r = -7, 7, 1.6 do K.box(ctx, "LadderRung", V3(2, 0.25, 0.25), lf * CFrame.new(0, i * 0.4, r), C.DARKWOOD, M.Wood) end
	end
	for i = 0, 3 do K.cyl(ctx, "Timber", 1.2, 10, CFrame.new(18, 0.6 + (i % 2) * 1.1, 110 + i * 1.3) * CFrame.Angles(0, DEG(90), DEG(90)), C.WOOD, M.Wood) end
	for _, p in ipairs({V3(-10, 0, 150), V3(12, 0, 154), V3(-30, 0, 120)}) do K.crate(ctx, p, 3, p.X * 3) end
	for _, p in ipairs({V3(30, 0, 120), V3(33, 0, 122)}) do K.barrel(ctx, p) end
	for _, x in ipairs({-8, 8}) do K.banner(ctx, V3(x, 0, 140), 10, CAMP) end
	-- a broken palisade at the camp's front, and stakes
	for i = -5, 5 do
		if math.abs(i) > 1 then
			local p = V3(i * 7, 0, 132 - math.abs(i) * 1.5)
			K.cyl(ctx, "Stake", 1, 6, CFrame.new(p + V3(0, 2.4, 0)) * CFrame.Angles(DEG(-30), 0, 0), C.WOOD, M.Wood)
		end
	end

	----------------------------------------------------------------
	-- the snowfield: pines, rocks, a frozen pond, old ruins for cover
	----------------------------------------------------------------
	local r = Random.new(41)
	for i = 1, 46 do
		local x = (i % 2 == 0 and 1 or -1) * r:NextNumber(80, 175)
		local z = r:NextNumber(-150, 220)
		snowPine(V3(x, 0, z), r:NextNumber(16, 28))
	end
	for i = 1, 14 do
		local x = (i % 2 == 0 and 1 or -1) * r:NextNumber(18, 70)
		local z = r:NextNumber(0, 120)
		if math.abs(x) > 14 then K.rock(ctx, V3(x, -0.4, z), r:NextNumber(3, 6), Color3.fromRGB(110, 116, 128)) end
	end
	-- ruins of an old watch post beside the road (cover for both sides)
	for _, w in ipairs({{V3(-30, 0, 66), V3(-30, 0, 80)}, {V3(-30, 0, 66), V3(-42, 0, 66)}, {V3(32, 0, 40), V3(44, 0, 40)}, {V3(32, 0, 40), V3(32, 0, 50)}}) do
		K.wall(ctx, w[1], w[2], 6, 2, {color = FROSTDARK})
	end
	K.cyl(ctx, "Pond", 26, 0.3, V3(-60, 0.1, 100), Color3.fromRGB(176, 206, 230), M.Ice)
	-- snow drifts against the castle walls
	for i = -6, 6 do
		if math.abs(i) > 1 then
			local d = K.box(ctx, "Drift", V3(9, 1.4, 4), CFrame.new(i * 10, 0.4, ZF + 4.6) * CFrame.Angles(DEG(-12), DEG(i * 7), 0), SNOW, M.Snow)
			d.CanCollide = false
		end
	end

	----------------------------------------------------------------
	-- snowfall over the field (one emitter high above)
	----------------------------------------------------------------
	do
		local sky = K.box(ctx, "Snowfall", V3(300, 1, 360), V3(0, 70, 0), SNOW, M.SmoothPlastic)
		sky.Transparency = 1; sky.CanCollide = false; sky.CanQuery = false; sky.CanTouch = false
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.new(1, 1, 1))
		e.Size = NumberSequence.new(0.28)
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.9, 0.3), NumberSequenceKeypoint.new(1, 1)})
		e.Lifetime = NumberRange.new(9, 12)
		e.Speed = NumberRange.new(6, 8)
		e.EmissionDirection = Enum.NormalId.Bottom
		e.SpreadAngle = Vector2.new(12, 12)
		e.Rate = 260
		e.LightInfluence = 1
		e.Parent = sky
	end

	----------------------------------------------------------------
	-- spawns (Side / Stage) and cameras
	----------------------------------------------------------------
	local function sp(pos, side, stage, look)
		local p = K.spawn(ctx, pos, nil, look)
		p:SetAttribute("Side", side)
		p:SetAttribute("Stage", stage)
		return p
	end
	-- attackers: the camp; then the road below the gate; then inside the gate
	for i = -3, 3 do sp(V3(i * 5, 1, 166), "Attack", 1, V3(0, 1, 0)) end
	for i = -3, 3 do sp(V3(i * 5, 1, 28 + math.abs(i) * 2), "Attack", 2, V3(0, 1, -60)) end
	for i = -3, 3 do sp(V3(i * 6, 1, -42), "Attack", 3, V3(0, 1, -120)) end
	-- defenders: out in front of their gate; then the north of the bailey; then round the hall
	for i = 1, 4 do sp(V3(-20 - i * 4, 1, -20), "Defend", 1, V3(0, 1, 60)); sp(V3(20 + i * 4, 1, -20), "Defend", 1, V3(0, 1, 60)) end
	for i = -3, 3 do sp(V3(i * 9, 1, -104), "Defend", 2, V3(0, 1, -40)) end
	for i = 1, 3 do sp(V3(-40 - i * 4, 1, -150), "Defend", 3, V3(0, 1, -120)); sp(V3(40 + i * 4, 1, -150), "Defend", 3, V3(0, 1, -120)) end
	-- plain team spawns too (any mode that isn't Siege): the camp and the bailey
	for i = -2, 2 do K.spawn(ctx, V3(i * 6, 1, 160), "A", V3(0, 1, 0)); K.spawn(ctx, V3(i * 6, 1, -96), "B", V3(0, 1, 0)) end
	K.camera(ctx, V3(-30, 26, 170), V3(0, 10, -30))
	K.camera(ctx, V3(26, 10, 4), V3(0, 12, -30))
	K.camera(ctx, V3(-16, 8, -110), V3(0, 6, -156))
	K.lighting(ctx, {ClockTime = 14.2, FogEnd = 520, FogStart = 60, FogColor = Color3.fromRGB(206, 214, 228), Brightness = 1.7,
		OutdoorAmbient = Color3.fromRGB(160, 170, 190), Ambient = Color3.fromRGB(96, 104, 120), ColorShift_Top = Color3.fromRGB(196, 210, 236)})
	return K.finish(ctx)
end
