--[[ MESH TOOL — assembles a weapon Tool from uploaded Blender meshes
     (blender/weapons.py → scripts/upload_asset.py). Studio edit mode only
     (the Studio MCP or the command bar); the result is saved in the place:

       require(game.ServerScriptService.Build.MeshTool).build({
           name = "Longsword",
           grip = 0.95,                       -- Handle length (the fist), studs
           hitbox = {y0 = 0.6, y1 = 3.85, cross = 0.6},   -- over the striking part
           regions = {                        -- from blender/out/<name>.json + the upload ids
               Blade = {id = 0, center = {0, 2.2, 0}, size = {0.34, 3.2, 0.14}},
               Grip  = {id = 0, center = {0, -0.1, 0}, size = {1.35, 1.49, 0.34}},
           },
       })

     Frame: the Handle (an invisible box the size of the grip) sits at the
     origin with the blade along +Y, exactly like Build ▸ Weapons blueprints,
     so Tool.Grip stays identity and the animations fit. Roblox re-centres
     every mesh on its bounding box, which is why each region carries its
     centre in the Tool frame: that is the weld offset from the Handle.
     Meshes are white with vertex colors, so skins tint them (SkinPart) just
     like the part-built weapons. Any Tool of that name already in
     ServerStorage ▸ Weapons keeps its scripts (Config / Server / Client);
     its old body parts are replaced. ]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local MeshTool = {}
-- the pipeline's meshes arrive turned 180° about Y (the FBX import swaps
-- front / back and left / right), so every region is turned back
local TURN = CFrame.Angles(0, math.pi, 0)

local function meshPart(id)
	-- a MeshPart with its MeshId set: only LoadAsset / CreateMeshPartAsync can
	-- do that from a script, and the upload is a Model asset wrapping one
	local m = InsertService:LoadAsset(id)
	local mp = m:FindFirstChildWhichIsA("MeshPart", true)
	if not mp then m:Destroy(); error("asset has no MeshPart") end
	mp.Parent = nil
	m:Destroy()
	return mp
end

local function weld(root, part, offset)
	local w = Instance.new("Weld")
	w.Name = "MeshWeld"
	w.Part0, w.Part1 = root, part
	w.C0 = offset
	w.Parent = part
end

function MeshTool.build(spec)
	local weapons = ServerStorage:FindFirstChild("Weapons") or Instance.new("Folder")
	weapons.Name = "Weapons"; weapons.Parent = ServerStorage
	local tool = weapons:FindFirstChild(spec.name)
	if not tool then
		tool = Instance.new("Tool"); tool.Name = spec.name; tool.Parent = weapons
	end
	-- strip the old body, keep the scripts
	for _, c in ipairs(tool:GetChildren()) do
		if c:IsA("BasePart") or c:IsA("Model") or c:IsA("Folder") then c:Destroy() end
	end
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.Grip = CFrame.identity
	tool:SetAttribute("Built", nil)
	tool:SetAttribute("Mesh", true)

	local gripD = spec.gripD or 0.26
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(gripD, spec.grip or 0.8, gripD)
	handle.Transparency = 1
	handle.CanCollide, handle.CanTouch, handle.CanQuery = false, false, false
	handle.Massless = true
	handle.CastShadow = false
	handle.CFrame = CFrame.new(0, 0, 0)
	handle.Parent = tool

	for region, r in pairs(spec.regions or {}) do
		local mp = meshPart(r.id)
		mp.Name = region
		mp.Color = Color3.new(1, 1, 1)
		mp.Material = r.material and Enum.Material[r.material] or Enum.Material.SmoothPlastic
		mp.DoubleSided = true
		mp.CanCollide, mp.CanTouch, mp.CanQuery = false, false, false
		mp.Massless = true
		mp.Anchored = false
		mp:SetAttribute("SkinPart", region)
		local c = r.center or {0, 0, 0}
		local off = CFrame.new(c[1], c[2], c[3]) * TURN
		mp.CFrame = handle.CFrame * off
		weld(handle, mp, off)
		mp:SetAttribute("Turned", true)
		mp.Parent = tool
	end

	local hb = spec.hitbox or {y0 = 0.5, y1 = 3, cross = 0.6}
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = Vector3.new(hb.cross, hb.y1 - hb.y0, hb.cross)
	hitbox.Transparency = 1
	hitbox.CanCollide, hitbox.CanTouch, hitbox.CanQuery = false, false, false
	hitbox.Massless = true
	hitbox.CastShadow = false
	local off = CFrame.new(0, (hb.y0 + hb.y1) / 2, 0)
	hitbox.CFrame = handle.CFrame * off
	weld(handle, hitbox, off)
	hitbox.Parent = tool

	-- refresh the menu display copy
	local cos = ReplicatedStorage:FindFirstChild("Cosmetics")
	local disp = cos and cos:FindFirstChild("Weapons")
	if disp then
		local old = disp:FindFirstChild(spec.name)
		if old then old:Destroy() end
		local Blueprints = require(script.Parent:WaitForChild("Blueprints"))
		local m = Blueprints.displayFor(tool)
		if m then m.Parent = disp end
	end
	return tool
end

return MeshTool
