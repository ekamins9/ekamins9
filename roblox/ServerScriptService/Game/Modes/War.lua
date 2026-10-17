--[[ WAR — the big battle (GameConfig.MODES.War, DOORS.War): two armies on a battlefield built fresh
     each round (Game ▸ WarMap), players and bots side by side, siege engines, archers and
     battle-mages, and the rest of each army clashing out on the flanks (War.client draws them).

     THE LINE: five banners between the camps. A side takes a banner by standing at it with more of
     its own than the enemy (up to three more count: faster together), but only a banner next to its
     line (its first, or one beside a banner it holds), so the fight moves along the field as a front.
     REINFORCEMENTS: each side starts with `tickets` (GameConfig); every fall costs one, players and
     bots alike; a side holding more banners bleeds the other a ticket per banner more every few
     seconds. At none, that side has lost; at the bell, more left wins.
     YOU COME IN at your foremost banner that isn't under attack, else at your camp (in waves).
     THE BOTS (Game ▸ BotFill, fillAnywhere): most push for the banner their side is taking, some
     hold one under attack; how many there are follows the server's frame rate (botTarget).
     THE ENGINES, each side on its own beat once the round is under way:
       • TREBUCHETS (two a side): a red ring where the shot will land, then the blast; the
         engine's enemies in it are hurt badly and thrown back
       • ARCHERS (a company on each flank): a volley into a knot of enemies; anyone in it not
         holding their guard up or under a roof is hit
       • BATTLE-MAGES: now and then a barrage: meteors across the enemy's front, lightning onto
         their fighters, or a frost that slows them
     Remote: ReplicatedStorage ▸ WarEvent (server → clients):
       "Treb", {side, from, to, t, r} · "Volley", {side, from, to, t, r, n} ·
       "Barrage", {side, kind, from, points, t, r} · "Captured", {id, side, lost} · "Charge", {side, lane}
     Round attributes: WarBanner1…5 ("A" | "B" | ""), WarProg1…5 (−1 Iron … +1 Crown), WarCount1…5
       ("a:b", fighters at each), WarTicketsA/B, WarTickets (the start), WarFront (the z the sides meet). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Game = require(script.Parent.Parent:WaitForChild("Game"))
local WarMap = require(script.Parent.Parent:WaitForChild("WarMap"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local Moves = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("BossMoves"))
local Teams, MapLoader = Game.Teams, Game.MapLoader
local node = Game.node

local War = setmetatable({}, {__index = Game.Mode})
War.__index = War
function War.new(def, id) return setmetatable(Game.Mode.new(def, id), War) end

local remote = ReplicatedStorage:FindFirstChild("WarEvent")
if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "WarEvent"; remote.Parent = ReplicatedStorage end

local ENEMY = {A = "B", B = "A"}
local DANGER = Color3.fromRGB(255, 84, 40)
local ARCANE = Color3.fromRGB(176, 96, 255)
local FROST = Color3.fromRGB(130, 200, 255)
local CFG = {
	capture = 9,              -- seconds for one fighter to swing a banner from one side to the other's
	most = 3,                 -- fighters past the enemy's that still make it faster
	bleed = 4,                -- seconds between bleeds
	grace = 20,               -- the engines hold off this long into a round
	treb = {9, 14}, trebWarn = 3.4, trebRadius = 13, trebDamage = 70,
	volley = {12, 18}, volleyFlight = 2.8, volleyRadius = 13, volleyDamage = 24,
	barrage = {30, 42},
	charge = {55, 80},
	-- the server's breath: fewer bots when its frames run long
	slow = 1 / 38, quick = 1 / 54, least = 10,
}
local FIELD_ATTRS = {"OwnHud", "OwnTop", "ObjKind", "WarFront", "WarTicketsA", "WarTicketsB", "WarTickets"}

local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function rnd(a, b) return a + math.random() * (b - a) end

--------------------------------------------------------------------
--  THE FIELD
--------------------------------------------------------------------
function War:buildMap(theme)
	local name, layout = WarMap.build(theme)
	self.layout = layout
	Dungeon.sweep(name)
	return name
end

function War:start(map)
	Game.Mode.start(self, map)
	if not self.layout then
		local name = self:buildMap(map)
		MapLoader.load(name)
	end
	local now = os.clock()
	local def = self.def
	local t0 = def.tickets or 300
	self.tickets = {A = t0, B = t0}
	self.owner = {"A", "A", nil, "B", "B"}     -- the opening line: each side holds its two nearest
	self.prog = {1, 1, 0, -1, -1}
	self.counts = {}
	self.bleedAt = now + CFG.bleed
	self.engines = {}
	for _, side in ipairs({"A", "B"}) do
		local off = side == "B" and 2 or 0
		self.engines[side] = {treb = now + CFG.grace + off + rnd(0, 4), volley = now + CFG.grace + 4 + off + rnd(0, 4),
			barrage = now + CFG.grace + 14 + off * 3 + rnd(0, 8), charge = now + 8 + off * 4}
	end
	self.botCap = def.botFill or 36
	self.frame = 1 / 60
	self.capAt = now + 6
	self.lastFront = nil
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("OwnTop", true)
	node:SetAttribute("ObjKind", "War")
	node:SetAttribute("WarTickets", t0)
	self.beat = RunService.Heartbeat:Connect(function(dt) self.frame = self.frame * 0.97 + math.min(dt, 0.2) * 0.03 end)
	self:publishScores()
end

function War:stop()
	if self.beat then self.beat:Disconnect(); self.beat = nil end
	for _, k in ipairs(FIELD_ATTRS) do node:SetAttribute(k, nil) end
	for i = 1, 5 do
		for _, k in ipairs({"WarBanner", "WarProg", "WarCount"}) do node:SetAttribute(k .. i, nil) end
	end
	self.layout = nil
end

-- may this side take banner i? (its own, its first, or one beside a banner it holds)
function War:canTake(side, i)
	if self.owner[i] == side then return true end
	if side == "A" then return i == 1 or self.owner[i - 1] == "A" end
	return i == 5 or self.owner[i + 1] == "B"
end

-- the banner each side is fighting for now (the first one from its end it doesn't hold)
function War:frontFor(side)
	if side == "A" then
		for i = 1, 5 do if self.owner[i] ~= "A" then return i end end
		return 5
	end
	for i = 5, 1, -1 do if self.owner[i] ~= "B" then return i end end
	return 1
end

-- the z where the sides meet: between the foremost banners each holds
function War:frontZ()
	local L = self.layout
	if not L then return 0 end
	local aMax, bMin = 0, 6
	for i = 1, 5 do
		if self.owner[i] == "A" then aMax = math.max(aMax, i) end
		if self.owner[i] == "B" then bMin = math.min(bMin, i) end
	end
	local za = aMax > 0 and L.banners[aMax].pos.Z or -L.bounds.z
	local zb = bMin < 6 and L.banners[bMin].pos.Z or L.bounds.z
	return (za + zb) / 2
end

function War:tick(dt)
	local L = self.layout
	if not L then return end
	local now = os.clock()
	-- WHO STANDS AT EACH BANNER
	local counts = {}
	for i = 1, 5 do counts[i] = {A = 0, B = 0} end
	local r = L.radius
	for _, side in ipairs({"A", "B"}) do
		for _, hrp in pairs(Teams.fighters(side)) do
			local p = hrp.Position
			for i, b in ipairs(L.banners) do
				if math.abs(p.Z - b.pos.Z) <= r and (flat(p) - flat(b.pos)).Magnitude <= r and math.abs(p.Y - b.pos.Y) < 16 then
					counts[i][side] += 1
				end
			end
		end
	end
	self.counts = counts
	-- THE BANNERS SWING
	for i = 1, 5 do
		local a, b = counts[i].A, counts[i].B
		local push = 0
		if a > b and self:canTake("A", i) then push = math.min(a - b, CFG.most)
		elseif b > a and self:canTake("B", i) then push = -math.min(b - a, CFG.most) end
		local p = self.prog[i]
		if push ~= 0 then
			local rate = 2 / CFG.capture * (1 + 0.5 * (math.abs(push) - 1))
			p = math.clamp(p + (push > 0 and 1 or -1) * rate * dt, -1, 1)
		elseif a == 0 and b == 0 and self.owner[i] then
			-- left alone, a banner settles back to its holder
			p = math.clamp(p + (self.owner[i] == "A" and 1 or -1) * 0.04 * dt, -1, 1)
		end
		self.prog[i] = p
		local was = self.owner[i]
		if p >= 1 and was ~= "A" then self:captured(i, "A")
		elseif p <= -1 and was ~= "B" then self:captured(i, "B")
		elseif was == "A" and p <= 0 then self:captured(i, nil, "A")
		elseif was == "B" and p >= 0 then self:captured(i, nil, "B") end
		-- (published only when it moved enough to see)
		local shown = node:GetAttribute("WarProg" .. i)
		if not shown or math.abs(shown - p) >= 0.02 or (p == 1 or p == -1) and shown ~= p then node:SetAttribute("WarProg" .. i, math.floor(p * 100 + 0.5) / 100) end
		local c = a .. ":" .. b
		if node:GetAttribute("WarCount" .. i) ~= c then node:SetAttribute("WarCount" .. i, c) end
		local o = self.owner[i] or ""
		if node:GetAttribute("WarBanner" .. i) ~= o then node:SetAttribute("WarBanner" .. i, o) end
	end
	local fz = self:frontZ()
	if not self.lastFront or math.abs(fz - self.lastFront) > 0.5 then self.lastFront = fz; node:SetAttribute("WarFront", fz) end
	-- THE BLEED: holding more banners wears the other side down
	if now >= self.bleedAt then
		self.bleedAt = now + CFG.bleed
		local ha, hb = 0, 0
		for i = 1, 5 do if self.owner[i] == "A" then ha += 1 elseif self.owner[i] == "B" then hb += 1 end end
		if ha > hb then self.tickets.B -= (ha - hb) + (ha == 5 and 3 or 0) end
		if hb > ha then self.tickets.A -= (hb - ha) + (hb == 5 and 3 or 0) end
		self:publishScores()
	end
	-- THE ENGINES
	if now - (self.startedAt or now) > CFG.grace then
		for _, side in ipairs({"A", "B"}) do
			local e = self.engines[side]
			if now >= e.treb then e.treb = now + rnd(CFG.treb[1], CFG.treb[2]); task.spawn(self.fireTrebuchet, self, side) end
			if now >= e.volley then e.volley = now + rnd(CFG.volley[1], CFG.volley[2]); task.spawn(self.fireVolley, self, side) end
			if now >= e.barrage then e.barrage = now + rnd(CFG.barrage[1], CFG.barrage[2]); task.spawn(self.fireBarrage, self, side) end
		end
	end
	for _, side in ipairs({"A", "B"}) do
		local e = self.engines[side]
		if now >= e.charge then
			e.charge = now + rnd(CFG.charge[1], CFG.charge[2])
			remote:FireAllClients("Charge", {side = side, lane = math.random() < 0.5 and -1 or 1})
		end
	end
	-- THE BOTS FOLLOW THE SERVER'S BREATH
	if now >= self.capAt then
		self.capAt = now + 5
		local most = self.def.botFill or 36
		if self.frame > CFG.slow then self.botCap = math.max(CFG.least, self.botCap - 4)
		elseif self.frame < CFG.quick and self.botCap < most then self.botCap = math.min(most, self.botCap + 2) end
	end
end

function War:captured(i, side, lost)
	self.owner[i] = side
	remote:FireAllClients("Captured", {id = i, side = side, lost = lost})
end

--------------------------------------------------------------------
--  THE ENGINES
--------------------------------------------------------------------
-- a knot of enemies near the front (the best of a few looks), or the banner they're fighting at
function War:targetFor(side)
	local foes = {}
	for _, hrp in pairs(Teams.fighters(ENEMY[side])) do table.insert(foes, hrp.Position) end
	local friends = {}
	for _, hrp in pairs(Teams.fighters(side)) do table.insert(friends, hrp.Position) end
	local fz = self:frontZ()
	local best, bestScore
	for _ = 1, 6 do
		local p = foes[math.random(math.max(#foes, 1))]
		if p and math.abs(p.Z - fz) < 110 then
			local score = 0
			for _, q in ipairs(foes) do if (flat(q) - flat(p)).Magnitude < 14 then score += 1 end end
			for _, q in ipairs(friends) do if (flat(q) - flat(p)).Magnitude < 16 then score -= 2 end end
			if score > 0 and (not bestScore or score > bestScore) then best, bestScore = p, score end
		end
	end
	if best then return Vector3.new(best.X + rnd(-4, 4), best.Y - 3, best.Z + rnd(-4, 4)) end
	-- nobody to aim at: the enemy's banner at the front
	local L = self.layout
	local i = self:frontFor(ENEMY[side])
	local b = L and L.banners[i]
	return b and (b.pos + Vector3.new(rnd(-12, 12), 0, rnd(-12, 12))) or nil
end

-- hurt the side's enemies within r of a point (fall-off from the middle); opts.guard: a raised
-- guard or a roof overhead saves you; opts.knock; opts.slow
local roofRay = RaycastParams.new()
roofRay.FilterType = Enum.RaycastFilterType.Exclude
function War:hurt(side, at, r, dmg, opts)
	opts = opts or {}
	local L = self.layout
	if not L then return end
	for model, hrp in pairs(Teams.fighters(ENEMY[side])) do
		local d = (flat(hrp.Position) - flat(at)).Magnitude
		if d <= r and math.abs(hrp.Position.Y - at.Y) < 12 then
			local hum = humOf(model)
			local safe = false
			if opts.guard then
				if model:GetAttribute("Blocking") == true then safe = true
				else
					roofRay.FilterDescendantsInstances = {model, workspace:FindFirstChild("NPCs")}
					safe = workspace:Raycast(hrp.Position + Vector3.new(0, 2, 0), Vector3.new(0, 40, 0), roofRay) ~= nil
				end
			end
			if hum and hum.Health > 0 and not safe then
				hum:TakeDamage(dmg * (opts.flat and 1 or (1 - 0.55 * d / r)))
				if opts.knock then
					local away = flat(hrp.Position - at)
					away = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, 1)
					hrp.AssemblyLinearVelocity = away * opts.knock + Vector3.new(0, opts.knock * 0.7, 0)
				end
				if opts.slow then
					model:SetAttribute("SpeedMult_Frost", opts.slow)
					task.delay(4, function() if model.Parent then model:SetAttribute("SpeedMult_Frost", nil) end end)
				end
			end
		end
	end
end

function War:fireTrebuchet(side)
	local L = self.layout
	local to = self:targetFor(side)
	if not (L and to) then return end
	local arms = L.trebuchets[side]
	local from = arms[math.random(#arms)]
	local t, r = CFG.trebWarn, CFG.trebRadius
	Moves.circle(to, r, DANGER, t)
	remote:FireAllClients("Treb", {side = side, from = from, to = to, t = t, r = r})
	task.wait(t)
	if Game.current ~= self then return end
	self:hurt(side, to, r, CFG.trebDamage, {knock = 46})
end

function War:fireVolley(side)
	local L = self.layout
	local to = self:targetFor(side)
	if not (L and to) then return end
	-- from the company on the flank nearer the target
	local comps = L.archers[side]
	local from = comps[to.X < 0 and 1 or 2] + Vector3.new(0, 6, 0)
	local t, r = CFG.volleyFlight, CFG.volleyRadius
	remote:FireAllClients("Volley", {side = side, from = from, to = to, t = t, r = r, n = 70})
	task.wait(t)
	if Game.current ~= self then return end
	self:hurt(side, to, r, CFG.volleyDamage, {guard = true, flat = true})
end

function War:fireBarrage(side)
	local L = self.layout
	if not L then return end
	local from = L.mages[side] + Vector3.new(0, 60, 0)
	local kind = ({"meteors", "lightning", "frost"})[math.random(3)]
	if kind == "meteors" then
		-- a line of meteors across the enemy's side of the front
		local fz = self:frontZ() + (side == "A" and 1 or -1) * rnd(8, 26)
		local pts = {}
		for k = 1, 5 do table.insert(pts, Vector3.new(-72 + k * 24 + rnd(-6, 6), 0, fz + rnd(-8, 8))) end
		for k, p in ipairs(pts) do Moves.circle(p, 10, ARCANE, 2.6 + k * 0.3) end
		remote:FireAllClients("Barrage", {side = side, kind = kind, from = from, points = pts, t = 2.6, step = 0.3, r = 10})
		for k, p in ipairs(pts) do
			task.delay(2.6 + k * 0.3, function() if Game.current == self then self:hurt(side, p, 10, 45, {knock = 34}) end end)
		end
	elseif kind == "lightning" then
		-- bolts onto their fighters where they stand
		local pts = {}
		local foes = {}
		for _, hrp in pairs(Teams.fighters(ENEMY[side])) do
			if math.abs(hrp.Position.Z - self:frontZ()) < 120 then table.insert(foes, hrp.Position) end
		end
		for _ = 1, 6 do
			local p = foes[math.random(math.max(#foes, 1))]
			if p then table.insert(pts, Vector3.new(p.X + rnd(-2, 2), p.Y - 3, p.Z + rnd(-2, 2))) end
		end
		if #pts == 0 then return end
		for k, p in ipairs(pts) do Moves.circle(p, 6, FROST:Lerp(Color3.new(1, 1, 1), 0.5), 1.4 + k * 0.35) end
		remote:FireAllClients("Barrage", {side = side, kind = kind, from = from, points = pts, t = 1.4, step = 0.35, r = 6})
		for k, p in ipairs(pts) do
			task.delay(1.4 + k * 0.35, function() if Game.current == self then self:hurt(side, p, 6, 35, {flat = true}) end end)
		end
	else
		-- a frost over a knot of them: it bites and slows
		local to = self:targetFor(side)
		if not to then return end
		Moves.circle(to, 18, FROST, 1.8)
		remote:FireAllClients("Barrage", {side = side, kind = kind, from = from, points = {to}, t = 1.8, step = 0, r = 18})
		task.wait(1.8)
		if Game.current == self then self:hurt(side, to, 18, 12, {flat = true, slow = 0.55}) end
	end
end

--------------------------------------------------------------------
--  FIGHTERS: where they come in, where the bots go
--------------------------------------------------------------------
function War:spawnCFrame(plr)
	local L = self.layout
	local side = Teams.keyOf(plr)
	if not (L and side) then return Game.Mode.spawnCFrame(self, plr) end
	local f = side == "A" and 1 or -1           -- which way the enemy is
	-- the foremost banner of ours nobody's attacking
	local at
	local order = side == "A" and {5, 4, 3, 2, 1} or {1, 2, 3, 4, 5}
	for _, i in ipairs(order) do
		local c = self.counts[i]
		if self.owner[i] == side and not (c and c[ENEMY[side]] > 0) and math.abs(self.prog[i]) >= 0.99 then
			at = L.banners[i].pos - Vector3.new(0, 0, f * 16)
			break
		end
	end
	at = at or (L.camps[side] + Vector3.new(0, 0, f * 4))
	local p = at + Vector3.new(rnd(-12, 12), 3, rnd(-5, 5))
	return CFrame.lookAt(p, p + Vector3.new(0, 0, f))
end

function War:botTarget() return self.botCap end

-- the bots' say: head for the front (most), or hold a banner under attack (some)
function War:botOpts(opts)
	local side = opts.team
	if not side then return end
	opts.corpseTime = 4
	local role = math.random() < 0.28 and "hold" or "push"
	local off = Vector3.new(rnd(-12, 12), 0, rnd(-10, 10))
	opts.goal = function()
		local L = self.layout
		if not L then return nil end
		if role == "hold" then
			for i = 1, 5 do
				local c = self.counts[i]
				if self.owner[i] == side and c and c[ENEMY[side]] > 0 then return L.banners[i].pos + off end
			end
		end
		return L.banners[self:frontFor(side)].pos + off
	end
end

--------------------------------------------------------------------
--  THE COUNT
--------------------------------------------------------------------
function War:onDeath(victimPlr)
	local side = victimPlr and Teams.keyOf(victimPlr)
	if side and self.tickets then self.tickets[side] -= 1 end
end
function War:onBotDeath(side)
	if side and self.tickets and self.tickets[side] then self.tickets[side] -= 1 end
end
function War:publishScores()
	local t = self.tickets or {A = 0, B = 0}
	self.scores = {A = math.max(t.A, 0), B = math.max(t.B, 0)}
	node:SetAttribute("WarTicketsA", self.scores.A)
	node:SetAttribute("WarTicketsB", self.scores.B)
	node:SetAttribute("ScoreA", self.scores.A)
	node:SetAttribute("ScoreB", self.scores.B)
	node:SetAttribute("Objective", self:objective())
end
function War:objective()
	local held = {A = 0, B = 0}
	for i = 1, 5 do local o = self.owner and self.owner[i]; if o then held[o] += 1 end end
	return string.format("WAR  ·  %s %d  ·  %d %s", string.upper(Teams.def("A").name), held.A, held.B, string.upper(Teams.def("B").name))
end
function War:isOver()
	if not self.tickets then return nil end
	if self.tickets.A <= 0 then return self:teamResult("B") end
	if self.tickets.B <= 0 then return self:teamResult("A") end
	return nil
end
function War:result()
	local t = self.tickets or {A = 0, B = 0}
	if t.A == t.B then return self:teamResult(nil) end
	return self:teamResult(t.A > t.B and "A" or "B")
end

return War
