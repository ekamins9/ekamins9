--[[ SIEGE — after Chivalry 2's Team Objective: the attackers take a castle
     stage by stage, the defenders hold until the clock runs out. Every stage
     the attackers finish adds time. Sides swap every round.

     The map lists its stages in Map ▸ Objectives (Build ▸ MapKit: K.objective):
       Ram      push the Ram along its Path: it rolls while more attackers than
                defenders stand within Radius of it (faster with more, up to
                1.75×) and stops when they're even. At the end it batters the
                Gate: one blow every Interval s while the attackers hold the
                ram, Hits blows to break it
       Capture  hold the Zone: attackers in it and no defender fill it in Time s
                (faster with more); defenders alone push it back
       Slay     the defenders' champion (a bot: Name, Weapon, Health +
                PerAttacker per attacker) rises at At: kill him
       every stage: Label (the HUD's line), AddTime (seconds added when it's done)
     Spawns (Map ▸ Spawns) carry Side = "Attack" | "Defend" and Stage = n: a side
     spawns at its highest Stage that isn't past the current one.

     Round attributes for the HUD (StarterPlayerScripts ▸ Objectives):
       Attackers "A"|"B" · ObjKind · ObjStage / ObjStages · ObjLabel ·
       ObjProgress 0..1 · ObjState ("moving" "contested" "idle" "battering"
       "capturing" "losing" "fighting") · ObjPos · ObjAttack / ObjDefend (bodies
       at the objective) · ObjNote ("GATE 4 / 10")
     ObjectiveEvent (RemoteEvent) server -> all: "Stage", {text, add, team, final} ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Sounds = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Teams, MapLoader = Game.Teams, Game.MapLoader

local event = ReplicatedStorage:FindFirstChild("ObjectiveEvent")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "ObjectiveEvent"
	event.Parent = ReplicatedStorage
end

local node = Game.node
local ATTRS = {"Attackers", "ObjKind", "ObjStage", "ObjStages", "ObjLabel", "ObjProgress", "ObjState", "ObjPos", "ObjAttack", "ObjDefend", "ObjNote"}

local Siege = setmetatable({}, {__index = Game.Mode})
Siege.__index = Siege

function Siege.new(def, id)
	local self = setmetatable(Game.Mode.new(def, id), Siege)
	self.roundWins = {A = 0, B = 0}
	self.attack = "B"   -- flips to A on the first round
	return self
end

local function other(t) return t == "A" and "B" or "A" end

-- living players of each side within r of pos (flat distance; |dy| ≤ h)
local function countNear(pos, r, h, attackKey)
	local a, d, who = 0, 0, {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local off = hrp.Position - pos
			if Vector3.new(off.X, 0, off.Z).Magnitude <= r and math.abs(off.Y) <= (h or 12) then
				local t = Teams.keyOf(p)
				if t == attackKey then a += 1; table.insert(who, p) elseif t then d += 1 end
			end
		end
	end
	return a, d, who
end

-- a point `d` studs along a polyline, and the way it runs there
local function along(pts, d)
	for i = 1, #pts - 1 do
		local seg = pts[i + 1] - pts[i]
		local len = seg.Magnitude
		if d <= len or i == #pts - 1 then
			local t = math.clamp(d / math.max(len, 1e-3), 0, 1)
			return pts[i] + seg * t, seg.Unit
		end
		d -= len
	end
	return pts[1], Vector3.new(0, 0, -1)
end

--------------------------------------------------------------------
--  ROUND
--------------------------------------------------------------------
function Siege:start(map)
	Game.Mode.start(self, map)
	self.attack = other(self.attack)
	self.defend = other(self.attack)
	node:SetAttribute("Attackers", self.attack)
	self.stages = {}
	local m = MapLoader.current
	local folder = m and m:FindFirstChild("Objectives")
	for _, c in ipairs(folder and folder:GetChildren() or {}) do table.insert(self.stages, c) end
	table.sort(self.stages, function(x, y) return (x:GetAttribute("Order") or 0) < (y:GetAttribute("Order") or 0) end)
	self.stage, self.done, self.bonusTime = 0, false, 0
	self.scores = {A = self.roundWins.A, B = self.roundWins.B}
	node:SetAttribute("ObjStages", #self.stages)
	-- zones start hidden; each shows while it's the stage
	for _, st in ipairs(self.stages) do
		local z = st:FindFirstChild("Zone")
		if z then z.Transparency = 1 end
	end
	self:nextStage()
	self:publishScores()
	self.conn = RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(self.step, self, dt)
		if not ok then warn("[Siege]", err) end
	end)
end

function Siege:stop()
	if self.conn then self.conn:Disconnect(); self.conn = nil end
	if self.boss then self.boss:destroy(); self.boss = nil end
	self.ram, self.cap = nil, nil
	for _, k in ipairs(ATTRS) do node:SetAttribute(k, nil) end
end

function Siege:nextStage()
	self.stage += 1
	local c = self.stages[self.stage]
	self.cur, self.ram, self.cap, self.progress = c, nil, nil, 0
	self.state, self.near = "idle", {a = 0, d = 0, who = {}}
	if not c then self.done = true; return end
	self.kind = c:GetAttribute("Kind")
	node:SetAttribute("ObjStage", self.stage)
	node:SetAttribute("ObjKind", self.kind)
	node:SetAttribute("ObjLabel", c:GetAttribute("Label") or self.kind)
	node:SetAttribute("ObjNote", "")
	if self.kind == "Ram" then self:setupRam(c)
	elseif self.kind == "Capture" then self:setupCapture(c)
	elseif self.kind == "Slay" then self:setupSlay(c)
	else warn("[Siege] unknown stage kind", tostring(self.kind)); self:complete("") end
	self:publishScores()
end

-- the stage is won: time on the clock, pay the attackers who did it, tell everyone
function Siege:complete(text)
	local c = self.cur
	local last = self.stage >= #self.stages
	local add = (c and c:GetAttribute("AddTime")) or 0
	if not last and add > 0 then self.bonusTime = (self.bonusTime or 0) + add end
	for _, p in ipairs(self.near.who or {}) do if _G.RoundBump then _G.RoundBump(p, "objective") end end
	if text ~= "" then event:FireAllClients("Stage", {text = text, add = last and 0 or add, team = self.attack, final = last}) end
	local z = c and c:FindFirstChild("Zone")
	if z then z.Transparency = 1 end
	self:nextStage()
end

--------------------------------------------------------------------
--  RAM AND GATE
--------------------------------------------------------------------
function Siege:setupRam(c)
	local model, pathF = c:FindFirstChild("Ram"), c:FindFirstChild("Path")
	local pts = {}
	for i = 1, 64 do
		local p = pathF and pathF:FindFirstChild("P" .. i)
		if not p then break end
		table.insert(pts, p.Position)
	end
	if not (model and model.PrimaryPart and #pts >= 2) then warn("[Siege] the ram stage needs Ram (with a PrimaryPart) and Path P1..Pn"); self:complete(""); return end
	local len = 0
	for i = 1, #pts - 1 do len += (pts[i + 1] - pts[i]).Magnitude end
	local gate = c:FindFirstChild("Gate")
	local r = {model = model, pts = pts, len = len, dist = 0, gate = gate,
		speed = c:GetAttribute("Speed") or 2.6, radius = c:GetAttribute("Radius") or 13, interval = c:GetAttribute("Interval") or 2.4,
		hits = (gate and gate:GetAttribute("Hits")) or 10, dealt = 0, nextHit = 0, swinging = false, atGate = false, swing = {}}
	local body = model.PrimaryPart
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("Swing") then table.insert(r.swing, {part = p, off = body.CFrame:ToObjectSpace(p.CFrame)}) end
	end
	self.ram = r
	self:placeRam(0)
end

function Siege:placeRam(d)
	local r = self.ram
	local pos, dir = along(r.pts, d)
	r.model:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(dir.X, 0, dir.Z)) * CFrame.new(0, 1.6, 0))
end

-- one blow: the log draws back on its chains, then drives into the gate
function Siege:swing()
	local r = self.ram
	r.swinging = true
	task.spawn(function()
		local body = r.model.PrimaryPart
		local function pose(back)
			for _, s in ipairs(r.swing) do s.part.CFrame = body.CFrame * CFrame.new(0, 0, back) * s.off end
		end
		local t0 = os.clock()
		while os.clock() - t0 < 0.9 do pose(2.6 * math.sin((os.clock() - t0) / 0.9 * math.pi / 2)); RunService.Heartbeat:Wait() end
		local t1 = os.clock()
		while os.clock() - t1 < 0.16 do local a = (os.clock() - t1) / 0.16; pose(2.6 * (1 - a * a)); RunService.Heartbeat:Wait() end
		pose(0)
		if self.ram == r then self:impact() end
		r.nextHit = os.clock() + math.max(0.3, r.interval - 1.06)
		r.swinging = false
	end)
end

function Siege:impact()
	local r = self.ram
	r.dealt += 1
	local gate = r.gate
	local head = r.model:FindFirstChild("RamHead")
	local at = head and (head.Position + r.model.PrimaryPart.CFrame.LookVector * 2) or r.model.PrimaryPart.Position
	Sounds.play(SoundConfig.RamHit, head or r.model.PrimaryPart, {Volume = 2, Speed = 0.5, MaxDistance = 220})
	-- splinters and dust where it lands
	local a0 = Instance.new("Attachment"); a0.WorldPosition = at; a0.Parent = workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(140, 104, 70)); e.Size = NumberSequence.new(0.5, 0.1)
	e.Lifetime = NumberRange.new(0.5, 1.1); e.Speed = NumberRange.new(10, 22); e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(0, -40, 0); e.Rate = 0; e.Parent = a0
	e:Emit(26)
	Debris:AddItem(a0, 1.5)
	-- the doors shudder
	if gate then
		for _, p in ipairs(gate:GetDescendants()) do
			if p:IsA("BasePart") and p.Name == "Door" then
				local home = p:GetAttribute("Home") or p.CFrame
				if not p:GetAttribute("Home") then p:SetAttribute("Home", home) end
				p.CFrame = home * CFrame.Angles(0, math.rad(math.random(-2, 2)), 0) * CFrame.new(0, 0, -0.3)
				TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Elastic), {CFrame = home}):Play()
			end
		end
	end
	if r.dealt >= r.hits then self:breakGate() end
end

function Siege:breakGate()
	local r = self.ram
	local gate = r.gate
	local inward = r.model.PrimaryPart.CFrame.LookVector
	Sounds.play(SoundConfig.GateBreak, r.model.PrimaryPart, {Volume = 1.6, Speed = 0.7, MaxDistance = 300})
	if gate then
		for _, p in ipairs(gate:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = false
				p.AssemblyLinearVelocity = inward * math.random(18, 34) + Vector3.new(math.random(-8, 8), math.random(4, 14), math.random(-8, 8))
				p.AssemblyAngularVelocity = Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))
			end
		end
		task.delay(1.4, function()
			for _, p in ipairs(gate:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
		end)
		task.delay(3, function()
			for _, p in ipairs(gate:GetDescendants()) do
				if p:IsA("BasePart") then TweenService:Create(p, TweenInfo.new(2), {Transparency = 1}):Play() end
			end
			Debris:AddItem(gate, 2.2)
		end)
	end
	self:complete("THE GATE IS BROKEN")
end

--------------------------------------------------------------------
--  CAPTURE
--------------------------------------------------------------------
function Siege:setupCapture(c)
	local z = c:FindFirstChild("Zone")
	if not z then warn("[Siege] a capture stage needs a Zone"); self:complete(""); return end
	z.Transparency = 0.72
	z.Color = Teams.def(self.defend).rgb
	self.cap = {zone = z, time = c:GetAttribute("Time") or 22, r = z:GetAttribute("Radius") or 10, h = z:GetAttribute("Height") or 10}
end

--------------------------------------------------------------------
--  SLAY: the defenders' champion
--------------------------------------------------------------------
function Siege:setupSlay(c)
	local at = c:FindFirstChild("At")
	if not at then warn("[Siege] a slay stage needs an At part"); self:complete(""); return end
	local Bots = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots"))
	local hp = (c:GetAttribute("Health") or 220) + (c:GetAttribute("PerAttacker") or 70) * math.max(1, Teams.count(self.attack))
	local bot = Bots.spawn({
		at = at.CFrame, skill = "Champion", weapon = c:GetAttribute("Weapon") or "Greatsword", name = c:GetAttribute("Name") or "The Lord",
		weight = "Heavy", team = self.defend, startDelay = 1.2, corpseTime = 10,
		arena = {centre = at.Position, radius = at:GetAttribute("ArenaRadius") or 26},
		onDeath = function(b, killer)
			if self.boss == b then
				self.bossDead = true
				if killer and _G.RoundBump then _G.RoundBump(killer, "objective") end
			end
		end,
	})
	bot.hum.MaxHealth = hp
	bot.hum.Health = hp
	bot.model:SetAttribute("Boss", true)
	self.boss, self.bossDead = bot, false
end

--------------------------------------------------------------------
--  EVERY FRAME: the ram rolls, zones fill, the champion bleeds
--------------------------------------------------------------------
function Siege:step(dt)
	if self.done then return end
	if self.kind == "Ram" and self.ram then
		local r = self.ram
		local body = r.model.PrimaryPart
		local a, d, who = countNear(body.Position, r.radius, 14, self.attack)
		self.near = {a = a, d = d, who = who, pos = body.Position}
		if not r.atGate then
			if a > d then
				r.dist = math.min(r.len, r.dist + r.speed * math.clamp(1 + 0.25 * (a - d - 1), 1, 1.75) * dt)
				self:placeRam(r.dist)
				self.state = "moving"
				if r.dist >= r.len - 0.01 then r.atGate = true end
			else
				self.state = a > 0 and "contested" or "idle"
			end
			self.progress = 0.7 * r.dist / math.max(r.len, 1)
			self.note = ""
		else
			if a > d then
				self.state = "battering"
				if not r.swinging and os.clock() >= r.nextHit then self:swing() end
			else
				self.state = a > 0 and "contested" or "idle"
			end
			self.progress = 0.7 + 0.3 * r.dealt / math.max(r.hits, 1)
			self.note = string.format("GATE %d / %d", r.dealt, r.hits)
		end
	elseif self.kind == "Capture" and self.cap then
		local cap = self.cap
		local pos = cap.zone.Position
		local a, d, who = countNear(pos, cap.r, cap.h, self.attack)
		self.near = {a = a, d = d, who = who, pos = pos}
		if a > 0 and d == 0 then
			self.progress = math.min(1, self.progress + dt / cap.time * math.min(1 + 0.4 * (a - 1), 2.2))
			self.state = "capturing"
		elseif a > 0 then
			self.state = "contested"
		elseif d > 0 and self.progress > 0 then
			self.progress = math.max(0, self.progress - dt / (cap.time * 1.5))
			self.state = "losing"
		else
			self.state = "idle"
		end
		self.note = string.format("%d%%", math.floor(self.progress * 100))
		if self.progress >= 1 then self:complete(string.upper(self.cur:GetAttribute("Label") or "TAKEN") .. "  ·  DONE") end
	elseif self.kind == "Slay" and self.boss then
		local b = self.boss
		local hrp = b.hrp
		local pos = hrp and hrp.Position or Vector3.zero
		local a, d, who = countNear(pos, 30, 14, self.attack)
		self.near = {a = a, d = d, who = who, pos = pos}
		local max = math.max(b.hum.MaxHealth, 1)
		self.progress = 1 - math.clamp(b.hum.Health / max, 0, 1)
		self.state = "fighting"
		self.note = string.format("%d HP", math.max(0, math.ceil(b.hum.Health)))
		if self.bossDead or b.hum.Health <= 0 then
			self.boss = nil
			self:complete(string.upper(self.cur:GetAttribute("Name") or "THE LORD") .. " IS SLAIN")
		end
	end
end

-- four times a second: what the HUD shows
function Siege:tick(dt)
	if self.done then return end
	node:SetAttribute("ObjProgress", math.floor((self.progress or 0) * 1000) / 1000)
	node:SetAttribute("ObjState", self.state or "idle")
	node:SetAttribute("ObjAttack", self.near and self.near.a or 0)
	node:SetAttribute("ObjDefend", self.near and self.near.d or 0)
	node:SetAttribute("ObjNote", self.note or "")
	if self.near and self.near.pos then node:SetAttribute("ObjPos", self.near.pos) end
	-- a capture zone takes the attackers' colour as it fills
	if self.cap then
		self.cap.zone.Color = Teams.def(self.defend).rgb:Lerp(Teams.def(self.attack).rgb, self.progress or 0)
	end
	node:SetAttribute("Objective", self:objective())
end

--------------------------------------------------------------------
--  SPAWNS, END, TEXT
--------------------------------------------------------------------
function Siege:spawnCFrame(plr)
	local side = Teams.keyOf(plr) == self.attack and "Attack" or "Defend"
	local m = MapLoader.current
	local folder = m and m:FindFirstChild("Spawns")
	local best, bestStage = {}, -1
	local now = math.max(self.stage or 1, 1)
	for _, p in ipairs(folder and folder:GetChildren() or {}) do
		local s, st = p:GetAttribute("Side"), p:GetAttribute("Stage") or 1
		if s == side and st <= now then
			if st > bestStage then best, bestStage = {p.CFrame}, st elseif st == bestStage then table.insert(best, p.CFrame) end
		end
	end
	if #best == 0 then return Game.Mode.spawnCFrame(self, plr) end
	-- the one farthest from the other side
	local enemies = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local hrp = p ~= plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if hrp and Teams.keyOf(p) ~= Teams.keyOf(plr) then table.insert(enemies, hrp.Position) end
	end
	local pick, far = best[1], -1
	for _, cf in ipairs(best) do
		local d = math.huge
		for _, e in ipairs(enemies) do d = math.min(d, (cf.Position - e).Magnitude) end
		if d == math.huge then d = 1e6 end
		d += math.random() * 3
		if d > far then pick, far = cf, d end
	end
	return pick
end

function Siege:isOver()
	if not self.done then return nil end
	self.roundWins[self.attack] += 1
	self.scores = {A = self.roundWins.A, B = self.roundWins.B}
	self:publishScores()
	return self:teamResult(self.attack) .. "  ·  " .. string.upper(GameConfig.mapTitle(MapLoader.name or "")) .. " HAS FALLEN"
end
function Siege:result()
	-- the clock ran out: the castle held
	self.roundWins[self.defend] += 1
	self.scores = {A = self.roundWins.A, B = self.roundWins.B}
	self:publishScores()
	return self:teamResult(self.defend) .. "  ·  " .. string.upper(GameConfig.mapTitle(MapLoader.name or "")) .. " HOLDS"
end
function Siege:objective()
	local c = self.cur
	local side = Teams.def(self.attack or "A")
	return string.format("SIEGE  ·  %s ATTACK  ·  STAGE %d / %d  ·  %s", string.upper(side and side.name or "?"),
		math.min(self.stage or 1, #(self.stages or {})), #(self.stages or {}), string.upper(c and (c:GetAttribute("Label") or "") or ""))
end

return Siege
