--[[ PROLOGUE (client) — the Siege of Stormwatch on your screen (Game ▸ Modes ▸ Prologue runs the
     story; its header lists the steps). Only while the round's Mode is "Prologue":
       • THE HOST AND THE GARRISON (ReplicatedStorage ▸ WarCrowd): the Iron Host drawn up in the
         field among its torches (foot, pikes, knights, archers), the garrison's archers along the
         north walls; the volleys cut men down on both sides; the Host closes on the gate as the
         night goes on, and at dawn it breaks and runs while the walls cheer
       • THE STORM AND THE WAR ALL ROUND (ReplicatedStorage ▸ WarFX): rain, lightning, heavy cloud;
         the garrison's volleys off the walls and the Host's back over them, arrows thudding into
         the yard; the trebuchets lobbing fire; war cries from the camp; the score and the roar of
         the battle (ReplicatedStorage ▸ WarAudio, Studio-only: anything missing is just quiet)
       • the lesson card (top): the step, what to do in your own controls (InputHints), how far along
       • THE PROMPT (the duel's beats, the dodge): the key to press, big, under the middle of the
         screen, in your own controls; green when it's done, red with a word when it went wrong
       • SLOW TIME (Round ▸ PrologueSlow, the duel): the colour drains and cools, bars close in at
         top and bottom; while the raider's moment is held (his Hold) it drains further
       • Captain Hale's lines (bottom), a beacon over where to go, an arrow at the screen's edge
         when it's behind you
       • the cutscenes (opening, breach, champion, victory): black bars, the camera flies, the
         lines as subtitles, title cards; SPACE / ENTER / a tap / the pad's A skips one
       • M (the menu key): RESUME or SKIP THE TUTORIAL
       • the end: STORMWATCH STANDS, the welcome purse, TO THE COURTYARD
     The music steps aside for the siege's own (`_G.OwnScore`), the hotbar for a cutscene
     (`_G.CinematicUp`). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local InputHints = require(ReplicatedStorage:WaitForChild("InputHints"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local WarCrowd = require(ReplicatedStorage:WaitForChild("WarCrowd"))
local UIFX = require(ReplicatedStorage:WaitForChild("UIFX"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local round = ReplicatedStorage:WaitForChild("Round")
local remote = ReplicatedStorage:WaitForChild("PrologueEvent", math.huge)   -- (the Prologue mode makes it)

local V3, CF = Vector3.new, CFrame.new
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 70)
local EASE = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function inPrologue() return round:GetAttribute("Mode") == "Prologue" end

-- the lessons, in order (for "3 / 13"), and what a beacon over each place is called
local LESSONS = {"arm", "out", "duel", "dodge", "gatehouse", "hold", "champion"}
local PLACE = {out = "THE YARD", gatehouse = "THE GATEHOUSE"}

-- where things are (the map carries its story points as attributes: StormwatchMap)
local function mapModel() return workspace:FindFirstChild("Map") end
local function P(name)
	local m = mapModel()
	local v = m and m:GetAttribute("P_" .. name)
	return typeof(v) == "Vector3" and v or Vector3.zero
end
local function trebuchets()
	local m, list = mapModel(), {}
	for i = 1, 6 do
		local v = m and m:GetAttribute("T_" .. i)
		if typeof(v) == "Vector3" then table.insert(list, v) end
	end
	if #list == 0 then list = {V3(-70, 22, -190), V3(40, 22, -210), V3(120, 22, -175)} end
	return list
end
local function castle()
	local gate = P("gate")
	return gate.Z - 18, P("breach").X + 12   -- the north wall's line, the east wall's
end

--------------------------------------------------------------------
--  THE SCREEN
--------------------------------------------------------------------
local ui = {}
local gui = Instance.new("ScreenGui")
gui.Name = "Prologue"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 40
gui.Enabled = false
gui.Parent = playerGui

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 14); c.Parent = o; return c end
local function outline(o, t)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness = Theme.OUTLINE, t or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = o
	return s
end
local function label(parent, str, size, font, color, h)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text, l.TextSize, l.Font, l.TextColor3 = str, size, font or Theme.FONT, color or WHITE
	l.TextWrapped = true
	l.Size = UDim2.new(1, 0, 0, h or size + 6)
	outline(l, size >= 26 and 2.6 or 1.6)
	l.Parent = parent
	return l
end
local function glass(parent, size, pos, anchor)
	local f = Instance.new("Frame")
	f.BackgroundColor3, f.BackgroundTransparency = Theme.GLASS, 0.12
	f.Size, f.Position, f.AnchorPoint = size, pos, anchor or Vector2.new(0.5, 0)
	corner(f, 16)
	local s = Instance.new("UIStroke")
	s.Color, s.Transparency, s.Thickness = WHITE, 0.82, 1.5
	s.Parent = f
	f.Parent = parent
	return f, s
end
local function button(parent, str, color, size, pos)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = color
	b.Size, b.Position = size, pos
	b.Text, b.Font, b.TextSize, b.TextColor3 = str, Theme.FONT_TITLE, 22, WHITE
	corner(b, 12)
	outline(b, 2)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200))
	g.Rotation = 90
	g.Parent = b
	b.Parent = parent
	return b
end

-- THE LESSON CARD (top)
do
	local card = glass(gui, UDim2.new(0.92, 0, 0, 122), UDim2.new(0.5, 0, 0, -160))
	local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(560, 140); lim.Parent = card
	local kicker = label(card, "", 13, Theme.FONT, GOLD); kicker.Position = UDim2.fromOffset(0, 10); kicker.TextTransparency = 0.05
	local title = label(card, "", 30, Theme.FONT_TITLE, WHITE, 36); title.Position = UDim2.fromOffset(0, 26)
	local body = label(card, "", 17, Theme.FONT_BODY, Color3.fromRGB(226, 232, 245), 42); body.Position = UDim2.new(0, 18, 0, 64); body.Size = UDim2.new(1, -36, 0, 42)
	local track = Instance.new("Frame"); track.BackgroundColor3 = Color3.fromRGB(40, 46, 66); track.BorderSizePixel = 0
	track.Size = UDim2.new(1, -36, 0, 6); track.Position = UDim2.new(0, 18, 1, -12); corner(track, 3); track.Parent = card
	local fill = Instance.new("Frame"); fill.BackgroundColor3 = GOLD; fill.BorderSizePixel = 0; fill.Size = UDim2.fromScale(0, 1); corner(fill, 3); fill.Parent = track
	ui.card, ui.kicker, ui.title, ui.body, ui.track, ui.fill = card, kicker, title, body, track, fill
end
-- THE CAPTAIN'S LINES (bottom)
do
	local box = glass(gui, UDim2.new(0.62, 0, 0, 86), UDim2.new(0.5, 0, 1, -170), Vector2.new(0.5, 1))
	local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(620, 120); lim.Parent = box
	local who = label(box, "", 17, Theme.FONT_TITLE, GOLD); who.Position = UDim2.fromOffset(18, 10); who.Size = UDim2.new(1, -36, 0, 22); who.TextXAlignment = Enum.TextXAlignment.Left
	local line = label(box, "", 19, Theme.FONT, WHITE, 48); line.Position = UDim2.fromOffset(18, 32); line.Size = UDim2.new(1, -36, 0, 48)
	line.TextXAlignment, line.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
	box.Visible = false
	ui.say, ui.who, ui.line = box, who, line
end
-- the arrow at the screen's edge
do
	local a = label(gui, "▶", 40, Theme.FONT_TITLE, GOLD, 44)
	a.Size = UDim2.fromOffset(44, 44); a.AnchorPoint = Vector2.new(0.5, 0.5); a.Visible = false
	ui.edge = a
end
-- THE PROMPT: the verb, the keycap, a line under it
do
	local holder = Instance.new("CanvasGroup")
	holder.Name = "Prompt"
	holder.BackgroundTransparency = 1
	-- (its foot just above the captain's lines)
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -268)
	holder.Size = UDim2.fromOffset(520, 160)
	holder.GroupTransparency = 1
	holder.Visible = false
	holder.ZIndex = 8
	holder.Parent = gui
	local verb = label(holder, "", 46, Theme.FONT_TITLE, WHITE, 52)
	local key = Instance.new("Frame")
	key.AnchorPoint = Vector2.new(0.5, 0)
	key.Position = UDim2.new(0.5, 0, 0, 58)
	key.Size = UDim2.fromOffset(150, 52)
	key.BackgroundColor3 = Color3.fromRGB(22, 20, 28)
	key.BackgroundTransparency = 0.08
	corner(key, 12)
	local ks = Instance.new("UIStroke"); ks.Color = GOLD; ks.Thickness = 2.5; ks.Parent = key
	local kt = label(key, "", 24, Theme.FONT_TITLE, GOLD, 52)
	kt.Size = UDim2.fromScale(1, 1)
	local kscale = Instance.new("UIScale"); kscale.Parent = key
	key.Parent = holder
	local line = label(holder, "", 19, Theme.FONT_BODY, Color3.fromRGB(226, 232, 245), 26); line.Position = UDim2.fromOffset(0, 120)
	local scale = Instance.new("UIScale"); scale.Parent = holder
	ui.prompt = {holder = holder, verb = verb, key = key, keyText = kt, keyStroke = ks, keyScale = kscale, line = line, scale = scale, token = 0}
end
-- SLOW TIME: bars that close in at top and bottom (the colour is Lighting's)
do
	local top = Instance.new("Frame"); top.BackgroundColor3 = Color3.new(); top.BorderSizePixel = 0; top.BackgroundTransparency = 0.1
	top.Size = UDim2.new(1, 0, 0, 0); top.ZIndex = 2; top.Parent = gui
	local bottom = top:Clone(); bottom.AnchorPoint = Vector2.new(0, 1); bottom.Position = UDim2.fromScale(0, 1); bottom.Parent = gui
	ui.slowTop, ui.slowBottom = top, bottom
end

-- THE CUTSCENE'S FRAME: black bars, subtitles, the title card, a veil to fade through, skip
do
	local cine = Instance.new("Frame"); cine.Name = "Cine"; cine.BackgroundTransparency = 1; cine.Size = UDim2.fromScale(1, 1); cine.ZIndex = 20; cine.Visible = false; cine.Parent = gui
	local top = Instance.new("Frame"); top.BackgroundColor3 = Color3.new(); top.BorderSizePixel = 0; top.Size = UDim2.new(1, 0, 0, 0); top.ZIndex = 21; top.Parent = cine
	local bottom = top:Clone(); bottom.AnchorPoint = Vector2.new(0, 1); bottom.Position = UDim2.fromScale(0, 1); bottom.Parent = cine
	local sub = label(cine, "", 22, Theme.FONT, WHITE, 60); sub.AnchorPoint = Vector2.new(0.5, 1); sub.Position = UDim2.new(0.5, 0, 0.86, 0); sub.Size = UDim2.new(0.8, 0, 0, 60); sub.ZIndex = 23
	sub.RichText = true; sub.TextTransparency = 1
	local tk = label(cine, "", 18, Theme.FONT, GOLD, 24); tk.AnchorPoint = Vector2.new(0.5, 0.5); tk.Position = UDim2.fromScale(0.5, 0.41); tk.ZIndex = 23; tk.TextTransparency = 1
	local tt = label(cine, "", 64, Theme.FONT_TITLE, WHITE, 76); tt.AnchorPoint = Vector2.new(0.5, 0.5); tt.Position = UDim2.fromScale(0.5, 0.5); tt.Size = UDim2.new(0.9, 0, 0, 76); tt.ZIndex = 23; tt.TextTransparency = 1
	tt.TextScaled = true
	local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 72; c.Parent = tt
	local skip = label(cine, "", 14, Theme.FONT, Color3.fromRGB(210, 214, 226), 20); skip.AnchorPoint = Vector2.new(1, 1); skip.Position = UDim2.new(1, -18, 1, -10)
	skip.Size = UDim2.fromOffset(300, 20); skip.TextXAlignment = Enum.TextXAlignment.Right; skip.ZIndex = 23; skip.TextTransparency = 1
	local tap = Instance.new("TextButton"); tap.BackgroundTransparency = 1; tap.Text = ""; tap.Size = UDim2.fromScale(1, 1); tap.ZIndex = 22; tap.Visible = false; tap.Parent = cine
	local veil = Instance.new("Frame"); veil.BackgroundColor3 = Color3.new(); veil.BorderSizePixel = 0; veil.Size = UDim2.fromScale(1, 1); veil.BackgroundTransparency = 1; veil.ZIndex = 40; veil.Parent = gui
	ui.cine, ui.barTop, ui.barBottom, ui.sub, ui.titleKick, ui.titleBig, ui.skip, ui.tap, ui.veil = cine, top, bottom, sub, tk, tt, skip, tap, veil
	for _, o in ipairs({sub, tk, tt, skip}) do o:FindFirstChildOfClass("UIStroke").Transparency = 1 end
end

local function fade(o, props, t) TweenService:Create(o, TweenInfo.new(t or 0.4, Enum.EasingStyle.Quad), props):Play() end

--------------------------------------------------------------------
--  THE LESSON, THE CAPTAIN, THE BEACON
--------------------------------------------------------------------
local step = nil   -- the server's last "Step"
local function lessonNumber(id) return table.find(LESSONS, id) end
local function fillCard()
	if not step then return end
	local n = lessonNumber(step.id)
	ui.kicker.Text = "THE SIEGE OF STORMWATCH" .. (n and string.format("  ·  %d / %d", n, #LESSONS) or "")
	ui.title.Text = step.title or ""
	ui.body.Text = InputHints.fill(step.text or "")
end
InputHints.changed:Connect(fillCard)

local function progress(n, goal)
	local k = goal and goal > 0 and math.clamp(n / goal, 0, 1) or 0
	TweenService:Create(ui.fill, EASE, {Size = UDim2.fromScale(k, 1)}):Play()
	if n > 0 and n < (goal or 1) then
		UIFX.play("Tick")
		ui.title.Text = (step and step.title or "") .. string.format("   %d / %d", n, goal)
	end
end

local function say(who, text, dur)
	local box = ui.say
	box.Visible = true
	ui.who.Text = who or ""
	ui.line.Text = text or ""
	ui.line.MaxVisibleGraphemes = 0
	local token = (ui.sayToken or 0) + 1
	ui.sayToken = token
	box.Position = UDim2.new(0.5, 0, 1, -160)
	TweenService:Create(box, EASE, {Position = UDim2.new(0.5, 0, 1, -170)}):Play()
	task.spawn(function()
		local len = utf8.len(text or "") or 0
		for i = 1, len, 2 do
			if ui.sayToken ~= token then return end
			ui.line.MaxVisibleGraphemes = i
			task.wait(0.012)
		end
		ui.line.MaxVisibleGraphemes = -1
		task.wait(dur or 5)
		if ui.sayToken == token then box.Visible = false end
	end)
end

local beacon = {}
local function clearBeacon()
	if beacon.part then beacon.part:Destroy() end
	if beacon.bill then beacon.bill:Destroy() end
	beacon.part, beacon.bill, beacon.at = nil, nil, nil
	ui.edge.Visible = false
end
local function setBeacon(pos, name)
	clearBeacon()
	if not pos or pos == Vector3.zero then return end
	local g = WarFX.ground(pos)
	local beam = WarFX.part(V3(1.2, 140, 1.2), Color3.fromRGB(255, 176, 60), Enum.Material.Neon, 0.8)
	beam.CFrame = CF(g + V3(0, 70, 0))
	local ring = WarFX.part(V3(0.3, 13, 13), Color3.fromRGB(255, 176, 60), Enum.Material.Neon, 0.7)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CF(g + V3(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = beam
	beam.Parent = workspace
	local bill = Instance.new("BillboardGui")
	bill.Name = "PrologueBeacon"
	bill.ResetOnSpawn = false
	bill.AlwaysOnTop = true
	bill.Size = UDim2.fromOffset(220, 74)
	bill.Adornee = ring
	bill.StudsOffsetWorldSpace = V3(0, 10, 0)
	bill.LightInfluence = 0
	local arrow = label(bill, "▼", 30, Theme.FONT_TITLE, GOLD, 30)
	local nm = label(bill, name or "", 18, Theme.FONT_TITLE, WHITE, 22); nm.Position = UDim2.fromOffset(0, 30)
	local dist = label(bill, "", 14, Theme.FONT, Color3.fromRGB(220, 224, 236), 18); dist.Position = UDim2.fromOffset(0, 52)
	bill.Parent = playerGui
	beacon.part, beacon.bill, beacon.at, beacon.arrow, beacon.dist = beam, bill, g, arrow, dist
end
RunService.RenderStepped:Connect(function()
	if not beacon.at then return end
	local cam = workspace.CurrentCamera
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then beacon.dist.Text = string.format("%d m", math.floor((root.Position - beacon.at).Magnitude / 3.5 + 0.5)) end
	beacon.arrow.Position = UDim2.fromOffset(0, math.sin(os.clock() * 5) * 4)
	-- off screen: an arrow at the edge, pointing the way
	local v, onScreen = cam:WorldToViewportPoint(beacon.at + V3(0, 8, 0))
	if (onScreen and v.Z > 0) or ui.cine.Visible then ui.edge.Visible = false; return end
	local vs = cam.ViewportSize
	local cx, cy = vs.X / 2, vs.Y / 2
	local dx, dy = v.X - cx, v.Y - cy
	if v.Z < 0 then dx, dy = -dx, -dy end
	if math.abs(dx) < 1 and math.abs(dy) < 1 then dy = 1 end
	local ang = math.atan2(dy, dx)
	local r = math.min(cx, cy) - 70
	ui.edge.Position = UDim2.fromOffset(cx + math.cos(ang) * r, cy + math.sin(ang) * r)
	ui.edge.Rotation = math.deg(ang)
	ui.edge.Visible = true
end)

local function showStep(s)
	step = s
	fillCard()
	ui.fill.Size = UDim2.fromScale(0, 1)
	ui.title.TextColor3 = WHITE
	local card = ui.card
	card.Visible = true
	card.Position = UDim2.new(0.5, 0, 0, -160)
	TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 16)}):Play()
	UIFX.play("Whoosh")
	setBeacon(s.target, PLACE[s.id] or "")
end

local function stepDone(text)
	ui.title.Text = "✓  " .. (text or (step and step.title) or "")
	ui.title.TextColor3 = Theme.GOOD
	TweenService:Create(ui.fill, EASE, {Size = UDim2.fromScale(1, 1)}):Play()
	UIFX.play("Rise")
	clearBeacon()
	task.delay(0.9, function()
		if ui.title.TextColor3 == Theme.GOOD then TweenService:Create(ui.card, EASE, {Position = UDim2.new(0.5, 0, 0, -160)}):Play() end
	end)
end

-- THE PROMPT: show the key to press; done (green), missed (red, a word why), hidden
local PR = {}
function PR.hide(now)
	local p = ui.prompt
	p.token += 1
	p.up = false
	if now then p.holder.Visible = false; p.holder.GroupTransparency = 1; return end
	local tok = p.token
	TweenService:Create(p.holder, TweenInfo.new(0.3), {GroupTransparency = 1}):Play()
	task.delay(0.32, function() if p.token == tok then p.holder.Visible = false end end)
end
local function promptKey(action)
	local p = ui.prompt
	p.keyText.Text = action and InputHints.name(action) or ""
	p.key.Visible = p.keyText.Text ~= ""
	local w = math.max(64, p.keyText.TextBounds.X + 40)
	p.key.Size = UDim2.fromOffset(w, 52)
end
function PR.show(d)
	local p = ui.prompt
	p.token += 1
	p.up, p.action, p.sub = true, d.action, d.sub
	p.verb.Text = d.verb or ""
	p.verb.TextColor3 = WHITE
	p.keyStroke.Color, p.keyText.TextColor3 = GOLD, GOLD
	p.line.Text = InputHints.fill(d.sub or "")
	p.line.TextColor3 = Color3.fromRGB(226, 232, 245)
	promptKey(d.action)
	p.holder.Visible = true
	p.holder.GroupTransparency = 1
	p.scale.Scale = 1.3
	TweenService:Create(p.holder, TweenInfo.new(0.22), {GroupTransparency = 0}):Play()
	TweenService:Create(p.scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	UIFX.play("Whoosh")
end
function PR.done(text)
	local p = ui.prompt
	p.token += 1
	local tok = p.token
	p.up = false
	p.holder.Visible = true
	p.holder.GroupTransparency = 0
	p.verb.Text = text or ""
	p.verb.TextColor3 = Theme.GOOD
	p.keyStroke.Color, p.keyText.TextColor3 = Theme.GOOD, Theme.GOOD
	p.line.Text = ""
	p.scale.Scale = 1.18
	TweenService:Create(p.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	UIFX.play("Rise")
	task.delay(0.95, function() if p.token == tok then PR.hide() end end)
end
function PR.miss(text)
	local p = ui.prompt
	p.token += 1
	local tok = p.token
	p.up = false
	p.holder.Visible = true
	p.holder.GroupTransparency = 0
	p.verb.Text = "AGAIN"
	p.verb.TextColor3 = Theme.RED
	p.keyStroke.Color, p.keyText.TextColor3 = Theme.RED, Theme.RED
	p.line.Text = InputHints.fill(text or "")
	p.line.TextColor3 = Color3.fromRGB(255, 190, 180)
	UIFX.play("Error")
	-- (a shake)
	task.spawn(function()
		for i = 1, 6 do
			if p.token ~= tok then return end
			p.holder.Position = UDim2.new(0.5, (i % 2 == 0 and 1 or -1) * (7 - i), 1, -268)
			task.wait(0.03)
		end
		p.holder.Position = UDim2.new(0.5, 0, 1, -268)
	end)
	task.delay(1.5, function() if p.token == tok then PR.hide() end end)
end
InputHints.changed:Connect(function()
	local p = ui.prompt
	if p.up then promptKey(p.action); p.line.Text = InputHints.fill(p.sub or "") end
end)
-- the keycap breathes while it waits; it lights as you press the key it asks for
RunService.RenderStepped:Connect(function()
	local p = ui.prompt
	if not p.up then p.keyScale.Scale = 1; return end
	p.keyScale.Scale = 1 + 0.06 * math.sin(os.clock() * 6)
end)
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
UserInputService.InputBegan:Connect(function(input, gp)
	local p = ui.prompt
	if gp or not p.up or not p.action then return end
	local ok, act = pcall(ClientSettings.actionForInput, input)
	local hit = ok and act == p.action
	if not hit and p.action == "Block" then hit = input.UserInputType == Enum.UserInputType.MouseButton2 end
	if hit then
		p.keyStroke.Color, p.keyText.TextColor3 = WHITE, WHITE
		p.keyScale.Scale = 0.9
	end
end)

-- SLOW TIME (the duel): the colour drains and cools, the bars close in; deeper while his moment
-- is held
local slow = {on = false, held = false}
local function slowLook()
	local cc = slow.cc
	if not cc then return end
	local held = slow.held
	TweenService:Create(cc, TweenInfo.new(held and 0.25 or 0.6), {Saturation = held and -0.7 or -0.42, Contrast = held and 0.2 or 0.1,
		TintColor = held and Color3.fromRGB(196, 214, 255) or Color3.fromRGB(222, 230, 255)}):Play()
end
local function setSlow(on)
	if on == slow.on then return end
	slow.on = on
	if on then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "PrologueSlow"
		cc.Parent = Lighting
		slow.cc = cc
		slowLook()
		for _, b in ipairs({ui.slowTop, ui.slowBottom}) do TweenService:Create(b, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0.075, 0)}):Play() end
		UIFX.play("Fallen")
		-- (your heart in your ears the whole slow fight: WarAudio ▸ Heartbeat, if the place has it)
		slow.heart = WarFX.loop("Heartbeat", 0.55)
	else
		local cc = slow.cc
		slow.cc, slow.held = nil, false
		if slow.heart then WarFX.stopLoop(slow.heart, 0.8); slow.heart = nil end
		if cc then
			TweenService:Create(cc, TweenInfo.new(0.5), {Saturation = 0, Contrast = 0, TintColor = WHITE}):Play()
			task.delay(0.55, function() cc:Destroy() end)
		end
		for _, b in ipairs({ui.slowTop, ui.slowBottom}) do TweenService:Create(b, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 0)}):Play() end
	end
end
round:GetAttributeChangedSignal("PrologueSlow"):Connect(function() setSlow(inPrologue() and round:GetAttribute("PrologueSlow") == true) end)
RunService.Heartbeat:Connect(function()
	if not slow.on then return end
	local npcs = workspace:FindFirstChild("NPCs")
	local raider = npcs and npcs:FindFirstChild("Iron Host Raider")
	local held = raider ~= nil and raider:GetAttribute("Hold") == true
	if held ~= slow.held then
		slow.held = held
		slowLook()
		if held then UIFX.play("Thud") end
	end
end)

--------------------------------------------------------------------
--  THE WAR ALL ROUND (until dawn)
--------------------------------------------------------------------
local amb = {on = false}
local function aroundMe()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return root and root.Position or P("yard")
end
-- somewhere in the yard, not on top of you
local function yardSpot(minFrom)
	local gz, W = castle()
	local me = aroundMe()
	for _ = 1, 8 do
		local p = V3((math.random() - 0.5) * (W * 2 - 30), 0, gz + 14 + math.random() * 100)
		if (V3(p.X, me.Y, p.Z) - me).Magnitude > (minFrom or 30) then return p end
	end
	return V3(-W + 20, 0, gz + 60)
end
local function onTheWall()
	local gz, W = castle()
	local x = (math.random() < 0.5 and -1 or 1) * (26 + math.random() * (W - 34))
	return V3(x, 30, gz)
end
local function inTheField()
	local gz = castle()
	return V3((math.random() - 0.5) * 220, 0, gz - 50 - math.random() * 90)
end

-- THE HOST AND THE GARRISON: real soldiers (WarCrowd), the Host's lines where its torches burn
local host = {}
local HOST_REGS = {"hostL", "hostC", "hostR", "hostK"}
local function hostUp()
	if host.crowd then return end
	local gz, W = castle()
	local wallY = P("wall").Y > 1 and P("wall").Y or 26
	local small = (require(ReplicatedStorage:WaitForChild("Device")).kind() == "phone")
	WarCrowd.SCALE = small and 0.6 or 1
	local crowd = WarCrowd.new()
	host.crowd = crowd
	-- the Host (the Iron side) facing the gate, its lines among the torches; archers before them
	local front = gz - 78
	crowd:regiment("hostL", {side = "B", kind = "foot", at = V3(-56, 0, front), facing = 1, cols = 14, ranks = 5, spacing = 3, detail = "lite"})
	crowd:regiment("hostC", {side = "B", kind = "pike", at = V3(0, 0, front - 2), facing = 1, cols = 14, ranks = 5, spacing = 3, detail = "lite"})
	crowd:regiment("hostR", {side = "B", kind = "foot", at = V3(56, 0, front), facing = 1, cols = 14, ranks = 5, spacing = 3, detail = "lite"})
	crowd:regiment("hostK", {side = "B", kind = "knight", at = V3(0, 0, front - 24), facing = 1, cols = 10, ranks = 4, spacing = 3.2, detail = "mass"})
	for k, x in ipairs({-60, 60}) do
		crowd:regiment("hostA" .. k, {side = "B", kind = "archer", at = V3(x, 0, front + 22), facing = 1, cols = 10, ranks = 2, spacing = 2.8, detail = "lite"})
	end
	-- the garrison's archers along the north walls, either side of the gatehouse
	for k, x in ipairs({-(W + 26) / 2, (W + 26) / 2}) do
		crowd:regiment("wall" .. k, {side = "A", kind = "archer", at = V3(x, wallY, gz + 0.5), facing = -1, cols = math.floor((W - 30) / 2.6), ranks = 1,
			spacing = 2.6, detail = "lite", banner = false, fixed = true})
	end
	host.front = front
end
-- the Host closes on the gate (the night goes on), or breaks and runs (dawn)
local function hostMarch(z, run)
	local crowd = host.crowd
	if not crowd then return end
	for _, id in ipairs(HOST_REGS) do
		local r = crowd.regs[id]
		if r then crowd:march(id, z + (id == "hostK" and -24 or 0), run) end
	end
	for k = 1, 2 do crowd:march("hostA" .. k, z + 22, run) end
end
local function hostRout()
	local crowd = host.crowd
	if not crowd then return end
	-- (they turn and run: the whole Host back into the dark, the walls cheering)
	for _, id in ipairs(HOST_REGS) do local r = crowd.regs[id]; if r then r.facing, r.dirty = -1, true end end
	for k = 1, 2 do local r = crowd.regs["hostA" .. k]; if r then r.facing, r.dirty = -1, true end end
	hostMarch(host.front - 320, true)
	crowd:cheer("A")
	task.delay(5, function() if host.crowd == crowd then crowd:cheer("A") end end)
end
local function hostDown()
	if host.crowd then host.crowd:stop(); host.crowd = nil end
end
-- where the story is: the Host comes on as the night goes on
local STEP_FRONT = {gatehouse = 10, hold = 30, champion = 40}
round:GetAttributeChangedSignal("PrologueStep"):Connect(function()
	local add = STEP_FRONT[round:GetAttribute("PrologueStep") or ""]
	if add and host.crowd and host.front then hostMarch(host.front + add, false) end
end)

local function ambience()
	if amb.on then return end
	amb.on = true
	amb.token = (amb.token or 0) + 1
	local token = amb.token
	WarFX.storm(true)
	_G.OwnScore = true
	task.spawn(function()
		-- (the field arrives with the map)
		for _ = 1, 60 do if mapModel() and mapModel():GetAttribute("P_army") then break end task.wait(0.5) end
		if amb.on and amb.token == token and mapModel() then pcall(hostUp) end
	end)
	amb.rain = WarFX.loop("Rain", 1)
	amb.battle = WarFX.loop("Battle", 0.8)
	amb.music = WarFX.loop("Music", 0.9)
	task.spawn(function()
		task.wait(2)
		while amb.on and amb.token == token do
			if mapModel() then
				local id = round:GetAttribute("PrologueStep") or ""
				local roll = math.random()
				if id == "gatehouse" then
					-- running the gauntlet: arrows falling all round you
					local me = aroundMe()
					local ang = math.random() * math.pi * 2
					WarFX.volley(inTheField(), me + V3(math.cos(ang) * 14, 0, math.sin(ang) * 14), 22, {spread = 9, flight = 2.4})
					if roll < 0.35 then WarFX.fireball(trebuchets()[math.random(#trebuchets())], yardSpot(40), 4.2, {whistle = true, big = true}) end
					task.wait(1.6 + math.random() * 1.2)
				else
					if roll < 0.32 then
						-- the garrison looses from the walls into the dark (onto the Host's lines)
						local from = onTheWall()
						local to = inTheField()
						if host.crowd then
							host.crowd:loose(from.X < 0 and "wall1" or "wall2")
							local r = host.crowd.regs[({"hostL", "hostC", "hostR"})[math.random(3)]]
							if r then to = V3(r.x + (math.random() - 0.5) * 30, 0, r.z - 4 - math.random() * 8) end
							local crowd = host.crowd
							task.delay(2.8, function() if host.crowd == crowd then crowd:hit(to, 10, 3) end end)
						end
						WarFX.volley(from, to, 26, {spread = 16, flight = 2.8, stick = false})
					elseif roll < 0.6 then
						-- the Host's answer, over the wall and into the yard
						local from = inTheField() + V3(0, 2, 0)
						if host.crowd then
							local k = math.random(2)
							host.crowd:loose("hostA" .. k)
							local r = host.crowd.regs["hostA" .. k]
							if r then from = V3(r.x, 4, r.z) end
						end
						WarFX.volley(from, yardSpot(26), 20, {spread = 12, flight = 2.7})
					elseif roll < 0.86 then
						local list = trebuchets()
						local to = math.random() < 0.5 and onTheWall() or yardSpot(45)
						WarFX.fireball(list[math.random(#list)], to, 4.4, {whistle = (to - aroundMe()).Magnitude < 160, big = math.random() < 0.5})
					else
						WarFX.sound("Charge", inTheField() + V3(0, 0, -60), {volume = 0.55, range = 1600, near = 220})
						if host.crowd then host.crowd:cheer("B") end
					end
					task.wait(2.6 + math.random() * 3.4)
				end
			else
				task.wait(0.5)
			end
		end
	end)
end
local function ambienceOff(fadeSecs)
	if not amb.on then return end
	amb.on = false
	amb.token = (amb.token or 0) + 1
	WarFX.storm(false, fadeSecs or 0)
	WarFX.stopLoop(amb.rain, fadeSecs or 1)
	WarFX.stopLoop(amb.battle, fadeSecs or 1)
	amb.rain, amb.battle = nil, nil
end

-- DAWN: the storm breaks, the sun comes up, the horns
local function dawn()
	ambienceOff(7)
	pcall(hostRout)
	local info = TweenInfo.new(9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(Lighting, info, {ClockTime = 6.4, Brightness = 1.7, Ambient = Color3.fromRGB(112, 100, 104), OutdoorAmbient = Color3.fromRGB(160, 136, 124),
		FogColor = Color3.fromRGB(206, 160, 128), FogEnd = 1100, ExposureCompensation = 0.25}):Play()
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		TweenService:Create(atmo, info, {Density = 0.28, Haze = 1.2, Glare = 0.7, Color = Color3.fromRGB(214, 170, 136), Decay = Color3.fromRGB(150, 96, 74)}):Play()
	end
	if amb.music then TweenService:Create(amb.music, TweenInfo.new(4), {Volume = amb.music.Volume * 1.4}):Play() end
	-- the Host's torches gutter out across the field
	local m = mapModel()
	local torches = {}
	if m then for _, d in ipairs(m:GetDescendants()) do if d.Name == "HostTorch" and d:IsA("BasePart") then table.insert(torches, d) end end end
	task.spawn(function()
		for i, t in ipairs(torches) do
			t.LocalTransparencyModifier = 1
			if i % 6 == 0 then task.wait(0.05) end
		end
	end)
end

--------------------------------------------------------------------
--  THE CUTSCENES
--------------------------------------------------------------------
local cine = {on = false, token = 0}
local hiddenGuis = {}
local function look(pos, at, fov) return {cf = CFrame.lookAt(pos, at), fov = fov or 55} end
local function S(t0, t1, a, b) return {t0 = t0, t1 = t1, a = a, b = b or a} end
local function smooth(t) return t * t * (3 - 2 * t) end
local function camAt(shots, t)
	local s = shots[1]
	for _, x in ipairs(shots) do if t >= x.t0 then s = x end end
	local u = smooth(math.clamp((t - s.t0) / math.max(s.t1 - s.t0, 0.01), 0, 1))
	return s.a.cf:Lerp(s.b.cf, u), s.a.fov + (s.b.fov - s.a.fov) * u
end

local function subtitle(who, text, dur)
	local s = ui.sub
	local tok = (ui.subTok or 0) + 1
	ui.subTok = tok
	s.Text = who and string.format('<font color="#FFC846">%s</font>   %s', who, text) or text
	local st = s:FindFirstChildOfClass("UIStroke")
	s.TextTransparency, st.Transparency = 1, 1
	fade(s, {TextTransparency = 0}, 0.3); fade(st, {Transparency = 0}, 0.3)
	task.delay(dur or 3.5, function()
		if ui.subTok == tok then fade(s, {TextTransparency = 1}, 0.4); fade(st, {Transparency = 1}, 0.4) end
	end)
end
local function titleCard(kicker, title, dur)
	ui.titleKick.Text, ui.titleBig.Text = kicker or "", title or ""
	for _, o in ipairs({ui.titleKick, ui.titleBig}) do
		o.TextTransparency = 1
		o:FindFirstChildOfClass("UIStroke").Transparency = 1
		fade(o, {TextTransparency = 0}, 0.6)
		fade(o:FindFirstChildOfClass("UIStroke"), {Transparency = 0}, 0.6)
	end
	ui.titleBig.Position = UDim2.fromScale(0.5, 0.52)
	fade(ui.titleBig, {Position = UDim2.fromScale(0.5, 0.5)}, 1.2)
	task.delay(dur or 3, function()
		for _, o in ipairs({ui.titleKick, ui.titleBig}) do
			fade(o, {TextTransparency = 1}, 0.6)
			fade(o:FindFirstChildOfClass("UIStroke"), {Transparency = 1}, 0.6)
		end
	end)
end
local function myHead()
	local c = player.Character
	local h = c and c:FindFirstChild("Head")
	return h and h.Position or P("wake") + V3(0, 4.5, 0)
end
local function haleHead()
	local m = mapModel()
	local cast = m and m:FindFirstChild("PrologueCast", true)
	local hale = cast and cast:FindFirstChild("Captain Hale")
	local h = hale and hale:FindFirstChild("Head")
	return h and h.Position or P("captain") + V3(0, 4.5, 0)
end

-- each cutscene: its length, its shots (camera moves), its beats (what happens when)
local CINES = {}
function CINES.opening()
	local army, gz, W = P("army"), castle()
	local treb = trebuchets()[1]
	local tower = V3(W, 32, gz)
	local me, hale = myHead(), haleHead()
	local toMe = (me - hale).Unit
	local right = toMe:Cross(Vector3.yAxis).Unit
	return {len = 19, shots = {
		S(0, 5.4, look(army + V3(-80, 72, -60), V3(0, 18, gz), 50), look(army + V3(-34, 54, 4), V3(0, 16, gz), 50)),
		S(5.4, 9.2, look(treb + V3(-16, -14, -36), tower, 58), look(treb + V3(-8, -12, -24), tower, 52)),
		S(9.2, 13.6, look(V3(W - 48, 7, gz + 54), tower + V3(0, 6, 0), 62), look(V3(W - 42, 9, gz + 46), tower, 56)),
		S(13.6, 16.6, look(hale - toMe * 2.6 + right * 1.4 + V3(0, 0.5, 0), me, 50), look(hale - toMe * 2.2 + right * 1.2 + V3(0, 0.3, 0), me, 46)),
		-- (your own eyes, opening on the barracks and the captain in its doorway)
		S(16.6, 19, look(me + V3(0, -0.25, 0), hale + V3(0, -0.4, 0), 72), look(me + V3(0, 0.1, 0), hale, 70)),
	}, fp = 16.6, beats = {
		{0.1, function() WarFX.lightning(true) end},
		{0.6, function() titleCard("THE NORTHERN MARCHES", "", 3.6); subtitle(nil, "The third night of the siege.", 3.6) end},
		{1.2, function() WarFX.sound("Charge", army, {volume = 0.7, range = 2000, near = 300}) end},
		{4.6, function() subtitle(nil, "For three days the Iron Host has waited before the walls of Stormwatch.", 3.4) end},
		{6.0, function() WarFX.fireball(treb, tower, 4.0, {blast = false, height = 120}) end},
		{6.6, function() subtitle(nil, "Tonight, in the storm, they come for the gate.", 3.2) end},
		{10.7, function() titleCard(string.upper(GameConfig.GAME_NAME or "STEEL & GLORY"), "THE SIEGE OF STORMWATCH", 2.8) end},
		{13.8, function() subtitle("CAPTAIN HALE", "Up! Up, soldier! On your feet!", 2.8) end},
		{16.45, function() fade(ui.veil, {BackgroundTransparency = 0}, 0.12) end},
		{16.75, function() fade(ui.veil, {BackgroundTransparency = 1}, 0.7) end},
		{16.8, function() subtitle("CAPTAIN HALE", "The Iron Host is at our gate. You're with me!", 2.4) end},
		{17.75, function() fade(ui.veil, {BackgroundTransparency = 0.15}, 0.08) end},
		{17.9, function() fade(ui.veil, {BackgroundTransparency = 1}, 0.3) end},
	}}
end
function CINES.breach()
	local gz = castle()
	local ram = P("ram")
	return {len = 9, shots = {
		S(0, 3, look(ram + V3(-16, 5, -14), V3(0, 8, gz), 58), look(ram + V3(-12, 6, -8), V3(0, 9, gz), 54)),
		S(3, 5.25, look(V3(9, 5, gz + 14), V3(0, 9, gz), 60), look(V3(6, 4.5, gz + 10), V3(0, 9, gz), 64)),
		S(5.25, 9, look(V3(14, 7, gz + 30), V3(0, 6, gz), 62), look(V3(10, 6, gz + 24), V3(0, 6, gz - 4), 58)),
	}, beats = {
		{0.3, function() subtitle("THE IRON HOST", "HEAVE! ... HEAVE!", 2.4); WarFX.sound("Charge", ram, {volume = 0.6, range = 800}) end},
		{3.1, function() subtitle("CAPTAIN HALE", "Brace the gate! BRACE IT!", 2) end},
		{6.0, function() subtitle("CAPTAIN HALE", "THEY'RE THROUGH! HOLD THE LINE!", 2.8) end},
	}}
end
function CINES.champion()
	local gz = castle()
	return {len = 6.5, shots = {
		S(0, 6.5, look(V3(7, 2.4, gz + 26), V3(0, 6, gz + 4), 52), look(V3(4, 3.2, gz + 20), V3(0, 6.5, gz + 8), 44)),
	}, beats = {
		{1.35, function() WarFX.lightning(true) end},
		{2.2, function() titleCard("CHAMPION OF THE IRON HOST", "LORD VARG", 2.8) end},
		{4.4, function() subtitle("LORD VARG", "Stormwatch falls tonight.", 2) ; WarFX.sound("Charge", P("gate"), {volume = 0.8, range = 600}) end},
	}}
end
function CINES.victory()
	local gz = castle()
	local ride = {}
	for _, p in ipairs({V3(300, 0, gz - 175), V3(190, 0, gz - 140), V3(60, 0, gz - 120), V3(-120, 0, gz - 118), V3(-320, 0, gz - 130)}) do
		table.insert(ride, WarFX.ground(p))
	end
	return {len = 13, shots = {
		S(0, 5, look(V3(-6, 40, gz - 6), V3(150, 6, gz - 150), 55), look(V3(-2, 41, gz - 10), V3(170, 6, gz - 150), 50)),
		S(5, 9, look(V3(150, 5, gz - 96), V3(190, 4, gz - 140), 60), look(V3(140, 6, gz - 100), V3(70, 4, gz - 122), 55)),
		S(9, 13, look(V3(-22, 6, gz + 44), V3(0, 14, gz), 60), look(V3(-34, 34, gz + 66), V3(0, 18, gz - 60), 55)),
	}, beats = {
		{0, function() dawn() end},
		{0.2, function() ui.riders = WarFX.riders(ride, 18, {color = Color3.fromRGB(56, 92, 210), side = "A", speed = 44}) end},
		{0.4, function() WarFX.sound("Horn", nil, {volume = 1}) end},
		{0.7, function() subtitle("CAPTAIN HALE", "Horns! Listen... the King's riders!", 3.4) end},
		{2.9, function() WarFX.sound("Horn", nil, {volume = 0.8, speed = 0.92}) end},
		{5.3, function() subtitle("CAPTAIN HALE", "They're running! The Host is RUNNING!", 3.2) end},
		{9.4, function() titleCard("VICTORY", "STORMWATCH STANDS", 3.4); UIFX.play("LevelUp") end},
	}}
end

local KEEP = {Prologue = true, TravelScreen = true, Chat = true}
local function hideHud()
	for _, g in ipairs(playerGui:GetChildren()) do
		if g:IsA("ScreenGui") and g.Enabled and not KEEP[g.Name] then
			g.Enabled = false
			hiddenGuis[g] = true
		end
	end
end
local function showSkip()
	local m = InputHints.mode()
	ui.skip.Text = m == "Touch" and "TAP TO SKIP" or (m == "Gamepad" and "Ⓐ  SKIP" or "SPACE  ·  SKIP")
	fade(ui.skip, {TextTransparency = 0.15}, 0.4)
	fade(ui.skip:FindFirstChildOfClass("UIStroke"), {Transparency = 0.3}, 0.4)
end

-- (your body is whole on screen during a cutscene: what first person hid comes back after)
local function restoreBody()
	for d, v in pairs(cine.vis or {}) do if d.Parent then d.LocalTransparencyModifier = v end end
	cine.vis = {}
end
local function endCine(report)
	if not cine.on then return end
	restoreBody()
	local name = cine.name
	cine.on = false
	cine.token += 1
	_G.CinematicUp = nil
	if report then remote:FireServer("CineDone", name) end
	ui.veil.BackgroundTransparency = 0
	pcall(function() RunService:UnbindFromRenderStep("PrologueCine") end)
	for g in pairs(hiddenGuis) do if g.Parent then g.Enabled = true end end
	table.clear(hiddenGuis)
	ui.cine.Visible, ui.tap.Visible = false, false
	ui.barTop.Size, ui.barBottom.Size = UDim2.new(1, 0, 0, 0), UDim2.new(1, 0, 0, 0)
	ui.sub.TextTransparency, ui.skip.TextTransparency = 1, 1
	for _, o in ipairs({ui.sub, ui.skip, ui.titleKick, ui.titleBig}) do o:FindFirstChildOfClass("UIStroke").Transparency = 1 end
	ui.titleKick.TextTransparency, ui.titleBig.TextTransparency = 1, 1
	ui.card.Visible = true
	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = 70 end
	fade(ui.veil, {BackgroundTransparency = 1}, 0.6)
end

local function runCine(name)
	if cine.on then endCine(false) end
	local make = CINES[name]
	if not make then remote:FireServer("CineDone", name); return end
	local def = make()
	cine.on, cine.name, cine.t0 = true, name, os.clock()
	cine.vis = {}
	cine.token += 1
	local token = cine.token
	_G.CinematicUp = true
	ui.card.Visible, ui.say.Visible = false, false
	clearBeacon()
	-- the world round the shots streams in
	for _, s in ipairs(def.shots) do
		local at = s.a.cf.Position + s.a.cf.LookVector * 30
		task.spawn(function() pcall(function() player:RequestStreamAroundAsync(at, 2) end) end)
	end
	ui.cine.Visible = true
	ui.tap.Visible = InputHints.mode() == "Touch"
	ui.veil.BackgroundTransparency = 0
	fade(ui.veil, {BackgroundTransparency = 1}, 0.8)
	TweenService:Create(ui.barTop, TweenInfo.new(0.8), {Size = UDim2.new(1, 0, 0.11, 0)}):Play()
	TweenService:Create(ui.barBottom, TweenInfo.new(0.8), {Size = UDim2.new(1, 0, 0.11, 0)}):Play()
	task.delay(1.2, function() if cine.token == token then showSkip() end end)
	RunService:BindToRenderStep("PrologueCine", Enum.RenderPriority.Camera.Value + 5, function()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local t = os.clock() - cine.t0
		cam.CameraType = Enum.CameraType.Scriptable
		local cf, fov = camAt(def.shots, t)
		cam.CFrame, cam.FieldOfView = cf, fov
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = false
		-- your own body, seen from outside, whole (first person hides the head) · back to
		-- your own eyes for a shot that ends in them (def.fp)
		local char = player.Character
		if def.fp and t >= def.fp then
			if next(cine.vis) then restoreBody() end
		elseif char then
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") and d.LocalTransparencyModifier ~= 0 then
					if cine.vis[d] == nil then cine.vis[d] = d.LocalTransparencyModifier end
					d.LocalTransparencyModifier = 0
				end
			end
		end
		hideHud()
	end)
	for _, b in ipairs(def.beats) do
		task.delay(b[1], function() if cine.token == token then b[2]() end end)
	end
	task.delay(def.len, function()
		if cine.token ~= token then return end
		-- (out through black, so the cut back to your eyes doesn't jar)
		fade(ui.veil, {BackgroundTransparency = 0}, 0.3)
		task.wait(0.32)
		if cine.token == token then endCine(true) end
	end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if not cine.on or os.clock() - cine.t0 < 1 then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.Space or k == Enum.KeyCode.Return or k == Enum.KeyCode.ButtonA or k == Enum.KeyCode.ButtonStart then endCine(true) end
end)
ui.tap.Activated:Connect(function() if cine.on and os.clock() - cine.t0 > 1 then endCine(true) end end)

--------------------------------------------------------------------
--  WHAT HAPPENS (the server's effects)
--------------------------------------------------------------------
local function jolt(gate)
	local m = mapModel()
	local g = m and m:FindFirstChild("Gate")
	if not g then return end
	for _, leaf in ipairs(g:GetChildren()) do
		if leaf:IsA("Model") then
			local cf = leaf:GetPivot()
			pcall(function() leaf:PivotTo(cf * CF(0, 0, 0.7) * CFrame.Angles(math.rad(1.5), 0, 0)) end)
			task.delay(0.12, function() pcall(function() if leaf.Parent then leaf:PivotTo(cf) end end) end)
		end
	end
	WarFX.dust(gate + V3(0, 14, 2), 1.4, Color3.fromRGB(120, 112, 100))
end

local FX = {}
function FX.Dust(d) WarFX.dust(d.pos or aroundMe(), 1.2) end
function FX.Good(d) stepDone(d.text) end
function FX.Incoming(d)
	local list = trebuchets()
	WarFX.fireball(d.from or list[math.random(#list)], d.pos, d.t or 1.7, {blast = false, height = 70})
	WarFX.sound("Incoming", d.pos, {range = 260, near = 30})
end
function FX.Impact(d) WarFX.blast(d.pos, {big = d.big, far = d.far}) end
function FX.Ram(d)
	local gz = castle()
	local at = V3(0, 0, gz)
	WarFX.sound("Gate", at + V3(0, 8, 0), {range = 700, near = 60})
	local dist = (aroundMe() - at).Magnitude
	WarFX.shake(1.6 * math.clamp(1 - dist / 160, 0.25, 1), 0.5)
	jolt(at)
end
function FX.Breach(d)
	local gz = castle()
	local at = V3(0, 0, gz)
	WarFX.sound("Gate", at + V3(0, 8, 0), {range = 900, near = 80, speed = 0.8, volume = 1.3})
	task.delay(0.4, function() WarFX.sound("Charge", at + V3(0, 0, -20), {range = 1200, near = 120, volume = 1.2}) end)
	for i = 1, 3 do WarFX.dust(at + V3((i - 2) * 6, 4 + i * 3, 4), 2.2, Color3.fromRGB(110, 100, 88)) end
	WarFX.flash(0.3)
	WarFX.shake(2.6, 0.9)
end
function FX.Charge(d) WarFX.sound("Charge", (d.pos or P("gate")) + V3(0, 0, -30), {range = 1200, near = 120}) end
function FX.Dawn() if not cine.on then dawn() end end
function FX.Armed() UIFX.play("Unsheath") end
function FX.FullSpeed()
	setSlow(false)
	WarFX.shake(0.7, 0.35)
	UIFX.play("Whoosh")
end

--------------------------------------------------------------------
--  THE MENU KEY: RESUME / SKIP THE TUTORIAL · THE END
--------------------------------------------------------------------
local modal
local function freeMouse(on)
	pcall(function() RunService:UnbindFromRenderStep("PrologueMouse") end)
	if on then
		RunService:BindToRenderStep("PrologueMouse", Enum.RenderPriority.Camera.Value + 6, function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end)
	end
end
local function closeModal()
	if modal then modal:Destroy(); modal = nil end
	freeMouse(false)
	GuiService.SelectedObject = nil
end
local function openModal(h)
	closeModal()
	local shade = Instance.new("Frame")
	shade.BackgroundColor3, shade.BackgroundTransparency = Color3.new(), 0.45
	shade.Size = UDim2.fromScale(1, 1)
	shade.ZIndex = 30
	shade.Parent = gui
	local box = glass(shade, UDim2.new(0.9, 0, 0, h), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	box.ZIndex = 31
	local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(480, h); lim.Parent = box
	modal = shade
	freeMouse(true)
	return box
end
local function pick(b) if InputHints.mode() == "Gamepad" then GuiService.SelectedObject = b end end

local function skipConfirm()
	local box = openModal(220)
	local t = label(box, "SKIP THE TUTORIAL?", 28, Theme.FONT_TITLE, WHITE, 34); t.Position = UDim2.fromOffset(0, 18); t.ZIndex = 32
	local b = label(box, "You'll go straight to the Courtyard. The siege is worth it, though: it's where you learn to fight.", 16, Theme.FONT_BODY, Color3.fromRGB(214, 220, 236), 44)
	b.Position = UDim2.new(0, 20, 0, 60); b.Size = UDim2.new(1, -40, 0, 44); b.ZIndex = 32
	local keep = button(box, "KEEP FIGHTING", Theme.GREEN, UDim2.new(0.5, -26, 0, 56), UDim2.new(0, 20, 1, -76)); keep.ZIndex = 32
	local skip = button(box, "SKIP", Theme.RED, UDim2.new(0.5, -26, 0, 56), UDim2.new(0.5, 6, 1, -76)); skip.ZIndex = 32
	keep.Activated:Connect(closeModal)
	skip.Activated:Connect(function()
		closeModal()
		remote:FireServer("Skip")
		if _G.ShowTravel then _G.ShowTravel("THE COURTYARD", "") end
	end)
	pick(keep)
end
local function pauseMenu()
	if modal then closeModal(); return end
	local box = openModal(250)
	local k = label(box, "THE SIEGE OF STORMWATCH", 14, Theme.FONT, GOLD, 18); k.Position = UDim2.fromOffset(0, 18); k.ZIndex = 32
	local t = label(box, step and step.title or "PAUSED", 30, Theme.FONT_TITLE, WHITE, 36); t.Position = UDim2.fromOffset(0, 38); t.ZIndex = 32
	local resume = button(box, "RESUME", Theme.GREEN, UDim2.new(1, -40, 0, 56), UDim2.new(0, 20, 0, 92)); resume.ZIndex = 32
	local skip = button(box, "SKIP THE TUTORIAL", Theme.GLASS2, UDim2.new(1, -40, 0, 50), UDim2.new(0, 20, 0, 160)); skip.ZIndex = 32; skip.TextSize = 18
	resume.Activated:Connect(closeModal)
	skip.Activated:Connect(skipConfirm)
	pick(resume)
end
do
	local prev = _G.MenuKeyOverride
	_G.MenuKeyOverride = function()
		if inPrologue() then
			if not cine.on and not ui.doneUp then pauseMenu() end
			return true
		end
		return prev and prev() or false
	end
end

local function done(info)
	info = info or {}
	ui.card.Visible, ui.say.Visible = false, false
	clearBeacon()
	if not info.won then
		if _G.ShowTravel then _G.ShowTravel("THE COURTYARD", "") end
		return
	end
	ui.doneUp = true
	local box = openModal(330)
	local k = label(box, "THE SIEGE OF STORMWATCH", 15, Theme.FONT, GOLD, 18); k.Position = UDim2.fromOffset(0, 20); k.ZIndex = 32
	local t = label(box, "STORMWATCH STANDS", 38, Theme.FONT_TITLE, WHITE, 44); t.Position = UDim2.fromOffset(0, 42); t.ZIndex = 32
	local b = label(box, "You held the gate beside the garrison and broke the Iron Host's champion. You're ready for the real fight.", 17, Theme.FONT_BODY, Color3.fromRGB(220, 226, 240), 48)
	b.Position = UDim2.new(0, 24, 0, 96); b.Size = UDim2.new(1, -48, 0, 48); b.ZIndex = 32
	local r = label(box, info.reward or "", 20, Theme.FONT_TITLE, Theme.MARKS, 26); r.Position = UDim2.fromOffset(0, 156); r.ZIndex = 32
	local go = button(box, "TO THE COURTYARD", Theme.GREEN, UDim2.new(1, -48, 0, 62), UDim2.new(0, 24, 1, -110)); go.ZIndex = 32; go.TextSize = 26
	local left = label(box, "", 14, Theme.FONT, Color3.fromRGB(190, 196, 214), 18); left.Position = UDim2.new(0, 0, 1, -40); left.ZIndex = 32
	pick(go)
	UIFX.play("Coins")
	local t0 = os.clock()
	local function leave()
		if not ui.doneUp then return end
		ui.doneUp = false
		closeModal()
		remote:FireServer("Finish")
		if _G.ShowTravel then _G.ShowTravel("THE COURTYARD", "") end
	end
	go.Activated:Connect(leave)
	task.spawn(function()
		while ui.doneUp and left.Parent do
			left.Text = string.format("Off to the Courtyard in %d s", math.max(0, math.ceil(38 - (os.clock() - t0))))
			task.wait(0.25)
		end
	end)
end

--------------------------------------------------------------------
--  THE SERVER'S EVENTS · COMING AND GOING
--------------------------------------------------------------------
remote.OnClientEvent:Connect(function(what, a, b)
	if not inPrologue() then return end
	if what == "Step" then
		PR.hide(true)
		showStep(a or {})
	elseif what == "Prompt" then
		PR.show(a or {})
	elseif what == "PromptDone" then
		PR.done((a or {}).text)
	elseif what == "PromptMiss" then
		PR.miss((a or {}).text)
	elseif what == "Progress" then
		progress(a, b)
	elseif what == "Line" then
		a = a or {}
		if cine.on then subtitle(a.who, a.text, a.dur) else say(a.who, a.text, a.dur) end
	elseif what == "Cine" then
		PR.hide(true)
		runCine(a)
	elseif what == "Fx" then
		local f = FX[a]
		if f then
			local ok, err = pcall(f, b or {})
			if not ok then warn("[Prologue] fx " .. tostring(a) .. ": " .. tostring(err)) end
		end
	elseif what == "Done" then
		done(a)
	end
end)

local function enter()
	gui.Enabled = true
	ui.card.Visible = false
	ambience()
	setSlow(round:GetAttribute("PrologueSlow") == true)
end
local function leave()
	gui.Enabled = false
	endCine(false)
	closeModal()
	ui.doneUp = false
	clearBeacon()
	PR.hide(true)
	setSlow(false)
	ambienceOff(0)
	if amb.music then WarFX.stopLoop(amb.music, 1.5); amb.music = nil end
	if ui.riders then ui.riders.stop(); ui.riders = nil end
	hostDown()
	WarFX.clear()
	_G.OwnScore, _G.CinematicUp = nil, nil
	step = nil
end
round:GetAttributeChangedSignal("Mode"):Connect(function()
	if inPrologue() then enter() else leave() end
end)
if inPrologue() then enter() end
