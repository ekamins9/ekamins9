--[[ BODY BLUEPRINTS — hair, beards and faces as part models around the head.
     Each is a spec list in the HEAD's frame: Middle = the 2×1×1 head part at
     the origin (the visible R6 head is a 1.25 cube, front at z = -0.625).
     Hair and beard parts take the player's hair color unless they carry
     attribute KeepColor = true. Faces are overlays on the default face decal
     (brows, mouth, marks) so they need no texture ids. Ids match Catalog ▸ Body:
     hair Cropped SweptBack LongTied BowlCut Tonsure ShavedSides Topknot WildMane
     BraidedCrown · beards Stubble Full Goatee MuttonChops Braided Forked ·
     faces Stern Grin Scarred Weary Fierce OneEyed. ]]

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

local E = C.EYE
local Z = -0.66
-- a complete face: the Roblox decal is hidden while one of these is worn, so
-- every face carries its own eyes, brows and mouth. The visible head is a
-- 1.25 cube: eyes sit a little above the middle (y 0.1), brows just over
-- them, the mouth a little below (-0.22) — compact, like a drawn face.
local K = {KeepColor = true}
local function eyes(y, w, h, squint)
	y = y or 0.1
	return {B.box("Eye", v(w or 0.17, h or 0.17, 0.04), cf(-0.25, y, Z), E, M.PLASTIC, K),
		B.box("Eye", v(w or 0.17, h or 0.17, 0.04), cf(0.25, y, Z), E, M.PLASTIC, K),
		B.box("Shine", v(0.05, 0.05, 0.04), cf(-0.22, y + 0.04, Z - 0.005), C.WHITE, M.PLASTIC, K),
		B.box("Shine", v(0.05, 0.05, 0.04), cf(0.28, y + 0.04, Z - 0.005), C.WHITE, M.PLASTIC, K)}
end
local function brows(angle, y)
	y = y or 0.27
	return {B.box("Brow", v(0.3, 0.07, 0.04), cf(-0.25, y, Z, 0, 0, -angle), E, M.PLASTIC, K),
		B.box("Brow", v(0.3, 0.07, 0.04), cf(0.25, y, Z, 0, 0, angle), E, M.PLASTIC, K)}
end
local function mouth(w, y, angle)
	return {B.box("Mouth", v(w or 0.3, 0.05, 0.04), cf(0, y or -0.22, Z, 0, 0, angle or 0), C.MOUTH, M.PLASTIC, K)}
end
local function face(...) return B.join({middle()}, ...) end

Body.Face.Stern   = face(eyes(), brows(14), mouth(0.3, -0.22))
Body.Face.Grin    = face(eyes(0.1, 0.17, 0.14), brows(-4, 0.29),
	{B.box("Mouth", v(0.5, 0.12, 0.04), cf(0, -0.22, Z), C.MOUTH, M.PLASTIC, K), B.box("Teeth", v(0.4, 0.05, 0.04), cf(0, -0.19, Z - 0.005), C.WHITE, M.PLASTIC, K)})
Body.Face.Scarred = face(eyes(), brows(10), mouth(0.28, -0.22, 6),
	{B.box("Scar", v(0.06, 0.55, 0.04), cf(0.3, 0.1, Z - 0.003, 0, 0, 14), Color3.fromRGB(190, 130, 110), M.PLASTIC, K)})
Body.Face.Weary   = face(eyes(0.08, 0.17, 0.11), brows(-12, 0.25), mouth(0.26, -0.24),
	{B.box("Bag", v(0.2, 0.04, 0.04), cf(-0.25, -0.02, Z), Color3.fromRGB(150, 110, 100), M.PLASTIC, K), B.box("Bag", v(0.2, 0.04, 0.04), cf(0.25, -0.02, Z), Color3.fromRGB(150, 110, 100), M.PLASTIC, K)})
Body.Face.Fierce  = face(eyes(0.09, 0.19, 0.13), brows(24, 0.24), mouth(0.36, -0.24, 180),
	{B.box("Paint", v(1.2, 0.16, 0.04), cf(0, 0.1, Z + 0.003), C.RED, M.PLASTIC, K)})
Body.Face.OneEyed = face({B.box("Eye", v(0.17, 0.17, 0.04), cf(-0.25, 0.1, Z), E, M.PLASTIC, K), B.box("Shine", v(0.05, 0.05, 0.04), cf(-0.22, 0.14, Z - 0.005), C.WHITE, M.PLASTIC, K)},
	brows(8), mouth(0.28, -0.22),
	{B.box("Patch", v(0.32, 0.26, 0.05), cf(0.25, 0.1, Z - 0.01), C.BLACK, M.LEATHER, K),
	 B.box("Strap", v(1.5, 0.06, 0.05), cf(0, 0.2, Z - 0.005, 0, 0, -12), C.BLACK, M.LEATHER, K), B.box("Strap", v(0.06, 0.3, 1.4), cf(0.62, 0.3, 0), C.BLACK, M.LEATHER, K)})

return Body
