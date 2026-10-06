--[[ THE COLOSSEUM — a sun-baked arena: a round sand floor ringed by a podium
     wall, four tiers of stands and a two-storey arcade of arches, red and
     white awnings overhead. Four gates (north, east, south, west) lead in
     under the stands: the Horde pours in through them (Spots HordeGate1..4).
     A low dais in the middle is the King of the Hill's hill; broken columns
     and a few statues give cover. Built by
       require(game.ServerScriptService.Build.Maps).build("Colosseum")
     Used by Horde, the Lists (2v2, 3v3), Last Team Standing, FFA, KOTH. ]]

return function(K)
	local C, M = K.C, K.M
	local V3 = Vector3.new
	local DEG = math.rad
	local ctx = K.new("Colosseum")

	local STONE = Color3.fromRGB(214, 188, 146)
	local STONE2 = Color3.fromRGB(190, 162, 120)
	local DARK = Color3.fromRGB(150, 124, 90)
	local MARBLE = Color3.fromRGB(232, 226, 214)
	local RED = Color3.fromRGB(176, 46, 40)

	local ARENA = 46      -- the sand floor's radius
	local SEG = 32        -- segments round the ring
	local GATES = {0, 90, 180, 270}   -- degrees (0 = +X, east; 90 = +Z, south)

	K.terrain(ctx, V3(-140, -40, -140), V3(280, 80, 280), function(T)
		T:FillBlock(CFrame.new(0, -6, 0), V3(270, 12, 270), Enum.Material.Sand)
		-- dunes outside the walls
		local r = Random.new(9)
		for i = 1, 18 do
			local a = i / 18 * math.pi * 2
			local d = 110 + r:NextNumber(0, 14)
			T:FillBall(V3(math.cos(a) * d, -8 + r:NextNumber(0, 4), math.sin(a) * d), r:NextNumber(12, 20), Enum.Material.Sand)
		end
	end)
	K.terrainColors(ctx, {Sand = Color3.fromRGB(222, 192, 134)})

	local function polar(r, deg, y) local a = DEG(deg); return V3(math.cos(a) * r, y or 0, math.sin(a) * r) end
	-- a segment at angle `deg` facing the middle: its frame sits on the ground at radius r
	local function seg(r, deg) return CFrame.lookAt(polar(r, deg), V3(0, 0, 0)) end
	local function nearGate(deg, half)
		for _, g in ipairs(GATES) do
			local d = math.abs(((deg - g + 180) % 360) - 180)
			if d < half then return true end
		end
		return false
	end
	local step = 360 / SEG

	-- the floor: a ring of darker sand at the edge
	K.cyl(ctx, "ArenaEdge", (ARENA + 2) * 2, 0.2, V3(0, 0.1, 0), Color3.fromRGB(196, 164, 110), M.Sand)
	K.cyl(ctx, "ArenaFloor", (ARENA - 1) * 2, 0.24, V3(0, 0.12, 0), Color3.fromRGB(226, 198, 142), M.Sand)

	-- the podium wall round the floor (6 high, marble-capped), open at the gates
	for i = 0, SEG - 1 do
		local deg = i * step
		if not nearGate(deg, step * 0.5) then
			local f = seg(ARENA + 1.5, deg)
			local len = 2 * math.pi * (ARENA + 1.5) / SEG + 0.1
			K.box(ctx, "Podium", V3(len, 6, 3), f * CFrame.new(0, 3, 0), STONE2, M.Sandstone)
			K.box(ctx, "PodiumCap", V3(len + 0.1, 0.6, 3.6), f * CFrame.new(0, 6.3, -0.1), MARBLE, M.Marble)
		end
	end
	-- four tiers of stands rising behind it
	for t = 1, 4 do
		local r = ARENA + 3 + t * 4
		local top = 6 + t * 3
		for i = 0, SEG - 1 do
			local deg = i * step
			if not nearGate(deg, step * 0.5) then
				local f = seg(r, deg)
				local len = 2 * math.pi * r / SEG + 0.15
				K.box(ctx, "Stand", V3(len, top, 4), f * CFrame.new(0, top / 2, 0), (t % 2 == 0) and STONE or STONE2, M.Sandstone)
				K.box(ctx, "StandLip", V3(len + 0.05, 0.4, 0.8), f * CFrame.new(0, top + 0.2, -1.6), DARK, M.Sandstone)
			end
		end
	end
	-- the outer arcade: two storeys of arches all round
	local OUT = ARENA + 24
	for i = 0, SEG - 1 do
		local deg = i * step
		local f = seg(OUT, deg)
		local len = 2 * math.pi * OUT / SEG + 0.2
		if nearGate(deg, step * 0.5) then
			-- the gate: a tall opening, a big arch and a raised portcullis
			K.box(ctx, "GateLintel", V3(len, 8, 4), f * CFrame.new(0, 26, 0), STONE, M.Sandstone)
			K.box(ctx, "GateAttic", V3(len, 4, 4.4), f * CFrame.new(0, 32, 0), STONE2, M.Sandstone)
			for _, sx in ipairs({-1, 1}) do K.box(ctx, "GatePier", V3(1.4, 22, 4.4), f * CFrame.new(sx * (len / 2 - 0.7), 11, 0), STONE2, M.Sandstone) end
			for k = -2, 2 do K.box(ctx, "Portcullis", V3(0.4, 6, 0.4), f * CFrame.new(k * 2.2, 19, -1.6), C.IRON, M.Metal) end
			K.box(ctx, "PortcullisBar", V3(10, 0.4, 0.4), f * CFrame.new(0, 16.5, -1.6), C.IRON, M.Metal)
		else
			-- lower storey: an arch; upper storey: an arch; an attic course on top
			K.arch(ctx, f * CFrame.new(0, 0, 0), 7, 11, 4, STONE, M.Sandstone)
			K.arch(ctx, f * CFrame.new(0, 13, 0), 7, 10, 4, STONE2, M.Sandstone)
			K.box(ctx, "Course", V3(len, 1.2, 4.6), f * CFrame.new(0, 12.4, 0), DARK, M.Sandstone)
			K.box(ctx, "Attic", V3(len, 6, 4), f * CFrame.new(0, 27, 0), STONE, M.Sandstone)
			-- the space between an arch's piers and its neighbours' is filled
			local fill = math.max(0, (len - 7 - 2.8) / 2)
			if fill > 0.05 then
				for _, sx in ipairs({-1, 1}) do
					K.box(ctx, "Pier", V3(fill, 24, 4), f * CFrame.new(sx * (len / 2 - fill / 2), 12, 0), STONE, M.Sandstone)
				end
			end
		end
	end
	-- the passages: from each gate in under the stands to the arena, walls each side
	for gi, g in ipairs(GATES) do
		local a = DEG(g)
		local dir = V3(math.cos(a), 0, math.sin(a))
		local side = V3(-dir.Z, 0, dir.X)
		local mid = dir * ((ARENA + OUT) / 2)
		local look = CFrame.lookAt(mid, mid - dir)
		local length = OUT - ARENA
		-- (thick walls: they close the stands' edges either side of the gap)
		for _, s in ipairs({-1, 1}) do
			K.box(ctx, "PassageWall", V3(3, 12, length), look * CFrame.new(s * 4.9, 6, 0), STONE2, M.Sandstone)
		end
		K.box(ctx, "PassageRoof", V3(12.8, 1.4, length), look * CFrame.new(0, 12.7, 0), DARK, M.Sandstone)
		for k = -2, 2 do K.torch(ctx, (look * CFrame.new(3.1, 7, k * (length / 5))).Position, math.deg(math.atan2(-side.X, -side.Z))) end
		-- where the horde comes in, and a sign of which gate
		K.spot(ctx, "HordeGate" .. gi, CFrame.lookAt(dir * (ARENA + 12) + V3(0, 3, 0), V3(0, 3, 0)))
	end

	-- awnings: red and white cloths from the attic toward the middle (the outer half only)
	for i = 0, SEG - 1 do
		if i % 2 == 1 then
			local deg = i * step
			local a = DEG(deg)
			local outP = V3(math.cos(a) * (OUT - 1), 30, math.sin(a) * (OUT - 1))
			local inP = V3(math.cos(a) * (ARENA + 6), 25, math.sin(a) * (ARENA + 6))
			local cloth = K.box(ctx, "Awning", V3(2 * math.pi * OUT / SEG * 0.9, 0.15, (outP - inP).Magnitude), CFrame.lookAt((outP + inP) / 2, inP), (i % 4 == 1) and RED or C.WHITE, M.Fabric)
			cloth.CanCollide = false
			K.rope(ctx, inP, inP + V3(0, 8, 0) + (V3(0, 0, 0) - inP).Unit * 6)
		end
	end
	-- banners and torches along the podium
	for i = 0, SEG - 1 do
		local deg = i * step
		if not nearGate(deg, step * 1.2) and i % 2 == 1 then
			local f = seg(ARENA - 0.6, deg)
			local b = K.box(ctx, "PodiumBanner", V3(2.4, 4.6, 0.15), f * CFrame.new(0, 3.4, 0.6), (i % 4 == 1) and RED or C.GOLD, M.Fabric)
			b.CanCollide = false
		end
	end

	-- the middle: a low round dais (the hill), four broken columns, two statues
	K.cyl(ctx, "Dais", 18, 1.2, V3(0, 0.6, 0), MARBLE, M.Marble)
	K.cyl(ctx, "DaisRing", 19, 0.6, V3(0, 0.3, 0), STONE2, M.Sandstone)
	K.hill(ctx, V3(0, 1.2, 0), 9, 8)
	for i, a in ipairs({45, 135, 225, 315}) do
		local p = polar(24, a)
		local h = (i % 2 == 0) and 9 or 5.5
		K.cyl(ctx, "ColumnBase", 3.6, 1, p + V3(0, 0.5, 0), MARBLE, M.Marble)
		K.cyl(ctx, "Column", 2.6, h, p + V3(0, 1 + h / 2, 0), MARBLE, M.Marble)
		if h > 6 then K.box(ctx, "Capital", V3(3.6, 1, 3.6), p + V3(0, 1 + h + 0.5, 0), MARBLE, M.Marble) end
		if h < 6 then
			-- the broken top lies beside it
			K.cyl(ctx, "Drum", 2.6, 3, CFrame.new(p + polar(3, a + 70, 1.3)) * CFrame.Angles(0, DEG(a), DEG(90)), MARBLE, M.Marble)
		end
	end
	-- two statues of champions on plinths, either side of the north gate
	for _, s in ipairs({-1, 1}) do
		local p = polar(ARENA - 5, 270 + s * 18)
		K.box(ctx, "StatuePlinth", V3(4, 3, 4), p + V3(0, 1.5, 0), MARBLE, M.Marble)
		K.box(ctx, "StatueBody", V3(2, 4, 1.2), p + V3(0, 5, 0), C.GOLD, M.Metal)
		K.ball(ctx, "StatueHead", 1.4, p + V3(0, 7.7, 0), C.GOLD, M.Metal)
		K.box(ctx, "StatueSword", V3(0.3, 5, 0.3), CFrame.new(p + V3(s * 1.4, 6.5, -0.3)) * CFrame.Angles(0, 0, DEG(s * 10)), C.GOLD, M.Metal)
	end
	-- a weapon rack and some crates by the east and west gates
	for _, g in ipairs({0, 180}) do
		local a = DEG(g)
		local dir = V3(math.cos(a), 0, math.sin(a))
		local side = V3(-dir.Z, 0, dir.X)
		K.rack(ctx, CFrame.lookAt(dir * (ARENA - 4) + side * 9, V3(0, 0, 0)))
		K.crate(ctx, dir * (ARENA - 4) - side * 9, 3, g + 20)
		K.barrel(ctx, dir * (ARENA - 6) - side * 12)
	end

	-- spawns: the two sides at the east and west gates, everyone else round the dais
	for i = -2, 2 do
		K.spawn(ctx, V3(-ARENA + 8, 1, i * 4), "A", V3(0, 1, i * 4))
		K.spawn(ctx, V3(ARENA - 8, 1, i * 4), "B", V3(0, 1, i * 4))
	end
	for i = 1, 8 do
		local p = polar(15, i * 45 + 22)
		K.spawn(ctx, p + V3(0, 1, 0), nil, V3(0, 1, 0))
	end
	K.camera(ctx, V3(-60, 34, 60), V3(0, 2, 0))
	K.camera(ctx, V3(30, 9, -30), V3(-10, 4, 10))
	K.camera(ctx, V3(0, 40, 0) + V3(50, 0, 0), V3(0, 0, 0))
	K.lighting(ctx, {ClockTime = 13.2, FogEnd = 900, FogColor = Color3.fromRGB(236, 214, 176), Brightness = 2.8,
		OutdoorAmbient = Color3.fromRGB(160, 146, 120), Ambient = Color3.fromRGB(96, 88, 74)})
	return K.finish(ctx)
end
