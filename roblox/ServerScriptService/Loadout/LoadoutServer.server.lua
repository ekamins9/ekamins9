--[[ LOADOUT SERVER — nobody spawns until they've picked an armor set and a
     weapon. Turns off CharacterAutoLoads, publishes a catalog of what's in
     ServerStorage.Armor and ServerStorage.Weapons, and spawns the player
     with that gear when the menu says so. On death the menu is re-shown
     (after the ragdoll has had its moment) with the last choice preselected.

       ReplicatedStorage.LoadoutRemote  (RemoteFunction, created here)
           client -> "Catalog"                -> {armors = {...}, weapons = {...}}
       ReplicatedStorage.LoadoutEvent   (RemoteEvent, created here)
           client -> "Spawn", armorId, weaponId
           server -> "Show", lastChoice       (re-open the menu)
           server -> "Spawned"                (menu closes)

     Weapons are Tools in ServerStorage.Weapons with the usual Config /
     Server / Client scripts inside. Nothing needs to be in StarterPack any
     more — the chosen weapon is cloned into the Backpack after spawn. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

local Armor      = require(script.Parent:WaitForChild("Armor"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local RESPAWN_MENU_DELAY = 4.0    -- seconds after death before the menu comes back
local AUTO_EQUIP         = true   -- draw the weapon as soon as they spawn

local function log(...) DebugFlags.log("Loadout", ...) end

Players.CharacterAutoLoads = false

local remote = Instance.new("RemoteFunction")
remote.Name = "LoadoutRemote"
remote.Parent = ReplicatedStorage
local event = Instance.new("RemoteEvent")
event.Name = "LoadoutEvent"
event.Parent = ReplicatedStorage

--------------------------------------------------------------------
--  WEAPON CATALOG
--------------------------------------------------------------------
local function weaponsFolder()
	local f = ServerStorage:FindFirstChild("Weapons")
	if not f then warn("[Loadout] ServerStorage.Weapons folder not found") end
	return f
end

local function weaponConfig(tool)
	local mod = tool:FindFirstChild("Config")
	if not (mod and mod:IsA("ModuleScript")) then return {} end
	local ok, t = pcall(require, mod)
	if ok and type(t) == "table" then return t end
	warn("[Loadout] bad Config in weapon", tool.Name, ok and "" or t)
	return {}
end

local function weaponSummary(tool)
	local cfg = weaponConfig(tool)
	local dmgMin, dmgMax
	local stab, slash = false, false
	if type(cfg.ATTACKS) == "table" then
		for _, a in pairs(cfg.ATTACKS) do
			if type(a) == "table" then
				if type(a.damage) == "number" then
					dmgMin = math.min(dmgMin or a.damage, a.damage)
					dmgMax = math.max(dmgMax or a.damage, a.damage)
				end
				if a.kind == "stab" then stab = true elseif a.kind == "slash" then slash = true end
			end
		end
	end
	return {
		id          = tool.Name,
		name        = cfg.Name or tool.Name,
		description = cfg.Description or "",
		damageMin   = dmgMin, damageMax = dmgMax,
		reach       = cfg.REACH,
		speedMult   = cfg.SPEED_MULT or 1,       -- attack tempo
		twoHanded   = cfg.TWO_HANDED == true,
		weightSpeed = cfg.SpeedMult or 1,        -- walkspeed while carried
		weightClunk = cfg.ClunkMult or 1,
		stab = stab, slash = slash,
	}
end

local function weaponList()
	local out = {}
	local f = weaponsFolder()
	if f then
		for _, t in ipairs(f:GetChildren()) do
			if t:IsA("Tool") then table.insert(out, weaponSummary(t)) end
		end
	end
	table.sort(out, function(a, b) return a.name < b.name end)
	return out
end

local function findWeapon(id)
	local f = weaponsFolder()
	local t = f and type(id) == "string" and f:FindFirstChild(id)
	return t and t:IsA("Tool") and t or nil
end

local function catalog()
	local armors = {}
	for _, cfg in ipairs(Armor.list()) do table.insert(armors, Armor.summary(cfg)) end
	return {armors = armors, weapons = weaponList()}
end

remote.OnServerInvoke = function(plr, what)
	if what == "Catalog" then return catalog() end
	return nil
end

--------------------------------------------------------------------
--  SPAWNING
--------------------------------------------------------------------
local lastChoice = {}   -- [player] = {armor = id, weapon = id}
local spawning   = {}   -- [player] = true while a spawn is in flight

local function isAlive(plr)
	local char = plr.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0 and char.Parent ~= nil
end

local function giveWeapon(plr, char, weaponId)
	local template = findWeapon(weaponId)
	if not template then return end
	local tool = template:Clone()
	tool.Parent = plr:WaitForChild("Backpack")
	if AUTO_EQUIP then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then task.defer(function() if tool.Parent and hum.Health > 0 then hum:EquipTool(tool) end end) end
	end
end

local function spawnWith(plr, armorId, weaponId)
	if spawning[plr] then return end
	if isAlive(plr) then log(plr.Name, "asked to spawn while alive — ignored"); return end
	local armorOk  = armorId == nil or Armor.config(armorId) ~= nil
	local weaponOk = weaponId == nil or findWeapon(weaponId) ~= nil
	if not (armorOk and weaponOk) then
		warn("[Loadout] " .. plr.Name .. " picked something that isn't in the folders:", tostring(armorId), tostring(weaponId))
		return
	end
	spawning[plr] = true
	lastChoice[plr] = {armor = armorId, weapon = weaponId}
	log(plr.Name, "spawning with", tostring(armorId), "+", tostring(weaponId))

	plr:LoadCharacter()
	local char = plr.Character or plr.CharacterAdded:Wait()
	local hum  = char:WaitForChild("Humanoid", 10)
	char:WaitForChild("Torso", 10)
	char:WaitForChild("HumanoidRootPart", 10)
	-- every limb has to exist before welding clothing onto it
	for _, limbName in pairs(Armor.SLOTS) do char:WaitForChild(limbName, 5) end
	if not (hum and char.Parent) then spawning[plr] = nil; return end

	if armorId then Armor.equip(char, armorId) end
	if weaponId then giveWeapon(plr, char, weaponId) end
	spawning[plr] = nil
	event:FireClient(plr, "Spawned")

	hum.Died:Once(function()
		task.delay(RESPAWN_MENU_DELAY, function()
			if plr.Parent and not isAlive(plr) then
				event:FireClient(plr, "Show", lastChoice[plr])
			end
		end)
	end)
end

event.OnServerEvent:Connect(function(plr, what, armorId, weaponId)
	if what == "Spawn" then
		spawnWith(plr, armorId, weaponId)
	elseif what == "Ready" then
		-- the menu script just started; if they have no body, show it
		if not isAlive(plr) then event:FireClient(plr, "Show", lastChoice[plr]) end
	end
end)

local function onPlayer(plr)
	-- CharacterAutoLoads was turned off above, but a character that got in
	-- before this script ran (Studio Play) would skip the menu
	if plr.Character then plr.Character:Destroy() end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
Players.PlayerRemoving:Connect(function(plr) lastChoice[plr] = nil; spawning[plr] = nil end)

log("ready —", #Armor.list(), "armor sets,", #weaponList(), "weapons")
