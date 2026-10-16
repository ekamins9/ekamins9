--[[ PLAGUE NIGHT — the living against the plague, till dawn (GameConfig.MODES.Plague).

     It's night. Everyone starts among THE LIVING (team A). A few seconds in, the plague stirs:
     patient zero (one in six of the players, never everyone) turns, and the first ghouls
     (Combat ▸ Monsters, PlagueGhoul) shamble out of the dark. Anyone of the living who falls
     RISES AS A GHOUL (team B) — with a ghoul's body (green, clawed, a sickly glow), a cleaver,
     more health, a quicker step, and the mending of the dead out of a fight — and hunts the rest.
     More ghouls come out of the dark as the night deepens. When the living are few, bots stand
     with them, and a bot that falls rises as a ghoul too.

     THE DEAD COME UP OUT OF THE GROUND all round the living, never in one place: on open ground
     45–80 studs from someone living, inside the map, clawing up in a breath of grave-mist. Every
     so often THE DEAD SURGE from several sides at once. As the night deepens worse things come
     up: Plague Runners (quick), Bloaters (slow; they burst when they fall: stand clear), Plague
     Brutes (huge). One of the living who falls rises as a ghoul WHERE THEY FELL. The living carry
     a lantern's glow; the last of them STANDS ALONE (mended, quicker). The night wears on toward
     dawn: the sky pales and the mist thins as the clock runs down.

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
local SURGE_EVERY = 70    -- seconds between the dead's surges
local Debris = game:GetService("Debris")

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
		-- a lantern's glow about the living (the dark is the plague's)
		task.defer(function()
			local torso = char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
			if torso and not torso:FindFirstChild("Lantern") then
				local l = Instance.new("PointLight")
				l.Name = "Lantern"; l.Color = Color3.fromRGB(255, 196, 120); l.Range = 16; l.Brightness = 1.1; l.Shadows = true
				l.Parent = torso
			end
		end)
	end
end

-- where you come in: the living anywhere far from the plague; one who fell rises where they fell;
-- the plague's other risen out of the dark round the living
function Plague:spawnCFrame(plr)
	local key = Teams.keyOf(plr)
	if key == "B" and self.fellAt and self.fellAt[plr] then
		local at = self.fellAt[plr]
		self.fellAt[plr] = nil
		return CFrame.new(at + Vector3.new(0, 1, 0))
	end
	if key == "B" and self.stirred then
		local at = self:darkSpot()
		if at then return CFrame.new(at + Vector3.new(0, 3, 0)) end
	end
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

-- the map's ground, roughly: its spawns and zones, and a margin (nothing comes up outside the town)
function Plague:area()
	if self.bounds ~= nil then return self.bounds end
	local lo, hi, any = Vector3.new(math.huge, 0, math.huge), Vector3.new(-math.huge, 0, -math.huge), false
	local m = MapLoader.current
	for _, name in ipairs({"Spawns", "Zones"}) do
		local f = m and m:FindFirstChild(name)
		if f then
			for _, p in ipairs(f:GetDescendants()) do
				if p:IsA("BasePart") then
					any = true
					lo = Vector3.new(math.min(lo.X, p.Position.X), 0, math.min(lo.Z, p.Position.Z))
					hi = Vector3.new(math.max(hi.X, p.Position.X), 0, math.max(hi.Z, p.Position.Z))
				end
			end
		end
	end
	self.bounds = any and {lo = lo - Vector3.new(50, 0, 50), hi = hi + Vector3.new(50, 0, 50)} or false
	return self.bounds
end

-- OUT OF THE DARK: a spot on open ground round the living, beyond their lantern-light (45–80
-- studs from one of them, nearer none than 38), at their level (not a roof), never inside
-- anything; else one of the map's spawns
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
function Plague:darkSpot()
	local living = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local r = Teams.keyOf(p) == "A" and alive(p.Character) and p.Character:FindFirstChild("HumanoidRootPart")
		if r then table.insert(living, r.Position) end
	end
	for b in pairs(self.allies) do if b.alive and b.hrp then table.insert(living, b.hrp.Position) end end
	local skip = {}
	for _, n in ipairs({"NPCs", "LootDrops", "MonsterFX", "LootFX", "DroppedWeapons"}) do local f = workspace:FindFirstChild(n); if f then table.insert(skip, f) end end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(skip, p.Character) end end
	groundParams.FilterDescendantsInstances = skip
	overlap.FilterDescendantsInstances = skip
	local area = self:area()
	for _ = 1, 30 do
		if #living == 0 then break end
		local near = living[math.random(#living)]
		local a, d = math.random() * math.pi * 2, 45 + math.random() * 35
		local probe = near + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		local inside = not area or (probe.X > area.lo.X and probe.X < area.hi.X and probe.Z > area.lo.Z and probe.Z < area.hi.Z)
		local hit = inside and workspace:Raycast(probe + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), groundParams)
		if hit and hit.Normal.Y > 0.7 and math.abs(hit.Position.Y - (near.Y - 3)) < 14 and hit.Material ~= Enum.Material.Water then
			local spot = hit.Position
			local nearest = math.huge
			for _, l in ipairs(living) do nearest = math.min(nearest, (l - spot).Magnitude) end
			local clear = nearest > 38
			if clear then
				for _, part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(spot + Vector3.new(0, 3.2, 0)), Vector3.new(3, 5, 3), overlap)) do
					if part.CanCollide then clear = false; break end
				end
			end
			if clear then return spot end
		end
	end
	local spots = MapLoader.spawns(nil)
	return #spots > 0 and (spots[math.random(#spots)].Position - Vector3.new(0, 3, 0)) or nil
end

-- the ground breaks, grave-mist, and it claws its way up
local function emerge(at)
	local fx = workspace:FindFirstChild("MonsterFX") or workspace
	local p = Instance.new("Part")
	p.Name = "GraveMist"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.2, 6, 6)
	p.CFrame = CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Color, p.Material = Color3.fromRGB(46, 38, 30), Enum.Material.Ground
	p.Parent = fx
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(120, 200, 110), Color3.fromRGB(40, 60, 40))
	pe.Size = NumberSequence.new(2, 6)
	pe.Transparency = NumberSequence.new(0.4, 1)
	pe.Lifetime = NumberRange.new(1.5, 2.5)
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(60, 60)
	pe.Rate = 0
	pe.Parent = p
	pe:Emit(26)
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/action_falling.mp3"; s.Volume = 0.5; s.PlaybackSpeed = 0.5; s.RollOffMaxDistance = 140
	s.Parent = p; s:Play()
	task.delay(3, function() if p.Parent then p.Transparency = 1 end end)
	Debris:AddItem(p, 5)
end

-- how far into the night (0 at the start, 1 at dawn)
function Plague:night()
	local total = Game.roundLength(self.def)
	if not total or total <= 0 or not self.startedClock then return 0 end
	return math.clamp((os.clock() - self.startedClock) / total, 0, 1)
end

-- what comes up: ghouls, and quick runners from the first; bloaters, then brutes, as it deepens
function Plague:pickKind()
	local k = self:night()
	local brutes = 0
	for m, kind in pairs(self.kindOf) do if kind == "PlagueBrute" and m.alive then brutes += 1 end end
	if k > 0.4 and brutes < 1 + math.floor(#Players:GetPlayers() / 6) and math.random() < 0.06 + k * 0.08 then return "PlagueBrute" end
	if k > 0.2 and math.random() < 0.16 then return "PlagueBloater" end
	if math.random() < 0.3 then return "PlagueRunner" end
	return "PlagueGhoul"
end

-- one of the dead out of the ground round the living (or where a villager fell)
function Plague:spawnGhoul(at, kind)
	local pos = at and at.Position or self:darkSpot()
	if not pos then return nil end
	kind = kind or (at and "PlagueGhoul") or self:pickKind()
	emerge(pos)
	local cf = CFrame.new(pos + Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	local m = Monsters.spawn(kind, self.mobOpts, {at = cf, hpMult = 1 + #Players:GetPlayers() * 0.05})
	if m then self.mobs[m] = true; self.kindOf[m] = kind end
	return m
end

function Plague:start(map)
	Game.Mode.start(self, map)   -- (teams: then everyone onto the living)
	for _, p in ipairs(Players:GetPlayers()) do Teams.set(p, "A") end
	node:SetAttribute("FriendlyFire", false)
	self.turned, self.mobs, self.allies, self.fellAt, self.kindOf = {}, {}, {}, {}, {}
	self.firstAt = os.clock() + FIRST_TURN
	self.surgeAt = self.firstAt + SURGE_EVERY
	self.startedClock = os.clock()
	self.bounds, self.lastStand = nil, nil
	self.nextGhoul = self.firstAt
	self.everLiving = false
	self.mobOpts = {team = "B", startDelay = 0.4, corpseTime = 4, fightBots = true,
		onDeath = function(m) self.mobs[m] = nil; self.kindOf[m] = nil end}
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
	-- (a map's Atmosphere overrules the fog: thicken it to a night mist instead)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		self.atmoBefore = {Density = atmo.Density, Color = atmo.Color, Decay = atmo.Decay, Haze = atmo.Haze, Glare = atmo.Glare, Offset = atmo.Offset}
		atmo.Density, atmo.Offset, atmo.Haze, atmo.Glare = 0.42, 0.1, 1.6, 0
		atmo.Color, atmo.Decay = Color3.fromRGB(42, 52, 62), Color3.fromRGB(22, 28, 34)
	end
	for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("AdvChip", "🛡 THE LIVING") end
	task.delay(2, function() banner({text = "PLAGUE NIGHT", sub = "SURVIVE UNTIL DAWN", kind = "floor"}) end)
end

function Plague:stop()
	if self.mobOpts then Monsters.halt(self.mobOpts) end
	for m in pairs(self.mobs or {}) do Monsters.despawn(m) end
	for b in pairs(self.allies or {}) do if b.model and b.model.Parent then pcall(function() b:destroy() end) end end
	self.mobs, self.allies = {}, {}
	if self.lightBefore then for k, v in pairs(self.lightBefore) do pcall(function() Lighting[k] = v end) end; self.lightBefore = nil end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo and self.atmoBefore then for k, v in pairs(self.atmoBefore) do pcall(function() atmo[k] = v end) end end
	self.atmoBefore = nil
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then p.Character:SetAttribute("SpeedMult_LastStand", nil) end end
	for _, k in ipairs({"OwnHud", "ObjKind", "ObjLabel", "ObjNote"}) do node:SetAttribute(k, nil) end
	for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("AdvChip", nil) end
end

-- the living fall: they turn, and rise where they fell
function Plague:onDeath(victimPlr)
	if Teams.keyOf(victimPlr) == "A" and self.firstAt and os.clock() >= self.firstAt then
		local r = victimPlr.Character and victimPlr.Character:FindFirstChild("HumanoidRootPart")
		if r then
			self.fellAt[victimPlr] = r.Position
			local pos = r.Position
			task.delay(math.max(0, (self.def.respawnDelay or 3) - 0.6), function() if Game.current == self then emerge(pos - Vector3.new(0, 3, 0)) end end)
		end
		self:turn(victimPlr)
	end
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
	-- THE DEAD SURGE: up out of the ground on several sides at once, now and then
	if self.stirred and now >= self.surgeAt then
		self.surgeAt = now + SURGE_EVERY
		local n = 3 + math.floor(#players / 2) + math.floor(self:night() * 3)
		for i = 1, n do task.delay(i * 0.4, function() if Game.current == self then self:spawnGhoul() end end) end
		banner({text = "THE DEAD SURGE", sub = "THEY'RE COMING UP OUT OF THE GROUND", kind = "boss"})
	end
	-- the night wears on toward dawn: the sky pales, the mist thins
	local k = self:night()
	local kk = k * k
	Lighting.ClockTime = 0.4 + k * 5.5
	Lighting.Brightness = 0.5 + kk * 1.3
	Lighting.FogEnd = 220 + kk * 380
	Lighting.OutdoorAmbient = Color3.fromRGB(64, 72, 96):Lerp(Color3.fromRGB(156, 140, 150), kk)
	Lighting.FogColor = Color3.fromRGB(20, 26, 34):Lerp(Color3.fromRGB(150, 128, 136), kk)
	local atmo = self.atmoBefore and Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmo.Density = 0.42 - kk * 0.12
		atmo.Color = Color3.fromRGB(42, 52, 62):Lerp(Color3.fromRGB(196, 168, 168), kk)
		atmo.Decay = Color3.fromRGB(22, 28, 34):Lerp(Color3.fromRGB(150, 110, 110), kk)
	end
	-- the last of the living STANDS ALONE: mended, quicker
	if self.stirred and not self.lastStand and #players >= 2 then
		local last, n = nil, 0
		for _, p in ipairs(players) do if Teams.keyOf(p) == "A" and alive(p.Character) then last = p; n += 1 end end
		if n == 1 and next(self.allies) == nil then
			self.lastStand = last
			local h = humOf(last.Character)
			if h then h.MaxHealth += 50; h.Health = h.MaxHealth end
			last.Character:SetAttribute("SpeedMult_LastStand", 1.12)
			banner({text = string.upper(last.DisplayName) .. " STANDS ALONE", sub = "THE LAST OF THE LIVING", kind = "elite"})
			banner({text = "YOU STAND ALONE", sub = "HOLD UNTIL DAWN", kind = "boss"}, last)
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
