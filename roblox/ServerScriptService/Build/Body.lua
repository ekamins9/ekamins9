--[[ BODY BLUEPRINTS — hair and beards around the head (the sources of the
     Body meshes: scripts/export_blueprints.lua → blender/parts2mesh.py, and
     the fallback where no model exists). Each is a spec list in the HEAD's
     frame: Middle = the 2×1×1 head part at the origin. The visible R6 head is
     a round drum 1.25 across with rounded rims (face at z = -0.625, crown at
     y = +0.625; the eyes sit about +0.15, the mouth about -0.25), so hair is a
     bowl spun to the head's own profile, with locks, tails and buns laid on
     it, and a beard hangs below the mouth and climbs the cheeks.
     Hair and beard parts take the player's hair color unless they carry
     attribute KeepColor = true. Ids match Catalog ▸ Body:
     hair Cropped SweptBack LongTied BowlCut Tonsure ShavedSides Topknot WildMane
     BraidedCrown · beards Stubble Full Goatee MuttonChops Braided Forked.
     Faces are Decal textures, not parts (Cosmetics ▸ Body ▸ Face, drawn by
     blender/faces.py). ]]

local B = require(script.Parent:WaitForChild("Builder"))
local C, M = B.C, B.M
local cf, v = B.cf, B.v
local Body = {Hair = {}, Beard = {}, Face = {}}

local H = C.HAIR
local KEEP = {KeepColor = true}
local egg, ball = B.egg, B.ball
local function middle() return B.box("Middle", v(2, 1, 1), cf(), C.WHITE, M.PLASTIC, nil, {transparency = 1, shadow = false}) end
local function J(...) return B.join({}, ...) end

-- the head's profile {radius, y} and the outward way at each point: hair lies `lift` off it
local PROFILE = {{0.625, 0.35, 1, 0}, {0.615, 0.43, 0.96, 0.28}, {0.585, 0.5, 0.84, 0.54}, {0.52, 0.565, 0.63, 0.78},
	{0.42, 0.61, 0.35, 0.94}, {0.3, 0.625, 0.1, 1}, {0.0, 0.625, 0, 1}}
-- a bowl of hair over the crown, down to `rim` all round, standing `lift` off the head
local function bowl(rim, lift, name)
	local pf = {{0.6, rim - 0.02}, {0.625 + lift, rim}}
	for _, p in ipairs(PROFILE) do
		if p[2] > rim then pf[#pf + 1] = {p[1] + p[3] * lift, p[2] + p[4] * lift} end
	end
	return B.lathe(name or "Bowl", pf, cf(), H, M.PLASTIC)
end
-- the back of the head down to the nape (and round to the temples), behind the face
local function back(low, lift)
	low, lift = low or -0.3, lift or 0.04
	local h = 0.6 - low
	return {egg("Back", v(1.26 + lift * 2, h, 0.76), cf(0, (0.6 + low) / 2, 0.28), H, M.PLASTIC),
		egg("Temple", v(0.14, 0.42, 0.52), cf(-0.61, 0.28, 0.16), H, M.PLASTIC),
		egg("Temple", v(0.14, 0.42, 0.52), cf(0.61, 0.28, 0.16), H, M.PLASTIC)}
end
-- a lock of hair: an egg laid from a toward b
local function lock(a, b, w, t, name)
	local mid, d = (a + b) / 2, b - a
	local up = math.abs(d.Unit.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
	local frame = CFrame.lookAt(mid, b, up) * CFrame.Angles(-math.pi / 2, 0, 0)
	return egg(name or "Lock", v(w, d.Magnitude, t), frame, H, M.PLASTIC)
end
-- a tail of hair through points, thinning to its tip
local function tail(pts, r0, r1, name)
	local out = {}
	for i = 1, #pts - 1 do
		local f = (i - 1) / math.max(1, #pts - 2)
		local d = r0 + (r1 - r0) * f
		out[#out + 1] = lock(pts[i], pts[i + 1], d, d * 0.9, name or "Tail")
	end
	return out
end
-- a braid: overlapping lobes down a line, alternately tilted
local function braid(a, b, n, w, name)
	local out = {}
	for i = 0, n - 1 do
		local p = a:Lerp(b, (i + 0.5) / n)
		local d = (b - a).Unit
		local up = math.abs(d.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
		out[#out + 1] = egg(name or "Braid", v(w, (b - a).Magnitude / n * 1.5, w * 0.8),
			CFrame.lookAt(p, p + d, up) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.Angles(0, 0, math.rad(i % 2 == 0 and 24 or -24)), H, M.PLASTIC)
	end
	return out
end
local function fringe(n, y, z, droop)   -- short locks falling over the brow
	local out = {}
	for i = 0, n - 1 do
		local x = -0.42 + 0.84 * (n == 1 and 0.5 or i / (n - 1))
		local zz = z - 0.06 * math.cos(x * 2)
		out[#out + 1] = lock(Vector3.new(x * 0.9, y + 0.12, zz + 0.06), Vector3.new(x, y - droop, zz), 0.26, 0.12, "Fringe")
	end
	return out
end

--------------------------------------------------------------------
--  HAIR
--------------------------------------------------------------------
-- short and neat, a little fringe, the back trimmed to the nape
Body.Hair.Cropped = J({middle(), bowl(0.36, 0.045)}, back(-0.2, 0.03), fringe(4, 0.42, -0.62, 0.06))

-- thick on top and combed back over the crown, long at the nape
Body.Hair.SweptBack = J({middle(), bowl(0.38, 0.06),
	egg("Sweep", v(1.08, 0.34, 1.36), cf(0, 0.66, 0.16, 12, 0, 0), H, M.PLASTIC),
	egg("Sweep", v(0.86, 0.28, 0.9), cf(0, 0.6, -0.36, -6, 0, 0), H, M.PLASTIC),
	lock(Vector3.new(-0.5, 0.5, -0.3), Vector3.new(-0.6, 0.36, 0.42), 0.24, 0.12),
	lock(Vector3.new(0.5, 0.5, -0.3), Vector3.new(0.6, 0.36, 0.42), 0.24, 0.12)}, back(-0.42, 0.05))

-- long hair gathered at the back into a tail and tied
Body.Hair.LongTied = J({middle(), bowl(0.36, 0.05)}, back(-0.36, 0.05),
	tail({Vector3.new(0, 0.18, 0.66), Vector3.new(0, -0.2, 0.8), Vector3.new(0, -0.62, 0.84), Vector3.new(0, -1.02, 0.76)}, 0.34, 0.18),
	{B.torus("Tie", v(0.34, 0.08, 0.3), CFrame.new(0, 0.1, 0.7) * CFrame.Angles(math.rad(-20), 0, 0), C.ROPE, M.FABRIC, KEEP)})

-- a round bowl cut straight across the brow
Body.Hair.BowlCut = {middle(), bowl(0.26, 0.08),
	B.torus("Rim", v(1.48, 0.13, 1.48), cf(0, 0.28, 0), H, M.PLASTIC)}

-- a monk's ring of hair round a shaven crown
Body.Hair.Tonsure = J({middle(),
	B.lathe("Ring", {{0.6, 0.16}, {0.675, 0.18}, {0.685, 0.3}, {0.67, 0.42}, {0.6, 0.5}, {0.56, 0.51}}, cf(), H, M.PLASTIC)},
	back(-0.22, 0.03))

-- the sides shaved, a crest standing from brow to nape
Body.Hair.ShavedSides = {middle(),
	egg("Crest", v(0.36, 0.6, 1.44), cf(0, 0.7, 0.0), H, M.PLASTIC),
	egg("Crest", v(0.32, 0.4, 0.5), cf(0, 0.36, 0.6, 20, 0, 0), H, M.PLASTIC),
	egg("Crest", v(0.26, 0.3, 0.36), cf(0, 0.08, 0.66, 30, 0, 0), H, M.PLASTIC)}

-- hair pulled up into a knot on the crown
Body.Hair.Topknot = J({middle(), bowl(0.38, 0.045),
	egg("Knot", v(0.46, 0.4, 0.46), cf(0, 0.86, 0.14), H, M.PLASTIC),
	egg("Knot", v(0.3, 0.26, 0.3), cf(0, 1.06, 0.14), H, M.PLASTIC),
	B.torus("Tie", v(0.4, 0.07, 0.4), cf(0, 0.72, 0.14), C.ROPE, M.FABRIC, KEEP)}, back(-0.16, 0.03))

-- a great shaggy mane, curls all over and down the neck
do
	local out = {middle(), bowl(0.34, 0.08)}
	local curls = {{-0.46, 0.66, -0.34}, {0.0, 0.74, -0.42}, {0.46, 0.66, -0.34}, {-0.62, 0.52, 0.12}, {0.62, 0.52, 0.12},
		{-0.3, 0.8, 0.12}, {0.3, 0.8, 0.12}, {0.0, 0.76, 0.48}, {-0.5, 0.4, 0.52}, {0.5, 0.4, 0.52}, {0.0, 0.3, 0.74},
		{-0.66, 0.16, 0.24}, {0.66, 0.16, 0.24}, {-0.34, -0.14, 0.64}, {0.34, -0.14, 0.64}, {0.0, -0.36, 0.7}}
	for i, p in ipairs(curls) do
		out[#out + 1] = ball("Curl", 0.5 + (i % 3) * 0.06, cf(p[1], p[2], p[3]), H, M.PLASTIC)
	end
	B.join(out, back(-0.5, 0.08), fringe(5, 0.44, -0.66, 0.12))
	Body.Hair.WildMane = out
end

-- braids wound round the head like a crown, a bead at each end
do
	local out = J({middle(), bowl(0.38, 0.045)}, back(-0.2, 0.03))
	local pts = {}
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		pts[#pts + 1] = Vector3.new(math.sin(a) * 0.66, 0.5 + 0.04 * math.sin(a * 2), -math.cos(a) * 0.66)
	end
	for i = 1, 16 do
		local a, b = pts[i], pts[i % 16 + 1]
		local d = (b - a).Unit
		out[#out + 1] = egg("Braid", v(0.2, (b - a).Magnitude * 1.5, 0.16), CFrame.lookAt((a + b) / 2, b, Vector3.yAxis) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.Angles(0, 0, math.rad(i % 2 == 0 and 26 or -26)), H, M.PLASTIC)
	end
	B.join(out, braid(Vector3.new(-0.5, 0.3, 0.5), Vector3.new(-0.56, -0.5, 0.62), 5, 0.18), braid(Vector3.new(0.5, 0.3, 0.5), Vector3.new(0.56, -0.5, 0.62), 5, 0.18),
		{ball("Bead", 0.16, cf(-0.56, -0.58, 0.62), C.BRASS, M.METAL, KEEP), ball("Bead", 0.16, cf(0.56, -0.58, 0.62), C.BRASS, M.METAL, KEEP),
		 ball("Bead", 0.12, cf(0, 0.54, -0.68), C.BRASS, M.METAL, KEEP)})
	Body.Hair.BraidedCrown = out
end

--------------------------------------------------------------------
--  HAIR, the second wave: bigger shapes with more going on (no mesh yet:
--  Blueprints builds them from these specs)
--------------------------------------------------------------------
-- a spike of hair: a cone from its foot a to its point b, d across at the foot
local function spike(a, b, d, name)
	local mid, dv = (a + b) / 2, b - a
	local up = math.abs(dv.Unit.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
	local frame = CFrame.lookAt(mid, b, up) * CFrame.Angles(-math.pi / 2, 0, 0)
	return {kind = "cone", name = name or "Spike", size = v(d, dv.Magnitude, d * 0.8), cf = frame, color = H, material = M.PLASTIC, top = 0}
end
-- a point on the head's dome at a yaw (0 = the face, + = the head's left) and an elevation, pushed out by lift
local function onDome(yaw, elev, lift)
	local r = 0.66 + (lift or 0)
	return Vector3.new(math.sin(yaw) * math.cos(elev) * r, 0.2 + math.sin(elev) * 0.62 * (r / 0.66), -math.cos(yaw) * math.cos(elev) * r)
end

-- spiky: a crown of spikes standing up and out, longest over the brow
do
	local out = J({middle(), bowl(0.32, 0.07)}, back(-0.28, 0.05))
	for i = 0, 8 do
		local yaw = math.rad(-150 + i * 37.5)
		local a = onDome(yaw, math.rad(38), 0.02)
		local dir = (a - Vector3.new(0, 0.1, 0)).Unit + Vector3.new(0, 0.55, 0)
		local len = 0.55 + 0.25 * math.cos(yaw) ^ 2
		out[#out + 1] = spike(a, a + dir.Unit * len, 0.34)
	end
	for i = 0, 4 do
		local yaw = math.rad(-120 + i * 60)
		local a = onDome(yaw, math.rad(66), 0.02)
		local dir = (a - Vector3.new(0, 0.1, 0)).Unit + Vector3.new(0, 0.9, 0)
		out[#out + 1] = spike(a, a + dir.Unit * 0.62, 0.36)
	end
	out[#out + 1] = spike(Vector3.new(0, 0.82, 0.06), Vector3.new(0, 1.42, 0.24), 0.4)
	Body.Hair.Spiky = out
end

-- a mohawk: the sides shorn close, a tall crest of spikes from brow to nape
do
	local out = {middle(), bowl(0.3, 0.012, "Shorn")}
	for i = 0, 7 do
		local t = i / 7
		local z = -0.5 + t * 1.12
		local y = 0.55 + math.sin(t * math.pi) * 0.1 - math.max(0, t - 0.75) * 0.6
		local foot = Vector3.new(0, y, z)
		local h = 0.48 + math.sin(t * math.pi) * 0.34
		out[#out + 1] = spike(foot, foot + Vector3.new(0, h, 0.14 + t * 0.12), 0.32, "Crest")
	end
	Body.Hair.Mohawk = out
end

-- a swoop: one big sweep of a fringe across the brow, the sides short
Body.Hair.Swoop = J({middle(), bowl(0.3, 0.05)}, back(-0.22, 0.03), {
	lock(Vector3.new(-0.56, 0.66, -0.2), Vector3.new(0.5, 0.34, -0.66), 0.5, 0.2, "Swoop"),
	lock(Vector3.new(-0.4, 0.74, 0.0), Vector3.new(0.6, 0.44, -0.5), 0.4, 0.18, "Swoop"),
	lock(Vector3.new(-0.2, 0.76, 0.3), Vector3.new(0.66, 0.5, -0.1), 0.34, 0.16, "Swoop"),
	egg("SwoopTip", v(0.24, 0.16, 0.2), cf(0.56, 0.3, -0.64, 0, 0, -30), H, M.PLASTIC),
})

-- a high ponytail that springs up off the crown and falls down the back
Body.Hair.Ponytail = J({middle(), bowl(0.36, 0.05)}, back(-0.24, 0.04), fringe(3, 0.44, -0.62, 0.05),
	tail({Vector3.new(0, 0.62, 0.48), Vector3.new(0, 0.82, 0.8), Vector3.new(0, 0.5, 1.06), Vector3.new(0, 0.0, 1.06), Vector3.new(0, -0.48, 0.9)}, 0.4, 0.16),
	{B.torus("Tie", v(0.36, 0.08, 0.36), CFrame.new(0, 0.66, 0.56) * CFrame.Angles(math.rad(-50), 0, 0), C.RED, M.FABRIC, KEEP)})

-- twin tails, one either side, tied high
do
	local out = J({middle(), bowl(0.36, 0.05)}, back(-0.2, 0.03), fringe(4, 0.44, -0.62, 0.08))
	for _, s in ipairs({-1, 1}) do
		B.join(out, tail({Vector3.new(s * 0.56, 0.5, 0.2), Vector3.new(s * 0.86, 0.46, 0.3), Vector3.new(s * 1.0, 0.0, 0.32), Vector3.new(s * 0.96, -0.56, 0.26)}, 0.36, 0.14),
			{B.torus("Tie", v(0.3, 0.08, 0.3), CFrame.new(s * 0.62, 0.5, 0.22) * CFrame.Angles(0, 0, math.rad(s * 70)), C.RED, M.FABRIC, KEEP)})
	end
	Body.Hair.TwinTails = out
end

-- an afro: a big round crown of curls
do
	local out = {middle()}
	local n = 0
	for ring = 0, 4 do
		local elev = math.rad(-20 + ring * 26)
		local count = math.max(1, math.floor(12 * math.cos(elev)))
		for i = 0, count - 1 do
			local yaw = (i + ring * 0.5) / count * math.pi * 2
			local p = Vector3.new(math.sin(yaw) * math.cos(elev) * 0.9, 0.42 + math.sin(elev) * 0.78, 0.12 - math.cos(yaw) * math.cos(elev) * 0.84)
			-- (none in front of the face)
			if not (p.Z < -0.35 and p.Y < 0.42) then
				n += 1
				out[#out + 1] = ball("Curl", 0.5 + (n % 3) * 0.07, CFrame.new(p), H, M.PLASTIC)
			end
		end
	end
	out[#out + 1] = ball("Curl", 0.8, cf(0, 1.06, 0.12), H, M.PLASTIC)
	Body.Hair.Afro = out
end

-- a man bun: slicked back into a knot at the back of the crown
Body.Hair.ManBun = J({middle(), bowl(0.36, 0.045),
	egg("Slick", v(1.06, 0.26, 1.3), cf(0, 0.64, 0.12, 10, 0, 0), H, M.PLASTIC),
	ball("Bun", 0.5, cf(0, 0.64, 0.7), H, M.PLASTIC),
	ball("Bun", 0.34, cf(0.04, 0.74, 0.84), H, M.PLASTIC),
	B.torus("Tie", v(0.42, 0.07, 0.42), CFrame.new(0, 0.62, 0.6) * CFrame.Angles(math.rad(-70), 0, 0), C.DARKLEATHER, M.FABRIC, KEEP)}, back(-0.22, 0.03))

-- curtains: parted in the middle, falling either side of the brow
Body.Hair.Curtains = J({middle(), bowl(0.3, 0.06)}, back(-0.42, 0.05), {
	lock(Vector3.new(-0.06, 0.7, -0.38), Vector3.new(-0.58, 0.12, -0.5), 0.46, 0.16, "Curtain"),
	lock(Vector3.new(0.06, 0.7, -0.38), Vector3.new(0.58, 0.12, -0.5), 0.46, 0.16, "Curtain"),
	lock(Vector3.new(-0.2, 0.74, 0.0), Vector3.new(-0.68, 0.0, -0.1), 0.4, 0.16, "Curtain"),
	lock(Vector3.new(0.2, 0.74, 0.0), Vector3.new(0.68, 0.0, -0.1), 0.4, 0.16, "Curtain"),
})

-- long and flowing: down past the shoulders, locks falling in front of them too
do
	local out = J({middle(), bowl(0.34, 0.06)}, back(-0.9, 0.07), fringe(3, 0.46, -0.62, 0.06))
	for _, s in ipairs({-1, 1}) do
		out[#out + 1] = lock(Vector3.new(s * 0.62, 0.34, -0.1), Vector3.new(s * 0.78, -0.9, -0.12), 0.4, 0.2, "Flow")
		out[#out + 1] = lock(Vector3.new(s * 0.6, 0.3, 0.2), Vector3.new(s * 0.86, -1.0, 0.3), 0.36, 0.2, "Flow")
	end
	for i = -2, 2 do
		out[#out + 1] = lock(Vector3.new(i * 0.24, 0.4, 0.6), Vector3.new(i * 0.32, -1.1 - math.abs(i) * 0.04, 0.76), 0.36, 0.18, "Flow")
	end
	Body.Hair.LongFlowing = out
end

-- viking braids: the sides shorn, a crest on top, a long braid down the back and two at the temples
do
	local out = {middle(), bowl(0.3, 0.012, "Shorn"),
		egg("Crest", v(0.52, 0.32, 1.38), cf(0, 0.66, 0.08), H, M.PLASTIC)}
	B.join(out, braid(Vector3.new(0, 0.42, 0.64), Vector3.new(0, -1.1, 0.86), 9, 0.3),
		braid(Vector3.new(-0.6, 0.2, 0.0), Vector3.new(-0.66, -0.74, -0.08), 5, 0.2),
		braid(Vector3.new(0.6, 0.2, 0.0), Vector3.new(0.66, -0.74, -0.08), 5, 0.2),
		{ball("Bead", 0.18, cf(0, -1.18, 0.88), C.BRASS, M.METAL, KEEP), ball("Bead", 0.15, cf(-0.67, -0.82, -0.08), C.BRASS, M.METAL, KEEP),
		 ball("Bead", 0.15, cf(0.67, -0.82, -0.08), C.BRASS, M.METAL, KEEP)})
	Body.Hair.VikingBraids = out
end

-- dreadlocks: thick locks hanging all round, tied back off the face
do
	local out = J({middle(), bowl(0.36, 0.06)}, back(-0.3, 0.05))
	for i = 0, 13 do
		local yaw = math.rad(-110 + i * (220 / 13))
		local a = onDome(yaw + math.pi, math.rad(20), 0.03)   -- (round the sides and back, none over the face)
		local hang = 0.7 + (i % 3) * 0.18
		B.join(out, tail({a, a + Vector3.new(a.X * 0.18, -hang * 0.5, a.Z * 0.12), a + Vector3.new(a.X * 0.26, -hang, a.Z * 0.2)}, 0.2, 0.15, "Dread"))
	end
	out[#out + 1] = B.torus("Band", v(1.4, 0.1, 1.4), cf(0, 0.36, 0.04), C.RED, M.FABRIC, KEEP)
	Body.Hair.Dreadlocks = out
end

--------------------------------------------------------------------
--  BEARDS (below the mouth and up the cheeks; a moustache over the lip)
--------------------------------------------------------------------
local function moustache(droop, w)
	w = w or 0.38
	return {lock(Vector3.new(-0.02, -0.15, -0.67), Vector3.new(-w, -0.22 - droop, -0.6), 0.2, 0.15, "Moustache"),
		lock(Vector3.new(0.02, -0.15, -0.67), Vector3.new(w, -0.22 - droop, -0.6), 0.2, 0.15, "Moustache")}
end
local function jaw(low, depth)   -- the beard along the jaw and over the chin, the mouth left clear
	return {egg("Jaw", v(1.36, 0.5, 0.92), cf(0, -0.5, -0.22), H, M.PLASTIC),
		egg("Chin", v(0.82, low or 0.5, depth or 0.48), cf(0, -0.62, -0.5), H, M.PLASTIC),
		egg("Cheek", v(0.14, 0.5, 0.46), cf(-0.61, -0.24, -0.16), H, M.PLASTIC),
		egg("Cheek", v(0.14, 0.5, 0.46), cf(0.61, -0.24, -0.16), H, M.PLASTIC)}
end

-- a few days' growth: a close shadow over the jaw and lip
Body.Beard.Stubble = {middle(),
	egg("Stubble", v(1.3, 0.46, 0.9), cf(0, -0.46, -0.2), H, M.PLASTIC),
	egg("Stubble", v(0.5, 0.08, 0.12), cf(0, -0.16, -0.62), H, M.PLASTIC)}

-- a full beard, thick at the chin, with a moustache
Body.Beard.Full = J({middle()}, jaw(0.62, 0.56), moustache(0.05))

-- a pointed tuft on the chin and a moustache
Body.Beard.Goatee = J({middle(), egg("Goatee", v(0.34, 0.46, 0.3), cf(0, -0.62, -0.58), H, M.PLASTIC),
	lock(Vector3.new(0, -0.68, -0.6), Vector3.new(0, -0.92, -0.62), 0.16, 0.14, "Goatee")}, moustache(0.08, 0.3))

-- broad whiskers down each cheek, joined by the moustache, the chin bare
Body.Beard.MuttonChops = J({middle(),
	egg("Chop", v(0.26, 0.74, 0.62), cf(-0.6, -0.22, -0.18), H, M.PLASTIC),
	egg("Chop", v(0.26, 0.74, 0.62), cf(0.6, -0.22, -0.18), H, M.PLASTIC),
	egg("Chop", v(0.34, 0.34, 0.3), cf(-0.48, -0.42, -0.42), H, M.PLASTIC),
	egg("Chop", v(0.34, 0.34, 0.3), cf(0.48, -0.42, -0.42), H, M.PLASTIC)}, moustache(0.0, 0.48))

-- a full beard worked into two braids, bound with brass beads
Body.Beard.Braided = J({middle()}, jaw(0.5, 0.46), moustache(0.06),
	braid(Vector3.new(-0.18, -0.74, -0.6), Vector3.new(-0.22, -1.4, -0.62), 5, 0.17),
	braid(Vector3.new(0.18, -0.74, -0.6), Vector3.new(0.22, -1.4, -0.62), 5, 0.17),
	{ball("Bead", 0.15, cf(-0.22, -1.44, -0.62), C.BRASS, M.METAL, KEEP), ball("Bead", 0.15, cf(0.22, -1.44, -0.62), C.BRASS, M.METAL, KEEP),
	 B.torus("Band", v(0.2, 0.06, 0.2), cf(-0.2, -1.0, -0.61), C.BRASS, M.METAL, KEEP), B.torus("Band", v(0.2, 0.06, 0.2), cf(0.2, -1.0, -0.61), C.BRASS, M.METAL, KEEP)})

-- a long beard split into two points
Body.Beard.Forked = J({middle()}, jaw(0.56, 0.5), moustache(0.1, 0.42),
	tail({Vector3.new(-0.12, -0.7, -0.56), Vector3.new(-0.24, -1.0, -0.6), Vector3.new(-0.36, -1.32, -0.6)}, 0.3, 0.12, "Fork"),
	tail({Vector3.new(0.12, -0.7, -0.56), Vector3.new(0.24, -1.0, -0.6), Vector3.new(0.36, -1.32, -0.6)}, 0.3, 0.12, "Fork"))

-- Faces are textures now (Decals in Cosmetics ▸ Body ▸ Face, drawn by
-- blender/faces.py): parts on the round R6 head never sat right.

return Body
