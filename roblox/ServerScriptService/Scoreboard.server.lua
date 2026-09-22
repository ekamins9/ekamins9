--[[ SCOREBOARD — kills / deaths per player (leaderstats) and the kill feed.
     Credit comes from the LastHitBy / LastHitWith / LastHitKind attributes
     CombatServer stamps on a character every time it hurts it; a death
     within CREDIT_WINDOW of the last hit counts for that attacker.

       ReplicatedStorage.KillFeedRemote (RemoteEvent, created here)
         server -> all: "Kill", {killer=, victim=, weapon=, kind=, killerId=, victimId=}

     Test dummies appear in the feed (as victims or killers) but never on
     the board — only players have leaderstats. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugFlags        = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local CREDIT_WINDOW = 15   -- seconds after the last hit a death still counts for the hitter

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

local function onDied(char)
	local victimPlr = Players:GetPlayerFromCharacter(char)
	if victimPlr then
		local d = stats(victimPlr):FindFirstChild("Deaths")
		if d then d.Value += 1 end
	end
	local recent = os.clock() - (char:GetAttribute("LastHitAt") or -1e9) <= CREDIT_WINDOW
	local killerId   = recent and char:GetAttribute("LastHitBy") or nil
	local killerName = recent and char:GetAttribute("LastHitByName") or nil
	if killerName == "" then killerName = nil end
	local killerPlr = killerId and killerId ~= 0 and Players:GetPlayerByUserId(killerId)
	if killerPlr and killerPlr.Character ~= char then
		local k = stats(killerPlr):FindFirstChild("Kills")
		if k then k.Value += 1 end
	end
	local entry = {
		victim   = char.Name,
		victimId = victimPlr and victimPlr.UserId or 0,
		killer   = killerName,
		killerId = killerId or 0,
		weapon   = recent and char:GetAttribute("LastHitWith") or "",
		kind     = recent and char:GetAttribute("LastHitKind") or "",
	}
	remote:FireAllClients("Kill", entry)
	log(entry.killer or "(nobody)", "killed", entry.victim, entry.kind)
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
