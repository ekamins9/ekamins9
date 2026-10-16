--[[ THROWING — the throwables (Catalog ▸ Arsenal: knives, axes, darts, a javelin, bombs,
     flasks, caltrops, bolas, holy water): every class carries one, on its own key (Throw, C).
     HELD TO AIM: press and the arm draws back (a wind-up, Catalog.throwWindup: knives quick, a
     javelin slow; you walk slower meanwhile), the client draws the
     arc and where it lands; let go and it flies — at once if the wind-up is done, else the
     moment it is. Combat ▸ Powers passes the asks on; here it's timed, flown (on an arc, the
     server's own flight) and resolved: a hit (a shield raised toward it stops it: Combat ▸
     Shields), a root, a burst where it lands (a pool of fire, frost, smoke, caltrops:
     Powers.zoneAt).

       Throwing.equip(character, id, skinId)   full charges (Throwable, ThrowSkin, ThrowCharges,
                                               ThrowMax, ThrowNextAt for the HUD)
       Throwing.aim(character) -> ok, why      the wind-up (ThrowAiming, ThrowWindup,
                                               SpeedMult_Throw)
       Throwing.release(character, aimPoint)   let go: thrown when the wind-up's done
       Throwing.cancel(character)
       Throwing.throw(character, aimPoint) -> ok, why   (straight away: no wind-up)
     ThrowFX (server → every screen): "Throw", shotId, origin, velocity, gravity, weaponId,
     skinId, thrower · "Land", shotId, pos, stuckIn (a part or nil) ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Ballistics = require(ReplicatedStorage:WaitForChild("Ballistics"))
local Sounds = require(ReplicatedStorage:WaitForChild("Sounds"))
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local MagicServer = require(script.Parent:WaitForChild("MagicServer"))
local Injury = require(script.Parent:WaitForChild("Injury"))

local Throwing = {}
local fx = ReplicatedStorage:FindFirstChild("ThrowFX")
if not fx then fx = Instance.new("RemoteEvent"); fx.Name = "ThrowFX"; fx.Parent = ReplicatedStorage end

local function now() return workspace:GetServerTimeNow() end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local state = setmetatable({}, {__mode = "k"})
local seq = 0
local WHOOSH = "rbxassetid://9120709477"   -- (the menus' whoosh: something leaving the hand)
local Powers, Shields
local function powers() Powers = Powers or require(script.Parent:WaitForChild("Powers")); return Powers end
local function shields() Shields = Shields or require(script.Parent:WaitForChild("Shields")); return Shields end

-- the wind-up before it can leave the hand (Catalog.throwWindup: by how it's thrown, or the
-- def's own `windup`)
local AIM_SLOW = 0.8     -- (walking while you aim)
local AIM_MAX = 10       -- (held longer than this: put away)
function Throwing.windupOf(def) return Catalog.throwWindup(def) end

local function publish(c, s)
	c:SetAttribute("ThrowCharges", s.charges)
	c:SetAttribute("ThrowNextAt", s.charges < s.def.charges and s.nextCharge or nil)
end

function Throwing.equip(c, id, skin)
	local def = Catalog.WEAPON[id or ""]
	if not (def and def.throwable) then return end
	local s = {def = def, skin = skin, charges = def.charges or 1, nextCharge = 0, nextThrow = 0}
	state[c] = s
	c:SetAttribute("Throwable", def.id); c:SetAttribute("ThrowSkin", skin)
	c:SetAttribute("ThrowMax", def.charges or 1)
	publish(c, s)
end

-- what a throw does where it lands
local function burst(c, s, at)
	local b = s.def.burst
	if not b then return end
	local ctx = {spellId = nil, skin = s.skin, name = s.def.name}
	if (b.time or 0) <= 0 then
		-- at once (holy water): your side healed, foes scalded
		for _, m in ipairs(MagicServer.everyone()) do
			local r = rootOf(m)
			if r and (r.Position - at).Magnitude <= b.radius and MagicServer.alive(m) then
				if MagicServer.friendly(c, m) then
					if b.heal then MagicServer.heal(m, b.heal, 2) end
				elseif b.holyDamage then MagicServer.hurt(c, m, b.holyDamage, s.def.name) end
			end
		end
		powers().fx:FireAllClients("Zone", s.def.id, at, b.radius, 0.6, 0, {heal = true, holy = true}, nil, s.skin)
		return
	end
	powers().zoneAt(c, at, {id = s.def.id, name = s.def.name, radius = b.radius, time = b.time, smoke = b.smoke,
		fire = b.fire, frost = b.frost, ground = b.ground,
		foes = {dps = b.dps, slow = b.slow}}, ctx)
end

local function land(c, s, id, res, vel)
	local def = s.def
	local part = res and res.Instance
	local pos = res and res.Position
	local model = part and part:FindFirstAncestorOfClass("Model")
	local hum = model and humOf(model)
	while model and not hum do
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
		hum = model and humOf(model)
	end
	local stuck = nil
	if model and hum and hum.Health > 0 and model ~= c then
		local dir = vel.Magnitude > 0 and vel.Unit or Vector3.zAxis
		if shields().stops(model, pos - dir * 6) then
			-- on the shield: it bounces off (a flask still breaks)
			Injury.sparks(pos, 0.8)
			Sounds.bank("Block", part)
			model:SetAttribute("GuardText", "SHIELD")
			model:SetAttribute("GuardTick", (model:GetAttribute("GuardTick") or 0) + 1)
		else
			local head = part.Name == "Head"
			local dmg = (def.damage or 0) * (head and (def.headMult or 1) or 1)
			-- (a javelin's point goes through armour: the half that MagicServer's hurt would let
			-- armour turn, less its pierce)
			if def.pierce then dmg *= 1 + 0.5 * math.clamp(model:GetAttribute("ArmorProtection") or 0, 0, 0.9) * def.pierce end
			if dmg > 0 and MagicServer.hurt(c, model, dmg, def.name, head) then
				CombatServer.interrupt(model, "hit")
				Sounds.bank("HitStab", part)
				if head and c.Parent then
					c:SetAttribute("GuardText", "HEADSHOT"); c:SetAttribute("GuardTick", (c:GetAttribute("GuardTick") or 0) + 1)
				end
			end
			if def.snare then powers().snare(c, model, def.snare) end
			if def.look == "blade" or def.look == "axe" or def.look == "spear" or def.look == "dart" then stuck = part end
		end
	elseif part then
		local fam = CombatServer.wallFamily(res.Material and res.Material.Name or "") or "Ground"
		if fam == "Ground" or fam == "Wood" then
			if def.look == "blade" or def.look == "axe" or def.look == "spear" or def.look == "dart" then stuck = part end
		end
	end
	fx:FireAllClients("Land", id, pos, stuck)
	if pos then burst(c, s, pos) end
end

function Throwing.throw(c, aim)
	local s = state[c]
	if not s then return false, "nothing to throw" end
	local def = s.def
	local t = now()
	if os.clock() < s.nextThrow then return false, "" end
	if s.charges <= 0 then return false, string.format("%s: the next one's back in %d", def.name, math.ceil(s.nextCharge - t)) end
	local head, r = c:FindFirstChild("Head"), rootOf(c)
	if not (head and r) then return false, "" end
	s.charges -= 1
	if s.charges == def.charges - 1 or s.nextCharge < t then s.nextCharge = t + (def.recharge or 15) end
	s.nextThrow = os.clock() + (def.gap or 0.6)
	publish(c, s)
	c:SetAttribute("ThrowTick", (c:GetAttribute("ThrowTick") or 0) + 1)
	local g, speed = def.gravity or 40, def.speed or 90
	local dir, origin
	if typeof(aim) == "Vector3" and (aim - head.Position).Magnitude > 3 then
		dir, origin = Ballistics.launch(head.Position, aim, speed, g)
	end
	-- (the aim must be roughly where you face)
	local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
	if not dir or (look.Magnitude > 0.1 and Vector3.new(dir.X, 0, dir.Z).Magnitude > 0.1 and look.Unit:Dot(Vector3.new(dir.X, 0, dir.Z).Unit) < 0.5) then
		dir = (look.Unit + Vector3.new(0, 0.15, 0)).Unit
		origin = nil
	end
	origin = origin or (head.Position + dir * 1.2)
	local vel = dir * speed
	seq += 1
	local plr = Players:GetPlayerFromCharacter(c)
	local id = (plr and plr.UserId or 0) .. ":t" .. seq
	fx:FireAllClients("Throw", id, origin, vel, g, def.id, s.skin, c)
	Sounds.play(WHOOSH, head, {Volume = 0.5, Speed = 1.5, MaxDistance = 70, Ttl = 2})
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {c}
	for _, n in ipairs({"StuckArrows", "MagicFX", "DroppedWeapons"}) do local f = workspace:FindFirstChild(n); if f then table.insert(ignore, f) end end
	params.FilterDescendantsInstances = ignore
	local pos, t0 = origin, os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local nextVel = vel - Vector3.new(0, g * dt, 0)
		local step = (vel + nextVel) * 0.5 * dt
		local res = workspace:Spherecast(pos, 0.35, step, params)
		if res then
			conn:Disconnect()
			local ok, err = pcall(land, c, s, id, res, vel)
			if not ok then warn("[Throwing]", err) end
			return
		end
		pos += step
		vel = nextVel
		if os.clock() - t0 > 6 or pos.Y < -200 then conn:Disconnect(); fx:FireAllClients("Land", id, nil, nil) end
	end)
	return true
end

local function stopAim(c, s)
	if s then s.aimAt = nil end
	c:SetAttribute("ThrowAiming", nil)
	c:SetAttribute("SpeedMult_Throw", nil)
end
function Throwing.cancel(c)
	stopAim(c, state[c])
end
function Throwing.aim(c)
	local s = state[c]
	if not s then return false, "no throwable: CLASSES › THROWABLE" end
	if s.charges <= 0 then return false, string.format("%s: the next one's back in %d", s.def.name, math.ceil(s.nextCharge - now())) end
	if os.clock() < s.nextThrow then return false, "" end
	if (c:GetAttribute("StunnedUntil") or 0) > os.clock() then return false, "" end
	s.aimAt = os.clock()
	s.aimToken = (s.aimToken or 0) + 1
	local token = s.aimToken
	c:SetAttribute("ThrowWindup", Throwing.windupOf(s.def))
	c:SetAttribute("ThrowAiming", true)
	c:SetAttribute("SpeedMult_Throw", AIM_SLOW)
	task.delay(AIM_MAX, function() if s.aimToken == token and s.aimAt then stopAim(c, s) end end)
	return true
end
function Throwing.release(c, aim)
	local s = state[c]
	if not s then return false, "" end
	-- (no wind-up seen: a tap, or an old client: it starts now)
	if not s.aimAt then
		local ok, why = Throwing.aim(c)
		if not ok then return false, why end
	end
	local token = s.aimToken
	local left = s.aimAt + Throwing.windupOf(s.def) - os.clock()
	local function go()
		if s.aimToken ~= token or not s.aimAt or not c.Parent then return end
		stopAim(c, s)
		if (c:GetAttribute("StunnedUntil") or 0) > os.clock() or c:GetAttribute("Ragdolled") then return end
		Throwing.throw(c, aim)
	end
	if left > 0.01 then task.delay(left, go) else go() end
	return true
end

-- charges come back one at a time
RunService.Heartbeat:Connect(function()
	local t = now()
	for c, s in pairs(state) do
		if not c.Parent then state[c] = nil
		elseif s.charges < s.def.charges and t >= s.nextCharge then
			s.charges += 1
			s.nextCharge = t + (s.def.recharge or 15)
			publish(c, s)
		end
	end
end)

return Throwing
