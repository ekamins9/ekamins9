--[[ DUNGEON — builds a dungeon floor from nothing, in a theme (ReplicatedStorage ▸ Catalog ▸
     Dungeons), for The Depths and Deadvault. Never the same twice.

       Dungeon.build(themeKey, opts) -> mapName, layout
         opts.rooms      how many rooms (8)
         opts.grid       {w, h} cells (4, 4); a cell is CELL studs
         opts.final      "boss" (the theme's boss in a great hall) · "stairs" (the way down) ·
                         "none"
         opts.special    {treasure = n, shrine = n, fountain = n, elite = n} (1, 1, 1, 1)
         opts.exits      n extraction rooms (Deadvault: kind "exit", far from the start)
         opts.havens     n more ways in (kind "start", r.haven: Deadvault's raiders come in apart)
         opts.raid       a raid's rooms (Deadvault): each was something (r.arch: hall crypt cells
                         library armory storeroom chapel cavern vault lair: furnished to match, its
                         own size and height r.h), with its CONTAINERS (r.containers = {{kind, cf}});
                         fewer torches; an exit is stairs up to a door of daylight (r.escape)
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
if not K.campfire then require(ServerScriptService.Build:WaitForChild("MapProps"))(K) end   -- (a cavern's camp: Build ▸ MapProps)

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
	-- HAVENS (a raid's other ways in): far from the start, from each other and from the exits
	for _ = 1, (opts.havens or 0) do
		local best, bestScore
		for _, r in ipairs(list) do
			if not r.kind then
				local s = math.huge
				for _, o in ipairs(list) do
					if o.kind == "start" or o.kind == "exit" then s = math.min(s, (math.abs(o.gx - r.gx) + math.abs(o.gy - r.gy)) * (o.kind == "exit" and 0.8 or 1)) end
				end
				s += rng:NextNumber() * 0.5
				if not bestScore or s > bestScore then best, bestScore = r, s end
			end
		end
		if best then best.kind = "start"; best.haven = true end
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
	local l = Instance.new("PointLight"); l.Name = "Flicker"; l.Color = th.torch; l.Range = 18; l.Brightness = 1.5; l.Shadows = true; l.Parent = flame
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
-- a cobweb: a pale triangle strung across where the wall meets the ceiling (cf: 1 stud out from the wall)
P.cobweb = function(ctx, th, cf, rng)
	local H = ctx.H or WALL_H
	local s = rng and rng:NextNumber(3, 5.5) or 4.5
	local p = K.wedge(ctx, "Cobweb", Vector3.new(0.05, s, s), cf * CFrame.new(rng and rng:NextNumber(-1, 1) or 0, H - s / 2 - 0.05, 1 - s / 2) * CFrame.Angles(0, 0, math.pi), Color3.fromRGB(226, 226, 226), Enum.Material.Fabric, ctx.Props)
	p.Transparency = 0.62
	p.CanCollide, p.CanQuery, p.CastShadow = false, false, false
end
P.candles = function(ctx, th, cf, rng)
	for i = 1, 4 do
		local h = rng:NextNumber(0.6, 1.6)
		local at = cf * CFrame.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
		K.cyl(ctx, "Candle", 0.35, h, at * CFrame.new(0, h / 2, 0), Color3.fromRGB(236, 228, 200), Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
		local f = K.ball(ctx, "Flame", 0.25, at * CFrame.new(0, h + 0.15, 0), Color3.fromRGB(255, 200, 110), Enum.Material.Neon, ctx.Props)
		f.CanCollide = false
		if i == 1 then local l = Instance.new("PointLight"); l.Name = "Flicker"; l.Color = Color3.fromRGB(255, 190, 110); l.Range = 9; l.Brightness = 1; l.Parent = f end
	end
end
P.pillar = function(ctx, th, cf)
	local H = ctx.H or WALL_H
	K.cyl(ctx, "Pillar", 3, H, cf * CFrame.new(0, H / 2, 0), th.trim, mat(th.trimMat))
	box(ctx, "PillarBase", Vector3.new(4, 1.2, 4), cf * CFrame.new(0, 0.6, 0), shade(th.trim, 0.85), mat(th.trimMat))
	box(ctx, "PillarCap", Vector3.new(4, 1, 4), cf * CFrame.new(0, H - 0.5, 0), shade(th.trim, 0.85), mat(th.trimMat))
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
	local l = Instance.new("PointLight"); l.Name = "Flicker"; l.Color = th.torch; l.Range = 20; l.Brightness = 1.6; l.Parent = coal
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
	local H = ctx.H or WALL_H
	local p = box(ctx, "Banner", Vector3.new(4, 9, 0.12), cf * CFrame.new(0, H - 7.5, 0), shade(c, 0.55), Enum.Material.Fabric, false)
	box(ctx, "BannerStripe", Vector3.new(1, 9, 0.14), p.CFrame, shade(c, 0.9), Enum.Material.Fabric, false)
	box(ctx, "BannerRod", Vector3.new(5, 0.4, 0.4), cf * CFrame.new(0, H - 2.8, 0), Color3.fromRGB(60, 50, 40), Enum.Material.Wood, false)
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
	local at = cf * CFrame.new(0, (ctx.H or WALL_H) - 5, 0)
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
		local p = K.wedge(ctx, "Icicle", Vector3.new(0.6, h, 0.6), cf * CFrame.new(rng:NextNumber(-3, 3), (ctx.H or WALL_H) - h / 2, rng:NextNumber(-1, 1)) * CFrame.Angles(0, 0, math.pi), Color3.fromRGB(200, 236, 255), Enum.Material.Ice, ctx.Props)
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
			box(ctx, "Link", Vector3.new(0.2, 0.9, 0.5), cf * CFrame.new(x, (ctx.H or WALL_H) - 1 - i * 0.85, 0) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0), Color3.fromRGB(70, 70, 74), Enum.Material.Metal, false)
		end
	end
end

P.cage = function(ctx, th, cf, rng)
	local iron = Color3.fromRGB(52, 50, 54)
	local H = ctx.H or WALL_H
	local hang = rng:NextNumber(3, 6)
	local top = cf * CFrame.new(0, H - hang, 0)
	K.cyl(ctx, "CageChain", 0.18, hang, cf * CFrame.new(0, H - hang / 2, 0), iron, Enum.Material.Metal, ctx.Props).CanCollide = false
	K.cyl(ctx, "CageTop", 3.2, 0.3, top, iron, Enum.Material.Metal, ctx.Props).CanCollide = false
	K.cyl(ctx, "CageFloor", 3.2, 0.3, top * CFrame.new(0, -4.2, 0), iron, Enum.Material.Metal, ctx.Props).CanCollide = false
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		box(ctx, "CageBar", Vector3.new(0.14, 4.2, 0.14), top * CFrame.new(math.cos(a) * 1.5, -2.1, math.sin(a) * 1.5), iron, Enum.Material.Metal, false).CanQuery = false
	end
	if rng:NextNumber() < 0.6 then
		K.ball(ctx, "Skull", 0.8, top * CFrame.new(0.4, -3.7, 0.2), BONE, Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
		box(ctx, "Bone", Vector3.new(0.25, 0.25, 1.6), top * CFrame.new(-0.3, -3.95, -0.2) * CFrame.Angles(0, 0.7, 0), BONE, Enum.Material.SmoothPlastic, false).CanQuery = false
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

--------------------------------------------------------------------
--  RAID ROOMS (opts.raid: Deadvault). A room was something before the dark took it — a great
--  hall, a crypt, the cells, a library, an armoury, a storeroom, a chapel, a cavern, a vault —
--  furnished to match, and it says where its CONTAINERS stand: r.containers = {{kind, cf}}
--  (the mode builds them: crate barrel sack urn rack stand shelf coffin remains chest ornate hoard)
--------------------------------------------------------------------
local ARCH_W = {   -- by theme: which rooms its dungeon has, by weight
	BoneCrypt = {crypt = 4, hall = 2, cells = 2, chapel = 2, library = 1, storeroom = 2, armory = 1},
	GoblinWarrens = {cavern = 4, storeroom = 3, cells = 1, armory = 2, hall = 1},
	CrimsonManor = {hall = 3, library = 3, chapel = 2, cells = 1, storeroom = 2, armory = 1},
	FrozenDepths = {cavern = 3, crypt = 2, hall = 2, armory = 1, storeroom = 2},
	EmberForge = {armory = 3, storeroom = 2, hall = 2, cells = 1, cavern = 2},
}
local ARCH_ORDER = {"hall", "crypt", "cells", "library", "armory", "storeroom", "chapel", "cavern"}
-- the odd container by a raid room's walls, by theme
local RAID_ODDS = {BoneCrypt = {"urn", "urn", "crate", "sack"}, GoblinWarrens = {"sack", "sack", "crate", "barrel"},
	CrimsonManor = {"urn", "crate", "barrel"}, FrozenDepths = {"crate", "barrel", "sack"}, EmberForge = {"crate", "barrel", "barrel"}}
local ARCH_SIZE = {hall = {30, 36}, crypt = {19, 26}, cells = {21, 26}, library = {21, 27}, armory = {18, 24},
	storeroom = {14, 19}, chapel = {21, 27}, cavern = {20, 27}, vault = {18, 22}, lair = {33, 35}}   -- ×2 studs
local ARCH_H = {hall = 30, cavern = 26, chapel = 28, lair = 30}
Dungeon.ARCH_NAMES = {hall = "Great Hall", crypt = "Crypt", cells = "The Cells", library = "Library", armory = "Armoury",
	storeroom = "Storeroom", chapel = "Chapel", cavern = "Cavern", vault = "Treasure Vault", lair = "The Lair"}

local function weighted(rng, t)
	local total = 0
	for _, k in ipairs(ARCH_ORDER) do total += t[k] or 0 end
	local x = rng:NextNumber() * total
	for _, k in ipairs(ARCH_ORDER) do
		x -= t[k] or 0
		if x <= 0 and (t[k] or 0) > 0 then return k end
	end
	return "storeroom"
end

local INWARD = {N = Vector3.new(0, 0, 1), S = Vector3.new(0, 0, -1), E = Vector3.new(-1, 0, 0), W = Vector3.new(1, 0, 0)}
local DIR_LIST = {"N", "S", "E", "W"}
local function wallLen(r, d) return (d == "N" or d == "S") and r.w or r.d end
-- a frame on the floor by wall `d`, `inset` in from it and `u` along it, looking into the room
local function wallFrame(r, c, d, inset, u)
	local v = DIRS[d]
	local half = (d == "N" or d == "S") and r.d / 2 or r.w / 2
	local along = (d == "N" or d == "S") and Vector3.new(1, 0, 0) or Vector3.new(0, 0, 1)
	local p = c + Vector3.new(v[1], 0, v[2]) * (half - inset) + along * u
	return CFrame.lookAt(p, p + INWARD[d])
end
-- a wall with no doorway in it (shelves, cells, an altar go there), or nil
local function quietWall(r, rng)
	local free = {}
	for _, d in ipairs(DIR_LIST) do if not r.doors[d] then table.insert(free, d) end end
	if #free == 0 then return nil end
	return free[rng:NextInteger(1, #free)]
end
-- clear of every doorway's way in, and of `taken`
local function clearSpot(r, c, p, taken, gap)
	for d in pairs(r.doors) do
		local v = DIRS[d]
		local door = c + Vector3.new(v[1] * r.w / 2, 0, v[2] * r.d / 2)
		if (door - p).Magnitude < 10 then return false end
	end
	for _, q in ipairs(taken or {}) do if (q - p).Magnitude < (gap or 6) then return false end end
	return true
end
local function floorSpot(r, c, rng, taken, edge)
	for _ = 1, 20 do
		local p = c + Vector3.new(rng:NextNumber(-r.w / 2 + (edge or 5), r.w / 2 - (edge or 5)), 0, rng:NextNumber(-r.d / 2 + (edge or 5), r.d / 2 - (edge or 5)))
		if clearSpot(r, c, p, taken) then return p end
	end
	return nil
end
-- a room's long axis: at(u, v) with u along it, v across
local function axes(r, c)
	local long = r.w >= r.d
	local L, S = long and r.w or r.d, long and r.d or r.w
	return long, L, S, function(u, v) return long and (c + Vector3.new(u, 0, v)) or (c + Vector3.new(v, 0, u)) end
end

local A = {}
-- a GREAT HALL: two rows of pillars down its length, a runner, chandeliers, banners, braziers
A.hall = function(ctx, th, r, c, rng, keep)
	local long, L, S, at = axes(r, c)
	for u = -L / 2 + 9, L / 2 - 9, 11 do
		if math.abs(u) > 7 then for _, v in ipairs({-S / 2 + 9, S / 2 - 9}) do P.pillar(ctx, th, CFrame.new(at(u, v))) end end
	end
	local run = box(ctx, "Runner", long and Vector3.new(L - 14, 0.1, 6) or Vector3.new(6, 0.1, L - 14), CFrame.new(c + Vector3.new(0, 0.05, 0)), shade(th.accent, 0.3), Enum.Material.Fabric, false)
	run.CanQuery = false
	for _, u in ipairs({-L / 4, L / 4}) do P.chandelier(ctx, th, CFrame.new(at(u, 0))) end
	for _, d in ipairs(long and {"N", "S"} or {"E", "W"}) do
		for _, u in ipairs({-L / 3, L / 3}) do P.banner(ctx, th, wallFrame(r, c, d, 1, u)) end
	end
	P.brazier(ctx, th, CFrame.new(at(L / 2 - 6, S / 2 - 5)))
	P.brazier(ctx, th, CFrame.new(at(-L / 2 + 6, -S / 2 + 5)))
	keep("urn", CFrame.new(at(-L / 2 + 5.5, S / 2 - 5)))
	if rng:NextNumber() < 0.6 then keep("chest", CFrame.lookAt(at(L / 2 - 6, -S / 2 + 6), c)) else keep("urn", CFrame.new(at(L / 2 - 5.5, -S / 2 + 5))) end
end
-- a CRYPT: rows of sarcophagi (some to be opened), the dead stacked in niches along a wall
local function sarcophagus(ctx, th, cf)
	local stone = shade(th.trim, 1.35)
	box(ctx, "Sarcophagus", Vector3.new(3.4, 2.4, 7), cf * CFrame.new(0, 1.2, 0), stone, Enum.Material.Marble)
	box(ctx, "SarcLid", Vector3.new(3.8, 0.6, 7.4), cf * CFrame.new(0, 2.7, 0), shade(stone, 0.85), Enum.Material.Marble)
	box(ctx, "Effigy", Vector3.new(1.6, 0.5, 4.6), cf * CFrame.new(0, 3.2, 0.4), shade(stone, 1.08), Enum.Material.Marble)
	K.ball(ctx, "EffigyHead", 1.1, cf * CFrame.new(0, 3.45, -2.4), shade(stone, 1.08), Enum.Material.Marble, ctx.Props)
end
A.crypt = function(ctx, th, r, c, rng, keep)
	local long, L, S, at = axes(r, c)
	local yaw = long and CFrame.new() or CFrame.Angles(0, math.pi / 2, 0)
	for u = -L / 2 + 8, L / 2 - 8, 9 do
		if math.abs(u) > 6 then
			for _, v in ipairs({-S / 4 - 1, S / 4 + 1}) do
				local cf = CFrame.new(at(u, v)) * yaw
				if rng:NextNumber() < 0.3 then keep("coffin", cf) else sarcophagus(ctx, th, cf) end
			end
		end
	end
	local qw = quietWall(r, rng)
	if qw then
		local len = wallLen(r, qw)
		for u = -len / 2 + 6, len / 2 - 6, 5 do
			local f = wallFrame(r, c, qw, 1.2, u)
			for row = 0, 2 do
				box(ctx, "Niche", Vector3.new(4, 0.4, 2), f * CFrame.new(0, 3 + row * 3.2, 0), shade(th.wall, 0.7), mat(th.wallMat))
				local sk = K.ball(ctx, "Skull", 0.9, f * CFrame.new(rng:NextNumber(-1.2, 1.2), 3.65 + row * 3.2, 0), BONE, Enum.Material.SmoothPlastic, ctx.Props)
				sk.CanCollide = false
			end
		end
	end
	for _, s in ipairs({-1, 1}) do P.candles(ctx, th, CFrame.new(at(s * (L / 2 - 5), -s * (S / 2 - 4))), rng) end
	P.bones(ctx, th, CFrame.new(at(rng:NextNumber(-L / 3, L / 3), 0)), rng)
end
-- THE CELLS: barred cells along a wall (a few with what's left of their prisoners), the jailer's table
A.cells = function(ctx, th, r, c, rng, keep)
	local qw = quietWall(r, rng)
	if not qw then return A.storeroom(ctx, th, r, c, rng, keep) end
	local len = wallLen(r, qw)
	local n = math.max(2, math.floor((len - 8) / 10))
	local cw = (len - 8) / n
	local depth = 8
	local iron = Color3.fromRGB(56, 54, 58)
	for i = 1, n do
		local u0 = -len / 2 + 4 + (i - 1) * cw
		local um = u0 + cw / 2
		box(ctx, "CellWall", Vector3.new(1, 12, depth), wallFrame(r, c, qw, depth / 2, u0) * CFrame.new(0, 6, 0), shade(th.wall, 0.85), mat(th.wallMat))
		if i == n then box(ctx, "CellWall", Vector3.new(1, 12, depth), wallFrame(r, c, qw, depth / 2, u0 + cw) * CFrame.new(0, 6, 0), shade(th.wall, 0.85), mat(th.wallMat)) end
		for u = u0 + 0.7, u0 + cw - 0.7, 1.1 do
			if math.abs(u - um) > 2.3 then box(ctx, "CellBar", Vector3.new(0.3, 10, 0.3), wallFrame(r, c, qw, depth, u) * CFrame.new(0, 5, 0), iron, Enum.Material.Metal) end
		end
		box(ctx, "CellRail", Vector3.new(cw, 0.4, 0.4), wallFrame(r, c, qw, depth, um) * CFrame.new(0, 10, 0), iron, Enum.Material.Metal)
		box(ctx, "CellRail", Vector3.new(cw, 0.3, 0.3), wallFrame(r, c, qw, depth, um) * CFrame.new(0, 1, 0), iron, Enum.Material.Metal, false)
		local inside = wallFrame(r, c, qw, depth / 2, um)
		if rng:NextNumber() < 0.45 then keep("remains", inside) else P.bones(ctx, th, inside, rng) end
		for _, x in ipairs({-1.4, 1.4}) do
			for k = 0, 3 do box(ctx, "Link", Vector3.new(0.2, 0.9, 0.5), wallFrame(r, c, qw, 0.5, um + x) * CFrame.new(0, 8 - k * 0.85, 0) * CFrame.Angles(0, (k % 2) * math.pi / 2, 0), Color3.fromRGB(70, 70, 74), Enum.Material.Metal, false) end
		end
	end
	local far = OPP[qw]
	local flen = wallLen(r, far)
	P.table(ctx, th, wallFrame(r, c, far, 5, flen / 2 - 10))
	P.candles(ctx, th, wallFrame(r, c, far, 5, flen / 2 - 10) * CFrame.new(-2, 3.25, 0), rng)
	keep("crate", wallFrame(r, c, far, 3, -flen / 2 + 6))
end
-- a LIBRARY: aisles of shelves (some worth searching), reading tables, a chandelier
A.library = function(ctx, th, r, c, rng, keep)
	local long, L, S, at = axes(r, c)
	local rot = long and CFrame.Angles(0, math.pi / 2, 0) or CFrame.new()
	for u = -L / 2 + 9, L / 2 - 9, 7 do
		if math.abs(u) > 6 then
			for _, v in ipairs({-S / 4 - 1, S / 4 + 1}) do
				local cf = CFrame.new(at(u, v)) * rot
				if rng:NextNumber() < 0.2 then keep("shelf", cf) else P.bookcase(ctx, th, cf, rng) end
			end
		end
	end
	for _, s in ipairs({-1, 1}) do
		local cf = CFrame.new(at(s * (L / 2 - 7), s * (S / 2 - 5))) * (long and CFrame.new() or CFrame.Angles(0, math.pi / 2, 0))
		P.table(ctx, th, cf)
		P.candles(ctx, th, cf * CFrame.new(1.5, 3.25, 0), rng)
	end
	P.chandelier(ctx, th, CFrame.new(c))
	if rng:NextNumber() < 0.35 then keep("chest", CFrame.lookAt(at(-L / 2 + 5, S / 2 - 5), c)) end
end
-- an ARMOURY: racks along the walls (some with something left on them), stands, an anvil
A.armory = function(ctx, th, r, c, rng, keep)
	for _, d in ipairs(DIR_LIST) do
		local len = wallLen(r, d)
		for _, u in ipairs({-len / 2 + 7, len / 2 - 7}) do
			local f = wallFrame(r, c, d, 1.6, u)
			local x = rng:NextNumber()
			if x < 0.28 then keep("rack", f) elseif x < 0.42 then keep("stand", f) elseif x < 0.8 then K.rack(ctx, f) end
		end
	end
	P.anvil(ctx, th, CFrame.new(c + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
	local p = floorSpot(r, c, rng, {c}, 7)
	if p then P.crates(ctx, th, CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), rng) end
	local q = floorSpot(r, c, rng, {c, p}, 7)
	if q then keep("crate", CFrame.new(q) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)) end
	P.brazier(ctx, th, CFrame.new(c + Vector3.new(r.w / 2 - 6, 0, -r.d / 2 + 6)))
end
-- a STOREROOM: crates, barrels and sacks stacked everywhere
A.storeroom = function(ctx, th, r, c, rng, keep)
	for _, s1 in ipairs({-1, 1}) do
		for _, s2 in ipairs({-1, 1}) do
			local p = c + Vector3.new(s1 * (r.w / 2 - 5.5), 0, s2 * (r.d / 2 - 5.5))
			local x = rng:NextNumber()
			local spin = CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
			if x < 0.32 then keep("crate", CFrame.new(p) * spin)
			elseif x < 0.5 then keep("barrel", CFrame.new(p))
			elseif x < 0.66 then keep("sack", CFrame.new(p) * spin)
			else P.crates(ctx, th, CFrame.new(p) * spin, rng) end
		end
	end
	local taken = {c}
	for _ = 1, 3 do
		local p = floorSpot(r, c, rng, taken, 6)
		if p then
			table.insert(taken, p)
			if rng:NextNumber() < 0.5 then P.barrel(ctx, th, CFrame.new(p)) else P.crates(ctx, th, CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), rng) end
		end
	end
end
-- a CHAPEL: an altar under coloured glass, statues, pews facing it, an aisle up the middle
A.chapel = function(ctx, th, r, c, rng, keep)
	local qw = quietWall(r, rng)
	if not qw then return A.hall(ctx, th, r, c, rng, keep) end
	local len = wallLen(r, qw)
	local deep = (qw == "N" or qw == "S") and r.d or r.w
	local alt = wallFrame(r, c, qw, 4, 0)
	box(ctx, "AltarStep", Vector3.new(12, 0.8, 7), alt * CFrame.new(0, 0.4, 0), shade(th.trim, 0.9), mat(th.trimMat))
	box(ctx, "Altar", Vector3.new(6, 3, 2.6), alt * CFrame.new(0, 2.3, 0), Color3.fromRGB(200, 196, 186), Enum.Material.Marble)
	box(ctx, "AltarCloth", Vector3.new(6.2, 0.1, 2.8), alt * CFrame.new(0, 3.85, 0), shade(th.accent, 0.5), Enum.Material.Fabric, false)
	P.candles(ctx, th, alt * CFrame.new(-1.8, 3.85, 0), rng)
	for _, x in ipairs({-8, 8}) do P.statue(ctx, th, alt * CFrame.new(x, 0, -1)) end
	local glass = box(ctx, "StainedGlass", Vector3.new(7, 10, 0.3), wallFrame(r, c, qw, 0.4, 0) * CFrame.new(0, 15, 0), th.accent, Enum.Material.Neon, false)
	glass.Transparency = 0.35
	local gl = Instance.new("PointLight"); gl.Color = th.accent; gl.Range = 26; gl.Brightness = 1.2; gl.Parent = glass
	local wood = Color3.fromRGB(86, 58, 36)
	local sideDoor = r.doors[(qw == "N" or qw == "S") and "E" or "N"] or r.doors[(qw == "N" or qw == "S") and "W" or "S"]
	for k = 1, math.floor((deep - 18) / 5) do
		local dist = 12 + k * 5
		if not (sideDoor and math.abs(dist - deep / 2) < 7) then
			for _, s in ipairs({-1, 1}) do
				local f = wallFrame(r, c, qw, dist, s * (len / 4 + 1.5))
				box(ctx, "Pew", Vector3.new(len / 2 - 9, 0.5, 1.6), f * CFrame.new(0, 1.6, 0), wood, Enum.Material.WoodPlanks)
				box(ctx, "PewBack", Vector3.new(len / 2 - 9, 2.4, 0.4), f * CFrame.new(0, 2.6, 0.9), wood, Enum.Material.WoodPlanks)
				for _, x in ipairs({-(len / 4 - 5), len / 4 - 5}) do box(ctx, "PewLeg", Vector3.new(0.4, 1.4, 1.4), f * CFrame.new(x, 0.7, 0), shade(wood, 0.8), Enum.Material.Wood) end
			end
		end
	end
	keep("urn", wallFrame(r, c, qw, 3, -len / 2 + 5))
	keep("urn", wallFrame(r, c, qw, 3, len / 2 - 5))
	if rng:NextNumber() < 0.5 then keep("chest", alt * CFrame.new(0, 0, -5.5) * CFrame.Angles(0, math.pi, 0)) end
end
-- a CAVERN: the walls fall in rough rock, stalagmites, the theme's growths, someone's old camp
A.cavern = function(ctx, th, r, c, rng, keep)
	for _ = 1, 16 do
		local d = DIR_LIST[rng:NextInteger(1, 4)]
		local len = wallLen(r, d)
		local u = rng:NextNumber(-len / 2 + 3, len / 2 - 3)
		if not (r.doors[d] and math.abs(u) < 10) then
			K.rock(ctx, wallFrame(r, c, d, rng:NextNumber(2, 4), u).Position, rng:NextNumber(3, 7), shade(th.wall, rng:NextNumber(0.7, 1)))
		end
	end
	local taken = {}
	for _ = 1, 6 do
		local p = floorSpot(r, c, rng, taken, 7)
		if p then
			table.insert(taken, p)
			K.cone(ctx, "Stalagmite", p, rng:NextNumber(0.9, 1.8), rng:NextNumber(3, 8), shade(th.wall, 0.8), mat(th.wallMat), ctx.Props, false, 6)
		end
	end
	local grow = (th.props and (table.find(th.props, "mushroom") and "mushroom" or (table.find(th.props, "crystal") and "crystal" or (table.find(th.props, "snowpile") and "snowpile")))) or nil
	for _ = 1, 3 do
		local p = floorSpot(r, c, rng, taken, 6)
		if p and grow and P[grow] then table.insert(taken, p); P[grow](ctx, th, CFrame.new(p), rng) end
	end
	local camp = floorSpot(r, c, rng, taken, 9)
	if camp then
		table.insert(taken, camp)
		if K.campfire then K.campfire(ctx, camp) else P.brazier(ctx, th, CFrame.new(camp)) end
		keep("sack", CFrame.new(camp + Vector3.new(4.5, 0, 1.5)))
		if rng:NextNumber() < 0.5 then keep("crate", CFrame.new(camp + Vector3.new(-4.5, 0, -1)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)) end
	end
end
-- a TREASURE VAULT: the ornate chest on its dais, gold piled round it, its silent guardians
A.vault = function(ctx, th, r, c, rng, keep)
	box(ctx, "Dais", Vector3.new(10, 0.8, 8), CFrame.new(c + Vector3.new(0, 0.4, 0)), shade(th.trim, 0.9), mat(th.trimMat))
	keep("ornate", CFrame.new(c + Vector3.new(0, 0.8, 0)))
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2 + 0.5
		P.goldpile(ctx, th, CFrame.new(c + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9)), rng)
	end
	for _, s in ipairs({-1, 1}) do
		P.statue(ctx, th, CFrame.lookAt(c + Vector3.new(s * (r.w / 2 - 5), 0, -r.d / 2 + 6), c))
		keep("urn", CFrame.new(c + Vector3.new(s * (r.w / 2 - 5), 0, r.d / 2 - 5)))
	end
	P.chandelier(ctx, th, CFrame.new(c))
end
-- THE LAIR (a raid's boss): the dais, and the hoard behind it
A.lair = function(ctx, th, r, c, rng, keep)
	feature(ctx, th, {kind = "boss", id = r.id}, CFrame.new(c))
	keep("hoard", CFrame.lookAt(c + Vector3.new(0, 0, r.d / 2 - 7), c))
	for _, s in ipairs({-1, 1}) do P.goldpile(ctx, th, CFrame.new(c + Vector3.new(s * 8, 0, r.d / 2 - 6)), rng) end
end
-- THE GRIME (a raid's rooms: Deadvault): cracks across the flags, rubble fallen into the corners,
-- cobwebs up the walls, damp streaks down them, a puddle, chains or a cage hanging out of the
-- dark, someone's bones, now and then guttering candles (a pool of light), and dust drifting in
-- the torchlight. Nothing of it is in the way (none of it collides).
local function grime(ctx, th, r, c, rng)
	local RH = r.h or WALL_H
	local taken = {}
	for _, k in ipairs(r.containers) do table.insert(taken, k.cf.Position) end
	local function deco(name, size, cf, color, m)
		local p = box(ctx, name, size, cf, color, m or Enum.Material.Slate, false)
		p.CanQuery = false; p.CastShadow = false
		return p
	end
	-- cracks
	local crack = shade(th.floor, 0.42)
	for _ = 1, rng:NextInteger(3, 6) do
		local at = c + Vector3.new(rng:NextNumber(-r.w / 2 + 4, r.w / 2 - 4), 0.04, rng:NextNumber(-r.d / 2 + 4, r.d / 2 - 4))
		local a = rng:NextNumber(0, math.pi * 2)
		for _ = 1, rng:NextInteger(2, 3) do
			local len = rng:NextNumber(1.4, 3.4)
			local f = CFrame.new(at) * CFrame.Angles(0, a, 0)
			deco("Crack", Vector3.new(0.16, 0.08, len), f * CFrame.new(0, 0, -len / 2), crack)
			at = (f * CFrame.new(0, 0, -len)).Position
			a += rng:NextNumber(-0.8, 0.8)
		end
	end
	-- rubble in a corner or two
	local corners = {{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}
	for _ = 1, rng:NextInteger(1, 2) do
		local k = table.remove(corners, rng:NextInteger(1, #corners))
		local base = c + Vector3.new(k[1] * (r.w / 2 - 5), 0, k[2] * (r.d / 2 - 5))
		if clearSpot(r, c, base, taken, 4.5) then
			for _ = 1, rng:NextInteger(4, 6) do
				local s = rng:NextNumber(0.6, 1.9)
				deco("Rubble", Vector3.new(s, s * 0.7, s * rng:NextNumber(0.8, 1.3)),
					CFrame.new(base + Vector3.new(rng:NextNumber(-2.2, 2.2), s * 0.3, rng:NextNumber(-2.2, 2.2))) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6.28), rng:NextNumber(-0.5, 0.5)),
					shade(th.wall, rng:NextNumber(0.68, 0.95)), mat(th.wallMat)).CastShadow = true
			end
		end
	end
	-- cobwebs up the walls; damp streaks down them
	for _ = 1, rng:NextInteger(1, 3) do
		local d = DIR_LIST[rng:NextInteger(1, 4)]
		local len = wallLen(r, d)
		P.cobweb(ctx, th, wallFrame(r, c, d, 1, rng:NextNumber(-len / 2 + 4, len / 2 - 4)), rng)
	end
	local damp = shade(th.wall, 0.62)
	for _ = 1, rng:NextInteger(2, 4) do
		local d = DIR_LIST[rng:NextInteger(1, 4)]
		local len = wallLen(r, d)
		local u = rng:NextNumber(-len / 2 + 4, len / 2 - 4)
		if not (r.doors[d] and math.abs(u) < DOOR_W / 2 + 2) then
			-- a stain spreading down from a seep, and a thinner drip running on below it
			local h = rng:NextNumber(RH * 0.2, RH * 0.45)
			local w = rng:NextNumber(0.8, 1.8)
			local f = wallFrame(r, c, d, 0.03, u)
			local top = RH - rng:NextNumber(0, 3)
			deco("Damp", Vector3.new(w, h, 0.06), f * CFrame.new(0, top - h / 2, 0), damp, mat(th.wallMat))
			local drip = rng:NextNumber(2, RH * 0.3)
			deco("Damp", Vector3.new(w * 0.35, drip, 0.07), f * CFrame.new(rng:NextNumber(-w * 0.25, w * 0.25), top - h - drip / 2 + 0.2, 0), shade(damp, 0.9), mat(th.wallMat))
		end
	end
	-- a puddle
	if rng:NextNumber() < 0.45 then
		local p = floorSpot(r, c, rng, taken, 6)
		if p then
			local s = rng:NextNumber(3, 6)
			local pd = K.cyl(ctx, "Puddle", s, 0.06, CFrame.new(p + Vector3.new(0, 0.05, 0)), Color3.fromRGB(28, 32, 36), Enum.Material.Glass, ctx.Props)
			pd.Size = Vector3.new(0.06, s, s * rng:NextNumber(0.6, 0.9))
			pd.CanCollide, pd.CanQuery, pd.Reflectance, pd.Transparency = false, false, 0.35, 0.15
		end
	end
	-- chains, or a cage, hanging out of the dark
	local roll = rng:NextNumber()
	if roll < 0.25 then
		local p = floorSpot(r, c, rng, taken, 7)
		if p then P.cage(ctx, th, CFrame.new(p), rng) end
	elseif roll < 0.5 then
		local d = DIR_LIST[rng:NextInteger(1, 4)]
		local len = wallLen(r, d)
		P.chains(ctx, th, wallFrame(r, c, d, 0.8, rng:NextNumber(-len / 2 + 5, len / 2 - 5)))
	end
	-- someone's bones
	if rng:NextNumber() < 0.4 then
		local p = floorSpot(r, c, rng, taken, 5)
		if p then P.bones(ctx, th, CFrame.new(p), rng) end
	end
	-- guttering candles by a wall (a pool of light)
	if rng:NextNumber() < 0.35 then
		local d = DIR_LIST[rng:NextInteger(1, 4)]
		local len = wallLen(r, d)
		local f = wallFrame(r, c, d, 2, rng:NextNumber(-len / 2 + 4, len / 2 - 4))
		if clearSpot(r, c, f.Position, taken, 4) then P.candles(ctx, th, f, rng) end
	end
	-- dust in the torchlight
	local dust = Instance.new("Part")
	dust.Name = "Dust"
	dust.Anchored, dust.CanCollide, dust.CanQuery, dust.CanTouch, dust.Transparency = true, false, false, false, 1
	dust.Size = Vector3.new(r.w - 4, RH * 0.7, r.d - 4)
	dust.CFrame = CFrame.new(c + Vector3.new(0, RH * 0.4, 0))
	dust.Parent = ctx.Props or ctx.model
	local pe = Instance.new("ParticleEmitter")
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	pe.Color = ColorSequence.new(Color3.fromRGB(230, 214, 190))
	pe.LightInfluence = 1
	pe.Brightness = 2
	pe.Size = NumberSequence.new(0.09)
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(0.7, 0.35), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(8, 12)
	pe.Speed = NumberRange.new(0.15, 0.45)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, -0.03, 0)
	pe.Rate = math.clamp(r.w * r.d / 400, 3, 10)
	pe.Parent = dust
end

-- THE WAY OUT (a raid's exit): stone steps climbing a wall to a door full of daylight
local function escapeStairs(ctx, th, r, c, rng)
	local qw = quietWall(r, rng) or "N"
	local steps, run = 10, 1.5
	local u0 = -steps * run / 2
	for i = 1, steps do
		box(ctx, "Step", Vector3.new(run, i * 1.2, 6), wallFrame(r, c, qw, 3.2, u0 + i * run) * CFrame.new(0, i * 0.6, 0), shade(th.trim, 1.15), mat(th.trimMat))
	end
	local top = wallFrame(r, c, qw, 3.2, u0 + steps * run + 3.5)
	box(ctx, "Landing", Vector3.new(6, 12, 6), top * CFrame.new(0, 6, 0), shade(th.trim, 1.1), mat(th.trimMat))
	local door = wallFrame(r, c, qw, 0.4, u0 + steps * run + 3.5)
	for _, x in ipairs({-3, 3}) do box(ctx, "EscapePost", Vector3.new(1, 9, 1.2), door * CFrame.new(x, 16.5, 0.2), Color3.fromRGB(96, 70, 44), Enum.Material.Wood) end
	box(ctx, "EscapeLintel", Vector3.new(7, 1, 1.2), door * CFrame.new(0, 21.5, 0.2), Color3.fromRGB(96, 70, 44), Enum.Material.Wood)
	local light = box(ctx, "EscapeDoor", Vector3.new(5, 8.6, 0.3), door * CFrame.new(0, 16.4, 0), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, false)
	light.Transparency = 0.1
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 236, 190); l.Range = 34; l.Brightness = 2.6; l.Parent = light
	local pe = Instance.new("ParticleEmitter"); pe.Color = ColorSequence.new(Color3.fromRGB(255, 244, 210)); pe.LightEmission = 0.6
	pe.Rate = 8; pe.Speed = NumberRange.new(0.5, 1.5); pe.Lifetime = NumberRange.new(2, 3); pe.Size = NumberSequence.new(0.25, 0)
	pe.SpreadAngle = Vector2.new(40, 40); pe.Parent = light
	r.escape = (top * CFrame.new(0, 12.5, 0)).Position
	r.escapeWall = qw
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

	-- each room's size and place (a raid's: what it was, and its size by that)
	local archW = ARCH_W[themeKey] or ARCH_W.BoneCrypt
	for _, r in ipairs(list) do
		r.cx = (r.gx - (W - 1) / 2) * CELL
		r.cz = (r.gy - (H - 1) / 2) * CELL
		if opts.raid then
			r.arch = (r.kind == "combat" and weighted(rng, archW)) or (r.kind == "elite" and "hall") or (r.kind == "treasure" and "vault") or (r.kind == "boss" and "lair") or nil
		end
		local sz = r.arch and ARCH_SIZE[r.arch]
		local big = r.kind == "boss" and 70 or (r.kind == "elite" and 52 or (r.kind == "start" and 40 or (r.kind == "exit" and opts.raid and 40 or nil)))
		r.w = (sz and rng:NextInteger(sz[1], sz[2]) * 2) or big or (rng:NextInteger(17, 25) * 2)
		r.d = (sz and rng:NextInteger(sz[1], sz[2]) * 2) or big or (rng:NextInteger(17, 25) * 2)
		if r.arch == "hall" and rng:NextNumber() < 0.5 then r.d = math.max(36, r.d - 16) end   -- (a long hall)
		r.h = (r.arch and ARCH_H[r.arch]) or WALL_H
		r.spots, r.gates, r.containers = {}, {}, {}
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
		local RH = r.h or WALL_H
		ctx.H = RH
		K.box(ctx, "Ceiling", Vector3.new(fw, 1, fd), CFrame.new(c + Vector3.new(0, RH + 0.5, 0)), shade(th.wall, 0.6), mat(th.wallMat))
		for x = -r.w / 2 + 8, r.w / 2 - 8, 12 do
			K.box(ctx, "Beam", Vector3.new(1.4, 1.4, r.d), CFrame.new(c + Vector3.new(x, RH - 0.7, 0)), th.trim, mat(th.trimMat)).CanCollide = false
		end
		-- the walls, a gap where a corridor comes in
		local gapsN, gapsS, gapsE, gapsW = {}, {}, {}, {}
		if r.doors.N then table.insert(gapsN, 0) end
		if r.doors.S then table.insert(gapsS, 0) end
		if r.doors.E then table.insert(gapsE, 0) end
		if r.doors.W then table.insert(gapsW, 0) end
		wallRun(ctx, th, c + Vector3.new(0, 0, -r.d / 2 - T / 2), "x", fw, RH, gapsN)
		wallRun(ctx, th, c + Vector3.new(0, 0, r.d / 2 + T / 2), "x", fw, RH, gapsS)
		wallRun(ctx, th, c + Vector3.new(r.w / 2 + T / 2, 0, 0), "z", r.d, RH, gapsE)
		wallRun(ctx, th, c + Vector3.new(-r.w / 2 - T / 2, 0, 0), "z", r.d, RH, gapsW)
		-- the baseboard, pillars at the corners
		for _, sx in ipairs({-1, 1}) do
			for _, sz in ipairs({-1, 1}) do
				K.box(ctx, "CornerPillar", Vector3.new(3, RH, 3), CFrame.new(c + Vector3.new(sx * (r.w / 2 - 1.5), RH / 2, sz * (r.d / 2 - 1.5))), th.trim, mat(th.trimMat))
			end
		end
		-- (a raid's rooms: pilasters down the walls and a skirting of the trim, between the doorways)
		if opts.raid then
			for _, d in ipairs(DIR_LIST) do
				local len = wallLen(r, d)
				for u = -len / 2 + 7, len / 2 - 7, 11 do
					if not (r.doors[d] and math.abs(u) < DOOR_W / 2 + 2.5) and math.abs(math.abs(u) - len * 0.3) > 2.5 then
						box(ctx, "Pilaster", Vector3.new(1.8, RH, 0.9), wallFrame(r, c, d, 0.45, u) * CFrame.new(0, RH / 2, 0), shade(th.trim, 1.08), mat(th.trimMat))
					end
				end
				local segs = r.doors[d] and {{-len / 2, -DOOR_W / 2 - 0.5}, {DOOR_W / 2 + 0.5, len / 2}} or {{-len / 2, len / 2}}
				for _, sg in ipairs(segs) do
					local slen = sg[2] - sg[1]
					if slen > 1 then box(ctx, "Skirting", Vector3.new(slen, 1.1, 0.5), wallFrame(r, c, d, 0.25, (sg[1] + sg[2]) / 2) * CFrame.new(0, 0.55, 0), shade(th.trim, 0.8), mat(th.trimMat), false) end
				end
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
				if not (r.doors[d] and math.abs(off) < DOOR_W) and (not opts.raid or rng:NextNumber() < 0.75 or r.kind == "start" or r.kind == "exit") then
					local pos
					if d == "N" or d == "S" then pos = c + Vector3.new(off, 8, v[2] * (r.d / 2 - 0.2))
					else pos = c + Vector3.new(v[1] * (r.w / 2 - 0.2), 8, off) end
					sconce(ctx, th, pos, inward[d])
				end
			end
		end
		-- the room's feature at its middle (the boss's dais, an altar…); a raid's rooms are furnished
		-- as what they were, and its exits are stairs up to the daylight
		local mid = CFrame.new(c)
		local function keep(kind, cf) table.insert(r.containers, {kind = kind, cf = cf}) end
		if r.arch and A[r.arch] then
			local okA, errA = pcall(A[r.arch], ctx, th, r, c, rng, keep)
			if not okA then warn("[Dungeon] room", r.arch, errA) end
		elseif opts.raid and r.kind == "exit" then
			escapeStairs(ctx, th, r, c, rng)
		elseif r.kind ~= "combat" and r.kind ~= "elite" then
			feature(ctx, th, r, mid)
		end
		-- (what's left of someone who came before; the odd crate, urn or sack by the walls)
		if opts.raid and r.kind ~= "start" and r.kind ~= "exit" then
			local taken = {c}
			for _, k in ipairs(r.containers) do table.insert(taken, k.cf.Position) end
			if rng:NextNumber() < 0.3 then
				local p = floorSpot(r, c, rng, taken, 6)
				if p then table.insert(taken, p); keep("remains", CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)) end
			end
			local odd = RAID_ODDS[themeKey] or RAID_ODDS.BoneCrypt
			for _ = 1, rng:NextInteger(1, 2) do
				local d = DIR_LIST[rng:NextInteger(1, 4)]
				local len = wallLen(r, d)
				local u = rng:NextNumber(-len / 2 + 5, len / 2 - 5)
				local f = wallFrame(r, c, d, 2.2, u)
				if clearSpot(r, c, f.Position, taken, 5) then
					table.insert(taken, f.Position)
					keep(odd[rng:NextInteger(1, #odd)], f * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0))
				end
			end
		end
		r.feature = c + Vector3.new(0, 0.5, 0)
		-- scattered props, kept off the middle and out of the doorways
		local nProps = (r.kind == "boss") and 6 or (r.arch and rng:NextInteger(1, 3) or rng:NextInteger(3, 6))
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
			for _, k in ipairs(r.containers) do if (k.cf.Position - p).Magnitude < 6 then ok = false end end
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
		if opts.raid and r.kind ~= "exit" then
			local okG, errG = pcall(grime, ctx, th, r, c, rng)
			if not okG then warn("[Dungeon] grime", errG) end
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
		b.Size = Vector3.new(r.w, RH, r.d)
		b.CFrame = CFrame.new(c + Vector3.new(0, RH / 2, 0))
		b:SetAttribute("RoomId", r.id); b:SetAttribute("Kind", r.kind); b:SetAttribute("Depth", r.depth)
		if r.arch then b:SetAttribute("Arch", r.arch) end
		ctx.H = nil
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
					if len > 18 and (not opts.raid or rng:NextNumber() < 0.5) then sconce(ctx, th, mid + Vector3.new(0, 8, -DOOR_W / 2 + 0.2), Vector3.new(0, 0, 1)) end
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
					if len > 18 and (not opts.raid or rng:NextNumber() < 0.5) then sconce(ctx, th, mid + Vector3.new(-DOOR_W / 2 + 0.2, 8, 0), Vector3.new(1, 0, 0)) end
				end
			end
		end
	end
	-- the room walls' lintels reach up to the room ceiling; above a corridor's ceiling is the room's own wall: closed

	-- the start: spawns round its middle, the menu's shot
	local s = list[1]
	for _, h in ipairs(list) do
		if h.kind == "start" then
			for i = 0, 5 do
				local a = i / 6 * math.pi * 2
				local sp = K.spawn(ctx, Vector3.new(h.cx + math.cos(a) * 9, 1, h.cz + math.sin(a) * 9), nil, Vector3.new(h.cx, 1, h.cz))
				sp:SetAttribute("Room", h.id)
			end
		end
	end
	local fin = finalId and list[finalId] or s
	K.camera(ctx, Vector3.new(s.cx + s.w * 0.35, 12, s.cz + s.d * 0.35), Vector3.new(s.cx, 3, s.cz))
	K.camera(ctx, Vector3.new(fin.cx - fin.w * 0.4, 14, fin.cz - fin.d * 0.4), Vector3.new(fin.cx, 4, fin.cz))
	local light = th.light
	if opts.raid then
		light = table.clone(th.light)
		light.Ambient = shade(th.light.Ambient, 0.62)
		light.OutdoorAmbient = shade(th.light.OutdoorAmbient, 0.62)
		light.Brightness = math.min(th.light.Brightness, 0.4)
		light.FogEnd = math.min(th.light.FogEnd or 260, 210)
		light.ExposureCompensation = -0.3
		light.EnvironmentDiffuseScale = 0.2
		light.EnvironmentSpecularScale = 0.35
	end
	K.lighting(ctx, light)
	K.atmosphere(ctx, {Density = opts.raid and 0.4 or 0.32, Offset = 0, Color = th.light.FogColor, Decay = th.light.FogColor, Glare = 0, Haze = opts.raid and 2 or 1.5})
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
