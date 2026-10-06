--[[ R6 — a plain R6 character built from parts (no assets to load), with the
     standard joints, attachments and a Humanoid, ready for the Dresser. Used
     by bots, the training yard's dummies and Drill Master, and the statues.

       R6.rig(name, opts) -> model, humanoid, root
           opts.skin      body colour (default: the catalog's default skin)
           opts.anchored  pin the root (a dummy on a post, a statue)
           opts.noFace    no face decal (a straw sack)
           opts.material  body material ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))

local R6 = {}

function R6.rig(name, opts)
	opts = opts or {}
	local m = Instance.new("Model")
	m.Name = name or "Rig"
	local skin = opts.skin or Catalog.BODY.skins[Catalog.BODY.defaults.skin or 2] or Color3.fromRGB(217, 180, 138)
	local function part(n, size, cf, collide)
		local p = Instance.new("Part")
		p.Name = n; p.Size = size; p.CFrame = cf; p.Color = skin
		p.CanCollide = collide == true
		p.Material = opts.material or Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local torso = part("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), true)
	local head = part("Head", Vector3.new(2, 1, 1), CFrame.new(0, 4.5, 0), true)
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Head; mesh.Scale = Vector3.new(1.25, 1.25, 1.25); mesh.Parent = head
	if not opts.noFace then
		local face = Instance.new("Decal"); face.Name = "face"; face.Texture = "rbxasset://textures/face.png"; face.Parent = head
	end
	local la = part("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 3, 0))
	local ra = part("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 3, 0))
	local ll = part("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, 1, 0))
	local rl = part("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, 1, 0))
	local hrp = part("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0))
	hrp.Transparency = 1
	hrp.Anchored = opts.anchored == true
	local function motor(n, p0, p1, c0, c1)
		local mo = Instance.new("Motor6D"); mo.Name = n; mo.Part0 = p0; mo.Part1 = p1; mo.C0 = c0; mo.C1 = c1; mo.MaxVelocity = 0.1; mo.Parent = p0
	end
	local R, h = CFrame.Angles(-math.pi / 2, 0, math.pi), math.pi / 2
	motor("RootJoint", hrp, torso, R, R)
	motor("Neck", torso, head, CFrame.new(0, 1, 0) * R, CFrame.new(0, -0.5, 0) * R)
	motor("Right Shoulder", torso, ra, CFrame.new(1, 0.5, 0) * CFrame.Angles(0, h, 0), CFrame.new(-0.5, 0.5, 0) * CFrame.Angles(0, h, 0))
	motor("Left Shoulder", torso, la, CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, -h, 0), CFrame.new(0.5, 0.5, 0) * CFrame.Angles(0, -h, 0))
	motor("Right Hip", torso, rl, CFrame.new(1, -1, 0) * CFrame.Angles(0, h, 0), CFrame.new(0.5, 1, 0) * CFrame.Angles(0, h, 0))
	motor("Left Hip", torso, ll, CFrame.new(-1, -1, 0) * CFrame.Angles(0, -h, 0), CFrame.new(-0.5, 1, 0) * CFrame.Angles(0, -h, 0))
	for _, a in ipairs({{"HairAttachment", CFrame.new(0, 0.6, 0)}, {"HatAttachment", CFrame.new(0, 0.6, 0)}, {"FaceFrontAttachment", CFrame.new(0, 0, -0.6)}}) do
		local at = Instance.new("Attachment"); at.Name = a[1]; at.CFrame = a[2]; at.Parent = head
	end
	local grip = Instance.new("Attachment"); grip.Name = "RightGripAttachment"; grip.CFrame = CFrame.new(0, -1, 0); grip.Parent = ra
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.DisplayName = m.Name
	hum.Parent = m
	Instance.new("Animator").Parent = hum
	local bc = Instance.new("BodyColors")
	for _, k in ipairs({"HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3"}) do bc[k] = skin end
	bc.Parent = m
	m.PrimaryPart = hrp
	return m, hum, hrp
end

return R6
