--[[ DEATH SCREEN — falling is a moment, then the way back: never a black screen.

       the fall    the world drains of colour, red closes in at the edges, a low boom,
                   and the word lands: YOU HAVE FALLEN (BEHEADED, SHOT THROUGH THE HEAD,
                   YOU BLED OUT, BETRAYED…) with who did it and with what (the kill feed's
                   own entry: KillFeedRemote), while CameraRig holds the camera in your head
       the wait    a dark veil with embers rising, and what comes next with a countdown:
                   BACK IN THE FIGHT IN 3 · BACK TO THE COURTYARD · BACK ON YOUR FEET ·
                   THE NEXT WAVE BRINGS YOU BACK · OUT FOR THIS ROUND
       the rise    a new body: a golden flash, a blade drawn, the veil lifts. The class
                   screen or the menu opening lifts it too (LoadoutMenu sets "Lift")

     The ScreenGui is still "DeathFade" (HubMenu and LoadoutMenu look for it). It holds
     the class screen back until the fall has been seen (attribute HoldUntil, os.clock()). ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Theme      = require(ReplicatedStorage:WaitForChild("Theme"))
local UIFX       = require(ReplicatedStorage:WaitForChild("UIFX"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local round     = ReplicatedStorage:WaitForChild("Round")

local HOLD = 2.2          -- the fall (CameraRig's death camera holds as long)
local MOMENT = 2.0        -- the class screen waits at least this long after you fall
local RED = Color3.fromRGB(255, 86, 76)
local GOLD = Color3.fromRGB(255, 206, 90)
local WHITE = Color3.new(1, 1, 1)

-- what the kill was, for the title (the feed's kinds)
local TITLE = {headslash = "BEHEADED", headshot = "SHOT THROUGH THE HEAD", arrow = "SHOT DOWN", kick = "KICKED TO DEATH",
	stab = "RUN THROUGH", facestab = "RUN THROUGH", bleed = "YOU BLED OUT", head = "BRAINED"}

local current       -- the screen up now
local lastKill      -- {entry, at}: the feed's entry for our death (it can land a beat before Died)

local function teamColour(key)
	local d = key and key ~= "" and GameConfig.TEAMS[key]
	return d and d.rgb:Lerp(WHITE, 0.3) or WHITE
end

-- what comes next, and how long (nil = no countdown)
local function nextStep()
	local mode = round:GetAttribute("Mode") or ""
	local def = GameConfig.MODES[mode]
	local delay = def and def.respawnDelay or 4
	if mode == "Hub" then return "BACK TO THE COURTYARD", delay end
	if mode == "Tiltyard" then return "BACK ON YOUR FEET", delay end
	if mode == "Horde" then return "THE NEXT WAVE BRINGS YOU BACK", nil end
	if def and (def.respawnDelay == 0 or def.roundsToWin ~= nil) then return "OUT FOR THIS ROUND", nil end
	return "BACK IN THE FIGHT", delay
end

local function label(parent, text, size, font, color, y, h)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.new(0.92, 0, 0, h or size + 12)
	l.Font = font
	l.TextSize = size
	l.TextColor3 = color
	l.Text = text
	l.RichText = true
	l.TextTransparency = 1
	l.ZIndex = 6
	local s = Instance.new("UIStroke")
	s.Color = Theme.OUTLINE
	s.Thickness = size >= 40 and 4 or 2
	s.Transparency = 1
	s.Parent = l
	l.Parent = parent
	return l, s
end
local function showText(l, s, dur)
	TweenService:Create(l, TweenInfo.new(dur or 0.3), {TextTransparency = 0}):Play()
	TweenService:Create(s, TweenInfo.new(dur or 0.3), {Transparency = 0.15}):Play()
end

local function lift(st, risen)
	if st.lifted then return end
	st.lifted = true
	st.stopEmbers()
	if current == st then current = nil end
	if risen then
		UIFX.flash(st.gui, GOLD, 0.45, 0.6)
		UIFX.play("Rise")
	end
	TweenService:Create(st.grade, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Saturation = 0, Contrast = 0, Brightness = 0, TintColor = WHITE}):Play()
	task.delay(0.75, function() st.grade:Destroy() end)
	st.gui:SetAttribute("HoldUntil", nil)
	UIFX.fadeOut(st.root, 0.55, false)
	task.delay(0.65, function() st.gui:Destroy() end)
end

local function setCause(st, e)
	if not e then return end
	local killer, weapon = e.killer, (e.weapon ~= "" and e.weapon or nil)
	if e.teamkill and killer then
		st.title.Text = "BETRAYED!"
		st.cause.Text = string.format('by your own side: <font color="#%s"><b>%s</b></font>', teamColour(e.killerTeam):ToHex(), killer)
	elseif killer then
		st.title.Text = TITLE[e.kind] or "YOU HAVE FALLEN"
		local who = string.format('<font color="#%s"><b>%s</b></font>', teamColour(e.killerTeam):ToHex(), killer)
		st.cause.Text = (e.kind == "bleed" and "after " or "by ") .. who .. (weapon and ("  ·  " .. string.upper(weapon)) or "")
	elseif e.kind == "bleed" then
		st.title.Text = "YOU BLED OUT"
	end
end

local function fall()
	if current then lift(current, false) end
	local st = {at = os.clock()}
	current = st
	local gui = Instance.new("ScreenGui")
	gui.Name = "DeathFade"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000      -- (under the class screen, 2000, and the Hub menu, 2050)
	gui:SetAttribute("DeathScreen", true)
	gui:SetAttribute("HoldUntil", os.clock() + MOMENT)
	gui.Parent = playerGui
	st.gui = gui
	local root = Instance.new("Frame")
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui
	st.root = root

	-- THE FALL: the colour drains, red closes in, a boom, the word
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "DeathGrade"
	grade.Parent = Lighting
	st.grade = grade
	TweenService:Create(grade, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Saturation = -0.8, Contrast = 0.15, Brightness = -0.04, TintColor = Color3.fromRGB(255, 226, 220)}):Play()
	local vig = UIFX.vignette(root, Color3.fromRGB(80, 0, 8), 0.9, 1)
	for _, e in ipairs(vig:GetChildren()) do TweenService:Create(e, TweenInfo.new(0.8), {BackgroundTransparency = 0}):Play() end
	UIFX.flash(gui, Color3.fromRGB(190, 24, 24), 0.4, 0.7)
	UIFX.play("Fallen")

	-- the veil (comes up after the fall) and the embers in it
	local veil = Instance.new("Frame")
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = WHITE
	veil.BackgroundTransparency = 1
	veil.BorderSizePixel = 0
	veil.ZIndex = 2
	veil.Parent = root
	local vg = Instance.new("UIGradient")
	vg.Rotation = 90
	vg.Color = ColorSequence.new(Color3.fromRGB(30, 12, 16), Color3.fromRGB(5, 4, 10))
	vg.Parent = veil
	local emberLayer = Instance.new("Frame")
	emberLayer.BackgroundTransparency = 1
	emberLayer.Size = UDim2.fromScale(1, 1)
	emberLayer.ZIndex = 3
	emberLayer.Parent = root
	st.stopEmbers = function() end

	st.title, st.titleStroke = label(root, "YOU HAVE FALLEN", 70, Theme.FONT_TITLE, RED, 0.4, 84)
	local sc = Instance.new("UIScale")
	sc.Scale = 2.2
	sc.Parent = st.title
	st.cause, st.causeStroke = label(root, "", 24, Theme.FONT, Color3.fromRGB(235, 230, 226), 0.48, 30)
	if lastKill and os.clock() - lastKill.at < 3 then setCause(st, lastKill.entry) end

	-- what comes next: a line, a bar
	local text, delay = nextStep()
	st.next, st.nextStroke = label(root, text, 22, Theme.FONT_TITLE, GOLD, 0.7, 28)
	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.5, 0.745)
	track.Size = UDim2.fromOffset(320, 6)
	track.BackgroundColor3 = Color3.fromRGB(50, 44, 56)
	track.BackgroundTransparency = 1
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.ZIndex = 6
	track.Parent = root
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = GOLD
	fill.BackgroundTransparency = 1
	fill.BorderSizePixel = 0
	fill.ZIndex = 7
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	-- the word lands
	task.delay(0.25, function()
		if st.lifted then return end
		showText(st.title, st.titleStroke, 0.15)
		TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Scale = 1}):Play()
		task.delay(0.3, function()
			if st.lifted then return end
			UIFX.sparks(root, Vector2.new(0.5, 0.4), {n = 22, colors = "blood", radius = 260, z = 8})
			UIFX.camShake(0.45, 5)
		end)
	end)
	task.delay(0.75, function() if not st.lifted then showText(st.cause, st.causeStroke, 0.4) end end)

	-- THE WAIT: the veil, embers, the way back
	task.delay(HOLD, function()
		if st.lifted then return end
		TweenService:Create(veil, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.16}):Play()
		st.stopEmbers = UIFX.embers(emberLayer, {colors = "fire", rate = 0.07, z = 3})
		showText(st.next, st.nextStroke, 0.5)
		TweenService:Create(track, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
		TweenService:Create(fill, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
		if delay then
			-- a countdown to the moment the server brings you back (the mode's respawn delay)
			task.spawn(function()
				while not st.lifted do
					local left = delay - (os.clock() - st.at)
					if left > 0 then
						st.next.Text = string.format("%s IN %d", text, math.ceil(left))
						fill.Size = UDim2.fromScale(math.clamp((os.clock() - st.at) / delay, 0, 1), 1)
					else
						st.next.Text = "GET READY…"
						fill.Size = UDim2.fromScale(1, 1)
						st.next.TextTransparency = 0.25 + 0.25 * math.sin(os.clock() * 6)
					end
					task.wait(0.05)
				end
			end)
		else
			-- no clock to show: a bar sweeping while you wait
			fill.Size = UDim2.fromScale(0.3, 1)
			fill.Position = UDim2.fromScale(-0.3, 0)
			TweenService:Create(fill, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), {Position = UDim2.fromScale(1, 0)}):Play()
		end
	end)

	-- THE RISE (or the class screen / the menu takes over)
	gui:GetAttributeChangedSignal("Lift"):Connect(function() if gui:GetAttribute("Lift") then lift(st, false) end end)
	-- (a long wait with nothing coming — spectating, a round ending — and the screen still
	-- lets go after a minute)
	task.delay(60, function() lift(st, false) end)
end

local function watch(char)
	if current then lift(current, true) end
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	hum.Died:Once(function()
		if player.Character == char then fall() end
	end)
end
player.CharacterAdded:Connect(watch)
if player.Character then task.spawn(watch, player.Character) end

-- the feed's entry for our own death: who, with what, how
task.spawn(function()
	local feed = ReplicatedStorage:WaitForChild("KillFeedRemote", 60)
	if not feed then return end
	feed.OnClientEvent:Connect(function(what, e)
		if what ~= "Kill" or type(e) ~= "table" or e.victimId ~= player.UserId then return end
		lastKill = {entry = e, at = os.clock()}
		if current and not current.lifted and os.clock() - current.at < 3 then setCause(current, e) end
	end)
end)

-- a test hook (the command bar / MCP): _G.ShowDeathScreen()
_G.ShowDeathScreen = fall
