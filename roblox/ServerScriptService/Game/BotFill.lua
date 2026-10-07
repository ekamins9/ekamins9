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

     Not on custom servers, ranked ones (The Lists), Horde or the hubs. ]]

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
local fill = {}          -- list of {bot, team, diedAt}
local startedAt = 0

-- is this server one that gets bots?
local function wanted()
	local sv = Game.server
	if sv.custom or sv.ranked or sv.door ~= "Warfront" then return nil end
	local def = Game.current and Game.current.def
	return def and def.botFill or nil
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
	local skill = pick(newcomerHere() and C.NEWCOMER_MIX or C.MIX)
	local list = weaponList()
	local cf = Game.spawnCFrameForTeam(team)
	if not cf then return end
	local at = CFrame.new(cf.Position + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))) * (cf - cf.Position)
	local myRound = roundId
	local entry = {team = team}
	local ok, bot = pcall(bots().spawn, {
		at = at, skill = skill, weapon = list[math.random(#list)], team = team,
		name = nextName(), fightBots = true, goal = objective, corpseTime = 6,
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
	if not ok or not bot then warn("[BotFill] spawn failed:", bot); return end
	entry.bot = bot
	bot.model:SetAttribute("FillBot", true)
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
		for i, e in ipairs(fill) do if e.team == team and e.diedAt then table.remove(fill, i); return true end end
		return false
	end
	for i, e in ipairs(fill) do if e == best then table.remove(fill, i) break end end
	pcall(function() best.bot:destroy() end)
	return true
end

local function tick()
	local target = wanted()
	if not target then return end
	local def = Game.current.def
	local now = os.clock()
	-- forget the fallen whose place has come round again (or, no respawns, keep them)
	local respawns = not (def.respawnDelay == 0 or def.roundsToWin ~= nil)
	for i = #fill, 1, -1 do
		local e = fill[i]
		if e.diedAt and respawns and now - e.diedAt >= C.RESPAWN then table.remove(fill, i) end
		if not e.diedAt and not e.bot.model.Parent then table.remove(fill, i) end
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
	end
end

local function clear()
	for _, e in ipairs(fill) do
		if e.bot and e.bot.alive then pcall(function() e.bot:destroy() end) end
	end
	fill = {}
	Game.fielded = {A = 0, B = 0}
end

function BotFill.start()
	if active then return end
	active = true
	Game.roundStarted.Event:Connect(function()
		roundId += 1
		clear()
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
