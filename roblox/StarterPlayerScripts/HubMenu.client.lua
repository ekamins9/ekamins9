--[[ HUB MENU — the main menu (M), lobby-style: your party stands on a stage
     in the middle, a big PLAY button opens the MODES board, and a dock of
     screens runs along the bottom. Opens by itself when you have no body in
     the Courtyard (over the cinematic camera); in a match M pauses (the same
     lobby: RESUME / LEAVE MATCH where PLAY was). Escape belongs to Roblox, so
     M is the menu key everywhere: M closes a pop-up, then a screen, then the menu.

       LOBBY      your party on the stage (+ invites, X removes, READY UP),
                  daily tasks, friends, the leaderboard, today's shop, the dock,
                  PLAY (the leader) / READY UP (the others) / SEARCHING
       MODES      Warfront · Training · Courtyard · The Lists 1v1 / 2v2 / 3v3 ·
                  Ranked · the server browser · custom servers
       LOADOUT    one loadout per class: armor of the class's weight, colours,
                  weapon + skin, secondary; locked pieces can be tried on
       ARMORY     WEAPONS (every weapon on a stage, its skins and where each comes
                  from) · ARMOR (every set worn by you, piece by piece, buy / equip)
       SHOP       DAILY (packs + the WEAPONS shelf, rotating) · CRATES (the drum)
                  · CROWNS (Robux bundles, Crowns › Marks) · COLORS
       TASKS      daily + weekly contracts, the task-skin track, mastery
       WARDROBE   hair, beard, face, skin, hair colour, title
       SERVERS    the browser with filters, and CREATE CUSTOM
       SETTINGS   camera feel, keybinds, attack side (ClientSettings)

     Every mannequin is a real dressed rig (Dresser) in a ViewportFrame, so what
     you see is what spawns. Talks to HubServer (HubRemote / HubEvent) and
     LoadoutServer (LoadoutRemote "Catalog", LoadoutEvent "Spawn").
     _G.MenuBus: "OpenHub", screen · "HubOpened" · "HubClosed" (class screen).
     Test hooks (set from the command bar / Studio MCP): ScreenGui attributes
     Tab, ShopTab, ArmoryTab, OpenCrowns. ]]

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
local ECON            = Catalog.ECONOMY
local CANVAS          = Vector2.new(1600, 900)   -- the layout's design size; UIScale fits it to the screen
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
local COL = {
	BACK = Theme.BACK, PANEL = Theme.PANEL, CARD = Theme.CARD, TEXT = Theme.TEXT, DIM = Theme.DIM,
	ACCENT = Theme.ACCENT, GOLD = Theme.GOLD, GO = Theme.GO, GOOD = Theme.GOOD, BAD = Theme.BAD,
	MARKS = Theme.MARKS, CROWNS = Theme.CROWNS, GLASS = Theme.GLASS, GLASS2 = Theme.GLASS2, GREEN = Theme.GREEN,
	BLUE = Theme.BLUE, RED = Theme.RED, YELLOW = Theme.YELLOW, PURPLE = Theme.PURPLE,
}
local WHITE       = Color3.new(1, 1, 1)
local TYPE_COL    = {Light = Color3.fromRGB(96, 190, 110), Medium = Color3.fromRGB(230, 180, 60), Heavy = Color3.fromRGB(230, 90, 80)}
-- what an armor weight gives and costs, in one line (Catalog ▸ Weights)
local function weightLine(weight)
	local w = Catalog.WEIGHTS[weight] or {}
	local pct = function(x) return math.floor((x or 1) * 100 + 0.5) end
	return string.format("+%d health  ·  %d%% protection on covered limbs  ·  %d%% speed, %d%% sprint  ·  %d stamina, %d%% regen  ·  dodges cost %d%%, reach %d%%",
		w.health or 0, pct(w.prot or 0), pct(w.speed), pct((w.sprint or 1.45) / 1.45), math.floor(100 * (w.stamina or 1) + 0.5), pct(w.regen), pct(w.dodgeCost), pct(w.dodgeReach))
end
local RARITY_COL  = {Mythic = Color3.fromRGB(255, 52, 78), Common = Color3.fromRGB(120, 134, 152), Rare = Color3.fromRGB(56, 140, 255), Epic = Color3.fromRGB(170, 80, 240), Legendary = Color3.fromRGB(255, 176, 40)}
local RARITY_ORDER = {Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5}

local orderN = 0
local function nextOrder() orderN += 1; return orderN end

-- the dark outline around white text (titles, buttons, numbers)
local function outline(t, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = Theme.OUTLINE
	s.Thickness = thickness or 2
	s.Transparency = transparency or 0.1
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = t
	return s
end
-- an outline around a frame / button's edge
local function border(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color or WHITE
	s.Thickness = thickness or 2
	s.Transparency = transparency or 0
	s.Parent = obj
	return s
end
-- a vertical sheen: the top keeps the colour, the bottom darkens
local function gloss(obj, amount)
	local k = 1 - (amount or 0.25)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(WHITE, Color3.new(k, k, k))
	g.Parent = obj
	return g
end
local function darker(c, k) k = k or 0.62; return Color3.new(c.R * k, c.G * k, c.B * k) end
local function hoverScale(target, watch, up)
	local sc = Instance.new("UIScale")
	sc.Parent = target
	watch.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), {Scale = up or 1.05}):Play() end)
	watch.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), {Scale = 1}):Play() end)
	return sc
end

local function label(parent, text, size, font, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = font or FONT_BODY
	t.TextSize = size or 15
	t.TextColor3 = color or COL.TEXT
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextWrapped = true
	t.Text = text or ""
	t.Parent = parent
	return t
end
-- big outlined white heading
local function title(parent, text, size, color)
	local t = label(parent, text, size or 24, FONT_BLACK, color or COL.TEXT)
	t.TextWrapped = false
	outline(t, (size or 24) >= 30 and 3 or 2)
	return t
end

local function frame(parent, color, corner)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = color or COL.CARD
	f.BorderSizePixel = 0
	f.Parent = parent
	if corner then Instance.new("UICorner", f).CornerRadius = UDim.new(0, corner) end
	return f
end
local function clearFrame(parent)
	local f = frame(parent, COL.PANEL)
	f.BackgroundTransparency = 1
	return f
end

-- a chunky glossy button with outlined white text (keeps the old signature:
-- callers size it, colour it, and read .Activated)
local function button(parent, text, size, color)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = color or COL.GLASS2
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = FONT_BLACK
	b.TextSize = size or 15
	b.TextColor3 = COL.TEXT
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	gloss(b, 0.2)
	if text ~= "" then outline(b, 1.6, 0.2) end
	return b
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
	s.ScrollBarThickness = 5
	s.ScrollBarImageColor3 = COL.DIM
	s.ScrollBarImageTransparency = 0.4
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

-- a titled dark-glass panel; `quiet` = a lighter inner one. Returns the panel (a list).
local function panel(parent, heading, quiet)
	local p = frame(parent, quiet and COL.GLASS2 or COL.GLASS, 14)
	p.BackgroundTransparency = quiet and 0.2 or 0.12
	border(p, WHITE, 1.5, 0.88)
	p.AutomaticSize = Enum.AutomaticSize.Y
	p.Size = UDim2.new(1, 0, 0, 0)
	p.LayoutOrder = nextOrder()
	padding(p, 14, 14, 12, 14)
	vlist(p, 6)
	if heading then
		local h = title(p, string.upper(heading), 15)
		h.Size = UDim2.new(1, 0, 0, 20)
		h.TextTruncate = Enum.TextTruncate.AtEnd
		h.LayoutOrder = 0
	end
	return p
end
local function heading(parent, text)
	local h = title(parent, string.upper(text), 13, COL.DIM)
	h.Size = UDim2.new(1, 0, 0, 22)
	h.LayoutOrder = nextOrder()
	h.TextYAlignment = Enum.TextYAlignment.Bottom
	return h
end
local function dim(parent, text, size)
	local t = label(parent, text, size or 13, FONT_BODY, COL.DIM)
	t.AutomaticSize = Enum.AutomaticSize.Y
	t.Size = UDim2.new(1, 0, 0, 0)
	t.LayoutOrder = nextOrder()
	return t
end
-- a selectable row: text left, something right
local function row(parent, text, right, on, onClick, rightColor)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 34)
	b.LayoutOrder = nextOrder()
	b.BackgroundColor3 = on and COL.BLUE or COL.GLASS2
	b.BackgroundTransparency = on and 0 or 0.1
	b.BorderSizePixel = 0
	b.AutoButtonColor = onClick ~= nil
	b.Text = ""
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	padding(b, 12, 12, 0, 0)
	local t = label(b, text, 14, FONT, COL.TEXT)
	t.Size = UDim2.new(0.62, 0, 1, 0)
	t.TextWrapped = false
	t.TextTruncate = Enum.TextTruncate.AtEnd
	if on then outline(t, 1.2, 0.3) end
	if right and right ~= "" then
		local r = label(b, right, 12, FONT, on and COL.TEXT or (rightColor or COL.DIM))
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
local function swatches(parent, items, isOn, isLocked, onClick, cell)
	local holder = clearFrame(parent)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Size = UDim2.new(1, 0, 0, 0)
	holder.LayoutOrder = nextOrder()
	local g = Instance.new("UIGridLayout", holder)
	g.CellSize = UDim2.fromOffset(cell or 32, cell or 32)
	g.CellPadding = UDim2.fromOffset(6, 6)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	for i, it in ipairs(items) do
		local b = Instance.new("TextButton")
		b.LayoutOrder = i
		b.BackgroundColor3 = it.color
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Text = isLocked(it) and "🔒" or ""
		b.TextSize = 12
		b.TextColor3 = COL.TEXT
		b.Parent = holder
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
		border(b, WHITE, 3, isOn(it) and 0 or 1)
		b.Activated:Connect(function() onClick(it) end)
	end
	return holder
end
local function chips(parent, items, isOn, onClick, height)
	local holder = clearFrame(parent)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Size = UDim2.new(1, 0, 0, 0)
	holder.LayoutOrder = nextOrder()
	local l = hlist(holder, 6)
	l.Wraps = true
	for i, it in ipairs(items) do
		local on = isOn(it)
		local b = button(holder, it.text, 13, on and COL.BLUE or COL.GLASS2)
		b.LayoutOrder = i
		b.AutomaticSize = Enum.AutomaticSize.X
		b.Size = UDim2.fromOffset(0, height or 30)
		if not on then b.TextColor3 = COL.DIM end
		padding(b, 12, 12, 0, 0)
		b.Activated:Connect(function() onClick(it) end)
	end
	return holder
end
local function bigBtn(parent, text, color, onClick)
	local b = button(parent, text, 16, color or COL.GLASS2)
	b.Size = UDim2.new(1, 0, 0, 42)
	b.LayoutOrder = nextOrder()
	if onClick then b.Activated:Connect(onClick) end
	return b
end

-- the chunky game button: a glossy face on a darker lip, big outlined text.
-- Returns the holder (size / position it) and the face (click it).
local function fatButton(parent, text, color, textSize)
	local holder = frame(parent, darker(color), 14)
	holder.Size = UDim2.fromOffset(240, 64)
	local b = Instance.new("TextButton")
	b.Name = "Face"
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Size = UDim2.new(1, 0, 1, -6)
	b.Font = FONT_BLACK
	b.TextSize = textSize or 26
	b.TextColor3 = COL.TEXT
	b.Text = text
	b.Parent = holder
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 14)
	gloss(b, 0.22)
	outline(b, textSize and textSize >= 34 and 3 or 2.2)
	hoverScale(holder, b, 1.04)
	b.MouseButton1Down:Connect(function() b.Position = UDim2.fromOffset(0, 4) end)
	b.MouseButton1Up:Connect(function() b.Position = UDim2.fromOffset(0, 0) end)
	b.MouseLeave:Connect(function() b.Position = UDim2.fromOffset(0, 0) end)
	return holder, b
end
local function paintFat(holder, face, text, color)
	if text then face.Text = text end
	if color then face.BackgroundColor3 = color; holder.BackgroundColor3 = darker(color) end
end
-- the red square X that closes a screen
local function closeX(parent, onClick)
	local holder, b = fatButton(parent, "X", COL.RED, 30)
	holder.Size = UDim2.fromOffset(64, 60)
	if onClick then b.Activated:Connect(onClick) end
	return holder, b
end
-- a progress bar (0..1) with optional text over it
local function progressBar(parent, frac, color, text, height)
	local track = frame(parent, Color3.fromRGB(6, 8, 16), 7)
	track.BackgroundTransparency = 0.2
	track.Size = UDim2.new(1, 0, 0, height or 14)
	track.LayoutOrder = nextOrder()
	local fill = frame(track, color or COL.BLUE, 7)
	fill.Size = UDim2.new(math.clamp(frac or 0, 0, 1), 0, 1, 0)
	fill.Visible = (frac or 0) > 0.001
	gloss(fill, 0.3)
	if text then
		local t = label(track, text, math.max(10, (height or 14) - 3), FONT_BLACK, COL.TEXT)
		t.Size = UDim2.fromScale(1, 1); t.TextXAlignment = Enum.TextXAlignment.Center; t.TextWrapped = false
		outline(t, 1.5)
	end
	return track, fill
end
local function rarityTag(parent, rarity)
	local t = label(parent, string.upper(rarity or "Common"), 11, FONT_BLACK, COL.TEXT)
	t.BackgroundTransparency = 0
	t.BackgroundColor3 = RARITY_COL[rarity] or COL.DIM
	t.TextXAlignment = Enum.TextXAlignment.Center
	t.TextWrapped = false
	t.Size = UDim2.fromOffset(84, 20)
	Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
	outline(t, 1.2, 0.3)
	return t
end

-- icons: Decals in ReplicatedStorage ▸ Cosmetics ▸ Icons (Crowns, Marks, Loadout,
-- Armory, Shop, Tasks, Wardrobe, Settings), made by blender/icons.py + ui_icons.py
local function iconTexture(key)
	local cos = ReplicatedStorage:FindFirstChild("Cosmetics")
	local f = cos and cos:FindFirstChild("Icons")
	local d = f and f:FindFirstChild(key)
	return (d and d:IsA("Decal")) and d.Texture or ""
end
local function iconImage(parent, key, px)
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromOffset(px or 24, px or 24)
	img.ScaleType = Enum.ScaleType.Fit
	img.Image = iconTexture(key)
	img.Parent = parent
	if img.Image == "" then   -- Cosmetics may replicate after the menu is built
		task.spawn(function()
			for _ = 1, 30 do
				task.wait(0.5)
				if not img.Parent then return end
				img.Image = iconTexture(key)
				if img.Image ~= "" then return end
			end
		end)
	end
	return img
end
-- a face texture (Cosmetics ▸ Body ▸ Face ▸ <id>)
local function faceTexture(id)
	local d = Catalog.bodyModel("Face", id)
	if d and d:IsA("Decal") then return d.Texture end
	for _, f in ipairs(Catalog.BODY.faces) do if f.id == id and f.texture then return f.texture end end
	return ""
end

-- a dock button: a big 3D icon popping out of a dark tile, its name under it
local function dockTile(parent, iconKey, text)
	local b = Instance.new("TextButton")
	b.Text = ""
	b.AutoButtonColor = false
	b.Size = UDim2.fromOffset(112, 112)
	b.BackgroundColor3 = COL.GLASS
	b.BackgroundTransparency = 0.15
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 18)
	local st = border(b, WHITE, 2, 0.84)
	local img = iconImage(b, iconKey, 96)
	img.AnchorPoint = Vector2.new(0.5, 0); img.Position = UDim2.new(0.5, 0, 0, -26)
	local t = title(b, text, 17)
	t.AnchorPoint = Vector2.new(0.5, 1); t.Position = UDim2.new(0.5, 0, 1, -8); t.Size = UDim2.new(1, 0, 0, 20)
	t.TextXAlignment = Enum.TextXAlignment.Center
	local badge = label(b, "", 14, FONT_BLACK, COL.TEXT)
	badge.Name = "Badge"; badge.BackgroundTransparency = 0; badge.BackgroundColor3 = COL.RED
	badge.AnchorPoint = Vector2.new(1, 0); badge.Position = UDim2.new(1, 8, 0, -8)
	badge.AutomaticSize = Enum.AutomaticSize.X; badge.Size = UDim2.fromOffset(28, 28)
	badge.TextXAlignment = Enum.TextXAlignment.Center; badge.TextWrapped = false; badge.Visible = false; badge.ZIndex = 3
	padding(badge, 7, 7, 0, 0)
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
	outline(badge, 1.5)
	hoverScale(b, b, 1.08)
	b.MouseEnter:Connect(function() st.Transparency = 0.3 end)
	b.MouseLeave:Connect(function() st.Transparency = 0.84 end)
	return b, badge
end
-- a currency pill: icon, amount, optional green +
local function currencyPill(parent, iconKey, withPlus)
	local p = frame(parent, COL.GLASS, 23)
	p.BackgroundTransparency = 0.12
	p.AutomaticSize = Enum.AutomaticSize.X
	p.Size = UDim2.fromOffset(0, 46)
	border(p, WHITE, 1.5, 0.85)
	padding(p, 4, withPlus and 5 or 18, 0, 0)
	local l = hlist(p, 6); l.VerticalAlignment = Enum.VerticalAlignment.Center
	local img = iconImage(p, iconKey, 44); img.LayoutOrder = 1
	local t = title(p, "0", 22)
	t.AutomaticSize = Enum.AutomaticSize.X; t.Size = UDim2.fromOffset(0, 46); t.LayoutOrder = 2
	local plus
	if withPlus then
		plus = button(p, "+", 26, COL.GREEN); plus.Size = UDim2.fromOffset(36, 36); plus.LayoutOrder = 3
		plus:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
	end
	return p, t, plus
end

--------------------------------------------------------------------
--  TOASTS, INVITE CARD, REWARDS CARD (always-on ScreenGui)
--------------------------------------------------------------------
local inviteCard, inviteText, acceptBtn, ignoreBtn, hint, toast, showRewards
do
	local toastGui = Instance.new("ScreenGui")
	toastGui.Name = "HubToasts"
	toastGui.ResetOnSpawn = false
	toastGui.IgnoreGuiInset = true
	toastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	toastGui.DisplayOrder = 2200
	toastGui.Parent = playerGui

	local toastStack = clearFrame(toastGui)
	toastStack.AnchorPoint = Vector2.new(0.5, 0)
	toastStack.Position = UDim2.new(0.5, 0, 0, 86)
	toastStack.Size = UDim2.fromOffset(620, 220)
	local tl = vlist(toastStack, 6)
	tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tl.VerticalAlignment = Enum.VerticalAlignment.Top

	toast = function(text, color)
		if not text or text == "" then return end
		local r = frame(toastStack, COL.GLASS, 19)
		r.BackgroundTransparency = 0.08
		r.AutomaticSize = Enum.AutomaticSize.X
		r.Size = UDim2.fromOffset(0, 38)
		r.LayoutOrder = nextOrder()
		padding(r, 18, 18, 0, 0)
		local s = border(r, color or COL.ACCENT, 2, 0.2)
		local t = title(r, text, 16, color == COL.BAD and Color3.fromRGB(255, 150, 160) or COL.TEXT)
		t.AutomaticSize = Enum.AutomaticSize.X
		t.Size = UDim2.new(0, 0, 1, 0)
		local sc = Instance.new("UIScale", r); sc.Scale = 0.85
		TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Scale = 1}):Play()
		task.delay(3.5, function()
			if not r.Parent then return end
			TweenService:Create(r, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
			TweenService:Create(t, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
			TweenService:Create(s, TweenInfo.new(0.4), {Transparency = 1}):Play()
			local o = t:FindFirstChildOfClass("UIStroke"); if o then TweenService:Create(o, TweenInfo.new(0.4), {Transparency = 1}):Play() end
			task.delay(0.45, function() if r.Parent then r:Destroy() end end)
		end)
	end

	inviteCard = frame(toastGui, COL.GLASS, 14)
	inviteCard.AnchorPoint = Vector2.new(1, 1)
	inviteCard.Position = UDim2.new(1, -24, 1, -150)
	inviteCard.Size = UDim2.fromOffset(340, 104)
	inviteCard.Visible = false
	border(inviteCard, COL.GREEN, 2, 0.2)
	padding(inviteCard, 14, 14, 12, 12)
	inviteText = title(inviteCard, "", 16)
	inviteText.TextWrapped = true
	inviteText.Size = UDim2.new(1, 0, 0, 40)
	acceptBtn = button(inviteCard, "ACCEPT", 16, COL.GREEN)
	acceptBtn.Position = UDim2.new(0, 0, 1, -36)
	acceptBtn.Size = UDim2.new(0.5, -5, 0, 36)
	ignoreBtn = button(inviteCard, "IGNORE", 16, COL.GLASS2)
	ignoreBtn.Position = UDim2.new(0.5, 5, 1, -36)
	ignoreBtn.Size = UDim2.new(0.5, -5, 0, 36)

	-- end-of-round pay card
	local rewardCard = frame(toastGui, COL.GLASS, 16)
	rewardCard.AnchorPoint = Vector2.new(0.5, 0)
	rewardCard.Position = UDim2.new(0.5, 0, 0, 130)
	rewardCard.Size = UDim2.fromOffset(460, 110)
	rewardCard.Visible = false
	border(rewardCard, COL.GOLD, 2.5, 0.1)
	padding(rewardCard, 18, 18, 12, 12)
	local rewardTitle = title(rewardCard, "", 24, COL.GOLD); rewardTitle.Size = UDim2.new(1, 0, 0, 30); rewardTitle.TextXAlignment = Enum.TextXAlignment.Center
	local rewardBody = title(rewardCard, "", 15); rewardBody.Position = UDim2.new(0, 0, 0, 34); rewardBody.Size = UDim2.new(1, 0, 0, 52); rewardBody.TextXAlignment = Enum.TextXAlignment.Center; rewardBody.TextWrapped = true
	showRewards = function(r)
		-- in a match the scoreboard shows the pay under the result, beside the vote
		if roundNode:GetAttribute("State") == "Intermission" and roundNode:GetAttribute("Mode") ~= "Hub" then return end
		if r.blocked then
			rewardTitle.Text = "ROUND OVER"; rewardBody.Text = "No rewards on a cheat server."
		else
			rewardTitle.Text = (r.won and "VICTORY" or "ROUND OVER") .. (r.firstWin and "  ·  FIRST WIN OF THE DAY" or "")
			local bits = {string.format("+%s Marks", fmt(r.marks or 0)), string.format("+%s XP", fmt(r.xp or 0))}
			if (r.levels or 0) > 0 then table.insert(bits, "LEVEL " .. tostring(r.level) .. "!") end
			if r.delta then table.insert(bits, string.format("rating %s%d › %s", r.delta >= 0 and "+" or "", r.delta, fmt(r.rating))) end
			rewardBody.Text = table.concat(bits, "   ·   ") .. string.format("\n%d kills  ·  %d parries", r.kills or 0, r.parries or 0)
		end
		rewardCard.Visible = true
		local sc = rewardCard:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", rewardCard)
		sc.Scale = 0.7
		TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
		task.delay(8, function() rewardCard.Visible = false end)
	end

	hint = title(toastGui, "M  ·  MENU", 15, COL.DIM)
	hint.AnchorPoint = Vector2.new(0, 1)
	hint.Position = UDim2.new(0, 24, 1, -24)
	hint.Size = UDim2.fromOffset(200, 20)
	hint.Visible = false
end

--------------------------------------------------------------------
--  MENU SHELL: the lobby layer, the screen layer (header + content), the
--  top bar (you, the wallet, close) and the pop-up. Everything sits on a
--  CANVAS-sized root that a UIScale fits to the screen, so the layout is
--  designed once in pixels and reads the same on any monitor.
--------------------------------------------------------------------
local gui, root, lobbyShade, lobby, screenLayer, sIcon, sTitle, sSub, content, profileChip, lvlBadge, xpText, whereText, modalBack, modalBox, fitRoot, closeModal, modal, setBlur, sClose, xpFill, crownsText, crownsPlus, marksText, topCloseHolder, topClose
do
	gui = Instance.new("ScreenGui")
	gui.Name = "HubMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2050
	gui.Enabled = false
	gui.Parent = playerGui

	root = clearFrame(gui)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(CANVAS.X, CANVAS.Y)
	local rootScale = Instance.new("UIScale", root)
	local applyInset   -- (below) keeps the top-left clear of Roblox's own buttons
	fitRoot = function()
		local abs = gui.AbsoluteSize
		if abs.X < 2 or abs.Y < 2 then return end
		local s = math.clamp(math.min(abs.X / CANVAS.X, abs.Y / CANVAS.Y), 0.45, 2.2)
		rootScale.Scale = s
		root.Size = UDim2.fromOffset(abs.X / s, abs.Y / s)
		if applyInset then applyInset(s) end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitRoot)
	task.defer(fitRoot)

	-- the lobby shade: dark at the top and bottom edges so the cards read over the
	-- 3D world, clear in the middle where your party stands. Active: it swallows
	-- clicks so nothing reaches the world behind the menu.
	lobbyShade = frame(root, COL.BACK)
	lobbyShade.Size = UDim2.fromScale(1, 1)
	lobbyShade.Active = true
	do
		local g = Instance.new("UIGradient", lobbyShade)
		g.Rotation = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.2, 0.78), NumberSequenceKeypoint.new(0.62, 0.8),
			NumberSequenceKeypoint.new(1, 0.2)})
	end
	lobby = clearFrame(root)
	lobby.Size = UDim2.fromScale(1, 1)

	-- a screen: dark glass over everything, an icon + title + subtitle header,
	-- the red X back to the lobby, and the content host the screens live in
	screenLayer = frame(root, COL.BACK)
	screenLayer.Size = UDim2.fromScale(1, 1)
	screenLayer.BackgroundTransparency = 0.12
	screenLayer.Visible = false
	screenLayer.Active = true
	do
		local g = Instance.new("UIGradient", screenLayer)
		g.Rotation = 90
		g.Color = ColorSequence.new(Color3.fromRGB(26, 34, 60), Color3.fromRGB(8, 10, 20))
	end
	local sHeader = clearFrame(screenLayer)
	sHeader.Position = UDim2.fromOffset(28, 16)
	sHeader.Size = UDim2.new(1, -56, 0, 76)
	sIcon = iconImage(sHeader, "Shop", 78)
	sIcon.Position = UDim2.fromOffset(-8, -6)
	sTitle = title(sHeader, "", 42)
	sTitle.Position = UDim2.fromOffset(78, 2)
	sTitle.Size = UDim2.new(0.38, 0, 0, 46)
	sSub = title(sHeader, "", 15, COL.DIM)
	sSub.Position = UDim2.fromOffset(80, 48)
	sSub.Size = UDim2.new(0.38, 0, 0, 20)
	sSub.TextTruncate = Enum.TextTruncate.AtEnd
	local sCloseHolder; sCloseHolder, sClose = closeX(sHeader)
	sCloseHolder.AnchorPoint = Vector2.new(1, 0)
	sCloseHolder.Position = UDim2.new(1, 0, 0, 4)
	content = clearFrame(screenLayer)
	content.Position = UDim2.fromOffset(28, 108)
	content.Size = UDim2.new(1, -56, 1, -130)

	-- the top bar, over both layers: you (lobby only) · the wallet · close
	local topBar = clearFrame(root)
	topBar.Size = UDim2.new(1, 0, 0, 92)
	profileChip = frame(topBar, COL.GLASS, 18)
	profileChip.BackgroundTransparency = 0.12
	profileChip.Position = UDim2.fromOffset(24, 18)
	profileChip.Size = UDim2.fromOffset(340, 68)
	border(profileChip, WHITE, 1.5, 0.85)
	local avatar = Instance.new("ImageLabel")
	avatar.BackgroundColor3 = COL.GLASS2
	avatar.Position = UDim2.fromOffset(6, 6)
	avatar.Size = UDim2.fromOffset(56, 56)
	avatar.Parent = profileChip
	Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 14)
	task.spawn(function()
		local ok, img = pcall(Players.GetUserThumbnailAsync, Players, player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		if ok then avatar.Image = img end
	end)
	local pName = title(profileChip, player.DisplayName, 20)
	pName.Position = UDim2.fromOffset(72, 6)
	pName.Size = UDim2.new(1, -82, 0, 26)
	pName.TextTruncate = Enum.TextTruncate.AtEnd
	lvlBadge = title(profileChip, "LVL 1", 14)
	lvlBadge.BackgroundTransparency = 0
	lvlBadge.BackgroundColor3 = COL.BLUE
	lvlBadge.Position = UDim2.fromOffset(72, 38)
	lvlBadge.Size = UDim2.fromOffset(70, 22)
	lvlBadge.TextXAlignment = Enum.TextXAlignment.Center
	Instance.new("UICorner", lvlBadge).CornerRadius = UDim.new(0, 7)
	local xpHolder = clearFrame(profileChip)
	xpHolder.Position = UDim2.fromOffset(150, 40)
	xpHolder.Size = UDim2.new(1, -162, 0, 18)
	local xpTrack; xpTrack, xpFill = progressBar(xpHolder, 0, COL.BLUE, "", 18)
	xpText = xpTrack:FindFirstChildOfClass("TextLabel")

	local wallet = clearFrame(topBar)
	wallet.AnchorPoint = Vector2.new(0.5, 0)
	wallet.Position = UDim2.new(0.5, 0, 0, 20)
	wallet.AutomaticSize = Enum.AutomaticSize.X
	wallet.Size = UDim2.fromOffset(0, 46)
	do local l = hlist(wallet, 14); l.VerticalAlignment = Enum.VerticalAlignment.Center end
	local crownsPill; crownsPill, crownsText, crownsPlus = currencyPill(wallet, "Crowns", true)
	crownsPill.LayoutOrder = 1
	local marksPill; marksPill, marksText = currencyPill(wallet, "Marks", false)
	marksPill.LayoutOrder = 2

	topCloseHolder, topClose = closeX(topBar)
	topCloseHolder.AnchorPoint = Vector2.new(1, 0)
	topCloseHolder.Position = UDim2.new(1, -24, 0, 20)
	whereText = title(topBar, "", 15, COL.DIM)
	whereText.AnchorPoint = Vector2.new(1, 0)
	whereText.Position = UDim2.new(1, -100, 0, 38)
	whereText.Size = UDim2.fromOffset(420, 22)
	whereText.TextXAlignment = Enum.TextXAlignment.Right
	whereText.TextTruncate = Enum.TextTruncate.AtEnd

	-- the pop-up (buy / confirm / previews)
	modalBack = frame(root, COL.BACK)
	modalBack.Size = UDim2.fromScale(1, 1)
	modalBack.BackgroundTransparency = 0.35
	modalBack.Visible = false
	modalBack.Active = true
	modalBack.ZIndex = 50
	local modalCatch = Instance.new("TextButton")
	modalCatch.BackgroundTransparency = 1; modalCatch.Text = ""; modalCatch.Size = UDim2.fromScale(1, 1); modalCatch.ZIndex = 50; modalCatch.Parent = modalBack
	modalBox = frame(modalBack, COL.GLASS, 18)
	modalBox.AnchorPoint = Vector2.new(0.5, 0.5)
	modalBox.Position = UDim2.fromScale(0.5, 0.5)
	modalBox.Size = UDim2.fromOffset(460, 0)
	modalBox.AutomaticSize = Enum.AutomaticSize.Y
	modalBox.ZIndex = 51
	modalBox.BackgroundTransparency = 0.04
	border(modalBox, WHITE, 2, 0.75)
	padding(modalBox, 22, 22, 18, 18)
	vlist(modalBox, 10)
	local modalScale = Instance.new("UIScale", modalBox)
	closeModal = function() modalBack.Visible = false; clear(modalBox) end
	modalCatch.Activated:Connect(closeModal)
	-- modal(title, bodyText, buttons = {{text, color, fn}}, extra = function(box) end, width)
	modal = function(mtitle, body, buttons, extra, width)
		clear(modalBox)
		modalBox.Size = UDim2.fromOffset(width or 460, 0)
		local t = title(modalBox, mtitle, 24); t.Size = UDim2.new(1, 0, 0, 30); t.LayoutOrder = 1; t.TextTruncate = Enum.TextTruncate.AtEnd
		if body and body ~= "" then local d = dim(modalBox, body, 14); d.LayoutOrder = 2 end
		if extra then extra(modalBox) end
		for i, b in ipairs(buttons or {}) do
			if b then
				local btn = bigBtn(modalBox, b[1], b[2], function() if b[3] then b[3]() end end)
				btn.Size = UDim2.new(1, 0, 0, 46)
				btn.LayoutOrder = 100 + i
			end
		end
		local c = bigBtn(modalBox, "CLOSE", COL.GLASS2, closeModal); c.LayoutOrder = 200
		modalBack.Visible = true
		modalScale.Scale = 0.9
		TweenService:Create(modalScale, TweenInfo.new(0.16, Enum.EasingStyle.Back), {Scale = 1}):Play()
	end

	-- Roblox draws its own buttons (menu, chat) across the top of the screen: the
	-- top bar, the screen header and the lobby all start below that strip
	applyInset = function(sc)
		local ok, inset = pcall(function() return game:GetService("GuiService"):GetGuiInset() end)
		local y = (ok and inset and inset.Y or 0) / math.max(sc or rootScale.Scale, 0.01)
		topBar.Position = UDim2.fromOffset(0, y)
		sHeader.Position = UDim2.fromOffset(28, 16 + y)
		content.Position = UDim2.fromOffset(28, 108 + y)
		content:SetAttribute("HomeY", 108 + y)
		content.Size = UDim2.new(1, -56, 1, -130 - y)
		lobby.Position = UDim2.fromOffset(0, y)
		lobby.Size = UDim2.new(1, 0, 1, -y)
	end
	applyInset()

	-- the world behind a screen blurs
	local blur = Instance.new("BlurEffect")
	blur.Name = "MenuBlur"
	blur.Size = 0
	blur.Enabled = false
	blur.Parent = game:GetService("Lighting")
	setBlur = function(size)
		if size > 0 then blur.Enabled = true end
		TweenService:Create(blur, TweenInfo.new(0.25), {Size = size}):Play()
		if size == 0 then task.delay(0.3, function() if blur.Size < 0.5 then blur.Enabled = false end end) end
	end
end

--------------------------------------------------------------------
--  STATE
--------------------------------------------------------------------
local state = {studio = false, reserved = false, access = "Public", name = "", custom = false, door = "Courtyard", mode = "Hub",
	bracket = nil, ranked = false, isHost = false, noRewards = false, party = nil, partyMax = GameConfig.PARTY_MAX or 3,
	profile = nil, contracts = {}, servers = {}, friends = {}, catalog = nil, activeClass = GameConfig.DEFAULT_CLASS,
	queue = nil, matchFound = nil, boards = {}, serversAt = 0, store = nil}
local ui = {bracket = "1v1", ranked = false, lbTab = "Warfront", editing = GameConfig.DEFAULT_CLASS,
	classEdit = {}, dirty = {}, team = nil, appDraft = nil, appDirty = false, helmPreview = false, tryOn = nil,
	shopTab = "daily", crate = nil, crateItem = nil, rolling = false, pulls = {},
	armoryTab = "weapons", shopWeapon = "Longsword", shopSkin = nil, armorSet = nil, armorSlots = {helmet = true, top = true, bottom = true},
	ownedOnly = true,   -- the Armory shows what you have; the filter off shows everything you can get
	filters = {hideEmpty = true, hideFull = false, customOnly = false, door = nil},
	customOpen = false, custom = nil, facing = 0, zoom = 1, shopSeen = nil}
do for k in pairs(Catalog.CRATES) do if not ui.crate or k < ui.crate then ui.crate = k end end end
ui.custom = {}
for k, v in pairs(GameConfig.CUSTOM_DEFAULTS) do ui.custom[k] = v end
ui.custom.name = ""
-- the drops, finishes and time helpers (one table: the main chunk is at Luau's 200-local limit)
local HX = {Drops = require(ReplicatedStorage:WaitForChild("Drops")),
	VARIANT_COL = {Masterwork = Color3.fromRGB(255, 214, 110), Radiant = Color3.fromRGB(150, 230, 255), Golden = Color3.fromRGB(255, 200, 60), Spectral = Color3.fromRGB(150, 235, 255)}}
-- "2d 4h" / "3h 12m" / "12m"
function HX.span(sec)
	sec = math.max(0, sec or 0)
	local d, h, m = math.floor(sec / 86400), math.floor(sec % 86400 / 3600), math.floor(sec % 3600 / 60)
	if d > 0 then return string.format("%dd %dh", d, h) end
	if h > 0 then return string.format("%dh %02dm", h, m) end
	return string.format("%dm", m)
end
-- a percentage the way the odds rules want it: exact, two places when small
function HX.pct(x)
	if x >= 10 or x == math.floor(x) then return string.format("%g%%", math.floor(x * 100 + 0.5) / 100) end
	return string.format("%.2f%%", x)
end
-- your copies of a skin / companion ("pet:" .. id), and the one that shows
function HX.copies(key)
	local p = state.profile
	return p and p.copies and p.copies[key] or {}
end
HX.RANK = {Masterwork = 1, Radiant = 2, Golden = 1, Spectral = 2}
HX.FX = require(ReplicatedStorage:WaitForChild("UIFX"))   -- menu sounds, flashes, banners (ReplicatedStorage ▸ UIFX)
-- the moment a pull lands: a beat of suspense, then flash + banner + sting (+ shake when it's big)
function HX.revealMoment(anchor, rarity, variant, dup)
	local FX = HX.FX
	local col = RARITY_COL[rarity] or Color3.new(1, 1, 1)
	local big = FX.BIG[rarity] == true
	if big then
		-- the big ones hold their breath a moment longer, with a first low flash
		FX.flash(anchor, col, 0.25, 0.35)
		task.wait(0.45)
	end
	FX.flash(anchor, col, big and 0.75 or 0.45, big and 0.9 or 0.5)
	FX.banner(anchor, string.upper(rarity) .. "!", col, big)
	FX.reveal(rarity)
	if variant then task.delay(0.35, function() FX.banner(anchor, string.upper(variant) .. " FINISH", HX.VARIANT_COL[variant] or col, false) end) end
	if dup then task.delay(0.25, function() FX.play("Coins") end) end
	if big then FX.shake(anchor:FindFirstAncestorOfClass("ScreenGui") and anchor:FindFirstAncestorOfClass("ScreenGui"):FindFirstChildWhichIsA("Frame") or anchor, 10, 0.5) end
	task.wait(big and 1.1 or 0.55)
end
function HX.best(key)
	local RANK = HX.RANK
	local best
	for _, c in ipairs(HX.copies(key)) do
		local rb, rc = best and (RANK[best.v] or 0) or -1, RANK[c.v] or 0
		if not best or rc > rb or (rc == rb and (c.n or math.huge) < (best.n or math.huge)) then best = c end
	end
	return best
end

local open = false
local listening = nil
local currentTab = "PLAY"   -- "PLAY" is the lobby; the rest are screens

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
	if kind == "skins" then local s = Catalog.SKIN[id]; if s and s.unlock and Catalog.unlocked(s.unlock, p) then return true end end
	if kind == "killfx" then local f = Catalog.KILLFX_BY[id]; if f and (f.free or (f.unlock and Catalog.unlocked(f.unlock, p))) then return true end end
	if kind == "emotes" then local e = Catalog.EMOTE[id]; if e and (e.free or (e.unlock and Catalog.unlocked(e.unlock, p))) then return true end end
	if kind == "weapons" then local w = Catalog.WEAPON[id]; if w and Catalog.unlocked(w.unlock, p) then return true end end
	if kind == "colors" then local c = Catalog.COLOR[id]; if c and not c.crowns then return true end end
	if kind == "hairColors" then for _, h in ipairs(Catalog.BODY.hairColors) do if h.name == id and not h.crowns then return true end end end
	if kind == "beards" then for _, b in ipairs(Catalog.BODY.beards) do if b.id == id and not b.crowns then return true end end end
	if kind == "titles" then
		for _, t in ipairs(Catalog.BODY.titles) do if t == id then return true end end
		for _, t in ipairs(Catalog.BODY.earnedTitles or {}) do if t.title == id and Catalog.unlocked(t.unlock, p) then return true end end
	end
	if kind == "skins" and #HX.copies(id) > 0 then return true end
	if kind == "companions" and #HX.copies("pet:" .. tostring(id)) > 0 then return true end
	return p ~= nil and p.owned ~= nil and p.owned[kind] ~= nil and p.owned[kind][id] == true
end
local function unlockText(w) return Catalog.unlockText(w.unlock) end
-- "37 / 100" for an unlock, or "" when it has no counter
local function progressText(u)
	local have, need = Catalog.unlockProgress(u, state.profile)
	return need and string.format("%s / %s", fmt(math.min(have, need)), fmt(need)) or ""
end
local function progressFrac(u)
	local have, need = Catalog.unlockProgress(u, state.profile)
	return need and math.clamp(have / math.max(need, 1), 0, 1) or 1
end
local function rankOf(r)
	local tiers = ECON.rankTiers or {"Peasant", "Levy", "Squire", "Knight", "Banneret", "Champion"}
	local step = ECON.rankStep or 250
	local i = math.clamp(math.floor((r - 1000) / step), 0, #tiers - 1) + 1
	local within = ((r - 1000) % step) / step
	local sub = within < 0.34 and "III" or (within < 0.67 and "II" or "I")
	return tiers[i] .. " " .. sub, tiers[i], i
end
local function rating(bracket)
	return state.profile and state.profile.rating and state.profile.rating[bracket] or ECON.ratingStart or 1500
end
local function classLoadout(id)
	local c = state.catalog and state.catalog.classes and state.catalog.classes[id]
	return c and c.loadout or (state.profile and state.profile.classes and state.profile.classes[id]) or {}
end
local function weightOf(classId) local c = GameConfig.CLASSES[classId]; return c and c.weight or "Light" end
local function className(classId) local c = GameConfig.CLASSES[classId]; return c and c.name or classId end

-- the day the server sells (its store info); skins and packs on sale that day
local function storeDay() return state.store and state.store.day or nil end
local function skinOnSale(id)
	local s = Catalog.SKIN[id]
	if not s then return false end
	local src = Catalog.skinSource(s)
	if src == "pack" then return Catalog.onSale(s.pack, storeDay()) end
	if src == "shop" then
		for _, o in ipairs(state.store and state.store.skins or {}) do if o == id then return true end end
	end
	return false
end
-- "13h 22m" until the store turns (server clock)
local function storeCountdown()
	local st = state.store
	if not (st and st.endsAt and st.serverTime) then return "" end
	local left = math.max(0, st.endsAt - (st.serverTime + (os.clock() - (st.at or 0))))
	local h, m = math.floor(left / 3600), math.floor(left % 3600 / 60)
	return h > 0 and string.format("%dh %02dm", h, m) or string.format("%dm", m)
end

local function xpNeeded(level)
	local L = ECON.levels or {}
	return L[level + 1] or L[#L] or 1000
end
local function refreshWallet()
	local p = state.profile
	marksText.Text = fmt(p and p.wallet and p.wallet.marks or 0)
	crownsText.Text = fmt(p and p.wallet and p.wallet.crowns or 0)
	local lvl = p and p.level or 1
	lvlBadge.Text = "LVL " .. tostring(lvl)
	local need = xpNeeded(lvl)
	local have = p and p.xp or 0
	xpFill.Size = UDim2.new(math.clamp(have / math.max(need, 1), 0, 1), 0, 1, 0)
	xpFill.Visible = have > 0
	if xpText then xpText.Text = string.format("%s / %s XP", fmt(have), fmt(need)) end
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
		for _, k in ipairs({"studio", "reserved", "access", "name", "custom", "door", "mode", "bracket", "ranked", "isHost", "noRewards", "party", "partyMax", "profile", "contracts", "settings", "store", "pass", "login", "gifts", "hatchery"}) do state[k] = r[k] end
		if state.store then state.store.at = os.clock() end
		state.activeClass = r.profile and r.profile.active or state.activeClass
		if r.party and r.party.queue then state.queue = {bracket = r.party.bracket, ranked = r.party.ranked, waiting = r.party.queue.waiting, window = r.party.queue.window, since = os.clock() - (r.party.queue.waiting or 0)}
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
local PreviewRig = require(ReplicatedStorage:WaitForChild("PreviewRig"))
local makeRig, settle, poseRig, dressedRig = PreviewRig.makeRig, PreviewRig.settle, PreviewRig.poseRig, PreviewRig.dressedRig

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
	return (nx * 0.5 + 0.5), (0.5 - ny * 0.5)
end

local function platformDisc(world, x, z, color)
	local d = Instance.new("Part")
	d.Shape = Enum.PartType.Cylinder
	d.Anchored = true
	d.CanCollide = false
	d.Size = Vector3.new(0.25, 4.6, 4.6)
	d.CFrame = CFrame.new(x, -3.1, z) * CFrame.Angles(0, 0, math.pi / 2)
	d.Material = Enum.Material.Neon
	d.Color = color
	d.Transparency = 0.45
	d.Parent = world
	local r = d:Clone()
	r.Size = Vector3.new(0.22, 5.4, 5.4)
	r.CFrame = d.CFrame * CFrame.new(-0.02, 0, 0)
	r.Color = darker(color, 0.5)
	r.Transparency = 0.25
	r.Material = Enum.Material.SmoothPlastic
	r.Parent = world
	return d, r
end

-- parent: where the viewport goes (it fills it). opts: transparent, dist,
-- platform (Color3 under every rig), sway (a slow camera drift), fov
function Stage.new(parent, opts)
	opts = opts or {}
	local self = setmetatable({}, Stage)
	if not opts.transparent then
		-- the backdrop (a gradient on the ViewportFrame itself would tint the render)
		local back = frame(parent, WHITE, 14)
		back.Size = UDim2.fromScale(1, 1)
		local g = Instance.new("UIGradient", back)
		g.Rotation = 90
		g.Color = ColorSequence.new(Color3.fromRGB(78, 96, 146), Color3.fromRGB(22, 26, 44))
	end
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(160, 156, 150)
	vp.LightColor = Color3.fromRGB(255, 244, 228)
	vp.LightDirection = Vector3.new(-0.6, -1, 0.5)
	vp.Parent = parent
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.Parent = vp
	vp.CurrentCamera = cam
	self.vp, self.world, self.cam = vp, world, cam
	self.rigs = {}
	self.props = {}
	self.dist = opts.dist or 7.5
	self.fov = opts.fov or 50
	self.platform = opts.platform
	self.sway = opts.sway
	self.focusY = opts.focusY or -0.6
	-- the overlay carries every name tag, status line and slot button; it is
	-- re-placed over the rigs whenever they move or the viewport resizes
	local overlay = clearFrame(parent)
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = 3
	overlay.ClipsDescendants = true
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
	if self.sway then
		task.spawn(function()
			while vp.Parent do
				if gui.Enabled and vp.Visible and #self.rigs > 0 and self.sway() then self:place() end
				task.wait(1 / 30)
			end
		end)
	end
	return self
end

-- slot i stands left to right; `back` slots stand a step behind, turned
-- toward the middle, so the middle one (you) is the one up front
function Stage:place()
	local n = #self.rigs
	local gap = 3.6
	local abs = self.vp.AbsoluteSize
	local anyBack = false
	for i, r in ipairs(self.rigs) do
		local x = -(i - (n + 1) / 2) * gap      -- world -X is screen-right for this camera
		local z = r.slot.back and 1.6 or 0
		local turn = r.slot.back and math.sign(x) * 18 or 0
		r.model:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(ui.facing + turn), 0))
		r.x, r.z = x, z
		if r.slot.back then anyBack = true end
		for _, p in ipairs(r.props or {}) do p.part.CFrame = CFrame.new(x, 0, z) * p.offset end
	end
	local d = (self.dist + (n - 1) * 1.6 + (anyBack and 0.6 or 0)) / ui.zoom
	local swayA = self.sway and math.sin(os.clock() * 0.35) * math.rad(4) or 0
	local eye = CFrame.Angles(0, swayA, 0) * Vector3.new(0, self.focusY + 0.5, -d)
	self.cam.CFrame = CFrame.lookAt(eye, Vector3.new(0, self.focusY, 0))
	self.cam.FieldOfView = self.fov
	for _, r in ipairs(self.rigs) do
		local ov = r.overlay
		local fx, fy = project(self.cam, abs, Vector3.new(r.x, -3.35, r.z))
		ov.foot.Position = UDim2.fromScale(fx, fy)
		if ov.mid then local mx, my = project(self.cam, abs, Vector3.new(r.x, 0.3, r.z)); ov.mid.Position = UDim2.fromScale(mx, my) end
		if ov.top then local hx, hy = project(self.cam, abs, Vector3.new(r.x, 2.9, r.z)); ov.top.Position = UDim2.fromScale(hx, hy) end
	end
end

-- slots: list of {loadout=, appearance=, weight=, team=, armor=bool(default true), weapon=bool(default true),
--   tag=, sub=, subColor=, ghost=bool, back=bool, pose=,
--   buttons = {{text, color, fn}}   small buttons under the name
--   onInvite = fn                   a big + on the (ghost) body
--   onKick = fn                     an X over the head }
function Stage:set(slots)
	for _, r in ipairs(self.rigs) do r.model:Destroy(); for _, p in ipairs(r.props or {}) do p.part:Destroy() end end
	self.rigs = {}
	clear(self.overlay)
	for _, s in ipairs(slots) do
		local m
		if s.ghost then
			m = makeRig()
			for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Transparency = 0.82; d.Color = Color3.fromRGB(120, 140, 190) elseif d:IsA("Decal") then d.Transparency = 1 end end
		else
			m = dressedRig(s)
		end
		m.Parent = self.world
		local props = {}
		if self.platform then
			local a, b = platformDisc(self.world, 0, 0, s.ghost and Color3.fromRGB(90, 100, 130) or self.platform)
			table.insert(props, {part = a, offset = CFrame.new(0, -3.1, 0) * CFrame.Angles(0, 0, math.pi / 2)})
			table.insert(props, {part = b, offset = CFrame.new(0, -3.12, 0) * CFrame.Angles(0, 0, math.pi / 2)})
		end
		local ov = {}
		-- under the feet: name, status, buttons
		local foot = clearFrame(self.overlay)
		foot.AnchorPoint = Vector2.new(0.5, 0)
		foot.Size = UDim2.fromOffset(220, 120)
		foot.ZIndex = 4
		local fl = vlist(foot, 4); fl.HorizontalAlignment = Enum.HorizontalAlignment.Center
		local t = title(foot, s.tag or "", 17, s.ghost and COL.DIM or COL.TEXT)
		t.Size = UDim2.new(1, 0, 0, 22); t.LayoutOrder = 1; t.ZIndex = 4
		t.TextXAlignment = Enum.TextXAlignment.Center; t.TextTruncate = Enum.TextTruncate.AtEnd
		if s.sub and s.sub ~= "" then
			local sb = title(foot, s.sub, 14, s.subColor or COL.DIM)
			sb.Size = UDim2.new(1, 0, 0, 18); sb.LayoutOrder = 2; sb.ZIndex = 4
			sb.TextXAlignment = Enum.TextXAlignment.Center
		end
		for j, b in ipairs(s.buttons or {}) do
			local btn = button(foot, b[1], 14, b[2] or COL.GLASS2)
			btn.Size = UDim2.fromOffset(150, 30); btn.LayoutOrder = 10 + j; btn.ZIndex = 5
			if b[3] then btn.Activated:Connect(b[3]) end
		end
		ov.foot = foot
		if s.onInvite then
			local mid = clearFrame(self.overlay)
			mid.AnchorPoint = Vector2.new(0.5, 0.5)
			mid.Size = UDim2.fromOffset(120, 96)
			mid.ZIndex = 4
			local plusH, plus = fatButton(mid, "+", COL.GREEN, 40)
			plusH.AnchorPoint = Vector2.new(0.5, 0); plusH.Position = UDim2.new(0.5, 0, 0, 0); plusH.Size = UDim2.fromOffset(64, 64); plusH.ZIndex = 5; plus.ZIndex = 5
			plusH:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
			plus:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
			local cap = title(mid, "INVITE", 15, COL.TEXT)
			cap.Position = UDim2.new(0, 0, 0, 70); cap.Size = UDim2.new(1, 0, 0, 20); cap.ZIndex = 5
			cap.TextXAlignment = Enum.TextXAlignment.Center
			plus.Activated:Connect(s.onInvite)
			ov.mid = mid
		end
		if s.onKick then
			local xh, x = fatButton(self.overlay, "X", COL.RED, 16)
			xh.AnchorPoint = Vector2.new(0.5, 1); xh.Size = UDim2.fromOffset(34, 34); xh.ZIndex = 5; x.ZIndex = 5
			x.Activated:Connect(s.onKick)
			ov.top = xh
		end
		table.insert(self.rigs, {model = m, slot = s, overlay = ov, props = props})
	end
	self:place()
end

-- stage + hint line below, inside a holder sized by the caller
local function stageBlock(parent, hintText, opts)
	local holder = clearFrame(parent)
	holder.Size = UDim2.new(1, 0, 1, 0)
	local vpHolder = clearFrame(holder)
	vpHolder.Size = UDim2.new(1, 0, 1, -24)
	local st = Stage.new(vpHolder, opts)
	local h = title(holder, hintText or "", 13, COL.DIM)
	h.AnchorPoint = Vector2.new(0, 1)
	h.Position = UDim2.new(0, 0, 1, 0)
	h.Size = UDim2.new(1, 0, 0, 20)
	h.TextXAlignment = Enum.TextXAlignment.Center
	h.TextTruncate = Enum.TextTruncate.AtEnd
	return holder, st, h
end

-- the Tool-like display copy of a weapon wearing a skin, anchored, laid with
-- its longest side along `axisTo` (the card's diagonal) — or nil
local function weaponDisplay(world, weaponId, skinId)
	local t = weaponId and Catalog.weaponModel(weaponId)
	if not t then return nil end
	local m = t:Clone()
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
	m.Parent = world
	if skinId and Catalog.SKIN[skinId] then
		local best = HX.best(skinId)
		pcall(Dresser.applySkin, m, skinId, best and best.v or nil)
	end
	settle(m)
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
	return m
end

-- a small 3D view of a weapon (Cosmetics › Weapons › <id>) wearing a skin,
-- laid diagonally across the card. No display model yet › a flat drawing.
local function weaponThumb(parent, weaponId, skinId, size, zoom)
	local holder = frame(parent, COL.GLASS2, 10)
	holder.Size = size or UDim2.new(1, 0, 0, 72)
	holder.ClipsDescendants = true
	local skin = skinId and Catalog.SKIN[skinId]
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(150, 144, 136)
	vp.LightColor = Color3.fromRGB(255, 244, 228)
	vp.LightDirection = Vector3.new(-0.5, -1, 0.6)
	vp.Parent = holder
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.Parent = vp
	vp.CurrentCamera = cam
	local m = weaponDisplay(world, weaponId, skinId)
	if m then
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
		local d = (longest * 0.6) / math.tan(math.rad(14)) / (zoom or 1)
		cam.FieldOfView = 28
		cam.CFrame = CFrame.lookAt(Vector3.new(0, d * 0.22, -d), Vector3.zero)
	else
		local blade = frame(holder, skin and skin.blade or Color3.fromRGB(180, 180, 180)); blade.AnchorPoint = Vector2.new(0.5, 0.5); blade.Position = UDim2.new(0.5, 0, 0.5, -6); blade.Size = UDim2.fromOffset(8, 48); blade.Rotation = -28
		local grip = frame(holder, skin and skin.grip or Color3.fromRGB(80, 60, 40)); grip.AnchorPoint = Vector2.new(0.5, 0.5); grip.Position = UDim2.new(0.5, -14, 0.5, 20); grip.Size = UDim2.fromOffset(24, 6); grip.Rotation = -28
	end
	return holder
end

-- a small 3D view of a dressed mannequin (a pack's set) facing the camera
local function mannequinThumb(parent, loadout, weight, size, colors, opts)
	opts = opts or {}
	local holder = frame(parent, COL.GLASS2, 10)
	holder.Size = size or UDim2.new(1, 0, 0, 160)
	holder.ClipsDescendants = true
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(150, 144, 136)
	vp.LightColor = Color3.fromRGB(255, 244, 228)
	vp.LightDirection = Vector3.new(-0.5, -1, 0.6)
	vp.Parent = holder
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.Parent = vp
	vp.CurrentCamera = cam
	local lo = {}
	for k, v in pairs(loadout or {}) do lo[k] = v end
	lo.colors = lo.colors or colors or {Primary = "Royal", Secondary = "Slate", Accent = "Ochre", Metal = "Ash"}
	local rig = dressedRig({loadout = lo, appearance = opts.appearance or Catalog.BODY.defaults, weight = weight, weapon = opts.weapon == true, pose = opts.pose})
	rig.Parent = world
	rig:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(opts.yaw or 20), 0))
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(0.4, 0.4, -(opts.dist or 9.4)), Vector3.new(0, -0.45, 0))
	return holder, rig
end

-- the big stage: one weapon with a skin, large, slowly turning about its own axis
local function weaponStage(parent, weaponId, skinId, size)
	local holder = frame(parent, COL.GLASS2, 14)
	holder.Size = size or UDim2.new(1, 0, 1, 0)
	holder.ClipsDescendants = true
	do
		local g = Instance.new("UIGradient", holder)
		g.Rotation = 90
		g.Color = ColorSequence.new(Color3.fromRGB(62, 76, 120), Color3.fromRGB(18, 22, 38))
	end
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(140, 136, 128)
	vp.LightColor = Color3.fromRGB(255, 244, 226)
	vp.LightDirection = Vector3.new(-0.4, -1, 0.5)
	vp.Parent = holder
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.Parent = vp
	vp.CurrentCamera = cam
	local m = weaponDisplay(world, weaponId, skinId)
	if not m then dim(holder, "no display model"); return holder end
	local cf, sz = m:GetBoundingBox()
	local longest = math.max(sz.X, sz.Y, sz.Z, 1)
	-- lay it diagonally, tip up-right, and spin it slowly about its own axis
	local center = cf.Position
	local base = CFrame.Angles(0, 0, math.rad(-30))
	m:PivotTo(base * CFrame.new(-center) * m:GetPivot())
	local d = (longest * 0.6) / math.tan(math.rad(16))
	cam.FieldOfView = 32
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0, -d), Vector3.zero)
	local t0 = os.clock()
	local pivot0 = m:GetPivot()
	task.spawn(function()
		while holder.Parent do
			if gui.Enabled then
				local a = (os.clock() - t0) * 0.5
				m:PivotTo(base * CFrame.Angles(0, a, 0) * base:Inverse() * pivot0)
			end
			task.wait(1 / 30)
		end
	end)
	return holder
end

--------------------------------------------------------------------
--  PREVIEWS of kill effects and emotes: your own look on a mannequin
--------------------------------------------------------------------
local Preview = {KillFX = require(ReplicatedStorage:WaitForChild("KillFX")), Emotes = require(ReplicatedStorage:WaitForChild("Emotes")), SkinFX = require(ReplicatedStorage:WaitForChild("SkinFX"))}
function Preview.fxText(skin) return skin and Preview.SkinFX.describe(skin) or nil end
function Preview.box(parent, size)
	local holder = frame(parent, COL.GLASS2, 14)
	holder.Size = size or UDim2.fromScale(1, 1)
	holder.ClipsDescendants = true
	do
		local g = Instance.new("UIGradient", holder)
		g.Rotation = 90
		g.Color = ColorSequence.new(Color3.fromRGB(62, 76, 120), Color3.fromRGB(18, 22, 38))
	end
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(160, 156, 150)
	vp.LightColor = Color3.fromRGB(255, 244, 228)
	vp.LightDirection = Vector3.new(-0.5, -1, 0.5)
	vp.Parent = holder
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.Parent = vp
	vp.CurrentCamera = cam
	return holder, world, cam
end
-- you in your active class (light = no armor: the small cards)
function Preview.rig(world, weapon, light)
	local lo = {}
	for k, v in pairs(classLoadout(state.activeClass)) do lo[k] = v end
	local rig = dressedRig({loadout = lo, appearance = state.profile and state.profile.appearance, weight = weightOf(state.activeClass), weapon = weapon, armor = not light})
	rig.Parent = world
	return rig
end
-- the kill effect on you, again and again (still = a frozen moment, 0..1)
function Preview.killFx(parent, id, size, still, light)
	local holder, world, cam = Preview.box(parent, size)
	cam.FieldOfView = 40
	cam.CFrame = light and CFrame.lookAt(Vector3.new(0, 1.6, -10.5), Vector3.new(0, 0.2, 0)) or CFrame.lookAt(Vector3.new(0, 2.4, -13.5), Vector3.new(0, 0.4, 0))
	local floor = Instance.new("Part")
	floor.Anchored = true; floor.Size = Vector3.new(40, 1, 40); floor.CFrame = CFrame.new(0, -3.5, 0)
	floor.Color = Color3.fromRGB(58, 64, 80); floor.Material = Enum.Material.Slate; floor.Parent = world
	local function once(freeze, sound)
		for _, c in ipairs(world:GetChildren()) do if c ~= floor then c:Destroy() end end
		local rig = Preview.rig(world, false, light)
		rig:PivotTo(CFrame.Angles(0, math.rad(18), 0))
		-- direct: the preview rig is ours, so the effect hides it for real
		local bodyParts = {direct = true}
		for _, d in ipairs(rig:GetDescendants()) do
			if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then table.insert(bodyParts, d) end
		end
		local torso = rig:FindFirstChild("Torso")
		return Preview.KillFX.play(id, world, torso and torso.CFrame or CFrame.new(), {body = bodyParts, freezeAt = freeze, sound = sound})
	end
	if still then once(still); return holder end
	task.spawn(function()
		local first = true   -- the first play is heard; the loop after it is silent
		while holder.Parent do
			if gui.Enabled then
				local d = once(nil, first)
				first = false
				task.wait((d or 2) + 0.9)
			else
				task.wait(0.5)
			end
		end
	end)
	return holder
end
-- the emote on you, looping (still = a frozen moment, 0..1)
function Preview.emote(parent, id, size, still, light)
	local holder, world, cam = Preview.box(parent, size)
	cam.FieldOfView = 40
	cam.CFrame = light and CFrame.lookAt(Vector3.new(0, 0.8, -8.6), Vector3.new(0, 0, 0)) or CFrame.lookAt(Vector3.new(0, 1.4, -12), Vector3.new(0, 0.2, 0))
	local rig = Preview.rig(world, true, light)
	rig:PivotTo(CFrame.Angles(0, math.rad(16), 0))
	if not light then platformDisc(world, 0, 0, COL.BLUE) end
	local origins = {}
	local dur = Preview.Emotes.DURATION[id] or 2
	if still then Preview.Emotes.poseRig(rig, id, dur * still, origins); settle(rig); return holder end
	local t0 = os.clock()
	task.spawn(function()
		while holder.Parent do
			if gui.Enabled then
				local t = (os.clock() - t0) % (dur + 0.8)
				Preview.Emotes.poseRig(rig, id, math.min(t, dur), origins)
				settle(rig)
			end
			task.wait(1 / 30)
		end
	end)
	return holder
end
-- an egg on a little stage, turning (wobble() -> 0..1, how hard it shakes)
Preview.Comp = require(ReplicatedStorage:WaitForChild("Companions"))
function Preview.egg(parent, eggId, size, wobble, still)
	local holder, world, cam = Preview.box(parent, size)
	local e = Preview.Comp.egg(eggId)
	if not e then return holder end
	e.model.Parent = world
	cam.FieldOfView = 30
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 1.5, -5.4), Vector3.new(0, 0.85, 0))
	Preview.Comp.poseEgg(e, CFrame.Angles(0, 0.5, 0), 0, 0)
	if still then return holder end
	local t0 = os.clock()
	task.spawn(function()
		while holder.Parent do
			if gui.Enabled then
				local t = os.clock() - t0
				Preview.Comp.poseEgg(e, CFrame.Angles(0, t * 0.6, 0), t, wobble and wobble() or 0.05)
			end
			task.wait(1 / 30)
		end
	end)
	return holder
end
-- HATCHING: the egg on a dark stage — it rocks, cracks three times (harder
-- each time, a crack spreading over it), bursts in a flash, and the reveal
-- comes in (rarity flash + banner + sting). Blocks until it's done.
function HX.hatchMoment(anchor, eggId, rarity, variant, dup)
	local FX = HX.FX
	local sg = anchor and anchor:FindFirstAncestorOfClass("ScreenGui")
	if not (sg and eggId and Catalog.EGG[eggId]) then return end
	local cover = Instance.new("Frame")
	cover.Name = "_Hatching"; cover.Size = UDim2.fromScale(1, 1); cover.BorderSizePixel = 0; cover.ZIndex = 900
	cover.BackgroundColor3 = Color3.fromRGB(8, 7, 12); cover.BackgroundTransparency = 1
	cover.Active = true; cover.Parent = sg
	game:GetService("TweenService"):Create(cover, TweenInfo.new(0.25), {BackgroundTransparency = 0.25}):Play()
	local shake = 0.08
	local stage = Preview.egg(cover, eggId, UDim2.fromOffset(420, 420), function() return shake end)
	stage.AnchorPoint = Vector2.new(0.5, 0.5); stage.Position = UDim2.fromScale(0.5, 0.5); stage.ZIndex = 901
	stage.BackgroundTransparency = 1
	-- cracks: jagged white lines laid over the egg, more with each blow
	local function crack(n)
		for k = 1, 2 + n do
			local ln = Instance.new("Frame")
			ln.BorderSizePixel = 0; ln.BackgroundColor3 = Color3.new(1, 1, 1); ln.ZIndex = 905
			ln.AnchorPoint = Vector2.new(0.5, 0.5)
			ln.Size = UDim2.fromOffset(18 + math.random(26), 3)
			ln.Position = UDim2.new(0.5, math.random(-46, 46), 0.48, math.random(-70, 50))
			ln.Rotation = math.random(-70, 70)
			ln.Parent = stage
		end
	end
	task.wait(0.35)
	for n = 1, 3 do
		shake = 0.3 + n * 0.25
		task.wait(0.5 - n * 0.08)
		FX.play("EggCrack", {Speed = 1 + n * 0.08})
		FX.flash(cover, Color3.new(1, 1, 1), 0.12 + n * 0.06, 0.18)
		FX.shake(stage, 4 + n * 3, 0.22)
		crack(n)
		shake = 0.1
		task.wait(0.18)
	end
	shake = 1.2
	task.wait(0.35)
	-- the burst
	FX.play("EggBurst"); FX.play("Shells")
	FX.flash(cover, Color3.new(1, 1, 1), 0.95, 0.6)
	stage:Destroy()
	task.wait(0.15)
	HX.revealMoment(cover, rarity, variant, dup)
	game:GetService("TweenService"):Create(cover, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
	task.delay(0.3, function() cover:Destroy() end)
end

-- a companion on a little stage (still = a frozen pose; dark = a silhouette)
function Preview.companion(parent, id, size, still, stars, dark)
	local holder, world, cam = Preview.box(parent, size)
	local rig = Preview.Comp.build(id, {stars = stars, variant = (not dark) and (HX.best("pet:" .. id) or {}).v or nil})
	if not rig then return holder end
	rig.model.Parent = world
	if dark then
		for _, p in ipairs(rig.list) do if p:IsA("BasePart") then p.Color = Color3.fromRGB(14, 16, 24); p.Material = Enum.Material.SmoothPlastic end end
	end
	local y = rig.flying and 1.3 * rig.scale or rig.foot
	local d = 6.6 * rig.scale
	cam.FieldOfView = 34
	cam.CFrame = CFrame.lookAt(Vector3.new(d * 0.5, y + 1.3 * rig.scale, -d), Vector3.new(0, y * 0.9 + 0.2 * rig.scale, 0))
	local disc = Instance.new("Part")
	disc.Shape = Enum.PartType.Cylinder; disc.Anchored = true; disc.Size = Vector3.new(0.2, 3.4 * rig.scale, 3.4 * rig.scale)
	disc.CFrame = CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, math.pi / 2); disc.Material = Enum.Material.Neon; disc.Color = COL.BLUE; disc.Transparency = 0.55
	disc.Parent = world
	if still then Preview.Comp.pose(rig, CFrame.new(0, y, 0) * CFrame.Angles(0, math.rad(200), 0), 0.4, 0); return holder end
	local t0 = os.clock()
	task.spawn(function()
		while holder.Parent do
			if gui.Enabled then
				local t = os.clock() - t0
				Preview.Comp.pose(rig, CFrame.new(0, y, 0) * CFrame.Angles(0, math.rad(200) + math.sin(t * 0.5) * 0.6, 0), t, 0.45 + 0.35 * math.sin(t * 0.7))
			end
			task.wait(1 / 30)
		end
	end)
	return holder
end
-- the time on a clock: 1:02:03 / 4:05
function Preview.clock(sec)
	sec = math.max(0, math.floor(sec))
	local h, m, s2 = math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s2) end
	return string.format("%d:%02d", m, s2)
end
-- what a gift / pass reward is, in a few words
function Preview.rewardName(r)
	if r.marks then return fmt(r.marks) .. " Marks" end
	if r.crowns then return fmt(r.crowns) .. " Crowns" end
	if r.egg and Catalog.EGG[r.egg] then return Catalog.EGG[r.egg].name end
	if r.crate and Catalog.CRATES[r.crate] then return "a free " .. Catalog.CRATES[r.crate].name end
	if r.companion and Catalog.COMPANION[r.companion] then return Catalog.COMPANION[r.companion].name end
	if r.emote and Catalog.EMOTE[r.emote] then return "the " .. Catalog.EMOTE[r.emote].name .. " emote" end
	if r.killfx and Catalog.KILLFX_BY[r.killfx] then return Catalog.KILLFX_BY[r.killfx].name end
	if r.skin and Catalog.SKIN[r.skin] then return Catalog.SKIN[r.skin].name end
	if r.title then return "the title " .. r.title end
	return "a gift"
end
-- eggs ready in your nests (the server's "Nests" attribute: egg,readyAt;…)
function Preview.readyEggs()
	local s, n = player:GetAttribute("Nests"), 0
	if type(s) ~= "string" then return 0 end
	local now = workspace:GetServerTimeNow()
	for at in s:gmatch(",(%d+)") do if tonumber(at) <= now then n += 1 end end
	return n
end

-- a small still card picture for any crate item
function Preview.thumb(parent, it, size, zoom)
	if it.kind == "skin" then return weaponThumb(parent, it.weapon, it.id, size, zoom) end
	if it.kind == "killfx" then return Preview.killFx(parent, it.id, size, 0.3, true) end
	return Preview.emote(parent, it.id, size, 0.45, true)
end

--------------------------------------------------------------------
--  SCREENS + SHARED ACTIONS
--------------------------------------------------------------------
-- every screen: its header (title, icon) and a frame in the content host.
-- "PLAY" is the lobby itself.
local SCREEN_DEF = {
	MODES      = {title = "PLAY",     icon = "Armory"},
	CLASSES    = {title = "LOADOUT",  icon = "Loadout"},
	ARMORY     = {title = "ARMORY",   icon = "Armory"},
	SHOP       = {title = "SHOP",     icon = "Shop"},
	TASKS      = {title = "TASKS",    icon = "Tasks"},
	APPEARANCE = {title = "WARDROBE", icon = "Wardrobe"},
	SERVERS    = {title = "SERVERS",  icon = "Tasks"},
	SETTINGS   = {title = "SETTINGS", icon = "Settings"},
	PASS       = {title = "SEASON PASS", icon = "Pass"},
	HATCHERY   = {title = "HATCHERY", icon = "Hatchery"},
	TRADE      = {title = "TRADE",    icon = "Shop"},
	RANKS      = {title = "LEADERBOARDS", icon = "Tasks"},
	PROFILE    = {title = "PROFILE",  icon = "Loadout"},
}
-- old tab names and the names other scripts send over the bus
local ALIAS = {LOBBY = "PLAY", MENU = "PLAY", LOADOUT = "CLASSES", WARDROBE = "APPEARANCE", STORE = "SHOP", CRATES = "SHOP", WEAPONS = "ARMORY", ARMOR = "ARMORY",
	EGGS = "HATCHERY", PETS = "HATCHERY", COMPANIONS = "HATCHERY", TRADING = "TRADE", LEADERBOARD = "RANKS", LEADERBOARDS = "RANKS"}
local tabFrame, render, screenFoot = {PLAY = lobby}, {}, {}
for name in pairs(SCREEN_DEF) do
	local f = clearFrame(content)
	f.Name = name
	f.Size = UDim2.fromScale(1, 1)
	f.Visible = false
	tabFrame[name] = f
end

local renderSide, selectTab, hide, show   -- forward
local passClaimable                      -- forward (the PASS screen defines it; the dock badge reads it)
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
	modal("PLAYERS HERE", string.format("People in this server: invite them to your party, or see their profile. A party is at most %d. Friends in other servers can be invited too: they travel here when they accept.", state.partyMax), nil, function(box)
		local n = 0
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				n += 1
				local inParty = false
				if state.party then for _, m in ipairs(state.party.members) do if m.id == other.UserId then inParty = true end end end
				local rb = row(box, other.DisplayName, inParty and "in your party" or "INVITE", false, (not inParty) and function()
					local r = call("PartyInvite", other.UserId, other.DisplayName)
					toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
					if r.party then state.party = r.party end
					closeModal(); rerender()
				end or nil, inParty and COL.DIM or COL.GOOD)
				local pb = button(rb, "PROFILE", 12, COL.BLUE)
				pb.AnchorPoint = Vector2.new(1, 0.5); pb.Position = UDim2.new(1, -110, 0.5, 0); pb.Size = UDim2.fromOffset(84, 26)
				local uid = other.UserId
				pb.Activated:Connect(function() closeModal(); HX.openProfile(uid) end)
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
			for _, fd in ipairs(away) do
				row(box, fd.name, "INVITE", false, function()
					local r = call("PartyInvite", fd.id, fd.name)
					toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
					if r.party then state.party = r.party end
					closeModal(); rerender()
				end, COL.GOOD)
			end
		end
	end)
end

local function partySize() return state.party and state.party.members and #state.party.members or 1 end
local function isLeader() return not state.party or state.party.leaderId == player.UserId end
local function inParty() return state.party ~= nil and #(state.party.members or {}) > 1 end
-- why the party can't go yet (nil = it can)
local function partyBlocked()
	local p = state.party
	if not p or #p.members <= 1 then return nil end
	if p.leaderId ~= player.UserId then return "the party leader picks where you go" end
	if not p.allReady then return "waiting for everyone to ready up" end
	return nil
end

local goDoor, offerTraining   -- forward (defined below)
local function findMatch()
	if state.queue then return end
	local blocked = partyBlocked()
	if blocked then toast(blocked, COL.BAD); return end
	local size = tonumber(ui.bracket:match("^(%d)")) or 1
	local n = partySize()
	if n > size then
		modal("PARTY TOO BIG FOR " .. ui.bracket, string.format("%s takes a party of at most %d and yours is %d. Remove someone (the X over their head in the lobby) or pick a bigger bracket.", ui.bracket, size, n),
			{{"PICK " .. (n <= 2 and "2v2" or "3v3"), COL.BLUE, function() ui.bracket = n <= 2 and "2v2" or "3v3"; closeModal(); rerender() end}})
		return
	end
	if offerTraining(findMatch) then return end
	local r = call("Play", "Lists", {bracket = ui.bracket, ranked = ui.ranked})
	if r.ok then
		toast(r.msg or "", COL.GOOD)
		state.queue = {bracket = ui.bracket, ranked = ui.ranked, since = os.clock(), waiting = 0, window = 100}
		selectTab("PLAY")
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

-- a new player (no lessons, no rounds) heading to battle is offered the
-- training once; either answer is remembered (profile askedTraining)
offerTraining = function(proceed)
	local p = state.profile
	if not p or p.askedTraining then return false end
	for _ in pairs(p.drills or {}) do return false end
	local st = p.stats or {}
	if (st.round or 0) > 0 or (st.kill or 0) > 0 then return false end
	p.askedTraining = true
	task.spawn(call, "AskedTraining")
	modal("NEW TO THE FIGHT?", "The Drill Master in the Training Yard teaches every move in a few minutes, and every lesson pays Marks. Would you like to complete the training first?",
		{{"TO THE TRAINING YARD", COL.GREEN, function() closeModal(); goDoor("Tiltyard") end},
		 {"STRAIGHT TO BATTLE", COL.RED, function() closeModal(); proceed() end}})
	return true
end

goDoor = function(doorId, opts)
	if doorId == "Warfront" and offerTraining(function() goDoor(doorId, opts) end) then return false end
	local blocked = partyBlocked()
	if blocked and doorId ~= "Courtyard" then toast(blocked, COL.BAD); return false end
	local r = call("Play", doorId, opts or {})
	toast((GameConfig.DOORS[doorId] and GameConfig.DOORS[doorId].name or doorId) .. ":  " .. (r.msg or ""), r.ok and COL.GOOD or COL.BAD)
	return r.ok
end
local function enterCourtyard()
	loadoutEvent:FireServer("Spawn", state.activeClass)
end
local function leaveMatch()
	if state.ranked and state.door == "Lists" then
		modal("LEAVE A RANKED MATCH?", "Leaving before the end counts as a loss and locks the queue for " .. tostring(ECON.queueLockMinutes or 10) .. " minutes.",
			{{"LEAVE", COL.RED, function() closeModal(); goDoor("Courtyard") end}})
	elseif roundState() == "Round" and not inHub() and roundNode:GetAttribute("Mode") ~= "Tiltyard"
		and roundNode:GetAttribute("NoRewards") ~= true then
		-- a battle in progress: the round's pay is only for those still in it at the end
		local e = ECON.earn
		local ls = player:FindFirstChild("leaderstats")
		local kills = ls and ls:FindFirstChild("Kills") and ls.Kills.Value or 0
		modal("LEAVE THE BATTLE?", string.format(
			"The round's pay goes to those who see it out: %d Marks for finishing it (win or lose), %d more if your side wins%s. Leave now and you get none of it.",
			e.round.marks, e.win.marks, kills > 0 and string.format(", and %d for your %d kill%s so far", e.kill.marks * kills, kills, kills == 1 and "" or "s") or ""),
			{{"LEAVE ANYWAY", COL.RED, function() closeModal(); goDoor("Courtyard") end}})
	else
		goDoor("Courtyard")
	end
end

-- packs: what a pack dresses, holds, costs, and when it is back
local Packs = {}
-- the loadout a pack dresses: its helm / top / legs (first piece per slot)
function Packs.loadout(packKey)
	local lo = {}
	for _, pc in ipairs(Catalog.PIECES) do
		if pc.pack == packKey and not lo[pc.slot] then lo[pc.slot] = pc.id end
	end
	return lo
end
function Packs.skins(packKey)
	local out = {}
	for _, sk in ipairs(Catalog.SKINS) do if sk.pack == packKey then table.insert(out, sk) end end
	return out
end
function Packs.pieces(packKey)
	local out = {}
	for _, pc in ipairs(Catalog.PIECES) do if pc.pack == packKey then table.insert(out, pc) end end
	return out
end
function Packs.rarity(packKey)
	local r = "Common"
	for _, pc in ipairs(Packs.pieces(packKey)) do if (RARITY_ORDER[pc.rarity] or 1) > (RARITY_ORDER[r] or 1) then r = pc.rarity end end
	return r
end
function Packs.owned(packKey)
	local all, any = true, false
	for _, pc in ipairs(Packs.pieces(packKey)) do if owns("pieces", pc.id) then any = true else all = false end end
	for _, sk in ipairs(Packs.skins(packKey)) do if owns("skins", sk.id) then any = true else all = false end end
	return all, any
end
function Packs.price(packKey)
	local m, c = 0, 0
	for _, pc in ipairs(Packs.pieces(packKey)) do if not owns("pieces", pc.id) then m += pc.marks or 0; c += pc.crowns or 0 end end
	for _, sk in ipairs(Packs.skins(packKey)) do if not owns("skins", sk.id) then m += sk.marks or 0; c += sk.crowns or 0 end end
	local disc = 1 - (Catalog.PACKS[packKey].bundle or 0)
	return math.floor(m * disc + 0.5), math.floor(c * disc + 0.5)
end
local function priceText(m, c)
	local bits = {}
	if (m or 0) > 0 then table.insert(bits, fmt(m) .. " Marks") end
	if (c or 0) > 0 then table.insert(bits, fmt(c) .. " Crowns") end
	return #bits > 0 and table.concat(bits, "  or  ") or "free"
end
-- the next UTC day (within a month) a pack is in the store, as "Oct 9", or nil
function Packs.nextOnSale(packKey)
	local today = storeDay() or os.date("!%Y-%m-%d")
	local y, mo, d = today:match("^(%d+)%-(%d+)%-(%d+)$")
	if not y then return nil end
	local base = os.time({year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = 12})
	for i = 1, 30 do
		local key = os.date("!%Y-%m-%d", base + i * 86400)
		for _, k in ipairs((Catalog.storeFor(key))) do
			if k == packKey then return os.date("!%b %d", base + i * 86400):gsub(" 0", " "), i end
		end
	end
	return nil
end

-- where a skin comes from, for a label: text, and the kind ("owned", "buy",
-- "crate", "earned", "pack", "shelf")
local function skinWhere(s)
	if not s or s.name == "Default" then return "free", "owned" end
	if owns("skins", s.id) then return "owned", "owned" end
	local src = Catalog.skinSource(s)
	local status, note = HX.Drops.skinStatus(s)
	if status == "relic" then return "RELIC  ·  " .. note .. ": it never comes back", "relic" end
	if src == "founder" then return "FOUNDERS  ·  free to everyone who plays before the Founders' window closes", "claim" end
	if src == "claim" then return "a free gift " .. ((HX.Drops.claim(s.claim) or {}).note or "on its day") .. "  ·  " .. note, "claim" end
	if s.limited then
		local left = s.limited - Catalog.limitedMade(s.id)
		if left <= 0 then return "LIMITED  ·  sold out: all " .. fmt(s.limited) .. " were made", "relic" end
		if skinOnSale(s.id) then return string.format("LIMITED  ·  %s of %s left  ·  in today's shop", fmt(left), fmt(s.limited)), "buy" end
	end
	if status == "vaulted" then return "VAULTED  ·  its crate (" .. (Catalog.CRATES[s.crate] and Catalog.CRATES[s.crate].name or s.crate) .. ") is out of rotation, it may come back", "vaulted" end
	if src == "pass" then
		for i, t in ipairs(Catalog.PASS.tiers or {}) do
			if (t.free and t.free.skin == s.id) then return "season pass reward  ·  tier " .. i .. " (free)", "pass" end
			if (t.premium and t.premium.skin == s.id) then return "season pass reward  ·  tier " .. i .. " (premium)", "pass" end
		end
		return "a season pass reward", "pass"
	elseif src == "earned" then
		return "earn it: " .. Catalog.unlockText(s.unlock) .. "  ·  " .. progressText(s.unlock), "earned"
	elseif src == "crate" then
		return "drops from the " .. (Catalog.CRATES[s.crate] and Catalog.CRATES[s.crate].name or s.crate), "crate"
	elseif src == "pack" then
		local pk = Catalog.PACKS[s.pack]
		if skinOnSale(s.id) then return "in today's shop  ·  " .. (pk and pk.name or s.pack) .. " pack", "buy" end
		local when = Packs.nextOnSale(s.pack)
		return "comes with the " .. (pk and pk.name or s.pack) .. " pack" .. (when and ("  ·  back " .. when) or ""), "pack"
	elseif src == "shop" then
		if skinOnSale(s.id) then return "on today's WEAPONS shelf", "buy" end
		return "sold on the shop's WEAPONS shelf some days, not today", "shelf"
	end
	return "free", "owned"
end

-- where a kill effect / emote comes from, for a label: text, kind
function Preview.where(it, ownKind)
	if not it then return "", "owned" end
	if owns(ownKind, it.id) then return "owned", "owned" end
	local src = Catalog.itemSource(it)
	if src == "free" then return "free for everyone", "owned" end
	if src == "earned" then return "earn it: " .. Catalog.unlockText(it.unlock) .. "  ·  " .. progressText(it.unlock), "earned" end
	if src == "pass" then
		local key = ownKind == "killfx" and "killfx" or "emote"
		for i, t in ipairs(Catalog.PASS.tiers or {}) do
			if t.free and t.free[key] == it.id then return "season pass reward  ·  tier " .. i .. " (free)", "pass" end
			if t.premium and t.premium[key] == it.id then return "season pass reward  ·  tier " .. i .. " (premium)", "pass" end
		end
		return "a season pass reward", "pass"
	end
	if src == "crate" then return "drops from the " .. (Catalog.CRATES[it.crate] and Catalog.CRATES[it.crate].name or it.crate), "crate" end
	return "", "owned"
end

local function afterBuy(r, rerenderFn)
	toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
	if r.profile then state.profile = r.profile; refreshWallet() end
	closeModal()
	if rerenderFn then rerenderFn() else rerender() end
end

-- the buy buttons for a skin on sale today (for modal() lists)
local function skinBuyButtons(s, after)
	local out = {}
	if (s.marks or 0) > 0 then table.insert(out, {"BUY  ·  " .. fmt(s.marks) .. " MARKS", COL.BLUE, function() afterBuy(call("Buy", "skin", s.id, "marks"), after) end}) end
	if (s.crowns or 0) > 0 then table.insert(out, {"BUY  ·  " .. fmt(s.crowns) .. " CROWNS", COL.GOLD, function() afterBuy(call("Buy", "skin", s.id, "crowns"), after) end}) end
	return out
end

--------------------------------------------------------------------
--  LOBBY — your party on the stage, tasks + friends on the left, the
--  leaderboard + today's shop on the right, the dock and PLAY at the bottom
--------------------------------------------------------------------
local dockBadges = {}
local renderPlayArea   -- forward (renderSide calls it)
do
	-- the stage: you up front in the middle, the party around you
	local stageArea = clearFrame(lobby)
	stageArea.Position = UDim2.fromOffset(372, 96)
	stageArea.Size = UDim2.new(1, -372 - 384, 1, -96 - 176)
	local stage = Stage.new(stageArea, {transparent = true, dist = 10.5, fov = 40, platform = COL.BLUE,
		sway = function() return currentTab == "PLAY" and not modalBack.Visible end})
	local stageHint = title(lobby, "", 13, COL.DIM)
	stageHint.AnchorPoint = Vector2.new(0.5, 1)
	stageHint.Position = UDim2.new(0.5, -4, 1, -176)
	stageHint.Size = UDim2.fromOffset(560, 18)
	stageHint.TextXAlignment = Enum.TextXAlignment.Center

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

	-- you in the middle; teammates and open slots (shadows) around you.
	-- Click a shadow's + to invite, the X over a teammate to remove them.
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
			local sub, subColor = className(cls), COL.DIM
			if party then
				if m.leader then sub, subColor = "👑 LEADER", COL.ACCENT
				elseif m.ready then sub, subColor = "READY ✔", COL.GOOD
				else sub, subColor = "NOT READY", COL.BAD end
			end
			local buttons = {}
			if mine and party then
				table.insert(buttons, {"LEAVE PARTY", COL.GLASS2, function() call("PartyLeave"); state.party = nil; state.queue = nil; toast("left the party", COL.DIM); rerender() end})
			end
			return {
				loadout = lo, appearance = mine and state.profile and state.profile.appearance or nil, weight = weightOf(cls), back = not mine,
				tag = mine and player.DisplayName or string.format("%s  ·  %d", m.name, m.level or 1),
				sub = sub, subColor = subColor, buttons = buttons,
				onKick = (leader and not mine) and function()
					local r = call("PartyKick", m.id)
					toast(r.msg or "", r.ok and COL.DIM or COL.BAD)
					if r.party then state.party = r.party end
					rerender()
				end or nil,
			}
		end
		local function ghostSlot()
			return {ghost = true, back = true, tag = "OPEN SLOT", sub = leader and "" or "the leader invites", onInvite = leader and inviteModal or nil}
		end
		local me, others = nil, {}
		for _, m in ipairs(list) do if m.id == player.UserId then me = m else table.insert(others, m) end end
		local slots, mid, k = {}, math.ceil(state.partyMax / 2), 1
		for i = 1, state.partyMax do
			if i == mid then table.insert(slots, me and memberSlot(me) or ghostSlot())
			else table.insert(slots, others[k] and memberSlot(others[k]) or ghostSlot()); k += 1 end
		end
		stage:set(slots)
		stageHint.Text = party and string.format("PARTY %d / %d  ·  EVERYONE READIES, THE LEADER PRESSES PLAY", #list, state.partyMax)
			or "DRAG TO TURN  ·  PRESS + TO INVITE A FRIEND"
	end

	----------------------------------------------------------------
	--  left: daily tasks + friends
	----------------------------------------------------------------
	local left = clearFrame(lobby)
	left.Position = UDim2.fromOffset(24, 104)
	left.Size = UDim2.new(0, 330, 1, -104 - 196)
	local leftList = scroll(left, 12)

	local function taskRow(parent, ct, big)
		local r = frame(parent, COL.GLASS2, 12)
		r.BackgroundTransparency = ct.done and 0.45 or 0.1
		r.Size = UDim2.new(1, 0, 0, big and 92 or 74)
		r.LayoutOrder = nextOrder()
		padding(r, 12, 12, 8, 10)
		local t = title(r, (ct.weekly and "★ " or "") .. ct.text, big and 17 or 15, ct.done and COL.DIM or COL.TEXT)
		t.TextWrapped = true
		t.Size = UDim2.new(1, -78, 0, big and 40 or 34)
		t.TextYAlignment = Enum.TextYAlignment.Top
		local rw = clearFrame(r)
		rw.AnchorPoint = Vector2.new(1, 0)
		rw.Position = UDim2.new(1, 0, 0, -2)
		rw.Size = UDim2.fromOffset(76, 30)
		local ic = iconImage(rw, "Marks", 30); ic.Position = UDim2.fromOffset(0, 0)
		local pay = title(rw, "+" .. fmt(ct.pay), 15, COL.MARKS); pay.Position = UDim2.fromOffset(30, 4); pay.Size = UDim2.fromOffset(46, 22)
		local barH = clearFrame(r)
		barH.AnchorPoint = Vector2.new(0, 1)
		barH.Position = UDim2.new(0, 0, 1, 0)
		barH.Size = UDim2.new(1, 0, 0, big and 20 or 16)
		progressBar(barH, ct.goal > 0 and ct.n / ct.goal or 0, ct.done and COL.GOOD or (ct.weekly and COL.PURPLE or COL.BLUE),
			ct.done and "DONE ✔" or string.format("%s / %s", fmt(ct.n), fmt(ct.goal)), big and 20 or 16)
		return r
	end

	local function renderLeft()
		clear(leftList)
		local c = panel(leftList, nil)
		do
			local h = clearFrame(c); h.Size = UDim2.new(1, 0, 0, 36); h.LayoutOrder = 0
			local ic = iconImage(h, "Tasks", 44); ic.Position = UDim2.fromOffset(-6, -6)
			local t = title(h, "DAILY TASKS", 20); t.Position = UDim2.fromOffset(42, 0); t.Size = UDim2.new(1, -42, 0, 24)
			local cd = title(h, "", 12, COL.DIM); cd.Position = UDim2.fromOffset(42, 22); cd.Size = UDim2.new(1, -42, 0, 14)
			local function tick() cd.Text = "NEW TASKS IN " .. storeCountdown() end
			tick()
			task.spawn(function() while cd.Parent do task.wait(30); tick() end end)
		end
		local n = 0
		for _, ct in ipairs(state.contracts or {}) do
			if not ct.weekly then n += 1; taskRow(c, ct, false) end
		end
		for _, ct in ipairs(state.contracts or {}) do
			if ct.weekly then taskRow(c, ct, false) end
		end
		if n == 0 then dim(c, "Tasks load with your profile.") end
		local all = bigBtn(c, "ALL TASKS  ›", COL.BLUE, function() selectTab("TASKS") end)
		all.Size = UDim2.new(1, 0, 0, 38)

		-- playtime gifts: the next one, its countdown, CLAIM
		do
			local G = Catalog.GIFTS.gifts
			local gp = panel(leftList, nil)
			local hd = clearFrame(gp); hd.Size = UDim2.new(1, 0, 0, 26); hd.LayoutOrder = 0
			local gt = title(hd, "🎁  PLAYTIME GIFTS", 18); gt.Size = UDim2.new(1, 0, 0, 24)
			local claimed, cnt = {}, 0
			for k in (player:GetAttribute("GiftsClaimed") or ""):gmatch("[^,]+") do claimed[k] = true; cnt += 1 end
			local played = player:GetAttribute("PlaySeconds") or 0
			local at = os.clock()
			local nextI
			for i in ipairs(G) do if not claimed[tostring(i)] then nextI = i; break end end
			if not nextI then
				dim(gp, "All " .. #G .. " claimed today. New gifts tomorrow!", 13)
			else
				local g = G[nextI]
				local prev = nextI > 1 and G[nextI - 1].minutes * 60 or 0
				local gr = row(gp, string.format("%d MIN  ·  %s", g.minutes, Preview.rewardName(g.reward)), "", false, nil, COL.DIM)
				local rl
				for _, ch in ipairs(gr:GetChildren()) do if ch:IsA("TextLabel") and ch.TextXAlignment == Enum.TextXAlignment.Right then rl = ch end end
				if not rl then rl = label(gr, "", 12, FONT, COL.DIM); rl.AnchorPoint = Vector2.new(1, 0); rl.Position = UDim2.new(1, 0, 0, 0); rl.Size = UDim2.new(0.4, 0, 1, 0); rl.TextXAlignment = Enum.TextXAlignment.Right end
				local bh = clearFrame(gp); bh.Size = UDim2.new(1, 0, 0, 12); bh.LayoutOrder = nextOrder()
				local _, fill = progressBar(bh, 0, COL.BLUE, nil, 12)
				local claimB = bigBtn(gp, "CLAIM GIFT", COL.GREEN, function()
					local r = call("GiftClaim", nextI)
					toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
					if r.profile then state.profile = r.profile; refreshWallet() end
					if r.ok and r.gifts then
						local list = {}
						for k in pairs(r.gifts.claimed or {}) do table.insert(list, k) end
						table.sort(list)
						player:SetAttribute("GiftsClaimed", table.concat(list, ","))
					end
					renderLeft()
				end)
				claimB.Size = UDim2.new(1, 0, 0, 38)
				dim(gp, string.format("%d / %d claimed today  ·  every minute you play counts", cnt, #G), 12)
				local function tick()
					local now = played + (os.clock() - at)
					local left = g.minutes * 60 - now
					rl.Text = left <= 0 and "READY!" or Preview.clock(left)
					rl.TextColor3 = left <= 0 and COL.GOOD or COL.DIM
					local fr = math.clamp((now - prev) / math.max(1, g.minutes * 60 - prev), 0, 1)
					fill.Size = UDim2.new(fr, 0, 1, 0); fill.Visible = fr > 0.001
					fill.BackgroundColor3 = left <= 0 and COL.GREEN or COL.BLUE
					claimB.Visible = left <= 0
				end
				tick()
				task.spawn(function() while gp.Parent do task.wait(1); tick() end end)
			end
		end

		local f = panel(leftList, "FRIENDS")
		local shown = 0
		local sorted = {}
		for _, fd in ipairs(state.friends) do table.insert(sorted, fd) end
		table.sort(sorted, function(a, b)
			local ra = a.here and 0 or (a.inGame and 1 or 2)
			local rb = b.here and 0 or (b.inGame and 1 or 2)
			if ra ~= rb then return ra < rb end
			return a.name < b.name
		end)
		for _, fd in ipairs(sorted) do
			if shown >= 5 then break end
			shown += 1
			local inP = false
			if state.party then for _, m in ipairs(state.party.members) do if m.id == fd.id then inP = true end end end
			row(f, fd.name, inP and "in party" or (fd.here and "INVITE" or (fd.inGame and "IN GAME" or "online")), false,
				(not inP and fd.here) and function() local r = call("PartyInvite", fd.id, fd.name); toast(r.msg or "", r.ok and COL.GOOD or COL.BAD); if r.party then state.party = r.party end end
				or ((not inP and fd.inGame) and function()
					modal(fd.name, "In another server of this game. Invite them to your party (they travel here when they accept), or go to them.", {
						{"INVITE TO MY PARTY", COL.BLUE, function() local r = call("PartyInvite", fd.id, fd.name); toast(r.msg or "", r.ok and COL.GOOD or COL.BAD); if r.party then state.party = r.party end; closeModal() end},
						{"JOIN THEM", COL.GREEN, function() local r = call("JoinFriend", fd.id); toast(r.msg or "", r.ok and COL.GOOD or COL.BAD); closeModal() end},
					})
				end or nil),
				(fd.here or fd.inGame) and COL.GOOD or COL.DIM)
		end
		if shown == 0 then dim(f, "No friends online right now.") end
		local inv = bigBtn(f, "+  INVITE PLAYERS", COL.GREEN, inviteModal)
		inv.Size = UDim2.new(1, 0, 0, 38)
	end

	----------------------------------------------------------------
	--  right: leaderboard + today's shop
	----------------------------------------------------------------
	local right = clearFrame(lobby)
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.new(1, -24, 0, 104)
	right.Size = UDim2.new(0, 340, 1, -104 - 232)
	local rightList = scroll(right, 12)

	local MEDAL = {Color3.fromRGB(255, 196, 40), Color3.fromRGB(200, 210, 224), Color3.fromRGB(214, 140, 80)}
	local renderRight
	local function renderBoard(parent)
		local which = ui.lbTab
		local p = panel(parent, nil)
		local h = title(p, "LEADERBOARD", 20); h.Size = UDim2.new(1, 0, 0, 24); h.LayoutOrder = 0
		local tabs = {{text = "Warfront"}}
		for _, b in ipairs(GameConfig.DOORS.Lists.brackets or {"1v1", "2v2", "3v3"}) do table.insert(tabs, {text = b}) end
		chips(p, tabs, function(it) return it.text == ui.lbTab end, function(it) ui.lbTab = it.text; renderRight() end, 28)
		local b = state.boards[which]
		if not b or os.clock() - b.at > 60 then
			local r = call("Leaderboard", which)
			b = {at = os.clock(), rows = r.ok and r.rows or {}}
			state.boards[which] = b
		end
		local meIn = false
		for i, rw in ipairs(b.rows) do
			if i > 5 then break end
			local mine = rw.id == player.UserId
			if mine then meIn = true end
			local r = row(p, string.format("%d    %s", rw.rank, mine and "You" or rw.name), fmt(rw.value), mine, function() HX.openProfile(rw.id) end, COL.TEXT)
			if MEDAL[rw.rank] then
				local m = frame(r, MEDAL[rw.rank], 4); m.Size = UDim2.fromOffset(6, 22); m.Position = UDim2.new(0, -8, 0.5, -11)
			end
		end
		if #b.rows == 0 then dim(p, "Nobody on the board yet. Be the first.") end
		if not meIn then
			local mine = which == "Warfront" and (state.profile and state.profile.stats and state.profile.stats.kill or 0) or rating(which)
			row(p, "You", fmt(mine), true, nil, COL.TEXT)
		end
		dim(p, which == "Warfront" and "Kills this season." or (string.upper(rankOf(rating(which))) .. "  ·  rating this season."), 12)
		local all = bigBtn(p, "TOP 100  ·  SEASON REWARDS  ›", COL.BLUE, function() ui.rankBoard = which; selectTab("RANKS") end)
		all.Size = UDim2.new(1, 0, 0, 34)
	end

	local function renderShopCard(parent)
		local p = panel(parent, nil)
		local h = clearFrame(p); h.Size = UDim2.new(1, 0, 0, 38); h.LayoutOrder = 0
		local ic = iconImage(h, "Shop", 46); ic.Position = UDim2.fromOffset(-6, -6)
		local t = title(h, "TODAY'S SHOP", 20); t.Position = UDim2.fromOffset(44, 0); t.Size = UDim2.new(1, -44, 0, 24)
		local cd = title(h, "", 12, COL.ACCENT); cd.Position = UDim2.fromOffset(44, 22); cd.Size = UDim2.new(1, -44, 0, 14)
		local function tick() cd.Text = "NEW ITEMS IN " .. storeCountdown() end
		tick()
		task.spawn(function() while cd.Parent do task.wait(30); tick() end end)
		local two = clearFrame(p); two.Size = UDim2.new(1, 0, 0, 150); two.LayoutOrder = nextOrder()
		local packs = state.store and state.store.packs or {}
		local skins = state.store and state.store.skins or {}
		if packs[1] and Catalog.PACKS[packs[1]] then
			local k = packs[1]
			local th = mannequinThumb(two, Packs.loadout(k), Catalog.PACKS[k].weight, UDim2.new(0.5, -5, 1, 0), nil, {dist = 9.5})
			border(th, RARITY_COL[Packs.rarity(k)] or COL.DIM, 2, 0.2)
			local n = title(th, Catalog.PACKS[k].name, 13); n.AnchorPoint = Vector2.new(0, 1); n.Position = UDim2.new(0, 6, 1, -4); n.Size = UDim2.new(1, -12, 0, 16); n.TextTruncate = Enum.TextTruncate.AtEnd
		end
		if skins[1] and Catalog.SKIN[skins[1]] then
			local s = Catalog.SKIN[skins[1]]
			local th = weaponThumb(two, s.weapon, s.id, UDim2.new(0.5, -5, 1, 0))
			th.Position = UDim2.new(0.5, 5, 0, 0)
			border(th, RARITY_COL[s.rarity] or COL.DIM, 2, 0.2)
			local n = title(th, s.name .. " " .. (Catalog.WEAPON[s.weapon] and Catalog.WEAPON[s.weapon].name or s.weapon), 13)
			n.AnchorPoint = Vector2.new(0, 1); n.Position = UDim2.new(0, 6, 1, -4); n.Size = UDim2.new(1, -12, 0, 16); n.TextTruncate = Enum.TextTruncate.AtEnd
		end
		local go = bigBtn(p, "OPEN SHOP  ›", COL.GOLD, function() ui.shopTab = "daily"; selectTab("SHOP") end)
		go.Size = UDim2.new(1, 0, 0, 38)
	end

	----------------------------------------------------------------
	--  THE HOST'S SERVER PANEL (a custom server's owner: Hub ▸ HostServer)
	----------------------------------------------------------------
	HX.hostRemote = ReplicatedStorage:WaitForChild("HostRemote", 10)
	function HX.hostCall(op, a, b)
		if not HX.hostRemote then return {ok = false, msg = "no host service"} end
		local ok, r = pcall(HX.hostRemote.InvokeServer, HX.hostRemote, op, a, b)
		return (ok and type(r) == "table") and r or {ok = false, msg = "no answer"}
	end
	-- (HostId is only set on a custom server: Hub ▸ HostServer)
	function HX.amHost() return (roundNode:GetAttribute("HostId") or 0) == player.UserId end
	function HX.cycleIn(list_, cur, dir)
		local idx = 1
		for i, v in ipairs(list_) do if v == cur then idx = i end end
		return list_[(idx - 1 + dir) % #list_ + 1]
	end
	HX.openHostPanel = function()
		local r = HX.hostCall("Info")
		if not (r.ok and r.isHost) then toast("Only the host runs this server.", COL.BAD); return end
		local s = r.settings or {}
		local function act(op, a, b)
			local res = HX.hostCall(op, a, b)
			if res.msg and res.msg ~= "set" then toast(res.msg, res.ok and COL.GOOD or COL.BAD) end
			HX.openHostPanel()
		end
		modal("YOUR SERVER  ·  HOST CONTROLS", "", {}, function(box)
			local sc = scroll(box, 6)
			sc.Size = UDim2.new(1, 0, 0, 470)
			sc.LayoutOrder = 3
			local function line(height)
				local f = frame(sc, COL.GLASS2, 8); f.Size = UDim2.new(1, 0, 0, height or 34); f.LayoutOrder = nextOrder(); f.BackgroundTransparency = 0.1
				padding(f, 12, 6, 0, 0)
				return f
			end
			local function small(parent, text, color, x, w, fn)
				local b = button(parent, text, 12, color)
				b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, -x, 0.5, 0); b.Size = UDim2.fromOffset(w, 26)
				b.Activated:Connect(fn)
				return b
			end
			local function sel(text, value, onDir)
				local f = line()
				local l = label(f, text, 13, FONT_BODY, COL.DIM); l.Size = UDim2.new(0.45, 0, 1, 0)
				local v = label(f, value, 13, FONT, COL.TEXT); v.Position = UDim2.new(0.45, 0, 0, 0); v.Size = UDim2.new(0.55, -70, 1, 0)
				v.TextXAlignment = Enum.TextXAlignment.Right; v.TextWrapped = false; v.TextTruncate = Enum.TextTruncate.AtEnd
				small(f, "‹", COL.CARD, 32, 28, function() onDir(-1) end)
				small(f, "›", COL.CARD, 0, 28, function() onDir(1) end)
			end
			local function tog(text, key)
				local f = line()
				local l = label(f, text, 13, FONT_BODY, COL.DIM); l.Size = UDim2.new(0.7, 0, 1, 0)
				small(f, s[key] ~= false and "ON" or "OFF", s[key] ~= false and COL.GOOD or COL.CARD, 0, 60, function() act("Set", key, s[key] == false) end)
			end

			-- PLAYERS: kick, hand over
			heading(sc, string.format("Players  ·  %d here", #r.players))
			for _, p in ipairs(r.players) do
				local f = line(36)
				local t = label(f, string.format("%s%s%s", p.display, p.host and "  ★ HOST" or "", p.team ~= "" and ("  ·  " .. p.team) or ""), 14, FONT, p.host and COL.ACCENT or COL.TEXT)
				t.Size = UDim2.new(0.5, 0, 1, 0); t.TextWrapped = false; t.TextTruncate = Enum.TextTruncate.AtEnd
				local kd = label(f, string.format("%d K  ·  %d D", p.kills, p.deaths), 12, FONT_BODY, COL.DIM)
				kd.Position = UDim2.new(0.5, 0, 0, 0); kd.Size = UDim2.new(0.5, -170, 1, 0)
				if p.id ~= player.UserId then
					small(f, "KICK", COL.RED, 0, 70, function()
						modal("KICK " .. string.upper(p.display) .. "?", "They're removed from this server and can't come back while it runs.",
							{{"KICK", COL.RED, function() act("Kick", p.id) end}})
					end)
					small(f, "MAKE HOST", COL.BLUE, 76, 90, function() act("MakeHost", p.id) end)
				end
			end

			-- BOTS
			heading(sc, string.format("Bots  ·  %d filling in, %d practice", r.bots or 0, r.extraBots or 0))
			tog("Bots fill empty places", "bots")
			local counts = {0, 2, 4, 6, 8, 10, 12, 16, 20, 24}
			sel("Fighters in all (players + bots)", tostring(s.botCount or 8), function(d) act("Set", "botCount", HX.cycleIn(counts, s.botCount or 8, d)) end)
			sel("Bot skill", s.botSkill or "Mixed", function(d) act("Set", "botSkill", HX.cycleIn(GameConfig.BOT_SKILLS, s.botSkill or "Mixed", d)) end)
			do
				local f = line(40)
				local l = label(f, "Practice bots where you stand", 13, FONT_BODY, COL.DIM); l.Size = UDim2.new(0.4, 0, 1, 0)
				ui.hostBotSkill = ui.hostBotSkill or "Knight"
				small(f, "CLEAR", COL.RED, 0, 66, function() act("ClearBots") end)
				small(f, "+3", COL.GREEN, 72, 44, function() act("SpawnBots", 3, ui.hostBotSkill) end)
				small(f, "+1", COL.GREEN, 122, 44, function() act("SpawnBots", 1, ui.hostBotSkill) end)
				small(f, string.upper(ui.hostBotSkill), COL.CARD, 172, 96, function()
					local skills = {"Squire", "Knight", "Champion"}
					ui.hostBotSkill = HX.cycleIn(skills, ui.hostBotSkill, 1)
					HX.openHostPanel()
				end)
			end

			-- THE ROUND: mode, map, end it
			heading(sc, "The round")
			local nextMode = r.nextMode ~= "" and r.nextMode or r.mode
			local md = GameConfig.MODES[nextMode]
			sel("Next mode", (md and md.name or nextMode) .. (r.nextMode == "" and "  (same)" or ""), function(d)
				act("NextMode", HX.cycleIn(r.modes, nextMode, d))
			end)
			local maps = r.maps or {}
			if #maps > 0 then
				sel("Next map", r.nextMap ~= "" and GameConfig.mapTitle(r.nextMap) or "rotate", function(d)
					act("NextMap", HX.cycleIn(maps, r.nextMap ~= "" and r.nextMap or maps[1], d))
				end)
			end
			do
				local f = line(40)
				local l = label(f, "Mode and map changes start the next round.", 12, FONT_BODY, COL.DIM); l.Size = UDim2.new(0.6, 0, 1, 0)
				small(f, "END ROUND NOW", COL.RED, 0, 150, function()
					modal("END THIS ROUND?", "Everyone goes to the results and the next round starts after the break.",
						{{"END IT", COL.RED, function() act("EndRound") end}})
				end)
			end

			-- THE RULES
			heading(sc, "Rules")
			tog("Friendly fire", "friendlyFire")
			tog("Respawns", "respawns")
			tog("Weapons on the ground", "groundWeapons")
			local lengths = {180, 300, 480, 600, 900, 1200}
			sel("Round length (next round)", string.format("%d min", math.floor((s.roundLength or 300) / 60)), function(d)
				act("Set", "roundLength", HX.cycleIn(lengths, s.roundLength or 300, d))
			end)
			local limits = {2, 4, 6, 8, 12, 16, 24, 32, 40}
			sel("Player limit", tostring(s.limit or 12), function(d) act("Set", "limit", HX.cycleIn(limits, s.limit or 12, d)) end)
			local access = {"Public", "Friends", "Locked"}
			sel("Who can join", s.access == "Friends" and "Friends of players" or (s.access == "Locked" and "Nobody new" or "Anyone"), function(d)
				act("Set", "access", HX.cycleIn(access, s.access or "Public", d))
			end)
		end, 640)
	end

	function HX.renderHostCard(parent)
		local p = panel(parent, nil)
		local h = title(p, "YOUR SERVER", 20); h.Size = UDim2.new(1, 0, 0, 24); h.LayoutOrder = 0
		dim(p, "You're the host: players, bots, the mode and map, the rules.", 12)
		local b = bigBtn(p, "SERVER PANEL  ›", COL.GOLD, HX.openHostPanel)
		b.Size = UDim2.new(1, 0, 0, 38)
	end

	renderRight = function()
		clear(rightList)
		if HX.amHost() then HX.renderHostCard(rightList) end
		renderBoard(rightList)
		renderShopCard(rightList)
	end
	roundNode:GetAttributeChangedSignal("HostId"):Connect(function() if open then renderRight() end end)

	----------------------------------------------------------------
	--  the dock
	----------------------------------------------------------------
	local dock = clearFrame(lobby)
	dock.AnchorPoint = Vector2.new(0, 1)
	dock.Position = UDim2.new(0, 24, 1, -22)
	dock.Size = UDim2.fromOffset(9 * 112 + 8 * 14, 112)
	hlist(dock, 14)
	local DOCK = {{"LOADOUT", "Loadout", "CLASSES"}, {"ARMORY", "Armory", "ARMORY"}, {"SHOP", "Shop", "SHOP"}, {"PASS", "Pass", "PASS"}, {"HATCHERY", "Hatchery", "HATCHERY"},
		{"TRADE", "Shop", "TRADE"}, {"TASKS", "Tasks", "TASKS"}, {"WARDROBE", "Wardrobe", "APPEARANCE"}, {"SETTINGS", "Settings", "SETTINGS"}}
	for i, d in ipairs(DOCK) do
		local b, badge = dockTile(dock, d[2], d[1])
		b.Name = "Dock_" .. d[1]
		b.LayoutOrder = i
		b.Activated:Connect(function() selectTab(d[3]) end)
		dockBadges[d[3]] = badge
	end

	----------------------------------------------------------------
	--  PLAY (and everything that takes its place)
	----------------------------------------------------------------
	local playArea = clearFrame(lobby)
	playArea.AnchorPoint = Vector2.new(1, 1)
	playArea.Position = UDim2.new(1, -24, 1, -22)
	playArea.Size = UDim2.fromOffset(384, 220)
	local playHolder, playFace = fatButton(playArea, "PLAY", COL.GREEN, 56)
	playHolder.Name = "Play"
	playHolder.AnchorPoint = Vector2.new(1, 1)
	playHolder.Position = UDim2.new(1, 0, 1, 0)
	playHolder.Size = UDim2.fromOffset(384, 114)
	local secHolder, secFace = fatButton(playArea, "", COL.BLUE, 22)
	secHolder.Name = "Secondary"
	secHolder.AnchorPoint = Vector2.new(1, 1)
	secHolder.Position = UDim2.new(1, 0, 1, -124)
	secHolder.Size = UDim2.fromOffset(384, 56)
	local statusPill = frame(playArea, COL.GLASS, 14)
	statusPill.BackgroundTransparency = 0.15
	statusPill.AnchorPoint = Vector2.new(1, 1)
	statusPill.Position = UDim2.new(1, 0, 1, -124)
	statusPill.Size = UDim2.fromOffset(384, 32)
	local statusText = title(statusPill, "", 14)
	statusText.Size = UDim2.fromScale(1, 1)
	statusText.TextXAlignment = Enum.TextXAlignment.Center
	statusText.TextTruncate = Enum.TextTruncate.AtEnd
	local playAction, secAction = nil, nil
	playFace.Activated:Connect(function() if playAction then playAction() end end)
	secFace.Activated:Connect(function() if secAction then secAction() end end)

	local function where()
		local modeName = roundNode:GetAttribute("ModeName") or ""
		local map = roundNode:GetAttribute("MapName") or roundNode:GetAttribute("Map") or ""
		if inHub() then return string.format("COURTYARD  ·  %d HERE", #Players:GetPlayers()) end
		return string.upper(((state.name or "") ~= "" and (state.name .. "  ·  ") or "") .. modeName .. (map ~= "" and ("  ·  " .. map) or ""))
	end

	renderPlayArea = function()
		local inMatch = not inHub()
		local leader, party = isLeader(), inParty()
		local me
		if state.party then for _, m in ipairs(state.party.members or {}) do if m.id == player.UserId then me = m end end end
		local secText, secColor = nil, nil
		local status
		if inMatch then
			paintFat(playHolder, playFace, alive() and "RESUME" or "BACK", COL.GREEN)
			playAction = hide
			secText, secColor, secAction = "LEAVE MATCH", COL.RED, leaveMatch
			status = where()
		elseif state.matchFound then
			paintFat(playHolder, playFace, "MATCH FOUND!", COL.GREEN)
			playAction = nil
			status = "TRAVELLING TO YOUR MATCH…"
		elseif state.queue then
			local s = math.floor(os.clock() - (state.queue.since or os.clock()))
			paintFat(playHolder, playFace, string.format("SEARCHING  %d:%02d", math.floor(s / 60), s % 60), COL.YELLOW)
			playAction = nil
			secText, secColor, secAction = "CANCEL", COL.RED, cancelQueue
			status = string.format("%s %s  ·  WINDOW ±%d", state.queue.ranked and "RANKED" or "CASUAL", state.queue.bracket or "", math.min(1000, 100 + 40 * math.floor(s / 4)))
		elseif party and not leader then
			local ready = me and me.ready
			paintFat(playHolder, playFace, ready and "READY ✔" or "READY UP", ready and Color3.fromRGB(70, 90, 120) or COL.GREEN)
			playAction = function()
				local r = call("PartyReady", not ready)
				if r.party then state.party = r.party end
				if not r.ok then toast(r.msg or "", COL.BAD) end
				renderStage(); renderPlayArea()
			end
			status = "THE LEADER PICKS THE MODE"
		else
			paintFat(playHolder, playFace, "PLAY", COL.GREEN)
			playAction = function() selectTab("MODES") end
			if not alive() then secText, secColor, secAction = "ENTER COURTYARD", COL.BLUE, enterCourtyard end
			if party then
				local ready = 0
				for _, m in ipairs(state.party.members) do if m.ready or m.leader then ready += 1 end end
				status = string.format("PARTY %d / %d  ·  %d READY", #state.party.members, state.partyMax, ready)
			else
				status = "SOLO  ·  " .. where()
			end
		end
		secHolder.Visible = secText ~= nil
		if secText then paintFat(secHolder, secFace, secText, secColor) end
		statusPill.Position = secText and UDim2.new(1, 0, 1, -188) or UDim2.new(1, 0, 1, -124)
		statusText.Text = status or ""
		-- the top bar's close: when there is somewhere to go back to
		topCloseHolder.Visible = currentTab == "PLAY" and (alive() or inMatch)
		-- dock badges: NEW on the shop when the day turned since you looked, open tasks
		local sb = dockBadges.SHOP
		if sb then sb.Visible = state.store ~= nil and ui.shopSeen ~= state.store.day; sb.Text = "NEW" end
		local pb = dockBadges.PASS
		if pb and passClaimable then local n = passClaimable(); pb.Visible = n > 0; pb.Text = tostring(n) end
		local tb = dockBadges.TASKS
		if tb then
			local left = 0
			for _, ct in ipairs(state.contracts or {}) do if not ct.done and not ct.weekly then left += 1 end end
			tb.Visible = left > 0; tb.Text = tostring(left)
		end
		local hb = dockBadges.HATCHERY
		if hb then local n = Preview.readyEggs(); hb.Visible = n > 0; hb.Text = tostring(n) end
	end

	render.PLAY = function()
		-- the town crier: once a session, this week's drop (and any event running)
		local cur = HX.Drops.current()
		if cur and ui.crierSeen ~= cur.id and state.profile then
			ui.crierSeen = cur.id
			local hs = cur.headline and Catalog.SKIN[cur.headline]
			local evs = {}
			for _, e in ipairs(HX.Drops.events()) do table.insert(evs, e.name .. " ends in " .. HX.span(HX.Drops.time(e.to) - HX.Drops.now())) end
			local nxt, at = HX.Drops.next()
			task.defer(modal, string.upper(cur.tag or "NEW") .. "  ·  " .. string.upper(cur.name),
				(cur.blurb or "") .. (#evs > 0 and ("\n" .. table.concat(evs, "  ·  ")) or "") .. (nxt and ("\nNext drop in " .. HX.span(at - HX.Drops.now()) .. ": ???") or ""),
				{{"SEE IT IN THE SHOP", cur.color or COL.GOLD, function()
					closeModal()
					ui.shopTab = cur.crate and "crates" or "daily"; ui.crate = cur.crate or ui.crate; ui.crateItem = nil
					selectTab("SHOP")
				end}},
				hs and function(box)
					local th = weaponStage(box, hs.weapon, hs.id, UDim2.new(1, 0, 0, 280)); th.LayoutOrder = 5
					border(th, cur.color or COL.ACCENT, 3, 0)
				end or nil, 620)
		end
		loadServers(false)
		local fr = call("Friends"); if fr.ok then state.friends = fr.friends or {} end
		renderStage()
		renderLeft()
		renderRight()
		renderPlayArea()
	end
	-- the queue clock on the PLAY button
	task.spawn(function()
		while true do
			task.wait(1)
			if open and currentTab == "PLAY" and state.queue and not state.matchFound then renderPlayArea() end
		end
	end)
	bus.Event:Connect(function(what) if what == "PartyChanged" and open and currentTab == "PLAY" then renderStage(); renderPlayArea() end end)
end

--------------------------------------------------------------------
--  MODES — the board PLAY opens: big tiles, each with a little 3D scene
--------------------------------------------------------------------
do
	local f = tabFrame.MODES

	-- the scenes' soldiers wear the game's own sets and weapons (with skins, so
	-- the trims show off a little)
	local sceneSets
	local function setsForScenes()
		if sceneSets then return sceneSets end
		local byKey = {}
		for _, pc in ipairs(Catalog.PIECES) do
			local key = pc.set or pc.pack
			byKey[key] = byKey[key] or {weight = pc.weight, key = key}
			byKey[key][pc.slot] = byKey[key][pc.slot] or pc.id
		end
		sceneSets = {}
		for _, s in pairs(byKey) do if s.helmet and s.top then table.insert(sceneSets, s) end end
		table.sort(sceneSets, function(a, b) return a.key < b.key end)
		return sceneSets
	end
	local SCENE_WEAPONS = {{"Longsword", "Longsword:Royal"}, {"Greatsword", "Greatsword:Gilded"}, {"Halberd", "Halberd:Frostbite"}, {"WarAxe", "WarAxe:Bloodrust"},
		{"Mace", "Mace:Ember"}, {"Spear", "Spear:Bronzed"}, {"ArmingSword", "ArmingSword:Crowfeather"}, {"Zweihander", "Zweihander:Royal"}}
	local POSE = {
		guard = {rs = {95, 0, 10}, ls = {40, 0, -20}, rh = {-12, 0, 0}, lh = {18, 0, 0}},
		swing = {rs = {165, 0, 25}, ls = {30, 0, -12}, rh = {-20, 0, 0}, lh = {24, 0, 0}},
		lunge = {rs = {80, 0, 0}, ls = {-25, 0, -15}, rh = {-38, 0, 0}, lh = {32, 0, 0}},
		cheer = {rs = {172, 0, 12}, ls = {0, 0, -18}},
		rest  = {rs = {12, 0, 6}, ls = {10, 0, -6}},
		wave  = {rs = {0, 0, 150}, ls = {6, 0, -6}},
	}
	local COLORS = {
		{Primary = "Royal", Secondary = "Slate", Accent = "Ochre", Metal = "Ash"},
		{Primary = "Slate", Secondary = "Umber", Accent = "Ochre", Metal = "Ash"},
	}
	local function soldier(world, i, o)
		local sets = setsForScenes()
		local s = sets[(i - 1) % math.max(#sets, 1) + 1] or {}
		local w = SCENE_WEAPONS[(i - 1) % #SCENE_WEAPONS + 1]
		local skin = Catalog.SKIN[w[2]] and w[2] or nil
		local lo = {helmet = o.noHelm and nil or s.helmet, top = s.top, bottom = s.bottom, weapon = o.unarmed and nil or w[1], weaponSkin = skin,
			colors = COLORS[(i - 1) % #COLORS + 1]}
		local app = {}
		for k, v in pairs(Catalog.BODY.defaults) do app[k] = v end
		local faces = Catalog.BODY.faces
		if #faces > 0 then app.face = faces[(i * 3 - 1) % #faces + 1].id end
		app.skin = (i % #Catalog.BODY.skins) + 1
		local rig = dressedRig({loadout = lo, weight = s.weight, team = o.team, pose = o.pose, appearance = app})
		rig.Parent = world
		rig:PivotTo(CFrame.new(o.pos) * CFrame.Angles(0, math.rad(o.yaw or 0), 0))
		return rig
	end
	local function ground(world, size, color)
		local g = Instance.new("Part")
		g.Anchored = true
		g.Shape = Enum.PartType.Cylinder
		g.Size = Vector3.new(0.4, size, size)
		g.CFrame = CFrame.new(0, -3.2, 0) * CFrame.Angles(0, 0, math.pi / 2)
		g.Color = color or Color3.fromRGB(96, 110, 80)
		g.Material = Enum.Material.Grass
		g.Parent = world
		return g
	end
	local function dummy(world, pos)
		local m = Instance.new("Model")
		local function p(size, cf, color, shape)
			local q = Instance.new("Part"); q.Anchored = true; q.Size = size; q.CFrame = cf; q.Color = color; q.Material = Enum.Material.Wood
			if shape then q.Shape = shape end
			q.Parent = m
			return q
		end
		p(Vector3.new(0.4, 6, 0.4), CFrame.new(pos + Vector3.new(0, -0.2, 0)), Color3.fromRGB(110, 80, 50))
		p(Vector3.new(3, 0.35, 0.35), CFrame.new(pos + Vector3.new(0, 1.3, 0)), Color3.fromRGB(110, 80, 50))
		local sack = p(Vector3.new(1.6, 2.2, 1.1), CFrame.new(pos + Vector3.new(0, 0.6, 0)), Color3.fromRGB(196, 170, 120))
		sack.Material = Enum.Material.Fabric
		local head = p(Vector3.new(1.2, 1.2, 1.2), CFrame.new(pos + Vector3.new(0, 2.3, 0)), Color3.fromRGB(196, 170, 120), Enum.PartType.Ball)
		head.Material = Enum.Material.Fabric
		m.Parent = world
	end

	-- scene builders: (world, cam) → fill the world, aim the camera
	local SCENES = {}
	SCENES.Warfront = function(world, cam)
		ground(world, 40, Color3.fromRGB(90, 104, 70))
		local spots = {{-5, -1, 70, "A", "swing"}, {-1.5, 0.5, -110, "B", "guard"}, {1.6, -1.2, 80, "A", "lunge"}, {5, 0.2, -95, "B", "swing"},
			{-7.5, 3, 60, "A", "guard"}, {8, 3.2, -120, "B", "lunge"}, {-2.5, 5, 90, "A", "cheer"}, {3, 5.5, -80, "B", "guard"}}
		for i, sp in ipairs(spots) do soldier(world, i, {pos = Vector3.new(sp[1], 0, sp[2]), yaw = sp[3], team = sp[4], pose = POSE[sp[5]]}) end
		cam.FieldOfView = 40
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 4.5, -17), Vector3.new(0, -0.5, 2))
	end
	SCENES.Horde = function(world, cam)
		-- two back to back, the horde closing in
		ground(world, 30, Color3.fromRGB(196, 168, 110))
		soldier(world, 1, {pos = Vector3.new(0.9, 0, 0), yaw = -60, team = "A", pose = POSE.guard})
		soldier(world, 2, {pos = Vector3.new(-0.9, 0, 0.2), yaw = 120, team = "A", pose = POSE.swing})
		local ring = {{5, 2, -100}, {4.2, -2.6, -60}, {-4.6, 2.6, 110}, {-5.2, -1.6, 70}, {1.6, 5, -150}, {-1.8, 5.4, 160}}
		for i, r in ipairs(ring) do soldier(world, i + 2, {pos = Vector3.new(r[1], 0, r[2]), yaw = r[3], team = "B", pose = (i % 2 == 0) and POSE.lunge or POSE.swing}) end
		cam.FieldOfView = 44
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 6.5, -14), Vector3.new(0, -0.6, 1.5))
	end
	SCENES.Training = function(world, cam)
		ground(world, 20, Color3.fromRGB(150, 130, 90))
		soldier(world, 3, {pos = Vector3.new(1.4, 0, 0), yaw = 70, pose = POSE.swing})
		dummy(world, Vector3.new(-2, 0, 0.3))
		cam.FieldOfView = 40
		cam.CFrame = CFrame.lookAt(Vector3.new(0.5, 1.6, -11), Vector3.new(-0.2, -0.3, 0))
	end
	SCENES.Courtyard = function(world, cam)
		-- three friends in the yard, one waving
		ground(world, 20, Color3.fromRGB(140, 140, 132))
		soldier(world, 5, {pos = Vector3.new(-2.2, 0, 0.6), yaw = 30, pose = POSE.wave, noHelm = true, unarmed = true})
		soldier(world, 2, {pos = Vector3.new(0.6, 0, -0.4), yaw = -10, pose = POSE.rest, noHelm = true})
		soldier(world, 7, {pos = Vector3.new(3.2, 0, 1), yaw = -40, pose = POSE.rest})
		cam.FieldOfView = 40
		cam.CFrame = CFrame.lookAt(Vector3.new(0.4, 1.6, -14.5), Vector3.new(0.4, -0.5, 0))
	end
	-- n pairs face off; each pair stands a step further back, so from the
	-- tile's camera (a little above) every fighter shows
	local function duel(n)
		return function(world, cam)
			ground(world, 30, Color3.fromRGB(196, 168, 110))
			for i = 1, n do
				-- the pairs line up on a diagonal: a step back and a step aside each
				local z = (i - 1) * 3.2
				local shift = (i - (n + 1) / 2) * 2.4
				soldier(world, i, {pos = Vector3.new(shift + 1.8, 0, z), yaw = -90, team = "A", pose = (i % 2 == 1) and POSE.guard or POSE.swing})
				soldier(world, i + 4, {pos = Vector3.new(shift - 1.8, 0, z + 0.5), yaw = 90, team = "B", pose = (i % 2 == 1) and POSE.swing or POSE.guard})
			end
			local back = (n - 1) * 3.4
			cam.FieldOfView = 42
			cam.CFrame = CFrame.lookAt(Vector3.new(0, 2.6 + n * 1.2, -(11 + n * 1.5)), Vector3.new(0, -0.4 + n * 0.25, back * 0.45))
		end
	end
	SCENES["1v1"] = duel(1)
	SCENES["2v2"] = duel(2)
	SCENES["3v3"] = duel(3)
	SCENES.Ranked = function(world, cam)
		-- the champion stands on the left of the card (world +X is screen-left here)
		local g = ground(world, 6, Color3.fromRGB(255, 196, 40))
		g.Material = Enum.Material.Neon
		g.Transparency = 0.3
		g.CFrame = CFrame.new(4.2, -3.2, 0) * CFrame.Angles(0, 0, math.pi / 2)
		soldier(world, 6, {pos = Vector3.new(4.2, 0, 0), yaw = 25, pose = POSE.cheer})
		cam.FieldOfView = 40
		cam.CFrame = CFrame.lookAt(Vector3.new(0.4, 0.9, -11), Vector3.new(0, -0.2, 0))
	end

	-- a tile: a glossy coloured card with a 3D scene, a big title, a line
	local function tile(o)
		local holder = frame(f, darker(o.color, 0.45), 20)
		holder.Name = "Mode_" .. o.key
		holder.Position, holder.Size = o.pos, o.size
		local face = Instance.new("TextButton")
		face.Text = ""
		face.AutoButtonColor = false
		face.BackgroundColor3 = o.color
		face.Size = UDim2.new(1, 0, 1, -6)
		face.ClipsDescendants = true
		face.Parent = holder
		Instance.new("UICorner", face).CornerRadius = UDim.new(0, 20)
		do
			local g = Instance.new("UIGradient", face)
			g.Rotation = 90
			g.Color = ColorSequence.new(WHITE, Color3.new(0.42, 0.42, 0.5))
		end
		local vp = Instance.new("ViewportFrame")
		vp.BackgroundTransparency = 1
		vp.Size = UDim2.fromScale(1, 1)
		vp.Ambient = Color3.fromRGB(160, 154, 146)
		vp.LightColor = Color3.fromRGB(255, 244, 228)
		vp.LightDirection = Vector3.new(-0.5, -1, 0.4)
		vp.Parent = face
		local world = Instance.new("WorldModel"); world.Parent = vp
		local cam = Instance.new("Camera"); cam.Parent = vp
		vp.CurrentCamera = cam
		local shade = frame(face, Color3.new(0, 0, 0))
		shade.Size = UDim2.fromScale(1, 1)
		do
			local g = Instance.new("UIGradient", shade)
			g.Rotation = 90
			g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 0.25)})
		end
		local t = title(face, o.title, o.big and 46 or 36)
		t.AnchorPoint = Vector2.new(0, 1)
		t.Position = UDim2.new(0, 18, 1, o.sub and -34 or -14)
		t.Size = UDim2.new(1, -36, 0, o.big and 50 or 40)
		local sub
		if o.sub then
			sub = title(face, o.sub, 15, Color3.fromRGB(230, 236, 250))
			sub.AnchorPoint = Vector2.new(0, 1)
			sub.Position = UDim2.new(0, 20, 1, -12)
			sub.Size = UDim2.new(1, -40, 0, 20)
			sub.TextTruncate = Enum.TextTruncate.AtEnd
		end
		local tag
		if o.tag then
			tag = title(face, o.tag, 13)
			tag.BackgroundTransparency = 0
			tag.BackgroundColor3 = o.tagColor or COL.RED
			tag.Position = UDim2.fromOffset(14, 14)
			tag.AutomaticSize = Enum.AutomaticSize.X
			tag.Size = UDim2.fromOffset(0, 24)
			padding(tag, 10, 10, 0, 0)
			Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 8)
		end
		local count = title(face, "", 14)
		count.AnchorPoint = Vector2.new(1, 0)
		count.Position = UDim2.new(1, -14, 0, 16)
		count.Size = UDim2.fromOffset(220, 20)
		count.TextXAlignment = Enum.TextXAlignment.Right
		local lock = frame(face, Color3.new(0, 0, 0))
		lock.Size = UDim2.fromScale(1, 1)
		lock.BackgroundTransparency = 0.45
		lock.Visible = false
		local lockText = title(lock, "", 20)
		lockText.Size = UDim2.fromScale(1, 1)
		lockText.TextXAlignment = Enum.TextXAlignment.Center
		lockText.TextWrapped = true
		hoverScale(holder, face, 1.025)
		face.Activated:Connect(function() if not lock.Visible and o.onClick then o.onClick() end end)
		return {holder = holder, face = face, world = world, cam = cam, sub = sub, count = count, lock = lock, lockText = lockText, scene = o.scene}
	end

	local tiles = {}
	local function partyLock(size)
		if inParty() and not isLeader() then return "THE PARTY LEADER\nPICKS THE MODE" end
		if size and partySize() > size then return string.format("PARTY TOO BIG\n(%d / %d)", partySize(), size) end
		return nil
	end
	-- row 1: Warfront · Training · Courtyard
	tiles.Warfront = tile({key = "Warfront", title = "WARFRONT", sub = "Big battles  ·  vote the next battle", big = true, color = Color3.fromRGB(214, 70, 60),
		pos = UDim2.new(0, 0, 0, 0), size = UDim2.new(0.4, -8, 0.46, -6), scene = "Warfront", tag = "POPULAR", tagColor = COL.RED,
		onClick = function() goDoor("Warfront") end})
	tiles.Horde = tile({key = "Horde", title = "HORDE", sub = "You + party vs waves of bots", color = Color3.fromRGB(150, 110, 60),
		pos = UDim2.new(0.4, 6, 0, 0), size = UDim2.new(0.2, -10, 0.46, -6), scene = "Horde", tag = "NEW", tagColor = COL.GOLD,
		onClick = function() goDoor("Horde") end})
	tiles.Training = tile({key = "Training", title = "TRAINING", sub = "Your own yard  ·  drills pay Marks", color = Color3.fromRGB(70, 150, 90),
		pos = UDim2.new(0.6, 4, 0, 0), size = UDim2.new(0.2, -8, 0.46, -6), scene = "Training",
		onClick = function() goDoor("Tiltyard") end})
	tiles.Courtyard = tile({key = "Courtyard", title = "COURTYARD", sub = "Hang out  ·  duel in the ring", color = Color3.fromRGB(70, 120, 210),
		pos = UDim2.new(0.8, 4, 0, 0), size = UDim2.new(0.2, -4, 0.46, -6), scene = "Courtyard",
		onClick = function()
			if inHub() then
				if alive() then hide() else enterCourtyard() end
			else goDoor("Courtyard") end
		end})
	-- row 2: The Lists (casual) · Ranked
	local listsLabel = title(f, "THE LISTS  ·  CASUAL", 16, COL.DIM)
	listsLabel.Position = UDim2.new(0, 4, 0.46, 6)
	listsLabel.Size = UDim2.new(0.6, 0, 0, 20)
	local BRACKET_COL = {Color3.fromRGB(240, 150, 40), Color3.fromRGB(60, 170, 200), Color3.fromRGB(130, 90, 220)}
	for i, b in ipairs(GameConfig.DOORS.Lists.brackets or {"1v1", "2v2", "3v3"}) do
		local size = tonumber(b:match("^(%d)")) or 1
		tiles[b] = tile({key = b, title = b, sub = size == 1 and "Duel  ·  best of 5" or ("Teams of " .. size .. "  ·  best of 5"), color = BRACKET_COL[i] or COL.BLUE,
			pos = UDim2.new((i - 1) * 0.19, 0, 0.46, 32), size = UDim2.new(0.19, -12, 0.42, -32), scene = b,
			onClick = function() ui.bracket = b; ui.ranked = false; findMatch() end})
	end
	-- the ranked card
	local rk = tile({key = "Ranked", title = "RANKED", color = Color3.fromRGB(120, 70, 200), big = true,
		pos = UDim2.new(0.57, 0, 0.46, 32), size = UDim2.new(0.43, 0, 0.42, -32), scene = "Ranked", tag = "SEASON", tagColor = COL.GOLD})
	tiles.Ranked = rk
	rk.face.Active = false
	local rkInfo = clearFrame(rk.face)
	rkInfo.Position = UDim2.new(0.42, 0, 0, 14)
	rkInfo.Size = UDim2.new(0.58, -16, 1, -28)
	vlist(rkInfo, 6)

	-- bottom strip
	local strip = clearFrame(f)
	strip.AnchorPoint = Vector2.new(0, 1)
	strip.Position = UDim2.new(0, 0, 1, 0)
	strip.Size = UDim2.new(1, 0, 0, 58)
	local browseH, browse = fatButton(strip, "SERVER BROWSER", COL.BLUE, 20)
	browseH.Size = UDim2.fromOffset(280, 58)
	browse.Activated:Connect(function() ui.customOpen = false; selectTab("SERVERS") end)
	local customH, customB = fatButton(strip, "CREATE CUSTOM", COL.GLASS2, 20)
	customH.Position = UDim2.fromOffset(296, 0)
	customH.Size = UDim2.fromOffset(280, 58)
	customB.Activated:Connect(function() ui.customOpen = true; selectTab("SERVERS") end)
	local note = title(strip, "", 14, COL.DIM)
	note.Position = UDim2.fromOffset(600, 0)
	note.Size = UDim2.new(1, -600, 1, 0)
	note.TextWrapped = true

	local built = false
	local function buildScenes()
		if built then return end
		built = true
		for _, t in pairs(tiles) do
			local fn = t.scene and SCENES[t.scene]
			if fn then local ok, err = pcall(fn, t.world, t.cam); if not ok then warn("[HubMenu] scene", t.scene, err) end end
			task.wait()
		end
	end

	local function renderRanked()
		clear(rkInfo)
		local r = rating(ui.bracket)
		local rkName = rankOf(r)
		local h = title(rkInfo, string.upper(rkName), 30, COL.ACCENT); h.Size = UDim2.new(1, 0, 0, 34); h.LayoutOrder = 1
		local rt = title(rkInfo, fmt(r) .. "  RATING  ·  " .. ui.bracket, 16); rt.Size = UDim2.new(1, 0, 0, 20); rt.LayoutOrder = 2
		local step = ECON.rankStep or 250
		local barH = clearFrame(rkInfo); barH.Size = UDim2.new(1, 0, 0, 16); barH.LayoutOrder = 3
		progressBar(barH, ((r - 1000) % step) / step, COL.GOLD, string.format("%d TO THE NEXT TIER", step - ((r - 1000) % step)), 16)
		local played = state.profile and state.profile.placements and state.profile.placements[ui.bracket] or 0
		local pl = title(rkInfo, played < (ECON.placementMatches or 10) and string.format("PLACEMENTS  %d / %d", played, ECON.placementMatches or 10) or ("SEASON " .. tostring(ECON.seasonDays or 42) .. " DAYS  ·  TOP 100 GET A SKIN"), 13, COL.DIM)
		pl.Size = UDim2.new(1, 0, 0, 16); pl.LayoutOrder = 4
		local bl = {}
		for _, b in ipairs(GameConfig.DOORS.Lists.brackets or {"1v1", "2v2", "3v3"}) do table.insert(bl, {text = b}) end
		local c = chips(rkInfo, bl, function(it) return it.text == ui.bracket end, function(it) ui.bracket = it.text; renderRanked() end, 32)
		c.LayoutOrder = 5
		local goH, go = fatButton(rkInfo, "FIND RANKED", COL.GOLD, 24)
		goH.LayoutOrder = 6
		goH.Size = UDim2.new(1, 0, 0, 56)
		local size = tonumber(ui.bracket:match("^(%d)")) or 1
		local lockWhy = partyLock(size)
		if lockWhy or state.queue then paintFat(goH, go, state.queue and "SEARCHING…" or lockWhy:gsub("\n", " "), Color3.fromRGB(90, 90, 110)) end
		go.Activated:Connect(function()
			if state.queue then return end
			if lockWhy then toast(lockWhy:gsub("\n", " "), COL.BAD); return end
			ui.ranked = true
			findMatch()
		end)
	end

	render.MODES = function()
		loadServers(false)
		local counts, servers = doorCounts()
		tiles.Warfront.count.Text = string.format("%d FIGHTING  ·  %d SERVER%s", counts.Warfront or 0, servers.Warfront or 0, (servers.Warfront or 0) == 1 and "" or "S")
		tiles.Courtyard.count.Text = string.format("%d HERE", counts.Courtyard or #Players:GetPlayers())
		tiles.Training.count.Text = "YOU + PARTY"
		tiles.Horde.count.Text = "YOU + PARTY  ·  BOTS"
		for _, key in ipairs({"Warfront", "Training", "Horde"}) do
			local why = partyLock(nil)
			tiles[key].lock.Visible = why ~= nil
			tiles[key].lockText.Text = why or ""
		end
		tiles.Courtyard.lock.Visible = false
		if inHub() then tiles.Courtyard.sub.Text = alive() and "You're here  ·  back to it" or "Spawn in and walk around"
		else tiles.Courtyard.sub.Text = "Back to the hub  ·  duel in the ring" end
		for _, b in ipairs(GameConfig.DOORS.Lists.brackets or {"1v1", "2v2", "3v3"}) do
			local size = tonumber(b:match("^(%d)")) or 1
			local why = state.queue and "ALREADY SEARCHING" or partyLock(size)
			tiles[b].lock.Visible = why ~= nil
			tiles[b].lockText.Text = why or ""
		end
		renderRanked()
		note.Text = state.studio and "Studio: there are no teleports, so PLAY switches this server's mode." or
			(partyBlocked() and string.upper(partyBlocked()) or "Your party travels with you. Everyone readies, the leader picks.")
		task.spawn(buildScenes)
	end
end

--------------------------------------------------------------------
--  LOADOUT (CLASSES) — one loadout per class; anything locked can be
--  tried on: it shows on your mannequin with how to get it
--------------------------------------------------------------------
do
	local f = tabFrame.CLASSES
	local left = clearFrame(f); left.Size = UDim2.new(1, -392, 1, 0)
	local classRow = clearFrame(left); classRow.Size = UDim2.new(1, 0, 0, 118)
	hlist(classRow, 10)
	local stageHolder = clearFrame(left); stageHolder.Position = UDim2.new(0, 0, 0, 128); stageHolder.Size = UDim2.new(1, 0, 1, -128 - 72)
	local _, stage, stageHint = stageBlock(stageHolder, "", {dist = 10, platform = COL.BLUE})
	local tryBanner = frame(stageHolder, COL.GLASS, 14)
	tryBanner.BackgroundTransparency = 0.08
	tryBanner.Position = UDim2.fromOffset(14, 14)
	tryBanner.Size = UDim2.new(0.34, 0, 0, 0)
	tryBanner.AutomaticSize = Enum.AutomaticSize.Y
	tryBanner.Visible = false
	tryBanner.ZIndex = 6
	border(tryBanner, COL.ACCENT, 2, 0.2)
	padding(tryBanner, 14, 14, 10, 10)
	local foot = clearFrame(left); foot.AnchorPoint = Vector2.new(0, 1); foot.Position = UDim2.new(0, 0, 1, 0); foot.Size = UDim2.new(1, 0, 0, 60)
	screenFoot.CLASSES = foot
	local right = clearFrame(f); right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 380, 1, 0)
	local list = scroll(right, 10)

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
	-- what the mannequin wears: the edit, with the tried-on item over it
	local function worn()
		local lo = edit()
		local t = ui.tryOn
		if not t or t.class ~= ui.editing then return lo end
		local w = {colors = lo.colors}
		for k, v in pairs(lo) do if k ~= "colors" then w[k] = v end end
		if t.slot == "weapon" then w.weapon = t.id; w.weaponSkin = nil
		elseif t.slot == "weaponSkin" then w.weapon = Catalog.SKIN[t.id] and Catalog.SKIN[t.id].weapon or w.weapon; w.weaponSkin = t.id
		else w[t.slot] = t.id end
		return w
	end
	local function renderTryBanner()
		clear(tryBanner)
		local t = ui.tryOn
		if not t or t.class ~= ui.editing then tryBanner.Visible = false; return end
		tryBanner.Visible = true
		vlist(tryBanner, 6)
		local name, how, buys = "", "", {}
		if t.slot == "weapon" then
			local w = Catalog.WEAPON[t.id]
			name = w and w.name or t.id
			how = "Unlock: " .. (w and unlockText(w) or "?") .. ((w and (w.marks or 0) > 0) and ("  ·  or " .. fmt(w.marks) .. " Marks") or "")
			if w and (w.marks or 0) > 0 then table.insert(buys, {"UNLOCK  ·  " .. fmt(w.marks) .. " MARKS", COL.BLUE, function() afterBuy(call("Buy", "weapon", w.id, "marks"), render.CLASSES) end}) end
		elseif t.slot == "weaponSkin" then
			local s = Catalog.SKIN[t.id]
			name = s and ((Catalog.WEAPON[s.weapon] and Catalog.WEAPON[s.weapon].name or s.weapon) .. "  ·  " .. s.name) or t.id
			local text, kind = skinWhere(s)
			how = text
			if kind == "buy" then buys = skinBuyButtons(s, render.CLASSES) end
		else
			local pc = Catalog.PIECE[t.id]
			name = pc and pc.name or t.id
			if pc and pc.unlock then how = "Earn it: " .. Catalog.unlockText(pc.unlock) .. "  ·  " .. progressText(pc.unlock)
			elseif pc then
				local pk = Catalog.PACKS[pc.pack]
				local on = Catalog.onSale(pc.pack, storeDay())
				how = (pk and pk.name or pc.pack) .. " pack  ·  " .. (on and ("in today's shop  ·  " .. priceText(pc.marks, pc.crowns)) or ("not in the shop today" .. (Packs.nextOnSale(pc.pack) and ("  ·  back " .. Packs.nextOnSale(pc.pack)) or "")))
				if on then
					if (pc.marks or 0) > 0 then table.insert(buys, {"BUY  ·  " .. fmt(pc.marks) .. " MARKS", COL.BLUE, function() afterBuy(call("Buy", "piece", pc.id, "marks"), render.CLASSES) end}) end
					if (pc.crowns or 0) > 0 then table.insert(buys, {"BUY  ·  " .. fmt(pc.crowns) .. " CROWNS", COL.GOLD, function() afterBuy(call("Buy", "piece", pc.id, "crowns"), render.CLASSES) end}) end
				end
			end
		end
		local h = title(tryBanner, "TRYING ON:  " .. string.upper(name), 18, COL.ACCENT); h.Size = UDim2.new(1, 0, 0, 22); h.LayoutOrder = 1; h.TextTruncate = Enum.TextTruncate.AtEnd
		local d = title(tryBanner, how, 13, COL.TEXT); d.Size = UDim2.new(1, 0, 0, 0); d.AutomaticSize = Enum.AutomaticSize.Y; d.TextWrapped = true; d.LayoutOrder = 2
		for i, b in ipairs(buys) do
			local btn = button(tryBanner, b[1], 15, b[2]); btn.Size = UDim2.new(1, 0, 0, 38); btn.LayoutOrder = 2 + i
			btn.Activated:Connect(b[3])
		end
		local stop = button(tryBanner, "TAKE IT OFF", 14, COL.GLASS2); stop.Size = UDim2.new(1, 0, 0, 34); stop.LayoutOrder = 10
		stop.Activated:Connect(function() ui.tryOn = nil; render.CLASSES() end)
	end
	local function renderStage()
		stage:set({{loadout = worn(), appearance = state.profile and state.profile.appearance, weight = weightOf(ui.editing), team = ui.team,
			tag = className(ui.editing), sub = string.upper(weightOf(ui.editing)) .. (ui.dirty[ui.editing] and "  ·  UNSAVED" or ""), subColor = ui.dirty[ui.editing] and COL.ACCENT or (TYPE_COL[weightOf(ui.editing)] or COL.DIM)}})
		stageHint.Text = ui.team and ("TEAM PREVIEW: PRIMARY FORCED TO " .. string.upper(GameConfig.TEAMS[ui.team] and GameConfig.TEAMS[ui.team].name or ui.team))
			or "EVERY CLICK RE-DRESSES YOU  ·  CLICK SOMETHING LOCKED TO TRY IT ON  ·  DRAG TO TURN"
		renderTryBanner()
	end
	-- class cards: a 3D thumbnail of that class's saved look, the name, the
	-- weight, and the three stats the weight gives (Catalog ▸ Weights)
	local function renderClassRow()
		clear(classRow)
		local maxHp, minSpeed, maxSpeed, maxProt, minSta, maxSta = 0, 1, 1, 0, 1, 1
		for _, ww in pairs(Catalog.WEIGHTS) do
			maxHp = math.max(maxHp, ww.health or 0); maxProt = math.max(maxProt, ww.prot or 0)
			minSpeed = math.min(minSpeed, ww.speed or 1); maxSpeed = math.max(maxSpeed, ww.speed or 1)
			-- stamina: the bar and how fast it comes back, together
			local sta = (ww.stamina or 1) * (ww.regen or 1)
			minSta = math.min(minSta, sta); maxSta = math.max(maxSta, sta)
		end
		for i, id in ipairs(GameConfig.CLASS_ORDER) do
			local def = GameConfig.CLASSES[id]
			local on = ui.editing == id
			local b = button(classRow, "", 14, on and COL.BLUE or COL.GLASS)
			b.Size = UDim2.new(1 / #GameConfig.CLASS_ORDER, -8, 1, 0)
			b.LayoutOrder = i
			b.AutoButtonColor = false
			b.BackgroundTransparency = on and 0 or 0.1
			border(b, TYPE_COL[def.weight] or COL.DIM, on and 3 or 2, on and 0 or 0.5)
			local lo = ui.classEdit[id] or classLoadout(id)
			local th = mannequinThumb(b, lo, def.weight, UDim2.fromOffset(88, 106), lo.colors, {dist = 8.4})
			th.Position = UDim2.fromOffset(6, 6); th.BackgroundTransparency = 1
			local n = title(b, string.upper(def.name), 22); n.Size = UDim2.new(1, -110, 0, 26); n.Position = UDim2.new(0, 100, 0, 8)
			local w = title(b, string.upper(def.weight) .. (ui.dirty[id] and "  ·  UNSAVED" or ""), 13, TYPE_COL[def.weight] or COL.DIM); w.Size = UDim2.new(1, -110, 0, 16); w.Position = UDim2.new(0, 100, 0, 34)
			local wt = Catalog.WEIGHTS[def.weight] or {}
			local sta = (wt.stamina or 1) * (wt.regen or 1)
			local bars = {
				{"HP", (100 + (wt.health or 0)) / (100 + maxHp), COL.GOOD},
				{"ARMOR", maxProt > 0 and (wt.prot or 0) / maxProt or 0, COL.ACCENT},
				{"SPEED", ((wt.speed or 1) - minSpeed * 0.8) / (maxSpeed - minSpeed * 0.8), COL.CROWNS},
				{"STAMINA", (sta - minSta * 0.6) / (maxSta - minSta * 0.6), Color3.fromRGB(90, 200, 255)},
			}
			for j, bar in ipairs(bars) do
				local y = 52 + (j - 1) * 15
				local l = title(b, bar[1], 11, COL.DIM); l.Position = UDim2.new(0, 100, 0, y); l.Size = UDim2.fromOffset(52, 14)
				local track = frame(b, Color3.fromRGB(6, 8, 16), 4); track.Position = UDim2.new(0, 152, 0, y + 3); track.Size = UDim2.new(1, -164, 0, 8); track.BackgroundTransparency = 0.2
				local fill = frame(track, bar[3], 4); fill.Size = UDim2.new(math.clamp(bar[2], 0.08, 1), 0, 1, 0)
			end
			if state.activeClass == id then
				local chipA = title(b, "★ ACTIVE", 12); chipA.BackgroundTransparency = 0; chipA.BackgroundColor3 = COL.GREEN
				chipA.AnchorPoint = Vector2.new(1, 0); chipA.Position = UDim2.new(1, -8, 0, 8); chipA.Size = UDim2.fromOffset(74, 20); chipA.TextXAlignment = Enum.TextXAlignment.Center
				Instance.new("UICorner", chipA).CornerRadius = UDim.new(0, 6)
			end
			b.Activated:Connect(function() ui.editing = id; render.CLASSES() end)
		end
	end
	local function tryOn(slot, id)
		ui.tryOn = {class = ui.editing, slot = slot, id = id}
		render.CLASSES()
	end
	local function choose(k, v)
		local lo = edit()
		lo[k] = v
		if k == "weapon" then lo.weaponSkin = v .. ":Default"; if lo.secondary == v then lo.secondary = nil; lo.secondarySkin = nil end end
		if k == "secondary" then lo.secondarySkin = v and (v .. ":Default") or nil end
		ui.dirty[ui.editing] = true
		ui.tryOn = nil
		render.CLASSES()
	end
	-- a grid of small cards (pieces / weapons / skins) for a slot
	local function cardGrid(parent, cellH)
		local g = clearFrame(parent)
		g.AutomaticSize = Enum.AutomaticSize.Y
		g.Size = UDim2.new(1, 0, 0, 0)
		g.LayoutOrder = nextOrder()
		local gl = Instance.new("UIGridLayout", g)
		gl.CellSize = UDim2.new(0.5, -5, 0, cellH or 40)
		gl.CellPadding = UDim2.fromOffset(10, 8)
		gl.SortOrder = Enum.SortOrder.LayoutOrder
		return g
	end
	local function itemCard(parent, order, text, sub, on, have, accent, onClick, trying)
		local b = button(parent, "", 13, on and COL.BLUE or COL.GLASS2)
		b.LayoutOrder = order
		b.AutoButtonColor = true
		b.BackgroundTransparency = have and 0 or 0.35
		if trying then border(b, COL.ACCENT, 2.5, 0) elseif accent then border(b, accent, 2, on and 0 or 0.45) end
		local t = title(b, (have and "" or "🔒 ") .. text, 13, have and COL.TEXT or COL.DIM)
		t.Position = UDim2.fromOffset(10, 3); t.Size = UDim2.new(1, -16, 0, 18); t.TextTruncate = Enum.TextTruncate.AtEnd
		local s = label(b, sub or "", 11, FONT, on and COL.TEXT or COL.DIM)
		s.Position = UDim2.fromOffset(10, 21); s.Size = UDim2.new(1, -16, 0, 14); s.TextWrapped = false; s.TextTruncate = Enum.TextTruncate.AtEnd
		b.Activated:Connect(onClick)
		return b
	end
	render.CLASSES = function()
		local id = ui.editing
		local cls = GameConfig.CLASSES[id]
		local lo = edit()
		renderClassRow()
		renderStage()
		clear(list)
		local t = ui.tryOn and ui.tryOn.class == id and ui.tryOn or nil
		local p = panel(list, "ARMOR  ·  " .. string.upper(cls.weight))
		for _, slot in ipairs(Catalog.SLOTS) do
			heading(p, slot == "bottom" and "LEGS" or string.upper(slot))
			local pieces = Catalog.piecesFor(slot, cls.weight)
			local g = cardGrid(p, 40)
			for i, pc in ipairs(pieces) do
				local have = owns("pieces", pc.id)
				local pk = Catalog.PACKS[pc.pack]
				local sub = have and ((slot == "helmet" and #(pc.covers or {}) > 0) and ("covers " .. string.lower(table.concat(pc.covers, " + "))) or (pk and pk.name or ""))
					or (pc.unlock and Catalog.unlockText(pc.unlock) or priceText(pc.marks, pc.crowns))
				itemCard(g, i, pc.name, sub, lo[slot] == pc.id and not t, have, RARITY_COL[pc.rarity], function()
					if have then choose(slot, pc.id) else tryOn(slot, pc.id) end
				end, t and t.slot == slot and t.id == pc.id)
			end
			if #pieces == 0 then dim(p, "No " .. string.lower(cls.weight) .. " " .. slot .. " yet.") end
		end
		local cp = panel(list, "COLORS")
		for _, slot in ipairs({"Primary", "Secondary", "Accent", "Metal"}) do
			dim(cp, slot .. (slot == "Primary" and "  ·  your team's colour in team modes" or ""), 12)
			swatches(cp, Catalog.PALETTE, function(it) return lo.colors[slot] == it.name end, function(it) return it.crowns and not owns("colors", it.name) end, function(it)
				if it.crowns and not owns("colors", it.name) then
					modal(it.name, string.format("A premium colour: %d Crowns once, usable on every slot of every class.", it.crowns), {{"BUY  ·  " .. it.crowns .. " CROWNS", COL.GOLD, function()
						afterBuy(call("Buy", "color", it.name, "crowns"), render.CLASSES) end}})
				else lo.colors[slot] = it.name; ui.dirty[id] = true; render.CLASSES() end
			end, 28)
		end
		local function allowed(w, slot) return Catalog.weaponFits(cls, w, slot or "primary") end
		local wp = panel(list, "PRIMARY WEAPON")
		local g = cardGrid(wp, 40)
		local n = 0
		for _, w in ipairs(Catalog.WEAPONS) do
			if allowed(w) then
				n += 1
				local have = owns("weapons", w.id)
				itemCard(g, n, w.name, have and (w.family == "OneHanded" and "one-handed" or (w.family == "TwoHanded" and "two-handed" or (w.family == "Ranged" and "ranged" or "polearm"))) or unlockText(w), lo.weapon == w.id and not (t and (t.slot == "weapon" or t.slot == "weaponSkin")), have, nil, function()
					if have then choose("weapon", w.id) else tryOn("weapon", w.id) end
				end, t and t.slot == "weapon" and t.id == w.id)
			end
		end
		if lo.weapon then
			heading(wp, "SKIN")
			local sg = cardGrid(wp, 40)
			itemCard(sg, 0, "Default", "free", (lo.weaponSkin or ""):match(":Default$") ~= nil and not (t and t.slot == "weaponSkin"), true, nil, function() lo.weaponSkin = lo.weapon .. ":Default"; ui.dirty[id] = true; ui.tryOn = nil; render.CLASSES() end)
			local skins = Catalog.skinsFor(lo.weapon)
			table.sort(skins, function(a, b)
				local ha, hb = owns("skins", a.id), owns("skins", b.id)
				if ha ~= hb then return ha end
				if (RARITY_ORDER[a.rarity] or 0) ~= (RARITY_ORDER[b.rarity] or 0) then return (RARITY_ORDER[a.rarity] or 0) > (RARITY_ORDER[b.rarity] or 0) end
				return a.name < b.name
			end)
			for i, s in ipairs(skins) do
				local have = owns("skins", s.id)
				itemCard(sg, i, s.name, have and s.rarity or (skinWhere(s)), lo.weaponSkin == s.id and not (t and t.slot == "weaponSkin"), have, RARITY_COL[s.rarity], function()
					if have then lo.weaponSkin = s.id; ui.dirty[id] = true; ui.tryOn = nil; render.CLASSES() else tryOn("weaponSkin", s.id) end
				end, t and t.slot == "weaponSkin" and t.id == s.id)
			end
		end
		local sp = panel(list, "SECONDARY")
		local sg2 = cardGrid(sp, 40)
		itemCard(sg2, 0, "None", "", lo.secondary == nil, true, nil, function() choose("secondary", nil) end)
		n = 0
		for _, w in ipairs(Catalog.WEAPONS) do
			if w.id ~= lo.weapon and allowed(w, "secondary") then
				n += 1
				local have = owns("weapons", w.id)
				itemCard(sg2, n, w.name, have and "one-handed" or unlockText(w), lo.secondary == w.id, have, nil, function()
					if have then choose("secondary", w.id) else tryOn("weapon", w.id) end
				end)
			end
		end
		if lo.secondary then
			heading(sp, "SECONDARY SKIN")
			local sg3 = cardGrid(sp, 40)
			itemCard(sg3, 0, "Default", "free", (lo.secondarySkin or ""):match(":Default$") ~= nil, true, nil, function() lo.secondarySkin = lo.secondary .. ":Default"; ui.dirty[id] = true; render.CLASSES() end)
			for i, s in ipairs(Catalog.skinsFor(lo.secondary)) do
				if owns("skins", s.id) then itemCard(sg3, i, s.name, s.rarity, lo.secondarySkin == s.id, true, RARITY_COL[s.rarity], function() lo.secondarySkin = s.id; ui.dirty[id] = true; render.CLASSES() end) end
			end
		end
		dim(list, string.format("%s.  Weight %s:  %s. Looks never change stats.", cls.description or "", cls.weight, weightLine(cls.weight)), 12)
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
			toast(className(id) .. " saved", COL.GOOD)
			render.CLASSES()
		else toast(r.msg or "save failed", COL.BAD) end
	end
	render.CLASSES_active = function()
		local r = call("SetActive", ui.editing)
		if r.ok then state.activeClass = ui.editing; if r.profile then state.profile = r.profile end; toast("Spawning as " .. className(ui.editing), COL.GOOD) end
		render.CLASSES()
	end
end

--------------------------------------------------------------------
--  a strip of skin cards (horizontal scroll) with the selected one lit;
--  the ARMORY and the CRATES share it
--------------------------------------------------------------------
local function skinStrip(parent, pool, selectedId, onPick, height, showWeapon)
	local holder = frame(parent, COL.GLASS, 14)
	holder.BackgroundTransparency = 0.12
	holder.Size = UDim2.new(1, 0, 0, height or 160)
	local sf = Instance.new("ScrollingFrame")
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.Size = UDim2.fromScale(1, 1)
	sf.CanvasSize = UDim2.new(0, 0, 0, 0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.X
	sf.ScrollingDirection = Enum.ScrollingDirection.X
	sf.ScrollBarThickness = 6
	sf.ScrollBarImageColor3 = COL.DIM
	sf.Parent = holder
	local lay = hlist(sf, 10); lay.VerticalAlignment = Enum.VerticalAlignment.Center
	padding(sf, 10, 10, 8, 8)
	for i, s in ipairs(pool) do
		local have = owns("skins", s.id)
		local on = s.id == selectedId
		local c = button(sf, "", 12, on and COL.BLUE or COL.GLASS2)
		c.AutoButtonColor = false
		c.Size = UDim2.fromOffset(122, (height or 160) - 26)
		c.LayoutOrder = i
		border(c, RARITY_COL[s.rarity] or COL.DIM, on and 3 or 2, on and 0 or 0.35)
		local th = weaponThumb(c, s.weapon, s.name ~= "Default" and s.id or nil, UDim2.new(1, -12, 0, 76), 1.45); th.Position = UDim2.new(0, 6, 0, 6); th.BackgroundTransparency = 1
		local t = title(c, s.name, 13); t.Position = UDim2.new(0, 6, 0, 84); t.Size = UDim2.new(1, -12, 0, 16); t.TextXAlignment = Enum.TextXAlignment.Center; t.TextTruncate = Enum.TextTruncate.AtEnd
		local text, kind = skinWhere(s)
		local subText = have and "OWNED" or (kind == "crate" and "CRATE" or (kind == "earned" and "EARN" or (kind == "buy" and "IN SHOP" or (kind == "pack" and "PACK" or (kind == "pass" and "PASS" or "SHOP")))))
		if showWeapon then subText = string.upper(Catalog.WEAPON[s.weapon] and Catalog.WEAPON[s.weapon].name or s.weapon) .. (have and "  ✔" or "") end
		local sub = title(c, subText, 11, have and COL.GOOD or (kind == "buy" and COL.ACCENT or COL.DIM)); sub.Position = UDim2.new(0, 6, 0, 102); sub.Size = UDim2.new(1, -12, 0, 14); sub.TextXAlignment = Enum.TextXAlignment.Center
		if not have then local lk = label(c, "🔒", 13, FONT, COL.TEXT); lk.AnchorPoint = Vector2.new(1, 0); lk.Position = UDim2.new(1, -6, 0, 4); lk.Size = UDim2.fromOffset(18, 18); lk.TextXAlignment = Enum.TextXAlignment.Right end
		c.Activated:Connect(function() onPick(s) end)
	end
	return holder, sf
end

-- the crates' strip: skins, kill effects and emotes side by side
function Preview.strip(parent, pool, selectedKey, onPick, height)
	local holder = frame(parent, COL.GLASS, 14)
	holder.BackgroundTransparency = 0.12
	holder.Size = UDim2.new(1, 0, 0, height or 160)
	local sf = Instance.new("ScrollingFrame")
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.Size = UDim2.fromScale(1, 1)
	sf.CanvasSize = UDim2.new(0, 0, 0, 0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.X
	sf.ScrollingDirection = Enum.ScrollingDirection.X
	sf.ScrollBarThickness = 6
	sf.ScrollBarImageColor3 = COL.DIM
	sf.Parent = holder
	local lay = hlist(sf, 10); lay.VerticalAlignment = Enum.VerticalAlignment.Center
	padding(sf, 10, 10, 8, 8)
	for i, it in ipairs(pool) do
		local key = it.kind .. "|" .. it.id
		local have = owns(it.kind == "skin" and "skins" or (it.kind == "killfx" and "killfx" or "emotes"), it.id)
		local on = key == selectedKey
		local c = button(sf, "", 12, on and COL.BLUE or COL.GLASS2)
		c.AutoButtonColor = false
		c.Size = UDim2.fromOffset(122, (height or 160) - 26)
		c.LayoutOrder = i
		border(c, RARITY_COL[it.rarity] or COL.DIM, on and 3 or 2, on and 0 or 0.35)
		local th = Preview.thumb(c, it, UDim2.new(1, -12, 0, 76), 1.45); th.Position = UDim2.new(0, 6, 0, 6); th.BackgroundTransparency = 1
		local t = title(c, it.name, 13); t.Position = UDim2.new(0, 6, 0, 84); t.Size = UDim2.new(1, -12, 0, 16); t.TextXAlignment = Enum.TextXAlignment.Center; t.TextTruncate = Enum.TextTruncate.AtEnd
		local subText = it.kind == "skin" and string.upper(Catalog.WEAPON[it.weapon] and Catalog.WEAPON[it.weapon].name or it.weapon) or (it.kind == "killfx" and "KILL FX" or "EMOTE")
		local sub = title(c, subText .. (have and "  ✔" or ""), 11, have and COL.GOOD or COL.DIM); sub.Position = UDim2.new(0, 6, 0, 102); sub.Size = UDim2.new(1, -12, 0, 14); sub.TextXAlignment = Enum.TextXAlignment.Center; sub.TextTruncate = Enum.TextTruncate.AtEnd
		if not have then local lk = label(c, "🔒", 13, FONT, COL.TEXT); lk.AnchorPoint = Vector2.new(1, 0); lk.Position = UDim2.new(1, -6, 0, 4); lk.Size = UDim2.fromOffset(18, 18); lk.TextXAlignment = Enum.TextXAlignment.Right end
		c.Activated:Connect(function() onPick(it) end)
	end
	return holder, sf
end

-- armor sets: pieces grouped by their set (auto-imported) or their pack
local function armorSets()
	local byKey, list = {}, {}
	for _, pc in ipairs(Catalog.PIECES) do
		-- an earned piece is its own entry (they don't come in sets)
		local key = pc.set or (pc.unlock and ("piece:" .. pc.id)) or ("pack:" .. pc.pack)
		local s = byKey[key]
		if not s then
			local pk = Catalog.PACKS[pc.pack]
			s = {key = key, name = pc.setName or (pc.unlock and pc.name) or (pk and pk.name) or pc.pack, weight = pc.weight, pack = pc.pack, pieces = {}, rarity = "Common", description = pc.description, earned = pc.unlock ~= nil}
			byKey[key] = s
			table.insert(list, s)
		end
		s.pieces[pc.slot] = s.pieces[pc.slot] or pc
		if (RARITY_ORDER[pc.rarity] or 1) > (RARITY_ORDER[s.rarity] or 1) then s.rarity = pc.rarity end
		s.description = s.description or pc.description
	end
	local W = {Light = 1, Medium = 2, Heavy = 3}
	table.sort(list, function(a, b)
		if a.earned ~= b.earned then return not a.earned end
		if (W[a.weight] or 9) ~= (W[b.weight] or 9) then return (W[a.weight] or 9) < (W[b.weight] or 9) end
		if (RARITY_ORDER[a.rarity] or 1) ~= (RARITY_ORDER[b.rarity] or 1) then return (RARITY_ORDER[a.rarity] or 1) < (RARITY_ORDER[b.rarity] or 1) end
		return a.name < b.name
	end)
	return list, byKey
end

--------------------------------------------------------------------
--  WEAPON STATS: the numbers the server publishes (ReplicatedStorage ▸
--  WeaponStats), as bars against every other weapon
--------------------------------------------------------------------
local function weaponStats(id)
	local f = ReplicatedStorage:FindFirstChild("WeaponStats")
	local c = f and f:FindFirstChild(id)
	return c and c:GetAttributes() or nil
end
local statRange
local function weaponStatRange()
	if statRange then return statRange end
	local f = ReplicatedStorage:FindFirstChild("WeaponStats")
	if not f or #f:GetChildren() == 0 then return nil end
	local r = {}
	local function see(k, v) if type(v) ~= "number" then return end; local e = r[k] or {lo = v, hi = v}; e.lo = math.min(e.lo, v); e.hi = math.max(e.hi, v); r[k] = e end
	for _, c in ipairs(f:GetChildren()) do
		local a = c:GetAttributes()
		see("Reach", a.Reach); see("Damage", math.max(a.SwingDamage or 0, a.OverheadDamage or 0)); see("Stab", a.StabDamage)
		see("Windup", a.SwingWindup); see("Cost", a.SwingCost); see("Block", a.SwingBlock); see("Move", a.Move)
	end
	statRange = r
	return r
end
-- a card of bars: reach, damage, stab, speed, stamina, guard break, armor pierce, walk speed
local function weaponStatCard(parent, id)
	local a, R = weaponStats(id), weaponStatRange()
	if not (a and R) then return nil end
	local card = frame(parent, COL.GLASS, 14)
	card.BackgroundTransparency = 0.18
	card.AnchorPoint = Vector2.new(1, 1)
	card.Position = UDim2.new(1, -14, 1, -14)
	card.Size = UDim2.fromOffset(360, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.ZIndex = 5
	border(card, WHITE, 1.5, 0.85)
	padding(card, 12, 12, 10, 10)
	vlist(card, 4)
	local h = title(card, "STATS", 14, COL.DIM); h.Size = UDim2.new(1, 0, 0, 18); h.ZIndex = 6
	local function frac(k, v, invert)
		local e = R[k]
		if not (e and v) or e.hi - e.lo < 1e-6 then return 0.5 end
		local f = (v - e.lo) / (e.hi - e.lo)
		if invert then f = 1 - f end
		return 0.12 + 0.88 * f
	end
	local dmg = math.max(a.SwingDamage or 0, a.OverheadDamage or 0)
	local rows = {
		{"REACH", frac("Reach", a.Reach), string.format("%.1f studs", a.Reach or 0), COL.CROWNS},
		{"DAMAGE", frac("Damage", dmg), string.format("%d  ·  head %d", dmg, math.floor(dmg * (a.HeadMult or 2) + 0.5)), COL.BAD},
		{"STAB", frac("Stab", a.StabDamage), string.format("%d", a.StabDamage or 0), Color3.fromRGB(230, 120, 90)},
		{"SPEED", frac("Windup", a.SwingWindup, true), string.format("%.2f s wind-up", a.SwingWindup or 0), COL.GOOD},
		{"STAMINA", frac("Cost", a.SwingCost), string.format("%d a swing", a.SwingCost or 0), Color3.fromRGB(255, 170, 60)},
		{"GUARD BREAK", frac("Block", a.SwingBlock), string.format("%d off a block", a.SwingBlock or 0), COL.PURPLE},
		{"ARMOR PIERCE", 0.04 + 0.96 * (a.ArmorPen or 0), string.format("%d%%", math.floor((a.ArmorPen or 0) * 100 + 0.5)), Color3.fromRGB(180, 190, 210)},
		{"MOVE", frac("Move", a.Move), string.format("%d%% walk speed", math.floor((a.Move or 1) * 100 + 0.5)), Color3.fromRGB(90, 200, 255)},
	}
	for i, r in ipairs(rows) do
		local row_ = clearFrame(card); row_.Size = UDim2.new(1, 0, 0, 18); row_.LayoutOrder = 10 + i
		local l = title(row_, r[1], 11, COL.DIM); l.Size = UDim2.fromOffset(96, 18); l.ZIndex = 6
		local track = frame(row_, Color3.fromRGB(6, 8, 16), 4); track.Position = UDim2.fromOffset(100, 5); track.Size = UDim2.new(1, -236, 0, 8); track.BackgroundTransparency = 0.2; track.ZIndex = 6
		local fill = frame(track, r[4], 4); fill.Size = UDim2.new(math.clamp(r[2], 0.04, 1), 0, 1, 0); fill.ZIndex = 7
		local v = label(row_, r[3], 12, FONT, COL.TEXT); v.AnchorPoint = Vector2.new(1, 0); v.Position = UDim2.new(1, 0, 0, 0); v.Size = UDim2.fromOffset(128, 18)
		v.TextXAlignment = Enum.TextXAlignment.Right; v.TextWrapped = false; v.ZIndex = 6
	end
	local tags = {}
	if a.TwoHanded then table.insert(tags, "two hands") end
	if a.Secondary then table.insert(tags, "can be a secondary") end
	if #tags > 0 then local t = label(card, table.concat(tags, "  ·  "), 11, FONT_BODY, COL.DIM); t.Size = UDim2.new(1, 0, 0, 14); t.LayoutOrder = 30; t.ZIndex = 6 end
	return card
end

--------------------------------------------------------------------
--  ARMORY — WEAPONS: every weapon on a stage with its skins, and for each
--  skin exactly where it comes from · ARMOR: every set, worn by you
--------------------------------------------------------------------
do
	local f = tabFrame.ARMORY
	local tabs = clearFrame(f); tabs.Size = UDim2.new(1, 0, 0, 46)
	hlist(tabs, 10)
	local body = clearFrame(f); body.Position = UDim2.new(0, 0, 0, 58); body.Size = UDim2.new(1, 0, 1, -58)
	local TABS = {{"weapons", "WEAPONS"}, {"armor", "ARMOR"}, {"killfx", "KILL FX"}, {"emotes", "EMOTES"}}

	local function renderTabs()
		clear(tabs)
		for i, t in ipairs(TABS) do
			local on = ui.armoryTab == t[1]
			local h, b = fatButton(tabs, t[2], on and COL.BLUE or COL.GLASS2, 20)
			h.Size = UDim2.fromOffset(190, 46); h.LayoutOrder = i
			if not on then b.TextColor3 = COL.DIM end
			b.Activated:Connect(function() ui.armoryTab = t[1]; render.ARMORY() end)
		end
		-- the filter: what you own (the default), or everything there is to get
		local gap = clearFrame(tabs); gap.Size = UDim2.fromOffset(24, 46); gap.LayoutOrder = 50
		local h, b = fatButton(tabs, ui.ownedOnly and "✔ OWNED ONLY" or "SHOWING ALL", ui.ownedOnly and COL.GREEN or COL.GLASS2, 18)
		h.Size = UDim2.fromOffset(230, 46); h.LayoutOrder = 51
		b.Activated:Connect(function() ui.ownedOnly = not ui.ownedOnly; render.ARMORY() end)
	end
	-- the filter's empty state
	local function nothingOwned(parent, what)
		local d = dim(parent, string.format("No %s unlocked yet. Tap  ✔ OWNED ONLY  to see everything you can get, and how.", what), 14)
		return d
	end

	-- equip helper: put these pieces / this weapon on the best class for them
	local function classFor(weight)
		if not weight or weightOf(state.activeClass) == weight then return state.activeClass end
		for _, id in ipairs(GameConfig.CLASS_ORDER) do if weightOf(id) == weight then return id end end
		return state.activeClass
	end
	local function equip(classId, change, what)
		local lo = {}
		for k, v in pairs(classLoadout(classId)) do lo[k] = v end
		local colors = {}
		for k, v in pairs(lo.colors or {}) do colors[k] = v end
		lo.colors = colors
		change(lo)
		local r = call("SaveClass", classId, lo)
		if r.ok then
			toast(what .. " equipped on " .. className(classId), COL.GOOD)
			if r.profile then state.profile = r.profile end
			ui.classEdit[classId] = nil; ui.dirty[classId] = nil
			loadCatalog()
		else toast(r.msg or "", COL.BAD) end
		render.ARMORY()
	end

	----------------------------------------------------------------
	--  WEAPONS
	----------------------------------------------------------------
	local function weapons()
		local left = clearFrame(body); left.Size = UDim2.new(0, 270, 1, 0)
		local leftList = scroll(left, 6)
		local right = clearFrame(body); right.Position = UDim2.new(0, 286, 0, 0); right.Size = UDim2.new(1, -286, 1, 0)
		local groups = {{"OneHanded", "ONE-HANDED"}, {"TwoHanded", "TWO-HANDED"}, {"Polearm", "POLEARMS"}, {"Ranged", "RANGED  ·  ARCHER"}}
		local function shown(w) return not ui.ownedOnly or owns("weapons", w.id) end
		if not Catalog.WEAPON[ui.shopWeapon] or not shown(Catalog.WEAPON[ui.shopWeapon]) then
			ui.shopWeapon = nil
			for _, w in ipairs(Catalog.WEAPONS) do if shown(w) then ui.shopWeapon = w.id; break end end
			ui.shopWeapon = ui.shopWeapon or (Catalog.WEAPONS[1] and Catalog.WEAPONS[1].id)
		end
		for _, g in ipairs(groups) do
			local list = {}
			for _, w in ipairs(Catalog.WEAPONS) do if w.family == g[1] and shown(w) then table.insert(list, w) end end
			if #list > 0 then heading(leftList, g[2]) end
			for _, w in ipairs(list) do
				local have = owns("weapons", w.id)
				local skinsOwned, skinsAll = 0, 0
				for _, s in ipairs(Catalog.skinsFor(w.id)) do skinsAll += 1; if owns("skins", s.id) then skinsOwned += 1 end end
				row(leftList, (have and "" or "🔒 ") .. w.name, have and string.format("%d / %d skins", skinsOwned, skinsAll) or unlockText(w), w.id == ui.shopWeapon,
					function() ui.shopWeapon = w.id; ui.shopSkin = nil; render.ARMORY() end, have and COL.DIM or COL.BAD)
			end
		end
		if ui.ownedOnly then dim(leftList, "Showing the weapons you own. Tap  ✔ OWNED ONLY  to see every weapon and how to unlock it.", 12) end
		local w = Catalog.WEAPON[ui.shopWeapon]
		if not w then return end
		local have = owns("weapons", w.id)
		local all = Catalog.skinsFor(w.id)
		local pool = {}
		for _, s in ipairs(all) do if not ui.ownedOnly or owns("skins", s.id) then table.insert(pool, s) end end
		local hidden = #all - #pool
		table.sort(pool, function(a, b)
			if (RARITY_ORDER[a.rarity] or 0) ~= (RARITY_ORDER[b.rarity] or 0) then return (RARITY_ORDER[a.rarity] or 0) < (RARITY_ORDER[b.rarity] or 0) end
			return a.name < b.name
		end)
		table.insert(pool, 1, {id = w.id .. ":Default", name = "Default", weapon = w.id, rarity = "Common"})
		local sel = ui.shopSkin and Catalog.SKIN[ui.shopSkin]
		if not sel or sel.weapon ~= w.id then sel = pool[1]; ui.shopSkin = sel.id end
		local stageH = clearFrame(right); stageH.Size = UDim2.new(1, 0, 1, -262)
		local stg = weaponStage(stageH, w.id, sel.name ~= "Default" and sel.id or nil)
		local nm = title(stg, w.name, 34); nm.Position = UDim2.fromOffset(18, 12); nm.Size = UDim2.new(1, -36, 0, 38)
		local sk = title(stg, sel.name == "Default" and "DEFAULT LOOK" or (string.upper(sel.name) .. "  SKIN"), 18, RARITY_COL[sel.rarity] or COL.DIM); sk.Position = UDim2.fromOffset(20, 50); sk.Size = UDim2.new(1, -40, 0, 22)
		if sel.name ~= "Default" then local tag = rarityTag(stg, sel.rarity); tag.AnchorPoint = Vector2.new(1, 0); tag.Position = UDim2.new(1, -16, 0, 16) end
		local fam = w.family == "OneHanded" and "One-handed" or (w.family == "TwoHanded" and "Two-handed" or (w.family == "Ranged" and "Ranged (the Archer's)" or "Polearm"))
		local fxText = Preview.fxText(sel)
		local info = title(stg, fam .. (w.secondary and "  ·  can be your secondary" or "") .. (sel.trim and ("  ·  trim: " .. sel.trim) or "") .. (fxText and ("  ·  " .. fxText) or ""), 13, COL.DIM); info.Position = UDim2.fromOffset(20, 74); info.Size = UDim2.new(1, -40, 0, 16)
		local desc = (weaponStats(w.id) or {}).Description
		if desc then local d2 = title(stg, desc, 14); d2.TextWrapped = true; d2.AnchorPoint = Vector2.new(0, 1); d2.Position = UDim2.new(0, 20, 1, -14); d2.Size = UDim2.new(1, -420, 0, 60); d2.TextYAlignment = Enum.TextYAlignment.Bottom end
		-- what it does, against every other weapon
		weaponStatCard(stg, w.id)
		-- what you can do with it: equip / unlock / buy / where it drops
		local act = clearFrame(right); act.Position = UDim2.new(0, 0, 1, -252); act.Size = UDim2.new(1, 0, 0, 56)
		hlist(act, 10).VerticalAlignment = Enum.VerticalAlignment.Center
		local skinHave = owns("skins", sel.id)
		local text, kind = skinWhere(sel)
		local function fat(textB, color, fn, width)
			local hh, bb = fatButton(act, textB, color, 18)
			hh.Size = UDim2.fromOffset(width or 260, 54); hh.LayoutOrder = nextOrder()
			bb.Activated:Connect(fn)
			return hh
		end
		if not have then
			if (w.marks or 0) > 0 then fat("UNLOCK  ·  " .. fmt(w.marks) .. " MARKS", COL.BLUE, function() afterBuy(call("Buy", "weapon", w.id, "marks"), render.ARMORY) end) end
			local l = title(act, "Unlocks at " .. unlockText(w), 15, COL.DIM); l.Size = UDim2.fromOffset(300, 54); l.LayoutOrder = nextOrder()
		elseif skinHave then
			-- (a bow is the Archer's; a blade isn't)
			local cls = classFor(nil)
			if w.ranged then cls = "Archer"
			elseif GameConfig.CLASSES[cls] and GameConfig.CLASSES[cls].ranged then cls = GameConfig.DEFAULT_CLASS end
			fat("EQUIP ON " .. string.upper(className(cls)), COL.GREEN, function()
				equip(cls, function(lo) lo.weapon = w.id; lo.weaponSkin = sel.id; if lo.secondary == w.id then lo.secondary = nil; lo.secondarySkin = nil end end, w.name .. (sel.name ~= "Default" and (" · " .. sel.name) or ""))
			end)
			if w.secondary then
				fat("AS SECONDARY", COL.GLASS2, function()
					equip(cls, function(lo) if lo.weapon ~= w.id then lo.secondary = w.id; lo.secondarySkin = sel.id end end, w.name .. " (secondary)")
				end, 200)
			end
		elseif kind == "buy" then
			for _, b in ipairs(skinBuyButtons(sel, render.ARMORY)) do fat(b[1], b[2], b[3], 240) end
		elseif kind == "crate" then
			fat("OPEN THE CRATE", COL.GOLD, function() ui.shopTab = "crates"; ui.crate = sel.crate; ui.crateItem = "skin|" .. sel.id; selectTab("SHOP") end)
		elseif kind == "pass" then
			fat("SEE THE PASS", COL.GOLD, function() selectTab("PASS") end)
		elseif kind == "earned" then
			local hold = clearFrame(act); hold.Size = UDim2.fromOffset(300, 30); hold.LayoutOrder = nextOrder()
			progressBar(hold, progressFrac(sel.unlock), COL.PURPLE, progressText(sel.unlock), 24)
			fat("SEE TASKS", COL.PURPLE, function() selectTab("TASKS") end, 180)
		end
		if (not skinHave or not have) and sel.name ~= "Default" then
			local l = title(act, text, 14, kind == "buy" and COL.ACCENT or ((kind == "relic" or kind == "vaulted") and RARITY_COL.Mythic or COL.DIM)); l.TextWrapped = true; l.Size = UDim2.fromOffset(420, 54); l.LayoutOrder = nextOrder()
		end
		-- yours: its finish, its number, where it came from, its kills; spare copies forge it up
		if skinHave and sel.name ~= "Default" then
			local P = state.profile or {}
			local list = HX.copies(sel.id)
			local it = HX.best(sel.id) or {}
			local bits = {}
			if #list > 1 then table.insert(bits, "×" .. #list .. " COPIES") end
			if it.v then table.insert(bits, string.upper(it.v) .. " FINISH") end
			if it.n then table.insert(bits, "#" .. fmt(it.n) .. (sel.limited and (" of " .. fmt(sel.limited)) or "")) end
			if it.from then table.insert(bits, "from " .. tostring(it.from)) end
			if it.at then table.insert(bits, os.date("!%d %b %Y", it.at)) end
			if (it.tr or 0) > 0 then table.insert(bits, "traded " .. it.tr .. "×") end
			table.insert(bits, fmt(P.tally and P.tally[sel.id] or 0) .. " kills with it")
			local st = HX.Drops.skinStatus(sel)
			if st == "relic" then table.insert(bits, "RELIC") elseif st == "vaulted" then table.insert(bits, "VAULTED") end
			local story = title(stg, table.concat(bits, "  ·  "), 14, HX.VARIANT_COL[it.v] or COL.ACCENT)
			story.Position = UDim2.fromOffset(20, 92); story.Size = UDim2.new(1, -40, 0, 18)
			if #list >= 3 and it.v ~= "Radiant" then
				fat("FORGE TO " .. (it.v == "Masterwork" and "RADIANT" or "MASTERWORK") .. "  ·  3 COPIES", COL.PURPLE, function()
					local r = call("Forge", sel.id)
					toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
					if r.profile then state.profile = r.profile end
					render.ARMORY()
				end, 300)
			end
			if #list >= 2 then
				-- the plainest spare goes for Marks
				local worst
				for _, c in ipairs(list) do
					if c ~= it and not c.b and (not worst or (HX.RANK[c.v] or 0) < (HX.RANK[worst.v] or 0)) then worst = c end
				end
				if worst then
					fat("SCRAP A SPARE", COL.GLASS2, function()
						modal("SCRAP A SPARE?", "Your plainest spare copy" .. (worst.n and (" (#" .. worst.n .. ")") or "") .. " melts down for Marks. You keep the rest.", {{"SCRAP IT", COL.BAD, function()
							local r = call("Scrap", worst.u)
							toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
							if r.profile then state.profile = r.profile; refreshWallet() end
							closeModal(); render.ARMORY()
						end}})
					end, 180)
				end
			end
		end
		-- the strip of this weapon's skins
		local stripH = clearFrame(right); stripH.AnchorPoint = Vector2.new(0, 1); stripH.Position = UDim2.new(0, 0, 1, 0); stripH.Size = UDim2.new(1, 0, 0, 186)
		local owned = 0
		for _, s in ipairs(pool) do if owns("skins", s.id) then owned += 1 end end
		local h = title(stripH, string.format("SKINS  ·  %d / %d OWNED", owned, #all + 1) .. (hidden > 0 and string.format("  ·  %d MORE TO UNLOCK: TAP  ✔ OWNED ONLY  TO SEE THEM", hidden) or ""), 15, COL.DIM)
		h.Size = UDim2.new(1, 0, 0, 20); h.TextTruncate = Enum.TextTruncate.AtEnd
		local sh = clearFrame(stripH); sh.Position = UDim2.new(0, 0, 0, 24); sh.Size = UDim2.new(1, 0, 1, -24)
		skinStrip(sh, pool, sel.id, function(s) ui.shopSkin = s.id; render.ARMORY() end, 162)
	end

	----------------------------------------------------------------
	--  ARMOR: every set on you, piece by piece
	----------------------------------------------------------------
	local armorStage, armorHint
	local function armor()
		local allSets, byKey = armorSets()
		-- the filter: sets you own a piece of (or everything)
		local sets = {}
		for _, s in ipairs(allSets) do
			local any = false
			for _, pc in pairs(s.pieces) do if owns("pieces", pc.id) then any = true; break end end
			if any or not ui.ownedOnly then table.insert(sets, s) end
		end
		local function listed(key) for _, s in ipairs(sets) do if s.key == key then return true end end return false end
		if not ui.armorSet or not byKey[ui.armorSet] or not listed(ui.armorSet) then
			-- start on the set your active class wears
			local lo = classLoadout(state.activeClass)
			local pc = lo.top and Catalog.PIECE[lo.top]
			ui.armorSet = pc and (pc.set or ("pack:" .. pc.pack)) or (sets[1] and sets[1].key)
			if not listed(ui.armorSet) then ui.armorSet = sets[1] and sets[1].key end
		end
		local set = byKey[ui.armorSet]
		local left = clearFrame(body); left.Size = UDim2.new(0, 290, 1, 0)
		local leftList = scroll(left, 6)
		local lastW
		for _, s in ipairs(sets) do
			local group = s.earned and "EARNED IN BATTLE" or (string.upper(s.weight) .. " ARMOR")
			if group ~= lastW then heading(leftList, group); lastW = group end
			local have, total = 0, 0
			for _, pc in pairs(s.pieces) do total += 1; if owns("pieces", pc.id) then have += 1 end end
			local right = have == total and "OWNED" or (s.earned and "EARN" or (Catalog.onSale(s.pack, storeDay()) and "IN SHOP" or string.format("%d / %d", have, total)))
			local r = row(leftList, s.name, right, s.key == ui.armorSet, function() ui.armorSet = s.key; ui.armorSlots = {helmet = true, top = true, bottom = true}; render.ARMORY() end,
				have == total and COL.GOOD or (right == "IN SHOP" and COL.ACCENT or COL.DIM))
			local bar = frame(r, RARITY_COL[s.rarity] or COL.DIM, 3); bar.Size = UDim2.fromOffset(4, 22); bar.Position = UDim2.new(0, -8, 0.5, -11)
		end
		if ui.ownedOnly then dim(leftList, string.format("Showing the sets you own a piece of. %d more to get: tap  ✔ OWNED ONLY  to see them.", #allSets - #sets), 12) end
		if not set then nothingOwned(body, "armor"); return end
		-- the stage: you, wearing the set (the slots you toggle off keep your class's pieces)
		local mid = clearFrame(body); mid.Position = UDim2.new(0, 306, 0, 0); mid.Size = UDim2.new(1, -306 - 400, 1, 0)
		local stageH = clearFrame(mid); stageH.Size = UDim2.new(1, 0, 1, -64)
		local _, stg, hint = stageBlock(stageH, "", {dist = 10, platform = TYPE_COL[set.weight] or COL.BLUE})
		armorStage, armorHint = stg, hint
		local base = classLoadout(classFor(set.weight))
		local lo = {colors = base.colors}
		for _, slot in ipairs(Catalog.SLOTS) do
			lo[slot] = (ui.armorSlots[slot] and set.pieces[slot]) and set.pieces[slot].id or base[slot]
		end
		stg:set({{loadout = lo, appearance = state.profile and state.profile.appearance, weight = set.weight, weapon = false,
			tag = set.name, sub = string.upper(set.weight) .. "  ·  " .. string.upper(set.rarity), subColor = RARITY_COL[set.rarity]}})
		hint.Text = "YOUR COLOURS, YOUR FACE  ·  DRAG TO TURN  ·  TOGGLE THE PIECES BELOW"
		-- piece toggles
		local toggles = clearFrame(mid); toggles.AnchorPoint = Vector2.new(0, 1); toggles.Position = UDim2.new(0, 0, 1, 0); toggles.Size = UDim2.new(1, 0, 0, 54)
		hlist(toggles, 10).HorizontalAlignment = Enum.HorizontalAlignment.Center
		for i, slot in ipairs(Catalog.SLOTS) do
			local pc = set.pieces[slot]
			if pc then
				local on = ui.armorSlots[slot]
				local h, b = fatButton(toggles, (slot == "bottom" and "LEGS" or string.upper(slot)) .. (on and "  ✔" or ""), on and COL.BLUE or COL.GLASS2, 17)
				h.Size = UDim2.fromOffset(150, 52); h.LayoutOrder = i
				b.Activated:Connect(function() ui.armorSlots[slot] = not ui.armorSlots[slot]; render.ARMORY() end)
			end
		end
		-- the set card
		local right = clearFrame(body); right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 390, 1, 0)
		local list = scroll(right, 10)
		local p = panel(list, nil)
		local t = title(p, set.name, 28); t.Size = UDim2.new(1, 0, 0, 32); t.TextTruncate = Enum.TextTruncate.AtEnd
		local tagRow = clearFrame(p); tagRow.Size = UDim2.new(1, 0, 0, 22); tagRow.LayoutOrder = nextOrder()
		hlist(tagRow, 8)
		local rt = rarityTag(tagRow, set.rarity); rt.LayoutOrder = 1
		local wt = title(tagRow, string.upper(set.weight), 12); wt.BackgroundTransparency = 0; wt.BackgroundColor3 = TYPE_COL[set.weight] or COL.DIM; wt.Size = UDim2.fromOffset(84, 20); wt.TextXAlignment = Enum.TextXAlignment.Center; wt.LayoutOrder = 2
		Instance.new("UICorner", wt).CornerRadius = UDim.new(0, 6)
		if set.description then dim(p, set.description, 13) end
		dim(p, string.format("%s armor: %s. Every %s set gives the same stats: looks never change them.",
			set.weight, weightLine(set.weight), string.lower(set.weight)), 12)
		heading(p, "PIECES")
		local allOwned = true
		for _, slot in ipairs(Catalog.SLOTS) do
			local pc = set.pieces[slot]
			if pc then
				local have = owns("pieces", pc.id)
				if not have then allOwned = false end
				local rightText = have and "OWNED ✔" or (pc.unlock and (Catalog.unlockText(pc.unlock) .. "  ·  " .. progressText(pc.unlock)) or priceText(pc.marks, pc.crowns))
				row(p, pc.name, rightText, false, nil, have and COL.GOOD or (pc.unlock and COL.PURPLE or COL.DIM))
			end
		end
		local pk = Catalog.PACKS[set.pack]
		local onSale = Catalog.onSale(set.pack, storeDay())
		local earned
		for _, pc in pairs(set.pieces) do if pc.unlock then earned = pc.unlock end end
		local acts = panel(list, nil, true)
		if allOwned then
			local cls = classFor(set.weight)
			local h, b = fatButton(acts, "EQUIP ON " .. string.upper(className(cls)), COL.GREEN, 20); h.Size = UDim2.new(1, 0, 0, 56); h.LayoutOrder = nextOrder()
			b.Activated:Connect(function()
				equip(cls, function(l) for _, slot in ipairs(Catalog.SLOTS) do if set.pieces[slot] and ui.armorSlots[slot] then l[slot] = set.pieces[slot].id end end end, set.name)
			end)
			dim(acts, "Classes of the same weight can wear it: " .. (function()
				local names = {}
				for _, id in ipairs(GameConfig.CLASS_ORDER) do if weightOf(id) == set.weight then table.insert(names, className(id)) end end
				return table.concat(names, ", ")
			end)() .. ".", 12)
		elseif earned then
			dim(acts, "Earned in battle, never sold. Keep playing: it unlocks by itself.", 13)
			local bh = clearFrame(acts); bh.Size = UDim2.new(1, 0, 0, 22); bh.LayoutOrder = nextOrder()
			progressBar(bh, progressFrac(earned), COL.PURPLE, progressText(earned), 22)
		elseif onSale and pk and not pk.free then
			local m, c = Packs.price(set.pack)
			title(acts, "IN TODAY'S SHOP  ·  " .. storeCountdown() .. " LEFT", 15, COL.ACCENT).Size = UDim2.new(1, 0, 0, 20)
			if m > 0 then local h, b = fatButton(acts, "BUY  ·  " .. fmt(m) .. " MARKS", COL.BLUE, 19); h.Size = UDim2.new(1, 0, 0, 52); h.LayoutOrder = nextOrder(); b.Activated:Connect(function() afterBuy(call("Buy", "pack", set.pack, "marks"), render.ARMORY) end) end
			if c > 0 then local h, b = fatButton(acts, "BUY  ·  " .. fmt(c) .. " CROWNS", COL.GOLD, 19); h.Size = UDim2.new(1, 0, 0, 52); h.LayoutOrder = nextOrder(); b.Activated:Connect(function() afterBuy(call("Buy", "pack", set.pack, "crowns"), render.ARMORY) end) end
			dim(acts, string.format("The whole %s pack%s, %d%% off.", pk.name, #Packs.skins(set.pack) > 0 and " (with its weapon skins)" or "", math.floor((pk.bundle or 0) * 100 + 0.5)), 12)
		else
			local when = Packs.nextOnSale(set.pack)
			title(acts, "NOT IN THE SHOP TODAY", 16, COL.DIM).Size = UDim2.new(1, 0, 0, 20)
			dim(acts, when and ("The " .. (pk and pk.name or set.pack) .. " pack is back in the shop on " .. when .. ".") or "This pack is resting: check the shop each day.", 13)
		end
	end


	----------------------------------------------------------------
	--  KILL FX and EMOTES: a list, you on a stage, where to get it, equip
	----------------------------------------------------------------
	local function sortedItems(list)
		local out = {}
		for _, it in ipairs(list) do table.insert(out, it) end
		table.sort(out, function(a, b)
			if (RARITY_ORDER[a.rarity] or 0) ~= (RARITY_ORDER[b.rarity] or 0) then return (RARITY_ORDER[a.rarity] or 0) < (RARITY_ORDER[b.rarity] or 0) end
			return a.name < b.name
		end)
		return out
	end
	local function itemCardRight(it, ownKind, extra)
		local right = clearFrame(body); right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 390, 1, 0)
		local list = scroll(right, 10)
		local p = panel(list, nil)
		local t = title(p, it.name, 28); t.Size = UDim2.new(1, 0, 0, 32); t.TextTruncate = Enum.TextTruncate.AtEnd
		local tags = clearFrame(p); tags.Size = UDim2.new(1, 0, 0, 22); tags.LayoutOrder = nextOrder()
		rarityTag(tags, it.rarity)
		dim(p, it.description or "", 14)
		local text, kind = Preview.where(it, ownKind)
		local w = title(p, string.upper(text), 13, kind == "owned" and COL.GOOD or COL.ACCENT); w.Size = UDim2.new(1, 0, 0, 0); w.AutomaticSize = Enum.AutomaticSize.Y; w.TextWrapped = true; w.LayoutOrder = nextOrder()
		local acts = panel(list, nil, true)
		if kind == "crate" then
			local h, b = fatButton(acts, "OPEN THE " .. string.upper(Catalog.CRATES[it.crate] and Catalog.CRATES[it.crate].name or it.crate), COL.GOLD, 18); h.Size = UDim2.new(1, 0, 0, 54); h.LayoutOrder = nextOrder()
			b.Activated:Connect(function() ui.shopTab = "crates"; ui.crate = it.crate; ui.crateItem = (ownKind == "killfx" and "killfx|" or "emote|") .. it.id; selectTab("SHOP") end)
		elseif kind == "pass" then
			local h, b = fatButton(acts, "SEE THE PASS", COL.GOLD, 18); h.Size = UDim2.new(1, 0, 0, 54); h.LayoutOrder = nextOrder()
			b.Activated:Connect(function() selectTab("PASS") end)
		elseif kind == "earned" then
			local bh = clearFrame(acts); bh.Size = UDim2.new(1, 0, 0, 22); bh.LayoutOrder = nextOrder()
			progressBar(bh, progressFrac(it.unlock), COL.PURPLE, progressText(it.unlock), 22)
		end
		if extra then extra(acts, kind == "owned") end
		return list
	end

	-- the filter: just what you own (or everything there is)
	local function filtered(items, kind)
		if not ui.ownedOnly then return items, 0 end
		local out = {}
		for _, it in ipairs(items) do if owns(kind, it.id) then table.insert(out, it) end end
		return out, #items - #out
	end
	local function killfx()
		local items, hidden = filtered(sortedItems(Catalog.KILLFX), "killfx")
		local equippedId = state.profile and state.profile.killfx or "Shatter"
		if #items == 0 then nothingOwned(body, "kill effects"); return end
		local inList = false
		for _, f in ipairs(items) do if f.id == ui.fxSel then inList = true end end
		if not Catalog.KILLFX_BY[ui.fxSel or ""] or not inList then ui.fxSel = Catalog.KILLFX_BY[equippedId] and equippedId or items[1].id end
		local left = clearFrame(body); left.Size = UDim2.new(0, 290, 1, 0)
		local leftList = scroll(left, 6)
		heading(leftList, "KILL EFFECTS")
		for _, f in ipairs(items) do
			local have = owns("killfx", f.id)
			local r = row(leftList, (have and "" or "🔒 ") .. f.name, f.id == equippedId and "EQUIPPED ★" or (have and string.upper(f.rarity) or ""), f.id == ui.fxSel,
				function() ui.fxSel = f.id; render.ARMORY() end, f.id == equippedId and COL.GOOD or (RARITY_COL[f.rarity] or COL.DIM))
			local bar = frame(r, RARITY_COL[f.rarity] or COL.DIM, 3); bar.Size = UDim2.fromOffset(4, 22); bar.Position = UDim2.new(0, -8, 0.5, -11)
		end
		dim(leftList, "Plays on whoever you finish off, for everyone to see. Looks only.", 12)
		if hidden > 0 then dim(leftList, string.format("%d more to get: tap  ✔ OWNED ONLY  to see them.", hidden), 12) end
		local f = Catalog.KILLFX_BY[ui.fxSel]
		local mid = clearFrame(body); mid.Position = UDim2.new(0, 306, 0, 0); mid.Size = UDim2.new(1, -306 - 400, 1, 0)
		Preview.killFx(mid, f.id, UDim2.fromScale(1, 1))
		itemCardRight(f, "killfx", function(acts, have)
			if not have then return end
			if f.id == equippedId then
				local t = title(acts, "★ EQUIPPED", 20, COL.GOOD); t.Size = UDim2.new(1, 0, 0, 26); t.LayoutOrder = nextOrder()
			else
				local h, b = fatButton(acts, "EQUIP", COL.GREEN, 20); h.Size = UDim2.new(1, 0, 0, 56); h.LayoutOrder = nextOrder()
				b.Activated:Connect(function()
					local r = call("Equip", "killfx", f.id)
					toast(r.ok and (f.name .. " equipped") or (r.msg or ""), r.ok and COL.GOOD or COL.BAD)
					if r.profile then state.profile = r.profile end
					render.ARMORY()
				end)
			end
		end)
	end

	local function emotes()
		local items, hidden = filtered(sortedItems(Catalog.EMOTES), "emotes")
		local wheel = {}
		for _, id in ipairs(state.profile and state.profile.emotes or {}) do table.insert(wheel, id) end
		local inWheel = {}
		for i, id in ipairs(wheel) do inWheel[id] = i end
		if #items == 0 then nothingOwned(body, "emotes"); return end
		local inList = false
		for _, e in ipairs(items) do if e.id == ui.emoteSel then inList = true end end
		if not Catalog.EMOTE[ui.emoteSel or ""] or not inList then ui.emoteSel = (wheel[1] and Catalog.EMOTE[wheel[1]] and wheel[1]) or items[1].id end
		local function saveWheel(list)
			local r = call("Equip", "emotes", list)
			if r.profile then state.profile = r.profile end
			if not r.ok then toast(r.msg or "", COL.BAD) end
			render.ARMORY()
		end
		local left = clearFrame(body); left.Size = UDim2.new(0, 290, 1, 0)
		local leftList = scroll(left, 6)
		heading(leftList, "EMOTES  ·  " .. tostring(ClientSettings.get("Key_Emote") or "B") .. " OPENS THE WHEEL")
		for _, e in ipairs(items) do
			local have = owns("emotes", e.id)
			local r = row(leftList, (have and "" or "🔒 ") .. e.name, inWheel[e.id] and ("ON WHEEL · " .. inWheel[e.id]) or (have and string.upper(e.rarity) or ""), e.id == ui.emoteSel,
				function() ui.emoteSel = e.id; render.ARMORY() end, inWheel[e.id] and COL.GOOD or (RARITY_COL[e.rarity] or COL.DIM))
			local bar = frame(r, RARITY_COL[e.rarity] or COL.DIM, 3); bar.Size = UDim2.fromOffset(4, 22); bar.Position = UDim2.new(0, -8, 0.5, -11)
		end
		if hidden > 0 then dim(leftList, string.format("%d more to get: tap  ✔ OWNED ONLY  to see them.", hidden), 12) end
		local e = Catalog.EMOTE[ui.emoteSel]
		local mid = clearFrame(body); mid.Position = UDim2.new(0, 306, 0, 0); mid.Size = UDim2.new(1, -306 - 400, 1, 0)
		Preview.emote(mid, e.id, UDim2.fromScale(1, 1))
		local list = itemCardRight(e, "emotes", function(acts, have)
			if not have then return end
			if inWheel[e.id] then
				local h, b = fatButton(acts, "TAKE OFF THE WHEEL", COL.GLASS2, 18); h.Size = UDim2.new(1, 0, 0, 52); h.LayoutOrder = nextOrder()
				b.Activated:Connect(function()
					local out = {}
					for _, id in ipairs(wheel) do if id ~= e.id then table.insert(out, id) end end
					saveWheel(out)
				end)
			elseif #wheel < 6 then
				local h, b = fatButton(acts, "PUT ON THE WHEEL", COL.GREEN, 18); h.Size = UDim2.new(1, 0, 0, 52); h.LayoutOrder = nextOrder()
				b.Activated:Connect(function() local out = table.clone(wheel); table.insert(out, e.id); saveWheel(out) end)
			else
				dim(acts, "The wheel is full (6): take one off first.", 13)
			end
		end)
		-- the wheel itself: six slots
		local wp = panel(list, "YOUR WHEEL")
		for i = 1, 6 do
			local id = wheel[i]
			local it = id and Catalog.EMOTE[id]
			row(wp, string.format("%d   %s", i, it and it.name or "—"), it and string.upper(it.rarity) or "empty", false, it and function() ui.emoteSel = id; render.ARMORY() end or nil, it and (RARITY_COL[it.rarity] or COL.DIM) or COL.DIM)
		end
		dim(wp, "In a match or the Courtyard, press " .. tostring(ClientSettings.get("Key_Emote") or "B") .. " and pick one (or its number). Moving or attacking ends it.", 12)
	end

	render.ARMORY = function()
		renderTabs()
		clear(body)
		if ui.armoryTab == "armor" then armor() elseif ui.armoryTab == "killfx" then killfx() elseif ui.armoryTab == "emotes" then emotes() else weapons() end
		renderSide()
	end
	gui:GetAttributeChangedSignal("ArmoryTab"):Connect(function() local t = gui:GetAttribute("ArmoryTab"); if t then ui.armoryTab = t; if currentTab == "ARMORY" then task.spawn(render.ARMORY) end end end)
end

--------------------------------------------------------------------
--  SHOP — DAILY (the packs + the WEAPONS shelf, new every day) · CRATES
--  (a weapon on a stage, the skin strip, the drum) · CROWNS · COLORS
--------------------------------------------------------------------
local openCrowns   -- forward: the + by the Crowns jumps here
do
	local f = tabFrame.SHOP
	local tabs = clearFrame(f); tabs.Size = UDim2.new(1, 0, 0, 46)
	hlist(tabs, 10)
	local body = clearFrame(f); body.Position = UDim2.new(0, 0, 0, 58); body.Size = UDim2.new(1, 0, 1, -58)
	local SHOP_TABS = {{"daily", "DAILY", COL.GOLD}, {"crates", "CRATES", COL.PURPLE}, {"crowns", "CROWNS", COL.GREEN}, {"colors", "COLORS", COL.BLUE}}
	local ALIASES = {store = "daily", weapons = "daily"}

	local function renderTabs()
		clear(tabs)
		for i, t in ipairs(SHOP_TABS) do
			local on = ui.shopTab == t[1]
			local h, b = fatButton(tabs, t[2], on and t[3] or COL.GLASS2, 20)
			h.Size = UDim2.fromOffset(170, 46); h.LayoutOrder = i
			if not on then b.TextColor3 = COL.DIM end
			b.Activated:Connect(function() ui.shopTab = t[1]; render.SHOP() end)
		end
	end

	----------------------------------------------------------------
	--  PACK DETAIL (pop-up): big mannequin, pieces, skins, buy
	----------------------------------------------------------------
	local function packDetail(k)
		local pk = Catalog.PACKS[k]
		local pieces, skins = Packs.pieces(k), Packs.skins(k)
		local all = Packs.owned(k)
		local m, c = Packs.price(k)
		local onSale = Catalog.onSale(k, storeDay())
		local buttons = {}
		if not all and onSale then
			if m > 0 then table.insert(buttons, {"WHOLE PACK  ·  " .. fmt(m) .. " MARKS", COL.BLUE, function() afterBuy(call("Buy", "pack", k, "marks"), render.SHOP) end}) end
			if c > 0 then table.insert(buttons, {"WHOLE PACK  ·  " .. fmt(c) .. " CROWNS", COL.GOLD, function() afterBuy(call("Buy", "pack", k, "crowns"), render.SHOP) end}) end
		end
		modal(pk.name, string.format("%s  ·  %s  ·  %s", pk.weight or "", Packs.rarity(k), all and "owned" or (onSale and string.format("%d%% off as a whole pack", math.floor((pk.bundle or 0) * 100 + 0.5)) or "not in today's shop")), buttons, function(box)
			local two = clearFrame(box); two.Size = UDim2.new(1, 0, 0, 280); two.LayoutOrder = 5
			local th = mannequinThumb(two, Packs.loadout(k), pk.weight, UDim2.new(0, 230, 1, 0), nil, {dist = 9})
			border(th, RARITY_COL[Packs.rarity(k)] or COL.DIM, 2, 0.2)
			local right = clearFrame(two); right.Position = UDim2.new(0, 242, 0, 0); right.Size = UDim2.new(1, -242, 1, 0)
			local rl = scroll(right, 6)
			for _, pc in ipairs(pieces) do
				local have = owns("pieces", pc.id)
				row(rl, pc.name, have and "owned ✔" or priceText(pc.marks, pc.crowns), false, (not have and onSale) and function()
					local opts = {}
					if (pc.marks or 0) > 0 then table.insert(opts, {"BUY  ·  " .. fmt(pc.marks) .. " MARKS", COL.BLUE, function() afterBuy(call("Buy", "piece", pc.id, "marks"), render.SHOP) end}) end
					if (pc.crowns or 0) > 0 then table.insert(opts, {"BUY  ·  " .. fmt(pc.crowns) .. " CROWNS", COL.GOLD, function() afterBuy(call("Buy", "piece", pc.id, "crowns"), render.SHOP) end}) end
					modal(pc.name, pc.description or "", opts)
				end or nil, have and COL.GOOD or COL.MARKS)
			end
			for _, sk in ipairs(skins) do
				local have = owns("skins", sk.id)
				row(rl, (Catalog.WEAPON[sk.weapon] and Catalog.WEAPON[sk.weapon].name or sk.weapon) .. "  ·  " .. sk.name, have and "owned ✔" or priceText(sk.marks, sk.crowns), false, (not have and onSale) and function()
					modal(sk.name, sk.rarity or "", skinBuyButtons(sk, render.SHOP), function(b2) local th2 = weaponStage(b2, sk.weapon, sk.id, UDim2.new(1, 0, 0, 200)); th2.LayoutOrder = 5 end)
				end or nil, have and COL.GOOD or (RARITY_COL[sk.rarity] or COL.MARKS))
			end
			if #pieces == 0 and #skins == 0 then dim(rl, "Nothing names this pack yet.") end
		end, 640)
	end

	-- a weapon offer's pop-up: the skin turning on a big stage, buy
	local function skinDetail(s)
		local w = Catalog.WEAPON[s.weapon]
		local have = owns("skins", s.id)
		modal((w and w.name or s.weapon) .. "  ·  " .. s.name, string.format("%s weapon skin%s%s", s.rarity, s.trim and ("  ·  " .. s.trim .. " trim") or "",
			(w and not owns("weapons", w.id)) and ("  ·  you unlock the " .. w.name .. " at " .. unlockText(w)) or ""),
			(not have and skinOnSale(s.id)) and skinBuyButtons(s, render.SHOP) or nil, function(box)
				local st = weaponStage(box, s.weapon, s.id, UDim2.new(1, 0, 0, 300)); st.LayoutOrder = 5
				border(st, RARITY_COL[s.rarity] or COL.DIM, 2, 0.2)
				if have then local o = title(box, "OWNED ✔", 18, COL.GOOD); o.Size = UDim2.new(1, 0, 0, 22); o.LayoutOrder = 6 end
			end, 620)
	end

	----------------------------------------------------------------
	--  DAILY: the packs on sale, the WEAPONS shelf, what is coming
	----------------------------------------------------------------
	local function daily()
		ui.shopSeen = storeDay()
		local list = scroll(body, 14)
		padding(list, 0, 14, 0, 8)
		-- THIS WEEK: the newest drop, what is on, and what comes next (a teaser)
		local cur = HX.Drops.current()
		if cur then
			local banner = frame(list, COL.GLASS, 14); banner.Size = UDim2.new(1, 0, 0, 200); banner.LayoutOrder = nextOrder()
			border(banner, cur.color or COL.ACCENT, 3, 0.1)
			local wash = frame(banner, cur.color or COL.ACCENT, 12); wash.Size = UDim2.fromScale(1, 1); wash.BackgroundTransparency = 0.5
			do local gg = Instance.new("UIGradient", wash); gg.Transparency = NumberSequence.new(0.1, 1) end
			local hs = cur.headline and Catalog.SKIN[cur.headline]
			if hs then
				local th = weaponThumb(banner, hs.weapon, hs.id, UDim2.new(0.34, 0, 1, -16), 1.2)
				th.AnchorPoint = Vector2.new(1, 0); th.Position = UDim2.new(1, -8, 0, 8); th.BackgroundTransparency = 1
			end
			local tg = title(banner, "THIS WEEK  ·  " .. (cur.tag or "NEW"), 14, cur.color or COL.ACCENT); tg.Position = UDim2.fromOffset(18, 14); tg.Size = UDim2.new(0.6, 0, 0, 18)
			local nm = title(banner, string.upper(cur.name), 36); nm.Position = UDim2.fromOffset(18, 34); nm.Size = UDim2.new(0.62, 0, 0, 42)
			local bl = title(banner, cur.blurb or "", 15); bl.TextWrapped = true; bl.Position = UDim2.fromOffset(18, 80); bl.Size = UDim2.new(0.6, 0, 0, 66); bl.TextYAlignment = Enum.TextYAlignment.Top
			local evs = {}
			for _, e in ipairs(HX.Drops.events()) do table.insert(evs, string.upper(e.name) .. " ENDS IN " .. HX.span(HX.Drops.time(e.to) - HX.Drops.now())) end
			local nxt, at = HX.Drops.next()
			local foot = title(banner, (#evs > 0 and (table.concat(evs, "  ·  ") .. "     ") or "") .. (nxt and ("NEXT DROP IN " .. HX.span(at - HX.Drops.now()) .. "  ·  ???") or ""), 14, COL.ACCENT)
			foot.Position = UDim2.new(0, 18, 1, -32); foot.Size = UDim2.new(0.66, 0, 0, 20)
			if cur.crate and Catalog.CRATES[cur.crate] then
				local gh, gb = fatButton(banner, "OPEN THE " .. string.upper(Catalog.CRATES[cur.crate].name), cur.color or COL.GOLD, 16)
				gh.AnchorPoint = Vector2.new(1, 1); gh.Position = UDim2.new(1, -14, 1, -12); gh.Size = UDim2.fromOffset(280, 44)
				gb.Activated:Connect(function() ui.shopTab = "crates"; ui.crate = cur.crate; ui.crateItem = nil; render.SHOP() end)
			end
		end
		local head = clearFrame(list); head.Size = UDim2.new(1, 0, 0, 34); head.LayoutOrder = nextOrder()
		local t = title(head, "PACKS", 26); t.Size = UDim2.new(0.5, 0, 1, 0)
		local cd = title(head, "", 16, COL.ACCENT); cd.AnchorPoint = Vector2.new(1, 0); cd.Position = UDim2.new(1, 0, 0, 0); cd.Size = UDim2.new(0.5, 0, 1, 0); cd.TextXAlignment = Enum.TextXAlignment.Right
		local function tick() cd.Text = "NEW ITEMS IN  " .. storeCountdown() end
		tick()
		task.spawn(function() while cd.Parent do task.wait(20); tick() end end)
		local onSale = state.store and state.store.packs or {}
		local grid = clearFrame(list); grid.AutomaticSize = Enum.AutomaticSize.Y; grid.Size = UDim2.new(1, 0, 0, 0); grid.LayoutOrder = nextOrder()
		local g = Instance.new("UIGridLayout", grid); g.CellSize = UDim2.new(1 / math.max(1, math.min(3, #onSale)), -10, 0, 330); g.CellPadding = UDim2.fromOffset(14, 14); g.SortOrder = Enum.SortOrder.LayoutOrder
		if #onSale == 0 then dim(list, "Nothing on sale today. Fill Catalog › Store › queue.") end
		for i, k in ipairs(onSale) do
			local pk = Catalog.PACKS[k]
			if pk then
				local all, any = Packs.owned(k)
				local m, c = Packs.price(k)
				local card = button(grid, "", 14, COL.GLASS)
				card.LayoutOrder = i
				card.AutoButtonColor = false
				border(card, RARITY_COL[Packs.rarity(k)] or COL.DIM, 3, 0.1)
				-- a colour wash in the pack's colour behind the mannequin
				local wash = frame(card, pk.color or RARITY_COL[Packs.rarity(k)] or COL.GLASS2, 12); wash.Size = UDim2.new(1, 0, 0, 220); wash.BackgroundTransparency = 0.3
				do local gg = Instance.new("UIGradient", wash); gg.Rotation = 90; gg.Transparency = NumberSequence.new(0, 0.85) end
				local th = mannequinThumb(card, Packs.loadout(k), pk.weight, UDim2.new(1, 0, 0, 220), nil, {dist = 10.5})
				th.BackgroundTransparency = 1
				local tag = rarityTag(card, Packs.rarity(k)); tag.Position = UDim2.new(0, 12, 0, 12)
				if pk.featured then local ft = title(card, "FEATURED", 13, COL.ACCENT); ft.AnchorPoint = Vector2.new(1, 0); ft.Position = UDim2.new(1, -12, 0, 12); ft.Size = UDim2.fromOffset(100, 18); ft.TextXAlignment = Enum.TextXAlignment.Right end
				local n = title(card, pk.name, 24); n.Position = UDim2.new(0, 14, 0, 226); n.Size = UDim2.new(1, -28, 0, 28); n.TextTruncate = Enum.TextTruncate.AtEnd
				local s = title(card, string.format("%s  ·  %d pieces%s", string.upper(pk.weight or ""), #Packs.pieces(k), #Packs.skins(k) > 0 and string.format("  ·  %d weapon skin%s", #Packs.skins(k), #Packs.skins(k) == 1 and "" or "s") or ""), 13, COL.DIM)
				s.Position = UDim2.new(0, 14, 0, 254); s.Size = UDim2.new(1, -28, 0, 18)
				local priceH = frame(card, all and COL.GLASS2 or COL.GOLD, 10); priceH.AnchorPoint = Vector2.new(0, 1); priceH.Position = UDim2.new(0, 12, 1, -12); priceH.Size = UDim2.new(1, -24, 0, 38)
				gloss(priceH, 0.2)
				local pr = title(priceH, all and "OWNED ✔" or (any and ("REST  ·  " .. priceText(m, c)) or priceText(m, c)), 16); pr.Size = UDim2.fromScale(1, 1); pr.TextXAlignment = Enum.TextXAlignment.Center
				hoverScale(card, card, 1.02)
				card.Activated:Connect(function() packDetail(k) end)
			end
		end

		-- the WEAPONS shelf: single skins, one big headliner and the rest
		local wh = clearFrame(list); wh.Size = UDim2.new(1, 0, 0, 34); wh.LayoutOrder = nextOrder()
		local wt = title(wh, "WEAPONS", 26); wt.Size = UDim2.new(0.5, 0, 1, 0)
		local wd = title(wh, "SKINS SOLD ALONE  ·  ONLY TODAY", 14, COL.DIM); wd.AnchorPoint = Vector2.new(1, 0); wd.Position = UDim2.new(1, 0, 0, 0); wd.Size = UDim2.new(0.5, 0, 1, 0); wd.TextXAlignment = Enum.TextXAlignment.Right
		local offers = state.store and state.store.skins or {}
		local shelf = clearFrame(list); shelf.Size = UDim2.new(1, 0, 0, 300); shelf.LayoutOrder = nextOrder()
		if #offers == 0 then dim(list, "No weapon skins on the shelf today.") end
		for i, id in ipairs(offers) do
			local s = Catalog.SKIN[id]
			if s then
				local w = Catalog.WEAPON[s.weapon]
				local have = owns("skins", s.id)
				local headline = i == 1
				local card = button(shelf, "", 14, COL.GLASS)
				card.AutoButtonColor = false
				if headline then card.Position = UDim2.new(0, 0, 0, 0); card.Size = UDim2.new(0.4, -8, 1, 0)
				else card.Position = UDim2.new(0.4 + (i - 2) * 0.2, 6, 0, 0); card.Size = UDim2.new(0.2, -10, 1, 0) end
				border(card, RARITY_COL[s.rarity] or COL.DIM, 3, 0.1)
				local wash = frame(card, RARITY_COL[s.rarity] or COL.GLASS2, 12); wash.Size = UDim2.new(1, 0, 1, 0); wash.BackgroundTransparency = 0.55
				do local gg = Instance.new("UIGradient", wash); gg.Rotation = 90; gg.Transparency = NumberSequence.new(0.2, 1) end
				local th = weaponThumb(card, s.weapon, s.id, UDim2.new(1, -16, 0, 190), headline and 1.25 or 1.6); th.Position = UDim2.new(0, 8, 0, 8); th.BackgroundTransparency = 1
				local tag = rarityTag(card, s.rarity); tag.Position = UDim2.new(0, 12, 0, 12)
				if headline then local hl = title(card, "★ HEADLINER", 13, COL.ACCENT); hl.AnchorPoint = Vector2.new(1, 0); hl.Position = UDim2.new(1, -12, 0, 12); hl.Size = UDim2.fromOffset(120, 18); hl.TextXAlignment = Enum.TextXAlignment.Right end
				local n = title(card, s.name, headline and 24 or 18); n.Position = UDim2.new(0, 12, 0, 200); n.Size = UDim2.new(1, -24, 0, 26); n.TextTruncate = Enum.TextTruncate.AtEnd
				local wn = title(card, string.upper(w and w.name or s.weapon), 13, COL.DIM); wn.Position = UDim2.new(0, 12, 0, 226); wn.Size = UDim2.new(1, -24, 0, 16); wn.TextTruncate = Enum.TextTruncate.AtEnd
				local priceH = frame(card, have and COL.GLASS2 or COL.GOLD, 10); priceH.AnchorPoint = Vector2.new(0, 1); priceH.Position = UDim2.new(0, 10, 1, -10); priceH.Size = UDim2.new(1, -20, 0, 36)
				gloss(priceH, 0.2)
				local pr = title(priceH, have and "OWNED ✔" or priceText(s.marks, s.crowns), 14); pr.Size = UDim2.fromScale(1, 1); pr.TextXAlignment = Enum.TextXAlignment.Center; pr.TextTruncate = Enum.TextTruncate.AtEnd
				hoverScale(card, card, 1.03)
				card.Activated:Connect(function() skinDetail(s) end)
			end
		end

		-- what is coming (the next days), so the player knows what to wait for
		local S = Catalog.STORE
		if S and S.queue and #S.queue > 0 then
			local nx = panel(list, "COMING UP", true)
			local today = storeDay() or os.date("!%Y-%m-%d")
			local y, mo, d = today:match("^(%d+)%-(%d+)%-(%d+)$")
			if y then
				local base = os.time({year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = 12})
				for dayOffset = 1, 2 do
					local key = os.date("!%Y-%m-%d", base + dayOffset * 86400)
					local n2 = {}
					for _, k in ipairs((Catalog.storeFor(key))) do table.insert(n2, Catalog.PACKS[k].name) end
					row(nx, (dayOffset == 1 and "Tomorrow" or "In 2 days"), table.concat(n2, "  ·  "), false, nil, COL.TEXT)
				end
			end
		end
		dim(list, "Skins never go on sale at will: they come out of crates, are earned on the TASKS screen, come with a pack, or sit on this shelf for a day.", 12)
	end

	----------------------------------------------------------------
	--  CRATES: the chosen item on a stage, the strip, the drum
	----------------------------------------------------------------
	local function crates()
		local left = clearFrame(body); left.Size = UDim2.new(1, -372, 1, 0)
		local right = clearFrame(body); right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 360, 1, 0)
		local rightList = scroll(right, 10)
		-- only the crates in rotation now: events first, then the featured ones, then the always-there
		local liveCrates = {}
		for k, c in pairs(Catalog.CRATES) do
			local live, leaves, rule = HX.Drops.crateLive(k)
			if live then table.insert(liveCrates, {id = k, c = c, leaves = leaves, event = rule and rule.event ~= nil, featured = rule ~= nil and not rule.always}) end
		end
		table.sort(liveCrates, function(a, b)
			local ra = a.event and 0 or (a.featured and 1 or 2)
			local rb = b.event and 0 or (b.featured and 1 or 2)
			if ra ~= rb then return ra < rb end
			return a.id < b.id
		end)
		local liveOf = {}
		for _, lc in ipairs(liveCrates) do liveOf[lc.id] = lc end
		if not liveOf[ui.crate] then ui.crate = liveCrates[1] and liveCrates[1].id; ui.crateItem = nil end
		local crate = Catalog.CRATES[ui.crate]
		if not crate then dim(left, "No crates in rotation right now."); return end
		local pool = Catalog.crateItems(ui.crate)
		table.sort(pool, function(a, b)
			if (RARITY_ORDER[a.rarity] or 0) ~= (RARITY_ORDER[b.rarity] or 0) then return (RARITY_ORDER[a.rarity] or 0) > (RARITY_ORDER[b.rarity] or 0) end
			return a.kind .. a.id < b.kind .. b.id
		end)
		local function keyOf(it) return it.kind .. "|" .. it.id end
		local function ownKind(it) return it.kind == "skin" and "skins" or (it.kind == "killfx" and "killfx" or "emotes") end
		local sel
		for _, it in ipairs(pool) do if keyOf(it) == ui.crateItem then sel = it end end
		sel = sel or pool[1]
		ui.crateItem = sel and keyOf(sel)
		-- stage: a skin on its weapon, a kill effect / emote on you
		local stageH = clearFrame(left); stageH.Size = UDim2.new(1, 0, 1, -196)
		if sel then
			local stg
			if sel.kind == "skin" then stg = weaponStage(stageH, sel.weapon, sel.id)
			elseif sel.kind == "killfx" then stg = Preview.killFx(stageH, sel.id, UDim2.fromScale(1, 1))
			else stg = Preview.emote(stageH, sel.id, UDim2.fromScale(1, 1)) end
			local nm = title(stg, sel.name, 32); nm.Position = UDim2.fromOffset(18, 12); nm.Size = UDim2.new(1, -36, 0, 36)
			local kindText = sel.kind == "skin" and string.upper(Catalog.WEAPON[sel.weapon] and Catalog.WEAPON[sel.weapon].name or sel.weapon) or (sel.kind == "killfx" and "KILL EFFECT" or "EMOTE")
			local fxText = sel.kind == "skin" and Preview.fxText(sel.ref) or nil
			local wn = title(stg, kindText .. (fxText and ("  ·  " .. string.upper(fxText)) or ""), 16, COL.DIM); wn.Position = UDim2.fromOffset(20, 48); wn.Size = UDim2.new(1, -40, 0, 20)
			local tag = rarityTag(stg, sel.rarity); tag.AnchorPoint = Vector2.new(1, 0); tag.Position = UDim2.new(1, -16, 0, 16)
			local have = owns(ownKind(sel), sel.id)
			local nOf = 0
			for _, it in ipairs(pool) do if it.rarity == sel.rarity then nOf += 1 end end
			local each = (crate.odds[sel.rarity] or 0) / math.max(1, nOf)
			local note = title(stg, have and "OWNED ✔" or string.format("%s CHANCE FOR A %s PER OPEN  ·  %s FOR THIS ONE", HX.pct(crate.odds[sel.rarity] or 0), string.upper(sel.rarity), HX.pct(each)), 14, have and COL.GOOD or COL.DIM)
			note.AnchorPoint = Vector2.new(0, 1); note.Position = UDim2.new(0, 20, 1, -14); note.Size = UDim2.new(1, -40, 0, 18)
		else
			dim(stageH, "This crate is empty: point some skins, kill effects or emotes at it.")
		end
		-- strip
		local stripH = clearFrame(left); stripH.AnchorPoint = Vector2.new(0, 1); stripH.Position = UDim2.new(0, 0, 1, 0); stripH.Size = UDim2.new(1, 0, 0, 184)
		local _, sf = Preview.strip(stripH, pool, sel and keyOf(sel), function(it) ui.crateItem = keyOf(it); render.SHOP() end, 184)
		-- right: the crates, open, odds, pulls
		local names = {}
		for _, lc in ipairs(liveCrates) do
			table.insert(names, {text = (lc.event and "★ " or (lc.featured and "◆ " or "")) .. lc.c.name, id = lc.id})
		end
		chips(rightList, names, function(it) return it.id == ui.crate end, function(it) ui.crate = it.id; ui.crateItem = nil; render.SHOP() end, 34)
		do   -- what's coming: the next drop that brings a crate
			local nd, nt = HX.Drops.nextWith("crate")
			local nc = nd and Catalog.CRATES[nd.crate]
			if nc and nt then
				local up = title(rightList, string.format("NEW CRATE IN %s  ·  %s", HX.span(nt - HX.Drops.now()), string.upper(nc.name)), 13, COL.ACCENT)
				up.Size = UDim2.new(1, 0, 0, 18); up.LayoutOrder = nextOrder()
			end
		end
		local lc = liveOf[ui.crate]
		local c1 = panel(rightList, crate.name)
		local P = state.profile or {}
		local cc = P.crates and P.crates[ui.crate] or {opens = 0, sinceLegendary = 0}
		-- in rotation how long: an event crate, a featured one leaving, or always here
		local when = lc.event and "EVENT CRATE" or (lc.featured and "FEATURED" or "ALWAYS IN THE ARMOURY")
		if lc.leaves then when ..= "  ·  LEAVES IN " .. HX.span(lc.leaves - HX.Drops.now()) end
		if lc.event or (lc.featured and not HX.Drops.crateReturns(ui.crate, math.huge)) then when ..= "  ·  NEVER COMES BACK" end
		local wl = title(c1, when, 13, lc.event and RARITY_COL.Mythic or COL.ACCENT); wl.Size = UDim2.new(1, 0, 0, 18); wl.LayoutOrder = nextOrder()
		dim(c1, crate.description or "", 13)
		-- the odds for YOUR next open (the pity, when due, shows as it is)
		local since = cc.sinceLegendary or 0
		local odds, pityDue = crate.odds, false
		if since >= (crate.pity or 20) - 1 then
			local l, m = crate.odds.Legendary or 0, crate.odds.Mythic or 0
			odds, pityDue = (l + m > 0) and {Legendary = 100 * l / (l + m), Mythic = 100 * m / (l + m)} or {Legendary = 100}, true
		end
		if pityDue then local pd = title(c1, "YOUR NEXT OPEN IS GUARANTEED LEGENDARY OR BETTER", 13, RARITY_COL.Legendary); pd.Size = UDim2.new(1, 0, 0, 18); pd.LayoutOrder = nextOrder() end
		for i = #Catalog.RARITIES, 1, -1 do
			local r = Catalog.RARITIES[i]
			if odds[r] then
				local rr = clearFrame(c1); rr.Size = UDim2.new(1, 0, 0, 18); rr.LayoutOrder = nextOrder()
				local l = title(rr, string.upper(r), 12, RARITY_COL[r]); l.Size = UDim2.fromOffset(90, 18)
				local bh = clearFrame(rr); bh.Position = UDim2.fromOffset(92, 2); bh.Size = UDim2.new(1, -150, 0, 14)
				progressBar(bh, math.max(odds[r] / 100, 0.01), RARITY_COL[r], nil, 14)
				local pt = title(rr, HX.pct(odds[r]), 12); pt.AnchorPoint = Vector2.new(1, 0); pt.Position = UDim2.new(1, 0, 0, 0); pt.Size = UDim2.fromOffset(54, 18); pt.TextXAlignment = Enum.TextXAlignment.Right
			end
		end
		local V = ECON.variants or {}
		dim(c1, string.format("Every skin also rolls a finish: Masterwork %s · Radiant %s (otherwise Standard). Within a rarity every item is equally likely.", HX.pct(V.Masterwork or 0), HX.pct(V.Radiant or 0)), 12)
		dim(c1, string.format("A Legendary or better is guaranteed within %d opens  ·  %d since your last.", crate.pity or 20, since), 12)
		local rf = {}
		for _, r in ipairs(Catalog.RARITIES) do if crate.refund and crate.refund[r] then table.insert(rf, string.lower(r) .. " " .. fmt(crate.refund[r])) end end
		dim(c1, "Duplicates pay Marks back (" .. table.concat(rf, " · ") .. ") and count toward forging the skin a better finish.", 12)
		-- open with a Key (earned only) or Crowns (not where paid random items are barred)
		local keys = P.wallet and P.wallet.keys or 0
		local need = crate.keys or 1
		local openH, openBtn = fatButton(c1, string.format("OPEN  ·  %d KEY%s  (YOU HAVE %d)", need, need > 1 and "S" or "", keys), keys >= need and COL.PURPLE or COL.GLASS2, 20)
		openH.Size = UDim2.new(1, 0, 0, 56); openH.LayoutOrder = nextOrder()
		local crownH, crownBtn
		if not P.restricted then
			crownH, crownBtn = fatButton(c1, "OPEN  ·  " .. tostring(crate.cost) .. " CROWNS", COL.GOLD, 20)
			crownH.Size = UDim2.new(1, 0, 0, 56); crownH.LayoutOrder = nextOrder()
		else
			dim(c1, "In your region crates open with Keys only. Keys are earned: a Key every level-up, one for your first win each day, more from tasks and events.", 12)
		end
		local rollNote = dim(c1, ui.rolling and "rolling…" or "")
		local function open(payWith, btn)
			if ui.rolling or #pool == 0 then return end
			ui.rolling = true
			btn.Active = false
			rollNote.Text = "rolling…"
			local r = call("OpenCrate", ui.crate, payWith)
			if not r.ok then ui.rolling = false; btn.Active = true; toast(r.msg or "", COL.BAD); rollNote.Text = r.msg or ""; return end
			if r.profile then state.profile = r.profile; refreshWallet() end
			local res = r.result
			-- the strip spins: flick through the pool fast, slow down, stop on the win
			local wonIndex = 1
			for i, it in ipairs(pool) do if it.kind == (res.kind or "skin") and it.id == (res.itemId or res.skinId) then wonIndex = i end end
			local cardW = 132
			local total = #pool * 3 + wonIndex - 1
			local t0 = os.clock()
			local dur = 3.6
			HX.FX.play("DrumRoll")
			local tick = HX.FX.ticker("Tick")
			while os.clock() - t0 < dur do
				local fr = (os.clock() - t0) / dur
				local eased = 1 - (1 - fr) * (1 - fr) * (1 - fr)
				local pos = eased * total * cardW
				sf.CanvasPosition = Vector2.new(pos % (#pool * cardW), 0)
				-- a tick each card that passes; higher as it slows to a stop
				tick(math.floor(pos / cardW + 0.5), 1 + fr * 0.35)
				task.wait()
			end
			sf.CanvasPosition = Vector2.new((wonIndex - 1) * cardW, 0)
			task.wait(0.35)
			HX.revealMoment(sf, res.rarity, res.variant, res.dup)
			ui.rolling = false
			table.insert(ui.pulls, 1, res)
			local kind = res.kind or "skin"
			ui.crateItem = kind .. "|" .. (res.itemId or res.skinId)
			local won = res.skinId and Catalog.SKIN[res.skinId]
			local line = kind == "skin" and "New skin! Equip it from the ARMORY or your LOADOUT." or (kind == "killfx" and "New kill effect! Equip it in the ARMORY." or "New emote! Put it on your wheel in the ARMORY.")
			if res.variant then line = string.upper(res.variant) .. " FINISH!  " .. line end
			local dupLine = res.copies and string.format("Another copy: you have %d. Trade it, scrap it, or forge three into a better finish.", res.copies)
				or string.format("Duplicate — %s Marks back.", fmt(res.refund))
			if res.dup and res.variant then dupLine = string.upper(res.variant) .. " FINISH!  " .. dupLine end
			modal(string.upper(res.rarity) .. "!  " .. res.name .. (res.serial and ("  #" .. fmt(res.serial)) or ""), res.dup and dupLine or line,
				{{"EQUIP IT", COL.GREEN, function()
					closeModal()
					if kind == "skin" then ui.armoryTab = "weapons"; ui.shopWeapon = won and won.weapon or res.weapon; ui.shopSkin = res.skinId
					elseif kind == "killfx" then ui.armoryTab = "killfx"; ui.fxSel = res.itemId
					else ui.armoryTab = "emotes"; ui.emoteSel = res.itemId end
					selectTab("ARMORY")
				end}}, function(box)
					local th
					if kind == "skin" then th = weaponStage(box, won and won.weapon or res.weapon, res.skinId, UDim2.new(1, 0, 0, 240))
					elseif kind == "killfx" then th = Preview.killFx(box, res.itemId, UDim2.new(1, 0, 0, 260))
					else th = Preview.emote(box, res.itemId, UDim2.new(1, 0, 0, 260)) end
					th.LayoutOrder = 5
					border(th, RARITY_COL[res.rarity] or COL.DIM, 3, 0)
				end, 560)
			render.SHOP()
		end
		openBtn.Activated:Connect(function() open("keys", openBtn) end)
		if crownBtn then crownBtn.Activated:Connect(function() open("crowns", crownBtn) end) end
		local pl = panel(rightList, "YOUR PULLS THIS SESSION", true)
		if #ui.pulls == 0 then dim(pl, "Nothing yet.") end
		for i, pu in ipairs(ui.pulls) do if i <= 8 then row(pl, pu.name .. (pu.serial and (" #" .. pu.serial) or ""), pu.dup and ("dup +" .. fmt(pu.refund)) or ((pu.variant and (pu.variant .. " ") or "") .. pu.rarity), false, nil, HX.VARIANT_COL[pu.variant] or RARITY_COL[pu.rarity]) end end
	end

	----------------------------------------------------------------
	--  CROWNS: the Robux bundles (art + price from the Developer Products,
	--  via the server) and the one-way Crowns › Marks exchange
	----------------------------------------------------------------
	local products, productsAt = nil, 0
	local function crowns()
		if not products or os.clock() - productsAt > 120 then
			local r = call("Products")
			products = (r.ok and r.products) or {}
			productsAt = os.clock()
		end
		local list = scroll(body, 14)
		local head = title(list, "GET CROWNS", 26); head.Size = UDim2.new(1, 0, 0, 32); head.LayoutOrder = nextOrder()
		dim(list, "Crowns open crates and buy packs, shelf skins and premium colours. Marks are earned by playing — or exchanged from Crowns, one way.", 13)
		local grid = clearFrame(list); grid.LayoutOrder = nextOrder()
		grid.Size = UDim2.new(1, 0, 0, 0); grid.AutomaticSize = Enum.AutomaticSize.Y
		local gl = Instance.new("UIGridLayout", grid)
		gl.CellSize = UDim2.new(0.25, -12, 0, 330); gl.CellPadding = UDim2.fromOffset(16, 16); gl.SortOrder = Enum.SortOrder.LayoutOrder
		local tierCol = {RARITY_COL.Common, RARITY_COL.Rare, RARITY_COL.Epic, RARITY_COL.Legendary}
		for i, pr in ipairs(ECON.products or {}) do
			local live = products[i] or {}
			local card = frame(grid, COL.GLASS, 16); card.LayoutOrder = i
			border(card, tierCol[math.min(i, #tierCol)] or COL.DIM, 3, 0.1)
			local wash = frame(card, tierCol[math.min(i, #tierCol)] or COL.GLASS2, 14); wash.Size = UDim2.new(1, 0, 1, 0); wash.BackgroundTransparency = 0.55
			do local gg = Instance.new("UIGradient", wash); gg.Rotation = 90; gg.Transparency = NumberSequence.new(0.1, 1) end
			local img = Instance.new("ImageLabel"); img.BackgroundTransparency = 1; img.ScaleType = Enum.ScaleType.Fit
			img.Size = UDim2.new(1, -20, 0, 170); img.Position = UDim2.fromOffset(10, 10)
			img.Image = live.icon and ("rbxassetid://" .. tostring(live.icon)) or iconTexture("Crowns")
			img.Parent = card
			if pr.bonus then
				local b = title(card, pr.bonus .. " BONUS", 13); b.BackgroundTransparency = 0; b.BackgroundColor3 = COL.GREEN
				b.Size = UDim2.fromOffset(100, 24); b.Position = UDim2.fromOffset(12, 12); b.TextXAlignment = Enum.TextXAlignment.Center
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
			end
			local n = title(card, fmt(pr.crowns), 40); n.Position = UDim2.fromOffset(0, 184); n.Size = UDim2.new(1, 0, 0, 44); n.TextXAlignment = Enum.TextXAlignment.Center
			local w = title(card, "CROWNS", 15, COL.CROWNS); w.Position = UDim2.fromOffset(0, 228); w.Size = UDim2.new(1, 0, 0, 18); w.TextXAlignment = Enum.TextXAlignment.Center
			local price = live.robux or pr.robux
			local bh, buy = fatButton(card, live.ready == false and "COMING SOON" or ("R$ " .. fmt(price)), live.ready == false and COL.GLASS2 or COL.GREEN, 22)
			bh.AnchorPoint = Vector2.new(0.5, 1); bh.Position = UDim2.new(0.5, 0, 1, -12); bh.Size = UDim2.new(1, -24, 0, 54)
			buy.Activated:Connect(function()
				local res = call("BuyCrowns", i)
				toast(res.msg or "", res.ok and COL.GOOD or COL.BAD)
			end)
		end
		local ex = panel(list, "CROWNS › MARKS")
		for i, e in ipairs(ECON.exchange or {}) do
			row(ex, fmt(e.marks) .. " Marks", fmt(e.crowns) .. " Crowns", false, function() afterBuy(call("Exchange", i), render.SHOP) end, COL.MARKS)
		end
	end

	local function colors()
		local list = scroll(body, 10)
		local two = clearFrame(list); two.AutomaticSize = Enum.AutomaticSize.Y; two.Size = UDim2.new(1, 0, 0, 0); two.LayoutOrder = nextOrder()
		hlist(two, 12)
		local a = panel(two, "PREMIUM ARMOR COLOURS"); a.Size = UDim2.new(0.5, -6, 0, 0)
		local n = 0
		for _, c in ipairs(Catalog.PALETTE) do
			if c.crowns then
				n += 1
				local have = owns("colors", c.name)
				local r = row(a, "        " .. c.name, have and "owned ✔" or (tostring(c.crowns) .. " CROWNS"), false, (not have) and function() afterBuy(call("Buy", "color", c.name, "crowns"), render.SHOP) end or nil, have and COL.GOOD or COL.CROWNS)
				local sw = frame(r, c.color, 6); sw.Size = UDim2.fromOffset(24, 24); sw.Position = UDim2.new(0, 0, 0.5, -12)
			end
		end
		if n == 0 then dim(a, "No premium colours (Catalog › Palette, crowns = …).") end
		dim(a, "Bought once, usable on every slot of every class.")
		local b = panel(two, "PREMIUM HAIR COLOURS & BEARDS"); b.Size = UDim2.new(0.5, -6, 0, 0)
		n = 0
		for _, h in ipairs(Catalog.BODY.hairColors) do
			if h.crowns then
				n += 1
				local have = owns("hairColors", h.name)
				local r = row(b, "        " .. h.name .. " hair", have and "owned ✔" or (tostring(h.crowns) .. " CROWNS"), false, (not have) and function() afterBuy(call("Buy", "hairColor", h.name, "crowns"), render.SHOP) end or nil, have and COL.GOOD or COL.CROWNS)
				local sw = frame(r, h.color, 6); sw.Size = UDim2.fromOffset(24, 24); sw.Position = UDim2.new(0, 0, 0.5, -12)
			end
		end
		for _, bd in ipairs(Catalog.BODY.beards) do
			if bd.crowns then
				n += 1
				local have = owns("beards", bd.id)
				row(b, bd.name .. " beard", have and "owned ✔" or (tostring(bd.crowns) .. " CROWNS"), false, (not have) and function() afterBuy(call("Buy", "beard", bd.id, "crowns"), render.SHOP) end or nil, have and COL.GOOD or COL.CROWNS)
			end
		end
		if n == 0 then dim(b, "Nothing premium here yet (Catalog › Body).") end
	end

	render.SHOP = function()
		ui.shopTab = ALIASES[ui.shopTab] or ui.shopTab
		renderTabs()
		clear(body)
		if ui.shopTab == "crates" then crates() elseif ui.shopTab == "crowns" then crowns() elseif ui.shopTab == "colors" then colors() else ui.shopTab = "daily"; daily() end
		renderSide()
	end
	openCrowns = function() ui.shopTab = "crowns"; selectTab("SHOP") end
	-- testing hook (like Tab / ShopTab): set attribute OpenCrowns on the ScreenGui
	gui:GetAttributeChangedSignal("OpenCrowns"):Connect(function() if gui:GetAttribute("OpenCrowns") then openCrowns() end end)
end
crownsPlus.Activated:Connect(function() if openCrowns then openCrowns() end end)

--------------------------------------------------------------------
--  TASKS — today's three + the weekly, the task-skin track (skins earned by
--  finishing tasks), and mastery (skins, armor and titles earned in battle)
--------------------------------------------------------------------
do
	local f = tabFrame.TASKS
	local left = clearFrame(f); left.Size = UDim2.new(0.4, -8, 1, 0)
	local leftList = scroll(left, 12)
	local right = clearFrame(f); right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0.6, -8, 1, 0)
	local rightList = scroll(right, 12)

	local function taskCard(parent, ct)
		local r = frame(parent, ct.weekly and Color3.fromRGB(56, 36, 90) or COL.GLASS2, 14)
		r.BackgroundTransparency = ct.done and 0.4 or 0.05
		r.Size = UDim2.new(1, 0, 0, 104)
		r.LayoutOrder = nextOrder()
		border(r, ct.done and COL.GOOD or (ct.weekly and COL.PURPLE or WHITE), 2, ct.done and 0.2 or 0.8)
		padding(r, 16, 16, 12, 12)
		local tag = title(r, ct.weekly and "WEEKLY" or "DAILY", 12, ct.weekly and Color3.fromRGB(210, 170, 255) or COL.DIM)
		tag.Size = UDim2.fromOffset(120, 14)
		local t = title(r, ct.text, 20, ct.done and COL.DIM or COL.TEXT)
		t.Position = UDim2.fromOffset(0, 16); t.Size = UDim2.new(1, -110, 0, 26); t.TextTruncate = Enum.TextTruncate.AtEnd
		local rw = clearFrame(r); rw.AnchorPoint = Vector2.new(1, 0); rw.Position = UDim2.new(1, 0, 0, 2); rw.Size = UDim2.fromOffset(104, 40)
		local ic = iconImage(rw, "Marks", 40)
		local pay = title(rw, "+" .. fmt(ct.pay), 18, COL.MARKS); pay.Position = UDim2.fromOffset(40, 9); pay.Size = UDim2.fromOffset(64, 22)
		local barH = clearFrame(r); barH.AnchorPoint = Vector2.new(0, 1); barH.Position = UDim2.new(0, 0, 1, 0); barH.Size = UDim2.new(1, 0, 0, 24)
		progressBar(barH, ct.goal > 0 and ct.n / ct.goal or 0, ct.done and COL.GOOD or (ct.weekly and COL.PURPLE or COL.BLUE),
			ct.done and "DONE ✔  ·  PAID" or string.format("%s / %s", fmt(ct.n), fmt(ct.goal)), 24)
		if ct.done then
			local check = title(r, "✔", 40, COL.GOOD); check.AnchorPoint = Vector2.new(1, 0.5); check.Position = UDim2.new(1, -4, 0.5, 0); check.Size = UDim2.fromOffset(40, 40); check.TextXAlignment = Enum.TextXAlignment.Right
			rw.Visible = false
		end
		return r
	end

	-- the task skins: unlocked by finishing tasks, counted for life
	local function taskSkins()
		local out = {}
		for _, s in ipairs(Catalog.SKINS) do
			if s.unlock and s.unlock.stat == "contract" then table.insert(out, s) end
		end
		table.sort(out, function(a, b) return (a.unlock.n or 0) < (b.unlock.n or 0) end)
		return out
	end

	local function renderLeft()
		clear(leftList)
		local p = panel(leftList, nil)
		local h = clearFrame(p); h.Size = UDim2.new(1, 0, 0, 40); h.LayoutOrder = 0
		local t = title(h, "TODAY", 28); t.Size = UDim2.new(0.5, 0, 1, 0)
		local cd = title(h, "", 14, COL.ACCENT); cd.AnchorPoint = Vector2.new(1, 0); cd.Position = UDim2.new(1, 0, 0, 0); cd.Size = UDim2.new(0.5, 0, 1, 0); cd.TextXAlignment = Enum.TextXAlignment.Right
		local function tick() cd.Text = "NEW TASKS IN " .. storeCountdown() end
		tick()
		task.spawn(function() while cd.Parent do task.wait(30); tick() end end)
		local n, done = 0, 0
		for _, ct in ipairs(state.contracts or {}) do
			if not ct.weekly then n += 1; if ct.done then done += 1 end; taskCard(p, ct) end
		end
		if n == 0 then dim(p, "Tasks load with your profile.") end
		dim(p, string.format("%d of %d done today. Every finished task pays Marks, moves you along the task-skin track and gives %d season pass XP.", done, n, Catalog.PASS and Catalog.PASS.taskXP or 0), 13)
		local w = panel(leftList, nil)
		local wt = title(w, "THIS WEEK", 24); wt.Size = UDim2.new(1, 0, 0, 30); wt.LayoutOrder = 0
		local any = false
		for _, ct in ipairs(state.contracts or {}) do if ct.weekly then any = true; taskCard(w, ct) end end
		if not any then dim(w, "No weekly task this week.") end
		dim(leftList, "Tasks count in every mode except cheat servers. Everyone gets the same tasks each day.", 12)
	end

	local function renderRight()
		clear(rightList)
		local done = state.profile and state.profile.stats and state.profile.stats.contract or 0
		local track = taskSkins()
		local p = panel(rightList, nil)
		local h = clearFrame(p); h.Size = UDim2.new(1, 0, 0, 40); h.LayoutOrder = 0
		local t = title(h, "TASK REWARDS", 28); t.Size = UDim2.new(0.6, 0, 1, 0)
		local c = title(h, string.format("%d TASKS DONE", done), 18, COL.ACCENT); c.AnchorPoint = Vector2.new(1, 0); c.Position = UDim2.new(1, 0, 0, 0); c.Size = UDim2.new(0.4, 0, 1, 0); c.TextXAlignment = Enum.TextXAlignment.Right
		local nextOne
		for _, s in ipairs(track) do if (s.unlock.n or 0) > done then nextOne = s; break end end
		local bh = clearFrame(p); bh.Size = UDim2.new(1, 0, 0, 22); bh.LayoutOrder = nextOrder()
		if nextOne then
			progressBar(bh, done / nextOne.unlock.n, COL.PURPLE, string.format("%d MORE FOR %s", nextOne.unlock.n - done, string.upper(nextOne.name)), 22)
		else
			progressBar(bh, 1, COL.GOOD, "THE WHOLE TRACK IS YOURS", 22)
		end
		-- the track: one card per skin, left to right
		local holder = clearFrame(p); holder.Size = UDim2.new(1, 0, 0, 236); holder.LayoutOrder = nextOrder()
		local sf = Instance.new("ScrollingFrame")
		sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0; sf.Size = UDim2.fromScale(1, 1)
		sf.CanvasSize = UDim2.new(); sf.AutomaticCanvasSize = Enum.AutomaticSize.X; sf.ScrollingDirection = Enum.ScrollingDirection.X
		sf.ScrollBarThickness = 6; sf.ScrollBarImageColor3 = COL.DIM
		sf.Parent = holder
		hlist(sf, 12).VerticalAlignment = Enum.VerticalAlignment.Center
		padding(sf, 4, 4, 6, 10)
		for i, s in ipairs(track) do
			local have = done >= (s.unlock.n or 0)
			local card = frame(sf, have and Color3.fromRGB(30, 60, 40) or COL.GLASS2, 14)
			card.Size = UDim2.fromOffset(170, 216); card.LayoutOrder = i
			border(card, have and COL.GOOD or (RARITY_COL[s.rarity] or COL.DIM), 3, have and 0 or 0.3)
			local th = weaponThumb(card, s.weapon, s.id, UDim2.new(1, -12, 0, 120), 1.4); th.Position = UDim2.fromOffset(6, 6); th.BackgroundTransparency = 1
			local need = title(card, string.format("%d TASKS", s.unlock.n or 0), 13); need.BackgroundTransparency = 0; need.BackgroundColor3 = have and COL.GOOD or COL.PURPLE
			need.Position = UDim2.fromOffset(10, 10); need.Size = UDim2.fromOffset(80, 20); need.TextXAlignment = Enum.TextXAlignment.Center
			Instance.new("UICorner", need).CornerRadius = UDim.new(0, 6)
			local n = title(card, s.name, 16); n.Position = UDim2.fromOffset(10, 130); n.Size = UDim2.new(1, -20, 0, 20); n.TextTruncate = Enum.TextTruncate.AtEnd
			local w = title(card, string.upper(Catalog.WEAPON[s.weapon] and Catalog.WEAPON[s.weapon].name or s.weapon), 12, COL.DIM); w.Position = UDim2.fromOffset(10, 150); w.Size = UDim2.new(1, -20, 0, 16); w.TextTruncate = Enum.TextTruncate.AtEnd
			local rt = rarityTag(card, s.rarity); rt.Position = UDim2.fromOffset(10, 170)
			local st = title(card, have and "✔ YOURS" or "🔒", 14, have and COL.GOOD or COL.DIM); st.AnchorPoint = Vector2.new(1, 0); st.Position = UDim2.new(1, -10, 0, 170); st.Size = UDim2.fromOffset(70, 20); st.TextXAlignment = Enum.TextXAlignment.Right
			local bh2 = clearFrame(card); bh2.AnchorPoint = Vector2.new(0, 1); bh2.Position = UDim2.new(0, 10, 1, -8); bh2.Size = UDim2.new(1, -20, 0, 10)
			progressBar(bh2, math.clamp(done / math.max(s.unlock.n or 1, 1), 0, 1), have and COL.GOOD or COL.PURPLE, nil, 10)
		end
		if #track == 0 then dim(p, "No task skins yet (Catalog › Skins, unlock = {stat = \"contract\", n = …}).") end

		-- MASTERY: kill skins for the weapons you use, armor and titles earned in battle
		local m = panel(rightList, "MASTERY  ·  EARNED IN BATTLE")
		local items = {}
		for _, s in ipairs(Catalog.SKINS) do
			if s.unlock and s.unlock.kills and s.unlock.weapon and (owns("weapons", s.weapon) or progressFrac(s.unlock) > 0) then
				local w = Catalog.WEAPON[s.weapon]
				table.insert(items, {text = (w and w.name or s.weapon) .. "  ·  " .. s.name .. " skin", u = s.unlock, have = owns("skins", s.id), color = RARITY_COL[s.rarity]})
			end
		end
		for _, pc in ipairs(Catalog.PIECES) do
			if pc.unlock then table.insert(items, {text = pc.name .. "  ·  " .. string.lower(pc.weight) .. " " .. (pc.slot == "bottom" and "legs" or pc.slot), u = pc.unlock, have = owns("pieces", pc.id), color = RARITY_COL[pc.rarity]}) end
		end
		for _, et in ipairs(Catalog.BODY.earnedTitles or {}) do
			table.insert(items, {text = "Title: " .. et.title, u = et.unlock, have = owns("titles", et.title), color = COL.ACCENT})
		end
		table.sort(items, function(a, b)
			if a.have ~= b.have then return not a.have end
			local fa, fb = progressFrac(a.u), progressFrac(b.u)
			if fa ~= fb then return fa > fb end
			return a.text < b.text
		end)
		for i, it in ipairs(items) do
			if i > 24 then break end
			local r = frame(m, COL.GLASS2, 10); r.Size = UDim2.new(1, 0, 0, 54); r.LayoutOrder = nextOrder(); r.BackgroundTransparency = it.have and 0.4 or 0.05
			padding(r, 12, 12, 6, 8)
			local bar = frame(r, it.color or COL.DIM, 3); bar.Size = UDim2.fromOffset(4, 38); bar.Position = UDim2.new(0, -8, 0, 0)
			local tt = title(r, it.text, 15, it.have and COL.DIM or COL.TEXT); tt.Size = UDim2.new(1, -150, 0, 20); tt.TextTruncate = Enum.TextTruncate.AtEnd
			local need = title(r, it.have and "EARNED ✔" or Catalog.unlockText(it.u), 12, it.have and COL.GOOD or COL.DIM); need.AnchorPoint = Vector2.new(1, 0); need.Position = UDim2.new(1, 0, 0, 2); need.Size = UDim2.fromOffset(240, 16); need.TextXAlignment = Enum.TextXAlignment.Right; need.TextTruncate = Enum.TextTruncate.AtEnd
			local bh3 = clearFrame(r); bh3.AnchorPoint = Vector2.new(0, 1); bh3.Position = UDim2.new(0, 0, 1, 0); bh3.Size = UDim2.new(1, 0, 0, 16)
			progressBar(bh3, it.have and 1 or progressFrac(it.u), it.have and COL.GOOD or COL.BLUE, it.have and nil or progressText(it.u), 16)
		end
		if #items == 0 then dim(m, "Nothing to earn yet.") end
	end

	render.TASKS = function()
		loadState()
		renderLeft()
		renderRight()
		renderSide()
	end
end

--------------------------------------------------------------------
--  WARDROBE (APPEARANCE) — hair, beard, face, skin, hair colour, title
--------------------------------------------------------------------
do
	local f = tabFrame.APPEARANCE
	local left = clearFrame(f); left.Size = UDim2.new(1, -452, 1, 0)
	local stageHolder = clearFrame(left); stageHolder.Size = UDim2.new(1, 0, 1, -72)
	local _, stage, stageHint = stageBlock(stageHolder, "", {dist = 5.6, platform = COL.BLUE, fov = 40, focusY = 0.7})
	local foot = clearFrame(left); foot.AnchorPoint = Vector2.new(0, 1); foot.Position = UDim2.new(0, 0, 1, 0); foot.Size = UDim2.new(1, 0, 0, 60)
	screenFoot.APPEARANCE = foot
	local right = clearFrame(f); right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 440, 1, 0)
	local list = scroll(right, 10)

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
			stage:set({{loadout = lo, appearance = a, weight = weightOf(state.activeClass), weapon = false, tag = player.DisplayName, sub = className(state.activeClass) .. "'s helmet on"}})
			stageHint.Text = "THE ACTIVE CLASS'S HELMET SHOWS WHAT IT HIDES"
		else
			stage:set({{loadout = lo, appearance = a, armor = false, weapon = false, tag = player.DisplayName, sub = a.title or ""}})
			stageHint.Text = "ARMOR AND WEAPON COME OFF WHILE YOU EDIT  ·  DRAG TO TURN, SCROLL TO ZOOM"
		end
	end
	local function set(k, v, buyKind, price)
		local a = draft()
		if buyKind and not owns(buyKind, v) then
			modal("PREMIUM", string.format("%s costs %d Crowns, once, forever.", tostring(v), price or 0), {{"BUY  ·  " .. tostring(price) .. " CROWNS", COL.GOLD, function()
				local r = call("Buy", buyKind == "hairColors" and "hairColor" or "beard", v, "crowns")
				toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
				if r.profile then state.profile = r.profile; refreshWallet() end
				closeModal()
				if r.ok then set(k, v) end
			end}})
			return
		end
		a[k] = v
		ui.appDirty = true
		render.APPEARANCE()
	end
	-- a grid of word tiles (hair, beards)
	local function wordGrid(parent, items, isOn, onClick, lockedText)
		local g = clearFrame(parent)
		g.AutomaticSize = Enum.AutomaticSize.Y
		g.Size = UDim2.new(1, 0, 0, 0)
		g.LayoutOrder = nextOrder()
		local gl = Instance.new("UIGridLayout", g)
		gl.CellSize = UDim2.new(1 / 3, -7, 0, 40)
		gl.CellPadding = UDim2.fromOffset(10, 8)
		gl.SortOrder = Enum.SortOrder.LayoutOrder
		for i, it in ipairs(items) do
			local on = isOn(it)
			local lock = lockedText and lockedText(it)
			local b = button(g, (lock and "🔒 " or "") .. it.name, 14, on and COL.BLUE or COL.GLASS2)
			b.LayoutOrder = i
			b.TextTruncate = Enum.TextTruncate.AtEnd
			if lock then
				b.TextColor3 = COL.CROWNS
				local pr = label(b, lock, 10, FONT, COL.CROWNS); pr.AnchorPoint = Vector2.new(0.5, 1); pr.Position = UDim2.new(0.5, 0, 1, -1); pr.Size = UDim2.new(1, 0, 0, 11); pr.TextXAlignment = Enum.TextXAlignment.Center
			end
			b.Activated:Connect(function() onClick(it) end)
		end
		return g
	end
	render.APPEARANCE = function()
		local a = draft()
		clear(list)
		local fp = panel(list, "FACE")
		do
			local g = clearFrame(fp)
			g.AutomaticSize = Enum.AutomaticSize.Y
			g.Size = UDim2.new(1, 0, 0, 0)
			g.LayoutOrder = nextOrder()
			local gl = Instance.new("UIGridLayout", g)
			gl.CellSize = UDim2.fromOffset(74, 92)
			gl.CellPadding = UDim2.fromOffset(8, 8)
			gl.SortOrder = Enum.SortOrder.LayoutOrder
			local tone = Catalog.BODY.skins[a.skin or Catalog.BODY.defaults.skin] or Catalog.BODY.skins[1]
			for i, fc in ipairs(Catalog.BODY.faces) do
				local on = a.face == fc.id
				local b = button(g, "", 12, on and COL.BLUE or COL.GLASS2)
				b.LayoutOrder = i
				border(b, on and WHITE or COL.GLASS2, on and 3 or 1, on and 0 or 0.6)
				local disc = frame(b, tone, 30); disc.AnchorPoint = Vector2.new(0.5, 0); disc.Position = UDim2.new(0.5, 0, 0, 6); disc.Size = UDim2.fromOffset(60, 60)
				disc:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
				local img = Instance.new("ImageLabel"); img.BackgroundTransparency = 1; img.Size = UDim2.fromScale(1, 1); img.Image = faceTexture(fc.id); img.ScaleType = Enum.ScaleType.Fit; img.Parent = disc
				local n = title(b, fc.name, 11); n.AnchorPoint = Vector2.new(0.5, 1); n.Position = UDim2.new(0.5, 0, 1, -4); n.Size = UDim2.new(1, -6, 0, 14); n.TextXAlignment = Enum.TextXAlignment.Center; n.TextTruncate = Enum.TextTruncate.AtEnd
				b.Activated:Connect(function() set("face", fc.id) end)
			end
		end
		local hp = panel(list, "HAIR")
		wordGrid(hp, Catalog.BODY.hair, function(it) return a.hair == it.id end, function(it) set("hair", it.id) end)
		heading(hp, "HAIR COLOUR")
		swatches(hp, Catalog.BODY.hairColors, function(it) return a.hairColor == it.name end, function(it) return it.crowns and not owns("hairColors", it.name) end,
			function(it) set("hairColor", it.name, it.crowns and "hairColors" or nil, it.crowns) end, 34)
		local bp = panel(list, "BEARD")
		wordGrid(bp, Catalog.BODY.beards, function(it) return a.beard == it.id end, function(it) set("beard", it.id, it.crowns and "beards" or nil, it.crowns) end,
			function(it) return (it.crowns and not owns("beards", it.id)) and (tostring(it.crowns) .. " CROWNS") or nil end)
		local sp = panel(list, "SKIN")
		local tones = {}
		for i, c in ipairs(Catalog.BODY.skins) do table.insert(tones, {i = i, color = c}) end
		swatches(sp, tones, function(it) return a.skin == it.i end, function() return false end, function(it) set("skin", it.i) end, 38)
		local tp = panel(list, "TITLE")
		local titles = {}
		for _, t in ipairs(Catalog.BODY.titles) do titles[t] = true end
		if state.profile and state.profile.owned and state.profile.owned.titles then for t in pairs(state.profile.owned.titles) do titles[t] = true end end
		local ordered = {}
		for t in pairs(titles) do table.insert(ordered, t) end
		table.sort(ordered)
		local items = {}
		for _, t in ipairs(ordered) do table.insert(items, {name = t}) end
		for _, et in ipairs(Catalog.BODY.earnedTitles or {}) do
			if owns("titles", et.title) and not titles[et.title] then table.insert(items, {name = et.title}) end
		end
		wordGrid(tp, items, function(it) return a.title == it.name end, function(it) set("title", it.name) end)
		local locked = {}
		for _, et in ipairs(Catalog.BODY.earnedTitles or {}) do if not owns("titles", et.title) then table.insert(locked, et) end end
		if #locked > 0 then
			heading(tp, "EARN MORE")
			for _, et in ipairs(locked) do row(tp, "🔒 " .. et.title, Catalog.unlockText(et.unlock) .. "  ·  " .. progressText(et.unlock), false, nil, COL.DIM) end
		end
		dim(list, "Locked colours and beards are premium: bought once with Crowns.", 12)
		renderStage()
		renderSide()
	end
	render.APPEARANCE_save = function()
		local r = call("SaveAppearance", draft())
		if r.ok then
			toast("appearance saved", COL.GOOD)
			if r.profile then state.profile = r.profile end
			ui.appDraft = nil; ui.appDirty = false
			render.APPEARANCE()
		else toast(r.msg or "save failed", COL.BAD) end
	end
end

--------------------------------------------------------------------
--  REWARDS (shared by the pass and the login gifts)
--------------------------------------------------------------------
-- a reward's look inside a card: a skin on its weapon, a currency, a crate, a title
local function rewardVisual(parent, r, h)
	h = h or 110
	if r.egg and Catalog.EGG[r.egg] then
		local e = Catalog.EGG[r.egg]
		local th = Preview.egg(parent, e.id, UDim2.new(1, -8, 0, h), nil, true); th.Position = UDim2.fromOffset(4, 4)
		return e.name, RARITY_COL[e.rarity], "EGG"
	end
	if r.companion and Catalog.COMPANION[r.companion] then
		local c = Catalog.COMPANION[r.companion]
		local th = Preview.companion(parent, c.id, UDim2.new(1, -8, 0, h), true); th.Position = UDim2.fromOffset(4, 4)
		return c.name, RARITY_COL[c.rarity], "COMPANION"
	end
	if r.killfx and Catalog.KILLFX_BY[r.killfx] then
		local f = Catalog.KILLFX_BY[r.killfx]
		local th = Preview.killFx(parent, f.id, UDim2.new(1, -8, 0, h), 0.3); th.Position = UDim2.fromOffset(4, 4)
		return f.name, RARITY_COL[f.rarity], "KILL EFFECT"
	end
	if r.emote and Catalog.EMOTE[r.emote] then
		local e = Catalog.EMOTE[r.emote]
		local th = Preview.emote(parent, e.id, UDim2.new(1, -8, 0, h), 0.45); th.Position = UDim2.fromOffset(4, 4)
		return e.name, RARITY_COL[e.rarity], "EMOTE"
	end
	if r.skin and Catalog.SKIN[r.skin] then
		local s = Catalog.SKIN[r.skin]
		local th = weaponThumb(parent, s.weapon, s.id, UDim2.new(1, -8, 0, h), 1.5)
		th.Position = UDim2.fromOffset(4, 4); th.BackgroundTransparency = 1
		return s.name, RARITY_COL[s.rarity], (Catalog.WEAPON[s.weapon] and Catalog.WEAPON[s.weapon].name or s.weapon)
	end
	local icon, text, col, sub
	if r.marks then icon, text, col, sub = "Marks", fmt(r.marks), COL.MARKS, "MARKS"
	elseif r.crowns then icon, text, col, sub = "Crowns", fmt(r.crowns), COL.CROWNS, "CROWNS"
	elseif r.crate then icon, text, col, sub = "Shop", "FREE OPEN", COL.PURPLE, string.upper(Catalog.CRATES[r.crate] and Catalog.CRATES[r.crate].name or r.crate)
	elseif r.title then icon, text, col, sub = "Wardrobe", r.title, COL.ACCENT, "TITLE"
	else icon, text, col, sub = "Shop", "?", COL.DIM, "" end
	local img = iconImage(parent, icon, math.floor(h * 0.72))
	img.AnchorPoint = Vector2.new(0.5, 0); img.Position = UDim2.new(0.5, 0, 0, 2)
	return text, col, sub
end

-- one reward card. state: "claimed" | "claim" | "locked" | "premium-locked"
local function rewardCard(parent, r, state, onClaim, premium)
	local card = frame(parent, premium and Color3.fromRGB(58, 42, 14) or COL.GLASS2, 14)
	card.BackgroundTransparency = state == "claimed" and 0.45 or 0.05
	border(card, state == "claim" and COL.GREEN or (premium and COL.GOLD or WHITE), state == "claim" and 3 or 2, state == "claim" and 0 or (premium and 0.3 or 0.8))
	local text, col, sub = rewardVisual(card, r, 96)
	local t = title(card, text or "", 15, col or COL.TEXT)
	t.Position = UDim2.new(0, 6, 0, 104); t.Size = UDim2.new(1, -12, 0, 18); t.TextXAlignment = Enum.TextXAlignment.Center; t.TextTruncate = Enum.TextTruncate.AtEnd
	local s2 = title(card, sub or "", 11, COL.DIM)
	s2.Position = UDim2.new(0, 6, 0, 122); s2.Size = UDim2.new(1, -12, 0, 14); s2.TextXAlignment = Enum.TextXAlignment.Center; s2.TextTruncate = Enum.TextTruncate.AtEnd
	if state == "claim" then
		local b = button(card, "CLAIM", 15, COL.GREEN)
		b.AnchorPoint = Vector2.new(0.5, 1); b.Position = UDim2.new(0.5, 0, 1, -6); b.Size = UDim2.new(1, -12, 0, 30)
		b.Activated:Connect(onClaim)
	elseif state == "claimed" then
		local c = title(card, "✔", 26, COL.GOOD); c.AnchorPoint = Vector2.new(0.5, 1); c.Position = UDim2.new(0.5, 0, 1, -4); c.Size = UDim2.new(1, 0, 0, 30); c.TextXAlignment = Enum.TextXAlignment.Center
	else
		local lock = frame(card, Color3.new(0, 0, 0), 14); lock.Size = UDim2.fromScale(1, 1); lock.BackgroundTransparency = 0.55
		local l = title(lock, "🔒", 26); l.AnchorPoint = Vector2.new(0.5, 1); l.Position = UDim2.new(0.5, 0, 1, -6); l.Size = UDim2.new(1, 0, 0, 30); l.TextXAlignment = Enum.TextXAlignment.Center
	end
	return card
end

-- days and hours until a UTC date ("2026-11-17"), by the server's clock
local function untilDate(dateKey)
	local y, mo, d = (dateKey or ""):match("^(%d+)%-(%d+)%-(%d+)$")
	if not y then return "" end
	local st = state.store
	local now = st and st.serverTime and (st.serverTime + (os.clock() - (st.at or 0))) or os.time()
	local ends = os.time({year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = 0}) - (os.time() - os.time(os.date("!*t", os.time())))
	local left = math.max(0, ends - now)
	local days, hours = math.floor(left / 86400), math.floor(left % 86400 / 3600)
	return days > 0 and string.format("%dd %dh", days, hours) or string.format("%dh", hours)
end

passClaimable = function()
	local P, ps = Catalog.PASS, state.pass
	if not (P and ps) then return 0 end
	local n = 0
	for i = 1, math.min(ps.tier or 0, #P.tiers) do
		if P.tiers[i].free and not (ps.claimedFree or {})[tostring(i)] then n += 1 end
		if ps.premium and P.tiers[i].premium and not (ps.claimedPremium or {})[tostring(i)] then n += 1 end
	end
	return n
end

--------------------------------------------------------------------
--  SEASON PASS — tiers climbed by playing and finishing tasks; a free
--  track and a premium one (Catalog ▸ Pass)
--------------------------------------------------------------------
do
	local f = tabFrame.PASS
	local head = clearFrame(f); head.Size = UDim2.new(1, 0, 0, 132)
	local track = clearFrame(f); track.Position = UDim2.new(0, 0, 0, 144); track.Size = UDim2.new(1, 0, 1, -144)
	local claiming = false

	local function claim(tier, kind)
		if claiming then return end
		claiming = true
		local r = call("PassClaim", tier, kind)
		claiming = false
		toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
		if r.pass then state.pass = r.pass end
		if r.profile then state.profile = r.profile; refreshWallet() end
		if r.crate and r.crate.skinId then
			local won = Catalog.SKIN[r.crate.skinId]
			modal(string.upper(r.crate.rarity) .. "!  " .. r.crate.name, r.crate.dup and string.format("Duplicate — %s Marks back.", fmt(r.crate.refund)) or "A free crate open from the pass.", nil, function(box)
				local th = weaponStage(box, won and won.weapon or r.crate.weapon, r.crate.skinId, UDim2.new(1, 0, 0, 220)); th.LayoutOrder = 5
				border(th, RARITY_COL[r.crate.rarity] or COL.DIM, 3, 0)
			end, 520)
		end
		render.PASS(true)
	end

	render.PASS = function(fresh)
		if not fresh then loadState() end
		local P = Catalog.PASS
		local ps = state.pass or {xp = 0, tier = 0, premium = false, claimedFree = {}, claimedPremium = {}}
		clear(head); clear(track)
		-- the header: your tier, the bar to the next, the season clock, premium
		local box = frame(head, COL.GLASS, 16); box.BackgroundTransparency = 0.1; box.Size = UDim2.new(1, 0, 1, 0)
		border(box, WHITE, 1.5, 0.85)
		padding(box, 22, 22, 14, 14)
		local tierT = title(box, "TIER " .. tostring(ps.tier or 0), 46, COL.ACCENT); tierT.Size = UDim2.fromOffset(260, 52)
		local nm = title(box, string.upper(P.name or ""), 18); nm.Position = UDim2.fromOffset(270, 4); nm.Size = UDim2.new(0.5, 0, 0, 24); nm.TextTruncate = Enum.TextTruncate.AtEnd
		local endsT = title(box, "ENDS IN " .. untilDate(P.ends), 14, COL.DIM); endsT.Position = UDim2.fromOffset(270, 30); endsT.Size = UDim2.new(0.5, 0, 0, 18)
		local maxTier = #P.tiers
		local into = (ps.tier or 0) >= maxTier and P.tierXP or ((ps.xp or 0) - (ps.tier or 0) * P.tierXP)
		local barH = clearFrame(box); barH.Position = UDim2.fromOffset(0, 66); barH.Size = UDim2.new(0.6, 0, 0, 24)
		progressBar(barH, into / P.tierXP, COL.GOLD, (ps.tier or 0) >= maxTier and "MAX TIER" or string.format("%s / %s XP TO TIER %d", fmt(into), fmt(P.tierXP), (ps.tier or 0) + 1), 24)
		local how = title(box, string.format("EVERY ROUND'S XP COUNTS  ·  +%d PER DAILY TASK, x3 FOR THE WEEKLY", P.taskXP or 0), 12, COL.DIM)
		how.Position = UDim2.fromOffset(0, 94); how.Size = UDim2.new(0.6, 0, 0, 16)
		if ps.premium then
			local pb = title(box, "★ PREMIUM", 28, COL.GOLD); pb.AnchorPoint = Vector2.new(1, 0); pb.Position = UDim2.new(1, 0, 0, 10); pb.Size = UDim2.fromOffset(320, 34); pb.TextXAlignment = Enum.TextXAlignment.Right
			local pbs = title(box, "EVERY PREMIUM REWARD IS YOURS AS YOU CLIMB", 12, COL.DIM); pbs.AnchorPoint = Vector2.new(1, 0); pbs.Position = UDim2.new(1, 0, 0, 46); pbs.Size = UDim2.fromOffset(380, 16); pbs.TextXAlignment = Enum.TextXAlignment.Right
		else
			local bh, bb = fatButton(box, "UNLOCK PREMIUM  ·  " .. tostring(P.price) .. " CROWNS", COL.GOLD, 20)
			bh.AnchorPoint = Vector2.new(1, 0); bh.Position = UDim2.new(1, 0, 0, 0); bh.Size = UDim2.fromOffset(400, 62)
			local skins = 0
			for _, t in ipairs(P.tiers) do if t.premium and t.premium.skin then skins += 1 end end
			local bs = title(box, string.format("%d PREMIUM REWARDS  ·  %d EXCLUSIVE SKINS  ·  TIERS YOU REACHED COUNT", maxTier, skins), 12, COL.DIM)
			bs.AnchorPoint = Vector2.new(1, 0); bs.Position = UDim2.new(1, 0, 0, 70); bs.Size = UDim2.fromOffset(420, 16); bs.TextXAlignment = Enum.TextXAlignment.Right
			bb.Activated:Connect(function()
				modal("UNLOCK THE PREMIUM PASS?", string.format("%s for %d Crowns: the premium track's %d rewards, including %d exclusive skins. Tiers you already reached unlock right away.", P.name, P.price, maxTier, skins),
					{{"UNLOCK  ·  " .. tostring(P.price) .. " CROWNS", COL.GOLD, function()
						local r = call("PassBuy")
						toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
						if r.pass then state.pass = r.pass end
						if r.profile then state.profile = r.profile; refreshWallet() end
						closeModal()
						if not r.ok and r.msg == "not enough Crowns" then openCrowns() else render.PASS(true) end
					end}})
			end)
		end
		local claimAll = passClaimable()
		if claimAll > 0 then
			local ch, cb = fatButton(box, "CLAIM ALL  ·  " .. claimAll, COL.GREEN, 18)
			if ps.premium then ch.AnchorPoint = Vector2.new(1, 1); ch.Position = UDim2.new(1, 0, 1, 4)
			else ch.AnchorPoint = Vector2.new(1, 0); ch.Position = UDim2.new(1, -414, 0, 0) end
			ch.Size = UDim2.fromOffset(220, ps.premium and 44 or 62)
			cb.Activated:Connect(function()
				if claiming then return end
				claiming = true
				local r = call("PassClaimAll")
				claiming = false
				if r.pass then state.pass = r.pass end
				if r.profile then state.profile = r.profile; refreshWallet() end
				if not r.ok then toast(r.msg or "", COL.BAD); return end
				toast(r.msg or "", COL.GOOD)
				render.PASS(true)
				-- what came out: every line, and the skins the free crate opens rolled
				modal("REWARDS CLAIMED", table.concat(r.lines or {}, "\n"), nil, function(box2)
					local crates = r.crates or {}
					if #crates > 0 then
						local strip = clearFrame(box2); strip.Size = UDim2.new(1, 0, 0, 130); strip.LayoutOrder = 5
						hlist(strip, 8)
						for i, c in ipairs(crates) do
							if i > 4 then break end
							local s = Catalog.SKIN[c.skinId]
							local th = weaponThumb(strip, s and s.weapon or c.weapon, c.skinId, UDim2.fromOffset(120, 120), 1.4)
							th.LayoutOrder = i
							border(th, RARITY_COL[c.rarity] or COL.DIM, 2, 0.1)
						end
					end
				end, 560)
			end)
		end
		-- the track: one column per tier, free on top, premium below
		local labels = clearFrame(track); labels.Size = UDim2.new(0, 96, 1, 0)
		local fl = title(labels, "FREE", 18); fl.Position = UDim2.fromOffset(0, 66); fl.Size = UDim2.new(1, -8, 0, 24)
		local pl = title(labels, "PREMIUM", 18, COL.GOLD); pl.Position = UDim2.fromOffset(0, 66 + 214); pl.Size = UDim2.new(1, -8, 0, 24)
		local sf = Instance.new("ScrollingFrame")
		sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
		sf.Position = UDim2.new(0, 100, 0, 0); sf.Size = UDim2.new(1, -100, 1, 0)
		sf.CanvasSize = UDim2.new(); sf.AutomaticCanvasSize = Enum.AutomaticSize.X; sf.ScrollingDirection = Enum.ScrollingDirection.X
		sf.ScrollBarThickness = 8; sf.ScrollBarImageColor3 = COL.DIM
		sf.Parent = track
		hlist(sf, 12)
		padding(sf, 4, 4, 4, 12)
		for i, t in ipairs(P.tiers) do
			local col = clearFrame(sf); col.Size = UDim2.fromOffset(158, 444); col.LayoutOrder = i
			local reached = (ps.tier or 0) >= i
			local num = title(col, tostring(i), 22, reached and COL.ACCENT or COL.DIM)
			num.BackgroundTransparency = 0; num.BackgroundColor3 = reached and Color3.fromRGB(70, 56, 14) or COL.GLASS
			num.AnchorPoint = Vector2.new(0.5, 0); num.Position = UDim2.new(0.5, 0, 0, 0); num.Size = UDim2.fromOffset(46, 34); num.TextXAlignment = Enum.TextXAlignment.Center
			Instance.new("UICorner", num).CornerRadius = UDim.new(0, 10)
			local line = frame(col, reached and COL.GOLD or COL.GLASS2); line.Position = UDim2.new(0, -6, 0, 40); line.Size = UDim2.new(1, 12, 0, 6)
			if t.free then
				local done = (ps.claimedFree or {})[tostring(i)]
				local st = done and "claimed" or (reached and "claim" or "locked")
				local c = rewardCard(col, t.free, st, function() claim(i, "free") end, false)
				c.Position = UDim2.fromOffset(0, 54); c.Size = UDim2.new(1, 0, 0, 180)
			end
			if t.premium then
				local done = (ps.claimedPremium or {})[tostring(i)]
				local st = done and "claimed" or ((reached and ps.premium) and "claim" or "locked")
				local c = rewardCard(col, t.premium, st, function() claim(i, "premium") end, true)
				c.Position = UDim2.fromOffset(0, 54 + 194); c.Size = UDim2.new(1, 0, 0, 180)
			end
		end
		-- open on your tier
		task.defer(function()
			-- the first unclaimed reward, or a little before your tier
			local first = nil
			for i = 1, math.min(ps.tier or 0, maxTier) do
				if (P.tiers[i].free and not (ps.claimedFree or {})[tostring(i)]) or (ps.premium and P.tiers[i].premium and not (ps.claimedPremium or {})[tostring(i)]) then first = i; break end
			end
			local x = math.max(0, ((first or (ps.tier or 0)) - 2) * 170)
			sf.CanvasPosition = Vector2.new(x, 0)
		end)
		renderSide()
	end
end

--------------------------------------------------------------------
--  HATCHERY — your nests, your eggs, the egg shelf and your companions
--  (Economy ▸ Pastimes on the server; the Hatchery itself stands in the
--  Courtyard, where your eggs hatch faster while you stay)
--------------------------------------------------------------------
do
	local f = tabFrame.HATCHERY
	local tabs = clearFrame(f); tabs.Size = UDim2.new(1, 0, 0, 46)
	hlist(tabs, 10)
	local body = clearFrame(f); body.Position = UDim2.new(0, 0, 0, 58); body.Size = UDim2.new(1, 0, 1, -58)
	local TABS = {{"nests", "NESTS"}, {"companions", "COMPANIONS"}}
	ui.hatchTab = ui.hatchTab or "nests"
	local E = Catalog.EGGS
	local busy = false

	local function skipCost(left) return math.max(E.skipMin or 3, math.ceil(left / 3600 * (E.skipCrowns or 10))) end
	local function apply(r)
		if r.profile then state.profile = r.profile; refreshWallet() end
		if r.hatchery then state.hatchery = r.hatchery end
	end

	local function hatch(i, now)
		if busy then return end
		busy = true
		local nest = state.hatchery and state.hatchery.nests and state.hatchery.nests[tostring(i)]
		local eggId = nest and nest.egg
		local r = call("Hatch", i, now == true)
		if r.ok and r.result then HX.hatchMoment(body, eggId, r.result.rarity, r.result.variant, r.result.dup) end
		busy = false
		apply(r)
		if not r.ok or not r.result then toast(r.msg or "", COL.BAD); render.HATCHERY(); return end
		local res = r.result
		local line = res.dup and ((res.refund or 0) > 0 and string.format("%s again: +%s Marks.", res.name, fmt(res.refund)) or string.format("%s again: now ★%d.", res.name, res.stars or 1))
			or "A new companion! It follows you around the Courtyard and your matches."
		local out = state.profile and state.profile.companion or ""
		local buttons = {}
		if out ~= res.id then
			table.insert(buttons, {"TAKE IT ALONG", COL.GREEN, function()
				closeModal()
				local r2 = call("Companion", res.id); apply(r2)
				toast(r2.msg or "", r2.ok and COL.GOOD or COL.BAD)
				ui.hatchTab = "companions"; ui.compSel = res.id; render.HATCHERY()
			end})
		end
		modal(string.upper(res.rarity) .. "!  " .. res.name, line, buttons, function(box)
			local v = Preview.companion(box, res.id, UDim2.new(1, 0, 0, 260), false, res.stars); v.LayoutOrder = 5
			border(v, RARITY_COL[res.rarity] or COL.DIM, 3, 0)
		end, 520)
		render.HATCHERY()
	end

	local function place(eggId, nest)
		local r = call("EggPlace", eggId, nest)
		apply(r)
		toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
		render.HATCHERY()
	end
	local function hatchTime(eg) return eg.minutes >= 60 and (math.floor(eg.minutes / 60 * 10) / 10 .. " h") or (eg.minutes .. " min") end
	local function priceOf(eg) return eg.marks and (fmt(eg.marks) .. " MARKS") or (eg.crowns and (fmt(eg.crowns) .. " CROWNS")) or nil end

	-- an egg as a card: its picture, its name, how many you have, how long it
	-- takes, and a line at the foot (what clicking it does)
	local function eggCard(parent, eg, count, w, h, foot, footColor)
		local mine = (count or 0) > 0
		local c = button(parent, "", 12, mine and COL.GLASS2 or Color3.fromRGB(14, 16, 26))
		c.Size = UDim2.fromOffset(w, h)
		border(c, RARITY_COL[eg.rarity] or WHITE, mine and 2.5 or 1.5, mine and 0.1 or 0.7)
		local th = Preview.egg(c, eg.id, UDim2.new(1, -12, 0, h - 84), nil, not mine)
		th.Position = UDim2.fromOffset(6, 6); th.BackgroundTransparency = 1
		if th:IsA("ViewportFrame") and not mine then th.ImageTransparency = 0.55 end
		local cnt = title(c, mine and ("×" .. count) or "NONE", mine and 18 or 12, mine and WHITE or COL.DIM)
		cnt.AnchorPoint = Vector2.new(1, 0); cnt.Position = UDim2.new(1, -8, 0, 6); cnt.Size = UDim2.fromOffset(60, 22); cnt.TextXAlignment = Enum.TextXAlignment.Right
		local nm = title(c, eg.name, 14, RARITY_COL[eg.rarity] or WHITE)
		nm.Position = UDim2.new(0, 6, 1, -76); nm.Size = UDim2.new(1, -12, 0, 18); nm.TextXAlignment = Enum.TextXAlignment.Center; nm.TextTruncate = Enum.TextTruncate.AtEnd
		local sub = label(c, string.upper(eg.rarity) .. "  ·  hatches in " .. hatchTime(eg), 11, FONT_BODY, COL.DIM)
		sub.Position = UDim2.new(0, 6, 1, -56); sub.Size = UDim2.new(1, -12, 0, 16); sub.TextXAlignment = Enum.TextXAlignment.Center
		if foot then
			local f = title(c, foot, 13, footColor or COL.ACCENT)
			f.Position = UDim2.new(0, 6, 1, -34); f.Size = UDim2.new(1, -12, 0, 26); f.TextXAlignment = Enum.TextXAlignment.Center; f.TextTruncate = Enum.TextTruncate.AtEnd
		end
		return c
	end

	-- SET AN EGG: your egg inventory pops up; pick one for this nest (one you
	-- don't have yet can be bought right there, if the shelf sells it)
	local pickEgg
	pickEgg = function(nest)
		local h = state.hatchery or {}
		local mine = h.eggs or {}
		local total = 0
		for _, e in ipairs(E.eggs) do total += mine[e.id] or 0 end
		modal("SET AN EGG IN NEST " .. nest,
			total > 0 and string.format("Your eggs (%d). Pick one to set it warming: it keeps warming while you're away, even offline.", total)
				or "You have no eggs yet. Buy one below, or earn them from playtime gifts, login days and the season pass.",
			nil, function(box)
				local grid = clearFrame(box)
				grid.Size = UDim2.new(1, 0, 0, 0); grid.AutomaticSize = Enum.AutomaticSize.Y; grid.LayoutOrder = 3
				local gl = Instance.new("UIGridLayout", grid)
				gl.CellSize = UDim2.fromOffset(152, 236); gl.CellPadding = UDim2.fromOffset(10, 10); gl.SortOrder = Enum.SortOrder.LayoutOrder
				for i, e in ipairs(E.eggs) do
					local n = mine[e.id] or 0
					local price = priceOf(e)
					local foot = n > 0 and "SET IT  ›" or (price and ("BUY  ·  " .. price) or "gifts · login · pass")
					local card = eggCard(grid, e, n, 152, 236, foot, n > 0 and COL.GOOD or (price and (e.crowns and COL.GOLD or COL.ACCENT) or COL.DIM))
					card.LayoutOrder = (n > 0 and 0 or 10) + i
					card.Activated:Connect(function()
						if n > 0 then closeModal(); place(e.id, nest); return end
						if not price then toast(e.name .. " comes from playtime gifts, login days and the pass", COL.BAD); return end
						local r = call("EggBuy", e.id); apply(r)
						toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
						if r.ok then
							local r2 = call("Hatchery"); if r2.ok then state.hatchery = r2.hatchery end
							pickEgg(nest)
						end
					end)
				end
			end, 700)
	end

	local function nests()
		local h = state.hatchery or {nests = {}, eggs = {}, count = E.nests}
		local count = h.count or E.nests
		local left = clearFrame(body); left.Size = UDim2.new(1, -424, 1, 0)
		local row3 = clearFrame(left); row3.Size = UDim2.new(1, 0, 0, 476)
		hlist(row3, 14)
		for i = 1, count do
			local nest = h.nests and h.nests[tostring(i)]
			local e = nest and Catalog.EGG[nest.egg]
			local card = frame(row3, COL.GLASS, 16); card.BackgroundTransparency = 0.1
			card.Size = UDim2.new(1 / count, -10, 1, 0); card.LayoutOrder = i
			border(card, e and (RARITY_COL[e.rarity] or WHITE) or WHITE, e and 2.5 or 1.5, e and 0.15 or 0.85)
			padding(card, 12, 12, 12, 12)
			local tl = title(card, "NEST " .. i, 15, COL.DIM); tl.Size = UDim2.new(1, 0, 0, 20)
			if e then
				local readyAt = os.clock() + (nest.left or 0)
				local view = Preview.egg(card, e.id, UDim2.new(1, 0, 0, 232), function() return (readyAt - os.clock()) <= 0 and 0.8 or 0.06 end)
				view.Position = UDim2.fromOffset(0, 26)
				local nm = title(card, e.name, 22); nm.Position = UDim2.fromOffset(0, 266); nm.Size = UDim2.new(1, 0, 0, 26); nm.TextTruncate = Enum.TextTruncate.AtEnd
				local tag = rarityTag(card, e.rarity); tag.Position = UDim2.fromOffset(0, 296)
				local barH = clearFrame(card); barH.Position = UDim2.fromOffset(0, 326); barH.Size = UDim2.new(1, 0, 0, 26)
				local track, fill = progressBar(barH, 0, COL.GOLD, "", 26)
				local txt = track:FindFirstChildOfClass("TextLabel")
				local act, actB = fatButton(card, "", COL.GREEN, 20)
				act.AnchorPoint = Vector2.new(0, 1); act.Position = UDim2.new(0, 0, 1, 0); act.Size = UDim2.new(1, 0, 0, 56)
				local function tick()
					local leftS = readyAt - os.clock()
					local fr = 1 - math.clamp(leftS / math.max(nest.need or 1, 1), 0, 1)
					fill.Size = UDim2.new(fr, 0, 1, 0); fill.Visible = fr > 0.001
					if txt then txt.Text = leftS <= 0 and "READY!" or Preview.clock(leftS) end
					if leftS <= 0 then paintFat(act, actB, "HATCH!", COL.GREEN)
					else paintFat(act, actB, "HATCH NOW  ·  " .. skipCost(leftS) .. " CROWNS", Color3.fromRGB(150, 120, 40)) end
				end
				tick()
				task.spawn(function() while card.Parent do task.wait(0.5); tick() end end)
				actB.Activated:Connect(function()
					local leftS = readyAt - os.clock()
					if leftS <= 0 then hatch(i, false); return end
					local cost = skipCost(leftS)
					modal("HATCH IT NOW?", string.format("%s left. Skip the wait for %d Crowns, or stand by the Hatchery in the Courtyard: eggs hatch %d× faster there.", Preview.clock(leftS), cost, E.boost or 2),
						{{"HATCH NOW  ·  " .. cost .. " CROWNS", COL.GOLD, function() closeModal(); hatch(i, true) end}})
				end)
			else
				local hole = frame(card, Color3.fromRGB(14, 16, 26), 14); hole.Position = UDim2.fromOffset(0, 26); hole.Size = UDim2.new(1, 0, 0, 232)
				local straw = title(hole, "an empty nest", 18, COL.DIM); straw.Size = UDim2.fromScale(1, 1); straw.TextXAlignment = Enum.TextXAlignment.Center
				local hint = dim(card, "Set an egg here and it starts warming, even while you're away.", 13)
				hint.Position = UDim2.fromOffset(0, 270); hint.Size = UDim2.new(1, 0, 0, 40)
				local act, actB = fatButton(card, "SET AN EGG", COL.BLUE, 20)
				act.AnchorPoint = Vector2.new(0, 1); act.Position = UDim2.new(0, 0, 1, 0); act.Size = UDim2.new(1, 0, 0, 56)
				actB.Activated:Connect(function() pickEgg(i) end)
			end
		end
		local tip = dim(left, string.format("Eggs keep warming in real time while you're away, in a match or offline. Stand by the Hatchery in the Courtyard and they hatch %d× faster. A hatched egg gives a companion that follows you around: looks only, never stats.", E.boost or 2), 14)
		tip.Position = UDim2.fromOffset(4, 490); tip.Size = UDim2.new(1, -8, 0, 60)

		-- right: your eggs (every kind, how many you hold), then the shelf
		local right = clearFrame(body); right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 410, 1, 0)
		local list = scroll(right, 10)
		local total = 0
		for _, eg in ipairs(E.eggs) do total += (h.eggs and h.eggs[eg.id]) or 0 end
		local inv = panel(list, string.format("YOUR EGGS  ·  %d", total))
		local eggGrid = clearFrame(inv)
		eggGrid.Size = UDim2.new(1, 0, 0, 0); eggGrid.AutomaticSize = Enum.AutomaticSize.Y; eggGrid.LayoutOrder = nextOrder()
		local gl = Instance.new("UIGridLayout", eggGrid)
		gl.CellSize = UDim2.fromOffset(182, 190); gl.CellPadding = UDim2.fromOffset(8, 8); gl.SortOrder = Enum.SortOrder.LayoutOrder
		local firstEmpty
		for i = 1, (h.count or E.nests) do if not (h.nests and h.nests[tostring(i)]) then firstEmpty = i; break end end
		for i, eg in ipairs(E.eggs) do
			local n = (h.eggs and h.eggs[eg.id]) or 0
			local foot = n > 0 and (firstEmpty and "SET IN A NEST  ›" or "NESTS FULL") or "NONE YET"
			local card = eggCard(eggGrid, eg, n, 182, 190, foot, n > 0 and (firstEmpty and COL.GOOD or COL.DIM) or COL.DIM)
			card.LayoutOrder = (n > 0 and 0 or 10) + i
			card.Activated:Connect(function()
				if n <= 0 then toast("Buy one on the shelf below, or earn it from gifts, login days and the pass", COL.BAD); return end
				if not firstEmpty then toast("Every nest is taken: hatch one first", COL.BAD); return end
				place(eg.id, firstEmpty)
			end)
		end
		if total == 0 then dim(inv, "None waiting. Buy one below, or earn them: playtime gifts, login days, the season pass.", 13) end
		local shelf = panel(list, "THE SHELF")
		local P = state.profile or {}
		local V = E.variants or {}
		dim(shelf, string.format("Every hatch also rolls a finish: Golden %s · Spectral %s (otherwise ordinary).", HX.pct(V.Golden or 0), HX.pct(V.Spectral or 0)), 12)
		if P.restricted then dim(shelf, "In your region eggs aren't sold: they come as gifts (playtime, login days, the pass, events).", 12) end
		do   -- what's coming: the next drop that brings an egg
			local nd, nt = HX.Drops.nextWith("egg")
			local ne = nd and Catalog.EGG[nd.egg]
			if ne and nt then
				local up = title(shelf, string.format("NEW EGG IN %s  ·  %s", HX.span(nt - HX.Drops.now()), string.upper(ne.name)), 13, COL.ACCENT)
				up.Size = UDim2.new(1, 0, 0, 18); up.LayoutOrder = nextOrder()
			end
		end
		for _, eg in ipairs(E.eggs) do
			local live, leaves = HX.Drops.eggLive(eg.id)
			if not (live and Catalog.released(eg)) then continue end
			local c = frame(shelf, COL.GLASS2, 12); c.BackgroundTransparency = 0.1; c.Size = UDim2.new(1, 0, 0, 96); c.LayoutOrder = nextOrder()
			border(c, RARITY_COL[eg.rarity] or WHITE, 1.5, 0.5)
			local th = Preview.egg(c, eg.id, UDim2.fromOffset(84, 84), nil, true); th.Position = UDim2.fromOffset(6, 6); th.BackgroundTransparency = 1
			local nm = title(c, eg.name, 17, RARITY_COL[eg.rarity]); nm.Position = UDim2.fromOffset(98, 8); nm.Size = UDim2.new(1, -230, 0, 20); nm.TextTruncate = Enum.TextTruncate.AtEnd
			local mins = eg.minutes >= 60 and (math.floor(eg.minutes / 60 * 10) / 10 .. " h") or (eg.minutes .. " min")
			local odds = {}
			for _, r in ipairs(Catalog.RARITIES) do if eg.odds[r] then table.insert(odds, eg.odds[r] .. "% " .. r) end end
			local d1 = label(c, "hatches in " .. mins .. "  ·  " .. table.concat(odds, " · ") .. (leaves and ("  ·  LEAVES IN " .. HX.span(leaves - HX.Drops.now())) or ""), 11, FONT_BODY, leaves and COL.ACCENT or COL.DIM)
			d1.Position = UDim2.fromOffset(98, 30); d1.Size = UDim2.new(1, -258, 0, 56); d1.TextYAlignment = Enum.TextYAlignment.Top
			-- WHAT'S INSIDE: everyone it can hatch, each one's own chance, which you have
			local peek = button(c, "WHAT'S INSIDE", 11, COL.GLASS)
			peek.AnchorPoint = Vector2.new(1, 1); peek.Position = UDim2.new(1, -136, 1, -8); peek.Size = UDim2.fromOffset(112, 26)
			peek.Activated:Connect(function()
				local pool = Catalog.eggPool(eg.id)
				local per = {}
				for _, comp in ipairs(pool) do per[comp.rarity] = (per[comp.rarity] or 0) + 1 end
				table.sort(pool, function(a, b)
					if (RARITY_ORDER[a.rarity] or 0) ~= (RARITY_ORDER[b.rarity] or 0) then return (RARITY_ORDER[a.rarity] or 0) > (RARITY_ORDER[b.rarity] or 0) end
					return a.name < b.name
				end)
				local mineP = state.profile or {}
				modal(string.upper(eg.name) .. "  ·  WHAT'S INSIDE", string.format("%d companions. Every hatch also rolls a finish: Golden %s · Spectral %s.", #pool, HX.pct(V.Golden or 0), HX.pct(V.Spectral or 0)), nil, function(box)
					local g = Instance.new("Frame"); g.BackgroundTransparency = 1; g.Size = UDim2.new(1, 0, 0, 0); g.AutomaticSize = Enum.AutomaticSize.Y; g.LayoutOrder = 5; g.Parent = box
					local gl = Instance.new("UIGridLayout", g); gl.CellSize = UDim2.fromOffset(128, 158); gl.CellPadding = UDim2.fromOffset(8, 8); gl.SortOrder = Enum.SortOrder.LayoutOrder
					for k, comp in ipairs(pool) do
						local cell = frame(g, COL.GLASS2, 10); cell.LayoutOrder = k
						border(cell, RARITY_COL[comp.rarity] or COL.DIM, 2, 0.3)
						local have = (mineP.owned and mineP.owned.companions and mineP.owned.companions[comp.id]) or (mineP.copies and mineP.copies["pet:" .. comp.id])
						local pv = Preview.companion(cell, comp.id, UDim2.new(1, -8, 0, 96), true); pv.Position = UDim2.fromOffset(4, 4); pv.BackgroundTransparency = 1
						local nmL = title(cell, comp.name, 12, RARITY_COL[comp.rarity]); nmL.Position = UDim2.fromOffset(6, 102); nmL.Size = UDim2.new(1, -12, 0, 16); nmL.TextTruncate = Enum.TextTruncate.AtEnd
						local chance = (eg.odds[comp.rarity] or 0) / math.max(per[comp.rarity] or 1, 1)
						local ch = title(cell, HX.pct(chance) .. (have and "  ·  OWNED" or ""), 11, have and COL.GOOD or COL.DIM); ch.Position = UDim2.fromOffset(6, 120); ch.Size = UDim2.new(1, -12, 0, 14)
						local rl = title(cell, string.upper(comp.rarity), 10, RARITY_COL[comp.rarity]); rl.Position = UDim2.fromOffset(6, 136); rl.Size = UDim2.new(1, -12, 0, 14)
					end
				end, 600)
			end)
			local price = eg.marks and (fmt(eg.marks) .. " MARKS") or (eg.crowns and (fmt(eg.crowns) .. " CROWNS"))
			if price and not P.restricted then
				local b = button(c, "BUY  ·  " .. price, 13, eg.crowns and COL.GOLD or COL.GREEN)
				b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, -8, 0.5, 0); b.Size = UDim2.fromOffset(120, 44)
				b.Activated:Connect(function()
					local r = call("EggBuy", eg.id); apply(r)
					toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
					render.HATCHERY()
				end)
			else
				local t = label(c, "gifts, login days and the pass", 11, FONT, COL.ACCENT)
				t.AnchorPoint = Vector2.new(1, 0.5); t.Position = UDim2.new(1, -8, 0.5, 0); t.Size = UDim2.fromOffset(120, 44); t.TextXAlignment = Enum.TextXAlignment.Center
			end
		end
	end

	local function companions()
		local p = state.profile or {}
		local owned = {}
		for id, v in pairs((p.owned and p.owned.companions) or {}) do owned[id] = v end
		for key in pairs(p.copies or {}) do if key:sub(1, 4) == "pet:" then owned[key:sub(5)] = true end end   -- (hatched ones are copies)
		local stars = p.stars or {}
		local out = p.companion or ""
		local list = {}
		for _, c in ipairs(Catalog.COMPANIONS) do if Catalog.released(c) or owned[c.id] or (p.copies and p.copies["pet:" .. c.id]) then table.insert(list, c) end end
		table.sort(list, function(a, b)
			local ha, hb = owned[a.id] == true, owned[b.id] == true
			if ha ~= hb then return ha end
			if (RARITY_ORDER[a.rarity] or 0) ~= (RARITY_ORDER[b.rarity] or 0) then return (RARITY_ORDER[a.rarity] or 0) > (RARITY_ORDER[b.rarity] or 0) end
			return a.name < b.name
		end)
		if not Catalog.COMPANION[ui.compSel or ""] then ui.compSel = (out ~= "" and out) or list[1].id end
		local sel = Catalog.COMPANION[ui.compSel]
		local have = owned[sel.id] == true
		-- left: everyone there is to find
		local left = clearFrame(body); left.Size = UDim2.new(1, -520, 1, 0)
		local sf = Instance.new("ScrollingFrame")
		sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0; sf.Size = UDim2.fromScale(1, 1)
		sf.CanvasSize = UDim2.new(); sf.AutomaticCanvasSize = Enum.AutomaticSize.Y; sf.ScrollBarThickness = 5; sf.ScrollBarImageColor3 = COL.DIM
		sf.Parent = left
		local grid = Instance.new("UIGridLayout", sf)
		grid.CellSize = UDim2.fromOffset(150, 176); grid.CellPadding = UDim2.fromOffset(10, 10); grid.SortOrder = Enum.SortOrder.LayoutOrder
		local found = 0
		for i, c in ipairs(list) do
			local mine = owned[c.id] == true
			if mine then found += 1 end
			local on = c.id == sel.id
			local cb = button(sf, "", 12, on and COL.BLUE or COL.GLASS2)
			cb.AutoButtonColor = false; cb.LayoutOrder = i
			border(cb, RARITY_COL[c.rarity] or COL.DIM, on and 3 or 2, on and 0 or (mine and 0.3 or 0.7))
			local th = Preview.companion(cb, c.id, UDim2.new(1, -12, 0, 116), true, stars[c.id], not mine); th.Position = UDim2.fromOffset(6, 6); th.BackgroundTransparency = 1
			local nm = title(cb, mine and c.name or "???", 13); nm.Position = UDim2.fromOffset(6, 124); nm.Size = UDim2.new(1, -12, 0, 16); nm.TextXAlignment = Enum.TextXAlignment.Center; nm.TextTruncate = Enum.TextTruncate.AtEnd
			local st = mine and (string.rep("★", stars[c.id] or 1) .. string.rep("☆", (E.stars or 5) - (stars[c.id] or 1))) or string.upper(c.rarity)
			local sl = title(cb, st, 12, mine and COL.GOLD or (RARITY_COL[c.rarity] or COL.DIM)); sl.Position = UDim2.fromOffset(6, 144); sl.Size = UDim2.new(1, -12, 0, 16); sl.TextXAlignment = Enum.TextXAlignment.Center
			if out == c.id then local o = label(cb, "OUT", 11, FONT_BLACK, COL.GOOD); o.Position = UDim2.fromOffset(10, 8); o.Size = UDim2.fromOffset(40, 14) end
			cb.Activated:Connect(function() ui.compSel = c.id; render.HATCHERY() end)
		end
		-- right: the chosen one on a stage
		local right = clearFrame(body); right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0, 506, 1, 0)
		local stage = Preview.companion(right, sel.id, UDim2.new(1, 0, 0, 320), false, stars[sel.id], not have)
		local nm = title(stage, have and sel.name or "???", 30); nm.Position = UDim2.fromOffset(16, 10); nm.Size = UDim2.new(1, -32, 0, 34)
		local tag = rarityTag(stage, sel.rarity); tag.AnchorPoint = Vector2.new(1, 0); tag.Position = UDim2.new(1, -14, 0, 14)
		local cnt = title(stage, string.format("FOUND %d / %d", found, #list), 13, COL.DIM); cnt.AnchorPoint = Vector2.new(0, 1); cnt.Position = UDim2.new(0, 16, 1, -10); cnt.Size = UDim2.fromOffset(200, 16)
		local info = clearFrame(right); info.Position = UDim2.fromOffset(0, 332); info.Size = UDim2.new(1, 0, 1, -332)
		local il = scroll(info, 8)
		local pnl = panel(il, nil)
		dim(pnl, have and (sel.description or "") or "Not found yet.", 14)
		local src = title(pnl, string.upper(Catalog.companionSource(sel)), 13, COL.ACCENT); src.Size = UDim2.new(1, 0, 0, 18); src.LayoutOrder = nextOrder()
		if have then
			local s2 = stars[sel.id] or 1
			local starT = title(pnl, string.rep("★", s2) .. string.rep("☆", (E.stars or 5) - s2) .. "   duplicates add a star; five stars sparkle", 13, COL.GOLD)
			starT.Size = UDim2.new(1, 0, 0, 18); starT.LayoutOrder = nextOrder()
			local acts = panel(il, nil, true)
			if out == sel.id then
				local hb, b = fatButton(acts, "SEND IT HOME", COL.GLASS2, 20); hb.Size = UDim2.new(1, 0, 0, 56); hb.LayoutOrder = nextOrder()
				b.Activated:Connect(function() local r = call("Companion", ""); apply(r); toast(r.msg or "", r.ok and COL.GOOD or COL.BAD); render.HATCHERY() end)
			else
				local hb, b = fatButton(acts, "TAKE IT ALONG", COL.GREEN, 20); hb.Size = UDim2.new(1, 0, 0, 56); hb.LayoutOrder = nextOrder()
				b.Activated:Connect(function() local r = call("Companion", sel.id); apply(r); toast(r.msg or "", r.ok and COL.GOOD or COL.BAD); render.HATCHERY() end)
			end
			dim(acts, "It follows you around the Courtyard and your matches. SETTINGS › Companions hides other people's.", 12)
		else
			local acts = panel(il, nil, true)
			local hb, b = fatButton(acts, "HATCH EGGS TO FIND IT", COL.BLUE, 18); hb.Size = UDim2.new(1, 0, 0, 52); hb.LayoutOrder = nextOrder()
			b.Activated:Connect(function() ui.hatchTab = "nests"; render.HATCHERY() end)
		end
	end

	local function renderTabs()
		clear(tabs)
		for i, t in ipairs(TABS) do
			local on = ui.hatchTab == t[1]
			local h2, b = fatButton(tabs, t[2], on and COL.BLUE or COL.GLASS2, 20)
			h2.Size = UDim2.fromOffset(210, 46); h2.LayoutOrder = i
			if not on then b.TextColor3 = COL.DIM end
			b.Activated:Connect(function() ui.hatchTab = t[1]; render.HATCHERY() end)
		end
	end

	render.HATCHERY = function()
		local r = call("Hatchery")
		if r.ok then state.hatchery = r.hatchery; state.gifts = r.gifts end
		renderTabs()
		clear(body)
		if ui.hatchTab == "companions" then companions() else nests() end
		renderSide()
	end
end

--------------------------------------------------------------------
--  LOGIN REWARDS — the pop-up on the first open of the day
--------------------------------------------------------------------
local loginShownDay = nil
local function loginPopup()
	local L = state.login
	local days = Catalog.LOGIN and Catalog.LOGIN.days or {}
	if not L or #days == 0 then return end
	modal("DAILY LOGIN REWARDS", L.claimed and "Today's gift is yours. Come back tomorrow: the streak goes on." or "A gift for every day you come back. Miss a day and the streak starts again at day 1.",
		(not L.claimed) and {{"CLAIM DAY " .. tostring(L.day), COL.GREEN, function()
			local r = call("LoginClaim")
			toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
			if r.login then state.login = r.login end
			if r.profile then state.profile = r.profile; refreshWallet() end
			closeModal()
			if r.crate and r.crate.skinId then
				local won = Catalog.SKIN[r.crate.skinId]
				modal(string.upper(r.crate.rarity) .. "!  " .. r.crate.name, r.crate.dup and string.format("Duplicate — %s Marks back.", fmt(r.crate.refund)) or "Your free crate open.", nil, function(box)
					local th = weaponStage(box, won and won.weapon or r.crate.weapon, r.crate.skinId, UDim2.new(1, 0, 0, 220)); th.LayoutOrder = 5
				end, 520)
			end
			renderSide()
		end}} or nil, function(box)
			local row7 = clearFrame(box); row7.Size = UDim2.new(1, 0, 0, 178); row7.LayoutOrder = 5
			local l = hlist(row7, 8); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
			for i, r in ipairs(days) do
				local past = i < L.day or (i == L.day and L.claimed)
				local today = i == L.day and not L.claimed
				local c = frame(row7, today and Color3.fromRGB(28, 70, 40) or COL.GLASS2, 12)
				c.Size = UDim2.fromOffset(98, 172); c.LayoutOrder = i
				c.BackgroundTransparency = past and 0.45 or 0.05
				border(c, today and COL.GREEN or (i == #days and COL.GOLD or WHITE), today and 3 or 2, today and 0 or (i == #days and 0.2 or 0.8))
				local d = title(c, "DAY " .. i, 15, today and COL.GOOD or COL.TEXT); d.Position = UDim2.fromOffset(0, 6); d.Size = UDim2.new(1, 0, 0, 18); d.TextXAlignment = Enum.TextXAlignment.Center
				local holder = clearFrame(c); holder.Position = UDim2.fromOffset(4, 26); holder.Size = UDim2.new(1, -8, 0, 92)
				local text, col, sub = rewardVisual(holder, r, 84)
				local t = title(c, text or "", 14, col or COL.TEXT); t.Position = UDim2.fromOffset(4, 120); t.Size = UDim2.new(1, -8, 0, 18); t.TextXAlignment = Enum.TextXAlignment.Center; t.TextTruncate = Enum.TextTruncate.AtEnd
				local s2 = title(c, sub or "", 10, COL.DIM); s2.Position = UDim2.fromOffset(4, 138); s2.Size = UDim2.new(1, -8, 0, 14); s2.TextXAlignment = Enum.TextXAlignment.Center; s2.TextTruncate = Enum.TextTruncate.AtEnd
				if past then local ck = title(c, "✔", 30, COL.GOOD); ck.Position = UDim2.fromOffset(0, 40); ck.Size = UDim2.new(1, 0, 0, 40); ck.TextXAlignment = Enum.TextXAlignment.Center end
			end
			local streak = title(box, string.format("STREAK: %d DAY%s", L.streak or 1, (L.streak or 1) == 1 and "" or "S"), 14, COL.ACCENT)
			streak.Size = UDim2.new(1, 0, 0, 18); streak.LayoutOrder = 6; streak.TextXAlignment = Enum.TextXAlignment.Center
		end, 780)
end

--------------------------------------------------------------------
--  SERVERS (browser + custom)
--------------------------------------------------------------------
do
	local f = tabFrame.SERVERS
	local listHolder = frame(f, COL.GLASS, 14); listHolder.BackgroundTransparency = 0.12; listHolder.Size = UDim2.new(1, 0, 1, -72); padding(listHolder, 14, 14, 12, 12)
	local foot = clearFrame(f); foot.AnchorPoint = Vector2.new(0, 1); foot.Position = UDim2.new(0, 0, 1, 0); foot.Size = UDim2.new(1, 0, 0, 60)
	screenFoot.SERVERS = foot
	local list = scroll(listHolder, 6)
	local customHolder = frame(f, COL.GLASS, 14); customHolder.BackgroundTransparency = 0.08; customHolder.AnchorPoint = Vector2.new(1, 0); customHolder.Position = UDim2.new(1, 0, 0, 0); customHolder.Size = UDim2.new(0, 360, 1, -72); customHolder.Visible = false
	padding(customHolder, 12, 12, 10, 10)
	local customList = scroll(customHolder, 6)
	local COLS = {{"SERVER", 0.34}, {"MODE", 0.2}, {"MAP", 0.14}, {"PLAYERS", 0.14}, {"", 0.18}}

	local function joinServer(s)
		local r = call("Join", s.jobId)
		toast(r.msg or (r.ok and "joining…" or "could not join"), r.ok and COL.GOOD or COL.BAD)
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
		local head = frame(list, COL.PANEL); head.BackgroundTransparency = 1; head.Size = UDim2.new(1, 0, 0, 18); head.LayoutOrder = nextOrder()
		local x = 0
		for _, c in ipairs(COLS) do local t = label(head, c[1], 11, FONT, COL.DIM); t.Position = UDim2.new(x, 8, 0, 0); t.Size = UDim2.new(c[2], -8, 1, 0); x += c[2] end
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
				local r = frame(list, s.here and COL.BLUE or COL.GLASS2, 8)
				r.Size = UDim2.new(1, 0, 0, 44); r.LayoutOrder = nextOrder(); r.BackgroundTransparency = s.here and 0.3 or 0.1
				if s.cheats then r.BackgroundTransparency = 0.4 end
				local name = (s.custom and s.name ~= "" and ("🏴 " .. s.name)) or (door .. "  #" .. string.sub(tostring(s.jobId or "?"), 1, 6))
				if s.pending then name = name .. "  (starting)" end
				if s.cheats then name = name .. "  ·  cheats, no rewards" elseif s.custom then name = name .. "  ·  custom" end
				local cells = {name .. (s.here and "   (here)" or ""), s.modeName ~= "" and s.modeName or s.mode, s.map, string.format("%d / %d", s.players or 0, s.max or 0)}
				x = 0
				for ci, c in ipairs(COLS) do
					if ci <= 4 then
						local t = label(r, cells[ci], 13, ci == 1 and FONT or FONT_BODY, ci == 4 and ((s.players or 0) >= (s.max or 1) and COL.BAD or COL.TEXT) or COL.TEXT)
						t.Position = UDim2.new(x, 8, 0, 0); t.Size = UDim2.new(c[2], -8, 1, 0); t.TextWrapped = false; t.TextTruncate = Enum.TextTruncate.AtEnd
					end
					x += c[2]
				end
				local b = button(r, s.here and "HERE" or (s.access == "Friends" and "FRIENDS ONLY" or (s.state == "Intermission" and "JOIN  (between rounds)" or "JOIN")), 13, s.here and COL.GLASS2 or COL.GREEN)
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
		local t = title(customList, "CREATE CUSTOM SERVER", 18, COL.ACCENT); t.Size = UDim2.new(1, 0, 0, 24); t.LayoutOrder = nextOrder()
		local box = Instance.new("TextBox")
		box.PlaceholderText = player.DisplayName .. "'s server"; box.Text = c.name or ""; box.ClearTextOnFocus = false
		box.Font = FONT_BODY; box.TextSize = 13; box.TextColor3 = COL.TEXT; box.PlaceholderColor3 = COL.DIM
		box.BackgroundColor3 = COL.PANEL; box.BorderSizePixel = 0; box.Size = UDim2.new(1, 0, 0, 30); box.LayoutOrder = nextOrder(); box.TextXAlignment = Enum.TextXAlignment.Left
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
			local r = frame(customList, COL.PANEL, 6); r.Size = UDim2.new(1, 0, 0, 30); r.LayoutOrder = nextOrder()
			padding(r, 10, 4, 0, 0)
			local l = label(r, labelText, 12, FONT_BODY, COL.DIM); l.Size = UDim2.new(0.45, 0, 1, 0)
			local v = label(r, value, 12, FONT, COL.TEXT); v.Position = UDim2.new(0.45, 0, 0, 0); v.Size = UDim2.new(0.55, -60, 1, 0); v.TextXAlignment = Enum.TextXAlignment.Right; v.TextWrapped = false; v.TextTruncate = Enum.TextTruncate.AtEnd
			local lb = button(r, "‹", 11, COL.CARD); lb.AnchorPoint = Vector2.new(1, 0.5); lb.Position = UDim2.new(1, -30, 0.5, 0); lb.Size = UDim2.fromOffset(26, 24); lb.Activated:Connect(function() onLeft(); renderCustom() end)
			local rb = button(r, "›", 11, COL.CARD); rb.AnchorPoint = Vector2.new(1, 0.5); rb.Position = UDim2.new(1, 0, 0.5, 0); rb.Size = UDim2.fromOffset(26, 24); rb.Activated:Connect(function() onRight(); renderCustom() end)
		end
		local function tog(labelText, k, hintText)
			local r = frame(customList, COL.PANEL, 6); r.Size = UDim2.new(1, 0, 0, 30); r.LayoutOrder = nextOrder()
			padding(r, 10, 4, 0, 0)
			local l = label(r, labelText, 12, FONT_BODY, COL.DIM); l.Size = UDim2.new(0.7, 0, 1, 0)
			local b = button(r, c[k] and "ON" or "OFF", 11, c[k] and COL.GOOD or COL.CARD); b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, 0, 0.5, 0); b.Size = UDim2.fromOffset(56, 24)
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
		tog("Bots fill empty places", "bots")
		if c.bots then
			local counts = {2, 4, 6, 8, 10, 12, 16, 20, 24}
			sel("Fighters in all (players + bots)", tostring(c.botCount or 8), function() c.botCount = cycle(counts, c.botCount or 8, -1) end, function() c.botCount = cycle(counts, c.botCount or 8, 1) end)
			sel("Bot skill", c.botSkill or "Mixed", function() c.botSkill = cycle(GameConfig.BOT_SKILLS, c.botSkill or "Mixed", -1) end, function() c.botSkill = cycle(GameConfig.BOT_SKILLS, c.botSkill or "Mixed", 1) end)
		end
		tog("Cheats / host commands", "cheats")
		dim(customList, c.cheats and "Marked as a cheat server: /god /heal /speed /tp /bring /give /kick for the host. No Marks, XP or rating for anyone in it."
			or "Cheats give the host /god /heal /speed /tp /bring /give /kick. The server is marked and pays no Marks, XP or rating.")
		bigBtn(customList, "RESERVE & TRAVEL", COL.GOLD, function()
			c.name = box.Text
			local r = call("Custom", c)
			toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
		end)
		dim(customList, "You and your party travel there together (everyone ready first).")
	end

	render.SERVERS = function()
		loadServers(true)
		customHolder.Visible = ui.customOpen
		listHolder.Size = ui.customOpen and UDim2.new(1, -372, 1, -72) or UDim2.new(1, 0, 1, -72)
		renderList()
		if ui.customOpen then renderCustom() end
		renderSide()
	end
	task.spawn(function()
		while true do
			task.wait(10)
			if open and currentTab == "SERVERS" then render.SERVERS() end
		end
	end)
end

--------------------------------------------------------------------
--  LEADERBOARDS (RANKS) + PLAYER PROFILES (PROFILE)
--  (built in a function on HX: the main chunk is at Luau's local limit)
--------------------------------------------------------------------
HX.screens = function()
	local MEDAL = {Color3.fromRGB(255, 196, 40), Color3.fromRGB(200, 210, 224), Color3.fromRGB(214, 140, 80)}
	local REWARDS = ECON.seasonRewards or {}

	-- a reward line in words: "the title Warlord · 500 Crowns · 20,000 Marks"
	local function rewardText(r)
		local bits = {}
		if r.title then table.insert(bits, "the title “" .. r.title .. "”") end
		if r.crowns then table.insert(bits, fmt(r.crowns) .. " Crowns") end
		if r.marks then table.insert(bits, fmt(r.marks) .. " Marks") end
		if r.keys then table.insert(bits, r.keys .. (r.keys == 1 and " Key" or " Keys")) end
		return table.concat(bits, "  ·  ")
	end
	local function seasonLeft()
		local y, m, d = tostring(Catalog.PASS.ends or ""):match("^(%d+)-(%d+)-(%d+)$")
		if not y then return "" end
		local t = DateTime.fromUniversalTime(tonumber(y), tonumber(m), tonumber(d)).UnixTimestamp - os.time()
		return t > 0 and HX.span(t) or "ended"
	end

	-- every way into a profile ends here
	HX.openProfile = function(userId)
		ui.profileId = tonumber(userId)
		if not open then show("PROFILE") else selectTab("PROFILE") end
	end

	------------------------------------------------------------------
	--  LEADERBOARDS
	------------------------------------------------------------------
	do
		local f = tabFrame.RANKS
		local left = frame(f, COL.GLASS, 14); left.BackgroundTransparency = 0.12; left.Size = UDim2.new(0.6, -8, 1, 0); padding(left, 14, 14, 12, 12)
		local right = frame(f, COL.GLASS, 14); right.BackgroundTransparency = 0.12
		right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0.4, -8, 1, 0); padding(right, 14, 14, 12, 12)
		local leftList, rightList = scroll(left, 6), scroll(right, 8)
		local cache = {}
		local function fetch(which)
			local c = cache[which]
			if c and os.clock() - c.at < 60 then return c.r end
			local r = call("Board", which)
			if r.ok then cache[which] = {at = os.clock(), r = r} end
			return r
		end
		local function valueText(which, v)
			v = v or 0
			if which == "Warfront" then return fmt(v) .. (v == 1 and " kill" or " kills") end
			return fmt(v) .. "  ·  " .. string.upper((rankOf(v)))
		end
		ui.rankBoard = ui.rankBoard or "Warfront"
		ui.rankSearch = ui.rankSearch or ""

		render.RANKS = function()
			clear(leftList); clear(rightList)
			local which = ui.rankBoard
			local tabs = {{text = "Warfront"}}
			for _, b in ipairs(GameConfig.DOORS.Lists.brackets or {"1v1", "2v2", "3v3"}) do table.insert(tabs, {text = b}) end
			chips(leftList, tabs, function(it) return it.text == which end, function(it) ui.rankBoard = it.text; render.RANKS() end, 32)
			local r = fetch(which)
			local me = r.me or {}

			-- where you stand
			local you = frame(leftList, COL.BLUE, 10); you.Size = UDim2.new(1, 0, 0, 54); you.LayoutOrder = nextOrder(); padding(you, 16, 16, 0, 0)
			local yt = title(you, me.place and ("YOU ARE  #" .. me.place) or "YOU  ·  NOT IN THE TOP 100 YET", 20); yt.Size = UDim2.new(0.58, 0, 1, 0); yt.TextTruncate = Enum.TextTruncate.AtEnd
			local yv = title(you, valueText(which, me.value), 16); yv.AnchorPoint = Vector2.new(1, 0); yv.Position = UDim2.new(1, 0, 0, 0)
			yv.Size = UDim2.new(0.42, 0, 1, 0); yv.TextXAlignment = Enum.TextXAlignment.Right
			if which ~= "Warfront" and (me.placements or 0) < (ECON.placementMatches or 10) then
				dim(leftList, string.format("Placements: %d of %d ranked matches played. You show on the board once they're done.", me.placements or 0, ECON.placementMatches or 10), 12)
			end

			-- search
			local box = Instance.new("TextBox")
			box.PlaceholderText = "Search the top 100 by name…"; box.Text = ui.rankSearch; box.ClearTextOnFocus = false
			box.Font = FONT_BODY; box.TextSize = 14; box.TextColor3 = COL.TEXT; box.PlaceholderColor3 = COL.DIM
			box.BackgroundColor3 = COL.PANEL; box.BorderSizePixel = 0; box.Size = UDim2.new(1, 0, 0, 34); box.LayoutOrder = nextOrder()
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.Parent = leftList
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
			padding(box, 12, 12, 0, 0)

			-- the rows (redrawn as you type)
			local holder = clearFrame(leftList); holder.AutomaticSize = Enum.AutomaticSize.Y; holder.Size = UDim2.new(1, 0, 0, 0); holder.LayoutOrder = nextOrder()
			vlist(holder, 4)
			local function drawRows()
				clear(holder)
				local q = string.lower(ui.rankSearch or "")
				local shown = 0
				for _, rw in ipairs(r.rows or {}) do
					if q == "" or string.find(string.lower(tostring(rw.name)), q, 1, true) then
						shown += 1
						local mine = rw.id == player.UserId
						local b = row(holder, string.format("#%d      %s%s", rw.rank, tostring(rw.name), mine and "  (you)" or ""), valueText(which, rw.value), mine,
							function() HX.openProfile(rw.id) end, COL.TEXT)
						if MEDAL[rw.rank] then
							local m = frame(b, MEDAL[rw.rank], 4); m.Size = UDim2.fromOffset(6, 22); m.Position = UDim2.new(0, -8, 0.5, -11)
						end
					end
				end
				if shown == 0 then
					dim(holder, #(r.rows or {}) == 0 and "Nobody on this board yet this season. Be the first." or "Nobody in the top 100 by that name.", 13)
				end
			end
			drawRows()
			box:GetPropertyChangedSignal("Text"):Connect(function() ui.rankSearch = box.Text; drawRows() end)
			dim(leftList, "Click anyone to see their profile.", 12)

			-- the season and its rewards
			local P = Catalog.PASS
			local h = title(rightList, string.upper(P.name or "THE SEASON"), 18, COL.ACCENT); h.Size = UDim2.new(1, 0, 0, 24); h.LayoutOrder = nextOrder(); h.TextTruncate = Enum.TextTruncate.AtEnd
			dim(rightList, string.format("Ends %s  ·  %s left. When it ends, everyone on a line below is paid the best line they reached on each board.", tostring(P.ends), seasonLeft()), 13)
			heading(rightList, which == "Warfront" and "Warfront  ·  most kills this season" or (which .. " Lists  ·  highest rating"))
			local lines = which == "Warfront" and REWARDS.Warfront or REWARDS.Lists
			local prevTop = 0
			for _, line in ipairs(lines or {}) do
				local reached = me.place ~= nil and me.place <= line.top and me.place > prevTop
				local c = frame(rightList, reached and COL.BLUE or COL.GLASS2, 10); c.LayoutOrder = nextOrder(); c.BackgroundTransparency = reached and 0 or 0.1
				c.AutomaticSize = Enum.AutomaticSize.Y; c.Size = UDim2.new(1, 0, 0, 0); padding(c, 12, 12, 8, 8); vlist(c, 2)
				local t = title(c, line.top == 1 and "#1" or ("TOP " .. fmt(line.top)), 16, line.top <= 3 and MEDAL[1] or COL.TEXT); t.Size = UDim2.new(1, 0, 0, 20)
				local d = label(c, rewardText(line.reward), 13, FONT_BODY, COL.TEXT); d.AutomaticSize = Enum.AutomaticSize.Y; d.Size = UDim2.new(1, 0, 0, 0)
				if reached then local y = label(c, "YOU'RE HERE NOW", 11, FONT, COL.ACCENT); y.Size = UDim2.new(1, 0, 0, 14) end
				prevTop = line.top
			end
			if REWARDS.tiers then
				heading(rightList, "Ranked  ·  the tier you finish in")
				for _, tier in ipairs(ECON.rankTiers or {}) do
					local rw = REWARDS.tiers[tier]
					if rw then
						local c = frame(rightList, COL.GLASS2, 10); c.LayoutOrder = nextOrder(); c.BackgroundTransparency = 0.1
						c.AutomaticSize = Enum.AutomaticSize.Y; c.Size = UDim2.new(1, 0, 0, 0); padding(c, 12, 12, 8, 8); vlist(c, 2)
						local t = title(c, string.upper(tier), 15, COL.PURPLE); t.Size = UDim2.new(1, 0, 0, 20)
						local d = label(c, rewardText(rw), 13, FONT_BODY, COL.TEXT); d.AutomaticSize = Enum.AutomaticSize.Y; d.Size = UDim2.new(1, 0, 0, 0)
					end
				end
				dim(rightList, "Your best bracket counts, once your placements are done.", 12)
			end
		end
	end

	------------------------------------------------------------------
	--  PROFILE
	------------------------------------------------------------------
	do
		local f = tabFrame.PROFILE
		local list = scroll(f, 10)
		local function tile(parent, big, small, color)
			local t = frame(parent, COL.GLASS2, 10); t.BackgroundTransparency = 0.1
			local v = title(t, big, 26, color or COL.TEXT); v.Position = UDim2.fromOffset(12, 8); v.Size = UDim2.new(1, -24, 0, 30); v.TextTruncate = Enum.TextTruncate.AtEnd
			local l = label(t, small, 12, FONT, COL.DIM); l.Position = UDim2.fromOffset(12, 40); l.Size = UDim2.new(1, -24, 0, 16)
			return t
		end
		local function grid(parent, cellW, cellH)
			local g = clearFrame(parent); g.AutomaticSize = Enum.AutomaticSize.Y; g.Size = UDim2.new(1, 0, 0, 0); g.LayoutOrder = nextOrder()
			local gl = Instance.new("UIGridLayout", g); gl.CellSize = UDim2.fromOffset(cellW, cellH); gl.CellPadding = UDim2.fromOffset(8, 8); gl.SortOrder = Enum.SortOrder.LayoutOrder
			return g
		end

		render.PROFILE = function()
			clear(list)
			local id = ui.profileId or player.UserId
			local d = call("PlayerProfile", id)
			if not d.ok then dim(list, d.msg or "That profile couldn't be loaded.", 15); return end
			local mine = id == player.UserId

			-- WHO
			local head = panel(list, nil)
			local top = clearFrame(head); top.Size = UDim2.new(1, 0, 0, 108); top.LayoutOrder = nextOrder()
			local img = Instance.new("ImageLabel")
			img.BackgroundColor3 = COL.GLASS2; img.Size = UDim2.fromOffset(104, 104); img.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", id)
			img.Parent = top
			Instance.new("UICorner", img).CornerRadius = UDim.new(0, 14)
			local nm = title(top, d.display or "?", 34); nm.Position = UDim2.fromOffset(120, 2); nm.Size = UDim2.new(1, -120, 0, 40); nm.TextTruncate = Enum.TextTruncate.AtEnd
			local sub = label(top, string.format("@%s   ·   LEVEL %d%s", tostring(d.name), d.level or 1, (d.title and d.title ~= "") and ("   ·   " .. d.title) or ""), 15, FONT, COL.DIM)
			sub.Position = UDim2.fromOffset(120, 44); sub.Size = UDim2.new(1, -120, 0, 20); sub.TextWrapped = false; sub.TextTruncate = Enum.TextTruncate.AtEnd
			local st = label(top, mine and "THIS IS YOU" or (d.here and "●  IN THIS SERVER" or "○  NOT IN THIS SERVER"), 13, FONT, d.here and COL.GOOD or COL.DIM)
			st.Position = UDim2.fromOffset(120, 70); st.Size = UDim2.new(1, -120, 0, 18)

			-- WHAT YOU CAN DO WITH THEM
			if not mine then
				local acts = clearFrame(head); acts.Size = UDim2.new(1, 0, 0, 44); acts.LayoutOrder = nextOrder()
				hlist(acts, 8)
				local function act(text, color, fn)
					local b = button(acts, text, 15, color); b.Size = UDim2.fromOffset(190, 42); b.LayoutOrder = nextOrder()
					b.Activated:Connect(fn)
					return b
				end
				if d.here then
					act("TRADE", COL.GOLD, function()
						local r = call("TradeRequest", id); toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
					end)
				end
				if not d.party then
					act("INVITE TO PARTY", COL.GREEN, function()
						local r = call("PartyInvite", id, d.display); toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
						if r.party then state.party = r.party end
					end)
				end
				local fb = act("ADD FRIEND", COL.BLUE, function()
					local target = Players:GetPlayerByUserId(id)
					if not target then toast("Add them from their Roblox profile: they aren't in this server.", COL.DIM); return end
					local ok = pcall(function() game:GetService("StarterGui"):SetCore("PromptSendFriendRequest", target) end)
					if not ok then toast("Roblox couldn't open the friend request just now.", COL.BAD) end
				end)
				task.spawn(function()
					local ok, isFriend = pcall(player.IsFriendsWith, player, id)
					if ok and isFriend and fb.Parent then fb.Text = "FRIENDS ✓"; fb.AutoButtonColor = false; fb.BackgroundColor3 = COL.GLASS2 end
				end)
			end

			-- THE RECORD
			local s = d.stats or {}
			local rec = panel(list, "Battle record")
			local g = grid(rec, 160, 64)
			local kd = (s.deaths or 0) > 0 and string.format("%.2f", (s.kill or 0) / s.deaths) or ((s.kill or 0) > 0 and "∞" or "–")
			local wr = (s.round or 0) > 0 and string.format("%d%%", math.floor(100 * (s.win or 0) / s.round + 0.5)) or "–"
			for i, t in ipairs({
				{fmt(s.kill or 0), "KILLS"}, {fmt(s.deaths or 0), "DEATHS"}, {kd, "K / D"},
				{fmt(s.round or 0), "ROUNDS"}, {fmt(s.win or 0), "WINS"}, {wr, "WIN RATE"},
				{fmt(s.parry or 0), "PARRIES"}, {fmt(d.seasonKills or 0), d.place and ("SEASON KILLS  ·  #" .. d.place) or "SEASON KILLS"},
			}) do tile(g, t[1], t[2], i == 8 and COL.ACCENT or nil).LayoutOrder = i end

			-- RANKED
			local rk = panel(list, "The Lists  ·  ranked")
			local g2 = grid(rk, 220, 64)
			for i, b in ipairs(GameConfig.DOORS.Lists.brackets or {"1v1", "2v2", "3v3"}) do
				local played = (d.placements or {})[b] or 0
				local r = (d.rating or {})[b]
				if r and played >= (ECON.placementMatches or 10) then
					tile(g2, string.upper((rankOf(r))), string.format("%s  ·  %s RATING", b, fmt(r)), COL.PURPLE).LayoutOrder = i
				else
					tile(g2, "UNRANKED", string.format("%s  ·  %d / %d PLACEMENTS", b, played, ECON.placementMatches or 10), COL.DIM).LayoutOrder = i
				end
			end

			-- THEIR CLASSES, as they wear them
			local cl = panel(list, mine and "Your classes" or "Their classes")
			local g3 = grid(cl, 150, 236)
			for i, cid in ipairs(GameConfig.CLASS_ORDER) do
				local def = GameConfig.CLASSES[cid]
				local cell = clearFrame(g3); cell.LayoutOrder = i
				local lo = (d.classes or {})[cid] or {}
				pcall(function()
					local th = mannequinThumb(cell, lo, def and def.weight or "Medium", UDim2.new(1, 0, 0, 206), nil, {appearance = d.appearance, weapon = true})
					th.LayoutOrder = 1
				end)
				local n = title(cell, string.upper(def and def.name or cid) .. (d.active == cid and "  ★" or ""), 14, d.active == cid and COL.ACCENT or COL.TEXT)
				n.Position = UDim2.new(0, 0, 0, 210); n.Size = UDim2.new(1, 0, 0, 22); n.TextXAlignment = Enum.TextXAlignment.Center
			end

			-- THE COLLECTION
			local c = d.collection or {}
			local co = panel(list, "Collection")
			local g4 = grid(co, 130, 64)
			for i, t in ipairs({{c.skins, "SKINS"}, {c.pieces, "ARMOR PIECES"}, {c.killfx, "KILL EFFECTS"}, {c.emotes, "EMOTES"}, {c.companions, "COMPANIONS"}, {c.titles, "TITLES"}}) do
				tile(g4, fmt(t[1] or 0), t[2]).LayoutOrder = i
			end
			if d.bestSkins and #d.bestSkins > 0 then
				heading(co, mine and "Your finest skins" or "Their finest skins")
				for _, sid in ipairs(d.bestSkins) do
					local sk = Catalog.SKIN[sid]
					if sk then
						local w = Catalog.WEAPON[sk.weapon]
						row(co, (w and w.name or sk.weapon) .. "  ·  " .. sk.name, string.upper(sk.rarity or ""), false, nil, RARITY_COL[sk.rarity] or COL.DIM)
					end
				end
			end
			if not mine then
				local back = bigBtn(list, "‹  BACK TO THE LEADERBOARDS", COL.GLASS2, function() selectTab("RANKS") end)
				back.Size = UDim2.new(1, 0, 0, 40)
			end
		end
	end
end
HX.screens()

-- the Profile key: the player you're looking at (the middle of the screen), their profile
UserInputService.InputBegan:Connect(function(input, gp)
	if gp or UserInputService:GetFocusedTextBox() or open then return end
	if ClientSettings.actionForInput(input) ~= "Profile" then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local ray = cam:ViewportPointToRay(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character}
	local res = workspace:Raycast(ray.Origin, ray.Direction * 120, params)
	local model = res and res.Instance:FindFirstAncestorOfClass("Model")
	local who
	while model and not who do
		who = Players:GetPlayerFromCharacter(model)
		model = model:FindFirstAncestorOfClass("Model")
	end
	if who and who ~= player then HX.openProfile(who.UserId) end
end)

--------------------------------------------------------------------
--  SETTINGS TAB (camera feel · attack side · keybinds)
--------------------------------------------------------------------
do
	local f = tabFrame.SETTINGS
	local sHint = label(f, "Camera feel is a multiplier on the tuned default (1.0); 0 turns an effect off. Right mouse is always block. Escape belongs to Roblox, so M is the menu key everywhere.", 13, FONT_BODY, COL.DIM)
	sHint.Size = UDim2.new(1, -170, 0, 32)
	local resetBtn = button(f, "RESET DEFAULTS", 13, COL.CARD)
	resetBtn.AnchorPoint = Vector2.new(1, 0)
	resetBtn.Position = UDim2.new(1, 0, 0, 0)
	resetBtn.Size = UDim2.fromOffset(150, 32)

	local sBody = frame(f, COL.PANEL)
	sBody.BackgroundTransparency = 1
	sBody.Position = UDim2.new(0, 0, 0, 44)
	sBody.Size = UDim2.new(1, 0, 1, -44)
	local sLayout = hlist(sBody, 24)

	local function settingsColumn(headingText, widthScale)
		local col = frame(sBody, COL.PANEL)
		col.BackgroundTransparency = 1
		col.Size = UDim2.new(widthScale, -12, 1, 0)
		local h = label(col, headingText, 16, FONT, COL.TEXT)
		h.Size = UDim2.new(1, 0, 0, 26)
		local holder = frame(col, COL.PANEL)
		holder.BackgroundTransparency = 1
		holder.Position = UDim2.new(0, 0, 0, 30)
		holder.Size = UDim2.new(1, 0, 1, -30)
		return scroll(holder, 10)
	end
	local camCol = settingsColumn("CAMERA FEEL", 0.55)
	local keyCol = settingsColumn("KEYBINDS", 0.45)

	local sliderRefresh, keyRefresh, choiceRefresh = {}, {}, {}
	local function sliderRow(spec, order)
		local r = frame(camCol, COL.PANEL)
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, -8, 0, 52)
		r.LayoutOrder = order
		local name = label(r, spec.label, 14, FONT, COL.TEXT); name.Size = UDim2.new(0.7, 0, 0, 20)
		local val = label(r, "", 14, FONT, COL.ACCENT); val.AnchorPoint = Vector2.new(1, 0); val.Position = UDim2.new(1, 0, 0, 0); val.Size = UDim2.new(0.3, 0, 0, 20); val.TextXAlignment = Enum.TextXAlignment.Right
		local h = label(r, spec.hint or "", 11, FONT_BODY, COL.DIM); h.Position = UDim2.new(0, 0, 0, 20); h.Size = UDim2.new(1, 0, 0, 14); h.TextWrapped = false; h.TextTruncate = Enum.TextTruncate.AtEnd
		local track = Instance.new("TextButton")
		track.Text = ""; track.AutoButtonColor = false
		track.Position = UDim2.new(0, 0, 0, 40); track.Size = UDim2.new(1, 0, 0, 10)
		track.BackgroundColor3 = Color3.new(0, 0, 0); track.BackgroundTransparency = 0.5; track.BorderSizePixel = 0
		track.Parent = r
		Instance.new("UICorner", track).CornerRadius = UDim.new(0, 5)
		local fill = frame(track, COL.ACCENT, 5); fill.Size = UDim2.fromScale(0.5, 1)
		local knob = frame(track, COL.TEXT); knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Size = UDim2.fromOffset(18, 18); knob.Position = UDim2.new(0.5, 0, 0.5, 0)
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
		local r = frame(keyCol, COL.PANEL)
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, -8, 0, 34)
		r.LayoutOrder = order
		local name = label(r, spec.label, 14, FONT_BODY, COL.TEXT); name.Size = UDim2.new(0.55, 0, 1, 0)
		local btn = button(r, "", 13, COL.CARD)
		btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, 0, 0.5, 0); btn.Size = UDim2.new(0.42, 0, 0, 30)
		local function refresh()
			if listening and listening.key == spec.key then btn.Text = "press a key…"; btn.TextColor3 = COL.ACCENT
			else btn.Text = ClientSettings.get("Key_" .. spec.key); btn.TextColor3 = COL.TEXT end
		end
		keyRefresh[spec.key] = refresh
		refresh()
		btn.Activated:Connect(function()
			listening = {key = spec.key, since = os.clock()}
			for _, rf in pairs(keyRefresh) do rf() end
		end)
	end
	local function choiceRow(spec, order)
		local r = frame(keyCol, COL.PANEL)
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, -8, 0, 56)
		r.LayoutOrder = order
		local name = label(r, spec.label, 14, FONT_BODY, COL.TEXT); name.Size = UDim2.new(0.55, 0, 0, 30)
		local h = label(r, spec.hint or "", 10, FONT_BODY, COL.DIM); h.Position = UDim2.new(0, 0, 0, 30); h.Size = UDim2.new(1, 0, 0, 26); h.TextYAlignment = Enum.TextYAlignment.Top
		local btn = button(r, "", 13, COL.CARD)
		btn.AnchorPoint = Vector2.new(1, 0); btn.Position = UDim2.new(1, 0, 0, 0); btn.Size = UDim2.new(0.42, 0, 0, 30)
		local function refresh() btn.Text = tostring(ClientSettings.get(spec.key)) .. "  ›" end
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
	local keyHint = label(keyCol, "Binds take keys, left / middle mouse, or scroll up / down. Right mouse is always block; M is always this menu; hold Tab for the board. Roblox can't see Mouse 4 / 5 — bind them to a key in your mouse software and use that key here. Escape cancels a rebind.", 11, FONT_BODY, COL.DIM)
	keyHint.Size = UDim2.new(1, -8, 0, 72)
	keyHint.LayoutOrder = 99
	keyHint.TextYAlignment = Enum.TextYAlignment.Top

	local function captureBind(input)
		if not listening then return end
		if os.clock() - (listening.since or 0) < 0.2 then return end
		local name = ClientSettings.inputName(input)
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then name = nil
		elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Unknown then return end
		if name == MENU_KEY.Name then toast("M stays the menu key", COL.BAD); name = nil end
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
--  ACTION BARS (per screen) + HEADER + NAVIGATION
--------------------------------------------------------------------
renderSide = function()
	if renderPlayArea then renderPlayArea() end
	local foot = screenFoot[currentTab]
	if not foot then return end
	clear(foot)
	if not foot:FindFirstChildOfClass("UIListLayout") then hlist(foot, 12).VerticalAlignment = Enum.VerticalAlignment.Center end
	local function fat(text, color, fn, width)
		local h, b = fatButton(foot, text, color, 19)
		h.Size = UDim2.fromOffset(width or 240, 56)
		h.LayoutOrder = nextOrder()
		b.Activated:Connect(fn)
		return h, b
	end
	if currentTab == "CLASSES" then
		local d = ui.dirty[ui.editing]
		fat(d and ("SAVE " .. string.upper(className(ui.editing))) or "SAVED ✔", d and COL.GREEN or COL.GLASS2, function() if d then render.CLASSES_save() end end)
		fat(state.activeClass == ui.editing and "★ ACTIVE CLASS" or "SET ACTIVE", state.activeClass == ui.editing and COL.GLASS2 or COL.BLUE, render.CLASSES_active)
		fat("TEAM PREVIEW" .. (ui.team and (": " .. (GameConfig.TEAMS[ui.team] and string.upper(GameConfig.TEAMS[ui.team].name) or ui.team)) or ""), ui.team and COL.PURPLE or COL.GLASS2, function()
			ui.team = ui.team == nil and "A" or (ui.team == "A" and "B" or nil); render.CLASSES()
		end, 260)
	elseif currentTab == "APPEARANCE" then
		fat(ui.appDirty and "SAVE" or "SAVED ✔", ui.appDirty and COL.GREEN or COL.GLASS2, function() if ui.appDirty then render.APPEARANCE_save() end end)
		fat(ui.helmPreview and "BACK TO EDITING" or "WITH HELMET", ui.helmPreview and COL.BLUE or COL.GLASS2, function() ui.helmPreview = not ui.helmPreview; render.APPEARANCE() end)
	elseif currentTab == "SERVERS" then
		fat(ui.customOpen and "CLOSE CUSTOM" or "CREATE CUSTOM", COL.GOLD, function() ui.customOpen = not ui.customOpen; render.SERVERS() end)
		fat("REFRESH", COL.BLUE, function() state.serversAt = 0; render.SERVERS() end, 180)
	end
end

local function refreshHeader()
	local def = SCREEN_DEF[currentTab]
	if def then
		local subs = {
			MODES = partyBlocked() and string.upper(partyBlocked()) or (inParty() and string.format("YOUR PARTY OF %d COMES WITH YOU", partySize()) or "PICK WHERE TO FIGHT"),
			CLASSES = string.upper(className(ui.editing)) .. "  ·  " .. string.upper(weightOf(ui.editing)) .. (ui.dirty[ui.editing] and "  ·  UNSAVED" or ""),
			ARMORY = "EVERY WEAPON AND EVERY SET  ·  AND WHERE TO GET THEM",
			SHOP = "NEW ITEMS IN " .. storeCountdown(),
			TASKS = "FINISH TASKS FOR MARKS AND TASK SKINS",
			APPEARANCE = ui.appDirty and "UNSAVED CHANGES" or "YOUR FACE, HAIR AND TITLE",
			SERVERS = "PICK A SERVER, OR MAKE YOUR OWN",
			SETTINGS = "CAMERA FEEL · KEYBINDS · ATTACK SIDE  ·  M IS THE MENU KEY",
			PASS = state.pass and string.format("TIER %d / %d  ·  PLAY AND FINISH TASKS TO CLIMB", state.pass.tier or 0, #(Catalog.PASS.tiers or {})) or "PLAY AND FINISH TASKS TO CLIMB",
		}
		sTitle.Text = def.title
		sIcon.Image = iconTexture(def.icon)
		sSub.Text = subs[currentTab] or ""
	end
	profileChip.Visible = currentTab == "PLAY"
	topCloseHolder.Visible = currentTab == "PLAY" and (alive() or not inHub())
	whereText.Visible = currentTab == "PLAY"
	whereText.Text = state.noRewards and "CHEAT SERVER  ·  NO REWARDS" or ""
	refreshWallet()
end

selectTab = function(name)
	name = ALIAS[name] or name
	if not tabFrame[name] then name = "PLAY" end
	local was = currentTab
	currentTab = name
	listening = nil
	if modalBack.Visible then closeModal() end
	local isLobby = name == "PLAY"
	lobby.Visible = isLobby
	lobbyShade.Visible = isLobby
	screenLayer.Visible = not isLobby
	for n, fr in pairs(tabFrame) do if n ~= "PLAY" then fr.Visible = n == name end end
	if open then setBlur(isLobby and 0 or 18) end
	refreshHeader()
	if render[name] then task.spawn(render[name]) end
	renderSide()
	if not isLobby and was ~= name then
		local home = UDim2.fromOffset(28, content:GetAttribute("HomeY") or 108)
		content.Position = home + UDim2.fromOffset(0, 18)
		TweenService:Create(content, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = home}):Play()
	end
end
sClose.Activated:Connect(function() selectTab("PLAY") end)
-- testing hooks: set the ScreenGui's `Tab` attribute (or `ShopTab`) from the
-- command bar / Studio MCP to switch screens without clicking
gui:GetAttributeChangedSignal("Tab"):Connect(function() local t = gui:GetAttribute("Tab"); if t then selectTab(t) end end)
gui:GetAttributeChangedSignal("ShopTab"):Connect(function() local t = gui:GetAttribute("ShopTab"); if t then ui.shopTab = t; if currentTab == "SHOP" and render.SHOP then task.spawn(render.SHOP) end end end)

--------------------------------------------------------------------
--  CINEMATIC CAMERA + MOUSE
--------------------------------------------------------------------
local classScreenUp, deathFadeUp
do
	local cineOn = false
	classScreenUp = function()
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

	deathFadeUp = function() return playerGui:FindFirstChild("DeathFade") ~= nil end

	RunService.RenderStepped:Connect(function(dt)
		local cam = workspace.CurrentCamera
		if not cam then return end
		local wantCine = not alive() and not deathFadeUp() and not _G.SpectateActive
		if wantCine then
			cam.CameraType = Enum.CameraType.Scriptable
			local target = cinematicCFrame(os.clock())
			if not cineOn or not lastCine then lastCine = cam.CFrame end
			lastCine = lastCine:Lerp(target, math.clamp(dt * (cineOn and 6 or 2), 0, 1))
			cam.CFrame = lastCine
			cineOn = true
			cam.FieldOfView = cam.FieldOfView + (62 - cam.FieldOfView) * math.clamp(dt * 3, 0, 1)
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
end

--------------------------------------------------------------------
--  OPEN / CLOSE
--------------------------------------------------------------------
local autoOpen = true
show = function(tab)
	if not open then
		open = true
		gui.Enabled = true
		fitRoot()
		root.Position = UDim2.fromScale(0.5, 0.52)
		TweenService:Create(root, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		bus:Fire("HubOpened")
		loadState()
		loadCatalog()
	end
	selectTab(tab or "PLAY")
	local day = storeDay()
	if state.login and not state.login.claimed and day and loginShownDay ~= day then
		loginShownDay = day
		task.delay(0.4, loginPopup)
	end
end

hide = function()
	if not open then return end
	open = false
	listening = nil
	closeModal()
	gui.Enabled = false
	setBlur(0)
	autoOpen = false
	bus:Fire("HubClosed")
end

topClose.Activated:Connect(function() hide() end)

-- M (or the MENU button on a touch screen: _G.HubMenuToggle): a pop-up closes
-- first, then a screen (back to the lobby), then the menu
local function menuKey()
	if open then
		if modalBack.Visible then closeModal()
		elseif currentTab ~= "PLAY" then selectTab("PLAY")
		else hide() end
	else show("PLAY") end
end
_G.HubMenuToggle = menuKey
_G.HubMenuOpen = function() return open end
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode ~= MENU_KEY or listening then return end
	if UserInputService:GetFocusedTextBox() then return end
	menuKey()
end)

task.spawn(function()
	while true do
		task.wait(1)
		if open then
			-- something else (the travel screen) switched us off: let go cleanly
			if not gui.Enabled then open = false; setBlur(0)
			else refreshHeader() end
		end
	end
end)

--------------------------------------------------------------------
--  SERVER EVENTS
--------------------------------------------------------------------
local pendingInvite = nil
--------------------------------------------------------------------
--  TRADE — swap copies of skins and companions with someone in this server
--  (Economy ▸ Trading decides everything: who may, what may, the countdown)
--------------------------------------------------------------------
do
	local f = tabFrame.TRADE
	local POINTS = {Common = 1, Rare = 4, Epic = 12, Legendary = 35, Mythic = 150}
	local VX = {Masterwork = 2, Radiant = 5, Golden = 2, Spectral = 5}
	local function defOf(key)
		if key:sub(1, 4) == "pet:" then return Catalog.COMPANION[key:sub(5)], true end
		return Catalog.SKIN[key], false
	end
	local function worth(c)
		local d = defOf(c.key)
		return d and math.floor((POINTS[d.rarity] or 1) * (VX[c.v] or 1) * ((c.n and c.n <= 100) and 1.5 or 1)) or 0
	end
	-- one item: its picture, name, number and finish
	local function card(parent, c, onClick, picked)
		local d, pet = defOf(c.key)
		local b = button(parent, "", 12, picked and COL.BLUE or COL.GLASS2)
		b.AutoButtonColor = false
		border(b, d and RARITY_COL[d.rarity] or COL.DIM, 2, picked and 0 or 0.3)
		if d then
			local th = pet and Preview.companion(b, d.id, UDim2.new(1, -8, 0, 88), true) or weaponThumb(b, d.weapon, c.key, UDim2.new(1, -8, 0, 88), 1.5)
			th.Position = UDim2.fromOffset(4, 4); th.BackgroundTransparency = 1
			local nm = title(b, d.name, 12); nm.Position = UDim2.fromOffset(6, 94); nm.Size = UDim2.new(1, -12, 0, 14); nm.TextTruncate = Enum.TextTruncate.AtEnd
			local sub = (c.v and (string.upper(c.v) .. " ") or "") .. (c.n and ("#" .. c.n) or string.upper(d.rarity))
			local sl = title(b, sub, 11, HX.VARIANT_COL[c.v] or RARITY_COL[d.rarity] or COL.DIM); sl.Position = UDim2.fromOffset(6, 110); sl.Size = UDim2.new(1, -12, 0, 13); sl.TextTruncate = Enum.TextTruncate.AtEnd
		end
		if onClick then b.Activated:Connect(onClick) end
		return b
	end
	local function grid(parent, h)
		local sf = Instance.new("ScrollingFrame")
		sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0; sf.Size = UDim2.new(1, 0, 0, h)
		sf.CanvasSize = UDim2.new(); sf.AutomaticCanvasSize = Enum.AutomaticSize.Y; sf.ScrollBarThickness = 5; sf.ScrollBarImageColor3 = COL.DIM
		sf.Parent = parent
		local g = Instance.new("UIGridLayout", sf); g.CellSize = UDim2.fromOffset(112, 128); g.CellPadding = UDim2.fromOffset(8, 8); g.SortOrder = Enum.SortOrder.LayoutOrder
		return sf
	end
	local ticking = false

	render.TRADE = function()
		clear(f)
		local T = state.trade
		local P = state.profile or {}
		local can = P.trading or {}
		if not T then
			-- who is here to trade with, and the requests waiting for you
			local left = clearFrame(f); left.Size = UDim2.new(0.5, -10, 1, 0)
			local list = scroll(left, 8)
			local head = title(list, "TRADE WITH SOMEONE HERE", 24); head.Size = UDim2.new(1, 0, 0, 30); head.LayoutOrder = nextOrder()
			if can.ok == false then dim(list, "You can't trade yet: " .. tostring(can.why or "") .. ".", 14) end
			local any = false
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player then
					any = true
					row(list, plr.DisplayName .. "  ·  level " .. tostring(plr:GetAttribute("Level") or "?"), "REQUEST", false, function()
						local r = call("TradeRequest", plr.UserId)
						toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
					end, COL.ACCENT)
				end
			end
			if not any then dim(list, "Nobody else is in this server.", 14) end
			local right = clearFrame(f); right.AnchorPoint = Vector2.new(1, 0); right.Position = UDim2.new(1, 0, 0, 0); right.Size = UDim2.new(0.5, -10, 1, 0)
			local rl = scroll(right, 8)
			local inv = panel(rl, "REQUESTS FOR YOU")
			local n = 0
			for uid, inv2 in pairs(ui.tradeInvites or {}) do
				if os.clock() - inv2.at < 30 then
					n += 1
					row(inv, inv2.name .. " wants to trade", "ACCEPT", false, function()
						ui.tradeInvites[uid] = nil
						local r = call("TradeAccept", uid)
						if not r.ok then toast(r.msg or "", COL.BAD) end
						if r.trade then state.trade = r.trade end
						render.TRADE()
					end, COL.GOOD)
				end
			end
			if n == 0 then dim(inv, "None right now.", 13) end
			local rules = panel(rl, "HOW TRADING WORKS")
			dim(rules, string.format("Both of you put up what you want to swap (up to %d each), both press READY, wait %s, then both CONFIRM. Any change un-readies both of you, so nothing can be swapped out at the last second.", can.max or 8, "5 seconds"), 13)
			dim(rules, "Crate and shop skins and hatched companions trade, with their number, finish and story. Founder gifts, free gifts, the pass and earned skins stay with whoever got them. Marks and Crowns never trade.", 13)
			dim(rules, "Trading opens at level " .. tostring(can.minLevel or 5) .. ". Nobody from staff will ever ask you to trade.", 13)
			return
		end
		-- the trade: their side, your side, your things to pick from
		local you, them = T.you, T.them
		local top = clearFrame(f); top.Size = UDim2.new(1, 0, 0, 300)
		local function side(x, w, s, heading, mine)
			local h = clearFrame(top); h.Position = UDim2.new(x, 0, 0, 0); h.Size = UDim2.new(w, -10, 1, 0)
			local total = 0
			for _, c in ipairs(s.items) do total += worth(c) end
			local hd = title(h, heading .. "  ·  WORTH " .. fmt(total) .. (s.confirmed and "  ·  CONFIRMED" or (s.ready and "  ·  READY" or "")), 18, s.confirmed and COL.GOOD or (s.ready and COL.ACCENT or COL.TEXT))
			hd.Size = UDim2.new(1, 0, 0, 24)
			local g = grid(h, 270); g.Position = UDim2.fromOffset(0, 28)
			for i, c in ipairs(s.items) do
				local cb = card(g, c, mine and function()
					local keep = {}
					for _, c2 in ipairs(you.items) do if c2.u ~= c.u then table.insert(keep, c2.u) end end
					local r = call("TradeOffer", keep); if not r.ok then toast(r.msg or "", COL.BAD) end
				end or nil)
				cb.LayoutOrder = i
			end
			if #s.items == 0 then local e = dim(g, mine and "Tap your things below to put them up." or "Nothing yet.", 13) end
		end
		side(0, 0.5, them, string.upper(them.name) .. " GIVES", false)
		side(0.5, 0.5, you, "YOU GIVE", true)
		-- your copies that can trade
		local picker = clearFrame(f); picker.Position = UDim2.fromOffset(0, 310); picker.Size = UDim2.new(1, -330, 1, -310)
		local ph = title(picker, "YOUR THINGS  ·  TAP TO PUT UP", 16, COL.DIM); ph.Size = UDim2.new(1, 0, 0, 20)
		local pg = grid(picker, 10); pg.Position = UDim2.fromOffset(0, 24); pg.Size = UDim2.new(1, 0, 1, -24)
		local offered = {}
		for _, c in ipairs(you.items) do offered[c.u] = true end
		local mine = {}
		for key, list in pairs(P.copies or {}) do
			for _, c in ipairs(list) do
				if not c.b then table.insert(mine, {u = c.u, key = key, n = c.n, v = c.v}) end
			end
		end
		table.sort(mine, function(a, b) return worth(a) > worth(b) end)
		for i, c in ipairs(mine) do
			local cb = card(pg, c, function()
				local ids = {}
				for _, c2 in ipairs(you.items) do table.insert(ids, c2.u) end
				if offered[c.u] then
					for k = #ids, 1, -1 do if ids[k] == c.u then table.remove(ids, k) end end
				else table.insert(ids, c.u) end
				local r = call("TradeOffer", ids); if not r.ok then toast(r.msg or "", COL.BAD) end
			end, offered[c.u])
			cb.LayoutOrder = i
		end
		if #mine == 0 then dim(pg, "Nothing tradable yet: crate skins and hatched companions can be traded.", 13) end
		-- ready / confirm / cancel
		local acts = clearFrame(f); acts.AnchorPoint = Vector2.new(1, 0); acts.Position = UDim2.new(1, 0, 0, 310); acts.Size = UDim2.new(0, 320, 1, -310)
		local al = scroll(acts, 10)
		if T.countdown and T.countdown > 0 then
			local cd = title(al, string.format("CONFIRM IN %d…", math.ceil(T.countdown)), 26, COL.ACCENT); cd.Size = UDim2.new(1, 0, 0, 34); cd.LayoutOrder = nextOrder()
			if not ticking then
				ticking = true
				task.delay(0.5, function() ticking = false; if currentTab == "TRADE" and state.trade then state.trade.countdown = math.max(0, (state.trade.countdown or 0) - 0.5); render.TRADE() end end)
			end
		end
		local bothReady = you.ready and them.ready
		if bothReady and (T.countdown or 0) <= 0 then
			local hc, bc = fatButton(al, you.confirmed and "WAITING FOR " .. string.upper(them.name) or "CONFIRM THE TRADE", you.confirmed and COL.GLASS2 or COL.GREEN, 20)
			hc.Size = UDim2.new(1, 0, 0, 60); hc.LayoutOrder = nextOrder()
			bc.Activated:Connect(function() local r = call("TradeConfirm"); if not r.ok then toast(r.msg or "", COL.BAD) end end)
		else
			local hr, br = fatButton(al, you.ready and "NOT READY" or "READY", you.ready and COL.GLASS2 or COL.BLUE, 20)
			hr.Size = UDim2.new(1, 0, 0, 60); hr.LayoutOrder = nextOrder()
			br.Activated:Connect(function() local r = call("TradeReady", not you.ready); if not r.ok then toast(r.msg or "", COL.BAD) end end)
		end
		local hx, bx = fatButton(al, "CANCEL", COL.BAD, 18); hx.Size = UDim2.new(1, 0, 0, 48); hx.LayoutOrder = nextOrder()
		bx.Activated:Connect(function() call("TradeCancel") end)
		dim(al, "Check both sides before you confirm: a trade can't be undone.", 13)
	end
end

hubEvent.OnClientEvent:Connect(function(what, a, b, c)
	if what == "FirstBattleDone" then
		toast("FIRST BATTLE DONE!  Off to the Courtyard: pick your class, gear and more in the menu.", COL.GOOD)
		return
	end
	if what == "Toast" then
		toast(a)
	elseif what == "TradeInvite" and type(a) == "table" then
		ui.tradeInvites = ui.tradeInvites or {}
		ui.tradeInvites[a.userId] = {name = a.name, at = os.clock()}
		modal("TRADE REQUEST", tostring(a.name) .. " wants to trade with you.", {
			{"ACCEPT", COL.GREEN, function()
				closeModal()
				ui.tradeInvites[a.userId] = nil
				local r = call("TradeAccept", a.userId)
				if not r.ok then toast(r.msg or "", COL.BAD) end
				if r.trade then state.trade = r.trade; selectTab("TRADE") end
			end},
			{"DECLINE", COL.GLASS2, function() closeModal(); ui.tradeInvites[a.userId] = nil; call("TradeDecline", a.userId) end},
		})
		if currentTab == "TRADE" then render.TRADE() end
	elseif what == "Trade" then
		state.trade = a
		if a == nil and b then toast(b == "done" and "Trade complete!" or tostring(b), b == "done" and COL.GOOD or COL.DIM) end
		if a and currentTab ~= "TRADE" then selectTab("TRADE")
		elseif currentTab == "TRADE" then render.TRADE() end
	elseif what == "Gift" and type(a) == "table" then
		local s = a.skin and Catalog.SKIN[a.skin]
		modal(a.title or "A GIFT", a.text or "", {{"SEE IT", COL.GREEN, function()
			closeModal()
			if s then ui.armoryTab = "weapons"; ui.shopWeapon = s.weapon; ui.shopSkin = s.id; selectTab("ARMORY") end
		end}}, s and function(box)
			local th = weaponStage(box, s.weapon, s.id, UDim2.new(1, 0, 0, 260)); th.LayoutOrder = 5
			border(th, RARITY_COL[s.rarity] or COL.DIM, 3, 0)
		end or nil, 560)
	elseif what == "Party" then
		state.party = a
		if a and a.queue then state.queue = state.queue or {bracket = a.bracket, ranked = a.ranked, since = os.clock() - (a.queue.waiting or 0)}
		elseif a == nil or a.queue == nil then if not state.matchFound then state.queue = nil end end
		bus:Fire("PartyChanged")
		if a and a.members then
			local ready = 0
			for _, m in ipairs(a.members) do if m.ready then ready += 1 end end
			toast(string.format("party  %d / %d   ·   %d ready", #a.members, a.max or state.partyMax, ready), COL.DIM)
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
		if open and not ui.rolling then
			if currentTab == "SHOP" or currentTab == "CLASSES" or currentTab == "ARMORY" or currentTab == "TASKS" then task.spawn(render[currentTab])
			elseif currentTab == "PLAY" then renderSide() end
		end
	elseif what == "MatchFound" then
		state.matchFound = a
		state.queue = state.queue or {bracket = a.bracket, ranked = a.ranked, since = os.clock()}
		toast("MATCH FOUND  ·  " .. tostring(a.bracket) .. (a.ranked and "  ·  ranked" or ""), COL.GOOD)
		if open and currentTab == "PLAY" then renderSide() end
	elseif what == "Rewards" then
		showRewards(a)
	elseif what == "TravelFailed" then
		state.matchFound = nil
		state.queue = nil
		if open then renderSide() end
	end
end)
acceptBtn.Activated:Connect(function()
	inviteCard.Visible = false
	pendingInvite = nil
	local r = call("PartyAccept")
	toast(r.msg or "", r.ok and COL.GOOD or COL.BAD)
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
	if what == "OpenHub" then show(tab)
	elseif what == "PlayDoor" then goDoor(tab) end   -- the Courtyard's gates
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
