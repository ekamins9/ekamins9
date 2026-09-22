--[[ INJURY — dismemberment, bleeding, and disarms. Weapon-agnostic; the
     combat system calls these and CharacterSystems ticks the bleed.

     Limb loss is recorded as LimbLost_<LeftArm|RightArm|LeftLeg|RightLeg|Head>
     attributes on the character. Losing legs publishes SpeedMult_Limbs /
     ClunkMult_Limbs, which compose with weapon and armor modifiers.

     Arms and legs: the REAL part stays in the rig (invisible, non-colliding)
     so animations and the camera rig keep working; a clone is flung as
     debris and a bloody stump is welded on. Head: the REAL head comes off —
     RequiresNeck kills the humanoid and the death camera rides the head. ]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds      = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local Pickup      = require(script.Parent:WaitForChild("Pickup"))

local Injury = {}

Injury.CONFIG = {
	BLEED_HP         = 25,    -- health you're left with after losing a limb…
	BLEED_TIME       = 10,    -- …and how long until it's gone (a bandage system can clear Bleeding)
	LEG_SPEED        = 0.45,  -- WalkSpeed factor per lost leg
	LEG_CLUNK        = 1.5,   -- footstep clunk factor per lost leg
	DISARM_FLING     = 30,    -- studs/s the weapon leaves the hand at (it lands as a pickup)
	LIMB_DEBRIS_TIME = 25,
	SKEWER_DURATION  = 0,     -- seconds the head stays on the blade; 0 = until the attacker's next swing launches it
	SKEWER_OFFSET    = 0.6,   -- how far past the hit point, along the blade, the head sits
	HEAD_THROW_LIFE  = 20,    -- seconds a thrown head lies around
	BLOOD_COLOR      = Color3.fromRGB(120, 0, 0),
}
local C = Injury.CONFIG

local LIMB_KEY = {
	["Left Arm"] = "LeftArm", ["Right Arm"] = "RightArm",
	["Left Leg"] = "LeftLeg", ["Right Leg"] = "RightLeg",
	["Head"]     = "Head",
}
Injury.LIMBS = LIMB_KEY

local function attrKey(partName)
	local k = LIMB_KEY[partName]
	return k and ("LimbLost_" .. k) or nil
end

-- Armor: the clothing model dressing a limb (Loadout.Armor tags each one
-- with a Limb attribute), so a severed limb takes its armor with it
local function clothingOn(char, limbName)
	local container = char:FindFirstChild("Armor")
	if not container then return nil end
	for _, m in ipairs(container:GetChildren()) do
		if m:GetAttribute("Limb") == limbName then return m end
	end
	return nil
end

-- copy the visible clothing parts off limbPart onto ontoPart at the same
-- offset, parented under parentTo, then remove the originals
local function carryClothing(char, limbName, limbPart, ontoPart, parentTo)
	local piece = clothingOn(char, limbName)
	if not piece then return end
	for _, p in ipairs(piece:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "Middle" then
			local rel = limbPart.CFrame:ToObjectSpace(p.CFrame)
			local c = p:Clone()
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("JointInstance") or d:IsA("Constraint") then d:Destroy() end
			end
			c.CanCollide, c.CanQuery, c.CanTouch, c.Massless, c.Anchored = false, false, false, true, false
			c.CFrame = ontoPart.CFrame * rel
			c.Parent = parentTo
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1, w.Parent = ontoPart, c, c
		end
	end
	piece:Destroy()
end

function Injury.hasLimb(char, partName)
	local k = attrKey(partName)
	return k == nil or char:GetAttribute(k) ~= true
end

function Injury.canWield(char, twoHanded)
	return Injury.hasLimb(char, "Right Arm") and (not twoHanded or Injury.hasLimb(char, "Left Arm"))
end

-- holding a guard braces the weapon with both arms
function Injury.canBlock(char)
	return Injury.hasLimb(char, "Right Arm") and Injury.hasLimb(char, "Left Arm")
end

--------------------------------------------------------------------
--  BLOOD
--------------------------------------------------------------------
local function bloodEmitter(parent, rate, life)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(C.BLOOD_COLOR)
	e.Size = NumberSequence.new(0.3, 0.05)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(0.4, 0.9)
	e.Speed = NumberRange.new(3, 8)
	e.SpreadAngle = Vector2.new(35, 35)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Drag = 2
	e.Rate = rate
	e.Parent = parent
	if life then
		task.delay(life, function()
			e.Enabled = false
			Debris:AddItem(e, 2)
		end)
	end
	return e
end

function Injury.bloodBurst(part, count)
	local e = bloodEmitter(part, 0, nil)
	e:Emit(count or 25)
	Debris:AddItem(e, 2)
end

--------------------------------------------------------------------
--  BLEEDING  (CharacterSystems calls Injury.tick every Heartbeat)
--------------------------------------------------------------------
function Injury.startBleed(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	hum.Health = C.BLEED_HP
	char:SetAttribute("Bleeding", true)
	char:SetAttribute("BleedDPS", C.BLEED_HP / C.BLEED_TIME)
	Sounds.play(SoundConfig.Bleed, char:FindFirstChild("Torso") or char.PrimaryPart)
end

function Injury.stopBleed(char)
	char:SetAttribute("Bleeding", nil)
	char:SetAttribute("BleedDPS", nil)
end

function Injury.tick(char, dt)
	if char:GetAttribute("Bleeding") ~= true then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		hum:TakeDamage((char:GetAttribute("BleedDPS") or 2.5) * dt)
	end
end

--------------------------------------------------------------------
--  MOBILITY
--------------------------------------------------------------------
function Injury.recomputeMobility(char)
	local legs = 0
	if not Injury.hasLimb(char, "Left Leg")  then legs += 1 end
	if not Injury.hasLimb(char, "Right Leg") then legs += 1 end
	char:SetAttribute("SpeedMult_Limbs", legs > 0 and C.LEG_SPEED ^ legs or nil)
	char:SetAttribute("ClunkMult_Limbs", legs > 0 and C.LEG_CLUNK ^ legs or nil)
end

--------------------------------------------------------------------
--  DISARM — the weapon is severed from the body, leaves the inventory,
--  and is thrown clear. It cannot be picked up again: a disarm is
--  permanent for that weapon, so losing your guard really costs you it.
--------------------------------------------------------------------
function Injury.disarm(char, dir)
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	-- flung clear as a pickup (Pickup severs the grip joints first so the
	-- body doesn't go with it)
	if not Pickup.drop(tool, char, dir, C.DISARM_FLING) then return false end
	Sounds.play(SoundConfig.Disarm, hrp)
	return true
end

--------------------------------------------------------------------
--  SKEWER — a lethal face stab leaves the victim's head riding the
--  attacker's blade. A CLONE of the head is welded to the blade and the
--  real one is just hidden, so nothing of the victim's rig ever joins the
--  attacker's physics assembly: the corpse keeps every joint and ragdolls
--  normally, and cleanup is a Debris call. Stays on until the next swing throws it,
--  or immediately if the attacker unequips/loses the weapon first.
--------------------------------------------------------------------
local skewers = {}   -- [hitbox] = {trophy=, head=, weld=, drop=fn}

function Injury.hasSkewer(hitbox)
	local e = hitbox and skewers[hitbox]
	return e ~= nil and e.head.Parent ~= nil
end

-- the blade's long axis in hitbox-local space, signed toward `towardWorld`
local function bladeAxis(hitbox, towardWorld)
	local sz = hitbox.Size
	local axis = (sz.X >= sz.Y and sz.X >= sz.Z) and Vector3.xAxis or (sz.Y >= sz.Z and Vector3.yAxis or Vector3.zAxis)
	local halfLen = math.abs(sz:Dot(axis)) * 0.5
	if towardWorld and hitbox.CFrame:VectorToWorldSpace(axis):Dot(towardWorld) < 0 then axis = -axis end
	return axis, halfLen
end

function Injury.skewerHead(char, hitbox, hitPos, bladeDir)
	local head = char:FindFirstChild("Head")
	if not (head and hitbox and hitbox.Parent) or char:GetAttribute("HeadSkewered") then return false end
	if Injury.hasSkewer(hitbox) then return false end   -- one head per blade
	char:SetAttribute("HeadSkewered", true)

	local dir = (typeof(bladeDir) == "Vector3" and bladeDir.Magnitude > 1e-4) and bladeDir.Unit or Vector3.new(0, 0, -1)
	-- Sit EXACTLY on the blade's axis: take the hit point in hitbox space,
	-- keep only its along-the-blade component (drops any sideways error from
	-- a hit on a hat or the head's edge), then push it out toward the tip.
	local axis, halfLen = bladeAxis(hitbox, dir)
	local along = (typeof(hitPos) == "Vector3") and hitbox.CFrame:PointToObjectSpace(hitPos):Dot(axis) or halfLen * 0.5
	along = math.clamp(along + C.SKEWER_OFFSET, -halfLen, halfLen + 0.4)
	local anchor  = hitbox.CFrame:PointToWorldSpace(axis * along)
	local tipDir  = hitbox.CFrame:VectorToWorldSpace(axis)
	-- the blade went in through the face: the face looks back down the blade
	local headCF  = CFrame.lookAt(anchor, anchor - tipDir)

	local function scrub(part)
		for _, d in ipairs(part:GetDescendants()) do
			if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("BaseScript") or d:IsA("Sound") then
				d:Destroy()
			end
		end
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		part.Massless, part.Anchored = true, false
		part.Transparency = 0
	end

	-- the trophy: their actual head — face, mesh and all — plus whatever they
	-- were wearing on it, so it reads as that specific enemy's head
	local trophy = Instance.new("Model")
	trophy.Name = "SkeweredHead"

	local headClone = head:Clone()
	headClone.Name = "Head"
	scrub(headClone)
	headClone.CFrame = headCF
	headClone.Parent = trophy
	trophy.PrimaryPart = headClone

	for _, acc in ipairs(char:GetChildren()) do
		if acc:IsA("Accessory") then
			local h = acc:FindFirstChild("Handle")
			local onHead = false
			if h and h:IsA("BasePart") then
				for _, j in ipairs(acc:GetDescendants()) do
					if j:IsA("JointInstance") and (j.Part0 == head or j.Part1 == head) then onHead = true; break end
				end
			end
			if onHead then
				local rel = head.CFrame:ToObjectSpace(h.CFrame)
				local hatClone = h:Clone()
				scrub(hatClone)
				hatClone.CFrame = headClone.CFrame * rel
				hatClone.Parent = trophy
				local hw = Instance.new("WeldConstraint")
				hw.Part0, hw.Part1 = headClone, hatClone
				hw.Parent = hatClone
				h.Transparency = 1   -- the corpse loses it along with the head
				h.CanQuery = false
			end
		end
	end

	-- their helmet comes along on the blade too
	carryClothing(char, "Head", head, headClone, trophy)

	trophy.Parent = workspace

	local weld = Instance.new("WeldConstraint")
	weld.Name = "SkewerWeld"
	weld.Part0, weld.Part1 = hitbox, headClone
	weld.Parent = headClone

	-- the real head stays on the corpse, just invisible and un-hittable
	head.Transparency = 1
	head.CanQuery = false
	for _, d in ipairs(head:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1 end
	end

	bloodEmitter(headClone, 25, 2)
	bloodEmitter(head, 12, 4)
	Sounds.play(SoundConfig.Impale, headClone)

	local dropped = false
	local function release()
		if dropped then return false end
		dropped = true
		skewers[hitbox] = nil
		if weld.Parent then weld:Destroy() end
		for _, p in ipairs(trophy:GetDescendants()) do
			if p:IsA("BasePart") then p.Massless = false end
		end
		Debris:AddItem(trophy, C.HEAD_THROW_LIFE)
		return true
	end
	local function drop()
		if release() and headClone.Parent then
			headClone.CanCollide = true
			headClone.AssemblyLinearVelocity = dir * 4 + Vector3.new(0, 3, 0)
		end
	end
	skewers[hitbox] = {trophy = trophy, head = headClone, weld = weld, drop = drop, release = release}
	if C.SKEWER_DURATION > 0 then task.delay(C.SKEWER_DURATION, drop) end
	local tool = hitbox:FindFirstAncestorOfClass("Tool")
	if tool then
		tool.Unequipped:Once(drop)
		tool.Destroying:Once(drop)
	end
	return true
end

-- The attacker swings: the head comes off the blade as a projectile. onHit(model, part)
-- is called once for the first other humanoid it strikes (the caller decides damage).
function Injury.launchSkewer(hitbox, dir, speed, thrower, onHit)
	local e = hitbox and skewers[hitbox]
	if not (e and e.head.Parent) then return false end
	local head = e.head
	if not e.release() then return false end
	dir = (typeof(dir) == "Vector3" and dir.Magnitude > 1e-4) and dir.Unit or Vector3.new(0, 0, -1)
	head.CanCollide, head.CanTouch, head.CanQuery = true, true, true
	head.AssemblyLinearVelocity  = dir * (speed or 60)
	head.AssemblyAngularVelocity = Vector3.new(math.random() * 20, math.random() * 20, math.random() * 20)
	e.trophy:SetAttribute("Thrown", true)
	Sounds.play(SoundConfig.HeadThrow, head)
	local struck = false
	local t0 = os.clock()
	head.Touched:Connect(function(part)
		if struck or os.clock() - t0 > 3 then return end
		local model = part:FindFirstAncestorOfClass("Model")
		while model and not model:FindFirstChildOfClass("Humanoid") do model = model:FindFirstAncestorOfClass("Model") end
		if not model or model == thrower or part:IsDescendantOf(e.trophy) then return end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return end
		if head.AssemblyLinearVelocity.Magnitude < 12 then return end   -- rolling on the floor doesn't count
		struck = true
		if onHit then onHit(model, part) end
	end)
	return true
end

--------------------------------------------------------------------
--  DISMEMBER  (fatal = the limb comes off and they die; otherwise they
--  survive on BLEED_HP and bleed. Head is always fatal.)
--------------------------------------------------------------------
function Injury.dismember(char, partName, dir, fatal)
	local part  = char:FindFirstChild(partName)
	local torso = char:FindFirstChild("Torso")
	local hum   = char:FindFirstChildOfClass("Humanoid")
	local key   = attrKey(partName)
	if not (part and torso and hum and key) or char:GetAttribute(key) then return false end

	local joint
	for _, m in ipairs(torso:GetChildren()) do
		if m:IsA("Motor6D") and m.Part1 == part then joint = m; break end
	end
	local socketCF = joint and (torso.CFrame * joint.C0) or part.CFrame
	dir = dir or torso.CFrame.LookVector

	if partName == "Head" then
		-- decapitation: the real head comes off and the humanoid is killed outright
		-- (RequiresNeck is off so ragdoll knockdowns can disable the Neck motor)
		if joint then joint:Destroy() end
		part.CanCollide = true
		part.AssemblyLinearVelocity  = dir * 12 + Vector3.new(0, 10, 0)
		part.AssemblyAngularVelocity = Vector3.new(8, 4, 8)
		bloodEmitter(part, 40, 4)
		hum.Health = 0
	else
		local clone = part:Clone()
		clone:ClearAllChildren()
		clone.Name = partName .. " (severed)"
		clone.CanCollide, clone.CanQuery, clone.CanTouch, clone.Anchored = true, false, false, false
		clone.CFrame = part.CFrame
		carryClothing(char, partName, part, clone, clone)   -- armor goes with the limb
		clone.Parent = workspace
		clone.AssemblyLinearVelocity  = dir * 15 + Vector3.new(0, 8, 0)
		clone.AssemblyAngularVelocity = Vector3.new(6, 6, 6)
		bloodEmitter(clone, 15, 3)
		Debris:AddItem(clone, C.LIMB_DEBRIS_TIME)
		-- the real limb stays so the rig keeps animating, just no longer seen or hit
		part.Transparency, part.CanCollide, part.CanQuery, part.CanTouch = 1, false, false, false
	end

	local stump = Instance.new("Part")
	stump.Name = "Stump_" .. LIMB_KEY[partName]
	stump.Size = Vector3.new(0.9, 0.35, 0.9)
	stump.Color = C.BLOOD_COLOR
	stump.Material = Enum.Material.SmoothPlastic
	stump.CanCollide, stump.CanQuery, stump.CanTouch, stump.Massless = false, false, false, true
	stump.CFrame = socketCF
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = torso, stump, stump
	stump.Parent = char
	bloodEmitter(stump, 8, nil)

	char:SetAttribute(key, true)
	char:SetAttribute("Blocking", false)
	Injury.recomputeMobility(char)
	Sounds.play(SoundConfig.Dismember, torso)
	if partName ~= "Head" then
		if fatal then hum.Health = 0 else Injury.startBleed(char) end
	end
	return true
end

return Injury
