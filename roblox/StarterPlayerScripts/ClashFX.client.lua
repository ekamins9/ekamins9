--[[ CLASH FX — steel on steel, seen. A blow stopped on a guard (blocked, parried, chambered,
     caught on a shield, or a guard broken) is fired to every screen by Combat ▸ CombatServer
     (ClashEvent: attacker, defender, where, kind, the attack's name, how hard), and each client
     works out on its own screen what the two blades did:

       WHERE they met    the closest points of the two blades (each a segment: the attacker's
                         Hitbox, the defender's GuardHull) — so the sparks come off the crossing
                         you actually see, not off a point the server guessed
       WHICH WAY it went the attacker's blade was travelling across its own length (the attack's
                         name says which way: RightSwing comes from the right and travels left,
                         an overhead down, an underhand up, a stab forward); on a blade it skids
                         along the guard's length and its push into the guard bounces back
                         (restitution); on a shield it reflects off the board
       THE GLANCE        the attacker's arm is knocked along that bounce (a damped spring on the
                         shoulder: out fast, back with a little overshoot) and the blade rings in
                         the hand (a fast shiver of the grip, dying away); the defender's arm gives
                         a little under the blow and its blade rings too
       THE SPARKS        white-hot slivers sprayed along the glance and down the guard's edge,
                         cooling to orange as they fall; a flash and a burst of light at the
                         crossing; a parry's spray is bigger, a perfect parry's has a glint

     Laid over the animation (the joints' Transform after the Animator, like DrawFX), so the
     clips themselves are untouched. Only within 120 studs of your camera; a phone throws fewer
     sparks. Nothing here is sent to the server. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Device = require(ReplicatedStorage:WaitForChild("Device"))
local PHONE = Device.kind() == "phone"
local NEAR = 120

-- per kind: how far the attacker's blade tip is knocked (studs), the defender's give, how many
-- sparks, how bright, and whether it glints
local KINDS = {
	block   = {knock = 0.9, give = 0.35, sparks = 18, light = 1,   ring = 1},
	parry   = {knock = 1.5, give = 0.25, sparks = 30, light = 1.5, ring = 1.2},
	perfect = {knock = 1.9, give = 0.2,  sparks = 42, light = 2.2, ring = 1.3, glint = true},
	chamber = {knock = 1.2, give = 0,    sparks = 26, light = 1.4, ring = 1.1},
	shield  = {knock = 1.2, give = 0.3,  sparks = 8,  light = 0.6, ring = 0.5},
	["break"] = {knock = 0.7, give = 0.6, sparks = 34, light = 1.8, ring = 1.2},
}
local WHITE = Color3.fromRGB(255, 252, 235)
local HOT = Color3.fromRGB(255, 196, 90)
local COOL = Color3.fromRGB(226, 96, 34)

local event = ReplicatedStorage:WaitForChild("ClashEvent", 1e9)
local folder = Instance.new("Folder")
folder.Name = "ClashFX"
folder.Parent = workspace

--------------------------------------------------------------------
--  GEOMETRY
--------------------------------------------------------------------
-- a box part as a segment along its longest axis: centre, unit axis, half-length; and, for a
-- board (two long sides: a shield), its face's normal
local function segOf(part)
	local s, cf = part.Size, part.CFrame
	local dims = {{s.X, cf.RightVector}, {s.Y, cf.UpVector}, {s.Z, cf.LookVector}}
	table.sort(dims, function(a, b) return a[1] > b[1] end)
	local plate = dims[2][1] >= dims[1][1] * 0.5
	return {c = cf.Position, a = dims[1][2], h = dims[1][1] / 2, n = plate and dims[3][2] or nil}
end

-- the closest points of two segments (Ericson, Real-Time Collision Detection 5.1.9)
local function closest(A, B)
	local p1, p2 = A.c - A.a * A.h, B.c - B.a * B.h
	local d1, d2 = A.a * (2 * A.h), B.a * (2 * B.h)
	local r = p1 - p2
	local a, e, f = d1:Dot(d1), d2:Dot(d2), d2:Dot(r)
	local s, t
	if a <= 1e-6 and e <= 1e-6 then return p1, p2 end
	if a <= 1e-6 then
		s, t = 0, math.clamp(f / e, 0, 1)
	else
		local c = d1:Dot(r)
		if e <= 1e-6 then
			s, t = math.clamp(-c / a, 0, 1), 0
		else
			local b = d1:Dot(d2)
			local den = a * e - b * b
			s = den > 1e-6 and math.clamp((b * f - c * e) / den, 0, 1) or 0
			t = (b * s + f) / e
			if t < 0 then s, t = math.clamp(-c / a, 0, 1), 0
			elseif t > 1 then s, t = math.clamp((b - c) / a, 0, 1), 1 end
		end
	end
	return p1 + d1 * s, p2 + d2 * t
end

-- the attacker's blade: its weapon's Hitbox
local function bladeOf(char)
	local tool = char and char:FindFirstChildOfClass("Tool")
	if not tool then return nil end
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Hitbox" then return d end
	end
	return nil
end
-- the defender's guard: the GuardHull (a weapon's or a shield's) nearest the blow
local function guardOf(char, near)
	local best, bd = nil, math.huge
	for _, d in ipairs(char and char:GetDescendants() or {}) do
		if d:IsA("BasePart") and d.Name == "GuardHull" then
			local dist = (d.Position - near).Magnitude
			if dist < bd then best, bd = d, dist end
		end
	end
	return best
end

-- which way the blow was travelling, from its name (<Side><Kind>: RightSwing comes from the
-- right and travels left), in the attacker's frame
local function travel(root, name)
	local R, U, F = root.CFrame.RightVector, Vector3.yAxis, root.CFrame.LookVector
	local side = name:sub(1, 4) == "Left" and -1 or 1
	local kind = name:gsub("^Left", ""):gsub("^Right", "")
	if kind == "Stab" then return F end
	if kind == "Overhead" then return (-U - R * side * 0.35 + F * 0.25).Unit end
	if kind == "Underhand" then return (U - R * side * 0.35 + F * 0.25).Unit end
	return (-R * side + F * 0.3).Unit
end

--------------------------------------------------------------------
--  THE GLANCE: springs laid over the joints
--------------------------------------------------------------------
local moves = {}   -- {motor, axis (the joint's own frame), amp (rad), freq, decay, t0, dur}
local function knock(motor, frame, worldAxis, amp, freq, decay, dur)
	if not (motor and motor:IsA("Motor6D") and frame) or worldAxis.Magnitude < 1e-4 or amp == 0 then return end
	-- the joint's frame: the turn is laid on its Transform, so the axis goes into that frame
	local jr = (frame.CFrame * motor.C0).Rotation
	table.insert(moves, {motor = motor, axis = jr:VectorToObjectSpace(worldAxis.Unit), amp = amp, freq = freq,
		decay = decay, t0 = os.clock(), dur = dur})
end
-- turn an arm about its shoulder so that `tip` moves `dist` studs along `dir`
local function swingArm(char, shoulderName, tip, dir, dist, freq, decay)
	local torso = char:FindFirstChild("Torso")
	local sh = torso and torso:FindFirstChild(shoulderName)
	if not (sh and sh:IsA("Motor6D")) or dir.Magnitude < 1e-4 then return end
	local pivot = (torso.CFrame * sh.C0).Position
	local r = tip - pivot
	if r.Magnitude < 0.5 then return end
	local axis = r:Cross(dir.Unit)
	-- (a spring's first lobe peaks at about 0.6 of its height: the amp is raised to match)
	knock(sh, torso, axis, (dist / r.Magnitude) / 0.6, freq, decay, 0.6)
end
-- the blade ringing in the hand: a fast shiver of the grip, dying away
local function ring(char, axisWorld, amp)
	local arm = char:FindFirstChild("Right Arm")
	local grip = arm and arm:FindFirstChild("ToolGrip")
	if grip then knock(grip, arm, axisWorld, amp, 24, 0.09, 0.4) end
end

RunService.Stepped:Connect(function()
	if #moves == 0 then return end
	local now = os.clock()
	for i = #moves, 1, -1 do
		local m = moves[i]
		local t = now - m.t0
		if t >= m.dur or not m.motor.Parent then
			table.remove(moves, i)
		else
			local a = m.amp * math.exp(-t / m.decay) * math.sin(2 * math.pi * m.freq * t)
			m.motor.Transform = CFrame.fromAxisAngle(m.axis, a) * m.motor.Transform
		end
	end
end)

--------------------------------------------------------------------
--  SPARKS
--------------------------------------------------------------------
local pool, live = {}, {}
local function sliver()
	local p = table.remove(pool)
	if not p then
		p = Instance.new("Part")
		p.Name = "Spark"
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Size = Vector3.new(0.05, 0.05, 0.3)
	end
	p.Transparency = 0
	p.Parent = folder
	return p
end
local function spray(at, dirs, count, speed)
	if PHONE then count = math.ceil(count * 0.5) end
	for i = 1, count do
		-- each spark leaves along one of the directions (weighted), scattered round it
		local pick = dirs[1 + (i - 1) % #dirs]
		local scatter = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.7
		local v = (pick + scatter)
		if v.Magnitude < 1e-3 then v = Vector3.yAxis end
		v = v.Unit * speed * (0.45 + math.random() * 0.75) + Vector3.new(0, 6, 0)
		local life = 0.18 + math.random() * 0.38
		table.insert(live, {p = sliver(), pos = at, v = v, t0 = os.clock(), life = life, w = 0.02 + math.random() * 0.025})
	end
end
local function flash(at, k)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Anchored, ball.CanCollide, ball.CanQuery, ball.CanTouch = true, false, false, false
	ball.CastShadow = false
	ball.Material = Enum.Material.Neon
	ball.Color = WHITE
	ball.Size = Vector3.new(0.25, 0.25, 0.25)
	ball.CFrame = CFrame.new(at)
	local light = Instance.new("PointLight")
	light.Color = HOT
	light.Brightness = 5 * k.light
	light.Range = 10 + 4 * k.light
	light.Shadows = false
	light.Parent = ball
	ball.Parent = folder
	table.insert(live, {flash = ball, light = light, t0 = os.clock(), life = 0.12, k = k.light})
end
-- a perfect parry's glint: a four-pointed star across the crossing, facing you
local function glint(at)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local face = CFrame.lookAt(at, cam.CFrame.Position)
	for _, roll in ipairs({0, math.pi / 2}) do
		local s = Instance.new("Part")
		s.Anchored, s.CanCollide, s.CanQuery, s.CanTouch = true, false, false, false
		s.CastShadow = false
		s.Material = Enum.Material.Neon
		s.Color = WHITE
		s.Size = Vector3.new(0.06, 3.2, 0.06)
		s.CFrame = face * CFrame.Angles(0, 0, roll + math.pi / 4)
		s.Parent = folder
		table.insert(live, {glint = s, face = s.CFrame, t0 = os.clock(), life = 0.22})
	end
end

RunService.RenderStepped:Connect(function(dt)
	if #live == 0 then return end
	local now = os.clock()
	for i = #live, 1, -1 do
		local s = live[i]
		local u = (now - s.t0) / s.life
		if u >= 1 then
			table.remove(live, i)
			if s.p then s.p.Parent = nil; table.insert(pool, s.p)
			elseif s.flash then s.flash:Destroy()
			elseif s.glint then s.glint:Destroy() end
		elseif s.p then
			-- falling, slowing, cooling: white-hot to orange
			s.v = s.v * (1 - math.min(dt * 2.6, 0.5)) + Vector3.new(0, -70 * dt, 0)
			s.pos = s.pos + s.v * dt
			local speed = s.v.Magnitude
			local len = math.clamp(speed * 0.018, 0.06, 0.7)
			s.p.Size = Vector3.new(s.w, s.w, len)
			if speed > 1e-3 then s.p.CFrame = CFrame.lookAt(s.pos, s.pos + s.v) * CFrame.new(0, 0, len / 2) end
			s.p.Color = u < 0.35 and WHITE:Lerp(HOT, u / 0.35) or HOT:Lerp(COOL, (u - 0.35) / 0.65)
			s.p.Transparency = u < 0.6 and 0 or (u - 0.6) / 0.4
		elseif s.flash then
			-- (a small white-hot bloom, gone in a blink: the light does the rest)
			local sz = 0.2 + 0.55 * math.min(s.k, 1.6) * math.sqrt(u)
			s.flash.Size = Vector3.new(sz, sz, sz)
			s.flash.Transparency = 0.15 + 0.85 * u
			s.light.Brightness = 5 * s.k * (1 - u) ^ 2
		elseif s.glint then
			local k = 1 - u
			s.glint.Size = Vector3.new(0.06 * k + 0.01, 3.2 * (0.4 + 0.6 * k), 0.06 * k + 0.01)
			s.glint.CFrame = s.face
			s.glint.Transparency = u ^ 2
		end
	end
end)

--------------------------------------------------------------------
--  A CLASH
--------------------------------------------------------------------
event.OnClientEvent:Connect(function(atk, def, hitPos, kind, name, power)
	if typeof(hitPos) ~= "Vector3" then return end
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - hitPos).Magnitude > NEAR then return end
	local k = KINDS[kind] or KINDS.block
	power = math.clamp(tonumber(power) or 1, 0.5, 2)
	local root = typeof(atk) == "Instance" and atk:FindFirstChild("HumanoidRootPart")

	-- where: the crossing of the two blades as this screen shows them
	local blade = typeof(atk) == "Instance" and bladeOf(atk)
	local guard = typeof(def) == "Instance" and guardOf(def, hitPos)
	local A = blade and segOf(blade)
	local B = guard and segOf(guard)
	local at = hitPos
	if A and B then
		local p1, p2 = closest(A, B)
		local mid = (p1 + p2) / 2
		if (mid - hitPos).Magnitude < 3.5 then at = mid end
	end

	-- which way: across the attacker's blade, as the attack goes
	local v = root and travel(root, tostring(name or "")) or Vector3.new(0, -1, 0)
	if A then
		local across = v - A.a * v:Dot(A.a)
		if across.Magnitude > 0.3 then v = across.Unit end
	end
	-- the bounce: off a board, a mirror; off a blade, a skid down its length and the push back
	local d
	if B and B.n then
		d = (v - B.n * (2 * v:Dot(B.n))).Unit
	elseif B then
		local along = B.a * v:Dot(B.a)
		local into = v - along
		d = along * 0.8 - into * 0.65 + Vector3.new(0, 0.15, 0)
		if d.Magnitude < 0.2 then d = -v + Vector3.new(0, 0.3, 0) end
		d = d.Unit
	else
		d = (-v + Vector3.new(0, 0.3, 0)).Unit
	end

	-- the glance: the attacker's arm knocked along the bounce, the blade ringing in the hand
	if typeof(atk) == "Instance" and A then
		local torso = atk:FindFirstChild("Torso")
		local tipA, tipB = A.c + A.a * A.h, A.c - A.a * A.h
		local tip = tipA
		if torso and (tipB - torso.Position).Magnitude > (tipA - torso.Position).Magnitude then tip = tipB end
		swingArm(atk, "Right Shoulder", tip, d, k.knock * power, 3.4, 0.14)
		ring(atk, A.a:Cross(d), 0.075 * k.ring)
	end
	-- the defender gives a little under it (a shield on the left arm)
	if typeof(def) == "Instance" and B and k.give > 0 then
		local onShield = B.n ~= nil
		local tipB = B.c
		swingArm(def, onShield and "Left Shoulder" or "Right Shoulder", tipB, v, k.give * power, 3, 0.12)
		if not onShield then ring(def, B.a:Cross(v), 0.05 * k.ring) end
	end

	-- the sparks: along the glance, both ways down the guard's edge, and out off its face
	local dirs = {d, d}
	if B and not B.n then table.insert(dirs, B.a); table.insert(dirs, -B.a) end
	if B and B.n then table.insert(dirs, B.n * (B.n:Dot(v) > 0 and -1 or 1)) end
	table.insert(dirs, -v + Vector3.new(0, 0.5, 0))
	spray(at, dirs, math.floor(k.sparks * power + 0.5), 34 * math.sqrt(power))
	flash(at, k)
	if k.glint then glint(at) end
end)
