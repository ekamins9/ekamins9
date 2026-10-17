--[[ HONOURS — a run of kills called out (ServerScriptService ▸ Game ▸ Honours sends them on
     ReplicatedStorage ▸ HonoursEvent):

       yours      big in gold, a third of the way down: DOUBLE KILL, WARLORD, STREAK BREAKER, with
                  the count under it and a gilt rule drawn out beneath; a horn for the big ones
       everyone's a line under the top of the screen: "65YAMAN IS A WARLORD · 8 IN A ROW", "… ENDS
                  …'S RUN" (not your own: you had yours)

     A new one takes the old one's place. Smaller on a phone. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("HonoursEvent")

local GOLD, PALE, INK = Color3.fromRGB(255, 212, 104), Color3.fromRGB(244, 236, 214), Color3.fromRGB(26, 18, 10)

local gui = Instance.new("ScreenGui")
gui.Name = "Honours"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 44
gui.Parent = player:WaitForChild("PlayerGui")
local fit = Instance.new("UIScale"); fit.Parent = gui
local function sizeIt() fit.Scale = Device.kind() == "phone" and 0.72 or 1 end
sizeIt()
Device.changed:Connect(sizeIt)

local function label(parent, size, font, color, stroke)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = font
	t.TextSize = size
	t.TextColor3 = color
	t.Text = ""
	local s = Instance.new("UIStroke"); s.Color = INK; s.Thickness = stroke; s.Parent = t
	t.Parent = parent
	return t, s
end

-- YOURS
local mine = Instance.new("Frame")
mine.BackgroundTransparency = 1
mine.AnchorPoint = Vector2.new(0.5, 0.5)
mine.Position = UDim2.fromScale(0.5, 0.3)
mine.Size = UDim2.fromOffset(700, 110)
mine.Visible = false
mine.Parent = gui
local pop = Instance.new("UIScale"); pop.Parent = mine
local title, titleStroke = label(mine, 46, Theme.FONT_TITLE, GOLD, 3)
title.Size = UDim2.new(1, 0, 0, 56)
local rule = Instance.new("Frame")
rule.AnchorPoint = Vector2.new(0.5, 0)
rule.Position = UDim2.new(0.5, 0, 0, 60)
rule.Size = UDim2.fromOffset(0, 3)
rule.BorderSizePixel = 0
rule.BackgroundColor3 = GOLD
rule.Parent = mine
local ruleGrad = Instance.new("UIGradient")
ruleGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})
ruleGrad.Parent = rule
local sub, subStroke = label(mine, 18, Theme.FONT, PALE, 2)
sub.Position = UDim2.new(0, 0, 0, 68)
sub.Size = UDim2.new(1, 0, 0, 24)

-- EVERYONE'S
local all = Instance.new("Frame")
all.BackgroundTransparency = 1
all.AnchorPoint = Vector2.new(0.5, 0)
all.Position = UDim2.new(0.5, 0, 0, 132)
all.Size = UDim2.fromOffset(760, 50)
all.Visible = false
all.Parent = gui
local allText, allStroke = label(all, 24, Theme.FONT_TITLE, PALE, 2.5)
allText.Size = UDim2.new(1, 0, 0, 30)
local allSub, allSubStroke = label(all, 15, Theme.FONT, GOLD, 1.5)
allSub.Position = UDim2.new(0, 0, 0, 30)
allSub.Size = UDim2.new(1, 0, 0, 18)

local function fade(objs, strokes, to, t)
	for _, o in ipairs(objs) do TweenService:Create(o, TweenInfo.new(t), {TextTransparency = to}):Play() end
	for _, s in ipairs(strokes) do TweenService:Create(s, TweenInfo.new(t), {Transparency = to}):Play() end
end

local mineToken, allToken = 0, 0
local function showMine(d)
	mineToken += 1
	local my = mineToken
	title.Text, sub.Text = d.title or "", d.sub or ""
	title.TextSize = d.big and 52 or 40
	mine.Visible = true
	fade({title, sub}, {titleStroke, subStroke}, 0, 0.08)
	pop.Scale = d.big and 1.5 or 1.25
	TweenService:Create(pop, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	rule.BackgroundTransparency = 0
	rule.Size = UDim2.fromOffset(0, 3)
	TweenService:Create(rule, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(d.big and 420 or 300, 3)}):Play()
	if d.big then
		local s = WarFX.sound("Horn", nil, {volume = 0.32, speed = 1.05})
		if s then task.delay(1.5, function() if s.Parent then TweenService:Create(s, TweenInfo.new(0.6), {Volume = 0}):Play() end end) end
	end
	task.delay(d.big and 2.2 or 1.6, function()
		if mineToken ~= my then return end
		fade({title, sub}, {titleStroke, subStroke}, 1, 0.45)
		TweenService:Create(rule, TweenInfo.new(0.45), {BackgroundTransparency = 1}):Play()
		task.delay(0.5, function() if mineToken == my then mine.Visible = false end end)
	end)
end
local function showAll(d)
	if d.who == player.UserId then return end
	allToken += 1
	local my = allToken
	allText.Text, allSub.Text = d.text or "", d.sub or ""
	all.Visible = true
	fade({allText, allSub}, {allStroke, allSubStroke}, 0, 0.2)
	task.delay(3.4, function()
		if allToken ~= my then return end
		fade({allText, allSub}, {allStroke, allSubStroke}, 1, 0.6)
		task.delay(0.65, function() if allToken == my then all.Visible = false end end)
	end)
end

event.OnClientEvent:Connect(function(kind, d)
	if type(d) ~= "table" then return end
	if kind == "Mine" then showMine(d) elseif kind == "All" then showAll(d) end
end)
