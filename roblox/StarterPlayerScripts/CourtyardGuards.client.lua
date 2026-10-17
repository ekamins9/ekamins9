--[[ COURTYARD GUARDS — the Courtyard is a garrison: on your screen only, sentries in the Crown's
     colours walk the battlements (every Walk part in the Map: a stretch each, a long walk shared
     by two), stopping at the end of their stretch to look out over the walls a while
     (ReplicatedStorage ▸ WarCrowd:sentry). Only in the hub (Round ▸ Mode "Hub"). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WarCrowd = require(ReplicatedStorage:WaitForChild("WarCrowd"))

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
