--[[ HURL — throw your own steel (the Hurl key, Y: hold to aim like a throwable, let go to throw).
     What goes is your SHIELD off your arm first; once it's gone, the ONE-HANDED weapon in your
     hand (a two-hander, a bow or a staff stays put). It flies on the arc your screen drew
     (Catalog.hurlOf: its speed and drop, the same Ballistics.launch), turning end over end, a
     shield flat and spinning, and hits like a heavy blow: a shield slams them back, staggered
     and dazed; a blade or a head lands its weapon's best blow and then some (a shield raised
     toward it turns it, with a clang). Then it's on the ground where it fell: a blade or an axe
     stuck in the turf or a beam where it went in, anything else lying flat, for 60 seconds.
     Walk over and pick it up (Combat ▸ Pickup's prompt: a weapon into your hands, a shield
     back onto your arm); anyone who could carry it may take it instead. Your other weapon
     comes to hand when the first one's thrown.

     Not in the Courtyard, the tavern or the loot games (Crownfall, Deadvault: gear lives in
     the bag there).

       Hurl.what(c) -> "shield" | "weapon" | nil, thing, def, how
       Hurl.aim(c) -> ok, why    Hurl.release(c, aim)    Hurl.cancel(c)
     ThrowFX (to every screen): "Throw", id, origin, velocity, gravity, weaponId, skin, thrower,
     the thing itself (each screen flies a copy of it, skin and paint and all), its look ·
     "Land", id ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Ballistics = require(ReplicatedStorage:WaitForChild("Ballistics"))
local Sounds = require(ReplicatedStorage:WaitForChild("Sounds"))
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local MagicServer = require(script.Parent:WaitForChild("MagicServer"))
local Injury = require(script.Parent:WaitForChild("Injury"))
local Pickup = require(script.Parent:WaitForChild("Pickup"))
local Janitor = require(script.Parent:WaitForChild("Janitor"))

local Hurl = {}
local fx = ReplicatedStorage:FindFirstChild("ThrowFX")
if not fx then fx = Instance.new("RemoteEvent"); fx.Name = "ThrowFX"; fx.Parent = ReplicatedStorage end

local LIE = 60            -- seconds a thrown thing lies where it fell
local AIM_SLOW = 0.8      -- walking while you aim
local AIM_MAX = 10        -- held longer than this: put away
local GAP = 0.6           -- between one throw and the next
local NO_HURL = {Hub = true, Tavern = true, Crownfall = true, Deadvault = true}
local WHOOSH = "rbxassetid://9120709477"

local state = setmetatable({}, {__mode = "k"})
local seq = 0
local Shields, Profile
local function shields() Shields = Shields or require(script.Parent:WaitForChild("Shields")); return Shields end
local function profile()
	Profile = Profile or require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
	return Profile
end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function folder()
	local f = workspace:FindFirstChild("DroppedWeapons")
	if not f then f = Instance.new("Folder"); f.Name = "DroppedWeapons"; f.Parent = workspace end
	return f
end

--------------------------------------------------------------------
--  WHAT GOES
--------------------------------------------------------------------
-- the shield on your arm (not slung on your back), its id
local function shieldOf(c)
	local m = c:FindFirstChild("ShieldModel")
	local id = c:GetAttribute("ShieldId")
	if not (m and id) or c:GetAttribute("ShieldSlung") then return nil end
	return m, id
end
-- the one-hander in your hand
local function toolOf(c)
	local t = c:FindFirstChildOfClass("Tool")
	if not t or t:GetAttribute("NoDrop") or t:GetAttribute("TwinHidden") or Pickup.isDropped(t) then return nil end
	local def = Catalog.WEAPON[t.Name]
	local how = def and Catalog.hurlOf(def)
	local cfg = Pickup.config(t)
	if not how or cfg.TWO_HANDED == true then return nil end
	-- (it hits with its own best blow, and then some)
	local best = 20
	for _, a in pairs(cfg.ATTACKS or {}) do if type(a) == "table" and (a.damage or 0) > best then best = a.damage end end
	how = table.clone(how)
	how.damage = best * Catalog.WEAPON_HURL
	return t, def, how
end
function Hurl.what(c)
	local m, id = shieldOf(c)
	if m then
		local def = Catalog.WEAPON[id]
		local how = def and Catalog.hurlOf(def)
		if how then return "shield", m, def, how end
	end
	local t, def, how = toolOf(c)
	if t then return "weapon", t, def, how end
	return nil
end

local function allowed(c)
	local round = ReplicatedStorage:FindFirstChild("Round")
	local mode = round and round:GetAttribute("Mode")
	if NO_HURL[mode or ""] then
		return false, (mode == "Crownfall" or mode == "Deadvault") and "not here: your gear lives in your bag" or ""
	end
	local hum = humOf(c)
	if not (hum and hum.Health > 0) or c:GetAttribute("Ragdolled") then return false, "" end
	if (c:GetAttribute("StunnedUntil") or 0) > os.clock() then return false, "" end
	return true
end

--------------------------------------------------------------------
--  THE GROUND IT ENDS ON
--------------------------------------------------------------------
local function groundParams(extra)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {}
	for _, n in ipairs({"DroppedWeapons", "StuckArrows", "MagicFX", "PowerFX", "LocalFX", "ThrownHelmets", "Corpses"}) do
		local f = workspace:FindFirstChild(n); if f then table.insert(ex, f) end
	end
	for _, m in ipairs(MagicServer.everyone()) do table.insert(ex, m) end
	for _, x in ipairs(extra or {}) do table.insert(ex, x) end
	p.FilterDescendantsInstances = ex
	p.IgnoreWater = true
	return p
end
local function groundBelow(at)
	local res = workspace:Raycast(at + Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), groundParams())
	return res and res.Position or (at - Vector3.new(0, 3, 0)), res and res.Normal or Vector3.yAxis
end
-- how far the business end reaches up the Handle's +Y (the tip)
local function tipOf(thing, handle)
	local top = 1
	for _, p in ipairs(thing:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "Hitbox" and p.Name ~= "GuardHull" and p.Transparency < 1 then
			local cf = handle.CFrame:ToObjectSpace(p.CFrame)
			local h = p.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				top = math.max(top, (cf * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
			end end end
		end
	end
	return top
end
-- a weapon lying flat (the Handle's +Y along `along`, the flat of the blade up)
local function flatWeapon(at, along)
	local h = Vector3.new(along.X, 0, along.Z)
	h = h.Magnitude > 0.05 and h.Unit or Vector3.xAxis
	local p = at + Vector3.new(0, 0.12, 0)
	return CFrame.lookAt(p, p + h) * CFrame.Angles(-math.pi / 2, 0, 0)
end
-- a shield lying face up on its straps (the Handle's -Z, the face, toward the sky)
local function flatShield(at, along)
	local h = Vector3.new(along.X, 0, along.Z)
	h = h.Magnitude > 0.05 and h.Unit or Vector3.xAxis
	return CFrame.fromMatrix(at + Vector3.new(0, 0.14, 0), h, Vector3.new(-h.Z, 0, h.X))
end

-- every part of a thing to `cf` (its Handle there), still and solid enough to stand on nothing
local function placeAll(thing, handle, cf)
	local offs = {}
	for _, p in ipairs(thing:GetDescendants()) do
		if p:IsA("BasePart") then offs[p] = handle.CFrame:ToObjectSpace(p.CFrame) end
	end
	for p, off in pairs(offs) do
		p.Anchored = true
		p.CFrame = cf * off
	end
end
-- out of the world while it flies (each screen flies its own copy)
local PARK = Vector3.new(0, 4500, 0)
local function park(thing, handle, n)
	for _, p in ipairs(thing:GetDescendants()) do
		if p:IsA("BasePart") then
			if thing:IsA("Tool") then Pickup.remember(p) end   -- (its own settings, for when it's taken up)
			p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
		end
	end
	placeAll(thing, handle, CFrame.new(PARK + Vector3.new((n % 40) * 12, 0, math.floor(n / 40) * 12)))
end

--------------------------------------------------------------------
--  A SHIELD ON THE GROUND: its own prompt, back onto an arm
--------------------------------------------------------------------
local function canCarryShield(char)
	if not char or char:FindFirstChild("ShieldModel") then return false, "you have a shield" end
	local cls = GameConfig.CLASSES[char:GetAttribute("Class") or ""]
	if not cls or cls.ranged or cls.magic then return false, "your class carries no shield" end
	if char:GetAttribute("LimbLost_LeftArm") == true then return false, "" end
	return true
end
local function layShield(m, id, skinId, cf)
	local handle = m:FindFirstChild("Handle")
	if not handle then m:Destroy(); return end
	placeAll(m, handle, cf)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide, p.CanTouch, p.CanQuery = false, false, false end
	end
	m.Name = "DroppedShield"
	m:SetAttribute("DroppedShield", id)
	m:SetAttribute("Dropped", true)
	local def = Catalog.WEAPON[id]
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = def and def.name or "Shield"
	prompt.KeyboardKeyCode = Enum.KeyCode.V   -- (the client swaps in its own keybind)
	prompt.HoldDuration = Pickup.CONFIG.PROMPT_HOLD
	prompt.MaxActivationDistance = Pickup.CONFIG.PROMPT_RANGE
	prompt.RequiresLineOfSight = false
	prompt.Parent = handle
	local taken = false
	prompt.Triggered:Connect(function(plr)
		if taken or not m.Parent then return end
		local char = plr.Character
		local hum, r = humOf(char), rootOf(char)
		if not (hum and r and hum.Health > 0) or (r.Position - handle.Position).Magnitude > Pickup.CONFIG.PROMPT_RANGE + 4 then return end
		local ok = canCarryShield(char)
		if not ok then return end
		taken = true
		local app
		pcall(function() app = profile().get(plr).appearance end)
		shields().wear(char, id, skinId, app)
		Sounds.play(require(ReplicatedStorage:WaitForChild("SoundConfig")).Pickup, r)
		m:Destroy()
	end)
	m.Parent = folder()
	local stamp = os.clock()
	m:SetAttribute("DropStamp", stamp)
	Janitor.add(m, "Thrown", {life = LIE, still = function() return m.Parent ~= nil and not taken end})
end

--------------------------------------------------------------------
--  THE FLIGHT AND WHERE IT ENDS
--------------------------------------------------------------------
local STICKS = {blade = true, axe = true}
local function push(m, vel)
	local r = rootOf(m)
	if not r then return end
	local att = Instance.new("Attachment"); att.Name = "Shove"; att.Parent = r
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att; lv.MaxForce = 4e5; lv.VectorVelocity = vel
	lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = r
	task.delay(0.2, function() lv:Destroy(); att:Destroy() end)
end

-- the blow it lands (nil: it didn't), on whoever was in the way
local function strike(c, rec, model, part, at, dir)
	local hum = humOf(model)
	if not (hum and hum.Health > 0) or model == c then return nil end
	local how = rec.how
	if shields().stops(model, at - dir * 6) then
		-- turned on their shield: a clang, sparks, and it drops at their feet
		Injury.sparks(at, 1)
		Sounds.bank("Block", part)
		pcall(shields().batter, model, at, 0.12)
		model:SetAttribute("GuardText", "SHIELD")
		model:SetAttribute("GuardTick", (model:GetAttribute("GuardTick") or 0) + 1)
		return "blocked"
	end
	local head = part.Name == "Head"
	local dmg = how.damage or 20
	if head then dmg *= how.headMult or 1.4 end
	local label = "Thrown " .. (rec.def and rec.def.name or "weapon")
	if MagicServer.hurt(c, model, dmg, label, head) then
		CombatServer.interrupt(model, "hit")
		local now = os.clock()
		if not model:GetAttribute("Boss") then
			model:SetAttribute("StunnedUntil", math.max(model:GetAttribute("StunnedUntil") or 0, now + (how.stun or 0.3)))
			if rec.kind == "shield" then model:SetAttribute("DazedUntil", workspace:GetServerTimeNow() + (how.stun or 0.8)) end
			local flat = Vector3.new(dir.X, 0, dir.Z)
			if flat.Magnitude > 0.05 and (how.push or 0) > 0 then push(model, flat.Unit * how.push + Vector3.new(0, 6, 0)) end
		end
		Sounds.bank(rec.kind == "shield" and "KickHit" or (how.look == "blunt" and "HitBlunt" or "HitStab"), part)
		if head and c.Parent then
			c:SetAttribute("GuardText", "HEADSHOT"); c:SetAttribute("GuardTick", (c:GetAttribute("GuardTick") or 0) + 1)
		end
		return "hit"
	end
	return "glanced"
end

local function finish(c, rec, res, vel)
	local dir = vel.Magnitude > 0.1 and vel.Unit or Vector3.zAxis
	local part = res and res.Instance
	local pos = res and res.Position or rec.lastPos
	local thing, handle = rec.thing, rec.handle
	fx:FireAllClients("Land", rec.id, pos, nil)
	if not (thing and thing.Parent and handle and handle.Parent) then return end
	-- whoever it hit
	local model = part and part:FindFirstAncestorOfClass("Model")
	local hum = model and humOf(model)
	while model and not hum do
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
		hum = model and humOf(model)
	end
	local outcome = (model and hum) and strike(c, rec, model, part, pos, dir) or nil
	-- where it ends up
	local cf
	if not outcome and part and rec.kind == "weapon" and STICKS[rec.how.look] then
		local fam = CombatServer.wallFamily(res.Material and res.Material.Name or "") or "Ground"
		if fam == "Ground" or fam == "Wood" then
			-- in where it went: point first, a hand's breadth deep (into the turf it goes in steeper)
			local n = res.Normal
			local into = dir
			if n.Y > 0.6 then into = (dir + Vector3.new(0, -0.9, 0)).Unit end
			local depth = rec.how.look == "axe" and 0.35 or 0.55
			local tip = tipOf(thing, handle)
			local at = pos - into * (tip - depth)
			cf = CFrame.lookAt(at, at + into) * CFrame.Angles(-math.pi / 2, 0, 0)
			Sounds.bank(fam == "Wood" and "WallWood" or "WallGround", part)
		else
			Injury.sparks(pos, 0.7)
			Sounds.bank(fam == "Metal" and "WallMetal" or "WallStone", part)
		end
	elseif not outcome and part then
		local fam = CombatServer.wallFamily(res.Material and res.Material.Name or "") or "Ground"
		if fam == "Stone" or fam == "Metal" then Injury.sparks(pos, 0.6) end
		Sounds.bank(rec.kind == "shield" and "KickHit" or ((fam == "Stone" and "WallStone") or (fam == "Metal" and "WallMetal") or (fam == "Wood" and "WallWood") or "WallGround"), part)
	end
	if not cf then
		-- (down onto the ground below where it ended, a step back toward the thrower off a body)
		local from = pos
		if outcome then from = pos - Vector3.new(dir.X, 0, dir.Z) * 1.4 end
		local g = groundBelow(from)
		cf = rec.kind == "shield" and flatShield(g, dir) or flatWeapon(g, dir)
	end
	if rec.kind == "shield" then
		layShield(thing, rec.shieldId, rec.skinId, cf)
	else
		placeAll(thing, handle, cf)
		Pickup.lay(thing, LIE)
	end
end

local function fly(c, rec, origin, vel, g)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {c}
	for _, n in ipairs({"StuckArrows", "MagicFX", "DroppedWeapons", "PowerFX", "ThrownHelmets", "Corpses"}) do
		local f = workspace:FindFirstChild(n); if f then table.insert(ignore, f) end
	end
	params.FilterDescendantsInstances = ignore
	local radius = rec.kind == "shield" and 0.8 or 0.4
	local pos, t0 = origin, os.clock()
	rec.lastPos = pos
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local nextVel = vel - Vector3.new(0, g * dt, 0)
		local step = (vel + nextVel) * 0.5 * dt
		local res = workspace:Spherecast(pos, radius, step, params)
		if res then
			conn:Disconnect()
			local ok, err = pcall(finish, c, rec, res, vel)
			if not ok then warn("[Hurl]", err) end
			return
		end
		pos += step
		vel = nextVel
		rec.lastPos = pos
		if os.clock() - t0 > 6 or pos.Y < -200 then
			conn:Disconnect()
			local ok, err = pcall(finish, c, rec, nil, vel)
			if not ok then warn("[Hurl]", err) end
		end
	end)
end

-- straight away (the wind-up's done): off the arm or out of the hand, and away
function Hurl.throw(c, aim)
	local ok, why = allowed(c)
	if not ok then return false, why end
	local s = state[c] or {}
	state[c] = s
	if os.clock() < (s.nextAt or 0) then return false, "" end
	local kind, thing, def, how = Hurl.what(c)
	if not kind then return false, "nothing to throw: a shield, or a one-handed weapon in your hand" end
	local head, r = c:FindFirstChild("Head"), rootOf(c)
	local handle = thing:FindFirstChild("Handle")
	if not (head and r and handle) then return false, "" end
	s.nextAt = os.clock() + GAP
	local g, speed = how.gravity or 34, how.speed or 80
	local dir, origin
	if typeof(aim) == "Vector3" and (aim - head.Position).Magnitude > 3 then
		dir, origin = Ballistics.launch(head.Position, aim, speed, g)
	end
	-- (the aim must be roughly where you face)
	local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
	if not dir or (look.Magnitude > 0.1 and Vector3.new(dir.X, 0, dir.Z).Magnitude > 0.1 and look.Unit:Dot(Vector3.new(dir.X, 0, dir.Z).Unit) < 0.5) then
		dir = (look.Unit + Vector3.new(0, 0.12, 0)).Unit
		origin = nil
	end
	origin = origin or (head.Position + dir * 1.2)
	local vel = dir * speed
	seq += 1
	local plr = Players:GetPlayerFromCharacter(c)
	local id = (plr and plr.UserId or 0) .. ":h" .. seq
	local rec = {id = id, kind = kind, def = def, how = how, thing = thing, handle = handle}
	if kind == "shield" then
		rec.shieldId = def.id
		local sk = thing:GetAttribute("Skin")
		rec.skinId = (sk and sk ~= "Default") and (def.id .. ":" .. sk) or nil
	end
	local skinId = rec.skinId or (kind == "weapon" and thing:GetAttribute("Skin") and (def.id .. ":" .. thing:GetAttribute("Skin"))) or nil
	c:SetAttribute("ThrowTick", (c:GetAttribute("ThrowTick") or 0) + 1)
	-- (every screen copies the thing as it is now, then flies its copy; it leaves the body a
	-- moment later)
	fx:FireAllClients("Throw", id, origin, vel, g, def.id, skinId, c, thing, how.look)
	Sounds.play(WHOOSH, head, {Volume = 0.6, Speed = kind == "shield" and 0.9 or 1.2, MaxDistance = 80, Ttl = 2})
	fly(c, rec, origin, vel, g)
	task.spawn(function()
		RunService.Heartbeat:Wait()
		if not thing.Parent then return end
		if kind == "shield" then
			-- off the arm: the guard, the cone, the bash all go with it (Shields.unwear spares the board)
			local grip = handle:FindFirstChild("ShieldGrip")
			if grip then grip:Destroy() end
			thing.Name = "ThrownShield"
			thing.Parent = folder()
			shields().unwear(c)
		else
			local hum = humOf(c)
			c:SetAttribute("Blocking", false)
			if hum and thing.Parent == c then hum:UnequipTools() end
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("JointInstance") and ((d.Part0 and d.Part0:IsDescendantOf(thing)) or (d.Part1 and d.Part1:IsDescendantOf(thing))) then d:Destroy() end
			end
			thing:SetAttribute("Dropped", true)   -- (in flight: nobody's, and every sweep looks past it)
			thing.Parent = folder()
			-- (the other weapon comes to hand)
			local bp = plr and plr:FindFirstChild("Backpack")
			if bp and hum then
				task.delay(0.35, function()
					if hum.Health <= 0 or c:FindFirstChildOfClass("Tool") then return end
					for _, t in ipairs(bp:GetChildren()) do
						if t:IsA("Tool") and not t:GetAttribute("TwinHidden") then hum:EquipTool(t); break end
					end
				end)
			end
		end
		park(thing, handle, seq)
	end)
	return true
end

--------------------------------------------------------------------
--  HELD TO AIM
--------------------------------------------------------------------
local function stopAim(c, s)
	if s then s.aimAt = nil end
	c:SetAttribute("HurlAiming", nil)
	if not c:GetAttribute("Throwable") or c:GetAttribute("HurlOwnsAim") then c:SetAttribute("ThrowAiming", nil) end
	c:SetAttribute("HurlOwnsAim", nil)
	c:SetAttribute("SpeedMult_Hurl", nil)
end
function Hurl.cancel(c) stopAim(c, state[c]) end
function Hurl.aim(c)
	local ok, why = allowed(c)
	if not ok then return false, why end
	local kind, _, _, how = Hurl.what(c)
	if not kind then return false, "nothing to throw: a shield, or a one-handed weapon in your hand" end
	if c:GetAttribute("ThrowAiming") and not c:GetAttribute("HurlOwnsAim") then return false, "" end
	local s = state[c] or {}
	state[c] = s
	if os.clock() < (s.nextAt or 0) then return false, "" end
	s.aimAt = os.clock()
	s.windup = how.windup or 0.4
	s.token = (s.token or 0) + 1
	local token = s.token
	c:SetAttribute("HurlAiming", kind)
	-- (the arm drawn back on every screen: the throwables' pose, Powers.client)
	c:SetAttribute("ThrowAiming", true)
	c:SetAttribute("HurlOwnsAim", true)
	c:SetAttribute("SpeedMult_Hurl", AIM_SLOW)
	task.delay(AIM_MAX, function() if s.token == token and s.aimAt then stopAim(c, s) end end)
	return true
end
function Hurl.release(c, aim)
	local s = state[c]
	if not (s and s.aimAt) then
		local ok, why = Hurl.aim(c)
		if not ok then return false, why end
		s = state[c]
	end
	local token = s.token
	local left = s.aimAt + (s.windup or 0.4) - os.clock()
	local function go()
		if s.token ~= token or not s.aimAt or not c.Parent then return end
		stopAim(c, s)
		local ok, why = Hurl.throw(c, aim)
		if not ok and why and why ~= "" then
			local plr = Players:GetPlayerFromCharacter(c)
			local remote = ReplicatedStorage:FindFirstChild("PowerRemote")
			if plr and remote then remote:FireClient(plr, "Denied", why, "hurl") end
		end
	end
	if left > 0.01 then task.delay(left, go) else go() end
	return true
end

return Hurl
