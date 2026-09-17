--[[ PITCHFORK — CLIENT: input, animation playback, hit-feel, the LOCAL
     turn-cap timer, the procedural kick trigger, and BLADE SWEEP HIT
     DETECTION.

     During an attack's release phase this script raycasts every frame from
     where each sample point along the blade WAS last frame to where it is
     NOW (a swept trail, so a fast swing can't tunnel through a thin target).
     The first thing each ray touches is reported to the server, which
     validates it and decides the outcome. Other players' GuardHull boxes
     only exist to raycasts while they hold block, so: blade touches a
     GuardHull first = block, touches a body part first = hit, and swinging
     at someone's back never touches their hull at all. ]]

local Tool       = script.Parent
local UIS        = game:GetService("UserInputService")
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris     = game:GetService("Debris")
local player     = Players.LocalPlayer
local remote     = Tool:WaitForChild("CombatRemote")

local DEBUG      = true
local DEBUG_RAYS = false     -- draw every blade ray (green miss / red hit) for a moment
local function dprint(...) if DEBUG then print("[Pitchfork/Client]", ...) end end

local BLADE_SAMPLES = 6      -- raycast origins spread along each Hitbox's long axis
local HITSTOP_HIT   = 0.06   -- animation freeze on a clean hit
local HITSTOP_BLOCK = 0.12   -- longer "clang" freeze when blocked
local HITBOX_NAME   = "Hitbox"

local KEYS = {
	[Enum.KeyCode.Q] = "LeftSwing",
	[Enum.KeyCode.E] = "RightSwing",
	[Enum.KeyCode.F] = "Overhead",
	[Enum.KeyCode.X] = "Stab",
}
local KICK_KEY = Enum.KeyCode.G

local equipped = false

--------------------------------------------------------------------
--  BLADE SAMPLES
--------------------------------------------------------------------
local blades = {}   -- { {part=Hitbox, offsets={Vector3...}} }
for _, d in ipairs(Tool:GetDescendants()) do
	if d:IsA("BasePart") and d.Name == HITBOX_NAME then
		local s = d.Size
		local axis, len
		if s.X >= s.Y and s.X >= s.Z then axis, len = Vector3.xAxis, s.X
		elseif s.Y >= s.Z then          axis, len = Vector3.yAxis, s.Y
		else                            axis, len = Vector3.zAxis, s.Z end
		local offsets = {}
		for i = 0, BLADE_SAMPLES - 1 do
			local t = BLADE_SAMPLES > 1 and (i / (BLADE_SAMPLES - 1) - 0.5) or 0
			offsets[#offsets + 1] = axis * (len * t)
		end
		table.insert(blades, {part = d, offsets = offsets})
	end
end
dprint("blade samples:", #blades * BLADE_SAMPLES)

--------------------------------------------------------------------
--  SWEEP
--------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local sweep = nil        -- {token, endsAt, last={[blade]={Vector3...}}, reported={[Humanoid]=true}}
local swingToken = nil

local function humanoidModelOf(part)
	local m = part:FindFirstAncestorOfClass("Model")
	while m do
		if m:FindFirstChildOfClass("Humanoid") then return m end
		m = m:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function debugRay(a, b, hit)
	local d = b - a
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Material = Enum.Material.Neon
	p.Color = hit and Color3.new(1, 0.2, 0.2) or Color3.new(0.2, 1, 0.2)
	p.Size = Vector3.new(0.05, 0.05, math.max(d.Magnitude, 0.05))
	p.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -d.Magnitude / 2)
	p.Parent = workspace
	Debris:AddItem(p, 0.25)
end

local function beginSweep(token, active)
	local char = player.Character
	if not char then return end
	rayParams.FilterDescendantsInstances = {char}
	local last = {}
	for _, b in ipairs(blades) do
		local pts = {}
		for i, off in ipairs(b.offsets) do pts[i] = b.part.CFrame:PointToWorldSpace(off) end
		last[b] = pts
	end
	sweep = {token = token, endsAt = os.clock() + active, last = last, reported = {}}
end

local function onRayHit(res)
	local part  = res.Instance
	local model = humanoidModelOf(part)
	if not model or model == player.Character then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum.Health <= 0 or sweep.reported[hum] then return end
	sweep.reported[hum] = true
	remote:FireServer("Hit", sweep.token, model, part, res.Position, part.Name == "GuardHull")
	dprint("blade touched", model.Name, part.Name)
end

RunService.Heartbeat:Connect(function()
	if not sweep then return end
	if os.clock() > sweep.endsAt then sweep = nil; return end
	for _, b in ipairs(blades) do
		local pts = sweep.last[b]
		for i, off in ipairs(b.offsets) do
			local p    = b.part.CFrame:PointToWorldSpace(off)
			local prev = pts[i]
			local d    = p - prev
			if d.Magnitude > 1e-3 then
				local res = workspace:Raycast(prev, d, rayParams)
				if DEBUG_RAYS then debugRay(prev, res and res.Position or p, res ~= nil) end
				if res then onRayHit(res) end
				if not sweep then return end
			end
			pts[i] = p
		end
	end
end)

--------------------------------------------------------------------
--  ANIMATION PLAYBACK
--------------------------------------------------------------------
local idleTrack, blockTrack
local attackCache = {}
local currentTrack, currentSpeed = nil, 1

local function getAnimator()
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local anim = hum:FindFirstChildOfClass("Animator")
	if not anim then
		anim = Instance.new("Animator")
		anim.Parent = hum
	end
	return anim
end

local function loadTrack(id, priority, looped)
	if not id or id == "rbxassetid://0" then return nil end
	local anim = getAnimator()
	if not anim then dprint("no animator yet"); return nil end
	local a = Instance.new("Animation"); a.AnimationId = id
	local ok, t = pcall(function() return anim:LoadAnimation(a) end)
	if not ok then
		warn("[Pitchfork/Client] LoadAnimation failed for", id, "->", t)
		return nil
	end
	t.Priority = priority
	t.Looped   = looped or false
	return t
end

local function hitstop(duration)
	local t, s = currentTrack, currentSpeed
	if not t then return end
	t:AdjustSpeed(0.05)
	task.delay(duration, function()
		if currentTrack == t and t.IsPlaying then t:AdjustSpeed(s) end
	end)
end

local function stopAttack()
	swingToken = nil
	sweep = nil
	if currentTrack then currentTrack:Stop(); currentTrack = nil end
end

local function stopAll()
	stopAttack()
	if idleTrack  then idleTrack:Stop()  end
	if blockTrack then blockTrack:Stop() end
	for _, t in pairs(attackCache) do t:Stop() end
end

local function setLocalTurnCap(duration)
	local char = player.Character
	if char and duration and duration > 0 then
		char:SetAttribute("LocalTurnCapUntil", os.clock() + duration)
	end
end

remote.OnClientEvent:Connect(function(what, a, b, c, d, e, f)
	dprint("recv", what, a, b, c)

	if what == "Setup" then
		attackCache = {}
		stopAll()
		idleTrack  = loadTrack(a, Enum.AnimationPriority.Idle,   true)
		blockTrack = loadTrack(b, Enum.AnimationPriority.Action, true)
		if idleTrack then idleTrack:Play() else dprint("idle track failed to load") end

	elseif what == "PlayAttack" then
		local id, speed, windup, active, capDuration, token = a, (b or 1), (c or 0), (d or 0), (e or 0), f
		local t = attackCache[id]
		if not t then
			t = loadTrack(id, Enum.AnimationPriority.Action, false)
			attackCache[id] = t
		end
		if currentTrack and currentTrack ~= t then currentTrack:Stop() end
		if t then t:Stop(); t:Play(); t:AdjustSpeed(speed) end
		currentTrack, currentSpeed = t, speed
		swingToken = token
		setLocalTurnCap(capDuration)
		-- blade goes live after windup, on this client's clock
		task.delay(windup, function()
			if swingToken == token and equipped then beginSweep(token, active) end
		end)

	elseif what == "PlayKick" then
		-- the leg itself is animated procedurally by the camera rig
		setLocalTurnCap(a)
		local char = player.Character
		if char then
			char:SetAttribute("LocalKickRise", b or 0.22)
			char:SetAttribute("LocalKickAt", os.clock())
		end

	elseif what == "HitConfirm" then
		hitstop(HITSTOP_HIT)

	elseif what == "Blocked" then
		hitstop(HITSTOP_BLOCK)
		sweep = nil   -- blade stopped on their guard; it can't carry on to hit others

	elseif what == "Parried" or what == "Cancel" then
		stopAttack()

	elseif what == "Block" then
		if a == true then
			if blockTrack then blockTrack:Play() end
		else
			if blockTrack then blockTrack:Stop() end
		end

	elseif what == "Cleanup" then
		stopAll()
	end
end)

--------------------------------------------------------------------
--  INPUT
--------------------------------------------------------------------
Tool.Equipped:Connect(function()   equipped = true;  dprint("equipped") end)
Tool.Unequipped:Connect(function()
	equipped = false
	remote:FireServer("BlockStop")
	stopAll()
end)

Tool.Activated:Connect(function()  -- left click cycles attacks
	remote:FireServer("Cycle")
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp or not equipped then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		remote:FireServer("BlockStart")
	elseif input.KeyCode == KICK_KEY then
		remote:FireServer("Kick")
	elseif KEYS[input.KeyCode] then
		remote:FireServer("Attack", KEYS[input.KeyCode])
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		remote:FireServer("BlockStop")
	end
end)
