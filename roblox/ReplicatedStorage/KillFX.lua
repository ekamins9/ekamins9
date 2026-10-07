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
           opts.colors    the body's colours when the body itself isn't here (a
                       client that hasn't streamed it in still sees the effect)
       KillFX.IDS      every effect id

     Effects only touch the body locally (LocalTransparencyModifier, a local
     colour), so a kill never changes what the server sees. ]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local KillFX = {}
KillFX.VOLUME = 0.55   -- every kill effect's sounds together: they sit under the fight, not on top of it
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
-- the body's colours (or, with no body here, the ones the server sent: opts.colors)
local function bodyColors(body, sent)
	local cols = {}
	for _, p in ipairs(body or {}) do
		if p:IsA("BasePart") and p.Transparency < 1 then table.insert(cols, p.Color) end
	end
	if #cols == 0 and type(sent) == "table" then for _, c in ipairs(sent) do if typeof(c) == "Color3" then table.insert(cols, c) end end end
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
	whoosh = 9114157391, rocksDirt = 9118680937, dirtHit = 9118598722, metalHit = 9116669163, sandHit = 9118767941,
	splash = 9119479417, rumble = 9118749929, foliage = 9114518577, hiss = 9119303232, chomp = 9113574800,
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
	s.Volume = (o.volume or 0.8) * (opts.world and 1 or 0.6) * KillFX.VOLUME
	s.PlaybackSpeed = (o.speed or 1) * rng:NextNumber(0.97, 1.03)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = o.near or 8
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
--------------------------------------------------------------------
--  MORE HELPERS (shapes, timing, the puppet)
--------------------------------------------------------------------
-- a sphere of any proportions (a Ball part is always round)
local function blob(folder, size, cf, color, mat, transp)
	local p = part(folder, Enum.PartType.Block, size, cf, color, mat, transp)
	local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
	return p
end
local function ball(folder, d, cf, color, mat, transp) return part(folder, Enum.PartType.Ball, Vector3.one * d, cf, color, mat, transp) end
local function seg(a, from, to) return math.clamp((a - from) / (to - from), 0, 1) end
local function easeOut(x) return 1 - (1 - x) ^ 3 end
local function easeIn(x) return x * x * x end
local function easeInOut(x) return x < 0.5 and 4 * x * x * x or 1 - (-2 * x + 2) ^ 3 / 2 end
-- the floor under the effect, facing the way the origin does
local function floorOf(origin) return CFrame.new(origin.Position - Vector3.new(0, 3, 0)) * origin.Rotation end
-- the body squashed flat (a menu preview's stand-in for the remains Corpses lays in the world)
local function flatBody(folder, base, cols)
	local function c(i) return cols[(i - 1) % #cols + 1] end
	local function slab(size, x, z, yaw, col) return part(folder, Enum.PartType.Block, size, base * CFrame.new(x, size.Y / 2 + 0.02, z) * CFrame.Angles(0, yaw, 0), col) end
	return {slab(Vector3.new(2.2, 0.12, 2.2), 0, 0, 0, c(1)), slab(Vector3.new(1.4, 0.1, 1.4), 0, -1.85, 0, c(2)),
		slab(Vector3.new(1.1, 0.1, 2.2), -1.8, -0.4, -0.5, c(3)), slab(Vector3.new(1.1, 0.1, 2.2), 1.8, -0.4, 0.5, c(3)),
		slab(Vector3.new(1.1, 0.1, 2.3), -0.7, 2.15, 0.2, c(4)), slab(Vector3.new(1.1, 0.1, 2.3), 0.7, 2.15, -0.2, c(4))}
end
--------------------------------------------------------------------
--  THE PUPPET: a stand-in for the body that an effect can move: dragged
--  under, swallowed, sucked in, squashed flat. Anchored copies of what can
--  be seen of the body (made the moment they're first needed, so a tint
--  carries over), and the real body hidden. Every client makes its own, so
--  the server's ragdoll is never touched.
--------------------------------------------------------------------
local KEEP = {Decal = true, Texture = true, SpecialMesh = true, BlockMesh = true, CylinderMesh = true, SurfaceAppearance = true}
local function puppet(folder, origin, opts)
	if opts.puppetState then return opts.puppetState end
	local P = {list = {}, origin = origin}
	opts.puppetState = P
	for _, b in ipairs(opts.body or {}) do
		if b:IsA("BasePart") and b.Parent and b.Archivable then
			local t0 = b:GetAttribute("FxT0")
			local seen = (t0 or b.Transparency) < 1 and (opts.body.direct or b.LocalTransparencyModifier < 1)
			local c = seen and b:Clone()
			if c then
				for _, k in ipairs(c:GetChildren()) do if not KEEP[k.ClassName] then k:Destroy() end end
				c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch, c.Massless = true, false, false, false, true
				if t0 then c.Transparency = t0 end
				c.LocalTransparencyModifier = 0
				c:SetAttribute("FxT0", nil)
				c:SetAttribute("FxOldColor", nil)
				c.Parent = folder
				table.insert(P.list, {p = c, rel = origin:ToObjectSpace(b.CFrame), size = c.Size, t0 = c.Transparency})
			end
		end
	end
	bodyFade(opts.body, 1, 0, 1)
	return P
end
-- place it: cf = where its origin is now; k = a uniform scale about that origin
local function posePuppet(P, cf, k)
	k = k or 1
	for _, q in ipairs(P.list) do
		q.p.Size = q.size * k
		q.p.CFrame = cf * (CFrame.new(q.rel.Position * k) * q.rel.Rotation)
	end
end
local function fadePuppet(P, t)
	for _, q in ipairs(P.list) do
		q.p.Transparency = q.t0 + (1 - q.t0) * t
		for _, d in ipairs(q.p:GetChildren()) do
			if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = math.max(d.Transparency, t) end
		end
	end
end
-- pressed toward the floor (k = 1 as it lay, small = flat), spreading out a little
local function squashPuppet(P, floorY, k)
	local c = P.origin.Position
	for _, q in ipairs(P.list) do
		local w = P.origin * q.rel
		local r = w.Rotation
		local ax, ay, az = math.abs(r.RightVector.Y), math.abs(r.UpVector.Y), math.abs(r.LookVector.Y)
		local sz = q.size
		if ax >= ay and ax >= az then sz = Vector3.new(sz.X * k, sz.Y, sz.Z)
		elseif ay >= az then sz = Vector3.new(sz.X, sz.Y * k, sz.Z)
		else sz = Vector3.new(sz.X, sz.Y, sz.Z * k) end
		q.p.Size = sz
		local pos = w.Position
		local spread = 1 + (1 - k) * 0.3
		q.p.CFrame = CFrame.new(c.X + (pos.X - c.X) * spread, floorY + math.max(pos.Y - floorY, 0) * k + 0.04, c.Z + (pos.Z - c.Z) * spread) * r
	end
end

local function fadeAll(list, t) for _, p in ipairs(list) do if p.Parent then p.Transparency = math.max(p.Transparency, t) end end end
-- debris (from debris()) kept out of sight until its moment
local function hideBits(bits) for _, b in ipairs(bits) do b.p.Transparency = 1 end end
-- a ring of dust or light that rushes out along the floor
local function shockRing(folder, floorCF, color, mat)
	return ring(folder, floorCF * CFrame.new(0, 0.08, 0), 0.5, 0.2, color, mat or M.SmoothPlastic, 0.2)
end
local function stepRing(r, floorCF, a, rMax, thick)
	local rr = 0.5 + (rMax - 0.5) * easeOut(a)
	r.Size = Vector3.new(thick or 0.2, rr * 2, rr * 2)
	r.CFrame = floorCF * CFrame.new(0, 0.08, 0) * CFrame.Angles(0, 0, math.pi / 2)
	r.Transparency = 0.2 + 0.8 * a
end

local FX = {}

-- the body bursts into blocks of its own colours
FX.Shatter = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.rockBurst, {volume = 0.9, speed = 1.15, cut = 1.4, fade = 0.5})
	sfx(folder, opts, origin, SND.glassBreak, {volume = 0.45, speed = 0.75})
	local cols = bodyColors(opts.body, opts.colors)
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
		-- the body itself is lifted into the light
		if a >= 0.05 then
			local P = puppet(folder, origin, opts)
			posePuppet(P, origin * CFrame.new(0, rise * 0.8 * easeIn(seg(a, 0.05, 0.7)) * 1.6, 0) * CFrame.Angles(0, a * 1.5, 0))
			fadePuppet(P, seg(a, 0.25, 0.7))
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
		-- pulled down into it
		if a >= 0.25 then
			local P = puppet(folder, origin, opts)
			local sink = easeIn(seg(a, 0.28, 0.75))
			posePuppet(P, origin * CFrame.new(0, -5 * sink, 0) * CFrame.Angles(0, sink * 2, 0))
			fadePuppet(P, seg(a, 0.7, 0.76))
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

--------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------
-- a cartoon puff of smoke and spinning stars: gone
FX.Poof = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.whoosh, {volume = 0.7, speed = 1.4, cut = 0.7, fade = 0.3})
	sfx(folder, opts, origin, SND.pop, {volume = 0.9, speed = 0.55})
	local puffs = {}
	for _ = 1, 13 do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.5, 1), rng:NextNumber(-1, 1))
		if dir.Magnitude < 0.1 then dir = Vector3.yAxis end
		local shade = rng:NextNumber(0.78, 0.96)
		table.insert(puffs, {p = ball(folder, 0.5, origin, Color3.new(shade, shade, shade), M.SmoothPlastic, 0.05), dir = dir.Unit, d = rng:NextNumber(1.5, 2.6), r = rng:NextNumber(1, 2.2)})
	end
	local stars = {}
	for i = 1, 5 do table.insert(stars, {p = part(folder, Enum.PartType.Block, Vector3.new(0.34, 0.34, 0.08), origin, Color3.fromRGB(255, 226, 110), M.Neon), ang = i / 5 * math.pi * 2}) end
	local D = 1.5
	animate(D, opts, function(a)
		local out, fade = easeOut(seg(a, 0, 0.3)), seg(a, 0.45, 1)
		for _, f in ipairs(puffs) do
			f.p.Size = Vector3.one * (0.5 + f.d * out) * (1 + 0.25 * fade)
			f.p.CFrame = origin + f.dir * f.r * out + Vector3.new(0, fade * 1.4, 0)
			f.p.Transparency = 0.05 + 0.95 * fade
		end
		for i, s in ipairs(stars) do
			local ang = s.ang + a * 7
			s.p.CFrame = origin * CFrame.new(math.cos(ang) * 2.2 * out, 1.4 + math.sin(a * 12 + i) * 0.25, math.sin(ang) * 2.2 * out) * CFrame.Angles(0, 0, a * 10)
			s.p.Transparency = seg(a, 0.5, 0.9)
		end
		bodyFade(opts.body, a, 0.04, 0.12)
	end)
	return D
end

-- the ground opens, a headstone rises over a fresh mound
FX.Tombstone = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.rocksDirt, {volume = 1, speed = 0.75})
	sfx(folder, opts, origin, SND.dirtHit, {volume = 0.9, speed = 0.8, delay = 0.95})
	sfx(folder, opts, origin, SND.raven, {volume = 0.45, delay = 1.3})
	local base = floorOf(origin)
	local stoneCol, cutCol = Color3.fromRGB(122, 124, 130), Color3.fromRGB(52, 52, 58)
	local slab = part(folder, Enum.PartType.Block, Vector3.new(2, 2.4, 0.4), base, stoneCol, M.Slate)
	local top = part(folder, Enum.PartType.Cylinder, Vector3.new(0.4, 2, 2), base, stoneCol, M.Slate)
	local cutV = part(folder, Enum.PartType.Block, Vector3.new(0.18, 1.1, 0.05), base, cutCol)
	local cutH = part(folder, Enum.PartType.Block, Vector3.new(0.7, 0.18, 0.05), base, cutCol)
	local mound = blob(folder, Vector3.new(0.1, 0.1, 0.1), base, Color3.fromRGB(92, 70, 50), M.Ground)
	local dirt = debris(folder, base * CFrame.new(0, 0.3, 0), 18, function()
		local s = rng:NextNumber(0.2, 0.45)
		return part(folder, Enum.PartType.Block, Vector3.one * s, base, Color3.fromRGB(96, 72, 50), M.Ground)
	end, {speedMin = 5, speedMax = 10, upMin = 0.8, upMax = 1.6, spawnSpread = 0.8})
	local stoneParts = {slab, top, cutV, cutH, mound}
	local D = 2.6
	animate(D, opts, function(a, dt)
		local rise = easeOut(seg(a, 0.12, 0.42))
		local y = -2.9 * (1 - rise)
		local at = base * CFrame.new(0, y, -1.6)
		slab.CFrame = at * CFrame.new(0, 1.2, 0)
		top.CFrame = at * CFrame.new(0, 2.4, 0) * CFrame.Angles(0, math.pi / 2, 0)
		cutV.CFrame = at * CFrame.new(0, 1.85, 0.22)
		cutH.CFrame = at * CFrame.new(0, 2.1, 0.22)
		local m = easeOut(seg(a, 0.25, 0.5))
		mound.Size = Vector3.new(2.2 * m + 0.05, 0.7 * m + 0.05, 3.4 * m + 0.05)
		mound.CFrame = base * CFrame.new(0, 0.05, 0.4)
		if a >= 0.08 then stepDebris(dirt, seg(a, 0.08, 0.6), dt, {gravity = 30, floor = base.Position.Y, fadeFrom = 0.6}, D * 0.52) else hideBits(dirt) end
		fadeAll(stoneParts, seg(a, 0.88, 1))
		-- the ground takes them first
		if a >= 0.08 then
			local P = puppet(folder, origin, opts)
			posePuppet(P, origin * CFrame.new(0, -4 * easeIn(seg(a, 0.08, 0.3)), 0))
			fadePuppet(P, seg(a, 0.28, 0.31))
		end
	end)
	return D
end

--------------------------------------------------------------------
--  RARE
--------------------------------------------------------------------
-- a whistle, a shadow, an anvil: flat
FX.Anvil = function(folder, origin, opts)
	local D, HIT = 2.3, 0.28
	sfx(folder, opts, origin, SND.swish, {volume = 0.6, speed = 0.45, cut = D * HIT, fade = 0.05})
	sfx(folder, opts, origin, SND.metalHit, {volume = 1, speed = 0.8, delay = D * HIT})
	sfx(folder, opts, origin, SND.dirtHit, {volume = 1, speed = 0.7, delay = D * HIT})
	sfx(folder, opts, origin, SND.rockBurst, {volume = 0.5, speed = 1.3, delay = D * HIT + 0.02, cut = 0.8})
	local base = floorOf(origin)
	local iron = Color3.fromRGB(56, 58, 66)
	local anvil = {
		{p = part(folder, Enum.PartType.Block, Vector3.new(1.8, 0.5, 1.2), base, iron, M.Metal), off = CFrame.new(0, 0.25, 0)},
		{p = part(folder, Enum.PartType.Block, Vector3.new(1, 0.6, 0.8), base, iron, M.Metal), off = CFrame.new(0, 0.8, 0)},
		{p = part(folder, Enum.PartType.Block, Vector3.new(2.6, 0.6, 1.2), base, iron, M.Metal), off = CFrame.new(0, 1.4, 0)},
		{p = wedgePart(folder, Vector3.new(1.2, 0.6, 1.1), base, iron, M.Metal), off = CFrame.new(1.85, 1.4, 0) * CFrame.Angles(0, -math.pi / 2, 0)},
	}
	local shadow = ring(folder, base * CFrame.new(0, 0.04, 0), 0.2, 0.05, Color3.new(0, 0, 0), M.SmoothPlastic, 0.6)
	local dust = shockRing(folder, base, Color3.fromRGB(170, 160, 140))
	local puffs = debris(folder, base * CFrame.new(0, 0.3, 0), 14, function()
		return ball(folder, rng:NextNumber(0.6, 1.1), base, Color3.fromRGB(190, 180, 160), M.SmoothPlastic, 0.3)
	end, {speedMin = 4, speedMax = 9, upMin = 0, upMax = 0.4})
	local flat
	animate(D, opts, function(a, dt)
		local fall = easeIn(seg(a, 0, HIT))
		local bounce = a > HIT and math.sin(seg(a, HIT, HIT + 0.12) * math.pi) * 0.5 or 0
		local y = 24 * (1 - fall) + bounce + (a >= HIT and 0.12 or 0)
		local spin = (1 - fall) * 0.6
		for _, q in ipairs(anvil) do
			q.p.CFrame = base * CFrame.new(0, y, 0) * CFrame.Angles(0, spin, 0) * q.off
			q.p.Transparency = seg(a, 0.86, 1)
		end
		local sh = 0.4 + 1.2 * fall
		shadow.Size = Vector3.new(0.05, sh * 2, sh * 2)
		shadow.Transparency = a < HIT and 0.85 - 0.35 * fall or 1
		if a >= HIT then
			stepRing(dust, base, seg(a, HIT, 0.75), 5.5, 0.3)
			stepDebris(puffs, seg(a, HIT, 1), dt, {gravity = 2, fadeFrom = 0.3}, D * (1 - HIT))
			local P = puppet(folder, origin, opts)
			squashPuppet(P, base.Position.Y, 0.07)
			fadePuppet(P, seg(a, 0.9, 1))
			-- (no body here at all: a flat stand-in in its colours)
			if #P.list == 0 and not flat then flat = flatBody(folder, base, bodyColors(opts.body, opts.colors)) end
		else
			dust.Transparency = 1
			hideBits(puffs)
		end
		if flat then fadeAll(flat, seg(a, 0.9, 1)) end
	end)
	return D
end

-- grey stone creeps up the body, cracks run through it: a statue
FX.Petrify = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.iceCrack, {volume = 0.8, speed = 0.55, cut = 1.0})
	sfx(folder, opts, origin, SND.rockBurst, {volume = 0.6, speed = 0.65, delay = 0.75, cut = 0.9})
	local base = floorOf(origin)
	local grey = Color3.fromRGB(132, 130, 126)
	local band = ring(folder, base, 1.5, 0.35, Color3.fromRGB(160, 158, 150), M.Slate, 0.1)
	local cracks = {}
	for _ = 1, 12 do
		local at = origin * CFrame.new(rng:NextNumber(-0.9, 0.9), rng:NextNumber(-2.4, 2), rng:NextNumber(-0.7, -0.55)) * CFrame.Angles(0, 0, rng:NextNumber(-1.2, 1.2))
		table.insert(cracks, part(folder, Enum.PartType.Block, Vector3.new(0.06, rng:NextNumber(0.4, 0.9), 0.05), at, Color3.fromRGB(40, 38, 36), M.SmoothPlastic, 1))
	end
	local dust = debris(folder, origin, 12, function()
		return ball(folder, rng:NextNumber(0.3, 0.6), origin, Color3.fromRGB(170, 166, 158), M.SmoothPlastic, 0.3)
	end, {speedMin = 2, speedMax = 5, upMin = -0.2, upMax = 0.6, spawnSpread = 1})
	local tinted = false
	local D = 1.9
	animate(D, opts, function(a, dt)
		local climb = seg(a, 0, 0.35)
		band.CFrame = base * CFrame.new(0, 0.2 + 5.4 * climb, 0) * CFrame.Angles(0, 0, math.pi / 2)
		band.Transparency = climb >= 1 and 1 or 0.1
		if climb >= 0.6 and not tinted then tinted = true; bodyTint(opts.body, grey, M.Slate) end
		for i, c in ipairs(cracks) do c.Transparency = a < 0.42 + i * 0.012 and 1 or seg(a, 0.85, 1) end
		if a >= 0.45 then stepDebris(dust, seg(a, 0.45, 1), dt, {gravity = 3, fadeFrom = 0.3}, D * 0.55) else hideBits(dust) end
		bodyFade(opts.body, a, 0.84, 0.92)
	end)
	return D
end

-- the ground turns to sand and swirls them under
FX.Quicksand = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.sandHit, {volume = 0.9, speed = 0.6})
	sfx(folder, opts, origin, SND.shellsLong, {volume = 0.45, speed = 0.45, cut = 1.8, fade = 0.5})
	local base = floorOf(origin)
	local sand = Color3.fromRGB(214, 186, 130)
	local disc = ring(folder, base * CFrame.new(0, 0.04, 0), 0.2, 0.08, sand, M.Sand, 0)
	local pit = ring(folder, base * CFrame.new(0, 0.06, 0), 0.1, 0.08, Color3.fromRGB(120, 96, 62), M.Sand, 0)
	local grains = {}
	for i = 1, 22 do table.insert(grains, {p = ball(folder, rng:NextNumber(0.18, 0.34), base, sand:Lerp(Color3.new(1, 1, 1), rng:NextNumber(0, 0.2)), M.Sand), ang = rng:NextNumber(0, 6.28), r = rng:NextNumber(0.8, 2.6), y = rng:NextNumber(0, 3), sp = rng:NextNumber(3, 6)}) end
	local mound = blob(folder, Vector3.new(0.1, 0.1, 0.1), base, sand, M.Sand)
	local D = 2.4
	animate(D, opts, function(a)
		local open = easeOut(seg(a, 0, 0.18)) * (1 - seg(a, 0.75, 0.9))
		local r = 2.8 * open
		disc.Size = Vector3.new(0.08, r * 2 + 0.01, r * 2 + 0.01)
		pit.Size = Vector3.new(0.08, r + 0.01, r + 0.01)
		for _, g in ipairs(grains) do
			local k = seg(a, 0.1, 0.8)
			local ang = g.ang + a * g.sp * 2
			local rr = g.r * (1 - k * 0.85)
			g.p.CFrame = base * CFrame.new(math.cos(ang) * rr, 0.2 + g.y * (1 - k), math.sin(ang) * rr)
			g.p.Transparency = seg(a, 0.75, 0.9)
		end
		local m = easeOut(seg(a, 0.72, 0.9))
		mound.Size = Vector3.new(3.8 * m + 0.05, 0.9 * m + 0.05, 3.8 * m + 0.05)
		mound.CFrame = base * CFrame.new(0, 0.05, 0)
		mound.Transparency = seg(a, 0.92, 1)
		-- slowly under, turning with the sand
		if a >= 0.15 then
			local P = puppet(folder, origin, opts)
			local sink = easeIn(seg(a, 0.18, 0.75))
			posePuppet(P, origin * CFrame.new(0, -6 * sink, 0) * CFrame.Angles(0, sink * 2.5, 0))
			fadePuppet(P, seg(a, 0.72, 0.78))
		end
	end)
	return D
end

--------------------------------------------------------------------
--  EPIC
--------------------------------------------------------------------
-- dark water underfoot, and arms reach up out of it and drag them down
FX.Kraken = function(folder, origin, opts)
	local D = 2.8
	sfx(folder, opts, origin, SND.splash, {volume = 0.7, speed = 1.2})
	sfx(folder, opts, origin, SND.rumble, {volume = 0.5, cut = 1.6, fade = 0.6})
	sfx(folder, opts, origin, SND.splash, {volume = 1, speed = 0.8, delay = D * 0.5})
	local base = floorOf(origin)
	local pool = ring(folder, base * CFrame.new(0, 0.04, 0), 0.2, 0.06, Color3.fromRGB(14, 32, 48), M.Glass, 0.1)
	local foam = ring(folder, base * CFrame.new(0, 0.03, 0), 0.2, 0.05, Color3.fromRGB(140, 220, 230), M.Neon, 0.5)
	local arms = {}
	for k = 1, 5 do
		local ang = k / 5 * math.pi * 2 + 0.3
		local segs = {}
		for j = 0, 13 do
			local u = j / 13
			table.insert(segs, ball(folder, 1.5 * (1 - u * 0.72), base, j % 3 == 2 and Color3.fromRGB(230, 170, 200) or (j % 2 == 0 and Color3.fromRGB(110, 60, 140) or Color3.fromRGB(132, 78, 160)), M.SmoothPlastic))
		end
		table.insert(arms, {segs = segs, ang = ang, phase = rng:NextNumber(0, 6.28)})
	end
	local drops = debris(folder, base * CFrame.new(0, 0.4, 0), 22, function()
		return ball(folder, rng:NextNumber(0.2, 0.4), base, Color3.fromRGB(150, 210, 235), M.Glass, 0.2)
	end, {speedMin = 6, speedMax = 13, upMin = 1, upMax = 2.2, spawnSpread = 1})
	animate(D, opts, function(a, dt)
		local open = easeOut(seg(a, 0, 0.15)) * (1 - seg(a, 0.85, 1))
		pool.Size = Vector3.new(0.06, 8 * open + 0.01, 8 * open + 0.01)
		foam.Size = Vector3.new(0.05, 8.7 * open + 0.01, 8.7 * open + 0.01)
		local grow = easeOut(seg(a, 0.08, 0.35))
		local pull = easeIn(seg(a, 0.45, 0.68))
		for _, arm in ipairs(arms) do
			local B = Vector3.new(math.cos(arm.ang) * 3, 0, math.sin(arm.ang) * 3)
			local side = Vector3.new(-math.sin(arm.ang), 0, math.cos(arm.ang))
			for j, p in ipairs(arm.segs) do
				local u = (j - 1) / 13
				if u > grow + 0.001 then
					p.Transparency = 1
				else
					local wrap = 1 - u * u * 0.95
					local pos = B * wrap + Vector3.new(0, 6 * math.sin(u * math.pi * 0.7) * grow - 8 * pull, 0)
						+ side * math.sin(a * 9 + u * 5 + arm.phase) * 0.25 * u
					p.CFrame = base * CFrame.new(pos)
					p.Transparency = (pos.Y < -0.2) and 1 or seg(a, 0.8, 0.9)
				end
			end
		end
		if a >= 0.5 then stepDebris(drops, seg(a, 0.5, 1), dt, {gravity = 34, fadeFrom = 0.5}, D * 0.5) else hideBits(drops) end
		-- held, shaken, dragged down with the arms
		if a >= 0.3 then
			local P = puppet(folder, origin, opts)
			local shake = math.sin(a * 90) * 0.15 * seg(a, 0.3, 0.36) * (1 - seg(a, 0.44, 0.48))
			posePuppet(P, origin * CFrame.new(shake, -8 * pull, 0) * CFrame.Angles(0, pull * 1.8, shake * 0.3))
			fadePuppet(P, seg(a, 0.66, 0.72))
		end
	end)
	return D
end

-- vines spiral up them, leaves open, flowers bloom: overgrown
FX.Overgrown = function(folder, origin, opts)
	sfx(folder, opts, origin, SND.foliage, {volume = 1, cut = 2, fade = 0.6})
	sfx(folder, opts, origin, SND.foliage, {volume = 0.6, speed = 1.3, delay = 0.6, cut = 1.4})
	sfx(folder, opts, origin, SND.choir, {volume = 0.25, speed = 1.5, delay = 1.3, cut = 1.0, fade = 0.6})
	local base = floorOf(origin)
	local vines, leaves = {}, {}
	for k = 1, 4 do
		local a0 = k / 4 * math.pi * 2
		local segs = {}
		for j = 1, 16 do
			table.insert(segs, part(folder, Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.6), base, Color3.fromRGB(56, 112, 44), M.Grass))
			if j % 3 == 0 then table.insert(leaves, {p = wedgePart(folder, Vector3.new(0.06, 0.4, 0.55), base, Color3.fromRGB(90, 160, 60), M.Grass), k = k, j = j}) end
		end
		table.insert(vines, {segs = segs, a0 = a0})
	end
	local function vinePos(v, j)
		local u = j / 16
		local ang = v.a0 + u * math.pi * 2.6
		local r = 1.15 - u * 0.25
		return Vector3.new(math.cos(ang) * r, u * 5.3, math.sin(ang) * r)
	end
	local petals = {Color3.fromRGB(255, 140, 180), Color3.fromRGB(255, 230, 100), Color3.fromRGB(250, 250, 250), Color3.fromRGB(190, 140, 255)}
	local flowers = {}
	for i = 1, 8 do
		local v = vines[(i - 1) % 4 + 1]
		table.insert(flowers, {p = ball(folder, 0.1, base, petals[(i - 1) % #petals + 1]), c = ball(folder, 0.1, base, Color3.fromRGB(255, 200, 60)), v = v, j = 6 + ((i * 5) % 10)})
	end
	local drift = debris(folder, origin * CFrame.new(0, 1.5, 0), 16, function(i)
		return part(folder, Enum.PartType.Block, Vector3.new(0.22, 0.04, 0.16), origin, petals[(i - 1) % #petals + 1])
	end, {speedMin = 2, speedMax = 5, upMin = 0.2, upMax = 0.8, spawnSpread = 1})
	local tinted = false
	local D = 2.9
	animate(D, opts, function(a, dt)
		local grow = easeOut(seg(a, 0.03, 0.5))
		local fade = seg(a, 0.86, 1)
		for _, v in ipairs(vines) do
			for j, p in ipairs(v.segs) do
				local u = j / 16
				if u > grow then p.Transparency = 1 else
					local p0, p1 = vinePos(v, j - 1), vinePos(v, j)
					p.Size = Vector3.new(0.2 * (1.2 - u * 0.6), 0.2 * (1.2 - u * 0.6), (p1 - p0).Magnitude + 0.08)
					p.CFrame = base * CFrame.lookAt((p0 + p1) / 2, p1)
					p.Transparency = fade
				end
			end
		end
		for _, l in ipairs(leaves) do
			local u = l.j / 16
			local open = seg(grow, u, u + 0.12)
			local v = vines[l.k]
			l.p.Size = Vector3.new(0.06, 0.4 * open + 0.01, 0.55 * open + 0.01)
			l.p.CFrame = base * CFrame.new(vinePos(v, l.j) * 1.12) * CFrame.Angles(0, -v.a0 - u * 8, 0.4)
			l.p.Transparency = open <= 0 and 1 or fade
		end
		local bloom = easeOut(seg(a, 0.5, 0.68))
		for _, f in ipairs(flowers) do
			local at = base * CFrame.new(vinePos(f.v, f.j) * 1.15)
			f.p.Size = Vector3.one * (0.62 * bloom + 0.02)
			f.c.Size = Vector3.one * (0.26 * bloom + 0.02)
			f.p.CFrame = at
			f.c.CFrame = at * CFrame.new(0, 0.2 * bloom, 0)
			f.p.Transparency = bloom <= 0 and 1 or fade
			f.c.Transparency = bloom <= 0 and 1 or fade
		end
		if a >= 0.45 and not tinted then tinted = true; bodyTint(opts.body, Color3.fromRGB(74, 108, 54), M.Grass) end
		if a >= 0.7 then stepDebris(drift, seg(a, 0.7, 1), dt, {gravity = 2.5, fadeFrom = 0.5}, D * 0.3) else hideBits(drift) end
		bodyFade(opts.body, a, 0.72, 0.84)
	end)
	return D
end

-- a burning rock from the sky
FX.Meteor = function(folder, origin, opts)
	local D, HIT = 2.5, 0.34
	sfx(folder, opts, origin, SND.fireWhoosh, {volume = 0.9, speed = 0.6, cut = D * HIT, fade = 0.1})
	sfx(folder, opts, origin, SND.thunder, {volume = 0.9, speed = 0.7, delay = D * HIT, cut = 2.2, fade = 1, far = 260})
	sfx(folder, opts, origin, SND.rockBurst, {volume = 1, speed = 0.8, delay = D * HIT})
	local base = floorOf(origin)
	local hitAt = base.Position + Vector3.new(0, 0.8, 0)
	local from = hitAt + (origin.RightVector * -16 + Vector3.new(0, 32, 0) + origin.LookVector * 8)
	local rock = blob(folder, Vector3.new(2.3, 2, 2.4), CFrame.new(from), Color3.fromRGB(58, 44, 38), M.Slate)
	local shell = ball(folder, 3, CFrame.new(from), Color3.fromRGB(255, 120, 30), M.Neon, 0.45)
	local trail = {}
	for i = 1, 7 do table.insert(trail, ball(folder, 2.6 - i * 0.3, CFrame.new(from), i < 3 and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(255, 90, 30), M.Neon, 0.3 + i * 0.08)) end
	local flashB = ball(folder, 1, CFrame.new(hitAt), Color3.fromRGB(255, 190, 90), M.Neon, 1)
	local wave = shockRing(folder, base, Color3.fromRGB(255, 140, 50), M.Neon)
	local crater = ring(folder, base * CFrame.new(0, 0.03, 0), 3, 0.05, Color3.fromRGB(34, 26, 22), M.Slate, 1)
	local rocks = debris(folder, CFrame.new(hitAt), 18, function()
		local s = rng:NextNumber(0.3, 0.8)
		return part(folder, Enum.PartType.Block, Vector3.one * s, base, Color3.fromRGB(70, 56, 46), M.Slate)
	end, {speedMin = 8, speedMax = 18, upMin = 0.5, upMax = 1.4, spawnSpread = 0.6})
	local lit = false
	animate(D, opts, function(a, dt)
		local f = easeIn(seg(a, 0, HIT))
		local pos = from:Lerp(hitAt, f)
		local before = a < HIT
		rock.CFrame = CFrame.new(pos) * CFrame.Angles(a * 9, a * 5, 0)
		shell.CFrame = CFrame.new(pos)
		rock.Transparency = before and 0 or 1
		shell.Transparency = before and 0.45 or 1
		for i, t in ipairs(trail) do
			t.CFrame = CFrame.new(from:Lerp(hitAt, math.max(f - i * 0.035, 0)))
			t.Transparency = before and (0.3 + i * 0.08) or 1
		end
		if not before then
			if not lit then
				lit = true
				bodyTint(opts.body, Color3.fromRGB(30, 24, 22), M.Slate)
				if opts.world then
					local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 140, 50); l.Range = 30; l.Brightness = 5; l.Parent = flashB
					emit(base * CFrame.new(0, 1, 0), folder, {Texture = FIRE, Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(180, 40, 10)), Size = NumberSequence.new(1.8, 0.3),
						Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(6, 14), SpreadAngle = Vector2.new(70, 70), LightEmission = 1, Rate = 50, Acceleration = Vector3.new(0, 5, 0)})
				end
			end
			local k = seg(a, HIT, HIT + 0.25)
			flashB.Size = Vector3.one * (1 + 11 * easeOut(k))
			flashB.Transparency = 0.1 + 0.9 * k
			stepRing(wave, base, seg(a, HIT, 0.8), 9, 0.3)
			stepDebris(rocks, seg(a, HIT, 1), dt, {gravity = 34, floor = base.Position.Y, fadeFrom = 0.7}, D * (1 - HIT))
			crater.Transparency = 0.1 + 0.9 * seg(a, 0.88, 1)
		else
			wave.Transparency = 1
			hideBits(rocks)
		end
	end)
	return D
end

--------------------------------------------------------------------
--  LEGENDARY
--------------------------------------------------------------------
-- the ground cracks, a great serpent bursts out, arcs over, swallows them
-- whole and dives; a moment later it pokes up and spits out the bones
FX.SerpentsMaw = function(folder, origin, opts)
	local D = 3.4
	local BITE, DIVE, SPIT = 0.42, 0.6, 0.78
	sfx(folder, opts, origin, SND.rumble, {volume = 0.8, cut = 1.6, fade = 0.6, far = 220})
	sfx(folder, opts, origin, SND.hiss, {volume = 1, delay = 0.35})
	sfx(folder, opts, origin, SND.chomp, {volume = 1, speed = 0.6, delay = D * BITE})
	sfx(folder, opts, origin, SND.dirtHit, {volume = 0.9, speed = 0.7, delay = D * (BITE + 0.08)})
	sfx(folder, opts, origin, SND.pop, {volume = 0.8, speed = 0.45, delay = D * SPIT})
	sfx(folder, opts, origin, SND.shells, {volume = 0.8, speed = 0.75, delay = D * SPIT + 0.15})
	local base = floorOf(origin)
	local floorY = base.Position.Y
	local C0 = base.Position
	local right = origin.RightVector * Vector3.new(1, 0, 1)
	right = right.Magnitude > 0.01 and right.Unit or Vector3.xAxis
	local H = C0 + right * 7
	local ctrl = (H + C0) / 2 + Vector3.new(0, 15, 0)
	-- the arc ends at the body, just above the floor (T); past it, straight down
	local T = C0 + Vector3.new(0, 1.6, 0)
	local lift = 0
	local function bez(s)
		local pos
		if s < 0 then pos = H + (ctrl - H) * 2 * s
		elseif s > 1 then pos = T + Vector3.new(0, -9 * (s - 1), 0)
		else local u = 1 - s; pos = H * u * u + ctrl * 2 * u * s + T * s * s end
		-- after the bite it rears up with them before the dive
		return pos + Vector3.new(0, lift * seg(s, 0.6, 1), 0)
	end
	local main, belly = Color3.fromRGB(44, 92, 52), Color3.fromRGB(196, 186, 120)
	-- the head: skull and a jaw that drops open, glowing eyes, fangs
	local K = 1.6   -- the head's scale
	local skull = blob(folder, Vector3.new(1.9, 1.1, 2.5) * K, base, main)
	local jaw = blob(folder, Vector3.new(1.6, 0.45, 2.2) * K, base, belly)
	local eyes = {ball(folder, 0.34 * K, base, Color3.fromRGB(255, 220, 60), M.Neon), ball(folder, 0.34 * K, base, Color3.fromRGB(255, 220, 60), M.Neon)}
	local fangs = {wedgePart(folder, Vector3.new(0.12, 0.45, 0.16) * K, base, Color3.fromRGB(245, 240, 225)), wedgePart(folder, Vector3.new(0.12, 0.45, 0.16) * K, base, Color3.fromRGB(245, 240, 225))}
	local head = {skull, jaw, eyes[1], eyes[2], fangs[1], fangs[2]}
	local body = {}
	for j = 1, 24 do
		local d = 2.5 - j * 0.07
		table.insert(body, {p = ball(folder, d, base, j % 3 == 0 and belly or main), back = j % 2 == 0 and ball(folder, d * 0.45, base, Color3.fromRGB(30, 64, 36)) or nil})
	end
	local holes = {ring(folder, CFrame.new(H.X, floorY + 0.03, H.Z), 2.4, 0.05, Color3.fromRGB(28, 22, 18), M.Ground, 1), ring(folder, CFrame.new(C0.X, floorY + 0.03, C0.Z), 2.4, 0.05, Color3.fromRGB(28, 22, 18), M.Ground, 1)}
	local clods = debris(folder, CFrame.new(H + Vector3.new(0, 0.3, 0)), 14, function()
		local s = rng:NextNumber(0.25, 0.55)
		return part(folder, Enum.PartType.Block, Vector3.one * s, base, Color3.fromRGB(96, 72, 50), M.Ground)
	end, {speedMin = 5, speedMax = 11, upMin = 0.8, upMax = 1.6, spawnSpread = 0.6})
	local boneCol = Color3.fromRGB(226, 218, 196)
	local bones = debris(folder, CFrame.new(C0 + Vector3.new(0, 2.2, 0)), 16, function(i)
		if i == 1 then return ball(folder, 0.9, base, boneCol) end
		return part(folder, Enum.PartType.Cylinder, Vector3.new(rng:NextNumber(0.6, 1.2), 0.2, 0.2), base, boneCol)
	end, {speedMin = 2, speedMax = 6, upMin = 0.8, upMax = 1.6, spawnSpread = 0.3})
	local SEG = 0.042
	local function place(cf, open, alpha)
		skull.CFrame = cf * CFrame.new(0, 0.25 * K, -0.2 * K)
		jaw.CFrame = cf * CFrame.new(0, -0.3 * K, 0.7 * K) * CFrame.Angles(-open, 0, 0) * CFrame.new(0, 0, -0.95 * K)
		eyes[1].CFrame = cf * CFrame.new(-0.62 * K, 0.6 * K, -0.7 * K)
		eyes[2].CFrame = cf * CFrame.new(0.62 * K, 0.6 * K, -0.7 * K)
		fangs[1].CFrame = cf * CFrame.new(-0.42 * K, -0.12 * K, -1.25 * K) * CFrame.Angles(math.pi, 0, 0)
		fangs[2].CFrame = cf * CFrame.new(0.42 * K, -0.12 * K, -1.25 * K) * CFrame.Angles(math.pi, 0, 0)
		for _, p in ipairs(head) do p.Transparency = alpha end
	end
	animate(D, opts, function(a, dt)
		lift = 4 * math.sin(math.pi * seg(a, BITE, DIVE))
		-- where the head is along the arc (past 1: under the ground at the body)
		local sh
		if a < 0.12 then sh = -0.3
		elseif a < BITE then sh = -0.3 + 1.3 * easeInOut(seg(a, 0.12, BITE))
		else sh = 1 + 0.9 * easeIn(seg(a, BITE, DIVE)) end
		local open = a < BITE and math.rad(55) * seg(a, 0.24, 0.36) * (1 - seg(a, BITE - 0.03, BITE)) or 0
		for j, b in ipairs(body) do
			local s = sh - j * SEG
			local pos = bez(s)
			local hidden = pos.Y < floorY - 0.4 or a > DIVE + 0.04
			b.p.CFrame = CFrame.new(pos)
			b.p.Transparency = hidden and 1 or 0
			if b.back then
				local tan = (bez(s + 0.01) - bez(s - 0.01))
				local up = tan.Magnitude > 0.001 and tan.Unit:Cross(right) or Vector3.yAxis
				b.back.CFrame = CFrame.new(pos + up * b.p.Size.X * 0.42)
				b.back.Transparency = hidden and 1 or 0
			end
		end
		if a < DIVE + 0.04 then
			local pos = bez(sh)
			local tan = bez(sh + 0.02) - pos
			local cf = CFrame.lookAt(pos, pos + (tan.Magnitude > 0.001 and tan or Vector3.new(0, -1, 0)))
			place(cf, open, (pos.Y < floorY - 0.5) and 1 or 0)
			-- in its jaws: carried up and down with the head, gone when it's under
			if a >= BITE - 0.01 then
				local P = puppet(folder, origin, opts)
				local mouth = (cf * CFrame.new(0, -0.3 * K, -0.6 * K)).Position
				posePuppet(P, CFrame.new(mouth + Vector3.new(0, 2.2, 0)) * origin.Rotation * CFrame.Angles(0, 0, 0.4), 0.85)
				fadePuppet(P, (mouth.Y < floorY - 0.6) and 1 or 0)
			end
		elseif a >= SPIT - 0.08 and a < 0.95 then
			-- it pokes up at the body, mouth open, and spits
			local bump = math.sin(math.pi * seg(a, SPIT - 0.08, 0.95))
			local pos = C0 + Vector3.new(0, -2.4 + 5 * bump, 0)
			local cf = CFrame.lookAt(pos, pos + Vector3.new(0, 1, 0) + right * -0.5)
			place(cf, math.rad(60) * seg(a, SPIT - 0.04, SPIT), 0)
		else
			place(base, 0, 1)
		end
		if a >= DIVE + 0.04 and opts.puppetState then fadePuppet(opts.puppetState, 1) end
		for i, h in ipairs(holes) do
			local on = i == 1 and seg(a, 0.05, 0.12) or seg(a, BITE, BITE + 0.04)
			h.Transparency = 1 - on * 0.9 + seg(a, 0.9, 1) * 0.9
		end
		if a >= 0.1 then stepDebris(clods, seg(a, 0.1, 0.5), dt, {gravity = 30, floor = floorY, fadeFrom = 0.7}, D * 0.4) else hideBits(clods) end
		if a >= SPIT then
			-- the pile stays (the world's remains take over; a preview keeps them to the end)
			stepDebris(bones, seg(a, SPIT, 1), dt, {gravity = 30, floor = floorY + 0.15, fadeFrom = opts.world and 0.9 or 0.97}, D * (1 - SPIT))
		else
			hideBits(bones)
		end
	end)
	return D
end

-- clouds gather overhead and a giant hand comes down out of them: flat
FX.HeavensHand = function(folder, origin, opts)
	local D, SLAM = 3.2, 0.55
	sfx(folder, opts, origin, SND.choir, {volume = 0.55, cut = 1.6, fade = 0.4, far = 220})
	sfx(folder, opts, origin, SND.rumble, {volume = 0.6, delay = 0.3, cut = 1.4, fade = 0.3})
	sfx(folder, opts, origin, SND.thunder, {volume = 1, speed = 0.75, delay = D * SLAM, cut = 2.4, fade = 1, far = 320})
	sfx(folder, opts, origin, SND.rockBurst, {volume = 1, speed = 0.7, delay = D * SLAM})
	sfx(folder, opts, origin, SND.dirtHit, {volume = 1, speed = 0.6, delay = D * SLAM})
	local base = floorOf(origin)
	local skin = Color3.fromRGB(240, 226, 196)
	local hand = {}
	local function add(p, off) table.insert(hand, {p = p, off = off}) end
	local K = 1.6   -- the hand's scale: a palm seven studs across
	local function blk(size, off) add(part(folder, Enum.PartType.Block, size * K, base, skin, M.Marble), CFrame.new(off * K)) end
	blk(Vector3.new(4.4, 1.5, 4.2), Vector3.new(0, 0.75, 0))
	-- four fingers fanned a little, two joints each, the tips curled down
	for i, x in ipairs({-1.65, -0.55, 0.55, 1.65}) do
		local len = (i == 1) and 2.3 or 3.0
		local root = CFrame.new(Vector3.new(x, 0.62, -2.05) * K) * CFrame.Angles(0, -x * 0.09, 0)
		add(part(folder, Enum.PartType.Block, Vector3.new(0.8, 1, len * 0.55) * K, base, skin, M.Marble), root * CFrame.new(0, 0, -len * 0.27 * K))
		add(part(folder, Enum.PartType.Block, Vector3.new(0.76, 0.9, len * 0.5) * K, base, skin, M.Marble),
			root * CFrame.new(0, -0.08 * K, -len * 0.55 * K) * CFrame.Angles(math.rad(16), 0, 0) * CFrame.new(0, 0, -len * 0.25 * K))
		add(ball(folder, 0.95 * K, base, skin, M.Marble), root)
	end
	-- the thumb, out to the side
	add(part(folder, Enum.PartType.Block, Vector3.new(0.95, 0.95, 2.6) * K, base, skin, M.Marble), CFrame.new(Vector3.new(2.9, 0.6, -0.6) * K) * CFrame.Angles(0, -0.75, 0))
	-- the forearm leans back up into the clouds; a gold cuff round the wrist
	local tilt = CFrame.Angles(0.5, 0, 0)
	add(part(folder, Enum.PartType.Block, Vector3.new(3.4, 16, 3.2) * K, base, skin, M.Marble), CFrame.new(Vector3.new(0, 1.5, 1.4) * K) * tilt * CFrame.new(0, 8 * K, 0))
	add(part(folder, Enum.PartType.Cylinder, Vector3.new(1.1, 4.4, 4.2) * K, base, Color3.fromRGB(255, 205, 90), M.Neon), CFrame.new(Vector3.new(0, 1.5, 1.4) * K) * tilt * CFrame.new(0, 1.6 * K, 0) * CFrame.Angles(0, 0, math.pi / 2))
	local clouds = {}
	for i = 1, 11 do
		local ang = i / 11 * math.pi * 2
		local shade = rng:NextNumber(0.42, 0.66)
		table.insert(clouds, {p = blob(folder, Vector3.new(0.1, 0.1, 0.1), base, Color3.new(shade, shade, shade * 1.06), M.SmoothPlastic, 0.1),
			off = Vector3.new(math.cos(ang) * rng:NextNumber(4, 10), 30 + rng:NextNumber(-1.5, 2), 2 + math.sin(ang) * rng:NextNumber(4, 9)), s = rng:NextNumber(7, 11)})
	end
	local shade = ring(folder, base * CFrame.new(0, 0.04, 0), 0.2, 0.05, Color3.new(0, 0, 0), M.SmoothPlastic, 1)
	local dust = shockRing(folder, base, Color3.fromRGB(200, 190, 170))
	local flashB = ball(folder, 1, base * CFrame.new(0, 0.5, 0), Color3.fromRGB(255, 240, 200), M.Neon, 1)
	local rocks = debris(folder, base * CFrame.new(0, 0.4, 0), 18, function()
		local s = rng:NextNumber(0.3, 0.7)
		return part(folder, Enum.PartType.Block, Vector3.one * s, base, Color3.fromRGB(120, 108, 92), M.Slate)
	end, {speedMin = 7, speedMax = 15, upMin = 0.3, upMax = 1, spawnSpread = 2})
	local flat
	animate(D, opts, function(a, dt)
		local gather = easeOut(seg(a, 0, 0.2))
		local cloudFade = seg(a, 0.85, 1)
		for _, c in ipairs(clouds) do
			c.p.Size = Vector3.new(c.s, c.s * 0.5, c.s) * gather + Vector3.one * 0.05
			c.p.CFrame = base * CFrame.new(c.off + Vector3.new(0, math.sin(a * 3 + c.s) * 0.3, 0))
			c.p.Transparency = 0.15 + 0.85 * cloudFade
		end
		-- the palm's height above the floor
		local y
		if a < 0.2 then y = 28
		elseif a < 0.42 then y = 28 - 18 * easeOut(seg(a, 0.2, 0.42))
		elseif a < 0.5 then y = 10 + 2 * easeOut(seg(a, 0.42, 0.5))
		elseif a < SLAM then y = 12 * (1 - easeIn(seg(a, 0.5, SLAM)))
		elseif a < 0.75 then y = 0
		else y = 32 * easeIn(seg(a, 0.75, 1)) end
		local hc = base * CFrame.new(0, y, 1.5)
		for _, h in ipairs(hand) do
			h.p.CFrame = hc * h.off
			h.p.Transparency = (a < 0.18) and 1 or seg(a, 0.88, 1)
		end
		local near = 1 - math.clamp(y / 28, 0, 1)
		shade.Size = Vector3.new(0.05, 3 + 9 * near, 3 + 9 * near)
		shade.Transparency = (a < SLAM) and (0.95 - 0.45 * near) or 1
		if a >= SLAM then
			local k = seg(a, SLAM, SLAM + 0.15)
			flashB.Size = Vector3.one * (1 + 12 * easeOut(k))
			flashB.Transparency = 0.2 + 0.8 * k
			stepRing(dust, base, seg(a, SLAM, 0.9), 10, 0.35)
			stepDebris(rocks, seg(a, SLAM, 1), dt, {gravity = 34, floor = base.Position.Y, fadeFrom = 0.7}, D * (1 - SLAM))
			local P = puppet(folder, origin, opts)
			squashPuppet(P, base.Position.Y, 0.06)
			fadePuppet(P, seg(a, 0.92, 1))
			if #P.list == 0 and not flat then flat = flatBody(folder, base, bodyColors(opts.body, opts.colors)) end
		else
			dust.Transparency = 1
			hideBits(rocks)
		end
		if flat then fadeAll(flat, seg(a, 0.92, 1)) end
	end)
	return D
end

-- a point of nothing opens at the chest; everything spirals into it
FX.BlackHole = function(folder, origin, opts)
	local D, COLLAPSE = 2.8, 0.78
	sfx(folder, opts, origin, SND.rift, {volume = 1, speed = 0.4, cut = 2.0, fade = 0.4})
	sfx(folder, opts, origin, SND.synthRip, {volume = 0.6, speed = 0.3, delay = 0.3})
	sfx(folder, opts, origin, SND.thunder, {volume = 0.8, speed = 1.4, delay = D * COLLAPSE, cut = 1.6, fade = 0.8})
	local centre = origin * CFrame.new(0, 0.6, 0)
	local core = ball(folder, 0.2, centre, Color3.new(0, 0, 0), M.SmoothPlastic)
	local rim = ball(folder, 0.3, centre, Color3.fromRGB(170, 90, 255), M.Neon, 0.6)
	local disc = ring(folder, centre, 0.2, 0.08, Color3.fromRGB(255, 150, 60), M.Neon, 0.3)
	local disc2 = ring(folder, centre, 0.2, 0.06, Color3.fromRGB(150, 70, 255), M.Neon, 0.4)
	local cols = bodyColors(opts.body, opts.colors)
	local bits = {}
	for i = 1, 22 do
		local off = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-2.6, 1.6), rng:NextNumber(-0.6, 0.6))
		table.insert(bits, {p = part(folder, Enum.PartType.Block, Vector3.new(0.4, 0.4, 0.4), origin, cols[(i - 1) % #cols + 1]),
			r = Vector3.new(off.X, 0, off.Z).Magnitude + 1, ang = math.atan2(off.Z, off.X), y = off.Y - 0.6, sp = rng:NextNumber(4, 8)})
	end
	local flashB = ball(folder, 1, centre, Color3.fromRGB(230, 210, 255), M.Neon, 1)
	if opts.world then
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(170, 90, 255); l.Range = 18; l.Brightness = 2; l.Parent = rim
	end
	animate(D, opts, function(a)
		local open = easeOut(seg(a, 0, 0.25))
		local shut = easeIn(seg(a, COLLAPSE - 0.08, COLLAPSE))
		local size = 4.4 * open * (1 - shut)
		core.Size = Vector3.one * (size + 0.05)
		rim.Size = Vector3.one * (size * 1.07 + 0.05)
		core.Transparency = a >= COLLAPSE and 1 or 0
		rim.Transparency = a >= COLLAPSE and 1 or 0.86
		local dr = (10 * open) * (1 - shut)
		disc.Size = Vector3.new(0.08, dr + 0.01, dr + 0.01)
		disc2.Size = Vector3.new(0.06, dr * 0.75 + 0.01, dr * 0.75 + 0.01)
		disc.CFrame = centre * CFrame.Angles(0.35, a * 6, 0) * CFrame.Angles(0, 0, math.pi / 2)
		disc2.CFrame = centre * CFrame.Angles(0.35, -a * 9, 0) * CFrame.Angles(0, 0, math.pi / 2)
		disc.Transparency = a >= COLLAPSE and 1 or 0.3
		disc2.Transparency = a >= COLLAPSE and 1 or 0.4
		local k = easeIn(seg(a, 0.15, COLLAPSE - 0.05))
		-- the body itself, piece by piece, spiralling in and stretching
		local P = a >= 0.12 and puppet(folder, origin, opts) or nil
		if P and not P.spiral then
			P.spiral = {}
			for _, q in ipairs(P.list) do
				local w = origin * q.rel
				local d = w.Position - centre.Position
				table.insert(P.spiral, {r = Vector3.new(d.X, 0, d.Z).Magnitude, ang = math.atan2(d.Z, d.X), y = d.Y, sp = rng:NextNumber(3, 6), rot = w.Rotation})
			end
		end
		for i, q in ipairs(P and P.list or {}) do
			local sp = P.spiral[i]
			local ang = sp.ang + (a - 0.12) * sp.sp * (1 + 3 * k)
			local rr = sp.r * (1 - k)
			local pos = centre.Position + Vector3.new(math.cos(ang) * rr, sp.y * (1 - k), math.sin(ang) * rr)
			q.p.Size = q.size * (1 - k * 0.85)
			q.p.CFrame = CFrame.new(pos) * sp.rot * CFrame.Angles(k * 4, k * 6, 0)
			q.p.Transparency = k >= 0.97 and 1 or q.t0
		end
		-- (no body here at all: bits in its colours instead)
		local useBits = not P or #P.list == 0
		for _, b in ipairs(bits) do
			local ang = b.ang + a * b.sp * (1 + 3 * k)
			local rr = b.r * (1 - k) + 0.05
			local pos = centre * CFrame.new(math.cos(ang) * rr, b.y * (1 - k), math.sin(ang) * rr)
			-- stretched along the way in
			b.p.Size = Vector3.new(0.4 * (1 - k * 0.6), 0.4 * (1 - k * 0.6), 0.4 + 1.8 * k)
			b.p.CFrame = CFrame.lookAt(pos.Position, centre.Position)
			b.p.Transparency = (not useBits or a < 0.12 or k >= 0.98) and 1 or 0
		end
		local f = seg(a, COLLAPSE, COLLAPSE + 0.15)
		flashB.Size = Vector3.one * (1 + 9 * easeOut(f))
		flashB.Transparency = a < COLLAPSE and 1 or (0.1 + 0.9 * f)
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
