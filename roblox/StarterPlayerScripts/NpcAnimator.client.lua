--[[ NPC ANIMATOR — legs for the bots (workspace ▸ NPCs, attribute Bot). A bot
     moves on the server and swings its weapon with server-played animations;
     its walk is drawn here, on every client, from how far its root moved since
     the last frame (smoothed): the hips swing like the R6 walk (Motor6D
     Transform, local only). The drill master and other standing NPCs
     (attribute Idle) just breathe.
     It runs on PreSimulation: the Animator writes every joint's Transform each
     frame (the weapon's idle pose covers the hips too), and the joints are
     solved just after, so a swing written any earlier (RenderStepped) is
     wiped before it ever moves a leg. ]]

local RunService = game:GetService("RunService")

local state = setmetatable({}, {__mode = "k"})   -- [model] = {pos, speed, phase, amp}

-- (the NPCs folder is looked up every frame: in the Courtyard it only appears
-- with the first bot, long after this script starts)
RunService.PreSimulation:Connect(function(dt)
	local folder = workspace:FindFirstChild("NPCs")
	if not folder then return end
	for _, m in ipairs(folder:GetChildren()) do
		local bot, idle = m:GetAttribute("Bot"), m:GetAttribute("Idle")
		if bot or idle then
			local hrp, torso = m:FindFirstChild("HumanoidRootPart"), m:FindFirstChild("Torso")
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hrp and torso and hum and hum.Health > 0 and not m:GetAttribute("Ragdolled") then
				local s = state[m]
				local pos, now = hrp.Position, os.clock()
				if not s then s = {pos = pos, at = now, raw = 0, speed = 0, phase = 0, amp = 0}; state[m] = s end
				-- how fast it walks: the replicated velocity when there is one; else the
				-- distance covered over at least 0.15 s. (Frame by frame, a server-moved
				-- body arrives in jumps between network updates — most frames show no
				-- move and the rest a "teleport" — so a sprinting bot read as standing.)
				local v = hrp.AssemblyLinearVelocity
				local raw = Vector3.new(v.X, 0, v.Z).Magnitude
				if now - s.at >= 0.15 then
					local d = pos - s.pos
					local windowed = Vector3.new(d.X, 0, d.Z).Magnitude / (now - s.at)
					s.raw = windowed < 80 and windowed or 0   -- (a real teleport is not a walk)
					s.pos, s.at = pos, now
				end
				if raw < 0.05 then raw = s.raw end
				s.speed += (math.min(raw, 40) - s.speed) * math.clamp(dt * 8, 0, 1)
				local moving = s.speed > 0.6
				-- the stride eases in and out instead of snapping
				s.amp += ((moving and math.clamp(s.speed / 12, 0.4, 1) or 0) - s.amp) * math.clamp(dt * 8, 0, 1)
				s.phase += dt * (moving and (4 + s.speed * 0.55) or 1.2)
				local rh, lh = torso:FindFirstChild("Right Hip"), torso:FindFirstChild("Left Hip")
				local neck = torso:FindFirstChild("Neck")
				-- (standing still the hips are left to the weapon's animations; the
				-- arms always are: a two-handed grip needs both)
				if s.amp > 0.005 then
					local a = math.sin(s.phase) * math.rad(38) * s.amp
					if rh then rh.Transform = CFrame.Angles(0, 0, a) end
					if lh then lh.Transform = CFrame.Angles(0, 0, a) end
				end
				-- standing: a slow breath in the neck
				if idle and neck and not moving then neck.Transform = CFrame.Angles(math.sin(s.phase) * math.rad(2.5), 0, 0) end
			else
				state[m] = nil
			end
		end
	end
end)

--------------------------------------------------------------------
--  A BOT WITH A BOW, A CROSSBOW OR A STAFF: the stance players have (RigPose: the bow
--  raised and drawn to the face, the crossbow shouldered and wound, the staff planted
--  and lifted to cast), from what the server publishes on the bot — Drawing / DrawAt /
--  DrawTime, Loaded / Aiming, Reloading / ReloadAt, Casting / CastStart / CastTime /
--  CastReady, Warded, Meditating, and AimPitch. Without it a bot held its bow out stiff
--  like any tool. A melee bot is left to its animations.
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RigPose = require(ReplicatedStorage:WaitForChild("RigPose"))
local posed = setmetatable({}, {__mode = "k"})   -- [model] = {joints, origins, cur = inputs}

local function stanceOf(m)
	local tool = m:FindFirstChildOfClass("Tool")
	if not tool then return 0 end
	local kind = tool:GetAttribute("Ranged")
	if kind then return kind == "crossbow" and 2 or 1 end
	if tool:GetAttribute("Magic") then return tool:GetAttribute("Stance") or 3 end
	return 0
end
local function clamp01(x) return math.clamp(x, 0, 1) end
local function inputsFor(m, stance)
	local now = workspace:GetServerTimeNow()
	local pitch = m:GetAttribute("AimPitch") or 0
	local i = {pitch = pitch, arm = pitch * RigPose.CONFIG.ARM_PITCH, ranged = stance, aim = 0, draw = 0, reload = 0,
		bob = 0, leanX = 0, leanZ = 0, kick = 0, crouch = 0, swayX = 0, swayY = 0, hitX = 0, hitZ = 0}
	if stance == 1 then
		local at = m:GetAttribute("DrawAt")
		if m:GetAttribute("Drawing") and at then
			i.aim = 1
			i.draw = clamp01((now - at) / math.max(0.2, m:GetAttribute("DrawTime") or 1.6))
		end
		local r, rat = m:GetAttribute("Reloading"), m:GetAttribute("ReloadAt")
		if r and rat then i.reload = clamp01((now - rat) / math.max(0.2, r)) end
	elseif stance == 2 then
		i.aim = m:GetAttribute("Aiming") == true and 1 or 0
		local r, rat = m:GetAttribute("Reloading"), m:GetAttribute("ReloadAt")
		if r and rat then i.reload = clamp01((now - rat) / math.max(0.2, r)); i.aim = 0 end
	else
		local casting = m:GetAttribute("Casting") ~= nil
		if casting then
			i.aim = 1
			i.draw = m:GetAttribute("CastReady") and 1 or clamp01((now - (m:GetAttribute("CastStart") or now)) / math.max(0.1, m:GetAttribute("CastTime") or 1))
		elseif m:GetAttribute("Warded") or m:GetAttribute("Meditating") then
			i.aim = 1
		end
	end
	return i
end

RunService.RenderStepped:Connect(function(dt)
	local folder = workspace:FindFirstChild("NPCs")
	if not folder then return end
	local k = math.clamp(dt * 12, 0, 1)
	for _, m in ipairs(folder:GetChildren()) do
		if not m:GetAttribute("Bot") then continue end
		local hum = m:FindFirstChildOfClass("Humanoid")
		local stance = (hum and hum.Health > 0 and not m:GetAttribute("Ragdolled")) and stanceOf(m) or 0
		local e = posed[m]
		if stance > 0 then
			if not e then
				local j = RigPose.joints(m)
				if not j then continue end
				e = {joints = j, origins = RigPose.origins(m)}
				posed[m] = e
			end
			local want = inputsFor(m, stance)
			e.cur = e.cur and RigPose.lerpInputs and RigPose.lerpInputs(e.cur, want, k) or want
			e.cur.ranged = stance
			pcall(RigPose.apply, e.joints, RigPose.compute(e.cur, e.origins), 1)
		elseif e then
			-- (the bow put away, a sword drawn: the joints back to rest for its animations)
			for name, m6 in pairs(e.joints) do if m6.Parent and e.origins[name] then m6.C0 = e.origins[name] end end
			posed[m] = nil
		end
	end
end)
