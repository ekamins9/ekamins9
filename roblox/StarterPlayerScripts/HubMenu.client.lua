--[[ HUB MENU — the main menu. Press M (or arrive in the courtyard with no
     body) and it opens over a slow cinematic camera (workspace.Map.MenuCamera
     when the map has one). Tabs:
       PLAY      the game modes (GameConfig.MODE_ORDER) with live player
                 counts, QUICK PLAY, custom servers, what this server runs;
                 RETURN TO HUB from any match (one mode per place, never
                 switched — travel is a teleport; Studio switches locally)
       SERVERS   the browser: every server that heartbeats into the registry,
                 filters (hide empty · custom only · type of gameplay), JOIN —
                 plus your friends who are online in the game, one click to join
       ARMORY    one saved loadout per class: pick the class, then armor of
                 that class's type and the weapons it may carry; SAVE writes it
                 to your profile, SET ACTIVE makes the spawn screen preselect it
       PARTY     make a party, invite people, accept invites; a party travels
                 together and lands on the same team
       SETTINGS  camera feel, keybinds, attack side (ClientSettings)
     ENTER COURTYARD (bottom left, Hub only) spawns you to walk around.

     Talks to HubServer (ReplicatedStorage.HubRemote / HubEvent) and to
     LoadoutServer (LoadoutRemote "Catalog", LoadoutEvent "Spawn"). The class
     screen (LoadoutMenu) and this script share one client-side BindableEvent,
     _G.MenuBus:  "OpenHub", tab  ·  "HubOpened"  ·  "HubClosed". ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local GameConfig     = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))

local player        = Players.LocalPlayer
local hubRemote     = ReplicatedStorage:WaitForChild("HubRemote")
local hubEvent      = ReplicatedStorage:WaitForChild("HubEvent")
local loadoutRemote = ReplicatedStorage:WaitForChild("LoadoutRemote")
local loadoutEvent  = ReplicatedStorage:WaitForChild("LoadoutEvent")
local roundNode     = ReplicatedStorage:WaitForChild("Round")
local playerGui     = player:WaitForChild("PlayerGui")

ClientSettings.load()

--------------------------------------------------------------------
local MENU_KEY        = Enum.KeyCode.M
local SERVER_REFRESH  = 10      -- seconds between browser refreshes while the tab is up
local CINE_FOV        = 62
local TOAST_TTL       = 3.5
--------------------------------------------------------------------

_G.MenuBus = _G.MenuBus or Instance.new("BindableEvent")
local bus = _G.MenuBus

-- one server call, never throws: {ok=false, msg=} on any failure
local function call(op, ...)
	local ok, res = pcall(hubRemote.InvokeServer, hubRemote, op, ...)
	if ok and type(res) == "table" then return res end
	return {ok = false, msg = ok and "no answer" or tostring(res)}
end

--------------------------------------------------------------------
--  LOOK
--------------------------------------------------------------------
local FONT       = Enum.Font.GothamBold
local FONT_BLACK = Enum.Font.GothamBlack
local FONT_BODY  = Enum.Font.Gotham
local COL_BACK    = Color3.fromRGB(8, 7, 6)
local COL_PANEL   = Color3.fromRGB(22, 20, 18)
local COL_SIDE    = Color3.fromRGB(16, 15, 13)
local COL_CARD    = Color3.fromRGB(38, 35, 31)
local COL_CARD_ON = Color3.fromRGB(96, 78, 46)
local COL_TEXT    = Color3.fromRGB(235, 228, 214)
local COL_DIM     = Color3.fromRGB(160, 150, 135)
local COL_ACCENT  = Color3.fromRGB(196, 150, 70)
local COL_GO      = Color3.fromRGB(120, 42, 34)
local COL_GO_ON   = Color3.fromRGB(170, 58, 44)
local COL_GOOD    = Color3.fromRGB(110, 170, 100)
local COL_BAD     = Color3.fromRGB(200, 80, 70)
local TYPE_COL    = {Light = Color3.fromRGB(96, 160, 96), Medium = Color3.fromRGB(190, 160, 70), Heavy = Color3.fromRGB(180, 80, 70)}
local CAT_COL     = {Arena = Color3.fromRGB(120, 150, 200), Battlefield = Color3.fromRGB(200, 120, 80), Hub = Color3.fromRGB(150, 150, 150)}

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
	b.TextColor3 = COL_TEXT
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local function frame(parent, color, corner)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = color or COL_CARD
	f.BorderSizePixel = 0
	f.Parent = parent
	if corner then Instance.new("UICorner", f).CornerRadius = UDim.new(0, corner) end
	return f
end

local function padding(parent, l, r, t, b)
	local p = Instance.new("UIPadding", parent)
	p.PaddingLeft, p.PaddingRight = UDim.new(0, l), UDim.new(0, r or l)
	p.PaddingTop, p.PaddingBottom = UDim.new(0, t or l), UDim.new(0, b or t or l)
	return p
end

local function scroll(parent, gap)
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 4
	s.ScrollBarImageColor3 = COL_ACCENT
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.Size = UDim2.fromScale(1, 1)
	s.Parent = parent
	local l = Instance.new("UIListLayout", s)
	l.Padding = UDim.new(0, gap or 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	return s
end

local function clear(container, keepNames)
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("GuiObject") and not (keepNames and keepNames[c.Name]) then c:Destroy() end
	end
end

--------------------------------------------------------------------
--  TOASTS + INVITE CARD (always-on ScreenGui, above everything)
--------------------------------------------------------------------
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "HubToasts"
toastGui.ResetOnSpawn = false
toastGui.IgnoreGuiInset = true
toastGui.DisplayOrder = 2200
toastGui.Parent = playerGui

local toastStack = Instance.new("Frame")
toastStack.AnchorPoint = Vector2.new(0.5, 1)
toastStack.Position = UDim2.new(0.5, 0, 1, -110)
toastStack.Size = UDim2.fromOffset(520, 200)
toastStack.BackgroundTransparency = 1
toastStack.Parent = toastGui
local tl = Instance.new("UIListLayout", toastStack)
tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
tl.VerticalAlignment = Enum.VerticalAlignment.Bottom
tl.Padding = UDim.new(0, 6)
tl.SortOrder = Enum.SortOrder.LayoutOrder

local toastOrder = 0
local function toast(text, color)
	if not text or text == "" then return end
	toastOrder += 1
	local row = frame(toastStack, COL_PANEL, 8)
	row.BackgroundTransparency = 0.15
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.fromOffset(0, 34)
	row.LayoutOrder = toastOrder
	padding(row, 14, 14, 0, 0)
	local s = Instance.new("UIStroke", row); s.Color = color or COL_ACCENT; s.Transparency = 0.4
	local t = label(row, text, 15, FONT, color or COL_TEXT)
	t.AutomaticSize = Enum.AutomaticSize.X
	t.Size = UDim2.new(0, 0, 1, 0)
	t.TextWrapped = false
	task.delay(TOAST_TTL, function()
		if not row.Parent then return end
		TweenService:Create(row, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
		TweenService:Create(t, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		TweenService:Create(s, TweenInfo.new(0.4), {Transparency = 1}):Play()
		task.delay(0.45, function() if row.Parent then row:Destroy() end end)
	end)
end

-- party invite: a card bottom right you can answer without opening the menu
local inviteCard = frame(toastGui, COL_PANEL, 10)
inviteCard.AnchorPoint = Vector2.new(1, 1)
inviteCard.Position = UDim2.new(1, -20, 1, -110)
inviteCard.Size = UDim2.fromOffset(300, 86)
inviteCard.Visible = false
local ics = Instance.new("UIStroke", inviteCard); ics.Color = COL_ACCENT; ics.Transparency = 0.4
padding(inviteCard, 12, 12, 10, 10)
local inviteText = label(inviteCard, "", 15, FONT, COL_TEXT)
inviteText.Size = UDim2.new(1, 0, 0, 36)
local acceptBtn = button(inviteCard, "ACCEPT", 14, COL_GO_ON)
acceptBtn.Position = UDim2.new(0, 0, 1, -28)
acceptBtn.Size = UDim2.new(0.5, -4, 0, 28)
local ignoreBtn = button(inviteCard, "IGNORE", 14, COL_CARD)
ignoreBtn.Position = UDim2.new(0.5, 4, 1, -28)
ignoreBtn.Size = UDim2.new(0.5, -4, 0, 28)

-- "M — menu" hint while you're bodiless in the courtyard with the menu closed
local hint = label(toastGui, "M  —  menu", 14, FONT, COL_DIM)
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 24, 1, -24)
hint.Size = UDim2.fromOffset(200, 20)
hint.TextStrokeTransparency = 0.5
hint.Visible = false

--------------------------------------------------------------------
--  MENU SHELL
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "HubMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2050   -- above the class screen (2000), under toasts
gui.Enabled = false
gui.Parent = playerGui

local backdrop = frame(gui, COL_BACK)
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundTransparency = 0.45
backdrop.Active = true   -- clicks on the dark are GUI input, not swings

local panel = frame(backdrop, COL_PANEL, 12)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.9, 0.86)
local ps = Instance.new("UIStroke", panel); ps.Color = COL_ACCENT; ps.Thickness = 1.5; ps.Transparency = 0.5
Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(1500, 900)

-- header
local header = frame(panel, COL_PANEL)
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundTransparency = 1
padding(header, 20, 20, 12, 0)
local title = label(header, "THE COURTYARD", 26, FONT_BLACK, COL_ACCENT)
title.Size = UDim2.new(0.6, 0, 0, 30)
local status = label(header, "", 13, FONT_BODY, COL_DIM)
status.Position = UDim2.new(0, 0, 0, 30)
status.Size = UDim2.new(0.75, 0, 0, 18)
local profileLine = label(header, "", 13, FONT, COL_DIM)
profileLine.AnchorPoint = Vector2.new(1, 0)
profileLine.Position = UDim2.new(1, -60, 0, 32)
profileLine.Size = UDim2.new(0.35, 0, 0, 18)
profileLine.TextXAlignment = Enum.TextXAlignment.Right
local closeBtn = button(header, "✕", 18, COL_CARD)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, 0, 0, 0)
closeBtn.Size = UDim2.fromOffset(44, 40)

-- side (tabs)
local side = frame(panel, COL_SIDE, 10)
side.Position = UDim2.new(0, 14, 0, 70)
side.Size = UDim2.new(0, 190, 1, -84)
padding(side, 10, 10, 10, 10)
local sideList = Instance.new("UIListLayout", side)
sideList.Padding = UDim.new(0, 6)
sideList.SortOrder = Enum.SortOrder.LayoutOrder

-- content
local content = frame(panel, COL_PANEL)
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 218, 0, 70)
content.Size = UDim2.new(1, -232, 1, -84)

local TABS = {"PLAY", "SERVERS", "ARMORY", "PARTY", "SETTINGS"}
local tabBtn, tabFrame, tabOpen = {}, {}, {}   -- opened callbacks refresh data
local currentTab = "PLAY"

for i, name in ipairs(TABS) do
	local b = button(side, name, 16, COL_CARD)
	b.Size = UDim2.new(1, 0, 0, 44)
	b.LayoutOrder = i
	b.TextXAlignment = Enum.TextXAlignment.Left
	padding(b, 14, 0, 0, 0)
	tabBtn[name] = b
	local f = frame(content, COL_PANEL)
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 1)
	f.Visible = false
	tabFrame[name] = f
end

-- bottom of the side bar: the big action + a hint
local actionBtn = button(side, "ENTER COURTYARD", 15, COL_GO_ON)
actionBtn.Size = UDim2.new(1, 0, 0, 48)
actionBtn.LayoutOrder = 50
local hubBtn = button(side, "⌂  RETURN TO HUB", 14, COL_CARD)
hubBtn.Size = UDim2.new(1, 0, 0, 40)
hubBtn.LayoutOrder = 49
hubBtn.Visible = false
local sideHint = label(side, "", 12, FONT_BODY, COL_DIM)
sideHint.Size = UDim2.new(1, 0, 0, 60)
sideHint.LayoutOrder = 51
sideHint.TextYAlignment = Enum.TextYAlignment.Top
local spacer = frame(side, COL_SIDE)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 40
spacer.Size = UDim2.new(1, 0, 1, -(5 * 50 + 46 + 48 + 60 + 40))

local open = false
local listening = nil   -- keybind capture (settings)

local function selectTab(name)
	if not tabFrame[name] then name = "PLAY" end
	currentTab = name
	listening = nil
	for n, f in ipairs(TABS) do
		local on = f == name
		tabFrame[f].Visible = on
		tabBtn[f].BackgroundColor3 = on and COL_CARD_ON or COL_CARD
		tabBtn[f].TextColor3 = on and COL_TEXT or COL_DIM
	end
	if tabOpen[name] then task.spawn(tabOpen[name]) end
end
for _, name in ipairs(TABS) do tabBtn[name].Activated:Connect(function() selectTab(name) end) end

--------------------------------------------------------------------
--  SHARED STATE
--------------------------------------------------------------------
local state = {studio = false, placesReady = false, custom = nil, party = nil, profile = nil, servers = {}, friends = {}, catalog = nil, activeClass = nil}

local function alive()
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0 and c.Parent ~= nil
end
local function inHub() return roundNode:GetAttribute("Mode") == "Hub" end
local function roundState() return roundNode:GetAttribute("State") or "" end

local function refreshHeader()
	local modeName = roundNode:GetAttribute("ModeName") or ""
	local map = roundNode:GetAttribute("Map") or ""
	status.Text = string.format("this server:  %s%s%s  ·  %d player%s%s", state.custom and ("[" .. state.custom .. "]  ") or "",
		modeName, map ~= "" and ("  on  " .. map) or "",
		#Players:GetPlayers(), #Players:GetPlayers() == 1 and "" or "s",
		state.studio and "  ·  Studio (no teleports: PLAY switches this server)" or "")
	hubBtn.Visible = not inHub()
	local st = state.profile and state.profile.stats
	if st then
		profileLine.Text = string.format("%s   ·   %d kills  %d deaths  %d wins", player.DisplayName, st.kills or 0, st.deaths or 0, st.wins or 0)
	else
		profileLine.Text = player.DisplayName
	end
	-- the side-bar action depends on where we are
	if alive() then
		actionBtn.Text = "RESUME"
		actionBtn.BackgroundColor3 = COL_CARD
		sideHint.Text = inHub() and "You're in the courtyard. Pick a mode on PLAY to go fight." or "Back to the fight."
	elseif inHub() and roundState() == "Round" then
		actionBtn.Text = "ENTER COURTYARD"
		actionBtn.BackgroundColor3 = COL_GO_ON
		local cls = state.activeClass and GameConfig.CLASSES[state.activeClass]
		sideHint.Text = "Walk around, warm up on the dummies." .. (cls and ("\nSpawning as " .. cls.name .. " (change it in ARMORY).") or "")
	else
		actionBtn.Text = "TO SPAWN SCREEN"
		actionBtn.BackgroundColor3 = COL_CARD
		sideHint.Text = roundState() == "Intermission" and "Next round starting soon." or "Pick a class and spawn."
	end
end

local function loadState()
	local r = call("State")
	if r.ok then
		state.studio = r.studio == true
		state.placesReady = r.placesReady == true
		state.custom = r.custom
		state.party = r.party
		state.profile = r.profile
		state.activeClass = r.profile and r.profile.active
	end
	refreshHeader()
end

--------------------------------------------------------------------
--  PLAY TAB
--------------------------------------------------------------------
do
	local f = tabFrame.PLAY
	local top = frame(f, COL_CARD, 10)
	top.Size = UDim2.new(1, 0, 0, 92)
	padding(top, 16, 16, 12, 12)
	local quick = button(top, "⚔  QUICK PLAY", 20, COL_GO_ON)
	quick.Size = UDim2.new(0, 260, 1, 0)
	local quickHint = label(top, "Drops you into the busiest fight. Below: every mode, with how many are playing right now across all servers.", 13, FONT_BODY, COL_DIM)
	quickHint.Position = UDim2.new(0, 280, 0, 0)
	quickHint.Size = UDim2.new(1, -280, 0, 40)
	local playNote = label(top, "", 12, FONT_BODY, COL_ACCENT)
	playNote.Position = UDim2.new(0, 280, 0, 44)
	playNote.Size = UDim2.new(1, -280, 0, 28)

	-- custom servers: name it here, then CUSTOM on a mode card
	local customRow = frame(f, COL_CARD, 10)
	customRow.Position = UDim2.new(0, 0, 0, 100)
	customRow.Size = UDim2.new(1, 0, 0, 44)
	padding(customRow, 16, 16, 7, 7)
	local customLbl = label(customRow, "CUSTOM SERVER", 13, FONT, COL_TEXT)
	customLbl.Size = UDim2.fromOffset(130, 30)
	local nameBox = Instance.new("TextBox")
	nameBox.PlaceholderText = player.DisplayName .. "'s server"
	nameBox.Text = ""
	nameBox.ClearTextOnFocus = false
	nameBox.Font = FONT_BODY
	nameBox.TextSize = 14
	nameBox.TextColor3 = COL_TEXT
	nameBox.PlaceholderColor3 = COL_DIM
	nameBox.BackgroundColor3 = COL_PANEL
	nameBox.BorderSizePixel = 0
	nameBox.Position = UDim2.new(0, 140, 0, 0)
	nameBox.Size = UDim2.new(0, 260, 0, 30)
	nameBox.TextXAlignment = Enum.TextXAlignment.Left
	nameBox.Parent = customRow
	Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 6)
	padding(nameBox, 10, 10, 0, 0)
	local customHint = label(customRow, "Name it, then press CUSTOM on a mode. A fresh server of that mode, listed in the browser under CUSTOM ONLY — friends and your party can join it.", 12, FONT_BODY, COL_DIM)
	customHint.Position = UDim2.new(0, 416, 0, 0)
	customHint.Size = UDim2.new(1, -416, 0, 30)

	local grid = Instance.new("ScrollingFrame")
	grid.Position = UDim2.new(0, 0, 0, 156)
	grid.Size = UDim2.new(1, 0, 1, -156)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 4
	grid.ScrollBarImageColor3 = COL_ACCENT
	grid.CanvasSize = UDim2.new()
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.Parent = f
	local gl = Instance.new("UIGridLayout", grid)
	gl.CellSize = UDim2.new(0.5, -8, 0, 172)
	gl.CellPadding = UDim2.fromOffset(12, 12)
	gl.SortOrder = Enum.SortOrder.LayoutOrder

	local countLabels = {}
	local function play(modeId, customServer)
		playNote.Text = "…"
		local r = customServer and call("Custom", modeId, nameBox.Text) or call("Play", modeId)
		playNote.Text = r.msg or (r.ok and "ok" or "failed")
		toast((GameConfig.MODES[modeId] and GameConfig.MODES[modeId].name or modeId) .. ":  " .. (r.msg or ""), r.ok and COL_GOOD or COL_BAD)
	end

	for i, id in ipairs(GameConfig.MODE_ORDER) do
		local def = GameConfig.MODES[id]
		if def and not def.hidden then
			local card = frame(grid, COL_CARD, 10)
			card.LayoutOrder = i
			padding(card, 16, 16, 12, 12)
			local n = label(card, string.upper(def.name), 20, FONT_BLACK, COL_TEXT)
			n.Size = UDim2.new(1, -110, 0, 26)
			local tag = label(card, string.upper(def.category) .. "  ·  " .. (def.teams == 2 and "2 TEAMS" or "SOLO") .. "  ·  UP TO " .. tostring(def.maxPlayers or 0), 11, FONT, CAT_COL[def.category] or COL_DIM)
			tag.Position = UDim2.new(0, 0, 0, 26)
			tag.Size = UDim2.new(1, -110, 0, 16)
			local d = label(card, def.description or "", 13, FONT_BODY, COL_DIM)
			d.Position = UDim2.new(0, 0, 0, 48)
			d.Size = UDim2.new(1, -110, 0, 54)
			d.TextYAlignment = Enum.TextYAlignment.Top
			local maps = label(card, "maps:  " .. table.concat(def.maps or {}, ", "), 12, FONT_BODY, COL_DIM)
			maps.Position = UDim2.new(0, 0, 1, -18)
			maps.Size = UDim2.new(1, -110, 0, 16)
			local count = label(card, "", 22, FONT_BLACK, COL_ACCENT)
			count.AnchorPoint = Vector2.new(1, 0)
			count.Position = UDim2.new(1, 0, 0, 0)
			count.Size = UDim2.fromOffset(100, 28)
			count.TextXAlignment = Enum.TextXAlignment.Right
			local countSub = label(card, "playing", 11, FONT, COL_DIM)
			countSub.AnchorPoint = Vector2.new(1, 0)
			countSub.Position = UDim2.new(1, 0, 0, 28)
			countSub.Size = UDim2.fromOffset(100, 14)
			countSub.TextXAlignment = Enum.TextXAlignment.Right
			countLabels[id] = count
			local b = button(card, "PLAY", 15, COL_GO)
			b.AnchorPoint = Vector2.new(1, 1)
			b.Position = UDim2.new(1, 0, 1, 0)
			b.Size = UDim2.fromOffset(100, 36)
			b.Activated:Connect(function() play(id) end)
			local cb = button(card, "CUSTOM", 12, COL_CARD_ON)
			cb.AnchorPoint = Vector2.new(1, 1)
			cb.Position = UDim2.new(1, 0, 1, -42)
			cb.Size = UDim2.fromOffset(100, 26)
			cb.Activated:Connect(function() play(id, true) end)
		end
	end

	local function refreshCounts()
		local counts = {}
		for _, s in ipairs(state.servers) do counts[s.mode] = (counts[s.mode] or 0) + (s.players or 0) end
		for id, l in pairs(countLabels) do l.Text = tostring(counts[id] or 0) end
	end

	quick.Activated:Connect(function()
		-- the mode with the most players; nobody anywhere → the first in the list
		local best, bestN = GameConfig.MODE_ORDER[1], -1
		local counts = {}
		for _, s in ipairs(state.servers) do counts[s.mode] = (counts[s.mode] or 0) + (s.players or 0) end
		for _, id in ipairs(GameConfig.MODE_ORDER) do
			if (counts[id] or 0) > bestN then best, bestN = id, counts[id] or 0 end
		end
		play(best)
	end)

	tabOpen.PLAY = function()
		local r = call("Servers")
		if r.ok then state.servers = r.servers or {} end
		refreshCounts()
		playNote.Text = state.studio
			and "Studio: no teleports here, so PLAY switches THIS server's mode (in the Hub at once, in a match at the intermission by majority). Live, PLAY teleports you and your party to the mode's place."
			or (state.placesReady and "Each mode runs in its own place. PLAY teleports you and your party there — Roblox joins a server with room or starts a new one."
				or "Some place ids in GameConfig.PLACES are still 0 — those modes can't be travelled to until you paste them in.")
	end
end

--------------------------------------------------------------------
--  SERVERS TAB (browser + friends)
--------------------------------------------------------------------
do
	local f = tabFrame.SERVERS
	local filters = {hideEmpty = true, customOnly = false, category = "All"}
	local chipRow = frame(f, COL_PANEL)
	chipRow.BackgroundTransparency = 1
	chipRow.Size = UDim2.new(1, 0, 0, 34)
	local cl = Instance.new("UIListLayout", chipRow)
	cl.FillDirection = Enum.FillDirection.Horizontal
	cl.Padding = UDim.new(0, 6)
	cl.SortOrder = Enum.SortOrder.LayoutOrder
	cl.VerticalAlignment = Enum.VerticalAlignment.Center

	local chips = {}
	local refreshList
	local function chip(text, order, isOn, onClick)
		local b = button(chipRow, text, 13, COL_CARD)
		b.LayoutOrder = order
		b.AutomaticSize = Enum.AutomaticSize.X
		b.Size = UDim2.fromOffset(0, 30)
		padding(b, 12, 12, 0, 0)
		local function paint() b.BackgroundColor3 = isOn() and COL_CARD_ON or COL_CARD; b.TextColor3 = isOn() and COL_TEXT or COL_DIM end
		b.Activated:Connect(function() onClick(); for _, p in ipairs(chips) do p() end; refreshList() end)
		table.insert(chips, paint)
		paint()
		return b
	end
	chip("HIDE EMPTY", 1, function() return filters.hideEmpty end, function() filters.hideEmpty = not filters.hideEmpty end)
	chip("CUSTOM ONLY", 2, function() return filters.customOnly end, function() filters.customOnly = not filters.customOnly end)
	local sep = label(chipRow, "  type:", 13, FONT, COL_DIM)
	sep.LayoutOrder = 3
	sep.Size = UDim2.fromOffset(52, 30)
	sep.TextWrapped = false
	local cats = {"All"}
	do
		local seen = {}
		for _, id in ipairs(GameConfig.MODE_ORDER) do
			local c = GameConfig.MODES[id] and GameConfig.MODES[id].category
			if c and not seen[c] then seen[c] = true; table.insert(cats, c) end
		end
		table.insert(cats, "Hub")
	end
	for i, c in ipairs(cats) do
		chip(string.upper(c), 3 + i, function() return filters.category == c end, function() filters.category = c end)
	end
	local refreshBtn = button(chipRow, "↻  REFRESH", 13, COL_CARD)
	refreshBtn.LayoutOrder = 20
	refreshBtn.Size = UDim2.fromOffset(110, 30)
	local countText = label(chipRow, "", 13, FONT_BODY, COL_DIM)
	countText.LayoutOrder = 21
	countText.Size = UDim2.fromOffset(160, 30)
	countText.TextWrapped = false

	-- server list (left) — header row + rows
	local left = frame(f, COL_PANEL)
	left.BackgroundTransparency = 1
	left.Position = UDim2.new(0, 0, 0, 44)
	left.Size = UDim2.new(0.66, -8, 1, -44)
	local COLS = {{"SERVER", 0.30}, {"MODE", 0.22}, {"MAP", 0.18}, {"PLAYERS", 0.14}, {"", 0.16}}
	local head = frame(left, COL_PANEL)
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, 0, 0, 20)
	do
		local x = 0
		for _, c in ipairs(COLS) do
			local t = label(head, c[1], 11, FONT, COL_DIM)
			t.Position = UDim2.new(x, 8, 0, 0)
			t.Size = UDim2.new(c[2], -8, 1, 0)
			x += c[2]
		end
	end
	local listHolder = frame(left, COL_PANEL)
	listHolder.BackgroundTransparency = 1
	listHolder.Position = UDim2.new(0, 0, 0, 24)
	listHolder.Size = UDim2.new(1, 0, 1, -24)
	local list = scroll(listHolder, 6)

	local function joinServer(s)
		local r = call("Join", s.jobId, s.placeId)
		toast(r.msg or (r.ok and "joining…" or "could not join"), r.ok and COL_GOOD or COL_BAD)
	end

	refreshList = function()
		clear(list)
		local shown = 0
		for i, s in ipairs(state.servers) do
			local ok = true
			if filters.hideEmpty and (s.players or 0) == 0 and not s.here then ok = false end
			if filters.customOnly and not s.custom then ok = false end
			if filters.category ~= "All" and s.category ~= filters.category then ok = false end
			if ok then
				shown += 1
				local row = frame(list, s.here and COL_CARD_ON or COL_CARD, 6)
				row.Size = UDim2.new(1, -6, 0, 40)
				row.LayoutOrder = i
				row.BackgroundTransparency = s.here and 0.3 or 0
				local x = 0
				local name = (s.custom and s.name ~= "" and s.name) or ("Official  #" .. string.sub(tostring(s.jobId or "?"), 1, 6))
				local cells = {name .. (s.here and "   (you're here)" or ""), s.modeName ~= "" and s.modeName or s.mode, s.map,
					string.format("%d / %d", s.players or 0, s.max or 0)}
				for ci, c in ipairs(COLS) do
					if ci <= 4 then
						local t = label(row, cells[ci], 14, ci == 1 and FONT or FONT_BODY, ci == 4 and ((s.players or 0) >= (s.max or 1) and COL_BAD or COL_TEXT) or COL_TEXT)
						t.Position = UDim2.new(x, 8, 0, 0)
						t.Size = UDim2.new(c[2], -8, 1, 0)
						t.TextWrapped = false
						t.TextTruncate = Enum.TextTruncate.AtEnd
					end
					x += c[2]
				end
				local b = button(row, s.here and "HERE" or (s.state == "Intermission" and "JOIN  (between rounds)" or "JOIN"), 13, s.here and COL_CARD or COL_GO)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -6, 0.5, 0)
				b.Size = UDim2.new(0.16, -10, 0, 30)
				b.TextTruncate = Enum.TextTruncate.AtEnd
				if s.here then b.AutoButtonColor = false else b.Activated:Connect(function() joinServer(s) end) end
			end
		end
		countText.Text = string.format("%d of %d server%s", shown, #state.servers, #state.servers == 1 and "" or "s")
		if shown == 0 then
			local t = label(list, #state.servers == 0 and "No servers answered — in Studio only this one exists." or "Nothing matches these filters.", 14, FONT_BODY, COL_DIM)
			t.Size = UDim2.new(1, 0, 0, 40)
		end
	end

	-- friends (right)
	local right = frame(f, COL_CARD, 10)
	right.Position = UDim2.new(0.66, 4, 0, 44)
	right.Size = UDim2.new(0.34, -4, 1, -44)
	padding(right, 12, 12, 10, 10)
	local fh = label(right, "FRIENDS IN THE GAME", 14, FONT, COL_TEXT)
	fh.Size = UDim2.new(1, 0, 0, 22)
	local fsub = label(right, "Friends online in this game, and everyone in this server. JOIN takes you (and your party) to their server.", 12, FONT_BODY, COL_DIM)
	fsub.Position = UDim2.new(0, 0, 0, 22)
	fsub.Size = UDim2.new(1, 0, 0, 44)
	local fHolder = frame(right, COL_CARD)
	fHolder.BackgroundTransparency = 1
	fHolder.Position = UDim2.new(0, 0, 0, 70)
	fHolder.Size = UDim2.new(1, 0, 1, -70)
	local flist = scroll(fHolder, 6)

	local function refreshFriends()
		clear(flist)
		for i, fr in ipairs(state.friends) do
			local row = frame(flist, COL_PANEL, 6)
			row.Size = UDim2.new(1, -6, 0, 40)
			row.LayoutOrder = i
			padding(row, 10, 6, 0, 0)
			local n = label(row, fr.name or "?", 14, FONT, COL_TEXT)
			n.Size = UDim2.new(1, -90, 0, 22)
			n.TextWrapped = false
			n.TextTruncate = Enum.TextTruncate.AtEnd
			local st = label(row, fr.here and "in this server" or (fr.inGame and "in another server" or "online elsewhere"), 11, FONT_BODY, fr.here and COL_GOOD or COL_DIM)
			st.Position = UDim2.new(0, 0, 0, 20)
			st.Size = UDim2.new(1, -90, 0, 16)
			local b = button(row, fr.here and "INVITE" or (fr.inGame and "JOIN" or "—"), 12, fr.here and COL_CARD or (fr.inGame and COL_GO or COL_CARD))
			b.AnchorPoint = Vector2.new(1, 0.5)
			b.Position = UDim2.new(1, 0, 0.5, 0)
			b.Size = UDim2.fromOffset(78, 28)
			if fr.here then
				b.Activated:Connect(function()
					local r = call("PartyInvite", fr.id)
					toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
					if r.party then state.party = r.party end
				end)
			elseif fr.inGame then
				b.Activated:Connect(function()
					local r = call("JoinFriend", fr.id)
					toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
				end)
			else
				b.AutoButtonColor = false
			end
		end
		if #state.friends == 0 then
			local t = label(flist, "Nobody yet.", 13, FONT_BODY, COL_DIM)
			t.Size = UDim2.new(1, 0, 0, 30)
		end
	end

	local function refreshAll()
		refreshBtn.Text = "…"
		local r = call("Servers")
		if r.ok then state.servers = r.servers or {} end
		local fr = call("Friends")
		if fr.ok then state.friends = fr.friends or {} end
		refreshList()
		refreshFriends()
		refreshBtn.Text = "↻  REFRESH"
	end
	refreshBtn.Activated:Connect(function() task.spawn(refreshAll) end)
	tabOpen.SERVERS = refreshAll

	-- auto refresh while the tab is up
	task.spawn(function()
		while true do
			task.wait(SERVER_REFRESH)
			if open and currentTab == "SERVERS" then refreshAll() end
		end
	end)
end

--------------------------------------------------------------------
--  ARMORY TAB (one loadout per class)
--------------------------------------------------------------------
do
	local f = tabFrame.ARMORY
	local NONE = "__none"
	local classRow = frame(f, COL_PANEL)
	classRow.BackgroundTransparency = 1
	classRow.Size = UDim2.new(1, 0, 0, 74)
	local crl = Instance.new("UIListLayout", classRow)
	crl.FillDirection = Enum.FillDirection.Horizontal
	crl.Padding = UDim.new(0, 10)
	crl.SortOrder = Enum.SortOrder.LayoutOrder

	local classBtn = {}
	local editing = GameConfig.DEFAULT_CLASS
	local edit = {}          -- [classId] = {armor=, weapon=, secondary=}
	local dirty = {}         -- [classId] = true when unsaved
	local cards = {armor = {}, weapon = {}, secondary = {}}
	local lastKind = "weapon"

	local body = frame(f, COL_PANEL)
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0, 0, 0, 84)
	body.Size = UDim2.new(1, 0, 1, -84)
	local bl = Instance.new("UIListLayout", body)
	bl.FillDirection = Enum.FillDirection.Horizontal
	bl.Padding = UDim.new(0, 12)
	bl.SortOrder = Enum.SortOrder.LayoutOrder

	local function column(widthScale, order)
		local c = frame(body, COL_PANEL)
		c.BackgroundTransparency = 1
		c.Size = UDim2.new(widthScale, -8, 1, 0)
		c.LayoutOrder = order
		return c
	end
	local function listBox(parent, heading, y, h)
		local hl = label(parent, heading, 15, FONT, COL_TEXT)
		hl.Position = UDim2.new(0, 0, y, 0)
		hl.Size = UDim2.new(1, 0, 0, 22)
		local holder = frame(parent, COL_PANEL)
		holder.BackgroundTransparency = 1
		holder.Position = UDim2.new(0, 0, y, 26)
		holder.Size = UDim2.new(1, 0, h, -30)
		return scroll(holder, 6), hl
	end
	local armorCol = column(0.27, 1)
	local armorList, armorHead = listBox(armorCol, "ARMOR", 0, 1)
	local weaponCol = column(0.30, 2)
	local primaryList = listBox(weaponCol, "PRIMARY", 0, 0.58)
	local secondList  = listBox(weaponCol, "SECONDARY", 0.6, 0.4)
	local right = column(0.43, 3)
	local rl = Instance.new("UIListLayout", right)
	rl.Padding = UDim.new(0, 10)
	rl.SortOrder = Enum.SortOrder.LayoutOrder

	local function statBox(order)
		local box = frame(right, COL_CARD, 8)
		box.Size = UDim2.new(1, 0, 0.5, -46)
		box.LayoutOrder = order
		padding(box, 12, 12, 10, 10)
		local name = label(box, "", 19, FONT, COL_TEXT); name.Size = UDim2.new(1, 0, 0, 24)
		local badge = label(box, "", 12, FONT, COL_ACCENT); badge.Size = UDim2.new(1, 0, 0, 16); badge.Position = UDim2.new(0, 0, 0, 24)
		local desc = label(box, "", 13, FONT_BODY, COL_DIM); desc.Position = UDim2.new(0, 0, 0, 44); desc.Size = UDim2.new(1, 0, 0, 50); desc.TextYAlignment = Enum.TextYAlignment.Top
		local stats = label(box, "", 14, FONT_BODY, COL_TEXT); stats.Position = UDim2.new(0, 0, 0, 98); stats.Size = UDim2.new(1, 0, 1, -98); stats.TextYAlignment = Enum.TextYAlignment.Top; stats.RichText = true
		return {name = name, badge = badge, desc = desc, stats = stats}
	end
	local armorBox, weaponBox = statBox(1), statBox(2)
	local btnRow = frame(right, COL_PANEL)
	btnRow.BackgroundTransparency = 1
	btnRow.Size = UDim2.new(1, 0, 0, 44)
	btnRow.LayoutOrder = 3
	local saveBtn = button(btnRow, "SAVE", 17, COL_GO_ON)
	saveBtn.Size = UDim2.new(0.5, -4, 1, 0)
	local activeBtn = button(btnRow, "SET ACTIVE", 15, COL_CARD)
	activeBtn.Position = UDim2.new(0.5, 4, 0, 0)
	activeBtn.Size = UDim2.new(0.5, -4, 1, 0)
	local loadoutLine = label(right, "", 12, FONT_BODY, COL_DIM)
	loadoutLine.Size = UDim2.new(1, 0, 0, 30)
	loadoutLine.LayoutOrder = 4
	loadoutLine.TextXAlignment = Enum.TextXAlignment.Center

	local function pct(mult, up, down)
		if math.abs(mult - 1) < 0.005 then return "normal" end
		return string.format("%d%% %s", math.floor(math.abs(mult - 1) * 100 + 0.5), mult > 1 and up or down)
	end
	local function line(k, v) return string.format('<font color="#a09687">%s</font>  %s', k, v) end
	local function armorStats(a)
		return table.concat({
			line("Class", a.type or "Light"),
			line("Health", a.health and a.health > 0 and ("+" .. a.health) or "no bonus"),
			line("Speed", pct(a.speedMult or 1, "faster", "slower")),
			line("Footsteps", pct(a.clunkMult or 1, "heavier", "lighter")),
			line("Protection", string.format("%d%% less damage on covered limbs", math.floor((a.protection or 0) * 100 + 0.5))),
		}, "\n")
	end
	local function weaponStats(w)
		local dmg = "?"
		if w.damageMin and w.damageMax then dmg = w.damageMin == w.damageMax and tostring(w.damageMin) or (w.damageMin .. " – " .. w.damageMax) end
		local kinds = {}
		if w.slash then table.insert(kinds, "slash") end
		if w.stab then table.insert(kinds, "stab") end
		return table.concat({
			line("Damage", dmg .. (w.damageMax and "  (head ×2)" or "")),
			line("Reach", w.reach and string.format("%.0f studs", w.reach) or "?"),
			line("Tempo", pct(w.speedMult or 1, "faster", "slower")),
			line("Grip", w.twoHanded and "two-handed" or "one-handed"),
			line("Weight", pct(w.weightSpeed or 1, "faster", "slower") .. " on foot"),
			line("Attacks", #kinds > 0 and table.concat(kinds, " + ") or "?"),
			line("Slot", w.secondary and "primary or secondary" or "primary only"),
			line("Classes", table.concat(w.classes or {}, ", ")),
		}, "\n")
	end

	local function byId(list, id)
		for _, it in ipairs(list or {}) do if it.id == id then return it end end
		return nil
	end

	local function paint(kind)
		local cur = edit[editing] or {}
		for id, card in pairs(cards[kind]) do
			local on = (cur[kind] or (kind == "secondary" and NONE)) == id
			card.BackgroundColor3 = on and COL_CARD_ON or COL_CARD
			card.Stroke.Transparency = on and 0 or 1
		end
	end

	local function refreshDetails()
		local cat = state.catalog
		if not cat then return end
		local cur = edit[editing] or {}
		local a = byId(cat.armors, cur.armor)
		local w = byId(cat.weapons, cur.weapon)
		local s = byId(cat.weapons, cur.secondary)
		local shown = lastKind == "secondary" and s or w
		armorBox.name.Text = a and a.name or "No armor"
		armorBox.badge.Text = a and string.upper(a.type or "") or ""
		armorBox.badge.TextColor3 = a and (TYPE_COL[a.type] or COL_ACCENT) or COL_ACCENT
		armorBox.desc.Text = a and a.description or "Pick a set on the left."
		armorBox.stats.Text = a and armorStats(a) or ""
		weaponBox.name.Text = shown and shown.name or (lastKind == "secondary" and "No secondary" or "No weapon")
		weaponBox.badge.Text = shown and ((lastKind == "secondary" and "SECONDARY  ·  " or "PRIMARY  ·  ") .. (shown.twoHanded and "TWO-HANDED" or "ONE-HANDED")) or ""
		weaponBox.desc.Text = shown and shown.description or "Pick a weapon in the middle."
		weaponBox.stats.Text = shown and weaponStats(shown) or ""
		local cls = GameConfig.CLASSES[editing]
		loadoutLine.Text = string.format("%s:  %s  ·  %s%s%s", cls and cls.name or editing, a and a.name or "no armor", w and w.name or "no weapon",
			s and ("  +  " .. s.name) or "", dirty[editing] and "   (unsaved)" or "")
		saveBtn.Text = dirty[editing] and "SAVE" or "SAVED ✓"
		saveBtn.BackgroundColor3 = dirty[editing] and COL_GO_ON or COL_CARD
		activeBtn.Text = state.activeClass == editing and "ACTIVE CLASS ✓" or "SET ACTIVE"
		activeBtn.BackgroundColor3 = state.activeClass == editing and COL_CARD_ON or COL_CARD
	end

	local function choose(kind, id)
		local cur = edit[editing]
		if not cur then return end
		if kind == "secondary" and id ~= NONE and id == cur.weapon then cur.weapon = nil; paint("weapon")
		elseif kind == "weapon" and id == cur.secondary then cur.secondary = nil; paint("secondary") end
		cur[kind] = (id == NONE) and nil or id
		if kind ~= "armor" then lastKind = kind end
		dirty[editing] = true
		paint(kind)
		refreshDetails()
	end

	local function makeCard(list, kind, item, order)
		local card = Instance.new("TextButton")
		card.Name = item.id
		card.Size = UDim2.new(1, -6, 0, 50)
		card.LayoutOrder = order
		card.BackgroundColor3 = COL_CARD
		card.BorderSizePixel = 0
		card.AutoButtonColor = false
		card.Text = ""
		card.Parent = list
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
		local s = Instance.new("UIStroke", card); s.Name = "Stroke"; s.Color = COL_ACCENT; s.Thickness = 1.5; s.Transparency = 1
		padding(card, 10, 10, 0, 0)
		local n = label(card, item.name, 15, FONT, COL_TEXT); n.Size = UDim2.new(1, 0, 0, 28); n.Position = UDim2.new(0, 0, 0, 3); n.TextWrapped = false; n.TextTruncate = Enum.TextTruncate.AtEnd
		local tag = label(card, "", 11, FONT, COL_DIM); tag.Size = UDim2.new(1, 0, 0, 16); tag.Position = UDim2.new(0, 0, 0, 29)
		if kind == "armor" then
			tag.Text = string.upper(item.type or ""); tag.TextColor3 = TYPE_COL[item.type] or COL_DIM
		elseif item.id == NONE then
			tag.Text = "travel light"
		else
			local bits = {}
			if item.damageMax then table.insert(bits, "dmg " .. item.damageMin .. "–" .. item.damageMax) end
			if item.reach then table.insert(bits, string.format("reach %.0f", item.reach)) end
			table.insert(bits, item.twoHanded and "2H" or "1H")
			tag.Text = table.concat(bits, "   ")
		end
		card.MouseEnter:Connect(function() if card.Stroke.Transparency > 0.5 then card.BackgroundColor3 = COL_CARD:Lerp(COL_CARD_ON, 0.35) end end)
		card.MouseLeave:Connect(function() if card.Stroke.Transparency > 0.5 then card.BackgroundColor3 = COL_CARD end end)
		card.Activated:Connect(function() choose(kind, item.id) end)
		cards[kind][item.id] = card
	end

	local function allows(w, classId)
		for _, c in ipairs(w.classes or {}) do if c == classId then return true end end
		return false
	end

	-- rebuild the three lists for the class being edited
	local function populate()
		local cat = state.catalog
		if not cat then return end
		local cls = GameConfig.CLASSES[editing]
		for _, l in ipairs({armorList, primaryList, secondList}) do clear(l) end
		cards = {armor = {}, weapon = {}, secondary = {}}
		armorHead.Text = "ARMOR  ·  " .. string.upper(cls and cls.armorType or "")
		armorHead.TextColor3 = TYPE_COL[cls and cls.armorType] or COL_TEXT
		local na, nw, ns = 0, 0, 0
		for i, a in ipairs(cat.armors) do
			if not cls or a.type == cls.armorType then na += 1; makeCard(armorList, "armor", a, i) end
		end
		for i, w in ipairs(cat.weapons) do
			if allows(w, editing) then
				nw += 1; makeCard(primaryList, "weapon", w, i)
				if w.secondary then ns += 1; makeCard(secondList, "secondary", w, i) end
			end
		end
		makeCard(secondList, "secondary", {id = NONE, name = "None"}, 0)
		if na == 0 then local t = label(armorList, "No " .. string.lower(cls and cls.armorType or "") .. " set in ServerStorage.Armor (Config.Type)", 13, FONT_BODY, COL_DIM); t.Size = UDim2.new(1, 0, 0, 40) end
		if nw == 0 then local t = label(primaryList, "No weapon allowed for this class (GameConfig.CLASSES.weapons)", 13, FONT_BODY, COL_DIM); t.Size = UDim2.new(1, 0, 0, 40) end
		if ns == 0 then local t = label(secondList, "No weapon has SECONDARY = true yet", 12, FONT_BODY, COL_DIM); t.Size = UDim2.new(1, 0, 0, 30); t.LayoutOrder = 99 end
		paint("armor"); paint("weapon"); paint("secondary")
		refreshDetails()
	end

	local function paintClasses()
		for id, b in pairs(classBtn) do
			local on = id == editing
			b.BackgroundColor3 = on and COL_CARD_ON or COL_CARD
			b.Stroke.Transparency = on and 0 or 1
			local sub = b:FindFirstChild("Sub")
			if sub then
				local cls = state.catalog and state.catalog.classes and state.catalog.classes[id]
				local sm = cls and cls.summary
				sub.Text = (sm and (sm.armor .. "  ·  " .. sm.weapon .. (sm.secondary and ("  +  " .. sm.secondary) or "")) or "")
					.. (state.activeClass == id and "   ★" or "")
			end
		end
	end

	for i, id in ipairs(GameConfig.CLASS_ORDER) do
		local def = GameConfig.CLASSES[id]
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1 / #GameConfig.CLASS_ORDER, -8, 1, 0)
		b.LayoutOrder = i
		b.BackgroundColor3 = COL_CARD
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Text = ""
		b.Parent = classRow
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		local s = Instance.new("UIStroke", b); s.Name = "Stroke"; s.Color = COL_ACCENT; s.Thickness = 1.5; s.Transparency = 1
		padding(b, 12, 12, 0, 0)
		local n = label(b, string.upper(def.name), 18, FONT_BLACK, COL_TEXT); n.Size = UDim2.new(1, 0, 0, 26); n.Position = UDim2.new(0, 0, 0, 8)
		local tg = label(b, string.upper(def.armorType) .. " ARMOR", 11, FONT, TYPE_COL[def.armorType] or COL_DIM); tg.Size = UDim2.new(1, 0, 0, 14); tg.Position = UDim2.new(0, 0, 0, 32)
		local sub = label(b, "", 11, FONT_BODY, COL_DIM); sub.Name = "Sub"; sub.Size = UDim2.new(1, 0, 0, 16); sub.Position = UDim2.new(0, 0, 0, 50); sub.TextWrapped = false; sub.TextTruncate = Enum.TextTruncate.AtEnd
		b.Activated:Connect(function() editing = id; lastKind = "weapon"; paintClasses(); populate() end)
		classBtn[id] = b
	end

	local function loadCatalog()
		local ok, data = pcall(loadoutRemote.InvokeServer, loadoutRemote, "Catalog")
		if not (ok and type(data) == "table") then
			toast("could not load the armory", COL_BAD)
			return
		end
		state.catalog = data
		state.activeClass = data.active or state.activeClass
		for id, c in pairs(data.classes or {}) do
			if not dirty[id] then
				local lo = c.loadout or {}
				edit[id] = {armor = lo.armor, weapon = lo.weapon, secondary = lo.secondary}
			end
		end
		paintClasses()
		populate()
	end

	saveBtn.Activated:Connect(function()
		local cur = edit[editing]
		if not cur then return end
		saveBtn.Text = "…"
		local r = call("SaveClass", editing, {armor = cur.armor, weapon = cur.weapon, secondary = cur.secondary})
		if r.ok then
			dirty[editing] = nil
			if type(r.loadout) == "table" then edit[editing] = {armor = r.loadout.armor, weapon = r.loadout.weapon, secondary = r.loadout.secondary} end
			toast((GameConfig.CLASSES[editing] and GameConfig.CLASSES[editing].name or editing) .. " saved", COL_GOOD)
			loadCatalog()   -- summaries on the class tabs
		else
			toast(r.msg or "save failed", COL_BAD)
			refreshDetails()
		end
	end)
	activeBtn.Activated:Connect(function()
		local r = call("SetActive", editing)
		if r.ok then state.activeClass = editing; toast("Spawning as " .. (GameConfig.CLASSES[editing] and GameConfig.CLASSES[editing].name or editing), COL_GOOD) end
		paintClasses(); refreshDetails(); refreshHeader()
	end)

	tabOpen.ARMORY = function()
		editing = state.activeClass or editing
		loadCatalog()
	end
end

--------------------------------------------------------------------
--  PARTY TAB
--------------------------------------------------------------------
do
	local f = tabFrame.PARTY
	local left = frame(f, COL_CARD, 10)
	left.Size = UDim2.new(0.45, -6, 1, 0)
	padding(left, 14, 14, 12, 12)
	local ph = label(left, "YOUR PARTY", 16, FONT, COL_TEXT)
	ph.Size = UDim2.new(1, 0, 0, 24)
	local psub = label(left, "A party travels together — PLAY, JOIN and JOIN FRIEND take everyone — and lands on the same team. Up to 6. Only the leader picks where you go.", 12, FONT_BODY, COL_DIM)
	psub.Position = UDim2.new(0, 0, 0, 26)
	psub.Size = UDim2.new(1, 0, 0, 50)
	local membersHolder = frame(left, COL_CARD)
	membersHolder.BackgroundTransparency = 1
	membersHolder.Position = UDim2.new(0, 0, 0, 84)
	membersHolder.Size = UDim2.new(1, 0, 1, -140)
	local members = scroll(membersHolder, 6)
	local partyBtn = button(left, "CREATE PARTY", 15, COL_GO_ON)
	partyBtn.AnchorPoint = Vector2.new(0, 1)
	partyBtn.Position = UDim2.new(0, 0, 1, 0)
	partyBtn.Size = UDim2.new(1, 0, 0, 44)

	local right = frame(f, COL_CARD, 10)
	right.Position = UDim2.new(0.45, 6, 0, 0)
	right.Size = UDim2.new(0.55, -6, 1, 0)
	padding(right, 14, 14, 12, 12)
	local ih = label(right, "INVITE", 16, FONT, COL_TEXT)
	ih.Size = UDim2.new(1, 0, 0, 24)
	local isub = label(right, "People in this server. Friends in other servers can be joined from SERVERS → FRIENDS.", 12, FONT_BODY, COL_DIM)
	isub.Position = UDim2.new(0, 0, 0, 26)
	isub.Size = UDim2.new(1, 0, 0, 34)
	local inviteHolder = frame(right, COL_CARD)
	inviteHolder.BackgroundTransparency = 1
	inviteHolder.Position = UDim2.new(0, 0, 0, 66)
	inviteHolder.Size = UDim2.new(1, 0, 1, -66)
	local inviteList = scroll(inviteHolder, 6)

	local function refreshParty()
		clear(members)
		local p = state.party
		if p and p.members then
			for i, m in ipairs(p.members) do
				local row = frame(members, COL_PANEL, 6)
				row.Size = UDim2.new(1, -6, 0, 36)
				row.LayoutOrder = i
				padding(row, 10, 10, 0, 0)
				local t = label(row, (m.leader and "♛  " or "") .. m.name .. (m.id == player.UserId and "  (you)" or ""), 14, m.leader and FONT or FONT_BODY, m.leader and COL_ACCENT or COL_TEXT)
				t.Size = UDim2.new(1, 0, 1, 0)
			end
			partyBtn.Text = "LEAVE PARTY"
			partyBtn.BackgroundColor3 = COL_CARD
		else
			local t = label(members, "You're on your own. Create a party and invite people, or accept an invite.", 13, FONT_BODY, COL_DIM)
			t.Size = UDim2.new(1, 0, 0, 40)
			partyBtn.Text = "CREATE PARTY"
			partyBtn.BackgroundColor3 = COL_GO_ON
		end
		clear(inviteList)
		local n = 0
		for i, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				n += 1
				local inParty = false
				if p and p.members then for _, m in ipairs(p.members) do if m.id == other.UserId then inParty = true end end end
				local row = frame(inviteList, COL_PANEL, 6)
				row.Size = UDim2.new(1, -6, 0, 36)
				row.LayoutOrder = i
				padding(row, 10, 6, 0, 0)
				local t = label(row, other.DisplayName, 14, FONT_BODY, COL_TEXT)
				t.Size = UDim2.new(1, -90, 1, 0)
				local b = button(row, inParty and "IN PARTY" or "INVITE", 12, inParty and COL_CARD or COL_GO)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, 0, 0.5, 0)
				b.Size = UDim2.fromOffset(80, 26)
				if inParty then b.AutoButtonColor = false else
					b.Activated:Connect(function()
						local r = call("PartyInvite", other.UserId)
						toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
						if r.party then state.party = r.party; refreshParty() end
					end)
				end
			end
		end
		if n == 0 then
			local t = label(inviteList, "Nobody else is in this server.", 13, FONT_BODY, COL_DIM)
			t.Size = UDim2.new(1, 0, 0, 30)
		end
	end
	partyBtn.Activated:Connect(function()
		if state.party then
			call("PartyLeave"); state.party = nil; toast("left the party", COL_DIM)
		else
			local r = call("PartyCreate"); if r.ok then state.party = r.party; toast("party created — invite someone", COL_GOOD) end
		end
		refreshParty()
	end)
	tabOpen.PARTY = function() loadState(); refreshParty() end
	bus.Event:Connect(function(what) if what == "PartyChanged" and open and currentTab == "PARTY" then refreshParty() end end)
end

--------------------------------------------------------------------
--  SETTINGS TAB (camera feel · attack side · keybinds)
--------------------------------------------------------------------
do
	local f = tabFrame.SETTINGS
	local sHint = label(f, "Camera feel is a multiplier on the tuned default (1.0); 0 turns an effect off. Right mouse is always block.", 13, FONT_BODY, COL_DIM)
	sHint.Size = UDim2.new(1, -170, 0, 32)
	local resetBtn = button(f, "RESET DEFAULTS", 13, COL_CARD)
	resetBtn.AnchorPoint = Vector2.new(1, 0)
	resetBtn.Position = UDim2.new(1, 0, 0, 0)
	resetBtn.Size = UDim2.fromOffset(150, 32)

	local sBody = frame(f, COL_PANEL)
	sBody.BackgroundTransparency = 1
	sBody.Position = UDim2.new(0, 0, 0, 44)
	sBody.Size = UDim2.new(1, 0, 1, -44)
	local sLayout = Instance.new("UIListLayout", sBody)
	sLayout.FillDirection = Enum.FillDirection.Horizontal
	sLayout.Padding = UDim.new(0, 24)

	local function settingsColumn(heading, widthScale)
		local col = frame(sBody, COL_PANEL)
		col.BackgroundTransparency = 1
		col.Size = UDim2.new(widthScale, -12, 1, 0)
		local h = label(col, heading, 16, FONT, COL_TEXT)
		h.Size = UDim2.new(1, 0, 0, 26)
		local holder = frame(col, COL_PANEL)
		holder.BackgroundTransparency = 1
		holder.Position = UDim2.new(0, 0, 0, 30)
		holder.Size = UDim2.new(1, 0, 1, -30)
		return scroll(holder, 10)
	end
	local camCol = settingsColumn("CAMERA FEEL", 0.55)
	local keyCol = settingsColumn("KEYBINDS", 0.45)

	local sliderRefresh, keyRefresh, choiceRefresh = {}, {}, {}
	local function sliderRow(spec, order)
		local row = frame(camCol, COL_PANEL)
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -8, 0, 52)
		row.LayoutOrder = order
		local name = label(row, spec.label, 14, FONT, COL_TEXT); name.Size = UDim2.new(0.7, 0, 0, 20)
		local val = label(row, "", 14, FONT, COL_ACCENT); val.AnchorPoint = Vector2.new(1, 0); val.Position = UDim2.new(1, 0, 0, 0); val.Size = UDim2.new(0.3, 0, 0, 20); val.TextXAlignment = Enum.TextXAlignment.Right
		local h = label(row, spec.hint or "", 11, FONT_BODY, COL_DIM); h.Position = UDim2.new(0, 0, 0, 20); h.Size = UDim2.new(1, 0, 0, 14); h.TextWrapped = false; h.TextTruncate = Enum.TextTruncate.AtEnd
		local track = Instance.new("TextButton")
		track.Text = ""; track.AutoButtonColor = false
		track.Position = UDim2.new(0, 0, 0, 40); track.Size = UDim2.new(1, 0, 0, 10)
		track.BackgroundColor3 = Color3.new(0, 0, 0); track.BackgroundTransparency = 0.5; track.BorderSizePixel = 0
		track.Parent = row
		Instance.new("UICorner", track).CornerRadius = UDim.new(0, 5)
		local fill = frame(track, COL_ACCENT, 5); fill.Size = UDim2.fromScale(0.5, 1)
		local knob = frame(track, COL_TEXT); knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Size = UDim2.fromOffset(18, 18); knob.Position = UDim2.new(0.5, 0, 0.5, 0)
		Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
		local function refresh()
			local v = ClientSettings.get(spec.key)
			local fr = (v - spec.min) / (spec.max - spec.min)
			fill.Size = UDim2.fromScale(fr, 1)
			knob.Position = UDim2.new(fr, 0, 0.5, 0)
			val.Text = spec.step and string.format("%d", v) or string.format("%d%%", math.floor(v * 100 + 0.5))
		end
		sliderRefresh[spec.key] = refresh
		refresh()
		local dragging = false
		local function setFromX(x)
			local fr = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			ClientSettings.set(spec.key, spec.min + fr * (spec.max - spec.min))
			refresh()
		end
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; setFromX(input.Position.X) end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then setFromX(input.Position.X) end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end)
	end
	for i, spec in ipairs(ClientSettings.SLIDERS) do sliderRow(spec, i) end

	local function keyRow(spec, order)
		local row = frame(keyCol, COL_PANEL)
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -8, 0, 34)
		row.LayoutOrder = order
		local name = label(row, spec.label, 14, FONT_BODY, COL_TEXT); name.Size = UDim2.new(0.55, 0, 1, 0)
		local btn = button(row, "", 13, COL_CARD)
		btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, 0, 0.5, 0); btn.Size = UDim2.new(0.42, 0, 0, 30)
		local function refresh()
			if listening and listening.key == spec.key then btn.Text = "press a key…"; btn.TextColor3 = COL_ACCENT
			else btn.Text = ClientSettings.get("Key_" .. spec.key); btn.TextColor3 = COL_TEXT end
		end
		keyRefresh[spec.key] = refresh
		refresh()
		btn.Activated:Connect(function()
			listening = {key = spec.key, since = os.clock()}
			for _, r in pairs(keyRefresh) do r() end
		end)
	end
	local function choiceRow(spec, order)
		local row = frame(keyCol, COL_PANEL)
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -8, 0, 56)
		row.LayoutOrder = order
		local name = label(row, spec.label, 14, FONT_BODY, COL_TEXT); name.Size = UDim2.new(0.55, 0, 0, 30)
		local h = label(row, spec.hint or "", 10, FONT_BODY, COL_DIM); h.Position = UDim2.new(0, 0, 0, 30); h.Size = UDim2.new(1, 0, 0, 26); h.TextYAlignment = Enum.TextYAlignment.Top
		local btn = button(row, "", 13, COL_CARD)
		btn.AnchorPoint = Vector2.new(1, 0); btn.Position = UDim2.new(1, 0, 0, 0); btn.Size = UDim2.new(0.42, 0, 0, 30)
		local function refresh() btn.Text = tostring(ClientSettings.get(spec.key)) .. "  ▸" end
		choiceRefresh[spec.key] = refresh
		refresh()
		btn.Activated:Connect(function()
			local cur = ClientSettings.get(spec.key)
			local idx = 1
			for i, o in ipairs(spec.options) do if o == cur then idx = i end end
			ClientSettings.set(spec.key, spec.options[idx % #spec.options + 1])
			refresh()
		end)
	end
	for i, spec in ipairs(ClientSettings.CHOICES) do choiceRow(spec, i) end
	for i, spec in ipairs(ClientSettings.KEYS) do keyRow(spec, 10 + i) end
	local keyHint = label(keyCol, "Binds take keys, left / middle mouse, or scroll up / down. Right mouse is always block; M is always this menu; hold Tab for the board. Roblox can't see Mouse 4 / 5 — bind them to a key in your mouse software and use that key here. Escape cancels a rebind.", 11, FONT_BODY, COL_DIM)
	keyHint.Size = UDim2.new(1, -8, 0, 72)
	keyHint.LayoutOrder = 99
	keyHint.TextYAlignment = Enum.TextYAlignment.Top

	local function captureBind(input)
		if not listening then return end
		if os.clock() - (listening.since or 0) < 0.2 then return end
		local name = ClientSettings.inputName(input)
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then name = nil
		elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Unknown then return end
		if name == MENU_KEY.Name then toast("M stays the menu key", COL_BAD); name = nil end
		if name then
			for _, k in ipairs(ClientSettings.KEYS) do
				if k.key ~= listening.key and ClientSettings.get("Key_" .. k.key) == name then
					ClientSettings.set("Key_" .. k.key, ClientSettings.get("Key_" .. listening.key))
				end
			end
			ClientSettings.set("Key_" .. listening.key, name)
		end
		listening = nil
		for _, r in pairs(keyRefresh) do r() end
	end
	UserInputService.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton3 then captureBind(input) end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if listening and input.UserInputType == Enum.UserInputType.MouseWheel and input.Position.Z ~= 0 then captureBind(input) end
	end)

	local function refreshAll()
		for _, r in pairs(sliderRefresh) do r() end
		for _, r in pairs(keyRefresh) do r() end
		for _, r in pairs(choiceRefresh) do r() end
	end
	ClientSettings.onChanged(function() refreshAll() end)
	resetBtn.Activated:Connect(function() ClientSettings.reset(); refreshAll() end)
	tabOpen.SETTINGS = refreshAll
end

--------------------------------------------------------------------
--  CINEMATIC CAMERA + MOUSE
--------------------------------------------------------------------
local cineOn = false
local function classScreenUp()
	local lm = playerGui:FindFirstChild("LoadoutMenu")
	return lm ~= nil and lm.Enabled
end

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local wantCine = (open or classScreenUp()) and not alive()
	if wantCine then
		cineOn = true
		cam.CameraType = Enum.CameraType.Scriptable
		local t = os.clock()
		local map = workspace:FindFirstChild("Map")
		local part = map and map:FindFirstChild("MenuCamera")
		if part and part:IsA("BasePart") then
			-- a slow breathe + drift around the author's camera
			local sway = CFrame.Angles(math.sin(t * 0.13) * 0.015, math.sin(t * 0.09) * 0.04, 0)
			cam.CFrame = part.CFrame * sway * CFrame.new(math.sin(t * 0.07) * 1.2, math.sin(t * 0.11) * 0.5, 0)
		else
			-- no MenuCamera part: a wide slow orbit of the spawn area
			local center = Vector3.new(0, 6, 0)
			local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
			if sp then center = sp.Position end
			local ang = t * 0.05
			cam.CFrame = CFrame.lookAt(center + Vector3.new(math.cos(ang) * 70, 32, math.sin(ang) * 70), center + Vector3.new(0, 4, 0))
		end
		cam.FieldOfView = CINE_FOV
	elseif cineOn then
		cineOn = false
		if not alive() then cam.CameraType = Enum.CameraType.Custom; cam.FieldOfView = 70 end
	end
	if open then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
	hint.Visible = not open and not alive() and inHub() and roundState() == "Round" and not classScreenUp()
end)

--------------------------------------------------------------------
--  OPEN / CLOSE
--------------------------------------------------------------------
local function show(tab)
	if not open then
		open = true
		gui.Enabled = true
		panel.Position = UDim2.fromScale(0.5, 0.53)
		TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		bus:Fire("HubOpened")
		task.spawn(loadState)
	end
	selectTab(tab or currentTab)
	refreshHeader()
end

local function hide()
	if not open then return end
	open = false
	listening = nil
	gui.Enabled = false
	bus:Fire("HubClosed")
end

closeBtn.Activated:Connect(hide)
hubBtn.Activated:Connect(function()
	hubBtn.Text = "…"
	local r = call("Hub")
	hubBtn.Text = "⌂  RETURN TO HUB"
	toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
end)
actionBtn.Activated:Connect(function()
	if not alive() and inHub() and roundState() == "Round" then
		actionBtn.Text = "SPAWNING…"
		loadoutEvent:FireServer("Spawn", state.activeClass)
	else
		hide()
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode ~= MENU_KEY or listening then return end
	if UserInputService:GetFocusedTextBox() then return end
	if open then hide() else show() end
end)

-- header refresh while open
task.spawn(function()
	while true do
		task.wait(1)
		if open then refreshHeader() end
	end
end)

--------------------------------------------------------------------
--  SERVER EVENTS
--------------------------------------------------------------------
local pendingInvite = nil
hubEvent.OnClientEvent:Connect(function(what, a, b)
	if what == "Toast" then
		toast(a)
	elseif what == "Party" then
		state.party = a
		bus:Fire("PartyChanged")
		if a and a.members then toast(string.format("party:  %d / 6", #a.members), COL_DIM) end
	elseif what == "Invite" then
		pendingInvite = b
		inviteText.Text = tostring(a) .. " invited you to their party"
		inviteCard.Visible = true
		task.delay(30, function() if pendingInvite == b then pendingInvite = nil; inviteCard.Visible = false end end)
	end
end)
acceptBtn.Activated:Connect(function()
	inviteCard.Visible = false
	pendingInvite = nil
	local r = call("PartyAccept")
	toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
	if r.party then state.party = r.party; bus:Fire("PartyChanged") end
end)
ignoreBtn.Activated:Connect(function() inviteCard.Visible = false; pendingInvite = nil end)

loadoutEvent.OnClientEvent:Connect(function(what)
	if what == "Spawned" then
		hide()
		task.delay(0.2, refreshHeader)
	end
end)

-- the class screen asks us to open (courtyard arrivals, its MENU / ARMORY / SETTINGS buttons)
bus.Event:Connect(function(what, tab)
	if what == "OpenHub" then show(tab) end
end)

-- first arrival in a Hub server with no body: open straight away
task.delay(1, function()
	if not alive() and inHub() and roundState() == "Round" and not open then show("PLAY") end
end)
