--[[ VAULT MENU — Deadvault's vault (Game ▸ Vault): what you've brought out of the raids, and the
     merchants who trade in it. Opened from PLAY ▸ ADVENTURES ▸ DEADVAULT (HubMenu calls
     _G.OpenVault).

       KIT & STASH   YOUR KIT (what you take in, what you can lose: a weapon, a sidearm, armour,
                     three relics, four draughts; an empty weapon slot goes in as the free kit's
                     plain weapon for your class) · THE STASH · pick a thing: EQUIP / TAKE OFF ·
                     SELL · the Smith's REFORGE and TEMPER · the class you raid as
       MERCHANTS     the Smith (today's four weapons for your class), the Armourer, the Alchemist,
                     the Treasurer (sell your valuables at their full worth, in one place)
       ENTER THE RAID

     The server decides everything (ReplicatedStorage ▸ VaultRemote: Hub ▸ VaultServer). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local remote = ReplicatedStorage:WaitForChild("VaultRemote")

local FONT, TITLE, BODY = Theme.FONT, Theme.FONT_TITLE, Theme.FONT_BODY
local RARITY_COLOR = {}
for _, r in ipairs(Catalog.LOOT and Catalog.LOOT.RARITIES or {}) do RARITY_COLOR[r.id] = r.color end
local BRASS = Color3.fromRGB(200, 160, 90)

local gui = Instance.new("ScreenGui")
gui.Name = "Vault"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2100   -- (over the menu it was opened from: HubMenu 2050; its toasts 2200 over this)
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local uiScale = Instance.new("UIScale"); uiScale.Parent = gui

local function frame(parent, color, t, corner)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = color or Theme.GLASS
	f.BackgroundTransparency = t or 0
	f.BorderSizePixel = 0
	if corner then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, corner); c.Parent = f end
	f.Parent = parent
	return f
end
local function text(parent, str, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = str or ""
	l.TextSize = size or 16
	l.TextColor3 = color or Theme.TEXT
	l.Font = font or FONT
	l.TextStrokeTransparency = 0.6
	l.TextStrokeColor3 = Theme.OUTLINE
	l.Parent = parent
	return l
end
local function button(parent, str, color, size)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = color
	b.Text = str
	b.TextColor3 = Theme.textOn(color)
	b.Font = FONT
	b.TextSize = size or 15
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = b
	b.Parent = parent
	return b
end
local function stroke(f, color, th, t)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness, s.Transparency = color, th or 2, t or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
end
local function left(l) l.TextXAlignment = Enum.TextXAlignment.Left; return l end

local back = frame(gui, Color3.new(0, 0, 0), 0.4)
back.Size = UDim2.fromScale(1, 1)
back.Active = true
local panel = frame(back, Theme.PANEL, 0.03, 18)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(1000, 640)
stroke(panel, BRASS, 2, 0.15)

local head = left(text(panel, "THE VAULT", 34, Theme.TEXT, TITLE))
head.Position = UDim2.fromOffset(24, 12); head.Size = UDim2.fromOffset(300, 40)
local sub = left(text(panel, "", 13, Theme.DIM, FONT))
sub.Position = UDim2.fromOffset(26, 50); sub.Size = UDim2.fromOffset(520, 16)
local goldLabel = text(panel, "", 26, Theme.MARKS, TITLE)
goldLabel.AnchorPoint = Vector2.new(1, 0); goldLabel.Position = UDim2.new(1, -78, 0, 16); goldLabel.Size = UDim2.fromOffset(220, 34)
goldLabel.TextXAlignment = Enum.TextXAlignment.Right
local close = button(panel, "X", Theme.RED, 22)
close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -16, 0, 14); close.Size = UDim2.fromOffset(44, 44)

-- tabs
local tabKit = button(panel, "KIT & STASH", Theme.BLUE, 15)
tabKit.Position = UDim2.fromOffset(340, 18); tabKit.Size = UDim2.fromOffset(150, 38)
local tabShop = button(panel, "MERCHANTS", Theme.CARD, 15)
tabShop.Position = UDim2.fromOffset(498, 18); tabShop.Size = UDim2.fromOffset(150, 38)

-- the class you raid as
local classRow = frame(panel, Theme.GLASS2, 0.15, 10)
classRow.Position = UDim2.fromOffset(20, 74); classRow.Size = UDim2.fromOffset(960, 40)
local classTitle = left(text(classRow, "RAIDING AS", 12, Theme.DIM, FONT))
classTitle.Position = UDim2.fromOffset(12, 0); classTitle.Size = UDim2.fromOffset(90, 40)
local classBtns = Instance.new("Frame")
classBtns.BackgroundTransparency = 1
classBtns.Position = UDim2.fromOffset(100, 5); classBtns.Size = UDim2.fromOffset(520, 30)
classBtns.Parent = classRow
local cbl = Instance.new("UIListLayout"); cbl.FillDirection = Enum.FillDirection.Horizontal; cbl.Padding = UDim.new(0, 6); cbl.Parent = classBtns
local freeLine = left(text(classRow, "", 11, Theme.DIM, BODY))
freeLine.Position = UDim2.fromOffset(630, 0); freeLine.Size = UDim2.fromOffset(320, 40); freeLine.TextWrapped = true

--------------------------------------------------------------------
--  KIT & STASH
--------------------------------------------------------------------
local kitPage = Instance.new("Frame")
kitPage.BackgroundTransparency = 1
kitPage.Position = UDim2.fromOffset(0, 120); kitPage.Size = UDim2.new(1, 0, 1, -120)
kitPage.Parent = panel

local kitBox = frame(kitPage, Theme.GLASS2, 0.1, 14)
kitBox.Position = UDim2.fromOffset(20, 4); kitBox.Size = UDim2.fromOffset(300, 340)
local kitTitle = left(text(kitBox, "YOUR KIT  ·  WHAT YOU RISK", 13, Theme.DIM, FONT))
kitTitle.Position = UDim2.fromOffset(12, 8); kitTitle.Size = UDim2.new(1, -24, 0, 16)
local KIT_SLOTS = {
	{key = "weapon1", label = "WEAPON", x = 12, y = 30, w = 134, h = 66}, {key = "weapon2", label = "SIDEARM", x = 154, y = 30, w = 134, h = 66},
	{key = "armor", label = "ARMOUR", x = 12, y = 102, w = 276, h = 60},
	{key = "relic1", label = "RELIC", x = 12, y = 168, w = 88, h = 76}, {key = "relic2", label = "RELIC", x = 106, y = 168, w = 88, h = 76}, {key = "relic3", label = "RELIC", x = 200, y = 168, w = 88, h = 76},
	{key = "potion1", label = "DRAUGHT", x = 12, y = 252, w = 64, h = 76}, {key = "potion2", label = "DRAUGHT", x = 82, y = 252, w = 64, h = 76},
	{key = "potion3", label = "DRAUGHT", x = 152, y = 252, w = 64, h = 76}, {key = "potion4", label = "DRAUGHT", x = 222, y = 252, w = 66, h = 76},
}

local stashBox = frame(kitPage, Theme.GLASS2, 0.1, 14)
stashBox.Position = UDim2.fromOffset(332, 4); stashBox.Size = UDim2.fromOffset(648, 340)
local stashTitle = left(text(stashBox, "THE STASH", 13, Theme.DIM, FONT))
stashTitle.Position = UDim2.fromOffset(12, 8); stashTitle.Size = UDim2.new(1, -24, 0, 16)
local grid = Instance.new("ScrollingFrame")
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.Position = UDim2.fromOffset(10, 30); grid.Size = UDim2.new(1, -20, 1, -40)
grid.CanvasSize = UDim2.new(); grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ScrollBarThickness = 6
grid.Parent = stashBox
local gl = Instance.new("UIGridLayout")
gl.CellSize = UDim2.fromOffset(98, 70); gl.CellPadding = UDim2.fromOffset(6, 6)
gl.Parent = grid

local detail = frame(kitPage, Theme.GLASS2, 0.1, 14)
detail.Position = UDim2.fromOffset(20, 352); detail.Size = UDim2.fromOffset(600, 150)
local dName = left(text(detail, "", 20, Theme.TEXT, TITLE))
dName.Position = UDim2.fromOffset(14, 8); dName.Size = UDim2.new(1, -28, 0, 26)
local dSub = left(text(detail, "", 13, Theme.DIM, FONT))
dSub.Position = UDim2.fromOffset(14, 34); dSub.Size = UDim2.new(1, -28, 0, 16)
local dLines = left(text(detail, "", 13, Color3.fromRGB(226, 232, 246), BODY))
dLines.Position = UDim2.fromOffset(14, 54); dLines.Size = UDim2.new(1, -180, 0, 90)
dLines.TextWrapped = true; dLines.TextYAlignment = Enum.TextYAlignment.Top
local act1 = button(detail, "EQUIP", Theme.GREEN, 14)
act1.AnchorPoint = Vector2.new(1, 0); act1.Position = UDim2.new(1, -12, 0, 40); act1.Size = UDim2.fromOffset(150, 32)
local act2 = button(detail, "SELL", Theme.GOLD, 14)
act2.AnchorPoint = Vector2.new(1, 0); act2.Position = UDim2.new(1, -12, 0, 76); act2.Size = UDim2.fromOffset(150, 32)
local smithRow = frame(detail, Theme.GLASS, 1)
smithRow.AnchorPoint = Vector2.new(1, 0); smithRow.Position = UDim2.new(1, -12, 0, 112); smithRow.Size = UDim2.fromOffset(310, 30)
local reforgeB = button(smithRow, "REFORGE", Theme.PURPLE, 12)
reforgeB.Size = UDim2.fromOffset(150, 30)
local temperB = button(smithRow, "TEMPER", Color3.fromRGB(210, 120, 40), 12)
temperB.Position = UDim2.fromOffset(160, 0); temperB.Size = UDim2.fromOffset(150, 30)

local enter = button(kitPage, "ENTER THE RAID", Theme.GREEN, 22)
enter.Position = UDim2.fromOffset(632, 352); enter.Size = UDim2.fromOffset(348, 60)
local enterNote = text(kitPage, "Your kit goes in with you: get out to keep it, and everything you find.", 12, Theme.DIM, BODY)
enterNote.Position = UDim2.fromOffset(632, 416); enterNote.Size = UDim2.fromOffset(348, 34); enterNote.TextWrapped = true
local toast = text(panel, "", 14, Theme.ACCENT, FONT)
toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -8); toast.Size = UDim2.fromOffset(700, 18)

--------------------------------------------------------------------
--  MERCHANTS
--------------------------------------------------------------------
local shopPage = Instance.new("Frame")
shopPage.BackgroundTransparency = 1
shopPage.Position = UDim2.fromOffset(0, 120); shopPage.Size = UDim2.new(1, 0, 1, -120)
shopPage.Visible = false
shopPage.Parent = panel
local merchList = frame(shopPage, Theme.GLASS2, 0.1, 14)
merchList.Position = UDim2.fromOffset(20, 4); merchList.Size = UDim2.fromOffset(260, 490)
local mll = Instance.new("UIListLayout"); mll.Padding = UDim.new(0, 8); mll.Parent = merchList
local mpad = Instance.new("UIPadding"); mpad.PaddingTop = UDim.new(0, 10); mpad.PaddingLeft = UDim.new(0, 10); mpad.PaddingRight = UDim.new(0, 10); mpad.Parent = merchList
local shopBox = frame(shopPage, Theme.GLASS2, 0.1, 14)
shopBox.Position = UDim2.fromOffset(292, 4); shopBox.Size = UDim2.fromOffset(688, 490)
local mName = left(text(shopBox, "", 26, Theme.TEXT, TITLE))
mName.Position = UDim2.fromOffset(18, 10); mName.Size = UDim2.new(1, -36, 0, 32)
local mLine = left(text(shopBox, "", 14, Theme.DIM, BODY))
mLine.Position = UDim2.fromOffset(18, 44); mLine.Size = UDim2.new(1, -36, 0, 36); mLine.TextWrapped = true
local wares = Instance.new("ScrollingFrame")
wares.BackgroundTransparency = 1
wares.BorderSizePixel = 0
wares.Position = UDim2.fromOffset(14, 88); wares.Size = UDim2.new(1, -28, 1, -100)
wares.CanvasSize = UDim2.new(); wares.AutomaticCanvasSize = Enum.AutomaticSize.Y
wares.ScrollBarThickness = 6
wares.Parent = shopBox
local wgl = Instance.new("UIGridLayout")
wgl.CellSize = UDim2.fromOffset(318, 112); wgl.CellPadding = UDim2.fromOffset(10, 10)
wgl.Parent = wares

--------------------------------------------------------------------
local view, selected, tab, merchant = nil, nil, "kit", "Smith"
local function say(msg, good)
	toast.Text = msg or ""
	toast.TextColor3 = good == false and Theme.BAD or Theme.ACCENT
	task.delay(2.5, function() if toast.Text == msg then toast.Text = "" end end)
end

local function itemTile(parent, c, onClick, h, label)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Text = ""
	b.BackgroundColor3 = Theme.GLASS
	b.BackgroundTransparency = 0.05
	b.Size = UDim2.new(1, 0, 0, h or 70)
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = b
	stroke(b, c and (RARITY_COLOR[c.rarity] or Theme.STROKE) or Color3.fromRGB(70, 76, 100), (selected and c and selected.uid == c.uid) and 3 or 1.5, c and 0 or 0.4)
	if c then
		local g = text(b, c.glyph or "💎", 24, Theme.TEXT, FONT)
		g.Position = UDim2.fromOffset(6, 4); g.Size = UDim2.fromOffset(30, 30); g.TextStrokeTransparency = 1
		local n = left(text(b, c.name or "", 11, Theme.TEXT, FONT))
		n.Position = UDim2.fromOffset(6, 34); n.Size = UDim2.new(1, -12, 1, -36)
		n.TextWrapped = true; n.TextYAlignment = Enum.TextYAlignment.Top
		local r = text(b, string.upper(c.rarity or ""), 9, RARITY_COLOR[c.rarity] or Theme.DIM, FONT)
		r.AnchorPoint = Vector2.new(1, 0); r.Position = UDim2.new(1, -6, 0, 5); r.Size = UDim2.fromOffset(70, 12); r.TextXAlignment = Enum.TextXAlignment.Right
		if (c.value or 0) > 0 then
			local v = text(b, "💰" .. c.value, 10, Theme.MARKS, FONT)
			v.AnchorPoint = Vector2.new(1, 0); v.Position = UDim2.new(1, -6, 0, 18); v.Size = UDim2.fromOffset(70, 12); v.TextXAlignment = Enum.TextXAlignment.Right
		end
	elseif label then
		local l = text(b, label, 10, Theme.DIM, FONT)
		l.Size = UDim2.fromScale(1, 1)
	end
	b.Activated:Connect(function() onClick(c) end)
	b.Parent = parent
	return b
end

local render
local function pick(c, where)
	if not c then return end
	selected = (selected and selected.uid == c.uid) and nil or {uid = c.uid, where = where, card = c}
	render()
end
local function call(kind, arg)
	local ok, res = pcall(function() return remote:InvokeServer(kind, arg) end)
	if not ok or type(res) ~= "table" then say("The vault didn't answer", false); return end
	if res.msg then say(res.msg, res.ok) end
	if res.view then view = res.view end
	if kind ~= "View" and kind ~= "Work" then selected = nil end
	if kind == "Work" and res.ok and selected and view then
		-- (the reworked one, still picked)
		for _, c in ipairs(view.stash or {}) do if c.uid == selected.uid then selected.card = c end end
		for _, c in ipairs(view.kit or {}) do if c.uid == selected.uid then selected.card = c end end
	end
	render()
end

local function drawKit()
	for _, c in ipairs(kitBox:GetChildren()) do if c:IsA("GuiObject") and c ~= kitTitle then c:Destroy() end end
	local bySlot = {}
	for _, c in ipairs(view.kit or {}) do bySlot[c.slot] = c end
	for _, s in ipairs(KIT_SLOTS) do
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Position = UDim2.fromOffset(s.x, s.y); holder.Size = UDim2.fromOffset(s.w, s.h)
		holder.Parent = kitBox
		local label = s.label
		if s.key == "weapon1" and not bySlot.weapon1 and view.free and view.free[1] then label = "FREE: " .. string.upper(view.free[1]) end
		if s.key == "weapon2" and not bySlot.weapon2 and view.free and view.free[2] then label = "FREE: " .. string.upper(view.free[2]) end
		itemTile(holder, bySlot[s.key], function(card) pick(card, "kit") end, s.h, label)
	end
	for _, c in ipairs(grid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for _, c in ipairs(view.stash or {}) do itemTile(grid, c, function(card) pick(card, "stash") end) end
	stashTitle.Text = string.format("THE STASH  ·  %d / %d", #(view.stash or {}), view.max or 60)
	local sel = selected and selected.card
	if sel then
		dName.Text = sel.name or ""
		dName.TextColor3 = RARITY_COLOR[sel.rarity] or Theme.TEXT
		dSub.Text = (sel.sub or "") .. ((sel.value or 0) > 0 and ("  ·  worth " .. sel.value .. " gold") or "")
		dLines.Text = table.concat(sel.lines or {}, "\n")
		act1.Visible = sel.kind ~= "treasure"
		act1.Text = selected.where == "kit" and "TAKE OFF" or "EQUIP"
		act1.BackgroundColor3 = selected.where == "kit" and Theme.BLUE or Theme.GREEN
		act2.Visible = selected.where == "stash"
		act2.Text = "SELL  ·  " .. tostring(sel.value or 0)
		smithRow.Visible = sel.kind == "weapon"
		reforgeB.Text = sel.reforge and ("REFORGE  ·  💰" .. sel.reforge) or "REFORGE  ·  —"
		temperB.Text = sel.temper and ("TEMPER  ·  💰" .. sel.temper) or "TEMPER  ·  FINEST"
	else
		dName.Text = "Pick something"
		dName.TextColor3 = Theme.TEXT
		dSub.Text = "Your kit is what you take in, and what you can lose."
		dLines.Text = "Everything you get out with lands in the stash. Sell what you don't need; the Treasurer pays full worth for valuables. The Smith reforges a weapon's powers, or tempers it a rarity higher."
		act1.Visible, act2.Visible, smithRow.Visible = false, false, false
	end
end

local function drawShop()
	for _, c in ipairs(merchList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local cur
	for _, m in ipairs(view.merchants or {}) do
		local b = button(merchList, m.glyph .. "  " .. m.name, m.id == merchant and Theme.BLUE or Theme.CARD, 14)
		b.Size = UDim2.new(1, 0, 0, 52)
		b.TextXAlignment = Enum.TextXAlignment.Left
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 12); pad.Parent = b
		b.Activated:Connect(function() merchant = m.id; render() end)
		if m.id == merchant then cur = m end
	end
	for _, c in ipairs(wares:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	if not cur then return end
	mName.Text = cur.glyph .. "  " .. string.upper(cur.name)
	mLine.Text = "“" .. (cur.line or "") .. "”"
	if cur.id == "Treasurer" then
		-- your valuables, sold here at their full worth
		local any = false
		for _, c in ipairs(view.stash or {}) do
			if c.kind == "treasure" then
				any = true
				local card = frame(wares, Theme.GLASS, 0.05, 12)
				stroke(card, RARITY_COLOR[c.rarity] or Theme.STROKE, 1.5, 0)
				local g = text(card, c.glyph or "💎", 30, Theme.TEXT, FONT); g.Position = UDim2.fromOffset(10, 10); g.Size = UDim2.fromOffset(40, 40); g.TextStrokeTransparency = 1
				local n = left(text(card, c.name, 16, RARITY_COLOR[c.rarity] or Theme.TEXT, FONT)); n.Position = UDim2.fromOffset(58, 12); n.Size = UDim2.new(1, -70, 0, 20)
				local s2 = left(text(card, c.sub or "", 12, Theme.DIM, BODY)); s2.Position = UDim2.fromOffset(58, 34); s2.Size = UDim2.new(1, -70, 0, 16)
				local b = button(card, "SELL  ·  💰" .. tostring(c.value or 0), Theme.GOLD, 14)
				b.AnchorPoint = Vector2.new(1, 1); b.Position = UDim2.new(1, -10, 1, -10); b.Size = UDim2.fromOffset(150, 34)
				b.Activated:Connect(function() call("Sell", c.uid) end)
			end
		end
		if not any then
			local l = text(wares, "No valuables in your stash. Cups, rings, idols, gems: bring them out of the Deadvault.", 15, Theme.DIM, BODY)
			l.Size = UDim2.fromOffset(318, 112); l.TextWrapped = true
		end
		return
	end
	for _, c in ipairs(cur.wares or {}) do
		local card = frame(wares, Theme.GLASS, 0.05, 12)
		stroke(card, RARITY_COLOR[c.rarity] or Theme.STROKE, 1.5, 0)
		local g = text(card, c.glyph or "💎", 30, Theme.TEXT, FONT); g.Position = UDim2.fromOffset(10, 10); g.Size = UDim2.fromOffset(40, 40); g.TextStrokeTransparency = 1
		local n = left(text(card, c.name or "", 15, RARITY_COLOR[c.rarity] or Theme.TEXT, FONT)); n.Position = UDim2.fromOffset(58, 10); n.Size = UDim2.new(1, -70, 0, 20)
		n.TextTruncate = Enum.TextTruncate.AtEnd
		local s2 = left(text(card, table.concat(c.lines or {}, " · "), 11, Theme.DIM, BODY)); s2.Position = UDim2.fromOffset(58, 32); s2.Size = UDim2.new(1, -70, 0, 32)
		s2.TextWrapped = true; s2.TextYAlignment = Enum.TextYAlignment.Top
		local b = button(card, c.sold and "SOLD  ·  MORE TOMORROW" or ("BUY  ·  💰" .. tostring(c.price or 0)), c.sold and Theme.CARD or Theme.GREEN, 14)
		b.AnchorPoint = Vector2.new(1, 1); b.Position = UDim2.new(1, -10, 1, -10); b.Size = UDim2.fromOffset(c.sold and 220 or 140, 34)
		b.Activated:Connect(function() if not c.sold then call("Buy", {cur.id, c.index}) end end)
	end
end

render = function()
	if not view then return end
	goldLabel.Text = "💰 " .. tostring(view.gold or 0)
	sub.Text = string.format("%d RAIDS  ·  %d TIMES OUT ALIVE", view.raids or 0, view.out or 0)
	tabKit.BackgroundColor3 = tab == "kit" and Theme.BLUE or Theme.CARD
	tabShop.BackgroundColor3 = tab == "shop" and Theme.BLUE or Theme.CARD
	kitPage.Visible, shopPage.Visible = tab == "kit", tab == "shop"
	for _, c in ipairs(classBtns:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for _, cl in ipairs(view.classes or {}) do
		local on = cl.id == view.class
		local b = button(classBtns, string.upper(cl.name) .. (cl.open and "" or " 🔒"), on and Theme.GREEN or (cl.open and Theme.CARD or Theme.GLASS), 12)
		b.Size = UDim2.fromOffset(96, 30)
		b.Activated:Connect(function() if cl.open and not on then call("Class", cl.id) end end)
	end
	freeLine.Text = (view.free and view.free[1]) and string.format("No weapon in your kit? You go in with a plain %s%s and a draught: free, never lost.", view.free[1], view.free[2] and (" and " .. view.free[2]) or "") or ""
	if tab == "kit" then drawKit() else drawShop() end
end
act1.Activated:Connect(function() if selected then call(selected.where == "kit" and "Unequip" or "Equip", selected.uid) end end)
act2.Activated:Connect(function() if selected and selected.where == "stash" then call("Sell", selected.uid) end end)
reforgeB.Activated:Connect(function() if selected then call("Work", {selected.uid, "reforge"}) end end)
temperB.Activated:Connect(function() if selected then call("Work", {selected.uid, "temper"}) end end)
tabKit.Activated:Connect(function() tab = "kit"; render() end)
tabShop.Activated:Connect(function() tab = "shop"; selected = nil; render() end)

local function setOpen(on)
	gui.Enabled = on
	if on then call("View") end
end
close.Activated:Connect(function() setOpen(false) end)
enter.Activated:Connect(function()
	setOpen(false)
	if _G.HubGoDoor then _G.HubGoDoor("Deadvault") end
end)
_G.OpenVault = function() setOpen(true) end
-- (test hooks: the Open and Tab attributes)
gui:GetAttributeChangedSignal("Tab"):Connect(function() tab = gui:GetAttribute("Tab") == "shop" and "shop" or "kit"; render() end)
gui:GetAttributeChangedSignal("Open"):Connect(function() setOpen(gui:GetAttribute("Open") == true) end)
UserInputService.InputBegan:Connect(function(input)
	if gui.Enabled and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then setOpen(false) end
end)
RunService:BindToRenderStep("VaultMouse", Enum.RenderPriority.Camera.Value + 21, function()
	if gui.Enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		uiScale.Scale = math.clamp(math.min(vs.X / 1040, vs.Y / 680), 0.5, 1.2)
	end
end)
