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
     The mode's `attack` table (GameConfig.MODES.Siege) scales those for the
     attackers: addTime, ramSpeed, gateHits, captureTime, champion.
     Numbers win ground: the ram creeps on a tie and rolls when the attackers
     outnumber the defenders; a zone fills (slower) while the attackers
     outnumber the defenders in it, and stops on a tie.
     Spawns (Map ▸ Spawns) carry Side = "Attack" | "Defend" and Stage = n: a side
     spawns at its highest Stage that isn't past the current one.

     Round attributes for the HUD (StarterPlayerScripts ▸ Objectives):
       Attackers "A"|"B" · ObjKind · ObjStage / ObjStages · ObjLabel ·
       ObjProgress 0..1 · ObjState ("moving" "contested" "idle" "battering"
       "capturing" "losing" "fighting") · ObjPos · ObjAttack / ObjDefend (bodies
       at the objective) · ObjNote ("GATE 4 / 10")
     ObjectiveEvent (RemoteEvent) server -> all: "Stage", {text, add, team, final}

     THE WAR ROUND IT (Game ▸ Engines, drawn by Engines.client): the attackers' trebuchets out
     beyond their first spawns lob fire onto the defenders near the objective (a red ring first),
     and both sides' archers loose volleys at knots of the other near it (a raised guard or a roof
     spares you). Gentler than War's (power 0.6).

     THE CASTLE, DESCRIBED for the war drawn round it on every screen (SiegeEpic.client): a client
     streams the map in bit by bit, so the server reads it once and puts what matters on the Map
     model as attributes: C_Gate, C_Att (the attackers' first spawns), C_F (+1/-1: the field
     lies towards +z/-z), C_FaceZ / C_Top (the front wall's outer face, its top), C_Ground (the
     ground before it), C_Half (the castle's half width), C_Bound (the field's edge in x),
     C_Spans + C_Span<i> (x0, walk y, z) / C_SpanEnd<i> (x1): the open stretches of the front
     walk; C_Towers + C_Tower<i>: the top of each tower's roof; C_Roof: the great hall's;
     C_Defs + C_Def<i>: the defenders' first spawns; C_SideX / C_SideY / C_SideZ: the side walls'
     outer face (|x| from the gate), walk top, and the middle of their walk in z (where the
     siege towers dock); C_TowerYaw: the SiegeTower prop's own turn, and Map ▸ TowerModel (one,
     under the map, always streamed) for the clients to copy. Only a castle facing along z. ]]

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
local Engines = require(script.Parent.Parent:WaitForChild("Engines"))
local WarProps = require(script.Parent.Parent:WaitForChild("WarProps"))
local Litter = require(script.Parent.Parent:WaitForChild("Litter"))
local Teams, MapLoader = Game.Teams, Game.MapLoader

local event = ReplicatedStorage:FindFirstChild("ObjectiveEvent")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "ObjectiveEvent"
	event.Parent = ReplicatedStorage
end

local node = Game.node
local ATTRS = {"Attackers", "ObjKind", "ObjStage", "ObjStages", "ObjLabel", "ObjProgress", "ObjState", "ObjPos", "ObjAttack", "ObjDefend", "ObjNote", "ObjRadius"}

local Siege = setmetatable({}, {__index = Game.Mode})
Siege.__index = Siege

function Siege.new(def, id)
	local self = setmetatable(Game.Mode.new(def, id), Siege)
	self.roundWins = {A = 0, B = 0}
	self.attack = "B"   -- flips to A on the first round
	return self
end

local function other(t) return t == "A" and "B" or "A" end
-- the attackers' easing (GameConfig.MODES.Siege.attack), 1 when unset
local function ease(self, key) local a = self.def and self.def.attack; return (a and a[key]) or 1 end

-- living fighters of each side within r of pos (flat distance; |dy| ≤ h),
-- fill bots too; `who` is the attacking players (they get the pay)
local function countNear(pos, r, h, attackKey)
	local a, d, who = 0, 0, {}
	for _, key in ipairs({"A", "B"}) do
		for char, hrp in pairs(Teams.fighters(key)) do
			local off = hrp.Position - pos
			if Vector3.new(off.X, 0, off.Z).Magnitude <= r and math.abs(off.Y) <= (h or 12) then
				if key == attackKey then
					a += 1
					local p = Players:GetPlayerFromCharacter(char)
					if p then table.insert(who, p) end
				else
					d += 1
				end
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
	-- THE DAY GOES ON over the assault (as War's): a morning brightens, an afternoon wears on
	-- towards evening, the fires showing brighter as it does; a dusk or a night stays as it is
	do
		local c0 = game:GetService("Lighting").ClockTime
		local to = (c0 >= 6 and c0 < 10 and c0 + 0.8) or (c0 >= 10 and c0 < 16.5 and math.min(c0 + 1.2, 17)) or c0
		self.sun = to ~= c0 and {from = c0, to = to, at = os.clock(), len = 600} or nil
		self.sunTick = 0
	end
	self.scores = {A = self.roundWins.A, B = self.roundWins.B}
	node:SetAttribute("ObjStages", #self.stages)
	-- zones start hidden; each shows while it's the stage
	for _, st in ipairs(self.stages) do
		local z = st:FindFirstChild("Zone")
		if z then z.Transparency = 1 end
	end
	self:nextStage()
	self:publishScores()
	pcall(Siege.describeCastle, MapLoader.current)
	self:startEngines()
	self.conn = RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(self.step, self, dt)
		if not ok then warn("[Siege]", err) end
	end)
end

-- THE CASTLE, DESCRIBED (the header): attributes on the Map for every screen's war round it
local function extent(p)
	local cf, sz = p.CFrame, p.Size
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	return Vector3.new(math.abs(r.X) * sz.X + math.abs(u.X) * sz.Y + math.abs(l.X) * sz.Z,
		math.abs(r.Y) * sz.X + math.abs(u.Y) * sz.Y + math.abs(l.Y) * sz.Z,
		math.abs(r.Z) * sz.X + math.abs(u.Z) * sz.Y + math.abs(l.Z) * sz.Z)
end
function Siege.describeCastle(m)
	local obj = m and m:FindFirstChild("Objectives")
	local geo = m and m:FindFirstChild("Geometry")
	local spawns = m and m:FindFirstChild("Spawns")
	if not (obj and geo and spawns) then return end
	local gate
	for _, c in ipairs(obj:GetChildren()) do
		local g = c:FindFirstChild("Gate")
		if g then gate = g:GetPivot().Position end
	end
	if not gate then return end
	local att, n, defs = Vector3.zero, 0, {}
	for _, p in ipairs(spawns:GetChildren()) do
		if p:IsA("BasePart") then
			local side, st = p:GetAttribute("Side"), p:GetAttribute("Stage") or 1
			if side == "Attack" and st == 1 then att += p.Position; n += 1 end
			if side == "Defend" and st == 1 then table.insert(defs, p.Position) end
		end
	end
	if n == 0 then return end
	att /= n
	if math.abs(att.Z - gate.Z) < math.abs(att.X - gate.X) * 2 then return end
	local f = att.Z > gate.Z and 1 or -1
	local faceZ, top, half, bound = gate.Z + f * 2, gate.Y + 10, 40, 400
	local walks, towers, roof = {}, {}, nil
	local side = nil   -- {face = |x| of the outer face, y = walk top, z = the walk's middle}
	for _, p in ipairs(geo:GetDescendants()) do
		if p:IsA("BasePart") then
			local nm, e, pos = p.Name, extent(p), p.Position
			if nm == "Walk" and e.Z > 40 and e.Z > e.X * 3 and math.abs(pos.X - gate.X) > 30 then
				-- (a side wall's walk: its outer face is the wall's, a couple of studs further out)
				side = side or {}
				side.y, side.z = pos.Y + e.Y / 2, pos.Z
				side.walk = math.abs(pos.X - gate.X) + e.X / 2
			elseif nm == "Wall" and e.Z > 40 and e.Z > e.X * 3 and math.abs(pos.X - gate.X) > 30 then
				side = side or {}
				side.face = math.abs(pos.X - gate.X) + e.X / 2
			end
			if (nm == "Walk" or nm == "Wall") and e.X > e.Z * 3 and math.abs(pos.Z - gate.Z) < 6 then
				if nm == "Walk" then table.insert(walks, {x0 = pos.X - e.X / 2, x1 = pos.X + e.X / 2, y = pos.Y + e.Y / 2, z = pos.Z})
				else faceZ = pos.Z + f * e.Z / 2; top = pos.Y + e.Y / 2 end
			elseif nm == "Tower" then
				table.insert(towers, {x0 = pos.X - e.X / 2, x1 = pos.X + e.X / 2, z = pos.Z, dz = e.Z / 2, at = pos})
				if math.abs(pos.Z - gate.Z) < e.Z then half = math.max(half, math.abs(pos.X - gate.X) + e.X / 2) end
			elseif nm == "HallRidge" or (nm == "HallRoof" and not roof) then
				roof = pos
			elseif nm == "Bound" and e.Z > e.X * 3 then
				bound = math.min(bound, math.abs(pos.X - gate.X) - 6)
			end
		end
	end
	if #walks == 0 then return end
	-- the top of whatever stands at a point (a roof's peak), and the ground before the wall
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = {m, workspace.Terrain}
	local function topAt(p)
		local r = workspace:Raycast(Vector3.new(p.X, p.Y + 120, p.Z), Vector3.new(0, -240, 0), ray)
		return r and r.Position or p
	end
	local spans = {}
	for _, w in ipairs(walks) do
		local cuts = {}
		for _, t in ipairs(towers) do
			if math.abs(t.z - w.z) < t.dz + 4 and t.x1 > w.x0 and t.x0 < w.x1 then table.insert(cuts, t) end
		end
		table.sort(cuts, function(a, b) return a.x0 < b.x0 end)
		local x = w.x0
		for _, t in ipairs(cuts) do
			if t.x0 - x >= 12 then table.insert(spans, {x, t.x0, w}) end
			x = math.max(x, t.x1)
		end
		if w.x1 - x >= 12 then table.insert(spans, {x, w.x1, w}) end
	end
	m:SetAttribute("C_Gate", gate)
	m:SetAttribute("C_Att", att)
	m:SetAttribute("C_F", f)
	m:SetAttribute("C_FaceZ", faceZ)
	m:SetAttribute("C_Top", top)
	m:SetAttribute("C_Ground", topAt(Vector3.new(gate.X, gate.Y, faceZ + f * 8)).Y)
	m:SetAttribute("C_Half", half)
	m:SetAttribute("C_Bound", bound)
	m:SetAttribute("C_Spans", #spans)
	for i, sp in ipairs(spans) do
		m:SetAttribute("C_Span" .. i, Vector3.new(sp[1], sp[3].y, sp[3].z))
		m:SetAttribute("C_SpanEnd" .. i, sp[2])
	end
	m:SetAttribute("C_Towers", #towers)
	for i, t in ipairs(towers) do m:SetAttribute("C_Tower" .. i, topAt(t.at)) end
	if roof then m:SetAttribute("C_Roof", topAt(roof)) end
	if side and side.y and side.z then
		m:SetAttribute("C_SideX", side.face or side.walk)
		m:SetAttribute("C_SideY", side.y)
		m:SetAttribute("C_SideZ", side.z)
	end
	local props = game:GetService("ServerStorage"):FindFirstChild("WarProps")
	local tpl = props and props:FindFirstChild("SiegeTower")
	if tpl and side then
		m:SetAttribute("C_TowerYaw", tpl:GetAttribute("Yaw") or 0)
		-- a siege tower for the clients to copy (SiegeEpic rolls them up to the side walls): kept
		-- far under the map, nothing solid, and always sent (the map streams; this mustn't)
		local tm = WarProps.place("SiegeTower", CFrame.new(gate + Vector3.new(0, -400, 0)), (side.y or 18) + 6, m, false)
		if tm then
			tm.Name = "TowerModel"
			pcall(function() tm.ModelStreamingMode = Enum.ModelStreamingMode.Persistent end)
			for _, d in ipairs(tm:GetDescendants()) do
				if d:IsA("BasePart") then d.CanQuery, d.CanTouch, d.CastShadow = false, false, false end
			end
		end
	end
	m:SetAttribute("C_Defs", #defs)
	for i, d in ipairs(defs) do m:SetAttribute("C_Def" .. i, d) end
end

-- the war round the castle: where each side's engines stand (from the map's spawns)
function Siege:startEngines()
	local m = MapLoader.current
	local folder = m and m:FindFirstChild("Spawns")
	local att, def = {}, {}
	local attFirst, defLast = math.huge, -1
	for _, p in ipairs(folder and folder:GetChildren() or {}) do
		local side, st = p:GetAttribute("Side"), p:GetAttribute("Stage") or 1
		if side == "Attack" then
			if st < attFirst then att, attFirst = {p.Position}, st elseif st == attFirst then table.insert(att, p.Position) end
		elseif side == "Defend" then
			if st > defLast then def, defLast = {p.Position}, st elseif st == defLast then table.insert(def, p.Position) end
		end
	end
	if #att == 0 or #def == 0 then self.engines = nil; return end
	local function mid(list) local v = Vector3.zero; for _, q in ipairs(list) do v += q end; return v / #list end
	local a, d = mid(att), mid(def)
	local away = Vector3.new(a.X - d.X, 0, a.Z - d.Z)
	away = away.Magnitude > 1 and away.Unit or Vector3.new(0, 0, 1)
	local side = Vector3.new(-away.Z, 0, away.X)
	-- the attackers' trebuchets well back beyond their first spawns (out of sight: only their fire is
	-- seen), their archers just behind them; the defenders' archers up on the walls by their keep
	local trebs = {a + away * 160 + side * 40 + Vector3.new(0, 30, 0), a + away * 170 - side * 50 + Vector3.new(0, 30, 0)}
	-- the attackers' camp dressed for a siege: towers, ballistae, a pavilion (Game ▸ WarProps; set
	-- down only where the ground is clear, into the map so they go with it)
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = {workspace:FindFirstChild("NPCs") or workspace.Terrain}
	local function ground(p)
		local r = workspace:Raycast(p + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), ray)
		if not r then return nil end
		-- (only open, level ground about as high as their spawns: not a roof, a wall, a tree)
		if r.Normal.Y < 0.9 or math.abs(r.Position.Y - a.Y) > 8 then return nil end
		return r.Position
	end
	local function face(at) return CFrame.lookAt(at, Vector3.new(d.X, at.Y, d.Z)) end
	local props = {{"SiegeTower", away * 26 + side * 30, 30}, {"SiegeTower", away * 30 - side * 34, 30},
		{"Ballista", away * 14 + side * 52, 7}, {"Ballista", away * 16 - side * 56, 7}, {"Pavilion", away * 60, 18}}
	for _, pr in ipairs(props) do
		local at = ground(a + pr[2])
		if at then pcall(WarProps.place, pr[1], face(at), pr[3], m) end
	end
	-- the field before the walls littered with the fighting of the days before: arrows thick under
	-- the walls (the defenders' volleys), shields and spears along the road, a banner or two
	local gateAt = m:GetAttribute("C_Gate")
	if typeof(gateAt) == "Vector3" then
		local fz = (m:GetAttribute("C_F") or 1)
		local half = m:GetAttribute("C_Half") or 80
		pcall(Litter.scatter, m, function()
			local near = math.random() < 0.55
			local x = gateAt.X + (math.random() - 0.5) * (near and half * 1.8 or half * 2.2)
			local z = gateAt.Z + fz * (near and (6 + math.random() * 30) or (30 + math.random() * 150))
			return Vector3.new(x, gateAt.Y + 20, z)
		end, {shields = 18, spears = 14, arrows = 18, banners = 4, helms = 6}, {houses = m:GetAttribute("HouseSeed")})
	end
	local sides = {}
	sides[self.attack] = {trebs = trebs, archers = {a + away * 30 + side * 20, a + away * 30 - side * 20}}
	sides[self.defend] = {archers = {d + Vector3.new(0, 18, 0)}}
	self.engines = Engines.new({
		sides = sides, power = 0.6, grace = 25,
		beats = {treb = {14, 20}, volley = {16, 24}},
		target = function(s)
			local at = node:GetAttribute("ObjPos")
			return Engines.knot(s, typeof(at) == "Vector3" and at or nil, 80)
		end,
		alive = function() return Game.current == self and not self.done end,
	})
end

function Siege:stop()
	self.engines = nil
	self.sun = nil
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
	local add = math.floor(((c and c:GetAttribute("AddTime")) or 0) * ease(self, "addTime") + 0.5)
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
		speed = (c:GetAttribute("Speed") or 2.6) * ease(self, "ramSpeed"), radius = c:GetAttribute("Radius") or 13, interval = c:GetAttribute("Interval") or 2.4,
		hits = math.max(1, math.floor(((gate and gate:GetAttribute("Hits")) or 10) * ease(self, "gateHits") + 0.5)), dealt = 0, nextHit = 0, swinging = false, atGate = false, swing = {}}
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
	self.cap = {zone = z, time = (c:GetAttribute("Time") or 22) * ease(self, "captureTime"), r = z:GetAttribute("Radius") or 10, h = z:GetAttribute("Height") or 10}
	z.Transparency = 1   -- the glowing ring on the ground shows it (ObjectiveFX)
end

--------------------------------------------------------------------
--  SLAY: the defenders' champion
--------------------------------------------------------------------
function Siege:setupSlay(c)
	local at = c:FindFirstChild("At")
	if not at then warn("[Siege] a slay stage needs an At part"); self:complete(""); return end
	local Bots = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots"))
	local hp = ((c:GetAttribute("Health") or 220) + (c:GetAttribute("PerAttacker") or 70) * math.max(1, Teams.count(self.attack))) * ease(self, "champion")
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
			if a > 0 and a >= d then
				-- outnumbering them it rolls (faster with more); level with them it creeps
				local pace = a > d and math.clamp(1 + 0.25 * (a - d - 1), 1, 1.75) or 0.35
				r.dist = math.min(r.len, r.dist + r.speed * pace * dt)
				self:placeRam(r.dist)
				self.state = a > d and "moving" or "contested"
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
		if a > 0 and a > d then
			-- uncontested at full pace (faster with more); outnumbering the defenders
			-- in it, at the share of the zone they hold
			local share = d == 0 and 1 or (a - d) / a
			self.progress = math.min(1, self.progress + dt / cap.time * math.min(1 + 0.4 * (a - d - 1), 2.2) * share)
			self.state = d == 0 and "capturing" or "contested"
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
	if self.engines then self.engines:tick() end
	if self.sun and os.clock() - (self.sunTick or 0) > 2 then
		self.sunTick = os.clock()
		local u = math.clamp((os.clock() - self.sun.at) / self.sun.len, 0, 1)
		game:GetService("Lighting").ClockTime = self.sun.from + (self.sun.to - self.sun.from) * u
	end
	node:SetAttribute("ObjProgress", math.floor((self.progress or 0) * 1000) / 1000)
	node:SetAttribute("ObjState", self.state or "idle")
	node:SetAttribute("ObjAttack", self.near and self.near.a or 0)
	node:SetAttribute("ObjDefend", self.near and self.near.d or 0)
	node:SetAttribute("ObjNote", self.note or "")
	if self.near and self.near.pos then node:SetAttribute("ObjPos", self.near.pos) end
	-- the ring each client draws round the objective (none for the champion: he moves)
	node:SetAttribute("ObjRadius", (self.ram and self.ram.radius) or (self.cap and self.cap.r) or nil)
	-- a capture zone takes the attackers' colour as it fills
	if self.cap then
		self.cap.zone.Color = Teams.def(self.defend).rgb:Lerp(Teams.def(self.attack).rgb, self.progress or 0)
		self.cap.zone.Transparency = 1
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
