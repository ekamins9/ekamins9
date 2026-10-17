--[[ HONOR DUELS (client) — the Courtyard's challenges and bouts on your screen (Hub ▸ Duels runs
     them; its header has the rules):
       • asked: a card, "<NAME> CHALLENGES YOU", ACCEPT [Y] / DECLINE [N] (or tap), a fuse burning
         down its 15 seconds
       • every bout, for everyone near: a ring of gold light round it on the ground, posts of
         flame at its edge, and a board over it (the two names and the touches)
       • yours: 3 · 2 · 1 · FIGHT!, a word for every touch (yours gold, theirs red), and at the end
         VICTORY / DEFEAT / A DRAW with the why
     Nothing here decides anything: it only asks (DuelEvent "Answer"). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local UIFX = require(ReplicatedStorage:WaitForChild("UIFX"))

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("DuelEvent", 1e9)
local RING_R = 20
local GOLD = Color3.fromRGB(255, 206, 92)
local RED = Color3.fromRGB(255, 96, 80)

local gui = Instance.new("ScreenGui")
gui.Name = "Duels"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 35
gui.Parent = player:WaitForChild("PlayerGui")

local function text(parent, str, size, font, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text, t.TextSize, t.Font, t.TextColor3 = str, size, font or Theme.FONT, color or Color3.new(1, 1, 1)
	t.Size = UDim2.new(1, 0, 0, size + 6)
	local s = Instance.new("UIStroke"); s.Thickness = size >= 30 and 2.5 or 1.5; s.Color = Color3.new(0, 0, 0); s.Transparency = 0.25; s.Parent = t
	t.Parent = parent
	return t
end

--------------------------------------------------------------------
--  THE CHALLENGE CARD
--------------------------------------------------------------------
local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, -200)
card.Size = UDim2.fromOffset(440, 156)
card.BackgroundColor3 = Theme.GLASS
card.BackgroundTransparency = 0.08
card.Visible = false
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
do local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.2; s.Parent = card end
local kicker = text(card, "AN HONOR DUEL", 13, Theme.FONT, GOLD); kicker.Position = UDim2.fromOffset(0, 12)
local who = text(card, "", 26, Theme.FONT_TITLE); who.Position = UDim2.fromOffset(0, 30)
local rules = text(card, "First to three clean touches. No wounds, no falls.", 15, Theme.FONT_BODY, Color3.fromRGB(214, 220, 236)); rules.Position = UDim2.fromOffset(0, 64)
local function button(label, color, x)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0.5, 0)
	b.Position = UDim2.new(x, 0, 0, 96)
	b.Size = UDim2.fromOffset(176, 40)
	b.BackgroundColor3 = color
	b.Text, b.Font, b.TextSize, b.TextColor3 = label, Theme.FONT_TITLE, 18, Color3.new(1, 1, 1)
	b.AutoButtonColor = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	b.Parent = card
	return b
end
local yes = button("ACCEPT  [Y]", Theme.GREEN, 0.27)
local no = button("DECLINE  [N]", Theme.RED, 0.73)
local fuse = Instance.new("Frame")
fuse.BackgroundColor3 = GOLD
fuse.BorderSizePixel = 0
fuse.AnchorPoint = Vector2.new(0.5, 1)
fuse.Position = UDim2.new(0.5, 0, 1, -6)
fuse.Size = UDim2.new(1, -28, 0, 3)
fuse.Parent = card

local asked = nil   -- {token, until}
local function closeCard()
	asked = nil
	TweenService:Create(card, TweenInfo.new(0.25), {Position = UDim2.new(0.5, 0, 0, -200)}):Play()
	task.delay(0.26, function() if not asked then card.Visible = false end end)
end
local function answer(ok)
	if not asked then return end
	event:FireServer("Answer", ok)
	UIFX.play(ok and "Click" or "Back")
	closeCard()
end
yes.Activated:Connect(function() answer(true) end)
no.Activated:Connect(function() answer(false) end)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not asked then return end
	if input.KeyCode == Enum.KeyCode.Y or input.KeyCode == Enum.KeyCode.DPadUp then answer(true)
	elseif input.KeyCode == Enum.KeyCode.N or input.KeyCode == Enum.KeyCode.DPadDown then answer(false) end
end)
local function ask(d)
	who.Text = string.upper(tostring(d.from or "Someone")) .. " CHALLENGES YOU"
	local token = {}
	asked = {token = token, untilT = os.clock() + 15}
	card.Visible = true
	card.Position = UDim2.new(0.5, 0, 0, -200)
	TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 110)}):Play()
	UIFX.play("Horn")
	task.spawn(function()
		while asked and asked.token == token do
			local left = asked.untilT - os.clock()
			fuse.Size = UDim2.new(math.clamp(left / 15, 0, 1), -28, 0, 3)
			if left <= 0 then closeCard(); return end
			task.wait(0.05)
		end
	end)
end

--------------------------------------------------------------------
--  THE BIG WORDS (yours: the count, a touch, the end)
--------------------------------------------------------------------
local big = text(gui, "", 64, Theme.FONT_TITLE)
big.AnchorPoint = Vector2.new(0.5, 0.5)
big.Position = UDim2.fromScale(0.5, 0.3)
big.Size = UDim2.new(1, 0, 0, 80)
big.TextTransparency = 1
big:FindFirstChildOfClass("UIStroke").Transparency = 1
local small = text(gui, "", 20, Theme.FONT)
small.AnchorPoint = Vector2.new(0.5, 0.5)
small.Position = UDim2.new(0.5, 0, 0.3, 50)
small.TextTransparency = 1
small:FindFirstChildOfClass("UIStroke").Transparency = 1
local bigToken = 0
local function say(word, color, sub, hold)
	bigToken += 1
	local tok = bigToken
	big.Text, big.TextColor3 = word, color or Color3.new(1, 1, 1)
	small.Text = sub or ""
	for _, t in ipairs({big, small}) do
		t.TextTransparency = 0
		t:FindFirstChildOfClass("UIStroke").Transparency = 0.25
	end
	big.TextSize = 80
	TweenService:Create(big, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 64}):Play()
	task.delay(hold or 0.8, function()
		if bigToken ~= tok then return end
		for _, t in ipairs({big, small}) do
			TweenService:Create(t, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
			TweenService:Create(t:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.35), {Transparency = 1}):Play()
		end
	end)
end

--------------------------------------------------------------------
--  THE RING (everyone's): gold light on the ground, flames at its edge, a board over it
--------------------------------------------------------------------
local rings = {}   -- [key] = {model, board, names, score}
local function keyOf(a, b) return tostring(math.min(a, b)) .. ":" .. tostring(math.max(a, b)) end
local function buildRing(d)
	local key = keyOf(d.a, d.b)
	if rings[key] then rings[key].model:Destroy() end
	local m = Instance.new("Model")
	m.Name = "DuelRing"
	local c = d.centre
	local function part(size, cf, color, mat, tr)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.CastShadow = false
		p.Size, p.CFrame, p.Color, p.Material, p.Transparency = size, cf, color, mat, tr or 0
		p.Parent = m
		return p
	end
	-- the ring on the ground: a band of gold light (segments round the circle)
	local n = 40
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		local p = c + Vector3.new(math.cos(a) * RING_R, 0.08, math.sin(a) * RING_R)
		part(Vector3.new(0.5, 0.06, RING_R * 2 * math.pi / n + 0.1), CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))), GOLD, Enum.Material.Neon, 0.35)
	end
	-- posts of flame at its edge
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + math.pi / 6
		local p = c + Vector3.new(math.cos(a) * (RING_R + 1.2), 0, math.sin(a) * (RING_R + 1.2))
		part(Vector3.new(0.5, 4, 0.5), CFrame.new(p + Vector3.new(0, 2, 0)), Color3.fromRGB(70, 48, 32), Enum.Material.Wood)
		local bowl = part(Vector3.new(1.4, 0.5, 1.4), CFrame.new(p + Vector3.new(0, 4.2, 0)), Color3.fromRGB(52, 50, 56), Enum.Material.Metal)
		local f = Instance.new("Fire"); f.Size = 3; f.Heat = 6; f.Parent = bowl
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 170, 90); l.Range = 14; l.Brightness = 1.2; l.Parent = bowl
	end
	-- the board over the middle
	local anchor = part(Vector3.new(0.2, 0.2, 0.2), CFrame.new(c + Vector3.new(0, 11, 0)), GOLD, Enum.Material.Neon, 1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(340, 86)
	bb.LightInfluence = 0
	bb.MaxDistance = 220
	bb.Adornee = anchor
	bb.Parent = anchor
	local k = text(bb, "AN HONOR DUEL", 14, Theme.FONT, GOLD)
	local names = text(bb, "", 24, Theme.FONT_TITLE); names.Position = UDim2.fromOffset(0, 18)
	local score = text(bb, "", 30, Theme.FONT_TITLE, GOLD); score.Position = UDim2.fromOffset(0, 48)
	names.Text = string.upper(d.aName or "") .. "   vs   " .. string.upper(d.bName or "")
	score.Text = "0  —  0"
	m.Parent = workspace
	rings[key] = {model = m, names = names, score = score, kicker = k}
	return rings[key]
end

local function mine(d) return d.a == player.UserId or d.b == player.UserId end

event.OnClientEvent:Connect(function(what, d)
	if what == "Count" then
		say(tostring(d), Color3.new(1, 1, 1), nil, 0.5)
		UIFX.play("Tick")
		return
	end
	d = type(d) == "table" and d or {}
	if what == "Ask" then
		ask(d)
	elseif what == "Start" then
		if typeof(d.centre) == "Vector3" then buildRing(d) end
		if mine(d) then
			local foe = d.a == player.UserId and d.bName or d.aName
			say("SALUTE", GOLD, "an honor duel with " .. tostring(foe) .. "  ·  first to three touches", 1.4)
		end
	elseif what == "Live" then
		say("FIGHT!", GOLD, nil, 0.7)
		UIFX.play("Horn")
	elseif what == "Score" then
		local r = rings[keyOf(d.a, d.b)]
		if r then r.score.Text = string.format("%d  —  %d", d.sa or 0, d.sb or 0) end
		if mine(d) then
			local meA = d.a == player.UserId
			local my, their = meA and d.sa or d.sb, meA and d.sb or d.sa
			if d.by == player.UserId then say("TOUCH!", GOLD, string.format("%d  —  %d", my, their), 0.7); UIFX.play("Rise")
			else say("TOUCHED", RED, string.format("%d  —  %d", my, their), 0.7); UIFX.play("Thud") end
		end
	elseif what == "End" then
		local key = keyOf(d.a, d.b)
		local r = rings[key]
		local winName = d.winner == d.a and d.aName or (d.winner == d.b and d.bName or nil)
		if r then
			r.kicker.Text = "THE DUEL IS OVER"
			r.score.Text = winName and (string.upper(winName) .. " WINS") or "A DRAW"
			task.delay(4, function()
				if rings[key] == r then rings[key] = nil end
				r.model:Destroy()
			end)
		end
		if mine(d) then
			local why = d.why ~= "touches" and d.why or ""
			local meA = d.a == player.UserId
			local my, their = meA and d.sa or d.sb, meA and d.sb or d.sa
			local line = string.format("%d  —  %d", my or 0, their or 0) .. (why ~= "" and ("  ·  " .. why) or "")
			if d.winner == player.UserId then say("VICTORY", GOLD, line, 2.2); UIFX.play("LevelUp")
			elseif d.winner == 0 then say("A DRAW", Color3.new(1, 1, 1), line, 2.2)
			else say("DEFEAT", RED, line, 2.2); UIFX.play("Fallen") end
		end
	end
end)

-- (out of the Courtyard: any rings go)
ReplicatedStorage:WaitForChild("Round"):GetAttributeChangedSignal("Mode"):Connect(function()
	for k, r in pairs(rings) do r.model:Destroy(); rings[k] = nil end
	if asked then closeCard() end
end)
