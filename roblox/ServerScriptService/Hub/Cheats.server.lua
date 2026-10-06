--[[ CHEATS — admin commands on a custom server whose host turned Cheats on
     (the server pays no Marks, XP or rating). The host only; in Studio anyone.
        /god          invulnerable (toggle)        /heal          full health
        /speed 2      walk speed multiplier        /tp <name>     teleport to a player
        /bring <name> pull a player to you         /give <Weapon> a weapon from ServerStorage ▸ Weapons
        /kick <name>  remove a player
     TESTING (Studio only, any server): /marks <n>  /crowns <n>  /xp <n>  /level <n>  /passxp <n>
        add that much to your wallet / XP (level = level-ups) / season pass XP, e.g. /marks 5000
        /egg <Id> [n]  eggs for the Hatchery   /ripen  every nest ready   /playtime <minutes> ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")
local ServerScriptService = game:GetService("ServerScriptService")
local Game = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Game"))
local Economy = require(ServerScriptService:WaitForChild("Economy"):WaitForChild("Economy"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))

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
-- XP needed to reach `level` (Catalog ▸ Economy ▸ levels; past the list the last value repeats)
local Catalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Catalog"))
local function Catalog_levels(level)
	local L = Catalog.ECONOMY.levels
	return L[level] or L[#L]
end
local function handle(plr, text)
	local cmd, rest = text:match("^/(%a+)%s*(.*)$")
	if not cmd then return end
	cmd = cmd:lower()
	if not ({god = 1, heal = 1, speed = 1, tp = 1, bring = 1, give = 1, kick = 1, marks = 1, crowns = 1, xp = 1, level = 1, passxp = 1, egg = 1, ripen = 1, playtime = 1})[cmd] then return end
	if os.clock() - (last[plr] or -1e9) < 0.3 then return end
	last[plr] = os.clock()
	-- testing cheats: Studio only, no server setting needed
	if cmd == "egg" or cmd == "ripen" or cmd == "playtime" then
		if not STUDIO then return end
		local Pastimes = require(ServerScriptService.Economy:WaitForChild("Pastimes"))
		if cmd == "egg" then
			local id, n = rest:match("^(%S+)%s*(%d*)")
			Pastimes.grantEgg(plr, id or "Speckled", tonumber(n) or 1)
		elseif cmd == "ripen" then
			Pastimes.boost(plr, 10 ^ 6)
		else
			Pastimes.addPlaytime(plr, (tonumber(rest) or 10) * 60)
		end
		Economy.changed:Fire(plr)
		return
	end
	if cmd == "marks" or cmd == "crowns" or cmd == "xp" or cmd == "level" or cmd == "passxp" then
		if not STUDIO then return end
		local n = math.floor(tonumber(rest) or 0)
		if n == 0 then return end
		local p = Profile.get(plr)
		if cmd == "marks" then p.wallet.marks = math.max(0, p.wallet.marks + n)
		elseif cmd == "crowns" then p.wallet.crowns = math.max(0, p.wallet.crowns + n)
		elseif cmd == "xp" then Economy.addXP(plr, math.max(0, n))
		elseif cmd == "passxp" then Economy.addPassXP(plr, math.max(0, n))
		elseif cmd == "level" then
			for _ = 1, math.clamp(n, 1, 100) do Economy.addXP(plr, Catalog_levels(p.level + 1) - p.xp) end
		end
		Profile.markDirty(plr)
		Economy.changed:Fire(plr)
		return
	end
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
	for _, name in ipairs({"god", "heal", "speed", "tp", "bring", "give", "kick", "marks", "crowns", "xp", "level", "passxp", "egg", "ripen", "playtime"}) do
		local c = Instance.new("TextChatCommand"); c.Name = "Cheat_" .. name; c.PrimaryAlias = "/" .. name; c.Parent = TextChatService
		c.Triggered:Connect(function(source, text) local p = Players:GetPlayerByUserId(source.UserId); if p then handle(p, text) end end)
	end
end)
local function hook(plr) plr.Chatted:Connect(function(msg) handle(plr, msg) end) end
Players.PlayerAdded:Connect(hook)
for _, p in ipairs(Players:GetPlayers()) do hook(p) end
