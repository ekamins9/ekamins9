--[[ TEAMS — two sides, "A" and "B" (names/colors in GameConfig.TEAMS), on top
     of Roblox's Teams service so overhead names take the team color. A
     character carries a Team attribute ("A"/"B") that combat reads for
     friendly fire, and a coloured tabard so you can tell at a glance, its house's
     badge on the chest; with no side (a free-for-all, a duel, the Courtyard) a player
     wears their own coat of arms there instead, on a roundel of their colour.
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

-- HIS HOUSE ON HIS CHEST: the arms his side's banners fly on this map (ReplicatedStorage ▸ Houses),
-- a gold badge on the front of whatever he wears, found by looking at his chest from in front
local function houseBadge(char, key, torso)
	local old = char:FindFirstChild("HouseBadge")
	if old then old:Destroy() end
	local RS = game:GetService("ReplicatedStorage")
	local art = RS:FindFirstChild("ShieldArt")
	local emblem, metal, edge, field
	if key == "A" or key == "B" then
		local map = workspace:FindFirstChild("Map")
		local okH, e = pcall(function() return require(RS:WaitForChild("Houses")).forTeam(key, map and map:GetAttribute("HouseSeed")) end)
		emblem = okH and e or nil
	else
		-- no side: their own arms (Profile.publishArms: "emblem|metal|field"), on a roundel
		local plr = Players:GetPlayerFromCharacter(char)
		local arms = plr and plr:GetAttribute("Arms")
		if type(arms) ~= "string" then return end
		local e, m, f = string.match(arms, "^([^|]+)|([^|]*)|(.*)$")
		local okC, Catalog = pcall(require, RS:WaitForChild("Catalog"))
		local A = okC and Catalog.ARMS
		if not (e and A and A.EMBLEM[e]) then return end
		local mt = A.METAL[m] or A.METALS[1]
		local fc = Catalog.COLOR[f or ""]
		emblem, metal, edge, field = e, mt.color, mt.edge, fc and fc.color or Color3.fromRGB(40, 44, 62)
	end
	if not (emblem and art and art:FindFirstChild(emblem)) then return end
	local look, up = torso.CFrame.LookVector, torso.CFrame.UpVector
	local chest = torso.Position + up * 0.25
	-- (the first of his visible parts a line into his chest from in front meets: armor isn't
	--  queryable, so each part's box is tested by hand)
	local from, dir = chest + look * 3, -look
	local best = 3 - 0.5
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 0.9 and part.Name ~= "HumanoidRootPart" and part.Name ~= "HouseBadge" then
			local o = part.CFrame:PointToObjectSpace(from)
			local d = part.CFrame:VectorToObjectSpace(dir)
			local h = part.Size / 2
			local t0, t1 = -math.huge, math.huge
			for _, ax in ipairs({"X", "Y", "Z"}) do
				local oa, da, ha = o[ax], d[ax], h[ax]
				if math.abs(da) < 1e-6 then
					if oa < -ha or oa > ha then t0 = math.huge; break end
				else
					local ta, tb = (-ha - oa) / da, (ha - oa) / da
					if ta > tb then ta, tb = tb, ta end
					t0, t1 = math.max(t0, ta), math.min(t1, tb)
				end
			end
			if t0 <= t1 and t0 >= 0 and t0 < best then best = t0 end
		end
	end
	local at = from + dir * best
	local p = Instance.new("Part")
	p.Name = "HouseBadge"
	p.Size = Vector3.new(1.05, 1.05, 0.01)
	p.Transparency = 1
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = false, false, false, false, true
	p.CFrame = CFrame.lookAt(at + look * 0.03, at + look * 2, up)
	for z, layer in ipairs({{emblem .. "_o", edge or Color3.fromRGB(26, 20, 18)}, {emblem, metal or Color3.new(1.06, 0.84, 0.4)}}) do
		local v = art:FindFirstChild(layer[1])
		if v then
			-- (the decal on the plate's back face: CFrame.lookAt points its -Z, the Front, outward)
			local d = Instance.new("Decal")
			d.Face = Enum.NormalId.Front
			d.Texture, d.Color3, d.ZIndex = v.Value, layer[2], z
			d.Parent = p
		end
	end
	-- (their own arms stand a little proud, on a roundel of their colour rimmed in their metal's edge)
	if field then p.CFrame = p.CFrame * CFrame.new(0, 0, -0.07) end
	local w = Instance.new("Weld"); w.Part0, w.Part1 = torso, p; w.C0 = torso.CFrame:ToObjectSpace(p.CFrame); w.Parent = p
	if field then
		local disc = Instance.new("Part")
		disc.Name = "Roundel"
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.03, 1.3, 1.3)
		disc.Color = field
		disc.Material = Enum.Material.Fabric
		disc.CanCollide, disc.CanQuery, disc.CanTouch, disc.CastShadow, disc.Massless = false, false, false, false, true
		disc.CFrame = p.CFrame * CFrame.new(0, 0, 0.03) * CFrame.Angles(0, math.pi / 2, 0)
		disc.Parent = p
		local rim = disc:Clone()
		rim.Name = "RoundelRim"
		rim.Size = Vector3.new(0.03, 1.42, 1.42)
		rim.Color = edge
		rim.CFrame = p.CFrame * CFrame.new(0, 0, 0.06) * CFrame.Angles(0, math.pi / 2, 0)
		rim.Parent = p
		for _, d in ipairs({disc, rim}) do
			local dw = Instance.new("WeldConstraint"); dw.Part0, dw.Part1 = p, d; dw.Parent = d
		end
	end
	p.Parent = char
end

-- the tabard: a thin plate on the chest in the team colour (or none), and his house's badge over it
local tabard
function Teams.mark(char, key)
	tabard(char, key)
	local torso = char:FindFirstChild("Torso")
	if torso then pcall(houseBadge, char, key, torso) end
end
tabard = function(char, key)
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
function Teams.object(key) return objects[key] end

-- the match's fill bots (Game ▸ BotFill) of a side, living
function Teams.botsAlive(key)
	local n = 0
	local f = workspace:FindFirstChild("NPCs")
	for _, m in ipairs(f and f:GetChildren() or {}) do
		if m:GetAttribute("FillBot") and m:GetAttribute("Team") == key then
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then n += 1 end
		end
	end
	return n
end
-- every living fighter of a side, bots included: {[model] = root}
function Teams.fighters(key)
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if c and hum and hum.Health > 0 and (key == nil or Teams.keyOf(p) == key) and c:FindFirstChild("HumanoidRootPart") then out[c] = c.HumanoidRootPart end
	end
	local f = workspace:FindFirstChild("NPCs")
	for _, m in ipairs(f and f:GetChildren() or {}) do
		if m:GetAttribute("FillBot") and (key == nil or m:GetAttribute("Team") == key) then
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 and m:FindFirstChild("HumanoidRootPart") then out[m] = m.HumanoidRootPart end
		end
	end
	return out
end

return Teams
