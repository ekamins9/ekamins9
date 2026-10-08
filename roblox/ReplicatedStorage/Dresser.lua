--[[ DRESSER — puts a loadout and an appearance onto an R6 character. Runs on
     the server (real spawns) and on the client (the menu mannequin), reading
     models from ReplicatedStorage ▸ Cosmetics through Catalog.

       Dresser.dress(char, {loadout = {helmet, top, bottom, colors, armorFx, weapon, weaponSkin},
                            appearance = {skin, hair, hairColor, beard, face},
                            weight = "Heavy", team = "A"|"B"|nil, preview = bool})
       Dresser.undress(char)              removes armor + body, resets stats
       Dresser.applySkin(tool, skinId, variant)   puts the skin on a weapon Tool: its Forge model
                                          (Cosmetics ▸ Skins) or, without one, tints + trim (SkinTrims);
                                          then its trail / aura and its finish (SkinFX: Masterwork, Radiant)
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
local SkinFX = require(ReplicatedStorage:WaitForChild("SkinFX"))
local Defight = require(ReplicatedStorage:WaitForChild("Defight"))
local ArmorFX   -- (required on first use: it needs Catalog's finishes)

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
	-- (a crate set keeps its own colours where its Config names them: Catalog piece.colors)
	for _, m in ipairs(container:GetChildren()) do
		local pc = Catalog.PIECE[m:GetAttribute("Piece") or ""]
		local own = pc and pc.colors
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				local slot = p:GetAttribute("ColorSlot")
				if slot then
					local name = colors and colors[slot]
					local c = name and Catalog.COLOR[name] and Catalog.COLOR[name].color
					if own and typeof(own[slot]) == "Color3" then c = own[slot] end
					if teamColor and slot == "Primary" then c = teamColor elseif teamColor and slot == "Secondary" then c = darker(teamColor) end
					if c then p.Color = c; painted += 1 end
				end
			end
		end
	end
	return painted
end

--------------------------------------------------------------------
--  GAPS: what shows between the plates
--------------------------------------------------------------------
-- R6 limbs are boxes and armor is rounded, so a garment leaves a box's corners
-- and edges bare here and there. A limb under a garment is painted a shade of
-- the garment instead of skin, so a gap reads as cloth in shadow: the model's
-- Under attribute (a ColorSlot name, or a colour; scripts/build_armor.py), else
-- its biggest painted part. Where the garment stops short of the limb's end (a
-- hand under a cuff, a forearm under a rolled sleeve) a skin-coloured sleeve
-- keeps that stretch bare.
local UNDER_SHADE = 0.6
local UNDER_DEFAULT = Color3.fromRGB(46, 40, 36)
local BARE_MIN = 0.12     -- studs: a bare end shorter than this is left to the garment
local BODY_COLOR = {Torso = "TorsoColor3", ["Left Arm"] = "LeftArmColor3", ["Right Arm"] = "RightArmColor3", ["Left Leg"] = "LeftLegColor3", ["Right Leg"] = "RightLegColor3"}

-- a box's half-size along one axis of the frame it is given in
local function halfAlong(cf, half, axis)
	return math.abs(cf.RightVector[axis]) * half.X + math.abs(cf.UpVector[axis]) * half.Y + math.abs(cf.LookVector[axis]) * half.Z
end

-- {model, color, lo, hi}: the garment's shade and the stretch of the limb it wraps (limb space, Y)
local function underOf(model, limb)
	local middle = model:FindFirstChild("Middle")
	if not middle then return nil end
	local want = model:GetAttribute("Under")
	local lh = limb.Size / 2
	local lo, hi = math.huge, -math.huge
	local best, bestVol
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= middle and p.Transparency < 0.9 then
			local cf = middle.CFrame:ToObjectSpace(p.CFrame)
			local h = p.Size / 2
			local ex, ey, ez = halfAlong(cf, h, "X"), halfAlong(cf, h, "Y"), halfAlong(cf, h, "Z")
			-- only what goes round the limb says how far along it the garment reaches
			if cf.X - ex <= -0.6 * lh.X and cf.X + ex >= 0.6 * lh.X and cf.Z - ez <= -0.6 * lh.Z and cf.Z + ez >= 0.6 * lh.Z then
				lo, hi = math.min(lo, cf.Y - ey), math.max(hi, cf.Y + ey)
			end
			local slot = p:GetAttribute("ColorSlot")
			if slot and (type(want) ~= "string" or want == slot) then
				local v = p.Size.X * p.Size.Y * p.Size.Z
				if not bestVol or v > bestVol then best, bestVol = p.Color, v end
			end
		end
	end
	if lo == math.huge then return nil end
	local c = typeof(want) == "Color3" and want or best or UNDER_DEFAULT
	return {model = model, color = Color3.new(c.R * UNDER_SHADE, c.G * UNDER_SHADE, c.B * UNDER_SHADE), lo = lo, hi = hi}
end

-- a skin-coloured sleeve over the stretch y0..y1 of a limb, worn with its garment
local function bareStretch(limb, u, y0, y1, tone)
	if y1 - y0 < BARE_MIN then return end
	local s = Instance.new("Part")
	s.Name = "Skin"
	s.Size = Vector3.new(limb.Size.X + 0.03, y1 - y0, limb.Size.Z + 0.03)
	s.Color, s.Material = tone, limb.Material
	s.TopSurface, s.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	s.CanCollide, s.CanQuery, s.CanTouch, s.Massless, s.Anchored = false, false, false, true, false
	local off = CFrame.new(0, (y0 + y1) / 2, 0)
	s.CFrame = limb.CFrame * off
	local w = Instance.new("Weld"); w.Name, w.Part0, w.Part1, w.C0 = "ArmorWeld", limb, s, off; w.Parent = s
	s.Parent = u.model
end

--------------------------------------------------------------------
--  BODY
--------------------------------------------------------------------
local function applyBody(char, app, coversHair, coversFace, coversBeard, under)
	app = app or {}
	under = under or {}
	local body = Instance.new("Folder"); body.Name = "Body"
	-- skin tone (a limb under a garment takes the garment's shade, see GAPS)
	local tone = Catalog.BODY.skins[app.skin or Catalog.BODY.defaults.skin] or Catalog.BODY.skins[1]
	char:SetAttribute("SkinTone", tone)
	for _, n in ipairs(BODY_PARTS) do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			local u = under[n]
			p.Color = u and u.color or tone
			if u then
				local half = p.Size.Y / 2
				bareStretch(p, u, -half, math.max(-half, u.lo + 0.04), tone)   -- tucked a hair under the garment's edge
				bareStretch(p, u, math.min(half, u.hi - 0.04), half, tone)
			end
		end
	end
	local bc = char:FindFirstChildOfClass("BodyColors")
	if bc then
		bc.HeadColor3 = tone
		for n, prop in pairs(BODY_COLOR) do bc[prop] = under[n] and under[n].color or tone end
	end
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
	add("Beard", app.beard, coversFace or coversBeard)
	-- face: a texture on the head's own face Decal. The textures are Decals in
	-- Cosmetics ▸ Body ▸ Face ▸ <id> (made in Studio, see blender/faces.py), or a
	-- `texture` id in Catalog ▸ Body. A helmet that covers the face hides it.
	-- the face builder (Catalog.faceLayers): one Decal per layer, stacked by ZIndex, the iris,
	-- brows and paint tinted; the head's own face decal steps aside. Without the FaceParts
	-- (an old place) the single-texture face below is used.
	local layered = false
	if head then
		for _, d in ipairs(head:GetChildren()) do if d:IsA("Decal") and d:GetAttribute("FaceLayer") then d:Destroy() end end
		for _, L in ipairs(Catalog.faceLayers(app, hairColor)) do
			local src = Catalog.bodyModel("FaceParts", L.part)
			if src and src:IsA("Decal") then
				local d = Instance.new("Decal")
				d.Name = "FaceLayer_" .. L.part
				d.Texture = src.Texture
				d.Face = Enum.NormalId.Front
				d.ZIndex = L.z
				if L.tint then d.Color3 = L.tint end
				d.Transparency = coversFace and 1 or 0
				d:SetAttribute("FaceLayer", true)
				d.Parent = head
				layered = true
			end
		end
	end
	if head then
		local decal = head:FindFirstChild("face")
		if not decal then
			for _, d in ipairs(head:GetChildren()) do if d:IsA("Decal") and not d:GetAttribute("FaceLayer") then decal = d end end
		end
		if not decal then
			decal = Instance.new("Decal"); decal.Name = "face"; decal.Face = Enum.NormalId.Front; decal.Parent = head
		end
		local face
		for _, f in ipairs(Catalog.BODY.faces) do if f.id == app.face then face = f end end
		face = face or Catalog.BODY.faces[1]
		local src = face and Catalog.bodyModel("Face", face.id)
		if src and src:IsA("Decal") then decal.Texture = src.Texture
		elseif face and face.texture and face.texture ~= "" then decal.Texture = face.texture end
		decal.Transparency = (coversFace or layered) and 1 or 0
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
	for _, a in ipairs({"SpeedMult_Armor", "ClunkMult_Armor", "ArmorId", "ArmorType", "ArmorProtection", "TeamPainted", "Pieces",
		"StaminaMult", "RegenMult", "StaminaCostMult", "SprintMult", "DodgeCost", "DodgeReach"}) do char:SetAttribute(a, nil) end
	local head = char:FindFirstChild("Head")
	if head then for _, d in ipairs(head:GetChildren()) do if d:IsA("Decal") and d:GetAttribute("FaceLayer") then d:Destroy() end end end
	local decal = head and (head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")); if decal then decal.Transparency = 0 end
	-- the limbs a garment had painted go back to skin
	local tone = char:GetAttribute("SkinTone")
	if typeof(tone) == "Color3" then
		for _, n in ipairs(BODY_PARTS) do local p = char:FindFirstChild(n); if p and p:IsA("BasePart") then p.Color = tone end end
	end
end

function Dresser.dress(char, opts)
	opts = opts or {}
	local lo = opts.loadout or {}
	Dresser.undress(char)
	local weight = opts.weight or (Catalog.PIECE[lo.top] and Catalog.PIECE[lo.top].weight) or "Light"
	local stats = Catalog.WEIGHTS[weight] or Catalog.WEIGHTS.Light

	local container = Instance.new("Folder"); container.Name = "Armor"
	local coversHair, coversFace, coversBeard = false, false, false
	local worn = {}
	for _, slot in ipairs(Catalog.SLOTS) do
		local id = lo[slot]
		if slot == "helmet" and lo.noHelm then id = nil end   -- (bareheaded: the face shows, the head is unprotected)
		local piece = id and Catalog.PIECE[id]
		if piece then
			table.insert(worn, id)
			if slot == "helmet" then
				for _, c in ipairs(piece.covers or {}) do
					if c == "Hair" then coversHair = true elseif c == "Face" then coversFace = true elseif c == "Beard" then coversBeard = true end
				end
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
	-- layers that sit flush (a glove as wide as its sleeve) would flicker: nudge them apart
	Defight.run(container)
	local painted = Dresser.paint(container, lo.colors, opts.team)
	-- the armor's finish (Catalog ▸ ArmorFX): the class's pick, else the top's own (a crate set's)
	local picked = lo.armorFx ~= nil and lo.armorFx ~= ""
	local finish = picked and lo.armorFx or (Catalog.PIECE[lo.top or ""] and Catalog.PIECE[lo.top].fx)
	if finish then
		ArmorFX = ArmorFX or require(ReplicatedStorage:WaitForChild("ArmorFX"))
		pcall(ArmorFX.apply, container, char, finish, opts.preview, not picked)
	end
	-- what each covered limb shows through the gaps (GAPS; the head keeps its skin)
	local under = {}
	for _, m in ipairs(container:GetChildren()) do
		local limbName = m:GetAttribute("Limb")
		local limb = limbName and limbName ~= "Head" and char:FindFirstChild(limbName)
		if limb and limb:IsA("BasePart") then under[limbName] = underOf(m, limb) end
	end
	applyBody(char, opts.appearance, coversHair, coversFace, coversBeard, under)

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
	-- the weight's wind and footwork: CombatServer scales the stamina bar and its
	-- regen by these, MovementServer the sprint and the dodge's cost, Movement its reach
	char:SetAttribute("StaminaMult", stats.stamina or 1)
	char:SetAttribute("RegenMult", stats.regen or 1)
	char:SetAttribute("StaminaCostMult", stats.cost or 1)
	char:SetAttribute("SprintMult", stats.sprint)
	char:SetAttribute("DodgeCost", stats.dodgeCost or 1)
	char:SetAttribute("DodgeReach", stats.dodgeReach or 1)
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
function Dresser.applySkin(tool, skinId, variant)
	local skin = skinId and Catalog.SKIN[skinId]
	SkinTrims.clear(tool)
	SkinFX.clear(tool)
	if not skin or skin.name == "Default" then return false end
	tool:SetAttribute("Skin", skin.name)   -- the HUD's weapon chip shows it
	tool:SetAttribute("SkinVariant", variant)
	local old = tool:FindFirstChild("Skin")
	if old and old:IsA("Model") then old:Destroy() end
	for _, p in ipairs(tool:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("SkinHidden") then p.Transparency = 0; p:SetAttribute("SkinHidden", nil) end
	end
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
			SkinFX.apply(tool, skin, variant)   -- the trail, the aura and the finish ride on the model
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
	if SkinFX.apply(tool, skin, variant) then n += 1 end
	return n > 0
end

-- preview rig: weld a display model of the weapon into the right hand
function Dresser.attachWeapon(rig, weaponId, skinId, variant)
	local old = rig:FindFirstChild("WeaponPreview"); if old then old:Destroy() end
	local arm = rig:FindFirstChild("Right Arm")
	local t = weaponId and Catalog.weaponModel(weaponId)
	if not (arm and t) then return false end
	local m = t:Clone()
	local handle = m:FindFirstChild("Handle", true)
	if not handle then m:Destroy(); return false end
	strip(m)
	-- the hand's grip, with the same roll a held weapon gets (CombatServer GRIP_ROLL = -90:
	-- edge to the front)
	local grip = CFrame.new(0, -1, 0) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
			local w = Instance.new("Weld"); w.Part0, w.Part1 = arm, p
			local off = p == handle and CFrame.identity or handle.CFrame:ToObjectSpace(p.CFrame)
			w.C0 = grip * off
			-- previews spin the weapon about the hand (Emotes.poseRig)
			w:SetAttribute("GripBase", grip)
			w:SetAttribute("GripOffset", off)
			w.Parent = p
		end
	end
	m.Name = "WeaponPreview"
	m.Parent = rig
	if skinId then Dresser.applySkin(m, skinId, variant) end
	return true
end

return Dresser
