--[[ DROPS — what is live right now, from Catalog ▸ Calendar. Shared: the server
     decides with it, clients draw with it, and both read the same clock (the
     server's, via workspace:GetServerTimeNow()), so a drop appears everywhere
     at the same second.

       Drops.now()                  the shared clock (+ a Studio time-travel offset)
       Drops.time(idOrTime)         unix time of a drop id or a "YYYY-MM-DD HH:MM" (UTC)
       Drops.released(dropId)       is that drop out? (forced / held by staff count)
       Drops.current() / next()     the newest drop that is out / the next one coming
       Drops.events()               the events running now
       Drops.earnMult(kind, mode)   the event bonus on "marks" / "xp" (1 = none)
       Drops.crateLive(id)          is that crate in rotation? (+ when it leaves)
       Drops.eggLive(id)            the same for an egg
       Drops.claimsOpen()           the claims open now
       Drops.skinStatus(skin, profileSummary?) -> status, note
             "unreleased" | "live" | "vaulted" (may come back) | "relic" (never again)
       Drops.foundersOpen()         can new Founders still join?

     Staff overrides (ReplicatedStorage attributes, set by the admin panel and
     mirrored to every server): DropsForced = "id,id" (out early),
     DropsHeld = "id,id" (kept back), ClockOffset = seconds (Studio only). ]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Drops = {}
local Cal
local function cal()
	if not Cal then
		local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
		Cal = Catalog.CALENDAR or {drops = {}, events = {}, claims = {}, crates = {}, eggs = {}, features = {}}
	end
	return Cal
end

--------------------------------------------------------------------
--  TIME
--------------------------------------------------------------------
local parsed = {}
local function parse(s)
	if parsed[s] then return parsed[s] end
	local y, mo, d, h, mi = s:match("^(%d+)%-(%d+)%-(%d+)%s+(%d+):(%d+)$")
	if not y then y, mo, d = s:match("^(%d+)%-(%d+)%-(%d+)$"); h, mi = 0, 0 end
	if not y then return nil end
	local t = DateTime.fromUniversalTime(tonumber(y), tonumber(mo), tonumber(d), tonumber(h), tonumber(mi), 0).UnixTimestamp
	parsed[s] = t
	return t
end

function Drops.now()
	local base = workspace:GetServerTimeNow()
	local off = RunService:IsStudio() and (ReplicatedStorage:GetAttribute("ClockOffset") or 0) or 0
	return base + off
end

local byId
local function drops()
	if not byId then
		byId = {}
		for i, d in ipairs(cal().drops or {}) do byId[d.id] = d; d.index = i end
	end
	return cal().drops or {}
end
function Drops.get(id) drops(); return byId[id] end

-- a drop id or a time string -> unix time (nil = open-ended)
function Drops.time(x)
	if x == nil then return nil end
	if type(x) == "number" then return x end
	local d = Drops.get(x)
	if d then return parse(d.at) end
	return parse(x)
end

local function listAttr(name)
	local out = {}
	for id in string.gmatch(ReplicatedStorage:GetAttribute(name) or "", "[^,%s]+") do out[id] = true end
	return out
end

function Drops.released(id, now)
	if id == nil then return true end
	local d = Drops.get(id)
	if not d then return true end   -- (an unknown drop id never hides anything)
	if listAttr("DropsHeld")[id] then return false end
	if listAttr("DropsForced")[id] then return true end
	return (now or Drops.now()) >= (parse(d.at) or 0)
end

function Drops.current(now)
	now = now or Drops.now()
	local best
	for _, d in ipairs(drops()) do if Drops.released(d.id, now) then best = d end end
	return best
end
function Drops.next(now)
	now = now or Drops.now()
	for _, d in ipairs(drops()) do
		if not Drops.released(d.id, now) then return d, parse(d.at) end
	end
	return nil
end
function Drops.list() return drops() end

-- is now inside [from, to)? from/to: drop ids or times; a drop's start is its release
local function inside(from, to, now)
	now = now or Drops.now()
	local okFrom = true
	if from then
		if Drops.get(from) then okFrom = Drops.released(from, now) else okFrom = now >= (parse(from) or 0) end
	end
	local okTo = true
	if to then
		if Drops.get(to) then okTo = not Drops.released(to, now) else okTo = now < (parse(to) or math.huge) end
	end
	return okFrom and okTo
end
Drops.inside = inside

--------------------------------------------------------------------
--  EVENTS
--------------------------------------------------------------------
function Drops.event(id)
	for _, e in ipairs(cal().events or {}) do if e.id == id then return e end end
	return nil
end
function Drops.eventLive(id, now)
	local e = Drops.event(id)
	return e ~= nil and inside(e.from, e.to, now)
end
function Drops.events(now)
	local out = {}
	for _, e in ipairs(cal().events or {}) do if inside(e.from, e.to, now) then table.insert(out, e) end end
	return out
end
function Drops.earnMult(kind, mode)
	local m = 1
	for _, e in ipairs(Drops.events()) do
		local x = e.earn and e.earn[kind]
		if x then
			local okMode = e.modes == nil
			for _, md in ipairs(e.modes or {}) do if md == mode then okMode = true end end
			if okMode then m *= x end
		end
	end
	return m
end

--------------------------------------------------------------------
--  ROTATION: crates and eggs
--------------------------------------------------------------------
-- live?, leavesAt (unix, nil = not leaving), rule
local function rotation(rule, now)
	now = now or Drops.now()
	if not rule or rule.always then return true, nil, rule end
	if rule.event then
		local e = Drops.event(rule.event)
		if e and inside(e.from, e.to, now) then return true, Drops.time(e.to), rule end
		return false, nil, rule
	end
	for _, w in ipairs(rule.windows or {}) do
		if inside(w.from, w.to, now) then return true, Drops.time(w.to), rule end
	end
	return false, nil, rule
end
-- will it ever be in rotation again after now?
local function returns(rule, now)
	now = now or Drops.now()
	if not rule or rule.always then return true end
	if rule.event then
		local e = Drops.event(rule.event)
		return e ~= nil and now < (Drops.time(e.from) or 0)
	end
	for _, w in ipairs(rule.windows or {}) do
		local from = Drops.time(w.from)
		if from and now < from then return true end
		if not w.to then return true end
	end
	return not rule.retire
end
function Drops.crateLive(id, now) return rotation((cal().crates or {})[id], now) end
function Drops.eggLive(id, now) return rotation((cal().eggs or {})[id], now) end
function Drops.crateReturns(id, now) return returns((cal().crates or {})[id], now) end
function Drops.eggReturns(id, now) return returns((cal().eggs or {})[id], now) end
-- when a crate / egg first comes out (for "NEW" badges), nil = always
function Drops.crateFrom(id)
	local r = (cal().crates or {})[id]
	if not r or r.always then return nil end
	if r.event then local e = Drops.event(r.event); return e and Drops.time(e.from) end
	local w = r.windows and r.windows[1]
	return w and Drops.time(w.from)
end

--------------------------------------------------------------------
--  CLAIMS, FOUNDERS, FEATURES
--------------------------------------------------------------------
function Drops.claimsOpen(now)
	local out = {}
	for _, c in ipairs(cal().claims or {}) do if inside(c.from, c.to, now) then table.insert(out, c) end end
	return out
end
function Drops.claim(id)
	for _, c in ipairs(cal().claims or {}) do if c.id == id then return c end end
	return nil
end
function Drops.foundersOpen(now)
	local f = cal().founders
	return f ~= nil and inside(f.from, f.to, now)
end
function Drops.founders() return cal().founders end
function Drops.features(now)
	local out = {}
	for _, f in ipairs(cal().features or {}) do if inside(f.from, f.to, now) then table.insert(out, f.item) end end
	return out
end

--------------------------------------------------------------------
--  A SKIN'S STATUS
--------------------------------------------------------------------
-- "unreleased" | "live" | "vaulted" | "relic", and a short note for its card
function Drops.skinStatus(s, now)
	if not s then return "live", "" end
	now = now or Drops.now()
	if s.drop and not Drops.released(s.drop, now) then return "unreleased", "coming soon" end
	if s.founder then
		if Drops.foundersOpen(now) then return "live", "free for Founders" end
		return "relic", "Founders only"
	end
	if s.claim then
		local c = Drops.claim(s.claim)
		if c and inside(c.from, c.to, now) then return "live", "free gift, today only" end
		if c and now < (Drops.time(c.from) or 0) then return "unreleased", "coming soon" end
		return "relic", c and c.note or "a past gift"
	end
	if s.crate and s.crate ~= "earned" then
		local live = Drops.crateLive(s.crate, now)
		if live then return "live", "" end
		if Drops.crateReturns(s.crate, now) then return "vaulted", "vaulted: its crate may come back" end
		return "relic", "its crate is gone for good"
	end
	return "live", ""
end

return Drops
