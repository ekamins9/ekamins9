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
     of steps would otherwise keep pattering on after you stop. ]]

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

function Footsteps.play(part, material, o)
	if not part then return nil end
	o = o or {}
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
