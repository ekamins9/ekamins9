--[[ FOOTSTEPS — one sound per step, picked by what's underfoot. Your own steps
     are timed by CameraRig (on the step bob); everyone else's (other players,
     bots) by StarterPlayerScripts ▸ Footsteps. Both play through here.

       Footsteps.idFor(material)          -> sound id
       Footsteps.play(part, material, o)  one step at `part` (o.Volume, o.Speed, o.MaxDistance)
       Footsteps.under(root, ignore)      -> the material under a body (raycast), or nil in the air

     SOUNDS is one sound per material; LIKE sends every other material to the
     closest one (Slate and Cobblestone sound like Rock…). A FootstepSounds
     folder in SoundService (one Sound per material name, plus "Default")
     still wins over both, so sounds can be swapped in Studio without code.
     Each step is cut after MAX_LENGTH seconds: a clip that holds a whole run
     of steps would otherwise keep pattering on after you stop.

     WATER: a step onto a puddle, standing water or a marsh pool (thin sheets on the floor that
     nothing queries: the dungeons' Puddle and StandingWater, a marsh's Marshwater) splashes
     instead (ReplicatedStorage ▸ WarAudio ▸ Splash, if the place has it), with a ripple spreading
     on the water. ]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Sounds = require(ReplicatedStorage:WaitForChild("Sounds"))

local Footsteps = {}

Footsteps.SOUNDS = {
	Grass        = "rbxassetid://507863105",
	Metal        = "rbxassetid://2812417769",
	DiamondPlate = "rbxassetid://2812417769",
	Pebble       = "rbxassetid://131436155",
	Wood         = "rbxassetid://4085869581",
	WoodPlanks   = "rbxassetid://4085869581",
	Plastic      = "rbxassetid://4453297814",
	SmoothPlastic = "rbxassetid://4453297814",
	Sand         = "rbxassetid://265653329",
	Rock         = "rbxassetid://379398649",
}
-- every other material: the closest sound above
Footsteps.LIKE = {
	Slate = "Rock", Cobblestone = "Rock", Brick = "Rock", Concrete = "Rock", Granite = "Rock", Marble = "Rock",
	Basalt = "Rock", Pavement = "Rock", Limestone = "Rock", Sandstone = "Rock", Asphalt = "Rock", CrackedLava = "Rock",
	Glacier = "Rock", Ice = "Rock", Glass = "Rock", Salt = "Sand", Snow = "Sand",
	Ground = "Grass", Mud = "Grass", LeafyGrass = "Grass", Fabric = "Grass",
	CorrodedMetal = "Metal", Foil = "Metal",
	Neon = "Plastic", ForceField = "Plastic", Cardboard = "WoodPlanks", Carpet = "Grass", Rubber = "Plastic",
}
Footsteps.DEFAULT = "Plastic"
-- per material: a pitch and a loudness on top of the sound (snow is a soft, low crunch)
Footsteps.PITCH = {Snow = 0.8, Mud = 0.85, Ground = 0.92, Metal = 1.0}
Footsteps.VOLUME = {Snow = 0.8, Metal = 0.7, DiamondPlate = 0.7}
Footsteps.MAX_LENGTH = 0.45

local function folder()
	return SoundService:FindFirstChild("FootstepSounds") or ReplicatedStorage:FindFirstChild("FootstepSounds")
end

-- -> id, volume, pitch
function Footsteps.idFor(material)
	local name = material and material.Name or "Plastic"
	local f = folder()
	if f then
		local s = f:FindFirstChild(name) or f:FindFirstChild("Default")
		if s and s:IsA("Sound") then return s.SoundId, s.Volume, s.PlaybackSpeed end
	end
	local key = Footsteps.SOUNDS[name] and name or Footsteps.LIKE[name] or Footsteps.DEFAULT
	return Footsteps.SOUNDS[key] or Footsteps.SOUNDS[Footsteps.DEFAULT], Footsteps.VOLUME[name] or 1, Footsteps.PITCH[name] or 1
end

-- WATER underfoot
local WET = {Puddle = true, StandingWater = true, Marshwater = true}
local wet, wetMap, wetAt = {}, nil, 0
local function refreshWet()
	local m = workspace:FindFirstChild("Map")
	if m == wetMap and os.clock() - wetAt < 10 then return end
	wetMap, wetAt, wet = m, os.clock(), {}
	if not m then return end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and WET[d.Name] then table.insert(wet, d) end
	end
end
local function waterAt(pos)
	refreshWet()
	for _, p in ipairs(wet) do
		if p.Parent then
			local rel = p.CFrame:PointToObjectSpace(pos)
			local s = p.Size
			if p.Shape == Enum.PartType.Cylinder then
				-- (a puddle: a cylinder lying flat, its X the thin axis, an ellipse across Y and Z)
				local a, b = s.Y / 2, s.Z / 2
				if math.abs(rel.X) < 4.5 and (rel.Y * rel.Y) / (a * a) + (rel.Z * rel.Z) / (b * b) <= 1 then return p end
			elseif math.abs(rel.X) < s.X / 2 and math.abs(rel.Z) < s.Z / 2 and math.abs(rel.Y) < 4.5 then
				return p
			end
		end
	end
	return nil
end
local function ripple(water, pos)
	local up = water.Shape == Enum.PartType.Cylinder and water.CFrame.RightVector or water.CFrame.UpVector
	local top = water.Position + up * ((water.Shape == Enum.PartType.Cylinder and water.Size.X or water.Size.Y) / 2 + 0.02)
	local at = Vector3.new(pos.X, top.Y, pos.Z)
	local r = Instance.new("Part")
	r.Anchored, r.CanCollide, r.CanQuery, r.CanTouch, r.CastShadow = true, false, false, false, false
	r.Shape = Enum.PartType.Cylinder
	r.Material = Enum.Material.SmoothPlastic
	r.Color = Color3.fromRGB(190, 210, 214)
	r.Transparency = 0.45
	r.Size = Vector3.new(0.03, 0.6, 0.6)
	r.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	r.Parent = workspace.Terrain
	TweenService:Create(r, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.03, 3.4, 3.4), Transparency = 1}):Play()
	game:GetService("Debris"):AddItem(r, 0.8)
end

function Footsteps.play(part, material, o)
	if not part then return nil end
	o = o or {}
	-- (into water: a splash, a ripple)
	local water = game:GetService("RunService"):IsClient() and waterAt(part.Position)
	if water then
		local wa = ReplicatedStorage:FindFirstChild("WarAudio")
		local sp = wa and wa:FindFirstChild("Splash")
		ripple(water, part.Position)
		if sp and sp:IsA("Sound") then
			return Sounds.play(sp.SoundId, part, {Volume = (o.Volume or 0.5) * 1.3, Speed = (o.Speed or 1) * (0.92 + math.random() * 0.16), MaxDistance = o.MaxDistance or 60, Ttl = 1.5})
		end
	end
	local id, vol, pitch = Footsteps.idFor(material)
	local s = Sounds.play(id, part, {
		Volume = (o.Volume or 0.5) * (vol or 1),
		Speed = (o.Speed or 1) * (pitch or 1),
		MaxDistance = o.MaxDistance or 60,
		Ttl = Footsteps.MAX_LENGTH + 0.6,
	})
	if s then
		task.delay(Footsteps.MAX_LENGTH, function()
			if s.Parent then TweenService:Create(s, TweenInfo.new(0.08), {Volume = 0}):Play() end
		end)
	end
	return s
end

local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude
ray.IgnoreWater = true
function Footsteps.under(root, ignore)
	ray.FilterDescendantsInstances = {ignore or root}
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -4.2, 0), ray)
	return hit and hit.Material or nil
end

return Footsteps
