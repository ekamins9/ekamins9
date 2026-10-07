--[[ ARROW FX — what a bow or crossbow skin does to its arrows (Catalog ▸ Skins
     `arrow = "<kind>"`). The arrow in flight wears it (ArrowFlight: a coloured
     trail, a glowing head, particles streaming off it, a light), it bursts where
     it lands, and an arrow left standing smoulders a moment (RangedServer).

       ArrowFX.decorate(shaft, head, kind, opts)   a flying (or stuck) arrow; opts.stuck
       ArrowFX.burst(position, kind, parent)       the impact
       ArrowFX.KINDS[kind].name                    "Fire Arrows" (menus)

     Kinds: fire frost shadow holy storm toxic gold blood ]]

local Debris = game:GetService("Debris")

local ArrowFX = {}
local C = Color3.fromRGB
local TEX = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
}

-- trail, head (glowing), light, the particles off it (tex, two colours, size,
-- rate, lifetime, drift), the burst on landing (count, speed)
ArrowFX.KINDS = {
	fire   = {name = "Fire Arrows",   trail = C(255, 150, 50),  head = C(255, 120, 30),  light = C(255, 140, 50),
		p = {TEX.fire, C(255, 210, 90), C(255, 60, 20), 0.7, 45, 0.35, Vector3.new(0, 5, 0)}, burst = {28, 10}},
	frost  = {name = "Frost Arrows",  trail = C(170, 230, 255), head = C(210, 245, 255), light = C(150, 220, 255),
		p = {TEX.spark, C(240, 252, 255), C(130, 200, 255), 0.35, 30, 0.6, Vector3.new(0, -3, 0)}, burst = {24, 8}},
	shadow = {name = "Shadow Arrows", trail = C(120, 50, 190),  head = C(70, 20, 110),   light = C(140, 60, 220),
		p = {TEX.smoke, C(80, 30, 120), C(10, 0, 20), 0.8, 25, 0.7, Vector3.new(0, 1, 0)}, burst = {20, 6}},
	holy   = {name = "Holy Arrows",   trail = C(255, 240, 170), head = C(255, 236, 150), light = C(255, 230, 150),
		p = {TEX.spark, C(255, 250, 220), C(255, 210, 110), 0.4, 35, 0.5, Vector3.new(0, 2, 0)}, burst = {30, 9}},
	storm  = {name = "Storm Arrows",  trail = C(150, 210, 255), head = C(200, 235, 255), light = C(150, 210, 255),
		p = {TEX.spark, C(230, 245, 255), C(90, 160, 255), 0.45, 50, 0.2, Vector3.zero}, burst = {36, 18}},
	toxic  = {name = "Venom Arrows",  trail = C(130, 255, 90),  head = C(110, 230, 70),  light = C(120, 255, 90),
		p = {TEX.smoke, C(140, 255, 100), C(40, 90, 20), 0.6, 25, 0.7, Vector3.new(0, -1, 0)}, burst = {22, 5}},
	gold   = {name = "Gilded Arrows", trail = C(255, 205, 80),  head = C(255, 200, 70),  light = C(255, 200, 90),
		p = {TEX.spark, C(255, 240, 160), C(255, 180, 40), 0.35, 30, 0.5, Vector3.new(0, -2, 0)}, burst = {26, 9}},
	blood  = {name = "Blood Arrows",  trail = C(190, 20, 30),   head = C(150, 10, 20),   light = C(200, 30, 40),
		p = {TEX.smoke, C(170, 20, 30), C(60, 0, 5), 0.45, 25, 0.55, Vector3.new(0, -4, 0)}, burst = {24, 7}},
}

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
	e.LightEmission = 0.8
	e.Parent = parent
	return e
end

function ArrowFX.decorate(shaft, head, kind, opts)
	local k = kind and ArrowFX.KINDS[kind]
	if not (k and shaft) then return end
	opts = opts or {}
	if head then
		head.Color = k.head
		head.Material = Enum.Material.Neon
	end
	local tail = Instance.new("Attachment"); tail.Position = Vector3.new(0, 0, shaft.Size.Z / 2); tail.Parent = shaft
	local tip = Instance.new("Attachment"); tip.Position = Vector3.new(0, 0, -shaft.Size.Z / 2); tip.Parent = shaft
	if not opts.stuck then
		-- a wide coloured trail behind it, on top of the plain streak
		local up = Instance.new("Attachment"); up.Position = Vector3.new(0, 0.18, 0); up.Parent = shaft
		local down = Instance.new("Attachment"); down.Position = Vector3.new(0, -0.18, 0); down.Parent = shaft
		local t = Instance.new("Trail")
		t.Attachment0, t.Attachment1 = up, down
		t.Lifetime = 0.35
		t.Color = ColorSequence.new(k.trail)
		t.Transparency = NumberSequence.new(0.2, 1)
		t.LightEmission = 1
		t.FaceCamera = true
		t.Parent = shaft
		emitter(tip, k, 1)
	else
		-- left standing: it smoulders a while, then goes quiet
		local e = emitter(tip, k, 0.35)
		task.delay(3, function() if e.Parent then e.Enabled = false end end)
	end
	local l = Instance.new("PointLight")
	l.Color = k.light
	l.Range = opts.stuck and 5 or 9
	l.Brightness = opts.stuck and 0.8 or 1.6
	l.Parent = shaft
	if opts.stuck then task.delay(3, function() if l.Parent then l:Destroy() end end) end
end

-- the impact: a burst of the kind's particles
function ArrowFX.burst(position, kind, parent)
	local k = kind and ArrowFX.KINDS[kind]
	if not k then return end
	local holder = Instance.new("Part")
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.1
	holder.CFrame = CFrame.new(position)
	holder.Parent = parent or workspace
	local a = Instance.new("Attachment"); a.Parent = holder
	local e = emitter(a, k, 1.4)
	e.Speed = NumberRange.new(k.burst[2] * 0.4, k.burst[2])
	e.Enabled = false
	e:Emit(k.burst[1])
	local l = Instance.new("PointLight"); l.Color = k.light; l.Range = 12; l.Brightness = 3; l.Parent = holder
	task.delay(0.15, function() if l.Parent then l.Brightness = 1 end end)
	Debris:AddItem(holder, 1.5)
end

return ArrowFX
