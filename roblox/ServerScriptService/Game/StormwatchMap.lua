--[[ STORMWATCH MAP — the prologue's castle (Game ▸ Modes ▸ Prologue), built fresh when it starts:
     Stormwatch, a border castle on a stormy night with the Iron Host at its gate.

       StormwatchMap.build() -> mapName, layout
         layout.points  named places (Vector3 on the ground): wake, armory, raiders, yard, breach,
                        breachOut, gate, gateOut, wall, keep, army, ram, captain…
         layout.trebuchets  where the Iron Host's engines stand (the mode lobs fire from them)
         Map ▸ Gate     the gate's two leaves (GateLeft, GateRight): the breach throws them down
         Map attributes P_<name> = the points again (the client's cutscenes read them)

     Inside: a cobbled courtyard under curtain walls with a wall walk and battlements, a
     gatehouse of two square towers over an arched gate of oak and iron, round corner towers
     (one burning), the keep, the barracks, the armoury's racks, a burning smithy and stables,
     a breach in the east wall heaped with rubble, braziers, banners, barricades, puddles in the
     rain. Outside: a field of mud, the Iron Host's camp (tents, fires, black banners, rank on
     rank of torches), their trebuchets (ServerStorage ▸ PrologueProps ▸ Trebuchet when the place
     has it, else built of timber), a covered ram before the gate, ladders on the walls. ]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local K = require(ServerScriptService:WaitForChild("Build"):WaitForChild("MapKit"))
if not K.campfire then require(ServerScriptService.Build:WaitForChild("MapProps"))(K) end

local StormwatchMap = {}
local V3 = Vector3.new
local DEG = math.rad
local made = 0

local STONE = Color3.fromRGB(104, 106, 112)
local STONE2 = Color3.fromRGB(80, 82, 90)
local STONE3 = Color3.fromRGB(62, 64, 72)
local COBBLE = Color3.fromRGB(86, 86, 92)
local MUD = Color3.fromRGB(58, 50, 42)
local WOOD = Color3.fromRGB(96, 66, 42)
local DARK = Color3.fromRGB(56, 38, 26)
local IRON = Color3.fromRGB(52, 52, 58)
local BLUE = Color3.fromRGB(38, 70, 160)
local HOST = Color3.fromRGB(110, 22, 24)
local FIRE = Color3.fromRGB(255, 140, 50)

local W, NZ, SZ = 76, -56, 66      -- the walls: x = ±W, north at NZ (the gate), south at SZ
local WALL_H, WALL_T = 26, 8

local function nocol(p) p.CanCollide = false; p.CanQuery = false; return p end

local function fireOn(part, size, light)
	local f = Instance.new("Fire"); f.Size = size or 6; f.Heat = 9; f.Color = FIRE; f.SecondaryColor = Color3.fromRGB(200, 50, 10); f.Parent = part
	local s = Instance.new("Smoke"); s.Size = (size or 6) * 1.6; s.RiseVelocity = 6; s.Opacity = 0.18; s.Color = Color3.fromRGB(40, 36, 34); s.Parent = part
	if light ~= false then
		local l = Instance.new("PointLight"); l.Name = "Flicker"; l.Color = FIRE; l.Range = math.min(60, (size or 6) * 4); l.Brightness = 2.2; l.Shadows = true; l.Parent = part
	end
end

local function brazier(ctx, pos)
	K.cyl(ctx, "BrazierStand", 0.6, 3, pos + V3(0, 1.5, 0), IRON, Enum.Material.Metal, ctx.Props)
	K.cyl(ctx, "BrazierBowl", 2.6, 0.9, pos + V3(0, 3.2, 0), IRON, Enum.Material.Metal, ctx.Props)
	local coals = nocol(K.cyl(ctx, "Coals", 2.2, 0.3, pos + V3(0, 3.65, 0), FIRE, Enum.Material.Neon, ctx.Props))
	local f = Instance.new("Fire"); f.Size = 3.5; f.Heat = 7; f.Color = FIRE; f.SecondaryColor = Color3.fromRGB(200, 60, 10); f.Parent = coals
	local l = Instance.new("PointLight"); l.Name = "Flicker"; l.Color = FIRE; l.Range = 24; l.Brightness = 1.8; l.Shadows = true; l.Parent = coals
end

local function stormBanner(ctx, pos, color)
	K.banner(ctx, pos, 12, color or BLUE)
end

-- a square tower: body, a corbelled top, battlements
local function squareTower(ctx, pos, s, h)
	K.box(ctx, "Tower", V3(s, h, s), CFrame.new(pos + V3(0, h / 2, 0)), STONE, Enum.Material.Slate)
	K.box(ctx, "TowerTop", V3(s + 1.6, 1.2, s + 1.6), CFrame.new(pos + V3(0, h + 0.6, 0)), STONE2, Enum.Material.Slate)
	local n = math.floor(s / 2.4)
	for i = 0, n do
		local u = -s / 2 - 0.4 + i * ((s + 0.8) / n)
		for _, side in ipairs({{u, s / 2 + 0.4}, {u, -s / 2 - 0.4}, {s / 2 + 0.4, u}, {-s / 2 - 0.4, u}}) do
			if (i % 2 == 0) then K.box(ctx, "Merlon", V3(1.4, 1.8, 1.4), CFrame.new(pos + V3(side[1], h + 2.1, side[2])), STONE, Enum.Material.Slate) end
		end
	end
	for _, y in ipairs({h * 0.45, h * 0.75}) do
		for _, f in ipairs({V3(0, y, -s / 2 - 0.1), V3(0, y, s / 2 + 0.1)}) do
			nocol(K.box(ctx, "Slit", V3(0.8, 2.6, 0.3), CFrame.new(pos + f), Color3.fromRGB(14, 14, 18), Enum.Material.SmoothPlastic))
		end
	end
end

-- a timber trebuchet (when the place has no PrologueProps ▸ Trebuchet)
local function timberTrebuchet(ctx, pos, yaw)
	local f = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	for _, s in ipairs({-1, 1}) do
		K.box(ctx, "TrebBase", V3(1.4, 1.4, 16), f * CFrame.new(s * 4, 0.7, 0), DARK, Enum.Material.Wood, ctx.Props)
		K.box(ctx, "TrebA", V3(1.2, 16, 1.2), f * CFrame.new(s * 3, 7.5, 2) * CFrame.Angles(DEG(14), 0, 0), WOOD, Enum.Material.Wood, ctx.Props)
		K.box(ctx, "TrebA", V3(1.2, 16, 1.2), f * CFrame.new(s * 3, 7.5, -2) * CFrame.Angles(DEG(-14), 0, 0), WOOD, Enum.Material.Wood, ctx.Props)
	end
	K.box(ctx, "TrebAxle", V3(8, 1, 1), f * CFrame.new(0, 15, 0), IRON, Enum.Material.Metal, ctx.Props)
	K.box(ctx, "TrebArm", V3(1.2, 1.2, 26), f * CFrame.new(0, 17, 4) * CFrame.Angles(DEG(-30), 0, 0), WOOD, Enum.Material.Wood, ctx.Props)
	K.box(ctx, "TrebWeight", V3(5, 5, 5), f * CFrame.new(0, 11, -6), DARK, Enum.Material.WoodPlanks, ctx.Props)
	for _, s in ipairs({-1, 1}) do
		for _, z in ipairs({-7, 7}) do K.cyl(ctx, "TrebWheel", 3, 0.6, f * CFrame.new(s * 4.8, 1.5, z) * CFrame.Angles(0, 0, DEG(90)), DARK, Enum.Material.Wood, ctx.Props) end
	end
end

function StormwatchMap.build()
	made += 1
	local name = "Gen_Stormwatch_" .. made
	local ctx = K.new(name)
	local L = {points = {}, trebuchets = {}}
	local P = L.points

	-- THE GROUND: cobbles within, mud without
	K.box(ctx, "Courtyard", V3(W * 2 + 10, 1, SZ - NZ + 10), CFrame.new(0, -0.5, (SZ + NZ) / 2), COBBLE, Enum.Material.Cobblestone)
	K.box(ctx, "Field", V3(900, 1, 900), CFrame.new(0, -0.6, -200), MUD, Enum.Material.Mud)
	-- puddles shining in the rain
	for _ = 1, 22 do
		local s = 3 + math.random() * 7
		local p = nocol(K.cyl(ctx, "Puddle", s, 0.06, CFrame.new(math.random(-66, 66), 0.03, math.random(NZ + 8, SZ - 8)), Color3.fromRGB(30, 36, 44), Enum.Material.Glass, ctx.Props))
		p.Size = V3(0.06, s, s * (0.5 + math.random() * 0.4)); p.Reflectance = 0.35; p.Transparency = 0.1
	end

	-- THE CURTAIN WALLS (the east one breached)
	local wopts = {crenels = true, color = STONE, material = Enum.Material.Slate, base = true, baseH = 2.4, baseW = 2, baseColor = STONE3}
	K.wall(ctx, V3(-W, 0, NZ), V3(-24, 0, NZ), WALL_H, WALL_T, wopts)
	K.wall(ctx, V3(24, 0, NZ), V3(W, 0, NZ), WALL_H, WALL_T, wopts)
	K.wall(ctx, V3(-W, 0, NZ), V3(-W, 0, SZ), WALL_H, WALL_T, wopts)
	K.wall(ctx, V3(W, 0, NZ), V3(W, 0, 4), WALL_H, WALL_T, wopts)
	K.wall(ctx, V3(W, 0, 18), V3(W, 0, SZ), WALL_H, WALL_T, wopts)
	K.wall(ctx, V3(-W, 0, SZ), V3(W, 0, SZ), WALL_H, WALL_T, wopts)
	-- the breach: a broken stump of wall and the rubble it became
	K.wall(ctx, V3(W, 0, 4), V3(W, 0, 18), 5, WALL_T, {color = STONE2, material = Enum.Material.Slate})
	for _ = 1, 26 do
		local s = 1.5 + math.random() * 3.5
		local x = W + (math.random() - 0.5) * 22
		K.box(ctx, "Rubble", V3(s, s * 0.7, s * 1.2), CFrame.new(x, s * 0.3, 4 + math.random() * 14) * CFrame.Angles(math.random(), math.random() * 6, math.random()), math.random() < 0.5 and STONE or STONE2, Enum.Material.Slate, ctx.Props)
	end
	P.breach = V3(W - 12, 0, 11)
	P.breachOut = V3(W + 16, 0, 11)

	-- THE GATEHOUSE: two square towers, the arch, the gate of oak and iron
	squareTower(ctx, V3(-18, 0, NZ), 12, 38)
	squareTower(ctx, V3(18, 0, NZ), 12, 38)
	local gateFrame = CFrame.new(0, 0, NZ)
	local top = K.arch(ctx, gateFrame, 16, 18, WALL_T, STONE, Enum.Material.Slate)
	K.box(ctx, "GateWall", V3(24, WALL_H + 6 - top, WALL_T), CFrame.new(0, top + (WALL_H + 6 - top) / 2, NZ), STONE, Enum.Material.Slate)
	for _, s in ipairs({-1, 1}) do K.box(ctx, "GateFill", V3(2.4, WALL_H + 6, WALL_T), CFrame.new(s * 10.9, (WALL_H + 6) / 2, NZ), STONE, Enum.Material.Slate) end
	local gate = Instance.new("Model"); gate.Name = "Gate"; gate.Parent = ctx.model
	for _, s in ipairs({-1, 1}) do
		local leaf = Instance.new("Model"); leaf.Name = s < 0 and "GateLeft" or "GateRight"; leaf.Parent = gate
		local body = K.box(ctx, "Leaf", V3(8, 17.5, 1.6), CFrame.new(s * 4, 8.75, NZ + 1.2), WOOD, Enum.Material.WoodPlanks, leaf)
		leaf.PrimaryPart = body
		for _, y in ipairs({3, 8.5, 14}) do K.box(ctx, "Band", V3(8.1, 0.7, 1.8), CFrame.new(s * 4, y, NZ + 1.2), IRON, Enum.Material.Metal, leaf) end
		for _, y in ipairs({3, 8.5, 14}) do K.box(ctx, "Stud", V3(0.5, 0.5, 2), CFrame.new(s * 1.2, y, NZ + 1.2), IRON, Enum.Material.Metal, leaf) end
	end
	K.box(ctx, "GateBar", V3(17, 1.2, 1.2), CFrame.new(0, 8, NZ + 2.4), DARK, Enum.Material.Wood, gate)
	P.gate = V3(0, 0, NZ + 18)
	P.gateOut = V3(0, 0, NZ - 30)
	P.ram = V3(0, 0, NZ - 14)
	-- battlement walk access: stairs up the inside of the west wall
	K.stairs(ctx, CFrame.new(-W + 7, 0, 12), 6, 26, 1, 1.45, STONE2, Enum.Material.Slate)
	P.wall = V3(-W, WALL_H, -26)
	P.stairs = V3(-W + 7, 0, 14)

	-- CORNER TOWERS (the north-east one burning, its roof half gone)
	for _, c in ipairs({{-W, NZ}, {W, NZ}, {-W, SZ}, {W, SZ}}) do
		K.tower(ctx, V3(c[1], 0, c[2]), 9, 34, {color = STONE, base = 3, roof = not (c[1] > 0 and c[2] < 0), roofColor = Color3.fromRGB(44, 52, 70), windows = true})
	end
	local burnTop = nocol(K.box(ctx, "TowerFire", V3(12, 2, 12), CFrame.new(W, 36, NZ), FIRE, Enum.Material.Neon, ctx.Props))
	burnTop.Transparency = 0.6
	fireOn(burnTop, 14)

	-- THE KEEP
	K.box(ctx, "Keep", V3(48, 34, 26), CFrame.new(0, 17, SZ - 18), STONE2, Enum.Material.Slate)
	K.box(ctx, "KeepTop", V3(50, 1.4, 28), CFrame.new(0, 34.7, SZ - 18), STONE3, Enum.Material.Slate)
	for _, x in ipairs({-24, 24}) do K.tower(ctx, V3(x, 0, SZ - 31), 5, 42, {color = STONE, roof = true, roofColor = Color3.fromRGB(44, 52, 70)}) end
	K.arch(ctx, CFrame.new(0, 0, SZ - 31.2), 8, 11, 1.2, STONE3, Enum.Material.Slate)
	nocol(K.box(ctx, "KeepDoor", V3(8, 10, 0.6), CFrame.new(0, 5, SZ - 30.8), DARK, Enum.Material.WoodPlanks, ctx.Props))
	for _, x in ipairs({-12, 12}) do stormBanner(ctx, V3(x, 0, SZ - 34), BLUE) end
	P.keep = V3(0, 0, SZ - 40)

	-- THE BARRACKS (where you come to), the armoury, the smithy and the stables
	K.house(ctx, CFrame.new(-56, 0, 34) * CFrame.Angles(0, DEG(90), 0), 16, 22, 11, Color3.fromRGB(150, 140, 124), DARK)
	P.wake = V3(-33, 0, 34)   -- (out before its door: room for the camera behind you)
	-- the armoury: a roofed rack yard
	local arm = CFrame.new(-50, 0, -8)
	for _, x in ipairs({-8, 8}) do for _, z in ipairs({-6, 6}) do K.box(ctx, "Post", V3(1, 10, 1), arm * CFrame.new(x, 5, z), DARK, Enum.Material.Wood) end end
	K.box(ctx, "ArmouryRoof", V3(20, 0.8, 16), arm * CFrame.new(0, 10.4, 0) * CFrame.Angles(0, 0, DEG(-8)), DARK, Enum.Material.WoodPlanks)
	for _, z in ipairs({-4, 0, 4}) do pcall(K.rack, ctx, arm * CFrame.new(-6, 0, z) * CFrame.Angles(0, DEG(90), 0)) end
	for _ = 1, 4 do K.crate(ctx, (arm * CFrame.new(math.random(2, 7), 0, math.random(-5, 5))).Position, 2.6, math.random(0, 90)) end
	P.armory = V3(-38, 0, -8)
	-- the smithy, burning
	K.house(ctx, CFrame.new(54, 0, 42) * CFrame.Angles(0, DEG(-90), 0), 14, 18, 10, Color3.fromRGB(140, 128, 112), DARK)
	local sf = nocol(K.box(ctx, "SmithyFire", V3(14, 2, 18), CFrame.new(54, 12, 42), FIRE, Enum.Material.Neon, ctx.Props))
	sf.Transparency = 0.7
	fireOn(sf, 16)
	-- the stables
	K.house(ctx, CFrame.new(56, 0, -30) * CFrame.Angles(0, DEG(-90), 0), 14, 22, 9, Color3.fromRGB(130, 112, 90), DARK)
	for _ = 1, 4 do K.hay(ctx, V3(44 + math.random() * 6, 0, -40 + math.random() * 20)) end

	-- THE YARD: barricades of stakes before the gate, braziers, banners, carts, barrels
	for i = -3, 3 do
		local x = i * 6
		for k = -1, 1, 2 do K.box(ctx, "Stake", V3(0.6, 6, 0.6), CFrame.new(x + k * 1.2, 2.4, NZ + 26) * CFrame.Angles(DEG(-35), 0, DEG(k * 12)), DARK, Enum.Material.Wood, ctx.Props) end
		K.box(ctx, "StakeBeam", V3(4, 0.6, 0.6), CFrame.new(x, 1.6, NZ + 25), DARK, Enum.Material.Wood, ctx.Props)
	end
	for _, pos in ipairs({V3(-26, 0, NZ + 14), V3(26, 0, NZ + 14), V3(-30, 0, 20), V3(30, 0, 20), V3(-12, 0, SZ - 44), V3(12, 0, SZ - 44)}) do brazier(ctx, pos) end
	for _, x in ipairs({-60, -36, 36, 60}) do stormBanner(ctx, V3(x, 0, NZ + 7), BLUE) end
	for _ = 1, 10 do K.barrel(ctx, V3(math.random(-66, 66), 0, math.random(NZ + 30, SZ - 40))) end
	for _ = 1, 8 do K.crate(ctx, V3(math.random(-66, 66), 0, math.random(NZ + 30, SZ - 40)), 2.4 + math.random(), math.random(0, 90)) end
	-- arrows stuck in the cobbles and the timbers
	for _ = 1, 40 do
		local at = V3(math.random(-68, 68), 0.8, math.random(NZ + 10, SZ - 34))
		nocol(K.box(ctx, "SpentArrow", V3(0.12, 0.12, 2.4), CFrame.new(at) * CFrame.Angles(DEG(-50 - math.random(0, 25)), math.random() * 6.28, 0), Color3.fromRGB(110, 84, 54), Enum.Material.Wood, ctx.Props))
	end
	-- torches along the wall faces
	for z = NZ + 14, SZ - 14, 18 do
		K.torch(ctx, V3(-W + WALL_T / 2 + 0.4, 9, z), 90)
		K.torch(ctx, V3(W - WALL_T / 2 - 0.4, 9, z), -90)
	end
	for x = -60, 60, 20 do if math.abs(x) > 26 then K.torch(ctx, V3(x, 9, NZ + WALL_T / 2 + 0.4), 0) end end
	-- a ballista on the wall walk
	local bal = CFrame.new(-40, WALL_H, NZ)
	K.box(ctx, "BallistaBase", V3(3, 1.2, 5), bal * CFrame.new(0, 0.6, 0), DARK, Enum.Material.Wood, ctx.Props)
	K.box(ctx, "BallistaArms", V3(7, 0.6, 0.8), bal * CFrame.new(0, 1.6, -1.6), WOOD, Enum.Material.Wood, ctx.Props)

	-- OUTSIDE: the Iron Host's camp, its fires, its engines, rank on rank of torches
	for i = 1, 14 do
		local a = (i / 14) * math.pi - math.pi / 2
		local r = 150 + math.random() * 60
		local pos = V3(math.sin(a) * r, 0, NZ - 60 - math.cos(a) * r * 0.6)
		K.tent(ctx, CFrame.new(pos) * CFrame.Angles(0, math.random() * 6.28, 0), 8, 10, 6, Color3.fromRGB(70, 60, 54))
		if i % 2 == 0 then pcall(K.campfire, ctx, pos + V3(8, 0, 4)) end
	end
	for i = 1, 6 do K.banner(ctx, V3(-90 + i * 30, 0, NZ - 110), 14, HOST) end
	-- the host itself: lines of torches in the dark
	for row = 0, 4 do
		for i = -12, 12 do
			if math.random() < 0.8 then
				local p = nocol(K.ball(ctx, "HostTorch", 0.7, V3(i * 7 + math.random(-2, 2), 6, NZ - 80 - row * 12 + math.random(-2, 2)), FIRE, Enum.Material.Neon, ctx.Props))
				if (i + row) % 5 == 0 then local l = Instance.new("PointLight"); l.Color = FIRE; l.Range = 16; l.Brightness = 1.4; l.Parent = p end
			end
		end
	end
	P.army = V3(0, 0, NZ - 100)
	-- the trebuchets
	local props = ServerStorage:FindFirstChild("PrologueProps")
	local tpl = props and props:FindFirstChild("Trebuchet")
	for _, t in ipairs({{-70, -190, 0.3}, {40, -210, -0.2}, {120, -175, -0.6}}) do
		local pos = V3(t[1], 0, t[2])
		if tpl then
			local m = tpl:Clone()
			for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
			m.Parent = ctx.Props
			local cf, size = m:GetBoundingBox()
			m:PivotTo(CFrame.new(pos + V3(0, size.Y / 2 - (cf.Position.Y - m:GetPivot().Position.Y), 0)) * CFrame.Angles(0, t[3] + math.pi, 0))
		else
			timberTrebuchet(ctx, pos, t[3])
		end
		table.insert(L.trebuchets, pos + V3(0, 22, 0))
		ctx.model:SetAttribute("T_" .. #L.trebuchets, pos + V3(0, 22, 0))   -- (the client lobs its fire from here)
	end
	-- the ram before the gate (under its hide roof) and ladders on the walls
	local ramF = CFrame.new(P.ram)
	for _, s in ipairs({-1, 1}) do
		for _, z in ipairs({-6, 6}) do K.box(ctx, "RamPost", V3(0.8, 8, 0.8), ramF * CFrame.new(s * 3.5, 4, z), DARK, Enum.Material.Wood, ctx.Props) end
		K.box(ctx, "RamRoof", V3(5, 0.4, 14), ramF * CFrame.new(s * 2, 8.4, 0) * CFrame.Angles(0, 0, DEG(s * -30)), Color3.fromRGB(90, 70, 50), Enum.Material.Fabric, ctx.Props)
	end
	K.cyl(ctx, "RamLog", 2, 16, ramF * CFrame.new(0, 4, 0) * CFrame.Angles(DEG(90), 0, 0), DARK, Enum.Material.Wood, ctx.Props)
	for _, x in ipairs({-50, -34, 36, 54}) do
		local lf = CFrame.new(x, 12, NZ - WALL_T / 2 - 4) * CFrame.Angles(DEG(-14), 0, 0)
		for _, s in ipairs({-1, 1}) do K.box(ctx, "Ladder", V3(0.5, 26, 0.5), lf * CFrame.new(s * 1.2, 0, 0), WOOD, Enum.Material.Wood, ctx.Props) end
		for y = -12, 12, 2 do K.box(ctx, "Rung", V3(2.4, 0.3, 0.3), lf * CFrame.new(0, y, 0), WOOD, Enum.Material.Wood, ctx.Props) end
	end
	-- hills on the horizon: great domes of grass and rock half sunk in the ground (soft and
	-- rolling in the fog; a handful of parts, no terrain to paste)
	for i = 1, 22 do
		local a = i / 22 * math.pi * 2 + math.random() * 0.15
		local r = 400 + math.random() * 80
		local d = 170 + math.random() * 120
		local c = V3(math.cos(a) * r, -d * (0.3 + math.random() * 0.12), -120 + math.sin(a) * r)
		local rock = math.random() < 0.3
		K.ball(ctx, "Hill", d, CFrame.new(c), rock and Color3.fromRGB(64, 62, 60) or Color3.fromRGB(46, 54, 38), rock and Enum.Material.Rock or Enum.Material.Grass, ctx.Props)
	end

	-- where the story happens
	P.raiders = V3(-24, 0, 2)
	P.yard = V3(-4, 0, 14)
	P.captain = V3(-27, 0, 29)
	P.boss = V3(0, 0, NZ + 34)
	for k, v in pairs(P) do ctx.model:SetAttribute("P_" .. k, v) end
	K.spawn(ctx, P.wake + V3(0, 1, 0), nil, P.wake + V3(10, 1, 0))
	K.camera(ctx, V3(-90, 70, 110), V3(0, 10, -20))
	K.camera(ctx, V3(30, 40, NZ - 70), V3(0, 14, NZ))

	-- a storm at night
	K.lighting(ctx, {ClockTime = 0.3, Brightness = 0.35, Ambient = Color3.fromRGB(46, 52, 70), OutdoorAmbient = Color3.fromRGB(60, 66, 88),
		FogColor = Color3.fromRGB(20, 24, 32), FogEnd = 520, FogStart = 80, ExposureCompensation = 0.1, EnvironmentDiffuseScale = 0.4})
	K.atmosphere(ctx, {Density = 0.38, Offset = 0.1, Color = Color3.fromRGB(64, 72, 88), Decay = Color3.fromRGB(28, 32, 44), Glare = 0, Haze = 2.4})
	ctx.model:SetAttribute("Generated", true)
	ctx.model:SetAttribute("Storm", true)
	local ok, err = pcall(K.finish, ctx)
	if not ok then
		warn("[StormwatchMap] finish:", err)
		local maps = ServerStorage:FindFirstChild("Maps") or Instance.new("Folder")
		maps.Name = "Maps"; maps.Parent = ServerStorage
		ctx.model.Parent = maps
	end
	return name, L
end

return StormwatchMap
