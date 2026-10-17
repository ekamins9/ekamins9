--[[ WHAT'S NEW — once per update, back in the Courtyard: a card of what's new since you last
     played (NEWS below: its `version` and its lines). Shown only to someone past the welcome and
     the menu tour (Tutorial ≥ 2, no intro or tour running), over the Hub menu; TO BATTLE! (or
     Escape, or a controller's B) puts it away, and the version you've seen is kept with your
     settings (ClientSettings ▸ SeenNews), so it never comes back for the same update.

     A new update: change NEWS.version and its lines. Nothing else. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local NEWS = {
	version = "2026-10-17b",
	title = "NEW IN THE DARK AND ON THE FIELD",
	lines = {
		{"🍂", "Amberwood", "a new War field: an autumn wood's edge, red and gold oaks, leaves drifting down"},
		{"🏰", "Stone, timber and sky", "castles of rough stone, half-timbered villages, clouds over every field"},
		{"💥", "Feel every blow", "a blast beside you leaves you deaf a moment; your armour scratches where blows land"},
		{"🕸", "The Silk Caverns", "a new dungeon of webs and nests, giant spiders, and their Queen"},
		{"🗡", "Through your own eyes", "in Settings, Start in: begin every fight in first person"},
		{"👻", "Banshees and gargoyles", "a scream that leaves you deaf; statues that wake as you pass"},
		{"📦", "Mimics", "in Deadvault not every chest is a chest; skeletons now fall apart into bones"},
	},
}

local player = Players.LocalPlayer
local round = ReplicatedStorage:WaitForChild("Round")
ClientSettings.load()

local function label(parent, text, size, font, color, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font or Theme.FONT
	l.TextSize = size
	l.TextColor3 = color or Theme.TEXT
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Text = text
	l.Parent = parent
	local st = Instance.new("UIStroke")
	st.Color = Theme.OUTLINE
	st.Thickness = 1.5
	st.Transparency = 0.2
	st.Parent = l
	return l
end

local shown = false
local function show()
	shown = true
	local gui = Instance.new("ScreenGui")
	gui.Name = "WhatsNew"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 2250
	gui.Parent = player:WaitForChild("PlayerGui")
	local veil = Instance.new("Frame")
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = Theme.BACK
	veil.BackgroundTransparency = 1
	veil.BorderSizePixel = 0
	veil.Parent = gui
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.52)
	card.Size = UDim2.new(0.9, 0, 0, 576)
	card.BackgroundColor3 = Theme.GLASS
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.Parent = gui
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
	local stroke = Instance.new("UIStroke", card); stroke.Color = Theme.ACCENT; stroke.Thickness = 2; stroke.Transparency = 0.35
	local size = Instance.new("UISizeConstraint", card); size.MaxSize = Vector2.new(640, 576)
	-- (a short screen, a phone on its side: the whole card scaled to fit)
	local vh = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 720
	local fit = math.min(1, (vh - 30) / 576)
	local scale = Instance.new("UIScale", card); scale.Scale = fit * 0.9
	local pad = Instance.new("UIPadding", card)
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 24), UDim.new(0, 24), UDim.new(0, 18), UDim.new(0, 18)

	local kicker = label(card, string.upper(GameConfig.GAME_NAME or "") .. "  ·  WHAT'S NEW", 15, Theme.FONT, Theme.ACCENT, Enum.TextXAlignment.Center)
	kicker.Size = UDim2.new(1, 0, 0, 20)
	local title = label(card, NEWS.title, 28, Theme.FONT_TITLE, Theme.TEXT, Enum.TextXAlignment.Center)
	title.Position = UDim2.fromOffset(0, 22)
	title.Size = UDim2.new(1, 0, 0, 36)
	title.TextScaled = true
	Instance.new("UITextSizeConstraint", title).MaxTextSize = 28

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(0, 70)
	list.Size = UDim2.new(1, 0, 1, -70 - 64)
	list.Parent = card
	local lay = Instance.new("UIListLayout", list)
	lay.Padding = UDim.new(0, 6)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	for i, ln in ipairs(NEWS.lines) do
		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 50)
		row.BackgroundColor3 = Theme.GLASS2
		row.BackgroundTransparency = 0.15
		row.BorderSizePixel = 0
		row.Parent = list
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
		local icon = label(row, ln[1], 24, Theme.FONT, Theme.TEXT, Enum.TextXAlignment.Center)
		icon.Size = UDim2.fromOffset(46, 50)
		local head = label(row, ln[2], 17, Theme.FONT, Theme.ACCENT)
		head.Position = UDim2.fromOffset(50, 5)
		head.Size = UDim2.new(1, -58, 0, 20)
		local sub = label(row, ln[3], 14, Theme.FONT_BODY, Theme.DIM)
		sub.Position = UDim2.fromOffset(50, 25)
		sub.Size = UDim2.new(1, -58, 0, 20)
		sub.TextTruncate = Enum.TextTruncate.AtEnd
		sub.TextWrapped = false
	end

	local go = Instance.new("TextButton")
	go.AnchorPoint = Vector2.new(0.5, 1)
	go.Position = UDim2.new(0.5, 0, 1, 0)
	go.Size = UDim2.fromOffset(260, 50)
	go.BackgroundColor3 = Theme.GREEN
	go.BorderSizePixel = 0
	go.AutoButtonColor = true
	go.Font = Theme.FONT_TITLE
	go.TextSize = 26
	go.TextColor3 = Theme.TEXT
	go.Text = "TO BATTLE!"
	go.Parent = card
	Instance.new("UICorner", go).CornerRadius = UDim.new(0, 12)
	local gs = Instance.new("UIStroke", go); gs.Color = Theme.OUTLINE; gs.Thickness = 2; gs.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	TweenService:Create(veil, TweenInfo.new(0.3), {BackgroundTransparency = 0.45}):Play()
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = fit}):Play()

	local closed = false
	local conn, modeConn
	local function close(seen)
		if closed then return end
		closed = true
		if conn then conn:Disconnect() end
		if modeConn then modeConn:Disconnect() end
		if seen ~= false then ClientSettings.set("SeenNews", NEWS.version) else shown = false end
		TweenService:Create(veil, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
		TweenService:Create(scale, TweenInfo.new(0.2), {Scale = fit * 0.85}):Play()
		task.delay(0.25, function() gui:Destroy() end)
	end
	go.Activated:Connect(function() close() end)
	conn = UIS.InputBegan:Connect(function(input, typed)
		-- (Enter only when it isn't a chat message being sent)
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB or (input.KeyCode == Enum.KeyCode.Return and not typed) then close() end
	end)
	-- (off to a match before reading it: put away, not marked seen, for next time in the Courtyard)
	modeConn = round:GetAttributeChangedSignal("Mode"):Connect(function()
		if round:GetAttribute("Mode") ~= "Hub" then close(false) end
	end)
end

-- (when: in the Courtyard, past the welcome and the tour, with nothing else running)
task.spawn(function()
	task.wait(4)
	while true do
		local ok = round:GetAttribute("Mode") == "Hub" and (player:GetAttribute("Tutorial") or 0) >= 2
			and player:GetAttribute("MenuTour") ~= false and not _G.IntroActive and not _G.TourActive and not _G.CinematicUp
		if ok and not shown then
			if ClientSettings.get("SeenNews") == NEWS.version then return end
			task.wait(1.5)
			if round:GetAttribute("Mode") == "Hub" and not (_G.IntroActive or _G.TourActive) then show() end
		end
		task.wait(1)
	end
end)
