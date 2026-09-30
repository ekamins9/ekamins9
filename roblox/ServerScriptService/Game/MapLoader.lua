--[[ MAP LOADER — swaps the playable map in and out of workspace.

     A map is a Model in ServerStorage.Maps/<Name> containing:
       Spawns/        any BaseParts; attribute Team = "A" | "B" on team spawns,
                      no attribute = anyone (FFA / Hub). Invisible, CanCollide off
                      is fine — only their CFrame is used.
       MenuCamera     (optional Part) where the menu's cinematic camera sits;
                      it looks along the part's LookVector.
       MenuCameras/   (optional Folder of Parts) several shots — the camera
                      glides from one to the next in name order (Shot1, Shot2…).
       Zones/Hill     (optional Part) King of the Hill capture volume.
       anything else  the geometry.
     Everything that is not the current map stays untouched (your baseplate,
     lighting, dummies folder…). No Maps folder / unknown name → the map is
     simply not loaded and spawns fall back to workspace SpawnLocations. ]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local MapLoader = {}
MapLoader.current = nil      -- the loaded Model in workspace
MapLoader.name = nil

local function log(...) DebugFlags.log("Map", ...) end

function MapLoader.available()
	local out = {}
	local f = ServerStorage:FindFirstChild("Maps")
	if f then
		for _, m in ipairs(f:GetChildren()) do table.insert(out, m.Name) end
	end
	table.sort(out)
	return out
end

function MapLoader.exists(name)
	local f = ServerStorage:FindFirstChild("Maps")
	return f ~= nil and f:FindFirstChild(name) ~= nil
end

function MapLoader.unload()
	if MapLoader.current then MapLoader.current:Destroy() end
	MapLoader.current, MapLoader.name = nil, nil
end

function MapLoader.load(name)
	if MapLoader.name == name and MapLoader.current and MapLoader.current.Parent then return true end
	MapLoader.unload()
	local f = ServerStorage:FindFirstChild("Maps")
	local template = f and f:FindFirstChild(name)
	if not template then
		warn("[Map] no map named", tostring(name), "in ServerStorage.Maps — playing on whatever is in workspace")
		MapLoader.name = name
		return false
	end
	local m = template:Clone()
	m.Name = "Map"
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and (d:IsDescendantOf(m:FindFirstChild("Spawns") or m) and d.Parent and d.Parent.Name == "Spawns") then
			d.Transparency, d.CanCollide, d.CanQuery, d.CanTouch = 1, false, false, false
			d.Anchored = true
		end
	end
	local zones = m:FindFirstChild("Zones")
	if zones then
		for _, z in ipairs(zones:GetDescendants()) do
			if z:IsA("BasePart") then z.CanCollide, z.CanQuery, z.CanTouch, z.Anchored = false, false, false, true end
		end
	end
	local cam = m:FindFirstChild("MenuCamera")
	if cam and cam:IsA("BasePart") then cam.Transparency, cam.CanCollide, cam.CanQuery, cam.Anchored = 1, false, false, true end
	local cams = m:FindFirstChild("MenuCameras")
	if cams then
		for _, c in ipairs(cams:GetDescendants()) do
			if c:IsA("BasePart") then c.Transparency, c.CanCollide, c.CanQuery, c.CanTouch, c.Anchored = 1, false, false, false, true end
		end
	end
	m.Parent = workspace
	MapLoader.current, MapLoader.name = m, name
	log("loaded", name)
	return true
end

-- CFrames of the spawns for a team ("A" / "B") or, with nil, the unteamed ones;
-- falls back to any spawn, then workspace SpawnLocations, then the origin
function MapLoader.spawns(team)
	local out, any = {}, {}
	local m = MapLoader.current
	local folder = m and m:FindFirstChild("Spawns")
	if folder then
		for _, p in ipairs(folder:GetDescendants()) do
			if p:IsA("BasePart") then
				local t = p:GetAttribute("Team")
				table.insert(any, p.CFrame)
				if (team == nil and t == nil) or (team ~= nil and t == team) then table.insert(out, p.CFrame) end
			end
		end
	end
	if #out > 0 then return out end
	if #any > 0 then return any end
	for _, s in ipairs(workspace:GetDescendants()) do
		if s:IsA("SpawnLocation") then table.insert(out, s.CFrame + Vector3.new(0, 3, 0)) end
	end
	if #out == 0 then out[1] = CFrame.new(0, 8, 0) end
	return out
end

-- the spawn farthest from any enemy (or any other player), so nobody drops
-- into a fight or onto a teammate
function MapLoader.pickSpawn(team, others)
	local list = MapLoader.spawns(team)
	local best, bestD = list[1], -1
	for _, cf in ipairs(list) do
		local d = math.huge
		for _, pos in ipairs(others or {}) do d = math.min(d, (cf.Position - pos).Magnitude) end
		if d == math.huge then d = 1e6 + math.random() end
		d = d + math.random() * 2   -- break ties randomly
		if d > bestD then best, bestD = cf, d end
	end
	return best
end

function MapLoader.menuCamera()
	local m = MapLoader.current
	local c = m and m:FindFirstChild("MenuCamera")
	return c and c:IsA("BasePart") and c or nil
end

function MapLoader.zone(name)
	local m = MapLoader.current
	local z = m and m:FindFirstChild("Zones")
	z = z and z:FindFirstChild(name)
	return z and z:IsA("BasePart") and z or nil
end

return MapLoader
