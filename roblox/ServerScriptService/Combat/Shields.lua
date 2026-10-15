--[[ SHIELDS — a shield in the secondary slot, beside a one-handed primary (Catalog ▸ Arsenal).
     It's worn, not held: a copy of its Tool's body (ServerStorage ▸ Weapons ▸ <id>) welded to
     your torso at your left arm, in its skin and arms (Dresser.applySkin, Heraldry). Every
     screen raises it in front of you while you block (Combat ▸ Powers.client: the weld's
     IdleC0 / BlockC0). The block itself is a GuardHull welded in front of you that's only
     there to blades while Blocking is on, so a blow that meets it is blocked, like a weapon's.

     What it does is on the character for the combat code: ShieldId (which), ShieldCone (CombatServer: the
     guard catches blows from wider), ShieldBlock (× a block's stamina), ShieldParry (× the
     parry window), ShieldArrows (it stops arrows, bolts and thrown things from the front:
     RangedServer, MagicServer, Throwing ask Shields.stops), ShieldBash / ShieldStun (the
     kick is a bash), SpeedMult_Shield.

       Shields.wear(character, shieldId, skinId)   Shields.unwear(character)
       Shields.stops(target, fromPosition) -> bool ]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))

local Shields = {}
local IDLE = CFrame.new(-1.55, -0.3, 0.05) * CFrame.Angles(0, math.rad(90), 0)    -- on the left arm, face out
local BLOCK = CFrame.new(-0.35, 0.2, -1.3) * CFrame.Angles(0, math.rad(12), 0)     -- up in front of you
local ATTRS = {"ShieldId", "ShieldCone", "ShieldBlock", "ShieldParry", "ShieldArrows", "ShieldBash", "ShieldStun", "SpeedMult_Shield"}

local function template(id)
	local f = ServerStorage:FindFirstChild("Weapons")
	local t = f and f:FindFirstChild(id)
	if t and not t:FindFirstChild("Handle") then
		pcall(function() require(ServerScriptService:WaitForChild("Build"):WaitForChild("Blueprints")).completeTool(t) end)
	end
	return t and t:FindFirstChild("Handle") and t or nil
end

function Shields.unwear(c)
	for _, n in ipairs({"ShieldModel", "ShieldHull"}) do
		local old = c:FindFirstChild(n)
		if old then old:Destroy() end
	end
	for _, a in ipairs(ATTRS) do c:SetAttribute(a, nil) end
end

function Shields.wear(c, id, skinId)
	Shields.unwear(c)
	local def = Catalog.WEAPON[id or ""]
	if not (def and def.shield) then return false end
	local torso = c:FindFirstChild("Torso")
	local t = template(id)
	if not (torso and t) then return false end
	-- the body: every visible part of the Tool, welded to its Handle
	local m = Instance.new("Model")
	m.Name = "ShieldModel"
	local handle
	for _, d in ipairs(t:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Hitbox" and d.Name ~= "GuardHull" then
			local p = d:Clone()
			for _, x in ipairs(p:GetChildren()) do if not (x:IsA("SpecialMesh") or x:IsA("Decal") or x:IsA("Texture")) then x:Destroy() end end
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
			p.Parent = m
			if d.Name == "Handle" then handle = p end
		end
	end
	if not handle then m:Destroy(); return false end
	-- (the whole body where it goes first, THEN the welds: a weld keeps whatever offset it finds)
	m.PrimaryPart = handle
	m:PivotTo(torso.CFrame * IDLE)
	for _, p in ipairs(m:GetChildren()) do
		if p ~= handle and p:IsA("BasePart") then
			local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = handle, p; w.Parent = p
		end
	end
	local grip = Instance.new("Weld")
	grip.Name = "ShieldGrip"
	grip.Part0, grip.Part1 = torso, handle
	grip.C0 = IDLE
	grip:SetAttribute("IdleC0", IDLE)
	grip:SetAttribute("BlockC0", BLOCK)
	grip.Parent = handle
	m.Parent = c
	if skinId then pcall(Dresser.applySkin, m, skinId) end
	-- the guard: in front of you, only there to blades while you block
	local face
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") and p:GetAttribute("ShieldFace") then face = p end end
	local w = face and face:GetAttribute("FaceW") or 2
	local h = face and face:GetAttribute("FaceH") or 2
	local hull = Instance.new("Part")
	hull.Name = "ShieldHull"
	hull.Size = Vector3.new(w + 0.8, h + 0.6, 1.6)
	hull.Transparency = 1
	hull.CanCollide, hull.CanTouch, hull.CanQuery, hull.Massless = false, false, false, true
	hull.CFrame = torso.CFrame * BLOCK * CFrame.new(0, 0, -0.2)
	local hw = Instance.new("Weld"); hw.Part0, hw.Part1, hw.C0 = torso, hull, BLOCK * CFrame.new(0, 0, -0.2); hw.Parent = hull
	-- (blade sweeps stop on a part named GuardHull: CombatClient / CombatServer)
	local guard = hull:Clone()
	guard.Name = "GuardHull"
	for _, x in ipairs(guard:GetChildren()) do x:Destroy() end
	guard.Parent = hull
	local gw = Instance.new("WeldConstraint"); gw.Part0, gw.Part1 = hull, guard; gw.Parent = guard
	hull.Parent = c
	local function sync() guard.CanQuery = c:GetAttribute("Blocking") == true end
	c:GetAttributeChangedSignal("Blocking"):Connect(sync)
	sync()
	c:SetAttribute("ShieldId", id)   -- (not "Shield": that's a barrier's points, Combat ▸ Ward)
	c:SetAttribute("ShieldCone", def.cone or 0)
	c:SetAttribute("ShieldBlock", def.block or 1)
	c:SetAttribute("ShieldParry", def.parry or 1)
	c:SetAttribute("ShieldArrows", def.arrows == true or nil)
	c:SetAttribute("ShieldBash", def.bash or nil)
	c:SetAttribute("ShieldStun", def.stun or nil)
	c:SetAttribute("SpeedMult_Shield", (def.speed or 1) < 1 and def.speed or nil)
	return true
end

-- is `target` blocking with a shield that stops things, toward `from`?
function Shields.stops(target, from)
	if not (target and target:GetAttribute("ShieldArrows") and target:GetAttribute("Blocking")) then return false end
	local r = target:FindFirstChild("HumanoidRootPart")
	if not (r and typeof(from) == "Vector3") then return false end
	local to = Vector3.new(from.X - r.Position.X, 0, from.Z - r.Position.Z)
	if to.Magnitude < 0.1 then return true end
	return r.CFrame.LookVector:Dot(to.Unit) >= math.cos(math.rad(70 + (target:GetAttribute("ShieldCone") or 0)))
end

return Shields
