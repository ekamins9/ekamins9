--[[ MAGIC SERVER — a magic weapon's server side (Tools ▸ Staff / Tome / Wand ▸ Server
     calls MagicServer.attach(Tool, Config)). The client only asks; here every cast
     is timed, paid for and resolved (ReplicatedStorage ▸ MagicSpells).

     THE WEAPON (its Config): SLOTS (how many spells it carries), WAND (it carries wand
     spells, and only those: MagicSpells wand = true), POWER (× every spell's damage and healing),
     CAST_MULT (× cast times), MANA_MULT (× costs), WALK (× MagicSpells.CAST_WALK: how
     fast you walk while casting), WARD (the right mouse soaks frontal blows into
     mana), STANCE (RigPose: 3 staff, 4 tome, 5 wand), TWIN (a Staff's melee self:
     LoadoutServer swaps them on the Stance bind). The arsenal is the Tool's Spells
     attribute (LoadoutServer, from the class loadout; Profile.validateLoadout checks
     it), their looks SpellSkins ("Firebolt=Dragonfire,…": Catalog ▸ SpellSkins).

       Tool.MagicRemote (client → server)
         "Cast", spellId, aimPoint   start casting (mana, cooldown, alive, not warding)
         "Aim", aimPoint             where it goes (the crosshair at the end of the cast)
         "Cancel"                    a feint: the cast is dropped, nothing paid
         "Ward", on                  raise / lower the ward (a Staff)
         "Meditate", on              stand still and breathe: mana comes back
         "Kick"                      the kick (CombatServer.resolveKick)
       ReplicatedStorage.MagicFXRemote (server → every client: ReplicatedStorage ▸ MagicFX)
         "Bolt", id, origin, dir, speed, spellId, range, caster, skin, seekTarget
         "Impact", id, pos, spellId, fizzled, skin
         "Chain", spellId, points, caster, skin · "Nova", spellId, pos, radius, skin
         "Heal", spellId, character, time, skin · "Meteor", spellId, pos, radius, delay, skin
         "Cloud", spellId, pos, radius, time, skin · "Buff", spellId, character, buff, time, skin
         "Hex", spellId, from, target (a character or a point), time, skin · "Blink", spellId, from, to, skin
         "Fizzle", character
         (the caster: each screen starts the spell at the orb it sees, the pose being its own)

     While casting the character carries Casting = spellId, CastStart (server time)
     and CastTime (everyone's MagicFX draws the circle and lifts the staff), walks at
     a crawl (SpeedMult_Cast) and can't sprint (Acting). A hit while casting breaks it
     (nothing paid). Mana (Mana / MaxMana, full at spawn for a magic class) comes back
     ONLY by meditating (Meditating, MeditateStart; MagicSpells.MEDITATE). Spells
     respect friendly fire, peaceful places, spawn protection, and half the target's
     armor; every hurt goes through Combat ▸ Ward (wards, barriers, hexes). ]]

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

local function now() return workspace:GetServerTimeNow() end
local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function alive(m) local h = humOf(m); return h ~= nil and h.Health > 0 end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end

--------------------------------------------------------------------
--  EVERYONE WHO MIGHT BE HIT
--------------------------------------------------------------------
local function everyone()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(out, p.Character) end end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do if m:IsA("Model") and humOf(m) then table.insert(out, m) end end end
	return out
end
MagicServer.everyone = everyone
local function modelOfPart(part)
	local m = part and part:FindFirstAncestorOfClass("Model")
	while m and not humOf(m) do m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model") end
	return m
end
local function castParams(caster)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {caster}
	for _, n in ipairs({"DroppedWeapons", "LocalFX", "EmoteFX", "ThrownHelmets", "MagicFX", "ArmorFXLocal"}) do local f = workspace:FindFirstChild(n); if f then table.insert(ex, f) end end
	p.FilterDescendantsInstances = ex
	p.IgnoreWater = true
	return p
end

--------------------------------------------------------------------
--  HURTING, HEALING, BURNING, CHILLING
--------------------------------------------------------------------
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
	target:SetAttribute("LastHitAttack", "Spell")   -- (no blade's attack: the training yard tells them apart)
	CombatServer.markCombat(target); CombatServer.markCombat(caster)
	local r, cr = rootOf(target), rootOf(caster)
	if r and cr and (r.Position - cr.Position).Magnitude > 0.1 then CombatServer.flinch(target, (r.Position - cr.Position).Unit) end
	CombatServer.showDamage(caster, target, dmg, head and "head" or nil, lethal, mult < 1)
	h:TakeDamage(dmg)
	return true
end
MagicServer.hurt = hurt
MagicServer.hurtMult = hurtMult

-- a shove: thrown along `vel` for a moment (a held push: a walking body shrugs off a single
-- change of velocity, and the push is simulated wherever the body is, a player's screen too)
local function shove(m, vel)
	local r = rootOf(m)
	if not r then return end
	local att = Instance.new("Attachment"); att.Name = "Shove"; att.Parent = r
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att; lv.MaxForce = 4e5; lv.VectorVelocity = vel
	lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = r
	task.delay(0.22, function() lv:Destroy(); att:Destroy() end)
end

-- a burn: dps for `time` seconds (a fresh burn restarts it)
local function burn(caster, target, b, spellName, power)
	if hurtMult(caster, target) <= 0 then return end
	local token = (target:GetAttribute("BurnToken") or 0) + 1
	target:SetAttribute("BurnToken", token)
	target:SetAttribute("Burning", true)
	task.spawn(function()
		local t = 0
		while t < b.time and target.Parent and alive(target) and target:GetAttribute("BurnToken") == token do
			task.wait(0.5); t += 0.5
			hurt(caster, target, b.dps * 0.5 * (power or 1), spellName)
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
-- your side (same team; in a free-for-all only you)
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
-- the character a fat ray from origin along dir meets first (or nil), where it stopped
local function rayTo(caster, origin, dir, range, width)
	local res = workspace:Spherecast(origin, (width or 1.4) / 2, dir * range, castParams(caster))
	local m = res and modelOfPart(res.Instance)
	return (m and humOf(m) and m ~= caster) and m or nil, res and res.Position or (origin + dir * range), res
end
-- the ground under a point (for spells that land where you aim)
local function groundAt(caster, p)
	local res = workspace:Raycast(p + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), castParams(caster))
	return res and res.Position or p
end

--------------------------------------------------------------------
--  THE SPELLS: RESOLVE[kind](caster, sp, ctx) — ctx = {id, origin, dir, aim (a point),
--  power, skin}
--------------------------------------------------------------------
local boltN = 0
local RESOLVE = {}

-- bolts fly, the server sweeping a sphere along each; it bursts on the first thing it meets.
-- count > 1: a fan of them (spread degrees apart); seek: each curves after the target
function RESOLVE.bolt(caster, sp, ctx)
	local params = castParams(caster)
	local seekTarget = nil
	if sp.seek then seekTarget = rayTo(caster, ctx.origin, ctx.dir, sp.range, 4) end
	local n = sp.count or 1
	for k = 1, n do
		boltN += 1
		local id = boltN
		local yaw = n > 1 and math.rad(((k - 1) / (n - 1) - 0.5) * 2 * (sp.spread or 5)) or 0
		local dir = (CFrame.fromAxisAngle(Vector3.yAxis, yaw) * ctx.dir).Unit
		fx:FireAllClients("Bolt", id, ctx.origin, dir, sp.speed, ctx.id, sp.range, caster, ctx.skin, seekTarget)
		local pos, travelled = ctx.origin, 0
		local conn
		local function burst(at, hitPart)
			conn:Disconnect()
			local direct = hitPart and modelOfPart(hitPart)
			if direct and humOf(direct) then
				local head = hitPart.Name == "Head"
				if hurt(caster, direct, sp.damage * ctx.power * (head and (sp.headMult or 1) or 1), sp.name, head) then
					if sp.burn then burn(caster, direct, sp.burn, sp.name, ctx.power) end
					if sp.chill then chill(caster, direct, sp.chill.slow, sp.chill.time) end
				end
			end
			if sp.splash then
				for _, m in ipairs(everyone()) do
					local r = rootOf(m)
					if m ~= direct and m ~= caster and r and (r.Position - at).Magnitude <= sp.splash then hurt(caster, m, (sp.splashDamage or 0) * ctx.power, sp.name) end
				end
			end
			fx:FireAllClients("Impact", id, at, ctx.id, false, ctx.skin)
		end
		conn = RunService.Heartbeat:Connect(function(dt)
			if sp.seek and seekTarget and alive(seekTarget) and rootOf(seekTarget) then
				local want = rootOf(seekTarget).Position - pos
				if want.Magnitude > 1 then dir = dir:Lerp(want.Unit, math.min(1, sp.seek * dt)).Unit end
			end
			local step = math.min(sp.speed * dt, sp.range - travelled)
			local res = workspace:Spherecast(pos, sp.radius or 0.6, dir * step, params)
			if res then burst(res.Position, res.Instance); return end
			pos += dir * step
			travelled += step
			if travelled >= sp.range - 0.01 then
				conn:Disconnect()
				fx:FireAllClients("Impact", id, pos, ctx.id, true, ctx.skin)
			end
		end)
	end
end

-- lightning: a fat ray to the first one in the way, then a leap to the nearest other
function RESOLVE.chain(caster, sp, ctx)
	local first, stop, res = rayTo(caster, ctx.origin, ctx.dir, sp.range, sp.width)
	local points = {ctx.origin}
	if first then
		local r = rootOf(first)
		table.insert(points, (r and r.Position) or stop)
		hurt(caster, first, sp.damage * ctx.power, sp.name, res and res.Instance.Name == "Head")
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
			hurt(caster, best, (sp.chainDamage or sp.damage) * ctx.power, sp.name)
		end
	else
		table.insert(points, stop)
	end
	fx:FireAllClients("Chain", ctx.id, points, caster, ctx.skin)
end

-- a nova: everyone in the radius round you, hurt and chilled
function RESOLVE.nova(caster, sp, ctx)
	local r0 = rootOf(caster)
	if not r0 then return end
	for _, m in ipairs(everyone()) do
		local r = rootOf(m)
		if m ~= caster and r and (r.Position - r0.Position).Magnitude <= sp.radius then
			if sp.shove then
				-- a gust: no harm, just thrown back (foes only)
				if hurtMult(caster, m) > 0 then
					local away = Vector3.new(r.Position.X - r0.Position.X, 0, r.Position.Z - r0.Position.Z)
					if away.Magnitude < 0.1 then away = r0.CFrame.LookVector end
					shove(m, away.Unit * sp.shove + Vector3.new(0, sp.shove * 0.3, 0))
					CombatServer.flinch(m, away.Unit)
					CombatServer.interrupt(m, "hit")
					CombatServer.credit(m, caster, sp.name, "Spell")
				end
			elseif hurt(caster, m, sp.damage * ctx.power, sp.name) then chill(caster, m, sp.slow or 0.4, sp.slowTime or 2) end
		end
	end
	fx:FireAllClients("Nova", ctx.id, r0.Position - Vector3.new(0, 2.8, 0), sp.radius, ctx.skin)
end

-- the ally under the crosshair, else you
local function allyOrSelf(caster, sp, ctx)
	local who = rayTo(caster, ctx.origin, ctx.dir, sp.range or 40, sp.width or 2)
	if not (who and alive(who) and friendly(caster, who)) then who = caster end
	return who
end
function RESOLVE.heal(caster, sp, ctx)
	local who = allyOrSelf(caster, sp, ctx)
	heal(who, sp.heal * ctx.power, sp.healTime or 2)
	fx:FireAllClients("Heal", ctx.id, who, sp.healTime or 2, ctx.skin)
end

-- where you aim, on the ground, within the spell's reach
local function aimedGround(caster, sp, ctx)
	local r0 = rootOf(caster)
	local p = ctx.aim or (ctx.origin + ctx.dir * (sp.range or 40))
	if r0 then
		local flat = Vector3.new(p.X - r0.Position.X, 0, p.Z - r0.Position.Z)
		if flat.Magnitude > (sp.range or 40) then p = r0.Position + flat.Unit * sp.range end
	end
	return groundAt(caster, p)
end
-- a meteor: after a delay; full damage in the middle, less at the edge, a shove away
function RESOLVE.meteor(caster, sp, ctx)
	local at = aimedGround(caster, sp, ctx)
	fx:FireAllClients("Meteor", ctx.id, at, sp.radius, sp.delay, ctx.skin)
	task.delay(sp.delay, function()
		for _, m in ipairs(everyone()) do
			local r = rootOf(m)
			local d = r and (r.Position - at).Magnitude
			if d and d <= sp.radius + 1 and m ~= caster then
				local k = math.clamp(1 - d / sp.radius, 0, 1)
				if hurt(caster, m, (sp.edgeDamage + (sp.damage - sp.edgeDamage) * k) * ctx.power, sp.name) then
					if sp.burn then burn(caster, m, sp.burn, sp.name, ctx.power) end
					local away = (r.Position - at) * Vector3.new(1, 0, 1)
					if away.Magnitude > 0.1 then shove(m, away.Unit * 34 * k + Vector3.new(0, 16 * k, 0)) end
				end
			end
		end
	end)
end

-- a cloud: a zone where you aim; every half second it hurts and slows whoever's in it
function RESOLVE.cloud(caster, sp, ctx)
	local at = aimedGround(caster, sp, ctx)
	fx:FireAllClients("Cloud", ctx.id, at, sp.radius, sp.time, ctx.skin)
	task.spawn(function()
		local t = 0
		while t < sp.time do
			task.wait(0.5); t += 0.5
			for _, m in ipairs(everyone()) do
				local r = rootOf(m)
				if r and m ~= caster and (r.Position - at).Magnitude <= sp.radius then
					if hurt(caster, m, sp.dps * 0.5 * ctx.power, sp.name) and sp.slow then chill(caster, m, sp.slow, 0.7) end
				end
			end
		end
	end)
end

-- a buff on you or the ally aimed at: haste (SpeedMult_Haste) or a barrier (Shield: Combat ▸
-- Ward soaks from it first)
function RESOLVE.buff(caster, sp, ctx)
	local who = allyOrSelf(caster, sp, ctx)
	local untilT = now() + sp.time
	if sp.buff == "haste" then
		who:SetAttribute("SpeedMult_Haste", 1 + sp.amount)
		who:SetAttribute("HasteUntil", untilT)
		task.delay(sp.time, function()
			if (who:GetAttribute("HasteUntil") or 0) <= now() + 0.05 then who:SetAttribute("SpeedMult_Haste", nil); who:SetAttribute("HasteUntil", nil) end
		end)
	elseif sp.buff == "barrier" then
		who:SetAttribute("Shield", sp.amount * ctx.power)
		who:SetAttribute("ShieldUntil", untilT)
		task.delay(sp.time, function()
			if (who:GetAttribute("ShieldUntil") or 0) <= now() + 0.05 then who:SetAttribute("Shield", nil); who:SetAttribute("ShieldUntil", nil) end
		end)
	end
	fx:FireAllClients("Buff", ctx.id, who, sp.buff, sp.time, ctx.skin)
end

-- a hex on whoever you aim at: they deal less and take more for a while (Combat ▸ Ward reads it)
function RESOLVE.hex(caster, sp, ctx)
	local who, stop = rayTo(caster, ctx.origin, ctx.dir, sp.range, sp.width)
	if who and hurtMult(caster, who) > 0 then
		who:SetAttribute("HexUntil", now() + sp.time)
		who:SetAttribute("HexWeaken", sp.weaken)
		who:SetAttribute("HexExpose", sp.expose)
		CombatServer.credit(who, caster, sp.name, "Spell")
	else
		who = nil
	end
	fx:FireAllClients("Hex", ctx.id, ctx.origin, who or stop, sp.time, ctx.skin)
end

-- a blink: up to `distance` where you're looking, stopping short of walls, onto the ground
function RESOLVE.blink(caster, sp, ctx)
	local r = rootOf(caster)
	if not r then return end
	local flat = Vector3.new(ctx.dir.X, 0, ctx.dir.Z)
	if flat.Magnitude < 0.1 then flat = r.CFrame.LookVector * Vector3.new(1, 0, 1) end
	flat = flat.Unit
	local params = castParams(caster)
	local from = r.Position
	local hit = workspace:Spherecast(from, 1.2, flat * sp.distance, params)
	local dist = hit and math.max(0, (hit.Position - from).Magnitude - 1.6) or sp.distance
	local to = from + flat * dist
	local ground = workspace:Raycast(to + Vector3.new(0, 3, 0), Vector3.new(0, -14, 0), params)
	if ground then to = Vector3.new(to.X, ground.Position.Y + 3, to.Z) end
	caster:PivotTo(CFrame.new(to) * (r.CFrame - r.Position))
	fx:FireAllClients("Blink", ctx.id, from, to, ctx.skin)
end

--------------------------------------------------------------------
--  MANA: meditation only (every character that has a mana bar)
--------------------------------------------------------------------
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then return end
	local step = acc
	acc = 0
	local M = Spells.MEDITATE
	for _, c in ipairs(everyone()) do
		local max = c:GetAttribute("MaxMana")
		if max and c:GetAttribute("Meditating") then
			local r = rootOf(c)
			local v = r and r.AssemblyLinearVelocity or Vector3.zero
			local moving = Vector3.new(v.X, 0, v.Z).Magnitude > M.still or math.abs(v.Y) > 6
			if moving or not alive(c) or c:GetAttribute("Casting") or c:GetAttribute("Warded") then
				c:SetAttribute("Meditating", nil); c:SetAttribute("MeditateStart", nil)
			elseif now() - (c:GetAttribute("MeditateStart") or now()) >= M.windup then
				c:SetAttribute("Mana", math.min(max, (c:GetAttribute("Mana") or 0) + M.rate * step))
			end
		elseif max and (Spells.MANA_REGEN or 0) > 0 then
			c:SetAttribute("Mana", math.min(max, (c:GetAttribute("Mana") or max) + Spells.MANA_REGEN * step))
		end
	end
end)

--------------------------------------------------------------------
--  A MAGIC WEAPON
--------------------------------------------------------------------
local function splitList(s)
	local out = {}
	if type(s) == "string" then for x in s:gmatch("[^,]+") do table.insert(out, x) end end
	return out
end
local function skinsOf(s)
	local out = {}
	if type(s) == "string" then for k, v in s:gmatch("([^,=]+)=([^,]+)") do out[k] = v end end
	return out
end
MagicServer.splitList, MagicServer.skinsOf = splitList, skinsOf

function MagicServer.attach(tool, cfg)
	cfg = cfg or {}
	local remote = Instance.new("RemoteEvent")
	remote.Name = "MagicRemote"
	remote.Parent = tool
	if cfg.GRIP then tool.Grip = cfg.GRIP end
	-- where spells leave from on every screen: an attachment on the orb / the book / the tip
	task.spawn(function()
		local handle = tool:WaitForChild("Handle", 15)
		if handle and cfg.ORB and not handle:FindFirstChild("TrailTip") then
			local at = Instance.new("Attachment"); at.Name = "TrailTip"; at.Position = cfg.ORB; at.Parent = handle
		end
	end)
	tool:SetAttribute("Magic", true)   -- (RangedFX takes Roblox's arm animations off: the stance is RigPose's)
	tool:SetAttribute("Stance", cfg.STANCE or 3)
	local power, castMult, manaMult = cfg.POWER or 1, cfg.CAST_MULT or 1, cfg.MANA_MULT or 1
	-- the arsenal: the Spells attribute (the loadout's), else the weapon's own
	local function fits(id) return Spells[id] ~= nil and Spells[id].kind ~= nil and (Spells[id].wand == true) == (cfg.WAND == true) end
	local function book()
		local list = {}
		for _, id in ipairs(splitList(tool:GetAttribute("Spells"))) do if fits(id) then table.insert(list, id) end end
		if #list == 0 then list = cfg.WAND and Spells.WAND_DEFAULT or Spells.DEFAULT end
		local set = {}
		for i, id in ipairs(list) do if fits(id) and i <= (cfg.SLOTS or 4) then set[id] = true end end
		return set
	end
	local cooldown = {}
	local casting = nil   -- {id, token, aim}
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
			for _, a in ipairs({"Casting", "CastStart", "CastTime", "CastReady", "SpeedMult_Cast"}) do c:SetAttribute(a, nil) end
			c:SetAttribute("Acting", nil)
		end
		if casting and casting.hc then casting.hc:Disconnect() end
		casting = nil
	end
	local function cancel(c, why)
		if not casting then return end
		token += 1
		clearCast(c)
		if why then fx:FireAllClients("Fizzle", c) end
		-- (the caster's screen lets go of it too: a hit broke it, the mana ran out)
		local plr = c and Players:GetPlayerFromCharacter(c)
		if plr then remote:FireClient(plr, "Cancelled") end
	end
	-- where the orb is in the casting stance (RigPose), in the body's frame: the server doesn't
	-- see the stance (each screen draws it, and starts the spell at the orb it sees)
	local castFrom = cfg.CAST_FROM or Vector3.new(1, 3.2, -1.7)
	local function originOf(c)
		local r = rootOf(c)
		return r and (r.CFrame * castFrom) or c:GetPivot().Position
	end
	local function stopMeditating(c)
		if c and c:GetAttribute("Meditating") then c:SetAttribute("Meditating", nil); c:SetAttribute("MeditateStart", nil) end
	end

	local function release(c, myToken)
		if not casting or casting.token ~= myToken or holder() ~= c then return end
		if incapacitated(c) then cancel(c, true); return end
		local id = casting.id
		local sp = Spells[id]
		local cost = (sp.mana or 0) * manaMult
		local mana = c:GetAttribute("Mana") or 0
		if mana < cost then cancel(c, true); return end
		if cost > 0 then c:SetAttribute("Mana", mana - cost) end
		cooldown[id] = os.clock() + (sp.cooldown or 0)
		local origin = originOf(c)
		local aim = casting.aim
		local dir = (typeof(aim) == "Vector3" and (aim - origin).Magnitude > 0.5) and (aim - origin).Unit or (rootOf(c) and rootOf(c).CFrame.LookVector or Vector3.zAxis)
		clearCast(c)
		local fn = RESOLVE[sp.kind]
		local skin = skinsOf(tool:GetAttribute("SpellSkins"))[id]
		if fn then task.spawn(fn, c, sp, {id = id, origin = origin, dir = dir, aim = typeof(aim) == "Vector3" and aim or nil, power = power, skin = skin}) end
		-- (a spell gone off, for whoever's watching: the training yard's lessons)
		c:SetAttribute("LastCast", id)
		c:SetAttribute("CastTick", (c:GetAttribute("CastTick") or 0) + 1)
		local who = playerOf(c)
		if who then remote:FireClient(who, "Cast", id, cooldown[id] - os.clock()) end
	end

	-- an action: a player's (the remote, below) or a bot's (the controller's npc): the same rules
	local function act(c, what, a)
		local plr = playerOf(c)
		if what == "Cast" then
			local sp = type(a) == "string" and book()[a] and Spells[a]
			if not sp or casting or incapacitated(c) or c:GetAttribute("Warded") then return end
			if os.clock() < (cooldown[a] or 0) then return end
			if (c:GetAttribute("Mana") or 0) < (sp.mana or 0) * manaMult then if plr then remote:FireClient(plr, "NoMana", a) end; return end
			stopMeditating(c)
			token += 1
			local myToken = token
			local castTime = sp.cast * castMult
			casting = {id = a, token = myToken}
			c:SetAttribute("Casting", a)
			c:SetAttribute("CastStart", now())
			c:SetAttribute("CastTime", castTime)
			c:SetAttribute("SpeedMult_Cast", math.min(1, Spells.CAST_WALK * (cfg.WALK or 1)))
			c:SetAttribute("Acting", true)
			-- a hit while casting (or holding it charged) breaks it
			local h = humOf(c)
			local hp = h.Health
			casting.hc = h.HealthChanged:Connect(function(new)
				if not casting or casting.token ~= myToken then return end
				if new < hp - 0.5 then cancel(c, true) end
				hp = new
			end)
			-- WOUND UP: it holds there, charged, until you let go ("Release"); let go early and it
			-- goes off the moment it's ready
			task.delay(castTime + 0.06, function()
				if not casting or casting.token ~= myToken then return end
				casting.ready = true
				c:SetAttribute("CastReady", true)
				if casting.released then release(c, myToken) end
			end)
		elseif what == "Release" then
			if not casting then return end
			if typeof(a) == "Vector3" then casting.aim = a end
			if casting.ready then release(c, casting.token) else casting.released = true end
		elseif what == "Aim" then
			if casting and typeof(a) == "Vector3" then casting.aim = a end
		elseif what == "Cancel" then
			cancel(c, false)
		elseif what == "Ward" then
			local on = cfg.WARD == true and a == true and not casting and (c:GetAttribute("Mana") or 0) > 4 and not incapacitated(c)
			if on then stopMeditating(c) end
			c:SetAttribute("Warded", on or nil)
			c:SetAttribute("SpeedMult_Ward", on and Spells.WARD.walk or nil)
		elseif what == "Meditate" then
			if a == true and not casting and not c:GetAttribute("Warded") and not incapacitated(c) and c:GetAttribute("MaxMana") then
				c:SetAttribute("Meditating", true)
				c:SetAttribute("MeditateStart", now())
			else
				stopMeditating(c)
			end
		elseif what == "Kick" then
			local t = os.clock()
			if casting or t - lastKick < 1.2 then return end
			lastKick = t
			stopMeditating(c)
			local kcfg = setmetatable({}, {__index = CombatServer.DEFAULTS})
			CombatServer.resolveKick(c, kcfg, {weaponName = tool.Name, tell = function(...) if plr then remote:FireClient(plr, ...) end end})
		end
	end
	remote.OnServerEvent:Connect(function(plr, what, a)
		local c = holder()
		if not c or playerOf(c) ~= plr then return end
		act(c, what, a)
	end)

	-- a bot's hands on it (Combat ▸ Bots): npc("Cast", id) · ("Release", aimPoint) · ("Cancel") ·
	-- ("Ward", on) · ("Meditate", on); state() says what it carries and what's ready
	local IDLE = {phase = "idle", windupStart = -1, windupEnd = -1, releaseEnd = -1}
	CombatServer.controllers[tool] = {
		tool = tool, magic = true, cfg = cfg,
		npc = function(what, a)
			local c = holder()
			if c and not playerOf(c) then act(c, what, a) end
		end,
		state = function()
			local c = holder()
			local list = {}
			for id in pairs(book()) do table.insert(list, id) end
			local ready = {}
			local mana = c and c:GetAttribute("Mana") or 0
			for _, id in ipairs(list) do ready[id] = os.clock() >= (cooldown[id] or 0) and mana >= (Spells[id].mana or 0) * manaMult end
			return {book = list, ready = ready, mana = mana, casting = casting and casting.id or nil, charged = casting and casting.ready == true,
				castMult = castMult, ward = cfg.WARD == true}
		end,
		snapshot = function() return IDLE end,
		interrupt = function() end, attack = function() end, cycle = function() end, feint = function() end,
		blockStart = function() end, blockStop = function() end, kick = function() end, chambered = function() end,
	}
	tool.Destroying:Connect(function() CombatServer.controllers[tool] = nil end)

	-- put away, dropped, dead: nothing stays raised, half-cast or sat down
	local owner = nil
	tool.Equipped:Connect(function() owner = holder() end)
	tool.Unequipped:Connect(function()
		token += 1
		if owner then
			clearCast(owner)
			owner:SetAttribute("Warded", nil)
			owner:SetAttribute("SpeedMult_Ward", nil)
			stopMeditating(owner)
		end
		casting = nil
		owner = nil
	end)
end

return MagicServer
