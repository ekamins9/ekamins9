--[[ CINEMATIC GRADE — a film look over the open-air maps, on your screen only: more contrast,
     the colour pulled back from Roblox's bright toy greens and blues towards a painted, sunlit
     field (warm highlights, a breath darker), and the sun's rays visible through the haze by day. Off in the dungeons (DungeonMood grades those:
     The Depths, Deadvault, Plague Night, the Undead invasion) and the Gilded Rat.

     GRADE below is the whole of it. Nothing here is sent to the server. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local round = ReplicatedStorage:WaitForChild("Round")

local GRADE = {contrast = 0.13, saturation = -0.12, brightness = -0.02, tint = Color3.fromRGB(255, 244, 228)}
local RAYS = {intensity = 0.06, spread = 0.3}
local SKIP = {Depths = true, Deadvault = true, Plague = true, InvUndead = true, Tavern = true}

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
