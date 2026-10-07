--[[ MAP KIT — builds a playable map Model out of parts (and a slab of
     Terrain) from a short description in Build ▸ Maps. Studio edit mode:

       require(game.ServerScriptService.Build.Maps).build("Sandpit")

     The result lands in ServerStorage ▸ Maps ▸ <Name> (replacing an older
     build of the same name) with everything MapLoader wants: Spawns (Team A /
     B / free), MenuCameras, Zones ▸ Hill, lighting attributes, and a
     TerrainRegion the loader pastes back in. Every helper takes studs; +Y is
     up; a map is centred on the origin and sits on y = 0.

     Helpers:  K.new(name)  K.box  K.wedge  K.cyl  K.ball  K.wall  K.tower
     K.arch  K.stairs  K.awning  K.tent  K.banner  K.pole  K.crate  K.barrel
     K.torch  K.tree  K.rock  K.hay  K.fence  K.spawn  K.camera  K.hill
     K.spot  K.palisade  K.rope  K.rack  K.torchPost
     K.cone  K.lighting  K.terrainColors  K.terrain  K.finish ]]

local ServerStorage = game:GetService("ServerStorage")
local Terrain = workspace.Terrain

local K = {}
local DEG = math.rad
local rnd = Random.new(7)

K.C = {
	SAND = Color3.fromRGB(222, 198, 140), SANDSTONE = Color3.fromRGB(206, 182, 134), SANDDARK = Color3.fromRGB(176, 148, 96),
	STONE = Color3.fromRGB(160, 160, 158), STONEDARK = Color3.fromRGB(112, 112, 112), BLUESTONE = Color3.fromRGB(150, 168, 196),
	WOOD = Color3.fromRGB(124, 86, 52), DARKWOOD = Color3.fromRGB(84, 58, 34), THATCH = Color3.fromRGB(196, 160, 86),
	RED = Color3.fromRGB(176, 42, 42), BLUE = Color3.fromRGB(52, 86, 190), WHITE = Color3.fromRGB(236, 232, 220), GOLD = Color3.fromRGB(222, 176, 64),
	GRASS = Color3.fromRGB(96, 150, 70), LEAF = Color3.fromRGB(70, 130, 60), LEAFDARK = Color3.fromRGB(46, 96, 44), ROPE = Color3.fromRGB(186, 160, 110),
	IRON = Color3.fromRGB(80, 84, 90), FIRE = Color3.fromRGB(255, 160, 60), WATER = Color3.fromRGB(60, 120, 180),
}
K.M = Enum.Material

--------------------------------------------------------------------
--  CONTEXT
--------------------------------------------------------------------
function K.new(name)
	local m = Instance.new("Model")
	m.Name = name
	local ctx = {name = name, model = m, n = 0}
	for _, f in ipairs({"Spawns", "MenuCameras", "Zones", "Geometry", "Props"}) do
		local fo = Instance.new("Folder"); fo.Name = f; fo.Parent = m; ctx[f] = fo
	end
	return ctx
end

local function cf(x, y, z, rx, ry, rz)
	return CFrame.new(x or 0, y or 0, z or 0) * CFrame.Angles(DEG(rx or 0), DEG(ry or 0), DEG(rz or 0))
end
K.cf = cf

--------------------------------------------------------------------
--  PRIMITIVES
--------------------------------------------------------------------
local function base(ctx, class, name, size, frame, color, material, parent)
	local p = Instance.new(class)
	p.Name = name or "Part"
	p.Size = size
	p.CFrame = typeof(frame) == "Vector3" and CFrame.new(frame) or frame
	p.Color = color or K.C.STONE
	p.Material = material or K.M.Slate
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent or ctx.Geometry
	ctx.n += 1
	return p
end
function K.box(ctx, name, size, frame, color, material, parent) return base(ctx, "Part", name, size, frame, color, material, parent) end
function K.wedge(ctx, name, size, frame, color, material, parent) return base(ctx, "WedgePart", name, size, frame, color, material, parent) end
function K.cwedge(ctx, name, size, frame, color, material, parent) return base(ctx, "CornerWedgePart", name, size, frame, color, material, parent) end
function K.cyl(ctx, name, d, h, frame, color, material, parent)
	-- axis along the frame's Y (Roblox cylinders run along X, hence the spin)
	local p = base(ctx, "Part", name, Vector3.new(h, d, d), (typeof(frame) == "Vector3" and CFrame.new(frame) or frame) * CFrame.Angles(0, 0, DEG(90)), color, material, parent)
	p.Shape = Enum.PartType.Cylinder
	return p
end
function K.ball(ctx, name, d, frame, color, material, parent)
	local p = base(ctx, "Part", name, Vector3.new(d, d, d), frame, color, material, parent)
	p.Shape = Enum.PartType.Ball
	return p
end
function K.nocollide(p) p.CanCollide = false; return p end

-- a many-sided cone (a spire roof, a pine's tier): wedges whose tall faces
-- meet at the axis and whose slopes run down and out. base = the centre of the
-- cone's foot; sides (default 12) trades smoothness for parts.
function K.cone(ctx, name, base, r, h, color, material, parent, noCollide, sides)
	sides = sides or 12
	local w = 2 * r * math.tan(math.pi / sides) + 0.06
	for i = 0, sides - 1 do
		local p = K.wedge(ctx, name, Vector3.new(w, h, r), CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 2 * math.pi * i / sides, 0) * CFrame.new(0, 0, r / 2) * CFrame.Angles(0, math.pi, 0), color, material, parent)
		if noCollide then p.CanCollide = false end
	end
end

--------------------------------------------------------------------
--  ARCHITECTURE
--------------------------------------------------------------------
-- a straight wall from a to b (Vector3s on the ground), height h, thickness t;
-- opts: crenels (battlements), color, material, base (a wider footing: baseH
-- tall, baseW wider than the wall; a tall one makes a wall look founded, not sunk), cap
function K.wall(ctx, a, b, h, t, opts)
	opts = opts or {}
	local color, mat = opts.color or K.C.STONE, opts.material or K.M.Slate
	local d = b - a
	local len = d.Magnitude
	local mid = (a + b) / 2
	local look = CFrame.lookAt(mid, b)
	local frame = look * CFrame.new(0, h / 2, 0)
	K.box(ctx, "Wall", Vector3.new(t, h, len), frame, color, mat)
	if opts.base then
		local bh, bw = opts.baseH or 1.2, opts.baseW or 1.2
		K.box(ctx, "Footing", Vector3.new(t + bw, bh, len), look * CFrame.new(0, bh / 2, 0), opts.baseColor or K.C.STONEDARK, mat)
		if bh >= 2 then K.box(ctx, "FootingCap", Vector3.new(t + bw * 0.6, 0.4, len - 0.3), look * CFrame.new(0, bh + 0.2, 0), opts.baseColor or K.C.STONEDARK, mat) end
	end
	if opts.crenels then
		local n = math.max(1, math.floor(len / 3.2))
		for i = 0, n do
			local z = -len / 2 + i * (len / n)
			K.box(ctx, "Crenel", Vector3.new(t, 1.6, 1.6), look * CFrame.new(0, h + 0.8, z), color, mat)
		end
		K.box(ctx, "Walk", Vector3.new(t + 1.0, 0.4, len), look * CFrame.new(0, h, 0), opts.walkColor or K.C.STONEDARK, mat)
	end
	return frame
end

-- a round tower: body, a wider top ring with crenels, an optional cone roof;
-- opts.base = a footing ring that many studs tall
function K.tower(ctx, pos, r, h, opts)
	opts = opts or {}
	local color, mat = opts.color or K.C.STONE, opts.material or K.M.Slate
	K.cyl(ctx, "Tower", r * 2, h, pos + Vector3.new(0, h / 2, 0), color, mat)
	if opts.base then
		K.cyl(ctx, "TowerFooting", r * 2 + 2.4, opts.base, pos + Vector3.new(0, opts.base / 2, 0), opts.baseColor or K.C.STONEDARK, mat)
		K.cyl(ctx, "TowerFootingCap", r * 2 + 1.4, 0.4, pos + Vector3.new(0, opts.base + 0.2, 0), opts.baseColor or K.C.STONEDARK, mat)
	end
	K.cyl(ctx, "TowerTop", r * 2 + 1.6, 1.0, pos + Vector3.new(0, h + 0.5, 0), opts.topColor or K.C.STONEDARK, mat)
	local n = math.max(6, math.floor(r * 2))
	for i = 1, n do
		local a = i / n * 2 * math.pi
		K.box(ctx, "Crenel", Vector3.new(1.2, 1.6, 1.4), CFrame.new(pos + Vector3.new(math.cos(a) * (r + 0.5), h + 1.8, math.sin(a) * (r + 0.5))) * CFrame.Angles(0, -a, 0), color, mat)
	end
	if opts.roof then
		-- a spire: an eight-sided cone over the crenels, a gold finial on top
		local rh = opts.roofH or r * 2.2
		K.cone(ctx, "Roof", pos + Vector3.new(0, h + 1, 0), r + 1.1, rh, opts.roofColor or K.C.RED, K.M.Fabric)
		K.ball(ctx, "Finial", 0.9, pos + Vector3.new(0, h + 1 + rh + 0.3, 0), K.C.GOLD, K.M.Metal)
	end
	if opts.windows then
		for i = 1, 3 do
			local a = i / 3 * 2 * math.pi
			K.box(ctx, "Window", Vector3.new(0.9, 2.2, 0.3), CFrame.new(pos + Vector3.new(math.cos(a) * r, h * 0.6, math.sin(a) * r)) * CFrame.Angles(0, -a + DEG(90), 0), Color3.fromRGB(20, 22, 30), K.M.SmoothPlastic)
		end
	end
end

-- the round part alone: a ring of voussoirs (inner radius R, `ring` thick)
-- springing at height `spring` in the frame, plus stepped fill in the two
-- corners up to the ring's top, so the arch sits in a flat face
function K.archRing(ctx, frame, R, ring, spring, t, color, mat)
	local n = 9
	for i = 0, n - 1 do
		local a0, a1 = math.pi * i / n, math.pi * (i + 1) / n
		local am = (a0 + a1) / 2
		local rm = R + ring / 2
		local seg = 2 * (R + ring) * math.sin((a1 - a0) / 2) + 0.12
		local p = frame * CFrame.new(math.cos(am) * rm, spring + math.sin(am) * rm, 0) * CFrame.Angles(0, 0, am - math.pi / 2)
		K.box(ctx, i == (n - 1) / 2 and "Keystone" or "Voussoir", Vector3.new(seg, ring, t + (i == (n - 1) / 2 and 0.3 or 0.1)), p, color, mat)
	end
	-- the corners between the ring and the top line: stepped fill, wider as it climbs
	for _, s in ipairs({-1, 1}) do
		for k = 1, 4 do
			local y0 = spring + (k - 1) / 4 * (R + ring)
			local y1 = spring + k / 4 * (R + ring)
			local inner = math.sqrt(math.max(0, (R + ring) ^ 2 - (y1 - spring) ^ 2))
			local wdt = (R + ring) - inner + 0.2
			K.box(ctx, "Spandrel", Vector3.new(wdt, y1 - y0, t), frame * CFrame.new(s * ((R + ring) - wdt / 2 + 0.1), (y0 + y1) / 2, 0), color, mat)
		end
	end
end

-- an archway (gate): two piers, a round arch of voussoirs springing from them,
-- filled corners above it and a lintel course on top. The opening (w wide,
-- h tall at the crown) stays clear. The frame's X runs along the wall.
function K.arch(ctx, frame, w, h, t, color, mat)
	color, mat = color or K.C.STONE, mat or K.M.Slate
	local R = w / 2
	local spring = math.max(1.5, h - R)
	local ring = 1.3
	local top = spring + R + ring
	K.box(ctx, "Pier", Vector3.new(1.8, top, t), frame * CFrame.new(-R - 0.9, top / 2, 0), color, mat)
	K.box(ctx, "Pier", Vector3.new(1.8, top, t), frame * CFrame.new(R + 0.9, top / 2, 0), color, mat)
	K.archRing(ctx, frame, R, ring, spring, t, color, mat)
	K.box(ctx, "Lintel", Vector3.new(w + 2 * ring + 3.6, 1.4, t + 0.4), frame * CFrame.new(0, top + 0.7, 0), color, mat)
	return top + 1.4
end

-- a flight of stairs climbing along the frame's -Z (look) direction
function K.stairs(ctx, frame, w, steps, rise, run, color, mat)
	for i = 1, steps do
		K.box(ctx, "Step", Vector3.new(w, rise, run), frame * CFrame.new(0, rise * (i - 0.5), -run * (i - 0.5)), color or K.C.SANDSTONE, mat or K.M.Slate)
	end
	-- a ramp part under them so walking is smooth
	local len = math.sqrt((steps * rise) ^ 2 + (steps * run) ^ 2)
	local ramp = K.box(ctx, "Ramp", Vector3.new(w, 0.3, len), frame * CFrame.new(0, steps * rise / 2, -steps * run / 2) * CFrame.Angles(math.atan2(steps * rise, steps * run), 0, 0), color or K.C.SANDSTONE, mat or K.M.Slate)
	ramp.Transparency = 1
end

-- a cloth sheet strung between four poles (the desert market look)
function K.awning(ctx, pos, w, len, h, color)
	for _, sx in ipairs({-1, 1}) do
		for _, sz in ipairs({-1, 1}) do
			K.cyl(ctx, "Pole", 0.5, h + 1, pos + Vector3.new(sx * w / 2, (h + 1) / 2, sz * len / 2), K.C.DARKWOOD, K.M.Wood)
		end
	end
	local sheet = K.box(ctx, "Awning", Vector3.new(w + 1, 0.15, len + 1), pos + Vector3.new(0, h, 0), color or K.C.RED, K.M.Fabric)
	sheet.CanCollide = false
	-- a sag: a slightly lower middle strip
	K.box(ctx, "AwningSag", Vector3.new(w * 0.6, 0.15, len * 0.6), pos + Vector3.new(0, h - 0.5, 0), color or K.C.RED, K.M.Fabric).CanCollide = false
	for _, sx in ipairs({-1, 1}) do
		K.box(ctx, "Rope", Vector3.new(0.1, 0.1, len + 1), pos + Vector3.new(sx * (w / 2 + 0.3), h + 0.2, 0), K.C.ROPE, K.M.Fabric).CanCollide = false
	end
end

-- a ridge tent: two sloped sheets, open front
function K.tent(ctx, frame, w, len, h, color)
	for _, s in ipairs({-1, 1}) do
		local side = math.sqrt((w / 2) ^ 2 + h ^ 2)
		local ang = math.atan2(h, w / 2)
		K.box(ctx, "TentSide", Vector3.new(side, 0.2, len), frame * CFrame.new(s * w / 4, h / 2, 0) * CFrame.Angles(0, 0, -s * ang), color or K.C.WHITE, K.M.Fabric)
	end
	K.box(ctx, "TentRidge", Vector3.new(0.3, 0.3, len + 0.6), frame * CFrame.new(0, h, 0), K.C.DARKWOOD, K.M.Wood)
	K.cyl(ctx, "Pole", 0.4, h, frame * CFrame.new(0, h / 2, len / 2 - 0.3), K.C.DARKWOOD, K.M.Wood)
	K.cyl(ctx, "Pole", 0.4, h, frame * CFrame.new(0, h / 2, -len / 2 + 0.3), K.C.DARKWOOD, K.M.Wood)
	local back = K.wedge(ctx, "TentBack", Vector3.new(w, h, 0.2), frame * CFrame.new(0, h / 2, len / 2) * CFrame.Angles(0, 0, 0), color or K.C.WHITE, K.M.Fabric)
	back:Destroy()   -- triangles are fiddly in parts: leave the back open, the sides sell it
end

-- a hanging banner on a pole with a crossbar
function K.banner(ctx, pos, h, color, parent)
	K.cyl(ctx, "Pole", 0.4, h, pos + Vector3.new(0, h / 2, 0), K.C.DARKWOOD, K.M.Wood, parent)
	K.box(ctx, "Crossbar", Vector3.new(2.6, 0.25, 0.25), pos + Vector3.new(0, h - 0.4, 0), K.C.DARKWOOD, K.M.Wood, parent)
	local cloth = K.box(ctx, "Banner", Vector3.new(2.2, h * 0.45, 0.1), pos + Vector3.new(0, h - 0.6 - h * 0.225, 0.2), color or K.C.RED, K.M.Fabric, parent)
	cloth.CanCollide = false
	for _, s in ipairs({-1, 1}) do
		K.wedge(ctx, "BannerTip", Vector3.new(0.1, 0.8, 1.1), CFrame.new(pos + Vector3.new(s * 0.55, h - 0.6 - h * 0.45 - 0.4, 0.2)) * CFrame.Angles(0, DEG(-90 * s), 0) * CFrame.Angles(0, 0, math.pi), color or K.C.RED, K.M.Fabric, parent).CanCollide = false
	end
	K.ball(ctx, "Finial", 0.5, pos + Vector3.new(0, h + 0.2, 0), K.C.GOLD, K.M.Metal, parent)
end
function K.pole(ctx, pos, h, color) return K.cyl(ctx, "Pole", 0.45, h, pos + Vector3.new(0, h / 2, 0), color or K.C.DARKWOOD, K.M.Wood) end

--------------------------------------------------------------------
--  PROPS
--------------------------------------------------------------------
function K.crate(ctx, pos, s, ry)
	s = s or 3
	local c = K.box(ctx, "Crate", Vector3.new(s, s, s), CFrame.new(pos + Vector3.new(0, s / 2, 0)) * CFrame.Angles(0, DEG(ry or 0), 0), K.C.WOOD, K.M.WoodPlanks, ctx.Props)
	for _, a in ipairs({0, 90}) do
		K.box(ctx, "Band", Vector3.new(s + 0.1, 0.3, s + 0.1), c.CFrame * CFrame.Angles(0, DEG(a), 0) * CFrame.new(0, s * 0.3, 0), K.C.DARKWOOD, K.M.Wood, ctx.Props).CanCollide = false
	end
	return c
end
function K.barrel(ctx, pos)
	local b = K.cyl(ctx, "Barrel", 2.2, 3, pos + Vector3.new(0, 1.5, 0), K.C.WOOD, K.M.Wood, ctx.Props)
	for _, y in ipairs({0.6, 2.4}) do K.cyl(ctx, "Hoop", 2.3, 0.2, pos + Vector3.new(0, y, 0), K.C.IRON, K.M.Metal, ctx.Props).CanCollide = false end
	return b
end
function K.torch(ctx, pos, ry)
	local base2 = K.box(ctx, "Bracket", Vector3.new(0.3, 0.3, 0.8), CFrame.new(pos) * CFrame.Angles(0, DEG(ry or 0), 0), K.C.IRON, K.M.Metal, ctx.Props)
	local stick = K.cyl(ctx, "Torch", 0.3, 1.6, pos + Vector3.new(0, 0.6, 0), K.C.DARKWOOD, K.M.Wood, ctx.Props)
	local flame = K.ball(ctx, "Flame", 0.7, pos + Vector3.new(0, 1.6, 0), K.C.FIRE, K.M.Neon, ctx.Props)
	flame.CanCollide = false
	local light = Instance.new("PointLight"); light.Color = K.C.FIRE; light.Range = 14; light.Brightness = 1.6; light.Parent = flame
	local fire = Instance.new("Fire"); fire.Size = 2; fire.Heat = 4; fire.Parent = flame
	return flame
end
-- a pine: a trunk and three stacked wedge-pyramids (cones from parts)
function K.tree(ctx, pos, h, color)
	h = h or 12
	K.cyl(ctx, "Trunk", 0.9, h * 0.35, pos + Vector3.new(0, h * 0.175, 0), K.C.DARKWOOD, K.M.Wood, ctx.Props)
	for i = 0, 2 do
		local r = h * (0.3 - i * 0.075)
		local y = h * (0.28 + i * 0.22)
		K.cone(ctx, "Leaves", pos + Vector3.new(0, y, 0), r, h * 0.36, color or (i == 0 and K.C.LEAFDARK or K.C.LEAF), K.M.Grass, ctx.Props, true, 8)
	end
end
-- a boulder: three overlapping balls, flattened
function K.rock(ctx, pos, s, color)
	s = s or 4
	for i = 1, 3 do
		local off = Vector3.new(rnd:NextNumber(-s * 0.3, s * 0.3), rnd:NextNumber(0, s * 0.2), rnd:NextNumber(-s * 0.3, s * 0.3))
		local b = K.ball(ctx, "Rock", s * rnd:NextNumber(0.7, 1.1), pos + off + Vector3.new(0, s * 0.3, 0), color or K.C.STONEDARK, K.M.Slate, ctx.Props)
		b.Size = Vector3.new(b.Size.X, b.Size.Y * 0.7, b.Size.Z)
	end
end
function K.hay(ctx, pos)
	local b = K.cyl(ctx, "Hay", 3, 3.2, CFrame.new(pos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, DEG(90)), K.C.THATCH, K.M.Grass, ctx.Props)
	return b
end
function K.fence(ctx, a, b, h)
	h = h or 2.4
	local d = (b - a); local len = d.Magnitude; local look = CFrame.lookAt((a + b) / 2, b)
	local n = math.max(1, math.floor(len / 4))
	for i = 0, n do K.box(ctx, "Post", Vector3.new(0.4, h, 0.4), look * CFrame.new(0, h / 2, -len / 2 + i * len / n), K.C.DARKWOOD, K.M.Wood, ctx.Props) end
	for _, y in ipairs({h * 0.45, h * 0.85}) do K.box(ctx, "Rail", Vector3.new(0.25, 0.3, len), look * CFrame.new(0, y, 0), K.C.WOOD, K.M.Wood, ctx.Props).CanCollide = false end
end
function K.house(ctx, frame, w, len, h, wallColor, roofColor)
	K.box(ctx, "House", Vector3.new(w, h, len), frame * CFrame.new(0, h / 2, 0), wallColor or K.C.WHITE, K.M.Concrete)
	K.box(ctx, "Beams", Vector3.new(w + 0.2, 0.4, len + 0.2), frame * CFrame.new(0, h * 0.55, 0), K.C.DARKWOOD, K.M.Wood).CanCollide = false
	local rh = w * 0.45
	for _, s in ipairs({-1, 1}) do
		local side = math.sqrt((w / 2 + 0.6) ^ 2 + rh ^ 2)
		K.box(ctx, "Roof", Vector3.new(side, 0.4, len + 1.2), frame * CFrame.new(s * (w / 4 + 0.3), h + rh / 2, 0) * CFrame.Angles(0, 0, -s * math.atan2(rh, w / 2 + 0.6)), roofColor or K.C.DARKWOOD, K.M.WoodPlanks)
	end
	for _, zf in ipairs({len / 2 - 0.15, -len / 2 + 0.15}) do
		for _, s in ipairs({-1, 1}) do
			K.wedge(ctx, "Gable", Vector3.new(0.3, rh, w / 2), frame * CFrame.new(s * w / 4, h + rh / 2, zf) * CFrame.Angles(0, DEG(-90 * s), 0), wallColor or K.C.WHITE, K.M.Concrete)
		end
	end
	K.box(ctx, "Door", Vector3.new(2.2, 3.4, 0.2), frame * CFrame.new(0, 1.7, len / 2 + 0.05), K.C.DARKWOOD, K.M.Wood).CanCollide = false
	for _, s in ipairs({-1, 1}) do K.box(ctx, "Window", Vector3.new(1.6, 1.6, 0.2), frame * CFrame.new(s * w * 0.3, h * 0.6, len / 2 + 0.05), Color3.fromRGB(60, 70, 90), K.M.Glass).CanCollide = false end
end

--------------------------------------------------------------------
--  GAMEPLAY MARKERS
--------------------------------------------------------------------
function K.spawn(ctx, pos, team, look)
	local p = Instance.new("Part")
	p.Name = "Spawn"
	p.Size = Vector3.new(2, 1, 2)
	p.CFrame = look and CFrame.lookAt(pos, look) or CFrame.new(pos)
	p.Anchored, p.CanCollide, p.Transparency = true, false, 1
	if team then p:SetAttribute("Team", team) end
	p.Parent = ctx.Spawns
	return p
end
-- a marker the game scripts look for (Map ▸ Spots ▸ <name>): where an NPC
-- stands, where a sign is, the middle of a ring… attrs become attributes
function K.spot(ctx, name, frame, attrs)
	if not ctx.Spots then
		local fo = Instance.new("Folder"); fo.Name = "Spots"; fo.Parent = ctx.model; ctx.Spots = fo
	end
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = typeof(frame) == "Vector3" and CFrame.new(frame) or frame
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	for k, v in pairs(attrs or {}) do p:SetAttribute(k, v) end
	p.Parent = ctx.Spots
	return p
end
-- a palisade of upright logs from a to b (on the ground), h tall, with a binding rail
function K.palisade(ctx, a, b, h, gap)
	h = h or 7
	local d = b - a
	local len = d.Magnitude
	local n = math.max(1, math.floor(len / (gap or 1.9)))
	for i = 0, n do
		local p = a + d * (i / n)
		local hh = h + ((i * 7919) % 5) * 0.18
		K.cyl(ctx, "Log", 1.8, hh, p + Vector3.new(0, hh / 2, 0), (i % 3 == 0) and K.C.DARKWOOD or K.C.WOOD, K.M.Wood)
		K.cone(ctx, "LogTip", p + Vector3.new(0, hh, 0), 0.9, 0.9, K.C.DARKWOOD, K.M.Wood, nil, true, 4)
	end
	local look = CFrame.lookAt((a + b) / 2, b)
	K.box(ctx, "Rail", Vector3.new(0.5, 0.5, len), look * CFrame.new(0, h * 0.75, -0.95), K.C.DARKWOOD, K.M.Wood).CanCollide = false
end
-- a rope strung between two points (in the air)
function K.rope(ctx, a, b, color)
	local d = b - a
	local r = K.box(ctx, "Rope", Vector3.new(0.18, 0.18, d.Magnitude), CFrame.lookAt((a + b) / 2, b), color or K.C.ROPE, K.M.Fabric)
	r.CanCollide = false
	return r
end
-- a weapon rack: two posts, a bar, swords and spears leaning on it
function K.rack(ctx, frame)
	for _, x in ipairs({-2.2, 2.2}) do K.box(ctx, "RackPost", Vector3.new(0.4, 3.2, 0.4), frame * CFrame.new(x, 1.6, 0), K.C.DARKWOOD, K.M.Wood) end
	K.box(ctx, "RackBar", Vector3.new(5, 0.3, 0.3), frame * CFrame.new(0, 2.6, 0), K.C.DARKWOOD, K.M.Wood)
	K.box(ctx, "RackFoot", Vector3.new(5, 0.3, 1.2), frame * CFrame.new(0, 0.15, 0.4), K.C.DARKWOOD, K.M.Wood)
	for i = -2, 2 do
		local x = i * 0.9
		local tall = (i % 2 == 0)
		local len = tall and 5.4 or 3.6
		local w = K.box(ctx, tall and "Spear" or "Sword", Vector3.new(tall and 0.16 or 0.3, len, tall and 0.16 or 0.08), frame * CFrame.new(x, len / 2, 0.55) * CFrame.Angles(math.rad(-12), 0, 0), tall and K.C.WOOD or Color3.fromRGB(196, 200, 210), tall and K.M.Wood or K.M.Metal)
		w.CanCollide = false
		if tall then K.box(ctx, "SpearHead", Vector3.new(0.3, 0.7, 0.1), w.CFrame * CFrame.new(0, len / 2 + 0.3, 0), Color3.fromRGB(196, 200, 210), K.M.Metal).CanCollide = false
		else K.box(ctx, "Guard", Vector3.new(1, 0.15, 0.2), w.CFrame * CFrame.new(0, -len / 2 + 0.8, 0), K.C.DARKWOOD, K.M.Wood).CanCollide = false end
	end
end
-- a torch on a tall post (a brazier bowl, fire, light)
function K.torchPost(ctx, pos, h)
	h = h or 6
	K.cyl(ctx, "TorchPost", 0.5, h, pos + Vector3.new(0, h / 2, 0), K.C.DARKWOOD, K.M.Wood)
	K.cyl(ctx, "TorchBowl", 1.4, 0.6, pos + Vector3.new(0, h + 0.3, 0), K.C.IRON, K.M.Metal)
	local flame = K.ball(ctx, "Flame", 0.9, pos + Vector3.new(0, h + 0.8, 0), K.C.FIRE, K.M.Neon)
	flame.CanCollide = false
	local light = Instance.new("PointLight"); light.Color = K.C.FIRE; light.Range = 16; light.Brightness = 1.4; light.Parent = flame
	local fire = Instance.new("Fire"); fire.Size = 2.5; fire.Heat = 5; fire.Parent = flame
	return flame
end

--------------------------------------------------------------------
--  SIEGE PIECES (Game ▸ Modes ▸ Siege reads Map ▸ Objectives)
--------------------------------------------------------------------
-- a stage: Objectives ▸ <order>, a Configuration whose attributes are the
-- stage's settings (Kind, Label, AddTime…); its pieces go inside it
function K.objective(ctx, order, kind, attrs)
	if not ctx.Objectives then
		local fo = Instance.new("Folder"); fo.Name = "Objectives"; fo.Parent = ctx.model; ctx.Objectives = fo
	end
	local c = Instance.new("Configuration")
	c.Name = tostring(order)
	c:SetAttribute("Order", order)
	c:SetAttribute("Kind", kind)
	for k, v in pairs(attrs or {}) do c:SetAttribute(k, v) end
	c.Parent = ctx.Objectives
	return c
end

-- a capture zone: a flat see-through disc on the ground (radius r; h tall for the inside test)
function K.zone(ctx, parent, name, pos, r, h)
	local z = Instance.new("Part")
	z.Name = name or "Zone"
	z.Shape = Enum.PartType.Cylinder
	z.Size = Vector3.new(0.3, r * 2, r * 2)
	z.CFrame = CFrame.new(pos + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, 0, DEG(90))
	z.Anchored, z.CanCollide, z.CanQuery, z.CanTouch = true, false, false, false
	z.Material = K.M.Neon
	z.Color = K.C.WHITE
	z.Transparency = 0.8
	z:SetAttribute("Radius", r)
	z:SetAttribute("Height", h or 10)
	z.Parent = parent or ctx.Zones
	return z
end

-- the road a ram rolls along: invisible markers P1..Pn on the ground
function K.path(ctx, parent, points)
	local f = Instance.new("Folder"); f.Name = "Path"; f.Parent = parent
	for i, p in ipairs(points) do
		local m = Instance.new("Part"); m.Name = "P" .. i; m.Size = Vector3.new(1, 1, 1); m.CFrame = CFrame.new(p)
		m.Anchored, m.CanCollide, m.CanQuery, m.CanTouch, m.Transparency = true, false, false, false, 1
		m.Parent = f
	end
	return f
end

-- a battering ram: a wheeled frame under a peaked hide roof, the log hung on
-- chains. A Model whose PrimaryPart "Body" is its pivot; parts with attribute
-- Swing (the log, its head, the chains) are what swings at the gate. It faces
-- the frame's -Z (look): stand it at the start of its path looking down the road.
function K.ram(ctx, parent, frame)
	local m = Instance.new("Model"); m.Name = "Ram"; m.Parent = parent
	local function part(name, size, cf, color, mat, collide)
		local p = K.box(ctx, name, size, frame * cf, color, mat, m)
		p.CanCollide = collide ~= false
		return p
	end
	local body = part("Body", Vector3.new(6.4, 0.8, 15), CFrame.new(0, 1.6, 0), K.C.DARKWOOD, K.M.WoodPlanks)
	m.PrimaryPart = body
	for _, x in ipairs({-2.9, 2.9}) do
		part("Rail", Vector3.new(0.7, 0.7, 15.4), CFrame.new(x, 2.3, 0), K.C.WOOD, K.M.Wood)
		for _, z in ipairs({-6.6, 0, 6.6}) do part("Post", Vector3.new(0.6, 6.2, 0.6), CFrame.new(x, 5.1, z), K.C.WOOD, K.M.Wood) end
		part("Beam", Vector3.new(0.6, 0.6, 15), CFrame.new(x, 8.2, 0), K.C.WOOD, K.M.Wood)
	end
	for _, z in ipairs({-6.6, 0, 6.6}) do part("CrossBeam", Vector3.new(6.4, 0.5, 0.5), CFrame.new(0, 8.2, z), K.C.WOOD, K.M.Wood) end
	-- the roof: two sloped planked sides under a stitched hide
	for _, s in ipairs({-1, 1}) do
		part("Roof", Vector3.new(4.4, 0.35, 15.8), CFrame.new(s * 1.8, 9.3, 0) * CFrame.Angles(0, 0, DEG(-s * 33)), K.C.DARKWOOD, K.M.WoodPlanks)
		part("Hide", Vector3.new(4.5, 0.12, 16.2), CFrame.new(s * 1.84, 9.52, 0) * CFrame.Angles(0, 0, DEG(-s * 33)), Color3.fromRGB(120, 92, 66), K.M.Fabric, false)
	end
	part("RoofRidge", Vector3.new(0.5, 0.5, 16.2), CFrame.new(0, 10.5, 0), K.C.DARKWOOD, K.M.Wood)
	-- wheels (axles across, X)
	for _, x in ipairs({-3.6, 3.6}) do
		for _, z in ipairs({-5, 5}) do
			K.cyl(ctx, "Wheel", 3.2, 0.7, frame * CFrame.new(x, 1.6, z) * CFrame.Angles(0, 0, DEG(90)), K.C.DARKWOOD, K.M.Wood, m)
			K.cyl(ctx, "Hub", 1, 0.9, frame * CFrame.new(x, 1.6, z) * CFrame.Angles(0, 0, DEG(90)), K.C.IRON, K.M.Metal, m)
		end
	end
	-- the log on its chains, an iron ram's head at the front
	local log = K.cyl(ctx, "Log", 1.7, 16, frame * CFrame.new(0, 4.6, -1.2) * CFrame.Angles(DEG(-90), 0, 0), Color3.fromRGB(110, 78, 46), K.M.Wood, m)
	log.CanCollide = false; log:SetAttribute("Swing", true)
	local head = K.cyl(ctx, "RamHead", 2.3, 2.2, frame * CFrame.new(0, 4.6, -9.9) * CFrame.Angles(DEG(-90), 0, 0), K.C.IRON, K.M.Metal, m)
	head.CanCollide = false; head:SetAttribute("Swing", true)
	local tip = K.cone(ctx, "RamTip", Vector3.zero, 1.15, 1.4, K.C.IRON, K.M.Metal, m, true, 8)
	for _, d in ipairs(m:GetChildren()) do
		if d.Name == "RamTip" then
			-- the cone was built at the origin pointing up: lay it at the head pointing forward
			d.CFrame = frame * CFrame.new(0, 4.6, -11) * CFrame.Angles(DEG(-90), 0, 0) * d.CFrame
			d:SetAttribute("Swing", true)
		end
	end
	for _, z in ipairs({-5.8, 3.4}) do
		for _, x in ipairs({-1.1, 1.1}) do
			local ch = K.box(ctx, "Chain", Vector3.new(0.18, 3.4, 0.18), frame * CFrame.new(x * 0.9, 6.3, z) * CFrame.Angles(0, 0, DEG(x * 9)), K.C.IRON, K.M.Metal, m)
			ch.CanCollide = false; ch:SetAttribute("Swing", true)
		end
	end
	return m
end

-- a gate the ram breaks: two studded doors with iron bands, w × h, in a Model
-- "Gate" (attribute Hits = blows it takes). The frame is the middle of the
-- doorway at ground level; its +Z faces the attackers (studs outside, the bar inside).
function K.gate(ctx, parent, frame, w, h, hits)
	local m = Instance.new("Model"); m.Name = "Gate"; m.Parent = parent
	m:SetAttribute("Hits", hits or 10)
	for _, s in ipairs({-1, 1}) do
		local door = K.box(ctx, "Door", Vector3.new(w / 2 - 0.1, h, 1.4), frame * CFrame.new(s * w / 4, h / 2, 0), Color3.fromRGB(96, 66, 40), K.M.WoodPlanks, m)
		for _, y in ipairs({0.18, 0.5, 0.82}) do
			K.box(ctx, "Band", Vector3.new(w / 2 - 0.3, 0.7, 1.6), frame * CFrame.new(s * w / 4, h * y, 0), K.C.IRON, K.M.Metal, m)
		end
		for i = 0, 3 do
			for j = 0, 5 do
				K.ball(ctx, "Stud", 0.4, frame * CFrame.new(s * (0.9 + i * (w / 2 - 1.8) / 3), 1.4 + j * (h - 2.8) / 5, 0.8), K.C.IRON, K.M.Metal, m).CanCollide = false
			end
		end
		door:SetAttribute("Side", s)
	end
	K.box(ctx, "Bar", Vector3.new(w - 0.6, 0.9, 0.8), frame * CFrame.new(0, h * 0.5, -1.1), K.C.DARKWOOD, K.M.Wood, m)
	return m
end

function K.camera(ctx, pos, look)
	local p = Instance.new("Part")
	p.Name = string.format("Shot%d", #ctx.MenuCameras:GetChildren() + 1)
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.lookAt(pos, look)
	p.Anchored, p.CanCollide, p.Transparency = true, false, 1
	p.Parent = ctx.MenuCameras
	return p
end
function K.hill(ctx, pos, r, h)
	local z = Instance.new("Part")
	z.Name = "Hill"
	z.Shape = Enum.PartType.Cylinder
	z.Size = Vector3.new(h or 8, r * 2, r * 2)
	z.CFrame = CFrame.new(pos + Vector3.new(0, (h or 8) / 2, 0)) * CFrame.Angles(0, 0, DEG(90))
	z.Anchored, z.CanCollide = true, false
	z.Transparency = 0.8
	z.Color = K.C.GOLD
	z.Material = K.M.Neon
	z.Parent = ctx.Zones
	return z
end
-- lighting for this map: MapLoader applies these attributes on load
function K.lighting(ctx, t)
	for k, v in pairs(t) do ctx.model:SetAttribute("Light_" .. k, v) end
end
-- the Atmosphere while the map is up (Density, Offset, Color, Decay, Glare,
-- Haze): with an Atmosphere in Lighting this, not FogEnd, is the map's haze
function K.atmosphere(ctx, t)
	for k, v in pairs(t) do ctx.model:SetAttribute("Atmo_" .. k, v) end
end

--------------------------------------------------------------------
--  TERRAIN — paint into workspace.Terrain inside `region`, then copy the
--  voxels into the map (a TerrainRegion) and clear them from the world
--------------------------------------------------------------------
-- terrain colours for this map (MapLoader sets them on load, restores on unload)
function K.terrainColors(ctx, t)
	for mat, c in pairs(t) do ctx.model:SetAttribute("TerrainColor_" .. mat, c) end
end

function K.terrain(ctx, corner, size, paint)
	local region = Region3.new(corner, corner + size):ExpandToGrid(4)
	Terrain:FillRegion(region, 4, Enum.Material.Air)
	-- a brush that reaches past the region (a hill ball near the edge) would
	-- leave voxels in the place for good, under every map: the band around the
	-- region is put back exactly as it was before painting
	local SPILL = 96
	local outer = Region3.new(corner - Vector3.one * SPILL, corner + size + Vector3.one * SPILL):ExpandToGrid(4)
	local keepM, keepO = Terrain:ReadVoxels(outer, 4)
	-- Roblox draws a terrain surface half a voxel (2 studs) above where a fill
	-- ends: ground filled up to y = 0 stands at y = 2, burying everything built
	-- on y = 0. The brushes the maps paint with are lowered by those 2 studs, so
	-- a map's numbers mean what they say: fill to y = 0 and the ground is at 0.
	local DROP = Vector3.new(0, 2, 0)
	local brush = {}
	function brush:FillBlock(cf, sz, mat) return Terrain:FillBlock(cf - DROP, sz, mat) end
	function brush:FillBall(c, r, mat) return Terrain:FillBall(c - DROP, r, mat) end
	function brush:FillCylinder(cf, h, r, mat) return Terrain:FillCylinder(cf - DROP, h, r, mat) end
	function brush:FillWedge(cf, sz, mat) return Terrain:FillWedge(cf - DROP, sz, mat) end
	function brush:FillRegion(r, res, mat) return Terrain:FillRegion(r, res, mat) end
	-- a flat-topped hill written voxel by voxel, so its top stands at exactly
	-- `top` studs above c (stacked thin fills round each part-filled voxel up
	-- to full, which lifts a hill by up to a whole voxel): flat out to
	-- `plateau`, an eased slope down to the ground at `foot`
	function brush:Mound(c, top, plateau, foot, mat)
		local region = Region3.new(c - Vector3.new(foot + 4, 8, foot + 4), c + Vector3.new(foot + 4, top + 8, foot + 4)):ExpandToGrid(4)
		local mats, occs = Terrain:ReadVoxels(region, 4)
		local lo = region.CFrame.Position - region.Size / 2
		for ix = 1, mats.Size.X do
			for iz = 1, mats.Size.Z do
				local d = Vector2.new(lo.X + (ix - 0.5) * 4 - c.X, lo.Z + (iz - 0.5) * 4 - c.Z).Magnitude
				if d < foot then
					local t = math.clamp((d - plateau) / math.max(foot - plateau, 1), 0, 1)
					local s = c.Y + top * (1 - t * t * (3 - 2 * t)) - DROP.Y   -- where the fill ends for the surface to stand there
					for iy = 1, mats.Size.Y do
						local o = math.clamp((s - (lo.Y + (iy - 1) * 4)) / 4, 0, 1)
						if o > occs[ix][iy][iz] then occs[ix][iy][iz] = o; mats[ix][iy][iz] = mat end
					end
				end
			end
		end
		Terrain:WriteVoxels(region, 4, mats, occs)
	end
	local ok, err = pcall(paint, brush)
	if not ok then Terrain:WriteVoxels(outer, 4, keepM, keepO); error(err) end
	-- CopyRegion wants voxel coordinates (studs / 4)
	local lo = region.CFrame.Position - region.Size / 2
	local hi = region.CFrame.Position + region.Size / 2
	local r16 = Region3int16.new(Vector3int16.new(lo.X / 4, lo.Y / 4, lo.Z / 4), Vector3int16.new(hi.X / 4, hi.Y / 4, hi.Z / 4))
	local tr = Terrain:CopyRegion(r16)
	tr.Name = "Terrain"
	tr.Parent = ctx.model
	local c = region.CFrame.Position - region.Size / 2
	ctx.model:SetAttribute("TerrainCorner", c)
	ctx.model:SetAttribute("TerrainSize", region.Size)
	-- the region was empty before, so this clears it and undoes any spill
	Terrain:WriteVoxels(outer, 4, keepM, keepO)
end

-- a spawn that ended up inside something solid (a wagon, a tent, a barrel) is
-- walked out along its line from the map's middle (or to either side) until a
-- body fits there
function K.clearSpawns(ctx)
	local was = ctx.model.Parent
	ctx.model.Parent = workspace            -- (bounds queries only see the workspace)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {ctx.Geometry, ctx.Props}
	local function blocked(pos)
		for _, h in ipairs(workspace:GetPartBoundsInBox(CFrame.new(pos + Vector3.new(0, 2.6, 0)), Vector3.new(3, 4.6, 3), params)) do
			if h.CanCollide then return true end
		end
		return false
	end
	local moved = 0
	for _, sp in ipairs(ctx.Spawns:GetChildren()) do
		local p = sp.Position
		if blocked(p) then
			local out = Vector3.new(p.X, 0, p.Z)
			out = out.Magnitude > 0.1 and out.Unit or Vector3.new(1, 0, 0)
			local side = Vector3.new(-out.Z, 0, out.X)
			for step = 1, 24 do
				local q
				for _, d in ipairs({out * step, side * step, -side * step}) do
					if not blocked(p + d) then q = p + d; break end
				end
				if q then sp.CFrame = sp.CFrame + (q - p); moved += 1; break end
			end
		end
	end
	ctx.model.Parent = was
	return moved
end

function K.finish(ctx)
	local maps = ServerStorage:FindFirstChild("Maps") or Instance.new("Folder")
	maps.Name = "Maps"; maps.Parent = ServerStorage
	local old = maps:FindFirstChild(ctx.name)
	if old then old:Destroy() end
	-- faces laid flush on faces (a path over a path, a trim on a wall) flicker: nudge them apart
	-- (a Defight beside this module wins: a fresh copy for a build run from the command bar)
	local fixed = require(script.Parent:FindFirstChild("Defight") or game:GetService("ReplicatedStorage"):WaitForChild("Defight")).run(ctx.model)
	local moved = K.clearSpawns(ctx)
	ctx.model:SetAttribute("Built", true)
	ctx.model.Parent = maps
	print(string.format("[MapKit] %s: %d parts, %d flush faces nudged apart, %d spawns moved clear of props", ctx.name, ctx.n, fixed, moved))
	return ctx.model
end

return K
