--[[ SHADE — what comes for a party that lingers in The Depths (Modes ▸ Depths). A floor's time
     away from a fight is counted (a fight's own time and the stairs' countdown never are). Past
     the floor's patience (Shade.PATIENCE) the torches gutter all over the floor and something far
     off draws breath: THE DARK STIRS. Shade.WARN seconds later THE SHADE comes, a tall hooded
     thing, faceless but for two pale eyes, drifting through the walls straight at the nearest of
     you. It can't be fought (blades pass through it). It starts slower than a walk and gains a
     little every half minute, never as quick as a sprint. Its touch is cold (Shade.TOUCH, armour
     takes some of it); then it falls back into the dark a few breaths before it comes on again.
     It won't come into a room you're fighting in: it waits outside its walls, watching, until the
     fight is done. It goes when you take the stairs down, or when the run ends.

     For every screen, on the Round node (StarterPlayerScripts ▸ Shade.client draws it;
     TorchFlicker gutters the lights round it):
       ShadeState   "stir" | "hunt" | "wait" | "back" | nil
       ShadePos     where it is (a Vector3, ~12 times a second)
       ShadeHit     a counter, one more each touch; ShadeHitPos where

     Deadvault calls it in for its last minutes instead (`manual`: no counting, `shade:stir()` at
     the time it chooses): it hunts whoever is still inside as the dungeon comes down.

     Shade.new(node, banner, words?) -> shade   words = {stir = sub, hunt = sub}: the banners' lines
       shade:tick(dt, ctx)   from the mode's tick: ctx = {floor, fighting = the room being fought
                             or nil, calm = true while the stairs count down or the run is won,
                             layout, manual = true: only shade:stir() begins it, near = studs:
                             it rises in the room nearest that far from you, not the farthest)
       shade:stir()          the dark stirs now (if it hasn't)
       shade:reset()         a new floor: it's gone and the count starts again
       shade:stop()          the run is over ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatServer = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatServer"))

local V3 = Vector3.new

local Shade = {}
Shade.__index = Shade

Shade.PATIENCE = {300, 260, 220}   -- seconds away from a fight on floors 1, 2, 3 before it stirs
Shade.WARN = 40                    -- …and from the stirring to its coming
Shade.SPEED = {7, 11, 0.6}         -- studs/s at first, at most, and the gain each half minute
Shade.TOUCH = 30                   -- its touch (halved by armour as a trap's is)
Shade.REACH = 3.4                  -- how near is a touch
Shade.BACK = 5                     -- seconds it falls back after a touch
Shade.MARGIN = 5                   -- how far outside a fought room's walls it waits

local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function flat(v) return V3(v.X, 0, v.Z) end

local function living()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h, r = humOf(c), rootOf(c)
		if h and r and h.Health > 0 then table.insert(out, {plr = p, char = c, root = r}) end
	end
	return out
end

local function inside(room, p, m)
	return math.abs(p.X - room.cx) < room.w / 2 + (m or 0) and math.abs(p.Z - room.cz) < room.d / 2 + (m or 0)
end

-- the nearest point to p on the ring just outside a room's walls (p itself if it's already out)
local function outside(room, p, m)
	local hw, hd = room.w / 2 + m, room.d / 2 + m
	local x, z = p.X - room.cx, p.Z - room.cz
	if math.abs(x) >= hw or math.abs(z) >= hd then return p, false end
	if hw - math.abs(x) < hd - math.abs(z) then x = (x >= 0 and 1 or -1) * hw else z = (z >= 0 and 1 or -1) * hd end
	return V3(room.cx + x, p.Y, room.cz + z), true
end

function Shade.new(node, banner, words)
	local self = setmetatable({node = node, banner = banner, words = words or {}}, Shade)
	self:reset()
	return self
end

function Shade:publish(state)
	if self.state == state then return end
	self.state = state
	self.node:SetAttribute("ShadeState", state)
end

function Shade:reset()
	if self.conn then self.conn:Disconnect(); self.conn = nil end
	self.idle, self.stirAt, self.huntAt, self.backUntil, self.pos = 0, nil, nil, nil, nil
	self.ctx = nil
	self:publish(nil)
	self.node:SetAttribute("ShadePos", nil)
end

function Shade:stop()
	self:reset()
	self.node:SetAttribute("ShadeHit", nil)
	self.node:SetAttribute("ShadeHitPos", nil)
end

-- where it comes from: the room farthest from all of you (or, given `want`, the one nearest
-- that far from the nearest of you: a raid's dungeon is too big to cross in its last minutes)
function Shade:origin(layout, list, want)
	local best, bd = nil, -math.huge
	for _, rm in ipairs(layout and layout.rooms or {}) do
		local near = math.huge
		for _, l in ipairs(list) do near = math.min(near, (flat(l.root.Position) - V3(rm.cx, 0, rm.cz)).Magnitude) end
		local score = want and -math.abs(near - want) or near
		if score > bd then best, bd = rm, score end
	end
	local y = (list[1] and list[1].root.Position.Y or 3) + 1.5
	return best and V3(best.cx, y, best.cz) or (list[1] and list[1].root.Position + V3(60, 1.5, 0)) or V3(0, y, 0)
end

function Shade:stir()
	if self.stirAt then return end
	self.stirAt = os.clock()
	self:publish("stir")
	if self.banner then self.banner({text = "THE DARK STIRS", sub = self.words.stir or "SOMETHING HAS NOTICED YOU LINGER  ·  KEEP MOVING", kind = "fight"}) end
end

function Shade:tick(dt, ctx)
	self.ctx = ctx
	if ctx.calm then
		if self.state then self:reset() end
		return
	end
	local now = os.clock()
	if not self.stirAt then
		if ctx.manual then return end
		if not ctx.fighting then self.idle += dt end
		local patience = Shade.PATIENCE[math.clamp(ctx.floor or 1, 1, #Shade.PATIENCE)]
		if self.idle >= patience then self:stir() end
		return
	end
	if not self.huntAt and now - self.stirAt >= Shade.WARN then
		local list = living()
		if #list == 0 then return end
		self.huntAt = now
		self.pos = self:origin(ctx.layout, list, ctx.near)
		self.node:SetAttribute("ShadePos", self.pos)
		self:publish("hunt")
		if self.banner then self.banner({text = "THE SHADE COMES", sub = self.words.hunt or "IT CANNOT BE FOUGHT  ·  FIND THE WAY DOWN", kind = "boss"}) end
		self:run()
	end
end

-- a touch: cold through the armour, a stagger, and it falls back
function Shade:touch(l)
	local c, r = l.char, l.root
	local h = humOf(c)
	if not h or h.Health <= 0 or CombatServer.isProtected(c) then return false end
	local dmg = Shade.TOUCH * (1 - 0.5 * math.clamp(c:GetAttribute("ArmorProtection") or 0, 0, 0.9))
	CombatServer.markCombat(c)
	local away = flat(r.Position - self.pos)
	away = away.Magnitude > 0.1 and away.Unit or V3(1, 0, 0)
	CombatServer.flinch(c, away)
	CombatServer.showDamage(nil, c, dmg, nil, dmg >= h.Health, false)
	h:TakeDamage(dmg)
	self.node:SetAttribute("ShadeHitPos", r.Position)
	self.node:SetAttribute("ShadeHit", (self.node:GetAttribute("ShadeHit") or 0) + 1)
	-- (back into the dark, somewhere off to the side, a while)
	local a = math.random() * math.pi * 2
	self.pos = r.Position + V3(math.cos(a) * 34, 1.5, math.sin(a) * 34)
	self.backUntil = os.clock() + Shade.BACK
	self:publish("back")
	self.node:SetAttribute("ShadePos", self.pos)
	return true
end

function Shade:run()
	if self.conn then self.conn:Disconnect() end
	local sent = 0
	self.conn = RunService.Heartbeat:Connect(function(dt)
		local ctx = self.ctx
		if not (ctx and self.pos and self.huntAt) then return end
		local now = os.clock()
		if self.backUntil then
			if now < self.backUntil then return end
			self.backUntil = nil
			self:publish("hunt")
		end
		local list = living()
		if #list == 0 then return end
		-- the nearest of you (one outside the room being fought, if any is)
		local room = ctx.fighting
		local pick, pd, pickOut, pdOut = nil, math.huge, nil, math.huge
		for _, l in ipairs(list) do
			local d = (l.root.Position - self.pos).Magnitude
			if d < pd then pick, pd = l, d end
			if (not room or not inside(room, l.root.Position, 0)) and d < pdOut then pickOut, pdOut = l, d end
		end
		pick = pickOut or pick
		local goal = pick.root.Position + V3(0, 1.5, 0)
		local speed = math.min(Shade.SPEED[2], Shade.SPEED[1] + math.floor((now - self.huntAt) / 30) * Shade.SPEED[3])
		local to = flat(goal - self.pos)
		local step = to.Magnitude > 0.05 and to.Unit * math.min(speed * dt, to.Magnitude) or V3()
		local nxt = self.pos + step
		nxt = V3(nxt.X, self.pos.Y + (goal.Y - self.pos.Y) * math.min(1, dt * 2), nxt.Z)
		-- (never into a room being fought: it waits at the walls)
		local waiting = false
		if room and inside(room, pick.root.Position, 0) then nxt, waiting = outside(room, nxt, Shade.MARGIN) end
		self.pos = nxt
		self:publish(waiting and "wait" or "hunt")
		if not waiting then
			for _, l in ipairs(list) do
				local d = flat(l.root.Position - self.pos).Magnitude
				if d < Shade.REACH and math.abs(l.root.Position.Y - self.pos.Y) < 5 and not (room and inside(room, l.root.Position, 0)) then
					if self:touch(l) then break end
				end
			end
		end
		sent += dt
		if sent >= 1 / 12 then
			sent = 0
			self.node:SetAttribute("ShadePos", self.pos)
		end
	end)
end

return Shade
