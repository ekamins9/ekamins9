--[[ HUB MENU — the main menu (M). Opens by itself when you have no body in
     the Courtyard, over the cinematic camera; in a match M pauses (same
     menu, RESUME / RETURN TO COURTYARD in the side bar). Escape belongs to
     Roblox, so M is the menu key everywhere.

       PLAY        the four DOORS (Courtyard · Tiltyard · Warfront · The Lists)
                   in the side bar, your party on the stage with READY-UP,
                   the leaderboard, contracts, friends; The Lists shows the
                   bracket / casual-ranked card and the queue
       APPEARANCE  hair, beard, face, skin, hair color, title (Catalog ▸ Body)
       CLASSES     one loadout per class: helmet / top / bottom of the class's
                   weight, color blocks, weapon + skin, secondary; TEAM PREVIEW
       SHOP        crates (the drum), packs, weapons, premium colors; GET CROWNS
                   (Robux products) and Crowns → Marks
       SERVERS     the browser with filters, and CREATE CUSTOM (all settings)
       SETTINGS    camera feel, keybinds, attack side (ClientSettings)

     Every mannequin is a real dressed rig (Dresser) in a ViewportFrame, so
     what you see is what spawns. Talks to HubServer (HubRemote / HubEvent)
     and LoadoutServer (LoadoutRemote "Catalog", LoadoutEvent "Spawn").
     _G.MenuBus: "OpenHub", tab · "HubOpened" · "HubClosed" (class screen). ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local GameConfig     = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Catalog        = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser        = require(ReplicatedStorage:WaitForChild("Dresser"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player        = Players.LocalPlayer
local hubRemote     = ReplicatedStorage:WaitForChild("HubRemote")
local hubEvent      = ReplicatedStorage:WaitForChild("HubEvent")
local loadoutRemote = ReplicatedStorage:WaitForChild("LoadoutRemote")
local loadoutEvent  = ReplicatedStorage:WaitForChild("LoadoutEvent")
local roundNode     = ReplicatedStorage:WaitForChild("Round")
local playerGui     = player:WaitForChild("PlayerGui")

ClientSettings.load()

-- the client's catalog only knows the armor sets once Cosmetics has replicated
do
	local cos = ReplicatedStorage:WaitForChild("Cosmetics", 30)
	local armor = cos and cos:WaitForChild("Armor", 10)
	if armor then
		if #armor:GetChildren() == 0 then armor.ChildAdded:Wait() end
		task.wait(0.2)
	end
	Catalog.rebuild()
end

--------------------------------------------------------------------
local MENU_KEY        = Enum.KeyCode.M
local SERVER_REFRESH  = 10
local CINE_FOV        = 62
local TOAST_TTL       = 3.5
local ECON            = Catalog.ECONOMY
--------------------------------------------------------------------

_G.MenuBus = _G.MenuBus or Instance.new("BindableEvent")
local bus = _G.MenuBus

-- one server call at a time, spaced for HubServer's rate limit; never throws
local callBusy, lastCallAt = false, 0
local function call(op, ...)
	while callBusy do task.wait() end
	callBusy = true
	local gap = 0.11 - (os.clock() - lastCallAt)
	if gap > 0 then task.wait(gap) end
	lastCallAt = os.clock()
	local ok, res = pcall(hubRemote.InvokeServer, hubRemote, op, ...)
	callBusy = false
	if ok and type(res) == "table" then return res end
	return {ok = false, msg = ok and "no answer" or tostring(res)}
end

local function fmt(n)
	n = math.floor(tonumber(n) or 0)
	local s = tostring(n)
	while true do
		local k; s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return s
end

--------------------------------------------------------------------
--  LOOK
--------------------------------------------------------------------
local FONT       = Theme.FONT
local FONT_BLACK = Theme.FONT_TITLE
local FONT_BODY  = Theme.FONT_BODY
local COL_BACK    = Theme.BACK
local COL_PANEL   = Theme.PANEL
local COL_SIDE    = Theme.SIDE
local COL_CARD    = Theme.CARD
local COL_CARD2   = Theme.CARD2
local COL_CARD_ON = Theme.CARD_ON
local COL_TEXT    = Theme.TEXT
local COL_DIM     = Theme.DIM
local COL_ACCENT  = Theme.ACCENT
local COL_GOLD    = Theme.GOLD
local COL_GO      = Theme.GO
local COL_GO_ON   = Theme.GO_ON
local COL_GOOD    = Theme.GOOD
local COL_BAD     = Theme.BAD
local COL_MARKS   = Theme.MARKS
local COL_CROWNS  = Theme.CROWNS
local TYPE_COL    = {Light = Color3.fromRGB(96, 160, 96), Medium = Color3.fromRGB(190, 160, 70), Heavy = Color3.fromRGB(180, 80, 70)}
local RARITY_COL  = {Common = Color3.fromRGB(93, 107, 122), Rare = Color3.fromRGB(47, 111, 176), Epic = Color3.fromRGB(122, 63, 176), Legendary = Color3.fromRGB(201, 154, 72)}

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
	local st = Instance.new("UIStroke", b); st.Color = Theme.STROKE; st.Transparency = 0.86; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		if b.TextColor3 == COL_TEXT or b.TextColor3 == Theme.INK then b.TextColor3 = Theme.textOn(b.BackgroundColor3) end
	end)
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

local function vlist(parent, gap)
	local l = Instance.new("UIListLayout", parent)
	l.Padding = UDim.new(0, gap or 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	return l
end
local function hlist(parent, gap)
	local l = vlist(parent, gap)
	l.FillDirection = Enum.FillDirection.Horizontal
	return l
end

local function clear(container)
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end

-- a titled panel; `quiet` = darker. Returns the panel and its inner list frame.
local orderN = 0
local function nextOrder() orderN += 1; return orderN end
local function panel(parent, heading, quiet)
	local p = frame(parent, quiet and COL_CARD2 or COL_CARD, 12)
	do local st = Instance.new("UIStroke", p); st.Color = Theme.STROKE; st.Transparency = 0.88 end
	p.AutomaticSize = Enum.AutomaticSize.Y
	p.Size = UDim2.new(1, 0, 0, 0)
	p.LayoutOrder = nextOrder()
	padding(p, 12, 12, 10, 12)
	vlist(p, 4)
	if heading then
		local h = label(p, string.upper(heading), 11, FONT, COL_DIM)
		h.Size = UDim2.new(1, 0, 0, 16)
		h.LayoutOrder = 0
	end
	return p
end
local function heading(parent, text)
	local h = label(parent, string.upper(text), 11, FONT, COL_DIM)
	h.Size = UDim2.new(1, 0, 0, 20)
	h.LayoutOrder = nextOrder()
	h.TextYAlignment = Enum.TextYAlignment.Bottom
	return h
end
local function dim(parent, text, size)
	local t = label(parent, text, size or 12, FONT_BODY, COL_DIM)
	t.AutomaticSize = Enum.AutomaticSize.Y
	t.Size = UDim2.new(1, 0, 0, 0)
	t.LayoutOrder = nextOrder()
	return t
end
-- a selectable row: text left, something right
local function row(parent, text, right, on, onClick, rightColor)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 30)
	b.LayoutOrder = nextOrder()
	b.BackgroundColor3 = on and COL_CARD_ON or COL_PANEL
	b.BorderSizePixel = 0
	b.AutoButtonColor = onClick ~= nil
	b.Text = ""
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	padding(b, 10, 10, 0, 0)
	local t = label(b, text, 13, on and FONT or FONT_BODY, COL_TEXT)
	t.Size = UDim2.new(0.6, 0, 1, 0)
	t.TextWrapped = false
	t.TextTruncate = Enum.TextTruncate.AtEnd
	if right and right ~= "" then
		local r = label(b, right, 12, FONT_BODY, rightColor or COL_DIM)
		r.AnchorPoint = Vector2.new(1, 0)
		r.Position = UDim2.new(1, 0, 0, 0)
		r.Size = UDim2.new(0.45, 0, 1, 0)
		r.TextXAlignment = Enum.TextXAlignment.Right
		r.TextWrapped = false
		r.TextTruncate = Enum.TextTruncate.AtEnd
	end
	if onClick then b.Activated:Connect(onClick) end
	return b
end
local function swatches(parent, items, isOn, isLocked, onClick)
	local holder = frame(parent, COL_CARD)
	holder.BackgroundTransparency = 1
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Size = UDim2.new(1, 0, 0, 0)
	holder.LayoutOrder = nextOrder()
	local g = Instance.new("UIGridLayout", holder)
	g.CellSize = UDim2.fromOffset(26, 26)
	g.CellPadding = UDim2.fromOffset(5, 5)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	for i, it in ipairs(items) do
		local b = Instance.new("TextButton")
		b.LayoutOrder = i
		b.BackgroundColor3 = it.color
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Text = isLocked(it) and "🔒" or ""
		b.TextSize = 11
		b.TextColor3 = COL_TEXT
		b.Parent = holder
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
		local s = Instance.new("UIStroke", b); s.Color = COL_TEXT; s.Thickness = 2; s.Transparency = isOn(it) and 0 or 1
		b.Activated:Connect(function() onClick(it) end)
	end
	return holder
end
local function chips(parent, items, isOn, onClick)
	local holder = frame(parent, COL_CARD)
	holder.BackgroundTransparency = 1
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Size = UDim2.new(1, 0, 0, 0)
	holder.LayoutOrder = nextOrder()
	local l = hlist(holder, 5)
	l.Wraps = true
	for i, it in ipairs(items) do
		local on = isOn(it)
		local b = button(holder, it.text, 11, on and COL_CARD_ON or COL_PANEL)
		b.LayoutOrder = i
		b.AutomaticSize = Enum.AutomaticSize.X
		b.Size = UDim2.fromOffset(0, 24)
		b.TextColor3 = on and COL_TEXT or COL_DIM
		padding(b, 10, 10, 0, 0)
		b.Activated:Connect(function() onClick(it) end)
	end
	return holder
end
local function bigBtn(parent, text, color, onClick)
	local b = button(parent, text, 14, color or COL_CARD)
	b.Size = UDim2.new(1, 0, 0, 36)
	b.LayoutOrder = nextOrder()
	if onClick then b.Activated:Connect(onClick) end
	return b
end
local function spacer(parent, h)
	local s = frame(parent, COL_CARD); s.BackgroundTransparency = 1; s.Size = UDim2.new(1, 0, 0, h or 6); s.LayoutOrder = nextOrder(); return s
end

--------------------------------------------------------------------
--  TOASTS, INVITE CARD, REWARDS CARD (always-on ScreenGui)
--------------------------------------------------------------------
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "HubToasts"
toastGui.ResetOnSpawn = false
toastGui.IgnoreGuiInset = true
toastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toastGui.DisplayOrder = 2200
toastGui.Parent = playerGui

local toastStack = frame(toastGui, COL_PANEL)
toastStack.BackgroundTransparency = 1
toastStack.AnchorPoint = Vector2.new(0.5, 1)
toastStack.Position = UDim2.new(0.5, 0, 1, -110)
toastStack.Size = UDim2.fromOffset(560, 200)
local tl = vlist(toastStack, 6)
tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
tl.VerticalAlignment = Enum.VerticalAlignment.Bottom

local function toast(text, color)
	if not text or text == "" then return end
	local r = frame(toastStack, COL_PANEL, 8)
	r.BackgroundTransparency = 0.15
	r.AutomaticSize = Enum.AutomaticSize.X
	r.Size = UDim2.fromOffset(0, 34)
	r.LayoutOrder = nextOrder()
	padding(r, 14, 14, 0, 0)
	local s = Instance.new("UIStroke", r); s.Color = color or COL_ACCENT; s.Transparency = 0.4
	local t = label(r, text, 15, FONT, color or COL_TEXT)
	t.AutomaticSize = Enum.AutomaticSize.X
	t.Size = UDim2.new(0, 0, 1, 0)
	t.TextWrapped = false
	task.delay(TOAST_TTL, function()
		if not r.Parent then return end
		TweenService:Create(r, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
		TweenService:Create(t, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		TweenService:Create(s, TweenInfo.new(0.4), {Transparency = 1}):Play()
		task.delay(0.45, function() if r.Parent then r:Destroy() end end)
	end)
end

local inviteCard = frame(toastGui, COL_PANEL, 10)
inviteCard.AnchorPoint = Vector2.new(1, 1)
inviteCard.Position = UDim2.new(1, -20, 1, -110)
inviteCard.Size = UDim2.fromOffset(300, 86)
inviteCard.Visible = false
do local s = Instance.new("UIStroke", inviteCard); s.Color = COL_ACCENT; s.Transparency = 0.4 end
padding(inviteCard, 12, 12, 10, 10)
local inviteText = label(inviteCard, "", 15, FONT, COL_TEXT)
inviteText.Size = UDim2.new(1, 0, 0, 36)
local acceptBtn = button(inviteCard, "ACCEPT", 14, COL_GO_ON)
acceptBtn.Position = UDim2.new(0, 0, 1, -28)
acceptBtn.Size = UDim2.new(0.5, -4, 0, 28)
local ignoreBtn = button(inviteCard, "IGNORE", 14, COL_CARD)
ignoreBtn.Position = UDim2.new(0.5, 4, 1, -28)
ignoreBtn.Size = UDim2.new(0.5, -4, 0, 28)

-- end-of-round pay card
local rewardCard = frame(toastGui, COL_PANEL, 10)
rewardCard.AnchorPoint = Vector2.new(0.5, 0)
rewardCard.Position = UDim2.new(0.5, 0, 0, 120)
rewardCard.Size = UDim2.fromOffset(420, 96)
rewardCard.Visible = false
do local s = Instance.new("UIStroke", rewardCard); s.Color = COL_GOLD; s.Transparency = 0.3 end
padding(rewardCard, 16, 16, 10, 10)
local rewardTitle = label(rewardCard, "", 18, FONT_BLACK, COL_GOLD); rewardTitle.Size = UDim2.new(1, 0, 0, 24); rewardTitle.TextXAlignment = Enum.TextXAlignment.Center
local rewardBody = label(rewardCard, "", 14, FONT, COL_TEXT); rewardBody.Position = UDim2.new(0, 0, 0, 26); rewardBody.Size = UDim2.new(1, 0, 0, 48); rewardBody.TextXAlignment = Enum.TextXAlignment.Center
local function showRewards(r)
	if r.blocked then
		rewardTitle.Text = "ROUND OVER"; rewardBody.Text = "No rewards on a cheat server."
	else
		rewardTitle.Text = (r.won and "VICTORY" or "ROUND OVER") .. (r.firstWin and "  ·  FIRST WIN OF THE DAY" or "")
		local bits = {string.format("+%s Marks", fmt(r.marks or 0)), string.format("+%s XP", fmt(r.xp or 0))}
		if (r.levels or 0) > 0 then table.insert(bits, "LEVEL " .. tostring(r.level) .. "!") end
		if r.delta then table.insert(bits, string.format("rating %s%d → %s", r.delta >= 0 and "+" or "", r.delta, fmt(r.rating))) end
		rewardBody.Text = table.concat(bits, "   ·   ") .. string.format("\n%d kills  ·  %d parries", r.kills or 0, r.parries or 0)
	end
	rewardCard.Visible = true
	task.delay(8, function() rewardCard.Visible = false end)
end

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
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 2050
gui.Enabled = false
gui.Parent = playerGui

local backdrop = frame(gui, COL_BACK)
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundTransparency = 0.35
backdrop.Active = true

local panelMain = frame(backdrop, COL_PANEL, 12)
panelMain.AnchorPoint = Vector2.new(0.5, 0.5)
panelMain.Position = UDim2.fromScale(0.5, 0.5)
panelMain.Size = UDim2.fromScale(0.92, 0.88)
do local s = Instance.new("UIStroke", panelMain); s.Color = Theme.STROKE; s.Thickness = 2; s.Transparency = 0.8 end
Instance.new("UISizeConstraint", panelMain).MaxSize = Vector2.new(1500, 920)

-- header: title · subtitle · wallet · close
local header = frame(panelMain, COL_PANEL)
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundTransparency = 1
padding(header, 20, 20, 12, 0)
local title = label(header, "PLAY", 26, FONT_BLACK, COL_ACCENT)
title.Size = UDim2.new(0.5, 0, 0, 30)
local subtitle = label(header, "", 13, FONT_BODY, COL_DIM)
subtitle.Position = UDim2.new(0, 0, 0, 30)
subtitle.Size = UDim2.new(0.6, 0, 0, 18)
subtitle.TextWrapped = false
subtitle.TextTruncate = Enum.TextTruncate.AtEnd
local wallet = frame(header, COL_PANEL)
wallet.BackgroundTransparency = 1
wallet.AnchorPoint = Vector2.new(1, 0)
wallet.Position = UDim2.new(1, -56, 0, 4)
wallet.Size = UDim2.new(0.45, 0, 0, 34)
local wl = hlist(wallet, 8)
wl.HorizontalAlignment = Enum.HorizontalAlignment.Right
wl.VerticalAlignment = Enum.VerticalAlignment.Center
local function coin(text, color, order)
	local c = frame(wallet, COL_CARD, 8)
	c.AutomaticSize = Enum.AutomaticSize.X
	c.Size = UDim2.fromOffset(0, 30)
	c.LayoutOrder = order
	padding(c, 12, 12, 0, 0)
	local t = label(c, text, 14, FONT, color)
	t.AutomaticSize = Enum.AutomaticSize.X
	t.Size = UDim2.new(0, 0, 1, 0)
	t.TextWrapped = false
	return t
end
local marksText = coin("0 Marks", COL_MARKS, 1)
local crownsText = coin("0 Crowns", COL_CROWNS, 2)
local getCrownsBtn = button(wallet, "+ GET CROWNS", 12, COL_GOLD)
getCrownsBtn.Size = UDim2.fromOffset(120, 30)
getCrownsBtn.LayoutOrder = 3
getCrownsBtn.TextColor3 = Color3.fromRGB(30, 22, 10)
local levelText = coin("LVL 1", COL_DIM, 0)
local closeBtn = button(header, "✕", 18, COL_CARD)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, 0, 0, 0)
closeBtn.Size = UDim2.fromOffset(44, 40)

-- side: tabs + the foot (per-tab buttons)
local side = frame(panelMain, COL_SIDE, 10)
side.Position = UDim2.new(0, 14, 0, 70)
side.Size = UDim2.new(0, 200, 1, -84)
padding(side, 10, 10, 10, 10)
vlist(side, 6)
local content = frame(panelMain, COL_PANEL)
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 228, 0, 70)
content.Size = UDim2.new(1, -242, 1, -84)

local TABS = {"PLAY", "APPEARANCE", "CLASSES", "SHOP", "SERVERS", "SETTINGS"}
local tabBtn, tabFrame, render = {}, {}, {}
local currentTab = "PLAY"
for i, name in ipairs(TABS) do
	local b = button(side, name, 15, COL_CARD)
	b.Size = UDim2.new(1, 0, 0, 38)
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
local sideGrow = frame(side, COL_SIDE); sideGrow.BackgroundTransparency = 1; sideGrow.LayoutOrder = 10; sideGrow.Size = UDim2.new(1, 0, 1, -(6 * 44 + 300))
local sideFoot = frame(side, COL_SIDE)
sideFoot.BackgroundTransparency = 1
sideFoot.AutomaticSize = Enum.AutomaticSize.Y
sideFoot.Size = UDim2.new(1, 0, 0, 0)
sideFoot.LayoutOrder = 20
vlist(sideFoot, 6)

-- modal (buy / confirm / crowns)
local modalBack = frame(backdrop, COL_BACK)
modalBack.Size = UDim2.fromScale(1, 1)
modalBack.BackgroundTransparency = 0.5
modalBack.Visible = false
modalBack.Active = true
modalBack.ZIndex = 50
local modalCatch = Instance.new("TextButton")
modalCatch.BackgroundTransparency = 1; modalCatch.Text = ""; modalCatch.Size = UDim2.fromScale(1, 1); modalCatch.ZIndex = 50; modalCatch.Parent = modalBack
local modalBox = frame(modalBack, COL_PANEL, 12)
modalBox.AnchorPoint = Vector2.new(0.5, 0.5)
modalBox.Position = UDim2.fromScale(0.5, 0.5)
modalBox.Size = UDim2.fromOffset(420, 0)
modalBox.AutomaticSize = Enum.AutomaticSize.Y
modalBox.ZIndex = 51
do local s = Instance.new("UIStroke", modalBox); s.Color = COL_ACCENT; s.Transparency = 0.4 end
padding(modalBox, 18, 18, 16, 16)
vlist(modalBox, 8)
local function closeModal() modalBack.Visible = false; clear(modalBox) end
modalCatch.Activated:Connect(closeModal)
-- modal(title, bodyText, buttons = {{text, color, fn}}, extra = function(box) end)
local function modal(mtitle, body, buttons, extra)
	clear(modalBox)
	local t = label(modalBox, mtitle, 18, FONT_BLACK, COL_ACCENT); t.Size = UDim2.new(1, 0, 0, 26); t.LayoutOrder = 1
	if body and body ~= "" then local d = dim(modalBox, body, 13); d.LayoutOrder = 2 end
	if extra then extra(modalBox) end
	for i, b in ipairs(buttons or {}) do
		local btn = bigBtn(modalBox, b[1], b[2], function() if b[3] then b[3]() end end)
		btn.LayoutOrder = 100 + i
	end
	local c = bigBtn(modalBox, "CLOSE", COL_CARD2, closeModal); c.LayoutOrder = 200
	modalBack.Visible = true
end

--------------------------------------------------------------------
--  STATE
--------------------------------------------------------------------
local state = {studio = false, reserved = false, access = "Public", name = "", custom = false, door = "Courtyard", mode = "Hub",
	bracket = nil, ranked = false, isHost = false, noRewards = false, party = nil, partyMax = GameConfig.PARTY_MAX or 3,
	profile = nil, contracts = {}, servers = {}, friends = {}, catalog = nil, activeClass = GameConfig.DEFAULT_CLASS,
	queue = nil, matchFound = nil, boards = {}, serversAt = 0}
local ui = {door = "Courtyard", bracket = "1v1", ranked = false, lbTab = "Warfront", editing = GameConfig.DEFAULT_CLASS,
	classEdit = {}, dirty = {}, team = nil, appDraft = nil, appDirty = false, helmPreview = false,
	shopTab = "crates", crate = nil, rolling = false, pulls = {}, filters = {hideEmpty = true, hideFull = false, customOnly = false, door = nil},
	customOpen = false, custom = nil, facing = 0, zoom = 1}
do for k in pairs(Catalog.CRATES) do if not ui.crate or k < ui.crate then ui.crate = k end end end
ui.custom = {}
for k, v in pairs(GameConfig.CUSTOM_DEFAULTS) do ui.custom[k] = v end
ui.custom.name = ""

local open = false
local listening = nil

local function alive()
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0 and c.Parent ~= nil
end
local function inHub() return roundNode:GetAttribute("Mode") == "Hub" end
local function roundState() return roundNode:GetAttribute("State") or "" end

-- ownership, mirroring Profile.has on the server
local function owns(kind, id)
	local p = state.profile
	if kind == "pieces" then
		local pc = Catalog.PIECE[id]
		if pc and Catalog.isFree(pc) then return true end
		if pc and pc.unlock and Catalog.unlocked(pc.unlock, p) then return true end
	end
	if kind == "skins" and type(id) == "string" and id:match(":Default$") then return true end
	if kind == "weapons" then local w = Catalog.WEAPON[id]; if w and Catalog.unlocked(w.unlock, p) then return true end end
	if kind == "colors" then local c = Catalog.COLOR[id]; if c and not c.crowns then return true end end
	if kind == "hairColors" then for _, h in ipairs(Catalog.BODY.hairColors) do if h.name == id and not h.crowns then return true end end end
	if kind == "beards" then for _, b in ipairs(Catalog.BODY.beards) do if b.id == id and not b.crowns then return true end end end
	if kind == "titles" then
		for _, t in ipairs(Catalog.BODY.titles) do if t == id then return true end end
		for _, t in ipairs(Catalog.BODY.earnedTitles or {}) do if t.title == id and Catalog.unlocked(t.unlock, p) then return true end end
	end
	return p ~= nil and p.owned ~= nil and p.owned[kind] ~= nil and p.owned[kind][id] == true
end
local function unlockText(w) return Catalog.unlockText(w.unlock) end
-- "37 / 100" for an unlock, or "" when it has no counter
local function progressText(u)
	local have, need = Catalog.unlockProgress(u, state.profile)
	return need and string.format("%s / %s", fmt(have), fmt(need)) or ""
end
local function rankOf(r)
	local tiers = ECON.rankTiers or {"Peasant", "Levy", "Squire", "Knight", "Banneret", "Champion"}
	local step = ECON.rankStep or 250
	local i = math.clamp(math.floor((r - 1000) / step), 0, #tiers - 1) + 1
	local within = ((r - 1000) % step) / step
	local sub = within < 0.34 and "III" or (within < 0.67 and "II" or "I")
	return tiers[i] .. " " .. sub
end
local function rating(bracket)
	return state.profile and state.profile.rating and state.profile.rating[bracket] or ECON.ratingStart or 1500
end
local function classLoadout(id)
	local c = state.catalog and state.catalog.classes and state.catalog.classes[id]
	return c and c.loadout or (state.profile and state.profile.classes and state.profile.classes[id]) or {}
end
local function weightOf(classId) local c = GameConfig.CLASSES[classId]; return c and c.weight or "Light" end

local function refreshWallet()
	local p = state.profile
	marksText.Text = fmt(p and p.wallet and p.wallet.marks or 0) .. " Marks"
	crownsText.Text = fmt(p and p.wallet and p.wallet.crowns or 0) .. " Crowns"
	levelText.Text = "LVL " .. tostring(p and p.level or 1)
	getCrownsBtn.Visible = currentTab == "SHOP"
end

local function loadCatalog()
	local ok, data = pcall(loadoutRemote.InvokeServer, loadoutRemote, "Catalog")
	if ok and type(data) == "table" then
		state.catalog = data
		state.activeClass = data.active or state.activeClass
	end
end
local function loadState()
	local r = call("State")
	if r.ok then
		for _, k in ipairs({"studio", "reserved", "access", "name", "custom", "door", "mode", "bracket", "ranked", "isHost", "noRewards", "party", "partyMax", "profile", "contracts", "settings"}) do state[k] = r[k] end
		state.activeClass = r.profile and r.profile.active or state.activeClass
		if r.party and r.party.queue then state.queue = {bracket = r.party.bracket, ranked = r.party.ranked, waiting = r.party.queue.waiting, window = r.party.queue.window}
		elseif r.party == nil or r.party.queue == nil then state.queue = nil end
	end
	refreshWallet()
end
local function loadServers(force)
	if not force and os.clock() - state.serversAt < 3 then return end
	local r = call("Servers")
	if r.ok then state.servers = r.servers or {}; state.serversAt = os.clock() end
end

--------------------------------------------------------------------
--  STAGE — dressed rigs in a ViewportFrame (drag to turn, scroll to zoom)
--------------------------------------------------------------------
local function proceduralRig()
	local m = Instance.new("Model")
	m.Name = "Mannequin"
	local skin = Catalog.BODY.skins[Catalog.BODY.defaults.skin or 2] or Color3.fromRGB(217, 180, 138)
	local function part(name, size, cf)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Anchored = true
		p.CanCollide = false
		p.Color = skin
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local torso = part("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0))
	local head = part("Head", Vector3.new(2, 1, 1), CFrame.new(0, 1.5, 0))
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Head; mesh.Scale = Vector3.new(1.25, 1.25, 1.25); mesh.Parent = head
	local face = Instance.new("Decal"); face.Name = "face"; face.Texture = "rbxasset://textures/face.png"; face.Face = Enum.NormalId.Front; face.Parent = head
	part("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0))
	part("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0))
	part("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0))
	part("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0))
	local hrp = part("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0)); hrp.Transparency = 1
	for _, a in ipairs({{"HairAttachment", head, CFrame.new(0, 0.6, 0)}, {"FaceFrontAttachment", head, CFrame.new(0, 0, -0.6)}, {"HatAttachment", head, CFrame.new(0, 0.6, 0)}}) do
		local at = Instance.new("Attachment"); at.Name = a[1]; at.CFrame = a[3]; at.Parent = a[2]
	end
	local bc = Instance.new("BodyColors"); bc.Parent = m
	m.PrimaryPart = hrp
	return m
end

local function makeRig()
	local t = Catalog.rig()
	local m
	if t then
		m = t:Clone()
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false
			elseif d:IsA("LuaSourceContainer") then d:Destroy() end
		end
		m.PrimaryPart = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
	else
		m = proceduralRig()
	end
	return m
end

-- resolve every weld the Dresser made into a fixed pose (no physics in a viewport)
local function settle(model)
	for _ = 1, 4 do
		for _, w in ipairs(model:GetDescendants()) do
			if (w:IsA("Weld") or w:IsA("Motor6D")) and w.Part0 and w.Part1 and w.Part0 ~= w.Part1 then
				w.Part1.CFrame = w.Part0.CFrame * w.C0 * w.C1:Inverse()
				w.Part1.Anchored = true
			end
		end
	end
end

local Stage = {}
Stage.__index = Stage

-- where a world point lands inside the viewport, in pixels (the viewport's
-- own camera has no screen, so the projection is done by hand)
local function project(cam, absSize, pos)
	local rel = cam.CFrame:PointToObjectSpace(pos)
	local z = math.max(0.01, -rel.Z)
	local tanY = math.tan(math.rad(cam.FieldOfView) * 0.5)
	local aspect = math.max(1, absSize.X) / math.max(1, absSize.Y)
	local nx = (rel.X / z) / (tanY * aspect)
	local ny = (rel.Y / z) / tanY
	return (nx * 0.5 + 0.5) * absSize.X, (0.5 - ny * 0.5) * absSize.Y
end

-- parent: where the viewport goes (it fills it). Returns a stage with :set(slots)
function Stage.new(parent)
	local self = setmetatable({}, Stage)
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundColor3 = Color3.fromRGB(14, 13, 12)
	vp.BackgroundTransparency = 0
	vp.BorderSizePixel = 0
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(120, 112, 100)
	vp.LightColor = Color3.fromRGB(255, 240, 220)
	vp.LightDirection = Vector3.new(-0.6, -1, 0.5)
	vp.Parent = parent
	Instance.new("UICorner", vp).CornerRadius = UDim.new(0, 10)
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.Parent = vp
	vp.CurrentCamera = cam
	self.vp, self.world, self.cam = vp, world, cam
	self.rigs = {}
	self.dist = 7.5
	-- the overlay carries every name tag, status line and slot button; it is
	-- re-placed over the rigs whenever they move or the viewport resizes
	local overlay = frame(parent, COL_CARD)
	overlay.BackgroundTransparency = 1
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = 3
	self.overlay = overlay
	vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:place() end)
	-- drag to turn, wheel to zoom (on the overlay: it sits over the viewport)
	local dragging, lastX = false, 0
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; lastX = input.Position.X end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			ui.facing += (input.Position.X - lastX) * 0.6
			lastX = input.Position.X
			self:place()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	overlay.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			ui.zoom = math.clamp(ui.zoom - input.Position.Z * 0.08, 0.7, 1.5)
			self:place()
		end
	end)
	return self
end

-- slot i stands left to right; `back` slots stand a step behind, turned
-- toward the middle, so the middle one (you) is the one up front
function Stage:place()
	local n = #self.rigs
	local gap = 3.4
	local abs = self.vp.AbsoluteSize
	local anyBack = false
	for i, r in ipairs(self.rigs) do
		local x = -(i - (n + 1) / 2) * gap      -- world -X is screen-right for this camera
		local z = r.slot.back and 1.4 or 0
		local turn = r.slot.back and math.sign(x) * 18 or 0
		r.model:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(ui.facing + turn), 0))
		r.x, r.z = x, z
		if r.slot.back then anyBack = true end
	end
	local d = (self.dist + (n - 1) * 1.6 + (anyBack and 0.6 or 0)) / ui.zoom
	self.cam.CFrame = CFrame.lookAt(Vector3.new(0, -0.3, -d), Vector3.new(0, -0.6, 0))
	self.cam.FieldOfView = 50
	for _, r in ipairs(self.rigs) do
		local ov = r.overlay
		local fx, fy = project(self.cam, abs, Vector3.new(r.x, -3.35, r.z))
		ov.foot.Position = UDim2.fromOffset(fx, fy)
		if ov.mid then local mx, my = project(self.cam, abs, Vector3.new(r.x, 0.3, r.z)); ov.mid.Position = UDim2.fromOffset(mx, my) end
		if ov.top then local hx, hy = project(self.cam, abs, Vector3.new(r.x, 2.9, r.z)); ov.top.Position = UDim2.fromOffset(hx, hy) end
	end
end

-- slots: list of {loadout=, appearance=, weight=, team=, armor=bool(default true), weapon=bool(default true),
--   tag=, sub=, subColor=, ghost=bool, back=bool,
--   buttons = {{text, color, fn}}   small buttons under the name
--   onInvite = fn                   a big + on the (ghost) body
--   onKick = fn                     an ✕ over the head }
function Stage:set(slots)
	for _, r in ipairs(self.rigs) do r.model:Destroy() end
	self.rigs = {}
	clear(self.overlay)
	for i, s in ipairs(slots) do
		local m = makeRig()
		if s.ghost then
			for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Transparency = 0.8; d.Color = Color3.fromRGB(90, 82, 72) elseif d:IsA("Decal") then d.Transparency = 1 end end
		else
			local lo = s.loadout or {}
			if s.armor == false then lo = {colors = lo.colors} end
			pcall(Dresser.dress, m, {loadout = lo, appearance = s.appearance, weight = s.weight, team = s.team, preview = true})
			if s.weapon ~= false and (s.loadout or {}).weapon then pcall(Dresser.attachWeapon, m, s.loadout.weapon, s.loadout.weaponSkin) end
			settle(m)
		end
		m.Parent = self.world
		local ov = {}
		-- under the feet: name, status, buttons
		local foot = frame(self.overlay, COL_CARD)
		foot.BackgroundTransparency = 1
		foot.AnchorPoint = Vector2.new(0.5, 0)
		foot.Size = UDim2.fromOffset(190, 96)
		foot.ZIndex = 4
		local fl = vlist(foot, 4); fl.HorizontalAlignment = Enum.HorizontalAlignment.Center
		local t = label(foot, s.tag or "", 13, FONT, s.ghost and COL_DIM or COL_TEXT)
		t.Size = UDim2.new(1, 0, 0, 16); t.LayoutOrder = 1; t.ZIndex = 4
		t.TextXAlignment = Enum.TextXAlignment.Center; t.TextStrokeTransparency = 0.6; t.TextWrapped = false; t.TextTruncate = Enum.TextTruncate.AtEnd
		if s.sub and s.sub ~= "" then
			local sb = label(foot, s.sub, 11, FONT, s.subColor or COL_DIM)
			sb.Size = UDim2.new(1, 0, 0, 14); sb.LayoutOrder = 2; sb.ZIndex = 4
			sb.TextXAlignment = Enum.TextXAlignment.Center; sb.TextStrokeTransparency = 0.6; sb.TextWrapped = false
		end
		for j, b in ipairs(s.buttons or {}) do
			local btn = button(foot, b[1], 11, b[2] or COL_CARD2)
			btn.Size = UDim2.fromOffset(124, 24); btn.LayoutOrder = 10 + j; btn.ZIndex = 5
			if b[3] then btn.Activated:Connect(b[3]) end
		end
		ov.foot = foot
		if s.onInvite then
			local mid = frame(self.overlay, COL_CARD)
			mid.BackgroundTransparency = 1
			mid.AnchorPoint = Vector2.new(0.5, 0.5)
			mid.Size = UDim2.fromOffset(120, 84)
			mid.ZIndex = 4
			local plus = button(mid, "+", 30, COL_CARD_ON)
			plus.AnchorPoint = Vector2.new(0.5, 0); plus.Position = UDim2.new(0.5, 0, 0, 0); plus.Size = UDim2.fromOffset(56, 56); plus.ZIndex = 5
			plus.TextColor3 = COL_ACCENT
			plus:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
			local st = Instance.new("UIStroke", plus); st.Color = COL_ACCENT; st.Thickness = 2; st.Transparency = 0.3
			local cap = label(mid, "INVITE", 11, FONT, COL_ACCENT)
			cap.Position = UDim2.new(0, 0, 0, 62); cap.Size = UDim2.new(1, 0, 0, 16); cap.ZIndex = 5
			cap.TextXAlignment = Enum.TextXAlignment.Center; cap.TextStrokeTransparency = 0.6
			plus.Activated:Connect(s.onInvite)
			ov.mid = mid
		end
		if s.onKick then
			local x = button(self.overlay, "✕", 14, COL_BAD)
			x.AnchorPoint = Vector2.new(0.5, 1); x.Size = UDim2.fromOffset(28, 28); x.ZIndex = 5
			x:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
			x.Activated:Connect(s.onKick)
			ov.top = x
		end
		table.insert(self.rigs, {model = m, slot = s, overlay = ov})
	end
	self:place()
end

-- stage + hint line below, inside a holder sized by the caller
local function stageBlock(parent, hintText)
	local holder = frame(parent, COL_PANEL)
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 1, 0)
	local vpHolder = frame(holder, COL_PANEL)
	vpHolder.BackgroundTransparency = 1
	vpHolder.Size = UDim2.new(1, 0, 1, -22)
	local st = Stage.new(vpHolder)
	local h = label(holder, hintText or "", 11, FONT_BODY, COL_DIM)
	h.AnchorPoint = Vector2.new(0, 1)
	h.Position = UDim2.new(0, 0, 1, 0)
	h.Size = UDim2.new(1, 0, 0, 18)
	h.TextXAlignment = Enum.TextXAlignment.Center
	return holder, st, h
end

-- a small 3D view of a weapon (Cosmetics ▸ Weapons ▸ <id>) wearing a skin,
-- laid diagonally across the card. No display model yet → a flat drawing.
local function weaponThumb(parent, weaponId, skinId, size)
	local holder = frame(parent, COL_CARD2, 8)
	holder.Size = size or UDim2.new(1, 0, 0, 72)
	holder.ClipsDescendants = true
	local skin = skinId and Catalog.SKIN[skinId]
	local t = weaponId and Catalog.weaponModel(weaponId)
	if t then
		local vp = Instance.new("ViewportFrame")
		vp.BackgroundTransparency = 1
		vp.Size = UDim2.fromScale(1, 1)
		vp.Ambient = Color3.fromRGB(130, 122, 110)
		vp.LightColor = Color3.fromRGB(255, 240, 220)
		vp.LightDirection = Vector3.new(-0.5, -1, 0.6)
		vp.Parent = holder
		local world = Instance.new("WorldModel"); world.Parent = vp
		local cam = Instance.new("Camera"); cam.Parent = vp
		vp.CurrentCamera = cam
		local m = t:Clone()
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
		m.Parent = world
		if skin then pcall(Dresser.applySkin, m, skinId) end
		settle(m)
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
		-- the model's longest side becomes the card's diagonal
		local cf, sz = m:GetBoundingBox()
		local axis = (sz.X >= sz.Y and sz.X >= sz.Z) and Vector3.xAxis or (sz.Y >= sz.Z and Vector3.yAxis or Vector3.zAxis)
		local longest = math.max(sz.X, sz.Y, sz.Z, 0.5)
		local along = cf:VectorToWorldSpace(axis)
		local up = math.abs(along.Y) < 0.9 and Vector3.yAxis or Vector3.zAxis
		local vy = (up - along * up:Dot(along)).Unit
		local box = CFrame.fromMatrix(cf.Position, along, vy)
		local target = CFrame.Angles(0, 0, math.rad(-28))
		m:PivotTo(target * box:Inverse() * m:GetPivot())
		local d = (longest * 0.6) / math.tan(math.rad(14))
		cam.FieldOfView = 28
		cam.CFrame = CFrame.lookAt(Vector3.new(0, d * 0.22, -d), Vector3.zero)
	else
		local blade = frame(holder, skin and skin.blade or Color3.fromRGB(180, 180, 180)); blade.AnchorPoint = Vector2.new(0.5, 0.5); blade.Position = UDim2.new(0.5, 0, 0.5, -6); blade.Size = UDim2.fromOffset(8, 48); blade.Rotation = -28
		local grip = frame(holder, skin and skin.grip or Color3.fromRGB(80, 60, 40)); grip.AnchorPoint = Vector2.new(0.5, 0.5); grip.Position = UDim2.new(0.5, -14, 0.5, 20); grip.Size = UDim2.fromOffset(24, 6); grip.Rotation = -28
	end
	return holder
end

--------------------------------------------------------------------
--  SHARED ACTIONS
--------------------------------------------------------------------
local renderSide, selectTab, hide   -- forward
local function rerender() if render[currentTab] then task.spawn(render[currentTab]) end; renderSide() end

local function doorCounts()
	local counts, servers = {}, {}
	for _, s in ipairs(state.servers) do
		local d = s.door or (s.mode == "Hub" and "Courtyard" or "Warfront")
		counts[d] = (counts[d] or 0) + (s.players or 0)
		servers[d] = (servers[d] or 0) + 1
	end
	return counts, servers
end

local function inviteModal()
	modal("INVITE TO YOUR PARTY", string.format("People in this server. A party is at most %d. Friends in other servers can be joined from their row.", state.partyMax), nil, function(box)
		local n = 0
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				n += 1
				local inParty = false
				if state.party then for _, m in ipairs(state.party.members) do if m.id == other.UserId then inParty = true end end end
				row(box, other.DisplayName, inParty and "in your party" or "INVITE", false, (not inParty) and function()
					local r = call("PartyInvite", other.UserId, other.DisplayName)
					toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
					if r.party then state.party = r.party end
					closeModal(); rerender()
				end or nil, inParty and COL_DIM or COL_GOOD)
			end
		end
		if n == 0 then dim(box, "Nobody else is in this server yet.") end
		local away = {}
		for _, fd in ipairs(state.friends) do
			local inParty = false
			if state.party then for _, m in ipairs(state.party.members) do if m.id == fd.id then inParty = true end end end
			if fd.inGame and not fd.here and not inParty then table.insert(away, fd) end
		end
		if #away > 0 then
			heading(box, "FRIENDS IN OTHER SERVERS")
			dim(box, "They get the invite there; accepting brings them to this server.")
			for _, fd in ipairs(away) do
				row(box, fd.name, "INVITE", false, function()
					local r = call("PartyInvite", fd.id, fd.name)
					toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
					if r.party then state.party = r.party end
					closeModal(); rerender()
				end, COL_GOOD)
			end
		end
	end)
end

local function partySize() return state.party and state.party.members and #state.party.members or 1 end
local function findMatch()
	if state.queue then return end
	local size = tonumber(ui.bracket:match("^(%d)")) or 1
	local n = partySize()
	if n > size then
		modal("PARTY TOO BIG FOR " .. ui.bracket, string.format("%s takes a party of at most %d and yours is %d. Remove someone (the ✕ over their head on PLAY) or pick a bigger bracket.", ui.bracket, size, n),
			{{"PICK " .. (n <= 2 and "2v2" or "3v3"), COL_CARD_ON, function() ui.bracket = n <= 2 and "2v2" or "3v3"; closeModal(); render.PLAY() end}})
		return
	end
	local r = call("Play", "Lists", {bracket = ui.bracket, ranked = ui.ranked})
	if r.ok then
		toast(r.msg or "", COL_GOOD)
		state.queue = {bracket = ui.bracket, ranked = ui.ranked, since = os.clock(), waiting = 0, window = 100}
	else
		modal("CAN'T QUEUE", r.msg or "no answer", nil)
	end
	rerender()
end
local function cancelQueue()
	call("QueueCancel")
	state.queue = nil
	state.matchFound = nil
	rerender()
end

local function goDoor(doorId, opts)
	local r = call("Play", doorId, opts or {})
	toast((GameConfig.DOORS[doorId] and GameConfig.DOORS[doorId].name or doorId) .. ":  " .. (r.msg or ""), r.ok and COL_GOOD or COL_BAD)
	return r.ok
end

--------------------------------------------------------------------
--  PLAY TAB
--------------------------------------------------------------------
do
	local f = tabFrame.PLAY
	local left = frame(f, COL_PANEL); left.BackgroundTransparency = 1; left.Size = UDim2.new(0, 220, 1, 0)
	local leftList = scroll(left, 8)
	local center = frame(f, COL_PANEL); center.BackgroundTransparency = 1; center.Position = UDim2.new(0, 232, 0, 0); center.Size = UDim2.new(1, -232 - 332, 1, 0)
	local right = frame(f, COL_PANEL); right.BackgroundTransparency = 1; right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 320, 1, 0)
	local rightList = scroll(right, 8)

	local stageHolder = frame(center, COL_PANEL); stageHolder.BackgroundTransparency = 1; stageHolder.Size = UDim2.new(1, 0, 1, 0)
	local _, stage, stageHint = stageBlock(stageHolder, "")

	local function partyMembers()
		local list = {}
		if state.party and state.party.members then
			for _, m in ipairs(state.party.members) do table.insert(list, m) end
		else
			local p = state.profile
			table.insert(list, {name = player.DisplayName, id = player.UserId, leader = true, ready = true, class = state.activeClass, level = p and p.level or 1})
		end
		return list
	end
	local function isLeader() return not state.party or state.party.leaderId == player.UserId end
	local function inParty() return state.party ~= nil and #(state.party.members or {}) > 1 end

	-- you up front in the middle; teammates and open slots (shadows) around
	-- you. Click a shadow to invite, the ✕ over a teammate to remove them.
	local function renderStage()
		local list = partyMembers()
		local leader, party = isLeader(), inParty()
		local function memberSlot(m)
			local mine = m.id == player.UserId
			local cls = m.class or GameConfig.DEFAULT_CLASS
			local lo = mine and classLoadout(cls) or nil
			-- other members: we only know their class; show the class default
			if not lo then
				lo = {helmet = (Catalog.defaultPiece("helmet", weightOf(cls)) or {}).id, top = (Catalog.defaultPiece("top", weightOf(cls)) or {}).id, bottom = (Catalog.defaultPiece("bottom", weightOf(cls)) or {}).id, colors = {Primary = "Slate", Secondary = "Umber", Accent = "Ochre", Metal = "Ash"}}
			end
			local sub, subColor = "", nil
			if party then
				if m.leader then sub, subColor = "party leader", COL_ACCENT
				elseif m.ready then sub, subColor = "READY ✓", COL_GOOD
				else sub, subColor = "not ready", COL_BAD end
			end
			local buttons = {}
			if mine and party and not m.leader then
				table.insert(buttons, {m.ready and "UNREADY" or "READY UP", m.ready and COL_CARD2 or COL_GO_ON, function()
					local r = call("PartyReady", not m.ready)
					if r.party then state.party = r.party end
					if not r.ok then toast(r.msg or "", COL_BAD) end
					renderStage(); renderSide()
				end})
			end
			if mine and party then
				table.insert(buttons, {"LEAVE PARTY", COL_CARD2, function() call("PartyLeave"); state.party = nil; state.queue = nil; toast("left the party", COL_DIM); rerender() end})
			end
			local clsName = GameConfig.CLASSES[cls] and GameConfig.CLASSES[cls].name or cls
			return {
				loadout = lo, appearance = mine and state.profile and state.profile.appearance or nil, weight = weightOf(cls), back = not mine,
				tag = (m.leader and "♛ " or "") .. (mine and "You" or m.name) .. "  ·  " .. clsName .. (mine and "" or string.format("  ·  lvl %d", m.level or 1)),
				sub = sub, subColor = subColor, buttons = buttons,
				onKick = (leader and not mine) and function()
					local r = call("PartyKick", m.id)
					toast(r.msg or "", r.ok and COL_DIM or COL_BAD)
					if r.party then state.party = r.party end
					renderStage(); renderSide()
				end or nil,
			}
		end
		local function ghostSlot()
			return {ghost = true, back = true, tag = "open slot", sub = leader and "" or "the leader invites", onInvite = leader and inviteModal or nil}
		end
		local me, others = nil, {}
		for _, m in ipairs(list) do if m.id == player.UserId then me = m else table.insert(others, m) end end
		local slots, mid, k = {}, math.ceil(state.partyMax / 2), 1
		for i = 1, state.partyMax do
			if i == mid then table.insert(slots, me and memberSlot(me) or ghostSlot())
			else table.insert(slots, others[k] and memberSlot(others[k]) or ghostSlot()); k += 1 end
		end
		stage:set(slots)
		stageHint.Text = party and string.format("party of %d / %d  ·  everyone readies, the leader presses PLAY  ·  drag to turn", #list, state.partyMax)
			or "click a shadow to invite someone  ·  drag to turn, scroll to zoom"
	end

	local function renderLeaderboard()
		clear(leftList)
		local which = ui.lbTab
		local p = panel(leftList, "LEADERBOARD  ·  " .. (which == "Warfront" and "WARFRONT KILLS" or "RANKED " .. which), true)
		local tabs = {}
		for _, b in ipairs(GameConfig.DOORS.Lists.brackets or {"1v1", "2v2", "3v3"}) do table.insert(tabs, {text = b}) end
		table.insert(tabs, {text = "Warfront"})
		chips(p, tabs, function(it) return it.text == ui.lbTab end, function(it) ui.lbTab = it.text; renderLeaderboard() end)
		local b = state.boards[which]
		if not b or os.clock() - b.at > 60 then
			local r = call("Leaderboard", which)
			b = {at = os.clock(), rows = r.ok and r.rows or {}}
			state.boards[which] = b
		end
		local meIn = false
		for _, rw in ipairs(b.rows) do
			local mine = rw.id == player.UserId
			if mine then meIn = true end
			row(p, string.format("%d   %s", rw.rank, mine and "You" or rw.name), fmt(rw.value), mine, nil, mine and COL_ACCENT or COL_TEXT)
		end
		if #b.rows == 0 then dim(p, "Nobody on the board yet.") end
		if not meIn then
			local mine = which == "Warfront" and (state.profile and state.profile.stats and state.profile.stats.kill or 0) or rating(which)
			dim(p, "…")
			row(p, "You", fmt(mine), true, nil, COL_ACCENT)
		end
		if which ~= "Warfront" then
			local r = rating(which)
			dim(p, string.upper(rankOf(r)) .. "  ·  " .. fmt(r) .. (state.profile and state.profile.placements and state.profile.placements[which] and (("  ·  " .. state.profile.placements[which] .. " played")) or ""))
		end
		dim(p, "Top 100 at season end get a skin and a title. Season lasts " .. tostring(ECON.seasonDays or 42) .. " days.")
	end

	local function renderListsCard()
		local p = panel(rightList, "BRACKET")
		local bl = {}
		for _, b in ipairs(GameConfig.DOORS.Lists.brackets or {"1v1", "2v2", "3v3"}) do table.insert(bl, {text = b}) end
		chips(p, bl, function(it) return it.text == ui.bracket end, function(it) ui.bracket = it.text; render.PLAY() end)
		chips(p, {{text = "CASUAL", v = false}, {text = "RANKED", v = true}}, function(it) return it.v == ui.ranked end, function(it) ui.ranked = it.v; render.PLAY() end)
		local size = tonumber(ui.bracket:match("^(%d)")) or 1
		local n = #partyMembers()
		if n > size then dim(p, string.format("Your party of %d is too big for %s.", n, ui.bracket), 12)
		elseif n < size then dim(p, string.format("%s with a party of %d: the rest of your side is filled from the queue.", ui.bracket, n), 12)
		else dim(p, string.format("Party of %d fits %s.", n, ui.bracket), 12) end
		if state.queue then
			local q = panel(rightList, "SEARCHING  ·  " .. (state.queue.ranked and "RANKED " or "CASUAL ") .. state.queue.bracket)
			local t = label(q, "0:00", 28, FONT_BLACK, COL_TEXT); t.Name = "QTime"; t.Size = UDim2.new(1, 0, 0, 34); t.LayoutOrder = nextOrder()
			local w = dim(q, "rating window widening…"); w.Name = "QWin"
			if state.matchFound then
				local mf = label(q, "MATCH FOUND  ·  travelling", 16, FONT_BLACK, COL_GOOD); mf.Size = UDim2.new(1, 0, 0, 24); mf.LayoutOrder = nextOrder()
			else
				dim(q, "Browse the menu while you wait; the card follows you.")
				bigBtn(q, "CANCEL", COL_CARD2, cancelQueue)
			end
		else
			local go = bigBtn(p, "FIND MATCH", COL_GO_ON, findMatch)
			if n > size then go.Active = false; go.BackgroundColor3 = COL_CARD2 end
			local h = panel(rightList, "HOW IT WORKS", true)
			dim(h, "Best of 5 rounds, 90 s each, no respawns. One on one means one on one: a third blade on a fight ends the round against that team.")
			dim(h, ui.ranked and "Ranked: rating, ranks, seasons. Leaving counts as a loss and locks the queue for " .. tostring(ECON.queueLockMinutes or 10) .. " minutes." or "Casual: no rating, just honor rules.")
		end
		local r = rating(ui.bracket)
		local rk = panel(rightList, "YOUR RANK  ·  " .. ui.bracket, true)
		local t = label(rk, string.upper(rankOf(r)) .. "   " .. fmt(r), 15, FONT_BLACK, COL_ACCENT); t.Size = UDim2.new(1, 0, 0, 22); t.LayoutOrder = nextOrder()
		local step = ECON.rankStep or 250
		dim(rk, string.format("%d to the next tier  ·  %d placement matches", step - ((r - 1000) % step), ECON.placementMatches or 10))
		dim(rk, table.concat(ECON.rankTiers or {}, "  ·  "))
	end

	local function renderRight()
		clear(rightList)
		if ui.door == "Lists" then renderListsCard() else
			local door = GameConfig.DOORS[ui.door]
			local counts, servers = doorCounts()
			local p = panel(rightList, (door and string.upper(door.name) or "") .. " NOW")
			if ui.door == "Courtyard" then
				dim(p, string.format("%d in courtyards right now. Walk around, hit the dummies, duel in the ring.", counts.Courtyard or 0))
			elseif ui.door == "Tiltyard" then
				dim(p, "Your own yard, friends only: you and your party. Drills with the drill master pay Marks once each.")
			else
				local best
				for _, s in ipairs(state.servers) do
					if s.door == "Warfront" and not s.custom and (s.players or 0) < (s.max or 0) and (not best or (s.players or 0) > (best.players or 0)) then best = s end
				end
				dim(p, best and string.format("%s on %s  ·  %d / %d  ·  %d server%s", best.modeName or best.mode, best.map ~= "" and best.map or "?", best.players or 0, best.max or 0, servers.Warfront or 0, (servers.Warfront or 0) == 1 and "" or "s")
					or "No Warfront running right now — PLAY starts one.")
				dim(p, "The mode changes between rounds by vote: " .. table.concat((function() local t = {}; for _, m in ipairs(door.modes or {}) do table.insert(t, GameConfig.MODES[m] and GameConfig.MODES[m].name or m) end; return t end)(), ", ") .. ".")
			end
			if ui.door == "Courtyard" and inHub() then
				-- already in a courtyard: this button just puts you in it
				if alive() then bigBtn(p, "BACK TO THE COURTYARD", COL_GO_ON, hide)
				else bigBtn(p, "ENTER THE COURTYARD", COL_GO_ON, function() loadoutEvent:FireServer("Spawn", state.activeClass) end) end
			else
				bigBtn(p, ui.door == "Courtyard" and "GO TO A COURTYARD" or (ui.door == "Tiltyard" and "OPEN YOUR TILTYARD" or "JOIN THIS BATTLE"), COL_GO_ON, function() goDoor(ui.door) end)
			end
			bigBtn(p, "BROWSE SERVERS", COL_CARD2, function() ui.filters.door = ui.door ~= "Courtyard" and ui.door or nil; selectTab("SERVERS") end)
			local c = panel(rightList, "DAILY CONTRACTS", true)
			for _, ct in ipairs(state.contracts or {}) do
				row(c, (ct.weekly and "★ " or "") .. ct.text, ct.done and "done ✓" or string.format("%d / %d  ·  %d", ct.n, ct.goal, ct.pay), false, nil, ct.done and COL_GOOD or COL_DIM)
			end
			if #(state.contracts or {}) == 0 then dim(c, "Contracts load with your profile.") end
			local fr = panel(rightList, "FRIENDS", true)
			local n = 0
			for _, fd in ipairs(state.friends) do
				n += 1
				local inParty = false
				if state.party then for _, m in ipairs(state.party.members) do if m.id == fd.id then inParty = true end end end
				row(fr, fd.name, inParty and "in party" or (fd.here and "INVITE" or (fd.inGame and "INVITE · JOIN" or "online")), false,
					(not inParty and fd.here) and function() local r = call("PartyInvite", fd.id, fd.name); toast(r.msg or "", r.ok and COL_GOOD or COL_BAD); if r.party then state.party = r.party end end
					or ((not inParty and fd.inGame) and function()
						modal(fd.name, "In another server of this game. Invite them to your party (they travel here when they accept), or go to them.", {
							{"INVITE TO MY PARTY", COL_CARD_ON, function() local r = call("PartyInvite", fd.id, fd.name); toast(r.msg or "", r.ok and COL_GOOD or COL_BAD); if r.party then state.party = r.party end; closeModal() end},
							{"JOIN THEM", COL_GO_ON, function() local r = call("JoinFriend", fd.id); toast(r.msg or "", r.ok and COL_GOOD or COL_BAD); closeModal() end},
						})
					end or nil),
					(fd.here or fd.inGame) and COL_GOOD or COL_DIM)
			end
			if n == 0 then dim(fr, "No friends online in the game.") end
		end
	end

	render.PLAY = function()
		loadServers(false)
		local fr = call("Friends"); if fr.ok then state.friends = fr.friends or {} end
		renderLeaderboard()
		renderStage()
		renderRight()
		renderSide()
	end
	-- queue clock
	task.spawn(function()
		while true do
			task.wait(1)
			if open and state.queue and currentTab == "PLAY" then
				local t = rightList:FindFirstChild("QTime", true)
				local w = rightList:FindFirstChild("QWin", true)
				local s = math.floor(os.clock() - (state.queue.since or os.clock()))
				if t then t.Text = string.format("%d:%02d", math.floor(s / 60), s % 60) end
				if w then w.Text = string.format("rating window ±%d  ·  widening", math.min(1000, 100 + 40 * math.floor(s / 4))) end
			end
		end
	end)
	bus.Event:Connect(function(what) if what == "PartyChanged" and open and currentTab == "PLAY" then renderStage(); renderRight(); renderSide() end end)
end

--------------------------------------------------------------------
--  APPEARANCE TAB
--------------------------------------------------------------------
do
	local f = tabFrame.APPEARANCE
	local left = frame(f, COL_PANEL); left.BackgroundTransparency = 1; left.Size = UDim2.new(1, -332, 1, 0)
	local _, stage, stageHint = stageBlock(left, "")
	local right = frame(f, COL_PANEL); right.BackgroundTransparency = 1; right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 320, 1, 0)
	local list = scroll(right, 8)

	local function draft()
		if not ui.appDraft then
			ui.appDraft = {}
			for k, v in pairs(state.profile and state.profile.appearance or Catalog.BODY.defaults) do ui.appDraft[k] = v end
		end
		return ui.appDraft
	end
	local function renderStage()
		local a = draft()
		local lo = classLoadout(state.activeClass)
		if ui.helmPreview then
			stage:set({{loadout = lo, appearance = a, weight = weightOf(state.activeClass), weapon = false, tag = "♛ You  ·  " .. (GameConfig.CLASSES[state.activeClass] and GameConfig.CLASSES[state.activeClass].name or "") .. " helmet on"}})
			stageHint.Text = "the active class's helmet shows what it hides"
		else
			stage:set({{loadout = lo, appearance = a, armor = false, weapon = false, tag = "♛ You"}})
			stageHint.Text = "armor and weapon come off while you edit  ·  drag to turn"
		end
	end
	local function set(k, v, buyKind, price)
		local a = draft()
		if buyKind and not owns(buyKind, v) then
			modal("PREMIUM", string.format("%s costs %d Crowns, once, forever.", tostring(v), price or 0), {{"BUY  ·  " .. tostring(price) .. " CROWNS", COL_GOLD, function()
				local r = call("Buy", buyKind == "hairColors" and "hairColor" or "beard", v, "crowns")
				toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
				if r.profile then state.profile = r.profile; refreshWallet() end
				closeModal()
				if r.ok then set(k, v) end
			end}})
			return
		end
		a[k] = v
		ui.appDirty = true
		render.APPEARANCE(true)
	end
	render.APPEARANCE = function(keepStage)
		local a = draft()
		clear(list)
		local p = panel(list, nil)
		heading(p, "HAIR")
		for _, h in ipairs(Catalog.BODY.hair) do row(p, h.name, "", a.hair == h.id, function() set("hair", h.id) end) end
		heading(p, "BEARD")
		for _, b in ipairs(Catalog.BODY.beards) do
			local locked = b.crowns and not owns("beards", b.id)
			row(p, b.name, locked and (tostring(b.crowns) .. " Crowns") or "", a.beard == b.id, function() set("beard", b.id, b.crowns and "beards" or nil, b.crowns) end, locked and COL_CROWNS or COL_DIM)
		end
		heading(p, "FACE")
		for _, fc in ipairs(Catalog.BODY.faces) do row(p, fc.name, "", a.face == fc.id, function() set("face", fc.id) end) end
		heading(p, "SKIN")
		local tones = {}
		for i, c in ipairs(Catalog.BODY.skins) do table.insert(tones, {i = i, color = c}) end
		swatches(p, tones, function(it) return a.skin == it.i end, function() return false end, function(it) set("skin", it.i) end)
		heading(p, "HAIR COLOR")
		swatches(p, Catalog.BODY.hairColors, function(it) return a.hairColor == it.name end, function(it) return it.crowns and not owns("hairColors", it.name) end,
			function(it) set("hairColor", it.name, it.crowns and "hairColors" or nil, it.crowns) end)
		dim(p, "Locked colors are premium: bought once with Crowns.")
		heading(p, "TITLE")
		local titles = {}
		for _, t in ipairs(Catalog.BODY.titles) do titles[t] = true end
		if state.profile and state.profile.owned and state.profile.owned.titles then for t in pairs(state.profile.owned.titles) do titles[t] = true end end
		local ordered = {}
		for t in pairs(titles) do table.insert(ordered, t) end
		table.sort(ordered)
		for _, t in ipairs(ordered) do row(p, t, "", a.title == t, function() set("title", t) end) end
		for _, et in ipairs(Catalog.BODY.earnedTitles or {}) do
			if owns("titles", et.title) then
				if not titles[et.title] then row(p, et.title, "earned", a.title == et.title, function() set("title", et.title) end, COL_GOOD) end
			else
				row(p, "🔒 " .. et.title, Catalog.unlockText(et.unlock) .. "  ·  " .. progressText(et.unlock), false, nil, COL_DIM)
			end
		end
		renderStage()
		renderSide()
	end
	render.APPEARANCE_save = function()
		local r = call("SaveAppearance", draft())
		if r.ok then
			toast("appearance saved", COL_GOOD)
			if r.profile then state.profile = r.profile end
			ui.appDraft = nil; ui.appDirty = false
			render.APPEARANCE()
		else toast(r.msg or "save failed", COL_BAD) end
	end
end

--------------------------------------------------------------------
--  CLASSES TAB
--------------------------------------------------------------------
do
	local f = tabFrame.CLASSES
	local left = frame(f, COL_PANEL); left.BackgroundTransparency = 1; left.Size = UDim2.new(1, -332, 1, 0)
	local classRow = frame(left, COL_PANEL); classRow.BackgroundTransparency = 1; classRow.Size = UDim2.new(1, 0, 0, 52)
	hlist(classRow, 8)
	local stageHolder = frame(left, COL_PANEL); stageHolder.BackgroundTransparency = 1; stageHolder.Position = UDim2.new(0, 0, 0, 60); stageHolder.Size = UDim2.new(1, 0, 1, -60)
	local _, stage, stageHint = stageBlock(stageHolder, "")
	local right = frame(f, COL_PANEL); right.BackgroundTransparency = 1; right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 320, 1, 0)
	local list = scroll(right, 8)

	local function edit()
		local id = ui.editing
		if not ui.classEdit[id] then
			local lo = classLoadout(id)
			local c = {colors = {}}
			for k, v in pairs(lo) do if k ~= "colors" then c[k] = v end end
			for k, v in pairs(lo.colors or {}) do c.colors[k] = v end
			ui.classEdit[id] = c
		end
		return ui.classEdit[id]
	end
	local function renderStage()
		local lo = edit()
		stage:set({{loadout = lo, appearance = state.profile and state.profile.appearance, weight = weightOf(ui.editing), team = ui.team,
			tag = "♛ You  ·  " .. (GameConfig.CLASSES[ui.editing] and GameConfig.CLASSES[ui.editing].name or ui.editing)}})
		stageHint.Text = ui.team and ("team preview: Primary forced to " .. (GameConfig.TEAMS[ui.team] and GameConfig.TEAMS[ui.team].name or ui.team) .. ", Secondary darkened")
			or "every click re-dresses the mannequin  ·  drag to turn, scroll to zoom"
	end
	local function renderClassRow()
		clear(classRow)
		for i, id in ipairs(GameConfig.CLASS_ORDER) do
			local def = GameConfig.CLASSES[id]
			local on = ui.editing == id
			local b = button(classRow, "", 14, on and COL_CARD_ON or COL_CARD)
			b.Size = UDim2.new(1 / #GameConfig.CLASS_ORDER, -6, 1, 0)
			b.LayoutOrder = i
			b.AutoButtonColor = false
			local n = label(b, string.upper(def.name) .. (state.activeClass == id and "  ★" or ""), 15, FONT_BLACK, COL_TEXT); n.Size = UDim2.new(1, 0, 0, 24); n.Position = UDim2.new(0, 10, 0, 6)
			local w = label(b, string.upper(def.weight) .. (ui.dirty[id] and "  ·  unsaved" or ""), 11, FONT, TYPE_COL[def.weight] or COL_DIM); w.Size = UDim2.new(1, 0, 0, 14); w.Position = UDim2.new(0, 10, 0, 30)
			b.Activated:Connect(function() ui.editing = id; render.CLASSES() end)
		end
	end
	local function buyPiece(pc)
		local opts = {}
		if pc.unlock then
			modal(pc.name, (pc.description or "") .. string.format("\n%s  ·  %s\nEarned: %s  ·  %s", pc.weight, pc.rarity or "Common", Catalog.unlockText(pc.unlock), progressText(pc.unlock)), nil)
			return
		end
		if (pc.marks or 0) > 0 then table.insert(opts, {"BUY  ·  " .. fmt(pc.marks) .. " MARKS", COL_CARD_ON, function()
			local r = call("Buy", "piece", pc.id, "marks"); toast(r.msg or "", r.ok and COL_GOOD or COL_BAD); if r.profile then state.profile = r.profile; refreshWallet() end; closeModal(); render.CLASSES() end}) end
		if (pc.crowns or 0) > 0 then table.insert(opts, {"BUY  ·  " .. fmt(pc.crowns) .. " CROWNS", COL_GOLD, function()
			local r = call("Buy", "piece", pc.id, "crowns"); toast(r.msg or "", r.ok and COL_GOOD or COL_BAD); if r.profile then state.profile = r.profile; refreshWallet() end; closeModal(); render.CLASSES() end}) end
		local pk = Catalog.PACKS[pc.pack]
		if pk and not pk.free then table.insert(opts, {"SEE THE " .. string.upper(pk.name) .. " PACK", COL_CARD2, function() closeModal(); ui.shopTab = "packs"; selectTab("SHOP") end}) end
		modal(pc.name, (pc.description or "") .. string.format("\n%s  ·  %s  ·  %s", pc.weight, pk and pk.name or pc.pack, pc.rarity or "Common"), opts)
	end
	local function choose(k, v)
		local lo = edit()
		lo[k] = v
		if k == "weapon" then lo.weaponSkin = v .. ":Default"; if lo.secondary == v then lo.secondary = nil; lo.secondarySkin = nil end end
		if k == "secondary" then lo.secondarySkin = v and (v .. ":Default") or nil end
		ui.dirty[ui.editing] = true
		render.CLASSES()
	end
	render.CLASSES = function()
		local id = ui.editing
		local cls = GameConfig.CLASSES[id]
		local lo = edit()
		renderClassRow()
		renderStage()
		clear(list)
		local p = panel(list, nil)
		for _, slot in ipairs(Catalog.SLOTS) do
			heading(p, slot == "bottom" and "BOTTOM" or string.upper(slot))
			local pieces = Catalog.piecesFor(slot, cls.weight)
			for _, pc in ipairs(pieces) do
				local have = owns("pieces", pc.id)
				local pk = Catalog.PACKS[pc.pack]
				local rightText = have and ((slot == "helmet" and (#(pc.covers or {}) > 0 and ("covers " .. string.lower(table.concat(pc.covers, "+"))) or "open")) or (pk and pk.name or "")) or
					(pc.unlock and ("🔒 " .. Catalog.unlockText(pc.unlock)) or
					((pc.marks or 0) > 0 and (fmt(pc.marks) .. " M") or "") .. ((pc.crowns or 0) > 0 and ("  " .. fmt(pc.crowns) .. " C") or ""))
				row(p, pc.name, rightText, lo[slot] == pc.id, function() if have then choose(slot, pc.id) else buyPiece(pc) end end, have and COL_DIM or COL_MARKS)
			end
			if #pieces == 0 then dim(p, "No " .. string.lower(cls.weight) .. " " .. slot .. " yet: drop a set with Config.Type = \"" .. cls.weight .. "\" into ServerStorage ▸ Armor.") end
		end
		heading(p, "COLOR BLOCKS")
		for _, slot in ipairs({"Primary", "Secondary", "Accent", "Metal"}) do
			dim(p, slot .. (slot == "Primary" and "  ·  team color in team modes" or ""))
			swatches(p, Catalog.PALETTE, function(it) return lo.colors[slot] == it.name end, function(it) return it.crowns and not owns("colors", it.name) end, function(it)
				if it.crowns and not owns("colors", it.name) then
					modal(it.name, string.format("A premium color: %d Crowns once, usable on every slot of every class.", it.crowns), {{"BUY  ·  " .. it.crowns .. " CROWNS", COL_GOLD, function()
						local r = call("Buy", "color", it.name, "crowns"); toast(r.msg or "", r.ok and COL_GOOD or COL_BAD); if r.profile then state.profile = r.profile; refreshWallet() end; closeModal(); render.CLASSES() end}})
				else lo.colors[slot] = it.name; ui.dirty[id] = true; render.CLASSES() end
			end)
		end
		heading(p, "PRIMARY WEAPON")
		local function allowed(w)
			if w.weights then local ok = false; for _, x in ipairs(w.weights) do if x == cls.weight then ok = true end end; if not ok then return false end end
			if cls.weapons and cls.weapons ~= "any" then local ok = false; for _, x in ipairs(cls.weapons) do if x == w.id then ok = true end end; if not ok then return false end end
			return true
		end
		for _, w in ipairs(Catalog.WEAPONS) do
			if allowed(w) then
				local have = owns("weapons", w.id)
				row(p, w.name, have and w.family or ("🔒 " .. unlockText(w)), lo.weapon == w.id, function()
					if have then choose("weapon", w.id) else
						modal(w.name, "Unlock: " .. unlockText(w) .. ((w.marks or 0) > 0 and ("  ·  or buy it outright for " .. fmt(w.marks) .. " Marks") or ""),
							(w.marks or 0) > 0 and {{"BUY  ·  " .. fmt(w.marks) .. " MARKS", COL_CARD_ON, function()
								local r = call("Buy", "weapon", w.id, "marks"); toast(r.msg or "", r.ok and COL_GOOD or COL_BAD); if r.profile then state.profile = r.profile; refreshWallet() end; closeModal(); render.CLASSES() end}} or nil)
					end
				end, have and COL_DIM or COL_MARKS)
			end
		end
		if lo.weapon then
			dim(p, "Skin")
			row(p, "Default", "", (lo.weaponSkin or ""):match(":Default$") ~= nil, function() lo.weaponSkin = lo.weapon .. ":Default"; ui.dirty[id] = true; render.CLASSES() end)
			for _, s in ipairs(Catalog.skinsFor(lo.weapon)) do
				local have = owns("skins", s.id)
				row(p, s.name, have and s.rarity or (s.crate == "earned" and (tostring(s.kills) .. " kills") or (s.crate and (Catalog.CRATES[s.crate] and Catalog.CRATES[s.crate].name or s.crate) or "shop")), lo.weaponSkin == s.id,
					have and function() lo.weaponSkin = s.id; ui.dirty[id] = true; render.CLASSES() end or nil, have and (RARITY_COL[s.rarity] or COL_DIM) or COL_DIM)
			end
		end
		heading(p, "SECONDARY")
		row(p, "None", "", lo.secondary == nil, function() choose("secondary", nil) end)
		for _, w in ipairs(Catalog.WEAPONS) do
			if w.secondary and w.id ~= lo.weapon and allowed(w) then
				local have = owns("weapons", w.id)
				row(p, w.name, have and w.family or ("🔒 " .. unlockText(w)), lo.secondary == w.id, have and function() choose("secondary", w.id) end or nil, have and COL_DIM or COL_MARKS)
			end
		end
		if lo.secondary then
			dim(p, "Secondary skin")
			row(p, "Default", "", (lo.secondarySkin or ""):match(":Default$") ~= nil, function() lo.secondarySkin = lo.secondary .. ":Default"; ui.dirty[id] = true; render.CLASSES() end)
			for _, s in ipairs(Catalog.skinsFor(lo.secondary)) do
				if owns("skins", s.id) then row(p, s.name, s.rarity, lo.secondarySkin == s.id, function() lo.secondarySkin = s.id; ui.dirty[id] = true; render.CLASSES() end, RARITY_COL[s.rarity]) end
			end
		end
		local wt = Catalog.WEIGHTS[cls.weight] or {}
		dim(p, string.format("Weight %s:  +%d health  ·  %d%% speed  ·  %d%% protection on covered limbs. Pieces never change these.", cls.weight, wt.health or 0, math.floor((wt.speed or 1) * 100 + 0.5), math.floor((wt.prot or 0) * 100 + 0.5)))
		renderSide()
	end
	render.CLASSES_save = function()
		local id = ui.editing
		local lo = edit()
		local r = call("SaveClass", id, lo)
		if r.ok then
			ui.dirty[id] = nil
			if r.loadout then ui.classEdit[id] = nil end
			if r.profile then state.profile = r.profile end
			loadCatalog()
			toast((GameConfig.CLASSES[id] and GameConfig.CLASSES[id].name or id) .. " saved", COL_GOOD)
			render.CLASSES()
		else toast(r.msg or "save failed", COL_BAD) end
	end
	render.CLASSES_active = function()
		local r = call("SetActive", ui.editing)
		if r.ok then state.activeClass = ui.editing; if r.profile then state.profile = r.profile end; toast("Spawning as " .. (GameConfig.CLASSES[ui.editing] and GameConfig.CLASSES[ui.editing].name or ui.editing), COL_GOOD) end
		render.CLASSES()
	end
end

--------------------------------------------------------------------
--  SHOP TAB
--------------------------------------------------------------------
do
	local f = tabFrame.SHOP
	local tabs = frame(f, COL_PANEL); tabs.BackgroundTransparency = 1; tabs.Size = UDim2.new(1, 0, 0, 30)
	hlist(tabs, 6)
	local body = frame(f, COL_PANEL); body.BackgroundTransparency = 1; body.Position = UDim2.new(0, 0, 0, 38); body.Size = UDim2.new(1, 0, 1, -38)
	local SHOP_TABS = {{"crates", "CRATES"}, {"packs", "PACKS"}, {"weapons", "WEAPONS"}, {"colors", "COLORS"}}

	local function afterBuy(r) toast(r.msg or "", r.ok and COL_GOOD or COL_BAD); if r.profile then state.profile = r.profile; refreshWallet() end; closeModal(); render.SHOP() end

	local function renderTabs()
		clear(tabs)
		for i, t in ipairs(SHOP_TABS) do
			local on = ui.shopTab == t[1]
			local b = button(tabs, t[2], 13, on and COL_CARD_ON or COL_CARD)
			b.Size = UDim2.fromOffset(120, 30); b.LayoutOrder = i; b.TextColor3 = on and COL_TEXT or COL_DIM
			b.Activated:Connect(function() ui.shopTab = t[1]; render.SHOP() end)
		end
	end

	-- the drum: a strip of skin cards that scrolls and stops under the mark
	local function crates()
		local left = frame(body, COL_PANEL); left.BackgroundTransparency = 1; left.Size = UDim2.new(1, -332, 1, 0)
		local leftList = scroll(left, 8)
		local right = frame(body, COL_PANEL); right.BackgroundTransparency = 1; right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 320, 1, 0)
		local rightList = scroll(right, 8)
		local names = {}
		for k, c in pairs(Catalog.CRATES) do table.insert(names, {text = c.name, id = k}) end
		table.sort(names, function(a, b) return a.id < b.id end)
		chips(leftList, names, function(it) return it.id == ui.crate end, function(it) ui.crate = it.id; render.SHOP() end)
		local crate = Catalog.CRATES[ui.crate]
		if not crate then dim(leftList, "No crates in Catalog ▸ Crates."); return end
		local pool = Catalog.crateSkins(ui.crate)
		-- drum
		local drum = frame(leftList, COL_CARD2, 10)
		drum.Size = UDim2.new(1, 0, 0, 150)
		drum.LayoutOrder = nextOrder()
		drum.ClipsDescendants = true
		local strip = frame(drum, COL_CARD2); strip.BackgroundTransparency = 1; strip.Size = UDim2.new(0, 0, 1, 0); strip.AutomaticSize = Enum.AutomaticSize.X; strip.Position = UDim2.new(0, 0, 0, 0)
		local sl = hlist(strip, 8); sl.VerticalAlignment = Enum.VerticalAlignment.Center
		padding(strip, 8, 8, 0, 0)
		local CARD_W, CARD_GAP = 118, 8
		local N = 24
		local cards = {}
		-- a card: the skin's weapon in 3D, its rarity as the border, its name below
		local function fillCard(c, s)
			clear(c)
			local st = c:FindFirstChildOfClass("UIStroke"); if st then st.Color = RARITY_COL[s.rarity] or COL_DIM end
			local th = weaponThumb(c, s.weapon, s.id, UDim2.new(1, -12, 0, 78)); th.Position = UDim2.new(0, 6, 0, 6)
			local t = label(c, string.upper(Catalog.WEAPON[s.weapon] and Catalog.WEAPON[s.weapon].name or s.weapon) .. "\n" .. s.name, 11, FONT, COL_TEXT); t.Position = UDim2.new(0, 6, 0, 86); t.Size = UDim2.new(1, -12, 0, 36); t.TextXAlignment = Enum.TextXAlignment.Center
		end
		if #pool > 0 then
			for i = 1, N do
				local s = pool[(i - 1) % #pool + 1]
				local c = frame(strip, COL_CARD, 8)
				c.Size = UDim2.fromOffset(CARD_W, 130)
				c.LayoutOrder = i
				local st = Instance.new("UIStroke", c); st.Thickness = 2
				fillCard(c, s)
				cards[i] = {frame = c, skin = s}
			end
		else
			dim(drum, "This crate has no skins yet: point some skins at it in Catalog ▸ Skins.")
		end
		local mark = frame(drum, COL_GOLD); mark.AnchorPoint = Vector2.new(0.5, 0); mark.Position = UDim2.new(0.5, 0, 0, 0); mark.Size = UDim2.new(0, 3, 1, 0); mark.ZIndex = 5
		local function centerOn(index, tweenTime)
			local x = -(8 + (index - 1) * (CARD_W + CARD_GAP) + CARD_W / 2) + drum.AbsoluteSize.X / 2
			if tweenTime then TweenService:Create(strip, TweenInfo.new(tweenTime, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, x, 0, 0)}):Play()
			else strip.Position = UDim2.new(0, x, 0, 0) end
		end
		task.defer(function() centerOn(3) end)
		local rollNote = dim(leftList, ui.rolling and "rolling…" or "the drum slows over 4 s  ·  the one under the line is yours")
		local two = frame(leftList, COL_PANEL); two.BackgroundTransparency = 1; two.AutomaticSize = Enum.AutomaticSize.Y; two.Size = UDim2.new(1, 0, 0, 0); two.LayoutOrder = nextOrder()
		local tl2 = hlist(two, 8)
		local c1 = panel(two, crate.name, true); c1.Size = UDim2.new(0.5, -4, 0, 0)
		local cc = state.profile and state.profile.crates and state.profile.crates[ui.crate] or {opens = 0, sinceLegendary = 0}
		dim(c1, (crate.description or "") .. string.format(" Legendary guaranteed within %d opens (%d since your last).", crate.pity or 20, cc.sinceLegendary or 0))
		local openBtn = bigBtn(c1, "OPEN  ·  " .. tostring(crate.cost) .. " CROWNS", COL_GOLD)
		openBtn.TextColor3 = Color3.fromRGB(30, 22, 10)
		local c2 = panel(two, "ODDS", true); c2.Size = UDim2.new(0.5, -4, 0, 0)
		local oddsLine = {}
		for _, r in ipairs(Catalog.RARITIES) do if crate.odds[r] then table.insert(oddsLine, string.format("%s %d%%", r, crate.odds[r])) end end
		dim(c2, table.concat(oddsLine, "  ·  "))
		local rf = {}
		for _, r in ipairs(Catalog.RARITIES) do if crate.refund and crate.refund[r] then table.insert(rf, string.lower(r) .. " " .. fmt(crate.refund[r])) end end
		dim(c2, "Duplicate: refunded as Marks (" .. table.concat(rf, " · ") .. ").")
		openBtn.Activated:Connect(function()
			if ui.rolling or #pool == 0 then return end
			ui.rolling = true
			openBtn.Active = false
			rollNote.Text = "rolling…"
			local r = call("OpenCrate", ui.crate)
			if not r.ok then ui.rolling = false; openBtn.Active = true; toast(r.msg or "", COL_BAD); rollNote.Text = r.msg or ""; return end
			if r.profile then state.profile = r.profile; refreshWallet() end
			local res = r.result
			-- put the winning skin on a card near the end of the strip and tween to it
			local target = N - 4
			for i = target, N do
				local c = cards[i]
				if c then
					local s = i == target and Catalog.SKIN[res.skinId] or pool[(i * 7) % #pool + 1]
					if s then c.skin = s; fillCard(c.frame, s) end
				end
			end
			centerOn(2)
			task.wait(0.05)
			centerOn(target, 4)
			task.wait(4.2)
			ui.rolling = false
			table.insert(ui.pulls, 1, res)
			local won = Catalog.SKIN[res.skinId]
			modal(string.upper(res.rarity) .. "  ·  " .. res.name, res.dup and string.format("Duplicate — refunded %s Marks.", fmt(res.refund)) or "New skin! Equip it on CLASSES under the weapon's skins.",
				{{"OK", COL_CARD_ON, closeModal}}, function(box)
					local th = weaponThumb(box, won and won.weapon or res.weapon, res.skinId, UDim2.new(1, 0, 0, 150)); th.LayoutOrder = 5
					local st = Instance.new("UIStroke", th); st.Color = RARITY_COL[res.rarity] or COL_DIM; st.Thickness = 2
				end)
			render.SHOP()
		end)
		openBtn.Name = "OpenBtn"
		-- right: pulls + unlocks
		local pl = panel(rightList, "YOUR PULLS THIS SESSION", true)
		if #ui.pulls == 0 then dim(pl, "Nothing yet.") end
		for i, pu in ipairs(ui.pulls) do if i <= 8 then row(pl, pu.name, pu.dup and ("dup +" .. fmt(pu.refund)) or pu.rarity, false, nil, RARITY_COL[pu.rarity]) end end
		local un = panel(rightList, "WEAPON UNLOCKS", true)
		local any = false
		for _, w in ipairs(Catalog.WEAPONS) do if not owns("weapons", w.id) then any = true; row(un, w.name, unlockText(w), false, nil) end end
		if not any then dim(un, "All weapons unlocked.") end
	end

	local function packs()
		local list = scroll(body, 8)
		local grid = frame(list, COL_PANEL); grid.BackgroundTransparency = 1; grid.AutomaticSize = Enum.AutomaticSize.Y; grid.Size = UDim2.new(1, 0, 0, 0); grid.LayoutOrder = nextOrder()
		local g = Instance.new("UIGridLayout", grid); g.CellSize = UDim2.new(0.25, -8, 0, 120); g.CellPadding = UDim2.fromOffset(8, 8); g.SortOrder = Enum.SortOrder.LayoutOrder
		local names = {}
		for k, p in pairs(Catalog.PACKS) do if not p.free then table.insert(names, k) end end
		table.sort(names, function(a, b) local pa, pb = Catalog.PACKS[a], Catalog.PACKS[b]; if (pa.featured == true) ~= (pb.featured == true) then return pa.featured == true end; return pa.name < pb.name end)
		if #names == 0 then dim(list, "No paid packs yet. A pack is a key in Catalog ▸ Packs that pieces (or a set's Config.Pack) name.") end
		for i, k in ipairs(names) do
			local pk = Catalog.PACKS[k]
			local pieces = {}
			local all = true
			for _, pc in ipairs(Catalog.PIECES) do if pc.pack == k then table.insert(pieces, pc); if not owns("pieces", pc.id) then all = false end end end
			local skins = {}
			for _, sk in ipairs(Catalog.SKINS) do if sk.pack == k then table.insert(skins, sk); if not owns("skins", sk.id) then all = false end end end
			local b = button(grid, "", 14, pk.color or COL_CARD)
			b.LayoutOrder = i
			b.AutoButtonColor = false
			local n = label(b, pk.name, 16, FONT_BLACK, COL_TEXT); n.Position = UDim2.new(0, 10, 0, 8); n.Size = UDim2.new(1, -20, 0, 40); n.TextYAlignment = Enum.TextYAlignment.Top
			local s = label(b, (pk.weight or "") .. (pk.featured and "  ·  featured" or "") .. (all and "  ·  owned" or "") .. string.format("  ·  %d piece%s", #pieces, #pieces == 1 and "" or "s") .. (#skins > 0 and string.format("  ·  %d skin%s", #skins, #skins == 1 and "" or "s") or ""), 11, FONT, COL_TEXT); s.Position = UDim2.new(0, 10, 1, -24); s.Size = UDim2.new(1, -20, 0, 16)
			b.Activated:Connect(function()
				local m, c = 0, 0
				for _, pc in ipairs(pieces) do if not owns("pieces", pc.id) then m += pc.marks or 0; c += pc.crowns or 0 end end
				for _, sk in ipairs(skins) do if not owns("skins", sk.id) then m += sk.marks or 0; c += sk.crowns or 0 end end
				local disc = 1 - (pk.bundle or 0)
				modal(pk.name, string.format("%s pack. Buy pieces one by one, or the rest of the pack at %d%% off.", pk.weight or "", math.floor((pk.bundle or 0) * 100 + 0.5)), (not all) and {
					m > 0 and {"ALL  ·  " .. fmt(math.floor(m * disc + 0.5)) .. " MARKS", COL_CARD_ON, function() afterBuy(call("Buy", "pack", k, "marks")) end} or nil,
					c > 0 and {"ALL  ·  " .. fmt(math.floor(c * disc + 0.5)) .. " CROWNS", COL_GOLD, function() afterBuy(call("Buy", "pack", k, "crowns")) end} or nil,
				} or nil, function(box)
					for _, pc in ipairs(pieces) do
						local have = owns("pieces", pc.id)
						row(box, pc.name .. "  ·  " .. pc.slot, have and "owned" or (fmt(pc.marks or 0) .. " M  ·  " .. fmt(pc.crowns or 0) .. " C"), false, (not have) and function()
							modal(pc.name, pc.description or "", {
								(pc.marks or 0) > 0 and {"BUY  ·  " .. fmt(pc.marks) .. " MARKS", COL_CARD_ON, function() afterBuy(call("Buy", "piece", pc.id, "marks")) end} or nil,
								(pc.crowns or 0) > 0 and {"BUY  ·  " .. fmt(pc.crowns) .. " CROWNS", COL_GOLD, function() afterBuy(call("Buy", "piece", pc.id, "crowns")) end} or nil})
						end or nil, have and COL_GOOD or COL_MARKS)
					end
					for _, sk in ipairs(skins) do
						local have = owns("skins", sk.id)
						row(box, (Catalog.WEAPON[sk.weapon] and Catalog.WEAPON[sk.weapon].name or sk.weapon) .. "  ·  " .. sk.name .. " skin", have and "owned" or (fmt(sk.marks or 0) .. " M  ·  " .. fmt(sk.crowns or 0) .. " C"), false, (not have) and function()
							modal(sk.name, sk.rarity or "", {
								(sk.marks or 0) > 0 and {"BUY  ·  " .. fmt(sk.marks) .. " MARKS", COL_CARD_ON, function() afterBuy(call("Buy", "skin", sk.id, "marks")) end} or nil,
								(sk.crowns or 0) > 0 and {"BUY  ·  " .. fmt(sk.crowns) .. " CROWNS", COL_GOLD, function() afterBuy(call("Buy", "skin", sk.id, "crowns")) end} or nil})
						end or nil, have and COL_GOOD or (RARITY_COL[sk.rarity] or COL_MARKS))
					end
					if #pieces == 0 and #skins == 0 then dim(box, "Nothing names this pack yet.") end
				end)
			end)
		end
		-- earned in battle: pieces, skins and titles with a kill / win / level requirement
		local e = panel(list, "EARNED IN BATTLE", true)
		local any = false
		for _, pc in ipairs(Catalog.PIECES) do
			if pc.unlock then
				any = true
				local have = owns("pieces", pc.id)
				row(e, pc.name .. "  ·  " .. pc.weight .. " " .. pc.slot, have and "earned ✓" or (Catalog.unlockText(pc.unlock) .. "  ·  " .. progressText(pc.unlock)), false, nil, have and COL_GOOD or COL_DIM)
			end
		end
		for _, sk in ipairs(Catalog.SKINS) do
			if sk.crate == "earned" then
				any = true
				local have = owns("skins", sk.id)
				local u = {kills = sk.kills, weapon = sk.weapon}
				row(e, (Catalog.WEAPON[sk.weapon] and Catalog.WEAPON[sk.weapon].name or sk.weapon) .. "  ·  " .. sk.name .. " skin", have and "earned ✓" or (Catalog.unlockText(u) .. "  ·  " .. progressText(u)), false, nil, have and COL_GOOD or (RARITY_COL[sk.rarity] or COL_DIM))
			end
		end
		for _, et in ipairs(Catalog.BODY.earnedTitles or {}) do
			any = true
			local have = owns("titles", et.title)
			row(e, "Title: " .. et.title, have and "earned ✓" or (Catalog.unlockText(et.unlock) .. "  ·  " .. progressText(et.unlock)), false, nil, have and COL_GOOD or COL_DIM)
		end
		if not any then dim(e, "Nothing to earn yet.") end
	end

	local function weapons()
		local list = scroll(body, 8)
		local grid = frame(list, COL_PANEL); grid.BackgroundTransparency = 1; grid.AutomaticSize = Enum.AutomaticSize.Y; grid.Size = UDim2.new(1, 0, 0, 0); grid.LayoutOrder = nextOrder()
		local gl = Instance.new("UIGridLayout", grid); gl.CellSize = UDim2.new(0.5, -6, 0, 0); gl.CellPadding = UDim2.fromOffset(8, 8); gl.SortOrder = Enum.SortOrder.LayoutOrder
		for i, w in ipairs(Catalog.WEAPONS) do
			local have = owns("weapons", w.id)
			local p = panel(grid, nil, true)
			p.LayoutOrder = i
			p.AutomaticSize = Enum.AutomaticSize.Y
			local t = label(p, w.name .. "   ·   " .. w.family .. (w.secondary and "  ·  secondary ok" or ""), 15, FONT, COL_TEXT); t.Size = UDim2.new(1, 0, 0, 20); t.LayoutOrder = nextOrder()
			dim(p, have and "unlocked" or ("unlock: " .. unlockText(w) .. ((w.marks or 0) > 0 and ("  ·  or " .. fmt(w.marks) .. " Marks") or "")))
			if not have and (w.marks or 0) > 0 then
				local b = bigBtn(p, "BUY  ·  " .. fmt(w.marks) .. " MARKS", COL_CARD_ON, function() afterBuy(call("Buy", "weapon", w.id, "marks")) end)
			end
			dim(p, "Skins")
			local n = 0
			for _, s in ipairs(Catalog.skinsFor(w.id)) do
				n += 1
				local src = owns("skins", s.id) and "owned" or (s.crate == "earned" and (tostring(s.kills) .. " kills with it") or (s.crate and ((Catalog.CRATES[s.crate] and Catalog.CRATES[s.crate].name or s.crate)) or ((s.marks or 0) > 0 and (fmt(s.marks) .. " M") or ((s.crowns or 0) > 0 and (fmt(s.crowns) .. " C") or "shop"))))
				local buyable = not owns("skins", s.id) and not s.crate and ((s.marks or 0) > 0 or (s.crowns or 0) > 0)
				row(p, s.name, src, false, buyable and function()
					modal(w.name .. "  ·  " .. s.name, s.rarity, {
						(s.marks or 0) > 0 and {"BUY  ·  " .. fmt(s.marks) .. " MARKS", COL_CARD_ON, function() afterBuy(call("Buy", "skin", s.id, "marks")) end} or nil,
						(s.crowns or 0) > 0 and {"BUY  ·  " .. fmt(s.crowns) .. " CROWNS", COL_GOLD, function() afterBuy(call("Buy", "skin", s.id, "crowns")) end} or nil})
				end or nil, RARITY_COL[s.rarity])
			end
			if n == 0 then dim(p, "No skins yet.") end
		end
	end

	local function colors()
		local list = scroll(body, 8)
		local two = frame(list, COL_PANEL); two.BackgroundTransparency = 1; two.AutomaticSize = Enum.AutomaticSize.Y; two.Size = UDim2.new(1, 0, 0, 0); two.LayoutOrder = nextOrder()
		hlist(two, 8)
		local a = panel(two, "PREMIUM ARMOR COLORS", true); a.Size = UDim2.new(0.5, -4, 0, 0)
		local n = 0
		for _, c in ipairs(Catalog.PALETTE) do
			if c.crowns then
				n += 1
				local have = owns("colors", c.name)
				local r = row(a, "      " .. c.name, have and "owned" or (tostring(c.crowns) .. " CROWNS"), false, (not have) and function() afterBuy(call("Buy", "color", c.name, "crowns")) end or nil, have and COL_GOOD or COL_CROWNS)
				local sw = frame(r, c.color, 4); sw.Size = UDim2.fromOffset(18, 18); sw.Position = UDim2.new(0, 0, 0.5, -9)
			end
		end
		if n == 0 then dim(a, "No premium colors (Catalog ▸ Palette, crowns = …).") end
		dim(a, "Bought once, usable on every slot of every class.")
		local b = panel(two, "PREMIUM HAIR COLORS & BEARDS", true); b.Size = UDim2.new(0.5, -4, 0, 0)
		n = 0
		for _, h in ipairs(Catalog.BODY.hairColors) do
			if h.crowns then
				n += 1
				local have = owns("hairColors", h.name)
				local r = row(b, "      " .. h.name .. " hair", have and "owned" or (tostring(h.crowns) .. " CROWNS"), false, (not have) and function() afterBuy(call("Buy", "hairColor", h.name, "crowns")) end or nil, have and COL_GOOD or COL_CROWNS)
				local sw = frame(r, h.color, 4); sw.Size = UDim2.fromOffset(18, 18); sw.Position = UDim2.new(0, 0, 0.5, -9)
			end
		end
		for _, bd in ipairs(Catalog.BODY.beards) do
			if bd.crowns then
				n += 1
				local have = owns("beards", bd.id)
				row(b, bd.name .. " beard", have and "owned" or (tostring(bd.crowns) .. " CROWNS"), false, (not have) and function() afterBuy(call("Buy", "beard", bd.id, "crowns")) end or nil, have and COL_GOOD or COL_CROWNS)
			end
		end
		if n == 0 then dim(b, "Nothing premium here yet (Catalog ▸ Body).") end
	end

	render.SHOP = function()
		renderTabs()
		clear(body)
		if ui.shopTab == "crates" then crates() elseif ui.shopTab == "packs" then packs() elseif ui.shopTab == "weapons" then weapons() else colors() end
		renderSide()
	end

	-- GET CROWNS: Robux products + Crowns → Marks
	getCrownsBtn.Activated:Connect(function()
		modal("GET CROWNS", "Crowns are bought with Robux. Marks are earned by playing, or exchanged from Crowns (one way).", nil, function(box)
			heading(box, "CROWN BUNDLES  ·  ROBUX")
			for i, pr in ipairs(ECON.products or {}) do
				row(box, string.format("%s Crowns%s", fmt(pr.crowns), pr.bonus and ("  ·  " .. pr.bonus) or ""), pr.id == 0 and "not set up yet" or ("R$ " .. fmt(pr.robux)), false, function()
					local r = call("BuyCrowns", i); toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
				end, pr.id == 0 and COL_DIM or COL_CROWNS)
			end
			heading(box, "CROWNS → MARKS")
			for i, ex in ipairs(ECON.exchange or {}) do
				row(box, fmt(ex.marks) .. " Marks", fmt(ex.crowns) .. " Crowns", false, function() afterBuy(call("Exchange", i)) end, COL_MARKS)
			end
		end)
	end)
end

--------------------------------------------------------------------
--  SERVERS TAB (browser + custom)
--------------------------------------------------------------------
do
	local f = tabFrame.SERVERS
	local listHolder = frame(f, COL_CARD2, 10); listHolder.Size = UDim2.new(1, 0, 1, 0); padding(listHolder, 12, 12, 10, 10)
	local list = scroll(listHolder, 6)
	local customHolder = frame(f, COL_CARD, 10); customHolder.AnchorPoint = Vector2.new(1, 0); customHolder.Position = UDim2.new(1, 0, 0, 0); customHolder.Size = UDim2.new(0, 340, 1, 0); customHolder.Visible = false
	padding(customHolder, 12, 12, 10, 10)
	local customList = scroll(customHolder, 6)
	local COLS = {{"SERVER", 0.34}, {"MODE", 0.2}, {"MAP", 0.14}, {"PLAYERS", 0.14}, {"", 0.18}}

	local function joinServer(s)
		local r = call("Join", s.jobId)
		toast(r.msg or (r.ok and "joining…" or "could not join"), r.ok and COL_GOOD or COL_BAD)
	end

	local function renderList()
		clear(list)
		local F = ui.filters
		local items = {{text = "HIDE EMPTY", k = "hideEmpty"}, {text = "HIDE FULL", k = "hideFull"}, {text = "CUSTOM ONLY", k = "customOnly"}}
		for _, d in ipairs({"Warfront", "Tiltyard", "Courtyard"}) do table.insert(items, {text = string.upper(d), door = d}) end
		chips(list, items, function(it) if it.k then return F[it.k] == true end; return F.door == it.door end, function(it)
			if it.k then F[it.k] = not F[it.k] else F.door = (F.door == it.door) and nil or it.door end
			renderList()
		end)
		if F.door then dim(list, "Filtered to " .. string.upper(F.door) .. ". Click the chip again to see everything.") end
		local head = frame(list, COL_PANEL); head.BackgroundTransparency = 1; head.Size = UDim2.new(1, 0, 0, 18); head.LayoutOrder = nextOrder()
		local x = 0
		for _, c in ipairs(COLS) do local t = label(head, c[1], 11, FONT, COL_DIM); t.Position = UDim2.new(x, 8, 0, 0); t.Size = UDim2.new(c[2], -8, 1, 0); x += c[2] end
		local shown = 0
		for _, s in ipairs(state.servers) do
			local door = s.door or (s.mode == "Hub" and "Courtyard" or "Warfront")
			local ok = true
			if F.hideEmpty and (s.players or 0) == 0 and not s.here then ok = false end
			if F.hideFull and (s.players or 0) >= (s.max or 1) then ok = false end
			if F.customOnly and not s.custom then ok = false end
			if F.door and door ~= F.door then ok = false end
			if ok then
				shown += 1
				local r = frame(list, s.here and COL_CARD_ON or COL_PANEL, 6)
				r.Size = UDim2.new(1, 0, 0, 40); r.LayoutOrder = nextOrder(); r.BackgroundTransparency = s.here and 0.3 or 0
				if s.cheats then r.BackgroundTransparency = 0.4 end
				local name = (s.custom and s.name ~= "" and ("⚑ " .. s.name)) or (door .. "  #" .. string.sub(tostring(s.jobId or "?"), 1, 6))
				if s.pending then name = name .. "  (starting)" end
				if s.cheats then name = name .. "  ·  cheats, no rewards" elseif s.custom then name = name .. "  ·  custom" end
				local cells = {name .. (s.here and "   (here)" or ""), s.modeName ~= "" and s.modeName or s.mode, s.map, string.format("%d / %d", s.players or 0, s.max or 0)}
				x = 0
				for ci, c in ipairs(COLS) do
					if ci <= 4 then
						local t = label(r, cells[ci], 13, ci == 1 and FONT or FONT_BODY, ci == 4 and ((s.players or 0) >= (s.max or 1) and COL_BAD or COL_TEXT) or COL_TEXT)
						t.Position = UDim2.new(x, 8, 0, 0); t.Size = UDim2.new(c[2], -8, 1, 0); t.TextWrapped = false; t.TextTruncate = Enum.TextTruncate.AtEnd
					end
					x += c[2]
				end
				local b = button(r, s.here and "HERE" or (s.access == "Friends" and "FRIENDS ONLY" or (s.state == "Intermission" and "JOIN  (between rounds)" or "JOIN")), 12, s.here and COL_CARD or COL_GO)
				b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, -6, 0.5, 0); b.Size = UDim2.new(0.18, -10, 0, 28); b.TextTruncate = Enum.TextTruncate.AtEnd
				if s.here then b.AutoButtonColor = false else b.Activated:Connect(function() joinServer(s) end) end
			end
		end
		if shown == 0 then dim(list, #state.servers == 0 and "No servers answered — in Studio only this one exists." or "Nothing matches these filters.", 13) end
	end

	-- custom panel
	local function cycle(list_, cur, dir)
		local idx = 1
		for i, v in ipairs(list_) do if v == cur then idx = i end end
		return list_[(idx - 1 + dir) % #list_ + 1]
	end
	local function renderCustom()
		clear(customList)
		local c = ui.custom
		local t = label(customList, "CREATE CUSTOM SERVER", 15, FONT_BLACK, COL_ACCENT); t.Size = UDim2.new(1, 0, 0, 22); t.LayoutOrder = nextOrder()
		local box = Instance.new("TextBox")
		box.PlaceholderText = player.DisplayName .. "'s server"; box.Text = c.name or ""; box.ClearTextOnFocus = false
		box.Font = FONT_BODY; box.TextSize = 13; box.TextColor3 = COL_TEXT; box.PlaceholderColor3 = COL_DIM
		box.BackgroundColor3 = COL_PANEL; box.BorderSizePixel = 0; box.Size = UDim2.new(1, 0, 0, 30); box.LayoutOrder = nextOrder(); box.TextXAlignment = Enum.TextXAlignment.Left
		box.Parent = customList
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
		padding(box, 10, 10, 0, 0)
		box.FocusLost:Connect(function() c.name = box.Text end)
		local doors = {"Warfront", "Tiltyard"}
		local modes = c.door == "Tiltyard" and {"Tiltyard"} or GameConfig.DOORS.Warfront.modes
		local okMode = false; for _, m in ipairs(modes) do if m == c.mode then okMode = true end end
		if not okMode then c.mode = modes[1] end
		local def = GameConfig.MODES[c.mode] or {}
		local maps = {""}; for _, m in ipairs(def.maps or {}) do table.insert(maps, m) end
		local okMap = false; for _, m in ipairs(maps) do if m == c.map then okMap = true end end
		if not okMap then c.map = "" end
		local function sel(labelText, value, onLeft, onRight)
			local r = frame(customList, COL_PANEL, 6); r.Size = UDim2.new(1, 0, 0, 30); r.LayoutOrder = nextOrder()
			padding(r, 10, 4, 0, 0)
			local l = label(r, labelText, 12, FONT_BODY, COL_DIM); l.Size = UDim2.new(0.45, 0, 1, 0)
			local v = label(r, value, 12, FONT, COL_TEXT); v.Position = UDim2.new(0.45, 0, 0, 0); v.Size = UDim2.new(0.55, -60, 1, 0); v.TextXAlignment = Enum.TextXAlignment.Right; v.TextWrapped = false; v.TextTruncate = Enum.TextTruncate.AtEnd
			local lb = button(r, "◀", 11, COL_CARD); lb.AnchorPoint = Vector2.new(1, 0.5); lb.Position = UDim2.new(1, -30, 0.5, 0); lb.Size = UDim2.fromOffset(26, 24); lb.Activated:Connect(function() onLeft(); renderCustom() end)
			local rb = button(r, "▶", 11, COL_CARD); rb.AnchorPoint = Vector2.new(1, 0.5); rb.Position = UDim2.new(1, 0, 0.5, 0); rb.Size = UDim2.fromOffset(26, 24); rb.Activated:Connect(function() onRight(); renderCustom() end)
		end
		local function tog(labelText, k, hintText)
			local r = frame(customList, COL_PANEL, 6); r.Size = UDim2.new(1, 0, 0, 30); r.LayoutOrder = nextOrder()
			padding(r, 10, 4, 0, 0)
			local l = label(r, labelText, 12, FONT_BODY, COL_DIM); l.Size = UDim2.new(0.7, 0, 1, 0)
			local b = button(r, c[k] and "ON" or "OFF", 11, c[k] and COL_GOOD or COL_CARD); b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, 0, 0.5, 0); b.Size = UDim2.fromOffset(56, 24)
			b.Activated:Connect(function() c[k] = not c[k]; renderCustom() end)
		end
		sel("Door", c.door, function() c.door = cycle(doors, c.door, -1) end, function() c.door = cycle(doors, c.door, 1) end)
		sel("Mode", GameConfig.MODES[c.mode] and GameConfig.MODES[c.mode].name or c.mode, function() c.mode = cycle(modes, c.mode, -1) end, function() c.mode = cycle(modes, c.mode, 1) end)
		sel("Map", c.map ~= "" and c.map or "rotate", function() c.map = cycle(maps, c.map, -1) end, function() c.map = cycle(maps, c.map, 1) end)
		local limits = {2, 4, 6, 8, 12, 16, 24, 32, 40}
		sel("Player limit", tostring(c.limit), function() c.limit = cycle(limits, c.limit, -1) end, function() c.limit = cycle(limits, c.limit, 1) end)
		local lengths = {180, 300, 480, 900, 1200}
		sel("Round length", string.format("%d min", math.floor((c.roundLength or 300) / 60)), function() c.roundLength = cycle(lengths, c.roundLength, -1) end, function() c.roundLength = cycle(lengths, c.roundLength, 1) end)
		local access = {"Public", "Friends", "Locked"}
		sel("Who can join", c.access == "Public" and "Listed · anyone" or (c.access == "Friends" and "Friends of players" or "Party only"), function() c.access = cycle(access, c.access, -1) end, function() c.access = cycle(access, c.access, 1) end)
		tog("Friendly fire", "friendlyFire")
		tog("Respawns", "respawns")
		tog("Weapons on the ground", "groundWeapons")
		tog("Cheats / host commands", "cheats")
		dim(customList, c.cheats and "Marked as a cheat server: /god /heal /speed /tp /bring /give /kick for the host. No Marks, XP or rating for anyone in it."
			or "Cheats give the host /god /heal /speed /tp /bring /give /kick. The server is marked and pays no Marks, XP or rating.")
		bigBtn(customList, "RESERVE & TRAVEL", COL_GOLD, function()
			c.name = box.Text
			local r = call("Custom", c)
			toast(r.msg or "", r.ok and COL_GOOD or COL_BAD)
		end).TextColor3 = Color3.fromRGB(30, 22, 10)
		dim(customList, "You and your party travel there together (everyone ready first).")
	end

	render.SERVERS = function()
		loadServers(true)
		customHolder.Visible = ui.customOpen
		listHolder.Size = ui.customOpen and UDim2.new(1, -352, 1, 0) or UDim2.new(1, 0, 1, 0)
		renderList()
		if ui.customOpen then renderCustom() end
		renderSide()
	end
	task.spawn(function()
		while true do
			task.wait(SERVER_REFRESH)
			if open and currentTab == "SERVERS" then render.SERVERS() end
		end
	end)
end

--------------------------------------------------------------------
--  SETTINGS TAB (camera feel · attack side · keybinds)
--------------------------------------------------------------------
do
	local f = tabFrame.SETTINGS
	local sHint = label(f, "Camera feel is a multiplier on the tuned default (1.0); 0 turns an effect off. Right mouse is always block. Escape belongs to Roblox, so M is the menu key everywhere.", 13, FONT_BODY, COL_DIM)
	sHint.Size = UDim2.new(1, -170, 0, 32)
	local resetBtn = button(f, "RESET DEFAULTS", 13, COL_CARD)
	resetBtn.AnchorPoint = Vector2.new(1, 0)
	resetBtn.Position = UDim2.new(1, 0, 0, 0)
	resetBtn.Size = UDim2.fromOffset(150, 32)

	local sBody = frame(f, COL_PANEL)
	sBody.BackgroundTransparency = 1
	sBody.Position = UDim2.new(0, 0, 0, 44)
	sBody.Size = UDim2.new(1, 0, 1, -44)
	local sLayout = hlist(sBody, 24)

	local function settingsColumn(headingText, widthScale)
		local col = frame(sBody, COL_PANEL)
		col.BackgroundTransparency = 1
		col.Size = UDim2.new(widthScale, -12, 1, 0)
		local h = label(col, headingText, 16, FONT, COL_TEXT)
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
		local r = frame(camCol, COL_PANEL)
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, -8, 0, 52)
		r.LayoutOrder = order
		local name = label(r, spec.label, 14, FONT, COL_TEXT); name.Size = UDim2.new(0.7, 0, 0, 20)
		local val = label(r, "", 14, FONT, COL_ACCENT); val.AnchorPoint = Vector2.new(1, 0); val.Position = UDim2.new(1, 0, 0, 0); val.Size = UDim2.new(0.3, 0, 0, 20); val.TextXAlignment = Enum.TextXAlignment.Right
		local h = label(r, spec.hint or "", 11, FONT_BODY, COL_DIM); h.Position = UDim2.new(0, 0, 0, 20); h.Size = UDim2.new(1, 0, 0, 14); h.TextWrapped = false; h.TextTruncate = Enum.TextTruncate.AtEnd
		local track = Instance.new("TextButton")
		track.Text = ""; track.AutoButtonColor = false
		track.Position = UDim2.new(0, 0, 0, 40); track.Size = UDim2.new(1, 0, 0, 10)
		track.BackgroundColor3 = Color3.new(0, 0, 0); track.BackgroundTransparency = 0.5; track.BorderSizePixel = 0
		track.Parent = r
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
		local r = frame(keyCol, COL_PANEL)
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, -8, 0, 34)
		r.LayoutOrder = order
		local name = label(r, spec.label, 14, FONT_BODY, COL_TEXT); name.Size = UDim2.new(0.55, 0, 1, 0)
		local btn = button(r, "", 13, COL_CARD)
		btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, 0, 0.5, 0); btn.Size = UDim2.new(0.42, 0, 0, 30)
		local function refresh()
			if listening and listening.key == spec.key then btn.Text = "press a key…"; btn.TextColor3 = COL_ACCENT
			else btn.Text = ClientSettings.get("Key_" .. spec.key); btn.TextColor3 = COL_TEXT end
		end
		keyRefresh[spec.key] = refresh
		refresh()
		btn.Activated:Connect(function()
			listening = {key = spec.key, since = os.clock()}
			for _, rf in pairs(keyRefresh) do rf() end
		end)
	end
	local function choiceRow(spec, order)
		local r = frame(keyCol, COL_PANEL)
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, -8, 0, 56)
		r.LayoutOrder = order
		local name = label(r, spec.label, 14, FONT_BODY, COL_TEXT); name.Size = UDim2.new(0.55, 0, 0, 30)
		local h = label(r, spec.hint or "", 10, FONT_BODY, COL_DIM); h.Position = UDim2.new(0, 0, 0, 30); h.Size = UDim2.new(1, 0, 0, 26); h.TextYAlignment = Enum.TextYAlignment.Top
		local btn = button(r, "", 13, COL_CARD)
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
		for _, rf in pairs(keyRefresh) do rf() end
	end
	UserInputService.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton3 then captureBind(input) end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if listening and input.UserInputType == Enum.UserInputType.MouseWheel and input.Position.Z ~= 0 then captureBind(input) end
	end)

	local function refreshAll()
		for _, rf in pairs(sliderRefresh) do rf() end
		for _, rf in pairs(keyRefresh) do rf() end
		for _, rf in pairs(choiceRefresh) do rf() end
	end
	ClientSettings.onChanged(function() refreshAll() end)
	resetBtn.Activated:Connect(function() ClientSettings.reset(); refreshAll() end)
	render.SETTINGS = function() refreshAll(); renderSide() end
end

--------------------------------------------------------------------
--  SIDE FOOT (per tab) + HEADER
--------------------------------------------------------------------
local function doorSub(id)
	local counts, servers = doorCounts()
	if id == "Courtyard" then return string.format("hub  ·  %d here", counts.Courtyard or 0) end
	if id == "Tiltyard" then return "training  ·  you + party" end
	if id == "Warfront" then return string.format("%d fighting  ·  %d server%s", counts.Warfront or 0, servers.Warfront or 0, (servers.Warfront or 0) == 1 and "" or "s") end
	return "arena  ·  1v1 · 2v2 · 3v3"
end
local function partyBlocked()
	local p = state.party
	if not p or #p.members <= 1 then return nil end
	if p.leaderId ~= player.UserId then return "the leader picks where you go" end
	if not p.allReady then return "waiting for everyone to ready up" end
	return nil
end
renderSide = function()
	clear(sideFoot)
	local inMatch = not inHub()
	if currentTab == "PLAY" then
		local h = label(sideFoot, "WHERE TO", 11, FONT, COL_DIM); h.Size = UDim2.new(1, 0, 0, 16); h.LayoutOrder = nextOrder()
		for _, id in ipairs(GameConfig.DOOR_ORDER) do
			local d = GameConfig.DOORS[id]
			local on = ui.door == id
			local b = button(sideFoot, "", 13, on and COL_CARD_ON or COL_CARD)
			b.Size = UDim2.new(1, 0, 0, 44); b.LayoutOrder = nextOrder(); b.AutoButtonColor = false
			local n = label(b, string.upper(d.name), 13, FONT_BLACK, on and COL_TEXT or COL_DIM); n.Position = UDim2.new(0, 10, 0, 5); n.Size = UDim2.new(1, -16, 0, 18)
			local s = label(b, doorSub(id), 10, FONT_BODY, COL_DIM); s.Position = UDim2.new(0, 10, 0, 24); s.Size = UDim2.new(1, -16, 0, 14); s.TextWrapped = false; s.TextTruncate = Enum.TextTruncate.AtEnd
			b.Activated:Connect(function() ui.door = id; render.PLAY() end)
		end
		local blocked = partyBlocked()
		local text, color
		if alive() and ui.door == state.door and not (ui.door == "Courtyard" and not inHub()) then text, color = "RESUME", COL_CARD
		elseif ui.door == "Courtyard" then
			if inHub() and roundState() == "Round" and not alive() then text, color = "ENTER COURTYARD ▸", COL_GO_ON
			elseif inHub() then text, color = "TO SPAWN SCREEN", COL_CARD
			else text, color = "RETURN TO COURTYARD ▸", COL_GO_ON end
		elseif ui.door == "Lists" then text, color = state.queue and "SEARCHING…" or "FIND MATCH ▸", COL_GO_ON
		elseif ui.door == "Tiltyard" then text, color = "OPEN TILTYARD ▸", COL_GO_ON
		else text, color = "QUICK JOIN ▸", COL_GO_ON end
		if blocked and text ~= "RESUME" then color = COL_CARD end
		local go = bigBtn(sideFoot, text, color, function()
			if text == "RESUME" then hide(); return end
			if blocked then toast(blocked, COL_BAD); return end
			if ui.door == "Courtyard" then
				if inHub() and roundState() == "Round" and not alive() then loadoutEvent:FireServer("Spawn", state.activeClass)
				elseif inHub() then hide()
				else goDoor("Courtyard") end
			elseif ui.door == "Lists" then if not state.queue then findMatch() end
			else goDoor(ui.door) end
		end)
		go.Size = UDim2.new(1, 0, 0, 44)
		local note = dim(sideFoot, blocked or (state.studio and "Studio: no teleports, PLAY switches this server's mode." or ""), 10)
	elseif currentTab == "CLASSES" then
		local d = ui.dirty[ui.editing]
		bigBtn(sideFoot, d and ("SAVE " .. string.upper(ui.editing)) or "SAVED ✓", d and COL_GOLD or COL_CARD, function() if d then render.CLASSES_save() end end).TextColor3 = d and Color3.fromRGB(30, 22, 10) or COL_TEXT
		bigBtn(sideFoot, state.activeClass == ui.editing and "ACTIVE CLASS ★" or "SET ACTIVE", state.activeClass == ui.editing and COL_CARD_ON or COL_CARD, render.CLASSES_active)
		bigBtn(sideFoot, "TEAM PREVIEW" .. (ui.team and (": " .. (GameConfig.TEAMS[ui.team] and string.upper(GameConfig.TEAMS[ui.team].name) or ui.team)) or ""), ui.team and COL_CARD_ON or COL_CARD, function()
			ui.team = ui.team == nil and "A" or (ui.team == "A" and "B" or nil); render.CLASSES()
		end)
	elseif currentTab == "APPEARANCE" then
		bigBtn(sideFoot, ui.appDirty and "SAVE" or "SAVED ✓", ui.appDirty and COL_GOLD or COL_CARD, function() if ui.appDirty then render.APPEARANCE_save() end end).TextColor3 = ui.appDirty and Color3.fromRGB(30, 22, 10) or COL_TEXT
		bigBtn(sideFoot, ui.helmPreview and "BACK TO EDITING" or "PREVIEW WITH HELMET", ui.helmPreview and COL_CARD_ON or COL_CARD, function() ui.helmPreview = not ui.helmPreview; render.APPEARANCE() end)
	elseif currentTab == "SERVERS" then
		bigBtn(sideFoot, ui.customOpen and "CLOSE CUSTOM" or "CREATE CUSTOM", COL_GOLD, function() ui.customOpen = not ui.customOpen; render.SERVERS() end).TextColor3 = Color3.fromRGB(30, 22, 10)
		bigBtn(sideFoot, "↻  REFRESH", COL_CARD, function() state.serversAt = 0; render.SERVERS() end)
	end
	if inMatch then
		spacer(sideFoot, 4)
		if alive() and currentTab ~= "PLAY" then bigBtn(sideFoot, "RESUME", COL_CARD, hide) end
		if currentTab ~= "PLAY" or ui.door ~= "Courtyard" then
			bigBtn(sideFoot, "⌂  RETURN TO COURTYARD", COL_CARD, function() goDoor("Courtyard") end)
		end
		if state.ranked and state.door == "Lists" then dim(sideFoot, "Ranked: leaving before the end counts as a loss and locks the queue for " .. tostring(ECON.queueLockMinutes or 10) .. " min.", 10) end
	elseif alive() and currentTab ~= "PLAY" then
		spacer(sideFoot, 4)
		bigBtn(sideFoot, "RESUME", COL_CARD, hide)
	end
end

local function refreshHeader()
	local modeName = roundNode:GetAttribute("ModeName") or ""
	local map = roundNode:GetAttribute("Map") or ""
	local where = inHub() and "" or string.format("%s%s%s  ·  ", (state.name or "") ~= "" and (state.name .. "  ·  ") or "", modeName, map ~= "" and (" on " .. map) or "")
	local subs = {
		PLAY = where .. string.format("%s  ·  %d player%s%s", GameConfig.CLASSES[state.activeClass] and GameConfig.CLASSES[state.activeClass].name or "", #Players:GetPlayers(), #Players:GetPlayers() == 1 and "" or "s",
			state.noRewards and "  ·  cheat server, no rewards" or ""),
		APPEARANCE = ui.helmPreview and "Preview with the active class's helmet" or ("Armor and weapon come off while you edit" .. (ui.appDirty and "  ·  unsaved" or "")),
		CLASSES = string.format("%s  ·  %s%s", GameConfig.CLASSES[ui.editing] and GameConfig.CLASSES[ui.editing].name or ui.editing, weightOf(ui.editing), ui.dirty[ui.editing] and "  ·  unsaved" or ""),
		SHOP = "Packs rotate  ·  crates roll a weapon skin  ·  duplicates refund Marks",
		SERVERS = "Pick a server, or create a custom one with your own rules",
		SETTINGS = "Camera feel, keybinds, attack side  ·  M is the menu key everywhere",
	}
	title.Text = (not inHub() and alive()) and ("PAUSED  ·  " .. currentTab) or currentTab
	subtitle.Text = subs[currentTab] or ""
	refreshWallet()
end

selectTab = function(name)
	if not tabFrame[name] then name = "PLAY" end
	currentTab = name
	listening = nil
	for _, n in ipairs(TABS) do
		local on = n == name
		tabFrame[n].Visible = on
		tabBtn[n].BackgroundColor3 = on and COL_CARD_ON or COL_CARD
		tabBtn[n].TextColor3 = on and COL_TEXT or COL_DIM
	end
	refreshHeader()
	if render[name] then task.spawn(render[name]) end
	renderSide()
end
for _, name in ipairs(TABS) do tabBtn[name].Activated:Connect(function() selectTab(name) end) end

--------------------------------------------------------------------
--  CINEMATIC CAMERA + MOUSE
--------------------------------------------------------------------
local cineOn = false
local function classScreenUp()
	local lm = playerGui:FindFirstChild("LoadoutMenu")
	return lm ~= nil and lm.Enabled
end
local ORBIT_SPEED  = 0.045
local ORBIT_HEIGHT = 0.55
local ORBIT_DIST   = 1.15
local GAZE_WANDER  = 0.28
local bounds = nil
local boundsAt = 0
local lastCine = nil

local function measure()
	local map = workspace:FindFirstChild("Map")
	local cf, size
	if map and map:IsA("Model") then
		cf, size = map:GetBoundingBox()
	else
		local minV, maxV = nil, nil
		local n = 0
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("BasePart") and not d:IsA("Terrain") and not Players:GetPlayerFromCharacter(d.Parent) and d.Size.Magnitude > 1 then
				n += 1
				if n > 4000 then break end
				local half = d.Size * 0.5
				local pos = d.Position
				minV = minV and Vector3.new(math.min(minV.X, pos.X - half.X), math.min(minV.Y, pos.Y - half.Y), math.min(minV.Z, pos.Z - half.Z)) or pos - half
				maxV = maxV and Vector3.new(math.max(maxV.X, pos.X + half.X), math.max(maxV.Y, pos.Y + half.Y), math.max(maxV.Z, pos.Z + half.Z)) or pos + half
			end
		end
		if minV then cf, size = CFrame.new((minV + maxV) * 0.5), maxV - minV else cf, size = CFrame.new(0, 4, 0), Vector3.new(80, 8, 80) end
	end
	local radius = math.max(size.X, size.Z) * 0.5
	radius = math.max(radius, 20)
	bounds = {center = cf.Position, radius = radius, top = cf.Position.Y + size.Y * 0.5, bottom = cf.Position.Y - size.Y * 0.5}
	boundsAt = os.clock()
end

local function cinematicCFrame(t)
	if not bounds or os.clock() - boundsAt > 4 then measure() end
	local b = bounds
	local r = b.radius
	local ang = t * ORBIT_SPEED
	local dist = r * ORBIT_DIST * (1 + 0.08 * math.sin(t * 0.07))
	local height = b.top + r * ORBIT_HEIGHT * (1 + 0.15 * math.sin(t * 0.05))
	local pos = Vector3.new(b.center.X + math.cos(ang) * dist, height, b.center.Z + math.sin(ang) * dist)
	local groundY = b.bottom + (b.top - b.bottom) * 0.25
	local look = Vector3.new(
		b.center.X + math.sin(t * 0.13) * r * GAZE_WANDER,
		groundY + math.sin(t * 0.09) * (b.top - b.bottom) * 0.15,
		b.center.Z + math.cos(t * 0.11) * r * GAZE_WANDER)
	return CFrame.lookAt(pos, look) * CFrame.Angles(0, 0, math.sin(t * 0.06) * 0.006)
end

local function deathFadeUp() return playerGui:FindFirstChild("DeathFade") ~= nil end

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local wantCine = not alive() and not deathFadeUp()
	if wantCine then
		cam.CameraType = Enum.CameraType.Scriptable
		local target = cinematicCFrame(os.clock())
		if not cineOn or not lastCine then lastCine = cam.CFrame end
		lastCine = lastCine:Lerp(target, math.clamp(dt * (cineOn and 6 or 2), 0, 1))
		cam.CFrame = lastCine
		cineOn = true
		cam.FieldOfView = cam.FieldOfView + (CINE_FOV - cam.FieldOfView) * math.clamp(dt * 3, 0, 1)
	elseif cineOn then
		cineOn = false
		lastCine = nil
		cam.CameraType = Enum.CameraType.Custom
		cam.FieldOfView = 70
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
		panelMain.Position = UDim2.fromScale(0.5, 0.53)
		TweenService:Create(panelMain, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		bus:Fire("HubOpened")
		loadState()
		loadCatalog()
		if not inHub() and ui.door == "Courtyard" then ui.door = state.door ~= "Lists" and state.door or "Courtyard" end
	end
	selectTab(tab or currentTab)
end

local autoOpen = true
hide = function()
	if not open then return end
	open = false
	listening = nil
	closeModal()
	gui.Enabled = false
	autoOpen = false
	bus:Fire("HubClosed")
end

closeBtn.Activated:Connect(hide)

UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode ~= MENU_KEY or listening then return end
	if UserInputService:GetFocusedTextBox() then return end
	if open then
		if modalBack.Visible then closeModal() else hide() end
	else show() end
end)

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
hubEvent.OnClientEvent:Connect(function(what, a, b, c)
	if what == "Toast" then
		toast(a)
	elseif what == "Party" then
		state.party = a
		if a and a.queue then state.queue = state.queue or {bracket = a.bracket, ranked = a.ranked, since = os.clock() - (a.queue.waiting or 0)}
		elseif a == nil or a.queue == nil then if not state.matchFound then state.queue = nil end end
		bus:Fire("PartyChanged")
		if a and a.members then
			local ready = 0
			for _, m in ipairs(a.members) do if m.ready then ready += 1 end end
			toast(string.format("party  %d / %d   ·   %d ready", #a.members, a.max or state.partyMax, ready), COL_DIM)
		end
	elseif what == "Invite" then
		pendingInvite = b
		inviteText.Text = tostring(a) .. " invited you to their party" .. ((type(c) == "table" and c.remote) and "  ·  another server: accepting travels there" or "")
		inviteCard.Visible = true
		task.delay(30, function() if pendingInvite == b then pendingInvite = nil; inviteCard.Visible = false end end)
	elseif what == "Profile" then
		state.profile = a
		state.activeClass = a and a.active or state.activeClass
		refreshWallet()
		if open and (currentTab == "SHOP" or currentTab == "CLASSES") and not ui.rolling then task.spawn(render[currentTab]) end
	elseif what == "MatchFound" then
		state.matchFound = a
		state.queue = state.queue or {bracket = a.bracket, ranked = a.ranked, since = os.clock()}
		toast("MATCH FOUND  ·  " .. tostring(a.bracket) .. (a.ranked and "  ·  ranked" or ""), COL_GOOD)
		if open and currentTab == "PLAY" then task.spawn(render.PLAY) end
	elseif what == "Rewards" then
		showRewards(a)
	elseif what == "TravelFailed" then
		state.matchFound = nil
		state.queue = nil
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

bus.Event:Connect(function(what, tab)
	if what == "OpenHub" then show(tab) end
end)

-- in the Courtyard with no body: the menu opens by itself, over the cinematic
task.spawn(function()
	local wasAlive = false
	while true do
		task.wait(0.4)
		local a = alive()
		if a and not wasAlive then autoOpen = true end
		wasAlive = a
		if autoOpen and not a and not open and inHub() and not deathFadeUp() and not classScreenUp() then show("PLAY") end
	end
end)
