--[[ RIG REPLICATOR — applies OTHER players' relayed RigPose inputs to their
     characters on this client, smoothed, using the exact math CameraRig uses
     for your own body. Lives in StarterPlayerScripts (one per player, survives
     respawns) because it tracks everyone else, not your character. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RigPose = require(ReplicatedStorage:WaitForChild("RigPose"))
local remote  = ReplicatedStorage:WaitForChild("PoseRemote")
local player  = Players.LocalPlayer

local SMOOTH  = 14     -- input smoothing toward the latest packet
local STALE   = 1.0    -- seconds without a packet before we stop posing them

local poses = {}   -- [Player] = {target=, current=, at=, char=, joints=, origins=}

remote.OnClientEvent:Connect(function(plr, arr)
	if plr == player then return end
	local inputs = RigPose.unpack(arr)
	if not inputs then return end
	local e = poses[plr]
	if not e then e = {}; poses[plr] = e end
	e.target, e.at = inputs, os.clock()
end)

Players.PlayerRemoving:Connect(function(plr) poses[plr] = nil end)

RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	local alpha = math.clamp(dt * SMOOTH, 0, 1)
	for plr, e in pairs(poses) do
		local char = plr.Character
		if char ~= e.char then
			e.char, e.joints, e.origins, e.current = char, nil, nil, nil
		end
		if char and not e.joints then
			e.joints  = RigPose.joints(char)
			e.origins = e.joints and RigPose.origins(char)
		end
		if e.joints and e.target and now - e.at < STALE then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 and not hum.PlatformStand then
				e.current = e.current and RigPose.lerpInputs(e.current, e.target, alpha) or e.target
				RigPose.apply(e.joints, RigPose.compute(e.current, e.origins), 1)
			end
		end
	end
end)
