--[[ MAP PROPS — the bigger set pieces the Horde maps share, added onto MapKit:

       require(script.Parent.MapProps)(K)   -- then K.wagon, K.pine2 …

     K.wheel(ctx, frame)                   a solid plank cart wheel (axis = frame X)
     K.wagon(ctx, frame, opts)             a covered wagon; opts.torn (0..1 of the canvas gone),
                                           opts.missing = {wheel indices 1..4}, opts.nocover
     K.pine2(ctx, pos, h, tiers, sides)    a pine, lighter than K.tree for a whole forest
     K.oak(ctx, pos, h)                    a broad leafy tree
     K.deadTree(ctx, pos, h)               a bare grey tree with crooked branches
     K.bush(ctx, pos, s)                   a clump of leaves
     K.campfire(ctx, pos)                  stones, logs, fire, smoke, a pot on a tripod
     K.lantern(ctx, pos, h)                a lantern on a crooked post
     K.brazier(ctx, pos)                   an iron fire basket on legs
     K.grave(ctx, frame)                   a leaning headstone and a low mound
     K.arrow(ctx, at, dir)                 an arrow stuck in something
     K.sack(ctx, pos)                      a tied grain sack
     K.longship(ctx, frame, sail)          a beached longship: hull, shields, mast, striped sail ]]

return function(K)
	local C, M = K.C, K.M
	local V3 = Vector3.new
	local DEG = math.rad
	local CANVAS = Color3.fromRGB(214, 202, 172)
	local OAKLEAF = {Color3.fromRGB(58, 92, 46), Color3.fromRGB(74, 108, 52), Color3.fromRGB(48, 78, 40)}
	local r = Random.new(23)

	function K.wheel(ctx, frame)
		local f = frame * CFrame.Angles(0, 0, DEG(90))
		K.cyl(ctx, "WheelRim", 3.3, 0.3, f, C.IRON, M.Metal, ctx.Props)
		K.cyl(ctx, "Wheel", 3.0, 0.38, f, C.DARKWOOD, M.WoodPlanks, ctx.Props)
		K.cyl(ctx, "Hub", 0.8, 0.6, f, C.IRON, M.Metal, ctx.Props)
	end

	-- a covered wagon in its own frame: ground centre, length along Z, front -Z
	function K.wagon(ctx, frame, opts)
		opts = opts or {}
		local function box(name, size, at, color, mat) return K.box(ctx, name, size, frame * at, color, mat, ctx.Props) end
		box("WagonBed", V3(5.6, 0.5, 11), CFrame.new(0, 2.4, 0), C.WOOD, M.WoodPlanks)
		for _, s in ipairs({-1, 1}) do
			box("WagonSide", V3(0.35, 1.6, 11), CFrame.new(s * 2.8, 3.45, 0), C.WOOD, M.WoodPlanks)
			box("WagonBeam", V3(0.5, 0.5, 11.6), CFrame.new(s * 1.6, 1.95, 0), C.DARKWOOD, M.Wood)
		end
		box("WagonFront", V3(5.6, 1.6, 0.35), CFrame.new(0, 3.45, -5.4), C.WOOD, M.WoodPlanks)
		if not opts.noTail then box("WagonTail", V3(5.6, 1.2, 0.35), CFrame.new(0, 3.25, 5.4), C.WOOD, M.WoodPlanks) end
		box("Axle", V3(6.6, 0.4, 0.4), CFrame.new(0, 1.6, -3.6), C.IRON, M.Metal)
		box("Axle", V3(6.6, 0.4, 0.4), CFrame.new(0, 1.6, 3.6), C.IRON, M.Metal)
		local miss = {}
		for _, i in ipairs(opts.missing or {}) do miss[i] = true end
		local i = 0
		for _, z in ipairs({-3.6, 3.6}) do
			for _, s in ipairs({-1, 1}) do
				i += 1
				if not miss[i] then K.wheel(ctx, frame * CFrame.new(s * 3.3, 1.6, z)) end
			end
		end
		if not opts.noTongue then
			box("Tongue", V3(0.35, 0.35, 6.4), CFrame.new(0, 1.3, -8.4) * CFrame.Angles(DEG(10), 0, 0), C.DARKWOOD, M.Wood)
			box("Yoke", V3(3.2, 0.3, 0.3), CFrame.new(0, 0.8, -11.2), C.DARKWOOD, M.Wood)
		end
		if opts.nocover then return end
		-- hoops over the bed and the canvas between them (opts.torn: share of panels gone)
		local zs = {-4.6, -1.55, 1.55, 4.6}
		local pts = {}
		for k = 0, 6 do
			local a = DEG(k * 30)
			table.insert(pts, V3(math.cos(a) * 2.75, 4.2 + math.sin(a) * 2.5, 0))
		end
		for _, z in ipairs(zs) do
			for k = 1, #pts - 1 do
				local a, b = pts[k] + V3(0, 0, z), pts[k + 1] + V3(0, 0, z)
				local d = b - a
				box("Hoop", V3(d.Magnitude + 0.1, 0.18, 0.18), CFrame.new((a + b) / 2) * CFrame.Angles(0, 0, math.atan2(d.Y, d.X)), C.DARKWOOD, M.Wood)
			end
		end
		local torn = opts.torn or 0
		for g = 1, #zs - 1 do
			local zm, zl = (zs[g] + zs[g + 1]) / 2, zs[g + 1] - zs[g] + 0.15
			for k = 1, #pts - 1 do
				if r:NextNumber() >= torn then
					local a, b = pts[k], pts[k + 1]
					local d = b - a
					local mid = (a + b) / 2 + d.Unit:Cross(V3(0, 0, 1)) * -0.05
					local p = box("Canvas", V3(d.Magnitude + 0.12, 0.08, zl), CFrame.new(mid.X, mid.Y, zm) * CFrame.Angles(0, 0, math.atan2(d.Y, d.X)), CANVAS, M.Fabric)
					p.CanCollide = false
				end
			end
		end
	end

	-- a pine for a whole forest: a trunk and `tiers` cones of `sides` wedges
	function K.pine2(ctx, pos, h, tiers, sides, color)
		tiers, sides = tiers or 3, sides or 6
		local trunk = K.cyl(ctx, "Trunk", 0.9 + h * 0.02, h * 0.45, pos + V3(0, h * 0.225, 0), C.DARKWOOD, M.Wood, ctx.Props)
		for t = 0, tiers - 1 do
			local f = t / math.max(tiers - 1, 1)
			local rr = h * (0.3 - f * 0.17)
			K.cone(ctx, "Needles", pos + V3(0, h * (0.26 + f * 0.42), 0), rr, h * (0.34 - f * 0.06), color or (t == 0 and C.LEAFDARK or Color3.fromRGB(52, 98, 50)), M.Grass, ctx.Props, true, sides)
		end
		return trunk
	end
	function K.oak(ctx, pos, h)
		h = h or 14
		K.cyl(ctx, "Trunk", 1.4, h * 0.55, pos + V3(0, h * 0.275, 0), Color3.fromRGB(92, 70, 50), M.Wood, ctx.Props)
		for i = 1, 5 do
			local off = V3(r:NextNumber(-1, 1) * h * 0.22, h * (0.62 + r:NextNumber(0, 0.22)), r:NextNumber(-1, 1) * h * 0.22)
			local b = K.ball(ctx, "Leaves", h * r:NextNumber(0.32, 0.46), pos + off, OAKLEAF[i % 3 + 1], M.Grass, ctx.Props)
			b.CanCollide = false
		end
	end
	function K.deadTree(ctx, pos, h)
		h = h or 12
		local grey = Color3.fromRGB(86, 80, 74)
		K.cyl(ctx, "DeadTrunk", 1.1, h, CFrame.new(pos + V3(0, h / 2, 0)) * CFrame.Angles(DEG(r:NextNumber(-5, 5)), 0, DEG(r:NextNumber(-5, 5))), grey, M.Wood, ctx.Props)
		for i = 1, 5 do
			local y = h * r:NextNumber(0.45, 0.95)
			local a = r:NextNumber(0, math.pi * 2)
			local len = h * r:NextNumber(0.2, 0.35)
			local b = K.box(ctx, "Branch", V3(0.35, len, 0.35), CFrame.new(pos + V3(0, y, 0)) * CFrame.Angles(0, a, 0) * CFrame.Angles(DEG(r:NextNumber(35, 65)), 0, 0) * CFrame.new(0, len / 2, 0), grey, M.Wood, ctx.Props)
			b.CanCollide = false
		end
	end
	function K.bush(ctx, pos, s)
		s = s or 3
		for i = 1, 3 do
			local b = K.ball(ctx, "Bush", s * r:NextNumber(0.6, 1), pos + V3(r:NextNumber(-0.4, 0.4) * s, s * 0.3, r:NextNumber(-0.4, 0.4) * s), OAKLEAF[i], M.Grass, ctx.Props)
			b.CanCollide = false
		end
	end

	function K.campfire(ctx, pos)
		for i = 1, 9 do
			local a = i / 9 * math.pi * 2
			K.ball(ctx, "FireStone", 0.9, pos + V3(math.cos(a) * 1.8, 0.25, math.sin(a) * 1.8), C.STONEDARK, M.Slate, ctx.Props)
		end
		for i = 1, 3 do
			K.cyl(ctx, "FireLog", 0.6, 3, CFrame.new(pos + V3(0, 0.4, 0)) * CFrame.Angles(0, DEG(i * 60), 0) * CFrame.Angles(DEG(78), 0, 0), C.DARKWOOD, M.Wood, ctx.Props)
		end
		local embers = K.box(ctx, "Embers", V3(2.2, 0.3, 2.2), pos + V3(0, 0.2, 0), Color3.fromRGB(255, 110, 40), M.Neon, ctx.Props)
		embers.CanCollide = false
		local fire = Instance.new("Fire"); fire.Size = 5; fire.Heat = 9; fire.Parent = embers
		local light = Instance.new("PointLight"); light.Color = C.FIRE; light.Range = 26; light.Brightness = 2.2; light.Shadows = true; light.Parent = embers
		local smoke = Instance.new("Smoke"); smoke.Size = 3; smoke.RiseVelocity = 4; smoke.Opacity = 0.08; smoke.Color = Color3.fromRGB(110, 106, 100); smoke.Parent = embers
		-- a pot on a tripod
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2
			local foot = pos + V3(math.cos(a) * 2.2, 0, math.sin(a) * 2.2)
			local top = pos + V3(0, 4.2, 0)
			K.box(ctx, "Tripod", V3(0.2, (top - foot).Magnitude, 0.2), CFrame.lookAt((foot + top) / 2, top) * CFrame.Angles(DEG(90), 0, 0), C.DARKWOOD, M.Wood, ctx.Props).CanCollide = false
		end
		K.ball(ctx, "Pot", 1.4, pos + V3(0, 2.6, 0), C.IRON, M.Metal, ctx.Props).CanCollide = false
		return embers
	end
	function K.lantern(ctx, pos, h)
		h = h or 7
		K.cyl(ctx, "LanternPost", 0.45, h, pos + V3(0, h / 2, 0), C.DARKWOOD, M.Wood, ctx.Props)
		K.box(ctx, "LanternArm", V3(0.3, 0.3, 1.6), pos + V3(0, h - 0.2, -0.7), C.DARKWOOD, M.Wood, ctx.Props)
		local lamp = K.box(ctx, "Lantern", V3(0.7, 0.9, 0.7), pos + V3(0, h - 1, -1.3), Color3.fromRGB(255, 196, 110), M.Neon, ctx.Props)
		lamp.CanCollide = false
		K.box(ctx, "LanternCap", V3(0.9, 0.2, 0.9), pos + V3(0, h - 0.48, -1.3), C.IRON, M.Metal, ctx.Props).CanCollide = false
		local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(255, 190, 110); light.Range = 18; light.Brightness = 1.6; light.Parent = lamp
		return lamp
	end
	function K.brazier(ctx, pos)
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2
			K.box(ctx, "BrazierLeg", V3(0.25, 3.2, 0.25), CFrame.new(pos + V3(math.cos(a) * 0.9, 1.5, math.sin(a) * 0.9)) * CFrame.Angles(0, -a, DEG(10)), C.IRON, M.Metal, ctx.Props)
		end
		K.cyl(ctx, "BrazierBowl", 2.4, 0.9, pos + V3(0, 3.2, 0), C.IRON, M.Metal, ctx.Props)
		local coals = K.cyl(ctx, "Coals", 2.0, 0.3, pos + V3(0, 3.65, 0), Color3.fromRGB(255, 120, 40), M.Neon, ctx.Props)
		coals.CanCollide = false
		local fire = Instance.new("Fire"); fire.Size = 3.5; fire.Heat = 7; fire.Parent = coals
		local light = Instance.new("PointLight"); light.Color = C.FIRE; light.Range = 22; light.Brightness = 2; light.Parent = coals
		return coals
	end
	function K.grave(ctx, frame)
		local stone = Color3.fromRGB(128, 130, 134)
		K.box(ctx, "Headstone", V3(2.2, 2.8, 0.5), frame * CFrame.new(0, 1.2, 0) * CFrame.Angles(DEG(r:NextNumber(-12, 8)), 0, DEG(r:NextNumber(-8, 8))), stone, M.Slate, ctx.Props)
		local mound = K.ball(ctx, "Mound", 3, frame * CFrame.new(0, -0.6, 2.4), Color3.fromRGB(70, 60, 48), M.Ground, ctx.Props)
		mound.Shape = Enum.PartType.Block   -- (a Ball is always round: block first, then stretch)
		mound.Size = V3(3, 1.6, 5)
		local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = mound
		mound.CanCollide = false
	end
	function K.arrow(ctx, at, dir)
		local f = CFrame.lookAt(at, at + dir)
		K.cyl(ctx, "Arrow", 0.12, 2.4, f * CFrame.new(0, 0, 1.1) * CFrame.Angles(DEG(90), 0, 0), C.DARKWOOD, M.Wood, ctx.Props).CanCollide = false
		for _, a in ipairs({0, 120, 240}) do
			K.box(ctx, "Fletching", V3(0.04, 0.25, 0.5), f * CFrame.new(0, 0, 2.1) * CFrame.Angles(0, 0, DEG(a)) * CFrame.new(0, 0.1, 0), Color3.fromRGB(230, 226, 214), M.Fabric, ctx.Props).CanCollide = false
		end
	end
	function K.sack(ctx, pos)
		local s = K.ball(ctx, "Sack", 1.8, pos + V3(0, 0.8, 0), Color3.fromRGB(176, 150, 106), M.Fabric, ctx.Props)
		s.Shape = Enum.PartType.Block
		local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Scale = V3(1, 1.2, 0.9); mesh.Parent = s
		K.cyl(ctx, "SackTie", 0.7, 0.4, pos + V3(0, 1.95, 0), C.ROPE, M.Fabric, ctx.Props).CanCollide = false
	end

	-- a longship hauled up on the sand: frame = keel centre on the ground, bow toward -Z
	function K.longship(ctx, frame, sail)
		local hull = Color3.fromRGB(96, 66, 40)
		local function box(name, size, at, color, mat) return K.box(ctx, name, size, frame * at, color or hull, mat or M.WoodPlanks, ctx.Props) end
		box("Keel", V3(1.2, 1, 22), CFrame.new(0, 0.5, 0))
		box("Bottom", V3(3.6, 0.5, 18), CFrame.new(0, 1.1, 0))
		for _, s in ipairs({-1, 1}) do
			box("Strake", V3(0.4, 2.4, 18), CFrame.new(s * 2.4, 2.2, 0) * CFrame.Angles(0, 0, DEG(-s * 24)))
			box("Strake", V3(0.4, 1.4, 17), CFrame.new(s * 3.0, 3.6, 0) * CFrame.Angles(0, 0, DEG(-s * 10)), Color3.fromRGB(120, 84, 52))
			-- the shields along the rail
			for i = -3, 3 do
				local col = (i % 2 == 0) and Color3.fromRGB(176, 42, 42) or Color3.fromRGB(226, 218, 196)
				K.cyl(ctx, "Shield", 1.8, 0.25, frame * CFrame.new(s * 3.35, 3.7, i * 2.3) * CFrame.Angles(0, 0, DEG(90)), col, M.Wood, ctx.Props).CanCollide = false
				K.cyl(ctx, "Boss", 0.45, 0.35, frame * CFrame.new(s * 3.45, 3.7, i * 2.3) * CFrame.Angles(0, 0, DEG(90)), C.IRON, M.Metal, ctx.Props).CanCollide = false
			end
		end
		-- the stem and stern rising in a curve, a dragon's head on the bow
		for _, e in ipairs({-1, 1}) do
			for k = 0, 4 do
				local a = DEG(k * 18)
				local z = e * (9 + math.sin(a) * 2.2)
				local y = 1.8 + (1 - math.cos(a)) * 2.6 + k * 0.6
				box("Stem", V3(0.9, 1.6, 1.4), CFrame.new(0, y, z) * CFrame.Angles(DEG(-e * k * 18), 0, 0))
			end
		end
		K.ball(ctx, "DragonHead", 1.6, frame * CFrame.new(0, 7.6, -11.8), Color3.fromRGB(70, 48, 30), M.Wood, ctx.Props).CanCollide = false
		K.wedge(ctx, "DragonJaw", V3(0.8, 0.8, 1.6), frame * CFrame.new(0, 7.3, -12.9) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(70, 48, 30), M.Wood, ctx.Props).CanCollide = false
		for _, s in ipairs({-0.35, 0.35}) do K.ball(ctx, "DragonEye", 0.3, frame * CFrame.new(s, 7.9, -12.4), Color3.fromRGB(230, 60, 40), M.Neon, ctx.Props).CanCollide = false end
		if sail ~= false then
			K.cyl(ctx, "Mast", 0.7, 14, frame * CFrame.new(0, 8, 0), C.DARKWOOD, M.Wood, ctx.Props)
			box("Yard", V3(11, 0.5, 0.5), CFrame.new(0, 13.6, 0), C.DARKWOOD, M.Wood)
			for i = 0, 3 do
				local col = (i % 2 == 0) and Color3.fromRGB(170, 40, 40) or Color3.fromRGB(230, 222, 200)
				local p = box("Sail", V3(10.4, 1.7, 0.15), CFrame.new(0, 12.4 - i * 1.7, 0.3) * CFrame.Angles(DEG(4), 0, 0), col, M.Fabric)
				p.CanCollide = false
			end
		end
	end
end
