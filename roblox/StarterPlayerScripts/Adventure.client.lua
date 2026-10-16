--[[ ADVENTURE — the screens of the Play menu's second page (The Depths, and the modes after it):
     a mode that draws its own HUD says so (Round ▸ OwnHud; Objectives steps aside).

       THE RUN       top middle: the floor, what's happening (Round ▸ ObjLabel / ObjNote), your
                     gold, and your relics (hover or tap one: what it does)
       THE MAP       top right: the dungeon's rooms as you find them (a room you've stood in, and
                     the doors out of it), what each one is, you and your party
       A CHOICE      a chest's (or a shrine's) three cards: a weapon with its looks in 3D, a
                     relic, a tome, gold… click one (1 / 2 / 3, a controller's A), or leave it
       THE BOSS BAR  any boss near you (a model with Boss: the Depths' lords, the Horde's Warlord)
       BANNERS       a room sealed or cleared, a floor, the boss, victory; the fade going down
     And in the world: loot on the floor turns slowly; a chest or a shrine you've already
     opened stops offering itself to you (OpenedBy_<your id>).

     Server → here: ReplicatedStorage ▸ AdventureEvent ("Layout", "Room", "Run", "Choice",
     "Banner", "Fade"). Here → server: "Pick" (offer id, card index | nil), "Hello". ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local round = ReplicatedStorage:WaitForChild("Round")
local event = ReplicatedStorage:WaitForChild("AdventureEvent")

local FONT, TITLE, BODY = Theme.FONT, Theme.FONT_TITLE, Theme.FONT_BODY
local KIND_ICON = {start = "🔥", treasure = "💎", shrine = "✨", fountain = "⛲", stairs = "🔽", boss = "💀", elite = "⭐", exit = "🌀"}
local RARITY_COLOR = {}
for _, r in ipairs(Catalog.LOOT and Catalog.LOOT.RARITIES or {}) do RARITY_COLOR[r.id] = r.color end

--------------------------------------------------------------------
--  BUILDING BLOCKS
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Adventure"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 6
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
local function stroke(f, color, th, t)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.STROKE
	s.Thickness = th or 1.5
	s.Transparency = t or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
end

local function ownHud()
	return round:GetAttribute("OwnHud") == true and round:GetAttribute("State") == "Round"
end
local function menuUp()
	local h = player.PlayerGui:FindFirstChild("HubMenu")
	return h ~= nil and h.Enabled
end

--------------------------------------------------------------------
--  THE RUN (top middle)
--------------------------------------------------------------------
local runPanel = frame(gui, Theme.GLASS, 0.18, 12)
runPanel.Name = "Run"
runPanel.AnchorPoint = Vector2.new(0.5, 0)
runPanel.Position = UDim2.new(0.5, 0, 0, 74)
runPanel.Size = UDim2.fromOffset(440, 54)
runPanel.Visible = false
stroke(runPanel, Theme.STROKE, 1.5, 0.85)
local runLabel = text(runPanel, "", 17, Theme.TEXT, TITLE)
runLabel.Position = UDim2.fromOffset(16, 6)
runLabel.Size = UDim2.new(1, -150, 0, 22)
runLabel.TextXAlignment = Enum.TextXAlignment.Left
local runNote = text(runPanel, "", 13, Theme.DIM, FONT)
runNote.Position = UDim2.fromOffset(16, 29)
runNote.Size = UDim2.new(1, -150, 0, 18)
runNote.TextXAlignment = Enum.TextXAlignment.Left
local goldChip = frame(runPanel, Theme.GLASS2, 0, 10)
goldChip.AnchorPoint = Vector2.new(1, 0.5)
goldChip.Position = UDim2.new(1, -10, 0.5, 0)
goldChip.Size = UDim2.fromOffset(122, 36)
local goldText = text(goldChip, "💰 0", 17, Theme.MARKS, TITLE)
goldText.Size = UDim2.fromScale(1, 1)

local relicBar = Instance.new("Frame")
relicBar.Name = "Relics"
relicBar.BackgroundTransparency = 1
relicBar.AnchorPoint = Vector2.new(0.5, 0)
relicBar.Position = UDim2.new(0.5, 0, 0, 134)
relicBar.Size = UDim2.fromOffset(440, 34)
relicBar.Visible = false
relicBar.Parent = gui
local rl = Instance.new("UIListLayout")
rl.FillDirection = Enum.FillDirection.Horizontal
rl.HorizontalAlignment = Enum.HorizontalAlignment.Center
rl.Padding = UDim.new(0, 6)
rl.Parent = relicBar

local tip = frame(gui, Theme.GLASS, 0.05, 8)
tip.Name = "Tip"
tip.Size = UDim2.fromOffset(240, 54)
tip.Visible = false
tip.ZIndex = 50
stroke(tip, Theme.STROKE, 1, 0.8)
local tipName = text(tip, "", 15, Theme.TEXT, FONT)
tipName.Position = UDim2.fromOffset(10, 5); tipName.Size = UDim2.new(1, -20, 0, 18); tipName.TextXAlignment = Enum.TextXAlignment.Left; tipName.ZIndex = 51
local tipText = text(tip, "", 12, Theme.DIM, BODY)
tipText.Position = UDim2.fromOffset(10, 25); tipText.Size = UDim2.new(1, -20, 0, 26); tipText.TextWrapped = true
tipText.TextXAlignment = Enum.TextXAlignment.Left; tipText.TextYAlignment = Enum.TextYAlignment.Top; tipText.ZIndex = 51
local function showTip(on, name, body, color, at)
	tip.Visible = on
	if not on then return end
	tipName.Text = name; tipName.TextColor3 = color or Theme.TEXT
	tipText.Text = body
	tip.Position = UDim2.fromOffset(at.X + 14, at.Y + 14)
end

local runData = nil
local function drawRun()
	for _, c in ipairs(relicBar:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	if not runData then return end
	goldText.Text = "💰 " .. tostring(runData.gold or 0)
	local items = {}
	for _, r in ipairs(runData.relics or {}) do table.insert(items, r) end
	if runData.power and Catalog.POWER and Catalog.POWER[runData.power] then
		local p = Catalog.POWER[runData.power]
		table.insert(items, 1, {name = "Tome: " .. (p.name or p.id), glyph = "📖", rarity = "Epic", text = "Your power for the run: " .. (p.name or p.id)})
	end
	for _, r in ipairs(items) do
		local col = RARITY_COLOR[r.rarity] or Theme.STROKE
		local b = Instance.new("TextButton")
		b.AutoButtonColor = false
		b.BackgroundColor3 = Theme.GLASS
		b.BackgroundTransparency = 0.1
		b.Size = UDim2.fromOffset(34, 34)
		b.Text = r.glyph or "💎"
		b.TextSize = 20
		b.Font = FONT
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
		stroke(b, col, 2, 0)
		b.MouseEnter:Connect(function() showTip(true, r.name, r.text or "", col, UserInputService:GetMouseLocation()) end)
		b.MouseLeave:Connect(function() showTip(false) end)
		b.Activated:Connect(function()
			-- (a potion in a raider's bag: drink it)
			if r.use and r.uid and event then event:FireServer("Use", r.uid); return end
			showTip(true, r.name, r.text or "", col, Vector2.new(b.AbsolutePosition.X, b.AbsolutePosition.Y + 30))
			task.delay(2.5, function() showTip(false) end)
		end)
		b.Parent = relicBar
	end
end

--------------------------------------------------------------------
--  THE MAP (top right)
--------------------------------------------------------------------
local mapPanel = frame(gui, Theme.GLASS, 0.2, 12)
mapPanel.Name = "Minimap"
mapPanel.AnchorPoint = Vector2.new(1, 0)
mapPanel.Position = UDim2.new(1, -14, 0, 52)
mapPanel.Size = UDim2.fromOffset(210, 230)
mapPanel.Visible = false
mapPanel.ClipsDescendants = true
stroke(mapPanel, Theme.STROKE, 1.5, 0.85)
local mapTitle = text(mapPanel, "", 12, Theme.DIM, FONT)
mapTitle.Position = UDim2.fromOffset(0, 4); mapTitle.Size = UDim2.new(1, 0, 0, 16)
local mapArea = Instance.new("Frame")
mapArea.BackgroundTransparency = 1
mapArea.Position = UDim2.fromOffset(8, 22)
mapArea.Size = UDim2.new(1, -16, 1, -30)
mapArea.Parent = mapPanel

local layout = nil
local placeName = nil
local seen, visited = {}, {}
local roomFrames, dots = {}, {}
local bounds = nil
local function toMap(x, z)
	if not bounds then return UDim2.new() end
	local w, h = mapArea.AbsoluteSize.X, mapArea.AbsoluteSize.Y
	local s = math.min(w / bounds.w, h / bounds.h)
	local ox = (w - bounds.w * s) / 2
	local oy = (h - bounds.h * s) / 2
	return UDim2.fromOffset(ox + (x - bounds.x0) * s, oy + (z - bounds.z0) * s), s
end
local STATE_COL = {sealed = Color3.fromRGB(70, 74, 90), fight = Color3.fromRGB(210, 60, 60), clear = Color3.fromRGB(64, 92, 140)}
-- an island (Crownfall): its shape, its places, the ring and the next one
local ringNow, ringNext
local function circleFrame(color, fillT, strokeColor)
	local f = frame(mapArea, color, fillT)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.5, 0); c.Parent = f
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	if strokeColor then stroke(f, strokeColor, 2, 0) end
	return f
end
local function drawRealm()
	local R = layout.radius or 300
	bounds = {x0 = -R - 12, z0 = -R - 12, w = 2 * R + 24, h = 2 * R + 24}
	mapTitle.Text = "CROWNFALL"
	local pos, sc = toMap(0, 0)
	local island = circleFrame(Color3.fromRGB(70, 110, 60), 0)
	island.Position = pos; island.Size = UDim2.fromOffset(2 * R * sc, 2 * R * sc)
	for _, poi in ipairs(layout.pois or {}) do
		local d = frame(mapArea, Color3.fromRGB(230, 220, 190), 0, 3)
		d.AnchorPoint = Vector2.new(0.5, 0.5)
		d.Position = toMap(poi.x, poi.z)
		d.Size = UDim2.fromOffset(5, 5)
		d.ZIndex = 3
		local t = text(mapArea, string.upper(poi.name), 8, Color3.fromRGB(240, 236, 220), FONT)
		t.AnchorPoint = Vector2.new(0.5, 0)
		local pp = toMap(poi.x, poi.z)
		t.Position = UDim2.fromOffset(pp.X.Offset, pp.Y.Offset + 3)
		t.Size = UDim2.fromOffset(80, 10)
		t.ZIndex = 3
	end
	ringNow = circleFrame(Color3.new(1, 1, 1), 1, Color3.fromRGB(255, 120, 40)); ringNow.ZIndex = 4
	ringNext = circleFrame(Color3.new(1, 1, 1), 1, Color3.fromRGB(255, 255, 255)); ringNext.ZIndex = 4
end
local function placeOn(f, c, r)
	if not (f and typeof(c) == "Vector3" and r) then if f then f.Visible = false end; return end
	local pos, sc = toMap(c.X, c.Z)
	f.Visible = true
	f.Position = pos
	f.Size = UDim2.fromOffset(2 * r * sc, 2 * r * sc)
end
local function drawMap()
	for _, c in ipairs(mapArea:GetChildren()) do c:Destroy() end
	roomFrames, dots = {}, {}
	ringNow, ringNext = nil, nil
	if not layout then return end
	if layout.kind == "realm" then drawRealm(); return end
	local x0, z0, x1, z1 = math.huge, math.huge, -math.huge, -math.huge
	for _, r in pairs(layout.rooms) do
		x0 = math.min(x0, r.cx - r.w / 2); x1 = math.max(x1, r.cx + r.w / 2)
		z0 = math.min(z0, r.cz - r.d / 2); z1 = math.max(z1, r.cz + r.d / 2)
	end
	bounds = {x0 = x0 - 6, z0 = z0 - 6, w = (x1 - x0) + 12, h = (z1 - z0) + 12}
	mapTitle.Text = string.upper(layout.themeName or "") .. "  ·  FLOOR " .. tostring(layout.floor or 1)
	-- corridors under the rooms
	for _, r in pairs(layout.rooms) do
		for d, nid in pairs(r.doors or {}) do
			local o = layout.rooms[nid]
			if o and (d == "E" or d == "S") then
				local c = frame(mapArea, Color3.fromRGB(110, 116, 136), 0)
				c.Name = "Corr_" .. r.id .. "_" .. nid
				c:SetAttribute("A", r.id); c:SetAttribute("B", nid)
				local p1, s = toMap(r.cx, r.cz)
				local p2 = toMap(o.cx, o.cz)
				local ax, ay = p1.X.Offset, p1.Y.Offset
				local bx, by = p2.X.Offset, p2.Y.Offset
				local wpx = math.max(2, 10 * s)
				c.Position = UDim2.fromOffset(math.min(ax, bx) - wpx / 2, math.min(ay, by) - wpx / 2)
				c.Size = UDim2.fromOffset(math.abs(bx - ax) + wpx, math.abs(by - ay) + wpx)
				c.Visible = false
			end
		end
	end
	for id, r in pairs(layout.rooms) do
		local f = frame(mapArea, STATE_COL[r.state] or STATE_COL.sealed, 0, 3)
		local pos, s = toMap(r.cx - r.w / 2, r.cz - r.d / 2)
		f.Position = pos
		f.Size = UDim2.fromOffset(r.w * s, r.d * s)
		f.Visible = false
		f.ZIndex = 2
		local st = stroke(f, Color3.new(1, 1, 1), 1.5, 1)
		local icon = text(f, KIND_ICON[r.kind] or "", math.clamp(r.w * s * 0.5, 9, 16), Theme.TEXT, FONT)
		icon.Size = UDim2.fromScale(1, 1)
		icon.ZIndex = 3
		roomFrames[id] = {frame = f, stroke = st, room = r}
	end
end
local function refreshRoom(id)
	local rf = roomFrames[id]
	if not rf then return end
	rf.frame.BackgroundColor3 = STATE_COL[rf.room.state] or STATE_COL.sealed
	rf.frame.Visible = seen[id] == true
	rf.frame.BackgroundTransparency = visited[id] and 0 or 0.45
end
local function see(id)
	if not (layout and layout.rooms and layout.rooms[id]) then return end
	local changed = not visited[id]
	visited[id] = true
	seen[id] = true
	for _, nid in pairs(layout.rooms[id].doors or {}) do seen[nid] = true end
	if changed then
		for rid in pairs(roomFrames) do refreshRoom(rid) end
		for _, c in ipairs(mapArea:GetChildren()) do
			local a, b = c:GetAttribute("A"), c:GetAttribute("B")
			if a then c.Visible = (visited[a] or visited[b]) == true end
		end
	end
end
local function roomAt(pos)
	if not (layout and layout.rooms) then return nil end
	for id, r in pairs(layout.rooms) do
		if math.abs(pos.X - r.cx) <= r.w / 2 and math.abs(pos.Z - r.cz) <= r.d / 2 then return id end
	end
	return nil
end

--------------------------------------------------------------------
--  THE BOSS BAR
--------------------------------------------------------------------
local bossPanel = Instance.new("Frame")
bossPanel.Name = "Boss"
bossPanel.BackgroundTransparency = 1
bossPanel.AnchorPoint = Vector2.new(0.5, 0)
bossPanel.Position = UDim2.new(0.5, 0, 0, 176)
bossPanel.Size = UDim2.fromOffset(560, 46)
bossPanel.Visible = false
bossPanel.Parent = gui
local bossName = text(bossPanel, "", 20, Color3.fromRGB(255, 220, 200), TITLE)
bossName.Size = UDim2.new(1, 0, 0, 22)
local bossPhase = text(bossPanel, "", 13, Color3.fromRGB(255, 90, 70), FONT)
bossPhase.AnchorPoint = Vector2.new(1, 0); bossPhase.Position = UDim2.new(1, 0, 0, 2); bossPhase.Size = UDim2.fromOffset(120, 18)
bossPhase.TextXAlignment = Enum.TextXAlignment.Right
local bossBack = frame(bossPanel, Color3.fromRGB(20, 10, 12), 0.15, 6)
bossBack.Position = UDim2.fromOffset(0, 26); bossBack.Size = UDim2.new(1, 0, 0, 16)
stroke(bossBack, Color3.fromRGB(255, 120, 100), 1.5, 0.4)
local bossLag = frame(bossBack, Color3.fromRGB(255, 220, 160), 0, 6)
bossLag.Size = UDim2.fromScale(1, 1)
local bossFill = frame(bossBack, Color3.fromRGB(210, 40, 50), 0, 6)
bossFill.Size = UDim2.fromScale(1, 1)
local bossGrad = Instance.new("UIGradient")
bossGrad.Color = ColorSequence.new(Color3.fromRGB(255, 90, 80), Color3.fromRGB(150, 20, 40))
bossGrad.Rotation = 90
bossGrad.Parent = bossFill
local lagFrac = 1

--------------------------------------------------------------------
--  BANNERS, THE FADE
--------------------------------------------------------------------
local banner = Instance.new("Frame")
banner.Name = "Banner"
banner.BackgroundTransparency = 1
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.32)
banner.Size = UDim2.fromOffset(900, 110)
banner.Visible = false
banner.Parent = gui
local bannerText = text(banner, "", 54, Theme.TEXT, TITLE)
bannerText.Size = UDim2.new(1, 0, 0, 64)
bannerText.TextStrokeTransparency = 0.2
local bannerSub = text(banner, "", 18, Theme.DIM, FONT)
bannerSub.Position = UDim2.fromOffset(0, 66); bannerSub.Size = UDim2.new(1, 0, 0, 24)
local BANNER_COL = {boss = Color3.fromRGB(255, 80, 70), elite = Color3.fromRGB(200, 130, 255), fight = Color3.fromRGB(255, 170, 80),
	clear = Color3.fromRGB(110, 240, 140), victory = Color3.fromRGB(255, 210, 80), floor = Color3.fromRGB(230, 236, 255), descend = Color3.fromRGB(150, 210, 255)}
local bannerToken = 0
local function showBanner(b)
	bannerToken += 1
	local my = bannerToken
	bannerText.Text = b.text or ""
	bannerSub.Text = b.sub or ""
	bannerText.TextColor3 = BANNER_COL[b.kind or ""] or Theme.TEXT
	banner.Visible = true
	bannerText.TextTransparency, bannerSub.TextTransparency = 1, 1
	local sc = banner:FindFirstChild("Pop") or Instance.new("UIScale")
	sc.Name = "Pop"; sc.Parent = banner
	sc.Scale = 1.25
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	TweenService:Create(bannerText, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
	TweenService:Create(bannerSub, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
	if b.countdown then
		task.spawn(function()
			for i = b.countdown, 1, -1 do
				if bannerToken ~= my then return end
				bannerSub.Text = (b.sub or ""):gsub("·%s*%d+$", "· " .. i)
				task.wait(1)
			end
		end)
	end
	task.delay(b.countdown or 2.6, function()
		if bannerToken ~= my then return end
		TweenService:Create(bannerText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(bannerSub, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		task.wait(0.55)
		if bannerToken == my then banner.Visible = false end
	end)
end

local fade = frame(gui, Color3.new(0, 0, 0), 1)
fade.Name = "Fade"
fade.Size = UDim2.fromScale(1, 1)
fade.ZIndex = 100
fade.Active = false

--------------------------------------------------------------------
--  A CHOICE (a chest's cards)
--------------------------------------------------------------------
local choiceBack = frame(gui, Color3.new(0, 0, 0), 0.45)
choiceBack.Name = "Choice"
choiceBack.Size = UDim2.fromScale(1, 1)
choiceBack.Visible = false
choiceBack.ZIndex = 20
choiceBack.Active = true
local choiceTitle = text(choiceBack, "", 40, Theme.TEXT, TITLE)
choiceTitle.AnchorPoint = Vector2.new(0.5, 0.5); choiceTitle.Position = UDim2.new(0.5, 0, 0.5, -250); choiceTitle.Size = UDim2.fromOffset(800, 46); choiceTitle.ZIndex = 21
local choiceSub = text(choiceBack, "", 16, Theme.DIM, FONT)
choiceSub.AnchorPoint = Vector2.new(0.5, 0.5); choiceSub.Position = UDim2.new(0.5, 0, 0.5, -216); choiceSub.Size = UDim2.fromOffset(800, 22); choiceSub.ZIndex = 21
local cardRow = Instance.new("Frame")
cardRow.BackgroundTransparency = 1
cardRow.AnchorPoint = Vector2.new(0.5, 0.5)
cardRow.Position = UDim2.new(0.5, 0, 0.5, 6)
cardRow.Size = UDim2.fromOffset(800, 360)
cardRow.ZIndex = 21
cardRow.Parent = choiceBack
local crl = Instance.new("UIListLayout")
crl.FillDirection = Enum.FillDirection.Horizontal
crl.HorizontalAlignment = Enum.HorizontalAlignment.Center
crl.VerticalAlignment = Enum.VerticalAlignment.Center
crl.Padding = UDim.new(0, 18)
crl.Parent = cardRow
local leave = Instance.new("TextButton")
leave.AnchorPoint = Vector2.new(0.5, 0.5)
leave.Position = UDim2.new(0.5, 0, 0.5, 222)
leave.Size = UDim2.fromOffset(180, 40)
leave.BackgroundColor3 = Theme.GLASS2
leave.Text = "LEAVE IT"
leave.TextColor3 = Theme.DIM
leave.Font = FONT
leave.TextSize = 15
leave.ZIndex = 21
leave.AutoButtonColor = true
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = leave end
leave.Parent = choiceBack

local current = nil   -- {id, cards}
local function closeChoice()
	choiceBack.Visible = false
	current = nil
	for _, c in ipairs(cardRow:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(choiceBack) then GuiService.SelectedObject = nil end
end
local function pick(i)
	if not current then return end
	event:FireServer("Pick", current.id, i)
	closeChoice()
end
leave.Activated:Connect(function() pick(nil) end)

-- a weapon in 3D, wearing its skin, turning slowly
local function weaponView(parent, weaponId, skinId)
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(160, 150, 140)
	vp.LightColor = Color3.fromRGB(255, 244, 228)
	vp.LightDirection = Vector3.new(-0.5, -1, 0.6)
	vp.ZIndex = 23
	vp.Parent = parent
	local t = Catalog.weaponModel(weaponId)
	if not t then vp:Destroy(); return nil end
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.Parent = vp
	vp.CurrentCamera = cam
	local m = t:Clone()
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end; if d:IsA("BasePart") then d.Anchored = true end end
	m.Parent = world
	if skinId and Catalog.SKIN and Catalog.SKIN[skinId] then pcall(Dresser.applySkin, m, skinId, nil) end
	local cf, sz = m:GetBoundingBox()
	local longest = math.max(sz.X, sz.Y, sz.Z, 0.5)
	local axis = (sz.X >= sz.Y and sz.X >= sz.Z) and Vector3.xAxis or (sz.Y >= sz.Z and Vector3.yAxis or Vector3.zAxis)
	local along = cf:VectorToWorldSpace(axis)
	local up = math.abs(along.Y) < 0.9 and Vector3.yAxis or Vector3.zAxis
	local vy = (up - along * up:Dot(along)).Unit
	local box = CFrame.fromMatrix(cf.Position, vy, along)
	local base = box:Inverse() * m:GetPivot()
	local d = (longest * 0.6) / math.tan(math.rad(14))
	cam.FieldOfView = 28
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0, -d), Vector3.zero)
	local spin = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not vp.Parent then conn:Disconnect(); return end
		spin += dt * 0.8
		m:PivotTo(CFrame.Angles(0, spin, 0) * CFrame.Angles(0, 0, math.rad(-30)) * base)
	end)
	return vp
end

local function card(i, c)
	local col = c.color or RARITY_COLOR[c.rarity] or Theme.STROKE
	local b = Instance.new("TextButton")
	b.Name = "Card" .. i
	b.AutoButtonColor = false
	b.Text = ""
	b.BackgroundColor3 = Theme.GLASS
	b.BackgroundTransparency = 0.04
	b.Size = UDim2.fromOffset(240, 350)
	b.ZIndex = 22
	b.LayoutOrder = i
	b.Selectable = true
	do local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 16); cr.Parent = b end
	local st = stroke(b, col, 3, 0)
	local sc = Instance.new("UIScale"); sc.Parent = b
	local glow = frame(b, col, 0.55, 16)
	glow.Size = UDim2.new(1, 0, 0, 150)
	glow.ZIndex = 22
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	g.Rotation = 90
	g.Parent = glow
	local kindLine = text(b, string.upper((c.rarity or "") .. "  ·  " .. (c.kind or "")), 12, col, FONT)
	kindLine.Position = UDim2.fromOffset(0, 10); kindLine.Size = UDim2.new(1, 0, 0, 16); kindLine.ZIndex = 24
	local view = Instance.new("Frame")
	view.BackgroundTransparency = 1
	view.Position = UDim2.fromOffset(10, 28)
	view.Size = UDim2.new(1, -20, 0, 120)
	view.ZIndex = 23
	view.Parent = b
	local shown = c.kind == "weapon" and c.weapon and weaponView(view, c.weapon, c.skin)
	if not shown then
		local g2 = text(view, c.glyph or "💎", 66, Theme.TEXT, FONT)
		g2.Size = UDim2.fromScale(1, 1); g2.ZIndex = 24
		g2.TextStrokeTransparency = 1
	end
	local name = text(b, c.name or "", 19, Theme.TEXT, TITLE)
	name.Position = UDim2.fromOffset(12, 152); name.Size = UDim2.new(1, -24, 0, 48)
	name.TextWrapped = true; name.ZIndex = 24
	local sub = text(b, c.sub or "", 12, Theme.DIM, FONT)
	sub.Position = UDim2.fromOffset(12, 200); sub.Size = UDim2.new(1, -24, 0, 16); sub.ZIndex = 24
	local lines = Instance.new("Frame")
	lines.BackgroundTransparency = 1
	lines.Position = UDim2.fromOffset(14, 222)
	lines.Size = UDim2.new(1, -28, 1, -262)
	lines.ZIndex = 24
	lines.Parent = b
	local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 4); ll.Parent = lines
	for _, line in ipairs(c.lines or {}) do
		local l = text(lines, "• " .. line, 13, Color3.fromRGB(226, 232, 246), BODY)
		l.Size = UDim2.new(1, 0, 0, 0)
		l.AutomaticSize = Enum.AutomaticSize.Y
		l.TextWrapped = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.ZIndex = 24
	end
	local key = text(b, Device.console() and "" or ("PRESS " .. i), 12, col, FONT)
	key.AnchorPoint = Vector2.new(0.5, 1); key.Position = UDim2.new(0.5, 0, 1, -10); key.Size = UDim2.new(1, 0, 0, 16); key.ZIndex = 24
	b.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), {Scale = 1.05}):Play(); st.Thickness = 4 end)
	b.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), {Scale = 1}):Play(); st.Thickness = 3 end)
	b.SelectionGained:Connect(function() sc.Scale = 1.05 end)
	b.SelectionLost:Connect(function() sc.Scale = 1 end)
	b.Activated:Connect(function() pick(i) end)
	-- it arrives: a flip up from below
	sc.Scale = 0.6
	b.Rotation = (i - 2) * 6
	task.delay(0.08 * i, function()
		TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TweenService:Create(b, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
	end)
	b.Parent = cardRow
	return b
end

local function openChoice(data)
	closeChoice()
	current = {id = data.id, cards = data.cards}
	choiceTitle.Text = data.title or "A CHEST"
	choiceSub.Text = data.sub or "Pick one"
	local first
	for i, c in ipairs(data.cards or {}) do
		local b = card(i, c)
		first = first or b
	end
	choiceBack.Visible = true
	if Device.console() and first then GuiService.SelectedObject = first end
end
UserInputService.InputBegan:Connect(function(input, gp)
	if not current or gp then return end
	local n = ({[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3})[input.KeyCode]
	if n and current.cards[n] then pick(n) end
	if input.KeyCode == Enum.KeyCode.ButtonB then pick(nil) end
end)
-- the mouse is free while the cards are up (the camera locks it every frame: this goes after)
RunService:BindToRenderStep("AdventureMouse", Enum.RenderPriority.Camera.Value + 20, function()
	if choiceBack.Visible then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)

--------------------------------------------------------------------
--  EVENTS
--------------------------------------------------------------------
if event then
	event.OnClientEvent:Connect(function(kind, data)
		if kind == "Layout" then
			layout = data
			seen, visited = {}, {}
			task.defer(function()
				drawMap()
				for id in pairs(roomFrames) do refreshRoom(id) end
			end)
			placeName = nil
		elseif kind == "Room" then
			if layout and layout.rooms and data and layout.rooms[data.id] then
				layout.rooms[data.id].state = data.state
				refreshRoom(data.id)
			end
		elseif kind == "Run" then
			runData = data
			drawRun()
		elseif kind == "Choice" then
			openChoice(data)
		elseif kind == "Banner" then
			showBanner(data or {})
		elseif kind == "Fade" then
			TweenService:Create(fade, TweenInfo.new(0.5), {BackgroundTransparency = (data and data.on) and 0 or 1}):Play()
		end
	end)
	event:FireServer("Hello")
end

--------------------------------------------------------------------
--  A BOSS'S MOVES (Combat ▸ BossMoves): the wind-up on its body, its glow, the ground
--  shaking under you, its second phase
--------------------------------------------------------------------
local PowerPoses = require(ReplicatedStorage:WaitForChild("PowerPoses"))
local bossFx = ReplicatedStorage:WaitForChild("BossFX")
local shakePower, shakeUntil, SHAKE = 0, 0, 0.5
if bossFx then
	bossFx.OnClientEvent:Connect(function(kind, a, b, c)
		if kind == "Pose" then
			if typeof(a) == "Instance" then pcall(PowerPoses.play, a, b) end
		elseif kind == "Flash" then
			if typeof(a) ~= "Instance" or not a.Parent then return end
			local hl = Instance.new("Highlight")
			hl.FillColor, hl.OutlineColor = b or Color3.new(1, 0.3, 0.2), b or Color3.new(1, 0.3, 0.2)
			hl.FillTransparency, hl.OutlineTransparency = 0.45, 0
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Parent = a
			TweenService:Create(hl, TweenInfo.new(c or 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {FillTransparency = 1, OutlineTransparency = 1}):Play()
			task.delay((c or 0.6) + 0.05, function() hl:Destroy() end)
		elseif kind == "Shake" then
			local cam = workspace.CurrentCamera
			local d = cam and typeof(a) == "Vector3" and (cam.CFrame.Position - a).Magnitude or 999
			if d < 100 then
				shakePower = math.max(os.clock() < shakeUntil and shakePower or 0, (b or 1) * (1 - d / 100))
				shakeUntil = os.clock() + SHAKE
			end
		elseif kind == "Phase" then
			local name = typeof(a) == "Instance" and (a:GetAttribute("BossName") or a:GetAttribute("TagName")) or "THE BOSS"
			showBanner({text = string.upper(name), sub = b or "", kind = "boss"})
		end
	end)
end
RunService:BindToRenderStep("AdventureShake", Enum.RenderPriority.Camera.Value + 15, function()
	local left = shakeUntil - os.clock()
	if left <= 0 then return end
	local cam = workspace.CurrentCamera
	local k = shakePower * (left / SHAKE)
	local t = os.clock() * 40
	cam.CFrame = cam.CFrame * CFrame.new(math.sin(t * 1.3) * 0.25 * k, math.cos(t * 1.7) * 0.25 * k, 0) * CFrame.Angles(math.sin(t) * 0.008 * k, 0, math.cos(t * 1.1) * 0.01 * k)
end)

--------------------------------------------------------------------
--  EVERY FRAME
--------------------------------------------------------------------
local lastScan = 0
local boss = nil
RunService.RenderStepped:Connect(function(dt)
	local own = ownHud() and not menuUp()
	runPanel.Visible = own
	relicBar.Visible = own and runData ~= nil
	mapPanel.Visible = own and layout ~= nil
	if not own then showTip(false) end
	if own then
		runLabel.Text = round:GetAttribute("ObjLabel") or ""
		runNote.Text = (round:GetAttribute("ObjNote") or "") .. (placeName and ("  ·  📍 " .. string.upper(placeName)) or "")
		-- the chip: a mode's word for you (your crown points, your side), else the run's gold
		local chip = player:GetAttribute("AdvChip")
		if chip then goldText.Text = chip; goldChip.Size = UDim2.fromOffset(170, 36)
		else goldChip.Size = UDim2.fromOffset(122, 36); goldText.Text = "💰 " .. tostring(runData and runData.gold or 0) end
	end
	-- a ghoul (Plague Night) sees the living near it through walls
	local me = player.Character
	local ghoul = me and me:GetAttribute("Ghoul") == true and round:GetAttribute("Mode") == "Plague"
	local myRoot = me and me:FindFirstChild("HumanoidRootPart")
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		local hl = c and c:FindFirstChild("ScentOfTheLiving")
		local want = ghoul and p ~= player and c and not c:GetAttribute("Ghoul") and r and myRoot and (r.Position - myRoot.Position).Magnitude < 70
		if want and not hl then
			hl = Instance.new("Highlight")
			hl.Name = "ScentOfTheLiving"
			hl.FillTransparency, hl.OutlineTransparency = 1, 0.1
			hl.OutlineColor = Color3.fromRGB(255, 70, 60)
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = c
		elseif hl and not want then
			hl:Destroy()
		end
	end
	-- the map: where you are, your party
	if layout and mapPanel.Visible then
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local id = roomAt(hrp.Position)
			if id then see(id) end
			for rid, rf in pairs(roomFrames) do rf.stroke.Transparency = (rid == id) and 0 or 1 end
			-- an island: the ring, the next ring, the place you're in
			if layout.kind == "realm" then
				placeOn(ringNow, round:GetAttribute("RingCentre"), round:GetAttribute("RingRadius"))
				placeOn(ringNext, round:GetAttribute("RingNextCentre"), round:GetAttribute("RingNextRadius"))
				local here
				for _, poi in ipairs(layout.pois or {}) do
					if (Vector3.new(poi.x, 0, poi.z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude < (poi.r or 25) + 6 then here = poi.name end
				end
				placeName = here
			end
		end
		local live = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			local r = c and c:FindFirstChild("HumanoidRootPart")
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if r and h and h.Health > 0 then
				local d = dots[p]
				if not d then
					d = frame(mapArea, p == player and Theme.ACCENT or Theme.CROWNS, 0, 6)
					d.Size = UDim2.fromOffset(p == player and 9 or 7, p == player and 9 or 7)
					d.AnchorPoint = Vector2.new(0.5, 0.5)
					d.ZIndex = 5
					stroke(d, Theme.OUTLINE, 1.5, 0)
					dots[p] = d
				end
				d.Position = toMap(r.Position.X, r.Position.Z)
				live[p] = true
			end
		end
		for p, d in pairs(dots) do if not live[p] then d:Destroy(); dots[p] = nil end end
	end
	-- the boss bar: the nearest boss
	local now = os.clock()
	if now - lastScan > 0.3 then
		lastScan = now
		boss = nil
		local npcs = workspace:FindFirstChild("NPCs")
		local cam = workspace.CurrentCamera
		local best = 140
		for _, m in ipairs(npcs and npcs:GetChildren() or {}) do
			if m:GetAttribute("Boss") then
				local h = m:FindFirstChildOfClass("Humanoid")
				local r = m:FindFirstChild("HumanoidRootPart")
				if h and r and h.Health > 0 and cam then
					local d = (r.Position - cam.CFrame.Position).Magnitude
					if d < best then best, boss = d, m end
				end
			end
		end
	end
	local bh = boss and boss.Parent and boss:FindFirstChildOfClass("Humanoid")
	bossPanel.Visible = bh ~= nil and bh.Health > 0 and not menuUp()
	if bossPanel.Visible then
		local frac = math.clamp(bh.Health / math.max(bh.MaxHealth, 1), 0, 1)
		bossFill.Size = UDim2.fromScale(frac, 1)
		lagFrac = math.max(frac, lagFrac - dt * 0.25)
		if lagFrac < frac then lagFrac = frac end
		bossLag.Size = UDim2.fromScale(lagFrac, 1)
		bossName.Text = string.upper(boss:GetAttribute("BossName") or boss:GetAttribute("TagName") or "BOSS")
		bossPhase.Text = boss:GetAttribute("Enraged") and "ENRAGED" or ""
	else
		lagFrac = 1
	end
end)

-- the world: loot turns, opened things stop offering themselves to you
local spinBase = setmetatable({}, {__mode = "k"})
RunService.Heartbeat:Connect(function()
	local f = workspace:FindFirstChild("LootDrops")
	if not f then return end
	local t = os.clock()
	for _, m in ipairs(f:GetChildren()) do
		if m.Name == "LootDrop" then
			local shape = m:FindFirstChild("Shape")
			if shape then
				local base = spinBase[shape]
				if not base then base = shape:GetPivot(); spinBase[shape] = base end
				local pos = base.Position
				shape:PivotTo(CFrame.new(pos + Vector3.new(0, math.sin(t * 2) * 0.25, 0)) * CFrame.Angles(0, t * 1.2, 0) * base.Rotation)
			end
		end
	end
end)
task.spawn(function()
	local key = "OpenedBy_" .. player.UserId
	while true do
		task.wait(0.5)
		for _, folder in ipairs({workspace:FindFirstChild("LootDrops"), workspace:FindFirstChild("Map")}) do
			for _, d in ipairs(folder and folder:GetDescendants() or {}) do
				if d:IsA("ProximityPrompt") and d.Enabled then
					local holder = d:FindFirstAncestorWhichIsA("Model")
					if (holder and holder:GetAttribute(key)) or (d.Parent and d.Parent:GetAttribute(key)) then d.Enabled = false end
				end
			end
		end
	end
end)
