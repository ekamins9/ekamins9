--[[ CALDERA MAP — Dragonfall's arena (Game ▸ Modes ▸ Dragonfall): the Ashen Caldera, a crater of
     black rock under a burning sky where Cindermaw nests, built fresh when its match starts.

       CalderaMap.build() -> mapName, layout
         layout.centre, layout.radius            the fighting ground (the dragon keeps inside it)
         layout.lava = {{pos, r}}                the lava pools (the mode burns who stands in one,
                                                 and the dragon's brood climbs out of them)
         Map ▸ Ballistae ▸ Ballista1..4          each a Model: its stone platform, and its Turret
                                                 (a Model, PrimaryPart "Pivot", aimed by the mode)
         Map ▸ Wards ▸ WardStone1..6             the ward stones (shelter from the Inferno)

     A wide floor of cracked basalt with glowing seams and old scorch marks, an ancient paved
     ring at its heart; a wall of black cliffs all round with lava falling down them into pools;
     six standing WARD STONES with runes cut in them; four BALLISTAE on stone platforms near the
     rim; the bones of something huge that died here, and the swords and shields of the ones who
     came before; ash drifting down, embers rising off the lava. ]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local K = require(ServerScriptService:WaitForChild("Build"):WaitForChild("MapKit"))

local CalderaMap = {}
local V3 = Vector3.new
local R = 110            -- the fighting ground
local made = 0

local ROCK = Color3.fromRGB(44, 38, 38)
local ROCK2 = Color3.fromRGB(62, 52, 50)
local FLOOR = Color3.fromRGB(56, 48, 46)
local PAVE = Color3.fromRGB(92, 84, 78)
local LAVA = Color3.fromRGB(255, 104, 24)
local GLOW = Color3.fromRGB(255, 120, 40)
local RUNE = Color3.fromRGB(110, 220, 255)
local BONE = Color3.fromRGB(214, 204, 180)
local IRON = Color3.fromRGB(58, 56, 60)
local WOOD = Color3.fromRGB(92, 62, 38)

local function nocol(p) p.CanCollide = false; p.CanQuery = false; return p end
local function polar(a, r, y) return V3(math.cos(a) * r, y or 0, math.sin(a) * r) end

-- embers or ash off a part
local function emitter(p, o)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = o.texture or "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(o.color or GLOW)
	pe.LightEmission = o.light or 1
	pe.Size = NumberSequence.new(o.size or 0.25, 0)
	pe.Lifetime = NumberRange.new(o.life or 2, (o.life or 2) * 1.6)
	pe.Speed = NumberRange.new(o.speed or 2, (o.speed or 2) * 2)
	pe.Acceleration = o.acc or V3(0, 3, 0)
	pe.SpreadAngle = Vector2.new(o.spread or 30, o.spread or 30)
	pe.Rate = o.rate or 6
	if o.box then pe.Shape = Enum.ParticleEmitterShape.Box; pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume end
	pe.Parent = p
	return pe
end

local function lavaPool(ctx, L, pos, r)
	local rim = K.cyl(ctx, "LavaRim", r * 2 + 3, 0.7, CFrame.new(pos + V3(0, 0.1, 0)), ROCK, Enum.Material.Basalt, ctx.Props)
	nocol(rim)
	local lava = K.cyl(ctx, "Lava", r * 2, 0.5, CFrame.new(pos + V3(0, 0.3, 0)), LAVA, Enum.Material.Neon, ctx.Props)
	nocol(lava)
	local l = Instance.new("PointLight"); l.Name = "Flicker"; l.Color = GLOW; l.Range = math.min(60, r * 3.5); l.Brightness = 2.2; l.Parent = lava
	emitter(lava, {rate = r * 0.8, speed = 3, life = 2.4, acc = V3(0, 4, 0), spread = 25, box = true})
	-- a crust of cooling rock floating on it
	for _ = 1, math.floor(r / 3) do
		local a, d = math.random() * 6.28, math.random() * r * 0.75
		local s = math.random() * 1.6 + 0.8
		nocol(K.cyl(ctx, "Crust", s * 2, 0.3, CFrame.new(pos + polar(a, d, 0.5)), ROCK2, Enum.Material.Basalt, ctx.Props))
	end
	table.insert(L.lava, {pos = pos, r = r})
end

local function wardStone(ctx, folder, i, a, r)
	local pos = polar(a, r)
	local face = CFrame.lookAt(pos, V3(0, 0, 0))   -- (its broad face to the middle: the fire comes from there)
	local tilt = CFrame.Angles(math.rad(math.random(-3, 3)), 0, math.rad(math.random(-4, 4)))
	local m = Instance.new("Model"); m.Name = "WardStone" .. i; m.Parent = folder
	local slab = K.box(ctx, "Stone", V3(10, 16, 3.4), face * CFrame.new(0, 8, 0) * tilt, Color3.fromRGB(78, 74, 80), Enum.Material.Slate, m)
	K.box(ctx, "Cap", V3(11, 1.4, 4.2), slab.CFrame * CFrame.new(0, 8.4, 0), Color3.fromRGB(64, 60, 66), Enum.Material.Slate, m)
	K.box(ctx, "Foot", V3(12, 1.6, 6), face * CFrame.new(0, 0.6, 0), Color3.fromRGB(60, 56, 60), Enum.Material.Slate, m)
	-- runes cut in both faces, glowing
	for _, side in ipairs({-1, 1}) do
		for j = 0, 2 do
			local rn = K.box(ctx, "Rune", V3(0.5, 2.4, 0.12), slab.CFrame * CFrame.new(-2.5 + j * 2.5, 2 - j % 2 * 1.2, side * 1.74), RUNE, Enum.Material.Neon, m)
			nocol(rn)
			local bar = K.box(ctx, "Rune", V3(1.6, 0.4, 0.12), slab.CFrame * CFrame.new(-2.5 + j * 2.5, 3.4 - j % 2 * 1.2, side * 1.74), RUNE, Enum.Material.Neon, m)
			nocol(bar)
		end
	end
	local l = Instance.new("PointLight"); l.Color = RUNE; l.Range = 14; l.Brightness = 0.9; l.Parent = slab
	m:SetAttribute("Ward", true)
	return m
end

local function ballista(ctx, folder, i, a)
	local pos = polar(a, 86)
	local face = CFrame.lookAt(pos, V3(0, 0, 0))
	local m = Instance.new("Model"); m.Name = "Ballista" .. i; m.Parent = folder
	-- the platform, and a ramp down toward the middle
	K.cyl(ctx, "Platform", 16, 3, CFrame.new(pos + V3(0, 1.5, 0)), Color3.fromRGB(74, 68, 66), Enum.Material.Slate, m)
	K.cyl(ctx, "PlatformRim", 17, 0.8, CFrame.new(pos + V3(0, 3.1, 0)), Color3.fromRGB(58, 54, 52), Enum.Material.Slate, m).CanCollide = false
	K.wedge(ctx, "Ramp", V3(6, 3, 8), face * CFrame.new(0, 1.5, -11.5) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(74, 68, 66), Enum.Material.Slate, m)
	-- the turret: a frame on a post, two bow arms, the string, a bolt laid in it
	local t = Instance.new("Model"); t.Name = "Turret"; t.Parent = m
	local top = face * CFrame.new(0, 3, 0)
	local pivot = K.box(ctx, "Pivot", V3(1, 1, 1), top * CFrame.new(0, 2.6, 0), IRON, Enum.Material.Metal, t)
	pivot.Transparency = 1; nocol(pivot)
	t.PrimaryPart = pivot
	K.cyl(ctx, "Post", 1.6, 2.6, top * CFrame.new(0, 1.3, 0), WOOD, Enum.Material.Wood, m)
	local aim = top * CFrame.new(0, 2.6, 0) * CFrame.Angles(math.rad(28), 0, 0)
	K.box(ctx, "Stock", V3(1.4, 1, 9), aim * CFrame.new(0, 0, 1), WOOD, Enum.Material.WoodPlanks, t)
	K.box(ctx, "Track", V3(0.5, 0.2, 8.6), aim * CFrame.new(0, 0.6, 1), Color3.fromRGB(70, 48, 30), Enum.Material.Wood, t).CanCollide = false
	for _, s in ipairs({-1, 1}) do
		K.box(ctx, "Arm", V3(4.6, 0.6, 0.7), aim * CFrame.new(s * 2.5, 0.1, -2.6) * CFrame.Angles(0, s * math.rad(-22), 0), WOOD, Enum.Material.Wood, t)
		K.box(ctx, "ArmTip", V3(0.5, 0.8, 0.8), aim * CFrame.new(s * 4.7, 0.1, -1.6), IRON, Enum.Material.Metal, t)
		nocol(K.box(ctx, "String", V3(0.12, 0.12, 5.4), aim * CFrame.new(s * 2.4, 0.4, 0.8) * CFrame.Angles(0, s * math.rad(-62), 0), Color3.fromRGB(40, 34, 30), Enum.Material.Fabric, t))
		K.cyl(ctx, "Wheel", 1.8, 0.5, aim * CFrame.new(s * 0.95, -0.2, 4.6) * CFrame.Angles(0, 0, math.pi / 2), IRON, Enum.Material.Metal, t).CanCollide = false
	end
	local bolt = K.cyl(ctx, "Bolt", 0.45, 7.5, aim * CFrame.new(0, 0.85, -0.2) * CFrame.Angles(math.pi / 2, 0, 0), Color3.fromRGB(120, 90, 60), Enum.Material.Wood, t)
	nocol(bolt)
	local tip = K.wedge(ctx, "BoltTip", V3(0.7, 0.7, 1.4), aim * CFrame.new(0, 0.85, -4.6) * CFrame.Angles(0, math.pi, 0), IRON, Enum.Material.Metal, t)
	nocol(tip)
	-- a brazier beside it (it's lit when it's ready)
	local bz = face * CFrame.new(5.5, 3, 2)
	K.cyl(ctx, "BrazierStand", 0.6, 3, bz * CFrame.new(0, 1.5, 0), IRON, Enum.Material.Metal, m)
	local bowl = K.cyl(ctx, "BrazierBowl", 2.4, 0.8, bz * CFrame.new(0, 3.2, 0), IRON, Enum.Material.Metal, m)
	local coals = nocol(K.cyl(ctx, "Coals", 2, 0.3, bz * CFrame.new(0, 3.6, 0), GLOW, Enum.Material.Neon, m))
	local fire = Instance.new("Fire"); fire.Name = "ReadyFire"; fire.Size = 3; fire.Heat = 6; fire.Color = GLOW; fire.SecondaryColor = Color3.fromRGB(255, 60, 10); fire.Parent = coals
	local l = Instance.new("PointLight"); l.Name = "Flicker"; l.Color = GLOW; l.Range = 18; l.Brightness = 1.4; l.Parent = coals
	m:SetAttribute("Ballista", i)
	return m
end

-- the bones of something huge that died here (long ago)
local function oldBones(ctx, at, yaw)
	local f = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	for i = 0, 6 do
		local z = -12 + i * 4
		nocol(K.cyl(ctx, "Spine", 2.2, 2.8, f * CFrame.new(0, 1.2, z) * CFrame.Angles(math.pi / 2, 0, 0), BONE, Enum.Material.SmoothPlastic, ctx.Props))
		if i >= 1 and i <= 5 then
			for _, s in ipairs({-1, 1}) do
				local h = 9 - math.abs(i - 3) * 1.4
				K.box(ctx, "Rib", V3(0.8, h, 0.8), f * CFrame.new(s * 2.6, h / 2 + 0.6, z) * CFrame.Angles(0, 0, s * -0.42), BONE, Enum.Material.SmoothPlastic, ctx.Props)
				K.box(ctx, "RibTip", V3(0.7, h * 0.55, 0.7), f * CFrame.new(s * (4.2 + h * 0.18), h + 0.3, z) * CFrame.Angles(0, 0, s * 0.35), BONE, Enum.Material.SmoothPlastic, ctx.Props)
			end
		end
	end
	local skull = K.ball(ctx, "OldSkull", 6, f * CFrame.new(0, 2, -18.5), BONE, Enum.Material.SmoothPlastic, ctx.Props)
	skull.Size = V3(5.4, 4, 7.5)
	K.box(ctx, "OldJaw", V3(4, 1, 7), f * CFrame.new(0, 0.5, -21.5) * CFrame.Angles(-0.15, 0, 0), BONE, Enum.Material.SmoothPlastic, ctx.Props)
	for _, s in ipairs({-1, 1}) do
		K.box(ctx, "OldHorn", V3(0.9, 0.9, 6), f * CFrame.new(s * 2.4, 4.2, -14.5) * CFrame.Angles(0.5, s * 0.35, 0), BONE, Enum.Material.SmoothPlastic, ctx.Props)
	end
end

-- the swords and shields of those who came before
local function fallen(ctx, at)
	local f = CFrame.new(at) * CFrame.Angles(0, math.random() * 6.28, 0)
	nocol(K.box(ctx, "OldBlade", V3(0.3, 4, 0.9), f * CFrame.new(0, 1.6, 0) * CFrame.Angles(0.25, 0, 0.12), Color3.fromRGB(110, 106, 104), Enum.Material.Metal, ctx.Props))
	nocol(K.box(ctx, "OldGuard", V3(1.8, 0.3, 0.4), f * CFrame.new(0.05, 3.55, 0.5) * CFrame.Angles(0.25, 0, 0.12), IRON, Enum.Material.Metal, ctx.Props))
	if math.random() < 0.6 then
		local sh = K.cyl(ctx, "OldShield", 3.4, 0.4, f * CFrame.new(2.2, 0.3, 0.8) * CFrame.Angles(math.rad(80), 0.4, 0), Color3.fromRGB(110, 40, 34), Enum.Material.WoodPlanks, ctx.Props)
		nocol(sh)
	end
end

function CalderaMap.build()
	made += 1
	local name = "Gen_Caldera_" .. made
	local ctx = K.new(name)
	local L = {centre = V3(0, 0, 0), radius = R, lava = {}}
	local ballistae = Instance.new("Folder"); ballistae.Name = "Ballistae"; ballistae.Parent = ctx.model
	local wards = Instance.new("Folder"); wards.Name = "Wards"; wards.Parent = ctx.model

	-- THE GROUND: cracked basalt, glowing seams, an ancient paved ring at the heart
	K.cyl(ctx, "Floor", 330, 4, CFrame.new(0, -2, 0), FLOOR, Enum.Material.Basalt)
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		local p = K.box(ctx, "Pave", V3(8.2, 0.3, 13), CFrame.lookAt(polar(a, 27, 0.15), V3(0, 0.15, 0)), PAVE, Enum.Material.Slate, ctx.Props)
		if math.random() < 0.25 then p.Color = Color3.fromRGB(70, 64, 60) end
		if math.random() < 0.15 then p.CFrame = p.CFrame * CFrame.Angles(0.06, 0, 0.04) end
	end
	nocol(K.cyl(ctx, "InnerRing", 36, 0.2, CFrame.new(0, 0.12, 0), Color3.fromRGB(70, 64, 60), Enum.Material.Slate, ctx.Props))
	-- seams of fire in the rock, running out from the heart
	for _ = 1, 26 do
		local a = math.random() * 6.28
		local r0 = 22 + math.random() * 60
		local at = polar(a, r0, 0.06)
		local dir = a + (math.random() - 0.5) * 0.8
		for _ = 1, math.random(3, 6) do
			local len = 3 + math.random() * 5
			local f = CFrame.new(at) * CFrame.Angles(0, -dir + math.pi / 2, 0)
			nocol(K.box(ctx, "Seam", V3(0.35, 0.12, len), f * CFrame.new(0, 0, -len / 2), GLOW, Enum.Material.Neon, ctx.Props))
			at = (f * CFrame.new(0, 0, -len)).Position
			dir += (math.random() - 0.5) * 0.9
		end
	end
	-- scorch marks
	for _ = 1, 14 do
		local s = 6 + math.random() * 10
		nocol(K.cyl(ctx, "Scorch", s, 0.08, CFrame.new(polar(math.random() * 6.28, 15 + math.random() * 80, 0.05)), Color3.fromRGB(28, 24, 24), Enum.Material.Basalt, ctx.Props))
	end

	-- THE CLIFFS all round, black and sheer, lava running down some of them
	local falls = {}
	for i = 0, 39 do
		local a = i / 40 * math.pi * 2 + (math.random() - 0.5) * 0.05
		local r = R + 16 + math.random() * 8
		local h = 48 + math.random() * 44
		local w = 22 + math.random() * 10
		local base = CFrame.lookAt(polar(a, r), V3(0, 0, 0))
		local cliff = K.box(ctx, "Cliff", V3(w, h, 20), base * CFrame.new(0, h / 2 - 4, 6) * CFrame.Angles(math.rad(-7 - math.random() * 6), 0, math.rad((math.random() - 0.5) * 6)), math.random() < 0.5 and ROCK or ROCK2, Enum.Material.Basalt)
		if math.random() < 0.45 then
			local s = 8 + math.random() * 8
			K.wedge(ctx, "Scree", V3(w * 0.8, s, s * 1.4), base * CFrame.new(0, s / 2 - 0.5, -6 - s * 0.4) * CFrame.Angles(0, math.pi, 0), ROCK2, Enum.Material.Basalt)
		end
		if i % 9 == 4 then table.insert(falls, {a = a, r = r, h = h, cliff = cliff.CFrame}) end
	end
	-- a few spires over the rim
	for _ = 1, 8 do
		local a = math.random() * 6.28
		local h = 80 + math.random() * 40
		K.box(ctx, "Spire", V3(10, h, 10), CFrame.new(polar(a, R + 34 + math.random() * 12, h / 2 - 6)) * CFrame.Angles(math.rad(math.random(-6, 6)), math.random() * 6.28, math.rad(math.random(-6, 6))), ROCK, Enum.Material.Basalt)
	end
	-- lava falls down the cliffs, into pools at their feet
	for _, fl in ipairs(falls) do
		-- (down the cliff's own face: its inner side, in its frame, from just under its top to its foot)
		local fall = nocol(K.box(ctx, "LavaFall", V3(5, fl.h - 8, 0.8), fl.cliff * CFrame.new(0, -3, -10.3), LAVA, Enum.Material.Neon, ctx.Props))
		emitter(fall, {rate = 8, speed = 2, life = 2, acc = V3(0, 2, 0), box = true})
		lavaPool(ctx, L, polar(fl.a, fl.r - 16), 9)
	end
	-- and pools out on the floor
	for _, p in ipairs({{a = 0.35, r = 66, s = 11}, {a = 2.1, r = 72, s = 9}, {a = 3.6, r = 58, s = 12}, {a = 5.0, r = 70, s = 10}}) do
		lavaPool(ctx, L, polar(p.a, p.r), p.s)
	end

	-- THE WARD STONES (shelter from its Inferno: get behind one)
	for i = 1, 6 do
		local a = (i - 1) / 6 * math.pi * 2 + 0.52
		wardStone(ctx, wards, i, a, 46 + (i % 2) * 12)
	end
	-- THE BALLISTAE, near the rim
	for i = 1, 4 do ballista(ctx, ballistae, i, (i - 1) / 4 * math.pi * 2 + math.pi / 4) end

	-- what died here, and who came before
	oldBones(ctx, polar(2.75, 84), 1.2)
	for _ = 1, 12 do fallen(ctx, polar(math.random() * 6.28, 30 + math.random() * 60)) end
	for _ = 1, 16 do K.rock(ctx, polar(math.random() * 6.28, 60 + math.random() * 44), 3 + math.random() * 5, ROCK2) end
	-- broken pillars of whoever paved the heart
	for _, a in ipairs({0.9, 2.5, 4.2, 5.7}) do
		local h = 6 + math.random() * 10
		K.cyl(ctx, "OldPillar", 4, h, CFrame.new(polar(a, 38, h / 2)), PAVE, Enum.Material.Slate, ctx.Props)
		nocol(K.cyl(ctx, "OldPillarDrum", 4, 3.4, CFrame.new(polar(a + 0.12, 42, 1)) * CFrame.Angles(0, 0, math.pi / 2), PAVE, Enum.Material.Slate, ctx.Props))
	end

	-- ash drifting down over everything, a glow off the sky
	local sky = Instance.new("Part")
	sky.Name = "AshFall"
	sky.Anchored, sky.CanCollide, sky.CanQuery, sky.CanTouch, sky.Transparency = true, false, false, false, 1
	sky.Size = V3(R * 2, 4, R * 2)
	sky.CFrame = CFrame.new(0, 70, 0)
	sky.Parent = ctx.Props
	emitter(sky, {texture = "rbxasset://textures/particles/smoke_main.dds", color = Color3.fromRGB(120, 110, 104), light = 0, size = 0.35,
		life = 14, speed = 1, acc = V3(0.6, -2.4, 0.3), spread = 40, rate = 30, box = true})

	-- where you come in: the south rim, looking in
	for i = -2, 3 do
		local a = math.pi / 2 + i * 0.07
		K.spawn(ctx, polar(a, 96, 1), nil, V3(0, 1, 0))
	end
	K.camera(ctx, V3(30, 26, 112), V3(0, 8, 0))
	K.camera(ctx, V3(-80, 40, -60), V3(10, 4, 20))
	K.lighting(ctx, {ClockTime = 18.3, Brightness = 1.1, Ambient = Color3.fromRGB(96, 60, 52), OutdoorAmbient = Color3.fromRGB(130, 78, 62),
		FogColor = Color3.fromRGB(70, 30, 22), FogEnd = 520, FogStart = 140, ColorShift_Top = Color3.fromRGB(255, 140, 90), ExposureCompensation = 0.1})
	K.atmosphere(ctx, {Density = 0.36, Offset = 0.1, Color = Color3.fromRGB(150, 80, 56), Decay = Color3.fromRGB(110, 46, 30), Glare = 0.4, Haze = 2.2})
	ctx.model:SetAttribute("Generated", true)
	ctx.model:SetAttribute("Centre", V3(0, 0, 0))
	local ok, err = pcall(K.finish, ctx)
	if not ok then
		warn("[CalderaMap] finish:", err)
		local maps = ServerStorage:FindFirstChild("Maps") or Instance.new("Folder")
		maps.Name = "Maps"; maps.Parent = ServerStorage
		ctx.model.Parent = maps
	end
	return name, L
end

return CalderaMap
