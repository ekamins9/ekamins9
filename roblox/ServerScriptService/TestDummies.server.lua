--[[ TEST DUMMIES — chat commands that spawn an R6 dummy holding WEAPON_NAME
     a few studs in front of you, facing you, running one behaviour:

        /spawn idle     stands there with the weapon out
        /spawn block    holds guard forever
        /spawn parry    raises guard the instant you start a swing (timed parry)
        /spawn attack   cycles attacks at you every ATTACK_INTERVAL
        /spawn clear    removes all dummies

     The dummy is a stripped clone of YOUR character (same R6 rig, no
     scripts, no tools, no attributes), so it needs no asset downloads.
     Dummies live in workspace.NPCs, so CharacterSystems gives them ragdoll,
     bleeding and death like players. Their weapon runs the normal combat
     module in NPC mode (server-side animations + server-side blade sweep),
     so an attack dummy can actually hit you and a parry dummy can actually
     parry you. The server doesn't render RigPose, so dummies see your
     un-leaned body (the HipHeight crouch IS physical, so ducking works).

     Every step logs under [TestDummies] while Debug.Logs is on. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPack   = game:GetService("StarterPack")
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local CombatServer = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatServer"))
local DebugFlags   = require(ReplicatedStorage:WaitForChild("DebugFlags"))

--------------------------------------------------------------------
local WEAPON_NAME     = "Greatsword"   -- default; /spawn <mode> <Weapon> [Armor] overrides. Looked up in ServerStorage.Weapons, ServerStorage, StarterPack
local SPAWN_DIST      = 8
local ATTACK_INTERVAL = 1.6
local PARRY_RANGE     = 20             -- parry dummy reacts to swings started within this range
local PARRY_REACTION  = 0.25           -- seconds before it raises guard (a human's reaction time)
local CORPSE_TIME     = 10
--------------------------------------------------------------------

local function log(...) DebugFlags.log("TestDummies", ...) end

local folder = workspace:FindFirstChild("NPCs")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "NPCs"
	folder.Parent = workspace
end

local dummies = {}

-- optional: Loadout.Armor, so dummies can wear a set (and inherit yours)
local Armor do
	local loadout = script.Parent:FindFirstChild("Loadout")
	local mod = loadout and loadout:FindFirstChild("Armor")
	if mod then Armor = require(mod) end
end

local function findWeapon(name)
	name = name or WEAPON_NAME
	local weapons = ServerStorage:FindFirstChild("Weapons")
	local t = (weapons and weapons:FindFirstChild(name))
		or ServerStorage:FindFirstChild(name)
		or StarterPack:FindFirstChild(name)
	return t and t:IsA("Tool") and t or nil
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

-- a clean R6 rig from the caller's own character
local function makeDummy(sourceChar, name)
	local wasArchivable = sourceChar.Archivable
	sourceChar.Archivable = true
	local model = sourceChar:Clone()
	sourceChar.Archivable = wasArchivable
	model.Name = name
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BaseScript") or d:IsA("Tool") or d:IsA("ForceField")
			or d.Name == "RagdollJoints" or d.Name == "SkewerWeld" or d.Name:find("^Stump_")
			or d.Name == "RagdollA0" or d.Name == "RagdollA1"
			or (d:IsA("Motor6D") and (not d.Part1 or not d.Part0)) then
			d:Destroy()
		elseif d:IsA("Motor6D") then
			d.Enabled = true            -- source may have been mid-ragdoll
		elseif d:IsA("BasePart") then
			d.CollisionGroup = "Default"
		end
	end
	local armorId = model:GetAttribute("ArmorId")
	local baseHp  = model:GetAttribute("BaseMaxHealth")   -- MaxHealth without the armor bonus
	for k in pairs(model:GetAttributes()) do model:SetAttribute(k, nil) end
	local oldArmor = model:FindFirstChild("Armor")
	if oldArmor then oldArmor:Destroy() end   -- re-equipped fresh below so welds are clean
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			p.Transparency = p.Name == "HumanoidRootPart" and 1 or 0
			p.CanQuery = true   -- a source head hidden by a skewer must not carry over
		end
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayName = name
	if baseHp then hum.MaxHealth = baseHp end
	hum.Health = hum.MaxHealth
	hum.WalkSpeed, hum.JumpPower = 0, 0
	hum.PlatformStand = false
	return model, hum, armorId
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
	log("cleared")
end

local function spawnDummy(player, mode, weaponName, armorName)
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then log("no character for", player.Name); return end
	local weapon = findWeapon(weaponName)
	if not weapon then
		warn("[TestDummies] no Tool named '" .. tostring(weaponName or WEAPON_NAME) .. "' in ServerStorage.Weapons / ServerStorage / StarterPack")
		return
	end
	log("spawning", mode, "dummy for", player.Name, "with", weapon.Name, armorName or "(your armor)")

	local model, hum, armorId = makeDummy(char, "Dummy_" .. mode)
	local pos = hrp.Position + hrp.CFrame.LookVector * SPAWN_DIST
	model:PivotTo(CFrame.lookAt(pos, Vector3.new(hrp.Position.X, pos.Y, hrp.Position.Z)))
	model.Parent = folder
	-- dress it: the named set, else whatever the caller is wearing
	if Armor then
		local wanted = armorName or armorId
		if wanted and wanted ~= "none" then Armor.equip(model, wanted) end
	end
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
	if ctrl then
		log("controller ready for", model.Name)
	else
		warn("[TestDummies] weapon never attached a combat controller — is its Server script (and ServerScriptService.Combat.CombatServer) in place?")
	end

	local entry = {model = model, tool = tool, ctrl = ctrl, mode = mode, conns = {}, blocking = false}
	table.insert(dummies, entry)

	-- always face the nearest player (yaw only) unless ragdolled
	table.insert(entry.conns, RunService.Heartbeat:Connect(function()
		if hum.PlatformStand or hum.Health <= 0 or model:GetAttribute("Ragdolled") then return end
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
			task.delay(0.3, function()
				if model.Parent then log("block dummy raising guard"); ctrl.blockStart() end
			end)

		elseif mode == "parry" then
			-- SpeedMult_Swing appears on a character the moment its windup starts
			table.insert(entry.conns, RunService.Heartbeat:Connect(function()
				if hum.Health <= 0 then return end
				local target = nearestPlayer(dhrp.Position, PARRY_RANGE)
				local swinging = target ~= nil and target:GetAttribute("SpeedMult_Swing") ~= nil
				if swinging and not entry.blocking then
					entry.blocking = true
					task.delay(PARRY_REACTION, function()
						if model.Parent and entry.blocking then
							log("parry dummy: guard up")
							ctrl.blockStart()
						end
					end)
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
					log("attack dummy swings")
					ctrl.cycle()
					task.wait(ATTACK_INTERVAL)
				end
			end)
		end
	end

	hum.Died:Once(function()
		log(model.Name, "died")
		task.delay(CORPSE_TIME, function() remove(entry) end)
	end)
end

local MODES = {idle = true, block = true, parry = true, attack = true}
local lastCommand = {}   -- [player] = os.clock(), to dedupe the two chat hooks

local function handle(player, text)
	local cmd, rest = text:match("^/(%a+)%s*(.*)$")
	if not cmd or cmd:lower() ~= "spawn" then return end
	if os.clock() - (lastCommand[player] or -1e9) < 0.3 then return end
	lastCommand[player] = os.clock()
	log("command from", player.Name .. ":", text)
	-- /spawn <mode> [WeaponName] [ArmorId|none]
	local words = {}
	for w in (rest or ""):gmatch("%S+") do table.insert(words, w) end
	local arg = (words[1] or ""):lower()
	if arg == "clear" then clearAll(); return end
	if arg == "" then arg = "idle" end
	if not MODES[arg] then
		warn("[TestDummies] unknown mode '" .. arg .. "' — use idle | block | parry | attack | clear")
		return
	end
	spawnDummy(player, arg, words[2], words[3])
end

-- both chat systems: TextChatService command AND legacy Chatted (deduped above)
local ok, cmdObj = pcall(function()
	local c = Instance.new("TextChatCommand")
	c.Name = "SpawnDummy"
	c.PrimaryAlias = "/spawn"
	c.Parent = TextChatService
	return c
end)
if ok and cmdObj then
	cmdObj.Triggered:Connect(function(source, text)
		local plr = Players:GetPlayerByUserId(source.UserId)
		if plr then handle(plr, text) end
	end)
end
local function hook(plr) plr.Chatted:Connect(function(msg) handle(plr, msg) end) end
Players.PlayerAdded:Connect(hook)
for _, p in ipairs(Players:GetPlayers()) do hook(p) end

log("ready — /spawn attack|parry|block|idle [Weapon] [ArmorId|none], /spawn clear")
