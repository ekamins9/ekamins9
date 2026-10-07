--[[ STORMBREAK — a palisade camp above a grey beach, a storm coming in off the
     sea. Three longships have run up on the sand below it and their crews are
     coming up the beach: in at the sea gate between the watchtowers, in at the
     two beach-side gaps in the stockade, and round to the land gate at the back
     (Spots HordeGate1..4, a dozen studs outside each). Tents, a smithy, a
     command tent and a bonfire inside; rain over everything. Built by
       require(game.ServerScriptService.Build.Maps).build("Stormbreak")
     Used by Horde. ]]

return function(K)
	require(script.Parent:WaitForChild("MapProps"))(K)
	local C, M = K.C, K.M
	local V3 = Vector3.new
	local DEG = math.rad
	local ctx = K.new("Stormbreak")
	local rng = Random.new(77)

	local R = 38                             -- the stockade: an octagon, this far to each corner
	local APO = R * math.cos(math.pi / 8)    -- …and this far to the middle of each side
	local GAP = 10                           -- the width of each way in
	local SEA = -2.5                         -- the water's surface
	local OPEN = {[45] = "SE", [90] = "Sea", [135] = "SW", [270] = "Land"}   -- sides with a way in (degrees; +Z is the sea)
	local function polar(rr, deg, y) local a = DEG(deg); return V3(math.cos(a) * rr, y or 0, math.sin(a) * rr) end

	-- the ground's height: flat where the camp is, the beach running down into
	-- the sea south of it
	local function groundY(z)
		if z < 38 then return 0 end
		if z < 72 then local t = (z - 38) / 34; return -4 * t * t * (3 - 2 * t) end
		return -4 - math.min((z - 72) / 38, 1) * 8
	end

	-- THE GROUND -------------------------------------------------------------
	K.terrain(ctx, V3(-240, -48, -220), V3(480, 96, 440), function(T)
		local Terrain = workspace.Terrain
		local region = Region3.new(V3(-240, -24, -220), V3(240, 8, 220)):ExpandToGrid(4)
		local mats, occs = Terrain:ReadVoxels(region, 4)
		local lo = region.CFrame.Position - region.Size / 2
		for ix = 1, mats.Size.X do
			local x = lo.X + (ix - 0.5) * 4
			for iz = 1, mats.Size.Z do
				local z = lo.Z + (iz - 0.5) * 4
				local n = math.noise(x / 16, 0.7, z / 16)
				local mat = M.Grass
				if z > 44 + n * 6 then mat = M.Sand
				elseif z > 34 + n * 6 then mat = n > 0 and M.Sand or M.Ground
				elseif V3(x, 0, z).Magnitude < APO - 2 and n > -0.4 then mat = M.Ground    -- trodden to mud inside the camp
				elseif n > 0.3 then mat = M.Ground end
				-- Roblox draws the surface 2 studs above where a fill ends (see MapKit)
				local top = groundY(z) - 2
				for iy = 1, mats.Size.Y do
					local y0 = lo.Y + (iy - 1) * 4
					local o = math.clamp((top - y0) / 4, 0, 1)
					if o > 0 then mats[ix][iy][iz], occs[ix][iy][iz] = mat, o end
				end
			end
		end
		Terrain:WriteVoxels(region, 4, mats, occs)
		-- the sea: water fills what the sand leaves, up to SEA (a shoreline voxel
		-- holds both, so the water meets the beach instead of stopping a voxel short)
		-- (straight onto the terrain, not through the lowered brush: water's
		-- surface stands where the fill ends)
		Terrain:FillBlock(CFrame.new(0, (SEA - 24) / 2, 136), V3(480, SEA + 24, 168), M.Water)
		-- headlands at each end of the beach, hills inland
		for _, s in ipairs({-1, 1}) do
			T:Mound(V3(s * 130, 0, 50), 30, 10, 60, M.Rock)
			T:Mound(V3(s * 96, 0, 96), 18, 6, 34, M.Rock)
		end
		for i = 1, 9 do
			local a = DEG(190 + i / 10 * 160)
			local d = rng:NextNumber(130, 175)
			T:Mound(V3(math.cos(a) * d, 0, math.sin(a) * d), rng:NextNumber(14, 30), 8, 46, M.Grass)
		end
	end)
	K.terrainColors(ctx, {Grass = Color3.fromRGB(88, 106, 72), Sand = Color3.fromRGB(162, 148, 116), Ground = Color3.fromRGB(96, 82, 64), Rock = Color3.fromRGB(96, 98, 102)})

	-- THE STOCKADE ------------------------------------------------------------
	local function onGround(p) return V3(p.X, groundY(p.Z) - 0.4, p.Z) end
	for k = 0, 7 do
		local mid = k * 45
		local a, b = onGround(polar(R, mid - 22.5)), onGround(polar(R, mid + 22.5))
		if OPEN[mid] then
			local len = (b - a).Magnitude
			local part = (len - GAP) / 2 / len
			K.palisade(ctx, a, a:Lerp(b, part), 8, 1.9)
			K.palisade(ctx, b:Lerp(a, part), b, 8, 1.9)
		else
			K.palisade(ctx, a, b, 8, 1.9)
		end
	end

	-- a watchtower: four posts, a railed platform, a pointed roof, a torch
	local function watchtower(pos)
		local y0 = pos.Y
		for _, sx in ipairs({-1, 1}) do
			for _, sz in ipairs({-1, 1}) do
				K.cyl(ctx, "TowerPost", 0.9, 14, V3(pos.X + sx * 1.9, y0 + 7, pos.Z + sz * 1.9), C.DARKWOOD, M.Wood)
			end
		end
		K.box(ctx, "Platform", V3(5.4, 0.6, 5.4), V3(pos.X, y0 + 10, pos.Z), C.WOOD, M.WoodPlanks)
		for _, side in ipairs({{V3(0, 0, 2.6), V3(5.4, 1.2, 0.3)}, {V3(0, 0, -2.6), V3(5.4, 1.2, 0.3)}, {V3(2.6, 0, 0), V3(0.3, 1.2, 5.4)}, {V3(-2.6, 0, 0), V3(0.3, 1.2, 5.4)}}) do
			K.box(ctx, "Rail", side[2], V3(pos.X, y0 + 11, pos.Z) + side[1], C.WOOD, M.Wood)
		end
		for _, s in ipairs({-1, 1}) do
			K.box(ctx, "Brace", V3(0.3, 9, 0.3), CFrame.new(pos.X, y0 + 5, pos.Z + s * 1.9) * CFrame.Angles(0, 0, DEG(24)), C.DARKWOOD, M.Wood).CanCollide = false
			K.box(ctx, "Brace", V3(0.3, 9, 0.3), CFrame.new(pos.X + s * 1.9, y0 + 5, pos.Z) * CFrame.Angles(DEG(24), 0, 0), C.DARKWOOD, M.Wood).CanCollide = false
		end
		K.cone(ctx, "TowerRoof", V3(pos.X, y0 + 14, pos.Z), 3.8, 3, Color3.fromRGB(70, 52, 36), M.WoodPlanks, nil, true, 4)
		K.torch(ctx, V3(pos.X + 2.4, y0 + 11.6, pos.Z + 2.4), 45)
	end
	-- the sea gate between two towers, the land gate with one
	local seaMid = polar(APO, 90)
	for _, s in ipairs({-1, 1}) do watchtower(onGround(seaMid + V3(s * (GAP / 2 + 3), 0, 2.6)) + V3(0, 0.4, 0)) end
	watchtower(onGround(polar(APO, 270) + V3(GAP / 2 + 3, 0, -2.6)) + V3(0, 0.4, 0))
	K.box(ctx, "GateBeam", V3(GAP + 9, 1, 1), seaMid + V3(0, 9.5, 2.6), C.DARKWOOD, M.Wood)
	K.banner(ctx, seaMid + V3(-4, 0, -3), 9, Color3.fromRGB(40, 70, 130))
	K.banner(ctx, seaMid + V3(4, 0, -3), 9, Color3.fromRGB(40, 70, 130))

	-- THE CAMP ---------------------------------------------------------------
	local canvas = {Color3.fromRGB(206, 196, 172), Color3.fromRGB(176, 160, 130), Color3.fromRGB(150, 70, 56)}
	for _, deg in ipairs({0, 340, 180, 200, 225, 315}) do
		local p = polar(22, deg)
		K.tent(ctx, CFrame.lookAt(p, V3(0, 0, 0)), 6, 8, 5, canvas[rng:NextInteger(1, #canvas)])
		K.sack(ctx, p + polar(4, deg + 70))
	end
	-- the command tent, a table of maps outside it
	local cmd = CFrame.lookAt(polar(17, 300), V3(0, 0, 0))
	K.tent(ctx, cmd, 10, 12, 7.5, Color3.fromRGB(40, 70, 130))
	K.box(ctx, "Table", V3(4, 0.3, 2.4), cmd * CFrame.new(0, 2.4, -8), C.WOOD, M.WoodPlanks)
	for _, x in ipairs({-1.7, 1.7}) do K.box(ctx, "TableLeg", V3(0.3, 2.3, 2), cmd * CFrame.new(x, 1.15, -8), C.DARKWOOD, M.Wood) end
	K.box(ctx, "Map", V3(2.4, 0.05, 1.6), cmd * CFrame.new(0.2, 2.58, -8) * CFrame.Angles(0, DEG(8), 0), Color3.fromRGB(220, 200, 150), M.SmoothPlastic).CanCollide = false
	K.lantern(ctx, (cmd * CFrame.new(3.4, 0, -7)).Position, 5)
	-- the smithy: forge, anvil, quench barrel
	local smith = CFrame.lookAt(polar(23, 160), V3(0, 0, 0))
	K.box(ctx, "Forge", V3(4, 3, 3), smith * CFrame.new(0, 1.5, 0), C.STONEDARK, M.Slate)
	local coals = K.box(ctx, "ForgeCoals", V3(3, 0.3, 2), smith * CFrame.new(0, 3.1, 0), Color3.fromRGB(255, 110, 40), M.Neon)
	coals.CanCollide = false
	local f = Instance.new("Fire"); f.Size = 3; f.Heat = 6; f.Parent = coals
	local l = Instance.new("PointLight"); l.Color = C.FIRE; l.Range = 18; l.Brightness = 1.8; l.Parent = coals
	K.box(ctx, "Chimney", V3(1.6, 5, 1.6), smith * CFrame.new(0, 5.5, 1), C.STONEDARK, M.Slate)
	K.box(ctx, "AnvilBase", V3(1, 1.6, 1), smith * CFrame.new(0, 0.8, -3.6), C.DARKWOOD, M.Wood)
	K.box(ctx, "Anvil", V3(2.2, 0.8, 1), smith * CFrame.new(0, 2, -3.6), C.IRON, M.Metal)
	K.barrel(ctx, (smith * CFrame.new(3, 0, -2)).Position)
	K.rack(ctx, smith * CFrame.new(-4.5, 0, -1) * CFrame.Angles(0, DEG(70), 0))
	-- the bonfire in the middle, crates and barrels about
	K.campfire(ctx, V3(0, 0, -4))
	for _, deg in ipairs({18, 172, 236, 332}) do
		local p = polar(rng:NextNumber(12, 16), deg)
		K.crate(ctx, p, rng:NextNumber(2.4, 3.2), rng:NextNumber(0, 90))
		if rng:NextNumber() < 0.6 then K.barrel(ctx, p + polar(3, deg + 90)) end
	end
	K.wagon(ctx, CFrame.lookAt(polar(26, 250), polar(26, 250) + polar(1, 340)), {nocover = true})
	K.rack(ctx, CFrame.lookAt(polar(28, 20), V3(0, 0, 0)))

	-- THE BEACH --------------------------------------------------------------
	-- the longships, run up on the sand, bows to the camp
	for _, sh in ipairs({{x = -40, z = 64, yaw = 14, roll = 5}, {x = 2, z = 70, yaw = -4, roll = -4}, {x = 42, z = 62, yaw = -18, roll = 6}}) do
		K.longship(ctx, CFrame.new(sh.x, groundY(sh.z) - 0.3, sh.z) * CFrame.Angles(0, DEG(sh.yaw), DEG(sh.roll)), true)
	end
	-- driftwood, rocks, a fish-drying rack, an upturned boat
	for _ = 1, 14 do
		local p = V3(rng:NextNumber(-90, 90), 0, rng:NextNumber(46, 60))
		if math.abs(p.X) > 12 then
			if rng:NextNumber() < 0.5 then
				K.cyl(ctx, "Driftwood", rng:NextNumber(0.8, 1.4), rng:NextNumber(5, 9), CFrame.new(p.X, groundY(p.Z) + 0.4, p.Z) * CFrame.Angles(0, rng:NextNumber(0, 6), DEG(90)), Color3.fromRGB(150, 136, 116), M.Wood, ctx.Props)
			else
				K.rock(ctx, V3(p.X, groundY(p.Z), p.Z), rng:NextNumber(2.5, 5), Color3.fromRGB(92, 94, 98))
			end
		end
	end
	local dry = V3(-24, groundY(48), 48)
	for _, x in ipairs({-3, 3}) do K.box(ctx, "DryPost", V3(0.4, 5, 0.4), dry + V3(x, 2.5, 0), C.DARKWOOD, M.Wood) end
	K.box(ctx, "DryBar", V3(7, 0.3, 0.3), dry + V3(0, 4.8, 0), C.DARKWOOD, M.Wood)
	for i = -2, 2 do K.box(ctx, "Fish", V3(0.5, 1.6, 0.2), dry + V3(i * 1.1, 3.8, 0), Color3.fromRGB(150, 160, 168), M.SmoothPlastic).CanCollide = false end
	local boat = CFrame.new(26, groundY(50) + 1, 50) * CFrame.Angles(0, DEG(70), DEG(180))
	K.box(ctx, "Rowboat", V3(3.4, 0.4, 9), boat * CFrame.new(0, -0.9, 0), Color3.fromRGB(96, 66, 40), M.WoodPlanks, ctx.Props)
	for _, s in ipairs({-1, 1}) do K.box(ctx, "RowboatSide", V3(0.3, 1.4, 9), boat * CFrame.new(s * 1.6, -0.2, 0) * CFrame.Angles(0, 0, DEG(-s * 18)), Color3.fromRGB(110, 76, 46), M.WoodPlanks, ctx.Props) end

	-- inland: pines and rocks behind the camp, the land gate's approach left open
	for _ = 1, 120 do
		local p = polar(rng:NextNumber(APO + 14, 170), rng:NextNumber(185, 355))
		local deg = math.deg(math.atan2(p.Z, p.X)) % 360
		if math.abs(deg - 270) > 12 and p.Z < 20 then
			if rng:NextNumber() < 0.75 then K.pine2(ctx, p, rng:NextNumber(18, 30), 3, 6) else K.rock(ctx, p, rng:NextNumber(3, 6), Color3.fromRGB(96, 98, 102)) end
		end
	end

	-- the rain
	local cloud = K.box(ctx, "Rain", V3(220, 1, 220), V3(0, 60, 10), Color3.new(), M.SmoothPlastic, ctx.Props)
	cloud.Transparency, cloud.CanCollide, cloud.CanQuery, cloud.CanTouch = 1, false, false, false
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(190, 200, 214))
	e.Transparency = NumberSequence.new(0.35)
	e.Size = NumberSequence.new(0.28)
	e.Squash = NumberSequence.new(-2.5)
	e.Orientation = Enum.ParticleOrientation.VelocityParallel
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Lifetime, e.Rate, e.Speed = NumberRange.new(0.9, 1.1), 900, NumberRange.new(62, 70)
	e.Acceleration = V3(4, 0, 2)
	e.Shape, e.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	e.LightInfluence = 1
	e.Parent = cloud

	-- where the raiders come in
	local i = 0
	for _, deg in ipairs({90, 45, 135, 270}) do
		i += 1
		local out = polar(APO + 12, deg)
		local at = V3(out.X, groundY(out.Z) + 3, out.Z)
		K.spot(ctx, "HordeGate" .. i, CFrame.lookAt(at, V3(0, 3, 0)))
		K.spawn(ctx, at, "B", V3(0, 3, 0))
	end
	-- you start round the bonfire
	for j = 1, 8 do
		local p = polar(9, j * 45 + 10, 1) + V3(0, 0, -4)
		K.spawn(ctx, p, (j % 2 == 0) and "A" or nil, V3(0, 1, -4))
	end
	K.camera(ctx, V3(30, 22, 92), V3(0, 2, 10))
	K.camera(ctx, V3(-14, 7, 18), V3(6, 4, -10))
	K.camera(ctx, V3(0, 50, -80), V3(0, 0, 20))
	-- a storm: grey light, a low heavy sky, rain driving in off the sea
	K.lighting(ctx, {ClockTime = 15.2, Brightness = 1.1, FogStart = 20, FogEnd = 320, FogColor = Color3.fromRGB(128, 136, 146),
		OutdoorAmbient = Color3.fromRGB(128, 134, 144), Ambient = Color3.fromRGB(84, 88, 96), ColorShift_Top = Color3.fromRGB(170, 180, 196)})
	K.atmosphere(ctx, {Density = 0.5, Offset = 0.12, Color = Color3.fromRGB(150, 158, 168), Decay = Color3.fromRGB(88, 96, 108), Glare = 0, Haze = 2.6})
	return K.finish(ctx)
end
