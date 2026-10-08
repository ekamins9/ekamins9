--[[ THE TRAINING YARD — a palisaded field below a castle wall, where you
     learn to fight (the Tiltyard mode). Built by Build ▸ Maps:

       require(game.ServerScriptService.Build.Maps).build("TrainingYard")

     North to south: the castle wall and its towers; the Drill Master's
     platform under a blue awning, the lesson circle in front of it; the
     straw dummies down the west side; the sparring ring on the east, with
     its challenge sign; the archery range along the north-west wall (Wren
     the Bowmaster); the arcane circle in the north (Magister Orrin); tents,
     racks, hay and torches by the south gate, where you arrive.
     Spots (Map ▸ Spots, for Game ▸ Training): DrillMaster, LessonAttacker,
     LessonBlocker, Dummy1..6, Ring (Radius), RingPlayer, RingBot, RingSign,
     Bowmaster, ArcheryTarget1..3, ArcheryLine, ArcheryFar, ArcheryCharge,
     Magister, MageTarget1..3, MageCircle, MageCharge. ]]

return function(K)
	local C, M = K.C, K.M
	local V3 = Vector3.new
	local ctx = K.new("TrainingYard")
	K.terrain(ctx, V3(-208, -72, -240), V3(416, 112, 448), function(T)
		T:FillBlock(CFrame.new(0, -6, 0), V3(380, 12, 380), Enum.Material.Grass)
		-- the yard: packed sand inside the palisade, a dirt road out of the gate
		T:FillBlock(CFrame.new(0, -2, 0), V3(158, 4, 128), Enum.Material.Sand)
		T:FillBlock(CFrame.new(0, -2, 110), V3(16, 4, 100), Enum.Material.Ground)
		-- hills behind the castle
		for i = -3, 3 do T:FillBall(V3(i * 50, -20, -170 - (i % 2) * 12), 48, Enum.Material.Grass) end
	end)
	K.terrainColors(ctx, {Grass = Color3.fromRGB(98, 150, 70), Sand = Color3.fromRGB(206, 182, 128), Ground = Color3.fromRGB(122, 98, 70)})

	-- the palisade (a gate gap on the south side)
	local X, Z = 80, 65
	K.palisade(ctx, V3(-X, 0, -Z), V3(X, 0, -Z))
	K.palisade(ctx, V3(-X, 0, -Z), V3(-X, 0, Z))
	K.palisade(ctx, V3(X, 0, -Z), V3(X, 0, Z))
	K.palisade(ctx, V3(-X, 0, Z), V3(-8, 0, Z))
	K.palisade(ctx, V3(8, 0, Z), V3(X, 0, Z))
	-- gate towers: four posts, a platform, a little roof
	for _, sx in ipairs({-1, 1}) do
		local base = V3(sx * 11, 0, Z)
		for _, dx in ipairs({-2.5, 2.5}) do
			for _, dz in ipairs({-2.5, 2.5}) do K.cyl(ctx, "TowerPost", 0.9, 12, base + V3(dx, 6, dz), C.DARKWOOD, M.Wood) end
		end
		K.box(ctx, "TowerFloor", V3(6.5, 0.5, 6.5), base + V3(0, 9, 0), C.WOOD, M.WoodPlanks)
		for _, a in ipairs({0, 90, 180, 270}) do
			K.box(ctx, "TowerWall", V3(6.5, 1.8, 0.4), CFrame.new(base + V3(0, 10, 0)) * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 0, 3.1), C.WOOD, M.WoodPlanks)
		end
		K.cone(ctx, "TowerRoof", base + V3(0, 12, 0), 4.8, 3.6, C.RED, M.Fabric, nil, false, 4)
		K.banner(ctx, base + V3(sx * 4.2, 0, 2.6), 9, C.BLUE)
	end
	K.box(ctx, "GateBeam", V3(22, 1.2, 1.2), V3(0, 11.5, Z), C.DARKWOOD, M.Wood)

	-- the castle wall to the north, with towers
	K.wall(ctx, V3(-120, 0, -96), V3(120, 0, -96), 16, 6, {crenels = true, base = true})
	for _, x in ipairs({-90, -30, 30, 90}) do K.tower(ctx, V3(x, 0, -96), 7, 22, {roof = (x == -30 or x == 30), roofColor = C.BLUE, windows = true}) end

	-- the Drill Master's platform and the lesson circle
	K.box(ctx, "Platform", V3(18, 1.6, 10), V3(0, 0.8, -36), C.WOOD, M.WoodPlanks)
	K.box(ctx, "PlatformEdge", V3(18.6, 0.4, 10.6), V3(0, 1.6, -36), C.DARKWOOD, M.Wood).CanCollide = false
	K.stairs(ctx, CFrame.new(0, 0, -28.6), 6, 2, 0.8, 1.2, C.WOOD, M.WoodPlanks)
	K.awning(ctx, V3(0, 1.6, -37), 16, 8, 7, C.BLUE)
	K.rack(ctx, CFrame.new(-6.5, 1.6, -40) * CFrame.Angles(0, math.pi, 0))
	K.rack(ctx, CFrame.new(6.5, 1.6, -40) * CFrame.Angles(0, math.pi, 0))
	K.banner(ctx, V3(-10.5, 0, -32), 10, C.BLUE)
	K.banner(ctx, V3(10.5, 0, -32), 10, C.BLUE)
	K.spot(ctx, "DrillMaster", CFrame.lookAt(V3(0, 4.6, -35), V3(0, 4.6, 0)))
	-- the lesson circle: a ring of stones on the sand
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		K.box(ctx, "CircleStone", V3(1.4, 0.4, 1), CFrame.new(math.cos(a) * 11, 0.2, -14 + math.sin(a) * 11) * CFrame.Angles(0, -a, 0), C.STONE, M.Slate).CanCollide = false
	end
	K.spot(ctx, "LessonAttacker", CFrame.lookAt(V3(-5, 3, -18), V3(-5, 3, 0)))
	K.spot(ctx, "LessonBlocker", CFrame.lookAt(V3(5, 3, -18), V3(5, 3, 0)))

	-- the straw dummies down the west side, each on a sand pad with a post
	K.box(ctx, "DummySign", V3(0.4, 3, 8), V3(-46, 4.6, -46), C.WOOD, M.WoodPlanks)
	for _, z in ipairs({-49, -43}) do K.pole(ctx, V3(-46, 0, z), 3.2) end
	for i = 1, 6 do
		local z = -40 + (i - 1) * 12
		K.cyl(ctx, "DummyPad", 7, 0.2, V3(-62, 0.15, z), Color3.fromRGB(186, 160, 110), M.Sand).CanCollide = false
		K.cyl(ctx, "DummyPost", 0.6, 7, V3(-64.5, 3.5, z), C.DARKWOOD, M.Wood)
		K.box(ctx, "DummyArm", V3(0.4, 0.4, 3), V3(-64.5, 6.6, z), C.DARKWOOD, M.Wood)
		K.spot(ctx, "Dummy" .. i, CFrame.lookAt(V3(-62, 3, z), V3(0, 3, z)))
	end
	K.hay(ctx, V3(-70, 0, 30)); K.hay(ctx, V3(-72, 0, 36)); K.hay(ctx, V3(-66, 0, 40))

	-- the sparring ring on the east side
	local ring = V3(48, 0, -6)
	K.cyl(ctx, "RingFloor", 31, 0.3, ring + V3(0, 0.15, 0), Color3.fromRGB(220, 196, 140), M.Sand)
	local posts = {}
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local p = ring + V3(math.cos(a) * 15.5, 0, math.sin(a) * 15.5)
		K.cyl(ctx, "RingPost", 0.6, 3.6, p + V3(0, 1.8, 0), C.DARKWOOD, M.Wood)
		posts[i] = p
	end
	for i = 0, 11 do
		local a, b = posts[i], posts[(i + 1) % 12]
		-- the way in faces the yard (west): no rope there
		if not (i == 5 or i == 6) then
			K.rope(ctx, a + V3(0, 3.1, 0), b + V3(0, 3.1, 0), Color3.fromRGB(190, 40, 40))
			K.rope(ctx, a + V3(0, 1.9, 0), b + V3(0, 1.9, 0))
		end
	end
	K.spot(ctx, "Ring", CFrame.new(ring + V3(0, 1, 0)), {Radius = 14})
	K.spot(ctx, "RingPlayer", CFrame.lookAt(ring + V3(-8, 3, 0), ring + V3(0, 3, 0)))
	K.spot(ctx, "RingBot", CFrame.lookAt(ring + V3(8, 3, 0), ring + V3(0, 3, 0)))
	-- the challenge sign: a big board facing the yard
	local signCF = CFrame.lookAt(V3(24, 0, -28), V3(0, 0, -28))
	for _, x in ipairs({-3.6, 3.6}) do K.box(ctx, "SignPost", V3(0.5, 6.4, 0.5), signCF * CFrame.new(x, 3.2, 0), C.DARKWOOD, M.Wood) end
	K.box(ctx, "SignBoard", V3(8.4, 4.6, 0.4), signCF * CFrame.new(0, 4.4, 0), C.WOOD, M.WoodPlanks)
	K.spot(ctx, "RingSign", signCF * CFrame.new(0, 4.4, -0.25))
	K.banner(ctx, ring + V3(-4, 0, -17.5), 9, C.RED)
	K.banner(ctx, ring + V3(4, 0, -17.5), 9, C.RED)

	-- log benches round the lesson circle (you can sit and watch)
	for i, a in ipairs({140, 180, 220}) do
		local r = math.rad(a)
		local pos = V3(math.sin(r) * 15, 0.6, -14 - math.cos(r) * 15)
		local log = K.cyl(ctx, "BenchLog", 1.2, 6, CFrame.new(pos) * CFrame.Angles(0, -r, 0) * CFrame.Angles(0, 0, math.rad(90)), C.WOOD, M.Wood)
		local seat = Instance.new("Seat"); seat.Name = "Seat"; seat.Size = V3(2, 0.4, 2); seat.Transparency = 1; seat.Anchored = true; seat.CanCollide = false
		seat.CFrame = CFrame.lookAt(pos + V3(0, 0.5, 0), V3(0, 1.1, -14)); seat.Parent = log.Parent
	end
	-- pells: wrapped practice posts in the middle of the yard
	for i, p in ipairs({V3(-26, 0, 4), V3(-18, 0, 8), V3(-26, 0, 14), V3(-18, 0, 18)}) do
		K.cyl(ctx, "Pell", 1.1, 6, p + V3(0, 3, 0), C.DARKWOOD, M.Wood)
		K.cyl(ctx, "PellWrap", 1.5, 2.2, p + V3(0, 3.6, 0), C.THATCH, M.Fabric)
		K.box(ctx, "PellNotch", V3(1.6, 0.25, 1.6), p + V3(0, 2.4, 0), C.ROPE, M.Fabric).CanCollide = false
	end
	-- a weapon cart, spears bristling out of it
	do
		local cartCF = CFrame.new(24, 0, 32) * CFrame.Angles(0, math.rad(20), 0)
		K.box(ctx, "CartBed", V3(5, 1.6, 8), cartCF * CFrame.new(0, 2.2, 0), C.WOOD, M.WoodPlanks)
		for _, x in ipairs({-2.8, 2.8}) do
			for _, z in ipairs({-2.6, 2.6}) do K.cyl(ctx, "Wheel", 2.6, 0.5, cartCF * CFrame.new(x, 1.3, z) * CFrame.Angles(0, 0, math.rad(90)), C.DARKWOOD, M.Wood) end
		end
		for k = 1, 6 do
			local sp = K.box(ctx, "Spear", V3(0.18, 6, 0.18), cartCF * CFrame.new(-1.6 + (k % 3) * 1.6, 4.6, -2 + math.floor(k / 3) * 2) * CFrame.Angles(math.rad(-18 + k * 4), 0, math.rad(-10 + k * 3)), C.WOOD, M.Wood)
			sp.CanCollide = false
		end
	end
	-- the practice ground (north-east, between the ring and the butts): call
	-- up bots at the sign and fight them here
	do
		local pg = V3(44, 0, -40)
		K.cyl(ctx, "PracticeFloor", 26, 0.3, pg + V3(0, 0.15, 0), Color3.fromRGB(196, 168, 118), M.Sand)
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			if i ~= 3 then   -- a gap on the side facing the yard
				K.box(ctx, "PracticeStone", V3(1.6, 0.7, 1.1), CFrame.new(pg + V3(math.cos(a) * 13.6, 0.35, math.sin(a) * 13.6)) * CFrame.Angles(0, -a, 0), C.STONE, M.Slate)
			end
		end
		K.banner(ctx, pg + V3(-12, 0, -10), 10, C.RED)
		K.banner(ctx, pg + V3(12, 0, -10), 10, C.RED)
		K.rack(ctx, CFrame.new(pg + V3(0, 0, -15.5)) * CFrame.Angles(0, 0, 0))
		local signCF = CFrame.lookAt(pg + V3(-4, 0, 15), pg + V3(-4, 0, 30))
		for _, x in ipairs({-3.6, 3.6}) do K.box(ctx, "PracticeSignPost", V3(0.6, 6, 0.6), signCF * CFrame.new(x, 3, 0), C.DARKWOOD, M.Wood) end
		K.box(ctx, "PracticeSignBoard", V3(8.4, 3.6, 0.4), signCF * CFrame.new(0, 4.6, 0), C.WOOD, M.WoodPlanks)
		K.spot(ctx, "PracticeSign", signCF * CFrame.new(0, 4.6, -0.25))
		K.spot(ctx, "Practice", CFrame.new(pg + V3(0, 1, 0)), {Radius = 12})
	end

	-- THE ARCHERY RANGE (Wren the Bowmaster's): a lane down the north-west wall,
	-- straw targets before straw butts at the far end, a near line and a far line
	do
		K.box(ctx, "RangeLane", V3(26, 0.12, 54), V3(-30, 0.06, -35), Color3.fromRGB(214, 190, 136), M.Sand).CanCollide = false
		for i, x in ipairs({-38, -30, -22}) do
			K.box(ctx, "ButtStand", V3(0.4, 5, 0.4), V3(x - 1.4, 2.5, -61), C.DARKWOOD, M.Wood)
			K.box(ctx, "ButtStand", V3(0.4, 5, 0.4), V3(x + 1.4, 2.5, -61), C.DARKWOOD, M.Wood)
			K.cyl(ctx, "Butt", 4.4, 1.2, CFrame.new(x, 4.6, -60.4) * CFrame.Angles(math.rad(90), 0, 0), C.THATCH, M.Fabric)
			K.cyl(ctx, "ButtRing", 3, 1.25, CFrame.new(x, 4.6, -60.4) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(190, 40, 36), M.Fabric).CanCollide = false
			K.cyl(ctx, "ButtEye", 1.2, 1.3, CFrame.new(x, 4.6, -60.4) * CFrame.Angles(math.rad(90), 0, 0), C.GOLD, M.Fabric).CanCollide = false
			K.cyl(ctx, "TargetPad", 4, 0.2, V3(x, 0.15, -56), Color3.fromRGB(186, 160, 110), M.Sand).CanCollide = false
			K.spot(ctx, "ArcheryTarget" .. i, CFrame.lookAt(V3(x, 3, -56), V3(x, 3, 0)))
		end
		-- the lines: rope on stakes (the near one twenty paces out, the far one forty-five)
		for _, z in ipairs({-34, -11}) do
			K.box(ctx, "ShootLine", V3(24, 0.14, 0.6), V3(-30, 0.08, z), C.WHITE, M.SmoothPlastic).CanCollide = false
			for _, x in ipairs({-42.5, -17.5}) do K.pole(ctx, V3(x, 0, z), 2.2) end
		end
		K.spot(ctx, "ArcheryLine", CFrame.lookAt(V3(-30, 3, -32), V3(-30, 3, -56)))
		K.spot(ctx, "ArcheryFar", CFrame.lookAt(V3(-30, 3, -9), V3(-30, 3, -56)))
		K.spot(ctx, "ArcheryCharge", CFrame.lookAt(V3(-41, 3, -59), V3(-30, 3, -30)))
		-- the Bowmaster's corner: a rack of bows, a barrel of arrows, a red banner
		K.spot(ctx, "Bowmaster", CFrame.lookAt(V3(-47, 3, -33), V3(-30, 3, -33)))
		K.rack(ctx, CFrame.new(-50, 0, -29) * CFrame.Angles(0, math.rad(90), 0))
		K.barrel(ctx, V3(-49, 0, -37))
		K.banner(ctx, V3(-47, 0, -39), 9, C.RED)
	end

	-- THE ARCANE CIRCLE (Magister Orrin's): a ring of rune stones glowing on the
	-- sand, three straw dummies standing close together beyond it
	do
		local ctr = V3(21, 0, -47)
		local RUNE = Color3.fromRGB(150, 100, 255)
		K.cyl(ctx, "CircleFloor", 15, 0.2, ctr + V3(0, 0.12, 0), Color3.fromRGB(70, 60, 96), M.Slate).CanCollide = false
		K.cyl(ctx, "CircleGlow", 13.4, 0.24, ctr + V3(0, 0.13, 0), RUNE, M.Neon).CanCollide = false
		K.cyl(ctx, "CircleInner", 12.8, 0.26, ctr + V3(0, 0.14, 0), Color3.fromRGB(56, 48, 80), M.Slate).CanCollide = false
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			local p = ctr + V3(math.cos(a) * 8.4, 0, math.sin(a) * 8.4)
			K.box(ctx, "RuneStone", V3(1, 2.6 + (i % 2) * 0.8, 0.7), CFrame.new(p + V3(0, 1.3, 0)) * CFrame.Angles(0, -a, 0), C.STONEDARK, M.Slate)
			K.box(ctx, "RuneMark", V3(0.2, 0.9, 0.74), CFrame.new(p + V3(0, 1.7, 0)) * CFrame.Angles(0, -a, 0) * CFrame.new(-0.45, 0, 0), RUNE, M.Neon).CanCollide = false
		end
		K.spot(ctx, "MageCircle", CFrame.new(ctr + V3(0, 1, 0)), {Radius = 7})
		for i, x in ipairs({16.5, 21, 25.5}) do
			K.cyl(ctx, "TargetPad", 4, 0.2, V3(x, 0.15, -59 + (i == 2 and -1.5 or 0)), Color3.fromRGB(186, 160, 110), M.Sand).CanCollide = false
			K.spot(ctx, "MageTarget" .. i, CFrame.lookAt(V3(x, 3, -59 + (i == 2 and -1.5 or 0)), V3(21, 3, -40)))
		end
		K.spot(ctx, "MageCharge", CFrame.lookAt(V3(28, 3, -62), V3(21, 3, -45)))
		K.spot(ctx, "Magister", CFrame.lookAt(V3(21, 3, -35.5), V3(21, 3, 0)))
		K.banner(ctx, ctr + V3(-9.5, 0, 9), 9, Color3.fromRGB(96, 56, 170))
		K.banner(ctx, ctr + V3(9.5, 0, 9), 9, Color3.fromRGB(96, 56, 170))
	end

	-- the camp by the gate
	K.tent(ctx, CFrame.new(-50, 0, 46) * CFrame.Angles(0, math.rad(90), 0), 8, 10, 6, C.WHITE)
	K.tent(ctx, CFrame.new(-36, 0, 50) * CFrame.Angles(0, math.rad(80), 0), 7, 9, 5.5, Color3.fromRGB(196, 72, 62))
	K.tent(ctx, CFrame.new(46, 0, 46) * CFrame.Angles(0, math.rad(-90), 0), 8, 10, 6, Color3.fromRGB(70, 96, 190))
	K.rack(ctx, CFrame.new(30, 0, 52) * CFrame.Angles(0, math.rad(-90), 0))
	K.rack(ctx, CFrame.new(-26, 0, 54) * CFrame.Angles(0, math.rad(90), 0))
	for _, p in ipairs({V3(-24, 0, 40), V3(-20, 0, 42), V3(22, 0, 38)}) do K.barrel(ctx, p) end
	for i, p in ipairs({V3(60, 0, 30), V3(63, 0, 33), V3(-58, 0, -54)}) do K.crate(ctx, p, 3, i * 17) end
	-- a water trough
	K.box(ctx, "Trough", V3(6, 1.6, 2), V3(-12, 0.8, 30), C.WOOD, M.WoodPlanks)
	K.box(ctx, "TroughWater", V3(5.4, 0.2, 1.4), V3(-12, 1.45, 30), C.WATER, M.Glass).CanCollide = false
	-- torches round the yard
	for _, p in ipairs({V3(-13, 0, -28), V3(12, 0, -27), V3(-40, 0, 0), V3(30, 0, 14), V3(-14, 0, 56), V3(14, 0, 56), V3(-54, 0, -24), V3(66, 0, -26)}) do K.torchPost(ctx, p) end
	-- trees outside the palisade
	local r = Random.new(11)
	for i = 1, 36 do
		local a = r:NextNumber(0, math.pi * 2)
		local d = r:NextNumber(110, 175)
		local p = V3(math.cos(a) * d, 0, math.sin(a) * d)
		if p.Z > -80 then K.tree(ctx, p, r:NextNumber(11, 19)) end
	end

	-- arrive by the gate, facing in
	for i = -2, 2 do K.spawn(ctx, V3(i * 4, 1, 54), nil, V3(i * 4, 1, 0)) end
	K.camera(ctx, V3(-70, 34, 90), V3(0, 4, -10))
	K.camera(ctx, V3(70, 22, 40), V3(40, 2, -10))
	K.camera(ctx, V3(0, 14, 20), V3(0, 5, -36))
	K.lighting(ctx, {ClockTime = 10.2, FogEnd = 900, FogColor = Color3.fromRGB(200, 214, 230), Brightness = 2.4, OutdoorAmbient = Color3.fromRGB(140, 140, 130), Ambient = Color3.fromRGB(86, 84, 78)})
	return K.finish(ctx)
end
