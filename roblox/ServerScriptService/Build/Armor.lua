--[[ ARMOR SET BLUEPRINTS — the clothing models of the twelve release sets
     (RELEASE_CONTENT.md), the three starter sets, and the nine earned pieces.
     They are the source of the armor meshes (these specs →
     scripts/export_blueprints.lua → blender/parts2mesh.py → uploaded meshes →
     Build ▸ MeshArmor; blender/preview_armor.py renders them first) and the
     fallback wherever no model exists. A set = {HeadClothing = specs,
     TorsoClothing = specs, LeftArmClothing = …, RightArmClothing = …,
     LeftLegClothing = …, RightLegClothing = …}; any slot may be missing. Every
     spec list sits in the LIMB'S frame: a part named Middle the size of the
     limb at the origin (Dresser welds Middle onto the limb and keeps every
     other part's offset).

     Every set has its own silhouette: a helm you can name from across the
     field, its own shoulders, hands, knees and feet. No two helms share a shape.

     Color blocks: attrs = {ColorSlot = "Primary" | "Secondary" | "Accent" | "Metal"}
     take the player's colors (Primary = team color in team modes). Parts
     without ColorSlot keep their own color (leather, mail, horn, fur, feathers).

     Limb sizes (R6): the visible head is a round drum 1.25 across with rounded
     rims (face at z = -0.625, crown at y = +0.625, shoulders at y = -0.5), so
     closed helms are a drum round it with a dome over; Torso 2×2×1 and arms /
     legs 1×2×1 are boxes, so whatever wraps them is a rounded box (an oval would
     leave their corners poking out). Shoulder / hip at +1, hand / foot at -1.
     Front is -Z. Limb builders take s = -1 (left) or 1 (right): the side the
     limb's outer face looks to. ]]

local B = require(script.Parent:WaitForChild("Builder"))
local C, M = B.C, B.M
local cf, v = B.cf, B.v
local P, S, A, MT = {ColorSlot = "Primary"}, {ColorSlot = "Secondary"}, {ColorSlot = "Accent"}, {ColorSlot = "Metal"}
local X, Y, Z = Vector3.xAxis, Vector3.yAxis, Vector3.zAxis
local BONE    = Color3.fromRGB(216, 204, 176)
local BLOOD   = Color3.fromRGB(104, 20, 18)
local FEATHER = Color3.fromRGB(30, 30, 36)
local FANG    = Color3.fromRGB(236, 230, 212)
local AMBER   = Color3.fromRGB(222, 150, 44)
local HORN    = Color3.fromRGB(176, 136, 86)
local STRAW2  = Color3.fromRGB(170, 140, 80)
local SAILCLOTH = Color3.fromRGB(120, 98, 72)
local PATCH   = Color3.fromRGB(168, 150, 116)

local A_ = {}
local HEAD, TORSO, LIMB = v(2, 1, 1), v(2, 2, 1), v(1, 2, 1)

--------------------------------------------------------------------
--  SHAPES
--------------------------------------------------------------------
local box, egg, ball, cyl, torus = B.box, B.egg, B.ball, B.cyl, B.torus
local function middle(size) return box("Middle", size, cf(), C.WHITE, M.PLASTIC, nil, {transparency = 1, shadow = false}) end
local function J(...) return B.join({}, ...) end
local function pair(fn) return fn(-1), fn(1) end
-- a box with rounded edges
local function rbox(name, size, frame, color, mat, attrs, bevel)
	return box(name, size, frame, color, mat, attrs, {bevel = bevel or 0.18})
end
-- a rounded box whose top face is `top` × its bottom's width and depth (a skirt, a fauld, a flared cuff)
local function tbox(name, size, frame, top, color, mat, attrs, bevel)
	return box(name, size, frame, color, mat, attrs, {bevel = bevel or 0.18, top = top})
end
-- a cone along its Y (frame = its middle); top = the top's share of the foot's width (0 = a point)
local function cone(name, size, frame, color, mat, attrs, top)
	return {kind = "cone", name = name, size = size, cf = frame, color = color, material = mat, attrs = attrs, top = top or 0}
end
-- an upright drum rx × rz round (0, zc) from y0 to y1
local function drum(name, rx, rz, y0, y1, zc, color, mat, attrs)
	return {kind = "cyl", name = name, size = v(rx * 2, y1 - y0, rz * 2), cf = cf(0, (y0 + y1) / 2, zc or 0), color = color, material = mat, attrs = attrs}
end
-- the frame halfway from a to b with its Y axis running a → b, and the length
local function span(a, b)
	local d = b - a
	local up = math.abs(d.Unit.Y) > 0.98 and Z or Y
	return CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(-math.pi / 2, 0, 0), d.Magnitude
end
local function rod(name, a, b, d, color, mat, attrs)
	local frame, len = span(a, b)
	return cyl(name, d, len, frame, color, mat, attrs)
end
local function spike(name, a, b, d, color, mat, attrs)   -- a cone from its foot a to its point b
	local frame, len = span(a, b)
	return cone(name, v(d, len, d), frame, color, mat, attrs)
end
-- a tube through points (closed: back to the first)
local function tube(name, pts, d, color, mat, attrs, closed)
	local out = {}
	local n = #pts
	for i = 1, closed and n or n - 1 do
		local a, b = pts[i], pts[i % n + 1]
		out[#out + 1] = rod(name, a, b, d, color, mat, attrs)
		out[#out + 1] = ball(name, d, CFrame.new(b), color, mat, attrs)
	end
	return out
end
-- a flat plate seen edge-on: its outer face runs from p down to q, w wide along
-- `across` (default X: a plate facing front) and d thick behind the face
local function plate(name, p, q, w, d, color, mat, attrs, across, bevel)
	local up = (p - q).Unit
	local back = (across or X):Cross(up).Unit
	local frame = CFrame.fromMatrix((p + q) / 2 + back * (d / 2), up:Cross(back), up, back)
	return box(name, v(w, (p - q).Magnitude, d), frame, color, mat, attrs, bevel and {bevel = bevel} or nil)
end
-- a line round a rounded box (w × d, its edges rounded by b) at height y, on its four faces
local function hoop(name, w, d, b, y, t, color, mat, attrs, zc)
	zc = zc or 0
	return {
		box(name, v(w - 2 * b, t, 0.04), cf(0, y, zc - d / 2 - 0.01), color, mat, attrs),
		box(name, v(w - 2 * b, t, 0.04), cf(0, y, zc + d / 2 + 0.01), color, mat, attrs),
		box(name, v(0.04, t, d - 2 * b), cf(-w / 2 - 0.01, y, zc), color, mat, attrs),
		box(name, v(0.04, t, d - 2 * b), cf(w / 2 + 0.01, y, zc), color, mat, attrs),
	}
end

--------------------------------------------------------------------
--  ON SURFACES — an egg kept as data (e = {c = centre, s = size}) so trim,
--  slits, studs and emblems can be laid on it and follow its curve
--------------------------------------------------------------------
local function shell(name, e, color, mat, attrs) return egg(name, e.s, CFrame.new(e.c), color, mat, attrs) end
local function normal(e, p)
	local a, b, c = e.s.X / 2, e.s.Y / 2, e.s.Z / 2
	local d = p - e.c
	return Vector3.new(d.X / (a * a), d.Y / (b * b), d.Z / (c * c)).Unit
end
-- the surface point in front of (x, y) (behind it with back = true) and its outward normal
local function front(e, x, y, back)
	local a, b, c = e.s.X / 2, e.s.Y / 2, e.s.Z / 2
	local u, w = (x - e.c.X) / a, (y - e.c.Y) / b
	local p = Vector3.new(x, y, e.c.Z + (back and c or -c) * math.sqrt(math.max(0, 1 - u * u - w * w)))
	return p, normal(e, p)
end
-- the surface point at height y, `yaw` radians round from the front (+ toward +X)
local function around(e, yaw, y)
	local a, b, c = e.s.X / 2, e.s.Y / 2, e.s.Z / 2
	local w = (y - e.c.Y) / b
	local k = math.sqrt(math.max(0, 1 - w * w))
	local p = Vector3.new(e.c.X + a * k * math.sin(yaw), y, e.c.Z - c * k * math.cos(yaw))
	return p, normal(e, p)
end
-- the same on a drum (rx × rz round (0, zc))
local function onDrum(rx, rz, zc, yaw, y)
	return Vector3.new(rx * math.sin(yaw), y, zc - rz * math.cos(yaw)), Vector3.new(math.sin(yaw) / rx, 0, -math.cos(yaw) / rz).Unit
end
-- lay a spec flat on the surface at p (outward normal n): its -Z face looks out, `out` proud
local function lay(spec, p, n, out, spin)
	local up = math.abs(n.Y) > 0.95 and -Z or Y
	spec.cf = CFrame.lookAt(p, p + n, up) * CFrame.Angles(0, 0, math.rad(spin or 0)) * CFrame.new(0, 0, spec.size.Z / 2 - (out or 0.02))
	return spec
end
local function disc(name, p, n, d, t, color, mat, attrs, out)   -- a disc lying face-out on the surface
	local up = math.abs(n.Y) > 0.95 and -Z or Y
	return cyl(name, d, t, CFrame.lookAt(p, p + n, up) * CFrame.new(0, 0, t / 2 - (out or t * 0.6)) * CFrame.Angles(math.pi / 2, 0, 0), color, mat, attrs)
end
local function stud(name, p, n, d, color, mat, attrs) return ball(name, d, CFrame.new(p + n * (d * 0.15)), color, mat, attrs) end
-- a band laid across an egg at height y from x0 to x1, in short pieces that follow the curve
local function row(name, e, y, x0, x1, h, color, mat, attrs, out)
	local n = math.max(2, math.ceil(math.abs(x1 - x0) / 0.13))
	local w = (x1 - x0) / n
	local list = {}
	for i = 0, n - 1 do
		local p, nn = front(e, x0 + w * (i + 0.5), y)
		list[#list + 1] = lay(box(name, v(math.abs(w) + 0.03, h, 0.08), nil, color, mat, attrs), p, nn, out or 0.015)
	end
	return list
end
-- the same running down an egg at x, from y0 to y1
local function column(name, e, x, y0, y1, w, color, mat, attrs, out)
	local n = math.max(2, math.ceil(math.abs(y1 - y0) / 0.13))
	local h = (y1 - y0) / n
	local list = {}
	for i = 0, n - 1 do
		local p, nn = front(e, x, y0 + h * (i + 0.5))
		list[#list + 1] = lay(box(name, v(w, math.abs(h) + 0.03, 0.08), nil, color, mat, attrs), p, nn, out or 0.015)
	end
	return list
end
-- a band laid round a drum at height y from yaw0 to yaw1 (degrees)
local function drumBand(name, rx, rz, zc, y, yaw0, yaw1, h, color, mat, attrs, out)
	local n = math.max(2, math.ceil(math.abs(yaw1 - yaw0) / 10))
	local step = (yaw1 - yaw0) / n
	local list = {}
	for i = 0, n - 1 do
		local p, nn = onDrum(rx, rz, zc, math.rad(yaw0 + step * (i + 0.5)), y)
		list[#list + 1] = lay(box(name, v(math.rad(math.abs(step)) * math.max(rx, rz) + 0.03, h, 0.08), nil, color, mat, attrs), p, nn, out or 0.015)
	end
	return list
end
-- n studs in a row across an egg at height y
local function studs(name, e, y, x0, x1, n, d, color, mat, attrs)
	local list = {}
	for i = 0, n - 1 do
		local p, nn = front(e, n == 1 and (x0 + x1) / 2 or x0 + (x1 - x0) * i / (n - 1), y)
		list[#list + 1] = stud(name, p, nn, d, color, mat, attrs)
	end
	return list
end
-- n studs round an egg at height y, from yaw0 to yaw1 (degrees)
local function studsRound(name, e, y, yaw0, yaw1, n, d, color, mat, attrs)
	local list = {}
	for i = 0, n - 1 do
		local p, nn = around(e, math.rad(yaw0 + (yaw1 - yaw0) * i / math.max(1, n - 1)), y)
		list[#list + 1] = stud(name, p, nn, d, color, mat, attrs)
	end
	return list
end
-- a closed helm's shell: a drum round the head from `bottom` up to `top`, a dome `dome` high over it.
-- Returns the specs and the dome (as an egg, to lay things on)
local function helmShell(rx, rz, zc, bottom, top, dome, color, mat, attrs)
	local d = {c = v(0, top, zc), s = v(rx * 2, dome * 2, rz * 2)}
	return {drum("Helm", rx, rz, bottom, top, zc, color, mat, attrs), shell("Dome", d, color, mat, attrs)}, d
end
-- the edge of a face opening (an oval rx × ry round y = yc), lying on the head and on the
-- shells round it, lifted `lift` off them: the points of a rolled hem or a binding
local function faceLoop(rx, ry, yc, shells, lift, n)
	n = n or 18
	local pts = {}
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		local x, y = rx * math.cos(a), yc + ry * math.sin(a)
		local z = -math.sqrt(math.max(0, 0.625 * 0.625 - x * x))
		for _, e in ipairs(shells) do
			local u, w = (x - e.c.X) / (e.s.X / 2), (y - e.c.Y) / (e.s.Y / 2)
			if u * u + w * w < 1 then z = math.min(z, (front(e, x, y)).Z) end
		end
		pts[#pts + 1] = Vector3.new(x, y, z - lift)
	end
	return pts
end

--------------------------------------------------------------------
--  HELMS AND HATS (head frame)
--------------------------------------------------------------------
-- Tourney Knight: the frog-mouthed jousting helm; its crest a twisted wreath, plumes and mantling
local function frogMouth()
	local m = C.STEEL
	local out = {middle(HEAD)}
	local sh = helmShell(0.74, 0.76, 0.1, -0.6, 0.3, 0.5, m, M.METAL, MT)
	B.join(out, sh, {
		-- the upper plate slopes forward to the sight; the lower juts out under it like a frog's jaw
		plate("Brow", v(0, 0.62, -0.5), v(0, 0.23, -1.0), 1.42, 0.64, m, M.METAL, MT, nil, 0.05),
		plate("Jaw", v(0, 0.14, -1.0), v(0, -0.62, -0.62), 1.4, 0.9, m, M.METAL, MT, nil, 0.05),
		plate("Keel", v(0, 0.12, -1.035), v(0, -0.6, -0.655), 0.08, 0.06, m, M.METAL, MT),
		box("Sight", v(1.28, 0.14, 0.3), cf(0, 0.185, -0.84), C.BLACK, M.PLASTIC),
		torus("Rim", v(1.56, 0.1, 1.6), cf(0, -0.56, 0.1), m, M.METAL, MT),
		egg("Plume", v(0.32, 0.95, 0.44), cf(0, 1.2, 0.22, 16, 0, 0), C.CLOTH, M.FABRIC, P),
		egg("Plume", v(0.28, 0.8, 0.4), cf(0, 1.44, 0.6, 52, 0, 0), C.CLOTH, M.FABRIC, P),
		egg("Plume", v(0.24, 0.62, 0.34), cf(0, 1.32, 0.98, 100, 0, 0), C.CLOTH, M.FABRIC, P),
		egg("Feather", v(0.2, 0.78, 0.3), cf(-0.24, 1.16, 0.32, 28, 0, 24), C.WHITE, M.FABRIC),
		egg("Feather", v(0.2, 0.78, 0.3), cf(0.24, 1.16, 0.32, 28, 0, -24), C.WHITE, M.FABRIC),
		plate("Mantling", v(0, 0.75, 0.44), v(0, -0.3, 1.0), 1.16, 0.06, C.CLOTH, M.FABRIC, P, -X),
		plate("Mantling", v(0, 0.7, 0.5), v(0, -0.36, 1.06), 0.8, 0.05, C.CLOTH2, M.FABRIC, S, -X),
	})
	for i = 0, 9 do   -- the wreath, twisted in two colors
		local a = i / 10 * math.pi * 2
		local first = i % 2 == 0
		out[#out + 1] = egg("Torse", v(0.24, 0.2, 0.36), CFrame.new(math.cos(a) * 0.46, 0.7, 0.1 + math.sin(a) * 0.48)
			* CFrame.Angles(0, -a, 0) * CFrame.Angles(math.rad(first and 28 or -28), 0, 0), first and C.CLOTH or C.GOLD, M.FABRIC, first and P or A)
	end
	for i = -2, 2 do out[#out + 1] = ball("Rivet", 0.09, cf(i * 0.27, 0.06, -0.975), C.BRASS, M.METAL, A) end
	return out
end

-- the Champion's sugarloaf: a tall round great helm drawn up to a point, a gilded cross and a crown
local function sugarloaf()
	local m, g = C.STEEL, C.GOLD
	local out = {middle(HEAD),
		cone("Helm", v(1.54, 1.12, 1.56), cf(0, -0.02, 0.02), m, M.METAL, MT, 0.88),
		cone("Loaf", v(1.36, 0.66, 1.38), cf(0, 0.87, 0.02), m, M.METAL, MT),
		torus("Hem", v(1.6, 0.08, 1.62), cf(0, -0.56, 0.02), g, M.METAL, A),
		torus("Circlet", v(1.44, 0.12, 1.46), cf(0, 0.55, 0.02), g, M.METAL, A),
		ball("Finial", 0.2, cf(0, 1.2, 0.02), g, M.METAL, A),
		plate("Cross", v(0, 0.5, -0.705), v(0, -0.52, -0.79), 0.16, 0.06, g, M.METAL, A),
	}
	local function at(yaw, y)   -- on the helm's tapering side
		local t = (y + 0.58) / 1.12
		local rx, rz = 0.77 - t * 0.092, 0.78 - t * 0.094
		local p = Vector3.new(rx * math.sin(yaw), y, 0.02 - rz * math.cos(yaw))
		return p, Vector3.new(math.sin(yaw) / rx, 0, -math.cos(yaw) / rz).Unit
	end
	for i = -3, 3 do   -- the cross's arm along the brow
		local p, n = at(math.rad(i * 12), 0.34)
		out[#out + 1] = lay(box("Cross", v(0.17, 0.15, 0.08), nil, g, M.METAL, A), p, n, 0.035)
	end
	for _, s in ipairs({-1, 1}) do   -- the sights, either side of the cross
		for i = 1, 3 do
			local p, n = at(math.rad(s * (3 + i * 10)), 0.19)
			out[#out + 1] = lay(box("Sight", v(0.15, 0.075, 0.08), nil, C.BLACK, M.PLASTIC), p, n, 0.012)
		end
	end
	for r = 0, 2 do for c2 = 0, 2 do   -- breaths on the right cheek
		local p, n = at(math.rad(28 + c2 * 11), -0.08 - r * 0.15)
		out[#out + 1] = disc("Breath", p, n, 0.08, 0.04, C.BLACK, M.PLASTIC, nil, 0.008)
	end end
	for i = 0, 7 do   -- the crown's points, a pearl on each
		local a = i / 8 * math.pi * 2
		local foot = Vector3.new(math.sin(a) * 0.66, 0.6, 0.02 - math.cos(a) * 0.67)
		local tip = foot + Vector3.new(math.sin(a) * 0.05, 0.3, -math.cos(a) * 0.05)
		out[#out + 1] = spike("Fleur", foot, tip, 0.16, g, M.METAL, A)
		out[#out + 1] = ball("Pearl", 0.09, CFrame.new(tip), C.WHITE, M.PLASTIC)
	end
	for i = 0, 11 do   -- rivets round the hem
		local a = i / 12 * math.pi * 2
		out[#out + 1] = ball("Rivet", 0.08, CFrame.new(math.sin(a) * 0.79, -0.45, 0.02 - math.cos(a) * 0.8), g, M.METAL, A)
	end
	return out
end

-- the Blackguard: a flat-topped great helm, horned, spikes along the crown, a red-trimmed face
local function hornedHelm()
	local m, t = C.BLACKIRON, C.RED
	local out = {middle(HEAD),
		cyl("Helm", 1.5, 1.2, cf(0, 0.02, 0.02), m, M.METAL, MT),
		egg("Top", v(1.5, 0.34, 1.5), cf(0, 0.62, 0.02), m, M.METAL, MT),
		torus("Band", v(1.56, 0.1, 1.56), cf(0, -0.5, 0.02), t, M.METAL, A),
		torus("Band", v(1.54, 0.08, 1.54), cf(0, 0.58, 0.02), t, M.METAL, A),
		plate("Nasal", v(0, 0.3, -0.765), v(0, -0.48, -0.765), 0.16, 0.06, t, M.METAL, A),
	}
	local function at(yaw, y) return onDrum(0.75, 0.75, 0.02, yaw, y) end
	for i = -4, 4 do   -- one sight across the face, a brow over it
		local p, n = at(math.rad(i * 9), 0.24)
		out[#out + 1] = lay(box("Sight", v(0.13, 0.09, 0.08), nil, C.BLACK, M.PLASTIC), p, n, 0.01)
		local q, nq = at(math.rad(i * 9), 0.35)
		out[#out + 1] = lay(box("Brow", v(0.13, 0.11, 0.08), nil, t, M.METAL, A), q, nq, 0.03)
	end
	for _, s in ipairs({-1, 1}) do
		for r = 0, 3 do   -- breaths either side of the nasal
			for _, yaw in ipairs({16, 27}) do
				local p, n = at(math.rad(s * yaw), 0.04 - r * 0.15)
				out[#out + 1] = disc("Breath", p, n, 0.08, 0.04, C.BLACK, M.PLASTIC, nil, 0.008)
			end
		end
		-- the horns: out from the temples, up, and in to a point
		local a, b = Vector3.new(s * 0.66, 0.42, 0.04), Vector3.new(s * 1.02, 0.56, 0.02)
		local c, d = Vector3.new(s * 1.22, 0.86, 0.04), Vector3.new(s * 1.2, 1.26, 0.16)
		out[#out + 1] = rod("Horn", a, b, 0.32, BONE, M.PLASTIC)
		out[#out + 1] = ball("Horn", 0.3, CFrame.new(b), BONE, M.PLASTIC)
		out[#out + 1] = rod("Horn", b, c, 0.27, BONE, M.PLASTIC)
		out[#out + 1] = ball("Horn", 0.26, CFrame.new(c), BONE, M.PLASTIC)
		out[#out + 1] = spike("Horn", c, d, 0.26, BONE, M.PLASTIC)
		local f, len = span(a, b)
		out[#out + 1] = torus("HornRing", v(0.42, 0.08, 0.42), f * CFrame.new(0, -len / 2 + 0.12, 0), t, M.METAL, A)
	end
	for i = -1, 1 do
		out[#out + 1] = spike("Spike", Vector3.new(0, 0.72, 0.02 + i * 0.42), Vector3.new(0, 1.02, 0.02 + i * 0.42), 0.17, m, M.METAL, MT)
	end
	return out
end

-- the Iron Crow: a hounskull — a bascinet with a long beak of a visor, crow feathers behind
local function hounskull()
	local m = C.BLACKIRON
	local out = {middle(HEAD)}
	local sh, dome = helmShell(0.73, 0.76, 0.08, -0.5, 0.25, 0.62, m, M.METAL, MT)
	local L = 0.95
	local foot = CFrame.new(0, -0.02, -0.34) * CFrame.Angles(-math.pi / 2, 0, 0)   -- the beak's foot: its Y runs forward, its Z up
	B.join(out, sh, {
		cone("Apex", v(0.6, 0.42, 0.64), cf(0, 0.92, 0.2, 16, 0, 0), m, M.METAL, MT),
		cone("Beak", v(1.38, L, 1.16), foot * CFrame.new(0, L / 2, 0), m, M.METAL, MT),
		cone("Aventail", v(1.86, 0.5, 1.88), cf(0, -0.42, 0.1), C.MAIL, M.PLATE, nil, 0.84),
	}, row("Sight", dome, 0.42, -0.48, -0.08, 0.075, C.BLACK, M.PLASTIC, nil, 0.01),
		row("Sight", dome, 0.42, 0.08, 0.48, 0.075, C.BLACK, M.PLASTIC, nil, 0.01),
		row("Brow", dome, 0.53, -0.5, 0.5, 0.09, m, M.METAL, MT, 0.035))
	for _, s in ipairs({-1, 1}) do
		local p, n = onDrum(0.73, 0.76, 0.08, math.rad(s * 72), 0.16)
		out[#out + 1] = disc("Pivot", p, n, 0.26, 0.06, C.IRON, M.METAL, nil, 0.04)
		for i = 0, 2 do   -- breaths down the beak's flanks
			local t = 0.24 + i * 0.13
			local k = 1 - t / L
			local al = math.rad(110)
			local loc = Vector3.new(s * math.sin(al) * 0.69 * k, t, math.cos(al) * 0.58 * k)
			local nl = Vector3.new(s * math.sin(al) / 0.69, 0.55, math.cos(al) / 0.58).Unit
			out[#out + 1] = disc("Breath", (foot * CFrame.new(loc)).Position, foot:VectorToWorldSpace(nl), 0.08, 0.04, C.BLACK, M.PLASTIC, nil, 0.012)
		end
	end
	for i = -1, 1 do   -- crow feathers rising behind
		out[#out + 1] = egg("Feather", v(0.16, 0.82, 0.3), cf(i * 0.16, 0.92, 0.66, 38, 0, -i * 14), FEATHER, M.FABRIC)
	end
	return out
end

-- the Knights of the Sun: a round armet under a crown of gilded rays, long and short
local function sunArmet()
	local m, g = C.BRIGHT, C.GOLD
	local out = {middle(HEAD)}
	local sh = helmShell(0.73, 0.76, 0.06, -0.56, 0.24, 0.62, m, M.METAL, MT)
	local visor = {c = v(0, -0.02, -0.34), s = v(1.38, 1.08, 1.0)}
	B.join(out, sh, {
		shell("Visor", visor, m, M.METAL, MT),
		egg("Comb", v(0.08, 0.3, 1.26), cf(0, 0.84, 0.06), m, M.METAL, MT),
		torus("Circlet", v(1.06, 0.11, 1.1), cf(0, 0.7, 0.06), g, M.METAL, A),
		torus("Gorget", v(1.56, 0.1, 1.6), cf(0, -0.54, 0.06), g, M.METAL, A),
		rod("RondelStem", v(0, -0.16, 0.7), v(0, -0.16, 0.9), 0.1, m, M.METAL, MT),
		cyl("Rondel", 0.46, 0.06, cf(0, -0.16, 0.92, 90, 0, 0), g, M.METAL, A),
	}, row("Sight", visor, 0.24, -0.44, -0.06, 0.07, C.BLACK, M.PLASTIC, nil, 0.012),
		row("Sight", visor, 0.24, 0.06, 0.44, 0.07, C.BLACK, M.PLASTIC, nil, 0.012),
		studs("Rivet", visor, -0.3, -0.32, 0.32, 5, 0.07, g, M.METAL, A))
	for r = 0, 2 do for c2 = -1, 1 do   -- breaths fanned below the sight
		local p, n = front(visor, c2 * 0.16, 0.04 - r * 0.11)
		out[#out + 1] = disc("Breath", p, n, 0.07, 0.04, C.BLACK, M.PLASTIC, nil, 0.008)
	end end
	for i = 0, 13 do   -- the sun
		local a = i / 14 * math.pi * 2
		local long = i % 2 == 0
		local base = Vector3.new(math.cos(a) * 0.5, 0.72, 0.06 + math.sin(a) * 0.52)
		local dir = Vector3.new(math.cos(a) * 0.62, 1, math.sin(a) * 0.62).Unit
		out[#out + 1] = spike("Ray", base, base + dir * (long and 0.66 or 0.4), long and 0.16 or 0.12, g, M.METAL, A)
	end
	return out
end

-- the starter heavy helm: a close helm with a tall comb and a sparrow-beak visor
local function closeHelm()
	local m = C.STEEL
	local out = {middle(HEAD)}
	local sh = helmShell(0.73, 0.76, 0.06, -0.56, 0.26, 0.6, m, M.METAL, MT)
	B.join(out, sh, {
		egg("Comb", v(0.09, 0.44, 1.38), cf(0, 0.84, 0.06), m, M.METAL, MT),
		torus("Gorget", v(1.56, 0.1, 1.6), cf(0, -0.54, 0.06), m, M.METAL, MT),
	})
	-- the visor and the bevor under it fold to a prow in front of the face; the sight is the gap between
	for _, s in ipairs({-1, 1}) do
		local across = Vector3.new(0.743, 0, s * 0.669)
		out[#out + 1] = plate("Visor", v(s * 0.31, 0.54, -0.64), v(s * 0.31, 0.245, -0.64), 0.84, 0.1, m, M.METAL, MT, across, 0.02)
		out[#out + 1] = plate("Bevor", v(s * 0.31, 0.155, -0.64), v(s * 0.29, -0.4, -0.6), 0.84, 0.1, m, M.METAL, MT, across, 0.02)
		out[#out + 1] = plate("Sight", v(s * 0.29, 0.25, -0.6), v(s * 0.29, 0.15, -0.6), 0.8, 0.06, C.BLACK, M.PLASTIC, nil, across)
		local hinge = onDrum(0.73, 0.76, 0.06, math.rad(s * 58), 0.2)
		out[#out + 1] = ball("Hinge", 0.14, CFrame.new(hinge), m, M.METAL, MT)
	end
	local nrm = Vector3.new(0.669, 0, -0.743)
	for r = 0, 1 do for c2 = 0, 2 do   -- breaths on the right of the bevor
		local p = Vector3.new(0.31, -0.06 - r * 0.13, -0.64) + Vector3.new(0.743, 0, 0.669) * (0.02 + c2 * 0.11)
		out[#out + 1] = disc("Breath", p, nrm, 0.07, 0.04, C.BLACK, M.PLASTIC, nil, 0.008)
	end end
	local peg = Vector3.new(0.31, 0.4, -0.64) + Vector3.new(0.743, 0, 0.669) * 0.3
	out[#out + 1] = rod("Peg", peg, peg + nrm * 0.14, 0.07, m, M.METAL, MT)   -- the lifting peg
	return out
end

-- Sellswords: a battered barbute, its T cut from brow to chin, a red feather at the back
local function barbute()
	local m = C.IRON
	local out = {middle(HEAD)}
	local sh, dome = helmShell(0.74, 0.77, 0.05, -0.6, 0.14, 0.7, m, M.METAL, MT)
	B.join(out, sh, {
		egg("Keel", v(0.08, 0.2, 1.3), cf(0, 0.82, 0.05), m, M.METAL, MT),
		cone("Flare", v(1.62, 0.12, 1.66), cf(0, -0.6, 0.05), m, M.METAL, MT, 0.92),
		rod("Socket", v(0, 0.46, 0.76), v(0, 0.68, 0.86), 0.1, C.BRASS, M.METAL, A),
		egg("Feather", v(0.14, 0.72, 0.28), cf(0, 0.94, 1.0, 34, 0, 0), C.RED, M.FABRIC),
	}, drumBand("Opening", 0.74, 0.77, 0.05, 0.2, -36, 36, 0.13, C.BLACK, M.PLASTIC, nil, 0.01))
	for i = 0, 4 do   -- the T's stem, down to the chin
		local p, n = onDrum(0.74, 0.77, 0.05, 0, 0.08 - i * 0.13)
		out[#out + 1] = lay(box("Opening", v(0.26, 0.16, 0.08), nil, C.BLACK, M.PLASTIC), p, n, 0.01)
	end
	local p, n = front(dome, -0.4, 0.5)
	out[#out + 1] = lay(box("Gash", v(0.36, 0.04, 0.06), nil, C.DARKSTEEL, M.METAL), p, n, 0.006, 26)
	p, n = onDrum(0.74, 0.77, 0.05, math.rad(34), -0.3)
	out[#out + 1] = lay(egg("Dent", v(0.22, 0.16, 0.05), nil, C.DARKSTEEL, M.METAL), p, n, 0.006, -15)
	return out
end

-- River Guard: an open bascinet over a mail aventail laced on with brass studs
local function aventailBascinet()
	local m = C.STEEL
	local skull = {c = v(0, 0.42, 0.08), s = v(1.46, 1.06, 1.5)}
	local out = {middle(HEAD),
		shell("Skull", skull, m, M.METAL, MT),
		cone("Apex", v(0.66, 0.4, 0.7), cf(0, 0.96, 0.22, 16, 0, 0), m, M.METAL, MT),
		egg("Aventail", v(1.58, 1.18, 1.38), cf(0, -0.1, 0.18), C.MAIL, M.PLATE),
		egg("Bib", v(1.3, 0.48, 0.8), cf(0, -0.58, -0.3), C.MAIL, M.PLATE),
		cone("Hem", v(1.9, 0.26, 1.9), cf(0, -0.66, 0.1), C.MAIL, M.PLATE, nil, 0.88),
	}
	B.join(out, row("Brow", skull, 0.32, -0.44, 0.44, 0.1, C.BRASS, M.METAL, A, 0.025),
		studsRound("Vervelle", skull, 0.2, 64, 296, 11, 0.09, C.BRASS, M.METAL, A))
	return out
end

-- the Gilded Court: a burgonet — a tall gilded comb, a peak over the eyes, hinged cheek plates, a flared neck guard
local function burgonet()
	local m, g = C.STEEL, C.GOLD
	local skull = {c = v(0, 0.38, 0.06), s = v(1.48, 1.12, 1.54)}
	local out = {middle(HEAD),
		shell("Skull", skull, m, M.METAL, MT),
		egg("Lining", v(1.4, 1.16, 1.06), cf(0, -0.06, 0.26), C.CLOTH2, M.FABRIC, S),
		egg("Comb", v(0.09, 0.58, 1.44), cf(0, 0.88, 0.06), g, M.METAL, A),
		egg("Peak", v(1.24, 0.07, 0.56), cf(0, 0.25, -0.68, -12, 0, 0), m, M.METAL, MT),
		egg("PeakEdge", v(1.28, 0.05, 0.6), cf(0, 0.25, -0.68, -12, 0, 0), g, M.METAL, A),
		plate("NeckGuard", v(0, 0.24, 0.72), v(0, -0.3, 0.98), 1.34, 0.07, m, M.METAL, MT, -X, 0.03),
		rod("PlumeHolder", v(0, 0.62, 0.74), v(0, 0.86, 0.8), 0.12, g, M.METAL, A),
		egg("Plume", v(0.3, 0.72, 0.4), cf(0, 1.0, 0.98, 48, 0, 0), C.CLOTH, M.FABRIC, P),
		egg("Plume", v(0.24, 0.6, 0.34), cf(0, 0.82, 1.28, 96, 0, 0), C.CLOTH, M.FABRIC, P),
	}
	for _, s in ipairs({-1, 1}) do   -- cheek plates, gold-edged, three studs each
		local across = Vector3.new(0, 0, s)
		out[#out + 1] = plate("Cheek", v(s * 0.72, 0.22, -0.13), v(s * 0.66, -0.5, -0.2), 0.62, 0.08, m, M.METAL, MT, across, 0.04)
		out[#out + 1] = plate("CheekEdge", v(s * 0.735, 0.2, -0.42), v(s * 0.675, -0.5, -0.49), 0.06, 0.09, g, M.METAL, A, across)
		for i = 0, 2 do
			out[#out + 1] = ball("Stud", 0.08, cf(s * (0.735 - i * 0.02), 0.08 - i * 0.22, -0.1), g, M.METAL, A)
		end
	end
	B.join(out, studsRound("Stud", skull, 0.16, 100, 260, 7, 0.08, g, M.METAL, A))
	return out
end

-- Wolf Company: a steel wolf's head — muzzle and fangs over the face, amber eyes slanted, ears up, a fur ruff
local function wolfHelm()
	local m = C.IRON
	local out = {middle(HEAD)}
	local sh, dome = helmShell(0.74, 0.76, 0.08, -0.56, 0.3, 0.56, m, M.METAL, MT)
	B.join(out, sh, {
		egg("Muzzle", v(0.86, 0.5, 1.04), cf(0, 0.25, -0.8, -6, 0, 0), m, M.METAL, MT),
		egg("Nose", v(0.32, 0.2, 0.24), cf(0, 0.36, -1.3), C.BLACK, M.PLASTIC),
		egg("Jaw", v(0.76, 0.28, 0.86), cf(0, -0.32, -0.72, 8, 0, 0), m, M.METAL, MT),
		egg("Throat", v(0.6, 0.26, 0.7), cf(0, -0.1, -0.74), C.BLACK, M.PLASTIC),
		egg("Brow", v(0.42, 0.16, 0.36), cf(-0.27, 0.56, -0.62, 0, 0, -14), m, M.METAL, MT),
		egg("Brow", v(0.42, 0.16, 0.36), cf(0.27, 0.56, -0.62, 0, 0, 14), m, M.METAL, MT),
		egg("Ruff", v(1.7, 0.7, 0.96), cf(0, -0.36, 0.44), C.FUR, M.FABRIC),
		cone("Aventail", v(1.86, 0.3, 1.86), cf(0, -0.58, 0.1), C.MAIL, M.PLATE, nil, 0.86),
	})
	for _, s in ipairs({-1, 1}) do
		local p, n = front(dome, s * 0.27, 0.44)
		out[#out + 1] = lay(box("Eye", v(0.26, 0.08, 0.08), nil, AMBER, M.PLASTIC), p, n, 0.012, s * 14)
		out[#out + 1] = cone("Ear", v(0.36, 0.5, 0.18), cf(s * 0.42, 0.98, 0.14, 0, 0, -s * 16), m, M.METAL, MT)
		for i = 0, 2 do   -- fangs: down from the muzzle, up from the jaw
			local x, z = s * (0.12 + i * 0.08), -1.12 + i * 0.13
			out[#out + 1] = spike("Fang", v(x, 0.04, z), v(x, -0.16 - (i == 0 and 0.05 or 0), z - 0.02), 0.09, FANG, M.PLASTIC)
			out[#out + 1] = spike("Fang", v(x * 0.9, -0.22, z + 0.06), v(x * 0.9, -0.08, z + 0.05), 0.07, FANG, M.PLASTIC)
		end
	end
	return out
end

-- the coif under a helmet or worn alone: a crown, a body round the sides and back (the face open), a bib under the chin
local COIF_CROWN = {c = v(0, 0.36, 0.06), s = v(1.48, 0.92, 1.54)}
local COIF_BODY = {c = v(0, -0.1, 0.16), s = v(1.66, 1.22, 1.36)}
local function coif(color, mat, attrs, roll, rollAttrs)
	return J({shell("Coif", COIF_CROWN, color, mat, attrs),
		shell("Coif", COIF_BODY, color, mat, attrs),
		egg("Bib", v(1.24, 0.46, 0.76), cf(0, -0.58, -0.28), color, mat, attrs),
		cone("Cape", v(1.96, 0.28, 1.9), cf(0, -0.62, 0.1), color, mat, attrs, 0.72)},
		tube("Roll", faceLoop(0.43, 0.48, -0.02, {COIF_CROWN, COIF_BODY}, 0.035), 0.09, roll, M.FABRIC, rollAttrs, true))
end
-- the starter medium helm: a padded coif under a plain steel cap
local function cappedCoif()
	local m = C.STEEL
	return J({middle(HEAD)}, coif(C.CLOTH, M.FABRIC, P, C.CLOTH2, S), {
		egg("Cap", v(1.6, 0.94, 1.64), cf(0, 0.43, 0.06), m, M.METAL, MT),
		torus("CapRim", v(1.6, 0.07, 1.64), cf(0, 0.3, 0.06), m, M.METAL, MT),
		egg("CapRidge", v(0.08, 0.24, 1.4), cf(0, 0.84, 0.06), m, M.METAL, MT),
		box("ChinStrap", v(0.6, 0.1, 0.08), cf(0, -0.56, -0.68), C.DARKLEATHER, M.LEATHER),
	})
end
-- Road Levy: a mail coif, its edge bound in leather, a cloth band knotted round the crown
local function mailCoif()
	return J({middle(HEAD)}, coif(C.MAIL, M.PLATE, nil, C.LEATHER, nil), {
		torus("Band", v(1.56, 0.13, 1.62), cf(0, 0.52, 0.06), C.CLOTH, M.FABRIC, P),
		egg("Knot", v(0.24, 0.18, 0.16), cf(0, 0.52, 0.84), C.CLOTH, M.FABRIC, P),
		plate("Tail", v(-0.06, 0.5, 0.86), v(-0.16, -0.06, 0.92), 0.12, 0.04, C.CLOTH, M.FABRIC, P, -X),
		plate("Tail", v(0.06, 0.5, 0.86), v(0.14, -0.14, 0.94), 0.12, 0.04, C.CLOTH, M.FABRIC, P, -X),
	})
end

-- Marsh Wardens: a hunter's hood with a long liripipe, its face edge rolled, the cowl dagged into leaves
local function wardenHood()
	local col = C.GREEN
	local crown = {c = v(0, 0.4, 0.08), s = v(1.56, 1.0, 1.62)}
	local body = {c = v(0, -0.08, 0.18), s = v(1.72, 1.26, 1.4)}
	local out = J({middle(HEAD),
		shell("Hood", crown, col, M.FABRIC, P),
		shell("Hood", body, col, M.FABRIC, P),
		egg("Peak", v(0.5, 0.4, 0.56), cf(0, 0.82, -0.3, -20, 0, 0), col, M.FABRIC, P),
		cone("Cowl", v(2.1, 0.38, 2.0), cf(0, -0.62, 0.1), col, M.FABRIC, P, 0.7),
		egg("Feather", v(0.08, 0.62, 0.2), cf(0.8, 0.56, 0.26, 18, 0, -16), C.GOLD, M.FABRIC, A),
	}, tube("Roll", faceLoop(0.44, 0.5, -0.02, {crown, body}, 0.05), 0.13, col, M.FABRIC, P, true))
	local tail = {v(0, 0.84, 0.56), v(0, 0.56, 0.98), v(0, 0.06, 1.12), v(0, -0.46, 1.06)}
	for i = 1, #tail - 1 do
		local d = 0.34 - i * 0.06
		out[#out + 1] = rod("Liripipe", tail[i], tail[i + 1], d, col, M.FABRIC, P)
		out[#out + 1] = ball("Liripipe", d, CFrame.new(tail[i + 1]), col, M.FABRIC, P)
	end
	for i = 0, 11 do   -- the dags round the cowl's hem, leaf-shaped, following its flare
		local a = i / 12 * math.pi * 2
		local outward = Vector3.new(math.sin(a), 0, -math.cos(a))
		local p = Vector3.new(math.sin(a) * 1.0, -0.86, 0.1 - math.cos(a) * 0.96)
		out[#out + 1] = egg("Dag", v(0.4, 0.34, 0.07), CFrame.lookAt(p, p + outward) * CFrame.Angles(math.rad(-38), 0, 0), col, M.FABRIC, P)
	end
	return out
end

-- Harriers of the Coast: a sailor's cap, its tip flopped forward, a red kerchief under it, a gold earring
local function seaCap()
	local col = C.CLOTH
	return {middle(HEAD),
		egg("Cap", v(1.46, 0.82, 1.52), cf(0, 0.52, 0.06), col, M.FABRIC, P),
		egg("Fold", v(0.72, 0.5, 1.0), cf(0, 0.92, -0.18, -48, 0, 0), col, M.FABRIC, P),
		egg("Tip", v(0.42, 0.36, 0.6), cf(0, 0.86, -0.64, -82, 0, 0), col, M.FABRIC, P),
		torus("Kerchief", v(1.52, 0.2, 1.58), cf(0, 0.25, 0.06), C.RED, M.FABRIC),
		egg("Knot", v(0.3, 0.24, 0.22), cf(0.36, 0.26, 0.76), C.RED, M.FABRIC),
		plate("KnotTail", v(0.42, 0.22, 0.82), v(0.5, -0.24, 0.9), 0.14, 0.04, C.RED, M.FABRIC, nil, -X),
		plate("KnotTail", v(0.3, 0.22, 0.82), v(0.28, -0.3, 0.88), 0.13, 0.04, C.RED, M.FABRIC, nil, -X),
		torus("Earring", v(0.22, 0.045, 0.22), cf(-0.66, -0.26, 0.02, 0, 0, 90), C.GOLD, M.METAL),
	}
end

-- Night Hunters: a head-wrap, a black half-mask over nose and mouth, the tails knotted behind
local function headWrap()
	local col, dark = C.CLOTH, C.CLOTH2
	return {middle(HEAD),
		egg("Wrap", v(1.5, 0.98, 1.56), cf(0, 0.4, 0.06), col, M.FABRIC, P),
		egg("Wrap", v(1.66, 1.2, 1.32), cf(0, -0.1, 0.18), col, M.FABRIC, P),
		torus("Turn", v(1.56, 0.11, 1.62), cf(0, 0.3, 0.06, 10, 0, 0), dark, M.FABRIC, S),
		torus("Turn", v(1.46, 0.11, 1.52), cf(0, 0.56, 0.08, -12, 0, 0), dark, M.FABRIC, S),
		egg("Mask", v(1.44, 0.64, 1.12), cf(0, -0.28, -0.14), C.BLACK, M.FABRIC),
		cone("Neck", v(1.6, 0.3, 1.6), cf(0, -0.58, 0.06), col, M.FABRIC, P, 0.86),
		egg("Knot", v(0.3, 0.24, 0.2), cf(0, 0.34, 0.82), dark, M.FABRIC, S),
		plate("Tail", v(-0.06, 0.3, 0.86), v(-0.2, -0.36, 0.94), 0.16, 0.04, dark, M.FABRIC, S, -X),
		plate("Tail", v(0.06, 0.3, 0.86), v(0.16, -0.42, 0.96), 0.16, 0.04, dark, M.FABRIC, S, -X),
	}
end

-- the free Light hat: a wide straw hat, a cloth band, a stalk of wheat
local function strawHat()
	return {middle(HEAD),
		cone("Brim", v(2.36, 0.14, 2.36), cf(0, 0.5, 0), C.STRAW, M.FABRIC, nil, 0.62),
		torus("BrimEdge", v(2.4, 0.06, 2.4), cf(0, 0.44, 0), STRAW2, M.FABRIC),
		torus("Weave", v(1.92, 0.035, 1.92), cf(0, 0.515, 0), STRAW2, M.FABRIC),
		cone("Crown", v(1.36, 0.44, 1.36), cf(0, 0.77, 0), C.STRAW, M.FABRIC, nil, 0.86),
		egg("Crown", v(1.18, 0.26, 1.18), cf(0, 0.99, 0), C.STRAW, M.FABRIC),
		torus("Band", v(1.42, 0.12, 1.42), cf(0, 0.63, 0), C.CLOTH, M.FABRIC, P),
		egg("Wheat", v(0.07, 0.42, 0.07), cf(0.64, 0.84, 0.22, 0, 0, -24), C.STRAW, M.FABRIC),
		egg("Wheat", v(0.1, 0.18, 0.1), cf(0.74, 1.04, 0.22, 0, 0, -24), STRAW2, M.FABRIC),
	}
end

-- Wolf Pelt Hood: the wolf's own head over yours, its pelt hanging round your head and down your back
local function wolfPelt()
	local f = C.FUR
	local out = {middle(HEAD),
		egg("Pelt", v(1.62, 0.9, 1.74), cf(0, 0.74, 0.1), f, M.FABRIC),
		egg("Snout", v(0.72, 0.46, 0.96), cf(0, 0.68, -0.84, -6, 0, 0), f, M.FABRIC),
		egg("Nose", v(0.26, 0.18, 0.2), cf(0, 0.74, -1.3), C.BLACK, M.PLASTIC),
		egg("Brow", v(0.4, 0.16, 0.34), cf(-0.27, 0.98, -0.6, 0, 0, -12), f, M.FABRIC),
		egg("Brow", v(0.4, 0.16, 0.34), cf(0.27, 0.98, -0.6, 0, 0, 12), f, M.FABRIC),
		egg("Pelt", v(1.72, 1.3, 1.4), cf(0, -0.08, 0.2), f, M.FABRIC),
		plate("Hide", v(0, 0.5, 0.8), v(0, -0.62, 0.9), 1.3, 0.1, f, M.FABRIC, nil, -X, 0.05),
		egg("Paw", v(0.26, 0.5, 0.16), cf(-0.5, -0.72, 0.88, 0, 0, -8), f, M.FABRIC),
		egg("Paw", v(0.26, 0.5, 0.16), cf(0.5, -0.72, 0.88, 0, 0, 8), f, M.FABRIC),
	}
	for _, s in ipairs({-1, 1}) do
		out[#out + 1] = ball("Eye", 0.11, cf(s * 0.27, 0.9, -0.69), AMBER, M.PLASTIC)
		out[#out + 1] = cone("Ear", v(0.36, 0.48, 0.2), cf(s * 0.46, 1.24, 0.12, 0, 0, -s * 16), f, M.FABRIC)
		out[#out + 1] = cone("EarInner", v(0.2, 0.3, 0.06), cf(s * 0.45, 1.2, 0.03, 0, 0, -s * 16), Color3.fromRGB(120, 86, 70), M.FABRIC)
		for i = 0, 1 do
			local x, z = s * (0.14 + i * 0.1), -1.14 + i * 0.16
			out[#out + 1] = spike("Fang", v(x, 0.5, z), v(x, 0.33, z - 0.02), 0.08, FANG, M.PLASTIC)
		end
	end
	return out
end

-- Bloodied Kettle: a broad-brimmed kettle hat, dented, splashed and dripping
local function bloodiedKettle()
	local m = C.IRON
	local dome = {c = v(0, 0.56, 0), s = v(1.38, 0.96, 1.38)}
	local out = {middle(HEAD),
		shell("Dome", dome, m, M.METAL, MT),
		egg("Ridge", v(0.08, 0.3, 1.24), cf(0, 0.94, 0), m, M.METAL, MT),
		cone("Brim", v(2.2, 0.18, 2.2), cf(0, 0.44, 0), m, M.METAL, MT, 0.64),
		torus("BrimRoll", v(2.24, 0.07, 2.24), cf(0, 0.355, 0), m, M.METAL, MT),
		box("ChinStrap", v(0.1, 0.8, 0.08), cf(-0.66, -0.06, -0.08), C.DARKLEATHER, M.LEATHER),
		box("ChinStrap", v(0.1, 0.8, 0.08), cf(0.66, -0.06, -0.08), C.DARKLEATHER, M.LEATHER),
	}
	for i = 0, 9 do
		local p, n = around(dome, i / 10 * math.pi * 2, 0.52)
		out[#out + 1] = stud("Rivet", p, n, 0.08, C.DARKSTEEL, M.METAL)
	end
	local p, n = around(dome, math.rad(-40), 0.74)
	out[#out + 1] = lay(egg("Dent", v(0.3, 0.2, 0.05), nil, C.DARKSTEEL, M.METAL), p, n, 0.006)
	p, n = around(dome, math.rad(130), 0.66)
	out[#out + 1] = lay(egg("Dent", v(0.24, 0.16, 0.05), nil, C.DARKSTEEL, M.METAL), p, n, 0.006)
	for _, b in ipairs({{20, 0.8, 0.38, 0.24}, {38, 0.62, 0.22, 0.32}, {-70, 0.86, 0.24, 0.16}}) do
		local q, nq = around(dome, math.rad(b[1]), b[2])
		out[#out + 1] = lay(egg("Blood", v(b[3], b[4], 0.05), nil, BLOOD, M.PLASTIC), q, nq, 0.01, b[1])
	end
	for i, a in ipairs({14, 26, 44}) do   -- a splash on the brim and drips off its edge
		local r = math.rad(a)
		out[#out + 1] = egg("Blood", v(0.36, 0.04, 0.24), CFrame.new(math.sin(r) * 0.9, 0.455, -math.cos(r) * 0.9) * CFrame.Angles(0, -r, 0) * CFrame.Angles(math.rad(-24), 0, 0), BLOOD, M.PLASTIC)
		out[#out + 1] = egg("Drip", v(0.07, 0.18 + i * 0.05, 0.07), cf(math.sin(r) * 1.1, 0.29 - i * 0.03, -math.cos(r) * 1.1), BLOOD, M.PLASTIC)
	end
	return out
end

-- Duelist's Sallet: a German sallet — a long swept tail, a visor with one narrow sight, a bevor to the nose
local function duelistSallet()
	local m = C.STEEL
	local out = {middle(HEAD)}
	local sh = helmShell(0.73, 0.76, 0.08, -0.5, 0.3, 0.56, m, M.METAL, MT)
	local visor = {c = v(0, 0.26, -0.32), s = v(1.42, 0.62, 0.94)}
	local bevor = {c = v(0, -0.3, -0.3), s = v(1.38, 0.76, 1.0)}
	B.join(out, sh, {
		plate("Tail", v(0, 0.34, 0.74), v(0, 0.06, 1.36), 1.26, 0.07, m, M.METAL, MT, -X, 0.03),
		shell("Visor", visor, m, M.METAL, MT),
		shell("Bevor", bevor, m, M.METAL, MT),
		egg("Keel", v(0.07, 0.18, 1.3), cf(0, 0.86, 0.08), m, M.METAL, MT),
		torus("Gorget", v(1.52, 0.1, 1.56), cf(0, -0.56, 0.0), m, M.METAL, MT),
	}, row("Sight", visor, 0.2, -0.5, 0.5, 0.06, C.BLACK, M.PLASTIC, nil, 0.012),
		studs("Rivet", bevor, -0.02, -0.4, 0.4, 5, 0.07, C.BRASS, M.METAL, A))
	for _, s in ipairs({-1, 1}) do
		local p, n = onDrum(0.73, 0.76, 0.08, math.rad(s * 70), 0.26)
		out[#out + 1] = disc("Pivot", p, n, 0.16, 0.05, C.BRASS, M.METAL, A, 0.035)
	end
	return out
end

--------------------------------------------------------------------
--  TORSOS (torso frame: shoulders at y = +1, waist at -1, chest at z = -0.5)
--------------------------------------------------------------------
local function belt(y, buckle, pouch, color)
	local col = color or C.DARKLEATHER
	local out = {rbox("Belt", v(2.26, 0.22, 1.26), cf(0, y, 0), col, M.LEATHER, nil, 0.1),
		rbox("Buckle", v(0.32, 0.3, 0.07), cf(0, y, -0.65), buckle or C.BRASS, M.METAL, A, 0.03),
		box("Tongue", v(0.07, 0.1, 0.05), cf(0.05, y, -0.7), col, M.LEATHER)}
	if pouch then
		B.join(out, {rbox("Pouch", v(0.44, 0.46, 0.26), cf(0.68, y - 0.26, -0.65), C.LEATHER, M.LEATHER, nil, 0.08),
			rbox("PouchFlap", v(0.46, 0.18, 0.28), cf(0.68, y - 0.08, -0.66), C.DARKLEATHER, M.LEATHER, nil, 0.05),
			ball("PouchStud", 0.08, cf(0.68, y - 0.15, -0.81), C.BRASS, M.METAL, A)})
	end
	return out
end
-- a breastplate drawn in at the waist, its gentle swell, a ridge down the middle; gorget and fauld
local function cuirass(m, trim, o)
	o = o or {}
	local breast = {c = v(0, 0.32, -0.48), s = v(2.0, 1.5, 0.32)}
	local out = {middle(TORSO),
		tbox("Cuirass", v(2.12, 1.66, 1.16), cf(0, 0.18, 0.02), 1.06, m, M.METAL, MT, 0.3),
		shell("Breast", breast, m, M.METAL, MT),
		cone("Gorget", v(1.56, 0.28, 1.46), cf(0, 0.98, 0.02), m, M.METAL, MT, 0.9),
		torus("GorgetRoll", v(1.44, 0.08, 1.36), cf(0, 1.12, 0.02), trim, M.METAL, A),
		rbox("Neckline", v(1.2, 0.07, 0.08), cf(0, 0.95, -0.585), trim, M.METAL, A, 0.03),
	}
	for i = 0, 2 do   -- the fauld: lames flaring over the hips
		out[#out + 1] = tbox("Fauld", v(2.24 + i * 0.06, 0.2, 1.26 + i * 0.04), cf(0, -0.66 - i * 0.17, 0.02), 0.95, m, M.METAL, MT, 0.12)
	end
	out[#out + 1] = tbox("FauldHem", v(2.38, 0.05, 1.38), cf(0, -1.02, 0.02), 0.98, trim, M.METAL, A, 0.12)
	if not o.smooth then B.join(out, column("Ridge", breast, 0, 0.78, -0.12, 0.06, m, M.METAL, MT, 0.025)) end
	if o.plackart then   -- a pointed plate over the belly
		out[#out + 1] = box("Plackart", v(0.6, 0.6, 0.05), cf(0, -0.14, -0.63, 0, 0, 45), m, M.METAL, MT)
		out[#out + 1] = box("Plackart", v(1.3, 0.34, 0.05), cf(0, -0.42, -0.63), m, M.METAL, MT)
		for i = -1, 1 do out[#out + 1] = ball("Rivet", 0.08, cf(i * 0.4, -0.44, -0.66), trim, M.METAL, A) end
	end
	for _, s in ipairs({-1, 1}) do
		out[#out + 1] = ball("Rivet", 0.09, cf(s * 0.86, 0.8, -0.6), trim, M.METAL, A)
		out[#out + 1] = ball("Rivet", 0.09, cf(s * 0.88, -0.36, -0.58), trim, M.METAL, A)
	end
	return out
end
-- a shoulder: a domed cop rimmed round its edge and two lames; style "haute" (a neck guard), "spikes", "sun" (a gilded disc)
local function pauldron(s, m, mat, slot, style, trim)
	local out = {
		egg("Pauldron", v(1.24, 0.76, 1.36), cf(s * 1.4, 0.94, 0.02, 0, 0, -s * 8), m, mat, slot),
		egg("Lame", v(1.12, 0.4, 1.28), cf(s * 1.5, 0.6, 0.02, 0, 0, -s * 14), m, mat, slot),
		egg("Lame", v(1.04, 0.36, 1.22), cf(s * 1.56, 0.4, 0.02, 0, 0, -s * 20), m, mat, slot),
		torus("Rim", v(1.26, 0.06, 1.38), cf(s * 1.4, 0.92, 0.02, 0, 0, -s * 8), trim or m, M.METAL, trim and A or slot),
	}
	if trim then
		out[#out + 1] = egg("LameEdge", v(1.06, 0.33, 1.24), cf(s * 1.56, 0.38, 0.02, 0, 0, -s * 20), trim, M.METAL, A)
	end
	if style == "haute" then
		out[#out + 1] = plate("Haute", v(s * 0.86, 1.5, 0.02), v(s * 0.9, 1.1, 0.02), 1.0, 0.06, m, mat, slot, Vector3.new(0, 0, s), 0.03)
		if trim then out[#out + 1] = rod("HauteEdge", v(s * 0.87, 1.51, -0.48), v(s * 0.87, 1.51, 0.52), 0.06, trim, M.METAL, A) end
	elseif style == "spikes" then
		for i = -1, 1 do
			local foot = Vector3.new(s * 1.4, 1.22, 0.02 + i * 0.36)
			out[#out + 1] = spike("Spike", foot, foot + Vector3.new(s * 0.16, 0.38, 0), 0.18, m, mat, slot)
		end
	elseif style == "sun" then
		local p, n = Vector3.new(s * 1.98, 0.9, 0.02), Vector3.new(s, 0.35, 0).Unit
		out[#out + 1] = disc("Sun", p, n, 0.6, 0.06, trim or C.GOLD, M.METAL, A, 0.05)
		local t1 = n:Cross(Z).Unit
		local t2 = n:Cross(t1).Unit
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			local dir = t1 * math.cos(a) + t2 * math.sin(a)
			local at = p + n * 0.03
			out[#out + 1] = spike("SunRay", at + dir * 0.26, at + dir * (i % 2 == 0 and 0.5 or 0.4), 0.11, trim or C.GOLD, M.METAL, A)
		end
		out[#out + 1] = ball("SunBoss", 0.18, CFrame.new(p + n * 0.05), trim or C.GOLD, M.METAL, A)
	end
	return out
end
-- a small shoulder plate over mail
local function spaulder(s, m, trim)
	local out = {
		egg("Spaulder", v(1.12, 0.56, 1.28), cf(s * 1.4, 0.96, 0.02, 0, 0, -s * 8), m, M.METAL, MT),
		egg("Lame", v(1.04, 0.36, 1.22), cf(s * 1.48, 0.7, 0.02, 0, 0, -s * 14), m, M.METAL, MT),
	}
	if trim then out[#out + 1] = egg("LameEdge", v(1.06, 0.33, 1.24), cf(s * 1.48, 0.68, 0.02, 0, 0, -s * 14), trim, M.METAL, A) end
	return out
end
-- a tabard, front and back, its hem dagged (len = 0: only the emblem, laid at z = ez on a coat already there);
-- emblem "cross" | "sun" | "waves" | "quarters" | "chevron" | "stripe"
local function tabard(len, emblem, eColor, wide, ez)
	local w, col, e = wide and 1.6 or 1.24, C.CLOTH, eColor or C.GOLD
	local top, bottom = 0.98, 0.98 - len
	local out = {}
	if len > 0 then
		out[#out + 1] = box("Tabard", v(w, len, 0.08), cf(0, (top + bottom) / 2, -0.67), col, M.FABRIC, P)
		out[#out + 1] = box("Tabard", v(w, len, 0.08), cf(0, (top + bottom) / 2, 0.67), col, M.FABRIC, P)
		local n = wide and 6 or 5
		for i = 0, n - 1 do   -- the dagged hem
			local x = -w / 2 + w / n * (i + 0.5)
			out[#out + 1] = egg("Dag", v(w / n * 0.9, 0.26, 0.08), cf(x, bottom - 0.04, -0.67), col, M.FABRIC, P)
			out[#out + 1] = egg("Dag", v(w / n * 0.9, 0.26, 0.08), cf(x, bottom - 0.04, 0.67), col, M.FABRIC, P)
		end
	end
	local z = ez or -0.725
	if emblem == "cross" then
		out[#out + 1] = box("Cross", v(0.22, 1.1, 0.04), cf(0, 0.22, z), e, M.FABRIC, A)
		out[#out + 1] = box("Cross", v(0.84, 0.22, 0.04), cf(0, 0.44, z), e, M.FABRIC, A)
	elseif emblem == "sun" then
		out[#out + 1] = cyl("Sun", 0.52, 0.04, cf(0, 0.36, z, 90, 0, 0), e, M.FABRIC, A)
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			local r0, r1 = 0.3, i % 2 == 0 and 0.56 or 0.46
			out[#out + 1] = box("SunRay", v(0.07, r1 - r0, 0.04), CFrame.new(math.cos(a) * (r0 + r1) / 2, 0.36 + math.sin(a) * (r0 + r1) / 2, z) * CFrame.Angles(0, 0, a - math.pi / 2), e, M.FABRIC, A)
		end
	elseif emblem == "waves" then
		for i = 0, 2 do
			for k = -2, 2 do
				out[#out + 1] = box("Wave", v(0.26, 0.07, 0.04), cf(k * 0.22, 0.56 - i * 0.28, z, 0, 0, (k % 2 == 0) and 24 or -24), e, M.FABRIC, A)
			end
		end
	elseif emblem == "quarters" then
		out[#out + 1] = box("Quarter", v(w / 2, 0.62, 0.04), cf(-w / 4, top - 0.31, z), C.CLOTH2, M.FABRIC, S)
		out[#out + 1] = box("Quarter", v(w / 2, 0.62, 0.04), cf(w / 4, top - 0.93, z), C.CLOTH2, M.FABRIC, S)
	elseif emblem == "chevron" then
		out[#out + 1] = box("Chevron", v(0.28, 1.05, 0.04), cf(-0.32, 0.12, z, 0, 0, -48), e, M.FABRIC, A)
		out[#out + 1] = box("Chevron", v(0.28, 1.05, 0.04), cf(0.32, 0.12, z, 0, 0, 48), e, M.FABRIC, A)
	elseif emblem == "stripe" then
		out[#out + 1] = box("Stripe", v(w, 0.36, 0.04), cf(0, 0.42, z), e, M.FABRIC, A)
		out[#out + 1] = box("Stripe", v(w, 0.36, 0.04), cf(0, 0.42, -z), e, M.FABRIC, A)
	end
	return out
end
local function cape(color, slot, tattered, edge)
	local col = color or C.CLOTH
	local out = {plate("Cape", v(0, 1.0, 0.66), v(0, -1.55, 0.88), 2.1, 0.08, col, M.FABRIC, slot, -X, 0.03),
		egg("CapeFold", v(2.1, 0.3, 0.4), cf(0, 0.98, 0.58), col, M.FABRIC, slot),
		cyl("Clasp", 0.3, 0.07, cf(-0.84, 0.94, -0.62, 90, 0, 0), C.GOLD, M.METAL, A),
		cyl("Clasp", 0.3, 0.07, cf(0.84, 0.94, -0.62, 90, 0, 0), C.GOLD, M.METAL, A),
		rod("Cord", v(-0.84, 0.94, -0.64), v(-0.95, 0.98, 0.5), 0.07, C.GOLD, M.FABRIC, A),
		rod("Cord", v(0.84, 0.94, -0.64), v(0.95, 0.98, 0.5), 0.07, C.GOLD, M.FABRIC, A)}
	if tattered then
		for i = -3, 3 do
			out[#out + 1] = egg("Tatter", v(0.26, 0.5 + (i % 2) * 0.16, 0.08), cf(i * 0.29, -1.62 - (i % 2) * 0.08, 0.895, -5, 0, 0), col, M.FABRIC, slot)
		end
	end
	if edge then out[#out + 1] = box("CapeEdge", v(2.12, 0.08, 0.1), cf(0, -1.5, 0.88, -5, 0, 0), edge, M.METAL, A) end
	return out
end

-- the free Light top: a long linen tunic laced at the neck, a rope belt with a pouch, a patch on the chest
local function peasantTorso()
	return {middle(TORSO),
		rbox("Tunic", v(2.12, 2.06, 1.12), cf(), C.LINEN, M.FABRIC, P, 0.22),
		tbox("Skirt", v(2.24, 0.56, 1.22), cf(0, -1.2, 0), 0.95, C.LINEN, M.FABRIC, P, 0.16),
		rbox("Keyhole", v(0.26, 0.44, 0.04), cf(0, 0.76, -0.565), C.CLOTH2, M.FABRIC, S, 0.015),
		box("Lace", v(0.3, 0.035, 0.03), cf(0, 0.86, -0.595, 0, 0, 22), C.ROPE, M.FABRIC),
		box("Lace", v(0.3, 0.035, 0.03), cf(0, 0.72, -0.595, 0, 0, -22), C.ROPE, M.FABRIC),
		rbox("Rope", v(2.2, 0.12, 1.2), cf(0, -0.62, 0), C.ROPE, M.FABRIC, nil, 0.06),
		egg("Knot", v(0.22, 0.2, 0.16), cf(-0.42, -0.62, -0.62), C.ROPE, M.FABRIC),
		rod("RopeEnd", v(-0.38, -0.66, -0.64), v(-0.34, -1.12, -0.66), 0.08, C.ROPE, M.FABRIC),
		rod("RopeEnd", v(-0.46, -0.66, -0.64), v(-0.54, -1.04, -0.66), 0.08, C.ROPE, M.FABRIC),
		rbox("Patch", v(0.36, 0.32, 0.04), cf(-0.52, 0.3, -0.565, 0, 0, 8), PATCH, M.FABRIC, nil, 0.015),
		rbox("Pouch", v(0.42, 0.44, 0.24), cf(0.66, -0.88, -0.62), C.LEATHER, M.LEATHER, nil, 0.08),
		rbox("PouchFlap", v(0.44, 0.16, 0.26), cf(0.66, -0.72, -0.63), C.DARKLEATHER, M.LEATHER, nil, 0.05),
	}
end
-- Road Levy: a padded jack over a linen shirt, a bedroll across the back, a waterskin and a pouch
local function levyTorso()
	local out = {middle(TORSO),
		rbox("Shirt", v(2.1, 2.06, 1.12), cf(), C.LINEN, M.FABRIC, nil, 0.2),
		rbox("Jack", v(2.2, 1.86, 1.2), cf(0, -0.1, 0), C.CLOTH, M.FABRIC, P, 0.26),
		tbox("JackSkirt", v(2.28, 0.34, 1.28), cf(0, -1.1, 0), 0.97, C.CLOTH, M.FABRIC, P, 0.2),
		rod("Bedroll", v(-0.98, 0.86, 0.86), v(0.98, -0.5, 0.86), 0.5, SAILCLOTH, M.FABRIC),
		plate("Strap", v(-0.96, 0.96, -0.64), v(0.92, -0.6, -0.64), 0.15, 0.04, C.DARKLEATHER, M.LEATHER),
		egg("Waterskin", v(0.38, 0.56, 0.3), cf(-0.84, -0.88, -0.5, 0, 0, 10), C.LEATHER, M.LEATHER),
		rod("Stopper", v(-0.88, -0.6, -0.5), v(-0.9, -0.48, -0.5), 0.1, C.WOOD, M.WOOD),
	}
	for _, x in ipairs({-0.7, -0.35, 0.35, 0.7}) do
		out[#out + 1] = box("Quilt", v(0.04, 1.7, 0.04), cf(x, -0.1, -0.615), C.CLOTH2, M.FABRIC, S)
	end
	B.join(out, hoop("Quilt", 2.2, 1.2, 0.26, 0.3, 0.04, C.CLOTH2, M.FABRIC, S), hoop("Quilt", 2.2, 1.2, 0.26, -0.3, 0.04, C.CLOTH2, M.FABRIC, S))
	local f, len = span(v(-0.98, 0.86, 0.86), v(0.98, -0.5, 0.86))
	for _, t in ipairs({-0.3, 0.3}) do
		out[#out + 1] = torus("Tie", v(0.56, 0.07, 0.56), f * CFrame.new(0, t * len, 0), C.DARKLEATHER, M.LEATHER)
	end
	return B.join(out, belt(-0.72, C.IRON, true))
end
-- Marsh Wardens: a laced leather jerkin over a green tunic, a cloak, a quiver of arrows, a knife
local function wardenTorso()
	local out = {middle(TORSO),
		rbox("Tunic", v(2.1, 2.06, 1.12), cf(), C.GREEN, M.FABRIC, P, 0.2),
		rbox("Jerkin", v(2.2, 1.64, 1.2), cf(0, -0.12, 0), C.LEATHER, M.LEATHER, nil, 0.24),
		tbox("JerkinSkirt", v(2.3, 0.42, 1.3), cf(0, -1.12, 0), 0.96, C.LEATHER, M.LEATHER, nil, 0.2),
		box("Opening", v(0.22, 1.5, 0.04), cf(0, -0.1, -0.605), C.GREEN, M.FABRIC, P),
		plate("Cloak", v(0, 1.0, 0.64), v(0, -1.35, 0.84), 2.12, 0.08, C.GREEN, M.FABRIC, P, -X, 0.03),
		egg("CloakFold", v(2.2, 0.32, 0.44), cf(0, 0.98, 0.54), C.GREEN, M.FABRIC, P),
		rod("Quiver", v(0.42, -0.42, 0.98), v(0.8, 0.96, 0.94), 0.42, C.DARKLEATHER, M.LEATHER),
		rbox("KnifeSheath", v(0.16, 0.56, 0.12), cf(-0.74, -0.98, -0.62, 0, 0, -12), C.BLACK, M.LEATHER, nil, 0.04),
		rod("KnifeHilt", v(-0.8, -0.7, -0.62), v(-0.84, -0.48, -0.62), 0.08, C.WOOD, M.WOOD),
	}
	for i = 0, 5 do   -- the lacing up the front
		out[#out + 1] = box("Lace", v(0.32, 0.035, 0.03), cf(0, 0.48 - i * 0.22, -0.625, 0, 0, i % 2 == 0 and 28 or -28), C.LINEN, M.FABRIC)
	end
	local qa, qb = v(0.42, -0.42, 0.98), v(0.8, 0.96, 0.94)
	local dir = (qb - qa).Unit
	for i = 0, 3 do   -- fletchings over the shoulder
		local base = qb + dir * 0.12 + Vector3.new((i % 2 - 0.5) * 0.14, 0, (i < 2 and -0.06 or 0.06))
		out[#out + 1] = rod("Shaft", base - dir * 0.2, base + dir * 0.12, 0.04, C.WOOD, M.WOOD)
		out[#out + 1] = egg("Fletching", v(0.05, 0.22, 0.14), CFrame.new(base + dir * 0.1) * CFrame.Angles(0, 0, math.rad(-15)), C.WHITE, M.FABRIC)
	end
	return B.join(out, belt(-0.62))
end
-- Harriers of the Coast: a striped shirt, an open vest, a wide red sash, a bandolier and a coil of rope
local function harrierTorso()
	local out = {middle(TORSO),
		rbox("Shirt", v(2.1, 2.06, 1.12), cf(), C.LINEN, M.FABRIC, nil, 0.2),
		box("Vest", v(0.6, 1.76, 0.06), cf(-0.74, 0.04, -0.585), C.DARKLEATHER, M.LEATHER),
		box("Vest", v(0.6, 1.76, 0.06), cf(0.74, 0.04, -0.585), C.DARKLEATHER, M.LEATHER),
		box("Vest", v(1.66, 1.76, 0.06), cf(0, 0.04, 0.585), C.DARKLEATHER, M.LEATHER),
		box("Vest", v(0.06, 1.76, 0.72), cf(-1.075, 0.04, 0), C.DARKLEATHER, M.LEATHER),
		box("Vest", v(0.06, 1.76, 0.72), cf(1.075, 0.04, 0), C.DARKLEATHER, M.LEATHER),
		box("VestEdge", v(0.05, 1.76, 0.07), cf(-0.42, 0.04, -0.59), C.BRASS, M.METAL, A),
		box("VestEdge", v(0.05, 1.76, 0.07), cf(0.42, 0.04, -0.59), C.BRASS, M.METAL, A),
		rbox("Sash", v(2.26, 0.44, 1.26), cf(0, -0.72, 0), C.RED, M.FABRIC, nil, 0.16),
		egg("SashKnot", v(0.3, 0.26, 0.2), cf(-0.66, -0.72, -0.66), C.RED, M.FABRIC),
		plate("SashTail", v(-0.6, -0.8, -0.68), v(-0.56, -1.4, -0.7), 0.2, 0.04, C.RED, M.FABRIC),
		plate("SashTail", v(-0.74, -0.8, -0.68), v(-0.82, -1.3, -0.7), 0.18, 0.04, C.RED, M.FABRIC),
		plate("Bandolier", v(0.96, 0.96, -0.64), v(-0.9, -0.5, -0.64), 0.16, 0.04, C.LEATHER, M.LEATHER),
		torus("Rope", v(0.62, 0.11, 0.62), cf(1.17, -0.62, 0.0, 0, 0, 90), C.ROPE, M.FABRIC),
	}
	for i = 0, 4 do   -- stripes round the shirt
		B.join(out, hoop("Stripe", 2.1, 1.12, 0.2, 0.84 - i * 0.3, 0.12, C.CLOTH, M.FABRIC, P))
	end
	for i = 0, 2 do   -- little pouches on the bandolier
		local p = v(0.96, 0.96, -0.64):Lerp(v(-0.9, -0.5, -0.64), 0.22 + i * 0.24)
		out[#out + 1] = rbox("Pouch", v(0.2, 0.22, 0.14), CFrame.new(p + Vector3.new(0, 0, -0.07)) * CFrame.Angles(0, 0, math.rad(38)), C.DARKLEATHER, M.LEATHER, nil, 0.04)
	end
	return out
end
-- Night Hunters: a black jack with a high collar, a short shoulder cape, crossed straps of throwing knives
local function hunterTorso()
	local out = {middle(TORSO),
		rbox("Jack", v(2.16, 2.08, 1.16), cf(), C.CLOTH, M.FABRIC, P, 0.22),
		cone("Collar", v(1.5, 0.36, 1.38), cf(0, 1.08, 0.02), C.CLOTH, M.FABRIC, P, 0.92),
		tbox("Mantlet", v(2.36, 0.44, 1.36), cf(0, 0.84, 0.02), 0.84, C.CLOTH2, M.FABRIC, S, 0.22),
		tbox("MantletHem", v(2.42, 0.18, 1.42), cf(0, 0.58, 0.02), 0.97, C.CLOTH2, M.FABRIC, S, 0.2),
		plate("Strap", v(-0.9, 0.5, -0.62), v(0.86, -0.7, -0.62), 0.17, 0.04, C.BLACK, M.LEATHER),
		plate("Strap", v(0.9, 0.5, -0.62), v(-0.86, -0.7, -0.62), 0.17, 0.04, C.BLACK, M.LEATHER),
		torus("StrapRing", v(0.24, 0.05, 0.24), cf(0, -0.1, -0.665, 90, 0, 0), C.IRON, M.METAL, MT),
	}
	B.join(out, hoop("Seam", 2.16, 1.16, 0.22, -0.3, 0.04, C.CLOTH2, M.FABRIC, S))
	for i = 0, 2 do   -- throwing knives along the left strap
		local p = v(-0.9, 0.5, -0.62):Lerp(v(0.86, -0.7, -0.62), 0.12 + i * 0.13)
		out[#out + 1] = rbox("KnifeSheath", v(0.13, 0.36, 0.08), CFrame.new(p + Vector3.new(0, 0, -0.06)) * CFrame.Angles(0, 0, math.rad(56)), C.DARKLEATHER, M.LEATHER, nil, 0.03)
		out[#out + 1] = box("KnifeHilt", v(0.07, 0.16, 0.06), CFrame.new(p + Vector3.new(-0.17, 0.12, -0.07)) * CFrame.Angles(0, 0, math.rad(56)), C.IRON, M.METAL, MT)
	end
	return B.join(out, belt(-0.74, C.IRON, true, C.BLACK))
end
-- the starter medium top: a quilted gambeson over mail, the mail showing at the hem
local function gambesonTorso(col, quilt)
	local out = {middle(TORSO),
		rbox("Gambeson", v(2.18, 2.08, 1.18), cf(), col, M.FABRIC, P, 0.26),
		cone("Collar", v(1.5, 0.26, 1.36), cf(0, 1.04, 0.02), col, M.FABRIC, P, 0.88),
		tbox("Skirt", v(2.26, 0.46, 1.26), cf(0, -1.18, 0), 0.97, col, M.FABRIC, P, 0.22),
		tbox("MailHem", v(2.32, 0.18, 1.32), cf(0, -1.47, 0), 0.98, C.MAIL, M.PLATE, nil, 0.2),
		box("Placket", v(0.06, 1.9, 0.04), cf(-0.04, 0, -0.605), quilt, M.FABRIC, S),
	}
	for i = 0, 4 do B.join(out, hoop("Quilt", 2.18, 1.18, 0.26, -0.8 + i * 0.4, 0.045, quilt, M.FABRIC, S)) end
	for _, x in ipairs({-0.62, -0.3, 0.3, 0.62}) do
		out[#out + 1] = box("Quilt", v(0.045, 1.96, 0.04), cf(x, 0, -0.605), quilt, M.FABRIC, S)
	end
	for i = 0, 3 do out[#out + 1] = ball("Toggle", 0.12, cf(0.06, 0.74 - i * 0.38, -0.62), C.BRASS, M.METAL, A) end
	return out
end
-- Sellswords: a leather brigandine studded with iron, one iron shoulder and one leather, a field sign across the chest
local function sellswordTorso()
	local out = J({middle(TORSO),
		rbox("Brigandine", v(2.18, 2.06, 1.18), cf(), C.LEATHER, M.LEATHER, nil, 0.24),
		tbox("MailHem", v(2.3, 0.26, 1.3), cf(0, -1.16, 0), 0.97, C.MAIL, M.PLATE, nil, 0.2),
		cone("MailCollar", v(1.46, 0.24, 1.32), cf(0, 1.04, 0.02), C.MAIL, M.PLATE, nil, 0.9),
		egg("Spaulder", v(1.16, 0.56, 1.3), cf(-1.4, 0.94, 0.02, 0, 0, 8), C.DARKLEATHER, M.LEATHER),
		egg("Spaulder", v(1.06, 0.38, 1.24), cf(-1.48, 0.68, 0.02, 0, 0, 14), C.DARKLEATHER, M.LEATHER),
		plate("FieldSign", v(-0.96, 0.96, -0.67), v(0.9, -0.62, -0.67), 0.3, 0.04, C.CLOTH, M.FABRIC, P),
	}, pauldron(1, C.IRON, M.METAL, MT), belt(-0.8, C.IRON, true))
	for r = 0, 4 do for col = 0, 4 do
		out[#out + 1] = ball("Rivet", 0.1, cf(-0.8 + col * 0.4, 0.78 - r * 0.36, -0.6), C.IRON, M.METAL, MT)
	end end
	for r = 0, 3 do for col = 0, 3 do
		out[#out + 1] = ball("Rivet", 0.1, cf(-0.6 + col * 0.4, 0.7 - r * 0.4, 0.6), C.IRON, M.METAL, MT)
	end end
	return out
end
-- River Guard: a quilted surcoat over mail, waves on the breast, small steel shoulders, a baldric
local function guardTorso()
	local out = J({middle(TORSO),
		rbox("Mail", v(2.12, 2.06, 1.14), cf(), C.MAIL, M.PLATE, nil, 0.2),
		rbox("Jupon", v(2.2, 1.84, 1.22), cf(0, 0.04, 0), C.CLOTH, M.FABRIC, P, 0.26),
		tbox("MailHem", v(2.28, 0.3, 1.28), cf(0, -1.12, 0), 0.96, C.MAIL, M.PLATE, nil, 0.2),
		plate("Baldric", v(0.96, 0.96, -0.665), v(-0.92, -0.84, -0.665), 0.16, 0.04, C.DARKLEATHER, M.LEATHER),
	}, spaulder(-1, C.STEEL, C.BRASS), spaulder(1, C.STEEL, C.BRASS), tabard(0, "waves", C.WHITE, false, -0.625))
	for _, x in ipairs({-0.75, -0.45, 0.45, 0.75}) do
		out[#out + 1] = box("Quilt", v(0.04, 1.7, 0.04), cf(x, 0.04, -0.625), C.CLOTH2, M.FABRIC, S)
	end
	for i = 0, 7 do   -- the scalloped hem
		out[#out + 1] = egg("Scallop", v(0.3, 0.2, 0.08), cf(-0.96 + i * 0.274, -0.88, -0.62), C.CLOTH, M.FABRIC, P)
		out[#out + 1] = egg("Scallop", v(0.3, 0.2, 0.08), cf(-0.96 + i * 0.274, -0.88, 0.62), C.CLOTH, M.FABRIC, P)
	end
	return B.join(out, belt(-0.6, C.BRASS))
end
-- the Gilded Court: velvet brigandine with gilt studs, gold-edged pauldrons, tassets, a half-cape, a gold chain
local function courtTorso()
	local out = J({middle(TORSO),
		rbox("Brigandine", v(2.18, 2.06, 1.18), cf(), C.CLOTH, M.FABRIC, P, 0.24),
		cone("Collar", v(1.48, 0.24, 1.34), cf(0, 1.04, 0.02), C.CLOTH, M.FABRIC, P, 0.9),
		egg("HalfCapeFold", v(1.3, 0.34, 0.5), cf(-0.48, 0.96, 0.56), C.CLOTH2, M.FABRIC, S),
		plate("HalfCape", v(-0.48, 1.0, 0.66), v(-0.48, -1.2, 0.86), 1.2, 0.07, C.CLOTH2, M.FABRIC, S, -X, 0.03),
		box("CapeEdge", v(1.22, 0.07, 0.1), cf(-0.48, -1.16, 0.875, -5, 0, 0), C.GOLD, M.METAL, A),
		ball("CapeClasp", 0.16, cf(-0.84, 0.94, -0.6), C.GOLD, M.METAL, A),
	}, pauldron(-1, C.STEEL, M.METAL, MT, nil, C.GOLD), pauldron(1, C.STEEL, M.METAL, MT, nil, C.GOLD), belt(-0.76, C.GOLD))
	for r = 0, 4 do for col = 0, 4 do
		out[#out + 1] = ball("Stud", 0.1, cf(-0.8 + col * 0.4, 0.74 - r * 0.32, -0.6), C.GOLD, M.METAL, A)
	end end
	for _, s in ipairs({-1, 1}) do   -- tassets over the thighs
		out[#out + 1] = plate("Tasset", v(s * 0.52, -0.9, -0.66), v(s * 0.58, -1.5, -0.72), 0.82, 0.08, C.STEEL, M.METAL, MT, nil, 0.04)
		out[#out + 1] = plate("TassetEdge", v(s * 0.58, -1.47, -0.735), v(s * 0.585, -1.53, -0.74), 0.86, 0.06, C.GOLD, M.METAL, A)
	end
	for i = 0, 12 do   -- the chain, shoulder to shoulder
		local a = math.rad(-60 + i * 10)
		out[#out + 1] = ball("Chain", 0.1, cf(math.sin(a) * 0.78, 0.98 - math.cos(a) * 0.44, -0.6 - math.cos(a) * 0.04), C.GOLD, M.METAL, A)
	end
	out[#out + 1] = cyl("Medal", 0.26, 0.05, cf(0, 0.47, -0.66, 90, 0, 0), C.GOLD, M.METAL, A)
	return out
end
-- Wolf Company: grey mail under a great fur mantle, a necklace of wolf teeth, a tail at the hip
local function wolfTorso()
	local out = J({middle(TORSO),
		rbox("Mail", v(2.14, 2.06, 1.14), cf(), C.MAIL, M.PLATE, nil, 0.2),
		tbox("MailHem", v(2.3, 0.34, 1.3), cf(0, -1.14, 0), 0.96, C.MAIL, M.PLATE, nil, 0.2),
		rbox("Corslet", v(2.2, 1.0, 1.2), cf(0, -0.3, 0), C.DARKLEATHER, M.LEATHER, nil, 0.24),
		egg("Mantle", v(2.74, 0.9, 1.72), cf(0, 0.92, 0.02), C.FUR, M.FABRIC),
		egg("Mantle", v(2.2, 1.3, 0.5), cf(0, 0.3, 0.64), C.FUR, M.FABRIC),
		egg("Paw", v(0.3, 0.62, 0.2), cf(-0.42, 0.26, -0.68, 0, 0, 12), C.FUR, M.FABRIC),
		egg("Paw", v(0.3, 0.62, 0.2), cf(0.42, 0.26, -0.68, 0, 0, -12), C.FUR, M.FABRIC),
		egg("Tail", v(0.3, 0.9, 0.3), cf(1.0, -1.02, 0.2, 0, 0, 8), C.FUR, M.FABRIC),
		ball("TailTip", 0.24, cf(1.04, -1.42, 0.2), Color3.fromRGB(70, 58, 46), M.FABRIC),
	}, belt(-0.76, C.IRON))
	for i = 0, 6 do   -- the teeth, on a cord
		local a = math.rad(-36 + i * 12)
		local p = Vector3.new(math.sin(a) * 0.66, 0.62 - math.cos(a) * 0.12, -0.7)
		out[#out + 1] = spike("Tooth", p, p + Vector3.new(0, -0.2, -0.02), 0.08, FANG, M.PLASTIC)
	end
	return out
end

-- the heavy sets' plate
local function knightTorso()
	return J(cuirass(C.STEEL, C.IRON), pauldron(-1, C.STEEL, M.METAL, MT), pauldron(1, C.STEEL, M.METAL, MT),
		{rbox("SwordBelt", v(2.4, 0.14, 1.4), cf(0, -0.86, 0.02, 0, 0, 6), C.DARKLEATHER, M.LEATHER, nil, 0.06)})
end
-- Tourney Knight: jousting plate — a grand guard over the left shoulder and breast, a lance rest, a quartered tabard
local function tourneyTorso()
	local out = J(cuirass(C.STEEL, C.GOLD, {plackart = true}), tabard(1.5, "quarters"), pauldron(1, C.STEEL, M.METAL, MT, "haute", C.GOLD), {
		egg("GrandGuard", v(1.3, 1.5, 0.52), cf(-0.6, 0.5, -0.62, 0, -16, 0), C.STEEL, M.METAL, MT),
		egg("GrandGuardEdge", v(1.36, 1.56, 0.48), cf(-0.6, 0.49, -0.6, 0, -16, 0), C.GOLD, M.METAL, A),
		egg("GrandGuard", v(1.34, 0.86, 1.52), cf(-1.36, 0.96, 0.0, 0, 0, 8), C.STEEL, M.METAL, MT),
		egg("Lame", v(1.12, 0.4, 1.3), cf(-1.5, 0.6, 0.02, 0, 0, 14), C.STEEL, M.METAL, MT),
		rbox("LanceRest", v(0.36, 0.14, 0.3), cf(0.7, 0.24, -0.84), C.IRON, M.METAL, nil, 0.04),
		rbox("LanceRest", v(0.12, 0.3, 0.12), cf(0.7, 0.36, -0.74), C.IRON, M.METAL, nil, 0.03),
	}, belt(-0.76))
	for i = 0, 3 do out[#out + 1] = ball("Rivet", 0.09, cf(-0.92 + i * 0.22, 1.12 - i * 0.06, -0.7), C.GOLD, M.METAL, A) end
	return out
end
-- the Iron Crow: black plate under a mantle of crow feathers, a crow's skull on the breast, a mail skirt
local function crowTorso()
	local out = J(cuirass(C.BLACKIRON, C.IRON, {smooth = true}), {
		tbox("MailSkirt", v(2.34, 0.56, 1.34), cf(0, -1.28, 0.02), 0.95, C.MAIL, M.PLATE, nil, 0.2),
		egg("CrowSkull", v(0.3, 0.26, 0.24), cf(0, 0.34, -0.72), BONE, M.PLASTIC),
		spike("CrowBeak", v(0, 0.3, -0.78), v(0, 0.12, -0.88), 0.16, FEATHER, M.PLASTIC),
		ball("CrowEye", 0.06, cf(-0.08, 0.38, -0.83), C.BLACK, M.PLASTIC),
		ball("CrowEye", 0.06, cf(0.08, 0.38, -0.83), C.BLACK, M.PLASTIC),
		rod("Cord", v(-0.3, 0.92, -0.62), v(0, 0.48, -0.7), 0.04, C.DARKLEATHER, M.LEATHER),
		rod("Cord", v(0.3, 0.92, -0.62), v(0, 0.48, -0.7), 0.04, C.DARKLEATHER, M.LEATHER),
	})
	-- the mantle: three rings of long feathers lying down over the shoulders, back and breast
	for ringI, r in ipairs({{0.84, 1.22, 0.62, 18}, {0.68, 1.12, 0.52, 16}, {0.5, 0.98, 0.42, 12}}) do
		local y, rx, len, n = r[1], r[2], r[3], r[4]
		for i = 0, n - 1 do
			local a = (i + (ringI % 2) * 0.5) / n * math.pi * 2
			local outward = Vector3.new(math.sin(a), 0, -math.cos(a) * 0.62).Unit
			local base = Vector3.new(math.sin(a) * rx, y + 0.3, 0.02 - math.cos(a) * rx * 0.62)
			local tip = base + outward * 0.22 + Vector3.new(0, -len, 0)
			out[#out + 1] = egg("Feather", v(0.2, len + 0.1, 0.06), (span(base, tip)), FEATHER, M.FABRIC)
		end
	end
	return out
end
-- the Blackguard: jet plate laced with red cords, spiked shoulders, a red cross, a tattered cape
local function blackguardTorso()
	local out = J(cuirass(C.BLACKIRON, C.RED, {plackart = true}), tabard(1.6, "cross", C.RED),
		pauldron(-1, C.BLACKIRON, M.METAL, MT, "spikes", C.RED), pauldron(1, C.BLACKIRON, M.METAL, MT, "spikes", C.RED),
		cape(C.BLACK, nil, true), belt(-0.76, C.IRON))
	for _, s in ipairs({-1, 1}) do   -- red cords laced up the sides of the breast
		for i = 0, 3 do
			out[#out + 1] = box("Cord", v(0.3, 0.05, 0.04), cf(s * 0.86, 0.66 - i * 0.24, -0.62, 0, 0, i % 2 == 0 and 30 or -30), C.RED, M.FABRIC)
		end
	end
	return out
end
-- the Knights of the Sun: bright fluted plate with a gilt sunburst on the breast, sun-disc shoulders, tassets, a white cape
local function sunTorso()
	local breast = {c = v(0, 0.32, -0.48), s = v(2.0, 1.5, 0.32)}
	local out = J(cuirass(C.BRIGHT, C.GOLD, {plackart = true, smooth = true}),
		pauldron(-1, C.BRIGHT, M.METAL, MT, "sun", C.GOLD), pauldron(1, C.BRIGHT, M.METAL, MT, "sun", C.GOLD),
		cape(C.WHITE, nil, false, C.GOLD), belt(-0.76, C.GOLD))
	for _, x in ipairs({-0.62, -0.42, 0.42, 0.62}) do   -- the fluting
		B.join(out, column("Flute", breast, x, 0.78, -0.12, 0.05, C.BRIGHT, M.METAL, MT, 0.025))
	end
	local p, n = front(breast, 0, 0.36)
	out[#out + 1] = disc("Sun", p, n, 0.42, 0.06, C.GOLD, M.METAL, A, 0.05)
	for i = 0, 11 do   -- the sunburst's rays
		local a = i / 12 * math.pi * 2
		local r = i % 2 == 0 and 0.36 or 0.31
		local q, nq = front(breast, math.cos(a) * r, 0.36 + math.sin(a) * r)
		out[#out + 1] = lay(box("SunRay", v(0.07, i % 2 == 0 and 0.22 or 0.14, 0.06), nil, C.GOLD, M.METAL, A), q, nq, 0.035, math.deg(a) - 90)
	end
	for _, s in ipairs({-1, 1}) do
		out[#out + 1] = plate("Tasset", v(s * 0.52, -0.9, -0.66), v(s * 0.58, -1.5, -0.72), 0.82, 0.08, C.BRIGHT, M.METAL, MT, nil, 0.04)
		out[#out + 1] = plate("TassetEdge", v(s * 0.58, -1.47, -0.735), v(s * 0.585, -1.53, -0.74), 0.86, 0.06, C.GOLD, M.METAL, A)
	end
	return out
end

--------------------------------------------------------------------
--  ARMS (arm frame: shoulder at +1, hand at -1, the elbow's point at +Z)
--------------------------------------------------------------------
local function arm(...) return B.join({middle(LIMB)}, ...) end
local function sleeve(color, slot, mat, top, bottom)   -- cloth from `top` down to `bottom`
	top, bottom = top or 1.0, bottom or -0.7
	return {rbox("Sleeve", v(1.1, top - bottom, 1.1), cf(0, (top + bottom) / 2, 0), color, mat or M.FABRIC, slot, 0.18)}
end
local function mailSleeve(bottom)
	bottom = bottom or -0.7
	return {rbox("Mail", v(1.1, 1 - bottom, 1.1), cf(0, (1 + bottom) / 2, 0), C.MAIL, M.PLATE, nil, 0.18),
		rbox("MailCuff", v(1.16, 0.12, 1.16), cf(0, bottom + 0.06, 0), C.MAIL, M.PLATE, nil, 0.18)}
end
local function cuffBand(y, color, slot, h, mat)
	return rbox("Cuff", v(1.2, h or 0.2, 1.2), cf(0, y, 0), color, mat or M.FABRIC, slot, 0.2)
end
local function glove(color, mat)
	local col = color or C.LEATHER
	return {rbox("Glove", v(1.1, 0.42, 1.12), cf(0, -0.8, 0), col, mat or M.LEATHER, nil, 0.16),
		rbox("GloveCuff", v(1.22, 0.2, 1.22), cf(0, -0.56, 0), col, mat or M.LEATHER, nil, 0.18)}
end
local function bracer(color, top, bottom, laces)
	top, bottom = top or -0.06, bottom or -0.62
	local out = {rbox("Bracer", v(1.16, top - bottom, 1.16), cf(0, (top + bottom) / 2, 0), color or C.LEATHER, M.LEATHER, nil, 0.2)}
	if laces ~= false then
		for i = 0, 2 do
			out[#out + 1] = box("Lace", v(0.42, 0.04, 0.03), cf(0, top - 0.14 - i * (top - bottom - 0.2) / 2, -0.595, 0, 0, i % 2 == 0 and 18 or -18), C.LINEN, M.FABRIC)
		end
	end
	return out
end
-- full plate, joint to joint: rerebrace, two lames at the bend, a couter with its wing, vambrace,
-- and a gauntlet — a flared cuff, the back of the hand, knuckles, finger lames.
-- o = {elbow = accent color, gauntlet = accent color, flutes, spike, talons, cords = color}
local function plateArm(s, m, trim, o)
	o = o or {}
	local elbow, eslot = o.elbow or m, o.elbow and A or MT
	local gaunt, gslot = o.gauntlet or m, o.gauntlet and A or MT
	local out = {
		rbox("Rerebrace", v(1.14, 0.8, 1.14), cf(0, 0.6, 0), m, M.METAL, MT, 0.2),
		rbox("Lame", v(1.18, 0.12, 1.18), cf(0, 0.17, 0), m, M.METAL, MT, 0.2),
		rbox("Lame", v(1.16, 0.12, 1.16), cf(0, 0.06, 0), m, M.METAL, MT, 0.2),
		egg("Couter", v(0.8, 0.66, 0.66), cf(0, 0.04, 0.44), elbow, M.METAL, eslot),
		egg("CouterWing", v(0.14, 0.64, 0.7), cf(s * 0.57, 0.04, 0.2), elbow, M.METAL, eslot),
		rbox("Vambrace", v(1.12, 0.62, 1.12), cf(0, -0.32, 0), m, M.METAL, MT, 0.2),
		tbox("Cuff", v(1.16, 0.24, 1.16), cf(0, -0.68, 0), 1.12, gaunt, M.METAL, gslot, 0.18),
		rbox("Gauntlet", v(1.1, 0.3, 1.12), cf(0, -0.88, 0), gaunt, M.METAL, gslot, 0.14),
	}
	if o.talons then   -- claws over the knuckles
		for i = -1, 1 do
			out[#out + 1] = spike("Talon", v(i * 0.3, -0.92, -0.5), v(i * 0.34, -1.08, -0.78), 0.14, m, M.METAL, MT)
		end
	else
		for i = 0, 2 do
			out[#out + 1] = rbox("Finger", v(1.08 - i * 0.03, 0.07, 0.62), cf(0, -0.99 - i * 0.065, -0.22), m, M.METAL, MT, 0.03)
		end
	end
	for i = -1, 1 do out[#out + 1] = ball("Knuckle", 0.1, cf(i * 0.3, -0.84, -0.57), gaunt, M.METAL, gslot) end
	if trim then
		out[#out + 1] = rbox("Trim", v(1.17, 0.05, 1.17), cf(0, 0.22, 0), trim, M.METAL, A, 0.2)
		out[#out + 1] = rbox("Trim", v(1.15, 0.05, 1.15), cf(0, -0.6, 0), trim, M.METAL, A, 0.2)
	end
	if o.flutes then
		for _, x in ipairs({-0.3, -0.1, 0.1, 0.3}) do
			out[#out + 1] = box("Flute", v(0.05, 0.62, 0.05), cf(x, 0.62, -0.585), m, M.METAL, MT)
			out[#out + 1] = box("Flute", v(0.05, 0.46, 0.05), cf(x, -0.32, -0.575), m, M.METAL, MT)
		end
	end
	if o.spike then out[#out + 1] = spike("CouterSpike", v(0, 0.04, 0.72), v(0, 0.08, 1.06), 0.18, elbow, M.METAL, eslot) end
	if o.cords then
		for i = 0, 2 do
			out[#out + 1] = box("Cord", v(0.36, 0.045, 0.04), cf(0, -0.14 - i * 0.14, -0.58, 0, 0, i % 2 == 0 and 26 or -26), o.cords, M.FABRIC)
		end
	end
	return out
end

--------------------------------------------------------------------
--  LEGS (leg frame: hip at +1, foot at -1, the knee's point at -Z)
--------------------------------------------------------------------
local function leg(...) return B.join({middle(LIMB)}, ...) end
local function hose(color, slot, top, bottom, mat)
	top, bottom = top or 1.0, bottom or -1.0
	return {rbox("Hose", v(1.08, top - bottom, 1.08), cf(0, (top + bottom) / 2, 0), color, mat or M.FABRIC, slot, 0.16)}
end
local function mailChausses() return {rbox("Chausses", v(1.1, 2.0, 1.1), cf(), C.MAIL, M.PLATE, nil, 0.18)} end
local function boot(color, top, cuff)
	local c = color or C.DARKLEATHER
	top = top or -0.4
	local out = {rbox("Boot", v(1.14, top + 1.0, 1.16), cf(0, (top - 1.0) / 2, -0.02), c, M.LEATHER, nil, 0.18),
		egg("Toe", v(0.96, 0.36, 0.66), cf(0, -0.82, -0.44), c, M.LEATHER),
		rbox("Sole", v(1.16, 0.08, 1.36), cf(0, -0.96, -0.14), C.BLACK, M.PLASTIC, nil, 0.03)}
	if cuff then out[#out + 1] = rbox("BootCuff", v(1.26, 0.26, 1.26), cf(0, top - 0.06, -0.02), c, M.LEATHER, nil, 0.2) end
	return out
end
local function wraps(color, n, y0, step, slot)   -- cloth bands wound round, tilted by turns
	local out = {}
	for i = 0, (n or 4) - 1 do
		out[#out + 1] = rbox("Wrap", v(1.14, 0.15, 1.14), cf(0, (y0 or -0.8) + i * (step or 0.3), 0, 0, 0, (i % 2 == 0) and 6 or -6), color or C.LINEN, M.FABRIC, slot, 0.18)
	end
	return out
end
-- half armor: a knee cop and a greave
local function kneeGreave(m, knee, kslot)
	return {egg("Poleyn", v(0.7, 0.58, 0.5), cf(0, 0.02, -0.48), knee or m, M.METAL, kslot or MT),
		rbox("Greave", v(1.14, 0.74, 1.14), cf(0, -0.42, 0), m, M.METAL, MT, 0.2),
		box("Keel", v(0.06, 0.6, 0.04), cf(0, -0.42, -0.585), m, M.METAL, MT)}
end
-- full plate, joint to joint: cuisse, a lame behind the knee, a poleyn with its wing, greave,
-- sabatons and a toe. o = {knee, foot = accent colors, toe = "pointed" | "bear" | "talons", flutes, spike}
local function plateLeg(s, m, trim, o)
	o = o or {}
	local knee, kslot = o.knee or m, o.knee and A or MT
	local foot, fslot = o.foot or m, o.foot and A or MT
	local out = {
		rbox("Cuisse", v(1.14, 0.9, 1.14), cf(0, 0.54, 0), m, M.METAL, MT, 0.2),
		rbox("Lame", v(1.16, 0.12, 1.16), cf(0, 0.04, 0), m, M.METAL, MT, 0.2),
		egg("Poleyn", v(0.74, 0.6, 0.5), cf(0, 0.02, -0.48), knee, M.METAL, kslot),
		egg("PoleynWing", v(0.14, 0.6, 0.6), cf(s * 0.56, 0.02, -0.26), knee, M.METAL, kslot),
		rbox("Greave", v(1.14, 0.76, 1.14), cf(0, -0.4, 0), m, M.METAL, MT, 0.2),
	}
	if o.flutes then
		for _, x in ipairs({-0.3, -0.1, 0.1, 0.3}) do
			out[#out + 1] = box("Flute", v(0.05, 0.7, 0.05), cf(x, 0.56, -0.585), m, M.METAL, MT)
			out[#out + 1] = box("Flute", v(0.05, 0.56, 0.05), cf(x, -0.42, -0.585), m, M.METAL, MT)
		end
	else
		out[#out + 1] = box("Keel", v(0.06, 0.74, 0.04), cf(0, 0.56, -0.585), m, M.METAL, MT)
		out[#out + 1] = box("Keel", v(0.06, 0.6, 0.04), cf(0, -0.42, -0.585), m, M.METAL, MT)
	end
	for i = 0, 2 do   -- sabaton lames stepping down over the foot
		out[#out + 1] = rbox("Sabaton", v(1.16 - i * 0.04, 0.12, 1.18 - i * 0.12), cf(0, -0.83 - i * 0.055, -0.06 - i * 0.07), foot, M.METAL, fslot, 0.05)
	end
	if o.toe == "pointed" then
		out[#out + 1] = cone("Poulaine", v(0.66, 0.66, 0.2), cf(0, -0.92, -0.5) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.new(0, 0.33, 0), foot, M.METAL, fslot)
	elseif o.toe == "bear" then
		out[#out + 1] = egg("Bearpaw", v(1.24, 0.24, 0.68), cf(0, -0.88, -0.48), foot, M.METAL, fslot)
	elseif o.toe == "talons" then
		out[#out + 1] = egg("Toe", v(0.9, 0.22, 0.56), cf(0, -0.89, -0.44), foot, M.METAL, fslot)
		for i = -1, 1 do
			out[#out + 1] = spike("Talon", v(i * 0.26, -0.9, -0.6), v(i * 0.36, -0.96, -0.96), 0.15, foot, M.METAL, fslot)
		end
		out[#out + 1] = spike("Spur", v(0, -0.86, 0.5), v(0, -0.92, 0.78), 0.12, foot, M.METAL, fslot)
	else
		out[#out + 1] = egg("Toe", v(0.9, 0.24, 0.6), cf(0, -0.88, -0.46), foot, M.METAL, fslot)
	end
	if trim then
		out[#out + 1] = rbox("Trim", v(1.17, 0.05, 1.17), cf(0, 0.1, 0), trim, M.METAL, A, 0.2)
		out[#out + 1] = rbox("Trim", v(1.17, 0.05, 1.17), cf(0, -0.76, 0), trim, M.METAL, A, 0.2)
	end
	if o.spike then out[#out + 1] = spike("KneeSpike", v(0, 0.02, -0.7), v(0, 0.06, -1.02), 0.2, knee, M.METAL, kslot) end
	return out
end

--------------------------------------------------------------------
--  THE TWELVE RELEASE SETS (ServerStorage ▸ Armor ▸ <Set>)
--------------------------------------------------------------------
local function set(head, torso, armFn, legFn)
	local la, ra = pair(armFn)
	local ll, rl = pair(legFn)
	return {HeadClothing = head, TorsoClothing = torso, LeftArmClothing = la, RightArmClothing = ra, LeftLegClothing = ll, RightLegClothing = rl}
end

-- LIGHT ---------------------------------------------------------------
A_.RoadLevy = set(mailCoif(), levyTorso(),
	function() return arm(sleeve(C.LINEN, nil), wraps(C.DARKLEATHER, 3, -0.6, 0.2), glove(C.LEATHER)) end,
	function(s) return leg(hose(C.CLOTH2, S),
		{egg("KneePatch", v(0.56, 0.5, 0.2), cf(0, 0.02, -0.52), C.LEATHER, M.LEATHER),
		 rbox("Garter", v(1.16, 0.08, 1.16), cf(0, -0.3, 0), C.DARKLEATHER, M.LEATHER, nil, 0.18),
		 box("GarterTie", v(0.08, 0.2, 0.06), cf(s * 0.5, -0.4, -0.56), C.DARKLEATHER, M.LEATHER)},
		boot(C.DARKLEATHER, -0.56, true)) end)

A_.MarshWardens = set(wardenHood(), wardenTorso(),
	function(s) return arm(sleeve(C.GREEN, P), bracer(C.DARKLEATHER, s < 0 and 0.14 or -0.12, -0.62), glove(C.DARKLEATHER)) end,
	function(s) return leg(hose(C.CLOTH2, S),   -- waders up the thigh
		{rbox("Wader", v(1.16, 1.4, 1.18), cf(0, -0.3, -0.02), C.DARKLEATHER, M.LEATHER, nil, 0.2),
		 rbox("WaderTop", v(1.26, 0.22, 1.28), cf(0, 0.42, -0.02), C.LEATHER, M.LEATHER, nil, 0.2),
		 box("WaderStrap", v(0.1, 0.5, 0.06), cf(s * 0.62, 0.68, -0.1), C.DARKLEATHER, M.LEATHER),
		 rbox("Buckle", v(0.16, 0.16, 0.05), cf(s * 0.64, 0.5, -0.1), C.BRASS, M.METAL, A, 0.02),
		 egg("Toe", v(0.96, 0.36, 0.66), cf(0, -0.82, -0.44), C.DARKLEATHER, M.LEATHER),
		 rbox("Sole", v(1.16, 0.08, 1.36), cf(0, -0.96, -0.14), C.BLACK, M.PLASTIC, nil, 0.03)}) end)

A_.CoastHarriers = set(seaCap(), harrierTorso(),
	function() return arm(
		{tbox("Sleeve", v(1.2, 1.1, 1.2), cf(0, 0.45, 0), 0.94, C.LINEN, M.FABRIC, nil, 0.2)},
		hoop("Stripe", 1.17, 1.17, 0.2, 0.78, 0.1, C.CLOTH, M.FABRIC, P), hoop("Stripe", 1.19, 1.19, 0.2, 0.5, 0.1, C.CLOTH, M.FABRIC, P),
		hoop("Stripe", 1.2, 1.2, 0.2, 0.22, 0.1, C.CLOTH, M.FABRIC, P),
		{cuffBand(-0.12, C.LINEN, nil, 0.2), rbox("WristGuard", v(1.16, 0.3, 1.16), cf(0, -0.62, 0), C.LEATHER, M.LEATHER, nil, 0.2)}) end,
	function() return leg(
		{tbox("Breeches", v(1.24, 1.08, 1.24), cf(0, 0.46, 0), 0.92, C.CLOTH, M.FABRIC, P, 0.24),
		 rbox("BreechCuff", v(1.28, 0.16, 1.28), cf(0, -0.1, 0), C.CLOTH2, M.FABRIC, S, 0.2)},
		hose(C.LINEN, nil, -0.1, -0.8),
		hoop("Stripe", 1.08, 1.08, 0.16, -0.3, 0.09, C.CLOTH2, M.FABRIC, S), hoop("Stripe", 1.08, 1.08, 0.16, -0.55, 0.09, C.CLOTH2, M.FABRIC, S),
		{rbox("Shoe", v(1.12, 0.3, 1.2), cf(0, -0.86, -0.06), C.BLACK, M.LEATHER, nil, 0.12),
		 egg("Toe", v(0.9, 0.26, 0.5), cf(0, -0.88, -0.48), C.BLACK, M.LEATHER),
		 rbox("Buckle", v(0.32, 0.2, 0.05), cf(0, -0.76, -0.66), C.BRASS, M.METAL, A, 0.03)}) end)

A_.NightHunters = set(headWrap(), hunterTorso(),
	function() return arm(sleeve(C.CLOTH, P), bracer(C.BLACK, 0.0, -0.62, false),
		{rbox("Strap", v(1.2, 0.06, 1.2), cf(0, -0.12, 0), C.DARKLEATHER, M.LEATHER, nil, 0.2),
		 rbox("Strap", v(1.2, 0.06, 1.2), cf(0, -0.32, 0), C.DARKLEATHER, M.LEATHER, nil, 0.2),
		 rbox("Strap", v(1.2, 0.06, 1.2), cf(0, -0.52, 0), C.DARKLEATHER, M.LEATHER, nil, 0.2)}, glove(C.BLACK)) end,
	function(s)
		local out = leg(hose(C.CLOTH, P), boot(C.BLACK, -0.08),
			{rbox("Strap", v(1.2, 0.06, 1.22), cf(0, -0.2, -0.02), C.DARKLEATHER, M.LEATHER, nil, 0.2),
			 rbox("Strap", v(1.2, 0.06, 1.22), cf(0, -0.4, -0.02), C.DARKLEATHER, M.LEATHER, nil, 0.2),
			 rbox("Strap", v(1.2, 0.06, 1.22), cf(0, -0.6, -0.02), C.DARKLEATHER, M.LEATHER, nil, 0.2)})
		if s > 0 then   -- a knife strapped to the right thigh
			B.join(out, {rbox("Sheath", v(0.16, 0.6, 0.12), cf(0.62, 0.42, -0.2), C.BLACK, M.LEATHER, nil, 0.04),
				rod("Hilt", v(0.62, 0.72, -0.2), v(0.62, 0.94, -0.2), 0.08, C.IRON, M.METAL, MT),
				rbox("ThighStrap", v(1.2, 0.07, 1.2), cf(0, 0.5, 0), C.DARKLEATHER, M.LEATHER, nil, 0.18)})
		end
		return out
	end)

-- MEDIUM --------------------------------------------------------------
-- mercenaries in odds and ends: one arm and one leg iron, the others leather
A_.Sellswords = set(barbute(), sellswordTorso(),
	function(s)
		if s > 0 then return arm(mailSleeve(-0.1), plateArm(s, C.IRON)) end
		return arm(mailSleeve(-0.2), bracer(C.DARKLEATHER, -0.1, -0.6), glove(C.DARKLEATHER),
			{rbox("Armband", v(1.18, 0.22, 1.18), cf(0, 0.44, 0), C.CLOTH, M.FABRIC, P, 0.18)})
	end,
	function(s)
		if s < 0 then return leg(mailChausses(), {egg("Poleyn", v(0.7, 0.58, 0.5), cf(0, 0.02, -0.48), C.IRON, M.METAL, MT)}, boot(C.DARKLEATHER, -0.4, true)) end
		return leg(hose(C.LEATHER, nil, 1.0, -1.0, M.LEATHER), kneeGreave(C.IRON), boot(C.DARKLEATHER, -0.72))
	end)

A_.RiverGuard = set(aventailBascinet(), guardTorso(),
	function(s) return arm(mailSleeve(-0.6),
		{egg("Couter", v(0.76, 0.62, 0.64), cf(0, 0.04, 0.44), C.STEEL, M.METAL, MT),
		 egg("CouterWing", v(0.12, 0.58, 0.62), cf(s * 0.57, 0.04, 0.2), C.STEEL, M.METAL, MT),
		 rbox("Vambrace", v(1.14, 0.56, 1.14), cf(0, -0.32, 0), C.STEEL, M.METAL, MT, 0.2)},
		glove(C.DARKLEATHER)) end,
	function() return leg(
		{rbox("Cuisse", v(1.16, 0.96, 1.16), cf(0, 0.5, 0), C.CLOTH, M.FABRIC, P, 0.2),
		 box("Quilt", v(0.04, 0.9, 0.04), cf(-0.22, 0.5, -0.595), C.CLOTH2, M.FABRIC, S),
		 box("Quilt", v(0.04, 0.9, 0.04), cf(0.22, 0.5, -0.595), C.CLOTH2, M.FABRIC, S)},
		hose(C.CLOTH2, S, 0.1, -0.6), kneeGreave(C.STEEL), boot(C.DARKLEATHER, -0.74)) end)

A_.GildedCourt = set(burgonet(), courtTorso(),
	function(s) return arm(
		{egg("Puff", v(1.3, 0.62, 1.3), cf(0, 0.72, 0), C.CLOTH, M.FABRIC, P),
		 box("Slash", v(0.08, 0.5, 0.04), cf(-0.18, 0.72, -0.64), C.CLOTH2, M.FABRIC, S),
		 box("Slash", v(0.08, 0.5, 0.04), cf(0.18, 0.72, -0.64), C.CLOTH2, M.FABRIC, S)},
		{rbox("Rerebrace", v(1.12, 0.42, 1.12), cf(0, 0.3, 0), C.STEEL, M.METAL, MT, 0.2),
		 egg("Couter", v(0.76, 0.6, 0.64), cf(0, 0.04, 0.44), C.STEEL, M.METAL, MT),
		 egg("CouterWing", v(0.12, 0.58, 0.62), cf(s * 0.57, 0.04, 0.2), C.GOLD, M.METAL, A),
		 rbox("Vambrace", v(1.12, 0.6, 1.12), cf(0, -0.32, 0), C.STEEL, M.METAL, MT, 0.2),
		 tbox("Cuff", v(1.16, 0.24, 1.16), cf(0, -0.68, 0), 1.12, C.GOLD, M.METAL, A, 0.18),
		 rbox("Glove", v(1.1, 0.34, 1.12), cf(0, -0.86, 0), C.DARKLEATHER, M.LEATHER, nil, 0.14)}) end,
	function(s) return leg(hose(C.CLOTH, P, 1.0, -0.2),
		{egg("Poleyn", v(0.7, 0.54, 0.48), cf(0, 0.14, -0.48), C.STEEL, M.METAL, MT),
		 disc("KneeRondel", v(0, 0.14, -0.71), -Z, 0.36, 0.05, C.GOLD, M.METAL, A, 0.03),
		 rbox("Boot", v(1.16, 1.04, 1.18), cf(0, -0.5, -0.02), C.BLACK, M.LEATHER, nil, 0.2),
		 tbox("BootCuff", v(1.2, 0.36, 1.22), cf(0, 0.0, -0.02), 1.14, C.BLACK, M.LEATHER, nil, 0.2),
		 egg("Toe", v(0.94, 0.34, 0.64), cf(0, -0.83, -0.44), C.BLACK, M.LEATHER),
		 rbox("Sole", v(1.16, 0.08, 1.36), cf(0, -0.96, -0.14), C.BLACK, M.PLASTIC, nil, 0.03),
		 box("Spur", v(0.08, 0.08, 0.3), cf(s * 0.3, -0.78, 0.66), C.GOLD, M.METAL, A)}) end)

A_.WolfCompany = set(wolfHelm(), wolfTorso(),
	function() return arm(mailSleeve(-0.3),
		{egg("Couter", v(0.76, 0.62, 0.64), cf(0, 0.04, 0.44), C.IRON, M.METAL, MT)},
		bracer(C.DARKLEATHER, -0.2, -0.62, false),
		{rbox("FurCuff", v(1.3, 0.2, 1.3), cf(0, -0.16, 0), C.FUR, M.FABRIC, nil, 0.22)},
		glove(C.DARKLEATHER)) end,
	function()
		local out = leg(hose(C.DARKLEATHER, nil, 1.0, -0.2, M.LEATHER), kneeGreave(C.IRON),
			{egg("FurBoot", v(1.36, 0.5, 1.38), cf(0, -0.7, -0.02), C.FUR, M.FABRIC),
			 egg("Toe", v(0.96, 0.32, 0.62), cf(0, -0.84, -0.44), C.DARKLEATHER, M.LEATHER),
			 rbox("Sole", v(1.16, 0.08, 1.36), cf(0, -0.96, -0.14), C.BLACK, M.PLASTIC, nil, 0.03)})
		for i = 0, 3 do   -- cross-gartering up the thigh
			out[#out + 1] = box("Garter", v(1.2, 0.06, 0.04), cf(0, 0.14 + i * 0.22, -0.56, 0, 0, i % 2 == 0 and 22 or -22), C.LEATHER, M.LEATHER)
		end
		return out
	end)

-- HEAVY ---------------------------------------------------------------
A_.TourneyKnight = set(frogMouth(), tourneyTorso(),
	function(s) return arm(sleeve(C.CLOTH2, S, nil, 1.0, -0.6), plateArm(s, C.STEEL, C.GOLD)) end,
	function(s) return leg(hose(C.CLOTH2, S), plateLeg(s, C.STEEL, C.GOLD, {toe = "pointed"})) end)

A_.IronCrow = set(hounskull(), crowTorso(),
	function(s) return arm(sleeve(C.BLACK, nil, nil, 1.0, -0.6), plateArm(s, C.BLACKIRON, nil, {talons = true}),
		{egg("Feather", v(0.18, 0.5, 0.06), cf(s * 0.3, 0.08, 0.66, -30, 0, s * 12), FEATHER, M.FABRIC),
		 egg("Feather", v(0.18, 0.46, 0.06), cf(s * 0.1, 0.04, 0.7, -34, 0, s * 4), FEATHER, M.FABRIC)}) end,
	function(s) return leg(mailChausses(), plateLeg(s, C.BLACKIRON, nil, {toe = "talons"})) end)

A_.Blackguard = set(hornedHelm(), blackguardTorso(),
	function(s) return arm(sleeve(C.BLACK, nil, nil, 1.0, -0.6), plateArm(s, C.BLACKIRON, C.RED, {elbow = C.RED, spike = true, cords = C.RED})) end,
	function(s) return leg(hose(C.BLACK), plateLeg(s, C.BLACKIRON, C.RED, {knee = C.RED, spike = true})) end)

A_.SunKnights = set(sunArmet(), sunTorso(),
	function(s) return arm(sleeve(C.CLOTH2, S, nil, 1.0, -0.6), plateArm(s, C.BRIGHT, C.GOLD, {elbow = C.GOLD, gauntlet = C.GOLD, flutes = true})) end,
	function(s) return leg(hose(C.CLOTH2, S), plateLeg(s, C.BRIGHT, C.GOLD, {knee = C.GOLD, foot = C.GOLD, toe = "bear", flutes = true})) end)

-- the three starter sets (the free kit of each weight)
A_.KnightSkin = set(closeHelm(), knightTorso(),
	function(s) return arm(sleeve(C.CLOTH2, S, nil, 1.0, -0.6), plateArm(s, C.STEEL)) end,
	function(s) return leg(hose(C.CLOTH2, S), plateLeg(s, C.STEEL)) end)

A_.GambesonSkin = set(cappedCoif(), J(gambesonTorso(C.CLOTH, C.CLOTH2), belt(-0.76)),
	function()
		local out = arm(sleeve(C.CLOTH, P, nil, 1.0, -0.56), mailSleeve(-0.62), glove(C.LEATHER))
		for i = 0, 3 do B.join(out, hoop("Quilt", 1.1, 1.1, 0.18, 0.78 - i * 0.36, 0.04, C.CLOTH2, M.FABRIC, S)) end
		return out
	end,
	function() return leg(hose(C.CLOTH2, S, 1.0, -0.5),
		{box("Quilt", v(0.04, 1.36, 0.04), cf(-0.2, 0.25, -0.555), C.CLOTH, M.FABRIC, P),
		 box("Quilt", v(0.04, 1.36, 0.04), cf(0.2, 0.25, -0.555), C.CLOTH, M.FABRIC, P),
		 egg("KneePad", v(0.66, 0.56, 0.36), cf(0, 0.0, -0.5), C.CLOTH, M.FABRIC, P)},
		boot(C.DARKLEATHER, -0.5, true)) end)

A_.PeasantSkin = set(strawHat(), peasantTorso(),
	function() return arm(sleeve(C.LINEN, P, nil, 1.0, 0.04), {cuffBand(0.04, C.LINEN, S, 0.24)}) end,
	function() return leg(
		{rbox("Trousers", v(1.14, 1.4, 1.14), cf(0, 0.3, 0), C.CLOTH2, M.FABRIC, S, 0.2),
		 rbox("Roll", v(1.22, 0.2, 1.22), cf(0, -0.38, 0), C.CLOTH2, M.FABRIC, S, 0.2)},
		wraps(C.LINEN, 3, -0.7, 0.16),
		{rbox("Shoe", v(1.1, 0.34, 1.18), cf(0, -0.84, -0.06), C.LEATHER, M.LEATHER, nil, 0.14),
		 egg("Toe", v(0.86, 0.28, 0.5), cf(0, -0.87, -0.46), C.LEATHER, M.LEATHER),
		 rbox("Lace", v(1.14, 0.05, 1.22), cf(0, -0.7, -0.06), C.DARKLEATHER, M.LEATHER, nil, 0.14)}) end)

--------------------------------------------------------------------
--  EARNED PIECES (Cosmetics ▸ Pieces ▸ <id>: only that slot's models)
--------------------------------------------------------------------
A_.PIECES = {}
A_.PIECES.WolfPeltHood = {HeadClothing = wolfPelt()}
A_.PIECES.BloodiedKettle = {HeadClothing = bloodiedKettle()}
A_.PIECES.DuelistsSallet = {HeadClothing = duelistSallet()}
A_.PIECES.ChampionsGreatHelm = {HeadClothing = sugarloaf()}
do   -- Runner's Wraps: wound tight from ankle to hip, crossed, over light strapped shoes
	local ll, rl = pair(function()
		local out = leg(hose(C.CLOTH2, S))
		for i = 0, 7 do
			out[#out + 1] = rbox("Wrap", v(1.14, 0.12, 1.14), cf(0, -0.72 + i * 0.22, 0, 0, 0, i % 2 == 0 and 12 or -12), C.LINEN, M.FABRIC, nil, 0.18)
		end
		return B.join(out, {rbox("Sole", v(1.14, 0.1, 1.34), cf(0, -0.95, -0.12), C.LEATHER, M.LEATHER, nil, 0.04),
			egg("Toe", v(0.86, 0.24, 0.46), cf(0, -0.88, -0.48), C.LINEN, M.FABRIC),
			rbox("Strap", v(1.18, 0.06, 1.3), cf(0, -0.84, -0.12), C.DARKLEATHER, M.LEATHER, nil, 0.1),
			box("Strap", v(0.06, 0.06, 0.5), cf(0, -0.88, -0.6), C.DARKLEATHER, M.LEATHER)})
	end)
	A_.PIECES.RunnersWraps = {LeftLegClothing = ll, RightLegClothing = rl}
end
do   -- Hunter's Cloak: a long fur-collared cloak over a jerkin, a horn at the hip, a game bag
	local la, ra = pair(function() return arm(sleeve(C.CLOTH2, S), bracer(C.DARKLEATHER, 0.0, -0.66), glove(C.LEATHER)) end)
	A_.PIECES.HuntersCloak = {TorsoClothing = J({middle(TORSO),
		rbox("Jerkin", v(2.16, 2.06, 1.16), cf(), C.CLOTH2, M.FABRIC, S, 0.22),
		tbox("JerkinSkirt", v(2.28, 0.4, 1.28), cf(0, -1.12, 0), 0.96, C.CLOTH2, M.FABRIC, S, 0.2),
		plate("Cloak", v(0, 1.02, 0.64), v(0, -1.58, 0.9), 2.2, 0.08, C.CLOTH, M.FABRIC, P, -X, 0.03),
		tbox("FurCollar", v(2.44, 0.5, 1.46), cf(0, 0.92, 0.04), 0.86, C.FUR, M.FABRIC, nil, 0.24),
		plate("Baldric", v(-0.96, 0.96, -0.64), v(0.92, -0.62, -0.64), 0.14, 0.04, C.DARKLEATHER, M.LEATHER),
		spike("Horn", v(0.68, -0.48, -0.68), v(1.12, -0.26, -0.52), 0.3, HORN, M.PLASTIC),
		torus("HornBand", v(0.3, 0.05, 0.3), CFrame.new(0.76, -0.44, -0.65) * CFrame.Angles(0, 0, math.rad(64)), C.BRASS, M.METAL, A),
		rbox("GameBag", v(0.56, 0.5, 0.26), cf(-0.74, -0.96, -0.52), C.LEATHER, M.LEATHER, nil, 0.1),
		rbox("GameBagFlap", v(0.58, 0.2, 0.28), cf(-0.74, -0.78, -0.53), C.DARKLEATHER, M.LEATHER, nil, 0.06),
	}, belt(-0.66)), LeftArmClothing = la, RightArmClothing = ra}
end
do   -- Sergeant's Surcoat: a long surcoat with a broad band over mail, belted high
	local la, ra = pair(function() return arm(mailSleeve(-0.5), bracer(C.LEATHER, -0.3, -0.66, false), glove(C.DARKLEATHER)) end)
	A_.PIECES.SergeantsSurcoat = {TorsoClothing = J({middle(TORSO),
		rbox("Mail", v(2.12, 2.06, 1.14), cf(), C.MAIL, M.PLATE, nil, 0.2),
		cone("MailCollar", v(1.46, 0.24, 1.32), cf(0, 1.04, 0.02), C.MAIL, M.PLATE, nil, 0.9),
		rbox("Surcoat", v(1.64, 1.5, 1.24), cf(0, 0.2, 0), C.CLOTH, M.FABRIC, P, 0.2),
		tbox("Surcoat", v(2.32, 1.0, 1.32), cf(0, -1.08, 0), 0.92, C.CLOTH, M.FABRIC, P, 0.2),
	}, tabard(1.0, "stripe", C.GOLD, true), belt(-0.5)), LeftArmClothing = la, RightArmClothing = ra}
end
do   -- Banneret's Tabard: plate under a long heraldic surcoat with a chevron, a gold livery collar
	local la, ra = pair(function(s) return arm(sleeve(C.CLOTH2, S, nil, 1.0, -0.6), plateArm(s, C.STEEL, C.GOLD),
		{tbox("SurcoatSleeve", v(1.36, 0.46, 1.36), cf(0, 0.74, 0), 0.86, C.CLOTH, M.FABRIC, P, 0.22)}) end)
	local out = J(cuirass(C.STEEL, C.GOLD), tabard(2.4, "chevron", C.GOLD, true),
		pauldron(-1, C.STEEL, M.METAL, MT, nil, C.GOLD), pauldron(1, C.STEEL, M.METAL, MT, nil, C.GOLD), belt(-0.7, C.GOLD))
	for i = 0, 14 do   -- the livery collar: links of gold over the shoulders
		local a = math.rad(-70 + i * 10)
		out[#out + 1] = egg("Link", v(0.14, 0.1, 0.14), cf(math.sin(a) * 0.86, 1.0 - math.cos(a) * 0.5, -0.64 - math.cos(a) * 0.08), C.GOLD, M.METAL, A)
	end
	out[#out + 1] = disc("Pendant", v(0, 0.46, -0.76), -Z, 0.24, 0.05, C.GOLD, M.METAL, A, 0.03)
	A_.PIECES.BanneretsTabard = {TorsoClothing = out, LeftArmClothing = la, RightArmClothing = ra}
end
do   -- Veteran's Chausses: scarred mail, steel knees and greaves, iron sabatons strapped on
	local ll, rl = pair(function(s) return leg(mailChausses(), kneeGreave(C.IRON),
		{egg("PoleynWing", v(0.12, 0.56, 0.56), cf(s * 0.56, 0.02, -0.26), C.IRON, M.METAL, MT),
		 rbox("Sabaton", v(1.16, 0.14, 1.2), cf(0, -0.83, -0.06), C.IRON, M.METAL, MT, 0.06),
		 rbox("Sabaton", v(1.12, 0.12, 1.06), cf(0, -0.91, -0.14), C.IRON, M.METAL, MT, 0.05),
		 egg("Toe", v(0.9, 0.24, 0.56), cf(0, -0.89, -0.46), C.IRON, M.METAL, MT),
		 rbox("Strap", v(1.2, 0.06, 1.2), cf(0, 0.36, 0), C.DARKLEATHER, M.LEATHER, nil, 0.18),
		 rbox("Strap", v(1.18, 0.06, 1.18), cf(0, -0.62, 0), C.DARKLEATHER, M.LEATHER, nil, 0.18),
		 box("Scar", v(0.3, 0.04, 0.04), cf(0.1, -0.36, -0.6, 0, 0, 30), C.DARKSTEEL, M.METAL)}) end)
	A_.PIECES.VeteransChausses = {LeftLegClothing = ll, RightLegClothing = rl}
end

return A_
