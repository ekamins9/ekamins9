--[[ RAVENHOLD — the ruins of a keep under a full moon. The curtain wall still
     stands, mostly: the main gate's doors lie smashed under the arch, three
     breaches have been knocked through and the south-west corner has fallen
     in. Inside, a roofless chapel, a well, a gibbet on a dead tree, a little
     graveyard and braziers someone keeps lit. Mist hangs outside the walls and
     the Horde comes through it, in at every opening (Spots HordeGate1..5, a
     dozen studs outside each). Built by
       require(game.ServerScriptService.Build.Maps).build("Ravenhold")
     Used by Horde. ]]

return function(K)
	require(script.Parent:WaitForChild("MapProps"))(K)
	local C, M = K.C, K.M
	local V3 = Vector3.new
	local DEG = math.rad
	local ctx = K.new("Ravenhold")
	local rng = Random.new(53)

	local HALF = 42                          -- the curtain wall's centre line, each way from the middle
	local WALL_H, WALL_T = 14, 4
	local STONES = {Color3.fromRGB(108, 110, 108), Color3.fromRGB(96, 98, 98), Color3.fromRGB(118, 116, 110)}
	local DARK = Color3.fromRGB(74, 76, 78)
	local function stone() return STONES[rng:NextInteger(1, #STONES)] end

	-- the openings: where the Horde gets in (centre of each, outside, and the way in)
	local OPENINGS = {
		{name = "gate",   at = V3(0, 0, -HALF)},
		{name = "east",   at = V3(HALF, 0, 11)},
		{name = "west",   at = V3(-HALF, 0, -13)},
		{name = "south",  at = V3(-8, 0, HALF)},
		{name = "corner", at = V3(-HALF + 4, 0, HALF - 4)},
	}
	local function nearApproach(p, half)
		-- keep the ground in front of every opening clear (trees, rocks)
		for _, o in ipairs(OPENINGS) do
			local d = o.at.Unit
			local along = p:Dot(d)
			local side = (p - d * along).Magnitude
			if along > HALF - 6 and side < (half or 14) then return true end
		end
		return false
	end

	-- THE GROUND -------------------------------------------------------------
	-- moonlit grass outside, the courtyard's old cobbles half grown over, a
	-- track from the gate out into the dark
	K.terrain(ctx, V3(-200, -48, -200), V3(400, 96, 400), function(T)
		T:FillBlock(CFrame.new(0, -8, 0), V3(400, 16, 400), M.Grass)
		local Terrain = workspace.Terrain
		local region = Region3.new(V3(-200, -20, -200), V3(200, 4, 200)):ExpandToGrid(4)
		local mats, occs = Terrain:ReadVoxels(region, 4)
		local lo = region.CFrame.Position - region.Size / 2
		for ix = 1, mats.Size.X do
			local x = lo.X + (ix - 0.5) * 4
			for iz = 1, mats.Size.Z do
				local z = lo.Z + (iz - 0.5) * 4
				local n = math.noise(x / 18, 0.3, z / 18)
				local mat = M.Grass
				if math.abs(x) < HALF and math.abs(z) < HALF then
					mat = n > -0.12 and M.Cobblestone or M.Grass
				elseif math.abs(x) < 6 + math.noise(z / 9, 2) * 2 and z < -HALF then
					mat = M.Ground                                   -- the track out of the gate
				elseif n > 0.32 then
					mat = M.Ground
				end
				for iy = 1, mats.Size.Y do
					if mats[ix][iy][iz] ~= M.Air then mats[ix][iy][iz] = mat end
				end
			end
		end
		Terrain:WriteVoxels(region, 4, mats, occs)
		-- low hills all round, black against the sky
		for i = 1, 12 do
			local a = DEG(i / 12 * 360 + rng:NextNumber(-10, 10))
			local d = rng:NextNumber(130, 170)
			T:Mound(V3(math.cos(a) * d, 0, math.sin(a) * d), rng:NextNumber(12, 28), 6, 44, M.Grass)
		end
	end)
	K.terrainColors(ctx, {Grass = Color3.fromRGB(70, 88, 62), Cobblestone = Color3.fromRGB(122, 120, 114), Ground = Color3.fromRGB(88, 76, 62)})

	-- THE CURTAIN WALL --------------------------------------------------------
	-- a ruined wall from a to b: built in short courses whose tops wander, and
	-- crumbling lower toward each gap (`gaps` = {from, to} studs along it;
	-- clean = a built opening, no crumbling)
	local function ruinWall(a, b, h, t, gaps)
		local d = b - a
		local len = d.Magnitude
		local look = CFrame.lookAt(a, b)
		local n = math.ceil(len / 3.5)
		local step = len / n
		for i = 0, n - 1 do
			local mid = (i + 0.5) * step
			local inGap, near = false, math.huge
			for _, g in ipairs(gaps or {}) do
				if mid > g[1] and mid < g[2] then inGap = true end
				if not g.clean then near = math.min(near, math.abs(mid - g[1]), math.abs(mid - g[2])) end
			end
			if not inGap then
				local f = math.clamp((near - 1) / 11, 0.22, 1)
				local hh = h * f * rng:NextNumber(0.88, 1)
				if f >= 1 and rng:NextNumber() < 0.14 then hh = h * rng:NextNumber(0.62, 0.8) end   -- a bite out of the top
				K.box(ctx, "Wall", V3(t, hh, step + 0.04), look * CFrame.new(0, hh / 2, -mid), stone(), M.Slate)
				K.box(ctx, "Footing", V3(t + 1.2, 1.4, step + 0.04), look * CFrame.new(0, 0.7, -mid), DARK, M.Slate)
				if hh > h * 0.93 and i % 2 == 0 then
					K.box(ctx, "Crenel", V3(t, 1.6, 1.6), look * CFrame.new(0, hh + 0.8, -mid), stone(), M.Slate)
				end
				-- ivy down the inner face, here and there
				if rng:NextNumber() < 0.18 then
					local ih = hh * rng:NextNumber(0.4, 0.8)
					K.box(ctx, "Ivy", V3(0.2, ih, step * rng:NextNumber(0.5, 1)), look * CFrame.new(t / 2 + 0.1, hh - ih / 2, -mid), Color3.fromRGB(52, 74, 46), M.Grass, ctx.Props).CanCollide = false
				end
			end
		end
		-- what came down: heaps at each side of a breach, loose stones across it
		for _, g in ipairs(gaps or {}) do
			if not g.clean then
				local across = look.RightVector
				for _, s in ipairs({g[1] - 1.5, g[2] + 1.5}) do
					K.rock(ctx, (look * CFrame.new(0, 0, -s)).Position + across * rng:NextNumber(-3, 3), rng:NextNumber(3.5, 5), DARK)
				end
				for _ = 1, 14 do
					local s = rng:NextNumber(g[1], g[2])
					local p = (look * CFrame.new(0, 0, -s)).Position + across * rng:NextNumber(-9, 9)
					local sz = rng:NextNumber(0.6, 1.6)
					K.box(ctx, "Rubble", V3(sz, sz * 0.7, sz * rng:NextNumber(0.8, 1.6)), CFrame.new(p + V3(0, sz * 0.3, 0)) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 6), rng:NextNumber(0, 1)), stone(), M.Slate, ctx.Props).CanCollide = false
				end
			end
		end
	end

	local NW, NE, SE, SW = V3(-HALF, 0, -HALF), V3(HALF, 0, -HALF), V3(HALF, 0, HALF), V3(-HALF, 0, HALF)
	ruinWall(NW, NE, WALL_H, WALL_T, {{HALF - 8, HALF + 8, clean = true}})          -- north: the gatehouse
	ruinWall(NE, SE, WALL_H, WALL_T, {{HALF + 4, HALF + 18}})                       -- east: a breach
	ruinWall(NW, SW, WALL_H, WALL_T, {{HALF - 20, HALF - 6}, {2 * HALF - 12, 2 * HALF + 1}})   -- west: a breach, and the fallen corner
	ruinWall(SW, SE, WALL_H, WALL_T, {{-1, 12}, {HALF - 14, HALF - 2}})              -- south: the fallen corner, a breach

	-- corner towers: three still standing, the south-east one broken off
	for _, p in ipairs({NW, NE}) do K.tower(ctx, p, 5.5, 19, {color = stone(), base = 2.4, baseColor = DARK, windows = true}) end
	K.cyl(ctx, "BrokenTower", 11, 11, SE + V3(0, 5.5, 0), stone(), M.Slate)
	K.cyl(ctx, "TowerFooting", 13.4, 2.4, SE + V3(0, 1.2, 0), DARK, M.Slate)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local hh = rng:NextNumber(1, 5)
		K.box(ctx, "Jag", V3(2.6, hh, 3), CFrame.new(SE + V3(math.cos(a) * 4.4, 11 + hh / 2, math.sin(a) * 4.4)) * CFrame.Angles(0, -a, 0), stone(), M.Slate)
	end
	K.rock(ctx, SE + V3(-9, 0, 2), 5, DARK)
	K.rock(ctx, SE + V3(3, 0, -10), 4.5, DARK)

	-- THE GATEHOUSE ------------------------------------------------------------
	local gate = CFrame.new(0, 0, -HALF)
	K.arch(ctx, gate, 12, 12, WALL_T + 2, stone(), M.Slate)
	K.tower(ctx, V3(-12.5, 0, -HALF - 1), 4.6, 21, {color = stone(), base = 2.4, baseColor = DARK, windows = true})
	-- the east gate tower lost its top
	K.cyl(ctx, "BrokenTower", 9.2, 16, V3(12.5, 8, -HALF - 1), stone(), M.Slate)
	K.cyl(ctx, "TowerFooting", 11.6, 2.4, V3(12.5, 1.2, -HALF - 1), DARK, M.Slate)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local hh = rng:NextNumber(1, 4)
		K.box(ctx, "Jag", V3(2.2, hh, 2.6), CFrame.new(V3(12.5, 16 + hh / 2, -HALF - 1) + V3(math.cos(a) * 3.6, 0, math.sin(a) * 3.6)) * CFrame.Angles(0, -a, 0), stone(), M.Slate)
	end
	-- the portcullis, jammed half up, and the doors: one torn off and flat on
	-- the cobbles, one hanging off its last hinge
	for i = -5, 5 do
		K.box(ctx, "Portcullis", V3(0.3, 5, 0.3), gate * CFrame.new(i * 1.1, 10.5, -1.6), C.IRON, M.Metal)
	end
	for y = 8.6, 12.6, 1.3 do K.box(ctx, "Portcullis", V3(12, 0.3, 0.3), gate * CFrame.new(0, y, -1.6), C.IRON, M.Metal) end
	local door = Color3.fromRGB(72, 50, 32)
	K.box(ctx, "Door", V3(6, 0.6, 10.5), gate * CFrame.new(-1.5, 0.35, 8.5) * CFrame.Angles(0, DEG(14), DEG(3)), door, M.WoodPlanks, ctx.Props)
	K.box(ctx, "DoorBand", V3(6.1, 0.65, 0.5), gate * CFrame.new(-1.5, 0.37, 6.4) * CFrame.Angles(0, DEG(14), DEG(3)), C.IRON, M.Metal, ctx.Props).CanCollide = false
	K.box(ctx, "DoorBand", V3(6.1, 0.65, 0.5), gate * CFrame.new(-0.6, 0.37, 11) * CFrame.Angles(0, DEG(14), DEG(3)), C.IRON, M.Metal, ctx.Props).CanCollide = false
	K.box(ctx, "Door", V3(0.6, 10.5, 6), gate * CFrame.new(6.3, 5.4, 3.4) * CFrame.Angles(0, DEG(-8), DEG(-9)), door, M.WoodPlanks, ctx.Props)
	for _, x in ipairs({-8.4, 8.4}) do
		K.torch(ctx, (gate * CFrame.new(x, 7, 3.4)).Position, 0)
		K.torch(ctx, (gate * CFrame.new(x, 7, -3.6)).Position, 180)
	end
	for _ = 1, 9 do
		local p = (gate * CFrame.new(rng:NextNumber(-12, 12), 0, rng:NextNumber(-14, -4))).Position
		K.arrow(ctx, p + V3(0, 0.6, 0), V3(rng:NextNumber(-0.3, 0.3), -0.8, rng:NextNumber(-0.3, 0.3)))
	end

	-- THE COURTYARD -----------------------------------------------------------
	-- the well in the middle
	local well = V3(4, 0, 6)
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		K.box(ctx, "WellStone", V3(1.6, 2.4, 1.2), CFrame.new(well + V3(math.cos(a) * 2.6, 1.2, math.sin(a) * 2.6)) * CFrame.Angles(0, -a + DEG(90), 0), stone(), M.Slate)
	end
	K.cyl(ctx, "WellWater", 4.4, 0.2, well + V3(0, 0.6, 0), Color3.fromRGB(20, 26, 34), M.Glass).CanCollide = false
	for _, s in ipairs({-1, 1}) do K.box(ctx, "WellPost", V3(0.5, 5.4, 0.5), CFrame.new(well + V3(s * 3, 2.7, 0)), C.DARKWOOD, M.Wood) end
	K.cyl(ctx, "WellCrank", 0.6, 6.4, CFrame.new(well + V3(0, 4.6, 0)) * CFrame.Angles(0, 0, DEG(90)), C.DARKWOOD, M.Wood)
	for _, s in ipairs({-1, 1}) do
		K.box(ctx, "WellRoof", V3(7.4, 0.3, 2.8), CFrame.new(well + V3(0, 6.1, s * 1.1)) * CFrame.Angles(DEG(s * 28), 0, 0), C.DARKWOOD, M.WoodPlanks)
	end
	K.rope(ctx, well + V3(0, 4.6, 0), well + V3(0, 2.2, 0))
	K.cyl(ctx, "Bucket", 1, 1, well + V3(0, 1.8, 0), C.WOOD, M.Wood).CanCollide = false

	-- the colonnade that once lined the north side: stumps, and one fallen
	for _, x in ipairs({-30, -24, -18, 18, 24, 30}) do
		local whole = rng:NextNumber() < 0.4
		local h = whole and 10 or rng:NextNumber(2, 7)
		K.cyl(ctx, "Pillar", 2.2, h, V3(x, h / 2, -32), stone(), M.Slate)
		K.box(ctx, "PillarBase", V3(3, 0.8, 3), V3(x, 0.4, -32), DARK, M.Slate)
		if whole then K.box(ctx, "Capital", V3(3, 0.8, 3), V3(x, h + 0.4, -32), DARK, M.Slate) end
	end
	K.cyl(ctx, "FallenPillar", 2.2, 9, CFrame.new(-21, 1.1, -27) * CFrame.Angles(0, DEG(70), DEG(90)), stone(), M.Slate)

	-- the chapel: roofless, its beams fallen in, the altar still dressed
	local CH = {x0 = -36, x1 = -24, z0 = -2, z1 = 20}
	local CHH = 11
	ruinWall(V3(CH.x0, 0, CH.z0), V3(CH.x0, 0, CH.z1), CHH, 1.6, {{9, 12}})
	ruinWall(V3(CH.x1, 0, CH.z0), V3(CH.x1, 0, CH.z1), CHH, 1.6, {{7, 12, clean = true}})   -- the door, off the courtyard
	ruinWall(V3(CH.x0, 0, CH.z1), V3(CH.x1, 0, CH.z1), CHH + 3, 1.6)
	ruinWall(V3(CH.x0, 0, CH.z0), V3(CH.x1, 0, CH.z0), CHH, 1.6, {{4, 8}})
	K.box(ctx, "ChapelFloor", V3(12, 0.3, 22), V3(-30, 0.15, 9), Color3.fromRGB(96, 92, 86), M.Slate)
	K.box(ctx, "Altar", V3(5, 2.8, 2.2), V3(-30, 1.4, 17.4), Color3.fromRGB(150, 146, 136), M.Marble)
	K.box(ctx, "AltarCloth", V3(5.2, 0.15, 2.4), V3(-30, 2.85, 17.4), Color3.fromRGB(110, 24, 30), M.Fabric).CanCollide = false
	for _, x in ipairs({-31.8, -30.6, -29.2, -28.2}) do
		local hgt = rng:NextNumber(0.6, 1.2)
		K.cyl(ctx, "Candle", 0.25, hgt, V3(x, 2.9 + hgt / 2, 17.6), Color3.fromRGB(232, 224, 200), M.SmoothPlastic).CanCollide = false
		local f = K.ball(ctx, "CandleFlame", 0.22, V3(x, 3.05 + hgt, 17.6), Color3.fromRGB(255, 200, 120), M.Neon)
		f.CanCollide = false
	end
	local glow = Instance.new("PointLight"); glow.Color = Color3.fromRGB(255, 180, 110); glow.Range = 14; glow.Brightness = 1.4
	glow.Parent = K.ball(ctx, "AltarGlow", 0.1, V3(-30, 4.2, 17), Color3.new(), M.SmoothPlastic)
	glow.Parent.Transparency, glow.Parent.CanCollide = 1, false
	for _, b in ipairs({{z = 4, tilt = 32}, {z = 11, tilt = -28}}) do
		K.box(ctx, "FallenBeam", V3(0.9, 0.9, 13.5), CFrame.new(-30, 4.6, b.z) * CFrame.Angles(DEG(b.tilt), DEG(90), 0), C.DARKWOOD, M.Wood, ctx.Props)
	end
	for z = 2, 14, 4 do                                         -- what's left of the pews
		if rng:NextNumber() < 0.75 then
			K.box(ctx, "Pew", V3(7, 0.4, 1.4), CFrame.new(-30, 1.2, z) * CFrame.Angles(0, DEG(rng:NextNumber(-6, 6)), 0), C.WOOD, M.WoodPlanks, ctx.Props)
			K.box(ctx, "PewBack", V3(7, 1.6, 0.3), CFrame.new(-30, 1.8, z + 0.7) * CFrame.Angles(0, DEG(rng:NextNumber(-6, 6)), 0), C.WOOD, M.WoodPlanks, ctx.Props)
		end
	end

	-- the gibbet: a cage on a dead oak's arm
	local gib = V3(22, 0, -16)
	K.deadTree(ctx, gib, 17)
	K.box(ctx, "GibbetArm", V3(0.6, 0.6, 7), CFrame.new(gib + V3(0, 13, -3)), Color3.fromRGB(86, 80, 74), M.Wood)
	K.rope(ctx, gib + V3(0, 12.7, -6), gib + V3(0, 9.2, -6), C.IRON)
	local cage = gib + V3(0, 7, -6)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		K.box(ctx, "CageBar", V3(0.16, 4.2, 0.16), CFrame.new(cage + V3(math.cos(a) * 1.2, 0, math.sin(a) * 1.2)), C.IRON, M.Metal, ctx.Props).CanCollide = false
	end
	for _, y in ipairs({-2.1, 2.1}) do K.cyl(ctx, "CageRing", 2.6, 0.2, cage + V3(0, y, 0), C.IRON, M.Metal, ctx.Props).CanCollide = false end
	K.ball(ctx, "Skull", 0.8, cage + V3(0.2, -1.6, 0.1), Color3.fromRGB(224, 214, 190), M.SmoothPlastic, ctx.Props).CanCollide = false

	-- the graveyard in the south-east corner
	for gx = 20, 32, 4 do
		for gz = 20, 32, 6 do
			if rng:NextNumber() < 0.85 then K.grave(ctx, CFrame.new(gx + rng:NextNumber(-0.6, 0.6), 0, gz) * CFrame.Angles(0, DEG(rng:NextNumber(-8, 8)), 0)) end
		end
	end
	K.deadTree(ctx, V3(34, 0, 18), 12)
	K.lantern(ctx, V3(18, 0, 17), 6)

	-- braziers someone keeps burning, and the odd crate and barrel
	for _, p in ipairs({V3(-10, 0, -24), V3(12, 0, -24), V3(-16, 0, 10), V3(18, 0, 6), V3(2, 0, 26), V3(30, 0, -4)}) do K.brazier(ctx, p) end
	for _, p in ipairs({V3(-12, 0, -36), V3(-15, 0, -35), V3(14, 0, -36), V3(36, 0, -30)}) do K.crate(ctx, p, rng:NextNumber(2.4, 3.2), rng:NextNumber(0, 90)) end
	for _, p in ipairs({V3(-9, 0, -37), V3(36, 0, -25), V3(-20, 0, 34)}) do K.barrel(ctx, p) end
	K.rack(ctx, CFrame.new(-26, 0, -37))
	for _, c in ipairs({{V3(-10, 0, -31), Color3.fromRGB(28, 28, 32)}, {V3(10, 0, -31), Color3.fromRGB(28, 28, 32)}}) do K.banner(ctx, c[1], 9, c[2]) end

	-- OUTSIDE ----------------------------------------------------------------
	-- dead trees and dark pines, boulders; the approaches left clear
	for _ = 1, 150 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(HALF + 14, 170)
		local p = V3(math.cos(a) * d, 0, math.sin(a) * d)
		if math.abs(p.X) > HALF + 10 or math.abs(p.Z) > HALF + 10 then
			if not nearApproach(p, d < 90 and 14 or 8) then
				if d > 95 and rng:NextNumber() < 0.7 then K.pine2(ctx, p, rng:NextNumber(22, 34), 3, 5, Color3.fromRGB(34, 52, 40))
				elseif rng:NextNumber() < 0.6 then K.deadTree(ctx, p, rng:NextNumber(10, 18))
				else K.rock(ctx, p, rng:NextNumber(3, 6), DARK) end
			end
		end
	end

	-- mist outside every opening, and the Horde in it
	local function mist(at)
		local box = K.box(ctx, "Mist", V3(26, 3, 26), at + V3(0, 1.5, 0), Color3.new(), M.SmoothPlastic, ctx.Props)
		box.Transparency, box.CanCollide, box.CanQuery, box.CanTouch = 1, false, false, false
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(150, 160, 186))
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 1)})
		e.Size = NumberSequence.new(9, 16)
		e.Lifetime, e.Rate, e.Speed = NumberRange.new(7, 11), 4, NumberRange.new(0.3, 0.9)
		e.SpreadAngle = Vector2.new(180, 10)
		e.Rotation, e.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-8, 8)
		e.Shape, e.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
		e.LightInfluence = 0.7
		e.Parent = box
	end
	for i, o in ipairs(OPENINGS) do
		local out = o.at + o.at.Unit * 13
		local at = V3(out.X, 3, out.Z)
		K.spot(ctx, "HordeGate" .. i, CFrame.lookAt(at, V3(0, 3, 0)))
		K.spawn(ctx, at, "B", V3(0, 3, 0))
		mist(V3(out.X, 0, out.Z))
	end

	-- you start round the well
	for i = 1, 8 do
		local a = DEG(i * 45 + 20)
		local p = well + V3(math.cos(a) * 10, 1, math.sin(a) * 10)
		K.spawn(ctx, p, (i % 2 == 0) and "A" or nil, well + V3(0, 1, 0))
	end
	K.camera(ctx, V3(-30, 26, 64), V3(0, 4, 0))
	K.camera(ctx, V3(0, 7, -60), V3(0, 6, -30))
	K.camera(ctx, V3(26, 8, 30), V3(-6, 4, -6))
	-- night: a high moon, blue light, warm fire inside the walls
	K.lighting(ctx, {ClockTime = 23.4, Brightness = 1.2, FogStart = 30, FogEnd = 260, FogColor = Color3.fromRGB(60, 70, 96),
		OutdoorAmbient = Color3.fromRGB(104, 114, 146), Ambient = Color3.fromRGB(70, 74, 96), ColorShift_Top = Color3.fromRGB(150, 170, 220)})
	K.atmosphere(ctx, {Density = 0.4, Offset = 0.05, Color = Color3.fromRGB(96, 110, 146), Decay = Color3.fromRGB(40, 46, 66), Glare = 0, Haze = 1.4})
	return K.finish(ctx)
end
