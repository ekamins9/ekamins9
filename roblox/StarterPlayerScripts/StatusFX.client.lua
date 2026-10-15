--[[ STATUS FX — what's been done to a body, on every screen, for as long as it lasts: players
     and bots alike, from the attributes the server publishes on the character.

       Burning       IGNITED: flames pouring off every limb, embers and smoke, a flickering
                     firelight, the body lit orange (Combat ▸ MagicServer.burn: a fire spell,
                     Flameblade, flame arrows, a firebomb's pool)
       Frosted       FROZEN: the feet locked in ice, crystals on the arms and shoulders, a cold
                     mist, the breath steaming, the body tinted pale blue (MagicServer.chill);
                     the ice shatters off when it ends
       Poisoned      bubbling and dripping green, a haze at the feet, a sickly pulsing glow
                     (Combat ▸ Powers.poison)
       Snared        vines burst out of the ground and wind up the legs, and sink back after
                     (Powers.snare)
       DazedUntil    stars circling the head (Powers.stun, a shield bash; server time)
       ShockedUntil  lightning crawling over the body (Powers.shock; server time)

     The tint is a Highlight, one per body, the strongest status's colour, at most HL_CAP at
     once (Roblox draws 31; ArmorFX's rims use some of them). Everything is local to this
     screen: anchored parts and welds made here, emitters on the limbs, gone with the status. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local C = Color3.fromRGB
local TEX = {spark = "rbxasset://textures/particles/sparkles_main.dds", fire = "rbxasset://textures/particles/fire_main.dds", smoke = "rbxasset://textures/particles/smoke_main.dds"}
local SND = {whoosh = 9120709477, ice = 9119577515, zap = 9116279560, thud = 9046338796}
local HL_CAP = 10
local LIMBS = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

local folder = workspace:FindFirstChild("StatusFX")
if not folder then folder = Instance.new("Folder"); folder.Name = "StatusFX"; folder.Parent = workspace end

local function snow() return workspace:GetServerTimeNow() end

local function emitter(parent, o)
	local e = Instance.new("ParticleEmitter")
	e.Texture = o.tex or TEX.spark
	e.Color = ColorSequence.new(o.c1, o.c2 or o.c1)
	e.LightEmission = o.light or 1
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, o.size or 0.5), NumberSequenceKeypoint.new(1, o.sizeEnd or 0)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, o.alpha or 0.1), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(o.life or 0.5, (o.life or 0.5) * 1.5)
	e.Speed = NumberRange.new(o.speed or 1, (o.speed or 1) * 1.8)
	e.SpreadAngle = Vector2.new(o.spread or 180, o.spread or 180)
	e.Rate = o.rate or 20
	e.Acceleration = o.accel or Vector3.zero
	e.Drag = o.drag or 0
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	if o.dir then e.EmissionDirection = o.dir end
	if o.box then e.Shape = Enum.ParticleEmitterShape.Box; e.ShapeStyle = o.surface and Enum.ParticleEmitterShapeStyle.Surface or Enum.ParticleEmitterShapeStyle.Volume end
	-- (drawn a little toward the camera: particles on a body are otherwise lost inside its clothes)
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
	p.Parent = folder
	return p
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
-- a piece welded to a limb (it moves with every pose and animation), grown in from small
local function crust(rec, limb, offset, size, props)
	local p = part(props)
	p.Anchored = false; p.Massless = true
	p.Size = size * 0.15
	p.CFrame = limb.CFrame * offset
	local w = Instance.new("Weld"); w.Part0, w.Part1, w.C0 = limb, p, offset; w.Parent = p
	TweenService:Create(p, TweenInfo.new(0.28, Enum.EasingStyle.Back), {Size = size}):Play()
	table.insert(rec.items, p)
	table.insert(rec.crust, p)
	return p
end
local function rnd(a, b) return a + math.random() * (b - a) end

--------------------------------------------------------------------
--  THE STATUSES: on(c, now) · make(c) -> rec {items} · step(rec, c, t) · drop(rec, c) · tint
--------------------------------------------------------------------
local STATUS = {}

STATUS.burn = {
	on = function(c) return c:GetAttribute("Burning") == true end,
	tint = {fill = C(255, 120, 30), outline = C(255, 214, 120), prio = 5, flicker = true},
	make = function(c)
		local rec = {items = {}, seed = math.random() * 100}
		local torso, head = c:FindFirstChild("Torso"), c:FindFirstChild("Head")
		local function flames(e, s)
			-- white-hot at the root, orange, a deep red as it dies
			e.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 240, 150)), ColorSequenceKeypoint.new(0.35, C(255, 140, 30)), ColorSequenceKeypoint.new(1, C(190, 30, 10))})
			e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, s * 0.5), NumberSequenceKeypoint.new(0.3, s), NumberSequenceKeypoint.new(1, s * 0.15)})
			e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.2, 0.1), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1)})
			table.insert(rec.items, e)
			return e
		end
		if torso then
			-- an invisible shell round the whole body, the flames pouring off every side of it
			local shell = Instance.new("Part")
			shell.Name = "BurnShell"; shell.Transparency = 1; shell.Massless = true
			shell.CanCollide, shell.CanQuery, shell.CanTouch, shell.CastShadow = false, false, false, false
			shell.Size = Vector3.new(3.6, 4.6, 1.6)
			shell.CFrame = torso.CFrame * CFrame.new(0, -0.8, 0)
			local w = Instance.new("Weld"); w.Part0, w.Part1, w.C0 = torso, shell, CFrame.new(0, -0.8, 0); w.Parent = shell
			shell.Parent = folder
			table.insert(rec.items, shell)
			flames(emitter(shell, {tex = TEX.fire, c1 = C(255, 200, 90), rate = 40, life = 0.55, speed = 1, accel = Vector3.new(0, 8, 0), box = true, surface = true, spread = 20, light = 0.55, z = 0.8}), 1.6)
		end
		-- the head and hands alight
		for _, n in ipairs({"Head", "Left Arm", "Right Arm"}) do
			local p = c:FindFirstChild(n)
			if p then
				flames(emitter(p, {tex = TEX.fire, c1 = C(255, 200, 90), rate = 12, life = 0.5, speed = 1.5, accel = Vector3.new(0, 7, 0), box = true, surface = true,
					spread = 25, light = 0.55, z = 0.8, dir = Enum.NormalId.Top}), n == "Head" and 1.2 or 1)
			end
		end
		if torso then
			-- embers drifting up, and the firelight
			table.insert(rec.items, emitter(torso, {c1 = C(255, 235, 150), c2 = C(255, 90, 20), size = 0.16, rate = 16, life = 1.1, speed = 3, accel = Vector3.new(0, 5, 0), box = true, drag = 1.2}))
			rec.light = light(torso, C(255, 140, 50), 12, 2)
			table.insert(rec.items, rec.light)
			-- (the moment it catches: a puff of flame)
			local puff = emitter(torso, {tex = TEX.fire, c1 = C(255, 230, 140), c2 = C(255, 80, 20), size = 2.4, rate = 0, life = 0.4, speed = 6, accel = Vector3.new(0, 8, 0), box = true, light = 0.6, z = 1.2})
			puff:Emit(18)
			Debris:AddItem(puff, 1)
			sound(SND.whoosh, torso, 0.55, 0.75)
		end
		if head then
			table.insert(rec.items, emitter(head, {tex = TEX.smoke, c1 = C(70, 60, 54), c2 = C(36, 32, 30), size = 1.4, sizeEnd = 3.2, rate = 5, life = 1.7,
				speed = 2.5, accel = Vector3.new(0, 4, 0), light = 0, alpha = 0.6, spread = 20, dir = Enum.NormalId.Top}))
		end
		return rec
	end,
	step = function(rec, c, t)
		if rec.light then rec.light.Brightness = 1.9 + 1.5 * math.noise(t * 8, rec.seed) end
	end,
}

STATUS.frost = {
	on = function(c) return c:GetAttribute("Frosted") == true end,
	tint = {fill = C(150, 215, 255), outline = C(235, 250, 255), prio = 3},
	make = function(c)
		local rec = {items = {}, crust = {}}
		local ice = {Material = Enum.Material.Glass, Color = C(185, 230, 255), Transparency = 0.18, Reflectance = 0.15, Name = "Frost"}
		local function A(x, y, z) return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z)) end
		-- the feet locked in a block of ice, crystals jutting from the shins
		for _, n in ipairs({"Left Leg", "Right Leg"}) do
			local leg = c:FindFirstChild(n)
			if leg then
				crust(rec, leg, CFrame.new(0, -0.62, 0) * A(0, rnd(0, 40), 0), Vector3.new(1.4, 0.95, 1.4), ice)
				crust(rec, leg, CFrame.new(0.38, -0.1, -0.32) * A(-22, 0, 28), Vector3.new(0.34, 1.15, 0.34), ice)
				crust(rec, leg, CFrame.new(-0.36, -0.25, 0.3) * A(16, 0, -22), Vector3.new(0.28, 0.9, 0.28), ice)
			end
		end
		-- the forearms crusted, a crystal on each shoulder
		for _, n in ipairs({"Left Arm", "Right Arm"}) do
			local arm = c:FindFirstChild(n)
			if arm then
				crust(rec, arm, CFrame.new(0, -0.55, 0) * A(0, rnd(0, 40), 0), Vector3.new(1.18, 0.85, 1.18), ice)
				crust(rec, arm, CFrame.new(0.32, -0.15, -0.3) * A(-26, 0, 30), Vector3.new(0.28, 0.85, 0.28), ice)
			end
		end
		local torso, head = c:FindFirstChild("Torso"), c:FindFirstChild("Head")
		if torso then
			crust(rec, torso, CFrame.new(0.85, 0.95, -0.15) * A(0, 0, -35), Vector3.new(0.3, 0.95, 0.3), ice)
			crust(rec, torso, CFrame.new(-0.9, 0.9, 0.1) * A(10, 0, 40), Vector3.new(0.26, 0.75, 0.26), ice)
			-- the cold coming off: mist sinking, glints of frost
			table.insert(rec.items, emitter(torso, {tex = TEX.smoke, c1 = C(215, 240, 255), size = 1.2, sizeEnd = 2.4, rate = 7, life = 1.2, speed = 0.5, accel = Vector3.new(0, -1.2, 0), light = 0.2, alpha = 0.7, box = true}))
			table.insert(rec.items, emitter(torso, {c1 = C(245, 252, 255), c2 = C(150, 214, 255), size = 0.28, rate = 20, life = 0.9, speed = 0.4, accel = Vector3.new(0, -1.5, 0), box = true}))
			table.insert(rec.items, light(torso, C(160, 215, 255), 9, 0.8))
			sound(SND.ice, torso, 0.5, 1)
		end
		if head then
			-- breath steaming in the cold
			rec.breath = emitter(head, {tex = TEX.smoke, c1 = C(240, 250, 255), size = 0.35, sizeEnd = 1.3, rate = 0, life = 0.9, speed = 2.2, light = 0.3, alpha = 0.45, spread = 12, dir = Enum.NormalId.Front})
			table.insert(rec.items, rec.breath)
		end
		return rec
	end,
	step = function(rec, c, t)
		if rec.breath and t - (rec.lastBreath or 0) > 1.3 then rec.lastBreath = t; rec.breath:Emit(4) end
	end,
	drop = function(rec, c)
		-- it shatters: the ice flies off in pieces
		for _, p in ipairs(rec.crust) do
			if p.Parent then
				local w = p:FindFirstChildOfClass("Weld")
				p.Anchored = true
				if w then w:Destroy() end
				local dir = Vector3.new(rnd(-1, 1), rnd(0.2, 1.2), rnd(-1, 1))
				TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {CFrame = p.CFrame * CFrame.Angles(rnd(-2, 2), rnd(-2, 2), 0) + dir * 2.2, Transparency = 1}):Play()
			end
		end
		sound(SND.ice, c:FindFirstChild("Torso"), 0.4, 1.45)
	end,
}

STATUS.poison = {
	on = function(c) return c:GetAttribute("Poisoned") == true end,
	tint = {fill = C(110, 220, 70), outline = C(200, 255, 150), prio = 2, pulse = true},
	make = function(c)
		local rec = {items = {}}
		local green, pale = C(110, 220, 70), C(200, 255, 150)
		local torso = c:FindFirstChild("Torso")
		if torso then
			table.insert(rec.items, emitter(torso, {c1 = green, c2 = pale, size = 0.38, rate = 18, life = 0.9, speed = 1.4, accel = Vector3.new(0, 3, 0), box = true, light = 0.7}))
		end
		for _, n in ipairs({"Left Arm", "Right Arm", "Head"}) do
			local p = c:FindFirstChild(n)
			if p then table.insert(rec.items, emitter(p, {c1 = green, c2 = C(60, 140, 40), size = 0.2, rate = 5, life = 0.7, speed = 0.3, accel = Vector3.new(0, -22, 0), box = true, light = 0.5})) end
		end
		local root = c:FindFirstChild("HumanoidRootPart")
		if root then
			local a = Instance.new("Attachment"); a.Name = "PoisonHaze"; a.Position = Vector3.new(0, -2.7, 0); a.Parent = root
			emitter(a, {tex = TEX.smoke, c1 = C(120, 200, 70), c2 = C(70, 120, 40), size = 2, sizeEnd = 3, rate = 5, life = 1.4, speed = 0.6, light = 0.3, alpha = 0.7, spread = 90, dir = Enum.NormalId.Top})
			table.insert(rec.items, a)
		end
		return rec
	end,
}

STATUS.snare = {
	on = function(c) return c:GetAttribute("Snared") == true end,
	make = function(c)
		local root = c:FindFirstChild("HumanoidRootPart")
		if not root then return nil end
		local rec = {items = {}, vines = {}}
		local base = CFrame.new(root.Position - Vector3.new(0, 3, 0)) * CFrame.Angles(0, rnd(0, 6.3), 0)
		for k = 1, 7 do
			local a = k / 7 * math.pi * 2
			-- each vine: out of the ground beside you, leaning in, a second length curling round the legs
			local foot = base * CFrame.new(math.cos(a) * 1.3, 0, math.sin(a) * 1.3)
			local inward = CFrame.lookAt(foot.Position, base.Position + Vector3.new(0, 4, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
			local tilt = inward * CFrame.Angles(math.rad(rnd(-12, 12)), 0, math.rad(rnd(-10, 10)))
			for seg = 1, 2 do
				local len = seg == 1 and rnd(1.4, 1.9) or rnd(0.9, 1.3)
				local from = seg == 1 and tilt or rec.vines[#rec.vines].tip * CFrame.Angles(math.rad(rnd(18, 34)), math.rad(rnd(-40, 40)), 0)
				local v = part({Name = "Vine", Size = Vector3.new(0.24, 0.1, 0.24), Material = Enum.Material.Grass, Color = seg == 1 and C(60, 125, 48) or C(78, 150, 58), CFrame = from})
				local full = from * CFrame.new(0, len / 2, 0)
				TweenService:Create(v, TweenInfo.new(0.22 + seg * 0.08, Enum.EasingStyle.Back), {Size = Vector3.new(0.24 - seg * 0.04, len, 0.24 - seg * 0.04), CFrame = full}):Play()
				table.insert(rec.items, v)
				table.insert(rec.vines, {p = v, from = from, tip = from * CFrame.new(0, len, 0)})
			end
		end
		-- the ground breaking open: dirt and leaves
		local holder = part({Name = "SnareBurst", Size = Vector3.new(2.6, 0.2, 2.6), Transparency = 1, CFrame = base})
		emitter(holder, {tex = TEX.smoke, c1 = C(110, 90, 65), size = 1.4, sizeEnd = 2.4, rate = 0, life = 0.7, speed = 5, light = 0, alpha = 0.5, spread = 50, dir = Enum.NormalId.Top}):Emit(10)
		emitter(holder, {c1 = C(120, 200, 80), c2 = C(60, 130, 40), size = 0.3, rate = 0, life = 0.8, speed = 8, accel = Vector3.new(0, -14, 0), light = 0.3, spread = 50, dir = Enum.NormalId.Top}):Emit(24)
		Debris:AddItem(holder, 1.5)
		sound(SND.thud, holder, 0.5, 0.7)
		return rec
	end,
	drop = function(rec)
		-- the vines sink back into the ground
		for _, v in ipairs(rec.vines) do
			if v.p.Parent then TweenService:Create(v.p, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Size = Vector3.new(0.1, 0.1, 0.1), CFrame = v.from}):Play() end
		end
	end,
}

STATUS.daze = {
	on = function(c, now) return (c:GetAttribute("DazedUntil") or 0) > now end,
	make = function(c)
		local rec = {items = {}, stars = {}}
		for k = 1, 3 do
			-- a little star: two squares turned against each other
			local s = {}
			for j = 0, 1 do
				local p = part({Name = "DazeStar", Size = Vector3.new(0.34, 0.34, 0.08), Color = C(255, 228, 90)})
				table.insert(rec.items, p)
				table.insert(s, {p = p, turn = j * math.rad(45)})
			end
			table.insert(rec.stars, s)
		end
		local head = c:FindFirstChild("Head")
		if head then
			table.insert(rec.items, emitter(head, {c1 = C(255, 240, 150), size = 0.2, rate = 8, life = 0.6, speed = 0.5, box = true}))
		end
		return rec
	end,
	step = function(rec, c, t)
		local head = c:FindFirstChild("Head")
		if not head then return end
		local centre = head.Position + Vector3.new(0, 1.15, 0)
		for k, s in ipairs(rec.stars) do
			local a = t * 5 + k / #rec.stars * math.pi * 2
			local at = centre + Vector3.new(math.cos(a) * 0.95, 0.12 * math.sin(t * 7 + k), math.sin(a) * 0.95)
			for _, q in ipairs(s) do q.p.CFrame = CFrame.lookAt(at, centre) * CFrame.Angles(0, 0, t * 4 + q.turn) end
		end
	end,
}

STATUS.shock = {
	on = function(c, now) return (c:GetAttribute("ShockedUntil") or 0) > now end,
	tint = {fill = C(170, 210, 255), outline = C(240, 250, 255), prio = 4, flicker = true},
	make = function(c)
		local rec = {items = {}, arcs = {}, seed = math.random() * 100}
		for k = 1, 10 do
			local p = part({Name = "Arc", Size = Vector3.new(0.07, 0.07, 1), Color = C(200, 230, 255), Transparency = 0.05})
			table.insert(rec.items, p)
			table.insert(rec.arcs, p)
		end
		local torso = c:FindFirstChild("Torso")
		if torso then
			table.insert(rec.items, emitter(torso, {c1 = C(235, 248, 255), c2 = C(140, 190, 255), size = 0.22, rate = 30, life = 0.18, speed = 7, box = true}))
			rec.light = light(torso, C(160, 205, 255), 11, 2)
			table.insert(rec.items, rec.light)
			sound(SND.zap, torso, 0.5, 1.1)
		end
		return rec
	end,
	step = function(rec, c, t)
		if rec.light then rec.light.Brightness = math.random() < 0.35 and 4 or 0.6 end
		if t - (rec.last or 0) < 0.05 then return end
		rec.last = t
		-- arcs jumping between random points on the body, a kink in each
		local parts = {}
		for _, n in ipairs(LIMBS) do local p = c:FindFirstChild(n); if p then table.insert(parts, p) end end
		if #parts == 0 then return end
		local function onBody()
			local p = parts[math.random(#parts)]
			local s = p.Size / 2
			return (p.CFrame * CFrame.new(rnd(-s.X, s.X), rnd(-s.Y, s.Y), rnd(-s.Z, s.Z))).Position
		end
		for k = 1, #rec.arcs, 2 do
			local a, b = onBody(), onBody()
			local mid = (a + b) / 2 + Vector3.new(rnd(-0.5, 0.5), rnd(-0.5, 0.5), rnd(-0.5, 0.5))
			for j, seg in ipairs({{a, mid}, {mid, b}}) do
				local p = rec.arcs[k + j - 1]
				if p then
					local from, to = seg[1], seg[2]
					local len = (to - from).Magnitude
					if len > 0.05 then
						p.Size = Vector3.new(0.07, 0.07, len)
						p.CFrame = CFrame.lookAt((from + to) / 2, to)
						p.Transparency = math.random() < 0.2 and 1 or 0.05
					end
				end
			end
		end
	end,
}

--------------------------------------------------------------------
--  EVERY BODY, EVERY FRAME
--------------------------------------------------------------------
local looks = setmetatable({}, {__mode = "k"})   -- [character] = {[status] = rec, hl = Highlight}
local highlights = 0

local function fadeOut(rec)
	for _, x in ipairs(rec.items or {}) do
		if x.Parent then
			if x:IsA("ParticleEmitter") then x.Enabled = false; Debris:AddItem(x, 1.6)
			elseif x:IsA("Light") then TweenService:Create(x, TweenInfo.new(0.35), {Brightness = 0}):Play(); Debris:AddItem(x, 0.4)
			elseif x:IsA("BasePart") and x.Transparency >= 1 then
				-- (a host for emitters: they stop, and it goes once their last particles have)
				for _, e in ipairs(x:GetChildren()) do if e:IsA("ParticleEmitter") then e.Enabled = false end end
				Debris:AddItem(x, 1.6)
			elseif x:IsA("BasePart") then
				if not x.Anchored then x.Anchored = true; local w = x:FindFirstChildOfClass("Weld"); if w then w:Destroy() end end
				TweenService:Create(x, TweenInfo.new(0.4), {Transparency = 1}):Play(); Debris:AddItem(x, 0.45)
			else x:Destroy() end
		end
	end
end
local function drop(key, rec, c)
	local S = STATUS[key]
	if S.drop then pcall(S.drop, rec, c) end
	fadeOut(rec)
end
local function dropHighlight(L)
	if L.hl then L.hl:Destroy(); L.hl = nil; highlights -= 1 end
end
-- one tint per body: the strongest status's colour
local function tint(c, L, t)
	local best
	for key, S in pairs(STATUS) do
		if L[key] and S.tint and (not best or S.tint.prio > best.prio) then best = S.tint end
	end
	if not best then dropHighlight(L); return end
	if not L.hl then
		if highlights >= HL_CAP then return end
		local h = Instance.new("Highlight")
		h.Name = "StatusTint"; h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Adornee = c; h.Parent = folder
		L.hl = h; highlights += 1
	end
	local h = L.hl
	h.FillColor, h.OutlineColor = best.fill, best.outline
	local f = 0.68
	if best.flicker then f = 0.6 + 0.16 * math.noise(t * 9, L.seed or 0) end
	if best.pulse then f = 0.66 + 0.1 * math.sin(t * 4) end
	h.FillTransparency = f
	h.OutlineTransparency = 0.45
end

local function bodies()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(out, p.Character) end end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do if m:IsA("Model") then table.insert(out, m) end end end
	return out
end

local scanT = 0
RunService.RenderStepped:Connect(function(dt)
	local now, t = snow(), os.clock()
	scanT += dt
	local scan = scanT > 0.1
	if scan then scanT = 0 end
	for _, c in ipairs(bodies()) do
		local L = looks[c]
		if not L then L = {seed = math.random() * 100}; looks[c] = L end
		for key, S in pairs(STATUS) do
			if scan then
				local on = S.on(c, now)
				if on and not L[key] then
					local ok, rec = pcall(S.make, c)
					if ok and rec then L[key] = rec elseif not ok then warn("[StatusFX]", key, rec) end
				elseif not on and L[key] then
					drop(key, L[key], c); L[key] = nil
				end
			end
			local rec = L[key]
			if rec and S.step then pcall(S.step, rec, c, t) end
		end
		tint(c, L, t)
	end
	if scan then
		for c, L in pairs(looks) do
			if not c.Parent then
				for key in pairs(STATUS) do if L[key] then fadeOut(L[key]) end end
				dropHighlight(L)
				looks[c] = nil
			end
		end
	end
end)
