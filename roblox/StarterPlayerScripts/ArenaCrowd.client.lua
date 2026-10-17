--[[ ARENA CROWD — the stands are full, on your screen only (ReplicatedStorage ▸ WarCrowd's
     audience: unarmed commoners in the two sides' colours, one end of the stands blue and the
     other red, a few mixed in). On any map with Stand parts (the Colosseum, the forge arenas, the
     Sandpit), in any mode but the hubs:

       a fall        anyone going down in the arena brings most of the crowd to its feet, arms
                     up, a roar
       a round won   the whole crowd on its feet, a long roar
       between       the murmur of the stands; now and then a few of them shout

     Each Stand part seats a row along its top, facing the middle of the map (its Centre). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WarCrowd = require(ReplicatedStorage:WaitForChild("WarCrowd"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))

local round = ReplicatedStorage:WaitForChild("Round")
local V3 = Vector3.new
local SKIP = {Hub = true, Tavern = true, Tiltyard = true, Training = true, Prologue = true}
local SPACING = 2.5

local arena = {on = false, token = 0}

-- a Stand part's top: where a row of them stands, along its longer side
local function rowOn(p, centre, out)
	local cf, sz = p.CFrame, p.Size
	local axes = {{cf.RightVector, sz.X}, {cf.UpVector, sz.Y}, {cf.LookVector, sz.Z}}
	local up, upI = nil, 1
	for i, a in ipairs(axes) do if not up or math.abs(a[1].Y) > math.abs(up[1].Y) then up, upI = a, i end end
	local h1, h2
	for i, a in ipairs(axes) do if i ~= upI then if not h1 then h1 = a else h2 = a end end end
	local along = h1[2] >= h2[2] and h1 or h2
	local top = p.Position + up[1] * (up[1].Y > 0 and 1 or -1) * up[2] / 2
	local n = math.floor((along[2] - 1) / SPACING)
	for k = 1, n do
		local at = top + along[1] * ((k - (n + 1) / 2) * SPACING)
		local look = V3(centre.X, at.Y, centre.Z)
		if (look - at).Magnitude > 1 then table.insert(out, CFrame.lookAt(at, look)) end
	end
end

local function standsOf(m)
	local list = {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Stand" then table.insert(list, d) end
	end
	return list
end

local function leave()
	if not arena.on then return end
	arena.on = false
	arena.token += 1
	if arena.crowd then arena.crowd:stop(); arena.crowd = nil end
	if arena.murmur then arena.murmur.stop(1); arena.murmur = nil end
	for _, c in ipairs(arena.conns or {}) do c:Disconnect() end
	arena.conns = {}
end

local function roar(secs, share, volume)
	if not arena.crowd then return end
	arena.crowd:roar(secs, share)
	WarFX.sound("Roar", arena.centre + V3(0, 10, 0), {volume = volume or 0.8, near = 80, range = 600, speed = 1.05 + math.random() * 0.1})
end

local function watchDeaths(radius)
	local function hookHum(h)
		if not h then return end
		table.insert(arena.conns, h.Died:Connect(function()
			local r = h.Parent and h.Parent:FindFirstChild("HumanoidRootPart")
			if not (arena.on and r) then return end
			if (V3(r.Position.X, 0, r.Position.Z) - V3(arena.centre.X, 0, arena.centre.Z)).Magnitude < radius + 10 then roar(2.8, 0.8) end
		end))
	end
	local function hookChar(c) if c then hookHum(c:WaitForChild("Humanoid", 5)) end end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then task.spawn(hookChar, p.Character) end
		table.insert(arena.conns, p.CharacterAdded:Connect(hookChar))
	end
	table.insert(arena.conns, Players.PlayerAdded:Connect(function(p) table.insert(arena.conns, p.CharacterAdded:Connect(hookChar)) end))
	local function hookNpcs(npcs)
		for _, m in ipairs(npcs:GetChildren()) do task.spawn(function() hookHum(m:WaitForChild("Humanoid", 5)) end) end
		table.insert(arena.conns, npcs.ChildAdded:Connect(function(m) hookHum(m:WaitForChild("Humanoid", 5)) end))
	end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then hookNpcs(npcs) end
	table.insert(arena.conns, workspace.ChildAdded:Connect(function(c) if c.Name == "NPCs" then hookNpcs(c) end end))
end

local function enter(m)
	if arena.on then return end
	arena.on = true
	arena.token += 1
	arena.conns = {}
	local token = arena.token
	task.spawn(function()
		-- (the stands stream in with the map: wait until their count settles)
		local stands, last = {}, -1
		for _ = 1, 20 do
			stands = standsOf(m)
			if #stands > 0 and #stands == last then break end
			last = #stands
			task.wait(0.5)
		end
		if arena.token ~= token or #stands == 0 then return end
		local c = m:GetAttribute("Centre")
		local centre = typeof(c) == "Vector3" and c or V3(0, 0, 0)
		arena.centre = centre
		local spots = {}
		for _, p in ipairs(stands) do rowOn(p, centre, spots) end
		-- (not more than a screen can carry: a phone seats fewer)
		local cap = Device.kind() == "phone" and 180 or 420
		while #spots > cap do table.remove(spots, math.random(#spots)) end
		-- one end of the stands for each side, a few strays mixed in
		local blue, red = {}, {}
		for _, cf in ipairs(spots) do
			local north = cf.Position.Z < centre.Z
			if math.random() < 0.2 then north = not north end
			table.insert(north and blue or red, cf)
		end
		WarCrowd.SCALE = 1
		local crowd = WarCrowd.new()
		arena.crowd = crowd
		crowd:audience("blue", {side = "A", kind = "pike", spots = blue, detail = "mass"})
		crowd:audience("red", {side = "B", kind = "pike", spots = red, detail = "mass"})
		arena.murmur = WarFX.loop3D("Roar", centre + V3(0, 10, 0), {volume = 0.16, near = 70, range = 320})
		watchDeaths(m:GetAttribute("Radius") or 60)
		roar(3, 0.6, 0.6)   -- (they're glad you came)
		while arena.on and arena.token == token do
			task.wait(8 + math.random() * 9)
			if arena.on and arena.token == token and round:GetAttribute("State") == "Round" then
				arena.crowd:roar(1.6, 0.25)
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
		local fits = m and not SKIP[round:GetAttribute("Mode") or ""] and not m:GetAttribute("Warfield") and not m:GetAttribute("Generated")
		if arena.on and (not fits or arena.map ~= m) then leave() end
		if fits and not arena.on then arena.map = m; enter(m) end
	end)
end
round:GetAttributeChangedSignal("Mode"):Connect(refresh)
round:GetAttributeChangedSignal("Map"):Connect(refresh)
round:GetAttributeChangedSignal("State"):Connect(function()
	if arena.on and round:GetAttribute("State") == "Intermission" then roar(5, 0.95, 1) end
end)
workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then refresh() end end)
refresh()
