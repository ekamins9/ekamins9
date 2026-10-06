--[[ THE COURTYARD — the hub: a castle courtyard to meet in (peaceful). Built by
     Build ▸ Maps:   require(game.ServerScriptService.Build.Maps).build("Courtyard")

     North: the keep, and before it the Hall of Champions (a terrace, three
     podium plinths whose statues are the best players, two leaderboards).
     Middle: the wishing fountain, benches round it. South: the Gates of War
     (Training Yard · Warfront · The Lists) by the gatehouse. West: the
     Hatchery's place; south-west, the Merchant's Stall. East: the stone
     circle (the shrine); south-east, the tavern. The Notice Board stands
     between the fountain and the gates, where you arrive.
     Spots (Map ▸ Spots) for Hub ▸ Courtyard and Hub ▸ Pastimes: HatcherySpot,
     ShrineSpot, Statue1..3, Plaque1..3, BoardKills, BoardRanked, NoticeBoard,
     WellSpot, StallMannequin1..2, StallRack, GateTraining, GateWarfront,
     GateLists, BardSpot. ]]

return function(K)
	local C, M = K.C, K.M
	local V3 = Vector3.new
	local ctx = K.new("Courtyard")
	local COBBLE = Color3.fromRGB(150, 140, 128)
	local MARBLE = Color3.fromRGB(226, 222, 212)

	K.terrain(ctx, V3(-192, -64, -200), V3(384, 124, 360), function(T)
		T:FillBlock(CFrame.new(0, -6, 0), V3(300, 12, 300), Enum.Material.Grass)
		T:FillBlock(CFrame.new(0, -2, 0), V3(228, 4, 196), Enum.Material.Cobblestone)
		-- the road out of the gate
		T:FillBlock(CFrame.new(0, -2, 120), V3(20, 4, 60), Enum.Material.Cobblestone)
		for i = -3, 3 do T:FillBall(V3(i * 46, -18, -150), 44, Enum.Material.Grass) end
	end)
	K.terrainColors(ctx, {Cobblestone = COBBLE, Grass = Color3.fromRGB(96, 146, 66)})

	----------------------------------------------------------------
	-- the walls, the corner towers, the gatehouse, the keep
	----------------------------------------------------------------
	local W, Z = 108, 90
	local WALL = {crenels = true, base = true, baseH = 2.8, baseW = 2.4}
	K.wall(ctx, V3(-W, 0, -Z), V3(W, 0, -Z), 20, 5, WALL)
	K.wall(ctx, V3(-W, 0, -Z), V3(-W, 0, Z), 20, 5, WALL)
	K.wall(ctx, V3(W, 0, -Z), V3(W, 0, Z), 20, 5, WALL)
	K.wall(ctx, V3(-W, 0, Z), V3(-16, 0, Z), 20, 5, WALL)
	K.wall(ctx, V3(16, 0, Z), V3(W, 0, Z), 20, 5, WALL)
	for _, x in ipairs({-W, W}) do
		for _, z in ipairs({-Z, Z}) do K.tower(ctx, V3(x, 0, z), 10, 30, {roof = true, roofColor = C.BLUE, windows = true, base = 3.4}) end
	end
	-- the gatehouse: two towers and a closed portcullis
	for _, x in ipairs({-16, 16}) do K.tower(ctx, V3(x, 0, Z), 7, 27, {roof = true, roofColor = C.RED, windows = true, base = 3.4}) end
	K.box(ctx, "GateArchTop", V3(26, 6, 6), V3(0, 21, Z), C.STONE, M.Slate)
	for i = -4, 4 do K.box(ctx, "Portcullis", V3(0.4, 18, 0.4), V3(i * 2.2, 9, Z - 1), C.IRON, M.Metal) end
	for j = 1, 6 do K.box(ctx, "PortcullisBar", V3(18, 0.4, 0.4), V3(0, j * 2.8, Z - 1), C.IRON, M.Metal) end
	-- the keep behind the north wall
	K.box(ctx, "Keep", V3(80, 44, 26), V3(0, 22, -Z - 18), C.STONE, M.Slate)
	K.box(ctx, "KeepFooting", V3(83, 3.4, 29), V3(0, 1.7, -Z - 18), C.STONEDARK, M.Slate)
	K.box(ctx, "KeepTop", V3(84, 1.4, 30), V3(0, 44.7, -Z - 18), C.STONEDARK, M.Slate)
	for i = -9, 9 do K.box(ctx, "KeepCrenel", V3(2, 2.2, 2), V3(i * 4.4, 46.5, -Z - 3.4), C.STONE, M.Slate) end
	for i = -3, 3 do
		K.box(ctx, "KeepWindow", V3(2.4, 6, 0.6), V3(i * 10, 30, -Z - 4.8), Color3.fromRGB(26, 30, 44), M.SmoothPlastic)
		K.box(ctx, "KeepWindowArch", V3(3.2, 0.8, 0.8), V3(i * 10, 33.4, -Z - 4.6), C.STONEDARK, M.Slate)
	end
	for _, x in ipairs({-44, 44}) do K.tower(ctx, V3(x, 0, -Z - 18), 9, 56, {roof = true, roofColor = C.BLUE, roofH = 22, windows = true, base = 4}) end
	-- great banners hanging down the keep
	for _, x in ipairs({-25, 25}) do
		local b = K.box(ctx, "KeepBanner", V3(7, 18, 0.3), V3(x, 30, -Z - 4.6), C.BLUE, M.Fabric)
		b.CanCollide = false
		K.box(ctx, "KeepBannerTrim", V3(7.4, 0.8, 0.4), V3(x, 39.2, -Z - 4.5), C.GOLD, M.Metal).CanCollide = false
		K.box(ctx, "KeepBannerCrest", V3(3, 3, 0.4), V3(x, 31, -Z - 4.4), C.GOLD, M.Metal).CanCollide = false
	end

	----------------------------------------------------------------
	-- the Hall of Champions: a terrace, three plinths, two boards
	----------------------------------------------------------------
	K.box(ctx, "Terrace", V3(96, 3, 32), V3(0, 1.5, -72), MARBLE, M.Marble)
	K.box(ctx, "TerraceEdge", V3(97, 0.6, 33), V3(0, 3.2, -72), C.STONEDARK, M.Slate)
	K.stairs(ctx, CFrame.new(0, 0, -48.4), 34, 4, 0.75, 1.9, MARBLE, M.Marble)
	local plinths = {{x = 0, h = 6.5, color = C.GOLD, rank = 1}, {x = -16, h = 4.6, color = Color3.fromRGB(196, 204, 214), rank = 2}, {x = 16, h = 3.4, color = Color3.fromRGB(196, 130, 72), rank = 3}}
	for _, pl in ipairs(plinths) do
		local z = pl.rank == 1 and -74 or -71
		local top = 3 + pl.h
		K.box(ctx, "Plinth", V3(7, pl.h, 7), V3(pl.x, 3 + pl.h / 2, z), MARBLE, M.Marble)
		K.box(ctx, "PlinthCap", V3(7.8, 0.6, 7.8), V3(pl.x, top + 0.3, z), C.STONEDARK, M.Slate)
		K.box(ctx, "PlinthBand", V3(7.2, 0.8, 7.2), V3(pl.x, 3 + pl.h * 0.65, z), pl.color, M.Metal)
		K.spot(ctx, "Statue" .. pl.rank, CFrame.lookAt(V3(pl.x, top + 0.6 + 3, z), V3(pl.x, top + 3.6, z + 10)))
		K.spot(ctx, "Plaque" .. pl.rank, CFrame.lookAt(V3(pl.x, 3 + pl.h * 0.35, z + 3.56), V3(pl.x, 3 + pl.h * 0.35, z + 10)), {Rank = pl.rank})
	end
	for _, sx in ipairs({-1, 1}) do
		local x = sx * 36
		for _, dx in ipairs({-7.6, 7.6}) do K.box(ctx, "BoardPost", V3(1.2, 15, 1.2), V3(x + dx, 3 + 7.5, -66), C.DARKWOOD, M.Wood) end
		K.box(ctx, "Board", V3(15, 11, 0.6), V3(x, 3 + 8.5, -66), C.DARKWOOD, M.WoodPlanks)
		K.box(ctx, "BoardRoof", V3(17, 0.6, 3), V3(x, 3 + 14.6, -65.4), C.RED, M.Fabric)
		K.spot(ctx, sx < 0 and "BoardKills" or "BoardRanked", CFrame.lookAt(V3(x, 3 + 8.5, -65.65), V3(x, 3 + 8.5, -40)))
	end
	for _, x in ipairs({-46, -26, 26, 46}) do K.banner(ctx, V3(x, 3, -86), 13, C.BLUE) end
	for _, x in ipairs({-19, 19}) do K.torchPost(ctx, V3(x, 0, -46), 5) end

	----------------------------------------------------------------
	-- the wishing fountain, benches round it
	----------------------------------------------------------------
	-- a stepped platform, a deep basin, two tiers of bowls and a gilded spire:
	-- about eighteen studs from the cobbles to the tip
	K.cyl(ctx, "FountainStep", 31, 0.8, V3(0, 0.4, 0), C.STONEDARK, M.Slate)
	K.cyl(ctx, "FountainStep", 27, 0.8, V3(0, 1.2, 0), MARBLE, M.Marble)
	K.cyl(ctx, "FountainBasin", 23, 2.6, V3(0, 2.9, 0), MARBLE, M.Marble)
	K.cyl(ctx, "FountainRim", 23.8, 0.5, V3(0, 4.45, 0), C.STONEDARK, M.Slate)
	K.nocollide(K.cyl(ctx, "FountainWater", 21.6, 0.2, V3(0, 3.9, 0), C.WATER, M.Glass)).Transparency = 0.25
	for i = 0, 7 do   -- carved panels round the basin
		local a = i / 8 * math.pi * 2 + math.pi / 8
		K.box(ctx, "BasinPanel", V3(3.4, 1.6, 0.3), CFrame.new(math.cos(a) * 11.6, 2.9, math.sin(a) * 11.6) * CFrame.Angles(0, -a + math.pi / 2, 0), C.STONEDARK, M.Slate)
	end
	K.cyl(ctx, "FountainPillar", 3.6, 5.6, V3(0, 6.4, 0), MARBLE, M.Marble)
	K.cyl(ctx, "FountainBowl", 11, 1.1, V3(0, 9.6, 0), MARBLE, M.Marble)
	K.cyl(ctx, "FountainBowlLip", 11.6, 0.4, V3(0, 10.3, 0), C.GOLD, M.Metal).CanCollide = false
	K.nocollide(K.cyl(ctx, "FountainBowlWater", 10.2, 0.2, V3(0, 10.2, 0), C.WATER, M.Glass)).Transparency = 0.2
	K.cyl(ctx, "FountainUpper", 1.8, 3.6, V3(0, 11.9, 0), MARBLE, M.Marble)
	K.cyl(ctx, "FountainCup", 5, 0.8, V3(0, 14, 0), MARBLE, M.Marble)
	K.nocollide(K.cyl(ctx, "FountainCupWater", 4.4, 0.2, V3(0, 14.35, 0), C.WATER, M.Glass)).Transparency = 0.2
	K.ball(ctx, "FountainCrown", 1.6, V3(0, 15.4, 0), C.GOLD, M.Metal)
	K.cone(ctx, "FountainSpire", V3(0, 16, 0), 0.5, 2.2, C.GOLD, M.Metal, nil, true, 6)
	-- falling water: sheets from each bowl into the one below
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local sheet = K.box(ctx, "Fall", V3(1.4, 5.9, 0.1), CFrame.new(math.cos(a) * 5.4, 7.1, math.sin(a) * 5.4) * CFrame.Angles(0, -a + math.pi / 2, 0), C.WATER, M.Glass)
		sheet.CanCollide = false; sheet.Transparency = 0.5
	end
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local sheet = K.box(ctx, "Fall", V3(1, 3.6, 0.1), CFrame.new(math.cos(a) * 2.4, 12.3, math.sin(a) * 2.4) * CFrame.Angles(0, -a + math.pi / 2, 0), C.WATER, M.Glass)
		sheet.CanCollide = false; sheet.Transparency = 0.5
	end
	-- a spray off the top
	do
		local jet = K.nocollide(K.box(ctx, "FountainJet", V3(0.4, 0.4, 0.4), V3(0, 17.4, 0), C.WATER, M.Glass))
		jet.Transparency = 1
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
		e.Size = NumberSequence.new(0.35, 0.1)
		e.Transparency = NumberSequence.new(0.2, 1)
		e.Lifetime = NumberRange.new(0.8, 1.2)
		e.Speed = NumberRange.new(5, 8)
		e.SpreadAngle = Vector2.new(18, 18)
		e.Acceleration = Vector3.new(0, -24, 0)
		e.Rate = 30
		e.LightEmission = 0.4
		e.Parent = jet
	end
	K.spot(ctx, "WellSpot", CFrame.new(0, 4.2, 0))
	for i, a in ipairs({45, 135, 225, 315}) do
		local r = math.rad(a)
		local pos = V3(math.cos(r) * 20, 0, math.sin(r) * 20)
		local look = CFrame.lookAt(pos, V3(0, 0, 0))
		K.box(ctx, "BenchSeat", V3(6, 0.5, 1.8), look * CFrame.new(0, 1.3, 0), C.WOOD, M.WoodPlanks)
		K.box(ctx, "BenchBack", V3(6, 1.6, 0.3), look * CFrame.new(0, 2.3, 0.85), C.WOOD, M.WoodPlanks)
		for _, dx in ipairs({-2.4, 2.4}) do K.box(ctx, "BenchLeg", V3(0.4, 1.1, 1.6), look * CFrame.new(dx, 0.55, 0), C.IRON, M.Metal) end
		for _, dx in ipairs({-1.5, 1.5}) do
			local seat = Instance.new("Seat"); seat.Name = "Seat"; seat.Size = V3(2, 0.3, 1.6); seat.Transparency = 1; seat.Anchored = true; seat.CanCollide = false
			seat.CFrame = look * CFrame.new(dx, 1.6, 0); seat.Parent = ctx.Props
		end
	end

	----------------------------------------------------------------
	-- the Gates of War (south): three arches with glowing doors
	----------------------------------------------------------------
	local gates = {{x = -36, name = "GateTraining", color = Color3.fromRGB(90, 200, 110)}, {x = 0, name = "GateWarfront", color = Color3.fromRGB(230, 70, 60)}, {x = 36, name = "GateLists", color = Color3.fromRGB(245, 190, 60)}}
	for _, g in ipairs(gates) do
		local frame = CFrame.new(g.x, 0, 72)
		K.box(ctx, "GateStep", V3(16, 0.6, 7), frame * CFrame.new(0, 0.3, 0), C.STONEDARK, M.Slate)
		K.arch(ctx, frame * CFrame.new(0, 0.6, 0), 10, 14, 3, MARBLE, M.Marble)
		local door = K.box(ctx, "GateGlow", V3(9, 12, 0.3), frame * CFrame.new(0, 6.6, 0), g.color, M.Neon)
		door.CanCollide = false; door.Transparency = 0.35
		K.box(ctx, "GateSign", V3(12, 2.4, 0.5), frame * CFrame.new(0, 17.6, -1.4), C.DARKWOOD, M.WoodPlanks)
		K.spot(ctx, g.name, CFrame.lookAt(V3(g.x, 6.6, 72), V3(g.x, 6.6, 0)))
		K.spot(ctx, g.name .. "Sign", CFrame.lookAt(V3(g.x, 17.6, 71.1), V3(g.x, 17.6, 0)))
		for _, dx in ipairs({-8.5, 8.5}) do K.torchPost(ctx, V3(g.x + dx, 0, 66), 4.5) end
	end

	----------------------------------------------------------------
	-- the Merchant's Stall (south-west)
	----------------------------------------------------------------
	local stall = CFrame.new(-64, 0, 40) * CFrame.Angles(0, math.rad(45), 0)
	K.box(ctx, "StallFloor", V3(18, 1, 10), stall * CFrame.new(0, 0.5, 0), C.WOOD, M.WoodPlanks)
	K.box(ctx, "StallCounter", V3(18, 3, 1.6), stall * CFrame.new(0, 2.5, -4.4), C.DARKWOOD, M.WoodPlanks)
	K.box(ctx, "StallCounterTop", V3(18.6, 0.4, 2.2), stall * CFrame.new(0, 4.1, -4.4), Color3.fromRGB(150, 40, 40), M.Fabric)
	for _, x in ipairs({-8.6, 8.6}) do
		for _, z in ipairs({-4.6, 4.6}) do K.cyl(ctx, "StallPole", 0.6, 11, stall * CFrame.new(x, 6.5, z), C.DARKWOOD, M.Wood) end
	end
	for i = -4, 4 do
		local stripe = K.box(ctx, "StallAwning", V3(2.05, 0.2, 11.8), stall * CFrame.new(i * 2.05, 12, 0) * CFrame.Angles(math.rad(-10), 0, 0), (i % 2 == 0) and Color3.fromRGB(190, 40, 40) or C.WHITE, M.Fabric)
		stripe.CanCollide = false
	end
	K.spot(ctx, "StallMannequin1", stall * CFrame.new(-4.5, 4, 1.4) * CFrame.Angles(0, math.pi, 0))
	K.spot(ctx, "StallMannequin2", stall * CFrame.new(4.5, 4, 1.4) * CFrame.Angles(0, math.pi, 0))
	K.spot(ctx, "StallRack", stall * CFrame.new(0, 1, 2.6) * CFrame.Angles(0, math.pi, 0))
	K.box(ctx, "StallSign", V3(9, 2, 0.4), stall * CFrame.new(0, 13.6, -5.8), C.DARKWOOD, M.WoodPlanks)
	K.spot(ctx, "StallSign", stall * CFrame.new(0, 13.6, -6.05) * CFrame.Angles(0, math.pi, 0))
	for i, off in ipairs({V3(-11, 0, -2), V3(-12, 0, 2), V3(11, 0, 1)}) do
		if i < 3 then K.barrel(ctx, (stall * CFrame.new(off)).Position) else K.crate(ctx, (stall * CFrame.new(off)).Position, 3, 20) end
	end

	----------------------------------------------------------------
	-- the tavern corner (south-east)
	----------------------------------------------------------------
	local tav = CFrame.new(78, 0, 52) * CFrame.Angles(0, math.rad(-90), 0)
	K.box(ctx, "Tavern", V3(26, 12, 14), tav * CFrame.new(0, 6, 0), C.WHITE, M.Concrete)
	for _, x in ipairs({-12.6, -4.2, 4.2, 12.6}) do K.box(ctx, "TavernBeam", V3(0.8, 12, 14.4), tav * CFrame.new(x, 6, 0), C.DARKWOOD, M.Wood) end
	K.box(ctx, "TavernBeamH", V3(26.4, 0.8, 14.4), tav * CFrame.new(0, 6.2, 0), C.DARKWOOD, M.Wood)
	for _, s in ipairs({-1, 1}) do
		K.wedge(ctx, "TavernRoof", V3(27, 6, 7.6), tav * CFrame.new(0, 15, s * 3.8) * CFrame.Angles(0, s < 0 and 0 or math.pi, 0), Color3.fromRGB(120, 60, 40), M.Slate)
	end
	K.box(ctx, "TavernDoor", V3(4, 7, 0.4), tav * CFrame.new(0, 3.5, -7.2), C.DARKWOOD, M.WoodPlanks).CanCollide = false
	for _, x in ipairs({-8, 8}) do K.box(ctx, "TavernWindow", V3(3.4, 3, 0.4), tav * CFrame.new(x, 6.8, -7.2), Color3.fromRGB(255, 204, 120), M.Neon).CanCollide = false end
	K.box(ctx, "TavernSign", V3(6, 2.6, 0.3), tav * CFrame.new(0, 10.4, -7.6), C.WOOD, M.WoodPlanks)
	K.spot(ctx, "TavernSign", tav * CFrame.new(0, 10.4, -7.8) * CFrame.Angles(0, math.pi, 0))
	-- tables with benches out front
	for i, off in ipairs({V3(-8, 0, -14), V3(4, 0, -16), V3(-2, 0, -25)}) do
		local t = tav * CFrame.new(off) * CFrame.Angles(0, math.rad(i * 25), 0)
		K.box(ctx, "Table", V3(6, 0.4, 3), t * CFrame.new(0, 2.6, 0), C.WOOD, M.WoodPlanks)
		K.box(ctx, "TableLeg", V3(0.6, 2.4, 2.4), t * CFrame.new(0, 1.2, 0), C.DARKWOOD, M.Wood)
		for _, s in ipairs({-1, 1}) do
			K.box(ctx, "TableBench", V3(6, 0.4, 1.2), t * CFrame.new(0, 1.5, s * 2.6), C.WOOD, M.WoodPlanks)
			for _, dx in ipairs({-1.8, 0, 1.8}) do
				local seat = Instance.new("Seat"); seat.Name = "Seat"; seat.Size = V3(1.6, 0.3, 1.2); seat.Transparency = 1; seat.Anchored = true; seat.CanCollide = false
				seat.CFrame = t * CFrame.new(dx, 1.75, s * 2.6) * CFrame.Angles(0, s < 0 and math.pi or 0, 0); seat.Parent = ctx.Props
			end
		end
		K.cyl(ctx, "Tankard", 0.5, 0.7, t * CFrame.new(1, 3.15, 0.4), Color3.fromRGB(120, 90, 60), M.Wood).CanCollide = false
	end
	K.spot(ctx, "BardSpot", tav * CFrame.new(10, 3, -16) * CFrame.Angles(0, math.rad(200), 0))
	K.box(ctx, "BardStage", V3(6, 0.8, 5), tav * CFrame.new(10, 0.4, -16), C.WOOD, M.WoodPlanks)
	for _, off in ipairs({V3(-14, 0, -9), V3(-15, 0, -6), V3(14, 0, -8)}) do K.barrel(ctx, (tav * CFrame.new(off)).Position) end

	----------------------------------------------------------------
	-- the Notice Board, where you arrive
	----------------------------------------------------------------
	do
		local nb = CFrame.lookAt(V3(0, 0, 38), V3(0, 0, 0))
		for _, x in ipairs({-5.2, 5.2}) do K.box(ctx, "NoticePost", V3(0.8, 10, 0.8), nb * CFrame.new(x, 5, 0), C.DARKWOOD, M.Wood) end
		K.box(ctx, "NoticeBoard", V3(10, 6.4, 0.5), nb * CFrame.new(0, 5.4, 0), C.WOOD, M.WoodPlanks)
		for _, s in ipairs({-1, 1}) do
			K.wedge(ctx, "NoticeRoof", V3(12, 1.6, 1.6), nb * CFrame.new(0, 9.6, s * 0.8) * CFrame.Angles(0, s < 0 and math.pi or 0, 0), Color3.fromRGB(150, 40, 40), M.Fabric)
		end
		K.spot(ctx, "NoticeBoard", nb * CFrame.new(0, 5.4, -0.3))
	end

	----------------------------------------------------------------
	-- the Hatchery's place (west) and the stone circle (east)
	----------------------------------------------------------------
	K.spot(ctx, "HatcherySpot", CFrame.lookAt(V3(-66, 0.5, -10), V3(0, 0.5, -10)))
	do
		local c = V3(66, 0, -10)
		K.cyl(ctx, "ShrineFloor", 22, 0.4, c + V3(0, 0.2, 0), C.STONE, M.Slate)
		K.cyl(ctx, "ShrineInner", 12, 0.45, c + V3(0, 0.22, 0), Color3.fromRGB(70, 96, 70), M.Grass).CanCollide = false
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			local p = c + V3(math.cos(a) * 9.5, 0, math.sin(a) * 9.5)
			local h = (i % 2 == 0) and 7.5 or 6
			K.box(ctx, "Standing", V3(1.8, h, 1.2), CFrame.new(p + V3(0, h / 2, 0)) * CFrame.Angles(0, -a, math.rad((i % 3 - 1) * 3)), C.STONEDARK, M.Slate)
			local candle = K.cyl(ctx, "Candle", 0.4, 0.9, p + V3(math.cos(a) * -1.4, 0.45, math.sin(a) * -1.4), C.WHITE, M.SmoothPlastic)
			candle.CanCollide = false
			local f = K.ball(ctx, "CandleFlame", 0.35, candle.Position + V3(0, 0.6, 0), K.C.FIRE, M.Neon)
			f.CanCollide = false
		end
		K.box(ctx, "Altar", V3(3.2, 1.6, 2.2), CFrame.new(c + V3(0, 0.8, 0)), MARBLE, M.Marble)
		K.ball(ctx, "AltarOrb", 1.2, c + V3(0, 2.3, 0), Color3.fromRGB(150, 200, 255), M.Neon).CanCollide = false
		K.spot(ctx, "ShrineSpot", CFrame.lookAt(c + V3(0, 0.5, 0), V3(0, 0.5, -10)))
	end

	----------------------------------------------------------------
	-- trees in planters, lamps, banners
	----------------------------------------------------------------
	-- big oaks in raised stone planters: a thick trunk, two boughs, a wide crown
	local function oak(pos, h)
		K.box(ctx, "Planter", V3(10, 1.8, 10), pos + V3(0, 0.9, 0), C.STONEDARK, M.Slate)
		K.box(ctx, "PlanterCap", V3(10.6, 0.4, 10.6), pos + V3(0, 2.0, 0), MARBLE, M.Marble)
		K.nocollide(K.box(ctx, "PlanterSoil", V3(9, 0.2, 9), pos + V3(0, 2.12, 0), Color3.fromRGB(80, 60, 40), M.Ground))
		local base = pos + V3(0, 2.2, 0)
		K.cyl(ctx, "Trunk", 2.2, h * 0.55, base + V3(0, h * 0.275, 0), C.DARKWOOD, M.Wood)
		K.cyl(ctx, "Bough", 1.1, h * 0.3, CFrame.new(base + V3(1.4, h * 0.5, 0)) * CFrame.Angles(0, 0, math.rad(-35)), C.DARKWOOD, M.Wood)
		K.cyl(ctx, "Bough", 1.0, h * 0.28, CFrame.new(base + V3(-1.2, h * 0.52, 0.6)) * CFrame.Angles(math.rad(20), 0, math.rad(32)), C.DARKWOOD, M.Wood)
		for _, o in ipairs({V3(0, h * 0.78, 0), V3(3.2, h * 0.66, 1.2), V3(-3, h * 0.68, -1.4), V3(1, h * 0.92, -1.6), V3(-1.6, h * 0.86, 2.4), V3(2.2, h * 0.84, 2.6)}) do
			K.nocollide(K.ball(ctx, "Leaves", h * 0.48, base + o, (o.X > 0) and C.LEAF or C.LEAFDARK, M.Grass))
		end
	end
	for _, p in ipairs({V3(-34, 0, -30), V3(34, 0, -30), V3(-34, 0, 34), V3(34, 0, 34), V3(-86, 0, -60), V3(86, 0, -60)}) do oak(p, 17) end
	for _, p in ipairs({V3(-28, 0, 14), V3(28, 0, 14), V3(-28, 0, -16), V3(28, 0, -16), V3(-50, 0, 66), V3(50, 0, 66), V3(-86, 0, 10), V3(86, 0, 18)}) do K.torchPost(ctx, p, 8.5) end

	-- paved walks of pale flagstones: a ring round the fountain and roads to
	-- the Hall, the Gates, the Hatchery and the stone circle
	local FLAG = Color3.fromRGB(196, 188, 172)
	-- (overlapping slabs never share a top: they'd flicker. Alternate ring
	-- stones sit 0.05 apart, the edging well below, the roads above the ring)
	local function walk(a, b, w, lift)
		local len = (b - a).Magnitude
		local h = 0.16 + (lift or 0)
		local slab = K.box(ctx, "Path", V3(w, h, len), CFrame.lookAt((a + b) / 2, b) + V3(0, h / 2, 0), FLAG, M.Pavement)
		K.box(ctx, "PathEdge", V3(w + 1, 0.07, len), CFrame.lookAt((a + b) / 2, b) + V3(0, 0.035, 0), C.STONEDARK, M.Slate)
		return slab
	end
	for i = 0, 23 do   -- the ring: 24 segments
		local a0, a1 = i / 24 * math.pi * 2, (i + 1) / 24 * math.pi * 2
		walk(V3(math.cos(a0) * 25.5, 0, math.sin(a0) * 25.5), V3(math.cos(a1) * 25.5, 0, math.sin(a1) * 25.5), 6, (i % 2) * 0.05)
	end
	walk(V3(0, 0, -27), V3(0, 0, -47), 10, 0.12)    -- to the Hall's stairs
	walk(V3(0, 0, 27), V3(0, 0, 33), 10, 0.12)      -- to the Notice Board
	walk(V3(0, 0, 42), V3(0, 0, 68), 10, 0.12)      -- and on to the Warfront gate
	walk(V3(-27, 0, 0), V3(-56, 0, -8), 8, 0.12)    -- to the Hatchery
	walk(V3(27, 0, 0), V3(55, 0, -8), 8, 0.12)      -- to the stone circle
	for _, x in ipairs({-80, -60, 60, 80}) do K.banner(ctx, V3(x, 0, 84), 11, C.BLUE) end

	-- arrive round the south side of the fountain, facing the Hall
	for i = -3, 3 do K.spawn(ctx, V3(i * 6, 1, 24 + math.abs(i) * 1.5), nil, V3(i * 2, 1, -40)) end
	K.camera(ctx, V3(0, 18, 60), V3(0, 9, -60))
	K.camera(ctx, V3(-80, 40, 70), V3(0, 4, -20))
	K.camera(ctx, V3(40, 10, -30), V3(-10, 8, -70))
	K.lighting(ctx, {ClockTime = 15.6, FogEnd = 1200, FogColor = Color3.fromRGB(214, 206, 190), Brightness = 2.5, OutdoorAmbient = Color3.fromRGB(146, 138, 124), Ambient = Color3.fromRGB(88, 84, 78)})
	return K.finish(ctx)
end
