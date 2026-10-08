--[[ MAGIC SERVER — a staff's server side (Tools ▸ Staff ▸ Server calls
     MagicServer.attach(Tool, Config)). The client only asks; here every cast is
     timed, paid for and resolved (ReplicatedStorage ▸ MagicSpells):

       Tool.MagicRemote (client → server)
         "Cast", spellId, aimPoint   start casting (mana, cooldown, alive, not warding)
         "Aim", aimPoint             where it goes off (the crosshair at the end of the cast)
         "Cancel"                    a feint: the cast is dropped, nothing paid
         "Ward", on                  raise / lower the ward (frontal blows soak into mana: Ward)
         "Kick"                      the kick (CombatServer.resolveKick)
       ReplicatedStorage.MagicFXRemote (server → every client: ReplicatedStorage ▸ MagicFX draws it)
         "Bolt", id, origin, dir, speed, spellId, range, caster · "Impact", id, pos, spellId, fizzled
         "Chain", spellId, points, caster · "Nova", spellId, pos, radius · "Heal", spellId, character, time
         (the caster: each screen starts the spell at the orb it sees, the pose being its own)
         "Fizzle", character

     While casting the character carries Casting = spellId, CastStart (server
     time) and CastTime (everyone's MagicFX draws the circle), and walks slower
     (SpeedMult_Cast). A hit while casting breaks the cast (nothing paid).
     Mana (attributes Mana / MaxMana, set at spawn for a magic class) comes back
     MAGIC.MANA_REGEN a second once REGEN_DELAY has passed since the last cast,
     never while warding. Spells respect friendly fire, peaceful places, spawn
     protection, and half the target's armor; a ward soaks them like a blade. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local Ward = require(script.Parent:WaitForChild("Ward"))
local Ragdoll = require(script.Parent:WaitForChild("Ragdoll"))

local MagicServer = {}

local fx = ReplicatedStorage:FindFirstChild("MagicFXRemote")
if not fx then fx = Instance.new("RemoteEvent"); fx.Name = "MagicFXRemote"; fx.Parent = ReplicatedStorage end

--------------------------------------------------------------------
--  MANA (every character that has some)
--------------------------------------------------------------------
local lastCast = setmetatable({}, {__mode = "k"})
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then return end
	local step = acc
	acc = 0
	local now = os.clock()
	for _, plr in ipairs(Players:GetPlayers()) do
		local c = plr.Character
		local max = c and c:GetAttribute("MaxMana")
		if max then
			local m = c:GetAttribute("Mana") or max
			if m < max and not c:GetAttribute("Warded") and now - (lastCast[c] or 0) > Spells.REGEN_DELAY then
				c:SetAttribute("Mana", math.min(max, m + Spells.MANA_REGEN * step))
			end
		end
	end
end)

--------------------------------------------------------------------
--  HURTING, HEALING, BURNING, CHILLING
--------------------------------------------------------------------
local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function alive(m) local h = humOf(m); return h ~= nil and h.Health > 0 end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end

-- may `caster` hurt `target` at all, and by how much (friendly fire)
local function hurtMult(caster, target)
	if target == caster or not alive(target) then return 0 end
	if CombatServer.peaceful(caster, target) or CombatServer.isProtected(target) or CombatServer.botFriends(caster, target) then return 0 end
	return CombatServer.friendlyMult(caster, target)
end
local function hurt(caster, target, dmg, spellName, head)
	local mult = hurtMult(caster, target)
	if mult <= 0 then return false end
	dmg *= mult
	-- armor turns half of what it would turn from a blade
	dmg *= 1 - 0.5 * math.clamp(target:GetAttribute("ArmorProtection") or 0, 0, 0.9)
	dmg = Ward.scale(target, caster, dmg)
	if dmg <= 0.05 then return true end
	local h = humOf(target)
	local lethal = dmg >= h.Health
	CombatServer.credit(target, caster, spellName, "Spell")
	CombatServer.markCombat(target); CombatServer.markCombat(caster)
	local r, cr = rootOf(target), rootOf(caster)
	if r and cr then CombatServer.flinch(target, (r.Position - cr.Position).Unit) end
	CombatServer.showDamage(caster, target, dmg, head and "head" or nil, lethal, mult < 1)
	h:TakeDamage(dmg)
	return true
end

-- a burn: dps for `time` seconds (a fresh burn restarts it)
local function burn(caster, target, b, spellName)
	if hurtMult(caster, target) <= 0 then return end
	local token = (target:GetAttribute("BurnToken") or 0) + 1
	target:SetAttribute("BurnToken", token)
	target:SetAttribute("Burning", true)
	task.spawn(function()
		local t = 0
		while t < b.time and target.Parent and alive(target) and target:GetAttribute("BurnToken") == token do
			task.wait(0.5); t += 0.5
			hurt(caster, target, b.dps * 0.5, spellName)
		end
		if target:GetAttribute("BurnToken") == token then target:SetAttribute("Burning", nil) end
	end)
end

-- a chill: slower for a while (SpeedMult_Frost, the Frosted attribute for the look)
local function chill(caster, target, slow, time)
	if hurtMult(caster, target) <= 0 then return end
	local token = (target:GetAttribute("FrostToken") or 0) + 1
	target:SetAttribute("FrostToken", token)
	target:SetAttribute("SpeedMult_Frost", 1 - slow)
	target:SetAttribute("Frosted", true)
	task.delay(time, function()
		if target:GetAttribute("FrostToken") ~= token then return end
		target:SetAttribute("SpeedMult_Frost", nil)
		target:SetAttribute("Frosted", nil)
	end)
end

-- a heal over time: you, or an ally (same team; in a free-for-all only you)
local function friendly(caster, target)
	if target == caster then return true end
	local t = caster:GetAttribute("Team")
	return t ~= nil and t ~= "" and t == target:GetAttribute("Team")
end
local function heal(target, amount, time)
	local h = humOf(target)
	if not h then return end
	task.spawn(function()
		local ticks = math.max(1, math.floor(time / 0.25))
		for _ = 1, ticks do
			if not (target.Parent and h.Health > 0) then return end
			h.Health = math.min(h.MaxHealth, h.Health + amount / ticks)
			task.wait(0.25)
		end
	end)
end

-- every character that might be hit: players and the NPC folder
local function everyone()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(out, p.Character) end end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do if m:IsA("Model") and humOf(m) then table.insert(out, m) end end end
	return out
end
local function modelOfPart(part)
	local m = part and part:FindFirstAncestorOfClass("Model")
	while m and not humOf(m) do m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model") end
	return m
end

--------------------------------------------------------------------
--  THE SPELLS
--------------------------------------------------------------------
local boltN = 0
local function castParams(caster)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {caster}
	for _, n in ipairs({"DroppedWeapons", "LocalFX", "EmoteFX", "ThrownHelmets"}) do local f = workspace:FindFirstChild(n); if f then table.insert(ex, f) end end
	p.FilterDescendantsInstances = ex
	p.IgnoreWater = true
	return p
end

local RESOLVE = {}

-- a bolt flies, the server sweeping a sphere along it; it bursts on the first thing it meets
function RESOLVE.bolt(caster, sp, spellId, origin, dir)
	boltN += 1
	local id = boltN
	fx:FireAllClients("Bolt", id, origin, dir, sp.speed, spellId, sp.range, caster)
	local params = castParams(caster)
	local pos, travelled = origin, 0
	local conn
	local function burst(at, hitPart)
		conn:Disconnect()
		local direct = hitPart and modelOfPart(hitPart)
		if direct and humOf(direct) then
			if hurt(caster, direct, sp.damage * ((hitPart.Name == "Head") and (sp.headMult or 1) or 1), sp.name, hitPart.Name == "Head") and sp.burn then
				burn(caster, direct, sp.burn, sp.name)
			end
		end
		if sp.splash then
			for _, m in ipairs(everyone()) do
				local r = rootOf(m)
				if m ~= direct and m ~= caster and r and (r.Position - at).Magnitude <= sp.splash then hurt(caster, m, sp.splashDamage or 0, sp.name) end
			end
		end
		fx:FireAllClients("Impact", id, at, spellId, false)
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		local step = math.min(sp.speed * dt, sp.range - travelled)
		local res = workspace:Spherecast(pos, sp.radius or 0.6, dir * step, params)
		if res then burst(res.Position, res.Instance); return end
		pos += dir * step
		travelled += step
		if travelled >= sp.range - 0.01 then
			conn:Disconnect()
			fx:FireAllClients("Impact", id, pos, spellId, true)
		end
	end)
end

-- lightning: a fat ray to the first one in the way, then a leap to the nearest other
function RESOLVE.chain(caster, sp, spellId, origin, dir)
	local params = castParams(caster)
	local res = workspace:Spherecast(origin, (sp.width or 1.4) / 2, dir * sp.range, params)
	local points = {origin}
	local first = res and modelOfPart(res.Instance)
	if first and humOf(first) and first ~= caster then
		local r = rootOf(first)
		table.insert(points, (r and r.Position) or res.Position)
		hurt(caster, first, sp.damage, sp.name, res.Instance.Name == "Head")
		CombatServer.interrupt(first, "lightning")
		local hit = {[first] = true}
		local from = points[#points]
		for _ = 1, sp.chain or 0 do
			local best, bestD = nil, sp.chainRange or 12
			for _, m in ipairs(everyone()) do
				local mr = rootOf(m)
				if not hit[m] and m ~= caster and mr and alive(m) and hurtMult(caster, m) > 0 then
					local d = (mr.Position - from).Magnitude
					if d < bestD then best, bestD = m, d end
				end
			end
			if not best then break end
			hit[best] = true
			from = rootOf(best).Position
			table.insert(points, from)
			hurt(caster, best, sp.chainDamage or sp.damage, sp.name)
		end
	else
		table.insert(points, res and res.Position or (origin + dir * sp.range))
	end
	fx:FireAllClients("Chain", spellId, points, caster)
end

-- a nova: everyone in the radius round you, hurt and chilled
function RESOLVE.nova(caster, sp, spellId)
	local r0 = rootOf(caster)
	if not r0 then return end
	for _, m in ipairs(everyone()) do
		local r = rootOf(m)
		if m ~= caster and r and (r.Position - r0.Position).Magnitude <= sp.radius then
			if hurt(caster, m, sp.damage, sp.name) then chill(caster, m, sp.slow or 0.4, sp.slowTime or 2) end
		end
	end
	fx:FireAllClients("Nova", spellId, r0.Position - Vector3.new(0, 2.8, 0), sp.radius)
end

-- a heal: the ally under the crosshair, else you
function RESOLVE.heal(caster, sp, spellId, origin, dir)
	local params = castParams(caster)
	local res = workspace:Spherecast(origin, (sp.width or 2) / 2, dir * (sp.range or 40), params)
	local who = res and modelOfPart(res.Instance)
	if not (who and humOf(who) and alive(who) and friendly(caster, who)) then who = caster end
	heal(who, sp.heal, sp.healTime or 2)
	fx:FireAllClients("Heal", spellId, who, sp.healTime or 2)
end

--------------------------------------------------------------------
--  A STAFF
--------------------------------------------------------------------
function MagicServer.attach(tool, cfg)
	cfg = cfg or {}
	local remote = Instance.new("RemoteEvent")
	remote.Name = "MagicRemote"
	remote.Parent = tool
	if cfg.GRIP then tool.Grip = cfg.GRIP end
	tool:SetAttribute("Magic", true)   -- (RangedFX takes Roblox's arm animations off: the staff's stance is RigPose's)
	-- where spells leave from: an attachment on the orb (everyone's MagicFX reads it too)
	task.spawn(function()
		local handle = tool:WaitForChild("Handle", 15)
		if handle and cfg.ORB and not handle:FindFirstChild("TrailTip") then
			local a = Instance.new("Attachment"); a.Name = "TrailTip"; a.Position = cfg.ORB; a.Parent = handle
		end
	end)
	local book = {}
	for _, id in ipairs(cfg.SPELLS or Spells.ORDER) do if Spells[id] then book[id] = true end end
	local cooldown = {}
	local casting = nil   -- {id, token, aim, char}
	local token = 0
	local lastKick = 0

	local function holder()
		local c = tool.Parent
		return (c and humOf(c)) and c or nil
	end
	local function playerOf(c) return c and Players:GetPlayerFromCharacter(c) end
	local function incapacitated(c)
		return not alive(c) or (c:GetAttribute("StunnedUntil") or 0) > os.clock() or Ragdoll.isRagdolled(c)
	end
	local function clearCast(c)
		if c then
			for _, a in ipairs({"Casting", "CastStart", "CastTime", "SpeedMult_Cast"}) do c:SetAttribute(a, nil) end
			c:SetAttribute("Acting", nil)
		end
		casting = nil
	end
	local function cancel(c, why)
		if not casting then return end
		token += 1
		clearCast(c)
		if why then fx:FireAllClients("Fizzle", c) end
	end
	-- the origin: where the orb is in the casting stance (RigPose.staff), in the body's frame
	-- (the server doesn't see the stance: the pose is drawn on each screen, which starts the
	-- spell at the orb it sees, MagicFX)
	local castFrom = cfg.CAST_FROM or Vector3.new(1, 2, -2.1)
	local function originOf(c)
		local r = rootOf(c)
		return r and (r.CFrame * castFrom) or c:GetPivot().Position
	end

	local function release(c, myToken)
		if not casting or casting.token ~= myToken or holder() ~= c or incapacitated(c) then return end
		local id = casting.id
		local sp = Spells[id]
		local mana = c:GetAttribute("Mana") or 0
		if mana < sp.mana then cancel(c, true); return end
		c:SetAttribute("Mana", mana - sp.mana)
		lastCast[c] = os.clock()
		cooldown[id] = os.clock() + (sp.cooldown or 0)
		local origin = originOf(c)
		local aim = casting.aim
		local dir = (typeof(aim) == "Vector3" and (aim - origin).Magnitude > 0.5) and (aim - origin).Unit or (rootOf(c) and rootOf(c).CFrame.LookVector or Vector3.zAxis)
		clearCast(c)
		local fn = RESOLVE[sp.kind]
		if fn then task.spawn(fn, c, sp, id, origin, dir) end
		remote:FireClient(playerOf(c), "Cast", id, cooldown[id] - os.clock())
	end

	remote.OnServerEvent:Connect(function(plr, what, a)
		local c = holder()
		if not c or playerOf(c) ~= plr then return end
		if what == "Cast" then
			local sp = type(a) == "string" and book[a] and Spells[a]
			if not sp or casting or incapacitated(c) or c:GetAttribute("Warded") then return end
			if os.clock() < (cooldown[a] or 0) then return end
			if (c:GetAttribute("Mana") or 0) < sp.mana then remote:FireClient(plr, "NoMana", a); return end
			token += 1
			local myToken = token
			casting = {id = a, token = myToken}
			c:SetAttribute("Casting", a)
			c:SetAttribute("CastStart", workspace:GetServerTimeNow())
			c:SetAttribute("CastTime", sp.cast)
			c:SetAttribute("SpeedMult_Cast", Spells.CAST_WALK)
			c:SetAttribute("Acting", true)
			lastCast[c] = os.clock()
			-- a hit while casting breaks it
			local h = humOf(c)
			local hp = h.Health
			local hc
			hc = h.HealthChanged:Connect(function(new)
				if not casting or casting.token ~= myToken then hc:Disconnect(); return end
				if new < hp - 0.5 then hc:Disconnect(); cancel(c, true) end
				hp = new
			end)
			task.delay(sp.cast + 0.06, function()
				if hc.Connected then hc:Disconnect() end
				release(c, myToken)
			end)
		elseif what == "Aim" then
			if casting and typeof(a) == "Vector3" then casting.aim = a end
		elseif what == "Cancel" then
			cancel(c, false)
		elseif what == "Ward" then
			local on = a == true and not casting and (c:GetAttribute("Mana") or 0) > 4 and not incapacitated(c)
			c:SetAttribute("Warded", on or nil)
			c:SetAttribute("SpeedMult_Ward", on and Spells.WARD.walk or nil)
		elseif what == "Kick" then
			local now = os.clock()
			if casting or now - lastKick < 1.2 then return end
			lastKick = now
			local kcfg = setmetatable({}, {__index = CombatServer.DEFAULTS})
			CombatServer.resolveKick(c, kcfg, {weaponName = tool.Name, tell = function(...) remote:FireClient(plr, ...) end})
		end
	end)

	-- put away, dropped, dead: nothing stays raised or half-cast
	local owner = nil
	tool.Equipped:Connect(function() owner = holder() end)
	tool.Unequipped:Connect(function()
		token += 1
		if owner then
			clearCast(owner)
			owner:SetAttribute("Warded", nil)
			owner:SetAttribute("SpeedMult_Ward", nil)
		end
		casting = nil
		owner = nil
	end)
end

return MagicServer
