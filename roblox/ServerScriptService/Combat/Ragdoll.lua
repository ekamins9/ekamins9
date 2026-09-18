--[[ RAGDOLL — turns a character floppy and back.

     Every Motor6D gets a BallSocketConstraint twin and is DISABLED, not
     destroyed: the joints stay in place so scripts that hold them (the
     camera rig) keep working, and a knockdown can be undone by re-enabling
     them. Death ragdolls are simply never undone.

     Ragdoll parts go into a collision group that doesn't collide with
     itself — switching collision on for limbs that already overlap each
     other is what launches bodies into orbit.

     Requires Humanoid.BreakJointsOnDeath = false and RequiresNeck = false
     (CharacterSystems sets both): otherwise Roblox explodes the rig on
     death, and disabling the Neck motor would itself kill the humanoid.

     A player's client owns its humanoid's STATE and its parts' physics, so
     the server can't put it into Physics / GettingUp or shove it directly;
     RagdollRemote asks the owning client (CameraRig listens). Server-owned
     NPCs are handled here directly. ]]

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local Ragdoll = {}

local FOLDER = "RagdollJoints"
local GROUP  = "Ragdoll"
local UPPER_ANGLE = 45
local TWIST       = 45

pcall(function() PhysicsService:RegisterCollisionGroup(GROUP) end)
pcall(function() PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false) end)

local remote = ReplicatedStorage:FindFirstChild("RagdollRemote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "RagdollRemote"
	remote.Parent = ReplicatedStorage
end

local function log(...) DebugFlags.log("Ragdoll", ...) end
local function humanoidOf(char) return char:FindFirstChildOfClass("Humanoid") end

local function setState(char, hum, ragdolled, dir, speed)
	local plr = Players:GetPlayerFromCharacter(char)
	if plr then
		remote:FireClient(plr, ragdolled, dir, speed)
	else
		hum:ChangeState(ragdolled and Enum.HumanoidStateType.Physics or Enum.HumanoidStateType.GettingUp)
		local torso = char:FindFirstChild("Torso")
		if ragdolled and dir and torso then
			torso.AssemblyLinearVelocity = torso.AssemblyLinearVelocity + dir * (speed or 0)
		end
	end
end

function Ragdoll.isRagdolled(char)
	return char:FindFirstChild(FOLDER) ~= nil
end

-- dir/speed: optional shove applied at the torso (e.g. away from the hit)
function Ragdoll.enable(char, dir, speed)
	if Ragdoll.isRagdolled(char) then return end
	local hum = humanoidOf(char)
	if not hum then return end

	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	local count = 0
	for _, m in ipairs(char:GetDescendants()) do
		if m:IsA("Motor6D") and m.Enabled and m.Part0 and m.Part1 then
			local a0 = Instance.new("Attachment")
			a0.Name, a0.CFrame, a0.Parent = "RagdollA0", m.C0, m.Part0
			local a1 = Instance.new("Attachment")
			a1.Name, a1.CFrame, a1.Parent = "RagdollA1", m.C1, m.Part1
			local bs = Instance.new("BallSocketConstraint")
			bs.Attachment0, bs.Attachment1 = a0, a1
			bs.LimitsEnabled, bs.UpperAngle = true, UPPER_ANGLE
			bs.TwistLimitsEnabled, bs.TwistLowerAngle, bs.TwistUpperAngle = true, -TWIST, TWIST
			local ref = Instance.new("ObjectValue")
			ref.Name, ref.Value, ref.Parent = "Motor", m, bs
			bs.Parent = folder
			m.Enabled = false
			count += 1
		end
	end
	folder.Parent = char

	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CollisionGroup = GROUP
			if p.Parent == char and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
		end
	end
	char:SetAttribute("Ragdolled", true)
	hum.PlatformStand = true
	setState(char, hum, true, dir, speed)
	log("enabled on", char.Name, "-", count, "joints", dir and "with shove" or "")
end

function Ragdoll.disable(char)
	local folder = char:FindFirstChild(FOLDER)
	if not folder then return end
	for _, bs in ipairs(folder:GetChildren()) do
		local ref = bs:FindFirstChild("Motor")
		if ref and ref.Value then ref.Value.Enabled = true end
	end
	folder:Destroy()
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Attachment") and (d.Name == "RagdollA0" or d.Name == "RagdollA1") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CollisionGroup = "Default"
		end
	end
	for _, name in ipairs({"Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
		local p = char:FindFirstChild(name)
		if p then p.CanCollide = false end
	end
	char:SetAttribute("Ragdolled", nil)
	local hum = humanoidOf(char)
	if hum and hum.Health > 0 then
		hum.PlatformStand = false
		setState(char, hum, false)
	end
	log("disabled on", char.Name)
end

-- temporary ragdoll; a second knockdown while down just extends the timer
function Ragdoll.knockdown(char, duration, dir, speed)
	Ragdoll.enable(char, dir, speed)
	local until_ = os.clock() + duration
	char:SetAttribute("KnockedDownUntil", until_)
	log("knockdown", char.Name, "for", duration)
	task.delay(duration, function()
		if not char.Parent then return end
		if (char:GetAttribute("KnockedDownUntil") or 0) > until_ + 1e-3 then return end
		local hum = humanoidOf(char)
		if hum and hum.Health > 0 then Ragdoll.disable(char) end
	end)
end

return Ragdoll
