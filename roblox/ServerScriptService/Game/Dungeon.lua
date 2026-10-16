--[[ DUNGEON — builds a dungeon floor from nothing, in a theme (ReplicatedStorage ▸ Catalog ▸
     Dungeons), for The Depths and Deadvault. Never the same twice.

       Dungeon.build(themeKey, opts) -> mapName, layout
         opts.rooms      how many rooms (8)
         opts.grid       {w, h} cells (4, 4); a cell is CELL studs
         opts.final      "boss" (the theme's boss in a great hall) · "stairs" (the way down) ·
                         "none"
         opts.special    {treasure = n, shrine = n, fountain = n, elite = n} (1, 1, 1, 1)
         opts.exits      n extraction rooms (Deadvault: kind "exit", far from the start)
         opts.seed       a number (random otherwise)
         opts.name       the map's name in ServerStorage ▸ Maps (Gen_<n> otherwise)

     The floor lands in ServerStorage ▸ Maps like any map (MapLoader loads it): Spawns in the
     start room, a menu camera, the theme's light. The LAYOUT tells the mode what's where:
       layout.rooms[id] = {id, gx, gy, cx, cz, w, d, kind, depth, doors = {N|S|E|W = room id},
                           spots = {Vector3…} (where monsters stand), chest (Vector3),
                           feature (Vector3: a shrine's altar, a fountain, the stairs, the boss's
                           dais, an exit portal), gates = {gate names}}
       layout.start · layout.final · layout.order (ids by depth) · layout.theme
     Rooms: start · combat · elite · treasure · shrine · fountain · stairs · boss · exit.
     A doorway carries a portcullis (Map ▸ Gates ▸ <name>: a Model with an anchored GateRoot,
     up inside the wall; the mode drops it to shut a fight in: Dungeon.setGate). ]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local K = require(ServerScriptService:WaitForChild("Build"):WaitForChild("MapKit"))

local Dungeon = {}
local CELL = 86
local T = 2            -- wall thickness
local WALL_H = 22      -- a room's walls (its ceiling sits on them)
local DOOR_W, DOOR_H = 12, 12
local CORR_H = 14      -- a corridor's ceiling
Dungeon.CELL, Dungeon.DOOR_W = CELL, DOOR_W

local DIRS = {N = {0, -1}, S = {0, 1}, E = {1, 0}, W = {-1, 0}}
local OPP = {N = "S", S = "N", E = "W", W = "E"}
local made = 0

local function mat(name) return Enum.Material[name] or Enum.Material.Slate end
local function shade(c, k) return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1)) end

--------------------------------------------------------------------
--  THE PLAN: which cells hold rooms, how they join, what each is
--------------------------------------------------------------------
local function plan(opts, rng)
	local W, H = opts.grid and opts.grid[1] or 4, opts.grid and opts.grid[2] or 4
	local want = math.min(opts.rooms or 8, W * H)
	local cells, list = {}, {}
	local function key(x, y) return x .. "," .. y end
	-- start on an edge
	local sx, sy
	if rng:NextInteger(0, 1) == 0 then sx, sy = rng:NextInteger(0, W - 1), (rng:NextInteger(0, 1) == 0) and 0 or H - 1
	else sx, sy = (rng:NextInteger(0, 1) == 0) and 0 or W - 1, rng:NextInteger(0, H - 1) end
	local function add(x, y)
		local r = {id = #list + 1, gx = x, gy = y, doors = {}}
		cells[key(x, y)] = r
		table.insert(list, r)
		return r
	end
	add(sx, sy)
	local tries = 0
	while #list < want and tries < 2000 do
		tries += 1
		-- grow from a random room, favouring the newer ones (long winding halls, not a blob)
		local from = list[math.max(1, #list - rng:NextInteger(0, math.min(#list - 1, 3)))]
		if rng:NextNumber() < 0.3 then from = list[rng:NextInteger(1, #list)] end
		local names = {"N", "S", "E", "W"}
		local d = names[rng:NextInteger(1, 4)]
		local nx, ny = from.gx + DIRS[d][1], from.gy + DIRS[d][2]
		if nx >= 0 and ny >= 0 and nx < W and ny < H and not cells[key(nx, ny)] then
			local r = add(nx, ny)
			from.doors[d] = r.id
			r.doors[OPP[d]] = from.id
		end
	end
	-- a loop or two (two ways round: a fight you can flank, a retreat)
	local loops = opts.loops or 1
	for _ = 1, 30 do
		if loops <= 0 then break end
		local r = list[rng:NextInteger(1, #list)]
		local names = {"N", "S", "E", "W"}
		local d = names[rng:NextInteger(1, 4)]
		local o = cells[key(r.gx + DIRS[d][1], r.gy + DIRS[d][2])]
		if o and not r.doors[d] and r.id ~= 1 and o.id ~= 1 then
			r.doors[d] = o.id; o.doors[OPP[d]] = r.id
			loops -= 1
		end
	end
	-- depth from the start
	local depth, order = {[1] = 0}, {1}
	local qi = 1
	while qi <= #order do
		local r = list[order[qi]]; qi += 1
		for _, nid in pairs(r.doors) do
			if depth[nid] == nil then depth[nid] = depth[r.id] + 1; table.insert(order, nid) end
		end
	end
	for _, r in ipairs(list) do r.depth = depth[r.id] or 0 end
	return list, W, H, order
end

local function kinds(list, order, opts, rng)
	local byDepth = table.clone(order)
	table.sort(byDepth, function(a, b) return list[a].depth > list[b].depth end)
	list[1].kind = "start"
	local finalId
	if opts.final and opts.final ~= "none" then
		finalId = byDepth[1]
		list[finalId].kind = opts.final
	end
	local exits = {}
	for i = 1, (opts.exits or 0) do
		-- far from the start, and from each other
		local best, bestScore
		for _, id in ipairs(byDepth) do
			local r = list[id]
			if not r.kind then
				local s = r.depth * 10
				for _, e in ipairs(exits) do s += math.abs(list[e].gx - r.gx) * 6 + math.abs(list[e].gy - r.gy) * 6 end
				if not bestScore or s > bestScore then best, bestScore = id, s end
			end
		end
		if best then list[best].kind = "exit"; table.insert(exits, best) end
	end
	-- dead ends (one door) make good treasure rooms and shrines
	local leaves, others = {}, {}
	for _, r in ipairs(list) do
		if not r.kind then
			local n = 0
			for _ in pairs(r.doors) do n += 1 end
			if n == 1 then table.insert(leaves, r) else table.insert(others, r) end
		end
	end
	local function take(pool, other)
		if #pool > 0 then return table.remove(pool, rng:NextInteger(1, #pool)) end
		if other and #other > 0 then return table.remove(other, rng:NextInteger(1, #other)) end
		return nil
	end
	local sp = opts.special or {}
	for _ = 1, sp.treasure or 1 do local r = take(leaves, others); if r then r.kind = "treasure" end end
	for _ = 1, sp.shrine or 1 do local r = take(leaves, others); if r then r.kind = "shrine" end end
	for _ = 1, sp.fountain or 1 do local r = take(others, leaves); if r then r.kind = "fountain" end end
	-- an elite: deep, not next to the start
	for _ = 1, sp.elite or 1 do
		table.sort(others, function(a, b) return a.depth > b.depth end)
		local r = table.remove(others, 1) or take(leaves)
		if r then r.kind = "elite" end
	end
	for _, r in ipairs(list) do r.kind = r.kind or "combat" end
	return finalId, exits
end

--------------------------------------------------------------------
--  BUILDING
--------------------------------------------------------------------
-- a wall along `axis` ("x" | "z") centred on `c` (Vector3 on the floor), `len` long, with
-- doorway gaps at offsets (along the wall) `gaps`; returns nothing
local function wallRun(ctx, th, c, axis, len, h, gaps, doorH)
	local wc, wm = th.wall, mat(th.wallMat)
	local function seg(a, b, y0, y1)
		if b - a < 0.05 or y1 - y0 < 0.05 then return end
		local mid = (a + b) / 2
		local pos = axis == "x" and Vector3.new(c.X + mid, (y0 + y1) / 2, c.Z) or Vector3.new(c.X, (y0 + y1) / 2, c.Z + mid)
		local size = axis == "x" and Vector3.new(b - a, y1 - y0, T) or Vector3.new(T, y1 - y0, b - a)
		K.box(ctx, "Wall", size, CFrame.new(pos), wc, wm)
	end
	local cuts = {}
	for _, g in ipairs(gaps or {}) do table.insert(cuts, {g - DOOR_W / 2, g + DOOR_W / 2}) end
	table.sort(cuts, function(a, b) return a[1] < b[1] end)
	local at = -len / 2
	for _, cut in ipairs(cuts) do
		seg(at, cut[1], 0, h)
		seg(cut[1], cut[2], doorH or DOOR_H, h)   -- the lintel
		at = cut[2]
	end
	seg(at, len / 2, 0, h)
end

-- a sconce on a wall: bracket, flame, the theme's light
local function sconce(ctx, th, pos, facing)
	local iron = Color3.fromRGB(56, 54, 58)
	local f = CFrame.lookAt(pos, pos + facing)
	K.box(ctx, "Bracket", Vector3.new(0.4, 0.4, 1.2), f * CFrame.new(0, 0, -0.4), iron, Enum.Material.Metal, ctx.Props)
	K.cyl(ctx, "Cup", 0.9, 0.5, f * CFrame.new(0, 0.3, -1), iron, Enum.Material.Metal, ctx.Props)
	local flame = K.ball(ctx, "Flame", 0.8, f * CFrame.new(0, 0.85, -1), th.torch, Enum.Material.Neon, ctx.Props)
	flame.CanCollide = false
	local l = Instance.new("PointLight"); l.Color = th.torch; l.Range = 18; l.Brightness = 1.5; l.Shadows = true; l.Parent = flame
	local fire = Instance.new("Fire"); fire.Size = 2; fire.Heat = 5; fire.Color = th.torch; fire.SecondaryColor = shade(th.torch, 0.6); fire.Parent = flame
end

-- PROPS: fn(ctx, th, cf, rng) — cf on the floor, facing into the room
local P = {}
local function box(ctx, name, size, cf, color, m, collide)
	local p = K.box(ctx, name, size, cf, color, m, ctx.Props)
	if collide == false then p.CanCollide = false end
	return p
end
local BONE = Color3.fromRGB(226, 218, 196)
P.coffin = function(ctx, th, cf)
	local wood = Color3.fromRGB(70, 46, 30)
	box(ctx, "Coffin", Vector3.new(2.6, 1.4, 6), cf * CFrame.new(0, 0.7, 0), wood, Enum.Material.Wood)
	box(ctx, "Lid", Vector3.new(2.8, 0.3, 6.2), cf * CFrame.new(0.4, 1.5, 0) * CFrame.Angles(0, math.rad(8), 0), shade(wood, 1.2), Enum.Material.Wood)
	box(ctx, "Cross", Vector3.new(0.3, 0.1, 2), cf * CFrame.new(0.4, 1.7, -1), Color3.fromRGB(200, 170, 90), Enum.Material.Metal, false)
	box(ctx, "Cross", Vector3.new(1.2, 0.1, 0.3), cf * CFrame.new(0.4, 1.7, -1.4), Color3.fromRGB(200, 170, 90), Enum.Material.Metal, false)
end
P.bones = function(ctx, th, cf, rng)
	for i = 1, 5 do
		local p = box(ctx, "Bone", Vector3.new(0.3, 0.3, rng:NextNumber(1, 1.8)), cf * CFrame.new(rng:NextNumber(-1.5, 1.5), 0.15, rng:NextNumber(-1.5, 1.5)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), BONE, Enum.Material.SmoothPlastic, false)
		p.CanQuery = false
	end
	K.ball(ctx, "Skull", 0.9, cf * CFrame.new(0.3, 0.4, 0.2), BONE, Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
end
P.cobweb = function(ctx, th, cf)
	local p = box(ctx, "Cobweb", Vector3.new(5, 5, 0.05), cf * CFrame.new(0, WALL_H - 3, 0) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(230, 230, 230), Enum.Material.Fabric, false)
	p.Transparency = 0.6
	p.CanQuery = false
end
P.candles = function(ctx, th, cf, rng)
	for i = 1, 4 do
		local h = rng:NextNumber(0.6, 1.6)
		local at = cf * CFrame.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
		K.cyl(ctx, "Candle", 0.35, h, at * CFrame.new(0, h / 2, 0), Color3.fromRGB(236, 228, 200), Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
		local f = K.ball(ctx, "Flame", 0.25, at * CFrame.new(0, h + 0.15, 0), Color3.fromRGB(255, 200, 110), Enum.Material.Neon, ctx.Props)
		f.CanCollide = false
		if i == 1 then local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 190, 110); l.Range = 9; l.Brightness = 1; l.Parent = f end
	end
end
P.pillar = function(ctx, th, cf)
	K.cyl(ctx, "Pillar", 3, WALL_H, cf * CFrame.new(0, WALL_H / 2, 0), th.trim, mat(th.trimMat))
	box(ctx, "PillarBase", Vector3.new(4, 1.2, 4), cf * CFrame.new(0, 0.6, 0), shade(th.trim, 0.85), mat(th.trimMat))
	box(ctx, "PillarCap", Vector3.new(4, 1, 4), cf * CFrame.new(0, WALL_H - 0.5, 0), shade(th.trim, 0.85), mat(th.trimMat))
end
P.statue = function(ctx, th, cf)
	local stone = Color3.fromRGB(150, 150, 146)
	box(ctx, "Plinth", Vector3.new(3.5, 2, 3.5), cf * CFrame.new(0, 1, 0), shade(th.trim, 0.9), mat(th.trimMat))
	box(ctx, "StatueLegs", Vector3.new(1.6, 2.4, 0.9), cf * CFrame.new(0, 3.2, 0), stone, Enum.Material.Marble)
	box(ctx, "StatueBody", Vector3.new(2, 2.2, 1), cf * CFrame.new(0, 5.5, 0), stone, Enum.Material.Marble)
	K.ball(ctx, "StatueHead", 1.3, cf * CFrame.new(0, 7.2, 0), stone, Enum.Material.Marble, ctx.Props)
	box(ctx, "StatueSword", Vector3.new(0.3, 4, 0.15), cf * CFrame.new(0, 4.5, -0.8), shade(stone, 0.8), Enum.Material.Marble)
	box(ctx, "StatueGuard", Vector3.new(1.4, 0.3, 0.3), cf * CFrame.new(0, 6.2, -0.8), shade(stone, 0.8), Enum.Material.Marble)
end
P.rubble = function(ctx, th, cf, rng)
	for i = 1, 5 do
		local s = rng:NextNumber(0.8, 2.2)
		box(ctx, "Rubble", Vector3.new(s, s * 0.7, s), cf * CFrame.new(rng:NextNumber(-2, 2), s * 0.3, rng:NextNumber(-2, 2)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)), shade(th.wall, rng:NextNumber(0.75, 1)), mat(th.wallMat))
	end
end
P.brazier = function(ctx, th, cf)
	local iron = Color3.fromRGB(50, 48, 52)
	K.cyl(ctx, "BrazierStand", 0.6, 3, cf * CFrame.new(0, 1.5, 0), iron, Enum.Material.Metal, ctx.Props)
	K.cyl(ctx, "BrazierBowl", 2.6, 0.9, cf * CFrame.new(0, 3.2, 0), iron, Enum.Material.Metal, ctx.Props)
	local coal = K.cyl(ctx, "Coals", 2.2, 0.3, cf * CFrame.new(0, 3.65, 0), th.accent, Enum.Material.Neon, ctx.Props)
	coal.CanCollide = false
	local l = Instance.new("PointLight"); l.Color = th.torch; l.Range = 20; l.Brightness = 1.6; l.Parent = coal
	local fire = Instance.new("Fire"); fire.Size = 3.5; fire.Heat = 6; fire.Color = th.torch; fire.SecondaryColor = shade(th.torch, 0.6); fire.Parent = coal
end
P.mushroom = function(ctx, th, cf, rng)
	for i = 1, 3 do
		local h = rng:NextNumber(1.2, 3.2)
		local at = cf * CFrame.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
		K.cyl(ctx, "Stalk", 0.4 + h * 0.08, h, at * CFrame.new(0, h / 2, 0), Color3.fromRGB(220, 210, 180), Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
		local cap = K.ball(ctx, "Cap", 1.2 + h * 0.5, at * CFrame.new(0, h, 0), (i % 2 == 0) and Color3.fromRGB(120, 210, 90) or Color3.fromRGB(230, 140, 60), Enum.Material.Neon, ctx.Props)
		cap.Size = Vector3.new(cap.Size.X, cap.Size.Y * 0.45, cap.Size.Z)
		cap.CanCollide = false
	end
end
P.scaffold = function(ctx, th, cf)
	local wood = Color3.fromRGB(100, 72, 44)
	for _, x in ipairs({-2.5, 2.5}) do for _, z in ipairs({-1.5, 1.5}) do box(ctx, "Post", Vector3.new(0.6, 8, 0.6), cf * CFrame.new(x, 4, z), wood, Enum.Material.Wood) end end
	box(ctx, "Deck", Vector3.new(6, 0.5, 4), cf * CFrame.new(0, 6, 0), wood, Enum.Material.WoodPlanks)
	box(ctx, "Brace", Vector3.new(0.4, 0.4, 6.5), cf * CFrame.new(-2.5, 3, 0) * CFrame.Angles(math.rad(50), 0, 0), wood, Enum.Material.Wood, false)
end
P.goldpile = function(ctx, th, cf, rng)
	local gold = Color3.fromRGB(240, 196, 70)
	for i = 1, 6 do
		local s = rng:NextNumber(1, 2.6)
		local b = K.ball(ctx, "Gold", s, cf * CFrame.new(rng:NextNumber(-1.5, 1.5), s * 0.2, rng:NextNumber(-1.5, 1.5)), gold, Enum.Material.Metal, ctx.Props)
		b.Size = Vector3.new(s, s * 0.45, s)
		b.CanCollide = false
	end
	K.cyl(ctx, "Goblet", 0.5, 0.9, cf * CFrame.new(0.4, 1.2, 0.3), gold, Enum.Material.Metal, ctx.Props).CanCollide = false
end
P.crates = function(ctx, th, cf, rng)
	K.crate(ctx, (cf * CFrame.new(0, 0, 0)).Position, 3, rng:NextNumber(0, 90))
	K.crate(ctx, (cf * CFrame.new(2.8, 0, 0.5)).Position, 2.4, rng:NextNumber(0, 90))
	K.crate(ctx, (cf * CFrame.new(1.3, 3, 0.2)).Position, 2.2, rng:NextNumber(0, 90))
end
P.barrel = function(ctx, th, cf) K.barrel(ctx, cf.Position); K.barrel(ctx, (cf * CFrame.new(2.4, 0, 0.6)).Position) end
P.banner = function(ctx, th, cf)
	local c = th.accent
	local p = box(ctx, "Banner", Vector3.new(4, 9, 0.12), cf * CFrame.new(0, WALL_H - 7.5, 0), shade(c, 0.55), Enum.Material.Fabric, false)
	box(ctx, "BannerStripe", Vector3.new(1, 9, 0.14), p.CFrame, shade(c, 0.9), Enum.Material.Fabric, false)
	box(ctx, "BannerRod", Vector3.new(5, 0.4, 0.4), cf * CFrame.new(0, WALL_H - 2.8, 0), Color3.fromRGB(60, 50, 40), Enum.Material.Wood, false)
end
P.carpet = function(ctx, th, cf)
	local p = box(ctx, "Carpet", Vector3.new(7, 0.1, 12), cf * CFrame.new(0, 0.05, 0), Color3.fromRGB(130, 24, 40), Enum.Material.Fabric, false)
	box(ctx, "CarpetTrim", Vector3.new(7.6, 0.08, 12.6), cf * CFrame.new(0, 0.03, 0), Color3.fromRGB(210, 170, 70), Enum.Material.Fabric, false)
	p.CanQuery = false
end
P.painting = function(ctx, th, cf, rng)
	local frame = Color3.fromRGB(200, 160, 70)
	box(ctx, "Frame", Vector3.new(5, 6, 0.3), cf * CFrame.new(0, 8, 0), frame, Enum.Material.Metal, false)
	local hues = {Color3.fromRGB(90, 30, 40), Color3.fromRGB(40, 50, 80), Color3.fromRGB(50, 70, 50)}
	box(ctx, "Canvas", Vector3.new(4.2, 5.2, 0.35), cf * CFrame.new(0, 8, 0.05), hues[rng:NextInteger(1, 3)], Enum.Material.Fabric, false)
	K.ball(ctx, "Portrait", 1.8, cf * CFrame.new(0, 8.6, 0.1), Color3.fromRGB(220, 200, 180), Enum.Material.Fabric, ctx.Props).CanCollide = false
end
P.bookcase = function(ctx, th, cf, rng)
	local wood = Color3.fromRGB(80, 50, 32)
	box(ctx, "Bookcase", Vector3.new(6, 9, 1.6), cf * CFrame.new(0, 4.5, 0), wood, Enum.Material.Wood)
	for row = 0, 3 do
		local x = -2.6
		while x < 2.4 do
			local w = rng:NextNumber(0.3, 0.6)
			box(ctx, "Book", Vector3.new(w, rng:NextNumber(1.1, 1.6), 1.2), cf * CFrame.new(x + w / 2, 1.3 + row * 2.1, -0.3), Color3.fromHSV(rng:NextNumber(), 0.5, 0.5), Enum.Material.Fabric, false)
			x += w + 0.05
		end
	end
end
P.chandelier = function(ctx, th, cf)
	local gold = Color3.fromRGB(210, 170, 80)
	local at = cf * CFrame.new(0, WALL_H - 5, 0)
	K.cyl(ctx, "Chain", 0.2, 4, at * CFrame.new(0, 3, 0), gold, Enum.Material.Metal, ctx.Props).CanCollide = false
	K.cyl(ctx, "Ring", 5, 0.4, at, gold, Enum.Material.Metal, ctx.Props).CanCollide = false
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local f = K.ball(ctx, "Flame", 0.4, at * CFrame.new(math.cos(a) * 2.3, 0.6, math.sin(a) * 2.3), Color3.fromRGB(255, 200, 120), Enum.Material.Neon, ctx.Props)
		f.CanCollide = false
	end
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 200, 130); l.Range = 22; l.Brightness = 1.4
	l.Parent = ctx.Props:GetChildren()[#ctx.Props:GetChildren()]
end
P.table = function(ctx, th, cf)
	local wood = Color3.fromRGB(96, 64, 40)
	box(ctx, "Table", Vector3.new(8, 0.5, 3.5), cf * CFrame.new(0, 3, 0), wood, Enum.Material.WoodPlanks)
	for _, x in ipairs({-3.5, 3.5}) do for _, z in ipairs({-1.3, 1.3}) do box(ctx, "Leg", Vector3.new(0.4, 3, 0.4), cf * CFrame.new(x, 1.5, z), wood, Enum.Material.Wood) end end
	K.cyl(ctx, "Plate", 1, 0.1, cf * CFrame.new(-2, 3.3, 0), Color3.fromRGB(220, 220, 220), Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
	K.cyl(ctx, "Goblet", 0.4, 0.8, cf * CFrame.new(1, 3.65, 0.3), Color3.fromRGB(210, 170, 80), Enum.Material.Metal, ctx.Props).CanCollide = false
end
P.icicle = function(ctx, th, cf, rng)
	for i = 1, 5 do
		local h = rng:NextNumber(2, 5)
		local p = K.wedge(ctx, "Icicle", Vector3.new(0.6, h, 0.6), cf * CFrame.new(rng:NextNumber(-3, 3), WALL_H - h / 2, rng:NextNumber(-1, 1)) * CFrame.Angles(0, 0, math.pi), Color3.fromRGB(200, 236, 255), Enum.Material.Ice, ctx.Props)
		p.CanCollide = false; p.Transparency = 0.2
	end
end
P.snowpile = function(ctx, th, cf, rng)
	for i = 1, 3 do
		local s = rng:NextNumber(3, 6)
		local b = K.ball(ctx, "Snow", s, cf * CFrame.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)), Color3.fromRGB(240, 246, 255), Enum.Material.Snow, ctx.Props)
		b.Size = Vector3.new(s, s * 0.5, s)
	end
end
P.frozen = function(ctx, th, cf)
	P.statue(ctx, th, cf)
	local ice = box(ctx, "IceBlock", Vector3.new(4.5, 9, 4.5), cf * CFrame.new(0, 4.5, 0), Color3.fromRGB(170, 220, 255), Enum.Material.Glass)
	ice.Transparency = 0.45
end
P.crystal = function(ctx, th, cf, rng)
	for i = 1, 4 do
		local h = rng:NextNumber(2, 6)
		local p = box(ctx, "Crystal", Vector3.new(1, h, 1), cf * CFrame.new(rng:NextNumber(-1.5, 1.5), h / 2 - 0.4, rng:NextNumber(-1.5, 1.5)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)), th.accent, Enum.Material.Neon, false)
		p.Transparency = 0.15
		if i == 1 then local l = Instance.new("PointLight"); l.Color = th.accent; l.Range = 12; l.Brightness = 1; l.Parent = p end
	end
end
P.lava = function(ctx, th, cf)
	local p = box(ctx, "Lava", Vector3.new(8, 0.3, 6), cf * CFrame.new(0, 0.1, 0), Color3.fromRGB(255, 110, 30), Enum.Material.Neon, false)
	p.CanQuery = false
	box(ctx, "LavaRim", Vector3.new(9, 0.4, 7), cf * CFrame.new(0, 0.05, 0), Color3.fromRGB(40, 32, 30), Enum.Material.Basalt, false)
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 120, 40); l.Range = 18; l.Brightness = 1.5; l.Parent = p
	local pe = Instance.new("ParticleEmitter"); pe.Color = ColorSequence.new(Color3.fromRGB(255, 150, 50)); pe.LightEmission = 1; pe.Rate = 6
	pe.Speed = NumberRange.new(2, 5); pe.Lifetime = NumberRange.new(0.6, 1.2); pe.Size = NumberSequence.new(0.3, 0); pe.Parent = p
end
P.anvil = function(ctx, th, cf)
	local iron = Color3.fromRGB(56, 56, 60)
	box(ctx, "Stump", Vector3.new(2, 2, 2), cf * CFrame.new(0, 1, 0), Color3.fromRGB(80, 56, 36), Enum.Material.Wood)
	box(ctx, "Anvil", Vector3.new(1.4, 1, 3), cf * CFrame.new(0, 2.5, 0), iron, Enum.Material.Metal)
	K.wedge(ctx, "Horn", Vector3.new(1, 0.8, 1.2), cf * CFrame.new(0, 2.6, -2.1) * CFrame.Angles(0, math.pi, 0), iron, Enum.Material.Metal, ctx.Props)
	box(ctx, "Hammer", Vector3.new(0.3, 0.3, 2), cf * CFrame.new(0.3, 3.15, 0.5) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(90, 64, 40), Enum.Material.Wood, false)
end
P.chains = function(ctx, th, cf)
	for _, x in ipairs({-1.2, 1.2}) do
		for i = 0, 6 do
			box(ctx, "Link", Vector3.new(0.2, 0.9, 0.5), cf * CFrame.new(x, WALL_H - 1 - i * 0.85, 0) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0), Color3.fromRGB(70, 70, 74), Enum.Material.Metal, false)
		end
	end
end

-- room furniture by kind (on top of the theme's scattered props)
local function feature(ctx, th, room, cf)
	local kind = room.kind
	if kind == "shrine" then
		box(ctx, "AltarStep", Vector3.new(10, 0.8, 8), cf * CFrame.new(0, 0.4, 0), shade(th.trim, 0.9), mat(th.trimMat))
		box(ctx, "Altar", Vector3.new(5, 3, 3), cf * CFrame.new(0, 2.3, 0), Color3.fromRGB(200, 196, 186), Enum.Material.Marble)
		local orb = K.ball(ctx, "ShrineOrb", 2.2, cf * CFrame.new(0, 5.2, 0), Color3.fromRGB(255, 226, 140), Enum.Material.Neon, ctx.Props)
		orb.CanCollide = false
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 220, 140); l.Range = 24; l.Brightness = 2; l.Parent = orb
		for _, x in ipairs({-4, 4}) do P.candles(ctx, th, cf * CFrame.new(x, 0.8, 2.5), Random.new(room.id)) end
	elseif kind == "fountain" then
		K.cyl(ctx, "Basin", 12, 1.6, cf * CFrame.new(0, 0.8, 0), shade(th.trim, 1.1), Enum.Material.Marble, ctx.Props)
		local water = K.cyl(ctx, "Water", 10.6, 0.3, cf * CFrame.new(0, 1.55, 0), Color3.fromRGB(110, 230, 200), Enum.Material.Neon, ctx.Props)
		water.CanCollide = false; water.Transparency = 0.25
		K.cyl(ctx, "Spout", 1.6, 5, cf * CFrame.new(0, 3, 0), shade(th.trim, 1.1), Enum.Material.Marble, ctx.Props)
		local top = K.ball(ctx, "SpoutTop", 2, cf * CFrame.new(0, 5.6, 0), Color3.fromRGB(150, 255, 220), Enum.Material.Neon, ctx.Props)
		top.CanCollide = false
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(120, 255, 210); l.Range = 22; l.Brightness = 1.6; l.Parent = top
		local pe = Instance.new("ParticleEmitter"); pe.Color = ColorSequence.new(Color3.fromRGB(170, 255, 230)); pe.LightEmission = 0.8; pe.Rate = 18
		pe.Speed = NumberRange.new(4, 7); pe.SpreadAngle = Vector2.new(25, 25); pe.Acceleration = Vector3.new(0, -14, 0)
		pe.Lifetime = NumberRange.new(0.7, 1); pe.Size = NumberSequence.new(0.3, 0.1); pe.Parent = top
	elseif kind == "stairs" or kind == "exit" then
		-- an archway of the theme's stone round a glowing way down (or, an exit: a portal)
		local glow = kind == "exit" and Color3.fromRGB(90, 170, 255) or th.accent
		for _, x in ipairs({-4, 4}) do box(ctx, "ArchPost", Vector3.new(2, 11, 2), cf * CFrame.new(x, 5.5, 0), th.trim, mat(th.trimMat)) end
		box(ctx, "ArchTop", Vector3.new(10, 2, 2), cf * CFrame.new(0, 12, 0), th.trim, mat(th.trimMat))
		local portal = box(ctx, kind == "exit" and "ExitPortal" or "StairsGlow", Vector3.new(6, 10, 0.4), cf * CFrame.new(0, 5.5, 0), glow, Enum.Material.Neon, false)
		portal.Transparency = 0.35
		local l = Instance.new("PointLight"); l.Color = glow; l.Range = 24; l.Brightness = 2; l.Parent = portal
		local pe = Instance.new("ParticleEmitter"); pe.Color = ColorSequence.new(glow); pe.LightEmission = 1; pe.Rate = 20
		pe.Speed = NumberRange.new(1, 3); pe.Lifetime = NumberRange.new(1, 1.5); pe.Size = NumberSequence.new(0.4, 0); pe.Parent = portal
		if kind == "stairs" then
			for i = 1, 4 do box(ctx, "Step", Vector3.new(6, 0.4, 1.4), cf * CFrame.new(0, 0.2 - i * 0.05, 1.2 + i * 1.3), shade(th.floor, 0.6 - i * 0.08), mat(th.floorMat), false) end
		end
		portal.Name = kind == "exit" and "ExitPortal" or "StairsGlow"
	elseif kind == "boss" then
		-- a dais under the boss, a ring of runes, braziers round it
		K.cyl(ctx, "Dais", 22, 1.2, cf * CFrame.new(0, 0.6, 0), shade(th.trim, 0.9), mat(th.trimMat), ctx.Props)
		K.cyl(ctx, "DaisTop", 18, 1.4, cf * CFrame.new(0, 0.7, 0), shade(th.floor, 0.9), mat(th.floorMat), ctx.Props)
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			local r = box(ctx, "Rune", Vector3.new(1.6, 0.1, 0.5), cf * CFrame.new(math.cos(a) * 7.5, 1.42, math.sin(a) * 7.5) * CFrame.Angles(0, -a, 0), th.accent, Enum.Material.Neon, false)
			r.CanQuery = false
		end
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2 + math.pi / 4
			P.brazier(ctx, th, cf * CFrame.new(math.cos(a) * 16, 0, math.sin(a) * 16))
		end
	elseif kind == "treasure" then
		box(ctx, "Dais", Vector3.new(8, 0.8, 6), cf * CFrame.new(0, 0.4, 0), shade(th.trim, 0.9), mat(th.trimMat))
		P.goldpile(ctx, th, cf * CFrame.new(-6, 0, 2), Random.new(room.id))
		P.goldpile(ctx, th, cf * CFrame.new(6, 0, 1), Random.new(room.id + 7))
	elseif kind == "start" then
		P.brazier(ctx, th, cf)
		for _, x in ipairs({-8, 8}) do P.banner(ctx, th, cf * CFrame.new(x, 0, (room.d / 2) - 0.6)) end
	end
end

-- a portcullis in a doorway (Map ▸ Gates ▸ name); raised: up inside the lintel
local function gate(ctx, gatesFolder, name, pos, axis, th)
	local m = Instance.new("Model")
	m.Name = name
	local root = Instance.new("Part")
	root.Name = "GateRoot"
	root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch, root.Transparency = true, false, false, false, 1
	root.Size = Vector3.new(1, 1, 1)
	local up = DOOR_H + 0.4
	root.CFrame = CFrame.new(pos + Vector3.new(0, up + DOOR_H / 2, 0)) * (axis == "x" and CFrame.new() or CFrame.Angles(0, math.pi / 2, 0))
	root.Parent = m
	local iron = Color3.fromRGB(46, 44, 48)
	local function bar(size, off)
		local p = Instance.new("Part")
		p.Name = "Bar"
		p.Size, p.Color, p.Material = size, iron, Enum.Material.Metal
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = false, false, true, false
		p.Massless = true
		p.CFrame = root.CFrame * off
		local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = p; w.Parent = p
		p.Parent = m
	end
	for i = -5, 5, 1.25 do bar(Vector3.new(0.35, DOOR_H, 0.35), CFrame.new(i, 0, 0)) end
	for _, y in ipairs({-DOOR_H / 2 + 1.5, 0, DOOR_H / 2 - 1.5}) do bar(Vector3.new(DOOR_W, 0.35, 0.3), CFrame.new(0, y, 0)) end
	-- a spike row at its foot
	for i = -5, 5, 1.25 do
		local p = Instance.new("WedgePart")
		p.Size = Vector3.new(0.35, 0.8, 0.35); p.Color = iron; p.Material = Enum.Material.Metal
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
		p.CFrame = root.CFrame * CFrame.new(i, -DOOR_H / 2 - 0.4, 0) * CFrame.Angles(0, 0, math.pi)
		local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = p; w.Parent = p
		p.Parent = m
	end
	-- the solid that actually shuts it (switched on with the drop)
	local block = Instance.new("Part")
	block.Name = "Blocker"
	block.Anchored, block.CanCollide, block.CanQuery, block.CanTouch, block.Transparency = true, false, false, false, 1
	block.Size = Vector3.new(DOOR_W, DOOR_H, 1.2)
	block.CFrame = CFrame.new(pos + Vector3.new(0, DOOR_H / 2, 0)) * (axis == "x" and CFrame.new() or CFrame.Angles(0, math.pi / 2, 0))
	block.Parent = m
	m:SetAttribute("Down", false)
	m.PrimaryPart = root
	m.Parent = gatesFolder
	return m
end

-- shut (true) or open (false) a gate of the loaded map
function Dungeon.setGate(gateModel, down)
	if not gateModel or gateModel:GetAttribute("Down") == down then return end
	gateModel:SetAttribute("Down", down)
	local root = gateModel:FindFirstChild("GateRoot")
	local block = gateModel:FindFirstChild("Blocker")
	if not (root and block) then return end
	local target = down and (block.CFrame) or (block.CFrame * CFrame.new(0, DOOR_H + 0.4, 0))
	TweenService:Create(root, TweenInfo.new(down and 0.35 or 1.1, down and Enum.EasingStyle.Quad or Enum.EasingStyle.Sine, Enum.EasingDirection.In), {CFrame = target}):Play()
	block.CanCollide = down
	if down then
		local s = Instance.new("Sound")
		s.SoundId = "rbxasset://sounds/clickfast.wav"
		s.Volume = 0.6
		s.Parent = root
		s:Play()
		game:GetService("Debris"):AddItem(s, 2)
	end
end

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
function Dungeon.build(themeKey, opts)
	opts = opts or {}
	local th = Catalog.DUNGEONS[themeKey] or Catalog.DUNGEONS.BoneCrypt
	local seed = opts.seed or math.random(1, 2 ^ 30)
	local rng = Random.new(seed)
	made += 1
	local name = opts.name or ("Gen_" .. made)
	local list, W, H, order = plan(opts, rng)
	local finalId, exits = kinds(list, order, opts, rng)
	local ctx = K.new(name)
	local gatesFolder = Instance.new("Folder"); gatesFolder.Name = "Gates"; gatesFolder.Parent = ctx.model
	local roomsFolder = Instance.new("Folder"); roomsFolder.Name = "Rooms"; roomsFolder.Parent = ctx.model

	-- each room's size and place
	for _, r in ipairs(list) do
		r.cx = (r.gx - (W - 1) / 2) * CELL
		r.cz = (r.gy - (H - 1) / 2) * CELL
		local big = r.kind == "boss" and 70 or (r.kind == "elite" and 52 or (r.kind == "start" and 40 or nil))
		r.w = big or (rng:NextInteger(17, 25) * 2)
		r.d = big or (rng:NextInteger(17, 25) * 2)
		r.spots, r.gates = {}, {}
	end

	local floorC, floorM = th.floor, mat(th.floorMat)
	for _, r in ipairs(list) do
		local c = Vector3.new(r.cx, 0, r.cz)
		local fw, fd = r.w + T * 2, r.d + T * 2
		-- floor, with a border of the trim and a few darker flags
		K.box(ctx, "Floor", Vector3.new(fw, 1, fd), CFrame.new(c + Vector3.new(0, -0.5, 0)), floorC, floorM)
		for _ = 1, 4 do
			local s = rng:NextInteger(6, 12)
			local p = K.box(ctx, "Flag", Vector3.new(s, 0.06, s), CFrame.new(c + Vector3.new(rng:NextNumber(-r.w / 2 + s, r.w / 2 - s), 0.03, rng:NextNumber(-r.d / 2 + s, r.d / 2 - s))), shade(floorC, 0.82), floorM)
			p.CanCollide = false; p.CanQuery = false
		end
		-- the ceiling, its beams
		K.box(ctx, "Ceiling", Vector3.new(fw, 1, fd), CFrame.new(c + Vector3.new(0, WALL_H + 0.5, 0)), shade(th.wall, 0.6), mat(th.wallMat))
		for x = -r.w / 2 + 8, r.w / 2 - 8, 12 do
			K.box(ctx, "Beam", Vector3.new(1.4, 1.4, r.d), CFrame.new(c + Vector3.new(x, WALL_H - 0.7, 0)), th.trim, mat(th.trimMat)).CanCollide = false
		end
		-- the walls, a gap where a corridor comes in
		local gapsN, gapsS, gapsE, gapsW = {}, {}, {}, {}
		if r.doors.N then table.insert(gapsN, 0) end
		if r.doors.S then table.insert(gapsS, 0) end
		if r.doors.E then table.insert(gapsE, 0) end
		if r.doors.W then table.insert(gapsW, 0) end
		wallRun(ctx, th, c + Vector3.new(0, 0, -r.d / 2 - T / 2), "x", fw, WALL_H, gapsN)
		wallRun(ctx, th, c + Vector3.new(0, 0, r.d / 2 + T / 2), "x", fw, WALL_H, gapsS)
		wallRun(ctx, th, c + Vector3.new(r.w / 2 + T / 2, 0, 0), "z", r.d, WALL_H, gapsE)
		wallRun(ctx, th, c + Vector3.new(-r.w / 2 - T / 2, 0, 0), "z", r.d, WALL_H, gapsW)
		-- the baseboard, pillars at the corners
		for _, sx in ipairs({-1, 1}) do
			for _, sz in ipairs({-1, 1}) do
				K.box(ctx, "CornerPillar", Vector3.new(3, WALL_H, 3), CFrame.new(c + Vector3.new(sx * (r.w / 2 - 1.5), WALL_H / 2, sz * (r.d / 2 - 1.5))), th.trim, mat(th.trimMat))
			end
		end
		-- doorway frames, gates, torches
		for d, _ in pairs(r.doors) do
			local v = DIRS[d]
			local edge = Vector3.new(v[1] * (r.w / 2 + T / 2), 0, v[2] * (r.d / 2 + T / 2))
			local at = c + edge
			local axis = (d == "N" or d == "S") and "x" or "z"
			local side = axis == "x" and Vector3.new(1, 0, 0) or Vector3.new(0, 0, 1)
			for _, s in ipairs({-1, 1}) do
				K.box(ctx, "DoorFrame", Vector3.new(axis == "x" and 1.6 or T + 1.2, DOOR_H + 1, axis == "x" and T + 1.2 or 1.6), CFrame.new(at + side * s * (DOOR_W / 2 + 0.8) + Vector3.new(0, (DOOR_H + 1) / 2, 0)), th.trim, mat(th.trimMat))
			end
			K.box(ctx, "Keystone", Vector3.new(axis == "x" and DOOR_W + 3.2 or T + 1.2, 1.4, axis == "x" and T + 1.2 or DOOR_W + 3.2), CFrame.new(at + Vector3.new(0, DOOR_H + 0.7, 0)), th.trim, mat(th.trimMat))
			local gname = string.format("G%d_%s", r.id, d)
			gate(ctx, gatesFolder, gname, at, axis, th)
			table.insert(r.gates, gname)
		end
		-- sconces on the walls (clear of doorways)
		local inward = {N = Vector3.new(0, 0, 1), S = Vector3.new(0, 0, -1), E = Vector3.new(-1, 0, 0), W = Vector3.new(1, 0, 0)}
		for d, v in pairs(DIRS) do
			local along = (d == "N" or d == "S") and r.w or r.d
			for _, f in ipairs({-0.3, 0.3}) do
				local off = f * along
				if not (r.doors[d] and math.abs(off) < DOOR_W) then
					local pos
					if d == "N" or d == "S" then pos = c + Vector3.new(off, 8, v[2] * (r.d / 2 - 0.2))
					else pos = c + Vector3.new(v[1] * (r.w / 2 - 0.2), 8, off) end
					sconce(ctx, th, pos, inward[d])
				end
			end
		end
		-- the room's feature at its middle (the boss's dais, an altar…)
		local mid = CFrame.new(c)
		if r.kind ~= "combat" and r.kind ~= "elite" then feature(ctx, th, r, mid) end
		r.feature = c + Vector3.new(0, 0.5, 0)
		-- scattered props, kept off the middle and out of the doorways
		local nProps = (r.kind == "boss") and 6 or rng:NextInteger(3, 6)
		local placed = {}
		for _ = 1, nProps * 4 do
			if #placed >= nProps then break end
			local x = rng:NextNumber(-r.w / 2 + 5, r.w / 2 - 5)
			local z = rng:NextNumber(-r.d / 2 + 5, r.d / 2 - 5)
			local p = c + Vector3.new(x, 0, z)
			local ok = Vector3.new(x, 0, z).Magnitude > (r.kind == "boss" and 20 or 11)
			for d2 in pairs(r.doors) do
				local v = DIRS[d2]
				local door = c + Vector3.new(v[1] * r.w / 2, 0, v[2] * r.d / 2)
				if (door - p).Magnitude < 10 then ok = false end
			end
			for _, q in ipairs(placed) do if (q - p).Magnitude < 7 then ok = false end end
			if ok then
				-- a wall prop (a banner, a painting, a bookcase, chains) goes to the nearest wall
				local kind = th.props[rng:NextInteger(1, #th.props)]
				local fn = P[kind]
				if fn then
					local cf
					if kind == "banner" or kind == "painting" or kind == "bookcase" or kind == "cobweb" or kind == "chains" then
						local dx, dz = r.w / 2 - math.abs(x), r.d / 2 - math.abs(z)
						if dx < dz then cf = CFrame.lookAt(Vector3.new(c.X + math.sign(x) * (r.w / 2 - 1), 0, p.Z), Vector3.new(c.X, 0, p.Z))
						else cf = CFrame.lookAt(Vector3.new(p.X, 0, c.Z + math.sign(z) * (r.d / 2 - 1)), Vector3.new(p.X, 0, c.Z)) end
					else
						cf = CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
					end
					local okP, err = pcall(fn, ctx, th, cf, rng)
					if not okP then warn("[Dungeon] prop", kind, err) end
					table.insert(placed, p)
				end
			end
		end
		-- where monsters stand: spread about the room, away from its doors
		local n = r.kind == "boss" and 10 or 8
		for i = 1, n do
			local a = (i / n) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
			local rad = rng:NextNumber(0.3, 0.42)
			table.insert(r.spots, c + Vector3.new(math.cos(a) * r.w * rad, 3, math.sin(a) * r.d * rad))
		end
		-- a chest: against the far wall from where you came in (else the middle)
		r.chest = c + Vector3.new(0, 0, 0)
		if r.kind == "treasure" or r.kind == "boss" then r.chest = c + Vector3.new(0, 0.8, 0) end
		-- the room's bounds (the mode tells who's inside)
		local b = Instance.new("Part")
		b.Name = "Room" .. r.id
		b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch, b.Transparency = true, false, false, false, 1
		b.Size = Vector3.new(r.w, WALL_H, r.d)
		b.CFrame = CFrame.new(c + Vector3.new(0, WALL_H / 2, 0))
		b:SetAttribute("RoomId", r.id); b:SetAttribute("Kind", r.kind); b:SetAttribute("Depth", r.depth)
		b.Parent = roomsFolder
	end

	-- corridors (each joined pair once)
	for _, r in ipairs(list) do
		for d, nid in pairs(r.doors) do
			if d == "E" or d == "S" then
				local o = list[nid]
				local c
				if d == "E" then
					local x0, x1 = r.cx + r.w / 2 + T, o.cx - o.w / 2 - T
					local len = x1 - x0
					local mid = Vector3.new((x0 + x1) / 2, 0, r.cz)
					K.box(ctx, "CorridorFloor", Vector3.new(len + T * 2 + 0.2, 1, DOOR_W + T * 2), CFrame.new(mid + Vector3.new(0, -0.5, 0)), shade(floorC, 0.9), floorM)
					K.box(ctx, "CorridorCeiling", Vector3.new(len + 0.2, 1, DOOR_W + T * 2), CFrame.new(mid + Vector3.new(0, CORR_H + 0.5, 0)), shade(th.wall, 0.55), mat(th.wallMat))
					for _, s in ipairs({-1, 1}) do
						K.box(ctx, "CorridorWall", Vector3.new(len + 0.2, CORR_H, T), CFrame.new(mid + Vector3.new(0, CORR_H / 2, s * (DOOR_W / 2 + T / 2))), shade(th.wall, 0.92), mat(th.wallMat))
					end
					c = mid
					if len > 18 then sconce(ctx, th, mid + Vector3.new(0, 8, -DOOR_W / 2 + 0.2), Vector3.new(0, 0, 1)) end
				else
					local z0, z1 = r.cz + r.d / 2 + T, o.cz - o.d / 2 - T
					local len = z1 - z0
					local mid = Vector3.new(r.cx, 0, (z0 + z1) / 2)
					K.box(ctx, "CorridorFloor", Vector3.new(DOOR_W + T * 2, 1, len + T * 2 + 0.2), CFrame.new(mid + Vector3.new(0, -0.5, 0)), shade(floorC, 0.9), floorM)
					K.box(ctx, "CorridorCeiling", Vector3.new(DOOR_W + T * 2, 1, len + 0.2), CFrame.new(mid + Vector3.new(0, CORR_H + 0.5, 0)), shade(th.wall, 0.55), mat(th.wallMat))
					for _, s in ipairs({-1, 1}) do
						K.box(ctx, "CorridorWall", Vector3.new(T, CORR_H, len + 0.2), CFrame.new(mid + Vector3.new(s * (DOOR_W / 2 + T / 2), CORR_H / 2, 0)), shade(th.wall, 0.92), mat(th.wallMat))
					end
					c = mid
					if len > 18 then sconce(ctx, th, mid + Vector3.new(-DOOR_W / 2 + 0.2, 8, 0), Vector3.new(1, 0, 0)) end
				end
			end
		end
	end
	-- the room walls' lintels reach up to the room ceiling; above a corridor's ceiling is the room's own wall: closed

	-- the start: spawns round its middle, the menu's shot
	local s = list[1]
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		K.spawn(ctx, Vector3.new(s.cx + math.cos(a) * 9, 1, s.cz + math.sin(a) * 9), nil, Vector3.new(s.cx, 1, s.cz))
	end
	local fin = finalId and list[finalId] or s
	K.camera(ctx, Vector3.new(s.cx + s.w * 0.35, 12, s.cz + s.d * 0.35), Vector3.new(s.cx, 3, s.cz))
	K.camera(ctx, Vector3.new(fin.cx - fin.w * 0.4, 14, fin.cz - fin.d * 0.4), Vector3.new(fin.cx, 4, fin.cz))
	K.lighting(ctx, th.light)
	K.atmosphere(ctx, {Density = 0.32, Offset = 0, Color = th.light.FogColor, Decay = th.light.FogColor, Glare = 0, Haze = 1.5})
	ctx.model:SetAttribute("Theme", themeKey)
	ctx.model:SetAttribute("Generated", true)
	local okF, errF = pcall(K.finish, ctx)
	if not okF then
		warn("[Dungeon] finish:", errF)
		local maps = ServerStorage:FindFirstChild("Maps") or Instance.new("Folder")
		maps.Name = "Maps"; maps.Parent = ServerStorage
		ctx.model.Parent = maps
	end
	local layout = {rooms = list, start = 1, final = finalId, exits = exits, order = order, theme = themeKey, name = name, seed = seed, grid = {W, H}}
	return name, layout
end

-- every generated floor gone from ServerStorage ▸ Maps (but `keep`)
function Dungeon.sweep(keep)
	local maps = ServerStorage:FindFirstChild("Maps")
	for _, m in ipairs(maps and maps:GetChildren() or {}) do
		if m:GetAttribute("Generated") and m.Name ~= keep then m:Destroy() end
	end
end

-- which room a point is in (or nil: a corridor)
function Dungeon.roomAt(layout, pos)
	for _, r in ipairs(layout.rooms) do
		if math.abs(pos.X - r.cx) <= r.w / 2 + 0.5 and math.abs(pos.Z - r.cz) <= r.d / 2 + 0.5 then return r end
	end
	return nil
end

return Dungeon
