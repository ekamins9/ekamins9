--[[ HORDE OBJECTIVE — what the players defend in a Horde (Game ▸ Modes ▸ Horde). The horde
     goes for it; when it falls, the round is lost. Built from parts (Build ▸ MapKit,
     MapProps) where the map says (Map ▸ Spots ▸ HordeObjective, a Part; its Kind attribute
     wins over the mode's `objectives` list), else on the clearest open ground near the
     middle of the map (the centre of its Horde gates).

       HordeObjective.build(kind, map, maxHp) -> obj
           kind  "Campfire" (a camp: the fire, benches, bedrolls, a tent) | "Caravan" (a
                 covered wagon and its cargo) | "Villagers" (four villagers round a well)
       obj.pos, obj.radius (how far out the horde stands to strike it), obj.name ("THE CAMPFIRE")
       obj.hp, obj.max, obj.lastHitAt (os.clock)
       obj:hit(n, from)     a blow (from = where it came from: sparks there, a thump)
       obj:repair(frac)     between waves: back up by frac of its whole
       obj:health()         0..1
       obj:destroy()

     As it wears down you can see it: the fire sinks and smokes, the wagon smokes, then burns,
     then its canvas is gone; the villagers fall one by one (and get back up when it's mended). ]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Sounds = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))

local K
local function kit()
	if not K then
		local build = ServerScriptService:WaitForChild("Build")
		K = require(build:WaitForChild("MapKit"))
		if not K.wagon then require(build:WaitForChild("MapProps"))(K) end
	end
	return K
end

local NAMES = {Campfire = "THE CAMPFIRE", Caravan = "THE CARAVAN", Villagers = "THE VILLAGERS"}
local RADIUS = {Campfire = 3.6, Caravan = 6.4, Villagers = 5.2}
local V3 = Vector3.new
local DEG = math.rad

local Obj = {}
Obj.__index = Obj
local HordeObjective = {NAMES = NAMES}

--------------------------------------------------------------------
--  WHERE: the map's spot, or open ground near the middle
--------------------------------------------------------------------
local function excludes(map)
	local list = {}
	for _, n in ipairs({"NPCs", "Corpses", "DroppedWeapons", "StuckArrows", "MagicFX"}) do
		local f = workspace:FindFirstChild(n); if f then table.insert(list, f) end
	end
	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do if p.Character then table.insert(list, p.Character) end end
	for _, n in ipairs({"Spots", "Zones", "Spawns", "MenuCameras"}) do
		local f = map and map:FindFirstChild(n); if f then table.insert(list, f) end
	end
	return list
end
-- the ground at (x, z): terrain or a floor (something wide both ways: not the top of a wall,
-- a wagon's side or a crate)
local function groundAt(x, z, top, ex)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = ex
	rp.RespectCanCollide = true
	local hit = workspace:Raycast(V3(x, top, z), V3(0, -top - 200, 0), rp)
	if not (hit and hit.Normal.Y > 0.75) then return nil end
	local p = hit.Instance
	if not p:IsA("Terrain") then
		local cf, sz = p.CFrame, p.Size
		local ex2 = math.abs(cf.RightVector.X) * sz.X + math.abs(cf.UpVector.X) * sz.Y + math.abs(cf.LookVector.X) * sz.Z
		local ez2 = math.abs(cf.RightVector.Z) * sz.X + math.abs(cf.UpVector.Z) * sz.Y + math.abs(cf.LookVector.Z) * sz.Z
		if ex2 < 8 or ez2 < 8 then return nil end
	end
	return hit.Position, p
end
-- is there room for it here (nothing standing in a box w wide, up to 6 high)?
local function roomy(pos, w, ex, ground)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = ex
	for _, p in ipairs(workspace:GetPartBoundsInBox(CFrame.new(pos + V3(0, 3.6, 0)), V3(w, 6, w), op)) do
		if p ~= ground and p.CanCollide and p.Transparency < 1 and not p:IsA("Terrain") then
			local cf, sz = p.CFrame, p.Size
			local ey = math.abs(cf.RightVector.Y) * sz.X / 2 + math.abs(cf.UpVector.Y) * sz.Y / 2 + math.abs(cf.LookVector.Y) * sz.Z / 2
			if p.Position.Y + ey > pos.Y + 0.9 then return false end   -- (a floor tile beside the ground is no bother)
		end
	end
	return true
end
function HordeObjective.place(map, w)
	local ex = excludes(map)
	local spots = map and map:FindFirstChild("Spots")
	local spot = spots and spots:FindFirstChild("HordeObjective")
	if spot then
		local g = groundAt(spot.Position.X, spot.Position.Z, spot.Position.Y + 6, ex)
		return g or spot.Position, spot:GetAttribute("Kind")
	end
	-- the middle: the centre of the gates (they ring it, three studs up), else the map's own
	-- centre. On the ground there, not on a roof: the rays start a little above ground level
	-- (under any roof) and the floor they find must be at that level.
	local sum, n = Vector3.zero, 0
	for _, s in ipairs(spots and spots:GetChildren() or {}) do
		if s.Name:match("^HordeGate") then sum += s.Position; n += 1 end
	end
	local c = n > 0 and sum / n - V3(0, 3, 0) or (map and map:GetPivot().Position or Vector3.zero)
	local level = c.Y
	for ring = 0, 12 do
		local steps = ring == 0 and 1 or 12
		for k = 0, steps - 1 do
			local a = k / steps * math.pi * 2 + ring * 0.7
			local x, z = c.X + math.cos(a) * ring * 5, c.Z + math.sin(a) * ring * 5
			local g, part = groundAt(x, z, level + 7, ex)
			if g and math.abs(g.Y - level) < 4 and roomy(g, w, ex, part) then return g end
		end
	end
	local g = groundAt(c.X, c.Z, level + 7, ex)
	return g or c
end

--------------------------------------------------------------------
--  THE LOOKS
--------------------------------------------------------------------
-- a villager from parts (a blocky R6 body, no Humanoid: blades pass it by), in its own model
local SKIN = {Color3.fromRGB(234, 196, 160), Color3.fromRGB(198, 150, 110), Color3.fromRGB(142, 98, 68), Color3.fromRGB(246, 214, 182)}
local TUNIC = {Color3.fromRGB(122, 92, 60), Color3.fromRGB(86, 112, 70), Color3.fromRGB(70, 92, 128), Color3.fromRGB(150, 70, 60), Color3.fromRGB(176, 150, 104)}
local function villager(ctx, frame, look, parent)
	local Kt = kit()
	local m = Instance.new("Model"); m.Name = "Villager"; m.Parent = parent
	local s = look.scale or 1
	local function part(name, size, at, color, mat)
		local p = Kt.box(ctx, name, size * s, frame * CFrame.new(at * s), color, mat or Enum.Material.SmoothPlastic, m)
		p.CanCollide = false
		return p
	end
	local skin, tunic = look.skin, look.tunic
	part("LeftLeg", V3(1, 2, 1), V3(-0.5, 1, 0), look.legs or Color3.fromRGB(70, 60, 52))
	part("RightLeg", V3(1, 2, 1), V3(0.5, 1, 0), look.legs or Color3.fromRGB(70, 60, 52))
	local torso = part("Torso", V3(2, 2, 1), V3(0, 3, 0), tunic, Enum.Material.Fabric)
	torso.CanCollide = true
	part("Belt", V3(2.05, 0.3, 1.05), V3(0, 2.2, 0), Color3.fromRGB(60, 42, 28), Enum.Material.Leather)
	part("LeftArm", V3(1, 2, 1), V3(-1.5, 3, 0), look.sleeves or tunic, Enum.Material.Fabric)
	local ra = look.raise and part("RightArm", V3(1, 2, 1), V3(1.5, 3.25, -0.35), look.sleeves or tunic, Enum.Material.Fabric)
		or part("RightArm", V3(1, 2, 1), V3(1.5, 3, 0), look.sleeves or tunic, Enum.Material.Fabric)
	if look.raise then ra.CFrame = ra.CFrame * CFrame.Angles(DEG(35), 0, 0) end   -- (gripping the pitchfork)
	local head = part("Head", V3(2, 1, 1), V3(0, 4.5, 0), skin)
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Head; mesh.Scale = V3(1.25, 1.25, 1.25); mesh.Parent = head
	local face = Instance.new("Decal"); face.Name = "face"; face.Texture = "rbxasset://textures/face.png"; face.Face = Enum.NormalId.Front; face.Parent = head
	if look.hat == "straw" then
		local brim = Kt.cyl(ctx, "HatBrim", 2.9 * s, 0.14 * s, frame * CFrame.new(V3(0, 5.15, 0) * s), Color3.fromRGB(214, 186, 112), Enum.Material.Fabric, m)
		local crown = Kt.cyl(ctx, "HatCrown", 1.5 * s, 0.6 * s, frame * CFrame.new(V3(0, 5.45, 0) * s), Color3.fromRGB(204, 176, 104), Enum.Material.Fabric, m)
		brim.CanCollide, crown.CanCollide = false, false
	elseif look.hat == "hood" then
		part("Hood", V3(2.2, 1.35, 1.3), V3(0, 4.6, 0.15), look.hood or Color3.fromRGB(96, 70, 50), Enum.Material.Fabric)
	elseif look.hat == "kerchief" then
		part("Kerchief", V3(2.1, 0.5, 1.15), V3(0, 4.95, 0.05), look.hood or Color3.fromRGB(176, 60, 50), Enum.Material.Fabric)
	end
	if look.tool == "pitchfork" then
		local pole = Kt.cyl(ctx, "Pitchfork", 0.22 * s, 5.4 * s, frame * CFrame.new(V3(1.8, 3.4, -0.6) * s) * CFrame.Angles(DEG(-12), 0, DEG(-8)), Color3.fromRGB(120, 88, 56), Enum.Material.Wood, m)
		pole.CanCollide = false
		for _, dx in ipairs({-0.35, 0, 0.35}) do
			local tine = Kt.box(ctx, "Tine", V3(0.1, 1, 0.1) * s, pole.CFrame * CFrame.Angles(0, 0, DEG(-90)) * CFrame.new(V3(dx, 3.1, 0) * s), Color3.fromRGB(90, 92, 96), Enum.Material.Metal, m)
			tine.CanCollide = false
		end
	elseif look.tool == "lantern" then
		local lamp = part("Lantern", V3(0.6, 0.8, 0.6), V3(1.6, 1.7, -0.3), Color3.fromRGB(255, 200, 120), Enum.Material.Neon)
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 190, 110); l.Range = 12; l.Brightness = 1.2; l.Parent = lamp
	elseif look.tool == "cane" then
		local cane = Kt.cyl(ctx, "Cane", 0.2 * s, 3.4 * s, frame * CFrame.new(V3(1.9, 1.7, -0.3) * s), Color3.fromRGB(110, 80, 52), Enum.Material.Wood, m)
		cane.CanCollide = false
	end
	m.PrimaryPart = torso
	m:SetAttribute("Feet", frame.Position)
	return m
end

local function campfire(self, ctx, pos)
	local Kt = kit()
	self.embers = Kt.campfire(ctx, pos)
	self.fire = self.embers:FindFirstChildOfClass("Fire")
	self.light = self.embers:FindFirstChildOfClass("PointLight")
	self.smoke = self.embers:FindFirstChildOfClass("Smoke")
	-- a camp round it: log benches, bedrolls, firewood, a tent, a banner
	for i, a in ipairs({20, 140, 250}) do
		local d = DEG(a)
		local at = pos + V3(math.cos(d) * 4.6, 0.55, math.sin(d) * 4.6)
		-- (lying round the fire: its length along the circle)
		Kt.cyl(ctx, "Bench", 1.1, 4.2, CFrame.fromMatrix(at, V3(math.cos(d), 0, math.sin(d)), V3(-math.sin(d), 0, math.cos(d))), Kt.C.DARKWOOD, Enum.Material.Wood, ctx.Props)
		if i ~= 2 then
			local r = DEG(a + 55)
			Kt.box(ctx, "Bedroll", V3(2, 0.35, 5), CFrame.new(pos + V3(math.cos(r) * 7.2, 0.18, math.sin(r) * 7.2)) * CFrame.Angles(0, -r, 0), i == 1 and Color3.fromRGB(150, 60, 50) or Color3.fromRGB(70, 96, 130), Enum.Material.Fabric, ctx.Props).CanCollide = false
		end
	end
	for k = 0, 5 do
		local row = k < 3 and 0 or 1
		Kt.cyl(ctx, "Firewood", 0.7, 2.6, CFrame.new(pos + V3(-6.5, 0.35 + row * 0.62, 3.5 + (k % 3 - 1) * 0.72 + row * 0.36)) * CFrame.Angles(0, 0, DEG(90)), Kt.C.WOOD, Enum.Material.Wood, ctx.Props)
	end
	Kt.tent(ctx, CFrame.new(pos + V3(0, 0, -11)) * CFrame.Angles(0, DEG(90), 0), 6, 7, 4.5, Color3.fromRGB(196, 182, 150))
	Kt.banner(ctx, pos + V3(6.5, 0, -6.5), 9, Color3.fromRGB(160, 40, 36))
end

local function caravan(self, ctx, pos)
	local Kt = kit()
	local frame = CFrame.new(pos) * CFrame.Angles(0, DEG(28), 0)
	Kt.wagon(ctx, frame, {})
	self.wagonFrame = frame
	for _, p in ipairs(ctx.Props:GetChildren()) do if p.Name == "Canvas" then table.insert(self.canvas, p) end end
	-- its cargo, unloaded beside it
	Kt.barrel(ctx, (frame * CFrame.new(4.6, 0, -2.5)).Position)
	Kt.barrel(ctx, (frame * CFrame.new(4.9, 0, 0.4)).Position)
	Kt.crate(ctx, (frame * CFrame.new(-4.8, 0, 2.6)).Position, 2.6, 15)
	Kt.crate(ctx, (frame * CFrame.new(-4.6, 0, -1)).Position, 2.2, -10)
	Kt.crate(ctx, (frame * CFrame.new(-4.7, 2.6, 2.4)).Position, 1.8, 30)
	Kt.sack(ctx, (frame * CFrame.new(-3.2, 0, 5.8)).Position)
	Kt.lantern(ctx, (frame * CFrame.new(3.8, 0, 6.5)).Position, 6.5)
	-- what burns when it burns: the bed
	self.bed = ctx.Props:FindFirstChild("WagonBed") or ctx.Geometry:FindFirstChild("WagonBed")
end

local LOOKS = {
	{tool = "pitchfork", hat = "straw", raise = true},
	{tool = "lantern", hat = "kerchief"},
	{tool = "cane", hat = "hood", hood = Color3.fromRGB(90, 90, 96)},
	{hat = "straw", scale = 0.72},
}
local function villagers(self, ctx, pos)
	local Kt = kit()
	-- the well they huddle round
	Kt.cyl(ctx, "WellWall", 4.4, 2.6, pos + V3(0, 1.3, 0), Kt.C.STONE, Enum.Material.Cobblestone, ctx.Props)
	local water = Kt.cyl(ctx, "WellWater", 3.6, 0.2, pos + V3(0, 2.2, 0), Color3.fromRGB(50, 90, 120), Enum.Material.Glass, ctx.Props)
	water.CanCollide = false
	for _, s in ipairs({-1, 1}) do Kt.box(ctx, "WellPost", V3(0.4, 4.6, 0.4), CFrame.new(pos + V3(s * 2, 4.6, 0)), Kt.C.DARKWOOD, Enum.Material.Wood, ctx.Props) end
	Kt.box(ctx, "WellBeam", V3(4.6, 0.4, 0.4), CFrame.new(pos + V3(0, 6.8, 0)), Kt.C.DARKWOOD, Enum.Material.Wood, ctx.Props)
	for _, s in ipairs({-1, 1}) do
		Kt.box(ctx, "WellRoof", V3(5.4, 0.25, 2.2), CFrame.new(pos + V3(0, 7.5, s * 0.85)) * CFrame.Angles(DEG(s * 30), 0, 0), Kt.C.THATCH, Enum.Material.Grass, ctx.Props)
	end
	Kt.cyl(ctx, "Bucket", 0.9, 0.9, pos + V3(0.4, 3.0, 1.6), Kt.C.WOOD, Enum.Material.Wood, ctx.Props)
	local folder = Instance.new("Folder"); folder.Name = "Villagers"; folder.Parent = ctx.model
	for i, look in ipairs(LOOKS) do
		local a = DEG(i * 90 - 30)
		local at = pos + V3(math.cos(a) * 3.7, 0, math.sin(a) * 3.7)
		local frame = CFrame.lookAt(at, at + V3(math.cos(a), 0, math.sin(a)))
		look.skin = look.skin or SKIN[(i - 1) % #SKIN + 1]
		look.tunic = look.tunic or TUNIC[(i - 1) % #TUNIC + 1]
		local m = villager(ctx, frame, look, folder)
		table.insert(self.people, {model = m, frame = frame, up = true, home = m:GetPivot()})
	end
end

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
function HordeObjective.build(kind, map, maxHp)
	local Kt = kit()
	local pos, spotKind = HordeObjective.place(map, kind == "Caravan" and 14 or 11)
	kind = spotKind or kind
	if not NAMES[kind] then kind = "Campfire" end
	local ctx = Kt.new("HordeObjective")
	local self = setmetatable({kind = kind, name = NAMES[kind], pos = pos, radius = RADIUS[kind], max = maxHp or 1500,
		lastHitAt = -1e9, canvas = {}, people = {}, ctx = ctx}, Obj)
	self.hp = self.max
	if kind == "Campfire" then campfire(self, ctx, pos)
	elseif kind == "Caravan" then caravan(self, ctx, pos)
	else villagers(self, ctx, pos) end
	ctx.model.Parent = map or workspace
	-- the bar over it, and where the sparks fly from
	local anchor = Instance.new("Part")
	anchor.Name = "ObjectiveAnchor"
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = V3(1, 1, 1)
	anchor.CFrame = CFrame.new(pos + V3(0, 2, 0))
	anchor.Parent = ctx.model
	self.anchor = anchor
	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 220, 150), Color3.fromRGB(255, 140, 60))
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)})
	sparks.Lifetime = NumberRange.new(0.25, 0.5)
	sparks.Speed = NumberRange.new(12, 22)
	sparks.SpreadAngle = Vector2.new(60, 60)
	sparks.Rate = 0
	sparks.Acceleration = V3(0, -40, 0)
	local att = Instance.new("Attachment"); att.Parent = anchor
	sparks.Parent = att
	self.sparkAt, self.sparks = att, sparks
	local bb = Instance.new("BillboardGui")
	bb.Name = "ObjectiveBar"
	bb.Size = UDim2.fromOffset(200, 44)
	bb.StudsOffsetWorldSpace = V3(0, (kind == "Villagers" and 8.5 or (kind == "Caravan" and 7.5 or 6.5)), 0)
	bb.MaxDistance = 160
	bb.LightInfluence = 0
	bb.Adornee = anchor
	bb.Parent = anchor
	local nm = Instance.new("TextLabel")
	nm.BackgroundTransparency = 1; nm.Size = UDim2.new(1, 0, 0, 20); nm.Font = Enum.Font.GothamBlack; nm.TextSize = 15
	nm.TextColor3 = Color3.fromRGB(255, 236, 200); nm.TextStrokeTransparency = 0.3; nm.Text = "DEFEND " .. self.name
	nm.Parent = bb
	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(10, 24); back.Size = UDim2.new(1, -20, 0, 12); back.BackgroundColor3 = Color3.fromRGB(20, 18, 22); back.BorderSizePixel = 0
	back.Parent = bb
	Instance.new("UICorner", back).CornerRadius = UDim.new(0, 5)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1); fill.BackgroundColor3 = Color3.fromRGB(120, 220, 110); fill.BorderSizePixel = 0
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)
	self.barFill, self.barName = fill, nm
	self:wear()
	return self
end

function Obj:health() return math.clamp(self.hp / self.max, 0, 1) end

-- how it looks at its health now
function Obj:wear()
	local h = self:health()
	if self.barFill then
		self.barFill.Size = UDim2.fromScale(h, 1)
		self.barFill.BackgroundColor3 = h > 0.6 and Color3.fromRGB(120, 220, 110) or (h > 0.3 and Color3.fromRGB(240, 190, 70) or Color3.fromRGB(240, 80, 70))
	end
	if self.kind == "Campfire" and self.fire then
		self.fire.Enabled = h > 0
		self.fire.Size = 1.5 + 4 * h
		self.fire.Heat = 3 + 6 * h
		if self.light then self.light.Range = 8 + 18 * h; self.light.Brightness = h > 0 and (0.8 + 1.4 * h) or 0 end
		if self.smoke then self.smoke.Opacity = h > 0 and (0.08 + 0.25 * (1 - h)) or 0.45; self.smoke.Size = 3 + 4 * (1 - h) end
		self.embers.Color = h > 0 and Color3.fromRGB(255, 110, 40):Lerp(Color3.fromRGB(120, 50, 30), 1 - h) or Color3.fromRGB(46, 40, 38)
		self.embers.Material = h > 0 and Enum.Material.Neon or Enum.Material.Slate
	elseif self.kind == "Caravan" and self.bed then
		local function ensure(class, name)
			local x = self.bed:FindFirstChild(name)
			if not x then x = Instance.new(class); x.Name = name; x.Parent = self.bed end
			return x
		end
		local smoke = ensure("Smoke", "HurtSmoke")
		smoke.Enabled = h < 0.7
		smoke.Opacity = 0.15 + 0.35 * (1 - h); smoke.Size = 4 + 6 * (1 - h); smoke.RiseVelocity = 6
		smoke.Color = Color3.fromRGB(70, 66, 62)
		local fire = ensure("Fire", "HurtFire")
		fire.Enabled = h < 0.45
		fire.Size = h > 0.2 and 5 or 9
		fire.Heat = 12
		for _, c in ipairs(self.canvas) do
			c.Transparency = h <= 0 and 1 or 0
			c.Color = Color3.fromRGB(214, 202, 172):Lerp(Color3.fromRGB(70, 56, 44), math.clamp((0.5 - h) * 2, 0, 1))
		end
	elseif self.kind == "Villagers" then
		local n = #self.people
		for k, pp in ipairs(self.people) do
			local standing = h > (k - 1) / n
			if standing ~= pp.up then
				pp.up = standing
				self:pose(pp, standing)
			end
		end
	end
end

-- a villager falls (tips over about its feet and fades) or gets back up
function Obj:pose(pp, up)
	local m = pp.model
	if not m.Parent then return end
	local feet = pp.frame
	local down = feet * CFrame.new(0, 0.5, 0) * CFrame.Angles(DEG(-85), 0, 0) * feet:Inverse() * pp.home
	local bits = {}
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") or d:IsA("Decal") then table.insert(bits, d) end end
	pp.token = (pp.token or 0) + 1
	local token, t0, dur = pp.token, os.clock(), up and 0.8 or 0.9
	local from, to = pp.v or (up and 1 or 0), up and 0 or 1
	task.spawn(function()
		while pp.token == token and m.Parent do
			local k = math.clamp((os.clock() - t0) / dur, 0, 1)
			local v = from + (to - from) * (up and (1 - (1 - k) ^ 2) or k * k)
			pp.v = v
			m:PivotTo(pp.home:Lerp(down, v))
			local fade = v > 0.6 and (v - 0.6) / 0.4 * 0.85 or 0
			for _, b in ipairs(bits) do b.Transparency = fade end
			if k >= 1 then break end
			task.wait()
		end
	end)
end

function Obj:hit(n, from)
	if self.hp <= 0 then return end
	self.hp = math.max(0, self.hp - n)
	self.lastHitAt = os.clock()
	-- sparks where the blow landed, a thump
	if from and self.sparkAt then
		local dir = from - self.pos
		dir = V3(dir.X, 0, dir.Z)
		local at = self.pos + (dir.Magnitude > 0.1 and dir.Unit * math.max(self.radius - 1.6, 1) or Vector3.zero) + V3(0, 2.4, 0)
		self.sparkAt.WorldPosition = at
		self.sparks:Emit(7)
	end
	if os.clock() - (self.lastThud or 0) > 0.25 then
		self.lastThud = os.clock()
		pcall(Sounds.play, SoundConfig.RamHit, self.anchor, {Volume = 0.9, Speed = 1.25, MaxDistance = 140})
	end
	self:wear()
	if self.hp <= 0 then
		pcall(Sounds.play, SoundConfig.GateBreak, self.anchor, {Volume = 1.3, Speed = 0.8, MaxDistance = 300})
		if self.kind == "Caravan" and self.wagonFrame then
			-- it slumps on a broken axle
			for _, p in ipairs(self.ctx.model:GetDescendants()) do
				if p:IsA("BasePart") and (p.Name:match("^Wagon") or p.Name == "Hoop" or p.Name == "Canvas" or p.Name == "Axle") then
					p.CFrame = CFrame.new(self.pos) * CFrame.Angles(0, 0, DEG(8)) * CFrame.new(self.pos):Inverse() * p.CFrame - V3(0, 0.5, 0)
				end
			end
		end
	end
end

function Obj:repair(frac)
	if self.hp <= 0 then return end
	self.hp = math.min(self.max, self.hp + self.max * (frac or 0.3))
	self:wear()
end

function Obj:destroy()
	if self.ctx and self.ctx.model then self.ctx.model:Destroy() end
end

return HordeObjective
