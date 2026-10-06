--[[ TRAINING (client) — the training yard's screens (Game ▸ Training on the
     server). Only in the Tiltyard mode:
       • the lesson card (right side): the Drill Master's current lesson, in
         your own key binds, and how far along you are
       • the lesson board (E at the Drill Master): every lesson, ticked when done
       • his speech bubble, saying the lesson
       • the ring board (E at the ring sign): Squire, Knight or Champion,
         your wins, what a win pays; then a 3-2-1 and the result ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("TrainingRemote")
local round = ReplicatedStorage:WaitForChild("Round")
local D = Catalog.DRILLS
local LESSON = {}
for i, l in ipairs(D.lessons) do LESSON[l.id] = l; l.index = i end

local WHITE = Color3.new(1, 1, 1)
local function inYard() return round:GetAttribute("Mode") == "Tiltyard" end

-- a key bind's name, the way a player says it
local NICE = {MouseButton1 = "LEFT MOUSE", MouseButton3 = "MIDDLE MOUSE", MouseWheelUp = "SCROLL UP", MouseWheelDown = "SCROLL DOWN",
	LeftAlt = "LEFT ALT", RightAlt = "RIGHT ALT", LeftShift = "LEFT SHIFT", LeftControl = "LEFT CTRL", Space = "SPACE"}
local function keyName(action)
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
--  THE LESSON CARD
--------------------------------------------------------------------
local card = panel(gui, UDim2.fromOffset(330, 168), UDim2.new(1, -346, 0.5, -84))
card.Visible = false
local cardHead = text(card, "DRILL MASTER  ·  LESSON", 12, Theme.DIM); cardHead.Position = UDim2.fromOffset(14, 10); cardHead.Size = UDim2.new(1, -28, 0, 14)
local cardTitle = text(card, "", 24); cardTitle.Position = UDim2.fromOffset(14, 26); cardTitle.Size = UDim2.new(1, -28, 0, 28)
local cardText = text(card, "", 14, WHITE, Theme.FONT); cardText.Position = UDim2.fromOffset(14, 56); cardText.Size = UDim2.new(1, -28, 0, 60); cardText.TextYAlignment = Enum.TextYAlignment.Top
local barBack = Instance.new("Frame"); barBack.BackgroundColor3 = Color3.fromRGB(8, 10, 18); barBack.BackgroundTransparency = 0.2; barBack.BorderSizePixel = 0
barBack.Position = UDim2.new(0, 14, 1, -40); barBack.Size = UDim2.new(1, -120, 0, 18); barBack.Parent = card
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 8)
local bar = Instance.new("Frame"); bar.BackgroundColor3 = Theme.GREEN; bar.BorderSizePixel = 0; bar.Size = UDim2.fromScale(0, 1); bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
local barText = text(barBack, "", 13); barText.Size = UDim2.fromScale(1, 1); barText.TextXAlignment = Enum.TextXAlignment.Center
local allB = button(card, "LESSONS", Theme.BLUE, UDim2.fromOffset(92, 30), UDim2.new(1, -104, 1, -46))

-- the Drill Master's bubble (local: he tells each of you your own lesson)
local bubble = Instance.new("BillboardGui")
bubble.Name = "DrillBubble"
bubble.Size = UDim2.fromOffset(300, 90)
bubble.StudsOffsetWorldSpace = Vector3.new(0, 4.4, 0)
bubble.MaxDistance = 60
bubble.AlwaysOnTop = false
bubble.Parent = gui
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
	card.Visible = yard and l ~= nil and not (player.PlayerGui:FindFirstChild("HubMenu") and player.PlayerGui.HubMenu.Enabled)
	bubble.Enabled = yard
	bubble.Adornee = yard and masterHead() or nil
	if not l then
		local done = 0
		for _ in (player:GetAttribute("DrillsDone") or ""):gmatch("[^,]+") do done += 1 end
		bubbleText.Text = done >= #D.lessons and "You've learned all I can teach. Go and prove it in the ring!" or "Come here, recruit. Press E and I'll teach you."
		return
	end
	local n, goal = player:GetAttribute("DrillProgress") or 0, player:GetAttribute("DrillGoal") or l.goal
	cardHead.Text = string.format("DRILL MASTER  ·  LESSON %d / %d", l.index, #D.lessons)
	cardTitle.Text = string.upper(l.title)
	cardText.Text = say(l.text)
	bar.Size = UDim2.fromScale(math.clamp(n / math.max(goal, 1), 0, 1), 1)
	barText.Text = string.format("%d / %d", n, goal)
	bubbleText.Text = say(l.text)
end
for _, a in ipairs({"Drill", "DrillProgress", "DrillGoal", "DrillsDone"}) do player:GetAttributeChangedSignal(a):Connect(refreshCard) end
round:GetAttributeChangedSignal("Mode"):Connect(refreshCard)
task.spawn(function() while true do task.wait(1); refreshCard() end end)

--------------------------------------------------------------------
--  BOARDS (a centred pop-up)
--------------------------------------------------------------------
local shade = Instance.new("TextButton"); shade.Text = ""; shade.AutoButtonColor = false; shade.BackgroundColor3 = Theme.BACK; shade.BackgroundTransparency = 0.45
shade.Size = UDim2.fromScale(1, 1); shade.Visible = false; shade.ZIndex = 5; shade.Parent = gui
local board = panel(shade, UDim2.fromOffset(620, 520), UDim2.new(0.5, -310, 0.5, -260))
board.ZIndex = 6
local function closeBoard() shade.Visible = false; for _, c in ipairs(board:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end end
shade.MouseButton1Click:Connect(closeBoard)
local function openBoard(titleText)
	closeBoard()
	shade.Visible = true
	local t = text(board, titleText, 28); t.Position = UDim2.fromOffset(20, 14); t.Size = UDim2.new(1, -120, 0, 34); t.ZIndex = 7
	local x = button(board, "X", Theme.RED, UDim2.fromOffset(44, 40), UDim2.new(1, -58, 0, 12)); x.ZIndex = 7
	x.MouseButton1Click:Connect(closeBoard)
	return board
end
-- the mouse is free while a board is up
game:GetService("RunService").RenderStepped:Connect(function()
	if shade.Visible then UserInputService.MouseBehavior = Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled = true end
end)

local function lessonBoard()
	local b = openBoard("THE DRILL MASTER'S LESSONS")
	local done = {}
	for id in (player:GetAttribute("DrillsDone") or ""):gmatch("[^,]+") do done[id] = true end
	local current = player:GetAttribute("Drill") or ""
	local pay = Catalog.ECONOMY.earn and Catalog.ECONOMY.earn.drill
	local sub = text(b, pay and string.format("Each lesson pays %d Marks and %d XP the first time.", pay.marks or 0, pay.xp or 0) or "", 13, Theme.DIM, Theme.FONT)
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
allB.MouseButton1Click:Connect(lessonBoard)

local FOES = {
	{skill = "Squire", blurb = "Slow to react, rarely parries. A good first fight."},
	{skill = "Knight", blurb = "Parries half your swings, feints now and then, kicks a turtle."},
	{skill = "Champion", blurb = "Reads your windup, parries most of it, feints and morphs. Good luck."},
}
local function ringBoard(rec)
	local b = openBoard("THE SPARRING RING")
	local sub = text(b, "Pick your opponent. Three, two, one, then it's to the death. Leave the ring and you forfeit.", 13, Theme.DIM, Theme.FONT)
	sub.Position = UDim2.fromOffset(20, 50); sub.Size = UDim2.new(1, -40, 0, 34); sub.ZIndex = 7
	for i, f in ipairs(FOES) do
		local wins = rec and rec[f.skill] or 0
		local pay = D.spar[f.skill] or {}
		local c = panel(b, UDim2.new(1 / 3, -20, 0, 330), UDim2.new((i - 1) / 3, 14, 0, 100)); c.ZIndex = 7
		local col = ({Theme.GREEN, Theme.BLUE, Theme.RED})[i]
		local t1 = text(c, string.upper(f.skill), 24, col); t1.Position = UDim2.fromOffset(12, 12); t1.Size = UDim2.new(1, -24, 0, 30); t1.ZIndex = 8
		local t2 = text(c, f.blurb, 14, WHITE, Theme.FONT); t2.Position = UDim2.fromOffset(12, 48); t2.Size = UDim2.new(1, -24, 0, 110); t2.TextYAlignment = Enum.TextYAlignment.Top; t2.ZIndex = 8
		local t3 = text(c, string.format("YOUR WINS: %d", wins), 15, Theme.ACCENT); t3.Position = UDim2.fromOffset(12, 168); t3.Size = UDim2.new(1, -24, 0, 20); t3.ZIndex = 8
		local t4 = text(c, wins == 0 and string.format("first win: %d Marks", pay.first or 0) or string.format("a win: %d Marks", pay.again or 0), 13, Theme.DIM, Theme.FONT)
		t4.Position = UDim2.fromOffset(12, 192); t4.Size = UDim2.new(1, -24, 0, 18); t4.ZIndex = 8
		local go = button(c, "FIGHT", col, UDim2.new(1, -24, 0, 50), UDim2.new(0, 12, 1, -62)); go.ZIndex = 8
		go.MouseButton1Click:Connect(function() remote:FireServer("Spar", f.skill); closeBoard() end)
	end
end

--------------------------------------------------------------------
--  BANNERS (a countdown, a result)
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

remote.OnClientEvent:Connect(function(what, a, b, c, d)
	if what == "Lessons" then lessonBoard()
	elseif what == "Ring" then ringBoard(a)
	elseif what == "Progress" then refreshCard()
	elseif what == "Done" then
		local l = LESSON[a]
		show("LESSON DONE!", (l and l.title or "") .. ((b and b:find("Marks")) and ("  ·  " .. (b:match("%+%d+ Marks.*") or "")) or ""), Theme.GOOD, 3)
	elseif what == "Spar" then
		if a == "start" then
			task.spawn(function()
				for _, n in ipairs({"3", "2", "1"}) do show(n, b and ("vs " .. b) or nil, WHITE, 0.95); task.wait(1) end
				show("FIGHT!", nil, Theme.RED, 1.2)
			end)
		elseif a == "win" then
			show("VICTORY!", string.format("you beat the %s%s", b or "", (c or 0) > 0 and string.format("  ·  +%d Marks", c) or ""), Theme.GOLD, 4)
		elseif a == "lose" then
			show("DEFEATED", "the " .. (b or "bot") .. " wins this time. Try again!", Theme.BAD, 3.5)
		elseif a == "forfeit" then
			show("FORFEIT", "you left the ring", Theme.BAD, 3)
		end
	end
end)
refreshCard()
