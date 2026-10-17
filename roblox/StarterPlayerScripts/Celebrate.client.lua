--[[ CELEBRATE — the big moments get a bit of fire (UIFX: embers, sparks, a flash):

       THE ROUND BEGINS   a match's round starts (State Intermission → Round): FIGHT!
                          slams down under the round's number and the mode, a war horn,
                          sparks, a shudder (not in the Courtyard or the training yard)
       LEVEL UP           your Level goes up (the attribute HubServer keeps): LEVEL 7 lands
                          in gold with a brass flourish and a shower of sparks — after the
                          round's result and any travel screen have gone
       A CLASS UNLOCKED   a level that opens a class (GameConfig.CLASSES unlock: the Archer and
                          the Mage at 5): a card after the banner, ARCHER & MAGE UNLOCKED, and
                          who teaches them in the Training Yard (in the Courtyard the menu's
                          pop-up then offers the trip: HubMenu HX.unlockPopup)
       BACK ON YOUR FEET  anyone (a player) spawning in a match rises out of a burst of
                          embers (local only; the Courtyard and the training yard don't)

     Test hooks (the command bar / MCP): _G.CelebrateRound(), _G.CelebrateLevel(n), _G.CelebrateUnlock(). ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Catalog    = require(ReplicatedStorage:WaitForChild("Catalog"))
local Theme      = require(ReplicatedStorage:WaitForChild("Theme"))
local UIFX       = require(ReplicatedStorage:WaitForChild("UIFX"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local round     = ReplicatedStorage:WaitForChild("Round")

local GOLD = Color3.fromRGB(255, 206, 90)
local WHITE = Color3.new(1, 1, 1)
local QUIET = {Hub = true, Tiltyard = true}

local gui = Instance.new("ScreenGui")
gui.Name = "Celebrate"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 2150      -- over the class screen (2000) and the Hub menu (2050), under the result (2200)
gui.Parent = playerGui

local function text(parent, t, size, font, color, y, h)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.new(0.9, 0, 0, h or size + 12)
	l.Font = font
	l.TextSize = size
	l.TextColor3 = color
	l.Text = t
	l.TextTransparency = 1
	l.ZIndex = 5
	local s = Instance.new("UIStroke")
	s.Color = Theme.OUTLINE
	s.Thickness = size >= 40 and 5 or 2.5
	s.Transparency = 1
	s.Parent = l
	l.Parent = parent
	return l, s
end
local function appear(l, s, dur)
	TweenService:Create(l, TweenInfo.new(dur or 0.25), {TextTransparency = 0}):Play()
	TweenService:Create(s, TweenInfo.new(dur or 0.25), {Transparency = 0.1}):Play()
end
-- a word that slams down from big (Quint in), then sparks fly from where it landed
local function slam(l, s, at, colors, from)
	local sc = Instance.new("UIScale")
	sc.Scale = from or 2.4
	sc.Parent = l
	appear(l, s, 0.15)
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Scale = 1}):Play()
	task.delay(0.3, function() UIFX.sparks(l.Parent, at, {n = 24, colors = colors, radius = 280, z = 6}) end)
end

--------------------------------------------------------------------
--  THE ROUND BEGINS
--------------------------------------------------------------------
local roundToken = 0
local function roundBegins()
	_G.FightBannerAt = os.clock()   -- (MatchIntro doesn't say the mode and map again)
	roundToken += 1
	local me = roundToken
	local mode = round:GetAttribute("Mode") or ""
	local def = GameConfig.MODES[mode]
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = gui
	local n = round:GetAttribute("Number") or 0
	local top = (def and def.roundsToWin and n > 0) and string.format("ROUND %d", n) or string.upper(round:GetAttribute("ModeName") or (def and def.name) or "")
	local map = round:GetAttribute("MapName") or round:GetAttribute("Map") or ""
	local upper, us = text(holder, top .. ((map ~= "" and not (def and def.roundsToWin)) and ("  ·  " .. string.upper(map)) or ""), 22, Theme.FONT_TITLE, GOLD, 0.24, 28)
	local word, ws = text(holder, "FIGHT!", 96, Theme.FONT_TITLE, WHITE, 0.31, 110)
	local band = Instance.new("Frame")
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = UDim2.fromScale(0.5, 0.29)
	band.Size = UDim2.new(1, 0, 0, 0)
	band.BackgroundColor3 = Color3.fromRGB(20, 14, 10)
	band.BackgroundTransparency = 0.35
	band.BorderSizePixel = 0
	band.ZIndex = 2
	band.Parent = holder
	local bf = Instance.new("UIGradient")
	bf.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.2),
		NumberSequenceKeypoint.new(0.75, 0.2), NumberSequenceKeypoint.new(1, 1)})
	bf.Parent = band
	TweenService:Create(band, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 170)}):Play()
	appear(upper, us, 0.3)
	UIFX.play("Horn")
	task.delay(0.2, function()
		slam(word, ws, Vector2.new(0.5, 0.31), "fire")
		task.delay(0.3, function()
			UIFX.flash(gui, Color3.fromRGB(255, 220, 160), 0.25, 0.5)
			UIFX.camShake(0.4, 4)
		end)
	end)
	task.delay(2.4, function()
		if roundToken ~= me then holder:Destroy(); return end
		UIFX.fadeOut(holder, 0.5, true)
	end)
end
local lastState = round:GetAttribute("State")
round:GetAttributeChangedSignal("State"):Connect(function()
	local st = round:GetAttribute("State")
	if lastState == "Intermission" and st == "Round" and not QUIET[round:GetAttribute("Mode") or ""] then
		task.delay(0.15, roundBegins)
	end
	lastState = st
end)

--------------------------------------------------------------------
--  LEVEL UP
--------------------------------------------------------------------
local function busy()
	for _, n in ipairs({"RoundResult", "TravelScreen", "Intro"}) do
		local g = playerGui:FindFirstChild(n)
		if g and g:IsA("ScreenGui") and g.Enabled then return true end
	end
	return false
end
-- the classes that open between two levels (GameConfig.CLASSES unlock = {level = n})
local function opened(from, to)
	local out = {}
	for _, id in ipairs(GameConfig.CLASS_ORDER) do
		local c = GameConfig.CLASSES[id]
		local at = c.unlock and c.unlock.level
		if at and from < at and to >= at then table.insert(out, c) end
	end
	return out
end
-- NEW CLASSES: a card under where the banner was, a while, then gone (no buttons: it may
-- come mid-fight; the Courtyard's menu offers the trip itself)
local function classesUnlocked(list)
	local names, who = {}, {}
	for _, c in ipairs(list) do
		table.insert(names, string.upper(c.name))
		local t = c.tutor and Catalog.DRILLS.tracks[c.tutor]
		if t then table.insert(who, string.format("%s teaches the %s", (t.master or ""):match("^([^,]+)") or t.master, c.name)) end
	end
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = gui
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.3)
	card.Size = UDim2.fromOffset(640, 224)
	card.BackgroundColor3 = Color3.fromRGB(20, 16, 10)
	card.BackgroundTransparency = 0.12
	card.BorderSizePixel = 0
	card.ZIndex = 2
	card.Parent = holder
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
	local st = Instance.new("UIStroke"); st.Color = GOLD; st.Thickness = 2; st.Transparency = 0.2; st.Parent = card
	local small, ss = text(holder, #list > 1 and "NEW CLASSES UNLOCKED" or "NEW CLASS UNLOCKED", 20, Theme.FONT_TITLE, GOLD, 0.3 - 0.075, 26)
	local big, bs = text(holder, table.concat(names, " & ") .. " UNLOCKED!", 46, Theme.FONT_TITLE, WHITE, 0.3 - 0.02, 56)
	local body, bds = text(holder, "Head to the TRAINING YARD (PLAY menu) to learn " .. (#list > 1 and "them" or "it") .. ": " .. table.concat(who, ", ")
		.. ". A few short lessons, and each one pays.", 17, Theme.FONT, WHITE, 0.3 + 0.07, 66)
	body.TextWrapped = true
	body.Size = UDim2.fromOffset(580, 66)
	for _, l in ipairs({small, big, body}) do l.ZIndex = 5 end
	local sc = Instance.new("UIScale"); sc.Scale = 0.7; sc.Parent = card
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
	UIFX.play("LevelUp")
	appear(small, ss, 0.25)
	slam(big, bs, Vector2.new(0.5, 0.28), "gold", 1.8)
	task.delay(0.4, function() appear(body, bds, 0.4) end)
	local stop = UIFX.embers(holder, {colors = "gold", rate = 0.05, life = {1.4, 2.2}, top = {0.18, 0.4}, z = 3})
	task.delay(8, function()
		stop()
		UIFX.fadeOut(holder, 0.7, true)
	end)
end
local function levelUp(level, from)
	-- (after the round's result, the travel screen, the welcome)
	local t0 = os.clock()
	while busy() and os.clock() - t0 < 20 do task.wait(0.25) end
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = gui
	local glow = Instance.new("Frame")
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.3)
	glow.Size = UDim2.fromOffset(0, 0)
	glow.BackgroundColor3 = GOLD
	glow.BackgroundTransparency = 0.55
	glow.BorderSizePixel = 0
	glow.ZIndex = 2
	glow.Parent = holder
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
	local gg = Instance.new("UIGradient")
	gg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.7, 0.85), NumberSequenceKeypoint.new(1, 1)})
	gg.Parent = glow
	-- (a dark band behind it: it reads over anything, a menu or a fight)
	local band = Instance.new("Frame")
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = UDim2.fromScale(0.5, 0.28)
	band.Size = UDim2.new(1, 0, 0, 0)
	band.BackgroundColor3 = Color3.fromRGB(20, 14, 6)
	band.BackgroundTransparency = 0.3
	band.BorderSizePixel = 0
	band.ZIndex = 1
	band.Parent = holder
	local bf = Instance.new("UIGradient")
	bf.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.15),
		NumberSequenceKeypoint.new(0.75, 0.15), NumberSequenceKeypoint.new(1, 1)})
	bf.Parent = band
	TweenService:Create(band, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 150)}):Play()
	local small, ss = text(holder, "LEVEL UP!", 24, Theme.FONT_TITLE, WHITE, 0.235, 30)
	local big, bs = text(holder, "LEVEL " .. tostring(level), 72, Theme.FONT_TITLE, GOLD, 0.3, 86)
	UIFX.play("LevelUp")
	TweenService:Create(glow, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(420, 420), BackgroundTransparency = 0.7}):Play()
	appear(small, ss, 0.3)
	slam(big, bs, Vector2.new(0.5, 0.3), "gold", 2)
	local stop = UIFX.embers(holder, {colors = "gold", rate = 0.04, life = {1.6, 2.6}, top = {0.1, 0.4}, z = 3})
	task.delay(2.6, function()
		stop()
		UIFX.fadeOut(holder, 0.6, true)
	end)
	-- a class opened at this level: its card once the banner's gone
	local list = from and opened(from, level) or {}
	if #list > 0 then task.delay(3.3, function() classesUnlocked(list) end) end
end
_G.CelebrateUnlock = function() classesUnlocked(opened(0, 99)) end
local lastLevel = nil
local function onLevel()
	local lv = player:GetAttribute("Level")
	if type(lv) ~= "number" then return end
	if lastLevel and lv > lastLevel then task.spawn(levelUp, lv, lastLevel) end
	lastLevel = lv
end
player:GetAttributeChangedSignal("Level"):Connect(onLevel)
onLevel()

--------------------------------------------------------------------
--  BACK ON YOUR FEET: a burst of embers where a player spawns (a match)
--------------------------------------------------------------------
local function burst(char)
	if QUIET[round:GetAttribute("Mode") or ""] then return end
	local root = char:WaitForChild("HumanoidRootPart", 5)
	if not root then return end
	task.wait(0.15)   -- (the server has put the body at its spawn by now)
	if not root.Parent then return end
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, -2.2, 0)
	a.Parent = root
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 214, 120), Color3.fromRGB(255, 110, 40))
	e.LightEmission = 1
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(0.8, 1.6)
	e.Speed = NumberRange.new(3, 9)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(0, 6, 0)
	e.Drag = 2
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = 0
	e.Parent = a
	e:Emit(46)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 180, 90)
	light.Range = 12
	light.Brightness = 3
	light.Parent = a
	TweenService:Create(light, TweenInfo.new(0.9, Enum.EasingStyle.Quad), {Brightness = 0}):Play()
	task.delay(2, function() a:Destroy() end)
end
local function watchPlayer(p)
	p.CharacterAdded:Connect(function(c) task.spawn(burst, c) end)
end
Players.PlayerAdded:Connect(watchPlayer)
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end

_G.CelebrateRound = roundBegins
_G.CelebrateLevel = function(n) task.spawn(levelUp, n or 7) end
