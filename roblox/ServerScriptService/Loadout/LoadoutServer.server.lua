--[[ LOADOUT SERVER — nobody spawns until they've picked a CLASS. A class
     (GameConfig.CLASSES) fixes the armor type and the weapons allowed; the
     player's saved loadout for that class (Profile) says exactly which set
     and weapons. Spawns go through the current GameMode: may they spawn, and
     where (team spawn points). On death the class screen comes back after
     the mode's respawnDelay; an intermission pulls everyone out.

       ReplicatedStorage.LoadoutRemote  (RemoteFunction)
           client -> "Catalog"   -> {armors, weapons, classes = {[id] = {def, loadout, summary}}}
       ReplicatedStorage.LoadoutEvent   (RemoteEvent)
           client -> "Spawn", classId
           server -> "Show", activeClass, waitReason|nil    (re-open the class screen)
           server -> "Spawned"

     Weapons are Tools in ServerStorage.Weapons, armor sets in
     ServerStorage.Armor (each with a Config). Building loadouts happens in
     the Hub menu's Armory (HubServer saves them). ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris            = game:GetService("Debris")

local Armor      = require(script.Parent:WaitForChild("Armor"))
local Profile    = require(script.Parent:WaitForChild("Profile"))
local Pickup     = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Pickup"))
local Game       = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Game"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local AUTO_EQUIP    = true   -- draw the primary as soon as they spawn
local SPAWN_PROTECT = 3.0    -- seconds of spawn protection (a ForceField; ends early if you attack)

local function log(...) DebugFlags.log("Loadout", ...) end

Players.CharacterAutoLoads = false

local remote = Instance.new("RemoteFunction")
remote.Name = "LoadoutRemote"
remote.Parent = ReplicatedStorage
local event = Instance.new("RemoteEvent")
event.Name = "LoadoutEvent"
event.Parent = ReplicatedStorage

--------------------------------------------------------------------
--  CATALOG (also used by HubServer's Armory)
--------------------------------------------------------------------
local Catalog = {}
_G.LoadoutCatalog = Catalog   -- HubServer reads the same lists

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
				local d = a.damage
				if type(d) == "table" then d = d.body or d.torso or d.head end
				if type(d) == "number" then
					dmgMin = math.min(dmgMin or d, d)
					dmgMax = math.max(dmgMax or d, d)
				end
				if a.kind == "stab" then stab = true elseif a.kind == "slash" then slash = true end
			end
		end
	end
	local classes = {}
	for _, id in ipairs(GameConfig.CLASS_ORDER) do
		if GameConfig.classAllowsWeapon(id, tool.Name) then table.insert(classes, id) end
	end
	return {
		id = tool.Name, name = cfg.Name or tool.Name, description = cfg.Description or "",
		damageMin = dmgMin, damageMax = dmgMax, reach = cfg.REACH, speedMult = cfg.SPEED_MULT or 1,
		twoHanded = cfg.TWO_HANDED == true, weightSpeed = cfg.SpeedMult or 1, weightClunk = cfg.ClunkMult or 1,
		stab = stab, slash = slash, secondary = cfg.SECONDARY == true, classes = classes,
	}
end

function Catalog.weapons()
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

function Catalog.findWeapon(id)
	local f = weaponsFolder()
	local t = f and type(id) == "string" and f:FindFirstChild(id)
	return t and t:IsA("Tool") and t or nil
end

function Catalog.armors()
	local out = {}
	for _, cfg in ipairs(Armor.list()) do table.insert(out, Armor.summary(cfg)) end
	return out
end

-- does this loadout fit the class? returns a corrected loadout (or nil) and why
function Catalog.validate(classId, loadout)
	local cls = GameConfig.CLASSES[classId]
	if not cls then return nil, "no such class" end
	loadout = type(loadout) == "table" and loadout or {}
	local out = {}
	-- armor: must exist and be the class's type; else the first set of that type
	local acfg = type(loadout.armor) == "string" and Armor.config(loadout.armor)
	if acfg and acfg.Type == cls.armorType then out.armor = acfg.Id end
	if not out.armor then
		for _, c in ipairs(Armor.list()) do if c.Type == cls.armorType then out.armor = c.Id; break end end
	end
	-- primary: must exist and be allowed; else the first allowed weapon
	local w = Catalog.findWeapon(loadout.weapon)
	if w and GameConfig.classAllowsWeapon(classId, w.Name) then out.weapon = w.Name end
	if not out.weapon then
		for _, s in ipairs(Catalog.weapons()) do
			if GameConfig.classAllowsWeapon(classId, s.id) then out.weapon = s.id; break end
		end
	end
	-- secondary: optional; must be a SECONDARY weapon, allowed, and not the primary
	local s = Catalog.findWeapon(loadout.secondary)
	if s and s.Name ~= out.weapon and Pickup.isSecondary(s) and GameConfig.classAllowsWeapon(classId, s.Name) then
		out.secondary = s.Name
	end
	return out
end

-- the player's loadout for a class, made valid
function Catalog.loadoutFor(plr, classId)
	local p = Profile.get(plr)
	return Catalog.validate(classId, p.classes[classId])
end

local function summaryOf(loadout)
	local a = loadout.armor and Armor.config(loadout.armor)
	local w = loadout.weapon and Catalog.findWeapon(loadout.weapon)
	local s = loadout.secondary and Catalog.findWeapon(loadout.secondary)
	return {
		armor = a and a.Name or "—", weapon = w and (weaponConfig(w).Name or w.Name) or "—",
		secondary = s and (weaponConfig(s).Name or s.Name) or nil,
	}
end

function Catalog.classes(plr)
	local out = {}
	for _, id in ipairs(GameConfig.CLASS_ORDER) do
		local def = GameConfig.CLASSES[id]
		local lo = Catalog.loadoutFor(plr, id)
		out[id] = {id = id, name = def.name, description = def.description, armorType = def.armorType,
			loadout = lo, summary = summaryOf(lo)}
	end
	return out
end

remote.OnServerInvoke = function(plr, what)
	if what == "Catalog" then
		return {armors = Catalog.armors(), weapons = Catalog.weapons(), classes = Catalog.classes(plr),
			order = GameConfig.CLASS_ORDER, active = Profile.get(plr).active}
	end
	return nil
end

--------------------------------------------------------------------
--  SPAWNING
--------------------------------------------------------------------
local spawning = {}   -- [player] = true while a spawn is in flight

local function isAlive(plr)
	local char = plr.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0 and char.Parent ~= nil
end

local function giveWeapon(plr, char, weaponId, equip)
	local template = Catalog.findWeapon(weaponId)
	if not template then return end
	local tool = template:Clone()
	tool.Parent = plr:WaitForChild("Backpack")
	if equip then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then task.defer(function() if tool.Parent and hum.Health > 0 then hum:EquipTool(tool) end end) end
	end
end

local function show(plr, reason)
	if plr.Parent then event:FireClient(plr, "Show", Profile.get(plr).active, reason) end
end

local function spawnAs(plr, classId)
	if spawning[plr] then return end
	if isAlive(plr) then log(plr.Name, "asked to spawn while alive — ignored"); return end
	if not GameConfig.CLASSES[classId] then classId = Profile.get(plr).active end
	local ok, why = Game.canSpawn(plr)
	if not ok then show(plr, why); return end
	local lo = Catalog.loadoutFor(plr, classId)
	Profile.setActive(plr, classId)
	spawning[plr] = true
	log(plr.Name, "spawning as", classId, "-", tostring(lo.armor), "+", tostring(lo.weapon), "/", tostring(lo.secondary))

	-- team before the body, so the spawn point and the tabard are right
	if Game.current and Game.current.def.teams == 2 and not Game.teamOf(plr) then Game.Teams.assign(plr) end

	plr:LoadCharacter()
	local char = plr.Character or plr.CharacterAdded:Wait()
	local hum  = char:WaitForChild("Humanoid", 10)
	char:WaitForChild("Torso", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	for _, limbName in pairs(Armor.SLOTS) do char:WaitForChild(limbName, 5) end
	if not (hum and hrp and char.Parent) then spawning[plr] = nil; return end

	local cf = Game.spawnCFrame(plr)
	if cf then char:PivotTo(CFrame.new(cf.Position + Vector3.new(0, 3, 0)) * (cf - cf.Position)) end
	char:SetAttribute("Class", classId)
	Game.Teams.mark(char, Game.teamOf(plr))
	if lo.armor then Armor.equip(char, lo.armor) end
	if lo.secondary then giveWeapon(plr, char, lo.secondary, false) end
	if lo.weapon then giveWeapon(plr, char, lo.weapon, AUTO_EQUIP) end
	if SPAWN_PROTECT > 0 and Game.modeId ~= "Hub" then
		local ff = Instance.new("ForceField")
		ff.Visible = true
		ff.Parent = char
		Debris:AddItem(ff, SPAWN_PROTECT)
	end
	if Game.current and Game.current.noteSpawn then Game.current:noteSpawn(plr) end
	spawning[plr] = nil
	event:FireClient(plr, "Spawned")

	hum.Died:Once(function()
		task.delay(Game.respawnDelay(), function()
			if plr.Parent and not isAlive(plr) then
				local ok2, why2 = Game.canSpawn(plr)
				show(plr, (not ok2) and why2 or nil)
			end
		end)
	end)
end

event.OnServerEvent:Connect(function(plr, what, a)
	if what == "Spawn" then
		spawnAs(plr, a)
	elseif what == "Ready" then
		if not isAlive(plr) then show(plr) end
	end
end)

-- round transitions
Game.intermissionStarted.Event:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then plr.Character:Destroy() end
		spawning[plr] = nil
		show(plr, "Waiting for the next round")
	end
end)
Game.roundStarted.Event:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if not isAlive(plr) then show(plr) end
	end
end)

local function onPlayer(plr)
	-- CharacterAutoLoads was turned off above, but a character that got in
	-- before this script ran (Studio Play) would skip the menu
	if plr.Character then plr.Character:Destroy() end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
Players.PlayerRemoving:Connect(function(plr) spawning[plr] = nil end)

log("ready —", #Armor.list(), "armor sets,", #Catalog.weapons(), "weapons,", #GameConfig.CLASS_ORDER, "classes")
