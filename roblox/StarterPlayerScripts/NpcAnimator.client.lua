--[[ NPC ANIMATOR — legs for the bots (workspace ▸ NPCs, attribute Bot). A bot
     moves on the server and swings its weapon with server-played animations;
     its walk is drawn here, on every client, from how fast its root moves:
     the hips swing like the R6 walk (Motor6D Transform, local only). The
     drill master and other standing NPCs (attribute Idle) just breathe. ]]

local RunService = game:GetService("RunService")

local folder = workspace:WaitForChild("NPCs", 60)
local phase = setmetatable({}, {__mode = "k"})

RunService.RenderStepped:Connect(function(dt)
	if not folder then return end
	for _, m in ipairs(folder:GetChildren()) do
		local bot, idle = m:GetAttribute("Bot"), m:GetAttribute("Idle")
		if bot or idle then
			local hrp, torso = m:FindFirstChild("HumanoidRootPart"), m:FindFirstChild("Torso")
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hrp and torso and hum and hum.Health > 0 and not m:GetAttribute("Ragdolled") then
				local v = hrp.AssemblyLinearVelocity
				local speed = Vector3.new(v.X, 0, v.Z).Magnitude
				local p = (phase[m] or 0) + dt * (speed > 0.5 and (4 + speed * 0.55) or 1.2)
				phase[m] = p
				local rh, lh = torso:FindFirstChild("Right Hip"), torso:FindFirstChild("Left Hip")
				local neck = torso:FindFirstChild("Neck")
				if speed > 0.5 then
					local a = math.sin(p) * math.rad(36) * math.clamp(speed / 12, 0.35, 1)
					if rh then rh.Transform = CFrame.Angles(0, 0, a) end
					if lh then lh.Transform = CFrame.Angles(0, 0, a) end
				else
					if rh then rh.Transform = CFrame.identity end
					if lh then lh.Transform = CFrame.identity end
					-- standing: a slow breath in the neck
					if idle and neck then neck.Transform = CFrame.Angles(math.sin(p) * math.rad(2.5), 0, 0) end
				end
			end
		end
	end
end)
