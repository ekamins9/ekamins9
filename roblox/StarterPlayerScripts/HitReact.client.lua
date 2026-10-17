--[[ HIT REACT — a blow that lands, seen landing. Whenever someone is struck (Combat ▸ CombatServer
     .flinch stamps HitDir / HitTick on them: a blade's clean hit, a kick, a bash), every screen near
     them shows it:

       THE BODY GIVES   a bot's whole body rocks away from the blow and twists with it, the head
                        snapping a beat later and further (damped springs on the RootJoint and the
                        Neck, laid over the animation like DrawFX / ClashFX; a player's own body
                        already jolts through CameraRig ▸ RigPose and the pose relay)
       A FLASH          the one struck flashes white for a blink (a Highlight, never more than a
                        few at once: Roblox draws 31 at most)

     Harder blows rock harder (the damage they took, TakenText). Your own body isn't flashed (your
     screen already flashes). Within 120 studs of your camera. Nothing is sent to the server. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local NEAR = 120
local MAX_FLASH = 6

-- the springs: {motor, axis (in the joint's frame), amp, freq, decay, t0, dur, delay}
local moves = {}
local function knock(motor, frame, worldAxis, amp, freq, decay, dur, delay)
	if not (motor and motor:IsA("Motor6D") and frame) or worldAxis.Magnitude < 1e-4 then return end
	local jr = (frame.CFrame * motor.C0).Rotation
	-- (a fresh blow on the same joint replaces the old one's spring)
	for i = #moves, 1, -1 do if moves[i].motor == motor then table.remove(moves, i) end end
	table.insert(moves, {motor = motor, axis = jr:VectorToObjectSpace(worldAxis.Unit), amp = amp, freq = freq, decay = decay,
		t0 = os.clock() + (delay or 0), dur = dur})
end
RunService.Stepped:Connect(function()
	if #moves == 0 then return end
	local now = os.clock()
	for i = #moves, 1, -1 do
		local m = moves[i]
		local t = now - m.t0
		if t >= m.dur or not m.motor.Parent then
			table.remove(moves, i)
		elseif t > 0 then
			local a = m.amp * math.exp(-t / m.decay) * math.sin(2 * math.pi * m.freq * t)
			m.motor.Transform = CFrame.fromAxisAngle(m.axis, a) * m.motor.Transform
		end
	end
end)

local flashes = 0
local function flash(model)
	if flashes >= MAX_FLASH then return end
	flashes += 1
	local h = Instance.new("Highlight")
	h.FillColor = Color3.fromRGB(255, 250, 236)
	h.FillTransparency = 0.25
	h.OutlineColor = Color3.fromRGB(255, 214, 120)
	h.OutlineTransparency = 0.4
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = model
	h.Parent = model
	TweenService:Create(h, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {FillTransparency = 1, OutlineTransparency = 1}):Play()
	task.delay(0.18, function() h:Destroy(); flashes -= 1 end)
end

local function react(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	local torso = model:FindFirstChild("Torso")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not (root and torso and hum) or hum.Health <= 0 then return end
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - root.Position).Magnitude > NEAR then return end
	local dir = model:GetAttribute("HitDir")
	if typeof(dir) ~= "Vector3" then return end
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 1e-3 then return end
	dir = dir.Unit
	local mine = model == player.Character
	if not mine then flash(model) end
	-- (a player's body jolts through their own CameraRig, relayed: only a bot's is rocked here)
	if Players:GetPlayerFromCharacter(model) then return end
	-- how hard: the damage it took (TakenText "-23"), a kick's little, a greatsword's a lot
	local dmg = tonumber(tostring(model:GetAttribute("TakenText") or ""):match("(%d+)")) or 18
	local k = math.clamp(dmg / 22, 0.6, 1.6)
	if model:GetAttribute("Boss") then k = k * 0.5 end
	-- away from the blow (the top of the body goes the blow's way) and twisted with it
	local tilt = Vector3.yAxis:Cross(dir)
	local side = root.CFrame.RightVector:Dot(dir)
	knock(root:FindFirstChild("RootJoint"), root, tilt, 0.28 * k, 2.4, 0.16, 0.7)
	knock(torso:FindFirstChild("Neck"), torso, tilt + Vector3.yAxis * (-side * 0.6), 0.48 * k, 3.2, 0.12, 0.6, 0.04)
	-- the arms fly a little with it
	for _, name in ipairs({"Left Shoulder", "Right Shoulder"}) do
		knock(torso:FindFirstChild(name), torso, tilt, 0.3 * k, 2.8, 0.14, 0.6, 0.02)
	end
end

-- everyone who can be struck: players' bodies, and the bots and dummies under workspace ▸ NPCs
local watched = setmetatable({}, {__mode = "k"})
local function watch(model)
	if watched[model] or not model:IsA("Model") then return end
	watched[model] = true
	model:GetAttributeChangedSignal("HitTick"):Connect(function()
		-- (the damage it took arrives with the same frame's attributes)
		task.defer(react, model)
	end)
end
local function watchPlayer(p)
	if p.Character then watch(p.Character) end
	p.CharacterAdded:Connect(watch)
end
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
task.spawn(function()
	local npcs = workspace:WaitForChild("NPCs", 1e9)
	for _, m in ipairs(npcs:GetChildren()) do watch(m) end
	npcs.ChildAdded:Connect(watch)
end)
