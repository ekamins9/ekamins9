--[[ COMBAT CLIENT — the shared melee client. One instance runs per Tool;
     a weapon's LocalScript is just:

        require(game.ReplicatedStorage.Combat.CombatClient)
            .attach(script.Parent, require(script.Parent.Config))

     Handles input, animation playback, hit-feel (hitstop), the LOCAL
     turn-cap timer, the procedural kick trigger, and BLADE SWEEP HIT
     DETECTION:

     During an attack's release phase this raycasts every frame from where
     each sample point along the blade WAS last frame to where it is NOW (a
     swept trail, so a fast swing can't tunnel through a thin target). The
     first thing each ray touches is reported to the server, which validates
     it and decides the outcome. Other players' GuardHull boxes only exist
     to raycasts while they hold block, so: blade touches a GuardHull first
     = block, touches a body part first = hit, and swinging at someone's
     back never touches their hull at all.

     DEBUG (ReplicatedStorage.Debug attributes, live): Logs, Rays ]]

local UIS        = game:GetService("UserInputService")
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris     = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local player     = Players.LocalPlayer

local CombatClient = {}

--------------------------------------------------------------------
--  DEFAULTS — a weapon Config can override any key (e.g. its own KEYS)
--------------------------------------------------------------------
CombatClient.DEFAULTS = {
	HITBOX_NAME   = "Hitbox",
	BLADE_SAMPLES = 6,      -- raycast origins spread along each Hitbox's long axis
	HITSTOP_HIT   = 0.06,   -- animation freeze on a clean hit
	HITSTOP_BLOCK = 0.12,   -- longer "clang" freeze when blocked
	TRAIL          = true,  -- blade trail while the hitbox is live
	TRAIL_LIFETIME = 0.12,
	TRAIL_COLOR    = Color3.new(1, 1, 1),
	KEYS = {
		[Enum.KeyCode.Q] = "LeftSwing",
		[Enum.KeyCode.E] = "RightSwing",
		[Enum.KeyCode.F] = "Overhead",
		[Enum.KeyCode.X] = "Stab",
	},
	KICK_KEY = Enum.KeyCode.G,
}

--------------------------------------------------------------------
function CombatClient.attach(Tool, weaponConfig)
	local cfg = {}
	for k, v in pairs(CombatClient.DEFAULTS) do cfg[k] = v end
	for k, v in pairs(weaponConfig or {}) do cfg[k] = v end

	local TAG = Tool.Name .. "/Client"
	local function dprint(...) DebugFlags.log(TAG, ...) end
	local remote = Tool:WaitForChild("CombatRemote")
	local equipped = false
	local conns = {}

	----------------------------------------------------------------
	--  BLADE SAMPLES
	----------------------------------------------------------------
	local blades = {}   -- { {part=Hitbox, offsets={Vector3...}} }
	for _, d in ipairs(Tool:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == cfg.HITBOX_NAME then
			local s = d.Size
			local axis, len
			if s.X >= s.Y and s.X >= s.Z then axis, len = Vector3.xAxis, s.X
			elseif s.Y >= s.Z then          axis, len = Vector3.yAxis, s.Y
			else                            axis, len = Vector3.zAxis, s.Z end
			local offsets = {}
			for i = 0, cfg.BLADE_SAMPLES - 1 do
				local t = cfg.BLADE_SAMPLES > 1 and (i / (cfg.BLADE_SAMPLES - 1) - 0.5) or 0
				offsets[#offsets + 1] = axis * (len * t)
			end
			table.insert(blades, {part = d, offsets = offsets})
		end
	end
	dprint("blade samples:", #blades * cfg.BLADE_SAMPLES)

	-- blade trail between the two ends of each Hitbox, lit only during release
	local trails = {}
	if cfg.TRAIL then
		for _, b in ipairs(blades) do
			local a0 = Instance.new("Attachment")
			a0.Name, a0.Position, a0.Parent = "TrailA0", b.offsets[1], b.part
			local a1 = Instance.new("Attachment")
			a1.Name, a1.Position, a1.Parent = "TrailA1", b.offsets[#b.offsets], b.part
			local t = Instance.new("Trail")
			t.Attachment0, t.Attachment1 = a0, a1
			t.Lifetime = cfg.TRAIL_LIFETIME
			t.Color = ColorSequence.new(cfg.TRAIL_COLOR)
			t.Transparency = NumberSequence.new(0.3, 1)
			t.WidthScale = NumberSequence.new(1, 0.2)
			t.LightEmission = 0.5
			t.Enabled = false
			t.Parent = b.part
			table.insert(trails, t)
		end
	end
	local function setTrail(on)
		for _, t in ipairs(trails) do t.Enabled = on end
	end

	-- our own swing landing or being stopped: the camera rig reads these for a kick
	local function impact(kind)
		local char = player.Character
		if not char then return end
		char:SetAttribute("LocalImpactKind", kind)
		char:SetAttribute("LocalImpactAt", os.clock())
	end

	----------------------------------------------------------------
	--  SWEEP
	----------------------------------------------------------------
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.MaxParts = 8
	local PROBE = Vector3.new(0.2, 0.2, 0.2)

	local sweep = nil        -- {token, endsAt, last={[blade]={Vector3...}}, reported={[Humanoid]=true}}
	local swingToken = nil

	local function endSweep()
		sweep = nil
		setTrail(false)
	end

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
		overlapParams.FilterDescendantsInstances = {char}
		local last = {}
		for _, b in ipairs(blades) do
			local pts = {}
			for i, off in ipairs(b.offsets) do pts[i] = b.part.CFrame:PointToWorldSpace(off) end
			last[b] = pts
		end
		sweep = {token = token, endsAt = os.clock() + active, last = last, reported = {}}
		setTrail(true)
	end

	-- Raycasts never register a surface they START inside, and at melee range
	-- the blade is often already inside the target's guard hull (or body) when
	-- release begins. So each frame every sample point is also tested for
	-- being inside a part: a cheap bounds query, then an exact box test.
	local function pointInPart(p, part)
		local l = part.CFrame:PointToObjectSpace(p)
		local h = part.Size * 0.5
		return math.abs(l.X) <= h.X and math.abs(l.Y) <= h.Y and math.abs(l.Z) <= h.Z
	end

	-- all touches in a frame are gathered per target first, so touching a
	-- GuardHull anywhere on the blade beats touching a body part elsewhere
	local function noteTouch(frameHits, part, pos)
		local model = humanoidModelOf(part)
		if not model or model == player.Character then return end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 or sweep.reported[hum] then return end
		local isGuard = part.Name == "GuardHull"
		local e = frameHits[hum]
		if not e then
			frameHits[hum] = {model = model, part = part, pos = pos, guard = isGuard}
		elseif isGuard and not e.guard then
			e.part, e.pos, e.guard = part, pos, true
		end
	end

	table.insert(conns, RunService.Heartbeat:Connect(function()
		if not sweep then return end
		if os.clock() > sweep.endsAt then endSweep(); return end
		local showRays = DebugFlags.get("Rays")
		local frameHits = {}
		for _, b in ipairs(blades) do
			local pts = sweep.last[b]
			for i, off in ipairs(b.offsets) do
				local p    = b.part.CFrame:PointToWorldSpace(off)
				local prev = pts[i]
				local d    = p - prev
				for _, part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(p), PROBE, overlapParams)) do
					if pointInPart(p, part) then noteTouch(frameHits, part, p) end
				end
				if d.Magnitude > 1e-3 then
					local res = workspace:Raycast(prev, d, rayParams)
					if showRays then debugRay(prev, res and res.Position or p, res ~= nil) end
					if res then noteTouch(frameHits, res.Instance, res.Position) end
				end
				pts[i] = p
			end
		end
		for hum, e in pairs(frameHits) do
			sweep.reported[hum] = true
			remote:FireServer("Hit", sweep.token, e.model, e.part, e.pos, e.guard)
			dprint("blade touched", e.model.Name, e.part.Name, e.guard and "(guard)" or "")
		end
	end))

	----------------------------------------------------------------
	--  ANIMATION PLAYBACK
	----------------------------------------------------------------
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
			warn("[" .. TAG .. "] LoadAnimation failed for", id, "->", t)
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
		endSweep()
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

	table.insert(conns, remote.OnClientEvent:Connect(function(what, a, b, c, d, e, f)
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
			hitstop(cfg.HITSTOP_HIT)
			impact("hit")

		elseif what == "Blocked" then
			hitstop(cfg.HITSTOP_BLOCK)
			impact("block")
			endSweep()   -- blade stopped on their guard; it can't carry on to hit others

		elseif what == "Parried" then
			impact("parry")
			stopAttack()

		elseif what == "Cancel" then
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
	end))

	----------------------------------------------------------------
	--  INPUT
	----------------------------------------------------------------
	table.insert(conns, Tool.Equipped:Connect(function()
		equipped = true
		dprint("equipped")
	end))
	table.insert(conns, Tool.Unequipped:Connect(function()
		equipped = false
		remote:FireServer("BlockStop")
		stopAll()
	end))

	table.insert(conns, Tool.Activated:Connect(function()  -- left click cycles attacks
		remote:FireServer("Cycle")
	end))

	table.insert(conns, UIS.InputBegan:Connect(function(input, gp)
		if gp or not equipped then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			remote:FireServer("BlockStart")
		elseif input.KeyCode == cfg.KICK_KEY then
			remote:FireServer("Kick")
		elseif cfg.KEYS[input.KeyCode] then
			remote:FireServer("Attack", cfg.KEYS[input.KeyCode])
		end
	end))

	table.insert(conns, UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			remote:FireServer("BlockStop")
		end
	end))

	table.insert(conns, Tool.Destroying:Connect(function()
		for _, c in ipairs(conns) do c:Disconnect() end
	end))
end

return CombatClient
