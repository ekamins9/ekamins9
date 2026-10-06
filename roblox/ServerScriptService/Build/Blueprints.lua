--[[ BLUEPRINTS — builds whatever has no hand-made model yet, from the specs
     in Build ▸ Weapons / Armor / Body, so the repo alone makes a playable,
     fully dressed game:
       • every Tool in ServerStorage ▸ Weapons without a Handle gets its body
         (Handle, Hitbox, blade / haft / head parts welded to the Handle)
       • every set folder in ServerStorage ▸ Armor without clothing models
         gets them (Middle-based, color blocks)
       • ReplicatedStorage ▸ Cosmetics gets its folders, hair / beard / face
         models, and a display copy of every weapon for the menu mannequin
     Hand-made models always win: the builder only fills gaps.

     Studio edit mode, command bar — materialize editable copies of all of it:
       require(game.ServerScriptService.Build.Blueprints).ensureAll()
     (then delete what you replace by hand; the builder never overwrites). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local B = require(script.Parent:WaitForChild("Builder"))
local WeaponBP = require(script.Parent:WaitForChild("Weapons"))
local ArmorBP = require(script.Parent:WaitForChild("Armor"))
local BodyBP = require(script.Parent:WaitForChild("Body"))

local Blueprints = {}
local function log(...) print("[Blueprints]", ...) end

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = parent end
	return f
end

--------------------------------------------------------------------
--  WEAPONS
--------------------------------------------------------------------
-- a Tool with scripts but no Handle: build its body from the blueprint
function Blueprints.completeTool(tool)
	if not tool:IsA("Tool") or tool:FindFirstChild("Handle") then return false end
	local bp = WeaponBP[tool.Name]
	if not bp then warn("[Blueprints] no weapon blueprint for Tool", tool.Name); return false end
	local specs = bp()
	local handle
	local parts = {}
	for _, s in ipairs(specs) do
		local p = B.make(s)
		p.Parent = tool
		parts[#parts + 1] = p
		if p.Name == "Handle" then handle = p end
	end
	if not handle then warn("[Blueprints] blueprint for", tool.Name, "has no Handle"); return false end
	B.weld(tool, handle)
	for _, p in ipairs(parts) do
		if p.Name == "Hitbox" then p.Transparency = 1; p.CanQuery = false end
	end
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("Built", true)
	return true
end

-- a display Model of a Tool for the menu mannequin (no scripts, no hitbox)
function Blueprints.displayFor(tool)
	local m = Instance.new("Model")
	m.Name = tool.Name
	local handle
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Hitbox" and d.Name ~= "GuardHull" and d.Transparency < 1 then
			local c = d:Clone()
			for _, x in ipairs(c:GetChildren()) do if not (x:IsA("SpecialMesh") or x:IsA("Decal") or x:IsA("Texture")) then x:Destroy() end end
			c.Anchored = true
			c.CanCollide, c.CanQuery, c.CanTouch, c.Massless = false, false, false, true
			c.Parent = m
			if d.Name == "Handle" then handle = c end
		end
	end
	if not handle then m:Destroy(); return nil end
	m.PrimaryPart = handle
	return m
end

--------------------------------------------------------------------
--  ARMOR SETS
--------------------------------------------------------------------
local SLOTS = {"HeadClothing", "TorsoClothing", "LeftArmClothing", "RightArmClothing", "LeftLegClothing", "RightLegClothing"}
function Blueprints.ensureSet(setFolder)
	for _, n in ipairs(SLOTS) do if setFolder:FindFirstChild(n) then return false end end   -- hand-made: leave it
	local bp = ArmorBP[setFolder.Name]
	if not bp then return false end
	for _, n in ipairs(SLOTS) do
		if bp[n] then
			local m = B.build(n, bp[n], {primary = "Middle"})
			m:SetAttribute("Built", true)
			m.Parent = setFolder
		end
	end
	return true
end

-- earned pieces: Cosmetics ▸ Pieces ▸ <id> holding only that slot's models
function Blueprints.ensurePieces(piecesFolder)
	local n = 0
	for id, slots in pairs(ArmorBP.PIECES or {}) do
		local f = piecesFolder:FindFirstChild(id)
		if not f then
			f = Instance.new("Folder"); f.Name = id; f.Parent = piecesFolder
		end
		local has = false
		for _, sn in ipairs(SLOTS) do if f:FindFirstChild(sn) then has = true end end
		if not has then
			for sn, specs in pairs(slots) do
				local m = B.build(sn, specs, {primary = "Middle"})
				m:SetAttribute("Built", true)
				m.Parent = f
			end
			n += 1
		end
	end
	return n
end

--------------------------------------------------------------------
--  BODY
--------------------------------------------------------------------
function Blueprints.ensureBody(bodyFolder)
	local n = 0
	for kind, list in pairs(BodyBP) do
		local kf = folder(bodyFolder, kind)
		for id, specs in pairs(list) do
			if not kf:FindFirstChild(id) then
				local m = B.build(id, specs, {primary = "Middle"})
				m:SetAttribute("Built", true)
				m.Parent = kf
				n += 1
			end
		end
	end
	return n
end

--------------------------------------------------------------------
--  ALL
--------------------------------------------------------------------
function Blueprints.ensureAll()
	local built = {tools = 0, sets = 0, body = 0, displays = 0, pieces = 0}
	local weapons = ServerStorage:FindFirstChild("Weapons")
	if weapons then
		for _, t in ipairs(weapons:GetChildren()) do if Blueprints.completeTool(t) then built.tools += 1 end end
	end
	local armor = ServerStorage:FindFirstChild("Armor")
	if armor then
		for _, set in ipairs(armor:GetChildren()) do if Blueprints.ensureSet(set) then built.sets += 1 end end
	end
	local cos = folder(ReplicatedStorage, "Cosmetics")
	for _, n in ipairs({"Armor", "Pieces", "Skins", "Weapons", "Body"}) do folder(cos, n) end
	for _, n in ipairs({"Hair", "Beard", "Face"}) do folder(cos.Body, n) end
	built.body = Blueprints.ensureBody(cos.Body)
	built.pieces = Blueprints.ensurePieces(cos.Pieces)
	if weapons then
		for _, t in ipairs(weapons:GetChildren()) do
			if t:IsA("Tool") and not cos.Weapons:FindFirstChild(t.Name) then
				local m = Blueprints.displayFor(t)
				if m then m.Parent = cos.Weapons; built.displays += 1 end
			end
		end
	end
	log(string.format("built %d weapon bodies, %d armor sets, %d earned pieces, %d body models, %d weapon displays", built.tools, built.sets, built.pieces, built.body, built.displays))
	return built
end

return Blueprints
