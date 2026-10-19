--[[ LISTS FLOW (client) — The Lists' rounds, start to finish (Game ▸ Modes ▸ Lists):
       • THE COUNTER under the top strip: ROUND n, your side's round wins and theirs as pips
         (first to RoundsToWin)
       • THE COUNTDOWN: each round starts held, the screen washed grey, 3 · 2 · 1 · FIGHT
         (FightAt, the server's clock)
       • BETWEEN ROUNDS: the screen grey again, who took the round, the counter, the next
         round's clock (on the same map: no vote)
       • THE END: VICTORY or DEFEAT over the winners on a podium in the middle of the arena,
         emoting (Lists:podium; the camera on PodiumCam), and RE-QUEUE / RETURN TO MENU
         (HubServer ListsRequeue / ListsLeave); left alone, everyone goes home after a while
     The round's big VICTORY band (RoundResult) and the intermission board (Scoreboard) stay out
     of the Lists. Reads the Round node: Mode, State, TimeLeft, ScoreA/B, RoundsToWin, ListsRound,
     FightAt, Winner, MatchOver, MatchWinner, PodiumCam. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local UIFX = require(ReplicatedStorage:WaitForChild("UIFX"))

local player = Players.LocalPlayer
local round = ReplicatedStorage:WaitForChild("Round")
local hubRemote = ReplicatedStorage:WaitForChild("HubRemote")

local GOLD = Color3.fromRGB(255, 206, 70)
local RED = Color3.fromRGB(255, 86, 96)
local DIM = Color3.fromRGB(200, 204, 214)
local WASH = Color3.fromRGB(58, 61, 70)
local WASH_T = 0.42             -- the grey's transparency (the arena still shows through)
local HOME_AFTER = 45           -- HubServer's MATCH_OVER_DELAY: the end screen's clock

local function inLists() return round:GetAttribute("Mode") == "Lists" end
local function serverNow() return workspace:GetServerTimeNow() end

--------------------------------------------------------------------
--  THE SCREEN
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ListsFlow"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 2250       -- over the spawn screen (2000), the board (2100), the round band (2200)
gui.Parent = player:WaitForChild("PlayerGui")

local function text(parent, size, font, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = font or Theme.FONT
	t.TextSize = size
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.45
	t.TextStrokeColor3 = Color3.new(0, 0, 0)
	t.Text = ""
	t.Parent = parent
	return t
end

-- PIPS: a side's round wins out of RoundsToWin
local function pipRow(parent, size)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.fromOffset(0, size)
	row.Parent = parent
	local ll = Instance.new("UIListLayout")
	ll.FillDirection = Enum.FillDirection.Horizontal
	ll.Padding = UDim.new(0, math.floor(size * 0.45))
	ll.VerticalAlignment = Enum.VerticalAlignment.Center
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Parent = row
	local pips = {}
	local function set(n, of, color, reverse)
		for i = #pips + 1, of do
			local p = Instance.new("Frame")
			p.Size = UDim2.fromOffset(size, size)
			p.BorderSizePixel = 0
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.5, 0); c.Parent = p
			local s = Instance.new("UIStroke"); s.Thickness = math.max(1.5, size / 9); s.Parent = p
			p.Parent = row
			pips[i] = p
		end
		for i, p in ipairs(pips) do
			p.Visible = i <= of
			-- (the far side fills from the middle out, like the near one)
			local lit
			if reverse then lit = i > of - n else lit = i <= n end
			p.BackgroundColor3 = lit and color or Color3.fromRGB(30, 32, 38)
			p.BackgroundTransparency = lit and 0 or 0.35
			p.UIStroke.Color = lit and color:Lerp(Color3.new(1, 1, 1), 0.35) or Color3.fromRGB(120, 124, 136)
			p.LayoutOrder = i
		end
	end
	return row, set
end

-- a whole counter: YOU ●●○  ROUND 2  ○●● THEM
local function counter(parent, size)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Size = UDim2.fromOffset(size * 30, size * 2.6)
	holder.Parent = parent
	local mid = text(holder, size * 1.05, Theme.FONT_TITLE, Color3.new(1, 1, 1))
	mid.AnchorPoint = Vector2.new(0.5, 0)
	mid.Position = UDim2.fromScale(0.5, 0)
	mid.Size = UDim2.fromOffset(size * 8, size * 1.4)
	local you = text(holder, size * 0.72, Theme.FONT, GOLD)
	you.AnchorPoint = Vector2.new(1, 0.5)
	you.Position = UDim2.new(0.5, -size * 4.2, 0, size * 0.7)
	you.Size = UDim2.fromOffset(size * 3, size)
	you.TextXAlignment = Enum.TextXAlignment.Right
	local them = text(holder, size * 0.72, Theme.FONT, RED)
	them.AnchorPoint = Vector2.new(0, 0.5)
	them.Position = UDim2.new(0.5, size * 4.2, 0, size * 0.7)
	them.Size = UDim2.fromOffset(size * 3, size)
	them.TextXAlignment = Enum.TextXAlignment.Left
	local leftRow, setLeft = pipRow(holder, size * 0.62)
	leftRow.AnchorPoint = Vector2.new(1, 0.5)
	leftRow.Position = UDim2.new(0.5, -size * 7.6, 0, size * 0.7)
	local rightRow, setRight = pipRow(holder, size * 0.62)
	rightRow.AnchorPoint = Vector2.new(0, 0.5)
	rightRow.Position = UDim2.new(0.5, size * 7.6, 0, size * 0.7)
	local function set(roundText, mine, theirs, of, youName, themName)
		mid.Text = roundText
		you.Text, them.Text = youName, themName
		setLeft(mine, of, GOLD, true)
		setRight(theirs, of, RED, false)
	end
	return holder, set
end

-- THE COUNTER (in play: under the top strip)
local hud, setHud = counter(gui, 22)
hud.Position = UDim2.new(0.5, 0, 0, 80)
hud.Visible = false

-- THE WASH: grey over the arena, the countdown or the round's result on it
local wash = Instance.new("Frame")
wash.Size = UDim2.fromScale(1, 1)
wash.BackgroundColor3 = WASH
wash.BackgroundTransparency = 1
wash.BorderSizePixel = 0
wash.Visible = false
wash.Parent = gui
do
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.15)})
	g.Rotation = 90
	g.Parent = wash
end
local washTop = text(wash, 30, Theme.FONT, DIM)
washTop.AnchorPoint = Vector2.new(0.5, 0.5)
washTop.Position = UDim2.fromScale(0.5, 0.3)
washTop.Size = UDim2.fromOffset(900, 40)
local washBig = text(wash, 150, Theme.FONT_TITLE, Color3.new(1, 1, 1))
washBig.AnchorPoint = Vector2.new(0.5, 0.5)
washBig.Position = UDim2.fromScale(0.5, 0.45)
washBig.Size = UDim2.fromOffset(1200, 170)
washBig.TextStrokeTransparency = 0.2
local bigScale = Instance.new("UIScale"); bigScale.Parent = washBig
local washCounter, setWashCounter = counter(wash, 30)
washCounter.Position = UDim2.fromScale(0.5, 0.57)
local washSub = text(wash, 24, Theme.FONT, DIM)
washSub.AnchorPoint = Vector2.new(0.5, 0.5)
washSub.Position = UDim2.fromScale(0.5, 0.7)
washSub.Size = UDim2.fromOffset(900, 34)

-- THE END: the verdict over the podium, the two buttons
local finale = Instance.new("Frame")
finale.Size = UDim2.fromScale(1, 1)
finale.BackgroundTransparency = 1
finale.Visible = false
finale.Parent = gui
local vignette = Instance.new("Frame")
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = Color3.new(0, 0, 0)
vignette.BackgroundTransparency = 0.25
vignette.BorderSizePixel = 0
vignette.Parent = finale
do
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.28, 1), NumberSequenceKeypoint.new(0.72, 1), NumberSequenceKeypoint.new(1, 0.05)})
	g.Rotation = 90
	g.Parent = vignette
end
local verdict = text(finale, 120, Theme.FONT_TITLE, GOLD)
verdict.AnchorPoint = Vector2.new(0.5, 0)
verdict.Position = UDim2.new(0.5, 0, 0, 40)
verdict.Size = UDim2.fromOffset(1200, 130)
verdict.TextStrokeTransparency = 0.15
local verdictScale = Instance.new("UIScale"); verdictScale.Parent = verdict
local verdictSub = text(finale, 26, Theme.FONT, DIM)
verdictSub.AnchorPoint = Vector2.new(0.5, 0)
verdictSub.Position = UDim2.new(0.5, 0, 0, 168)
verdictSub.Size = UDim2.fromOffset(1000, 34)
local buttons = Instance.new("Frame")
buttons.AnchorPoint = Vector2.new(0.5, 1)
buttons.Position = UDim2.new(0.5, 0, 1, -64)
buttons.Size = UDim2.fromOffset(620, 64)
buttons.BackgroundTransparency = 1
buttons.Parent = finale
do
	local ll = Instance.new("UIListLayout")
	ll.FillDirection = Enum.FillDirection.Horizontal
	ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ll.Padding = UDim.new(0, 20)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Parent = buttons
end
local homeLine = text(finale, 18, Theme.FONT_BODY, DIM)
homeLine.AnchorPoint = Vector2.new(0.5, 1)
homeLine.Position = UDim2.new(0.5, 0, 1, -30)
homeLine.Size = UDim2.fromOffset(800, 24)

local busy = false
local function button(label, color, textColor, order, op)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(290, 64)
	b.BackgroundColor3 = color
	b.AutoButtonColor = true
	b.Font = Theme.FONT
	b.TextSize = 24
	b.TextColor3 = textColor
	b.Text = label
	b.LayoutOrder = order
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = color:Lerp(Color3.new(1, 1, 1), 0.4); s.Thickness = 2; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = b
	b.Parent = buttons
	b.Activated:Connect(function()
		if busy then return end
		busy = true
		UIFX.play("Click")
		homeLine.Text = "travelling…"
		local ok, r = pcall(hubRemote.InvokeServer, hubRemote, op)
		if not (ok and type(r) == "table" and r.ok) then
			busy = false
			homeLine.Text = (ok and type(r) == "table" and r.msg) or "couldn't go just now: try again"
		end
	end)
	return b
end
local requeueBtn = button("RE-QUEUE", GOLD, Color3.fromRGB(40, 28, 6), 1, "ListsRequeue")
local menuBtn = button("RETURN TO MENU", Color3.fromRGB(44, 48, 58), Color3.new(1, 1, 1), 2, "ListsLeave")

--------------------------------------------------------------------
--  WHO'S WHO
--------------------------------------------------------------------
local mySide   -- "A" | "B": the side you fought on (teams may clear the moment a round ends)
local function sideNow()
	local t = player.Team
	if t then for k, d in pairs(GameConfig.TEAMS) do if d.name == t.Name then return k end end end
	local c = player.Character
	local a = c and c:GetAttribute("Team")
	return (a == "A" or a == "B") and a or nil
end
local function other(k) return k == "A" and "B" or "A" end
local function counts()
	local of = round:GetAttribute("RoundsToWin") or 3
	local a, b = round:GetAttribute("ScoreA") or 0, round:GetAttribute("ScoreB") or 0
	local me = mySide or "A"
	local mine = me == "A" and a or b
	local theirs = me == "A" and b or a
	return mine, theirs, of
end
local function names()
	local bracket = round:GetAttribute("Bracket") or ""
	if bracket == "1v1" or bracket == "" then return "YOU", "THEM" end
	return "YOUR SIDE", "THEIRS"
end

--------------------------------------------------------------------
--  THE FLOW
--------------------------------------------------------------------
local phase = nil          -- nil | "count" | "between" | "end"
local lastNumber = nil
local fightShown = false
local betweenRound = nil
local endedAt = nil
local matchEnded = false   -- (once the match is over, no more "between rounds", whatever the clock does)

-- (the death screen has had its moment: it gives way to ours, DeathScreen's "Lift")
local phaseAt = os.clock()
local function liftDeath(after)
	if os.clock() - phaseAt < after then return end
	local fade = player.PlayerGui:FindFirstChild("DeathFade")
	if fade and fade:GetAttribute("DeathScreen") and not fade:GetAttribute("Lift") then fade:SetAttribute("Lift", true) end
end
local function setWash(on, transparency)
	wash.Visible = on
	if on then wash.BackgroundTransparency = transparency or WASH_T end
end
local function pop(label, txt, color)
	label.Text = txt
	label.TextColor3 = color
	bigScale.Scale = 1.7
	label.TextTransparency = 0
	TweenService:Create(bigScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
end

-- the countdown: 3 · 2 · 1 on the grey, then FIGHT as the grey lifts
local function showCount(left)
	if phase ~= "count" then
		phase, lastNumber, fightShown = "count", nil, false
		setWash(true)
	end
	local mine, theirs, of = counts()
	local you, them = names()
	local n = round:GetAttribute("ListsRound") or 1
	washTop.Text = string.format("ROUND %d", n)
	setWashCounter(string.format("%d – %d", mine, theirs), mine, theirs, of, you, them)
	washCounter.Visible = true
	if left > 0 then
		local num = math.clamp(math.ceil(left), 1, 9)
		if num ~= lastNumber then
			lastNumber = num
			pop(washBig, tostring(num), Color3.new(1, 1, 1))
			UIFX.play("Tick")
		end
		washSub.Text = (mine + 1 >= of and theirs + 1 >= of) and "DECIDING ROUND" or string.format("FIRST TO %d", of)
	else
		if not fightShown then
			fightShown = true
			pop(washBig, "FIGHT!", GOLD)
			UIFX.play("Horn")
			washSub.Text = ""
			TweenService:Create(wash, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
		end
	end
end

-- between rounds: who took it, the counter, the next round's clock
local function showBetween()
	local n = round:GetAttribute("ListsRound") or 1
	if phase ~= "between" or betweenRound ~= n then
		phase, betweenRound, phaseAt = "between", n, os.clock()
		setWash(true)
		local w = round:GetAttribute("Winner") or ""
		local mine = mySide and GameConfig.TEAMS[mySide] and GameConfig.TEAMS[mySide].name
		if w == "" then
			pop(washBig, "DRAW", DIM)
			UIFX.play("Whoosh")
		elseif mine and w == mine then
			pop(washBig, "ROUND WON", GOLD)
			UIFX.play("Rise")
		else
			pop(washBig, "ROUND LOST", RED)
			UIFX.play("Fallen")
		end
		washTop.Text = string.format("ROUND %d", n)
	end
	local mine, theirs, of = counts()
	local you, them = names()
	setWashCounter(string.format("%d – %d", mine, theirs), mine, theirs, of, you, them)
	washCounter.Visible = true
	washSub.Text = string.format("NEXT ROUND IN %d", round:GetAttribute("TimeLeft") or 0)
	liftDeath(1.6)
end

-- (the end is a picture: the in-play HUD steps aside for it, and comes back after)
local HIDE_AT_END = {"Hotbar", "HUD", "PowerHUD", "StanceHint", "LockOnHUD", "Threats", "Objectives", "Honours", "RiposteCue",
	"EmoteHint", "Pastimes", "Scoreboard", "Adventure", "Skyfall", "RaidInventory", "Duels", "HitArcs"}
local hiddenGuis = {}
local function hudAside(on)
	local pg = player.PlayerGui
	if on then
		for _, name in ipairs(HIDE_AT_END) do
			local g = pg:FindFirstChild(name)
			if g and g:IsA("ScreenGui") and g.Enabled then g.Enabled = false; hiddenGuis[g] = true end
		end
	else
		for g in pairs(hiddenGuis) do if g.Parent then g.Enabled = true end end
		hiddenGuis = {}
	end
end

-- the end: the verdict over the podium, and the way home
local function showEnd()
	if phase ~= "end" then
		phase = "end"
		endedAt, phaseAt = os.clock(), os.clock()
		busy = false
		setWash(false)
		finale.Visible = true
		local winner = round:GetAttribute("MatchWinner") or ""
		local mine, theirs = counts()
		local won = mySide ~= nil and winner == mySide
		if winner == "" then
			verdict.Text, verdict.TextColor3 = "A DRAW", DIM
		elseif mySide == nil then
			local d = GameConfig.TEAMS[winner]
			verdict.Text, verdict.TextColor3 = string.upper(d and d.name or winner) .. " WINS", Color3.new(1, 1, 1)
		else
			verdict.Text, verdict.TextColor3 = won and "VICTORY" or "DEFEAT", won and GOLD or RED
		end
		verdictSub.Text = string.format("%d – %d  ·  %s", mine, theirs, won and "THE MATCH IS YOURS" or (winner == "" and "NOBODY TAKES IT" or "THE MATCH IS THEIRS"))
		verdictScale.Scale = 1.8
		verdict.TextTransparency = 1
		TweenService:Create(verdictScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Scale = 1}):Play()
		TweenService:Create(verdict, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
		if won then
			UIFX.play("LevelUp")
			task.delay(0.3, function() UIFX.sparks(finale, Vector2.new(0.5, 0.12), {n = 34, colors = "gold", radius = 360, z = 6}) end)
		else
			UIFX.play("Fallen")
		end
	end
	liftDeath(1.2)
	hudAside(true)
	local left = math.max(0, math.ceil(HOME_AFTER - (os.clock() - (endedAt or os.clock()))))
	if not busy then homeLine.Text = string.format("back to the Courtyard in %d", left) end
end

local function clear()
	if phase == "end" then finale.Visible = false; hudAside(false) end
	if phase then setWash(false) end
	phase = nil
end

RunService.RenderStepped:Connect(function()
	if not inLists() then
		hud.Visible = false
		if phase then clear() end
		finale.Visible = false
		if next(hiddenGuis) then hudAside(false) end
		mySide, matchEnded = nil, false
		return
	end
	local st = round:GetAttribute("State")
	local over = round:GetAttribute("MatchOver") == true
	if st == "Round" then
		local s = sideNow()
		if s then mySide = s end
	end
	-- the counter in play
	local mine, theirs, of = counts()
	local you, them = names()
	setHud(string.format("ROUND %d", round:GetAttribute("ListsRound") or 1), mine, theirs, of, you, them)
	if over and st == "Intermission" then
		hud.Visible = false
		matchEnded = true
		showEnd()
	elseif st == "Round" then
		if phase == "end" then finale.Visible = false; hudAside(false); phase = nil end
		local left = (round:GetAttribute("FightAt") or 0) - serverNow()
		if left > -0.9 then
			hud.Visible = false
			showCount(left)
		else
			if phase then clear() end
			hud.Visible = true
		end
	elseif st == "Intermission" and not matchEnded then
		hud.Visible = false
		showBetween()
	else
		hud.Visible = false
		if phase then clear() end
	end
end)

-- THE END'S CAMERA: on the podium once it's up, drifting a little; the cursor free for the buttons
local cam = workspace.CurrentCamera
RunService:BindToRenderStep("ListsFinale", Enum.RenderPriority.Last.Value + 950, function()
	if phase ~= "end" then return end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	local at = round:GetAttribute("PodiumCam")
	if typeof(at) ~= "CFrame" then return end
	cam = workspace.CurrentCamera
	local t = os.clock() - (endedAt or os.clock())
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = at * CFrame.new(math.sin(t * 0.22) * 1.6, math.sin(t * 0.17) * 0.3, -math.min(t, 6) * 0.25)
end)
-- (out of the end screen: the camera back to the player's)
round:GetAttributeChangedSignal("MatchOver"):Connect(function()
	if round:GetAttribute("MatchOver") ~= true then
		local c = workspace.CurrentCamera
		if c then c.CameraType = Enum.CameraType.Custom end
	end
end)
