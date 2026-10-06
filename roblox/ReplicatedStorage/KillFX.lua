--[[ KILL FX — what happens to the body when YOU land the killing blow
     (Catalog ▸ KillFX lists them, the player equips one). Built mostly from
     parts that fly, spin, grow and fade, so the same effect plays in the
     world (every client runs it) and inside a menu ViewportFrame (the
     preview); particles and lights are extras that only the world shows.

       KillFX.play(id, container, origin, opts) -> duration
           container   a Folder / Model / WorldModel to build in
           origin      CFrame at the victim's torso
           opts.body   the victim's BaseParts (hidden / tinted by some effects);
                       body.direct = true hides them for real (a menu preview's
                       own rig, where LocalTransparencyModifier may not show)
           opts.world  true in the world (adds particles, lights, sounds)
           opts.sound  true: sounds in a preview too (the menu's first play)
           opts.freezeAt  0..1: build the effect frozen at that moment (tests)
       KillFX.IDS      every effect id

     Effects only touch the body locally (LocalTransparencyModifier, a local
     colour), so a kill never changes what the server sees. ]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local KillFX = {}
local M = Enum.Material
local rng = Random.new()

--------------------------------------------------------------------
--  HELPERS
--------------------------------------------------------------------
local function part(folder, shape, size, cf, color, mat, transp)
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or M.SmoothPlastic
	p.Transparency = transp or 0
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.CastShadow = false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end
local function wedgePart(folder, size, cf, color, mat)
	local p = Instance.new("WedgePart")
	p.Size = size; p.CFrame = cf; p.Color = color; p.Material = mat or M.SmoothPlastic
	p.Anchored = true; p.CanCollide, p.CanQuery, p.CanTouch = false, false, false; p.CastShadow = false
	p.Parent = folder
	return p
end

-- run step(alpha, dt) every frame for `duration` seconds (or once, frozen)
local function animate(duration, opts, step, done)
	if opts.freezeAt then step(opts.freezeAt, 1 / 60); return end
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local a = (os.clock() - t0) / duration
		if a >= 1 then
			conn:Disconnect()
			step(1, dt)
			if done then done() end
			return
		end
		step(a, dt)
	end)
end

-- debris: bits that fly out with a velocity and spin, fall with gravity, fade
local function debris(folder, origin, n, make, o)
	local bits = {}
	for i = 1, n do
		local p = make(i)
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(o.upMin or 0.2, o.upMax or 1), rng:NextNumber(-1, 1))
		if dir.Magnitude < 0.05 then dir = Vector3.yAxis end
		table.insert(bits, {p = p, pos = origin.Position + (o.spawnSpread and Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1.5, 1.5), rng:NextNumber(-1, 1)) * o.spawnSpread or Vector3.zero),
			vel = dir.Unit * rng:NextNumber(o.speedMin or 6, o.speedMax or 14),
			rot = CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28)),
			spin = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8)),
			t0 = p.Transparency})
	end
	return bits
end
local function stepDebris(bits, a, dt, o, duration)
	local g = o.gravity or 30
	-- integrate from the start every frame (so a frozen frame matches a played one)
	local t = a * duration
	for _, b in ipairs(bits) do
		local pos = b.pos + b.vel * t + Vector3.new(0, -0.5 * g * t * t, 0)
		if o.floor and pos.Y < o.floor then pos = Vector3.new(pos.X, o.floor, pos.Z) end
		local r = b.rot * CFrame.Angles(b.spin.X * t, b.spin.Y * t, b.spin.Z * t)
		b.p.CFrame = CFrame.new(pos) * r
		b.p.Transparency = b.t0 + (1 - b.t0) * math.clamp((a - (o.fadeFrom or 0.6)) / (1 - (o.fadeFrom or 0.6)), 0, 1)
	end
end

-- hide one body part / decal (0 = as it was, 1 = gone)
local function hide(p, f, body)
	if not (p.Parent and (p:IsA("BasePart") or p:IsA("Decal"))) then return end
	if body and body.direct then
		local t0 = p:GetAttribute("FxT0")
		if t0 == nil then t0 = p.Transparency; p:SetAttribute("FxT0", t0) end
		p.Transparency = t0 + (1 - t0) * f
	else
		p.LocalTransparencyModifier = f
	end
end
-- hide the victim's body (locally) over time; tint it first
local function bodyFade(body, a, from, to)
	if not body then return end
	local f = math.clamp((a - from) / (to - from), 0, 1)
	for _, p in ipairs(body) do hide(p, f, body) end
end
local function bodyTint(body, color, mat)
	if not body then return end
	for _, p in ipairs(body) do
		if p:IsA("BasePart") and p.Parent then
			p:SetAttribute("FxOldColor", p:GetAttribute("FxOldColor") or p.Color)
			p.Color = color
			if mat then p.Material = mat end
		end
	end
end
local function bodyColors(body)
	local cols = {}
	for _, p in ipairs(body or {}) do
		if p:IsA("BasePart") and p.Transparency < 1 then table.insert(cols, p.Color) end
	end
	if #cols == 0 then cols = {Color3.fromRGB(160, 160, 170), Color3.fromRGB(120, 90, 60)} end
	return cols
end

local function flash(folder, origin, color, r, a)
	local s = part(folder, Enum.PartType.Ball, Vector3.one * (0.5 + r * a), origin, color, M.Neon, 0.2 + 0.8 * a)
	return s
end
local function ring(folder, cf, r, thick, color, mat, transp)
	local p = part(folder, Enum.PartType.Cylinder, Vector3.new(thick, r * 2, r * 2), cf * CFrame.Angles(0, 0, math.pi / 2), color, mat or M.Neon, transp)
	return p
end
local function emit(at, folder, props)
	local holder = part(folder, Enum.PartType.Block, Vector3.one * 0.1, at, Color3.new(), M.SmoothPlastic, 1)
	local att = Instance.new("Attachment")
	att.Parent = holder
	local pe = Instance.new("ParticleEmitter")
	for k, v in pairs(props) do pe[k] = v end
	pe.Enabled = false
	pe.Parent = att
	pe:Emit(props.Rate or 30)
	return pe
end
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- SOUNDS (world only, or a preview asked for them with opts.sound): Roblox's
-- licensed libraries (Pro Sound Effects, APM Music), so they play anywhere
local SND = {
	rockBurst = 9114221862, glassBreak = 9114592102, glassShatter = 9114592245, iceCrack = 9118762653,
	zap = 9119594928, thunder = 9126099928, wings = 9125386714, raven = 9118066014,
	choir = 1846902441, fanfare = 9042409054, pop = 9113263649, fireWhoosh = 9120696702,
	rift = 9120706422, synthRip = 9119805147, swish = 9120726501, shells = 9119117331, shellsLong = 9119117098,
}
-- a sound at `at`: o.delay before it starts, o.cut seconds in it fades out over o.fade,
-- o.from starts it part-way in. It lives beside the effect (which may end sooner).
local function sfx(folder, opts, at, id, o)
	if not (opts.world or opts.sound) or opts.freezeAt then return end
	o = o or {}
	local holder
	if opts.world then
		-- in the world: from the body, fading with distance
		holder = Instance.new("Part")
		holder.Name = "KillSound"
		holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
		holder.Transparency = 1
		holder.Size = Vector3.one * 0.1
		holder.CFrame = CFrame.new(typeof(at) == "CFrame" and at.Position or at)
		holder.Parent = folder.Parent or folder
	else
		-- a menu preview (a ViewportFrame can't carry a sound): flat, a little quieter
		holder = Instance.new("Folder")
		holder.Name = "KillSound"
		holder.Parent = game:GetService("SoundService")
	end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = (o.volume or 0.8) * (opts.world and 1 or 0.6)
	s.PlaybackSpeed = (o.speed or 1) * rng:NextNumber(0.97, 1.03)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = o.near or 12
	s.RollOffMaxDistance = o.far or 160
	s.TimePosition = o.from or 0
	s.Parent = holder
	local life = (o.delay or 0) + (o.cut and (o.cut + (o.fade or 0.4)) or 8) + 0.3
	task.delay(o.delay or 0, function()
		if not s.Parent then return end
		s:Play()
		if o.cut then
			task.delay(o.cut, function()
				if s.Parent then TweenService:Create(s, TweenInfo.new(o.fade or 0.4), {Volume = 0}):Play() end
			end)
		end
	end)
	task.delay(life, function() if holder.Parent then holder:Destroy() end end)
	return s
end

--------------------------------------------------------------------
--  THE EFFECTS: function(folder, origin, opts) -> duration
--------------------------------------------------------------------
local FX = {}

-- the body bursts into blocks of its own colours
FX.Shatter = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.rockBurst, {volume = 0.9, speed = 1.15, cut = 1.4, fade = 0.5})
	sfx(folder, opts, origin, SND.glassBreak, {volume = 0.45, speed = 0.75})
	local cols = bodyColors(opts.body)
	local floor = origin.Position.Y - 3
	local bits = debris(folder, origin, 22, function(i)
		local s = rng:NextNumber(0.3, 0.7)
		return part(folder, Enum.PartType.Block, Vector3.new(s, s, s), origin, cols[(i - 1) % #cols + 1], M.SmoothPlastic)
	end, {speedMin = 5, speedMax = 12, upMin = 0.1, upMax = 0.9, spawnSpread = 0.7, floor = floor, fadeFrom = 0.7})
	local D = 1.6
	animate(D, opts, function(a, dt)
		stepDebris(bits, a, dt, {gravity = 28, floor = floor, fadeFrom = 0.7}, D)
		bodyFade(opts.body, a, 0, 0.05)
	end)
	return D
end

-- a pop and a cloud of spinning confetti
FX.Confetti = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.pop, {volume = 1, speed = 0.85})
	sfx(folder, opts, origin, SND.pop, {volume = 0.7, speed = 1.25, delay = 0.06})
	sfx(folder, opts, origin, SND.swish, {volume = 0.35, speed = 1.6, cut = 0.9})
	local palette = {Color3.fromRGB(255, 80, 90), Color3.fromRGB(255, 210, 60), Color3.fromRGB(80, 200, 120), Color3.fromRGB(70, 150, 255), Color3.fromRGB(200, 100, 255), Color3.fromRGB(255, 150, 60)}
	local bits = debris(folder, origin, 40, function(i)
		return part(folder, Enum.PartType.Block, Vector3.new(0.35, 0.05, 0.22), origin, palette[(i - 1) % #palette + 1], M.SmoothPlastic)
	end, {speedMin = 8, speedMax = 16, upMin = 0.4, upMax = 1.2})
	local pop = part(folder, Enum.PartType.Ball, Vector3.one, origin, Color3.fromRGB(255, 255, 255), M.Neon, 0.3)
	local D = 2
	animate(D, opts, function(a, dt)
		stepDebris(bits, a, dt, {gravity = 9, fadeFrom = 0.75}, D)
		local pa = math.clamp(a / 0.15, 0, 1)
		pop.Size = Vector3.one * (1 + 6 * pa)
		pop.Transparency = 0.3 + 0.7 * pa
		bodyFade(opts.body, a, 0, 0.06)
	end)
	return D
end

-- a column of fire; the body chars black and crumbles to embers
FX.Inferno = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.fireWhoosh, {volume = 1, speed = 0.75})
	sfx(folder, opts, origin, SND.fireWhoosh, {volume = 0.7, speed = 0.55, delay = 0.35})
	sfx(folder, opts, origin, SND.rockBurst, {volume = 0.35, speed = 1.6, delay = 1.0, cut = 1.0})   -- the char crumbles
	local base = CFrame.new(origin.Position - Vector3.new(0, 3, 0))
	local flames = {}
	for i = 1, 16 do
		local ang = i / 16 * math.pi * 2
		local inner = i % 3 == 0
		local r = inner and rng:NextNumber(0.1, 0.5) or rng:NextNumber(0.6, 1.6)
		local h = inner and rng:NextNumber(4, 6.5) or rng:NextNumber(2.5, 5)
		local col = inner and Color3.fromRGB(255, 230, 120) or (i % 2 == 0 and Color3.fromRGB(255, 150, 30) or Color3.fromRGB(255, 70, 20))
		local f = wedgePart(folder, Vector3.new(0.8, h, 1.3), base * CFrame.new(math.cos(ang) * r, h / 2, math.sin(ang) * r) * CFrame.Angles(0, -ang + math.pi, 0), col, M.Neon)
		table.insert(flames, {p = f, h = h, ang = ang, r = r, phase = rng:NextNumber(0, 6.28)})
	end
	local scorch = ring(folder, base * CFrame.new(0, 0.05, 0), 2.8, 0.1, Color3.fromRGB(30, 22, 18), M.SmoothPlastic, 0)
	if opts.world then
		emit(base * CFrame.new(0, 1, 0), folder, {Texture = FIRE, Color = ColorSequence.new(Color3.fromRGB(255, 160, 40), Color3.fromRGB(200, 40, 10)), Size = NumberSequence.new(1.6, 0.2),
			Lifetime = NumberRange.new(0.6, 1.1), Speed = NumberRange.new(4, 9), SpreadAngle = Vector2.new(25, 25), LightEmission = 1, Rate = 40, Acceleration = Vector3.new(0, 6, 0)})
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 140, 50); l.Range = 18; l.Brightness = 3; l.Parent = scorch
	end
	bodyTint(opts.body, Color3.fromRGB(28, 22, 20), M.Slate)
	local D = 2.2
	animate(D, opts, function(a)
		local grow = math.clamp(a / 0.2, 0, 1)
		local fade = math.clamp((a - 0.6) / 0.4, 0, 1)
		for _, f in ipairs(flames) do
			local hh = f.h * grow * (1 - fade * 0.7) * (0.85 + 0.15 * math.sin(a * 40 + f.phase))
			f.p.Size = Vector3.new(0.8, math.max(0.05, hh), 1.3)
			f.p.CFrame = base * CFrame.new(math.cos(f.ang) * f.r, hh / 2, math.sin(f.ang) * f.r) * CFrame.Angles(0, -f.ang + math.pi, 0)
			f.p.Transparency = fade
		end
		scorch.Transparency = math.clamp((a - 0.8) / 0.2, 0, 1)
		bodyFade(opts.body, a, 0.45, 0.85)
	end)
	return D
end

-- encased in ice, then the ice and the body shatter into shards
FX.Frozen = function(folder, origin, opts)
	local ice = part(folder, Enum.PartType.Block, Vector3.new(3.2, 5.6, 2.2), origin * CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0.3, 0), Color3.fromRGB(180, 230, 255), M.Glass, 0.35)
	local shards
	local floor = origin.Position.Y - 3
	local D = 2.2
	bodyTint(opts.body, Color3.fromRGB(170, 220, 255), M.Ice)
	-- the ice creaks as it closes, then bursts at the shatter
	sfx(folder, opts, origin, SND.iceCrack, {volume = 0.8, speed = 1.35, cut = 0.9, fade = 0.2})
	sfx(folder, opts, origin, SND.glassShatter, {volume = 1, speed = 0.95, delay = D * 0.45})
	sfx(folder, opts, origin, SND.glassBreak, {volume = 0.6, speed = 1.3, delay = D * 0.45 + 0.05})
	animate(D, opts, function(a, dt)
		local grow = math.clamp(a / 0.15, 0, 1)
		ice.Size = Vector3.new(3.2, 5.6 * grow + 0.05, 2.2)
		if a < 0.45 then
			ice.Transparency = 0.35
		else
			if not shards then
				ice.Transparency = 1
				bodyFade(opts.body, 1, 0, 1)
				shards = debris(folder, origin, 26, function(i)
					local s = rng:NextNumber(0.25, 0.7)
					return wedgePart(folder, Vector3.new(s * 0.4, s * 1.6, s), origin, i % 3 == 0 and Color3.fromRGB(240, 250, 255) or Color3.fromRGB(150, 210, 255), M.Glass)
				end, {speedMin = 6, speedMax = 14, upMin = 0, upMax = 0.8, spawnSpread = 0.9})
			end
			stepDebris(shards, (a - 0.45) / 0.55, dt, {gravity = 30, floor = floor, fadeFrom = 0.6}, D * 0.55)
		end
	end)
	return D
end

-- a bolt from the sky, a flash, a scorch mark
FX.Thunderstrike = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.zap, {volume = 1, speed = 0.8})
	sfx(folder, opts, origin, SND.thunder, {volume = 1, cut = 3.2, fade = 1.5, far = 300})
	local top = origin.Position + Vector3.new(0, 26, 0)
	local bottom = origin.Position - Vector3.new(0, 2.6, 0)
	local segs = {}
	local p0 = top
	for i = 1, 9 do
		local f = i / 9
		local p1 = top:Lerp(bottom, f) + (i < 9 and Vector3.new(rng:NextNumber(-1.6, 1.6), 0, rng:NextNumber(-1.6, 1.6)) or Vector3.zero)
		local mid = (p0 + p1) / 2
		local s = part(folder, Enum.PartType.Block, Vector3.new(0.45, 0.45, (p1 - p0).Magnitude + 0.2), CFrame.lookAt(mid, p1), Color3.fromRGB(200, 235, 255), M.Neon, 0)
		table.insert(segs, s)
		p0 = p1
	end
	local glow = part(folder, Enum.PartType.Ball, Vector3.one * 3, origin, Color3.fromRGB(170, 220, 255), M.Neon, 0.5)
	local scorch = ring(folder, CFrame.new(bottom + Vector3.new(0, 0.05, 0)), 2.2, 0.1, Color3.fromRGB(25, 25, 30), M.SmoothPlastic, 0)
	if opts.world then
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(180, 220, 255); l.Range = 30; l.Brightness = 6; l.Parent = glow
		emit(origin, folder, {Texture = SPARK, Color = ColorSequence.new(Color3.fromRGB(200, 240, 255)), Size = NumberSequence.new(0.4, 0), Lifetime = NumberRange.new(0.2, 0.5),
			Speed = NumberRange.new(10, 22), SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Rate = 60, Drag = 4})
	end
	bodyTint(opts.body, Color3.fromRGB(30, 30, 36), nil)
	local D = 1.4
	animate(D, opts, function(a)
		local strike = math.clamp(a / 0.08, 0, 1)
		local fade = math.clamp((a - 0.12) / 0.3, 0, 1)
		for i, s in ipairs(segs) do
			s.Transparency = (i / #segs > strike) and 1 or (fade + (math.sin(a * 90 + i) > 0.6 and 0.3 or 0))
		end
		glow.Size = Vector3.one * (3 + 5 * math.clamp(a / 0.2, 0, 1))
		glow.Transparency = 0.55 + 0.45 * math.clamp((a - 0.05) / 0.35, 0, 1)
		scorch.Transparency = math.clamp((a - 0.75) / 0.25, 0, 1)
		bodyFade(opts.body, a, 0.5, 0.9)
	end)
	return D
end

-- a pillar of light: the body rises, golden motes and wings, then it is gone
FX.Ascension = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.choir, {volume = 0.75, cut = 3.4, fade = 1.6, far = 200})
	sfx(folder, opts, origin, SND.swish, {volume = 0.5, speed = 0.8, delay = 0.3})
	local beam = part(folder, Enum.PartType.Cylinder, Vector3.new(30, 3, 3), CFrame.new(origin.Position + Vector3.new(0, 12, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 240, 190), M.Neon, 0.5)
	local motes = {}
	for i = 1, 16 do
		local ang = rng:NextNumber(0, 6.28)
		table.insert(motes, {p = part(folder, Enum.PartType.Ball, Vector3.one * rng:NextNumber(0.15, 0.35), origin, Color3.fromRGB(255, 220, 120), M.Neon, 0), ang = ang, r = rng:NextNumber(0.6, 1.8), y0 = rng:NextNumber(-3, 1), sp = rng:NextNumber(3, 7)})
	end
	local wings = {}
	for _, s in ipairs({-1, 1}) do
		for k = 1, 4 do
			local w = wedgePart(folder, Vector3.new(0.12, 0.5, 1.6 - k * 0.25), origin, Color3.fromRGB(255, 255, 245), M.Neon)
			table.insert(wings, {p = w, s = s, k = k})
		end
	end
	local D = 2.4
	animate(D, opts, function(a)
		local open = math.clamp(a / 0.2, 0, 1)
		beam.Size = Vector3.new(30, 3 * open, 3 * open)
		beam.Transparency = 0.5 + 0.5 * math.clamp((a - 0.7) / 0.3, 0, 1)
		local rise = a * 6
		for _, m in ipairs(motes) do
			local y = m.y0 + m.sp * a * 2
			m.p.CFrame = CFrame.new(origin.Position + Vector3.new(math.cos(m.ang + a * 4) * m.r, y, math.sin(m.ang + a * 4) * m.r))
			m.p.Transparency = math.clamp((a - 0.6) / 0.4, 0, 1)
		end
		for _, w in ipairs(wings) do
			local spread = math.rad(20 + 18 * w.k) * open
			w.p.CFrame = origin * CFrame.new(0, 0.8 + rise, 0.6) * CFrame.Angles(0, 0, w.s * spread) * CFrame.new(0, 0.9 + w.k * 0.35, 0) * CFrame.Angles(0, w.s * math.pi / 2, 0)
			w.p.Transparency = math.clamp((a - 0.65) / 0.35, 0, 1)
		end
		if opts.body then
			for _, p in ipairs(opts.body) do
				if p:IsA("BasePart") then hide(p, math.clamp((a - 0.15) / 0.5, 0, 1), opts.body) end
			end
		end
	end)
	return D
end

-- a rift opens underfoot; the body sinks into purple smoke
FX.ShadowRift = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.rift, {volume = 0.9, speed = 0.55})
	sfx(folder, opts, origin, SND.synthRip, {volume = 0.5, speed = 0.45, delay = 0.25})
	local floorCF = CFrame.new(origin.Position - Vector3.new(0, 2.95, 0))
	local rim = ring(folder, floorCF, 0.2, 0.06, Color3.fromRGB(150, 60, 255), M.Neon, 0)
	local disc = ring(folder, floorCF * CFrame.new(0, 0.03, 0), 0.2, 0.08, Color3.fromRGB(12, 0, 20), M.SmoothPlastic, 0)
	local wisps = {}
	for i = 1, 10 do
		local ang = i / 10 * math.pi * 2
		table.insert(wisps, {p = wedgePart(folder, Vector3.new(0.2, 1.4, 0.5), floorCF, Color3.fromRGB(90, 30, 150), M.Neon), ang = ang})
	end
	if opts.world then
		emit(floorCF * CFrame.new(0, 0.5, 0), folder, {Texture = SMOKE, Color = ColorSequence.new(Color3.fromRGB(60, 10, 90), Color3.fromRGB(10, 0, 20)), Size = NumberSequence.new(1.5, 3),
			Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(60, 60), Rate = 30, Transparency = NumberSequence.new(0.4, 1)})
	end
	local D = 2.2
	animate(D, opts, function(a)
		local open = math.clamp(a / 0.25, 0, 1) * (1 - math.clamp((a - 0.8) / 0.2, 0, 1))
		local r = 3.2 * open
		disc.Size = Vector3.new(0.08, r * 2 + 0.01, r * 2 + 0.01)
		rim.Size = Vector3.new(0.06, r * 2 + 0.6, r * 2 + 0.6)
		rim.Transparency = 0.2 + 0.8 * (1 - open)
		for _, w in ipairs(wisps) do
			local ang = w.ang + a * 5
			w.p.CFrame = floorCF * CFrame.new(math.cos(ang) * r * 0.8, 0.7 + math.sin(a * 12 + w.ang) * 0.3, math.sin(ang) * r * 0.8) * CFrame.Angles(0, -ang, 0)
			w.p.Transparency = 1 - open
		end
		if opts.body then
			for _, p in ipairs(opts.body) do
				if p:IsA("BasePart") then hide(p, math.clamp((a - 0.3) / 0.45, 0, 1), opts.body) end
			end
		end
	end)
	return D
end

-- the body bursts into gold coins that bounce on the floor
FX.GoldRush = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.pop, {volume = 0.6, speed = 0.7})
	sfx(folder, opts, origin, SND.shells, {volume = 0.9, speed = 1.45, delay = 0.25})
	sfx(folder, opts, origin, SND.shellsLong, {volume = 0.6, speed = 1.6, delay = 0.45, cut = 1.4})
	local floor = origin.Position.Y - 2.95
	local bits = debris(folder, origin, 28, function()
		return part(folder, Enum.PartType.Cylinder, Vector3.new(0.12, 0.6, 0.6), origin, Color3.fromRGB(255, 200, 60), M.Metal)
	end, {speedMin = 6, speedMax = 13, upMin = 0.5, upMax = 1.3, spawnSpread = 0.5})
	local glint = part(folder, Enum.PartType.Ball, Vector3.one, origin, Color3.fromRGB(255, 230, 120), M.Neon, 0.2)
	local D = 2
	animate(D, opts, function(a, dt)
		stepDebris(bits, a, dt, {gravity = 32, floor = floor, fadeFrom = 0.75}, D)
		glint.Size = Vector3.one * (1 + 4 * math.clamp(a / 0.15, 0, 1))
		glint.Transparency = 0.2 + 0.8 * math.clamp(a / 0.25, 0, 1)
		bodyFade(opts.body, a, 0, 0.06)
	end)
	return D
end

-- a burst of black feathers that flutter down
FX.CrowSwarm = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.wings, {volume = 1})
	sfx(folder, opts, origin, SND.raven, {volume = 0.8, delay = 0.15})
	sfx(folder, opts, origin, SND.raven, {volume = 0.6, speed = 0.85, delay = 0.7})
	local bits = debris(folder, origin, 30, function(i)
		return wedgePart(folder, Vector3.new(0.05, 0.25, 0.8), origin, i % 4 == 0 and Color3.fromRGB(60, 60, 75) or Color3.fromRGB(14, 14, 18), M.SmoothPlastic)
	end, {speedMin = 7, speedMax = 15, upMin = 0.3, upMax = 1.1, spawnSpread = 0.6})
	local D = 2.4
	animate(D, opts, function(a, dt)
		stepDebris(bits, a, dt, {gravity = 6, fadeFrom = 0.7}, D)
		bodyFade(opts.body, a, 0, 0.06)
	end)
	return D
end

-- gold rays and a crown that settles over the fallen
FX.RoyalDecree = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.fanfare, {volume = 0.7, cut = 3.6, fade = 1.4, far = 220})
	sfx(folder, opts, origin, SND.swish, {volume = 0.4, speed = 1.3})
	local crownCF = origin * CFrame.new(0, 3.2, 0)
	local band = ring(folder, crownCF, 0.75, 0.35, Color3.fromRGB(255, 200, 60), M.Metal, 0)
	local points = {}
	for i = 0, 4 do
		local ang = i / 5 * math.pi * 2
		table.insert(points, {p = wedgePart(folder, Vector3.new(0.12, 0.6, 0.35), crownCF, Color3.fromRGB(255, 200, 60), M.Metal), ang = ang})
	end
	local gem = part(folder, Enum.PartType.Ball, Vector3.one * 0.35, crownCF, Color3.fromRGB(230, 30, 60), M.Neon, 0)
	local rays = {}
	for i = 1, 12 do
		local ang = i / 12 * math.pi * 2
		table.insert(rays, {p = part(folder, Enum.PartType.Block, Vector3.new(0.15, 0.15, 4), origin, Color3.fromRGB(255, 230, 140), M.Neon, 0.3), ang = ang})
	end
	local D = 2.4
	animate(D, opts, function(a)
		local drop = 1 - math.clamp(a / 0.3, 0, 1)
		local cf = crownCF * CFrame.new(0, drop * 3, 0) * CFrame.Angles(0, a * 3, 0)
		local fade = math.clamp((a - 0.75) / 0.25, 0, 1)
		band.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
		band.Transparency = fade
		for _, pt in ipairs(points) do
			pt.p.CFrame = cf * CFrame.new(math.cos(pt.ang) * 0.75, 0.45, math.sin(pt.ang) * 0.75) * CFrame.Angles(0, -pt.ang + math.pi / 2, 0)
			pt.p.Transparency = fade
		end
		gem.CFrame = cf * CFrame.new(0, 0.1, -0.78)
		gem.Transparency = fade
		local spread = math.clamp(a / 0.4, 0, 1)
		for _, r in ipairs(rays) do
			local ang = r.ang + a * 0.8
			r.p.CFrame = origin * CFrame.Angles(0, ang, 0) * CFrame.Angles(math.rad(35), 0, 0) * CFrame.new(0, 0, -2.5 * spread - 1)
			r.p.Transparency = 0.3 + 0.7 * math.clamp((a - 0.5) / 0.5, 0, 1)
		end
		bodyFade(opts.body, a, 0.55, 0.9)
	end)
	return D
end

KillFX.IDS = {}
for k in pairs(FX) do table.insert(KillFX.IDS, k) end
table.sort(KillFX.IDS)

function KillFX.has(id) return FX[id] ~= nil end

function KillFX.play(id, container, origin, opts)
	opts = opts or {}
	local fn = FX[id]
	if not fn or not container then return 0 end
	local folder = Instance.new("Folder")
	folder.Name = "KillFX_" .. id
	folder.Parent = container
	local ok, d = pcall(fn, folder, origin, opts)
	if not ok then warn("[KillFX]", id, d); folder:Destroy(); return 0 end
	if not opts.freezeAt then task.delay((d or 2) + 0.2, function() if folder.Parent then folder:Destroy() end end) end
	return d or 2
end

return KillFX
