--[[ BUILDER — turns a BLUEPRINT (a list of part specs) into real Instances.
     Blueprints live in Build ▸ Weapons / Armor / Body. The server runs them at
     startup for anything that has no model yet (Build ▸ Blueprints.ensureAll),
     so a weapon Tool synced from the repo with only its scripts grows a Handle,
     a Hitbox and a body; an armor set with only a Config grows its clothing
     models; hair / beards / faces appear in Cosmetics ▸ Body.
     In Studio edit mode you can materialize editable copies from the command
     bar:   require(game.ServerScriptService.Build.Blueprints).ensureAll()

     A spec:  {kind = "box" | "cyl" | "ball" | "wedge" | "cwedge",
               name = "Blade", size = Vector3, cf = CFrame (relative to the model origin),
               color = Color3, material = Enum.Material, transparency = 0..1,
               reflectance = 0..1, attrs = {SkinPart = "Blade"}}
     "cyl" is a cylinder whose axis is the spec's local Y (size = diameter, height, diameter).
     Every part comes out anchored, non-colliding, massless; Dresser / the
     Tool code re-weld as they need. ]]

local B = {}

--------------------------------------------------------------------
--  PALETTE (shared by every blueprint so the set looks like one game)
--------------------------------------------------------------------
B.C = {
	STEEL      = Color3.fromRGB(196, 203, 212),
	BRIGHT     = Color3.fromRGB(226, 232, 240),
	DARKSTEEL  = Color3.fromRGB(96, 104, 116),
	IRON       = Color3.fromRGB(130, 136, 146),
	BLACKIRON  = Color3.fromRGB(44, 46, 52),
	GOLD       = Color3.fromRGB(232, 184, 74),
	BRASS      = Color3.fromRGB(190, 150, 80),
	BRONZE     = Color3.fromRGB(176, 120, 72),
	WOOD       = Color3.fromRGB(140, 96, 56),
	DARKWOOD   = Color3.fromRGB(86, 58, 34),
	LEATHER    = Color3.fromRGB(110, 72, 44),
	DARKLEATHER= Color3.fromRGB(62, 42, 28),
	ROPE       = Color3.fromRGB(190, 160, 110),
	STRAW      = Color3.fromRGB(214, 184, 116),
	CLOTH      = Color3.fromRGB(70, 110, 220),   -- Primary default (team blue)
	CLOTH2     = Color3.fromRGB(42, 62, 120),    -- Secondary default
	ACCENT     = Color3.fromRGB(232, 184, 74),   -- Accent default
	MAIL       = Color3.fromRGB(120, 126, 136),
	LINEN      = Color3.fromRGB(222, 212, 190),
	FUR        = Color3.fromRGB(150, 128, 100),
	GREEN      = Color3.fromRGB(70, 120, 60),
	RED        = Color3.fromRGB(170, 48, 44),
	BLACK      = Color3.fromRGB(28, 28, 30),
	WHITE      = Color3.fromRGB(240, 240, 240),
	HAIR       = Color3.fromRGB(58, 42, 26),
	SKIN       = Color3.fromRGB(217, 180, 138),
	EYE        = Color3.fromRGB(30, 30, 34),
	MOUTH      = Color3.fromRGB(110, 50, 50),
}
B.M = {
	METAL = Enum.Material.Metal, PLASTIC = Enum.Material.SmoothPlastic, WOOD = Enum.Material.Wood,
	FABRIC = Enum.Material.Fabric, LEATHER = Enum.Material.SmoothPlastic, PLATE = Enum.Material.DiamondPlate,
	FOIL = Enum.Material.Foil, SLATE = Enum.Material.Slate, NEON = Enum.Material.Neon, GRANITE = Enum.Material.Granite,
}

local DEG = math.rad
B.DEG = DEG
function B.cf(x, y, z, rx, ry, rz)
	return CFrame.new(x or 0, y or 0, z or 0) * CFrame.Angles(DEG(rx or 0), DEG(ry or 0), DEG(rz or 0))
end
function B.v(x, y, z) return Vector3.new(x, y, z) end

--------------------------------------------------------------------
--  ONE PART
--------------------------------------------------------------------
function B.make(spec, origin)
	origin = origin or CFrame.identity
	local part
	local kind = spec.kind or "box"
	if kind == "wedge" then part = Instance.new("WedgePart")
	elseif kind == "cwedge" then part = Instance.new("CornerWedgePart")
	else
		part = Instance.new("Part")
		if kind == "cyl" then part.Shape = Enum.PartType.Cylinder
		elseif kind == "ball" then part.Shape = Enum.PartType.Ball
		else part.Shape = Enum.PartType.Block end
	end
	local size, cf = spec.size, spec.cf or CFrame.identity
	if kind == "cyl" then
		-- a cylinder's axis is X; the spec gives (diameter, height, diameter) along its Y
		size = Vector3.new(size.Y, size.X, size.Z)
		cf = cf * CFrame.Angles(0, 0, DEG(90))
	end
	part.Name = spec.name or "Part"
	part.Size = size
	part.CFrame = origin * cf
	part.Color = spec.color or B.C.STEEL
	part.Material = spec.material or B.M.PLASTIC
	part.Transparency = spec.transparency or 0
	part.Reflectance = spec.reflectance or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = spec.canQuery == true
	part.Massless = true
	part.CastShadow = spec.shadow ~= false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(spec.attrs or {}) do part:SetAttribute(k, v) end
	return part
end

-- a Model from specs; opts.primary names the PrimaryPart
function B.build(name, specs, opts)
	opts = opts or {}
	local m = Instance.new("Model")
	m.Name = name
	for _, s in ipairs(specs) do
		local p = B.make(s, opts.origin)
		p.Parent = m
		if opts.primary and p.Name == opts.primary then m.PrimaryPart = p end
	end
	if not m.PrimaryPart then m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart") end
	-- faces laid flush on faces flicker (z-fighting): nudge them apart
	require(script.Parent:FindFirstChild("Defight") or game:GetService("ReplicatedStorage"):WaitForChild("Defight")).run(m)
	return m
end

-- weld every part to the root (WeldConstraint) and unanchor: for Tools
function B.weld(container, root)
	for _, p in ipairs(container:GetDescendants()) do
		if p:IsA("BasePart") and p ~= root then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = root, p
			w.Parent = p
			p.Anchored = false
		end
	end
	root.Anchored = false
end

-- paint a spec list with a shared tint (nil values keep the spec's own)
function B.tint(specs, colorBySlot)
	for _, s in ipairs(specs) do
		local slot = s.attrs and s.attrs.SkinPart
		if slot and colorBySlot[slot] then s.color = colorBySlot[slot] end
	end
	return specs
end

-- helpers for common spec shapes ------------------------------------
function B.box(name, size, cf, color, material, attrs, extra)
	local s = {kind = "box", name = name, size = size, cf = cf, color = color, material = material, attrs = attrs}
	for k, v in pairs(extra or {}) do s[k] = v end
	return s
end
function B.cyl(name, diameter, height, cf, color, material, attrs, extra)
	local s = {kind = "cyl", name = name, size = Vector3.new(diameter, height, diameter), cf = cf, color = color, material = material, attrs = attrs}
	for k, v in pairs(extra or {}) do s[k] = v end
	return s
end
function B.ball(name, diameter, cf, color, material, attrs)
	return {kind = "ball", name = name, size = Vector3.new(diameter, diameter, diameter), cf = cf, color = color, material = material, attrs = attrs}
end
function B.wedge(name, size, cf, color, material, attrs)
	return {kind = "wedge", name = name, size = size, cf = cf, color = color, material = material, attrs = attrs}
end
-- append list b to list a
function B.join(a, ...)
	for _, list in ipairs({...}) do for _, s in ipairs(list) do table.insert(a, s) end end
	return a
end
-- a flat ring of N boxes around the Y axis (rivets, studs, a crown)
function B.ring(name, n, radius, size, y, color, material, attrs)
	local out = {}
	for i = 1, n do
		local a = (i - 1) / n * 2 * math.pi
		out[#out + 1] = B.box(name, size, CFrame.new(math.cos(a) * radius, y, math.sin(a) * radius) * CFrame.Angles(0, -a, 0), color, material, attrs)
	end
	return out
end

return B
