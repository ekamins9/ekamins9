--[[ PASTIMES — the things to do between fights, all looks-only, all decided
     here on the server:
       PLAYTIME GIFTS (Catalog ▸ Gifts): minutes played today unlock gifts
       THE HATCHERY (Catalog ▸ Eggs): eggs incubate in nests in real time,
         faster while you stand by the Hatchery; a hatched egg rolls a
         COMPANION (Catalog ▸ Companions) that follows you around

       Pastimes.gifts(plr)               -> {day, seconds, claimed = {["1"] = true}}
       Pastimes.addPlaytime(plr, seconds)
       Pastimes.giftClaim(plr, i)        -> ok, msg, crateResult
       Pastimes.hatchery(plr)            -> {nests = {["1"] = {egg, need, left, ready}}, eggs = {id = n}, count, now}
       Pastimes.grantEgg(plr, id, n)
       Pastimes.eggBuy(plr, id)          -> ok, msg        (the Hatchery's shelf)
       Pastimes.eggPlace(plr, id, nest)  -> ok, msg        (nest nil = the first empty one)
       Pastimes.hatch(plr, nest, now)    -> result | nil, msg   (now = pay Crowns to skip the wait)
       Pastimes.skipCost(secondsLeft)    -> Crowns
       Pastimes.boost(plr, seconds)      the Hatchery's speed-up (Hub ▸ Pastimes calls it)
       Pastimes.grantCompanion(plr, id)  -> {id, name, rarity, dup, stars, refund}
       Pastimes.equip(plr, id | "")      -> ok, msg
     A companion result: a duplicate adds a star (up to Eggs.stars); past that
     it pays the rarity's refund in Marks. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Economy = require(script.Parent:WaitForChild("Economy"))

local Pastimes = {}
local EGGS = Catalog.EGGS
local function today() return os.date("!%Y-%m-%d") end

--------------------------------------------------------------------
--  PLAYTIME GIFTS
--------------------------------------------------------------------
local function playRecord(plr)
	local p = Profile.get(plr)
	if type(p.play) ~= "table" or p.play.day ~= today() then
		p.play = {day = today(), seconds = 0, claimed = {}}
		Profile.markDirty(plr)
	end
	p.play.claimed = p.play.claimed or {}
	return p.play
end

function Pastimes.gifts(plr)
	local r = playRecord(plr)
	local claimed = {}
	for k in pairs(r.claimed) do claimed[tostring(k)] = true end
	return {day = r.day, seconds = r.seconds or 0, claimed = claimed}
end

function Pastimes.addPlaytime(plr, seconds)
	local r = playRecord(plr)
	r.seconds = (r.seconds or 0) + seconds
	Profile.markDirty(plr)
end

function Pastimes.giftClaim(plr, i)
	i = tonumber(i)
	local g = i and Catalog.GIFTS.gifts[i]
	if not g then return false, "no such gift" end
	local r = playRecord(plr)
	if r.claimed[tostring(i)] then return false, "already claimed" end
	local wait = g.minutes * 60 - (r.seconds or 0)
	if wait > 0 then return false, string.format("play %d more minute%s", math.ceil(wait / 60), math.ceil(wait / 60) == 1 and "" or "s") end
	r.claimed[tostring(i)] = true
	local line, crate = Economy.grantReward(plr, g.reward)
	return true, "GIFT  ·  " .. line, crate
end

--------------------------------------------------------------------
--  THE HATCHERY
--------------------------------------------------------------------
local function hatcheryRecord(plr)
	local p = Profile.get(plr)
	if type(p.eggs) ~= "table" then p.eggs = {} end
	if type(p.nests) ~= "table" then p.nests = {} end
	if type(p.stars) ~= "table" then p.stars = {} end
	return p
end
local function needOf(eggId) local e = Catalog.EGG[eggId]; return e and e.minutes * 60 or 0 end
local function progressOf(n, now) return (now - (n.started or now)) + (n.boost or 0) end

function Pastimes.skipCost(left)
	return math.max(EGGS.skipMin or 3, math.ceil(left / 3600 * (EGGS.skipCrowns or 10)))
end

function Pastimes.hatchery(plr)
	local p = hatcheryRecord(plr)
	local now = os.time()
	local nests = {}
	for i = 1, EGGS.nests do
		local n = p.nests[tostring(i)]
		if type(n) == "table" and Catalog.EGG[n.egg] then
			local need = needOf(n.egg)
			local left = math.max(0, need - progressOf(n, now))
			nests[tostring(i)] = {egg = n.egg, need = need, left = left, ready = left <= 0, skip = left > 0 and Pastimes.skipCost(left) or 0}
		end
	end
	local eggs = {}
	for id, c in pairs(p.eggs) do if Catalog.EGG[id] and type(c) == "number" and c > 0 then eggs[id] = c end end
	return {nests = nests, eggs = eggs, count = EGGS.nests, now = now, boost = EGGS.boost}
end

function Pastimes.grantEgg(plr, id, n)
	if not Catalog.EGG[id] then return false end
	local p = hatcheryRecord(plr)
	p.eggs[id] = (p.eggs[id] or 0) + (n or 1)
	Profile.markDirty(plr)
	return true
end

function Pastimes.eggBuy(plr, id)
	local e = Catalog.EGG[id]
	if not e then return false, "no such egg" end
	if not e.marks and not e.crowns then return false, e.name .. " isn't sold: it comes from gifts and the pass" end
	local ok, msg = Economy.spend(plr, e.marks or 0, e.crowns or 0)
	if not ok then return false, msg end
	Pastimes.grantEgg(plr, id, 1)
	Economy.changed:Fire(plr)
	return true, e.name .. " bought: set it in a nest"
end

function Pastimes.eggPlace(plr, id, nest)
	local e = Catalog.EGG[id]
	if not e then return false, "no such egg" end
	local p = hatcheryRecord(plr)
	if (p.eggs[id] or 0) <= 0 then return false, "you have no " .. e.name end
	nest = tonumber(nest)
	if not nest then
		for i = 1, EGGS.nests do if not p.nests[tostring(i)] then nest = i; break end end
	end
	if not nest or nest < 1 or nest > EGGS.nests then return false, "every nest is taken: hatch one first" end
	if p.nests[tostring(nest)] then return false, "that nest is taken" end
	p.eggs[id] -= 1
	if p.eggs[id] <= 0 then p.eggs[id] = nil end
	p.nests[tostring(nest)] = {egg = id, started = os.time(), boost = 0}
	Profile.markDirty(plr)
	Economy.changed:Fire(plr)
	return true, string.format("%s is warming in nest %d", e.name, nest)
end

-- standing by the Hatchery: every incubating egg gains `seconds` extra
function Pastimes.boost(plr, seconds)
	local p = hatcheryRecord(plr)
	local now, any = os.time(), false
	for _, n in pairs(p.nests) do
		if type(n) == "table" and Catalog.EGG[n.egg] and progressOf(n, now) < needOf(n.egg) then
			n.boost = (n.boost or 0) + seconds
			any = true
		end
	end
	if any then Profile.markDirty(plr) end
	return any
end

local function roll(odds)
	local r, acc = math.random() * 100, 0
	for _, name in ipairs({"Legendary", "Epic", "Rare", "Common"}) do
		acc += odds[name] or 0
		if r < acc then return name end
	end
	return "Common"
end

function Pastimes.grantCompanion(plr, id)
	local c = Catalog.COMPANION[id]
	if not c then return nil end
	local p = hatcheryRecord(plr)
	local dup = Profile.has(plr, "companions", id)
	local refund = 0
	if dup then
		local s = p.stars[id] or 1
		if s < (EGGS.stars or 5) then p.stars[id] = s + 1
		else refund = (EGGS.refund or {})[c.rarity] or 0; p.wallet.marks += refund end
	else
		Profile.grant(plr, "companions", id)
		p.stars[id] = 1
		-- the first one comes along at once
		if (p.companion or "") == "" then p.companion = id end
	end
	Profile.markDirty(plr)
	Economy.changed:Fire(plr)
	return {id = id, name = c.name, rarity = c.rarity, dup = dup, stars = p.stars[id], refund = refund}
end

function Pastimes.hatch(plr, nest, now)
	local p = hatcheryRecord(plr)
	nest = tostring(tonumber(nest) or 0)
	local n = p.nests[nest]
	if type(n) ~= "table" or not Catalog.EGG[n.egg] then return nil, "that nest is empty" end
	local e = Catalog.EGG[n.egg]
	local left = needOf(n.egg) - progressOf(n, os.time())
	if left > 0 then
		if not now then return nil, "not ready yet" end
		local ok, msg = Economy.spend(plr, 0, Pastimes.skipCost(left))
		if not ok then return nil, msg end
	end
	local pool = Catalog.eggPool(n.egg)
	local rarity = roll(e.odds)
	local picks = {}
	for _, c in ipairs(pool) do if c.rarity == rarity then table.insert(picks, c) end end
	if #picks == 0 then picks = pool end
	if #picks == 0 then return nil, "nothing hatches from this egg yet" end
	local win = picks[math.random(#picks)]
	p.nests[nest] = nil
	local res = Pastimes.grantCompanion(plr, win.id)
	res.egg = n.egg
	res.nest = tonumber(nest)
	return res
end

function Pastimes.equip(plr, id)
	local p = hatcheryRecord(plr)
	if id == nil or id == "" then
		p.companion = ""
		Profile.markDirty(plr)
		return true, "your companion is resting"
	end
	if not Catalog.COMPANION[id] or not Profile.has(plr, "companions", id) then return false, "you haven't hatched that one" end
	p.companion = id
	Profile.markDirty(plr)
	return true, Catalog.COMPANION[id].name .. " comes along"
end

return Pastimes
