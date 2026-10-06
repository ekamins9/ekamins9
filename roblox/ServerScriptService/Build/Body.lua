--[[ BODY BLUEPRINTS — hair and beards as part models around the head.
     Each is a spec list in the HEAD's frame: Middle = the 2×1×1 head part at
     the origin (the visible R6 head is a 1.25 cube, front at z = -0.625).
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

local function middle() return B.box("Middle", v(2, 1, 1), cf(), C.WHITE, M.PLASTIC, nil, {transparency = 1, shadow = false}) end
local H = C.HAIR
local function cap(extra)   -- the basic hair cap over the top and back of the head
	return B.join({middle(),
		B.box("Top", v(1.34, 0.3, 1.34), cf(0, 0.6, 0.02), H, M.PLASTIC),
		B.box("Back", v(1.34, 0.7, 0.3), cf(0, 0.2, 0.55), H, M.PLASTIC),
		B.box("Side", v(0.22, 0.6, 1.0), cf(-0.6, 0.25, 0.12), H, M.PLASTIC),
		B.box("Side", v(0.22, 0.6, 1.0), cf(0.6, 0.25, 0.12), H, M.PLASTIC),
	}, extra or {})
end

Body.Hair.Cropped     = cap()
Body.Hair.SweptBack   = cap({B.box("Sweep", v(1.3, 0.3, 0.6), cf(0, 0.75, 0.3, -15, 0, 0), H, M.PLASTIC), B.box("Fringe", v(1.3, 0.2, 0.3), cf(0, 0.55, -0.55), H, M.PLASTIC)})
Body.Hair.LongTied    = cap({B.box("Tail", v(0.4, 1.1, 0.3), cf(0, -0.3, 0.72, 8, 0, 0), H, M.PLASTIC), B.box("Tie", v(0.46, 0.14, 0.36), cf(0, 0.1, 0.72), C.ROPE, M.FABRIC, {KeepColor = true})})
Body.Hair.BowlCut     = {middle(), B.box("Bowl", v(1.44, 0.55, 1.44), cf(0, 0.5, 0), H, M.PLASTIC), B.box("Fringe", v(1.44, 0.3, 0.25), cf(0, 0.3, -0.62), H, M.PLASTIC)}
Body.Hair.Tonsure     = {middle(), B.box("Ring", v(1.34, 0.22, 0.3), cf(0, 0.45, 0.55), H, M.PLASTIC), B.box("Ring", v(0.22, 0.22, 1.1), cf(-0.6, 0.45, 0.1), H, M.PLASTIC), B.box("Ring", v(0.22, 0.22, 1.1), cf(0.6, 0.45, 0.1), H, M.PLASTIC)}
Body.Hair.ShavedSides = {middle(), B.box("Strip", v(0.7, 0.3, 1.34), cf(0, 0.72, 0.02), H, M.PLASTIC), B.box("Back", v(0.7, 0.5, 0.3), cf(0, 0.35, 0.6), H, M.PLASTIC)}
Body.Hair.Topknot     = cap({B.ball("Knot", 0.5, cf(0, 0.95, 0.1), H, M.PLASTIC), B.box("Tie", v(0.3, 0.1, 0.3), cf(0, 0.78, 0.1), C.ROPE, M.FABRIC, {KeepColor = true})})
Body.Hair.WildMane    = B.join({middle()}, (function()
	local out = {}
	for _, p in ipairs({{-0.5, 0.7, -0.3}, {0, 0.85, -0.2}, {0.5, 0.7, -0.3}, {-0.55, 0.65, 0.35}, {0, 0.8, 0.45}, {0.55, 0.65, 0.35}, {-0.7, 0.2, 0.1}, {0.7, 0.2, 0.1}, {0, 0.25, 0.7}, {-0.4, -0.3, 0.6}, {0.4, -0.3, 0.6}}) do
		out[#out + 1] = B.ball("Curl", 0.62, cf(p[1], p[2], p[3]), H, M.PLASTIC)
	end
	return out
end)())
Body.Hair.BraidedCrown = cap({B.box("Braid", v(1.5, 0.22, 0.22), cf(0, 0.55, -0.6), H, M.PLASTIC), B.box("Braid", v(1.5, 0.22, 0.22), cf(0, 0.55, 0.6), H, M.PLASTIC),
	B.box("Braid", v(0.22, 0.22, 1.5), cf(-0.6, 0.55, 0), H, M.PLASTIC), B.box("Braid", v(0.22, 0.22, 1.5), cf(0.6, 0.55, 0), H, M.PLASTIC),
	B.box("Bead", v(0.26, 0.26, 0.26), cf(-0.6, 0.55, -0.6), C.BRASS, M.METAL, {KeepColor = true}), B.box("Bead", v(0.26, 0.26, 0.26), cf(0.6, 0.55, -0.6), C.BRASS, M.METAL, {KeepColor = true})})

Body.Beard.Stubble    = {middle(), B.box("Stubble", v(1.0, 0.3, 0.06), cf(0, -0.42, -0.65), H, M.PLASTIC, nil, {transparency = 0.35})}
Body.Beard.Full       = {middle(), B.box("Beard", v(1.1, 0.6, 0.35), cf(0, -0.55, -0.5), H, M.PLASTIC), B.box("Cheek", v(0.2, 0.7, 0.7), cf(-0.6, -0.2, -0.25), H, M.PLASTIC), B.box("Cheek", v(0.2, 0.7, 0.7), cf(0.6, -0.2, -0.25), H, M.PLASTIC)}
Body.Beard.Goatee     = {middle(), B.box("Goatee", v(0.4, 0.45, 0.2), cf(0, -0.55, -0.6), H, M.PLASTIC)}
Body.Beard.MuttonChops = {middle(), B.box("Chop", v(0.24, 0.8, 0.6), cf(-0.6, -0.15, -0.3), H, M.PLASTIC), B.box("Chop", v(0.24, 0.8, 0.6), cf(0.6, -0.15, -0.3), H, M.PLASTIC)}
Body.Beard.Braided    = B.join({middle(), B.box("Beard", v(1.1, 0.5, 0.35), cf(0, -0.5, -0.5), H, M.PLASTIC)},
	{B.box("Braid", v(0.24, 0.8, 0.24), cf(-0.25, -1.1, -0.55), H, M.PLASTIC), B.box("Braid", v(0.24, 0.8, 0.24), cf(0.25, -1.1, -0.55), H, M.PLASTIC),
	 B.box("Bead", v(0.28, 0.12, 0.28), cf(-0.25, -1.45, -0.55), C.BRASS, M.METAL, {KeepColor = true}), B.box("Bead", v(0.28, 0.12, 0.28), cf(0.25, -1.45, -0.55), C.BRASS, M.METAL, {KeepColor = true})})
Body.Beard.Forked     = {middle(), B.box("Beard", v(1.0, 0.4, 0.3), cf(0, -0.5, -0.5), H, M.PLASTIC), B.box("Fork", v(0.3, 0.7, 0.26), cf(-0.3, -1.0, -0.5, 0, 0, 15), H, M.PLASTIC), B.box("Fork", v(0.3, 0.7, 0.26), cf(0.3, -1.0, -0.5, 0, 0, -15), H, M.PLASTIC)}

-- Faces are textures now (Decals in Cosmetics ▸ Body ▸ Face, drawn by
-- blender/faces.py): parts on the round R6 head never sat right.

return Body
