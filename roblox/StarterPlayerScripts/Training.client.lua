--[[ TRAINING (client) — the training yard's screens (Game ▸ Training on the
     server). Only in the Tiltyard mode:
       • WHERE TO GO: a light beam and a bobbing arrow over your next stop
         (the straw dummy, the drill dummy, the ring, the Drill Master), and
         an arrow at the screen's edge pointing to it when it's off screen
       • the lesson card (right side): the lesson in your own key binds, how
         far along you are, and where to go
       • the Drill Master's menu (E at him): carry on, start over, every
         lesson, the sparring ring, practice bots, the Gauntlet
       • the boards: lessons, the ring (Squire / Knight / Champion), practice
         (which bots, how many)
       • his speech bubble, saying the lesson
       • banners: 3-2-1, VICTORY / DEFEATED / FORFEIT, LESSON DONE, gauntlet
         waves
       • BASIC TRAINING (a newcomer's first visit): the card up top with the
         step (1 / 8 …), a welcome and a send-off; FIND YOUR FEET's checklist
         of controls (each ticks the moment you press it, in your own binds);
         SKIP (the button, or M: the menu key asks "are you sure?" here, since
         a newcomer may not know how to free the mouse yet) ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("TrainingRemote", math.huge)   -- only a training server makes it
local round = ReplicatedStorage:WaitForChild("Round")
local D = Catalog.DRILLS
local LESSON = {}
for i, l in ipairs(D.lessons) do LESSON[l.id] = l; l.index = i end

local WHITE = Color3.new(1, 1, 1)
local GUIDE = Color3.fromRGB(255, 206, 70)
local function inYard() return round:GetAttribute("Mode") == "Tiltyard" end
local function hubMenuUp()
	local h = player.PlayerGui:FindFirstChild("HubMenu")
	return h ~= nil and h.Enabled
end

-- a key bind's name, the way a player says it
local NICE = {MouseButton1 = "LEFT MOUSE", MouseButton3 = "MIDDLE MOUSE", MouseWheelUp = "SCROLL UP", MouseWheelDown = "SCROLL DOWN",
	LeftAlt = "LEFT ALT", RightAlt = "RIGHT ALT", LeftShift = "LEFT SHIFT", LeftControl = "LEFT CTRL", Space = "SPACE"}
-- (on a touch screen the moves are buttons: TouchControls)
local function touchOnly() return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled end
local function keyName(action)
	if touchOnly() then return "the " .. string.upper(action) .. " button" end
	if action == "Block" then return "[RIGHT MOUSE]" end
	local n = ClientSettings.get("Key_" .. action) or action
	return "[" .. (NICE[n] or string.upper(n)) .. "]"
end
local function say(text)
	return (text:gsub("{(%a+)}", function(a) return keyName(a) end))
end

--------------------------------------------------------------------
--  LOOK
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Training"
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function text(parent, t, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font or Theme.FONT_TITLE
	l.TextSize = size or 16
	l.TextColor3 = color or WHITE
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = t or ""
	l.Parent = parent
	local s = Instance.new("UIStroke"); s.Color = Theme.OUTLINE; s.Thickness = (size or 16) >= 24 and 2.4 or 1.6; s.Parent = l
	return l
end
local function panel(parent, size, pos)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Theme.GLASS
	f.BackgroundTransparency = 0.12
	f.Size, f.Position = size, pos or UDim2.new()
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 14)
	local s = Instance.new("UIStroke", f); s.Color = WHITE; s.Transparency = 0.85; s.Thickness = 1.5
	return f
end
local function button(parent, t, color, size, pos)
	local b = Instance.new("TextButton")
	b.Text = t
	b.Font = Theme.FONT_TITLE
	b.TextSize = 17
	b.TextColor3 = WHITE
	b.AutoButtonColor = true
	b.BackgroundColor3 = color or Theme.GLASS2
	b.Size, b.Position = size, pos or UDim2.new()
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local s = Instance.new("UIStroke"); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual; s.Color = Theme.OUTLINE; s.Thickness = 1.6; s.Parent = b
	return b
end

--------------------------------------------------------------------
--  WHERE TO GO: a beam, an arrow over it, and an arrow at the screen edge
--------------------------------------------------------------------
local beam = Instance.new("Part")
beam.Name = "TrainingBeacon"
beam.Anchored, beam.CanCollide, beam.CanQuery, beam.CanTouch, beam.CastShadow = true, false, false, false, false
beam.Shape = Enum.PartType.Cylinder
beam.Material = Enum.Material.Neon
beam.Color = GUIDE
beam.Size = Vector3.new(90, 1.1, 1.1)
beam.Transparency = 1
local over = Instance.new("BillboardGui")
over.Name = "TrainingArrow"
over.Size = UDim2.fromOffset(160, 70)
over.AlwaysOnTop = true
over.LightInfluence = 0
over.MaxDistance = 1000
over.ResetOnSpawn = false
over.Enabled = false
over.Parent = player.PlayerGui
local overArrow = text(over, "▼", 38, GUIDE); overArrow.Size = UDim2.new(1, 0, 0, 40); overArrow.TextXAlignment = Enum.TextXAlignment.Center
local overName = text(over, "", 14, WHITE); overName.Position = UDim2.fromOffset(0, 40); overName.Size = UDim2.new(1, 0, 0, 18); overName.TextXAlignment = Enum.TextXAlignment.Center
local anchor = Instance.new("Part")
anchor.Name = "TrainingArrowAnchor"
anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
anchor.Transparency = 1
anchor.Size = Vector3.new(0.2, 0.2, 0.2)
over.Adornee = anchor

local edge = Instance.new("Frame")
edge.AnchorPoint = Vector2.new(0.5, 0.5)
edge.Size = UDim2.fromOffset(120, 64)
edge.BackgroundTransparency = 1
edge.Visible = false
edge.Parent = gui
local edgeArrow = text(edge, "➤", 40, GUIDE); edgeArrow.AnchorPoint = Vector2.new(0.5, 0.5); edgeArrow.Position = UDim2.fromScale(0.5, 0.36); edgeArrow.Size = UDim2.fromOffset(46, 46); edgeArrow.TextXAlignment = Enum.TextXAlignment.Center
local edgeName = text(edge, "", 13, WHITE); edgeName.Position = UDim2.new(0, 0, 1, -18); edgeName.Size = UDim2.new(1, 0, 0, 16); edgeName.TextXAlignment = Enum.TextXAlignment.Center

local fighting = false   -- in the ring / the gauntlet / practice: no guide
RunService.RenderStepped:Connect(function()
	local pos = player:GetAttribute("DrillTarget")
	local name = player:GetAttribute("DrillTargetName") or ""
	local cam = workspace.CurrentCamera
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local show = inYard() and typeof(pos) == "Vector3" and cam ~= nil and hrp ~= nil and not hubMenuUp() and not fighting
	local near = show and (Vector3.new(pos.X, hrp.Position.Y, pos.Z) - hrp.Position).Magnitude < 9
	-- the beam and the bobbing arrow (gone once you're there)
	if show and not near then
		beam.Parent = workspace
		beam.CFrame = CFrame.new(pos.X, pos.Y - 3 + 45, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		beam.Transparency = 0.55 + 0.1 * math.sin(os.clock() * 3)
		anchor.Parent = workspace
		anchor.Position = Vector3.new(pos.X, pos.Y + 4.5 + 0.6 * math.sin(os.clock() * 4), pos.Z)
		over.Enabled = true
		overName.Text = name
	else
		beam.Parent = nil
		over.Enabled = false
	end
	-- the edge arrow when it's off screen
	if show and not near then
		local v, onScreen = cam:WorldToViewportPoint(pos)
		local size = cam.ViewportSize
		if onScreen and v.Z > 0 and v.X > 40 and v.X < size.X - 40 and v.Y > 40 and v.Y < size.Y - 40 then
			edge.Visible = false
		else
			local c = size / 2
			local dir = Vector2.new(v.X, v.Y) - c
			if v.Z < 0 then dir = -dir end
			if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
			dir = dir.Unit
			-- out to an ellipse just inside the screen's edge
			local rx, ry = c.X - 90, c.Y - 80
			local t = 1 / math.sqrt((dir.X / rx) ^ 2 + (dir.Y / ry) ^ 2)
			local p = c + dir * t
			edge.Position = UDim2.fromOffset(p.X, p.Y)
			edgeArrow.Rotation = math.deg(math.atan2(dir.Y, dir.X))
			edgeName.Text = name
			edge.Visible = true
		end
	else
		edge.Visible = false
	end
end)

--------------------------------------------------------------------
--  THE LESSON CARD
--------------------------------------------------------------------
local card = panel(gui, UDim2.fromOffset(330, 192), UDim2.new(1, -346, 0.5, -96))
card.Visible = false
local cardHead = text(card, "DRILL MASTER  ·  LESSON", 12, Theme.DIM); cardHead.Position = UDim2.fromOffset(14, 10); cardHead.Size = UDim2.new(1, -28, 0, 14)
local cardTitle = text(card, "", 24); cardTitle.Position = UDim2.fromOffset(14, 26); cardTitle.Size = UDim2.new(1, -28, 0, 28)
local cardText = text(card, "", 14, WHITE, Theme.FONT); cardText.Position = UDim2.fromOffset(14, 56); cardText.Size = UDim2.new(1, -28, 0, 60); cardText.TextYAlignment = Enum.TextYAlignment.Top
local cardGo = text(card, "", 13, GUIDE); cardGo.Position = UDim2.new(0, 14, 1, -62); cardGo.Size = UDim2.new(1, -28, 0, 16)
local barBack = Instance.new("Frame"); barBack.BackgroundColor3 = Color3.fromRGB(8, 10, 18); barBack.BackgroundTransparency = 0.2; barBack.BorderSizePixel = 0
barBack.Position = UDim2.new(0, 14, 1, -40); barBack.Size = UDim2.new(1, -120, 0, 18); barBack.Parent = card
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 8)
local bar = Instance.new("Frame"); bar.BackgroundColor3 = Theme.GREEN; bar.BorderSizePixel = 0; bar.Size = UDim2.fromScale(0, 1); bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
local barText = text(barBack, "", 13); barText.Size = UDim2.fromScale(1, 1); barText.TextXAlignment = Enum.TextXAlignment.Center
local menuB = button(card, "MENU", Theme.BLUE, UDim2.fromOffset(92, 30), UDim2.new(1, -104, 1, -46))
-- basic training: skip it and go straight to battle
local skipB = button(gui, "SKIP TRAINING  ·  M", Theme.GLASS2, UDim2.fromOffset(210, 40), UDim2.new(1, -226, 0, 64))
skipB.Visible = false
local skipping = false
local skipConfirm   -- (below, with the boards)
local function skipNow()
	if skipping then return end
	skipping = true
	skipB.Text = "OFF TO BATTLE…"
	remote:FireServer("SkipTraining")
end
skipB.MouseButton1Click:Connect(function() if skipConfirm then skipConfirm() end end)

-- the Drill Master's bubble (local: he tells each of you your own lesson)
local bubble = Instance.new("BillboardGui")
bubble.Name = "DrillBubble"
bubble.Size = UDim2.fromOffset(300, 90)
bubble.StudsOffsetWorldSpace = Vector3.new(0, 4.4, 0)
bubble.MaxDistance = 60
bubble.AlwaysOnTop = false
bubble.ResetOnSpawn = false
bubble.Parent = player.PlayerGui
local bubbleBox = Instance.new("Frame"); bubbleBox.BackgroundColor3 = Color3.fromRGB(250, 244, 226); bubbleBox.Size = UDim2.fromScale(1, 1); bubbleBox.Parent = bubble
Instance.new("UICorner", bubbleBox).CornerRadius = UDim.new(0, 12)
local bubbleText = Instance.new("TextLabel"); bubbleText.BackgroundTransparency = 1; bubbleText.Size = UDim2.new(1, -16, 1, -12); bubbleText.Position = UDim2.fromOffset(8, 6)
bubbleText.Font = Theme.FONT; bubbleText.TextSize = 15; bubbleText.TextWrapped = true; bubbleText.TextColor3 = Color3.fromRGB(40, 30, 20); bubbleText.Parent = bubbleBox

local function masterHead()
	local map = workspace:FindFirstChild("Map")
	if not map then return nil end
	for _, m in ipairs(map:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("DrillMaster") then return m:FindFirstChild("Head") end
	end
	return nil
end

local function refreshCard()
	local yard = inYard()
	local id = player:GetAttribute("Drill") or ""
	local l = LESSON[id]
	card.Visible = yard and l ~= nil and not hubMenuUp() and not fighting
	bubble.Enabled = yard
	bubble.Adornee = yard and masterHead() or nil
	if not l then
		local done = 0
		for _ in (player:GetAttribute("DrillsDone") or ""):gmatch("[^,]+") do done += 1 end
		bubbleText.Text = done >= #D.lessons and "You've learned all I can teach. Spar in the ring, run the Gauntlet, or call up bots. Press E!"
			or "Come here, recruit. Press E and I'll teach you."
		return
	end
	local n, goal = player:GetAttribute("DrillProgress") or 0, player:GetAttribute("DrillGoal") or l.goal
	local basic = player:GetAttribute("Course") == "basic"
	skipB.Visible = yard and basic and not skipping
	menuB.Visible = not basic
	-- a newcomer's card sits up top, where they can't miss it
	card.Position = basic and UDim2.new(0.5, -165, 0, 64) or UDim2.new(1, -346, 0.5, -96)
	if basic then
		cardHead.Text = string.format("BASIC TRAINING  ·  STEP %d / %d", player:GetAttribute("CourseStep") or 1, player:GetAttribute("CourseSteps") or 7)
	else
		cardHead.Text = string.format("DRILL MASTER  ·  LESSON %d / %d", l.index, #D.lessons)
	end
	cardTitle.Text = string.upper(l.title)
	cardText.Text = say(l.text)
	local where = player:GetAttribute("DrillTargetName") or ""
	cardGo.Text = where ~= "" and ("GO TO  ›  " .. where) or ""
	bar.Size = UDim2.fromScale(math.clamp(n / math.max(goal, 1), 0, 1), 1)
	barText.Text = string.format("%d / %d", n, goal)
	bubbleText.Text = say(l.text)
end
for _, a in ipairs({"Drill", "DrillProgress", "DrillGoal", "DrillsDone", "DrillTargetName", "Course", "CourseStep"}) do player:GetAttributeChangedSignal(a):Connect(refreshCard) end
round:GetAttributeChangedSignal("Mode"):Connect(refreshCard)
task.spawn(function() while true do task.wait(1); refreshCard() end end)

--------------------------------------------------------------------
--  FIND YOUR FEET: each control on the list ticks the moment you press it
--  (in your own binds); the server counts them (Drills ▸ basics)
--------------------------------------------------------------------
local FEET = {
	View = "Switch first / third person", Sprint = "Sprint (hold it while you run)", Crouch = "Crouch",
	Jump = "Hop", Dodge = "Dodge (with a direction)", Cursor = "Free the mouse (and again to lock it)",
}
local feet = panel(gui, UDim2.fromOffset(330, 0), UDim2.new(0, 16, 0.5, -150))
feet.AutomaticSize = Enum.AutomaticSize.Y
feet.Visible = false
do
	local pad = Instance.new("UIPadding", feet)
	pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12), UDim.new(0, 14), UDim.new(0, 14)
	local lay = Instance.new("UIListLayout", feet); lay.Padding = UDim.new(0, 6); lay.SortOrder = Enum.SortOrder.LayoutOrder
end
local feetHead = text(feet, "THE BASICS  ·  TRY EACH ONE", 13, GUIDE); feetHead.Size = UDim2.new(1, 0, 0, 16); feetHead.LayoutOrder = 0
local feetRows, tried = {}, {}
local feetFoot = text(feet, "", 12, Theme.DIM, Theme.FONT); feetFoot.Size = UDim2.new(1, 0, 0, 30); feetFoot.LayoutOrder = 100
local gotIt = button(feet, "GOT IT  ›", Theme.GREEN, UDim2.new(1, 0, 0, 40)); gotIt.LayoutOrder = 101; gotIt.Visible = false
local function feetControls()
	local l = LESSON.basics
	return l and l.controls or {}
end
local function buildFeet()
	for _, r in pairs(feetRows) do r.row:Destroy() end
	feetRows = {}
	for i, action in ipairs(feetControls()) do
		local row = Instance.new("Frame")
		row.BackgroundColor3 = Theme.GLASS2; row.BackgroundTransparency = 0.25; row.Size = UDim2.new(1, 0, 0, 34); row.LayoutOrder = i; row.Parent = feet
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
		local key = text(row, keyName(action):gsub("[%[%]]", ""), 13, WHITE)
		key.BackgroundTransparency = 0; key.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
		key.Position = UDim2.fromOffset(6, 5); key.Size = UDim2.fromOffset(96, 24); key.TextXAlignment = Enum.TextXAlignment.Center; key.TextScaled = false
		Instance.new("UICorner", key).CornerRadius = UDim.new(0, 6)
		local what = text(row, FEET[action] or action, 13, WHITE, Theme.FONT); what.Position = UDim2.fromOffset(110, 0); what.Size = UDim2.new(1, -146, 1, 0)
		local tick = text(row, "", 20, Theme.GOOD); tick.AnchorPoint = Vector2.new(1, 0.5); tick.Position = UDim2.new(1, -8, 0.5, 0); tick.Size = UDim2.fromOffset(26, 26)
		tick.TextXAlignment = Enum.TextXAlignment.Center
		feetRows[action] = {row = row, tick = tick, what = what}
	end
	feetFoot.Text = "Anytime: M opens the menu (Settings has every key), Tab holds the scoreboard."
	gotIt.Visible = touchOnly()
end
local function markFeet(action)
	local r = feetRows[action]
	if not r or tried[action] then return end
	tried[action] = true
	r.tick.Text = "✔"
	r.row.BackgroundColor3 = Color3.fromRGB(40, 90, 50)
	local sc = r.tick:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", r.tick)
	sc.Scale = 1.8
	TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
	pcall(function() require(ReplicatedStorage:WaitForChild("UIFX")).play("Click") end)
	remote:FireServer("Basic", action)
end
local function refreshFeet()
	local on = inYard() and player:GetAttribute("Drill") == "basics" and not hubMenuUp()
	if on and not feet.Visible then tried = {}; buildFeet() end
	feet.Visible = on
end
UserInputService.InputBegan:Connect(function(input)
	if not feet.Visible or UserInputService:GetFocusedTextBox() then return end
	local action = ClientSettings.actionForInput(input)
	if action and FEET[action] then markFeet(action) end
end)
-- (on a touch screen the moves are buttons: a hop and a dodge show for themselves, the rest on GOT IT)
gotIt.MouseButton1Click:Connect(function() for _, a in ipairs(feetControls()) do markFeet(a) end end)
local function watchFeet(c)
	local hum = c:WaitForChild("Humanoid", 10)
	if hum then hum.Jumping:Connect(function(on) if on and feet.Visible then markFeet("Jump") end end) end
	c:GetAttributeChangedSignal("LocalDodgeAt"):Connect(function() if feet.Visible then markFeet("Dodge") end end)
end
if player.Character then task.spawn(watchFeet, player.Character) end
player.CharacterAdded:Connect(watchFeet)
for _, a in ipairs({"Drill", "Course"}) do player:GetAttributeChangedSignal(a):Connect(refreshFeet) end
task.spawn(function() while true do task.wait(0.5); refreshFeet() end end)

--------------------------------------------------------------------
--  BOARDS (a centred pop-up)
--------------------------------------------------------------------
local shade = Instance.new("TextButton"); shade.Text = ""; shade.AutoButtonColor = false; shade.BackgroundColor3 = Theme.BACK; shade.BackgroundTransparency = 0.45
shade.Size = UDim2.fromScale(1, 1); shade.Visible = false; shade.ZIndex = 5; shade.Parent = gui
local board = panel(shade, UDim2.fromOffset(640, 540), UDim2.new(0.5, -320, 0.5, -270))
board.ZIndex = 6
local function closeBoard() shade.Visible = false; for _, c in ipairs(board:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end end
shade.MouseButton1Click:Connect(closeBoard)
local function openBoard(titleText)
	closeBoard()
	board.Size = UDim2.fromOffset(640, 540)
	board.Position = UDim2.new(0.5, -320, 0.5, -270)
	shade.Visible = true
	local t = text(board, titleText, 28); t.Position = UDim2.fromOffset(20, 14); t.Size = UDim2.new(1, -120, 0, 34); t.ZIndex = 7
	local x = button(board, "X", Theme.RED, UDim2.fromOffset(44, 40), UDim2.new(1, -58, 0, 12)); x.ZIndex = 7
	x.MouseButton1Click:Connect(closeBoard)
	return board
end
-- the mouse is free while a board is up
RunService.RenderStepped:Connect(function()
	if shade.Visible then UserInputService.MouseBehavior = Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled = true end
end)

local lastInfo = {}

-- "are you sure?": a newcomer leaving basic training early
skipConfirm = function()
	if skipping then return end
	local b = openBoard("SKIP TRAINING?")
	b.Size = UDim2.fromOffset(600, 340)
	b.Position = UDim2.new(0.5, -300, 0.5, -170)
	local step, steps = player:GetAttribute("CourseStep") or 1, player:GetAttribute("CourseSteps") or 8
	local left = math.max(steps - step + 1, 1)
	local t = text(b, string.format("Combat here is different. Every swing follows your mouse, and blocks, parries and kicks decide who walks away. "
		.. "You're on step %d of %d: about %d minute%s to go, and every step pays Marks.\n\nYou can always come back later: the Training Yard is in the PLAY menu.",
		step, steps, math.max(1, math.ceil(left * 0.3)), left > 3 and "s" or ""), 16, WHITE, Theme.FONT)
	t.Position = UDim2.fromOffset(22, 58); t.Size = UDim2.new(1, -44, 0, 150); t.TextYAlignment = Enum.TextYAlignment.Top; t.ZIndex = 7
	local keep = button(b, "KEEP TRAINING", Theme.GREEN, UDim2.new(0.5, -28, 0, 58), UDim2.new(0, 22, 1, -80)); keep.ZIndex = 7; keep.TextSize = 20
	keep.MouseButton1Click:Connect(closeBoard)
	local go = button(b, "SKIP TO BATTLE", Theme.GLASS2, UDim2.new(0.5, -28, 0, 58), UDim2.new(0.5, 6, 1, -80)); go.ZIndex = 7; go.TextSize = 20
	go.MouseButton1Click:Connect(function() closeBoard(); skipNow() end)
end
-- M in basic training: the question (not the menu)
_G.MenuKeyOverride = function()
	if not (inYard() and player:GetAttribute("Course") == "basic") or skipping then return false end
	if shade.Visible then closeBoard() else skipConfirm() end
	return true
end

local function lessonBoard()
	local b = openBoard("THE DRILL MASTER'S LESSONS")
	local done = {}
	for id in (player:GetAttribute("DrillsDone") or ""):gmatch("[^,]+") do done[id] = true end
	local current = player:GetAttribute("Drill") or ""
	local pay = Catalog.ECONOMY.earn and Catalog.ECONOMY.earn.drill
	local sub = text(b, pay and string.format("Each lesson pays %d Marks and %d XP the first time. Pick any to (re)learn it.", pay.marks or 0, pay.xp or 0) or "", 13, Theme.DIM, Theme.FONT)
	sub.Position = UDim2.fromOffset(20, 50); sub.Size = UDim2.new(1, -40, 0, 18); sub.ZIndex = 7
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.Position = UDim2.fromOffset(16, 76); list.Size = UDim2.new(1, -32, 1, -92)
	list.CanvasSize = UDim2.new(); list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.ScrollBarThickness = 5; list.ZIndex = 7; list.Parent = b
	local lay = Instance.new("UIListLayout", list); lay.Padding = UDim.new(0, 6); lay.SortOrder = Enum.SortOrder.LayoutOrder
	for i, l in ipairs(D.lessons) do
		local on = l.id == current
		local r = button(list, "", on and Theme.BLUE or Theme.GLASS2, UDim2.new(1, -8, 0, 46))
		r.LayoutOrder = i; r.ZIndex = 8
		local t1 = text(r, string.format("%d.  %s", i, string.upper(l.title)), 17); t1.Position = UDim2.fromOffset(12, 4); t1.Size = UDim2.new(1, -150, 0, 20); t1.ZIndex = 9
		local t2 = text(r, say(l.text), 11, Theme.DIM, Theme.FONT); t2.Position = UDim2.fromOffset(12, 24); t2.Size = UDim2.new(1, -150, 0, 18); t2.TextTruncate = Enum.TextTruncate.AtEnd; t2.TextWrapped = false; t2.ZIndex = 9
		local st = text(r, done[l.id] and "DONE ✔" or (on and "NOW" or "START ›"), 15, done[l.id] and Theme.GOOD or (on and WHITE or Theme.ACCENT)); st.AnchorPoint = Vector2.new(1, 0.5)
		st.Position = UDim2.new(1, -12, 0.5, 0); st.Size = UDim2.fromOffset(120, 20); st.TextXAlignment = Enum.TextXAlignment.Right; st.ZIndex = 9
		r.MouseButton1Click:Connect(function() remote:FireServer("Lesson", l.id); closeBoard() end)
	end
end

local FOES = {
	{skill = "Squire", blurb = "Slow to react, rarely parries. A good first fight."},
	{skill = "Knight", blurb = "Parries half your swings, feints now and then, kicks a turtle."},
	{skill = "Champion", blurb = "Reads your windup, parries most of it, feints and morphs. Good luck."},
}
local FOE_COL = {Theme.GREEN, Theme.BLUE, Theme.RED}
local function ringBoard(rec)
	local b = openBoard("THE SPARRING RING")
	local sub = text(b, "Pick your opponent. Three, two, one, then it's to the death. Leave the ring and you forfeit.", 13, Theme.DIM, Theme.FONT)
	sub.Position = UDim2.fromOffset(20, 50); sub.Size = UDim2.new(1, -40, 0, 34); sub.ZIndex = 7
	for i, f in ipairs(FOES) do
		local wins = rec and rec[f.skill] or 0
		local pay = D.spar[f.skill] or {}
		local c = panel(b, UDim2.new(1 / 3, -20, 0, 340), UDim2.new((i - 1) / 3, 14, 0, 100)); c.ZIndex = 7
		local col = FOE_COL[i]
		local t1 = text(c, string.upper(f.skill), 24, col); t1.Position = UDim2.fromOffset(12, 12); t1.Size = UDim2.new(1, -24, 0, 30); t1.ZIndex = 8
		local t2 = text(c, f.blurb, 14, WHITE, Theme.FONT); t2.Position = UDim2.fromOffset(12, 48); t2.Size = UDim2.new(1, -24, 0, 110); t2.TextYAlignment = Enum.TextYAlignment.Top; t2.ZIndex = 8
		local t3 = text(c, string.format("YOUR WINS: %d", wins), 15, Theme.ACCENT); t3.Position = UDim2.fromOffset(12, 168); t3.Size = UDim2.new(1, -24, 0, 20); t3.ZIndex = 8
		local t4 = text(c, wins == 0 and string.format("first win: %d Marks", pay.first or 0) or string.format("a win: %d Marks", pay.again or 0), 13, Theme.DIM, Theme.FONT)
		t4.Position = UDim2.fromOffset(12, 192); t4.Size = UDim2.new(1, -24, 0, 18); t4.ZIndex = 8
		local go = button(c, "FIGHT", col, UDim2.new(1, -24, 0, 50), UDim2.new(0, 12, 1, -62)); go.ZIndex = 8
		go.MouseButton1Click:Connect(function() remote:FireServer("Spar", f.skill); closeBoard() end)
	end
end

local function practiceBoard()
	local b = openBoard("THE PRACTICE GROUND")
	local sub = text(b, "Call up bots to fight on the practice ground: they come at you together. Fight as often as you like; no pay, just practice.", 13, Theme.DIM, Theme.FONT)
	sub.Position = UDim2.fromOffset(20, 50); sub.Size = UDim2.new(1, -40, 0, 34); sub.ZIndex = 7
	for i, f in ipairs(FOES) do
		local c = panel(b, UDim2.new(1 / 3, -20, 0, 340), UDim2.new((i - 1) / 3, 14, 0, 100)); c.ZIndex = 7
		local col = FOE_COL[i]
		local t1 = text(c, string.upper(f.skill), 24, col); t1.Position = UDim2.fromOffset(12, 12); t1.Size = UDim2.new(1, -24, 0, 30); t1.ZIndex = 8
		local t2 = text(c, f.blurb, 14, WHITE, Theme.FONT); t2.Position = UDim2.fromOffset(12, 48); t2.Size = UDim2.new(1, -24, 0, 90); t2.TextYAlignment = Enum.TextYAlignment.Top; t2.ZIndex = 8
		for n = 1, 3 do
			local go = button(c, n == 1 and "ONE" or (n == 2 and "TWO AT ONCE" or "THREE AT ONCE"), n == 1 and col or Theme.GLASS2, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, 150 + (n - 1) * 54)); go.ZIndex = 8
			go.MouseButton1Click:Connect(function() remote:FireServer("Practice", f.skill, n); closeBoard() end)
		end
	end
	if lastInfo.practicing then
		local clear = button(b, "SEND MY BOTS AWAY", Theme.RED, UDim2.new(1, -40, 0, 40), UDim2.new(0, 20, 1, -56)); clear.ZIndex = 7
		clear.MouseButton1Click:Connect(function() remote:FireServer("ClearPractice"); closeBoard() end)
	end
end

-- the Drill Master's menu
local function menuBoard(info)
	lastInfo = info or {}
	local b = openBoard("SIR ALDRIC, DRILL MASTER")
	local doneN = 0
	for _ in (player:GetAttribute("DrillsDone") or ""):gmatch("[^,]+") do doneN += 1 end
	local cur = LESSON[lastInfo.current or ""]
	local sub = text(b, cur and string.format("\"You're on lesson %d: %s. %d of %d done.\"", cur.index, cur.title, doneN, #D.lessons)
		or (doneN >= #D.lessons and "\"You've learned it all. Now prove it.\"" or "\"What'll it be, recruit?\""), 15, Theme.DIM, Theme.FONT)
	sub.Position = UDim2.fromOffset(20, 50); sub.Size = UDim2.new(1, -40, 0, 22); sub.ZIndex = 7
	local rows = {
		{cur and ("CARRY ON  ·  " .. string.upper(cur.title)) or "PICK UP THE LESSONS", Theme.GREEN, function()
			if cur then closeBoard() else lessonBoard() end end,
			cur and "Back to it: follow the arrow." or "Every lesson, ticked when done."},
		{"ALL LESSONS", Theme.BLUE, lessonBoard, "Pick any lesson to learn or redo it."},
		{"START OVER", Theme.GLASS2, function() remote:FireServer("Restart"); closeBoard() end, "Walk the whole course again from the first swing."},
		{"SPAR IN THE RING", Theme.GLASS2, function() ringBoard(lastInfo.records) end, "One on one with a Squire, a Knight or a Champion."},
		{"PRACTICE BOTS", Theme.GLASS2, practiceBoard, "One to three bots at once on the practice ground."},
		{"THE GAUNTLET", Theme.RED, function() remote:FireServer("Gauntlet"); closeBoard() end,
			string.format("Wave after wave in the ring until you fall. Your best: wave %d. Each new best wave pays %d Marks.", lastInfo.gauntlet or 0, lastInfo.perWave or 0)},
	}
	if lastInfo.ringBusy then rows[4][4] = lastInfo.ringBusy .. " is in the ring right now."; rows[6][4] = lastInfo.ringBusy .. " is in the ring right now." end
	for i, r in ipairs(rows) do
		local y = 84 + (i - 1) * 72
		local bt = button(b, r[1], r[2], UDim2.new(0.5, -24, 0, 58), UDim2.new(0, 20, 0, y)); bt.ZIndex = 7; bt.TextSize = 18
		bt.MouseButton1Click:Connect(r[3])
		local d = text(b, r[4], 13, Theme.DIM, Theme.FONT); d.Position = UDim2.new(0.5, 6, 0, y + 6); d.Size = UDim2.new(0.5, -26, 0, 46); d.TextYAlignment = Enum.TextYAlignment.Center; d.ZIndex = 7
	end
end
menuB.MouseButton1Click:Connect(function() menuBoard(lastInfo) end)

--------------------------------------------------------------------
--  BANNERS (a countdown, a result) and the gauntlet's wave line
--------------------------------------------------------------------
local banner = text(gui, "", 64); banner.AnchorPoint = Vector2.new(0.5, 0.5); banner.Position = UDim2.fromScale(0.5, 0.32)
banner.Size = UDim2.fromOffset(900, 80); banner.TextXAlignment = Enum.TextXAlignment.Center; banner.Visible = false
local bannerSub = text(gui, "", 22); bannerSub.AnchorPoint = Vector2.new(0.5, 0); bannerSub.Position = UDim2.new(0.5, 0, 0.32, 44)
bannerSub.Size = UDim2.fromOffset(900, 30); bannerSub.TextXAlignment = Enum.TextXAlignment.Center; bannerSub.Visible = false
local bannerAt = 0
local function show(big, small, color, secs)
	bannerAt = os.clock()
	banner.Text, bannerSub.Text = big, small or ""
	banner.TextColor3 = color or WHITE
	banner.Visible, bannerSub.Visible = true, small ~= nil
	local sc = banner:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", banner)
	sc.Scale = 1.4
	TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
	local mine = bannerAt
	task.delay(secs or 2.5, function() if bannerAt == mine then banner.Visible = false; bannerSub.Visible = false end end)
end
local waveLine = text(gui, "", 20, Theme.ACCENT); waveLine.AnchorPoint = Vector2.new(0.5, 0); waveLine.Position = UDim2.new(0.5, 0, 0, 84)
waveLine.Size = UDim2.fromOffset(600, 26); waveLine.TextXAlignment = Enum.TextXAlignment.Center; waveLine.Visible = false

-- 3-2-1-FIGHT, counted to the server time the fight starts (goAt): you're
-- held on your mark till then, and the bots start on FIGHT too
local function countdown(vs, goAt)
	goAt = goAt or (workspace:GetServerTimeNow() + 3)
	task.spawn(function()
		for n = 3, 1, -1 do
			local wait = goAt - n - workspace:GetServerTimeNow()
			if wait > 0 then task.wait(wait) end
			if goAt - workspace:GetServerTimeNow() > n - 1 then show(tostring(n), vs, WHITE, 0.95) end
		end
		local wait = goAt - workspace:GetServerTimeNow()
		if wait > 0 then task.wait(wait) end
		show("FIGHT!", nil, Theme.RED, 1.2)
	end)
end

remote.OnClientEvent:Connect(function(what, a, b, c, d, e)
	if what == "Menu" then
		lastInfo = a or {}
		if b == "practice" then practiceBoard() else menuBoard(a) end
	elseif what == "Lessons" then lessonBoard()
	elseif what == "Ring" then ringBoard(a)
	elseif what == "Progress" then refreshCard()
	elseif what == "Course" then
		skipping = false
		skipB.Text = "SKIP TRAINING  ·  M"
		show("WELCOME, RECRUIT!", "A few quick steps, then your first battle.", Theme.ACCENT, 4.5)
	elseif what == "Graduated" then
		skipB.Visible = false
		if a then
			show("TO BATTLE!", "your first battle is loading…", Theme.ACCENT, 6)
		else
			show("TRAINING COMPLETE!", "well fought, recruit  ·  your first battle is loading…", Theme.GOLD, 6)
		end
		-- the travel screen comes up straight away (the trip itself starts on the server)
		task.delay(a and 0.5 or 2.2, function()
			if _G.ShowTravel then _G.ShowTravel(a and "TO BATTLE" or "TRAINING COMPLETE", "YOUR FIRST BATTLE") end
		end)
	elseif what == "Done" then
		local l = LESSON[a]
		show("LESSON DONE!", (l and l.title or "") .. ((b and b:find("Marks")) and ("  ·  " .. (b:match("%+%d+ Marks.*") or "")) or ""), Theme.GOOD, 3)
	elseif what == "Spar" then
		if a == "start" then
			fighting = true
			countdown(b and ("vs " .. b) or nil, c)
		else
			fighting = false
			if a == "win" then
				show("VICTORY!", string.format("you beat the %s%s", b or "", (c or 0) > 0 and string.format("  ·  +%d Marks", c) or ""), Theme.GOLD, 4)
			elseif a == "lose" then
				show("DEFEATED", "the " .. (b or "bot") .. " wins this time. Try again!", Theme.BAD, 3.5)
			elseif a == "forfeit" then
				show("FORFEIT", "you left the ring", Theme.BAD, 3)
			end
		end
	elseif what == "Gauntlet" then
		if a == "start" then
			fighting = true
			show("THE GAUNTLET", string.format("survive as long as you can  ·  your best: wave %d", b or 0), Theme.ACCENT, 2.5)
		elseif a == "wave" then
			fighting = true
			waveLine.Text = string.format("THE GAUNTLET  ·  WAVE %d", b or 1)
			waveLine.Visible = true
			countdown(string.format("wave %d  ·  %s", b or 1, table.concat(c or {}, ", ")), d)
		elseif a == "cleared" then
			show(string.format("WAVE %d CLEARED", b or 0), "catch your breath…", Theme.GOOD, 2.6)
		elseif a == "over" then
			fighting = false
			waveLine.Visible = false
			local sub = string.format("you cleared %d wave%s  ·  best %d", b or 0, (b or 0) == 1 and "" or "s", c or 0)
			if (d or 0) > 0 then sub ..= string.format("  ·  NEW BEST! +%d Marks", d) end
			show(e == "forfeit" and "FORFEIT" or "THE GAUNTLET ENDS", sub, (d or 0) > 0 and Theme.GOLD or Theme.BAD, 4.5)
		end
	elseif what == "Practice" then
		if a == "start" then
			fighting = true
			countdown(string.format("%d %s%s", c or 1, b or "", (c or 1) > 1 and "s" or ""), d)
		elseif a == "won" then
			fighting = false
			show("ALL DOWN!", string.format("you beat %d %s%s. Again? Ask the Drill Master or the sign", c or 1, b or "", (c or 1) > 1 and "s" or ""), Theme.GOOD, 3.5)
		elseif a == "lost" then
			fighting = false
			show("DOWN YOU GO", "the bots won that one. Call them up again!", Theme.BAD, 3)
		elseif a == "cleared" then
			fighting = false
		end
	end
	refreshCard()
end)
refreshCard()
