--[[ CONTAINERS — Deadvault's things to search (Game ▸ Modes ▸ Deadvault): crates, barrels, sacks,
     urns, weapon racks, armour stands, bookshelves, sarcophagi, what's left of those who came
     before, chests (plain, ornate, the hoard), and a fallen raider's pack. Each holds a few
     things (Catalog ▸ Loot CONTAINERS, rolled the first time anyone opens it, for their class),
     shared: whoever takes a thing first has it.

       Containers.new(mode)                    a raid's set
       set:add(kind, cf[, opts]) -> box        opts.items (a fallen raider's: given, not rolled),
                                               opts.name, opts.luck
       set:open(plr, box)                      (its prompt) -> the loot window, AdventureEvent "Loot"
       set:take(plr, id, uid) · set:takeAll(plr, id)   the window's asks: the mode's take(plr, item)
                                               decides where it goes (false: it stays)
       set:clear()

     Opening a chest is loud (Combat ▸ Perception.noise): the dark hears it. A sarcophagus's dead
     isn't always resting: on the first look the mode's waken(box, char) may raise it, and then
     the lid is thrown off, it climbs out, and there's no searching it till it's dealt with. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Loot = require(script.Parent:WaitForChild("Loot"))
local Perception = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Perception"))

local CFG = Catalog.LOOT
local Containers = {}
Containers.__index = Containers

local REACH = 14
local HOLD = {crate = 0.8, barrel = 0.6, sack = 0.6, urn = 0.7, rack = 0.6, stand = 0.6, shelf = 1, coffin = 1.6, remains = 0.8,
	chest = 1.2, ornate = 2, hoard = 2.6, pack = 1.2, corpse = 1}
local LOUD = {chest = 22, ornate = 30, hoard = 40, coffin = 18}
local WOOD, DARKWOOD, IRON = Color3.fromRGB(124, 86, 52), Color3.fromRGB(84, 58, 34), Color3.fromRGB(70, 70, 76)
local BONE = Color3.fromRGB(226, 218, 196)

local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function rootOf(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function alive(c) local h = c and c:FindFirstChildOfClass("Humanoid"); return h ~= nil and h.Health > 0 end
local folder = workspace:FindFirstChild("LootDrops") or Instance.new("Folder")
folder.Name = "LootDrops"; folder.Parent = workspace

--------------------------------------------------------------------
--  THE LOOKS
--------------------------------------------------------------------
local function part(m, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanTouch = true, true, false
	p.Size, p.Color, p.Material = size, color, mat or Enum.Material.Wood
	if shape then p.Shape = shape end
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CFrame = cf
	p.Parent = m
	return p
end
local function cyl(m, name, d, h, cf, color, mat)
	return part(m, name, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.pi / 2), color, mat, Enum.PartType.Cylinder)
end
local function ellipsoid(m, name, size, cf, color, mat)
	local p = part(m, name, size, cf, color, mat)
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p
	return p
end

local LOOKS = {}
LOOKS.crate = function(m, cf)
	local s = 3
	local b = part(m, "Body", Vector3.new(s, s, s), cf * CFrame.new(0, s / 2, 0), WOOD, Enum.Material.WoodPlanks)
	for _, a in ipairs({0, 90}) do
		local band = part(m, "Band", Vector3.new(s + 0.1, 0.3, s + 0.1), b.CFrame * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, s * 0.3, 0), DARKWOOD)
		band.CanCollide = false
	end
	return b
end
LOOKS.barrel = function(m, cf)
	local b = cyl(m, "Body", 2.4, 3.2, cf * CFrame.new(0, 1.6, 0), WOOD, Enum.Material.Wood)
	for _, y in ipairs({0.6, 2.6}) do cyl(m, "Hoop", 2.5, 0.2, cf * CFrame.new(0, y, 0), IRON, Enum.Material.Metal).CanCollide = false end
	cyl(m, "Lid", 2.2, 0.1, cf * CFrame.new(0, 3.22, 0), DARKWOOD, Enum.Material.WoodPlanks).CanCollide = false
	return b
end
LOOKS.sack = function(m, cf)
	local b = ellipsoid(m, "Body", Vector3.new(2.4, 2.2, 2.2), cf * CFrame.new(0, 1.05, 0), Color3.fromRGB(150, 120, 80), Enum.Material.Fabric)
	ellipsoid(m, "Neck", Vector3.new(0.9, 0.7, 0.9), cf * CFrame.new(0, 2.2, 0), Color3.fromRGB(130, 100, 66), Enum.Material.Fabric).CanCollide = false
	cyl(m, "Tie", 0.75, 0.15, cf * CFrame.new(0, 2.05, 0), Color3.fromRGB(90, 66, 40), Enum.Material.Fabric).CanCollide = false
	return b
end
LOOKS.urn = function(m, cf)
	local clay = Color3.fromRGB(150, 84, 52)
	local b = ellipsoid(m, "Body", Vector3.new(2, 2.6, 2), cf * CFrame.new(0, 1.3, 0), clay, Enum.Material.Slate)
	cyl(m, "Neck", 1, 0.9, cf * CFrame.new(0, 2.8, 0), clay, Enum.Material.Slate).CanCollide = false
	cyl(m, "Lip", 1.3, 0.2, cf * CFrame.new(0, 3.25, 0), Color3.fromRGB(200, 170, 80), Enum.Material.Metal).CanCollide = false
	cyl(m, "Band", 2.05, 0.25, cf * CFrame.new(0, 1.6, 0), Color3.fromRGB(200, 170, 80), Enum.Material.Metal).CanCollide = false
	return b
end
LOOKS.rack = function(m, cf)
	for _, x in ipairs({-2.2, 2.2}) do part(m, "RackPost", Vector3.new(0.4, 3.6, 0.4), cf * CFrame.new(x, 1.8, 0), DARKWOOD) end
	local b = part(m, "Body", Vector3.new(5, 0.35, 0.35), cf * CFrame.new(0, 3, 0), DARKWOOD)
	part(m, "RackFoot", Vector3.new(5, 0.3, 1.4), cf * CFrame.new(0, 0.15, 0.4), DARKWOOD)
	-- what leans on it: a blade or two, a haft
	for i, x in ipairs({-1.2, 0, 1.3}) do
		local steel = part(m, "Blade", Vector3.new(0.2, 3.2 - i * 0.3, 0.06), cf * CFrame.new(x, 1.8, -0.25) * CFrame.Angles(0, 0, math.rad(6)), Color3.fromRGB(190, 194, 200), Enum.Material.Metal)
		steel.CanCollide = false
	end
	return b
end
LOOKS.stand = function(m, cf)
	part(m, "StandFoot", Vector3.new(2.2, 0.3, 2.2), cf * CFrame.new(0, 0.15, 0), DARKWOOD)
	part(m, "StandPost", Vector3.new(0.35, 5, 0.35), cf * CFrame.new(0, 2.5, 0), DARKWOOD)
	local b = part(m, "Body", Vector3.new(2.6, 2.4, 1.2), cf * CFrame.new(0, 3.6, 0), Color3.fromRGB(150, 156, 166), Enum.Material.Metal)
	part(m, "Pauldron", Vector3.new(3.4, 0.6, 1.4), cf * CFrame.new(0, 4.8, 0), Color3.fromRGB(130, 136, 146), Enum.Material.Metal).CanCollide = false
	ellipsoid(m, "Helm", Vector3.new(1.2, 1.4, 1.2), cf * CFrame.new(0, 5.6, 0), Color3.fromRGB(140, 146, 156), Enum.Material.Metal).CanCollide = false
	return b
end
LOOKS.shelf = function(m, cf)
	local b = part(m, "Body", Vector3.new(6, 9, 1.6), cf * CFrame.new(0, 4.5, 0), Color3.fromRGB(80, 50, 32), Enum.Material.Wood)
	local rng = Random.new(math.floor(cf.Position.X * 7 + cf.Position.Z))
	for row = 0, 3 do
		local x = -2.6
		while x < 2.4 do
			local w = rng:NextNumber(0.3, 0.6)
			local bk = part(m, "Book", Vector3.new(w, rng:NextNumber(1.1, 1.6), 1.2), cf * CFrame.new(x + w / 2, 1.3 + row * 2.1, -0.3), Color3.fromHSV(rng:NextNumber(), 0.5, 0.5), Enum.Material.Fabric)
			bk.CanCollide = false
			x += w + 0.05
		end
	end
	-- (a glint: something on it worth taking)
	local g = part(m, "Glint", Vector3.new(0.4, 0.4, 0.4), cf * CFrame.new(1.8, 5.6, -0.7), Color3.fromRGB(255, 220, 120), Enum.Material.Neon)
	g.CanCollide = false
	return b
end
LOOKS.coffin = function(m, cf)
	local stone = Color3.fromRGB(150, 146, 140)
	local b = part(m, "Body", Vector3.new(3.4, 2.4, 7), cf * CFrame.new(0, 1.2, 0), stone, Enum.Material.Marble)
	local lid = part(m, "Lid", Vector3.new(3.8, 0.6, 7.4), cf * CFrame.new(0, 2.7, 0), Color3.fromRGB(130, 126, 120), Enum.Material.Marble)
	lid:SetAttribute("Slides", true)
	part(m, "Effigy", Vector3.new(1.6, 0.5, 4.6), cf * CFrame.new(0, 3.2, 0.4), Color3.fromRGB(160, 156, 150), Enum.Material.Marble).CanCollide = false
	return b
end
LOOKS.remains = function(m, cf)
	-- a skeleton slumped by its pack
	ellipsoid(m, "Skull", Vector3.new(0.9, 0.9, 1), cf * CFrame.new(-1.2, 0.45, 0), BONE, Enum.Material.SmoothPlastic).CanCollide = false
	part(m, "Ribs", Vector3.new(1.4, 0.5, 1.8), cf * CFrame.new(0, 0.3, 0.2), BONE, Enum.Material.SmoothPlastic).CanCollide = false
	for _, z in ipairs({-0.6, 0.6}) do part(m, "Bone", Vector3.new(2.2, 0.25, 0.25), cf * CFrame.new(1.4, 0.15, z) * CFrame.Angles(0, z * 0.4, 0), BONE, Enum.Material.SmoothPlastic).CanCollide = false end
	local b = ellipsoid(m, "Body", Vector3.new(1.6, 1.3, 1.2), cf * CFrame.new(0.2, 0.65, -1.4), Color3.fromRGB(110, 80, 50), Enum.Material.Fabric)
	b.CanCollide = false
	part(m, "Rust", Vector3.new(0.3, 0.12, 3), cf * CFrame.new(-0.4, 0.08, 1.3) * CFrame.Angles(0, 0.5, 0), Color3.fromRGB(120, 90, 70), Enum.Material.CorrodedMetal).CanCollide = false
	return b
end
-- a monster's body (it lies there itself: this is only where you search it)
LOOKS.corpse = function(m, cf)
	local b = part(m, "Body", Vector3.new(4, 2.4, 4), cf * CFrame.new(0, 1.2, 0), Color3.new(0, 0, 0))
	b.Transparency, b.CanCollide = 1, false
	return b
end
LOOKS.pack = function(m, cf)
	local b = ellipsoid(m, "Body", Vector3.new(2, 1.6, 1.4), cf * CFrame.new(0, 0.8, 0), Color3.fromRGB(96, 70, 46), Enum.Material.Leather)
	part(m, "Strap", Vector3.new(0.3, 1.7, 1.5), cf * CFrame.new(0.4, 0.85, 0), Color3.fromRGB(60, 42, 28), Enum.Material.Leather).CanCollide = false
	local glow = part(m, "Glow", Vector3.new(0.5, 0.5, 0.5), cf * CFrame.new(0, 1.8, 0), Color3.fromRGB(255, 220, 120), Enum.Material.Neon)
	glow.CanCollide = false; glow.Shape = Enum.PartType.Ball
	return b
end

--------------------------------------------------------------------
--  THE SET
--------------------------------------------------------------------
function Containers.new(mode)
	return setmetatable({mode = mode, boxes = {}, n = 0}, Containers)
end

function Containers:add(kind, cf, opts)
	opts = opts or {}
	self.n += 1
	local id = self.n
	local def = CFG.CONTAINERS[kind]
	local name = opts.name or (def and def.name) or "Pack"
	local box = {id = id, kind = kind, cf = cf, pos = cf.Position, items = opts.items, luck = opts.luck or 0, name = name, opened = {}}
	local body, model, chest
	if kind == "chest" or kind == "ornate" or kind == "hoard" then
		chest = Loot.chest(cf, {rarity = kind == "hoard" and "Legendary" or (kind == "ornate" and "Epic" or "Uncommon"), gilded = kind ~= "chest", los = true,
			label = name, hold = HOLD[kind], onOpen = function(plr) self:open(plr, box); return false end})
		model = chest.model
		body = model:FindFirstChild("Body")
		box.chest = chest
	else
		model = Instance.new("Model")
		model.Name = "Container"
		body = (LOOKS[kind] or LOOKS.crate)(model, cf)
		model.PrimaryPart = body
		model.Parent = folder
		local pr = Instance.new("ProximityPrompt")
		pr.Name = "SearchPrompt"
		pr.ActionText = (kind == "pack" or kind == "corpse") and "Loot" or "Search"
		pr.ObjectText = name
		pr.KeyboardKeyCode = Enum.KeyCode.V
		pr:SetAttribute("PickupKey", true)
		pr.HoldDuration = HOLD[kind] or 0.8
		pr.MaxActivationDistance = 9
		pr.RequiresLineOfSight = true
		pr.Parent = body
		pr.Triggered:Connect(function(plr) self:open(plr, box) end)
		box.prompt = pr
	end
	model:SetAttribute("Kind", kind)
	model:SetAttribute("BoxId", id)
	box.model, box.body = model, body
	self.boxes[id] = box
	return box
end

local function cards(box)
	local out = {}
	for _, it in ipairs(box.items or {}) do table.insert(out, Loot.card(it)) end
	return out
end

-- what it holds, on the opener's screen (and on everyone's who has it open)
function Containers:show(plr, box)
	local e = event()
	if not e then return end
	e:FireClient(plr, "Loot", {id = box.id, name = box.name, kind = box.kind, pos = box.pos, items = cards(box)})
end
function Containers:refresh(box)
	for plr in pairs(box.opened) do
		if plr.Parent and box.watch and box.watch[plr] then self:show(plr, box) end
	end
	local empty = box.items and #box.items == 0
	if empty and not box.emptied then
		box.emptied = true
		box.model:SetAttribute("Empty", true)
		if box.prompt then box.prompt.ObjectText = box.name .. " (empty)" end
		if box.chest and box.chest.seam then
			box.chest.seam.Transparency = 1
			local l = box.chest.seam:FindFirstChildOfClass("PointLight"); if l then l.Enabled = false end
			local pe = box.chest.seam:FindFirstChildOfClass("ParticleEmitter"); if pe then pe.Enabled = false end
		end
		local g = box.model:FindFirstChild("Glint") or box.model:FindFirstChild("Glow")
		if g then g.Transparency = 1 end
	end
end

function Containers:open(plr, box)
	local char = plr.Character
	if not (alive(char) and rootOf(char)) then return end
	if (rootOf(char).Position - box.pos).Magnitude > REACH then return end
	if not box.items then
		local classId = char:GetAttribute("Class") or "Knight"
		box.items = Loot.container(box.kind, classId, box.luck + Loot.luckOf(char))
	end
	-- the first look: the lid comes up, a coffin's slides aside, the dark hears a chest
	if not box.looked then
		box.looked = true
		if box.chest and box.chest.swing then box.chest.swing() end
		local lid = box.model:FindFirstChild("Lid")
		local woke = box.kind == "coffin" and self.mode and self.mode.waken and self.mode:waken(box, char)
		if lid and lid:GetAttribute("Slides") then
			-- (slid aside; or, its dead awake, thrown off to land against its side) with the effigy
			-- carved on it
			-- (thrown towards the one who opened it: its dead climbs out of the far side)
			local sx = (rootOf(char).Position - box.pos):Dot(lid.CFrame.RightVector) < 0 and -1 or 1
			local to = woke and lid.CFrame * CFrame.new(3.6 * sx, -1.2, 0.4) * CFrame.Angles(0, math.rad(12), math.rad(-72 * sx))
				or lid.CFrame * CFrame.new(1.6, 0.2, 1.2) * CFrame.Angles(0, math.rad(18), 0)
			local info = woke and TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or TweenInfo.new(0.9, Enum.EasingStyle.Quad)
			if woke then lid.CanCollide = false end
			local effigy = box.model:FindFirstChild("Effigy")
			if effigy then TweenService:Create(effigy, info, {CFrame = to * lid.CFrame:ToObjectSpace(effigy.CFrame)}):Play() end
			TweenService:Create(lid, info, {CFrame = to}):Play()
		end
		if LOUD[box.kind] then Perception.noise(box.pos, LOUD[box.kind], char) end
		if woke then return end
	end
	box.opened[plr] = true
	box.watch = box.watch or {}
	box.watch[plr] = true
	box.model:SetAttribute("OpenedBy_" .. plr.UserId, true)
	self:show(plr, box)
	self:refresh(box)
end

local function near(plr, box)
	local r = rootOf(plr.Character)
	return alive(plr.Character) and r and (r.Position - box.pos).Magnitude <= REACH + 2
end

function Containers:take(plr, id, uid)
	local box = self.boxes[id]
	if not (box and box.items and near(plr, box)) then return false end
	for i, it in ipairs(box.items) do
		if it.uid == uid then
			local ok = self.mode:take(plr, it, box.pos)
			if ok then table.remove(box.items, i) end
			self:refresh(box)
			if not (box.watch and box.watch[plr]) then self:show(plr, box) end
			return ok
		end
	end
	self:show(plr, box)
	return false
end
function Containers:takeAll(plr, id)
	local box = self.boxes[id]
	if not (box and box.items and near(plr, box)) then return end
	local i = 1
	while i <= #box.items do
		if self.mode:take(plr, box.items[i], box.pos, true) then table.remove(box.items, i) else i += 1 end
	end
	self:refresh(box)
end
function Containers:close(plr, id)
	local box = self.boxes[id]
	if box and box.watch then box.watch[plr] = nil end
end

function Containers:clear()
	for _, box in pairs(self.boxes) do if box.model then box.model:Destroy() end end
	self.boxes = {}
end

return Containers
