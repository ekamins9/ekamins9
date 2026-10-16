--[[ DARK UI — the look of the dungeon game (the Deadvault lobby: DungeonMenu.client; its raid
     screens: RaidInventory.client): near-black panels with a worn edge and a thin gold line
     inside it, small gold diamonds at the corners, Merriweather type, slots sunk into the panel,
     and every item shown as ITSELF in 3D (no emoji): its weapon in its skin, its armour's coat,
     a corked bottle of its colour, a goblet, a ring, a gem, a tome, a stack of coin.

       DarkUI.C                          the colours · DarkUI.font(weight) a FontFace
       DarkUI.text(parent, str, size, color, weight)
       DarkUI.panel(parent, opts)        opts.title: a title band at its top · opts.corners
       DarkUI.slot(parent, rarity)       a sunken square (a rarity tints its floor)
       DarkUI.button(parent, str, kind)  "stone" (default) · "gold" · "red" · "green"
       DarkUI.diamond(parent, size, color, filled)
       DarkUI.rule(parent, y)            a gold line with a diamond in its middle
       DarkUI.icon(parent, card)         the item in 3D, framed to fit (cached per kind)
       DarkUI.tooltip(gui)               -> tip; tip:show(card, extra) / tip:hide() ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))

local DarkUI = {}
local C = {
	BG = Color3.fromRGB(9, 8, 7), PANEL = Color3.fromRGB(21, 19, 17), PANEL2 = Color3.fromRGB(30, 27, 24), INSET = Color3.fromRGB(12, 11, 10),
	EDGE = Color3.fromRGB(64, 57, 49), EDGE2 = Color3.fromRGB(96, 86, 72), GOLD = Color3.fromRGB(196, 160, 96), GOLD2 = Color3.fromRGB(236, 204, 136),
	TEXT = Color3.fromRGB(228, 218, 198), DIM = Color3.fromRGB(150, 140, 122), FAINT = Color3.fromRGB(92, 86, 76),
	GOOD = Color3.fromRGB(134, 206, 92), BAD = Color3.fromRGB(214, 74, 62), BLUE = Color3.fromRGB(110, 160, 230),
	PARCH = Color3.fromRGB(122, 104, 80), PARCH2 = Color3.fromRGB(84, 70, 52), INK = Color3.fromRGB(34, 24, 14),
}
DarkUI.C = C
DarkUI.RARITY = {}
for _, r in ipairs(Catalog.LOOT and Catalog.LOOT.RARITIES or {}) do DarkUI.RARITY[r.id] = r.color end

local FAMILY = "rbxasset://fonts/families/Merriweather.json"
function DarkUI.font(weight) return Font.new(FAMILY, weight or Enum.FontWeight.Regular) end

function DarkUI.text(parent, str, size, color, weight)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = str or ""
	l.TextSize = size or 16
	l.TextColor3 = color or C.TEXT
	l.FontFace = DarkUI.font(weight)
	l.TextStrokeTransparency = 0.75
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	l.Parent = parent
	return l
end
local function corner(f, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 3); c.Parent = f; return c end
local function stroke(f, color, th, t)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness, s.Transparency = color, th or 1, t or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
end
DarkUI.stroke = stroke
local function gradient(f, top, bottom, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(top, bottom)
	g.Rotation = rot or 90
	g.Parent = f
	return g
end
DarkUI.gradient = gradient

function DarkUI.diamond(parent, size, color, filled)
	local d = Instance.new("Frame")
	d.Size = UDim2.fromOffset(size, size)
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Rotation = 45
	d.BackgroundColor3 = color or C.GOLD
	d.BackgroundTransparency = filled == false and 1 or 0
	d.BorderSizePixel = 0
	stroke(d, color or C.GOLD, 1, filled == false and 0 or 0.3)
	d.Parent = parent
	return d
end

-- a gold line across, a diamond in its middle (under titles, between sections)
function DarkUI.rule(parent, y, width)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, y)
	holder.Size = width and UDim2.fromOffset(width, 10) or UDim2.new(1, -40, 0, 10)
	holder.Parent = parent
	local line = Instance.new("Frame")
	line.BorderSizePixel = 0
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.fromScale(0, 0.5)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.BackgroundColor3 = C.GOLD
	line.Parent = holder
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1)})
	g.Parent = line
	local d = DarkUI.diamond(holder, 7, C.GOLD)
	d.Position = UDim2.fromScale(0.5, 0.5)
	return holder
end

-- A PANEL: near-black, a worn edge, a thin gold line inside it, gold diamonds at the corners
function DarkUI.panel(parent, opts)
	opts = opts or {}
	local f = Instance.new("Frame")
	f.BackgroundColor3 = opts.color or C.PANEL
	f.BorderSizePixel = 0
	corner(f, 4)
	gradient(f, Color3.new(1, 1, 1), Color3.fromRGB(150, 146, 140))
	stroke(f, C.EDGE, 2, 0)
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.BackgroundTransparency = 1
	inner.Position = UDim2.fromOffset(5, 5)
	inner.Size = UDim2.new(1, -10, 1, -10)
	corner(inner, 2)
	stroke(inner, C.GOLD, 1, 0.72)
	inner.Parent = f
	if opts.corners ~= false then
		for _, p in ipairs({{0, 0}, {1, 0}, {0, 1}, {1, 1}}) do
			local d = DarkUI.diamond(f, 9, C.GOLD)
			d.Position = UDim2.new(p[1], p[1] == 0 and 5 or -5, p[2], p[2] == 0 and 5 or -5)
			d.ZIndex = 3
		end
	end
	if opts.title then
		local t = DarkUI.text(f, opts.title, opts.titleSize or 20, C.GOLD2, Enum.FontWeight.Bold)
		t.Name = "Title"
		t.Position = UDim2.fromOffset(0, 10)
		t.Size = UDim2.new(1, 0, 0, 26)
		DarkUI.rule(f, 38)
	end
	f.Parent = parent
	return f
end

-- a parchment page (the class screen's sides)
function DarkUI.parchment(parent)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromRGB(196, 176, 140)
	f.BorderSizePixel = 0
	corner(f, 3)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 128, 98)), ColorSequenceKeypoint.new(0.12, Color3.fromRGB(226, 208, 172)),
		ColorSequenceKeypoint.new(0.88, Color3.fromRGB(216, 196, 160)), ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 118, 90))})
	g.Parent = f
	-- (burnt at its top and bottom)
	for _, top in ipairs({true, false}) do
		local band = Instance.new("Frame")
		band.BorderSizePixel = 0
		band.BackgroundColor3 = Color3.fromRGB(40, 28, 18)
		band.Size = UDim2.new(1, 0, 0, 40)
		band.Position = top and UDim2.new() or UDim2.new(0, 0, 1, -40)
		local bg = Instance.new("UIGradient")
		bg.Rotation = top and 90 or -90
		bg.Transparency = NumberSequence.new(0.2, 1)
		bg.Parent = band
		band.Parent = f
	end
	stroke(f, Color3.fromRGB(40, 32, 24), 3, 0)
	f.Parent = parent
	return f
end

-- a slot sunk into the panel (a rarity tints its floor, like a lit gem in it)
function DarkUI.slot(parent, rarity)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = C.INSET
	f.BorderSizePixel = 0
	corner(f, 2)
	stroke(f, C.EDGE, 1, 0)
	local floor = Instance.new("Frame")
	floor.Name = "Floor"
	floor.BorderSizePixel = 0
	floor.Size = UDim2.fromScale(1, 1)
	floor.BackgroundColor3 = rarity and DarkUI.RARITY[rarity] or Color3.fromRGB(40, 36, 32)
	floor.BackgroundTransparency = rarity and 0.55 or 0.85
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 0.85), NumberSequenceKeypoint.new(1, 0.2)})
	g.Parent = floor
	corner(floor, 2)
	floor.Parent = f
	f.Parent = parent
	return f
end

function DarkUI.button(parent, str, kind, size)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Text = str
	b.TextSize = size or 16
	b.FontFace = DarkUI.font(Enum.FontWeight.Bold)
	local base = (kind == "gold" and Color3.fromRGB(120, 92, 46)) or (kind == "red" and Color3.fromRGB(110, 34, 28)) or (kind == "green" and Color3.fromRGB(56, 92, 38)) or C.PANEL2
	b.BackgroundColor3 = base
	b.TextColor3 = kind == "gold" and C.GOLD2 or C.TEXT
	b.TextStrokeTransparency = 0.6
	corner(b, 3)
	gradient(b, Color3.new(1, 1, 1), Color3.fromRGB(120, 116, 110))
	local s = stroke(b, kind == "gold" and C.GOLD or C.EDGE2, 1.5, 0)
	b.MouseEnter:Connect(function() b.BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.12); s.Color = C.GOLD2 end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = base; s.Color = kind == "gold" and C.GOLD or C.EDGE2 end)
	b.Parent = parent
	return b
end

--------------------------------------------------------------------
--  THE THINGS THEMSELVES, IN 3D
--------------------------------------------------------------------
local cache = {}
local function P(m, size, cf, color, mat, shape, t)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Size, p.CFrame = size, cf
	p.Color, p.Material = color, mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	if t then p.Transparency = t end
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end
local function ell(m, size, cf, color, mat, t)
	local p = P(m, size, cf, color, mat, nil, t)
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p
	return p
end
local function cyl(m, d, h, cf, color, mat, t) return P(m, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.pi / 2), color, mat, Enum.PartType.Cylinder, t) end
local function ball(m, d, cf, color, mat, t) return P(m, Vector3.new(d, d, d), cf, color, mat, Enum.PartType.Ball, t) end
local function ring(m, r, th, cf, color, mat, n)
	n = n or 14
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		P(m, Vector3.new(th, th, 2 * math.pi * r / n + 0.02), cf * CFrame.Angles(0, a, 0) * CFrame.new(r, 0, 0), color, mat)
	end
end
local GOLDM, SILVER = Color3.fromRGB(226, 180, 70), Color3.fromRGB(200, 204, 210)
local CF = CFrame.new
local POTION_COLOR = {Healing = Color3.fromRGB(210, 30, 40), Greater = Color3.fromRGB(240, 60, 90), Fury = Color3.fromRGB(255, 120, 20),
	Stone = Color3.fromRGB(130, 140, 160), Swift = Color3.fromRGB(80, 220, 120)}

local SHAPES = {}
SHAPES.potion = function(m, card)
	local col = POTION_COLOR[card.potion or ""] or (DarkUI.RARITY[card.rarity] or Color3.fromRGB(200, 50, 60))
	ball(m, 1.75, CF(0, -0.05, 0), col, Enum.Material.Neon, 0)
	ball(m, 2, CF(0, 0, 0), Color3.fromRGB(190, 210, 220), Enum.Material.SmoothPlastic, 0.82)
	ball(m, 0.5, CF(-0.45, 0.45, -0.75), Color3.new(1, 1, 1), Enum.Material.Neon, 0.35)
	cyl(m, 0.62, 1, CF(0, 1.25, 0), Color3.fromRGB(170, 190, 200), Enum.Material.SmoothPlastic, 0.55)
	cyl(m, 0.66, 0.5, CF(0, 1.85, 0), Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
	cyl(m, 0.72, 0.12, CF(0, 1.55, 0), GOLDM, Enum.Material.Metal)
end
SHAPES.gold = function(m)
	for i = 0, 4 do cyl(m, 1.5, 0.22, CF(math.sin(i) * 0.12, i * 0.24, math.cos(i) * 0.1) * CFrame.Angles(0, i, 0), GOLDM, Enum.Material.Metal) end
	cyl(m, 1.5, 0.22, CF(1.4, 0, 0.4) * CFrame.Angles(0, 0, 1.2), GOLDM, Enum.Material.Metal)
end
SHAPES.tome = function(m, card)
	local col = DarkUI.RARITY[card.rarity] or Color3.fromRGB(110, 60, 140)
	P(m, Vector3.new(2.4, 0.5, 3), CF(0, 0, 0), Color3.fromRGB(70, 40, 30), Enum.Material.Leather)
	P(m, Vector3.new(2.2, 0.4, 2.85), CF(0.08, 0, 0), Color3.fromRGB(236, 226, 196), Enum.Material.SmoothPlastic)
	P(m, Vector3.new(2.42, 0.52, 0.3), CF(0, 0, -1.1), GOLDM, Enum.Material.Metal)
	P(m, Vector3.new(2.42, 0.52, 0.3), CF(0, 0, 1.1), GOLDM, Enum.Material.Metal)
	P(m, Vector3.new(0.6, 0.12, 0.6), CF(0, 0.3, 0) * CFrame.Angles(0, math.rad(45), 0), col, Enum.Material.Neon)
end
-- a pendant on a chain (most relics), a ring, a coin, a feather, a heart…
local function pendant(m, col, gem)
	ring(m, 1.1, 0.12, CF(0, 1, 0) * CFrame.Angles(math.rad(90), 0, 0), GOLDM, Enum.Material.Metal, 16)
	cyl(m, 1.1, 0.3, CF(0, -0.4, 0) * CFrame.Angles(math.rad(90), 0, 0), GOLDM, Enum.Material.Metal)
	ball(m, gem or 0.75, CF(0, -0.4, -0.2), col, Enum.Material.Neon)
end
local RELIC_LOOK = {
	IronBand = function(m) ring(m, 0.9, 0.3, CF() * CFrame.Angles(math.rad(70), 0, 0), Color3.fromRGB(110, 112, 120), Enum.Material.Metal, 16) end,
	StormRing = function(m) ring(m, 0.9, 0.26, CF() * CFrame.Angles(math.rad(70), 0, 0), GOLDM, Enum.Material.Metal, 16); ball(m, 0.6, CF(0, 0.85, 0.3), Color3.fromRGB(120, 190, 255), Enum.Material.Neon) end,
	LuckyCoin = function(m) cyl(m, 1.8, 0.25, CF() * CFrame.Angles(math.rad(70), 0, 0), GOLDM, Enum.Material.Metal); cyl(m, 1.1, 0.27, CF() * CFrame.Angles(math.rad(70), 0, 0), Color3.fromRGB(200, 150, 50), Enum.Material.Metal) end,
	EagleFeather = function(m) P(m, Vector3.new(0.12, 3, 0.7), CF() * CFrame.Angles(0, 0, 0.5), Color3.fromRGB(220, 210, 190)); P(m, Vector3.new(0.06, 3.2, 0.08), CF() * CFrame.Angles(0, 0, 0.5), Color3.fromRGB(120, 90, 60)) end,
	PhoenixPlume = function(m) P(m, Vector3.new(0.12, 3, 0.8), CF() * CFrame.Angles(0, 0, 0.5), Color3.fromRGB(255, 120, 40), Enum.Material.Neon); P(m, Vector3.new(0.13, 1.4, 0.5), CF(0.2, 0.6, 0) * CFrame.Angles(0, 0, 0.5), Color3.fromRGB(255, 220, 90), Enum.Material.Neon) end,
	OxHeart = function(m) ball(m, 1.2, CF(-0.4, 0.3, 0), Color3.fromRGB(170, 30, 40)); ball(m, 1.2, CF(0.4, 0.3, 0), Color3.fromRGB(170, 30, 40)); P(m, Vector3.new(1.2, 1.2, 1), CF(0, -0.25, 0) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(170, 30, 40)) end,
	TrollHeart = function(m) ball(m, 1.2, CF(-0.4, 0.3, 0), Color3.fromRGB(60, 150, 60)); ball(m, 1.2, CF(0.4, 0.3, 0), Color3.fromRGB(60, 150, 60)); P(m, Vector3.new(1.2, 1.2, 1), CF(0, -0.25, 0) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(60, 150, 60)) end,
	ManaPearl = function(m) ball(m, 1.6, CF(), Color3.fromRGB(120, 150, 255), Enum.Material.Neon); ball(m, 1.9, CF(), Color3.fromRGB(200, 210, 255), Enum.Material.Glass, 0.6) end,
	WarHorn = function(m) for i = 0, 4 do cyl(m, 1.2 - i * 0.2, 0.7, CF(i * 0.55, i * i * 0.08, 0) * CFrame.Angles(0, 0, -i * 0.18 + math.pi / 2), i == 0 and GOLDM or Color3.fromRGB(220, 206, 176)) end end,
	FrostShard = function(m) for i = 0, 2 do P(m, Vector3.new(0.6, 2.4 - i * 0.5, 0.6), CF(i * 0.4 - 0.4, 0, 0) * CFrame.Angles(0, i, (i - 1) * 0.3), Color3.fromRGB(170, 230, 255), Enum.Material.Ice, 0.15) end end,
	CountessFang = function(m) local w = Instance.new("WedgePart"); w.Anchored = true; w.Size = Vector3.new(0.6, 2.2, 0.8); w.Color = Color3.fromRGB(236, 230, 214); w.CFrame = CF() * CFrame.Angles(0, 0, math.pi); w.Parent = m; ball(m, 0.5, CF(0, 1.2, 0), Color3.fromRGB(170, 20, 50), Enum.Material.Neon) end,
	HareFoot = function(m) ell(m, Vector3.new(0.9, 2, 0.9), CF(), Color3.fromRGB(210, 200, 180), Enum.Material.Fabric); cyl(m, 0.7, 0.4, CF(0, 1.1, 0), GOLDM, Enum.Material.Metal) end,
	WindBoots = function(m) P(m, Vector3.new(0.9, 1.6, 1), CF(0, 0.3, 0), Color3.fromRGB(120, 90, 60), Enum.Material.Leather); P(m, Vector3.new(0.9, 0.6, 1.8), CF(0, -0.3, -0.4), Color3.fromRGB(110, 80, 54), Enum.Material.Leather); P(m, Vector3.new(0.1, 0.8, 0.9), CF(0.5, 0.5, 0.2), Color3.fromRGB(180, 230, 255), Enum.Material.Neon) end,
	GiantsBelt = function(m) P(m, Vector3.new(3.2, 0.7, 0.2), CF(), Color3.fromRGB(100, 70, 44), Enum.Material.Leather); P(m, Vector3.new(0.9, 0.9, 0.25), CF(0, 0, -0.05), GOLDM, Enum.Material.Metal) end,
	BerserkTotem = function(m) P(m, Vector3.new(0.9, 2.4, 0.9), CF(), Color3.fromRGB(120, 84, 50), Enum.Material.Wood); P(m, Vector3.new(1.4, 0.3, 0.3), CF(0, 0.7, -0.3), Color3.fromRGB(200, 40, 40)); ball(m, 0.35, CF(-0.2, 0.9, -0.45), Color3.fromRGB(255, 200, 60), Enum.Material.Neon); ball(m, 0.35, CF(0.2, 0.9, -0.45), Color3.fromRGB(255, 200, 60), Enum.Material.Neon) end,
	ThornMantle = function(m) for i = 0, 7 do local a = i / 8 * math.pi * 2; local w = Instance.new("WedgePart"); w.Anchored = true; w.Size = Vector3.new(0.3, 1, 0.3); w.Color = Color3.fromRGB(70, 100, 50); w.CFrame = CF(math.cos(a), math.sin(a), 0) * CFrame.Angles(0, 0, a - math.pi / 2); w.Parent = m end; ball(m, 1, CF(), Color3.fromRGB(80, 120, 60)) end,
	CrownShard = function(m) P(m, Vector3.new(1.8, 0.6, 0.3), CF(), GOLDM, Enum.Material.Metal); for i = -1, 1 do local w = Instance.new("WedgePart"); w.Anchored = true; w.Size = Vector3.new(0.3, 0.9, 0.4); w.Color = GOLDM; w.Material = Enum.Material.Metal; w.CFrame = CF(i * 0.6, 0.7, 0); w.Parent = m end; ball(m, 0.4, CF(0, 0, -0.2), Color3.fromRGB(220, 30, 60), Enum.Material.Neon) end,
}
SHAPES.relic = function(m, card)
	local f = RELIC_LOOK[card.relic or ""]
	if f then f(m) else pendant(m, DarkUI.RARITY[card.rarity] or Color3.fromRGB(255, 120, 40)) end
end
local TREASURE_LOOK = {
	SilverCup = function(m) cyl(m, 1.2, 1.4, CF(0, 0.5, 0), SILVER, Enum.Material.Metal); cyl(m, 0.4, 0.6, CF(0, -0.4, 0), SILVER, Enum.Material.Metal); cyl(m, 1, 0.15, CF(0, -0.75, 0), SILVER, Enum.Material.Metal) end,
	GoldGoblet = function(m) cyl(m, 1.3, 1.5, CF(0, 0.6, 0), GOLDM, Enum.Material.Metal); cyl(m, 0.35, 0.8, CF(0, -0.5, 0), GOLDM, Enum.Material.Metal); cyl(m, 1.1, 0.2, CF(0, -0.95, 0), GOLDM, Enum.Material.Metal); ball(m, 0.4, CF(0, 0.6, -0.62), Color3.fromRGB(220, 30, 60), Enum.Material.Neon) end,
	BronzeBell = function(m) for i = 0, 3 do cyl(m, 0.8 + i * 0.35, 0.4, CF(0, 0.8 - i * 0.4, 0), Color3.fromRGB(180, 120, 60), Enum.Material.Metal) end; ball(m, 0.35, CF(0, -0.8, 0), Color3.fromRGB(150, 100, 50), Enum.Material.Metal) end,
	Candelabra = function(m) cyl(m, 0.2, 2, CF(), Color3.fromRGB(200, 160, 80), Enum.Material.Metal); P(m, Vector3.new(2, 0.15, 0.15), CF(0, 0.5, 0), Color3.fromRGB(200, 160, 80), Enum.Material.Metal); for _, x in ipairs({-1, 0, 1}) do cyl(m, 0.25, 0.7, CF(x, 1.1, 0), Color3.fromRGB(236, 228, 200)); ball(m, 0.25, CF(x, 1.55, 0), Color3.fromRGB(255, 200, 100), Enum.Material.Neon) end; cyl(m, 0.9, 0.15, CF(0, -1, 0), Color3.fromRGB(200, 160, 80), Enum.Material.Metal) end,
	CoinPurse = function(m) ell(m, Vector3.new(1.8, 1.6, 1.8), CF(), Color3.fromRGB(130, 90, 56), Enum.Material.Leather); ell(m, Vector3.new(0.7, 0.6, 0.7), CF(0, 0.95, 0), Color3.fromRGB(120, 84, 50), Enum.Material.Leather); cyl(m, 0.8, 0.15, CF(0, 0.75, 0), GOLDM, Enum.Material.Metal); cyl(m, 0.7, 0.15, CF(0.9, -0.6, 0.3) * CFrame.Angles(0, 0, 1.2), GOLDM, Enum.Material.Metal) end,
	SilverRing = function(m) ring(m, 0.8, 0.22, CF() * CFrame.Angles(math.rad(70), 0, 0), SILVER, Enum.Material.Metal, 16); ball(m, 0.5, CF(0, 0.78, 0.28), Color3.fromRGB(110, 200, 255), Enum.Material.Neon) end,
	OldMap = function(m) cyl(m, 0.5, 2.6, CF(0, 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(220, 200, 150)); P(m, Vector3.new(2.4, 0.05, 1.6), CF(0, -0.2, 0.4) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(226, 208, 160)); P(m, Vector3.new(0.6, 0.06, 0.06), CF(0.3, -0.15, 0.3) * CFrame.Angles(math.rad(-30), 0.5, 0), Color3.fromRGB(150, 40, 30)) end,
	JadeFigure = function(m) P(m, Vector3.new(0.9, 1.4, 0.6), CF(0, -0.1, 0), Color3.fromRGB(70, 170, 110), Enum.Material.Marble); ball(m, 0.7, CF(0, 0.95, 0), Color3.fromRGB(70, 170, 110), Enum.Material.Marble); P(m, Vector3.new(1.3, 0.25, 0.8), CF(0, -0.9, 0), Color3.fromRGB(60, 150, 96), Enum.Material.Marble) end,
	Sapphire = function(m) local p = P(m, Vector3.new(1.2, 1.2, 1.2), CF() * CFrame.Angles(math.rad(45), 0, math.rad(45)), Color3.fromRGB(40, 90, 230), Enum.Material.Glass, 0.15); local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Scale = Vector3.new(0.9, 1.3, 0.9); mesh.Parent = p; ball(m, 0.6, CF(), Color3.fromRGB(80, 140, 255), Enum.Material.Neon) end,
	GildedUrn = function(m) ell(m, Vector3.new(1.6, 2, 1.6), CF(), Color3.fromRGB(150, 84, 52), Enum.Material.Slate); cyl(m, 0.8, 0.7, CF(0, 1.2, 0), Color3.fromRGB(150, 84, 52), Enum.Material.Slate); cyl(m, 1.7, 0.25, CF(0, 0.2, 0), GOLDM, Enum.Material.Metal); cyl(m, 1, 0.2, CF(0, 1.6, 0), GOLDM, Enum.Material.Metal) end,
	RubyCirclet = function(m) ring(m, 1.1, 0.2, CF() * CFrame.Angles(math.rad(60), 0, 0), GOLDM, Enum.Material.Metal, 18); for i = -1, 1 do ball(m, 0.4, CF(i * 0.6, 0.95, 0.5 - math.abs(i) * 0.2), Color3.fromRGB(220, 30, 60), Enum.Material.Neon) end end,
	GoldenIdol = function(m) P(m, Vector3.new(1, 1.6, 0.7), CF(0, -0.1, 0), GOLDM, Enum.Material.Metal); ball(m, 0.9, CF(0, 1.05, 0), GOLDM, Enum.Material.Metal); P(m, Vector3.new(1.5, 0.3, 1), CF(0, -1, 0), Color3.fromRGB(190, 150, 60), Enum.Material.Metal); ball(m, 0.22, CF(-0.2, 1.1, -0.42), Color3.fromRGB(80, 220, 120), Enum.Material.Neon); ball(m, 0.22, CF(0.2, 1.1, -0.42), Color3.fromRGB(80, 220, 120), Enum.Material.Neon) end,
	DragonPearl = function(m) ball(m, 1.8, CF(), Color3.fromRGB(255, 140, 60), Enum.Material.Neon); ball(m, 2.1, CF(), Color3.fromRGB(255, 220, 180), Enum.Material.Glass, 0.6); ring(m, 1.15, 0.15, CF(0, -0.6, 0), GOLDM, Enum.Material.Metal, 14) end,
	KingsSigil = function(m) cyl(m, 2, 0.3, CF() * CFrame.Angles(math.rad(70), 0, 0), GOLDM, Enum.Material.Metal); cyl(m, 1.3, 0.32, CF() * CFrame.Angles(math.rad(70), 0, 0), Color3.fromRGB(140, 20, 30), Enum.Material.Metal); P(m, Vector3.new(0.3, 0.9, 0.36), CF(0, 0.05, -0.08) * CFrame.Angles(math.rad(-20), 0, 0), GOLDM, Enum.Material.Metal) end,
}
SHAPES.treasure = function(m, card)
	local f = TREASURE_LOOK[card.treasure or ""]
	if f then f(m) else ball(m, 1.4, CF(), DarkUI.RARITY[card.rarity] or GOLDM, Enum.Material.Neon) end
end
SHAPES.weapon = function(m, card)
	local t = card.weapon and Catalog.weaponModel(card.weapon)
	if not t then P(m, Vector3.new(0.3, 4, 0.1), CF(), SILVER, Enum.Material.Metal); return end
	local c = t:Clone()
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Trail") then d:Destroy() end
	end
	if card.skin and Catalog.SKIN and Catalog.SKIN[card.skin] then pcall(Dresser.applySkin, c, card.skin, nil) end
	for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
	for _, d in ipairs(c:GetChildren()) do d.Parent = m end
	c:Destroy()
end
-- the loot's armour: its set's coat (Catalog ▸ Loot ARMOR set)
SHAPES.armor = function(m, card)
	local a = Catalog.LOOT.ARMOR_BY and Catalog.LOOT.ARMOR_BY[card.armor or ""]
	local done = false
	if a and a.set then
		for _, pc in ipairs(Catalog.setPieces(a.set)) do
			if pc.slot == "top" then
				local models = Catalog.pieceModels(pc.id)
				local tm = models.TorsoClothing
				if tm then
					local c = tm:Clone()
					for _, d in ipairs(c:GetDescendants()) do
						if d:IsA("LuaSourceContainer") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
					end
					c.Parent = m
					done = true
				end
			end
		end
	end
	if not done then
		local col = Color3.fromRGB(150, 156, 166)
		P(m, Vector3.new(2, 2.2, 1), CF(), col, Enum.Material.Metal)
		P(m, Vector3.new(2.8, 0.6, 1.2), CF(0, 0.9, 0), col:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Metal)
		P(m, Vector3.new(2.1, 0.25, 1.05), CF(0, -0.4, 0), DarkUI.RARITY[card.rarity] or GOLDM, Enum.Material.Metal)
	end
end

-- the model for a card (built once per look, copied after)
local function modelFor(card)
	local key = table.concat({card.kind or "", card.weapon or "", card.skin or "", card.potion or "", card.relic or "", card.treasure or "", card.armor or "", card.rarity or ""}, "|")
	local tpl = cache[key]
	if not tpl then
		tpl = Instance.new("Model")
		local f = SHAPES[card.kind or ""] or SHAPES.treasure
		local ok, err = pcall(f, tpl, card)
		if not ok then warn("[DarkUI] icon", card.kind, err) end
		cache[key] = tpl
	end
	return tpl:Clone(), key
end

-- AN ITEM, ITSELF: a ViewportFrame with its model, turned to show it best and framed to fit
function DarkUI.icon(parent, card, opts)
	opts = opts or {}
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Icon"
	vp.BackgroundTransparency = 1
	vp.Size = opts.size or UDim2.fromScale(1, 1)
	vp.Position = opts.pos or UDim2.new()
	vp.Ambient = Color3.fromRGB(150, 140, 126)
	vp.LightColor = Color3.fromRGB(255, 238, 210)
	vp.LightDirection = Vector3.new(-0.6, -1, -0.7)
	vp.ZIndex = opts.z or 2
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.FieldOfView = 26; cam.Parent = vp
	vp.CurrentCamera = cam
	local m = modelFor(card)
	m.Parent = world
	local ok, cf, size = pcall(function() return m:GetBoundingBox() end)
	if ok then
		if card.kind == "weapon" then
			-- (its longest side across the slot's diagonal, or upright in a tall slot)
			local axis = (size.X >= size.Y and size.X >= size.Z) and Vector3.xAxis or (size.Y >= size.Z and Vector3.yAxis or Vector3.zAxis)
			local along = cf:VectorToWorldSpace(axis)
			local up = math.abs(along.Y) < 0.9 and Vector3.yAxis or Vector3.zAxis
			local vy = (up - along * up:Dot(along)).Unit
			local box = CFrame.fromMatrix(cf.Position, along, vy)
			local tilt = opts.upright and CFrame.Angles(0, 0, math.rad(-90)) or CFrame.Angles(0, 0, math.rad(-45))
			m:PivotTo(tilt * box:Inverse() * m:GetPivot())
		else
			m:PivotTo(CFrame.Angles(0, math.rad(opts.yaw or 25), 0) * CFrame.new(-cf.Position) * m:GetPivot())
		end
		local _, sz2 = m:GetBoundingBox()
		local r = math.max(sz2.X, sz2.Y, sz2.Z, 0.5) * 0.5
		local d = r / math.tan(math.rad(13)) * (opts.zoom or 1.05) * (card.kind == "weapon" and not opts.upright and 0.78 or 1)
		cam.CFrame = CFrame.lookAt(Vector3.new(0, d * 0.18, -d), Vector3.zero)
	end
	vp.Parent = parent
	return vp
end

--------------------------------------------------------------------
--  A TOOLTIP: what a thing is, following the mouse
--------------------------------------------------------------------
function DarkUI.tooltip(gui)
	local tip = {}
	local f = DarkUI.panel(gui, {corners = false})
	f.Name = "Tooltip"
	f.Visible = false
	f.ZIndex = 50
	f.Size = UDim2.fromOffset(280, 120)
	f.AutomaticSize = Enum.AutomaticSize.Y
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10); pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14); pad.Parent = f
	local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 4); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = f
	local name = DarkUI.text(f, "", 18, C.TEXT, Enum.FontWeight.Bold)
	name.Size = UDim2.new(1, 0, 0, 22); name.TextXAlignment = Enum.TextXAlignment.Left; name.LayoutOrder = 1; name.ZIndex = 51
	name.TextWrapped = true; name.AutomaticSize = Enum.AutomaticSize.Y
	local sub = DarkUI.text(f, "", 13, C.DIM)
	sub.Size = UDim2.new(1, 0, 0, 16); sub.TextXAlignment = Enum.TextXAlignment.Left; sub.LayoutOrder = 2; sub.ZIndex = 51
	local body = DarkUI.text(f, "", 13, C.TEXT)
	body.Size = UDim2.new(1, 0, 0, 0); body.AutomaticSize = Enum.AutomaticSize.Y; body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left; body.TextYAlignment = Enum.TextYAlignment.Top; body.LayoutOrder = 3; body.ZIndex = 51
	local foot = DarkUI.text(f, "", 13, C.GOLD2, Enum.FontWeight.Bold)
	foot.Size = UDim2.new(1, 0, 0, 18); foot.TextXAlignment = Enum.TextXAlignment.Left; foot.LayoutOrder = 4; foot.ZIndex = 51
	for _, d in ipairs(f:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = math.max(d.ZIndex, 50) end end
	function tip:show(card, extra)
		if not card then return self:hide() end
		name.Text = card.name or ""
		name.TextColor3 = DarkUI.RARITY[card.rarity] or C.TEXT
		sub.Text = card.sub or ""
		body.Text = table.concat(card.lines or {}, "\n")
		foot.Text = extra or ((card.value or 0) > 0 and ("Worth " .. card.value .. " gold") or "")
		foot.Visible = foot.Text ~= ""
		f.Visible = true
	end
	function tip:hide() f.Visible = false end
	RunService.RenderStepped:Connect(function()
		if not f.Visible then return end
		local m = UserInputService:GetMouseLocation()
		local scale = gui:FindFirstChildOfClass("UIScale")
		local k = scale and scale.Scale or 1
		local vs = workspace.CurrentCamera.ViewportSize
		local x, y = m.X / k + 18, m.Y / k - 10
		if x + 290 > vs.X / k then x = m.X / k - 300 end
		if y + f.AbsoluteSize.Y / k > vs.Y / k - 10 then y = vs.Y / k - f.AbsoluteSize.Y / k - 10 end
		f.Position = UDim2.fromOffset(x, y)
	end)
	tip.frame = f
	return tip
end

return DarkUI
