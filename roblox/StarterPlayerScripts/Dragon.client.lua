--[[ DRAGON (client) — moves Cindermaw's body on your screen (Combat ▸ Dragon builds it, flies and walks
     it on the server and says what it's doing in attributes; this turns its joints to match):

       DragonState   intro · ground · takeoff · sky · crash · downed · land · inferno · dead
       Fly           wings beating (in the air), legs tucked
       Jaw  0..1     its mouth open          Rear 0..1   its head up, its front lifting
       Look          where its head turns    Breath / BreathYaw   fire from its mouth, swept
       Snap Swipe Tail Buffet   counters: a bite snaps, a claw swipes, the tail whips, a big wingbeat
       Reel · Downed · Enraged · Dead

     Every joint is a Motor6D named after the part it moves; this sets their Transform (axes at
     rest: X to its right, Y up, Z behind it). Its walk is read off how fast it's going. The fire
     is a stream of flame off its mouth while Breath is on. ]]

local RunService = game:GetService("RunService")
local BossIntro = require(game:GetService("ReplicatedStorage"):WaitForChild("BossIntro"))

local FIRE = Color3.fromRGB(255, 130, 40)
local dragons = {}   -- model -> state

local function A(x, y, z) return CFrame.Angles(x or 0, y or 0, z or 0) end
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
local function pulse(t0, dur)   -- 0 → 1 → 0 over dur seconds after t0 (nil when over)
	if not t0 then return 0 end
	local k = (os.clock() - t0) / dur
	if k < 0 or k > 1 then return 0 end
	return math.sin(k * math.pi)
end

local function setup(m)
	if dragons[m] then return end
	local root = m:WaitForChild("HumanoidRootPart", 5)
	if not root then return end
	local st = {model = m, root = root, joints = {}, phase = 0, last = {}, at = {}, smooth = {}}
	for _, j in ipairs(m:GetDescendants()) do if j:IsA("Motor6D") then st.joints[j.Name] = j end end
	-- the fire off its mouth
	local snout = m:FindFirstChild("Snout")
	local mouth = snout and snout:FindFirstChild("Mouth")
	if mouth then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "BreathFire"
		pe.Texture = "rbxasset://textures/particles/fire_main.dds"
		pe.EmissionDirection = Enum.NormalId.Front
		pe.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 150)), ColorSequenceKeypoint.new(0.35, FIRE), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 30, 10))})
		pe.LightEmission = 1
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(0.4, 6), NumberSequenceKeypoint.new(1, 10)})
		pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.4), NumberSequenceKeypoint.new(1, 1)})
		pe.Speed = NumberRange.new(55, 75)
		pe.SpreadAngle = Vector2.new(9, 9)
		pe.Lifetime = NumberRange.new(0.55, 0.85)
		pe.Drag = 1.2
		pe.Rate = 0
		pe.Parent = mouth
		st.breath = pe
		local l = Instance.new("PointLight"); l.Color = FIRE; l.Range = 40; l.Brightness = 0; l.Parent = mouth
		st.breathLight = l
		-- a glow in its throat (always, brighter with its jaw open)
		local ember = Instance.new("ParticleEmitter")
		ember.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		ember.Color = ColorSequence.new(FIRE)
		ember.LightEmission = 1
		ember.Size = NumberSequence.new(0.5, 0)
		ember.Speed = NumberRange.new(2, 5)
		ember.Lifetime = NumberRange.new(0.6, 1)
		ember.Rate = 6
		ember.Parent = mouth
		st.ember = ember
	end
	-- its fury: fire off its back
	local chest = m:FindFirstChild("Chest")
	if chest then
		local f = Instance.new("Fire"); f.Name = "Fury"; f.Size = 9; f.Heat = 12; f.Color = FIRE; f.SecondaryColor = Color3.fromRGB(200, 40, 10); f.Enabled = false; f.Parent = chest
		st.fury = f
	end
	-- the one-shot moves, on their counters
	for _, k in ipairs({"Snap", "Swipe", "Tail", "Buffet"}) do
		st.last[k] = m:GetAttribute(k) or 0
		m:GetAttributeChangedSignal(k):Connect(function()
			local v = m:GetAttribute(k) or 0
			if v ~= st.last[k] then st.last[k] = v; st.at[k] = os.clock() end
		end)
	end
	dragons[m] = st
	m.AncestryChanged:Connect(function() if not m:IsDescendantOf(workspace) then dragons[m] = nil end end)
end

local function watch(folder)
	for _, m in ipairs(folder:GetChildren()) do if m:GetAttribute("Dragon") then task.spawn(setup, m) end end
	folder.ChildAdded:Connect(function(m)
		task.wait()
		if m:GetAttribute("Dragon") then setup(m) end
	end)
end
-- (and workspace ▸ Steeds: dragons that carry riders, Crownfall's)
for _, name in ipairs({"NPCs", "Steeds"}) do
	local f = workspace:FindFirstChild(name)
	if f then watch(f) end
end
workspace.ChildAdded:Connect(function(c) if (c.Name == "NPCs" or c.Name == "Steeds") and c:IsA("Folder") then watch(c) end end)

-- eased toward a target (so a change of state never snaps)
local function ease(st, key, target, dt, rate)
	local v = st.smooth[key]
	if v == nil then v = target end
	v += (target - v) * math.min(1, dt * (rate or 6))
	st.smooth[key] = v
	return v
end

local function animate(st, dt)
	local m, root, J = st.model, st.root, st.joints
	local t = os.clock()
	local state = m:GetAttribute("DragonState") or "ground"
	local dead = m:GetAttribute("Dead") == true
	-- (its death: a boss's fall, the size of a dragon)
	if (dead or state == "dead") and not st.fell then
		st.fell = true
		task.spawn(BossIntro.falls, root.Position - Vector3.new(0, 6, 0), 3)
	end
	local downed = m:GetAttribute("Downed") == true or state == "downed" or dead
	local fly = m:GetAttribute("Fly") == true and not dead
	local flyK = ease(st, "fly", fly and 1 or 0, dt, 3)
	local downK = ease(st, "down", downed and 1 or 0, dt, 4)
	local rear = ease(st, "rear", m:GetAttribute("Rear") or 0, dt, 7)
	local jaw = ease(st, "jaw", m:GetAttribute("Jaw") or 0, dt, 12)
	local breathing = m:GetAttribute("Breath") == true and not dead
	local bYaw = ease(st, "byaw", m:GetAttribute("BreathYaw") or 0, dt, 10)
	-- its walk, off how fast it goes
	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local walk = ease(st, "walk", (fly or downed) and 0 or clamp(speed / 10, 0, 1), dt, 5)
	st.phase += dt * (1.2 + speed * 0.28)
	local p = st.phase
	-- where its head turns
	local look = m:GetAttribute("Look")
	local yawWant = 0
	if typeof(look) == "Vector3" and not downed then
		local lp = root.CFrame:PointToObjectSpace(look)
		yawWant = clamp(math.atan2(-lp.X, -lp.Z), -0.75, 0.75)
	end
	local headYaw = ease(st, "hyaw", yawWant + (breathing and bYaw or 0), dt, 5)
	if m:GetAttribute("Reel") then headYaw += math.sin(t * 15) * 0.18 end
	-- the one-shots
	local snap = pulse(st.at.Snap, 0.28)
	local swipe = pulse(st.at.Swipe, 0.6)
	local whipT = st.at.Tail and (t - st.at.Tail) or 99
	local buffet = pulse(st.at.Buffet, 0.9)

	local function set(name, cf) local j = J[name]; if j then j.Transform = cf end end
	local breathe = math.sin(t * 1.3) * 0.025

	-- the body: a little lift with each breath; slumped when down
	set("Chest", A(breathe - downK * 0.12 + rear * 0.12, 0, 0))
	set("Hips", A(-downK * 0.05, math.sin(p) * 0.04 * walk, 0))
	-- the neck and head
	local lift = rear * 0.32 - downK * 0.45 + flyK * 0.08
	set("Neck1", A(breathe + lift * 0.9, headYaw * 0.15, 0))
	set("Neck2", A(lift * 0.4, headYaw * 0.25, 0))
	set("Neck3", A(lift * 0.2 - (breathing and 0.12 or 0), headYaw * 0.3, 0))
	set("Neck4", A(-lift * 0.5 - (breathing and 0.1 or 0), headYaw * 0.3, 0))
	set("Skull", A(-lift * 0.3 - downK * 0.1, 0, 0))
	set("Jaw", A(-(jaw * 0.6 + snap * 0.55 + downK * 0.25), 0, 0))

	-- the legs: a walk (diagonal pairs); tucked in the air; splayed when down
	for _, s in ipairs({-1, 1}) do
		local k = s < 0 and "L" or "R"
		local ph = s < 0 and 0 or math.pi
		local fSwing = math.sin(p + ph) * 0.38 * walk
		local hSwing = math.sin(p + ph + math.pi) * 0.38 * walk
		local claw = (k == "R") and swipe or 0
		set("FrontArm" .. k, A(fSwing + rear * 0.45 - flyK * 0.7 + claw * 1.1 + downK * 0.5, claw * 0.4 * s, -s * downK * 0.5))
		set("FrontShin" .. k, A(-math.max(0, -math.sin(p + ph)) * 0.45 * walk + flyK * 1.1 - claw * 0.6, 0, 0))
		set("FrontPaw" .. k, A(-flyK * 0.4, 0, 0))
		set("HindHaunch" .. k, A(hSwing - flyK * 0.9 - downK * 0.2, 0, -s * downK * 0.35))
		set("HindShank" .. k, A(-math.max(0, -math.sin(p + ph + math.pi)) * 0.45 * walk + flyK * 1.2, 0, 0))
		set("HindPaw" .. k, A(-flyK * 0.5, 0, 0))
	end

	-- the wings: beating in the air (and for a buffet), half-folded and drooping on the ground
	local beat = math.sin(t * 2 * math.pi * 0.95)
	local beat2 = math.sin(t * 2 * math.pi * 0.95 - 0.8)
	for _, s in ipairs({-1, 1}) do
		local k = s < 0 and "L" or "R"
		local flap = flyK * (0.15 + 0.62 * beat) + buffet * 1.0 * math.sin(math.min(1, (t - (st.at.Buffet or 0)) / 0.9) * math.pi * 2)
		local restSweep = (1 - flyK) * (1 - downK)
		set("WingArm" .. k, A(0, -s * 0.38 * restSweep, s * (flap + restSweep * 0.18 - downK * 0.35)))
		set("WingFore" .. k, A(0, -s * 0.55 * restSweep, s * (flyK * 0.28 * beat2 - restSweep * 0.22 - downK * 0.2)))
		for i = 1, 3 do set("WingFinger" .. k .. i, A(0, -s * 0.18 * restSweep * i, s * flyK * 0.1 * beat2)) end
	end

	-- the tail: a slow sway, a whip when it sweeps, trailing straight in the air
	for i = 1, 6 do
		local sway = math.sin(t * 1.5 - i * 0.55) * 0.11 * (1 - flyK * 0.7) * (1 - downK * 0.8)
		local whip = 0
		if whipT < 1 then whip = math.sin(math.clamp(whipT * 1.2 - i * 0.07, 0, 1) * math.pi) * 0.42 end
		set("Tail" .. i, A(-flyK * 0.03 + (i == 1 and downK * -0.1 or 0), sway + whip, 0))
	end

	-- the fire
	if st.breath then
		st.breath.Rate = breathing and 260 or 0
		st.breathLight.Brightness = ease(st, "blight", breathing and 4 or 0, dt, 10)
		st.ember.Rate = 6 + jaw * 30
	end
	if st.fury then st.fury.Enabled = m:GetAttribute("Enraged") == true and not dead end
end

RunService.PreSimulation:Connect(function(dt)
	for m, st in pairs(dragons) do
		if m.Parent then
			local ok, err = pcall(animate, st, dt)
			if not ok then warn("[Dragon.client]", err); dragons[m] = nil end
		else
			dragons[m] = nil
		end
	end
end)
