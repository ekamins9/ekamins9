--[[ LOADOUT MENU — pick an armor set and a weapon, then spawn. Built from
     Instances so there's nothing to paste besides this script. Lives in
     StarterPlayerScripts (not the character) so it survives death and
     opens again when the server says so.

     Layout:  [ ARMOR list ] [ WEAPON list ] [ armor stats / weapon stats / SPAWN ]

     Talks to LoadoutServer through ReplicatedStorage.LoadoutRemote
     ("Catalog") and ReplicatedStorage.LoadoutEvent ("Ready" / "Spawn" out,
     "Show" / "Spawned" in). ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("LoadoutRemote")
local event  = ReplicatedStorage:WaitForChild("LoadoutEvent")

--------------------------------------------------------------------
--  LOOK
--------------------------------------------------------------------
local FONT       = Enum.Font.GothamBold
local FONT_BODY  = Enum.Font.Gotham
local COL_BACK   = Color3.fromRGB(10, 9, 8)
local COL_PANEL  = Color3.fromRGB(24, 22, 20)
local COL_CARD   = Color3.fromRGB(38, 35, 31)
local COL_CARD_ON= Color3.fromRGB(96, 78, 46)
local COL_TEXT   = Color3.fromRGB(235, 228, 214)
local COL_DIM    = Color3.fromRGB(160, 150, 135)
local COL_ACCENT = Color3.fromRGB(196, 150, 70)
local COL_SPAWN  = Color3.fromRGB(120, 42, 34)
local COL_SPAWN_ON = Color3.fromRGB(170, 58, 44)
local TYPE_COL   = {
	Light  = Color3.fromRGB(96, 160, 96),
	Medium = Color3.fromRGB(190, 160, 70),
	Heavy  = Color3.fromRGB(180, 80, 70),
}

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "LoadoutMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = COL_BACK
backdrop.BackgroundTransparency = 0.25
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.86, 0, 0.8, 0)
panel.BackgroundColor3 = COL_PANEL
panel.BorderSizePixel = 0
panel.Parent = backdrop
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = COL_ACCENT
stroke.Thickness = 1.5
stroke.Transparency = 0.5
local pad = Instance.new("UIPadding", panel)
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 18), UDim.new(0, 18)
pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 14), UDim.new(0, 16)
local sizeCap = Instance.new("UISizeConstraint", panel)
sizeCap.MaxSize = Vector2.new(1300, 820)

local function label(parent, text, size, font, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = font or FONT_BODY
	t.TextSize = size or 16
	t.TextColor3 = color or COL_TEXT
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextWrapped = true
	t.Text = text or ""
	t.Parent = parent
	return t
end

local title = label(panel, "CHOOSE YOUR LOADOUT", 28, FONT, COL_ACCENT)
title.Size = UDim2.new(1, 0, 0, 34)
local subtitle = label(panel, "Pick an armor set and a weapon. You can change both every time you die.", 15, FONT_BODY, COL_DIM)
subtitle.Position = UDim2.new(0, 0, 0, 34)
subtitle.Size = UDim2.new(1, 0, 0, 20)

local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.new(0, 0, 0, 66)
body.Size = UDim2.new(1, 0, 1, -66)
body.Parent = panel
local bodyLayout = Instance.new("UIListLayout", body)
bodyLayout.FillDirection = Enum.FillDirection.Horizontal
bodyLayout.Padding = UDim.new(0, 14)
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function column(name, widthScale, order)
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(widthScale, -10, 1, 0)
	f.LayoutOrder = order
	f.Parent = body
	return f
end

local function listColumn(name, heading, order)
	local col = column(name, 0.3, order)
	local h = label(col, heading, 18, FONT, COL_TEXT)
	h.Size = UDim2.new(1, 0, 0, 26)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.Position = UDim2.new(0, 0, 0, 30)
	scroll.Size = UDim2.new(1, 0, 1, -30)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = COL_ACCENT
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = col
	local l = Instance.new("UIListLayout", scroll)
	l.Padding = UDim.new(0, 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	return scroll
end

local armorList  = listColumn("Armor",  "ARMOR",  1)
local weaponList = listColumn("Weapon", "WEAPON", 2)

-- right column: two stat boxes and the spawn button
local right = column("Details", 0.4, 3)
local rightLayout = Instance.new("UIListLayout", right)
rightLayout.Padding = UDim.new(0, 10)
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function statBox(order)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, 0, 0.5, -34)
	box.BackgroundColor3 = COL_CARD
	box.BorderSizePixel = 0
	box.LayoutOrder = order
	box.Parent = right
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
	local p = Instance.new("UIPadding", box)
	p.PaddingLeft, p.PaddingRight, p.PaddingTop, p.PaddingBottom = UDim.new(0, 12), UDim.new(0, 12), UDim.new(0, 10), UDim.new(0, 10)
	local name = label(box, "", 20, FONT, COL_TEXT)
	name.Size = UDim2.new(1, 0, 0, 26)
	local badge = label(box, "", 13, FONT, COL_ACCENT)
	badge.Size = UDim2.new(1, 0, 0, 16)
	badge.Position = UDim2.new(0, 0, 0, 26)
	local desc = label(box, "", 14, FONT_BODY, COL_DIM)
	desc.Position = UDim2.new(0, 0, 0, 46)
	desc.Size = UDim2.new(1, 0, 0, 58)
	desc.TextYAlignment = Enum.TextYAlignment.Top
	local stats = label(box, "", 15, FONT_BODY, COL_TEXT)
	stats.Position = UDim2.new(0, 0, 0, 108)
	stats.Size = UDim2.new(1, 0, 1, -108)
	stats.TextYAlignment = Enum.TextYAlignment.Top
	stats.RichText = true
	return {box = box, name = name, badge = badge, desc = desc, stats = stats}
end

local armorBox  = statBox(1)
local weaponBox = statBox(2)

local spawnBtn = Instance.new("TextButton")
spawnBtn.Name = "Spawn"
spawnBtn.Size = UDim2.new(1, 0, 0, 48)
spawnBtn.LayoutOrder = 3
spawnBtn.BackgroundColor3 = COL_SPAWN
spawnBtn.BorderSizePixel = 0
spawnBtn.Font = FONT
spawnBtn.TextSize = 22
spawnBtn.TextColor3 = COL_TEXT
spawnBtn.Text = "SPAWN"
spawnBtn.AutoButtonColor = false
spawnBtn.Parent = right
Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 8)

--------------------------------------------------------------------
--  FORMATTING
--------------------------------------------------------------------
local function pct(mult, up, down)
	-- 0.75 -> "25% slower", 1.1 -> "10% faster", 1 -> "normal"
	if math.abs(mult - 1) < 0.005 then return "normal" end
	local p = math.floor(math.abs(mult - 1) * 100 + 0.5)
	return string.format("%d%% %s", p, mult > 1 and up or down)
end

local function line(k, v)
	return string.format('<font color="#a09687">%s</font>  %s', k, v)
end

local function armorStats(a)
	local rows = {
		line("Class",      a.type or "Light"),
		line("Health",     a.health and a.health > 0 and ("+" .. a.health) or "no bonus"),
		line("Speed",      pct(a.speedMult or 1, "faster", "slower")),
		line("Footsteps",  pct(a.clunkMult or 1, "heavier", "lighter")),
		line("Protection", string.format("%d%% less damage on covered limbs", math.floor((a.protection or 0) * 100 + 0.5))),
	}
	return table.concat(rows, "\n")
end

local function weaponStats(w)
	local dmg = "?"
	if w.damageMin and w.damageMax then
		dmg = w.damageMin == w.damageMax and tostring(w.damageMin) or (w.damageMin .. " – " .. w.damageMax)
	end
	local kinds = {}
	if w.slash then table.insert(kinds, "slash") end
	if w.stab  then table.insert(kinds, "stab")  end
	local rows = {
		line("Damage",  dmg .. (w.damageMax and "  (head ×2)" or "")),
		line("Reach",   w.reach and string.format("%.0f studs", w.reach) or "?"),
		line("Tempo",   pct(w.speedMult or 1, "faster", "slower")),
		line("Grip",    w.twoHanded and "two-handed (needs both arms)" or "one-handed"),
		line("Weight",  pct(w.weightSpeed or 1, "faster", "slower") .. " on foot"),
		line("Attacks", #kinds > 0 and table.concat(kinds, " + ") or "?"),
	}
	return table.concat(rows, "\n")
end

--------------------------------------------------------------------
--  STATE
--------------------------------------------------------------------
local catalogData
local selected = {armor = nil, weapon = nil}
local cards    = {armor = {}, weapon = {}}   -- [id] = TextButton
local open     = false

local function paintCards(kind)
	for id, card in pairs(cards[kind]) do
		local on = selected[kind] == id
		TweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = on and COL_CARD_ON or COL_CARD}):Play()
		card.Stroke.Transparency = on and 0 or 1
	end
end

local function refreshDetails()
	local a = catalogData and catalogData.byArmor[selected.armor]
	local w = catalogData and catalogData.byWeapon[selected.weapon]
	armorBox.name.Text  = a and a.name or "No armor"
	armorBox.badge.Text = a and string.upper(a.type or "") or ""
	armorBox.badge.TextColor3 = a and (TYPE_COL[a.type] or COL_ACCENT) or COL_ACCENT
	armorBox.desc.Text  = a and a.description or "Pick a set on the left."
	armorBox.stats.Text = a and armorStats(a) or ""
	weaponBox.name.Text  = w and w.name or "No weapon"
	weaponBox.badge.Text = w and (w.twoHanded and "TWO-HANDED" or "ONE-HANDED") or ""
	weaponBox.badge.TextColor3 = COL_ACCENT
	weaponBox.desc.Text  = w and w.description or "Pick a weapon in the middle."
	weaponBox.stats.Text = w and weaponStats(w) or ""
	local ready = (a ~= nil or #catalogData.armors == 0) and (w ~= nil or #catalogData.weapons == 0)
	spawnBtn.BackgroundColor3 = ready and COL_SPAWN_ON or COL_SPAWN
	spawnBtn.TextTransparency = ready and 0 or 0.4
end

local function choose(kind, id)
	selected[kind] = id
	paintCards(kind)
	refreshDetails()
end

local function makeCard(list, kind, item, order)
	local card = Instance.new("TextButton")
	card.Name = item.id
	card.Size = UDim2.new(1, -6, 0, 54)
	card.LayoutOrder = order
	card.BackgroundColor3 = COL_CARD
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.Text = ""
	card.Parent = list
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
	local s = Instance.new("UIStroke", card)
	s.Name = "Stroke"
	s.Color = COL_ACCENT
	s.Thickness = 1.5
	s.Transparency = 1
	local p = Instance.new("UIPadding", card)
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	local n = label(card, item.name, 17, FONT, COL_TEXT)
	n.Size = UDim2.new(1, 0, 0, 30)
	n.Position = UDim2.new(0, 0, 0, 4)
	local tag = label(card, "", 12, FONT, COL_DIM)
	tag.Size = UDim2.new(1, 0, 0, 16)
	tag.Position = UDim2.new(0, 0, 0, 32)
	if kind == "armor" then
		tag.Text = string.upper(item.type or "")
		tag.TextColor3 = TYPE_COL[item.type] or COL_DIM
	else
		local bits = {}
		if item.damageMax then table.insert(bits, "dmg " .. item.damageMin .. "–" .. item.damageMax) end
		if item.reach then table.insert(bits, string.format("reach %.0f", item.reach)) end
		table.insert(bits, item.twoHanded and "2H" or "1H")
		tag.Text = table.concat(bits, "   ")
	end
	card.MouseEnter:Connect(function() if selected[kind] ~= item.id then card.BackgroundColor3 = COL_CARD:Lerp(COL_CARD_ON, 0.35) end end)
	card.MouseLeave:Connect(function() if selected[kind] ~= item.id then card.BackgroundColor3 = COL_CARD end end)
	card.Activated:Connect(function() choose(kind, item.id) end)
	cards[kind][item.id] = card
	return card
end

local function populate(data)
	for _, c in pairs(cards.armor)  do c:Destroy() end
	for _, c in pairs(cards.weapon) do c:Destroy() end
	cards = {armor = {}, weapon = {}}
	data.byArmor, data.byWeapon = {}, {}
	for i, a in ipairs(data.armors)  do data.byArmor[a.id]  = a; makeCard(armorList,  "armor",  a, i) end
	for i, w in ipairs(data.weapons) do data.byWeapon[w.id] = w; makeCard(weaponList, "weapon", w, i) end
	if #data.armors == 0 then
		local t = label(armorList, "No armor sets in ServerStorage.Armor", 14, FONT_BODY, COL_DIM)
		t.Size = UDim2.new(1, 0, 0, 40)
	end
	if #data.weapons == 0 then
		local t = label(weaponList, "No weapons in ServerStorage.Weapons", 14, FONT_BODY, COL_DIM)
		t.Size = UDim2.new(1, 0, 0, 40)
	end
	catalogData = data
end

local function fetchCatalog()
	local ok, data = pcall(remote.InvokeServer, remote, "Catalog")
	if ok and type(data) == "table" then
		populate(data)
	else
		warn("[LoadoutMenu] could not fetch catalog:", data)
		populate({armors = {}, weapons = {}})
	end
end

--------------------------------------------------------------------
--  OPEN / CLOSE
--------------------------------------------------------------------
local mouseConn

local function show(last)
	fetchCatalog()   -- fresh every time, so sets added while testing appear
	-- preselect: last choice, else the first of each list
	selected.armor  = (last and catalogData.byArmor[last.armor])   and last.armor  or (catalogData.armors[1]  and catalogData.armors[1].id)
	selected.weapon = (last and catalogData.byWeapon[last.weapon]) and last.weapon or (catalogData.weapons[1] and catalogData.weapons[1].id)
	paintCards("armor"); paintCards("weapon")
	refreshDetails()
	spawnBtn.Text = "SPAWN"
	open = true
	gui.Enabled = true
	panel.Position = UDim2.fromScale(0.5, 0.53)
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
	-- CameraRig re-locks the mouse every frame while it runs; win that fight while the menu is up
	if mouseConn then mouseConn:Disconnect() end
	mouseConn = RunService.RenderStepped:Connect(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)
end

local function hide()
	open = false
	gui.Enabled = false
	if mouseConn then mouseConn:Disconnect(); mouseConn = nil end
end

spawnBtn.Activated:Connect(function()
	if not open or not catalogData then return end
	local a = catalogData.byArmor[selected.armor]
	local w = catalogData.byWeapon[selected.weapon]
	if (#catalogData.armors > 0 and not a) or (#catalogData.weapons > 0 and not w) then return end
	spawnBtn.Text = "SPAWNING…"
	event:FireServer("Spawn", a and a.id or nil, w and w.id or nil)
end)

event.OnClientEvent:Connect(function(what, last)
	if what == "Show" then
		show(last)
	elseif what == "Spawned" then
		hide()
	end
end)

-- tell the server we're listening; it answers "Show" if we have no body yet
event:FireServer("Ready")
