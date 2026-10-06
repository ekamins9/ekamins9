--[[ FOOTSTEPS (client) — everyone else's steps: other players and the bots
     (workspace ▸ NPCs). Your own steps are CameraRig's, timed on the step bob.
     A body's pace comes from how far its root moved since the last frame (a
     replicated body's velocity can't be trusted), its weight from the same
     SpeedMult attributes CameraRig reads, and the sound from what's under it
     (ReplicatedStorage ▸ Footsteps). Only bodies near the camera are heard.

     Also mutes Roblox's own looping run sound on every character (ours
     included): it plays a whole run of little steps on top of ours. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Footsteps = require(ReplicatedStorage:WaitForChild("Footsteps"))
local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))

local player = Players.LocalPlayer
local STEP_RATE = 2.25                      -- steps a second at BASE_SPEED (CameraRig's cadence)
local BASE = MovementConfig.BASE_SPEED
local HEAR = 70                             -- studs: farther bodies are skipped
local VOLUME = 0.45

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

local function step(m, dt, camPos)
	local hrp = m:FindFirstChild("HumanoidRootPart")
	local hum = m:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 or hrp.Anchored or m:GetAttribute("Ragdolled") then track[m] = nil; return end
	if (hrp.Position - camPos).Magnitude > HEAR then track[m] = nil; return end
	local t = track[m]
	local pos = hrp.Position
	if not t then track[m] = {pos = pos, speed = 0, phase = 0.6}; return end
	local d = pos - t.pos
	t.pos = pos
	local raw = Vector3.new(d.X, 0, d.Z).Magnitude / math.max(dt, 1e-3)
	if raw > 60 then raw = 0 end                    -- a teleport, not a stride
	t.speed += (raw - t.speed) * math.clamp(dt * 10, 0, 1)
	if t.speed < 1.2 or hum.Sit then t.phase = 0.6; return end
	t.phase += dt * STEP_RATE * (t.speed / BASE)
	if t.phase < 1 then return end
	t.phase %= 1
	local mat = Footsteps.under(hrp, m)
	if not mat then return end                      -- in the air
	local heavy = weightOf(m)
	Footsteps.play(hrp, mat, {Volume = VOLUME * math.clamp(heavy, 0.6, 1.6), Speed = 1 / heavy ^ 0.3})
end

RunService.Heartbeat:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local camPos = cam.CFrame.Position
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then step(p.Character, dt, camPos) end
	end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then
		for _, m in ipairs(npcs:GetChildren()) do
			if m:IsA("Model") then step(m, dt, camPos) end
		end
	end
end)
