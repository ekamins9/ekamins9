--[[ RIPOSTE CUE — a parry opens a RIPOSTE (Combat ▸ CombatServer: for RIPOSTE_DURATION your
     next swing winds up RIPOSTE_SPEED × quicker), and it should be impossible to miss:

       YOURS     a gold flash round the screen as it opens; under the crosshair RIPOSTE · STRIKE
                 NOW, how much quicker, and a bar running out with the window; swing into it
                 and RIPOSTE! lands, the blade trailing gold through the quick swing
       ANYONE'S  (players and bots) their blade glows gold while their window's open — guard
                 up — and trails gold through the riposte itself

     From the character attributes RiposteUntil / RiposteLen / RiposteSpeed (the shared clock)
     and RiposteTick (a riposte swung). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 206, 90)
local PALE = Color3.fromRGB(255, 244, 200)
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

--------------------------------------------------------------------
--  YOUR HUD
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "RiposteCue"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent, size, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextSize = size
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.35
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	l.Parent = parent
	return l
end

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0.5, 58)
panel.Size = UDim2.fromOffset(260, 54)
panel.BackgroundTransparency = 1
panel.Visible = false
panel.Parent = gui
local title = label(panel, 20, GOLD)
title.Size = UDim2.new(1, 0, 0, 22)
title.Text = "⚔  RIPOSTE  ·  STRIKE NOW"
local sub = label(panel, 12, PALE)
sub.Position = UDim2.fromOffset(0, 22)
sub.Size = UDim2.new(1, 0, 0, 14)
local back = Instance.new("Frame")
back.Position = UDim2.fromOffset(20, 40)
back.Size = UDim2.new(1, -40, 0, 8)
back.BackgroundColor3 = Color3.fromRGB(20, 16, 8)
back.BackgroundTransparency = 0.25
back.BorderSizePixel = 0
back.Parent = panel
Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)
local fill = Instance.new("Frame")
fill.AnchorPoint = Vector2.new(0.5, 0)
fill.Position = UDim2.fromScale(0.5, 0)
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = GOLD
fill.BorderSizePixel = 0
fill.Parent = back
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
local scale = Instance.new("UIScale"); scale.Parent = panel

-- the edge of the screen flashing gold as the window opens
local edge = Instance.new("Frame")
edge.Size = UDim2.fromScale(1, 1)
edge.BackgroundTransparency = 1
edge.Parent = gui
local edgeStroke = Instance.new("UIStroke")
edgeStroke.Color = GOLD
edgeStroke.Thickness = 22
edgeStroke.Transparency = 1
edgeStroke.Parent = edge

-- RIPOSTE! as the quick swing goes
local shout = label(gui, 44, GOLD)
shout.AnchorPoint = Vector2.new(0.5, 0.5)
shout.Position = UDim2.new(0.5, 0, 0.5, -90)
shout.Size = UDim2.fromOffset(500, 50)
shout.Text = "RIPOSTE!"
shout.TextTransparency = 1
shout.TextStrokeTransparency = 1
local shoutScale = Instance.new("UIScale"); shoutScale.Parent = shout

local function opened(c)
	edgeStroke.Transparency = 0.15
	TweenService:Create(edgeStroke, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
	scale.Scale = 1.35
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
	local mult = c:GetAttribute("RiposteSpeed") or 1.6
	sub.Text = string.format("YOUR NEXT SWING  +%d%% FASTER", math.floor((mult - 1) * 100 + 0.5))
end
local spent = nil   -- (the window you've swung into: its bar goes)
local function riposted(c)
	spent = c:GetAttribute("RiposteUntil")
	shout.TextTransparency, shout.TextStrokeTransparency = 0, 0.3
	shoutScale.Scale = 1.6
	TweenService:Create(shoutScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = 1}):Play()
	task.delay(0.45, function()
		TweenService:Create(shout, TweenInfo.new(0.35), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end)
end

--------------------------------------------------------------------
--  EVERYONE'S BLADE
--------------------------------------------------------------------
local function bladeParts(c)
	local tool = c:FindFirstChildOfClass("Tool")
	if not tool then return {} end
	local out = {}
	for _, p in ipairs(tool:GetDescendants()) do
		if p:IsA("BasePart") and (p:GetAttribute("SkinPart") == "Blade" or p.Name == "Hitbox") and #out < 3 then table.insert(out, p) end
	end
	if #out == 0 and tool:FindFirstChild("Handle") then out = {tool.Handle} end
	return out
end
-- the gold glow while the window's open
local function glowOn(c)
	local made = {}
	for _, p in ipairs(bladeParts(c)) do
		local e = Instance.new("ParticleEmitter")
		e.Texture = SPARK
		e.Color = ColorSequence.new(PALE, GOLD)
		e.LightEmission = 1
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)})
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
		e.Lifetime = NumberRange.new(0.25, 0.45)
		e.Speed = NumberRange.new(0.5, 1.5)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Rate = 45
		e.ZOffset = 0.5
		e.Shape = Enum.ParticleEmitterShape.Box
		e.Parent = p
		local l = Instance.new("PointLight"); l.Color = GOLD; l.Range = 5; l.Brightness = 0.9; l.Shadows = false; l.Parent = p
		table.insert(made, e); table.insert(made, l)
	end
	return made
end
-- a gold trail along the blade through the quick swing
local function trail(c)
	for _, p in ipairs(bladeParts(c)) do
		local s = p.Size
		local axis = (s.X >= s.Y and s.X >= s.Z) and Vector3.xAxis or ((s.Y >= s.Z) and Vector3.yAxis or Vector3.zAxis)
		local half = math.max(s.X, s.Y, s.Z) / 2
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = axis * half, -axis * half
		a0.Parent, a1.Parent = p, p
		local t = Instance.new("Trail")
		t.Attachment0, t.Attachment1 = a0, a1
		t.Color = ColorSequence.new(PALE, GOLD)
		t.LightEmission = 1
		t.Lifetime = 0.22
		t.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
		t.FaceCamera = true
		t.Parent = p
		Debris:AddItem(t, 0.8); Debris:AddItem(a0, 0.8); Debris:AddItem(a1, 0.8)
		break
	end
end

local looks = setmetatable({}, {__mode = "k"})   -- [character] = {glow, tick, open}
local function bodies()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(out, p.Character) end end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do if m:IsA("Model") then table.insert(out, m) end end end
	return out
end

RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	local me = player.Character
	local mine = false
	for _, c in ipairs(bodies()) do
		local L = looks[c]
		if not L then L = {tick = c:GetAttribute("RiposteTick")}; looks[c] = L end
		local untilT = c:GetAttribute("RiposteUntil") or 0
		local open = untilT > now
		if open and not L.open then
			L.open = true
			L.glow = glowOn(c)
			if c == me then opened(c) end
		elseif not open and L.open then
			L.open = false
			for _, x in ipairs(L.glow or {}) do
				if x:IsA("ParticleEmitter") then x.Enabled = false; Debris:AddItem(x, 0.5) else x:Destroy() end
			end
			L.glow = nil
		end
		local tick = c:GetAttribute("RiposteTick")
		if tick ~= L.tick then
			L.tick = tick
			pcall(trail, c)
			if c == me then riposted(c) end
		end
		if c == me and open and untilT ~= spent then
			mine = true
			local len = c:GetAttribute("RiposteLen") or 1.2
			fill.Size = UDim2.fromScale(math.clamp((untilT - now) / len, 0, 1), 1)
		end
	end
	panel.Visible = mine
	for c, L in pairs(looks) do
		if not c.Parent then
			for _, x in ipairs(L.glow or {}) do x:Destroy() end
			looks[c] = nil
		end
	end
end)
