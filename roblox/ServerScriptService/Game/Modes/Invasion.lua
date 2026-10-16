--[[ INVASIONS — the Horde (Game ▸ Modes ▸ Horde), but an ARMY comes, each with its own way of
     making your life hard (GameConfig.MODES.InvGoblin / InvElf / InvUndead / InvOrc: impl =
     "Invasion", army = the key below, objective = what you defend):

       GOBLIN RAID       they want your gold (THE HOARD). Goblin Thieves don't fight: they run
                         in, grab a sack of it and run for their gate. Kill a carrier and the gold
                         comes back; let one through and it's gone. Bombers lob fire-pots.
       THE ELVEN HOST    arrows from everywhere: archers and rangers by the dozen (more of them
                         shoot at once than any other horde), blademasters to run them down,
                         spellweavers, wardens. They come for THE LOGGING CAMP.
       UNDEAD NIGHT      it's night. Skeletons that stand back up, ghouls that mend, necromancers
                         raising more, wraiths, death knights. Keep THE HOLY FLAME alight.
       THE ORC WARBAND   big, hard-hitting, and its WAR-DRUMMERS make every orc faster and
                         harder while they live (you hear them, you see the beat): kill them
                         first. They come for THE VILLAGERS.

     Every fifth wave its lord comes (the Goblin King, the Elf Queen, the Lich King or the Bone
     Colossus, the Warchief) with its own big moves (Combat ▸ BossMoves) and a boss bar. Waves
     grow and harden as in the Horde; the break between makes you whole and mends what you
     defend. Pay as the Horde: `wave` for everyone, a kill by its rank. Your best wave per army:
     stats.invasionBest_<army>.

     SPOILS OF WAR: every third wave beaten, a gilded chest stands by what you defend, one for
     each of you (open it in the break): a RELIC rolled for your class (better the deeper you are:
     Game ▸ Loot), yours for the rest of the run (it comes back with you when you fall), and a
     healing draught drunk on the spot. Runs grow stronger as they go. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Lighting = game:GetService("Lighting")

local Horde = require(script.Parent:WaitForChild("Horde"))
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Monsters = require(Combat:WaitForChild("Monsters"))
local Powers = require(Combat:WaitForChild("Powers"))
local MapLoader = Game.MapLoader
local node = Game.node

local function adventure() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function flat(v) return Vector3.new(v.X, 0, v.Z).Magnitude end

-- THE ARMIES: who's in each, by role
local ARMIES = {
	Goblin = {name = "THE GOBLIN RAID", common = {"Goblin", "Goblin", "GoblinSpearman", "GoblinBrute"}, ranged = {"GoblinArcher", "GoblinBomber", "GoblinShaman"},
		elite = {"GoblinWarboss", "Ogre"}, special = "GoblinThief", lords = {"GoblinKing"}, rangedShare = 0.25},
	Elf = {name = "THE ELVEN HOST", common = {"ElfBlademaster"}, ranged = {"ElfArcher", "ElfArcher", "ElfRanger", "ElfSpellweaver"},
		elite = {"ElfWarden"}, lords = {"ElfQueen"}, rangedShare = 0.6, fire = 3},
	Undead = {name = "UNDEAD NIGHT", common = {"Skeleton", "Skeleton", "Ghoul", "SkeletonKnight"}, ranged = {"SkeletonArcher", "Necromancer"},
		elite = {"DeathKnight", "Wraith"}, lords = {"LichKing", "BoneColossus"}, rangedShare = 0.25, night = true},
	Orc = {name = "THE ORC WARBAND", common = {"OrcGrunt", "OrcGrunt", "OrcBerserker"}, ranged = {"OrcArcher"},
		elite = {"OrcBerserker", "Ogre"}, special = "OrcDrummer", lords = {"OrcWarchief"}, rangedShare = 0.2},
}
local STEAL = 120          -- what a thief carries off
local SPOILS_EVERY = 3     -- waves between the spoils of war
local Loot = require(script.Parent.Parent:WaitForChild("Loot"))
local DRUM_EVERY = 1.25    -- the war drums' beat

local Invasion = setmetatable({}, {__index = Horde})
Invasion.__index = Invasion
function Invasion.new(def, id)
	local self = setmetatable(Horde.new(def, id), Invasion)
	self.army = ARMIES[def.army or "Goblin"] or ARMIES.Goblin
	return self
end

-- WHO'S COMING in wave n: an army's own mix
function Invasion:roster(n, players)
	local a = self.army
	local count = 3 + n + math.floor((players - 1) * 1.5 + n * 0.4 * (players - 1))
	local list = {}
	for _ = 1, count do
		local r = math.random()
		local eliteChance = n >= 4 and math.min(0.25, 0.06 + n * 0.012) or 0
		local id
		if r < eliteChance then id = a.elite[math.random(#a.elite)]
		elseif r < eliteChance + a.rangedShare then id = a.ranged[math.random(#a.ranged)]
		else id = a.common[math.random(#a.common)] end
		table.insert(list, {id = id, elite = n >= 6 and math.random() < 0.08})
	end
	-- the special ones: thieves every wave, drummers from the second
	if a.special == "GoblinThief" then for _ = 1, 2 + math.floor(n / 2) do table.insert(list, math.random(1, #list + 1), {id = "GoblinThief"}) end end
	if a.special == "OrcDrummer" and n >= 2 then for _ = 1, 1 + math.floor(n / 4) do table.insert(list, 2, {id = "OrcDrummer"}) end end
	if n % 5 == 0 then table.insert(list, 1, {id = a.lords[((n / 5 - 1) % #a.lords) + 1], lord = true}) end
	return list
end

function Invasion:aliveCount()
	local n = 0
	for m in pairs(self.live) do if m.alive then n += 1 else self.live[m] = nil end end
	return n + (self.mobOpts and Monsters.pending(self.mobOpts) or 0)
end
function Invasion:removeLive(m) Monsters.despawn(m) end

-- a thief's errand: in to the hoard, out with a sack, back to its gate
local function sackOf(model, on)
	local look = model:FindFirstChild("MonsterLook")
	local old = look and look:FindFirstChild("GoldSack")
	if old then old:Destroy() end
	if not (on and look) then return end
	local torso = model:FindFirstChild("Torso")
	if not torso then return end
	local p = Instance.new("Part")
	p.Name = "GoldSack"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(1.6, 1.6, 1.6)
	p.Color = Color3.fromRGB(240, 196, 70)
	p.Material = Enum.Material.Neon
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
	p.CFrame = torso.CFrame * CFrame.new(0, 0.6, 1.1)
	local w = Instance.new("Weld"); w.Part0 = torso; w.Part1 = p; w.C0 = CFrame.new(0, 0.6, 1.1); w.Parent = p
	local l = Instance.new("PointLight"); l.Color = p.Color; l.Range = 10; l.Brightness = 1.5; l.Parent = p
	p.Parent = look
end

function Invasion:spawnOne(entry, at)
	if type(entry) ~= "table" then entry = {id = entry} end
	local id = entry.id
	local def = Monsters.def(id)
	if not def then return end
	local players = math.max(1, #Players:GetPlayers())
	local thief = id == "GoblinThief"
	local gate = at.Position
	local mob
	local over = {at = at * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)), elite = entry.elite}
	if entry.lord then over.hpMult = (1 + (players - 1) * 0.55) * (1 + self.wave * 0.04) end
	if thief then
		local o2 = table.clone(self.mobOpts)
		o2.goal = function(b)
			local o = self.obj
			if not o or o.hp <= 0 then return gate end
			if b.carrying then return gate end
			local me = b.hrp.Position
			if flat(me - o.pos) <= o.radius + 2.5 then return me end
			return o.pos
		end
		-- (a thief runs from a fight unless it's cornered)
		o2.engage = function(b, foe)
			local fr = foe:FindFirstChild("HumanoidRootPart")
			return fr ~= nil and flat(fr.Position - b.hrp.Position) < 4.5
		end
		o2.sack = function(b)
			local o = self.obj
			if b.carrying or not o or o.hp <= 0 or self.phase ~= "wave" then return end
			local take = math.min(STEAL, o.hp)
			o:hit(take, b.hrp.Position)
			b.carrying = take
			sackOf(b.model, true)
			b.model:SetAttribute("TagName", "Goblin Thief  ·  GOLD!")
			self:alert(string.format("A THIEF HAS YOUR GOLD!  ·  %d%% LEFT", math.floor(o:health() * 100 + 0.5)), "CUT IT DOWN BEFORE IT REACHES THE GATE")
		end
		o2.onDeath = function(m, killer)
			self.live[m] = nil
			self.killed += 1
			local b = m.bot
			if b and b.carrying and not b.escaped and self.obj and self.obj.hp > 0 then
				self.obj:repair(b.carrying / self.obj.max)
				local ev = adventure()
				if ev then ev:FireAllClients("Banner", {text = "GOLD RECOVERED", sub = killer and (string.upper(killer.DisplayName) .. " CUT DOWN A THIEF") or nil, kind = "clear"}) end
			end
			if killer and _G.RoundBump then _G.RoundBump(killer, "kill_Squire") end
		end
		mob = Monsters.spawn(id, o2, over)
		if mob then mob.thiefGate = gate; mob.bot.thiefGate = gate end
	else
		mob = Monsters.spawn(id, self.mobOpts, over)
	end
	if not mob then return end
	self.live[mob] = true
	self.ring = (self.ring or 0) + 1
	mob.bot.ringAngle = self.ring * 2.39996 + math.random() * 0.3
	if def.class == "Mage" then mob.model:SetAttribute("Mana", math.min(mob.model:GetAttribute("Mana") or 60, 60)) end
	if entry.lord then
		local ev = adventure()
		if ev then ev:FireAllClients("Banner", {text = string.upper(def.name), sub = "THE LORD OF " .. self.army.name .. " COMES", kind = "boss"}) end
	end
	if id == "OrcDrummer" and not self.drumsWarned then
		self.drumsWarned = true
		local ev = adventure()
		if ev then ev:FireAllClients("Banner", {text = "WAR DRUMS!", sub = "KILL THE DRUMMERS: THEY DRIVE THE WARBAND ON", kind = "elite"}) end
	end
end

-- SPOILS OF WAR: a gilded chest by the objective, one for each of you: a relic for the run
function Invasion:spoils()
	if self.spoilsChest and self.spoilsChest.model then self.spoilsChest.model:Destroy() end
	local o = self.obj
	local centre = o and o.pos or (MapLoader.spawns(nil)[1] and MapLoader.spawns(nil)[1].Position) or Vector3.zero
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = {MapLoader.current, workspace.Terrain}
	local spot
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2 + math.random() * 0.3
		local probe = centre + Vector3.new(math.cos(a) * ((o and o.radius or 6) + 6), 0, math.sin(a) * ((o and o.radius or 6) + 6))
		local hit = workspace:Raycast(probe + Vector3.new(0, 30, 0), Vector3.new(0, -70, 0), rp)
		if hit and hit.Normal.Y > 0.8 then spot = hit.Position; break end
	end
	spot = spot or centre
	local wave = self.wave
	local rarity = wave >= 12 and "Legendary" or (wave >= 9 and "Epic" or (wave >= 6 and "Rare" or "Uncommon"))
	self.spoilsChest = Loot.chest(CFrame.lookAt(spot, Vector3.new(centre.X, spot.Y, centre.Z)), {rarity = rarity, gilded = true, label = "Spoils of war", perPlayer = true, hold = 0.8,
		onOpen = function(plr) return self:takeSpoils(plr, wave) end})
	local ev = adventure()
	if ev then ev:FireAllClients("Banner", {text = "SPOILS OF WAR", sub = "A CHEST FOR EACH OF YOU BY " .. (o and o.name or "THE CAMP") .. "  ·  A RELIC FOR THE RUN", kind = "victory"}) end
end

-- your share of the spoils: a relic for the run (rolled for your class, better the deeper), a draught
function Invasion:takeSpoils(plr, wave)
	local char = plr.Character
	local h = char and char:FindFirstChildOfClass("Humanoid")
	if not (h and h.Health > 0) then return false end
	local mine = self.relics[plr] or {}
	local have = {}
	for _, id in ipairs(mine) do have[id] = true end
	local item = Loot.relic(0.6 + wave * 0.22 + Loot.luckOf(char), have, nil, char:GetAttribute("Class"))
	if item then
		table.insert(mine, item.relic)
		self.relics[plr] = mine
		Loot.setRelics(char, mine)
	end
	pcall(Loot.drink, char, "Healing")
	local ev = adventure()
	if ev then ev:FireClient(plr, "Banner", {text = item and string.upper(item.name) or "SPOILS OF WAR", sub = item and ((Loot.card(item) or {}).sub or "A RELIC FOR THE RUN") or "NOTHING LEFT TO TAKE", kind = "clear"}) end
	return true
end

-- back in after a fall: your relics come with you
function Invasion:noteSpawn(plr)
	local mine = self.relics and self.relics[plr]
	if mine and #mine > 0 then
		task.defer(function()
			local char = plr.Character
			if char and char.Parent then Loot.setRelics(char, mine) end
		end)
	end
end

-- a shout (the Horde's banner)
function Invasion:alert(text, sub)
	local now = os.clock()
	if now - (self.lastAlert or 0) < 4 then return end
	self.lastAlert = now
	local ev = ReplicatedStorage:FindFirstChild("ObjectiveEvent")
	if ev then ev:FireAllClients("Stage", {text = text, team = "B", horde = true, sub = sub}) end
end

function Invasion:start(map)
	-- every monster of this round shares one set of options (the objective's goal / engage / blow)
	self.mobOpts = {team = "B", startDelay = 0.6, corpseTime = 4,
		goal = function(b) return self:goalFor(b) end,
		engage = function(b, foe) return self:engage(b, foe) end,
		sack = function(b) self:sacked(b, ({"Squire", "Knight", "Champion", "Warlord"})[b.model:GetAttribute("Tier") or 1] or "Knight", b.model:GetAttribute("Class") ~= nil) end,
		face = function() return self.obj and self.obj.pos end,
		fireLimit = function() return (self.army.fire or 1) + (self.wave >= 10 and 1 or 0) end,
		onSpawn = function(m) self.live[m] = true; self.total += 1 end,
		onDeath = function(m, killer)
			self.live[m] = nil
			self.killed += 1
			local tier = m.def.tier or 1
			if killer and _G.RoundBump then _G.RoundBump(killer, "kill_" .. (tier >= 3 and "Champion" or (tier == 2 and "Knight" or "Squire"))) end
		end}
	Horde.start(self, map)
	self.relics, self.spoilsFor, self.spoilsChest = {}, 0, nil
	node:SetAttribute("ObjName", self.obj and self.obj.name or "")
	-- Undead Night: it's night
	if self.army.night then
		self.lightBefore = {ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness}
		Lighting.ClockTime = 0.2
		Lighting.Brightness = 0.6
		Lighting.Ambient = Color3.fromRGB(60, 66, 90)
		Lighting.OutdoorAmbient = Color3.fromRGB(70, 76, 104)
	end
	task.delay(2, function()
		local ev = adventure()
		if ev then ev:FireAllClients("Banner", {text = self.army.name, sub = "DEFEND " .. (self.obj and self.obj.name or "THE CAMP"), kind = "floor"}) end
	end)
end

function Invasion:stop()
	if self.mobOpts then Monsters.halt(self.mobOpts) end
	pcall(Loot.clear)
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then pcall(Loot.setRelics, p.Character, {}) end end
	self.relics, self.spoilsChest = {}, nil
	Horde.stop(self)
	if self.lightBefore then
		for k, v in pairs(self.lightBefore) do pcall(function() Lighting[k] = v end) end
		self.lightBefore = nil
	end
end

function Invasion:tick(dt)
	Horde.tick(self, dt)
	local now = os.clock()
	-- thieves home free
	for m in pairs(self.live) do
		local b = m.bot
		if m.alive and b and b.carrying and b.thiefGate and b.hrp and flat(b.hrp.Position - b.thiefGate) < 6 then
			b.escaped = true
			Monsters.despawn(m)
			self.live[m] = nil
			self.killed += 1
			self:alert("A THIEF GOT AWAY WITH YOUR GOLD", "THAT GOLD IS GONE")
		end
	end
	-- the war drums: every orc faster and harder while a drummer lives
	if self.army.special == "OrcDrummer" and now - (self.lastDrum or 0) > DRUM_EVERY then
		self.lastDrum = now
		local drummers = {}
		for m in pairs(self.live) do if m.alive and m.id == "OrcDrummer" and m.model.PrimaryPart then table.insert(drummers, m) end end
		if #drummers > 0 then
			for m in pairs(self.live) do
				if m.alive and m.id ~= "OrcDrummer" then Powers.addMods(m.model, {speed = 1.15, dealt = 1.15}, DRUM_EVERY + 0.6, "WarDrums") end
			end
			for _, d in ipairs(drummers) do
				local r = d.model:FindFirstChild("HumanoidRootPart")
				if r then
					Monsters.ring(r.Position - Vector3.new(0, 3 * (d.model:GetAttribute("MonsterScale") or 1), 0), 12, Color3.fromRGB(255, 120, 40), 0.5)
					Monsters.burst(r.Position + Vector3.new(0, 1, 0), Color3.fromRGB(255, 150, 60), 8, 4)
				end
			end
		end
	end
	-- the spoils of war, every third wave
	if self.phase == "break" and self.wave > 0 and self.wave % SPOILS_EVERY == 0 and (self.spoilsFor or 0) < self.wave then
		self.spoilsFor = self.wave
		local ok, err = pcall(self.spoils, self)
		if not ok then warn("[Invasion] spoils:", err) end
	end
	-- keep a best wave per army
	if self.phase == "break" and self.wave > (self.bestNoted or 0) then
		self.bestNoted = self.wave
		local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
		for _, p in ipairs(Players:GetPlayers()) do
			local st = Profile.get(p).stats
			local k = "invasionBest_" .. (self.def.army or "Goblin")
			st[k] = math.max(st[k] or 0, self.wave)
		end
	end
end

function Invasion:objective()
	local base = Horde.objective(self)
	return (base:gsub("^HORDE", self.army.name))
end

return Invasion
