--[[ COLLECTION — what makes a cosmetic YOURS and not a database flag: its
     number, its finish, its story, and where it came from.

       Collection.restricted(plr)        paid random items are barred for this player
                                         (PolicyService ArePaidRandomItemsRestricted;
                                         unknown = barred). They open crates with Keys
                                         (earned only) and get eggs as gifts.
       Collection.serial(key, limit)     the next serial number of an item, global across
                                         servers (DataStore "Serials_v1"); nil = sold out
       Collection.grantNumbered(plr, skinId, from, variant)   a skin as a new COPY (Profile.addCopy),
                                         numbered if it wants a number; bound if it is not tradable
       Collection.tradable(key)          may a copy of it change hands (Trading)?
       Collection.rollSkinVariant() / rollPetVariant()   a finish by percent chance: Masterwork /
                                         Radiant (Catalog ▸ Economy ▸ variants), Golden / Spectral
                                         (Catalog ▸ Eggs ▸ variants)
       Collection.forge(plr, skinId)     FORGE_COST copies of a skin forge into one with the next
                                         finish (Standard → Masterwork → Radiant): no luck involved
       Collection.scrap(plr, copyId)     a spare copy melted down for Marks
       Collection.tally(plr, skinId)     one more kill on that skin (shown on its card)
       Collection.checkClaims(plr)       hands out open Calendar claims and the Founder's Oath
       Collection.rating(p)              the Armoury rating: what a collection is worth

     Numbered (serial) things: every Mythic, every limited skin, every claim and
     Founder gift, every Mythic companion. ]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Drops = require(ReplicatedStorage:WaitForChild("Drops"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Profile = require(script.Parent.Parent:WaitForChild("Loadout"):WaitForChild("Profile"))

local Collection = {}
Collection.FORGE_COST = 3
local SKIN_VARIANTS = {"Masterwork", "Radiant"}
local PET_VARIANTS = {"Golden", "Spectral"}
Collection.VARIANT_RANK = {Masterwork = 1, Radiant = 2, Golden = 1, Spectral = 2}

local function log(...) DebugFlags.log("Economy", ...) end

--------------------------------------------------------------------
--  PAID RANDOM ITEMS: who may buy them
--------------------------------------------------------------------
local restricted = {}
local function checkPolicy(plr)
	local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, plr)
	-- (Studio answers too; if Roblox can't say, treat the player as restricted)
	restricted[plr] = not (ok and type(info) == "table" and info.ArePaidRandomItemsRestricted == false)
	if RunService:IsStudio() and ReplicatedStorage:GetAttribute("PretendRestricted") then restricted[plr] = true end
end
function Collection.restricted(plr)
	if restricted[plr] == nil then checkPolicy(plr) end
	return restricted[plr] == true
end
Players.PlayerAdded:Connect(function(plr) task.spawn(checkPolicy, plr) end)
for _, plr in ipairs(Players:GetPlayers()) do task.spawn(checkPolicy, plr) end
Players.PlayerRemoving:Connect(function(plr) restricted[plr] = nil end)

--------------------------------------------------------------------
--  SERIAL NUMBERS (global) and LIMITED STOCK
--------------------------------------------------------------------
local store
pcall(function() store = DataStoreService:GetDataStore("Serials_v1") end)
local localCounters = {}   -- Studio / no DataStore: counts for this server only
local function dsKey(key) return (key:gsub("[^%w]", "")):sub(1, 48) end

function Collection.serial(key, limit)
	local got
	local ok = false
	if store then
		ok = pcall(function()
			store:UpdateAsync(dsKey(key), function(old)
				old = tonumber(old) or 0
				if limit and old >= limit then got = nil; return nil end
				got = old + 1
				return got
			end)
		end)
	end
	if not ok then
		local old = localCounters[key] or 0
		if limit and old >= limit then return nil end
		got = old + 1
		localCounters[key] = got
	end
	-- a limited one: everyone's shop shows the stock
	local s = Catalog.SKIN[key]
	if s and s.limited and got then Collection.publishStock(key, got) end
	return got
end

local stockFolder = ReplicatedStorage:FindFirstChild("LimitedStock")
if not stockFolder then stockFolder = Instance.new("Folder"); stockFolder.Name = "LimitedStock"; stockFolder.Parent = ReplicatedStorage end
function Collection.publishStock(skinId, made)
	local v = stockFolder:FindFirstChild(skinId)
	if not v then v = Instance.new("IntValue"); v.Name = skinId; v.Parent = stockFolder end
	v.Value = math.max(v.Value, made)
end
-- every server keeps the stock of every limited skin fresh
task.spawn(function()
	while true do
		for _, s in ipairs(Catalog.SKINS) do
			if s.limited then
				local made = localCounters[s.id] or 0
				if store then
					local ok, v = pcall(store.GetAsync, store, dsKey(s.id))
					if ok then made = math.max(made, tonumber(v) or 0) end
				end
				Collection.publishStock(s.id, made)
			end
		end
		task.wait(60)
	end
end)

--------------------------------------------------------------------
--  COPIES, VARIANTS, FORGING, SCRAPPING, TALLIES
--------------------------------------------------------------------
local function record(p)
	p.copies = p.copies or {}
	p.tally = p.tally or {}
	p.claims = p.claims or {}
	return p
end
function Collection.rollVariant(odds, names)
	local r, acc = math.random() * 100, 0
	for i = #names, 1, -1 do   -- rarest first
		acc += odds[names[i]] or 0
		if r < acc then return names[i] end
	end
	return nil
end
function Collection.rollSkinVariant() return Collection.rollVariant(Catalog.ECONOMY.variants or {}, SKIN_VARIANTS) end
function Collection.rollPetVariant() return Collection.rollVariant(Catalog.EGGS.variants or {}, PET_VARIANTS) end

-- a skin that wants a number gets one
function Collection.wantsSerial(s)
	return s ~= nil and (s.rarity == "Mythic" or s.limited ~= nil or s.claim ~= nil or s.founder == true)
end
-- may a copy of it change hands? Crate and shop skins, hatched companions: yes.
-- Founder gifts, claims, the pass, earned and pack skins stay with whoever got them.
function Collection.tradable(key)
	if type(key) ~= "string" then return false end
	if key:sub(1, 4) == "pet:" then
		local c = Catalog.COMPANION[key:sub(5)]
		return c ~= nil and not c.pass
	end
	local s = Catalog.SKIN[key]
	if not s then return false end
	local src = Catalog.skinSource(s)
	return src == "crate" or src == "shop"
end

-- a skin as a new copy, numbered if it wants one (nil, "sold out" for a limited one)
function Collection.grantNumbered(plr, skinId, from, variant)
	local s = Catalog.SKIN[skinId]
	if not s then return nil end
	local n
	if Collection.wantsSerial(s) then
		n = Collection.serial(skinId, s.limited)
		if s.limited and not n then return nil, "sold out" end
	end
	return Profile.addCopy(plr, skinId, {n = n, v = variant, from = from, bound = not Collection.tradable(skinId)})
end

-- three copies of a skin forge into one with the next finish (Standard → Masterwork
-- → Radiant): the two plainest go into the fire, the best one comes out better
function Collection.forge(plr, skinId)
	local p = record(Profile.get(plr))
	local s = Catalog.SKIN[skinId]
	if not s then return false, "no such skin" end
	local list = Profile.copies(p, skinId)
	if #list < Collection.FORGE_COST then
		return false, string.format("forging takes %d copies (you have %d)", Collection.FORGE_COST, #list)
	end
	table.sort(list, function(a, b)
		local ra, rb = Collection.VARIANT_RANK[a.v] or 0, Collection.VARIANT_RANK[b.v] or 0
		if ra ~= rb then return ra > rb end
		return (a.n or math.huge) < (b.n or math.huge)
	end)
	local keep = list[1]
	local rank = Collection.VARIANT_RANK[keep.v] or 0
	if rank >= #SKIN_VARIANTS then return false, "your best copy is already Radiant" end
	for _ = 1, Collection.FORGE_COST - 1 do table.remove(list) end
	keep.v = SKIN_VARIANTS[rank + 1]
	keep.from = (keep.from or "") .. ", forged"
	Profile.markDirty(plr)
	log(plr.Name, "forged", skinId, "->", keep.v)
	return true, string.format("%s forged to %s", s.name, keep.v), keep.v
end

-- a spare copy melted down for Marks (its rarity's duplicate refund)
function Collection.scrap(plr, uid)
	local p = record(Profile.get(plr))
	local key, c = Profile.findCopy(p, uid)
	if not key then return false, "you don't have that copy" end
	if Profile.copyCount(p, key) <= 1 then return false, "that's your only one: keep it" end
	local pet = key:sub(1, 4) == "pet:"
	local def = pet and Catalog.COMPANION[key:sub(5)] or Catalog.SKIN[key]
	if not def then return false, "unknown item" end
	local refund
	if pet then refund = (Catalog.EGGS.refund or {})[def.rarity] or 100
	else
		local cr = def.crate and Catalog.CRATES[def.crate]
		refund = (cr and cr.refund and cr.refund[def.rarity]) or ({Common = 150, Rare = 400, Epic = 900, Legendary = 2000, Mythic = 6000})[def.rarity] or 100
	end
	refund = math.floor(refund * ((c.v == "Radiant" or c.v == "Spectral") and 5 or ((c.v == "Masterwork" or c.v == "Golden") and 2 or 1)))
	Profile.takeCopy(plr, uid)
	p.wallet.marks += refund
	Profile.markDirty(plr)
	return true, string.format("scrapped for %d Marks", refund), refund
end

function Collection.tally(plr, skinId)
	if not skinId or not Catalog.SKIN[skinId] then return end
	local p = record(Profile.get(plr))
	p.tally[skinId] = (p.tally[skinId] or 0) + 1
	Profile.markDirty(plr)
end

--------------------------------------------------------------------
--  CLAIMS and FOUNDERS
--------------------------------------------------------------------
local Economy   -- (Economy requires this module)
local function toast(plr, text)
	local ev = ReplicatedStorage:FindFirstChild("HubEvent")
	if ev and plr.Parent then ev:FireClient(plr, "Toast", text) end
end
local function gift(plr, title, text, skinId, serial)
	local ev = ReplicatedStorage:FindFirstChild("HubEvent")
	if ev and plr.Parent then ev:FireClient(plr, "Gift", {title = title, text = text, skin = skinId, serial = serial}) end
end

function Collection.checkClaims(plr)
	Economy = Economy or require(script.Parent:WaitForChild("Economy"))
	local p = record(Profile.get(plr))
	local changed = false
	-- the Founders: everyone who plays before the window closes, numbered in the order they came
	local f = Drops.founders()
	if f and Drops.foundersOpen() and not p.founder then
		p.founder = Collection.serial("Founder") or 0
		if f.skin and Catalog.SKIN[f.skin] then
			Profile.addCopy(plr, f.skin, {n = p.founder, from = "Founder", bound = true})
		end
		if f.title then Profile.grant(plr, "titles", f.title) end
		changed = true
		gift(plr, "FOUNDER #" .. p.founder, "You were here at the start. The Founder's Oath is yours, numbered for ever.", f.skin, p.founder)
	end
	for _, c in ipairs(Drops.claimsOpen()) do
		if not p.claims[c.id] then
			p.claims[c.id] = os.time()
			local r = c.reward or {}
			local serial
			if r.skin and Catalog.SKIN[r.skin] then
				local it = Collection.grantNumbered(plr, r.skin, c.note or c.id)
				serial = it and it.n
			end
			local rest = {}
			for k, v in pairs(r) do if k ~= "skin" then rest[k] = v end end
			local line = next(rest) and Economy.grantReward(plr, rest) or nil
			local s = r.skin and Catalog.SKIN[r.skin]
			gift(plr, s and string.upper(s.name) .. (serial and (" #" .. serial) or "") or "A GIFT", (c.note and ("A gift " .. c.note .. ". ") or "") .. (line or ""), r.skin, serial)
			changed = true
		end
	end
	if changed then Profile.markDirty(plr); Economy.changed:Fire(plr) end
end
Players.PlayerAdded:Connect(function(plr)
	task.delay(6, function() if plr.Parent then pcall(Collection.checkClaims, plr) end end)
end)
task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in ipairs(Players:GetPlayers()) do pcall(Collection.checkClaims, plr) end
	end
end)

--------------------------------------------------------------------
--  THE ARMOURY RATING
--------------------------------------------------------------------
local POINTS = {Common = 1, Rare = 4, Epic = 12, Legendary = 35, Mythic = 150}
local VARIANT_X = {Masterwork = 2, Radiant = 5, Golden = 2, Spectral = 5}
function Collection.rating(p)
	local total = 0
	local function worth(key, def, c)
		local pts = POINTS[def.rarity] or 1
		if c and c.v then pts *= VARIANT_X[c.v] or 1 end
		if c and c.n and c.n <= 100 then pts *= 1.5 end
		return pts
	end
	for key, list in pairs(p.copies or {}) do
		local pet = key:sub(1, 4) == "pet:"
		local def = pet and Catalog.COMPANION[key:sub(5)] or Catalog.SKIN[key]
		if def then
			local mult = 1
			if pet then
				if def.egg and not Drops.eggReturns(def.egg) and not Drops.eggLive(def.egg) then mult = 2 end
			else
				local status = Drops.skinStatus(def)
				if status == "relic" then mult = 2 elseif status == "vaulted" then mult = 1.3 end
				if def.limited then mult *= 2 end
			end
			for _, c in ipairs(list) do total += worth(key, def, c) * mult end
		end
	end
	-- skins held the old way (earned, the pass, packs): one each
	for id, owned in pairs(p.owned and p.owned.skins or {}) do
		local s = owned and Catalog.SKIN[id]
		if s and not (p.copies and p.copies[id]) then total += POINTS[s.rarity] or 1 end
	end
	return math.floor(total)
end
Collection.POINTS, Collection.VARIANT_X = POINTS, VARIANT_X

-- the profile summary shows these to the client
Profile.restrictedHook = Collection.restricted
Profile.ratingHook = Collection.rating

return Collection
