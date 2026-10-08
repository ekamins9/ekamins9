--[[ INTRO — a newcomer's first minutes (profile tutorial ▸ player attribute Tutorial).

     THE WELCOME (the Courtyard, Tutorial 0, every visit until they answer):
       • a short cinematic over the Courtyard: letterbox bars, the map's own
         camera shots (Map ▸ MenuCameras) as slow dollies with a line each, then
         the game's name (GameConfig.GAME_NAME) with a horn and a boom. Any key,
         click or tap skips it.
       • the card: WELCOME, SOLDIER! · BEGIN TRAINING (recommended; Enter) or
         SKIP TO BATTLE, which asks "are you sure?" first. The answer goes to
         HubServer ("Intro"): training is a Tiltyard of their own, battle a
         Warfront match (Team Deathmatch, Free-for-All or King of the Hill).
       While it runs it holds the menu (HubMenu: _G.IntroActive), the menu's
       camera (_G.IntroCamera) and the score (Music: _G.IntroMusic).

     THE FIRST BATTLE (Tutorial 1, in a match): a briefing card as they arrive,
       then a few tips, each once, as things happen: the first wound (block,
       parry), running out of breath, the first kill, the first fall.

     Back in the Courtyard after that first battle: MenuTour. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local round = ReplicatedStorage:WaitForChild("Round")
local hubRemote = ReplicatedStorage:WaitForChild("HubRemote")

local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 206, 90)

-- the intro owns the menu until it knows this isn't a newcomer (no menu flashing up first)
_G.IntroActive = true

--------------------------------------------------------------------
--  SOUND (Roblox's licensed libraries: Pro Sound Effects, APM Music)
--------------------------------------------------------------------
local SND = {
	horn   = {id = 9114821239, vol = 0.45, speed = 0.78},   -- a ram's horn, pitched down to a war horn
	boom   = {id = 1835337001, vol = 0.7},                   -- a low boom under the title
	draw   = {id = 9119742466, vol = 0.55},                  -- a blade drawn
	whoosh = {id = 9114157391, vol = 0.3, speed = 0.85},     -- a cut between shots
	hit    = {id = 9046338796, vol = 0.45},                  -- a card lands
	kill   = {id = 1835324771, vol = 0.5},                   -- the first kill
}
local function sfx(name, cut)
	local d = SND[name]
	if not d then return end
	local v = ClientSettings.get("UISounds")
	v = type(v) == "number" and v or 1
	if v <= 0.01 then return end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(d.id)
	s.Volume = d.vol * v
	s.PlaybackSpeed = d.speed or 1
	s.Parent = SoundService
	s:Play()
	task.delay(cut or 8, function()
		if s.Parent then
			TweenService:Create(s, TweenInfo.new(0.4), {Volume = 0}):Play()
			task.delay(0.45, function() s:Destroy() end)
		end
	end)
end

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
	l.Text = text or ""
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Color = Theme.OUTLINE
	s.Thickness = size >= 30 and 3 or (size >= 18 and 2 or 1.4)
	s.Parent = l
	return l
end
local function hoverScale(b)
	local sc = Instance.new("UIScale", b)
	b.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.1), {Scale = 1.03}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.1), {Scale = 1}):Play() end)
end
local function button(parent, text, color, textSize)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = color
	b.Font = Theme.FONT_TITLE
	b.TextSize = textSize or 22
	b.TextColor3 = WHITE
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 14)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = Theme.OUTLINE
	s.Thickness = 2
	s.Parent = b
	local g = Instance.new("UIGradient", b)
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205))
	hoverScale(b)
	return b
end
local function panel(parent)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Theme.GLASS
	f.BackgroundTransparency = 0.08
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 22)
	local s = Instance.new("UIStroke", f)
	s.Color = WHITE
	s.Transparency = 0.8
	s.Thickness = 1.5
	return f
end
-- a pixel layout that grows / shrinks with the screen
local function fitScale(gui, frame, w, h)
	local sc = Instance.new("UIScale", frame)
	local function fit()
		local abs = gui.AbsoluteSize
		if abs.X < 2 then return end
		sc.Scale = math.clamp(math.min(abs.X / (w + 60), abs.Y * 0.8 / h), 0.45, 1.25)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	task.defer(fit)
	return sc
end

--------------------------------------------------------------------
--  THE WELCOME
--------------------------------------------------------------------
local function welcome()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Intro"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 4000
	gui.Parent = playerGui

	local cover = Instance.new("Frame")
	cover.BackgroundColor3 = Color3.new(0, 0, 0)
	cover.BorderSizePixel = 0
	cover.Size = UDim2.fromScale(1, 1)
	cover.ZIndex = 50
	cover.Parent = gui
	local bars = {}
	for i, y in ipairs({0, 1}) do
		local b = Instance.new("Frame")
		b.BackgroundColor3 = Color3.new(0, 0, 0)
		b.BorderSizePixel = 0
		b.AnchorPoint = Vector2.new(0, y)
		b.Position = UDim2.fromScale(0, y)
		b.Size = UDim2.fromScale(1, 0.11)
		b.ZIndex = 40
		b.Parent = gui
		bars[i] = b
	end
	local caption = label(gui, "", 40)
	caption.AnchorPoint = Vector2.new(0.5, 0.5)
	caption.Position = UDim2.fromScale(0.5, 0.8)
	caption.Size = UDim2.new(0.9, 0, 0, 50)
	caption.TextTransparency = 1
	caption.ZIndex = 45
	local captionStroke = caption:FindFirstChildOfClass("UIStroke")
	local titleBig = label(gui, string.upper(GameConfig.GAME_NAME or ""), 96, GOLD)
	titleBig.AnchorPoint = Vector2.new(0.5, 0.5)
	titleBig.Position = UDim2.fromScale(0.5, 0.44)
	titleBig.Size = UDim2.new(0.95, 0, 0, 110)
	titleBig.TextTransparency = 1
	titleBig.ZIndex = 45
	local titleScale = Instance.new("UIScale", titleBig)
	local titleStroke = titleBig:FindFirstChildOfClass("UIStroke")
	titleStroke.Thickness = 5
	local tagline = label(gui, string.upper(GameConfig.TAGLINE or ""), 22, WHITE, Theme.FONT)
	tagline.AnchorPoint = Vector2.new(0.5, 0.5)
	tagline.Position = UDim2.fromScale(0.5, 0.56)
	tagline.Size = UDim2.new(0.9, 0, 0, 30)
	tagline.TextTransparency = 1
	tagline.ZIndex = 45
	local skipHint = label(gui, InputHints.mode() == "Touch" and "TAP TO SKIP" or (InputHints.mode() == "Gamepad" and "PRESS ANY BUTTON TO SKIP" or "PRESS ANY KEY TO SKIP"), 14, Theme.DIM, Theme.FONT)
	skipHint.AnchorPoint = Vector2.new(1, 1)
	skipHint.Position = UDim2.new(1, -24, 1, -18)
	skipHint.Size = UDim2.fromOffset(300, 18)
	skipHint.TextXAlignment = Enum.TextXAlignment.Right
	skipHint.ZIndex = 60
	for _, o in ipairs({caption, titleBig, tagline}) do o:FindFirstChildOfClass("UIStroke").Transparency = 1 end

	local blur = Instance.new("BlurEffect")
	blur.Name = "IntroBlur"
	blur.Size = 0
	blur.Parent = Lighting

	-- THE CAMERA: a function of time while the intro has it
	_G.IntroCamera = true
	_G.IntroMusic = true
	local camFn
	local function ease(t) return t * t * (3 - 2 * t) end
	RunService:BindToRenderStep("IntroCam", Enum.RenderPriority.Camera.Value + 5, function()
		if not camFn then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = camFn(os.clock())
		cam.FieldOfView = 50
	end)
	-- the map's shots (MapLoader puts them on the Map as attributes: with no body
	-- yet, its parts haven't streamed in), or three round its middle
	local map = workspace:WaitForChild("Map", 10)
	local centre = map and map:GetAttribute("Centre") or Vector3.new(0, 6, 0)
	local radius = math.clamp(map and map:GetAttribute("Radius") or 70, 30, 160)
	local height = 20
	local shots = {}
	for i = 1, 6 do
		local cf = map and map:GetAttribute("Shot" .. i)
		if typeof(cf) == "CFrame" then table.insert(shots, cf) end
	end
	while #shots < 3 do
		local a = #shots * 2.1
		table.insert(shots, CFrame.lookAt(centre + Vector3.new(math.cos(a) * radius * 0.6, height + 12, math.sin(a) * radius * 0.6), centre))
	end
	-- the world streams in around them first (behind the black)
	do
		local pending = 0
		local spots = {centre}
		for _, cf in ipairs(shots) do table.insert(spots, cf.Position + cf.LookVector * 40) end
		for _, pos in ipairs(spots) do
			pending += 1
			task.spawn(function()
				pcall(function() player:RequestStreamAroundAsync(pos, 3) end)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 3.5 do task.wait(0.1) end
	end
	local function dolly(cf, t0, dur, side)
		return function(now)
			local t = ease(math.clamp((now - t0) / dur, 0, 1))
			local a = cf * CFrame.new(-5 * side, 1.5, 9) * CFrame.Angles(0, math.rad(-3 * side), 0)
			local b = cf * CFrame.new(5 * side, -0.5, -7) * CFrame.Angles(0, math.rad(3 * side), 0)
			return a:Lerp(b, t)
		end
	end
	-- behind the title and the card: the wide shot, drifting slowly
	local function orbit(t0)
		local cf = shots[2] or shots[1]
		return function(now)
			local t = (now - t0) * 0.04
			return cf * CFrame.new(math.sin(t) * 6, math.sin(t * 0.7) * 1.5, -math.min(now - t0, 40) * 0.25) * CFrame.Angles(0, math.sin(t * 0.8) * 0.05, 0)
		end
	end

	-- the screen is the intro's: the HUD bits step aside until it's over
	local hidden = {}
	for _, name in ipairs({"Pastimes", "AdminPanel", "HubToasts", "EmoteHint", "Scoreboard", "Objectives"}) do
		local g = playerGui:FindFirstChild(name)
		if g and g:IsA("ScreenGui") and g.Enabled then g.Enabled = false; table.insert(hidden, g) end
	end

	-- the mouse is free while the card is up
	local mouseConn = RunService.RenderStepped:Connect(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)

	local done = false
	local function cleanup()
		if done then return end
		done = true
		pcall(function() RunService:UnbindFromRenderStep("IntroCam") end)
		if mouseConn then mouseConn:Disconnect() end
		blur:Destroy()
		gui:Destroy()
		for _, g in ipairs(hidden) do if g.Parent then g.Enabled = true end end
		_G.IntroCamera, _G.IntroMusic, _G.IntroActive = nil, nil, nil
		local cam = workspace.CurrentCamera
		if cam then cam.CameraType = Enum.CameraType.Custom; cam.FieldOfView = 70 end
	end

	-- THE CINEMATIC (skippable)
	local skipped = false
	local function hold(secs)
		local t0 = os.clock()
		while os.clock() - t0 < secs do
			if skipped then return false end
			RunService.RenderStepped:Wait()
		end
		return true
	end
	local function fadeText(o, to, secs)
		TweenService:Create(o, TweenInfo.new(secs), {TextTransparency = to}):Play()
		local st = o:FindFirstChildOfClass("UIStroke")
		if st then TweenService:Create(st, TweenInfo.new(secs), {Transparency = to}):Play() end
	end
	local skipConn = UserInputService.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or t == Enum.UserInputType.Gamepad1 then
			skipped = true
		end
	end)
	task.spawn(function() pcall(function() hubRemote:InvokeServer("Intro", "Shown") end) end)

	local LINES = {"THE REALM IS AT WAR.", "EVERY SWING IS YOURS TO AIM.", "BLOCK.  PARRY.  FEINT.  STRIKE."}
	local function cinematic()
		sfx("horn", 6)
		for i = 1, 3 do
			local dur = 3.1
			camFn = dolly(shots[i], os.clock(), dur + 0.4, i % 2 == 0 and -1 or 1)
			if i == 1 then
				TweenService:Create(cover, TweenInfo.new(1.4), {BackgroundTransparency = 1}):Play()
			else
				sfx("whoosh", 2)
				cover.BackgroundTransparency = 0.15
				TweenService:Create(cover, TweenInfo.new(0.45), {BackgroundTransparency = 1}):Play()
			end
			caption.Text = LINES[i]
			if not hold(0.35) then return end
			fadeText(caption, 0, 0.45)
			if not hold(dur - 0.9) then return end
			fadeText(caption, 1, 0.35)
			if not hold(0.4) then return end
			if i < 3 then
				TweenService:Create(cover, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
				if not hold(0.2) then return end
			end
		end
		-- the name
		camFn = orbit(os.clock())
		TweenService:Create(blur, TweenInfo.new(0.6), {Size = 10}):Play()
		sfx("boom", 5); sfx("draw", 3)
		titleScale.Scale = 1.5
		TweenService:Create(titleScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Scale = 1}):Play()
		fadeText(titleBig, 0, 0.3)
		if not hold(0.5) then return end
		fadeText(tagline, 0, 0.6)
		if not hold(2.2) then return end
		fadeText(titleBig, 1, 0.4); fadeText(tagline, 1, 0.4)
		hold(0.4)
	end
	cinematic()
	skipConn:Disconnect()
	-- (skipped or over: straight to the card)
	skipHint.Visible = false
	caption.Visible, titleBig.Visible, tagline.Visible = false, false, false
	if not camFn or skipped then camFn = orbit(os.clock()) end
	TweenService:Create(cover, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
	TweenService:Create(blur, TweenInfo.new(0.6), {Size = 10}):Play()

	-- THE CARD (the bars ease back to give it room)
	for _, b in ipairs(bars) do TweenService:Create(b, TweenInfo.new(0.5), {Size = UDim2.fromScale(1, 0.06)}):Play() end
	local W, H = 640, 440
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(W, H)
	holder.Parent = gui
	fitScale(gui, holder, W, H)
	local card = panel(holder)
	card.Size = UDim2.fromScale(1, 1)
	local pop = Instance.new("UIScale", card)
	pop.Scale = 0.85
	TweenService:Create(pop, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
	sfx("hit", 2)

	local content = Instance.new("Frame")
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.Parent = card
	local busy = false
	local primaryFn

	local function clearContent() for _, c in ipairs(content:GetChildren()) do c:Destroy() end end
	local function header(kicker, big, body)
		local k = label(content, kicker, 15, GOLD, Theme.FONT)
		k.Position = UDim2.fromOffset(30, 26); k.Size = UDim2.new(1, -60, 0, 18)
		local t = label(content, big, 46)
		t.Position = UDim2.fromOffset(30, 46); t.Size = UDim2.new(1, -60, 0, 56)
		local b = label(content, body, 18, Theme.DIM, Theme.FONT_BODY)
		b.Position = UDim2.fromOffset(34, 110); b.Size = UDim2.new(1, -68, 0, 120)
		b.TextYAlignment = Enum.TextYAlignment.Top
		b:FindFirstChildOfClass("UIStroke").Transparency = 0.6
		return b
	end
	local status
	local function setStatus(text, color)
		if status then status.Text = text; status.TextColor3 = color or Theme.DIM end
	end

	local showWelcome, showSure
	local function choose(what)
		if busy then return end
		busy = true
		setStatus(what == "Battle" and "Heading to the front…" or "Off to the Training Yard…", GOLD)
		if _G.ShowTravel then
			_G.ShowTravel(what == "Battle" and "TO BATTLE" or "BASIC TRAINING", what == "Battle" and "YOUR FIRST BATTLE" or "THE TRAINING YARD")
		end
		local ok, r = pcall(function() return hubRemote:InvokeServer("Intro", what) end)
		if not (ok and type(r) == "table" and r.ok) then
			if _G.HideTravel then _G.HideTravel() end
			busy = false
			setStatus("Couldn't head out: " .. tostring(ok and type(r) == "table" and r.msg or "no answer") .. ". Try again.", Theme.BAD)
			return
		end
		-- (the trip is on: a teleport takes it from here; in Studio the mode switches under us)
	end

	showWelcome = function()
		clearContent()
		header(string.upper(GameConfig.GAME_NAME or ""), "WELCOME, SOLDIER!",
			"You've reached the Courtyard, the last safe ground before the front. Out there, skill decides everything: you aim every swing with your mouse, and a well-timed block, parry or feint wins the day.")
		local go = button(content, "BEGIN TRAINING  ›", Theme.GREEN, 32)
		go.Position = UDim2.fromOffset(30, 220); go.Size = UDim2.new(1, -60, 0, 84)
		go.TextYAlignment = Enum.TextYAlignment.Top
		local pad = Instance.new("UIPadding", go); pad.PaddingTop = UDim.new(0, 12)
		local sub = label(go, "ABOUT 2 MINUTES  ·  PAYS MARKS  ·  RECOMMENDED", 13, WHITE, Theme.FONT)
		sub.AnchorPoint = Vector2.new(0.5, 1); sub.Position = UDim2.new(0.5, 0, 1, -2); sub.Size = UDim2.new(1, 0, 0, 16)
		go.Activated:Connect(function() choose("Train") end)
		local skip = button(content, "SKIP TO BATTLE", Theme.GLASS2, 20)
		skip.Position = UDim2.fromOffset(30, 316); skip.Size = UDim2.new(1, -60, 0, 50)
		skip.Activated:Connect(function() if not busy then showSure() end end)
		status = label(content, "ENTER  ·  BEGIN TRAINING", 13, Theme.DIM, Theme.FONT)
		status.Position = UDim2.fromOffset(30, 378); status.Size = UDim2.new(1, -60, 0, 40)
		primaryFn = function() choose("Train") end
	end
	showSure = function()
		clearContent()
		sfx("whoosh", 1.5)
		header("BEFORE YOU GO", "ARE YOU SURE?",
			"Combat here can be complicated. Swings follow your mouse, and one well-timed parry beats ten wild swings. Two minutes with the Drill Master will make your first battle a lot more fun (and pays Marks).")
		local go = button(content, "TRAIN FIRST", Theme.GREEN, 30)
		go.Position = UDim2.fromOffset(30, 226); go.Size = UDim2.new(1, -60, 0, 72)
		go.Activated:Connect(function() choose("Train") end)
		local skip = button(content, "SKIP ANYWAY  ·  TO BATTLE", Theme.RED, 20)
		skip.Position = UDim2.fromOffset(30, 310); skip.Size = UDim2.new(1, -60, 0, 50)
		skip.Activated:Connect(function() choose("Battle") end)
		local back = Instance.new("TextButton")
		back.BackgroundTransparency = 1; back.Text = "‹  BACK"; back.Font = Theme.FONT; back.TextSize = 14; back.TextColor3 = Theme.DIM
		back.Position = UDim2.fromOffset(30, 374); back.Size = UDim2.fromOffset(90, 30); back.Parent = content
		back.Activated:Connect(function() if not busy then showWelcome() end end)
		status = label(content, "You can always train later: the Training Yard is on the PLAY menu.", 13, Theme.DIM, Theme.FONT)
		status.Position = UDim2.fromOffset(130, 372); status.Size = UDim2.new(1, -160, 0, 36)
		status.TextXAlignment = Enum.TextXAlignment.Right
		primaryFn = function() choose("Train") end
	end
	showWelcome()
	UserInputService.InputBegan:Connect(function(input)
		if done or busy then return end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter or input.KeyCode == Enum.KeyCode.ButtonA then
			if primaryFn then primaryFn() end
		end
	end)

	-- the trip failed: the card is theirs again
	local hubEvent = ReplicatedStorage:FindFirstChild("HubEvent")
	if hubEvent then
		hubEvent.OnClientEvent:Connect(function(what)
			if what == "TravelFailed" and not done then busy = false; setStatus("The trip failed. Try again.", Theme.BAD) end
		end)
	end
	-- gone from the Courtyard (Studio switches mode in place), or no longer new: it's over
	local function check()
		if round:GetAttribute("Mode") ~= "Hub" or (player:GetAttribute("Tutorial") or 2) >= 1 and not busy then cleanup() end
	end
	round:GetAttributeChangedSignal("Mode"):Connect(check)
	player:GetAttributeChangedSignal("Tutorial"):Connect(check)
end

--------------------------------------------------------------------
--  THE FIRST BATTLE: a briefing, then tips as things happen
--------------------------------------------------------------------
local BRIEF = {
	TDM = "Two armies, one pool of tickets each. Every enemy you drop costs their side a ticket: bleed them dry.",
	FFA = "Everyone for themselves. Most kills when the clock runs out wins.",
	KOTH = "Take the hill and hold it: points tick for the side standing on it.",
}
-- a control's name for what the player holds (keys, a controller, a touch screen)
local InputHints = require(ReplicatedStorage:WaitForChild("InputHints"))
local function keyOf(action) return InputHints.name(action) end

local function firstBattle()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FirstBattle"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 70
	gui.Parent = playerGui
	local over = false
	local function stillFirst() return not over and (player:GetAttribute("Tutorial") or 2) == 1 and round:GetAttribute("Mode") ~= "Hub" end

	-- a tip at the bottom of the screen (one at a time)
	local tipBox = panel(gui)
	tipBox.AnchorPoint = Vector2.new(0.5, 1)
	tipBox.Position = UDim2.new(0.5, 0, 1, -170)
	tipBox.Size = UDim2.fromOffset(560, 0)
	tipBox.AutomaticSize = Enum.AutomaticSize.Y
	tipBox.Visible = false
	do local p = Instance.new("UIPadding", tipBox); p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = UDim.new(0, 12), UDim.new(0, 12), UDim.new(0, 18), UDim.new(0, 18) end
	local tipHead = label(tipBox, "", 14, GOLD, Theme.FONT); tipHead.Size = UDim2.new(1, 0, 0, 16)
	local tipText = label(tipBox, "", 17, WHITE, Theme.FONT_BODY)
	tipText.Position = UDim2.fromOffset(0, 20); tipText.Size = UDim2.new(1, 0, 0, 0); tipText.AutomaticSize = Enum.AutomaticSize.Y
	tipText:FindFirstChildOfClass("UIStroke").Transparency = 0.5
	local tipAt = 0
	local shown = {}
	local function tip(id, head, text, secs)
		if shown[id] or not stillFirst() then return end
		shown[id] = true
		tipAt = os.clock()
		local mine = tipAt
		tipHead.Text, tipText.Text = head, text
		tipBox.Visible = true
		tipBox.Position = UDim2.new(0.5, 0, 1, -150)
		TweenService:Create(tipBox, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 1, -170)}):Play()
		task.delay(secs or 7, function() if tipAt == mine then tipBox.Visible = false end end)
	end

	-- a word that punches in (the first kill)
	local big = label(gui, "", 64, GOLD)
	big.AnchorPoint = Vector2.new(0.5, 0.5); big.Position = UDim2.fromScale(0.5, 0.3); big.Size = UDim2.fromOffset(900, 80); big.Visible = false
	local bigSub = label(gui, "", 20, WHITE, Theme.FONT)
	bigSub.AnchorPoint = Vector2.new(0.5, 0); bigSub.Position = UDim2.new(0.5, 0, 0.3, 44); bigSub.Size = UDim2.fromOffset(900, 26); bigSub.Visible = false
	local function punch(text, sub)
		big.Text, bigSub.Text = text, sub or ""
		big.Visible, bigSub.Visible = true, sub ~= nil
		local s = big:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", big)
		s.Scale = 1.6
		TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
		task.delay(2.6, function() big.Visible, bigSub.Visible = false, false end)
	end

	-- THE BRIEFING, once there's a body on the field
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 60 and not (player.Character and player.Character:FindFirstChildOfClass("Humanoid")) do task.wait(0.3) end
		task.wait(1.2)
		if not stillFirst() then return end
		local mode = round:GetAttribute("Mode") or ""
		local def = GameConfig.MODES[mode]
		local card = panel(gui)
		card.AnchorPoint = Vector2.new(0.5, 0)
		card.Position = UDim2.new(0.5, 0, 0, 120)
		card.Size = UDim2.fromOffset(600, 196)
		local k = label(card, "YOUR FIRST BATTLE", 15, GOLD, Theme.FONT); k.Position = UDim2.fromOffset(24, 16); k.Size = UDim2.new(1, -48, 0, 18)
		local t = label(card, string.upper(def and def.name or mode), 38); t.Position = UDim2.fromOffset(24, 36); t.Size = UDim2.new(1, -48, 0, 44)
		local b = label(card, BRIEF[mode] or (def and def.description) or "", 17, Theme.DIM, Theme.FONT_BODY)
		b.Position = UDim2.fromOffset(24, 84); b.Size = UDim2.new(1, -48, 0, 46); b.TextYAlignment = Enum.TextYAlignment.Top
		local chips = Instance.new("Frame"); chips.BackgroundTransparency = 1; chips.Position = UDim2.fromOffset(24, 140); chips.Size = UDim2.new(1, -48, 0, 34); chips.Parent = card
		local lay = Instance.new("UIListLayout", chips); lay.FillDirection = Enum.FillDirection.Horizontal; lay.Padding = UDim.new(0, 8)
		lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
		for _, c in ipairs({"STICK WITH YOUR TEAM", keyOf("Block") .. "  ·  BLOCK", "WATCH YOUR STAMINA"}) do
			local chip = Instance.new("TextLabel")
			chip.BackgroundColor3 = Theme.GLASS2; chip.Font = Theme.FONT; chip.TextSize = 13; chip.TextColor3 = WHITE; chip.Text = c
			chip.Size = UDim2.fromOffset(176, 32); chip.Parent = chips
			Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 10)
		end
		local pop = Instance.new("UIScale", card); pop.Scale = 0.8
		TweenService:Create(pop, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
		sfx("hit", 2)
		task.wait(9)
		if card.Parent then
			TweenService:Create(pop, TweenInfo.new(0.25), {Scale = 0}):Play()
			task.delay(0.3, function() card:Destroy() end)
		end
	end)

	-- TIPS: watch the body (each new one after a respawn)
	local function watch(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then return end
		local last = hum.Health
		hum.HealthChanged:Connect(function(h)
			if h < last - 1 and h > 0 then
				tip("hurt", "YOU'RE HIT!", InputHints.fill("Hold {Block} to block their blows, or tap it just as a blow lands to PARRY: a parry costs you nothing and opens them up."))
			end
			last = h
		end)
		hum.Died:Connect(function()
			tip("died", "YOU FELL", "That's war. You'll be back in a moment: stick close to your team, and fight them one at a time.", 6)
		end)
		task.spawn(function()
			while char.Parent and hum.Health > 0 and stillFirst() do
				local max = char:GetAttribute("BlockMax") or 100
				local now = char:GetAttribute("BlockMeter") or max
				if now / math.max(max, 1) < 0.2 then
					tip("winded", "OUT OF BREATH!", "Swings, misses, blocks and sprints cost stamina. Back off for a moment and it comes back: an exhausted fighter can't block.")
				end
				task.wait(0.4)
			end
		end)
	end
	if player.Character then task.spawn(watch, player.Character) end
	player.CharacterAdded:Connect(watch)
	-- the first kill
	task.spawn(function()
		local ls = player:WaitForChild("leaderstats", 30)
		local k = ls and ls:WaitForChild("Kills", 10)
		if not k then return end
		local start = k.Value
		k.Changed:Connect(function(v)
			if v > start and not shown.kill and stillFirst() then
				shown.kill = true
				sfx("kill", 4)
				punch("FIRST KILL!", "keep it up, soldier")
			end
		end)
	end)
	-- a minute in: the two tricks that beat a turtle
	task.delay(75, function()
		tip("tricks", "TWO TRICKS", InputHints.fill("{Feint} feints a swing: they flinch at nothing. {Kick} kicks straight through a raised guard."), 8)
	end)
	-- the battle's over (the travel screen takes it from here)
	player:GetAttributeChangedSignal("Tutorial"):Connect(function()
		if (player:GetAttribute("Tutorial") or 2) >= 2 then over = true; tipBox.Visible = false end
	end)
end

--------------------------------------------------------------------
--  WHO GETS WHAT (again whenever the mode changes: Studio switches in place)
--------------------------------------------------------------------
local welcoming, battling = false, false
local function decide()
	local tut = player:GetAttribute("Tutorial") or 2
	local mode = round:GetAttribute("Mode")
	if tut == 0 and mode == "Hub" then
		if welcoming then return end
		welcoming = true
		-- (the menu may have opened in the moment before we knew: close it)
		if _G.HubMenuOpen and _G.HubMenuOpen() and _G.HubMenuToggle then
			_G.IntroActive = nil
			for _ = 1, 3 do if _G.HubMenuOpen() then _G.HubMenuToggle() end end
		end
		_G.IntroActive = true
		task.spawn(function() welcome(); welcoming = false end)
		return
	end
	if not welcoming then _G.IntroActive = nil end
	if tut == 1 and mode ~= "Hub" and mode ~= "Tiltyard" and not battling then
		battling = true
		firstBattle()
	end
end
local t0 = os.clock()
while player:GetAttribute("Tutorial") == nil and os.clock() - t0 < 10 do task.wait(0.1) end
while (round:GetAttribute("Mode") or "") == "" and os.clock() - t0 < 15 do task.wait(0.1) end
decide()
round:GetAttributeChangedSignal("Mode"):Connect(function() task.delay(0.5, decide) end)
