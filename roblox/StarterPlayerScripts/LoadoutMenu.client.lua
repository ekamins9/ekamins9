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
modeLine.Size = UDim2.new(1, -260, 0, 20)
modeLine.RichText = true

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

-- class cards
local cardRow = Instance.new("Frame")
cardRow.BackgroundTransparency = 1
cardRow.Position = UDim2.new(0, 0, 0, 68)
cardRow.Size = UDim2.new(1, 0, 1, -68 - 130)
cardRow.Parent = panel
local crl = Instance.new("UIListLayout", cardRow)
crl.FillDirection = Enum.FillDirection.Horizontal
crl.Padding = UDim.new(0, 14)
crl.SortOrder = Enum.SortOrder.LayoutOrder

local cards = {}   -- [classId] = {btn, sum, tag}
local selected = GameConfig.DEFAULT_CLASS
local catalog = nil

local function paint()
	for id, c in pairs(cards) do
		local on = id == selected
		TweenService:Create(c.btn, TweenInfo.new(0.12), {BackgroundColor3 = on and COL_CARD_ON or COL_CARD}):Play()
		c.stroke.Transparency = on and 0 or 1
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
	local tag = label(b, string.upper(def.armorType) .. " ARMOR", 12, FONT, TYPE_COL[def.armorType] or COL_DIM); tag.Position = UDim2.new(0, 0, 0, 32); tag.Size = UDim2.new(1, 0, 0, 16)
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
	local d = label(b, def.description or "", 13, FONT_BODY, COL_DIM); d.AnchorPoint = Vector2.new(0, 1); d.Position = UDim2.new(0, 0, 1, -62); d.Size = UDim2.new(1, 0, 0, 54); d.TextYAlignment = Enum.TextYAlignment.Top
	local lh = label(b, "LOADOUT", 11, FONT, COL_DIM); lh.AnchorPoint = Vector2.new(0, 1); lh.Position = UDim2.new(0, 0, 1, -44); lh.Size = UDim2.new(1, 0, 0, 14)
	local sum = label(b, "…", 14, FONT, COL_TEXT); sum.AnchorPoint = Vector2.new(0, 1); sum.Position = UDim2.new(0, 0, 1, 0); sum.Size = UDim2.new(1, 0, 0, 44); sum.TextYAlignment = Enum.TextYAlignment.Top
	b.MouseEnter:Connect(function() if selected ~= id then b.BackgroundColor3 = COL_CARD:Lerp(COL_CARD_ON, 0.35) end end)
	b.MouseLeave:Connect(function() if selected ~= id then b.BackgroundColor3 = COL_CARD end end)
	b.Activated:Connect(function() selected = id; paint() end)
	cards[id] = {btn = b, sum = sum, tag = tag, stroke = s, vp = vp, cam = cam}
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
RunService.RenderStepped:Connect(function(dt)
	local c = cards[selected]
	if not (c and c.rig and c.vp.Parent and c.vp:IsDescendantOf(game)) then return end
	if not (c.vp:FindFirstAncestorOfClass("ScreenGui") and c.vp:FindFirstAncestorOfClass("ScreenGui").Enabled) then return end
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
local editHint = label(panel, "Change a class's armor and weapons in ARMORY  ·  M opens the menu any time", 12, FONT_BODY, COL_DIM)
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
	modeLine.Text = string.format("%s%s%s%s", mode, map ~= "" and ("  on  " .. map) or "", teamInfo(),
		def and def.description and ("\n" .. def.description) or "")
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
	if fade then
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
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end)
	elseif not gui.Enabled and mouseConn then
		mouseConn:Disconnect(); mouseConn = nil
	end
end

local function show(active, reason)
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
