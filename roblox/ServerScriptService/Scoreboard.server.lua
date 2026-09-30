--[[ SCOREBOARD — kills / deaths per player (leaderstats), the kill feed, and
     the bridge to the game mode: every player death is reported to Game
     (Game.onDeath) so modes can count tickets, lives, round kills, and
     stats land in the player's Profile.
     Credit comes from the LastHitBy / LastHitWith / LastHitKind attributes
     CombatServer stamps on a character every time it hurts it; a death
     within CREDIT_WINDOW of the last hit counts for that attacker. A kill on
     a TEAMMATE is a teamkill: no credit, marked in the feed.

       ReplicatedStorage.KillFeedRemote (RemoteEvent, created here)
         server -> all: "Kill", {killer=, victim=, weapon=, kind=, killerId=, victimId=, teamkill=}

     Test dummies appear in the feed (as victims or killers) but never on
     the board and never count for the mode — only players do. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DebugFlags        = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local CREDIT_WINDOW = 15   -- seconds after the last hit a death still counts for the hitter

-- optional: the game framework and profiles (missing → plain leaderstats)
local Game, Profile
do
	local gf = ServerScriptService:WaitForChild("Game", 10)
	local gm = gf and gf:FindFirstChild("Game")
	if gm then local ok, g = pcall(require, gm); if ok then Game = g end end
	local lf = ServerScriptService:FindFirstChild("Loadout")
	local pm = lf and lf:FindFirstChild("Profile")
	if pm then local ok, p = pcall(require, pm); if ok then Profile = p end end
end

local remote = Instance.new("RemoteEvent")
remote.Name = "KillFeedRemote"
remote.Parent = ReplicatedStorage

local function log(...) DebugFlags.log("Scoreboard", ...) end

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
	local killerPlr = killerId and killerId ~= 0 and Players:GetPlayerByUserId(killerId) or nil
	if killerPlr and killerPlr.Character == char then killerPlr = nil end   -- suicide
	local teamkill = killerPlr ~= nil and victimPlr ~= nil and sameTeam(killerPlr, victimPlr)
	if killerPlr and not teamkill then
		local k = stats(killerPlr):FindFirstChild("Kills")
		if k then k.Value += 1 end
		if Profile and victimPlr then Profile.addStat(killerPlr, "kills", 1) end
	end
	if Game and victimPlr then
		Game.onDeath(victimPlr, (not teamkill) and killerPlr or nil, char)
	end
	local entry = {
		victim   = char.Name,
		victimId = victimPlr and victimPlr.UserId or 0,
		killer   = killerName,
		killerId = killerId or 0,
		weapon   = recent and char:GetAttribute("LastHitWith") or "",
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

-- per-round reset of the board when a new round starts (profile stats keep counting)
if Game then
	Game.roundStarted.Event:Connect(function()
		for _, p in ipairs(Players:GetPlayers()) do
			local ls = stats(p)
			ls.Kills.Value, ls.Deaths.Value = 0, 0
		end
	end)
	Game.roundEnded.Event:Connect(function()
		-- a "wins" stat for whoever the mode named
		local w = Game.node:GetAttribute("Winner") or ""
		if w == "" or not Profile then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p.DisplayName == w or (p.Team and p.Team.Name == w) then Profile.addStat(p, "wins", 1) end
		end
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
