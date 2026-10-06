--[[ SKIN TRIMS — the shape half of a weapon skin. A skin names a trim in
     Catalog ▸ Skins (trim = "royal"); the trim adds parts around the weapon —
     wings on the guard, a gem in the pommel, thorns, rings on the haft, a
     glowing inlay, a crown — so a skin changes the silhouette, not only the
     colours. Every trim is fitted from the weapon's own Blade / Grip regions
     (their boxes in the Handle's frame: +Y toward the tip, X across the edge,
     Z through the flat), so one trim fits all the weapons. Looks only: the
     parts are massless, never collide or query, and the Hitbox is untouched.

       SkinTrims.apply(tool, skin)   (re)builds the Folder "Trim", welded to the Handle
       SkinTrims.clear(tool)
       SkinTrims.NAMES               every trim name (the catalog check uses it)

     Colours come from the skin: blade, grip, accent (default: gold on Epic and
     Legendary, steel below) and glow (the Neon parts). Trails and auras are
     the next layer (SkinFX).
     Add a trim: write a builder below (frame, palette → specs) and name it in
     a skin. ]]

local SkinTrims = {}

local GOLD    = Color3.fromRGB(232, 184, 74)
local STEEL   = Color3.fromRGB(200, 204, 212)
local IRON    = Color3.fromRGB(74, 76, 82)
local LEATHER = Color3.fromRGB(92, 62, 40)
local BONE    = Color3.fromRGB(226, 218, 196)
local M = Enum.Material

--------------------------------------------------------------------
--  THE WEAPON'S FRAME
--------------------------------------------------------------------
local function boxOf(handle, parts)
	local lo, hi
	for _, p in ipairs(parts) do
		local cf = handle.CFrame:ToObjectSpace(p.CFrame)
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do
			for _, sy in ipairs({-1, 1}) do
				for _, sz in ipairs({-1, 1}) do
					local c = cf * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
					lo = lo and lo:Min(c) or c
					hi = hi and hi:Max(c) or c
				end
			end
		end
	end
	return lo, hi
end

-- nil when the tool has no Blade region to fit to
function SkinTrims.frame(tool)
	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then return nil end
	local trim = tool:FindFirstChild("Trim")
	local blades, grips = {}, {}
	for _, p in ipairs(tool:GetDescendants()) do
		if p:IsA("BasePart") and not (trim and p:IsDescendantOf(trim)) then
			local sp = p:GetAttribute("SkinPart")
			if sp == "Blade" then table.insert(blades, p) elseif sp == "Grip" then table.insert(grips, p) end
		end
	end
	if #blades == 0 then return nil end
	local bLo, bHi = boxOf(handle, blades)
	local gLo, gHi
	if #grips > 0 then gLo, gHi = boxOf(handle, grips) else gLo, gHi = handle.Size * -0.5, handle.Size * 0.5 end
	local F = {
		handle = handle,
		bLo = bLo.Y, bHi = bHi.Y, bX = (bLo.X + bHi.X) / 2, bW = bHi.X - bLo.X, bT = bHi.Z - bLo.Z,
		bMinX = bLo.X, bMaxX = bHi.X,
		gLo = gLo.Y, gHi = gHi.Y, gW = gHi.X - gLo.X, gT = gHi.Z - gLo.Z,
		d = math.clamp(handle.Size.X, 0.16, 0.4),      -- grip / haft thickness
	}
	F.bLen = F.bHi - F.bLo
	F.gLen = F.gHi - F.gLo
	-- axes, hammers, maces, polearms: a long haft with a head on top
	F.hafted = F.gLen > F.bLen * 1.2
	-- a staff shod at both ends: its "head" is the top shoe
	if F.hafted and F.bLo < F.gLo + F.gLen * 0.3 then
		F.bLo = F.bHi - math.min(F.bLen, 0.8)
		F.bLen = F.bHi - F.bLo
	end
	-- the guard line: where the blade (or the head) starts
	F.guard = F.bLo
	F.pommel = F.gLo
	F.tip = F.bHi
	-- the grip the hand holds: swords from pommel to guard, hafted weapons the
	-- lowest stretch of the haft
	F.holdLo = F.gLo + 0.12
	F.holdHi = F.hafted and math.min(F.gLo + 1.3, F.guard - 0.4) or (F.guard - 0.12)
	return F
end

--------------------------------------------------------------------
--  SPEC HELPERS (all CFrames in the Handle's frame)
--------------------------------------------------------------------
local function spec(shape, size, cf, color, material, extra)
	local s = {shape = shape, size = size, cf = cf, color = color, material = material or M.SmoothPlastic}
	if extra then for k, v in pairs(extra) do s[k] = v end end
	return s
end
local function block(size, cf, color, material, extra) return spec("Block", size, cf, color, material, extra) end
local function ball(d, cf, color, material, extra) return spec("Ball", Vector3.new(d, d, d), cf, color, material, extra) end
-- a ring around the Y axis (a short cylinder: Roblox cylinders run along X)
local function ring(y, diameter, thick, color, material, x, z)
	return spec("Cylinder", Vector3.new(thick, diameter, diameter), CFrame.new(x or 0, y, z or 0) * CFrame.Angles(0, 0, math.pi / 2), color, material or M.Metal)
end
-- a thorn: a diamond-section spike, base centre at `cf`, pointing along its +Y
local function thorn(out, cf, len, width, thick, color, material, extra)
	local c = cf * CFrame.new(0, len / 2, 0)
	table.insert(out, spec("Wedge", Vector3.new(thick, len, width / 2), c * CFrame.new(0, 0, width / 4) * CFrame.Angles(0, math.pi, 0), color, material, extra))
	table.insert(out, spec("Wedge", Vector3.new(thick, len, width / 2), c * CFrame.new(0, 0, -width / 4), color, material, extra))
end
-- point a CFrame at `pos` so its +Y runs along `dir`, its X as close to the
-- blade's flat normal (Z) as `dir` allows: thorns, leaves and flames then taper
-- in the blade's own plane, the way the weapon is seen from the side
local function along(pos, dir)
	dir = dir.Unit
	local n = math.abs(dir.Z) > 0.95 and Vector3.xAxis or Vector3.zAxis
	local x = (n - dir * n:Dot(dir)).Unit
	return CFrame.fromMatrix(pos, x, dir, x:Cross(dir))
end
-- x of a blade's edge at height y (side -1 = the back / left, 1 = the right):
-- a sword narrows toward its point, a head is a block
local function edge(F, y, side)
	if F.hafted then return side < 0 and F.bMinX or F.bMaxX end
	local f = math.clamp((y - F.bLo) / math.max(F.bLen, 0.1), 0, 1)
	local half = F.bW / 2 * (1 - 0.35 * f)
	if f > 0.88 then half *= (1 - f) / 0.12 end
	return F.bX + side * half
end
-- a feather / leaf: a flat tapered blade (two thin wedges) along +Y of `cf`
local function vane(out, cf, len, width, color, material)
	thorn(out, cf, len, width, 0.03, color, material)
end

local function rarityAccent(skin)
	if skin.accent then return skin.accent end
	if skin.rarity == "Legendary" or skin.rarity == "Epic" then return GOLD end
	return STEEL
end

--------------------------------------------------------------------
--  TRIMS: builder(F, P) → list of specs. P = {blade, grip, accent, glow}
--------------------------------------------------------------------
local T = {}

-- cloth wraps around the grip and a tassel from the pommel
T.wrap = function(F, P)
	local out = {}
	local n = 4
	for i = 1, n do
		local y = F.holdLo + (F.holdHi - F.holdLo) * (i - 0.5) / n
		table.insert(out, ring(y, F.d + 0.07, 0.07, P.grip, M.Fabric))
	end
	table.insert(out, ball(0.12, CFrame.new(0, F.pommel - 0.05, 0), P.grip, M.Fabric))
	table.insert(out, block(Vector3.new(0.05, 0.42, 0.05), CFrame.new(0.03, F.pommel - 0.28, 0) * CFrame.Angles(0, 0, math.rad(8)), P.grip, M.Fabric))
	table.insert(out, block(Vector3.new(0.05, 0.36, 0.05), CFrame.new(-0.03, F.pommel - 0.25, 0.02) * CFrame.Angles(0, 0, math.rad(-10)), P.accent, M.Fabric))
	return out
end

-- bronze rivets along the grip and on the guard
T.rivets = function(F, P)
	local out = {}
	for i = 0, 3 do
		local y = F.holdLo + (F.holdHi - F.holdLo) * i / 3
		for _, z in ipairs({-1, 1}) do table.insert(out, ball(0.09, CFrame.new(0, y, z * (F.d / 2 + 0.01)), P.accent, M.Metal)) end
	end
	if not F.hafted then
		for _, x in ipairs({-1, 1}) do
			for _, z in ipairs({-1, 1}) do table.insert(out, ball(0.08, CFrame.new(x * (F.gW / 2 - 0.1), F.guard - 0.06, z * 0.07), P.accent, M.Metal)) end
		end
	else
		for _, x in ipairs({-1, 1}) do table.insert(out, ball(0.1, CFrame.new(F.bX + x * F.bW * 0.25, F.guard + F.bLen * 0.5, F.bT / 2), P.accent, M.Metal)) end
	end
	return out
end

-- iron rings: three around a haft, one at the base of a blade
T.rings = function(F, P)
	local out = {}
	if F.hafted then
		for i = 1, 3 do table.insert(out, ring(F.gLo + F.gLen * (0.25 + 0.2 * i), F.d + 0.1, 0.1, P.accent, M.Metal)) end
	else
		table.insert(out, ring(F.guard + 0.12, math.max(F.bT, 0.18) + 0.12, 0.08, P.accent, M.Metal))
		table.insert(out, ring(F.holdHi - 0.04, F.d + 0.1, 0.08, P.accent, M.Metal))
		table.insert(out, ring(F.holdLo + 0.04, F.d + 0.1, 0.08, P.accent, M.Metal))
	end
	return out
end

-- an inlaid strip down the middle of the blade, both faces (glows if the skin has a glow)
T.fuller = function(F, P)
	local out = {}
	local mat = P.glow and M.Neon or M.Metal
	local col = P.glow or P.accent
	if F.hafted then
		local h = F.bLen * 0.5
		for _, z in ipairs({-1, 1}) do
			table.insert(out, block(Vector3.new(F.bW * 0.45, h * 0.18, 0.02), CFrame.new(F.bX, F.guard + F.bLen * 0.5, z * (F.bT / 2 + 0.005)), col, mat))
		end
	else
		local len = F.bLen * 0.68
		for _, z in ipairs({-1, 1}) do
			table.insert(out, block(Vector3.new(math.max(F.bW * 0.2, 0.05), len, 0.02), CFrame.new(F.bX, F.guard + 0.15 + len / 2, z * (F.bT * 0.35 + 0.01)), col, mat))
		end
	end
	return out
end

-- square studs down the grip and on the guard / head
T.studs = function(F, P)
	local out = {}
	for i = 0, 4 do
		local y = F.holdLo + (F.holdHi - F.holdLo) * i / 4
		for _, z in ipairs({-1, 1}) do table.insert(out, block(Vector3.new(0.09, 0.09, 0.05), CFrame.new(0, y, z * (F.d / 2 + 0.02)) * CFrame.Angles(0, 0, math.rad(45)), P.accent, M.Metal)) end
	end
	if F.hafted then
		for i = 0, 2 do table.insert(out, block(Vector3.new(0.1, 0.1, 0.1), CFrame.new(0, F.guard - 0.25 - i * 0.3, 0) * CFrame.Angles(0, math.rad(45), 0), P.accent, M.Metal)) end
	else
		for _, x in ipairs({-1, 1}) do table.insert(out, block(Vector3.new(0.12, 0.12, 0.12), CFrame.new(x * (F.gW / 2 + 0.02), F.guard - 0.07, 0) * CFrame.Angles(math.rad(45), 0, 0), P.accent, M.Metal)) end
	end
	return out
end

-- serrated teeth along the back edge
T.notch = function(F, P)
	local out = {}
	local n = F.hafted and 3 or 6
	for i = 1, n do
		local y = F.guard + (F.hafted and F.bLen * (0.2 + 0.25 * (i - 1)) or F.bLen * (0.08 + 0.1 * (i - 1)))
		thorn(out, along(Vector3.new(edge(F, y, -1) + 0.02, y, 0), Vector3.new(-1, 0.5, 0)), 0.2, 0.16, math.clamp(F.bT * 0.6, 0.04, 0.08), P.blade, M.Metal)
	end
	return out
end

-- laurel leaves curving up from the guard, a band on the grip
T.laurel = function(F, P)
	local out = {}
	local reach = F.hafted and F.bW * 0.6 + 0.2 or F.gW * 0.5 + 0.1
	for _, side in ipairs({-1, 1}) do
		for i = 1, 5 do
			local a = math.rad(10 + i * 14)
			local pos = Vector3.new(F.bX * (F.hafted and 1 or 0) + side * reach * math.cos(a) * 0.8, F.guard - 0.05 + reach * math.sin(a) * 0.55, 0)
			vane(out, along(pos, Vector3.new(side * -0.3, 1, 0.15 * side)), 0.24, 0.12, P.accent, M.Metal)
		end
	end
	table.insert(out, ring(F.holdHi - 0.06, F.d + 0.08, 0.06, P.accent, M.Metal))
	return out
end

-- crow feathers fanning from the guard and one from the pommel
T.feather = function(F, P)
	local out = {}
	local dark = P.blade
	local baseX = F.hafted and F.bX or 0
	for _, side in ipairs({-1, 1}) do
		for i = 1, 3 do
			local pos = Vector3.new(baseX + side * (F.hafted and F.bW * 0.3 or F.gW * 0.42), F.guard - 0.05, 0)
			local dir = Vector3.new(side * (0.9 - i * 0.22), 0.6 + i * 0.25, (i - 2) * 0.15)
			vane(out, along(pos, dir), 0.55 - i * 0.07, 0.17, dark, M.SmoothPlastic)
		end
	end
	vane(out, along(Vector3.new(0, F.pommel - 0.02, 0), Vector3.new(0.25, -1, 0)), 0.5, 0.16, dark, M.SmoothPlastic)
	table.insert(out, ball(0.1, CFrame.new(0, F.pommel - 0.02, 0), P.accent, M.Metal))
	return out
end

-- thorns on the guard ends, a pommel spike; on a head, spikes out of the top and back
T.spikes = function(F, P)
	local out = {}
	local col, mat = P.accent, M.Metal
	if F.hafted then
		thorn(out, along(Vector3.new(F.bX, F.tip - 0.05, 0), Vector3.yAxis), 0.45, 0.16, 0.12, col, mat)
		thorn(out, along(Vector3.new(F.bMinX + 0.05, F.guard + F.bLen * 0.55, 0), Vector3.new(-1, 0.3, 0)), 0.42, 0.16, 0.12, col, mat)
		thorn(out, along(Vector3.new(0, F.pommel + 0.02, 0), -Vector3.yAxis), 0.3, 0.12, 0.1, col, mat)
		for i = 1, 2 do thorn(out, along(Vector3.new(0, F.guard - 0.2 - i * 0.25, F.d / 2), Vector3.new(0, 0.2, 1)), 0.16, 0.08, 0.06, col, mat) end
	else
		for _, side in ipairs({-1, 1}) do
			thorn(out, along(Vector3.new(side * F.gW / 2, F.guard - 0.06, 0), Vector3.new(side, 0.5, 0)), 0.32, 0.14, 0.1, col, mat)
		end
		thorn(out, along(Vector3.new(0, F.pommel + 0.02, 0), -Vector3.yAxis), 0.28, 0.14, 0.12, col, mat)
	end
	return out
end

-- flame tongues licking up the back of the blade (or off the head), glowing
T.flame = function(F, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(255, 140, 40)
	local n = F.hafted and 4 or 6
	for i = 1, n do
		local f = (i - 0.5) / n
		local y = F.guard + F.bLen * (F.hafted and (0.15 + 0.7 * f) or (0.05 + 0.75 * f))
		thorn(out, along(Vector3.new(edge(F, y, -1) + 0.02, y, 0), Vector3.new(-0.55, 1, 0)), 0.24 + 0.14 * (i % 2), 0.16, math.clamp(F.bT * 0.5, 0.04, 0.08), glow, M.Neon)
	end
	table.insert(out, ball(0.16, CFrame.new(0, F.pommel - 0.04, 0), glow, M.Neon))
	return out
end

-- ice shards bursting from the guard and riding the edges, glassy
T.frost = function(F, P)
	local out = {}
	local ice = P.glow or Color3.fromRGB(190, 236, 255)
	local extra = {transparency = 0.15}
	local baseX = F.hafted and F.bX or 0
	local spread = F.hafted and F.bW * 0.45 or F.gW * 0.45
	for i, a in ipairs({-60, -30, 0, 30, 60}) do
		local r = math.rad(a)
		local dir = Vector3.new(math.sin(r), math.cos(r) * 0.8 + 0.2, (i % 2 == 0) and 0.3 or -0.3)
		thorn(out, along(Vector3.new(baseX + math.sin(r) * spread * 0.4, F.guard + 0.02, 0), dir), 0.3 + 0.12 * (3 - math.abs(i - 3)), 0.12, 0.08, ice, M.Glass, extra)
	end
	for i = 1, 3 do
		local y = F.guard + F.bLen * (0.25 + 0.22 * i)
		local side = (i % 2 == 0) and 1 or -1
		thorn(out, along(Vector3.new(edge(F, y, side) - side * 0.02, y, 0), Vector3.new(side, 0.9, 0)), 0.24, 0.14, 0.06, ice, M.Glass, extra)
	end
	table.insert(out, ball(0.18, CFrame.new(0, F.pommel - 0.04, 0), ice, M.Glass, extra))
	return out
end

-- a row of glowing rune dashes down the blade, both faces, and a lit pommel
T.runes = function(F, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(150, 110, 255)
	local n = F.hafted and 3 or 6
	for i = 1, n do
		local y = F.guard + (F.hafted and F.bLen * (0.3 + 0.18 * (i - 1)) or (0.2 + (F.bLen * 0.7) * (i - 1) / math.max(n - 1, 1)))
		local tall = (i % 2 == 0) and 0.14 or 0.08
		for _, z in ipairs({-1, 1}) do
			table.insert(out, block(Vector3.new(math.max(F.bW * (F.hafted and 0.3 or 0.25), 0.05), tall, 0.02), CFrame.new(F.bX, y, z * (F.bT * (F.hafted and 0.5 or 0.35) + 0.01)) * CFrame.Angles(0, 0, math.rad((i % 3 - 1) * 20)), glow, M.Neon))
		end
	end
	table.insert(out, ball(0.15, CFrame.new(0, F.pommel - 0.03, 0), glow, M.Neon))
	return out
end

-- swept wings on the guard, a jewel in its heart, a jewelled pommel
T.royal = function(F, P)
	local out = {}
	local gem = P.glow or Color3.fromRGB(60, 120, 255)
	local baseX = F.hafted and F.bX or 0
	local reach = F.hafted and F.bW * 0.35 + 0.1 or F.gW * 0.5
	for _, side in ipairs({-1, 1}) do
		thorn(out, along(Vector3.new(baseX + side * reach, F.guard - 0.04, 0), Vector3.new(side * 0.55, 1, 0)), 0.42, 0.2, 0.08, P.accent, M.Metal)
		thorn(out, along(Vector3.new(baseX + side * reach * 0.7, F.guard - 0.08, 0), Vector3.new(side * 0.9, 0.55, 0)), 0.3, 0.16, 0.07, P.accent, M.Metal)
	end
	for _, z in ipairs({-1, 1}) do table.insert(out, ball(0.15, CFrame.new(baseX, F.guard - 0.04, z * 0.08), gem, M.Glass)) end
	table.insert(out, ball(0.2, CFrame.new(0, F.pommel - 0.06, 0), gem, M.Glass))
	table.insert(out, ring(F.pommel + 0.06, F.d + 0.1, 0.06, P.accent, M.Metal))
	return out
end

-- a crown at the pommel, gold bands and a great jewel at the guard
T.crown = function(F, P)
	local out = {}
	local gem = P.glow or Color3.fromRGB(220, 40, 60)
	local y = F.pommel - 0.02
	table.insert(out, ring(y, 0.36, 0.1, P.accent, M.Metal))
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		thorn(out, along(Vector3.new(math.cos(a) * 0.15, y - 0.03, math.sin(a) * 0.15), Vector3.new(math.cos(a) * 0.2, -1, math.sin(a) * 0.2)), 0.2, 0.08, 0.04, P.accent, M.Metal)
	end
	table.insert(out, ball(0.14, CFrame.new(0, y - 0.1, 0), gem, M.Glass))
	local baseX = F.hafted and F.bX or 0
	for _, z in ipairs({-1, 1}) do table.insert(out, ball(0.2, CFrame.new(baseX, F.guard - 0.03, z * 0.09), gem, M.Glass)) end
	table.insert(out, ring(F.holdHi - 0.05, F.d + 0.1, 0.07, P.accent, M.Metal))
	table.insert(out, ring(F.holdLo + 0.05, F.d + 0.1, 0.07, P.accent, M.Metal))
	if not F.hafted then
		for _, side in ipairs({-1, 1}) do table.insert(out, ball(0.14, CFrame.new(side * F.gW / 2, F.guard - 0.06, 0), P.accent, M.Metal)) end
	end
	return out
end

-- a ring of light around the upper blade (or the head), gold guard caps
T.halo = function(F, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(255, 226, 140)
	local cy = F.hafted and (F.guard + F.bLen * 0.5) or (F.guard + F.bLen * 0.72)
	local r = F.hafted and math.max(F.bW, F.bT) * 0.75 + 0.15 or math.max(F.bW, 0.3) * 0.9 + 0.15
	local tilt = CFrame.Angles(math.rad(70), 0, math.rad(12))
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		local p = CFrame.new(F.bX, cy, 0) * tilt * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r)
		table.insert(out, block(Vector3.new(0.05, 0.05, r * 0.5), p * CFrame.Angles(0, -a, 0), glow, M.Neon))
	end
	if not F.hafted then
		for _, side in ipairs({-1, 1}) do table.insert(out, ball(0.15, CFrame.new(side * F.gW / 2, F.guard - 0.06, 0), P.accent, M.Metal)) end
	end
	table.insert(out, ball(0.16, CFrame.new(0, F.pommel - 0.04, 0), glow, M.Neon))
	return out
end

-- bone ribs across the grip, a skull pommel, fangs on the guard
T.bone = function(F, P)
	local out = {}
	for i = 0, 4 do
		local y = F.holdLo + (F.holdHi - F.holdLo) * i / 4
		table.insert(out, block(Vector3.new(F.d + 0.1, 0.06, F.d + 0.03), CFrame.new(0, y, 0), BONE, M.SmoothPlastic))
	end
	local sy = F.pommel - 0.1
	table.insert(out, ball(0.3, CFrame.new(0, sy, 0), BONE, M.SmoothPlastic))
	table.insert(out, block(Vector3.new(0.18, 0.1, 0.16), CFrame.new(0, sy - 0.14, -0.04), BONE, M.SmoothPlastic))
	for _, x in ipairs({-0.06, 0.06}) do table.insert(out, ball(0.08, CFrame.new(x, sy + 0.02, -0.12), Color3.fromRGB(20, 16, 14), M.SmoothPlastic)) end
	local baseX = F.hafted and F.bX or 0
	local reach = F.hafted and F.bW * 0.4 or F.gW * 0.45
	for _, side in ipairs({-1, 1}) do
		thorn(out, along(Vector3.new(baseX + side * reach, F.guard - 0.04, 0), Vector3.new(side * 0.3, 1, 0)), 0.26, 0.12, 0.08, BONE, M.SmoothPlastic)
	end
	return out
end

-- a serpent coiling up the grip / haft with its head at the guard
T.serpent = function(F, P)
	local out = {}
	local col = P.accent
	local lo, hi = F.holdLo, F.hafted and (F.guard - 0.1) or (F.guard - 0.05)
	local turns = F.hafted and 4 or 2
	local n = turns * 9
	local r = F.d / 2 + 0.05
	for i = 0, n do
		local f = i / n
		local a = f * turns * math.pi * 2
		table.insert(out, ball(0.1 + 0.03 * math.sin(f * math.pi), CFrame.new(math.cos(a) * r, lo + (hi - lo) * f, math.sin(a) * r), col, M.Metal))
	end
	local head = Vector3.new(0, hi + 0.08, -r)
	table.insert(out, ball(0.18, CFrame.new(head), col, M.Metal))
	for _, x in ipairs({-0.05, 0.05}) do table.insert(out, ball(0.05, CFrame.new(head + Vector3.new(x, 0.03, -0.08)), P.glow or Color3.fromRGB(80, 255, 120), M.Neon)) end
	return out
end

-- a wavy (flamberge) edge: little scallops out of both edges
T.wave = function(F, P)
	local out = {}
	if F.hafted then return T.notch(F, P) end
	local n = 8
	for i = 1, n do
		local y = F.guard + 0.2 + (F.bLen * 0.72) * (i - 1) / (n - 1)
		local side = (i % 2 == 0) and 1 or -1
		table.insert(out, block(Vector3.new(0.12, 0.22, math.max(F.bT * 0.5, 0.04)), CFrame.new(edge(F, y, side), y, 0) * CFrame.Angles(0, 0, math.rad(45)), P.blade, M.Metal))
	end
	table.insert(out, ring(F.guard + 0.1, math.max(F.bT, 0.2) + 0.1, 0.06, P.accent, M.Metal))
	return out
end

-- lightning: zig-zag bolts of light around the head / along the blade
T.thunder = function(F, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(150, 210, 255)
	for _, z in ipairs({-1, 1}) do
		local x, y = F.bX - F.bW * 0.25, F.guard + F.bLen * 0.15
		local stepY = F.bLen * 0.7 / 4
		for i = 1, 4 do
			local nx = F.bX + ((i % 2 == 0) and -1 or 1) * F.bW * 0.22
			local ny = y + stepY
			local a, b = Vector3.new(x, y, z * (F.bT / 2 + 0.01)), Vector3.new(nx, ny, z * (F.bT / 2 + 0.01))
			local mid = (a + b) / 2
			table.insert(out, block(Vector3.new(0.03, (b - a).Magnitude + 0.03, 0.07), along(mid, b - a), glow, M.Neon))
			x, y = nx, ny
		end
	end
	table.insert(out, ring(F.guard - 0.12, F.d + 0.1, 0.06, glow, M.Neon))
	return out
end

SkinTrims.NAMES = {}
for k in pairs(T) do table.insert(SkinTrims.NAMES, k) end
table.sort(SkinTrims.NAMES)

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
function SkinTrims.clear(tool)
	local old = tool:FindFirstChild("Trim")
	if old then old:Destroy() end
end

function SkinTrims.apply(tool, skin)
	SkinTrims.clear(tool)
	local builder = skin and skin.trim and T[skin.trim]
	if not builder then return false end
	local F = SkinTrims.frame(tool)
	if not F then return false end
	local P = {blade = skin.blade or STEEL, grip = skin.grip or LEATHER, accent = rarityAccent(skin), glow = skin.glow}
	local ok, specs = pcall(builder, F, P)
	if not ok or type(specs) ~= "table" then warn("[SkinTrims]", skin.trim, specs); return false end
	local folder = Instance.new("Folder")
	folder.Name = "Trim"
	local handle = F.handle
	local anchoredTool = handle.Anchored
	for i, s in ipairs(specs) do
		local p = Instance.new("Part")
		p.Name = "Trim" .. i
		p.Shape = Enum.PartType[s.shape] or Enum.PartType.Block
		p.Size = s.size
		p.Color = s.color or STEEL
		p.Material = s.material or M.SmoothPlastic
		p.Transparency = s.transparency or 0
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.Massless = true
		p.CastShadow = false
		p.Anchored = anchoredTool
		p.CFrame = handle.CFrame * s.cf
		p:SetAttribute("TrimPart", true)
		local w = Instance.new("Weld")
		w.Part0, w.Part1, w.C0 = handle, p, s.cf
		w.Parent = p
		p.Parent = folder
	end
	folder.Parent = tool
	return true
end

return SkinTrims
