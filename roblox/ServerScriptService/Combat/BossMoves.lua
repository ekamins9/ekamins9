--[[ BOSS MOVES — the big moves a boss (and an elite, and a few others) has on top of its blade,
     after the bosses of the souls games: every one is TELEGRAPHED (the ground lights where it
     will land, the body winds up and glows), every one has a way out — step out of the ring,
     JUMP the shockwave, DODGE through the blow (a dodge's moment untouchable), block the ones a
     shield can take (a sweep, a charge) — and a charge that meets a wall leaves the boss
     STAGGERED, open, for a moment. Under half its health a boss enters its SECOND PHASE: it
     roars, its moves come faster, new ones open up, and its arena turns on you (its hazard).

     A monster's moves are its Bestiary `moves` (Catalog ▸ Bestiary), each:
       {kind, name, dmg, cd (seconds between uses), phase (1 | 2: from which phase), range
        {min, max} (how far the one it's aimed at must be), weight, fx (its look: bone ghost
        gold crimson ice ember holy nature shadow), count, radius, …}
     and its `hazard` (phase two's: {kind = "rain", every = s, count, radius, dmg, fx}).

       slam       a ring round it fills, then it comes down (radius ×its size)
       shockwave  it strikes the ground: a wall of force rolls out, ring after ring — JUMP it
       charge     a lane lights up ahead of it, then it barrels down it (into a wall: staggered)
       leap       a ring lights under you; it jumps, and lands there
       sweep      a wide arc in front of it fills, then the great swing (block it, or get behind)
       spin       it whirls for a few seconds, drifting after you
       eruption   a line of rings races from it to you, bursting one after another
       rain       rings fall about the arena, and under each of you, then what falls from above
       nova       a ring under each of you, then it erupts
       blink      it vanishes, and comes out of the dark behind you, already swinging
       barrage    a fan of bolts at you (step aside, dodge)
       beam       a lance of light sweeps across the room
       roar       (the second phase's start) a burst that throws everyone back

     Moves.run(mob) starts its loop (Combat ▸ Monsters, for any monster with moves). While a
     move is on, the bot's own fighting waits (bot.startAt). Every screen draws the wind-up
     poses, the shakes, the flashes: BossFX (StarterPlayerScripts ▸ Adventure.client). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local MagicServer = require(script.Parent:WaitForChild("MagicServer"))
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local Powers
local function powers() Powers = Powers or require(script.Parent:WaitForChild("Powers")); return Powers end

local Moves = {}
local fxRemote = ReplicatedStorage:FindFirstChild("BossFX")
if not fxRemote then fxRemote = Instance.new("RemoteEvent"); fxRemote.Name = "BossFX"; fxRemote.Parent = ReplicatedStorage end
Moves.remote = fxRemote

local folder = workspace:FindFirstChild("MonsterFX")
if not folder then folder = Instance.new("Folder"); folder.Name = "MonsterFX"; folder.Parent = workspace end

local DODGE_IFRAMES = 0.45
local FX = {
	bone    = {main = Color3.fromRGB(230, 222, 196), glow = Color3.fromRGB(120, 255, 170), mat = Enum.Material.SmoothPlastic},
	ghost   = {main = Color3.fromRGB(140, 230, 255), glow = Color3.fromRGB(150, 240, 255), mat = Enum.Material.Neon},
	gold    = {main = Color3.fromRGB(240, 196, 70),  glow = Color3.fromRGB(255, 210, 90),  mat = Enum.Material.Metal},
	crimson = {main = Color3.fromRGB(170, 20, 50),   glow = Color3.fromRGB(255, 50, 90),   mat = Enum.Material.Neon},
	ice     = {main = Color3.fromRGB(180, 230, 255), glow = Color3.fromRGB(170, 230, 255), mat = Enum.Material.Ice},
	ember   = {main = Color3.fromRGB(255, 120, 30),  glow = Color3.fromRGB(255, 150, 50),  mat = Enum.Material.Neon},
	holy    = {main = Color3.fromRGB(255, 236, 160), glow = Color3.fromRGB(255, 226, 130), mat = Enum.Material.Neon},
	nature  = {main = Color3.fromRGB(90, 160, 70),   glow = Color3.fromRGB(150, 255, 110), mat = Enum.Material.Grass},
	shadow  = {main = Color3.fromRGB(60, 30, 90),    glow = Color3.fromRGB(170, 100, 255), mat = Enum.Material.Neon},
	stone   = {main = Color3.fromRGB(120, 116, 110), glow = Color3.fromRGB(255, 120, 60),  mat = Enum.Material.Slate},
}
local WARN = Color3.fromRGB(255, 60, 40)   -- the telegraph's red, under its colour

local function now() return os.clock() end
local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function fxOf(spec, mob) return FX[spec.fx or (mob.def.moveFx) or "stone"] or FX.stone end
local function scaleOf(mob) return mob.model:GetAttribute("MonsterScale") or 1 end
local function feet(mob)
	local r = rootOf(mob.model)
	return r and (r.Position - Vector3.new(0, 3 * scaleOf(mob), 0)) or Vector3.zero
end

local function sound(id, at, vol, speed)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.new(1, 1, 1); p.Position = at; p.Parent = folder
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol or 0.8; s.PlaybackSpeed = speed or 1
	s.RollOffMaxDistance = 220
	s.Parent = p
	s:Play()
	Debris:AddItem(p, 4)
end
local SND = {boom = "rbxasset://sounds/impact_explosion_03.mp3", land = "rbxasset://sounds/action_jump_land.mp3", lunge = "rbxasset://sounds/swordlunge.wav", slash = "rbxasset://sounds/swordslash.wav"}

--------------------------------------------------------------------
--  TELEGRAPHS (ground marks that fill), BURSTS
--------------------------------------------------------------------
local function quiet(p)
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end
local function disc(pos, r, color, t)
	local p = quiet(Instance.new("Part"))
	p.Shape = Enum.PartType.Cylinder
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.new(0.1, r * 2, r * 2)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Transparency = t
	p.Parent = folder
	return p
end
-- a ring on the ground that fills over `t` seconds
function Moves.circle(pos, r, color, t)
	local outer = disc(pos, r, color, 0.7)
	local edge = disc(pos, r + 0.35, WARN, 0.35)
	edge.Size = Vector3.new(0.06, (r + 0.35) * 2, (r + 0.35) * 2)
	local fill = disc(pos, 0.3, color, 0.25)
	fill.Size = Vector3.new(0.12, 0.6, 0.6)
	TweenService:Create(fill, TweenInfo.new(t, Enum.EasingStyle.Linear), {Size = Vector3.new(0.12, r * 2, r * 2)}):Play()
	for _, p in ipairs({outer, edge, fill}) do Debris:AddItem(p, t + 0.05) end
end
-- a lane from `from` along `dir`, `len` long, `w` wide, filling from its foot
function Moves.lane(from, dir, len, w, color, t)
	dir = flat(dir).Unit
	local base = CFrame.lookAt(from + Vector3.new(0, 0.1, 0), from + Vector3.new(0, 0.1, 0) + dir)
	local outer = quiet(Instance.new("Part"))
	outer.Material = Enum.Material.Neon; outer.Color = color; outer.Transparency = 0.7
	outer.Size = Vector3.new(w, 0.1, len); outer.CFrame = base * CFrame.new(0, 0, -len / 2); outer.Parent = folder
	local fill = quiet(Instance.new("Part"))
	fill.Material = Enum.Material.Neon; fill.Color = WARN; fill.Transparency = 0.3
	fill.Size = Vector3.new(w * 0.8, 0.12, 0.2); fill.CFrame = base * CFrame.new(0, 0, -0.1); fill.Parent = folder
	local v = Instance.new("NumberValue")
	v.Changed:Connect(function(a) fill.Size = Vector3.new(w * 0.8, 0.12, math.max(0.2, len * a)); fill.CFrame = base * CFrame.new(0, 0, -len * a / 2) end)
	TweenService:Create(v, TweenInfo.new(t, Enum.EasingStyle.Linear), {Value = 1}):Play()
	for _, p in ipairs({outer, fill, v}) do Debris:AddItem(p, t + 0.05) end
end
-- an arc in front (half-angle `half` radians) as spokes that grow
function Moves.arc(cf, r, half, color, t)
	local n = 9
	for i = 0, n - 1 do
		local a = -half + (2 * half) * (i / (n - 1))
		local dirCf = cf * CFrame.Angles(0, a, 0)
		local spoke = quiet(Instance.new("Part"))
		spoke.Material = Enum.Material.Neon; spoke.Color = (i % 2 == 0) and WARN or color; spoke.Transparency = 0.45
		spoke.Size = Vector3.new(r * math.sin(half * 2 / n) * 1.25 + 0.4, 0.1, 0.4)
		spoke.CFrame = dirCf * CFrame.new(0, 0.1, -0.2)
		spoke.Parent = folder
		local v = Instance.new("NumberValue")
		v.Changed:Connect(function(k) spoke.Size = Vector3.new(spoke.Size.X, 0.1, math.max(0.4, r * k)); spoke.CFrame = dirCf * CFrame.new(0, 0.1, -r * k / 2) end)
		TweenService:Create(v, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = 1}):Play()
		Debris:AddItem(spoke, t + 0.05); Debris:AddItem(v, t + 0.05)
	end
end

local function emitAt(pos, color, n, speed, up, texture, size)
	local a = quiet(Instance.new("Part"))
	a.Transparency = 1; a.Size = Vector3.new(1, 1, 1); a.Position = pos; a.Parent = folder
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color)
	pe.LightEmission = 1
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, up or -20, 0)
	pe.Lifetime = NumberRange.new(0.5, 1.1)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size or 1), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	if texture then pe.Texture = texture end
	pe.Rate = 0
	pe.Parent = a
	pe:Emit(n)
	Debris:AddItem(a, 1.8)
end
-- what bursts out of the ground (a spike of bone or ice, a geyser of fire, a column of light)
local function spike(pos, fx, h)
	h = h or 7
	local p = quiet(Instance.new("WedgePart"))
	p.Material = fx.mat; p.Color = fx.main
	p.Size = Vector3.new(1.6, h, 1.6)
	local up = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, math.random() * 6.28, 0)
	p.CFrame = up * CFrame.new(0, -h, 0)
	p.Parent = folder
	TweenService:Create(p, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = up}):Play()
	task.delay(0.9, function() TweenService:Create(p, TweenInfo.new(0.4), {CFrame = up * CFrame.new(0, -h, 0), Transparency = 1}):Play() end)
	Debris:AddItem(p, 1.5)
	emitAt(pos + Vector3.new(0, 1, 0), fx.glow, 18, 18, -30, nil, 0.6)
end

--------------------------------------------------------------------
--  LANDING A BLOW (on whoever is where it lands)
--------------------------------------------------------------------
local function victims(mob)
	local out = {}
	for _, c in ipairs(MagicServer.everyone()) do
		if c ~= mob.model and humOf(c) and humOf(c).Health > 0 and MagicServer.hurtMult(mob.model, c) > 0 then table.insert(out, c) end
	end
	return out
end
local function grounded(c)
	local h = humOf(c)
	return h and h.FloorMaterial ~= Enum.Material.Air
end
-- the blow: unless they dodged through it, or (a blockable one) took it on their guard
local function strike(mob, c, dmg, spec, from, o)
	o = o or {}
	local r = rootOf(c)
	if not r then return false end
	if now() - (c:GetAttribute("LastDodgeAt") or -1e9) < DODGE_IFRAMES then
		c:SetAttribute("GuardText", "DODGED"); c:SetAttribute("GuardTick", (c:GetAttribute("GuardTick") or 0) + 1)
		return false
	end
	if o.blockable and c:GetAttribute("Blocking") == true then
		local mr = rootOf(mob.model)
		local facing = mr and r.CFrame.LookVector:Dot(flat(mr.Position - r.Position).Unit) > 0.2
		if facing then
			local meter = c:GetAttribute("BlockMeter") or 100
			local cost = dmg * 1.4
			if meter >= cost then
				CombatServer.drainStamina(c, cost, c:GetAttribute("BlockMax"))
				c:SetAttribute("GuardText", "BLOCKED  ·  " .. string.upper(spec.name or "")); c:SetAttribute("GuardTick", (c:GetAttribute("GuardTick") or 0) + 1)
				MagicServer.shove(c, flat(r.Position - (from or mr.Position)).Unit * 18)
				return false
			end
			-- the guard breaks: half of it through, and a stagger
			c:SetAttribute("BlockMeter", 0)
			c:SetAttribute("GuardText", "GUARD BROKEN"); c:SetAttribute("GuardTick", (c:GetAttribute("GuardTick") or 0) + 1)
			powers().stun(c, 0.9)
			dmg *= 0.5
		end
	end
	-- (MagicServer scales a caster's damage by its SpellPower: a move is its own, at full weight)
	MagicServer.hurt(mob.model, c, dmg / math.max(0.1, mob.model:GetAttribute("SpellPower") or 1), spec.name or mob.def.name)
	if o.knock ~= false and from then
		local away = flat(r.Position - from)
		if away.Magnitude < 0.1 then away = Vector3.new(0, 0, 1) end
		MagicServer.shove(c, away.Unit * (o.knock or 30) + Vector3.new(0, o.lift or 22, 0))
	end
	if spec.burn then MagicServer.burn(mob.model, c, {dps = spec.burn, time = 3}, spec.name) end
	if spec.chill then MagicServer.chill(mob.model, c, spec.chill, 2.5) end
	return true
end
Moves.strike = strike
-- everyone within r of pos (in the air too, unless `ground`: then only those on the ground)
local function areaHit(mob, pos, r, dmg, spec, o)
	o = o or {}
	for _, c in ipairs(victims(mob)) do
		local cr = rootOf(c)
		if cr and flat(cr.Position - pos).Magnitude <= r and math.abs(cr.Position.Y - pos.Y) < (o.height or 8) then
			if not (o.ground and not grounded(c)) then strike(mob, c, dmg, spec, pos, o) end
		end
	end
end

--------------------------------------------------------------------
--  THE BODY DURING A MOVE
--------------------------------------------------------------------
local function pose(mob, id) fxRemote:FireAllClients("Pose", mob.model, id) end
local function flash(mob, color, t) fxRemote:FireAllClients("Flash", mob.model, color, t or 0.6) end
local function shake(pos, power) fxRemote:FireAllClients("Shake", pos, power or 1) end
-- face this way (the bot's own facing loop turns it: bot.lookAt)
local function face(mob, pos)
	local r = rootOf(mob.model)
	if r then mob.bot.lookAt = flat(pos - r.Position) end
end
-- hold still for `t` (its fighting waits)
local function hold(mob, t)
	mob.bot.startAt = math.max(mob.bot.startAt or 0, now() + t)
	local h = mob.bot.hum
	if h then h:Move(Vector3.zero) end
end
local function anchor(mob, on)
	local r = rootOf(mob.model)
	if r then r.Anchored = on end
end
-- move the body (anchored) along a path over `t`: fn(a) -> CFrame
local function carry(mob, t, fn)
	local r = rootOf(mob.model)
	if not r then return end
	anchor(mob, true)
	local t0 = now()
	while now() - t0 < t and mob.alive and r.Parent do
		local a = math.clamp((now() - t0) / t, 0, 1)
		r.CFrame = fn(a)
		RunService.Heartbeat:Wait()
	end
	if r.Parent then r.CFrame = fn(1) end
	anchor(mob, false)
end

-- the one it aims at: the nearest (or, `far`, the furthest) of those who can be hurt
local function target(mob, far)
	local me = rootOf(mob.model)
	if not me then return nil end
	local best, bestD
	for _, c in ipairs(victims(mob)) do
		if Players:GetPlayerFromCharacter(c) then
			local r = rootOf(c)
			local d = r and (r.Position - me.Position).Magnitude
			if d and d < 120 and (not bestD or (far and d > bestD) or (not far and d < bestD)) then best, bestD = c, d end
		end
	end
	return best, bestD
end
local function playersNear(mob, range)
	local me = rootOf(mob.model)
	local out = {}
	if not me then return out end
	for _, c in ipairs(victims(mob)) do
		local r = rootOf(c)
		if r and Players:GetPlayerFromCharacter(c) and (r.Position - me.Position).Magnitude < (range or 90) then table.insert(out, c) end
	end
	return out
end
local function groundUnder(pos, mob)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = {folder, mob.model}
	local npcs = workspace:FindFirstChild("NPCs"); if npcs then table.insert(skip, npcs) end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(skip, p.Character) end end
	params.FilterDescendantsInstances = skip
	local hit = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -40, 0), params)
	return hit and hit.Position or Vector3.new(pos.X, pos.Y - 3, pos.Z)
end
local function wallParams(mob)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = {folder, mob.model}
	local npcs = workspace:FindFirstChild("NPCs"); if npcs then table.insert(skip, npcs) end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(skip, p.Character) end end
	for _, n in ipairs({"LootDrops", "LootFX", "DroppedWeapons"}) do local f = workspace:FindFirstChild(n); if f then table.insert(skip, f) end end
	params.FilterDescendantsInstances = skip
	return params
end

--------------------------------------------------------------------
--  THE MOVES
--------------------------------------------------------------------
local K = {}

K.slam = function(mob, spec)
	local fx = fxOf(spec, mob)
	local s = scaleOf(mob)
	local r = (spec.radius or 9) + 3 * s
	hold(mob, 1.6)
	pose(mob, "PwSlam")
	flash(mob, fx.glow, 1.1)
	local at = feet(mob)
	Moves.circle(at, r, fx.glow, 1.1)
	task.wait(1.1)
	if not mob.alive then return end
	at = feet(mob)
	sound(SND.boom, at, 1, 0.8)
	shake(at, 1.2)
	emitAt(at + Vector3.new(0, 1, 0), fx.glow, 60, 40, -30, nil, 1.2)
	for i = 0, 5 do local a = i / 6 * math.pi * 2; spike(at + Vector3.new(math.cos(a) * r * 0.6, 0, math.sin(a) * r * 0.6), fx, 4) end
	areaHit(mob, at, r, spec.dmg or 34, spec, {knock = 36})
end

K.shockwave = function(mob, spec)
	local fx = fxOf(spec, mob)
	local waves = spec.count or 2
	hold(mob, 1.4 + waves * 0.7)
	pose(mob, "PwSlam")
	flash(mob, fx.glow, 0.9)
	local at = feet(mob)
	Moves.circle(at, 5 + 2 * scaleOf(mob), fx.glow, 0.9)
	task.wait(0.9)
	for w = 1, waves do
		if not mob.alive then return end
		at = feet(mob)
		sound(SND.boom, at, 0.9, 0.7 + w * 0.08)
		shake(at, 0.9)
		-- the wall of force: segments in a ring, rolling out; whoever's on the ground as it passes
		local n, speed, maxR = 36, spec.speed or 34, spec.radius or 46
		local segs = {}
		for i = 1, n do
			local p = quiet(Instance.new("Part"))
			p.Material = Enum.Material.Neon; p.Color = fx.glow; p.Transparency = 0.25
			p.Size = Vector3.new(1.6, 1.5, 0.5)
			p.Parent = folder
			segs[i] = p
		end
		local hitOnce = {}
		local t0 = now()
		task.spawn(function()
			while true do
				local rr = 2 + (now() - t0) * speed
				if rr > maxR then break end
				for i, p in ipairs(segs) do
					local a = i / n * math.pi * 2
					local pos = at + Vector3.new(math.cos(a) * rr, 0.75, math.sin(a) * rr)
					p.Size = Vector3.new(math.max(1.6, rr * 2 * math.pi / n + 0.2), 1.5, 0.5)
					p.CFrame = CFrame.lookAt(pos, at + Vector3.new(0, 0.75, 0))
				end
				for _, c in ipairs(victims(mob)) do
					local cr = rootOf(c)
					if cr and not hitOnce[c] then
						local d = flat(cr.Position - at).Magnitude
						if math.abs(d - rr) < 2.2 and math.abs(cr.Position.Y - at.Y) < 7 then
							if grounded(c) then hitOnce[c] = true; strike(mob, c, spec.dmg or 22, spec, at, {knock = 26, lift = 26}) else hitOnce[c] = true end
						end
					end
				end
				RunService.Heartbeat:Wait()
			end
			for _, p in ipairs(segs) do p:Destroy() end
		end)
		task.wait(0.7)
	end
end

K.charge = function(mob, spec)
	local fx = fxOf(spec, mob)
	local tgt = target(mob)
	local me = rootOf(mob.model)
	if not (tgt and me) then return end
	local tr = rootOf(tgt)
	local dir = flat(tr.Position - me.Position)
	if dir.Magnitude < 1 then return end
	dir = dir.Unit
	local len = spec.length or 46
	-- (the lane stops at a wall: and so will it)
	local res = workspace:Raycast(me.Position, dir * len, wallParams(mob))
	local stopAt = res and math.max(4, (res.Position - me.Position).Magnitude - 2.5 * scaleOf(mob)) or len
	hold(mob, 2.6)
	face(mob, me.Position + dir * 10)
	pose(mob, "PwLunge")
	flash(mob, fx.glow, 1)
	Moves.lane(feet(mob), dir, stopAt, 5 + 2 * scaleOf(mob), fx.glow, 1)
	task.wait(1)
	if not mob.alive then return end
	sound(SND.lunge, me.Position, 1, 0.7)
	local start = me.CFrame
	local hit = {}
	local look = CFrame.lookAt(Vector3.zero, dir)
	carry(mob, stopAt / (spec.speed or 75), function(a)
		local pos = start.Position + dir * stopAt * a
		for _, c in ipairs(victims(mob)) do
			local cr = rootOf(c)
			if cr and not hit[c] and flat(cr.Position - pos).Magnitude < 3.5 + 1.5 * scaleOf(mob) then
				hit[c] = true
				strike(mob, c, spec.dmg or 32, spec, pos - dir * 2, {blockable = true, knock = 40, lift = 20})
			end
		end
		return CFrame.new(pos) * look.Rotation
	end)
	if res then
		-- into the wall: stunned, open
		local at = me.Position + dir * 2
		sound(SND.boom, at, 0.9, 1.1)
		shake(at, 0.8)
		emitAt(at + Vector3.new(0, 2, 0), Color3.fromRGB(255, 255, 255), 30, 20, -30, nil, 0.8)
		mob.model:SetAttribute("DazedUntil", workspace:GetServerTimeNow() + 2.6)
		mob.model:SetAttribute("GuardText", "STAGGERED"); mob.model:SetAttribute("GuardTick", (mob.model:GetAttribute("GuardTick") or 0) + 1)
		powers().addMods(mob.model, {taken = 1.3}, 2.6, "Staggered")
		hold(mob, 2.6)
		task.wait(2.6)
	end
end

K.leap = function(mob, spec)
	local fx = fxOf(spec, mob)
	local tgt = target(mob, spec.far)
	local me = rootOf(mob.model)
	if not (tgt and me) then return end
	local land = groundUnder(rootOf(tgt).Position, mob)
	local r = (spec.radius or 8) + 2 * scaleOf(mob)
	hold(mob, 2.6)
	face(mob, land)
	pose(mob, "PwLeap")
	flash(mob, fx.glow, 1)
	Moves.circle(land, r, fx.glow, 1.4)
	task.wait(0.6)
	if not mob.alive then return end
	local s = scaleOf(mob)
	local from = me.CFrame
	local to = land + Vector3.new(0, 3 * s, 0)
	local peak = math.max(from.Position.Y, to.Y) + 14
	local rot = CFrame.lookAt(Vector3.zero, flat(to - from.Position).Magnitude > 0.1 and flat(to - from.Position) or Vector3.new(0, 0, -1)).Rotation
	carry(mob, 0.8, function(a)
		local p = from.Position:Lerp(to, a)
		local y = (1 - a) * from.Position.Y + a * to.Y + 4 * (peak - math.max(from.Position.Y, to.Y)) * a * (1 - a)
		return CFrame.new(p.X, y, p.Z) * rot
	end)
	if not mob.alive then return end
	sound(SND.land, land, 1, 0.6)
	sound(SND.boom, land, 0.8, 0.9)
	shake(land, 1.4)
	emitAt(land + Vector3.new(0, 1, 0), fx.glow, 70, 45, -35, nil, 1.3)
	for i = 0, 7 do local a = i / 8 * math.pi * 2; spike(land + Vector3.new(math.cos(a) * r * 0.75, 0, math.sin(a) * r * 0.75), fx, 5) end
	areaHit(mob, land, r, spec.dmg or 38, spec, {knock = 40})
end

K.sweep = function(mob, spec)
	local fx = fxOf(spec, mob)
	local tgt = target(mob)
	local me = rootOf(mob.model)
	if not (tgt and me) then return end
	face(mob, rootOf(tgt).Position)
	hold(mob, 1.6)
	pose(mob, "PwSpin")
	flash(mob, fx.glow, 0.85)
	local s = scaleOf(mob)
	local r = (spec.radius or 11) + 3 * s
	local half = math.rad(spec.angle or 75)
	local dir = flat(rootOf(tgt).Position - me.Position)
	dir = dir.Magnitude > 0.1 and dir.Unit or me.CFrame.LookVector
	local base = CFrame.lookAt(feet(mob), feet(mob) + dir)
	Moves.arc(base, r, half, fx.glow, 0.85)
	task.wait(0.85)
	if not mob.alive then return end
	sound(SND.slash, me.Position, 1, 0.6)
	emitAt(me.Position + dir * r * 0.5, fx.glow, 40, 30, -10, nil, 1)
	for _, c in ipairs(victims(mob)) do
		local cr = rootOf(c)
		if cr then
			local to = flat(cr.Position - me.Position)
			if to.Magnitude <= r and to.Magnitude > 0.1 and math.acos(math.clamp(to.Unit:Dot(dir), -1, 1)) <= half + 0.1 then
				strike(mob, c, spec.dmg or 30, spec, me.Position, {blockable = true, knock = 34})
			end
		end
	end
end

K.spin = function(mob, spec)
	local fx = fxOf(spec, mob)
	local dur = spec.time or 3
	local me = rootOf(mob.model)
	if not me then return end
	hold(mob, dur + 1)
	pose(mob, "PwSpin")
	flash(mob, fx.glow, 0.7)
	Moves.circle(feet(mob), 7 + 2 * scaleOf(mob), fx.glow, 0.7)
	task.wait(0.7)
	local t0 = now()
	local lastHit = {}
	local r = 7 + 2 * scaleOf(mob)
	anchor(mob, true)
	local spinA = 0
	while now() - t0 < dur and mob.alive and me.Parent do
		local dt = RunService.Heartbeat:Wait()
		spinA += dt * 14
		local tgt = target(mob)
		local pos = me.Position
		if tgt then
			local to = flat(rootOf(tgt).Position - pos)
			if to.Magnitude > 2 then pos += to.Unit * math.min(to.Magnitude, (spec.speed or 9) * dt) end
		end
		me.CFrame = CFrame.new(pos) * CFrame.Angles(0, spinA, 0)
		if math.floor((now() - t0) * 8) % 2 == 0 then emitAt(pos, fx.glow, 4, 18, 0, nil, 0.5) end
		for _, c in ipairs(victims(mob)) do
			local cr = rootOf(c)
			if cr and flat(cr.Position - pos).Magnitude <= r and now() - (lastHit[c] or 0) > 0.55 then
				lastHit[c] = now()
				strike(mob, c, spec.dmg or 12, spec, pos, {blockable = true, knock = 22, lift = 10})
			end
		end
	end
	anchor(mob, false)
end

K.eruption = function(mob, spec)
	local fx = fxOf(spec, mob)
	local tgt = target(mob)
	local me = rootOf(mob.model)
	if not (tgt and me) then return end
	hold(mob, 1.4)
	face(mob, rootOf(tgt).Position)
	pose(mob, "PwCast")
	flash(mob, fx.glow, 0.7)
	local lines = spec.lines or 1
	for l = 1, lines do
		local tp = rootOf(tgt) and rootOf(tgt).Position or me.Position
		local dir = flat(tp - me.Position)
		if dir.Magnitude < 1 then dir = me.CFrame.LookVector end
		local spread = (l - (lines + 1) / 2) * 0.35
		dir = (CFrame.Angles(0, spread, 0) * dir.Unit)
		local from = feet(mob)
		local n = spec.count or 9
		for i = 1, n do
			local at = groundUnder(from + dir * (4 + i * 4.2), mob)
			task.delay((i - 1) * 0.11, function()
				Moves.circle(at, 2.6, fx.glow, 0.55)
				task.wait(0.55)
				if not mob.alive then return end
				spike(at, fx, 6 + (i % 3))
				areaHit(mob, at, 2.8, spec.dmg or 20, spec, {knock = 16, lift = 30})
			end)
		end
	end
	task.wait(0.6 + (spec.count or 9) * 0.11)
end

K.nova = function(mob, spec)
	local fx = fxOf(spec, mob)
	local list = playersNear(mob, 90)
	if #list == 0 then return end
	hold(mob, 1.5)
	pose(mob, "PwCast")
	flash(mob, fx.glow, 1.2)
	local r = spec.radius or 6
	for _, c in ipairs(list) do
		local at = groundUnder(rootOf(c).Position, mob)
		Moves.circle(at, r, fx.glow, 1.2)
		task.delay(1.2, function()
			if not mob.alive then return end
			sound(SND.boom, at, 0.6, 1.3)
			emitAt(at + Vector3.new(0, 1, 0), fx.glow, 50, 30, 10, nil, 1)
			spike(at, fx, 8)
			areaHit(mob, at, r, spec.dmg or 26, spec, {knock = 18, lift = 34})
		end)
	end
	task.wait(1.3)
end

K.rain = function(mob, spec, arena)
	local fx = fxOf(spec, mob)
	local me = rootOf(mob.model)
	if not me then return end
	if not spec.silent then hold(mob, 1.2); pose(mob, "PwSky"); flash(mob, fx.glow, 0.8) end
	local spots = {}
	for _, c in ipairs(playersNear(mob, 100)) do table.insert(spots, rootOf(c).Position) end
	local centre = arena and arena.centre or me.Position
	local radius = arena and arena.radius or 26
	for _ = 1, spec.count or 8 do
		local a, d = math.random() * 6.28, math.sqrt(math.random()) * radius * 0.85
		table.insert(spots, centre + Vector3.new(math.cos(a) * d, me.Position.Y, math.sin(a) * d))
	end
	local r = spec.radius or 4.5
	for i, p in ipairs(spots) do
		local at = groundUnder(Vector3.new(p.X, me.Position.Y, p.Z), mob)
		task.delay(i * 0.07, function()
			Moves.circle(at, r, fx.glow, 1.3)
			-- what falls: a stone of its colour, from high up
			local rock = quiet(Instance.new("Part"))
			rock.Shape = Enum.PartType.Ball
			rock.Material = fx.mat == Enum.Material.Ice and Enum.Material.Ice or Enum.Material.Neon
			rock.Color = fx.main
			rock.Size = Vector3.new(2.6, 2.6, 2.6)
			rock.CFrame = CFrame.new(at + Vector3.new(math.random(-8, 8), 42, math.random(-8, 8)))
			rock.Parent = folder
			local fire = Instance.new("Fire"); fire.Color = fx.glow; fire.SecondaryColor = fx.main; fire.Size = 4; fire.Parent = rock
			TweenService:Create(rock, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame = CFrame.new(at + Vector3.new(0, 1, 0))}):Play()
			Debris:AddItem(rock, 1.35)
			task.wait(1.3)
			emitAt(at + Vector3.new(0, 1, 0), fx.glow, 30, 26, -30, nil, 0.9)
			if i % 3 == 0 then sound(SND.boom, at, 0.5, 1.2) end
			if mob.model.Parent then areaHit(mob, at, r, spec.dmg or 18, spec, {knock = 14, lift = 24}) end
		end)
	end
	task.wait(1.5)
end

K.blink = function(mob, spec)
	local fx = fxOf(spec, mob)
	local tgt = target(mob, spec.far)
	local me = rootOf(mob.model)
	if not (tgt and me) then return end
	hold(mob, 2.4)
	flash(mob, fx.glow, 0.5)
	emitAt(me.Position, fx.glow, 50, 14, 6, "rbxasset://textures/particles/smoke_main.dds", 3)
	-- gone (every part out of sight a moment)
	local hidden = {}
	for _, d in ipairs(mob.model:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 then hidden[d] = d.Transparency; d.Transparency = 1 end
	end
	mob.model:SetAttribute("HiddenUntil", workspace:GetServerTimeNow() + 0.9)
	task.wait(0.8)
	if not mob.alive then for d, t in pairs(hidden) do d.Transparency = t end; return end
	local tr = rootOf(tgt)
	local behind = tr and (tr.Position - tr.CFrame.LookVector * (5 + 2 * scaleOf(mob))) or me.Position
	-- (not through a wall: a wall behind them, it comes out in front instead)
	if tr then
		local back = behind - tr.Position
		local hit = workspace:Raycast(tr.Position, back + back.Unit * 2, wallParams(mob))
		if hit then behind = tr.Position + tr.CFrame.LookVector * (5 + 2 * scaleOf(mob)) end
	end
	local land = groundUnder(behind, mob)
	mob.model:PivotTo(CFrame.lookAt(land + Vector3.new(0, 3 * scaleOf(mob) + 0.2, 0), Vector3.new(tr.Position.X, land.Y + 3 * scaleOf(mob), tr.Position.Z)))
	for d, t in pairs(hidden) do if d.Parent then d.Transparency = t end end
	mob.model:SetAttribute("HiddenUntil", nil)
	emitAt(land + Vector3.new(0, 3, 0), fx.glow, 50, 14, 6, "rbxasset://textures/particles/smoke_main.dds", 3)
	-- and swings at once (a short warning: turn round, dodge)
	K.sweep(mob, {name = spec.name, dmg = spec.dmg or 28, fx = spec.fx, radius = 8, angle = 70, burn = spec.burn, chill = spec.chill})
end

K.barrage = function(mob, spec)
	local fx = fxOf(spec, mob)
	local tgt = target(mob)
	local me = rootOf(mob.model)
	if not (tgt and me) then return end
	local volleys = spec.volleys or 2
	hold(mob, 0.8 + volleys * 0.6)
	face(mob, rootOf(tgt).Position)
	pose(mob, "PwCast")
	flash(mob, fx.glow, 0.6)
	task.wait(0.6)
	for v = 1, volleys do
		if not (mob.alive and tgt.Parent and rootOf(tgt)) then break end
		local from = me.Position + Vector3.new(0, 1.5 * scaleOf(mob), 0)
		local aim = rootOf(tgt).Position - from
		local n = spec.count or 5
		local spread = math.rad(spec.spread or 40)
		for i = 1, n do
			local a = (n == 1) and 0 or (-spread / 2 + spread * (i - 1) / (n - 1))
			local dir = (CFrame.Angles(0, a, 0) * aim.Unit)
			local bolt = quiet(Instance.new("Part"))
			bolt.Shape = Enum.PartType.Ball
			bolt.Material = Enum.Material.Neon; bolt.Color = fx.glow
			bolt.Size = Vector3.new(1.2, 1.2, 1.2)
			bolt.Position = from
			bolt.Parent = folder
			local l = Instance.new("PointLight"); l.Color = fx.glow; l.Range = 8; l.Brightness = 1.5; l.Parent = bolt
			local att0 = Instance.new("Attachment"); att0.Position = Vector3.new(0, 0.4, 0); att0.Parent = bolt
			local att1 = Instance.new("Attachment"); att1.Position = Vector3.new(0, -0.4, 0); att1.Parent = bolt
			local trail = Instance.new("Trail"); trail.Attachment0 = att0; trail.Attachment1 = att1; trail.Color = ColorSequence.new(fx.glow)
			trail.Lifetime = 0.25; trail.LightEmission = 1; trail.Transparency = NumberSequence.new(0.2, 1); trail.Parent = bolt
			task.spawn(function()
				local t0 = now()
				local pos = from
				local speed = spec.speed or 55
				while now() - t0 < 2.2 and bolt.Parent do
					local dt = RunService.Heartbeat:Wait()
					local step = dir * speed * dt
					local res = workspace:Raycast(pos, step, wallParams(mob))
					pos += step
					bolt.Position = pos
					for _, c in ipairs(victims(mob)) do
						local cr = rootOf(c)
						if cr and (cr.Position - pos).Magnitude < 2.6 then
							strike(mob, c, spec.dmg or 12, spec, pos - dir, {knock = 12, lift = 8})
							emitAt(pos, fx.glow, 14, 14, 0, nil, 0.6)
							bolt:Destroy()
							return
						end
					end
					if res then emitAt(res.Position, fx.glow, 10, 10, 0, nil, 0.5); break end
				end
				if bolt.Parent then bolt:Destroy() end
			end)
		end
		task.wait(0.6)
	end
end

K.beam = function(mob, spec)
	local fx = fxOf(spec, mob)
	local tgt = target(mob)
	local me = rootOf(mob.model)
	if not (tgt and me) then return end
	local dur = spec.time or 2.4
	local sweep = math.rad(spec.sweep or 110)
	local len = spec.length or 60
	local dir0 = flat(rootOf(tgt).Position - me.Position)
	dir0 = dir0.Magnitude > 0.1 and dir0.Unit or me.CFrame.LookVector
	local side = math.random() < 0.5 and 1 or -1
	local startDir = CFrame.Angles(0, -side * sweep / 2, 0) * dir0
	hold(mob, dur + 1.6)
	pose(mob, "PwCast")
	flash(mob, fx.glow, 1.1)
	face(mob, me.Position + startDir * 10)
	Moves.lane(feet(mob), startDir, len, 2.5, fx.glow, 1.1)
	task.wait(1.1)
	if not mob.alive then return end
	local beam = quiet(Instance.new("Part"))
	beam.Material = Enum.Material.Neon; beam.Color = fx.glow; beam.Transparency = 0.15
	beam.Parent = folder
	local core = quiet(Instance.new("Part"))
	core.Material = Enum.Material.Neon; core.Color = Color3.new(1, 1, 1); core.Transparency = 0.1
	core.Parent = folder
	local lastHit = {}
	local t0 = now()
	anchor(mob, true)
	while now() - t0 < dur and mob.alive do
		RunService.Heartbeat:Wait()
		local a = (now() - t0) / dur
		local dir = CFrame.Angles(0, side * sweep * a, 0) * startDir
		local from = me.Position + Vector3.new(0, 1.2 * scaleOf(mob), 0) + dir * 2
		local res = workspace:Raycast(from, dir * len, wallParams(mob))
		local l = res and (res.Position - from).Magnitude or len
		beam.Size = Vector3.new(2.2, 2.2, l); beam.CFrame = CFrame.lookAt(from + dir * l / 2, from + dir * l)
		core.Size = Vector3.new(0.8, 0.8, l); core.CFrame = beam.CFrame
		me.CFrame = CFrame.lookAt(me.Position, me.Position + dir)
		if res then emitAt(res.Position, fx.glow, 3, 10, 0, nil, 0.6) end
		for _, c in ipairs(victims(mob)) do
			local cr = rootOf(c)
			if cr and now() - (lastHit[c] or 0) > 0.35 then
				local rel = cr.Position - from
				local along = rel:Dot(dir)
				if along > 0 and along < l and (rel - dir * along).Magnitude < 2.6 then
					lastHit[c] = now()
					strike(mob, c, spec.dmg or 10, spec, cr.Position - dir, {knock = 10, lift = 6})
				end
			end
		end
	end
	anchor(mob, false)
	beam:Destroy(); core:Destroy()
end

K.roar = function(mob, spec)
	local fx = fxOf(spec, mob)
	hold(mob, 1.8)
	pose(mob, "PwRoar")
	flash(mob, Color3.fromRGB(255, 60, 40), 1.4)
	local at = feet(mob)
	Moves.circle(at, 12 + 3 * scaleOf(mob), fx.glow, 0.8)
	task.wait(0.8)
	sound(SND.boom, at, 1, 0.55)
	shake(at, 2)
	emitAt(at + Vector3.new(0, 3, 0), fx.glow, 90, 50, 0, nil, 1.5)
	areaHit(mob, at, 12 + 3 * scaleOf(mob), spec.dmg or 10, spec, {knock = 55, lift = 24})
	task.wait(0.8)
end
Moves.KINDS = K

--------------------------------------------------------------------
--  THE LOOP
--------------------------------------------------------------------
local function usable(mob, spec, phase, dist)
	if (spec.phase or 1) > phase then return false end
	if now() < (mob.moveReady[spec] or 0) then return false end
	local rg = spec.range
	if rg and dist and (dist < (rg[1] or 0) or dist > (rg[2] or 999)) then return false end
	return K[spec.kind] ~= nil
end

function Moves.run(mob, arena)
	local def = mob.def
	local list = mob.moves or def.moves
	if not (list and #list > 0) then return end
	mob.moveReady = {}
	local boss = mob.boss
	-- (the first few seconds: its blade first, so the fight starts as a fight)
	for _, spec in ipairs(list) do mob.moveReady[spec] = now() + (spec.first or (boss and 4 or 6)) + math.random() * 2 end
	task.spawn(function()
		task.wait(boss and 3 or 4)
		local phase = 1
		local hazardAt = 0
		while mob.alive and mob.model.Parent do
			-- the second phase
			if boss and phase == 1 and mob.model:GetAttribute("BossPhase") == 2 then
				phase = 2
				fxRemote:FireAllClients("Phase", mob.model, def.phaseLine or "ITS FURY IS UNLEASHED")
				pcall(K.roar, mob, {name = "Roar", fx = def.moveFx})
				mob.bot.startAt = now()
				mob.bot.lookAt = nil
				hazardAt = now() + 2
			end
			-- phase two's hazard: the arena turns on you, on its own clock
			if phase == 2 and def.hazard and now() >= hazardAt then
				hazardAt = now() + (def.hazard.every or 9)
				local hz = table.clone(def.hazard)
				hz.silent = true
				task.spawn(function() pcall(K[hz.kind or "rain"], mob, hz, arena) end)
			end
			local gap = boss and (phase == 2 and 2.6 or 4) or 6
			task.wait(gap * (0.8 + math.random() * 0.4))
			if not mob.alive then break end
			local me = rootOf(mob.model)
			local tgt, dist = target(mob)
			if me and tgt and not mob.model:GetAttribute("Ragdolled") then
				-- what it can do now, by weight
				local pool, total = {}, 0
				for _, spec in ipairs(list) do
					if usable(mob, spec, phase, dist) then table.insert(pool, spec); total += spec.weight or 1 end
				end
				if #pool > 0 then
					local x = math.random() * total
					local pickd = pool[1]
					for _, spec in ipairs(pool) do x -= spec.weight or 1; if x <= 0 then pickd = spec; break end end
					mob.moveReady[pickd] = now() + (pickd.cd or 10) * (phase == 2 and 0.75 or 1)
					mob.model:SetAttribute("BossMove", pickd.name)
					local ok, err = pcall(K[pickd.kind], mob, pickd, arena)
					if not ok then warn("[BossMoves]", pickd.kind, err) end
					mob.model:SetAttribute("BossMove", nil)
					if mob.alive then
						anchor(mob, false)
						mob.bot.lookAt = nil
						mob.bot.startAt = math.min(mob.bot.startAt or 0, now() + 0.2)
					end
				end
			end
		end
	end)
end

return Moves
