--[[ WEAPON BLUEPRINTS — one entry per Tool name. Each returns the part specs
     of the weapon in the Tool's local frame: the HANDLE (the fist) is at the
     origin, the business end runs along +Y, the pommel / butt along -Y. That
     is exactly how Roblox grips a Tool (the Handle's +Y points out of the
     fist), so Tool.Grip stays at its default.

     Parts that skins recolor carry attribute SkinPart = "Blade" | "Grip";
     the Hitbox is a transparent box over the striking part (its longest axis
     is the blade — CombatServer / CombatClient read it). A finished Tool has
     every part welded to the Handle (Blueprints.completeTool).

     Add a weapon: write `W.MyWeapon = function() … return specs end` here (use
     the sub-assemblies below), add its Tool scripts under Tools/MyWeapon and a
     line in Catalog ▸ Weapons. Sizes are studs on an R6 body (arm = 2 studs). ]]

local B = require(script.Parent:WaitForChild("Builder"))
local C, M = B.C, B.M
local cf, v = B.cf, B.v

local W = {}

--------------------------------------------------------------------
--  SUB-ASSEMBLIES
--------------------------------------------------------------------
-- the grip = the Handle, a BLOCK centered at the origin with the blade along
-- its +Y. (A Roblox cylinder's axis is its X, so a cylinder Handle would put
-- the blade sideways out of the fist: the Handle is a box, like the hand-made
-- weapons; the leather wraps around it stay round.)
local function grip(len, d, color, material)
	return B.box("Handle", v(d or 0.26, len, d or 0.26), cf(0, 0, 0), color or C.DARKLEATHER, material or M.LEATHER, {SkinPart = "Grip"})
end
-- leather wrap rings on a grip
local function wraps(len, d, n, color)
	local out = {}
	for i = 1, n do
		local y = -len / 2 + len * (i - 0.5) / n
		out[#out + 1] = B.cyl("Wrap", (d or 0.26) + 0.04, 0.06, cf(0, y, 0), color or C.LEATHER, M.LEATHER, {SkinPart = "Grip"})
	end
	return out
end
local function pommel(y, d, color, material, kind)
	if kind == "disc" then return B.cyl("Pommel", d, d * 0.45, cf(0, y, 0, 90, 0, 0), color or C.STEEL, material or M.METAL, {SkinPart = "Grip"}) end
	if kind == "box" then return B.box("Pommel", v(d, d * 0.8, d * 0.6), cf(0, y, 0), color or C.STEEL, material or M.METAL, {SkinPart = "Grip"}) end
	return B.ball("Pommel", d, cf(0, y, 0), color or C.STEEL, material or M.METAL, {SkinPart = "Grip"})
end
-- a straight crossguard at height y (width along X)
local function crossguard(y, w, t, color, material, extra)
	return B.box("Guard", v(w, t, t * 1.4), cf(0, y, 0), color or C.STEEL, material or M.METAL, {SkinPart = "Grip"}, extra)
end
-- a symmetric sword point: two wedges meeting at x = 0
local function tip(name, yBase, len, w, th, color, material, attrs)
	return {
		B.wedge(name, v(th, len, w / 2), cf(-w / 4, yBase + len / 2, 0, 0, 90, 0), color, material, attrs),
		B.wedge(name, v(th, len, w / 2), cf(w / 4, yBase + len / 2, 0, 0, -90, 0), color, material, attrs),
	}
end
-- a straight double-edged blade from yBase, total length len (incl. point)
local function blade(yBase, len, w, th, color, material, opts)
	opts = opts or {}
	local tipLen = opts.tipLen or math.min(0.6, len * 0.22)
	local body = len - tipLen
	local attrs = {SkinPart = "Blade"}
	local out = {B.box("Blade", v(w, body, th), cf(0, yBase + body / 2, 0), color or C.STEEL, material or M.METAL, attrs)}
	-- fuller (groove) as a darker thin strip
	if opts.fuller ~= false and w >= 0.28 then
		out[#out + 1] = B.box("Fuller", v(w * 0.3, body * 0.8, th + 0.02), cf(0, yBase + body / 2, 0), C.IRON, M.METAL, {SkinPart = "Blade"})
	end
	if opts.flatTip then
		out[#out + 1] = B.box("Blade", v(w, tipLen, th), cf(0, yBase + body + tipLen / 2, 0), color or C.STEEL, material or M.METAL, attrs)
	else
		B.join(out, tip("Blade", yBase + body, tipLen, w, th, color or C.STEEL, material or M.METAL, attrs))
	end
	return out
end
-- the hitbox over [y0, y1] with a square cross-section
local function hitbox(y0, y1, cross)
	return B.box("Hitbox", v(cross, y1 - y0, cross), cf(0, (y0 + y1) / 2, 0), C.WHITE, M.PLASTIC, nil, {transparency = 1, shadow = false})
end
-- a wooden haft from yBottom to yTop (the Handle segment is left out: it's the grip)
local function haft(yBottom, yTop, d, gripLen, color)
	local out = {}
	color = color or C.WOOD
	local lo, hi = -gripLen / 2, gripLen / 2
	if yBottom < lo then out[#out + 1] = B.cyl("Haft", d, lo - yBottom, cf(0, (yBottom + lo) / 2, 0), color, M.WOOD, {SkinPart = "Grip"}) end
	if yTop > hi then out[#out + 1] = B.cyl("Haft", d, yTop - hi, cf(0, (hi + yTop) / 2, 0), color, M.WOOD, {SkinPart = "Grip"}) end
	return out
end
local function cap(y, d, color) return B.cyl("Cap", d, 0.18, cf(0, y, 0), color or C.IRON, M.METAL, {SkinPart = "Grip"}) end
-- an axe bit: a broad wedge-shaped blade on the +X side of the haft at height y
local function axeBit(y, h, reach, th, color, opts)
	opts = opts or {}
	local attrs = {SkinPart = "Blade"}
	local out = {
		B.box("Eye", v(0.5, h * 0.55, 0.42), cf(0, y, 0), C.DARKSTEEL, M.METAL, attrs),           -- the socket around the haft
		B.box("Blade", v(reach * 0.55, h * 0.8, th), cf(0.25 + reach * 0.275, y, 0), color or C.STEEL, M.METAL, attrs),
		-- flared edge: taller than the body, with wedge corners top and bottom
		B.box("Blade", v(reach * 0.4, h, th), cf(0.25 + reach * 0.55 + reach * 0.2, y, 0), color or C.STEEL, M.METAL, attrs),
		B.wedge("Blade", v(th, h * 0.3, reach * 0.4), cf(0.25 + reach * 0.75, y + h * 0.65, 0, 0, -90, 0), color or C.STEEL, M.METAL, attrs),
		B.wedge("Blade", v(th, h * 0.3, reach * 0.4), cf(0.25 + reach * 0.75, y - h * 0.65, 0, 180, -90, 0), color or C.STEEL, M.METAL, attrs),
	}
	if opts.spike then out[#out + 1] = B.wedge("Spike", v(th * 1.2, 0.26, 0.7), cf(-0.6, y, 0, 0, 90, 90), C.DARKSTEEL, M.METAL, attrs) end
	if opts.hammer then out[#out + 1] = B.box("Face", v(0.6, h * 0.5, 0.45), cf(-0.55, y, 0), C.DARKSTEEL, M.METAL, attrs) end
	return out
end
-- a leaf / diamond spearhead at yBase
local function spearhead(yBase, len, w, th, color)
	local attrs = {SkinPart = "Blade"}
	local out = {B.cyl("Socket", 0.3, 0.5, cf(0, yBase + 0.2, 0), C.DARKSTEEL, M.METAL, attrs)}
	B.join(out, tip("Blade", yBase + 0.4, len * 0.7, w, th, color or C.STEEL, M.METAL, attrs))
	-- lower half of the leaf: inverted wedges
	out[#out + 1] = B.wedge("Blade", v(th, len * 0.3, w / 2), cf(-w / 4, yBase + 0.4 + len * 0.15 - len * 0.3 + 0.3, 0, 180, 90, 0), color or C.STEEL, M.METAL, attrs)
	out[#out + 1] = B.wedge("Blade", v(th, len * 0.3, w / 2), cf(w / 4, yBase + 0.4 + len * 0.15 - len * 0.3 + 0.3, 0, 180, -90, 0), color or C.STEEL, M.METAL, attrs)
	return out
end

--------------------------------------------------------------------
--  SWORDS
--------------------------------------------------------------------
local function sword(p)
	-- p: grip, gripD, blade, w, th, guard, guardT, pommel, pommelKind, flatTip, bladeColor, gripColor, wraps, rings
	local g = p.grip or 0.7
	local y0 = g / 2 + (p.guardT or 0.14)
	local out = {grip(g, p.gripD or 0.26, p.gripColor)}
	B.join(out, wraps(g, p.gripD or 0.26, p.wraps or math.max(2, math.floor(g / 0.3)), p.wrapColor))
	out[#out + 1] = pommel(-g / 2 - (p.pommel or 0.3) / 2, p.pommel or 0.3, p.metal, nil, p.pommelKind)
	out[#out + 1] = crossguard(g / 2 + (p.guardT or 0.14) / 2, p.guard or 1.1, p.guardT or 0.14, p.metal)
	if p.rings then
		-- side rings (zweihander) as two small discs beside the guard
		out[#out + 1] = B.cyl("Ring", 0.5, 0.08, cf(0, y0 + 0.1, 0.22, 90, 0, 0), p.metal or C.STEEL, M.METAL, {SkinPart = "Grip"})
		out[#out + 1] = B.cyl("Ring", 0.5, 0.08, cf(0, y0 + 0.1, -0.22, 90, 0, 0), p.metal or C.STEEL, M.METAL, {SkinPart = "Grip"})
	end
	if p.ricasso then
		-- a leather-wrapped ricasso + parrying lugs above the guard (zweihander)
		out[#out + 1] = B.box("Ricasso", v(p.w + 0.08, p.ricasso, (p.th or 0.12) + 0.08), cf(0, y0 + p.ricasso / 2, 0), C.DARKLEATHER, M.LEATHER, {SkinPart = "Grip"})
		out[#out + 1] = B.box("Lug", v(p.w + 0.6, 0.12, 0.16), cf(0, y0 + p.ricasso + 0.06, 0), p.metal or C.STEEL, M.METAL, {SkinPart = "Grip"})
		y0 = y0 + p.ricasso + 0.12
	end
	B.join(out, blade(y0, p.blade, p.w, p.th or 0.12, p.bladeColor, nil, {flatTip = p.flatTip, fuller = p.fuller, tipLen = p.tipLen}))
	out[#out + 1] = hitbox(y0 - 0.1, y0 + p.blade + 0.05, math.max(p.w, p.th or 0.12) + 0.25)
	return out
end

W.Longsword   = function() return sword{grip = 0.95, blade = 3.2, w = 0.32, guard = 1.3, pommel = 0.32, pommelKind = "disc"} end
W.ArmingSword = function() return sword{grip = 0.62, blade = 2.6, w = 0.3, guard = 1.1, pommel = 0.3} end
W.Zweihander  = function() return sword{grip = 1.4, gripD = 0.28, blade = 4.4, w = 0.38, th = 0.13, guard = 1.8, guardT = 0.16, pommel = 0.36, rings = true, ricasso = 0.6} end
W.Executioner = function() return sword{grip = 1.2, blade = 3.6, w = 0.5, th = 0.13, guard = 1.2, pommel = 0.34, pommelKind = "box", flatTip = true, tipLen = 0.15} end
W.Estoc       = function() return sword{grip = 1.0, blade = 3.4, w = 0.2, th = 0.2, guard = 1.1, pommel = 0.3, fuller = false, tipLen = 0.5} end
W.Dagger      = function() return sword{grip = 0.45, gripD = 0.2, blade = 1.1, w = 0.22, th = 0.08, guard = 0.5, guardT = 0.1, pommel = 0.22, wraps = 1} end
W.Rapier = function()
	local out = sword{grip = 0.6, gripD = 0.22, blade = 3.2, w = 0.16, th = 0.1, guard = 0.9, guardT = 0.08, pommel = 0.26, fuller = false, tipLen = 0.5}
	-- cup guard and a knuckle bow
	out[#out + 1] = B.cyl("Cup", 0.9, 0.08, cf(0, 0.36, 0), C.STEEL, M.METAL, {SkinPart = "Grip"})
	out[#out + 1] = B.box("Bow", v(0.06, 0.7, 0.06), cf(0.3, 0, 0, 0, 0, 20), C.STEEL, M.METAL, {SkinPart = "Grip"})
	return out
end
W.Falchion = function()
	local out = {grip(0.6, 0.26), pommel(-0.45, 0.3, nil, nil, "disc"), crossguard(0.37, 1.0, 0.14)}
	B.join(out, wraps(0.6, 0.26, 2))
	local a = {SkinPart = "Blade"}
	-- broad single-edged blade that widens toward the tip, clipped point
	out[#out + 1] = B.box("Blade", v(0.42, 1.5, 0.12), cf(0.02, 1.2, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.box("Blade", v(0.56, 0.7, 0.12), cf(0.1, 2.3, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.wedge("Blade", v(0.12, 0.45, 0.56), cf(0.1, 2.875, 0, 0, -90, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.box("Spine", v(0.08, 2.1, 0.14), cf(-0.2, 1.5, 0), C.IRON, M.METAL, a)
	out[#out + 1] = hitbox(0.4, 3.15, 0.8)
	return out
end
W.Messer = function()
	local out = {grip(0.9, 0.26, C.LEATHER), pommel(-0.6, 0.28, nil, nil, "box"), crossguard(0.52, 1.1, 0.12)}
	B.join(out, wraps(0.9, 0.26, 3))
	out[#out + 1] = B.box("Nagel", v(0.1, 0.22, 0.45), cf(0, 0.6, -0.25), C.STEEL, M.METAL, {SkinPart = "Grip"})   -- the side nail
	local a = {SkinPart = "Blade"}
	out[#out + 1] = B.box("Blade", v(0.38, 1.6, 0.12), cf(0, 1.4, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.box("Blade", v(0.36, 1.0, 0.12), cf(0.12, 2.68, 0, 0, 0, -8), C.STEEL, M.METAL, a)
	out[#out + 1] = B.wedge("Blade", v(0.12, 0.5, 0.36), cf(0.2, 3.4, 0, 0, -90, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = hitbox(0.55, 3.7, 0.7)
	return out
end
W.Cleaver = function()
	local out = {grip(0.5, 0.24, C.WOOD, M.WOOD)}
	out[#out + 1] = B.box("Bolster", v(0.3, 0.12, 0.2), cf(0, 0.31, 0), C.IRON, M.METAL, {SkinPart = "Grip"})
	local a = {SkinPart = "Blade"}
	out[#out + 1] = B.box("Blade", v(0.75, 1.5, 0.1), cf(0.18, 1.12, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.wedge("Blade", v(0.1, 0.3, 0.75), cf(0.18, 2.02, 0, 0, -90, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = hitbox(0.35, 2.2, 0.95)
	return out
end

--------------------------------------------------------------------
--  BLUNT
--------------------------------------------------------------------
W.Mace = function()
	local out = {grip(0.8, 0.26)}
	B.join(out, wraps(0.8, 0.26, 2), haft(-0.6, 1.3, 0.18, 0.8, C.DARKSTEEL))
	out[#out + 1] = cap(-0.65, 0.3)
	out[#out + 1] = B.ball("Head", 0.5, cf(0, 1.55, 0), C.STEEL, M.METAL, {SkinPart = "Blade"})
	B.join(out, B.ring("Flange", 6, 0.28, v(0.12, 0.6, 0.2), 1.55, C.STEEL, M.METAL, {SkinPart = "Blade"}))
	out[#out + 1] = hitbox(1.1, 1.95, 0.95)
	return out
end
W.MorningStar = function()
	local out = {grip(0.9, 0.26)}
	B.join(out, wraps(0.9, 0.26, 3), haft(-0.7, 1.4, 0.2, 0.9))
	out[#out + 1] = cap(-0.75, 0.3)
	out[#out + 1] = B.ball("Head", 0.7, cf(0, 1.75, 0), C.DARKSTEEL, M.METAL, {SkinPart = "Blade"})
	B.join(out, B.ring("Spike", 8, 0.42, v(0.12, 0.12, 0.28), 1.75, C.STEEL, M.METAL, {SkinPart = "Blade"}))
	out[#out + 1] = B.box("Spike", v(0.12, 0.3, 0.12), cf(0, 2.2, 0), C.STEEL, M.METAL, {SkinPart = "Blade"})
	out[#out + 1] = hitbox(1.2, 2.35, 1.1)
	return out
end
W.Maul = function()
	local out = {grip(1.0, 0.28, C.WOOD, M.WOOD)}
	B.join(out, haft(-1.2, 2.3, 0.26, 1.0))
	out[#out + 1] = cap(-1.25, 0.34)
	out[#out + 1] = B.box("Head", v(1.1, 0.7, 0.7), cf(0, 2.55, 0), C.DARKSTEEL, M.METAL, {SkinPart = "Blade"})
	out[#out + 1] = B.box("Band", v(1.14, 0.12, 0.74), cf(0, 2.55, 0), C.IRON, M.METAL, {SkinPart = "Blade"})
	out[#out + 1] = B.wedge("Spike", v(0.7, 0.4, 0.5), cf(0, 3.1, 0, 0, 0, 0), C.STEEL, M.METAL, {SkinPart = "Blade"})
	out[#out + 1] = hitbox(2.1, 3.3, 1.3)
	return out
end
W.Hammer = function()   -- the existing war hammer, in case the Tool arrives without a body
	local out = {grip(0.7, 0.26)}
	B.join(out, wraps(0.7, 0.26, 2), haft(-0.5, 1.4, 0.18, 0.7, C.DARKSTEEL))
	out[#out + 1] = B.box("Head", v(0.55, 0.4, 0.4), cf(0.2, 1.55, 0), C.STEEL, M.METAL, {SkinPart = "Blade"})
	out[#out + 1] = B.wedge("Spike", v(0.3, 0.26, 0.7), cf(-0.45, 1.55, 0, 0, 90, 90), C.DARKSTEEL, M.METAL, {SkinPart = "Blade"})
	out[#out + 1] = hitbox(1.2, 1.9, 1.0)
	return out
end

--------------------------------------------------------------------
--  AXES
--------------------------------------------------------------------
W.WarAxe = function()
	local out = {grip(0.8, 0.26, C.WOOD, M.WOOD)}
	B.join(out, wraps(0.8, 0.26, 2, C.DARKLEATHER), haft(-0.7, 1.6, 0.2, 0.8))
	out[#out + 1] = cap(-0.75, 0.3)
	B.join(out, axeBit(1.35, 0.9, 1.0, 0.1, C.STEEL))
	out[#out + 1] = hitbox(0.8, 1.95, 1.6)
	return out
end
W.BattleAxe = function()
	local out = {grip(1.1, 0.28, C.WOOD, M.WOOD)}
	B.join(out, haft(-1.0, 2.6, 0.24, 1.1))
	out[#out + 1] = cap(-1.05, 0.34)
	B.join(out, axeBit(2.2, 1.3, 1.3, 0.12, C.STEEL, {spike = true}))
	out[#out + 1] = B.wedge("Spike", v(0.2, 0.5, 0.2), cf(0, 2.95, 0), C.STEEL, M.METAL, {SkinPart = "Blade"})
	out[#out + 1] = hitbox(1.4, 3.2, 2.0)
	return out
end
W.Bardiche = function()
	local out = {grip(1.1, 0.28, C.WOOD, M.WOOD)}
	B.join(out, haft(-1.3, 3.2, 0.24, 1.1))
	out[#out + 1] = cap(-1.35, 0.34)
	local a = {SkinPart = "Blade"}
	-- a long crescent blade bound to the haft at two points
	out[#out + 1] = B.box("Blade", v(0.9, 2.0, 0.1), cf(0.6, 2.4, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.wedge("Blade", v(0.1, 0.6, 0.9), cf(0.6, 3.7, 0, 0, -90, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.box("Langet", v(0.3, 0.2, 0.3), cf(0.1, 1.5, 0), C.DARKSTEEL, M.METAL, a)
	out[#out + 1] = B.box("Langet", v(0.3, 0.2, 0.3), cf(0.1, 3.1, 0), C.DARKSTEEL, M.METAL, a)
	out[#out + 1] = hitbox(1.4, 4.0, 1.5)
	return out
end

--------------------------------------------------------------------
--  POLEARMS
--------------------------------------------------------------------
W.Spear = function()
	local out = {grip(0.9, 0.22, C.WOOD, M.WOOD)}
	B.join(out, haft(-1.6, 3.4, 0.2, 0.9))
	out[#out + 1] = cap(-1.65, 0.26)
	B.join(out, spearhead(3.4, 1.1, 0.4, 0.1))
	out[#out + 1] = hitbox(3.2, 4.9, 0.7)
	return out
end
W.Pitchfork = function()   -- fallback body for the existing pitchfork
	local out = {grip(0.9, 0.22, C.WOOD, M.WOOD)}
	B.join(out, haft(-1.6, 3.2, 0.2, 0.9))
	local a = {SkinPart = "Blade"}
	out[#out + 1] = B.box("Yoke", v(0.9, 0.14, 0.14), cf(0, 3.3, 0), C.IRON, M.METAL, a)
	for _, x in ipairs({-0.38, 0, 0.38}) do
		out[#out + 1] = B.box("Tine", v(0.1, 1.0, 0.1), cf(x, 3.85, 0), C.STEEL, M.METAL, a)
		B.join(out, tip("Tine", 4.35, 0.25, 0.1, 0.1, C.STEEL, M.METAL, a))
	end
	out[#out + 1] = hitbox(3.2, 4.65, 1.1)
	return out
end
W.Halberd = function()
	local out = {grip(1.0, 0.24, C.WOOD, M.WOOD)}
	B.join(out, haft(-1.6, 3.6, 0.22, 1.0))
	out[#out + 1] = cap(-1.65, 0.3)
	B.join(out, axeBit(3.0, 1.1, 1.0, 0.1, C.STEEL))
	-- rear hook + top spike
	out[#out + 1] = B.wedge("Hook", v(0.1, 0.5, 0.6), cf(-0.55, 3.0, 0, 0, 90, 90), C.DARKSTEEL, M.METAL, {SkinPart = "Blade"})
	B.join(out, tip("Spike", 3.6, 1.0, 0.24, 0.1, C.STEEL, M.METAL, {SkinPart = "Blade"}))
	out[#out + 1] = B.box("Langet", v(0.3, 1.4, 0.3), cf(0, 2.3, 0), C.DARKSTEEL, M.METAL, {SkinPart = "Grip"})
	out[#out + 1] = hitbox(2.3, 4.65, 1.9)
	return out
end
W.Poleaxe = function()
	local out = {grip(1.0, 0.24, C.WOOD, M.WOOD)}
	B.join(out, haft(-1.5, 3.3, 0.22, 1.0))
	out[#out + 1] = cap(-1.55, 0.3)
	local a = {SkinPart = "Blade"}
	out[#out + 1] = B.box("Head", v(0.6, 0.45, 0.45), cf(0.35, 2.9, 0), C.DARKSTEEL, M.METAL, a)   -- hammer face
	B.join(out, B.ring("Tooth", 4, 0.14, v(0.1, 0.1, 0.1), 2.9, C.STEEL, M.METAL, a))
	out[#out + 1] = B.wedge("Fluke", v(0.12, 0.45, 0.8), cf(-0.55, 2.9, 0, 0, 90, 90), C.STEEL, M.METAL, a)   -- the back spike
	B.join(out, tip("Spike", 3.3, 0.9, 0.22, 0.12, C.STEEL, M.METAL, a))
	out[#out + 1] = B.box("Langet", v(0.28, 1.4, 0.28), cf(0, 2.2, 0), C.DARKSTEEL, M.METAL, {SkinPart = "Grip"})
	out[#out + 1] = hitbox(2.3, 4.25, 1.6)
	return out
end
W.Glaive = function()
	local out = {grip(1.0, 0.24, C.WOOD, M.WOOD)}
	B.join(out, haft(-1.5, 3.2, 0.22, 1.0))
	out[#out + 1] = cap(-1.55, 0.3)
	local a = {SkinPart = "Blade"}
	out[#out + 1] = B.cyl("Socket", 0.3, 0.5, cf(0, 3.4, 0), C.DARKSTEEL, M.METAL, a)
	out[#out + 1] = B.box("Blade", v(0.42, 1.3, 0.1), cf(0.1, 4.2, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.wedge("Blade", v(0.1, 0.7, 0.42), cf(0.1, 5.2, 0, 0, -90, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.box("Spine", v(0.08, 1.3, 0.12), cf(-0.14, 4.2, 0), C.IRON, M.METAL, a)
	out[#out + 1] = hitbox(3.3, 5.6, 0.9)
	return out
end
W.Billhook = function()
	local out = {grip(1.0, 0.24, C.WOOD, M.WOOD)}
	B.join(out, haft(-1.4, 3.0, 0.22, 1.0))
	out[#out + 1] = cap(-1.45, 0.3)
	local a = {SkinPart = "Blade"}
	out[#out + 1] = B.cyl("Socket", 0.3, 0.5, cf(0, 3.2, 0), C.DARKSTEEL, M.METAL, a)
	out[#out + 1] = B.box("Blade", v(0.36, 1.4, 0.1), cf(0, 4.1, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.box("Hook", v(0.6, 0.3, 0.1), cf(0.3, 4.9, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.wedge("Hook", v(0.1, 0.5, 0.3), cf(0.45, 4.6, 0, 180, -90, 0), C.STEEL, M.METAL, a)
	out[#out + 1] = B.wedge("Spur", v(0.1, 0.35, 0.45), cf(-0.4, 3.9, 0, 0, 90, 90), C.STEEL, M.METAL, a)
	B.join(out, tip("Spike", 4.8, 0.5, 0.2, 0.1, C.STEEL, M.METAL, a))
	out[#out + 1] = hitbox(3.1, 5.35, 1.4)
	return out
end
W.Quarterstaff = function()
	local out = {grip(1.0, 0.24, C.WOOD, M.WOOD)}
	B.join(out, haft(-2.4, 2.6, 0.22, 1.0))
	out[#out + 1] = cap(-2.45, 0.28)
	out[#out + 1] = cap(2.65, 0.28)
	out[#out + 1] = B.cyl("Band", 0.28, 0.1, cf(0, 1.2, 0), C.IRON, M.METAL, {SkinPart = "Blade"})
	out[#out + 1] = B.cyl("Band", 0.28, 0.1, cf(0, -1.2, 0), C.IRON, M.METAL, {SkinPart = "Blade"})
	out[#out + 1] = hitbox(0.6, 2.75, 0.5)
	return out
end
-- THE MAGE'S STAFF: a long blackwood shaft shod in iron, a brass collar and four claws curling
-- up round an orb of light. The orb is the "Blade" (a skin recolours it); spells leave from it
-- (Tools ▸ Staff ▸ Config.ORB). No hitbox: a staff casts, it doesn't cut.
W.Staff = function()
	local out = {grip(0.9, 0.24, C.DARKLEATHER, M.LEATHER)}
	B.join(out, wraps(0.9, 0.24, 3, C.LEATHER))
	B.join(out, haft(-1.9, 3.0, 0.22, 0.9, C.DARKWOOD))
	out[#out + 1] = cap(-1.95, 0.26)
	out[#out + 1] = B.cyl("Band", 0.27, 0.1, cf(0, 1.6, 0), C.BRASS, M.METAL, {SkinPart = "Grip"})
	out[#out + 1] = B.cyl("Collar", 0.36, 0.22, cf(0, 3.05, 0), C.BRASS, M.METAL, {SkinPart = "Grip"})
	-- (a rod between two points: a cylinder's Y axis laid along them)
	local function rod(name, a, b, d, color, mat, attrs)
		local mid, dir = (a + b) / 2, b - a
		local up = math.abs(dir.Unit.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
		return B.cyl(name, d, dir.Magnitude, CFrame.lookAt(mid, b, up) * CFrame.Angles(-math.pi / 2, 0, 0), color, mat, attrs)
	end
	for i = 0, 3 do   -- the claws: out from the collar, round the orb, curling in over it
		local a = i * math.pi / 2 + math.pi / 4
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		local p0, p1, p2 = Vector3.new(0, 3.12, 0) + d * 0.1, Vector3.new(0, 3.5, 0) + d * 0.38, Vector3.new(0, 3.92, 0) + d * 0.16
		out[#out + 1] = rod("Claw", p0, p1, 0.09, C.BRASS, M.METAL, {SkinPart = "Grip"})
		out[#out + 1] = rod("Claw", p1, p2, 0.08, C.BRASS, M.METAL, {SkinPart = "Grip"})
		out[#out + 1] = B.ball("ClawTip", 0.11, CFrame.new(p2), C.BRASS, M.METAL, {SkinPart = "Grip"})
	end
	out[#out + 1] = B.ball("Orb", 0.56, cf(0, 3.55, 0), Color3.fromRGB(140, 200, 255), M.NEON, {SkinPart = "Blade"})
	return out
end
W.Greatsword = function() return sword{grip = 1.2, gripD = 0.28, blade = 4.0, w = 0.36, th = 0.12, guard = 1.6, guardT = 0.16, pommel = 0.34} end
W.Shortsword = function() return sword{grip = 0.55, blade = 2.2, w = 0.28, guard = 0.9, pommel = 0.26, wraps = 2} end

--------------------------------------------------------------------
--  RANGED (Combat ▸ RangedServer). No Hitbox: they don't strike.
--------------------------------------------------------------------
-- THE LONGBOW, in the left hand: the limbs run along ±Y (upright with the arm
-- raised), bowed toward +Z (the archer's side, where the string is). The
-- string itself is two Beams between attachments RangedServer puts on the
-- Handle (Config STRING), so it can be drawn back to the hand.
W.Bow = function()
	local wood, dark = C.WOOD, C.DARKWOOD
	local out = {B.box("Handle", v(0.24, 0.62, 0.3), cf(0, 0, 0), C.DARKLEATHER, M.LEATHER, {SkinPart = "Grip"})}
	out[#out + 1] = B.box("Shelf", v(0.26, 0.12, 0.34), cf(0, 0.36, -0.02), dark, M.WOOD, {SkinPart = "Grip"})
	-- each limb: segments along an arc of radius Rb, tapering to the tip
	local Rb, PHI, N = 4.0, 0.56, 6
	for _, sgn in ipairs({1, -1}) do
		for i = 1, N do
			local a0, a1 = PHI * (i - 1) / N, PHI * i / N
			local p0 = v(0, sgn * Rb * math.sin(a0), Rb * (1 - math.cos(a0)))
			local p1 = v(0, sgn * Rb * math.sin(a1), Rb * (1 - math.cos(a1)))
			local mid, len = (p0 + p1) / 2, (p1 - p0).Magnitude
			local w = 0.22 - 0.1 * (i / N)
			-- (a turn about X takes +Y to (0, cos, sin): straight along p0 → p1)
			local tilt = math.atan2(p1.Z - p0.Z, p1.Y - p0.Y)
			out[#out + 1] = B.box("Limb", v(w, len + 0.04, w * 1.25), CFrame.new(mid) * CFrame.Angles(tilt, 0, 0), wood, M.WOOD, {SkinPart = "Blade"})
		end
		-- the horn nock at the tip
		local tip = v(0, sgn * Rb * math.sin(PHI), Rb * (1 - math.cos(PHI)))
		out[#out + 1] = B.ball("Nock", 0.16, CFrame.new(tip), C.LINEN, M.PLASTIC, {SkinPart = "Grip"})
	end
	return out
end

-- THE CROSSBOW, in the right hand like any weapon: the grip upright, the
-- tiller running forward along -Z, the prod across the front, the stock back
-- to the shoulder. The Bolt shows while it's loaded (RangedServer: Loaded).
W.Crossbow = function()
	local a = {SkinPart = "Blade"}
	local out = {B.box("Handle", v(0.24, 0.7, 0.3), cf(0, 0, 0), C.DARKWOOD, M.WOOD, {SkinPart = "Grip"})}
	out[#out + 1] = B.box("Tiller", v(0.3, 0.3, 2.9), cf(0, 0.48, -0.95), C.WOOD, M.WOOD, a)
	out[#out + 1] = B.box("Stock", v(0.3, 0.46, 0.95), cf(0, 0.36, 0.9), C.WOOD, M.WOOD, a)
	out[#out + 1] = B.box("Butt", v(0.32, 0.6, 0.18), cf(0, 0.3, 1.42), C.DARKWOOD, M.WOOD, a)
	out[#out + 1] = B.box("Nut", v(0.2, 0.14, 0.18), cf(0, 0.68, -0.6), C.IRON, M.METAL)
	out[#out + 1] = B.box("Trigger", v(0.08, 0.3, 0.1), cf(0, 0.12, -0.42), C.IRON, M.METAL)
	-- the prod: two steel limbs swept back a little
	for _, sgn in ipairs({1, -1}) do
		out[#out + 1] = B.box("Prod", v(1.3, 0.14, 0.18), cf(sgn * 0.62, 0.55, -2.18, 0, sgn * -12, 0), C.DARKSTEEL, M.METAL, a)
	end
	out[#out + 1] = B.box("Lath", v(0.36, 0.22, 0.26), cf(0, 0.55, -2.3), C.IRON, M.METAL)
	out[#out + 1] = B.box("Stirrup", v(0.42, 0.06, 0.06), cf(0, 0.55, -2.62), C.IRON, M.METAL)
	-- the bolt, lying in its groove
	out[#out + 1] = B.box("Bolt", v(0.07, 0.07, 1.45), cf(0, 0.67, -1.32), Color3.fromRGB(150, 110, 66), M.WOOD)
	return out
end

return W
