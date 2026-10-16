--[[ PROMPTS — every ProximityPrompt in the game drawn in its own look, not Roblox's default box:
     a dark-glass card (Theme), a key cap with the key on it (your pickup key, E, a gamepad button,
     or TAP on a phone), what it does in big outlined type and what it is under that, and a bar
     along the bottom that fills while you hold. Loot (a chest, a drop, a container: anything
     whose model carries Rarity) tints the key cap and the bar its rarity's colour.

     Each prompt is switched to Style Custom on this screen only (the server's prompts are
     unchanged); ProximityPromptService says when one is shown, held and triggered. On a touch
     screen, the card is the button. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))

local player = Players.LocalPlayer
-- (each card straight in PlayerGui, ResetOnSpawn off: a respawn empties PlayerGui of anything else)
local playerGui = player:WaitForChild("PlayerGui")

local RARITY = {}
for _, r in ipairs(Catalog.LOOT and Catalog.LOOT.RARITIES or {}) do RARITY[r.id] = r.color end

-- every prompt: ours to draw
local function claim(d)
	if d:IsA("ProximityPrompt") then d.Style = Enum.ProximityPromptStyle.Custom end
end
for _, d in ipairs(workspace:GetDescendants()) do claim(d) end
workspace.DescendantAdded:Connect(claim)

-- the key, as a word on a cap
local KEY_NAME = {One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
	LeftShift = "SHIFT", LeftControl = "CTRL", Return = "ENTER", Space = "SPACE", Tab = "TAB"}
local PAD_NAME = {ButtonX = "X", ButtonY = "Y", ButtonA = "A", ButtonB = "B", ButtonL1 = "LB", ButtonR1 = "RB", ButtonL2 = "LT", ButtonR2 = "RT", DPadUp = "↑", DPadDown = "↓"}
local function keyText(prompt, inputType)
	if inputType == Enum.ProximityPromptInputType.Touch then return "TAP" end
	if inputType == Enum.ProximityPromptInputType.Gamepad then
		local n = prompt.GamepadKeyCode.Name
		return PAD_NAME[n] or n
	end
	local n = prompt.KeyboardKeyCode.Name
	return KEY_NAME[n] or n
end

local function rarityOf(prompt)
	local p = prompt.Parent
	for _ = 1, 4 do
		if not p then break end
		local r = p:GetAttribute("Rarity")
		if r and RARITY[r] then return RARITY[r] end
		p = p.Parent
	end
	return nil
end

local function outline(t, th)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = Theme.OUTLINE
	s.Thickness = th or 1.6
	s.Transparency = 0.1
	s.Parent = t
	return s
end
local function corner(f, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = f end

local cards = {}   -- prompt -> card

local function build(prompt, inputType)
	local accent = rarityOf(prompt) or Theme.ACCENT
	local bb = Instance.new("BillboardGui")
	bb.Name = "PromptCard"
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.ResetOnSpawn = false
	bb.Active = true
	bb.Size = UDim2.fromOffset(440, 70)
	bb.ClipsDescendants = false
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0)
	bb.Adornee = prompt.Parent
	bb.Parent = playerGui

	local scale = Instance.new("UIScale"); scale.Scale = 0.6; scale.Parent = bb
	local card = Instance.new("TextButton")
	card.Name = "Card"
	card.Text = ""
	card.AutoButtonColor = false
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3 = Theme.GLASS
	card.BackgroundTransparency = 0.12
	card.Size = UDim2.new(0, 0, 0, 58)
	card.AutomaticSize = Enum.AutomaticSize.X
	card.Parent = bb
	corner(card, 14)
	local edge = Instance.new("UIStroke"); edge.Color = Color3.new(1, 1, 1); edge.Thickness = 1.5; edge.Transparency = 0.82; edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; edge.Parent = card
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 16); pad.Parent = card
	-- (the row: the cap and the words side by side; the hold bar lies under it, on its own)
	local rowF = Instance.new("Frame")
	rowF.Name = "Row"
	rowF.BackgroundTransparency = 1
	rowF.Size = UDim2.fromOffset(0, 58)
	rowF.AutomaticSize = Enum.AutomaticSize.X
	rowF.Parent = card
	local row = Instance.new("UIListLayout"); row.FillDirection = Enum.FillDirection.Horizontal; row.VerticalAlignment = Enum.VerticalAlignment.Center; row.Padding = UDim.new(0, 12); row.Parent = rowF

	-- the key cap
	local cap = Instance.new("Frame")
	cap.Name = "Cap"
	cap.BackgroundColor3 = Color3.fromRGB(245, 247, 252)
	cap.Size = UDim2.fromOffset(42, 42)
	cap.LayoutOrder = 1
	cap.Parent = rowF
	corner(cap, 10)
	local capEdge = Instance.new("UIStroke"); capEdge.Color = accent; capEdge.Thickness = 2.5; capEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; capEdge.Parent = cap
	local g = Instance.new("UIGradient"); g.Rotation = 90; g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(196, 202, 216)); g.Parent = cap
	local key = Instance.new("TextLabel")
	key.BackgroundTransparency = 1
	key.Size = UDim2.fromScale(1, 1)
	key.Font = Theme.FONT_TITLE
	key.TextColor3 = Theme.INK
	key.TextScaled = true
	key.Text = keyText(prompt, inputType)
	key.Parent = cap
	local kp = Instance.new("UIPadding"); kp.PaddingTop = UDim.new(0, 7); kp.PaddingBottom = UDim.new(0, 7); kp.PaddingLeft = UDim.new(0, 5); kp.PaddingRight = UDim.new(0, 5); kp.Parent = key

	-- what it does, and what it is
	local words = Instance.new("Frame")
	words.BackgroundTransparency = 1
	words.Size = UDim2.fromOffset(0, 46)
	words.AutomaticSize = Enum.AutomaticSize.X
	words.LayoutOrder = 2
	words.Parent = rowF
	local action = Instance.new("TextLabel")
	action.BackgroundTransparency = 1
	action.Font = Theme.FONT_TITLE
	action.TextSize = 22
	action.TextColor3 = Theme.TEXT
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.Size = UDim2.fromOffset(0, 26)
	action.AutomaticSize = Enum.AutomaticSize.X
	action.Text = string.upper(prompt.ActionText)
	action.Parent = words
	outline(action, 2)
	local object = Instance.new("TextLabel")
	object.BackgroundTransparency = 1
	object.Font = Theme.FONT
	object.TextSize = 14
	object.TextColor3 = accent == Theme.ACCENT and Theme.DIM or accent
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.Position = UDim2.fromOffset(0, 26)
	object.Size = UDim2.fromOffset(0, 18)
	object.AutomaticSize = Enum.AutomaticSize.X
	object.Text = prompt.ObjectText
	object.Visible = prompt.ObjectText ~= ""
	object.Parent = words
	outline(object, 1.2)
	if prompt.ObjectText == "" then action.Position = UDim2.fromOffset(0, 10) end

	-- the hold, filling along the bottom
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundColor3 = Color3.new(0, 0, 0)
	track.BackgroundTransparency = 0.5
	track.AnchorPoint = Vector2.new(0, 1)
	track.Position = UDim2.new(0, 2, 1, -5)
	track.Size = UDim2.new(1, -4, 0, 4)
	track.Visible = prompt.HoldDuration > 0
	track.Parent = card
	corner(track, 2)
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = accent
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track
	corner(fill, 2)

	TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

	local c = {bb = bb, card = card, key = key, action = action, object = object, fill = fill, track = track, scale = scale, conns = {}}
	-- (the server or Movement.client may change its words or its key while it's up)
	table.insert(c.conns, prompt:GetPropertyChangedSignal("ActionText"):Connect(function() action.Text = string.upper(prompt.ActionText) end))
	table.insert(c.conns, prompt:GetPropertyChangedSignal("ObjectText"):Connect(function() object.Text = prompt.ObjectText; object.Visible = prompt.ObjectText ~= "" end))
	table.insert(c.conns, prompt:GetPropertyChangedSignal("KeyboardKeyCode"):Connect(function() key.Text = keyText(prompt, inputType) end))
	-- a tap, or a click, on the card
	table.insert(c.conns, card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldBegin()
		end
	end))
	table.insert(c.conns, card.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end))
	return c
end

local function drop(prompt)
	local c = cards[prompt]
	if not c then return end
	cards[prompt] = nil
	for _, cn in ipairs(c.conns) do cn:Disconnect() end
	local t = TweenService:Create(c.scale, TweenInfo.new(0.12), {Scale = 0.6})
	t:Play()
	task.delay(0.12, function() c.bb:Destroy() end)
end

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
	drop(prompt)
	-- (Movement.client sets the pickup key as it's shown: read it a frame later)
	task.defer(function()
		if not prompt.Parent then return end
		local c = build(prompt, inputType)
		cards[prompt] = c
		local hidden
		hidden = prompt.PromptHidden:Connect(function()
			hidden:Disconnect()
			drop(prompt)
		end)
		table.insert(c.conns, hidden)
	end)
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	local c = cards[prompt]
	if not c then return end
	c.fill.Size = UDim2.fromScale(0, 1)
	if prompt.HoldDuration > 0 then
		c.hold = TweenService:Create(c.fill, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(1, 1)})
		c.hold:Play()
	end
	TweenService:Create(c.scale, TweenInfo.new(0.08), {Scale = 0.96}):Play()
end)
ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
	local c = cards[prompt]
	if not c then return end
	if c.hold then c.hold:Cancel(); c.hold = nil end
	c.fill.Size = UDim2.fromScale(0, 1)
	TweenService:Create(c.scale, TweenInfo.new(0.1), {Scale = 1}):Play()
end)
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local c = cards[prompt]
	if not c then return end
	c.fill.Size = UDim2.fromScale(1, 1)
	c.scale.Scale = 1.12
	TweenService:Create(c.scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end)
