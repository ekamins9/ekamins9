--[[ GIFTING — send Marks, Crowns and items to anyone by their username, whether they're online
     or not, or buy anything in the shop for them (a skin, a pack, a weapon, the pass, a Crowns
     bundle with Robux). Separate from Trading: one way, nothing back.

       Gifting.find(plr, username)          who that is: their name, whether they've played, whether
                                            they take gifts from you
       Gifting.info(plr)                    what you may send today (the daily allowances)
       Gifting.send(plr, toId, what)        what = {marks, crowns, items = {copy uid…}, note}
       Gifting.buy(plr, toId, what)         what = {kind, id, currency, note}: a shop purchase, theirs
       Gifting.buyCrowns(plr, toId, i, note)  a Crowns bundle (Robux) for them: the receipt delivers it
       Gifting.receipt(plr, productId, receiptId)  (EconomyServer) -> handled, saved

     THE GIFT BOX: Gifts_v1, key u<UserId> = {list = {gift…}}. Every gift goes in their box (each
     with its own id, so writing it twice is harmless), and is taken out when they're here: as
     they join, the moment it's sent if they're in this server, on a MessagingService nudge if
     they're in another, and every two minutes anyway. Taking is safe twice over: the profile
     remembers the ids it has opened (giftsIn), and the box only lets go of a gift once the
     profile holding it has saved.

     A gift: {id, from, fromName, at, note, marks, crowns, copies = {{key, copy}}, grants = {{kind,
     id, refund}}, skins = {{id, n, refund}}, pass, passRefund, label, returned}. Something they
     already own (an armor piece, a weapon, the pass) comes as what was paid for it instead.
     A skin is a copy of its own, so a second one is simply another copy.

     THE RULES:
       • the sender: level MIN_LEVEL and up, and where Roblox allows trading paid items
         (PolicyService IsPaidItemTradingAllowed: "trade virtual items purchased with
         in-experience currency or Robux"); the same for the one it reaches, checked as it
         arrives: where they can't receive it, it goes back to the sender, whole
       • the recipient has played, and takes gifts from you (Settings ▸ Gifts from)
       • at most ECONOMY.gifting.perDay of Marks, Crowns, items and gifts a day (UTC)
       • items: the copies that trade (Collection.tradable, unbound; armor as full sets)
       • never: crates, eggs or Keys (random items stay with whoever pays for them)
       • a note is one of ECONOMY.gifting.notes, picked, never typed
     The sender's side saves before anything leaves; if the box can't be written, it all comes
     back. Every gift is logged (GiftLog_v1, g<time>_<from>_<to>_<gift id>; Safety ▸ Erasure scrubs it). ]]

local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local UserService = game:GetService("UserService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Stores = require(ServerScriptService:WaitForChild("Safety"):WaitForChild("Stores"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Trading = require(script.Parent:WaitForChild("Trading"))
local Collection = require(script.Parent:WaitForChild("Collection"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))

local Gifting = {}
local CFG = Catalog.ECONOMY.gifting or {}
Gifting.MIN_LEVEL = CFG.minLevel or 5
Gifting.MAX_ITEMS = CFG.maxItems or 8
Gifting.PER_DAY = CFG.perDay or {marks = 25000, crowns = 5000, items = 20, gifts = 30}
Gifting.NOTES = CFG.notes or {"For you!"}
local INBOX_MAX = 60          -- gifts waiting in one box
local CHECK_EVERY = 120       -- seconds: everyone here looks in their box this often anyway
local TOPIC = "Gifts"

local inbox, logStore, profiles, settingsStore
pcall(function() inbox = Stores.get("Gifts_v1") end)
pcall(function() logStore = Stores.get("GiftLog_v1") end)
pcall(function() profiles = Stores.get("Profiles_v2") end)
pcall(function() settingsStore = Stores.get("PlayerSettings_v1") end)

local function economy() return require(script.Parent:WaitForChild("Economy")) end
local function event() return ReplicatedStorage:FindFirstChild("HubEvent") end
local function tell(plr, ...) local ev = event(); if ev and plr.Parent then ev:FireClient(plr, ...) end end
local function today() return os.date("!%Y-%m-%d") end
local function newId() return (HttpService:GenerateGUID(false):gsub("[^%w]", "")):sub(1, 16) end

--------------------------------------------------------------------
--  WHO MAY SEND, AND HOW MUCH TODAY
--------------------------------------------------------------------
function Gifting.allowed(plr)
	if not Trading.policyOk(plr) then return false, "gifting isn't available in your region" end
	if (Profile.get(plr).level or 1) < Gifting.MIN_LEVEL then return false, "gifting opens at level " .. Gifting.MIN_LEVEL end
	if not Profile.ready(plr) then return false, "your save hasn't loaded yet: try again in a moment" end
	return true
end

local function dayUse(p)
	if type(p.giftDay) ~= "table" or p.giftDay.day ~= today() then p.giftDay = {day = today(), marks = 0, crowns = 0, items = 0, gifts = 0} end
	return p.giftDay
end
local function left(p)
	local u = dayUse(p)
	local out = {}
	for k, cap in pairs(Gifting.PER_DAY) do out[k] = math.max(0, cap - (u[k] or 0)) end
	return out
end

function Gifting.info(plr)
	local ok, why = Gifting.allowed(plr)
	return {ok = true, allowed = ok, why = why, minLevel = Gifting.MIN_LEVEL, maxItems = Gifting.MAX_ITEMS,
		left = left(Profile.get(plr)), perDay = Gifting.PER_DAY, notes = Gifting.NOTES}
end

--------------------------------------------------------------------
--  WHO IS IT FOR
--------------------------------------------------------------------
local found = {}   -- [userId] = {at, info}: a look-up is a few web calls, kept a minute
local lastFind = {}

-- what they chose in Settings ▸ Gifts from (here: on them; elsewhere: their saved settings)
local function giftsFrom(userId)
	local here = Players:GetPlayerByUserId(userId)
	if here then return here:GetAttribute("Priv_Gifts") or "Everyone" end
	if not settingsStore then return "Everyone" end
	local ok, t = pcall(settingsStore.GetAsync, settingsStore, "u" .. userId)
	local v = ok and type(t) == "table" and t.Gifts
	return ClientSettings.valid("Gifts", v) and v or "Everyone"
end

local function lookUp(userId)
	local c = found[userId]
	if c and os.clock() - c.at < 60 then return c.info end
	local info = {userId = userId}
	local here = Players:GetPlayerByUserId(userId)
	if here then
		info.name, info.displayName, info.here = here.Name, here.DisplayName, true
		info.played, info.level = true, Profile.get(here).level
	else
		local okN, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		info.name = okN and name or nil
		local okI, infos = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, {userId})
		info.displayName = (okI and type(infos) == "table" and infos[1] and infos[1].DisplayName) or info.name
		if profiles then
			local okP, prof = pcall(profiles.GetAsync, profiles, "u" .. userId)
			if okP then info.played = type(prof) == "table"; info.level = info.played and prof.level or nil
			else info.played = nil end   -- (couldn't tell: let it through, the box will hold it)
		end
	end
	found[userId] = {at = os.clock(), info = info}
	return info
end

-- may this gift go from plr to userId? -> their info, or nil and why
local function canReach(plr, userId)
	userId = tonumber(userId)
	if not userId or userId <= 0 then return nil, "who is it for?" end
	if userId == plr.UserId then return nil, "that's you!" end
	local info = lookUp(userId)
	if not info.name then return nil, "no Roblox player by that name" end
	if info.played == false then return nil, (info.displayName or info.name) .. " hasn't played Steel & Glory yet" end
	local from = giftsFrom(userId)
	if from == "Nobody" then return nil, (info.displayName or info.name) .. " isn't taking gifts" end
	if from == "Friends" then
		local ok, isFriend = pcall(plr.IsFriendsWith, plr, userId)
		if not (ok and isFriend) then return nil, (info.displayName or info.name) .. " only takes gifts from friends" end
	end
	return info
end

function Gifting.find(plr, name)
	if os.clock() - (lastFind[plr] or 0) < 1 then return {ok = false, msg = "one moment"} end
	lastFind[plr] = os.clock()
	local userId
	if type(name) == "number" then
		userId = math.floor(name)   -- (picked from a list: a friend, someone here, a profile)
	else
		name = tostring(name or ""):gsub("^%s*@?", ""):gsub("%s*$", "")
		if #name < 3 or #name > 20 or name:find("[^%w_]") then return {ok = false, msg = "type their Roblox username (3-20 letters, numbers or _)"} end
		local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, name)
		if not ok or not id then return {ok = false, msg = "no Roblox player called " .. name} end
		userId = id
	end
	local info, why = canReach(plr, userId)
	if not info then return {ok = false, msg = why, userId = userId} end
	return {ok = true, userId = userId, name = info.name, displayName = info.displayName, here = info.here == true, level = info.level}
end

--------------------------------------------------------------------
--  THE GIFT BOX
--------------------------------------------------------------------
-- a gift into their box (written twice: still one gift). -> ok, why
local function post(toId, gift)
	if not inbox then return false, "gifts are unavailable right now" end
	local full = false
	local ok = false
	for attempt = 1, 3 do
		ok = pcall(inbox.UpdateAsync, inbox, "u" .. toId, function(old)
			full = false
			old = type(old) == "table" and old or {list = {}}
			old.list = type(old.list) == "table" and old.list or {}
			for _, g in ipairs(old.list) do if g.id == gift.id then return old end end
			if #old.list >= INBOX_MAX then full = true; return nil end
			table.insert(old.list, gift)
			return old
		end)
		if ok then break end
		task.wait(attempt)
	end
	if full then return false, "their gift box is full: they need to come and open it" end
	if not ok then return false, "couldn't reach their gift box just now" end
	-- here: open it now; another server: a nudge; offline: a Roblox notification (Hub ▸ Reminders)
	local here = Players:GetPlayerByUserId(toId)
	if here then task.spawn(Gifting.claim, here)
	else
		task.spawn(function() pcall(MessagingService.PublishAsync, MessagingService, TOPIC, {to = toId}) end)
		if _G.NotifyGift and not gift.returned then task.spawn(_G.NotifyGift, toId, gift.fromName) end
	end
	return true
end

-- something they already own comes as what was paid for it
local function refund(p, r, lines, what)
	if type(r) ~= "table" then return end
	local m, c = tonumber(r.marks) or 0, tonumber(r.crowns) or 0
	if m <= 0 and c <= 0 then return end
	p.wallet.marks += m; p.wallet.crowns += c
	table.insert(lines, string.format("%s (you had it: %s)", what, c > 0 and ("+" .. c .. " Crowns") or ("+" .. m .. " Marks")))
end

local KIND_NAME = {pieces = function(id) return (Catalog.PIECE[id] or {}).name or id end, weapons = function(id) return (Catalog.WEAPON[id] or {}).name or id end,
	skins = function(id) local s = Catalog.SKIN[id]; return s and s.name or id end, colors = function(id) return id end}

-- a gift into their profile -> the lines that say what came, and what the card shows
local function apply(plr, g)
	local p = Profile.get(plr)
	local lines, show = {}, {}
	if (tonumber(g.marks) or 0) > 0 then
		p.wallet.marks += g.marks; table.insert(lines, "+" .. g.marks .. " Marks"); table.insert(show, {kind = "marks", n = g.marks})
		Analytics.source(plr, "Marks", g.marks, p.wallet.marks, "Gameplay", g.returned and "GiftReturned" or "Gift")
	end
	if (tonumber(g.crowns) or 0) > 0 then
		p.wallet.crowns += g.crowns; table.insert(lines, "+" .. g.crowns .. " Crowns"); table.insert(show, {kind = "crowns", n = g.crowns})
		Analytics.source(plr, "Crowns", g.crowns, p.wallet.crowns, "Gameplay", g.returned and "GiftReturned" or "Gift")
	end
	for _, e in ipairs(g.copies or {}) do
		-- (a copy from someone's collection: it keeps its number, finish and story)
		if type(e) == "table" and type(e.key) == "string" and type(e.c) == "table" then
			Profile.giveCopy(plr, e.key, e.c)
			table.insert(show, {kind = "copy", key = e.key, n = e.c.n, v = e.c.v})
		end
	end
	for _, e in ipairs(g.skins or {}) do
		-- (a skin bought in the shop for them: a copy of its own, numbered at the time it was bought)
		if type(e) == "table" and Catalog.SKIN[e.id] then
			Profile.addCopy(plr, e.id, {n = e.n, from = "a gift"})
			table.insert(show, {kind = "copy", key = e.id, n = e.n})
		end
	end
	for _, e in ipairs(g.grants or {}) do
		local kind, id, r = e[1], e[2], e[3]
		if type(kind) == "string" and type(id) == "string" then
			local name = (KIND_NAME[kind] or tostring)(id)
			if Profile.has(plr, kind, id) then refund(p, r, lines, name)
			else
				Profile.grant(plr, kind, id)
				table.insert(lines, name)
				table.insert(show, {kind = "grant", grant = kind, id = id})
			end
		end
	end
	if g.pass then
		if economy().passGift(plr, g.pass) then
			table.insert(lines, Catalog.PASS.name .. " premium"); table.insert(show, {kind = "pass"})
		else refund(p, g.passRefund, lines, Catalog.PASS.name) end
	end
	-- (a companion out with you that was given away goes home: the sender's side, Gifting.send)
	Profile.markDirty(plr)
	return lines, show
end

-- the same gift, sent back to whoever sent it (they can't receive it where they are)
local function bounce(g, toName)
	local back = {}
	for k, v in pairs(g) do back[k] = v end
	back.id = tostring(g.id) .. "r"
	back.returned = true
	back.fromName = toName
	back.from = 0
	back.note = nil
	return post(g.from, back)
end

local claiming = {}
function Gifting.claim(plr)
	if claiming[plr] or not inbox or not plr.Parent then return end
	if not Profile.ready(plr) then return end
	claiming[plr] = true
	local ok, box = pcall(inbox.GetAsync, inbox, "u" .. plr.UserId)
	local list = ok and type(box) == "table" and type(box.list) == "table" and box.list or {}
	if #list == 0 then claiming[plr] = nil; return end
	local p = Profile.get(plr)
	p.giftsIn = type(p.giftsIn) == "table" and p.giftsIn or {}
	local done, opened = {}, {}
	local policyOk = Trading.policyOk(plr)
	for _, g in ipairs(list) do
		if type(g) ~= "table" or not g.id then continue end
		if p.giftsIn[g.id] then
			done[g.id] = true   -- (opened already: its save landed before the box let go)
		elseif not policyOk and not g.returned then
			-- where they can't receive bought things: back to the sender, whole
			if bounce(g, plr.DisplayName) then
				p.giftsIn[g.id] = os.time()
				done[g.id] = true
			end
		else
			local lines, show = apply(plr, g)
			p.giftsIn[g.id] = os.time()
			done[g.id] = true
			table.insert(opened, {id = g.id, fromName = g.fromName, note = g.note, label = g.label, lines = lines, items = show,
				returned = g.returned == true, at = g.at})
		end
	end
	-- (the profile remembers a few hundred: the oldest go)
	local n, oldest = 0, nil
	for _ in pairs(p.giftsIn) do n += 1 end
	while n > 300 do
		oldest = nil
		for id, t in pairs(p.giftsIn) do if not oldest or t < p.giftsIn[oldest] then oldest = id end end
		p.giftsIn[oldest] = nil; n -= 1
	end
	Profile.markDirty(plr)
	local saved = Profile.save(plr)
	if saved and next(done) then
		pcall(inbox.UpdateAsync, inbox, "u" .. plr.UserId, function(old)
			if type(old) ~= "table" or type(old.list) ~= "table" then return nil end
			local keep = {}
			for _, g in ipairs(old.list) do if not (type(g) == "table" and done[g.id]) then table.insert(keep, g) end end
			old.list = keep
			return old
		end)
	end
	if #opened > 0 then
		pcall(function() economy().changed:Fire(plr) end)
		tell(plr, "GiftsIn", opened, Profile.summary(plr))
	end
	claiming[plr] = nil
end

--------------------------------------------------------------------
--  SENDING
--------------------------------------------------------------------
local lastSend = {}
local function logGift(plr, toId, g)
	if not logStore then return end
	task.spawn(function()
		local rec = {at = os.time(), from = plr.UserId, to = toId, marks = g.marks, crowns = g.crowns, label = g.label,
			copies = {}, grants = g.grants, skins = g.skins, pass = g.pass}
		for _, e in ipairs(g.copies or {}) do table.insert(rec.copies, {key = e.key, n = e.c.n, v = e.c.v}) end
		pcall(logStore.SetAsync, logStore, string.format("g%d_%d_%d_%s", os.time(), plr.UserId, toId, tostring(g.id)), rec)
	end)
end

local function precheck(plr, toId)
	local ok, why = Gifting.allowed(plr)
	if not ok then return nil, why end
	if os.clock() - (lastSend[plr] or 0) < 3 then return nil, "one moment between gifts" end
	local info, why2 = canReach(plr, toId)
	if not info then return nil, why2 end
	local p = Profile.get(plr)
	if left(p).gifts <= 0 then return nil, "that's all the gifts you can send today: more tomorrow" end
	return info, p
end

local function noteOf(i)
	i = tonumber(i)
	return i and Gifting.NOTES[i] or nil
end

-- Marks, Crowns and items from what you have
function Gifting.send(plr, toId, what)
	toId = tonumber(toId)
	local info, p = precheck(plr, toId)
	if not info then return false, p end
	what = type(what) == "table" and what or {}
	local marks = math.max(0, math.floor(tonumber(what.marks) or 0))
	local crowns = math.max(0, math.floor(tonumber(what.crowns) or 0))
	local uids = type(what.items) == "table" and what.items or {}
	local items, count = {}, 0
	if #uids > 0 then
		local list, why = Trading.checkItems(plr, uids, Gifting.MAX_ITEMS)
		if not list then return false, why end
		items, count = list, #list
	end
	if marks == 0 and crowns == 0 and #items == 0 then return false, "pick something to send" end
	local L = left(p)
	if marks > L.marks then return false, string.format("you can send %d more Marks today", L.marks) end
	if crowns > L.crowns then return false, string.format("you can send %d more Crowns today", L.crowns) end
	if count > L.items then return false, string.format("you can send %d more items today", L.items) end
	if p.wallet.marks < marks then return false, string.format("not enough Marks (you need %d, you have %d)", marks, p.wallet.marks) end
	if p.wallet.crowns < crowns then return false, string.format("not enough Crowns (you need %d, you have %d)", crowns, p.wallet.crowns) end
	lastSend[plr] = os.clock()
	-- out of your hands (no yield until it's all taken)
	local gift = {id = newId(), from = plr.UserId, fromName = plr.DisplayName, at = os.time(), note = noteOf(what.note),
		marks = marks > 0 and marks or nil, crowns = crowns > 0 and crowns or nil, copies = {}}
	p.wallet.marks -= marks; p.wallet.crowns -= crowns
	for _, uid in ipairs(items) do
		local key, c = Profile.takeCopy(plr, uid)
		if key then c.tr = (c.tr or 0) + 1; table.insert(gift.copies, {key = key, c = c}) end
	end
	if (p.companion or "") ~= "" and not Profile.has(plr, "companions", p.companion) then p.companion = "" end
	local u = dayUse(p)
	u.marks += marks; u.crowns += crowns; u.items += count; u.gifts += 1
	local function undo()
		p.wallet.marks += marks; p.wallet.crowns += crowns
		for _, e in ipairs(gift.copies) do e.c.tr = math.max(0, (e.c.tr or 1) - 1); Profile.giveCopy(plr, e.key, e.c) end
		u.marks -= marks; u.crowns -= crowns; u.items -= count; u.gifts -= 1
		Profile.markDirty(plr)
	end
	-- your side saves first: nothing leaves that isn't gone from you for good
	if not Profile.save(plr) then undo(); return false, "couldn't save just now: nothing was sent" end
	local okPost, why = post(toId, gift)
	if not okPost then undo(); Profile.save(plr); return false, (why or "it couldn't be sent") .. ": nothing was sent" end
	if marks > 0 then Analytics.sink(plr, "Marks", marks, p.wallet.marks, "Gameplay", "Gift") end
	if crowns > 0 then Analytics.sink(plr, "Crowns", crowns, p.wallet.crowns, "Gameplay", "Gift") end
	pcall(function() Analytics.event(plr, "GiftSent", 1, marks > 0 and "marks" or "", crowns > 0 and "crowns" or "", count > 0 and "items" or "") end)
	logGift(plr, toId, gift)
	pcall(function() economy().changed:Fire(plr) end)
	return true, "🎁 sent to " .. (info.displayName or info.name) .. (info.here and "" or ": they'll get it next time they play")
end

-- anything in the shop, bought for them
function Gifting.buy(plr, toId, what)
	toId = tonumber(toId)
	local info, p = precheck(plr, toId)
	if not info then return false, p end
	what = type(what) == "table" and what or {}
	local E = economy()
	local q, why = E.giftQuote(tostring(what.kind or ""), tostring(what.id or ""), what.currency)
	if not q then return false, why end
	local m, c = q.marks or 0, q.crowns or 0
	if p.wallet.marks < m then return false, string.format("not enough Marks (you need %d, you have %d)", m, p.wallet.marks) end
	if p.wallet.crowns < c then return false, string.format("not enough Crowns (you need %d, you have %d)", c, p.wallet.crowns) end
	lastSend[plr] = os.clock()
	local gift = {id = newId(), from = plr.UserId, fromName = plr.DisplayName, at = os.time(), note = noteOf(what.note),
		label = q.label, grants = q.grants, pass = q.pass, passRefund = q.passRefund, skins = {}}
	local ok, msg = E.spend(plr, m, c, "Gift:" .. tostring(what.kind))
	if not ok then return false, msg end
	local u = dayUse(p)
	u.gifts += 1
	local function undo()
		p.wallet.marks += m; p.wallet.crowns += c; u.gifts -= 1
		Profile.markDirty(plr)
	end
	if not Profile.save(plr) then undo(); return false, "couldn't save just now: nothing was bought" end
	-- a numbered skin takes its number now (a limited one may just have sold out)
	for _, e in ipairs(q.skins or {}) do
		local n
		if q.serial == e.id then
			local s = Catalog.SKIN[e.id]
			n = Collection.serial(e.id, Collection.limitOf(s))
			if Collection.limitOf(s) and not n then undo(); Profile.save(plr); return false, "sold out: every one has been made" end
		end
		table.insert(gift.skins, {id = e.id, n = n})
	end
	local okPost, why2 = post(toId, gift)
	if not okPost then undo(); Profile.save(plr); return false, (why2 or "it couldn't be sent") .. ": nothing was bought" end
	logGift(plr, toId, gift)
	pcall(function() Analytics.event(plr, "GiftBought", 1, tostring(what.kind), tostring(what.id)) end)
	pcall(function() E.changed:Fire(plr) end)
	return true, "🎁 " .. q.label .. " bought for " .. (info.displayName or info.name)
end

-- a Crowns bundle for them, with Robux: the purchase is remembered on the buyer until Roblox's
-- receipt comes (Gifting.receipt), then it goes to their box; a cancelled prompt forgets it
function Gifting.buyCrowns(plr, toId, index, note)
	toId = tonumber(toId)
	local info, p = precheck(plr, toId)
	if not info then return false, p end
	local prod = Catalog.ECONOMY.products[tonumber(index) or 0]
	if not prod then return false, "no such bundle" end
	if (prod.id or 0) == 0 then return false, "that bundle isn't set up yet" end
	p.giftIntent = {to = toId, toName = info.displayName or info.name, product = prod.id, at = os.time(), note = tonumber(note)}
	Profile.markDirty(plr)
	local ok, err = pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, plr, prod.id)
	if not ok then p.giftIntent = nil; return false, "could not open the purchase: " .. tostring(err) end
	return true, "buying " .. prod.crowns .. " Crowns for " .. (info.displayName or info.name)
end
-- a plain Crowns purchase for yourself: no gift waiting on it
function Gifting.forget(plr)
	local p = Profile.get(plr)
	if p.giftIntent then p.giftIntent = nil; Profile.markDirty(plr) end
end
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, bought)
	if bought then return end
	local plr = Players:GetPlayerByUserId(userId)
	local p = plr and Profile.get(plr)
	if p and p.giftIntent and p.giftIntent.product == productId then p.giftIntent = nil; Profile.markDirty(plr) end
end)

-- EconomyServer's ProcessReceipt asks first -> handled (a gift), saved
function Gifting.receipt(plr, productId, receiptId)
	local p = Profile.get(plr)
	local it = p.giftIntent
	if not (type(it) == "table" and it.product == productId and os.time() - (it.at or 0) < 3 * 86400) then return false end
	if not Profile.ready(plr) then return true, false end
	if receiptId and p.receipts[receiptId] then return true, Profile.save(plr) end
	local prod
	for _, pr in ipairs(Catalog.ECONOMY.products) do if pr.id == productId then prod = pr end end
	if not prod then return false end
	-- (the receipt's id is the gift's: a receipt Roblox sends twice is still one gift)
	local gift = {id = "r" .. tostring(receiptId), from = plr.UserId, fromName = plr.DisplayName, at = os.time(), note = noteOf(it.note),
		crowns = prod.crowns, label = prod.crowns .. " Crowns"}
	local ok = post(it.to, gift)
	if not ok then return true, false end   -- (Roblox asks again later)
	if receiptId then p.receipts[receiptId] = true end
	p.giftIntent = nil
	Profile.markDirty(plr)
	Analytics.event(plr, "GiftCrowns", prod.crowns)
	logGift(plr, it.to, gift)
	tell(plr, "Toast", "🎁 " .. prod.crowns .. " Crowns sent to " .. tostring(it.toName))
	return true, Profile.save(plr)
end

--------------------------------------------------------------------
--  KEEPING UP
--------------------------------------------------------------------
pcall(function()
	MessagingService:SubscribeAsync(TOPIC, function(msg)
		local d = msg and msg.Data
		local plr = type(d) == "table" and Players:GetPlayerByUserId(tonumber(d.to) or 0)
		if plr then task.spawn(Gifting.claim, plr) end
	end)
end)
Players.PlayerAdded:Connect(function(plr)
	task.delay(8, function() if plr.Parent then Profile.get(plr); Gifting.claim(plr) end end)
end)
Players.PlayerRemoving:Connect(function(plr) lastSend[plr], lastFind[plr], claiming[plr] = nil, nil, nil end)
task.spawn(function()
	while true do
		task.wait(CHECK_EVERY)
		for _, plr in ipairs(Players:GetPlayers()) do task.spawn(Gifting.claim, plr); task.wait(0.5) end
	end
end)

-- one call from HubServer for every "Gift…" op
function Gifting.op(plr, op, a, b, c)
	if op == "GiftFind" then return Gifting.find(plr, a)
	elseif op == "GiftInfo" then return Gifting.info(plr) end
	local ok, msg
	if op == "GiftSend" then ok, msg = Gifting.send(plr, a, b)
	elseif op == "GiftBuy" then ok, msg = Gifting.buy(plr, a, b)
	elseif op == "GiftCrowns" then ok, msg = Gifting.buyCrowns(plr, a, b, c)
	else return {ok = false, msg = "no such thing"} end
	local out = Gifting.info(plr)
	out.ok, out.msg, out.profile = ok == true, msg, Profile.summary(plr)
	return out
end

return Gifting
