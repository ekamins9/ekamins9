--[[ PLAGUE NIGHT — the living against the plague, till dawn (GameConfig.MODES.Plague).

     It's night. Everyone starts among THE LIVING (team A). A few seconds in, the plague stirs:
     patient zero (one in six of the players, never everyone) turns, and the first ghouls
     (Combat ▸ Monsters, PlagueGhoul) shamble out of the dark. Anyone of the living who falls
     RISES AS A GHOUL (team B) — with a ghoul's body (green, clawed, a sickly glow), a cleaver,
     more health, a quicker step, and the mending of the dead out of a fight — and hunts the rest.
     More ghouls come out of the dark as the night deepens. When the living are few, bots stand
     with them, and a bot that falls rises as a ghoul too.

     DAWN (the clock running out) with anyone still living: the living win. Nobody left: the
     plague takes the town. A ghoul sees the living's outline through walls when they're near
     (Adventure.client). Pay as any battle: a kill, the round, the win for your side. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Lighting = game:GetService("Lighting")

local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Loot = require(script.Parent.Parent:WaitForChild("Loot"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Monsters = require(Combat:WaitForChild("Monsters"))
local Bots = require(Combat:WaitForChild("Bots"))
local MapLoader = Game.MapLoader
local Teams = Game.Teams
local node = Game.node

local GHOUL_HEALTH = 60   -- on top of their class
local FIRST_TURN = 14     -- seconds before patient zero

local Plague = setmetatable({}, {__index = Game.Mode})
Plague.__index = Plague
function Plague.new(def, id) return setmetatable(Game.Mode.new(def, id), Plague) end

local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function banner(t, plr) local e = event(); if e then if plr then e:FireClient(plr, "Banner", t) else e:FireAllClients("Banner", t) end end end
local function humOf(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(c) local h = humOf(c); return h ~= nil and h.Health > 0 end

function Plague:living()
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do if Teams.keyOf(p) == "A" and alive(p.Character) then n += 1 end end
	for b in pairs(self.allies) do if b.alive then n += 1 end end
	return n
end
function Plague:plague()
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do if Teams.keyOf(p) == "B" then n += 1 end end
	for m in pairs(self.mobs) do if m.alive then n += 1 end end
	return n
end

-- a turned player: the ghoul's kit (LoadoutServer asks before dressing them)
function Plague:adjustLoadout(plr, lo, classId)
	-- (one who joins late: the living before the plague stirs, the plague after)
	if not Teams.keyOf(plr) then Teams.set(plr, self.stirred and "B" or "A") end
	if Teams.keyOf(plr) ~= "B" then return end
	lo.weapon, lo.weaponSkin = "Cleaver", nil
	lo.secondary, lo.secondarySkin = nil, nil
	lo.shield, lo.shieldSkin = nil, nil
	lo.power = "Bloodlust"; lo.thirdKind = "power"; lo.thirdId = "Bloodlust"
	lo.throwable = nil
	lo.noHelm = true
end
function Plague:noteSpawn(plr)
	local char = plr.Character
	if not char then return end
	if Teams.keyOf(plr) == "B" then
		task.defer(function()
			Monsters.decorate(char, "PlagueGhoul")
			local h = humOf(char)
			if h then h.MaxHealth += GHOUL_HEALTH; h.Health = h.MaxHealth end
			char:SetAttribute("SpeedMult_Plague", 1.1)
			char:SetAttribute("Ghoul", true)
			Loot.setRelics(char, {"TrollHeart"})   -- (the dead mend out of a fight)
		end)
		plr:SetAttribute("AdvChip", "🧟 THE PLAGUE")
	else
		plr:SetAttribute("AdvChip", "🛡 THE LIVING")
	end
end

-- where you come in: the living anywhere far from the plague, the plague at its side's spawns
function Plague:spawnCFrame(plr)
	local key = Teams.keyOf(plr)
	local others = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local r = p ~= plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r and Teams.keyOf(p) ~= key then table.insert(others, r.Position) end
	end
	return MapLoader.pickSpawn(key == "B" and "B" or nil, others)
end

function Plague:canSpawn(plr)
	-- (the living don't come back: they come back as the plague)
	return true
end

function Plague:turn(plr, quiet)
	if Teams.keyOf(plr) == "B" then return end
	Teams.set(plr, "B")
	self.turned[plr] = true
	if not quiet then
		banner({text = string.upper(plr.DisplayName) .. " HAS TURNED", sub = "THE PLAGUE SPREADS", kind = "boss"})
		banner({text = "YOU HAVE TURNED", sub = "HUNT THE LIVING", kind = "boss"}, plr)
	end
end

-- a ghoul out of the dark (or where one of the living fell)
function Plague:spawnGhoul(at)
	local spots = MapLoader.spawns("B")
	local cf = at or spots[math.random(#spots)]
	local m = Monsters.spawn("PlagueGhoul", self.mobOpts, {at = cf * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)), hpMult = 1 + #Players:GetPlayers() * 0.05})
	if m then self.mobs[m] = true end
	return m
end

function Plague:start(map)
	Game.Mode.start(self, map)   -- (teams: then everyone onto the living)
	for _, p in ipairs(Players:GetPlayers()) do Teams.set(p, "A") end
	node:SetAttribute("FriendlyFire", false)
	self.turned, self.mobs, self.allies = {}, {}, {}
	self.firstAt = os.clock() + FIRST_TURN
	self.nextGhoul = self.firstAt
	self.everLiving = false
	self.mobOpts = {team = "B", startDelay = 0.4, corpseTime = 4, fightBots = true,
		onDeath = function(m) self.mobs[m] = nil end}
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("ObjKind", "Plague")
	-- it's night
	self.lightBefore = {ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd, FogColor = Lighting.FogColor}
	Lighting.ClockTime = 0.4
	Lighting.Brightness = 0.5
	Lighting.Ambient = Color3.fromRGB(50, 58, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(64, 72, 96)
	Lighting.FogColor = Color3.fromRGB(20, 26, 34)
	Lighting.FogEnd = 220
	for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("AdvChip", "🛡 THE LIVING") end
	task.delay(2, function() banner({text = "PLAGUE NIGHT", sub = "SURVIVE UNTIL DAWN", kind = "floor"}) end)
end

function Plague:stop()
	if self.mobOpts then Monsters.halt(self.mobOpts) end
	for m in pairs(self.mobs or {}) do Monsters.despawn(m) end
	for b in pairs(self.allies or {}) do if b.model and b.model.Parent then pcall(function() b:destroy() end) end end
	self.mobs, self.allies = {}, {}
	if self.lightBefore then for k, v in pairs(self.lightBefore) do pcall(function() Lighting[k] = v end) end; self.lightBefore = nil end
	for _, k in ipairs({"OwnHud", "ObjKind", "ObjLabel", "ObjNote"}) do node:SetAttribute(k, nil) end
	for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("AdvChip", nil) end
end

-- the living fall: they turn
function Plague:onDeath(victimPlr)
	if Teams.keyOf(victimPlr) == "A" and self.firstAt and os.clock() >= self.firstAt then self:turn(victimPlr) end
	-- the plague gets back up by itself (a turned one, a fallen ghoul)
	if Teams.keyOf(victimPlr) == "B" then
		task.delay(self.def.respawnDelay or 3, function()
			if Game.current == self and victimPlr.Parent and _G.AutoSpawn then _G.AutoSpawn(victimPlr) end
		end)
	end
end

function Plague:tick(dt)
	local now = os.clock()
	local players = Players:GetPlayers()
	-- patient zero
	if self.firstAt and now >= self.firstAt and not self.stirred then
		self.stirred = true
		local pool = {}
		for _, p in ipairs(players) do if alive(p.Character) then table.insert(pool, p) end end
		local n = #pool >= 4 and math.max(1, math.floor(#pool / 6)) or 0
		for _ = 1, n do
			local p = table.remove(pool, math.random(#pool))
			self:turn(p, true)
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if _G.Respawn then _G.Respawn(p, p.Character and p.Character:GetAttribute("Class") or "Knight", r and r.CFrame or nil, {}) end
			banner({text = "YOU ARE PATIENT ZERO", sub = "HUNT THE LIVING", kind = "boss"}, p)
		end
		for _ = 1, 2 + math.floor(#players / 2) do self:spawnGhoul() end
		banner({text = "THE PLAGUE STIRS", sub = n > 0 and "SOMEONE AMONG YOU HAS TURNED" or "THE DEAD ARE COMING OUT OF THE DARK", kind = "boss"})
	end
	-- the living when they're few: bots stand with them; a bot that falls rises a ghoul
	if not self.alliesMade then
		self.alliesMade = true
		local want = math.max(0, 4 - #players)
		local spots = MapLoader.spawns(nil)
		for i = 1, want do
			local at = spots[((i - 1) % #spots) + 1]
			local b = Bots.spawn({at = at * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)), team = "A", skill = "Knight", fightBots = true,
				name = "Villager", corpseTime = 3,
				onDeath = function(bot)
					self.allies[bot] = nil
					local r = bot.hrp
					if r and self.stirred then
						local cf = CFrame.new(r.Position)
						task.delay(2.5, function() if self.mobs then self:spawnGhoul(cf) end end)
						banner({text = "A VILLAGER HAS TURNED", kind = "elite"})
					end
				end})
			if b then self.allies[b] = true end
		end
	end
	-- more out of the dark as the night deepens
	if self.stirred and now >= self.nextGhoul then
		local minutes = (now - self.firstAt) / 60
		local want = 2 + math.floor(minutes * 1.5) + math.floor(#players / 3)
		local have = 0
		for m in pairs(self.mobs) do if m.alive then have += 1 end end
		if have < want then self:spawnGhoul() end
		self.nextGhoul = now + 4
	end
	local living, plague = self:living(), self:plague()
	if living > 0 then self.everLiving = true end
	local left = node:GetAttribute("TimeLeft") or 0
	node:SetAttribute("ObjLabel", string.format("PLAGUE NIGHT  ·  DAWN IN %d:%02d", math.floor(left / 60), left % 60))
	node:SetAttribute("ObjNote", string.format("THE LIVING %d  ·  THE PLAGUE %d", living, plague))
	node:SetAttribute("ObjLiving", living)
	node:SetAttribute("Objective", self:objective())
end

function Plague:isOver()
	if self.stirred and self.everLiving and self:living() == 0 then
		self:teamResult("B")
		return "THE PLAGUE TAKES THE TOWN"
	end
	return nil
end
function Plague:result()
	if self:living() > 0 then
		self:teamResult("A")
		return string.format("DAWN BREAKS  ·  %d OF THE LIVING HELD OUT", self:living())
	end
	self:teamResult("B")
	return "THE PLAGUE TAKES THE TOWN"
end
function Plague:objective() return "PLAGUE NIGHT  ·  SURVIVE UNTIL DAWN" end

return Plague
