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
     THE BALLISTAE: two a side behind its second banner, for its players: hold E and it swings onto
     the nearest knot of enemies in front of it and looses a bolt that goes through up to three of
     them (yours the kills); six seconds to wind again.
     THE ENGINES, each side on its own beat once the round is under way:
       • TREBUCHETS (two a side): a red ring where the shot will land, then the blast; the
         engine's enemies in it are hurt badly and thrown back
       • ARCHERS (a company on each flank): a volley into a knot of enemies; anyone in it not
         holding their guard up or under a roof is hit
       • BATTLE-MAGES: now and then a barrage: meteors across the enemy's front, lightning onto
         their fighters, or a frost that slows them
     The engines are Game ▸ Engines' (drawn by Engines.client). Remote: ReplicatedStorage ▸
     WarEvent (server → clients): Engines' "Treb" · "Volley" · "Barrage", and War's own
       "Captured", {id, side, lost} · "Charge", {side, lane}
     Round attributes: WarBanner1…5 ("A" | "B" | ""), WarProg1…5 (−1 Iron … +1 Crown), WarCount1…5
       ("a:b", fighters at each), WarTicketsA/B, WarTickets (the start), WarFront (the z the sides meet). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Game = require(script.Parent.Parent:WaitForChild("Game"))
local WarMap = require(script.Parent.Parent:WaitForChild("WarMap"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local Engines = require(script.Parent.Parent:WaitForChild("Engines"))
local Teams, MapLoader = Game.Teams, Game.MapLoader
local node = Game.node

local War = setmetatable({}, {__index = Game.Mode})
War.__index = War
function War.new(def, id) return setmetatable(Game.Mode.new(def, id), War) end

local remote = Engines.remote   -- (ReplicatedStorage ▸ WarEvent: the engines' shots, and War's own news)

local ENEMY = {A = "B", B = "A"}
local CFG = {
	capture = 9,              -- seconds for one fighter to swing a banner from one side to the other's
	most = 3,                 -- fighters past the enemy's that still make it faster
	bleed = 4,                -- seconds between bleeds
	grace = 20,               -- the engines hold off this long into a round (Game ▸ Engines)
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
	self.chargeAt = {A = now + 8, B = now + 16}
	local L = self.layout
	self.engines = Engines.new({
		sides = {A = {trebs = L.trebuchets.A, archers = L.archers.A, mages = L.mages.A}, B = {trebs = L.trebuchets.B, archers = L.archers.B, mages = L.mages.B}},
		target = function(side) return self:targetFor(side) end,
		grace = CFG.grace,
		alive = function() return Game.current == self end,
	})
	self.botCap = def.botFill or 32
	self.frame = 1 / 60
	self.capAt = now + 6
	self.lastFront = nil
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("OwnTop", true)
	node:SetAttribute("ObjKind", "War")
	node:SetAttribute("WarTickets", t0)
	self.beat = RunService.Heartbeat:Connect(function(dt) self.frame = self.frame * 0.97 + math.min(dt, 0.2) * 0.03 end)
	self:rigBallistae()
	self:publishScores()
end

function War:stop()
	if self.beat then self.beat:Disconnect(); self.beat = nil end
	self.engines = nil
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
	-- THE ENGINES (Game ▸ Engines), and now and then a cavalry charge up a flank
	if self.engines then self.engines:tick(fz) end
	for _, side in ipairs({"A", "B"}) do
		if now >= self.chargeAt[side] then
			self.chargeAt[side] = now + rnd(CFG.charge[1], CFG.charge[2])
			remote:FireAllClients("Charge", {side = side, lane = math.random() < 0.5 and -1 or 1})
		end
	end
	-- THE BOTS FOLLOW THE SERVER'S BREATH
	if now >= self.capAt then
		self.capAt = now + 5
		local most = self.def.botFill or 32
		if self.frame > CFG.slow then self.botCap = math.max(CFG.least, self.botCap - 4)
		elseif self.frame < CFG.quick and self.botCap < most then self.botCap = math.min(most, self.botCap + 2) end
	end
end

function War:captured(i, side, lost)
	self.owner[i] = side
	remote:FireAllClients("Captured", {id = i, side = side, lost = lost})
	-- (everyone of the side standing at it when it fell is paid for it: Catalog ▸ Economy war_banner)
	local b = side and self.layout and self.layout.banners[i]
	if b and _G.RoundBump then
		for model, hrp in pairs(Teams.fighters(side)) do
			local plr = Players:GetPlayerFromCharacter(model)
			if plr and (flat(hrp.Position) - flat(b.pos)).Magnitude <= self.layout.radius + 2 then _G.RoundBump(plr, "war_banner") end
		end
	end
end

--------------------------------------------------------------------
--  WHERE THE ENGINES AIM: a knot of enemies near the front, or the banner they're fighting at
--------------------------------------------------------------------
function War:targetFor(side)
	local p = Engines.knot(side, self:frontZ(), 110)
	if p then return p end
	local L = self.layout
	local b = L and L.banners[self:frontFor(ENEMY[side])]
	return b and (b.pos + Vector3.new(rnd(-12, 12), 0, rnd(-12, 12))) or nil
end

--------------------------------------------------------------------
--  THE BALLISTAE players man
--------------------------------------------------------------------
local BALLISTA = {reload = 6, range = 260, arc = 0.35, pierce = 3, damage = {85, 70, 55}, width = 3.5}
function War:rigBallistae()
	self.ballistae = {}
	for _, b in ipairs(self.layout and self.layout.ballistae or {}) do
		local m = b.model
		if m and m.Parent then
			local holder = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
			local pr = Instance.new("ProximityPrompt")
			pr.ActionText, pr.ObjectText = "Loose", "Ballista"
			pr.KeyboardKeyCode = Enum.KeyCode.E
			pr.HoldDuration = 0.25
			pr.MaxActivationDistance = 11
			pr.RequiresLineOfSight = false
			-- (its own side's only; winding: nobody's · Prompts.client)
			pr:SetAttribute("Team", b.side)
			pr:SetAttribute("Ready", true)
			pr.Parent = holder
			local e = {model = m, side = b.side, prompt = pr, readyAt = 0, home = m:GetPivot()}
			pr.Triggered:Connect(function(plr) self:looseBallista(e, plr) end)
			table.insert(self.ballistae, e)
		end
	end
end

function War:looseBallista(e, plr)
	if Game.current ~= self or os.clock() < e.readyAt then return end
	if Teams.keyOf(plr) ~= e.side then return end
	local char = plr.Character
	local hum = humOf(char)
	if not (hum and hum.Health > 0) then return end
	e.readyAt = os.clock() + BALLISTA.reload
	e.prompt:SetAttribute("Ready", false)
	local f = e.side == "A" and 1 or -1
	local from = e.home.Position + Vector3.new(0, 4, 0)
	local ahead = Vector3.new(0, 0, f)
	-- the nearest knot of enemies in front of it (else straight down the field)
	local best, bestD
	for _, hrp in pairs(Teams.fighters(ENEMY[e.side])) do
		local to = hrp.Position - from
		local d = to.Magnitude
		if d < BALLISTA.range and d > 4 and flat(to).Unit:Dot(ahead) > BALLISTA.arc and (not bestD or d < bestD) then best, bestD = hrp.Position, d end
	end
	local aim = best and (best - from).Unit or (ahead + Vector3.new(0, 0.02, 0)).Unit
	-- it swings onto them
	-- (turned the way it's aiming: its home pivot already faces the enemy, so turn by the difference)
	local yaw = math.atan2(-aim.X, -aim.Z) - math.atan2(-ahead.X, -ahead.Z)
	pcall(function() e.model:PivotTo(e.home * CFrame.Angles(0, yaw, 0)) end)
	local L = BALLISTA.range
	local to = from + aim * L
	-- who's in the bolt's way: the first few along its line
	local hits = {}
	for model, hrp in pairs(Teams.fighters(ENEMY[e.side])) do
		local rel = hrp.Position - from
		local along = rel:Dot(aim)
		if along > 0 and along < L then
			local off = (rel - aim * along).Magnitude
			if off < BALLISTA.width then table.insert(hits, {model = model, hrp = hrp, along = along}) end
		end
	end
	table.sort(hits, function(x, y) return x.along < y.along end)
	if #hits >= BALLISTA.pierce then to = from + aim * (hits[BALLISTA.pierce].along + 6) end
	local flight = math.clamp((to - from).Magnitude / 220, 0.15, 1.2)
	remote:FireAllClients("Bolt", {side = e.side, from = from, to = to, t = flight})
	task.delay(flight * 0.5, function()
		for k, h in ipairs(hits) do
			if k > BALLISTA.pierce then break end
			local victim = humOf(h.model)
			if victim and victim.Health > 0 then
				h.model:SetAttribute("LastHitBy", plr.UserId)
				h.model:SetAttribute("LastHitByName", plr.DisplayName)
				h.model:SetAttribute("LastHitWith", "Ballista")
				h.model:SetAttribute("LastHitByTeam", e.side)
				h.model:SetAttribute("LastHitAt", os.clock())
				victim:TakeDamage(BALLISTA.damage[k])
				h.hrp.AssemblyLinearVelocity = aim * 40 + Vector3.new(0, 22, 0)
			end
		end
	end)
	task.delay(BALLISTA.reload, function()
		if Game.current ~= self then return end
		e.prompt:SetAttribute("Ready", true)
		pcall(function() e.model:PivotTo(e.home) end)
	end)
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
