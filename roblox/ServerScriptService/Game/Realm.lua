--[[ REALM — builds Crownfall's island from nothing every match (Game ▸ Modes ▸ Crownfall).

       Realm.build(opts) -> mapName, layout
         opts.radius   the island's (520)
         opts.seed     a number (random otherwise)
         opts.name     its name in ServerStorage ▸ Maps (Gen_Realm_<n> otherwise)

     THE LAND is one height function, written into the terrain voxel by voxel and asked again for
     every thing that stands on it, so nothing floats and nothing is buried: a coast that wanders
     (sand beaches into a summer sea), rolling grassland, hills, HIGHLANDS of rock and snow on one
     side, a RIVER running down out of them to the sea, a LAKE in a valley, the CROWN KEEP on its hill
     in the middle, and dirt ROADS between the places (stone BRIDGES where they cross the river).
     The ground is levelled under each place, so its buildings sit flat.

     THE PLACES, each with a name and its chests: the Crown Keep (curtain walls, towers, the great
     hall, banners), villages (cottages round a green, a well, a market, carts, lanterns), a harbour
     (a quay, a pier into the sea, warehouses, a beached longship), farmsteads (a barn, fields of
     wheat behind fences, haystacks), a windmill, watchtowers on the hills, a bandit camp and a
     hunters' camp, a chapel and its graveyard, the old ruins, standing stones, a mine in the
     highlands (its timbered mouth, rails, ore), a lakeside lodge and its jetty, and a fort at a
     river crossing. Forests between them (oak and pine, thicker in the woods' heart), boulders,
     bushes, fallen logs, wildflowers.

     A place may use a prefab from ServerStorage ▸ RealmProps (Studio-only models: an Oak, a Pine,
     a Boulder…) when one is there; otherwise it's built of parts.

       layout.pois   = {{name, kind, pos (Vector3), radius}}
       layout.chests = {CFrame…} (on the ground, facing out: exactly where the chest stands)
       layout.loot   = {Vector3…} (on the ground: a weapon or armour lying there)
       layout.drops  = {Vector3…} (every place)
       layout.radius, layout.centre, layout.height(x, z) (the ground's height) ]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Terrain = workspace.Terrain

local Build = ServerScriptService:WaitForChild("Build")
local K = require(Build:WaitForChild("MapKit"))
if not K.wagon then require(Build:WaitForChild("MapProps"))(K) end
local Realm = {}
local made = 0
local DEG = math.rad
local V3 = Vector3.new
local M = Enum.Material

local SEA = -9            -- the sea's surface (Game ▸ Horizon reads SeaLevel)
local VOX = 4
local Y0, LAYERS = -28, 30   -- the terrain's slab: y from -28, 30 voxels up (to 92)
local MAXH = 86

local NAMES = {
	village = {"Ashford", "Millbrook", "Thornvale", "Oakhollow", "Briar's End", "Cobblecross", "Wrenfield", "Hartsdale", "Fernmere", "Dunmoor"},
	harbor = {"Saltmarsh Harbour", "Gull's Landing", "Port Brennock", "Tidewater"},
	farm = {"Haywood Farm", "the Old Steading", "Barley Fields", "Goldacre"},
	camp = {"Bandit Camp", "Smugglers' Den", "Cutthroat Hollow"},
	hunters = {"the Hunters' Rest", "Wolfpine Camp", "Deerstalk"},
	chapel = {"Saint Aldric's", "the Grey Chapel", "Bellrest"},
	ruins = {"the Old Ruins", "Fallen Hall", "Brokenstone", "the Sunken Court"},
	mill = {"the Old Mill", "Windmere", "Grindstone"},
	tower = {"Raven Tower", "the Old Watch", "Highlook", "Stormwatch Tower", "the Beacon"},
	stones = {"the Standing Stones", "the Giants' Ring", "the Old Circle"},
	mine = {"the Deep Mine", "Ironvein", "the Black Pit"},
	lodge = {"Lakeside Lodge", "the Fisher's Rest", "Mirrormere"},
	fort = {"the Bridge Fort", "Riverwatch", "the Fording Keep"},
}
local function pick(rng, list) return list[rng:NextInteger(1, #list)] end
local function smooth(a, b, x) local t = math.clamp((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t) end
local function flat(v) return V3(v.X, 0, v.Z) end
-- distance from p to the segment ab (in the xz plane), and how far along it (0..1)
local function segDist(px, pz, ax, az, bx, bz)
	local dx, dz = bx - ax, bz - az
	local l2 = dx * dx + dz * dz
	local t = l2 > 0 and math.clamp(((px - ax) * dx + (pz - az) * dz) / l2, 0, 1) or 0
	local qx, qz = ax + dx * t - px, az + dz * t - pz
	return math.sqrt(qx * qx + qz * qz), t
end
-- where two segments cross (xz), or nil
local function cross2(a, b, c, d)
	local r = b - a
	local s = d - c
	local den = r.X * s.Z - r.Z * s.X
	if math.abs(den) < 1e-6 then return nil end
	local t = ((c.X - a.X) * s.Z - (c.Z - a.Z) * s.X) / den
	local u = ((c.X - a.X) * r.Z - (c.Z - a.Z) * r.X) / den
	if t < 0 or t > 1 or u < 0 or u > 1 then return nil end
	return a + r * t, t
end

--------------------------------------------------------------------
--  THE ISLAND
--------------------------------------------------------------------
function Realm.build(opts)
	opts = opts or {}
	local R = opts.radius or 520
	local E = math.ceil((R * 1.24) / 64) * 64      -- the slab's half-width (a whole number of chunks)
	local rng = Random.new(opts.seed or math.random(1, 2 ^ 30))
	made += 1
	local name = opts.name or ("Gen_Realm_" .. made)
	local ctx = K.new(name)
	local L = {pois = {}, chests = {}, loot = {}, drops = {}, radius = R, centre = V3(0, 0, 0)}
	local prefabs = ServerStorage:FindFirstChild("RealmProps")

	----------------------------------------------------------------
	-- THE SHAPE OF THE LAND
	----------------------------------------------------------------
	local sx, sz = rng:NextNumber(-4000, 4000), rng:NextNumber(-4000, 4000)
	local function noise(x, z, scale, o)
		o = o or 0
		return math.noise(x / scale + sx + o * 31.7, z / scale + sz - o * 17.3, o * 0.37)
	end
	local function shoreAt(x, z)
		local a = math.atan2(z, x)
		local c, s = math.cos(a), math.sin(a)
		return R * (1 + 0.17 * math.noise(c * 1.4 + sx * 0.001, s * 1.4 + sz * 0.001, 0.5) + 0.07 * math.noise(c * 3.9 + 9.1, s * 3.9 - 4.3, 1.5))
	end
	-- the highlands, out on one side
	local hlA = rng:NextNumber(0, math.pi * 2)
	local HC = V3(math.cos(hlA) * R * 0.5, 0, math.sin(hlA) * R * 0.5)
	local function raw(x, z)
		local d = math.sqrt(x * x + z * z)
		local m = 1 - smooth(0.8, 1.0, d / shoreAt(x, z))
		local h = 6 + 7 * noise(x, z, 260) + 3.5 * noise(x, z, 90, 1) + 1.1 * noise(x, z, 28, 2)
		local hill = noise(x, z, 170, 3)
		if hill > 0 then h += 46 * hill ^ 1.35 end
		local dh = math.sqrt((x - HC.X) ^ 2 + (z - HC.Z) ^ 2)
		local k = 1 - dh / (R * 0.42)
		if k > 0 then
			local ridge = 1 - math.abs(noise(x, z, 70, 4)) * 2
			h += 64 * k ^ 1.4 * (0.55 + 0.45 * ridge)
		end
		-- the keep's hill in the middle
		h += 13 * math.max(0, 1 - d / 130) ^ 1.4
		h = math.max(h, 2)
		return -18 + (h + 18) * m, m
	end

	----------------------------------------------------------------
	-- WHERE THINGS GO
	----------------------------------------------------------------
	local places = {}
	local function addPlace(kind, pos, radius, nm)
		-- (fall: how far the levelled ground blends back into the land; the harbour's is short, so
		-- the sea floor stays deep under its pier)
		local pl = {kind = kind, pos = pos, radius = radius, name = nm, fall = kind == "harbor" and 12 or 34}
		table.insert(places, pl)
		return pl
	end
	local function onLand(p, margin)
		local d = flat(p).Magnitude
		return d < shoreAt(p.X, p.Z) * (margin or 0.78)
	end
	local function farFromAll(p, gap)
		for _, pl in ipairs(places) do if (flat(pl.pos) - flat(p)).Magnitude < pl.radius + gap then return false end end
		return true
	end
	addPlace("keep", V3(0, 0, 0), 52, "the Crown Keep")
	-- the lake, in a valley on the far side from the highlands
	local lakeA = hlA + math.pi + rng:NextNumber(-0.9, 0.9)
	local LAKE = {c = V3(math.cos(lakeA) * R * 0.46, 0, math.sin(lakeA) * R * 0.46), r = rng:NextNumber(34, 46)}
	-- the river: from the highlands' foot to the sea, winding
	local river = {}
	do
		local out = flat(HC).Unit
		local dirA = math.atan2(out.Z, out.X) + ((rng:NextNumber() < 0.5) and 1 or -1) * rng:NextNumber(0.5, 1.0)
		local dir = V3(math.cos(dirA), 0, math.sin(dirA))
		local perp = V3(-dir.Z, 0, dir.X)
		local start = HC - out * (R * 0.12)
		local n = 16
		local len = R * 1.25
		for i = 0, n do
			local t = i / n
			table.insert(river, start + dir * (len * t) + perp * (math.sin(t * 7.3 + rng:NextNumber(0, 0.4)) * 26 * t))
		end
	end
	-- (the river's water level falls with the land it runs through; the bed a little under it)
	local riverLevel = {}
	for i, p in ipairs(river) do riverLevel[i] = math.max(SEA, (raw(p.X, p.Z)) - 4) end
	local RIVER_W = 8
	local function riverAt(x, z)
		local best, lvl = math.huge, nil
		for i = 1, #river - 1 do
			local a, b = river[i], river[i + 1]
			local d, t = segDist(x, z, a.X, a.Z, b.X, b.Z)
			if d < best then best, lvl = d, riverLevel[i] + (riverLevel[i + 1] - riverLevel[i]) * t end
		end
		return best, lvl
	end
	local plan = {
		{"mine", 1}, {"fort", 1}, {"lodge", 1}, {"harbor", 1},
		{"village", 4}, {"farm", 2}, {"mill", 1}, {"tower", 2}, {"camp", 1}, {"hunters", 1}, {"chapel", 1}, {"ruins", 1}, {"stones", 1},
	}
	local RADIUS = {village = 42, harbor = 22, farm = 40, mill = 26, tower = 20, camp = 26, hunters = 22, chapel = 30, ruins = 28, stones = 20, mine = 26, lodge = 26, fort = 30}
	local used = {}
	for _, item in ipairs(plan) do
		local kind, count = item[1], item[2]
		for _ = 1, count do
			local nm
			for _ = 1, 12 do nm = pick(rng, NAMES[kind]); if not used[nm] then break end end
			used[nm] = true
			local r = RADIUS[kind]
			local spot
			for try = 1, 160 do
				local gap = try < 120 and 70 or 30
				local p
				if kind == "mine" then
					local a = rng:NextNumber(0, math.pi * 2)
					p = HC + V3(math.cos(a), 0, math.sin(a)) * (R * rng:NextNumber(0.18, 0.28))
				elseif kind == "fort" then
					local i = rng:NextInteger(5, #river - 6)
					p = river[i]
				elseif kind == "lodge" then
					local a = rng:NextNumber(0, math.pi * 2)
					p = LAKE.c + V3(math.cos(a), 0, math.sin(a)) * (LAKE.r + r + 6)
				elseif kind == "harbor" then
					local a = rng:NextNumber(0, math.pi * 2)
					p = V3(math.cos(a), 0, math.sin(a)) * (shoreAt(math.cos(a), math.sin(a)) * 0.84)
				else
					local a, d = rng:NextNumber(0, math.pi * 2), math.sqrt(rng:NextNumber(0.06, 1)) * R * 0.74
					p = V3(math.cos(a) * d, 0, math.sin(a) * d)
				end
				local ok = (kind == "harbor" or onLand(p)) and farFromAll(p, gap)
				if ok and kind ~= "mine" and (flat(p - HC)).Magnitude < R * 0.3 then ok = false end
				if ok and kind ~= "lodge" and (flat(p - LAKE.c)).Magnitude < LAKE.r + r + 10 then ok = false end
				if ok and kind ~= "fort" then local d = riverAt(p.X, p.Z); if d < r + RIVER_W + 8 then ok = false end end
				if ok then spot = p; break end
			end
			if spot then addPlace(kind, spot, r, nm) end
		end
	end
	-- each place's level ground (the keep's on its hill; the harbour just above the sea)
	for _, pl in ipairs(places) do
		local h = raw(pl.pos.X, pl.pos.Z)
		if pl.kind == "harbor" then h = 3
		elseif pl.kind == "fort" then h = math.max(h, (select(2, riverAt(pl.pos.X, pl.pos.Z)) or SEA) + 5)
		elseif pl.kind == "lodge" then h = math.max(h, 4) end
		pl.padH = math.max(h, 2.5)
		pl.pos = V3(pl.pos.X, pl.padH, pl.pos.Z)
	end
	local lakeLevel = math.max(SEA, raw(LAKE.c.X, LAKE.c.Z) - 3)

	-- THE ROADS: each place to the nearest place nearer the keep (the keep's are cobbled)
	local roads = {}
	for _, pl in ipairs(places) do
		if pl.kind ~= "keep" and pl.kind ~= "stones" then
			local best, bd = places[1], math.huge
			local my = flat(pl.pos).Magnitude
			for _, o in ipairs(places) do
				if o ~= pl and flat(o.pos).Magnitude < my - 20 and o.kind ~= "stones" then
					local d = (flat(o.pos) - flat(pl.pos)).Magnitude
					if d < bd then best, bd = o, d end
				end
			end
			table.insert(roads, {a = flat(pl.pos), b = flat(best.pos)})
		end
	end
	local function roadDist(x, z)
		local best = math.huge
		for _, r in ipairs(roads) do
			local d = segDist(x, z, r.a.X, r.a.Z, r.b.X, r.b.Z)
			if d < best then best = d end
		end
		return best
	end

	-- THE GROUND'S HEIGHT, everything considered; and the water over it, if any
	local function ground(x, z)
		local h, m = raw(x, z)
		for _, pl in ipairs(places) do
			local d = math.sqrt((x - pl.pos.X) ^ 2 + (z - pl.pos.Z) ^ 2)
			if d < pl.radius + pl.fall then
				local w = 1 - smooth(pl.radius, pl.radius + pl.fall, d)
				h = h + (pl.padH - h) * w
			end
		end
		-- the lake's basin
		local dl = math.sqrt((x - LAKE.c.X) ^ 2 + (z - LAKE.c.Z) ^ 2)
		local water = nil
		if dl < LAKE.r + 18 then
			local bed = lakeLevel - 5 * (1 - smooth(LAKE.r * 0.3, LAKE.r, dl))
			local w = 1 - smooth(LAKE.r - 6, LAKE.r + 18, dl)
			h = h + (math.min(h, bed) - h) * w
			if dl < LAKE.r + 4 then water = lakeLevel end
		end
		-- the river's channel
		local dr, lvl = riverAt(x, z)
		if dr < RIVER_W + 10 and lvl then
			local bed = lvl - 3 + 2 * (dr / RIVER_W) ^ 2
			local w = 1 - smooth(RIVER_W, RIVER_W + 10, dr)
			h = h + (math.min(h, bed) - h) * w
			if dr < RIVER_W + 3 then water = math.max(water or -math.huge, lvl) end
		end
		-- the sea
		if h < SEA then water = math.max(water or -math.huge, SEA) end
		return math.min(h, MAXH), water, m
	end
	L.height = function(x, z) return (ground(x, z)) end
	local function at(x, z, sink) return V3(x, (ground(x, z)) - (sink or 0), z) end

	----------------------------------------------------------------
	-- THE TERRAIN, voxel by voxel
	----------------------------------------------------------------
	local N = (E * 2) / VOX
	local hg, wg = table.create(N * N, 0), {}
	for i = 1, N do
		local x = -E + (i - 0.5) * VOX
		for j = 1, N do
			local z = -E + (j - 0.5) * VOX
			local h, w = ground(x, z)
			hg[(i - 1) * N + j] = h
			if w then wg[(i - 1) * N + j] = w end
		end
		if i % 24 == 0 then task.wait() end
	end
	local function H(i, j) return hg[(math.clamp(i, 1, N) - 1) * N + math.clamp(j, 1, N)] end
	local forestScale = 150
	local function forestK(x, z) return noise(x, z, forestScale, 5) end
	local function topMat(i, j, x, z)
		local h = H(i, j)
		local w = wg[(i - 1) * N + j]
		if w and h < w then return (w > SEA + 0.5) and M.Mud or M.Sand end
		local slope = math.max(math.abs(H(i + 1, j) - H(i - 1, j)), math.abs(H(i, j + 1) - H(i, j - 1))) / (2 * VOX)
		if h > 62 then return slope > 0.9 and M.Rock or M.Snow end
		if slope > 0.85 or (h > 46 and slope > 0.45) then return M.Rock end
		if roadDist(x, z) < 3.6 then return flat(V3(x, 0, z)).Magnitude < 70 and M.Cobblestone or M.Ground end
		for _, pl in ipairs(places) do
			local d = math.sqrt((x - pl.pos.X) ^ 2 + (z - pl.pos.Z) ^ 2)
			if d < pl.radius then
				if pl.kind == "keep" and d < 36 then return M.Cobblestone end
				if (pl.kind == "village" or pl.kind == "harbor") and d < 13 then return M.Cobblestone end
				if pl.kind == "camp" or pl.kind == "hunters" or pl.kind == "mine" then return M.Ground end
				return M.Grass
			end
		end
		-- (sand only on the coast: a low meadow inland stays green)
		if h < 3.2 and math.sqrt(x * x + z * z) > shoreAt(x, z) * 0.72 then return M.Sand end
		local dr = riverAt(x, z)
		if dr < RIVER_W + 4 then return M.Mud end
		if forestK(x, z) > 0.16 then return M.LeafyGrass end
		return M.Grass
	end
	local corner = V3(-E, Y0, -E)
	local size = V3(E * 2, LAYERS * VOX, E * 2)
	K.terrain(ctx, corner, size, function()
		local CH = 32
		for ci = 0, N / CH - 1 do
			for cj = 0, N / CH - 1 do
				local mats, occs = {}, {}
				for a = 1, CH do
					local i = ci * CH + a
					local x = -E + (i - 0.5) * VOX
					local mcol, ocol = {}, {}
					mats[a], occs[a] = mcol, ocol
					for iy = 1, LAYERS do mcol[iy], ocol[iy] = {}, {} end
					for b = 1, CH do
						local j = cj * CH + b
						local z = -E + (j - 0.5) * VOX
						local h = H(i, j)
						local w = wg[(i - 1) * N + j]
						local top = topMat(i, j, x, z)
						local deep = (top == M.Snow or top == M.Rock) and M.Rock or M.Ground
						for iy = 1, LAYERS do
							local yb = Y0 + (iy - 1) * VOX
							-- (Roblox draws a fill's surface 2 studs above where it ends: end it 2 low)
							local o = math.clamp((h - 2 - yb) / VOX, 0, 1)
							local mat = M.Air
							if o > 0.02 then
								mat = (h - yb <= 8) and top or deep
							end
							if w and o < 0.5 then
								local wo = math.clamp((w - 2 - yb) / VOX, 0, 1)
								if wo > o then mat, o = M.Water, wo end
							end
							mcol[iy][b], ocol[iy][b] = mat, (mat == M.Air) and 0 or o
						end
					end
				end
				local lo = V3(-E + ci * CH * VOX, Y0, -E + cj * CH * VOX)
				Terrain:WriteVoxels(Region3.new(lo, lo + V3(CH * VOX, LAYERS * VOX, CH * VOX)), VOX, mats, occs)
				task.wait()
			end
		end
	end, {fast = true})
	K.terrainColors(ctx, {Grass = Color3.fromRGB(98, 148, 70), LeafyGrass = Color3.fromRGB(72, 120, 54), Sand = Color3.fromRGB(220, 202, 156),
		Ground = Color3.fromRGB(116, 94, 68), Mud = Color3.fromRGB(86, 72, 56), Rock = Color3.fromRGB(118, 114, 108), Snow = Color3.fromRGB(240, 244, 250),
		Cobblestone = Color3.fromRGB(128, 124, 116)})

	----------------------------------------------------------------
	-- SET PIECES (all on the ground)
	----------------------------------------------------------------
	local function prefab(kind, pos, scale, yaw)
		local src = prefabs and prefabs:FindFirstChild(kind)
		if not src then return nil end
		local m = src:Clone()
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
		if scale and scale ~= 1 then pcall(function() m:ScaleTo(m:GetScale() * scale) end) end
		local cf, sz = m:GetBoundingBox()
		local bottom = cf.Position.Y - sz.Y / 2
		m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, yaw or 0, 0) * (m:GetPivot() - m:GetPivot().Position) + V3(0, m:GetPivot().Position.Y - bottom, 0))
		m.Parent = ctx.Props
		ctx.n += 1
		return m
	end
	local function chestSpot(pos, face)
		local p = at(pos.X, pos.Z)
		table.insert(L.chests, CFrame.lookAt(p, p + flat(face or V3(0, 0, -1))))
	end
	local function lootSpot(pos) table.insert(L.loot, at(pos.X, pos.Z)) end
	local WALLS = {Color3.fromRGB(226, 214, 190), Color3.fromRGB(206, 184, 150), Color3.fromRGB(190, 170, 140), Color3.fromRGB(214, 206, 196)}
	local ROOFS = {Color3.fromRGB(116, 62, 44), Color3.fromRGB(84, 66, 54), Color3.fromRGB(150, 110, 60), Color3.fromRGB(96, 104, 112)}
	local function house(frame, w, len, h)
		K.house(ctx, frame, w, len, h, WALLS[rng:NextInteger(1, #WALLS)], ROOFS[rng:NextInteger(1, #ROOFS)])
	end
	local function oak(pos, h) if not prefab("Oak", pos, h / 14, rng:NextNumber(0, 6.28)) then K.oak(ctx, pos, h) end end
	local function pine(pos, h) if not prefab("Pine", pos, h / 16, rng:NextNumber(0, 6.28)) then K.pine2(ctx, pos, h, 3, 5) end end
	local function boulder(pos, s) if not prefab("Boulder", pos, s / 5, rng:NextNumber(0, 6.28)) then K.rock(ctx, pos, s) end end
	local function log(pos, yaw, len)
		local p = K.cyl(ctx, "Log", 1.4, len, CFrame.new(pos + V3(0, 0.6, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, DEG(90)), Color3.fromRGB(96, 70, 48), M.Wood, ctx.Props)
		return p
	end
	local function flowers(pos, n)
		local cols = {Color3.fromRGB(240, 220, 80), Color3.fromRGB(236, 120, 150), Color3.fromRGB(180, 140, 240), Color3.fromRGB(250, 250, 250)}
		for _ = 1, n do
			local q = pos + V3(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
			local b = K.ball(ctx, "Flower", rng:NextNumber(0.4, 0.7), at(q.X, q.Z, -0.25), cols[rng:NextInteger(1, #cols)], M.SmoothPlastic, ctx.Props)
			b.CanCollide, b.CastShadow = false, false
		end
	end
	local function stall(frame, color)
		for _, s in ipairs({{-1.8, -1.2}, {1.8, -1.2}, {-1.8, 1.2}, {1.8, 1.2}}) do K.box(ctx, "StallPost", V3(0.3, 4, 0.3), frame * CFrame.new(s[1], 2, s[2]), K.C.DARKWOOD, M.Wood, ctx.Props) end
		K.box(ctx, "StallTable", V3(4, 0.3, 2.2), frame * CFrame.new(0, 1.6, 0), K.C.WOOD, M.WoodPlanks, ctx.Props)
		K.box(ctx, "StallCloth", V3(4.4, 0.2, 3), frame * CFrame.new(0, 4.1, 0) * CFrame.Angles(DEG(-8), 0, 0), color, M.Fabric, ctx.Props).CanCollide = false
		for i = 1, 3 do K.ball(ctx, "Goods", 0.7, frame * CFrame.new(-1.2 + i * 0.7, 2.1, 0), ({Color3.fromRGB(200, 60, 40), Color3.fromRGB(240, 190, 60), Color3.fromRGB(110, 160, 70)})[i], M.SmoothPlastic, ctx.Props).CanCollide = false end
	end
	local function field(frame, w, len, crop)
		-- rows of a crop on the ground, a fence round it
		local rows = math.floor(w / 2.4)
		for i = 0, rows - 1 do
			local x = -w / 2 + 1.2 + i * 2.4
			K.box(ctx, "Crop", V3(1.2, 1.4, len - 2), frame * CFrame.new(x, 0.6, 0), crop or Color3.fromRGB(214, 182, 84), M.Grass, ctx.Props).CanCollide = false
		end
		local c = {frame * CFrame.new(-w / 2, 0, -len / 2), frame * CFrame.new(w / 2, 0, -len / 2), frame * CFrame.new(w / 2, 0, len / 2), frame * CFrame.new(-w / 2, 0, len / 2)}
		for i = 1, 4 do
			if i ~= 3 then K.fence(ctx, c[i].Position, c[i % 4 + 1].Position, 2.2) end
		end
	end

	-- THE CROWN KEEP: curtain walls and towers round a cobbled bailey, the great hall, banners
	local function keep(pl)
		local c = pl.pos
		local stone = Color3.fromRGB(150, 146, 138)
		local r = 40
		for i = 0, 5 do
			local a0 = i / 6 * math.pi * 2
			local a1 = (i + 1) / 6 * math.pi * 2
			local p0 = c + V3(math.cos(a0) * r, 0, math.sin(a0) * r)
			local p1 = c + V3(math.cos(a1) * r, 0, math.sin(a1) * r)
			if i % 2 == 0 then
				-- a gatehouse in every other wall
				local mid = (p0 + p1) / 2
				local dir = (p1 - p0).Unit
				K.wall(ctx, p0, mid - dir * 7, 13, 3, {crenels = true, color = stone, base = true})
				K.wall(ctx, mid + dir * 7, p1, 13, 3, {crenels = true, color = stone, base = true})
				K.arch(ctx, CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.pi / 2, 0), 14, 13, 3, stone)
				for _, s in ipairs({-1, 1}) do K.tower(ctx, mid + dir * (s * 8.5), 3.5, 17, {color = stone, roof = true, roofColor = Color3.fromRGB(120, 40, 40)}) end
			else
				K.wall(ctx, p0, p1, 13, 3, {crenels = true, color = stone, base = true})
			end
			K.tower(ctx, p0, 6, 22, {color = stone, roof = true, roofColor = Color3.fromRGB(120, 40, 40), base = 2, windows = true})
		end
		-- the great hall and its tower
		local f = CFrame.new(c) * CFrame.Angles(0, DEG(rng:NextInteger(0, 5) * 60), 0)
		K.house(ctx, f * CFrame.new(0, 0, 4), 18, 26, 14, stone, Color3.fromRGB(110, 40, 40))
		K.tower(ctx, (f * CFrame.new(-15, 0, -15)).Position, 5, 34, {color = stone, roof = true, roofColor = Color3.fromRGB(110, 40, 40), windows = true})
		for _, a in ipairs({30, 90, 150, 210, 270, 330}) do
			local p = c + V3(math.cos(DEG(a)) * 26, 0, math.sin(DEG(a)) * 26)
			K.banner(ctx, p, 11, Color3.fromRGB(200, 160, 40))
			if a % 60 == 30 then chestSpot(c + V3(math.cos(DEG(a + 18)) * 30, 0, math.sin(DEG(a + 18)) * 30), c - p) end
		end
		for i = 1, 4 do
			local a = rng:NextNumber(0, math.pi * 2)
			local p = c + V3(math.cos(a) * 18, 0, math.sin(a) * 18)
			if i % 2 == 0 then K.brazier(ctx, p) else K.crate(ctx, p, 3, rng:NextNumber(0, 90)) end
		end
		pcall(K.rack, ctx, f * CFrame.new(10, 0, -12))
		lootSpot(f * Vector3.new(10, 0, -9.5))
		lootSpot(f * Vector3.new(-6, 0, 18))
	end

	-- A VILLAGE: cottages round a green with a well, a market, carts, lanterns, a fence or two
	local function village(pl)
		local c = pl.pos
		local n = rng:NextInteger(5, 7)
		for i = 1, n do
			local a = (i / n) * math.pi * 2 + rng:NextNumber(-0.18, 0.18)
			local d = rng:NextNumber(23, 31)
			local p = c + V3(math.cos(a) * d, 0, math.sin(a) * d)
			-- (the door, +Z, onto the green)
			local frame = CFrame.lookAt(p, V3(c.X, p.Y, c.Z)) * CFrame.Angles(0, math.pi, 0)
			house(frame, rng:NextInteger(10, 13), rng:NextInteger(11, 15), rng:NextInteger(7, 10))
			if i % 2 == 1 then chestSpot((frame * CFrame.new(0, 0, -9.5)).Position, flat(c - p)) end
			if rng:NextNumber() < 0.5 then K.barrel(ctx, (frame * CFrame.new(4.5, 0, 8.4)).Position) end
		end
		K.cyl(ctx, "Well", 4.4, 2.4, c + V3(0, 1.2, 0), K.C.STONE, M.Cobblestone)
		K.cyl(ctx, "WellWater", 3.6, 0.2, c + V3(0, 1.9, 0), Color3.fromRGB(60, 100, 140), M.Glass).CanCollide = false
		K.box(ctx, "WellBeam", V3(5, 0.4, 0.4), CFrame.new(c + V3(0, 5, 0)), K.C.DARKWOOD, M.Wood)
		for _, s in ipairs({-1, 1}) do K.box(ctx, "WellPost", V3(0.4, 5, 0.4), CFrame.new(c + V3(s * 2.2, 2.5, 0)), K.C.DARKWOOD, M.Wood) end
		chestSpot(c + V3(5, 0, 5), V3(1, 0, 1))
		local cloths = {Color3.fromRGB(176, 42, 42), Color3.fromRGB(52, 86, 190), Color3.fromRGB(220, 190, 80), Color3.fromRGB(70, 130, 70)}
		for i = 1, 3 do
			local a = rng:NextNumber(0, math.pi * 2)
			local p = c + V3(math.cos(a) * 11, 0, math.sin(a) * 11)
			stall(CFrame.lookAt(p, V3(c.X, p.Y, c.Z)), cloths[rng:NextInteger(1, #cloths)])
		end
		for i = 1, 4 do
			local a = rng:NextNumber(0, math.pi * 2)
			local p = c + V3(math.cos(a) * 16, 0, math.sin(a) * 16)
			if i == 1 then pcall(K.wagon, ctx, CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)) elseif i == 2 then K.hay(ctx, p) else K.lantern(ctx, p) end
		end
		local fa = rng:NextNumber(0, math.pi * 2)
		local f0, f1 = c + V3(math.cos(fa) * 36, 0, math.sin(fa) * 36), c + V3(math.cos(fa + 0.5) * 36, 0, math.sin(fa + 0.5) * 36)
		K.fence(ctx, at(f0.X, f0.Z), at(f1.X, f1.Z), 2.4)
		lootSpot(c + V3(-4, 0, 6))
		flowers(c + V3(7, 0, -6), 8)
	end

	-- THE HARBOUR: a quay along the water, a pier out into the sea, warehouses, a beached longship
	local function harbor(pl)
		local c = pl.pos
		local seaward = flat(c).Unit
		local f = CFrame.lookAt(c, c + seaward)
		-- the pier on posts, out over the water
		for i = 0, 7 do
			local p = f * CFrame.new(0, 0, -6 - i * 6)
			K.box(ctx, "Pier", V3(6, 0.6, 6.2), p * CFrame.new(0, 0.2, 0), K.C.WOOD, M.WoodPlanks)
			for _, s in ipairs({-1, 1}) do K.cyl(ctx, "Piling", 0.9, 16, p * CFrame.new(s * 2.8, -7.6, 0), K.C.DARKWOOD, M.Wood) end
		end
		pcall(K.longship, ctx, f * CFrame.new(14, -2.5, -26) * CFrame.Angles(0, DEG(rng:NextNumber(-15, 15)), 0), true)
		for i = -1, 1, 2 do
			house(f * CFrame.new(i * 15, 0, 14) * CFrame.Angles(0, math.pi, 0), 14, 16, 9)
		end
		for i = 1, 6 do K.crate(ctx, (f * CFrame.new(rng:NextNumber(-10, 10), 0, rng:NextNumber(-4, 4))).Position, rng:NextNumber(2.2, 3.2), rng:NextNumber(0, 90)) end
		for i = 1, 4 do K.barrel(ctx, (f * CFrame.new(rng:NextNumber(-8, 8), 0, rng:NextNumber(0, 6))).Position) end
		K.lantern(ctx, (f * CFrame.new(-3, 0, -6)).Position)
		chestSpot((f * CFrame.new(-6, 0, 2)).Position, seaward)
		chestSpot((f * CFrame.new(-15, 0, 4)).Position, seaward)
		chestSpot((f * CFrame.new(15, 0, 4)).Position, seaward)
		lootSpot((f * CFrame.new(6, 0, 2)).Position)
	end

	-- A FARMSTEAD: the barn, a cottage, fields behind fences, haystacks, a cart
	local function farm(pl)
		local c = pl.pos
		local f = CFrame.new(c) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
		K.house(ctx, f * CFrame.new(-8, 0, 0), 16, 20, 11, Color3.fromRGB(150, 70, 52), Color3.fromRGB(80, 60, 50))
		house(f * CFrame.new(12, 0, -10), 10, 11, 8)
		field(f * CFrame.new(4, 0, 20), 22, 16)
		field(f * CFrame.new(-18, 0, 22), 16, 18, Color3.fromRGB(120, 170, 70))
		for i = 1, 5 do K.hay(ctx, (f * CFrame.new(rng:NextNumber(-4, 12), 0, rng:NextNumber(-4, 6))).Position) end
		pcall(K.wagon, ctx, f * CFrame.new(6, 0, 2) * CFrame.Angles(0, DEG(70), 0))
		chestSpot((f * CFrame.new(-8, 0, 11.5)).Position, f.LookVector)
		chestSpot((f * CFrame.new(12, 0, -3)).Position, -f.LookVector)
		lootSpot((f * CFrame.new(2, 0, -6)).Position)
	end

	-- THE WINDMILL on its rise, sacks of grain, a field
	local function mill(pl)
		local c = pl.pos
		local f = CFrame.new(c) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
		K.tower(ctx, c, 6, 18, {color = Color3.fromRGB(206, 196, 176), roof = true, roofColor = Color3.fromRGB(110, 60, 44)})
		local hub = (f * CFrame.new(0, 15, -6.6)).Position
		K.cyl(ctx, "MillHub", 1.6, 1.2, CFrame.new(hub) * f.Rotation * CFrame.Angles(DEG(90), 0, 0), K.C.DARKWOOD, M.Wood)
		for i = 0, 3 do
			local blade = K.box(ctx, "MillSail", V3(2.4, 16, 0.25), CFrame.new(hub) * f.Rotation * CFrame.Angles(0, 0, DEG(i * 90 + 20)) * CFrame.new(0, 8.4, -0.4), Color3.fromRGB(226, 214, 186), M.Fabric)
			blade.CanCollide = false
		end
		for i = 1, 6 do K.sack(ctx, (f * CFrame.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(7, 10))).Position) end
		field(f * CFrame.new(0, 0, 24), 20, 14)
		chestSpot((f * CFrame.new(0, 0, 8)).Position, f.LookVector)
		chestSpot((f * CFrame.new(8, 0, -2)).Position, f.RightVector)
	end

	-- A WATCHTOWER on its height, a rack, a brazier, rocks round it
	local function tower(pl)
		local c = pl.pos
		K.tower(ctx, c, 7, 30, {color = Color3.fromRGB(150, 146, 138), roof = true, roofColor = Color3.fromRGB(70, 60, 54), base = 2, windows = true})
		K.brazier(ctx, c + V3(10, 0, 6))
		pcall(K.rack, ctx, CFrame.new(c + V3(10, 0, -5)))
		for _, a in ipairs({40, 160, 280}) do boulder(at(c.X + math.cos(DEG(a)) * 15, c.Z + math.sin(DEG(a)) * 15, 0.6), rng:NextNumber(3, 5)) end
		chestSpot(c + V3(9.5, 0, 0), V3(1, 0, 0))
		lootSpot(c + V3(-9, 0, 4))
	end

	-- A CAMP: tents round a fire, a palisade, crates and barrels
	local function camp(pl, hunters)
		local c = pl.pos
		local cols = hunters and {Color3.fromRGB(120, 100, 76), Color3.fromRGB(96, 110, 70), Color3.fromRGB(140, 120, 90)} or {Color3.fromRGB(110, 40, 40), Color3.fromRGB(70, 60, 54), Color3.fromRGB(150, 120, 80)}
		for i = 1, 4 do
			local a = i / 4 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
			K.tent(ctx, CFrame.lookAt(c + V3(math.cos(a) * 11, 0, math.sin(a) * 11), c), 7, 8, 5, cols[(i - 1) % 3 + 1])
		end
		K.campfire(ctx, c)
		for i = 1, 5 do
			local p = c + V3(rng:NextNumber(-15, 15), 0, rng:NextNumber(-15, 15))
			if (flat(p - c)).Magnitude > 5 then if i % 2 == 0 then K.barrel(ctx, p) else K.crate(ctx, p, 2.6, rng:NextNumber(0, 90)) end end
		end
		if hunters then
			for i = 1, 3 do K.box(ctx, "HideRack", V3(0.3, 4, 3), CFrame.new(c + V3(-14 + i * 3, 2, 13)), K.C.DARKWOOD, M.Wood, ctx.Props) end
			for i = 1, 3 do log(at(c.X + rng:NextNumber(-12, 12), c.Z + rng:NextNumber(-12, 12)), rng:NextNumber(0, 6.28), rng:NextNumber(6, 9)) end
		else
			local a0 = rng:NextNumber(0, math.pi * 2)
			for i = 0, 3 do
				local p0 = c + V3(math.cos(a0 + i * 1.3) * 21, 0, math.sin(a0 + i * 1.3) * 21)
				local p1 = c + V3(math.cos(a0 + i * 1.3 + 1.0) * 21, 0, math.sin(a0 + i * 1.3 + 1.0) * 21)
				K.palisade(ctx, at(p0.X, p0.Z), at(p1.X, p1.Z), 6)
			end
		end
		chestSpot(c + V3(5, 0, -4), V3(0, 0, 1))
		chestSpot(c + V3(-6, 0, 6), V3(1, 0, 0))
		lootSpot(c + V3(3, 0, 6))
	end

	-- A CHAPEL and its graveyard behind a low wall
	local function chapel(pl)
		local c = pl.pos
		local stone = Color3.fromRGB(196, 190, 176)
		local f = CFrame.new(c) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
		K.house(ctx, f, 14, 22, 12, stone, Color3.fromRGB(90, 60, 50))
		K.tower(ctx, (f * CFrame.new(0, 0, -14)).Position, 4, 24, {color = stone, roof = true, roofColor = Color3.fromRGB(90, 60, 50)})
		for i = 1, 10 do
			local p = f * CFrame.new(rng:NextNumber(-12, 12), 0, rng:NextNumber(15, 25))
			pcall(K.grave, ctx, CFrame.new(at(p.Position.X, p.Position.Z)) * p.Rotation)
		end
		for _, s in ipairs({-1, 1}) do
			local a, b = (f * CFrame.new(s * 15, 0, 13)).Position, (f * CFrame.new(s * 15, 0, 28)).Position
			K.wall(ctx, at(a.X, a.Z), at(b.X, b.Z), 2.2, 1, {color = stone})
		end
		oak(at((f * CFrame.new(-10, 0, 30)).Position.X, (f * CFrame.new(-10, 0, 30)).Position.Z, 0.5), 16)
		chestSpot((f * CFrame.new(0, 0, 12.5)).Position, f.LookVector)
		chestSpot((f * CFrame.new(9, 0, 20)).Position, -f.LookVector)
	end

	-- THE OLD RUINS: broken walls, fallen pillars, a stair to nowhere
	local function ruins(pl)
		local c = pl.pos
		local stone = Color3.fromRGB(140, 138, 130)
		for i = 1, 7 do
			local a = i / 7 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
			local p0 = c + V3(math.cos(a) * 16, 0, math.sin(a) * 16)
			local p1 = p0 + V3(math.cos(a + 1.6) * rng:NextNumber(6, 12), 0, math.sin(a + 1.6) * rng:NextNumber(6, 12))
			K.wall(ctx, p0, V3(p1.X, c.Y, p1.Z), rng:NextNumber(3, 10), 2, {color = stone})
			boulder(V3(p1.X, c.Y - 0.5, p1.Z) + V3(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), rng:NextNumber(2, 4))
		end
		for i = 1, 4 do K.cyl(ctx, "Pillar", 2.6, rng:NextNumber(5, 13), c + V3(rng:NextNumber(-9, 9), 0, rng:NextNumber(-9, 9)) + V3(0, 3, 0), stone, M.Marble) end
		local fallen = K.cyl(ctx, "FallenPillar", 2.6, 12, CFrame.new(c + V3(4, 1.3, -6)) * CFrame.Angles(0, rng:NextNumber(0, 3), DEG(90)), stone, M.Marble)
		fallen.CanCollide = true
		pcall(K.stairs, ctx, CFrame.new(c + V3(-6, 0, 8)), 4, 6, 0.9, 1.3, stone, M.Slate)
		chestSpot(c, V3(0, 0, 1))
		chestSpot(c + V3(9, 0, -7), V3(-1, 0, 0))
		lootSpot(c + V3(-8, 0, -4))
	end

	-- THE STANDING STONES on their hill: a ring of tall stones, an altar in the middle
	local function stones(pl)
		local c = pl.pos
		for i = 1, 9 do
			local a = i / 9 * math.pi * 2
			local p = c + V3(math.cos(a) * 13, 0, math.sin(a) * 13)
			local h = rng:NextNumber(7, 11)
			K.box(ctx, "Monolith", V3(2.4, h, 1.6), CFrame.new(p + V3(0, h / 2 - 0.5, 0)) * CFrame.Angles(DEG(rng:NextNumber(-4, 4)), -a, DEG(rng:NextNumber(-5, 5))), Color3.fromRGB(128, 126, 120), M.Slate)
		end
		K.box(ctx, "Altar", V3(5, 1.6, 3), CFrame.new(c + V3(0, 0.8, 0)), Color3.fromRGB(110, 108, 104), M.Slate)
		chestSpot(c + V3(0, 0, 3), V3(0, 0, 1))
	end

	-- THE MINE in the highlands: a timbered mouth in a rock face, rails, a cart, heaps of ore
	local function mine(pl)
		local c = pl.pos
		local f = CFrame.lookAt(c, V3(HC.X, c.Y, HC.Z))
		-- the hill it goes into (a mound of rock behind the mouth)
		K.box(ctx, "MineRock", V3(26, 14, 14), f * CFrame.new(0, 6, -14), Color3.fromRGB(108, 104, 98), M.Rock)
		K.box(ctx, "MineMouth", V3(7, 8, 6), f * CFrame.new(0, 4, -8), Color3.fromRGB(18, 16, 14), M.SmoothPlastic).CanCollide = false
		for _, s in ipairs({-1, 1}) do K.box(ctx, "MinePost", V3(1, 9, 1), f * CFrame.new(s * 4, 4.5, -5), K.C.DARKWOOD, M.Wood) end
		K.box(ctx, "MineLintel", V3(10, 1, 1.2), f * CFrame.new(0, 9.2, -5), K.C.DARKWOOD, M.Wood)
		for i = 0, 6 do K.box(ctx, "Sleeper", V3(4, 0.3, 0.6), f * CFrame.new(0, 0.15, -6 + i * 2.4), K.C.DARKWOOD, M.Wood, ctx.Props) end
		for _, s in ipairs({-1, 1}) do K.box(ctx, "Rail", V3(0.25, 0.3, 17), f * CFrame.new(s * 1.2, 0.4, 1.2), K.C.IRON, M.Metal, ctx.Props) end
		K.box(ctx, "MineCart", V3(3, 2.2, 4), f * CFrame.new(0, 1.6, 5), Color3.fromRGB(70, 60, 50), M.Wood)
		for i = 1, 5 do K.ball(ctx, "Ore", rng:NextNumber(1.4, 2.6), f * CFrame.new(rng:NextNumber(-9, 9), 0.6, rng:NextNumber(2, 10)), Color3.fromRGB(70, 66, 64), M.Slate, ctx.Props) end
		K.torchPost(ctx, (f * CFrame.new(5.5, 0, -3)).Position, 5)
		chestSpot((f * CFrame.new(-6, 0, 2)).Position, f.LookVector)
		chestSpot((f * CFrame.new(0, 0, -6)).Position, f.LookVector)
		lootSpot((f * CFrame.new(6, 0, 6)).Position)
	end

	-- THE LAKESIDE LODGE: a timber house, a jetty out over the water, a rowing boat
	local function lodge(pl)
		local c = pl.pos
		local toLake = flat(LAKE.c - c).Unit
		local f = CFrame.lookAt(c, c + toLake)
		house(f * CFrame.Angles(0, math.pi, 0), 12, 14, 9)
		local edge = c + toLake * (pl.radius - 4)
		for i = 0, 4 do
			local p = CFrame.lookAt(edge + toLake * (i * 5), edge + toLake * (i * 5 + 1))
			K.box(ctx, "Jetty", V3(4, 0.5, 5.2), p * CFrame.new(0, 0.2, 0), K.C.WOOD, M.WoodPlanks)
			for _, s in ipairs({-1, 1}) do K.cyl(ctx, "Piling", 0.6, 10, p * CFrame.new(s * 1.8, -4.6, 0), K.C.DARKWOOD, M.Wood) end
		end
		K.box(ctx, "Boat", V3(3, 1.2, 7), CFrame.lookAt(edge + toLake * 16, edge + toLake * 17) * CFrame.new(4, lakeLevel - edge.Y - 0.2, 0), Color3.fromRGB(110, 76, 48), M.WoodPlanks).CanCollide = false
		for i = 1, 2 do log(at(c.X + rng:NextNumber(-8, 8), c.Z + rng:NextNumber(-8, 8)), rng:NextNumber(0, 6.28), 7) end
		chestSpot((f * CFrame.new(0, 0, 9)).Position, toLake)
		lootSpot((f * CFrame.new(5, 0, -4)).Position)
	end

	-- THE BRIDGE FORT at the river crossing: two squat towers, a wall, the bridge between
	local function fort(pl)
		local c = pl.pos
		local dr, lvl = riverAt(c.X, c.Z)
		local i0 = 1
		local best = math.huge
		for i = 1, #river - 1 do local d = segDist(c.X, c.Z, river[i].X, river[i].Z, river[i + 1].X, river[i + 1].Z); if d < best then best, i0 = d, i end end
		local along = flat(river[i0 + 1] - river[i0]).Unit
		local across = V3(-along.Z, 0, along.X)
		local stone = Color3.fromRGB(136, 132, 124)
		for _, s in ipairs({-1, 1}) do
			K.tower(ctx, c + across * (s * (RIVER_W + 9)), 6, 18, {color = stone, roof = true, roofColor = Color3.fromRGB(80, 60, 50), base = 2})
		end
		chestSpot(c + across * (RIVER_W + 16), across)
		chestSpot(c - across * (RIVER_W + 16), -across)
		lootSpot(c + across * (RIVER_W + 13) + along * 6)
	end

	local BUILD = {keep = keep, village = village, harbor = harbor, farm = farm, mill = mill, tower = tower,
		camp = function(pl) camp(pl, false) end, hunters = function(pl) camp(pl, true) end, chapel = chapel, ruins = ruins,
		stones = stones, mine = mine, lodge = lodge, fort = fort}
	for n, pl in ipairs(places) do
		local fn = BUILD[pl.kind]
		if fn then
			local ok, err = pcall(fn, pl)
			if not ok then warn("[Realm] place", pl.kind, err) end
		end
		table.insert(L.pois, {name = pl.name, kind = pl.kind, pos = pl.pos, radius = pl.radius})
		table.insert(L.drops, pl.pos)
		K.spawn(ctx, pl.pos + V3(rng:NextNumber(-6, 6), 1, rng:NextNumber(-6, 6)), nil, V3(0, 1, 0))
		if n % 3 == 0 then task.wait() end
	end

	-- BRIDGES where a road crosses the river
	for _, r in ipairs(roads) do
		for i = 1, #river - 1 do
			local p = cross2(r.a, r.b, flat(river[i]), flat(river[i + 1]))
			if p then
				local dir = (r.b - r.a).Unit
				local len = (RIVER_W + 10) * 2 + 4
				local e0, e1 = p - dir * (len / 2), p + dir * (len / 2)
				local y = math.max((ground(e0.X, e0.Z)), (ground(e1.X, e1.Z))) + 0.6
				local f = CFrame.lookAt(V3(p.X, y, p.Z), V3(p.X, y, p.Z) + dir)
				local stone = Color3.fromRGB(150, 146, 138)
				K.box(ctx, "BridgeDeck", V3(7, 1.2, len), f * CFrame.new(0, -0.6, 0), stone, M.Cobblestone)
				for _, s in ipairs({-1, 1}) do K.box(ctx, "BridgeRail", V3(0.8, 1.4, len), f * CFrame.new(s * 3.3, 0.7, 0), stone, M.Cobblestone) end
				local lv = select(2, riverAt(p.X, p.Z)) or SEA
				K.box(ctx, "BridgePier", V3(6, math.max(2, y - lv + 4), 3), CFrame.new(V3(p.X, (y + lv - 4) / 2, p.Z)) * f.Rotation, stone, M.Cobblestone)
				-- (slopes up to it from either bank)
				for _, s in ipairs({-1, 1}) do
					local endp = p + dir * (s * len / 2)
					local gy = (ground(endp.X, endp.Z))
					if y - gy > 0.6 then
						local rampLen = 6
						local mid = endp + dir * (s * rampLen / 2)
						K.wedge(ctx, "BridgeRamp", V3(7, y - gy, rampLen), CFrame.lookAt(V3(mid.X, gy + (y - gy) / 2, mid.Z), V3(mid.X, gy + (y - gy) / 2, mid.Z) - dir * s), stone, M.Cobblestone)
					end
				end
				break
			end
		end
	end

	----------------------------------------------------------------
	-- THE COUNTRY BETWEEN: forests, boulders, bushes, logs, flowers
	----------------------------------------------------------------
	local function clear(p, margin)
		for _, pl in ipairs(places) do if (flat(pl.pos) - p).Magnitude < pl.radius + margin then return false end end
		if roadDist(p.X, p.Z) < 6 then return false end
		if riverAt(p.X, p.Z) < RIVER_W + 5 then return false end
		if (p - flat(LAKE.c)).Magnitude < LAKE.r + 6 then return false end
		return true
	end
	local trees, rocks = 0, 0
	for k = 1, 2600 do
		local a, d = rng:NextNumber(0, math.pi * 2), math.sqrt(rng:NextNumber()) * R
		local p = V3(math.cos(a) * d, 0, math.sin(a) * d)
		local h, w = ground(p.X, p.Z)
		if not w and h > 3.6 and clear(p, 8) then
			local fk = forestK(p.X, p.Z)
			local dense = fk > 0.16
			local roll = rng:NextNumber()
			if (dense and roll < 0.75) or (not dense and roll < 0.1) then
				-- (pines up high and in the woods' heart, oaks lower)
				local pos = V3(p.X, h - 0.5, p.Z)
				if h > 54 then
					if roll < 0.35 then pine(pos, rng:NextNumber(12, 16)) end
				elseif fk > 0.3 or h > 26 then pine(pos, rng:NextNumber(14, 22))
				else oak(pos, rng:NextNumber(12, 18)) end
				trees += 1
			elseif roll < (dense and 0.82 or 0.13) then
				boulder(V3(p.X, h - 0.8, p.Z), rng:NextNumber(2.5, 6))
				rocks += 1
			elseif roll < (dense and 0.9 or 0.17) then
				K.bush(ctx, V3(p.X, h - 0.4, p.Z), rng:NextNumber(2, 3.5))
			elseif roll < (dense and 0.94 or 0.19) then
				log(V3(p.X, h - 0.4, p.Z), rng:NextNumber(0, 6.28), rng:NextNumber(5, 9))
			elseif not dense and roll < 0.22 then
				flowers(V3(p.X, h, p.Z), 6)
			end
		end
		if k % 200 == 0 then task.wait() end
	end
	-- reeds along the river and the lake
	for k = 1, 160 do
		local i = rng:NextInteger(1, #river - 1)
		local t = rng:NextNumber()
		local p = flat(river[i]:Lerp(river[i + 1], t))
		local dir = flat(river[i + 1] - river[i]).Unit
		local side = V3(-dir.Z, 0, dir.X) * (((rng:NextNumber() < 0.5) and 1 or -1) * (RIVER_W + rng:NextNumber(1, 4)))
		local q = p + side
		if flat(q).Magnitude < R * 0.95 then
			local h = (ground(q.X, q.Z))
			local reed = K.box(ctx, "Reed", V3(0.2, rng:NextNumber(2, 3.4), 0.2), CFrame.new(q.X, h + 1.2, q.Z) * CFrame.Angles(DEG(rng:NextNumber(-10, 10)), 0, DEG(rng:NextNumber(-10, 10))), Color3.fromRGB(120, 140, 70), M.Grass, ctx.Props)
			reed.CanCollide = false
		end
	end
	print(string.format("[Realm] %d places, %d roads, %d trees, %d rocks", #places, #roads, trees, rocks))

	-- menu shots: over the keep, over the island
	K.camera(ctx, V3(90, 90, 90), V3(0, 10, 0))
	K.camera(ctx, V3(-R * 0.85, 140, -R * 0.4), V3(0, 0, 0))
	K.lighting(ctx, {ClockTime = 15.5, Brightness = 2.2, Ambient = Color3.fromRGB(110, 110, 120), OutdoorAmbient = Color3.fromRGB(130, 130, 140), FogEnd = 1400, FogStart = 400, FogColor = Color3.fromRGB(180, 196, 214)})
	K.atmosphere(ctx, {Density = 0.26, Offset = 0.1, Color = Color3.fromRGB(200, 214, 230), Decay = Color3.fromRGB(110, 120, 140), Glare = 0.2, Haze = 1.1})
	ctx.model:SetAttribute("Generated", true)
	ctx.model:SetAttribute("Realm", true)
	-- (an island in a summer sea: the sea runs on to the sky, Game ▸ Horizon)
	ctx.model:SetAttribute("Island", true)
	ctx.model:SetAttribute("HorizonTheme", "summer")
	ctx.model:SetAttribute("SeaLevel", SEA)
	local okF, errF = pcall(K.finish, ctx)
	if not okF then
		warn("[Realm] finish:", errF)
		local maps = ServerStorage:FindFirstChild("Maps") or Instance.new("Folder")
		maps.Name = "Maps"; maps.Parent = ServerStorage
		ctx.model.Parent = maps
	end
	L.name = name
	return name, L
end

return Realm
