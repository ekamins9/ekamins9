--[[ HUB SERVER — everything the main menu (HubMenu) needs that isn't combat:
       • PLAY:    teleport to the mode's place (GameConfig.PLACES; Roblox joins
                  a server with room or starts one). A place never changes
                  mode. Studio has no teleports: PLAY switches the mode
                  locally there (Game.requestMode) so it can all be tested.
       • HUB:     RETURN TO HUB — teleport back to the start place
       • CUSTOM:  a named custom server of a mode (TeleportService:ReserveServer);
                  it shows in the browser as custom and is joined by access code
       • SERVERS: the browser. Every server heartbeats itself into a
                  MemoryStore SortedMap ("Servers") with mode / map / players;
                  the menu lists them, filters client-side, joins by JobId
       • FRIENDS: who's online in this game, join them by instance
       • PARTY:   invite / accept / leave; parties teleport together (carried
                  in TeleportData and rebuilt on arrival) and the Party
                  attribute keeps them on one team (Teams)
       • ARMORY:  save a loadout per class, set the active class

       ReplicatedStorage.HubRemote (RemoteFunction) client -> op, ... -> result
       ReplicatedStorage.HubEvent  (RemoteEvent)    server -> "Party", partyInfo | "Toast", text | "Invite", fromName, fromId

     MemoryStore / TeleportService need a published game; in Studio the browser
     just shows this server. ]]

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

local STUDIO = RunService:IsStudio()
local PARTY_MAX = 6

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
local registry
pcall(function() registry = MemoryStoreService:GetSortedMap("Servers") end)
-- a custom (reserved) server learns its name + access code from the first
-- arrival's TeleportData and advertises both, so the browser can join it
local customName, accessCode = nil, nil

local function entry()
	local node = Game.node
	return {
		jobId = game.JobId, placeId = game.PlaceId,
		mode = node:GetAttribute("Mode") or "", modeName = node:GetAttribute("ModeName") or "",
		category = node:GetAttribute("Category") or "", map = node:GetAttribute("Map") or "",
		players = #Players:GetPlayers(), max = Players.MaxPlayers,
		custom = customName ~= nil, name = customName or "", accessCode = accessCode,
		state = node:GetAttribute("State") or "", updated = os.time(),
	}
end

local function myKey() return game.JobId ~= "" and game.JobId or "studio" end

task.spawn(function()
	while true do
		if registry then pcall(function() registry:SetAsync(myKey(), entry(), EXPIRY) end) end
		task.wait(HEARTBEAT)
	end
end)
game:BindToClose(function()
	if registry then pcall(function() registry:RemoveAsync(myKey()) end) end
end)

local function listServers()
	local out = {}
	if registry then
		local ok, items = pcall(function() return registry:GetRangeAsync(Enum.SortDirection.Ascending, 200) end)
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

local function findServer(jobId)
	for _, e in ipairs(listServers()) do if e.jobId == jobId then return e end end
	return nil
end

--------------------------------------------------------------------
--  PARTY
--------------------------------------------------------------------
local parties = {}   -- [leaderUserId] = {leader = Player, members = {Player...}}
local invites = {}   -- [invitee Player] = leaderUserId
local carried = {}   -- [original leader UserId] = party, for a party arriving by teleport

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

local function setLeader(party, plr)
	parties[party.leader.UserId] = nil
	party.leader = plr
	parties[plr.UserId] = party
	for _, m in ipairs(party.members) do m:SetAttribute("Party", plr.UserId) end
end

local function leaveParty(plr)
	local party = partyOf(plr)
	plr:SetAttribute("Party", nil)
	if not party then return end
	for i, m in ipairs(party.members) do if m == plr then table.remove(party.members, i); break end end
	event:FireClient(plr, "Party", nil)
	if #party.members == 0 then
		parties[party.leader.UserId] = nil
		for k, p in pairs(carried) do if p == party then carried[k] = nil end end
		return
	end
	if party.leader == plr then setLeader(party, party.members[1]) end
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

local function joinParty(party, plr)
	leaveParty(plr)
	table.insert(party.members, plr)
	plr:SetAttribute("Party", party.leader.UserId)
	broadcast(party)
end

local function invite(plr, targetId)
	local target = Players:GetPlayerByUserId(targetId)
	if not target or target == plr then return false, "they're not in this server" end
	local party = partyOf(plr) or createParty(plr)
	if party.leader ~= plr then return false, "only the leader invites" end
	if #party.members >= PARTY_MAX then return false, "party is full" end
	invites[target] = plr.UserId
	event:FireClient(target, "Invite", plr.DisplayName, plr.UserId)
	return true, "invited " .. target.DisplayName
end

local function accept(plr)
	local leaderId = invites[plr]
	local party = leaderId and parties[leaderId]
	invites[plr] = nil
	if not party then return false, "that invite expired" end
	if #party.members >= PARTY_MAX then return false, "party is full" end
	joinParty(party, plr)
	return true, "joined " .. party.leader.DisplayName .. "'s party"
end

-- a party that teleported here together: TeleportData.party = {leader=, members={ids}}
local function arrivedWithParty(plr, td)
	local info = type(td) == "table" and td.party
	if type(info) ~= "table" or type(info.leader) ~= "number" then return end
	local party = carried[info.leader]
	if not party then
		party = createParty(plr)
		carried[info.leader] = party
	else
		joinParty(party, plr)
	end
	if plr.UserId == info.leader and party.leader ~= plr then setLeader(party, plr); broadcast(party) end
end

Players.PlayerRemoving:Connect(function(plr) leaveParty(plr); invites[plr] = nil end)

--------------------------------------------------------------------
--  TRAVEL: play / hub / custom / join
--------------------------------------------------------------------
-- who travels: the leader takes the party; a member goes alone (and leaves it)
local function groupFor(plr, leaderOnly)
	local party = partyOf(plr)
	if not party then return {plr} end
	if party.leader == plr then return party.members end
	if leaderOnly then return nil, "only the party leader picks where you go" end
	leaveParty(plr)
	return {plr}
end

local function teleport(players, placeId, data, jobId, code)
	local opts = Instance.new("TeleportOptions")
	data = data or {}
	if #players > 1 then
		local ids = {}
		for _, p in ipairs(players) do table.insert(ids, p.UserId) end
		data.party = {leader = players[1].UserId, members = ids}
	end
	opts:SetTeleportData(data)
	if code then opts.ReservedServerAccessCode = code elseif jobId then opts.ServerInstanceId = jobId end
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, placeId, players, opts)
	if not ok then warn("[Hub] teleport failed:", err) end
	return ok, ok and "travelling…" or "teleport failed (published game only)"
end

local function play(plr, modeId)
	local def = GameConfig.MODES[modeId]
	if not def then return false, "no such mode" end
	local group, why = groupFor(plr, true)
	if not group then return false, why end
	if STUDIO then
		-- no teleports in Studio: switch this server instead (dev convenience)
		local ok, msg = Game.requestMode(plr, modeId)
		return ok, ok and ("Studio: switching this server — " .. msg) or msg
	end
	if modeId == Game.modeId then return false, "you're already in " .. def.name end
	local placeId = GameConfig.placeFor(modeId)
	if not placeId then return false, def.name .. "'s place isn't published yet (GameConfig.PLACES)" end
	return teleport(group, placeId, {})
end

local function goHub(plr)
	if Game.modeId == "Hub" then return false, "you're in the Hub" end
	local group = groupFor(plr, false)
	if STUDIO then
		local ok, msg = Game.requestMode(plr, "Hub")
		return ok, ok and ("Studio: switching this server — " .. msg) or msg
	end
	local placeId = GameConfig.placeFor("Hub")
	if not placeId then return false, "the Hub place id isn't in GameConfig.PLACES" end
	return teleport(group, placeId, {})
end

local function custom(plr, modeId, name)
	local def = GameConfig.MODES[modeId]
	if not def or modeId == "Hub" then return false, "no such mode" end
	local group, why = groupFor(plr, true)
	if not group then return false, why end
	local placeId = GameConfig.placeFor(modeId)
	if STUDIO or not placeId then return false, STUDIO and "custom servers need a published game" or (def.name .. "'s place isn't published yet") end
	name = type(name) == "string" and name:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 32) or ""
	if name == "" then name = plr.DisplayName .. "'s server" end
	local ok, code = pcall(TeleportService.ReserveServer, TeleportService, placeId)
	if not ok then warn("[Hub] ReserveServer failed:", code); return false, "could not reserve a server" end
	return teleport(group, placeId, {custom = {name = name, code = code}}, nil, code)
end

local function joinServer(plr, jobId, placeId)
	if type(jobId) ~= "string" or jobId == "" then return false, "bad server" end
	if jobId == game.JobId then return false, "you're already here" end
	local group, why = groupFor(plr, true)
	if not group then return false, why end
	local e = findServer(jobId)
	if e and (e.players or 0) >= (e.max or 1) then return false, "that server is full" end
	if e and e.custom and e.accessCode then return teleport(group, e.placeId or placeId, {}, nil, e.accessCode) end
	return teleport(group, placeId or game.PlaceId, {}, jobId)
end

local function joinFriend(plr, userId)
	if type(userId) ~= "number" then return false, "bad user" end
	local group, why = groupFor(plr, true)
	if not group then return false, why end
	local ok, inGame, err, placeId, jobId = pcall(TeleportService.GetPlayerPlaceInstanceAsync, TeleportService, userId)
	if not ok or not inGame then return false, "they're not in this game" end
	if jobId == game.JobId then return false, "they're in this server" end
	local e = findServer(jobId)
	if e and e.custom and e.accessCode then return teleport(group, placeId, {}, nil, e.accessCode) end
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
		return {ok = true, studio = STUDIO, placesReady = GameConfig.placesReady(), placeId = game.PlaceId, jobId = game.JobId,
			mode = Game.modeId, custom = customName, party = partyInfo(partyOf(plr)),
			profile = {active = Profile.get(plr).active, stats = Profile.get(plr).stats}}
	elseif op == "Servers" then
		return {ok = true, servers = listServers()}
	elseif op == "Friends" then
		return {ok = true, friends = friendsOnline(plr)}
	elseif op == "Play" then
		local ok, msg = play(plr, a); return {ok = ok, msg = msg}
	elseif op == "Hub" then
		local ok, msg = goHub(plr); return {ok = ok, msg = msg}
	elseif op == "Custom" then
		local ok, msg = custom(plr, a, b); return {ok = ok, msg = msg}
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
	end
	return {ok = false, msg = "unknown op"}
end

Players.PlayerAdded:Connect(function(plr)
	local ok, data = pcall(plr.GetJoinData, plr)
	local td = ok and data and data.TeleportData
	if type(td) == "table" then
		if type(td.custom) == "table" and customName == nil and game.PrivateServerId ~= "" then
			customName = tostring(td.custom.name or "custom"):sub(1, 32)
			accessCode = td.custom.code
			log("this is the custom server", customName)
		end
		arrivedWithParty(plr, td)
	end
end)

log("ready —", "mode", GameConfig.thisMode(), STUDIO and "(Studio: no teleports)" or (GameConfig.placesReady() and "" or "(some PLACES ids are 0)"))
