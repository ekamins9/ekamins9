--[[ TRAPS — what the dungeon's builders left in its corridors (The Depths, Deadvault): on a
     generated floor (Game ▸ Dungeon's layout.corridors), set once the map is loaded.

       spikes     a grate of iron slots in the floor: step on it and it clicks, and half a
                  second later spikes punch up through it (step off fast, keep to the wall beside
                  it, or jump it)
       blade      a great crescent blade swinging from the ceiling across the corridor (two in a
                  long one, out of step): time it
       darts      a plate right across the corridor: step on it and darts hiss out of the holes
                  in one wall (jump it)
       flames     two grates side by side that breathe fire in turn (the Ember Forge's, the
                  Warrens'): cross on the cool side

     Each shows itself (a grate, a plate, holes in a wall, a blade you hear) and has a way past.
     They hurt anyone who blunders in, monsters on the hunt too (a calm one knows its own dungeon). The server decides every hit; every screen
     draws the moving parts (StarterPlayerScripts ▸ Traps.client: a blade swings on the server's
     clock, so every screen sees it in the same place).

       Traps.arm(map, layout, opts)   opts.count (how many corridors), opts.theme, opts.skip
                                      ({[room id] = true}: their corridors stay clear)
       Traps.disarm()

     A trap is a Model in Map ▸ Traps with the attribute Trap (its kind) and what its screen needs:
       blade    Pivot (Vector3), Cross (Vector3: the way it swings), Arm, Amp (radians), Period,
                Phase (all on the server's clock: workspace:GetServerTimeNow())
       spikes   FiredAt (server time of the click; the spikes are up from +RISE to +HOLD)
       darts    FiredAt, Side (+1 | -1: which wall they come out of, along Cross), Cross
       flames   the server lights its fire itself ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatServer = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatServer"))

local Traps = {}
local V3, CF = Vector3.new, CFrame.new
local UP = V3(0, 1, 0)

-- what each kind does, and how often each theme reaches for it
Traps.SPIKES = {dmg = 26, rise = 0.5, hold = 1.6, rearm = 3}
Traps.BLADE = {dmg = 30, knock = 42, again = 1.2}
Traps.DARTS = {dmg = 18, delay = 0.18, rearm = 4}
Traps.FLAMES = {dmg = 9, every = 0.5, period = 4.4, warn = 0.9, burn = 1.7}
local WEIGHTS = {
	BoneCrypt = {spikes = 3, blade = 3, darts = 2},
	GoblinWarrens = {darts = 3, spikes = 3, flames = 2, blade = 1},
	CrimsonManor = {blade = 3, darts = 3, spikes = 2},
	FrozenDepths = {spikes = 3, blade = 2, darts = 2},
	EmberForge = {flames = 4, spikes = 2, blade = 2, darts = 1},
	DrownedHalls = {blade = 3, spikes = 3, darts = 2},
	HollowAbbey = {blade = 3, darts = 3, spikes = 2},
}
local IRON, DARK = Color3.fromRGB(70, 70, 76), Color3.fromRGB(26, 24, 24)
local DODGE_IFRAMES = 0.45

local live = {conn = nil, traps = {}, map = nil}

local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function clock() return workspace:GetServerTimeNow() end

local function piece(parent, name, size, cf, color, mat, class)
	local p = Instance.new(class or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.Metal
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- everyone who might be caught: players, and monsters on the hunt (a monster the dark is keeping
-- calm, walking its patrol or waiting in its room: Perceives without an Alert "!", knows its own
-- dungeon's traps and steps round them)
local function bodies()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = humOf(c)
		if h and h.Health > 0 and rootOf(c) then table.insert(out, c) end
	end
	local npcs = workspace:FindFirstChild("NPCs")
	for _, m in ipairs(npcs and npcs:GetChildren() or {}) do
		local h = humOf(m)
		local calm = m:GetAttribute("Perceives") and m:GetAttribute("Alert") ~= "!"
		if h and h.Health > 0 and rootOf(m) and not calm then table.insert(out, m) end
	end
	return out
end

-- a trap's bite: armour turns some of it; a dodge's moment slips it; spawn protection too
local function harm(c, dmg, from, push)
	local h, r = humOf(c), rootOf(c)
	if not (h and r) or h.Health <= 0 or CombatServer.isProtected(c) then return false end
	if os.clock() - (c:GetAttribute("LastDodgeAt") or -1e9) < DODGE_IFRAMES then
		c:SetAttribute("GuardText", "DODGED"); c:SetAttribute("GuardTick", (c:GetAttribute("GuardTick") or 0) + 1)
		return false
	end
	dmg *= 1 - 0.5 * math.clamp(c:GetAttribute("ArmorProtection") or 0, 0, 0.9)
	CombatServer.markCombat(c)
	local away = from and V3(r.Position.X - from.X, 0, r.Position.Z - from.Z)
	if away and away.Magnitude > 0.1 then CombatServer.flinch(c, away.Unit) end
	CombatServer.showDamage(nil, c, dmg, nil, dmg >= h.Health, false)
	h:TakeDamage(dmg)
	if push then
		local att = Instance.new("Attachment"); att.Name = "TrapShove"; att.Parent = r
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = att; lv.MaxForce = 4e5; lv.VectorVelocity = push
		lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = r
		task.delay(0.2, function() lv:Destroy(); att:Destroy() end)
	end
	return true
end

-- on the ground inside a rectangle on the floor (centre, the way the corridor runs `T`, half its
-- length along T, half its width across)
local function onPlate(c, at, T, halfL, halfW)
	local r, h = rootOf(c), humOf(c)
	local rel = r.Position - at
	local along = rel:Dot(T)
	local across = (rel - T * along - UP * rel.Y).Magnitude
	if math.abs(along) > halfL or across > halfW then return false end
	-- (in the air over it: jumped)
	return rel.Y < 4.6 and h.FloorMaterial ~= Enum.Material.Air
end

--------------------------------------------------------------------
--  THE KINDS (each builds itself and returns its step)
--------------------------------------------------------------------
local BUILD = {}

-- SPIKES: a grate of slots, spikes waiting under it
function BUILD.spikes(folder, at, T, C, ceil, rng, theme)
	local m = Instance.new("Model")
	m.Name = "SpikeTrap"
	m:SetAttribute("Trap", "spikes")
	local halfL, halfW = 3, 4
	local frame = CFrame.fromMatrix(at, C, UP)   -- (X across, Z along)
	piece(m, "Grate", V3(halfW * 2, 0.14, halfL * 2), frame * CF(0, 0.07, 0), IRON, Enum.Material.DiamondPlate)
	local tip = theme == "FrozenDepths" and Color3.fromRGB(170, 206, 232) or Color3.fromRGB(84, 84, 90)
	for i = 0, 3 do
		for j = 0, 4 do
			local x, z = -halfW + 1 + i * (halfW * 2 - 2) / 3, -halfL + 0.6 + j * (halfL * 2 - 1.2) / 4
			piece(m, "Slot", V3(0.55, 0.02, 0.55), frame * CF(x, 0.15, z), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
			-- (a point: down out of sight under the floor; the screen raises it)
			local s = piece(m, "Spike", V3(0.45, 3, 0.45), frame * CF(x, -2.4, z) * CFrame.Angles(0, math.rad(45 + (i + j) * 90), 0), tip, theme == "FrozenDepths" and Enum.Material.Ice or Enum.Material.Metal, "CornerWedgePart")
			s.CastShadow = false
		end
	end
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.Parent = folder
	local cfg = Traps.SPIKES
	local firedAt, hurt = nil, {}
	return function(now, list)
		if firedAt then
			local t = now - firedAt
			if t >= cfg.rise and t < cfg.hold then
				for _, c in ipairs(list) do
					if not hurt[c] and onPlate(c, at, T, halfL + 0.4, halfW + 0.4) then
						hurt[c] = true
						harm(c, cfg.dmg, nil, UP * 26)
					end
				end
			elseif t >= cfg.rearm then
				firedAt, hurt = nil, {}
			end
			return
		end
		for _, c in ipairs(list) do
			if onPlate(c, at, T, halfL, halfW) then
				firedAt = now
				m:SetAttribute("FiredAt", now)
				return
			end
		end
	end
end

-- BLADE: a crescent on an iron arm, swinging across from a slot in the ceiling
function BUILD.blade(folder, at, T, C, ceil, rng, theme, phase)
	local m = Instance.new("Model")
	m.Name = "BladeTrap"
	m:SetAttribute("Trap", "blade")
	local arm = ceil - 3.4
	local pivot = at + UP * (ceil - 0.4)
	local amp, period = 0.56, rng:NextNumber(2.6, 3.4)
	m:SetAttribute("Pivot", pivot)
	m:SetAttribute("Cross", C)
	m:SetAttribute("Arm", arm)
	m:SetAttribute("Amp", amp)
	m:SetAttribute("Period", period)
	m:SetAttribute("Phase", phase or rng:NextNumber(0, math.pi * 2))
	-- (built hanging straight down; every screen swings it. Pieces in the swing's own frame: X
	-- across, Y up, Z along the corridor)
	local frame = CFrame.fromMatrix(pivot, C, UP)
	piece(m, "Slot", V3(13, 0.1, 0.8), frame * CF(0, 0.38, 0), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
	piece(m, "Hub", V3(1, 1, 1), frame, IRON)
	piece(m, "Arm", V3(0.35, arm, 0.35), frame * CF(0, -arm / 2, 0), IRON)
	local steel = Color3.fromRGB(176, 178, 184)
	piece(m, "Blade", V3(4.2, 1.1, 0.22), frame * CF(0, -arm - 0.2, 0), steel)
	piece(m, "BladeTip", V3(1.8, 0.8, 0.2), frame * CF(-2.6, -arm + 0.25, 0) * CFrame.Angles(0, 0, math.rad(-32)), steel)
	piece(m, "BladeTip", V3(1.8, 0.8, 0.2), frame * CF(2.6, -arm + 0.25, 0) * CFrame.Angles(0, 0, math.rad(32)), steel)
	piece(m, "BladeBack", V3(3.4, 0.5, 0.3), frame * CF(0, -arm + 0.5, 0), IRON)
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.Parent = folder
	local cfg = Traps.BLADE
	local last = {}
	local ph = m:GetAttribute("Phase")
	return function(now, list)
		local th = amp * math.sin(now / period * math.pi * 2 + ph)
		local centre = pivot + C * (math.sin(th) * (arm + 0.2)) - UP * (math.cos(th) * (arm + 0.2))
		local sweep = math.cos(now / period * math.pi * 2 + ph) >= 0 and 1 or -1
		for _, c in ipairs(list) do
			local r = rootOf(c)
			local rel = r.Position - centre
			if math.abs(rel:Dot(T)) < 1.4 and (not last[c] or now - last[c] > cfg.again) then
				-- (the body, feet to head: 3 below its root to 2 above, the blade half a stud tall)
				local across = rel:Dot(C)
				if math.abs(across) < 3 and rel.Y > -2.5 and rel.Y < 3.5 then
					last[c] = now
					harm(c, cfg.dmg, centre, C * (sweep * cfg.knock) + UP * 14)
				end
			end
		end
	end
end

-- DARTS: a plate right across, holes in one wall
function BUILD.darts(folder, at, T, C, ceil, rng, theme)
	local m = Instance.new("Model")
	m.Name = "DartTrap"
	m:SetAttribute("Trap", "darts")
	local side = rng:NextNumber() < 0.5 and 1 or -1
	m:SetAttribute("Side", side)
	m:SetAttribute("Cross", C)
	local frame = CFrame.fromMatrix(at, C, UP)
	local halfL, halfW = 1.3, 6
	piece(m, "Plate", V3(halfW * 2 - 0.2, 0.16, halfL * 2), frame * CF(0, 0.08, 0), Color3.fromRGB(58, 54, 50), Enum.Material.Slate)
	piece(m, "PlateSeam", V3(halfW * 2 - 0.2, 0.17, 0.12), frame * CF(0, 0.08, halfL), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
	piece(m, "PlateSeam", V3(halfW * 2 - 0.2, 0.17, 0.12), frame * CF(0, 0.08, -halfL), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
	for k = -1, 1 do
		for h = 0, 1 do
			local hole = piece(m, "DartHole", V3(0.08, 0.3, 0.3), frame * CF(side * (halfW - 0.02), 2.6 + h * 1.6, k * 1.4), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
			hole:SetAttribute("Lane", k)
		end
	end
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.Parent = folder
	local cfg = Traps.DARTS
	local firedAt, done = nil, false
	return function(now, list)
		if firedAt then
			if not done and now - firedAt >= cfg.delay then
				done = true
				-- (the darts cross the whole corridor about the plate: anyone in that stretch, on
				-- the ground or not)
				for _, c in ipairs(list) do
					local rel = rootOf(c).Position - at
					if math.abs(rel:Dot(T)) < 2.6 and rel.Y < 5.5 then harm(c, cfg.dmg, at + C * side * 6) end
				end
			end
			if now - firedAt >= cfg.rearm then firedAt, done = nil, false end
			return
		end
		for _, c in ipairs(list) do
			if onPlate(c, at, T, halfL, halfW) then
				firedAt = now
				m:SetAttribute("FiredAt", now)
				return
			end
		end
	end
end

-- FLAMES: two round grates side by side, breathing fire in turn
function BUILD.flames(folder, at, T, C, ceil, rng, theme)
	local m = Instance.new("Model")
	m.Name = "FlameTrap"
	m:SetAttribute("Trap", "flames")
	local cfg = Traps.FLAMES
	local vents = {}
	local src = ReplicatedStorage:FindFirstChild("WarAudio")
	src = src and src:FindFirstChild("Fire")
	for i, s in ipairs({-1, 1}) do
		local c = at + C * (s * 3)
		local g = piece(m, "Vent", V3(0.16, 5.2, 5.2), CF(c + UP * 0.08) * CFrame.Angles(0, 0, math.pi / 2), IRON, Enum.Material.Metal)
		g.Shape = Enum.PartType.Cylinder
		-- (an iron grate: bars across the hole)
		for k = -2, 2 do
			piece(m, "VentBar", V3(0.3, 0.2, 4.4 - math.abs(k) * 0.7), CF(c + C * (k * 0.8) + UP * 0.2) * CFrame.fromMatrix(Vector3.zero, C, UP), IRON, Enum.Material.Metal)
		end
		local glow = piece(m, "VentGlow", V3(0.18, 4.4, 4.4), CF(c + UP * 0.1) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 110, 30), Enum.Material.Neon)
		glow.Shape = Enum.PartType.Cylinder
		glow.Transparency = 1
		-- (the dark below the bars, while it's cold)
		local pit = piece(m, "VentPit", V3(0.17, 4.4, 4.4), CF(c + UP * 0.09) * CFrame.Angles(0, 0, math.pi / 2), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
		pit.Shape = Enum.PartType.Cylinder
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/fire_main.dds"
		e.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 170)), ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 150, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 10))})
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Brightness = 3
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(0.5, 3.2), NumberSequenceKeypoint.new(1, 1)})
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.7, 0.4), NumberSequenceKeypoint.new(1, 1)})
		e.Lifetime = NumberRange.new(0.4, 0.6)
		e.Speed = NumberRange.new(18, 24)
		e.SpreadAngle = Vector2.new(7, 7)
		e.RotSpeed = NumberRange.new(-90, 90)
		e.Rotation = NumberRange.new(0, 360)
		e.Rate = 120
		e.EmissionDirection = Enum.NormalId.Right
		e.Enabled = false
		e.Parent = glow
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Enabled = Color3.fromRGB(255, 130, 50), 16, 2.4, false
		l.Parent = glow
		local snd
		if src and src:IsA("Sound") then
			snd = src:Clone()
			snd.Looped = true
			snd.Volume = src.Volume * 0.7
			snd.RollOffMode = Enum.RollOffMode.InverseTapered
			snd.RollOffMinDistance, snd.RollOffMaxDistance = 10, 70
			snd.Parent = glow
		end
		vents[i] = {at = c, glow = glow, e = e, l = l, snd = snd, off = (i - 1) * 0.5, state = nil, last = {}}
	end
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.Parent = folder
	local base = rng:NextNumber(0, cfg.period)
	return function(now, list)
		for _, v in ipairs(vents) do
			local t = (now + base + v.off * cfg.period) % cfg.period
			local state = (t < cfg.warn and "warn") or (t < cfg.warn + cfg.burn and "burn") or nil
			if state ~= v.state then
				v.state = state
				v.glow.Transparency = (state == "warn" and 0.45) or (state == "burn" and 0.05) or 1
				v.e.Enabled = state == "burn"
				v.l.Enabled = state ~= nil
				v.l.Brightness = state == "burn" and 2.6 or 0.9
				if v.snd then if state == "burn" then v.snd:Play() else v.snd:Stop() end end
			end
			if state == "burn" then
				for _, c in ipairs(list) do
					local rel = rootOf(c).Position - v.at
					if V3(rel.X, 0, rel.Z).Magnitude < 2.9 and rel.Y < 8 and (not v.last[c] or now - v.last[c] >= cfg.every) then
						v.last[c] = now
						harm(c, cfg.dmg, nil, nil)
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------
--  SETTING THEM
--------------------------------------------------------------------
local function pick(rng, weights)
	local total = 0
	for _, w in pairs(weights) do total += w end
	local x = rng:NextNumber(0, total)
	for k, w in pairs(weights) do
		x -= w
		if x <= 0 then return k end
	end
	return next(weights)
end

function Traps.disarm()
	if live.conn then live.conn:Disconnect(); live.conn = nil end
	live.traps, live.map = {}, nil
end

function Traps.arm(map, layout, opts)
	Traps.disarm()
	opts = opts or {}
	if not (map and layout and layout.corridors) then return 0 end
	-- (each trap streams to a screen whole, all its parts at once: Atomic below)
	local rng = Random.new()
	local ceil = require(script.Parent:WaitForChild("Dungeon")).CORR_H or 14
	local folder = map:FindFirstChild("Traps") or Instance.new("Folder")
	folder:ClearAllChildren()
	folder.Name = "Traps"
	folder.Parent = map
	local weights = WEIGHTS[opts.theme or layout.theme or ""] or WEIGHTS.BoneCrypt
	local skip = opts.skip or {}
	-- the corridors long enough, away from the rooms kept clear, in a random order
	local pool = {}
	for _, c in ipairs(layout.corridors) do
		if c.len >= 14 and not skip[c.a] and not skip[c.b] then table.insert(pool, c) end
	end
	for i = #pool, 2, -1 do local j = rng:NextInteger(1, i); pool[i], pool[j] = pool[j], pool[i] end
	local ground = RaycastParams.new()
	ground.FilterType = Enum.RaycastFilterType.Include
	ground.FilterDescendantsInstances = {map}
	local steps = {}
	for i = 1, math.min(opts.count or 2, #pool) do
		local c = pool[i]
		local T = c.axis == "X" and V3(1, 0, 0) or V3(0, 0, 1)
		local C = c.axis == "X" and V3(0, 0, 1) or V3(1, 0, 0)
		local kind = pick(rng, weights)
		local function at(off)
			local p = c.mid + T * off
			local hit = workspace:Raycast(p + UP * 6, -UP * 14, ground)
			return hit and V3(p.X, hit.Position.Y, p.Z) or p
		end
		local room = math.max(0, c.len / 2 - 5)
		if kind == "blade" and c.len >= 26 then
			-- (a long corridor: two, out of step)
			local ph = rng:NextNumber(0, math.pi * 2)
			table.insert(steps, BUILD.blade(folder, at(-3.5), T, C, ceil, rng, layout.theme, ph))
			table.insert(steps, BUILD.blade(folder, at(3.5), T, C, ceil, rng, layout.theme, ph + math.pi * 0.6))
		else
			table.insert(steps, BUILD[kind](folder, at(rng:NextNumber(-room, room) * 0.6), T, C, ceil, rng, layout.theme))
		end
	end
	live.map, live.traps = map, steps
	if #steps == 0 then return 0 end
	local acc = 0
	live.conn = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 / 20 then return end
		acc = 0
		if not map.Parent then Traps.disarm(); return end
		local now = clock()
		local list = bodies()
		for _, step in ipairs(steps) do
			local ok, err = pcall(step, now, list)
			if not ok then warn("[Traps]", err) end
		end
	end)
	return #steps
end

return Traps
