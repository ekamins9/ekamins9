--[[ ARROW FX — what a bow or crossbow skin does to its arrows (Catalog ▸ Skins
     `arrow = "<kind>"`). The arrow in flight wears it (ArrowFlight: a coloured
     trail with a hot core, a glowing head, particles streaming off it, a light,
     and the kind's own touch: a halo, a flicker, smoke, wisps), it bursts where
     it lands with the kind's own impact (a fire that keeps burning, ice shards,
     a lightning bolt from the sky, a pillar of light, an implosion, a splash,
     a lingering cloud, a spray of gold, rising wisps), and an arrow left
     standing smoulders a moment (RangedServer). Each kind has its own release
     and impact sounds (RangedServer plays them: ArrowFX.sound).

       ArrowFX.decorate(shaft, head, kind, opts)   a flying (or stuck) arrow; opts.stuck
       ArrowFX.burst(position, kind, parent)       the impact
       ArrowFX.sound(kind, "release" | "impact")   -> {id, Speed, Volume} | nil
       ArrowFX.KINDS[kind].name                    "Fire Arrows" (menus)

     Kinds: fire frost shadow holy storm toxic gold blood void spirit ]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local ArrowFX = {}
local C = Color3.fromRGB
local TEX = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
}
-- licensed sounds (Pro Sound Effects / APM; the same ones the kill effects use)
local S = {
	fireWhoosh = 9120696702, fireBurst = 9114444008, iceCrack = 9118762653, glassShatter = 9114592245,
	rift = 9120706422, synthRip = 9119805147, choir = 1846902441, zap = 9119594928, thunder = 9126099928,
	hiss = 9119303232, splash = 9119479417, shells = 9119117331, chomp = 9113574800, rumble = 9118749929,
	wings = 9125386714, swish = 9120726501,
}

-- trail, head (glowing), light, the particles off it (tex, two colours, size,
-- rate, lifetime, drift), the burst on landing (count, speed), its impact, its sounds
ArrowFX.KINDS = {
	fire   = {name = "Fire Arrows",   trail = C(255, 150, 50),  head = C(255, 120, 30),  light = C(255, 140, 50),
		p = {TEX.fire, C(255, 210, 90), C(255, 60, 20), 0.8, 50, 0.35, Vector3.new(0, 5, 0)}, burst = {32, 11}, impact = "fire", smoke = true,
		snd = {release = {S.fireWhoosh, 1.5, 0.5}, impact = {S.fireBurst, 1.2, 0.6}}},
	frost  = {name = "Frost Arrows",  trail = C(170, 230, 255), head = C(210, 245, 255), light = C(150, 220, 255),
		p = {TEX.spark, C(240, 252, 255), C(130, 200, 255), 0.35, 34, 0.6, Vector3.new(0, -3, 0)}, burst = {26, 8}, impact = "shards",
		snd = {release = {S.iceCrack, 1.6, 0.35}, impact = {S.glassShatter, 1.3, 0.6}}},
	shadow = {name = "Shadow Arrows", trail = C(120, 50, 190),  head = C(70, 20, 110),   light = C(140, 60, 220),
		p = {TEX.smoke, C(80, 30, 120), C(10, 0, 20), 0.9, 28, 0.7, Vector3.new(0, 1, 0)}, burst = {22, 6}, impact = "implode",
		snd = {release = {S.rift, 1.8, 0.4}, impact = {S.synthRip, 1.2, 0.5}}},
	holy   = {name = "Holy Arrows",   trail = C(255, 240, 170), head = C(255, 236, 150), light = C(255, 230, 150),
		p = {TEX.spark, C(255, 250, 220), C(255, 210, 110), 0.45, 40, 0.5, Vector3.new(0, 2, 0)}, burst = {34, 9}, impact = "pillar", halo = true,
		snd = {release = {S.choir, 1.6, 0.35}, impact = {S.choir, 1.1, 0.5}}},
	storm  = {name = "Storm Arrows",  trail = C(150, 210, 255), head = C(200, 235, 255), light = C(150, 210, 255),
		p = {TEX.spark, C(230, 245, 255), C(90, 160, 255), 0.5, 55, 0.2, Vector3.zero}, burst = {40, 18}, impact = "bolt", flicker = true,
		snd = {release = {S.zap, 1.4, 0.45}, impact = {S.thunder, 1.0, 0.55}}},
	toxic  = {name = "Venom Arrows",  trail = C(130, 255, 90),  head = C(110, 230, 70),  light = C(120, 255, 90),
		p = {TEX.smoke, C(140, 255, 100), C(40, 90, 20), 0.65, 28, 0.7, Vector3.new(0, -1, 0)}, burst = {24, 5}, impact = "cloud",
		snd = {release = {S.hiss, 1.6, 0.4}, impact = {S.splash, 1.4, 0.5}}},
	gold   = {name = "Gilded Arrows", trail = C(255, 205, 80),  head = C(255, 200, 70),  light = C(255, 200, 90),
		p = {TEX.spark, C(255, 240, 160), C(255, 180, 40), 0.4, 36, 0.5, Vector3.new(0, -2, 0)}, burst = {34, 10}, impact = "fountain",
		snd = {release = {S.swish, 1.8, 0.35}, impact = {S.shells, 1.6, 0.6}}},
	blood  = {name = "Blood Arrows",  trail = C(190, 20, 30),   head = C(150, 10, 20),   light = C(200, 30, 40),
		p = {TEX.smoke, C(170, 20, 30), C(60, 0, 5), 0.5, 28, 0.55, Vector3.new(0, -4, 0)}, burst = {28, 7}, impact = "splatter",
		snd = {release = {S.swish, 1.3, 0.4}, impact = {S.chomp, 1.1, 0.5}}},
	void   = {name = "Void Arrows",   trail = C(90, 30, 160),   head = C(20, 0, 40),     light = C(160, 70, 255),
		p = {TEX.smoke, C(170, 90, 255), C(5, 0, 15), 1.0, 34, 0.6, Vector3.new(0, 0.5, 0)}, burst = {30, 4}, impact = "implode", dark = true,
		snd = {release = {S.rift, 1.3, 0.5}, impact = {S.rumble, 1.4, 0.6}}},
	spirit = {name = "Spirit Arrows", trail = C(170, 255, 230), head = C(220, 255, 245), light = C(160, 255, 220),
		p = {TEX.spark, C(220, 255, 245), C(90, 200, 180), 0.5, 40, 0.9, Vector3.new(0, 3, 0)}, burst = {30, 6}, impact = "wisps", wisps = true,
		snd = {release = {S.wings, 1.6, 0.4}, impact = {S.choir, 1.5, 0.45}}},
}

function ArrowFX.sound(kind, which)
	local k = kind and ArrowFX.KINDS[kind]
	local s = k and k.snd and k.snd[which]
	if not s then return nil end
	return {id = "rbxassetid://" .. s[1], Speed = s[2], Volume = s[3]}
end

local function emitter(parent, k, scale)
	local p = k.p
	local e = Instance.new("ParticleEmitter")
	e.Texture = p[1]
	e.Color = ColorSequence.new(p[2], p[3])
	e.Size = NumberSequence.new(p[4] * (scale or 1), 0)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Rate = p[5] * (scale or 1)
	e.Lifetime = NumberRange.new(p[6] * 0.7, p[6])
	e.Speed = NumberRange.new(0.3, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = p[7]
	e.LightEmission = k.dark and 0 or 0.8
	e.Parent = parent
	return e
end

local function trail(shaft, a0, a1, color, life, transp, emission)
	local t = Instance.new("Trail")
	t.Attachment0, t.Attachment1 = a0, a1
	t.Lifetime = life
	t.Color = typeof(color) == "ColorSequence" and color or ColorSequence.new(color)
	t.Transparency = transp
	t.LightEmission = emission
	t.FaceCamera = true
	t.WidthScale = NumberSequence.new(1, 0.15)
	t.Parent = shaft
	return t
end

function ArrowFX.decorate(shaft, head, kind, opts)
	local k = kind and ArrowFX.KINDS[kind]
	if not (k and shaft) then return end
	opts = opts or {}
	if head then
		head.Color = k.head
		head.Material = Enum.Material.Neon
	end
	local tip = Instance.new("Attachment"); tip.Position = Vector3.new(0, 0, -shaft.Size.Z / 2); tip.Parent = shaft
	if not opts.stuck then
		-- the colour trail, wide, and a hot white core inside it
		local up = Instance.new("Attachment"); up.Position = Vector3.new(0, 0.24, 0); up.Parent = shaft
		local down = Instance.new("Attachment"); down.Position = Vector3.new(0, -0.24, 0); down.Parent = shaft
		trail(shaft, up, down, ColorSequence.new(k.light, k.trail), 0.45, NumberSequence.new(0.15, 1), k.dark and 0.2 or 1)
		local up2 = Instance.new("Attachment"); up2.Position = Vector3.new(0, 0.07, 0); up2.Parent = shaft
		local down2 = Instance.new("Attachment"); down2.Position = Vector3.new(0, -0.07, 0); down2.Parent = shaft
		trail(shaft, up2, down2, k.dark and k.head or Color3.new(1, 1, 1), 0.18, NumberSequence.new(0.1, 1), 1)
		emitter(tip, k, 1)
		if k.smoke then
			local sm = emitter(tip, {p = {TEX.smoke, C(90, 80, 70), C(40, 36, 34), 0.9, 18, 0.8, Vector3.new(0, 3, 0)}}, 1)
			sm.LightEmission = 0
		end
		if k.wisps then
			local w = emitter(tip, k, 0.6)
			w.Lifetime = NumberRange.new(1.2, 1.8)
			w.Speed = NumberRange.new(1, 2.5)
			w.Acceleration = Vector3.new(0, 4, 0)
		end
		if k.halo and head then
			local ring = Instance.new("Part")
			ring.Name = "Halo"; ring.Shape = Enum.PartType.Cylinder
			ring.Size = Vector3.new(0.04, 0.7, 0.7); ring.Material = Enum.Material.Neon; ring.Color = k.light
			ring.Anchored = head.Anchored; ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.Massless = false, false, false, true
			ring.Transparency = 0.25
			ring.CFrame = shaft.CFrame * CFrame.new(0, 0, -shaft.Size.Z * 0.2) * CFrame.Angles(0, math.pi / 2, 0)
			ring.Parent = shaft.Parent
			local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = shaft, ring; w.Parent = ring
			if shaft.Anchored then
				-- (the client's flying arrow is anchored and moved by CFrame: carry the halo along)
				ring.Anchored = false
				ring:SetAttribute("FollowShaft", true)
			end
		end
	else
		-- left standing: it smoulders a while, then goes quiet
		local e = emitter(tip, k, 0.35)
		task.delay(3, function() if e.Parent then e.Enabled = false end end)
	end
	local l = Instance.new("PointLight")
	l.Color = k.light
	l.Range = opts.stuck and 5 or 10
	l.Brightness = opts.stuck and 0.8 or 1.8
	l.Parent = shaft
	if opts.stuck then task.delay(3, function() if l.Parent then l:Destroy() end end) end
	if k.flicker and not opts.stuck then
		task.spawn(function()
			while l.Parent do
				l.Brightness = 0.6 + math.random() * 3
				task.wait(0.04 + math.random() * 0.06)
			end
		end)
	end
end

--------------------------------------------------------------------
--  IMPACTS
--------------------------------------------------------------------
local function speck(position, parent, life)
	local holder = Instance.new("Part")
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.1
	holder.CFrame = CFrame.new(position)
	holder.Parent = parent or workspace
	Debris:AddItem(holder, life or 1.5)
	return holder
end
local function fx(part, props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	for k, v in pairs(props) do p[k] = v end
	return p
end
local function fade(p, t, goal)
	goal = goal or {}
	goal.Transparency = 1
	TweenService:Create(p, TweenInfo.new(t), goal):Play()
	Debris:AddItem(p, t + 0.1)
end

local IMPACT = {}
-- a fire that keeps burning a moment where it landed
IMPACT.fire = function(pos, k, parent)
	local h = speck(pos, parent, 2.6)
	local f = Instance.new("Fire"); f.Size = 3; f.Heat = 6; f.Color = k.trail; f.SecondaryColor = k.head; f.Parent = h
	task.delay(1.8, function() if f.Parent then f.Enabled = false end end)
end
-- ice shards flying out and falling
IMPACT.shards = function(pos, k, parent)
	for i = 1, 7 do
		local s = fx(nil, {Size = Vector3.new(0.12, 0.12, math.random() * 0.5 + 0.3), Color = k.head, Material = Enum.Material.Glass, Transparency = 0.2,
			CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)})
		s.Parent = parent or workspace
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.2, math.random() - 0.5).Unit
		TweenService:Create(s, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = s.CFrame + dir * (1.5 + math.random() * 2)}):Play()
		task.delay(0.35, function() if s.Parent then fade(s, 0.4) end end)
	end
end
-- a bolt of lightning down from the sky onto it, and a flash
IMPACT.bolt = function(pos, k, parent)
	local top = pos + Vector3.new(math.random(-4, 4), 40, math.random(-4, 4))
	local prev = top
	for i = 1, 7 do
		local f = i / 7
		local nxt = i == 7 and pos or top:Lerp(pos, f) + Vector3.new(math.random() * 3 - 1.5, 0, math.random() * 3 - 1.5)
		local seg = fx(nil, {Size = Vector3.new(0.25, 0.25, (nxt - prev).Magnitude), Color = k.head, CFrame = CFrame.lookAt((prev + nxt) / 2, nxt)})
		seg.Parent = parent or workspace
		fade(seg, 0.35)
		prev = nxt
	end
	local h = speck(pos, parent, 0.5)
	local l = Instance.new("PointLight"); l.Color = k.light; l.Range = 30; l.Brightness = 6; l.Parent = h
end
-- a pillar of light rising from it
IMPACT.pillar = function(pos, k, parent)
	local p = fx(nil, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(16, 1.6, 1.6), Color = k.light, Transparency = 0.3,
		CFrame = CFrame.new(pos + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.pi / 2)})
	p.Parent = parent or workspace
	fade(p, 0.9, {Size = Vector3.new(20, 0.2, 0.2)})
end
-- the light drawn in: a dark sphere shrinking to nothing
IMPACT.implode = function(pos, k, parent)
	local b = fx(nil, {Shape = Enum.PartType.Ball, Size = Vector3.one * 4, Color = k.head, Material = Enum.Material.ForceField, Transparency = 0.1, CFrame = CFrame.new(pos)})
	b.Parent = parent or workspace
	TweenService:Create(b, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = Vector3.one * 0.1}):Play()
	Debris:AddItem(b, 0.5)
end
-- a red splash on the ground
IMPACT.splatter = function(pos, k, parent)
	for i = 1, 5 do
		local d = fx(nil, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.05, 0.6 + math.random(), 0.6 + math.random()), Color = k.head, Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(pos + Vector3.new(math.random() * 2 - 1, -0.3, math.random() * 2 - 1)) * CFrame.Angles(0, 0, math.pi / 2)})
		d.Parent = parent or workspace
		task.delay(2, function() if d.Parent then fade(d, 1) end end)
	end
end
-- a cloud of poison that hangs there a moment
IMPACT.cloud = function(pos, k, parent)
	local h = speck(pos, parent, 4)
	local a = Instance.new("Attachment"); a.Parent = h
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX.smoke; e.Color = ColorSequence.new(k.trail, C(40, 90, 20)); e.Size = NumberSequence.new(2, 4)
	e.Transparency = NumberSequence.new(0.5, 1); e.Lifetime = NumberRange.new(2, 3); e.Speed = NumberRange.new(0.3, 1)
	e.SpreadAngle = Vector2.new(180, 180); e.Rate = 12; e.Parent = a
	task.delay(1.5, function() if e.Parent then e.Enabled = false end end)
end
-- a fountain of gold sparks
IMPACT.fountain = function(pos, k, parent)
	local h = speck(pos, parent, 2)
	local a = Instance.new("Attachment"); a.Parent = h
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX.spark; e.Color = ColorSequence.new(C(255, 240, 160), C(255, 180, 40)); e.Size = NumberSequence.new(0.35, 0)
	e.Lifetime = NumberRange.new(0.8, 1.2); e.Speed = NumberRange.new(8, 14); e.SpreadAngle = Vector2.new(25, 25)
	e.EmissionDirection = Enum.NormalId.Top; e.Acceleration = Vector3.new(0, -30, 0); e.LightEmission = 1; e.Rate = 0; e.Parent = a
	e:Emit(40)
end
-- spirits rising out of it
IMPACT.wisps = function(pos, k, parent)
	for i = 1, 4 do
		local w = fx(nil, {Shape = Enum.PartType.Ball, Size = Vector3.one * 0.5, Color = k.light, Transparency = 0.2, CFrame = CFrame.new(pos)})
		w.Parent = parent or workspace
		local goal = pos + Vector3.new(math.random() * 4 - 2, 5 + math.random() * 3, math.random() * 4 - 2)
		TweenService:Create(w, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {CFrame = CFrame.new(goal), Size = Vector3.one * 0.1, Transparency = 1}):Play()
		Debris:AddItem(w, 1.5)
	end
end

-- the impact: a burst of the kind's particles, a flash, and its own effect
function ArrowFX.burst(position, kind, parent)
	local k = kind and ArrowFX.KINDS[kind]
	if not k then return end
	local holder = speck(position, parent, 1.5)
	local a = Instance.new("Attachment"); a.Parent = holder
	local e = emitter(a, k, 1.4)
	e.Speed = NumberRange.new(k.burst[2] * 0.4, k.burst[2])
	e.Enabled = false
	e:Emit(k.burst[1])
	local l = Instance.new("PointLight"); l.Color = k.light; l.Range = 14; l.Brightness = 4; l.Parent = holder
	task.delay(0.15, function() if l.Parent then l.Brightness = 1 end end)
	local f = k.impact and IMPACT[k.impact]
	if f then pcall(f, position, k, parent) end
end

return ArrowFX
