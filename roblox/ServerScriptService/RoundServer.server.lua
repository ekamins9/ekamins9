--[[ ROUND SERVER — the game loop: free-for-all rounds of ROUND_LENGTH,
     the top killer wins, INTERMISSION seconds with the board up, then a
     fresh round where everyone comes back in through the loadout menu.

     Publishes on ReplicatedStorage.Round (a Configuration, attributes):
       State     "Round" | "Intermission"
       TimeLeft  whole seconds left in the current state
       Number    round counter
       Winner    name of the last round's winner ("" if nobody scored)
       WinnerKills
     LoadoutServer refuses spawns in an intermission and re-opens the menu
     at round start; Scoreboard.client shows the timer and forces the
     leaderboard open during the intermission. A round only counts down
     while someone is in the server. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugFlags        = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local ROUND_LENGTH = 5 * 60   -- seconds
local INTERMISSION = 15
local MIN_PLAYERS  = 1        -- rounds tick only with at least this many in

local function log(...) DebugFlags.log("Round", ...) end

local node = Instance.new("Configuration")
node.Name = "Round"
node:SetAttribute("State", "Round")
node:SetAttribute("TimeLeft", ROUND_LENGTH)
node:SetAttribute("Number", 1)
node:SetAttribute("Winner", "")
node:SetAttribute("WinnerKills", 0)
node.Parent = ReplicatedStorage

local function resetStats()
	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		if ls then
			for _, v in ipairs(ls:GetChildren()) do
				if v:IsA("IntValue") then v.Value = 0 end
			end
		end
	end
end

local function winner()
	local best, bestK = nil, 0
	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		local k = ls and ls:FindFirstChild("Kills")
		if k and k.Value > bestK then best, bestK = p, k.Value end
	end
	return best, bestK
end

local function setState(state, seconds)
	node:SetAttribute("State", state)
	node:SetAttribute("TimeLeft", seconds)
end

-- counts down TimeLeft while players are present; returns when it hits 0
local function countdown(seconds)
	local left = seconds
	while left > 0 do
		task.wait(1)
		if #Players:GetPlayers() >= MIN_PLAYERS then
			left -= 1
			node:SetAttribute("TimeLeft", left)
		end
	end
end

task.spawn(function()
	while true do
		log("round", node:GetAttribute("Number"), "started")
		setState("Round", ROUND_LENGTH)
		countdown(ROUND_LENGTH)

		local w, k = winner()
		node:SetAttribute("Winner", w and w.DisplayName or "")
		node:SetAttribute("WinnerKills", k)
		log("round over — winner:", w and w.Name or "nobody", k)
		setState("Intermission", INTERMISSION)
		countdown(INTERMISSION)

		resetStats()
		node:SetAttribute("Number", node:GetAttribute("Number") + 1)
	end
end)
