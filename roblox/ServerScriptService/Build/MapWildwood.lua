--[[ THE WILDWOOD — a clearing in a dark pine forest at dusk, a dirt road
     running through it, and a merchant caravan that didn't make it: one wagon
     on its side with its canvas torn, another sagging on a broken wheel, cargo
     spilled across the road, arrows in the boards, the campfire still burning.
     Fireflies over the grass, fog in the trees. The Horde comes out of the
     forest down six trails (Spots HordeGate1..6, a few studs inside the trees);
     you hold the wagons. Built by
       require(game.ServerScriptService.Build.Maps).build("Wildwood")
     Used by Horde. ]]

return function(K)
	require(script.Parent:WaitForChild("MapProps"))(K)
	local C, M = K.C, K.M
	local V3 = Vector3.new
	local DEG = math.rad
	local ctx = K.new("Wildwood")
	local rng = Random.new(31)

	local CLEAR = 38                       -- the clearing's radius
	local TRAILS = {20, 80, 140, 200, 260, 320}   -- degrees round the clearing where the trails come in
	local function polar(rr, deg, y) local a = DEG(deg); return V3(math.cos(a) * rr, y or 0, math.sin(a) * rr) end
	local function onTrail(p, half)
		local deg = math.deg(math.atan2(p.Z, p.X)) % 360
		for _, t in ipairs(TRAILS) do
			if math.abs(((deg - t + 180) % 360) - 180) < (half or 9) then return true end
		end
		return false
	end
	local function onRoad(p) return math.abs(p.Z) < 9 end

	-- the ground: forest floor everywhere, grass in the clearing, a dirt road east-west
	K.terrain(ctx, V3(-232, -48, -232), V3(464, 96, 464), function(T)
		T:FillBlock(CFrame.new(0, -8, 0), V3(464, 16, 464), Enum.Material.LeafyGrass)
		-- what each patch of ground is made of, written onto the voxels themselves
		-- (a fill only changes a voxel's material where it adds to it, so a road
		-- painted over a full surface row would stay grass)
		local Terrain = workspace.Terrain
		local region = Region3.new(V3(-232, -20, -232), V3(232, 4, 232)):ExpandToGrid(4)
		local mats, occs = Terrain:ReadVoxels(region, 4)
		local lo = region.CFrame.Position - region.Size / 2
		for ix = 1, mats.Size.X do
			local x = lo.X + (ix - 0.5) * 4
			for iz = 1, mats.Size.Z do
				local z = lo.Z + (iz - 0.5) * 4
				local p = V3(x, 0, z)
				local mat = Enum.Material.LeafyGrass
				if math.abs(z) < 8 then mat = (math.abs(z) < 4 and math.noise(x / 14, 0.5, z / 6) > -0.15) and Enum.Material.Mud or Enum.Material.Ground   -- churned ruts down the middle
				elseif p.Magnitude < CLEAR + 5 then mat = Enum.Material.Grass
				elseif p.Magnitude < CLEAR + 70 and onTrail(p, 4) then mat = Enum.Material.Ground end
				for iy = 1, mats.Size.Y do
					if mats[ix][iy][iz] ~= Enum.Material.Air then mats[ix][iy][iz] = mat end
				end
			end
		end
		Terrain:WriteVoxels(region, 4, mats, occs)
		-- the land rolls away into hills beyond the trees
		for i = 1, 14 do
			local a = i / 14 * 360
			T:Mound(polar(rng:NextNumber(150, 200), a), rng:NextNumber(10, 26), 8, 48, Enum.Material.LeafyGrass)
		end
	end)
	K.terrainColors(ctx, {Grass = Color3.fromRGB(96, 120, 60), LeafyGrass = Color3.fromRGB(72, 90, 50), Ground = Color3.fromRGB(116, 92, 66), Mud = Color3.fromRGB(80, 63, 46)})

	-- THE CARAVAN ------------------------------------------------------------
	-- the lead wagon, over on its side across the road, its canvas half gone
	local over = CFrame.new(-6, 0, -1) * CFrame.Angles(0, DEG(70), 0)
	K.wagon(ctx, over * CFrame.new(0, 3.45, 0) * CFrame.Angles(0, 0, DEG(90)), {torn = 0.55, missing = {2}, noTongue = true})
	K.wheel(ctx, over * CFrame.new(-7.5, 0.2, 5) * CFrame.Angles(0, 0, DEG(90)) * CFrame.Angles(0, DEG(20), 0))   -- the lost wheel, flat in the grass
	-- the second, sagging on a broken wheel, propped on a crate
	local sag = CFrame.new(10, 0, 6) * CFrame.Angles(0, DEG(-12), 0)
	K.wagon(ctx, sag * CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, DEG(-7)), {torn = 0.25, missing = {3}})
	K.crate(ctx, (sag * CFrame.new(-3.4, 0, 3.6)).Position, 2.6, 15)
	K.box(ctx, "BrokenWheel", V3(0.38, 3.0, 1.6), sag * CFrame.new(-4.4, 0.6, 3.6) * CFrame.Angles(DEG(80), 0, DEG(15)), C.DARKWOOD, M.WoodPlanks, ctx.Props)
	-- a third wagon at the back, uncovered, its load roped down
	local back = CFrame.new(-2, 0, 16) * CFrame.Angles(0, DEG(95), 0)
	K.wagon(ctx, back, {nocover = true})
	for i = -1, 1 do K.crate(ctx, (back * CFrame.new(0, 2.65, i * 3.2)).Position, 2.4, i * 12) end
	K.rope(ctx, (back * CFrame.new(-2.8, 4.9, -4.8)).Position, (back * CFrame.new(2.8, 4.9, 4.8)).Position)
	-- the cargo, spilled across the road
	for _, p in ipairs({V3(2, 0, -6), V3(-14, 0, 6), V3(4, 0, 12), V3(-16, 0, -8)}) do K.crate(ctx, p, rng:NextNumber(2.2, 3.2), rng:NextNumber(0, 90)) end
	for _, p in ipairs({V3(-1, 0, -9), V3(16, 0, -4), V3(-12, 0, 12)}) do K.barrel(ctx, p) end
	for _, p in ipairs({V3(6, 0, -11), V3(-9, 0, -13)}) do
		local b = K.cyl(ctx, "Barrel", 2.2, 3, CFrame.new(p + V3(0, 1.1, 0)) * CFrame.Angles(DEG(90), DEG(rng:NextNumber(0, 180)), 0), C.WOOD, M.Wood, ctx.Props)
		b.Name = "SpiltBarrel"
	end
	for _, p in ipairs({V3(-4, 0, -12), V3(-3, 0, -13.5), V3(13, 0, 13), V3(8, 0, -2)}) do K.sack(ctx, p) end
	-- a strongbox burst open, its coins in the mud
	local chest = CFrame.new(0, 0, 5) * CFrame.Angles(0, DEG(30), 0)
	K.box(ctx, "Chest", V3(3, 1.6, 2), chest * CFrame.new(0, 0.8, 0), Color3.fromRGB(110, 70, 40), M.WoodPlanks, ctx.Props)
	K.box(ctx, "ChestLid", V3(3, 0.4, 2), chest * CFrame.new(0, 1.9, 1.3) * CFrame.Angles(DEG(-70), 0, 0), Color3.fromRGB(110, 70, 40), M.WoodPlanks, ctx.Props)
	for i = 1, 14 do
		K.cyl(ctx, "Coin", 0.55, 0.1, CFrame.new(V3(rng:NextNumber(-3, 3), 0.06, 5 + rng:NextNumber(-2, 3))) * CFrame.Angles(DEG(rng:NextNumber(-8, 8)), 0, 0), C.GOLD, M.Metal, ctx.Props).CanCollide = false
	end
	-- the ambush: arrows in the wagons and the ground
	for _ = 1, 16 do
		local at = V3(rng:NextNumber(-14, 16), rng:NextNumber(0.3, 4), rng:NextNumber(-12, 18))
		K.arrow(ctx, at, V3(rng:NextNumber(-1, 1), rng:NextNumber(0.2, 0.8), rng:NextNumber(-1, 1)).Unit)
	end
	-- the camp they made: a fire, logs to sit on, a lantern or two
	K.campfire(ctx, V3(12, 0, -14))
	for _, a in ipairs({20, 140, 260}) do
		K.cyl(ctx, "SeatLog", 1.6, 5, CFrame.new(V3(12, 0.8, -14) + polar(4.6, a)) * CFrame.Angles(0, DEG(-a), DEG(90)), C.DARKWOOD, M.Wood, ctx.Props)
	end
	for _, p in ipairs({V3(-20, 0, -4), V3(22, 0, 8), V3(0, 0, -22), V3(-6, 0, 24)}) do K.lantern(ctx, p, 7) end
	-- fireflies over the clearing
	local motes = K.box(ctx, "Fireflies", V3(CLEAR * 1.6, 7, CLEAR * 1.6), V3(0, 4.5, 0), Color3.new(), M.SmoothPlastic, ctx.Props)
	motes.Transparency, motes.CanCollide, motes.CanQuery, motes.CanTouch = 1, false, false, false
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(220, 255, 140))
	e.LightEmission, e.LightInfluence = 1, 0
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.22), NumberSequenceKeypoint.new(0.8, 0.22), NumberSequenceKeypoint.new(1, 0)})
	e.Lifetime, e.Rate, e.Speed = NumberRange.new(4, 8), 14, NumberRange.new(0.2, 0.6)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Shape, e.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	e.Parent = motes

	-- THE FOREST ------------------------------------------------------------
	-- a ring of trees from the clearing's edge out into the fog, trails left open
	for _ = 1, 210 do
		local d = CLEAR + 4 + (rng:NextNumber() ^ 0.8) * 120
		local p = polar(d, rng:NextNumber(0, 360))
		if not onTrail(p, d < 80 and 10 or 6) and not onRoad(p) then
			local kind = rng:NextNumber()
			local h = rng:NextNumber(16, 30)
			if d > 110 then K.pine2(ctx, p, h + 6, 2, 5)            -- the far trees: lighter
			elseif kind < 0.72 then K.pine2(ctx, p, h, 3, 6)
			elseif kind < 0.92 then K.oak(ctx, p, h * 0.65)
			else K.deadTree(ctx, p, h * 0.6) end
		end
	end
	-- the undergrowth at the treeline: bushes, ferns, rocks, fallen logs
	for _ = 1, 40 do
		local p = polar(CLEAR + rng:NextNumber(-2, 12), rng:NextNumber(0, 360))
		if not onTrail(p, 11) and not onRoad(p) then
			if rng:NextNumber() < 0.6 then K.bush(ctx, p, rng:NextNumber(2.2, 4)) else K.rock(ctx, p, rng:NextNumber(2.5, 5), Color3.fromRGB(104, 106, 100)) end
		end
	end
	for _ = 1, 8 do
		local p = polar(CLEAR + rng:NextNumber(6, 30), rng:NextNumber(0, 360))
		if not onTrail(p, 12) and not onRoad(p) then
			K.cyl(ctx, "FallenLog", 2, rng:NextNumber(8, 14), CFrame.new(p + V3(0, 1, 0)) * CFrame.Angles(0, DEG(rng:NextNumber(0, 180)), DEG(90)), Color3.fromRGB(78, 62, 44), M.Wood, ctx.Props)
		end
	end
	-- where the horde comes out: a few studs into each trail, facing the wagons
	for i, t in ipairs(TRAILS) do
		local at = polar(CLEAR + 12, t, 3)
		K.spot(ctx, "HordeGate" .. i, CFrame.lookAt(at, V3(0, 3, 0)))
		K.spawn(ctx, at, "B", V3(0, 3, 0))
	end
	-- the road runs on out east and west, a gap in the trees
	K.spot(ctx, "HordeGate7", CFrame.lookAt(V3(CLEAR + 14, 3, 0), V3(0, 3, 0)))
	K.spot(ctx, "HordeGate8", CFrame.lookAt(V3(-CLEAR - 14, 3, 0), V3(0, 3, 0)))

	-- you start round the wagons
	for i = 1, 8 do
		local p = polar(13, i * 45 + 10)
		K.spawn(ctx, p + V3(0, 1, 0), (i % 2 == 0) and "A" or nil, V3(0, 1, 0))
	end
	K.camera(ctx, V3(-34, 16, -30), V3(2, 2, 4))
	K.camera(ctx, V3(26, 6, -26), V3(4, 3, 4))
	K.camera(ctx, V3(0, 46, 60), V3(0, 0, 0))
	-- dusk: the sun low and orange through the trees, a warm haze in the forest
	K.lighting(ctx, {ClockTime = 17.85, Brightness = 2, FogStart = 26, FogEnd = 230, FogColor = Color3.fromRGB(128, 112, 98),
		OutdoorAmbient = Color3.fromRGB(140, 122, 120), Ambient = Color3.fromRGB(80, 74, 80), ColorShift_Top = Color3.fromRGB(255, 150, 90)})
	-- warm dusk haze that closes in among the trees, so the Horde comes out of murk
	K.atmosphere(ctx, {Density = 0.45, Offset = 0.1, Color = Color3.fromRGB(214, 150, 112), Decay = Color3.fromRGB(92, 70, 72), Glare = 0.6, Haze = 2.2})
	return K.finish(ctx)
end
