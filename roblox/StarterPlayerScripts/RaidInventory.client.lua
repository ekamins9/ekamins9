--[[ RAID INVENTORY — Deadvault's gear, bag, belt and loot windows (Game ▸ Modes ▸ Deadvault), in
     the dungeon game's look (ReplicatedStorage ▸ DarkUI: every thing shown as itself, in 3D).

       THE BELT (always on screen)     your four draughts: keys 3 – 6 (a tap on phone) drink one: a
                                       moment with the bottle at your lips, slowed, then it works
       YOUR GEAR (I, or the bag button) what you wear (a weapon, a sidearm, armour, a tome's power,
                                       three relics), the belt and the bag; pick a thing: EQUIP /
                                       TAKE OFF / DRINK / DROP. What you carry is worth (to the vault)
       A LOOT WINDOW                   searching a crate, a chest, a body: what's in it; TAKE one, or
                                       TAKE ALL (Y). Walk away and it closes.

     Server → here: AdventureEvent "Inv" (your gear, or nil: out of a raid), "Loot" (a container's
     things). Here → server: "Inv" (Equip | Unequip | Use | Drop, uid or slot), "Belt" (1–4),
     "Take" (box id, uid), "TakeAll" (box id), "CloseLoot" (box id). The server decides. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local DarkUI = require(ReplicatedStorage:WaitForChild("DarkUI"))
local event = ReplicatedStorage:WaitForChild("AdventureEvent")

local C = DarkUI.C
local RAR = DarkUI.RARITY
local BOLD, SEMI = Enum.FontWeight.Bold, Enum.FontWeight.SemiBold
local T = DarkUI.text
local function left(l) l.TextXAlignment = Enum.TextXAlignment.Left; return l end

local gui = Instance.new("ScreenGui")
gui.Name = "RaidInventory"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")
local scale = Instance.new("UIScale")
scale.Parent = gui
local tip = DarkUI.tooltip(gui)

local inv = nil        -- the server's picture of your gear (nil: not in a raid)
local loot = nil       -- the container open in front of you
local open = false
local selected = nil   -- {uid, where = "bag" | slot key, card}
local BELT_KEYS = {Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six}

local function cell(parent, card, onClick, opts)
	opts = opts or {}
	local c = DarkUI.slot(parent, card and card.rarity or nil)
	c.Size = opts.size or UDim2.fromScale(1, 1)
	c.Position = opts.pos or UDim2.new()
	c.LayoutOrder = opts.order or 0
	if card and selected and selected.uid == card.uid then DarkUI.stroke(c, C.GOLD2, 2) end
	if card then DarkUI.icon(c, card, {upright = opts.upright}) end
	if card and card.free then
		local f = T(c, "FREE", 9, C.DIM, BOLD); f.AnchorPoint = Vector2.new(1, 1); f.Position = UDim2.new(1, -3, 1, -2); f.Size = UDim2.fromOffset(40, 12)
		f.TextXAlignment = Enum.TextXAlignment.Right; f.ZIndex = 4
	end
	if opts.label and not card then local l = T(c, opts.label, 12, C.FAINT, BOLD); l.Size = UDim2.fromScale(1, 1); l.ZIndex = 3 end
	if opts.key then
		local k = T(c, opts.key, 12, C.GOLD2, BOLD); k.Position = UDim2.fromOffset(3, 1); k.Size = UDim2.fromOffset(14, 14); k.ZIndex = 5
	end
	local b = Instance.new("TextButton")
	b.BackgroundTransparency = 1; b.Text = ""; b.Size = UDim2.fromScale(1, 1); b.ZIndex = 6
	b.Parent = c
	b.MouseEnter:Connect(function() if card then tip:show(card) end end)
	b.MouseLeave:Connect(function() tip:hide() end)
	b.Activated:Connect(function() tip:hide(); if onClick then onClick(card) end end)
	return c
end

--------------------------------------------------------------------
--  YOUR GEAR
--------------------------------------------------------------------
local back = Instance.new("Frame")
back.BackgroundColor3 = Color3.new(0, 0, 0)
back.BackgroundTransparency = 0.35
back.BorderSizePixel = 0
back.Size = UDim2.fromScale(1, 1)
back.Visible = false
back.Active = true
back.Parent = gui
local panel = DarkUI.panel(back)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(940, 600)
local head = left(T(panel, "Your Gear", 28, C.GOLD2, BOLD))
head.Position = UDim2.fromOffset(28, 14); head.Size = UDim2.fromOffset(300, 34)
local worthLabel = left(T(panel, "", 14, C.DIM, SEMI))
worthLabel.Position = UDim2.fromOffset(30, 50); worthLabel.Size = UDim2.fromOffset(560, 18)
local goldLabel = T(panel, "", 22, C.GOLD2, BOLD)
goldLabel.AnchorPoint = Vector2.new(1, 0); goldLabel.Position = UDim2.new(1, -90, 0, 18); goldLabel.Size = UDim2.fromOffset(260, 30)
goldLabel.TextXAlignment = Enum.TextXAlignment.Right
local close = DarkUI.button(panel, "X", "red", 20)
close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -20, 0, 16); close.Size = UDim2.fromOffset(44, 40)
DarkUI.rule(panel, 74)

local worn = Instance.new("Frame")
worn.BackgroundTransparency = 1
worn.Position = UDim2.fromOffset(24, 88); worn.Size = UDim2.fromOffset(330, 360)
worn.Parent = panel
local SLOTS = {
	{key = "weapon1", label = "1", x = 0, y = 0, w = 90, h = 190, upright = true}, {key = "weapon2", label = "2", x = 240, y = 0, w = 90, h = 190, upright = true},
	{key = "armor", label = "ARMOUR", x = 104, y = 0, w = 122, h = 122}, {key = "power", label = "TOME", x = 129, y = 134, w = 72, h = 72},
	{key = "relic1", label = "R", x = 66, y = 218, w = 60, h = 60}, {key = "relic2", label = "R", x = 135, y = 218, w = 60, h = 60}, {key = "relic3", label = "R", x = 204, y = 218, w = 60, h = 60},
}
local beltTitle = T(worn, "Belt  ·  3 – 6", 13, C.DIM, SEMI)
beltTitle.Position = UDim2.fromOffset(0, 288); beltTitle.Size = UDim2.new(1, 0, 0, 16)
local bagTitle = T(panel, "Bag", 18, C.GOLD2, BOLD)
bagTitle.Position = UDim2.fromOffset(370, 86); bagTitle.Size = UDim2.fromOffset(546, 22)
local bagGrid = Instance.new("Frame")
bagGrid.BackgroundTransparency = 1
bagGrid.Position = UDim2.fromOffset(372, 114); bagGrid.Size = UDim2.fromOffset(546, 330)
bagGrid.Parent = panel
local bgl = Instance.new("UIGridLayout")
bgl.CellSize = UDim2.fromOffset(62, 62); bgl.CellPadding = UDim2.fromOffset(6, 6)
bgl.SortOrder = Enum.SortOrder.LayoutOrder
bgl.Parent = bagGrid

local detail = Instance.new("Frame")
detail.BackgroundColor3 = C.INSET
detail.BorderSizePixel = 0
detail.Position = UDim2.fromOffset(24, 460); detail.Size = UDim2.new(1, -48, 0, 120)
detail.Parent = panel
DarkUI.stroke(detail, C.EDGE, 1)
local dName = left(T(detail, "", 18, C.TEXT, BOLD)); dName.Position = UDim2.fromOffset(14, 8); dName.Size = UDim2.new(1, -340, 0, 24)
local dSub = left(T(detail, "", 13, C.DIM, SEMI)); dSub.Position = UDim2.fromOffset(14, 34); dSub.Size = UDim2.new(1, -340, 0, 16)
local dLines = left(T(detail, "", 13, C.TEXT)); dLines.Position = UDim2.fromOffset(14, 54); dLines.Size = UDim2.new(1, -340, 0, 60)
dLines.TextWrapped = true; dLines.TextYAlignment = Enum.TextYAlignment.Top
local act1 = DarkUI.button(detail, "Equip", "green", 16)
act1.AnchorPoint = Vector2.new(1, 0); act1.Position = UDim2.new(1, -164, 0, 38); act1.Size = UDim2.fromOffset(146, 46)
local act2 = DarkUI.button(detail, "Drop", "red", 16)
act2.AnchorPoint = Vector2.new(1, 0); act2.Position = UDim2.new(1, -12, 0, 38); act2.Size = UDim2.fromOffset(140, 46)

local render
local function pick(card, where)
	if not card then return end
	selected = (selected and selected.uid == card.uid) and nil or {uid = card.uid, where = where, card = card}
	render()
end

render = function()
	if not inv then return end
	goldLabel.Text = "Gold  " .. tostring(inv.gold or 0)
	worthLabel.Text = string.format("What you carry is worth about %d gold  ·  get it out to keep it", inv.worth or 0)
	bagTitle.Text = string.format("Bag  ·  %d / %d", #(inv.bag or {}), inv.max or 20)
	for _, c in ipairs(worn:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, s in ipairs(SLOTS) do
		cell(worn, inv.equip and inv.equip[s.key], function(card) pick(card, s.key) end, {pos = UDim2.fromOffset(s.x, s.y), size = UDim2.fromOffset(s.w, s.h), label = s.label, upright = s.upright})
	end
	for i = 1, inv.beltMax or 4 do
		local card = inv.belt and inv.belt[i]
		cell(worn, card, function(c2) pick(c2, "belt" .. i) end, {pos = UDim2.fromOffset(22 + (i - 1) * 74, 306), size = UDim2.fromOffset(66, 66), label = tostring(i + 2), key = card and tostring(i + 2) or nil})
	end
	for _, c in ipairs(bagGrid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for i = 1, inv.max or 20 do
		cell(bagGrid, inv.bag and inv.bag[i], function(card) pick(card, "bag") end, {order = i})
	end
	local sel = selected and selected.card
	if sel then
		dName.Text = sel.name or ""
		dName.TextColor3 = RAR[sel.rarity] or C.TEXT
		dSub.Text = (sel.sub or "") .. ((sel.value or 0) > 0 and ("  ·  worth " .. sel.value .. " gold") or "")
		dLines.Text = table.concat(sel.lines or {}, "\n")
		act1.Visible, act2.Visible = true, true
		if selected.where == "bag" then
			act1.Text = sel.kind == "potion" and "To Belt" or "Equip"
			act1.Visible = sel.kind ~= "treasure" and sel.kind ~= "gold"
		elseif selected.where:match("^belt") then
			act1.Text = "Drink"
		else
			act1.Text = "Take Off"
		end
	else
		dName.Text = "Pick a thing"
		dName.TextColor3 = C.TEXT
		dSub.Text = "Valuables (cups, rings, idols, gems) sell to the Treasurer, if you get them out."
		dLines.Text = "Fall, and everything here lies on your body where you fell. The free kit (FREE) is never lost."
		act1.Visible, act2.Visible = false, false
	end
end
act1.Activated:Connect(function()
	if not selected then return end
	local c = selected.card
	if selected.where == "bag" then
		if c.kind ~= "treasure" and c.kind ~= "gold" then event:FireServer("Inv", "Equip", c.uid) end
	elseif selected.where:match("^belt") then
		event:FireServer("Inv", "Use", c.uid)
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
--  A LOOT WINDOW
--------------------------------------------------------------------
local lootPanel = DarkUI.panel(gui)
lootPanel.AnchorPoint = Vector2.new(1, 0)
lootPanel.Position = UDim2.new(1, -24, 0, 300)
lootPanel.Size = UDim2.fromOffset(360, 400)
lootPanel.Visible = false
local lootTitle = T(lootPanel, "", 22, C.GOLD2, BOLD)
lootTitle.Position = UDim2.fromOffset(0, 12); lootTitle.Size = UDim2.new(1, 0, 0, 26)
local lootSub = T(lootPanel, "", 12, C.DIM, SEMI)
lootSub.Position = UDim2.fromOffset(0, 38); lootSub.Size = UDim2.new(1, 0, 0, 16)
DarkUI.rule(lootPanel, 58)
local lootClose = DarkUI.button(lootPanel, "X", "red", 16)
lootClose.AnchorPoint = Vector2.new(1, 0); lootClose.Position = UDim2.new(1, -14, 0, 12); lootClose.Size = UDim2.fromOffset(34, 32)
local lootList = Instance.new("ScrollingFrame")
lootList.BackgroundTransparency = 1
lootList.BorderSizePixel = 0
lootList.Position = UDim2.fromOffset(14, 70); lootList.Size = UDim2.new(1, -28, 1, -132)
lootList.CanvasSize = UDim2.new(); lootList.AutomaticCanvasSize = Enum.AutomaticSize.Y
lootList.ScrollBarThickness = 4
lootList.Parent = lootPanel
local lll = Instance.new("UIListLayout"); lll.Padding = UDim.new(0, 6); lll.Parent = lootList
local takeAll = DarkUI.button(lootPanel, "Take All  (Y)", "gold", 18)
takeAll.AnchorPoint = Vector2.new(0.5, 1); takeAll.Position = UDim2.new(0.5, 0, 1, -14); takeAll.Size = UDim2.new(1, -28, 0, 44)

local function closeLoot()
	if loot then event:FireServer("CloseLoot", loot.id) end
	loot = nil
	lootPanel.Visible = false
	tip:hide()
end
local function drawLoot()
	for _, c in ipairs(lootList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	if not loot then lootPanel.Visible = false; return end
	lootPanel.Visible = true
	lootTitle.Text = loot.name or ""
	local n = #(loot.items or {})
	lootSub.Text = n == 0 and "Nothing left in it" or string.format("%d thing%s  ·  click one to take it", n, n == 1 and "" or "s")
	takeAll.Visible = n > 0
	for _, c in ipairs(loot.items or {}) do
		local row = Instance.new("TextButton")
		row.AutoButtonColor = false
		row.Text = ""
		row.BackgroundColor3 = C.INSET
		row.BorderSizePixel = 0
		row.Size = UDim2.new(1, -6, 0, 64)
		DarkUI.stroke(row, RAR[c.rarity] or C.EDGE, 1, 0.3)
		local ic = DarkUI.slot(row, c.rarity)
		ic.Position = UDim2.fromOffset(4, 4); ic.Size = UDim2.fromOffset(56, 56)
		DarkUI.icon(ic, c)
		local nm = left(T(row, c.name or "", 15, RAR[c.rarity] or C.TEXT, BOLD))
		nm.Position = UDim2.fromOffset(70, 8); nm.Size = UDim2.new(1, -130, 0, 20); nm.TextTruncate = Enum.TextTruncate.AtEnd
		local ln = left(T(row, (c.sub or "") .. ((c.lines and c.lines[1]) and ("  ·  " .. c.lines[1]) or ""), 11, C.DIM))
		ln.Position = UDim2.fromOffset(70, 30); ln.Size = UDim2.new(1, -130, 0, 30); ln.TextWrapped = true; ln.TextYAlignment = Enum.TextYAlignment.Top
		local t = T(row, "Take", 14, C.GOOD, BOLD)
		t.AnchorPoint = Vector2.new(1, 0.5); t.Position = UDim2.new(1, -10, 0.5, 0); t.Size = UDim2.fromOffset(50, 20)
		row.MouseEnter:Connect(function() tip:show(c) end)
		row.MouseLeave:Connect(function() tip:hide() end)
		row.Activated:Connect(function() tip:hide(); if loot then event:FireServer("Take", loot.id, c.uid) end end)
		row.Parent = lootList
	end
end
takeAll.Activated:Connect(function() if loot then event:FireServer("TakeAll", loot.id) end end)
lootClose.Activated:Connect(closeLoot)

--------------------------------------------------------------------
--  THE BELT (on screen) and the bag button
--------------------------------------------------------------------
local belt = Instance.new("Frame")
belt.BackgroundTransparency = 1
belt.AnchorPoint = Vector2.new(0, 1)
belt.Position = UDim2.new(0, 22, 1, -22)
belt.Size = UDim2.fromOffset(4 * 70, 92)
belt.Visible = false
belt.Parent = gui
local beltLbl = left(T(belt, "BELT", 12, C.GOLD, BOLD)); beltLbl.Size = UDim2.new(1, 0, 0, 16)
local beltSlots = Instance.new("Frame"); beltSlots.BackgroundTransparency = 1; beltSlots.Position = UDim2.fromOffset(0, 20); beltSlots.Size = UDim2.new(1, 0, 0, 64); beltSlots.Parent = belt
local drinkBar = Instance.new("Frame")
drinkBar.BackgroundColor3 = C.INSET; drinkBar.BorderSizePixel = 0
drinkBar.AnchorPoint = Vector2.new(0.5, 1)
drinkBar.Position = UDim2.new(0.5, 0, 1, -200); drinkBar.Size = UDim2.fromOffset(240, 26)
drinkBar.Visible = false
drinkBar.Parent = gui
DarkUI.stroke(drinkBar, C.GOLD, 1)
local drinkFill = Instance.new("Frame"); drinkFill.BackgroundColor3 = Color3.fromRGB(200, 60, 60); drinkFill.BorderSizePixel = 0; drinkFill.Size = UDim2.fromScale(0, 1); drinkFill.Parent = drinkBar
local drinkText = T(drinkBar, "Drinking", 14, C.TEXT, BOLD); drinkText.Size = UDim2.fromScale(1, 1); drinkText.ZIndex = 2
local lastBelt = ""
local function drawBelt()
	local key = ""
	for i = 1, 4 do local c = inv and inv.belt and inv.belt[i]; key ..= (c and c.uid or "-") end
	if key == lastBelt then return end
	lastBelt = key
	for _, c in ipairs(beltSlots:GetChildren()) do c:Destroy() end
	for i = 1, 4 do
		local card = inv and inv.belt and inv.belt[i]
		cell(beltSlots, card, function() if card then event:FireServer("Belt", i) end end,
			{pos = UDim2.fromOffset((i - 1) * 70, 0), size = UDim2.fromOffset(64, 64), label = tostring(i + 2), key = card and tostring(i + 2) or nil})
	end
end

local bagButton = DarkUI.button(gui, "Bag  (I)", "stone", 16)
bagButton.AnchorPoint = Vector2.new(0, 1)
bagButton.Position = UDim2.new(0, 22 + 4 * 70 + 6, 1, -22)
bagButton.Size = UDim2.fromOffset(110, 64)
bagButton.Visible = false

local function setOpen(on)
	open = on and inv ~= nil
	back.Visible = open
	if open then selected = nil; render() else tip:hide() end
end
close.Activated:Connect(function() setOpen(false) end)
bagButton.Activated:Connect(function() setOpen(not open) end)
-- (a test hook: the Open attribute opens and shuts it)
gui:GetAttributeChangedSignal("Open"):Connect(function() setOpen(gui:GetAttribute("Open") == true) end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed and input.KeyCode ~= Enum.KeyCode.Escape then return end
	if UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.ButtonSelect then
		if inv then setOpen(not open) end
	elseif input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		if open then setOpen(false) elseif loot then closeLoot() end
	elseif input.KeyCode == Enum.KeyCode.Y and loot and lootPanel.Visible and not open then
		event:FireServer("TakeAll", loot.id)
	elseif inv then
		local i = table.find(BELT_KEYS, input.KeyCode)
		if i and inv.belt and inv.belt[i] then event:FireServer("Belt", i) end
	end
end)

event.OnClientEvent:Connect(function(kind, data)
	if kind == "Inv" then
		inv = data
		if not inv then setOpen(false); closeLoot() end
		if selected and inv then
			local found = false
			for _, c in ipairs(inv.bag or {}) do if c.uid == selected.uid then selected.card = c; found = true end end
			for i, c in ipairs(inv.belt or {}) do if c.uid == selected.uid then selected.card = c; selected.where = "belt" .. i; found = true end end
			for _, c in pairs(inv.equip or {}) do if c.uid == selected.uid then selected.card = c; selected.where = c.slot; found = true end end
			if not found then selected = nil end
		end
		lastBelt = "?"
		drawBelt()
		if open then render() end
	elseif kind == "Loot" then
		loot = data
		drawLoot()
	end
end)

-- walk away and the loot window closes; the mouse is free while either is up; the drinking bar
RunService:BindToRenderStep("RaidInventory", Enum.RenderPriority.Camera.Value + 22, function()
	local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min(vs.X / 1100, vs.Y / 720), 0.55, 1.15)
	local looting = loot ~= nil and lootPanel.Visible
	belt.Visible = inv ~= nil and not open
	bagButton.Visible = inv ~= nil and not open
	panel.Position = (open and looting) and UDim2.new(0.5, -190, 0.5, 0) or UDim2.fromScale(0.5, 0.5)
	lootPanel.Position = (open and looting) and UDim2.new(1, -16, 0.5, -200) or UDim2.new(1, -24, 0, 300)
	local c = player.Character
	if loot then
		local r = c and c:FindFirstChild("HumanoidRootPart")
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if not (r and h and h.Health > 0) or (typeof(loot.pos) == "Vector3" and (r.Position - loot.pos).Magnitude > 16) then closeLoot() end
	end
	local untilT = c and c:GetAttribute("DrinkingUntil") or 0
	local left2 = untilT - workspace:GetServerTimeNow()
	drinkBar.Visible = left2 > 0
	if left2 > 0 then drinkFill.Size = UDim2.fromScale(math.clamp(1 - left2, 0, 1), 1) end
	if open or looting then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)
