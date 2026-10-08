--[[ ARMOR FX (client) — makes an armor finish (Catalog ▸ ArmorFX) come alive,
     on anyone's armor in the world and on the menu's mannequins. Looks only,
     local only. ReplicatedStorage ▸ ArmorFX tags what it dresses:

       parts "ArmorGlow" (attribute Mode)   the glowing trims: "pulse" breathes,
                                            "flicker" crackles, "radiant" walks the rainbow
       the Armor folder "FinishWorn"        FinishTier 1..4, FinishAccent, FinishAura, FinishRadiant

     The rarer, the more alive:
       every finish   the plates catch the light (a glint now and then); the wearer's
                      kills flare it (a ring, a burst of its aura, a flash of the trims)
       Epic +         footprints in its own element (frost, fire, petals, sparks…)
       Legendary +    the arms and legs streak light when you run or swing; a surge
                      ring rolls off you every few seconds
       Mythic         motes of it circle you, and a rim of its light outlines you ]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkinFX = require(ReplicatedStorage:WaitForChild("SkinFX"))

local rng = Random.new()
local WHITE = Color3.new(1, 1, 1)
local FAR = 140            -- studs: past this, a wearer in the world is left alone
local MAX_RIMS = 8         -- (Roblox draws at most 31 Highlights at once)

--------------------------------------------------------------------
--  GLOWING TRIMS
--------------------------------------------------------------------
local parts = {}     -- [part] = {base, seed, mode, cont}
local wearers = {}   -- [Armor folder] = state (below)

local function addGlow(p)
	if not p:IsA("BasePart") then return end
	local c = p:GetAttribute("GlowColor")
	parts[p] = {base = typeof(c) == "Color3" and c or p.Color, seed = rng:NextNumber(0, 6.28), mode = p:GetAttribute("Mode"), cont = p:FindFirstAncestor("Armor")}
end
CollectionService:GetInstanceAddedSignal("ArmorGlow"):Connect(addGlow)
CollectionService:GetInstanceRemovedSignal("ArmorGlow"):Connect(function(p) parts[p] = nil end)
for _, p in ipairs(CollectionService:GetTagged("ArmorGlow")) do addGlow(p) end

--------------------------------------------------------------------
--  LITTLE PIECES OF LIGHT (parented beside the wearer: the world, or the
--  mannequin's WorldModel in a menu ViewportFrame)
--------------------------------------------------------------------
local worldFolder
local function homeOf(st)
	if st.preview then return st.char.Parent end
	if not (worldFolder and worldFolder.Parent) then
		worldFolder = Instance.new("Folder"); worldFolder.Name = "ArmorFXLocal"; worldFolder.Parent = workspace
	end
	return worldFolder
end
local function bit(st, size, color, shape, material)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = material or Enum.Material.Neon
	p.Color = color
	p.Size = size
	if shape then p.Shape = shape end
	p.Parent = homeOf(st)
	return p
end
local function fade(p, time, props)
	props = props or {}
	props.Transparency = 1
	TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
	Debris:AddItem(p, time + 0.05)
end
-- a burst of the finish's own aura particles at a point (the world only: a ViewportFrame shows none)
local function auraBurst(st, at, n)
	if st.preview then return end
	local def = st.aura and SkinFX.AURA_DEF and SkinFX.AURA_DEF[st.aura]
	local e = def and def.emit and def.emit[1]
	if not e then return end
	local holder = bit(st, Vector3.one * 0.2, WHITE)
	holder.Transparency = 1
	holder.Position = at
	local pe = SkinFX.makeEmitter(e, "Burst")
	pe.Rate = 0
	pe.Parent = holder
	pe:Emit(n)
	Debris:AddItem(holder, 2.5)
end
local function accentOf(st, now)
	if st.radiant then return Color3.fromHSV((now * 0.15 + st.seed) % 1, 0.55, 1) end
	return st.accent
end

-- a sparkle on the plates: two crossed slivers that swell and vanish
local function glint(st, now)
	local list = st.metal
	if #list == 0 then return end
	local p = list[rng:NextInteger(1, #list)]
	if not p.Parent then return end
	local at = p.CFrame * Vector3.new(rng:NextNumber(-0.4, 0.4) * p.Size.X, rng:NextNumber(-0.4, 0.4) * p.Size.Y, -p.Size.Z * 0.5)
	local cam = workspace.CurrentCamera
	local face = st.preview and CFrame.new(at) or CFrame.lookAt(at, cam and cam.CFrame.Position or at + Vector3.zAxis)
	local col = WHITE:Lerp(accentOf(st, now), 0.25)
	for _, a in ipairs({0, 90}) do
		local s = bit(st, Vector3.new(0.05, 0.05, 0.02), col)
		s.CFrame = face * CFrame.Angles(0, 0, math.rad(a + 20))
		TweenService:Create(s, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.07, 0.75, 0.02)}):Play()
		task.delay(0.16, function() if s.Parent then fade(s, 0.22, {Size = Vector3.new(0.02, 0.1, 0.02)}) end end)
	end
end

-- a ring of light rolling out along the ground from the wearer's feet
local function ring(st, radius, time, thick)
	local root = st.char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local base = root.Position - Vector3.new(0, 2.9, 0)
	local n = 20
	local segs = {}
	local col = accentOf(st, os.clock())
	for i = 1, n do segs[i] = bit(st, Vector3.new(0.5, thick or 0.12, 0.18), col) end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / time, 0, 1)
		local r = 0.6 + (radius - 0.6) * (1 - (1 - k) ^ 3)
		for i, s in ipairs(segs) do
			local a = i / n * math.pi * 2
			s.Size = Vector3.new(2 * math.pi * r / n * 1.05, thick or 0.12, 0.18)
			s.CFrame = CFrame.new(base + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)) * CFrame.Angles(0, -a + math.pi / 2, 0)
			s.Transparency = 0.15 + 0.85 * k * k
		end
		if k >= 1 then conn:Disconnect(); for _, s in ipairs(segs) do s:Destroy() end end
	end)
end

-- the surge: a ring, a flash of the trims; big = a kill (a wider ring, a burst, a pillar for a Mythic)
local function surge(st, big)
	st.flash = os.clock()
	ring(st, big and 9 or 4.5, big and 0.7 or 0.55, big and 0.2 or 0.1)
	if not big then return end
	local root = st.char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	auraBurst(st, root.Position, 26)
	if st.tier >= 4 then
		local p = bit(st, Vector3.new(0.6, 14, 0.6), accentOf(st, os.clock()), Enum.PartType.Cylinder)
		p.CFrame = CFrame.new(root.Position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		p.Transparency = 0.2
		fade(p, 0.8, {Size = Vector3.new(26, 0.1, 0.1)})
	end
end

--------------------------------------------------------------------
--  FOOTPRINTS (Epic +): each step leaves a print of the finish's element
--------------------------------------------------------------------
local PRINT = {   -- by aura: the print's look, how long it stays, how many particles kick up
	frost = {mat = Enum.Material.Ice, col = Color3.fromRGB(200, 236, 255), life = 3.2, n = 2, size = 1.15},
	embers = {life = 1.4, n = 3}, inferno = {life = 1.8, n = 4, size = 1.2}, phoenix = {life = 1.6, n = 4},
	storm = {life = 0.7, n = 3, spark = true}, holy = {life = 1.6, n = 2, size = 1.1}, sovereign = {life = 1.6, n = 3},
	gold = {life = 1.4, n = 2}, celestial = {life = 2.2, n = 3, size = 1.15}, toxic = {life = 1.8, n = 3},
	shadow = {col = Color3.fromRGB(20, 16, 26), mat = Enum.Material.SmoothPlastic, life = 1.8, n = 3},
	petals = {life = 2.2, n = 3}, blood = {col = Color3.fromRGB(110, 10, 10), mat = Enum.Material.SmoothPlastic, life = 2.4, n = 2},
}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function footstep(st, now)
	local char, root = st.char, st.char:FindFirstChild("HumanoidRootPart")
	local legName = st.side == 1 and "Right Leg" or "Left Leg"
	local legPart = char:FindFirstChild(legName)
	if not (root and legPart) then return end
	rayParams.FilterDescendantsInstances = {char, homeOf(st)}
	local hit = workspace:Raycast(legPart.Position, Vector3.new(0, -3.5, 0), rayParams)
	if not hit then return end
	local look = root.CFrame.LookVector
	local fwd = Vector3.new(look.X, 0, look.Z)
	if fwd.Magnitude < 1e-3 then return end
	local spec = PRINT[st.aura] or {}
	local sz = spec.size or 1
	local at = hit.Position + hit.Normal * 0.03
	local base = CFrame.lookAt(at, at + fwd.Unit, hit.Normal)
	-- a boot's print: the ball of the foot ahead, the heel behind (flat discs)
	for _, d in ipairs({{0.68 * sz, -0.22 * sz}, {0.5 * sz, 0.34 * sz}}) do
		local p = bit(st, Vector3.new(0.05, d[1], d[1]), spec.col or accentOf(st, now), Enum.PartType.Cylinder, spec.mat)
		p.CFrame = base * CFrame.new(0, 0, d[2]) * CFrame.Angles(0, 0, math.pi / 2)
		task.delay((spec.life or 1.5) * 0.4, function() if p.Parent then fade(p, (spec.life or 1.5) * 0.6) end end)
	end
	if spec.spark then   -- a crackle across the print
		local s = bit(st, Vector3.new(0.06, 0.06, 1.2), WHITE)
		s.CFrame = base * CFrame.Angles(0, rng:NextNumber(-1, 1), 0) * CFrame.new(0, 0.06, 0)
		fade(s, 0.3)
	end
	auraBurst(st, hit.Position + Vector3.new(0, 0.3, 0), spec.n or 2)
end

--------------------------------------------------------------------
--  STREAKS (Legendary +): trails on the arms and legs, lit while you run or swing
--------------------------------------------------------------------
local LIMBS = {{"Left Arm", -0.2, -1}, {"Right Arm", -0.2, -1}, {"Left Leg", -0.3, -1}, {"Right Leg", -0.3, -1}}
local function makeTrails(st)
	st.trails = {}
	for _, d in ipairs(LIMBS) do
		local limb = st.char:FindFirstChild(d[1])
		if limb then
			local a0 = Instance.new("Attachment"); a0.Name = "FinishTrail0"; a0.Position = Vector3.new(0, d[2], 0); a0.Parent = limb
			local a1 = Instance.new("Attachment"); a1.Name = "FinishTrail1"; a1.Position = Vector3.new(0, d[3], 0); a1.Parent = limb
			local tr = Instance.new("Trail")
			tr.Name = "FinishTrail"
			tr.Attachment0, tr.Attachment1 = a0, a1
			tr.Color = ColorSequence.new(st.accent:Lerp(WHITE, 0.4), st.accent)
			tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1)})
			tr.LightEmission = 1
			tr.Lifetime = 0.22
			tr.MinLength = 0.05
			tr.FaceCamera = true
			tr.Enabled = false
			tr.Parent = limb
			table.insert(st.trails, {tr, a0, a1})
		end
	end
end

--------------------------------------------------------------------
--  MOTES (Mythic): little stars of it circling you
--------------------------------------------------------------------
local function makeMotes(st)
	st.motes = {}
	for i = 1, 3 do
		local core = bit(st, Vector3.one * (st.preview and 0.24 or 0.32), st.accent:Lerp(WHITE, 0.15), Enum.PartType.Ball)
		local arms = {}
		for _, a in ipairs({0, 90}) do
			local s = bit(st, st.preview and Vector3.new(0.04, 0.42, 0.04) or Vector3.new(0.06, 0.7, 0.06), st.accent:Lerp(WHITE, 0.35))
			s:SetAttribute("Spin", a)
			table.insert(arms, s)
		end
		if not st.preview then
			local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.12, 0); a0.Parent = core
			local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.12, 0); a1.Parent = core
			local tr = Instance.new("Trail"); tr.Attachment0, tr.Attachment1 = a0, a1
			tr.Color = ColorSequence.new(st.accent); tr.LightEmission = 1; tr.Lifetime = 0.45; tr.FaceCamera = true
			tr.Transparency = NumberSequence.new(0.2, 1); tr.WidthScale = NumberSequence.new(1, 0); tr.Parent = core
			local l = Instance.new("PointLight"); l.Color = st.accent; l.Range = 5; l.Brightness = 1.2; l.Shadows = false; l.Parent = core
		end
		table.insert(st.motes, {core = core, arms = arms, phase = (i - 1) / 3 * math.pi * 2, tilt = rng:NextNumber(-0.4, 0.4)})
	end
end
local function dropMotes(st)
	for _, m in ipairs(st.motes or {}) do
		m.core:Destroy()
		for _, s in ipairs(m.arms) do s:Destroy() end
	end
	st.motes = nil
end

--------------------------------------------------------------------
--  WEARERS
--------------------------------------------------------------------
local METAL = {[Enum.Material.Metal] = true, [Enum.Material.Foil] = true, [Enum.Material.DiamondPlate] = true, [Enum.Material.Ice] = true,
	[Enum.Material.Glass] = true, [Enum.Material.Basalt] = true, [Enum.Material.Slate] = true, [Enum.Material.Limestone] = true}
local function addWearer(cont)
	local char = cont.Parent
	if not (char and char:IsA("Model")) then return end
	local st = {
		cont = cont, char = char,
		tier = cont:GetAttribute("FinishTier") or 1,
		accent = cont:GetAttribute("FinishAccent") or WHITE,
		aura = cont:GetAttribute("FinishAura"),
		radiant = cont:GetAttribute("FinishRadiant") == true,
		preview = not char:IsDescendantOf(workspace),
		seed = rng:NextNumber(0, 1),
		nextGlint = os.clock() + rng:NextNumber(0.5, 2), nextSurge = os.clock() + rng:NextNumber(2, 5),
		walked = 0, side = 1, flash = -1e9, metal = {},
	}
	for _, p in ipairs(cont:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "Middle" and p.Transparency < 1 and METAL[p.Material] then table.insert(st.metal, p) end
	end
	wearers[cont] = st
end
local function dropWearer(cont)
	local st = wearers[cont]
	if not st then return end
	wearers[cont] = nil
	dropMotes(st)
	for _, t in ipairs(st.trails or {}) do for _, x in ipairs(t) do x:Destroy() end end
	if st.rim then st.rim:Destroy() end
end
CollectionService:GetInstanceAddedSignal("FinishWorn"):Connect(function(c) task.defer(addWearer, c) end)
CollectionService:GetInstanceRemovedSignal("FinishWorn"):Connect(dropWearer)
for _, c in ipairs(CollectionService:GetTagged("FinishWorn")) do addWearer(c) end

-- a kill flares the killer's finish
task.spawn(function()
	local feed = ReplicatedStorage:WaitForChild("KillFeedRemote", 60)
	if not feed then return end
	feed.OnClientEvent:Connect(function(what, entry)
		if what ~= "Kill" or type(entry) ~= "table" then return end
		local plr = entry.killerId and entry.killerId ~= 0 and Players:GetPlayerByUserId(entry.killerId)
		local cont = plr and plr.Character and plr.Character:FindFirstChild("Armor")
		local st = cont and wearers[cont]
		if st then surge(st, true) end
	end)
end)

--------------------------------------------------------------------
--  EVERY FRAME
--------------------------------------------------------------------
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	local cam = workspace.CurrentCamera
	local eye = cam and cam.CFrame.Position

	-- the wearers: who's near enough, what they're doing
	local rims = {}
	for cont, st in pairs(wearers) do
		local char = st.char
		if not (cont.Parent == char and char.Parent) then dropWearer(cont); continue end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		local near = st.preview or (eye ~= nil and (root.Position - eye).Magnitude < FAR)
		if not near then
			if st.motes then dropMotes(st) end
			for _, t in ipairs(st.trails or {}) do t[1].Enabled = false end
			continue
		end
		-- glints, on every finish
		if now >= st.nextGlint then
			st.nextGlint = now + rng:NextNumber(1.2, 2.8) / st.tier
			glint(st, now)
		end
		local vel = st.preview and Vector3.zero or root.AssemblyLinearVelocity
		local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
		-- footprints
		if st.tier >= 2 and not st.preview then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.FloorMaterial ~= Enum.Material.Air and speed > 3 then
				st.walked += speed * dt
				if st.walked > 2.3 then st.walked = 0; st.side = -st.side; footstep(st, now) end
			end
		end
		-- streaks and surges
		if st.tier >= 3 then
			if not st.preview then
				if not st.trails then makeTrails(st) end
				local on = speed > 14 or char:GetAttribute("Acting") == true   -- (sprinting: walking is 11)
				for _, t in ipairs(st.trails) do
					t[1].Enabled = on
					if st.radiant then t[1].Color = ColorSequence.new(accentOf(st, now)) end
				end
			end
			if now >= st.nextSurge then
				st.nextSurge = now + rng:NextNumber(6, 9) - st.tier
				surge(st, false)
			end
		end
		-- motes and the rim
		if st.tier >= 4 then
			if not st.motes then makeMotes(st) end
			local centre = root.Position + Vector3.new(0, 0.6, 0)
			for i, m in ipairs(st.motes) do
				local a = now * 1.6 + m.phase
				local pos = centre + Vector3.new(math.cos(a) * 2.3, math.sin(now * 2 + i) * 0.5 + math.sin(a) * m.tilt, math.sin(a) * 2.3)
				m.core.Position = pos
				local col = accentOf(st, now + i * 0.3)
				m.core.Color = col:Lerp(WHITE, 0.15)
				for _, s in ipairs(m.arms) do
					s.CFrame = (eye and not st.preview) and CFrame.lookAt(pos, eye) * CFrame.Angles(0, 0, now * 3 + math.rad(s:GetAttribute("Spin"))) or CFrame.new(pos) * CFrame.Angles(0, now, now * 3 + math.rad(s:GetAttribute("Spin")))
					s.Color = col:Lerp(WHITE, 0.35)
				end
			end
			if not st.preview then table.insert(rims, {st, (root.Position - eye).Magnitude}) end
		end
	end
	-- the rims: the nearest Mythic wearers only
	table.sort(rims, function(a, b) return a[2] < b[2] end)
	local keep = {}
	for i = 1, math.min(#rims, MAX_RIMS) do keep[rims[i][1]] = true end
	for _, st in pairs(wearers) do
		if keep[st] then
			if not st.rim then
				local h = Instance.new("Highlight")
				h.Name = "FinishRim"
				h.DepthMode = Enum.HighlightDepthMode.Occluded
				h.FillTransparency = 0.94
				h.OutlineTransparency = 0.35
				h.Adornee = st.char
				h.Parent = st.char
				st.rim = h
			end
			local col = accentOf(st, now)
			st.rim.OutlineColor = col; st.rim.FillColor = col
		elseif st.rim then
			st.rim:Destroy(); st.rim = nil
		end
	end

	-- the glowing trims, 30 times a second
	acc += dt
	if acc < 1 / 30 then return end
	acc = 0
	for p, g in pairs(parts) do
		if not p.Parent then parts[p] = nil; continue end
		-- (far away in the world: left as it is)
		if eye and p:IsDescendantOf(workspace) and (p.Position - eye).Magnitude > 160 then continue end
		local w = g.cont and wearers[g.cont]
		local flash = w and math.clamp(1 - (now - w.flash) / 0.6, 0, 1) or 0
		local c
		if g.mode == "radiant" then
			c = Color3.fromHSV((now * 0.15 + g.seed) % 1, 0.6, 0.72)
		elseif g.mode == "flicker" then
			local k = rng:NextNumber() < 0.12 and rng:NextNumber(0.3, 0.7) or 1
			c = g.base:Lerp(WHITE, (1 - k) * 0.6)
			p.Transparency = (k < 1) and 0.25 or 0
		else   -- pulse
			local k = 0.5 + 0.5 * math.sin(now * 2.4 + g.seed)
			c = g.base:Lerp(Color3.new(0, 0, 0), 0.35 * (1 - k))
		end
		p.Color = flash > 0 and c:Lerp(WHITE, flash * 0.75) or c
	end
end)
