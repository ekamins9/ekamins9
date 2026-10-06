--[[ DEFIGHT — stops z-fighting. Where two parts have faces in the same plane,
     facing the same way and overlapping (a path laid over a path, a glove the
     same width as its sleeve), the renderer can't tell which is in front and
     the surface flickers. Defight.run finds every such pair among the parts
     it's given and grows the smaller part a hair along that face's axis
     (NUDGE studs in all, half on each side), so its face sits just in front.
     Map builds (Build ▸ MapKit), blueprints (Build ▸ Builder) and dressed
     characters (Dresser) run it.

       Defight.run(root)            -> fixes   (every block part under root)
       Defight.run(nil, {parts})    -> fixes   (just these parts)

     Blocks and meshes (as their boxes) are looked at; cylinders, balls and
     wedges keep their sizes, and parts that are nearly invisible are skipped. ]]

local Defight = {}

local EPS = 0.006     -- faces closer than this lie in the same plane (well under one notch)
local NUDGE = 0.04    -- one notch: how much a part grows along that axis (0.02 on each side)
local CELL = 24       -- the spatial hash's cell size, studs

-- blocks, and meshes taken as their boxes (the armor meshes are box-shaped
-- layers: a sleeve, a band, a glove); growing a mesh scales it a hair
local function eligible(p)
	return ((p:IsA("Part") and p.Shape == Enum.PartType.Block) or p:IsA("MeshPart")) and p.Transparency < 0.98
end

local function boxOf(p)
	local cf, s = p.CFrame, p.Size
	return {p = p, pos = cf.Position, ax = {cf.RightVector, cf.UpVector, -cf.LookVector}, half = {s.X / 2, s.Y / 2, s.Z / 2}, vol = s.X * s.Y * s.Z}
end

-- the first coplanar, same-facing, overlapping pair of faces of A and B:
-- returns A's axis index and B's axis index, or nil
local function coplanar(A, B)
	for i = 1, 3 do
		local n = A.ax[i]
		for j = 1, 3 do
			if math.abs(n:Dot(B.ax[j])) > 0.9995 then
				for _, s in ipairs({1, -1}) do
					local fa = n:Dot(A.pos) + s * A.half[i]
					local fb = n:Dot(B.pos) + s * B.half[j]
					-- (faces pointing down onto the ground are never seen: leave them)
					local out = n * s
					local underside = out.Y < -0.95 and math.abs(A.pos.Y + out.Y * A.half[i]) < 0.1
					if not underside and math.abs(fa - fb) < EPS then
						-- do the two faces overlap in the plane? (A's other two axes)
						local over = true
						for k = 1, 3 do
							if k ~= i then
								local u = A.ax[k]
								local ca, cb = u:Dot(A.pos), u:Dot(B.pos)
								local rb = 0
								for m = 1, 3 do rb += math.abs(u:Dot(B.ax[m])) * B.half[m] end
								if math.min(ca + A.half[k], cb + rb) - math.max(ca - A.half[k], cb - rb) < 0.02 then over = false; break end
							end
						end
						if over then return i, j end
					end
				end
			end
		end
	end
	return nil
end

local STEP = {Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)}

-- one pass: find the clashes, then step parts forward. The smaller of two
-- clashing parts steps forward one notch; parts of the same size (a row of
-- path stones, planks, crenels) get notches like colours on a map, 0 to 3,
-- so no two neighbours end up level again and nothing moves more than 3 notches.
local function pass(recs, cells)
	local seen = {}
	local bump = {}        -- [rec][axis] = notches
	local tie = {}         -- node key -> {rec, axis, links = {node keys}}
	local function node(rec, axis)
		local k = rec.idx * 4 + axis
		local n = tie[k]
		if not n then n = {rec = rec, axis = axis, links = {}, key = k}; tie[k] = n end
		return n
	end
	local clashes = 0
	for _, c in pairs(cells) do
		for a = 1, #c do
			for b = a + 1, #c do
				local ia, ib = c[a], c[b]
				local key = ia < ib and (ia * 65536 + ib) or (ib * 65536 + ia)
				if not seen[key] then
					seen[key] = true
					local A, B = recs[ia], recs[ib]
					local i, j = coplanar(A, B)
					if i then
						clashes += 1
						if math.abs(A.vol - B.vol) > 1e-4 * math.max(A.vol, B.vol) then
							local small, ax = A, i
							if B.vol < A.vol then small, ax = B, j end
							bump[small] = bump[small] or {}
							bump[small][ax] = math.max(bump[small][ax] or 0, 1)
						else
							local na, nb = node(A, i), node(B, j)
							table.insert(na.links, nb.key)
							table.insert(nb.links, na.key)
						end
					end
				end
			end
		end
	end
	-- colour the ties: each takes the lowest notch none of its neighbours has
	local order = {}
	for _, n in pairs(tie) do table.insert(order, n) end
	table.sort(order, function(x, y) return x.key < y.key end)
	local colour = {}
	for _, n in ipairs(order) do
		local used = {}
		for _, k in ipairs(n.links) do if colour[k] then used[colour[k]] = true end end
		local c = 0
		while used[c] and c < 3 do c += 1 end
		colour[n.key] = c
		if c > 0 then
			bump[n.rec] = bump[n.rec] or {}
			bump[n.rec][n.axis] = math.max(bump[n.rec][n.axis] or 0, c)
		end
	end
	local moved = 0
	for rec, axes in pairs(bump) do
		for axis, notches in pairs(axes) do
			rec.p.Size += STEP[axis] * (NUDGE * notches)
			moved += 1
		end
		local fresh = boxOf(rec.p)
		rec.half, rec.vol = fresh.half, fresh.vol
	end
	return clashes, moved
end

function Defight.run(root, list)
	local parts = {}
	if list then
		for _, p in ipairs(list) do if eligible(p) then table.insert(parts, p) end end
	elseif root then
		for _, p in ipairs(root:GetDescendants()) do if eligible(p) then table.insert(parts, p) end end
	end
	if #parts < 2 then return 0 end
	local recs = {}
	local cells = {}
	for idx, p in ipairs(parts) do
		local r = boxOf(p)
		r.idx = idx
		recs[idx] = r
		-- the world box this part covers, into the hash
		local ext = Vector3.zero
		for m = 1, 3 do ext += Vector3.new(math.abs(r.ax[m].X), math.abs(r.ax[m].Y), math.abs(r.ax[m].Z)) * r.half[m] end
		local lo, hi = r.pos - ext, r.pos + ext
		for x = math.floor(lo.X / CELL), math.floor(hi.X / CELL) do
			for y = math.floor(lo.Y / CELL), math.floor(hi.Y / CELL) do
				for z = math.floor(lo.Z / CELL), math.floor(hi.Z / CELL) do
					local key = x .. "," .. y .. "," .. z
					local c = cells[key]
					if not c then c = {}; cells[key] = c end
					table.insert(c, idx)
				end
			end
		end
	end
	local fixed = 0
	for _ = 1, 4 do   -- a stepped part can line up with a third one (or another face of the same one): look again
		local _, moved = pass(recs, cells)
		fixed += moved
		if moved == 0 then break end
	end
	return fixed
end

return Defight
