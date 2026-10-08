--[[ HUD — chunky Health / Energy bars at the bottom centre and a weapon chip
     bottom-right. Built from Instances so there's nothing to upload. Reads Humanoid.Health and the BlockMeter /
     BlockMax attributes (stamina); pulses when stamina is low, flashes the
     health bar while bleeding. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = script.Parent
local Humanoid  = character:WaitForChild("Humanoid")

--------------------------------------------------------------------
local BAR_W, BAR_H   = 330, 30
local LOW_STAMINA    = 0.2
local LERP_SPEED     = 10
local HP_HIGH  = Color3.fromRGB(255, 118, 48)    -- health: orange-red, like the references
local HP_LOW   = Color3.fromRGB(215, 50, 40)
local STA_COL  = Color3.fromRGB(64, 138, 255)    -- energy: bright blue
local BG_COL   = Color3.fromRGB(10, 22, 48)
local FONT_BIG = Enum.Font.FredokaOne
--------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = true
gui.DisplayOrder = 10

-- the two bars sit side by side at the bottom centre: HEALTH left, ENERGY right
local root = Instance.new("Frame")
root.Name = "Bars"
root.AnchorPoint = Vector2.new(0.5, 1)
root.Position = UDim2.new(0.5, 0, 1, -100)   -- above the weapon bar (StarterPlayerScripts ▸ Hotbar)
root.Size = UDim2.fromOffset(BAR_W * 2 + 16, BAR_H)
root.BackgroundTransparency = 1
root.Parent = gui

local function makeBar(x, color, label, alignRight)
	local track = Instance.new("Frame")
	track.Position = UDim2.fromOffset(x, 0)
	track.Size = UDim2.fromOffset(BAR_W, BAR_H)
	track.BackgroundColor3 = BG_COL
	track.BackgroundTransparency = 0.25
	track.BorderSizePixel = 0
	track.Parent = root
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 8)
	local st = Instance.new("UIStroke", track); st.Color = Color3.new(1, 1, 1); st.Transparency = 0.7; st.Thickness = 2

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)
	local grad = Instance.new("UIGradient", fill)
	grad.Rotation = 90
	grad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170))
	-- a thin highlight along the top
	local shine = Instance.new("Frame"); shine.Size = UDim2.new(1, -8, 0, 3); shine.Position = UDim2.fromOffset(4, 3); shine.BackgroundColor3 = Color3.new(1, 1, 1); shine.BackgroundTransparency = 0.6; shine.BorderSizePixel = 0; shine.Parent = fill
	Instance.new("UICorner", shine).CornerRadius = UDim.new(1, 0)

	local num = Instance.new("TextLabel")
	num.BackgroundTransparency = 1
	num.Size = UDim2.new(0.5, 0, 1, 0)
	num.Position = UDim2.fromOffset(12, 0)
	num.Font = FONT_BIG
	num.TextSize = 22
	num.TextColor3 = Color3.new(1, 1, 1)
	num.TextStrokeTransparency = 0.5
	num.TextXAlignment = Enum.TextXAlignment.Left
	num.Text = "100"
	num.ZIndex = 3
	num.Parent = track
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(0.5, -12, 1, 0)
	text.Position = UDim2.new(0.5, 0, 0, 0)
	text.Font = FONT_BIG
	text.TextSize = 18
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.5
	text.TextXAlignment = Enum.TextXAlignment.Right
	text.Text = label
	text.ZIndex = 3
	text.Parent = track
	return fill, num, text
end

local hpFill,  hpText,  hpLabel  = makeBar(0,          HP_HIGH, "Health")
local staFill, staText, staLabel = makeBar(BAR_W + 16, STA_COL, "Energy")

-- weapon chip, bottom right: what is in your hands
local chip = Instance.new("Frame")
chip.AnchorPoint = Vector2.new(1, 1)
chip.Position = UDim2.new(1, -24, 1, -100)
chip.Size = UDim2.fromOffset(220, 46)
chip.BackgroundColor3 = BG_COL
chip.BackgroundTransparency = 0.25
chip.BorderSizePixel = 0
chip.Parent = gui
Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 10)
do local st = Instance.new("UIStroke", chip); st.Color = Color3.new(1, 1, 1); st.Transparency = 0.75; st.Thickness = 2 end
local chipName = Instance.new("TextLabel")
chipName.BackgroundTransparency = 1; chipName.Size = UDim2.new(1, -24, 0, 24); chipName.Position = UDim2.fromOffset(12, 4)
chipName.Font = FONT_BIG; chipName.TextSize = 18; chipName.TextColor3 = Color3.new(1, 1, 1); chipName.TextXAlignment = Enum.TextXAlignment.Left; chipName.TextTruncate = Enum.TextTruncate.AtEnd
chipName.Text = "Unarmed"; chipName.Parent = chip
local chipSub = Instance.new("TextLabel")
chipSub.BackgroundTransparency = 1; chipSub.Size = UDim2.new(1, -24, 0, 16); chipSub.Position = UDim2.fromOffset(12, 26)
chipSub.Font = Enum.Font.GothamMedium; chipSub.TextSize = 11; chipSub.TextColor3 = Color3.fromRGB(168, 190, 230); chipSub.TextXAlignment = Enum.TextXAlignment.Left
chipSub.Text = "1 · 2 to switch  ·  G kick  ·  M menu"; chipSub.Parent = chip
local function refreshChip()
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then chipName.Text = "Unarmed"; return end
	local ok, cfg = pcall(function() return require(tool:WaitForChild("Config", 1)) end)
	local skin = tool:GetAttribute("Skin")
	chipName.Text = (ok and cfg and cfg.Name or tool.Name) .. (skin and skin ~= "" and skin ~= "Default" and ("  ·  " .. skin) or "")
end
character.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.defer(refreshChip) end end)
character.ChildRemoved:Connect(function(c) if c:IsA("Tool") then task.defer(refreshChip) end end)
refreshChip()
gui.Parent = player:WaitForChild("PlayerGui")

local hpShown, staShown = 1, 1

--------------------------------------------------------------------
--  COMBAT TEXT — a word near the crosshair for what just happened:
--  as the defender  PARRY x2 +12 (gold, big) · BLOCK -20 (grey) · CHAMBER · GUARD BROKEN
--  as the attacker  PARRIED / CHAMBERED (red) · BLOCKED (grey) · FEINT · TEAMMATE (orange)
--  (hitting a wall / the floor shows nothing — you heard the clang)
--------------------------------------------------------------------
local TEXT_COL = {
	PARRY = Color3.fromRGB(255, 215, 110), CHAMBER = Color3.fromRGB(255, 215, 110),
	BLOCK = Color3.fromRGB(200, 200, 200), ["GUARD BROKEN"] = Color3.fromRGB(230, 80, 60), DISARMED = Color3.fromRGB(230, 80, 60),
	PARRIED = Color3.fromRGB(230, 80, 60), CHAMBERED = Color3.fromRGB(230, 80, 60),
	BLOCKED = Color3.fromRGB(200, 200, 200), HIT = Color3.fromRGB(240, 240, 240), FEINT = Color3.fromRGB(170, 170, 190), WALL = Color3.fromRGB(170, 170, 170),
	DODGED = Color3.fromRGB(120, 200, 120), EXHAUSTED = Color3.fromRGB(230, 80, 60),
	DEALT = Color3.fromRGB(255, 240, 200), HEAD = Color3.fromRGB(255, 200, 90), KILL = Color3.fromRGB(255, 90, 70),
	TAKEN = Color3.fromRGB(230, 70, 60), TEAMMATE = Color3.fromRGB(200, 140, 60),
}
local popupOrder = 0
local function popup(text, big, colorKey, offsetX)
	popupOrder += 1
	local key = colorKey or text:match("^(GUARD BROKEN)") or text:match("^(%u+)")
	-- a parry streak grows: PARRY x2, x3… get bigger each time
	local streak = tonumber(text:match("x(%d+)")) or 1
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.new(0.5, offsetX or 0, 0.5, 70 + (popupOrder % 3) * 4)
	l.Size = UDim2.fromOffset(400, 40)
	l.Font = Enum.Font.GothamBlack
	l.TextSize = (big and 30 or 20) + (streak - 1) * 5
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
character:GetAttributeChangedSignal("ExhaustedTick"):Connect(function() popup("EXHAUSTED", false) end)
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

local hubMenu = nil
local conn = RunService.RenderStepped:Connect(function(dt)
	local a = math.clamp(dt * LERP_SPEED, 0, 1)
	local t = os.clock()
	-- the main menu covers the screen: the bars step aside while it is up
	hubMenu = hubMenu or (gui.Parent and gui.Parent:FindFirstChild("HubMenu"))
	local menuUp = hubMenu ~= nil and hubMenu.Enabled
	if root.Visible == menuUp then root.Visible = not menuUp; chip.Visible = not menuUp end

	local hp = Humanoid.MaxHealth > 0 and math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1) or 0
	hpShown = hpShown + (hp - hpShown) * a
	hpFill.Size = UDim2.fromScale(hpShown, 1)
	local col = HP_LOW:Lerp(HP_HIGH, hpShown)
	if character:GetAttribute("Bleeding") == true then
		col = col:Lerp(Color3.new(1, 1, 1), 0.25 + 0.25 * math.sin(t * 9))
	end
	hpFill.BackgroundColor3 = col
	hpText.Text = string.format("+ %d", math.ceil(Humanoid.Health))

	local staMax = character:GetAttribute("BlockMax") or 100
	local sta = math.clamp((character:GetAttribute("BlockMeter") or staMax) / staMax, 0, 1)
	staShown = staShown + (sta - staShown) * a
	staFill.Size = UDim2.fromScale(staShown, 1)
	if sta < LOW_STAMINA then
		staFill.BackgroundTransparency = 0.25 + 0.25 * math.sin(t * 10)
	else
		staFill.BackgroundTransparency = 0
	end
	staText.Text = string.format("%d +", math.floor(sta * staMax + 0.5))
		staLabel.Text = (character:GetAttribute("BlockMeter") ~= nil and sta <= 0) and "EXHAUSTED" or "Energy"
end)

script.Destroying:Connect(function() conn:Disconnect() end)

--------------------------------------------------------------------
--  WHERE THE HIT CAME FROM: a red arc at the edge of the screen, toward
--  the blow, fading out (several at once if you're being swarmed)
--------------------------------------------------------------------
do
	local arcGui = Instance.new("ScreenGui")
	arcGui.Name = "HitArcs"
	arcGui.IgnoreGuiInset = true
	arcGui.ResetOnSpawn = true
	arcGui.DisplayOrder = 4
	arcGui.Parent = player:WaitForChild("PlayerGui")
	local TweenService = game:GetService("TweenService")
	character:GetAttributeChangedSignal("HitTick"):Connect(function()
		local dir = character:GetAttribute("HitDir")
		local cam = workspace.CurrentCamera
		if typeof(dir) ~= "Vector3" or not cam then return end
		-- the blow travels along dir: it came FROM the other way
		local from = -dir
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		local ang = math.atan2(from:Dot(right), from:Dot(Vector3.new(look.X, 0, look.Z).Unit))   -- 0 = in front, + = to the right
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromScale(0.62, 0.62)
		holder.SizeConstraint = Enum.SizeConstraint.RelativeYY
		holder.Rotation = math.deg(ang)
		holder.Parent = arcGui
		local arc = Instance.new("Frame")
		arc.AnchorPoint = Vector2.new(0.5, 0)
		arc.Position = UDim2.fromScale(0.5, 0)
		arc.Size = UDim2.new(0.34, 0, 0, 10)
		arc.BackgroundColor3 = Color3.fromRGB(220, 30, 40)
		arc.BackgroundTransparency = 0.15
		arc.BorderSizePixel = 0
		Instance.new("UICorner", arc).CornerRadius = UDim.new(1, 0)
		local g = Instance.new("UIGradient", arc)
		g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})
		arc.Parent = holder
		TweenService:Create(arc, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
		task.delay(1, function() holder:Destroy() end)
	end)
end
