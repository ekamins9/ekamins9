--[[ SHIELDS — a shield in the secondary slot, beside a one-handed primary (Catalog ▸ Arsenal).
     It's worn, not held: a copy of its Tool's body (ServerStorage ▸ Weapons ▸ <id>) strapped
     to your LEFT ARM (welded to it: it goes wherever the arm goes), in its skin and arms
     (Dresser.applySkin, Heraldry, ShieldDress). While you block, the arm comes up across your
     chest (RigPose) and the shield turns upright on it, facing the blow (Combat ▸
     Powers.client: the weld's IdleC0 / BlockC0, in the arm's frame). The block itself is a GuardHull welded in front of you that's only
     there to blades while Blocking is on, so a blow that meets it is blocked, like a weapon's.

     What it does is on the character for the combat code: ShieldId (which), ShieldCone (CombatServer: the
     guard catches blows from wider), ShieldBlock (× a block's stamina), ShieldParry (× the
     parry window), ShieldArrows (it stops arrows, bolts and thrown things from the front:
     RangedServer, MagicServer, Throwing ask Shields.stops), ShieldBash / ShieldStun (the
     kick is a bash), SpeedMult_Shield.

       Shields.wear(character, shieldId, skinId, appearance)   Shields.unwear(character)
                                  (appearance: the player's, for their own arms on a plain shield)
       Shields.sling(character, true | false)
       Shields.stops(target, fromPosition) -> bool

     SLUNG ON YOUR BACK: whenever what's in your hand can't go beside a shield (a two-hander, a
     polearm, a bow, a staff: one picked up off the floor, a looted one), the shield goes onto your
     back by itself (ShieldSlung), and none of what it does is on you (no shield block, cone,
     bash, arrows) until a one-handed weapon is back in your hand and it comes back to the arm. ]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))

local Shields = {}
-- IN THE LEFT ARM'S FRAME. At ease: on the outside of the forearm, face out, the board's back
-- against the arm and its armor (further out it floats; further in the arm comes through it)
local IDLE = CFrame.new(-0.35, -0.3, 0.05) * CFrame.Angles(0, math.rad(90), 0)
-- blocking: the arm raised across the chest (RigPose SHIELD_RAISE / SHIELD_ACROSS), the shield
-- turned upright on it, facing forward (a little to the left), just in front of the chest
local BLOCK = CFrame.new(-0.35, -0.3, 0, 0, 0, 1, -0.98545, 0.16997, 0, -0.16997, -0.98545, 0)
-- the guard that catches blades while you block, where the raised shield is (TORSO frame)
local HULL = CFrame.new(-0.6, 0.35, -1.4) * CFrame.Angles(0, math.rad(21), 0)
-- (no left arm: the same places on the torso)
local ARM_AT = CFrame.new(-1.5, 0, 0)
local ATTRS = {"ShieldId", "ShieldCone", "ShieldBlock", "ShieldParry", "ShieldArrows", "ShieldBash", "ShieldStun", "SpeedMult_Shield"}
-- ON THE BACK, IN THE TORSO'S FRAME: face out behind you, a little tilted
local SLUNG = CFrame.new(0.1, 0.15, 0.8) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, math.rad(14))
local worn = setmetatable({}, {__mode = "k"})   -- [character] = {attrs, slung, conns}

local function template(id)
	local f = ServerStorage:FindFirstChild("Weapons")
	local t = f and f:FindFirstChild(id)
	if t and not t:FindFirstChild("Handle") then
		pcall(function() require(ServerScriptService:WaitForChild("Build"):WaitForChild("Blueprints")).completeTool(t) end)
	end
	return t and t:FindFirstChild("Handle") and t or nil
end

function Shields.unwear(c)
	local w = worn[c]
	if w then for _, cn in ipairs(w.conns) do cn:Disconnect() end end
	worn[c] = nil
	c:SetAttribute("ShieldSlung", nil)
	for _, n in ipairs({"ShieldModel", "ShieldHull"}) do
		local old = c:FindFirstChild(n)
		if old then old:Destroy() end
	end
	for _, a in ipairs(ATTRS) do c:SetAttribute(a, nil) end
end

function Shields.wear(c, id, skinId, appearance)
	Shields.unwear(c)
	local def = Catalog.WEAPON[id or ""]
	if not (def and def.shield) then return false end
	local torso = c:FindFirstChild("Torso")
	local arm = c:FindFirstChild("Left Arm")
	local t = template(id)
	if not (torso and t) then return false end
	local idle, block = IDLE, BLOCK
	if not arm then arm, idle, block = torso, ARM_AT * IDLE, ARM_AT * BLOCK end
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
	m:PivotTo(arm.CFrame * idle)
	for _, p in ipairs(m:GetChildren()) do
		if p ~= handle and p:IsA("BasePart") then
			local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = handle, p; w.Parent = p
		end
	end
	local grip = Instance.new("Weld")
	grip.Name = "ShieldGrip"
	grip.Part0, grip.Part1 = arm, handle
	grip.C0 = idle
	grip:SetAttribute("IdleC0", idle)
	grip:SetAttribute("BlockC0", block)
	grip.Parent = handle
	m.Parent = c
	if skinId then pcall(Dresser.applySkin, m, skinId) end
	-- a plain shield carries your own arms (LOOK ▸ YOUR ARMS), on your side's colour in a team
	-- fight; with none of your own, there, your side's house's: the arms its banners fly on this map
	-- (ShieldPaint.plain, ReplicatedStorage ▸ Houses)
	if not skinId or tostring(skinId):match(":Default$") then
		pcall(function() require(ReplicatedStorage:WaitForChild("ShieldPaint")).plain(m, appearance, c:GetAttribute("Team")) end)
	end
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
	hull.CFrame = torso.CFrame * HULL
	local hw = Instance.new("Weld"); hw.Part0, hw.Part1, hw.C0 = torso, hull, HULL; hw.Parent = hull
	-- (blade sweeps stop on a part named GuardHull: CombatClient / CombatServer)
	local guard = hull:Clone()
	guard.Name = "GuardHull"
	for _, x in ipairs(guard:GetChildren()) do x:Destroy() end
	guard.Parent = hull
	local gw = Instance.new("WeldConstraint"); gw.Part0, gw.Part1 = hull, guard; gw.Parent = guard
	hull.Parent = c
	local function sync() guard.CanQuery = c:GetAttribute("Blocking") == true and not c:GetAttribute("ShieldSlung") end
	local w0 = {conns = {}, attrs = nil, slung = false, grip = grip, arm = arm, torso = torso, idle = idle}
	worn[c] = w0
	table.insert(w0.conns, c:GetAttributeChangedSignal("Blocking"):Connect(sync))
	sync()
	c:SetAttribute("ShieldId", id)   -- (not "Shield": that's a barrier's points, Combat ▸ Ward)
	c:SetAttribute("ShieldCone", def.cone or 0)
	c:SetAttribute("ShieldBlock", def.block or 1)
	c:SetAttribute("ShieldParry", def.parry or 1)
	c:SetAttribute("ShieldArrows", def.arrows == true or nil)
	c:SetAttribute("ShieldBash", def.bash or nil)
	c:SetAttribute("ShieldStun", def.stun or nil)
	c:SetAttribute("SpeedMult_Shield", (def.speed or 1) < 1 and def.speed or nil)
	-- onto the back while what's in your hand can't go beside it
	local function check()
		local tool = c:FindFirstChildOfClass("Tool")
		local fits = true
		if tool then
			local wid = tool:GetAttribute("Twin") and not Catalog.WEAPON[tool.Name] and tool:GetAttribute("Twin") or tool.Name
			local wdef = Catalog.WEAPON[wid]
			local cfgMod = tool:FindFirstChild("Config")
			local okc, cfg = pcall(function() return cfgMod and require(cfgMod) end)
			local twoHanded = okc and type(cfg) == "table" and cfg.TWO_HANDED == true
			fits = wdef ~= nil and wdef.family == "OneHanded" and not wdef.ranged and not wdef.magic and not twoHanded
		end
		Shields.sling(c, not fits)
		sync()
	end
	table.insert(w0.conns, c.ChildAdded:Connect(function(x) if x:IsA("Tool") then task.defer(check) end end))
	table.insert(w0.conns, c.ChildRemoved:Connect(function(x) if x:IsA("Tool") then task.defer(check) end end))
	task.defer(check)
	return true
end

-- the shield onto your back (true) or back on your arm (false)
function Shields.sling(c, on)
	local w = worn[c]
	if not w or w.slung == on then return end
	local grip = w.grip
	if not (grip and grip.Parent) then return end
	w.slung = on
	if on then
		w.attrs = {}
		for _, a in ipairs(ATTRS) do w.attrs[a] = c:GetAttribute(a); c:SetAttribute(a, nil) end
		c:SetAttribute("ShieldSlung", w.attrs.ShieldId or true)
		grip.Part0 = w.torso
		grip.C0 = SLUNG
	else
		for a, v in pairs(w.attrs or {}) do c:SetAttribute(a, v) end
		w.attrs = nil
		c:SetAttribute("ShieldSlung", nil)
		grip.Part0 = w.arm
		grip.C0 = w.idle
	end
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
