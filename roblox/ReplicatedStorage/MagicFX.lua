--[[ MAGIC FX (client) — what magic looks like, for everyone (StarterPlayerScripts
     ▸ MagicFX runs it). It draws from two things the server publishes:

       ReplicatedStorage.MagicFXRemote (Combat ▸ MagicServer): a bolt flying and bursting,
         lightning leaping, a nova's ring of ice, a heal's rising light, a fizzle
       character attributes: Casting (+ CastStart, CastTime) → a magic circle of runes
         turning at the staff's orb, growing as the cast fills · Warded → a shield of
         light in front (WardHit makes it ripple, WardBroke shatters it) · Burning
         → flames on the body · Frosted → frost on it

     Glowing parts (they show in every quality setting), particles from Roblox's
     own textures, sounds from the licensed libraries (Pro Sound Effects, APM). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))

local MagicFX = {}

local TEX = {spark = "rbxasset://textures/particles/sparkles_main.dds", fire = "rbxasset://textures/particles/fire_main.dds", smoke = "rbxasset://textures/particles/smoke_main.dds"}
local SND = {cast = 9125899162, boom = 1835337001, whoosh = 9120709477, zap = 9116279560, zap2 = 9116275998, ice = 9119577515, shing = 9119742466, hum = 9112889082}

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
local function colorsOf(spellId)
	local sp = Spells[spellId] or {}
	return sp.color or Color3.new(1, 1, 1), sp.glow or Color3.new(1, 1, 1)
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

--------------------------------------------------------------------
--  THE EVENTS
--------------------------------------------------------------------
local bolts = {}   -- id → {ball, pos, dir, speed, left, spell}

local EVENTS = {}
-- (where this screen sees the caster's orb: the pose is drawn on each screen, the server's
-- origin is its own guess; a spell starts at the orb and joins the server's line)
local function tipOf(caster)
	local tool = caster and caster:FindFirstChildOfClass("Tool")
	local tip = tool and tool:FindFirstChild("TrailTip", true)
	return tip and tip:IsA("Attachment") and tip.WorldPosition or nil
end
function EVENTS.Bolt(id, origin, dir, speed, spellId, range, caster)
	local c0, c1 = colorsOf(spellId)
	local ball = part(Vector3.one * 1.1, c1, Enum.PartType.Ball)
	ball.Position = origin
	local tip = tipOf(caster)
	local core = Instance.new("PointLight"); core.Color = c0; core.Range = 12; core.Brightness = 3; core.Parent = ball
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.4, 0); a0.Parent = ball
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.4, 0); a1.Parent = ball
	local tr = Instance.new("Trail"); tr.Attachment0, tr.Attachment1 = a0, a1; tr.Color = ColorSequence.new(c1, c0); tr.LightEmission = 1
	tr.Transparency = NumberSequence.new(0.1, 1); tr.Lifetime = 0.25; tr.FaceCamera = true; tr.Parent = ball
	emitter(ball, TEX.fire, c0, c1, 1.1, 60, {0.15, 0.35}, {0.5, 2}, Vector3.zero, 180, 1)
	emitter(ball, TEX.spark, c1, c0, 0.35, 30, {0.2, 0.5}, {1, 3}, Vector3.new(0, -4, 0), 180, 1)
	sound(SND.whoosh, ball, 0.45, 1.2)
	bolts[id] = {ball = ball, pos = origin, dir = dir, speed = speed, left = range or 300, spell = spellId,
		offset = (tip and (tip - origin).Magnitude < 8) and (tip - origin) or Vector3.zero, born = os.clock()}
	if tip then ball.Position = tip end
end
function EVENTS.Impact(id, pos, spellId, fizzled)
	local b = bolts[id]
	if b then bolts[id] = nil; b.ball:Destroy() end
	local c0, c1 = colorsOf(spellId)
	if fizzled then flash(pos, c0, 0.6, 2.5, 0.3); return end
	flash(pos, c1, 1, 8, 0.35)
	flash(pos, c0, 0.6, 5, 0.5)
	burstAt(pos, c1, c0, 26, 18)
	sound(SND.boom, pos, 0.42, 1.25, 1.6)
end
function EVENTS.Chain(spellId, points, caster)
	local c0, c1 = colorsOf(spellId)
	local tip = tipOf(caster)
	if tip and points[1] and (tip - points[1]).Magnitude < 8 then points[1] = tip end
	for i = 1, #points - 1 do
		jag(points[i], points[i + 1], c1, 0.32, 0.28)
		jag(points[i], points[i + 1], c0, 0.18, 0.4)
		flash(points[i + 1], c0, 0.5, 4, 0.3)
	end
	sound(SND.zap, points[1], 0.6, 1)
	sound(SND.boom, points[#points], 0.4, 0.62, 2)
end
function EVENTS.Nova(spellId, pos, radius)
	local c0, c1 = colorsOf(spellId)
	-- the ring, racing out along the ground
	local n = 28
	local segs = {}
	for i = 1, n do segs[i] = part(Vector3.new(1, 0.3, 0.3), c1) end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / 0.45, 0, 1)
		local r = 1 + (radius - 1) * (1 - (1 - k) ^ 3)
		for i, s in ipairs(segs) do
			local a = i / n * math.pi * 2
			s.Size = Vector3.new(2 * math.pi * r / n * 1.1, 0.3, 0.35)
			s.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * r, 0.2, math.sin(a) * r)) * CFrame.Angles(0, -a + math.pi / 2, 0)
			s.Transparency = k ^ 2
		end
		if k >= 1 then conn:Disconnect(); for _, s in ipairs(segs) do s:Destroy() end end
	end)
	-- shards of ice bursting up round you
	for i = 1, 14 do
		local a = math.random() * math.pi * 2
		local d = 2 + math.random() * (radius - 3)
		local h = 1.2 + math.random() * 2.2
		local s = part(Vector3.new(0.6, h, 0.6), c0, nil, Enum.Material.Ice)
		s.Transparency = 0.2
		local at = pos + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		s.CFrame = CFrame.new(at - Vector3.new(0, h, 0)) * CFrame.Angles(math.rad(math.random(-20, 20)), a, math.rad(math.random(-20, 20)))
		TweenService:Create(s, TweenInfo.new(0.18, Enum.EasingStyle.Back), {CFrame = s.CFrame + Vector3.new(0, h * 0.9, 0)}):Play()
		task.delay(1.2, function() if s.Parent then TweenService:Create(s, TweenInfo.new(0.5), {Transparency = 1, Size = s.Size * 0.4}):Play() end end)
		Debris:AddItem(s, 1.8)
	end
	flash(pos + Vector3.new(0, 1, 0), c1, 2, radius * 1.2, 0.4)
	sound(SND.ice, pos, 0.7, 0.7, 1)
	sound(SND.boom, pos, 0.35, 1.4, 1.2)
end
function EVENTS.Heal(spellId, char, time)
	local torso = char and char:FindFirstChild("Torso")
	if not torso then return end
	local c0, c1 = colorsOf(spellId)
	local a = Instance.new("Attachment"); a.Position = Vector3.new(0, -2.6, 0); a.Parent = torso
	local pe = emitter(a, TEX.spark, c1, c0, 0.4, 40, {0.8, 1.4}, {2, 4}, Vector3.new(0, 3, 0), 30, 1)
	pe.Shape = Enum.ParticleEmitterShape.Disc; pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	pe.EmissionDirection = Enum.NormalId.Top
	local l = Instance.new("PointLight"); l.Color = c0; l.Range = 10; l.Brightness = 2; l.Parent = torso
	task.delay(time or 2, function() pe.Enabled = false; TweenService:Create(l, TweenInfo.new(0.4), {Brightness = 0}):Play() end)
	Debris:AddItem(a, (time or 2) + 1.5); Debris:AddItem(l, (time or 2) + 0.5)
	sound(SND.cast, torso, 0.35, 1.8, 2)
	sound(SND.shing, torso, 0.25, 1.6, 1)
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
--  WHAT CHARACTERS CARRY (casting, warding, burning, frosted)
--------------------------------------------------------------------
local looks = setmetatable({}, {__mode = "k"})   -- char → {circle, ward, burn, frost}

local function staffTip(char)
	local tool = char:FindFirstChildOfClass("Tool")
	local tip = tool and tool:FindFirstChild("TrailTip", true)
	if tip and tip:IsA("Attachment") then return tip.WorldPosition end
	local head = char:FindFirstChild("Head")
	return head and head.Position or nil
end

local function makeCircle(char, spellId)
	local c0, c1 = colorsOf(spellId)
	local m = {segs = {}, runes = {}, spell = spellId, t0 = os.clock()}
	for i = 1, 20 do m.segs[i] = part(Vector3.new(0.4, 0.08, 0.08), c1) end
	for i = 1, 6 do m.runes[i] = part(Vector3.new(0.18, 0.5, 0.06), c0) end
	m.inner = {}
	for i = 1, 12 do m.inner[i] = part(Vector3.new(0.3, 0.06, 0.06), c0) end
	local tip = staffTip(char)
	m.light = part(Vector3.one * 0.6, c1, Enum.PartType.Ball)
	m.light.Transparency = 0.2
	local l = Instance.new("PointLight"); l.Color = c0; l.Range = 10; l.Brightness = 2; l.Parent = m.light
	m.sparks = emitter(m.light, TEX.spark, c1, c0, 0.3, 30, {0.2, 0.5}, {1, 3}, Vector3.zero, 180, 1)
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

local function makeWard(char)
	local disc = part(Vector3.new(0.12, 6, 6), Color3.fromRGB(160, 200, 255), Enum.PartType.Cylinder, Enum.Material.ForceField)
	disc.Transparency = 0.1
	local rim = {}
	for i = 1, 18 do rim[i] = part(Vector3.new(0.12, 0.12, 1.1), Color3.fromRGB(190, 220, 255)) end
	local hum = sound(SND.hum, disc, 0.12, 1.5, 999)
	hum.Looped = true
	return {disc = disc, rim = rim, hum = hum, hitAt = 0}
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

local function bodyFx(char, kind)
	local torso = char:FindFirstChild("Torso")
	if not torso then return nil end
	local a = Instance.new("Attachment"); a.Name = "MagicFX_" .. kind; a.Parent = torso
	if kind == "burn" then
		emitter(a, TEX.fire, Color3.fromRGB(255, 160, 60), Color3.fromRGB(200, 40, 10), 1.6, 30, {0.3, 0.6}, {1, 3}, Vector3.new(0, 6, 0), 40, 1)
		emitter(a, TEX.spark, Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 80, 20), 0.25, 14, {0.4, 0.9}, {1, 4}, Vector3.new(0, 5, 0), 90, 1)
	else
		emitter(a, TEX.spark, Color3.fromRGB(240, 252, 255), Color3.fromRGB(150, 214, 255), 0.3, 24, {0.6, 1.2}, {0.2, 0.8}, Vector3.new(0, -1.5, 0), 180, 0.8)
		emitter(a, TEX.smoke, Color3.fromRGB(200, 236, 255), nil, 1.4, 6, {0.6, 1}, {0.2, 0.6}, Vector3.new(0, -0.5, 0), 180, 0.2)
	end
	return a
end

local function chars()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(out, p.Character) end end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do if m:IsA("Model") then table.insert(out, m) end end end
	return out
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
		-- the bolts fly on every screen
		for id, b in pairs(bolts) do
			local step = b.speed * dt
			b.pos += b.dir * step
			b.left -= step
			if b.left <= 0 or not b.ball.Parent then bolts[id] = nil; if b.ball.Parent then b.ball:Destroy() end
			else b.ball.Position = b.pos + b.offset * (1 - math.clamp((now - b.born) / 0.15, 0, 1)) end
		end
		scan += dt
		local full = scan > 0.1
		if full then scan = 0 end
		for _, char in ipairs(chars()) do
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
					local k = math.clamp((os.clock() - m.t0) / math.max(char:GetAttribute("CastTime") or 0.5, 0.1), 0, 1)
					local r = 0.6 + 1.3 * (1 - (1 - k) ^ 2)
					local look = root.CFrame.LookVector
					local centre = tip + look * 0.8
					local face = CFrame.lookAt(centre, centre + look)
					local spin = os.clock() * 3
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
			if warded and not L.ward then L.ward = makeWard(char) end
			if L.ward and not warded then dropWard(L.ward, now - (char:GetAttribute("WardBroke") or -1e9) < 0.5); L.ward = nil end
			if L.ward then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					local hit = now - (char:GetAttribute("WardHit") or -1e9)
					local pulse = hit < 0.3 and (1 - hit / 0.3) or 0
					local c = root.CFrame * CFrame.new(0, 0.3, -2.2)
					L.ward.disc.CFrame = c * CFrame.Angles(0, math.pi / 2, 0)
					L.ward.disc.Size = Vector3.new(0.12, 5.6 + pulse * 1.2, 5.6 + pulse * 1.2)
					L.ward.disc.Color = Color3.fromRGB(160, 200, 255):Lerp(Color3.new(1, 1, 1), pulse)
					for i, s in ipairs(L.ward.rim) do
						local a = i / #L.ward.rim * math.pi * 2 + now
						local rr = 2.8 + pulse * 0.6
						s.CFrame = c * CFrame.Angles(0, 0, a) * CFrame.new(0, rr, 0) * CFrame.Angles(0, math.pi / 2, 0)
					end
					if pulse > 0.95 and not L.wardSnd then L.wardSnd = true; sound(SND.shing, L.ward.disc, 0.4, 1.4, 0.6) elseif pulse < 0.5 then L.wardSnd = false end
				end
			end
			-- burning, frosted
			if full then
				local burning = char:GetAttribute("Burning") == true
				if burning and not L.burn then L.burn = bodyFx(char, "burn") elseif not burning and L.burn then L.burn:Destroy(); L.burn = nil end
				local frosted = char:GetAttribute("Frosted") == true
				if frosted and not L.frost then L.frost = bodyFx(char, "frost") elseif not frosted and L.frost then L.frost:Destroy(); L.frost = nil end
			end
		end
		-- (gone characters)
		if full then
			for char, L in pairs(looks) do
				if not char.Parent then dropCircle(L.circle); dropWard(L.ward); looks[char] = nil end
			end
		end
	end)
end

return MagicFX
