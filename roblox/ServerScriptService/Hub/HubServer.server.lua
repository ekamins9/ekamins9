--[[ HUB SERVER — everything the main menu (HubMenu) needs that isn't combat.
     ONE PLACE: public servers are the Hub (Courtyard); every match is a
     RESERVED server of this same place (see GameConfig.DOORS). A server
     never changes mode.

       • PLAY door:  Courtyard → a public server.  Tiltyard → a Friends-only
                     reserved server for you and your party.  Warfront → a
                     public Warfront server with room, else a fresh one.
                     The Lists → the matchmaking queue (Matchmaker).
                     Studio has no teleports: PLAY switches this server's mode.
       • PARTY:      invite / accept / leave, max GameConfig.PARTY_MAX, and
                     READY-UP: every member readies, the leader's PLAY only
                     goes when all are ready (reset on arrival and on leave).
                     Friends in OTHER servers can be invited too: the invite
                     travels by MessagingService, accepting teleports them
                     here with TeleportData.joinParty = the leader's id
       • CUSTOM:     a named server with the host's settings (mode, map, limit,
                     round length, access, friendly fire, respawns, ground
                     weapons, cheats → no rewards)
       • SERVERS:    the browser (MemoryStore SortedMap "Servers"; codes never
                     reach a client)   • FRIENDS: online, join by instance
       • SHOP:       Buy / OpenCrate / Exchange / BuyCrowns (Robux prompt)
       • ARMORY:     SaveClass / SetActive / SaveAppearance
       • BOARDS:     Leaderboard(bracket) from OrderedDataStores Scoreboard writes

       ReplicatedStorage.HubRemote (RemoteFunction)  client -> op, ... -> result
       ReplicatedStorage.HubEvent  (RemoteEvent)     server -> "Party", info | "Toast", text | "Invite", name, id
                                                     | "Profile", summary | "Travel", where | "TravelFailed"
                                                     | "MatchFound", info | "Rewards", table | "Crate", result ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Catalog    = require(ReplicatedStorage:WaitForChild("Catalog"))
local Game       = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Game"))
local Profile    = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Economy    = require(ServerScriptService:WaitForChild("Economy"):WaitForChild("Economy"))
local Stats      = require(ServerScriptService.Economy:WaitForChild("Stats"))
local Pastimes   = require(ServerScriptService.Economy:WaitForChild("Pastimes"))
local Matchmaker = require(script.Parent:WaitForChild("Matchmaker"))

local STUDIO = RunService:IsStudio()
local PARTY_MAX = GameConfig.PARTY_MAX or 3
local PENDING_TTL = 90      -- a freshly reserved server is advertised for this long until it heartbeats itself
local MATCH_OVER_DELAY = 12 -- seconds a finished Lists match shows its result before everyone goes home

local function log(...) DebugFlags.log("Hub", ...) end

local remote = Instance.new("RemoteFunction")
remote.Name = "HubRemote"
remote.Parent = ReplicatedStorage
local event = Instance.new("RemoteEvent")
event.Name = "HubEvent"
event.Parent = ReplicatedStorage

local function toast(plr, text) event:FireClient(plr, "Toast", text) end
local function pushProfile(plr) if plr.Parent then event:FireClient(plr, "Profile", Profile.summary(plr)) end end
Economy.changed.Event:Connect(pushProfile)
Stats.changed.Event:Connect(function(plr, text, pay)
	toast(plr, (pay or 0) > 0 and string.format("CONTRACT DONE  ·  %s  ·  +%d Marks", text, pay) or text)
	pushProfile(plr)
end)

--------------------------------------------------------------------
--  SERVER REGISTRY (browser)
--------------------------------------------------------------------
local HEARTBEAT, EXPIRY = 20, 60
local registry
pcall(function() registry = MemoryStoreService:GetSortedMap("Servers") end)
local accessCode = nil   -- a reserved server learns its code from its first arrival's TeleportData

local function entry()
	local node, sv = Game.node, Game.server
	local def = GameConfig.MODES[sv.mode or "Hub"]
	local members = {}
	for _, p in ipairs(Players:GetPlayers()) do table.insert(members, p.UserId) end
	local st = sv.settings
	return {
		jobId = game.JobId, placeId = game.PlaceId, reserved = sv.reserved,
		mode = sv.mode or node:GetAttribute("Mode") or "", modeName = node:GetAttribute("ModeName") or "",
		category = node:GetAttribute("Category") or "", map = node:GetAttribute("Map") or "",
		door = sv.door or "Warfront", bracket = sv.bracket, ranked = sv.ranked == true,
		players = #Players:GetPlayers(), max = (st and tonumber(st.limit)) or (def and def.maxPlayers) or Players.MaxPlayers,
		custom = sv.custom, name = sv.name or "", access = sv.access, hostId = sv.hostId,
		cheats = st and st.cheats == true or false, friendlyFire = not (st and st.friendlyFire == false),
		respawns = not (st and st.respawns == false),
		accessCode = accessCode, members = members,
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

-- what a client may see: Public servers (and this one), never a code or the member list
local function listForClient()
	local out = {}
	for _, e in ipairs(listServers()) do
		if (e.access == "Public" or e.here) and not (e.door == "Lists" and not e.here) then
			local c = {}
			for k, v in pairs(e) do if k ~= "accessCode" and k ~= "members" then c[k] = v end end
			table.insert(out, c)
		end
	end
	return out
end

local function findServer(jobId)
	for _, e in ipairs(listServers()) do if e.jobId == jobId then return e end end
	return nil
end

local function hasMember(e, userId)
	for _, id in ipairs(e.members or {}) do if id == userId then return true end end
	return false
end

local function mayEnter(plr, e)
	if (e.players or 0) >= (e.max or 1) then return false, "that server is full" end
	if e.access == "Public" or not e.reserved then return true end
	if e.access == "Locked" then return false, "that match is locked" end
	for _, id in ipairs(e.members or {}) do
		local ok, f = pcall(plr.IsFriendsWith, plr, id)
		if ok and f then return true end
	end
	return false, "that server is friends only"
end

--------------------------------------------------------------------
--  PARTY (with ready-up)
--------------------------------------------------------------------
local parties = {}   -- [leaderUserId] = {leader = Player, members = {Player...}, ready = {[Player]=true}}
local invites = {}   -- [invitee Player] = leaderUserId
local carried = {}   -- [original leader UserId] = party, for a party arriving by teleport
local remoteInvites = {}   -- [invitee Player] = {leader=, name=, jobId=, code=, placeId=, at=}  an invite from another server
local expected = {}        -- [userId] = {leader=, at=}  someone we invited from another server, due to arrive
local INVITE_TOPIC = "PartyInvite"
local INVITE_TTL = 90
local teleport, identityOf   -- forward (TRAVEL)

local function partyOf(plr)
	local id = plr:GetAttribute("Party")
	return id and parties[id] or nil
end

local function allReady(party)
	if #party.members <= 1 then return true end
	for _, m in ipairs(party.members) do if m ~= party.leader and not party.ready[m] then return false end end
	return true
end

local function partyInfo(party)
	if not party then return nil end
	local list = {}
	for _, m in ipairs(party.members) do
		local p = Profile.get(m)
		table.insert(list, {name = m.DisplayName, id = m.UserId, leader = m == party.leader,
			ready = m == party.leader or party.ready[m] == true, class = p.active, level = p.level})
	end
	return {leaderId = party.leader.UserId, leaderName = party.leader.DisplayName, members = list,
		allReady = allReady(party), max = PARTY_MAX, queue = party.ticket and Matchmaker.status(party.ticket) or nil,
		bracket = party.bracket, ranked = party.ranked}
end

local function broadcast(party)
	local info = partyInfo(party)
	for _, m in ipairs(party.members) do event:FireClient(m, "Party", info) end
end

local function unready(party) party.ready = {}; end

local function setLeader(party, plr)
	parties[party.leader.UserId] = nil
	party.leader = plr
	parties[plr.UserId] = party
	for _, m in ipairs(party.members) do m:SetAttribute("Party", plr.UserId) end
end

local cancelQueue   -- forward
local function leaveParty(plr)
	local party = partyOf(plr)
	plr:SetAttribute("Party", nil)
	if not party then return end
	if party.ticket then cancelQueue(party, "a member left the party") end
	for i, m in ipairs(party.members) do if m == plr then table.remove(party.members, i); break end end
	party.ready[plr] = nil
	event:FireClient(plr, "Party", nil)
	if #party.members == 0 then
		parties[party.leader.UserId] = nil
		for k, p in pairs(carried) do if p == party then carried[k] = nil end end
		return
	end
	if party.leader == plr then setLeader(party, party.members[1]) end
	unready(party)
	broadcast(party)
end

local function createParty(plr)
	leaveParty(plr)
	local party = {leader = plr, members = {plr}, ready = {}}
	parties[plr.UserId] = party
	plr:SetAttribute("Party", plr.UserId)
	broadcast(party)
	return party
end

local function joinParty(party, plr)
	leaveParty(plr)
	if party.ticket then cancelQueue(party, "the party changed") end
	table.insert(party.members, plr)
	plr:SetAttribute("Party", party.leader.UserId)
	unready(party)
	broadcast(party)
end

local function invite(plr, targetId, targetName)
	if type(targetId) ~= "number" or targetId == plr.UserId then return false, "bad user" end
	local target = Players:GetPlayerByUserId(targetId)
	local party = partyOf(plr) or createParty(plr)
	if party.leader ~= plr then return false, "only the leader invites" end
	if #party.members >= PARTY_MAX then return false, "party is full (" .. PARTY_MAX .. ")" end
	if target then
		invites[target] = plr.UserId
		event:FireClient(target, "Invite", plr.DisplayName, plr.UserId)
		return true, "invited " .. target.DisplayName
	end
	-- not here: a friend in another server. The invite rides MessagingService;
	-- accepting teleports them to this server, where joinInvited seats them.
	local okF, isFriend = pcall(plr.IsFriendsWith, plr, targetId)
	if not (okF and isFriend) then return false, "only friends can be invited from other servers" end
	if Game.server.door == "Lists" then return false, "no invites into a match" end
	if Game.server.access == "Locked" then return false, "this server is locked" end
	if Game.server.reserved and not accessCode then return false, "this server can't be joined from outside" end
	if STUDIO then return false, "cross-server invites need a published game" end
	expected[targetId] = {leader = plr.UserId, at = os.time()}
	local ok, err = pcall(MessagingService.PublishAsync, MessagingService, INVITE_TOPIC,
		{to = targetId, from = plr.UserId, name = plr.DisplayName, jobId = game.JobId, code = accessCode, placeId = game.PlaceId, at = os.time()})
	if not ok then expected[targetId] = nil; warn("[Hub] invite publish failed:", err); return false, "could not reach their server" end
	return true, "invited " .. tostring(targetName or targetId) .. " — they travel here when they accept"
end

-- an invite from another server lands here if its target is with us
pcall(function()
	MessagingService:SubscribeAsync(INVITE_TOPIC, function(msg)
		local d = type(msg) == "table" and msg.Data
		if type(d) ~= "table" or d.jobId == game.JobId then return end
		local target = Players:GetPlayerByUserId(d.to)
		if not target then return end
		remoteInvites[target] = {leader = d.from, name = d.name, jobId = d.jobId, code = d.code, placeId = d.placeId, at = os.time()}
		invites[target] = nil
		event:FireClient(target, "Invite", d.name, d.from, {remote = true})
	end)
end)

local function accept(plr)
	local ri = remoteInvites[plr]
	if ri and not invites[plr] then
		remoteInvites[plr] = nil
		if os.time() - ri.at > INVITE_TTL then return false, "that invite expired" end
		if STUDIO then return false, "no teleports in Studio" end
		local party = partyOf(plr)
		if party and party.leader == plr and #party.members > 1 then return false, "you lead a party — leave it first" end
		leaveParty(plr)
		local e = findServer(ri.jobId)
		local data = e and identityOf(e) or {}
		data.joinParty = ri.leader
		if ri.code then return teleport({plr}, ri.placeId or game.PlaceId, data, nil, ri.code, ri.name .. "'s party") end
		return teleport({plr}, ri.placeId or game.PlaceId, data, ri.jobId, nil, ri.name .. "'s party")
	end
	local leaderId = invites[plr]
	local party = leaderId and parties[leaderId]
	invites[plr] = nil
	if not party then return false, "that invite expired" end
	if #party.members >= PARTY_MAX then return false, "party is full" end
	joinParty(party, plr)
	return true, "joined " .. party.leader.DisplayName .. "'s party"
end

local function setReady(plr, ready)
	local party = partyOf(plr)
	if not party then return false, "you're not in a party" end
	if party.leader == plr then return false, "the leader is always ready — press PLAY when everyone is" end
	party.ready[plr] = ready and true or nil
	broadcast(party)
	if allReady(party) then toast(party.leader, "Everyone is ready") end
	return true, ready and "ready" or "not ready"
end

local function kickFromParty(plr, targetId)
	local party = partyOf(plr)
	if not party or party.leader ~= plr then return false, "only the leader can remove members" end
	local target = Players:GetPlayerByUserId(targetId)
	if not target or target == plr or partyOf(target) ~= party then return false, "they're not in your party" end
	leaveParty(target)
	toast(target, "You were removed from the party")
	return true, "removed " .. target.DisplayName
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

-- someone we invited from another server has arrived (TeleportData.joinParty)
local function joinInvited(plr, leaderId)
	local exp = expected[plr.UserId]
	expected[plr.UserId] = nil
	local party = parties[leaderId]
	if not exp or exp.leader ~= leaderId or os.time() - exp.at > INVITE_TTL * 2 then toast(plr, "That invite expired"); return end
	if not party then toast(plr, "That party is gone"); return end
	if #party.members >= PARTY_MAX then toast(plr, "That party is full now"); return end
	joinParty(party, plr)
	toast(plr, "Joined " .. party.leader.DisplayName .. "'s party")
	toast(party.leader, plr.DisplayName .. " joined your party")
end

Players.PlayerRemoving:Connect(function(plr) leaveParty(plr); invites[plr] = nil; remoteInvites[plr] = nil end)

--------------------------------------------------------------------
--  TRAVEL
--------------------------------------------------------------------
-- who travels: the leader takes the party (everyone ready); a member goes alone (and leaves it)
local function groupFor(plr, leaderOnly)
	local party = partyOf(plr)
	if not party then return {plr} end
	if party.leader == plr then
		if not allReady(party) then return nil, "not everyone is ready" end
		if party.ticket then return nil, "you're in the queue — cancel it first" end
		return party.members
	end
	if leaderOnly then return nil, "only the party leader picks where you go" end
	leaveParty(plr)
	return {plr}
end

function teleport(players, placeId, data, jobId, code, where)
	local opts = Instance.new("TeleportOptions")
	data = data or {}
	if code then data.code = code end
	for _, p in ipairs(players) do event:FireClient(p, "Travel", where or "") end
	if #players > 1 then
		local ids = {}
		for _, p in ipairs(players) do table.insert(ids, p.UserId) end
		data.party = {leader = players[1].UserId, members = ids}
	end
	opts:SetTeleportData(data)
	if code then opts.ReservedServerAccessCode = code elseif jobId then opts.ServerInstanceId = jobId end
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, placeId, players, opts)
	if not ok then
		warn("[Hub] teleport failed:", err)
		for _, p in ipairs(players) do event:FireClient(p, "TravelFailed") end
	end
	return ok, ok and "travelling…" or "teleport failed (published game only)"
end

function identityOf(e)
	return {mode = e.mode, access = e.access, name = e.name, custom = e.custom, host = e.hostId, door = e.door}
end
local function whereOf(e)
	return ((e.name or "") ~= "" and (e.name .. "  ·  ") or "") .. (e.modeName or e.mode or "") .. ((e.map or "") ~= "" and ("  ·  " .. e.map) or "")
end

local function reserve(group, modeId, access, name, custom, door, settings, where)
	local ok, code = pcall(TeleportService.ReserveServer, TeleportService, game.PlaceId)
	if not ok then warn("[Hub] ReserveServer failed:", code); return false, "could not reserve a server" end
	local def = GameConfig.MODES[modeId]
	local ids = {}
	for _, p in ipairs(group) do table.insert(ids, p.UserId) end
	local data = {mode = modeId, access = access, name = name or "", custom = custom == true, host = group[1].UserId,
		allowed = access ~= "Public" and ids or nil, door = door, settings = settings}
	if registry then
		pcall(function()
			registry:SetAsync("pending:" .. code:sub(1, 24), {
				jobId = "pending:" .. code:sub(1, 24), placeId = game.PlaceId, reserved = true, pending = true,
				mode = modeId, modeName = def.name, category = def.category, map = settings and settings.map or "",
				door = door, players = #group, max = (settings and tonumber(settings.limit)) or def.maxPlayers or Players.MaxPlayers,
				custom = custom == true, name = name or "", access = access, hostId = group[1].UserId,
				cheats = settings and settings.cheats == true or false,
				accessCode = code, members = ids, state = "Round", updated = os.time(),
			}, PENDING_TTL)
		end)
	end
	return teleport(group, game.PlaceId, data, nil, code, where or ((custom and (name .. "  ·  ") or "") .. def.name .. "  ·  new server"))
end

-- Studio: no teleports; switch this server instead
local function studioSwitch(plr, modeId, extra)
	local sv = Game.server
	if extra then for k, v in pairs(extra) do sv[k] = v end end
	local ok, msg = Game.requestMode(plr, modeId)
	return ok, ok and ("Studio: switching this server — " .. msg) or msg
end

local function goHub(plr)
	local group = groupFor(plr, false)
	if STUDIO then
		-- (Studio switches one server's mode: what's running now, not what it started as)
		if Game.modeId == "Hub" then return false, "you're in the Courtyard" end
		return studioSwitch(plr, "Hub", {door = "Courtyard", settings = nil, noRewards = false, sides = nil, bracket = nil, ranked = false})
	end
	if Game.server.mode == "Hub" then return false, "you're in the Courtyard" end
	return teleport(group, game.PlaceId, {}, nil, nil, "Courtyard")
end

local joinQueue   -- forward
local function play(plr, doorId, opts)
	local door = GameConfig.DOORS[doorId]
	if not door then return false, "no such door" end
	opts = type(opts) == "table" and opts or {}
	if doorId == "Courtyard" then return goHub(plr) end
	if doorId == "Lists" then return joinQueue(plr, opts.bracket, opts.ranked == true) end
	local group, why = groupFor(plr, true)
	if not group then return false, why end
	local modeId = door.mode or (door.modes and door.modes[1])
	if doorId == "Tiltyard" then
		if STUDIO then return studioSwitch(plr, "Tiltyard", {door = "Tiltyard", settings = nil, noRewards = false}) end
		if Game.server.door == "Tiltyard" then return false, "you're in your Tiltyard" end
		return reserve(group, modeId, "Friends", plr.DisplayName .. "'s Tiltyard", false, "Tiltyard", nil, "Tiltyard")
	end
	if doorId == "Horde" then
		if STUDIO then return studioSwitch(plr, "Horde", {door = "Horde", settings = nil, noRewards = false}) end
		if Game.server.door == "Horde" then return false, "you're holding off the horde already" end
		return reserve(group, modeId, "Friends", plr.DisplayName .. "'s Horde", false, "Horde", nil, "Horde")
	end
	-- Warfront
	if STUDIO then
		local m = GameConfig.MODES[opts.mode] and opts.mode or modeId
		return studioSwitch(plr, m, {door = "Warfront", settings = nil, noRewards = false})
	end
	if Game.server.door == "Warfront" and not Game.server.custom then return false, "you're on the Warfront" end
	for _, e in ipairs(listServers()) do
		if e.door == "Warfront" and not e.custom and e.access == "Public" and e.reserved and e.accessCode and not e.here
			and (e.players or 0) + #group <= (e.max or 0) then
			return teleport(group, game.PlaceId, identityOf(e), nil, e.accessCode, "Warfront  ·  " .. (e.modeName or "") .. (e.map ~= "" and ("  ·  " .. e.map) or ""))
		end
	end
	-- (no room anywhere: a new server; a newcomer's first one is Team Deathmatch)
	local m = (opts.first and GameConfig.MODES[opts.mode]) and opts.mode or modeId
	return reserve(group, m, "Public", "", false, "Warfront", nil, "Warfront  ·  new server")
end

-- custom server: settings = GameConfig.CUSTOM_DEFAULTS keys (clamped here)
local function cleanSettings(s)
	s = type(s) == "table" and s or {}
	local D = GameConfig.CUSTOM_DEFAULTS
	local out = {}
	out.door = GameConfig.DOORS[s.door] and s.door ~= "Courtyard" and s.door ~= "Lists" and s.door or D.door
	local allowed = {}
	if out.door == "Tiltyard" then allowed = {"Tiltyard"} else allowed = GameConfig.DOORS.Warfront.modes end
	out.mode = allowed[1]
	for _, m in ipairs(allowed) do if m == s.mode then out.mode = m end end
	local def = GameConfig.MODES[out.mode]
	out.map = ""
	for _, m in ipairs(def.maps or {}) do if m == s.map then out.map = m end end
	out.limit = math.clamp(math.floor(tonumber(s.limit) or D.limit), 2, def.maxPlayers or 24)
	out.roundLength = math.clamp(math.floor(tonumber(s.roundLength) or D.roundLength), 60, 20 * 60)
	out.access = (s.access == "Friends" or s.access == "Locked") and s.access or "Public"
	out.friendlyFire = s.friendlyFire ~= false
	out.respawns = s.respawns ~= false
	out.groundWeapons = s.groundWeapons ~= false
	out.cheats = s.cheats == true
	out.name = type(s.name) == "string" and s.name:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 32) or ""
	return out
end

local function custom(plr, settings)
	local s = cleanSettings(settings)
	local group, why = groupFor(plr, true)
	if not group then return false, why end
	if s.name == "" then s.name = plr.DisplayName .. "'s server" end
	if STUDIO then
		return studioSwitch(plr, s.mode, {door = s.door, custom = true, name = s.name, hostId = plr.UserId, settings = s, noRewards = s.cheats})
	end
	return reserve(group, s.mode, s.access, s.name, true, s.door, s, s.name .. "  ·  " .. GameConfig.MODES[s.mode].name)
end

local function joinServer(plr, jobId)
	if type(jobId) ~= "string" or jobId == "" then return false, "bad server" end
	if jobId == game.JobId then return false, "you're already here" end
	local group, why = groupFor(plr, true)
	if not group then return false, why end
	if STUDIO then return false, "no teleports in Studio" end
	local e = findServer(jobId)
	if not e then return false, "that server is gone" end
	local ok, msg = mayEnter(plr, e)
	if not ok then return false, msg end
	if (e.players or 0) + #group > (e.max or 0) then return false, "no room for your whole party there" end
	if e.reserved then
		if not e.accessCode then return false, "that server can't be joined" end
		return teleport(group, game.PlaceId, identityOf(e), nil, e.accessCode, whereOf(e))
	end
	return teleport(group, game.PlaceId, {}, jobId, nil, whereOf(e))
end

local function joinFriend(plr, userId)
	if type(userId) ~= "number" then return false, "bad user" end
	local group, why = groupFor(plr, true)
	if not group then return false, why end
	if STUDIO then return false, "no teleports in Studio" end
	local ok, inGame, err, placeId, jobId = pcall(TeleportService.GetPlayerPlaceInstanceAsync, TeleportService, userId)
	if not ok or not inGame then return false, "they're not in this game" end
	if jobId == game.JobId then return false, "they're in this server" end
	local e = findServer(jobId)
	if e then
		if e.access == "Locked" then return false, "they're in a locked match" end
		if e.access == "Friends" then
			local okF, f = pcall(plr.IsFriendsWith, plr, userId)
			if not (okF and f) and not hasMember(e, plr.UserId) then return false, "that server is friends only" end
		end
		if (e.players or 0) + #group > (e.max or 0) then return false, "no room there" end
		if e.reserved then
			if not e.accessCode then return false, "that server can't be joined" end
			return teleport(group, game.PlaceId, identityOf(e), nil, e.accessCode, whereOf(e))
		end
		return teleport(group, placeId, {}, jobId, nil, whereOf(e))
	end
	return teleport(group, placeId, {}, jobId, nil, "a friend's server")
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
--  THE LISTS: queue + match found
--------------------------------------------------------------------
local tickets = {}   -- [ticketId] = party
local nextTicket = 0

local function bracketSize(b) return tonumber(tostring(b):match("^(%d)v%d$")) or 0 end

function cancelQueue(party, why)
	if not party.ticket then return end
	Matchmaker.dequeue(party.ticket)
	tickets[party.ticket] = nil
	party.ticket = nil
	for _, m in ipairs(party.members) do toast(m, "Left the queue" .. (why and (" — " .. why) or "")) end
	broadcast(party)
end

function joinQueue(plr, bracket, ranked)
	local door = GameConfig.DOORS.Lists
	local okB = false
	for _, b in ipairs(door.brackets or {}) do if b == bracket then okB = true end end
	if not okB then return false, "pick a bracket" end
	local party = partyOf(plr) or createParty(plr)
	if party.leader ~= plr then return false, "only the party leader queues" end
	if party.ticket then return false, "already in the queue" end
	if not allReady(party) then return false, "not everyone is ready" end
	local size = bracketSize(bracket)
	if #party.members > size then return false, string.format("%s takes a party of at most %d", bracket, size) end
	if Game.server.door == "Lists" then return false, "finish this match first" end
	local p = Profile.get(plr)
	local lockUntil = p.queueLock and p.queueLock[bracket] or 0
	if ranked and os.time() < lockUntil then return false, string.format("ranked locked for %d more min (abandoned match)", math.ceil((lockUntil - os.time()) / 60)) end
	local ids, sum = {}, 0
	for _, m in ipairs(party.members) do table.insert(ids, m.UserId); sum += Profile.rating(m, bracket) end
	nextTicket += 1
	local id = string.format("%s:%d:%d", myKey(), os.time(), nextTicket)
	party.ticket, party.bracket, party.ranked = id, bracket, ranked
	tickets[id] = party
	local ok, msg = Matchmaker.enqueue({id = id, bracket = bracket, ranked = ranked, players = ids, rating = math.floor(sum / #ids)})
	if not ok then party.ticket = nil; tickets[id] = nil; return false, msg end
	broadcast(party)
	return true, "searching…"
end

Matchmaker.onMatch = function(ticketId, match)
	local party = tickets[ticketId]
	tickets[ticketId] = nil
	if not party then return end
	party.ticket = nil
	local group = {}
	for _, m in ipairs(party.members) do if m.Parent then table.insert(group, m) end end
	if #group == 0 then return end
	local info = {bracket = match.bracket, ranked = match.ranked, sides = match.sides}
	for _, m in ipairs(group) do event:FireClient(m, "MatchFound", info) end
	broadcast(party)
	task.delay(3, function()
		if match.studio or STUDIO then
			studioSwitch(group[1], "Lists", {door = "Lists", bracket = match.bracket, ranked = match.ranked,
				sides = (function() local s = {A = {}, B = {}}; for _, id in ipairs(match.sides.A) do s.A[id] = true end; for _, id in ipairs(match.sides.B) do s.B[id] = true end; return s end)(),
				settings = nil, noRewards = false})
			return
		end
		local data = {mode = "Lists", door = "Lists", access = "Locked", allowed = match.players, host = match.players[1],
			sides = match.sides, bracket = match.bracket, ranked = match.ranked, name = ""}
		teleport(group, game.PlaceId, data, nil, match.code, "The Lists  ·  " .. match.bracket .. (match.ranked and "  ·  RANKED" or ""))
	end)
end

-- a finished Lists match: everyone back to a Courtyard
do
	Game.node:GetAttributeChangedSignal("MatchOver"):Connect(function()
		if Game.node:GetAttribute("MatchOver") ~= true then return end
		task.delay(MATCH_OVER_DELAY, function()
			local all = Players:GetPlayers()
			if #all == 0 then return end
			if STUDIO then Game.node:SetAttribute("MatchOver", false); studioSwitch(all[1], "Hub", {door = "Courtyard", sides = nil, bracket = nil, ranked = false}); return end
			teleport(all, game.PlaceId, {}, nil, nil, "Courtyard")
		end)
	end)
end

--------------------------------------------------------------------
--  LEADERBOARDS (Scoreboard writes LB_<bracket> ratings and LB_Warfront kills)
--------------------------------------------------------------------
-- (the boards themselves live in Hub ▸ Leaderboards, shared with the Courtyard)
local Leaderboards = require(script.Parent:WaitForChild("Leaderboards"))
local function nameOf(userId) return Leaderboards.nameOf(userId) end
local function leaderboard(plr, which) return Leaderboards.top(which, 10) end

--------------------------------------------------------------------
--  SHOP
--------------------------------------------------------------------
local function buyCrowns(plr, index)
	local prod = Catalog.ECONOMY.products[tonumber(index) or 0]
	if not prod then return false, "no such bundle" end
	if (prod.id or 0) == 0 then return false, string.format("no Developer Product named \"%s\" yet (Creator Dashboard ▸ Monetization)", prod.product or (tostring(prod.crowns) .. " Crowns")) end
	local ok, err = pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, plr, prod.id)
	return ok, ok and "purchase prompt opened" or ("could not open the purchase: " .. tostring(err))
end

--------------------------------------------------------------------
--  STATE
--------------------------------------------------------------------
-- today's store (Catalog ▸ Store): the packs on sale and when the day turns
local function storeInfo()
	local packs, day, endsAt = Catalog.storeFor()
	return {packs = packs, skins = Catalog.skinOffers(day), day = day, endsAt = endsAt, serverTime = os.time()}
end

local function state(plr)
	local sv = Game.server
	local party = partyOf(plr)
	return {ok = true, studio = STUDIO, placeId = game.PlaceId, jobId = game.JobId,
		mode = sv.mode, door = sv.door, reserved = sv.reserved, access = sv.access, name = sv.name, custom = sv.custom,
		bracket = sv.bracket, ranked = sv.ranked, hostId = sv.hostId, isHost = sv.hostId == plr.UserId,
		settings = sv.settings, noRewards = sv.noRewards,
		party = partyInfo(party), partyMax = PARTY_MAX,
		profile = Profile.summary(plr), contracts = Stats.contracts(plr),
		store = storeInfo(), pass = Economy.passState(plr), login = Economy.loginStatus(plr),
		gifts = Pastimes.gifts(plr), hatchery = Pastimes.hatchery(plr),
		players = #Players:GetPlayers()}
end

--------------------------------------------------------------------
--  REMOTES
--------------------------------------------------------------------
local lastCall = {}
remote.OnServerInvoke = function(plr, op, a, b, c)
	local now = os.clock()
	if now - (lastCall[plr] or 0) < 0.08 then return {ok = false, msg = "slow down"} end
	lastCall[plr] = now

	if op == "State" then return state(plr)
	elseif op == "Store" then return {ok = true, store = storeInfo()}
	elseif op == "Products" then
		-- the Crown bundles as linked at start (EconomyServer): price and art from the dashboard
		local list = {}
		for i, pr in ipairs(Catalog.ECONOMY.products) do
			list[i] = {crowns = pr.crowns, robux = pr.robux, bonus = pr.bonus, icon = pr.icon, ready = (pr.id or 0) ~= 0}
		end
		return {ok = true, products = list}
	elseif op == "Servers" then return {ok = true, servers = listForClient()}
	elseif op == "Friends" then return {ok = true, friends = friendsOnline(plr)}
	elseif op == "Leaderboard" then return {ok = true, rows = leaderboard(plr, a)}
	elseif op == "Play" then local ok, msg = play(plr, a, b); return {ok = ok, msg = msg}
	elseif op == "Hub" then local ok, msg = goHub(plr); return {ok = ok, msg = msg}
	elseif op == "Custom" then local ok, msg = custom(plr, a); return {ok = ok, msg = msg}
	elseif op == "Join" then local ok, msg = joinServer(plr, a); return {ok = ok, msg = msg}
	elseif op == "JoinFriend" then local ok, msg = joinFriend(plr, a); return {ok = ok, msg = msg}
	elseif op == "QueueCancel" then
		local party = partyOf(plr)
		if party and party.ticket and party.leader == plr then cancelQueue(party); return {ok = true} end
		return {ok = false, msg = "not queued"}
	elseif op == "PartyCreate" then createParty(plr); return {ok = true, party = partyInfo(partyOf(plr))}
	elseif op == "PartyInvite" then local ok, msg = invite(plr, a, type(b) == "string" and b:sub(1, 32) or nil); return {ok = ok, msg = msg, party = partyInfo(partyOf(plr))}
	elseif op == "PartyAccept" then local ok, msg = accept(plr); return {ok = ok, msg = msg, party = partyInfo(partyOf(plr))}
	elseif op == "PartyLeave" then leaveParty(plr); return {ok = true}
	elseif op == "PartyReady" then local ok, msg = setReady(plr, a ~= false); return {ok = ok, msg = msg, party = partyInfo(partyOf(plr))}
	elseif op == "PartyKick" then local ok, msg = kickFromParty(plr, a); return {ok = ok, msg = msg, party = partyInfo(partyOf(plr))}
	elseif op == "SaveClass" then
		if not GameConfig.CLASSES[a] then return {ok = false, msg = "no such class"} end
		local lo = Profile.validateLoadout(plr, a, b)
		Profile.setClass(plr, a, lo)
		local party = partyOf(plr)
		if party and party.leader ~= plr and party.ready[plr] then party.ready[plr] = nil; broadcast(party) end
		return {ok = true, loadout = lo, profile = Profile.summary(plr)}
	elseif op == "SetActive" then
		Profile.setActive(plr, a)
		local party = partyOf(plr); if party then broadcast(party) end
		return {ok = true, profile = Profile.summary(plr)}
	elseif op == "SaveAppearance" then
		local app = Profile.validateAppearance(plr, a)
		Profile.setAppearance(plr, app)
		return {ok = true, appearance = app, profile = Profile.summary(plr)}
	elseif op == "Buy" then local ok, msg = Economy.buy(plr, a, b, c); return {ok = ok, msg = msg, profile = Profile.summary(plr)}
	elseif op == "OpenCrate" then
		local res, msg = Economy.openCrate(plr, a, false, b == "crowns" and "crowns" or "keys")
		if not res then return {ok = false, msg = msg} end
		return {ok = true, result = res, profile = Profile.summary(plr)}
	elseif op == "Forge" then
		local ok, msg, variant = Economy.collection().forge(plr, a)
		return {ok = ok, msg = msg, variant = variant, profile = Profile.summary(plr)}
	elseif op:sub(1, 5) == "Trade" then
		local Trading = require(ServerScriptService:WaitForChild("Economy"):WaitForChild("Trading"))
		local fn = ({TradeRequest = Trading.request, TradeAccept = Trading.accept, TradeDecline = Trading.decline, TradeOffer = Trading.offer,
			TradeReady = Trading.ready, TradeConfirm = Trading.confirm, TradeCancel = Trading.cancel})[op]
		if op == "TradeState" then return {ok = true, trade = Trading.view(plr)} end
		if not fn then return {ok = false, msg = "unknown trade op"} end
		local ok, msg = fn(plr, a)
		return {ok = ok, msg = msg, trade = Trading.view(plr), profile = Profile.summary(plr)}
	elseif op == "Scrap" then
		local ok, msg = Economy.collection().scrap(plr, a)
		return {ok = ok, msg = msg, profile = Profile.summary(plr)}
	elseif op == "Exchange" then local ok, msg = Economy.exchange(plr, tonumber(a) or 0); return {ok = ok, msg = msg, profile = Profile.summary(plr)}
	elseif op == "PassClaim" then
		local ok, msg, crate = Economy.passClaim(plr, a, b)
		return {ok = ok, msg = msg, crate = crate, pass = Economy.passState(plr), profile = Profile.summary(plr)}
	elseif op == "Equip" then
		-- a = "killfx" + id, or "emotes" + {id, ...} (up to 6, owned)
		local p = Profile.get(plr)
		if a == "killfx" then
			if type(b) ~= "string" or not Catalog.KILLFX_BY[b] or not Profile.has(plr, "killfx", b) then return {ok = false, msg = "you don't have that kill effect"} end
			p.killfx = b
		elseif a == "emotes" then
			if type(b) ~= "table" then return {ok = false, msg = "bad list"} end
			local list, seen = {}, {}
			for _, id in ipairs(b) do
				if #list >= 6 then break end
				if type(id) == "string" and Catalog.EMOTE[id] and not seen[id] and Profile.has(plr, "emotes", id) then table.insert(list, id); seen[id] = true end
			end
			p.emotes = list
		else return {ok = false, msg = "nothing to equip"} end
		Profile.markDirty(plr)
		return {ok = true, profile = Profile.summary(plr)}
	elseif op == "PassClaimAll" then
		local ok, msg, lines, crates = Economy.passClaimAll(plr)
		return {ok = ok, msg = msg, lines = lines, crates = crates, pass = Economy.passState(plr), profile = Profile.summary(plr)}
	elseif op == "PassBuy" then
		local ok, msg = Economy.passBuy(plr)
		return {ok = ok, msg = msg, pass = Economy.passState(plr), profile = Profile.summary(plr)}
	elseif op == "LoginClaim" then
		local ok, msg, crate = Economy.loginClaim(plr)
		return {ok = ok, msg = msg, crate = crate, login = Economy.loginStatus(plr), profile = Profile.summary(plr)}
	elseif op == "BuyCrowns" then local ok, msg = buyCrowns(plr, a); return {ok = ok, msg = msg}
	-- pastimes: playtime gifts, the Hatchery, companions (Economy ▸ Pastimes)
	elseif op == "AskedTraining" then
		Profile.get(plr).askedTraining = true
		Profile.markDirty(plr)
		return {ok = true}
	elseif op == "GiftClaim" then
		local ok, msg, crate = Pastimes.giftClaim(plr, a)
		return {ok = ok, msg = msg, crate = crate, gifts = Pastimes.gifts(plr), profile = Profile.summary(plr)}
	elseif op == "Hatchery" then return {ok = true, hatchery = Pastimes.hatchery(plr), gifts = Pastimes.gifts(plr)}
	elseif op == "EggBuy" then
		local ok, msg = Pastimes.eggBuy(plr, a)
		return {ok = ok, msg = msg, hatchery = Pastimes.hatchery(plr), profile = Profile.summary(plr)}
	elseif op == "EggPlace" then
		local ok, msg = Pastimes.eggPlace(plr, a, b)
		return {ok = ok, msg = msg, hatchery = Pastimes.hatchery(plr), profile = Profile.summary(plr)}
	elseif op == "Hatch" then
		local res, msg = Pastimes.hatch(plr, a, b == true)
		return {ok = res ~= nil, msg = msg, result = res, hatchery = Pastimes.hatchery(plr), profile = Profile.summary(plr)}
	elseif op == "Companion" then
		local ok, msg = Pastimes.equip(plr, type(a) == "string" and a or "")
		return {ok = ok, msg = msg, profile = Profile.summary(plr)}
	end
	return {ok = false, msg = "unknown op"}
end

--------------------------------------------------------------------
--  A NEWCOMER'S PATH (profile tutorial): the Courtyard sends someone brand new
--  straight to basic training (Game ▸ Training), and someone who's trained (or
--  skipped it) straight into a battle. After that first battle they come back
--  here to the full menu.
--------------------------------------------------------------------
_G.HubTravel = function(plr, doorId, opts) return play(plr, doorId, opts) end

local function routeNewcomer(plr)
	if Game.server.mode ~= "Hub" then return end
	local t = Profile.get(plr).tutorial or 2
	if t >= 2 then return end
	task.wait(STUDIO and 0.5 or 2)   -- (the client is up: it shows the travel screen)
	if not plr.Parent then return end
	if t == 0 then play(plr, "Tiltyard") else play(plr, "Warfront", {mode = "TDM", first = true}) end
end

-- the first battle is over: next stop, the menu
Game.roundEnded.Event:Connect(function(modeId)
	-- (a battle's round: not the Courtyard's or the training yard's, which "end" when Studio switches mode)
	if Game.server.door ~= "Warfront" or modeId == "Hub" or modeId == "Tiltyard" or modeId == "Horde" then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if (Profile.get(plr).tutorial or 2) == 1 then
			Profile.setTutorial(plr, 2)
			event:FireClient(plr, "FirstBattleDone")
			task.delay(9, function() if plr.Parent then goHub(plr) end end)
		end
	end
end)

local function onArrival(plr)
	Game.identify(plr)
	local ok, data = pcall(plr.GetJoinData, plr)
	local td = ok and data and data.TeleportData
	if type(td) == "table" then
		if accessCode == nil and Game.server.reserved and type(td.code) == "string" then accessCode = td.code end
		arrivedWithParty(plr, td)
		if type(td.joinParty) == "number" then task.defer(joinInvited, plr, td.joinParty) end
	end
	local allowed, why = Game.mayJoin(plr)
	if not allowed then
		log("kicked", plr.Name, "-", why)
		plr:Kick(why .. " Rejoin from the Courtyard.")
		return
	end
	if registry then task.spawn(function() pcall(function() registry:SetAsync(myKey(), entry(), EXPIRY) end) end) end
	task.spawn(routeNewcomer, plr)
end
Players.PlayerAdded:Connect(onArrival)
for _, p in ipairs(Players:GetPlayers()) do onArrival(p) end

log("ready —", Game.server.reserved and "reserved server" or "public server (Courtyard)", STUDIO and "(Studio: no teleports)" or "")
