--[[ SHIELD DRESS — what makes one shield skin look nothing like another (Catalog ▸ ArsenalSkins):
     the board's MATERIAL and the rim's, and ORNAMENTS built onto the shield that change its
     shape — wings, a crown, a sunburst behind it, horns, thorns, vines, studs, iron bands,
     hanging feathers, ribbons, battlements, a gem, a glowing edge. (The arms painted on the
     board are Heraldry's.) Every piece follows the board's outline (ShieldFace's FaceW / FaceH
     / FaceY / FaceZ / FaceShape: Build ▸ ArsenalBlueprints), welded to the Handle (anchored on
     an anchored menu model). Dresser.applySkin calls it; a new skin clears the old dress and
     puts the materials back first.

       ShieldDress.apply(container, skin) -> bool     ShieldDress.clear(container)

     A skin's fields: field (the board's material: "Fabric", "WoodPlanks", "Marble", "Foil"…),
     rim (the rim's and boss's material), accent (the ornaments' colour; else grip), glow (the glowing
     bits'), wing / wingMaterial, horn, feather, ribbon (those ornaments' own colours), and
     adorn = {…} of: studs gilded glowedge boss gem spike thorns wings crown rays horns
     feathers vines runes bands tassels merlons flames. ]]

local ShieldDress = {}
local TAG = "ShieldDressPart"
local C = Color3.fromRGB

-- each board's outline in the face's frame (x across, y up; origin at FaceY): a polygon, or a circle
local function outline(shape, W, H)
	if shape == "heater" then
		return {{-1.15, 1.28}, {1.15, 1.28}, {1.15, -0.25}, {0, -1.4}, {-1.15, -0.25}}
	elseif shape == "kite" then
		local pts = {}
		for k = 0, 8 do
			local a = math.pi * (k / 8)
			table.insert(pts, {math.cos(a) * 1.1, 0.65 + math.sin(a) * 1.1})
		end
		table.insert(pts, {-1.1, -1.0}); table.insert(pts, {0, -2.1}); table.insert(pts, {1.1, -1.0})
		-- (counter-clockwise from the right: the arc runs right → left over the top)
		local out = {}
		for i = 1, #pts do out[i] = pts[i] end
		return out
	elseif shape == "scutum" then
		return {{-0.65, 1.8}, {0.65, 1.8}, {0.65, -1.8}, {-0.65, -1.8}}
	elseif shape == "rect" then
		return {{-1.25, 2.0}, {1.25, 2.0}, {1.25, -2.0}, {-1.25, -2.0}}
	end
	return nil   -- round: a circle of W
end

local function darker(c, k) return c:Lerp(Color3.new(0, 0, 0), k or 0.45) end

function ShieldDress.clear(container)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") then
			if d:GetAttribute(TAG) then d:Destroy()
			else
				local m = d:GetAttribute("DressMaterial")
				if m and Enum.Material[m] then d.Material = Enum.Material[m]; d:SetAttribute("DressMaterial", nil) end
			end
		end
	end
end

local function faceOf(container)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("ShieldFace") then return d end
	end
	return nil
end

function ShieldDress.apply(container, skin)
	ShieldDress.clear(container)
	if not skin then return false end
	local face = faceOf(container)
	local handle = container:FindFirstChild("Handle", true)
	if not (face and handle) then return false end
	local did = false
	-- MATERIALS: the board's, the rim's (what they were is kept, for the next skin)
	for _, p in ipairs(container:GetDescendants()) do
		if p:IsA("BasePart") and not p:GetAttribute(TAG) then
			local sp = p:GetAttribute("SkinPart")
			local want = (sp == "Blade" and skin.field) or (sp == "Grip" and p.Name ~= "Handle" and skin.rim) or nil
			if want and Enum.Material[want] then
				p:SetAttribute("DressMaterial", p.Material.Name)
				p.Material = Enum.Material[want]
				did = true
			end
		end
	end
	local adorn = skin.adorn
	if not (adorn and #adorn > 0) then return did end

	local W, H = face:GetAttribute("FaceW") or 2, face:GetAttribute("FaceH") or 2
	local Y, Z = face:GetAttribute("FaceY") or 0, face:GetAttribute("FaceZ") or -0.3
	local shape = face:GetAttribute("FaceShape") or (face:GetAttribute("FaceRound") and "round") or "rect"
	local F = handle.CFrame * CFrame.new(0, Y, Z)
	local poly = outline(shape, W, H)
	local R = W / 2
	local accent = skin.accent or skin.grip or C(214, 180, 90)
	local glow = skin.glow or accent
	local field = skin.blade or C(120, 120, 120)
	local gold = Enum.Material.Foil
	local made = {}
	-- (the same on every screen: the skin's own dice)
	local rng = Random.new(#(skin.name or "") * 131 + #(skin.weapon or "") * 17)
	local function chance(p) return rng:NextNumber() < p end

	local function part(size, cf, color, mat, cls)
		local p = Instance.new(cls or "Part")
		p.Name = "Dress"
		p.Size = size
		p.CFrame = cf
		p.Color, p.Material = color, mat or Enum.Material.SmoothPlastic
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		if p:IsA("Part") or p:IsA("WedgePart") then p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth end
		p:SetAttribute(TAG, true)
		p.Anchored = true
		table.insert(made, p)
		return p
	end
	local function at(x, y, z) return F * CFrame.new(x, y, z or 0) end
	local function ball(x, y, z, d, color, mat)
		local p = part(Vector3.one * d, at(x, y, z), color, mat)
		p.Shape = Enum.PartType.Ball
		return p
	end
	local function bar(x, y, z, w, l, depth, rot, color, mat)
		return part(Vector3.new(w, l, depth), at(x, y, z) * CFrame.Angles(0, 0, math.rad(rot or 0)), color, mat)
	end
	-- a flat triangle on the face's plane: its base centred on (x, y), its point `len` out along
	-- the angle `deg` (0 = +x, 90 = up); thick = how deep it stands
	local function tri(x, y, z, deg, base, len, thick, color, mat)
		local T = at(x, y, z) * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.Angles(math.rad(deg - 90), 0, 0) * CFrame.new(0, len / 2, 0)
		local a = part(Vector3.new(thick, len, base / 2), T * CFrame.new(0, 0, -base / 4), color, mat, "WedgePart")
		local b = part(Vector3.new(thick, len, base / 2), T * CFrame.new(0, 0, base / 4) * CFrame.Angles(0, math.pi, 0), color, mat, "WedgePart")
		return a, b
	end
	-- a spike out of the face (two crossed blades along -z)
	local function spike(x, y, z, base, len, color, mat)
		local T = at(x, y, z) * CFrame.Angles(-math.pi / 2, 0, 0)
		for _, turn in ipairs({0, math.pi / 2}) do
			local S = T * CFrame.Angles(0, turn, 0) * CFrame.new(0, len / 2, 0)
			part(Vector3.new(0.06, len, base / 2), S * CFrame.new(0, 0, -base / 4), color, mat, "WedgePart")
			part(Vector3.new(0.06, len, base / 2), S * CFrame.new(0, 0, base / 4) * CFrame.Angles(0, math.pi, 0), color, mat, "WedgePart")
		end
	end
	-- walk the outline, `inset` inside it, every `step` studs: fn(x, y, outward angle in degrees)
	local function along(inset, step, fn, from, to)
		if not poly then
			local r = R - inset
			local n = math.max(6, math.floor(2 * math.pi * r / step + 0.5))
			for k = 0, n - 1 do
				local a = k / n * math.pi * 2
				local deg = math.deg(a)
				if (not from or deg >= from) and (not to or deg <= to) then fn(math.cos(a) * r, math.sin(a) * r, deg) end
			end
			return
		end
		-- (a polygon: each side, pulled in toward the middle by `inset`)
		local cx, cy = 0, 0
		for _, p in ipairs(poly) do cx += p[1]; cy += p[2] end
		cx, cy = cx / #poly, cy / #poly
		for i = 1, #poly do
			local a, b = poly[i], poly[i % #poly + 1]
			local dx, dy = b[1] - a[1], b[2] - a[2]
			local len = math.sqrt(dx * dx + dy * dy)
			local n = math.max(1, math.floor(len / step + 0.5))
			for k = 0, n - 1 do
				local t = k / n
				local x, y = a[1] + dx * t, a[2] + dy * t
				local ox, oy = x - cx, y - cy
				local ol = math.sqrt(ox * ox + oy * oy)
				local ux, uy = ol > 0 and ox / ol or 0, ol > 0 and oy / ol or 1
				local deg = math.deg(math.atan2(uy, ux))
				if (not from or deg >= from) and (not to or deg <= to) then fn(x - ux * inset, y - uy * inset, deg) end
			end
		end
	end
	-- the outline's segments (a band round the rim), `inset` in
	local function rimBars(inset, width, depth, z, color, mat)
		if not poly then
			local r = R - inset
			local n = 28
			for k = 0, n - 1 do
				local a = (k + 0.5) / n * math.pi * 2
				bar(math.cos(a) * r, math.sin(a) * r, z, 2 * math.pi * r / n * 1.08, width, depth, math.deg(a) - 90, color, mat)
			end
			return
		end
		local cx, cy = 0, 0
		for _, p in ipairs(poly) do cx += p[1]; cy += p[2] end
		cx, cy = cx / #poly, cy / #poly
		for i = 1, #poly do
			local a, b = poly[i], poly[i % #poly + 1]
			local mx, my = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
			local ox, oy = mx - cx, my - cy
			local ol = math.sqrt(ox * ox + oy * oy)
			mx, my = mx - (ol > 0 and ox / ol or 0) * inset, my - (ol > 0 and oy / ol or 0) * inset
			local dx, dy = b[1] - a[1], b[2] - a[2]
			bar(mx, my, z, math.sqrt(dx * dx + dy * dy) + width * 0.6, width, depth, math.deg(math.atan2(dy, dx)), color, mat)
		end
	end
	local top = poly and poly[1][2] or R
	local bottom = poly and math.huge or -R
	local half = poly and 0 or R
	if poly then
		for _, p in ipairs(poly) do bottom = math.min(bottom, p[2]); half = math.max(half, math.abs(p[1])); top = math.max(top, p[2]) end
	end

	local A = {}
	-- (each ornament's pieces built in the face's frame; see the header for the list)
	A.studs = function() along(0.15, 0.42, function(x, y) ball(x, y, -0.05, 0.17, accent, Enum.Material.Metal) end) end
	A.gilded = function() rimBars(0.05, 0.13, 0.1, -0.05, accent, gold) end
	A.glowedge = function()
		rimBars(0.02, 0.06, 0.05, -0.1, glow, Enum.Material.Neon)
		local core = ball(0, 0, -0.05, 0.1, glow, Enum.Material.Neon)
		core.Transparency = 1
		local l = Instance.new("PointLight"); l.Color = glow; l.Range = 7; l.Brightness = 1.2; l.Shadows = false; l.Parent = core
	end
	A.boss = function()
		ball(0, 0, -0.12, math.min(W, H) * 0.28, accent, skin.rim and Enum.Material[skin.rim] or Enum.Material.Metal)
	end
	A.gem = function()
		local hasBoss = table.find(adorn, "boss") ~= nil
		local g = ball(0, 0, hasBoss and -0.32 or -0.1, 0.32, glow, Enum.Material.Neon)
		local setting = ball(0, 0, hasBoss and -0.26 or -0.06, 0.44, accent, gold)
		local l = Instance.new("PointLight"); l.Color = glow; l.Range = 6; l.Brightness = 1.4; l.Shadows = false; l.Parent = g
		for k = 0, 3 do tri(0, 0, hasBoss and -0.27 or -0.07, k * 90 + 45, 0.16, 0.42, 0.05, accent, gold) end
		return g, setting
	end
	A.spike = function()
		local hasBoss = table.find(adorn, "boss") ~= nil
		spike(0, 0, hasBoss and -0.3 or -0.08, 0.36, 1.0, accent, Enum.Material.Metal)
	end
	A.thorns = function()
		along(-0.02, 0.38, function(x, y, deg) tri(x, y, -0.02, deg, 0.2, 0.34, 0.08, darker(accent, 0.2), Enum.Material.Metal) end)
	end
	A.wings = function()
		local wingCol = skin.wing or accent
		for _, s in ipairs({-1, 1}) do
			-- five feathers fanned up and out from the side, the long ones in the middle
			for k = 1, 6 do
				local deg = s > 0 and (5 + k * 15) or (175 - k * 15)
				local len = 1.2 + 0.28 * (k <= 3 and k or 7 - k) + (k == 3 and 0.2 or 0)
				local x = s * (half - 0.15)
				local y = (top + bottom) / 2 + 0.35 + k * 0.06
				tri(x, y, 0.05, deg, 0.34, len, 0.07, k % 2 == 0 and wingCol or darker(wingCol, 0.12), skin.wingMaterial and Enum.Material[skin.wingMaterial] or gold)
			end
			-- the wing's root, a curled plate
			ball(s * (half - 0.1), (top + bottom) / 2 + 0.45, -0.02, 0.38, accent, gold)
		end
	end
	A.crown = function()
		local y = top + 0.02
		bar(0, y + 0.06, -0.05, 1.1, 0.2, 0.12, 0, accent, gold)
		for k = -2, 2 do
			local tall = (k % 2 == 0) and 0.5 or 0.34
			tri(k * 0.24, y + 0.15, -0.05, 90, 0.22, tall, 0.1, accent, gold)
			ball(k * 0.24, y + 0.15 + tall + 0.02, -0.07, 0.11, k == 0 and glow or C(230, 40, 60), Enum.Material.Neon)
		end
	end
	A.rays = function()
		local n = 16
		local len = math.max(half, (top - bottom) / 2) + 0.75
		for k = 0, n - 1 do
			local deg = k / n * 360
			local p1, p2 = tri(0, 0, 0.12, deg, k % 2 == 0 and 0.34 or 0.22, k % 2 == 0 and len or len * 0.82, 0.04, glow, Enum.Material.Neon)
			p1.Transparency, p2.Transparency = 0.15, 0.15
		end
	end
	A.horns = function()
		local hornCol = skin.horn or C(232, 222, 196)
		for _, s in ipairs({-1, 1}) do
			-- four tapering lengths, each turned further in: a curl
			local x, y, deg = s * half * 0.55, top - 0.05, s > 0 and 70 or 110
			local base, len = 0.34, 0.5
			for k = 1, 4 do
				tri(x, y, -0.04, deg, base, len, 0.12, hornCol, Enum.Material.SmoothPlastic)
				local r = math.rad(deg)
				x, y = x + math.cos(r) * len * 0.85, y + math.sin(r) * len * 0.85
				deg += s > 0 and 22 or -22
				base, len = base * 0.75, len * 0.92
			end
		end
	end
	A.feathers = function()
		local fc = skin.feather or C(30, 30, 36)
		for k = -1, 1 do
			local x = k * half * 0.45
			local y0 = (poly and (shape == "heater" or shape == "kite")) and (bottom + 0.55 + math.abs(k) * 0.5) or (bottom - 0.02)
			bar(x, y0 - 0.25, -0.03, 0.04, 0.5, 0.04, 0, C(110, 80, 50))
			ball(x, y0 - 0.5, -0.03, 0.12, accent, Enum.Material.Metal)
			tri(x, y0 - 0.55, -0.03, -90 + k * 8, 0.3, 1.0, 0.05, fc)
			tri(x + 0.04, y0 - 0.6, -0.04, -90 + k * 8, 0.18, 0.75, 0.05, fc:Lerp(Color3.new(1, 1, 1), 0.25))
		end
	end
	A.vines = function()
		local green, leaf = C(52, 110, 52), C(86, 170, 70)
		along(0.12, 0.3, function(x, y, deg)
			bar(x, y, -0.04, 0.32, 0.07, 0.05, deg + 90, green)
			if chance(0.7) then tri(x, y, -0.06, deg + (chance(0.5) and 40 or -40), 0.16, 0.26, 0.04, leaf) end
			if chance(0.12) then ball(x, y, -0.08, 0.1, glow, Enum.Material.Neon) end
		end)
	end
	A.runes = function()
		local r = math.min(half, (top - bottom) / 2) * 0.62
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			local p = bar(math.cos(a) * r, math.sin(a) * r, -0.06, 0.16, 0.24, 0.04, math.deg(a) + (k % 2) * 30, glow, Enum.Material.Neon)
			p.Transparency = 0.1
		end
	end
	A.bands = function()
		for _, f in ipairs({0.28, -0.22}) do
			local y = f * (top - bottom)
			local w = poly and half * 2 - 0.1 or 2 * math.sqrt(math.max(0, R * R - y * y)) - 0.1
			if w > 0.3 then
				bar(0, y, -0.04, w, 0.18, 0.06, 0, C(70, 70, 76), Enum.Material.Metal)
				for _, x in ipairs({-w / 2 + 0.12, 0, w / 2 - 0.12}) do ball(x, y, -0.08, 0.13, C(150, 150, 160), Enum.Material.Metal) end
			end
		end
	end
	A.tassels = function()
		local col = skin.ribbon or accent
		for _, s in ipairs({-1, 1}) do
			local x = s * half * 0.6
			local y0 = (shape == "heater" or shape == "kite") and (bottom + 0.9) or bottom
			bar(x, y0 - 0.55, -0.03, 0.28, 1.1, 0.04, s * 4, col, Enum.Material.Fabric)
			tri(x - 0.07, y0 - 1.1, -0.03, -90, 0.14, 0.25, 0.04, col)
			tri(x + 0.07, y0 - 1.1, -0.03, -90, 0.14, 0.25, 0.04, col)
			ball(x, y0 - 0.02, -0.05, 0.16, glow, Enum.Material.Neon)
		end
	end
	A.merlons = function()
		local n = math.max(3, math.floor(half * 2 / 0.5))
		for k = 0, n - 1 do
			if k % 2 == 0 then
				local x = -half + (k + 0.5) * (half * 2 / n)
				bar(x, top + 0.17, 0.0, half * 2 / n, 0.34, 0.22, 0, darker(field, 0.15), Enum.Material.Slate)
			end
		end
	end
	A.flames = function()
		along(-0.02, 0.32, function(x, y, deg)
			local big = chance(0.5)
			local p1, p2 = tri(x, y, -0.01, deg + rng:NextInteger(-12, 12), big and 0.26 or 0.18, big and 0.6 or 0.38, 0.05,
				big and C(255, 120, 40) or C(255, 200, 80), Enum.Material.Neon)
			p1.Transparency, p2.Transparency = 0.1, 0.1
		end, 15, 165)
	end

	for _, name in ipairs(adorn) do
		local fn = A[name]
		if fn then
			local ok, err = pcall(fn)
			if not ok then warn("[ShieldDress]", name, err) end
		end
	end
	-- (welded only once every piece is where it goes)
	local parent = face.Parent
	for _, p in ipairs(made) do
		if not handle.Anchored then
			p.Anchored = false
			p.Massless = true
			local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = handle, p; w.Parent = p
		end
		p.Parent = parent
	end
	return did or #made > 0
end

return ShieldDress
