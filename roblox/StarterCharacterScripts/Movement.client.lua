--[[ MOVEMENT (client) — sprint, dodge, the short jump and the unarmed kick for
     your own character, plus the small things a body needs:
       • the jump: a short hop on the Jump bind (Space); the same key stands
         you up from a seat. Roblox's own jump stays off between hops.
       • dodge on the Dodge bind (F) or a double-tap of A / D / S
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
-- held on your mark for a countdown (HoldUntil, server time): no hops, dodges or kicks till FIGHT
local function held() return (character:GetAttribute("HoldUntil") or 0) > workspace:GetServerTimeNow() end

--------------------------------------------------------------------
--  JUMP (a short hop) and getting up from a seat
--------------------------------------------------------------------
-- Roblox's jump is off between hops (holding the key can't bunny-hop, and the
-- PlayerModule's own Space binding does nothing); tryJump turns it on for one.
Humanoid.UseJumpPower = true
Humanoid.JumpPower = M.JUMP_POWER
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
local jumpReadyAt = 0
local function hop()
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	Humanoid.JumpPower = M.JUMP_POWER
	Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	task.delay(0.25, function()
		if Humanoid.Parent then Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end
	end)
end
local function tryJump()
	if Humanoid.Health <= 0 then return end
	-- seated: stand up and step off the front, or the seat you're still
	-- touching catches you again
	if Humanoid.Sit or Humanoid.SeatPart then
		local seat = Humanoid.SeatPart
		Humanoid.Sit = false
		jumpReadyAt = os.clock() + 0.6
		task.spawn(function()
			local t0 = os.clock()
			while Humanoid.SeatPart and os.clock() - t0 < 0.6 do task.wait() end   -- the seat lets go
			if seat then
				local fwd = seat.CFrame.LookVector * Vector3.new(1, 0, 1)
				if fwd.Magnitude > 0.1 then HRP.CFrame += fwd.Unit * 2.6 end
			end
			hop()
		end)
		return
	end
	local now = os.clock()
	if now < jumpReadyAt then return end
	if held() then return end
	if character:GetAttribute("Acting") or character:GetAttribute("Blocking") or character:GetAttribute("Crouching") then return end
	if character:GetAttribute("Ragdolled") or Humanoid.PlatformStand then return end
	if (character:GetAttribute("BlockMeter") or 100) < M.JUMP_COST then log("jump: no stamina"); return end
	if Humanoid.FloorMaterial == Enum.Material.Air then return end
	jumpReadyAt = now + M.JUMP_COOLDOWN
	remote:FireServer("Jump")
	hop()
end

-- a hint while seated
local seatHint
local function showSeatHint(on)
	if on and not seatHint then
		local g = Instance.new("ScreenGui")
		g.Name = "SeatHint"
		g.ResetOnSpawn = true
		local l = Instance.new("TextLabel")
		l.AnchorPoint = Vector2.new(0.5, 1)
		l.Position = UDim2.new(0.5, 0, 1, -150)   -- above the health / energy bars
		l.Size = UDim2.fromOffset(320, 30)
		l.BackgroundColor3 = Color3.fromRGB(20, 18, 16)
		l.BackgroundTransparency = 0.35
		l.Font = Enum.Font.GothamBold
		l.TextSize = 15
		l.TextColor3 = Color3.fromRGB(240, 232, 214)
		l.Parent = g
		Instance.new("UICorner", l).CornerRadius = UDim.new(0, 8)
		g.Parent = player:WaitForChild("PlayerGui")
		seatHint = g
	end
	if seatHint then
		seatHint.Enabled = on
		local key = ClientSettings.get("Key_Jump")
		seatHint.TextLabel.Text = string.format("%s  to stand up", string.upper(key == "Space" and "SPACE" or tostring(key)))
	end
end
table.insert(conns, Humanoid.Seated:Connect(function(active) showSeatHint(active) end))
script.Destroying:Connect(function() if seatHint then seatHint:Destroy() end end)

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

-- dirOverride: a body-space direction (a double-tapped key); else the move keys
local function tryDodge(dirOverride)
	if Humanoid.Health <= 0 or Humanoid.Sit then return end
	if held() then return end
	local now = os.clock()
	if now < dodgeReadyAt then log("dodge: cooldown"); return end
	if character:GetAttribute("Blocking") or character:GetAttribute("Acting") then log("dodge: busy"); return end
	if character:GetAttribute("Ragdolled") then return end
	if (character:GetAttribute("BlockMeter") or 100) < M.DODGE_COST * (character:GetAttribute("DodgeCost") or 1) then log("dodge: no stamina"); return end
	if Humanoid.FloorMaterial == Enum.Material.Air then log("dodge: airborne"); return end

	-- direction from the move keys, in body space (x = right, z = back).
	-- Forward is stripped: forward-diagonal becomes a side dodge, no input
	-- (or pure forward) becomes a hop back.
	local local_ = dirOverride or HRP.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
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
	-- light armor dodges further, heavy armor shorter (Catalog ▸ Weights dodgeReach)
	lv.PlaneVelocity = Vector2.new(dirW.X, dirW.Z) * M.DODGE_SPEED * (character:GetAttribute("DodgeReach") or 1)
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
	if held() then return end
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
-- double-tap a direction to dodge that way (setting DodgeTap)
local TAP_DIR = {[Enum.KeyCode.A] = Vector3.new(-1, 0, 0), [Enum.KeyCode.D] = Vector3.new(1, 0, 0), [Enum.KeyCode.S] = Vector3.new(0, 0, 1)}
local lastTap = {}

table.insert(conns, UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	local t = input.UserInputType
	if t ~= Enum.UserInputType.Keyboard and t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.MouseButton3 then return end
	if UIS:GetFocusedTextBox() then return end
	local action = ClientSettings.actionForInput(input)
	if action == "Sprint" then sprintHeld = true; sendSprint()
	elseif action == "Dodge" then tryDodge()
	elseif action == "Jump" then tryJump()
	elseif action == "Kick" then tryKick() end
	local tap = TAP_DIR[input.KeyCode]
	if tap and ClientSettings.get("DodgeTap") == "On" then
		local now = os.clock()
		if now - (lastTap[input.KeyCode] or -1) <= M.DODGE_TAP then
			lastTap[input.KeyCode] = -1
			tryDodge(tap)
		else
			lastTap[input.KeyCode] = now
		end
	end
end))
table.insert(conns, UIS.InputChanged:Connect(function(input, gp)
	if gp or input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
	local action = ClientSettings.actionForInput(input)
	if action == "Dodge" then tryDodge() elseif action == "Jump" then tryJump() elseif action == "Kick" then tryKick() end
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
