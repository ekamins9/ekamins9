--[[ HORIZON — the land round every outdoor map, so none of them floats in the fog: built when
     MapLoader loads a map out of ServerStorage ▸ Maps, cleared when it goes. Beside the map, not in
     it (workspace ▸ MapHorizon, Persistent: every screen sees it however far off it is).

       • a SKIRT of the map's own terrain round its square, flush with its ground, so the edge
         runs on into country (mounds, rocky outcrops, the theme's mud or lava patches, pools)
       • the PLAIN beyond, out past the haze, and rolling HILLS rising out of it, with far
         MOUNTAINS behind (snow-capped in winter, mesas in the desert, black cones by the ember maps)
       • WOODS in the theme's trees, in groves
       • a fighting map has the ARMIES' CAMPS outside it (tents, banners in both colours, fires);
         a village, a clearing or ruins has a VILLAGE down a road instead, and fields
       • a CASTLE on a far hill, and SMOKE rising off on the horizon (burning farms on a war map,
         chimneys on a quiet one; more of it on the ash and ember maps)

     The look comes from the map's theme (its Theme attribute: Build ▸ MapForge's THEMES; the
     hand-made maps are named in HAND below). A map with NoHorizon = true is left alone (the
     Courtyard has its own: Game ▸ HubBackdrop).

       Horizon.build(map, name)    Horizon.clear() ]]

local ServerScriptService = game:GetService("ServerScriptService")
local Build = ServerScriptService:WaitForChild("Build")
local K = require(Build:WaitForChild("MapKit"))
if not K.campfire then require(Build:WaitForChild("MapProps"))(K) end

local Horizon = {}
local V3, CF, DEG = Vector3.new, CFrame.new, math.rad
local Mat = Enum.Material
local RGB = Color3.fromRGB
local SKIRT = 360                 -- the terrain band's width round the map's square (its outer half rolls in hills)
local SKIP = {Courtyard = true}
-- the hand-made maps' looks (a MapForge theme each)
local HAND = {
	Colosseum = "desert", Frostgate = "winter", Highbridge = "dawnMist", Millfield = "summer", Ravenhold = "nightForest",
	RoseCourt = "spring", Sandpit = "desert", Stormbreak = "stormNight", TrainingYard = "summer", Wildwood = "summer",
}
-- the War mode's battlefields (Game ▸ WarMap, its W_Theme): the nearest MapForge look
local WAR = {
	Redfield = "summer", Ironridge = "stormNight", Frostmere = "winter", Ashvale = "ash", Kingsbridge = "summer",
	Nightfall = "nightForest", Sunreach = "desert", Stormvale = "stormNight", Duskmoor = "autumn", Mistmarsh = "swamp", Amberwood = "autumn",
}
-- the layouts that are a fight in a war (camps outside), and the rest (a village down the road)
local WARLIKE = {siege = true, warfield = true, arena = true, bailey = true, bridge = true}
local TEAM = {RGB(56, 92, 206), RGB(190, 50, 44)}
local bands = {}                  -- the skirt's terrain boxes, to clear

local function themeOf(map, name)
	local ok, F = pcall(require, Build:WaitForChild("MapForge"))
	local themes = ok and F.THEMES or {}
	-- (only the outdoor battlegrounds: a map named nowhere here makes its own world: the dungeons,
	--  the Gilded Rat, Crownlands, the Caldera, the prologue's Stormwatch)
	local key = map:GetAttribute("Theme") or WAR[map:GetAttribute("W_Theme") or ""] or HAND[name]
	if not key then return nil, nil end
	return themes[key] or themes.summer, key
end

-- the ground's height round the map's edge: what most of the edge stands at
local function edgeHeight(map, c, ex, ez)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Terrain}
	local ys = {}
	for i = 0, 31 do
		local a = i / 32 * math.pi * 2
		-- (on the square's edge, a few studs in)
		local dx, dz = math.cos(a), math.sin(a)
		local s = math.min((ex - 6) / math.max(math.abs(dx), 1e-3), (ez - 6) / math.max(math.abs(dz), 1e-3))
		local p = c + V3(dx * s, 0, dz * s)
		local hit = workspace:Raycast(V3(p.X, c.Y + 300, p.Z), V3(0, -600, 0), params)
		if hit then table.insert(ys, hit.Position.Y) end
	end
	if #ys == 0 then return 0 end
	table.sort(ys)
	return math.clamp(ys[math.floor(#ys * 0.4) + 1], -40, 60)
end

local function part(ctx, class, size, cf, color, material, shape)
	local p = Instance.new(class or "Part")
	p.Size = size
	p.CFrame = cf
	p.Color, p.Material = color, material or Mat.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = ctx.Props
	ctx.n += 1
	return p
end
-- a ball, or (any other proportions) an ellipsoid: a Ball part is always round, so a squashed one is
-- a block wearing a sphere mesh
local function ball(ctx, size, at, color, material)
	local cf = typeof(at) == "Vector3" and CF(at) or at
	if math.abs(size.X - size.Y) < 0.01 and math.abs(size.Y - size.Z) < 0.01 then
		return part(ctx, "Part", size, cf, color, material, Enum.PartType.Ball)
	end
	local p = part(ctx, "Part", size, cf, color, material)
	local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
	return p
end
local function cyl(ctx, d, h, at, color, material)
	return part(ctx, "Part", V3(h, d, d), (typeof(at) == "Vector3" and CF(at) or at) * CFrame.Angles(0, 0, DEG(90)), color, material, Enum.PartType.Cylinder)
end
local function shade(c, k) return c:Lerp(Color3.new(0, 0, 0), k) end
local function tint(c, k) return c:Lerp(Color3.new(1, 1, 1), k) end

-- a tree for a far wood, in a few parts: the theme's kind
local function tree(ctx, T, r, p, h)
	local style = T.tree
	if style == "pine" then
		cyl(ctx, h * 0.07, h * 0.4, p + V3(0, h * 0.2, 0), T.woodDark, Mat.Wood)
		ball(ctx, V3(h * 0.5, h * 0.62, h * 0.5), p + V3(0, h * 0.42, 0), T.leaf, Mat.Grass)
		ball(ctx, V3(h * 0.32, h * 0.5, h * 0.32), p + V3(0, h * 0.78, 0), T.leaf2 or T.leaf, Mat.Grass)
		if T.snow then ball(ctx, V3(h * 0.2, h * 0.16, h * 0.2), p + V3(0, h * 0.98, 0), T.groundColor, Mat.Snow) end
	elseif style == "palm" then
		local top = p + V3(r:NextNumber(-1, 1) * h * 0.1, h, 0)
		part(ctx, "Part", V3(h * 0.07, h, h * 0.07), CFrame.lookAt((p + top) / 2, top) * CFrame.Angles(DEG(90), 0, 0), T.wood, Mat.Wood)
		for i = 0, 3 do
			part(ctx, "WedgePart", V3(0.4, h * 0.08, h * 0.45), CF(top) * CFrame.Angles(0, i * math.pi / 2 + r:NextNumber(0, 0.6), 0) * CFrame.Angles(DEG(24), 0, 0) * CF(0, 0, -h * 0.2), i % 2 == 0 and T.leaf or T.leaf2, Mat.Grass)
		end
	elseif style == "dead" then
		cyl(ctx, h * 0.08, h * 0.8, p + V3(0, h * 0.4, 0), T.woodDark, Mat.Wood)
		for i = 1, 2 do
			local a = r:NextNumber(0, math.pi * 2)
			part(ctx, "Part", V3(h * 0.04, h * 0.35, h * 0.04), CF(p + V3(0, h * (0.5 + i * 0.12), 0)) * CFrame.Angles(0, a, 0) * CFrame.Angles(DEG(50), 0, 0) * CF(0, h * 0.17, 0), T.woodDark, Mat.Wood)
		end
	else
		-- oak, birch, willow, blossom: a trunk under two crowns
		local trunk = style == "birch" and RGB(226, 224, 214) or T.woodDark
		cyl(ctx, h * 0.09, h * 0.55, p + V3(0, h * 0.27, 0), trunk, Mat.Wood)
		local mat = style == "blossom" and Mat.SmoothPlastic or Mat.Grass
		local leaf3 = T.leaf3 or T.leaf2 or T.leaf
		ball(ctx, V3(h * 0.62, h * (style == "willow" and 0.55 or 0.48), h * 0.62), p + V3(0, h * 0.66, 0), T.leaf, mat)
		ball(ctx, V3(h * 0.42, h * 0.38, h * 0.42), p + V3(r:NextNumber(-1, 1) * h * 0.14, h * 0.86, r:NextNumber(-1, 1) * h * 0.14), r:NextNumber() < 0.4 and leaf3 or (T.leaf2 or T.leaf), mat)
	end
end

-- a cottage for a far village: walls, a roof, a chimney (a thread of smoke now and then)
local function cottage(ctx, T, r, cf)
	local w, len, h = r:NextNumber(10, 14), r:NextNumber(12, 18), r:NextNumber(7, 9)
	part(ctx, "Part", V3(w, h, len), cf * CF(0, h / 2, 0), T.plaster or RGB(226, 214, 190), Mat.Plaster)
	local rh = w * 0.42
	for _, s in ipairs({-1, 1}) do
		part(ctx, "WedgePart", V3(len + 1, rh, w / 2 + 0.6), cf * CF(0, h + rh / 2, s * (w / 4 + 0.15)) * CFrame.Angles(0, s > 0 and DEG(90) or DEG(-90), 0),
			T.snow and T.groundColor or T.roof, T.snow and Mat.Snow or Mat.Slate)
	end
	if r:NextNumber() < 0.5 then
		local ch = part(ctx, "Part", V3(1.4, 4, 1.4), cf * CF(w * 0.25, h + rh * 0.8, len * 0.3), T.stoneDark or RGB(110, 106, 100), Mat.Cobblestone)
		local s = Instance.new("Smoke"); s.Size = 2.5; s.RiseVelocity = 3; s.Opacity = 0.07; s.Color = RGB(150, 146, 140); s.Parent = ch
	end
end

-- a castle on a far hill: a keep and four towers under their roofs
local function castle(ctx, T, at, s)
	local stone = T.stone or RGB(160, 156, 150)
	part(ctx, "Part", V3(40 * s, 34 * s, 40 * s), CF(at + V3(0, 17 * s, 0)), stone, T.stoneMat or Mat.Slate)
	part(ctx, "Part", V3(70 * s, 18 * s, 70 * s), CF(at + V3(0, 9 * s, 0)), shade(stone, 0.12), T.stoneMat or Mat.Slate)
	for _, d in ipairs({V3(1, 0, 1), V3(-1, 0, 1), V3(1, 0, -1), V3(-1, 0, -1)}) do
		local p = at + d * 35 * s
		cyl(ctx, 14 * s, 32 * s, p + V3(0, 16 * s, 0), stone, T.stoneMat or Mat.Slate)
		if not T.flatTowers then
			-- (a roof cone of four wedges each side: fine at this distance)
			for i = 0, 3 do
				part(ctx, "WedgePart", V3(16 * s, 14 * s, 8 * s), CF(p + V3(0, 39 * s, 0)) * CFrame.Angles(0, i * math.pi / 2, 0) * CF(0, 0, 4 * s) * CFrame.Angles(0, math.pi, 0), T.roof, Mat.Slate)
			end
		end
	end
	K.banner(ctx, at + V3(0, 34 * s, 0), 12 * s, TEAM[2], ctx.Props)
end

-- a camp outside the walls: tents round fires, banners in its colour
local function camp(ctx, T, r, at, face, color)
	local look = CFrame.lookAt(at, at + face)
	for i = 1, 7 do
		local off = V3(r:NextNumber(-34, 34), 0, r:NextNumber(-22, 22))
		local p = (look * CF(off)).Position
		K.tent(ctx, CF(p) * CFrame.Angles(0, r:NextNumber(0, math.pi * 2), 0), r:NextNumber(8, 11), r:NextNumber(10, 13), r:NextNumber(6, 8), i % 3 == 0 and color or (T.tent or RGB(200, 186, 160)))
	end
	for i = 1, 4 do K.banner(ctx, (look * CF(-36 + i * 14, 0, -26)).Position, 15, color, ctx.Props) end
	for _ = 1, 2 do pcall(K.campfire, ctx, (look * CF(r:NextNumber(-20, 20), 0, r:NextNumber(-12, 12))).Position) end
end

-- a column of smoke rising off the horizon (a fire's glow under it at night)
local function smokeColumn(ctx, T, at, big)
	local p = part(ctx, "Part", V3(8, 1, 8), CF(at), RGB(0, 0, 0))
	p.Transparency = 1
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = big and ColorSequence.new(RGB(66, 62, 58), RGB(124, 120, 114)) or ColorSequence.new(RGB(150, 146, 140), RGB(196, 192, 186))
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, big and 22 or 12), NumberSequenceKeypoint.new(1, big and 80 or 46)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.6, 0.72), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(18, 26)
	e.Speed = NumberRange.new(big and 9 or 6, big and 13 or 9)
	e.SpreadAngle = Vector2.new(8, 8)
	e.Acceleration = V3(2.5, 0, 1)
	e.Rate = big and 5 or 3
	e.RotSpeed = NumberRange.new(-10, 10)
	e.LightInfluence = 1
	e.Parent = p
	if T.night or big then
		local f = Instance.new("ParticleEmitter")
		f.Texture = "rbxasset://textures/particles/fire_main.dds"
		f.Color = ColorSequence.new(RGB(255, 170, 70), RGB(255, 80, 30))
		f.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 2)})
		f.Transparency = NumberSequence.new(0.35)
		f.Lifetime = NumberRange.new(1, 1.8)
		f.Speed = NumberRange.new(6, 10)
		f.Rate = 14
		f.LightEmission = 1
		f.Parent = p
		local l = Instance.new("PointLight"); l.Color = RGB(255, 130, 60); l.Range = 60; l.Brightness = 2; l.Shadows = false; l.Parent = p
	end
end

function Horizon.clear()
	local m = workspace:FindFirstChild("MapHorizon")
	if m then m:Destroy() end
	for _, region in ipairs(bands) do pcall(function() workspace.Terrain:FillRegion(region, 4, Mat.Air) end) end
	bands = {}
end

function Horizon.build(map, name)
	-- (the terrain was cleared with the last map: MapLoader.unload)
	local old = workspace:FindFirstChild("MapHorizon"); if old then old:Destroy() end
	if not map or SKIP[name] or map:GetAttribute("NoHorizon") then return false end
	local corner, size = map:GetAttribute("TerrainCorner"), map:GetAttribute("TerrainSize")
	if typeof(corner) ~= "Vector3" or typeof(size) ~= "Vector3" then return false end
	local T, themeKey = themeOf(map, name)
	if not T then return false end
	local r = Random.new(#name * 977 + 13)
	local c = corner + size / 2
	local ex, ez = size.X / 2, size.Z / 2
	local G = map:GetAttribute("Theme") and 0 or edgeHeight(map, c, ex, ez)
	local E = math.max(ex, ez)
	local ctx = K.new("MapHorizon")
	local cx, cz = c.X, c.Z
	local function at(a, d, y) return V3(cx + math.cos(a) * d, y or G, cz + math.sin(a) * d) end
	-- (is a point out of the map's square, by a margin?)
	local function outside(p, m) return math.abs(p.X - cx) > ex + (m or 0) or math.abs(p.Z - cz) > ez + (m or 0) end

	-- THE SKIRT: the map's ground running on, flush with its edge
	-- (Roblox draws terrain's surface half a voxel above where a fill ends: every brush is lowered
	-- by those 2 studs, as Build ▸ MapKit's are, so the skirt meets the map's ground flush)
	local DROP = V3(0, 2, 0)
	local T_ = {}
	function T_:FillBlock(cf, sz, mat) return workspace.Terrain:FillBlock(cf - DROP, sz, mat) end
	function T_:FillBall(c, r, mat) return workspace.Terrain:FillBall(c - DROP, r, mat) end
	local depth = 16
	-- (8 studs over the map's own edge: MapForge's ground stops 4 short of its terrain box)
	local LAP = 8
	local slabs = {
		{CF(cx, G - depth / 2, cz - ez - SKIRT / 2 + LAP / 2), V3(size.X + SKIRT * 2, depth, SKIRT + LAP)},
		{CF(cx, G - depth / 2, cz + ez + SKIRT / 2 - LAP / 2), V3(size.X + SKIRT * 2, depth, SKIRT + LAP)},
		{CF(cx - ex - SKIRT / 2 + LAP / 2, G - depth / 2, cz), V3(SKIRT + LAP, depth, size.Z)},
		{CF(cx + ex + SKIRT / 2 - LAP / 2, G - depth / 2, cz), V3(SKIRT + LAP, depth, size.Z)},
	}
	for _, s in ipairs(slabs) do
		pcall(function() T_:FillBlock(s[1], s[2], T.ground) end)
		local lo, hi = s[1].Position - s[2] / 2, s[1].Position + s[2] / 2
		table.insert(bands, Region3.new(V3(lo.X, G - depth - 8, lo.Z), V3(hi.X, G + 90, hi.Z)):ExpandToGrid(4))
	end
	-- mounds and rocky outcrops on it, the theme's patches
	for _ = 1, 70 do
		local p = at(r:NextNumber(0, math.pi * 2), r:NextNumber(E + 14, E + SKIRT - 20))
		if outside(p, 8) then
			if r:NextNumber() < 0.3 then
				local rad = r:NextNumber(7, 18)
				pcall(function() T_:FillBall(p - V3(0, rad * 0.35, 0), rad, T.cliff) end)
			else
				local rad = r:NextNumber(14, 40)
				pcall(function() T_:FillBall(p - V3(0, rad * 0.7, 0), rad, T.ground) end)
			end
		end
	end
	-- (and its outer half rolls: hills of the same ground, sunk to their shoulders)
	for _ = 1, 30 do
		local p = at(r:NextNumber(0, math.pi * 2), r:NextNumber(E + 150, E + SKIRT + 40))
		if outside(p, 90) then
			local rad = r:NextNumber(40, 95)
			pcall(function() T_:FillBall(p - V3(0, rad * r:NextNumber(0.72, 0.85), 0), rad, T.ground) end)
		end
	end
	for _ = 1, 26 do
		local p = at(r:NextNumber(0, math.pi * 2), r:NextNumber(E + 20, E + SKIRT - 30))
		if outside(p, 10) then
			if T.accent then pcall(function() T_:FillBlock(CF(p - V3(0, 0.8, 0)) * CFrame.Angles(0, r:NextNumber(0, 3), 0), V3(r:NextNumber(10, 26), 2, r:NextNumber(8, 18)), T.accent) end)
			elseif T.puddles then pcall(function() T_:FillBlock(CF(p - V3(0, 0.8, 0)), V3(r:NextNumber(8, 18), 1.6, r:NextNumber(8, 18)), Mat.Water) end)
			elseif T.path and r:NextNumber() < 0.5 then pcall(function() T_:FillBlock(CF(p - V3(0, 0.9, 0)) * CFrame.Angles(0, r:NextNumber(0, 3), 0), V3(r:NextNumber(12, 30), 2, r:NextNumber(6, 12)), T.path) end)
			end
		end
	end

	-- THE PLAIN past it, out beyond the haze (a ring of slabs, none bigger than a part may be)
	local plainColor = shade(T.groundColor, 0.05)
	local inner = E + SKIRT - 30
	local outer = E + 2600
	local step = 2000
	for x0 = cx - outer, cx + outer - 1, step do
		for z0 = cz - outer, cz + outer - 1, step do
			-- each tile, minus what the skirt already covers (cut into the strips round the hole)
			local x1, z1 = math.min(x0 + step, cx + outer), math.min(z0 + step, cz + outer)
			local hx0, hx1, hz0, hz1 = cx - inner, cx + inner, cz - inner, cz + inner
			local rects = {}
			if x1 <= hx0 or x0 >= hx1 or z1 <= hz0 or z0 >= hz1 then
				rects = {{x0, z0, x1, z1}}
			else
				if z0 < hz0 then table.insert(rects, {x0, z0, x1, hz0}) end
				if z1 > hz1 then table.insert(rects, {x0, hz1, x1, z1}) end
				local mz0, mz1 = math.max(z0, hz0), math.min(z1, hz1)
				if x0 < hx0 and mz1 > mz0 then table.insert(rects, {x0, mz0, hx0, mz1}) end
				if x1 > hx1 and mz1 > mz0 then table.insert(rects, {hx1, mz0, x1, mz1}) end
			end
			for _, q in ipairs(rects) do
				local w, d = q[3] - q[1], q[4] - q[2]
				if w > 1 and d > 1 then
					-- (its top a hair over the skirt's outer edge: the terrain's rounded rim stays under it)
					local p = part(ctx, "Part", V3(w, 4, d), CF((q[1] + q[3]) / 2, G - 1.9, (q[2] + q[4]) / 2), plainColor, T.ground)
					p.CanCollide = true
				end
			end
		end
	end

	-- HILLS rolling out of it, MOUNTAINS behind
	local hillMat = T.ground
	for _ = 1, 28 do
		local a, d = r:NextNumber(0, math.pi * 2), r:NextNumber(E + SKIRT - 10, E + SKIRT + 640)
		local w = r:NextNumber(180, 400)
		local h = w * r:NextNumber(0.22, 0.34)
		ball(ctx, V3(w, h, w * r:NextNumber(0.8, 1.3)), CF(at(a, d, G - h * 0.08)) * CFrame.Angles(0, r:NextNumber(0, 3), 0), r:NextNumber() < 0.5 and plainColor or shade(T.groundColor, 0.1), hillMat)
	end
	local rocky = T.cliff
	-- (a screen draws only so far, a slow one less: past that the sky shows through like a sea.
	--  So a RIDGE closes the view all round, unbroken, inside that; bigger mountains stand behind it
	--  for the screens that see further)
	for i = 1, 30 do
		local ridge = i <= 22
		local a = (ridge and i / 22 or (i - 22) / 8) * math.pi * 2 + r:NextNumber(-0.12, 0.12)
		local d = ridge and r:NextNumber(E + 560, E + 760) or r:NextNumber(E + 1000, E + 1400)
		local w = ridge and r:NextNumber(420, 640) or r:NextNumber(700, 1100)
		local h = ridge and r:NextNumber(110, 220) or r:NextNumber(260, 480)   -- (how high it rises)
		local p = at(a, d, G)
		if themeKey == "desert" or themeKey == "desertDusk" then
			-- mesas: flat-topped and steep, low dunes between
			cyl(ctx, w * 0.6, h, p + V3(0, h / 2 - 4, 0), shade(T.cliffColor, r:NextNumber(0, 0.12)), Mat.Sandstone)
			ball(ctx, V3(w * 1.1, h * 0.7, w * 0.8), CF(p + V3(r:NextNumber(-1, 1) * w * 0.4, 0, 0)), T.groundColor, T.ground)
		else
			ball(ctx, V3(w, h * 2, w * 0.75), CF(p) * CFrame.Angles(0, -a + math.pi / 2 + r:NextNumber(-0.3, 0.3), 0), shade(T.cliffColor, r:NextNumber(0, 0.12)), rocky)
			if T.snow or (themeKey == "dawnMist" and i % 3 == 0) then
				ball(ctx, V3(w * 0.5, h * 0.7, w * 0.4), CF(p + V3(0, h * 0.72, 0)), tint(T.groundColor, 0.2), Mat.Snow)
			elseif themeKey == "ember" and i % 4 == 0 then
				-- a fire mountain: a glowing crown, smoke off it
				local cap = ball(ctx, V3(w * 0.2, h * 0.22, w * 0.2), CF(p + V3(0, h * 0.95, 0)), RGB(255, 110, 40), Mat.Neon)
				cap.Transparency = 0.2
				smokeColumn(ctx, T, p + V3(0, h, 0), true)
			elseif not ridge or i % 2 == 0 then
				-- (a green flank on the ridge's foot: grass climbing the rock)
				ball(ctx, V3(w * 0.9, h * 0.8, w * 0.7), CF(p + (V3(cx, G, cz) - p).Unit * w * 0.12), shade(T.groundColor, 0.06), T.ground)
			end
		end
	end

	-- WOODS in groves
	local layout = map:GetAttribute("Layout") or map:GetAttribute("Kind")
	local groves = (T.trees or 30) >= 30 and 12 or 7
	local warlike = WARLIKE[layout] or map:GetAttribute("W_Theme") ~= nil or (layout == nil and themeKey ~= "spring")
	local campA = r:NextNumber(0, math.pi * 2)
	local sectors = {campA, campA + math.pi}   -- (the camps, or the village and its road: kept clear of trees)
	local function clear_(a) for _, s in ipairs(sectors) do if math.abs(math.atan2(math.sin(a - s), math.cos(a - s))) < 0.32 then return false end end return true end
	for _ = 1, groves do
		local a = r:NextNumber(0, math.pi * 2)
		if clear_(a) then
			local d = r:NextNumber(E + 40, E + SKIRT + 380)
			local n = r:NextInteger(8, 18)
			for _ = 1, n do
				local p = at(a + r:NextNumber(-0.18, 0.18), d + r:NextNumber(-50, 50))
				if outside(p, 14) then tree(ctx, T, r, p - V3(0, 0.5, 0), r:NextNumber(16, 30)) end
			end
		end
	end

	-- THE ARMIES' CAMPS (a fighting map) or A VILLAGE down a road (a quiet one), and fields
	if warlike then
		-- (War's field has its own camps at both ends: Game ▸ WarMap)
		for i, a in ipairs(map:GetAttribute("W_Theme") and {} or sectors) do
			local p = at(a, E + r:NextNumber(70, 130))
			if outside(p, 30) then camp(ctx, T, r, p, (V3(cx, p.Y, cz) - p).Unit, TEAM[i]) end
		end
	else
		local a = sectors[1]
		-- the road out of the map
		local roadMat = T.path or Mat.Ground
		pcall(function() T_:FillBlock(CF(at(a, E + SKIRT / 2, G - 0.9)) * CFrame.Angles(0, -a, 0), V3(SKIRT + 20, 2, 12), roadMat) end)
		part(ctx, "Part", V3(300, 0.4, 12), CF(at(a, E + SKIRT + 140, G + 0.2)) * CFrame.Angles(0, -a, 0), T.pathColor or RGB(124, 100, 72), Mat.Ground)
		for k = 1, 9 do
			local d = E + SKIRT - 90 + k * 26
			local side = k % 2 == 0 and 1 or -1
			local p = at(a, d) + V3(-math.sin(a), 0, math.cos(a)) * side * r:NextNumber(20, 30)
			cottage(ctx, T, r, CFrame.lookAt(p, p + V3(math.cos(a), 0, math.sin(a))) * CFrame.Angles(0, DEG(90 * side), 0))
		end
		if not (T.snow or themeKey == "desert" or themeKey == "desertDusk" or themeKey == "ember" or themeKey == "ash") then
			for _ = 1, 12 do
				local p = at(a + r:NextNumber(-0.5, 0.5), E + SKIRT + r:NextNumber(-60, 200))
				local gold = r:NextNumber() < 0.45
				part(ctx, "Part", V3(r:NextNumber(40, 80), 0.5, r:NextNumber(40, 80)), CF(p + V3(0, -0.1, 0)) * CFrame.Angles(0, r:NextNumber(-0.4, 0.4), 0),
					gold and RGB(206, 178, 92) or shade(T.groundColor, 0.18), Mat.Grass)
			end
		end
	end
	-- A CASTLE on a far hill
	do
		local a = sectors[2] + r:NextNumber(0.7, 1.2)
		local d = E + SKIRT + r:NextNumber(110, 200)
		local p = at(a, d, G)
		local hw = 260
		ball(ctx, V3(hw, hw * 0.4, hw), CF(p - V3(0, hw * 0.06, 0)), T.groundColor, hillMat)
		castle(ctx, T, p + V3(0, hw * 0.13, 0), 1)
	end
	-- SMOKE off the horizon
	local fires = (warlike and 3 or 1) + ((T.burnt or themeKey == "ember") and 3 or 0)
	for _ = 1, fires do
		local p = at(r:NextNumber(0, math.pi * 2), r:NextNumber(E + SKIRT + 120, E + SKIRT + 600), G + 2)
		smokeColumn(ctx, T, p, warlike)
	end

	ctx.model.Name = "MapHorizon"
	ctx.model:SetAttribute("Theme", themeKey)
	pcall(function() ctx.model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent end)
	ctx.model.Parent = workspace
	return true
end

return Horizon
