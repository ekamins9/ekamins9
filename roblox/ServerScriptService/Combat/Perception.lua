--[[ PERCEPTION — what a monster knows (Deadvault, The Depths). It doesn't come for you until it
     SEES you (in front of it, near enough, nothing solid in the way — half as far while you
     crouch) or HEARS you (running, fighting, close by; a crouch is quiet); struck, it knows who
     did it. One that finds you SHOUTS: the others near it know too. Lose it (out of sight a
     while) and it goes where it last saw you, looks about, and goes back.

       local P = Perception.new(opts)         a group's senses
         opts.sight (46 studs) · opts.fov (degrees, 150) · opts.hearing (12) · opts.memory (7 s)
         opts.shout (30 studs: who hears its call) · opts.leash (studs from home it'll chase: 160)
       P.engage(bot, foe), P.goal(bot)        Bots' hooks (Combat ▸ Bots: opts.engage, opts.goal)
       P.add(bot, how)                        how = {home = Vector3, patrol = {Vector3…},
                                              asleep = true, sight =, hearing =}
       P.alert(bot, foe)                      it knows them now (a shout, a blow)
       Perception.noise(pos, radius)          something loud (a chest's lid, a portal opening):
                                              everyone within radius, of every group, wakes and
                                              comes to look

     Its state rides the model's Alert attribute: "!" (it knows you), "?" (searching), "z"
     (asleep): every client draws it over its head (Adventure.client). ]]

local Players = game:GetService("Players")

local Perception = {}
Perception.__index = Perception

local groups = setmetatable({}, {__mode = "k"})
local function now() return os.clock() end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

-- solid things between two points (bodies, loot and effects don't hide anyone)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
local paramsAt = 0
local function params()
	if now() - paramsAt > 1 then
		paramsAt = now()
		local skip = {}
		for _, n in ipairs({"NPCs", "LootDrops", "MonsterFX", "DroppedWeapons", "LootFX", "MagicFX"}) do
			local f = workspace:FindFirstChild(n)
			if f then table.insert(skip, f) end
		end
		for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(skip, p.Character) end end
		rayParams.FilterDescendantsInstances = skip
	end
	return rayParams
end
local function clearLine(a, b)
	local d = b - a
	if d.Magnitude < 0.5 then return true end
	return workspace:Raycast(a, d, params()) == nil
end

function Perception.new(opts)
	opts = opts or {}
	local self = setmetatable({
		sight = opts.sight or 46, fov = math.cos(math.rad((opts.fov or 150) / 2)), hearing = opts.hearing or 12,
		memory = opts.memory or 7, shout = opts.shout or 30, leash = opts.leash or 160,
		bots = {},   -- [bot] = state
	}, Perception)
	groups[self] = true
	self.engage = function(b, foe) return self:_engage(b, foe) end
	self.goal = function(b) return self:_goal(b) end
	return self
end

function Perception:add(bot, how)
	how = how or {}
	local s = {aware = {}, checked = {}, home = how.home, patrol = how.patrol, wp = 1, asleep = how.asleep,
		sight = how.sight or self.sight, hearing = how.hearing or self.hearing, mode = how.asleep and "asleep" or "idle"}
	self.bots[bot] = s
	if bot.model then bot.model:SetAttribute("Alert", how.asleep and "z" or nil) end
	return s
end
function Perception:remove(bot) self.bots[bot] = nil end

local function setAlert(b, a) if b.model and b.model.Parent and b.model:GetAttribute("Alert") ~= a then b.model:SetAttribute("Alert", a) end end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end

-- does it notice them, right now?
function Perception:sense(b, s, foe)
	local me, fr = b.hrp, rootOf(foe)
	if not (me and fr) then return false end
	local to = fr.Position - me.Position
	local d = to.Magnitude
	if d < 5 then return true end
	-- struck by them a moment ago
	local plr = Players:GetPlayerFromCharacter(foe)
	if plr and b.model:GetAttribute("LastHitBy") == plr.UserId and now() - (b.model:GetAttribute("LastHitAt") or -1e9) < 1.5 then return true end
	local crouch = foe:GetAttribute("Crouching") == true
	local eye, theirs = me.Position + Vector3.new(0, 1.5, 0), fr.Position + Vector3.new(0, 1.2, 0)
	-- HEARING: how loud they are (a run, a fight), muffled by a wall between
	local speed = flat(fr.AssemblyLinearVelocity).Magnitude
	local loud = 0
	if speed > 17 then loud = 30 elseif speed > 5 then loud = crouch and 5 or 15 end
	if now() - (foe:GetAttribute("LastCombatAt") or -1e9) < 1.5 then loud = math.max(loud, 42) end
	loud = math.max(loud, crouch and s.hearing * 0.4 or s.hearing)
	if s.asleep then loud *= 0.45 end
	if d < loud then
		if d < loud * 0.6 or clearLine(eye, theirs) then return true end
	end
	if s.asleep then return false end
	-- SIGHT: in front of it, near enough, nothing in the way
	local range = s.sight * (crouch and 0.55 or 1)
	if d > range then return false end
	local f = flat(to)
	if f.Magnitude > 0.1 and flat(me.CFrame.LookVector).Unit:Dot(f.Unit) < self.fov and d > 9 then return false end
	return clearLine(eye, theirs)
end

-- it knows them now, and so do its friends within earshot
function Perception:alert(b, foe, quiet)
	local s = self.bots[b]
	if not s then return end
	local first = s.mode ~= "hunt"
	s.aware[foe] = now()
	s.asleep = false
	s.mode = "hunt"
	local fr = rootOf(foe)
	if fr then s.lastKnown = fr.Position end
	setAlert(b, "!")
	if first and not quiet and b.hrp then
		for o, os2 in pairs(self.bots) do
			if o ~= b and o.alive and o.hrp and (o.hrp.Position - b.hrp.Position).Magnitude < self.shout and os2.mode ~= "hunt" then
				task.delay(0.3 + math.random() * 0.4, function() if self.bots[o] then self:alert(o, foe, true) end end)
			end
		end
	end
end

function Perception:_engage(b, foe)
	local s = self.bots[b]
	if not s then return true end
	local t = now()
	-- (a few looks a second at each, not every frame)
	local c = s.checked[foe]
	local seen
	if c and t - c.at < 0.25 then seen = c.seen
	else
		seen = self:sense(b, s, foe)
		s.checked[foe] = {at = t, seen = seen}
	end
	local fr = rootOf(foe)
	-- too far from home: it lets them go
	if s.home and fr and flat(fr.Position - s.home).Magnitude > self.leash then
		s.aware[foe] = nil
		return false
	end
	if seen then
		if s.mode ~= "hunt" or not s.aware[foe] then self:alert(b, foe) end
		s.aware[foe] = t
		if fr then s.lastKnown = fr.Position end
		return true
	end
	local known = s.aware[foe]
	if known then
		if t - known < self.memory then
			-- (it heads for where they went: it remembers for a while)
			if fr then s.lastKnown = fr.Position end
			return true
		end
		s.aware[foe] = nil
		if not next(s.aware) then
			s.mode, s.searchUntil = "search", t + 7
			setAlert(b, "?")
		end
	end
	return false
end

function Perception:_goal(b)
	local s = self.bots[b]
	if not s then return nil end
	local t = now()
	local me = b.hrp
	if not me then return nil end
	if s.mode == "hunt" and not next(s.aware) then s.mode, s.searchUntil = "search", t + 7; setAlert(b, "?") end
	if s.mode == "search" then
		if t < (s.searchUntil or 0) and s.lastKnown then
			if flat(s.lastKnown - me.Position).Magnitude > 4 then return s.lastKnown end
			-- (there: it looks about)
			s.lookAround = s.lookAround or (me.Position + Vector3.new(math.random(-12, 12), 0, math.random(-12, 12)))
			if flat(s.lookAround - me.Position).Magnitude > 3 then return s.lookAround end
			s.lookAround = nil
			return nil
		end
		s.mode, s.lastKnown, s.lookAround = "idle", nil, nil
		setAlert(b, nil)
	end
	if s.mode == "asleep" then return nil end
	-- its patrol, round and round
	if s.patrol and #s.patrol > 0 then
		local wp = s.patrol[s.wp]
		if flat(wp - me.Position).Magnitude < 6 then
			s.wp = (s.wp % #s.patrol) + 1
			wp = s.patrol[s.wp]
		end
		return wp
	end
	-- home
	if s.home and flat(s.home - me.Position).Magnitude > 7 then return s.home end
	return nil
end

-- something loud at pos: every group's monsters within radius come to look (the asleep wake)
function Perception.noise(pos, radius, foe)
	for g in pairs(groups) do
		for b, s in pairs(g.bots) do
			if b.alive and b.hrp and (b.hrp.Position - pos).Magnitude < radius and s.mode ~= "hunt" then
				s.asleep = false
				if foe and foe.Parent then
					g:alert(b, foe, true)
				else
					s.mode, s.searchUntil, s.lastKnown = "search", now() + 9, pos
					setAlert(b, "?")
				end
			end
		end
	end
end

return Perception
