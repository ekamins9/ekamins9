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
	table.insert(out, egg(V(0.52, 0.44, 0.6), CFrame.new(s + V(0, 0.08, 0.08)), bone, M.SmoothPlastic, {name = "Skull"}))
	table.insert(out, egg(V(0.34, 0.26, 0.62), CFrame.new(s + V(0, 0.1, -0.38)), bone, M.SmoothPlastic))
	table.insert(out, egg(V(0.3, 0.12, 0.56), CFrame.new(s + V(0, -0.2, -0.32)) * CFrame.Angles(math.rad(-14), 0, 0), bone, M.SmoothPlastic))
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
		for j = 0, 2 do
			local tip = base + V(x * (0.7 + j * 0.15), 0.55 - j * 0.35, 0.25)
			table.insert(out, rod(base, tip, 0.05, bone, M.SmoothPlastic))
			table.insert(out, ball(0.07, tip, bone, M.SmoothPlastic))
			if j < 2 then
				local nxt = base + V(x * (0.85 + j * 0.15), 0.2 - j * 0.35, 0.25)
				local mid = (base + tip + nxt) / 3
				table.insert(out, block(V(0.02, (tip - nxt).Magnitude * 0.9, (mid - base).Magnitude * 1.6), along(mid, tip - nxt) * CFrame.Angles(0, PI / 2, 0), C(150, 40, 30), M.SmoothPlastic, {transparency = 0.25}))
			end
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
