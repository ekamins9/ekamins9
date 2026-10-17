--[[ HORDE HOST — the rest of the horde, on your screen only: out past each of the map's gates
     (Map ▸ Spots ▸ HordeGate<n>) and past the map's edge, a block of its soldiers stands facing
     the camp (at night with torches held high) (ReplicatedStorage ▸ WarCrowd's audience: real armour, the attackers'
     colours, weapons in hand). When a wave comes (Round ▸ ObjState → "wave") they roar and
     raise their weapons, horns sound and the war drums beat; between waves they wait. The more
     waves you've beaten, the more of them there are. Only in the Horde. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WarCrowd = require(ReplicatedStorage:WaitForChild("WarCrowd"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))

local round = ReplicatedStorage:WaitForChild("Round")
local V3 = Vector3.new

local host = {on = false, token = 0}
local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude

local function groundAt(p)
	local r = workspace:Raycast(V3(p.X, p.Y + 120, p.Z), V3(0, -260, 0), ray)
	return r and r.Position or p
end

-- where the gates are: a direction out from the middle and the gate itself (or three, evenly,
-- out at the edge, if there are none)
local function gates(m, centre, R)
	local list = {}
	local spots = m:FindFirstChild("Spots")
	for i = 1, 8 do
		local g = spots and spots:FindFirstChild("HordeGate" .. i)
		if g and g:IsA("BasePart") then
			local d = V3(g.Position.X - centre.X, 0, g.Position.Z - centre.Z)
			if d.Magnitude > 4 then
				d = d.Unit
				-- (one block a direction: gates side by side share it)
				local near = false
				for _, o in ipairs(list) do if o.dir:Dot(d) > 0.85 then near = true end end
				if not near then table.insert(list, {dir = d, at = g.Position}) end
			end
		end
	end
	if #list == 0 then
		for k = 0, 2 do
			local a = k * 2.094 + 0.5
			local d = V3(math.cos(a), 0, math.sin(a))
			table.insert(list, {dir = d, at = centre + d * R * 0.85})
		end
	end
	return list
end

-- a block of men out past the gate and past the map's edge (never where anyone can walk up to
-- them and take them for the wave), `rows` deep, facing the camp
local function block(gate, centre, R, rows, cols)
	local spots = {}
	local dir = gate.dir
	local right = V3(-dir.Z, 0, dir.X)
	local out = (V3(gate.at.X, 0, gate.at.Z) - V3(centre.X, 0, centre.Z)).Magnitude
	local front = V3(centre.X, centre.Y, centre.Z) + dir * math.max(out + 20, R + 8)
	for r = 0, rows - 1 do
		for c = 1, cols do
			local off = (c - (cols + 1) / 2) * 3 + (math.random() - 0.5) * 0.8
			local p = groundAt(front + right * off + dir * (r * 3 + (math.random() - 0.5) * 0.8))
			table.insert(spots, CFrame.lookAt(p, V3(centre.X, p.Y, centre.Z)))
		end
	end
	return spots
end

local function leave()
	if not host.on then return end
	host.on = false
	host.token += 1
	if host.crowd then host.crowd:stop(); host.crowd = nil end
	for _, t in ipairs(host.torches or {}) do t:Destroy() end
	host.torches = {}
	if host.drums then WarFX.stopLoop(host.drums, 1.5); host.drums = nil end
end

local function build(level)
	local m = workspace:FindFirstChild("Map")
	local c, R = m and m:GetAttribute("Centre"), m and m:GetAttribute("Radius")
	if typeof(c) ~= "Vector3" or type(R) ~= "number" then return end
	if host.crowd then host.crowd:stop() end
	ray.FilterDescendantsInstances = {workspace.CurrentCamera, workspace:FindFirstChild("NPCs")}
	local small = Device.kind() == "phone"
	WarCrowd.SCALE = 1
	local crowd = WarCrowd.new()
	host.crowd = crowd
	host.centre = c
	-- (deeper with every few waves beaten)
	local rows = math.clamp(2 + math.floor(level / 3), 2, small and 3 or 5)
	local night = game:GetService("Lighting").ClockTime < 6.5 or game:GetService("Lighting").ClockTime > 18.5
	host.torches = host.torches or {}
	for _, t in ipairs(host.torches) do t:Destroy() end
	host.torches = {}
	for i, gate in ipairs(gates(m, c, R)) do
		local spots = block(gate, c, R, rows, small and 6 or 9)
		crowd:audience("gate" .. i, {side = "B", kind = i % 2 == 0 and "pike" or "foot", spots = spots, detail = "mass", unarmed = false})
		-- (at night a few of them hold torches up: you see them coming out of the dark)
		if night then
			for k = 2, #spots, 5 do
				local fire = Instance.new("Part")
				fire.Shape = Enum.PartType.Ball
				fire.Size = V3(0.7, 0.7, 0.7)
				fire.Material = Enum.Material.Neon
				fire.Color = Color3.fromRGB(255, 150, 60)
				fire.Anchored, fire.CanCollide, fire.CanQuery, fire.CanTouch, fire.CastShadow = true, false, false, false, false
				fire.CFrame = spots[k] * CFrame.new(1.4, 7.2, 0)
				local l = Instance.new("PointLight")
				l.Name = "Flicker"
				l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 150, 70), 14, 1.4
				l.Parent = fire
				fire.Parent = workspace.CurrentCamera
				table.insert(host.torches, fire)
			end
		end
	end
	host.level = level
end

local function waveComes()
	if not host.crowd then return end
	host.crowd:roar(4, 0.9)
	local c = host.centre or V3()
	WarFX.sound("Horn", nil, {volume = 0.8, speed = 0.9})
	WarFX.sound("Roar", c + V3(0, 10, 0), {volume = 1, near = 120, range = 1200})
	if not host.drums then host.drums = WarFX.loop("Drums", 0.4) end
end
local function breather()
	if host.drums then WarFX.stopLoop(host.drums, 3); host.drums = nil end
	-- (more of them waiting for the next one)
	local wave = tonumber(string.match(round:GetAttribute("ObjLabel") or "", "%d+")) or 0
	if host.crowd and math.floor(wave / 3) ~= math.floor((host.level or 0) / 3) then pcall(build, wave) end
end

local function enter()
	if host.on then return end
	host.on = true
	host.token += 1
	local token = host.token
	task.spawn(function()
		-- (the map and its rise stream in first)
		for _ = 1, 40 do
			local m = workspace:FindFirstChild("Map")
			if m and m:GetAttribute("Centre") then break end
			task.wait(0.5)
		end
		task.wait(1.5)
		if host.token ~= token then return end
		pcall(build, 0)
	end)
end

local lastState
round:GetAttributeChangedSignal("ObjState"):Connect(function()
	if not host.on then return end
	local st = round:GetAttribute("ObjState")
	if st == lastState then return end
	lastState = st
	if st == "wave" then waveComes() elseif st == "break" then breather() end
end)
local function refresh()
	if round:GetAttribute("Mode") == "Horde" then enter() else leave() end
end
round:GetAttributeChangedSignal("Mode"):Connect(refresh)
round:GetAttributeChangedSignal("Map"):Connect(function() leave(); task.wait(0.5); refresh() end)
refresh()
