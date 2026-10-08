--[[ BOT FILL — a Warfront match is never empty. While a round runs, bots
     make up the numbers: each side of a team mode is filled to half the
     mode's `botFill` (GameConfig.MODES), a free-for-all to all of it. A player
     who joins takes a bot's place (the bot leaves in a puff); a fallen bot's
     place is filled again after RESPAWN seconds (not in Last Team Standing:
     one life a round, bots too).

     Bots fight everyone not on their side (players and bots), head for the
     objective when nobody is near (KOTH's hill, Siege's ram or zone: Round
     ObjPos), count on hills and rams, cost their side a ticket when they fall
     and give their killer the kill (Game.onBotDeath). A server with a
     newcomer in it (their first match) fields only Squires.

     THE BOARD: every bot holds a SEAT (ReplicatedStorage ▸ BotScores ▸ <id>, a
     Configuration: Name, Team, Kills, Deaths; Scoreboard counts them). A fallen
     bot comes back in its own seat (same name, same score); the seat goes when a
     player takes it. Seats last through the intermission and clear at the next round.

     Custom servers follow their host's settings (bots on/off, botCount, botSkill:
     GameConfig.CUSTOM_DEFAULTS; the host panel changes them live: Hub ▸ HostServer).
     Never on ranked servers (The Lists), Horde or the hubs. ]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Game = require(script.Parent:WaitForChild("Game"))
local Teams = Game.Teams

local BotFill = {}
BotFill.CONFIG = {
	RESPAWN = 5,            -- seconds a fallen bot's place stays empty
	PER_TICK = 2,           -- at most this many bots come in a second (no wall of spawns)
	MIX = {{"Squire", 0.6}, {"Knight", 0.33}, {"Champion", 0.07}},
	NEWCOMER_MIX = {{"Squire", 1}},
	WEAPONS = {"Longsword", "ArmingSword", "Mace", "Falchion", "Spear", "BattleAxe", "Shortsword", "Greatsword",
		"Hammer", "Halberd", "WarAxe", "Messer", "MorningStar", "Glaive"},
	NAMES = {"Aldo", "Bertram", "Cuthbert", "Drogo", "Edric", "Fulk", "Godwin", "Hamon", "Ivo", "Jocelin", "Kenric",
		"Lambert", "Merek", "Nigel", "Osric", "Piers", "Ranulf", "Simund", "Tybalt", "Ulric", "Walter", "Wat", "Hugh",
		"Gilbert", "Roger", "Alard", "Benet", "Colin", "Denis", "Everard", "Geoffrey", "Hob", "Jordan", "Milo", "Odo"},
}
local C = BotFill.CONFIG

local Bots   -- (lazily: Combat ▸ Bots)
local function bots()
	if not Bots then Bots = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots")) end
	return Bots
end

local active = false
local roundId = 0
local fill = {}          -- list of {bot, team, diedAt, seat}
local vacant = {}        -- seats whose bot fell and hasn't come back yet
local startedAt = 0

-- the seats on the board
local seatFolder = ReplicatedStorage:FindFirstChild("BotScores")
if not seatFolder then
	seatFolder = Instance.new("Folder")
	seatFolder.Name = "BotScores"
	seatFolder.Parent = ReplicatedStorage
end
local seatId = 0
local function dropSeat(seat) if seat then seat:Destroy() end end
-- a vacant seat of this side, or a new one
local function takeSeat(team, name)
	for i, seat in ipairs(vacant) do
		if seat:GetAttribute("Team") == (team or "") then table.remove(vacant, i); return seat end
	end
	seatId += 1
	local seat = Instance.new("Configuration")
	seat.Name = tostring(seatId)
	seat:SetAttribute("Name", name)
	seat:SetAttribute("Team", team or "")
	seat:SetAttribute("Kills", 0)
	seat:SetAttribute("Deaths", 0)
	seat.Parent = seatFolder
	return seat
end

-- is this server one that gets bots?
local function wanted(def)
	local sv = Game.server
	if sv.ranked or sv.door ~= "Warfront" then return nil end
	def = def or (Game.current and Game.current.def)
	if sv.custom then
		local s = sv.settings
		if not (s and s.bots ~= false) then return nil end
		local n = math.floor(tonumber(s.botCount) or 0)
		return (def and n > 0) and n or nil
	end
	return def and def.botFill or nil
end
-- the skills bots come in: a custom server's choice, else the usual mix
local function mixHere()
	local s = Game.server.custom and Game.server.settings
	local skill = s and s.botSkill
	if skill and skill ~= "Mixed" and bots().SKILLS[skill] then return {{skill, 1}} end
	return C.MIX
end

local function newcomerHere()
	for _, p in ipairs(Players:GetPlayers()) do
		local t = p:GetAttribute("Tutorial")
		if t ~= nil and t < 2 then return true end
	end
	return false
end

local function pick(mix)
	local r, acc = math.random(), 0
	for _, e in ipairs(mix) do acc += e[2]; if r <= acc then return e[1] end end
	return mix[1][1]
end

local usable
local function weaponList()
	if usable then return usable end
	usable = {}
	local f = ServerStorage:FindFirstChild("Weapons")
	for _, w in ipairs(C.WEAPONS) do if f and f:FindFirstChild(w) then table.insert(usable, w) end end
	if #usable == 0 then usable = {"Longsword"} end
	return usable
end

local nameAt = math.random(#C.NAMES)
local function nextName()
	nameAt = nameAt % #C.NAMES + 1
	return C.NAMES[nameAt]
end

-- what the objective is, for bots with nobody near (KOTH / Siege publish it)
local function objective()
	local p = Game.node:GetAttribute("ObjPos")
	return typeof(p) == "Vector3" and p or nil
end

local function spawnOne(team)
	local skill = pick(newcomerHere() and C.NEWCOMER_MIX or mixHere())
	local list = weaponList()
	local cf = Game.spawnCFrameForTeam(team)
	if not cf then return end
	local at = CFrame.new(cf.Position + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))) * (cf - cf.Position)
	local myRound = roundId
	local seat = takeSeat(team, nextName())
	local entry = {team = team, seat = seat}
	local ok, bot = pcall(bots().spawn, {
		at = at, skill = skill, weapon = list[math.random(#list)], team = team,
		name = seat:GetAttribute("Name"), fightBots = true, goal = objective, corpseTime = 6,
		startDelay = 0.5,
		onDeath = function(_, killer)
			entry.diedAt = os.clock()
			if roundId ~= myRound then return end
			-- (a teammate's blow is no kill)
			local kt = killer and killer.Character and killer.Character:GetAttribute("Team")
			if killer and team and kt == team then killer = nil end
			Game.onBotDeath(entry.bot.model, killer)
		end,
	})
	if not ok or not bot then warn("[BotFill] spawn failed:", bot); table.insert(vacant, seat); return end
	entry.bot = bot
	bot.model:SetAttribute("FillBot", true)
	bot.model:SetAttribute("BotSeat", seat.Name)
	if team then Teams.mark(bot.model, team) end
	table.insert(fill, entry)
	if team then Game.fielded[team] = (Game.fielded[team] or 0) + 1 end
end

-- a bot leaves (a player took its place): the one farthest from any player
local function retireOne(team)
	local best, bestD
	for _, e in ipairs(fill) do
		if e.team == team and not e.diedAt and e.bot.alive then
			local d = math.huge
			for _, p in ipairs(Players:GetPlayers()) do
				local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if hrp then d = math.min(d, (hrp.Position - e.bot.hrp.Position).Magnitude) end
			end
			if not best or d > bestD then best, bestD = e, d end
		end
	end
	if not best then
		-- a place being held for a fallen one: just let it go
		for i, e in ipairs(fill) do if e.team == team and e.diedAt then table.remove(fill, i); dropSeat(e.seat); return true end end
		return false
	end
	for i, e in ipairs(fill) do if e == best then table.remove(fill, i) break end end
	pcall(function() best.bot:destroy() end)
	dropSeat(best.seat)
	return true
end

-- (exported: the map pick wants the same number, for the mode it'll be)
BotFill.wanted = wanted

local function tick()
	local target = wanted()
	if not target then return end
	-- never more fighters than the map suits (GameConfig.MAP_FIGHTERS)
	local _, most = GameConfig.mapFighters(Game.node:GetAttribute("Map") or "")
	target = math.min(target, most)
	local def = Game.current.def
	local now = os.clock()
	-- forget the fallen whose place has come round again (or, no respawns, keep them)
	local respawns = not (def.respawnDelay == 0 or def.roundsToWin ~= nil)
	for i = #fill, 1, -1 do
		local e = fill[i]
		if (e.diedAt and respawns and now - e.diedAt >= C.RESPAWN) or (not e.diedAt and not e.bot.model.Parent) then
			table.remove(fill, i)
			table.insert(vacant, e.seat)   -- its next bot sits here (same name, same score)
		end
	end
	-- (one life a round: bots come in at the start only)
	if not respawns and now - startedAt > 15 then return end

	local sides = def.teams == 2 and {"A", "B"} or {false}
	local per = def.teams == 2 and math.ceil(target / 2) or target
	local spawned = 0
	for _, side in ipairs(sides) do
		local key = side or nil
		local players = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if key == nil or Teams.keyOf(p) == key then players += 1 end
		end
		local held = 0
		for _, e in ipairs(fill) do if e.team == key then held += 1 end end
		local want = math.max(0, per - players)
		if held > want then
			for _ = 1, held - want do if not retireOne(key) then break end end
		elseif held < want then
			for _ = 1, want - held do
				if spawned >= C.PER_TICK then break end
				spawnOne(key)
				spawned += 1
			end
		end
		-- seats nobody will come back to (a player took the place meanwhile)
		held = 0
		for _, e in ipairs(fill) do if e.team == key then held += 1 end end
		for i = #vacant, 1, -1 do
			if vacant[i]:GetAttribute("Team") == (key or "") then
				if held >= want then dropSeat(table.remove(vacant, i)) else held += 1 end
			end
		end
	end
end

-- the bots go; their seats stay on the board (the round's result) unless `seats`
local function clear(seats)
	for _, e in ipairs(fill) do
		if e.bot and e.bot.alive then pcall(function() e.bot:destroy() end) end
	end
	fill = {}
	vacant = {}
	Game.fielded = {A = 0, B = 0}
	if seats then seatFolder:ClearAllChildren() end
end

function BotFill.start()
	if active then return end
	active = true
	Game.roundStarted.Event:Connect(function()
		roundId += 1
		clear(true)
		startedAt = os.clock()
	end)
	Game.roundEnded.Event:Connect(function()
		roundId += 1
		clear()
	end)
	task.spawn(function()
		while true do
			if Game.node:GetAttribute("State") == "Round" then
				local ok, err = pcall(tick)
				if not ok then warn("[BotFill]", err) end
			end
			task.wait(1)
		end
	end)
end

-- how many fill bots are on the field now (tests, the admin panel)
function BotFill.count()
	local n = 0
	for _, e in ipairs(fill) do if not e.diedAt then n += 1 end end
	return n
end

return BotFill
