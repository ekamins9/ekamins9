--[[ CHEATS — admin commands on a custom server whose host turned Cheats on
     (the server pays no Marks, XP or rating). The host only; in Studio anyone.
        /god          invulnerable (toggle)        /heal          full health
        /speed 2      walk speed multiplier        /tp <name>     teleport to a player
        /bring <name> pull a player to you         /give <Weapon> a weapon from ServerStorage ▸ Weapons
        /kick <name>  remove a player ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")
local ServerScriptService = game:GetService("ServerScriptService")
local Game = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Game"))

local STUDIO = RunService:IsStudio()
local function allowed(plr)
	local sv = Game.server
	if not (sv.settings and sv.settings.cheats) then return STUDIO and sv.custom end
	return STUDIO or plr.UserId == sv.hostId
end
local function findPlayer(name)
	name = (name or ""):lower()
	if name == "" then return nil end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then return p end
	end
	return nil
end
local god = {}
local last = {}
local function handle(plr, text)
	local cmd, rest = text:match("^/(%a+)%s*(.*)$")
	if not cmd then return end
	cmd = cmd:lower()
	if not ({god = 1, heal = 1, speed = 1, tp = 1, bring = 1, give = 1, kick = 1})[cmd] then return end
	if os.clock() - (last[plr] or -1e9) < 0.3 then return end
	last[plr] = os.clock()
	if not allowed(plr) then return end
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if cmd == "god" and hum then
		god[plr] = not god[plr]
		if god[plr] then hum.MaxHealth = 1e6; hum.Health = 1e6 else local base = char:GetAttribute("BaseMaxHealth") or 100; hum.MaxHealth = base; hum.Health = base end
	elseif cmd == "heal" and hum then hum.Health = hum.MaxHealth
	elseif cmd == "speed" and char then char:SetAttribute("SpeedMult", math.clamp(tonumber(rest) or 1, 0.1, 10))
	elseif cmd == "tp" then local t = findPlayer(rest); local hrp = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart"); if hrp and char then char:PivotTo(hrp.CFrame * CFrame.new(0, 0, -4)) end
	elseif cmd == "bring" then local t = findPlayer(rest); local hrp = char and char:FindFirstChild("HumanoidRootPart"); if hrp and t and t.Character then t.Character:PivotTo(hrp.CFrame * CFrame.new(0, 0, -4)) end
	elseif cmd == "give" then local f = ServerStorage:FindFirstChild("Weapons"); local w = f and f:FindFirstChild(rest); if w and w:IsA("Tool") then w:Clone().Parent = plr:WaitForChild("Backpack") end
	elseif cmd == "kick" then local t = findPlayer(rest); if t and t ~= plr then t:Kick("Removed by the host.") end
	end
end
pcall(function()
	for _, name in ipairs({"god", "heal", "speed", "tp", "bring", "give", "kick"}) do
		local c = Instance.new("TextChatCommand"); c.Name = "Cheat_" .. name; c.PrimaryAlias = "/" .. name; c.Parent = TextChatService
		c.Triggered:Connect(function(source, text) local p = Players:GetPlayerByUserId(source.UserId); if p then handle(p, text) end end)
	end
end)
local function hook(plr) plr.Chatted:Connect(function(msg) handle(plr, msg) end) end
Players.PlayerAdded:Connect(hook)
for _, p in ipairs(Players:GetPlayers()) do hook(p) end
