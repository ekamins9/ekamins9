--[[ SCUFFS — a fight shows on you: every clean blow leaves its mark where it landed, on your
     screen only (Combat ▸ CombatServer fires ScuffEvent with the part struck, where and which way):
     a bright scratch across plate and mail, a dark scuff on cloth, leather and skin, laid along the
     blade's path. A dozen to a fighter at most (the oldest go first); gone with the body. A
     blade that hits the world leaves its nick there too: a pale chip in stone, a dark gash in
     wood, a bright scratch on metal, fading after a minute and a half.

     Only within 70 studs of your camera. Nothing here is sent to the server. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Device = require(ReplicatedStorage:WaitForChild("Device"))
-- (a phone keeps fewer, nearer: a War brawl would otherwise lay hundreds)
local PHONE = Device.kind() == "phone"
local NEAR, MAX_EACH = PHONE and 40 or 70, PHONE and 4 or 12
local METAL = {[Enum.Material.Metal] = true, [Enum.Material.DiamondPlate] = true, [Enum.Material.CorrodedMetal] = true, [Enum.Material.Foil] = true}

local marks = setmetatable({}, {__mode = "k"})   -- [character model] = {scuff parts}

-- the fighter it's on (an armour piece sits in a model of its own inside the body)
local function modelOf(part)
	local m = part:FindFirstAncestorOfClass("Model")
	while m and not m:FindFirstChildOfClass("Humanoid") do m = m:FindFirstAncestorOfClass("Model") end
	return m
end

-- how far a point is outside a part's box (0 inside it)
local function outside(p, pos)
	local lp = p.CFrame:PointToObjectSpace(pos)
	local h = p.Size / 2
	return Vector3.new(math.max(math.abs(lp.X) - h.X, 0), math.max(math.abs(lp.Y) - h.Y, 0), math.max(math.abs(lp.Z) - h.Z, 0)).Magnitude
end
-- what the blade really met: the visible piece of that fighter nearest the blow (the limb the
-- server struck is under the armour, often hidden)
local LIMB = {Head = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true}
local function surfaceOf(part, hitPos)
	local m = modelOf(part)
	if not m then return part end
	local best, bd = nil, 1.2
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Scuff" and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.5 and d.LocalTransparencyModifier < 0.5
			and not d:FindFirstAncestorOfClass("Tool") and d.Size.Magnitude > 0.5 then
			local o = outside(d, hitPos) + (LIMB[d.Name] and 0.25 or 0)   -- (armour over the limb first)
			if o < bd then best, bd = d, o end
		end
	end
	return best
end

local STONE = {[Enum.Material.Slate] = true, [Enum.Material.Cobblestone] = true, [Enum.Material.Brick] = true, [Enum.Material.Granite] = true,
	[Enum.Material.Marble] = true, [Enum.Material.Concrete] = true, [Enum.Material.Rock] = true, [Enum.Material.Basalt] = true, [Enum.Material.Limestone] = true,
	[Enum.Material.Sandstone] = true, [Enum.Material.Pavement] = true, [Enum.Material.Plaster] = true}
local function scuff(part, hitPos, dir, world)
	if not (part and part:IsA("BasePart") and part.Parent) then return end
	local cam = workspace.CurrentCamera
	if not cam or (cam.CFrame.Position - hitPos).Magnitude > NEAR then return end
	if not world then part = surfaceOf(part, hitPos) end
	if not part or part.Transparency > 0.5 or part.Size.Magnitude < 0.5 then return end
	-- the nearest point on its surface to where the blade met it, and which face that's on
	local cf, half = part.CFrame, part.Size / 2
	local lp = cf:PointToObjectSpace(hitPos)
	lp = Vector3.new(math.clamp(lp.X, -half.X, half.X), math.clamp(lp.Y, -half.Y, half.Y), math.clamp(lp.Z, -half.Z, half.Z))
	local gaps = {half.X - math.abs(lp.X), half.Y - math.abs(lp.Y), half.Z - math.abs(lp.Z)}
	local axis = 1
	if gaps[2] < gaps[axis] then axis = 2 end
	if gaps[3] < gaps[axis] then axis = 3 end
	local normal
	if axis == 1 then lp = Vector3.new(lp.X >= 0 and half.X or -half.X, lp.Y, lp.Z); normal = Vector3.new(lp.X >= 0 and 1 or -1, 0, 0)
	elseif axis == 2 then lp = Vector3.new(lp.X, lp.Y >= 0 and half.Y or -half.Y, lp.Z); normal = Vector3.new(0, lp.Y >= 0 and 1 or -1, 0)
	else lp = Vector3.new(lp.X, lp.Y, lp.Z >= 0 and half.Z or -half.Z); normal = Vector3.new(0, 0, lp.Z >= 0 and 1 or -1) end
	-- laid along the blade's path, flat on that face
	local ld = cf:VectorToObjectSpace(dir)
	ld = ld - normal * ld:Dot(normal)
	if ld.Magnitude < 0.05 then ld = normal:Cross(Vector3.new(0.3, 1, 0.2)) end
	ld = ld.Unit
	local len = math.min(0.4 + math.random() * 0.5, math.max(half.X, half.Y, half.Z) * 1.6)
	local metal = METAL[part.Material]
	local stone = world and STONE[part.Material]
	if world then len = 0.45 + math.random() * 0.6 end
	local s = Instance.new("Part")
	s.Name = "Scuff"
	s.Size = Vector3.new(0.04, metal and 0.05 or (world and 0.1 or 0.08), len)
	-- (fresh stone shows pale where it's chipped; wood and cloth darken; metal shines)
	s.Color = (metal and part.Color:Lerp(Color3.new(1, 1, 1), 0.45)) or (stone and part.Color:Lerp(Color3.new(1, 1, 1), 0.35)) or part.Color:Lerp(Color3.new(0, 0, 0), 0.55)
	s.Material = metal and Enum.Material.Metal or Enum.Material.SmoothPlastic
	s.Transparency = world and 0.4 or 0.25
	s.CanCollide, s.CanQuery, s.CanTouch, s.CastShadow, s.Massless, s.Anchored = false, false, false, false, true, false
	local rel = CFrame.fromMatrix(lp + normal * 0.02, normal, ld:Cross(normal), ld)
	s.CFrame = cf * rel
	local w = Instance.new("Weld")
	w.Part0, w.Part1, w.C0 = part, s, rel
	w.Parent = s
	s.Parent = part
	-- (a chip in the world has its groove: a thin dark line down its middle)
	if world and not metal then
		local g = Instance.new("Part")
		g.Name = "ScuffGroove"
		g.Size = Vector3.new(0.045, 0.03, len * 0.85)
		g.Color = part.Color:Lerp(Color3.new(0, 0, 0), 0.6)
		g.Material = Enum.Material.SmoothPlastic
		g.Transparency = 0.2
		g.CanCollide, g.CanQuery, g.CanTouch, g.CastShadow, g.Massless, g.Anchored = false, false, false, false, true, false
		local grel = rel * CFrame.new(0.005, 0, 0)
		g.CFrame = cf * grel
		local gw = Instance.new("Weld")
		gw.Part0, gw.Part1, gw.C0 = part, g, grel
		gw.Parent = g
		g.Parent = s
	end
	-- (a dozen to a fighter)
	local m = modelOf(part) or part
	local list = marks[m] or {}
	marks[m] = list
	table.insert(list, s)
	while #list > MAX_EACH do
		local old = table.remove(list, 1)
		if old then old:Destroy() end
	end
	if world then
		task.delay(90, function()
			if not s.Parent then return end
			for _, q in ipairs({s, s:FindFirstChild("ScuffGroove")}) do game:GetService("TweenService"):Create(q, TweenInfo.new(3), {Transparency = 1}):Play() end
			task.delay(3.1, function() s:Destroy() end)
		end)
	end
end

-- a blade into the world: the surface it met, found from where the swing came
local wallRay = RaycastParams.new()
wallRay.FilterType = Enum.RaycastFilterType.Exclude
local function wallScuff(hitPos, dir, from)
	local cam = workspace.CurrentCamera
	if not cam or (cam.CFrame.Position - hitPos).Magnitude > NEAR then return end
	local skip = {cam}
	for _, n in ipairs({"NPCs", "DroppedWeapons", "Remains"}) do local f = workspace:FindFirstChild(n); if f then table.insert(skip, f) end end
	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do if p.Character then table.insert(skip, p.Character) end end
	wallRay.FilterDescendantsInstances = skip
	local start = from + Vector3.new(0, 1.2, 0)
	local hit = workspace:Raycast(start, (hitPos - start).Unit * ((hitPos - start).Magnitude + 2), wallRay)
	if not (hit and hit.Instance and hit.Instance:IsA("BasePart")) or hit.Instance:IsA("Terrain") then return end
	scuff(hit.Instance, hit.Position, dir, true)
end

local ev = ReplicatedStorage:WaitForChild("ScuffEvent", 30)
if ev then
	ev.OnClientEvent:Connect(function(part, hitPos, dir, from)
		if typeof(hitPos) ~= "Vector3" or typeof(dir) ~= "Vector3" then return end
		if part == nil and typeof(from) == "Vector3" then pcall(wallScuff, hitPos, dir, from); return end
		pcall(scuff, part, hitPos, dir)
	end)
end
