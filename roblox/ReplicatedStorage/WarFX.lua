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
                                          opts.scorch = false: no burnt mark; opts.floor: where its
                                          stones come to rest, if not where it lands;
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
       WarFX.strike(pos, opts)            a bolt from the sky onto a point (a battle-mage's lightning)
       WarFX.frost(pos, r)                a burst of ice and cold mist (a battle-mage's frost)
       WarFX.weather(kind, fade)          "storm" (= WarFX.storm), "rain", "snow", "embers", "petals", or nil: off
       WarFX.column(pos, opts)            a column of smoke rising high over a fire (opts.scale, opts.fire:
                                          flames at its foot, opts.dark) · handle:stop()
       WarFX.haze(pos, opts)              a low drifting haze of dust and smoke over a melee · handle:move(pos),
                                          handle:stop()
       WarFX.loop3D(name, pos, opts)      a looping sound at a point (opts.volume, opts.near, opts.range) ·
                                          handle:move(pos), handle:stop(fade)
       WarFX.clear()                      everything gone (leaving the mode)
     A fireball takes opts.color (a battle-mage's meteor) and opts.size; a blast opts.color. ]]

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

-- two local folders: the world's (fire, lights, smoke, scorches) and the camera's for the crowds
-- (arrows, raindrops, soldiers, horsemen, flying stones): parts under the camera are drawn but
-- never enter the physics world, so moving thousands of them each frame stays cheap
local folder, crowdFolder
local function home()
	if folder and folder.Parent then return folder end
	folder = Instance.new("Folder")
	folder.Name = "WarFX"
	folder.Parent = workspace
	return folder
end
local function crowd()
	local cam = workspace.CurrentCamera
	if crowdFolder and crowdFolder.Parent and crowdFolder.Parent == cam then return crowdFolder end
	crowdFolder = Instance.new("Folder")
	crowdFolder.Name = "WarFXCrowd"
	crowdFolder.Parent = cam or workspace
	return crowdFolder
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
	local h = crowd()
	local a = table.remove(pool)
	if a and a[1].Parent ~= h then
		local ok = pcall(function() a[1].Parent = h; a[2].Parent = h end)
		if not ok then a = nil end
	end
	if not a then a = newArrow(); a[1].Parent = h; a[2].Parent = h end
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
			if s.opts.blast ~= false then WarFX.blast(s.p1, {big = s.opts.big, far = s.opts.far, color = s.opts.color, scorch = s.opts.scorch, floor = s.opts.floor}) end
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
	local list = {home(), crowd()}
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
	local col = opts.color or Color3.fromRGB(255, 140, 40)
	local sz = opts.size or 3.4
	local ball = part(V3(sz, sz, sz), col, Enum.Material.Neon)
	ball.Shape = Enum.PartType.Ball
	ball.CFrame = CF(from)
	local fire = Instance.new("Fire")
	fire.Size, fire.Heat = sz * 2.6, 0
	fire.Color = opts.color and col:Lerp(Color3.new(1, 1, 1), 0.3) or Color3.fromRGB(255, 150, 50)
	fire.SecondaryColor = opts.color and col:Lerp(Color3.new(), 0.4) or Color3.fromRGB(200, 50, 10)
	fire.Parent = ball
	local light = Instance.new("PointLight")
	light.Range, light.Brightness, light.Color = 36, 3, col
	light.Parent = ball
	local a0 = Instance.new("Attachment"); a0.Position = V3(0, 1.3, 0); a0.Parent = ball
	local a1 = Instance.new("Attachment"); a1.Position = V3(0, -1.3, 0); a1.Parent = ball
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime, trail.LightEmission, trail.FaceCamera = 0.7, 1, true
	trail.Color = opts.color and ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.4), col:Lerp(Color3.new(), 0.5)) or ColorSequence.new(Color3.fromRGB(255, 190, 90), Color3.fromRGB(140, 40, 10))
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
	local tint = opts.color
	local orb = part(V3(2, 2, 2), tint or Color3.fromRGB(255, 176, 70), Enum.Material.Neon)
	orb.Shape = Enum.PartType.Ball
	orb.CFrame = CF(pos + V3(0, 1, 0))
	orb.Parent = home()
	TweenService:Create(orb, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = V3(1, 1, 1) * (big and 24 or 13), Transparency = 1}):Play()
	Debris:AddItem(orb, 0.6)
	-- light, smoke, sparks, flame
	local a = anchorAt(pos + V3(0, 2, 0), 7)
	local light = Instance.new("PointLight")
	light.Range, light.Brightness, light.Color = big and 60 or 40, 9, tint or Color3.fromRGB(255, 150, 70)
	light.Parent = a
	TweenService:Create(light, TweenInfo.new(1.4, Enum.EasingStyle.Quad), {Brightness = 0}):Play()
	emitter(a, {life = NumberRange.new(3, 5.5), size = NumberSequence.new({NumberSequenceKeypoint.new(0, big and 7 or 4), NumberSequenceKeypoint.new(1, big and 22 or 13)}),
		speed = NumberRange.new(6, big and 22 or 14), color = ColorSequence.new(Color3.fromRGB(46, 42, 40)), accel = V3(0, 3, 0)}):Emit(big and 22 or 12)
	emitter(a, {texture = SPARK, life = NumberRange.new(0.6, 1.4), size = NumberSequence.new(1.2, 0), speed = NumberRange.new(30, 70),
		color = tint and ColorSequence.new(tint:Lerp(Color3.new(1, 1, 1), 0.5), tint) or ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 90, 20)), transparency = NumberSequence.new(0, 1), glow = 1, accel = V3(0, -60, 0), drag = 0.5}):Emit(big and 40 or 22)
	emitter(a, {texture = FIRE_TEX, life = NumberRange.new(0.35, 0.8), size = NumberSequence.new(big and 10 or 6, 2), speed = NumberRange.new(8, 22),
		color = tint and ColorSequence.new(tint:Lerp(Color3.new(1, 1, 1), 0.3), tint) or ColorSequence.new(Color3.fromRGB(255, 180, 70), Color3.fromRGB(255, 70, 20)), transparency = NumberSequence.new(0.1, 1), glow = 1, accel = V3(0, 10, 0)}):Emit(big and 16 or 9)
	-- stones and splinters thrown up
	for _ = 1, big and 10 or 5 do
		local r = 0.5 + math.random() * (big and 1.4 or 0.9)
		local s = part(V3(r, r * 0.8, r * 1.1), math.random() < 0.5 and Color3.fromRGB(70, 66, 62) or Color3.fromRGB(96, 74, 52), Enum.Material.Slate)
		s.CFrame = CF(pos)
		s.Parent = crowd()
		local ang = math.random() * math.pi * 2
		local sp = 16 + math.random() * (big and 34 or 22)
		table.insert(stones, {p = s, pos = pos + V3(0, 1, 0), vel = V3(math.cos(ang) * sp, 26 + math.random() * 36, math.sin(ang) * sp),
			spin = V3(math.random() * 10, math.random() * 10, math.random() * 10), t = 0, life = 4 + math.random() * 3, floor = (opts.floor or pos.Y) + r * 0.3})
	end
	-- a black scorch where it hit, for a while (not where nothing flat is: a roof, a wall's top)
	local sc = opts.scorch ~= false and part(V3(0.2, big and 17 or 10, big and 17 or 10), Color3.fromRGB(22, 18, 16), Enum.Material.Slate, 0.2)
	if sc then
		sc.Shape = Enum.PartType.Cylinder
		sc.CFrame = CF(pos + V3(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
		sc.Parent = home()
		task.delay(22, function() if sc.Parent then TweenService:Create(sc, TweenInfo.new(3), {Transparency = 1}):Play() end end)
		Debris:AddItem(sc, 26)
	end
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

-- A COLUMN OF SMOKE over a burning thing: big soft puffs rising and spreading, darker at the
-- foot, lit orange from below when there's fire there
function WarFX.column(pos, opts)
	opts = opts or {}
	local k = opts.scale or 1
	local a = anchorAt(pos)
	local dark = opts.dark ~= false
	local e = emitter(a, {rate = 3.2 * math.max(k, 0.5), life = NumberRange.new(14, 20),
		size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10 * k), NumberSequenceKeypoint.new(0.5, 32 * k), NumberSequenceKeypoint.new(1, 60 * k)}),
		speed = NumberRange.new(9 * k, 14 * k), spread = Vector2.new(9, 9), accel = V3(2.5, 1.2, 1),
		color = dark and ColorSequence.new(Color3.fromRGB(34, 30, 28), Color3.fromRGB(88, 84, 82)) or ColorSequence.new(Color3.fromRGB(120, 116, 110), Color3.fromRGB(170, 166, 160)),
		transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(1, 1)}), drag = 0.2})
	e.LightInfluence = 0.6
	local h = {anchor = a}
	if opts.fire then
		local f = Instance.new("Fire")
		f.Size, f.Heat = 12 * k, 16
		f.Color, f.SecondaryColor = Color3.fromRGB(255, 140, 40), Color3.fromRGB(190, 40, 10)
		f.Parent = a
		emitter(a, {texture = FIRE_TEX, rate = 14 * k, life = NumberRange.new(0.6, 1.2), size = NumberSequence.new(6 * k, 1), speed = NumberRange.new(6, 12),
			color = ColorSequence.new(Color3.fromRGB(255, 190, 80), Color3.fromRGB(255, 70, 20)), transparency = NumberSequence.new(0.15, 1), glow = 1, accel = V3(0, 8, 0), spread = Vector2.new(25, 25)})
		local l = Instance.new("PointLight")
		l.Range, l.Brightness, l.Color = math.min(60, 30 * k), 2.4, Color3.fromRGB(255, 130, 50)
		l.Parent = a
		h.light = l
	end
	function h.stop() if a.Parent then a:Destroy() end end
	return h
end

-- A HAZE over a melee: dust and smoke drifting low, kicked up by thousands of feet
function WarFX.haze(pos, opts)
	opts = opts or {}
	local a = anchorAt(pos)
	a.Size = V3(opts.width or 40, 1, opts.depth or 16)
	local e = emitter(a, {rate = opts.rate or 6, life = NumberRange.new(6, 10), size = NumberSequence.new(8, 22),
		speed = NumberRange.new(1, 3), spread = Vector2.new(60, 60), accel = V3(1.5, 0.6, 0.5), drag = 0.5,
		color = ColorSequence.new(opts.color or Color3.fromRGB(150, 136, 116)), transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.72), NumberSequenceKeypoint.new(1, 1)})})
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.LightInfluence = 0.8
	local h = {anchor = a, emitter = e}
	function h.move(p) if a.Parent then a.CFrame = CF(p) end end
	function h.stop() if a.Parent then a:Destroy() end end
	return h
end

-- A SOUND THAT LIVES SOMEWHERE: a loop at a point (the melee on the left flank, a burning tower)
function WarFX.loop3D(name, pos, opts)
	opts = opts or {}
	local src = audio(name)
	if not (src and src:IsA("Sound")) then return nil end
	local holder = Instance.new("Attachment")
	holder.Position = pos
	holder.Parent = workspace.Terrain
	local s = src:Clone()
	s.Looped = true
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = opts.near or 40
	s.RollOffMaxDistance = opts.range or 600
	s.Volume = 0
	s.TimePosition = math.random() * math.max(s.TimeLength - 1, 0)
	s.Parent = holder
	s:Play()
	TweenService:Create(s, TweenInfo.new(2), {Volume = src.Volume * (opts.volume or 1)}):Play()
	local h = {sound = s, holder = holder}
	function h.move(p) if holder.Parent then holder.Position = p end end
	function h.stop(fade)
		if not holder.Parent then return end
		TweenService:Create(s, TweenInfo.new(fade or 1), {Volume = 0}):Play()
		Debris:AddItem(holder, (fade or 1) + 0.2)
	end
	return h
end

function WarFX.dust(pos, size, color)
	size = size or 1
	local a = anchorAt(pos, 5)
	emitter(a, {life = NumberRange.new(1.4, 2.6), size = NumberSequence.new(3 * size, 9 * size), speed = NumberRange.new(5, 12),
		color = ColorSequence.new(color or Color3.fromRGB(140, 128, 112)), transparency = NumberSequence.new(0.35, 1), accel = V3(0, 1.5, 0)}):Emit(math.floor(12 * size))
end

--------------------------------------------------------------------
--  THE SKY: lightning, a battle-mage's strikes and frost, the weather
--------------------------------------------------------------------
local function bolt(at, exact, color)
	local h = home()
	local segs = {}
	local p = at + V3(0, 330, 0)
	local function line(a, b, w)
		local s = part(V3(w, w, (b - a).Magnitude), color or Color3.fromRGB(220, 230, 255), Enum.Material.Neon)
		s.CFrame = CFrame.lookAt((a + b) / 2, b)
		s.Parent = h
		table.insert(segs, s)
	end
	for i = 1, 9 do
		local q = V3(at.X + (math.random() - 0.5) * 50 * (1 - i / 10), at.Y + 330 - i * 36.6, at.Z + (math.random() - 0.5) * 50 * (1 - i / 10))
		if exact and i == 9 then q = at end
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

-- a battle-mage's lightning: a bolt onto the very spot, a crack of thunder, a flash
function WarFX.strike(pos, opts)
	opts = opts or {}
	bolt(pos, true, opts.color)
	local cam = workspace.CurrentCamera
	local d = cam and (cam.CFrame.Position - pos).Magnitude or 0
	WarFX.flash(math.clamp(0.5 - d / 600, 0.06, 0.5))
	WarFX.sound("Thunder", pos, {range = 1600, near = 90, volume = 1.1, speed = 1.1 + math.random() * 0.15})
	local a = anchorAt(pos + V3(0, 1, 0), 3)
	local light = Instance.new("PointLight")
	light.Range, light.Brightness, light.Color = 40, 10, opts.color or Color3.fromRGB(180, 200, 255)
	light.Parent = a
	TweenService:Create(light, TweenInfo.new(0.6), {Brightness = 0}):Play()
	emitter(a, {texture = SPARK, life = NumberRange.new(0.3, 0.8), size = NumberSequence.new(1, 0), speed = NumberRange.new(20, 50),
		color = ColorSequence.new(Color3.fromRGB(220, 235, 255), opts.color or Color3.fromRGB(120, 160, 255)), transparency = NumberSequence.new(0, 1), glow = 1, drag = 1}):Emit(30)
	local sc = part(V3(0.2, 6, 6), Color3.fromRGB(24, 22, 26), Enum.Material.Slate, 0.25)
	sc.Shape = Enum.PartType.Cylinder
	sc.CFrame = CF(pos + V3(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	sc.Parent = home()
	Debris:AddItem(sc, 14)
	local k = 1.3 * math.clamp(1 - d / 160, 0, 1)
	if k > 0.05 then WarFX.shake(k, 0.4) end
end

-- a battle-mage's frost: shards of ice burst from the ground in a ring, a cold mist rolls out
function WarFX.frost(pos, r)
	r = r or 14
	for i = 1, 14 do
		local ang = i / 14 * math.pi * 2
		local sh = part(V3(0.9, 3 + math.random() * 3, 0.9), Color3.fromRGB(170, 220, 255), Enum.Material.Ice, 0.15)
		local at = pos + V3(math.cos(ang) * r * (0.35 + math.random() * 0.6), 0, math.sin(ang) * r * (0.35 + math.random() * 0.6))
		local cf = CF(at - V3(0, 4, 0)) * CFrame.Angles(math.random() - 0.5, math.random() * 6, math.random() - 0.5)
		sh.CFrame = cf
		sh.Parent = home()
		TweenService:Create(sh, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = cf + V3(0, 4.5, 0)}):Play()
		task.delay(3 + math.random(), function() if sh.Parent then TweenService:Create(sh, TweenInfo.new(0.8), {Transparency = 1}):Play() end end)
		Debris:AddItem(sh, 5.5)
	end
	local a = anchorAt(pos + V3(0, 1, 0), 6)
	emitter(a, {life = NumberRange.new(2, 3.5), size = NumberSequence.new(4, 11), speed = NumberRange.new(r * 0.5, r),
		color = ColorSequence.new(Color3.fromRGB(205, 232, 255)), transparency = NumberSequence.new(0.4, 1), accel = V3(0, 0.5, 0)}):Emit(30)
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color = math.min(r * 2.5, 60), 4, Color3.fromRGB(150, 200, 255)
	l.Parent = a
	TweenService:Create(l, TweenInfo.new(1.5), {Brightness = 0}):Play()
	WarFX.sound("Impact", pos, {speed = 1.7, volume = 0.6, range = 600})
end

-- WEATHER round the camera: each drop a thin part, all moved in one bulk move
local WEATHER = {
	storm = {n = 220, size = V3(0.07, 0.07, 3), color = Color3.fromRGB(168, 184, 210), alpha = 0.5, wind = V3(16, -110, 7), lightning = true, roof = true,
		clouds = {Cover = 0.86, Density = 0.75, Color = Color3.fromRGB(50, 56, 70)}},
	rain = {n = 150, size = V3(0.06, 0.06, 2.6), color = Color3.fromRGB(176, 190, 214), alpha = 0.55, wind = V3(8, -100, 4), roof = true,
		clouds = {Cover = 0.72, Density = 0.6, Color = Color3.fromRGB(120, 126, 138)}},
	snow = {n = 200, size = V3(0.3, 0.3, 0.3), color = Color3.fromRGB(245, 248, 255), alpha = 0.1, wind = V3(4, -9, 2), drift = 3, roof = true, round = true,
		clouds = {Cover = 0.72, Density = 0.5, Color = Color3.fromRGB(220, 226, 236)}},
	embers = {n = 80, size = V3(0.22, 0.22, 0.22), color = Color3.fromRGB(255, 140, 50), alpha = 0, wind = V3(3, 5, 1), drift = 2.5, neon = true, rise = true, round = true},
	petals = {n = 70, size = V3(0.5, 0.06, 0.4), color = Color3.fromRGB(255, 186, 214), alpha = 0.05, wind = V3(5, -4, 2), drift = 3.5},
}
local weather = nil
function WarFX.weather(kind, fade)
	local w = kind and WEATHER[kind]
	if weather and weather.kind == kind then return end
	-- the old weather thins out
	local old = weather
	weather = nil
	if old then
		old.alive = false
		task.spawn(function()
			local steps = math.max(1, math.floor((fade or 0) / 0.1))
			for i = steps, 1, -1 do
				old.n = math.floor(#old.drops * (i - 1) / steps)
				for j = old.n + 1, #old.drops do old.drops[j].p.CFrame = FAR end
				task.wait(0.1)
			end
			if old.conn then old.conn:Disconnect() end
			for _, dr in ipairs(old.drops) do dr.p:Destroy() end
			if old.clouds and old.clouds.Parent then
				if old.hadClouds then for k, v in pairs(old.oldClouds) do old.clouds[k] = v end else old.clouds:Destroy() end
			end
		end)
	end
	if not w then return end
	local s = {kind = kind, drops = {}, visible = true, n = w.n, alive = true}
	weather = s
	local h = crowd()
	for i = 1, w.n do
		local d = part(w.size, w.color, w.neon and Enum.Material.Neon or Enum.Material.SmoothPlastic, w.alpha)
		if w.round then d.Shape = Enum.PartType.Ball end
		d.CFrame = FAR
		d.Parent = h
		s.drops[i] = {p = d, pos = nil, ph = math.random() * 6.28}
	end
	local parts, cfs = {}, {}
	local up = RaycastParams.new()
	up.FilterType = Enum.RaycastFilterType.Exclude
	local nextRoof = 0
	s.conn = RunService.RenderStepped:Connect(function(dt)
		local cam = workspace.CurrentCamera
		if not cam then return end
		local c = cam.CFrame.Position
		local now = os.clock()
		-- under a roof: none in your face
		if w.roof and now > nextRoof then
			nextRoof = now + 0.3
			up.FilterDescendantsInstances = {h, home(), Players.LocalPlayer.Character}
			local roofed = workspace:Raycast(c, V3(0, 60, 0), up) ~= nil
			if roofed == s.visible then
				s.visible = not roofed
				for _, dr in ipairs(s.drops) do dr.p.Transparency = s.visible and w.alpha or 1 end
			end
		end
		if not s.visible then return end
		table.clear(parts); table.clear(cfs)
		local live = math.min(s.n, #s.drops)
		for i = 1, live do
			local dr = s.drops[i]
			local p = dr.pos
			local gone = not p or math.abs(p.X - c.X) > 40 or math.abs(p.Z - c.Z) > 40
			if w.rise then gone = gone or p.Y > c.Y + 40 else gone = gone or p.Y < c.Y - 28 end
			if gone then
				local y = w.rise and (c.Y - 20 + math.random() * 10) or (c.Y + 10 + math.random() * 40)
				p = V3(c.X + (math.random() - 0.5) * 80, y, c.Z + (math.random() - 0.5) * 80)
			end
			local v = w.wind
			if w.drift then v += V3(math.sin(now * 1.3 + dr.ph) * w.drift, 0, math.cos(now * 1.1 + dr.ph) * w.drift) end
			p += v * dt
			dr.pos = p
			parts[i] = dr.p
			cfs[i] = CFrame.lookAt(p, p + v)
		end
		if live > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	end)
	if w.lightning then
		task.spawn(function()
			task.wait(2)
			while weather == s and s.alive do
				WarFX.lightning(math.random() < 0.15)
				task.wait(5 + math.random() * 8)
			end
		end)
	end
	if w.clouds then
		local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
		s.hadClouds = clouds ~= nil
		if not clouds then clouds = Instance.new("Clouds"); clouds.Parent = workspace.Terrain end
		s.clouds, s.oldClouds = clouds, {Cover = clouds.Cover, Density = clouds.Density, Color = clouds.Color}
		for k, v in pairs(w.clouds) do clouds[k] = v end
	end
end
function WarFX.storm(on, fade) WarFX.weather(on and "storm" or nil, fade) end
function WarFX.weatherKind() return weather and weather.kind or nil end

--------------------------------------------------------------------
--  HORSEMEN: a column riding along a path (each horse and rider a handful of parts)
--------------------------------------------------------------------
local HORSES = {Color3.fromRGB(70, 48, 32), Color3.fromRGB(40, 32, 28), Color3.fromRGB(120, 92, 64), Color3.fromRGB(200, 196, 186)}
local function horseman(color, lance)
	local h = crowd()
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
	WarFX.weather(nil, 0)
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
