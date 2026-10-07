--[[ PREVIEW RIG — a dressed R6 mannequin for menus (ViewportFrames): the Hub
     menu's stages and the class screen's cards. Built from Cosmetics ▸ Rig when
     the place has one, else from parts; dressed with the Dresser exactly like a
     real spawn; every weld resolved into a fixed pose (a viewport runs no physics).

       PreviewRig.dressedRig({loadout, appearance, weight, team, weapon = bool,
                              armor = bool, pose = {rs = {x, y, z}, …}}) -> Model
       PreviewRig.makeRig()          an undressed mannequin
       PreviewRig.poseRig(rig, pose) turn joints (degrees, torso frame); before settle
       PreviewRig.settle(model)      put every welded part where its weld says ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))

local PreviewRig = {}

function PreviewRig.proceduralRig()
	local m = Instance.new("Model")
	m.Name = "Mannequin"
	local skin = Catalog.BODY.skins[Catalog.BODY.defaults.skin or 2] or Color3.fromRGB(217, 180, 138)
	local function part(name, size, cf)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Anchored = true
		p.CanCollide = false
		p.Color = skin
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local torso = part("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0))
	local head = part("Head", Vector3.new(2, 1, 1), CFrame.new(0, 1.5, 0))
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Head; mesh.Scale = Vector3.new(1.25, 1.25, 1.25); mesh.Parent = head
	local face = Instance.new("Decal"); face.Name = "face"; face.Texture = "rbxasset://textures/face.png"; face.Face = Enum.NormalId.Front; face.Parent = head
	local la = part("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0))
	local ra = part("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0))
	local ll = part("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0))
	local rl = part("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0))
	local hrp = part("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0)); hrp.Transparency = 1
	-- the R6 joints, so poses work on this fallback too
	local function motor(name, p0, p1, c0, c1)
		local mo = Instance.new("Motor6D"); mo.Name = name; mo.Part0 = p0; mo.Part1 = p1; mo.C0 = c0; mo.C1 = c1; mo.Parent = p0
	end
	motor("Right Shoulder", torso, ra, CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.pi / 2, 0), CFrame.new(-0.5, 0.5, 0) * CFrame.Angles(0, math.pi / 2, 0))
	motor("Left Shoulder", torso, la, CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, -math.pi / 2, 0), CFrame.new(0.5, 0.5, 0) * CFrame.Angles(0, -math.pi / 2, 0))
	motor("Right Hip", torso, rl, CFrame.new(1, -1, 0) * CFrame.Angles(0, math.pi / 2, 0), CFrame.new(0.5, 1, 0) * CFrame.Angles(0, math.pi / 2, 0))
	motor("Left Hip", torso, ll, CFrame.new(-1, -1, 0) * CFrame.Angles(0, -math.pi / 2, 0), CFrame.new(-0.5, 1, 0) * CFrame.Angles(0, -math.pi / 2, 0))
	motor("Neck", torso, head, CFrame.new(0, 1, 0) * CFrame.Angles(-math.pi / 2, 0, math.pi), CFrame.new(0, -0.5, 0) * CFrame.Angles(-math.pi / 2, 0, math.pi))
	motor("RootJoint", hrp, torso, CFrame.Angles(-math.pi / 2, 0, math.pi), CFrame.Angles(-math.pi / 2, 0, math.pi))
	for _, a in ipairs({{"HairAttachment", head, CFrame.new(0, 0.6, 0)}, {"FaceFrontAttachment", head, CFrame.new(0, 0, -0.6)}, {"HatAttachment", head, CFrame.new(0, 0.6, 0)}}) do
		local at = Instance.new("Attachment"); at.Name = a[1]; at.CFrame = a[3]; at.Parent = a[2]
	end
	local bc = Instance.new("BodyColors"); bc.Parent = m
	m.PrimaryPart = hrp
	return m
end

function PreviewRig.makeRig()
	local t = Catalog.rig()
	local m
	if t then
		m = t:Clone()
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false
			elseif d:IsA("LuaSourceContainer") then d:Destroy() end
		end
		m.PrimaryPart = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
	else
		m = PreviewRig.proceduralRig()
	end
	return m
end

-- resolve every weld the Dresser made into a fixed pose (no physics in a viewport)
function PreviewRig.settle(model)
	for _ = 1, 4 do
		for _, w in ipairs(model:GetDescendants()) do
			if (w:IsA("Weld") or w:IsA("Motor6D")) and w.Part0 and w.Part1 and w.Part0 ~= w.Part1 then
				w.Part1.CFrame = w.Part0.CFrame * w.C0 * w.C1:Inverse()
				w.Part1.Anchored = true
			end
		end
	end
end

-- a pose: joint = {x, y, z} degrees, turned in the torso's frame about the
-- joint (rs / ls shoulders, rh / lh hips, neck). x = +90 raises an arm
-- straight forward; z swings it out to the side. Call before settle().
local JOINT = {rs = "Right Shoulder", ls = "Left Shoulder", rh = "Right Hip", lh = "Left Hip", neck = "Neck"}
function PreviewRig.poseRig(rig, pose)
	local torso = rig:FindFirstChild("Torso")
	if not (torso and pose) then return end
	for key, deg in pairs(pose) do
		local m = JOINT[key] and torso:FindFirstChild(JOINT[key])
		if m and m:IsA("Motor6D") then
			local r = CFrame.Angles(math.rad(deg[1] or 0), math.rad(deg[2] or 0), math.rad(deg[3] or 0))
			m.C0 = CFrame.new(m.C0.Position) * r * m.C0.Rotation
		end
	end
end

-- dress a fresh rig: {loadout, appearance, weight, team, weapon = bool, pose}
function PreviewRig.dressedRig(o)
	local m = PreviewRig.makeRig()
	local lo = o.loadout or {}
	if o.armor == false then lo = {colors = lo.colors} end
	pcall(Dresser.dress, m, {loadout = lo, appearance = o.appearance, weight = o.weight, team = o.team, preview = true})
	if o.weapon ~= false and (o.loadout or {}).weapon then pcall(Dresser.attachWeapon, m, o.loadout.weapon, o.loadout.weaponSkin) end
	PreviewRig.poseRig(m, o.pose)
	PreviewRig.settle(m)
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
	return m
end

return PreviewRig
