--[[ DROPS — what is live right now, from Catalog ▸ Calendar. Shared: the server
     decides with it, clients draw with it, and both read the same clock (the
     server's, via workspace:GetServerTimeNow()), so a drop appears everywhere
     at the same second.

       Drops.now()                  the shared clock (+ a Studio time-travel offset)
       Drops.time(idOrTime)         unix time of a drop id or a "YYYY-MM-DD HH:MM" (UTC)
       Drops.released(dropId)       is that drop out? (forced / held by staff count)
       Drops.current() / next()     the newest drop that is out / the next one coming
       Drops.events()               the events running now (the dated ones, else this weekend's)
       Drops.rule(name)             is a play rule on now? ("roulette": Armory Roulette)
       Drops.earnMult(kind, mode)   the event bonus on "marks" / "xp" (1 = none)
       Drops.crateLive(id)          is that crate in rotation? (+ when it leaves, the rule,
                                    and how: "daily" | "featured" | "event" | "vault")
       Drops.eggLive(id)            the same for an egg
       Drops.crateNext(id) / eggNext(id)   when it is next in rotation (nil = not planned)
       Drops.vaulted(now)           the crate brought back this weekend ("From the Vault"), if any
       Drops.claimsOpen()           the claims open now
       Drops.skinStatus(skin, profileSummary?) -> status, note
             "unreleased" | "live" | "vaulted" (may come back) | "relic" (never again)
       Drops.foundersOpen()         can new Founders still join?
       Drops.betaOpen() / beta()    is the beta on (new Beta Testers)? / its config
     A drop with no `at` is TBD: never out by itself (Drops.next gives it with a nil time).

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
	if s == nil then return nil end
	if type(s) == "number" then return s end
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
	if not d.at then return false end   -- (TBD: no date yet)
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
-- the next drop (not yet live) that brings a field — "crate" / "egg" — and when
function Drops.nextWith(field, now)
	now = now or Drops.now()
	for _, d in ipairs(drops()) do
		if d[field] and not Drops.released(d.id, now) then return d, parse(d.at) end
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
-- (an event or a claim with `after` waits for that drop, whatever its dates say)
local function on(x, now) return inside(x.from, x.to, now) and Drops.released(x.after, now) end
function Drops.eventLive(id, now)
	local e = Drops.event(id)
	return e ~= nil and on(e, now)
end
-- THE WEEKENDS (Calendar weekends): Friday 16:00 to Monday 08:00 UTC, the rotation in turn
local WEEK = 7 * 86400
local weekendCache = {}
local function weekendEvent(now)
	local W = cal().weekends
	if not (W and W.rotation and #W.rotation > 0) or not Drops.released(W.from, now) then return nil end
	local t = os.date("!*t", now)
	local fri = now - ((t.wday - 6) % 7) * 86400 - (t.hour * 3600 + t.min * 60 + t.sec) + 16 * 3600
	if fri > now then fri -= WEEK end
	local monday = fri + 2 * 86400 + 16 * 3600
	if now >= monday then return nil end
	local week = math.floor(fri / WEEK)
	local key = tostring(fri)
	if weekendCache.key ~= key then
		local e
		-- FROM THE VAULT: one vaulted crate back for the weekend, each in turn; with nothing
		-- in the vault yet, the next weekend of the rotation runs instead
		for k = 0, #W.rotation - 1 do
			local pick = W.rotation[(week + k) % #W.rotation + 1]
			local vaultCrate
			if pick.vault then
				local list = Drops.vaultable(fri)
				vaultCrate = #list > 0 and list[week % #list + 1] or nil
			end
			if not pick.vault or vaultCrate then
				e = table.clone(pick)
				e.crate = vaultCrate
				break
			end
		end
		if e then
			e.id = "Weekend:" .. tostring(e.id)
			e.from, e.to = os.date("!%Y-%m-%d %H:%M", fri), os.date("!%Y-%m-%d %H:%M", monday)
			e.weekend = true
		end
		weekendCache.key, weekendCache.e = key, e
	end
	return weekendCache.e
end
function Drops.events(now)
	now = now or Drops.now()
	local out = {}
	for _, e in ipairs(cal().events or {}) do if on(e, now) then table.insert(out, e) end end
	-- (the weekend's own, unless a dated event has the weekend already)
	if #out == 0 then
		local w = weekendEvent(now)
		if w then table.insert(out, w) end
	end
	return out
end
function Drops.rule(name, now)
	for _, e in ipairs(Drops.events(now)) do if e.rule == name then return true end end
	return false
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
local DAY = 86400
-- THE DAILY ROTATION (Calendar rotations): each UTC day `slots` of a group are in, the
-- window sliding through its `order`. -> is `id` in on day `d` (days since 1970)?
local function dailyIn(group, id, d)
	local g = (cal().rotations or {})[group]
	if not (g and g.order and #g.order > 0) then return false end
	local n, slots = #g.order, math.max(1, g.slots or 1)
	if slots >= n then return true end
	local start = ((d - math.floor((parse(g.epoch or "2026-01-01") or 0) / DAY)) * slots) % n
	for i = 0, slots - 1 do if g.order[(start + i) % n + 1] == id then return true end end
	return false
end
-- live?, leavesAt (unix, nil = not leaving), rule, how ("daily" | "event" | "vault" | "featured")
local function rotation(id, rule, now)
	now = now or Drops.now()
	if not rule or rule.always then return true, nil, rule, "always" end   -- (nothing uses this: everything rotates)
	if rule.daily then
		local d = math.floor(now / DAY)
		if dailyIn(rule.daily, id, d) then
			-- (in tomorrow as well: it leaves when its run of days ends)
			local last = d
			while last - d < 30 and dailyIn(rule.daily, id, last + 1) do last += 1 end
			return true, (last + 1) * DAY, rule, "daily"
		end
		return false, nil, rule, "daily"
	end
	if rule.event then
		local e = Drops.event(rule.event)
		if e and on(e, now) then return true, Drops.time(e.to), rule, "event" end
		return false, nil, rule, "event"
	end
	for _, w in ipairs(rule.windows or {}) do
		if inside(w.from, w.to, now) then return true, Drops.time(w.to), rule, "featured" end
	end
	-- back from the vault for the weekend
	for _, e in ipairs(Drops.events(now)) do
		if e.vault and e.crate == id then return true, Drops.time(e.to), rule, "vault" end
	end
	return false, nil, rule, "featured"
end
-- will it ever be in rotation again after now?
local function returns(rule, now)
	now = now or Drops.now()
	if not rule or rule.always or rule.daily then return true end
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
-- when is it next in? (nil = nothing planned: an event that's over, a vaulted crate)
local function nextIn(id, rule, now)
	now = now or Drops.now()
	if not rule or rule.always then return nil end
	if rule.daily then
		local d = math.floor(now / DAY)
		for k = 1, 60 do if dailyIn(rule.daily, id, d + k) then return (d + k) * DAY end end
		return nil
	end
	if rule.event then
		local e = Drops.event(rule.event)
		local t = e and Drops.time(e.from)
		return (t and t > now) and t or nil
	end
	local best
	for _, w in ipairs(rule.windows or {}) do
		local t = Drops.time(w.from)
		if t and t > now and (not best or t < best) then best = t end
	end
	return best
end
function Drops.crateLive(id, now) return rotation(id, (cal().crates or {})[id], now) end
function Drops.eggLive(id, now) return rotation(id, (cal().eggs or {})[id], now) end
function Drops.crateReturns(id, now) return returns((cal().crates or {})[id], now) end
function Drops.eggReturns(id, now) return returns((cal().eggs or {})[id], now) end
function Drops.crateNext(id, now) return nextIn(id, (cal().crates or {})[id], now) end
function Drops.eggNext(id, now) return nextIn(id, (cal().eggs or {})[id], now) end
-- the crates a FROM THE VAULT weekend can bring back at time t: a drop crate whose every
-- window is over (and not retired: a retired one's items are relics), in calendar order
function Drops.vaultable(t)
	local out = {}
	for cid, rule in pairs(cal().crates or {}) do
		if rule.windows and not rule.retire and #rule.windows > 0 then
			local over, future = true, false
			for _, w in ipairs(rule.windows) do
				local from = Drops.time(w.from)
				if not from or from > t or not Drops.released(w.from, t) then future = true end
				if not w.to or inside(w.from, w.to, t) then over = false end
				if w.to and Drops.get(w.to) and not Drops.released(w.to, t) then over = false end
			end
			if over and not future then table.insert(out, cid) end
		end
	end
	table.sort(out)
	return out
end
function Drops.vaulted(now)
	for _, e in ipairs(Drops.events(now)) do if e.vault and e.crate then return e.crate, Drops.time(e.to) end end
	return nil
end
-- when a crate / egg first comes out (for "NEW" badges), nil = always
function Drops.crateFrom(id)
	local r = (cal().crates or {})[id]
	if not r or r.always or r.daily then return nil end
	if r.event then local e = Drops.event(r.event); return e and Drops.time(e.from) end
	local w = r.windows and r.windows[1]
	return w and Drops.time(w.from)
end

--------------------------------------------------------------------
--  CLAIMS, FOUNDERS, FEATURES
--------------------------------------------------------------------
function Drops.claimsOpen(now)
	local out = {}
	for _, c in ipairs(cal().claims or {}) do if on(c, now) then table.insert(out, c) end end
	return out
end
function Drops.claim(id)
	for _, c in ipairs(cal().claims or {}) do if c.id == id then return c end end
	return nil
end
-- a window's end: its `to`, or `days` after its start (nil = open-ended)
local function windowEnd(w)
	if w.to then return w.to end
	local t0 = w.days and Drops.released(w.from) and Drops.time(w.from)
	return t0 and (t0 + w.days * 86400) or nil
end
function Drops.foundersOpen(now)
	local f = cal().founders
	return f ~= nil and inside(f.from, windowEnd(f), now)
end
function Drops.founders() return cal().founders end
function Drops.betaOpen(now)
	local b = cal().beta
	return b ~= nil and inside(b.from, windowEnd(b), now)
end
function Drops.beta() return cal().beta end
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
		if c and on(c, now) then return "live", "free gift, today only" end
		if c and now < (Drops.time(c.from) or 0) then return "unreleased", "coming soon" end
		return "relic", c and c.note or "a past gift"
	end
	if s.crate and s.crate ~= "earned" then
		local live, _, rule = Drops.crateLive(s.crate, now)
		if live then return "live", "" end
		if rule and rule.daily then return "live", "its crate is in the Armoury every few days" end
		if Drops.crateReturns(s.crate, now) then return "vaulted", "vaulted: its crate may come back" end
		return "relic", "its crate is gone for good"
	end
	return "live", ""
end

return Drops
