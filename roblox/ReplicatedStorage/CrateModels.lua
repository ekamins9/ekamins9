--[[ CRATE MODELS — every crate as a real 3D chest, built from parts (no
     meshes, so a new crate needs no art): a planked body, a stepped lid, metal
     straps and corner caps in the crate's metal, a lock, and a glowing emblem
     on the front that says what's inside (a sword, an axe, a gem, a skull…).
     The menu's crate gallery turns them in ViewportFrames, and a crate bursts
     open (lid flung back, light pouring out) before its reel spins.

       local model, rig = CrateModels.build(crateId [, crateDef])
         model             a Model (PrimaryPart "Base", the base's bottom at y = 0)
         rig.setLid(a)     open the lid by `a` radians about its back hinge (0 = shut)
         rig.glow(k)       the light inside, 0..1 (rays and the inner glow)
         rig.height        studs to the top of the shut lid
       CrateModels.LOOKS   per crate: {wood, metal, emblem, glow}; a crate with no
                           entry takes its accent colour and a star

     A crate's look can also sit on the crate itself (Catalog ▸ Crates): look =
     {wood = Color3, metal = Color3, emblem = "skull", glow = Color3}. Emblems:
     sword · axe · hammer · gem · arrow · skull · crown · star · anchor · flame ]]

local CrateModels = {}

local C = Color3.fromRGB
local OAK, DARK_OAK, IRON, GOLD = C(120, 74, 38), C(70, 42, 22), C(150, 156, 168), C(232, 184, 74)

CrateModels.LOOKS = {
	Bladesmith = {wood = OAK, metal = IRON, emblem = "sword", glow = C(200, 220, 255)},
	Hafted     = {wood = DARK_OAK, metal = C(170, 130, 90), emblem = "axe", glow = C(255, 190, 120)},
	Relic      = {wood = C(52, 40, 74), metal = C(170, 150, 255), emblem = "gem", glow = C(170, 120, 255)},
	Fletcher   = {wood = C(96, 82, 44), metal = C(120, 170, 80), emblem = "arrow", glow = C(170, 255, 120)},
	Grim       = {wood = C(30, 34, 30), metal = C(90, 170, 100), emblem = "skull", glow = C(110, 255, 140)},
	Royal      = {wood = C(90, 20, 30), metal = GOLD, emblem = "crown", glow = C(255, 220, 120)},
	Ossuary    = {wood = C(150, 140, 118), metal = C(222, 210, 182), emblem = "skull", glow = C(255, 240, 200)},
	Hollow     = {wood = C(40, 26, 20), metal = C(255, 140, 40), emblem = "flame", glow = C(255, 150, 40)},
	Foundry    = {wood = C(54, 50, 50), metal = C(255, 150, 70), emblem = "hammer", glow = C(255, 130, 50)},
	WildHunt   = {wood = C(80, 58, 34), metal = C(150, 230, 120), emblem = "arrow", glow = C(150, 255, 120)},
	Longship   = {wood = C(84, 64, 46), metal = C(120, 200, 255), emblem = "axe", glow = C(120, 210, 255)},
	Rime       = {wood = C(150, 190, 220), metal = C(220, 245, 255), emblem = "star", glow = C(170, 230, 255)},
	Yule       = {wood = C(120, 24, 24), metal = C(240, 240, 240), emblem = "star", glow = C(255, 230, 140)},
	BlackSails = {wood = C(36, 40, 44), metal = C(90, 255, 210), emblem = "anchor", glow = C(90, 255, 210)},
}

local W, D, H = 4, 2.6, 2.1          -- the body: wide, deep, tall
local LID_H, CAP_H = 0.7, 0.36       -- the lid and the step on top of it

local function part(model, size, cf, color, material, name)
	local p = Instance.new("Part")
	p.Name = name or "Part"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = model
	return p
end
local function ball(model, d, cf, color, material)
	local p = part(model, Vector3.new(d, d, d), cf, color, material, "Ball")
	p.Shape = Enum.PartType.Ball
	return p
end

-- the emblem on the front, centred at `at` (facing -Z), `s` studs tall, glowing
local function emblem(model, kind, at, s, color)
	local NEON, M = Enum.Material.Neon, Enum.Material.Metal
	local dark = C(16, 16, 20)
	local function b(sx, sy, x, y, rot, mat, col)
		return part(model, Vector3.new(sx * s, sy * s, 0.08), at * CFrame.new(x * s, y * s, 0) * CFrame.Angles(0, 0, math.rad(rot or 0)), col or color, mat or NEON, "Emblem")
	end
	if kind == "sword" then
		b(0.14, 0.72, 0, 0.1); b(0.5, 0.1, 0, -0.28); b(0.1, 0.22, 0, -0.42); b(0.16, 0.16, 0, -0.56, 45)
	elseif kind == "axe" then
		b(0.1, 1.0, 0.05, 0, 0, M, C(110, 80, 50)); b(0.42, 0.4, -0.18, 0.24); b(0.22, 0.48, -0.36, 0.24)
	elseif kind == "hammer" then
		b(0.1, 0.9, 0, -0.05, 0, M, C(110, 80, 50)); b(0.62, 0.28, 0, 0.36); b(0.1, 0.36, 0.33, 0.36)
	elseif kind == "gem" then
		b(0.5, 0.5, 0, 0.02, 45); b(0.28, 0.28, 0, 0.02, 45, NEON, color:Lerp(Color3.new(1, 1, 1), 0.6))
	elseif kind == "arrow" then
		b(0.08, 0.95, 0, -0.05, -45, M, C(130, 100, 60)); b(0.26, 0.26, 0.27, 0.27, 0); b(0.1, 0.3, -0.33, -0.36, -45)
	elseif kind == "skull" then
		local sk = ball(model, 0.62 * s, at * CFrame.new(0, 0.1 * s, 0.1), color, NEON); sk.Name = "Emblem"
		part(model, Vector3.new(0.38 * s, 0.2 * s, 0.3), at * CFrame.new(0, -0.22 * s, 0.05), color, NEON, "Emblem")
		for _, x in ipairs({-0.13, 0.13}) do
			local e = ball(model, 0.17 * s, at * CFrame.new(x * s, 0.1 * s, -0.12), dark, Enum.Material.SmoothPlastic); e.Name = "Emblem"
		end
	elseif kind == "crown" then
		b(0.7, 0.2, 0, -0.18)
		for _, x in ipairs({-0.28, 0, 0.28}) do b(0.14, 0.34, x, 0.06, x == 0 and 0 or (x < 0 and 12 or -12)) end
		for _, x in ipairs({-0.28, 0, 0.28}) do b(0.1, 0.1, x, 0.27, 45, NEON, Color3.new(1, 1, 1)) end
	elseif kind == "anchor" then
		b(0.1, 0.8, 0, 0); b(0.46, 0.08, 0, 0.26); b(0.18, 0.18, 0, 0.44, 45)
		b(0.36, 0.08, -0.17, -0.38, 30); b(0.36, 0.08, 0.17, -0.38, -30)
	elseif kind == "flame" then
		b(0.44, 0.44, 0, -0.18, 45); b(0.3, 0.3, 0, 0.08, 45); b(0.18, 0.18, 0.02, 0.3, 45)
		b(0.2, 0.2, 0, -0.16, 45, NEON, color:Lerp(Color3.new(1, 1, 0.6), 0.6))
	else   -- star
		b(0.18, 0.8, 0, 0); b(0.18, 0.8, 0, 0, 60); b(0.18, 0.8, 0, 0, -60); b(0.22, 0.22, 0, 0, 45, NEON, Color3.new(1, 1, 1))
	end
end

function CrateModels.lookOf(crateId, def)
	local look = (def and def.look) or CrateModels.LOOKS[crateId] or {}
	local accent = def and def.accent or C(200, 200, 210)
	return {
		wood = look.wood or OAK:Lerp(accent, 0.25),
		metal = look.metal or accent,
		emblem = look.emblem or "star",
		glow = look.glow or accent,
	}
end

function CrateModels.build(crateId, def)
	local L = CrateModels.lookOf(crateId, def)
	local model = Instance.new("Model")
	model.Name = "Crate_" .. tostring(crateId)
	local WOOD, METAL = Enum.Material.WoodPlanks, Enum.Material.Metal
	local wood2 = L.wood:Lerp(Color3.new(0, 0, 0), 0.25)
	local metalDark = L.metal:Lerp(Color3.new(0, 0, 0), 0.35)

	-- the body
	local base = part(model, Vector3.new(W, H, D), CFrame.new(0, H / 2, 0), L.wood, WOOD, "Base")
	model.PrimaryPart = base
	part(model, Vector3.new(W + 0.12, 0.22, D + 0.12), CFrame.new(0, 0.11, 0), metalDark, METAL, "Plinth")
	-- the light inside (seen when the lid opens)
	local inner = part(model, Vector3.new(W - 0.3, 0.1, D - 0.3), CFrame.new(0, H - 0.04, 0), L.glow, Enum.Material.Neon, "Inner")
	inner.Transparency = 1
	-- straps and corner caps
	for _, x in ipairs({-1.3, 1.3}) do
		part(model, Vector3.new(0.34, H + 0.04, D + 0.1), CFrame.new(x, H / 2, 0), L.metal, METAL, "Strap")
		for _, z in ipairs({-1, 1}) do
			ball(model, 0.16, CFrame.new(x, H * 0.3, z * (D / 2 + 0.05)), metalDark, METAL)
			ball(model, 0.16, CFrame.new(x, H * 0.75, z * (D / 2 + 0.05)), metalDark, METAL)
		end
	end
	for _, x in ipairs({-1, 1}) do
		for _, z in ipairs({-1, 1}) do
			part(model, Vector3.new(0.42, 0.42, 0.42), CFrame.new(x * (W / 2 - 0.15), H - 0.15, z * (D / 2 - 0.15)), metalDark, METAL, "Corner")
			part(model, Vector3.new(0.42, 0.42, 0.42), CFrame.new(x * (W / 2 - 0.15), 0.3, z * (D / 2 - 0.15)), metalDark, METAL, "Corner")
		end
	end
	-- the emblem, on a dark plate
	part(model, Vector3.new(1.2, 1.2, 0.08), CFrame.new(0, H * 0.41, -D / 2 - 0.04) * CFrame.Angles(0, 0, math.rad(45)), C(16, 16, 22), Enum.Material.Slate, "Plate")
	part(model, Vector3.new(1.34, 1.34, 0.06), CFrame.new(0, H * 0.41, -D / 2 - 0.02) * CFrame.Angles(0, 0, math.rad(45)), L.metal, METAL, "PlateRim")
	emblem(model, L.emblem, CFrame.new(0, H * 0.41, -D / 2 - 0.12), 1.05, L.glow)

	-- the lid (its parts move together about the back hinge)
	local lidParts = {}
	local function lid(p) table.insert(lidParts, p); return p end
	lid(part(model, Vector3.new(W + 0.08, LID_H, D + 0.08), CFrame.new(0, H + LID_H / 2, 0), wood2, WOOD, "Lid"))
	lid(part(model, Vector3.new(W - 0.5, CAP_H, D - 0.6), CFrame.new(0, H + LID_H + CAP_H / 2, 0), L.wood, WOOD, "LidCap"))
	for _, x in ipairs({-1.3, 1.3}) do
		lid(part(model, Vector3.new(0.34, LID_H + 0.04, D + 0.16), CFrame.new(x, H + LID_H / 2, 0), L.metal, METAL, "LidStrap"))
		lid(part(model, Vector3.new(0.34, CAP_H + 0.04, D - 0.5), CFrame.new(x, H + LID_H + CAP_H / 2, 0), L.metal, METAL, "LidStrap"))
	end
	lid(part(model, Vector3.new(W + 0.16, 0.14, D + 0.16), CFrame.new(0, H + 0.07, 0), metalDark, METAL, "LidRim"))
	-- the lock, hanging off the lid's front
	lid(part(model, Vector3.new(0.7, 0.8, 0.16), CFrame.new(0, H + 0.05, -D / 2 - 0.1), L.metal, METAL, "Lock"))
	lid(part(model, Vector3.new(0.12, 0.26, 0.04), CFrame.new(0, H - 0.02, -D / 2 - 0.19), C(10, 10, 12), Enum.Material.SmoothPlastic, "Keyhole"))
	-- a gem on the lid
	local gem = lid(part(model, Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, H + LID_H + CAP_H + 0.08, -0.2) * CFrame.Angles(math.rad(45), 0, math.rad(45)), L.glow, Enum.Material.Neon, "Gem"))
	gem.Size = Vector3.new(0.34, 0.34, 0.34)

	-- the rays (hidden until it opens): thin glowing blades fanned out of the box
	local rays = {}
	for i = 1, 9 do
		local a = math.rad(-60 + (i - 1) * 15)
		local r = part(model, Vector3.new(0.18, 6, 0.04), CFrame.new(0, H, 0) * CFrame.Angles(0, 0, a) * CFrame.new(0, 3, 0), L.glow, Enum.Material.Neon, "Ray")
		r.Transparency = 1
		rays[i] = {p = r, a = a}
	end

	local hinge = CFrame.new(0, H, D / 2 + 0.04)
	local rel = {}
	for _, p in ipairs(lidParts) do rel[p] = hinge:ToObjectSpace(p.CFrame) end
	local rig = {height = H + LID_H + CAP_H, look = L, lidParts = lidParts}
	-- (the model can be moved: the hinge goes with the base)
	local baseRel = base.CFrame:ToObjectSpace(hinge)
	function rig.setLid(a)
		local h = base.CFrame * baseRel * CFrame.Angles(a, 0, 0)   -- (the front edge lifts: the hinge is at the back)
		for p, r in pairs(rel) do p.CFrame = h * r end
	end
	function rig.glow(k, spin)
		inner.Transparency = 1 - math.clamp(k, 0, 1) * 0.9
		for i, r in ipairs(rays) do
			local wob = math.sin((spin or 0) * 2 + i) * 0.08
			r.p.Transparency = 1 - math.clamp(k, 0, 1) * (0.55 + wob)
			r.p.Size = Vector3.new(0.18 + 0.3 * k, 6 * math.max(k, 0.01), 0.04)
			r.p.CFrame = base.CFrame * CFrame.new(0, H / 2, 0) * CFrame.Angles(0, (spin or 0) * 0.3, r.a + wob) * CFrame.new(0, 3 * math.max(k, 0.01), 0)
		end
	end
	return model, rig
end

return CrateModels
