--[[ HORDE — everyone together against waves of bots (after Mordhau's Horde), DEFENDING
     SOMETHING: the camp's fire, the caravan, the villagers round the well (Game ▸
     HordeObjective; which one is the mode's `objectives` list, by map, or the map's own
     Spots ▸ HordeObjective). The horde comes for it. A bot fights a player who is in its
     face, or who stands by the objective; one who's off away from it (further than LEASH),
     or up on something it can't reach, it leaves be and goes to wreck the objective instead.
     So running round the map or sitting on a roof saves nobody: kill them before they
     wreck it. A blow from a Squire takes 12 of its health, a Knight 18, a Champion 26, the
     Warlord 60, an archer or a mage 10; it's mended by REPAIR of its whole between waves.
     When it falls, or everyone is down at once, the horde has won and the round ends.

     A short breather, then wave 1: a handful of Squires pour in through the
     map's gates (Map ▸ Spots ▸ HordeGate1..n; the map's B spawns if there are
     none). Each wave is bigger and better trained: Knights from wave 3,
     Champions from wave 6, and every fifth wave a Warlord (a Champion with a
     lot of health). The fallen come back between waves (and when the break
     runs out, whoever hasn't pressed SPAWN goes in as the class they're on:
     LoadoutServer ▸ _G.AutoSpawn); the standing are made whole, limbs and all
     (_G.MakeWhole).

     Players can't hurt each other (pvp = false) and bots don't hurt each other
     (FriendlyFire off). Each wave cleared pays everyone here `wave`; each bot
     killed pays its killer `kill`; your best wave is kept (stats.hordeBest).

     Round attributes for the HUD (StarterPlayerScripts ▸ Objectives):
       ObjKind "Horde" · ObjLabel "WAVE n" · ObjState "wave" | "break" ·
       ObjProgress · ObjNote · ObjAttack (players up) · ObjDefend (bots up) ·
       ObjPos (the objective) · ObjName ("THE CAMPFIRE") · ObjHealth 0..1 · ObjHit (under attack) ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local MapLoader = Game.MapLoader

local node = Game.node
local event   -- the ObjectiveEvent banner (Siege makes it; made here too if needed)
local ATTRS = {"ObjKind", "ObjStage", "ObjStages", "ObjLabel", "ObjProgress", "ObjState", "ObjPos", "ObjAttack", "ObjDefend", "ObjNote", "ObjName", "ObjHealth", "ObjHit"}
local HordeObjective = require(script.Parent.Parent:WaitForChild("HordeObjective"))

local BREAK = 12          -- seconds between waves
local FIRST = 8           -- before the first
local MAX_ALIVE = 10      -- bots on the field at once (the rest wait their turn)
local LEASH = 55          -- a player further than this from the objective is left be (unless in a bot's face)
local FACE = 12           -- …this close to a bot, it fights them wherever they are
local CHASE = 40          -- how far a bot goes after someone by the objective (an archer or a mage: 70)
local UP = 7              -- up on something more than this above a bot: it can't reach them, so it doesn't try
local SACK = {Squire = 12, Knight = 18, Champion = 26, Warlord = 60}   -- a blow on the objective, by rank
local SACK_CASTER = 10    -- an archer's or a mage's
local REPAIR = 0.3        -- of its whole, mended between waves
-- THE HORDE'S ARCHERS AND MAGES. Each player is shot at by at most FIRE_LIMIT of them at a
-- time (two from wave FIRE_TWO); the rest keep their distance and wait their turn. Mages hit
-- for SPELL_POWER of a player's spell, take CAST_SLOW as long over it (their rune circle and
-- your screen's warning give you time to dodge or break it), come in with MAGE_MANA, and no
-- more than 1 + one per two more players are up at once (the rest come as archers). A bot's
-- lightning never breaks your swing or guard (Combat ▸ MagicServer).
local FIRE_LIMIT, FIRE_TWO = 1, 10
local SPELL_POWER = 0.65
local CAST_SLOW = 1.5     -- a Horde mage takes this much longer over each spell (time to see it coming)
local MAGE_MANA = 60      -- …and comes in with this much mana, so it has to stop and meditate sooner
local LOST = {Campfire = "THE CAMPFIRE WENT OUT", Caravan = "THE CARAVAN BURNED", Villagers = "THE VILLAGERS FELL",
	Hoard = "THE HOARD WAS PLUNDERED", Flame = "THE HOLY FLAME WENT OUT", Camp = "THE CAMP BURNED"}
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

local function flat(v) return Vector3.new(v.X, 0, v.Z).Magnitude end

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
	-- what you're defending: by map (the mode's `objectives`), built on open ground in the middle
	local mapModel = MapLoader.current
	local kinds = self.def.objectives or {}
	if self.obj then self.obj:destroy() end
	local mapName = map or node:GetAttribute("Map") or ""   -- (the loaded model is always called "Map")
	local ok, obj = pcall(HordeObjective.build, self.def.objective or kinds[mapName] or "Campfire", mapModel, self.def.objectiveHealth or 1500, self.def.objective ~= nil)
	if ok then self.obj = obj else warn("[Horde] objective:", obj); self.obj = nil end
	self.ring, self.lost, self.alertAt, self.warned = 0, nil, -1e9, {}
	if self.obj then
		node:SetAttribute("ObjPos", self.obj.pos)
		node:SetAttribute("ObjName", self.obj.name)
		node:SetAttribute("ObjHealth", 1)
	end
	self:publishScores()
end

-- (hooks a kind of horde can change: Game ▸ Modes ▸ Invasion)
function Horde:removeLive(b) if b.model and b.model.Parent then b:destroy() end end
function Horde:aliveCount()
	local n = 0
	for _ in pairs(self.live) do n += 1 end
	return n
end
function Horde:roster(n, players) return roster(n, players) end

function Horde:stop()
	for b in pairs(self.live or {}) do self:removeLive(b) end
	self.live, self.queue = {}, {}
	if self.obj then self.obj:destroy(); self.obj = nil end
	for _, k in ipairs(ATTRS) do node:SetAttribute(k, nil) end
end

-- THE OBJECTIVE, through a bot's eyes -------------------------------------------------
-- where it heads with nobody to fight: its own place round the objective (or right here,
-- once it's close enough to strike)
function Horde:goalFor(b)
	local o = self.obj
	if not o or o.hp <= 0 then return nil end
	local me = b.hrp.Position
	if flat(me - o.pos) <= o.radius + 3.2 then return me end
	local a = b.ringAngle or 0
	return o.pos + Vector3.new(math.cos(a), 0, math.sin(a)) * (o.radius + 2.2)
end
-- may it fight this player? In its face: yes. Out of reach above it, or off away from the
-- objective: no (it goes for the objective). Otherwise: someone near the objective it can get to.
function Horde:engage(b, foe)
	local o = self.obj
	if not o or o.hp <= 0 then return true end
	local fr = foe:FindFirstChild("HumanoidRootPart")
	if not fr then return false end
	local me = b.hrp.Position
	local caster = b.model:GetAttribute("Class") ~= nil
	if not caster and math.abs(fr.Position.Y - me.Y) > UP then return false end
	local d = flat(fr.Position - me)
	if d < FACE then return true end
	if flat(fr.Position - o.pos) > LEASH then return false end
	return d < (caster and 70 or CHASE)
end
-- a blow lands on it
function Horde:sacked(b, rank, caster)
	local o = self.obj
	if not o or o.hp <= 0 or self.phase ~= "wave" then return end
	o:hit(caster and SACK_CASTER or (SACK[rank] or 12), b.hrp.Position)
	local h = o:health()
	if o.hp <= 0 then
		self.lost = "objective"
		self.phase = "over"
		event:FireAllClients("Stage", {text = LOST[o.kind] or (o.name .. " FELL"), team = "B", horde = true, sub = "THE HORDE HAS WON", final = true})
		return
	end
	-- the alarm: when it's first hit (again, after a quiet spell), and at half and a quarter
	local now = os.clock()
	local word = (h <= 0.25 and not self.warned[25]) and 25 or ((h <= 0.5 and not self.warned[50]) and 50 or nil)
	if word then
		self.warned[word] = true
		self.alertAt = now
		event:FireAllClients("Stage", {text = string.format("%s: %d%% LEFT", o.name, math.floor(h * 100 + 0.5)), team = "B", horde = true, sub = "SAVE IT! GET BACK THERE!"})
	elseif now - self.alertAt > 20 then
		self.alertAt = now
		event:FireAllClients("Stage", {text = o.name .. " IS UNDER ATTACK!", team = "B", horde = true, sub = "GET BACK AND DEFEND IT!"})
	end
end

function Horde:canSpawn(plr)
	if self.phase == "wave" then return false, "The wave is on: you're back in when it's beaten (you go in by yourself)" end
	return true
end

function Horde:startWave()
	self.wave += 1
	self.phase = "wave"
	self.queue = self:roster(self.wave, math.max(1, #Players:GetPlayers()))
	self.total, self.killed = #self.queue, 0
	event:FireAllClients("Stage", {text = "WAVE " .. self.wave, add = 0, team = "B", final = false, horde = true, count = self.total})
end

function Horde:spawnOne(skill, at)
	local Bots = bots()
	local warlord = skill == "Warlord"
	-- archers in the horde from wave 3, mages from wave 5 (Combat ▸ Bots: opts.class)
	local r = math.random()
	local cls = not warlord and ((self.wave >= 3 and r < 0.16) and "Archer" or ((self.wave >= 5 and r < 0.26) and "Mage" or nil)) or nil
	if cls == "Mage" then
		local mages = 0
		for b in pairs(self.live) do if b.alive and b.model:GetAttribute("Class") == "Mage" then mages += 1 end end
		if mages >= 1 + math.floor((#Players:GetPlayers() - 1) / 2) then cls = "Archer" end
	end
	-- (a power: every Warlord, half the Champions; never the archers or mages: they're enough)
	local power = warlord and (math.random() < 0.5 and "AvatarOfWar" or "ThunderSlam")
		or ((skill == "Champion" and not cls) and (Bots.pickPower("Champion", nil, 0.5)) or nil)
	local bot = Bots.spawn({
		power = power,
		at = at * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)),
		skill = warlord and "Champion" or skill,
		class = cls,
		weapon = warlord and "Zweihander" or ((not cls) and WEAPONS[math.random(#WEAPONS)] or nil),
		weight = warlord and "Heavy" or nil,
		name = warlord and "The Warlord" or (cls and (skill .. " " .. cls)) or skill,
		team = "B", startDelay = 0.6, corpseTime = 4,
		-- the objective (Horde:goalFor / engage / sacked)
		goal = function(b) return self:goalFor(b) end,
		engage = function(b, foe) return self:engage(b, foe) end,
		sack = function(b) self:sacked(b, warlord and "Warlord" or skill, cls ~= nil) end,
		face = function() return self.obj and self.obj.pos end,
		fireLimit = function() return self.wave >= FIRE_TWO and 2 or FIRE_LIMIT end,
		onDeath = function(b, killer)
			self.live[b] = nil
			self.killed += 1
			if killer and _G.RoundBump then _G.RoundBump(killer, "kill_" .. (warlord and "Champion" or skill or "Squire")) end
		end,
	})
	if cls == "Mage" then
		bot.model:SetAttribute("SpellPower", SPELL_POWER)
		bot.model:SetAttribute("CastSlow", CAST_SLOW)
		bot.model:SetAttribute("Mana", math.min(bot.model:GetAttribute("Mana") or MAGE_MANA, MAGE_MANA))
	end
	-- its own place round the objective (spread by the golden angle)
	self.ring = (self.ring or 0) + 1
	bot.ringAngle = self.ring * 2.39996 + math.random() * 0.3
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
		if now >= self.nextAt then
			-- nobody is shut out of the wave for not pressing SPAWN: whoever's still on the
			-- class screen goes in as the class they picked (LoadoutServer: _G.AutoSpawn)
			local any = false
			for _, p in ipairs(Players:GetPlayers()) do
				any = true
				if _G.AutoSpawn then _G.AutoSpawn(p) end
			end
			if any then self:startWave() end
		end
	elseif self.phase == "wave" then
		-- feed the field from the queue, a few at a time, through the gates
		local alive = self:aliveCount()
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
		if self.phase == "over" then return end   -- (the objective fell this tick)
		-- the wave is beaten
		if #self.queue == 0 and alive == 0 then
			self.phase = "break"
			self.nextAt = now + BREAK
			-- the objective mended a little, the alarms reset
			if self.obj then self.obj:repair(REPAIR) end
			self.warned, self.alertAt = {}, -1e9
			for _, p in ipairs(Players:GetPlayers()) do
				if _G.RoundBump then _G.RoundBump(p, "wave") end
				local st = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile")).get(p).stats
				st.hordeBest = math.max(st.hordeBest or 0, self.wave)
				-- the break: whole again, where you stand: full health, your wind and mana, and
				-- lost limbs, bleeding and a knocked-away weapon put right (LoadoutServer: _G.MakeWhole)
				if _G.MakeWhole then _G.MakeWhole(p) end
			end
			event:FireAllClients("Stage", {text = "WAVE " .. self.wave .. " BEATEN", add = 0, team = "A", final = false, horde = true})
		end
	end
	node:SetAttribute("ObjAttack", up)
	if self.obj then
		node:SetAttribute("ObjHealth", self.obj:health())
		node:SetAttribute("ObjHit", os.clock() - self.obj.lastHitAt < 1.6)
	end
	node:SetAttribute("Objective", self:objective())
end

function Horde:isOver()
	if self.phase == "over" then
		local o = self.obj
		local head = (self.lost == "objective" and o) and (LOST[o.kind] or (o.name .. " FELL")) or "THE HORDE OVERRAN YOU"
		return string.format("%s  ·  YOU HELD %d WAVE%s", head, math.max(0, self.wave - 1), self.wave - 1 == 1 and "" or "S")
	end
	return nil
end
function Horde:result() return string.format("YOU HELD %d WAVES", math.max(0, self.wave - 1)) end
function Horde:objective()
	local o = self.obj
	local guard = o and string.format("  ·  defend %s (%d%%)", string.lower(o.name), math.floor(o:health() * 100 + 0.5)) or ""
	if self.phase == "wave" then return string.format("HORDE  ·  WAVE %d%s  ·  %d foes left", self.wave, guard, (self.total or 0) - (self.killed or 0)) end
	return string.format("HORDE  ·  %s%s", self.wave == 0 and "the first wave is coming" or ("wave " .. self.wave .. " beaten: get back up and get ready"), guard)
end

return Horde
