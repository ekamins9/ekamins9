--[[ GAME SERVER — the loop: pick a mode → vote/pick a map → load it → run the
     round (mode ticks, clock, early end) → result → intermission (board up,
     map vote, everyone pulled out) → next round. Replaces RoundServer.

     Which mode: Game.server.mode — the Hub in a public server, the teleport
     data's mode in a reserved one (Game.identify, fixed by the first
     arrival); a server never changes mode live. In Studio, NextMode
     (Game.requestMode from the menu's PLAY) switches it so every mode can
     be tested. A round only counts down while someone is in the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Game       = require(script.Parent:WaitForChild("Game"))
local MapLoader  = Game.MapLoader
-- Warfront matches are filled up with bots while players are few (Game ▸ BotFill)
require(script.Parent:WaitForChild("BotFill")).start()

local node = Game.node
local function log(...) DebugFlags.log("Game", ...) end

-- map vote (client: Scoreboard sends "Vote", index)
local voteRemote = Instance.new("RemoteEvent")
voteRemote.Name = "VoteRemote"
voteRemote.Parent = ReplicatedStorage
-- Warfront votes BATTLES: three cards, each a mode on a map (VoteMode1..3 +
-- Vote1..3); everywhere else the cards are maps for the same mode (VoteMode "")
local votes = {}   -- [player] = card index
local function tally()
	for i = 1, 3 do
		local n = 0
		for _, v in pairs(votes) do if v == i then n += 1 end end
		node:SetAttribute("Votes" .. i, n)
	end
end
-- client: VoteRemote:FireServer("map", idx) (a bare number works too)
voteRemote.OnServerEvent:Connect(function(plr, kind, idx)
	if type(kind) == "number" then idx = kind end
	if node:GetAttribute("State") ~= "Intermission" or type(idx) ~= "number" or idx < 1 or idx > 3 then return end
	if (node:GetAttribute("Vote" .. math.floor(idx)) or "") == "" then return end
	votes[plr] = math.floor(idx)
	tally()
end)
Players.PlayerRemoving:Connect(function(p) votes[p] = nil; tally() end)

-- three mode candidates for a Warfront server, rotating
local modeRotation = 0
local function modeCandidates()
	local door = GameConfig.DOORS[Game.server.door]
	local list = door and door.modes or {}
	local out = {}
	for i = 0, math.min(2, #list - 1) do table.insert(out, list[((modeRotation + i) % #list) + 1]) end
	modeRotation += 1
	return out
end

local function startingMode()
	Game.identify(Players:GetPlayers()[1])
	return Game.server.mode or "Hub"
end

-- up to three candidate maps for a mode (that exist), rotating. Sized to the
-- numbers: maps that suit the players here and the bots the mode brings first
-- (GameConfig.MAP_FIGHTERS: a 1v1 isn't lost in a field, a 16v16 isn't crammed
-- into a garden), then maps that at least fit the players
local BotFill = require(script.Parent:WaitForChild("BotFill"))
local rotation = {}
local function candidates(def)
	local players = #Players:GetPlayers()
	local bots = (BotFill.wanted and BotFill.wanted(def)) or 0
	local fits = {{}, {}, {}}
	for _, m in ipairs(def.maps or {}) do
		if MapLoader.exists(m) then table.insert(fits[GameConfig.mapFit(m, players, bots) + 1], m) end
	end
	local start = (rotation[def] or 0)
	rotation[def] = start + 1
	local out = {}
	local function take(list)
		for i = 0, #list - 1 do
			if #out >= 3 then return end
			table.insert(out, list[((start + i) % #list) + 1])
		end
	end
	take(fits[1]); take(fits[2])
	if #out == 0 then take(fits[3]) end
	if #out == 0 then out = {def.maps and def.maps[1] or "None"} end
	return out
end

local function countdown(seconds, mode, earlyEnd)
	local left = seconds
	node:SetAttribute("TimeLeft", left)
	local last = os.clock()
	while true do
		task.wait(0.25)
		local now = os.clock()
		local dt = now - last
		last = now
		if mode then mode:tick(dt) end
		-- staff ended the round (Admin)
		if mode and Game.adminEnd then local r = Game.adminEnd; Game.adminEnd = nil; return r end
		-- time a mode earned (a siege stage taken)
		if mode and (mode.bonusTime or 0) ~= 0 then left += mode.bonusTime; mode.bonusTime = 0 end
		local over = earlyEnd and earlyEnd()
		if over then return over end
		if seconds > 0 and #Players:GetPlayers() > 0 then
			left -= dt
			local whole = math.max(0, math.ceil(left))
			if node:GetAttribute("TimeLeft") ~= whole then node:SetAttribute("TimeLeft", whole) end
			if left <= 0 then return nil end
		end
	end
end

task.spawn(function()
	-- a reserved server learns its mode from its first arrival, so it waits for
	-- one; a public server is the Hub and loads the courtyard straight away, so
	-- the menu camera has something to look at from the first frame
	while Game.server.reserved and #Players:GetPlayers() == 0 do task.wait(0.5) end
	local modeId = startingMode()
	local pendingMaps
	while true do
		local nextMode = node:GetAttribute("NextMode")
		if nextMode ~= "" and GameConfig.MODES[nextMode] then
			modeId = nextMode
			node:SetAttribute("NextMode", "")
			Game.clearRequests()
		end
		local mode = (Game.current and Game.modeId == modeId) and Game.current or Game.load(modeId)
		local def = mode.def
		-- custom server settings
		local st = Game.server.settings
		node:SetAttribute("FriendlyFire", not (st and st.friendlyFire == false))
		node:SetAttribute("GroundWeapons", not (st and st.groundWeapons == false))
		node:SetAttribute("NoRewards", Game.server.noRewards == true)
		node:SetAttribute("Door", Game.server.door or "")
		node:SetAttribute("Bracket", Game.server.bracket or "")
		node:SetAttribute("Ranked", Game.server.ranked == true)
		node:SetAttribute("ServerName", Game.server.name or "")
		Game.resetSpawns()

		-- map: the vote's winner, else rotate
		local map
		if pendingMaps then
			local best, bestN = 1, -1
			for i = 1, #pendingMaps do
				local n = node:GetAttribute("Votes" .. i) or 0
				if n > bestN then best, bestN = i, n end
			end
			map = pendingMaps[best]
		end
		-- (only a map this mode plays on: a vote for another battle, overridden by an
		-- asked-for mode, must not put Team Deathmatch behind Frostgate's shut gate)
		if not (map and table.find(def.maps or {}, map)) then
			map = candidates(def)[1]
		end
		-- a custom server's host fixed the map (settings.map; "" = rotate), if this mode plays on it
		local fixed = st and st.map
		if Game.server.custom and fixed and fixed ~= "" and table.find(def.maps or {}, fixed) and MapLoader.exists(fixed) then map = fixed end
		-- staff (Admin) or the host (HostServer) picked the next map
		if Game.adminNextMap and MapLoader.exists(Game.adminNextMap) then map = Game.adminNextMap end
		Game.adminNextMap = nil
		MapLoader.load(map)
		node:SetAttribute("Map", map)
		node:SetAttribute("MapName", GameConfig.mapTitle(map))
		node:SetAttribute("Number", (node:GetAttribute("Number") or 0) + 1)
		node:SetAttribute("Winner", "")
		for i = 1, 3 do node:SetAttribute("Vote" .. i, ""); node:SetAttribute("Votes" .. i, 0); node:SetAttribute("VoteMode" .. i, "") end
		votes = {}

		mode:start(map)
		mode:publishScores()
		node:SetAttribute("State", "Round")
		Game.roundStarted:Fire(modeId, map)
		log("round", node:GetAttribute("Number"), "-", modeId, "on", map)

		local early = countdown(Game.roundLength(def), mode, function() return mode:isOver() end)
		local result = early or mode:result()
		mode:stop()
		log("round over:", result)
		Game.roundEnded:Fire(modeId, result)

		-- intermission: the board is up and everyone votes the next battle
		local door = GameConfig.DOORS[Game.server.door]
		local cards = nil
		if door and door.vote and not (Game.server.settings and Game.server.custom) then
			-- Warfront: three different modes, each on one of its maps (not the one just played if it can help it)
			cards = {}
			for _, m in ipairs(modeCandidates()) do
				local d2 = GameConfig.MODES[m]
				local maps = d2 and candidates(d2) or {}
				local pick = maps[1]
				for _, mp in ipairs(maps) do if mp ~= map then pick = mp; break end end
				if pick then table.insert(cards, {mode = m, map = pick}) end
			end
			pendingMaps = {}
			for i, c in ipairs(cards) do
				pendingMaps[i] = c.map
				node:SetAttribute("Vote" .. i, c.map)
				node:SetAttribute("VoteMode" .. i, c.mode)
			end
		else
			local nextDef = GameConfig.MODES[node:GetAttribute("NextMode")] or def
			pendingMaps = candidates(nextDef)
			for i, m in ipairs(pendingMaps) do node:SetAttribute("Vote" .. i, m); node:SetAttribute("VoteMode" .. i, "") end
		end
		node:SetAttribute("Objective", result)
		node:SetAttribute("State", "Intermission")
		local inter = def.intermission or 0
		if modeId == "Hub" or modeId == "Tiltyard" then inter = 3 end
		Game.intermissionStarted:Fire(inter)
		-- a finished Lists match stays on its result; HubServer sends everyone home
		if node:GetAttribute("MatchOver") == true then
			node:SetAttribute("TimeLeft", 0)
			while node:GetAttribute("MatchOver") == true do task.wait(1) end   -- Studio: HubServer clears it to go home
		end
		countdown(inter, nil, nil)
		-- (a mode asked for outright — Studio's switch — isn't voted away)
		local asked = node:GetAttribute("NextMode")
		if cards and #cards > 0 and (asked == nil or asked == "" or asked == modeId) then
			-- the card with the most votes (a tie: one of the tied, at random)
			local top, tied = -1, {}
			for i = 1, #cards do
				local n = node:GetAttribute("Votes" .. i) or 0
				if n > top then top, tied = n, {i} elseif n == top then table.insert(tied, i) end
			end
			local win = cards[tied[math.random(#tied)]]
			node:SetAttribute("NextMode", win.mode)
			pendingMaps = {win.map}
			log("the vote: " .. win.mode .. " on " .. win.map)
		end
		-- the mode's per-round score display resets with the next start
	end
end)
