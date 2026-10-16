--[[ POWER AURAS — what a power that lasts looks like on you while it does, unmistakable on
     every screen (Powers.client builds one when the character's Aura attribute comes up, and
     ends it when AuraUntil runs out; Combat ▸ Powers sets them). Each is built on the body
     itself: welded pieces that move with every pose, emitters on a shell round the body drawn
     toward the camera (particles inside a body are hidden by its clothes), a light, and a
     glowing outline and tint in its colour (a Highlight: seen at any distance, in daylight; at
     most TINT_CAP at once, Roblox draws 31).

       PowerAuras.build(character, kind, color, glow) -> aura | nil
         aura.step(t)    every frame (halos turn, runes orbit, lightning crawls)
         aura.finish()   it ends: stone crumbles away, the rest fades

     KINDS (Catalog ▸ Powers `aura`, or a shout's `allies.aura`):
       stone       IRON SKIN: granite plates grow over shoulders, chest, forearms and shins;
                   dust sifts off; a stamp of dust as it comes
       juggernaut  the same, darker, molten cracks glowing through, embers
       holy        a turning halo, golden motes rising, a warm light
       wind        streaks trailing from hands and feet, a gust spiralling round the legs
       tempest     wind trails, and lightning crawling over you
       night       a shroud of dark smoke, violet eyes burning
       arcane      runes orbiting your chest, arcane sparks
       avatar      a crown of light and embers (the wings: Powers.client)
       rally       a war cry heard: embers rising from your feet, a pulse of red-gold
       renew       a second wind: green-white motes spiralling up, breath steaming
       glow        anything else: motes and a light in its colours ]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local PowerAuras = {}
local C = Color3.fromRGB
local TEX = {spark = "rbxasset://textures/particles/sparkles_main.dds", fire = "rbxasset://textures/particles/fire_main.dds", smoke = "rbxasset://textures/particles/smoke_main.dds"}
local SND = {thud = 9046338796, whoosh = 9120709477, shing = 9119742466, zap = 9116279560}

local function fxFolder()
	local f = workspace:FindFirstChild("PowerAuras")
	if not f then f = Instance.new("Folder"); f.Name = "PowerAuras"; f.Parent = workspace end
	return f
end
local function emitter(parent, o)
	local e = Instance.new("ParticleEmitter")
	e.Texture = o.tex or TEX.spark
	if o.seq then e.Color = o.seq else e.Color = ColorSequence.new(o.c1, o.c2 or o.c1) end
	e.LightEmission = o.light or 0.65
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, o.size or 0.4), NumberSequenceKeypoint.new(1, o.sizeEnd or 0)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, o.alpha or 0.1), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(o.life or 0.6, (o.life or 0.6) * 1.5)
	e.Speed = NumberRange.new(o.speed or 1, (o.speed or 1) * 1.8)
	e.SpreadAngle = Vector2.new(o.spread or 180, o.spread or 180)
	e.Rate = o.rate or 20
	e.Acceleration = o.accel or Vector3.zero
	e.Drag = o.drag or 0
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	if o.dir then e.EmissionDirection = o.dir end
	if o.box then e.Shape = Enum.ParticleEmitterShape.Box; e.ShapeStyle = o.surface and Enum.ParticleEmitterShapeStyle.Surface or Enum.ParticleEmitterShapeStyle.Volume end
	e.ZOffset = o.z or 0.7
	e.Parent = parent
	return e
end
local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Neon
	for k, v in pairs(props) do p[k] = v end
	p.Parent = fxFolder()
	return p
end
-- a piece welded to a limb (it moves with every pose), grown in from small
local function welded(limb, offset, size, props, grow)
	local p = part(props)
	p.Anchored = false; p.Massless = true
	p.Size = grow and size * 0.15 or size
	p.CFrame = limb.CFrame * offset
	local w = Instance.new("Weld"); w.Part0, w.Part1, w.C0 = limb, p, offset; w.Parent = p
	if grow then TweenService:Create(p, TweenInfo.new(grow, Enum.EasingStyle.Back), {Size = size}):Play() end
	return p
end
-- an invisible box round the whole body for emitters (their particles start outside the clothes)
local function shell(c)
	local torso = c:FindFirstChild("Torso")
	if not torso then return nil end
	return welded(torso, CFrame.new(0, -0.8, 0), Vector3.new(3.4, 4.8, 1.6), {Name = "AuraShell", Transparency = 1})
end
local function light(parent, color, range, brightness)
	local l = Instance.new("PointLight"); l.Color = color; l.Range = range; l.Brightness = brightness; l.Shadows = false; l.Parent = parent
	return l
end
local function sound(id, at, vol, speed)
	if not (at and at.Parent) then return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = vol or 0.5; s.PlaybackSpeed = speed or 1
	s.RollOffMaxDistance = 80; s.Parent = at; s:Play()
	Debris:AddItem(s, 4)
end
local function rnd(a, b) return a + math.random() * (b - a) end
-- the body outlined and tinted (a Highlight; a few at once at most)
local TINT_CAP = 8
local tints = 0
local function tint(c, fill, outline, fillT)
	if tints >= TINT_CAP then return nil end
	local h = Instance.new("Highlight")
	h.Name = "AuraTint"; h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.FillColor, h.OutlineColor = fill, outline or fill
	h.FillTransparency, h.OutlineTransparency = 1, 1
	h.Adornee = c
	h.Parent = fxFolder()
	tints += 1
	h.Destroying:Connect(function() tints -= 1 end)
	TweenService:Create(h, TweenInfo.new(0.35), {FillTransparency = fillT or 0.78, OutlineTransparency = 0.15}):Play()
	return h
end
local function A(x, y, z) return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z)) end

-- the usual end: emitters stop and their hosts go once the last particles have; lights fade;
-- visible pieces fade out
local function fadeAll(items)
	for _, x in ipairs(items) do
		if x.Parent then
			if x:IsA("ParticleEmitter") then x.Enabled = false; Debris:AddItem(x, 1.6)
			elseif x:IsA("Light") then TweenService:Create(x, TweenInfo.new(0.4), {Brightness = 0}):Play(); Debris:AddItem(x, 0.5)
			elseif x:IsA("Trail") then x.Enabled = false; Debris:AddItem(x, 1)
			elseif x:IsA("Highlight") then TweenService:Create(x, TweenInfo.new(0.4), {FillTransparency = 1, OutlineTransparency = 1}):Play(); Debris:AddItem(x, 0.45)
			elseif x:IsA("BasePart") then
				if x.Transparency >= 1 then
					for _, e in ipairs(x:GetChildren()) do if e:IsA("ParticleEmitter") then e.Enabled = false end end
					Debris:AddItem(x, 1.6)
				else
					TweenService:Create(x, TweenInfo.new(0.4), {Transparency = 1}):Play(); Debris:AddItem(x, 0.45)
				end
			else Debris:AddItem(x, 1.6) end
		end
	end
end
local function new(items, step, finish)
	return {items = items, step = step, finish = finish or function() fadeAll(items) end}
end
-- a ring of small neon segments (a halo, a crown): returns the parts and a placer
local function ring(n, radius, col, thick)
	local segs = {}
	for i = 1, n do
		segs[i] = part({Name = "Halo", Size = Vector3.new(2 * math.pi * radius / n * 1.1, thick or 0.1, thick or 0.1), Color = col, Transparency = 0.1})
	end
	local function place(centre, spin)
		for i, s in ipairs(segs) do
			local a = i / n * math.pi * 2 + spin
			s.CFrame = CFrame.new(centre + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)) * CFrame.Angles(0, -a + math.pi / 2, 0)
		end
	end
	return segs, place
end
-- trails from the ends of the limbs (feet, hands)
local function trails(c, col, glow, life, limbs)
	local out = {}
	for _, n in ipairs(limbs or {"Left Leg", "Right Leg", "Left Arm", "Right Arm"}) do
		local limb = c:FindFirstChild(n)
		if limb then
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position, a1.Position = Vector3.new(0, -0.6, 0), Vector3.new(0, -1, 0)
			a0.Parent, a1.Parent = limb, limb
			local t = Instance.new("Trail")
			t.Attachment0, t.Attachment1 = a0, a1
			t.Color = ColorSequence.new(glow, col)
			t.LightEmission = 1
			t.Lifetime = life or 0.3
			t.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
			t.WidthScale = NumberSequence.new(1, 0)
			t.FaceCamera = true
			t.Parent = limb
			table.insert(out, t); table.insert(out, a0); table.insert(out, a1)
		end
	end
	return out
end

--------------------------------------------------------------------
--  THE KINDS
--------------------------------------------------------------------
local KIND = {}

-- IRON SKIN / JUGGERNAUT: the body plated in rock
local function stoneskin(c, col, glow, molten)
	local items, plates, orbit = {}, {}, {}
	local rock = {Material = Enum.Material.Slate, Color = molten and C(58, 50, 46) or C(96, 88, 80), Transparency = 0, Name = "StonePlate"}
	local function plate(limbName, offset, size)
		local limb = c:FindFirstChild(limbName)
		if not limb then return end
		local r = table.clone(rock)
		r.Color = r.Color:Lerp(C(0, 0, 0), rnd(0, 0.18))
		local p = welded(limb, offset, size, r, 0.3)
		table.insert(plates, p)
		return p
	end
	-- pauldrons, a breastplate, bracers, greaves, and a few rough chunks
	plate("Left Arm", CFrame.new(-0.05, 0.8, 0) * A(0, 0, -14), Vector3.new(1.5, 0.7, 1.5))
	plate("Right Arm", CFrame.new(0.05, 0.8, 0) * A(0, 0, 14), Vector3.new(1.5, 0.7, 1.5))
	plate("Left Arm", CFrame.new(-0.55, 1.15, 0) * A(0, 0, 35), Vector3.new(0.35, 0.7, 0.35))
	plate("Right Arm", CFrame.new(0.55, 1.15, 0) * A(0, 0, -35), Vector3.new(0.35, 0.7, 0.35))
	plate("Torso", CFrame.new(0, 0.25, -0.5) * A(-4, 0, 0), Vector3.new(1.7, 1.2, 0.3))
	plate("Torso", CFrame.new(0, -0.55, -0.48), Vector3.new(1.5, 0.45, 0.28))
	plate("Torso", CFrame.new(0, 0.2, 0.5), Vector3.new(1.6, 1.3, 0.25))
	plate("Left Arm", CFrame.new(0, -0.45, 0) * A(0, rnd(0, 30), 0), Vector3.new(1.18, 0.7, 1.18))
	plate("Right Arm", CFrame.new(0, -0.45, 0) * A(0, rnd(0, 30), 0), Vector3.new(1.18, 0.7, 1.18))
	plate("Left Leg", CFrame.new(0, -0.5, -0.05), Vector3.new(1.16, 0.85, 1.2))
	plate("Right Leg", CFrame.new(0, -0.5, -0.05), Vector3.new(1.16, 0.85, 1.2))
	plate("Torso", CFrame.new(0.75, 0.8, -0.35) * A(20, 30, 15), Vector3.new(0.45, 0.4, 0.4))
	plate("Torso", CFrame.new(-0.8, 0.75, -0.3) * A(-15, 20, -25), Vector3.new(0.4, 0.35, 0.45))
	plate("Head", CFrame.new(0, 0.62, 0) * A(0, rnd(0, 90), 0), Vector3.new(0.9, 0.22, 0.9))
	-- molten: cracks glowing through the breastplate, embers
	if molten then
		local torso = c:FindFirstChild("Torso")
		if torso then
			for k = 1, 3 do
				local crack = welded(torso, CFrame.new(rnd(-0.5, 0.5), rnd(-0.1, 0.6), -0.66) * A(0, 0, rnd(-60, 60)), Vector3.new(rnd(0.7, 1.1), 0.06, 0.04),
					{Name = "Crack", Color = C(255, 120, 40), Transparency = 0}, 0.3)
				table.insert(plates, crack)
			end
		end
	end
	-- boulders circling you, grinding round slowly
	for k = 1, 4 do
		local r = part({Name = "OrbitRock", Material = Enum.Material.Slate, Color = rock.Color:Lerp(C(0, 0, 0), rnd(0, 0.2)),
			Size = Vector3.new(rnd(0.5, 0.8), rnd(0.45, 0.7), rnd(0.5, 0.8)), Transparency = 0})
		if molten then emitter(r, {tex = TEX.fire, c1 = C(255, 170, 70), c2 = C(220, 50, 20), size = 0.5, rate = 10, life = 0.35, speed = 0.5, accel = Vector3.new(0, 4, 0), z = 0.3}) end
		table.insert(orbit, {p = r, a = k / 4 * math.pi * 2, spin = rnd(-2, 2)})
		table.insert(plates, r)
	end
	table.insert(items, tint(c, molten and C(90, 40, 20) or C(120, 112, 100), molten and C(255, 110, 40) or C(215, 200, 170), molten and 0.7 or 0.65))
	local sh = shell(c)
	if sh then
		table.insert(items, sh)
		-- dust sifting off the stone
		emitter(sh, {tex = TEX.smoke, c1 = C(150, 140, 128), c2 = C(110, 104, 96), size = 0.5, sizeEnd = 1.1, rate = 8, life = 0.9, speed = 0.3,
			accel = Vector3.new(0, -3, 0), box = true, surface = true, light = 0, alpha = 0.45})
		emitter(sh, {c1 = molten and C(255, 150, 60) or C(210, 200, 185), c2 = molten and C(255, 70, 20) or C(150, 140, 128), size = 0.14, rate = molten and 16 or 8,
			life = 0.8, speed = molten and 2 or 0.5, accel = molten and Vector3.new(0, 4, 0) or Vector3.new(0, -6, 0), box = true, surface = true, light = molten and 1 or 0.2})
		table.insert(items, light(sh, molten and C(255, 110, 40) or col, 9, molten and 1.6 or 0.6))
	end
	-- the stamp: dust bursting out at the feet, a heavy thud
	local root = c:FindFirstChild("HumanoidRootPart")
	if root then
		local d = part({Name = "StoneStamp", Size = Vector3.new(4, 0.2, 4), Transparency = 1, CFrame = CFrame.new(root.Position - Vector3.new(0, 2.9, 0))})
		emitter(d, {tex = TEX.smoke, c1 = C(160, 150, 136), size = 1.6, sizeEnd = 3, rate = 0, life = 0.8, speed = 7, light = 0, alpha = 0.4, spread = 80, dir = Enum.NormalId.Top, z = 0}):Emit(18)
		Debris:AddItem(d, 1.5)
		sound(SND.thud, root, 0.6, molten and 0.55 or 0.7)
	end
	local function finish()
		fadeAll(items)
		-- the stone cracks off and falls away
		for _, p in ipairs(plates) do
			if p.Parent then
				p.Anchored = true
				local w = p:FindFirstChildOfClass("Weld"); if w then w:Destroy() end
				TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{CFrame = p.CFrame * A(rnd(-40, 40), rnd(-40, 40), rnd(-40, 40)) - Vector3.new(rnd(-0.6, 0.6), 2.4, rnd(-0.6, 0.6)), Transparency = 1}):Play()
				Debris:AddItem(p, 0.55)
			end
		end
		if root then sound(SND.thud, root, 0.35, 1.2) end
	end
	local step = function(t)
		local r = c:FindFirstChild("HumanoidRootPart")
		if r then
			for k, o in ipairs(orbit) do
				if o.p.Parent and o.p:FindFirstChildOfClass("Weld") == nil and not o.dropped then
					local a = o.a + t * 1.1
					o.p.CFrame = CFrame.new(r.Position + Vector3.new(math.cos(a) * 2.4, -0.6 + 0.3 * math.sin(t * 2 + k), math.sin(a) * 2.4)) * CFrame.Angles(t * o.spin, t * o.spin * 0.7, 0)
				end
			end
		end
		if molten then
			for _, p in ipairs(plates) do if p.Name == "Crack" and p.Parent then p.Transparency = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(t * 6 + p.Size.X * 9)) end end
		end
	end
	local base = finish
	finish = function()
		for _, o in ipairs(orbit) do o.dropped = true end
		base()
	end
	return new(items, step, finish)
end
KIND.stone = function(c, col, glow) return stoneskin(c, col, glow, false) end
KIND.juggernaut = function(c, col, glow) return stoneskin(c, col, glow, true) end

-- a halo above the head, motes rising, a warm light
local function haloed(c, col, glow, opts)
	local items = {}
	local head = c:FindFirstChild("Head")
	local gold = col:Lerp(glow, 0.25)
	local segs, place = ring(opts.n or 14, opts.radius or 0.95, gold, 0.13)
	for _, s in ipairs(segs) do table.insert(items, s) end
	table.insert(items, tint(c, gold, glow, 0.8))
	local sh = shell(c)
	if sh then
		table.insert(items, sh)
		emitter(sh, {c1 = glow, c2 = col, size = 0.32, rate = opts.rate or 30, life = 1.1, speed = 1.2, accel = Vector3.new(0, 3, 0), box = true, surface = true, light = 0.8})
		emitter(sh, {c1 = gold, size = 0.6, sizeEnd = 0, rate = 6, life = 0.6, speed = 0.2, box = true, surface = true, light = 1, alpha = 0.3})
		table.insert(items, light(sh, col, 11, 1.3))
	end
	if head then sound(SND.shing, head, 0.35, 1.3) end
	return new(items, function(t)
		local h = c:FindFirstChild("Head")
		if h then place(h.Position + Vector3.new(0, opts.height or 1.15, 0) + Vector3.new(0, 0.06 * math.sin(t * 2.4), 0), t * (opts.spin or 1.2)) end
	end)
end
KIND.holy = function(c, col, glow) return haloed(c, col, glow, {}) end

-- streaks from hands and feet, a gust spiralling round the legs
KIND.wind = function(c, col, glow)
	local items = trails(c, glow, glow, 0.35)
	table.insert(items, tint(c, C(200, 245, 240), C(220, 255, 250), 0.85))
	local sh = shell(c)
	if sh then
		table.insert(items, sh)
		emitter(sh, {c1 = C(235, 255, 250), c2 = glow, size = 0.16, sizeEnd = 0.05, rate = 40, life = 0.35, speed = 10, spread = 15,
			dir = Enum.NormalId.Back, box = true, surface = true, light = 0.8})
		emitter(sh, {tex = TEX.smoke, c1 = C(230, 250, 245), size = 0.7, sizeEnd = 1.6, rate = 6, life = 0.5, speed = 4, spread = 20,
			dir = Enum.NormalId.Back, box = true, surface = true, light = 0.2, alpha = 0.75})
	end
	local root = c:FindFirstChild("HumanoidRootPart")
	if root then sound(SND.whoosh, root, 0.45, 1.4) end
	return new(items)
end

-- wind, and lightning crawling over you
KIND.tempest = function(c, col, glow)
	local h = KIND.wind(c, C(170, 210, 255), C(220, 240, 255))
	for i, x in ipairs(h.items) do if x:IsA("Highlight") then x.FillColor, x.OutlineColor = C(150, 200, 255), C(220, 240, 255) end end
	local arcs = {}
	for k = 1, 6 do
		local p = part({Name = "TempestArc", Size = Vector3.new(0.06, 0.06, 1), Color = C(200, 230, 255), Transparency = 0.1})
		table.insert(arcs, p); table.insert(h.items, p)
	end
	local torso = c:FindFirstChild("Torso")
	local l = torso and light(torso, C(160, 205, 255), 12, 1.5)
	if l then table.insert(h.items, l) end
	local last = 0
	h.step = function(t)
		if l then l.Brightness = math.random() < 0.2 and 3.5 or 1.2 end
		if t - last < 0.07 then return end
		last = t
		local limbs = {}
		for _, n in ipairs({"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do local p = c:FindFirstChild(n); if p then table.insert(limbs, p) end end
		if #limbs == 0 then return end
		local function onBody()
			local p = limbs[math.random(#limbs)]
			local s = p.Size / 2
			return (p.CFrame * CFrame.new(rnd(-s.X, s.X) * 1.2, rnd(-s.Y, s.Y), rnd(-s.Z, s.Z) * 1.4)).Position
		end
		for k = 1, #arcs, 2 do
			local a, b = onBody(), onBody()
			local mid = (a + b) / 2 + Vector3.new(rnd(-0.5, 0.5), rnd(-0.5, 0.5), rnd(-0.5, 0.5))
			for j, seg in ipairs({{a, mid}, {mid, b}}) do
				local p = arcs[k + j - 1]
				if p then
					local len = (seg[2] - seg[1]).Magnitude
					p.Size = Vector3.new(0.06, 0.06, math.max(len, 0.05))
					p.CFrame = CFrame.lookAt((seg[1] + seg[2]) / 2, seg[2])
					p.Transparency = math.random() < 0.35 and 1 or 0.1
				end
			end
		end
	end
	return h
end

-- a shroud of dark smoke, and violet eyes
KIND.night = function(c, col, glow)
	local items = {}
	local sh = shell(c)
	if sh then
		table.insert(items, sh)
		emitter(sh, {tex = TEX.smoke, c1 = C(60, 28, 92), c2 = C(14, 8, 24), size = 1.6, sizeEnd = 3.2, rate = 34, life = 1.2, speed = 0.8,
			accel = Vector3.new(0, 1.8, 0), box = true, surface = true, light = 0, alpha = 0.12})
		emitter(sh, {c1 = C(200, 140, 255), c2 = C(110, 50, 190), size = 0.28, rate = 22, life = 0.9, speed = 1.2, box = true, surface = true, light = 1})
		table.insert(items, light(sh, C(140, 70, 220), 8, 1))
	end
	table.insert(items, tint(c, C(30, 10, 50), C(170, 90, 255), 0.55))
	local head = c:FindFirstChild("Head")
	if head then
		for s = -1, 1, 2 do
			local eye = welded(head, CFrame.new(0.21 * s, 0.12, -0.6), Vector3.new(0.22, 0.1, 0.05), {Name = "NightEye", Color = C(215, 140, 255), Transparency = 0})
			emitter(eye, {c1 = C(230, 170, 255), c2 = C(140, 60, 220), size = 0.3, rate = 24, life = 0.45, speed = 0.6, accel = Vector3.new(0, 2, 0), z = 1, light = 1})
			table.insert(items, eye)
		end
	end
	return new(items)
end

-- runes orbiting the chest, arcane sparks
KIND.arcane = function(c, col, glow)
	local items, runes = {}, {}
	for k = 1, 3 do
		local r = part({Name = "Rune", Size = Vector3.new(0.5, 0.5, 0.07), Color = col:Lerp(glow, 0.2), Transparency = 0.05})
		emitter(r, {c1 = glow, c2 = col, size = 0.18, rate = 18, life = 0.45, speed = 0.3, z = 0.5})
		table.insert(runes, r); table.insert(items, r)
	end
	table.insert(items, tint(c, col, glow, 0.8))
	local sh = shell(c)
	if sh then
		table.insert(items, sh)
		emitter(sh, {c1 = glow, c2 = col, size = 0.3, rate = 26, life = 0.8, speed = 1, box = true, surface = true, light = 0.9})
		table.insert(items, light(sh, col, 10, 1.3))
	end
	return new(items, function(t)
		local torso = c:FindFirstChild("Torso")
		if not torso then return end
		for k, r in ipairs(runes) do
			local a = t * 2.2 + k / #runes * math.pi * 2
			local at = torso.Position + Vector3.new(math.cos(a) * 1.9, 0.3 + 0.25 * math.sin(t * 3 + k), math.sin(a) * 1.9)
			r.CFrame = CFrame.lookAt(at, torso.Position) * CFrame.Angles(0, 0, math.rad(45) + t * 2)
		end
	end)
end

-- a crown of light and embers (the wings are Powers.client's)
KIND.avatar = function(c, col, glow)
	local h = haloed(c, col, glow, {n = 18, radius = 0.8, height = 0.95, rate = 30, spin = 0.6})
	local sh
	for _, x in ipairs(h.items) do if x.Name == "AuraShell" then sh = x end end
	if sh then emitter(sh, {tex = TEX.fire, c1 = glow, c2 = col, size = 0.8, rate = 16, life = 0.5, speed = 1, accel = Vector3.new(0, 6, 0), box = true, surface = true, light = 0.6}) end
	return h
end

-- a war cry heard: embers rising from the feet, a red-gold pulse
KIND.rally = function(c, col, glow)
	local items = {}
	local root = c:FindFirstChild("HumanoidRootPart")
	if root then
		local a = Instance.new("Attachment"); a.Name = "RallyFeet"; a.Position = Vector3.new(0, -2.7, 0); a.Parent = root
		emitter(a, {c1 = C(255, 220, 120), c2 = C(255, 70, 30), size = 0.2, rate = 26, life = 1, speed = 3, spread = 25, dir = Enum.NormalId.Top, accel = Vector3.new(0, 3, 0)})
		emitter(a, {tex = TEX.fire, c1 = C(255, 170, 70), c2 = C(220, 50, 20), size = 1, sizeEnd = 0.2, rate = 10, life = 0.45, speed = 2, spread = 40, dir = Enum.NormalId.Top, light = 0.6})
		table.insert(items, a)
		table.insert(items, light(root, C(255, 120, 50), 10, 1.2))
	end
	table.insert(items, tint(c, C(255, 110, 50), C(255, 190, 90), 0.82))
	local pulse = part({Name = "RallyRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.08, 2, 2), Color = C(255, 150, 60), Transparency = 1})
	table.insert(items, pulse)
	return new(items, function(t)
		local r = c:FindFirstChild("HumanoidRootPart")
		if not r then return end
		local k = (t * 1.2) % 1
		pulse.CFrame = CFrame.new(r.Position - Vector3.new(0, 2.85, 0)) * CFrame.Angles(0, 0, math.rad(90))
		pulse.Size = Vector3.new(0.08, 2 + 4 * k, 2 + 4 * k)
		pulse.Transparency = 0.3 + 0.7 * k
	end)
end

-- a second wind: green-white motes spiralling up, breath steaming
KIND.renew = function(c, col, glow)
	local items = {}
	local sh = shell(c)
	if sh then
		table.insert(items, sh)
		emitter(sh, {c1 = C(230, 255, 230), c2 = C(110, 230, 140), size = 0.3, rate = 32, life = 1, speed = 1.6, accel = Vector3.new(0, 4, 0), box = true, surface = true, light = 0.9})
		table.insert(items, light(sh, C(140, 255, 170), 9, 1.1))
	end
	table.insert(items, tint(c, C(120, 240, 150), C(210, 255, 220), 0.82))
	local head = c:FindFirstChild("Head")
	local breath = head and emitter(head, {tex = TEX.smoke, c1 = C(235, 255, 240), size = 0.3, sizeEnd = 1.2, rate = 0, life = 0.8, speed = 2.2, light = 0.4, alpha = 0.4, spread = 12, dir = Enum.NormalId.Front})
	if breath then table.insert(items, breath) end
	local last = 0
	return new(items, function(t)
		if breath and t - last > 0.9 then last = t; breath:Emit(4) end
	end)
end

-- anything else: motes and a light in its colours
KIND.glow = function(c, col, glow)
	local items = {}
	local sh = shell(c)
	if sh then
		table.insert(items, sh)
		emitter(sh, {c1 = glow, c2 = col, size = 0.3, rate = 30, life = 0.9, speed = 1.2, accel = Vector3.new(0, 2, 0), box = true, surface = true, light = 0.9})
		table.insert(items, light(sh, col, 10, 1.2))
	end
	table.insert(items, tint(c, col, glow, 0.82))
	return new(items)
end

function PowerAuras.build(c, kind, col, glow)
	if not (c and c.Parent) then return nil end
	local fn = KIND[kind] or KIND.glow
	local ok, aura = pcall(fn, c, col or Color3.new(1, 1, 1), glow or Color3.new(1, 1, 1))
	if not ok then warn("[PowerAuras]", kind, aura); return nil end
	return aura
end
PowerAuras.KINDS = KIND

return PowerAuras
