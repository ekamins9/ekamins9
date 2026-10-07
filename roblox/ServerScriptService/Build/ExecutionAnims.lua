--[[ EXECUTION ANIMS — the finishers, made from the game's OWN hand-made clips:
     each one is a few of those clips' keyframes (the idle, the overhead's raise
     and strike, the stab's draw and drive, the swing's start and end) re-timed,
     held, and leaned a little — the same simple style (torso, arms, head; the
     grip as the source pose has it). Nothing is solved or generated.

     A step: {t, from = "<clip>:<keyframe index>", lean = degrees forward (+) /
     back (-), twist = degrees}. The clip's Impact (seconds) is when the blow
     lands; CombatServer kills the victim then.

     Studio:  require(ServerScriptService.Build.ExecutionAnims).build()
              → ServerStorage ▸ ExecutionAnims ▸ <id> (KeyframeSequences)
     Upload like the other clips (scripts/upload_anims.py), the ids go into
     ReplicatedStorage ▸ ExecutionAnims ▸ <id> (Animation, attribute Impact). ]]

local KSP = game:GetService("KeyframeSequenceProvider")
local ServerStorage = game:GetService("ServerStorage")

local EA = {}

-- the source clips (the Longsword's, which every weapon shares)
EA.SOURCE = {
	Idle          = "rbxassetid://132465214430348",
	RightOverhead = "rbxassetid://81289899270401",
	RightStab     = "rbxassetid://108978202248647",
	RightSwing    = "rbxassetid://73820534240915",
}

EA.CLIPS = {
	-- a raised overhead, a breath, brought down hard
	Finisher = {impact = 1.0, steps = {
		{t = 0,    from = "Idle:1"},
		{t = 0.45, from = "RightOverhead:1", lean = -8},
		{t = 0.85, from = "RightOverhead:1", lean = -10},
		{t = 1.0,  from = "RightOverhead:2", lean = 20},
		{t = 1.5,  from = "RightOverhead:2", lean = 16},
		{t = 1.9,  from = "Idle:1"},
	}},
	-- drawn back, driven through, twisted, pulled free
	Skewer = {impact = 0.88, steps = {
		{t = 0,    from = "Idle:1"},
		{t = 0.4,  from = "RightStab:1", lean = -4},
		{t = 0.75, from = "RightStab:1", lean = -6},
		{t = 0.88, from = "RightStab:2", lean = 16},
		{t = 1.3,  from = "RightStab:2", lean = 12, twist = 12},
		{t = 1.55, from = "RightStab:1", lean = 4},
		{t = 1.95, from = "Idle:1"},
	}},
	-- the headsman's pause: raised high and held, then the drop
	HeadsmansDue = {impact = 1.32, steps = {
		{t = 0,    from = "Idle:1"},
		{t = 0.5,  from = "RightOverhead:1", lean = -14},
		{t = 1.2,  from = "RightOverhead:1", lean = -16},
		{t = 1.32, from = "RightOverhead:2", lean = 26},
		{t = 1.9,  from = "RightOverhead:2", lean = 22},
		{t = 2.3,  from = "Idle:1"},
	}},
	-- a cut across, then the overhead to end it
	Kingslayer = {impact = 1.3, steps = {
		{t = 0,    from = "Idle:1"},
		{t = 0.35, from = "RightSwing:1"},
		{t = 0.55, from = "RightSwing:2", lean = 6},
		{t = 0.95, from = "RightOverhead:1", lean = -12},
		{t = 1.15, from = "RightOverhead:1", lean = -14},
		{t = 1.3,  from = "RightOverhead:2", lean = 26},
		{t = 1.9,  from = "RightOverhead:2", lean = 20},
		{t = 2.3,  from = "Idle:1"},
	}},
}

-- the source clip: a saved copy in ServerStorage ▸ ExecutionAnims ▸ Sources ▸ <name>
-- if there is one, else from the asset (KeyframeSequenceProvider hands out a
-- CACHED instance: never Destroy what it returns, or it's empty until restart)
local function sourceSeq(name, id)
	local folder = ServerStorage:FindFirstChild("ExecutionAnims")
	local saved = folder and folder:FindFirstChild("Sources") and folder.Sources:FindFirstChild(name)
	if saved and #saved:GetKeyframes() > 0 then return saved end
	return KSP:GetKeyframeSequenceAsync(id)
end

-- every keyframe of a source clip as {poseName = CFrame} (missing poses carried from the one before)
local function framesOf(name, id)
	local ks = sourceSeq(name, id)
	local kfs = ks:GetKeyframes()
	table.sort(kfs, function(a, b) return a.Time < b.Time end)
	local out, carry = {}, {}
	for _, kf in ipairs(kfs) do
		local poses = {}
		for _, p in ipairs(kf:GetDescendants()) do
			if p:IsA("Pose") and p.Weight > 0 then carry[p.Name] = p.CFrame end
		end
		for k, v in pairs(carry) do poses[k] = v end
		table.insert(out, poses)
	end
	return out
end

local TREE = {Torso = "HumanoidRootPart", Head = "Torso", ["Right Arm"] = "Torso", ["Left Arm"] = "Torso", Handle = "Right Arm"}

local function keyframe(t, poses, name)
	local kf = Instance.new("Keyframe")
	kf.Time = t
	if name then kf.Name = name end
	local root = Instance.new("Pose"); root.Name = "HumanoidRootPart"; root.Weight = 0; root.Parent = kf
	local made = {HumanoidRootPart = root}
	local function make(n)
		if made[n] then return made[n] end
		local parent = make(TREE[n])
		local p = Instance.new("Pose"); p.Name = n; p.CFrame = poses[n] or CFrame.identity; p.Parent = parent
		made[n] = p
		return p
	end
	for _, n in ipairs({"Torso", "Head", "Right Arm", "Left Arm", "Handle"}) do
		if poses[n] or n == "Torso" then make(n) end
	end
	return kf
end

function EA.sequence(id)
	local def = EA.CLIPS[id]
	local src = {}
	for name, aid in pairs(EA.SOURCE) do src[name] = framesOf(name, aid) end
	local ks = Instance.new("KeyframeSequence")
	ks.Name = id
	ks.Loop = false
	ks.Priority = Enum.AnimationPriority.Action4
	for _, st in ipairs(def.steps) do
		local clip, idx = st.from:match("^(%w+):(%d+)$")
		local poses = table.clone(src[clip][tonumber(idx)] or src[clip][1])
		local torso = poses.Torso or CFrame.identity
		-- +X leans forward, +Z twists (the RootJoint's frame)
		poses.Torso = torso * CFrame.Angles(math.rad(st.lean or 0), 0, math.rad(st.twist or 0))
		keyframe(st.t, poses, math.abs(st.t - def.impact) < 1e-3 and "Impact" or nil).Parent = ks
	end
	ks:SetAttribute("Impact", def.impact)
	return ks
end

function EA.build()
	local folder = ServerStorage:FindFirstChild("ExecutionAnims") or Instance.new("Folder")
	folder.Name = "ExecutionAnims"
	folder.Parent = ServerStorage
	local n = 0
	for id in pairs(EA.CLIPS) do
		local old = folder:FindFirstChild(id); if old then old:Destroy() end
		EA.sequence(id).Parent = folder
		n += 1
	end
	return n
end

return EA
