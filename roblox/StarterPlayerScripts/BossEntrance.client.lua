--[[ BOSS ENTRANCE — Siege's champion on his throne and the Horde's Warlord get the entrance the
     Depths' lords have (ReplicatedStorage ▸ BossIntro): when a bot in workspace ▸ NPCs becomes a
     Boss in one of those modes, the bars, the camera on it, its name, a boom. Once each.
     War's champions (Game ▸ Modes ▸ War:champion) get the bars and the name only: in the thick of
     a battle the camera stays yours.

     A BOSS FALLS (any boss in workspace ▸ NPCs, in any mode, within 200 studs of you): a deep
     boom and the ground shaking, a pillar of light where it stood, a ring of force rolling out
     over the floor, a cloud of dust, the world washing white for a moment. ]]

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
	War = function(m)
		local me = game:GetService("Players").LocalPlayer.Character
		local ours = me and me:GetAttribute("Team") ~= nil and me:GetAttribute("Team") == m:GetAttribute("Team")
		return string.upper(m:GetAttribute("TagName") or m.Name), ours and "YOUR CHAMPION TAKES THE FIELD" or "THEIR CHAMPION TAKES THE FIELD  ·  BRING HIM DOWN", true
	end,
}

local function check(m)
	local say = SAYS[round:GetAttribute("Mode") or ""]
	if not say or seen[m] or not m:GetAttribute("Boss") then return end
	if round:GetAttribute("State") ~= "Round" then return end
	seen[m] = true
	task.wait(0.4)   -- (dressed and standing first)
	if not m.Parent then return end
	local text, sub, nameOnly = say(m)
	BossIntro.play(not nameOnly and m or nil, text, sub)
end

-- A BOSS FALLS (BossIntro.falls)
local fallen = setmetatable({}, {__mode = "k"})
local function falls(m)
	if fallen[m] then return end
	fallen[m] = true
	local root = m:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local scale = m:GetAttribute("MonsterScale") or 1
	BossIntro.falls(root.Position - Vector3.new(0, 3 * scale, 0), scale)
end

local function watch(npcs)
	local function hook(m)
		if not m:IsA("Model") then return end
		task.spawn(function()
			local h = m:FindFirstChildOfClass("Humanoid") or m:WaitForChild("Humanoid", 5)
			if h then h.Died:Connect(function() if m:GetAttribute("Boss") then falls(m) end end) end
		end)
		m:GetAttributeChangedSignal("Boss"):Connect(function() task.spawn(check, m) end)
		if m:GetAttribute("Boss") then task.spawn(check, m) end
	end
	for _, m in ipairs(npcs:GetChildren()) do hook(m) end
	npcs.ChildAdded:Connect(hook)
end
local npcs = workspace:FindFirstChild("NPCs")
if npcs then watch(npcs) end
workspace.ChildAdded:Connect(function(c) if c.Name == "NPCs" then watch(c) end end)
