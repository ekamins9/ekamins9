--[[ LOADOUT MENU — pick an armor set, a primary weapon and (optionally) a
     secondary, then spawn. Built from Instances so there's nothing to paste
     besides this script. Lives in StarterPlayerScripts (not the character)
     so it survives death and opens again when the server says so.

     Layout:  [ ARMOR ] [ PRIMARY / SECONDARY ] [ armor stats / weapon stats / SPAWN ]
              ⚙ (top right) opens SETTINGS: camera feel sliders + keybinds,
              backed by ReplicatedStorage.ClientSettings (saved per player).

     Talks to LoadoutServer through ReplicatedStorage.LoadoutRemote
     ("Catalog") and ReplicatedStorage.LoadoutEvent ("Ready" / "Spawn" out,
     "Show" / "Spawned" in). ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("LoadoutRemote")
local event  = ReplicatedStorage:WaitForChild("LoadoutEvent")

ClientSettings.load()

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
gui.DisplayOrder = 2000   -- above CameraRig's DeathFade (1000)
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
panel.Size = UDim2.new(0.88, 0, 0.82, 0)
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
sizeCap.MaxSize = Vector2.new(1400, 860)

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

local function button(parent, text, size, color)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = color or COL_CARD
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = FONT
	b.TextSize = size or 16
	b.TextColor3 = COL_TEXT
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local title = label(panel, "CHOOSE YOUR LOADOUT", 28, FONT, COL_ACCENT)
title.Size = UDim2.new(1, -130, 0, 34)
local subtitle = label(panel, "Armor, a primary weapon and an optional secondary. You can change them every time you die.", 15, FONT_BODY, COL_DIM)
subtitle.Position = UDim2.new(0, 0, 0, 34)
subtitle.Size = UDim2.new(1, -130, 0, 20)

-- ⚙ settings
local cog = button(panel, "SETTINGS", 15, COL_CARD)
cog.Name = "Settings"
cog.AnchorPoint = Vector2.new(1, 0)
cog.Position = UDim2.new(1, 0, 0, 0)
cog.Size = UDim2.fromOffset(120, 40)

local body = Instance.new("Frame")
body.Name = "Body"
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

local function scrollList(parent, heading, y, h)
	local hl = label(parent, heading, 18, FONT, COL_TEXT)
	hl.Position = UDim2.new(0, 0, y, 0)
	hl.Size = UDim2.new(1, 0, 0, 26)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = heading
	scroll.Position = UDim2.new(0, 0, y, 30)
	scroll.Size = UDim2.new(1, 0, h, -34)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = COL_ACCENT
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = parent
	local l = Instance.new("UIListLayout", scroll)
	l.Padding = UDim.new(0, 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	return scroll
end

local armorCol  = column("Armor", 0.28, 1)
local armorList = scrollList(armorCol, "ARMOR", 0, 1)
local weaponCol   = column("Weapons", 0.32, 2)
local primaryList = scrollList(weaponCol, "PRIMARY", 0, 0.58)
local secondList  = scrollList(weaponCol, "SECONDARY", 0.6, 0.4)

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

local spawnBtn = button(right, "SPAWN", 22, COL_SPAWN)
spawnBtn.Name = "Spawn"
spawnBtn.Size = UDim2.new(1, 0, 0, 48)
spawnBtn.LayoutOrder = 3
spawnBtn.AutoButtonColor = false
local loadoutLine = label(right, "", 13, FONT_BODY, COL_DIM)
loadoutLine.Size = UDim2.new(1, 0, 0, 18)
loadoutLine.LayoutOrder = 4
loadoutLine.TextXAlignment = Enum.TextXAlignment.Center

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
		line("Slot",    w.secondary and "primary or secondary" or "primary only"),
	}
	return table.concat(rows, "\n")
end

--------------------------------------------------------------------
--  STATE
--------------------------------------------------------------------
local NONE = "__none"
local catalogData
local selected = {armor = nil, weapon = nil, secondary = NONE}
local lastWeaponKind = "weapon"       -- which weapon card the stats box shows
local cards    = {armor = {}, weapon = {}, secondary = {}}   -- [id] = TextButton
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
	local sec = catalogData and catalogData.byWeapon[selected.secondary]
	local shown = lastWeaponKind == "secondary" and sec or w
	armorBox.name.Text  = a and a.name or "No armor"
	armorBox.badge.Text = a and string.upper(a.type or "") or ""
	armorBox.badge.TextColor3 = a and (TYPE_COL[a.type] or COL_ACCENT) or COL_ACCENT
	armorBox.desc.Text  = a and a.description or "Pick a set on the left."
	armorBox.stats.Text = a and armorStats(a) or ""
	weaponBox.name.Text  = shown and shown.name or (lastWeaponKind == "secondary" and "No secondary" or "No weapon")
	weaponBox.badge.Text = shown and ((lastWeaponKind == "secondary" and "SECONDARY  ·  " or "PRIMARY  ·  ") .. (shown.twoHanded and "TWO-HANDED" or "ONE-HANDED")) or ""
	weaponBox.badge.TextColor3 = COL_ACCENT
	weaponBox.desc.Text  = shown and shown.description or "Pick a weapon in the middle."
	weaponBox.stats.Text = shown and weaponStats(shown) or ""
	local ready = (a ~= nil or #catalogData.armors == 0) and (w ~= nil or #catalogData.weapons == 0)
	spawnBtn.BackgroundColor3 = ready and COL_SPAWN_ON or COL_SPAWN
	spawnBtn.TextTransparency = ready and 0 or 0.4
	loadoutLine.Text = string.format("%s  ·  %s%s", a and a.name or "no armor", w and w.name or "no weapon",
		sec and ("  +  " .. sec.name) or "")
end

local function choose(kind, id)
	if kind == "secondary" and id ~= NONE and id == selected.weapon then
		-- the same weapon can't fill both hands; swap the primary out
		selected.weapon = nil
		paintCards("weapon")
	elseif kind == "weapon" and id == selected.secondary then
		selected.secondary = NONE
		paintCards("secondary")
	end
	selected[kind] = id
	if kind ~= "armor" then lastWeaponKind = kind end
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
	elseif item.id == NONE then
		tag.Text = "travel light"
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
	for _, kind in ipairs({"armor", "weapon", "secondary"}) do
		for _, c in pairs(cards[kind]) do c:Destroy() end
	end
	for _, l in ipairs({armorList, primaryList, secondList}) do
		for _, c in ipairs(l:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
	end
	cards = {armor = {}, weapon = {}, secondary = {}}
	data.byArmor, data.byWeapon = {}, {}
	for i, a in ipairs(data.armors)  do data.byArmor[a.id]  = a; makeCard(armorList,  "armor",  a, i) end
	for i, w in ipairs(data.weapons) do data.byWeapon[w.id] = w; makeCard(primaryList, "weapon", w, i) end
	makeCard(secondList, "secondary", {id = NONE, name = "None"}, 0)
	local n = 0
	for i, w in ipairs(data.weapons) do
		if w.secondary then n += 1; makeCard(secondList, "secondary", w, i) end
	end
	if #data.armors == 0 then
		local t = label(armorList, "No armor sets in ServerStorage.Armor", 14, FONT_BODY, COL_DIM)
		t.Size = UDim2.new(1, 0, 0, 40)
	end
	if #data.weapons == 0 then
		local t = label(primaryList, "No weapons in ServerStorage.Weapons", 14, FONT_BODY, COL_DIM)
		t.Size = UDim2.new(1, 0, 0, 40)
	end
	if n == 0 then
		local t = label(secondList, "No weapon has SECONDARY = true in its Config yet", 13, FONT_BODY, COL_DIM)
		t.Size = UDim2.new(1, 0, 0, 40)
		t.LayoutOrder = 99
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
--  SETTINGS PANEL (covers the body while open)
--------------------------------------------------------------------
local settings = Instance.new("Frame")
settings.Name = "SettingsPanel"
settings.BackgroundColor3 = COL_PANEL
settings.BorderSizePixel = 0
settings.Position = UDim2.new(0, 0, 0, 66)
settings.Size = UDim2.new(1, 0, 1, -66)
settings.Visible = false
settings.Parent = panel

local sTitle = label(settings, "SETTINGS", 22, FONT, COL_ACCENT)
sTitle.Size = UDim2.new(1, 0, 0, 30)
local sHint = label(settings, "Camera feel is a multiplier on the tuned default (1.0). Set anything to 0 to turn it off. Block is always right mouse, left click cycles attacks.", 13, FONT_BODY, COL_DIM)
sHint.Position = UDim2.new(0, 0, 0, 30)
sHint.Size = UDim2.new(1, -200, 0, 32)

local backBtn = button(settings, "◀  BACK", 15, COL_CARD)
backBtn.AnchorPoint = Vector2.new(1, 0)
backBtn.Position = UDim2.new(1, 0, 0, 0)
backBtn.Size = UDim2.fromOffset(110, 34)
local resetBtn = button(settings, "RESET DEFAULTS", 13, COL_CARD)
resetBtn.AnchorPoint = Vector2.new(1, 0)
resetBtn.Position = UDim2.new(1, -120, 0, 0)
resetBtn.Size = UDim2.fromOffset(140, 34)

local sBody = Instance.new("Frame")
sBody.BackgroundTransparency = 1
sBody.Position = UDim2.new(0, 0, 0, 70)
sBody.Size = UDim2.new(1, 0, 1, -70)
sBody.Parent = settings
local sLayout = Instance.new("UIListLayout", sBody)
sLayout.FillDirection = Enum.FillDirection.Horizontal
sLayout.Padding = UDim.new(0, 24)

local function settingsColumn(heading, widthScale)
	local col = Instance.new("Frame")
	col.BackgroundTransparency = 1
	col.Size = UDim2.new(widthScale, -12, 1, 0)
	col.Parent = sBody
	local h = label(col, heading, 17, FONT, COL_TEXT)
	h.Size = UDim2.new(1, 0, 0, 26)
	local scroll = Instance.new("ScrollingFrame")
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
	l.Padding = UDim.new(0, 10)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	return scroll
end

local camCol = settingsColumn("CAMERA FEEL", 0.55)
local keyCol = settingsColumn("KEYBINDS", 0.45)

-- a slider row: label + value on top, a draggable track under it
local sliderRefresh = {}
local function sliderRow(spec, order)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -8, 0, 52)
	row.LayoutOrder = order
	row.Parent = camCol
	local name = label(row, spec.label, 15, FONT, COL_TEXT)
	name.Size = UDim2.new(0.7, 0, 0, 20)
	local val = label(row, "", 15, FONT, COL_ACCENT)
	val.AnchorPoint = Vector2.new(1, 0)
	val.Position = UDim2.new(1, 0, 0, 0)
	val.Size = UDim2.new(0.3, 0, 0, 20)
	val.TextXAlignment = Enum.TextXAlignment.Right
	local hint = label(row, spec.hint or "", 12, FONT_BODY, COL_DIM)
	hint.Position = UDim2.new(0, 0, 0, 20)
	hint.Size = UDim2.new(1, 0, 0, 14)
	local track = Instance.new("TextButton")
	track.Text = ""
	track.AutoButtonColor = false
	track.Position = UDim2.new(0, 0, 0, 40)
	track.Size = UDim2.new(1, 0, 0, 10)
	track.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	track.BackgroundTransparency = 0.5
	track.BorderSizePixel = 0
	track.Parent = row
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 5)
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = COL_ACCENT
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0.5, 1)
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)
	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(18, 18)
	knob.Position = UDim2.new(0.5, 0, 0.5, 0)
	knob.BackgroundColor3 = COL_TEXT
	knob.BorderSizePixel = 0
	knob.Parent = track
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local function refresh()
		local v = ClientSettings.get(spec.key)
		local f = (v - spec.min) / (spec.max - spec.min)
		fill.Size = UDim2.fromScale(f, 1)
		knob.Position = UDim2.new(f, 0, 0.5, 0)
		val.Text = spec.step and string.format("%d", v) or string.format("%d%%", math.floor(v * 100 + 0.5))
	end
	sliderRefresh[spec.key] = refresh
	refresh()

	local dragging = false
	local function setFromX(x)
		local f = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		ClientSettings.set(spec.key, spec.min + f * (spec.max - spec.min))
		refresh()
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end
for i, spec in ipairs(ClientSettings.SLIDERS) do sliderRow(spec, i) end

-- a keybind row: label + a button showing the key; click, then press the new key
local keyRefresh = {}
local listening = nil   -- {key=, btn=}
local function keyRow(spec, order)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -8, 0, 34)
	row.LayoutOrder = order
	row.Parent = keyCol
	local name = label(row, spec.label, 15, FONT_BODY, COL_TEXT)
	name.Size = UDim2.new(0.55, 0, 1, 0)
	local btn = button(row, "", 14, COL_CARD)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, 0, 0.5, 0)
	btn.Size = UDim2.new(0.42, 0, 0, 30)
	local function refresh()
		if listening and listening.key == spec.key then
			btn.Text = "press a key…"
			btn.TextColor3 = COL_ACCENT
		else
			btn.Text = ClientSettings.get("Key_" .. spec.key)
			btn.TextColor3 = COL_TEXT
		end
	end
	keyRefresh[spec.key] = refresh
	refresh()
	btn.Activated:Connect(function()
		listening = {key = spec.key}
		for _, r in pairs(keyRefresh) do r() end
	end)
end
for i, spec in ipairs(ClientSettings.KEYS) do keyRow(spec, i) end

UserInputService.InputBegan:Connect(function(input, gp)
	if not listening or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local kc = input.KeyCode
	if kc ~= Enum.KeyCode.Escape and kc ~= Enum.KeyCode.Unknown then
		-- steal the key from whatever else had it, so two actions never share one
		for _, k in ipairs(ClientSettings.KEYS) do
			if k.key ~= listening.key and ClientSettings.get("Key_" .. k.key) == kc.Name then
				ClientSettings.set("Key_" .. k.key, ClientSettings.get("Key_" .. listening.key))
			end
		end
		ClientSettings.set("Key_" .. listening.key, kc.Name)
	end
	listening = nil
	for _, r in pairs(keyRefresh) do r() end
end)

local function refreshSettingsUI()
	for _, r in pairs(sliderRefresh) do r() end
	for _, r in pairs(keyRefresh) do r() end
end
ClientSettings.onChanged(function() refreshSettingsUI() end)

local function showSettings(on)
	settings.Visible = on
	body.Visible = not on
	if on then refreshSettingsUI() else listening = nil end
end
cog.Activated:Connect(function() showSettings(not settings.Visible) end)
backBtn.Activated:Connect(function() showSettings(false) end)
resetBtn.Activated:Connect(function() ClientSettings.reset(); refreshSettingsUI() end)

--------------------------------------------------------------------
--  OPEN / CLOSE
--------------------------------------------------------------------
local mouseConn

-- CameraRig fades to black when we die and, with no auto-respawn, nothing
-- ever clears it: lift it here so the menu opens over the (Custom) camera
local function clearDeathFade()
	local pg = player:FindFirstChild("PlayerGui")
	local fade = pg and pg:FindFirstChild("DeathFade")
	pcall(RunService.UnbindFromRenderStep, RunService, "DeathCam")
	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Custom
		cam.FieldOfView = 70
	end
	if fade then
		local black = fade:FindFirstChildOfClass("Frame")
		if black then TweenService:Create(black, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play() end
		task.delay(0.7, function() if fade.Parent then fade:Destroy() end end)
	end
end

local function show(last)
	clearDeathFade()
	fetchCatalog()   -- fresh every time, so sets added while testing appear
	-- preselect: last choice, else the first of each list
	selected.armor  = (last and catalogData.byArmor[last.armor])   and last.armor  or (catalogData.armors[1]  and catalogData.armors[1].id)
	selected.weapon = (last and catalogData.byWeapon[last.weapon]) and last.weapon or (catalogData.weapons[1] and catalogData.weapons[1].id)
	selected.secondary = (last and last.secondary and cards.secondary[last.secondary]) and last.secondary or NONE
	lastWeaponKind = "weapon"
	paintCards("armor"); paintCards("weapon"); paintCards("secondary")
	refreshDetails()
	spawnBtn.Text = "SPAWN"
	showSettings(false)
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
	listening = nil
	if mouseConn then mouseConn:Disconnect(); mouseConn = nil end
end

-- during an intermission the button waits (RoundServer's countdown is on ReplicatedStorage.Round)
local roundNode = ReplicatedStorage:FindFirstChild("Round")
RunService.Heartbeat:Connect(function()
	if not open then return end
	roundNode = roundNode or ReplicatedStorage:FindFirstChild("Round")
	if roundNode and roundNode:GetAttribute("State") == "Intermission" then
		spawnBtn.Text = string.format("NEXT ROUND IN %d", roundNode:GetAttribute("TimeLeft") or 0)
		spawnBtn.TextTransparency = 0.3
	elseif spawnBtn.Text:sub(1, 4) == "NEXT" then
		spawnBtn.Text = "SPAWN"
		refreshDetails()
	end
end)

spawnBtn.Activated:Connect(function()
	if not open or not catalogData then return end
	if roundNode and roundNode:GetAttribute("State") == "Intermission" then return end
	local a = catalogData.byArmor[selected.armor]
	local w = catalogData.byWeapon[selected.weapon]
	local sec = catalogData.byWeapon[selected.secondary]
	if (#catalogData.armors > 0 and not a) or (#catalogData.weapons > 0 and not w) then return end
	spawnBtn.Text = "SPAWNING…"
	event:FireServer("Spawn", a and a.id or nil, w and w.id or nil, sec and sec.id or nil)
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
