--[[ CINEMATIC GRADE — a gentle film look over the open-air maps, on your screen only: a touch
     more contrast and colour, the shadows a shade cooler and the lights a shade warmer, and the
     sun's rays visible through the haze by day. Off in the dungeons (DungeonMood grades those:
     The Depths, Deadvault, Plague Night, the Undead invasion) and the Gilded Rat.

     GRADE below is the whole of it. Nothing here is sent to the server. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local round = ReplicatedStorage:WaitForChild("Round")

local GRADE = {contrast = 0.08, saturation = 0.08, tint = Color3.fromRGB(255, 250, 244)}
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
	TweenService:Create(cc, info, on and {Contrast = GRADE.contrast, Saturation = GRADE.saturation, TintColor = GRADE.tint}
		or {Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1)}):Play()
	local r = rays()
	if r then
		baseRays = baseRays or {intensity = r.Intensity, spread = r.Spread}
		TweenService:Create(r, info, on and {Intensity = RAYS.intensity, Spread = RAYS.spread} or {Intensity = baseRays.intensity, Spread = baseRays.spread}):Play()
	end
end
round:GetAttributeChangedSignal("Mode"):Connect(apply)
apply()
