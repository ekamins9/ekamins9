--[[ SHADE (client) — draws what Game ▸ Shade sends for a party that lingers in The Depths, from
     the Round node's ShadeState / ShadePos / ShadeHit:
       stir   a breath far off in the dark (TorchFlicker sputters every torch on the floor)
       hunt   a tall hooded figure drifts at you through the walls: no face under the hood but two
              pale eyes, long arms that lift and reach as it closes, its hem trailing into smoke.
              Its breath and whispers come with it (WarAudio ▸ ShadeBreath, Whisper); near it the
              world drains of colour, your heart pounds (WarAudio ▸ Heartbeat), the view trembles,
              and the torches round it gutter low (TorchFlicker)
       wait   the same, held outside the walls of the room you're fighting in
       back   it sinks into the dark after a touch, and comes again from somewhere else
     A touch (ShadeHit): a cold flash and its shriek; if it was you, your ears ring (Hearing).
     Nothing here is sent to the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local Hearing = require(ReplicatedStorage:WaitForChild("Hearing"))
local round = ReplicatedStorage:WaitForChild("Round")
local player = Players.LocalPlayer

local V3, CF = Vector3.new, CFrame.new
local ROBE = Color3.fromRGB(32, 32, 40)   -- (not quite black: a shape against the dark)
local HAND = Color3.fromRGB(150, 158, 172)
local EYE = Color3.fromRGB(205, 225, 255)

local fig = nil        -- the figure while it's about
local grade = nil      -- the colour drained near it
local heart = nil      -- your heartbeat
local kNear = 0

local function myRoot()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function part(model, name, size, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size, p.Color, p.Material = size, color, mat or Enum.Material.Fabric
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	if shape then p.Shape = shape end
	p.Parent = model
	return p
end

local function emitter(at, props)
	local e = Instance.new("ParticleEmitter")
	for k, v in pairs(props) do e[k] = v end
	e.Parent = at
	return e
end

local function build(at)
	local m = Instance.new("Model")
	m.Name = "Shade"
	local f = {model = m, list = {}, pos = at, yaw = 0, alpha = 0, twitch = 0, twitchAt = os.clock() + 3}
	local function add(name, size, color, mat, base, rel, shape)
		local p = part(m, name, size, color, mat, shape ~= "round" and shape or nil)
		if shape == "round" then
			local sm = Instance.new("SpecialMesh"); sm.MeshType = Enum.MeshType.Sphere; sm.Parent = p
		end
		p.Transparency = 1
		local e = {p = p, base = base or 0, rel = rel}
		table.insert(f.list, e)
		f[name] = e
		return e
	end
	-- the robe: shoulders to a hem that frays into nothing
	-- (a deep cowl, its peak drawn back, and the dark hollow where a face should be)
	add("Hood", V3(2.3, 2.7, 2.5), ROBE, nil, 0.02, nil, "round")
	add("Peak", V3(1.5, 2.1, 1.7), ROBE, nil, 0.02, nil, "round")
	add("Void", V3(1.45, 1.8, 0.7), Color3.fromRGB(2, 2, 3), Enum.Material.SmoothPlastic, 0, nil, "round")
	add("EyeL", V3(0.22, 0.22, 0.22), EYE, Enum.Material.Neon, 0, nil, Enum.PartType.Ball)
	add("EyeR", V3(0.22, 0.22, 0.22), EYE, Enum.Material.Neon, 0, nil, Enum.PartType.Ball)
	-- (a bell of a robe: round, widening to the hem; cylinders stood on end)
	add("Shoulders", V3(2.6, 2.8, 2.8), ROBE, nil, 0.04, nil, Enum.PartType.Cylinder)
	add("Waist", V3(2.4, 3.2, 3.2), ROBE, nil, 0.1, nil, Enum.PartType.Cylinder)
	add("Hem", V3(2.4, 3.9, 3.9), ROBE, nil, 0.3, nil, Enum.PartType.Cylinder)
	f.tatters = {}
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local t = add("Tatter" .. i, V3(0.55, 2.8, 0.06), ROBE, nil, 0.35)
		t.a, t.ph = a, math.random() * 6
		table.insert(f.tatters, t)
	end
	-- long arms in their sleeves, gaunt grey hands
	for _, s in ipairs({"L", "R"}) do
		add("Upper" .. s, V3(0.6, 2.8, 0.6), ROBE, nil, 0.05)
		add("Fore" .. s, V3(0.5, 2.5, 0.5), ROBE, nil, 0.05)
		add("Hand" .. s, V3(0.42, 0.5, 0.2), HAND, Enum.Material.SmoothPlastic, 0)
		for i = 1, 4 do add("Finger" .. s .. i, V3(0.08, 1.1, 0.08), HAND, Enum.Material.SmoothPlastic, 0) end
	end
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = EYE, 12, 0, false
	light.Parent = f.EyeL.p
	f.light = light
	-- (smoke off its hem, and pale wisps)
	-- (the hem stands on end: its part's own -X is down)
	local hem = Instance.new("Attachment"); hem.Position = V3(-1.2, 0, 0); hem.Parent = f.Hem.p
	f.smoke = emitter(hem, {Color = ColorSequence.new(Color3.fromRGB(16, 16, 20)), LightInfluence = 1,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 4.2)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.4), NumberSequenceKeypoint.new(1, 1)}),
		Lifetime = NumberRange.new(1.6, 2.6), Rate = 0, Speed = NumberRange.new(0.5, 1.6), SpreadAngle = Vector2.new(180, 40),
		Acceleration = V3(0, 0.7, 0), Drag = 1.4, RotSpeed = NumberRange.new(-30, 30), Rotation = NumberRange.new(0, 360)})
	f.wisps = emitter(hem, {Color = ColorSequence.new(Color3.fromRGB(176, 188, 214)), LightEmission = 0.3, LightInfluence = 0.4,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.4)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.7), NumberSequenceKeypoint.new(1, 1)}),
		Lifetime = NumberRange.new(1.2, 2), Rate = 0, Speed = NumberRange.new(0.3, 1), SpreadAngle = Vector2.new(180, 180),
		Acceleration = V3(0, 1.2, 0)})
	m.Parent = workspace
	-- its breath and whispers go where it goes
	f.breath = WarFX.loop3D("ShadeBreath", at, {near = 8, range = 90, volume = 1})
	f.whisper = WarFX.loop3D("Whisper", at, {near = 6, range = 50, volume = 0.7})
	return f
end

local function unbuild()
	if not fig then return end
	if fig.breath then fig.breath.stop(1.5) end
	if fig.whisper then fig.whisper.stop(1.5) end
	fig.model:Destroy()
	fig = nil
end

-- the figure's pose this frame: its whole body from where it is, which way it faces, and how far
-- its arms reach for you (0 hanging, 1 outstretched)
local parts, cfs = {}, {}
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)   -- (a cylinder stood on end)
local function pose(f, root, reach, now)
	table.clear(parts); table.clear(cfs)
	local function put(e, cf) table.insert(parts, e.p); table.insert(cfs, cf) end
	local head = root * CF(0, 3.4, 0.1) * CFrame.Angles(-0.2, f.twitch, math.sin(now * 0.6) * 0.06 + reach * 0.22)
	put(f.Hood, head)
	put(f.Peak, head * CF(0, 1.05, 0.55) * CFrame.Angles(-0.55, 0, 0))
	put(f.Void, head * CF(0, -0.15, -0.95))
	put(f.EyeL, head * CF(-0.3, -0.05, -1.25))
	put(f.EyeR, head * CF(0.3, -0.05, -1.25))
	put(f.Shoulders, root * CF(0, 1.4, 0.15) * UPRIGHT)
	put(f.Waist, root * CF(0, -0.9, 0.25) * CFrame.Angles(0.05, 0, 0) * UPRIGHT)
	put(f.Hem, root * CF(0, -3.1, 0.35) * CFrame.Angles(0.1, 0, math.sin(now * 0.8) * 0.04) * UPRIGHT)
	for _, t in ipairs(f.tatters) do
		local sway = math.sin(now * 1.7 + t.ph) * 0.25
		put(t, root * CF(math.cos(t.a) * 1.9, -4.6, 0.35 + math.sin(t.a) * 1.2) * CFrame.Angles(0, -t.a, 0) * CF(0, 1.4, 0) * CFrame.Angles(sway + 0.12, 0, 0) * CF(0, -1.4, 0))
	end
	for i, s in ipairs({"L", "R"}) do
		local side = i == 1 and -1 or 1
		-- (hanging, a little forward; reaching, up and out toward you, the hands half-open)
		local lift = 0.15 + reach * 1.3 + math.sin(now * 1.1 + i) * 0.05
		local out = side * (0.08 + reach * 0.12)
		local sh = root * CF(side * 1.62, 2.4, 0) * CFrame.Angles(lift, 0, out)
		put(f["Upper" .. s], sh * CF(0, -1.4, 0))
		local el = sh * CF(0, -2.7, 0) * CFrame.Angles(0.25 + reach * 0.2, 0, 0)
		put(f["Fore" .. s], el * CF(0, -1.25, 0))
		local wr = el * CF(0, -2.5, 0)
		put(f["Hand" .. s], wr * CF(0, -0.2, 0))
		for k = 1, 4 do
			local spread = (k - 2.5) * (0.12 + reach * 0.1)
			put(f["Finger" .. s .. k], wr * CF((k - 2.5) * 0.1, -0.35, 0) * CFrame.Angles(0.15 + reach * 0.3, 0, spread) * CF(0, -0.55, 0))
		end
	end
	workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

local function setAlpha(f, a)
	for _, e in ipairs(f.list) do e.p.Transparency = e.base + (1 - e.base) * (1 - a) end
	f.light.Brightness = 1.3 * a
	f.smoke.Rate = a > 0.3 and 26 or 0
	f.wisps.Rate = a > 0.3 and 5 or 0
end

local function heartSound()
	if heart and heart.Parent then return heart end
	local src = ReplicatedStorage:FindFirstChild("WarAudio") and ReplicatedStorage.WarAudio:FindFirstChild("Heartbeat")
	if not (src and src:IsA("Sound")) then return nil end
	heart = src:Clone()
	heart.Name = "ShadeHeart"
	heart.Looped, heart.Volume = true, 0
	heart:SetAttribute("Base", src.Volume)
	heart.Parent = SoundService
	heart:Play()
	return heart
end

local shakeAcc = 0
RunService.RenderStepped:Connect(function(dt)
	local state = round:GetAttribute("ShadeState")
	local target = round:GetAttribute("ShadePos")
	local now = os.clock()
	local about = (state == "hunt" or state == "wait" or state == "back") and typeof(target) == "Vector3"
	if about and not fig then fig = build(target) end
	local r = myRoot()
	local k = 0
	if fig then
		-- (back in the dark: it fades, and comes again from wherever it is next)
		local want = (state == "hunt" or state == "wait") and 1 or 0
		if want == 1 and fig.alpha <= 0.02 then fig.pos = target end
		-- (it sinks away where it stood: no sliding off to its next place)
		if about and want == 1 then fig.pos = fig.pos:Lerp(target, 1 - math.exp(-dt * 6)) end
		fig.alpha = math.clamp(fig.alpha + (want - fig.alpha) * math.min(1, dt * (want == 1 and 2.5 or 4)), 0, 1)
		if not about and fig.alpha < 0.02 then unbuild() end
	end
	if fig then
		local me = r and r.Position or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position)
		local d = me and (me - fig.pos).Magnitude or 1e9
		-- (it faces you once you're near; otherwise the way it drifts)
		local look = me and d < 90 and V3(me.X - fig.pos.X, 0, me.Z - fig.pos.Z) or nil
		if look and look.Magnitude > 0.1 then
			local yaw = math.atan2(-look.X, -look.Z)
			local dy = (yaw - fig.yaw + math.pi) % (2 * math.pi) - math.pi
			fig.yaw += dy * math.min(1, dt * 3)
		end
		-- (now and then its head jerks aside)
		if now > fig.twitchAt then
			fig.twitch = (math.random() - 0.5) * 0.7
			fig.twitchAt = now + 2 + math.random() * 4
			task.delay(0.12 + math.random() * 0.1, function() if fig then fig.twitch = 0 end end)
		end
		local reach = math.clamp((14 - d) / 10, 0, 1)
		local root = CF(fig.pos + V3(0, math.sin(now * 1.3) * 0.35, 0)) * CFrame.Angles(0, fig.yaw, 0) * CFrame.Angles(-0.06 - reach * 0.1, 0, math.sin(now * 0.7) * 0.04)
		pose(fig, root, reach, now)
		setAlpha(fig, fig.alpha)
		if fig.breath then fig.breath.move(fig.pos) end
		if fig.whisper then fig.whisper.move(fig.pos) end
		if state ~= "back" then k = math.clamp((44 - d) / 36, 0, 1) * fig.alpha end
		-- (close: the view trembles)
		shakeAcc += dt
		if d < 10 and shakeAcc > 0.25 and fig.alpha > 0.5 then
			shakeAcc = 0
			WarFX.shake(0.22 * (1 - d / 10), 0.35)
		end
	end
	-- the world drains of colour near it, and your heart pounds
	kNear += (k - kNear) * math.min(1, dt * 2)
	if kNear > 0.005 then
		if not (grade and grade.Parent) then
			grade = Instance.new("ColorCorrectionEffect")
			grade.Name = "ShadeGrade"
			grade.Parent = Lighting
		end
		grade.Saturation = -0.7 * kNear
		grade.Brightness = -0.06 * kNear
		grade.Contrast = 0.14 * kNear
		grade.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(196, 212, 255), kNear)
		local h = heartSound()
		if h then
			h.Volume = (h:GetAttribute("Base") or 0.5) * math.min(1, kNear * 1.3)
			h.PlaybackSpeed = 0.85 + 0.6 * kNear
		end
	elseif grade then
		grade:Destroy(); grade = nil
		if heart then heart:Destroy(); heart = nil end
	end
end)

-- THE DARK STIRS: a breath far off, and a low cry
round:GetAttributeChangedSignal("ShadeState"):Connect(function()
	if round:GetAttribute("ShadeState") == "stir" then
		WarFX.sound("ShadeBreath", nil, {volume = 0.55, speed = 0.8})
		task.delay(1.2, function() WarFX.sound("Wail", nil, {volume = 0.22, speed = 0.5}) end)
	end
end)

-- a touch: its shriek where it was, and on you, the cold
round:GetAttributeChangedSignal("ShadeHit"):Connect(function()
	local at = round:GetAttribute("ShadeHitPos")
	if typeof(at) ~= "Vector3" then return end
	WarFX.sound("Wail", at, {volume = 0.9, speed = 0.75, near = 12, range = 120})
	local r = myRoot()
	if r and (r.Position - at).Magnitude < 7 then
		WarFX.flash(0.5)
		WarFX.shake(1.1, 0.8)
		Hearing.ring(0.6, 3)
	end
end)
