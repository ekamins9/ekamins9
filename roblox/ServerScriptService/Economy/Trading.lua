--[[ TRADING — two players in the same server swap copies of skins and
     companions (Profile copies). Server-authoritative from first click to last:

       request → the other accepts → both put up their side (up to MAX items) →
       both press READY → a COUNTDOWN runs (any change to either side stops it
       and un-readies both) → both CONFIRM → the server checks every copy is
       still theirs and still tradable, swaps them in one step, and saves both
       profiles at once.

     What can be traded: copies of crate and shop skins, hatched companions
     (Collection.tradable). Never: Founder gifts, claims, pass rewards, earned
     and pack skins (bound to whoever got them), Marks or Crowns.
     Who can trade: level MIN_LEVEL and up, and only where Roblox allows trading
     paid items (PolicyService IsPaidItemTradingAllowed).
     A copy keeps its number, its finish and where it first came from; it
     counts how many times it has changed hands (tr).

       Trading.request(plr, userId) / accept(plr, userId) / decline(plr, userId)
       Trading.offer(plr, {copyId, …}) / ready(plr, on) / confirm(plr) / cancel(plr)
       Trading.view(plr)                    the trade as that player sees it ]]

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Profile = require(script.Parent.Parent:WaitForChild("Loadout"):WaitForChild("Profile"))
local Collection = require(script.Parent:WaitForChild("Collection"))

local Trading = {}
local CFG = (Catalog.ECONOMY.trading or {})
Trading.MIN_LEVEL = CFG.minLevel or 5
Trading.MAX = CFG.maxItems or 8
Trading.COUNTDOWN = CFG.countdown or 5
Trading.INVITE_LIFE = 30

local function log(...) DebugFlags.log("Economy", ...) end
local logStore
pcall(function() logStore = DataStoreService:GetDataStore("TradeLog_v1") end)

local function event() return ReplicatedStorage:FindFirstChild("HubEvent") end
local function send(plr, ...) local ev = event(); if ev and plr.Parent then ev:FireClient(plr, ...) end end

--------------------------------------------------------------------
--  WHO MAY TRADE
--------------------------------------------------------------------
local policy = {}
local function checkPolicy(plr)
	local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, plr)
	policy[plr] = ok and type(info) == "table" and info.IsPaidItemTradingAllowed == true
	if RunService:IsStudio() and ok then policy[plr] = info.IsPaidItemTradingAllowed ~= false end
end
Players.PlayerAdded:Connect(function(plr) task.spawn(checkPolicy, plr) end)
for _, plr in ipairs(Players:GetPlayers()) do task.spawn(checkPolicy, plr) end

function Trading.allowed(plr)
	if policy[plr] == nil then checkPolicy(plr) end
	if not policy[plr] then return false, "trading isn't available in your region" end
	if (Profile.get(plr).level or 1) < Trading.MIN_LEVEL then return false, "trading opens at level " .. Trading.MIN_LEVEL end
	return true
end
Profile.tradingHook = function(plr)
	local ok, why = Trading.allowed(plr)
	return {ok = ok, why = why, minLevel = Trading.MIN_LEVEL, max = Trading.MAX}
end

--------------------------------------------------------------------
--  SESSIONS
--------------------------------------------------------------------
local invites = {}     -- [target] = {[from] = time}
local byPlayer = {}    -- plr -> session
local nextId = 0

local function other(s, plr) return s.a == plr and s.b or s.a end

local function copyView(p, uid)
	local key, c = Profile.findCopy(p, uid)
	if not key then return nil end
	return {u = c.u, key = key, n = c.n, v = c.v, from = c.from, at = c.at, tr = c.tr}
end

function Trading.view(plr)
	local s = byPlayer[plr]
	if not s then return nil end
	local function side(who)
		local p = Profile.get(who)
		local items = {}
		for _, uid in ipairs(s.offer[who]) do local v = copyView(p, uid); if v then table.insert(items, v) end end
		return {name = who.DisplayName, userId = who.UserId, items = items, ready = s.ready[who] == true, confirmed = s.confirmed[who] == true}
	end
	local left = s.readyAt and math.max(0, s.readyAt + Trading.COUNTDOWN - os.clock()) or nil
	return {id = s.id, you = side(plr), them = side(other(s, plr)), countdown = left, max = Trading.MAX}
end

local function push(s)
	for _, who in ipairs({s.a, s.b}) do send(who, "Trade", Trading.view(who)) end
end

local function close(s, why)
	byPlayer[s.a], byPlayer[s.b] = nil, nil
	s.closed = true
	for _, who in ipairs({s.a, s.b}) do send(who, "Trade", nil, why) end
end

function Trading.request(plr, userId)
	local ok, why = Trading.allowed(plr)
	if not ok then return false, why end
	local target = Players:GetPlayerByUserId(tonumber(userId) or 0)
	if not target or target == plr then return false, "they aren't in this server" end
	-- their privacy (Settings ▸ Trade requests from)
	local priv = target:GetAttribute("Priv_TradeRequests") or "Everyone"
	if priv == "Nobody" then return false, target.DisplayName .. " isn't taking trade requests" end
	if priv == "Friends" then
		local okF, isFriend = pcall(plr.IsFriendsWith, plr, target.UserId)
		if not (okF and isFriend) then return false, target.DisplayName .. " only trades with friends" end
	end
	local ok2, why2 = Trading.allowed(target)
	if not ok2 then return false, target.DisplayName .. " can't trade (" .. why2 .. ")" end
	if byPlayer[plr] then return false, "finish your current trade first" end
	if byPlayer[target] then return false, target.DisplayName .. " is already trading" end
	invites[target] = invites[target] or {}
	invites[target][plr] = os.clock()
	send(target, "TradeInvite", {name = plr.DisplayName, userId = plr.UserId})
	return true, "trade request sent to " .. target.DisplayName
end

function Trading.decline(plr, userId)
	local from = Players:GetPlayerByUserId(tonumber(userId) or 0)
	if from and invites[plr] then invites[plr][from] = nil end
	if from then send(from, "Toast", plr.DisplayName .. " declined the trade") end
	return true
end

function Trading.accept(plr, userId)
	local from = Players:GetPlayerByUserId(tonumber(userId) or 0)
	local at = from and invites[plr] and invites[plr][from]
	if not at or os.clock() - at > Trading.INVITE_LIFE then return false, "that request has expired" end
	invites[plr][from] = nil
	if byPlayer[plr] or byPlayer[from] then return false, "one of you is already trading" end
	local ok, why = Trading.allowed(plr); if not ok then return false, why end
	nextId += 1
	local s = {id = nextId, a = from, b = plr, offer = {[from] = {}, [plr] = {}}, ready = {}, confirmed = {}}
	byPlayer[from], byPlayer[plr] = s, s
	push(s)
	return true
end

-- any change: both un-ready, the countdown stops
local function unready(s)
	s.ready, s.confirmed, s.readyAt = {}, {}, nil
end

function Trading.offer(plr, uids)
	local s = byPlayer[plr]
	if not s then return false, "you aren't trading" end
	if type(uids) ~= "table" then return false, "bad offer" end
	local p = Profile.get(plr)
	local list, seen = {}, {}
	for _, uid in ipairs(uids) do
		if type(uid) ~= "string" or seen[uid] then continue end
		local key, c = Profile.findCopy(p, uid)
		if not key then return false, "you don't have that any more" end
		if c.b or not Collection.tradable(key) then return false, "that one can't be traded" end
		if #list >= Trading.MAX then return false, "at most " .. Trading.MAX .. " items a side" end
		seen[uid] = true
		table.insert(list, uid)
	end
	s.offer[plr] = list
	unready(s)
	push(s)
	return true
end

function Trading.ready(plr, on)
	local s = byPlayer[plr]
	if not s then return false, "you aren't trading" end
	if #s.offer[s.a] == 0 and #s.offer[s.b] == 0 then return false, "put something up first" end
	s.ready[plr] = on ~= false or nil
	s.confirmed = {}
	s.readyAt = (s.ready[s.a] and s.ready[s.b]) and os.clock() or nil
	push(s)
	if s.readyAt then
		local id = s.id
		task.delay(Trading.COUNTDOWN + 0.05, function() if not s.closed and s.id == id then push(s) end end)
	end
	return true
end

local function execute(s)
	local pa, pb = Profile.get(s.a), Profile.get(s.b)
	-- everything still where it was, still tradable
	for _, side in ipairs({{s.a, pa}, {s.b, pb}}) do
		for _, uid in ipairs(s.offer[side[1]]) do
			local key, c = Profile.findCopy(side[2], uid)
			if not key or c.b or not Collection.tradable(key) then return false, "something changed: check both sides again" end
		end
	end
	-- the swap: no yield between taking and giving
	local moved = {}
	for _, side in ipairs({{s.a, s.b}, {s.b, s.a}}) do
		local giver, taker = side[1], side[2]
		for _, uid in ipairs(s.offer[giver]) do
			local key, c = Profile.takeCopy(giver, uid)
			if key then
				c.tr = (c.tr or 0) + 1
				Profile.giveCopy(taker, key, c)
				table.insert(moved, {key = key, n = c.n, v = c.v, from = giver.UserId, to = taker.UserId})
			end
		end
	end
	-- a companion out with you that you traded away goes home
	for _, who in ipairs({s.a, s.b}) do
		local p = Profile.get(who)
		if (p.companion or "") ~= "" and not Profile.has(who, "companions", p.companion) then p.companion = "" end
	end
	task.spawn(Profile.save, s.a)
	task.spawn(Profile.save, s.b)
	if logStore then
		task.spawn(function()
			pcall(logStore.SetAsync, logStore, string.format("t%d_%d_%d", os.time(), s.a.UserId, s.b.UserId), {at = os.time(), a = s.a.UserId, b = s.b.UserId, moved = moved})
		end)
	end
	log("trade", s.a.Name, "<->", s.b.Name, #moved, "items")
	return true
end

function Trading.confirm(plr)
	local s = byPlayer[plr]
	if not s then return false, "you aren't trading" end
	if not (s.readyAt and s.ready[s.a] and s.ready[s.b]) then return false, "both of you must be ready" end
	if os.clock() < s.readyAt + Trading.COUNTDOWN then return false, "wait for the countdown" end
	s.confirmed[plr] = true
	if s.confirmed[s.a] and s.confirmed[s.b] then
		local ok, why = execute(s)
		if ok then
			local Economy = require(script.Parent:WaitForChild("Economy"))
			Economy.changed:Fire(s.a); Economy.changed:Fire(s.b)
			close(s, "done")
		else
			unready(s); push(s)
			return false, why
		end
		return true
	end
	push(s)
	return true
end

function Trading.cancel(plr)
	local s = byPlayer[plr]
	if not s then return true end
	close(s, plr.DisplayName .. " cancelled the trade")
	return true
end

Players.PlayerRemoving:Connect(function(plr)
	invites[plr] = nil
	for _, list in pairs(invites) do list[plr] = nil end
	local s = byPlayer[plr]
	if s then close(s, plr.DisplayName .. " left") end
	policy[plr] = nil
end)

return Trading
