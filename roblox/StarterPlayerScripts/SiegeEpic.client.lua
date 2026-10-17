--[[ SIEGE EPIC — the war round the castle in a Siege, on your screen only (ReplicatedStorage ▸
     WarCrowd and WarFX: never fighters, nothing replicated):

       the walls      the defenders' archers lining the front wall, loosing on the field
       the ladders    ladders against the wall, men swarming up them under a roof of raised
                      shields; some go over the top, some are thrown off
       the towers     two siege towers roll slowly up to the side walls, pushed by their crews,
                      dock against them, and men climb up inside and over onto the walls
       the flanks     the battle fought out on both sides before the walls: the defenders' sally
                      against the attackers' lines, charging, crashing, falling
       behind         the attackers' archers loosing on the walls, their reserves by the camp
       the castle     towers burning, smoke rising high, trebuchet fire falling on the walls,
                      villages burning beyond; dust over the melee, the din of it all

     The story follows the objective (Round ▸ ObjStage): as the gate falls the walls are
     overrun (the attackers cheer, the archers fall, the ladders all go over, the reserves pour
     in, the sally is driven back to the walls); as the great hall is stormed its roof catches.
     The winners cheer at the end, the camera rising and circling slowly over the castle a few
     seconds before the board comes up. Only while the round's Mode is "Siege", on a castle that
     faces along z (a gate in Map ▸ Objectives, Walk and Wall parts in Map ▸ Geometry). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local WarCrowd = require(ReplicatedStorage:WaitForChild("WarCrowd"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))

local player = Players.LocalPlayer
local round = ReplicatedStorage:WaitForChild("Round")

local V3, CF = Vector3.new, CFrame.new
local DUST = Color3.fromRGB(150, 136, 116)

local function phone() return Device.kind() == "phone" end
local function inSiege() return round:GetAttribute("Mode") == "Siege" end
local function other(t) return t == "A" and "B" or "A" end
local function myPos()
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return r and r.Position or nil
end

local siege = {on = false, token = 0}

--------------------------------------------------------------------
--  THE CASTLE (read from the map)
--------------------------------------------------------------------
-- (the server reads the castle once and describes it on the Map: Siege.describeCastle; a client
-- streams the map in bit by bit and can't count on seeing all of it)
local function readCastle()
	local m = workspace:FindFirstChild("Map")
	local gate = m and m:GetAttribute("C_Gate")
	if typeof(gate) ~= "Vector3" then return nil end
	local function A(k) return m:GetAttribute("C_" .. k) end
	local C = {gate = gate, att = A("Att"), f = A("F") or 1, faceZ = A("FaceZ"), top = A("Top"), ground = A("Ground") or 0,
		half = A("Half") or 40, bound = A("Bound") or 300, spans = {}, towers = {}, fires = {}, defs = {}, roof = A("Roof"),
		sideX = A("SideX"), sideY = A("SideY"), sideZ = A("SideZ"), towerYaw = A("TowerYaw")}
	if typeof(C.att) ~= "Vector3" or not C.faceZ or not C.top then return nil end
	for i = 1, A("Spans") or 0 do
		local a, x1 = A("Span" .. i), A("SpanEnd" .. i)
		if typeof(a) == "Vector3" and x1 then table.insert(C.spans, {x0 = a.X, x1 = x1, y = a.Y, z = a.Z}) end
	end
	for i = 1, A("Towers") or 0 do
		local t = A("Tower" .. i)
		if typeof(t) == "Vector3" then table.insert(C.towers, {top = t}) end
	end
	for i = 1, A("Defs") or 0 do
		local d = A("Def" .. i)
		if typeof(d) == "Vector3" then table.insert(C.defs, d) end
	end
	if #C.spans == 0 then return nil end
	-- what burns: two towers away from the gate, by chance (the hall's roof later)
	local far = {}
	for _, t in ipairs(C.towers) do if math.abs(t.top.X - gate.X) > 30 then table.insert(far, t.top) end end
	for _ = 1, math.min(2, #far) do table.insert(C.fires, table.remove(far, math.random(#far))) end
	return C
end

--------------------------------------------------------------------
--  BUILDING IT
--------------------------------------------------------------------
local function ladderModel(home, from, to)
	local up = to - from
	local len = up.Magnitude
	local frame = CFrame.lookAt(from + up / 2, to)
	local wood = Color3.fromRGB(96, 70, 46)
	local function bit(size, cf)
		local p = Instance.new("Part")
		p.Size = size
		p.CFrame = cf
		p.Color, p.Material = wood, Enum.Material.Wood
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, true
		p.Parent = home
	end
	for _, x in ipairs({-0.95, 0.95}) do bit(V3(0.32, 0.32, len + 1), frame * CF(x, 0, 0)) end
	for k = 1, math.floor(len / 1.4) do bit(V3(1.9, 0.18, 0.22), frame * CF(0, 0, len / 2 - k * 1.4)) end
end

local function build(C)
	WarCrowd.SCALE = phone() and 0.6 or 1
	local crowd = WarCrowd.new()
	siege.crowd = crowd
	siege.C = C
	local A = round:GetAttribute("Attackers") or "A"
	local D = other(A)
	siege.A, siege.D = A, D
	local f = C.f
	local small = phone()
	-- THE WALLS: the defenders' archers along each open stretch of the front walk
	siege.walls = {}
	for i, sp in ipairs(C.spans) do
		local w = sp.x1 - sp.x0
		local id = "wall" .. i
		local at = V3((sp.x0 + sp.x1) / 2, sp.y, sp.z - f * 0.4)
		crowd:regiment(id, {side = D, kind = "archer", at = at, facing = f, cols = math.max(2, math.floor((w - 3) / 2.6)), ranks = 1,
			spacing = 2.6, detail = "lite", banner = false, fixed = true})
		table.insert(siege.walls, {id = id, at = at, w = w})
	end
	-- THE LADDERS: under each stretch (clear of the defenders' own spawns), a block of attackers
	-- with shields raised and two ladders with men swarming up them
	siege.ladderHome = Instance.new("Folder")
	siege.ladderHome.Name = "SiegeLadders"
	siege.ladderHome.Parent = workspace.CurrentCamera
	siege.ladders = {}
	siege.feet = {}
	for i, sp in ipairs(C.spans) do
		local w = sp.x1 - sp.x0
		if w >= 16 then
			local out = (sp.x0 + sp.x1) / 2 > C.gate.X and 1 or -1
			local cx = (sp.x0 + sp.x1) / 2 + out * w * 0.2
			local cw = w * 0.5
			-- (keep off the defenders' spawns)
			local clear = true
			for _, d in ipairs(C.defs) do
				if math.abs(d.X - cx) < cw / 2 + 4 and math.abs(d.Z - (C.faceZ + f * 12)) < 10 then clear = false end
			end
			if clear then
				local id = "cover" .. i
				crowd:regiment(id, {side = A, kind = "foot", at = V3(cx, 0, C.faceZ + f * 9), facing = -f, cols = math.max(3, math.floor(cw / 2.6)),
					ranks = small and 2 or 3, spacing = 2.6, detail = "lite"})
				crowd:hold(id, "cover")
				table.insert(siege.feet, V3(cx, 0, C.faceZ + f * 10))
				for k, u in ipairs({-0.3, 0.3}) do
					local x = cx + u * cw
					local from = V3(x, C.ground, C.faceZ + f * 6)
					local to = V3(x, C.top + 1.2, C.faceZ + f * 0.6)
					ladderModel(siege.ladderHome, from, to)
					local lid = "ladder" .. i .. k
					crowd:ladder(lid, {side = A, kind = k == 1 and "foot" or "knight", from = from, to = to, n = small and 3 or 5, rate = 0.06})
					table.insert(siege.ladders, lid)
				end
			end
		end
	end
	-- THE FLANKS: the defenders' sally against the attackers' lines, both sides of the castle
	siege.lanes = {}
	local lanes = {C.half + 24, C.half + 64}
	if small then lanes = {lanes[1]} end
	for _, x in ipairs(lanes) do
		if x + 20 < C.bound then table.insert(siege.lanes, x) end
	end
	siege.front = C.gate.Z + f * 48
	local kinds = {{D = "foot", A = "foot"}, {D = "pike", A = "knight"}}
	for _, s in ipairs({-1, 1}) do
		for li, x in ipairs(siege.lanes) do
			crowd:regiment("D" .. s .. li, {side = D, kind = kinds[li].D, at = V3(C.gate.X + s * x, 0, siege.front - f * 26), facing = f,
				cols = 12, ranks = 5, spacing = 3.1, detail = li == 1 and "full" or "lite", torches = WarCrowd.night()})
			crowd:regiment("A" .. s .. li, {side = A, kind = kinds[li].A, at = V3(C.gate.X + s * x, 0, siege.front + f * 40), facing = -f,
				cols = 12, ranks = 5, spacing = 3.1, detail = li == 1 and "full" or "lite", torches = WarCrowd.night()})
		end
	end
	-- BEHIND: the attackers' archers loosing on the walls, their reserves beside the camp
	for _, s in ipairs({-1, 1}) do
		local ax = C.gate.X + s * math.max(C.half - 12, 40)
		crowd:regiment("arch" .. s, {side = A, kind = "archer", at = V3(ax, 0, C.gate.Z + f * 95), facing = -f, cols = 10, ranks = 2, spacing = 2.8, detail = "lite"})
		if not small then
			crowd:regiment("res" .. s, {side = A, kind = "pike", at = V3(C.att.X + s * 50, 0, C.att.Z), facing = -f, cols = 10, ranks = 6, spacing = 3, detail = "lite", torches = WarCrowd.night()})
		end
	end
	-- THE CASTLE BURNING: towers on fire, smoke over the keep, villages burning beyond
	siege.columns, siege.loops, siege.hazes = {}, {}, {}
	for _, at in ipairs(C.fires) do
		table.insert(siege.columns, WarFX.column(at, {fire = true, scale = 1.1}))
		siege.loops["fire" .. #siege.columns] = WarFX.loop3D("Fire", at, {volume = 1, near = 20, range = 220})
	end
	for k = 1, small and 2 or 4 do
		local sx = k % 2 == 0 and 1 or -1
		table.insert(siege.columns, WarFX.column(V3(C.gate.X + sx * (40 + math.random() * 120), 0, C.gate.Z - f * (190 + math.random() * 80)), {scale = 1.7 + math.random() * 0.8}))
	end
	-- the din: each flank's melee where it is, the roar of the armies, the battle beyond
	for _, s in ipairs({-1, 1}) do
		local x = C.gate.X + s * (siege.lanes[1] or C.half + 24)
		siege.loops["melee" .. s] = WarFX.loop3D("Melee", V3(x, 3, siege.front), {volume = 1.1, near = 50, range = 500})
		siege.loops["roar" .. s] = WarFX.loop3D("Roar", V3(x, 6, siege.front), {volume = 0.8, near = 100, range = 1000})
		for li, lx in ipairs(siege.lanes) do
			siege.hazes[s .. ":" .. li] = WarFX.haze(V3(C.gate.X + s * lx, 2, siege.front), {width = 46, depth = 14, rate = small and 2 or 5})
		end
	end
	siege.hazes.gate = WarFX.haze(V3(C.gate.X, 2, C.faceZ + f * 14), {width = 60, depth = 20, rate = small and 1 or 3, color = DUST})
	siege.battle = WarFX.loop("Battle", 0.4)
	-- THE RAM'S CREW: six of the attackers under its roof, walking it up the road, leaning into it
	task.spawn(function()
		local m = workspace:FindFirstChild("Map")
		local obj = m and m:FindFirstChild("Objectives")
		local ram
		for _ = 1, 40 do
			for _, c in ipairs(obj and obj:GetChildren() or {}) do
				local r = c:FindFirstChild("Ram")
				if r and r.PrimaryPart then ram = r end
			end
			if ram or siege.crowd ~= crowd then break end
			task.wait(0.5)
		end
		if not ram or siege.crowd ~= crowd then return end
		local spots = {}
		for _, x in ipairs({-2, 2}) do
			for _, z in ipairs({-4.5, 0, 4.5}) do table.insert(spots, CF(x, -1.6, z)) end
		end
		crowd:crew(ram.PrimaryPart, {side = A, kind = "foot", spots = spots})
	end)
	-- THE SIEGE TOWERS: copies of the camp's (only on this screen, nothing solid) rolled up to the
	-- side walls by their crews; docked, men climb up inside them and over onto the walk
	if C.sideX and C.sideY and C.sideZ and C.towerYaw then
		task.spawn(function()
			local m = workspace:FindFirstChild("Map")
			local src
			for _ = 1, 30 do
				src = m and m:FindFirstChild("TowerModel")
				if src or siege.crowd ~= crowd then break end
				task.wait(1)
			end
			if not src or siege.crowd ~= crowd then return end
			siege.rollers = {}
			for _, s in ipairs({-1, 1}) do
				local ok, tw = pcall(function() return src:Clone() end)
				if ok and tw then
					for _, d in ipairs(tw:GetDescendants()) do
						if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false end
					end
					local _, size = tw:GetBoundingBox()
					pcall(function() tw:ScaleTo(tw:GetScale() * (C.sideY + 6) / size.Y) end)
					tw.Parent = siege.ladderHome
					local _, sz = tw:GetBoundingBox()
					local depth = math.min(sz.X, sz.Z)
					local face = C.gate.X + s * C.sideX
					local dock = V3(face + s * (depth / 2 + 0.6), 0, C.sideZ)
					-- (from 32 studs out: the field beside a castle's walls is narrow, its edge hills close)
					local start = dock + V3(s * 32, 0, 0)
					local yawCF = CFrame.Angles(0, math.rad(C.towerYaw), 0)
					local look = V3(-s, 0, 0)
					local function placeAt(p)
						local g = WarFX.ground(V3(p.X, C.sideY + 30, p.Z))
						tw:PivotTo(CFrame.lookAt(g, g + look) * yawCF)
						local bcf, bsz = tw:GetBoundingBox()
						tw:PivotTo(tw:GetPivot() + V3(0, g.Y - (bcf.Position.Y - bsz.Y / 2), 0))
					end
					placeAt(start)
					local body = tw:IsA("BasePart") and tw or tw:FindFirstChildWhichIsA("BasePart", true)
					local r = {model = tw, body = body, start = start, dock = dock, placeAt = placeAt, s = s, t0 = os.clock() + 12 + math.random() * 10, T = 50}
					table.insert(siege.rollers, r)
					-- its crew, pushing from behind
					if body then
						local spots = {}
						for k = -1, 1 do
							local at = WarFX.ground(start + V3(s * (depth / 2 + 1.6), C.sideY + 30, k * 3))
							table.insert(spots, body.CFrame:Inverse() * CFrame.lookAt(at, at + look))
						end
						r.crewSpots = spots
					end
				end
			end
			-- rolling (a few times a second: they're slow), then docked: the climb
			while siege.on and siege.crowd == crowd do
				local now = os.clock()
				local moving = false
				for _, r in ipairs(siege.rollers) do
					if not r.docked then
						local u = math.clamp((now - r.t0) / r.T, 0, 1)
						if u > 0 then
							r.placeAt(r.start:Lerp(r.dock, u * u * (3 - 2 * u)))
							moving = true
						end
						if u >= 1 then
							r.docked = true
							local g = WarFX.ground(V3(r.dock.X, C.sideY + 30, r.dock.Z))
							local lid = "tower" .. r.s
							crowd:ladder(lid, {side = A, kind = "foot", from = V3(r.dock.X, g.Y, r.dock.Z), to = V3(C.gate.X + r.s * (C.sideX - 0.5), C.sideY + 1.2, r.dock.Z),
								n = 6, rate = 0.02, speed = 4.5})
							table.insert(siege.ladders, lid)
							if siege.taken then crowd:overrun(lid) end
							WarFX.sound("Gate", r.dock, {volume = 0.8, range = 500, near = 50, speed = 0.7})
							WarFX.dust(g + V3(0, 1, 0), 3, DUST)
						end
					end
					if r.crewSpots and not r.crew and r.body then r.crew = crowd:crew(r.body, {side = A, kind = "pike", spots = r.crewSpots}) end
				end
				task.wait(moving and 0.1 or 0.5)
			end
		end)
	end
	siege.crows = WarFX.crows(V3(C.gate.X, 0, C.gate.Z - f * 40), {n = small and 8 or 14, radius = 90, height = 70})
	siege.charged = false
	siege.chargeAt = os.clock() + 8
	siege.nextWall = os.clock() + 4
	siege.nextArch = os.clock() + 7
	siege.nextBomb = os.clock() + 10
	siege.stage = 0
end

--------------------------------------------------------------------
--  THE BATTLE'S LIFE (twice a second)
--------------------------------------------------------------------
local function wallsTaken(quiet)
	local crowd, C = siege.crowd, siege.C
	if not crowd or siege.taken then return end
	siege.taken = true
	if not quiet then
		crowd:cheer(siege.A)
		crowd:crewCheer(6)
		-- the gate bursts: a cloud of dust and splinters, the crash, the ground jumping under you
		local g = C.gate
		WarFX.dust(g + V3(0, 3, C.f * 4), 4, DUST)
		WarFX.dust(g + V3(0, 8, -C.f * 6), 3, DUST)
		WarFX.sound("Gate", g, {volume = 1, range = 900, near = 60, speed = 0.8})
		WarFX.sound("Impact", g, {volume = 0.8, range = 900, near = 60, speed = 0.7})
		local me = myPos()
		local d = me and (me - g).Magnitude or 999
		if d < 160 then WarFX.shake(1.4 * (1 - d / 160) + 0.15, 0.8) end
	end
	for _, id in ipairs(siege.ladders) do crowd:overrun(id) end
	-- the archers on the walls cut down, the men under the walls lower their shields (no more arrows)
	for _, w in ipairs(siege.walls) do crowd:rout(w.id, quiet and 0 or 5) end
	for id in pairs(crowd.regs) do if id:sub(1, 5) == "cover" then crowd:hold(id, nil) end end
	for _, s in ipairs({-1, 1}) do crowd:march("res" .. s, C.gate.Z + C.f * 22, true) end
	-- (the sally is driven back under the walls)
	siege.front = C.gate.Z + C.f * 26
end

-- THE BAILEY: once the gate is down, a melee on each side of the yard being fought over (where
-- the ground is clear and level: no building, no stair), defenders against attackers; when the
-- bailey falls its defenders are cut down
local function clearGround(x, z, w, d, y)
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = {workspace.CurrentCamera, workspace:FindFirstChild("NPCs")}
	for _, u in ipairs({-0.5, 0, 0.5}) do
		for _, v in ipairs({-0.5, 0, 0.5}) do
			local r = workspace:Raycast(V3(x + u * w, y + 40, z + v * d), V3(0, -80, 0), ray)
			if not r or math.abs(r.Position.Y - y) > 1.5 then return false end
		end
	end
	return true
end
local function baileyFight(at)
	local crowd, C = siege.crowd, siege.C
	if not crowd or siege.bailey then return end
	siege.bailey = {}
	local f = C.f
	-- (the yard's own level: the zone part lies on it; not the well or whatever stands in the middle)
	local floor = at.Y
	for _, s in ipairs({-1, 1}) do
		local placed = false
		for _, dz in ipairs({0, -f * 24, f * 22}) do
			for _, off in ipairs({40, 32, 48, 24}) do
				local x, z = at.X + s * off, at.Z + dz
				if not placed and clearGround(x, z, 20, 34, floor) then
					placed = true
					local idD, idA = "bD" .. s, "bA" .. s
					crowd:regiment(idD, {side = siege.D, kind = "foot", at = V3(x, 0, z - f * 3), facing = f, cols = 6, ranks = 3, spacing = 3, detail = "lite", torches = WarCrowd.night()})
					crowd:regiment(idA, {side = siege.A, kind = "foot", at = V3(x, 0, z + f * 12), facing = -f, cols = 6, ranks = 3, spacing = 3, detail = "lite", torches = WarCrowd.night()})
					table.insert(siege.bailey, {D = idD, A = idA, z = z})
				end
			end
		end
	end
end
local function baileyStep(now)
	local crowd = siege.crowd
	-- (the yard's fight starts once its zone is known: ObjPos follows the stage a moment later)
	if not siege.bailey and siege.stage == 2 and round:GetAttribute("ObjKind") == "Capture" then
		local at = round:GetAttribute("ObjPos")
		if typeof(at) == "Vector3" and math.abs(at.Z - siege.C.gate.Z) > 20 then baileyFight(at) end
	end
	for _, b in ipairs(siege.bailey or {}) do
		if not b.done then crowd:lane(b.D, b.A, b.z, now, siege.C.f) end
	end
end
local function baileyTaken()
	local crowd = siege.crowd
	for _, b in ipairs(siege.bailey or {}) do
		if not b.done then
			b.done = true
			crowd:clash(b.D, false); crowd:clash(b.A, false)
			crowd:rout(b.D, 3)
			task.delay(1, function() if siege.crowd == crowd then crowd:cheer(siege.A) end end)
		end
	end
end

local function stageChanged(quiet)
	local st = round:GetAttribute("ObjStage") or 1
	if st == siege.stage then return end
	siege.stage = st
	if st >= 2 then wallsTaken(quiet) end
	if st >= 3 then baileyTaken() end
	-- (inside the walls: smoke from the burning castle drifts through the yard being fought over)
	local at = round:GetAttribute("ObjPos")
	if st >= 2 and typeof(at) == "Vector3" and round:GetAttribute("ObjKind") == "Capture" then
		if siege.hazes.inner then siege.hazes.inner.move(at + V3(0, 3, 0))
		else siege.hazes.inner = WarFX.haze(at + V3(0, 3, 0), {width = 70, depth = 50, rate = 4, color = Color3.fromRGB(96, 90, 86)}) end
	end
	if st >= 3 and siege.C.roof and not siege.roofFire then
		siege.roofFire = WarFX.column(siege.C.roof, {fire = true, scale = 1.5})
		table.insert(siege.columns, siege.roofFire)
		siege.loops.roof = WarFX.loop3D("Fire", siege.C.roof, {volume = 1.2, near = 30, range = 260})
	end
end

-- the charge: both lines of every flank run at each other and crash
local function flanks(now)
	local crowd, C = siege.crowd, siege.C
	local f = C.f
	if not siege.charged then
		if now < siege.chargeAt then return end
		siege.charged = true
		WarFX.sound("Horn", nil, {volume = 0.8})
		task.delay(0.8, function() if siege.on then WarFX.sound("Charge", nil, {volume = 0.8}) end end)
	end
	for _, s in ipairs({-1, 1}) do
		for li in ipairs(siege.lanes) do
			local crash, at = crowd:lane("D" .. s .. li, "A" .. s .. li, siege.front, now, f)
			if crash then
				WarFX.dust(crash + V3(0, 1, 0), 3, DUST)
				WarFX.sound("Gate", crash, {range = 450, near = 40, speed = 1.3, volume = 0.6})
				local me = myPos()
				if me and (me - crash).Magnitude < 110 then WarFX.shake(0.8 * (1 - (me - crash).Magnitude / 110) + 0.1, 0.5) end
				for _ = 1, 3 do crowd:blast(crash + V3((math.random() - 0.5) * 30, 0, 0), 2.5) end
			end
			local hz = siege.hazes[s .. ":" .. li]
			if hz and at then hz.move(at + V3(0, 2, 0)) end
		end
		local mel = siege.loops["melee" .. s]
		if mel then mel.move(V3(C.gate.X + s * (siege.lanes[1] or C.half + 24), 3, siege.front)) end
	end
end

-- the arrows: the walls loose on the field, the attackers' archers on the walls
local function arrows(now)
	local crowd, C = siege.crowd, siege.C
	local f = C.f
	if not siege.taken and now >= siege.nextWall and #siege.walls > 0 then
		siege.nextWall = now + 6 + math.random() * 5
		local w = siege.walls[math.random(#siege.walls)]
		crowd:loose(w.id)
		-- (at the men under the walls, or the attackers' line on a flank)
		local to
		if #siege.feet > 0 and math.random() < 0.5 then
			to = siege.feet[math.random(#siege.feet)] + V3((math.random() - 0.5) * 10, 0, f * math.random() * 6)
		else
			local s = math.random() < 0.5 and -1 or 1
			local x = siege.lanes[math.random(math.max(1, #siege.lanes))] or (C.half + 24)
			to = V3(C.gate.X + s * x + (math.random() - 0.5) * 24, 0, siege.front + f * (8 + math.random() * 10))
		end
		to = WarFX.ground(to)
		task.delay(0.9, function()
			if not siege.on or siege.crowd ~= crowd then return end
			WarFX.volley(w.at + V3(0, 4, 0), to, 50, {flight = 2.2, spread = 9, stick = false, range = 280})
			task.delay(2.2, function() if siege.crowd == crowd then crowd:hit(to, 9, 3) end end)
		end)
	end
	-- pitch: a pot of it, burning, hurled down from the walk onto the shields under the walls
	if not siege.taken and #siege.feet > 0 and now >= (siege.nextPitch or 0) then
		siege.nextPitch = now + 8 + math.random() * 7
		local foot = siege.feet[math.random(#siege.feet)]
		local from = V3(foot.X + (math.random() - 0.5) * 8, C.top + 2, C.faceZ - f * 1)
		local to = WarFX.ground(V3(foot.X + (math.random() - 0.5) * 10, C.top, foot.Z + f * (math.random() * 4 - 2)))
		local me = myPos()
		local close = me and (me - to).Magnitude < 50
		WarFX.fireball(from, to, 1.1, {size = 1.3, height = 5, far = not close, scorch = true,
			onLand = function(p) if siege.crowd == crowd then crowd:hit(p, 6, 3) end end})
	end
	if now >= siege.nextArch then
		siege.nextArch = now + 8 + math.random() * 5
		local s = math.random() < 0.5 and -1 or 1
		local reg = crowd.regs["arch" .. s]
		if reg then
			crowd:loose("arch" .. s)
			local w = (#siege.walls > 0 and not siege.taken) and siege.walls[math.random(#siege.walls)] or nil
			local to = w and (w.at + V3((math.random() - 0.5) * w.w * 0.6, 0, 0)) or V3(C.gate.X + (math.random() - 0.5) * 60, C.top, C.gate.Z - f * 20)
			task.delay(0.9, function()
				if not siege.on or siege.crowd ~= crowd then return end
				WarFX.volley(V3(reg.x, (reg.y0 or 0) + 6, reg.z), to, 60, {flight = 2.6, spread = 10, stick = false, range = 280})
				if w then task.delay(2.6, function() if siege.crowd == crowd then crowd:hit(to, 6, 2) end end) end
			end)
		end
	end
end

-- the castle under bombardment: stones and fire falling on its towers and walls from far behind
local function bombard(now)
	local C = siege.C
	if now < siege.nextBomb then return end
	siege.nextBomb = now + 9 + math.random() * 8
	local f = C.f
	local from = V3(C.att.X + (math.random() - 0.5) * 160, C.att.Y + 70, C.att.Z + f * 200)
	local to, onWall
	local r = math.random()
	if r < 0.45 and #C.towers > 0 then
		to, onWall = C.towers[math.random(#C.towers)].top - V3(0, 4, 0), true
	elseif r < 0.8 then
		to, onWall = V3(C.gate.X + (math.random() - 0.5) * C.half * 1.6, C.top, C.faceZ - f * 2), true
	else
		to = WarFX.ground(V3(C.gate.X + (math.random() - 0.5) * C.half * 1.4, C.top, C.gate.Z - f * (30 + math.random() * 90)))
	end
	local me = myPos()
	local close = me and (me - to).Magnitude < 70
	WarFX.fireball(from, to, 4.4, {big = true, whistle = close, far = not close, scorch = not onWall, floor = onWall and C.ground or nil,
		onLand = function(p) if siege.crowd then siege.crowd:blast(p, 9) end end})
end

-- the server's engines: their volleys land on the crowds too, its trebuchets throw men
local function hookEngines()
	task.spawn(function()
		local remote = ReplicatedStorage:WaitForChild("WarEvent", math.huge)
		if siege.hooked then return end
		siege.hooked = true
		remote.OnClientEvent:Connect(function(what, d)
			if not siege.on or type(d) ~= "table" then return end
			local crowd = siege.crowd
			if not crowd then return end
			if what == "Volley" and typeof(d.to) == "Vector3" then
				if d.side == siege.D and siege.walls[1] and not siege.taken then crowd:loose(siege.walls[math.random(#siege.walls)].id) end
				if d.side == siege.A then crowd:loose("arch-1"); crowd:loose("arch1") end
				task.delay(d.t or 2.4, function() if siege.crowd == crowd then crowd:hit(d.to, (d.r or 10) + 4, 4) end end)
			elseif what == "Treb" and typeof(d.to) == "Vector3" then
				task.delay(d.t or 4, function() if siege.crowd == crowd then crowd:blast(d.to, 10) end end)
			end
		end)
	end)
end

--------------------------------------------------------------------
--  COMING AND GOING
--------------------------------------------------------------------
local function leave()
	if not siege.on then return end
	siege.on = false
	siege.token += 1
	if siege.crowd then siege.crowd:stop(); siege.crowd = nil end
	-- (a 2D loop is the Sound itself; a placed one a handle)
	for _, l in pairs(siege.loops or {}) do if typeof(l) == "Instance" then WarFX.stopLoop(l, 1) elseif l then l.stop(1) end end
	for _, h in pairs(siege.hazes or {}) do h.stop() end
	for _, c in ipairs(siege.columns or {}) do c.stop() end
	if siege.ladderHome then siege.ladderHome:Destroy(); siege.ladderHome = nil end
	if siege.crows then siege.crows.stop(); siege.crows = nil end
	WarFX.stopLoop(siege.battle, 1)
	siege.loops, siege.hazes, siege.columns, siege.battle = {}, {}, {}, nil
	siege.taken, siege.roofFire, siege.bailey = nil, nil, nil
end

local function enter()
	if siege.on then return end
	siege.on = true
	siege.token += 1
	local token = siege.token
	hookEngines()
	task.spawn(function()
		-- the castle arrives with the map
		local C
		for _ = 1, 60 do
			C = round:GetAttribute("Attackers") and readCastle()
			if C or siege.token ~= token then break end
			task.wait(0.5)
		end
		if siege.token ~= token then return end
		if not C then siege.on = false; return end
		-- (and for the ground before the walls to have streamed in: the men stand on it)
		for _ = 1, 40 do
			local r = workspace:Raycast(V3(C.gate.X + C.half + 24, C.top + 100, C.gate.Z + C.f * 48), V3(0, -300, 0))
			if r or siege.token ~= token then break end
			task.wait(0.5)
		end
		if siege.token ~= token then return end
		build(C)
		stageChanged(true)
		while siege.on and siege.token == token do
			local now = os.clock()
			local ok, err = pcall(stageChanged, false)
			if not ok then warn("[SiegeEpic] " .. tostring(err)) end
			for _, step in ipairs({flanks, arrows, bombard, baileyStep}) do
				ok, err = pcall(step, now)
				if not ok then warn("[SiegeEpic] " .. tostring(err)) end
			end
			task.wait(0.5)
		end
	end)
end

-- the end: the winners cheer, the camera rises over the castle and circles it slowly (the board
-- waits a few seconds: _G.BoardHoldUntil)
local finale = false
local function finaleStop()
	if not finale then return end
	finale = false
	_G.FinaleCamera = nil
	pcall(function() RunService:UnbindFromRenderStep("SiegeFinale") end)
	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = 70 end
end
round:GetAttributeChangedSignal("State"):Connect(function()
	if round:GetAttribute("State") ~= "Intermission" then finaleStop(); return end
	if not (siege.on and siege.crowd and siege.C) then return end
	local winner = round:GetAttribute("Winner") or ""
	for k, d in pairs(GameConfig.TEAMS) do
		if d.name == winner then siege.crowd:cheer(k); siege.crowd:crewCheer(6) end
	end
	WarFX.sound("Horn", nil, {volume = 1})
	task.delay(2.4, function() if finale then WarFX.sound("Horn", nil, {volume = 0.8, speed = 0.92}) end end)
	finale = true
	_G.FinaleCamera = true
	_G.BoardHoldUntil = os.clock() + 5
	local C = siege.C
	local mid = V3(C.gate.X, C.top * 0.6, C.gate.Z - C.f * 60)
	local t0 = os.clock()
	RunService:BindToRenderStep("SiegeFinale", Enum.RenderPriority.Camera.Value + 6, function()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local t = os.clock() - t0
		local a = t * 0.07 + math.atan2(C.f, 0) - 0.6
		local r = 120
		local h = 40 + math.min(t, 6) * 4
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(V3(mid.X + math.cos(a) * r, h, mid.Z + math.sin(a) * r), mid)
		cam.FieldOfView = 60
	end)
end)
-- a new round (the sides swap, the castle is whole again), a new map: everything again
local want = 0
local function rebuild()
	want += 1
	local w = want
	task.delay(0.6, function()
		if want ~= w then return end
		leave()
		if inSiege() then enter() end
	end)
end
round:GetAttributeChangedSignal("Map"):Connect(rebuild)
round:GetAttributeChangedSignal("Attackers"):Connect(function() if round:GetAttribute("Attackers") then rebuild() end end)
round:GetAttributeChangedSignal("Mode"):Connect(function() if inSiege() then enter() else leave(); finaleStop() end end)
if inSiege() then enter() end
