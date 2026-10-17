--[[ COURTYARD GUARDS — the Courtyard is a garrison, on your screen only (ReplicatedStorage ▸
     WarCrowd, WarFX):
       the walls        sentries in the Crown's colours walk the battlements (every Walk part in
                        the Map: a stretch each, a long walk shared by two), stopping at the end of
                        their stretch to look out over the walls a while
       the east field   two companies of the garrison drill against each other: they charge,
                        crash together, fight it out and pull apart to go again
       the west field   an archery range: a line of archers loosing at straw butts, the arrows
                        thudding in round them
     Only in the hub (Round ▸ Mode "Hub"). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WarCrowd = require(ReplicatedStorage:WaitForChild("WarCrowd"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))

local round = ReplicatedStorage:WaitForChild("Round")
local V3 = Vector3.new

local guards = {on = false, token = 0}

-- a part's extent along the world's x, y and z
local function extent(p)
	local cf, s = p.CFrame, p.Size
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	return V3(math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
		math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
		math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z)
end

local function walksOf(m)
	local list = {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Walk" then table.insert(list, d) end
	end
	return list
end

local function leave()
	if not guards.on then return end
	guards.on = false
	guards.token += 1
	if guards.crowd then guards.crowd:stop(); guards.crowd = nil end
	for _, p in ipairs(guards.props or {}) do p:Destroy() end
	guards.props = {}
end

-- THE FIELDS OUTSIDE: the drill (east) and the archery range (west), past the walls' x
local function fields(crowd, centre, half, token)
	local east, west = centre.X + half + 62, centre.X - half - 62
	crowd:regiment("drillA", {side = "A", kind = "foot", at = V3(east, 0, centre.Z - 30), facing = 1, cols = 10, ranks = 4, spacing = 3, detail = "lite"})
	crowd:regiment("drillB", {side = "A", kind = "pike", at = V3(east, 0, centre.Z + 30), facing = -1, cols = 10, ranks = 4, spacing = 3, detail = "lite"})
	crowd:regiment("range", {side = "A", kind = "archer", at = V3(west, 0, centre.Z + 36), facing = -1, cols = 10, ranks = 1, spacing = 3.2, detail = "lite", banner = false})
	-- the straw butts down the range
	guards.props = {}
	local butts = {}
	for k = -2, 2 do
		local x = west + k * 7
		local g = WarFX.ground(V3(x, centre.Y, centre.Z - 34))
		local b = Instance.new("Part")
		b.Shape = Enum.PartType.Cylinder
		b.Size = V3(1.6, 4.6, 4.6)
		b.Color = Color3.fromRGB(206, 176, 104)
		b.Material = Enum.Material.Fabric
		b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch = true, false, false, false
		b.CFrame = CFrame.new(g + V3(0, 3, 0)) * CFrame.Angles(0, math.rad(90), 0)
		b.Parent = workspace.CurrentCamera
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = V3(1.7, 1.6, 1.6)
		ring.Color = Color3.fromRGB(190, 40, 40)
		ring.Material = Enum.Material.SmoothPlastic
		ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
		ring.CFrame = b.CFrame
		ring.Parent = workspace.CurrentCamera
		table.insert(guards.props, b)
		table.insert(guards.props, ring)
		table.insert(butts, g + V3(0, 3, 0))
	end
	task.spawn(function()
		local nextVolley = os.clock() + 5
		while guards.on and guards.token == token do
			local now = os.clock()
			-- (the drill: the two companies charge, crash, fight and pull apart again)
			crowd:lane("drillA", "drillB", centre.Z, now, 1)
			if now >= nextVolley then
				nextVolley = now + 7 + math.random() * 4
				crowd:loose("range")
				local reg = crowd.regs.range
				task.delay(0.9, function()
					if not (guards.on and guards.token == token and reg) then return end
					local to = butts[math.random(#butts)]
					WarFX.volley(V3(reg.x, (reg.y0 or 0) + 5, reg.z), to, 10, {flight = 1.4, spread = 3, height = 10, range = 200, stickRange = 260})
				end)
			end
			task.wait(0.5)
		end
	end)
end

local function enter(m)
	if guards.on then return end
	guards.on = true
	guards.token += 1
	local token = guards.token
	task.spawn(function()
		local walks, last = {}, -1
		for _ = 1, 20 do
			walks = walksOf(m)
			if #walks > 0 and #walks == last then break end
			last = #walks
			task.wait(0.5)
		end
		if guards.token ~= token or #walks == 0 then return end
		local c = m:GetAttribute("Centre")
		local centre = typeof(c) == "Vector3" and c or V3()
		local crowd = WarCrowd.new()
		guards.crowd = crowd
		local half = 0
		for _, w in ipairs(walks) do half = math.max(half, math.abs(w.Position.X - centre.X)) end
		pcall(fields, crowd, centre, half, token)
		for _, w in ipairs(walks) do
			local e = extent(w)
			local along = e.X >= e.Z and V3(1, 0, 0) or V3(0, 0, 1)
			local len = math.max(e.X, e.Z)
			local top = w.Position + V3(0, e.Y / 2, 0)
			local out = V3(top.X - centre.X, 0, top.Z - centre.Z)
			-- (looking out over the wall: away from the middle, across the walk)
			local across = V3(along.Z, 0, along.X)
			if across:Dot(out) < 0 then across = -across end
			local n = math.max(1, math.floor(len / 100) + 1)
			local seg = (len - 12) / n
			for k = 1, n do
				local a = top + along * (-len / 2 + 6 + (k - 1) * seg)
				local b = a + along * seg
				crowd:sentry({side = "A", kind = (k % 3 == 0) and "archer" or "pike", from = a, to = b, out = across, speed = 3.2 + math.random() * 0.8})
			end
		end
	end)
end

local want = 0
local function refresh()
	want += 1
	local w = want
	task.delay(1, function()
		if want ~= w then return end
		local m = workspace:FindFirstChild("Map")
		local fits = m and round:GetAttribute("Mode") == "Hub"
		if guards.on and (not fits or guards.map ~= m) then leave() end
		if fits and not guards.on then guards.map = m; enter(m) end
	end)
end
round:GetAttributeChangedSignal("Mode"):Connect(refresh)
round:GetAttributeChangedSignal("Map"):Connect(refresh)
workspace.ChildAdded:Connect(function(ch) if ch.Name == "Map" then refresh() end end)
refresh()
