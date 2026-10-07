--[[ HOST (server) — the custom server's owner runs it: the SERVER panel in the
     menu (HubMenu) asks, this decides. Only the host of a custom server (the one
     who made it; if they leave, whoever has been here longest), never a public or
     ranked one.

       HostRemote (RemoteFunction) client → server
         "Info"                        -> {ok, isHost, hostId, settings, mode, nextMode, nextMap,
                                           modes = {...}, maps = {...}, players = {...}, bots, extraBots}
         "Set", key, value             a setting, live: friendlyFire respawns groundWeapons
                                       bots botCount botSkill roundLength limit access map
         "Kick", userId                out, and kept out of this server
         "MakeHost", userId            hand the server over
         "SpawnBots", count, skill     practice bots where you stand (they fight everyone)
         "ClearBots"                   the practice bots go (the fill bots follow the setting)
         "NextMode", modeId            the next round's mode (at the end of this one)
         "NextMap", map                the next round's map
         "EndRound"                    end this round now
     Round attribute HostId: who the host is (the menu shows the panel to them). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Game = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Game"))

local remote = Instance.new("RemoteFunction")
remote.Name = "HostRemote"
remote.Parent = ReplicatedStorage

local node = Game.node
local kicked = {}       -- [userId] = true: kept out of this server
local practice = {}     -- the host's practice bots
local joinedAt = {}     -- [player] = os.clock() (the longest here takes over)

local function server() return Game.server end
local function isCustom() local sv = server(); return sv.custom == true and not sv.ranked end
local function isHost(plr) return isCustom() and server().hostId == plr.UserId end

local function publishHost()
	node:SetAttribute("HostId", isCustom() and (server().hostId or 0) or 0)
end

-- the host left: whoever has been here longest takes over
local function passOn()
	local best, at
	for _, p in ipairs(Players:GetPlayers()) do
		local t = joinedAt[p] or math.huge
		if not best or t < at then best, at = p, t end
	end
	server().hostId = best and best.UserId or nil
	publishHost()
end

Players.PlayerAdded:Connect(function(p)
	joinedAt[p] = os.clock()
	if kicked[p.UserId] then p:Kick("The host removed you from this server.") end
	task.defer(publishHost)
end)
for _, p in ipairs(Players:GetPlayers()) do joinedAt[p] = joinedAt[p] or os.clock() end
Players.PlayerRemoving:Connect(function(p)
	joinedAt[p] = nil
	if isCustom() and server().hostId == p.UserId then task.defer(passOn) end
end)
task.defer(publishHost)
Game.roundStarted.Event:Connect(publishHost)

local function bots() return require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots")) end
local function botFill() return require(ServerScriptService:WaitForChild("Game"):WaitForChild("BotFill")) end
local function livePractice()
	local n = 0
	for b in pairs(practice) do if b.alive and b.model.Parent then n += 1 else practice[b] = nil end end
	return n
end

-- the modes this custom server can switch between (its door's)
local function modesHere()
	local door = GameConfig.DOORS[server().door or "Warfront"]
	return door and (door.modes or {door.mode}) or {}
end
local function mapsFor(modeId)
	local def = GameConfig.MODES[modeId]
	local out = {}
	local folder = ServerStorage:FindFirstChild("Maps")
	for _, m in ipairs(def and def.maps or {}) do
		if not folder or folder:FindFirstChild(m) then table.insert(out, m) end
	end
	return out
end

local function info(plr)
	local sv = server()
	local nextMode = node:GetAttribute("NextMode") or ""
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		table.insert(list, {id = p.UserId, name = p.Name, display = p.DisplayName,
			team = p.Team and p.Team.Name or "", kills = ls and ls:FindFirstChild("Kills") and ls.Kills.Value or 0,
			deaths = ls and ls:FindFirstChild("Deaths") and ls.Deaths.Value or 0, host = p.UserId == sv.hostId})
	end
	local modeForMaps = nextMode ~= "" and nextMode or Game.modeId
	return {ok = true, isHost = isHost(plr), hostId = sv.hostId, settings = sv.settings, mode = Game.modeId,
		nextMode = nextMode, nextMap = Game.adminNextMap or "", modes = modesHere(), maps = mapsFor(modeForMaps),
		players = list, bots = botFill().count(), extraBots = livePractice(), state = node:GetAttribute("State")}
end

-- a setting changed live: what each means right away
local SETTERS = {
	friendlyFire = function(s, v) s.friendlyFire = v == true; node:SetAttribute("FriendlyFire", s.friendlyFire) end,
	respawns = function(s, v) s.respawns = v == true end,
	groundWeapons = function(s, v) s.groundWeapons = v == true; node:SetAttribute("GroundWeapons", s.groundWeapons) end,
	bots = function(s, v) s.bots = v == true end,
	botCount = function(s, v) s.botCount = math.clamp(math.floor(tonumber(v) or s.botCount or 8), 0, 24) end,
	botSkill = function(s, v) if table.find(GameConfig.BOT_SKILLS, v) then s.botSkill = v end end,
	roundLength = function(s, v) s.roundLength = math.clamp(math.floor(tonumber(v) or 300), 60, 20 * 60) end,
	limit = function(s, v)
		local def = GameConfig.MODES[Game.modeId]
		s.limit = math.clamp(math.floor(tonumber(v) or 12), math.max(2, #Players:GetPlayers()), def and def.maxPlayers or 40)
	end,
	access = function(s, v) if v == "Public" or v == "Friends" or v == "Locked" then s.access = v; server().access = v end end,
	map = function(s, v)
		v = tostring(v or "")
		if v == "" or table.find(mapsFor(Game.modeId), v) then s.map = v end
	end,
}

remote.OnServerInvoke = function(plr, op, a, b)
	if op == "Info" then return info(plr) end
	if not isHost(plr) then return {ok = false, msg = "only the host can do that"} end
	local sv = server()
	sv.settings = sv.settings or {}
	if op == "Set" then
		local f = SETTERS[a]
		if not f then return {ok = false, msg = "no such setting"} end
		f(sv.settings, b)
		return {ok = true, msg = "set"}
	elseif op == "Kick" then
		local p = Players:GetPlayerByUserId(tonumber(a) or 0)
		if not p then return {ok = false, msg = "not here"} end
		if p == plr then return {ok = false, msg = "you can't kick yourself"} end
		kicked[p.UserId] = true
		p:Kick("The host removed you from this server.")
		return {ok = true, msg = p.DisplayName .. " was removed"}
	elseif op == "MakeHost" then
		local p = Players:GetPlayerByUserId(tonumber(a) or 0)
		if not p or p == plr then return {ok = false, msg = "pick someone else here"} end
		sv.hostId = p.UserId
		publishHost()
		return {ok = true, msg = p.DisplayName .. " is the host now"}
	elseif op == "SpawnBots" then
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return {ok = false, msg = "spawn first: they come where you stand"} end
		local B = bots()
		local skill = B.SKILLS[b] and b or "Knight"
		local count = math.clamp(math.floor(tonumber(a) or 1), 1, 8)
		if livePractice() + count > 12 then return {ok = false, msg = "12 practice bots at most"} end
		local weapons = {"Longsword", "ArmingSword", "Mace", "Spear", "WarAxe", "Halberd", "Messer", "Falchion"}
		for i = 1, count do
			local ang = (i / count) * math.pi * 2
			local ok, bot = pcall(B.spawn, {at = hrp.CFrame * CFrame.new(math.cos(ang) * 12, 0, math.sin(ang) * 12 - 6),
				skill = skill, weapon = weapons[math.random(#weapons)], name = skill, startDelay = 1.5, fightBots = true, corpseTime = 6})
			if ok and bot then practice[bot] = true end
		end
		return {ok = true, msg = string.format("%d %s%s", count, skill, count > 1 and "s" or "")}
	elseif op == "ClearBots" then
		local n = 0
		for bot in pairs(practice) do
			if bot.alive then pcall(function() bot:destroy() end); n += 1 end
			practice[bot] = nil
		end
		return {ok = true, msg = n .. " practice bots gone"}
	elseif op == "NextMode" then
		if not table.find(modesHere(), a) then return {ok = false, msg = "not a mode for this server"} end
		node:SetAttribute("NextMode", a)
		Game.adminNextMap = nil   -- (a map picked for the old mode might not exist in the new one)
		return {ok = true, msg = "next round: " .. GameConfig.MODES[a].name}
	elseif op == "NextMap" then
		local nextMode = node:GetAttribute("NextMode") or ""
		local forMode = nextMode ~= "" and nextMode or Game.modeId
		if not table.find(mapsFor(forMode), a) then return {ok = false, msg = "that mode doesn't play there"} end
		Game.adminNextMap = a
		return {ok = true, msg = "next map: " .. GameConfig.mapTitle(a)}
	elseif op == "EndRound" then
		if node:GetAttribute("State") ~= "Round" then return {ok = false, msg = "no round running"} end
		Game.adminEnd = "THE HOST ENDED THE ROUND"
		return {ok = true, msg = "ending the round"}
	end
	return {ok = false, msg = "unknown"}
end
