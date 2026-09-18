--[[ TEST DUMMIES — chat commands that spawn an R6 dummy holding WEAPON_NAME
     a few studs in front of you, facing you, running one behaviour:

        /spawn idle     stands there with the weapon out
        /spawn block    holds guard forever
        /spawn parry    raises guard the instant you start a swing (timed parry)
        /spawn attack   cycles attacks at you every ATTACK_INTERVAL
        /spawn clear    removes all dummies

     Dummies live in workspace.NPCs, so CharacterSystems gives them ragdoll,
     bleeding and death like players. Their weapon runs the normal combat
     module in NPC mode (server-side animations + server-side blade sweep),
     so an attack dummy can actually hit you and a parry dummy can actually
     parry you. Note: the server doesn't render RigPose, so dummies see your
     un-crouched, un-leaned body. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPack   = game:GetService("StarterPack")
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatServer = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatServer"))

--------------------------------------------------------------------
local WEAPON_NAME     = "Greatsword"   -- looked up in StarterPack, then ServerStorage
local SPAWN_DIST      = 8
local ATTACK_INTERVAL = 1.6
local PARRY_RANGE     = 20             -- parry dummy reacts to swings started within this range
local CORPSE_TIME     = 10
--------------------------------------------------------------------

local folder = workspace:FindFirstChild("NPCs")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "NPCs"
	folder.Parent = workspace
end

local dummies = {}

local function findWeapon()
	return StarterPack:FindFirstChild(WEAPON_NAME) or ServerStorage:FindFirstChild(WEAPON_NAME)
end

local function nearestPlayer(pos, range)
	local best, bestD = nil, range or math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local d = (hrp.Position - pos).Magnitude
			if d < bestD then best, bestD = p.Character, d end
		end
	end
	return best
end

local function remove(entry)
	for _, c in ipairs(entry.conns) do c:Disconnect() end
	if entry.model.Parent then entry.model:Destroy() end
	for i, e in ipairs(dummies) do
		if e == entry then table.remove(dummies, i); break end
	end
end

local function clearAll()
	for i = #dummies, 1, -1 do remove(dummies[i]) end
end

local function spawnDummy(player, mode)
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local weapon = findWeapon()
	if not weapon then
		warn("[TestDummies] no Tool named '" .. WEAPON_NAME .. "' in StarterPack or ServerStorage")
		return
	end

	local model = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	model.Name = "Dummy_" .. mode
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayName = mode:upper() .. " DUMMY"
	hum.WalkSpeed, hum.JumpPower = 0, 0

	local pos = hrp.Position + hrp.CFrame.LookVector * SPAWN_DIST
	model:PivotTo(CFrame.lookAt(pos, Vector3.new(hrp.Position.X, pos.Y, hrp.Position.Z)))
	model.Parent = folder
	local dhrp = model:WaitForChild("HumanoidRootPart")
	dhrp:SetNetworkOwner(nil)   -- server simulates it, so its blade sweep sees true positions

	local tool = weapon:Clone()
	tool.Parent = model
	local ctrl
	for _ = 1, 60 do
		ctrl = CombatServer.get(tool)
		if ctrl then break end
		task.wait(0.05)
	end
	if not ctrl then
		warn("[TestDummies] weapon never attached a combat controller — is its Server script in place?")
	end

	local entry = {model = model, tool = tool, ctrl = ctrl, mode = mode, conns = {}, blocking = false}
	table.insert(dummies, entry)

	-- always face the nearest player (yaw only) unless ragdolled
	table.insert(entry.conns, RunService.Heartbeat:Connect(function()
		if hum.PlatformStand or hum.Health <= 0 then return end
		local target = nearestPlayer(dhrp.Position)
		local thrp = target and target:FindFirstChild("HumanoidRootPart")
		if not thrp then return end
		local look = Vector3.new(thrp.Position.X, dhrp.Position.Y, thrp.Position.Z)
		if (look - dhrp.Position).Magnitude > 0.5 then
			dhrp.CFrame = CFrame.lookAt(dhrp.Position, look)
		end
	end))

	if ctrl then
		if mode == "block" then
			task.delay(0.2, function() if model.Parent then ctrl.blockStart() end end)

		elseif mode == "parry" then
			-- SpeedMult_Swing appears on a character the moment its windup starts
			table.insert(entry.conns, RunService.Heartbeat:Connect(function()
				if hum.Health <= 0 then return end
				local target = nearestPlayer(dhrp.Position, PARRY_RANGE)
				local swinging = target ~= nil and target:GetAttribute("SpeedMult_Swing") ~= nil
				if swinging and not entry.blocking then
					entry.blocking = true
					ctrl.blockStart()
				elseif not swinging and entry.blocking then
					entry.blocking = false
					task.delay(0.3, function()
						if model.Parent and not entry.blocking then ctrl.blockStop() end
					end)
				end
			end))

		elseif mode == "attack" then
			task.spawn(function()
				task.wait(0.5)
				while model.Parent and hum.Health > 0 do
					ctrl.cycle()
					task.wait(ATTACK_INTERVAL)
				end
			end)
		end
	end

	hum.Died:Once(function()
		task.delay(CORPSE_TIME, function() remove(entry) end)
	end)
end

local MODES = {idle = true, block = true, parry = true, attack = true}

local function handle(player, text)
	local cmd, arg = text:match("^/(%a+)%s*(%a*)")
	if not cmd or cmd:lower() ~= "spawn" then return end
	arg = (arg or ""):lower()
	if arg == "clear" then clearAll(); return end
	if arg == "" then arg = "idle" end
	if not MODES[arg] then
		warn("[TestDummies] unknown mode '" .. arg .. "' — use idle | block | parry | attack | clear")
		return
	end
	spawnDummy(player, arg)
end

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "SpawnDummy"
	cmd.PrimaryAlias = "/spawn"
	cmd.Parent = TextChatService
	cmd.Triggered:Connect(function(source, text)
		local plr = Players:GetPlayerByUserId(source.UserId)
		if plr then handle(plr, text) end
	end)
else
	local function hook(plr) plr.Chatted:Connect(function(msg) handle(plr, msg) end) end
	Players.PlayerAdded:Connect(hook)
	for _, p in ipairs(Players:GetPlayers()) do hook(p) end
end
