--[[ CINEMATIC GRADE — a film look over the open-air maps, on your screen only: more contrast,
     the colour pulled back from Roblox's bright toy greens and blues towards a painted, sunlit
     field (warm highlights, a breath darker), the sun's rays visible through the haze by day, and
     fair-weather clouds drifting over (Terrain ▸ Clouds; the weather takes the sky over while it
     lasts: WarFX.weather, and gives it back as it found it). Off in the dungeons (DungeonMood grades those:
     The Depths, Deadvault, Plague Night, the Undead invasion) and the Gilded Rat.

     GRADE below is the whole of it. Nothing here is sent to the server. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local round = ReplicatedStorage:WaitForChild("Round")
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
-- (a phone keeps its frames for the fight: no fair-weather clouds there; the weather's own still come)
local CLOUDS = Device.kind() ~= "phone"

local GRADE = {contrast = 0.13, saturation = -0.12, brightness = -0.02, tint = Color3.fromRGB(255, 244, 228)}
local RAYS = {intensity = 0.06, spread = 0.3}
local SKIP = {Depths = true, Deadvault = true, Plague = true, InvUndead = true, Tavern = true}
local FAIR = {Cover = 0.5, Density = 0.55, Color = Color3.fromRGB(250, 248, 244)}
local NO_CLOUDS = {Dragonfall = true}   -- (the caldera's sky is its own: ash and fire)

local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "CinematicGrade"
cc.Contrast, cc.Saturation, cc.TintColor = 0, 0, Color3.new(1, 1, 1)
cc.Parent = Lighting

local function rays() return Lighting:FindFirstChildOfClass("SunRaysEffect") end
local baseRays   -- (the place's own, put back where the grade is off)

local function apply()
	local on = not SKIP[round:GetAttribute("Mode") or ""]
	local info = TweenInfo.new(1.5)
	TweenService:Create(cc, info, on and {Contrast = GRADE.contrast, Saturation = GRADE.saturation, Brightness = GRADE.brightness, TintColor = GRADE.tint}
		or {Contrast = 0, Saturation = 0, Brightness = 0, TintColor = Color3.new(1, 1, 1)}):Play()
	local r = rays()
	if r then
		baseRays = baseRays or {intensity = r.Intensity, spread = r.Spread}
		TweenService:Create(r, info, on and {Intensity = RAYS.intensity, Spread = RAYS.spread} or {Intensity = baseRays.intensity, Spread = baseRays.spread}):Play()
	end
end
round:GetAttributeChangedSignal("Mode"):Connect(apply)
apply()

-- the clouds: one Clouds under the Terrain, eased towards what this map wants a little at a time
-- (never a tween: the weather may set its own at any moment, and while it's up it's left alone)
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
local placeSky = clouds and {Cover = clouds.Cover, Density = clouds.Density, Color = clouds.Color}
if not clouds then
	clouds = Instance.new("Clouds")
	clouds.Cover, clouds.Density = 0, 0
	clouds.Parent = workspace.Terrain
end
local function skyWant()
	local mode = round:GetAttribute("Mode") or ""
	if not CLOUDS or SKIP[mode] or NO_CLOUDS[mode] then return placeSky or {Cover = 0, Density = 0, Color = FAIR.Color} end
	return FAIR
end
task.spawn(function()
	local first = true   -- (the sky as it should be from the start: no clouding over as you join)
	while true do
		if not clouds.Parent then
			clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
			clouds.Parent = workspace.Terrain
		end
		if not WarFX.weatherKind() then
			local want = skyWant()
			if math.abs(want.Cover - clouds.Cover) + math.abs(want.Density - clouds.Density) > 0.004 then
				local k = first and 1 or 0.04
				clouds.Cover += (want.Cover - clouds.Cover) * k
				clouds.Density += (want.Density - clouds.Density) * k
				clouds.Color = clouds.Color:Lerp(want.Color, k)
			end
		end
		first = false
		task.wait(0.25)
	end
end)
