--[[ DRESSER — puts a loadout and an appearance onto an R6 character. Runs on
     the server (real spawns) and on the client (the menu mannequin), reading
     models from ReplicatedStorage ▸ Cosmetics through Catalog.

       Dresser.dress(char, {loadout = {helmet, top, bottom, colors, weapon, weaponSkin},
                            appearance = {skin, hair, hairColor, beard, face},
                            weight = "Heavy", team = "A"|"B"|nil, preview = bool})
       Dresser.undress(char)              removes armor + body, resets stats
       Dresser.applySkin(tool, skinId)    recolors a weapon Tool and adds the skin's trim (SkinTrims)
       Dresser.attachWeapon(rig, weaponId, skinId)   preview only: welds Cosmetics ▸ Weapons ▸ <id> to the right hand

     Welding follows the armor convention: every clothing model has a part
     named Middle the size of the limb; Middle lands exactly on the limb and
     every other part keeps the offset it had from Middle. Color blocks are
     parts with attribute ColorSlot = Primary | Secondary | Accent | Metal.
     Stats come from Catalog.WEIGHTS and publish as the attributes the combat
     code already reads (ArmorType, ArmorProtection, SpeedMult_Armor,
     ClunkMult_Armor, MaxHealth via BaseMaxHealth); each clothing model gets a
     Limb attribute so CombatServer's covered-limb check keeps working. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local SkinTrims = require(ReplicatedStorage:WaitForChild("SkinTrims"))

local Dresser = {}

local LIMB_OF = {HeadClothing = "Head", TorsoClothing = "Torso", LeftArmClothing = "Left Arm", RightArmClothing = "Right Arm", LeftLegClothing = "Left Leg", RightLegClothing = "Right Leg"}
local BODY_PARTS = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

--------------------------------------------------------------------
--  WELDING
--------------------------------------------------------------------
local function strip(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("Constraint") or (d:IsA("Attachment") and d.Name:find("^Ragdoll")) then d:Destroy() end
	end
end

-- weld a Middle-based model onto a limb; returns false if it has no Middle
local function weldMiddle(limb, model)
	local middle = model:FindFirstChild("Middle")
	if not middle then return false end
	strip(model)
	local offsets = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= middle then offsets[p] = middle.CFrame:ToObjectSpace(p.CFrame) end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
			local w = Instance.new("Weld")
			w.Name, w.Part0, w.Part1, w.C0 = "ArmorWeld", limb, p, offsets[p] or CFrame.identity
			w.Parent = p
		end
	end
	middle.Transparency = 1
	return true
end

-- weld an Accessory-style model (Handle + attachment) onto the head
local function weldAccessory(head, model)
	local handle = model:FindFirstChild("Handle", true)
	if not (handle and handle:IsA("BasePart")) then return false end
	strip(model)
	local hAtt
	for _, a in ipairs(handle:GetChildren()) do if a:IsA("Attachment") then hAtt = a; break end end
	local headAtt = hAtt and head:FindFirstChild(hAtt.Name)
	local c0 = headAtt and (headAtt.CFrame * hAtt.CFrame:Inverse()) or CFrame.new(0, 0.5, 0)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
			if p ~= handle then
				local w = Instance.new("Weld"); w.Part0, w.Part1, w.C0 = handle, p, handle.CFrame:ToObjectSpace(p.CFrame); w.Parent = p
			end
		end
	end
	local w = Instance.new("Weld"); w.Name, w.Part0, w.Part1, w.C0 = "ArmorWeld", head, handle, c0; w.Parent = handle
	return true
end

local function putOn(limb, template)
	local m = template:Clone()
	local ok = m:FindFirstChild("Middle") and weldMiddle(limb, m) or weldAccessory(limb, m)
	if not ok then m:Destroy(); return nil end
	return m
end

--------------------------------------------------------------------
--  COLOR BLOCKS
--------------------------------------------------------------------
local function darker(c) return Color3.new(c.R * 0.55, c.G * 0.55, c.B * 0.55) end

function Dresser.paint(container, colors, teamKey)
	local GameConfig = ReplicatedStorage:FindFirstChild("GameConfig") and require(ReplicatedStorage.GameConfig)
	local teamColor = teamKey and GameConfig and GameConfig.TEAMS[teamKey] and GameConfig.TEAMS[teamKey].rgb
	local painted = 0
	for _, p in ipairs(container:GetDescendants()) do
		if p:IsA("BasePart") then
			local slot = p:GetAttribute("ColorSlot")
			if slot then
				local name = colors and colors[slot]
				local c = name and Catalog.COLOR[name] and Catalog.COLOR[name].color
				if teamColor and slot == "Primary" then c = teamColor elseif teamColor and slot == "Secondary" then c = darker(teamColor) end
				if c then p.Color = c; painted += 1 end
			end
		end
	end
	return painted
end

--------------------------------------------------------------------
--  BODY
--------------------------------------------------------------------
local function applyBody(char, app, coversHair, coversFace)
	app = app or {}
	local body = Instance.new("Folder"); body.Name = "Body"
	-- skin tone
	local tone = Catalog.BODY.skins[app.skin or Catalog.BODY.defaults.skin] or Catalog.BODY.skins[1]
	for _, n in ipairs(BODY_PARTS) do local p = char:FindFirstChild(n); if p and p:IsA("BasePart") then p.Color = tone end end
	local bc = char:FindFirstChildOfClass("BodyColors")
	if bc then local b = BrickColor.new(tone); bc.HeadColor3, bc.TorsoColor3, bc.LeftArmColor3, bc.RightArmColor3, bc.LeftLegColor3, bc.RightLegColor3 = tone, tone, tone, tone, tone, tone end
	local head = char:FindFirstChild("Head")
	local hairColor = Catalog.BODY.hairColors[1].color
	for _, h in ipairs(Catalog.BODY.hairColors) do if h.name == app.hairColor then hairColor = h.color end end
	local function add(kind, id, hidden)
		if not id or id == "None" or id == "Bald" or hidden or not head then return end
		local t = Catalog.bodyModel(kind, id)
		if not t then return end
		local m = putOn(head, t)
		if m then
			m.Name = kind
			for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "Middle" and p:GetAttribute("KeepColor") ~= true then p.Color = hairColor end end
			m.Parent = body
		end
	end
	add("Hair", app.hair, coversHair)
	add("Beard", app.beard, coversFace)
	-- face: a texture on the head's own face Decal. The textures are Decals in
	-- Cosmetics ▸ Body ▸ Face ▸ <id> (made in Studio, see blender/faces.py), or a
	-- `texture` id in Catalog ▸ Body. A helmet that covers the face hides it.
	if head then
		local decal = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
		if not decal then
			decal = Instance.new("Decal"); decal.Name = "face"; decal.Face = Enum.NormalId.Front; decal.Parent = head
		end
		local face
		for _, f in ipairs(Catalog.BODY.faces) do if f.id == app.face then face = f end end
		face = face or Catalog.BODY.faces[1]
		local src = face and Catalog.bodyModel("Face", face.id)
		if src and src:IsA("Decal") then decal.Texture = src.Texture
		elseif face and face.texture and face.texture ~= "" then decal.Texture = face.texture end
		decal.Transparency = coversFace and 1 or 0
	end
	body.Parent = char
end

--------------------------------------------------------------------
--  DRESS / UNDRESS
--------------------------------------------------------------------
function Dresser.undress(char)
	for _, n in ipairs({"Armor", "Body"}) do local c = char:FindFirstChild(n); if c then c:Destroy() end end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local base = char:GetAttribute("BaseMaxHealth")
	if hum and base then local frac = hum.MaxHealth > 0 and hum.Health / hum.MaxHealth or 1; hum.MaxHealth = base; hum.Health = base * frac end
	for _, a in ipairs({"SpeedMult_Armor", "ClunkMult_Armor", "ArmorId", "ArmorType", "ArmorProtection", "TeamPainted", "Pieces"}) do char:SetAttribute(a, nil) end
	local head = char:FindFirstChild("Head"); local decal = head and head:FindFirstChildOfClass("Decal"); if decal then decal.Transparency = 0 end
end

function Dresser.dress(char, opts)
	opts = opts or {}
	local lo = opts.loadout or {}
	Dresser.undress(char)
	local weight = opts.weight or (Catalog.PIECE[lo.top] and Catalog.PIECE[lo.top].weight) or "Light"
	local stats = Catalog.WEIGHTS[weight] or Catalog.WEIGHTS.Light

	local container = Instance.new("Folder"); container.Name = "Armor"
	local coversHair, coversFace = false, false
	local worn = {}
	for _, slot in ipairs(Catalog.SLOTS) do
		local id = lo[slot]
		local piece = id and Catalog.PIECE[id]
		if piece then
			table.insert(worn, id)
			if slot == "helmet" then
				for _, c in ipairs(piece.covers or {}) do if c == "Hair" then coversHair = true elseif c == "Face" then coversFace = true end end
			end
			for modelName, template in pairs(Catalog.pieceModels(id)) do
				local limb = char:FindFirstChild(LIMB_OF[modelName])
				if limb then
					local m = putOn(limb, template)
					if m then m.Name = modelName; m:SetAttribute("Limb", LIMB_OF[modelName]); m:SetAttribute("Piece", id); m.Parent = container end
				end
			end
		end
	end
	container.Parent = char
	local painted = Dresser.paint(container, lo.colors, opts.team)
	applyBody(char, opts.appearance, coversHair, coversFace)

	-- stats (real characters; harmless on a preview rig)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and not opts.preview then
		local base = char:GetAttribute("BaseMaxHealth") or hum.MaxHealth
		char:SetAttribute("BaseMaxHealth", base)
		hum.MaxHealth = base + (stats.health or 0)
		hum.Health = hum.MaxHealth
	end
	if stats.speed ~= 1 then char:SetAttribute("SpeedMult_Armor", stats.speed) end
	if stats.clunk ~= 1 then char:SetAttribute("ClunkMult_Armor", stats.clunk) end
	char:SetAttribute("ArmorType", weight)
	char:SetAttribute("ArmorProtection", stats.prot or 0)
	char:SetAttribute("ArmorId", table.concat(worn, ","))
	char:SetAttribute("Pieces", table.concat(worn, ","))
	char:SetAttribute("TeamPainted", opts.team ~= nil and painted > 0)
	return true
end

--------------------------------------------------------------------
--  WEAPON SKINS
--------------------------------------------------------------------
-- real Tool on the server (or a preview copy): tint SkinPart parts (or swap
-- in the skin model's parts around the Handle), then build the skin's trim —
-- the parts that change the weapon's shape (SkinTrims)
function Dresser.applySkin(tool, skinId)
	local skin = skinId and Catalog.SKIN[skinId]
	SkinTrims.clear(tool)
	if not skin or skin.name == "Default" then return false end
	tool:SetAttribute("Skin", skin.name)   -- the HUD's weapon chip shows it
	local handle = tool:FindFirstChild("Handle")
	local model = Catalog.skinModel(skinId)
	if model and handle then
		local mh = model:FindFirstChild("Handle")
		if mh then
			-- hide the tool's own visible parts (keep the collision/guard parts the combat code needs)
			for _, p in ipairs(tool:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "Hitbox" and p.Name ~= "GuardHull" and p.Transparency < 1 then p.Transparency = 1; p:SetAttribute("SkinHidden", true) end
			end
			local clone = model:Clone()
			strip(clone)
			for _, p in ipairs(clone:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
					local w = Instance.new("Weld"); w.Part0, w.Part1, w.C0 = handle, p, mh.CFrame:ToObjectSpace(p.CFrame); w.Parent = p
				end
			end
			clone.Name = "Skin"
			clone.Parent = tool
			return true
		end
	end
	local n = 0
	for _, p in ipairs(tool:GetDescendants()) do
		if p:IsA("BasePart") then
			local part = p:GetAttribute("SkinPart")
			if part == "Blade" and skin.blade then p.Color = skin.blade; n += 1
			elseif part == "Grip" and skin.grip then p.Color = skin.grip; n += 1 end
		end
	end
	if SkinTrims.apply(tool, skin) then n += 1 end
	return n > 0
end

-- preview rig: weld a display model of the weapon into the right hand
function Dresser.attachWeapon(rig, weaponId, skinId)
	local old = rig:FindFirstChild("WeaponPreview"); if old then old:Destroy() end
	local arm = rig:FindFirstChild("Right Arm")
	local t = weaponId and Catalog.weaponModel(weaponId)
	if not (arm and t) then return false end
	local m = t:Clone()
	local handle = m:FindFirstChild("Handle", true)
	if not handle then m:Destroy(); return false end
	strip(m)
	local grip = CFrame.new(0, -1, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
			local w = Instance.new("Weld"); w.Part0, w.Part1 = arm, p
			w.C0 = p == handle and grip or (grip * handle.CFrame:ToObjectSpace(p.CFrame))
			w.Parent = p
		end
	end
	m.Name = "WeaponPreview"
	m.Parent = rig
	if skinId then Dresser.applySkin(m, skinId) end
	return true
end

return Dresser
