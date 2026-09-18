--[[ POSE RELAY — makes everyone's procedural rig visible to everyone else.
     Each client sends its RigPose inputs ~20×/s over an UnreliableRemoteEvent;
     this forwards them to every OTHER player (never back to the sender, so
     the owner's own rig is never overwritten). Nothing is applied on the
     server. Also owns the crouch attribute so the WalkSpeed governor can
     slow a crouching player. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RigPose = require(ReplicatedStorage:WaitForChild("RigPose"))

local CROUCH_SPEED = 0.55   -- WalkSpeed multiplier while crouched (SpeedMult_Crouch)

local pose = ReplicatedStorage:FindFirstChild("PoseRemote")
if not pose then
	pose = Instance.new("UnreliableRemoteEvent")
	pose.Name = "PoseRemote"
	pose.Parent = ReplicatedStorage
end
local crouch = ReplicatedStorage:FindFirstChild("CrouchRemote")
if not crouch then
	crouch = Instance.new("RemoteEvent")
	crouch.Name = "CrouchRemote"
	crouch.Parent = ReplicatedStorage
end

pose.OnServerEvent:Connect(function(plr, arr)
	if not RigPose.unpack(arr) then return end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= plr then pose:FireClient(other, plr, arr) end
	end
end)

crouch.OnServerEvent:Connect(function(plr, on)
	local char = plr.Character
	if not char then return end
	on = on == true
	char:SetAttribute("Crouching", on or nil)
	char:SetAttribute("SpeedMult_Crouch", on and CROUCH_SPEED or nil)
end)
