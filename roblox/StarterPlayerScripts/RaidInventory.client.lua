--[[ RAID INVENTORY — Deadvault's bag and its loot windows (Game ▸ Modes ▸ Deadvault).

       YOUR GEAR (I, or the 🎒 button)   what you wear (a weapon, a sidearm, armour, your power, three
                                        relics) and your bag; pick a thing: EQUIP / TAKE OFF / DRINK /
                                        DROP. What you carry is worth (to the vault) at the top.
       A LOOT WINDOW                    searching a crate, a chest, a fallen raider's pack: what's in
                                        it; TAKE one, or TAKE ALL. Walk away and it closes.

     Server → here: AdventureEvent "Inv" (your gear, or nil: out of a raid), "Loot" (a container's
     things). Here → server: "Inv" (Equip | Unequip | Use | Drop, uid or slot), "Take" (box id,
     uid), "TakeAll" (box id), "CloseLoot" (box id). The server decides everything. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local event = ReplicatedStorage:WaitForChild("AdventureEvent")

local FONT, TITLE, BODY = Theme.FONT, Theme.FONT_TITLE, Theme.FONT_BODY
local RARITY_COLOR = {}
for _, r in ipairs(Catalog.LOOT and Catalog.LOOT.RARITIES or {}) do RARITY_COLOR[r.id] = r.color end

local gui = Instance.new("ScreenGui")
gui.Name = "RaidInventory"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")
local scale = Instance.new("UIScale")
scale.Parent = gui

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
local function stroke(f, color, th, t)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.STROKE
	s.Thickness = th or 1.5
	s.Transparency = t or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
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

local inv = nil        -- the server's picture of your gear (nil: not in a raid)
local loot = nil       -- the container open in front of you
local open = false
local selected = nil   -- {uid, where = "bag" | slot key, card}

--------------------------------------------------------------------
--  YOUR GEAR
--------------------------------------------------------------------
local back = frame(gui, Color3.new(0, 0, 0), 0.45)
back.Size = UDim2.fromScale(1, 1)
back.Visible = false
back.Active = true
local panel = frame(back, Theme.PANEL, 0.04, 18)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(900, 560)
stroke(panel, Color3.fromRGB(150, 120, 80), 2, 0.2)
local head = text(panel, "YOUR GEAR", 30, Theme.TEXT, TITLE)
head.Position = UDim2.fromOffset(24, 12); head.Size = UDim2.fromOffset(300, 38); head.TextXAlignment = Enum.TextXAlignment.Left
local worthLabel = text(panel, "", 15, Theme.DIM, FONT)
worthLabel.Position = UDim2.fromOffset(26, 48); worthLabel.Size = UDim2.fromOffset(560, 18); worthLabel.TextXAlignment = Enum.TextXAlignment.Left
local goldLabel = text(panel, "", 24, Theme.MARKS, TITLE)
goldLabel.AnchorPoint = Vector2.new(1, 0); goldLabel.Position = UDim2.new(1, -78, 0, 16); goldLabel.Size = UDim2.fromOffset(240, 32)
goldLabel.TextXAlignment = Enum.TextXAlignment.Right
local close = button(panel, "X", Theme.RED, 22)
close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -16, 0, 14); close.Size = UDim2.fromOffset(44, 44)

local wornBox = frame(panel, Theme.GLASS2, 0.1, 14)
wornBox.Position = UDim2.fromOffset(20, 78); wornBox.Size = UDim2.fromOffset(300, 320)
local wornTitle = text(wornBox, "WORN  ·  IN YOUR HANDS", 13, Theme.DIM, FONT)
wornTitle.Position = UDim2.fromOffset(12, 8); wornTitle.Size = UDim2.new(1, -24, 0, 16); wornTitle.TextXAlignment = Enum.TextXAlignment.Left
local SLOTS = {
	{key = "weapon1", label = "WEAPON", x = 12, y = 30, w = 134, h = 76}, {key = "weapon2", label = "SIDEARM", x = 154, y = 30, w = 134, h = 76},
	{key = "armor", label = "ARMOUR", x = 12, y = 114, w = 134, h = 76}, {key = "power", label = "POWER (TOME)", x = 154, y = 114, w = 134, h = 76},
	{key = "relic1", label = "RELIC", x = 12, y = 198, w = 88, h = 76}, {key = "relic2", label = "RELIC", x = 106, y = 198, w = 88, h = 76},
	{key = "relic3", label = "RELIC", x = 200, y = 198, w = 88, h = 76},
}
local hint = text(wornBox, "Pick a thing for what you can do with it.", 12, Theme.DIM, BODY)
hint.Position = UDim2.fromOffset(12, 284); hint.Size = UDim2.new(1, -24, 0, 30); hint.TextWrapped = true
hint.TextXAlignment = Enum.TextXAlignment.Left

local bagBox = frame(panel, Theme.GLASS2, 0.1, 14)
bagBox.Position = UDim2.fromOffset(332, 78); bagBox.Size = UDim2.fromOffset(548, 320)
local bagTitle = text(bagBox, "YOUR BAG", 13, Theme.DIM, FONT)
bagTitle.Position = UDim2.fromOffset(12, 8); bagTitle.Size = UDim2.new(1, -24, 0, 16); bagTitle.TextXAlignment = Enum.TextXAlignment.Left
local bagGrid = Instance.new("Frame")
bagGrid.BackgroundTransparency = 1
bagGrid.Position = UDim2.fromOffset(10, 30); bagGrid.Size = UDim2.new(1, -20, 1, -40)
bagGrid.Parent = bagBox
local bgl = Instance.new("UIGridLayout")
bgl.CellSize = UDim2.fromOffset(100, 66); bgl.CellPadding = UDim2.fromOffset(6, 6)
bgl.SortOrder = Enum.SortOrder.LayoutOrder
bgl.Parent = bagGrid

local detail = frame(panel, Theme.GLASS2, 0.1, 14)
detail.Position = UDim2.fromOffset(20, 410); detail.Size = UDim2.fromOffset(860, 130)
local dName = text(detail, "", 20, Theme.TEXT, TITLE)
dName.Position = UDim2.fromOffset(14, 8); dName.Size = UDim2.new(1, -330, 0, 26); dName.TextXAlignment = Enum.TextXAlignment.Left
local dSub = text(detail, "", 13, Theme.DIM, FONT)
dSub.Position = UDim2.fromOffset(14, 34); dSub.Size = UDim2.new(1, -330, 0, 16); dSub.TextXAlignment = Enum.TextXAlignment.Left
local dLines = text(detail, "", 13, Color3.fromRGB(226, 232, 246), BODY)
dLines.Position = UDim2.fromOffset(14, 54); dLines.Size = UDim2.new(1, -330, 0, 70)
dLines.TextWrapped = true; dLines.TextXAlignment = Enum.TextXAlignment.Left; dLines.TextYAlignment = Enum.TextYAlignment.Top
local act1 = button(detail, "EQUIP", Theme.GREEN, 16)
act1.AnchorPoint = Vector2.new(1, 0); act1.Position = UDim2.new(1, -164, 0, 40); act1.Size = UDim2.fromOffset(150, 48)
local act2 = button(detail, "DROP", Theme.RED, 16)
act2.AnchorPoint = Vector2.new(1, 0); act2.Position = UDim2.new(1, -12, 0, 40); act2.Size = UDim2.fromOffset(140, 48)

local function tile(parent, c, onClick, label)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Text = ""
	b.BackgroundColor3 = Theme.GLASS
	b.BackgroundTransparency = 0.05
	b.Size = UDim2.fromScale(1, 1)
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = b
	local sel = selected and c and selected.uid == c.uid
	stroke(b, c and (RARITY_COLOR[c.rarity] or Theme.STROKE) or Color3.fromRGB(70, 76, 100), sel and 3 or 1.5, c and 0 or 0.4)
	if c then
		local g = text(b, c.glyph or "💎", 24, Theme.TEXT, FONT)
		g.Position = UDim2.fromOffset(6, 4); g.Size = UDim2.fromOffset(30, 30); g.TextStrokeTransparency = 1
		local n = text(b, c.name or "", 11, Theme.TEXT, FONT)
		n.Position = UDim2.fromOffset(6, 34); n.Size = UDim2.new(1, -12, 1, -36)
		n.TextWrapped = true; n.TextXAlignment = Enum.TextXAlignment.Left; n.TextYAlignment = Enum.TextYAlignment.Top
		local r = text(b, c.free and "FREE" or string.upper(c.rarity or ""), 9, c.free and Theme.DIM or (RARITY_COLOR[c.rarity] or Theme.DIM), FONT)
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

render = function()
	if not inv then return end
	goldLabel.Text = "💰 " .. tostring(inv.gold or 0)
	worthLabel.Text = string.format("WHAT YOU CARRY IS WORTH ABOUT %d GOLD  ·  GET IT OUT TO KEEP IT", inv.worth or 0)
	bagTitle.Text = string.format("YOUR BAG  ·  %d / %d", #(inv.bag or {}), inv.max or 20)
	for _, c in ipairs(wornBox:GetChildren()) do if c:IsA("Frame") and c.Name == "Slot" then c:Destroy() end end
	for _, s in ipairs(SLOTS) do
		local holder = Instance.new("Frame")
		holder.Name = "Slot"
		holder.BackgroundTransparency = 1
		holder.Position = UDim2.fromOffset(s.x, s.y); holder.Size = UDim2.fromOffset(s.w, s.h)
		holder.Parent = wornBox
		tile(holder, inv.equip and inv.equip[s.key], function(card) pick(card, s.key) end, s.label)
	end
	for _, c in ipairs(bagGrid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for i = 1, inv.max or 20 do
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.LayoutOrder = i
		holder.Parent = bagGrid
		tile(holder, inv.bag and inv.bag[i], function(card) pick(card, "bag") end, nil)
	end
	-- what's picked
	local sel = selected and selected.card
	if sel then
		dName.Text = sel.name or ""
		dName.TextColor3 = RARITY_COLOR[sel.rarity] or Theme.TEXT
		dSub.Text = (sel.sub or "") .. ((sel.value or 0) > 0 and ("  ·  worth " .. sel.value .. " gold") or "")
		dLines.Text = table.concat(sel.lines or {}, "\n")
		act1.Visible, act2.Visible = true, true
		if selected.where == "bag" then
			act1.Text = sel.kind == "potion" and "DRINK" or ((sel.kind == "treasure" or sel.kind == "gold") and "VALUABLE" or "EQUIP")
			act1.BackgroundColor3 = (sel.kind == "treasure" or sel.kind == "gold") and Theme.CARD or Theme.GREEN
		else
			act1.Text = "TAKE OFF"
			act1.BackgroundColor3 = Theme.BLUE
		end
		act1.TextColor3 = Theme.textOn(act1.BackgroundColor3)
	else
		dName.Text = "Pick a thing"
		dName.TextColor3 = Theme.TEXT
		dSub.Text = "Valuables (cups, rings, idols, gems) are worth gold to the Treasurer, if you get them out."
		dLines.Text = "Your bag holds " .. tostring(inv.max or 20) .. " things. Fall, and everything here lies in your pack where you fell.\nThe free kit (FREE) is never lost and never sold."
		act1.Visible, act2.Visible = false, false
	end
end
act1.Activated:Connect(function()
	if not selected then return end
	local c = selected.card
	if selected.where == "bag" then
		if c.kind == "potion" then event:FireServer("Inv", "Use", c.uid)
		elseif c.kind ~= "treasure" and c.kind ~= "gold" then event:FireServer("Inv", "Equip", c.uid) end
	else
		event:FireServer("Inv", "Unequip", selected.where)
	end
	selected = nil
end)
act2.Activated:Connect(function()
	if not selected then return end
	event:FireServer("Inv", "Drop", selected.card.uid)
	selected = nil
end)

--------------------------------------------------------------------
--  A LOOT WINDOW (what's in what you searched)
--------------------------------------------------------------------
local lootPanel = frame(gui, Theme.PANEL, 0.06, 16)
lootPanel.AnchorPoint = Vector2.new(1, 0)
lootPanel.Position = UDim2.new(1, -24, 0, 300)
lootPanel.Size = UDim2.fromOffset(360, 400)
lootPanel.Visible = false
stroke(lootPanel, Color3.fromRGB(200, 160, 90), 2, 0.2)
local lootTitle = text(lootPanel, "", 22, Theme.TEXT, TITLE)
lootTitle.Position = UDim2.fromOffset(16, 10); lootTitle.Size = UDim2.new(1, -70, 0, 28); lootTitle.TextXAlignment = Enum.TextXAlignment.Left
local lootSub = text(lootPanel, "", 12, Theme.DIM, FONT)
lootSub.Position = UDim2.fromOffset(16, 38); lootSub.Size = UDim2.new(1, -32, 0, 16); lootSub.TextXAlignment = Enum.TextXAlignment.Left
local lootClose = button(lootPanel, "X", Theme.RED, 18)
lootClose.AnchorPoint = Vector2.new(1, 0); lootClose.Position = UDim2.new(1, -12, 0, 12); lootClose.Size = UDim2.fromOffset(36, 36)
local lootList = Instance.new("ScrollingFrame")
lootList.BackgroundTransparency = 1
lootList.BorderSizePixel = 0
lootList.Position = UDim2.fromOffset(12, 62); lootList.Size = UDim2.new(1, -24, 1, -126)
lootList.CanvasSize = UDim2.new(); lootList.AutomaticCanvasSize = Enum.AutomaticSize.Y
lootList.ScrollBarThickness = 5
lootList.Parent = lootPanel
local lll = Instance.new("UIListLayout"); lll.Padding = UDim.new(0, 6); lll.Parent = lootList
local takeAll = button(lootPanel, "TAKE ALL  (Y)", Theme.GREEN, 16)
takeAll.AnchorPoint = Vector2.new(0.5, 1); takeAll.Position = UDim2.new(0.5, 0, 1, -12); takeAll.Size = UDim2.new(1, -24, 0, 44)

local function closeLoot()
	if loot then event:FireServer("CloseLoot", loot.id) end
	loot = nil
	lootPanel.Visible = false
end
local function drawLoot()
	for _, c in ipairs(lootList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	if not loot then lootPanel.Visible = false; return end
	lootPanel.Visible = true
	lootTitle.Text = string.upper(loot.name or "")
	local n = #(loot.items or {})
	lootSub.Text = n == 0 and "NOTHING LEFT IN IT" or string.format("%d THING%s  ·  CLICK ONE TO TAKE IT", n, n == 1 and "" or "S")
	takeAll.Visible = n > 0
	for _, c in ipairs(loot.items or {}) do
		local row = Instance.new("TextButton")
		row.AutoButtonColor = true
		row.Text = ""
		row.BackgroundColor3 = Theme.GLASS2
		row.Size = UDim2.new(1, -6, 0, 64)
		local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = row
		stroke(row, RARITY_COLOR[c.rarity] or Theme.STROKE, 1.5, 0.1)
		local g = text(row, c.glyph or "💎", 26, Theme.TEXT, FONT)
		g.Position = UDim2.fromOffset(8, 0); g.Size = UDim2.fromOffset(40, 64); g.TextStrokeTransparency = 1
		local nm = text(row, c.name or "", 15, RARITY_COLOR[c.rarity] or Theme.TEXT, FONT)
		nm.Position = UDim2.fromOffset(54, 6); nm.Size = UDim2.new(1, -120, 0, 20); nm.TextXAlignment = Enum.TextXAlignment.Left
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		local ln = text(row, (c.sub or "") .. ((c.lines and c.lines[1]) and ("  ·  " .. c.lines[1]) or ""), 11, Theme.DIM, BODY)
		ln.Position = UDim2.fromOffset(54, 28); ln.Size = UDim2.new(1, -120, 0, 30); ln.TextWrapped = true
		ln.TextXAlignment = Enum.TextXAlignment.Left; ln.TextYAlignment = Enum.TextYAlignment.Top
		local t = text(row, "TAKE", 13, Theme.GO, FONT)
		t.AnchorPoint = Vector2.new(1, 0.5); t.Position = UDim2.new(1, -10, 0.5, 0); t.Size = UDim2.fromOffset(56, 20)
		row.Activated:Connect(function() if loot then event:FireServer("Take", loot.id, c.uid) end end)
		row.Parent = lootList
	end
end
takeAll.Activated:Connect(function() if loot then event:FireServer("TakeAll", loot.id) end end)
lootClose.Activated:Connect(closeLoot)

--------------------------------------------------------------------
--  OPENING, CLOSING, THE BUTTON
--------------------------------------------------------------------
local bagButton = button(gui, "🎒  BAG  (I)", Theme.GLASS, 15)
bagButton.AnchorPoint = Vector2.new(1, 1)
bagButton.Position = UDim2.new(1, -18, 1, -150)
bagButton.Size = UDim2.fromOffset(130, 40)
bagButton.BackgroundTransparency = 0.15
stroke(bagButton, Color3.fromRGB(200, 160, 90), 1.5, 0.3)
bagButton.Visible = false

local function setOpen(on)
	open = on and inv ~= nil
	back.Visible = open
	if open then selected = nil; render() end
end
close.Activated:Connect(function() setOpen(false) end)
bagButton.Activated:Connect(function() setOpen(not open) end)
-- (a test hook: the Open attribute opens and shuts it)
gui:GetAttributeChangedSignal("Open"):Connect(function() setOpen(gui:GetAttribute("Open") == true) end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed and input.KeyCode ~= Enum.KeyCode.Escape then return end
	if input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.ButtonSelect then
		if inv then setOpen(not open) end
	elseif input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		if open then setOpen(false) elseif loot then closeLoot() end
	elseif input.KeyCode == Enum.KeyCode.Y and loot and lootPanel.Visible and not open then
		event:FireServer("TakeAll", loot.id)
	end
end)

event.OnClientEvent:Connect(function(kind, data)
	if kind == "Inv" then
		inv = data
		if not inv then setOpen(false); closeLoot() end
		if selected and inv then
			-- (still there? keep it picked)
			local found = false
			for _, c in ipairs(inv.bag or {}) do if c.uid == selected.uid then selected.card = c; found = true end end
			for _, c in pairs(inv.equip or {}) do if c.uid == selected.uid then selected.card = c; selected.where = c.slot; found = true end end
			if not found then selected = nil end
		end
		if open then render() end
	elseif kind == "Loot" then
		loot = data
		drawLoot()
	end
end)

-- walk away and the loot window closes; the mouse is free while either is up
RunService:BindToRenderStep("RaidInventory", Enum.RenderPriority.Camera.Value + 22, function()
	local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min(vs.X / 960, vs.Y / 620), 0.55, 1.15)
	local looting = loot ~= nil and lootPanel.Visible
	bagButton.Visible = inv ~= nil and not open and not looting
	-- (both up: your gear slides left of the window, side by side)
	panel.Position = (open and looting) and UDim2.new(0.5, -190, 0.5, 0) or UDim2.fromScale(0.5, 0.5)
	lootPanel.Position = (open and looting) and UDim2.new(1, -16, 0.5, -200) or UDim2.new(1, -24, 0, 300)
	if loot then
		local c = player.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if not (r and h and h.Health > 0) or (typeof(loot.pos) == "Vector3" and (r.Position - loot.pos).Magnitude > 16) then closeLoot() end
	end
	if open or (loot and lootPanel.Visible) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)
