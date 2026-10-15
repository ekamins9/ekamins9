--[[ POWERS — the third slot's magic (Catalog ▸ Powers: every class's ten), and its throwables
     (Combat ▸ Throwing). The client only asks (PowerRemote "Use", aimPoint); here every use is
     checked (alive, not stunned, off cooldown, in battle), timed and resolved.

       Powers.equip(character, player, loadout)   at spawn (LoadoutServer): what the slot holds
       Powers.onMelee(attacker, target, dmg, hitPos) -> dmg   a blade's clean hit (CombatServer):
                                                  the imbue on the weapon, a stealth ambush
       Powers.takeArrow(shooter) -> enchant|nil   an arrow being loosed (RangedServer): the
                                                  enchantment it carries, if any is left
       Powers.arrowHit(shooter, enchant, pos, target, dir)   where an enchanted arrow landed

     What the slot holds and what's on you is on the character, for every screen (Combat ▸
     Powers.client draws it): Power (id), PowerReadyAt / PowerCD (server time, seconds),
     PowerSpell / PowerSkin (its look) · Imbue (element), ImbueUntil, ImbueSpell, ImbueSkin ·
     Aura (name), AuraUntil, AuraSpell, AuraSkin · HiddenUntil (stealth) · ArrowEnchant (id),
     ArrowLeft · Familiar (until) · and the sums of every buff on you (Combat ▸ Ward and the
     movement read them): SpeedMult_Power, TakenMult, DealtMult, StaminaRegenMult,
     DodgeCostMult, DodgeCooldownMult, Unflinching, DrawMult, CastMult_Power, ManaFree.
     PowerFX (server → every screen): "Zone", id, pos, radius, time, delay, flags, spellId, skin ·
     "Decoy", model · "Dash", character, time · "Slam", pos, radius, spellId, skin ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local MagicServer = require(script.Parent:WaitForChild("MagicServer"))

local Powers = {}
local remote = ReplicatedStorage:FindFirstChild("PowerRemote")
if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "PowerRemote"; remote.Parent = ReplicatedStorage end
local fx = ReplicatedStorage:FindFirstChild("PowerFX")
if not fx then fx = Instance.new("RemoteEvent"); fx.Name = "PowerFX"; fx.Parent = ReplicatedStorage end
Powers.remote, Powers.fx = remote, fx

local function now() return workspace:GetServerTimeNow() end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function alive(m) local h = humOf(m); return h ~= nil and h.Health > 0 end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local hurt, hurtMult = MagicServer.hurt, MagicServer.hurtMult

-- every character's state: what it carries, the buffs and the imbue on it
local state = setmetatable({}, {__mode = "k"})
local function st(c)
	local s = state[c]
	if not s then s = {mods = {}, pulses = {}}; state[c] = s end
	return s
end
-- a player's cooldowns outlive their body (no dying to get a power back)
local readyAt = {}   -- [userId][powerId] = server time

local function spellOf(id) return "Pw_" .. id end
local function skinFor(lo, id) return lo and lo.spellSkins and lo.spellSkins[spellOf(id)] or nil end

--------------------------------------------------------------------
--  BUFFS: every modifier on a character, summed into the attributes others read
--------------------------------------------------------------------
local ATTR = {speed = "SpeedMult_Power", taken = "TakenMult", dealt = "DealtMult", stamina = "StaminaRegenMult",
	dodgeCost = "DodgeCostMult", dodgeCooldown = "DodgeCooldownMult", draw = "DrawMult", cast = "CastMult_Power"}
local function recompute(c)
	local s = st(c)
	local t = now()
	local agg = {speed = 1, taken = 1, dealt = 1, stamina = 1, dodgeCost = 1, dodgeCooldown = 1, draw = 1, cast = 1}
	local unflinching, manaFree, regen = false, false, 0
	for key, m in pairs(s.mods) do
		if m.untilT <= t then s.mods[key] = nil
		else
			for k, v in pairs(m.mods) do
				if agg[k] then agg[k] *= v
				elseif k == "unflinching" then unflinching = unflinching or v
				elseif k == "manaFree" then manaFree = manaFree or v
				elseif k == "regen" then regen += v end
			end
		end
	end
	for k, a in pairs(ATTR) do
		local v = agg[k] ~= 1 and agg[k] or nil
		if c:GetAttribute(a) ~= v then c:SetAttribute(a, v) end
	end
	c:SetAttribute("Unflinching", unflinching or nil)
	c:SetAttribute("ManaFree", manaFree or nil)
	s.regen = regen
end
-- put a set of modifiers on a character for `time` s (the same key refreshes it)
function Powers.addMods(c, mods, time, key)
	if not (c and mods and time and time > 0) then return end
	st(c).mods[key or tostring(mods)] = {mods = mods, untilT = now() + time}
	recompute(c)
end
local function aura(c, name, time, spellId, skin)
	if not name then return end
	c:SetAttribute("Aura", name); c:SetAttribute("AuraUntil", now() + time)
	c:SetAttribute("AuraSpell", spellId); c:SetAttribute("AuraSkin", skin)
end
local function imbue(c, def, time, spellId, skin)
	local s = st(c)
	s.imbue = {def = def, untilT = now() + time, hits = def.hits, spellId = spellId, skin = skin}
	c:SetAttribute("Imbue", def.element or "arcane")
	c:SetAttribute("ImbueUntil", s.imbue.untilT)
	c:SetAttribute("ImbueSpell", spellId)
	c:SetAttribute("ImbueSkin", skin)
end
local function endImbue(c)
	local s = st(c)
	s.imbue = nil
	for _, a in ipairs({"Imbue", "ImbueUntil", "ImbueSpell", "ImbueSkin"}) do c:SetAttribute(a, nil) end
end
local function stun(target, secs)
	if secs and secs > 0 and not target:GetAttribute("Boss") then
		target:SetAttribute("StunnedUntil", math.max(target:GetAttribute("StunnedUntil") or 0, os.clock() + secs))
		CombatServer.interrupt(target, "kicked")
	end
end
local function hex(target, h)
	if not h then return end
	target:SetAttribute("HexUntil", now() + (h.time or 3))
	target:SetAttribute("HexWeaken", h.weaken or 0)
	target:SetAttribute("HexExpose", h.expose or 0)
end
-- a poison: like a burn, but green (Poisoned for the look)
local function poison(caster, target, p, name)
	if hurtMult(caster, target) <= 0 then return end
	local token = (target:GetAttribute("PoisonToken") or 0) + 1
	target:SetAttribute("PoisonToken", token)
	target:SetAttribute("Poisoned", true)
	task.spawn(function()
		local t = 0
		while t < p.time and target.Parent and alive(target) and target:GetAttribute("PoisonToken") == token do
			task.wait(0.5); t += 0.5
			hurt(caster, target, p.dps * 0.5, name)
		end
		if target:GetAttribute("PoisonToken") == token then target:SetAttribute("Poisoned", nil) end
	end)
end
-- a root: can't move for a moment (SpeedMult_Snare 0)
local function snare(caster, target, secs)
	if hurtMult(caster, target) <= 0 then return end
	local token = (target:GetAttribute("SnareToken") or 0) + 1
	target:SetAttribute("SnareToken", token)
	target:SetAttribute("SpeedMult_Snare", 0.02)
	target:SetAttribute("Snared", true)
	task.delay(secs, function()
		if target:GetAttribute("SnareToken") ~= token then return end
		target:SetAttribute("SpeedMult_Snare", nil); target:SetAttribute("Snared", nil)
	end)
end
Powers.snare, Powers.poison, Powers.hex, Powers.stun = snare, poison, hex, stun

-- the nearest foe of `caster` near `pos` (not in `skip`), within range
local function nearestFoe(caster, pos, range, skip)
	local best, bestD
	for _, m in ipairs(MagicServer.everyone()) do
		local r = rootOf(m)
		if r and m ~= caster and not (skip and skip[m]) and alive(m) and hurtMult(caster, m) > 0 then
			local d = (r.Position - pos).Magnitude
			if d <= range and (not bestD or d < bestD) then best, bestD = m, d end
		end
	end
	return best
end
-- lightning from `from` to the nearest foe, then on (jumps)
local function shock(caster, fromModel, sh, spellId, skin)
	local r0 = rootOf(fromModel)
	if not r0 then return end
	local points, hit = {r0.Position}, {[fromModel] = true}
	local at = r0.Position
	for _ = 1, sh.jumps or 1 do
		local m = nearestFoe(caster, at, sh.range or 12, hit)
		if not m then break end
		hit[m] = true
		at = rootOf(m).Position
		table.insert(points, at)
		hurt(caster, m, sh.damage or 6, (Spells[spellId] or {}).name or "Power")
	end
	if #points > 1 then MagicServer.fx:FireAllClients("Chain", spellId, points, caster, skin) end
end

--------------------------------------------------------------------
--  THE KINDS
--------------------------------------------------------------------
local KIND = {}

function KIND.imbue(c, def, aim, ctx)
	imbue(c, def, def.time, ctx.spellId, ctx.skin)
end

function KIND.buff(c, def, aim, ctx)
	local hum = humOf(c)
	if def.instant then
		local i = def.instant
		if i.stamina then c:SetAttribute("BlockMeter", math.min(c:GetAttribute("BlockMax") or 100, (c:GetAttribute("BlockMeter") or 0) + i.stamina)) end
		if i.heal and hum then hum.Health = math.min(hum.MaxHealth, hum.Health + i.heal) end
		if i.mana and c:GetAttribute("MaxMana") then c:SetAttribute("Mana", math.min(c:GetAttribute("MaxMana"), (c:GetAttribute("Mana") or 0) + i.mana)) end
	end
	if def.mods then Powers.addMods(c, def.mods, def.time, "power") end
	if def.barrier then
		c:SetAttribute("Shield", def.barrier); c:SetAttribute("ShieldUntil", now() + def.time)
		MagicServer.fx:FireAllClients("Buff", ctx.spellId, c, "barrier", def.time, ctx.skin)
		task.delay(def.time, function()
			if (c:GetAttribute("ShieldUntil") or 0) <= now() + 0.05 then c:SetAttribute("Shield", nil); c:SetAttribute("ShieldUntil", nil) end
		end)
	end
	if def.imbue then imbue(c, def.imbue, def.time, ctx.spellId, ctx.skin) end
	if def.pulse then table.insert(st(c).pulses, {def = def.pulse, untilT = now() + def.time, nextAt = 0}) end
	aura(c, def.aura or (def.mods and "glow") or nil, def.time, ctx.spellId, ctx.skin)
end

function KIND.spell(c, def, aim, ctx)
	MagicServer.cast(c, ctx.spellId, aim, ctx.skin)
end

function KIND.shout(c, def, aim, ctx)
	local r0 = rootOf(c)
	if not r0 then return end
	for _, m in ipairs(MagicServer.everyone()) do
		local r = rootOf(m)
		if r and alive(m) and (r.Position - r0.Position).Magnitude <= def.radius then
			if MagicServer.friendly(c, m) then
				if def.allies then Powers.addMods(m, def.allies.mods, def.allies.time, "shout:" .. def.id); aura(m, "glow", def.allies.time, ctx.spellId, ctx.skin) end
			elseif def.foes and hurtMult(c, m) > 0 then
				local f = def.foes
				if f.damage then hurt(c, m, f.damage, def.name) end
				if f.slow then MagicServer.chill(c, m, f.slow, f.time or 2) end
				if f.weaken or f.expose then hex(m, {weaken = f.weaken, expose = f.expose, time = f.time}) end
				if f.shove then
					local away = flat(r.Position - r0.Position)
					if away.Magnitude > 0.1 then MagicServer.shove(m, away.Unit * f.shove + Vector3.new(0, f.shove * 0.3, 0)) end
				end
			end
		end
	end
	MagicServer.fx:FireAllClients("Nova", ctx.spellId, r0.Position - Vector3.new(0, 2.8, 0), def.radius, ctx.skin)
end

-- a push that lasts: horizontal only (gravity still has you), for `time` s
local function rush(c, vel, time, up)
	local r = rootOf(c)
	if not r then return end
	local att = Instance.new("Attachment"); att.Name = "PowerRush"; att.Parent = r
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	if up then
		lv.MaxForce = 2e5; lv.VectorVelocity = vel
	else
		lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		lv.MaxAxesForce = Vector3.new(2e5, 0, 2e5)
		lv.VectorVelocity = vel
	end
	lv.Parent = r
	task.delay(time, function() lv:Destroy(); att:Destroy() end)
end

function KIND.dash(c, def, aim, ctx)
	local r = rootOf(c)
	if not r then return end
	local dir = flat(typeof(aim) == "Vector3" and (aim - r.Position) or r.CFrame.LookVector)
	if dir.Magnitude < 0.1 then dir = flat(r.CFrame.LookVector) end
	dir = dir.Unit
	rush(c, dir * (def.distance / def.time), def.time)
	fx:FireAllClients("Dash", c, def.time, ctx.spellId, ctx.skin)
	if def.hit then
		local hit = {}
		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			if os.clock() - t0 > def.time + 0.1 or not alive(c) then conn:Disconnect(); return end
			for _, m in ipairs(MagicServer.everyone()) do
				local mr = rootOf(m)
				if mr and m ~= c and not hit[m] and alive(m) and (mr.Position - r.Position).Magnitude < 4.2 and hurtMult(c, m) > 0 then
					hit[m] = true
					hurt(c, m, def.hit.damage or 0, def.name)
					if def.hit.shove then MagicServer.shove(m, dir * def.hit.shove + Vector3.new(0, def.hit.shove * 0.35, 0)) end
					stun(m, def.hit.stun)
				end
			end
		end)
	end
	if def.after then
		task.delay(def.time, function()
			if not alive(c) then return end
			if def.after.imbue then imbue(c, def.after.imbue, def.after.time, ctx.spellId, ctx.skin) end
			if def.after.mods then Powers.addMods(c, def.after.mods, def.after.time, "after") end
		end)
	end
end

-- a slam where you land (Skybound, a Knight's own): everyone round, hurt and thrown
local function slam(c, at, s, ctx)
	for _, m in ipairs(MagicServer.everyone()) do
		local r = rootOf(m)
		if r and m ~= c and alive(m) and (r.Position - at).Magnitude <= s.radius and hurtMult(c, m) > 0 then
			if (s.damage or 0) > 0 then hurt(c, m, s.damage, ctx.name) end
			if s.slow then MagicServer.chill(c, m, s.slow, 2) end
			if s.shove then
				local away = flat(r.Position - at)
				if away.Magnitude > 0.1 then MagicServer.shove(m, away.Unit * s.shove + Vector3.new(0, s.shove * 0.4, 0)) end
			end
		end
	end
	fx:FireAllClients("Slam", at, s.radius, ctx.spellId, ctx.skin)
end
function KIND.leap(c, def, aim, ctx)
	local r, hum = rootOf(c), humOf(c)
	if not (r and hum) then return end
	local dir = flat(typeof(aim) == "Vector3" and (aim - r.Position) or r.CFrame.LookVector)
	dir = dir.Magnitude > 0.1 and dir.Unit or flat(r.CFrame.LookVector).Unit
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	rush(c, dir * (def.forward or 30) + Vector3.new(0, def.up or 50, 0), 0.18, true)
	fx:FireAllClients("Dash", c, 0.6, ctx.spellId, ctx.skin)
	if def.float then
		-- a slow fall: most of your weight lifted for a while
		task.delay(0.35, function()
			if not (alive(c) and r.Parent) then return end
			local att = Instance.new("Attachment"); att.Name = "PowerFloat"; att.Parent = r
			local vf = Instance.new("VectorForce")
			vf.Attachment0 = att; vf.RelativeTo = Enum.ActuatorRelativeTo.World
			vf.Force = Vector3.new(0, r.AssemblyMass * workspace.Gravity * 0.78, 0)
			vf.Parent = r
			task.delay(def.float, function() vf:Destroy(); att:Destroy() end)
		end)
	end
	if def.slam then
		task.spawn(function()
			local t0 = os.clock()
			task.wait(0.3)
			while os.clock() - t0 < 4 and alive(c) do
				if hum.FloorMaterial ~= Enum.Material.Air then slam(c, r.Position - Vector3.new(0, 2.8, 0), def.slam, ctx); return end
				task.wait()
			end
		end)
	end
end

-- a circle: at you or where you aim; every half second it heals, shields, hurts, slows or pulls
local function aimedGround(c, aim, range)
	local r = rootOf(c)
	local p = typeof(aim) == "Vector3" and aim or (r and r.Position) or Vector3.zero
	if r and range then
		local f = flat(p - r.Position)
		if f.Magnitude > range then p = r.Position + f.Unit * range end
	end
	return MagicServer.groundAt(c, p)
end
function KIND.zone(c, def, aim, ctx)
	local r = rootOf(c)
	if not r then return end
	local at = def.at == "aim" and aimedGround(c, aim, def.range or 50) or MagicServer.groundAt(c, r.Position)
	Powers.zoneAt(c, at, def, ctx)
end
-- a circle at `at` (a power's, or a throwable's burst: Combat ▸ Throwing)
function Powers.zoneAt(c, at, def, ctx)
	local flags = {smoke = def.smoke, dome = def.dome, arrows = def.arrows, pull = def.foes and def.foes.pull ~= nil,
		heal = def.allies and def.allies.heal ~= nil, hurt = def.foes and (def.foes.dps or 0) > 0,
		fire = def.fire, frost = def.frost, ground = def.ground}
	fx:FireAllClients("Zone", def.id, at, def.radius, def.time, def.delay or 0, flags, ctx.spellId, ctx.skin)
	task.spawn(function()
		if def.delay then task.wait(def.delay) end
		local t = 0
		while t < def.time do
			for _, m in ipairs(MagicServer.everyone()) do
				local mr = rootOf(m)
				if mr and alive(m) and flat(mr.Position - at).Magnitude <= def.radius and math.abs(mr.Position.Y - at.Y) < 14 then
					if MagicServer.friendly(c, m) then
						local a = def.allies
						if a then
							if a.heal then MagicServer.heal(m, a.heal * 0.5, 0.4) end
							if a.taken then Powers.addMods(m, {taken = a.taken}, 0.7, "zone:" .. def.id) end
						end
						if def.smoke then m:SetAttribute("InSmokeUntil", now() + 0.7) end
					elseif hurtMult(c, m) > 0 then
						local f = def.foes
						if f then
							if (f.dps or 0) > 0 then hurt(c, m, f.dps * 0.5, def.name) end
							if f.slow then MagicServer.chill(c, m, f.slow, 0.7) end
							if f.pull then
								local to = flat(at - mr.Position)
								if to.Magnitude > 1.5 then MagicServer.shove(m, to.Unit * f.pull) end
							end
						end
						if def.smoke then m:SetAttribute("InSmokeUntil", now() + 0.7) end
					end
				end
			end
			task.wait(0.5); t += 0.5
		end
	end)
end

function KIND.summon(c, def, aim, ctx)
	local untilT = now() + def.time
	c:SetAttribute("Familiar", untilT); c:SetAttribute("FamiliarSpell", ctx.spellId); c:SetAttribute("FamiliarSkin", ctx.skin)
	task.spawn(function()
		while now() < untilT and alive(c) and c:GetAttribute("Familiar") == untilT do
			local r = rootOf(c)
			local m = r and nearestFoe(c, r.Position, def.range or 40)
			if m and rootOf(m) then MagicServer.cast(c, ctx.spellId, rootOf(m).Position + Vector3.new(0, 0.6, 0), ctx.skin) end
			task.wait(def.interval or 1.5)
		end
		if c:GetAttribute("Familiar") == untilT then c:SetAttribute("Familiar", nil) end
	end)
end

function KIND.stealth(c, def, aim, ctx)
	local untilT = now() + def.time
	c:SetAttribute("HiddenUntil", untilT)
	c:SetAttribute("Ambush", def.ambush)
	if def.mods then Powers.addMods(c, def.mods, def.time, "stealth") end
	if def.decoy then
		-- a shimmering double where you stood (looks only: nothing to hit, nobody home)
		local ok, copy = pcall(function()
			local was = c.Archivable
			c.Archivable = true
			local cl = c:Clone()
			c.Archivable = was
			return cl
		end)
		if ok and copy then
			for _, d in ipairs(copy:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Tool") or d:IsA("Humanoid") or d:IsA("ForceField") then d:Destroy()
				elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end
			end
			copy.Name = "Decoy"
			copy.Parent = workspace
			fx:FireAllClients("Decoy", copy, def.time + 1, ctx.spellId, ctx.skin)
			Debris:AddItem(copy, def.time + 1.2)
		end
	end
	task.delay(def.time, function()
		if c:GetAttribute("HiddenUntil") == untilT then c:SetAttribute("HiddenUntil", nil); c:SetAttribute("Ambush", nil) end
	end)
end

function KIND.arrows(c, def, aim, ctx)
	local s = st(c)
	s.arrows = {def = def, left = def.count or 1, spellId = ctx.spellId, skin = ctx.skin}
	c:SetAttribute("ArrowEnchant", def.id)
	c:SetAttribute("ArrowLeft", s.arrows.left)
end

--------------------------------------------------------------------
--  USING IT
--------------------------------------------------------------------
local function inBattle()
	local round = ReplicatedStorage:FindFirstChild("Round")
	return not (round and round:GetAttribute("Mode") == "Hub")
end
local Throwing
local function throwing() Throwing = Throwing or require(script.Parent:WaitForChild("Throwing")); return Throwing end

function Powers.use(c, aim)
	local plr = Players:GetPlayerFromCharacter(c)
	local s = st(c)
	if not alive(c) or c:GetAttribute("Ragdolled") then return false, "" end
	if (c:GetAttribute("StunnedUntil") or 0) > os.clock() then return false, "stunned" end
	if s.kind == "throwable" then return throwing().throw(c, aim) end
	if s.kind ~= "power" or not s.power then return false, "nothing in your third slot" end
	if not inBattle() then return false, "Powers are for battle: try them in the Training Yard" end
	local def = s.power
	local uid = plr and plr.UserId or c   -- (a bot's cooldowns are its own body's)
	readyAt[uid] = readyAt[uid] or {}
	local t = now()
	if t < (readyAt[uid][def.id] or 0) then return false, string.format("%s is ready in %d", def.name, math.ceil(readyAt[uid][def.id] - t)) end
	local cd = def.cooldown or 20
	readyAt[uid][def.id] = t + cd + (def.cast or 0)
	c:SetAttribute("PowerReadyAt", readyAt[uid][def.id]); c:SetAttribute("PowerCD", cd)
	local ctx = {spellId = spellOf(def.id), skin = s.skin, name = def.name}
	local function go()
		if not alive(c) or c:GetAttribute("Ragdolled") then return end
		c:SetAttribute("PowerCasting", nil)
		c:SetAttribute("PowerTick", (c:GetAttribute("PowerTick") or 0) + 1)
		c:SetAttribute("LastPower", def.id)
		local fn = KIND[def.kind]
		if fn then
			local ok, err = pcall(fn, c, def, aim, ctx)
			if not ok then warn("[Powers]", def.id, err) end
		end
	end
	if (def.cast or 0) > 0 then
		c:SetAttribute("PowerCasting", def.id)
		task.delay(def.cast, go)
	else go() end
	return true
end

remote.OnServerEvent:Connect(function(plr, what, aim)
	if what ~= "Use" then return end
	local c = plr.Character
	if not c then return end
	local s = st(c)
	local t = os.clock()
	if t - (s.lastAsk or 0) < 0.15 then return end
	s.lastAsk = t
	if typeof(aim) ~= "Vector3" or aim ~= aim then aim = nil end
	local ok, why = Powers.use(c, aim)
	if not ok and why and why ~= "" then remote:FireClient(plr, "Denied", why) end
end)

--------------------------------------------------------------------
--  WHAT THE SLOT HOLDS (LoadoutServer, at every spawn)
--------------------------------------------------------------------
function Powers.equip(c, plr, lo)
	local s = st(c)
	s.kind, s.power, s.skin = nil, nil, nil
	for _, a in ipairs({"Power", "PowerSpell", "PowerSkin", "PowerReadyAt", "PowerCD", "Throwable", "ThrowCharges", "ThrowMax", "ThrowNextAt"}) do c:SetAttribute(a, nil) end
	if not lo then return end
	if lo.thirdKind == "power" and Catalog.POWER[lo.thirdId or ""] then
		local def = Catalog.POWER[lo.thirdId]
		s.kind, s.power, s.skin = "power", def, skinFor(lo, def.id)
		c:SetAttribute("Power", def.id)
		c:SetAttribute("PowerSpell", spellOf(def.id))
		c:SetAttribute("PowerSkin", s.skin)
		local uid = plr and plr.UserId or c
		c:SetAttribute("PowerReadyAt", readyAt[uid] and readyAt[uid][def.id] or 0)
		c:SetAttribute("PowerCD", def.cooldown)
	elseif lo.thirdKind == "throwable" then
		s.kind = "throwable"
		throwing().equip(c, lo.thirdId, lo.thirdSkin)
	end
end

--------------------------------------------------------------------
--  THE HOOKS (CombatServer: a blade's clean hit · RangedServer: arrows)
--------------------------------------------------------------------
local function behind(attacker, target)
	local ar, tr = rootOf(attacker), rootOf(target)
	if not (ar and tr) then return false end
	local to = flat(ar.Position - tr.Position)
	return to.Magnitude > 0.1 and tr.CFrame.LookVector:Dot(to.Unit) < -0.3
end
function Powers.onMelee(attacker, target, dmg, hitPos)
	if not (attacker and target and dmg) then return dmg end
	local s = state[attacker]
	local im = s and s.imbue
	if im and im.untilT > now() then
		local d = im.def
		dmg += d.bonus or 0
		if d.behind and behind(attacker, target) then dmg *= d.behind end
		local name = (Spells[im.spellId] or {}).name or "Power"
		task.defer(function()
			if not target.Parent then return end
			if d.burn then MagicServer.burn(attacker, target, d.burn, name) end
			if d.poison then poison(attacker, target, d.poison, name) end
			if d.chill then MagicServer.chill(attacker, target, d.chill.slow, d.chill.time) end
			if d.hex then hex(target, d.hex) end
			if d.shove then
				local ar, tr = rootOf(attacker), rootOf(target)
				local away = ar and tr and flat(tr.Position - ar.Position)
				if away and away.Magnitude > 0.1 then MagicServer.shove(target, away.Unit * d.shove + Vector3.new(0, d.shove * 0.3, 0)) end
			end
			if d.shock then shock(attacker, target, d.shock, im.spellId, im.skin) end
			local h = humOf(attacker)
			if h and h.Health > 0 then
				local back = (d.heal or 0) + dmg * (d.lifesteal or 0)
				if back > 0 then h.Health = math.min(h.MaxHealth, h.Health + back) end
			end
		end)
		if im.hits then
			im.hits -= 1
			if im.hits <= 0 then endImbue(attacker) end
		end
	end
	return dmg
end

function Powers.takeArrow(shooter)
	local s = state[shooter]
	local a = s and s.arrows
	if not (a and a.left > 0) then return nil end
	a.left -= 1
	shooter:SetAttribute("ArrowLeft", a.left)
	if a.left <= 0 then s.arrows = nil; shooter:SetAttribute("ArrowEnchant", nil); shooter:SetAttribute("ArrowLeft", nil) end
	local e = table.clone(a.def.enchant or {})
	e.spellId, e.skin, e.name = a.spellId, a.skin, a.def.name
	return e
end

function Powers.arrowHit(shooter, e, pos, target, dir)
	if not (e and shooter) then return end
	local name = e.name or "Arrow"
	if target and alive(target) then
		if e.burn then MagicServer.burn(shooter, target, e.burn, name) end
		if e.chill then MagicServer.chill(shooter, target, e.chill.slow, e.chill.time) end
		if e.snare then snare(shooter, target, e.snare.time) end
		if e.mark then hex(target, {expose = e.mark.expose, time = e.mark.time}) end
		if e.shock then shock(shooter, target, e.shock, e.spellId, e.skin) end
	end
	if e.splash then
		for _, m in ipairs(MagicServer.everyone()) do
			local r = rootOf(m)
			if r and m ~= shooter and m ~= target and (r.Position - pos).Magnitude <= e.splash.radius then hurt(shooter, m, e.splash.damage, name) end
		end
		fx:FireAllClients("Slam", pos, e.splash.radius, e.spellId, e.skin)
	end
	if e.explode then
		for _, m in ipairs(MagicServer.everyone()) do
			local r = rootOf(m)
			local d = r and (r.Position - pos).Magnitude
			if d and m ~= shooter and d <= e.explode.radius and alive(m) then
				local k = math.clamp(1 - d / e.explode.radius, 0.35, 1)
				if hurt(shooter, m, e.explode.damage * k, name) then
					local away = flat(r.Position - pos)
					if away.Magnitude > 0.1 then MagicServer.shove(m, away.Unit * 30 * k + Vector3.new(0, 14 * k, 0)) end
				end
			end
		end
		fx:FireAllClients("Slam", pos, e.explode.radius, e.spellId, e.skin)
		MagicServer.fx:FireAllClients("Nova", e.spellId, pos, e.explode.radius, e.skin)
	end
end

-- (a stealthy character striking from it: the ambush, and they're seen again; Combat ▸ Ward)
function Powers.reveal(c)
	if c and (c:GetAttribute("HiddenUntil") or 0) > now() then
		local amb = c:GetAttribute("Ambush")
		c:SetAttribute("HiddenUntil", nil); c:SetAttribute("Ambush", nil)
		return amb or 1
	end
	return 1
end

--------------------------------------------------------------------
--  EVERY QUARTER SECOND: buffs run out, regen ticks, pulses go off, imbues end
--------------------------------------------------------------------
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then return end
	local step = acc
	acc = 0
	local t = now()
	for c, s in pairs(state) do
		if not c.Parent then state[c] = nil
		else
			if next(s.mods) then recompute(c) end
			if (s.regen or 0) > 0 then
				local h = humOf(c)
				if h and h.Health > 0 then h.Health = math.min(h.MaxHealth, h.Health + s.regen * step) end
			end
			if s.imbue and s.imbue.untilT <= t then endImbue(c) end
			for i = #s.pulses, 1, -1 do
				local p = s.pulses[i]
				if p.untilT <= t then table.remove(s.pulses, i)
				elseif t >= p.nextAt then
					p.nextAt = t + (p.def.every or 1)
					local r0 = rootOf(c)
					for _, m in ipairs(r0 and MagicServer.everyone() or {}) do
						local r = rootOf(m)
						if r and m ~= c and alive(m) and (r.Position - r0.Position).Magnitude <= p.def.radius and hurtMult(c, m) > 0 then
							hex(m, {weaken = p.def.foes.weaken, expose = p.def.foes.expose, time = p.def.foes.time})
						end
					end
				end
			end
			if (c:GetAttribute("AuraUntil") or 0) > 0 and c:GetAttribute("AuraUntil") <= t then
				c:SetAttribute("Aura", nil); c:SetAttribute("AuraUntil", nil); c:SetAttribute("AuraSpell", nil); c:SetAttribute("AuraSkin", nil)
			end
		end
	end
end)

return Powers
