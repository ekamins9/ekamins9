--[[ HUB SERVER — everything the main menu (HubMenu) needs that isn't combat:
       • PLAY:    start a mode — teleport to its place, or (single place) ask
                  this server to switch (Game.requestMode)
       • SERVERS: the browser. Every server heartbeats itself into a
                  MemoryStore SortedMap ("Servers") with mode / map / players;
                  the menu lists them, filters client-side, joins by JobId
       • FRIENDS: who's online in this game, join them by instance
       • PARTY:   invite / accept / leave; parties teleport together and the
                  Party attribute keeps them on one team (Teams)
       • ARMORY:  save a loadout per class, set the active class
       • ENTER:   spawn into the courtyard (Hub mode) to walk around

       ReplicatedStorage.HubRemote (RemoteFunction) client -> op, ... -> result
       ReplicatedStorage.HubEvent  (RemoteEvent)    server -> "Party", partyInfo | "Toast", text | "Invite", fromName, fromId

     MemoryStore / TeleportService need a published game; in Studio the browser
     just shows this server and Play switches modes locally. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Game       = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Game"))
local Profile    = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))

local function log(...) DebugFlags.log("Hub", ...) end

local remote = Instance.new("RemoteFunction")
remote.Name = "HubRemote"
remote.Parent = ReplicatedStorage
local event = Instance.new("RemoteEvent")
event.Name = "HubEvent"
event.Parent = ReplicatedStorage

local function toast(plr, text) event:FireClient(plr, "Toast", text) end

--------------------------------------------------------------------
--  SERVER REGISTRY (browser)
--------------------------------------------------------------------
local HEARTBEAT, EXPIRY = 20, 60
local map
pcall(function() map = MemoryStoreService:GetSortedMap("Servers") end)
local customName = nil   -- set for reserved/custom servers via teleport data

local function entry()
	local node = Game.node
	return {
		jobId = game.JobId, placeId = game.PlaceId,
		mode = node:GetAttribute("Mode") or "", modeName = node:GetAttribute("ModeName") or "",
		category = node:GetAttribute("Category") or "", map = node:GetAttribute("Map") or "",
		players = #Players:GetPlayers(), max = Players.MaxPlayers,
		custom = customName ~= nil, name = customName or "", state = node:GetAttribute("State") or "",
		updated = os.time(),
	}
end

task.spawn(function()
	while true do
		if map and not RunService:IsStudio() or (map and RunService:IsStudio()) then
			pcall(function() map:SetAsync(game.JobId ~= "" and game.JobId or "studio", entry(), EXPIRY) end)
		end
		task.wait(HEARTBEAT)
	end
end)

local function listServers()
	local out = {}
	if map then
		local ok, items = pcall(function() return map:GetRangeAsync(Enum.SortDirection.Ascending, 200) end)
		if ok and items then
			for _, it in ipairs(items) do
				if type(it.value) == "table" then
					it.value.here = (it.value.jobId == game.JobId)
					table.insert(out, it.value)
				end
			end
		end
	end
	local seen = false
	for _, e in ipairs(out) do if e.here then seen = true end end
	if not seen then local e = entry(); e.here = true; table.insert(out, e) end
	table.sort(out, function(a, b) return (a.players or 0) > (b.players or 0) end)
	return out
end

--------------------------------------------------------------------
--  PARTY
--------------------------------------------------------------------
local parties = {}   -- [leaderUserId] = {leader = Player, members = {Player...}}
local invites = {}   -- [invitee Player] = leaderUserId

local function partyOf(plr)
	local id = plr:GetAttribute("Party")
	return id and parties[id] or nil
end

local function partyInfo(party)
	if not party then return nil end
	local names = {}
	for _, m in ipairs(party.members) do table.insert(names, {name = m.DisplayName, id = m.UserId, leader = m == party.leader}) end
	return {leaderId = party.leader.UserId, leaderName = party.leader.DisplayName, members = names}
end

local function broadcast(party)
	local info = partyInfo(party)
	for _, m in ipairs(party.members) do event:FireClient(m, "Party", info) end
end

local function leaveParty(plr)
	local party = partyOf(plr)
	plr:SetAttribute("Party", nil)
	if not party then return end
	for i, m in ipairs(party.members) do if m == plr then table.remove(party.members, i); break end end
	event:FireClient(plr, "Party", nil)
	if #party.members == 0 then parties[party.leader.UserId] = nil; return end
	if party.leader == plr then
		party.leader = party.members[1]
		parties[party.leader.UserId] = party
		parties[plr.UserId] = nil
		for _, m in ipairs(party.members) do m:SetAttribute("Party", party.leader.UserId) end
	end
	broadcast(party)
end

local function createParty(plr)
	leaveParty(plr)
	local party = {leader = plr, members = {plr}}
	parties[plr.UserId] = party
	plr:SetAttribute("Party", plr.UserId)
	broadcast(party)
	return party
end

local function invite(plr, targetId)
	local target = Players:GetPlayerByUserId(targetId)
	if not target or target == plr then return false, "they're not in this server" end
	local party = partyOf(plr) or createParty(plr)
	if party.leader ~= plr then return false, "only the leader invites" end
	if #party.members >= 6 then return false, "party is full" end
	invites[target] = plr.UserId
	event:FireClient(target, "Invite", plr.DisplayName, plr.UserId)
	return true, "invited " .. target.DisplayName
end

local function accept(plr)
	local leaderId = invites[plr]
	local party = leaderId and parties[leaderId]
	invites[plr] = nil
	if not party then return false, "that invite expired" end
	leaveParty(plr)
	table.insert(party.members, plr)
	plr:SetAttribute("Party", party.leader.UserId)
	broadcast(party)
	return true, "joined " .. party.leader.DisplayName .. "'s party"
end

Players.PlayerRemoving:Connect(function(plr) leaveParty(plr); invites[plr] = nil end)

--------------------------------------------------------------------
--  PLAY / JOIN
--------------------------------------------------------------------
local function groupFor(plr)
	local party = partyOf(plr)
	if party and party.leader == plr then return party.members end
	if party then return nil, "only the party leader picks where you go" end
	return {plr}
end

local function teleport(players, placeId, data, jobId)
	local opts = Instance.new("TeleportOptions")
	opts:SetTeleportData(data or {})
	if jobId then opts.ServerInstanceId = jobId end
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, placeId, players, opts)
	if not ok then warn("[Hub] teleport failed:", err) end
	return ok, ok and "travelling…" or "teleport failed (published game only)"
end

local function play(plr, modeId)
	local def = GameConfig.MODES[modeId]
	if not def or def.hidden then return false, "no such mode" end
	local group, why = groupFor(plr)
	if not group then return false, why end
	local placeId = GameConfig.placeFor(modeId)
	if placeId then return teleport(group, placeId, {mode = modeId}) end
	local ok, msg = Game.requestMode(plr, modeId)
	return ok, msg
end

local function joinServer(plr, jobId, placeId)
	if type(jobId) ~= "string" or jobId == "" then return false, "bad server" end
	if jobId == game.JobId then return false, "you're already here" end
	local group, why = groupFor(plr)
	if not group then return false, why end
	return teleport(group, placeId or game.PlaceId, {}, jobId)
end

local function joinFriend(plr, userId)
	if type(userId) ~= "number" then return false, "bad user" end
	local group, why = groupFor(plr)
	if not group then return false, why end
	local ok, inGame, err, placeId, jobId = pcall(TeleportService.GetPlayerPlaceInstanceAsync, TeleportService, userId)
	if not ok or not inGame then return false, "they're not in this game" end
	if jobId == game.JobId then return false, "they're in this server" end
	return teleport(group, placeId, {}, jobId)
end

local function friendsOnline(plr)
	local out = {}
	local ok, list = pcall(plr.GetFriendsOnline, plr, 50)
	if ok and list then
		for _, f in ipairs(list) do
			local here = Players:GetPlayerByUserId(f.VisitorId) ~= nil
			table.insert(out, {id = f.VisitorId, name = f.UserName, inGame = f.GameId == game.GameId or here, here = here, placeId = f.PlaceId})
		end
	end
	-- in Studio GetFriendsOnline is empty: list the other players here instead
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= plr then
			local dup = false
			for _, f in ipairs(out) do if f.id == p.UserId then dup = true end end
			if not dup then table.insert(out, {id = p.UserId, name = p.Name, inGame = true, here = true}) end
		end
	end
	return out
end

--------------------------------------------------------------------
--  ARMORY
--------------------------------------------------------------------
local function catalog() return _G.LoadoutCatalog end

local function saveClass(plr, classId, loadout)
	local C = catalog()
	if not C or not GameConfig.CLASSES[classId] then return false, "no such class" end
	local valid = C.validate(classId, loadout)
	if not valid then return false, "invalid loadout" end
	Profile.setClass(plr, classId, valid)
	return true, valid
end

--------------------------------------------------------------------
--  REMOTES
--------------------------------------------------------------------
local lastCall = {}
remote.OnServerInvoke = function(plr, op, a, b, c)
	-- light rate limit
	local now = os.clock()
	if now - (lastCall[plr] or 0) < 0.15 then return {ok = false, msg = "slow down"} end
	lastCall[plr] = now

	if op == "State" then
		return {ok = true, singlePlace = GameConfig.singlePlace(), placeId = game.PlaceId, jobId = game.JobId,
			party = partyInfo(partyOf(plr)), profile = {active = Profile.get(plr).active, stats = Profile.get(plr).stats}}
	elseif op == "Servers" then
		return {ok = true, servers = listServers()}
	elseif op == "Friends" then
		return {ok = true, friends = friendsOnline(plr)}
	elseif op == "Play" then
		local ok, msg = play(plr, a); return {ok = ok, msg = msg}
	elseif op == "Join" then
		local ok, msg = joinServer(plr, a, b); return {ok = ok, msg = msg}
	elseif op == "JoinFriend" then
		local ok, msg = joinFriend(plr, a); return {ok = ok, msg = msg}
	elseif op == "PartyCreate" then
		createParty(plr); return {ok = true, party = partyInfo(partyOf(plr))}
	elseif op == "PartyInvite" then
		local ok, msg = invite(plr, a); return {ok = ok, msg = msg, party = partyInfo(partyOf(plr))}
	elseif op == "PartyAccept" then
		local ok, msg = accept(plr); return {ok = ok, msg = msg, party = partyInfo(partyOf(plr))}
	elseif op == "PartyLeave" then
		leaveParty(plr); return {ok = true}
	elseif op == "SaveClass" then
		local ok, res = saveClass(plr, a, b); return {ok = ok, loadout = ok and res or nil, msg = (not ok) and res or nil}
	elseif op == "SetActive" then
		Profile.setActive(plr, a); return {ok = true}
	elseif op == "Enter" then
		-- walk the courtyard: only meaningful in the Hub mode (elsewhere the class screen spawns you)
		if Game.modeId ~= "Hub" then return {ok = false, msg = "not in the courtyard"} end
		local ev = ReplicatedStorage:FindFirstChild("LoadoutEvent")
		return {ok = ev ~= nil}
	end
	return {ok = false, msg = "unknown op"}
end

Players.PlayerAdded:Connect(function(plr)
	local ok, data = pcall(plr.GetJoinData, plr)
	local td = ok and data and data.TeleportData
	if type(td) == "table" and type(td.customName) == "string" then customName = td.customName:sub(1, 32) end
end)

log("ready —", GameConfig.singlePlace() and "single-place mode" or ("place " .. tostring(GameConfig.thisPlace())))
