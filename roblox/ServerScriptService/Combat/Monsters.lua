--[[ MONSTERS — the Bestiary brought to life (ReplicatedStorage ▸ Catalog ▸ Bestiary). Every monster
     is a bot on the real combat system (Combat ▸ Bots: it blocks, parries, feints, kicks like any
     fighter), dressed and then BUILT into its shape with welded parts: a skeleton's bones, a
     goblin's ears, a wraith's robe, a troll's belly, horns, crowns, capes, wings, glowing eyes
     and an aura, then scaled (Model:ScaleTo) to its size.

       Monsters.spawn(id, opts, over) -> mob   opts (one table a whole room / wave can share): everything Bots.spawn takes (at, team, goal,
                                           engage, arena, startDelay…), plus
                                             hpMult      × its health (a bigger party)
                                             dealt       × the damage it does
                                             elite       true: a champion (ELITE: a random
                                                         affix, more health, a glow)
                                             onSpawn     fn(mob): another mob came of this one
                                                         (a skeleton standing back up, a summon)
                                             onDeath     fn(mob, killerPlayer): it fell (a skeleton
                                                         that will stand back up says mob.rising)
                                           over: this one's own (at, elite…) on top of opts
       Monsters.pending(opts) -> n         mobs of these opts on their way (a skeleton getting
                                           up, a summon in its circle): a room isn't clear yet
       Monsters.despawn(mob)               gone, no callbacks
       Monsters.alive(mob)
       Monsters.def(id)

     A MOB is {id, def, bot, model, alive, elite}. Its traits (Bestiary) run here:
       reassemble  a skeleton stands back up once (a new mob through onSpawn, a moment later)
       lifesteal   its blade's hits mend it · frostbite / burning: its hits chill / burn
       enrage      under half health: faster, harder, its eyes blaze
       explode     bursts in embers when it falls (stand clear)
       summon      calls up its kind every so often (through onSpawn)
       regen       mends itself out of a fight
     A BOSS (tier 4) shrugs off flinches, carries Boss (the boss bar: Adventure.client), and
     every few seconds marks the ground — a ring under it or under you — and SLAMS it. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Bots = require(script.Parent:WaitForChild("Bots"))
local MagicServer = require(script.Parent:WaitForChild("MagicServer"))
local BossMoves = require(script.Parent:WaitForChild("BossMoves"))
local Powers   -- (loaded when first needed: Powers loads after us)
local function powers() Powers = Powers or require(script.Parent:WaitForChild("Powers")); return Powers end

local Monsters = {}
local BEST = Catalog.BESTIARY or {}
local FOREVER = 1e6

local function now() return workspace:GetServerTimeNow() end
local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
-- a palette colour by its name (Catalog ▸ Palette is a list)
local PALETTE = {}
for _, c in ipairs(Catalog.PALETTE or {}) do PALETTE[c.name] = c.color end
local function palette(name) return name and PALETTE[name] or nil end

function Monsters.def(id) return BEST[id] end

--------------------------------------------------------------------
--  BUILDING A SHAPE
--------------------------------------------------------------------
local SMOOTH = Enum.SurfaceType.Smooth
local function piece(folder, limb, shape, size, color, mat, offset, props)
	if not limb then return nil end
	local p = (shape == "wedge") and Instance.new("WedgePart") or Instance.new("Part")
	if shape == "ball" then p.Shape = Enum.PartType.Ball elseif shape == "cyl" then p.Shape = Enum.PartType.Cylinder end
	p.Name = "Look"
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = SMOOTH, SMOOTH
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.Anchored = false, false, false, true, false
	if props then for k, v in pairs(props) do p[k] = v end end
	p.CFrame = limb.CFrame * offset
	local w = Instance.new("Weld")
	w.Name = "LookWeld"; w.Part0 = limb; w.Part1 = p; w.C0 = offset
	w.Parent = p
	p.Parent = folder
	return p
end
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)   -- (a Cylinder runs along X: this stands it up)
local function darker(c, k) return Color3.new(c.R * k, c.G * k, c.B * k) end

local LIMBS = {"Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

-- the skin under it all: the limbs, the BodyColors, the strips of skin round the armor
local function paintSkin(model, color, material)
	for _, n in ipairs({"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
		local p = model:FindFirstChild(n)
		if p then p.Color = color; if material then p.Material = material end end
	end
	local bc = model:FindFirstChildOfClass("BodyColors")
	if bc then for _, k in ipairs({"HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3"}) do bc[k] = color end end
	local armor = model:FindFirstChild("Armor")
	for _, d in ipairs(armor and armor:GetDescendants() or {}) do
		if d:IsA("BasePart") and d.Name == "Skin" then d.Color = color end
	end
	model:SetAttribute("SkinTone", color)
end

local function hideFace(model)
	local head = model:FindFirstChild("Head")
	for _, d in ipairs(head and head:GetChildren() or {}) do
		if d:IsA("Decal") then d.Transparency = 1; d:SetAttribute("Covered", nil) end
	end
end

local function glowEyes(f, head, color, wide)
	local w = wide or 0.24
	for _, x in ipairs({-w, w}) do
		piece(f, head, "block", Vector3.new(0.2, 0.12, 0.06), color, Enum.Material.Neon, CFrame.new(x, 0.1, -0.6))
	end
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = color, 7, 1.2, false
	l.Name = "EyeGlow"
	l.Parent = head
end

-- a skeleton: the limbs vanish, bones take their place
local function buildSkeleton(f, model, bone, eye)
	local dark = darker(bone, 0.7)
	for _, n in ipairs(LIMBS) do
		local p = model:FindFirstChild(n)
		if p then p.Transparency = 1 end
	end
	local armor = model:FindFirstChild("Armor")
	for _, d in ipairs(armor and armor:GetDescendants() or {}) do
		if d:IsA("BasePart") and d.Name == "Skin" then d.Transparency = 1 end
	end
	local head, torso = model:FindFirstChild("Head"), model:FindFirstChild("Torso")
	hideFace(model)
	if head then
		head.Color = bone
		-- the sockets, the nose, the jaw and its teeth
		for _, x in ipairs({-0.25, 0.25}) do
			piece(f, head, "block", Vector3.new(0.34, 0.3, 0.05), Color3.fromRGB(16, 14, 14), nil, CFrame.new(x, 0.08, -0.59))
		end
		piece(f, head, "wedge", Vector3.new(0.05, 0.18, 0.14), Color3.fromRGB(16, 14, 14), nil, CFrame.new(0, -0.14, -0.6) * CFrame.Angles(0, math.pi / 2, 0))
		piece(f, head, "block", Vector3.new(0.78, 0.22, 0.5), bone, nil, CFrame.new(0, -0.58, -0.22))
		for i = -3, 3 do
			piece(f, head, "block", Vector3.new(0.06, 0.12, 0.04), Color3.fromRGB(40, 36, 32), nil, CFrame.new(i * 0.1, -0.5, -0.48))
		end
		glowEyes(f, head, eye or Color3.fromRGB(120, 255, 170), 0.25)
	end
	if torso then
		piece(f, torso, "cyl", Vector3.new(2.1, 0.3, 0.3), bone, nil, CFrame.new(0, 0, 0.2) * UPRIGHT)                -- the spine
		for i, y in ipairs({0.62, 0.3, -0.02}) do                                                                       -- the ribs
			local w = 1.7 - i * 0.12
			piece(f, torso, "cyl", Vector3.new(w, 0.16, 0.16), bone, nil, CFrame.new(0, y, -0.25))
			piece(f, torso, "cyl", Vector3.new(0.5, 0.14, 0.14), bone, nil, CFrame.new(-w / 2 + 0.05, y, 0) * CFrame.Angles(0, math.pi / 2, 0))
			piece(f, torso, "cyl", Vector3.new(0.5, 0.14, 0.14), bone, nil, CFrame.new(w / 2 - 0.05, y, 0) * CFrame.Angles(0, math.pi / 2, 0))
		end
		piece(f, torso, "block", Vector3.new(0.18, 0.8, 0.12), bone, nil, CFrame.new(0, 0.32, -0.3))                     -- the breastbone
		piece(f, torso, "block", Vector3.new(1.5, 0.36, 0.55), dark, nil, CFrame.new(0, -0.82, 0.05))                    -- the hips
		piece(f, torso, "cyl", Vector3.new(1.9, 0.18, 0.18), bone, nil, CFrame.new(0, 0.9, 0))                           -- the collarbones
	end
	for _, n in ipairs({"Left Arm", "Right Arm"}) do
		local a = model:FindFirstChild(n)
		piece(f, a, "ball", Vector3.new(0.5, 0.5, 0.5), bone, nil, CFrame.new(0, 0.75, 0))
		piece(f, a, "cyl", Vector3.new(1.8, 0.26, 0.26), bone, nil, CFrame.new(0, -0.05, 0) * UPRIGHT)
		piece(f, a, "ball", Vector3.new(0.34, 0.34, 0.34), dark, nil, CFrame.new(0, 0, 0))
		piece(f, a, "ball", Vector3.new(0.42, 0.42, 0.42), bone, nil, CFrame.new(0, -0.88, 0))
	end
	for _, n in ipairs({"Left Leg", "Right Leg"}) do
		local l = model:FindFirstChild(n)
		piece(f, l, "cyl", Vector3.new(1.85, 0.3, 0.3), bone, nil, CFrame.new(0, 0.02, 0) * UPRIGHT)
		piece(f, l, "ball", Vector3.new(0.38, 0.38, 0.38), dark, nil, CFrame.new(0, 0, 0))
		piece(f, l, "block", Vector3.new(0.42, 0.2, 0.7), bone, nil, CFrame.new(0, -0.92, -0.12))
	end
end

-- a wraith: a robe where its legs were, a hood round a face of nothing
local function buildWraith(f, model, cloth, eye)
	for _, n in ipairs({"Left Leg", "Right Leg"}) do local p = model:FindFirstChild(n); if p then p.Transparency = 1 end end
	local head, torso = model:FindFirstChild("Head"), model:FindFirstChild("Torso")
	hideFace(model)
	local robe = darker(cloth, 0.8)
	if head then
		head.Color = Color3.fromRGB(8, 8, 12)
		piece(f, head, "block", Vector3.new(1.5, 1.4, 1.3), robe, Enum.Material.Fabric, CFrame.new(0, 0.18, 0.24))
		piece(f, head, "wedge", Vector3.new(1.5, 1.3, 1.2), robe, Enum.Material.Fabric, CFrame.new(0, 1.5, 0.45) * CFrame.Angles(0, math.pi, 0))
		for _, x in ipairs({-0.72, 0.72}) do piece(f, head, "block", Vector3.new(0.12, 1.3, 1.2), robe, Enum.Material.Fabric, CFrame.new(x, 0.1, -0.15)) end
		glowEyes(f, head, eye, 0.22)
	end
	if torso then
		piece(f, torso, "cyl", Vector3.new(1.3, 2.4, 2.4), robe, Enum.Material.Fabric, CFrame.new(0, -1.45, 0) * UPRIGHT, {Transparency = 0.1})
		piece(f, torso, "cyl", Vector3.new(1.0, 2.7, 2.7), robe, Enum.Material.Fabric, CFrame.new(0, -2.4, 0) * UPRIGHT, {Transparency = 0.3})
		piece(f, torso, "cyl", Vector3.new(0.8, 3.0, 3.0), robe, Enum.Material.Fabric, CFrame.new(0, -3.2, 0) * UPRIGHT, {Transparency = 0.55})
		local hem = piece(f, torso, "block", Vector3.new(2.6, 0.2, 2.6), robe, nil, CFrame.new(0, -3.6, 0), {Transparency = 1})
		if hem then
			local mist = Instance.new("ParticleEmitter")
			mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
			mist.Color = ColorSequence.new(eye:Lerp(Color3.new(0, 0, 0), 0.5))
			mist.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1)})
			mist.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 3)})
			mist.Lifetime = NumberRange.new(1, 1.6); mist.Rate = 10; mist.Speed = NumberRange.new(0.5, 1.2)
			mist.SpreadAngle = Vector2.new(180, 20); mist.LightEmission = 0.4
			mist.Parent = hem
		end
		for i = 0, 7 do   -- the tatters
			local a = i / 8 * math.pi * 2
			piece(f, torso, "block", Vector3.new(0.5, 0.9 + (i % 3) * 0.35, 0.08), robe, Enum.Material.Fabric,
				CFrame.new(math.cos(a) * 1.05, -3.4 - (i % 3) * 0.15, math.sin(a) * 1.05) * CFrame.Angles(0, -a + math.pi / 2, 0), {Transparency = 0.25})
		end
		piece(f, torso, "block", Vector3.new(2.15, 2.05, 1.15), robe, Enum.Material.Fabric, CFrame.new(0, 0, 0))
	end
	for _, n in ipairs({"Left Arm", "Right Arm"}) do
		local a = model:FindFirstChild(n)
		if a then a.Color = Color3.fromRGB(20, 22, 28) end
		piece(f, a, "block", Vector3.new(1.2, 1.5, 1.2), robe, Enum.Material.Fabric, CFrame.new(0, 0.3, 0))
	end
end

-- a golem: stone, its seams glowing
local function buildGolem(f, model, stone, eye)
	paintSkin(model, stone, Enum.Material.Slate)
	hideFace(model)
	local head, torso = model:FindFirstChild("Head"), model:FindFirstChild("Torso")
	if head then glowEyes(f, head, eye, 0.24); piece(f, head, "block", Vector3.new(0.6, 0.08, 0.05), eye, Enum.Material.Neon, CFrame.new(0, -0.3, -0.6)) end
	if torso then
		piece(f, torso, "ball", Vector3.new(1.3, 1.1, 1.1), darker(stone, 0.85), Enum.Material.Slate, CFrame.new(-1.15, 1.05, 0))
		piece(f, torso, "ball", Vector3.new(1.3, 1.1, 1.1), darker(stone, 0.85), Enum.Material.Slate, CFrame.new(1.15, 1.05, 0))
		piece(f, torso, "block", Vector3.new(0.5, 0.5, 0.06), eye, Enum.Material.Neon, CFrame.new(0, 0.3, -0.53) * CFrame.Angles(0, 0, math.rad(45)))
	end
end

-- a beast's head: face kept (the face builder), ears / tusks / nose added by extras
local FACE_OF = {
	goblin  = {eyes = "Fierce", eyeColor = "Amber", brows = "Angry", mouth = "Toothy", hair = "Bald"},
	orc     = {eyes = "Narrow", eyeColor = "Crimson", brows = "Thick", mouth = "Grimace", hair = "Topknot", hairColor = "Black"},
	elf     = {eyes = "Lashes", eyeColor = "Green", brows = "Thin", mouth = "Flat", hair = "LongFlowing", hairColor = "Blond"},
	vampire = {eyes = "Narrow", eyeColor = "Crimson", brows = "Angry", mouth = "Fangs", hair = "SweptBack", hairColor = "Black"},
	ghoul   = {eyes = "Wide", eyeColor = "Green", brows = "None", mouth = "Grimace", hair = "Bald", mark = "Stitches"},
	troll   = {eyes = "Fierce", eyeColor = "Amber", brows = "Unibrow", mouth = "Toothy", hair = "Bald"},
	human   = {eyes = "Narrow", eyeColor = "Grey", brows = "Thick", mouth = "Flat", hair = "Cropped", hairColor = "Brown"},
	cinder  = {},
}
local DECAL_FACE = {skeleton = false, wraith = false, golem = false, cinder = false}

--------------------------------------------------------------------
--  EXTRAS
--------------------------------------------------------------------
local GOLD = Color3.fromRGB(232, 186, 64)
local EXTRA = {}
EXTRA.ears = function(f, m, look)
	local head = m:FindFirstChild("Head")
	local elf = look.body == "elf"
	local skin = look.skin or Color3.fromRGB(200, 170, 140)
	for _, s in ipairs({-1, 1}) do
		local len = elf and 0.75 or 1.0
		piece(f, head, "block", Vector3.new(0.1, 0.3, len), skin, nil,
			CFrame.new(s * 0.66, 0.12, 0.12) * CFrame.Angles(math.rad(elf and 32 or 14), math.rad(s * (elf and 70 or 62)), 0))
	end
	if look.body == "goblin" then piece(f, head, "ball", Vector3.new(0.36, 0.3, 0.42), darker(skin, 0.85), nil, CFrame.new(0, -0.08, -0.62)) end
end
EXTRA.tusks = function(f, m)
	local head = m:FindFirstChild("Head")
	for _, s in ipairs({-1, 1}) do
		piece(f, head, "block", Vector3.new(0.12, 0.32, 0.12), Color3.fromRGB(240, 232, 210), nil, CFrame.new(s * 0.28, -0.32, -0.58) * CFrame.Angles(math.rad(-12), 0, math.rad(s * -10)))
	end
end
EXTRA.fangs = function() end   -- (the face builder's Fangs mouth)
EXTRA.horns = function(f, m, look)
	local head = m:FindFirstChild("Head")
	local c = look.hornColor or Color3.fromRGB(60, 50, 44)
	for _, s in ipairs({-1, 1}) do
		local cf = CFrame.new(s * 0.45, 0.55, 0) * CFrame.Angles(0, 0, math.rad(s * -35))
		for i, seg in ipairs({{0.5, 0.3}, {0.45, 0.22}, {0.4, 0.13}}) do
			local p = piece(f, head, "cyl", Vector3.new(seg[1], seg[2], seg[2]), c, nil, cf * CFrame.new(0, seg[1] / 2, 0) * UPRIGHT)
			cf = cf * CFrame.new(0, seg[1] * 0.9, 0) * CFrame.Angles(math.rad(-25), 0, math.rad(s * 22))
			if i == 3 and p then p.Color = darker(c, 1.5) end
		end
	end
end
EXTRA.antlers = function(f, m)
	local head = m:FindFirstChild("Head")
	local c = Color3.fromRGB(120, 92, 60)
	for _, s in ipairs({-1, 1}) do
		local base = CFrame.new(s * 0.35, 0.6, 0.05) * CFrame.Angles(math.rad(-10), 0, math.rad(s * -28))
		piece(f, head, "cyl", Vector3.new(1.1, 0.1, 0.1), c, nil, base * CFrame.new(0, 0.55, 0) * UPRIGHT)
		for i = 1, 3 do
			piece(f, head, "cyl", Vector3.new(0.45, 0.07, 0.07), c, nil, base * CFrame.new(0, 0.25 + i * 0.25, 0) * CFrame.Angles(0, 0, math.rad(s * -50)) * CFrame.new(0, 0.2, 0) * UPRIGHT)
		end
	end
end
EXTRA.crown = function(f, m, look)
	local head = m:FindFirstChild("Head")
	local gem = look.eyes or Color3.fromRGB(220, 40, 60)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local cf = CFrame.new(math.cos(a) * 0.62, 0.72, math.sin(a) * 0.62) * CFrame.Angles(0, -a + math.pi / 2, 0)
		piece(f, head, "block", Vector3.new(0.5, 0.22, 0.07), GOLD, Enum.Material.Metal, cf)
		piece(f, head, "wedge", Vector3.new(0.07, 0.28, 0.2), GOLD, Enum.Material.Metal, cf * CFrame.new(0, 0.24, 0) * CFrame.Angles(0, math.pi / 2, 0))
		if i % 2 == 0 then piece(f, head, "ball", Vector3.new(0.14, 0.14, 0.14), gem, Enum.Material.Neon, cf * CFrame.new(0, 0, -0.05)) end
	end
end
EXTRA.halo = function(f, m)
	local head = m:FindFirstChild("Head")
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		piece(f, head, "block", Vector3.new(0.3, 0.06, 0.06), Color3.fromRGB(255, 230, 140), Enum.Material.Neon, CFrame.new(math.cos(a) * 0.6, 1.15, math.sin(a) * 0.6) * CFrame.Angles(0, -a + math.pi / 2, 0))
	end
end
EXTRA.cape = function(f, m, look)
	local torso = m:FindFirstChild("Torso")
	local c = (look.colors and palette(look.colors.Primary)) or Color3.fromRGB(90, 20, 30)
	piece(f, torso, "block", Vector3.new(2.0, 3.4, 0.08), c, Enum.Material.Fabric, CFrame.new(0, -0.65, 0.62) * CFrame.Angles(math.rad(8), 0, 0))
	if look.body == "vampire" then
		piece(f, torso, "block", Vector3.new(1.9, 0.75, 0.08), darker(c, 0.6), Enum.Material.Fabric, CFrame.new(0, 1.25, 0.5) * CFrame.Angles(math.rad(-18), 0, 0))
	end
end
EXTRA.hood = function(f, m, look)
	if look.body == "wraith" then return end
	local head = m:FindFirstChild("Head")
	local c = (look.colors and palette(look.colors.Primary)) or Color3.fromRGB(46, 40, 36)
	piece(f, head, "block", Vector3.new(1.45, 1.3, 1.25), c, Enum.Material.Fabric, CFrame.new(0, 0.18, 0.2))
	piece(f, head, "wedge", Vector3.new(1.45, 0.45, 0.55), c, Enum.Material.Fabric, CFrame.new(0, 0.9, 0.2) * CFrame.Angles(0, math.pi, 0))
end
EXTRA.belly = function(f, m, look)
	piece(f, m:FindFirstChild("Torso"), "ball", Vector3.new(1.7, 1.6, 1.4), look.skin or Color3.fromRGB(160, 140, 110), nil, CFrame.new(0, -0.35, -0.3))
end
EXTRA.beard = function() end   -- (the appearance's beard)
EXTRA.ribs = function() end    -- (a skeleton has them already)
EXTRA.spikes = function(f, m)
	local c = Color3.fromRGB(70, 66, 62)
	for _, n in ipairs({"Left Arm", "Right Arm"}) do
		local a = m:FindFirstChild(n)
		for i = -1, 1 do
			piece(f, a, "wedge", Vector3.new(0.18, 0.55, 0.3), c, Enum.Material.Metal, CFrame.new(0, 1.15, i * 0.32) * CFrame.Angles(0, math.pi / 2, 0))
		end
	end
end
EXTRA.crystals = function(f, m)
	local c = Color3.fromRGB(150, 220, 255)
	local torso = m:FindFirstChild("Torso")
	local spots = {CFrame.new(-0.9, 1.0, 0.3), CFrame.new(0.95, 1.05, 0.25), CFrame.new(-0.3, 0.6, 0.6), CFrame.new(0.4, 0.2, 0.6), CFrame.new(0, 0.9, 0.55)}
	for i, cf in ipairs(spots) do
		piece(f, torso, "block", Vector3.new(0.3, 0.6 + (i % 3) * 0.3, 0.3), c, Enum.Material.Glass,
			cf * CFrame.Angles(math.rad(-30 + i * 12), math.rad(i * 40), math.rad(i * 17 - 30)), {Transparency = 0.15, Reflectance = 0.2})
	end
end
EXTRA.cracks = function(f, m, look)
	local c = look.eyes or Color3.fromRGB(255, 130, 40)
	local torso = m:FindFirstChild("Torso")
	for i, cf in ipairs({CFrame.new(-0.4, 0.3, -0.51) * CFrame.Angles(0, 0, 0.6), CFrame.new(0.35, -0.2, -0.51) * CFrame.Angles(0, 0, -0.9),
		CFrame.new(0.1, 0.65, -0.51) * CFrame.Angles(0, 0, 1.4), CFrame.new(-0.2, -0.6, -0.51) * CFrame.Angles(0, 0, -0.3)}) do
		piece(f, torso, "block", Vector3.new(0.8 - i * 0.08, 0.07, 0.04), c, Enum.Material.Neon, cf)
	end
	for _, n in ipairs({"Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
		piece(f, m:FindFirstChild(n), "block", Vector3.new(0.06, 1.1, 0.04), c, Enum.Material.Neon, CFrame.new(0.1, -0.1, -0.51) * CFrame.Angles(0, 0, 0.25))
	end
end
EXTRA.wings = function(f, m, look)
	local torso = m:FindFirstChild("Torso")
	local c = look.wingColor or (look.body == "golem" and Color3.fromRGB(96, 98, 104)) or Color3.fromRGB(40, 20, 30)
	for _, s in ipairs({-1, 1}) do
		local root = CFrame.new(s * 0.5, 0.6, 0.6) * CFrame.Angles(0, math.rad(s * -25), math.rad(s * 20))
		piece(f, torso, "cyl", Vector3.new(2.6, 0.16, 0.16), darker(c, 0.7), nil, root * CFrame.new(s * 1.2, 0.3, 0) * CFrame.Angles(0, 0, math.rad(s * 15)))
		for i = 0, 2 do
			piece(f, torso, "block", Vector3.new(0.85, 1.6 - i * 0.35, 0.05), c, Enum.Material.Fabric, root * CFrame.new(s * (0.45 + i * 0.75), -0.4 + i * 0.12, 0), {Transparency = 0.05})
		end
	end
end
EXTRA.collar = function(f, m, look)
	local torso = m:FindFirstChild("Torso")
	local c = (look.colors and palette(look.colors.Secondary)) or Color3.fromRGB(150, 20, 40)
	for _, s in ipairs({-1, 1}) do
		piece(f, torso, "block", Vector3.new(0.9, 1.1, 0.1), Color3.fromRGB(20, 16, 22), Enum.Material.Fabric, CFrame.new(s * 0.55, 1.35, 0.35) * CFrame.Angles(math.rad(-20), math.rad(s * -25), 0))
		piece(f, torso, "block", Vector3.new(0.85, 1.0, 0.04), c, Enum.Material.Fabric, CFrame.new(s * 0.55, 1.33, 0.29) * CFrame.Angles(math.rad(-20), math.rad(s * -25), 0))
	end
	piece(f, torso, "ball", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(200, 20, 50), Enum.Material.Neon, CFrame.new(0, 0.85, -0.55))
end
EXTRA.rags = function(f, m)
	local torso = m:FindFirstChild("Torso")
	local c = Color3.fromRGB(96, 84, 66)
	for i = 0, 5 do
		local x = -0.85 + i * 0.34
		piece(f, torso, "block", Vector3.new(0.32, 0.5 + (i % 3) * 0.25, 0.05), c, Enum.Material.Fabric, CFrame.new(x, -1.15 - (i % 3) * 0.12, -0.53) * CFrame.Angles(0, 0, math.rad((i % 2 == 0) and 6 or -6)))
	end
	piece(f, torso, "block", Vector3.new(0.35, 2.4, 0.06), darker(c, 0.8), Enum.Material.Fabric, CFrame.new(0.2, 0.1, -0.53) * CFrame.Angles(0, 0, math.rad(38)))
end
EXTRA.claws = function(f, m)
	for _, n in ipairs({"Left Arm", "Right Arm"}) do
		local a = m:FindFirstChild(n)
		for i = -1, 1 do
			piece(f, a, "wedge", Vector3.new(0.12, 0.7, 0.18), Color3.fromRGB(230, 222, 200), nil, CFrame.new(i * 0.28, -1.25, -0.25) * CFrame.Angles(math.rad(200), 0, 0))
		end
	end
end
EXTRA.loincloth = function(f, m, look)
	local torso = m:FindFirstChild("Torso")
	local cloth = (look.colors and palette(look.colors.Primary)) or Color3.fromRGB(110, 76, 46)
	piece(f, torso, "block", Vector3.new(2.15, 0.4, 1.15), Color3.fromRGB(70, 48, 30), Enum.Material.Leather or Enum.Material.Fabric, CFrame.new(0, -0.85, 0))
	piece(f, torso, "block", Vector3.new(1.1, 1.3, 0.08), cloth, Enum.Material.Fabric, CFrame.new(0, -1.55, -0.58))
	piece(f, torso, "block", Vector3.new(1.3, 1.2, 0.08), darker(cloth, 0.8), Enum.Material.Fabric, CFrame.new(0, -1.5, 0.58))
	piece(f, torso, "cyl", Vector3.new(0.15, 0.5, 0.5), Color3.fromRGB(200, 170, 90), Enum.Material.Metal, CFrame.new(0, -0.85, -0.6) * CFrame.Angles(0, math.pi / 2, 0))
end
EXTRA.fur = function(f, m, look)
	local c = look.skin and darker(look.skin, 0.88) or Color3.fromRGB(220, 220, 220)
	local torso = m:FindFirstChild("Torso")
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		piece(f, torso, "wedge", Vector3.new(0.5, 0.9, 0.6), c, Enum.Material.Fabric, CFrame.new(math.cos(a) * 0.95, 1.05, math.sin(a) * 0.5) * CFrame.Angles(0, -a, 0))
	end
	for _, n in ipairs({"Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
		local l = m:FindFirstChild(n)
		if l then l.Material = Enum.Material.Fabric end
		for i = 0, 2 do piece(f, l, "wedge", Vector3.new(1.05, 0.4, 0.25), c, Enum.Material.Fabric, CFrame.new(0, 0.6 - i * 0.6, -0.55) * CFrame.Angles(0, math.pi, 0)) end
	end
	if torso then torso.Material = Enum.Material.Fabric end
end
EXTRA.warpaint = function(f, m)
	local head = m:FindFirstChild("Head")
	for _, x in ipairs({-0.3, 0.3}) do piece(f, head, "block", Vector3.new(0.1, 0.55, 0.04), Color3.fromRGB(190, 30, 30), nil, CFrame.new(x, 0, -0.6)) end
	local torso = m:FindFirstChild("Torso")
	for i = 0, 2 do piece(f, torso, "block", Vector3.new(1.6, 0.14, 0.04), Color3.fromRGB(190, 30, 30), nil, CFrame.new(0, 0.6 - i * 0.4, -0.52) * CFrame.Angles(0, 0, math.rad(14))) end
end
EXTRA.drum = function(f, m)
	local torso = m:FindFirstChild("Torso")
	piece(f, torso, "cyl", Vector3.new(1.3, 2.2, 2.2), Color3.fromRGB(120, 80, 50), Enum.Material.Wood, CFrame.new(0, -0.3, -1.6) * CFrame.Angles(0, math.pi / 2, 0))
	piece(f, torso, "cyl", Vector3.new(1.34, 2.0, 2.0), Color3.fromRGB(226, 210, 176), Enum.Material.Fabric, CFrame.new(0, -0.3, -1.6) * CFrame.Angles(0, math.pi / 2, 0))
	piece(f, torso, "block", Vector3.new(0.2, 3.2, 0.1), Color3.fromRGB(80, 56, 36), Enum.Material.Leather or Enum.Material.Fabric, CFrame.new(0, 0.4, -0.55) * CFrame.Angles(0, 0, math.rad(35)))
end
EXTRA.sack = function(f, m)
	local torso = m:FindFirstChild("Torso")
	local b = piece(f, torso, "ball", Vector3.new(1.6, 1.8, 1.4), Color3.fromRGB(150, 120, 80), Enum.Material.Fabric, CFrame.new(0.3, 0.2, 1.0))
	piece(f, torso, "cyl", Vector3.new(0.3, 0.7, 0.7), Color3.fromRGB(120, 92, 60), Enum.Material.Fabric, CFrame.new(0.3, 1.15, 1.0) * UPRIGHT)
end
EXTRA.goggles = function(f, m)
	local head = m:FindFirstChild("Head")
	for _, x in ipairs({-0.25, 0.25}) do
		piece(f, head, "cyl", Vector3.new(0.2, 0.42, 0.42), Color3.fromRGB(120, 90, 50), Enum.Material.Metal, CFrame.new(x, 0.12, -0.62) * CFrame.Angles(0, math.pi / 2, 0))
		piece(f, head, "cyl", Vector3.new(0.22, 0.32, 0.32), Color3.fromRGB(255, 170, 60), Enum.Material.Glass, CFrame.new(x, 0.12, -0.63) * CFrame.Angles(0, math.pi / 2, 0), {Transparency = 0.2})
	end
	piece(f, head, "block", Vector3.new(1.32, 0.16, 1.3), Color3.fromRGB(80, 56, 36), Enum.Material.Fabric, CFrame.new(0, 0.12, 0))
end
EXTRA.mask = function(f, m)
	local head = m:FindFirstChild("Head")
	local c = Color3.fromRGB(150, 110, 70)
	piece(f, head, "block", Vector3.new(1.05, 1.15, 0.12), c, Enum.Material.Wood, CFrame.new(0, 0.02, -0.64))
	for _, x in ipairs({-0.25, 0.25}) do piece(f, head, "block", Vector3.new(0.22, 0.14, 0.04), Color3.fromRGB(180, 120, 255), Enum.Material.Neon, CFrame.new(x, 0.12, -0.71)) end
	piece(f, head, "block", Vector3.new(0.6, 0.1, 0.04), Color3.fromRGB(200, 40, 40), nil, CFrame.new(0, -0.25, -0.71))
	hideFace(m)
end

--------------------------------------------------------------------
--  AURAS
--------------------------------------------------------------------
local AURA = {
	ghost   = {color = Color3.fromRGB(150, 230, 255), rate = 7, speed = 0.6, up = 1.5, size = 0.7, light = 1},
	frost   = {color = Color3.fromRGB(200, 240, 255), rate = 9, speed = 1.2, up = -1.5, size = 0.35, light = 0.6},
	ember   = {color = Color3.fromRGB(255, 140, 40), rate = 12, speed = 2, up = 4, size = 0.3, light = 1},
	crimson = {color = Color3.fromRGB(170, 20, 60), rate = 7, speed = 0.5, up = 1, size = 0.9, light = 0.4},
	shadow  = {color = Color3.fromRGB(60, 30, 90), rate = 7, speed = 0.4, up = 1, size = 1.0, light = 0},
	toxic   = {color = Color3.fromRGB(120, 255, 90), rate = 7, speed = 0.8, up = 2, size = 0.45, light = 1},
	holy    = {color = Color3.fromRGB(255, 220, 120), rate = 8, speed = 0.8, up = 2, size = 0.35, light = 1},
}
local function addAura(model, kind)
	local a = AURA[kind]
	local torso = model:FindFirstChild("Torso")
	if not (a and torso) then return end
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "MonsterAura"
	pe.Color = ColorSequence.new(a.color)
	pe.LightEmission = a.light
	pe.Rate = a.rate
	pe.Lifetime = NumberRange.new(1, 1.8)
	pe.Speed = NumberRange.new(a.speed * 0.5, a.speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, a.up, 0)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, a.size), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1)})
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	pe.Parent = torso
	if a.light > 0 then
		local l = Instance.new("PointLight")
		l.Name = "AuraLight"; l.Color = a.color; l.Range = 10; l.Brightness = 0.8; l.Shadows = false
		l.Parent = torso
	end
end

-- the look, built onto a dressed bot
local function build(model, def)
	local look = def.look or {}
	local f = Instance.new("Folder")
	f.Name = "MonsterLook"
	f.Parent = model
	-- (a set worn as clothes, in the monster's own cloth: its unpainted parts too)
	local cloth = look.cloth and palette(look.cloth)
	if cloth then
		local armor = model:FindFirstChild("Armor")
		for _, d in ipairs(armor and armor:GetDescendants() or {}) do
			if d:IsA("BasePart") and d.Name ~= "Middle" and d.Name ~= "Skin" and not d:GetAttribute("ColorSlot") and d.Transparency < 1 then d.Color = cloth end
		end
	end
	local body = look.body or "human"
	local skin = look.skin
	local eye = look.eyes or Color3.fromRGB(255, 80, 60)
	if body == "skeleton" then
		buildSkeleton(f, model, skin or Color3.fromRGB(222, 214, 190), eye)
	elseif body == "wraith" then
		buildWraith(f, model, skin or Color3.fromRGB(40, 50, 60), eye)
	elseif body == "golem" then
		buildGolem(f, model, skin or Color3.fromRGB(110, 112, 118), eye)
	else
		if skin then paintSkin(model, skin, body == "cinder" and Enum.Material.Basalt or nil) end
		if body == "cinder" then hideFace(model); local h = model:FindFirstChild("Head"); if h then glowEyes(f, h, eye, 0.24) end end
	end
	for _, x in ipairs(look.extras or {}) do
		local fn = EXTRA[x]
		if fn then
			local ok, err = pcall(fn, f, model, look)
			if not ok then warn("[Monsters] extra", x, err) end
		end
	end
	if look.aura then addAura(model, look.aura) end
	model:SetAttribute("Monster", def.id)
	model:SetAttribute("Faction", def.faction)
end

-- what it wears: a crate set, its weight's plain pieces, or nothing
local function loadoutOf(def)
	local look = def.look or {}
	local colors = {}
	for k, v in pairs(look.colors or {}) do colors[k] = v end
	colors.Primary = colors.Primary or "Ash"; colors.Secondary = colors.Secondary or "Slate"
	colors.Accent = colors.Accent or "Ochre"; colors.Metal = colors.Metal or "Steel"
	if look.set then
		local lo = {colors = colors}
		for _, pc in ipairs(Catalog.setPieces(look.set)) do lo[pc.slot] = pc.id end
		if look.noHelm then lo.helmet = nil; lo.noHelm = true end
		if next(lo) and (lo.top or lo.helmet or lo.bottom) then return lo, (Catalog.PIECE[lo.top or ""] and Catalog.PIECE[lo.top].weight) end
	end
	if look.armor and look.armor ~= "none" then
		local w = ({light = "Light", medium = "Medium", heavy = "Heavy"})[look.armor] or "Medium"
		local lo = Bots.loadoutFor(w, colors)
		if look.noHelm then lo.helmet = nil; lo.noHelm = true end
		return lo, w
	end
	return {colors = colors}, nil
end

local function appearanceOf(def)
	local look = def.look or {}
	local body = look.body or "human"
	local face = FACE_OF[body] or FACE_OF.human
	local app = {}
	for k, v in pairs(Catalog.BODY.defaults) do app[k] = v end
	for k, v in pairs(face) do app[k] = v end
	app.beard = "None"
	if DECAL_FACE[body] == false then app.hair = "Bald" end
	for _, x in ipairs(look.extras or {}) do if x == "beard" then app.beard = "Full"; app.hairColor = "White" end end
	if body == "human" then
		local hairs = {"Cropped", "ShavedSides", "SweptBack", "LongTied", "Mohawk", "Bald"}
		app.hair = hairs[math.random(#hairs)]
		app.beard = ({"None", "Stubble", "Full", "Goatee"})[math.random(4)]
	end
	return app
end

--------------------------------------------------------------------
--  ELITES — a champion of its kind (Monsters.spawn opts.elite)
--------------------------------------------------------------------
Monsters.ELITE = {
	{id = "Blazing",   color = Color3.fromRGB(255, 120, 40),  traits = {"burning"}, mods = {dealt = 1.15}},
	{id = "Frozen",    color = Color3.fromRGB(140, 220, 255), traits = {"frostbite"}, mods = {taken = 0.9}},
	{id = "Swift",     color = Color3.fromRGB(120, 255, 160), mods = {speed = 1.3, dodgeCooldown = 0.6}},
	{id = "Vampiric",  color = Color3.fromRGB(200, 40, 90),   traits = {"lifesteal"}},
	{id = "Stoneskin", color = Color3.fromRGB(190, 180, 160), mods = {taken = 0.7, speed = 0.9}},
	{id = "Savage",    color = Color3.fromRGB(255, 60, 60),   mods = {dealt = 1.35}},
	{id = "Undying",   color = Color3.fromRGB(255, 230, 120), traits = {"regen"}, mods = {taken = 0.85}},
}

--------------------------------------------------------------------
--  TRAITS ON A HIT (Powers.meleeHooks: a blade's clean hit)
--------------------------------------------------------------------
local mobOf = setmetatable({}, {__mode = "k"})   -- [model] = mob
local pendingOf = setmetatable({}, {__mode = "k"})   -- [opts] = mobs on their way
local function pend(opts, d) pendingOf[opts] = math.max(0, (pendingOf[opts] or 0) + d) end
function Monsters.pending(opts) return pendingOf[opts] or 0 end
local function has(mob, t) return mob and mob.traits[t] == true end

local function onMelee(attacker, target, dmg)
	local mob = mobOf[attacker]
	if not (mob and mob.alive) then return dmg end
	if has(mob, "burning") then MagicServer.burn(attacker, target, {dps = 6, time = 3}, mob.def.name) end
	if has(mob, "frostbite") then MagicServer.chill(attacker, target, 0.3, 2.5) end
	if has(mob, "lifesteal") then
		local h = humOf(attacker)
		if h and h.Health > 0 then h.Health = math.min(h.MaxHealth, h.Health + dmg * 0.4) end
		-- (a thread of life back to it: the drain's crimson wisp)
		local ar = rootOf(attacker)
		if ar then Monsters.burst(ar.Position, Color3.fromRGB(200, 30, 80), 10, 6) end
	end
	return dmg
end
task.defer(function()
	local P = powers()
	P.meleeHooks = P.meleeHooks or {}
	table.insert(P.meleeHooks, onMelee)
end)

--------------------------------------------------------------------
--  THE GROUND SLAM (bosses): a ring that fills, then the blow
--------------------------------------------------------------------
local fxFolder = workspace:FindFirstChild("MonsterFX")
if not fxFolder then fxFolder = Instance.new("Folder"); fxFolder.Name = "MonsterFX"; fxFolder.Parent = workspace end

local function ring(pos, radius, color, t)
	local p = Instance.new("Part")
	p.Name = "SlamRing"
	p.Shape = Enum.PartType.Cylinder
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.55
	p.Size = Vector3.new(0.12, radius * 2, radius * 2)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Parent = fxFolder
	local inner = p:Clone()
	inner.Transparency = 0.2
	inner.Size = Vector3.new(0.14, 0.5, 0.5)
	inner.Parent = fxFolder
	local tw = game:GetService("TweenService"):Create(inner, TweenInfo.new(t, Enum.EasingStyle.Linear), {Size = Vector3.new(0.14, radius * 2, radius * 2)})
	tw:Play()
	Debris:AddItem(p, t + 0.05); Debris:AddItem(inner, t + 0.05)
end

local function burst(pos, color, n, up)
	local a = Instance.new("Part")
	a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.Transparency = true, false, false, false, 1
	a.Size = Vector3.new(1, 1, 1)
	a.Position = pos
	a.Parent = fxFolder
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color)
	pe.LightEmission = 1
	pe.Speed = NumberRange.new(12, 26)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, up or -20, 0)
	pe.Lifetime = NumberRange.new(0.5, 1)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	pe.Rate = 0
	pe.Parent = a
	pe:Emit(n or 40)
	Debris:AddItem(a, 1.5)
end
Monsters.burst, Monsters.ring = burst, ring

-- the slam lands at `pos`: everyone (but its own side) within `radius` is hurt and thrown
function Monsters.slam(mob, pos, radius, dmg, color)
	local model = mob.model
	burst(pos + Vector3.new(0, 1, 0), color, 60, -30)
	for _, c in ipairs(MagicServer.everyone()) do
		local r = rootOf(c)
		if r and c ~= model and (r.Position - pos).Magnitude <= radius and MagicServer.hurtMult(model, c) > 0 then
			MagicServer.hurt(model, c, dmg, mob.def.name)
			local away = Vector3.new(r.Position.X - pos.X, 0, r.Position.Z - pos.Z)
			if away.Magnitude < 0.1 then away = Vector3.new(0, 0, 1) end
			MagicServer.shove(c, away.Unit * 38 + Vector3.new(0, 26, 0))
		end
	end
end

-- a boss's heavy moves, on their own clock (on top of its fighting)
local function bossLoop(mob)
	local model, def = mob.model, mob.def
	local color = (def.look and def.look.eyes) or Color3.fromRGB(255, 80, 60)
	local caster = def.class == "Mage" or def.class == "Archer"
	task.wait(6)
	while mob.alive and model.Parent do
		local enraged = model:GetAttribute("Enraged") == true
		task.wait(enraged and 6 or 9)
		if not (mob.alive and model.Parent) then break end
		local me = rootOf(model)
		if not me then break end
		-- who's near
		local foes = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local r = p.Character and rootOf(p.Character)
			local h = p.Character and humOf(p.Character)
			if r and h and h.Health > 0 and (r.Position - me.Position).Magnitude < 60 then table.insert(foes, r) end
		end
		if #foes == 0 then continue end
		local scale = model:GetAttribute("MonsterScale") or 1
		local dmg = (mob.slamDamage or 34) * (enraged and 1.2 or 1)
		if caster then
			-- under each of them (a few at most): a circle, then it erupts
			for i = 1, math.min(#foes, enraged and 3 or 2) do
				local at = foes[i].Position - Vector3.new(0, 2.8, 0)
				ring(at, 7, color, 1.3)
				task.delay(1.3, function() if mob.alive then Monsters.slam(mob, at, 7, dmg * 0.8, color) end end)
			end
		else
			-- round itself: it rears up, the ring fills, it comes down
			local at = me.Position - Vector3.new(0, 2.8 * scale, 0)
			local radius = 9 + 3 * scale
			ring(at, radius, color, 1.2)
			model:SetAttribute("BossWindup", now() + 1.2)
			task.wait(1.2)
			if mob.alive then
				local r2 = rootOf(model)
				Monsters.slam(mob, r2 and (r2.Position - Vector3.new(0, 2.8 * scale, 0)) or at, radius, dmg, color)
			end
		end
	end
end

--------------------------------------------------------------------
--  SPAWNING
--------------------------------------------------------------------
local function pick(v) if type(v) == "table" then return v[math.random(#v)] end return v end

local spawnMob   -- (forward)

local function traitLoops(mob)
	local model, hum = mob.model, mob.bot.hum
	local lastHurt = os.clock()
	local lastHealth = hum.Health
	table.insert(mob.conns, hum.HealthChanged:Connect(function(h)
		if h < lastHealth then lastHurt = os.clock() end
		lastHealth = h
		if has(mob, "enrage") and not mob.enraged and h > 0 and h < hum.MaxHealth * 0.5 then
			mob.enraged = true
			model:SetAttribute("Enraged", true)
			powers().addMods(model, {speed = 1.2, dealt = 1.2, dodgeCooldown = 0.7}, FOREVER, "Enrage")
			local r = rootOf(model)
			if r then burst(r.Position, Color3.fromRGB(255, 60, 40), 50, 10) end
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("PointLight") and d.Name == "EyeGlow" then d.Brightness = 3; d.Range = 12 end
			end
			if mob.boss then model:SetAttribute("BossPhase", 2) end
		end
	end))
	if has(mob, "regen") then
		task.spawn(function()
			while mob.alive and model.Parent do
				task.wait(1)
				if os.clock() - lastHurt > 4 and hum.Health > 0 and hum.Health < hum.MaxHealth then
					hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * 0.025)
				end
			end
		end)
	end
	if has(mob, "summon") then
		task.spawn(function()
			task.wait(8)
			while mob.alive and model.Parent do
				task.wait(mob.boss and 14 or 18)
				if not mob.alive then break end
				local me = rootOf(model)
				if not me then break end
				local near = false
				for _, p in ipairs(Players:GetPlayers()) do
					local r = p.Character and rootOf(p.Character)
					if r and (r.Position - me.Position).Magnitude < 50 then near = true end
				end
				local mine = 0
				for m in pairs(mob.minions) do if m.alive then mine += 1 else mob.minions[m] = nil end end
				if near and mine < (mob.boss and 4 or 2) then
					local kinds = mob.def.summons or Monsters.MINIONS[mob.def.faction] or {"Skeleton"}
					for i = 1, mob.boss and 2 or 1 do
						local at = me.CFrame * CFrame.new((i == 1 and -1 or 1) * 6, 0, 3)
						-- (never outside its room: a boss by a wall would call them up behind it)
						local bd = mob.opts and mob.opts.bounds
						if bd then
							local p = at.Position
							at = CFrame.new(math.clamp(p.X, bd.centre.X - bd.hw + 3, bd.centre.X + bd.hw - 3), p.Y, math.clamp(p.Z, bd.centre.Z - bd.hd + 3, bd.centre.Z + bd.hd - 3))
						end
						ring(at.Position - Vector3.new(0, 2.8, 0), 3, (mob.def.look and mob.def.look.eyes) or Color3.fromRGB(150, 255, 150), 1)
						pend(mob.opts, 1)
						task.delay(1, function()
							pend(mob.opts, -1)
							if not mob.alive or mob.dropped or Monsters.halted[mob.opts] then return end
							local child = spawnMob(pick(kinds), mob.opts, {at = at, startDelay = 0.3, child = true})
							if child then mob.minions[child] = true end
						end)
					end
				end
			end
		end)
	end
	-- its big moves (Combat ▸ BossMoves: telegraphed, phased); a boss without any slams the old way
	if mob.moves or (mob.def.moves and #mob.def.moves > 0) then BossMoves.run(mob, mob.opts and mob.opts.arena)
	elseif mob.boss then task.spawn(bossLoop, mob) end
end
-- what a champion of its kind (opts.elite) can do on top, if its kind has no moves of its own
local ELITE_MOVES = {
	{kind = "slam", name = "Champion's Slam", dmg = 24, cd = 12, radius = 6},
	{kind = "charge", name = "Champion's Rush", dmg = 22, cd = 12, range = {8, 40}},
	{kind = "leap", name = "Champion's Leap", dmg = 24, cd = 13, range = {10, 45}},
	{kind = "nova", name = "Champion's Curse", dmg = 18, cd = 14, radius = 5},
}

-- the minions a summoner calls up, by faction
Monsters.MINIONS = {
	Undead = {"Skeleton", "SkeletonArcher"}, Goblin = {"Goblin", "GoblinSpearman"}, Vampire = {"Thrall", "Vampire"},
	Frost = {"FrostSkeleton"}, Infernal = {"Cinderling"}, Elf = {"ElfArcher"}, Orc = {"OrcGrunt"}, Human = {"Crossbowman"},
}

function spawnMob(id, opts, over)
	local def = BEST[id]
	if not def then warn("[Monsters] no such monster", tostring(id)); return nil end
	opts = opts or {}
	local o = {}
	for k, v in pairs(opts) do o[k] = v end
	for k, v in pairs(over or {}) do o[k] = v end
	local mob = {id = id, def = def, alive = true, opts = opts, over = over, conns = {}, minions = {}, traits = {}, boss = (def.tier or 1) >= 4}
	for _, t in ipairs(def.traits or {}) do mob.traits[t] = true end
	local elite = o.elite and Monsters.ELITE[math.random(#Monsters.ELITE)] or nil
	if elite then for _, t in ipairs(elite.traits or {}) do mob.traits[t] = true end end
	mob.elite = elite
	if elite and not (def.moves and #def.moves > 0) then mob.moves = {ELITE_MOVES[math.random(#ELITE_MOVES)]} end

	local lo, setWeight = loadoutOf(def)
	local weight = def.weight or setWeight or "Light"
	local name = def.name
	if elite then name = elite.id .. " " .. name end
	-- (a mode can cap how well it fights: The Depths' first floors)
	local skill = def.skill or "Squire"
	local RANKS = {Squire = 1, Knight = 2, Champion = 3}
	if o.skillCap and (RANKS[skill] or 1) > (RANKS[o.skillCap] or 3) then skill = o.skillCap end
	local bot = Bots.spawn({
		-- (no team colours on its armour: its own; its side is set just below)
		at = o.at, team = nil, skill = skill, class = def.class,
		weapon = pick(def.weapon), name = name, loadout = lo, appearance = appearanceOf(def), weight = weight,
		goal = o.goal, engage = o.engage, sack = o.sack, face = o.face, arena = o.arena, fightBots = o.fightBots,
		fireLimit = o.fireLimit, startDelay = o.startDelay or 0.5, corpseTime = o.corpseTime or 4,
		power = o.power or def.power, spare = (def.class == "Archer") and "Dagger" or false,
		skin = o.skin, target = o.target,
		onDeath = function(b, killer)
			mob.alive = false
			for _, c in ipairs(mob.conns) do c:Disconnect() end
			local r = b.hrp
			local pos = r and r.Position
			-- explode: embers burst where it fell (stand clear)
			if has(mob, "explode") and pos then
				local col = def.burst or Color3.fromRGB(255, 130, 40)
				ring(pos - Vector3.new(0, 2.8, 0), 8, col, 0.6)
				task.delay(0.6, function() Monsters.slam(mob, pos, 8, 16, col) end)
			end
			-- reassemble: the bones pull themselves back together (once)
			if has(mob, "reassemble") and not o.risen and pos and math.random() < 0.55 and not mob.dropped then
				local cf = CFrame.new(pos)
				pend(opts, 1)
				task.delay(2.6, function()
					pend(opts, -1)
					if mob.dropped or Monsters.halted[opts] then return end
					burst(pos, Color3.fromRGB(222, 214, 190), 30, 6)
					spawnMob(id, opts, {at = cf, risen = mob, startDelay = 0.6, elite = false, child = true})
				end)
				mob.rising = true
			end
			if opts.onDeath then task.spawn(opts.onDeath, mob, killer) end
		end,
	})
	mob.bot, mob.model = bot, bot.model
	mobOf[bot.model] = mob
	local model, hum = bot.model, bot.hum
	model:SetAttribute("Team", o.team or "B")
	-- the look
	local ok, err = pcall(build, model, def)
	if not ok then warn("[Monsters] build", id, err) end
	-- its size, and its feet on whatever floor is under where it was asked to stand (a dais,
	-- a step: a body sunk into one gets flung out of the world)
	local scale = def.scale or 1
	if o.risen then model:SetAttribute("Risen", true); mob.risenFrom = o.risen end
	if scale ~= 1 then pcall(function() model:ScaleTo(scale) end) end
	do
		local at = o.at or model:GetPivot()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip = {model}
		for _, n in ipairs({"NPCs", "LootDrops", "MonsterFX", "LootFX", "DroppedWeapons"}) do local f = workspace:FindFirstChild(n); if f then table.insert(skip, f) end end
		for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(skip, p.Character) end end
		params.FilterDescendantsInstances = skip
		local hit = workspace:Raycast(at.Position + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), params)
		local floorY = hit and hit.Position.Y or (at.Position.Y - 3)
		model:PivotTo(CFrame.new(at.Position.X, floorY + 3 * scale + 0.2, at.Position.Z) * at.Rotation)
	end
	model:SetAttribute("MonsterScale", scale)
	-- its health, its pace, its weight in a fight
	local hp = (def.hp or 100) * (o.hpMult or 1) * (elite and 1.6 or 1) * (o.risen and 0.5 or 1)
	hum.MaxHealth, hum.Health = hp, hp
	model:SetAttribute("BaseMaxHealth", hp)
	if def.speed and def.speed ~= 1 then model:SetAttribute("SpeedMult_Monster", def.speed) end
	local mods = {}
	if (o.dealt or 1) ~= 1 then mods.dealt = o.dealt end
	if mob.boss then mods.unflinching = true; model:SetAttribute("Boss", true); model:SetAttribute("BossName", def.name); model:SetAttribute("BossPhase", 1) end
	if elite then
		for k, v in pairs(elite.mods or {}) do mods[k] = (mods[k] or 1) * v end
		model:SetAttribute("Elite", elite.id)
		local hl = Instance.new("Highlight")
		hl.Name = "EliteGlow"
		hl.FillTransparency, hl.OutlineTransparency = 0.85, 0.2
		hl.FillColor, hl.OutlineColor = elite.color, elite.color
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = model
	end
	if next(mods) then powers().addMods(model, mods, FOREVER, "Monster") end
	if def.class == "Mage" then
		model:SetAttribute("SpellPower", o.spellPower or (mob.boss and 0.9 or 0.65))
		model:SetAttribute("CastSlow", mob.boss and 1.15 or 1.4)
	end
	model:SetAttribute("Tier", def.tier or 1)
	traitLoops(mob)
	if o.onSpawn and o.child then task.spawn(o.onSpawn, mob) end
	return mob
end

function Monsters.spawn(id, opts, over) return spawnMob(id, opts, over) end
-- these opts' mobs-to-come are cancelled (a mode ending: nobody stands back up after it)
Monsters.halted = setmetatable({}, {__mode = "k"})
function Monsters.halt(opts) Monsters.halted[opts] = true; pendingOf[opts] = 0 end

function Monsters.alive(mob) return mob ~= nil and mob.alive == true end

-- A STILL COPY for the screens (the Play menu's scenes): dressed, built, scaled, its weapon
-- in hand, anchored, no fighting in it
function Monsters.display(id)
	local def = BEST[id]
	if not def then return nil end
	local R6 = require(script.Parent:WaitForChild("R6"))
	local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
	local model = R6.rig(def.name)
	local lo, setWeight = loadoutOf(def)
	pcall(Dresser.dress, model, {loadout = lo, appearance = appearanceOf(def), weight = def.weight or setWeight or "Light", preview = true})
	local ok, err = pcall(build, model, def)
	if not ok then warn("[Monsters] display", id, err) end
	local w = pick(def.weapon)
	if w then pcall(Dresser.attachWeapon, model, w, nil) end
	if (def.scale or 1) ~= 1 then pcall(function() model:ScaleTo(def.scale) end) end
	-- (its clothes, its bits and its weapon hang off the limbs by welds, which only place them
	-- once physics steps: a moment in the world, held by the root, before it's frozen)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root then root.Anchored = true end
	model:PivotTo(CFrame.new(0, 3000, 0))
	model.Parent = workspace
	RunService.Heartbeat:Wait()
	RunService.Heartbeat:Wait()
	model.Parent = nil
	model:PivotTo(CFrame.new())
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end
		if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	model:SetAttribute("Monster", id)
	model:SetAttribute("MonsterScale", def.scale or 1)
	return model
end
-- a monster's look on someone else's body (Plague Night: a player turned ghoul): its skin,
-- its bits, its aura (none of its clothes or its weapon)
function Monsters.decorate(model, id)
	local def = BEST[id]
	if not (def and model) then return false end
	local old = model:FindFirstChild("MonsterLook")
	if old then old:Destroy() end
	local ok, err = pcall(build, model, def)
	if not ok then warn("[Monsters] decorate", id, err) end
	return ok
end
-- the menu's copies (ReplicatedStorage ▸ MonsterDisplays ▸ <id>)
function Monsters.publishDisplays(ids)
	local f = ReplicatedStorage:FindFirstChild("MonsterDisplays") or Instance.new("Folder")
	f.Name = "MonsterDisplays"
	for _, id in ipairs(ids) do
		if not f:FindFirstChild(id) then
			local m = Monsters.display(id)
			if m then m.Name = id; m.Parent = f end
			task.wait()
		end
	end
	f.Parent = ReplicatedStorage
end

-- gone without a word (the mode ended, the room was left)
function Monsters.despawn(mob)
	if not mob then return end
	mob.dropped = true
	mob.alive = false
	for _, c in ipairs(mob.conns or {}) do c:Disconnect() end
	if mob.bot and mob.bot.model and mob.bot.model.Parent then pcall(function() mob.bot:destroy() end) end
end

return Monsters
