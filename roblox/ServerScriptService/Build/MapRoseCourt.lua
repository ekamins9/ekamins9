--[[ THE ROSE COURT — a walled rose garden for duels (a hortus conclusus): a
     heraldic rose laid in the marble floor, a ring of columns under a pergola
     of roses, flowerbeds and climbing roses along warm stone walls, four
     barred gates looking out on the lawns, little fountains in two corners and
     rose trees in the other two, a tower with a rose-red spire at each corner,
     the afternoon sun. Built by
       require(game.ServerScriptService.Build.Maps).build("RoseCourt")
     Used by the Lists (1v1, 2v2, 3v3) and the Duel Yard. The walls are too
     tall to get over and the gates are barred, so the court is the arena. ]]

return function(K)
	local C, M = K.C, K.M
	local V3 = Vector3.new
	local DEG = math.rad
	local ctx = K.new("RoseCourt")

	local STONE = Color3.fromRGB(222, 206, 178)    -- the walls: warm sandstone
	local STONE2 = Color3.fromRGB(196, 178, 148)   -- coping, curbs, steps
	local MARBLE = Color3.fromRGB(236, 232, 224)
	local MARBLE2 = Color3.fromRGB(206, 200, 190)
	local VEIN = Color3.fromRGB(150, 140, 132)
	local CREAM = Color3.fromRGB(228, 216, 192)
	local PEARL = Color3.fromRGB(250, 248, 242)
	local ROSE = Color3.fromRGB(190, 32, 56)
	local ROSE2 = Color3.fromRGB(232, 108, 140)
	local MAROON = Color3.fromRGB(112, 24, 40)
	local LEAF = Color3.fromRGB(62, 112, 54)
	local HEDGE = Color3.fromRGB(46, 90, 44)
	local SOIL = Color3.fromRGB(74, 52, 36)
	local GOLD = C.GOLD
	local BLOOMS = {ROSE, ROSE2, PEARL}

	local IN = 23          -- the walls' inner faces: the court is 46 x 46
	local WH = 8           -- wall height (too tall to get over)
	local RING = 15        -- the column ring
	local GATE = 4.8       -- half a gateway's width, piers included
	local r = Random.new(41)

	local function polar(rad, deg, y) local a = DEG(deg); return V3(math.cos(a) * rad, y or 0, math.sin(a) * rad) end
	local function nocollide(p) p.CanCollide = false; return p end

	K.terrain(ctx, V3(-100, -40, -100), V3(200, 80, 200), function(T)
		T:FillBlock(CFrame.new(0, -6, 0), V3(192, 12, 192), Enum.Material.Grass)
		-- paving under the whole court: grass blades grow up through thin floor parts
		T:FillBlock(CFrame.new(0, -2, 0), V3(48, 4, 48), Enum.Material.Pavement)
		-- gravel walks out of the four gates, a little square round each outer
		-- fountain (whole voxel rows, so the ground stays level)
		T:FillBlock(CFrame.new(0, -2, -36), V3(8, 4, 24), Enum.Material.Pavement)
		T:FillBlock(CFrame.new(0, -2, 36), V3(8, 4, 24), Enum.Material.Pavement)
		T:FillBlock(CFrame.new(-36, -2, 0), V3(24, 4, 8), Enum.Material.Pavement)
		T:FillBlock(CFrame.new(36, -2, 0), V3(24, 4, 8), Enum.Material.Pavement)
		T:FillBlock(CFrame.new(0, -2, -40), V3(16, 4, 16), Enum.Material.Pavement)
		T:FillBlock(CFrame.new(0, -2, 40), V3(16, 4, 16), Enum.Material.Pavement)
	end)
	K.terrainColors(ctx, {Grass = Color3.fromRGB(96, 142, 70), Pavement = Color3.fromRGB(206, 196, 178)})

	------------------------------------------------------------------
	-- the floor: pale marble slabs, the rose in the middle (each layer stands
	-- a hair above the one under it, so nothing flickers)
	------------------------------------------------------------------
	K.box(ctx, "Floor", V3(IN * 2, 0.2, IN * 2), V3(0, 0.1, 0), MARBLE2, M.Marble)
	for i = -2, 2 do
		K.box(ctx, "FloorLine", V3(IN * 2, 0.24, 0.25), V3(0, 0.12, i * 9.2), VEIN, M.Marble)
		K.box(ctx, "FloorLine", V3(0.25, 0.24, IN * 2), V3(i * 9.2, 0.12, 0), VEIN, M.Marble)
	end
	K.cyl(ctx, "RoseBorder", 27, 0.3, V3(0, 0.15, 0), MAROON, M.Marble)
	K.cyl(ctx, "RoseField", 25.4, 0.34, V3(0, 0.17, 0), CREAM, M.Marble)
	-- a heraldic rose: five red petals, five white over them, a gold heart,
	-- green barbs between the red petals
	for i = 0, 4 do
		local a = 90 + i * 72
		local h = 0.40 + i * 0.03
		local p = polar(6, a)
		K.cyl(ctx, "Petal", 7.6, h, V3(p.X, h / 2, p.Z), ROSE, M.Marble)
		local hw = 0.56 + i * 0.03
		local q = polar(3, a + 36)
		K.cyl(ctx, "WhitePetal", 4.6, hw, V3(q.X, hw / 2, q.Z), PEARL, M.Marble)
		local yaw = -DEG(a + 36) + math.pi / 2
		K.box(ctx, "Barb", V3(1, 0.38, 3.2), CFrame.new(polar(9, a + 36, 0.19)) * CFrame.Angles(0, yaw, 0), LEAF, M.Marble)
		K.box(ctx, "BarbTip", V3(1, 0.38, 1), CFrame.new(polar(10.6, a + 36, 0.19)) * CFrame.Angles(0, yaw + DEG(45), 0), LEAF, M.Marble)
	end
	K.cyl(ctx, "Heart", 2.8, 0.72, V3(0, 0.36, 0), GOLD, M.Marble)
	K.cyl(ctx, "HeartSeed", 1.2, 0.76, V3(0, 0.38, 0), Color3.fromRGB(176, 128, 36), M.Marble)

	------------------------------------------------------------------
	-- the ring of columns under a pergola of roses
	------------------------------------------------------------------
	for i = 0, 7 do
		local a = 22.5 + i * 45
		local p = polar(RING, a)
		K.cyl(ctx, "ColumnPlinth", 2.8, 0.8, p + V3(0, 0.4, 0), MARBLE2, M.Marble)
		K.cyl(ctx, "Column", 1.7, 9, p + V3(0, 5.3, 0), MARBLE, M.Marble)
		K.box(ctx, "Capital", V3(2.6, 0.8, 2.6), CFrame.new(p + V3(0, 10.2, 0)) * CFrame.Angles(0, -DEG(a), 0), MARBLE2, M.Marble)
		local q = polar(RING, a + 45)
		local beam = K.box(ctx, "Beam", V3(1.2, 1, (q - p).Magnitude), CFrame.lookAt((p + q) / 2 + V3(0, 11, 0), q + V3(0, 11, 0)), MARBLE, M.Marble)
		for k = -2, 2 do
			local side = (k % 2 == 0) and 0.45 or -0.45
			nocollide(K.ball(ctx, "RoseLeaves", 1.3, beam.CFrame * CFrame.new(side, 0.55, k * 2.2 + 0.5), LEAF, M.Grass))
			nocollide(K.ball(ctx, "Rose", 0.8, beam.CFrame * CFrame.new(side, 0.75, k * 2.2), BLOOMS[(i + k) % 3 + 1], M.SmoothPlastic))
			-- a spray hanging under the beam
			if k ~= 0 then nocollide(K.ball(ctx, "RoseLeaves", 1, beam.CFrame * CFrame.new(-side, -0.75, k * 2.2 - 0.6), HEDGE, M.Grass)) end
		end
		-- a climbing rose up the column
		for k = 1, 4 do
			local v = nocollide(K.ball(ctx, "Vine", 1, CFrame.new(p + V3(math.cos(k * 1.7) * 0.9, 1.6 + k * 2, math.sin(k * 1.7) * 0.9)), LEAF, M.Grass))
			if k % 2 == 0 then nocollide(K.ball(ctx, "Rose", 0.6, v.CFrame * CFrame.new(0.3, 0.3, 0), BLOOMS[(i + k) % 3 + 1], M.SmoothPlastic)) end
		end
	end

	------------------------------------------------------------------
	-- the walls and the four gates. Each gate's frame stands in the middle of
	-- its gateway, X along the wall, +Z into the court.
	------------------------------------------------------------------
	local SIDES = {
		{frame = CFrame.new(0, 0, -IN - 1), yaw = 0, reach = IN + 2},
		{frame = CFrame.new(0, 0, IN + 1) * CFrame.Angles(0, math.pi, 0), yaw = 180, reach = IN + 2},
		{frame = CFrame.new(-IN - 1, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), yaw = 90, reach = IN},
		{frame = CFrame.new(IN + 1, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), yaw = -90, reach = IN},
	}
	for si, side in ipairs(SIDES) do
		local g = side.frame
		-- two runs of wall either side of the gate: a base course, the wall, a coping
		for _, s in ipairs({-1, 1}) do
			local len = side.reach - GATE
			local x = s * (GATE + side.reach) / 2
			K.box(ctx, "Wall", V3(len, WH, 2), g * CFrame.new(x, WH / 2, 0), STONE, M.Sandstone)
			K.box(ctx, "BaseCourse", V3(len, 0.8, 2.5), g * CFrame.new(x, 0.4, 0), STONE2, M.Sandstone)
			K.box(ctx, "Coping", V3(len, 0.5, 2.6), g * CFrame.new(x, WH + 0.25, 0), STONE2, M.Sandstone)
		end
		-- the gateway: an arch, a cap with gold finials, a rose medallion over the court side
		local top = K.arch(ctx, g, 6, 7, 2.6, STONE, M.Sandstone)
		K.box(ctx, "GateCap", V3(13, 0.5, 3.4), g * CFrame.new(0, top + 0.25, 0), STONE2, M.Sandstone)
		for _, s in ipairs({-1, 1}) do K.ball(ctx, "Finial", 1.1, g * CFrame.new(s * 6, top + 1.05, 0), GOLD, M.Metal) end
		K.cyl(ctx, "Medallion", 2.2, 0.3, g * CFrame.new(0, top - 0.7, 1.6) * CFrame.Angles(math.pi / 2, 0, 0), MAROON, M.Marble)
		K.ball(ctx, "MedallionRose", 1, g * CFrame.new(0, top - 0.7, 1.8), ROSE, M.SmoothPlastic)
		-- the grille that bars it: bars up to the curve of the arch, two rails
		for k = 0, 9 do
			local x = -2.7 + k * 0.6
			local h = 4 + math.sqrt(9 - x * x) - 0.05
			K.box(ctx, "GrilleBar", V3(0.22, h, 0.22), g * CFrame.new(x, h / 2, 0), C.IRON, M.Metal)
		end
		for _, y in ipairs({1, 3.4}) do K.box(ctx, "GrilleRail", V3(6, 0.25, 0.32), g * CFrame.new(0, y, 0), C.IRON, M.Metal) end

		-- the flowerbeds along the wall: a curb, soil, rose bushes in bloom
		for _, s in ipairs({-1, 1}) do
			local x = s * (GATE + 0.6 + 20.6) / 2
			local len = 20.6 - GATE - 0.6
			K.box(ctx, "BedCurb", V3(len, 0.7, 0.5), g * CFrame.new(x, 0.35, 3.15), STONE2, M.Sandstone)
			K.box(ctx, "BedSoil", V3(len, 0.5, 1.9), g * CFrame.new(x, 0.25, 1.95), SOIL, M.Ground)
			for k = 0, 6 do
				local bx = s * (6.5 + k * 2.2)
				local bush = K.ball(ctx, "RoseBush", 1.9, g * CFrame.new(bx, 1.15, 2), (k % 2 == 0) and LEAF or HEDGE, M.Grass)
				local bloom = BLOOMS[(si + k) % 3 + 1]
				nocollide(K.ball(ctx, "Rose", 0.55, bush.CFrame * CFrame.new(0.45, 0.75, 0.35), bloom, M.SmoothPlastic))
				nocollide(K.ball(ctx, "Rose", 0.55, bush.CFrame * CFrame.new(-0.4, 0.8, -0.2), bloom, M.SmoothPlastic))
			end
			-- climbing roses up the wall over the bed (clusters of leaves zig-zagging
			-- up, blooms among them), a lantern between them
			for _, cx in ipairs({8.3, 16.7}) do
				local px = s * cx
				for n = 1, 6 do
					local y = 0.9 + n * 0.95
					local leaf = nocollide(K.ball(ctx, "Climber", r:NextNumber(1.2, 1.7) * (1.15 - n * 0.06),
						g * CFrame.new(px + ((n % 2 == 0) and 0.55 or -0.55) + r:NextNumber(-0.3, 0.3), y, 1.25), (n % 2 == 0) and LEAF or HEDGE, M.Grass))
					if n % 2 == 1 then
						nocollide(K.ball(ctx, "Rose", 0.6, leaf.CFrame * CFrame.new(0.25, 0.3, 0.45), BLOOMS[(n + si) % 3 + 1], M.SmoothPlastic))
					end
				end
			end
			K.torch(ctx, (g * CFrame.new(s * 12.5, 5.2, 1.4)).Position, side.yaw)
		end
	end
	-- a tower with a rose-red spire at each corner
	for _, sx in ipairs({-1, 1}) do
		for _, sz in ipairs({-1, 1}) do
			K.tower(ctx, V3(sx * (IN + 1), 0, sz * (IN + 1)), 2.6, 11, {roof = true, roofColor = MAROON, roofH = 6,
				color = STONE, topColor = STONE2, material = M.Sandstone})
		end
	end

	------------------------------------------------------------------
	-- the corners: little fountains (NW, SE) and rose trees (NE, SW); benches
	------------------------------------------------------------------
	local function spray(pos, speed)
		local jet = nocollide(K.box(ctx, "FountainJet", V3(0.4, 0.4, 0.4), pos, C.WATER, M.Glass))
		jet.Transparency = 1
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
		e.Size = NumberSequence.new(0.25, 0.08)
		e.Transparency = NumberSequence.new(0.2, 1)
		e.Lifetime = NumberRange.new(0.6, 0.9)
		e.Speed = NumberRange.new(speed, speed * 1.5)
		e.SpreadAngle = Vector2.new(14, 14)
		e.Acceleration = V3(0, -22, 0)
		e.Rate = 22
		e.LightEmission = 0.4
		e.Parent = jet
	end
	local function water(name, d, top, pos)
		local w = nocollide(K.cyl(ctx, name, d, 0.12, pos + V3(0, top - 0.06, 0), C.WATER, M.Glass))
		w.Transparency = 0.2
		return w
	end
	local function smallFountain(c)
		K.cyl(ctx, "FountainStep", 5.6, 0.4, c + V3(0, 0.2, 0), STONE2, M.Sandstone)
		K.cyl(ctx, "FountainBasin", 4.6, 1.3, c + V3(0, 1.05, 0), MARBLE, M.Marble)
		water("FountainWater", 4, 1.82, c)
		K.cyl(ctx, "FountainStem", 0.7, 2.6, c + V3(0, 3, 0), MARBLE, M.Marble)
		K.cyl(ctx, "FountainCup", 1.9, 0.4, c + V3(0, 4.5, 0), MARBLE, M.Marble)
		water("FountainCupWater", 1.6, 4.8, c)
		K.ball(ctx, "FountainKnob", 0.6, c + V3(0, 5, 0), GOLD, M.Metal)
		for k = 0, 3 do
			local a = k * math.pi / 2 + math.pi / 4
			local sheet = nocollide(K.box(ctx, "Fall", V3(0.8, 2.9, 0.08), CFrame.new(c + V3(math.cos(a) * 0.95, 3.25, math.sin(a) * 0.95)) * CFrame.Angles(0, -a + math.pi / 2, 0), C.WATER, M.Glass))
			sheet.Transparency = 0.5
		end
		spray(c + V3(0, 5.3, 0), 4)
	end
	local function roseTree(c)
		K.cyl(ctx, "Planter", 3.6, 1.3, c + V3(0, 0.65, 0), STONE2, M.Sandstone)
		K.cyl(ctx, "PlanterSoil", 3, 0.08, c + V3(0, 1.34, 0), SOIL, M.Ground)
		K.cyl(ctx, "RoseTrunk", 0.45, 3.4, c + V3(0, 3, 0), C.DARKWOOD, M.Wood)
		local crown = nocollide(K.ball(ctx, "RoseCrown", 3.4, c + V3(0, 5.6, 0), LEAF, M.Grass))
		nocollide(K.ball(ctx, "RoseCrown", 2.4, c + V3(0.9, 6.3, 0.5), HEDGE, M.Grass))
		nocollide(K.ball(ctx, "RoseCrown", 2.2, c + V3(-0.8, 6.1, -0.6), HEDGE, M.Grass))
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			local up = (k % 2 == 0) and 0.5 or -0.1
			local dir = V3(math.cos(a), up, math.sin(a)).Unit
			nocollide(K.ball(ctx, "Rose", 0.6, crown.Position + dir * 1.7 + V3(0, 0.3, 0), BLOOMS[k % 3 + 1], M.SmoothPlastic))
		end
	end
	smallFountain(V3(-18, 0, -18))
	smallFountain(V3(18, 0, 18))
	roseTree(V3(18, 0, -18))
	roseTree(V3(-18, 0, 18))
	-- marble benches by the north and south beds, backs to the wall
	for si = 1, 2 do
		local g = SIDES[si].frame
		for _, x in ipairs({-10.5, 10.5}) do
			K.box(ctx, "BenchSeat", V3(5, 0.4, 1.6), g * CFrame.new(x, 1.3, 4.4), MARBLE, M.Marble)
			K.box(ctx, "BenchBack", V3(5, 1.4, 0.3), g * CFrame.new(x, 2.2, 3.7), MARBLE, M.Marble)
			for _, dx in ipairs({-1.9, 1.9}) do K.box(ctx, "BenchLeg", V3(0.5, 1.1, 1.4), g * CFrame.new(x + dx, 0.55, 4.4), MARBLE2, M.Marble) end
		end
	end

	------------------------------------------------------------------
	-- outside: fountains beyond the north and south gates, cypresses along
	-- the walks, trees on the lawns all round
	------------------------------------------------------------------
	local function bigFountain(c)
		K.cyl(ctx, "FountainStep", 10, 0.4, c + V3(0, 0.2, 0), STONE2, M.Sandstone)
		K.cyl(ctx, "FountainBasin", 8.4, 1.4, c + V3(0, 1.1, 0), MARBLE, M.Marble)
		water("FountainWater", 7.6, 1.92, c)
		K.cyl(ctx, "FountainStem", 1.2, 3, c + V3(0, 3.3, 0), MARBLE, M.Marble)
		K.cyl(ctx, "FountainBowl", 3.6, 0.5, c + V3(0, 5.05, 0), MARBLE, M.Marble)
		water("FountainBowlWater", 3.2, 5.4, c)
		K.cyl(ctx, "FountainUpper", 0.6, 1.4, c + V3(0, 6, 0), MARBLE, M.Marble)
		K.cyl(ctx, "FountainCup", 1.4, 0.3, c + V3(0, 6.85, 0), MARBLE, M.Marble)
		K.ball(ctx, "FountainKnob", 0.7, c + V3(0, 7.25, 0), GOLD, M.Metal)
		spray(c + V3(0, 7.6, 0), 5)
	end
	bigFountain(V3(0, 0, -40))
	bigFountain(V3(0, 0, 40))
	-- a cypress: a tall green column with a rounded top (a ball part can't be
	-- stretched, so the body is a cylinder)
	local function cypress(pos)
		K.cyl(ctx, "CypressTrunk", 0.6, 1.6, pos + V3(0, 0.8, 0), C.DARKWOOD, M.Wood, ctx.Props)
		K.cyl(ctx, "Cypress", 2.6, 6.4, pos + V3(0, 4.6, 0), HEDGE, M.Grass, ctx.Props)
		nocollide(K.ball(ctx, "CypressTop", 2.6, pos + V3(0, 7.8, 0), HEDGE, M.Grass, ctx.Props))
		nocollide(K.ball(ctx, "CypressTip", 1.6, pos + V3(0, 9.3, 0), LEAF, M.Grass, ctx.Props))
		nocollide(K.cyl(ctx, "CypressFoot", 2.9, 0.6, pos + V3(0, 1.7, 0), HEDGE, M.Grass, ctx.Props))
	end
	for si, side in ipairs(SIDES) do
		local far = (si <= 2) and {5} or {5, 12, 19}
		for _, d in ipairs(far) do
			for _, s in ipairs({-1, 1}) do cypress((side.frame * CFrame.new(s * 6, 0, -d)).Position) end
		end
	end
	for _, sx in ipairs({-1, 1}) do
		-- a stone bench at the end of the east and west walks, facing the court
		local f = CFrame.lookAt(V3(sx * 46, 0, 0), V3(0, 0, 0))
		K.box(ctx, "BenchSeat", V3(6, 0.5, 1.8), f * CFrame.new(0, 1.3, 0), STONE2, M.Sandstone)
		for _, dx in ipairs({-2.4, 2.4}) do K.box(ctx, "BenchLeg", V3(0.6, 1.05, 1.6), f * CFrame.new(dx, 0.525, 0), STONE2, M.Sandstone) end
	end
	local placed = 0
	for _ = 1, 400 do
		if placed >= 46 then break end
		local a = r:NextNumber(0, math.pi * 2)
		local d = r:NextNumber(34, 74)
		local p = V3(math.cos(a) * d, 0, math.sin(a) * d)
		-- keep the walks and the fountain squares clear
		local onWalk = (math.abs(p.X) < 10 and math.abs(p.Z) < 54) or (math.abs(p.Z) < 10 and math.abs(p.X) < 54)
		if not onWalk then
			placed += 1
			local h = r:NextNumber(6, 9)
			K.cyl(ctx, "Trunk", 1.3, h, p + V3(0, h / 2, 0), C.DARKWOOD, M.Wood, ctx.Props)
			for k = 0, 2 do
				nocollide(K.ball(ctx, "Crown", r:NextNumber(5.5, 8), p + V3(r:NextNumber(-1.8, 1.8), h + 1 + k * 1.3, r:NextNumber(-1.8, 1.8)),
					(k % 2 == 0) and LEAF or HEDGE, M.Grass, ctx.Props))
			end
		end
	end

	------------------------------------------------------------------
	-- spawns, cameras, the afternoon light
	------------------------------------------------------------------
	for _, z in ipairs({-4, 0, 4}) do
		K.spawn(ctx, V3(-11, 1, z), "A", V3(0, 1, z))
		K.spawn(ctx, V3(11, 1, z), "B", V3(0, 1, z))
	end
	for i = 0, 7 do
		K.spawn(ctx, polar(10.5, i * 45, 1), nil, V3(0, 1, 0))
		K.spawn(ctx, polar(19, 22.5 + i * 45, 1), nil, V3(0, 1, 0))
	end
	K.camera(ctx, V3(-40, 26, 38), V3(0, 2, 0))
	K.camera(ctx, V3(-10, 4.5, 9), V3(10, 2, -6))
	K.camera(ctx, V3(0, 48, 8), V3(0, 0, 0))
	K.lighting(ctx, {ClockTime = 16.4, FogStart = 80, FogEnd = 600, FogColor = Color3.fromRGB(250, 222, 190), Brightness = 2.4,
		OutdoorAmbient = Color3.fromRGB(165, 140, 128), Ambient = Color3.fromRGB(96, 82, 76), ColorShift_Top = Color3.fromRGB(255, 205, 160)})
	return K.finish(ctx)
end
