--[[ BREAKABLES — a map's crates and barrels give way to a blade (any map built with MapKit's
     crate / barrel: the war camps, the Courtyard, the dungeons' storerooms). A blow that hits
     the world (Combat ▸ CombatServer.worldHitHooks) on a Crate or a Barrel bursts it: planks or
     staves flung out and tumbling, a crunch of wood, a puff of dust; a crate stacked on it comes
     down with it. Its bands and hoops go with it. Ninety seconds later it's back where it was.

     Not the dungeon raid's searchable containers (workspace ▸ LootDrops): only the map's own.

       Breakables.init()   (once: GameServer) ]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local CombatServer = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatServer"))
local Sounds = require(ReplicatedStorage:WaitForChild("Sounds"))

local Breakables = {}
local BACK_AFTER = 90
local KINDS = {Crate = "Band", Barrel = "Hoop"}
local inited = false

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

local function mapModel() return workspace:FindFirstChild("Map") end

-- its bands / hoops: the trim pieces of its kind that sit inside its bounds
local function trimOf(part)
	local trim = {}
	local name = KINDS[part.Name]
	local box = part.Size + Vector3.new(0.6, 0.6, 0.6)
	for _, p in ipairs(workspace:GetPartBoundsInBox(part.CFrame, box, overlap)) do
		if p.Name == name and p ~= part then table.insert(trim, p) end
	end
	return trim
end

local burst
-- what sits on it: crates whose middle is right above it
local function stackedOn(part)
	local out = {}
	local top = part.Position + Vector3.new(0, part.Size.Y / 2, 0)
	for _, p in ipairs(workspace:GetPartBoundsInBox(CFrame.new(top + Vector3.new(0, 2, 0)), Vector3.new(part.Size.X, 4, part.Size.Z), overlap)) do
		if p ~= part and KINDS[p.Name] and p.Position.Y > part.Position.Y + 0.5 then table.insert(out, p) end
	end
	return out
end

burst = function(part)
	if not part.Parent or part:GetAttribute("Broken") then return end
	part:SetAttribute("Broken", true)
	local map = mapModel()
	local parent = part.Parent
	-- (kept to put back)
	local keep = {part:Clone()}
	local trim = trimOf(part)
	for _, t in ipairs(trim) do table.insert(keep, t:Clone()) end
	local above = stackedOn(part)
	local cf, size, color, mat = part.CFrame, part.Size, part.Color, part.Material
	local pos = part.Position
	-- the crunch, the dust
	local snd = Instance.new("Part")
	snd.Anchored, snd.CanCollide, snd.CanQuery, snd.CanTouch, snd.Transparency = true, false, false, false, 1
	snd.Size = Vector3.new(1, 1, 1)
	snd.CFrame = CFrame.new(pos)
	snd.Parent = workspace
	Sounds.bank("WallWoodChip", snd)
	Sounds.bank("WallWood", snd, {Volume = 0.8})
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(150, 128, 100))
	e.Size = NumberSequence.new(1, 3)
	e.Transparency = NumberSequence.new(0.4, 1)
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(3, 7)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = snd
	e:Emit(14)
	Debris:AddItem(snd, 3)
	-- the pieces: planks for a crate, staves for a barrel
	local folder = Instance.new("Folder")
	folder.Name = "Splinters"
	folder.Parent = workspace
	local n = part.Name == "Barrel" and 8 or 7
	for i = 1, n do
		local p = Instance.new("Part")
		if part.Name == "Barrel" then
			p.Size = Vector3.new(0.3, size.X * 0.9, 0.7)
		else
			p.Size = Vector3.new(size.X * (0.5 + math.random() * 0.45), 0.25, 0.7)
		end
		p.Color, p.Material = color, mat
		p.CanQuery, p.CanTouch = false, false
		p.CFrame = cf * CFrame.new((math.random() - 0.5) * size.X * 0.6, (math.random() - 0.5) * size.Y * 0.6, (math.random() - 0.5) * size.Z * 0.6) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.Parent = folder
		local out = (p.Position - pos)
		out = out.Magnitude > 0.1 and out.Unit or Vector3.new(0, 1, 0)
		p.AssemblyLinearVelocity = out * (10 + math.random() * 10) + Vector3.new(0, 10 + math.random() * 8, 0)
		p.AssemblyAngularVelocity = Vector3.new(math.random() * 12, math.random() * 12, math.random() * 12)
	end
	task.delay(2.5, function()
		for _, p in ipairs(folder:GetChildren()) do p.CanCollide = false end
	end)
	Debris:AddItem(folder, 8)
	for _, t in ipairs(trim) do t:Destroy() end
	part:Destroy()
	-- what was stacked on it comes down
	for _, a in ipairs(above) do task.delay(0.15, burst, a) end
	-- and back, a while later (if the same map is still here)
	task.delay(BACK_AFTER, function()
		if mapModel() ~= map or not parent.Parent then return end
		for _, k in ipairs(keep) do k:SetAttribute("Broken", nil); k.Parent = parent end
	end)
end

local function onHit(character, pos)
	local map = mapModel()
	if not map then return end
	overlap.FilterDescendantsInstances = {map}
	for _, p in ipairs(workspace:GetPartBoundsInRadius(pos, 1.6, overlap)) do
		if KINDS[p.Name] then burst(p); return end
	end
end

function Breakables.init()
	if inited then return end
	inited = true
	table.insert(CombatServer.worldHitHooks, function(character, pos)
		local ok, err = pcall(onHit, character, pos)
		if not ok then warn("[Breakables]", err) end
	end)
end

return Breakables
