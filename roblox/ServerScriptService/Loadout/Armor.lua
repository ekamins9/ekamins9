--[[ ARMOR — equips clothing sets built around "Middle" reference parts.

     ServerStorage/Armor/<SkinId>/
        Config              ModuleScript — Name, Description, Type, Health,
                            SpeedMult, ClunkMult, Protection (see DEFAULTS)
        HeadClothing        Model  }  each holds a part named Middle, the same
        TorsoClothing       Model  }  size/orientation as the limb it dresses,
        LeftArmClothing     Model  }  plus any number of other parts placed
        RightArmClothing    Model  }  around it. Any slot may be missing —
        LeftLegClothing     Model  }  a peasant with no shoes just has no
        RightLegClothing    Model  }  leg models.

     Equipping clones each slot model into character.Armor and welds it on:
     Middle is welded to the limb with no offset (Middle IS the limb), and
     every other part is welded to the limb at the offset it had from Middle
     in the template — so whatever you built around the dummy lands exactly
     where you built it. These are classic C0 welds, so placement never
     depends on where the clone is sitting when it's parented. All parts are
     massless and non-colliding; Middle is invisible.

     Stats publish through the attributes everything else already composes:
       SpeedMult_Armor / ClunkMult_Armor   (ReplicatedStorage.Modifiers)
       Humanoid.MaxHealth  += Health
       ArmorProtection     read per struck limb by CombatServer — only limbs
                           that actually have a clothing model on them get it
     Each clothing model carries a Limb attribute ("Head", "Left Arm", …) so
     other systems (dismemberment, skewer, first-person hiding) can find the
     piece for a limb without knowing this module. ]]

local ServerStorage = game:GetService("ServerStorage")

local Armor = {}

Armor.SLOTS = {   -- clothing model name → character limb it dresses
	HeadClothing     = "Head",
	TorsoClothing    = "Torso",
	LeftArmClothing  = "Left Arm",
	RightArmClothing = "Right Arm",
	LeftLegClothing  = "Left Leg",
	RightLegClothing = "Right Leg",
}

Armor.DEFAULTS = {
	Name        = nil,      -- shown in the menu; falls back to the folder name
	Description = "",
	Type        = "Light",  -- Light | Medium | Heavy (display + sort order)
	Health      = 0,        -- added to MaxHealth
	SpeedMult   = 1.0,      -- WalkSpeed multiplier (published as SpeedMult_Armor)
	ClunkMult   = 1.0,      -- footstep weight multiplier (published as ClunkMult_Armor)
	Protection  = 0.0,      -- 0..1 damage removed from hits on COVERED limbs
}

local TYPE_ORDER = {Light = 1, Medium = 2, Heavy = 3}

local function folder()
	local f = ServerStorage:FindFirstChild("Armor")
	if not f then warn("[Armor] ServerStorage.Armor folder not found") end
	return f
end

function Armor.config(id)
	local f = folder()
	local template = f and f:FindFirstChild(id)
	if not template then return nil end
	local cfg = {}
	for k, v in pairs(Armor.DEFAULTS) do cfg[k] = v end
	local mod = template:FindFirstChild("Config")
	if mod and mod:IsA("ModuleScript") then
		local ok, t = pcall(require, mod)
		if ok and type(t) == "table" then
			for k, v in pairs(t) do cfg[k] = v end
		else
			warn("[Armor] bad Config in", id, ok and "" or t)
		end
	end
	cfg.Id   = id
	cfg.Name = cfg.Name or id
	return cfg
end

-- every set, sorted light → heavy then by name
function Armor.list()
	local out = {}
	local f = folder()
	if f then
		for _, template in ipairs(f:GetChildren()) do
			local cfg = Armor.config(template.Name)
			if cfg then table.insert(out, cfg) end
		end
	end
	table.sort(out, function(a, b)
		local ta, tb = TYPE_ORDER[a.Type] or 9, TYPE_ORDER[b.Type] or 9
		if ta ~= tb then return ta < tb end
		return a.Name < b.Name
	end)
	return out
end

--------------------------------------------------------------------
--  WELDING
--------------------------------------------------------------------
local function dress(limb, model, limbName)
	local middle = model:FindFirstChild("Middle")
	if not middle then
		warn("[Armor] " .. model:GetFullName() .. " has no part named Middle — skipped")
		return false
	end
	-- anything the template was welded/constrained to (its display dummy, say)
	-- must not come along — the clone would otherwise weld itself to the original
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("Attachment") and d.Name:find("^Ragdoll") then
			d:Destroy()
		end
	end
	-- offsets are measured in the template, relative to Middle, BEFORE anything moves
	local offsets = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= middle then
			offsets[p] = middle.CFrame:ToObjectSpace(p.CFrame)
		end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = false, false, false, false
			p.Massless = true
			local w = Instance.new("Weld")
			w.Name  = "ArmorWeld"
			w.Part0 = limb
			w.Part1 = p
			w.C0    = offsets[p] or CFrame.identity   -- Middle sits exactly on the limb
			w.Parent = p
		end
	end
	middle.Transparency = 1
	model:SetAttribute("Limb", limbName)
	return true
end

--------------------------------------------------------------------
--  EQUIP / UNEQUIP
--------------------------------------------------------------------
function Armor.unequip(char)
	local old = char:FindFirstChild("Armor")
	if old then old:Destroy() end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local base = char:GetAttribute("BaseMaxHealth")
	if hum and base then
		local frac = hum.MaxHealth > 0 and hum.Health / hum.MaxHealth or 1
		hum.MaxHealth = base
		hum.Health = base * frac
	end
	char:SetAttribute("SpeedMult_Armor", nil)
	char:SetAttribute("ClunkMult_Armor", nil)
	char:SetAttribute("ArmorId", nil)
	char:SetAttribute("ArmorType", nil)
	char:SetAttribute("ArmorProtection", nil)
end

function Armor.equip(char, id)
	local f = folder()
	local template = f and f:FindFirstChild(id)
	local cfg = template and Armor.config(id)
	if not cfg then
		warn("[Armor] no armor set named", tostring(id))
		return false
	end
	Armor.unequip(char)

	local container = Instance.new("Folder")
	container.Name = "Armor"
	for modelName, limbName in pairs(Armor.SLOTS) do
		local src  = template:FindFirstChild(modelName)
		local limb = char:FindFirstChild(limbName)
		if src and limb then
			local m = src:Clone()
			m.Name = modelName
			if dress(limb, m, limbName) then m.Parent = container else m:Destroy() end
		end
	end
	container.Parent = char

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local base = char:GetAttribute("BaseMaxHealth") or hum.MaxHealth
		char:SetAttribute("BaseMaxHealth", base)
		hum.MaxHealth = base + (cfg.Health or 0)
		hum.Health = hum.MaxHealth
	end
	if cfg.SpeedMult ~= 1 then char:SetAttribute("SpeedMult_Armor", cfg.SpeedMult) end
	if cfg.ClunkMult ~= 1 then char:SetAttribute("ClunkMult_Armor", cfg.ClunkMult) end
	char:SetAttribute("ArmorId", id)
	char:SetAttribute("ArmorType", cfg.Type)
	char:SetAttribute("ArmorProtection", cfg.Protection or 0)
	return true
end

--------------------------------------------------------------------
--  QUERIES
--------------------------------------------------------------------
-- the clothing model dressing a limb, if any
function Armor.pieceOn(char, limbName)
	local container = char:FindFirstChild("Armor")
	if not container then return nil end
	for _, m in ipairs(container:GetChildren()) do
		if m:GetAttribute("Limb") == limbName then return m end
	end
	return nil
end

-- damage fraction removed from a hit on this limb: the set's Protection if
-- the limb is covered, nothing if it's bare
function Armor.protectionAt(char, limbName)
	if not Armor.pieceOn(char, limbName) then return 0 end
	return char:GetAttribute("ArmorProtection") or 0
end

-- plain-data version of a config for sending to clients
function Armor.summary(cfg)
	return {
		id = cfg.Id, name = cfg.Name, description = cfg.Description, type = cfg.Type,
		health = cfg.Health, speedMult = cfg.SpeedMult, clunkMult = cfg.ClunkMult,
		protection = cfg.Protection,
	}
end

return Armor
