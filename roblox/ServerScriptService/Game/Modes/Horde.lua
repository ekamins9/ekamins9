--[[ HORDE — everyone together against waves of bots (after Mordhau's Horde).
     A short breather, then wave 1: a handful of Squires pour in through the
     map's gates (Map ▸ Spots ▸ HordeGate1..n; the map's B spawns if there are
     none). Each wave is bigger and better trained: Knights from wave 3,
     Champions from wave 6, and every fifth wave a Warlord (a Champion with a
     lot of health). The fallen come back between waves; when everyone is
     down at once, the horde has won and the round ends.

     Players can't hurt each other (pvp = false) and bots don't hurt each other
     (FriendlyFire off). Each wave cleared pays everyone here `wave`; each bot
     killed pays its killer `kill`; your best wave is kept (stats.hordeBest).

     Round attributes for the HUD (StarterPlayerScripts ▸ Objectives):
       ObjKind "Horde" · ObjLabel "WAVE n" · ObjState "wave" | "break" ·
       ObjProgress · ObjNote · ObjAttack (players up) · ObjDefend (bots up) ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local MapLoader = Game.MapLoader

local node = Game.node
local event   -- the ObjectiveEvent banner (Siege makes it; made here too if needed)
local ATTRS = {"ObjKind", "ObjStage", "ObjStages", "ObjLabel", "ObjProgress", "ObjState", "ObjPos", "ObjAttack", "ObjDefend", "ObjNote"}

local BREAK = 12          -- seconds between waves
local FIRST = 8           -- before the first
local MAX_ALIVE = 10      -- bots on the field at once (the rest wait their turn)
local WEAPONS = {"Longsword", "ArmingSword", "Mace", "Spear", "WarAxe", "Falchion", "Halberd", "MorningStar"}

local Horde = setmetatable({}, {__index = Game.Mode})
Horde.__index = Horde
function Horde.new(def, id) return setmetatable(Game.Mode.new(def, id), Horde) end

local function bots() return require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots")) end

-- who's coming in wave n, given how many players are here
local function roster(n, players)
	local count = 2 + n + math.floor((players - 1) * 1.5 + n * 0.4 * (players - 1))
	local list = {}
	for i = 1, count do
		local roll = math.random()
		local skill = "Squire"
		if n >= 6 then skill = roll < 0.35 and "Champion" or (roll < 0.8 and "Knight" or "Squire")
		elseif n >= 3 then skill = roll < 0.45 and "Knight" or "Squire" end
		table.insert(list, skill)
	end
	if n % 5 == 0 then table.insert(list, 1, "Warlord") end
	return list
end

local function alivePlayers()
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then n += 1 end
	end
	return n
end

local function gates()
	local out = {}
	local m = MapLoader.current
	local spots = m and m:FindFirstChild("Spots")
	for _, s in ipairs(spots and spots:GetChildren() or {}) do
		if s.Name:match("^HordeGate") then table.insert(out, s.CFrame) end
	end
	if #out == 0 then
		local sp = m and m:FindFirstChild("Spawns")
		for _, p in ipairs(sp and sp:GetChildren() or {}) do if p:GetAttribute("Team") == "B" then table.insert(out, p.CFrame) end end
	end
	if #out == 0 then table.insert(out, CFrame.new(0, 4, -40)) end
	return out
end

function Horde:start(map)
	Game.Mode.start(self, map)
	event = ReplicatedStorage:FindFirstChild("ObjectiveEvent")
	if not event then event = Instance.new("RemoteEvent"); event.Name = "ObjectiveEvent"; event.Parent = ReplicatedStorage end
	node:SetAttribute("FriendlyFire", false)   -- the horde doesn't cut itself down
	self.wave, self.phase, self.nextAt = 0, "break", os.clock() + FIRST
	self.queue, self.live, self.killed, self.total = {}, {}, 0, 0
	self.everUp = false
	node:SetAttribute("ObjKind", "Horde")
	node:SetAttribute("ObjStages", 0)
	node:SetAttribute("ObjStage", 0)
	self:publishScores()
end

function Horde:stop()
	for b in pairs(self.live or {}) do if b.model.Parent then b:destroy() end end
	self.live, self.queue = {}, {}
	for _, k in ipairs(ATTRS) do node:SetAttribute(k, nil) end
end

function Horde:canSpawn(plr)
	if self.phase == "wave" then return false, "The wave is on: you're back in when it's beaten" end
	return true
end

function Horde:startWave()
	self.wave += 1
	self.phase = "wave"
	self.queue = roster(self.wave, math.max(1, #Players:GetPlayers()))
	self.total, self.killed = #self.queue, 0
	event:FireAllClients("Stage", {text = "WAVE " .. self.wave, add = 0, team = "B", final = false, horde = true, count = self.total})
end

function Horde:spawnOne(skill, at)
	local Bots = bots()
	local warlord = skill == "Warlord"
	local bot = Bots.spawn({
		at = at * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)),
		skill = warlord and "Champion" or skill,
		weapon = warlord and "Zweihander" or WEAPONS[math.random(#WEAPONS)],
		weight = warlord and "Heavy" or nil,
		name = warlord and "The Warlord" or skill,
		team = "B", startDelay = 0.6, corpseTime = 4,
		onDeath = function(b, killer)
			self.live[b] = nil
			self.killed += 1
			if killer and _G.RoundBump then _G.RoundBump(killer, "kill") end
		end,
	})
	if warlord then
		local hp = 320 + 80 * #Players:GetPlayers()
		bot.hum.MaxHealth, bot.hum.Health = hp, hp
		bot.model:SetAttribute("Boss", true)
	end
	self.live[bot] = true
end

function Horde:tick(dt)
	local now = os.clock()
	local up = alivePlayers()
	if up > 0 then self.everUp = true end
	if self.phase == "break" then
		node:SetAttribute("ObjState", "break")
		node:SetAttribute("ObjLabel", self.wave == 0 and "GET READY" or ("WAVE " .. self.wave .. " BEATEN"))
		node:SetAttribute("ObjNote", string.format("NEXT WAVE IN %d", math.max(0, math.ceil(self.nextAt - now))))
		node:SetAttribute("ObjProgress", math.clamp(1 - (self.nextAt - now) / (self.wave == 0 and FIRST or BREAK), 0, 1))
		if now >= self.nextAt and up > 0 then self:startWave() end
	elseif self.phase == "wave" then
		-- feed the field from the queue, a few at a time, through the gates
		local alive = 0
		for _ in pairs(self.live) do alive += 1 end
		if #self.queue > 0 and alive < MAX_ALIVE and (self.lastSpawn or 0) + 0.6 < now then
			local g = gates()
			local skill = table.remove(self.queue, 1)
			self:spawnOne(skill, g[math.random(#g)])
			self.lastSpawn = now
			alive += 1
		end
		node:SetAttribute("ObjState", "wave")
		node:SetAttribute("ObjLabel", "WAVE " .. self.wave)
		node:SetAttribute("ObjNote", string.format("%d FOE%s LEFT", self.total - self.killed, self.total - self.killed == 1 and "" or "S"))
		node:SetAttribute("ObjProgress", self.total > 0 and self.killed / self.total or 0)
		node:SetAttribute("ObjDefend", alive)
		-- everyone down: the horde wins
		if self.everUp and up == 0 then self.phase = "over" return end
		-- the wave is beaten
		if #self.queue == 0 and alive == 0 then
			self.phase = "break"
			self.nextAt = now + BREAK
			for _, p in ipairs(Players:GetPlayers()) do
				if _G.RoundBump then _G.RoundBump(p, "wave") end
				local st = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile")).get(p).stats
				st.hordeBest = math.max(st.hordeBest or 0, self.wave)
				-- the break: your wind back at once, and a quarter of your health
				local c = p.Character
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					c:SetAttribute("BlockMeter", c:GetAttribute("BlockMax") or 100)
					hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * 0.25)
				end
			end
			event:FireAllClients("Stage", {text = "WAVE " .. self.wave .. " BEATEN", add = 0, team = "A", final = false, horde = true})
		end
	end
	node:SetAttribute("ObjAttack", up)
	node:SetAttribute("Objective", self:objective())
end

function Horde:isOver()
	if self.phase == "over" then
		return string.format("THE HORDE OVERRAN YOU  ·  YOU HELD %d WAVE%s", math.max(0, self.wave - 1), self.wave - 1 == 1 and "" or "S")
	end
	return nil
end
function Horde:result() return string.format("YOU HELD %d WAVES", math.max(0, self.wave - 1)) end
function Horde:objective()
	if self.phase == "wave" then return string.format("HORDE  ·  WAVE %d  ·  %d foes left", self.wave, (self.total or 0) - (self.killed or 0)) end
	return string.format("HORDE  ·  %s", self.wave == 0 and "the first wave is coming" or ("wave " .. self.wave .. " beaten: get back up and get ready"))
end

return Horde
