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

local Injury = {}

Injury.CONFIG = {
	BLEED_HP         = 25,    -- health you're left with after losing a limb…
	BLEED_TIME       = 10,    -- …and how long until it's gone (a bandage system can clear Bleeding)
	LEG_SPEED        = 0.45,  -- WalkSpeed factor per lost leg
	LEG_CLUNK        = 1.5,   -- footstep clunk factor per lost leg
	DISARM_FLING     = 30,    -- studs/s the weapon leaves the hand at
	DISARM_NO_PICKUP = 2.0,   -- seconds before a flung weapon can be grabbed again
	LIMB_DEBRIS_TIME = 25,
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
--  DISARM — the equipped Tool leaves the hand and lands as a real pickup
--------------------------------------------------------------------
function Injury.disarm(char, dir)
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return false end
	local handle = tool:FindFirstChild("Handle")
	local hrp    = char:FindFirstChild("HumanoidRootPart")
	local hum    = char:FindFirstChildOfClass("Humanoid")

	char:SetAttribute("Blocking", false)
	if hum then hum:UnequipTools() end
	tool.Parent = workspace
	if handle and hrp then
		handle.CFrame = hrp.CFrame * CFrame.new(1.5, 1.5, -1)
		local fling = (dir or hrp.CFrame.LookVector) + Vector3.new(0, 0.8, 0)
		handle.AssemblyLinearVelocity  = fling.Unit * C.DISARM_FLING
		handle.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		handle.CanTouch = false
		task.delay(C.DISARM_NO_PICKUP, function()
			if handle.Parent then handle.CanTouch = true end
		end)
	end
	Sounds.play(SoundConfig.Disarm, handle or hrp)
	return true
end

--------------------------------------------------------------------
--  DISMEMBER
--------------------------------------------------------------------
function Injury.dismember(char, partName, dir)
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
	if partName ~= "Head" then Injury.startBleed(char) end
	return true
end

return Injury
