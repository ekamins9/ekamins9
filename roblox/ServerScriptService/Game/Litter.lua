--[[ LITTER — what earlier fighting leaves on a field, set down on whatever ground is there: round
     shields dropped face up (the two houses' arms on them: ReplicatedStorage ▸ Houses) or face down
     on their straps, spears snapped in two, volleys of arrows still standing in the turf and all
     leaning back the way they flew, a banner trampled with its pole, helmets. Looks only (no
     collision, no queries, no touches): blades, rays and feet pass through it.

       Litter.scatter(parent, sample, counts [, opts])
           sample()   -> a Vector3 (x, z where it goes; y is found by a ray down onto the ground),
                         or nil to skip one
           counts     {shields, spears, arrows (clusters), banners, helms} (any left out: none)
           opts       seed      a number: the same field every time (else a fresh one)
                      houses    the map's HouseSeed: whose arms the shields and banners carry
                      from      a flat Vector3: where the volleys came from (else each its own)
                      terrain   true: only bare ground (terrain, not water: never a floor, a
                                bridge, a roof or a wall top)
                      trample   false: leave the grass (else the turf under each heap is
                                trodden to bare earth, or the grass would hide it all)

     Every map with land round it gets a field of it as it loads (MapLoader ▸ Litter.field); War's
     fields have their own (Game ▸ WarMap ▸ debris); Siege adds the field before its castle
     (Game ▸ Modes ▸ Siege). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Litter = {}

local V3, CF, DEG = Vector3.new, CFrame.new, math.rad
local M = Enum.Material
local WOOD, DARK, SHAFT, LEATHER, IRON = Color3.fromRGB(96, 74, 52), Color3.fromRGB(62, 44, 30), Color3.fromRGB(128, 98, 64), Color3.fromRGB(86, 58, 38), Color3.fromRGB(122, 124, 130)
local FLETCH = {Color3.fromRGB(226, 220, 206), Color3.fromRGB(150, 40, 36), Color3.fromRGB(40, 40, 44)}
local GILT, INK = Color3.new(1.06, 0.84, 0.4), Color3.fromRGB(28, 22, 20)
local WATER = {[M.Water] = true, [M.Air] = true}
local GRASSY = {[M.Grass] = true, [M.LeafyGrass] = true}

local function piece(parent, name, size, cf, color, mat, ball, cyl)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	if ball then p.Shape = Enum.PartType.Ball elseif cyl then p.Shape = Enum.PartType.Cylinder end
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.CastShadow = math.min(size.X, size.Y, size.Z) > 0.15
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
-- a pole along cf's Y
local function pole(parent, name, len, dia, cf, color, mat)
	return piece(parent, name, V3(len, dia, dia), cf * CFrame.Angles(0, 0, math.pi / 2), color, mat, false, true)
end
-- a house's arms on a clear plate lying on something (its outline, then the emblem in gold)
local function arms(parent, cf, size, emblem)
	local art = ReplicatedStorage:FindFirstChild("ShieldArt")
	local v = emblem and art and art:FindFirstChild(emblem)
	if not v or v.Value == "" then return end
	local pl = piece(parent, "LitterArms", V3(size, 0.02, size), cf, Color3.new(), M.SmoothPlastic)
	pl.Transparency = 1
	pl.CastShadow = false
	local o = art:FindFirstChild(emblem .. "_o")
	for z, l in ipairs({{o and o.Value, INK}, {v.Value, GILT}}) do
		if l[1] and l[1] ~= "" then
			local d = Instance.new("Decal")
			d.Face = Enum.NormalId.Top
			d.Texture = l[1]; d.Color3 = l[2]; d.ZIndex = z
			d.Parent = pl
		end
	end
end

-- the two sides' colours and, on a map, their houses' emblems
local function sidesOf(houseSeed)
	local out = {}
	local okG, GameConfig = pcall(require, ReplicatedStorage:WaitForChild("GameConfig"))
	local okH, Houses = pcall(require, ReplicatedStorage:WaitForChild("Houses"))
	for _, k in ipairs({"A", "B"}) do
		local t = okG and GameConfig.TEAMS and GameConfig.TEAMS[k]
		local col = t and t.rgb or (k == "A" and Color3.fromRGB(56, 92, 206) or Color3.fromRGB(190, 50, 44))
		table.insert(out, {color = col, emblem = okH and houseSeed and Houses.forColor(col, houseSeed) or nil})
	end
	return out
end

function Litter.scatter(parent, sample, counts, opts)
	counts, opts = counts or {}, opts or {}
	local folder = Instance.new("Folder")
	folder.Name = "Litter"
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = {folder, workspace:FindFirstChild("NPCs") or folder}
	local rng = opts.seed and Random.new(opts.seed) or Random.new()
	local sides = sidesOf(opts.houses)
	local function ground(at)
		at = at or sample()
		if not at then return nil end
		local r = workspace:Raycast(V3(at.X, at.Y + 80, at.Z), V3(0, -200, 0), ray)
		-- (only open, level-ish ground: not a cliff; with opts.terrain only bare earth)
		if not r or r.Normal.Y < 0.85 then return nil end
		if opts.terrain and (r.Instance ~= workspace.Terrain or WATER[r.Material]) then return nil end
		return r.Position, r.Material
	end
	-- the turf trodden to earth round a heap (only grass: its blades would hide what lies there)
	local function trample(at, mat, rad)
		if opts.trample == false or not GRASSY[mat] then return end
		local reg = Region3.new(at - V3(rad, 4, rad), at + V3(rad, 4, rad)):ExpandToGrid(4)
		pcall(function()
			workspace.Terrain:ReplaceMaterial(reg, 4, M.Grass, M.Ground)
			workspace.Terrain:ReplaceMaterial(reg, 4, M.LeafyGrass, M.Ground)
		end)
	end
	local function flat() return CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0) end

	-- SHIELDS: round, face up with a side's arms and a boss, or face down on its straps
	for _ = 1, counts.shields or 0 do
		local at, mat = ground()
		if at then
			trample(at, mat, 4.5)
			local s = sides[rng:NextInteger(1, #sides)]
			local d = rng:NextNumber(2.6, 3.2)
			local cf = CF(at + V3(0, 0.16, 0)) * flat() * CFrame.Angles(DEG(rng:NextNumber(-7, 7)), 0, DEG(rng:NextNumber(-7, 7)))
			if rng:NextNumber() < 0.65 then
				pole(folder, "DroppedShield", 0.22, d, cf, s.color, M.Wood)
				pole(folder, "ShieldRim", 0.18, d + 0.14, cf * CF(0, -0.04, 0), DARK, M.Wood)
				piece(folder, "ShieldBoss", V3(0.7, 0.7, 0.7), cf * CF(0, 0.12, 0), IRON, M.Metal, true)
				arms(folder, cf * CF(0, 0.125, 0), d * 0.7, s.emblem)
			else
				pole(folder, "DroppedShield", 0.22, d, cf, WOOD, M.Wood)
				piece(folder, "ShieldStrap", V3(d * 0.7, 0.06, 0.22), cf * CF(0, 0.13, 0.35), LEATHER, M.Leather)
				piece(folder, "ShieldStrap", V3(d * 0.7, 0.06, 0.22), cf * CF(0, 0.13, -0.35), LEATHER, M.Leather)
			end
		end
	end
	-- SPEARS: snapped, the head end and the butt apart
	for _ = 1, counts.spears or 0 do
		local at, mat = ground()
		if at then
			trample(at, mat, 5.5)
			local len = rng:NextNumber(6, 9)
			local base = CF(at + V3(0, 0.12, 0)) * flat()
			local brk = len * rng:NextNumber(0.45, 0.65)
			local head = base * CF(brk / 2, 0, 0) * CFrame.Angles(0, 0, math.pi / 2)
			pole(folder, "BrokenSpear", brk, 0.2, head, SHAFT, M.Wood)
			piece(folder, "SpearHead", V3(0.08, 0.9, 0.3), base * CF(brk + 0.4, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), IRON, M.Metal)
			local rest = len - brk
			local butt = base * CF(-0.4, 0, 0) * CFrame.Angles(0, DEG(rng:NextNumber(20, 50)), 0) * CF(-rest / 2, 0, 0) * CFrame.Angles(0, 0, math.pi / 2)
			pole(folder, "BrokenSpear", rest, 0.2, butt, SHAFT, M.Wood)
		end
	end
	-- ARROWS: a volley come down, standing in the ground, all leaning back the way it flew
	for _ = 1, counts.arrows or 0 do
		local at, mat = ground()
		if at then
			trample(at, mat, 5.5)
			local fa = rng:NextNumber(0, math.pi * 2)
			local from = opts.from and opts.from.Unit or V3(math.cos(fa), 0, math.sin(fa))
			local fl = FLETCH[rng:NextInteger(1, #FLETCH)]
			for _ = 1, rng:NextInteger(5, 9) do
				local g = ground(at + V3(rng:NextNumber(-3.2, 3.2), 0, rng:NextNumber(-3.2, 3.2)))
				if g then
					local lean = DEG(rng:NextNumber(22, 38))
					local axis = (V3(0, math.cos(lean), 0) + from * math.sin(lean) + V3(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.08, 0.08))).Unit
					local len = 3
					local c = g + axis * (len / 2 - 0.55)
					local cf = CFrame.lookAt(c, c + axis) * CFrame.Angles(-math.pi / 2, 0, 0)
					pole(folder, "SpentArrow", len, 0.09, cf, SHAFT, M.Wood)
					local top = cf * CF(0, len / 2 - 0.32, 0) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0)
					piece(folder, "SpentFletch", V3(0.03, 0.5, 0.26), top, fl, M.Fabric)
					piece(folder, "SpentFletch", V3(0.26, 0.5, 0.03), top, fl, M.Fabric)
				end
			end
		end
	end
	-- BANNERS: down in the mud with their poles, a side's colours and arms
	for _ = 1, counts.banners or 0 do
		local at, mat = ground()
		if at then
			trample(at, mat, 6)
			local s = sides[rng:NextInteger(1, #sides)]
			local base = CF(at + V3(0, 0.12, 0)) * flat()
			pole(folder, "FallenStandard", 9, 0.22, base * CFrame.Angles(0, 0, math.pi / 2), DARK, M.Wood)
			local top = base * CF(3.2, 0.02, 0)
			pole(folder, "FallenStandard", 3, 0.16, top * CF(0, 0, 0) * CFrame.Angles(math.pi / 2, 0, 0), DARK, M.Wood)
			local cloth = top * CF(-1.75, -0.02, 0) * CFrame.Angles(0, DEG(rng:NextNumber(-12, 12)), DEG(rng:NextNumber(-4, 4)))
			piece(folder, "FallenBanner", V3(3.3, 0.06, 2.6), cloth, s.color, M.Fabric)
			arms(folder, cloth * CF(0, 0.04, 0), 2.0, s.emblem)
		end
	end
	-- HELMS: dropped, half sunk, a brim or a nasal
	for _ = 1, counts.helms or 0 do
		local at, mat = ground()
		if at then
			trample(at, mat, 3.5)
			local cf = CF(at + V3(0, 0.25, 0)) * flat() * CFrame.Angles(DEG(rng:NextNumber(-35, 35)), 0, DEG(rng:NextNumber(-35, 35)))
			piece(folder, "DroppedHelm", V3(1.3, 1.3, 1.3), cf, Color3.fromRGB(150, 152, 158), M.Metal, true)
			if rng:NextNumber() < 0.5 then
				pole(folder, "HelmBrim", 0.08, 2, cf * CF(0, -0.1, 0), Color3.fromRGB(132, 134, 140), M.Metal)
			else
				piece(folder, "HelmNasal", V3(0.14, 0.8, 0.08), cf * CF(0, -0.15, -0.62), Color3.fromRGB(132, 134, 140), M.Metal)
			end
		end
	end
	folder.Parent = parent
	return folder
end

-- a battle map as it loads (MapLoader: only the maps with land round them): its open ground strewn
-- with the last fight, the same every time; the volleys all came from one side
function Litter.field(map, houseSeed)
	local c, r = map:GetAttribute("Centre"), map:GetAttribute("Radius")
	if typeof(c) ~= "Vector3" or type(r) ~= "number" then return nil end
	local seed = 0
	for i = 1, #(houseSeed or "") do seed = (seed * 31 + string.byte(houseSeed, i)) % 2147483647 end
	local rng = Random.new(seed + 7)
	-- (never on a spawn)
	local spawns = {}
	for _, p in ipairs(map:FindFirstChild("Spawns") and map.Spawns:GetDescendants() or {}) do
		if p:IsA("BasePart") then table.insert(spawns, p.Position) end
	end
	local function sample()
		local a, d = rng:NextNumber(0, math.pi * 2), r * 0.92 * math.sqrt(rng:NextNumber())
		local p = V3(c.X + math.cos(a) * d, c.Y + 60, c.Z + math.sin(a) * d)
		for _, s in ipairs(spawns) do
			if (V3(s.X, 0, s.Z) - V3(p.X, 0, p.Z)).Magnitude < 12 then return nil end
		end
		return p
	end
	local k = math.clamp(r / 60, 0.6, 2.2)
	local a = rng:NextNumber(0, math.pi * 2)
	return Litter.scatter(map, sample, {shields = math.floor(12 * k), spears = math.floor(9 * k), arrows = math.floor(8 * k),
		banners = math.floor(2 * k), helms = math.floor(5 * k)}, {seed = seed, houses = houseSeed, terrain = true, from = V3(math.cos(a), 0, math.sin(a))})
end

return Litter
