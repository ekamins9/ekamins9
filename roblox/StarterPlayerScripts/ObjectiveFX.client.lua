--[[ OBJECTIVE FX — the objective drawn on the world, the same for everyone:
     a glowing ring on the GROUND (visible from inside it, unlike a box), a
     light pillar to find it from across the map, and a ring of segments that
     says who holds it:

       KOTH hill      segments split by how many of each team stand on it;
                      the rim takes the holder's colour, flashes when contested
       Siege ram      segments split attackers vs defenders round the ram
                      ("who's holding it"); the ring rolls with the ram
       Siege capture  segments fill with the attackers' colour as it's taken

     Reads ReplicatedStorage ▸ Round: ObjKind ("Hill" | "Ram" | "Capture"),
     ObjPos, ObjRadius, ObjState, and ObjOwner / ObjCountA / ObjCountB (KOTH) or
     Attackers / ObjAttack / ObjDefend / ObjProgress (Siege). Local only. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local round  = ReplicatedStorage:WaitForChild("Round")
local player = Players.LocalPlayer

local SEGMENTS = 48
local NEUTRAL  = Color3.fromRGB(240, 226, 190)
local DIM      = Color3.fromRGB(120, 116, 108)
local WHITE    = Color3.new(1, 1, 1)
local KINDS    = {Hill = true, Ram = true, Capture = true}

local function teamColor(k)
	local t = k and GameConfig.TEAMS[k]
	return t and t.rgb or NEUTRAL
end
local function myKey()
	local t = player.Team
	if not t then return nil end
	for k, d in pairs(GameConfig.TEAMS) do if d.name == t.Name then return k end end
	return nil
end

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
local fx = nil

local function circle(parent, scale, z)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromScale(scale, scale)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.ZIndex = z or 1
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	f.Parent = parent
	return f
end

local function stroke(f, px, color, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = px
	s.Color = color
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
end

local function destroyFx()
	if fx then fx.part:Destroy(); fx.pillar:Destroy(); fx = nil end
end

local function build(radius)
	destroyFx()
	local d = radius * 2 + 4                     -- room round the rim for the halo
	local pps = math.clamp(math.floor(1024 / d), 6, 28)
	local part = Instance.new("Part")
	part.Name = "ObjectiveRing"
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Transparency = 1
	part.Size = Vector3.new(d, 0.05, d)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.Brightness = 2.2
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pps
	gui.Parent = part
	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = gui

	local s = radius * 2 / d                     -- the rim's diameter as a share of the gui
	local px = function(studs) return math.max(1, studs * pps) end
	local o = {part = part, gui = gui, radius = radius, segs = {}, spin = 0}
	-- the floor of the zone: a soft glow, brighter toward the rim
	o.fillOuter = circle(root, s, 1); o.fillOuter.BackgroundTransparency = 0.84
	o.fillInner = circle(root, s * 0.78, 2); o.fillInner.BackgroundTransparency = 0.92
	o.fillInner.BackgroundColor3 = Color3.new(0, 0, 0)
	-- halo just outside the rim
	o.halo = circle(root, s + px(0.9) * 2 / (d * pps), 3)
	o.haloStroke = stroke(o.halo, px(0.5), NEUTRAL, 0.65)
	-- the rim
	o.rim = circle(root, s, 4)
	o.rimStroke = stroke(o.rim, px(0.26), NEUTRAL, 0)
	-- who holds it: segments just inside the rim
	local segR = radius - 0.75
	local arc = 2 * math.pi * segR / SEGMENTS
	for i = 1, SEGMENTS do
		local a = (i - 0.5) / SEGMENTS * 2 * math.pi - math.pi / 2
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromOffset(px(arc * 0.72), px(0.42))
		f.Position = UDim2.new(0.5, math.cos(a) * px(segR), 0.5, math.sin(a) * px(segR))
		f.Rotation = math.deg(a) + 90
		f.BorderSizePixel = 0
		f.ZIndex = 5
		f.Parent = root
		o.segs[i] = f
	end
	-- the spinning dashes: life in it even when nobody's there
	o.dashes = Instance.new("Frame")
	o.dashes.AnchorPoint = Vector2.new(0.5, 0.5)
	o.dashes.Position = UDim2.fromScale(0.5, 0.5)
	o.dashes.Size = UDim2.fromScale(1, 1)
	o.dashes.BackgroundTransparency = 1
	o.dashes.ZIndex = 6
	o.dashes.Parent = root
	local dashR = radius * 0.62
	o.dashList = {}
	for i = 1, 12 do
		local a = i / 12 * 2 * math.pi
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromOffset(px(2 * math.pi * dashR / 12 * 0.45), px(0.16))
		f.Position = UDim2.new(0.5, math.cos(a) * px(dashR), 0.5, math.sin(a) * px(dashR))
		f.Rotation = math.deg(a) + 90
		f.BorderSizePixel = 0
		f.BackgroundTransparency = 0.45
		f.ZIndex = 6
		f.Parent = o.dashes
		table.insert(o.dashList, f)
	end
	-- a soft light on the ground
	o.light = Instance.new("PointLight")
	o.light.Range = math.min(radius * 1.3, 60)
	o.light.Brightness = 1.4
	o.light.Shadows = false
	o.light.Parent = part
	-- the pillar: a beam of light up into the sky
	local pillar = Instance.new("Part")
	pillar.Name = "ObjectivePillar"
	pillar.Anchored, pillar.CanCollide, pillar.CanQuery, pillar.CanTouch, pillar.CastShadow = true, false, false, false, false
	pillar.Transparency = 1
	pillar.Size = Vector3.new(0.1, 0.1, 0.1)
	local a0 = Instance.new("Attachment"); a0.Parent = pillar
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, 90, 0); a1.Parent = pillar
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Width0, beam.Width1 = math.clamp(radius * 0.22, 1.5, 5), 0.6
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 8
	beam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.6, 0.85), NumberSequenceKeypoint.new(1, 1)})
	beam.Parent = pillar
	o.pillar, o.beam = pillar, beam
	part.Parent = workspace
	pillar.Parent = workspace
	fx = o
end

--------------------------------------------------------------------
--  WHERE THE GROUND IS (the ram is ON the ground: look past it)
--------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function groundBelow(pos)
	local ignore = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	local npcs = workspace:FindFirstChild("NPCs"); if npcs then table.insert(ignore, npcs) end
	if fx then table.insert(ignore, fx.part); table.insert(ignore, fx.pillar) end
	for _ = 1, 6 do
		rayParams.FilterDescendantsInstances = ignore
		local res = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), rayParams)
		if not res then return pos end
		local inst = res.Instance
		local model = inst:FindFirstAncestorOfClass("Model")
		if inst.CanCollide and inst.Transparency < 1 and not (model and model.Name:find("Ram")) then return res.Position end
		table.insert(ignore, (model and model.Name:find("Ram")) and model or inst)
	end
	return pos
end

--------------------------------------------------------------------
--  EVERY FRAME
--------------------------------------------------------------------
local shownAt, groundAt, lastPos = nil, nil, nil

RunService.RenderStepped:Connect(function(dt)
	local kind = round:GetAttribute("ObjKind")
	local pos = round:GetAttribute("ObjPos")
	local radius = round:GetAttribute("ObjRadius")
	local live = KINDS[kind or ""] and round:GetAttribute("State") == "Round" and typeof(pos) == "Vector3" and type(radius) == "number" and radius > 0
	if not live then
		if fx then destroyFx() end
		shownAt, groundAt, lastPos = nil, nil, nil
		return
	end
	if not fx or math.abs(fx.radius - radius) > 0.05 then build(radius) end

	-- follow the objective (the ram rolls) along the ground, smoothly
	if not lastPos or (pos - lastPos).Magnitude > 0.2 then
		groundAt = groundBelow(pos)
		lastPos = pos
	end
	local target = groundAt + Vector3.new(0, 0.08, 0)
	shownAt = shownAt and shownAt:Lerp(target, math.clamp(dt * 8, 0, 1)) or target
	fx.part.CFrame = CFrame.new(shownAt)
	fx.pillar.CFrame = CFrame.new(shownAt)

	-- who's there, and what that means
	local t = os.clock()
	local state = round:GetAttribute("ObjState") or "idle"
	local leftCol, rightCol, leftN, rightN, fillShare
	local rimCol, active = NEUTRAL, false
	if kind == "Hill" then
		local a, b = round:GetAttribute("ObjCountA") or 0, round:GetAttribute("ObjCountB") or 0
		local owner = round:GetAttribute("ObjOwner") or ""
		leftCol, rightCol, leftN, rightN = teamColor("A"), teamColor("B"), a, b
		fillShare = (a + b) > 0 and a / (a + b) or nil
		if owner ~= "" then rimCol, active = teamColor(owner), true end
	else
		local atk = round:GetAttribute("Attackers") or "A"
		local def = atk == "A" and "B" or "A"
		local a, d = round:GetAttribute("ObjAttack") or 0, round:GetAttribute("ObjDefend") or 0
		leftCol, rightCol, leftN, rightN = teamColor(atk), teamColor(def), a, d
		if kind == "Capture" then
			fillShare = math.clamp(round:GetAttribute("ObjProgress") or 0, 0, 1)
			active = state == "capturing"
			rimCol = (state == "capturing") and teamColor(atk) or ((state == "losing") and teamColor(def) or NEUTRAL)
		else
			fillShare = (a + d) > 0 and a / (a + d) or nil
			active = state == "moving" or state == "battering"
			rimCol = active and teamColor(atk) or ((d > 0 and a == 0) and teamColor(def) or NEUTRAL)
		end
	end
	local contested = state == "contested"
	if contested then
		-- flash between the two sides
		rimCol = (math.sin(t * 9) > 0) and leftCol or rightCol
	end
	-- you're standing in it: it lights up for you
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local inside = false
	if hrp then
		local off = hrp.Position - shownAt
		inside = Vector3.new(off.X, 0, off.Z).Magnitude <= radius and math.abs(off.Y) < 12
	end

	-- the segments
	local filled = fillShare and math.floor(fillShare * SEGMENTS + 0.5) or nil
	for i, f in ipairs(fx.segs) do
		if not filled then
			f.BackgroundColor3 = DIM
			f.BackgroundTransparency = 0.55
		else
			local mine = i <= filled
			f.BackgroundColor3 = mine and leftCol or rightCol
			f.BackgroundTransparency = (kind == "Capture" and not mine) and 0.7 or 0.05
		end
	end

	-- the rim, the halo, the floor, the dashes, the light, the pillar
	local pulse = 0.5 + 0.5 * math.sin(t * (contested and 9 or (active and 4 or 1.6)))
	fx.rimStroke.Color = rimCol
	fx.rimStroke.Transparency = (inside and 0 or 0.08) + (active and 0 or 0.15 * pulse)
	fx.haloStroke.Color = rimCol
	fx.haloStroke.Transparency = 0.55 + 0.3 * pulse
	fx.fillOuter.BackgroundColor3 = rimCol
	fx.fillOuter.BackgroundTransparency = (inside and 0.76 or 0.84) - (active and 0.05 * pulse or 0)
	fx.spin += dt * (active and 70 or 18)
	fx.dashes.Rotation = fx.spin % 360
	for _, dsh in ipairs(fx.dashList) do dsh.BackgroundColor3 = rimCol:Lerp(WHITE, 0.3) end
	fx.gui.Brightness = inside and 2.8 or 2.2
	fx.light.Color = rimCol
	fx.light.Brightness = 1 + (active and 0.8 * pulse or 0.3)
	fx.beam.Color = ColorSequence.new(rimCol:Lerp(WHITE, 0.2), rimCol)
	-- the pillar fades when you're right there (it'd be in your face)
	fx.beam.Enabled = not inside
end)
