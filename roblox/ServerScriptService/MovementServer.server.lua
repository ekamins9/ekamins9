--[[ MOVEMENT SERVER — sprint, facing-based speed, dodge and the unarmed
     kick. Publishes SpeedMult_Sprint / SpeedMult_Facing (composed by
     WalkSpeedGovernor) and validates dodges before charging stamina.

       ReplicatedStorage.MoveRemote (RemoteEvent, created here)
         client -> "Sprint", held(bool)        wants to sprint while this is true
         client -> "Dodge", dx, dz             local-space direction (x right, z back)
         client -> "Kick"                      unarmed kick (no Tool equipped)
         server -> "Kick", cap, windup         play the procedural kick
         server -> "DodgeDenied", reason

     Rules (numbers in ReplicatedStorage.MovementConfig):
       • sprint only while moving forward / forward-diagonal, never while
         blocking, crouching, acting (attack/kick), stunned or ragdolled
       • moving backwards or sideways is slower — that's what dodging is for
       • dodge: side or back only, costs DODGE_COST stamina, DODGE_COOLDOWN.
         The push itself happens on the client (it owns its physics); the
         server decides whether it counts and drains stamina.
     The client can only ever publish INPUT; every multiplier is written
     here from replicated state (MoveDirection, attributes). ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local DebugFlags     = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Sounds         = require(ReplicatedStorage:WaitForChild("Sounds"))
local CombatServer   = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatServer"))
local Injury         = require(ServerScriptService.Combat:WaitForChild("Injury"))
local Ragdoll        = require(ServerScriptService.Combat:WaitForChild("Ragdoll"))

local M = MovementConfig
local K = CombatServer.DEFAULTS   -- kick numbers + default sounds for the unarmed kick

local function log(...) DebugFlags.log("Movement", ...) end

local remote = Instance.new("RemoteEvent")
remote.Name = "MoveRemote"
remote.Parent = ReplicatedStorage

local sprintHeld = {}   -- [char] = true while the client holds sprint
local dodgeReady = {}   -- [char] = os.clock() when the next dodge is allowed
local kickReady  = {}   -- [char] = os.clock()
local kickBusyUntil = {}

local function alive(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0 and char.Parent ~= nil, hum
end

local function incapacitated(char)
	return (char:GetAttribute("StunnedUntil") or 0) > os.clock() or Ragdoll.isRagdolled(char)
end

--------------------------------------------------------------------
--  SPRINT + FACING (every frame, from replicated state)
--------------------------------------------------------------------
local function govern(char)
	local hum = char:WaitForChild("Humanoid", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not (hum and hrp) then return end
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not (char.Parent and hum.Parent) then
			conn:Disconnect()
			sprintHeld[char], dodgeReady[char], kickReady[char], kickBusyUntil[char] = nil, nil, nil, nil
			return
		end
		local move = hum.MoveDirection
		local facing, sprint = nil, nil
		if move.Magnitude > 0.1 then
			local dot = move.Unit:Dot(hrp.CFrame.LookVector)
			if dot < -M.BACKPEDAL_DOT then facing = M.BACKPEDAL_MULT
			elseif dot < M.FORWARD_DOT then facing = M.STRAFE_MULT end
			if sprintHeld[char] and dot >= M.SPRINT_MIN_DOT
				and not char:GetAttribute("Blocking") and not char:GetAttribute("Crouching")
				and not char:GetAttribute("Acting") and hum.Health > 0 and not incapacitated(char) then
				sprint = M.SPRINT_MULT
			end
		end
		if char:GetAttribute("SpeedMult_Facing") ~= facing then char:SetAttribute("SpeedMult_Facing", facing) end
		if char:GetAttribute("SpeedMult_Sprint") ~= sprint then char:SetAttribute("SpeedMult_Sprint", sprint) end
	end)
end

--------------------------------------------------------------------
--  DODGE
--------------------------------------------------------------------
local function dodge(plr, char, dx, dz)
	local ok, hum = alive(char)
	if not ok then return end
	if type(dx) ~= "number" or type(dz) ~= "number" or dx ~= dx or dz ~= dz then return end
	local now = os.clock()
	local why
	if now < (dodgeReady[char] or 0) then why = "cooldown"
	elseif char:GetAttribute("Blocking") then why = "blocking"
	elseif char:GetAttribute("Acting") then why = "mid-action"
	elseif incapacitated(char) then why = "stunned"
	elseif (char:GetAttribute("BlockMeter") or 100) < M.DODGE_COST then why = "stamina"
	elseif dz < -0.01 then why = "no forward dodge"           -- the client already strips this; belt and braces
	elseif math.abs(dx) < 0.05 and math.abs(dz) < 0.05 then why = "no direction" end
	if why then
		log(plr.Name, "dodge denied:", why)
		remote:FireClient(plr, "DodgeDenied", why)
		return
	end
	dodgeReady[char] = now + M.DODGE_COOLDOWN
	char:SetAttribute("DodgeReadyAt", dodgeReady[char])   -- server clock; the client keeps its own
	CombatServer.drainStamina(char, M.DODGE_COST, char:GetAttribute("BlockMax"))
	log(plr.Name, string.format("dodge %.1f %.1f", dx, dz))
end

--------------------------------------------------------------------
--  UNARMED KICK (a weapon's CombatServer handles it while one is held)
--------------------------------------------------------------------
local function kick(plr, char)
	local ok, hum = alive(char)
	if not ok then return end
	if char:FindFirstChildOfClass("Tool") then return end   -- the weapon owns kicks
	local now = os.clock()
	if incapacitated(char) or char:GetAttribute("Blocking") or char:GetAttribute("Acting") then return end
	if now < (kickReady[char] or 0) or now < (kickBusyUntil[char] or 0) then return end
	if not Injury.hasLimb(char, "Right Leg") then return end
	kickReady[char]    = now + K.KICK_COOLDOWN
	kickBusyUntil[char] = now + K.KICK_WINDUP + K.KICK_RECOVERY
	CombatServer.drainStamina(char, K.KICK_COST, char:GetAttribute("BlockMax"))
	char:SetAttribute("Acting", true)
	char:SetAttribute("SpeedMult_Swing", K.SWING_SLOW)
	char:SetAttribute("TurnCapUntil", now + K.KICK_WINDUP + K.TURN_CAP_EXTRA)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	Sounds.play(K.SOUNDS.Kick, hrp)
	remote:FireClient(plr, "Kick", K.KICK_WINDUP + K.TURN_CAP_EXTRA, K.KICK_WINDUP)
	local stamp = kickBusyUntil[char]
	task.delay(K.KICK_WINDUP, function()
		if kickBusyUntil[char] ~= stamp or not char.Parent then return end
		if not incapacitated(char) then
			CombatServer.resolveKick(char, K, {
				sfx = function(slot, at) Sounds.play(K.SOUNDS[slot], at or hrp) end,
				dprint = log,
			})
		end
	end)
	task.delay(K.KICK_WINDUP + K.KICK_RECOVERY, function()
		if kickBusyUntil[char] ~= stamp or not char.Parent then return end
		char:SetAttribute("Acting", nil)
		char:SetAttribute("SpeedMult_Swing", nil)
	end)
end

--------------------------------------------------------------------
remote.OnServerEvent:Connect(function(plr, what, a, b)
	local char = plr.Character
	if not char then return end
	if what == "Sprint" then
		sprintHeld[char] = a == true or nil
	elseif what == "Dodge" then
		dodge(plr, char, a, b)
	elseif what == "Kick" then
		kick(plr, char)
	end
end)

local function onPlayer(p)
	p.CharacterAdded:Connect(govern)
	if p.Character then govern(p.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
