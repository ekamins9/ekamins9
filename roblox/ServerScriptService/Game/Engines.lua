--[[ ENGINES — siege engines, archer companies and battle-mages for any team mode: War's, and
     Siege's (the attackers' trebuchets beyond the walls, both sides' archers). Each side fires on
     its own beat; what it fires is drawn on every screen by Engines.client (ReplicatedStorage ▸
     WarEvent) and only ever hurts the other side.

       local e = Engines.new({
           sides = {A = {trebs = {Vector3…}, archers = {Vector3…}, mages = Vector3 | nil}, B = {…}},
           target = function(side) -> Vector3 | nil   where that side's engines aim (nil: they hold
                                                      fire); without it, a knot of enemies anywhere
           beats = {treb = {9, 14}, volley = {12, 18}, barrage = {30, 42}}   seconds between; a
                                                      kind left out never fires
           grace = 20,                                seconds before the first shots
           power = 1,                                 damage × (Siege's are gentler than War's)
           alive = function() -> bool                 still this round?
       })
       e:tick()                                       from the mode's tick
       Engines.knot(side, near, within)               a knot of the side's enemies (the best of a few
                                                      looks); near = a line across z, or a point

     The trebuchet: a red ring where it lands (3.4 s), then the blast: heavy damage and thrown
     back. The volley: anyone in it holding their guard up, or under a roof, is spared. The
     barrage: meteors across the enemy's front, chain lightning onto their fighters, or a frost
     that bites and slows (SpeedMult_Frost).
     WarEvent payloads: "Treb", {side, from, to, t, r} · "Volley", {side, from, to, t, r, n} ·
       "Barrage", {side, kind, from, points, t, step, r} ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Game = require(script.Parent:WaitForChild("Game"))
local Moves = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("BossMoves"))
local RangedServer
local function Ranged() RangedServer = RangedServer or require(ServerScriptService:WaitForChild("Combat"):WaitForChild("RangedServer")); return RangedServer end
local Teams = Game.Teams

local Engines = {}
Engines.__index = Engines

local remote = ReplicatedStorage:FindFirstChild("WarEvent")
if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "WarEvent"; remote.Parent = ReplicatedStorage end
Engines.remote = remote

local ENEMY = {A = "B", B = "A"}
local DANGER = Color3.fromRGB(255, 84, 40)
local ARCANE = Color3.fromRGB(176, 96, 255)
local FROST = Color3.fromRGB(130, 200, 255)
Engines.TREB = {warn = 3.4, radius = 13, damage = 70, knock = 46}
Engines.VOLLEY = {flight = 2.8, radius = 13, damage = 24}

local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
-- "Crown Trebuchet", "Iron Archers": who the feed says did it
function Engines.name(side, what)
	local d = Teams.def(side)
	return (d and d.name or side) .. " " .. what
end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function rnd(a, b) return a + math.random() * (b - a) end

-- a knot of the side's enemies: the best of a few looks (most of them close together, none of
-- the side's own in the way); near a line across z when given
function Engines.knot(side, near, within)
	local foes = {}
	for _, hrp in pairs(Teams.fighters(ENEMY[side])) do
		local p = hrp.Position
		local ok = true
		if typeof(near) == "Vector3" then ok = (flat(p) - flat(near)).Magnitude < (within or 80)
		elseif near then ok = math.abs(p.Z - near) < (within or 110) end
		if ok then table.insert(foes, p) end
	end
	if #foes == 0 then return nil end
	local friends = {}
	for _, hrp in pairs(Teams.fighters(side)) do table.insert(friends, hrp.Position) end
	local best, bestScore
	for _ = 1, 6 do
		local p = foes[math.random(#foes)]
		local score = 0
		for _, q in ipairs(foes) do if (flat(q) - flat(p)).Magnitude < 14 then score += 1 end end
		for _, q in ipairs(friends) do if (flat(q) - flat(p)).Magnitude < 16 then score -= 2 end end
		if score > 0 and (not bestScore or score > bestScore) then best, bestScore = p, score end
	end
	return best and Vector3.new(best.X + rnd(-4, 4), best.Y - 3, best.Z + rnd(-4, 4)) or nil
end

function Engines.new(o)
	local self = setmetatable({}, Engines)
	self.sides = o.sides or {}
	self.target = o.target
	self.beats = o.beats or {treb = {9, 14}, volley = {12, 18}, barrage = {30, 42}}
	self.power = o.power or 1
	self.alive = o.alive or function() return true end
	local now = os.clock()
	local grace = o.grace or 20
	self.next = {}
	for _, side in ipairs({"A", "B"}) do
		local off = side == "B" and 2 or 0
		self.next[side] = {treb = now + grace + off + rnd(0, 4), volley = now + grace + 4 + off + rnd(0, 4), barrage = now + grace + 14 + off * 3 + rnd(0, 8)}
	end
	return self
end

-- hurt the side's enemies within r of a point (fall-off from the middle unless opts.flat);
-- opts.guard: a raised guard or a roof overhead spares you · opts.knock · opts.slow
local roofRay = RaycastParams.new()
roofRay.FilterType = Enum.RaycastFilterType.Exclude
function Engines:hurt(side, at, r, dmg, opts)
	opts = opts or {}
	dmg *= self.power
	for model, hrp in pairs(Teams.fighters(ENEMY[side])) do
		local d = (flat(hrp.Position) - flat(at)).Magnitude
		if d <= r and math.abs(hrp.Position.Y - at.Y) < 12 then
			local hum = humOf(model)
			local safe = false
			if opts.guard then
				if model:GetAttribute("Blocking") == true then
					safe = true
					-- (a shield raised against the volley comes out of it bristling)
					if opts.arrows then
						for _ = 1, math.random(1, 2) do pcall(Ranged().shieldCatch, model, "Arrow") end
					end
				else
					roofRay.FilterDescendantsInstances = {model, workspace:FindFirstChild("NPCs")}
					safe = workspace:Raycast(hrp.Position + Vector3.new(0, 2, 0), Vector3.new(0, 40, 0), roofRay) ~= nil
				end
			end
			if hum and hum.Health > 0 and not safe then
				-- (the feed names the engine: "Crown Trebuchet struck down …")
				if opts.by then
					model:SetAttribute("LastHitBy", 0)
					model:SetAttribute("LastHitByName", opts.by)
					model:SetAttribute("LastHitWith", opts.with or "")
					model:SetAttribute("LastHitByTeam", side)
					model:SetAttribute("LastHitAt", os.clock())
				end
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

-- (a mode's own aim, nil meaning hold fire; without one, a knot of enemies anywhere)
function Engines:aim(side)
	if self.target then return self.target(side) end
	return Engines.knot(side)
end

function Engines:fireTrebuchet(side)
	local arms = self.sides[side] and self.sides[side].trebs
	if not (arms and #arms > 0) then return end
	local to = self:aim(side)
	if not to then return end
	local T = Engines.TREB
	Moves.circle(to, T.radius, DANGER, T.warn)
	remote:FireAllClients("Treb", {side = side, from = arms[math.random(#arms)], to = to, t = T.warn, r = T.radius})
	task.wait(T.warn)
	if self.alive() then self:hurt(side, to, T.radius, T.damage, {knock = T.knock, by = Engines.name(side, "Trebuchet"), with = "Trebuchet"}) end
end

function Engines:fireVolley(side)
	local comps = self.sides[side] and self.sides[side].archers
	if not (comps and #comps > 0) then return end
	local to = self:aim(side)
	if not to then return end
	-- from the company nearest the target
	local from, best = comps[1], math.huge
	for _, c in ipairs(comps) do
		local d = (flat(c) - flat(to)).Magnitude
		if d < best then from, best = c, d end
	end
	local V = Engines.VOLLEY
	remote:FireAllClients("Volley", {side = side, from = from + Vector3.new(0, 6, 0), to = to, t = V.flight, r = V.radius, n = 120})
	task.wait(V.flight)
	if self.alive() then self:hurt(side, to, V.radius, V.damage, {guard = true, arrows = true, flat = true, by = Engines.name(side, "Archers"), with = "Volley"}) end
end

function Engines:fireBarrage(side, frontZ)
	local mages = self.sides[side] and self.sides[side].mages
	if not mages then return end
	local from = mages + Vector3.new(0, 60, 0)
	local kind = ({"meteors", "lightning", "frost"})[math.random(3)]
	if kind == "meteors" then
		-- a line of meteors across the enemy's side of the fight
		local centre = self:aim(side)
		if not centre then return end
		local pts = {}
		for k = 1, 5 do table.insert(pts, Vector3.new(centre.X - 72 + k * 24 + rnd(-6, 6), centre.Y, centre.Z + rnd(-8, 8))) end
		for k, p in ipairs(pts) do Moves.circle(p, 10, ARCANE, 2.6 + k * 0.3) end
		remote:FireAllClients("Barrage", {side = side, kind = kind, from = from, points = pts, t = 2.6, step = 0.3, r = 10})
		for k, p in ipairs(pts) do
			task.delay(2.6 + k * 0.3, function() if self.alive() then self:hurt(side, p, 10, 45, {knock = 34, by = Engines.name(side, "Battle-Mages"), with = "Meteor"}) end end)
		end
	elseif kind == "lightning" then
		-- bolts onto their fighters where they stand
		local foes = {}
		for _, hrp in pairs(Teams.fighters(ENEMY[side])) do
			if not frontZ or math.abs(hrp.Position.Z - frontZ) < 120 then table.insert(foes, hrp.Position) end
		end
		if #foes == 0 then return end
		local pts = {}
		for _ = 1, 6 do
			local p = foes[math.random(#foes)]
			table.insert(pts, Vector3.new(p.X + rnd(-2, 2), p.Y - 3, p.Z + rnd(-2, 2)))
		end
		for k, p in ipairs(pts) do Moves.circle(p, 6, FROST:Lerp(Color3.new(1, 1, 1), 0.5), 1.4 + k * 0.35) end
		remote:FireAllClients("Barrage", {side = side, kind = kind, from = from, points = pts, t = 1.4, step = 0.35, r = 6})
		for k, p in ipairs(pts) do
			task.delay(1.4 + k * 0.35, function() if self.alive() then self:hurt(side, p, 6, 35, {flat = true, by = Engines.name(side, "Battle-Mages"), with = "Lightning"}) end end)
		end
	else
		-- a frost over a knot of them: it bites and slows
		local to = self:aim(side)
		if not to then return end
		Moves.circle(to, 18, FROST, 1.8)
		remote:FireAllClients("Barrage", {side = side, kind = kind, from = from, points = {to}, t = 1.8, step = 0, r = 18})
		task.wait(1.8)
		if self.alive() then self:hurt(side, to, 18, 12, {flat = true, slow = 0.55, by = Engines.name(side, "Battle-Mages"), with = "Frost"}) end
	end
end

-- each side on its own beat
function Engines:tick(frontZ)
	local now = os.clock()
	for _, side in ipairs({"A", "B"}) do
		local n = self.next[side]
		local b = self.beats
		if b.treb and now >= n.treb then n.treb = now + rnd(b.treb[1], b.treb[2]); task.spawn(self.fireTrebuchet, self, side) end
		if b.volley and now >= n.volley then n.volley = now + rnd(b.volley[1], b.volley[2]); task.spawn(self.fireVolley, self, side) end
		if b.barrage and now >= n.barrage then n.barrage = now + rnd(b.barrage[1], b.barrage[2]); task.spawn(self.fireBarrage, self, side, frontZ) end
	end
end

return Engines
