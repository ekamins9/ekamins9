--[[ STAFF HEADS — a Mage's staff skin is a whole new head, not a recolour. Each staff
     skin names a design (Catalog ▸ Skins head = "<design>"); the design replaces the
     plain claws and orb with its own: a crook, an ember coal in charred prongs, a
     tuning fork of storm, a skull, a sunburst, a gyroscope round a crystal, a dragon's
     skull with a fire in its jaw, a black hole, a little solar system. The rarer, the
     wilder:
       Common     its own shape and a soft glow (a stone that breathes)
       Rare       an aura of its own and something that moves: a gem turning, motes
                  circling, a heart that beats
       Epic       moving machinery: rings turning, lightning between prongs, ghosts
                  circling a skull, a sun that wheels
       Legendary  a head that's alive: gyroscopes, wings, shards in orbit, light
                  pulled into a void
       Mythic     the Staff of the Cosmos: a star with planets in orbit (a moon round
                  the ringed one), a crown of constellations wheeling, a nebula
     How it's built: StaffHeads.design(skin, G) → {parts, hide, tip, fx}. SkinTrims makes
     the parts (welded to the Handle like any trim), hides the default claws and orb,
     and puts the spell's tip (TrailTip) at the design's core; SkinFX adds the fx
     (particles, lights, beams, trails). Anything with `anim` is turned by the client
     (StarterPlayerScripts ▸ TrimAnim): rot = turns about a centre (a list: the first
     innermost, so a moon goes round its planet as the planet goes round the star),
     osc = a swing back and forth (a wing's beat), bob = up and down, pulse = a glow
     that breathes (transparency). Looks only: massless, no collisions, no hitbox.

     G (the staff's frame, Handle space, +Y up the haft): o = the orb's centre, r its
     radius, c = the collar's top. A design is laid out round those. ]]

local StaffHeads = {}

local M = Enum.Material
local C = Color3.fromRGB
local V = Vector3.new
local PI = math.pi
local GOLD = C(232, 184, 74)
local BONE = C(226, 216, 190)
local TEX = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
}

--------------------------------------------------------------------
--  THE STAFF'S FRAME
--------------------------------------------------------------------
function StaffHeads.frame(tool)
	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then return nil end
	local orb, collar
	for _, p in ipairs(tool:GetDescendants()) do
		if p:IsA("BasePart") and not p:GetAttribute("TrimPart") then
			if p.Name == "Orb" or (p:GetAttribute("SkinPart") == "Blade" and not orb) then orb = p end
			if p.Name == "Collar" then collar = p end
		end
	end
	local o = orb and handle.CFrame:PointToObjectSpace(orb.Position) or V(0, 3.55, 0)
	local r = orb and orb.Size.X / 2 or 0.28
	local c = collar and (handle.CFrame:PointToObjectSpace(collar.Position).Y + 0.1) or (o.Y - 0.45)
	return {handle = handle, o = o, r = r, c = c}
end

--------------------------------------------------------------------
--  SHAPES (specs in the Handle's frame)
--------------------------------------------------------------------
local function spec(shape, size, cf, color, mat, extra)
	local s = {shape = shape, size = size, cf = cf, color = color, material = mat or M.SmoothPlastic}
	if extra then for k, v in pairs(extra) do s[k] = v end end
	return s
end
local function ball(d, pos, color, mat, extra) return spec("Ball", V(d, d, d), CFrame.new(pos), color, mat, extra) end
local function egg(size, cf, color, mat, extra) return spec("Ball", size, cf, color, mat, extra) end
local function block(size, cf, color, mat, extra) return spec("Block", size, cf, color, mat, extra) end
-- a frame at `pos` whose +Y runs along `dir`
local function along(pos, dir)
	dir = dir.Unit
	local n = math.abs(dir.Z) > 0.95 and Vector3.xAxis or Vector3.zAxis
	local x = (n - dir * n:Dot(dir)).Unit
	return CFrame.fromMatrix(pos, x, dir, x:Cross(dir))
end
-- a round bar from a to b
local function rod(a, b, d, color, mat, extra)
	local len = (b - a).Magnitude
	return spec("Cylinder", V(len, d, d), along((a + b) / 2, b - a) * CFrame.Angles(0, 0, PI / 2), color, mat, extra)
end
-- a bar through a list of points (a bent branch, a curl)
local function bend(out, pts, d, color, mat, extra)
	for i = 1, #pts - 1 do
		table.insert(out, rod(pts[i], pts[i + 1], d, color, mat, extra))
		if i > 1 then table.insert(out, ball(d, pts[i], color, mat, extra)) end
	end
end
-- a spike, base at `cf`, pointing along its +Y (two wedges: a diamond section)
local function thorn(out, cf, len, width, thick, color, mat, extra)
	local c = cf * CFrame.new(0, len / 2, 0)
	table.insert(out, spec("Wedge", V(thick, len, width / 2), c * CFrame.new(0, 0, width / 4) * CFrame.Angles(0, PI, 0), color, mat, extra))
	table.insert(out, spec("Wedge", V(thick, len, width / 2), c * CFrame.new(0, 0, -width / 4), color, mat, extra))
end
-- a leaf / feather / petal: a flat spike
local function leaf(out, pos, dir, len, width, color, mat, extra)
	thorn(out, along(pos, dir), len, width, 0.03, color, mat or M.SmoothPlastic, extra)
end
-- a flat triangle a-b-c (two right-angled wedges, the classic way): a wing's skin, a sail
local function tri(out, a, b, c, th, color, mat, extra)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then c, a = a, c elseif acd > bcd and acd > abd then a, b = b, a end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	table.insert(out, spec("Wedge", V(th, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2, right, up, back), color, mat, extra))
	table.insert(out, spec("Wedge", V(th, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2, -right, up, -back), color, mat, extra))
end
-- a ring of `n` segments round `centre`, in the plane of `frame` (its Y is the ring's axis)
local function ring(out, centre, frame, radius, n, thick, color, mat, extra)
	local seg = 2 * PI * radius / n * 1.12
	for i = 0, n - 1 do
		local a = i / n * 2 * PI
		local pos = centre + frame:VectorToWorldSpace(V(math.cos(a) * radius, 0, math.sin(a) * radius))
		local tan = frame:VectorToWorldSpace(V(-math.sin(a), 0, math.cos(a)))
		local up = frame.UpVector
		table.insert(out, block(V(seg, thick, thick), CFrame.fromMatrix(pos, tan, up, tan:Cross(up)), color, mat, extra))
	end
end
-- a ring of dots (an orbit's path, a crown of stars)
local function dots(out, centre, frame, radius, n, d, color, mat, extra)
	for i = 0, n - 1 do
		local a = i / n * 2 * PI
		table.insert(out, ball(d, centre + frame:VectorToWorldSpace(V(math.cos(a) * radius, 0, math.sin(a) * radius)), color, mat, extra))
	end
end
-- the same anim on every spec in a list (from index i0)
local function animate(out, i0, anim)
	for i = i0, #out do out[i].anim = anim end
end
local function spin(centre, axis, speed) return {rot = {{c = centre, axis = axis, speed = speed}}} end
local function tilt(xDeg, zDeg) return CFrame.Angles(math.rad(xDeg or 0), 0, math.rad(zDeg or 0)) end
local function hsv(h, s, v) return Color3.fromHSV(h, s, v) end

-- an emitter definition (SkinFX's format)
local function motes(c0, c1, size, rate, life, speed, accel, light, extra)
	local e = {tex = TEX.spark, c0 = c0, c1 = c1, size = size, rate = rate, life = life, speed = speed, accel = accel, spread = 180, light = light or 1}
	if extra then for k, v in pairs(extra) do e[k] = v end end
	return e
end

--------------------------------------------------------------------
--  THE DESIGNS: (G, P) → {parts, hide, tip, fx}
--  P = {blade, grip, metal, glow}; fx = {lights = {{at, color, range, brightness, flicker}},
--  emit = {{at = Vector3 or a part name, def}}, beams = {{a, b, color, width, crackle}},
--  trails = {{part, color, life, width}}}
--------------------------------------------------------------------
local D = {}
local CLAWS = {"Claw", "ClawTip", "Orb"}

-- ASHWOOD (Common): a pale crook curling over a crystal that breathes, three new leaves
D.ashwood = function(G, P)
	local o, out = G.o, {}
	local pts = {V(0.05, G.c, 0), V(0.16, o.Y - 0.2, 0)}
	local cc = V(-0.04, o.Y + 0.12, 0)
	for i = 0, 8 do
		local a = math.rad(-20 + i * 28)
		table.insert(pts, cc + V(math.cos(a) * 0.42, math.sin(a) * 0.42, 0))
	end
	bend(out, pts, 0.15, P.grip, M.Wood)
	table.insert(out, ball(0.2, pts[#pts], P.grip, M.Wood))
	for i = -1, 1 do leaf(out, pts[#pts] + V(0, -0.04, 0), V(-0.4 + i * 0.5, -0.8, i * 0.4), 0.3, 0.14, C(120, 168, 90)) end
	local n = #out + 1
	table.insert(out, egg(V(0.26, 0.42, 0.26), CFrame.new(o + V(0, 0.06, 0)), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {bob = {0.04, 2, 0}, pulse = {0, 0.25, 1.6}}
	table.insert(out, ball(0.22, V(0, G.c + 0.05, 0), P.metal, M.Metal))
	return {parts = out, hide = CLAWS, tip = o + V(0, 0.06, 0),
		fx = {lights = {{at = o, color = P.blade, range = 5, brightness = 0.6}},
			emit = {{at = "Core", def = motes(P.blade, Color3.new(1, 1, 1), {{0, 0.06}, {0.5, 0.1}, {1, 0}}, 3, {1.2, 2}, {0.05, 0.25}, V(0, 0.4, 0))}}}}
end

-- OAKEN (Common): three gnarled oak branches cradling a turning amber stone, acorns, leaves
D.oaken = function(G, P)
	local o, out = G.o, {}
	for k = 0, 2 do
		local a = k / 3 * 2 * PI
		local dir = V(math.cos(a), 0, math.sin(a))
		bend(out, {V(0, G.c, 0) + dir * 0.06, V(0, o.Y - 0.25, 0) + dir * 0.3, V(0, o.Y + 0.1, 0) + dir * 0.36, V(0, o.Y + 0.42, 0) + dir * 0.12}, 0.13, P.grip, M.Wood)
		table.insert(out, egg(V(0.12, 0.15, 0.12), CFrame.new(V(0, o.Y - 0.12, 0) + dir * 0.4), C(150, 104, 52), M.Wood))
		table.insert(out, egg(V(0.14, 0.07, 0.14), CFrame.new(V(0, o.Y - 0.05, 0) + dir * 0.4), C(92, 64, 36), M.Wood))
		leaf(out, V(0, o.Y + 0.1, 0) + dir * 0.36, dir + V(0, 0.6, 0), 0.32, 0.18, C(84, 130, 60))
	end
	local n = #out + 1
	table.insert(out, block(V(0.32, 0.32, 0.32), CFrame.new(o) * CFrame.Angles(PI / 4, 0, PI / 4), P.blade, M.Glass, {name = "Core", SkinPart = "Blade", transparency = 0.15}))
	table.insert(out, ball(0.2, o, P.blade, M.Neon))
	animate(out, n, spin(o, V(0, 1, 0), 0.7))
	return {parts = out, hide = CLAWS, tip = o,
		fx = {lights = {{at = o, color = P.blade, range = 5, brightness = 0.7}},
			emit = {{at = "Core", def = motes(C(255, 220, 140), C(255, 170, 60), {{0, 0.07}, {1, 0}}, 4, {1, 1.8}, {0.1, 0.3}, V(0, 0.3, 0))}}}}
end

-- EMBERWOOD (Rare): charred prongs gripping a living coal; embers circle it, flames lick up
D.emberwood = function(G, P)
	local o, out = G.o, {}
	local char = C(34, 24, 22)
	for k = 0, 3 do
		local a = k / 4 * 2 * PI + PI / 4
		local dir = V(math.cos(a), 0, math.sin(a))
		bend(out, {V(0, G.c, 0) + dir * 0.08, V(0, o.Y - 0.3, 0) + dir * 0.36, V(0, o.Y + 0.15, 0) + dir * 0.42, V(0, o.Y + 0.5, 0) + dir * 0.2}, 0.12, char, M.Slate)
		thorn(out, along(V(0, o.Y + 0.5, 0) + dir * 0.2, -dir + V(0, 0.5, 0)), 0.16, 0.09, 0.06, C(255, 120, 40), M.Neon)
	end
	local n = #out + 1
	table.insert(out, ball(0.5, o, P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {pulse = {0, 0.3, 4}}
	for k = 0, 5 do   -- the crust of the coal
		local a = k / 6 * 2 * PI
		table.insert(out, block(V(0.18, 0.12, 0.14), CFrame.new(o + V(math.cos(a) * 0.22, (k % 2 - 0.5) * 0.24, math.sin(a) * 0.22)) * CFrame.Angles(a, a * 2, 0), char, M.Slate))
	end
	animate(out, n + 1, spin(o, V(0, 1, 0), 0.4))
	local m = #out + 1
	dots(out, o, tilt(12, 0), 0.62, 6, 0.08, C(255, 170, 60), M.Neon)
	animate(out, m, spin(o, CFrame.Angles(math.rad(12), 0, 0).UpVector, 1.3))
	return {parts = out, hide = CLAWS, tip = o,
		fx = {lights = {{at = o, color = C(255, 130, 50), range = 8, brightness = 1.1, flicker = true}},
			emit = {{at = "Core", def = {tex = TEX.fire, c0 = C(255, 170, 60), c1 = C(220, 50, 10), size = {{0, 0.45}, {0.5, 0.3}, {1, 0.04}}, rate = 14, life = {0.25, 0.5}, speed = {0.3, 1}, accel = V(0, 5, 0), spread = 25, light = 1, transp = {{0, 0.25}, {1, 1}}}},
				{at = "Core", def = motes(C(255, 220, 110), C(255, 70, 20), {{0, 0.12}, {1, 0}}, 16, {0.6, 1.3}, {0.5, 1.8}, V(0, 6, 0), 1, {spread = 70})}}}}
end

-- FROSTBRANCH (Rare): a burst of ice shards round a turning frost crystal; shards circle it
D.frostbranch = function(G, P)
	local o, out = G.o, {}
	local ice = C(196, 232, 255)
	for k = 0, 6 do
		local a = k / 7 * 2 * PI
		local dir = V(math.cos(a), 0, math.sin(a))
		thorn(out, along(V(0, G.c + 0.1, 0) + dir * 0.1, dir * 0.5 + V(0, 1, 0)), 0.75 + (k % 3) * 0.18, 0.2, 0.16, ice, M.Glass, {transparency = 0.2})
	end
	local n = #out + 1
	table.insert(out, block(V(0.24, 0.5, 0.24), CFrame.new(o + V(0, 0.15, 0)) * CFrame.Angles(0, PI / 4, 0), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	thorn(out, CFrame.new(o + V(0, 0.4, 0)), 0.3, 0.24, 0.24, P.blade, M.Neon)
	thorn(out, CFrame.new(o + V(0, -0.1, 0)) * CFrame.Angles(PI, 0, 0), 0.25, 0.24, 0.24, P.blade, M.Neon)
	animate(out, n, {rot = {{c = o, axis = V(0, 1, 0), speed = 0.9}}, bob = {0.05, 1.7, 0}})
	local m = #out + 1
	for k = 0, 2 do
		local a = k / 3 * 2 * PI
		thorn(out, along(o + V(math.cos(a) * 0.62, 0.1, math.sin(a) * 0.62), V(0, 1, 0)), 0.22, 0.1, 0.08, ice, M.Glass, {transparency = 0.1})
	end
	animate(out, m, spin(o, CFrame.Angles(0, 0, math.rad(-15)).UpVector, -1.1))
	return {parts = out, hide = CLAWS, tip = o + V(0, 0.15, 0),
		fx = {lights = {{at = o, color = C(150, 210, 255), range = 8, brightness = 1}},
			emit = {{at = "Core", def = motes(C(240, 252, 255), C(150, 214, 255), {{0, 0.14}, {1, 0.02}}, 18, {0.9, 1.7}, {0.1, 0.5}, V(0, -1.2, 0), 0.9, {rot = 80})},
				{at = "Core", def = {tex = TEX.smoke, c0 = C(205, 238, 255), size = {{0, 0.3}, {1, 0.9}}, rate = 5, life = {0.8, 1.3}, speed = {0.05, 0.2}, accel = V(0, -0.5, 0), spread = 180, light = 0.25, transp = {{0, 0.7}, {1, 1}}}}}}}
end

-- GILT SPIRE (Rare): a crown of golden blades; above it a gem turns and floats on a turning halo
D.giltspire = function(G, P)
	local o, out = G.o, {}
	local gold = P.metal or GOLD
	for k = 0, 5 do
		local a = k / 6 * 2 * PI
		local dir = V(math.cos(a), 0, math.sin(a))
		thorn(out, along(V(0, G.c + 0.05, 0) + dir * 0.12, dir * 0.25 + V(0, 1, 0)), (k % 2 == 0) and 0.95 or 0.7, 0.16, 0.05, gold, M.Foil)
	end
	table.insert(out, spec("Cylinder", V(0.12, 0.46, 0.46), CFrame.new(V(0, G.c + 0.05, 0)) * CFrame.Angles(0, 0, PI / 2), gold, M.Foil))
	local top = o + V(0, 0.55, 0)
	local n = #out + 1
	table.insert(out, block(V(0.3, 0.3, 0.3), CFrame.new(top) * CFrame.Angles(PI / 4, 0, PI / 4), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	animate(out, n, {rot = {{c = top, axis = V(0, 1, 0), speed = 1.2}}, bob = {0.07, 1.5, 0}})
	local m = #out + 1
	ring(out, top + V(0, -0.32, 0), CFrame.new(), 0.34, 14, 0.04, gold, M.Neon)
	animate(out, m, {rot = {{c = top, axis = V(0, 1, 0), speed = -0.8}}, bob = {0.07, 1.5, 0}})
	return {parts = out, hide = CLAWS, tip = top,
		fx = {lights = {{at = top, color = C(255, 226, 150), range = 8, brightness = 1}},
			emit = {{at = "Core", def = motes(C(255, 250, 220), C(232, 184, 74), {{0, 0.05}, {0.5, 0.14}, {1, 0}}, 12, {0.5, 1.1}, {0, 0.1}, nil, 1, {locked = true})},
				{at = "Core", def = motes(C(255, 236, 160), GOLD, {{0, 0.08}, {1, 0}}, 6, {1, 1.8}, {0.1, 0.3}, V(0, -0.8, 0))}}}}
end

-- BLOODROOT (Rare): thorned roots twist round a blood gem that beats like a heart and drips
D.bloodroot = function(G, P)
	local o, out = G.o, {}
	local root = C(60, 18, 20)
	for k = 0, 4 do
		local a0 = k / 5 * 2 * PI
		local pts = {}
		for i = 0, 5 do
			local a = a0 + i * 0.55
			local rr = 0.12 + math.sin(i / 5 * PI) * 0.3
			table.insert(pts, V(math.cos(a) * rr, G.c + i * ((o.Y + 0.5 - G.c) / 5), math.sin(a) * rr))
		end
		bend(out, pts, 0.09, root, M.Wood)
		thorn(out, along(pts[3], (pts[3] * V(1, 0, 1)).Unit + V(0, 0.3, 0)), 0.18, 0.08, 0.05, C(20, 8, 8), M.SmoothPlastic)
		thorn(out, along(pts[5], (pts[5] * V(1, 0, 1)).Unit + V(0, 0.6, 0)), 0.14, 0.07, 0.05, C(20, 8, 8), M.SmoothPlastic)
	end
	local n = #out + 1
	table.insert(out, egg(V(0.42, 0.5, 0.42), CFrame.new(o + V(0, 0.05, 0)), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {pulse = {0, 0.45, 7}}
	table.insert(out, egg(V(0.5, 0.58, 0.5), CFrame.new(o + V(0, 0.05, 0)), C(120, 10, 16), M.Glass, {transparency = 0.45}))
	return {parts = out, hide = CLAWS, tip = o + V(0, 0.05, 0),
		fx = {lights = {{at = o, color = C(255, 50, 50), range = 7, brightness = 1, pulse = 7}},
			emit = {{at = "Core", def = {tex = TEX.spark, c0 = C(200, 20, 30), c1 = C(90, 0, 10), size = {{0, 0.1}, {1, 0.05}}, rate = 6, life = {0.6, 1}, speed = {0.1, 0.4}, accel = V(0, -10, 0), spread = 30, light = 0.3}},
				{at = "Core", def = motes(C(255, 90, 90), C(140, 0, 20), {{0, 0.07}, {1, 0}}, 8, {0.8, 1.4}, {0.1, 0.3}, V(0, 0.4, 0))}}}}
end

-- VERDANT BOUGH (Epic): the staff still grows: branches, a crown of leaves turning round a
-- flower in bloom with a seed of light at its heart; spores and fireflies drift off it
D.verdantbough = function(G, P)
	local o, out = G.o, {}
	local bark = P.grip
	local green = C(96, 168, 70)
	for k = 0, 2 do
		local a = k / 3 * 2 * PI + 0.4
		local dir = V(math.cos(a), 0, math.sin(a))
		bend(out, {V(0, G.c, 0), V(0, o.Y - 0.2, 0) + dir * 0.32, V(0, o.Y + 0.2, 0) + dir * 0.5}, 0.11, bark, M.Wood)
		for j = 0, 2 do leaf(out, V(0, o.Y + 0.2, 0) + dir * 0.5, dir + V((j - 1) * 0.4, 0.5 + j * 0.2, (j - 1) * 0.3), 0.34, 0.2, j == 1 and C(140, 200, 90) or green) end
	end
	-- the flower: petals round a glowing seed
	local top = o + V(0, 0.15, 0)
	for k = 0, 5 do
		local a = k / 6 * 2 * PI
		leaf(out, top + V(math.cos(a) * 0.08, 0, math.sin(a) * 0.08), V(math.cos(a), 0.7, math.sin(a)), 0.38, 0.26, k % 2 == 0 and C(255, 214, 236) or C(255, 170, 210))
	end
	local n = #out + 1
	table.insert(out, ball(0.3, top + V(0, 0.08, 0), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {pulse = {0, 0.3, 2}}
	local m = #out + 1
	for k = 0, 5 do
		local a = k / 6 * 2 * PI
		leaf(out, o + V(math.cos(a) * 0.75, -0.05 + (k % 2) * 0.2, math.sin(a) * 0.75), V(-math.sin(a), 0.4, math.cos(a)), 0.26, 0.16, green)
	end
	animate(out, m, {rot = {{c = o, axis = V(0, 1, 0), speed = 0.8}}, bob = {0.05, 1.2, 0}})
	return {parts = out, hide = CLAWS, tip = top + V(0, 0.08, 0),
		fx = {lights = {{at = top, color = C(150, 255, 120), range = 9, brightness = 1.1}},
			emit = {{at = "Core", def = motes(C(255, 255, 160), C(160, 255, 90), {{0, 0.1}, {0.5, 0.14}, {1, 0}}, 10, {1.4, 2.4}, {0.3, 0.9}, V(0, 0.15, 0), 1, {drag = 0.6})},
				{at = "Core", def = motes(C(240, 255, 220), C(140, 220, 120), {{0, 0.05}, {1, 0.03}}, 14, {1.5, 2.5}, {0.2, 0.5}, V(0, 0.5, 0), 0.6)}}}}
end

-- STORMCALLER (Epic): a steel tuning fork; lightning cracks between its prongs round a ball
-- of storm, a ring of runes whirling about it
D.stormcaller = function(G, P)
	local o, out = G.o, {}
	local steel = P.metal or C(170, 180, 205)
	local tips = {}
	for _, s in ipairs({-1, 1}) do
		local p0, p1, p2, p3 = V(0, G.c, 0), V(s * 0.3, G.c + 0.25, 0), V(s * 0.42, o.Y + 0.1, 0), V(s * 0.36, o.Y + 0.75, 0)
		bend(out, {p0, p1, p2, p3}, 0.1, steel, M.Metal)
		table.insert(out, ball(0.16, p3, P.blade, M.Neon, {name = s < 0 and "ForkL" or "ForkR"}))
		thorn(out, along(p3, V(s * 0.2, 1, 0)), 0.22, 0.1, 0.06, steel, M.Metal)
		table.insert(tips, p3)
	end
	local n = #out + 1
	table.insert(out, ball(0.34, o + V(0, 0.25, 0), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {bob = {0.06, 3, 0}, pulse = {0, 0.35, 9}}
	local m = #out + 1
	for k = 0, 7 do
		local a = k / 8 * 2 * PI
		table.insert(out, block(V(0.1, 0.14, 0.03), CFrame.new(o + V(math.cos(a) * 0.5, 0.25, math.sin(a) * 0.5)) * CFrame.Angles(0, -a, 0), C(200, 235, 255), M.Neon))
	end
	animate(out, m, {rot = {{c = o + V(0, 0.25, 0), axis = V(0, 1, 0), speed = 3}, {c = o + V(0, 0.25, 0), axis = V(1, 0, 0), speed = 0.7}}})
	return {parts = out, hide = CLAWS, tip = o + V(0, 0.25, 0),
		fx = {lights = {{at = o, color = C(140, 200, 255), range = 10, brightness = 1.3, flicker = true}},
			beams = {{a = "ForkL", b = "ForkR", color = C(200, 235, 255), width = 0.18, crackle = true}, {a = "ForkL", b = "Core", color = C(150, 210, 255), width = 0.1, crackle = true},
				{a = "ForkR", b = "Core", color = C(150, 210, 255), width = 0.1, crackle = true}},
			emit = {{at = "Core", def = motes(C(255, 255, 255), C(90, 170, 255), {{0, 0.18}, {1, 0}}, 30, {0.05, 0.14}, {3, 7}, nil, 1, {drag = 8})}}}}
end

-- BONECALLER (Epic): a skull on a spine; its eyes burn green and ghosts circle it
D.bonecaller = function(G, P)
	local o, out = G.o, {}
	local bone = P.grip or BONE
	for i = 0, 3 do   -- the spine under the skull
		table.insert(out, spec("Cylinder", V(0.1, 0.28 - i * 0.02, 0.28 - i * 0.02), CFrame.new(0, G.c + 0.05 + i * 0.13, 0) * CFrame.Angles(0, 0, PI / 2), bone, M.SmoothPlastic))
		table.insert(out, block(V(0.08, 0.06, 0.3), CFrame.new(0, G.c + 0.05 + i * 0.13, 0.12), bone, M.SmoothPlastic))
	end
	local s = o + V(0, 0.12, 0)
	table.insert(out, egg(V(0.62, 0.6, 0.66), CFrame.new(s), bone, M.SmoothPlastic, {name = "Skull"}))
	table.insert(out, block(V(0.42, 0.18, 0.3), CFrame.new(s + V(0, -0.3, -0.16)), bone, M.SmoothPlastic))
	for i = -2, 2 do table.insert(out, block(V(0.05, 0.08, 0.04), CFrame.new(s + V(i * 0.07, -0.21, -0.31)), C(250, 246, 230), M.SmoothPlastic)) end
	table.insert(out, block(V(0.08, 0.1, 0.04), CFrame.new(s + V(0, -0.08, -0.33)) * CFrame.Angles(0, 0, PI / 4), C(20, 16, 14), M.SmoothPlastic))
	for _, x in ipairs({-1, 1}) do
		table.insert(out, ball(0.18, s + V(x * 0.14, 0.02, -0.27), C(20, 16, 14), M.SmoothPlastic))
		local n = #out + 1
		table.insert(out, ball(0.11, s + V(x * 0.14, 0.02, -0.31), P.blade, M.Neon, {name = x < 0 and "EyeL" or "EyeR", SkinPart = x < 0 and "Blade" or nil}))
		out[n].anim = {pulse = {0, 0.4, 5}}
		bend(out, {s + V(x * 0.26, 0.2, 0.05), s + V(x * 0.46, 0.38, 0.16), s + V(x * 0.5, 0.62, 0.3)}, 0.08, bone, M.SmoothPlastic)
	end
	local m = #out + 1
	for k = 0, 2 do
		local a = k / 3 * 2 * PI
		table.insert(out, egg(V(0.16, 0.26, 0.16), CFrame.new(s + V(math.cos(a) * 0.7, 0, math.sin(a) * 0.7)), P.blade, M.Neon, {transparency = 0.35, name = "Ghost" .. k}))
	end
	animate(out, m, {rot = {{c = s, axis = V(0, 1, 0), speed = 1.7}}, bob = {0.12, 2.2, 0}})
	return {parts = out, hide = CLAWS, tip = s,
		fx = {lights = {{at = s, color = P.blade, range = 9, brightness = 1.1}},
			emit = {{at = "EyeL", def = {tex = TEX.fire, c0 = P.blade, c1 = C(20, 120, 40), size = {{0, 0.2}, {1, 0.02}}, rate = 12, life = {0.2, 0.45}, speed = {0.3, 0.8}, accel = V(0, 3, 0), spread = 15, light = 1, transp = {{0, 0.2}, {1, 1}}}},
				{at = "EyeR", def = {tex = TEX.fire, c0 = P.blade, c1 = C(20, 120, 40), size = {{0, 0.2}, {1, 0.02}}, rate = 12, life = {0.2, 0.45}, speed = {0.3, 0.8}, accel = V(0, 3, 0), spread = 15, light = 1, transp = {{0, 0.2}, {1, 1}}}}},
			trails = {{part = "Ghost0", color = P.blade, life = 0.5, width = 0.12}, {part = "Ghost1", color = P.blade, life = 0.5, width = 0.12}, {part = "Ghost2", color = P.blade, life = 0.5, width = 0.12}}}}
end

-- SUNSPIRE (Epic): a wheel of golden rays round a white sun, the wheel turning, a ring of
-- light turning the other way
D.sunspire = function(G, P)
	local o, out = G.o, {}
	local gold = P.metal or GOLD
	local sun = o + V(0, 0.3, 0)
	table.insert(out, rod(V(0, G.c, 0), sun, 0.12, gold, M.Foil))
	local n = #out + 1
	for k = 0, 11 do
		local a = k / 12 * 2 * PI
		local dir = V(math.cos(a), math.sin(a), 0)
		thorn(out, along(sun + dir * 0.3, dir), k % 2 == 0 and 0.5 or 0.32, 0.16, 0.05, gold, M.Foil)
	end
	table.insert(out, spec("Cylinder", V(0.06, 0.62, 0.62), CFrame.new(sun) * CFrame.Angles(0, PI / 2, 0), gold, M.Foil))
	animate(out, n, spin(sun, V(0, 0, 1), 0.6))
	local m = #out + 1
	dots(out, sun, CFrame.Angles(PI / 2, 0, 0), 0.95, 16, 0.07, C(255, 240, 190), M.Neon)
	animate(out, m, spin(sun, V(0, 0, 1), -0.9))
	local k = #out + 1
	table.insert(out, ball(0.36, sun, P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[k].anim = {pulse = {0, 0.2, 2.5}}
	return {parts = out, hide = CLAWS, tip = sun,
		fx = {lights = {{at = sun, color = C(255, 236, 170), range = 12, brightness = 1.5}},
			emit = {{at = "Core", def = motes(C(255, 255, 240), C(255, 210, 110), {{0, 0.1}, {0.5, 0.22}, {1, 0}}, 18, {0.4, 0.9}, {0, 0.1}, nil, 1, {locked = true})},
				{at = "Core", def = {tex = TEX.smoke, c0 = C(255, 236, 170), size = {{0, 0.5}, {1, 1.4}}, rate = 4, life = {0.6, 1}, speed = {0.05, 0.2}, spread = 180, light = 1, transp = {{0, 0.82}, {1, 1}}}}}}}
end

-- ARCHMAGE'S ROD (Legendary): a great crystal floating in a gyroscope of three rings, each
-- turning on its own axis while the whole turns, runes circling outside
D.archmage = function(G, P)
	local o, out = G.o, {}
	local silver = P.metal or C(222, 228, 240)
	local c = o + V(0, 0.35, 0)
	-- the cradle: four curved arms up from the collar
	for k = 0, 3 do
		local a = k / 4 * 2 * PI + PI / 4
		local dir = V(math.cos(a), 0, math.sin(a))
		bend(out, {V(0, G.c, 0), V(0, G.c + 0.2, 0) + dir * 0.28, V(0, c.Y - 0.45, 0) + dir * 0.3}, 0.07, silver, M.Foil)
		table.insert(out, ball(0.1, V(0, c.Y - 0.45, 0) + dir * 0.3, P.blade, M.Neon))
	end
	local outer = {c = c, axis = V(0, 1, 0), speed = 0.5}
	local i1 = #out + 1
	ring(out, c, CFrame.new(), 0.62, 26, 0.05, silver, M.Foil)
	animate(out, i1, {rot = {{c = c, axis = V(1, 0, 0), speed = 1.1}, outer}})
	local i2 = #out + 1
	ring(out, c, CFrame.Angles(PI / 2, 0, 0), 0.52, 22, 0.05, GOLD, M.Foil)
	animate(out, i2, {rot = {{c = c, axis = V(0, 0, 1), speed = -0.9}, outer}})
	local i3 = #out + 1
	ring(out, c, CFrame.Angles(0, 0, PI / 2), 0.42, 18, 0.045, P.blade, M.Neon)
	animate(out, i3, {rot = {{c = c, axis = V(0, 1, 0), speed = 1.7}, outer}})
	local i4 = #out + 1
	table.insert(out, block(V(0.3, 0.3, 0.3), CFrame.new(c) * CFrame.Angles(PI / 4, 0, PI / 4), P.blade, M.Glass, {name = "Core", SkinPart = "Blade", transparency = 0.1}))
	table.insert(out, ball(0.22, c, Color3.new(1, 1, 1), M.Neon))
	thorn(out, CFrame.new(c + V(0, 0.18, 0)), 0.28, 0.2, 0.2, P.blade, M.Glass)
	thorn(out, CFrame.new(c + V(0, -0.18, 0)) * CFrame.Angles(PI, 0, 0), 0.28, 0.2, 0.2, P.blade, M.Glass)
	animate(out, i4, {rot = {{c = c, axis = V(0, 1, 0), speed = 0.8}}, bob = {0.05, 1.6, 0}})
	local i5 = #out + 1
	for k = 0, 5 do
		local a = k / 6 * 2 * PI
		table.insert(out, block(V(0.12, 0.16, 0.03), CFrame.new(c + V(math.cos(a) * 0.95, math.sin(a * 2) * 0.12, math.sin(a) * 0.95)) * CFrame.Angles(0, -a, 0), P.blade, M.Neon, {name = "Rune" .. k}))
	end
	animate(out, i5, {rot = {{c = c, axis = V(0, 1, 0), speed = -1.3}}, bob = {0.06, 2, 1}})
	return {parts = out, hide = CLAWS, tip = c,
		fx = {lights = {{at = c, color = P.blade, range = 13, brightness = 1.8}},
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), P.blade, {{0, 0.06}, {0.5, 0.2}, {1, 0}}, 18, {0.5, 1}, {0, 0.06}, nil, 1, {locked = true})},
				{at = "Core", def = motes(C(220, 240, 255), P.blade, {{0, 0.12}, {1, 0}}, 14, {1, 1.8}, {0.4, 1}, V(0, -0.6, 0), 1)}},
			trails = {{part = "Rune0", color = P.blade, life = 0.35, width = 0.08}, {part = "Rune3", color = P.blade, life = 0.35, width = 0.08}}}}
end

-- DRAGONBONE (Legendary): a dragon's skull with a fire caught in its jaws, horns swept back,
-- bone wings spread from the collar that beat slowly
D.dragonbone = function(G, P)
	local o, out = G.o, {}
	local bone = P.grip or BONE
	local dark = P.metal or C(140, 30, 20)
	local s = o + V(0, 0.15, 0)
	-- the skull: a long snout reaching forward (-Z), brow ridges, horns
	table.insert(out, egg(V(0.62, 0.52, 0.66), CFrame.new(s + V(0, 0.08, 0.08)), bone, M.SmoothPlastic, {name = "Skull"}))
	table.insert(out, egg(V(0.4, 0.3, 0.66), CFrame.new(s + V(0, 0.1, -0.4)), bone, M.SmoothPlastic))
	table.insert(out, egg(V(0.36, 0.14, 0.6), CFrame.new(s + V(0, -0.2, -0.34)) * CFrame.Angles(math.rad(-14), 0, 0), bone, M.SmoothPlastic))
	for _, x in ipairs({-1, 1}) do table.insert(out, egg(V(0.18, 0.12, 0.3), CFrame.new(s + V(x * 0.18, 0.28, -0.1)), bone, M.SmoothPlastic)) end   -- brow ridges
	for _, x in ipairs({-1, 1}) do
		for i = 0, 2 do thorn(out, along(s + V(x * 0.08, 0.02, -0.52 + i * 0.1), V(0, -1, -0.2)), 0.12, 0.05, 0.04, C(250, 244, 226), M.SmoothPlastic) end
		local e = #out + 1
		table.insert(out, ball(0.1, s + V(x * 0.15, 0.18, -0.16), C(255, 150, 40), M.Neon))
		out[e].anim = {pulse = {0, 0.4, 3}}
		bend(out, {s + V(x * 0.2, 0.22, 0.18), s + V(x * 0.34, 0.42, 0.42), s + V(x * 0.4, 0.5, 0.78)}, 0.09, dark, M.SmoothPlastic)
		thorn(out, along(s + V(x * 0.4, 0.5, 0.78), V(x * 0.1, 0.2, 1)), 0.3, 0.09, 0.08, dark, M.SmoothPlastic)
	end
	for i = 0, 3 do thorn(out, along(s + V(0, 0.28, 0.1 + i * 0.12), V(0, 1, 0.4)), 0.18 - i * 0.02, 0.1, 0.05, dark, M.SmoothPlastic) end
	-- the fire in its jaws
	local f = s + V(0, -0.05, -0.42)
	local n = #out + 1
	table.insert(out, ball(0.3, f, P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {pulse = {0, 0.3, 6}}
	-- the wings: three spars a side and the skin between, beating
	for _, x in ipairs({-1, 1}) do
		local w0 = #out + 1
		local base = V(x * 0.12, G.c + 0.15, 0.1)
		local tips = {}
		for j = 0, 3 do
			local tip = base + V(x * (0.75 + j * 0.12), 0.7 - j * 0.38, 0.22 + j * 0.04)
			table.insert(out, rod(base, tip, 0.05, bone, M.SmoothPlastic))
			table.insert(out, ball(0.08, tip, bone, M.SmoothPlastic))
			tips[j + 1] = tip
		end
		for j = 1, 3 do   -- the skin between the spars, sagging a little toward the base
			tri(out, base, tips[j], tips[j + 1], 0.03, C(150, 40, 30), M.SmoothPlastic, {transparency = 0.15})
		end
		animate(out, w0, {osc = {c = base, axis = V(0, 1, 0), amp = x * 0.35, speed = 2.2}})
	end
	return {parts = out, hide = CLAWS, tip = f,
		fx = {lights = {{at = f, color = C(255, 120, 40), range = 13, brightness = 1.9, flicker = true}},
			emit = {{at = "Core", def = {tex = TEX.fire, c0 = C(255, 190, 70), c1 = C(220, 40, 10), size = {{0, 0.5}, {0.5, 0.36}, {1, 0.05}}, rate = 26, life = {0.25, 0.55}, speed = {0.4, 1.4}, accel = V(0, 6, 0), spread = 30, light = 1, transp = {{0, 0.2}, {1, 1}}}},
				{at = "Core", def = motes(C(255, 230, 120), C(255, 60, 20), {{0, 0.14}, {1, 0}}, 22, {0.6, 1.4}, {0.8, 2.4}, V(0, 7, 0), 1, {spread = 80})},
				{at = "Skull", def = {tex = TEX.smoke, c0 = C(60, 40, 34), size = {{0, 0.3}, {1, 1.2}}, rate = 5, life = {0.9, 1.6}, speed = {0.2, 0.6}, accel = V(0, 2.5, 0), spread = 40, light = 0, transp = {{0, 0.65}, {1, 1}}}}}}}
end

-- VOIDSTAFF (Legendary): an obsidian crescent holds a black hole: a disc of violet fire
-- whirling round it, shards in orbit, and light drawn in from all round
D.voidstaff = function(G, P)
	local o, out = G.o, {}
	local obs = C(24, 18, 32)
	local c = o + V(0, 0.3, 0)
	-- the crescent: an arc of obsidian under and round the hole
	local pts = {}
	for i = 0, 10 do
		local a = math.rad(200 + i * 14)
		table.insert(pts, c + V(math.cos(a) * 0.62, math.sin(a) * 0.62, 0))
	end
	bend(out, pts, 0.14, obs, M.Glass)
	thorn(out, along(pts[1], pts[1] - pts[2]), 0.3, 0.14, 0.1, obs, M.Glass)
	thorn(out, along(pts[#pts], pts[#pts] - pts[#pts - 1]), 0.3, 0.14, 0.1, obs, M.Glass)
	table.insert(out, rod(V(0, G.c, 0), pts[6], 0.11, obs, M.Glass))
	-- the hole and its disc
	table.insert(out, ball(0.42, c, C(4, 2, 8), M.SmoothPlastic, {name = "Hole"}))
	local n = #out + 1
	table.insert(out, ball(0.5, c, P.blade, M.Neon, {name = "Core", SkinPart = "Blade", transparency = 0.7}))
	out[n].anim = {pulse = {0.6, 0.85, 3}}
	local disc = CFrame.Angles(math.rad(18), 0, math.rad(8))
	local i1 = #out + 1
	ring(out, c, disc, 0.4, 24, 0.05, P.blade, M.Neon)
	animate(out, i1, spin(c, disc.UpVector, 2.6))
	local i2 = #out + 1
	dots(out, c, disc, 0.58, 18, 0.05, C(220, 170, 255), M.Neon)
	animate(out, i2, spin(c, disc.UpVector, -1.4))
	for k = 0, 4 do
		local i3 = #out + 1
		local tk = CFrame.Angles(math.rad(-40 + k * 20), math.rad(k * 70), 0)
		thorn(out, along(c + tk:VectorToWorldSpace(V(0.85, 0, 0)), tk.UpVector), 0.2, 0.1, 0.08, obs, M.Glass)
		animate(out, i3, spin(c, tk.UpVector, 0.9 + k * 0.2))
	end
	table.insert(out, ball(1.9, c, C(0, 0, 0), M.SmoothPlastic, {name = "Pull", transparency = 1}))
	return {parts = out, hide = CLAWS, tip = c,
		fx = {lights = {{at = c, color = C(150, 70, 255), range = 12, brightness = 1.6}},
			emit = {{at = "Pull", def = {tex = TEX.spark, c0 = C(220, 170, 255), c1 = C(110, 40, 200), size = {{0, 0.02}, {0.6, 0.12}, {1, 0}}, rate = 30, life = {0.5, 0.8}, speed = {1.1, 1.6}, spread = 0, light = 1, inward = true}},
				{at = "Core", def = {tex = TEX.smoke, c0 = C(46, 22, 70), c1 = C(10, 5, 20), size = {{0, 0.4}, {1, 1.1}}, rate = 10, life = {0.7, 1.2}, speed = {0.1, 0.4}, spread = 180, light = 0, transp = {{0, 0.45}, {1, 1}}}}}}}
end

-- THE STAFF OF THE COSMOS (Mythic): a star burning on an astrolabe; three worlds in orbit
-- (a moon round the ringed one), their paths drawn in dust, a crown of constellations
-- wheeling round it all, a nebula breathing off it
D.cosmos = function(G, P)
	local o, out = G.o, {}
	local gold = P.metal or C(255, 236, 170)
	local c = o + V(0, 0.55, 0)
	-- the astrolabe: six golden arcs from the collar cupping the star
	for k = 0, 5 do
		local a = k / 6 * 2 * PI
		local dir = V(math.cos(a), 0, math.sin(a))
		bend(out, {V(0, G.c, 0), V(0, G.c + 0.25, 0) + dir * 0.32, V(0, c.Y - 0.35, 0) + dir * 0.42, V(0, c.Y - 0.12, 0) + dir * 0.3}, 0.05, gold, M.Foil)
		table.insert(out, ball(0.07, V(0, c.Y - 0.12, 0) + dir * 0.3, C(255, 250, 230), M.Neon))
	end
	table.insert(out, spec("Cylinder", V(0.06, 0.9, 0.9), CFrame.new(c + V(0, -0.36, 0)) * CFrame.Angles(0, 0, PI / 2), gold, M.Foil))
	-- the star and its corona
	local n = #out + 1
	table.insert(out, ball(0.42, c, C(255, 252, 235), M.Neon, {name = "Core", SkinPart = "Blade"}))
	table.insert(out, ball(0.62, c, C(255, 200, 90), M.Neon, {transparency = 0.6, name = "Corona"}))
	out[n + 1].anim = {pulse = {0.5, 0.8, 2.2}}
	-- the worlds: (radius, size, colour, speed, tilt)
	local worlds = {{0.55, 0.12, C(110, 190, 255), 2.4, tilt(8, 0)}, {0.82, 0.16, C(255, 110, 80), 1.5, tilt(-14, 6)}, {1.14, 0.24, C(232, 200, 140), 0.85, tilt(10, -12)}}
	for i, w in ipairs(worlds) do
		local r, d, col, sp, tk = w[1], w[2], w[3], w[4], w[5]
		-- the orbit's path in dust
		local pth = #out + 1
		dots(out, c, tk, r, 28, 0.03, C(200, 210, 255), M.Neon, {transparency = 0.45})
		animate(out, pth, spin(c, tk.UpVector, 0.1))
		local a0 = i * 2.1
		local at = c + tk:VectorToWorldSpace(V(math.cos(a0) * r, 0, math.sin(a0) * r))
		local orbit = {c = c, axis = tk.UpVector, speed = sp}
		local wi = #out + 1
		table.insert(out, ball(d, at, col, M.Neon, {name = "World" .. i}))
		if i == 3 then
			-- the ringed one: its rings, and a moon going round it as it goes round the star
			ring(out, at, tilt(28, 0), 0.22, 14, 0.025, C(255, 236, 200), M.Neon)
			animate(out, wi, {rot = {{c = at, axis = V(0, 1, 0), speed = 1.5}, orbit}})
			local mi = #out + 1
			table.insert(out, ball(0.07, at + V(0.34, 0.04, 0), C(230, 230, 240), M.Neon, {name = "Moon"}))
			animate(out, mi, {rot = {{c = at, axis = V(0.15, 1, 0).Unit, speed = 3.2}, orbit}})
		else
			animate(out, wi, {rot = {orbit}})
		end
	end
	-- the crown of constellations: stars on a great tilted wheel, joined by faint lines
	local crown = tilt(-22, 14)
	local ci = #out + 1
	for k = 0, 8 do
		local a = k / 9 * 2 * PI
		local rr = 1.42 + (k % 3 - 1) * 0.08
		table.insert(out, ball(k % 3 == 0 and 0.1 or 0.07, c + crown:VectorToWorldSpace(V(math.cos(a) * rr, (k % 2) * 0.1, math.sin(a) * rr)), Color3.new(1, 1, 1), M.Neon, {name = "Star" .. k}))
	end
	animate(out, ci, {rot = {{c = c, axis = crown.UpVector, speed = -0.35}}})
	local beams = {}
	for k = 0, 8 do table.insert(beams, {a = "Star" .. k, b = "Star" .. ((k + 1) % 9), color = C(190, 210, 255), width = 0.03, faint = true}) end
	return {parts = out, hide = CLAWS, tip = c,
		fx = {lights = {{at = c, color = C(255, 236, 190), range = 16, brightness = 2.3, hue = true}},
			beams = beams,
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), C(255, 220, 140), {{0, 0.06}, {0.5, 0.26}, {1, 0}}, 24, {0.4, 0.9}, {0, 0.05}, nil, 1, {locked = true})},
				{at = "Corona", def = {tex = TEX.smoke, c0 = C(140, 90, 255), c1 = C(60, 140, 255), size = {{0, 0.6}, {1, 2}}, rate = 6, life = {1.4, 2.2}, speed = {0.1, 0.35}, spread = 180, light = 1, transp = {{0, 0.8}, {1, 1}}, rot = 30}},
				{at = "Corona", def = motes(Color3.new(1, 1, 1), C(160, 190, 255), {{0, 0.05}, {0.5, 0.1}, {1, 0}}, 20, {1.5, 2.6}, {0.3, 0.9}, nil, 1)}},
			trails = {{part = "World1", color = C(110, 190, 255), life = 0.35, width = 0.1}, {part = "World2", color = C(255, 120, 90), life = 0.45, width = 0.12},
				{part = "World3", color = C(240, 210, 150), life = 0.6, width = 0.16}, {part = "Moon", color = Color3.new(1, 1, 1), life = 0.25, width = 0.05}}}}
end

--------------------------------------------------------------------
--  WANDS AND GRIMOIRES: the Mage's other two weapons get whole new shapes too (a wand skin
--  or a grimoire skin names a design with head = "<design>", like a staff's). Same ladder:
--  a Common has its own shape and a glow; the rarer, the more that moves and burns.
--  A wand (Build ▸ Weapons ▸ Wand): its rod, crystal, collar and pommel give way to the
--  design's (the leather grip stays). A grimoire (Build ▸ Weapons ▸ Tome): its covers,
--  spine, corners, rune and ribbon give way; the open pages stay unless a design takes them.
--------------------------------------------------------------------
local WAND = {"Rod", "Crystal", "Collar", "Pommel"}
local TOME = {"Cover", "Corner", "Spine", "Rune", "Ribbon"}
local TOME_PAGES = {"Cover", "Corner", "Spine", "Rune", "Ribbon", "Pages", "Script"}

-- a flat disc / coin, its axis along `cf`'s Y
local function disc(cf, d, h, color, mat, extra) return spec("Cylinder", V(h, d, d), cf * CFrame.Angles(0, 0, PI / 2), color, mat, extra) end
-- a flat star of `n` points in the plane of `cf` (its Z is the star's face)
local function star(out, cf, n, r, w, th, color, mat, extra)
	for k = 0, n - 1 do
		local a = k / n * 2 * PI
		local dir = cf:VectorToWorldSpace(V(math.sin(a), math.cos(a), 0))
		thorn(out, CFrame.fromMatrix(cf.Position, cf.ZVector, dir), r, w, th, color, mat, extra)
	end
end
-- points winding round the Y axis from y0 to y1 (a spiral, a vine, a coil), the radius going r → r1
local function helix(y0, y1, r, turns, n, phase, r1)
	local pts = {}
	for i = 0, n do
		local t = i / n
		local a = (phase or 0) + t * turns * 2 * PI
		local rr = r + ((r1 or r) - r) * t
		table.insert(pts, V(math.cos(a) * rr, y0 + (y1 - y0) * t, math.sin(a) * rr))
	end
	return pts
end
-- a flat thorn lying on a surface whose normal is `n`, pointing along `dir`
local function flatThorn(out, pos, n, dir, len, width, th, color, mat, extra)
	thorn(out, CFrame.fromMatrix(pos, n.Unit, (dir - n.Unit * dir:Dot(n.Unit)).Unit), len, width, th, color, mat, extra)
end
-- a sigil: two rings of light, a star and runes, in the plane facing +Z, turning. -> first index
local function sigil(out, at, r, color, n, speed, extra)
	local face = CFrame.Angles(PI / 2, 0, 0)   -- (a ring's frame: its axis along +Z)
	local i0 = #out + 1
	ring(out, at, face, r, math.max(10, math.floor(r * 60)), 0.02, color, M.Neon, extra)
	ring(out, at, face, r * 0.78, math.max(8, math.floor(r * 48)), 0.012, color, M.Neon, extra)
	star(out, CFrame.new(at), n, r * 0.72, r * 0.22, 0.012, color, M.Neon, extra)
	for k = 0, n - 1 do
		local a = (k + 0.5) / n * 2 * PI
		table.insert(out, block(V(0.035, 0.035, 0.012), CFrame.new(at + V(math.sin(a) * r * 0.89, math.cos(a) * r * 0.89, 0)) * CFrame.Angles(0, 0, -a + PI / 4), color, M.Neon, extra))
	end
	animate(out, i0, spin(at, V(0, 0, 1), speed))
	return i0
end

-- A WAND'S BODY below its head: a pommel, a collar, a shaft tapering from the collar to `top`.
-- o = {top, d0, d1, wood (colour), mat, segs, pommel, collar} -> the top of the shaft
local function wandShaft(out, P, o)
	o = o or {}
	local top, d0, d1 = o.top or 1.15, o.d0 or 0.11, o.d1 or 0.07
	local col, mat, segs = o.wood or P.grip, o.mat or M.Wood, o.segs or 4
	table.insert(out, ball(o.pommelD or 0.17, V(0, -0.25, 0), o.pommel or P.metal, M.Metal))
	table.insert(out, disc(CFrame.new(0, 0.235, 0), 0.17, 0.07, o.collar or P.metal, M.Metal))
	for i = 0, segs - 1 do
		local a, b = 0.25 + (top - 0.25) * i / segs, 0.25 + (top - 0.25) * (i + 1) / segs
		table.insert(out, rod(V(0, a, 0), V(0, b + 0.012, 0), d0 + (d1 - d0) * (i + 0.5) / segs, col, mat))
	end
	return V(0, top, 0)
end

-- A GRIMOIRE'S COVERS, as the blueprint lays them: s = -1 the left, 1 the right; each cover's
-- frame has X across it, Y up it, and its outside facing -Z (the open pages face +Z)
local function coverCF(s) return CFrame.new(s * 0.34, 0.66, -0.07) * CFrame.Angles(0, math.rad(s * -8), 0) end
-- a point on a cover's outside: x out from its middle toward its open edge (mirrored, so both
-- covers match), y up from its middle, d off its face
local function onCover(s, x, y, d) return coverCF(s) * CFrame.new(s * x, y, -0.04 - (d or 0)) end
-- new covers and spine; o = {color, mat, spine, th}
local function tomeCovers(out, P, o)
	o = o or {}
	local col, mat = o.color or P.grip, o.mat or M.Leather
	for _, s in ipairs({-1, 1}) do
		table.insert(out, block(V(0.66, 1.38, o.th or 0.08), coverCF(s), col, mat, {transparency = o.transparency}))
	end
	table.insert(out, spec("Cylinder", V(1.38, 0.14, 0.14), CFrame.new(0, 0.66, -0.1) * CFrame.Angles(0, 0, PI / 2), o.spine or col, mat))
end
-- metal caps on the eight corners (outer, both covers)
local function tomeCorners(out, color, mat, size)
	for _, s in ipairs({-1, 1}) do
		for _, x in ipairs({-0.29, 0.29}) do
			for _, y in ipairs({-0.65, 0.65}) do
				table.insert(out, block(V(size or 0.13, size or 0.13, 0.03), onCover(s, x, y, 0.005), color, mat or M.Metal))
			end
		end
	end
end
-- a strip of metal round a cover's edge (four bars)
local function tomeBorder(out, inset, w, color, mat)
	for _, s in ipairs({-1, 1}) do
		local hx, hy = 0.33 - inset, 0.69 - inset
		table.insert(out, block(V(hx * 2, w, 0.015), onCover(s, 0, hy, 0.002), color, mat))
		table.insert(out, block(V(hx * 2, w, 0.015), onCover(s, 0, -hy, 0.002), color, mat))
		table.insert(out, block(V(w, hy * 2, 0.015), onCover(s, hx, 0, 0.002), color, mat))
		table.insert(out, block(V(w, hy * 2, 0.015), onCover(s, -hx, 0, 0.002), color, mat))
	end
end
-- the outward normal of a cover (-Z of its frame)
local function outward(s) return coverCF(s):VectorToWorldSpace(V(0, 0, -1)) end
local BOOK_C = V(0, 0.66, 0)   -- the middle of the open book

--------------------------------------------------------------------
--  WANDS
--------------------------------------------------------------------
-- BIRCH (Common): white birch with black bark marks and a knot; a moonstone breathes in a silver cup
D.birch = function(G, P)
	local out = {}
	local top = wandShaft(out, P, {top = 1.12, d0 = 0.12, d1 = 0.08, wood = C(236, 232, 222)})
	for i, y in ipairs({0.36, 0.47, 0.6, 0.74, 0.86, 0.99}) do
		local a = i * 2.3
		table.insert(out, block(V(0.03, 0.018, 0.06), CFrame.new(math.cos(a) * 0.046, y, math.sin(a) * 0.046) * CFrame.Angles(0, -a, 0), C(36, 34, 34)))
	end
	table.insert(out, ball(0.12, V(0.025, 0.62, 0), C(222, 214, 198), M.Wood))
	for k = 0, 2 do
		local a = k / 3 * 2 * PI
		local d = V(math.cos(a), 0, math.sin(a))
		bend(out, {top + V(0, -0.03, 0), top + d * 0.075 + V(0, 0.06, 0), top + d * 0.055 + V(0, 0.19, 0)}, 0.028, P.metal, M.Metal)
	end
	local core = top + V(0, 0.12, 0)
	local n = #out + 1
	table.insert(out, egg(V(0.11, 0.17, 0.11), CFrame.new(core), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {pulse = {0, 0.35, 1.8}}
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = P.blade, range = 4, brightness = 0.7, pulse = 1.8}},
			emit = {{at = "Core", def = motes(P.blade, C(200, 220, 255), {{0, 0.05}, {1, 0}}, 4, {0.8, 1.4}, {0.05, 0.2}, V(0, 0.3, 0))}}}}
end

-- HOLLY (Rare): dark wood wound with a holly vine; berries at the collar; a crown of spiked
-- leaves round a red gem that turns; snow drifts down round it
D.holly = function(G, P)
	local out = {}
	local green = C(34, 104, 48)
	local top = wandShaft(out, P, {top = 1.12, wood = C(58, 44, 34)})
	local vine = helix(0.3, 1.04, 0.058, 2.2, 16, 0)
	bend(out, vine, 0.024, green)
	for i = 3, #vine - 1, 3 do
		local p = vine[i]
		leaf(out, p, V(p.X, 0, p.Z).Unit + V(0, 0.9, 0), 0.13, 0.07, C(30, 124, 52))
	end
	for k = 0, 2 do table.insert(out, ball(0.065, V(math.cos(k * 2.1) * 0.085, 0.31 + (k % 2) * 0.05, math.sin(k * 2.1) * 0.085), C(220, 26, 36), M.Glass)) end
	for k = 0, 4 do
		local a = k / 5 * 2 * PI
		local d = V(math.cos(a), 0, math.sin(a))
		leaf(out, top + d * 0.03, d * 0.7 + V(0, 1, 0), 0.22, 0.11, green)
	end
	local core = top + V(0, 0.13, 0)
	local n = #out + 1
	table.insert(out, block(V(0.1, 0.1, 0.1), CFrame.new(core) * CFrame.Angles(PI / 4, 0, PI / 4), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {rot = {{c = core, axis = V(0, 1, 0), speed = 1.4}}, bob = {0.015, 2.2, 0}}
	local m = #out + 1
	dots(out, core, tilt(15, 0), 0.19, 5, 0.035, Color3.new(1, 1, 1), M.Neon)
	animate(out, m, spin(core, CFrame.Angles(math.rad(15), 0, 0).UpVector, 1.8))
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = P.blade, range = 5, brightness = 0.9}},
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), C(220, 240, 255), {{0, 0.06}, {1, 0.02}}, 7, {1, 1.6}, {0.1, 0.3}, V(0, -0.8, 0), 0.6, {rot = 60})}}}}
end

-- EBONY (Rare): black lacquer ringed and wound with silver; a cut diamond turns in silver
-- claws, a silver halo tumbling under it; starlight glints
D.ebony = function(G, P)
	local out = {}
	local top = wandShaft(out, P, {top = 1.12, d0 = 0.11, d1 = 0.075, wood = C(20, 18, 22), mat = M.SmoothPlastic})
	for _, y in ipairs({0.42, 0.7, 0.98}) do table.insert(out, disc(CFrame.new(0, y, 0), 0.118, 0.03, P.metal, M.Metal)) end
	bend(out, helix(0.44, 0.96, 0.047, 1.5, 12, 0.5), 0.016, P.metal, M.Metal)
	for k = 0, 2 do
		local a = k / 3 * 2 * PI + 0.5
		local d = V(math.cos(a), 0, math.sin(a))
		bend(out, {top, top + d * 0.085 + V(0, 0.08, 0), top + d * 0.05 + V(0, 0.2, 0)}, 0.025, P.metal, M.Metal)
	end
	local core = top + V(0, 0.14, 0)
	local n = #out + 1
	thorn(out, CFrame.new(core), 0.14, 0.15, 0.15, P.blade, M.Glass, {transparency = 0.05, name = "Core", SkinPart = "Blade"})
	thorn(out, CFrame.new(core) * CFrame.Angles(PI, 0, 0), 0.1, 0.15, 0.15, P.blade, M.Glass, {transparency = 0.05})
	table.insert(out, ball(0.06, core, Color3.new(1, 1, 1), M.Neon))
	animate(out, n, spin(core, V(0, 1, 0), 0.8))
	local m = #out + 1
	ring(out, core - V(0, 0.03, 0), tilt(0, 0), 0.16, 12, 0.014, P.metal, M.Neon)
	animate(out, m, spin(core, V(1, 0, 0), 1.2))
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = C(220, 230, 255), range = 6, brightness = 1}},
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), C(200, 215, 255), {{0, 0}, {0.5, 0.12}, {1, 0}}, 5, {0.3, 0.6}, {0, 0.05}, nil, 1, {locked = true, rot = 30})}}}}
end

-- CORAL (Rare): a branch of living coral forks into three arms cupping a pearl that bobs;
-- bubbles rise from it
D.coral = function(G, P)
	local out = {}
	local top = wandShaft(out, P, {top = 0.9, d0 = 0.12, d1 = 0.09, mat = M.Slate})
	for i = 0, 6 do local a = i * 2.4; table.insert(out, ball(0.05, V(math.cos(a) * 0.05, 0.35 + i * 0.08, math.sin(a) * 0.05), P.grip, M.Slate)) end
	for k = 0, 2 do
		local a = k / 3 * 2 * PI
		local d = V(math.cos(a), 0, math.sin(a))
		local p1, p2, p3 = top + d * 0.06 + V(0, 0.12, 0), top + d * 0.14 + V(0, 0.27, 0), top + d * 0.08 + V(0, 0.42, 0)
		bend(out, {top, p1, p2, p3}, 0.045, P.grip, M.Slate)
		table.insert(out, ball(0.05, p3, P.grip, M.Slate))
		bend(out, {p1, p1 + d * 0.11 + V(0, 0.08, 0)}, 0.03, P.grip, M.Slate)
		table.insert(out, ball(0.035, p1 + d * 0.11 + V(0, 0.08, 0), P.grip, M.Slate))
	end
	local core = top + V(0, 0.27, 0)
	local n = #out + 1
	table.insert(out, ball(0.14, core, P.metal, M.Glass, {name = "Core", SkinPart = "Blade", transparency = 0.15}))
	table.insert(out, ball(0.09, core, P.blade, M.Neon))
	animate(out, n, {bob = {0.02, 1.6, 0}})
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = P.blade, range = 5, brightness = 0.9, pulse = 1.2}},
			emit = {{at = "Core", def = {tex = TEX.spark, c0 = C(220, 250, 255), c1 = P.blade, size = {{0, 0.04}, {1, 0.08}}, rate = 7, life = {1, 1.8}, speed = {0.2, 0.4}, accel = V(0, 0.6, 0), spread = 30, light = 0.4, transp = {{0, 0.3}, {1, 1}}}}}}}
end

-- PHOENIX FEATHER (Epic): a gold-wound wand crowned in flame petals; two fans of burning
-- feathers beat like wings round a coal-bright heart; fire licks up, sparks fly
D.phoenix = function(G, P)
	local out = {}
	local top = wandShaft(out, P, {top = 1.06, d0 = 0.11, d1 = 0.08, mat = M.SmoothPlastic})
	bend(out, helix(0.3, 1.0, 0.052, 2, 14, 0), 0.02, P.metal, M.Foil)
	local core = top + V(0, 0.1, 0)
	for k = 0, 5 do
		local a = k / 6 * 2 * PI
		local d = V(math.cos(a), 0, math.sin(a))
		thorn(out, along(top + d * 0.03, d * 0.6 + V(0, 1, 0)), 0.16 + (k % 2) * 0.07, 0.075, 0.025, k % 2 == 0 and P.metal or C(255, 120, 40), k % 2 == 0 and M.Foil or M.Neon)
	end
	for _, s in ipairs({-1, 1}) do
		local w0 = #out + 1
		for f = 0, 3 do
			leaf(out, core + V(s * 0.03, -0.03, 0), V(s * (0.7 + f * 0.15), 0.9 - f * 0.35, -0.35), 0.36 - f * 0.04, 0.1, f % 2 == 0 and C(255, 160, 60) or C(255, 84, 30), M.Neon)
		end
		animate(out, w0, {osc = {c = core, axis = V(0, 0, s), amp = 0.28, speed = 4}})
	end
	local n = #out + 1
	table.insert(out, ball(0.13, core, P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {pulse = {0, 0.35, 5}}
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = C(255, 130, 50), range = 7, brightness = 1.2, flicker = true}},
			emit = {{at = "Core", def = {tex = TEX.fire, c0 = C(255, 190, 80), c1 = C(230, 60, 10), size = {{0, 0.2}, {0.5, 0.13}, {1, 0.02}}, rate = 18, life = {0.25, 0.45}, speed = {0.3, 0.8}, accel = V(0, 4, 0), spread = 20, light = 1, transp = {{0, 0.2}, {1, 1}}}},
				{at = "Core", def = motes(C(255, 220, 110), C(255, 70, 20), {{0, 0.05}, {1, 0}}, 12, {0.5, 1.1}, {0.4, 1.4}, V(0, 4, 0), 1, {spread = 60})}}}}
end

-- UNICORN HAIR (Epic): a spiral horn of pearl, a ribbon of light winding up it, little wings
-- at the collar; at the point, a prism turning in a halo that walks the rainbow
D.unicorn = function(G, P)
	local out = {}
	local top = wandShaft(out, P, {top = 1.32, d0 = 0.13, d1 = 0.035, mat = M.Marble, segs = 8})
	bend(out, helix(0.27, 1.28, 0.066, 4, 32, 0, 0.022), 0.022, P.metal, M.Neon)
	for _, s in ipairs({-1, 1}) do
		local w0 = #out + 1
		for f = 0, 2 do leaf(out, V(s * 0.06, 0.26, 0), V(s * (1 - f * 0.2), 0.3 + f * 0.35, -0.2), 0.22 - f * 0.03, 0.08, Color3.new(1, 1, 1)) end
		animate(out, w0, {osc = {c = V(0, 0.26, 0), axis = V(0, 0, s), amp = 0.3, speed = 3}})
	end
	local core = top + V(0, 0.08, 0)
	local n = #out + 1
	table.insert(out, block(V(0.09, 0.09, 0.09), CFrame.new(core) * CFrame.Angles(PI / 4, 0, PI / 4), Color3.new(1, 1, 1), M.Neon, {name = "Core", SkinPart = "Blade"}))
	animate(out, n, spin(core, V(0, 1, 0), 2))
	local m = #out + 1
	for k = 0, 5 do
		local a = k / 6 * 2 * PI
		table.insert(out, ball(0.045, core + V(math.cos(a) * 0.16, 0, math.sin(a) * 0.16), hsv(k / 6, 0.55, 1), M.Neon, {name = "Hue" .. k}))
	end
	animate(out, m, spin(core, V(0.2, 1, 0).Unit, 2.4))
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = P.blade, range = 6, brightness = 1.1, hue = true}},
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), P.blade, {{0, 0.07}, {1, 0}}, 10, {0.7, 1.2}, {0.1, 0.4}, V(0, 0.5, 0), 1, {rot = 90})}},
			trails = {{part = "Hue0", color = hsv(0, 0.5, 1), life = 0.3, width = 0.04}, {part = "Hue2", color = hsv(0.33, 0.5, 1), life = 0.3, width = 0.04},
				{part = "Hue4", color = hsv(0.66, 0.5, 1), life = 0.3, width = 0.04}}}}
end

-- WILLOW WISP (Epic): a willow branch bowing over, its strands weeping; a ghost-light hangs
-- at the tip and three wisps drift round it, trailing light
D.willowwisp = function(G, P)
	local out = {}
	local top = wandShaft(out, P, {top = 0.95, d0 = 0.11, d1 = 0.08})
	local crook = {top, top + V(0.04, 0.12, 0), top + V(0.11, 0.2, 0), top + V(0.2, 0.22, 0)}
	bend(out, crook, 0.06, P.grip, M.Wood)
	table.insert(out, ball(0.06, crook[4], P.grip, M.Wood))
	for k = 0, 5 do
		local base = crook[2 + k % 3] + V(0, -0.01, (k - 2.5) * 0.025)
		local pts = {base, base + V(0.02, -0.13, 0.01 * k), base + V(0.035, -0.28, 0)}
		bend(out, pts, 0.014, C(120, 150, 80))
		leaf(out, pts[3], V(0.1, -1, 0), 0.07, 0.035, C(150, 210, 120))
	end
	local core = top + V(0.03, 0.36, 0)
	local n = #out + 1
	table.insert(out, ball(0.1, core, P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {bob = {0.03, 1.4, 0}, pulse = {0, 0.3, 2.4}}
	table.insert(out, ball(0.18, core, P.blade, M.Neon, {transparency = 0.7}))
	out[n + 1].anim = {bob = {0.03, 1.4, 0}, pulse = {0.6, 0.85, 2.4}}
	local orbits = {{0.22, tilt(20, 0), 1.6}, {0.3, tilt(-25, 30), -1.1}, {0.38, tilt(10, -40), 0.8}}
	for i, w in ipairs(orbits) do
		local wi = #out + 1
		table.insert(out, ball(0.05, core + w[2]:VectorToWorldSpace(V(w[1], 0, 0)), C(190, 255, 210), M.Neon, {name = "Wisp" .. i}))
		out[wi].anim = {rot = {{c = core, axis = w[2].UpVector, speed = w[3]}}, bob = {0.04, 1.1 + i * 0.3, i}}
	end
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = P.blade, range = 7, brightness = 1, pulse = 2.4}},
			emit = {{at = "Core", def = {tex = TEX.smoke, c0 = P.blade, c1 = C(60, 120, 90), size = {{0, 0.12}, {1, 0.4}}, rate = 4, life = {1, 1.6}, speed = {0.05, 0.15}, spread = 180, light = 0.6, transp = {{0, 0.75}, {1, 1}}}},
				{at = "Core", def = motes(C(210, 255, 220), P.blade, {{0, 0.05}, {1, 0}}, 6, {0.8, 1.4}, {0.1, 0.3}, V(0, 0.2, 0), 1)}},
			trails = {{part = "Wisp1", color = C(170, 255, 200), life = 0.5, width = 0.05}, {part = "Wisp2", color = C(170, 255, 200), life = 0.5, width = 0.05},
				{part = "Wisp3", color = C(170, 255, 200), life = 0.5, width = 0.05}}}}
end

-- ELDER BRANCH (Legendary): the knotted elder wand; above it a white star turns inside a
-- golden gyroscope, three runes circle, and it shines like a little sun
D.elder = function(G, P)
	local out = {}
	local top = wandShaft(out, P, {top = 1.2, d0 = 0.1, d1 = 0.07, wood = C(96, 88, 78)})
	for i = 0, 6 do table.insert(out, ball(0.118 - i * 0.007, V(0, 0.3 + i * 0.13, 0), C(112, 102, 90), M.Wood)) end
	local core = top + V(0, 0.22, 0)
	table.insert(out, rod(top, core - V(0, 0.08, 0), 0.03, P.metal, M.Metal))
	local n = #out + 1
	star(out, CFrame.new(core), 4, 0.21, 0.075, 0.03, Color3.new(1, 1, 1), M.Neon, {name = "Core", SkinPart = "Blade"})
	star(out, CFrame.new(core) * CFrame.Angles(0, 0, PI / 4), 4, 0.12, 0.065, 0.03, C(255, 236, 170), M.Neon)
	table.insert(out, ball(0.08, core, Color3.new(1, 1, 1), M.Neon))
	animate(out, n, spin(core, V(0, 1, 0), 1.2))
	local m = #out + 1
	ring(out, core, CFrame.Angles(PI / 2, 0, 0), 0.27, 16, 0.018, GOLD, M.Foil)
	animate(out, m, spin(core, V(0, 1, 0), -0.7))
	local m2 = #out + 1
	ring(out, core, CFrame.Angles(0, 0, PI / 2), 0.32, 18, 0.014, GOLD, M.Foil)
	animate(out, m2, spin(core, V(0, 1, 0), 0.45))
	local r0 = #out + 1
	for k = 0, 2 do
		local a = k / 3 * 2 * PI
		table.insert(out, block(V(0.06, 0.08, 0.012), CFrame.new(core + V(math.cos(a) * 0.42, -0.05, math.sin(a) * 0.42)) * CFrame.Angles(0, -a + PI / 2, 0), C(255, 240, 190), M.Neon, {name = "Rune" .. k}))
	end
	animate(out, r0, spin(core, V(0, 1, 0), 0.9))
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = C(255, 245, 220), range = 10, brightness = 1.5, pulse = 1.5}},
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), C(255, 230, 160), {{0, 0.1}, {0.5, 0.18}, {1, 0}}, 10, {0.4, 0.8}, {0, 0.1}, nil, 1, {locked = true, rot = 40})},
				{at = "Core", def = motes(C(255, 250, 220), C(255, 220, 140), {{0, 0.04}, {1, 0}}, 14, {0.8, 1.4}, {0.2, 0.6}, V(0, 0.6, 0), 1)}},
			trails = {{part = "Rune0", color = C(255, 236, 170), life = 0.3, width = 0.05}, {part = "Rune1", color = C(255, 236, 170), life = 0.3, width = 0.05},
				{part = "Rune2", color = C(255, 236, 170), life = 0.3, width = 0.05}}}}
end

-- THUNDERROD (Legendary): an iron rod wound in copper; a fork at the top with lightning
-- jumping between its prongs and up into a charged ball inside tumbling rings; sparks spit
D.thunderrod = function(G, P)
	local out = {}
	local copper = C(204, 124, 72)
	local top = wandShaft(out, P, {top = 1.04, d0 = 0.1, d1 = 0.09, mat = M.Metal})
	bend(out, helix(0.3, 0.95, 0.06, 6, 40, 0), 0.022, copper, M.Metal)
	for _, s in ipairs({-1, 1}) do
		bend(out, {top, top + V(s * 0.1, 0.06, 0), top + V(s * 0.12, 0.3, 0)}, 0.035, P.metal, M.Metal)
		table.insert(out, ball(0.065, top + V(s * 0.12, 0.31, 0), P.blade, M.Neon, {name = s < 0 and "ForkL" or "ForkR"}))
	end
	local core = top + V(0, 0.47, 0)
	local n = #out + 1
	table.insert(out, ball(0.13, core, P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {pulse = {0, 0.4, 9}, bob = {0.015, 3, 0}}
	for i, tk in ipairs({tilt(0, 0), tilt(60, 0), tilt(-60, 0)}) do
		local m = #out + 1
		ring(out, core, tk, 0.18, 12, 0.013, C(180, 230, 255), M.Neon, {transparency = 0.15})
		animate(out, m, {rot = {{c = core, axis = tk.RightVector, speed = 2 + i * 0.7}, {c = core, axis = V(0, 1, 0), speed = 0.8}}})
	end
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = C(170, 220, 255), range = 9, brightness = 1.6, flicker = true}},
			beams = {{a = "ForkL", b = "ForkR", color = C(210, 240, 255), width = 0.06, crackle = true}, {a = "ForkL", b = "Core", color = C(170, 220, 255), width = 0.045, crackle = true},
				{a = "ForkR", b = "Core", color = C(170, 220, 255), width = 0.045, crackle = true}},
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), C(140, 200, 255), {{0, 0.06}, {1, 0}}, 18, {0.15, 0.35}, {1.5, 3}, nil, 1)}}}}
end

-- STARFALL WAND (Mythic): a wand of night sky, gold-wound and starred; at its point a gold
-- star turns before a crescent moon; two comets fly round it, a crown of stars wheels above,
-- and stardust falls
D.starfall = function(G, P)
	local out = {}
	local top = wandShaft(out, P, {top = 1.16, d0 = 0.11, d1 = 0.075, mat = M.SmoothPlastic})
	bend(out, helix(0.3, 1.1, 0.05, 2.5, 20, 0), 0.016, P.metal, M.Foil)
	for i = 0, 5 do local a = i * 2.2; table.insert(out, ball(0.032, V(math.cos(a) * 0.05, 0.35 + i * 0.13, math.sin(a) * 0.05), Color3.new(1, 1, 1), M.Neon)) end
	local core = top + V(0, 0.24, 0)
	table.insert(out, rod(top, core - V(0, 0.1, 0), 0.03, P.metal, M.Foil))
	-- the crescent moon (an arc of beads, fat in the middle), behind the star
	for k = -6, 6 do
		local a = k / 6 * 2.2
		table.insert(out, ball(0.035 + 0.075 * (1 - math.abs(k) / 6.5), core + V(-math.cos(a) * 0.2, math.sin(a) * 0.2, -0.05), C(250, 244, 220), M.Neon))
	end
	local n = #out + 1
	star(out, CFrame.new(core), 5, 0.17, 0.1, 0.04, P.metal, M.Neon, {name = "Core", SkinPart = "Blade"})
	table.insert(out, ball(0.08, core, Color3.new(1, 1, 1), M.Neon))
	animate(out, n, spin(core, V(0, 0, 1), 0.9))
	for i, w in ipairs({{0.34, tilt(25, 10), 2.2}, {0.44, tilt(-30, -20), -1.5}}) do
		local ci = #out + 1
		table.insert(out, ball(0.06, core + w[2]:VectorToWorldSpace(V(w[1], 0, 0)), Color3.new(1, 1, 1), M.Neon, {name = "Comet" .. i}))
		out[ci].anim = {rot = {{c = core, axis = w[2].UpVector, speed = w[3]}}}
	end
	local cr = #out + 1
	local crown = tilt(-15, 10)
	for k = 0, 7 do
		local a = k / 8 * 2 * PI
		table.insert(out, ball(k % 2 == 0 and 0.05 or 0.035, core + V(0, 0.12, 0) + crown:VectorToWorldSpace(V(math.cos(a) * 0.52, 0, math.sin(a) * 0.52)), Color3.new(1, 1, 1), M.Neon, {name = "Star" .. k}))
	end
	animate(out, cr, spin(core + V(0, 0.12, 0), crown.UpVector, -0.4))
	local beams = {}
	for k = 0, 7 do table.insert(beams, {a = "Star" .. k, b = "Star" .. ((k + 1) % 8), color = C(190, 210, 255), width = 0.02, faint = true}) end
	return {parts = out, hide = WAND, tip = core,
		fx = {lights = {{at = core, color = C(255, 236, 190), range = 10, brightness = 1.8, hue = true}},
			beams = beams,
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), C(255, 220, 140), {{0, 0.06}, {0.5, 0.2}, {1, 0}}, 12, {0.4, 0.9}, {0, 0.05}, nil, 1, {locked = true})},
				{at = "Core", def = motes(Color3.new(1, 1, 1), C(160, 190, 255), {{0, 0.05}, {1, 0}}, 14, {1, 1.8}, {0.1, 0.4}, V(0, -1.5, 0), 1)}},
			trails = {{part = "Comet1", color = C(200, 220, 255), life = 0.45, width = 0.07}, {part = "Comet2", color = C(255, 230, 180), life = 0.5, width = 0.07}}}}
end

--------------------------------------------------------------------
--  GRIMOIRES
--------------------------------------------------------------------
-- LEATHERBOUND (Common): tooled leather, brass corners and spine bands, a brass medallion with
-- an amber stone on each cover; over the pages a warm sigil turns slowly; dust in the light
D.leatherbound = function(G, P)
	local out = {}
	tomeCovers(out, P, {mat = M.Leather})
	tomeCorners(out, P.metal)
	tomeBorder(out, 0.07, 0.02, C(70, 44, 28), M.Leather)
	for _, y in ipairs({0.22, 0.66, 1.1}) do table.insert(out, spec("Cylinder", V(0.06, 0.16, 0.16), CFrame.new(0, y, -0.1) * CFrame.Angles(0, 0, PI / 2), P.metal, M.Metal)) end
	for _, s in ipairs({-1, 1}) do
		table.insert(out, disc(onCover(s, 0, 0.05, 0.012) * CFrame.Angles(PI / 2, 0, 0), 0.26, 0.025, P.metal, M.Metal))
		table.insert(out, ball(0.1, onCover(s, 0, 0.05, 0.03).Position, P.blade, M.Neon))
	end
	table.insert(out, block(V(0.05, 0.55, 0.012), CFrame.new(0.05, 0.02, 0.04) * CFrame.Angles(0, 0, math.rad(6)), C(170, 36, 40), M.Fabric))
	local i0 = sigil(out, G.o, 0.22, P.blade, 4, 0.5)
	out[i0].name, out[i0].SkinPart = "Core", "Blade"
	return {parts = out, hide = TOME, tip = G.o,
		fx = {lights = {{at = G.o, color = P.blade, range = 5, brightness = 0.7, pulse = 1.4}},
			emit = {{at = G.o, def = motes(P.blade, C(255, 240, 210), {{0, 0.04}, {1, 0}}, 4, {1.2, 2}, {0.05, 0.2}, V(0, 0.2, 0))}}}}
end

-- BLUE FOLIO (Rare): blue leather framed in silver filigree, a silver crescent on each cover;
-- three loose pages float out and circle the book; a blue sigil turns over the open pages
D.bluefolio = function(G, P)
	local out = {}
	tomeCovers(out, P, {mat = M.Leather})
	tomeBorder(out, 0.05, 0.03, P.metal, M.Metal)
	tomeBorder(out, 0.11, 0.012, P.metal, M.Metal)
	for _, s in ipairs({-1, 1}) do
		for k = -4, 4 do
			local a = k / 4 * 1.9
			table.insert(out, ball(0.03 + 0.04 * (1 - math.abs(k) / 4.5), (onCover(s, -math.cos(a) * 0.15, math.sin(a) * 0.15, 0.01)).Position, P.metal, M.Metal))
		end
		for _, x in ipairs({-0.27, 0.27}) do for _, y in ipairs({-0.63, 0.63}) do
			table.insert(out, block(V(0.08, 0.08, 0.02), onCover(s, x, y, 0.01) * CFrame.Angles(0, 0, PI / 4), P.metal, M.Metal))
		end end
	end
	for k = 0, 2 do
		local a = k / 3 * 2 * PI
		local pi = #out + 1
		local at = BOOK_C + V(math.cos(a) * 0.82, 0.1 + k * 0.12, math.sin(a) * 0.82)
		table.insert(out, block(V(0.32, 0.42, 0.012), CFrame.new(at) * CFrame.Angles(0.2, -a, 0.15), C(240, 232, 212), M.SmoothPlastic, {name = "Leaf" .. k}))
		for l = 1, 3 do table.insert(out, block(V(0.22, 0.02, 0.014), CFrame.new(at) * CFrame.Angles(0.2, -a, 0.15) * CFrame.new(0, 0.12 - l * 0.07, 0), P.grip)) end
		animate(out, pi, {rot = {{c = BOOK_C, axis = V(0, 1, 0), speed = 0.7}}, bob = {0.08, 1.3, k * 2}})
	end
	local i0 = sigil(out, G.o, 0.22, P.blade, 6, -0.8)
	out[i0].name, out[i0].SkinPart = "Core", "Blade"
	return {parts = out, hide = TOME, tip = G.o,
		fx = {lights = {{at = G.o, color = P.blade, range = 6, brightness = 0.9}},
			emit = {{at = G.o, def = motes(Color3.new(1, 1, 1), P.blade, {{0, 0.05}, {1, 0}}, 6, {1, 1.6}, {0.1, 0.3}, V(0, 0.3, 0), 1)}},
			trails = {{part = "Leaf0", color = C(200, 220, 255), life = 0.3, width = 0.1}, {part = "Leaf1", color = C(200, 220, 255), life = 0.3, width = 0.1},
				{part = "Leaf2", color = C(200, 220, 255), life = 0.3, width = 0.1}}}}
end

-- HERBARIUM (Rare): moss-green covers overgrown with a creeping vine, leaves and flowers;
-- out of the open pages a seedling grows, its glowing bud swaying; pollen drifts, leaves circle
D.herbarium = function(G, P)
	local out = {}
	local moss = C(70, 112, 56)
	tomeCovers(out, P, {mat = M.Fabric})
	tomeCorners(out, P.metal, M.Metal, 0.11)
	for _, s in ipairs({-1, 1}) do
		local nrm = outward(s)
		local pts = {}
		for i = 0, 8 do
			local v = -0.6 + i * 0.15
			table.insert(pts, onCover(s, math.sin(i * 1.3) * 0.17, v, 0.015).Position)
		end
		bend(out, pts, 0.03, moss)
		for i = 2, #pts - 1, 2 do
			flatThorn(out, pts[i], nrm, coverCF(s):VectorToWorldSpace(V(s * (i % 4 == 0 and 1 or -1), 0.6, 0)), 0.16, 0.09, 0.02, C(96, 160, 70))
		end
		-- two flowers
		for _, f in ipairs({{0.15, 0.35}, {-0.12, -0.3}}) do
			local c0 = onCover(s, f[1], f[2], 0.02)
			for k = 0, 4 do
				local a = k / 5 * 2 * PI
				flatThorn(out, c0.Position, nrm, c0:VectorToWorldSpace(V(math.cos(a), math.sin(a), 0)), 0.09, 0.07, 0.015, C(255, 236, 160))
			end
			table.insert(out, ball(0.05, c0.Position + nrm * 0.01, C(255, 170, 60), M.Neon))
		end
	end
	-- the seedling
	local base = V(0, 0.42, 0.07)
	local sway = #out + 1
	local stem = {base, base + V(0.03, 0.12, 0.1), base + V(-0.02, 0.22, 0.25), G.o + V(0, -0.06, -0.02)}
	bend(out, stem, 0.035, C(110, 170, 70))
	leaf(out, stem[2], V(1, 0.5, 0.3), 0.18, 0.1, C(110, 190, 80))
	leaf(out, stem[3], V(-1, 0.4, 0.2), 0.16, 0.09, C(110, 190, 80))
	for k = 0, 4 do
		local a = k / 5 * 2 * PI
		leaf(out, G.o, V(math.cos(a), 0.9, math.sin(a)), 0.12, 0.08, C(255, 236, 170))
	end
	table.insert(out, egg(V(0.1, 0.14, 0.1), CFrame.new(G.o + V(0, 0.03, 0)), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	animate(out, sway, {osc = {c = base, axis = V(0, 0, 1), amp = 0.12, speed = 1.3}})
	-- leaves circling the book
	local lv = #out + 1
	for k = 0, 3 do
		local a = k / 4 * 2 * PI
		leaf(out, BOOK_C + V(math.cos(a) * 0.75, (k % 2) * 0.3 - 0.1, math.sin(a) * 0.75), V(math.sin(a), 0.4, -math.cos(a)), 0.14, 0.08, C(130, 200, 90))
	end
	animate(out, lv, {rot = {{c = BOOK_C, axis = V(0, 1, 0), speed = 0.5}}, bob = {0.06, 1.1, 0}})
	return {parts = out, hide = TOME, tip = G.o,
		fx = {lights = {{at = G.o, color = P.blade, range = 5, brightness = 0.8, pulse = 1.3}},
			emit = {{at = "Core", def = motes(C(255, 245, 170), P.blade, {{0, 0.05}, {1, 0}}, 6, {1.4, 2.2}, {0.05, 0.25}, V(0, 0.15, 0), 1, {rot = 40})}}}}
end

-- LEDGER OF DEBTS (Rare): a black ledger edged in gold, padlocked with a gold chain round its
-- covers; gold coins circle the book, one flips over the pages; everything glints
D.ledger = function(G, P)
	local out = {}
	tomeCovers(out, P, {mat = M.Leather})
	tomeBorder(out, 0.03, 0.035, P.metal, M.Foil)
	tomeCorners(out, P.metal, M.Foil, 0.12)
	for _, s in ipairs({-1, 1}) do
		-- a chain across, link by link
		for i = 0, 6 do
			local cf = onCover(s, -0.27 + i * 0.09, 0.3 - i * 0.09, 0.03)
			ring(out, cf.Position, cf * CFrame.Angles(i % 2 == 0 and 0 or PI / 2, 0, PI / 4) - cf.Position, 0.035, 6, 0.014, P.metal, M.Foil)
		end
		-- the padlock
		local lk = onCover(s, 0.05, -0.12, 0.05)
		table.insert(out, block(V(0.14, 0.12, 0.05), lk, P.metal, M.Foil))
		table.insert(out, block(V(0.03, 0.05, 0.06), lk * CFrame.new(0, -0.01, 0), C(30, 26, 20)))
		bend(out, {(lk * CFrame.new(-0.045, 0.05, 0)).Position, (lk * CFrame.new(-0.04, 0.12, 0)).Position, (lk * CFrame.new(0.04, 0.12, 0)).Position, (lk * CFrame.new(0.045, 0.05, 0)).Position}, 0.022, P.metal, M.Metal)
	end
	local cn = #out + 1
	for k = 0, 7 do
		local a = k / 8 * 2 * PI
		table.insert(out, disc(CFrame.new(BOOK_C + V(math.cos(a) * 0.72, math.sin(a * 2) * 0.12, math.sin(a) * 0.72)) * CFrame.Angles(0, -a, PI / 2), 0.13, 0.022, P.metal, M.Foil, {name = "Coin" .. k}))
	end
	animate(out, cn, spin(BOOK_C, V(0, 1, 0), 0.9))
	local n = #out + 1
	table.insert(out, disc(CFrame.new(G.o) * CFrame.Angles(PI / 2, 0, 0), 0.22, 0.03, P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	star(out, CFrame.new(G.o + V(0, 0, 0.02)), 5, 0.08, 0.05, 0.01, P.metal, M.Foil)
	animate(out, n, {rot = {{c = G.o, axis = V(0, 1, 0), speed = 2.4}}, bob = {0.03, 2, 0}})
	return {parts = out, hide = TOME, tip = G.o,
		fx = {lights = {{at = G.o, color = P.blade, range = 6, brightness = 1}},
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), P.blade, {{0, 0}, {0.5, 0.12}, {1, 0}}, 6, {0.3, 0.6}, {0, 0.05}, nil, 1, {locked = true, rot = 30})},
				{at = "Coin0", def = motes(C(255, 240, 160), P.metal, {{0, 0.04}, {1, 0}}, 5, {0.4, 0.8}, {0, 0.1}, nil, 1)}}}}
end

-- NECRONOMICON (Epic): pale bound covers with a carved skull whose eyes glow, bone spikes at
-- the corners, chains; over the pages a great green eye looks about; ghost-lights circle
D.necronomicon = function(G, P)
	local out = {}
	tomeCovers(out, P, {mat = M.Leather})
	local bone = P.metal or BONE
	for _, s in ipairs({-1, 1}) do
		local nrm = outward(s)
		for _, x in ipairs({-0.3, 0.3}) do for _, y in ipairs({-0.66, 0.66}) do
			flatThorn(out, onCover(s, x, y, 0.01).Position, nrm, coverCF(s):VectorToWorldSpace(V(s * x, y, 0)), 0.2, 0.09, 0.05, bone, M.Marble)
		end end
		-- the skull
		local sk = onCover(s, 0, 0.12, 0.05)
		table.insert(out, egg(V(0.32, 0.34, 0.12), sk, bone, M.Marble))
		table.insert(out, block(V(0.2, 0.1, 0.1), sk * CFrame.new(0, -0.19, 0), bone, M.Marble))
		for _, ex in ipairs({-0.07, 0.07}) do
			table.insert(out, ball(0.095, (sk * CFrame.new(ex, 0.02, -0.035)).Position, C(20, 18, 16)))
			local ei = #out + 1
			table.insert(out, ball(0.05, (sk * CFrame.new(ex, 0.02, -0.06)).Position, P.blade, M.Neon))
			out[ei].anim = {pulse = {0, 0.5, 3}}
		end
		for t = -1, 1 do table.insert(out, block(V(0.03, 0.04, 0.02), sk * CFrame.new(t * 0.05, -0.2, -0.055), C(30, 28, 26))) end
		-- a chain down the cover
		for i = 0, 7 do
			local cf = onCover(s, 0.26, 0.6 - i * 0.17, 0.02)
			ring(out, cf.Position, cf * CFrame.Angles(0, i % 2 == 0 and 0 or PI / 2, 0) - cf.Position, 0.045, 6, 0.015, C(80, 82, 86), M.Metal)
		end
	end
	-- the eye
	local n = #out + 1
	table.insert(out, ball(0.22, G.o, C(236, 230, 214), M.SmoothPlastic, {name = "Core", SkinPart = "Blade"}))
	table.insert(out, disc(CFrame.new(G.o + V(0, 0, 0.1)) * CFrame.Angles(PI / 2, 0, 0), 0.13, 0.03, P.blade, M.Neon))
	table.insert(out, disc(CFrame.new(G.o + V(0, 0, 0.115)) * CFrame.Angles(PI / 2, 0, 0), 0.06, 0.02, C(10, 10, 12)))
	animate(out, n, {osc = {c = G.o, axis = V(0, 1, 0), amp = 0.7, speed = 0.9}, bob = {0.03, 1.5, 0}})
	local gi = #out + 1
	for i, w in ipairs({{0.75, tilt(10, 0), 1.2}, {0.85, tilt(-20, 15), -0.9}, {0.65, tilt(25, -20), 0.7}}) do
		local wi = #out + 1
		table.insert(out, egg(V(0.1, 0.16, 0.1), CFrame.new(BOOK_C + w[2]:VectorToWorldSpace(V(w[1], 0, 0))), C(170, 255, 170), M.Neon, {transparency = 0.35, name = "Ghost" .. i}))
		out[wi].anim = {rot = {{c = BOOK_C, axis = w[2].UpVector, speed = w[3]}}, bob = {0.06, 1.2 + i * 0.2, i}}
	end
	return {parts = out, hide = TOME, tip = G.o,
		fx = {lights = {{at = G.o, color = P.blade, range = 7, brightness = 1, flicker = true}},
			emit = {{at = G.o, def = {tex = TEX.smoke, c0 = P.blade, c1 = C(30, 60, 40), size = {{0, 0.2}, {1, 0.7}}, rate = 6, life = {1, 1.8}, speed = {0.1, 0.3}, accel = V(0, 0.5, 0), spread = 180, light = 0.4, transp = {{0, 0.7}, {1, 1}}}}},
			trails = {{part = "Ghost1", color = C(170, 255, 170), life = 0.6, width = 0.08}, {part = "Ghost2", color = C(170, 255, 170), life = 0.6, width = 0.08},
				{part = "Ghost3", color = C(170, 255, 170), life = 0.6, width = 0.08}}}}
end

-- BOOK OF FLAMES (Epic): charred red covers split by glowing cracks, iron flame-spikes along
-- the top; the open pages burn, and over them a ring of fire turns round a burning heart
D.bookofflames = function(G, P)
	local out = {}
	tomeCovers(out, P, {mat = M.Slate})
	tomeCorners(out, C(40, 36, 34), M.Metal, 0.12)
	local glow = C(255, 120, 30)
	for _, s in ipairs({-1, 1}) do
		local nrm = outward(s)
		for c = 0, 2 do
			local pts, x, y = {}, -0.22 + c * 0.2, 0.62
			for i = 0, 5 do
				table.insert(pts, onCover(s, x, y, 0.004).Position)
				x += (i % 2 == 0 and 0.06 or -0.05) * (c == 1 and -1 or 1); y -= 0.22
			end
			bend(out, pts, 0.022, glow, M.Neon)
		end
		for k = 0, 4 do
			local x = -0.26 + k * 0.13
			flatThorn(out, onCover(s, x, 0.69, 0.0).Position, nrm, coverCF(s):VectorToWorldSpace(V(s * x * 0.5, 1, 0)), 0.14 + (k % 2) * 0.08, 0.08, 0.04, k % 2 == 0 and C(44, 40, 38) or glow, k % 2 == 0 and M.Metal or M.Neon)
		end
	end
	local r0 = #out + 1
	dots(out, G.o, CFrame.Angles(PI / 2, 0, 0), 0.25, 10, 0.05, C(255, 160, 50), M.Neon)
	for k = 0, 7 do
		local a = k / 8 * 2 * PI
		local d = V(math.sin(a), math.cos(a), 0)
		thorn(out, CFrame.fromMatrix(G.o + d * 0.25, V(0, 0, 1), d), 0.12, 0.07, 0.02, C(255, 100, 30), M.Neon)
	end
	animate(out, r0, spin(G.o, V(0, 0, 1), 1.4))
	local n = #out + 1
	table.insert(out, ball(0.15, G.o, P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {pulse = {0, 0.35, 6}}
	return {parts = out, hide = TOME, tip = G.o,
		fx = {lights = {{at = G.o, color = C(255, 130, 50), range = 9, brightness = 1.3, flicker = true}},
			emit = {{at = V(0, 0.66, 0.08), def = {tex = TEX.fire, c0 = C(255, 190, 80), c1 = C(220, 50, 10), size = {{0, 0.35}, {0.5, 0.25}, {1, 0.05}}, rate = 22, life = {0.3, 0.6}, speed = {0.3, 0.9}, accel = V(0, 4, 0), spread = 25, light = 1, transp = {{0, 0.3}, {1, 1}}}},
				{at = "Core", def = motes(C(255, 220, 110), C(255, 70, 20), {{0, 0.05}, {1, 0}}, 14, {0.5, 1.1}, {0.4, 1.4}, V(0, 4, 0), 1, {spread = 70})}}}}
end

-- FROST CODEX (Epic): covers of clear blue ice, frost spikes bristling along the top and
-- icicles hanging below; a six-armed snowflake turns over the pages; snow falls, cold mist
D.frostcodex = function(G, P)
	local out = {}
	tomeCovers(out, P, {mat = M.Glass, transparency = 0.15})
	tomeBorder(out, 0.04, 0.03, P.metal, M.Ice)
	local ice = C(200, 236, 255)
	for _, s in ipairs({-1, 1}) do
		local nrm = outward(s)
		for k = 0, 4 do
			local x = -0.26 + k * 0.13
			flatThorn(out, onCover(s, x, 0.69, 0).Position, nrm, coverCF(s):VectorToWorldSpace(V(s * x, 1, 0)), 0.18 + (k % 3) * 0.06, 0.08, 0.05, ice, M.Glass, {transparency = 0.1})
			flatThorn(out, onCover(s, x + 0.05, -0.69, 0).Position, nrm, V(0, -1, 0), 0.12 + (k % 2) * 0.1, 0.06, 0.04, ice, M.Glass, {transparency = 0.1})
		end
		-- a frost star etched on each cover
		star(out, onCover(s, 0, 0.05, 0.01) * CFrame.Angles(0, PI, 0), 6, 0.2, 0.05, 0.01, Color3.new(1, 1, 1), M.Neon)
	end
	-- the snowflake
	local n = #out + 1
	for k = 0, 5 do
		local a = k / 6 * 2 * PI
		local d = V(math.sin(a), math.cos(a), 0)
		table.insert(out, rod(G.o, G.o + d * 0.28, 0.025, P.blade, M.Neon))
		for _, f in ipairs({0.12, 0.2}) do
			for _, sd in ipairs({-1, 1}) do
				local b = V(math.sin(a + sd * 0.7), math.cos(a + sd * 0.7), 0)
				table.insert(out, rod(G.o + d * f, G.o + d * f + b * (0.3 - f) * 0.5, 0.018, P.blade, M.Neon))
			end
		end
	end
	table.insert(out, block(V(0.08, 0.08, 0.03), CFrame.new(G.o) * CFrame.Angles(0, 0, PI / 4), Color3.new(1, 1, 1), M.Neon, {name = "Core", SkinPart = "Blade"}))
	animate(out, n, spin(G.o, V(0, 0, 1), 0.6))
	return {parts = out, hide = TOME, tip = G.o,
		fx = {lights = {{at = G.o, color = C(150, 210, 255), range = 8, brightness = 1}},
			emit = {{at = "Core", def = motes(C(240, 252, 255), C(150, 214, 255), {{0, 0.08}, {1, 0.02}}, 14, {1, 1.8}, {0.1, 0.5}, V(0, -1.2, 0), 0.9, {rot = 80})},
				{at = V(0, 0.2, 0), def = {tex = TEX.smoke, c0 = C(205, 238, 255), size = {{0, 0.3}, {1, 0.9}}, rate = 5, life = {0.8, 1.3}, speed = {0.05, 0.2}, accel = V(0, -0.5, 0), spread = 180, light = 0.25, transp = {{0, 0.7}, {1, 1}}}}}}}
end

-- CELESTIAL ATLAS (Legendary): night-blue covers starred with gold constellations; over the
-- pages an armillary sphere, gold rings turning about a little sun, a moon on its round
D.celestialatlas = function(G, P)
	local out = {}
	tomeCovers(out, P, {mat = M.Leather})
	tomeBorder(out, 0.04, 0.025, P.metal, M.Foil)
	tomeCorners(out, P.metal, M.Foil, 0.1)
	local shapes = {{{-0.2, 0.45}, {-0.05, 0.52}, {0.1, 0.4}, {0.2, 0.5}}, {{-0.15, -0.1}, {0, 0.05}, {0.15, -0.05}, {0.05, -0.25}, {-0.15, -0.1}}, {{-0.2, -0.5}, {0, -0.42}, {0.2, -0.55}}}
	for _, s in ipairs({-1, 1}) do
		for _, sh in ipairs(shapes) do
			local prev
			for _, pt in ipairs(sh) do
				local p = onCover(s, pt[1], pt[2], 0.012).Position
				table.insert(out, ball(0.045, p, Color3.new(1, 1, 1), M.Neon))
				if prev then table.insert(out, rod(prev, p, 0.012, P.metal, M.Foil)) end
				prev = p
			end
		end
	end
	local sun = G.o + V(0, 0.08, 0)
	local n = #out + 1
	table.insert(out, ball(0.13, sun, C(255, 236, 170), M.Neon, {name = "Core", SkinPart = "Blade"}))
	table.insert(out, ball(0.2, sun, C(255, 190, 90), M.Neon, {transparency = 0.65}))
	out[n + 1].anim = {pulse = {0.5, 0.8, 2.2}}
	for i, tk in ipairs({tilt(0, 0), tilt(90, 0), tilt(0, 90), tilt(23, 0)}) do
		local m = #out + 1
		ring(out, sun, tk, i == 4 and 0.36 or 0.27, i == 4 and 22 or 16, 0.016, P.metal, M.Foil)
		if i == 4 then animate(out, m, spin(sun, tk.UpVector, 0.2))
		else animate(out, m, {rot = {{c = sun, axis = tk.RightVector, speed = 0.6 + i * 0.25}, {c = sun, axis = V(0, 1, 0), speed = 0.3}}}) end
	end
	local mi = #out + 1
	table.insert(out, ball(0.06, sun + V(0.36, 0, 0), C(230, 230, 240), M.Neon, {name = "Moon"}))
	out[mi].anim = {rot = {{c = sun, axis = tilt(23, 0).UpVector, speed = 1.4}}}
	return {parts = out, hide = TOME, tip = sun,
		fx = {lights = {{at = sun, color = C(255, 236, 190), range = 10, brightness = 1.6, hue = true}},
			emit = {{at = "Core", def = motes(Color3.new(1, 1, 1), C(255, 220, 140), {{0, 0.05}, {0.5, 0.18}, {1, 0}}, 14, {0.4, 0.9}, {0, 0.05}, nil, 1, {locked = true})},
				{at = BOOK_C, def = motes(Color3.new(1, 1, 1), C(160, 190, 255), {{0, 0.04}, {0.5, 0.08}, {1, 0}}, 10, {1.5, 2.6}, {0.2, 0.6}, nil, 1)}},
			trails = {{part = "Moon", color = Color3.new(1, 1, 1), life = 0.35, width = 0.05}}}}
end

-- CODEX OF STORMS (Legendary): iron-bound slate covers inlaid with copper lightning; over the
-- pages a storm cloud swirls and lightning strikes down onto the pages; runestones circle
D.codexofstorms = function(G, P)
	local out = {}
	tomeCovers(out, P, {mat = M.Slate})
	tomeBorder(out, 0.035, 0.04, P.metal, M.Metal)
	tomeCorners(out, P.metal, M.Metal, 0.14)
	for _, s in ipairs({-1, 1}) do
		local zig = {{0.08, 0.55}, {-0.08, 0.2}, {0.06, 0.12}, {-0.1, -0.25}, {0.04, -0.3}, {-0.06, -0.58}}
		local pts = {}
		for _, z in ipairs(zig) do table.insert(pts, onCover(s, z[1], z[2], 0.008).Position) end
		bend(out, pts, 0.04, C(205, 128, 74), M.Metal)
		bend(out, pts, 0.02, P.blade, M.Neon)
	end
	local cloud = G.o + V(0, 0.18, -0.05)
	local cn = #out + 1
	for k, b in ipairs({{V(0, 0, 0), 0.26}, {V(0.16, -0.03, 0.03), 0.2}, {V(-0.16, -0.02, 0), 0.21}, {V(0.06, 0.08, -0.06), 0.18}, {V(-0.08, 0.06, 0.06), 0.17}, {V(0.25, -0.06, -0.02), 0.13}, {V(-0.26, -0.05, 0.02), 0.13}}) do
		table.insert(out, ball(b[2], cloud + b[1], C(96, 102, 120), M.SmoothPlastic, {transparency = 0.12, name = "Cloud" .. k}))
	end
	animate(out, cn, spin(cloud, V(0, 1, 0), 0.8))
	local n = #out + 1
	table.insert(out, ball(0.11, cloud + V(0, -0.04, 0), P.blade, M.Neon, {name = "Core", SkinPart = "Blade"}))
	out[n].anim = {pulse = {0, 0.6, 11}}
	table.insert(out, ball(0.03, V(-0.28, 0.75, 0.07), P.blade, M.Neon, {name = "StrikeL", transparency = 0.3}))
	table.insert(out, ball(0.03, V(0.3, 0.52, 0.07), P.blade, M.Neon, {name = "StrikeR", transparency = 0.3}))
	local rs = #out + 1
	for k = 0, 3 do
		local a = k / 4 * 2 * PI
		local at = BOOK_C + V(math.cos(a) * 0.78, 0.15, math.sin(a) * 0.78)
		table.insert(out, block(V(0.11, 0.15, 0.06), CFrame.new(at) * CFrame.Angles(0, -a + PI / 2, 0), C(70, 74, 84), M.Slate))
		table.insert(out, block(V(0.05, 0.08, 0.065), CFrame.new(at) * CFrame.Angles(0, -a + PI / 2, 0), P.blade, M.Neon, {name = "Stone" .. k}))
	end
	animate(out, rs, {rot = {{c = BOOK_C, axis = V(0, 1, 0), speed = 0.6}}, bob = {0.05, 1.4, 0}})
	return {parts = out, hide = TOME, tip = cloud,
		fx = {lights = {{at = cloud, color = C(170, 220, 255), range = 10, brightness = 1.5, flicker = true}},
			beams = {{a = "Core", b = "StrikeL", color = C(210, 240, 255), width = 0.06, crackle = true}, {a = "Core", b = "StrikeR", color = C(210, 240, 255), width = 0.05, crackle = true},
				{a = "Cloud2", b = "Cloud3", color = C(170, 220, 255), width = 0.04, crackle = true}},
			emit = {{at = "Core", def = {tex = TEX.smoke, c0 = C(120, 128, 150), c1 = C(60, 64, 80), size = {{0, 0.3}, {1, 0.7}}, rate = 6, life = {0.8, 1.4}, speed = {0.05, 0.2}, spread = 180, light = 0.1, transp = {{0, 0.6}, {1, 1}}, rot = 40}},
				{at = "Core", def = motes(Color3.new(1, 1, 1), C(140, 200, 255), {{0, 0.05}, {1, 0}}, 14, {0.15, 0.35}, {1.5, 3}, nil, 1)}},
			trails = {{part = "Stone0", color = C(150, 210, 255), life = 0.3, width = 0.06}, {part = "Stone2", color = C(150, 210, 255), life = 0.3, width = 0.06}}}}
end

-- THE BURNING BOOK (Mythic): obsidian covers split by lava; two great wings of fire unfold
-- from the spine and beat; its pages of flame turn by themselves; over them a burning sigil,
-- two rings counter-turning round a molten heart; a storm of embers
D.burningbook = function(G, P)
	local out = {}
	local lava = C(255, 110, 20)
	tomeCovers(out, P, {mat = M.Basalt, color = C(30, 14, 12)})
	for _, s in ipairs({-1, 1}) do
		local nrm = outward(s)
		for c = 0, 3 do
			local pts, x, y = {}, -0.25 + c * 0.16, 0.66
			for i = 0, 6 do
				table.insert(pts, onCover(s, x, y, 0.004).Position)
				x += ((i + c) % 2 == 0 and 0.05 or -0.06); y -= 0.19
			end
			bend(out, pts, 0.024, lava, M.Neon)
		end
		for _, x in ipairs({-0.3, 0.3}) do for _, y in ipairs({-0.68, 0.68}) do
			flatThorn(out, onCover(s, x, y, 0.01).Position, nrm, coverCF(s):VectorToWorldSpace(V(s * x, y * 1.3, 0)) - nrm * 0.4, 0.22, 0.09, 0.05, C(24, 20, 20), M.Basalt)
		end end
	end
	-- the pages: fire, two of them turning over and back
	for _, s in ipairs({-1, 1}) do
		table.insert(out, block(V(0.6, 1.26, 0.1), CFrame.new(s * 0.31, 0.66, 0.0) * CFrame.Angles(0, math.rad(s * -8), 0), C(255, 170, 70), M.Neon, {transparency = 0.15}))
	end
	for k = 0, 1 do
		local pi = #out + 1
		table.insert(out, block(V(0.56, 1.18, 0.01), CFrame.new(0.3, 0.66, 0.08 + k * 0.01), C(255, 200, 90), M.Neon, {transparency = 0.25, name = "Flip" .. k}))
		out[pi].anim = {osc = {c = V(0, 0.66, 0.06), axis = V(0, 1, 0), amp = 1.45, speed = 1.2 + k * 0.5}}
	end
	-- the wings, from the spine
	for _, s in ipairs({-1, 1}) do
		local root = V(s * 0.05, 0.9, -0.14)
		local w0 = #out + 1
		local tips = {V(s * 1.0, 1.65, -0.7), V(s * 1.15, 1.2, -0.65), V(s * 1.05, 0.75, -0.6), V(s * 0.85, 0.35, -0.5)}
		for i = 1, #tips - 1 do
			tri(out, root, tips[i], tips[i + 1], 0.03, i % 2 == 1 and C(255, 120, 30) or C(255, 180, 60), M.Neon, {transparency = 0.1})
		end
		bend(out, {root, root + V(s * 0.4, 0.5, -0.3), tips[1]}, 0.05, C(255, 210, 120), M.Neon)
		animate(out, w0, {osc = {c = root, axis = V(0, 1, 0), amp = 0.35 * s, speed = 2.6}})
	end
	-- the sigil
	local r1 = #out + 1
	ring(out, G.o, CFrame.Angles(PI / 2, 0, 0), 0.28, 18, 0.025, lava, M.Neon)
	for k = 0, 9 do
		local a = k / 10 * 2 * PI
		local d = V(math.sin(a), math.cos(a), 0)
		thorn(out, CFrame.fromMatrix(G.o + d * 0.28, V(0, 0, 1), d), 0.14, 0.07, 0.02, C(255, 160, 40), M.Neon)
	end
	animate(out, r1, spin(G.o, V(0, 0, 1), 1.1))
	local r2 = #out + 1
	ring(out, G.o, CFrame.Angles(PI / 2, 0, 0), 0.2, 14, 0.018, C(255, 220, 120), M.Neon)
	star(out, CFrame.new(G.o), 5, 0.17, 0.06, 0.012, C(255, 200, 80), M.Neon)
	animate(out, r2, spin(G.o, V(0, 0, 1), -1.7))
	local n = #out + 1
	table.insert(out, ball(0.14, G.o, C(255, 240, 200), M.Neon, {name = "Core", SkinPart = "Blade"}))
	table.insert(out, ball(0.22, G.o, lava, M.Neon, {transparency = 0.6}))
	out[n + 1].anim = {pulse = {0.45, 0.8, 4}}
	return {parts = out, hide = TOME_PAGES, tip = G.o,
		fx = {lights = {{at = G.o, color = C(255, 130, 40), range = 12, brightness = 2, flicker = true}},
			emit = {{at = V(0, 0.66, 0.1), def = {tex = TEX.fire, c0 = C(255, 200, 90), c1 = C(220, 40, 10), size = {{0, 0.4}, {0.5, 0.3}, {1, 0.05}}, rate = 26, life = {0.3, 0.6}, speed = {0.4, 1}, accel = V(0, 5, 0), spread = 30, light = 1, transp = {{0, 0.25}, {1, 1}}}},
				{at = "Core", def = motes(C(255, 230, 130), C(255, 60, 10), {{0, 0.07}, {1, 0}}, 26, {0.6, 1.4}, {0.6, 2}, V(0, 5, 0), 1, {spread = 90})},
				{at = V(0, 1.2, -0.3), def = {tex = TEX.smoke, c0 = C(80, 40, 30), size = {{0, 0.4}, {1, 1.2}}, rate = 4, life = {1, 1.6}, speed = {0.3, 0.6}, accel = V(0, 1.5, 0), spread = 40, light = 0, transp = {{0, 0.75}, {1, 1}}, rot = 30}}},
			trails = {{part = "Flip0", color = C(255, 180, 60), life = 0.2, width = 0.3}}}}
end

StaffHeads.DESIGNS = D

-- a design for this skin? (skin.head on a Staff skin)
function StaffHeads.has(skin)
	return skin ~= nil and skin.head ~= nil and D[skin.head] ~= nil
end

function StaffHeads.design(skin, G)
	local fn = skin and skin.head and D[skin.head]
	if not (fn and G) then return nil end
	local P = {blade = skin.blade or C(140, 200, 255), grip = skin.grip or C(92, 62, 36), metal = skin.metal or skin.accent, glow = skin.glow}
	local ok, res = pcall(fn, G, P)
	if not ok then warn("[StaffHeads]", skin.head, res); return nil end
	return res
end

-- the effects (SkinFX ▸ apply calls this with its emitter maker): lights, particles, beams,
-- trails on the head's parts; everything tagged SkinFX so SkinFX.clear takes it away
function StaffHeads.fx(tool, skin, makeEmitter)
	local G = StaffHeads.frame(tool)
	local d = G and StaffHeads.design(skin, G)
	local handle = G and G.handle
	local trim = tool:FindFirstChild("Trim")
	if not (d and d.fx and handle) then return false end
	local function partNamed(name) return trim and trim:FindFirstChild(name) end
	local function mark(x) x:SetAttribute("SkinFX", true); return x end
	local function attachAt(where, name)
		local a = Instance.new("Attachment")
		a.Name = name
		mark(a)
		if typeof(where) == "Vector3" then a.Position = where; a.Parent = handle
		else
			local p = partNamed(where)
			if not p then return nil end
			a.Parent = p
		end
		return a
	end
	for i, l in ipairs(d.fx.lights or {}) do
		local a = attachAt(l.at, "HeadLightAt" .. i)
		if a then
			local pl = mark(Instance.new("PointLight"))
			pl.Name = "HeadLight"
			pl.Color, pl.Range, pl.Brightness, pl.Shadows = l.color, l.range, l.brightness, false
			pl:SetAttribute("BaseBrightness", l.brightness)
			if l.flicker then pl:SetAttribute("Flicker", true) end
			if l.pulse then pl:SetAttribute("Pulse", l.pulse) end
			if l.hue then pl:SetAttribute("Hue", true) end
			pl.Parent = a
		end
	end
	for i, e in ipairs(d.fx.emit or {}) do
		local host = typeof(e.at) == "Vector3" and attachAt(e.at, "HeadEmitAt" .. i) or partNamed(e.at)
		if host then
			local pe = makeEmitter(e.def, "HeadAura" .. i)
			if e.def.inward then
				-- (drawn in: from the surface of a big unseen ball toward its middle)
				pe.Shape = Enum.ParticleEmitterShape.Sphere
				pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
				pe.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
			end
			pe.Parent = host
		end
	end
	for i, b in ipairs(d.fx.beams or {}) do
		local a0, a1 = attachAt(b.a, "HeadBeamA" .. i), attachAt(b.b, "HeadBeamB" .. i)
		if a0 and a1 then
			local bm = mark(Instance.new("Beam"))
			bm.Name = "HeadBeam"
			bm.Attachment0, bm.Attachment1 = a0, a1
			bm.Color = ColorSequence.new(b.color)
			bm.Width0, bm.Width1 = b.width, b.width
			bm.LightEmission, bm.LightInfluence = 1, 0
			bm.FaceCamera = true
			bm.Transparency = NumberSequence.new(b.faint and 0.65 or 0.1)
			bm.Segments = b.crackle and 8 or 1
			if b.crackle then bm:SetAttribute("Crackle", true); bm.Texture = TEX.spark; bm.TextureSpeed = 3 end
			bm.Parent = handle
		end
	end
	for i, t in ipairs(d.fx.trails or {}) do
		local p = partNamed(t.part)
		if p then
			local w = (t.width or 0.1) / 2
			local a0 = mark(Instance.new("Attachment")); a0.Name = "HeadTrailA"; a0.Position = V(0, w, 0); a0.Parent = p
			local a1 = mark(Instance.new("Attachment")); a1.Name = "HeadTrailB"; a1.Position = V(0, -w, 0); a1.Parent = p
			local tr = mark(Instance.new("Trail"))
			tr.Name = "HeadTrail"
			tr.Attachment0, tr.Attachment1 = a0, a1
			tr.Color = ColorSequence.new(t.color)
			tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
			tr.Lifetime = t.life or 0.4
			tr.LightEmission, tr.LightInfluence = 1, 0
			tr.FaceCamera = true
			tr.MinLength = 0.02
			tr.Parent = p
		end
	end
	return true
end

return StaffHeads
