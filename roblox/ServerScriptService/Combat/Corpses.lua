--[[ CORPSES — what a death leaves on the field. A fallen fighter is laid out
     where they dropped: a still copy of everything you could see of them (armor,
     hair, face; their severed limbs join it), which lies there a while and
     fades with its limbs as one (Janitor "Corpse": CONFIG.LIFE seconds, at most
     LIMIT at once, the oldest first). The real body is hidden, not destroyed,
     so a death camera riding the head keeps working until the respawn.

     A kill effect decides what is left (Catalog ▸ KillFX `remains`, laid
     `remainsAt` seconds into the effect): body · skeleton (picked clean, black
     feathers about) · ash (a charred skeleton in a heap of ash, smoking) ·
     charred (the body blackened, smoking) · gold (a golden statue with a crown)
     · rubble (blocks of the body's colours) · coins · confetti · shards (ice)
     · rift (a scorched ring) · light (a few glowing feathers) · none (nothing)
     · grave (a headstone over a fresh mound) · flat (squashed flat into a dent)
     · stone (a stone statue) · mound (a heap of sand) · puddle (dark water, a
     tentacle tip) · garden (a mossy mound in flower) · crater (charred in a
     crater) · bones (a picked pile with the skull on top) — and with anything
     but a body or a statue, the limbs it lost go with it. Remains that don't
     need the body itself keep their time even if a player respawns first.

       Corpses.died(char)            CharacterSystems, on death (lays a body after SETTLE)
       Corpses.lay(char, kind)       lay it out now (idempotent)
       Corpses.idOf(char)            the id severed limbs carry (attribute CorpseOf)
       Corpses.pending(char, kind, inSeconds)   a kill effect's remains are coming ]]

local Players = game:GetService("Players")
local Janitor = require(script.Parent:WaitForChild("Janitor"))

local Corpses = {}
Corpses.CONFIG = {
	SETTLE = 2.8,     -- seconds after death a body (no kill effect) is laid out for good
	HOLD = 4.5,       -- the longest a body may wait for its kill effect's remains
	BONE = Color3.fromRGB(226, 218, 196),
	CHAR = Color3.fromRGB(36, 30, 27),
	GOLD = Color3.fromRGB(232, 184, 74),
}
local C = Corpses.CONFIG
local M = Enum.Material
local rng = Random.new()

local nextId = 0
function Corpses.idOf(char)
	local id = char:GetAttribute("CorpseId")
	if not id then
		nextId += 1
		id = nextId
		char:SetAttribute("CorpseId", id)
	end
	return id
end

--------------------------------------------------------------------
--  PIECES
--------------------------------------------------------------------
local function piece(model, shape, size, cf, color, mat, transp)
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or M.SmoothPlastic
	p.Transparency = transp or 0
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end
local function ball(model, d, cf, color, mat) return piece(model, Enum.PartType.Ball, Vector3.one * d, cf, color, mat) end
-- a bone along a limb's Y axis: a cylinder (Roblox cylinders run along X)
local function bone(model, cf, len, r, color)
	return piece(model, Enum.PartType.Cylinder, Vector3.new(len, r * 2, r * 2), cf * CFrame.Angles(0, 0, math.pi / 2), color)
end

-- where the floor is under a point (the body and the remains left out)
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Exclude
local function floorUnder(pos, ignore)
	floorParams.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), floorParams)
	return hit and hit.Position.Y or (pos.Y - 1)
end
-- a spot on the floor near a point, laid flat with a random turn
local function onFloor(centre, r, y, lift)
	local a, d = rng:NextNumber(0, math.pi * 2), r * math.sqrt(rng:NextNumber())
	return CFrame.new(centre.X + math.cos(a) * d, y + (lift or 0), centre.Z + math.sin(a) * d) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
end

--------------------------------------------------------------------
--  SKELETONS — bones laid on the limbs where they lie
--------------------------------------------------------------------
local SKEL = {}
SKEL.Head = function(model, cf, col)
	ball(model, 1.0, cf * CFrame.new(0, 0.12, 0.05), col)                                    -- the cranium
	piece(model, nil, Vector3.new(0.62, 0.3, 0.5), cf * CFrame.new(0, -0.3, -0.12), col)     -- the jaw
	piece(model, nil, Vector3.new(0.5, 0.07, 0.06), cf * CFrame.new(0, -0.2, -0.38), Color3.fromRGB(240, 236, 220))   -- teeth
	for _, x in ipairs({-0.2, 0.2}) do ball(model, 0.26, cf * CFrame.new(x, 0.1, -0.4), Color3.fromRGB(20, 18, 16)) end   -- sockets
	piece(model, nil, Vector3.new(0.1, 0.14, 0.06), cf * CFrame.new(0, -0.06, -0.47), Color3.fromRGB(20, 18, 16))         -- the nose
end
SKEL.Torso = function(model, cf, col)
	for i = 0, 4 do piece(model, nil, Vector3.new(0.22, 0.3, 0.22), cf * CFrame.new(0, 0.8 - i * 0.4, 0.28), col) end   -- spine
	for i, y in ipairs({0.55, 0.2, -0.15}) do
		local w = 0.78 - i * 0.06
		for _, s in ipairs({-1, 1}) do
			piece(model, nil, Vector3.new(w, 0.09, 0.09), cf * CFrame.new(s * w / 2, y, 0.22) * CFrame.Angles(0, 0, s * 0.12), col)   -- round the back
			piece(model, nil, Vector3.new(0.09, 0.09, 0.62), cf * CFrame.new(s * w, y - 0.06, -0.06), col)                            -- down the side
			piece(model, nil, Vector3.new(w * 0.8, 0.08, 0.08), cf * CFrame.new(s * w * 0.45, y - 0.1, -0.36) * CFrame.Angles(0, 0, -s * 0.15), col)   -- to the breastbone
		end
	end
	piece(model, nil, Vector3.new(0.14, 0.85, 0.08), cf * CFrame.new(0, 0.2, -0.38), col)                                  -- sternum
	for _, s in ipairs({-1, 1}) do piece(model, nil, Vector3.new(0.75, 0.09, 0.09), cf * CFrame.new(s * 0.45, 0.92, -0.18), col) end   -- collarbones
	piece(model, nil, Vector3.new(1.05, 0.35, 0.5), cf * CFrame.new(0, -0.85, 0.05), col)                                  -- pelvis
end
local function armBones(model, cf, col)
	bone(model, cf * CFrame.new(0, 0.45, 0), 0.95, 0.13, col)
	ball(model, 0.3, cf * CFrame.new(0, -0.05, 0), col)
	for _, x in ipairs({-0.08, 0.08}) do bone(model, cf * CFrame.new(x, -0.5, 0), 0.8, 0.07, col) end
	piece(model, nil, Vector3.new(0.32, 0.28, 0.14), cf * CFrame.new(0, -0.95, 0), col)
end
local function legBones(model, cf, col)
	bone(model, cf * CFrame.new(0, 0.45, 0), 1.0, 0.16, col)
	ball(model, 0.34, cf * CFrame.new(0, -0.08, 0), col)
	bone(model, cf * CFrame.new(0, -0.55, 0), 0.85, 0.13, col)
	piece(model, nil, Vector3.new(0.36, 0.18, 0.62), cf * CFrame.new(0, -0.95, -0.15), col)
end
SKEL["Left Arm"], SKEL["Right Arm"] = armBones, armBones
SKEL["Left Leg"], SKEL["Right Leg"] = legBones, legBones
-- a severed limb's name is "<Limb> (severed)"
local function limbKey(name) return (name:gsub(" %(severed%)$", "")) end

--------------------------------------------------------------------
--  WHAT EACH KIND LEAVES
--------------------------------------------------------------------
-- copies of the parts you could see, where they lie
local function copies(model, parts)
	local out = {}
	for _, p in ipairs(parts) do
		local c = p:Clone()
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("Attachment") or d:IsA("LuaSourceContainer") or d:IsA("Sound")
				or d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("Trail") then
				d:Destroy()
			end
		end
		-- (a severed limb carries its armor as child parts: those hold still too)
		for _, q in ipairs({c, table.unpack(c:GetDescendants())}) do
			if q:IsA("BasePart") then q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.Massless = true, false, false, false, true end
		end
		c.CFrame = p.CFrame
		c.Parent = model
		table.insert(out, c)
	end
	return out
end
local function recolor(parts, color, mat, keepFace)
	for _, c in ipairs(parts) do
		for _, q in ipairs({c, table.unpack(c:GetDescendants())}) do
			if q:IsA("BasePart") then
				q.Color, q.Material = color, mat
				if q:IsA("MeshPart") then q.TextureID = "" end
			elseif (q:IsA("Decal") and not keepFace) or q:IsA("Texture") or q:IsA("SurfaceAppearance") then
				q:Destroy()
			end
		end
	end
end
local function smoke(at, seconds, color, size)
	local a = Instance.new("Attachment")
	a.Parent = at
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(color or Color3.fromRGB(60, 56, 52))
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size or 0.8), NumberSequenceKeypoint.new(1, (size or 0.8) * 3)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(1.6, 2.6)
	e.Rate = 6
	e.Speed = NumberRange.new(0.6, 1.4)
	e.Acceleration = Vector3.new(0, 1.6, 0)
	e.SpreadAngle = Vector2.new(20, 20)
	e.Parent = a
	task.delay(seconds, function() e.Enabled = false end)
end

local KIND = {}
KIND.body = function(model, b)
	copies(model, b.parts)
	copies(model, b.limbs)
	return true
end
KIND.charred = function(model, b)
	local cs = copies(model, b.parts)
	local ls = copies(model, b.limbs)
	recolor(cs, C.CHAR, M.Slate); recolor(ls, C.CHAR, M.Slate)
	if cs[1] then smoke(b.torso and model:FindFirstChild(b.torso.Name) or cs[1], 7) end
	return true
end
KIND.gold = function(model, b)
	local cs = copies(model, b.parts)
	local ls = copies(model, b.limbs)
	recolor(cs, C.GOLD, M.Metal); recolor(ls, C.GOLD, M.Metal)
	-- a crown on the statue's head
	local head = b.rig.Head
	if head then
		local cf = head.CFrame * CFrame.new(0, 0.78, 0)
		piece(model, Enum.PartType.Cylinder, Vector3.new(0.2, 1.05, 1.05), cf * CFrame.Angles(0, 0, math.pi / 2), C.GOLD, M.Metal)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			piece(model, nil, Vector3.new(0.12, 0.3, 0.12), cf * CFrame.new(math.cos(a) * 0.45, 0.22, math.sin(a) * 0.45), C.GOLD, M.Metal)
			ball(model, 0.13, cf * CFrame.new(math.cos(a) * 0.45, 0.42, math.sin(a) * 0.45), Color3.fromRGB(200, 30, 50), M.Glass)
		end
	end
	return true
end
local function skeleton(model, b, col)
	for name, part in pairs(b.rig) do
		if SKEL[name] and part.Transparency < 1 then SKEL[name](model, part.CFrame, col) end
	end
	for _, l in ipairs(b.limbs) do
		local f = SKEL[limbKey(l.Name)]
		if f then f(model, l.CFrame, col) end
	end
end
KIND.skeleton = function(model, b)
	skeleton(model, b, C.BONE)
	-- the crows' leavings: black feathers about the bones
	for _ = 1, 9 do
		piece(model, Enum.PartType.Block, Vector3.new(0.06, 0.04, 0.7), onFloor(b.centre, 2.6, b.floor, 0.03) * CFrame.Angles(0, 0, rng:NextNumber(-0.3, 0.3)), Color3.fromRGB(16, 16, 20))
	end
	return true
end
KIND.ash = function(model, b)
	skeleton(model, b, C.CHAR)
	-- a heap of ash under it, embers going out
	for _ = 1, 9 do
		-- (a Ball part is always round: a flat heap is a block with a sphere mesh)
		local d = rng:NextNumber(1.2, 2.4)
		local p = piece(model, nil, Vector3.new(d, d * 0.28, d), onFloor(b.centre, 1.8, b.floor, 0.05), Color3.fromRGB(70, 66, 62), M.Sand)
		local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p
	end
	for _ = 1, 6 do ball(model, 0.16, onFloor(b.centre, 1.8, b.floor, 0.12), Color3.fromRGB(255, 120, 40), M.Neon) end
	local core = piece(model, nil, Vector3.new(0.2, 0.2, 0.2), CFrame.new(b.centre.X, b.floor + 0.3, b.centre.Z), Color3.new(), nil, 1)
	smoke(core, 8, Color3.fromRGB(48, 44, 40), 1)
	return true
end
KIND.rubble = function(model, b)
	local cols = {}
	for _, p in ipairs(b.parts) do table.insert(cols, p.Color) end
	if #cols == 0 then cols = {Color3.fromRGB(150, 150, 160)} end
	for i = 1, 11 do
		local s = rng:NextNumber(0.35, 0.75)
		piece(model, nil, Vector3.one * s, onFloor(b.centre, 2.8, b.floor, s / 2) * CFrame.Angles(rng:NextNumber(0, 1), 0, rng:NextNumber(0, 1)), cols[(i - 1) % #cols + 1])
	end
	return false
end
KIND.coins = function(model, b)
	local gold = Color3.fromRGB(255, 200, 60)
	for i = 1, 16 do   -- a heap
		local ring, h = math.floor((i - 1) / 6), (i - 1) % 6
		local a = h / 6 * math.pi * 2 + ring
		local r = 0.55 - ring * 0.25
		piece(model, Enum.PartType.Cylinder, Vector3.new(0.1, 0.6, 0.6),
			CFrame.new(b.centre.X + math.cos(a) * r, b.floor + 0.06 + ring * 0.1, b.centre.Z + math.sin(a) * r) * CFrame.Angles(0, a, math.pi / 2 + rng:NextNumber(-0.2, 0.2)), gold, M.Metal)
	end
	for _ = 1, 12 do   -- and some rolled away
		piece(model, Enum.PartType.Cylinder, Vector3.new(0.1, 0.6, 0.6), onFloor(b.centre, 3, b.floor, 0.05) * CFrame.Angles(0, 0, math.pi / 2), gold, M.Metal)
	end
	return false
end
KIND.confetti = function(model, b)
	local palette = {Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 210, 70), Color3.fromRGB(90, 200, 255), Color3.fromRGB(120, 230, 120), Color3.fromRGB(230, 120, 255)}
	for i = 1, 28 do
		piece(model, nil, Vector3.new(0.32, 0.03, 0.2), onFloor(b.centre, 3, b.floor, 0.02), palette[(i - 1) % #palette + 1])
	end
	return false
end
KIND.shards = function(model, b)
	for i = 1, 11 do
		local s = rng:NextNumber(0.4, 1)
		local w = Instance.new("WedgePart")
		w.Size = Vector3.new(s * 0.4, s * 1.4, s)
		w.CFrame = onFloor(b.centre, 2.4, b.floor, s * 0.5) * CFrame.Angles(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
		w.Color = i % 3 == 0 and Color3.fromRGB(240, 250, 255) or Color3.fromRGB(150, 210, 255)
		w.Material = M.Glass
		w.Transparency = 0.25
		w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch = true, false, false, false
		w.Parent = model
	end
	return false
end
KIND.rift = function(model, b)
	piece(model, Enum.PartType.Cylinder, Vector3.new(0.06, 4.6, 4.6), CFrame.new(b.centre.X, b.floor + 0.03, b.centre.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(14, 10, 20), nil, 0.15)
	piece(model, Enum.PartType.Cylinder, Vector3.new(0.07, 3.2, 3.2), CFrame.new(b.centre.X, b.floor + 0.04, b.centre.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(70, 30, 110), M.Neon, 0.6)
	return false
end
KIND.light = function(model, b)
	for i = 1, 7 do
		piece(model, nil, Vector3.new(0.08, 0.03, 0.75), onFloor(b.centre, 2.2, b.floor, 0.03), i % 3 == 0 and Color3.fromRGB(255, 220, 140) or Color3.fromRGB(255, 255, 255), M.Neon)
	end
	return false
end

-- the floor at the body, turned the way its torso faces: the same turn the
-- kill effect was built in (Hub > Cosmetics), so its headstone or squashed
-- body is where the effect left it
local function groundFrame(b)
	local look = b.torso and b.torso.CFrame.LookVector or Vector3.new(0, 0, -1)
	return CFrame.new(b.centre.X, b.floor, b.centre.Z) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
end
-- (a Ball part is always round: any other proportions are a block with a sphere mesh)
local function blob(model, size, cf, color, mat, transp)
	local p = piece(model, nil, size, cf, color, mat, transp)
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p
	return p
end
local function rigColor(b, name, fallback)
	local p = b.rig[name]
	return p and p.Color or fallback
end
local SKIN = Color3.fromRGB(204, 170, 136)

KIND.none = function() return false end
KIND.grave = function(model, b)
	local g = groundFrame(b)
	local stone, cut = Color3.fromRGB(122, 124, 130), Color3.fromRGB(52, 52, 58)
	piece(model, nil, Vector3.new(2, 2.4, 0.4), g * CFrame.new(0, 1.2, -1.6), stone, M.Slate)
	piece(model, Enum.PartType.Cylinder, Vector3.new(0.4, 2, 2), g * CFrame.new(0, 2.4, -1.6) * CFrame.Angles(0, math.pi / 2, 0), stone, M.Slate)
	piece(model, nil, Vector3.new(0.18, 1.1, 0.05), g * CFrame.new(0, 1.85, -1.38), cut)
	piece(model, nil, Vector3.new(0.7, 0.18, 0.05), g * CFrame.new(0, 2.1, -1.38), cut)
	blob(model, Vector3.new(2.2, 0.7, 3.4), g * CFrame.new(0, 0.05, 0.4), Color3.fromRGB(92, 70, 50), M.Ground)
	return false
end
-- squashed flat: the body's colours spread out like a star in a dent in the ground
KIND.flat = function(model, b)
	local g = groundFrame(b)
	local function slab(size, x, z, yaw, c)
		piece(model, nil, size, g * CFrame.new(x, size.Y / 2 + 0.02, z) * CFrame.Angles(0, yaw, 0), c)
	end
	local torso, head = rigColor(b, "Torso", SKIN), rigColor(b, "Head", SKIN)
	local arm, leg = rigColor(b, "Right Arm", SKIN), rigColor(b, "Left Leg", SKIN)
	slab(Vector3.new(2.2, 0.12, 2.2), 0, 0, 0, torso)
	slab(Vector3.new(1.4, 0.1, 1.4), 0, -1.85, 0, head)
	slab(Vector3.new(1.1, 0.1, 2.2), -1.8, -0.4, -0.5, arm)
	slab(Vector3.new(1.1, 0.1, 2.2), 1.8, -0.4, 0.5, arm)
	slab(Vector3.new(1.1, 0.1, 2.3), -0.7, 2.15, 0.2, leg)
	slab(Vector3.new(1.1, 0.1, 2.3), 0.7, 2.15, -0.2, leg)
	piece(model, Enum.PartType.Cylinder, Vector3.new(0.04, 7, 7), g * CFrame.new(0, 0.01, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(64, 58, 52), M.Ground, 0.35)
	return false
end
KIND.stone = function(model, b)
	local cs = copies(model, b.parts)
	local ls = copies(model, b.limbs)
	local grey = Color3.fromRGB(132, 130, 126)
	recolor(cs, grey, M.Slate); recolor(ls, grey, M.Slate)
	for _ = 1, 6 do
		local s = rng:NextNumber(0.2, 0.45)
		piece(model, nil, Vector3.one * s, onFloor(b.centre, 2, b.floor, s / 2) * CFrame.Angles(rng:NextNumber(0, 1), 0, rng:NextNumber(0, 1)), grey, M.Slate)
	end
	return true
end
KIND.mound = function(model, b)
	local sand = Color3.fromRGB(214, 186, 130)
	local g = groundFrame(b)
	blob(model, Vector3.new(3.8, 0.9, 3.8), g * CFrame.new(0, 0.05, 0), sand, M.Sand)
	for _ = 1, 4 do blob(model, Vector3.new(1.4, 0.4, 1.4), onFloor(b.centre, 2.2, b.floor, 0.02), sand:Lerp(Color3.new(0, 0, 0), 0.1), M.Sand) end
	return false
end
KIND.puddle = function(model, b)
	local g = groundFrame(b)
	piece(model, Enum.PartType.Cylinder, Vector3.new(0.06, 5, 5), g * CFrame.new(0, 0.03, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(16, 34, 50), M.Glass, 0.15)
	-- one arm still curled out of it
	local tip = g * CFrame.new(1, 0, 0.6)
	for i = 0, 4 do
		local a = i / 4
		ball(model, 0.55 - a * 0.35, tip * CFrame.new(math.sin(a * 2.4) * 0.6, 0.2 + a * 1.1, -math.cos(a * 2.4) * 0.3 + 0.3), i % 2 == 0 and Color3.fromRGB(110, 60, 140) or Color3.fromRGB(150, 96, 176))
	end
	return false
end
KIND.garden = function(model, b)
	local g = groundFrame(b)
	blob(model, Vector3.new(3.2, 1, 4.2), g * CFrame.new(0, 0.1, 0), Color3.fromRGB(70, 110, 52), M.Grass)
	blob(model, Vector3.new(1.2, 0.8, 1.2), g * CFrame.new(0, 0.3, -1.7), Color3.fromRGB(80, 120, 60), M.Grass)
	local petals = {Color3.fromRGB(255, 140, 180), Color3.fromRGB(255, 230, 100), Color3.fromRGB(250, 250, 250), Color3.fromRGB(190, 140, 255)}
	for i = 1, 9 do
		local at = onFloor(b.centre, 1.6, b.floor, 0)
		local h = rng:NextNumber(0.5, 0.9)
		piece(model, nil, Vector3.new(0.06, h, 0.06), at * CFrame.new(0, h / 2 + 0.3, 0), Color3.fromRGB(60, 120, 50))
		ball(model, 0.34, at * CFrame.new(0, h + 0.32, 0), petals[(i - 1) % #petals + 1])
		ball(model, 0.14, at * CFrame.new(0, h + 0.42, 0), Color3.fromRGB(255, 200, 60))
	end
	return false
end
KIND.crater = function(model, b)
	local keeps = KIND.charred(model, b)
	local g = groundFrame(b)
	piece(model, Enum.PartType.Cylinder, Vector3.new(0.05, 6, 6), g * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(34, 26, 22), M.Slate, 0.1)
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		local s = rng:NextNumber(0.5, 1)
		piece(model, nil, Vector3.new(s, s * 0.7, s), g * CFrame.new(math.cos(a) * 3.1, s * 0.25, math.sin(a) * 3.1) * CFrame.Angles(rng:NextNumber(0, 1), a, rng:NextNumber(0, 1)), Color3.fromRGB(70, 56, 46), M.Slate)
	end
	for _ = 1, 5 do ball(model, 0.16, onFloor(b.centre, 2.4, b.floor, 0.1), Color3.fromRGB(255, 120, 40), M.Neon) end
	return keeps
end
-- picked clean and spat out: a heap of bones, the skull on top
KIND.bones = function(model, b)
	local g = groundFrame(b)
	for _ = 1, 16 do
		local at = onFloor(b.centre, 1.5, b.floor, rng:NextNumber(0.1, 0.45))
		bone(model, at * CFrame.Angles(math.pi / 2 + rng:NextNumber(-0.4, 0.4), 0, 0), rng:NextNumber(0.6, 1.2), rng:NextNumber(0.07, 0.13), C.BONE)
	end
	SKEL.Torso(model, g * CFrame.new(0.4, 0.45, 0.5) * CFrame.Angles(-math.pi / 2, 0, 0.3), C.BONE)
	SKEL.Head(model, g * CFrame.new(-0.2, 0.95, -0.2) * CFrame.Angles(0.2, 0.5, 0.15), C.BONE)
	-- still wet
	piece(model, Enum.PartType.Cylinder, Vector3.new(0.04, 3.6, 3.6), g * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(70, 90, 50), M.Glass, 0.4)
	return false
end
-- these leave nothing of the body itself, so they can be laid after it's gone
local AFTER_BODY = {none = true, grave = true, flat = true, mound = true, puddle = true, garden = true, bones = true, rift = true, light = true}

--------------------------------------------------------------------
--  LAYING OUT
--------------------------------------------------------------------
local RIG = {Head = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true}

-- everything about the body the remains are built from
local function gather(char)
	local id = Corpses.idOf(char)
	local remains = Janitor.folder()
	-- what can be seen of it, and the limbs it lost (lying in Remains, tagged CorpseOf)
	local b = {parts = {}, limbs = {}, rig = {}}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 and not d:FindFirstAncestorOfClass("Tool") then
			table.insert(b.parts, d)
		end
	end
	for name in pairs(RIG) do
		local p = char:FindFirstChild(name)
		if p and p:IsA("BasePart") then b.rig[name] = p end
	end
	for _, l in ipairs(remains:GetChildren()) do
		if l:GetAttribute("CorpseOf") == id and l:IsA("BasePart") then table.insert(b.limbs, l) end
	end
	b.torso = b.rig.Torso
	local at = (b.torso or b.rig.Head or b.parts[1])
	if not at then return nil end
	b.centre = at.Position
	b.floor = floorUnder(b.centre, {char, remains})
	b.id, b.remains = id, remains
	return b
end

local function build(b, kind)
	local id, remains = b.id, b.remains
	local model = Instance.new("Model")
	model.Name = "Corpse"
	model:SetAttribute("CorpseOf", id)
	model:SetAttribute("Kind", kind)
	local keepsLimbs = KIND[kind](model, b)
	model.Parent = remains
	-- its lost limbs: copied into the corpse (or turned to bones, or gone with it)
	for _, l in ipairs(b.limbs) do
		if l.Parent then
			Janitor.forget(l)
			if keepsLimbs then l:Destroy() else Janitor.add(l, "Limb", {life = 0.05, parent = false}) end
		end
	end
	Janitor.add(model, "Corpse")
	return model
end

local function hideBody(char)
	-- the real body goes from sight (it stays for the death camera until the respawn)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then d.Transparency = 1
		elseif d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1
		elseif d:IsA("ParticleEmitter") then d.Enabled = false end
	end
end

-- delay (optional): build the remains that much later, from what the body is
-- now (only for kinds that don't copy the body: AFTER_BODY)
function Corpses.lay(char, kind, delay)
	if not char or char:GetAttribute("Laid") then return end
	char:SetAttribute("Laid", true)
	kind = KIND[kind or ""] and kind or "body"
	local b = gather(char)
	if not b then return end
	if delay and delay > 0 and AFTER_BODY[kind] then
		task.delay(delay, function() build(b, kind) end)
		return nil
	end
	local model = build(b, kind)
	hideBody(char)
	return model
end

-- a kill effect is coming: its remains take the body's place `inSeconds` from now
function Corpses.pending(char, kind, inSeconds)
	if not char then return end
	char:SetAttribute("RemainsPending", kind)
	char:SetAttribute("RemainsDue", os.clock() + math.clamp(inSeconds or 1.5, 0, C.HOLD))
	task.delay(math.clamp(inSeconds or 1.5, 0, C.HOLD), function()
		if char.Parent then Corpses.lay(char, kind) end
	end)
end

function Corpses.died(char)
	Corpses.idOf(char)
	task.delay(C.SETTLE, function()
		if char.Parent and not char:GetAttribute("RemainsPending") then Corpses.lay(char, "body") end
	end)
end

-- a player respawning before their body was laid out: lay it out as it lies
local function watch(plr)
	plr.CharacterRemoving:Connect(function(char)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if (hum and hum.Health <= 0) or char:GetAttribute("CorpseId") then
			-- (a kill effect still playing: its remains come when it says)
			local due = (char:GetAttribute("RemainsDue") or 0) - os.clock()
			Corpses.lay(char, char:GetAttribute("RemainsPending") or "body", due)
		end
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

return Corpses
