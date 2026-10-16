--[[ WARFX — a battle's sights and sounds, drawn on your screen only (nothing here replicates):
     arrow volleys arcing overhead, trebuchet fire and its blasts, the storm, horsemen on the
     hills. Pooled and moved in bulk (workspace:BulkMoveTo), so a sky full of arrows costs little.
     Used by Prologue.client (the Siege of Stormwatch) and War.client (the War mode).

       WarFX.sound(name, at, opts)        a sound from ReplicatedStorage ▸ WarAudio by name (anything
                                          missing is just quiet): 2D, or at a point · opts.volume,
                                          opts.speed, opts.range, opts.near
       WarFX.loop(name, volume)           a looping ambience (2D), faded in · the Sound or nil
       WarFX.stopLoop(sound, secs)        fades one out and lets it go
       WarFX.volley(from, to, n, opts)    n arrows loosed round `from`, falling round `to`
                                          (opts.spread, opts.flight seconds, opts.height, opts.stagger,
                                          opts.stick = false: they vanish where they land)
       WarFX.fireball(from, to, t, opts)  a burning shot on a high arc landing at `to` after t s
                                          (opts.blast = false: no blast; opts.big; opts.onLand(pos);
                                          opts.whistle: the scream of it coming down)
       WarFX.blast(pos, opts)             flash, fire, smoke, flying stones, a scorch, a boom, a shake
                                          by distance (opts.big; opts.far: no shake, a deep far boom)
       WarFX.dust(pos, size, color)       a puff of dust
       WarFX.shake(strength, secs)        the camera shakes (over whatever drives it; Settings ▸ Shake)
       WarFX.flash(k)                     the screen flashes (lightning, a blast close by)
       WarFX.storm(on, fade)              rain round the camera (not under a roof), lightning and
                                          thunder, heavy cloud · off: the rain thins out over `fade` s
       WarFX.riders(path, n, opts)        a column of horsemen riding along a list of points
                                          (opts.color, opts.speed, opts.lances) · handle:stop()
       WarFX.clear()                      everything gone (leaving the mode) ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local WarFX = {}
local V3, CF = Vector3.new, CFrame.new
local FAR = CF(0, -5000, 0)
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE_TEX = "rbxasset://textures/particles/fire_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local settings
local function shakeSetting()
	settings = settings or require(ReplicatedStorage:WaitForChild("ClientSettings"))
	local v = settings.get("Shake")
	return type(v) == "number" and v or 1
end

-- everything lives in one local folder
local folder
local function home()
	if folder and folder.Parent then return folder end
	folder = Instance.new("Folder")
	folder.Name = "WarFX"
	folder.Parent = workspace
	return folder
end

local function part(size, color, mat, transp)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size, p.Color = size, color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Transparency = transp or 0
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end
WarFX.part = part

local function emitter(parent, o)
	local e = Instance.new("ParticleEmitter")
	e.Texture = o.texture or SMOKE
	e.Color = o.color or ColorSequence.new(Color3.fromRGB(60, 56, 54))
	e.Size = o.size or NumberSequence.new(4, 12)
	e.Transparency = o.transparency or NumberSequence.new(0.35, 1)
	e.Lifetime = o.life or NumberRange.new(2, 4)
	e.Speed = o.speed or NumberRange.new(6, 14)
	e.SpreadAngle = o.spread or Vector2.new(180, 180)
	e.Acceleration = o.accel or V3(0, 2, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-40, 40)
	e.LightEmission = o.glow or 0
	e.Drag = o.drag or 1.5
	e.Rate = o.rate or 0
	e.EmissionDirection = o.dir or Enum.NormalId.Top
	e.Parent = parent
	return e
end

-- a still point in the world to hang sounds, lights and particles on
local function anchorAt(pos, life)
	local a = part(V3(0.2, 0.2, 0.2), Color3.new(), nil, 1)
	a.CFrame = CF(pos)
	a.Parent = home()
	if life then Debris:AddItem(a, life) end
	return a
end

--------------------------------------------------------------------
--  SOUND
--------------------------------------------------------------------
local function audio(name)
	local f = ReplicatedStorage:FindFirstChild("WarAudio")
	return f and f:FindFirstChild(name)
end

function WarFX.sound(name, at, opts)
	opts = opts or {}
	local src = audio(name)
	if not (src and src:IsA("Sound")) then return nil end
	local s = src:Clone()
	s.Looped = false
	s.Volume = src.Volume * (opts.volume or 1)
	s.PlaybackSpeed = opts.speed or src.PlaybackSpeed
	local holder = s
	if at then
		holder = Instance.new("Attachment")
		holder.Position = at
		holder.Parent = workspace.Terrain
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = opts.near or 40
		s.RollOffMaxDistance = opts.range or 900
		s.Parent = holder
	else
		s.Parent = SoundService
	end
	s:Play()
	local len = (s.TimeLength > 0 and s.TimeLength or 8) / math.max(s.PlaybackSpeed, 0.1)
	Debris:AddItem(holder, len + 0.5)
	return s
end

function WarFX.loop(name, volume)
	local src = audio(name)
	if not (src and src:IsA("Sound")) then return nil end
	local s = src:Clone()
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	s:Play()
	TweenService:Create(s, TweenInfo.new(2), {Volume = src.Volume * (volume or 1)}):Play()
	return s
end

function WarFX.stopLoop(s, secs)
	if not (s and s.Parent) then return end
	TweenService:Create(s, TweenInfo.new(secs or 2), {Volume = 0}):Play()
	Debris:AddItem(s, (secs or 2) + 0.2)
end

--------------------------------------------------------------------
--  THE CAMERA: shake, flash
--------------------------------------------------------------------
local trauma, decay = 0, 1
local function bindShake()
	pcall(function() RunService:UnbindFromRenderStep("WarFXShake") end)
	RunService:BindToRenderStep("WarFXShake", Enum.RenderPriority.Camera.Value + 40, function(dt)
		if trauma <= 0 then return end
		trauma = math.max(0, trauma - decay * dt)
		local cam = workspace.CurrentCamera
		if not cam then return end
		local k = trauma * trauma * 1.6
		cam.CFrame = cam.CFrame * CFrame.Angles(math.rad((math.random() - 0.5) * 2 * k), math.rad((math.random() - 0.5) * 2 * k), math.rad((math.random() - 0.5) * k))
	end)
end
local shakeBound = false
function WarFX.shake(strength, secs)
	strength = (strength or 1) * shakeSetting()
	if strength <= 0.02 then return end
	if strength > trauma then
		trauma = strength
		decay = strength / math.max(secs or 0.6, 0.1)
	end
	if not shakeBound then shakeBound = true; bindShake() end
end

local cc
function WarFX.flash(k)
	if not (cc and cc.Parent) then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "WarFXFlash"
		cc.Parent = Lighting
	end
	cc.Brightness = k or 0.4
	TweenService:Create(cc, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Brightness = 0}):Play()
end

--------------------------------------------------------------------
--  THE LOOP: arrows, shots, flying stones, horsemen (one connection, bulk moves)
--------------------------------------------------------------------
local pool, flying, stuck = {}, {}, {}
local shots, stones, columns = {}, {}, {}
local MAX_STUCK = 260
local ARROW = Color3.fromRGB(86, 66, 46)
local FLETCH = Color3.fromRGB(226, 220, 206)
local loopConn

local function newArrow()
	local shaft = part(V3(0.13, 0.13, 3.4), ARROW, Enum.Material.Wood)
	local tail = part(V3(0.36, 0.05, 0.75), FLETCH)
	shaft.CFrame, tail.CFrame = FAR, FAR
	return {shaft, tail}
end
local function takeArrow()
	local a = table.remove(pool) or newArrow()
	local h = home()
	if a[1].Parent ~= h then a[1].Parent = h; a[2].Parent = h end
	return a
end
local function giveBack(a)
	a[1].CFrame, a[2].CFrame = FAR, FAR
	table.insert(pool, a)
end

local function arrowCF(p0, p1, h, u)
	local pos = p0:Lerp(p1, u) + V3(0, 4 * h * u * (1 - u), 0)
	local vel = (p1 - p0) + V3(0, 4 * h * (1 - 2 * u), 0)
	return CFrame.lookAt(pos, pos + vel)
end

local bulkParts, bulkCFs = {}, {}
local function step(dt)
	local now = os.clock()
	table.clear(bulkParts); table.clear(bulkCFs)
	local n = 0
	local function put(p, cf) n += 1; bulkParts[n] = p; bulkCFs[n] = cf end
	-- arrows in the air
	for i = #flying, 1, -1 do
		local f = flying[i]
		local u = (now - f.t0) / f.T
		if u >= 1 then
			table.remove(flying, i)
			if f.stick then
				-- in the ground (or a roof), along the line it fell
				local cf = arrowCF(f.p0, f.p1, f.h, 1) * CF(0, 0, 0.7)
				put(f.a[1], cf); put(f.a[2], cf * CF(0, 0, 1.45))
				table.insert(stuck, {a = f.a, til = now + f.stick})
				if #stuck > MAX_STUCK then giveBack(table.remove(stuck, 1).a) end
			else
				giveBack(f.a)
			end
		elseif u > 0 then
			local cf = arrowCF(f.p0, f.p1, f.h, u)
			put(f.a[1], cf); put(f.a[2], cf * CF(0, 0, 1.45))
		end
	end
	for i = #stuck, 1, -1 do
		if now > stuck[i].til then giveBack(table.remove(stuck, i).a) end
	end
	-- trebuchet shots
	for i = #shots, 1, -1 do
		local s = shots[i]
		local u = (now - s.t0) / s.T
		if u >= 1 then
			table.remove(shots, i)
			s.ball.Transparency = 1
			for _, d in ipairs(s.ball:GetChildren()) do
				if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Light") then d.Enabled = false end
			end
			Debris:AddItem(s.ball, 3)
			if s.opts.blast ~= false then WarFX.blast(s.p1, {big = s.opts.big, far = s.opts.far}) end
			if s.opts.onLand then task.spawn(s.opts.onLand, s.p1) end
		else
			if s.opts.whistle and not s.whistled and (1 - u) * s.T <= 2.3 then
				s.whistled = true
				WarFX.sound("Incoming", s.p1, {range = 260, near = 30})
			end
			put(s.ball, arrowCF(s.p0, s.p1, s.h, math.max(u, 0)))
		end
	end
	-- stones thrown by a blast
	for i = #stones, 1, -1 do
		local s = stones[i]
		s.t += dt
		if s.t > s.life then
			table.remove(stones, i)
			s.p:Destroy()
		elseif not s.rest then
			s.vel += V3(0, -110 * dt, 0)
			s.pos += s.vel * dt
			if s.pos.Y < s.floor then s.pos = V3(s.pos.X, s.floor, s.pos.Z); s.rest = true end
			put(s.p, CF(s.pos) * CFrame.Angles(s.spin.X * s.t, s.spin.Y * s.t, s.spin.Z * s.t))
		end
	end
	-- horsemen
	for i = #columns, 1, -1 do
		local c = columns[i]
		if c.dead then table.remove(columns, i) else c.step(now, put) end
	end
	if n > 0 then workspace:BulkMoveTo(bulkParts, bulkCFs, Enum.BulkMoveMode.FireCFrameChanged) end
end

local function ensureLoop()
	if loopConn and loopConn.Connected then return end
	loopConn = RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(step, dt)
		if not ok then warn("[WarFX] " .. tostring(err)) end
	end)
end

--------------------------------------------------------------------
--  ARROWS
--------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function refreshFilter()
	local list = {home()}
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then table.insert(list, npcs) end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(list, p.Character) end end
	rayParams.FilterDescendantsInstances = list
end
local function ground(p)
	local r = workspace:Raycast(p + V3(0, 90, 0), V3(0, -220, 0), rayParams)
	return r and r.Position or p
end
WarFX.ground = function(p) refreshFilter(); return ground(p) end

function WarFX.volley(from, to, n, opts)
	opts = opts or {}
	ensureLoop()
	refreshFilter()
	local spread = opts.spread or 14
	local T = opts.flight or 2.6
	local dist = (to - from).Magnitude
	local h = opts.height or math.clamp(dist * 0.32, 18, 150)
	local now = os.clock()
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or to
	for _ = 1, n do
		local a = takeArrow()
		local p0 = from + V3((math.random() - 0.5) * spread, math.random() * 2, (math.random() - 0.5) * spread)
		local p1 = ground(to + V3((math.random() - 0.5) * spread * 1.7, 0, (math.random() - 0.5) * spread * 1.7))
		local stick = opts.stick ~= false and (p1 - camPos).Magnitude < (opts.stickRange or 170)
		table.insert(flying, {a = a, p0 = p0, p1 = p1, h = h * (0.9 + math.random() * 0.2),
			t0 = now + math.random() * (opts.stagger or 0.6), T = T * (0.92 + math.random() * 0.16),
			stick = stick and (opts.stickTime or 12) or nil})
	end
	-- the hiss as they come down
	if opts.sound ~= false then
		task.delay(math.max(T - 1.4, 0), function() WarFX.sound("Arrows", to, {range = opts.range or 320, near = 50}) end)
	end
end

--------------------------------------------------------------------
--  TREBUCHET FIRE
--------------------------------------------------------------------
function WarFX.fireball(from, to, T, opts)
	opts = opts or {}
	ensureLoop()
	local ball = part(V3(3.4, 3.4, 3.4), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
	ball.Shape = Enum.PartType.Ball
	ball.CFrame = CF(from)
	local fire = Instance.new("Fire")
	fire.Size, fire.Heat = 9, 0
	fire.Color, fire.SecondaryColor = Color3.fromRGB(255, 150, 50), Color3.fromRGB(200, 50, 10)
	fire.Parent = ball
	local light = Instance.new("PointLight")
	light.Range, light.Brightness, light.Color = 36, 3, Color3.fromRGB(255, 150, 60)
	light.Parent = ball
	local a0 = Instance.new("Attachment"); a0.Position = V3(0, 1.3, 0); a0.Parent = ball
	local a1 = Instance.new("Attachment"); a1.Position = V3(0, -1.3, 0); a1.Parent = ball
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime, trail.LightEmission, trail.FaceCamera = 0.7, 1, true
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 190, 90), Color3.fromRGB(140, 40, 10))
	trail.Transparency = NumberSequence.new(0.15, 1)
	trail.WidthScale = NumberSequence.new(1, 0.2)
	trail.Parent = ball
	emitter(ball, {rate = 26, life = NumberRange.new(1.6, 2.6), size = NumberSequence.new(3, 9), speed = NumberRange.new(0.5, 2),
		color = ColorSequence.new(Color3.fromRGB(40, 36, 34)), transparency = NumberSequence.new(0.45, 1)})
	ball.Parent = home()
	local dist = (to - from).Magnitude
	table.insert(shots, {ball = ball, p0 = from, p1 = to, t0 = os.clock(), T = T, h = opts.height or math.clamp(dist * 0.42, 40, 240), opts = opts})
	return ball
end

function WarFX.blast(pos, opts)
	opts = opts or {}
	ensureLoop()
	local big = opts.big
	local cam = workspace.CurrentCamera
	local d = cam and (cam.CFrame.Position - pos).Magnitude or 0
	-- the fireball itself, swelling and gone
	local orb = part(V3(2, 2, 2), Color3.fromRGB(255, 176, 70), Enum.Material.Neon)
	orb.Shape = Enum.PartType.Ball
	orb.CFrame = CF(pos + V3(0, 1, 0))
	orb.Parent = home()
	TweenService:Create(orb, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = V3(1, 1, 1) * (big and 24 or 13), Transparency = 1}):Play()
	Debris:AddItem(orb, 0.6)
	-- light, smoke, sparks, flame
	local a = anchorAt(pos + V3(0, 2, 0), 7)
	local light = Instance.new("PointLight")
	light.Range, light.Brightness, light.Color = big and 60 or 40, 9, Color3.fromRGB(255, 150, 70)
	light.Parent = a
	TweenService:Create(light, TweenInfo.new(1.4, Enum.EasingStyle.Quad), {Brightness = 0}):Play()
	emitter(a, {life = NumberRange.new(3, 5.5), size = NumberSequence.new({NumberSequenceKeypoint.new(0, big and 7 or 4), NumberSequenceKeypoint.new(1, big and 22 or 13)}),
		speed = NumberRange.new(6, big and 22 or 14), color = ColorSequence.new(Color3.fromRGB(46, 42, 40)), accel = V3(0, 3, 0)}):Emit(big and 22 or 12)
	emitter(a, {texture = SPARK, life = NumberRange.new(0.6, 1.4), size = NumberSequence.new(1.2, 0), speed = NumberRange.new(30, 70),
		color = ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 90, 20)), transparency = NumberSequence.new(0, 1), glow = 1, accel = V3(0, -60, 0), drag = 0.5}):Emit(big and 40 or 22)
	emitter(a, {texture = FIRE_TEX, life = NumberRange.new(0.35, 0.8), size = NumberSequence.new(big and 10 or 6, 2), speed = NumberRange.new(8, 22),
		color = ColorSequence.new(Color3.fromRGB(255, 180, 70), Color3.fromRGB(255, 70, 20)), transparency = NumberSequence.new(0.1, 1), glow = 1, accel = V3(0, 10, 0)}):Emit(big and 16 or 9)
	-- stones and splinters thrown up
	for _ = 1, big and 10 or 5 do
		local r = 0.5 + math.random() * (big and 1.4 or 0.9)
		local s = part(V3(r, r * 0.8, r * 1.1), math.random() < 0.5 and Color3.fromRGB(70, 66, 62) or Color3.fromRGB(96, 74, 52), Enum.Material.Slate)
		s.CFrame = CF(pos)
		s.Parent = home()
		local ang = math.random() * math.pi * 2
		local sp = 16 + math.random() * (big and 34 or 22)
		table.insert(stones, {p = s, pos = pos + V3(0, 1, 0), vel = V3(math.cos(ang) * sp, 26 + math.random() * 36, math.sin(ang) * sp),
			spin = V3(math.random() * 10, math.random() * 10, math.random() * 10), t = 0, life = 4 + math.random() * 3, floor = pos.Y + r * 0.3})
	end
	-- a black scorch where it hit, for a while
	local sc = part(V3(0.2, big and 17 or 10, big and 17 or 10), Color3.fromRGB(22, 18, 16), Enum.Material.Slate, 0.2)
	sc.Shape = Enum.PartType.Cylinder
	sc.CFrame = CF(pos + V3(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	sc.Parent = home()
	task.delay(22, function() if sc.Parent then TweenService:Create(sc, TweenInfo.new(3), {Transparency = 1}):Play() end end)
	Debris:AddItem(sc, 26)
	if big then
		local burn = anchorAt(pos + V3(0, 1, 0), 9)
		local f = Instance.new("Fire")
		f.Size, f.Heat = 7, 6
		f.Color, f.SecondaryColor = Color3.fromRGB(255, 140, 40), Color3.fromRGB(180, 40, 10)
		f.Parent = burn
		task.delay(6, function() if f.Parent then f.Enabled = false end end)
	end
	-- the boom, and the ground under you jumping
	if opts.far then
		WarFX.sound("Impact", pos, {volume = 0.9, speed = 0.82, range = 2400, near = 260})
	else
		WarFX.sound("Impact", pos, {range = 1400, near = 70, speed = 0.95 + math.random() * 0.1})
		local k = (big and 2.6 or 1.5) * math.clamp(1 - d / 240, 0, 1)
		if k > 0.05 then WarFX.shake(k, 0.45 + k * 0.3) end
		if d < 40 then WarFX.flash(0.25 * (1 - d / 40)) end
	end
end

function WarFX.dust(pos, size, color)
	size = size or 1
	local a = anchorAt(pos, 5)
	emitter(a, {life = NumberRange.new(1.4, 2.6), size = NumberSequence.new(3 * size, 9 * size), speed = NumberRange.new(5, 12),
		color = ColorSequence.new(color or Color3.fromRGB(140, 128, 112)), transparency = NumberSequence.new(0.35, 1), accel = V3(0, 1.5, 0)}):Emit(math.floor(12 * size))
end

--------------------------------------------------------------------
--  THE STORM: rain round the camera, lightning, cloud
--------------------------------------------------------------------
local storm = nil
local function bolt(at)
	local h = home()
	local segs = {}
	local p = at + V3(0, 330, 0)
	local function line(a, b, w)
		local s = part(V3(w, w, (b - a).Magnitude), Color3.fromRGB(220, 230, 255), Enum.Material.Neon)
		s.CFrame = CFrame.lookAt((a + b) / 2, b)
		s.Parent = h
		table.insert(segs, s)
	end
	for i = 1, 9 do
		local q = V3(at.X + (math.random() - 0.5) * 50, 330 - i * 34, at.Z + (math.random() - 0.5) * 50)
		line(p, q, 1.6)
		if math.random() < 0.35 then
			local b = q + V3((math.random() - 0.5) * 70, -30 - math.random() * 30, (math.random() - 0.5) * 70)
			line(q, b, 0.8)
		end
		p = q
	end
	task.spawn(function()
		task.wait(0.07)
		for _, s in ipairs(segs) do s.Transparency = 1 end
		task.wait(0.06)
		for _, s in ipairs(segs) do s.Transparency = 0 end
		task.wait(0.1)
		for _, s in ipairs(segs) do s:Destroy() end
	end)
end

function WarFX.lightning(near)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local c = cam.CFrame.Position
	local ang = math.random() * math.pi * 2
	local dist = near and (90 + math.random() * 80) or (240 + math.random() * 300)
	local at = V3(c.X + math.cos(ang) * dist, 0, c.Z + math.sin(ang) * dist)
	bolt(at)
	WarFX.flash(near and 0.55 or 0.3)
	task.delay(0.15, function() WarFX.flash(near and 0.35 or 0.18) end)
	task.delay(dist / 1000, function()
		WarFX.sound("Thunder", nil, {volume = near and 1.2 or (0.55 + math.random() * 0.3), speed = 0.9 + math.random() * 0.2})
		if near then WarFX.shake(0.8, 0.8) end
	end)
end

function WarFX.storm(on, fade)
	if on then
		if storm then return end
		local s = {drops = {}, visible = true, n = 220, alive = true}
		storm = s
		local h = home()
		for i = 1, s.n do
			local d = part(V3(0.07, 0.07, 3), Color3.fromRGB(168, 184, 210), Enum.Material.SmoothPlastic, 0.5)
			d.CFrame = FAR
			d.Parent = h
			s.drops[i] = {p = d, pos = nil}
		end
		local WIND = V3(16, -110, 7)
		local parts, cfs = {}, {}
		local up = RaycastParams.new()
		up.FilterType = Enum.RaycastFilterType.Exclude
		local nextRoof = 0
		s.conn = RunService.RenderStepped:Connect(function(dt)
			local cam = workspace.CurrentCamera
			if not cam then return end
			local c = cam.CFrame.Position
			local now = os.clock()
			-- under a roof (or deep in the keep): no rain in your face
			if now > nextRoof then
				nextRoof = now + 0.3
				local char = Players.LocalPlayer.Character
				up.FilterDescendantsInstances = {h, char}
				local roofed = workspace:Raycast(c, V3(0, 60, 0), up) ~= nil
				if roofed == s.visible then
					s.visible = not roofed
					for _, dr in ipairs(s.drops) do dr.p.Transparency = s.visible and 0.5 or 1 end
				end
			end
			if not s.visible then return end
			table.clear(parts); table.clear(cfs)
			local live = s.n
			for i, dr in ipairs(s.drops) do
				if i > live then break end
				local p = dr.pos
				if not p or p.Y < c.Y - 28 or math.abs(p.X - c.X) > 40 or math.abs(p.Z - c.Z) > 40 then
					p = V3(c.X + (math.random() - 0.5) * 80, c.Y + 10 + math.random() * 40, c.Z + (math.random() - 0.5) * 80)
				end
				p += WIND * dt
				dr.pos = p
				parts[i] = dr.p
				cfs[i] = CFrame.lookAt(p, p + WIND)
			end
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		end)
		-- lightning, now and then
		task.spawn(function()
			task.wait(2)
			while storm == s and s.alive do
				WarFX.lightning(math.random() < 0.15)
				task.wait(5 + math.random() * 8)
			end
		end)
		-- heavy cloud
		local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
		s.hadClouds = clouds ~= nil
		if not clouds then clouds = Instance.new("Clouds"); clouds.Parent = workspace.Terrain end
		s.clouds, s.oldClouds = clouds, {Cover = clouds.Cover, Density = clouds.Density, Color = clouds.Color}
		clouds.Cover, clouds.Density, clouds.Color = 0.86, 0.75, Color3.fromRGB(50, 56, 70)
		return
	end
	local s = storm
	if not s then return end
	storm = nil
	s.alive = false
	task.spawn(function()
		-- the rain thins out
		local steps = math.max(1, math.floor((fade or 0) / 0.1))
		for i = steps, 1, -1 do
			for j = math.floor(s.n * i / steps) + 1, #s.drops do s.drops[j].p.CFrame = FAR end
			s.n = math.floor(#s.drops * (i - 1) / steps)
			task.wait(0.1)
		end
		if s.conn then s.conn:Disconnect() end
		for _, dr in ipairs(s.drops) do dr.p:Destroy() end
		if s.clouds and s.clouds.Parent then
			if s.hadClouds then
				for k, v in pairs(s.oldClouds) do s.clouds[k] = v end
			else
				s.clouds:Destroy()
			end
		end
	end)
end

--------------------------------------------------------------------
--  HORSEMEN: a column riding along a path (each horse and rider a handful of parts)
--------------------------------------------------------------------
local HORSES = {Color3.fromRGB(70, 48, 32), Color3.fromRGB(40, 32, 28), Color3.fromRGB(120, 92, 64), Color3.fromRGB(200, 196, 186)}
local function horseman(color, lance)
	local h = home()
	local coat = HORSES[math.random(#HORSES)]
	local steel = Color3.fromRGB(150, 152, 158)
	local list = {}
	local function add(size, col, mat, offset)
		local p = part(size, col, mat)
		p.CFrame = FAR
		p.Parent = h
		table.insert(list, {p = p, off = offset})
		return #list
	end
	add(V3(2.3, 2.4, 5.4), coat, nil, CF(0, 3.6, 0))                                                 -- barrel
	add(V3(2.36, 1.2, 4.6), color, Enum.Material.Fabric, CF(0, 3.1, 0))                              -- caparison
	add(V3(1.3, 2.6, 1.5), coat, nil, CF(0, 5.2, -2.7) * CFrame.Angles(math.rad(-30), 0, 0))        -- neck
	add(V3(1.1, 1.1, 2.4), coat, nil, CF(0, 6.1, -3.8) * CFrame.Angles(math.rad(-50), 0, 0))        -- head
	local legs = {}
	for _, l in ipairs({{-0.7, -2}, {0.7, -2}, {-0.7, 2}, {0.7, 2}}) do
		legs[add(V3(0.55, 2.8, 0.55), coat, nil, CF(l[1], 1.4, l[2]))] = l[2] < 0 and 0 or 1.6
	end
	add(V3(0.4, 2.2, 0.5), coat, nil, CF(0, 3.6, 2.9) * CFrame.Angles(math.rad(30), 0, 0))           -- tail
	add(V3(1.9, 2, 1.1), color, Enum.Material.Fabric, CF(0, 5.9, 0.3))                               -- rider's coat
	add(V3(1.2, 1.2, 1.2), steel, Enum.Material.Metal, CF(0, 7.5, 0.3))                              -- helm
	if lance then
		add(V3(0.22, 0.22, 11), Color3.fromRGB(110, 84, 56), Enum.Material.Wood, CF(1.1, 6.6, -2.6) * CFrame.Angles(math.rad(-12), 0, 0))
		add(V3(0.06, 0.9, 1.6), color, Enum.Material.Fabric, CF(1.1, 7.6, -6.6) * CFrame.Angles(math.rad(-12), 0, 0))
	end
	return list, legs
end

local function pathAt(path, lens, s)
	if s <= 0 then return path[1], (path[2] - path[1]).Unit end
	for i = 1, #path - 1 do
		if s <= lens[i] then
			local d = path[i + 1] - path[i]
			return path[i] + d.Unit * s, d.Unit
		end
		s -= lens[i]
	end
	local d = path[#path] - path[#path - 1]
	return path[#path], d.Unit
end

function WarFX.riders(path, n, opts)
	opts = opts or {}
	ensureLoop()
	local lens, total = {}, 0
	for i = 1, #path - 1 do lens[i] = (path[i + 1] - path[i]).Magnitude; total += lens[i] end
	local riders = {}
	for i = 1, n do
		local list, legs = horseman(opts.color or Color3.fromRGB(60, 90, 200), opts.lances ~= false)
		riders[i] = {list = list, legs = legs, row = math.floor((i - 1) / 3), col = ((i - 1) % 3) - 1, phase = math.random() * 6, jit = math.random() * 2}
	end
	local speed = opts.speed or 46
	local t0 = os.clock()
	local col = {dead = false}
	col.step = function(now, put)
		local t = now - t0
		local lead = t * speed
		for _, r in ipairs(riders) do
			local s = lead - r.row * 8 - r.jit
			local pos, dir = pathAt(path, lens, math.clamp(s, 0, total))
			local gallop = t * 11 + r.phase
			local base = CFrame.lookAt(pos, pos + V3(dir.X, 0, dir.Z)) * CF(r.col * 4.2, math.abs(math.sin(gallop)) * 0.5, 0)
			for k, e in ipairs(r.list) do
				local leg = r.legs[k]
				if leg then
					put(e.p, base * e.off * CF(0, 1.4, 0) * CFrame.Angles(math.sin(gallop + leg) * 0.6, 0, 0) * CF(0, -1.4, 0))
				else
					put(e.p, base * e.off)
				end
			end
		end
		if lead - (#riders / 3) * 8 > total + 10 and not opts.hold then col.stop() end
	end
	col.stop = function()
		if col.dead then return end
		col.dead = true
		for _, r in ipairs(riders) do for _, e in ipairs(r.list) do e.p:Destroy() end end
	end
	table.insert(columns, col)
	return col
end

--------------------------------------------------------------------
function WarFX.clear()
	WarFX.storm(false, 0)
	for _, f in ipairs(flying) do giveBack(f.a) end
	for _, s in ipairs(stuck) do giveBack(s.a) end
	table.clear(flying); table.clear(stuck)
	for _, s in ipairs(shots) do s.ball:Destroy() end
	for _, s in ipairs(stones) do s.p:Destroy() end
	table.clear(shots); table.clear(stones)
	for _, c in ipairs(columns) do c.stop() end
	table.clear(columns)
	trauma = 0
end

return WarFX
