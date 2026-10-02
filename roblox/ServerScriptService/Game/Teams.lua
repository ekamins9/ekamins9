--[[ TEAMS — two sides, "A" and "B" (names/colors in GameConfig.TEAMS), on top
     of Roblox's Teams service so overhead names take the team color. A
     character carries a Team attribute ("A"/"B") that combat reads for
     friendly fire, and a coloured tabard so you can tell at a glance.
     Parties (HubServer sets a Party attribute on players) stay together. ]]

local Players = game:GetService("Players")
local TeamsService = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Teams = {}
local objects = {}   -- [key] = Team instance

local function ensure()
	for key, def in pairs(GameConfig.TEAMS) do
		local t = TeamsService:FindFirstChild(def.name)
		if not t then
			t = Instance.new("Team")
			t.Name = def.name
			t.TeamColor = def.color
			t.AutoAssignable = false
			t.Parent = TeamsService
		end
		objects[key] = t
	end
end
ensure()

function Teams.keyOf(plr)
	local t = plr and plr.Team
	if not t then return nil end
	for key, obj in pairs(objects) do if obj == t then return key end end
	return nil
end

function Teams.count(key)
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do if Teams.keyOf(p) == key then n += 1 end end
	return n
end

function Teams.set(plr, key)
	plr.Team = key and objects[key] or nil
	plr.Neutral = key == nil
	if plr.Character then Teams.mark(plr.Character, key) end
end

-- the smaller team, party members with their leader
function Teams.assign(plr)
	local party = plr:GetAttribute("Party")
	if party then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= plr and p:GetAttribute("Party") == party and Teams.keyOf(p) then
				Teams.set(plr, Teams.keyOf(p))
				return Teams.keyOf(plr)
			end
		end
	end
	local a, b = Teams.count("A"), Teams.count("B")
	Teams.set(plr, (a <= b) and "A" or "B")
	return Teams.keyOf(plr)
end

-- everyone onto balanced teams (round start), keeping parties together
function Teams.assignAll()
	local list = Players:GetPlayers()
	table.sort(list, function(x, y) return (x:GetAttribute("Party") or 0) < (y:GetAttribute("Party") or 0) end)
	for _, p in ipairs(list) do Teams.set(p, nil) end
	for _, p in ipairs(list) do Teams.assign(p) end
end

function Teams.clearAll()
	for _, p in ipairs(Players:GetPlayers()) do Teams.set(p, nil) end
end

-- the tabard: a thin plate on the chest in the team colour (or none)
function Teams.mark(char, key)
	char:SetAttribute("Team", key)
	local old = char:FindFirstChild("Tabard")
	if old then old:Destroy() end
	local torso = char:FindFirstChild("Torso")
	if not (key and torso) then return end
	-- armor with color blocks already wears the team color (Dresser): no plate
	if char:GetAttribute("TeamPainted") == true then return end
	local def = GameConfig.TEAMS[key]
	local plate = Instance.new("Part")
	plate.Name = "Tabard"
	plate.Size = Vector3.new(1.6, 1.4, 0.12)
	plate.Color = def.rgb
	plate.Material = Enum.Material.Fabric
	plate.CanCollide, plate.CanQuery, plate.CanTouch, plate.Massless = false, false, false, true
	plate.CFrame = torso.CFrame * CFrame.new(0, 0.1, -0.56)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1, w.Parent = torso, plate, plate
	plate.Parent = char
end

function Teams.sameTeam(charA, charB)
	local a, b = charA and charA:GetAttribute("Team"), charB and charB:GetAttribute("Team")
	return a ~= nil and a == b
end

function Teams.aliveCount(key)
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if Teams.keyOf(p) == key then
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then n += 1 end
		end
	end
	return n
end

function Teams.def(key) return GameConfig.TEAMS[key] end

return Teams
