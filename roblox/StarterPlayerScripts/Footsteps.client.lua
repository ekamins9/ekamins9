--[[ FOOTSTEPS (client) — everyone else's steps (and everyone's prints): other players and the bots
     (workspace ▸ NPCs). Your own steps are CameraRig's, timed on the step bob.
     A body's pace comes from how far its root moved since the last frame (a
     replicated body's velocity can't be trusted), its weight from the same
     SpeedMult attributes CameraRig reads, and the sound from what's under it
     (ReplicatedStorage ▸ Footsteps). Only bodies near the camera are heard.

     Also mutes Roblox's own looping run sound on every character (ours
     included): it plays a whole run of little steps on top of ours.

     MARKS ON THE GROUND (every body near the camera, yours too): a step into snow, sand, mud or
     bare earth presses a print there (left, right, along the way it walks), fading over a while
     (snow keeps them longest); a run kicks up a little puff of it (snow, sand, dust). At most
     MARKS prints at once, the oldest going first (a phone: fewer, and no puffs). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Footsteps = require(ReplicatedStorage:WaitForChild("Footsteps"))
local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))

local player = Players.LocalPlayer
local STEP_RATE = 2.25                      -- steps a second at BASE_SPEED (CameraRig's cadence)
local BASE = MovementConfig.BASE_SPEED
local HEAR = 70                             -- studs: farther bodies are skipped
local VOLUME = 0.45
local PHONE = Device.kind() == "phone"
local MARKS = PHONE and 100 or 220          -- prints on the ground at once, at most (fewer on a phone)

--------------------------------------------------------------------
--  ROBLOX'S RUN LOOP: muted wherever it appears
--------------------------------------------------------------------
local function mute(s)
	if s:IsA("Sound") and (s.Name == "Running" or s.Name == "Climbing") then
		s.Volume = 0
		s:GetPropertyChangedSignal("Volume"):Connect(function() if s.Volume ~= 0 then s.Volume = 0 end end)
	end
end
local function watchCharacter(char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	for _, s in ipairs(hrp:GetChildren()) do mute(s) end
	hrp.ChildAdded:Connect(mute)
end
local function watchPlayer(p)
	p.CharacterAdded:Connect(watchCharacter)
	if p.Character then task.spawn(watchCharacter, p.Character) end
end
Players.PlayerAdded:Connect(watchPlayer)
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end

--------------------------------------------------------------------
--  MARKS ON THE GROUND
--------------------------------------------------------------------
-- what takes a print: how dark it is against the ground, how long it lasts, the puff's colour
-- (and how see-through it starts: a print is an impression, not a stone)
local SOFT = {
	Snow = {k = 0.6, a = 0.4, life = 40, puff = Color3.fromRGB(240, 244, 250), tint = Color3.fromRGB(200, 214, 236)},
	Sand = {k = 0.8, a = 0.45, life = 24, puff = Color3.fromRGB(214, 192, 150)},
	Salt = {k = 0.85, a = 0.45, life = 24, puff = Color3.fromRGB(230, 226, 220)},
	Mud = {k = 0.66, a = 0.4, life = 26},
	Ground = {k = 0.78, a = 0.6, life = 10, puff = Color3.fromRGB(150, 128, 100)},
}
local markFolder = Instance.new("Folder")
markFolder.Name = "GroundMarks"
markFolder.Parent = workspace
local marks, head = {}, 0
local markRay = RaycastParams.new()
markRay.FilterType = Enum.RaycastFilterType.Exclude
markRay.IgnoreWater = true
local puffAt
local function puff(pos, color)
	if not puffAt then
		puffAt = Instance.new("Attachment")
		puffAt.Name = "StepPuff"
		puffAt.Parent = workspace.Terrain
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Size = NumberSequence.new(0.5, 1.8)
		e.Transparency = NumberSequence.new(0.45, 1)
		e.Lifetime = NumberRange.new(0.5, 0.9)
		e.Speed = NumberRange.new(1.5, 3)
		e.SpreadAngle = Vector2.new(70, 70)
		e.Acceleration = Vector3.new(0, 1, 0)
		e.Rate = 0
		e.Parent = puffAt
	end
	local e = puffAt:FindFirstChildOfClass("ParticleEmitter")
	puffAt.WorldPosition = pos
	e.Color = ColorSequence.new(color)
	e:Emit(3)
end
local function mark(m, hrp, side, speed)
	markRay.FilterDescendantsInstances = {m, markFolder}
	local foot = hrp.Position + hrp.CFrame.RightVector * (side * 0.5)
	local hit = workspace:Raycast(foot, Vector3.new(0, -4.4, 0), markRay)
	if not hit then return end
	local soft = SOFT[hit.Material.Name]
	if not soft or hit.Normal.Y < 0.7 then return end
	local base = hit.Instance == workspace.Terrain and workspace.Terrain:GetMaterialColor(hit.Material) or (hit.Instance:IsA("BasePart") and hit.Instance.Color) or Color3.new(0.5, 0.5, 0.5)
	local up = hit.Normal
	local look = hrp.CFrame.LookVector
	local fwd = look - up * look:Dot(up)
	if fwd.Magnitude < 0.1 then return end
	fwd = fwd.Unit
	local right = fwd:Cross(up)
	-- (the oldest print goes back into use)
	head = head % MARKS + 1
	local e = marks[head]
	if not e then
		local p = Instance.new("Part")
		p.Name = "Print"
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material = Enum.Material.SmoothPlastic
		p.Size = Vector3.new(0.55, 0.04, 1)
		local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p
		p.Parent = markFolder
		e = {part = p}
		marks[head] = e
	end
	e.part.CFrame = CFrame.fromMatrix(hit.Position + up * 0.02, right, up)
	local tint = soft.tint or Color3.new(1, 1, 1)
	e.part.Color = Color3.new(base.R * soft.k * tint.R, base.G * soft.k * tint.G, base.B * soft.k * tint.B)
	e.part.Transparency = soft.a
	e.born, e.life, e.a = os.clock(), soft.life, soft.a
	if soft.puff and speed > 17 and not PHONE then puff(hit.Position + up * 0.3, soft.puff) end
end
-- (prints fade out over their life: a few at a time, a few times a second)
task.spawn(function()
	local i = 0
	while true do
		task.wait(0.25)
		local now = os.clock()
		for _ = 1, 60 do
			i = i % MARKS + 1
			local e = marks[i]
			if e and e.born then
				local u = (now - e.born) / e.life
				if u >= 1 then
					e.born = nil
					e.part.Transparency = 1
				elseif u > 0.6 then
					e.part.Transparency = e.a + (1 - e.a) * (u - 0.6) / 0.4
				end
			end
		end
	end
end)

--------------------------------------------------------------------
--  OTHER BODIES' STEPS
--------------------------------------------------------------------
local track = setmetatable({}, {__mode = "k"})   -- [model] = {pos, speed, phase}

local function weightOf(char)
	local ratio = 1
	for _, k in ipairs({"SpeedMult", "SpeedMult_Weapon", "SpeedMult_Armor", "SpeedMult_Limbs"}) do
		local v = char:GetAttribute(k)
		if type(v) == "number" then ratio *= v end
	end
	return math.clamp(1 / math.max(ratio, 0.05), 0.6, 1.5)
end

local function step(m, dt, camPos, quiet)
	local hrp = m:FindFirstChild("HumanoidRootPart")
	local hum = m:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 or hrp.Anchored or m:GetAttribute("Ragdolled") then track[m] = nil; return end
	if (hrp.Position - camPos).Magnitude > HEAR then track[m] = nil; return end
	local t = track[m]
	local pos = hrp.Position
	if not t then track[m] = {pos = pos, speed = 0, phase = 0.6, side = 1}; return end
	local d = pos - t.pos
	t.pos = pos
	local raw = Vector3.new(d.X, 0, d.Z).Magnitude / math.max(dt, 1e-3)
	if raw > 60 then raw = 0 end                    -- a teleport, not a stride
	t.speed += (raw - t.speed) * math.clamp(dt * 10, 0, 1)
	if t.speed < 1.2 or hum.Sit then t.phase = 0.6; return end
	t.phase += dt * STEP_RATE * (t.speed / BASE)
	if t.phase < 1 then return end
	t.phase %= 1
	t.side = -t.side
	local mat = Footsteps.under(hrp, m)
	if not mat then return end                      -- in the air
	if SOFT[mat.Name] then mark(m, hrp, t.side, t.speed) end
	if quiet then return end                        -- (yours: CameraRig plays your steps)
	local heavy = weightOf(m)
	Footsteps.play(hrp, mat, {Volume = VOLUME * math.clamp(heavy, 0.6, 1.6), Speed = 1 / heavy ^ 0.3})
end

RunService.Heartbeat:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local camPos = cam.CFrame.Position
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then step(p.Character, dt, camPos, p == player) end
	end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then
		for _, m in ipairs(npcs:GetChildren()) do
			if m:IsA("Model") then step(m, dt, camPos) end
		end
	end
end)
