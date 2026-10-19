--[[ DRAGON — Dragonfall's wyrm (Game ▸ Modes ▸ Dragonfall): a body of its own (no person's rig)
     built from parts on joints, flown and walked by the server, every joint moved on everyone's
     screen (StarterPlayerScripts ▸ Dragon.client). It is a Humanoid model in workspace ▸ NPCs, so
     every blade, arrow and spell hits it like anything else (no head to stab through: it has
     none called Head), and its blows are the bosses' (Combat ▸ BossMoves: telegraphed, dodged
     through, some blocked).

       Dragon.build() -> model                  its body, at rest (the menu's copy uses it too)
       Dragon.spawn(opts) -> dragon             opts.at (CFrame on the ground), opts.arena
                                                {centre, radius}, opts.hp, opts.onState(state),
                                                opts.onDeath(killerPlayer), opts.onHarpoon(n, need)
       dragon:harpoon(plr) -> bool              a ballista's bolt struck it (Dragonfall): in the air,
                                                enough bring it down; on the ground, two close
                                                together PIN it (staggered, open)
       dragon:rockfall(plr, at) -> bool         boulders cut down on it (Dragonfall's traps): it's
                                                FELLED, down a while, everyone strike
       dragon.state                             intro · ground · takeoff · sky · crash · downed ·
                                                land · inferno · dead
       Dragon.publishDisplay()                  a still copy for the Play menu (MonsterDisplays ▸ Dragon)

     ON THE GROUND it stalks the nearest of you, turning slowly (get to its side), and fights in
     PATTERNS you can learn (COMBOS: which one by where you all are): CLAW then BITE when you're at
     its front, TAIL then STOMP when you're behind it, a WING BUFFET then FIRE BREATH when you crowd
     it, FIRE BREATH at range, a CHARGE then its TAIL at whoever keeps away (into the cliffs: it
     reels), a STOMP then a BITE right under it; enraged, each runs one blow longer. Every blow is
     called over its head as it winds up (its name, and what to do the first few times: MoveName,
     MoveTip, MoveTick; Dragon.client), and after every pattern it's OPEN a moment (it takes more
     from every blow: "OPENING"); after its fire, its belly glows and it's open longer. At two thirds it TAKES TO THE SKY: strafing runs of fire,
     fireballs at each of you, and its brood called up out of the lava; BALLISTAE bring it down
     (enough bolts and it CRASHES, DOWNED for a while: everyone strike). Under a third it is
     ENRAGED: quicker, the caldera rains fire, and now and then it rises over the middle and
     breathes INFERNO over everything — only the ward stones shelter you. Near the end (a fifth
     left) it takes to the sky ONE LAST TIME: the ballistae again. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Moves = require(script.Parent:WaitForChild("BossMoves"))
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local MagicServer = require(script.Parent:WaitForChild("MagicServer"))
local Powers = require(script.Parent:WaitForChild("Powers"))

local Dragon = {}
Dragon.__index = Dragon
Dragon.NAME = "Cindermaw"
Dragon.TITLE = "THE ASHEN WYRM"

local GROUND_H = 8       -- its root above the ground, standing
local SKY_ALT = 44
local CIRCLE_R = 58
local SC = Color3.fromRGB(58, 42, 40)
local SC2 = Color3.fromRGB(74, 50, 44)
local BELLY = Color3.fromRGB(168, 104, 62)
local HORN = Color3.fromRGB(226, 212, 182)
local MEM = Color3.fromRGB(122, 34, 26)
local EMBER = Color3.fromRGB(255, 120, 30)
local EYE = Color3.fromRGB(255, 206, 80)
local FIRE = Color3.fromRGB(255, 130, 40)

local fxFolder = workspace:FindFirstChild("MonsterFX") or Instance.new("Folder")
fxFolder.Name = "MonsterFX"; fxFolder.Parent = workspace

local function now() return os.clock() end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function V(x, y, z) return Vector3.new(x, y, z) end

--------------------------------------------------------------------
--  THE BODY (at rest: its root at the origin, facing -Z, the ground at y = -GROUND_H)
--------------------------------------------------------------------
-- {name, shape, size, at, parent, joint (where it turns), look (it points from `at` this way), color, material, extra}
local PARTS = {}
local function add(name, shape, size, at, parent, o)
	o = o or {}
	table.insert(PARTS, {name = name, shape = shape, size = size, at = at, parent = parent, joint = o.joint, look = o.look,
		color = o.color or SC, mat = o.mat or Enum.Material.Slate, noQuery = o.noQuery, rot = o.rot, transparency = o.transparency})
end
local function seg(name, shape, from, to, w, h, parent, o)
	o = o or {}
	o.joint = o.joint or from
	o.look = to
	add(name, shape, V(w, h, (to - from).Magnitude + (o.extra or 0)), (from + to) / 2, parent, o)
end

-- the body
add("Chest", "ell", V(10, 9, 12), V(0, 1, -5), "HumanoidRootPart", {joint = V(0, 0, 3)})
add("Belly", "ell", V(11, 8.5, 13), V(0, 0, 5), "HumanoidRootPart")
add("Underside", "ell", V(8, 5, 19), V(0, -2.7, 0.5), "HumanoidRootPart", {color = BELLY})
add("Hips", "ell", V(9, 8, 9), V(0, 0.6, 11.5), "HumanoidRootPart", {joint = V(0, 0.6, 9)})
for i, z in ipairs({-10, -7, -4, -1, 2, 5, 8, 11}) do
	local h = 2.6 - i * 0.14
	add("Spine" .. i, "wedge", V(0.7, h, 2.2), V(0, 5.2 - math.abs(z) * 0.03 + h / 2 - 0.5, z), z < 0 and "Chest" or "HumanoidRootPart", {color = SC2})
end
for _, s in ipairs({-1, 1}) do
	add("Ember" .. (s < 0 and "L" or "R") .. 1, "box", V(0.2, 0.3, 6), V(s * 5, 0.8, -4), "Chest", {color = EMBER, mat = Enum.Material.Neon, rot = CFrame.Angles(0, 0, s * 0.3), noQuery = true})
	add("Ember" .. (s < 0 and "L" or "R") .. 2, "box", V(0.2, 0.3, 7), V(s * 5.4, -0.2, 5), "HumanoidRootPart", {color = EMBER, mat = Enum.Material.Neon, rot = CFrame.Angles(0, 0, s * 0.2), noQuery = true})
end
-- the neck, the head
local NP = {V(0, 3, -10), V(0, 5.2, -13.5), V(0, 7.2, -16.8), V(0, 8.7, -19.8), V(0, 9.6, -22.3)}
local NW = {5.4, 4.8, 4.3, 4}
for i = 1, 4 do
	seg("Neck" .. i, "ell", NP[i], NP[i + 1], NW[i], NW[i] * 0.95, i == 1 and "Chest" or ("Neck" .. (i - 1)), {extra = 1.6})
	add("NeckSpine" .. i, "wedge", V(0.5, 1.5 - i * 0.15, 1.6), (NP[i] + NP[i + 1]) / 2 + V(0, NW[i] * 0.45, 0), "Neck" .. i, {color = SC2})
end
add("Skull", "ell", V(5, 4.2, 6), V(0, 10, -24.4), "Neck4", {joint = NP[5]})
add("Snout", "box", V(3.6, 2.4, 6), V(0, 9.5, -28.6), "Skull")
add("SnoutRidge", "wedge", V(3.6, 1.2, 6), V(0, 11.3, -28.6), "Skull", {color = SC2})
add("Jaw", "box", V(3.2, 1.3, 6.6), V(0, 7.9, -27.6), "Skull", {joint = V(0, 8.4, -24.6), color = SC2})
for _, s in ipairs({-1, 1}) do
	local k = s < 0 and "L" or "R"
	add("Eye" .. k, "ball", V(0.8, 0.8, 0.8), V(s * 1.9, 10.8, -25.8), "Skull", {color = EYE, mat = Enum.Material.Neon, noQuery = true})
	add("Brow" .. k, "wedge", V(1.3, 0.7, 2.2), V(s * 1.9, 11.5, -25.4), "Skull", {color = SC2})
	seg("HornBase" .. k, "box", V(s * 1.6, 11.8, -22.8), V(s * 2.5, 13.8, -19), 0.95, 0.95, "Skull", {color = HORN, mat = Enum.Material.SmoothPlastic, joint = V(0, 10, -24.4)})
	seg("HornTip" .. k, "box", V(s * 2.5, 13.8, -19), V(s * 2.7, 14.4, -15.8), 0.55, 0.55, "Skull", {color = HORN, mat = Enum.Material.SmoothPlastic, joint = V(0, 10, -24.4)})
	add("Frill" .. k, "wedge", V(0.4, 1.6, 2.4), V(s * 2.6, 9.4, -22.8), "Skull", {color = MEM, mat = Enum.Material.Fabric, rot = CFrame.Angles(0, 0, s * 0.5)})
	for t = 0, 2 do
		add("Tooth" .. k .. t, "wedge", V(0.3, 0.8, 0.3), V(s * 1.5, 8.05, -26.4 - t * 1.5), "Skull", {color = HORN, mat = Enum.Material.SmoothPlastic, rot = CFrame.Angles(0, 0, math.pi), noQuery = true})
	end
end
-- the legs
for _, s in ipairs({-1, 1}) do
	local k = s < 0 and "L" or "R"
	add("FrontArm" .. k, "ell", V(3.2, 6.4, 3.6), V(s * 5.6, -2.5, -6.4), "Chest", {joint = V(s * 5, 0.5, -6)})
	add("FrontShin" .. k, "ell", V(2.2, 4.6, 2.4), V(s * 5.8, -5.9, -7), "FrontArm" .. k, {joint = V(s * 5.8, -4.6, -6.8), color = SC2})
	add("FrontPaw" .. k, "box", V(3.2, 1.2, 4.2), V(s * 5.8, -7.4, -7.9), "FrontShin" .. k, {joint = V(s * 5.8, -7.2, -7.2), color = SC2})
	add("HindHaunch" .. k, "ell", V(4.3, 7.6, 5.6), V(s * 5.6, -1.4, 11.8), "Hips", {joint = V(s * 5, 0.5, 11)})
	add("HindShank" .. k, "ell", V(2.4, 5, 2.6), V(s * 5.8, -5.5, 13.2), "HindHaunch" .. k, {joint = V(s * 5.8, -3.9, 13.3), color = SC2})
	add("HindPaw" .. k, "box", V(3.4, 1.2, 4.4), V(s * 5.8, -7.4, 11.9), "HindShank" .. k, {joint = V(s * 5.8, -7.2, 12.6), color = SC2})
	for c = -1, 1 do
		add("Claw" .. k .. "F" .. (c + 2), "wedge", V(0.6, 0.9, 1.3), V(s * 5.8 + c * 1.05, -7.6, -10.6), "FrontPaw" .. k, {color = HORN, mat = Enum.Material.SmoothPlastic, noQuery = true})
		add("Claw" .. k .. "H" .. (c + 2), "wedge", V(0.6, 0.9, 1.3), V(s * 5.8 + c * 1.1, -7.6, 9.2), "HindPaw" .. k, {color = HORN, mat = Enum.Material.SmoothPlastic, noQuery = true})
	end
end
-- the tail
local TP = {V(0, 0.6, 14.5), V(0, -0.2, 19.5), V(0, -1.2, 24.5), V(0, -2.3, 29.5), V(0, -3.2, 34), V(0, -3.8, 38), V(0, -4.2, 41.5)}
local TW = {5.4, 4.6, 3.8, 3, 2.2, 1.5}
for i = 1, 6 do
	seg("Tail" .. i, "ell", TP[i], TP[i + 1], TW[i], TW[i] * 0.92, i == 1 and "Hips" or ("Tail" .. (i - 1)), {extra = 1.8})
	if i <= 4 then add("TailSpine" .. i, "wedge", V(0.5, 1.6 - i * 0.2, 1.8), (TP[i] + TP[i + 1]) / 2 + V(0, TW[i] * 0.45, 0), "Tail" .. i, {color = SC2}) end
end
add("TailBlade", "box", V(3.4, 0.45, 3.4), V(0, -4.3, 43.6), "Tail6", {rot = CFrame.Angles(0, math.pi / 4, 0), color = SC2})
add("TailEmber", "box", V(2.2, 0.5, 2.2), V(0, -4.25, 43.6), "Tail6", {rot = CFrame.Angles(0, math.pi / 4, 0), color = EMBER, mat = Enum.Material.Neon, noQuery = true})
-- the wings: bones, and their skin in triangles
local function wing(s)
	local k = s < 0 and "L" or "R"
	local S, E, W = V(s * 3.5, 4.8, -4), V(s * 14, 11, -1), V(s * 24, 8, 2)
	local F1, F2, F3, B = V(s * 33, 3, 5), V(s * 29, -0.5, 9.5), V(s * 21, 0.5, 12.5), V(s * 5, 3.5, 9)
	seg("WingArm" .. k, "box", S, E, 1.3, 1.3, "Chest", {color = SC2})
	seg("WingFore" .. k, "box", E, W, 1, 1, "WingArm" .. k, {color = SC2})
	seg("WingFinger" .. k .. 1, "box", W, F1, 0.6, 0.6, "WingFore" .. k, {color = SC2, joint = W})
	seg("WingFinger" .. k .. 2, "box", W, F2, 0.6, 0.6, "WingFore" .. k, {color = SC2, joint = W})
	seg("WingFinger" .. k .. 3, "box", W, F3, 0.6, 0.6, "WingFore" .. k, {color = SC2, joint = W})
	add("WingThumb" .. k, "wedge", V(0.6, 1.4, 0.6), E + V(0, 1, -0.6), "WingArm" .. k, {color = HORN, mat = Enum.Material.SmoothPlastic, noQuery = true})
	return {k = k, S = S, E = E, W = W, F1 = F1, F2 = F2, F3 = F3, B = B}
end
local WINGS = {wing(-1), wing(1)}

-- a flat triangle a-b-c as two wedges (the classic way): a wing's skin
local function tri(a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then c, a = a, c elseif acd > bcd and acd > abd then a, b = b, a end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	return {
		{size = V(0.25, height, math.abs(ab:Dot(back))), cf = CFrame.fromMatrix((a + b) / 2, right, up, back)},
		{size = V(0.25, height, math.abs(ac:Dot(back))), cf = CFrame.fromMatrix((a + c) / 2, -right, up, -back)},
	}
end

function Dragon.build()
	local m = Instance.new("Model")
	m.Name = Dragon.NAME
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = V(6, 6, 6)
	root.Transparency = 1
	root.CanCollide, root.CanQuery, root.CanTouch = false, false, false
	root.CFrame = CFrame.new()
	root.Parent = m
	local byName = {HumanoidRootPart = root}
	local function joint(p, parentName, at)
		local p0 = byName[parentName]
		local j = Instance.new("Motor6D")
		j.Name = p.Name
		j.Part0, j.Part1 = p0, p
		local jcf = CFrame.new(at)
		j.C0 = p0.CFrame:Inverse() * jcf
		j.C1 = p.CFrame:Inverse() * jcf
		j.Parent = p0
	end
	for _, d in ipairs(PARTS) do
		local p = Instance.new(d.shape == "wedge" and "WedgePart" or "Part")
		p.Name = d.name
		p.Size = d.size
		local cf = d.look and CFrame.lookAt(d.at, d.look) or CFrame.new(d.at)
		if d.rot then cf = cf * d.rot end
		p.CFrame = cf
		p.Color, p.Material = d.color, d.mat
		if d.transparency then p.Transparency = d.transparency end
		if d.shape == "ball" then p.Shape = Enum.PartType.Ball end
		if d.shape == "ell" then local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p end
		p.CanCollide, p.CanTouch, p.CanQuery = false, false, not d.noQuery
		p.Massless = true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
		byName[d.name] = p
		joint(p, d.parent, d.joint or d.at)
	end
	-- the wings' skin
	for _, w in ipairs(WINGS) do
		local sets = {
			{w.S, w.E, w.B, "WingArm"}, {w.E, w.F3, w.B, "WingArm"}, {w.E, w.W, w.F3, "WingFore"}, {w.W, w.F2, w.F3, "WingFore"}, {w.W, w.F1, w.F2, "WingFore"},
		}
		for i, t in ipairs(sets) do
			for j, piece in ipairs(tri(t[1], t[2], t[3])) do
				local p = Instance.new("WedgePart")
				p.Name = "Membrane" .. w.k .. i .. j
				p.Size, p.CFrame = piece.size, piece.cf
				p.Color, p.Material, p.Transparency = MEM, Enum.Material.Fabric, 0.06
				p.CanCollide, p.CanTouch, p.CanQuery, p.Massless = false, false, true, true
				p.Parent = m
				local parent = byName[t[4] .. w.k]
				local wj = Instance.new("WeldConstraint"); wj.Part0, wj.Part1 = parent, p; wj.Parent = p
			end
		end
	end
	-- the fire in its mouth, its belly's glow
	local mouth = Instance.new("Attachment")
	mouth.Name = "Mouth"
	mouth.CFrame = byName.Snout.CFrame:Inverse() * CFrame.new(V(0, 9.1, -31.7))
	mouth.Parent = byName.Snout
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness, glow.Shadows = FIRE, 16, 1.2, false
	glow.Parent = byName.Chest
	m.PrimaryPart = root
	m:SetAttribute("CustomBody", true)
	m:SetAttribute("Dragon", true)
	return m
end

--------------------------------------------------------------------
--  IN THE WORLD
--------------------------------------------------------------------
local function rayParams(self)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local skip = {fxFolder, self and self.model}
	for _, n in ipairs({"NPCs", "LootDrops", "DroppedWeapons"}) do local f = workspace:FindFirstChild(n); if f then table.insert(skip, f) end end
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
	p.FilterDescendantsInstances = skip
	p.RespectCanCollide = true
	return p
end
local function groundY(self, x, z)
	local hit = workspace:Raycast(V(x, 260, z), V(0, -520, 0), rayParams(self))
	return hit and hit.Position.Y or 0
end

local function humOf(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function rootOf(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function players(self, range)
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h, r = humOf(c), rootOf(c)
		if h and r and h.Health > 0 and (not range or (r.Position - self.root.Position).Magnitude < range) then table.insert(out, c) end
	end
	return out
end
local function grounded(c)
	local h = humOf(c)
	return h and h.FloorMaterial ~= Enum.Material.Air
end
local function sound(id, at, vol, speed)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = V(1, 1, 1); p.Position = at; p.Parent = fxFolder
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol or 1; s.PlaybackSpeed = speed or 1; s.RollOffMaxDistance = 400
	s.Parent = p; s:Play()
	Debris:AddItem(p, 6)
end
local BOOM = "rbxasset://sounds/impact_explosion_03.mp3"
local ROAR = "rbxasset://sounds/HalloweenGhost.wav"

local function burst(pos, color, n, speed, size)
	local a = Instance.new("Part")
	a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.Transparency = true, false, false, false, 1
	a.Size = V(1, 1, 1); a.Position = pos; a.Parent = fxFolder
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/fire_main.dds"
	pe.Color = ColorSequence.new(color or FIRE, Color3.fromRGB(255, 60, 20))
	pe.LightEmission = 1
	pe.Speed = NumberRange.new((speed or 30) * 0.4, speed or 30)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.5, 1.2)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size or 3), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
	pe.Rate = 0
	pe.Parent = a
	pe:Emit(n or 40)
	Debris:AddItem(a, 2)
end

-- FIRE ON THE GROUND: a burning patch that hurts who stands in it
function Dragon:firePatch(pos, r, life)
	local at = V(pos.X, groundY(self, pos.X, pos.Z) + 0.1, pos.Z)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Shape = Enum.PartType.Cylinder
	p.Size = V(0.2, r * 2, r * 2)
	p.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2)
	p.Material, p.Color, p.Transparency = Enum.Material.Neon, Color3.fromRGB(255, 96, 20), 0.35
	p.Parent = fxFolder
	local f = Instance.new("Fire"); f.Size = r * 1.4; f.Heat = 9; f.Color = FIRE; f.SecondaryColor = Color3.fromRGB(255, 60, 10); f.Parent = p
	TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
	Debris:AddItem(p, life)
	task.spawn(function()
		local t0 = now()
		local last = {}
		while now() - t0 < life - 0.3 and self.alive do
			for _, c in ipairs(players(self)) do
				local cr = rootOf(c)
				if cr and flat(cr.Position - at).Magnitude < r and math.abs(cr.Position.Y - at.Y) < 6 and now() - (last[c] or 0) > 0.5 then
					last[c] = now()
					MagicServer.hurt(self.model, c, 5, "Dragonfire")
				end
			end
			task.wait(0.1)
		end
	end)
end

-- a blow (Combat ▸ BossMoves.strike: dodge through it, block the ones that can be)
function Dragon:hit(c, dmg, name, from, o)
	o = o or {}
	local spec = {name = name, burn = o.burn}
	return Moves.strike(self.mob, c, dmg, spec, from, {blockable = o.blockable, knock = o.knock, lift = o.lift})
end

-- the ground point under its mouth, and where its mouth is
function Dragon:mouth()
	return self.root.CFrame * CFrame.new(0, 9, -31)
end
function Dragon:feet() return V(self.pos.X, self.pos.Y - GROUND_H, self.pos.Z) end

--------------------------------------------------------------------
--  SPAWN
--------------------------------------------------------------------
function Dragon.spawn(opts)
	local self = setmetatable({}, Dragon)
	self.opts = opts
	self.arena = opts.arena or {centre = Vector3.zero, radius = 100}
	local m = Dragon.build()
	self.model = m
	self.root = m.HumanoidRootPart
	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = opts.hp or 2000
	hum.Health = hum.MaxHealth
	hum.Parent = m
	self.hum = hum
	for k, v in pairs({Boss = true, BossName = Dragon.NAME, Team = "B", Bot = true, Unflinching = true, TagName = Dragon.NAME, SpellPower = 1}) do m:SetAttribute(k, v) end
	-- how it moves: held where the server says (smooth on every screen: physics carries it)
	local att = Instance.new("Attachment"); att.Name = "Drive"; att.Parent = self.root
	local ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment; ap.Attachment0 = att; ap.RigidityEnabled = true; ap.Parent = self.root
	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; ao.Attachment0 = att; ao.RigidityEnabled = true; ao.Parent = self.root
	self.ap, self.ao = ap, ao
	local at = opts.at or CFrame.new(self.arena.centre)
	local look = at.LookVector
	self.yaw = math.atan2(-look.X, -look.Z)
	self.pitch, self.roll = 0, 0
	self.pos = at.Position + V(0, SKY_ALT + 30, 0)
	m:PivotTo(CFrame.new(self.pos) * CFrame.Angles(0, self.yaw, 0))
	ap.Position = self.pos
	ao.CFrame = CFrame.Angles(0, self.yaw, 0)
	local npcs = workspace:FindFirstChild("NPCs") or Instance.new("Folder")
	npcs.Name = "NPCs"; npcs.Parent = workspace
	-- (whole on every screen at once: Dragon.client wants every joint)
	pcall(function() m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)
	m.Parent = npcs
	pcall(function() self.root:SetNetworkOwner(nil) end)
	hum.PlatformStand = true
	self.alive = true
	self.mob = {model = m, def = {name = Dragon.NAME, moveFx = "ember"}, alive = true, boss = true, bot = {startAt = 0, hum = hum}}
	self.cd = {}
	self.hits = 0
	self.state = "intro"
	self.phase = 1
	self.speedMul, self.gapMul = 1, 1
	-- where it's going, frame by frame
	self.conn = RunService.Heartbeat:Connect(function(dt) self:step(dt) end)
	hum.Died:Once(function() self:die() end)
	task.spawn(function() self:brain() end)
	return self
end

function Dragon:setState(s)
	self.state = s
	self.model:SetAttribute("DragonState", s)
	if self.opts.onState then task.spawn(self.opts.onState, s, self) end
end

function Dragon:attr(k, v) if self.model.Parent then self.model:SetAttribute(k, v) end end
function Dragon:tick(k) self:attr(k, (self.model:GetAttribute(k) or 0) + 1) end

-- the one it's after: the nearest, now and then another
function Dragon:target()
	local best, bestD
	for _, c in ipairs(players(self, 240)) do
		local d = (rootOf(c).Position - self.root.Position).Magnitude
		if c == self.focus then d *= 0.7 end
		if not bestD or d < bestD then best, bestD = c, d end
	end
	if now() > (self.focusUntil or 0) then self.focus, self.focusUntil = best, now() + 8 end
	return best, bestD
end

--------------------------------------------------------------------
--  EVERY FRAME: where it is
--------------------------------------------------------------------
local function lerpAngle(a, b, t)
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * t
end
function Dragon:turnTo(pos, rate, dt)
	local to = flat(pos - self.pos)
	if to.Magnitude < 0.5 then return 0 end
	local want = math.atan2(-to.X, -to.Z)
	local d = (want - self.yaw + math.pi) % (2 * math.pi) - math.pi
	local step = math.clamp(d, -rate * dt, rate * dt)
	self.yaw += step
	return math.abs(d)
end
function Dragon:keepIn(p)
	local c = self.arena.centre
	local off = flat(p - c)
	local lim = self.arena.radius - 16
	if off.Magnitude > lim then p = V(c.X, p.Y, c.Z) + off.Unit * lim end
	return p
end

function Dragon:step(dt)
	if not self.alive then return end
	local s = self.state
	if s == "ground" and not self.busy then
		-- stalk the nearest: it turns slowly (get to its side), and comes on
		local tgt = self:target()
		local tr = rootOf(tgt)
		if tr then
			-- (where its head looks: a few times a second, not every frame)
			if now() - (self.lookSent or 0) > 0.25 then self.lookSent = now(); self:attr("Look", tr.Position) end
			local off = self:turnTo(tr.Position, 1.05 * self.speedMul, dt)
			local dist = flat(tr.Position - self.pos).Magnitude
			if dist > 20 and off < 0.9 then
				local fwd = V(-math.sin(self.yaw), 0, -math.cos(self.yaw))
				self.pos = self:keepIn(self.pos + fwd * 13 * self.speedMul * dt)
			end
		end
		self.pos = V(self.pos.X, self.pos.Y + ((groundY(self, self.pos.X, self.pos.Z) + GROUND_H) - self.pos.Y) * math.min(1, dt * 8), self.pos.Z)
	elseif s == "sky" and not self.busy then
		-- round and round the caldera, high up
		self.orbit = (self.orbit or 0) + dt * 24 / CIRCLE_R
		local c = self.arena.centre
		local want = c + V(math.cos(self.orbit) * CIRCLE_R, SKY_ALT, math.sin(self.orbit) * CIRCLE_R)
		self.pos = self.pos:Lerp(want, math.min(1, dt * 1.6))
		local tang = V(-math.sin(self.orbit), 0, math.cos(self.orbit))
		self.yaw = lerpAngle(self.yaw, math.atan2(-tang.X, -tang.Z), math.min(1, dt * 2))
		self.roll = -0.25
	end
	if s ~= "sky" and s ~= "takeoff" and s ~= "inferno" then self.roll *= math.max(0, 1 - dt * 3) end
	self.ap.Position = self.pos
	self.ao.CFrame = CFrame.Angles(0, self.yaw, 0) * CFrame.Angles(self.pitch, 0, self.roll)
end

-- carried along a path over `t` seconds (fn(a) -> position, yaw or nil)
function Dragon:glide(t, fn)
	local t0 = now()
	while self.alive do
		local a = math.clamp((now() - t0) / t, 0, 1)
		local p, yaw = fn(a)
		self.pos = p
		if yaw then self.yaw = yaw end
		if a >= 1 then break end
		RunService.Heartbeat:Wait()
	end
end

--------------------------------------------------------------------
--  ITS BLOWS (on the ground)
--------------------------------------------------------------------
local A = {}
-- what each blow is called over its head, and what to do (the tip only the first few times)
local MOVE_INFO = {
	bite = {"BITE", "STEP OUT OF THE RING UNDER ITS JAWS"},
	claw = {"CLAW", "BACK OFF, OR BLOCK IT"},
	tail = {"TAIL SWEEP", "JUMP IT, OR DODGE AWAY"},
	buffet = {"WING BUFFET", "GET OUT FROM UNDER IT"},
	stomp = {"STOMP", "GET OUT FROM UNDER IT"},
	charge = {"CHARGE", "STEP OUT OF THE LANE  ·  LURE IT INTO THE CLIFFS"},
	breath = {"FIRE BREATH", "GET UNDER ITS HEAD, OR BEHIND IT"},
	open = {"OPENING", "STRIKE IT NOW"},
	belly = {"ITS BELLY GLOWS", "STRIKE IT NOW: IT TAKES DOUBLE"},
	pinned = {"PINNED!", "THE BOLTS HOLD IT  ·  STRIKE"},
	felled = {"FELLED!", "THE ROCKS HAVE IT DOWN  ·  STRIKE"},
}
local TELL_TIMES = 3
function Dragon:call(k)
	local info = MOVE_INFO[k]
	if not info then return end
	self.told = self.told or {}
	self.told[k] = (self.told[k] or 0) + 1
	self:attr("MoveName", info[1])
	self:attr("MoveTip", self.told[k] <= TELL_TIMES and info[2] or "")
	self:tick("MoveTick")
end

-- a bite: a ring under its jaws fills, the jaws snap shut
A.bite = function(self, tgt)
	local tr = rootOf(tgt)
	if not tr then return end
	self:call("bite")
	self:faceQuick(tr.Position, 0.35)
	self:attr("Jaw", 0.6)
	local m = self:mouth()
	local at = V(m.Position.X, self:feet().Y, m.Position.Z)
	Moves.circle(at, 9, FIRE, 0.75)
	task.wait(0.75)
	self:attr("Jaw", 0)
	self:tick("Snap")
	sound("rbxasset://sounds/swordslash.wav", at, 1, 0.45)
	for _, c in ipairs(players(self)) do
		local cr = rootOf(c)
		if cr and flat(cr.Position - at).Magnitude < 9 and math.abs(cr.Position.Y - at.Y) < 10 then self:hit(c, 30, "Bite", self.pos, {blockable = true, knock = 32}) end
	end
	task.wait(0.5)
end
-- a claw: an arc in front fills, then the swipe
A.claw = function(self, tgt)
	if not rootOf(tgt) then return end
	self:call("claw")
	self:faceQuick(rootOf(tgt).Position, 0.3)
	local base = CFrame.new(self:feet()) * CFrame.Angles(0, self.yaw, 0)
	Moves.arc(base, 22, math.rad(55), FIRE, 0.8)
	self:tick("Swipe")
	task.wait(0.8)
	sound("rbxasset://sounds/swordslash.wav", self.pos, 1, 0.5)
	local fwd = base.LookVector
	for _, c in ipairs(players(self)) do
		local to = flat(rootOf(c).Position - self:feet())
		if to.Magnitude < 22 and to.Magnitude > 2 and math.acos(math.clamp(to.Unit:Dot(flat(fwd).Unit), -1, 1)) < math.rad(60) then
			self:hit(c, 24, "Claw", self.pos, {blockable = true, knock = 30})
		end
	end
	task.wait(0.4)
end
-- its tail behind it: an arc at its back, only the ones on the ground (jump it, or dodge)
A.tail = function(self)
	self:call("tail")
	local hip = self.root.CFrame * CFrame.new(0, -GROUND_H, 12)
	local base = CFrame.new(hip.Position) * CFrame.Angles(0, self.yaw + math.pi, 0)
	Moves.arc(base, 28, math.rad(75), FIRE, 0.9)
	task.wait(0.55)
	self:tick("Tail")
	task.wait(0.35)
	sound(BOOM, hip.Position, 0.7, 1.4)
	for _, c in ipairs(players(self)) do
		local to = flat(rootOf(c).Position - hip.Position)
		if to.Magnitude < 28 and to.Magnitude > 0.5 and math.acos(math.clamp(to.Unit:Dot(flat(base.LookVector).Unit), -1, 1)) < math.rad(80) and grounded(c) then
			self:hit(c, 26, "Tail Sweep", hip.Position, {knock = 46, lift = 18})
		end
	end
	task.wait(0.5)
end
-- its wings: a gust that throws everyone close away
A.buffet = function(self)
	self:call("buffet")
	Moves.circle(self:feet(), 19, FIRE, 0.85)
	self:tick("Buffet")
	task.wait(0.85)
	Moves.remote:FireAllClients("Shake", self:feet(), 1)
	burst(self:feet() + V(0, 1, 0), Color3.fromRGB(200, 170, 140), 50, 50, 4)
	for _, c in ipairs(players(self)) do
		local cr = rootOf(c)
		if flat(cr.Position - self:feet()).Magnitude < 19 then self:hit(c, 12, "Wing Buffet", self:feet(), {knock = 72, lift = 26}) end
	end
	task.wait(0.6)
end
-- a stomp: the ground under it
A.stomp = function(self)
	self:call("stomp")
	self:attr("Rear", 0.6)
	Moves.circle(self:feet(), 13, FIRE, 0.75)
	task.wait(0.75)
	self:attr("Rear", 0)
	sound(BOOM, self:feet(), 1, 0.8)
	Moves.remote:FireAllClients("Shake", self:feet(), 1.4)
	burst(self:feet() + V(0, 1, 0), Color3.fromRGB(160, 130, 110), 60, 40, 4)
	for _, c in ipairs(players(self)) do
		local cr = rootOf(c)
		if flat(cr.Position - self:feet()).Magnitude < 13 then self:hit(c, 22, "Stomp", self:feet(), {knock = 40}) end
	end
	task.wait(0.5)
end
-- a charge: a lane lights up, then it barrels down it (into the cliffs: it reels)
A.charge = function(self, tgt)
	local tr = rootOf(tgt)
	if not tr then return end
	local dir = flat(tr.Position - self.pos)
	if dir.Magnitude < 1 then return end
	dir = dir.Unit
	self:call("charge")
	self:faceQuick(self.pos + dir * 10, 0.45)
	local len = math.min(80, (flat(tr.Position - self.pos)).Magnitude + 16)
	-- (the lane stops short of the caldera's wall)
	local c = self.arena.centre
	local stopAt = len
	for d = 0, len, 2 do
		if flat(self.pos + dir * d - c).Magnitude > self.arena.radius - 16 then stopAt = d; break end
	end
	Moves.lane(self:feet(), dir, stopAt + 10, 15, FIRE, 1.1)
	self:attr("Rear", 0.3)
	task.wait(1.1)
	self:attr("Rear", 0)
	sound(BOOM, self.pos, 0.6, 1.6)
	local from = self.pos
	local hit = {}
	local t = stopAt / 58
	self:glide(math.max(0.2, t), function(a)
		local p = from + dir * stopAt * a
		p = V(p.X, groundY(self, p.X, p.Z) + GROUND_H, p.Z)
		for _, ch in ipairs(players(self)) do
			local cr = rootOf(ch)
			if not hit[ch] and flat(cr.Position - p).Magnitude < 9 then
				hit[ch] = true
				self:hit(ch, 30, "Charge", p - dir * 3, {blockable = true, knock = 50, lift = 22})
			end
		end
		return p
	end)
	if stopAt < len - 1 then
		-- into the wall: it reels, open
		Moves.remote:FireAllClients("Shake", self.pos, 1.6)
		burst(self.pos + dir * 8, Color3.fromRGB(200, 190, 180), 50, 30, 4)
		self.model:SetAttribute("GuardText", "STAGGERED")
		Powers.addMods(self.model, {taken = 1.35}, 3, "Staggered")
		self:attr("Reel", true)
		task.wait(3)
		self:attr("Reel", nil)
	end
	task.wait(0.3)
end
-- FIRE BREATH: its head comes up, an arc lights across the ground, then the fire sweeps it
A.breath = function(self, tgt)
	if not rootOf(tgt) then return end
	self:call("breath")
	self:faceQuick(rootOf(tgt).Position, 0.4)
	self:attr("Rear", 1)
	self:attr("Jaw", 0.5)
	local base = CFrame.new(self:feet()) * CFrame.Angles(0, self.yaw, 0)
	Moves.arc(base * CFrame.new(0, 0, -6), 54, math.rad(48), FIRE, 1.3)
	Moves.remote:FireAllClients("Flash", self.model, FIRE, 1.3)
	task.wait(1.3)
	if not self.alive then return end
	self:attr("Jaw", 1)
	self:attr("Breath", true)
	sound(BOOM, self.pos, 0.5, 0.6)
	local side = math.random() < 0.5 and 1 or -1
	local t0 = now()
	local dur = 2.4
	local last, lastPatch = {}, 0
	while now() - t0 < dur and self.alive do
		local a = (now() - t0) / dur
		local off = side * math.rad(-45 + 90 * a)
		self:attr("BreathYaw", off)
		local dir = CFrame.Angles(0, self.yaw + off, 0).LookVector
		local mouth = self:mouth().Position
		local ground = V(mouth.X, self:feet().Y, mouth.Z)
		for _, c in ipairs(players(self)) do
			local cr = rootOf(c)
			local to = flat(cr.Position - ground)
			if to.Magnitude < 54 and to.Magnitude > 0.5 and math.acos(math.clamp(to.Unit:Dot(flat(dir).Unit), -1, 1)) < math.rad(14) and now() - (last[c] or 0) > 0.3 then
				local los = workspace:Raycast(mouth, cr.Position - mouth, rayParams(self))
				if not los then
					last[c] = now()
					self:hit(c, 7, "Fire Breath", mouth, {knock = 6, lift = 2, burn = 4})
				end
			end
		end
		if now() - lastPatch > 0.35 then
			lastPatch = now()
			self:firePatch(ground + flat(dir).Unit * (14 + math.random() * 30), 5, 3.2)
		end
		RunService.Heartbeat:Wait()
	end
	self:attr("Breath", nil)
	self:attr("BreathYaw", nil)
	self:attr("Jaw", 0)
	self:attr("Rear", 0)
	task.wait(0.6)
end

-- a quick turn to face somewhere (its attacks swing it round)
function Dragon:faceQuick(pos, t)
	local to = flat(pos - self.pos)
	if to.Magnitude < 0.5 then return end
	local want = math.atan2(-to.X, -to.Z)
	local from = self.yaw
	self:glide(t, function(a) return self.pos, lerpAngle(from, want, a) end)
	self:attr("Look", pos)
end

-- OPEN: after a pattern it stops a moment to breathe, and every blow on it lands harder
function Dragon:opening(k, dur, mult)
	if not self.alive then return end
	self:call(k)
	self:attr("Open", true)
	Powers.addMods(self.model, {taken = mult}, dur, "Opening")
	Moves.remote:FireAllClients("Flash", self.model, k == "belly" and FIRE or Color3.fromRGB(255, 220, 140), 0.5)
	local t0 = now()
	while self.alive and now() - t0 < dur and not self.felled and not self.pinNow do task.wait(0.1) end
	self:attr("Open", nil)
end

-- THE PATTERNS: a few blows in a row, always the same ones in the same order (learn them), then
-- an opening. Which one, by where you all are; enraged, each runs one blow longer
local COMBOS = {
	{k = "claws", moves = {"claw", "bite"}, rage = {"claw", "bite", "claw"}, cd = 5},
	{k = "rear", moves = {"tail", "stomp"}, rage = {"tail", "stomp", "tail"}, cd = 6},
	{k = "gust", moves = {"buffet", "breath"}, rage = {"buffet", "breath", "stomp"}, cd = 14},
	{k = "fire", moves = {"breath"}, rage = {"breath", "charge"}, cd = 13},
	{k = "rush", moves = {"charge", "tail"}, rage = {"charge", "charge", "tail"}, cd = 10},
	{k = "trample", moves = {"stomp", "bite"}, rage = {"stomp", "bite", "buffet"}, cd = 7},
}
local COMBO = {}
for _, c in ipairs(COMBOS) do COMBO[c.k] = c end
function Dragon:runCombo(c)
	local list = self.enraged and c.rage or c.moves
	local fiery = false
	for i, m in ipairs(list) do
		if not self.alive or self.felled or self.pinNow or self.state ~= "ground" then return end
		local tgt = self:target()
		if not rootOf(tgt) then return end
		A[m](self, tgt)
		if m == "breath" then fiery = true end
		if i < #list then task.wait(0.3 * self.gapMul) end
	end
	if not self.alive or self.felled or self.pinNow then return end
	-- (after its fire its belly glows: open longer, and every blow lands double)
	if fiery then self:opening("belly", 3.4, 2) else self:opening("open", 2.2, 1.45) end
end

-- which pattern, by where you all are
function Dragon:choose()
	local tgt, dist = self:target()
	local tr = rootOf(tgt)
	if not tr then return nil end
	local function ready(k) return now() >= (self.cd[k] or 0) end
	local function use(k, cd) self.cd[k] = now() + cd * self.gapMul end
	local pool, total = {}, 0
	local function opt(k, w, _, cd)
		local c = COMBO[k]
		if c and ready(k) and w > 0 then table.insert(pool, {k = k, w = w, fn = function() self:runCombo(c) end, cd = c.cd}); total += w end
	end
	-- who's where, from its point of view
	local behind, close, front = 0, 0, false
	for _, c in ipairs(players(self, 60)) do
		local l = self.root.CFrame:PointToObjectSpace(rootOf(c).Position)
		local d = flat(l).Magnitude
		if l.Z > 6 and d < 34 then behind += 1 end
		if d < 17 then close += 1 end
	end
	-- (the one it's after, from its point of view: X right, Z behind)
	local lt = self.root.CFrame:PointToObjectSpace(tr.Position)
	local side = math.abs(lt.X)
	local underJaw = lt.Z < -14 and lt.Z > -42 and side < 12
	local beside = lt.Z < 6 and lt.Z > -26 and side < 24
	opt("rear", behind > 0 and 5 or 0)
	opt("gust", close >= 2 and 4 or (close >= 1 and 1 or 0))
	opt("trample", flat(lt).Magnitude < 12 and 3 or 0)
	opt("claws", (underJaw or beside) and 4 or 0)
	opt("fire", (dist > 18 and dist < 64 and lt.Z < 0) and 3 or 0)
	opt("rush", dist > 38 and 4 or 0)
	if #pool == 0 then return nil end
	local x = math.random() * total
	for _, o in ipairs(pool) do
		x -= o.w
		if x <= 0 then use(o.k, o.cd); return o.fn end
	end
	use(pool[1].k, pool[1].cd)
	return pool[1].fn
end

--------------------------------------------------------------------
--  THE SKY
--------------------------------------------------------------------
function Dragon:roar(knock)
	self:attr("Rear", 1); self:attr("Jaw", 1)
	sound(ROAR, self.pos, 3, 0.35)
	sound(BOOM, self.pos, 0.8, 0.4)
	Moves.remote:FireAllClients("Shake", self.pos, 2.2)
	Moves.remote:FireAllClients("Flash", self.model, Color3.fromRGB(255, 80, 40), 1.4)
	if knock then
		for _, c in ipairs(players(self)) do
			if flat(rootOf(c).Position - self:feet()).Magnitude < 22 then self:hit(c, 4, "Roar", self:feet(), {knock = 60, lift = 20}) end
		end
	end
	task.wait(1.6)
	self:attr("Rear", 0); self:attr("Jaw", 0)
end

function Dragon:takeOff()
	self:setState("takeoff")
	self:roar(true)
	self:attr("Fly", true)
	self:tick("Buffet")
	local from = self.pos
	local c = self.arena.centre
	self.orbit = math.atan2(from.Z - c.Z, from.X - c.X)
	local to = c + V(math.cos(self.orbit) * CIRCLE_R, SKY_ALT, math.sin(self.orbit) * CIRCLE_R)
	burst(self:feet() + V(0, 1, 0), Color3.fromRGB(190, 160, 130), 80, 60, 5)
	self:glide(3, function(a) return from:Lerp(to, a * a * (3 - 2 * a)) end)
	self.hits = 0
	self.skyUntil = now() + 75
	self:setState("sky")
end

-- the sky's blows: fireballs at each of you
local function fireball(self, at)
	local from = self:mouth().Position
	local ball = Instance.new("Part")
	ball.Anchored, ball.CanCollide, ball.CanQuery, ball.CanTouch = true, false, false, false
	ball.Shape = Enum.PartType.Ball; ball.Size = V(3.4, 3.4, 3.4)
	ball.Material, ball.Color = Enum.Material.Neon, FIRE
	ball.Position = from
	ball.Parent = fxFolder
	local f = Instance.new("Fire"); f.Size = 7; f.Heat = 12; f.Color = FIRE; f.SecondaryColor = Color3.fromRGB(255, 50, 10); f.Parent = ball
	local l = Instance.new("PointLight"); l.Color = FIRE; l.Range = 20; l.Brightness = 3; l.Parent = ball
	local dur = 1.5
	TweenService:Create(ball, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = at + V(0, 1, 0)}):Play()
	Debris:AddItem(ball, dur + 0.05)
	task.delay(dur, function()
		if not self.alive then return end
		sound(BOOM, at, 0.8, 1)
		burst(at + V(0, 1, 0), FIRE, 50, 34, 4)
		Moves.remote:FireAllClients("Shake", at, 0.9)
		for _, c in ipairs(players(self)) do
			local cr = rootOf(c)
			if flat(cr.Position - at).Magnitude < 7.5 and math.abs(cr.Position.Y - at.Y) < 8 then self:hit(c, 20, "Fireball", at, {knock = 28, lift = 24, burn = 4}) end
		end
		self:firePatch(at, 6, 3.5)
	end)
end
local S = {}
S.fireballs = function(self)
	self:attr("Jaw", 1)
	local spots = {}
	for _, c in ipairs(players(self, 260)) do
		local cr = rootOf(c)
		table.insert(spots, V(cr.Position.X, groundY(self, cr.Position.X, cr.Position.Z), cr.Position.Z))
	end
	local cc = self.arena.centre
	for _ = 1, 2 do
		local a, d = math.random() * 6.28, math.random() * (self.arena.radius - 24)
		local x, z = cc.X + math.cos(a) * d, cc.Z + math.sin(a) * d
		table.insert(spots, V(x, groundY(self, x, z), z))
	end
	for i, at in ipairs(spots) do
		Moves.circle(at, 7.5, FIRE, 1.5)
		task.delay((i - 1) * 0.15, function() fireball(self, at) end)
	end
	task.wait(1.9 + #spots * 0.15)
	self:attr("Jaw", 0)
end
-- a strafing run: a lane across the caldera lights up, then it flies down it low, breathing fire
S.strafe = function(self)
	local tgt = self:target()
	local tr = rootOf(tgt)
	if not tr then return end
	local c = self.arena.centre
	local through = V(tr.Position.X, 0, tr.Position.Z)
	local a = math.random() * 6.28
	local dir = V(math.cos(a), 0, math.sin(a))
	local half = self.arena.radius - 6
	local startG, endG = through - dir * half, through + dir * half
	-- (from where it is to the run's start, up high)
	local from = self.pos
	local startAir = V(startG.X, c.Y + 28, startG.Z)
	local yaw = math.atan2(-dir.X, -dir.Z)
	self:glide(2.2, function(k) return from:Lerp(startAir, k * k * (3 - 2 * k)), lerpAngle(self.yaw, yaw, k) end)
	if not self.alive then return end
	local gy = groundY(self, through.X, through.Z)
	Moves.lane(V(startG.X, gy, startG.Z), dir, half * 2, 13, FIRE, 1.4)
	task.wait(1.1)
	self:attr("Breath", true); self:attr("Jaw", 1); self:attr("BreathYaw", 0)
	self.pitch = 0.18
	local hit, lastPatch = {}, 0
	local endAir = V(endG.X, c.Y + 18, endG.Z)
	self:glide(2.6, function(k)
		local p = startAir:Lerp(endAir, k)
		p = V(p.X, c.Y + 18 + math.sin(k * math.pi) * -2, p.Z)
		local under = V(p.X, 0, p.Z) + dir * 10
		for _, ch in ipairs(players(self)) do
			local cr = rootOf(ch)
			local rel = flat(cr.Position) - under
			if not hit[ch] and rel.Magnitude < 8 then hit[ch] = true; self:hit(ch, 24, "Strafing Fire", cr.Position + V(0, 6, 0), {knock = 20, lift = 12, burn = 5}) end
		end
		if now() - lastPatch > 0.2 then lastPatch = now(); self:firePatch(under, 5.5, 4) end
		return p, yaw
	end)
	self.pitch = 0
	self:attr("Breath", nil); self:attr("Jaw", 0); self:attr("BreathYaw", nil)
end

-- a ballista's bolt struck it. ON THE GROUND: a heavy wound, and two close together PIN it
-- (staggered, open: everyone strike), not again for a while
function Dragon:harpoon(plr)
	if not self.alive then return false end
	if self.state == "ground" or self.state == "downed" then
		if plr and plr.Character then CombatServer.credit(self.model, plr.Character, "Ballista", "Bolt") end
		self.hum:TakeDamage(self.hum.MaxHealth * 0.035)
		Moves.remote:FireAllClients("Flash", self.model, Color3.fromRGB(255, 255, 255), 0.4)
		local recent = {}
		for _, t in ipairs(self.boltsAt or {}) do if now() - t < 12 then table.insert(recent, t) end end
		table.insert(recent, now())
		self.boltsAt = recent
		local pinned = #recent >= 2 and self.state == "ground" and now() > (self.pinFreeAt or 0)
		if pinned then self.pinNow = true; self.boltsAt = {} end
		if self.opts.onBolt then task.spawn(self.opts.onBolt, plr, pinned, #recent) end
		return true
	end
	if self.state ~= "sky" then return false end
	self.hits += 1
	if plr and plr.Character then CombatServer.credit(self.model, plr.Character, "Ballista", "Bolt") end
	self.hum:TakeDamage(self.hum.MaxHealth * 0.03)
	Moves.remote:FireAllClients("Flash", self.model, Color3.fromRGB(255, 255, 255), 0.4)
	if self.opts.onHarpoon then task.spawn(self.opts.onHarpoon, self.hits, self.need or 3, plr) end
	if self.hits >= (self.need or 3) then self.downNow = true end
	return true
end

-- PINNED: the bolts hold it where it stands, a while (after a pattern's blow, never mid-air)
function Dragon:pinned()
	self.pinNow = false
	self.pinFreeAt = now() + 22
	self:call("pinned")
	self:attr("Reel", true)
	self:attr("Open", true)
	Moves.remote:FireAllClients("Shake", self.pos, 1.2)
	Powers.addMods(self.model, {taken = 1.6}, 5, "Pinned")
	sound(ROAR, self.pos, 2.4, 0.5)
	task.wait(5)
	self:attr("Reel", nil)
	self:attr("Open", nil)
end

-- BOULDERS ON IT (a Dragonfall trap cut loose over where it stood): a crushing wound, and down
function Dragon:rockfall(plr, at)
	if not self.alive or (self.state ~= "ground" and self.state ~= "downed") then return false end
	if flat(self:feet() - at).Magnitude > 20 then return false end
	if plr and plr.Character then CombatServer.credit(self.model, plr.Character, "Rockfall", "Rocks") end
	self.hum:TakeDamage(self.hum.MaxHealth * 0.08)
	Moves.remote:FireAllClients("Flash", self.model, Color3.fromRGB(255, 255, 255), 0.6)
	self.felled = true
	return true
end
function Dragon:felledDown()
	self.felled = false
	self:call("felled")
	self:setState("downed")
	self:attr("Downed", true)
	Powers.addMods(self.model, {taken = 1.5}, 6, "Felled")
	task.wait(6)
	self:attr("Downed", nil)
	if self.alive then self:roar(true) end
	if self.alive then self:setState("ground") end
end

function Dragon:crash()
	self:setState("crash")
	self:attr("Fly", nil)
	self:attr("Breath", nil)
	local from = self.pos
	local c = self.arena.centre
	local land = flat(from - c)
	land = c + (land.Magnitude > 1 and land.Unit or V(1, 0, 0)) * math.min(land.Magnitude, self.arena.radius - 30)
	land = V(land.X, groundY(self, land.X, land.Z) + GROUND_H - 1, land.Z)
	self.roll = 0.5
	self:glide(1.3, function(a) return from:Lerp(land, a * a) + V(0, math.sin(a * math.pi) * 4, 0) end)
	sound(BOOM, land, 1.4, 0.5)
	Moves.remote:FireAllClients("Shake", land, 2.6)
	burst(land - V(0, 6, 0), Color3.fromRGB(180, 150, 120), 120, 60, 6)
	for _, ch in ipairs(players(self)) do
		if flat(rootOf(ch).Position - land).Magnitude < 16 then self:hit(ch, 18, "Crash", land, {knock = 50}) end
	end
	self.roll = 0
	self:setState("downed")
	self:attr("Downed", true)
	Powers.addMods(self.model, {taken = 1.5}, 9, "Downed")
	task.wait(9)
	self:attr("Downed", nil)
	if self.alive then self:roar(true) end
	self.phase = math.max(self.phase, 2)
	self:setState("ground")
end
function Dragon:land()
	self:setState("land")
	local from = self.pos
	local c = self.arena.centre
	local to = V(c.X + math.random(-20, 20), 0, c.Z + math.random(-20, 20))
	to = V(to.X, groundY(self, to.X, to.Z) + GROUND_H, to.Z)
	self:glide(2.6, function(a) return from:Lerp(to, a * a * (3 - 2 * a)) end)
	self:attr("Fly", nil)
	sound(BOOM, to, 0.9, 0.6)
	Moves.remote:FireAllClients("Shake", to, 1.4)
	self.phase = math.max(self.phase, 2)
	self:setState("ground")
end

--------------------------------------------------------------------
--  ENRAGED, AND THE INFERNO
--------------------------------------------------------------------
function Dragon:enrage()
	self.enraged = true
	self:attr("Enraged", true)
	self.speedMul, self.gapMul = 1.2, 0.75
	Moves.remote:FireAllClients("Phase", self.model, "ITS FURY IS UNLEASHED")
	self:roar(true)
	self.infernoAt = now() + 8
	self.rainAt = now() + 4
	self.phase = 3
	if self.opts.onState then task.spawn(self.opts.onState, "enraged", self) end
end

-- it rises over the middle, and breathes over everything: only the ward stones shelter you
function Dragon:inferno()
	self:setState("inferno")
	self:attr("Fly", true)
	self:tick("Buffet")
	local c = self.arena.centre
	local from = self.pos
	local over = V(c.X, groundY(self, c.X, c.Z) + 28, c.Z)
	self:glide(2.2, function(a) return from:Lerp(over, a * a * (3 - 2 * a)) end)
	-- the wind-up: its belly glows, the caldera shakes
	self:attr("Rear", 1); self:attr("Jaw", 0.4)
	for _ = 1, 6 do
		if not self.alive then return end
		Moves.remote:FireAllClients("Flash", self.model, FIRE, 0.55)
		Moves.remote:FireAllClients("Shake", over, 0.6)
		self.yaw += 0.35
		task.wait(0.6)
	end
	if not self.alive then return end
	self:attr("Jaw", 1); self:attr("Breath", true)
	sound(BOOM, over, 2, 0.4)
	sound(ROAR, over, 3, 0.3)
	-- the blast: a sphere of fire swelling over the caldera
	local ball = Instance.new("Part")
	ball.Anchored, ball.CanCollide, ball.CanQuery, ball.CanTouch = true, false, false, false
	ball.Shape = Enum.PartType.Ball; ball.Size = V(8, 8, 8)
	ball.Material, ball.Color, ball.Transparency = Enum.Material.Neon, FIRE, 0.3
	ball.Position = over - V(0, 10, 0)
	ball.Parent = fxFolder
	TweenService:Create(ball, TweenInfo.new(1.4, Enum.EasingStyle.Quad), {Size = V(1, 1, 1) * self.arena.radius * 2.2, Transparency = 1}):Play()
	Debris:AddItem(ball, 1.5)
	Moves.remote:FireAllClients("Shake", over, 2.4)
	local mouth = self:mouth().Position
	for _, ch in ipairs(players(self)) do
		local cr = rootOf(ch)
		local to = cr.Position + V(0, 1, 0) - mouth
		local shelter = workspace:Raycast(mouth, to, rayParams(self))
		if shelter then
			ch:SetAttribute("GuardText", "SHELTERED"); ch:SetAttribute("GuardTick", (ch:GetAttribute("GuardTick") or 0) + 1)
		else
			self:hit(ch, 46, "Inferno", mouth, {knock = 30, lift = 10, burn = 6})
		end
	end
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		self:firePatch(c + V(math.cos(a) * 30, 0, math.sin(a) * 30), 6, 3)
	end
	task.wait(1.2)
	self:attr("Breath", nil); self:attr("Jaw", 0); self:attr("Rear", 0)
	self:land()
	self.infernoAt = now() + 40
end

--------------------------------------------------------------------
--  THE BRAIN
--------------------------------------------------------------------
function Dragon:intro()
	-- out of the sky, onto the caldera, a roar
	local c = self.arena.centre
	local at = self.opts.at and self.opts.at.Position or c
	local land = V(at.X, groundY(self, at.X, at.Z) + GROUND_H, at.Z)
	local from = self.pos
	self:attr("Fly", true)
	self:glide(4, function(a) return from:Lerp(land, 1 - (1 - a) ^ 2) end)
	self:attr("Fly", nil)
	sound(BOOM, land, 1.2, 0.55)
	Moves.remote:FireAllClients("Shake", land, 2)
	burst(land - V(0, 6, 0), Color3.fromRGB(180, 150, 120), 100, 60, 6)
	self:setState("ground")
	self:roar(true)
end

function Dragon:brain()
	local ok, err = pcall(self.intro, self)
	if not ok then warn("[Dragon] intro", err); self:setState("ground") end
	while self.alive and self.model.Parent do
		local frac = self.hum.Health / self.hum.MaxHealth
		local s = self.state
		if s == "ground" then
			if frac <= 0.66 and not self.flown then
				self.flown = true
				self.busy = true
				local ok, err = pcall(self.takeOff, self)
				if not ok then warn("[Dragon] take off", err); self:setState("sky") end
				self.busy = false
			elseif frac <= 0.2 and self.enraged and not self.flownAgain then
				-- one last time into the sky (the ballistae again)
				self.flownAgain = true
				self.busy = true
				local ok, err = pcall(self.takeOff, self)
				if not ok then warn("[Dragon] take off", err); self:setState("sky") end
				self.busy = false
			elseif frac <= 0.33 and not self.enraged then
				self.busy = true
				pcall(self.enrage, self)
				self.busy = false
			elseif self.enraged and now() >= (self.infernoAt or 1e9) then
				self.busy = true
				local ok, err = pcall(self.inferno, self)
				if not ok then warn("[Dragon] inferno", err); self.infernoAt = now() + 40; if self.state ~= "ground" then pcall(self.land, self) end end
				self.busy = false
			elseif self.felled then
				self.busy = true
				local ok, err = pcall(self.felledDown, self)
				if not ok then warn("[Dragon] felled", err); self:setState("ground") end
				self.busy = false
			elseif self.pinNow then
				self.busy = true
				local ok, err = pcall(self.pinned, self)
				if not ok then warn("[Dragon] pinned", err) end
				self.busy = false
			else
				if self.enraged and now() >= (self.rainAt or 1e9) then
					self.rainAt = now() + 11
					task.spawn(function()
						pcall(Moves.KINDS.rain, self.mob, {name = "Falling Fire", count = 6, radius = 5, dmg = 16, fx = "ember", burn = 4, silent = true}, self.arena)
					end)
				end
				local fn = self:choose()
				if fn then
					self.busy = true
					local ok, err = pcall(fn)
					if not ok then warn("[Dragon]", err) end
					self.busy = false
				end
				task.wait((0.9 + math.random() * 0.8) * self.gapMul)
			end
		elseif s == "sky" then
			if self.downNow then
				self.downNow = false
				self.busy = true
				pcall(self.crash, self)
				self.busy = false
			elseif now() > (self.skyUntil or 0) then
				self.busy = true
				pcall(self.land, self)
				self.busy = false
			else
				task.wait(2.6 + math.random() * 1.6)
				if self.state == "sky" and not self.downNow and self.alive then
					self.busy = true
					local ok, err = pcall(math.random() < 0.55 and S.strafe or S.fireballs, self)
					if not ok then warn("[Dragon] sky", err) end
					self.busy = false
				end
			end
		else
			task.wait(0.2)
		end
	end
end

function Dragon:die()
	if not self.alive then return end
	self.alive = false
	self.mob.alive = false
	self.busy = true
	self:setState("dead")
	self:attr("Dead", true)
	self:attr("Breath", nil)
	self:attr("Fly", nil)
	local killerId = self.model:GetAttribute("LastHitBy")
	local killer = killerId and Players:GetPlayerByUserId(killerId)
	-- it comes down, and lies where it fell
	local from = self.pos
	local land = V(from.X, groundY(self, from.X, from.Z) + 4.5, from.Z)
	local roll0 = self.roll
	sound(ROAR, from, 3, 0.25)
	task.spawn(function()
		local t0 = now()
		while now() - t0 < 2.4 do
			local a = math.clamp((now() - t0) / 2.4, 0, 1)
			self.pos = from:Lerp(land, a * a)
			self.roll = roll0 + (1.35 - roll0) * a
			self.ap.Position = self.pos
			self.ao.CFrame = CFrame.Angles(0, self.yaw, 0) * CFrame.Angles(0, 0, self.roll)
			RunService.Heartbeat:Wait()
		end
		sound(BOOM, land, 1.6, 0.4)
		Moves.remote:FireAllClients("Shake", land, 2.5)
		burst(land, Color3.fromRGB(180, 150, 120), 120, 60, 6)
		if self.conn then self.conn:Disconnect() end
		if self.root.Parent then self.root.Anchored = true end
	end)
	if self.opts.onDeath then task.spawn(self.opts.onDeath, killer) end
end

function Dragon:destroy()
	self.alive = false
	if self.conn then self.conn:Disconnect() end
	if self.model then self.model:Destroy() end
end

--------------------------------------------------------------------
--  THE MENU'S COPY (ReplicatedStorage ▸ MonsterDisplays ▸ Dragon): still, its wings up, small
--------------------------------------------------------------------
function Dragon.publishDisplay()
	local f = ReplicatedStorage:FindFirstChild("MonsterDisplays")
	if not f then f = Instance.new("Folder"); f.Name = "MonsterDisplays"; f.Parent = ReplicatedStorage end
	if f:FindFirstChild("Dragon") then return end
	local m = Dragon.build()
	-- (posed: its wings raised, its head up; then every part held where it is)
	for _, j in ipairs(m:GetDescendants()) do
		if j:IsA("Motor6D") then
			local n = j.Name
			if n:match("^WingArm") then
				local s = n:sub(-1) == "L" and -1 or 1
				j.C0 = j.C0 * CFrame.Angles(0, s * 0.15, s * 0.35)
			elseif n == "Neck1" then j.C0 = j.C0 * CFrame.Angles(0.25, 0, 0)
			elseif n == "Jaw" then j.C0 = j.C0 * CFrame.Angles(-0.35, 0, 0) end
		end
	end
	m.HumanoidRootPart.Anchored = true
	m.Parent = workspace
	RunService.Heartbeat:Wait()
	RunService.Heartbeat:Wait()
	local cfs = {}
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then cfs[p] = p.CFrame end end
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("Motor6D") or d:IsA("WeldConstraint") or d:IsA("PointLight") then d:Destroy() end end
	for p, cf in pairs(cfs) do p.Anchored = true; p.CFrame = cf end
	m.WorldPivot = CFrame.new(0, -GROUND_H, 0)
	m:ScaleTo(0.36)
	m.Name = "Dragon"
	m.Parent = f
end

return Dragon
