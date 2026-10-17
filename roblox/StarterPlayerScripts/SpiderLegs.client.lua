--[[ SPIDER LEGS — the dungeons' spiders walked on your screen (Combat ▸ Monsters builds them:
     body = "spider", each leg on its SpiderHip_n and SpiderKnee_n joints, the body on SpiderBody).

       the gait     as it moves, its legs step in two sets of four, each lifting and reaching
                    forward in turn, the body bobbing; standing, they twitch
       the bite     as it strikes (the body it fights with swings its hidden arm), it rears and
                    thrusts forward, its front legs up
       its skitter  running, now and then the dry click of its legs (WarAudio ▸ Skitter)
       its death    the legs curl in under it

     Only the ones within 140 studs are moved. Nothing here is sent to the server. ]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))

local NEAR = 140
local HEAR = 45
local spiders = {}   -- [model] = rig
local skitterGap = 0

local function rigOf(m)
	local look = m:WaitForChild("MonsterLook", 6)
	local root = look and look:WaitForChild("SpiderRoot", 3)
	if not root then return nil end
	root:WaitForChild("SpiderHip_8", 3)
	local torso = m:FindFirstChild("Torso")
	local body = torso and torso:FindFirstChild("SpiderBody")
	if not body then return nil end
	local legs = {}
	for n = 1, 8 do
		local hip = root:FindFirstChild("SpiderHip_" .. n)
		local upper = hip and hip.Part1
		local knee = upper and upper:WaitForChild("SpiderKnee_" .. n, 2)
		if hip and knee then
			local side = n <= 4 and -1 or 1
			local i = (n - 1) % 4 + 1
			-- (two sets of four, stepping in turn: front and third on one side with second and back
			-- on the other)
			table.insert(legs, {hip = hip, knee = knee, side = side, i = i, set = (i + (side < 0 and 0 or 1)) % 2, ph = math.random() * 6})
		end
	end
	return {
		model = m, body = body, legs = legs, shoulder = torso:FindFirstChild("Right Shoulder"),
		root = m:FindFirstChild("HumanoidRootPart"), hum = m:FindFirstChildOfClass("Humanoid"),
		scale = m:GetAttribute("MonsterScale") or 1, phase = math.random() * 6, lunge = 0, curl = 0,
		speed = 0, last = nil, nextSkitter = 0, arm = nil,
	}
end

local function watch(m)
	if not m:IsA("Model") or spiders[m] then return end
	task.spawn(function()
		local r = rigOf(m)
		if r and m.Parent then spiders[m] = r end
	end)
end

local function hookFolder(f)
	for _, m in ipairs(f:GetChildren()) do watch(m) end
	f.ChildAdded:Connect(watch)
end
local npcs = workspace:FindFirstChild("NPCs")
if npcs then hookFolder(npcs) end
workspace.ChildAdded:Connect(function(c) if c.Name == "NPCs" then hookFolder(c) end end)

-- (after the body's own animation has posed its joints, before physics places the parts: the
-- Animator writes every joint each frame, so this has to come after it)
RunService.Stepped:Connect(function(_, dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local cp = cam.CFrame.Position
	local t = os.clock()
	skitterGap -= dt
	for m, r in pairs(spiders) do
		if not m.Parent then spiders[m] = nil; continue end
		local root = r.root
		if not (root and root.Parent) then continue end
		local pos = root.Position
		local dist = (pos - cp).Magnitude
		if dist > NEAR then r.last = nil; continue end
		local dead = not r.hum or r.hum.Health <= 0
		-- how fast it goes (from where it was: what the server tells us of its velocity lags)
		local raw = 0
		if r.last then
			local d = pos - r.last
			raw = Vector3.new(d.X, 0, d.Z).Magnitude / math.max(dt, 1e-3)
			if raw > 80 then raw = 0 end
		end
		r.last = pos
		r.speed += (raw - r.speed) * math.clamp(dt * 8, 0, 1)
		local moveK = dead and 0 or math.clamp(r.speed / (7 * r.scale), 0, 1)
		r.phase += dt * (1.5 + r.speed * 1.1 / r.scale)
		-- the bite: its hidden arm swinging (how fast it turns, not where it is: it holds its guard
		-- up the whole time)
		local want = 0
		if not dead and r.shoulder then
			local now = r.shoulder.Transform
			if r.arm then
				local _, turn = (r.arm:Inverse() * now):ToAxisAngle()
				if turn / math.max(dt, 1e-3) > 5 then want = 1 end
			end
			r.arm = now
		end
		r.lunge += (want - r.lunge) * math.clamp(dt * (want > r.lunge and 14 or 5), 0, 1)
		r.curl += ((dead and 1 or 0) - r.curl) * math.clamp(dt * 4, 0, 1)
		local k = r.scale
		local bob = math.abs(math.sin(r.phase * 2)) * 0.07 * moveK
		local l = r.lunge
		r.body.Transform = CFrame.new(0, (bob + 0.25 * l) * k, -0.55 * l * k) * CFrame.Angles(math.rad(24) * l, 0, 0)
		for _, leg in ipairs(r.legs) do
			local a = r.phase * 2 + leg.set * math.pi
			local sweep = math.sin(a) * 0.38 * moveK * leg.side
			local lift = math.max(0, math.cos(a)) * 0.4 * moveK
			local twitch = (1 - moveK) * (math.sin(t * 2.3 + leg.ph) * math.sin(t * 0.7 + leg.ph * 2)) * 0.08
			local raise = (leg.i == 1 and 0.9 or (leg.i == 2 and 0.35 or 0)) * l
			local curl = r.curl
			leg.hip.Transform = CFrame.Angles(lift + raise + twitch - 0.35 * curl, sweep * (1 - curl), 0)
			leg.knee.Transform = CFrame.Angles(-lift * 0.7 - raise * 0.4 - 1.3 * curl, 0, 0)
		end
		-- its skitter, running near you
		if moveK > 0.5 and dist < HEAR and t > r.nextSkitter and skitterGap <= 0 then
			r.nextSkitter = t + 0.7 + math.random() * 0.9
			skitterGap = 0.25
			WarFX.sound("Skitter", pos, {volume = 0.4, speed = (1.05 + math.random() * 0.2) / math.sqrt(k), near = 6, range = HEAR})
		end
	end
end)
