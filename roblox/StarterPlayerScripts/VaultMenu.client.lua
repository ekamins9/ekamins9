--[[ VAULT MENU — Deadvault's vault (Game ▸ Vault): what you've brought out of the raids.
     Opened from PLAY ▸ ADVENTURES ▸ DEADVAULT (HubMenu calls _G.OpenVault).

       YOUR KIT    what you'll take in: a weapon, a sidearm, armour, three relics, three potions
                   (no kit: you go in with your class's plain weapon, and nothing to lose)
       THE STASH   everything else you've got out with (STASH_MAX)
       an item     EQUIP (stash → kit) · TAKE OFF (kit → stash) · SELL (for vault gold)
       MERCHANT    potions, plain armour, a plain or fine weapon for your class, for gold
       ENTER THE RAID

     The server decides everything (ReplicatedStorage ▸ VaultRemote: Hub ▸ VaultServer). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local remote = ReplicatedStorage:WaitForChild("VaultRemote")

local FONT, TITLE, BODY = Theme.FONT, Theme.FONT_TITLE, Theme.FONT_BODY
local RARITY_COLOR = {}
for _, r in ipairs(Catalog.LOOT and Catalog.LOOT.RARITIES or {}) do RARITY_COLOR[r.id] = r.color end

local gui = Instance.new("ScreenGui")
gui.Name = "Vault"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2100   -- (over the menu it was opened from: HubMenu 2050; its toasts 2200 over this)
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

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
local function stroke(f, color, th)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness = color, th or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
end

local back = frame(gui, Color3.new(0, 0, 0), 0.4)
back.Size = UDim2.fromScale(1, 1)
back.Active = true
local panel = frame(back, Theme.PANEL, 0.04, 18)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(960, 600)
stroke(panel, Color3.fromRGB(90, 140, 255), 2)

local head = text(panel, "YOUR VAULT", 34, Theme.TEXT, TITLE)
head.Position = UDim2.fromOffset(24, 14); head.Size = UDim2.fromOffset(400, 40); head.TextXAlignment = Enum.TextXAlignment.Left
local sub = text(panel, "", 14, Theme.DIM, FONT)
sub.Position = UDim2.fromOffset(26, 54); sub.Size = UDim2.fromOffset(560, 18); sub.TextXAlignment = Enum.TextXAlignment.Left
local goldLabel = text(panel, "", 24, Theme.MARKS, TITLE)
goldLabel.AnchorPoint = Vector2.new(1, 0); goldLabel.Position = UDim2.new(1, -80, 0, 18); goldLabel.Size = UDim2.fromOffset(220, 32)
goldLabel.TextXAlignment = Enum.TextXAlignment.Right
local close = button(panel, "X", Theme.RED, 22)
close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -16, 0, 16); close.Size = UDim2.fromOffset(44, 44)

-- the kit (left)
local kitBox = frame(panel, Theme.GLASS2, 0.1, 14)
kitBox.Position = UDim2.fromOffset(20, 84); kitBox.Size = UDim2.fromOffset(300, 330)
local kitTitle = text(kitBox, "YOUR KIT  ·  WHAT YOU RISK", 13, Theme.DIM, FONT)
kitTitle.Position = UDim2.fromOffset(12, 8); kitTitle.Size = UDim2.new(1, -24, 0, 16); kitTitle.TextXAlignment = Enum.TextXAlignment.Left
local KIT_SLOTS = {
	{key = "weapon1", label = "WEAPON", x = 12, y = 32, w = 134}, {key = "weapon2", label = "SIDEARM", x = 154, y = 32, w = 134},
	{key = "armor", label = "ARMOUR", x = 12, y = 112, w = 276},
	{key = "relic1", label = "RELIC", x = 12, y = 192, w = 88}, {key = "relic2", label = "RELIC", x = 106, y = 192, w = 88}, {key = "relic3", label = "RELIC", x = 200, y = 192, w = 88},
	{key = "potion1", label = "POTION", x = 12, y = 260, w = 88}, {key = "potion2", label = "POTION", x = 106, y = 260, w = 88}, {key = "potion3", label = "POTION", x = 200, y = 260, w = 88},
}

-- the stash (right)
local stashBox = frame(panel, Theme.GLASS2, 0.1, 14)
stashBox.Position = UDim2.fromOffset(332, 84); stashBox.Size = UDim2.fromOffset(608, 330)
local stashTitle = text(stashBox, "THE STASH", 13, Theme.DIM, FONT)
stashTitle.Position = UDim2.fromOffset(12, 8); stashTitle.Size = UDim2.new(1, -24, 0, 16); stashTitle.TextXAlignment = Enum.TextXAlignment.Left
local grid = Instance.new("ScrollingFrame")
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.Position = UDim2.fromOffset(10, 30); grid.Size = UDim2.new(1, -20, 1, -40)
grid.CanvasSize = UDim2.new(); grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ScrollBarThickness = 6
grid.Parent = stashBox
local gl = Instance.new("UIGridLayout")
gl.CellSize = UDim2.fromOffset(110, 70); gl.CellPadding = UDim2.fromOffset(8, 8)
gl.Parent = grid

-- the detail (bottom left) and the merchant (bottom right)
local detail = frame(panel, Theme.GLASS2, 0.1, 14)
detail.Position = UDim2.fromOffset(20, 426); detail.Size = UDim2.fromOffset(500, 154)
local dName = text(detail, "Pick something", 20, Theme.TEXT, TITLE)
dName.Position = UDim2.fromOffset(14, 8); dName.Size = UDim2.new(1, -28, 0, 26); dName.TextXAlignment = Enum.TextXAlignment.Left
local dSub = text(detail, "", 13, Theme.DIM, FONT)
dSub.Position = UDim2.fromOffset(14, 34); dSub.Size = UDim2.new(1, -28, 0, 16); dSub.TextXAlignment = Enum.TextXAlignment.Left
local dLines = text(detail, "", 13, Color3.fromRGB(226, 232, 246), BODY)
dLines.Position = UDim2.fromOffset(14, 54); dLines.Size = UDim2.new(1, -170, 0, 90)
dLines.TextWrapped = true; dLines.TextXAlignment = Enum.TextXAlignment.Left; dLines.TextYAlignment = Enum.TextYAlignment.Top
local act1 = button(detail, "EQUIP", Theme.GREEN, 15)
act1.AnchorPoint = Vector2.new(1, 0); act1.Position = UDim2.new(1, -12, 0, 54); act1.Size = UDim2.fromOffset(140, 38); act1.Visible = false
local act2 = button(detail, "SELL", Theme.GOLD, 15)
act2.AnchorPoint = Vector2.new(1, 0); act2.Position = UDim2.new(1, -12, 0, 100); act2.Size = UDim2.fromOffset(140, 38); act2.Visible = false

local shopBox = frame(panel, Theme.GLASS2, 0.1, 14)
shopBox.Position = UDim2.fromOffset(532, 426); shopBox.Size = UDim2.fromOffset(408, 100)
local shopTitle = text(shopBox, "THE MERCHANT", 13, Theme.DIM, FONT)
shopTitle.Position = UDim2.fromOffset(12, 6); shopTitle.Size = UDim2.new(1, -24, 0, 16); shopTitle.TextXAlignment = Enum.TextXAlignment.Left
local shopRow = Instance.new("Frame")
shopRow.BackgroundTransparency = 1
shopRow.Position = UDim2.fromOffset(10, 26); shopRow.Size = UDim2.new(1, -20, 1, -32)
shopRow.Parent = shopBox
local sgl = Instance.new("UIGridLayout")
sgl.CellSize = UDim2.fromOffset(126, 30); sgl.CellPadding = UDim2.fromOffset(6, 6)
sgl.Parent = shopRow

local enter = button(panel, "ENTER THE RAID", Theme.GREEN, 20)
enter.Position = UDim2.fromOffset(532, 534); enter.Size = UDim2.fromOffset(408, 46)
local toast = text(panel, "", 14, Theme.ACCENT, FONT)
toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, 18); toast.Size = UDim2.fromOffset(600, 18)

--------------------------------------------------------------------
local view, selected = nil, nil
local function say(msg, good)
	toast.Text = msg or ""
	toast.TextColor3 = good == false and Theme.BAD or Theme.ACCENT
	task.delay(2.5, function() if toast.Text == msg then toast.Text = "" end end)
end

local function itemTile(parent, c, onClick, h)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Text = ""
	b.BackgroundColor3 = Theme.GLASS
	b.BackgroundTransparency = 0.05
	b.Size = UDim2.new(1, 0, 0, h or 70)
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = b
	local st = stroke(b, c and (RARITY_COLOR[c.rarity] or Theme.STROKE) or Color3.fromRGB(70, 76, 100), (selected and c and selected.uid == c.uid) and 3 or 1.5)
	if c then
		local g = text(b, c.glyph or "💎", 24, Theme.TEXT, FONT)
		g.Position = UDim2.fromOffset(6, 4); g.Size = UDim2.fromOffset(30, 30); g.TextStrokeTransparency = 1
		local n = text(b, c.name or "", 12, Theme.TEXT, FONT)
		n.Position = UDim2.fromOffset(6, 34); n.Size = UDim2.new(1, -12, 0, 30)
		n.TextWrapped = true; n.TextXAlignment = Enum.TextXAlignment.Left; n.TextYAlignment = Enum.TextYAlignment.Top
		local r = text(b, string.upper(c.rarity or ""), 10, RARITY_COLOR[c.rarity] or Theme.DIM, FONT)
		r.AnchorPoint = Vector2.new(1, 0); r.Position = UDim2.new(1, -6, 0, 6); r.Size = UDim2.fromOffset(80, 12); r.TextXAlignment = Enum.TextXAlignment.Right
	end
	b.Activated:Connect(function() onClick(c) end)
	b.Parent = parent
	return b
end

local render
local function pick(c, where)
	selected = c and {uid = c.uid, where = where, card = c} or nil
	render()
end
local function call(kind, arg)
	local ok, res = pcall(function() return remote:InvokeServer(kind, arg) end)
	if not ok or type(res) ~= "table" then say("The vault didn't answer", false); return end
	if res.msg then say(res.msg, res.ok) end
	if res.view then view = res.view end
	if kind ~= "View" then selected = nil end
	render()
end

render = function()
	if not view then return end
	goldLabel.Text = "💰 " .. tostring(view.gold or 0)
	sub.Text = string.format("%d RAIDS  ·  %d TIMES OUT ALIVE  ·  RAIDING AS A %s", view.raids or 0, view.out or 0, string.upper(view.class or ""))
	stashTitle.Text = string.format("THE STASH  ·  %d / %d", #(view.stash or {}), view.max or 30)
	-- the kit
	for _, c in ipairs(kitBox:GetChildren()) do if c:IsA("GuiObject") and c ~= kitTitle then c:Destroy() end end
	local bySlot = {}
	for _, c in ipairs(view.kit or {}) do bySlot[c.slot] = c end
	for _, s in ipairs(KIT_SLOTS) do
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Position = UDim2.fromOffset(s.x, s.y); holder.Size = UDim2.fromOffset(s.w, 64)
		holder.Parent = kitBox
		local c = bySlot[s.key]
		local t = itemTile(holder, c, function(card) if card then pick(card, "kit") end end, 64)
		if not c then
			local l = text(t, s.label, 11, Theme.DIM, FONT)
			l.Size = UDim2.fromScale(1, 1)
		end
	end
	-- the stash
	for _, c in ipairs(grid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for _, c in ipairs(view.stash or {}) do itemTile(grid, c, function(card) pick(card, "stash") end) end
	-- the merchant
	for _, c in ipairs(shopRow:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for _, s in ipairs(view.shop or {}) do
		local b = button(shopRow, string.format("%s  ·  %d", s.name:gsub("A plain weapon for your class", "Plain weapon"):gsub("A fine weapon for your class", "Fine weapon"), s.price), Theme.CARD, 11)
		b.Activated:Connect(function() call("Buy", s.id) end)
	end
	-- the detail
	local sel = selected and selected.card
	if sel then
		dName.Text = sel.name or ""
		dName.TextColor3 = RARITY_COLOR[sel.rarity] or Theme.TEXT
		dSub.Text = (sel.sub or "") .. (sel.value and ("  ·  worth " .. sel.value .. " gold") or "")
		dLines.Text = table.concat(sel.lines or {}, "\n")
		act1.Visible = true
		act1.Text = selected.where == "kit" and "TAKE OFF" or "EQUIP"
		act1.BackgroundColor3 = selected.where == "kit" and Theme.BLUE or Theme.GREEN
		act2.Visible = selected.where == "stash"
		act2.Text = "SELL  ·  " .. tostring(sel.value or 0)
	else
		dName.Text = "Pick something"
		dName.TextColor3 = Theme.TEXT
		dSub.Text = "Your kit is what you take in, and what you can lose. No kit: your class's plain weapon."
		dLines.Text = "Everything you get out with lands in the stash. Sell what you don't need to the merchant."
		act1.Visible, act2.Visible = false, false
	end
end
act1.Activated:Connect(function()
	if not selected then return end
	call(selected.where == "kit" and "Unequip" or "Equip", selected.uid)
end)
act2.Activated:Connect(function()
	if selected and selected.where == "stash" then call("Sell", selected.uid) end
end)

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
UserInputService.InputBegan:Connect(function(input)
	if gui.Enabled and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then setOpen(false) end
end)
RunService:BindToRenderStep("VaultMouse", Enum.RenderPriority.Camera.Value + 21, function()
	if gui.Enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)
