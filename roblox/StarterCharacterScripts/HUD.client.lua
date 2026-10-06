--[[ HUD — health and stamina bars, bottom-left. Built from Instances so
     there's nothing to upload. Reads Humanoid.Health and the BlockMeter /
     BlockMax attributes (stamina); pulses when stamina is low, flashes the
     health bar while bleeding. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = script.Parent
local Humanoid  = character:WaitForChild("Humanoid")

--------------------------------------------------------------------
local BAR_W, BAR_H   = 260, 18
local LOW_STAMINA    = 0.2
local LERP_SPEED     = 10
local HP_HIGH  = Color3.fromRGB(105, 205, 120)
local HP_LOW   = Color3.fromRGB(215, 70, 60)
local STA_COL  = Color3.fromRGB(235, 190, 80)
local BG_COL   = Color3.fromRGB(13, 30, 64)
--------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = true
gui.DisplayOrder = 10

local root = Instance.new("Frame")
root.Name = "Bars"
root.AnchorPoint = Vector2.new(0, 1)
root.Position = UDim2.new(0, 24, 1, -24)
root.Size = UDim2.fromOffset(BAR_W + 24, BAR_H * 2 + 36)
root.BackgroundColor3 = BG_COL
root.BackgroundTransparency = 0.35
root.BorderSizePixel = 0
root.Parent = gui
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", root)
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.85
stroke.Thickness = 1

local function makeBar(y, color, label)
	local track = Instance.new("Frame")
	track.Position = UDim2.fromOffset(12, y)
	track.Size = UDim2.fromOffset(BAR_W, BAR_H)
	track.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	track.BackgroundTransparency = 0.5
	track.BorderSizePixel = 0
	track.Parent = root
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 8)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)
	local grad = Instance.new("UIGradient", fill)
	grad.Rotation = 90
	grad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190))

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Position = UDim2.fromOffset(8, 0)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 12
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.6
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Text = label
	text.Parent = track
	return fill, text
end

local hpFill,  hpText  = makeBar(10,          HP_HIGH, "HP")
local staFill, staText = makeBar(BAR_H + 22,  STA_COL, "STAMINA")
gui.Parent = player:WaitForChild("PlayerGui")

local hpShown, staShown = 1, 1

--------------------------------------------------------------------
--  COMBAT TEXT — a word near the crosshair for what just happened:
--  as the defender  PARRY ×2 +12 (gold, big) · BLOCK −20 (grey) · CHAMBER · GUARD BROKEN
--  as the attacker  PARRIED / CHAMBERED (red) · BLOCKED (grey) · FEINT · TEAMMATE (orange)
--  (hitting a wall / the floor shows nothing — you heard the clang)
--------------------------------------------------------------------
local TEXT_COL = {
	PARRY = Color3.fromRGB(255, 215, 110), CHAMBER = Color3.fromRGB(255, 215, 110),
	BLOCK = Color3.fromRGB(200, 200, 200), ["GUARD BROKEN"] = Color3.fromRGB(230, 80, 60), DISARMED = Color3.fromRGB(230, 80, 60),
	PARRIED = Color3.fromRGB(230, 80, 60), CHAMBERED = Color3.fromRGB(230, 80, 60),
	BLOCKED = Color3.fromRGB(200, 200, 200), HIT = Color3.fromRGB(240, 240, 240), FEINT = Color3.fromRGB(170, 170, 190), WALL = Color3.fromRGB(170, 170, 170),
	DODGED = Color3.fromRGB(120, 200, 120),
	DEALT = Color3.fromRGB(255, 240, 200), HEAD = Color3.fromRGB(255, 200, 90), KILL = Color3.fromRGB(255, 90, 70),
	TAKEN = Color3.fromRGB(230, 70, 60), TEAMMATE = Color3.fromRGB(200, 140, 60),
}
local popupOrder = 0
local function popup(text, big, colorKey, offsetX)
	popupOrder += 1
	local key = colorKey or text:match("^(GUARD BROKEN)") or text:match("^(%u+)")
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.new(0.5, offsetX or 0, 0.5, 70 + (popupOrder % 3) * 4)
	l.Size = UDim2.fromOffset(400, 40)
	l.Font = Enum.Font.GothamBlack
	l.TextSize = big and 30 or 20
	l.TextColor3 = TEXT_COL[key] or Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.4
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	l.Text = text
	l.ZIndex = 5
	l.Parent = gui
	local tw = game:GetService("TweenService")
	tw:Create(l, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = l.Position - UDim2.fromOffset(0, big and 46 or 30)}):Play()
	task.delay(0.35, function()
		tw:Create(l, TweenInfo.new(0.4), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		task.delay(0.45, function() if l.Parent then l:Destroy() end end)
	end)
end

-- defender side (server stamps these)
character:GetAttributeChangedSignal("GuardTick"):Connect(function()
	local t = character:GetAttribute("GuardText") or ""
	popup(t, t:sub(1, 5) == "PARRY" or t:sub(1, 7) == "CHAMBER")
end)
character:GetAttributeChangedSignal("DodgeRefundTick"):Connect(function() popup("DODGED  +8", false) end)
-- attacker side (CombatClient stamps LocalImpactKind; the damage number comes from the server)
character:GetAttributeChangedSignal("LocalImpactAt"):Connect(function()
	local k = character:GetAttribute("LocalImpactKind")
	if k == "parry" then popup("PARRIED", true)
	elseif k == "chamber" then popup("CHAMBERED", true)
	elseif k == "block" then popup("BLOCKED", false)
	elseif k == "feint" then popup("FEINT", false) end
end)
-- damage dealt: "30" · "HEAD  60" (gold) · "KILL  60" (red), to the right of the crosshair
character:GetAttributeChangedSignal("DealtTick"):Connect(function()
	local t = character:GetAttribute("DealtText") or ""
	local key = t:sub(1, 4) == "KILL" and "KILL" or (t:sub(1, 4) == "HEAD" and "HEAD" or (t:sub(1, 4) == "TEAM" and "TEAMMATE" or "DEALT"))
	popup(t, key == "KILL" or key == "HEAD", key, 120)
end)
-- damage taken: "-30" in red, to the left
character:GetAttributeChangedSignal("TakenTick"):Connect(function()
	popup(character:GetAttribute("TakenText") or "", true, "TAKEN", -120)
end)

local conn = RunService.RenderStepped:Connect(function(dt)
	local a = math.clamp(dt * LERP_SPEED, 0, 1)
	local t = os.clock()

	local hp = Humanoid.MaxHealth > 0 and math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1) or 0
	hpShown = hpShown + (hp - hpShown) * a
	hpFill.Size = UDim2.fromScale(hpShown, 1)
	local col = HP_LOW:Lerp(HP_HIGH, hpShown)
	if character:GetAttribute("Bleeding") == true then
		col = col:Lerp(Color3.new(1, 1, 1), 0.25 + 0.25 * math.sin(t * 9))
	end
	hpFill.BackgroundColor3 = col
	hpText.Text = string.format("HP  %d", math.ceil(Humanoid.Health))

	local staMax = character:GetAttribute("BlockMax") or 100
	local sta = math.clamp((character:GetAttribute("BlockMeter") or staMax) / staMax, 0, 1)
	staShown = staShown + (sta - staShown) * a
	staFill.Size = UDim2.fromScale(staShown, 1)
	if sta < LOW_STAMINA then
		staFill.BackgroundTransparency = 0.25 + 0.25 * math.sin(t * 10)
	else
		staFill.BackgroundTransparency = 0
	end
	staText.Text = string.format("STAMINA  %d", math.floor(sta * staMax + 0.5))
end)

script.Destroying:Connect(function() conn:Disconnect() end)
