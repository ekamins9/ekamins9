--[[ TAVERN MAP — the dungeon game's own world (Game ▸ Modes ▸ Tavern): "The Gilded Rat", an
     adventurers' lodge at the top of the stairs to the dark, built fresh when its server starts.

       TavernMap.build() -> mapName, layout
         layout.npcs   = {{id = "Smith" | "Armourer" | "Alchemist" | "Treasurer", cf}}
         layout.points = {stash = cf, board = cf, gate = cf, exit = cf}   (what the mode puts prompts on)

     A long hall under timber beams: candle-lit tables under iron chandeliers, a great hearth, the
     counter where the Treasurer weighs gold, the Smith's forge, the Armourer's stands, the
     Alchemist's shelves of coloured bottles and a cauldron, your stash (an iron-bound chest by a
     strongroom door), the notice board (class and perks), the DUNGEON GATE (a stone arch over stairs
     going down into the dark, cold torches either side) and the door home to the Courtyard. ]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local K = require(ServerScriptService:WaitForChild("Build"):WaitForChild("MapKit"))
if not K.campfire then require(ServerScriptService.Build:WaitForChild("MapProps"))(K) end

local TavernMap = {}
local V3 = Vector3.new
local W, D, H = 110, 84, 26   -- the hall
local made = 0

local WOOD = Color3.fromRGB(96, 66, 42)
local DARK = Color3.fromRGB(52, 36, 24)
local STONE = Color3.fromRGB(96, 90, 82)
local STONE2 = Color3.fromRGB(72, 68, 62)
local IRON = Color3.fromRGB(52, 50, 54)
local GOLD = Color3.fromRGB(226, 182, 74)
local FLAME = Color3.fromRGB(255, 170, 90)

local function flame(ctx, at, size, range, bright, color)
	local f = K.ball(ctx, "Flame", size or 0.4, at, color or Color3.fromRGB(255, 200, 110), Enum.Material.Neon, ctx.Props)
	f.CanCollide = false
	local l = Instance.new("PointLight"); l.Color = color or FLAME; l.Range = range or 12; l.Brightness = bright or 1.3; l.Shadows = true; l.Parent = f
	local fire = Instance.new("Fire"); fire.Size = (size or 0.4) * 2; fire.Heat = 4; fire.Color = color or FLAME; fire.SecondaryColor = Color3.fromRGB(255, 90, 30); fire.Parent = f
	return f
end
local function candle(ctx, at, h)
	h = h or 1
	K.cyl(ctx, "Candle", 0.4, h, at + V3(0, h / 2, 0), Color3.fromRGB(236, 226, 196), Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
	flame(ctx, at + V3(0, h + 0.2, 0), 0.28, 10, 0.9)
end
local function chandelier(ctx, at)
	K.cyl(ctx, "Chain", 0.25, H - at.Y, CFrame.new(at.X, (H + at.Y) / 2, at.Z), IRON, Enum.Material.Metal, ctx.Props).CanCollide = false
	local ring = K.cyl(ctx, "Ring", 7, 0.5, CFrame.new(at), IRON, Enum.Material.Metal, ctx.Props)
	ring.CanCollide = false
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local p = at + V3(math.cos(a) * 3.2, 0.3, math.sin(a) * 3.2)
		K.cyl(ctx, "Candle", 0.3, 0.8, p + V3(0, 0.4, 0), Color3.fromRGB(236, 226, 196), Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
		local f = K.ball(ctx, "Flame", 0.25, p + V3(0, 0.95, 0), Color3.fromRGB(255, 200, 110), Enum.Material.Neon, ctx.Props)
		f.CanCollide = false
	end
	local l = Instance.new("PointLight"); l.Color = FLAME; l.Range = 30; l.Brightness = 1.4; l.Shadows = true; l.Parent = ring
end
local function table_(ctx, cf, len)
	K.box(ctx, "Table", V3(5, 0.6, len), cf * CFrame.new(0, 3, 0), WOOD, Enum.Material.WoodPlanks, ctx.Props)
	for _, z in ipairs({-len / 2 + 1.5, len / 2 - 1.5}) do
		for _, x in ipairs({-1.8, 1.8}) do K.box(ctx, "Leg", V3(0.5, 3, 0.5), cf * CFrame.new(x, 1.5, z), DARK, Enum.Material.Wood, ctx.Props) end
	end
	for _, x in ipairs({-4, 4}) do K.box(ctx, "Bench", V3(1.8, 0.5, len - 1), cf * CFrame.new(x, 1.8, 0), DARK, Enum.Material.WoodPlanks, ctx.Props) end
	for z = -len / 2 + 3, len / 2 - 3, 6 do
		candle(ctx, (cf * CFrame.new(math.random() < 0.5 and -0.8 or 0.8, 3.3, z)).Position, 0.6 + math.random() * 0.6)
		K.cyl(ctx, "Bowl", 1.2, 0.3, cf * CFrame.new(1.2, 3.45, z + 1.5), Color3.fromRGB(150, 110, 70), Enum.Material.Wood, ctx.Props).CanCollide = false
		K.cyl(ctx, "Bread", 0.9, 0.5, cf * CFrame.new(-1.3, 3.55, z - 1.4) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(196, 140, 70), Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
	end
end
local function shelf(ctx, cf, w, rows, items)
	K.box(ctx, "Shelf", V3(w, rows * 2.4 + 0.6, 1.4), cf * CFrame.new(0, (rows * 2.4 + 0.6) / 2, 0), DARK, Enum.Material.Wood, ctx.Props)
	for r = 1, rows do
		local y = r * 2.4
		for x = -w / 2 + 0.8, w / 2 - 0.8, 1 do
			if math.random() < 0.8 then items(cf * CFrame.new(x, y - 1.6, -0.3)) end
		end
	end
end

function TavernMap.build()
	made += 1
	local name = "Gen_Tavern_" .. made
	local ctx = K.new(name)
	local L = {npcs = {}, points = {}}

	-- the hall: a floor of boards, stone walls, a timbered ceiling
	K.box(ctx, "Floor", V3(W + 4, 1, D + 4), CFrame.new(0, -0.5, 0), Color3.fromRGB(84, 58, 38), Enum.Material.WoodPlanks)
	for x = -W / 2 + 6, W / 2 - 6, 12 do
		K.box(ctx, "FloorBeam", V3(0.6, 0.08, D), CFrame.new(x, 0.02, 0), DARK, Enum.Material.Wood).CanCollide = false
	end
	K.wall(ctx, V3(-W / 2, 0, -D / 2), V3(W / 2, 0, -D / 2), H, 3, {color = STONE})
	K.wall(ctx, V3(-W / 2, 0, -D / 2), V3(-W / 2, 0, D / 2), H, 3, {color = STONE})
	K.wall(ctx, V3(W / 2, 0, -D / 2), V3(W / 2, 0, D / 2), H, 3, {color = STONE})
	-- (the south wall, a gap for the door home)
	K.wall(ctx, V3(-W / 2, 0, D / 2), V3(-7, 0, D / 2), H, 3, {color = STONE})
	K.wall(ctx, V3(7, 0, D / 2), V3(W / 2, 0, D / 2), H, 3, {color = STONE})
	K.box(ctx, "Lintel", V3(14, H - 12, 3), CFrame.new(0, 12 + (H - 12) / 2, D / 2), STONE, Enum.Material.Slate)
	K.box(ctx, "Ceiling", V3(W + 4, 1, D + 4), CFrame.new(0, H + 0.5, 0), DARK, Enum.Material.WoodPlanks)
	for x = -W / 2 + 4, W / 2 - 4, 9 do
		K.box(ctx, "Beam", V3(1.6, 1.6, D), CFrame.new(x, H - 0.8, 0), DARK, Enum.Material.Wood).CanCollide = false
	end
	for z = -D / 2 + 6, D / 2 - 6, 14 do
		K.box(ctx, "CrossBeam", V3(W, 1.2, 1.2), CFrame.new(0, H - 2.2, z), DARK, Enum.Material.Wood).CanCollide = false
	end
	-- timber posts down the hall
	for _, x in ipairs({-22, 22}) do
		for _, z in ipairs({-20, 0, 20}) do
			K.box(ctx, "Post", V3(1.8, H, 1.8), CFrame.new(x, H / 2, z), DARK, Enum.Material.Wood)
			K.box(ctx, "PostBrace", V3(1, 1, 7), CFrame.new(x, H - 4, z) * CFrame.Angles(math.rad(35), 0, 0), DARK, Enum.Material.Wood).CanCollide = false
		end
	end
	-- the tables, the chandeliers over them
	for i, x in ipairs({-11, 0, 11}) do
		table_(ctx, CFrame.new(x, 0, 2 + (i == 2 and -4 or 0)), 26)
		chandelier(ctx, V3(x, 15, (i == 2 and -4 or 2)))
	end
	-- THE HEARTH (east wall)
	local hx = W / 2 - 3
	K.box(ctx, "Hearth", V3(4, 16, 18), CFrame.new(hx, 8, 0), STONE2, Enum.Material.Cobblestone)
	K.box(ctx, "HearthMouth", V3(2, 7, 10), CFrame.new(hx - 1.2, 3.5, 0), Color3.fromRGB(14, 10, 8), Enum.Material.Slate)
	K.box(ctx, "Mantle", V3(3.4, 1.2, 20), CFrame.new(hx - 1.4, 9, 0), DARK, Enum.Material.Wood)
	K.box(ctx, "Chimney", V3(4, H - 16, 10), CFrame.new(hx, 16 + (H - 16) / 2, 0), STONE2, Enum.Material.Cobblestone)
	for i = -1, 1 do K.box(ctx, "Log", V3(0.8, 0.8, 4), CFrame.new(hx - 2.6, 0.6, i * 1.4) * CFrame.Angles(0, 0.3 * i, 0), Color3.fromRGB(70, 44, 28), Enum.Material.Wood, ctx.Props) end
	local coals = K.box(ctx, "Coals", V3(2.4, 0.4, 5), CFrame.new(hx - 2.4, 0.3, 0), Color3.fromRGB(200, 70, 20), Enum.Material.Neon, ctx.Props)
	coals.CanCollide = false
	local hl = Instance.new("PointLight"); hl.Color = Color3.fromRGB(255, 120, 50); hl.Range = 40; hl.Brightness = 2; hl.Shadows = true; hl.Parent = coals
	local hf = Instance.new("Fire"); hf.Size = 9; hf.Heat = 10; hf.Color = Color3.fromRGB(255, 140, 50); hf.SecondaryColor = Color3.fromRGB(255, 60, 20); hf.Parent = coals
	for _, z in ipairs({-6, 6}) do candle(ctx, V3(hx - 1.6, 9.6, z), 1.2) end
	K.banner(ctx, V3(hx - 2.2, 11, -14), 10, Color3.fromRGB(120, 30, 30))
	K.banner(ctx, V3(hx - 2.2, 11, 14), 10, Color3.fromRGB(120, 30, 30))

	-- THE COUNTER (west wall): the Treasurer weighs gold here
	local cx = -W / 2 + 9
	K.box(ctx, "Counter", V3(3, 4, 22), CFrame.new(cx, 2, 0), WOOD, Enum.Material.WoodPlanks)
	K.box(ctx, "CounterTop", V3(3.6, 0.5, 22.6), CFrame.new(cx, 4.2, 0), DARK, Enum.Material.Wood)
	shelf(ctx, CFrame.new(-W / 2 + 2.5, 0, -4) * CFrame.Angles(0, -math.pi / 2, 0), 14, 3, function(cf)
		K.cyl(ctx, "Jug", 0.8, 1.2, cf * CFrame.new(0, 0.6, 0), Color3.fromRGB(150, 110, 80), Enum.Material.Slate, ctx.Props).CanCollide = false
	end)
	for i = 0, 4 do
		local g = K.cyl(ctx, "Coins", 1, 0.25 + i * 0.05, CFrame.new(cx - 0.3, 4.6 + i * 0.12, 5 + i * 0.4), GOLD, Enum.Material.Metal, ctx.Props)
		g.CanCollide = false
	end
	-- the scales
	K.cyl(ctx, "ScalePost", 0.25, 2.4, CFrame.new(cx, 5.6, 7.5), GOLD, Enum.Material.Metal, ctx.Props).CanCollide = false
	K.box(ctx, "ScaleBeam", V3(0.2, 0.2, 3), CFrame.new(cx, 6.8, 7.5), GOLD, Enum.Material.Metal, ctx.Props).CanCollide = false
	for _, z in ipairs({6.1, 8.9}) do K.cyl(ctx, "ScalePan", 1.1, 0.12, CFrame.new(cx, 5.8, z), GOLD, Enum.Material.Metal, ctx.Props).CanCollide = false end
	candle(ctx, V3(cx, 4.45, -8), 1)
	table.insert(L.npcs, {id = "Treasurer", cf = CFrame.lookAt(V3(cx - 3.4, 3, 6), V3(0, 3, 6))})

	-- THE SMITH (north-west): a forge, an anvil, racks
	local sx, sz = -W / 2 + 12, -D / 2 + 12
	K.box(ctx, "Forge", V3(8, 4, 6), CFrame.new(sx - 4, 2, sz - 4), STONE2, Enum.Material.Cobblestone)
	local fc = K.box(ctx, "ForgeCoals", V3(5, 0.4, 3.6), CFrame.new(sx - 4, 4.2, sz - 4), Color3.fromRGB(230, 90, 20), Enum.Material.Neon, ctx.Props)
	fc.CanCollide = false
	local fl = Instance.new("PointLight"); fl.Color = Color3.fromRGB(255, 120, 40); fl.Range = 26; fl.Brightness = 2.2; fl.Shadows = true; fl.Parent = fc
	local ff = Instance.new("Fire"); ff.Size = 4; ff.Heat = 8; ff.Parent = fc
	K.box(ctx, "ForgeHood", V3(9, 2, 7), CFrame.new(sx - 4, 11, sz - 4), STONE2, Enum.Material.Slate)
	K.box(ctx, "ForgeFlue", V3(3, H - 12, 3), CFrame.new(sx - 4, 12 + (H - 12) / 2, sz - 4), STONE2, Enum.Material.Slate)
	K.box(ctx, "Stump", V3(2.4, 2.2, 2.4), CFrame.new(sx + 3, 1.1, sz + 2), Color3.fromRGB(80, 56, 36), Enum.Material.Wood)
	K.box(ctx, "Anvil", V3(1.6, 1.1, 3.2), CFrame.new(sx + 3, 2.75, sz + 2), IRON, Enum.Material.Metal)
	K.rack(ctx, CFrame.new(sx + 10, 0, sz - 7))
	K.rack(ctx, CFrame.new(sx - 10 + 6, 0, sz + 9) * CFrame.Angles(0, math.pi / 2, 0))
	for i = 0, 2 do K.box(ctx, "RackSword", V3(0.25, 3.4, 0.08), CFrame.new(sx + 8.6 + i * 1.3, 1.9, sz - 6.8) * CFrame.Angles(0, 0, math.rad(5)), Color3.fromRGB(196, 200, 206), Enum.Material.Metal, ctx.Props).CanCollide = false end
	table.insert(L.npcs, {id = "Smith", cf = CFrame.lookAt(V3(sx + 5.5, 3, sz + 4), V3(sx + 10, 3, sz + 14))})

	-- THE ARMOURER (south-east): armour on stands
	local ax, az = W / 2 - 14, D / 2 - 14
	for i = 0, 3 do
		local at = V3(ax - 6 + i * 4, 0, az + 6)
		K.box(ctx, "StandFoot", V3(2, 0.3, 2), CFrame.new(at + V3(0, 0.15, 0)), DARK, Enum.Material.Wood, ctx.Props)
		K.box(ctx, "StandPost", V3(0.35, 5, 0.35), CFrame.new(at + V3(0, 2.5, 0)), DARK, Enum.Material.Wood, ctx.Props)
		K.box(ctx, "StandPlate", V3(2.4, 2.4, 1.2), CFrame.new(at + V3(0, 3.6, 0)), Color3.fromRGB(150 - i * 12, 156 - i * 12, 166 - i * 10), Enum.Material.Metal, ctx.Props)
		K.box(ctx, "StandShoulders", V3(3.2, 0.6, 1.4), CFrame.new(at + V3(0, 4.8, 0)), Color3.fromRGB(130, 136, 146), Enum.Material.Metal, ctx.Props)
		K.ball(ctx, "StandHelm", 1.3, CFrame.new(at + V3(0, 5.6, 0)), Color3.fromRGB(140, 146, 156), Enum.Material.Metal, ctx.Props)
	end
	K.crate(ctx, V3(ax + 8, 0, az - 2), 3, 20)
	K.barrel(ctx, V3(ax + 8, 0, az + 2))
	table.insert(L.npcs, {id = "Armourer", cf = CFrame.lookAt(V3(ax, 3, az), V3(0, 3, 0))})

	-- THE ALCHEMIST (north-east): shelves of coloured bottles, a cauldron
	local lx, lz = W / 2 - 12, -D / 2 + 12
	local glass = {Color3.fromRGB(210, 40, 50), Color3.fromRGB(70, 200, 110), Color3.fromRGB(90, 140, 255), Color3.fromRGB(255, 160, 40), Color3.fromRGB(170, 80, 230)}
	shelf(ctx, CFrame.new(lx, 0, -D / 2 + 2.5), 14, 3, function(cf)
		local b = K.ball(ctx, "Bottle", 0.8, cf * CFrame.new(0, 0.45, 0), glass[math.random(#glass)], Enum.Material.Neon, ctx.Props)
		b.CanCollide = false
		b.Transparency = 0.15
	end)
	K.cyl(ctx, "Cauldron", 4, 2.6, CFrame.new(lx - 4, 1.3, lz + 3), IRON, Enum.Material.Metal, ctx.Props)
	local brew = K.cyl(ctx, "Brew", 3.4, 0.3, CFrame.new(lx - 4, 2.55, lz + 3), Color3.fromRGB(90, 230, 110), Enum.Material.Neon, ctx.Props)
	brew.CanCollide = false
	local bl = Instance.new("PointLight"); bl.Color = Color3.fromRGB(110, 255, 140); bl.Range = 16; bl.Brightness = 1.6; bl.Parent = brew
	local bp = Instance.new("ParticleEmitter"); bp.Color = ColorSequence.new(Color3.fromRGB(150, 255, 170)); bp.LightEmission = 0.8; bp.Rate = 6
	bp.Speed = NumberRange.new(1, 2); bp.Lifetime = NumberRange.new(1.5, 2.5); bp.Size = NumberSequence.new(0.6, 0); bp.Parent = brew
	K.box(ctx, "AlchemyTable", V3(7, 0.5, 3), CFrame.new(lx + 3, 3, lz + 2), WOOD, Enum.Material.WoodPlanks, ctx.Props)
	for _, x in ipairs({0.5, 5.5}) do K.box(ctx, "Leg", V3(0.4, 3, 2.6), CFrame.new(lx + x, 1.5, lz + 2), DARK, Enum.Material.Wood, ctx.Props) end
	for i = 0, 3 do
		local b = K.ball(ctx, "Flask", 0.7, CFrame.new(lx + 1 + i * 1.3, 3.6, lz + 2), glass[i + 1], Enum.Material.Neon, ctx.Props)
		b.CanCollide = false
	end
	table.insert(L.npcs, {id = "Alchemist", cf = CFrame.lookAt(V3(lx + 3, 3, lz + 6), V3(0, 3, 0))})

	-- YOUR STASH (south-west): a strongroom door and a great iron-bound chest
	local tx, tz = -W / 2 + 10, D / 2 - 10
	K.box(ctx, "StrongDoor", V3(0.6, 10, 7), CFrame.new(-W / 2 + 1.8, 5, tz - 4), IRON, Enum.Material.DiamondPlate)
	for _, y in ipairs({2, 5, 8}) do K.box(ctx, "DoorBand", V3(0.7, 0.5, 7.2), CFrame.new(-W / 2 + 1.9, y, tz - 4), Color3.fromRGB(80, 74, 66), Enum.Material.Metal) end
	K.box(ctx, "Chest", V3(5, 2.6, 3), CFrame.new(tx, 1.3, tz), Color3.fromRGB(100, 64, 36), Enum.Material.WoodPlanks)
	K.box(ctx, "ChestLid", V3(5.2, 1, 3.2), CFrame.new(tx, 3.1, tz), Color3.fromRGB(110, 70, 40), Enum.Material.WoodPlanks)
	for _, x in ipairs({-1.8, 1.8}) do K.box(ctx, "ChestBand", V3(0.4, 3.7, 3.3), CFrame.new(tx + x, 1.85, tz), GOLD, Enum.Material.Metal) end
	local seam = K.box(ctx, "ChestGlow", V3(4.8, 0.15, 3), CFrame.new(tx, 2.65, tz), GOLD, Enum.Material.Neon, ctx.Props)
	seam.CanCollide = false
	local sl = Instance.new("PointLight"); sl.Color = GOLD; sl.Range = 10; sl.Brightness = 1.2; sl.Parent = seam
	L.points.stash = CFrame.new(tx, 3, tz)

	-- THE NOTICE BOARD (by the gate): class and perks
	local bxp = V3(-14, 0, -D / 2 + 2.2)
	K.box(ctx, "Board", V3(8, 6, 0.5), CFrame.new(bxp + V3(0, 6, 0)), WOOD, Enum.Material.WoodPlanks)
	for i = 0, 5 do
		K.box(ctx, "Notice", V3(1.6, 2, 0.1), CFrame.new(bxp + V3(-3 + i * 1.2 + (i % 2) * 0.2, 6 + (i % 2) * 0.6 - 0.3, 0.3)) * CFrame.Angles(0, 0, (i - 2.5) * 0.06), Color3.fromRGB(226, 214, 180), Enum.Material.SmoothPlastic, ctx.Props).CanCollide = false
	end
	candle(ctx, bxp + V3(-4.6, 3.2, 0.6), 0.8)
	L.points.board = CFrame.new(bxp + V3(0, 4, 2))

	-- THE DUNGEON GATE (north wall's middle): a stone arch over stairs down into the dark
	local gz = -D / 2
	for _, x in ipairs({-7, 7}) do K.box(ctx, "GatePost", V3(3, 16, 4), CFrame.new(x, 8, gz + 1), STONE2, Enum.Material.Cobblestone) end
	K.box(ctx, "GateTop", V3(17, 3, 4), CFrame.new(0, 17, gz + 1), STONE2, Enum.Material.Cobblestone)
	K.box(ctx, "GateKey", V3(3, 4, 4.4), CFrame.new(0, 16.6, gz + 1), STONE, Enum.Material.Slate)
	local dark = K.box(ctx, "GateDark", V3(11, 15, 1), CFrame.new(0, 7.5, gz - 0.2), Color3.fromRGB(4, 4, 6), Enum.Material.SmoothPlastic)
	dark.CanCollide = true
	for i = 1, 6 do
		K.box(ctx, "GateStep", V3(11, 0.6, 2), CFrame.new(0, -0.3 - i * 0.6 + 0.6, gz + 5 - i * 1.6), STONE2, Enum.Material.Slate).CanCollide = false
	end
	for _, x in ipairs({-9.5, 9.5}) do
		K.box(ctx, "Sconce", V3(0.6, 0.6, 1.2), CFrame.new(x, 9, gz + 3), IRON, Enum.Material.Metal, ctx.Props)
		flame(ctx, V3(x, 10, gz + 3.6), 0.7, 18, 1.6, Color3.fromRGB(140, 200, 255))
	end
	local mist = K.box(ctx, "GateMist", V3(11, 2, 6), CFrame.new(0, 0.5, gz + 3), Color3.fromRGB(20, 24, 34), Enum.Material.SmoothPlastic, ctx.Props)
	mist.Transparency = 1; mist.CanCollide = false
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(60, 70, 90))
	pe.Rate = 6; pe.Speed = NumberRange.new(0.5, 1.2); pe.Lifetime = NumberRange.new(3, 5); pe.Size = NumberSequence.new(3, 6)
	pe.Transparency = NumberSequence.new(0.7, 1); pe.Parent = mist
	L.points.gate = CFrame.new(0, 4, gz + 6)

	-- THE DOOR HOME (south wall): daylight through it
	local dz = D / 2
	local doorLight = K.box(ctx, "DoorLight", V3(12, 12, 0.4), CFrame.new(0, 6, dz + 1.4), Color3.fromRGB(255, 236, 190), Enum.Material.Neon)
	doorLight.CanCollide = true
	doorLight.Transparency = 0.15
	local dl = Instance.new("PointLight"); dl.Color = Color3.fromRGB(255, 230, 180); dl.Range = 28; dl.Brightness = 1.4; dl.Parent = doorLight
	for _, x in ipairs({-6.5, 6.5}) do K.box(ctx, "DoorPost", V3(1.2, 12, 2.4), CFrame.new(x, 6, dz), DARK, Enum.Material.Wood) end
	K.box(ctx, "DoorBeam", V3(14, 1.4, 2.4), CFrame.new(0, 12.6, dz), DARK, Enum.Material.Wood)
	L.points.exit = CFrame.new(0, 4, dz - 3)

	-- wall torches round the hall, barrels and crates in its corners, banners
	for _, z in ipairs({-28, -12, 12, 28}) do
		for _, s in ipairs({-1, 1}) do
			if not (s == 1 and math.abs(z) < 12) then
				local x = s * (W / 2 - 1.8)
				K.box(ctx, "Bracket", V3(1, 0.4, 0.4), CFrame.new(x - s * 0.4, 9, z), IRON, Enum.Material.Metal, ctx.Props)
				flame(ctx, V3(x - s * 1, 9.8, z), 0.55, 18, 1.2)
			end
		end
	end
	for _, at in ipairs({V3(-30, 0, 36), V3(-26, 0, 37), V3(26, 0, -37), V3(31, 0, 36)}) do K.barrel(ctx, at) end
	K.crate(ctx, V3(-34, 0, -36), 3, 10)
	K.crate(ctx, V3(-31, 0, -37), 2.4, 40)
	for _, x in ipairs({-28, 28}) do K.banner(ctx, V3(x, 0, -D / 2 + 2), 14, Color3.fromRGB(110, 26, 30)) end

	-- where you come in: by the door home
	for i = -2, 2 do K.spawn(ctx, V3(i * 4, 1, dz - 10), nil, V3(i * 4, 1, 0)) end
	K.camera(ctx, V3(30, 16, 34), V3(-6, 4, -10))
	K.camera(ctx, V3(-36, 12, 10), V3(10, 4, -14))
	K.lighting(ctx, {ClockTime = 0, Brightness = 0, Ambient = Color3.fromRGB(46, 36, 30), OutdoorAmbient = Color3.fromRGB(30, 26, 24),
		FogColor = Color3.fromRGB(20, 14, 10), FogEnd = 400, FogStart = 120})
	K.atmosphere(ctx, {Density = 0.18, Offset = 0, Color = Color3.fromRGB(60, 40, 28), Decay = Color3.fromRGB(30, 20, 14), Glare = 0, Haze = 0.6})
	ctx.model:SetAttribute("Generated", true)
	ctx.model:SetAttribute("Tavern", true)
	local ok, err = pcall(K.finish, ctx)
	if not ok then
		warn("[TavernMap] finish:", err)
		local maps = ServerStorage:FindFirstChild("Maps") or Instance.new("Folder")
		maps.Name = "Maps"; maps.Parent = ServerStorage
		ctx.model.Parent = maps
	end
	return name, L
end

return TavernMap
