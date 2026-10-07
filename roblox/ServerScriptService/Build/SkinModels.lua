--[[ SKIN MODELS — assembles the Forge's skin meshes (blender/forge.py →
     scripts/upload_skins.py) into ReplicatedStorage ▸ Cosmetics ▸ Skins ▸
     <weapon> ▸ <skin name>: the model Dresser.applySkin welds onto a weapon in
     place of its own body. Studio edit mode only (the Studio MCP or the
     command bar); the models are saved with the place.

       require(game.ServerScriptService.Build.SkinModels).build({
           {weapon = "Longsword", skin = "Gilded", glow = {255, 60, 80},
            regions = {Body = {id = <asset id>, center = {x, y, z}},
                       Glow = {id = <asset id>, center = {x, y, z}}}},
           ...
       }, from, to)                        -> built, failed   (from / to: a batch of the list)

     The frame is the weapon Tool's (MeshTool): an invisible Handle at the
     origin, each mesh at its centre turned 180° about Y (the FBX import turns
     it). Body keeps its vertex colours (white part); Glow is Neon in the
     skin's glow colour. Asset ids come from blender/out/skins/uploads.json
     (gitignored) and are pasted into the call, never into code. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local SkinModels = {}
local TURN = CFrame.Angles(0, math.pi, 0)

local function meshPart(id)
	local m = InsertService:LoadAsset(id)
	local mp = m:FindFirstChildWhichIsA("MeshPart", true)
	if not mp then m:Destroy(); error("asset " .. tostring(id) .. " has no MeshPart") end
	mp.Parent = nil
	m:Destroy()
	return mp
end

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = parent end
	return f
end

function SkinModels.buildOne(e)
	local cos = folder(ReplicatedStorage, "Cosmetics")
	local wf = folder(folder(cos, "Skins"), e.weapon)
	local model = Instance.new("Model")
	model.Name = e.skin
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 0.2)
	handle.Transparency = 1
	handle.Anchored = true
	handle.CanCollide, handle.CanTouch, handle.CanQuery = false, false, false
	handle.CFrame = CFrame.identity
	handle.Parent = model
	model.PrimaryPart = handle
	for region, r in pairs(e.regions) do
		local mp = meshPart(r.id)
		mp.Name = region
		mp.Anchored = true
		mp.CanCollide, mp.CanTouch, mp.CanQuery = false, false, false
		mp.Massless = true
		mp.DoubleSided = true
		local c = r.center or {0, 0, 0}
		mp.CFrame = CFrame.new(c[1], c[2], c[3]) * TURN
		if region == "Glow" then
			local g = e.glow or {255, 255, 255}
			mp.Material = Enum.Material.Neon
			mp.Color = Color3.fromRGB(g[1], g[2], g[3])
			mp.CastShadow = false
		else
			mp.Material = Enum.Material.SmoothPlastic
			mp.Color = Color3.new(1, 1, 1)
			mp:SetAttribute("SkinBody", true)
		end
		mp.Parent = model
	end
	local old = wf:FindFirstChild(e.skin)
	if old then old:Destroy() end
	model.Parent = wf
	return model
end

function SkinModels.build(entries, from, to)
	local built, failed = 0, {}
	for i = from or 1, math.min(to or #entries, #entries) do
		local e = entries[i]
		local ok, err = pcall(SkinModels.buildOne, e)
		if ok then built += 1 else table.insert(failed, e.weapon .. ":" .. e.skin .. " (" .. tostring(err) .. ")") end
	end
	return built, failed
end

return SkinModels
