--[[ MESH ARMOR — assembles clothing / hair / beard / face Models from uploaded
     Blender meshes (blender/parts2mesh.py → scripts/build_armor.py). Studio
     edit mode only; the result is saved in the place and beats the blueprint:

       require(game.ServerScriptService.Build.MeshArmor).build({
           path = "RoadLevy/HeadClothing",        -- <Set>/<Slot>, "Pieces/<id>/<Slot>" or "Body/<Kind>/<id>"
           limb = "Head",                          -- Head | Torso | Arm | Leg (the Middle's size)
           regions = {
               Fixed  = {id = 0, center = {0, 0.6, 0}, material = "SmoothPlastic"},
               Accent = {id = 0, center = {…}},     -- ColorSlot regions carry the attribute
           },
           under = "Primary",                      -- or {r, g, b}: the Under attribute (see Dresser ▸ GAPS)
       })

     A region named after a ColorSlot (Primary / Secondary / Accent / Metal)
     gets that attribute; "Hair" is the Dresser's tintable hair region (no
     attribute, no KeepColor); "Fixed" keeps its vertex colors (KeepColor on
     body models so hair color leaves it alone). Meshes are white; Roblox
     re-centres meshes, so each region's centre in the limb frame is the
     offset from Middle. ]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local MeshArmor = {}
-- the pipeline's meshes arrive turned 180° about Y (the FBX import swaps
-- front / back and left / right), so every region is turned back
local TURN = CFrame.Angles(0, math.pi, 0)
local SLOTS = {"Primary", "Secondary", "Accent", "Metal"}
local LIMB_SIZE = {Head = Vector3.new(2, 1, 1), Torso = Vector3.new(2, 2, 1), Arm = Vector3.new(1, 2, 1), Leg = Vector3.new(1, 2, 1)}
local LIMB_OF = {HeadClothing = "Head", TorsoClothing = "Torso", LeftArmClothing = "Arm", RightArmClothing = "Arm", LeftLegClothing = "Leg", RightLegClothing = "Leg", Hair = "Head", Beard = "Head", Face = "Head"}

local function meshPart(id)
	local m = InsertService:LoadAsset(id)
	local mp = m:FindFirstChildWhichIsA("MeshPart", true)
	if not mp then m:Destroy(); error("asset has no MeshPart") end
	mp.Parent = nil
	m:Destroy()
	return mp
end

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = parent end
	return f
end

-- where the model lives, from its path
local function placeFor(path)
	local a, b, c = path:match("^([^/]+)/([^/]+)/?([^/]*)$")
	if a == "Pieces" then
		local cos = folder(ReplicatedStorage, "Cosmetics")
		return folder(folder(cos, "Pieces"), b), c, "piece"
	elseif a == "Body" then
		local cos = folder(ReplicatedStorage, "Cosmetics")
		return folder(folder(cos, "Body"), b), c, b   -- Hair / Beard / Face
	else
		local armor = folder(ServerStorage, "Armor")
		local set = armor:FindFirstChild(a)
		if not set then set = Instance.new("Model"); set.Name = a; set.Parent = armor end
		return set, b, "set"
	end
end

function MeshArmor.build(spec)
	local parent, modelName, kind = placeFor(spec.path)
	local limbKind = spec.limb or LIMB_OF[modelName] or "Head"
	local old = parent:FindFirstChild(modelName)
	if old then old:Destroy() end
	local m = Instance.new("Model")
	m.Name = modelName
	local middle = Instance.new("Part")
	middle.Name = "Middle"
	middle.Size = LIMB_SIZE[limbKind] or LIMB_SIZE.Head
	middle.Transparency = 1
	middle.Anchored = true
	middle.CanCollide, middle.CanTouch, middle.CanQuery = false, false, false
	middle.CastShadow = false
	middle.CFrame = CFrame.new(0, 0, 0)
	middle.Parent = m
	m.PrimaryPart = middle
	for region, r in pairs(spec.regions or {}) do
		local mp = meshPart(r.id)
		mp.Name = region
		mp.Color = Color3.new(1, 1, 1)
		mp.Material = r.material and Enum.Material[r.material] or Enum.Material.SmoothPlastic
		mp.DoubleSided = true   -- clothing shells read right from every angle
		mp.Anchored = true
		mp.CanCollide, mp.CanTouch, mp.CanQuery = false, false, false
		mp.Massless = true
		local c = r.center or {0, 0, 0}
		mp.CFrame = middle.CFrame * CFrame.new(c[1], c[2], c[3]) * TURN
		mp:SetAttribute("Turned", true)
		if table.find(SLOTS, region) then mp:SetAttribute("ColorSlot", region) end
		if region == "Fixed" and (kind == "Hair" or kind == "Beard" or kind == "Face") then mp:SetAttribute("KeepColor", true) end
		mp.Parent = m
	end
	m:SetAttribute("Mesh", true)
	local u = spec.under
	if type(u) == "table" then u = Color3.new(u[1], u[2], u[3]) end
	if u ~= nil then m:SetAttribute("Under", u) end
	m.Parent = parent
	return m
end

return MeshArmor
