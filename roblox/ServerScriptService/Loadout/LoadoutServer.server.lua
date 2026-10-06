--[[ LOADOUT SERVER — nobody spawns until they've picked a CLASS. A class
     (GameConfig.CLASSES) is a weight; the player's saved loadout for it
     (Profile: pieces, colors, weapon, skins) says what they look like.
     Spawns go through the current GameMode (may they spawn, where, which
     team) and the Dresser puts the pieces, colors, body and skins on.

       ReplicatedStorage.LoadoutRemote  (RemoteFunction)
           client -> "Catalog"   -> {classes = {[id] = {def, loadout, summary}}, order, active}
       ReplicatedStorage.LoadoutEvent   (RemoteEvent)
           client -> "Spawn", classId   |  "Ready"
           server -> "Show", activeClass, waitReason|nil   |  "Spawned"

     At startup the server mirrors ServerStorage ▸ Armor into
     ReplicatedStorage ▸ Cosmetics ▸ Armor so the client can preview sets, and
     makes the Cosmetics folders if they are missing. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris            = game:GetService("Debris")

-- 1) anything without a hand-made model is built from Build ▸ Blueprints
--    (weapon bodies, armor set models, hair / beards / faces, weapon displays)
do
	local build = ServerScriptService:FindFirstChild("Build")
	local bp = build and build:FindFirstChild("Blueprints")
	if bp then
		local ok, err = pcall(function() require(bp).ensureAll() end)
		if not ok then warn("[Loadout] Blueprints failed:", err) end
	end
end
-- 2) Cosmetics folders, so Catalog finds them on the client too
local cos = ReplicatedStorage:FindFirstChild("Cosmetics")
if not cos then cos = Instance.new("Folder"); cos.Name = "Cosmetics"; cos.Parent = ReplicatedStorage end
for _, n in ipairs({"Armor", "Pieces", "Skins", "Weapons", "Body"}) do
	if not cos:FindFirstChild(n) then local f = Instance.new("Folder"); f.Name = n; f.Parent = cos end
end
for _, n in ipairs({"Hair", "Beard", "Face"}) do if not cos.Body:FindFirstChild(n) then local f = Instance.new("Folder"); f.Name = n; f.Parent = cos.Body end end
local legacy = ServerStorage:FindFirstChild("Armor")
if legacy then
	for _, set in ipairs(legacy:GetChildren()) do
		if not cos.Armor:FindFirstChild(set.Name) then set:Clone().Parent = cos.Armor end
	end
end

local Catalog    = require(ReplicatedStorage:WaitForChild("Catalog"))
Catalog.rebuild()
local Dresser    = require(ReplicatedStorage:WaitForChild("Dresser"))
local Profile    = require(script.Parent:WaitForChild("Profile"))
local Game       = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Game"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local AUTO_EQUIP    = true
local SPAWN_PROTECT = 3.0

local function log(...) DebugFlags.log("Loadout", ...) end

Players.CharacterAutoLoads = false

local remote = Instance.new("RemoteFunction"); remote.Name = "LoadoutRemote"; remote.Parent = ReplicatedStorage
local event  = Instance.new("RemoteEvent");    event.Name  = "LoadoutEvent";  event.Parent  = ReplicatedStorage

local function weaponsFolder() return ServerStorage:FindFirstChild("Weapons") end
local function findWeapon(id)
	local f = weaponsFolder()
	local t = f and type(id) == "string" and f:FindFirstChild(id)
	return t and t:IsA("Tool") and t or nil
end

local function summaryOf(lo)
	local function nm(id) local p = Catalog.PIECE[id]; return p and p.name or "—" end
	local w = Catalog.WEAPON[lo.weapon]; local s = Catalog.WEAPON[lo.secondary]
	local sk = Catalog.SKIN[lo.weaponSkin]
	return {helmet = nm(lo.helmet), top = nm(lo.top), bottom = nm(lo.bottom),
		weapon = w and w.name or "—", weaponSkin = sk and sk.name ~= "Default" and sk.name or nil, secondary = s and s.name or nil}
end

local function classes(plr)
	local out = {}
	for _, id in ipairs(GameConfig.CLASS_ORDER) do
		local def = GameConfig.CLASSES[id]
		local lo = Profile.validateLoadout(plr, id, Profile.get(plr).classes[id])
		out[id] = {id = id, name = def.name, description = def.description, weight = def.weight, loadout = lo, summary = summaryOf(lo)}
	end
	return out
end

remote.OnServerInvoke = function(plr, what)
	if what == "Catalog" then
		return {classes = classes(plr), order = GameConfig.CLASS_ORDER, active = Profile.get(plr).active, appearance = Profile.get(plr).appearance}
	end
	return nil
end

--------------------------------------------------------------------
--  SPAWNING
--------------------------------------------------------------------
local spawning = {}
local function isAlive(plr)
	local char = plr.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0 and char.Parent ~= nil
end

local function giveWeapon(plr, char, weaponId, skinId, equip)
	local template = findWeapon(weaponId)
	if not template then warn("[Loadout] no Tool named", weaponId, "in ServerStorage.Weapons"); return end
	local tool = template:Clone()
	if skinId then Dresser.applySkin(tool, skinId) end
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
	if isAlive(plr) then return end
	if not GameConfig.CLASSES[classId] then classId = Profile.get(plr).active end
	local ok, why = Game.canSpawn(plr)
	if not ok then show(plr, why); return end
	local p = Profile.get(plr)
	local lo = Profile.validateLoadout(plr, classId, p.classes[classId])
	Profile.setActive(plr, classId)
	spawning[plr] = true
	log(plr.Name, "spawning as", classId, "-", lo.helmet, lo.top, lo.bottom, "+", tostring(lo.weapon), "/", tostring(lo.secondary))

	if Game.current and Game.current.def.teams == 2 and not Game.teamOf(plr) then Game.Teams.assign(plr) end

	plr:LoadCharacter()
	local char = plr.Character or plr.CharacterAdded:Wait()
	local hum  = char:WaitForChild("Humanoid", 10)
	char:WaitForChild("Torso", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	for _, limbName in ipairs({"Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do char:WaitForChild(limbName, 5) end
	if not (hum and hrp and char.Parent) then spawning[plr] = nil; return end

	local cf = Game.spawnCFrame(plr)
	if cf then char:PivotTo(CFrame.new(cf.Position + Vector3.new(0, 3, 0)) * (cf - cf.Position)) end
	char:SetAttribute("Class", classId)
	char:SetAttribute("Title", p.appearance.title or "")
	local team = Game.teamOf(plr)
	Dresser.dress(char, {loadout = lo, appearance = p.appearance, weight = GameConfig.CLASSES[classId].weight, team = team})
	Game.Teams.mark(char, team)
	if lo.secondary then giveWeapon(plr, char, lo.secondary, lo.secondarySkin, false) end
	if lo.weapon then giveWeapon(plr, char, lo.weapon, lo.weaponSkin, AUTO_EQUIP) end
	if SPAWN_PROTECT > 0 and Game.modeId ~= "Hub" and Game.modeId ~= "Tiltyard" then
		local ff = Instance.new("ForceField"); ff.Visible = true; ff.Parent = char
		Debris:AddItem(ff, SPAWN_PROTECT)
	end
	Game.noteSpawn(plr)
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
	if what == "Spawn" then spawnAs(plr, a)
	elseif what == "Ready" then if not isAlive(plr) then show(plr) end end
end)

Game.intermissionStarted.Event:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then plr.Character:Destroy() end
		spawning[plr] = nil
		show(plr, Game.node:GetAttribute("MatchOver") and "Match over" or "Waiting for the next round")
	end
end)
Game.roundStarted.Event:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do if not isAlive(plr) then show(plr) end end
end)

local function onPlayer(plr) if plr.Character then plr.Character:Destroy() end end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
Players.PlayerRemoving:Connect(function(plr) spawning[plr] = nil end)

log("ready —", #Catalog.PIECES, "pieces,", #Catalog.WEAPONS, "weapons,", #Catalog.SKINS, "skins,", #GameConfig.CLASS_ORDER, "classes")
