--[[ REALM — builds Crownfall's island from nothing every match (Game ▸ Modes ▸ Crownfall).

       Realm.build(opts) -> mapName, layout
         opts.radius   the island's (300)
         opts.seed     a number (random otherwise)
         opts.name     its name in ServerStorage ▸ Maps (Gen_Realm_<n> otherwise)

     Terrain (grass on a sand beach in a sea, a few round hills), and its PLACES, each with a name
     and chests: the Crown Keep in the middle (walls, towers, a courtyard), villages (houses, a
     well, fences), a mill, a watchtower, camps (tents, a fire, crates), a chapel and its graves,
     ruins. Forests and rocks between them. It lands in ServerStorage ▸ Maps like any map.

       layout.pois   = {{name, kind, pos (Vector3), radius}}
       layout.chests = {CFrame…} (on the ground, facing out)
       layout.drops  = {Vector3…} (where you can come down: every place)
       layout.radius, layout.centre ]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Build = ServerScriptService:WaitForChild("Build")
local K = require(Build:WaitForChild("MapKit"))
if not K.wagon then require(Build:WaitForChild("MapProps"))(K) end   -- (the campfire, the wagon: Build ▸ MapProps)
local Realm = {}
local made = 0
local DEG = math.rad
local V3 = Vector3.new

local NAMES = {
	village = {"Ashford", "Millbrook", "Thornvale", "Oakhollow", "Briar's End", "Cobblecross", "Wrenfield", "Hartsdale"},
	camp = {"Bandit Camp", "the Hunters' Rest", "Smugglers' Den", "Wolfpine Camp"},
	chapel = {"Saint Aldric's", "the Grey Chapel", "Bellrest", "the Quiet Graves"},
	ruins = {"the Old Ruins", "Fallen Hall", "Brokenstone", "the Sunken Court"},
	mill = {"the Old Mill", "Windmere", "Grindstone"},
	tower = {"Raven Tower", "the Old Watch", "Highlook", "Stormwatch"},
}

local function pick(rng, list) return list[rng:NextInteger(1, #list)] end

--------------------------------------------------------------------
--  PLACES
--------------------------------------------------------------------
local function chestSpot(L, pos, face)
	table.insert(L.chests, CFrame.lookAt(pos, pos + (face or V3(0, 0, -1))))
end

local function village(ctx, L, c, rng)
	local walls = {Color3.fromRGB(226, 214, 190), Color3.fromRGB(206, 184, 150), Color3.fromRGB(190, 170, 140)}
	local roofs = {Color3.fromRGB(110, 60, 44), Color3.fromRGB(80, 64, 52), Color3.fromRGB(150, 110, 60)}
	local n = rng:NextInteger(3, 5)
	for i = 1, n do
		local a = (i / n) * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
		local d = rng:NextNumber(16, 22)
		local at = c + V3(math.cos(a) * d, 0, math.sin(a) * d)
		local frame = CFrame.lookAt(at, V3(c.X, 0, c.Z)) * CFrame.Angles(0, math.pi, 0)
		K.house(ctx, frame, rng:NextInteger(9, 12), rng:NextInteger(10, 13), rng:NextInteger(7, 9), walls[rng:NextInteger(1, 3)], roofs[rng:NextInteger(1, 3)])
		-- a chest round the back of every other house
		if i % 2 == 1 then chestSpot(L, (frame * CFrame.new(0, 0, -8.5)).Position, V3(c.X, 0, c.Z) - at) end
	end
	-- the well in the middle, fences, barrels, carts of hay
	K.cyl(ctx, "Well", 4, 2.4, c + V3(0, 1.2, 0), K.C.STONE, Enum.Material.Cobblestone)
	K.box(ctx, "WellBeam", V3(4.6, 0.4, 0.4), CFrame.new(c + V3(0, 5, 0)), K.C.DARKWOOD, Enum.Material.Wood)
	for _, s in ipairs({-1, 1}) do K.box(ctx, "WellPost", V3(0.4, 5, 0.4), CFrame.new(c + V3(s * 2, 2.5, 0)), K.C.DARKWOOD, Enum.Material.Wood) end
	chestSpot(L, c + V3(4, 0, 4), V3(1, 0, 1))
	for i = 1, 3 do
		local a = rng:NextNumber(0, math.pi * 2)
		local at = c + V3(math.cos(a) * 9, 0, math.sin(a) * 9)
		if i == 1 then K.barrel(ctx, at) elseif i == 2 then K.crate(ctx, at, 3, rng:NextNumber(0, 90)) else K.hay(ctx, at) end
	end
	local fa = rng:NextNumber(0, math.pi * 2)
	K.fence(ctx, c + V3(math.cos(fa) * 28, 0, math.sin(fa) * 28), c + V3(math.cos(fa + 0.6) * 28, 0, math.sin(fa + 0.6) * 28), 2.4)
end

local function keep(ctx, L, c, rng)
	local stone = Color3.fromRGB(150, 146, 138)
	local r = 34
	for i = 0, 3 do
		local a0 = i / 4 * math.pi * 2 + math.pi / 4
		local a1 = (i + 1) / 4 * math.pi * 2 + math.pi / 4
		local p0 = c + V3(math.cos(a0) * r, 0, math.sin(a0) * r)
		local p1 = c + V3(math.cos(a1) * r, 0, math.sin(a1) * r)
		-- each wall has a gate gap in its middle
		local mid = (p0 + p1) / 2
		local dir = (p1 - p0).Unit
		K.wall(ctx, p0, mid - dir * 6, 11, 2.5, {crenels = true, color = stone, base = true})
		K.wall(ctx, mid + dir * 6, p1, 11, 2.5, {crenels = true, color = stone, base = true})
		K.arch(ctx, CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.pi / 2, 0), 12, 11, 2.5, stone)
		K.tower(ctx, p0, 6, 18, {color = stone, roof = true, roofColor = Color3.fromRGB(120, 40, 40)})
	end
	-- the hall in the middle and its banners
	K.house(ctx, CFrame.new(c) * CFrame.Angles(0, DEG(rng:NextInteger(0, 3) * 90), 0), 16, 20, 12, stone, Color3.fromRGB(110, 40, 40))
	for _, a in ipairs({0, 90, 180, 270}) do
		local at = c + V3(math.cos(DEG(a)) * 18, 0, math.sin(DEG(a)) * 18)
		K.banner(ctx, at, 10, Color3.fromRGB(200, 160, 40))
		chestSpot(L, c + V3(math.cos(DEG(a + 45)) * 22, 0, math.sin(DEG(a + 45)) * 22), c - at)
	end
end

local function camp(ctx, L, c, rng)
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2
		K.tent(ctx, CFrame.lookAt(c + V3(math.cos(a) * 10, 0, math.sin(a) * 10), c), 7, 8, 5, ({Color3.fromRGB(150, 120, 80), Color3.fromRGB(110, 90, 70), Color3.fromRGB(170, 150, 110)})[i])
	end
	if K.campfire then K.campfire(ctx, c) else K.torchPost(ctx, c, 2) end
	for i = 1, 4 do K.crate(ctx, c + V3(rng:NextNumber(-14, 14), 0, rng:NextNumber(-14, 14)), 2.5, rng:NextNumber(0, 90)) end
	K.palisade(ctx, c + V3(-18, 0, -16), c + V3(18, 0, -16), 6)
	chestSpot(L, c + V3(5, 0, -4), V3(0, 0, 1))
	chestSpot(L, c + V3(-6, 0, 6), V3(1, 0, 0))
end

local function chapel(ctx, L, c, rng)
	local stone = Color3.fromRGB(196, 190, 176)
	local f = CFrame.new(c) * CFrame.Angles(0, DEG(rng:NextInteger(0, 3) * 90), 0)
	K.box(ctx, "Nave", V3(14, 12, 22), f * CFrame.new(0, 6, 0), stone, Enum.Material.Cobblestone)
	K.wedge(ctx, "NaveRoof", V3(14, 6, 22), f * CFrame.new(0, 15, 0), Color3.fromRGB(90, 60, 50), Enum.Material.WoodPlanks)
	K.tower(ctx, (f * CFrame.new(0, 0, -13)).Position, 4, 22, {color = stone, roof = true, roofColor = Color3.fromRGB(90, 60, 50)})
	for i = 1, 8 do
		local at = (f * CFrame.new(rng:NextNumber(-14, 14), 0, rng:NextNumber(14, 24))).Position
		K.box(ctx, "Grave", V3(1.8, 2.4, 0.5), CFrame.new(at + V3(0, 1.2, 0)) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.15, 0.15)), Color3.fromRGB(150, 150, 146), Enum.Material.Slate)
	end
	chestSpot(L, (f * CFrame.new(0, 0, 13)).Position, f.LookVector)
	chestSpot(L, (f * CFrame.new(9, 0, 18)).Position, -f.LookVector)
end

local function ruins(ctx, L, c, rng)
	local stone = Color3.fromRGB(140, 138, 130)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local p0 = c + V3(math.cos(a) * 14, 0, math.sin(a) * 14)
		local p1 = p0 + V3(math.cos(a + 1.6) * rng:NextNumber(6, 12), 0, math.sin(a + 1.6) * rng:NextNumber(6, 12))
		K.wall(ctx, p0, p1, rng:NextNumber(3, 9), 2, {color = stone})
		K.rock(ctx, p1 + V3(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), rng:NextNumber(2, 4), Color3.fromRGB(120, 118, 112))
	end
	for i = 1, 3 do K.cyl(ctx, "BrokenPillar", 2.6, rng:NextNumber(4, 12), c + V3(rng:NextNumber(-8, 8), 3, rng:NextNumber(-8, 8)), stone, Enum.Material.Marble) end
	chestSpot(L, c + V3(0, 0, 0), V3(0, 0, 1))
	chestSpot(L, c + V3(8, 0, -6), V3(-1, 0, 0))
end

local function mill(ctx, L, c, rng)
	local f = CFrame.new(c) * CFrame.Angles(0, DEG(rng:NextNumber(0, 360)), 0)
	K.tower(ctx, c, 6, 16, {color = Color3.fromRGB(200, 190, 170), roof = true, roofColor = Color3.fromRGB(110, 60, 44)})
	local hub = (f * CFrame.new(0, 13, -6.4)).Position
	for i = 0, 3 do
		local blade = K.box(ctx, "MillBlade", V3(1.6, 14, 0.3), CFrame.new(hub) * f.Rotation * CFrame.Angles(0, 0, DEG(i * 90 + 20)) * CFrame.new(0, 7, 0), Color3.fromRGB(200, 186, 150), Enum.Material.WoodPlanks)
		blade.CanCollide = false
	end
	for i = 1, 4 do K.hay(ctx, c + V3(rng:NextNumber(-16, 16), 0, rng:NextNumber(8, 18))) end
	K.house(ctx, f * CFrame.new(16, 0, 6), 9, 10, 7, Color3.fromRGB(214, 200, 170), Color3.fromRGB(110, 60, 44))
	chestSpot(L, (f * CFrame.new(0, 0, 8)).Position, f.LookVector)
	chestSpot(L, (f * CFrame.new(16, 0, -2)).Position, -f.LookVector)
end

local function watchtower(ctx, L, c, rng)
	K.tower(ctx, c, 7, 28, {color = Color3.fromRGB(150, 146, 138), roof = true, roofColor = Color3.fromRGB(70, 60, 54), base = 2})
	for _, a in ipairs({30, 150, 270}) do
		K.rock(ctx, c + V3(math.cos(DEG(a)) * 13, 0, math.sin(DEG(a)) * 13), 4)
	end
	K.rack(ctx, CFrame.new(c + V3(10, 0, -4)))
	chestSpot(L, c + V3(9, 0, 4), V3(0, 0, 1))
	chestSpot(L, c + V3(-9, 0, -3), V3(1, 0, 0))
end

local BUILD = {village = village, camp = camp, chapel = chapel, ruins = ruins, mill = mill, tower = watchtower}

--------------------------------------------------------------------
--  THE ISLAND
--------------------------------------------------------------------
function Realm.build(opts)
	opts = opts or {}
	local R = opts.radius or 300
	local rng = Random.new(opts.seed or math.random(1, 2 ^ 30))
	made += 1
	local name = opts.name or ("Gen_Realm_" .. made)
	local ctx = K.new(name)
	local L = {pois = {}, chests = {}, drops = {}, radius = R, centre = V3(0, 0, 0)}

	-- where things go: the keep in the middle, the rest round two rings
	local places = {{kind = "keep", pos = V3(0, 0, 0), radius = 40, name = "the Crown Keep"}}
	local kinds = {"village", "village", "village", "mill", "tower", "camp", "camp", "chapel", "ruins", "tower"}
	local used = {}
	for i, kind in ipairs(kinds) do
		local ring = (i % 2 == 0) and 0.42 or 0.72
		local a = (i / #kinds) * math.pi * 2 + rng:NextNumber(-0.18, 0.18)
		local d = R * ring + rng:NextNumber(-12, 12)
		local nm
		for _ = 1, 10 do nm = pick(rng, NAMES[kind]); if not used[nm] then break end end
		used[nm] = true
		table.insert(places, {kind = kind, pos = V3(math.cos(a) * d, 0, math.sin(a) * d), radius = kind == "village" and 30 or 22, name = nm})
	end

	-- terrain: sea, a beach, grass, a few hills away from the places
	local hills = {}
	for _ = 1, 7 do
		for _try = 1, 20 do
			local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(R * 0.2, R * 0.85)
			local p = V3(math.cos(a) * d, 0, math.sin(a) * d)
			local ok = true
			for _, pl in ipairs(places) do if (pl.pos - p).Magnitude < pl.radius + 34 then ok = false end end
			for _, h in ipairs(hills) do if (h - p).Magnitude < 50 then ok = false end end
			if ok then table.insert(hills, p); break end
		end
	end
	local size = V3(R * 2 + 120, 48, R * 2 + 120)
	K.terrain(ctx, V3(-size.X / 2, -24, -size.Z / 2), size, function(b)
		b:FillBlock(CFrame.new(0, -14, 0), V3(size.X - 8, 10, size.Z - 8), Enum.Material.Water)
		-- (the beach a voxel lower than the grass: a voxel both end in keeps the first one's
		-- material, so they mustn't share the top one; a low bank at the shore)
		b:FillCylinder(CFrame.new(0, -6.5, 0), 8, R + 16, Enum.Material.Sand)
		b:FillCylinder(CFrame.new(0, -3.5, 0), 7, R, Enum.Material.Grass)
		for _, h in ipairs(hills) do
			b:Mound(h, rng:NextNumber(8, 16), rng:NextNumber(4, 10), rng:NextNumber(22, 34), Enum.Material.Grass)
		end
		-- a dirt road from every place to the keep
		for _, pl in ipairs(places) do
			if pl.kind ~= "keep" then
				local dir = (V3(0, 0, 0) - pl.pos)
				local len = dir.Magnitude
				b:FillBlock(CFrame.lookAt(pl.pos + dir / 2 + V3(0, -0.4, 0), V3(0, -0.4, 0)), V3(7, 1.4, len), Enum.Material.Ground)
			end
		end
	end)
	K.terrainColors(ctx, {Grass = Color3.fromRGB(96, 146, 70), Sand = Color3.fromRGB(214, 196, 150), Ground = Color3.fromRGB(110, 90, 66)})

	-- the places
	for _, pl in ipairs(places) do
		local fn = BUILD[pl.kind] or (pl.kind == "keep" and keep)
		if fn then
			local ok, err = pcall(fn, ctx, L, pl.pos, rng)
			if not ok then warn("[Realm] place", pl.kind, err) end
		end
		table.insert(L.pois, {name = pl.name, kind = pl.kind, pos = pl.pos, radius = pl.radius})
		table.insert(L.drops, pl.pos)
		K.spawn(ctx, pl.pos + V3(rng:NextNumber(-8, 8), 1, rng:NextNumber(-8, 8)), nil, V3(0, 1, 0))
	end
	-- forests and rocks between
	for _ = 1, 90 do
		for _try = 1, 6 do
			local a, d = rng:NextNumber(0, math.pi * 2), math.sqrt(rng:NextNumber()) * (R - 14)
			local p = V3(math.cos(a) * d, 0, math.sin(a) * d)
			local ok = true
			for _, pl in ipairs(places) do if (pl.pos - p).Magnitude < pl.radius + 6 then ok = false end end
			for _, h in ipairs(hills) do if (h - p).Magnitude < 20 then ok = false end end
			if ok then
				if rng:NextNumber() < 0.82 then K.tree(ctx, p, rng:NextNumber(11, 18), rng:NextNumber() < 0.5 and K.C.LEAFDARK or nil)
				else K.rock(ctx, p, rng:NextNumber(3, 6)) end
				break
			end
		end
	end
	-- menu shots: over the keep, over the island
	K.camera(ctx, V3(70, 60, 70), V3(0, 4, 0))
	K.camera(ctx, V3(-R * 0.8, 90, -R * 0.4), V3(0, 0, 0))
	K.lighting(ctx, {ClockTime = 15.5, Brightness = 2.2, Ambient = Color3.fromRGB(110, 110, 120), OutdoorAmbient = Color3.fromRGB(130, 130, 140), FogEnd = 900, FogStart = 300, FogColor = Color3.fromRGB(180, 196, 214)})
	K.atmosphere(ctx, {Density = 0.28, Offset = 0.1, Color = Color3.fromRGB(200, 214, 230), Decay = Color3.fromRGB(110, 120, 140), Glare = 0.2, Haze = 1.2})
	ctx.model:SetAttribute("Generated", true)
	ctx.model:SetAttribute("Realm", true)
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
