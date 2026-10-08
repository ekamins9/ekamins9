--[[ MENU TOUR — back in the Courtyard after a newcomer's first battle (Tutorial 2,
     the tour not offered yet: player attribute MenuTour false):
       • WELCOME TO THE COURTYARD: a card over the menu. SHOW ME AROUND (the
         tour) or I'LL EXPLORE MYSELF.
       • THE TOUR: a spotlight on one part of the menu at a time (HubMenu names
         them: Play, Dock_*, Wallet, LobbyLeft), a line about each, NEXT (Enter /
         Space) · BACK · SKIP TOUR. It ends on the menu key and Settings (every
         key can be rebound there).
       • THE RECRUIT'S GIFT (Catalog ▸ Economy ▸ starterGift, once, either way):
         HubServer "TourDone" pays it; OPEN A CRATE goes straight to the crates
         (the gift has a Key in it).
     While it runs it holds the menu's M key and its daily pop-up (HubMenu:
     _G.IntroActive / _G.TourActive).
     Studio test: the player attribute TourAutoplay = true clicks through it. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local round = ReplicatedStorage:WaitForChild("Round")
local hubRemote = ReplicatedStorage:WaitForChild("HubRemote")

local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 206, 90)

local function menuKey() return "M" end   -- (the menu key is fixed: Escape is Roblox's)

-- the stops: what to light up (by name inside the HubMenu), what to say
local STEPS = {
	{target = "Play", title = "PLAY",
		text = "Your way into a fight. The Warfront's battles never stop, the Lists are duels (ranked too), and the Training Yard is always open."},
	{target = "Dock_LOADOUT", title = "LOADOUT",
		text = "Four classes: Knight, Footman, Vanguard and Archer. Pick each one's weapons and armor: heavier armor takes more hits, lighter armor moves faster."},
	{target = "Dock_ARMORY", title = "ARMORY",
		text = "Every weapon skin, kill effect and emote you own. Skins change how a weapon looks, never how it fights."},
	{target = "Dock_SHOP", title = "SHOP",
		text = "A new daily shop every day, and the crates: Keys or Crowns open them, and the rarest skins only come out of crates."},
	{target = "Dock_TASKS", title = "TASKS",
		text = "Daily and weekly tasks pay Marks, XP and Keys. The Season Pass next to them levels up as you play."},
	{target = "Dock_TRADE", title = "TRADE",
		text = "Swap skins with other players. A rare pull is worth a lot to someone."},
	{target = "Wallet", title = "YOUR WALLET",
		text = "Marks: earned by fighting. Crowns: for premium things. Keys (earned too) open crates."},
	{target = "LobbyLeft", title = "TASKS & FRIENDS",
		text = "Today's tasks, and your friends who are online: invite them to a party and you fight on the same team."},
	{target = "Dock_SETTINGS", title = "SETTINGS",
		text = "Rebind every key (all the controls you learned), mouse sensitivity, the camera, sound, and privacy: who can invite you or ask to trade."},
	{target = nil, title = "THAT'S THE MENU",
		text = function() return string.format("%s opens it anywhere, even in the middle of a battle. One more thing before you go…", menuKey()) end},
}

--------------------------------------------------------------------
--  LOOK
--------------------------------------------------------------------
local function label(parent, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font or Theme.FONT_TITLE
	l.TextSize = size
	l.TextColor3 = color or WHITE
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text or ""
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Color = Theme.OUTLINE
	s.Thickness = size >= 24 and 2.4 or 1.4
	s.Parent = l
	return l
end
local function button(parent, text, color, textSize)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = color
	b.Font = Theme.FONT_TITLE
	b.TextSize = textSize or 18
	b.TextColor3 = WHITE
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = Theme.OUTLINE
	s.Thickness = 2
	s.Parent = b
	local g = Instance.new("UIGradient", b)
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205))
	return b
end
local function panel(parent)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Theme.GLASS
	f.BackgroundTransparency = 0.04
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 18)
	local s = Instance.new("UIStroke", f)
	s.Color = GOLD
	s.Transparency = 0.35
	s.Thickness = 2
	return f
end
-- (Studio: a test can let it play itself)
local function autoplay() return RunService:IsStudio() and player:GetAttribute("TourAutoplay") == true end
local function click()
	pcall(function() require(ReplicatedStorage:WaitForChild("UIFX")).play("Click") end)
end

--------------------------------------------------------------------
--  THE TOUR
--------------------------------------------------------------------
local function run()
	_G.IntroActive, _G.TourActive = true, true
	local gui = Instance.new("ScreenGui")
	gui.Name = "MenuTour"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2300
	gui.Parent = playerGui

	-- the shade, in four pieces round a hole (all of it swallows clicks)
	local shades = {}
	for i = 1, 4 do
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.fromRGB(2, 4, 10)
		f.BackgroundTransparency = 0.38
		f.BorderSizePixel = 0
		f.Active = true
		f.Parent = gui
		shades[i] = f
	end
	local hole = Instance.new("Frame")
	hole.BackgroundTransparency = 1
	hole.Active = true
	hole.Parent = gui
	Instance.new("UICorner", hole).CornerRadius = UDim.new(0, 16)
	local ring = Instance.new("UIStroke", hole)
	ring.Color = GOLD
	ring.Thickness = 4
	local arrow = label(gui, "▼", 34, GOLD)
	arrow.TextXAlignment = Enum.TextXAlignment.Center
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(40, 40)

	local card = panel(gui)
	card.Size = UDim2.fromOffset(430, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.ZIndex = 5
	do
		local p = Instance.new("UIPadding", card)
		p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = UDim.new(0, 16), UDim.new(0, 16), UDim.new(0, 20), UDim.new(0, 20)
		local l = Instance.new("UIListLayout", card)
		l.Padding = UDim.new(0, 8)
		l.SortOrder = Enum.SortOrder.LayoutOrder
	end
	local cardScale = Instance.new("UIScale", card)
	local counter = label(card, "", 13, GOLD, Theme.FONT); counter.Size = UDim2.new(1, 0, 0, 16); counter.LayoutOrder = 1
	local head = label(card, "", 30); head.Size = UDim2.new(1, 0, 0, 34); head.LayoutOrder = 2
	local body = label(card, "", 16, WHITE, Theme.FONT_BODY); body.Size = UDim2.new(1, 0, 0, 0); body.AutomaticSize = Enum.AutomaticSize.Y; body.LayoutOrder = 3
	body:FindFirstChildOfClass("UIStroke").Transparency = 0.5
	local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.Size = UDim2.new(1, 0, 0, 46); row.LayoutOrder = 4; row.Parent = card
	local backB = button(row, "‹", Theme.GLASS2, 24); backB.Size = UDim2.fromOffset(52, 46)
	local nextB = button(row, "NEXT  ›", Theme.GREEN, 20); nextB.AnchorPoint = Vector2.new(1, 0); nextB.Position = UDim2.new(1, 0, 0, 0); nextB.Size = UDim2.fromOffset(180, 46)
	local skipB = Instance.new("TextButton")
	skipB.BackgroundTransparency = 1; skipB.Font = Theme.FONT; skipB.TextSize = 13; skipB.TextColor3 = Theme.DIM; skipB.Text = "SKIP TOUR"
	skipB.Position = UDim2.fromOffset(62, 0); skipB.Size = UDim2.fromOffset(110, 46); skipB.Parent = row

	local hubGui = playerGui:FindFirstChild("HubMenu")
	local i = 1
	local finished = false
	local function targetOf(step)
		if not (step.target and hubGui) then return nil end
		local t = hubGui:FindFirstChild(step.target, true)
		if t and t:IsA("GuiObject") and t.Visible and t.AbsoluteSize.X > 4 then return t end
		return nil
	end
	local function show()
		local step = STEPS[i]
		counter.Text = string.format("THE MENU  ·  %d / %d", i, #STEPS)
		head.Text = step.title
		body.Text = type(step.text) == "function" and step.text() or step.text
		backB.Visible = i > 1
		nextB.Text = i < #STEPS and "NEXT  ›" or "FINISH  ›"
		cardScale.Scale = 0.9
		TweenService:Create(cardScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = 1}):Play()
	end

	-- every frame: the hole over the target, the card beside it (the menu scales with the screen)
	local hp, hs = Vector2.new(), Vector2.new()
	local conn = RunService.RenderStepped:Connect(function(dt)
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		local screen = gui.AbsoluteSize
		local t = targetOf(STEPS[i])
		local wantP, wantS
		if t then
			-- (AbsolutePosition is measured below Roblox's top bar; this screen starts above it)
			wantP, wantS = t.AbsolutePosition - gui.AbsolutePosition - Vector2.new(10, 10), t.AbsoluteSize + Vector2.new(20, 20)
		else
			wantP, wantS = screen / 2, Vector2.new(0, 0)
		end
		local a = math.clamp(dt * 12, 0, 1)
		hp, hs = hp:Lerp(wantP, a), hs:Lerp(wantS, a)
		local x0, y0, x1, y1 = hp.X, hp.Y, hp.X + hs.X, hp.Y + hs.Y
		shades[1].Position, shades[1].Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(screen.X, math.max(y0, 0))
		shades[2].Position, shades[2].Size = UDim2.fromOffset(0, y1), UDim2.fromOffset(screen.X, math.max(screen.Y - y1, 0))
		shades[3].Position, shades[3].Size = UDim2.fromOffset(0, y0), UDim2.fromOffset(math.max(x0, 0), math.max(hs.Y, 0))
		shades[4].Position, shades[4].Size = UDim2.fromOffset(x1, y0), UDim2.fromOffset(math.max(screen.X - x1, 0), math.max(hs.Y, 0))
		hole.Visible = t ~= nil
		hole.Position, hole.Size = UDim2.fromOffset(x0, y0), UDim2.fromOffset(hs.X, hs.Y)
		ring.Transparency = 0.15 + 0.25 * math.sin(os.clock() * 5)
		-- the card: above the target if there's room, else below; centred without one
		local cs = card.AbsoluteSize
		local cx, cy
		if t then
			cx = math.clamp(x0 + hs.X / 2 - cs.X / 2, 16, screen.X - cs.X - 16)
			if y0 - cs.Y - 46 > 10 then cy = y0 - cs.Y - 46; arrow.Text = "▼"; arrow.Position = UDim2.fromOffset(x0 + hs.X / 2, y0 - 22)
			else cy = math.min(y1 + 46, screen.Y - cs.Y - 10); arrow.Text = "▲"; arrow.Position = UDim2.fromOffset(x0 + hs.X / 2, y1 + 22) end
			arrow.Visible = true
			arrow.Position = arrow.Position + UDim2.fromOffset(0, math.sin(os.clock() * 6) * 4)
		else
			cx, cy = screen.X / 2 - cs.X / 2, screen.Y / 2 - cs.Y / 2
			arrow.Visible = false
		end
		card.Position = UDim2.fromOffset(cx, cy)
	end)

	local function finish()
		if finished then return end
		finished = true
		conn:Disconnect()
		gui:Destroy()
	end

	-- the steps
	local doneTour = Instance.new("BindableEvent")
	local function go(d)
		click()
		local n = i + d
		if n < 1 then return end
		if n > #STEPS then doneTour:Fire(); return end
		i = n
		show()
	end
	nextB.Activated:Connect(function() go(1) end)
	backB.Activated:Connect(function() go(-1) end)
	skipB.Activated:Connect(function() doneTour:Fire() end)
	local keyConn = UserInputService.InputBegan:Connect(function(input)
		if finished then return end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Right then go(1)
		elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Backspace then go(-1) end
	end)
	if _G.HubMenuGo then _G.HubMenuGo("PLAY") end
	show()
	if autoplay() then task.spawn(function() while not finished do task.wait(2.5); if not finished then go(1) end end end) end
	doneTour.Event:Wait()
	keyConn:Disconnect()
	finish()
end

-- a centred card on a shade: kicker, title, body, buttons {{text, color, fn}}
local function bigCard(kicker, titleText, bodyText, buttons, extra)
	local gui = Instance.new("ScreenGui")
	gui.Name = "MenuTourCard"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2300
	gui.Parent = playerGui
	local shade = Instance.new("Frame")
	shade.BackgroundColor3 = Color3.fromRGB(2, 4, 10); shade.BackgroundTransparency = 0.35; shade.BorderSizePixel = 0
	shade.Size = UDim2.fromScale(1, 1); shade.Active = true; shade.Parent = gui
	local card = panel(gui)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(560, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	do
		local p = Instance.new("UIPadding", card)
		p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = UDim.new(0, 22), UDim.new(0, 22), UDim.new(0, 26), UDim.new(0, 26)
		local l = Instance.new("UIListLayout", card)
		l.Padding = UDim.new(0, 10)
		l.SortOrder = Enum.SortOrder.LayoutOrder
	end
	local sc = Instance.new("UIScale", card)
	local function fit()
		local abs = gui.AbsoluteSize
		if abs.X > 2 then sc.Scale = math.clamp(math.min(abs.X / 640, abs.Y / 560), 0.5, 1.25) end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	local k = label(card, kicker, 14, GOLD, Theme.FONT); k.Size = UDim2.new(1, 0, 0, 16); k.LayoutOrder = 1
	local t = label(card, titleText, 38); t.Size = UDim2.new(1, 0, 0, 44); t.LayoutOrder = 2
	local b = label(card, bodyText, 17, Theme.DIM, Theme.FONT_BODY); b.Size = UDim2.new(1, 0, 0, 0); b.AutomaticSize = Enum.AutomaticSize.Y; b.LayoutOrder = 3
	b:FindFirstChildOfClass("UIStroke").Transparency = 0.6
	if extra then extra(card) end
	local chosen = Instance.new("BindableEvent")
	for n, bt in ipairs(buttons) do
		local btn = button(card, bt[1], bt[2], n == 1 and 24 or 18)
		btn.Size = UDim2.new(1, 0, 0, n == 1 and 62 or 46)
		btn.LayoutOrder = 10 + n
		btn.Activated:Connect(function() click(); chosen:Fire(n) end)
	end
	sc.Scale = sc.Scale * 0.9
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = sc.Scale / 0.9}):Play()
	local mouse = RunService.RenderStepped:Connect(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)
	local keyConn = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Return then chosen:Fire(1) end
	end)
	if autoplay() then task.delay(2, function() chosen:Fire(1) end) end
	local n = chosen.Event:Wait()
	keyConn:Disconnect()
	mouse:Disconnect()
	gui:Destroy()
	return n
end

--------------------------------------------------------------------
--  WHEN: in the Courtyard, through the first battle, not toured yet
--------------------------------------------------------------------
local function due()
	return round:GetAttribute("Mode") == "Hub" and (player:GetAttribute("Tutorial") or 0) >= 2 and player:GetAttribute("MenuTour") == false
end
local running = false
local function maybe()
	if running or not due() then return end
	running = true
	local t0 = os.clock()
	while (player:GetAttribute("MenuTour") == nil or (round:GetAttribute("Mode") or "") == "") and os.clock() - t0 < 15 do task.wait(0.2) end
	if not due() then running = false; return end
	-- the travel screen gone and the menu up
	t0 = os.clock()
	while os.clock() - t0 < 25 do
		local travel = playerGui:FindFirstChild("TravelScreen")
		if not (travel and travel.Enabled) and _G.HubMenuOpen and _G.HubMenuOpen() then break end
		task.wait(0.25)
	end
	task.wait(1)
	if not due() then running = false; return end
	if _G.HubMenuGo then _G.HubMenuGo("PLAY") end
	_G.IntroActive, _G.TourActive = true, true

	local choice = bigCard("BACK FROM THE FRONT", "WELCOME TO THE COURTYARD",
		"This is home between battles: change your class, gear up, open crates, trade, and team up with friends. Want a quick look around the menu? It takes half a minute, and a recruit's gift waits at the end.",
		{{"SHOW ME AROUND", Theme.GREEN}, {"I'LL EXPLORE MYSELF", Theme.GLASS2}})
	if choice == 1 then run() end

	-- the gift (once; the server decides)
	local ok, r = pcall(function() return hubRemote:InvokeServer("TourDone") end)
	_G.IntroActive, _G.TourActive = nil, nil
	if ok and type(r) == "table" and r.ok and r.gift and r.gift ~= "" then
		local SND = Instance.new("Sound")
		SND.SoundId = "rbxassetid://1840296036"   -- a brass flourish (APM)
		local v = ClientSettings.get("UISounds"); SND.Volume = 0.6 * (type(v) == "number" and v or 1)
		SND.Parent = SoundService
		SND:Play()
		task.delay(5, function() SND:Destroy() end)
		local pick = bigCard("FOR A NEW RECRUIT", "A GIFT FOR YOU", "Welcome to the fight, soldier. Keys open crates: open your first one now and see what you pull.",
			{{"OPEN A CRATE  ›", Theme.GOLD}, {"LATER", Theme.GLASS2}},
			function(card)
				local g = label(card, string.upper(r.gift), 24, GOLD)
				g.TextXAlignment = Enum.TextXAlignment.Center
				g.Size = UDim2.new(1, 0, 0, 40)
				g.LayoutOrder = 4
			end)
		if pick == 1 and _G.HubMenuGo then _G.HubMenuGo("SHOP", "crates") else if _G.HubMenuGo then _G.HubMenuGo("PLAY") end end
	else
		if _G.HubMenuGo then _G.HubMenuGo("PLAY") end
	end
	running = false
end
-- (again whenever the mode changes: Studio switches in place)
task.spawn(maybe)
round:GetAttributeChangedSignal("Mode"):Connect(function() task.delay(0.5, maybe) end)
player:GetAttributeChangedSignal("MenuTour"):Connect(function() task.delay(0.5, maybe) end)
