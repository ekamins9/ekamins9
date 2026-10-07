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
local AnimSets = require(game:GetService("ReplicatedStorage"):WaitForChild("Combat"):WaitForChild("AnimSets"))

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
				-- forged swings turn the torso: the hips counter it so the legs stay planted
				local rootJ = hrp:FindFirstChild("RootJoint")
				if rh and lh and rootJ then
					s.rh0 = s.rh0 or rh.C0
					s.lh0 = s.lh0 or lh.C0
					local counter = AnimSets.forged() and AnimSets.counterHips(rootJ) or CFrame.identity
					rh.C0 = counter * s.rh0
					lh.C0 = counter * s.lh0
				end
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
