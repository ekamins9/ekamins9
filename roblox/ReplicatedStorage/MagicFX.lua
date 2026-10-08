--[[ MAGIC FX (client) — what magic looks like, for everyone (StarterPlayerScripts
     ▸ MagicFX runs it). It draws from what the server publishes:

       ReplicatedStorage.MagicFXRemote (Combat ▸ MagicServer): bolts flying and bursting
         (an orb, a lance of ice, a wisp, a spark; a skin's dragon, phoenix, skull, star,
         crescent or comet), lightning leaping, a nova's ring of ice, a heal's rising light, a meteor's
         warning ring and its fall, a choking cloud, a haste or a barrier on someone, a hex,
         a blink, a fizzle
       character attributes: Casting (+ CastStart, CastTime) → a magic circle of runes at
         the orb, growing as the cast fills · Warded → a shield of light in front (WardHit
         ripples it, WardBroke shatters it) · Meditating → a turning circle on the ground
         and light rising into you · Shield → a shell of light (ShieldHit flashes it) ·
         HexUntil → a curse's mark over the head · HasteUntil → wind at the heels ·
         Burning → flames · Frosted → frost

     A SPELL SKIN (Catalog ▸ SpellSkins, the caster's choice per spell, passed with every
     event) changes the colours and the shape: MagicFX.lookOf(spellId, skinId). The menus
     show one with MagicFX.preview (a still model of it).

     THE HOLD: a staff stays upright in the hand whatever the arm does (it's lifted off
     the ground, not tipped), a tome stays open towards your face: each screen turns the
     weapon in the hand of everyone holding one (its grip joint's C0), like an emote does.

     Glowing parts (they show in every quality setting), particles from Roblox's own
     textures, sounds from the licensed libraries (Pro Sound Effects, APM). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))
local Emotes = require(ReplicatedStorage:WaitForChild("Emotes"))

local MagicFX = {}

local TEX = {spark = "rbxasset://textures/particles/sparkles_main.dds", fire = "rbxasset://textures/particles/fire_main.dds", smoke = "rbxasset://textures/particles/smoke_main.dds"}
local SND = {cast = 9125899162, boom = 1835337001, whoosh = 9120709477, zap = 9116279560, zap2 = 9116275998, ice = 9119577515, shing = 9119742466, hum = 9112889082, thud = 9046338796, choir = 1846902441}
local WHITE = Color3.new(1, 1, 1)

-- a spell's look: its own colours, and a skin's over them
local skinsMod
function MagicFX.lookOf(spellId, skinId)
	local sp = Spells[spellId] or {}
	local L = {color = sp.color or WHITE, glow = sp.glow or WHITE, shape = sp.shape}
	if skinId and skinsMod == nil then
		local cat = ReplicatedStorage:FindFirstChild("Catalog")
		local m = cat and cat:FindFirstChild("SpellSkins")
		local ok, t = pcall(function() return m and require(m) end)
		skinsMod = (ok and type(t) == "table") and t or false
	end
	if skinId and skinsMod then
		for _, s in ipairs(skinsMod) do
			if s.id == skinId and s.spell == spellId then
				for k, v in pairs(s.look or {}) do L[k] = v end
			end
		end
	end
	return L
end

local folder
local function fxFolder()
	if folder and folder.Parent then return folder end
	folder = Instance.new("Folder"); folder.Name = "MagicFX"; folder.Parent = workspace
	return folder
end
local function part(size, color, shape, material)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = material or Enum.Material.Neon
	p.Color = color
	p.Size = size
	if shape then p.Shape = shape end
	p.Parent = fxFolder()
	return p
end
local function sound(id, at, vol, speed, cut)
	local holder = typeof(at) == "Instance" and at or part(Vector3.one * 0.1, Color3.new(), nil, Enum.Material.SmoothPlastic)
	if typeof(at) == "Vector3" then holder.Transparency = 1; holder.Position = at; Debris:AddItem(holder, (cut or 4) + 1) end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Volume = vol or 0.5
	s.PlaybackSpeed = speed or 1
	s.RollOffMinDistance = 10; s.RollOffMaxDistance = 140
	s.Parent = holder
	s:Play()
	Debris:AddItem(s, cut or 4)
	return s
end
local function emitter(parent, tex, c0, c1, size, rate, life, speed, accel, spread, light)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = tex
	pe.Color = ColorSequence.new(c0, c1 or c0)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new(0.1, 1)
	pe.Rate = rate
	pe.Lifetime = NumberRange.new(life[1], life[2])
	pe.Speed = NumberRange.new(speed[1], speed[2])
	pe.Acceleration = accel or Vector3.zero
	pe.SpreadAngle = Vector2.new(spread or 180, spread or 180)
	pe.LightEmission = light or 1
	pe.Parent = parent
	return pe
end
-- a quick ball of light that swells and fades (a burst, a flash)
local function flash(at, color, from, to, time)
	local b = part(Vector3.one * from, color, Enum.PartType.Ball)
	b.Position = at
	b.Transparency = 0.15
	TweenService:Create(b, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.one * to, Transparency = 1}):Play()
	Debris:AddItem(b, time + 0.05)
	local l = Instance.new("PointLight"); l.Color = color; l.Range = to * 3; l.Brightness = 4; l.Parent = b
	TweenService:Create(l, TweenInfo.new(time), {Brightness = 0}):Play()
	return b
end
local function burstAt(at, c0, c1, n, speed)
	local holder = part(Vector3.one * 0.2, c0)
	holder.Transparency = 1
	holder.Position = at
	local pe = emitter(holder, TEX.spark, c0, c1, 0.5, 0, {0.3, 0.7}, {speed * 0.4, speed}, Vector3.new(0, -12, 0), 180, 1)
	pe:Emit(n)
	Debris:AddItem(holder, 1.2)
end
-- a ring rolling out along the ground (a nova, a meteor's landing, a warning)
local function groundRing(pos, radius, time, color, thick, hold)
	local n = 28
	local segs = {}
	for i = 1, n do segs[i] = part(Vector3.new(1, thick or 0.3, 0.3), color) end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / time, 0, 1)
		local r = hold and radius or (1 + (radius - 1) * (1 - (1 - k) ^ 3))
		for i, s in ipairs(segs) do
			local a = i / n * math.pi * 2 + (hold and os.clock() * 0.6 or 0)
			s.Size = Vector3.new(2 * math.pi * r / n * 1.1, thick or 0.3, 0.35)
			s.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * r, 0.2, math.sin(a) * r)) * CFrame.Angles(0, -a + math.pi / 2, 0)
			s.Transparency = hold and (0.3 + 0.4 * math.sin(os.clock() * 8) ^ 2) or k ^ 2
		end
		if k >= 1 then conn:Disconnect(); for _, s in ipairs(segs) do s:Destroy() end end
	end)
end
-- a jagged line of light between a and b (lightning)
local function jag(a, b, color, width, life)
	local n = math.max(3, math.floor((b - a).Magnitude / 3))
	local pts = {a}
	for i = 1, n - 1 do
		local p = a:Lerp(b, i / n)
		local j = 0.6 + (1 - math.abs(i / n - 0.5) * 2) * 1.0
		table.insert(pts, p + Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1) * j)
	end
	table.insert(pts, b)
	for i = 1, #pts - 1 do
		local p0, p1 = pts[i], pts[i + 1]
		local s = part(Vector3.new(width, width, (p1 - p0).Magnitude), color)
		s.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		TweenService:Create(s, TweenInfo.new(life), {Transparency = 1}):Play()
		Debris:AddItem(s, life + 0.05)
	end
end
-- (where this screen sees the caster's orb: the pose is drawn on each screen, the server's
-- origin is its own guess; a spell starts at the orb and joins the server's line)
local function tipOf(caster)
	local tool = caster and caster:FindFirstChildOfClass("Tool")
	local tip = tool and tool:FindFirstChild("TrailTip", true)
	return tip and tip:IsA("Attachment") and tip.WorldPosition or nil
end

--------------------------------------------------------------------
--  BOLT SHAPES: parts round a core that flies (offset CFrames in the core's frame,
--  its -Z along the flight)
--------------------------------------------------------------------
local SHAPES = {}
function SHAPES.orb(L)
	return {{size = Vector3.one * 1.1, color = L.glow, shape = Enum.PartType.Ball, cf = CFrame.new()}}, 1.1
end
function SHAPES.lance(L)
	return {{size = Vector3.new(0.3, 0.3, 2.4), color = L.glow, cf = CFrame.new(0, 0, 0)},
		{size = Vector3.new(0.5, 0.5, 1.2), color = L.color, cf = CFrame.new(0, 0, 0.5), mat = Enum.Material.Ice}}, 0.5
end
function SHAPES.wisp(L)
	return {{size = Vector3.one * 0.6, color = L.glow, shape = Enum.PartType.Ball, cf = CFrame.new()}}, 0.6
end
function SHAPES.spark(L)
	return {{size = Vector3.one * 0.35, color = L.glow, shape = Enum.PartType.Ball, cf = CFrame.new()}}, 0.35
end
function SHAPES.comet(L)
	return {{size = Vector3.one * 1.6, color = L.glow, shape = Enum.PartType.Ball, cf = CFrame.new()},
		{size = Vector3.one * 2.3, color = L.color, shape = Enum.PartType.Ball, cf = CFrame.new(0, 0, 0.6), transp = 0.6}}, 1.8
end
-- a dragon's head of fire: a snout, a jaw open, horns swept back, burning eyes
function SHAPES.dragon(L)
	local c, g, dark = L.color, L.glow, (L.color):Lerp(Color3.new(0, 0, 0), 0.45)
	return {
		{size = Vector3.new(1.2, 1.0, 1.4), color = c, cf = CFrame.new(0, 0.1, 0.2)},                               -- the skull
		{size = Vector3.new(0.8, 0.5, 1.3), color = c, cf = CFrame.new(0, 0.2, -0.9)},                              -- the snout
		{size = Vector3.new(0.75, 0.25, 1.2), color = dark, cf = CFrame.new(0, -0.35, -0.75) * CFrame.Angles(math.rad(-18), 0, 0)},   -- the jaw
		{size = Vector3.new(0.18, 0.18, 0.18), color = WHITE, cf = CFrame.new(-0.33, 0.45, -0.3)},                  -- eyes
		{size = Vector3.new(0.18, 0.18, 0.18), color = WHITE, cf = CFrame.new(0.33, 0.45, -0.3)},
		{size = Vector3.new(0.18, 0.18, 1.3), color = g, cf = CFrame.new(-0.45, 0.7, 0.9) * CFrame.Angles(math.rad(25), math.rad(-15), 0)},   -- horns
		{size = Vector3.new(0.18, 0.18, 1.3), color = g, cf = CFrame.new(0.45, 0.7, 0.9) * CFrame.Angles(math.rad(25), math.rad(15), 0)},
		{size = Vector3.new(0.12, 0.3, 0.12), color = WHITE, cf = CFrame.new(-0.25, -0.15, -1.4)},                  -- fangs
		{size = Vector3.new(0.12, 0.3, 0.12), color = WHITE, cf = CFrame.new(0.25, -0.15, -1.4)},
		{size = Vector3.new(1.0, 1.0, 1.0), color = g, shape = Enum.PartType.Ball, cf = CFrame.new(0, -0.1, -1.0), transp = 0.35},  -- fire in its mouth
	}, 2.2
end
-- a phoenix: a bright body, two wings beating, a long tail of fire
function SHAPES.phoenix(L)
	return {
		{size = Vector3.new(0.7, 0.6, 1.4), color = L.glow, shape = Enum.PartType.Ball, cf = CFrame.new()},
		{size = Vector3.new(0.5, 0.5, 0.6), color = L.glow, shape = Enum.PartType.Ball, cf = CFrame.new(0, 0.2, -0.8)},
		-- (the wings swept up in a V, beating)
		{size = Vector3.new(2.2, 0.12, 0.9), color = L.color, cf = CFrame.new(-1.1, 0.5, 0.1) * CFrame.Angles(0, math.rad(-12), math.rad(-28)), wing = -1},
		{size = Vector3.new(2.2, 0.12, 0.9), color = L.color, cf = CFrame.new(1.1, 0.5, 0.1) * CFrame.Angles(0, math.rad(12), math.rad(28)), wing = 1},
		{size = Vector3.new(1.4, 0.1, 0.5), color = L.glow, cf = CFrame.new(-1.0, 0.56, -0.2) * CFrame.Angles(0, math.rad(-12), math.rad(-28)), wing = -1},
		{size = Vector3.new(1.4, 0.1, 0.5), color = L.glow, cf = CFrame.new(1.0, 0.56, -0.2) * CFrame.Angles(0, math.rad(12), math.rad(28)), wing = 1},
		{size = Vector3.new(0.5, 0.1, 1.6), color = L.color, cf = CFrame.new(0, 0, 1.3)},
	}, 2.4
end
-- a burning skull
function SHAPES.skull(L)
	return {
		{size = Vector3.one * 1.1, color = Color3.fromRGB(230, 225, 210), shape = Enum.PartType.Ball, cf = CFrame.new(), mat = Enum.Material.SmoothPlastic},
		{size = Vector3.new(0.7, 0.35, 0.6), color = Color3.fromRGB(220, 214, 196), cf = CFrame.new(0, -0.45, -0.15), mat = Enum.Material.SmoothPlastic},
		{size = Vector3.new(0.25, 0.25, 0.1), color = L.glow, cf = CFrame.new(-0.22, 0.05, -0.52)},
		{size = Vector3.new(0.25, 0.25, 0.1), color = L.glow, cf = CFrame.new(0.22, 0.05, -0.52)},
		{size = Vector3.one * 1.5, color = L.color, shape = Enum.PartType.Ball, cf = CFrame.new(0, 0.2, 0.3), transp = 0.55},
	}, 1.5
end

-- a star: five points round a bright heart, turning as it flies (spin: radians a second
-- round the line of flight)
function SHAPES.star(L)
	local out = {{size = Vector3.one * 0.7, color = WHITE, shape = Enum.PartType.Ball, cf = CFrame.new(), spin = 9}}
	for i = 0, 4 do
		local a = i * math.pi * 2 / 5
		table.insert(out, {size = Vector3.new(0.26, 0.9, 0.26), color = i % 2 == 0 and L.glow or L.color,
			cf = CFrame.Angles(0, 0, a) * CFrame.new(0, 0.55, 0), spin = 9})
	end
	return out, 1.2
end
-- a crescent of moonlight, spinning edge-first
function SHAPES.crescent(L)
	local out = {}
	for i = -3, 3 do
		local a = math.rad(i * 24)
		local thick = 0.34 - math.abs(i) * 0.07
		table.insert(out, {size = Vector3.new(0.5, thick, 0.16), color = math.abs(i) <= 1 and L.glow or L.color,
			cf = CFrame.Angles(0, 0, a) * CFrame.new(0, 0.9, 0), spin = -14})
	end
	table.insert(out, {size = Vector3.one * 0.35, color = WHITE, shape = Enum.PartType.Ball, cf = CFrame.new()})
	return out, 1.3
end
-- a wyrm: the dragon's head, a neck behind it and two great wings beating (a meteor's)
function SHAPES.wyrm(L)
	local out = SHAPES.dragon(L)
	local dark = (L.color):Lerp(Color3.new(0, 0, 0), 0.35)
	for i = 1, 3 do
		table.insert(out, {size = Vector3.one * (1.05 - i * 0.18), color = i % 2 == 1 and L.color or dark, shape = Enum.PartType.Ball, cf = CFrame.new(0, 0.1, 0.9 + i * 0.75)})
	end
	for _, side in ipairs({-1, 1}) do
		table.insert(out, {size = Vector3.new(2.6, 0.12, 1.5), color = L.color, cf = CFrame.new(side * 1.9, 0.5, 1.6), wing = side, transp = 0.15})
		table.insert(out, {size = Vector3.new(2.2, 0.16, 0.16), color = L.glow, cf = CFrame.new(side * 1.8, 0.56, 1.0), wing = side})
	end
	return out, 2.6
end

-- A STILL MODEL OF A SPELL'S LOOK (the menus: a card, the inspect stage): its bolt's body
-- for a bolt or a meteor, else a rune circle in its colours with its orb
function MagicFX.preview(spellId, skinId)
	local L = MagicFX.lookOf(spellId, skinId)
	local sp = Spells[spellId] or {}
	local m = Instance.new("Model")
	m.Name = "SpellPreview"
	-- (the glowing bits glow; a bolt's body is lit, so a dragon's head has a shape to it)
	local glowAll = false
	local function add(size, color, shape, cframe, mat, transp)
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CastShadow = false
		p.Size = size; p.Color = color
		p.Material = mat or ((glowAll or color == L.glow or color == WHITE) and Enum.Material.Neon or Enum.Material.SmoothPlastic)
		if shape then p.Shape = shape end
		p.Transparency = transp or 0
		p.CFrame = cframe
		p.Parent = m
		return p
	end
	local shape = L.shape
	if not shape and sp.kind == "meteor" then shape = "rock" end
	if (sp.kind == "bolt" or sp.kind == "meteor") and shape ~= "rock" then
		local spec, scale = (SHAPES[shape or "orb"] or SHAPES.orb)(L)
		-- (coming at you three-quarters on, from the right)
		local face = CFrame.lookAt(Vector3.zero, Vector3.new(-1, 0.15, 1.05))
		for _, s in ipairs(spec) do add(s.size, s.color, s.shape, face * s.cf, s.mat, s.transp) end
		-- its trail (a small one's: a big body fills the picture by itself)
		if scale < 1.5 then
			for i = 1, 4 do add(Vector3.one * (0.7 - i * 0.12), i % 2 == 1 and L.color or L.glow, Enum.PartType.Ball, CFrame.new(i * 0.85, 0, -i * 0.3), Enum.Material.Neon, 0.25 + i * 0.15) end
		end
	elseif shape == "rock" then
		add(Vector3.one * 2.4, Color3.fromRGB(60, 40, 30), Enum.PartType.Ball, CFrame.new(), Enum.Material.Basalt)
		add(Vector3.one * 3, L.color, Enum.PartType.Ball, CFrame.new(), nil, 0.55)
		for i = 1, 4 do add(Vector3.one * (1.6 - i * 0.25), i % 2 == 1 and L.color or L.glow, Enum.PartType.Ball, CFrame.new(i * 0.9, i * 0.9, 0), nil, 0.2 + i * 0.15) end
	else
		-- a circle of runes behind, faint, and the spell's own mark in front of it (all light)
		glowAll = true
		local tilt = CFrame.Angles(math.rad(70), 0, 0)
		for i = 0, 11 do
			local a = i * math.pi * 2 / 12
			add(Vector3.new(0.5, 0.12, 0.2), i % 3 == 0 and L.glow or L.color, nil, CFrame.new(0, 0, -0.6) * tilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -1.9), nil, 0.35)
		end
		add(Vector3.new(0.08, 4.2, 4.2), L.color, Enum.PartType.Cylinder, CFrame.new(0, 0, -0.6) * tilt * CFrame.Angles(0, 0, math.pi / 2), nil, 0.82)
		local k = sp.kind
		if k == "chain" then
			-- a bolt of lightning, zig-zagging down (forked; and the sky's own, for a pillar)
			local pts = {Vector3.new(-1.3, 1.5, 0.3), Vector3.new(0.3, 0.6, 0.3), Vector3.new(-0.4, 0.1, 0.3), Vector3.new(1.0, -0.8, 0.3), Vector3.new(0.2, -1.5, 0.3)}
			local w = 0.22 * (L.thick or 1)
			for i = 1, #pts - 1 do
				local a, b = pts[i], pts[i + 1]
				add(Vector3.new(w, w, (b - a).Magnitude), L.glow, nil, CFrame.lookAt((a + b) / 2, b))
				add(Vector3.new(w * 2.2, w * 2.2, (b - a).Magnitude), L.color, nil, CFrame.lookAt((a + b) / 2, b), nil, 0.6)
			end
			if L.forks then
				add(Vector3.new(w * 0.7, w * 0.7, 1.1), L.color, nil, CFrame.lookAt(Vector3.new(0.6, 0.25, 0.3), Vector3.new(1.3, 0.4, 0.3)))
				add(Vector3.new(w * 0.7, w * 0.7, 0.9), L.color, nil, CFrame.lookAt(Vector3.new(-0.9, -0.2, 0.3), Vector3.new(-1.5, -0.6, 0.3)))
			end
			if L.pillar then add(Vector3.new(w * 1.4, 4, w * 1.4), L.glow, nil, CFrame.new(1.5, 0.4, 0.2), nil, 0.2) end
		elseif k == "nova" then
			-- shards bursting out of the ground in a ring
			local mat = (L.shard and Enum.Material[L.shard]) or (L.petals and Enum.Material.Neon or Enum.Material.Ice)
			for i = 0, 7 do
				local a = i * math.pi * 2 / 8
				add(Vector3.new(0.4, 1.3, 0.4), i % 2 == 0 and L.color or L.glow, nil, CFrame.Angles(0, 0, a) * CFrame.new(0, 1.15, 0.2), mat, 0.1)
			end
			add(Vector3.one * 0.9, L.glow, Enum.PartType.Ball, CFrame.new(0, 0, 0.2))
		elseif k == "heal" then
			-- a cross of light (crowned, for a halo)
			add(Vector3.new(0.6, 2.2, 0.4), L.glow, nil, CFrame.new(0, 0, 0.3))
			add(Vector3.new(2.2, 0.6, 0.4), L.glow, nil, CFrame.new(0, 0, 0.3))
			add(Vector3.new(1.0, 2.6, 0.3), L.color, nil, CFrame.new(0, 0, 0.1), nil, 0.55)
			add(Vector3.new(2.6, 1.0, 0.3), L.color, nil, CFrame.new(0, 0, 0.1), nil, 0.55)
			if L.halo then add(Vector3.new(0.14, 1.8, 1.8), L.glow, Enum.PartType.Cylinder, CFrame.new(0, 1.75, 0.3) * CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(math.rad(-20), 0, 0)) end
		elseif k == "buff" and sp.buff == "barrier" then
			-- a shell of light
			add(Vector3.one * 2.6, L.color, Enum.PartType.Ball, CFrame.new(0, 0, 0.3), Enum.Material.ForceField, 0)
			add(Vector3.one * 2.4, L.glow, Enum.PartType.Ball, CFrame.new(0, 0, 0.3), nil, 0.85)
			add(Vector3.one * 0.7, L.glow, Enum.PartType.Ball, CFrame.new(0, 0, 0.3))
		elseif k == "buff" then
			-- wind: three chevrons, running
			for i = -1, 1 do
				for _, sgn in ipairs({1, -1}) do
					add(Vector3.new(1.1, 0.26, 0.26), i == 1 and L.glow or L.color, nil, CFrame.new(i * 0.75, 0, 0.3) * CFrame.Angles(0, 0, sgn * math.rad(40)) * CFrame.new(-0.42, 0, 0), nil, (1 - i) * 0.2)
				end
			end
		elseif k == "cloud" then
			-- a choking cloud
			for i, o in ipairs({Vector3.new(0, 0, 0.3), Vector3.new(-0.9, -0.3, 0.2), Vector3.new(0.9, -0.2, 0.2), Vector3.new(-0.4, 0.6, 0.1), Vector3.new(0.5, 0.55, 0.1), Vector3.new(0, -0.6, 0.4)}) do
				add(Vector3.one * (1.5 - i * 0.1), i % 2 == 0 and L.glow or L.color, Enum.PartType.Ball, CFrame.new(o), Enum.Material.SmoothPlastic, 0.25)
			end
		elseif k == "hex" then
			-- a curse's skull
			for _, s in ipairs((SHAPES.skull)(L)) do add(s.size * 1.4, s.color, s.shape, CFrame.Angles(0, math.pi, 0) * CFrame.new(s.cf.Position * 1.4) * s.cf.Rotation, s.mat, s.transp) end
		elseif k == "blink" then
			-- a spiral of light, stepping out of the air (and smoke, for a shadowstep)
			for i = 0, 13 do
				local a = i * 0.62
				local r = 0.25 + i * 0.1
				add(Vector3.one * (0.18 + i * 0.03), i % 2 == 0 and L.glow or L.color, Enum.PartType.Ball, CFrame.new(math.cos(a) * r, math.sin(a) * r, 0.3))
			end
			if L.smoke then add(Vector3.one * 2.4, Color3.fromRGB(24, 16, 34), Enum.PartType.Ball, CFrame.new(0.3, -0.5, -0.2), Enum.Material.SmoothPlastic, 0.35) end
		else
			add(Vector3.one * 1.1, L.glow, Enum.PartType.Ball, CFrame.new(0, 0, 0.2))
			add(Vector3.one * 1.6, L.color, Enum.PartType.Ball, CFrame.new(0, 0, 0.2), nil, 0.6)
		end
	end
	return m
end

--------------------------------------------------------------------
--  THE EVENTS
--------------------------------------------------------------------
local bolts = {}   -- id → {core, parts, pos, dir, speed, left, seek, seekRate, offset, born}

local EVENTS = {}
function EVENTS.Bolt(id, origin, dir, speed, spellId, range, caster, skin, seekTarget)
	local L = MagicFX.lookOf(spellId, skin)
	local sp = Spells[spellId] or {}
	local shapeFn = SHAPES[L.shape or "orb"] or SHAPES.orb
	local spec, scale = shapeFn(L)
	local core = part(Vector3.one * 0.2, L.glow)
	core.Transparency = 1
	core.CFrame = CFrame.lookAt(origin, origin + dir)
	local pieces = {}
	for _, s in ipairs(spec) do
		local p = part(s.size, s.color, s.shape, s.mat)
		p.Transparency = s.transp or 0
		table.insert(pieces, {part = p, cf = s.cf, wing = s.wing, spin = s.spin})
	end
	local l = Instance.new("PointLight"); l.Color = L.color; l.Range = 10 + scale * 3; l.Brightness = 3; l.Parent = core
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.3 * scale, 0); a0.Parent = core
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.3 * scale, 0); a1.Parent = core
	local tr = Instance.new("Trail"); tr.Attachment0, tr.Attachment1 = a0, a1; tr.Color = ColorSequence.new(L.glow, L.color); tr.LightEmission = 1
	tr.Transparency = NumberSequence.new(0.1, 1); tr.Lifetime = (L.shape == "wisp" or L.shape == "phoenix" or L.shape == "dragon" or L.shape == "star") and 0.5 or 0.25; tr.FaceCamera = true; tr.Parent = core
	if L.shape ~= "lance" and L.shape ~= "spark" and L.shape ~= "crescent" then
		emitter(core, TEX.fire, L.color, L.glow, 0.9 * scale, 50, {0.15, 0.35}, {0.5, 2}, Vector3.zero, 180, 1)
	end
	emitter(core, TEX.spark, L.glow, L.color, 0.3 * math.max(scale, 0.6), 25, {0.2, 0.5}, {1, 3}, Vector3.new(0, -4, 0), 180, 1)
	if (sp.mana or 0) > 0 then sound(SND.whoosh, core, 0.45, L.shape == "dragon" and 0.7 or 1.2) end
	if L.shape == "dragon" then sound(SND.boom, core, 0.35, 0.55, 1.5) end
	local tip = tipOf(caster)
	bolts[id] = {core = core, pieces = pieces, pos = origin, dir = dir, speed = speed, left = range or 300,
		seek = seekTarget, seekRate = sp.seek or 0, born = os.clock(),
		offset = (tip and (tip - origin).Magnitude < 8) and (tip - origin) or Vector3.zero}
end
function EVENTS.Impact(id, pos, spellId, fizzled, skin)
	local b = bolts[id]
	if b then bolts[id] = nil; b.core:Destroy(); for _, p in ipairs(b.pieces) do p.part:Destroy() end end
	local L = MagicFX.lookOf(spellId, skin)
	if fizzled then flash(pos, L.color, 0.6, 2.5, 0.3); return end
	local big = L.shape == "dragon" or L.shape == "comet" or L.shape == "phoenix"
	flash(pos, L.glow, 1, big and 12 or 7, 0.35)
	flash(pos, L.color, 0.6, big and 7 or 4.5, 0.5)
	burstAt(pos, L.glow, L.color, big and 40 or 22, big and 24 or 16)
	if big then groundRing(pos - Vector3.new(0, 1.5, 0), 7, 0.5, L.color, 0.25) end
	if L.shape == "lance" or L.shape == "crescent" then sound(SND.ice, pos, 0.55, 1.3, 1) else sound(SND.boom, pos, (Spells[spellId] and Spells[spellId].mana or 0) > 0 and 0.42 or 0.15, big and 0.9 or 1.25, 1.6) end
end
function EVENTS.Chain(spellId, points, caster, skin)
	local L = MagicFX.lookOf(spellId, skin)
	local tip = tipOf(caster)
	if tip and points[1] and (tip - points[1]).Magnitude < 8 then points[1] = tip end
	local k = L.thick or 1
	for i = 1, #points - 1 do
		jag(points[i], points[i + 1], L.glow, 0.32 * k, 0.28)
		jag(points[i], points[i + 1], L.color, 0.18 * k, 0.4)
		if L.forks then jag(points[i], points[i + 1] + Vector3.new(math.random() * 4 - 2, math.random() * 3, math.random() * 4 - 2), L.color, 0.12 * k, 0.3) end
		flash(points[i + 1], L.color, 0.5, 4 * k, 0.3)
		-- (the sky answers: a bolt straight down on whoever it struck)
		if L.pillar then
			local at = points[i + 1]
			jag(at + Vector3.new(math.random() * 6 - 3, 60, math.random() * 6 - 3), at, L.glow, 0.5 * k, 0.35)
			jag(at + Vector3.new(math.random() * 6 - 3, 60, math.random() * 6 - 3), at, L.color, 0.28 * k, 0.45)
			groundRing(at - Vector3.new(0, 2.8, 0), 4, 0.4, L.glow, 0.2)
		end
	end
	sound(SND.zap, points[1], 0.6, 1)
	sound(SND.boom, points[#points], 0.4, 0.62, 2)
end
function EVENTS.Nova(spellId, pos, radius, skin)
	local L = MagicFX.lookOf(spellId, skin)
	groundRing(pos, radius, 0.45, L.glow, 0.3)
	-- shards of ice (or the skin's petals) bursting up round you
	for i = 1, 14 do
		local a = math.random() * math.pi * 2
		local d = 2 + math.random() * (radius - 3)
		local h = 1.2 + math.random() * 2.2
		local s = part(Vector3.new(0.6, h, 0.6), L.color, nil, (L.shard and Enum.Material[L.shard]) or (L.petals and Enum.Material.Neon or Enum.Material.Ice))
		s.Transparency = 0.2
		local at = pos + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		s.CFrame = CFrame.new(at - Vector3.new(0, h, 0)) * CFrame.Angles(math.rad(math.random(-20, 20)), a, math.rad(math.random(-20, 20)))
		TweenService:Create(s, TweenInfo.new(0.18, Enum.EasingStyle.Back), {CFrame = s.CFrame + Vector3.new(0, h * 0.9, 0)}):Play()
		task.delay(1.2, function() if s.Parent then TweenService:Create(s, TweenInfo.new(0.5), {Transparency = 1, Size = s.Size * 0.4}):Play() end end)
		Debris:AddItem(s, 1.8)
	end
	flash(pos + Vector3.new(0, 1, 0), L.glow, 2, radius * 1.2, 0.4)
	sound(SND.ice, pos, 0.7, 0.7, 1)
	sound(SND.boom, pos, 0.35, 1.4, 1.2)
end
function EVENTS.Heal(spellId, char, time, skin)
	local torso = char and char:FindFirstChild("Torso")
	if not torso then return end
	local L = MagicFX.lookOf(spellId, skin)
	local a = Instance.new("Attachment"); a.Position = Vector3.new(0, -2.6, 0); a.Parent = torso
	local pe = emitter(a, TEX.spark, L.glow, L.color, 0.4, 40, {0.8, 1.4}, {2, 4}, Vector3.new(0, 3, 0), 30, 1)
	pe.Shape = Enum.ParticleEmitterShape.Disc; pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	pe.EmissionDirection = Enum.NormalId.Top
	local l = Instance.new("PointLight"); l.Color = L.color; l.Range = 10; l.Brightness = 2; l.Parent = torso
	task.delay(time or 2, function() pe.Enabled = false; TweenService:Create(l, TweenInfo.new(0.4), {Brightness = 0}):Play() end)
	Debris:AddItem(a, (time or 2) + 1.5); Debris:AddItem(l, (time or 2) + 0.5)
	if L.halo then
		-- a ring of light over the head for as long as it heals
		local head = char:FindFirstChild("Head")
		local ring = part(Vector3.new(0.12, 1.7, 1.7), L.glow, Enum.PartType.Cylinder)
		ring.Transparency = 0.15
		local t0, conn = os.clock(), nil
		conn = RunService.RenderStepped:Connect(function()
			if not (ring.Parent and head and head.Parent) then if conn then conn:Disconnect() end; return end
			local t = os.clock() - t0
			ring.CFrame = CFrame.new(head.Position + Vector3.new(0, 1.15 + math.sin(t * 3) * 0.08, 0)) * CFrame.Angles(0, t * 1.5, math.pi / 2)
		end)
		task.delay(time or 2, function() if ring.Parent then TweenService:Create(ring, TweenInfo.new(0.5), {Transparency = 1}):Play() end end)
		Debris:AddItem(ring, (time or 2) + 0.6)
	end
	sound(SND.cast, torso, 0.35, 1.8, 2)
	sound(SND.shing, torso, 0.25, 1.6, 1)
end
-- a meteor: the warning ring where it'll land, a burning rock falling out of the sky, the blast
function EVENTS.Meteor(spellId, pos, radius, delay, skin)
	local L = MagicFX.lookOf(spellId, skin)
	groundRing(pos, radius, delay, L.color, 0.18, true)
	local disc = part(Vector3.new(0.1, radius * 2, radius * 2), L.color, Enum.PartType.Cylinder)
	disc.CFrame = CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	disc.Transparency = 0.82
	Debris:AddItem(disc, delay + 0.1)
	local from = pos + Vector3.new(-18, 70, -10)
	local rock
	if L.shape and SHAPES[L.shape] and L.shape ~= "orb" then
		local spec = SHAPES[L.shape](L)
		local k = (L.shape == "wyrm" or L.shape == "dragon") and 2.6 or 2.2
		rock = {}
		for _, s in ipairs(spec) do local p = part(s.size * k, s.color, s.shape, s.mat); p.Transparency = s.transp or 0; table.insert(rock, {part = p, cf = CFrame.new(s.cf.Position * k) * s.cf.Rotation, wing = s.wing}) end
		if L.shape == "wyrm" then sound(SND.boom, pos, 0.5, 0.45, 2) end
	else
		rock = {{part = part(Vector3.one * 4.5, Color3.fromRGB(60, 40, 30), Enum.PartType.Ball, Enum.Material.Basalt), cf = CFrame.new()},
			{part = part(Vector3.one * 5.5, L.color, Enum.PartType.Ball), cf = CFrame.new()}}
		rock[2].part.Transparency = 0.5
	end
	local holder = part(Vector3.one * 0.2, L.color); holder.Transparency = 1
	emitter(holder, TEX.fire, L.color, L.glow, 4, 80, {0.3, 0.6}, {2, 6}, Vector3.zero, 40, 1)
	emitter(holder, TEX.smoke, Color3.fromRGB(70, 60, 55), nil, 4, 30, {0.6, 1.2}, {1, 3}, Vector3.zero, 60, 0)
	local t0 = os.clock()
	local conn
	sound(SND.whoosh, pos, 0.6, 0.45, 2)
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / delay, 0, 1)
		local p = from:Lerp(pos, k * k)
		local face = CFrame.lookAt(p, pos)
		holder.Position = p
		for _, r in ipairs(rock) do
			r.part.CFrame = r.wing and (face * CFrame.Angles(0, 0, r.wing * math.sin(os.clock() * 9) * 0.5) * r.cf) or (face * r.cf)
		end
		if k >= 1 then
			conn:Disconnect()
			for _, r in ipairs(rock) do r.part:Destroy() end
			holder:Destroy()
			flash(pos + Vector3.new(0, 1, 0), L.glow, 3, radius * 2.2, 0.5)
			flash(pos + Vector3.new(0, 1, 0), L.color, 2, radius * 1.4, 0.8)
			burstAt(pos + Vector3.new(0, 1, 0), L.glow, L.color, 60, 30)
			groundRing(pos, radius * 1.3, 0.5, L.glow, 0.4)
			sound(SND.boom, pos, 0.9, 0.7, 3)
		end
	end)
end
-- a cloud: a green haze on the ground for a while
function EVENTS.Cloud(spellId, pos, radius, time, skin)
	local L = MagicFX.lookOf(spellId, skin)
	local disc = part(Vector3.new(0.1, radius * 2, radius * 2), L.color, Enum.PartType.Cylinder)
	disc.CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	disc.Transparency = 0.75
	local holder = part(Vector3.new(radius * 1.6, 2, radius * 1.6), L.color); holder.Transparency = 1
	holder.Position = pos + Vector3.new(0, 1.4, 0)
	local pe = emitter(holder, TEX.smoke, L.color, L.glow, 6, 22, {1.6, 2.6}, {0.2, 1}, Vector3.new(0, 0.4, 0), 180, 0.3)
	pe.Shape = Enum.ParticleEmitterShape.Box; pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(1, 1)})
	sound(SND.hum, pos, 0.3, 0.6, time)
	task.delay(time, function()
		pe.Enabled = false
		TweenService:Create(disc, TweenInfo.new(0.8), {Transparency = 1}):Play()
	end)
	Debris:AddItem(disc, time + 1); Debris:AddItem(holder, time + 3)
end
-- a buff: haste or a barrier going on (what stays is drawn from the attributes below)
function EVENTS.Buff(spellId, char, buff, time, skin)
	local torso = char and char:FindFirstChild("Torso")
	if not torso then return end
	local L = MagicFX.lookOf(spellId, skin)
	flash(torso.Position, L.glow, 1, 7, 0.35)
	groundRing(torso.Position - Vector3.new(0, 2.8, 0), 4, 0.4, L.color, 0.18)
	sound(SND.shing, torso, 0.4, buff == "haste" and 1.6 or 1.1, 1)
	sound(SND.cast, torso, 0.25, 2, 1)
end
-- a hex: a curse leaping from the hand (its mark stays over the head: the attributes below)
function EVENTS.Hex(spellId, from, to, time, skin)
	local L = MagicFX.lookOf(spellId, skin)
	local p = typeof(to) == "Instance" and to:FindFirstChild("Head") and to.Head.Position or to
	if typeof(p) ~= "Vector3" then return end
	jag(from, p, L.color, 0.2, 0.5)
	jag(from, p, Color3.fromRGB(20, 10, 30), 0.35, 0.35)
	flash(p, L.color, 1, 5, 0.4)
	sound(SND.zap2, p, 0.5, 0.55, 1)
end
-- a blink: gone in a puff, out of the air in a flash, a streak between
function EVENTS.Blink(spellId, from, to, skin)
	local L = MagicFX.lookOf(spellId, skin)
	burstAt(from, L.glow, L.color, 30, 10)
	flash(from, L.color, 3, 0.5, 0.3)
	flash(to, L.glow, 0.5, 6, 0.35)
	local s = part(Vector3.new(0.3, 0.3, (to - from).Magnitude), L.glow)
	s.CFrame = CFrame.lookAt((from + to) / 2, to)
	TweenService:Create(s, TweenInfo.new(0.35), {Transparency = 1, Size = Vector3.new(0.05, 0.05, s.Size.Z)}):Play()
	Debris:AddItem(s, 0.4)
	if L.smoke then
		for _, at in ipairs({from, to}) do
			local h = part(Vector3.one * 0.2, L.color); h.Transparency = 1; h.Position = at
			emitter(h, TEX.smoke, Color3.fromRGB(20, 14, 28), L.color, 3, 0, {0.8, 1.4}, {1, 4}, Vector3.new(0, 1.5, 0), 180, 0):Emit(26)
			Debris:AddItem(h, 1.6)
		end
	end
	sound(SND.whoosh, to, 0.5, 1.6, 1)
end
function EVENTS.Fizzle(char)
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	local holder = part(Vector3.one * 0.2, Color3.new(), nil, Enum.Material.SmoothPlastic)
	holder.Transparency = 1; holder.Position = head.Position + Vector3.new(0, 0.5, 0)
	emitter(holder, TEX.smoke, Color3.fromRGB(160, 160, 180), nil, 1.2, 0, {0.5, 0.9}, {1, 3}, Vector3.new(0, 2, 0), 180, 0):Emit(10)
	Debris:AddItem(holder, 1.2)
	sound(SND.zap2, holder, 0.3, 0.6, 0.6)
end

--------------------------------------------------------------------
--  WHAT CHARACTERS CARRY
--------------------------------------------------------------------
local looks = setmetatable({}, {__mode = "k"})   -- char → {circle, ward, burn, frost, med, shell, hex, haste}

local function staffTip(char)
	local t = tipOf(char)
	if t then return t end
	local head = char:FindFirstChild("Head")
	return head and head.Position or nil
end
-- the skin a caster wears on a spell (their weapon's SpellSkins: "Firebolt=Dragonfire,…")
local function skinOf(char, spellId)
	local tool = char:FindFirstChildOfClass("Tool")
	local list = tool and tool:GetAttribute("SpellSkins")
	if type(list) ~= "string" then return nil end
	for sp, sk in list:gmatch("([%w_]+)=([%w_]+)") do if sp == spellId then return sk end end
	return nil
end
local function makeCircle(char, spellId)
	local L = MagicFX.lookOf(spellId, skinOf(char, spellId))
	local m = {segs = {}, runes = {}, spell = spellId, t0 = os.clock()}
	for i = 1, 20 do m.segs[i] = part(Vector3.new(0.4, 0.08, 0.08), L.glow) end
	for i = 1, 6 do m.runes[i] = part(Vector3.new(0.18, 0.5, 0.06), L.color) end
	m.inner = {}
	for i = 1, 12 do m.inner[i] = part(Vector3.new(0.3, 0.06, 0.06), L.color) end
	local tip = staffTip(char)
	m.light = part(Vector3.one * 0.6, L.glow, Enum.PartType.Ball)
	m.light.Transparency = 0.2
	local l = Instance.new("PointLight"); l.Color = L.color; l.Range = 10; l.Brightness = 2; l.Parent = m.light
	m.sparks = emitter(m.light, TEX.spark, L.glow, L.color, 0.3, 30, {0.2, 0.5}, {1, 3}, Vector3.zero, 180, 1)
	m.sound = sound(SND.cast, m.light, 0.32, 1.1, 2)
	if tip then m.light.Position = tip end
	return m
end
local function dropCircle(m, burst)
	if not m then return end
	for _, s in ipairs(m.segs) do s:Destroy() end
	for _, s in ipairs(m.runes) do s:Destroy() end
	for _, s in ipairs(m.inner) do s:Destroy() end
	if burst and m.light.Parent then flash(m.light.Position, m.light.Color, 0.8, 3, 0.25) end
	m.light:Destroy()
	if m.sound then m.sound:Destroy() end
end
local function makeWard()
	local disc = part(Vector3.new(0.12, 6, 6), Color3.fromRGB(160, 200, 255), Enum.PartType.Cylinder, Enum.Material.ForceField)
	disc.Transparency = 0.1
	local rim = {}
	for i = 1, 18 do rim[i] = part(Vector3.new(0.12, 0.12, 1.1), Color3.fromRGB(190, 220, 255)) end
	local hum = sound(SND.hum, disc, 0.12, 1.5, 999)
	hum.Looped = true
	return {disc = disc, rim = rim, hum = hum}
end
local function dropWard(w, broke)
	if not w then return end
	if broke and w.disc.Parent then
		burstAt(w.disc.Position, Color3.fromRGB(200, 230, 255), Color3.fromRGB(120, 170, 255), 30, 16)
		sound(SND.ice, w.disc.Position, 0.6, 1.3, 1)
	end
	w.disc:Destroy()
	for _, r in ipairs(w.rim) do r:Destroy() end
end
-- meditation: a circle of runes turning on the ground, light rising into you
local function makeMed(char)
	local m = {segs = {}, runes = {}}
	local col, glow = Color3.fromRGB(120, 180, 255), Color3.fromRGB(220, 240, 255)
	for i = 1, 24 do m.segs[i] = part(Vector3.new(0.6, 0.06, 0.1), col) end
	for i = 1, 8 do m.runes[i] = part(Vector3.new(0.12, 0.06, 0.5), glow) end
	local torso = char:FindFirstChild("Torso")
	if torso then
		local a = Instance.new("Attachment"); a.Name = "MagicFX_med"; a.Position = Vector3.new(0, -2.8, 0); a.Parent = torso
		local pe = emitter(a, TEX.spark, glow, col, 0.25, 26, {1, 1.6}, {1.5, 3}, Vector3.new(0, 1.5, 0), 25, 1)
		pe.Shape = Enum.ParticleEmitterShape.Disc; pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume; pe.EmissionDirection = Enum.NormalId.Top
		local l = Instance.new("PointLight"); l.Color = col; l.Range = 9; l.Brightness = 1.4; l.Parent = a
		m.att = a
	end
	m.hum = sound(SND.choir, char:FindFirstChild("Head") or fxFolder(), 0.12, 1, 999)
	m.hum.Looped = true
	return m
end
local function dropMed(m)
	if not m then return end
	for _, s in ipairs(m.segs) do s:Destroy() end
	for _, s in ipairs(m.runes) do s:Destroy() end
	if m.att then m.att:Destroy() end
	if m.hum then m.hum:Destroy() end
end

local function bodyFx(char, kind)
	local torso = char:FindFirstChild("Torso")
	if not torso then return nil end
	local a = Instance.new("Attachment"); a.Name = "MagicFX_" .. kind; a.Parent = torso
	if kind == "burn" then
		emitter(a, TEX.fire, Color3.fromRGB(255, 160, 60), Color3.fromRGB(200, 40, 10), 1.6, 30, {0.3, 0.6}, {1, 3}, Vector3.new(0, 6, 0), 40, 1)
		emitter(a, TEX.spark, Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 80, 20), 0.25, 14, {0.4, 0.9}, {1, 4}, Vector3.new(0, 5, 0), 90, 1)
	elseif kind == "frost" then
		emitter(a, TEX.spark, Color3.fromRGB(240, 252, 255), Color3.fromRGB(150, 214, 255), 0.3, 24, {0.6, 1.2}, {0.2, 0.8}, Vector3.new(0, -1.5, 0), 180, 0.8)
		emitter(a, TEX.smoke, Color3.fromRGB(200, 236, 255), nil, 1.4, 6, {0.6, 1}, {0.2, 0.6}, Vector3.new(0, -0.5, 0), 180, 0.2)
	elseif kind == "haste" then
		a.Position = Vector3.new(0, -2.6, 0)
		emitter(a, TEX.spark, Color3.fromRGB(220, 250, 255), Color3.fromRGB(120, 220, 255), 0.35, 40, {0.3, 0.6}, {3, 6}, Vector3.new(0, 2, 0), 70, 1)
	end
	return a
end
-- a barrier's shell, and a hex's mark
local function makeShell(char)
	local s = part(Vector3.one * 6.2, Color3.fromRGB(255, 220, 120), Enum.PartType.Ball, Enum.Material.ForceField)
	s.Transparency = 0.15
	return s
end
local function makeHexMark()
	local m = {}
	m.core = part(Vector3.one * 0.7, Color3.fromRGB(180, 80, 255), Enum.PartType.Ball)
	m.core.Transparency = 0.15
	m.ring = {}
	for i = 1, 10 do m.ring[i] = part(Vector3.new(0.3, 0.06, 0.06), Color3.fromRGB(230, 190, 255)) end
	emitter(m.core, TEX.smoke, Color3.fromRGB(70, 20, 110), Color3.fromRGB(20, 10, 30), 0.8, 10, {0.5, 1}, {0.3, 1}, Vector3.new(0, 1, 0), 180, 0)
	return m
end
local function dropHex(m) if not m then return end; m.core:Destroy(); for _, r in ipairs(m.ring) do r:Destroy() end end

local function chars()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(out, p.Character) end end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do if m:IsA("Model") then table.insert(out, m) end end end
	return out
end

--------------------------------------------------------------------
--  THE HOLD: a staff upright, a tome open (the grip joint's C0, on every screen)
--------------------------------------------------------------------
local held = setmetatable({}, {__mode = "k"})   -- grip joint → its own C0
local function gripOf(char)
	local arm = char:FindFirstChild("Right Arm")
	return arm and (arm:FindFirstChild("ToolGrip") or arm:FindFirstChild("RightGrip")), arm
end
local function hold(char)
	local tool = char:FindFirstChildOfClass("Tool")
	local grip = gripOf(char)
	local stance = tool and tool:GetAttribute("Magic") and tool:GetAttribute("Stance")
	if not (grip and grip:IsA("JointInstance")) then return end
	if not (stance == 3 or stance == 4) or Emotes.playing(char) then
		if held[grip] then grip.C0 = held[grip]; held[grip] = nil end
		return
	end
	local hrp, torso = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChild("Torso")
	local rj = hrp and hrp:FindFirstChild("RootJoint")
	local sh = torso and torso:FindFirstChild("Right Shoulder")
	if not (rj and sh) then return end
	if not held[grip] then held[grip] = grip.C0 end
	local torsoCF = hrp.CFrame * rj.C0 * rj.Transform * rj.C1:Inverse()
	local armCF = torsoCF * sh.C0 * sh.Transform * sh.C1:Inverse()
	local hand = (armCF * CFrame.new(0, -1, 0)).Position
	local body = CFrame.new(hand) * (hrp.CFrame - hrp.Position)
	local want
	if stance == 3 then
		-- upright, its business end up; a hair forward while a spell's coming
		local lean = char:GetAttribute("Casting") and math.rad(8) or 0
		want = body * CFrame.Angles(-lean, 0, 0)
	else
		-- open before you, nearly flat, the pages up towards your face
		want = body * CFrame.Angles(math.rad(-78), 0, 0)
	end
	grip.C0 = armCF:Inverse() * want * grip.C1
end

function MagicFX.start()
	local fxRemote = ReplicatedStorage:WaitForChild("MagicFXRemote", 30)
	if fxRemote then
		fxRemote.OnClientEvent:Connect(function(what, ...)
			local fn = EVENTS[what]
			if fn then local ok, err = pcall(fn, ...); if not ok then warn("[MagicFX]", what, err) end end
		end)
	end
	local scan = 0
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		local snow = workspace:GetServerTimeNow()
		-- the bolts fly on every screen
		for id, b in pairs(bolts) do
			if b.seek and b.seekRate > 0 and b.seek.Parent then
				local r = b.seek:FindFirstChild("HumanoidRootPart")
				if r then
					local want = r.Position - b.pos
					if want.Magnitude > 1 then b.dir = b.dir:Lerp(want.Unit, math.min(1, b.seekRate * dt)).Unit end
				end
			end
			local step = b.speed * dt
			b.pos += b.dir * step
			b.left -= step
			if b.left <= 0 or not b.core.Parent then
				bolts[id] = nil
				if b.core.Parent then b.core:Destroy() end
				for _, p in ipairs(b.pieces) do p.part:Destroy() end
			else
				local at = b.pos + b.offset * (1 - math.clamp((now - b.born) / 0.15, 0, 1))
				local cf = CFrame.lookAt(at, at + b.dir)
				b.core.CFrame = cf
				for _, p in ipairs(b.pieces) do
					local c = cf * p.cf
					if p.wing then c = cf * CFrame.Angles(0, 0, p.wing * math.sin(now * 14) * 0.6) * p.cf end
					if p.spin then c = cf * CFrame.Angles(0, 0, now * p.spin) * p.cf end
					p.part.CFrame = c
				end
			end
		end
		scan += dt
		local full = scan > 0.1
		if full then scan = 0 end
		for _, char in ipairs(chars()) do
			pcall(hold, char)
			local L = looks[char]
			if not L then L = {}; looks[char] = L end
			-- the casting circle
			local casting = char:GetAttribute("Casting")
			if casting and not L.circle then L.circle = makeCircle(char, casting) end
			if L.circle and (not casting or casting ~= L.circle.spell) then dropCircle(L.circle, casting == nil); L.circle = nil end
			if L.circle then
				local m = L.circle
				local tip = staffTip(char)
				local root = char:FindFirstChild("HumanoidRootPart")
				if tip and root then
					local k = math.clamp((now - m.t0) / math.max(char:GetAttribute("CastTime") or 0.5, 0.1), 0, 1)
					local r = 0.6 + 1.3 * (1 - (1 - k) ^ 2)
					local look = root.CFrame.LookVector
					local centre = tip + look * 0.8
					local face = CFrame.lookAt(centre, centre + look)
					local spin = now * 3
					for i, s in ipairs(m.segs) do
						local a = i / #m.segs * math.pi * 2 + spin * 0.4
						s.Size = Vector3.new(2 * math.pi * r / #m.segs * 1.08, 0.08, 0.08)
						s.CFrame = face * CFrame.Angles(0, 0, a) * CFrame.new(0, r, 0)
					end
					for i, s in ipairs(m.inner) do
						local a = i / #m.inner * math.pi * 2 - spin * 0.7
						local ri = r * 0.62
						s.Size = Vector3.new(2 * math.pi * ri / #m.inner * 1.08, 0.06, 0.06)
						s.CFrame = face * CFrame.Angles(0, 0, a) * CFrame.new(0, ri, 0)
					end
					for i, s in ipairs(m.runes) do
						local a = i / #m.runes * math.pi * 2 - spin
						s.CFrame = face * CFrame.Angles(0, 0, a) * CFrame.new(0, r * 0.82, -0.02) * CFrame.Angles(0, 0, math.rad(20))
						s.Transparency = 0.6 - 0.5 * k
					end
					m.light.Position = tip
					m.light.Size = Vector3.one * (0.5 + 0.5 * k)
				end
			end
			-- the ward
			local warded = char:GetAttribute("Warded") == true
			if warded and not L.ward then L.ward = makeWard() end
			if L.ward and not warded then dropWard(L.ward, now - (char:GetAttribute("WardBroke") or -1e9) < 0.5); L.ward = nil end
			if L.ward then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					local hit = now - (char:GetAttribute("WardHit") or -1e9)
					local pulse = hit < 0.3 and (1 - hit / 0.3) or 0
					local c = root.CFrame * CFrame.new(0, 0.3, -2.2)
					L.ward.disc.CFrame = c * CFrame.Angles(0, math.pi / 2, 0)
					L.ward.disc.Size = Vector3.new(0.12, 5.6 + pulse * 1.2, 5.6 + pulse * 1.2)
					L.ward.disc.Color = Color3.fromRGB(160, 200, 255):Lerp(WHITE, pulse)
					for i, s in ipairs(L.ward.rim) do
						local a = i / #L.ward.rim * math.pi * 2 + now
						local rr = 2.8 + pulse * 0.6
						s.CFrame = c * CFrame.Angles(0, 0, a) * CFrame.new(0, rr, 0) * CFrame.Angles(0, math.pi / 2, 0)
					end
					if pulse > 0.95 and not L.wardSnd then L.wardSnd = true; sound(SND.shing, L.ward.disc, 0.4, 1.4, 0.6) elseif pulse < 0.5 then L.wardSnd = false end
				end
			end
			-- meditation
			local med = char:GetAttribute("Meditating") == true
			if med and not L.med then L.med = makeMed(char) end
			if L.med and not med then dropMed(L.med); L.med = nil end
			if L.med then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					local base = root.Position - Vector3.new(0, 2.9, 0)
					local grow = math.clamp((snow - (char:GetAttribute("MeditateStart") or snow)) / Spells.MEDITATE.windup, 0, 1)
					local r = 1.2 + 1.6 * grow
					for i, s in ipairs(L.med.segs) do
						local a = i / #L.med.segs * math.pi * 2 + now * 0.5
						s.Size = Vector3.new(2 * math.pi * r / #L.med.segs * 1.05, 0.06, 0.1)
						s.CFrame = CFrame.new(base + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)) * CFrame.Angles(0, -a + math.pi / 2, 0)
						s.Transparency = 0.2 + 0.5 * (1 - grow)
					end
					for i, s in ipairs(L.med.runes) do
						local a = i / #L.med.runes * math.pi * 2 - now * 0.8
						s.CFrame = CFrame.new(base + Vector3.new(math.cos(a) * r * 0.7, 0.02, math.sin(a) * r * 0.7)) * CFrame.Angles(0, -a, 0)
						s.Transparency = 0.3 + 0.6 * (1 - grow)
					end
				end
			end
			-- a barrier's shell
			local shield = (char:GetAttribute("Shield") or 0) > 0 and (char:GetAttribute("ShieldUntil") or 0) > snow
			if shield and not L.shell then L.shell = makeShell(char) end
			if L.shell and not shield then
				burstAt(L.shell.Position, Color3.fromRGB(255, 230, 150), Color3.fromRGB(255, 180, 60), 24, 12)
				L.shell:Destroy(); L.shell = nil
			end
			if L.shell then
				local root = char:FindFirstChild("HumanoidRootPart")
				local hit = now - (char:GetAttribute("ShieldHit") or -1e9)
				local pulse = hit < 0.25 and (1 - hit / 0.25) or 0
				if root then L.shell.Position = root.Position + Vector3.new(0, 0.3, 0) end
				L.shell.Size = Vector3.one * (6.2 + pulse * 0.8)
				L.shell.Color = Color3.fromRGB(255, 220, 120):Lerp(WHITE, pulse)
			end
			-- a hex's mark over the head
			local hexed = (char:GetAttribute("HexUntil") or 0) > snow
			if hexed and not L.hex then L.hex = makeHexMark() end
			if L.hex and not hexed then dropHex(L.hex); L.hex = nil end
			if L.hex then
				local head = char:FindFirstChild("Head")
				if head then
					local c = head.Position + Vector3.new(0, 2.1 + math.sin(now * 3) * 0.15, 0)
					L.hex.core.Position = c
					for i, s in ipairs(L.hex.ring) do
						local a = i / #L.hex.ring * math.pi * 2 + now * 2
						s.CFrame = CFrame.new(c + Vector3.new(math.cos(a) * 0.8, 0, math.sin(a) * 0.8)) * CFrame.Angles(0, -a + math.pi / 2, 0)
					end
				end
			end
			-- burning, frosted, hasted
			if full then
				local burning = char:GetAttribute("Burning") == true
				if burning and not L.burn then L.burn = bodyFx(char, "burn") elseif not burning and L.burn then L.burn:Destroy(); L.burn = nil end
				local frosted = char:GetAttribute("Frosted") == true
				if frosted and not L.frost then L.frost = bodyFx(char, "frost") elseif not frosted and L.frost then L.frost:Destroy(); L.frost = nil end
				local hasted = (char:GetAttribute("HasteUntil") or 0) > snow
				if hasted and not L.haste then L.haste = bodyFx(char, "haste") elseif not hasted and L.haste then L.haste:Destroy(); L.haste = nil end
			end
		end
		-- (gone characters)
		if full then
			for char, L in pairs(looks) do
				if not char.Parent then
					dropCircle(L.circle); dropWard(L.ward); dropMed(L.med); dropHex(L.hex)
					if L.shell then L.shell:Destroy() end
					looks[char] = nil
				end
			end
		end
	end)
end

return MagicFX
