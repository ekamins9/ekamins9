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
-- 3) every weapon's numbers, for the menus: ReplicatedStorage ▸ WeaponStats ▸ <id>
--    (attributes). The Tools and their Configs stay on the server.
--      Reach · <Type>Damage / <Type>Windup (seconds) / <Type>Cost (stamina) /
--      <Type>Block (what blocking it costs) for Swing, Stab, Overhead ·
--      HeadMult · Move (walk speed while held) · ArmorPen · TwoHanded · Secondary
do
	local ok, DEF = pcall(function() return require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatServer")).DEFAULTS end)
	DEF = ok and DEF or {}
	local out = ReplicatedStorage:FindFirstChild("WeaponStats")
	if out then out:ClearAllChildren() else out = Instance.new("Folder"); out.Name = "WeaponStats" end
	local wf = ServerStorage:FindFirstChild("Weapons")
	for _, tool in ipairs(wf and wf:GetChildren() or {}) do
		local mod = tool:IsA("Tool") and tool:FindFirstChild("Config")
		local okc, cfg = false, nil
		if mod then okc, cfg = pcall(require, mod) end
		if okc and type(cfg) == "table" then
			local function get(k) if cfg[k] ~= nil then return cfg[k] end return DEF[k] end
			local A, ts = cfg.ATTACKS or {}, get("TYPE_SPEED") or {}
			local c = Instance.new("Configuration")
			c.Name = tool.Name
			c:SetAttribute("Reach", get("REACH") or 6)
			for _, kind in ipairs({"Swing", "Stab", "Overhead"}) do
				local info = A["Right" .. kind] or A["Left" .. kind] or A[kind]
				if info then
					local d = type(info.damage) == "table" and (info.damage.body or info.damage.torso or 0) or (info.damage or 0)
					local speed = (info.speed or 1) * (ts[kind] or 1) * (get("SPEED_MULT") or 1)
					c:SetAttribute(kind .. "Damage", d)
					c:SetAttribute(kind .. "Windup", (info.windup or get("WINDUP") or 0.15) / math.max(speed, 0.01))
					c:SetAttribute(kind .. "Cost", info.staminaCost or 0)
					-- what a held guard actually pays for it (a timed parry pays nothing)
					c:SetAttribute(kind .. "Block", math.floor((info.blockCost or 0) * (get("BLOCK_COST_MULT") or 1) + 0.5))
				end
			end
			c:SetAttribute("HeadMult", get("HEAD_DAMAGE_MULT") or 2)
			c:SetAttribute("Move", get("SpeedMult") or 1)
			c:SetAttribute("ArmorPen", get("ARMOR_PEN") or 0)
			c:SetAttribute("TwoHanded", get("TWO_HANDED") == true)
			c:SetAttribute("Secondary", get("SECONDARY") == true)
			if type(cfg.Description) == "string" then c:SetAttribute("Description", cfg.Description) end
			c.Parent = out
		end
	end
	out.Parent = ReplicatedStorage
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
	if skinId then
		-- the finish this player's copy has (Masterwork, Radiant)
		local best = Profile.bestCopy(Profile.get(plr), skinId)
		Dresser.applySkin(tool, skinId, best and best.v or nil)
	end
	tool.Parent = plr:WaitForChild("Backpack")
	if equip then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then task.defer(function() if tool.Parent and hum.Health > 0 then hum:EquipTool(tool) end end) end
	end
end

local spawnAs   -- (below)
local function show(plr, reason)
	if not plr.Parent then return end
	-- a newcomer (training, their first battle) doesn't pick a class yet: in they go
	if reason == nil and (Profile.get(plr).tutorial or 2) < 2 and Game.modeId ~= "Hub" then
		task.defer(function() spawnAs(plr, Profile.get(plr).active) end)
		return
	end
	event:FireClient(plr, "Show", Profile.get(plr).active, reason)
end

spawnAs = function(plr, classId)
	if spawning[plr] then return end
	if isAlive(plr) then return end
	if not GameConfig.CLASSES[classId] then classId = Profile.get(plr).active end
	local ok, why = Game.canSpawn(plr)
	if not ok then show(plr, why); return end
	-- reinforcements come in waves (a mode's waveSpawn): wait for your side's next one
	local wave = Game.waveWait(plr)
	if wave > 0.4 then
		spawning[plr] = true
		event:FireClient(plr, "Wave", wave)
		task.wait(wave)
		spawning[plr] = nil
		if not plr.Parent or isAlive(plr) then return end
		local ok2, why2 = Game.canSpawn(plr)
		if not ok2 then show(plr, why2); return end
	end
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
	-- names are drawn by NameTags (only when you look right at someone), not by Roblox
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	char:SetAttribute("Class", classId)
	char:SetAttribute("Title", p.appearance.title or "")
	local team = Game.teamOf(plr)
	Dresser.dress(char, {loadout = lo, appearance = p.appearance, weight = GameConfig.CLASSES[classId].weight, team = team})
	Game.Teams.mark(char, team)
	-- a class lighter (or heavier) than its weight: the Archer (GameConfig.CLASSES health / prot / speed)
	local cdef = GameConfig.CLASSES[classId]
	if cdef.health then
		local base = char:GetAttribute("BaseMaxHealth") or 100
		hum.MaxHealth = math.max(10, hum.MaxHealth + cdef.health)
		hum.Health = hum.MaxHealth
		char:SetAttribute("BaseMaxHealth", base)
	end
	if cdef.prot then char:SetAttribute("ArmorProtection", cdef.prot) end
	if cdef.speed then char:SetAttribute("SpeedMult_Class", cdef.speed) end
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
	-- a round with no respawns (The Lists, Last Team Standing) is lost by not being in it:
	-- everyone spawns as their active class at once, no SPAWN press needed
	local def = Game.current and Game.current.def
	local noRespawns = def and (def.respawnDelay == 0 or def.roundsToWin ~= nil)
	for _, plr in ipairs(Players:GetPlayers()) do
		if not isAlive(plr) then
			if noRespawns then task.spawn(spawnAs, plr, Profile.get(plr).active) else show(plr) end
		end
	end
end)

local function onPlayer(plr) if plr.Character then plr.Character:Destroy() end end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
Players.PlayerRemoving:Connect(function(plr) spawning[plr] = nil end)

log("ready —", #Catalog.PIECES, "pieces,", #Catalog.WEAPONS, "weapons,", #Catalog.SKINS, "skins,", #GameConfig.CLASS_ORDER, "classes")
