--[[ INJURY FX — what being hurt feels like on screen (local player only).
       • red flash when we take a hit            (HitTick attribute, server)
       • colour drains + heartbeat while bleeding or below LOW_HP_FRAC
     Camera motion on hits lives in CameraRig; this is purely screen + sound. ]]

local RunService = game:GetService("RunService")
local Lighting   = game:GetService("Lighting")
local Players    = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds      = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))

local player    = Players.LocalPlayer
local character = script.Parent
local Humanoid  = character:WaitForChild("Humanoid")

--------------------------------------------------------------------
local FLASH_ALPHA  = 0.45   -- how red the screen goes on a hit
local FLASH_DECAY  = 2.5    -- per second
local BLEED_SAT    = -0.75  -- saturation at full severity
local BLEED_TINT   = 0.25   -- red tint at full severity
local LOW_HP_FRAC  = 0.35   -- effects start ramping below this health fraction
local HEART_VOLUME = 0.8
--------------------------------------------------------------------

local cc = Lighting:FindFirstChild("InjuryFX")
if not cc then
	cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "InjuryFX"
	cc.Parent = Lighting
end

local gui = Instance.new("ScreenGui")
gui.Name = "InjuryFX"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 900
gui.ResetOnSpawn = true
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

-- screen-EDGE flash: white for a parry / chamber we landed, red for one we ate
local edgeFrames = {}
for _, side in ipairs({"L", "R", "T", "B"}) do
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 1
	local g = Instance.new("UIGradient", f)
	if side == "L" then
		f.Size = UDim2.new(0.07, 0, 1, 0)
		g.Transparency = NumberSequence.new(0, 1)
	elseif side == "R" then
		f.Size = UDim2.new(0.07, 0, 1, 0); f.AnchorPoint = Vector2.new(1, 0); f.Position = UDim2.fromScale(1, 0)
		g.Transparency = NumberSequence.new(1, 0)
	elseif side == "T" then
		f.Size = UDim2.new(1, 0, 0.1, 0)
		g.Rotation = 90; g.Transparency = NumberSequence.new(0, 1)
	else
		f.Size = UDim2.new(1, 0, 0.1, 0); f.AnchorPoint = Vector2.new(0, 1); f.Position = UDim2.fromScale(0, 1)
		g.Rotation = 90; g.Transparency = NumberSequence.new(1, 0)
	end
	f.Parent = gui
	table.insert(edgeFrames, f)
end
local edgeAlpha = 0
local function edgeFlash(color, alpha)
	for _, f in ipairs(edgeFrames) do f.BackgroundColor3 = color end
	edgeAlpha = alpha
end

local heartbeat = nil

character:GetAttributeChangedSignal("HitTick"):Connect(function()
	flash.BackgroundTransparency = 1 - FLASH_ALPHA
end)
-- we parried / chambered someone (server stamps ParryTick)
character:GetAttributeChangedSignal("ParryTick"):Connect(function()
	edgeFlash(Color3.fromRGB(255, 250, 230), 0.8)
end)
-- our swing got parried / chambered (CombatClient stamps LocalImpactKind)
character:GetAttributeChangedSignal("LocalImpactAt"):Connect(function()
	local k = character:GetAttribute("LocalImpactKind")
	if k == "parry" or k == "chamber" then edgeFlash(Color3.fromRGB(200, 40, 30), 0.6) end
end)

local conn = RunService.RenderStepped:Connect(function(dt)
	flash.BackgroundTransparency = math.min(1, flash.BackgroundTransparency + FLASH_DECAY * dt)
	if edgeAlpha > 0 then
		edgeAlpha = math.max(0, edgeAlpha - 3 * dt)
		for _, f in ipairs(edgeFrames) do f.BackgroundTransparency = 1 - edgeAlpha end
	end

	local frac = Humanoid.MaxHealth > 0 and (Humanoid.Health / Humanoid.MaxHealth) or 1
	local severity
	if character:GetAttribute("Bleeding") == true then
		severity = 1
	elseif frac < LOW_HP_FRAC then
		severity = 1 - frac / LOW_HP_FRAC
	else
		severity = 0
	end

	local a = math.clamp(dt * 3, 0, 1)
	cc.Saturation = cc.Saturation + (BLEED_SAT * severity - cc.Saturation) * a
	cc.Contrast   = cc.Contrast   + (0.1 * severity - cc.Contrast) * a
	cc.TintColor  = cc.TintColor:Lerp(Color3.new(1, 1 - BLEED_TINT * severity, 1 - BLEED_TINT * severity), a)

	if severity > 0.05 and Humanoid.Health > 0 then
		if not heartbeat then
			heartbeat = Sounds.loop(SoundConfig.Heartbeat, workspace.CurrentCamera, 0)
		end
		if heartbeat then
			heartbeat.Volume = HEART_VOLUME * severity
			heartbeat.PlaybackSpeed = 0.9 + 0.5 * severity
		end
	elseif heartbeat then
		heartbeat:Destroy()
		heartbeat = nil
	end
end)

local function cleanup()
	conn:Disconnect()
	if heartbeat then heartbeat:Destroy(); heartbeat = nil end
	cc.Saturation, cc.Contrast, cc.TintColor = 0, 0, Color3.new(1, 1, 1)
end
script.Destroying:Connect(cleanup)
