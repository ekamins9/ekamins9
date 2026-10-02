--[[ SCOREBOARD — kills / deaths per player (leaderstats), the kill feed, the
     bridge to the game mode (Game.onDeath), and the PAY at the end of every
     round: Economy.award per player (round / win / kills / parries / chambers),
     stats + contracts (Stats), ranked ratings and the leaderboards for The
     Lists, the kills board for the Warfront.

     Credit comes from the LastHitBy / LastHitWith / LastHitKind attributes
     CombatServer stamps on a character every time it hurts it; a death
     within CREDIT_WINDOW of the last hit counts for that attacker. A kill on
     a TEAMMATE is a teamkill: no credit, marked in the feed.

       ReplicatedStorage.KillFeedRemote (RemoteEvent, created here)
         server -> all: "Kill", {killer=, victim=, weapon=, kind=, killerId=, victimId=, teamkill=}
       ReplicatedStorage.HubEvent "Rewards", {marks, xp, level, levels, firstWin, blocked, won, kills, parries, result, rating, delta}

     Test dummies appear in the feed but never on the board, never pay. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService  = game:GetService("DataStoreService")
local DebugFlags        = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local GameConfig        = require(ReplicatedStorage:WaitForChild("GameConfig"))

local CREDIT_WINDOW = 15   -- seconds after the last hit a death still counts for the hitter
local K_FACTOR = 32        -- ranked rating swing per match (Elo)

-- the game framework, profiles, economy (any missing → plain leaderstats)
local Game, Profile, Economy, Stats, Catalog
do
	local function try(folder, name)
		local f = folder and folder:FindFirstChild(name)
		if not f then return nil end
		local ok, m = pcall(require, f)
		return ok and m or nil
	end
	local gf = ServerScriptService:WaitForChild("Game", 10)
	Game = try(gf, "Game")
	Profile = try(ServerScriptService:FindFirstChild("Loadout"), "Profile")
	local ef = ServerScriptService:FindFirstChild("Economy")
	Economy = try(ef, "Economy")
	Stats = try(ef, "Stats")
	local c = ReplicatedStorage:FindFirstChild("Catalog")
	if c then local ok, m = pcall(require, c); if ok then Catalog = m end end
end

local remote = Instance.new("RemoteEvent")
remote.Name = "KillFeedRemote"
remote.Parent = ReplicatedStorage

local function log(...) DebugFlags.log("Scoreboard", ...) end
local function hubEvent() return ReplicatedStorage:FindFirstChild("HubEvent") end

local function stats(plr)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		local k = Instance.new("IntValue"); k.Name = "Kills";  k.Parent = ls
		local d = Instance.new("IntValue"); d.Name = "Deaths"; d.Parent = ls
		ls.Parent = plr
	end
	return ls
end

local function sameTeam(a, b)
	return a ~= nil and b ~= nil and a.Team ~= nil and a.Team == b.Team
end

-- per-round counters for the pay (kills, parries, chambers)
local roundCount = {}   -- [plr] = {kill=, parry=, chamber=}
local function bump(plr, key)
	local c = roundCount[plr]
	if not c then c = {}; roundCount[plr] = c end
	c[key] = (c[key] or 0) + 1
end
-- parries / chambers come through _G.StatHook (set by Stats); count them for the round too
task.defer(function()
	local prev = _G.StatHook
	_G.StatHook = function(char, key)
		if prev then prev(char, key) end
		local plr = Players:GetPlayerFromCharacter(char)
		if plr then bump(plr, key) end
	end
end)

local function onDied(char)
	local victimPlr = Players:GetPlayerFromCharacter(char)
	if victimPlr then
		local d = stats(victimPlr):FindFirstChild("Deaths")
		if d then d.Value += 1 end
		if Profile then Profile.addStat(victimPlr, "deaths", 1) end
	end
	local recent = os.clock() - (char:GetAttribute("LastHitAt") or -1e9) <= CREDIT_WINDOW
	local killerId   = recent and char:GetAttribute("LastHitBy") or nil
	local killerName = recent and char:GetAttribute("LastHitByName") or nil
	if killerName == "" then killerName = nil end
	local weapon = recent and char:GetAttribute("LastHitWith") or ""
	local killerPlr = killerId and killerId ~= 0 and Players:GetPlayerByUserId(killerId) or nil
	if killerPlr and killerPlr.Character == char then killerPlr = nil end   -- suicide
	local teamkill = killerPlr ~= nil and victimPlr ~= nil and sameTeam(killerPlr, victimPlr)
	if killerPlr and not teamkill then
		local k = stats(killerPlr):FindFirstChild("Kills")
		if k then k.Value += 1 end
		if victimPlr then
			bump(killerPlr, "kill")
			if Stats then Stats.weaponKill(killerPlr, weapon) elseif Profile then Profile.addStat(killerPlr, "kill", 1) end
		end
	end
	if Game and victimPlr then
		Game.onDeath(victimPlr, (not teamkill) and killerPlr or nil, char)
	end
	local entry = {
		victim   = char.Name,
		victimId = victimPlr and victimPlr.UserId or 0,
		killer   = killerName,
		killerId = killerId or 0,
		weapon   = weapon,
		kind     = recent and char:GetAttribute("LastHitKind") or "",
		teamkill = teamkill,
	}
	remote:FireAllClients("Kill", entry)
	log(entry.killer or "(nobody)", teamkill and "TEAMKILLED" or "killed", entry.victim, entry.kind)
end

local function setup(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	hum.Died:Once(function() onDied(char) end)
end

local function onPlayer(plr)
	stats(plr)
	plr.CharacterAdded:Connect(setup)
	if plr.Character then setup(plr.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
Players.PlayerRemoving:Connect(function(plr)
	roundCount[plr] = nil
	-- leaving a ranked match before it's over: a queue lock
	if Game and Profile and Catalog and Game.server.ranked and Game.node:GetAttribute("MatchOver") ~= true and Game.node:GetAttribute("State") ~= "" then
		local p = Profile.get(plr)
		p.queueLock = p.queueLock or {}
		p.queueLock[Game.server.bracket or "1v1"] = os.time() + (Catalog.ECONOMY.queueLockMinutes or 10) * 60
		Profile.markDirty(plr)
	end
end)

--------------------------------------------------------------------
--  ROUND END: pay, stats, boards, ratings
--------------------------------------------------------------------
local function board(name) local ok, ds = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, name); return ok and ds or nil end

local function wonBy(plr, winner)
	if winner == "" then return false end
	if plr.DisplayName == winner then return true end
	for key, t in pairs(GameConfig.TEAMS) do
		if t.name == winner then return Game.teamOf(plr) == key end
	end
	return false
end

-- Elo for two sides: returns delta for side A's players (B gets -delta)
local function ratingDelta(avgA, avgB, aWon)
	local expA = 1 / (1 + 10 ^ ((avgB - avgA) / 400))
	return math.floor(K_FACTOR * ((aWon and 1 or 0) - expA) + 0.5)
end

local function rankedResult(winner)
	if not (Game and Profile and Game.server.ranked and Game.server.bracket) then return {} end
	local bracket = Game.server.bracket
	local sideOf = {}
	local sumA, nA, sumB, nB = 0, 0, 0, 0
	for _, p in ipairs(Players:GetPlayers()) do
		local key = Game.teamOf(p)
		if key == "A" or key == "B" then
			sideOf[p] = key
			local r = Profile.rating(p, bracket)
			if key == "A" then sumA += r; nA += 1 else sumB += r; nB += 1 end
		end
	end
	if nA == 0 or nB == 0 then return {} end
	local winKey
	for key, t in pairs(GameConfig.TEAMS) do if t.name == winner then winKey = key end end
	if not winKey then return {} end
	local dA = ratingDelta(sumA / nA, sumB / nB, winKey == "A")
	local out = {}
	local ds = board("LB_" .. bracket)
	for p, key in pairs(sideOf) do
		local d = key == "A" and dA or -dA
		local r = math.max(0, Profile.rating(p, bracket) + d)
		Profile.setRating(p, bracket, r)
		local prof = Profile.get(p)
		prof.placements[bracket] = (prof.placements[bracket] or 0) + 1
		out[p] = {rating = r, delta = d}
		if ds then task.spawn(function() pcall(ds.SetAsync, ds, tostring(p.UserId), r) end) end
	end
	return out
end

if Game then
	Game.roundStarted.Event:Connect(function()
		roundCount = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local ls = stats(p)
			ls.Kills.Value, ls.Deaths.Value = 0, 0
		end
	end)

	Game.roundEnded.Event:Connect(function(modeId, result)
		if modeId == "Hub" or modeId == "Tiltyard" then return end   -- the Courtyard pays nothing; drills pay through their own hook
		local winner = Game.node:GetAttribute("Winner") or ""
		local matchOver = Game.node:GetAttribute("MatchOver") == true or (Game.server.door ~= "Lists")
		local ranked = (Game.server.door == "Lists" and matchOver) and rankedResult(winner) or {}
		local kills = board("LB_Warfront")
		local ev = hubEvent()
		for _, p in ipairs(Players:GetPlayers()) do
			local c = roundCount[p] or {}
			local won = wonBy(p, winner)
			local events = {round = 1, win = won and 1 or 0, kill = c.kill or 0, parry = c.parry or 0, chamber = c.chamber or 0}
			local pay = Economy and Economy.award(p, events) or {marks = 0, xp = 0, levels = 0}
			if Stats and not (Economy and pay.blocked) then
				Stats.add(p, "round", 1)
				if won then
					Stats.add(p, "win", 1)
					if Game.server.bracket then Stats.add(p, "win_" .. Game.server.bracket, 1) end
				end
			elseif Profile then
				Profile.addStat(p, "round", 1); if won then Profile.addStat(p, "win", 1) end
			end
			if kills and Profile and Game.server.door == "Warfront" and not Game.server.custom then
				local total = Profile.get(p).stats.kill or 0
				task.spawn(function() pcall(kills.SetAsync, kills, tostring(p.UserId), total) end)
			end
			if ev then
				local r = ranked[p]
				ev:FireClient(p, "Rewards", {marks = pay.marks or 0, xp = pay.xp or 0, level = pay.level, levels = pay.levels or 0,
					firstWin = pay.firstWin == true, blocked = pay.blocked == true, won = won, kills = events.kill, parries = events.parry,
					result = result, rating = r and r.rating or nil, delta = r and r.delta or nil, matchOver = Game.node:GetAttribute("MatchOver") == true})
			end
		end
		roundCount = {}
	end)
end

local npcs = workspace:FindFirstChild("NPCs")
if not npcs then
	npcs = Instance.new("Folder")
	npcs.Name = "NPCs"
	npcs.Parent = workspace
end
for _, m in ipairs(npcs:GetChildren()) do
	if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then setup(m) end
end
npcs.ChildAdded:Connect(function(m)
	if m:IsA("Model") then task.defer(setup, m) end
end)
