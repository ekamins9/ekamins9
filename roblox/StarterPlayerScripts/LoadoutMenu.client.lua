--[[ CLASS SCREEN — what you see with no body in a match: pick a CLASS and
     spawn. Each class (GameConfig.CLASSES) carries the loadout you saved for
     it on the LOADOUT screen (Hub menu, M); the card shows that loadout. Lives in
     StarterPlayerScripts so it survives death and opens again when the
     server says so. Each card shows your fighter in that class's loadout
     (PreviewRig in a ViewportFrame), the chosen one turning slowly. During
     the intermission the vote has the screen (Scoreboard) and this waits.

       ReplicatedStorage.LoadoutRemote  "Catalog" -> {classes, order, active, …}
       ReplicatedStorage.LoadoutEvent   out: "Ready" · "Spawn", classId
                                        in:  "Show", activeClass, waitReason · "Spawned" ·
                                             "Wave", seconds (the next reinforcement wave)

     In the courtyard (Hub mode) this screen steps aside and opens the Hub
     menu instead — there you ENTER COURTYARD. The two talk over _G.MenuBus:
       "OpenHub", tab   (we ask)      "HubOpened" / "HubClosed"   (it tells us)
     SPECTATE hands the screen to the Spectate script (watch the fight until
     you spawn) over the same bus:
       "Spectate", true (we ask)      "SpectateEnd" · "SpawnNow"   (it asks us)
     and _G.ClassScreen lets it read the spawn button's state. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local PreviewRig = require(ReplicatedStorage:WaitForChild("PreviewRig"))

local player    = Players.LocalPlayer
local remote    = ReplicatedStorage:WaitForChild("LoadoutRemote")
local event     = ReplicatedStorage:WaitForChild("LoadoutEvent")
local roundNode = ReplicatedStorage:WaitForChild("Round")
local playerGui = player:WaitForChild("PlayerGui")

_G.MenuBus = _G.MenuBus or Instance.new("BindableEvent")
local bus = _G.MenuBus

--------------------------------------------------------------------
--  LOOK
--------------------------------------------------------------------
local FONT       = Theme.FONT
local FONT_BLACK = Theme.FONT_TITLE
local FONT_BODY  = Theme.FONT_BODY
local COL_BACK    = Theme.BACK
local COL_PANEL   = Theme.PANEL
local COL_CARD    = Theme.CARD
local COL_CARD_ON = Theme.CARD_ON
local COL_TEXT    = Theme.TEXT
local COL_DIM     = Theme.DIM
local COL_ACCENT  = Theme.ACCENT
local COL_SPAWN   = Theme.GO
local COL_SPAWN_ON= Theme.GO_ON
local TYPE_COL    = {Light = Color3.fromRGB(96, 160, 96), Medium = Color3.fromRGB(190, 160, 70), Heavy = Color3.fromRGB(180, 80, 70)}

local function label(parent, text, size, font, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = font or FONT_BODY
	t.TextSize = size or 15
	t.TextColor3 = color or COL_TEXT
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextWrapped = true
	t.Text = text or ""
	t.Parent = parent
	return t
end
local function button(parent, text, size, color)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = color or COL_CARD
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = FONT
	b.TextSize = size or 15
	b.TextColor3 = Theme.textOn(b.BackgroundColor3)
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		if b.TextColor3 == COL_TEXT or b.TextColor3 == Theme.INK then b.TextColor3 = Theme.textOn(b.BackgroundColor3) end
	end)
	return b
end

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "LoadoutMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2000   -- above CameraRig's DeathFade (1000); the Hub menu sits at 2050
gui.Enabled = false
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = COL_BACK
backdrop.BackgroundTransparency = 0.35
backdrop.BorderSizePixel = 0
backdrop.Active = true
backdrop.Parent = gui

-- embers drifting up behind the panel while the screen is up (UIFX)
do
	local embers = Instance.new("Frame")
	embers.BackgroundTransparency = 1
	embers.Size = UDim2.fromScale(1, 1)
	embers.ZIndex = 0
	embers.Parent = backdrop
	require(ReplicatedStorage:WaitForChild("UIFX")).embers(embers, {colors = "fire", rate = 0.14, z = 0, alpha = 0.3})
end

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.8, 0.72)
panel.BackgroundColor3 = COL_PANEL
panel.BorderSizePixel = 0
panel.Parent = backdrop
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", panel); stroke.Color = COL_ACCENT; stroke.Thickness = 1.5; stroke.Transparency = 0.5
Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(1150, 640)
local pad = Instance.new("UIPadding", panel)
pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 22), UDim.new(0, 22), UDim.new(0, 16), UDim.new(0, 18)

local title = label(panel, "CHOOSE YOUR CLASS", 28, FONT_BLACK, COL_ACCENT)
title.Size = UDim2.new(1, -260, 0, 34)
local modeLine = label(panel, "", 14, FONT_BODY, COL_DIM)
modeLine.Position = UDim2.new(0, 0, 0, 34)
-- (the mode and map beside the menu's tabs; the mode's description under them, the panel's whole
-- width and two lines, so a long one is read in full: descLine)
modeLine.Size = UDim2.new(1, -260, 0, 18)
modeLine.TextYAlignment = Enum.TextYAlignment.Top
modeLine.TextTruncate = Enum.TextTruncate.AtEnd
modeLine.RichText = true
local descLine = label(panel, "", 13, FONT_BODY, COL_DIM)
descLine.Position = UDim2.new(0, 0, 0, 53)
descLine.Size = UDim2.new(1, 0, 0, 32)
descLine.TextWrapped = true
descLine.TextYAlignment = Enum.TextYAlignment.Top
descLine.TextTruncate = Enum.TextTruncate.AtEnd

-- top-right: the Hub menu's tabs
local menuRow = Instance.new("Frame")
menuRow.BackgroundTransparency = 1
menuRow.AnchorPoint = Vector2.new(1, 0)
menuRow.Position = UDim2.new(1, 0, 0, 0)
menuRow.Size = UDim2.fromOffset(250, 36)
menuRow.Parent = panel
local mrl = Instance.new("UIListLayout", menuRow)
mrl.FillDirection = Enum.FillDirection.Horizontal
mrl.HorizontalAlignment = Enum.HorizontalAlignment.Right
mrl.Padding = UDim.new(0, 6)
for i, tab in ipairs({"MENU", "LOADOUT", "SETTINGS"}) do
	local b = button(menuRow, tab, 13, COL_CARD)
	b.Size = UDim2.fromOffset(tab == "MENU" and 64 or 84, 36)
	b.LayoutOrder = i
	b.Activated:Connect(function() bus:Fire("OpenHub", tab == "MENU" and "PLAY" or tab) end)
end

-- (a phone: the panel nearly the whole screen, and each card's fighter where its description
-- was, or there'd be no room for them: ReplicatedStorage ▸ Device; applied once the cards exist)
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local fitCards   -- (below)

-- class cards
local cardRow = Instance.new("Frame")
cardRow.BackgroundTransparency = 1
cardRow.Position = UDim2.new(0, 0, 0, 88)
cardRow.Size = UDim2.new(1, 0, 1, -88 - 150)
cardRow.Parent = panel
-- the class you pick, in full, under the cards (each card has its bars instead)
local classLine = label(panel, "", 13, FONT_BODY, COL_TEXT)
classLine.AnchorPoint = Vector2.new(0.5, 1)
classLine.Position = UDim2.new(0.5, 0, 1, -110)
classLine.Size = UDim2.new(1, -40, 0, 36)
classLine.TextXAlignment = Enum.TextXAlignment.Center
classLine.RichText = true
local crl = Instance.new("UIListLayout", cardRow)
crl.FillDirection = Enum.FillDirection.Horizontal
crl.Padding = UDim.new(0, 14)
crl.SortOrder = Enum.SortOrder.LayoutOrder

local cards = {}   -- [classId] = {btn, sum, tag, vp, desc}
local selected = GameConfig.DEFAULT_CLASS
-- is this class open to you yet? (the Archer and the Mage wait for level 5)
local lockVeils = {}
local function open_(id)
	local d = GameConfig.CLASSES[id]
	return d ~= nil and (d.unlock == nil or (Players.LocalPlayer:GetAttribute("Level") or 1) >= (d.unlock.level or 0))
end
local catalog = nil

local function paint()
	for id, v in pairs(lockVeils) do v.Visible = not open_(id) end
	if not open_(selected) then selected = GameConfig.DEFAULT_CLASS end
	for id, c in pairs(cards) do
		local on = id == selected
		TweenService:Create(c.btn, TweenInfo.new(0.12), {BackgroundColor3 = on and COL_CARD_ON or COL_CARD}):Play()
		c.stroke.Transparency = on and 0 or 1
		-- (its armour's colour, lifted towards white on the bright card so it still reads)
		if c.tagCol then c.tag.TextColor3 = on and c.tagCol:Lerp(Color3.new(1, 1, 1), 0.65) or c.tagCol end
	end
	local def = GameConfig.CLASSES[selected]
	if def then classLine.Text = string.format('<font color="#%s"><b>%s</b></font>   %s', COL_ACCENT:ToHex(), string.upper(def.name), def.description or "") end
end

-- each card's three bars: how much it takes, how fast it moves, how long it lasts (Catalog ▸
-- Weights and the class's own health / prot / speed: what a spawn really gets, never its looks)
local STATS = {}
local STAT_ROWS = {{"TOUGHNESS", Color3.fromRGB(222, 112, 72)}, {"SPEED", Color3.fromRGB(122, 190, 108)}, {"STAMINA", Color3.fromRGB(86, 140, 226)}}
do
	local W = require(ReplicatedStorage:WaitForChild("Catalog")).WEIGHTS or {}
	local raw = {}
	for id, def in pairs(GameConfig.CLASSES) do
		local w = W[def.weight] or {}
		local hp = 100 + (w.health or 0) + (def.health or 0)
		local prot = def.prot or w.prot or 0
		raw[id] = {hp / math.max(0.3, 1 - prot), (w.speed or 1) * (def.speed or 1), (w.stamina or 1) * (w.regen or 1)}
	end
	for k = 1, 3 do
		local lo, hi = math.huge, -math.huge
		for _, r in pairs(raw) do lo = math.min(lo, r[k]); hi = math.max(hi, r[k]) end
		for id, r in pairs(raw) do
			STATS[id] = STATS[id] or {}
			STATS[id][k] = hi > lo and 0.18 + 0.82 * (r[k] - lo) / (hi - lo) or 1
		end
	end
end

for i, id in ipairs(GameConfig.CLASS_ORDER) do
	local def = GameConfig.CLASSES[id]
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1 / #GameConfig.CLASS_ORDER, -10, 1, 0)
	b.LayoutOrder = i
	b.BackgroundColor3 = COL_CARD
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.Parent = cardRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local s = Instance.new("UIStroke", b); s.Color = COL_ACCENT; s.Thickness = 2; s.Transparency = 1
	local p = Instance.new("UIPadding", b)
	p.PaddingLeft, p.PaddingRight, p.PaddingTop, p.PaddingBottom = UDim.new(0, 16), UDim.new(0, 16), UDim.new(0, 14), UDim.new(0, 14)
	local n = label(b, string.upper(def.name), 24, FONT_BLACK, COL_TEXT); n.Size = UDim2.new(1, 0, 0, 30)
	local tag = label(b, def.weight == "Robe" and "MAGE ROBES" or (string.upper(def.armorType) .. " ARMOR"), 12, FONT, TYPE_COL[def.armorType] or COL_DIM); tag.Position = UDim2.new(0, 0, 0, 32); tag.Size = UDim2.new(1, 0, 0, 16)
	-- your fighter in this class's loadout
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Preview"
	vp.BackgroundTransparency = 1
	vp.Position = UDim2.new(0, -8, 0, 50)
	vp.Size = UDim2.new(1, 16, 1, -50 - 122)
	vp.Ambient = Color3.fromRGB(150, 146, 140)
	vp.LightColor = Color3.fromRGB(255, 244, 226)
	vp.LightDirection = Vector3.new(-0.4, -1, 0.6)
	vp.Parent = b
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	-- (its bars where a paragraph was: the whole of it is under the cards, for the one you pick)
	local d = Instance.new("Frame"); d.Name = "Stats"; d.BackgroundTransparency = 1; d.AnchorPoint = Vector2.new(0, 1); d.Position = UDim2.new(0, 0, 1, -64); d.Size = UDim2.new(1, 0, 0, 50); d.Parent = b
	for k, row in ipairs(STAT_ROWS) do
		local y = (k - 1) * 17
		local nm = label(d, row[1], 10, FONT, COL_DIM); nm.Position = UDim2.fromOffset(0, y); nm.Size = UDim2.new(0, 74, 0, 14); nm.TextWrapped = false
		local bar = Instance.new("Frame"); bar.BackgroundColor3 = Color3.fromRGB(10, 12, 22); bar.BackgroundTransparency = 0.25; bar.BorderSizePixel = 0
		bar.Position = UDim2.new(0, 76, 0, y + 3); bar.Size = UDim2.new(1, -76, 0, 8); bar.Parent = d
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame"); fill.BackgroundColor3 = row[2]; fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale((STATS[id] or {})[k] or 0.5, 1); fill.Parent = bar
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	end
	local lh = label(b, "LOADOUT", 11, FONT, COL_DIM); lh.AnchorPoint = Vector2.new(0, 1); lh.Position = UDim2.new(0, 0, 1, -44); lh.Size = UDim2.new(1, 0, 0, 14)
	local sum = label(b, "…", 14, FONT, COL_TEXT); sum.AnchorPoint = Vector2.new(0, 1); sum.Position = UDim2.new(0, 0, 1, 0); sum.Size = UDim2.new(1, 0, 0, 44); sum.TextYAlignment = Enum.TextYAlignment.Top
	b.MouseEnter:Connect(function() if selected ~= id then b.BackgroundColor3 = COL_CARD:Lerp(COL_CARD_ON, 0.35) end end)
	b.MouseLeave:Connect(function() if selected ~= id then b.BackgroundColor3 = COL_CARD end end)
	b.Activated:Connect(function()
		if not open_(id) then return end
		selected = id; paint(); event:FireServer("Pick", id)
	end)
	-- (locked: a veil and the level it opens at — GameConfig.CLASSES unlock)
	if def.unlock then
		local veil = Instance.new("Frame"); veil.Name = "Locked"; veil.BackgroundColor3 = Color3.fromRGB(8, 10, 18); veil.BackgroundTransparency = 0.12
		veil.Size = UDim2.fromScale(1, 1); veil.ZIndex = 20; veil.Visible = false; veil.Parent = b
		Instance.new("UICorner", veil).CornerRadius = UDim.new(0, 10)
		local lt = label(veil, "🔒  LEVEL " .. tostring(def.unlock.level or "?"), 18, FONT, COL_TEXT)
		lt.Size = UDim2.new(1, 0, 0, 30); lt.Position = UDim2.new(0, 0, 0.5, -15); lt.TextXAlignment = Enum.TextXAlignment.Center; lt.ZIndex = 21
		lockVeils[id] = veil
	end
	cards[id] = {btn = b, sum = sum, tag = tag, tagCol = tag.TextColor3, stroke = s, vp = vp, cam = cam, desc = d}
end

-- each class's fighter: dressed by the same Dresser as a real spawn
local SPIN = 20      -- degrees a second the chosen class's fighter turns
local function buildPreviews()
	for id, c in pairs(cards) do
		if c.rig then c.rig:Destroy(); c.rig = nil end
		local cls = catalog and catalog.classes and catalog.classes[id]
		if cls and cls.loadout then
			local ok, rig = pcall(PreviewRig.dressedRig, {loadout = cls.loadout, appearance = catalog.appearance,
				weight = GameConfig.CLASSES[id] and GameConfig.CLASSES[id].weight, weapon = true,
				pose = {rs = {12, 0, 0}, ls = {-6, 0, 0}}})
			if ok and rig then
				c.yaw = -25
				rig:PivotTo(CFrame.Angles(0, math.rad(c.yaw), 0))
				rig.Parent = c.vp
				c.rig = rig
				-- frame the whole body, boots to crest
				c.cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.1, -10.4), Vector3.new(0, -0.4, 0))
			end
		end
	end
end
-- (only while the card is on screen: the class screen up and nothing above it hidden)
local function onScreen(obj)
	local o = obj
	while o and not o:IsA("LayerCollector") do
		if o:IsA("GuiObject") and not o.Visible then return false end
		o = o.Parent
	end
	return o ~= nil and o.Enabled
end
RunService.RenderStepped:Connect(function(dt)
	local c = cards[selected]
	if not (c and c.rig and c.vp.Parent and onScreen(c.vp)) then return end
	c.yaw = (c.yaw or -25) + SPIN * dt
	c.rig:PivotTo(CFrame.Angles(0, math.rad(c.yaw), 0))
end)

-- bottom: spawn + wait reason
local spawnBtn = button(panel, "SPAWN", 24, COL_SPAWN_ON)
spawnBtn.AnchorPoint = Vector2.new(0.5, 1)
spawnBtn.Position = UDim2.new(0.5, 0, 1, -30)
spawnBtn.Size = UDim2.new(0.5, 0, 0, 54)
spawnBtn.AutoButtonColor = false
local spectateBtn = button(panel, "SPECTATE", 16, COL_CARD)
spectateBtn.AnchorPoint = Vector2.new(1, 1)
spectateBtn.Position = UDim2.new(1, 0, 1, -30)
spectateBtn.Size = UDim2.new(0, 170, 0, 54)
local waitLine = label(panel, "", 14, FONT, COL_ACCENT)
waitLine.AnchorPoint = Vector2.new(0.5, 1)
waitLine.Position = UDim2.new(0.5, 0, 1, 0)
waitLine.Size = UDim2.new(1, 0, 0, 22)
waitLine.TextXAlignment = Enum.TextXAlignment.Center
local editHint = label(panel, "Change a class's armor and weapons in LOADOUT (up top)  ·  " .. require(ReplicatedStorage:WaitForChild("InputHints")).name("Menu") .. " opens the menu any time", 12, FONT_BODY, COL_DIM)
editHint.AnchorPoint = Vector2.new(0.5, 1)
editHint.Position = UDim2.new(0.5, 0, 1, -90)
editHint.Size = UDim2.new(1, 0, 0, 18)
editHint.TextXAlignment = Enum.TextXAlignment.Center

--------------------------------------------------------------------
--  DATA
--------------------------------------------------------------------
local function fetchCatalog()
	local ok, data = pcall(remote.InvokeServer, remote, "Catalog")
	if ok and type(data) == "table" then catalog = data else warn("[ClassScreen] could not fetch catalog:", data) end
	buildPreviews()
	for id, c in pairs(cards) do
		local cls = catalog and catalog.classes and catalog.classes[id]
		local sm = cls and cls.summary
		c.sum.Text = sm and ((sm.helmet or "—") .. "  ·  " .. (sm.top or "—") .. "  ·  " .. (sm.bottom or "—") .. "\n" .. sm.weapon .. (sm.weaponSkin and ("  (" .. sm.weaponSkin .. ")") or "") .. (sm.secondary and ("  +  " .. sm.secondary) or "")) or "—"
	end
end

local function teamInfo()
	if (roundNode:GetAttribute("Teams") or 0) ~= 2 then return "" end
	local t = player.Team
	if not t then return "  ·  team assigned when you spawn" end
	for _, def in pairs(GameConfig.TEAMS) do
		if def.name == t.Name then return string.format('  ·  team <font color="#%s"><b>%s</b></font>', def.rgb:ToHex(), string.upper(def.name)) end
	end
	return "  ·  team " .. t.Name
end

local function refreshModeLine()
	local mode = roundNode:GetAttribute("ModeName") or ""
	local map = roundNode:GetAttribute("MapName") or roundNode:GetAttribute("Map") or ""
	local def = GameConfig.MODES[roundNode:GetAttribute("Mode") or ""]
	modeLine.Text = string.format("%s%s%s", mode, map ~= "" and ("  on  " .. map) or "", teamInfo())
	descLine.Text = def and def.description or ""
end

--------------------------------------------------------------------
--  OPEN / CLOSE
--------------------------------------------------------------------
local open = false        -- we want to be on screen (dead, in a match)
local hubOpen = false     -- the Hub menu is covering us
local waitReason = nil
local waveAt = nil   -- os.clock() when our reinforcement wave lands
local mouseConn

-- CameraRig fades to black when we die and, with no auto-respawn, nothing
-- ever clears it: lift it here so the menu opens over the cinematic camera
local function clearDeathFade()
	local fade = playerGui:FindFirstChild("DeathFade")
	pcall(RunService.UnbindFromRenderStep, RunService, "DeathCam")
	local cam = workspace.CurrentCamera
	if cam and cam.CameraType ~= Enum.CameraType.Scriptable then
		cam.CameraType = Enum.CameraType.Custom
		cam.FieldOfView = 70
	end
	if fade and fade:GetAttribute("DeathScreen") then
		fade:SetAttribute("Lift", true)   -- (DeathScreen lifts its veil and goes)
	elseif fade then
		local black = fade:FindFirstChildOfClass("Frame")
		if black then TweenService:Create(black, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play() end
		task.delay(0.7, function() if fade.Parent then fade:Destroy() end end)
	end
end

local function inCourtyard()
	return roundNode:GetAttribute("Mode") == "Hub"
end

local function voting() return roundNode:GetAttribute("State") == "Intermission" end

local spectating = false   -- the Spectate script has the screen

local function present()
	gui.Enabled = open and not hubOpen and not voting() and not spectating
	if gui.Enabled then
		panel.Position = UDim2.fromScale(0.5, 0.53)
		TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
	end
	if gui.Enabled and not mouseConn then
		mouseConn = RunService.RenderStepped:Connect(function()
			-- (only while it's really up: Ctrl+H or a showcase can hide it with this still connected)
			if not gui.Enabled then return end
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end)
	elseif not gui.Enabled and mouseConn then
		mouseConn:Disconnect(); mouseConn = nil
	end
end

local function show(active, reason)
	-- (you just fell: the fall is seen first — DeathScreen's HoldUntil — then the screen comes)
	local fade = playerGui:FindFirstChild("DeathFade")
	local hold = fade and fade:GetAttribute("HoldUntil")
	if hold and os.clock() < hold then task.delay(hold - os.clock(), show, active, reason); return end
	-- (a battle's own finale has the screen a few seconds first: War.client's _G.BoardHoldUntil)
	local held = _G.BoardHoldUntil
	if held and os.clock() < held then task.delay(held - os.clock(), show, active, reason); return end
	clearDeathFade()
	waitReason = reason
	if inCourtyard() then
		-- the courtyard has its own front door
		open = false
		present()
		bus:Fire("OpenHub", "PLAY")
		return
	end
	fetchCatalog()
	if GameConfig.CLASSES[active] then selected = active elseif catalog and GameConfig.CLASSES[catalog.active] then selected = catalog.active end
	paint()
	event:FireServer("Pick", selected)
	refreshModeLine()
	spawnBtn.Text = "SPAWN"
	open = true
	present()
end

local function hide()
	open = false
	present()
end

-- state line under the button, every half second while up
RunService.Heartbeat:Connect(function()
	if not open then return end
	local st = roundNode:GetAttribute("State")
	if st == "Intermission" then
		spawnBtn.Text = string.format("NEXT ROUND IN %d", roundNode:GetAttribute("TimeLeft") or 0)
		spawnBtn.BackgroundColor3 = COL_SPAWN
		local nxt = GameConfig.MODES[roundNode:GetAttribute("NextMode") or ""]
		waitLine.Text = nxt and ("next:  " .. string.upper(nxt.name)) or (waitReason or "")
	elseif waveAt and os.clock() < waveAt then
		spawnBtn.Text = string.format("REINFORCEMENTS IN %d", math.ceil(waveAt - os.clock()))
		spawnBtn.BackgroundColor3 = COL_SPAWN
		waitLine.Text = "you join the next wave"
	elseif spawnBtn.Text:sub(1, 4) == "NEXT" then
		spawnBtn.Text = "SPAWN"
		spawnBtn.BackgroundColor3 = COL_SPAWN_ON
		waitLine.Text = waitReason or ""
		refreshModeLine()
	elseif roundNode:GetAttribute("ObjKind") == "Horde" and roundNode:GetAttribute("ObjState") == "break" then
		-- (the next wave takes you in by itself, as the class you're on)
		local d = GameConfig.CLASSES[selected]
		waitLine.Text = string.format("%s  ·  or you go in as %s when it starts", roundNode:GetAttribute("ObjNote") or "NEXT WAVE SOON", d and string.upper(d.name) or "your class")
	else
		waitLine.Text = waitReason or ""
	end
end)

local function trySpawn()
	if not open or roundNode:GetAttribute("State") == "Intermission" then return end
	if waveAt and os.clock() < waveAt then return end   -- already waiting for the wave
	if not GameConfig.CLASSES[selected] then return end
	spawnBtn.Text = "SPAWNING…"
	event:FireServer("Spawn", selected)
end
spawnBtn.Activated:Connect(trySpawn)

spectateBtn.Activated:Connect(function()
	if not open then return end
	spectating = true
	present()
	bus:Fire("Spectate", true)
end)

-- what the spectate bar shows on its SPAWN button, and as which class
_G.ClassScreen = {
	spawnText = function() return spawnBtn.Text end,
	className = function() local d = GameConfig.CLASSES[selected]; return d and d.name or "" end,
}

event.OnClientEvent:Connect(function(what, a, b)
	if what == "Show" then
		waveAt = nil
		show(a, b)
	elseif what == "Spawned" then
		waveAt = nil
		spectating = false
		hide()
	elseif what == "Wave" then
		waveAt = os.clock() + (tonumber(a) or 0)
	end
end)

-- step aside while the round is being voted on; back when it starts
roundNode:GetAttributeChangedSignal("State"):Connect(function()
	if open then
		if not voting() then fetchCatalog(); refreshModeLine() end
		present()
	end
end)

bus.Event:Connect(function(what)
	if what == "SpectateStarted" then
		spectating = true
		present()
	elseif what == "SpectateEnd" then
		spectating = false
		if open then fetchCatalog(); refreshModeLine() end
		present()
	elseif what == "SpawnNow" then
		trySpawn()
	elseif what == "HubOpened" then
		hubOpen = true; present()
	elseif what == "HubClosed" then
		hubOpen = false
		if open then fetchCatalog(); refreshModeLine() end
		present()
	end
end)

-- tell the server we're listening; it answers "Show" if we have no body yet
event:FireServer("Ready")

fitCards = function()
	local phone = Device.kind() == "phone"
	panel.Size = phone and UDim2.fromScale(0.96, 0.94) or UDim2.fromScale(0.8, 0.72)
	-- (a phone has no room for the class's line under the cards, nor the mode's description)
	cardRow.Position = UDim2.new(0, 0, 0, phone and 58 or 88)
	cardRow.Size = phone and UDim2.new(1, 0, 1, -58 - 130) or UDim2.new(1, 0, 1, -88 - 150)
	classLine.Visible = not phone
	descLine.Visible = not phone
	for _, c in pairs(cards) do
		if c.desc then c.desc.Visible = not phone end
		c.vp.Size = phone and UDim2.new(1, 16, 1, -50 - 64) or UDim2.new(1, 16, 1, -50 - 122)
	end
end
Device.changed:Connect(fitCards)
fitCards()
