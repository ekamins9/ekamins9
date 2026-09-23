--[[ MOVEMENT (client) — sprint, dodge and the unarmed kick for your own
     character, plus the small things a body needs when it has no weapon:
       • jumping off (Space is the dodge key)
       • stray weapon animations stopped when a Tool leaves the character
         (a disarm parents the Tool out of the player, which kills the Tool's
         LocalScript before it can stop its looping idle/guard tracks)
       • dropped-weapon prompts use YOUR pickup keybind

     Keys come from ReplicatedStorage.ClientSettings (rebind in the loadout
     menu's settings). Talks to MovementServer over ReplicatedStorage.MoveRemote.

     Dodge feel: the push is applied here immediately (this client owns its
     physics) — the server validates in parallel and charges the stamina.
     Attributes for CameraRig: LocalDodgeAt, LocalDodgeX, LocalDodgeZ. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Debris     = game:GetService("Debris")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local DebugFlags     = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Sounds         = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig    = require(ReplicatedStorage:WaitForChild("SoundConfig"))

local M = MovementConfig
local player    = Players.LocalPlayer
local character = script.Parent
local Humanoid  = character:WaitForChild("Humanoid")
local HRP       = character:WaitForChild("HumanoidRootPart")
local remote    = ReplicatedStorage:WaitForChild("MoveRemote", 10)
if not remote then warn("[Movement] MoveRemote missing — is ServerScriptService.MovementServer in place?") return end

ClientSettings.load()
local function log(...) DebugFlags.log("Movement", ...) end
local conns = {}

--------------------------------------------------------------------
--  NO JUMPING
--------------------------------------------------------------------
if M.NO_JUMP then
	Humanoid.UseJumpPower = true
	Humanoid.JumpPower = 0
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
end

--------------------------------------------------------------------
--  SPRINT (held)
--------------------------------------------------------------------
local sprintHeld, sprintSent = false, false
local function sendSprint()
	local want = sprintHeld and Humanoid.Health > 0
	if want ~= sprintSent then
		sprintSent = want
		remote:FireServer("Sprint", want)
	end
end

--------------------------------------------------------------------
--  DODGE
--------------------------------------------------------------------
local dodgeReadyAt = 0
local dodgeAttachment

local function tryDodge()
	if Humanoid.Health <= 0 then return end
	local now = os.clock()
	if now < dodgeReadyAt then log("dodge: cooldown"); return end
	if character:GetAttribute("Blocking") or character:GetAttribute("Acting") then log("dodge: busy"); return end
	if character:GetAttribute("Ragdolled") then return end
	if (character:GetAttribute("BlockMeter") or 100) < M.DODGE_COST then log("dodge: no stamina"); return end
	if Humanoid.FloorMaterial == Enum.Material.Air then log("dodge: airborne"); return end

	-- direction from the move keys, in body space (x = right, z = back).
	-- Forward is stripped: forward-diagonal becomes a side dodge, no input
	-- (or pure forward) becomes a hop back.
	local local_ = HRP.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
	local dx, dz = local_.X, math.max(local_.Z, 0)
	if math.abs(dx) < 0.3 and dz < 0.3 then dx, dz = 0, 1 end
	local dirL = Vector3.new(dx, 0, dz)
	if dirL.Magnitude < 1e-3 then return end
	dirL = dirL.Unit
	local dirW = HRP.CFrame:VectorToWorldSpace(dirL)

	dodgeReadyAt = now + M.DODGE_COOLDOWN
	remote:FireServer("Dodge", dirL.X, dirL.Z)

	-- the push: a LinearVelocity for DODGE_TIME overrides the humanoid's own
	-- walking for the burst, then hands control straight back
	if dodgeAttachment then dodgeAttachment:Destroy() end
	dodgeAttachment = Instance.new("Attachment")
	dodgeAttachment.Name = "DodgeAttachment"
	dodgeAttachment.Parent = HRP
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = dodgeAttachment
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.xAxis
	lv.SecondaryTangentAxis = Vector3.zAxis
	lv.PlaneVelocity = Vector2.new(dirW.X, dirW.Z) * M.DODGE_SPEED
	lv.MaxForce = 1e6
	lv.Parent = dodgeAttachment
	Debris:AddItem(dodgeAttachment, M.DODGE_TIME)

	character:SetAttribute("LocalDodgeX", dirL.X)
	character:SetAttribute("LocalDodgeZ", dirL.Z)
	character:SetAttribute("LocalDodgeAt", now)
	Sounds.play(SoundConfig.Dodge, HRP)
	log(string.format("dodge x=%.1f z=%.1f", dirL.X, dirL.Z))
end

--------------------------------------------------------------------
--  UNARMED KICK
--------------------------------------------------------------------
local function tryKick()
	if character:FindFirstChildOfClass("Tool") then return end   -- the weapon's CombatClient sends its own
	remote:FireServer("Kick")
end

table.insert(conns, remote.OnClientEvent:Connect(function(what, a, b)
	if what == "Kick" then
		-- same procedural leg as the armed kick (CameraRig reads these)
		character:SetAttribute("LocalTurnCapUntil", os.clock() + (a or 0))
		character:SetAttribute("LocalKickRise", b or 0.22)
		character:SetAttribute("LocalKickAt", os.clock())
	elseif what == "DodgeDenied" then
		log("server denied dodge:", a)
	end
end))

--------------------------------------------------------------------
--  INPUT
--------------------------------------------------------------------
table.insert(conns, UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	local t = input.UserInputType
	if t ~= Enum.UserInputType.Keyboard and t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.MouseButton3 then return end
	if UIS:GetFocusedTextBox() then return end
	local action = ClientSettings.actionForInput(input)
	if action == "Sprint" then sprintHeld = true; sendSprint()
	elseif action == "Dodge" then tryDodge()
	elseif action == "Kick" then tryKick() end
end))
table.insert(conns, UIS.InputChanged:Connect(function(input, gp)
	if gp or input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
	local action = ClientSettings.actionForInput(input)
	if action == "Dodge" then tryDodge() elseif action == "Kick" then tryKick() end
end))
table.insert(conns, UIS.InputEnded:Connect(function(input)
	if ClientSettings.actionForInput(input) == "Sprint" then sprintHeld = false; sendSprint() end
end))
-- a rebind while the key is down, or losing window focus, must not leave sprint stuck on
table.insert(conns, UIS.WindowFocusReleased:Connect(function() sprintHeld = false; sendSprint() end))
table.insert(conns, RunService.Heartbeat:Connect(function()
	if sprintHeld and not ClientSettings.isDown("Sprint") then sprintHeld = false; sendSprint() end
end))

--------------------------------------------------------------------
--  WEAPON LEAVING THE HAND: kill any looping weapon animation
--------------------------------------------------------------------
table.insert(conns, character.ChildRemoved:Connect(function(child)
	if not child:IsA("Tool") then return end
	task.defer(function()
		local bp = player:FindFirstChild("Backpack")
		if child.Parent == character or (bp and child.Parent == bp) then return end   -- just unequipped / swapped
		local animator = Humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:Stop(0.1) end
		end
		character:SetAttribute("LocalKickAt", 0)
		log("weapon left the character — animations cleared")
	end)
end))

--------------------------------------------------------------------
--  PICKUP PROMPTS use our keybind
--------------------------------------------------------------------
table.insert(conns, ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.Name == "PickupPrompt" then prompt.KeyboardKeyCode = ClientSettings.key("Pickup") end
end))

Humanoid.Died:Once(function()
	sprintHeld = false
	sendSprint()
end)
script.Destroying:Connect(function()
	for _, c in ipairs(conns) do c:Disconnect() end
end)
