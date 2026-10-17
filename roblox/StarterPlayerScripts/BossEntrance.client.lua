--[[ BOSS ENTRANCE — Siege's champion on his throne and the Horde's Warlord get the entrance the
     Depths' lords have (ReplicatedStorage ▸ BossIntro): when a bot in workspace ▸ NPCs becomes a
     Boss in one of those modes, the bars, the camera on it, its name, a boom. Once each. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossIntro = require(ReplicatedStorage:WaitForChild("BossIntro"))

local round = ReplicatedStorage:WaitForChild("Round")
local seen = setmetatable({}, {__mode = "k"})

-- what the bars say, by mode
local SAYS = {
	Siege = function(m)
		local title = round:GetAttribute("MapName") or round:GetAttribute("Map") or "the castle"
		return string.upper(m:GetAttribute("TagName") or m.Name), "THE CHAMPION OF " .. string.upper(title) .. "  ·  SLAY HIM"
	end,
	Horde = function(m)
		return string.upper(m:GetAttribute("TagName") or "THE WARLORD"), "THE WARLORD LEADS THIS WAVE  ·  HOLD THE CAMP"
	end,
}

local function check(m)
	local say = SAYS[round:GetAttribute("Mode") or ""]
	if not say or seen[m] or not m:GetAttribute("Boss") then return end
	if round:GetAttribute("State") ~= "Round" then return end
	seen[m] = true
	task.wait(0.4)   -- (dressed and standing first)
	if not m.Parent then return end
	local text, sub = say(m)
	BossIntro.play(m, text, sub)
end

local function watch(npcs)
	local function hook(m)
		if not m:IsA("Model") then return end
		m:GetAttributeChangedSignal("Boss"):Connect(function() task.spawn(check, m) end)
		if m:GetAttribute("Boss") then task.spawn(check, m) end
	end
	for _, m in ipairs(npcs:GetChildren()) do hook(m) end
	npcs.ChildAdded:Connect(hook)
end
local npcs = workspace:FindFirstChild("NPCs")
if npcs then watch(npcs) end
workspace.ChildAdded:Connect(function(c) if c.Name == "NPCs" then watch(c) end end)
