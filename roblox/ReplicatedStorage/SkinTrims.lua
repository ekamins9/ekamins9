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

--------------------------------------------------------------------
--  RANGED TRIMS: a bow's limbs and a crossbow's prod are curves, not a blade
--  on a guard, so these fit to the shapes Build ▸ Weapons gives them:
--    G.at(f, side) → position, tangent (out along the limb), out-normal (the
--    belly: away from the string), for f 0 (the grip) .. 1 (the tip)
--    G.riser (the grip's front / the crossbow's lock), G.butt, G.nose, G.tiller
--------------------------------------------------------------------
-- (bigger than a sword's: a bow is seen from further off)
local RZ = 1.45
local function rthorn(out, cf, len, width, thick, color, material, extra) thorn(out, cf, len * RZ, width * RZ, thick * 1.25, color, material, extra) end
local function rvane(out, cf, len, width, color, material) vane(out, cf, len * RZ, width * RZ, color, material) end
local function rball(d, cf, color, material, extra) return ball(d * 1.3, cf, color, material, extra) end
local function rangedGeom(kind)
	if kind == "crossbow" then
		local c, tip0 = Vector3.new(0, 0.55, -2.28), 1.27
		local function at(f, side)
			local tip = Vector3.new(side * tip0, 0.55, -2.02)
			local t = (tip - c).Unit
			local n = Vector3.new(t.Z, 0, -t.X)
			if n.Z > 0 then n = -n end
			return c:Lerp(tip, f), t, n
		end
		return {kind = "crossbow", at = at, riser = Vector3.new(0, 0.72, -0.5), riserDir = Vector3.yAxis,
			butt = Vector3.new(0, 0.3, 1.52), nose = Vector3.new(0, 0.55, -2.62),
			tillerA = Vector3.new(0, 0.64, -2.2), tillerB = Vector3.new(0, 0.64, 0.4), w = 0.16}
	end
	local Rb, PHI = 4.0, 0.56
	local function at(f, side)
		local a = PHI * f
		return Vector3.new(0, side * Rb * math.sin(a), Rb * (1 - math.cos(a))),
			Vector3.new(0, side * math.cos(a), math.sin(a)), Vector3.new(0, side * math.sin(a), -math.cos(a))
	end
	return {kind = "bow", at = at, riser = Vector3.new(0, 0, -0.17), riserDir = Vector3.new(0, 0, -1), w = 0.18}
end
-- a band round a limb at f (a short cylinder across the limb's axis)
local function bandAt(out, G, f, side, d, thick, color, mat)
	local p, t = G.at(f, side)
	table.insert(out, spec("Cylinder", Vector3.new(thick, d, d), along(p, t) * CFrame.Angles(0, 0, math.pi / 2), color, mat or M.Metal))
end
-- a ring lying round an axis through `pos`
local function ringAround(out, pos, axis, d, thick, color, mat)
	table.insert(out, spec("Cylinder", Vector3.new(thick, d, d), along(pos, axis) * CFrame.Angles(0, 0, math.pi / 2), color, mat or M.Metal))
end
local SIDES = {-1, 1}
local RT = {}

-- metal bands down the limbs (and the tiller): plain and sturdy
RT.bands = function(G, P)
	local out = {}
	for _, s in ipairs(SIDES) do for _, f in ipairs({0.25, 0.55, 0.85}) do bandAt(out, G, f, s, G.w + 0.08, 0.06, P.accent) end end
	if G.kind == "crossbow" then
		for _, k in ipairs({0.15, 0.45, 0.85}) do ringAround(out, G.tillerA:Lerp(G.tillerB, k), Vector3.zAxis, 0.42, 0.07, P.accent) end
	end
	return out
end
-- feathers at the tips, leather wraps at the grip
RT.fletch = function(G, P)
	local out = {}
	for _, s in ipairs(SIDES) do
		local p, t, n = G.at(1, s)
		for i = -1, 1 do rvane(out, along(p, (t + n * 0.6 + Vector3.xAxis * i * 0.35).Unit), 0.5, 0.16, i == 0 and P.accent or P.blade, M.SmoothPlastic) end
		bandAt(out, G, 0.08, s, G.w + 0.06, 0.08, P.grip, M.Fabric)
	end
	return out
end
-- bone horns curling off each tip, bone collars by the grip
RT.horn = function(G, P)
	local out = {}
	for _, s in ipairs(SIDES) do
		local p, t, n = G.at(1, s)
		local pos, dir = p, t
		for i = 1, 4 do
			dir = (dir * 0.6 + n * 0.55).Unit
			pos = pos + dir * 0.18
			table.insert(out, rball(0.2 - i * 0.03, CFrame.new(pos), BONE, M.SmoothPlastic))
		end
		rthorn(out, along(pos, dir), 0.22, 0.1, 0.08, BONE, M.SmoothPlastic)
		for _, f in ipairs({0.12, 0.2}) do bandAt(out, G, f, s, G.w + 0.07, 0.06, BONE, M.SmoothPlastic) end
	end
	return out
end
-- thorns all down the belly, a thorn off each tip
RT.thorn = function(G, P)
	local out = {}
	for _, s in ipairs(SIDES) do
		for i = 1, 6 do
			local p, t, n = G.at(0.15 + i * 0.13, s)
			rthorn(out, along(p + n * G.w * 0.4, (n + t * 0.4).Unit), 0.24, 0.1, 0.07, P.accent, M.SmoothPlastic)
		end
		local p, t = G.at(1, s)
		rthorn(out, along(p, t), 0.3, 0.12, 0.08, P.accent, M.SmoothPlastic)
	end
	if G.kind == "crossbow" then
		for i = 0, 3 do rthorn(out, along(G.tillerA:Lerp(G.tillerB, i / 4) + Vector3.new(0, 0.15, 0), Vector3.new(0, 1, 0.3)), 0.22, 0.1, 0.06, P.accent, M.SmoothPlastic) end
	end
	return out
end
-- crystal clusters at the tips and a great crystal at the grip, lit
RT.crystal = function(G, P)
	local out = {}
	local c = P.glow or Color3.fromRGB(160, 220, 255)
	local x = {transparency = 0.1}
	for _, s in ipairs(SIDES) do
		local p, t, n = G.at(1, s)
		for i = -1, 1 do rthorn(out, along(p, (t + n * 0.3 * i + Vector3.xAxis * 0.4 * i).Unit), 0.34 - math.abs(i) * 0.1, 0.14, 0.12, c, M.Glass, x) end
		local q = G.at(0.5, s)
		table.insert(out, rball(0.14, CFrame.new(q), c, M.Neon))
	end
	rthorn(out, along(G.riser, G.riserDir), 0.34, 0.2, 0.18, c, M.Glass, x)
	table.insert(out, rball(0.16, CFrame.new(G.riser), c, M.Neon))
	return out
end
-- wings: feathered fans spread from the grip, a feather on each tip
RT.wing = function(G, P)
	local out = {}
	for _, s in ipairs(SIDES) do
		local base = G.at(0.18, s)
		for i = 1, 4 do
			local _, t, n = G.at(0.18 + i * 0.12, s)
			rvane(out, along(base, (n * 0.8 + t * (0.3 + i * 0.25)).Unit), 0.45 + i * 0.12, 0.18, i % 2 == 0 and P.accent or P.blade, M.SmoothPlastic)
		end
		local p, t, n = G.at(1, s)
		rvane(out, along(p, (t + n * 0.5).Unit), 0.36, 0.14, P.accent, M.SmoothPlastic)
	end
	return out
end
-- tongues of flame along the belly and off the tips, glowing
RT.ember = function(G, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(255, 140, 40)
	for _, s in ipairs(SIDES) do
		for i = 1, 5 do
			local p, t, n = G.at(0.2 + i * 0.14, s)
			rthorn(out, along(p + n * G.w * 0.3, (n + t * 0.6).Unit), 0.2 + 0.12 * (i % 2), 0.14, 0.05, glow, M.Neon)
		end
		local p, t = G.at(1, s)
		rthorn(out, along(p, t), 0.36, 0.16, 0.06, glow, M.Neon)
	end
	table.insert(out, rball(0.18, CFrame.new(G.riser), glow, M.Neon))
	return out
end
-- ice: glassy spikes off the belly, a burst at each tip
RT.frost = function(G, P)
	local out = {}
	local ice = P.glow or Color3.fromRGB(190, 236, 255)
	local x = {transparency = 0.15}
	for _, s in ipairs(SIDES) do
		for i = 1, 4 do
			local p, t, n = G.at(0.2 + i * 0.17, s)
			rthorn(out, along(p + n * G.w * 0.3, (n + t * 0.5).Unit), 0.22 + 0.06 * i, 0.12, 0.08, ice, M.Glass, x)
		end
		local p, t, n = G.at(1, s)
		for i = -1, 1 do rthorn(out, along(p, (t + n * 0.5 * i).Unit), 0.3, 0.12, 0.08, ice, M.Glass, x) end
	end
	table.insert(out, rball(0.2, CFrame.new(G.riser), ice, M.Glass, x))
	return out
end
-- runes: glowing bands at intervals, a lit gem at the grip
RT.runic = function(G, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(150, 110, 255)
	for _, s in ipairs(SIDES) do for i = 1, 4 do bandAt(out, G, 0.15 + i * 0.18, s, G.w + 0.05, 0.04, glow, M.Neon) end end
	table.insert(out, rball(0.18, CFrame.new(G.riser), glow, M.Neon))
	return out
end
-- a skull at the grip, bone ribs down the limbs, fangs at the tips
RT.skull = function(G, P)
	local out = {}
	local sk = G.riser + G.riserDir * 0.12
	table.insert(out, rball(0.34, CFrame.new(sk), BONE, M.SmoothPlastic))
	table.insert(out, block(Vector3.new(0.2, 0.12, 0.16), CFrame.new(sk + Vector3.new(0, -0.16, -0.06)), BONE, M.SmoothPlastic))
	for _, x in ipairs({-0.07, 0.07}) do table.insert(out, rball(0.09, CFrame.new(sk + Vector3.new(x, 0.03, -0.14)), P.glow or Color3.fromRGB(20, 16, 14), P.glow and M.Neon or M.SmoothPlastic)) end
	for _, s in ipairs(SIDES) do
		for i = 1, 4 do bandAt(out, G, 0.15 + i * 0.17, s, G.w + 0.06, 0.07, BONE, M.SmoothPlastic) end
		local p, t, n = G.at(1, s)
		rthorn(out, along(p, (t + n * 0.4).Unit), 0.3, 0.12, 0.08, BONE, M.SmoothPlastic)
	end
	return out
end
-- gilded: gold caps on the tips, gold bands, a jewel at the grip
RT.gilded = function(G, P)
	local out = {}
	for _, s in ipairs(SIDES) do
		table.insert(out, rball(0.22, CFrame.new((G.at(1, s))), GOLD, M.Metal))
		for _, f in ipairs({0.3, 0.6, 0.86}) do bandAt(out, G, f, s, G.w + 0.07, 0.06, GOLD, M.Metal) end
	end
	table.insert(out, rball(0.22, CFrame.new(G.riser), P.glow or Color3.fromRGB(220, 40, 60), M.Glass))
	ringAround(out, G.riser, G.riserDir, 0.32, 0.06, GOLD, M.Metal)
	return out
end
-- storm: zig-zag bolts down the limbs, lit tips
RT.storm = function(G, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(150, 210, 255)
	for _, s in ipairs(SIDES) do
		local prev
		for i = 0, 6 do
			local p, _, n = G.at(0.12 + i * 0.13, s)
			local q = p + n * (G.w * 0.6 + ((i % 2 == 0) and 0.12 or -0.02))
			if prev then
				table.insert(out, block(Vector3.new(0.03, (q - prev).Magnitude + 0.03, 0.07), along((prev + q) / 2, q - prev), glow, M.Neon))
			end
			prev = q
		end
		table.insert(out, rball(0.14, CFrame.new((G.at(1, s))), glow, M.Neon))
	end
	return out
end
-- venom: green barbs and drops of poison hanging off the tips
RT.venom = function(G, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(120, 255, 90)
	for _, s in ipairs(SIDES) do
		for i = 1, 4 do
			local p, t, n = G.at(0.2 + i * 0.17, s)
			rthorn(out, along(p + n * G.w * 0.3, (n - t * 0.4).Unit), 0.2, 0.1, 0.06, P.accent, M.SmoothPlastic)
		end
		local p = G.at(1, s)
		for k = 1, 3 do table.insert(out, rball(0.1 - k * 0.02, CFrame.new(p + Vector3.new(0, -0.12 * k, 0)), glow, M.Neon)) end
	end
	return out
end
-- blood: crimson barbs and veins of red light
RT.blood = function(G, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(220, 30, 40)
	for _, s in ipairs(SIDES) do
		for i = 1, 4 do bandAt(out, G, 0.12 + i * 0.2, s, G.w + 0.03, 0.03, glow, M.Neon) end
		for i = 1, 3 do
			local p, t, n = G.at(0.25 + i * 0.22, s)
			rthorn(out, along(p + n * G.w * 0.3, (n + t * 0.5).Unit), 0.26, 0.12, 0.07, P.blade, M.SmoothPlastic)
		end
	end
	table.insert(out, rball(0.2, CFrame.new(G.riser), glow, M.Neon))
	return out
end
-- void: obsidian shards round the tips, a violet core in a ring of motes at the grip
RT.void = function(G, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(150, 70, 230)
	local obs = Color3.fromRGB(24, 18, 32)
	for _, s in ipairs(SIDES) do
		local p, t, n = G.at(1, s)
		for i = -1, 1 do rthorn(out, along(p - t * 0.1, (t + n * 0.6 * i + Vector3.xAxis * 0.5 * i).Unit), 0.38, 0.14, 0.1, obs, M.Glass) end
		for i = 1, 3 do
			local q, tt, nn = G.at(0.2 + i * 0.2, s)
			rthorn(out, along(q + nn * G.w * 0.3, (nn + tt * 0.3).Unit), 0.22, 0.12, 0.08, obs, M.Glass)
		end
	end
	table.insert(out, rball(0.22, CFrame.new(G.riser), glow, M.Neon))
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local off = (G.kind == "bow") and Vector3.new(math.cos(a) * 0.34, math.sin(a) * 0.34, 0) or Vector3.new(math.cos(a) * 0.34, 0, math.sin(a) * 0.34)
		table.insert(out, rball(0.06, CFrame.new(G.riser + off), glow, M.Neon))
	end
	return out
end
-- a dragon: horns off the tips, a dorsal ridge (down the tiller), ember eyes
RT.dragon = function(G, P)
	local out = RT.horn(G, P)
	for _, s in ipairs(out) do s.color = P.accent end
	local glow = P.glow or Color3.fromRGB(255, 120, 40)
	if G.kind == "crossbow" then
		for i = 0, 5 do rthorn(out, along(G.tillerA:Lerp(G.tillerB, i / 6) + Vector3.new(0, 0.14, 0), Vector3.new(0, 1, 0.5)), 0.26 - i * 0.02, 0.14, 0.06, P.accent, M.SmoothPlastic) end
		for _, x in ipairs({-0.1, 0.1}) do table.insert(out, rball(0.08, CFrame.new(G.nose + Vector3.new(x, 0.12, 0.1)), glow, M.Neon)) end
	else
		for _, s in ipairs(SIDES) do
			for i = 1, 4 do
				local p, t, n = G.at(0.2 + i * 0.17, s)
				rthorn(out, along(p + n * G.w * 0.3, (n + t * 0.6).Unit), 0.2, 0.12, 0.06, P.accent, M.SmoothPlastic)
			end
		end
		table.insert(out, rball(0.16, CFrame.new(G.riser), glow, M.Neon))
	end
	return out
end
-- holy: a halo of light round the grip, gold-tipped limbs
RT.halo = function(G, P)
	local out = {}
	local glow = P.glow or Color3.fromRGB(255, 226, 140)
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		local off = (G.kind == "bow") and Vector3.new(math.cos(a) * 0.55, math.sin(a) * 0.55, -0.1) or Vector3.new(math.cos(a) * 0.5, 0.3, math.sin(a) * 0.5)
		table.insert(out, rball(0.08, CFrame.new(G.riser + off), glow, M.Neon))
	end
	for _, s in ipairs(SIDES) do
		local p, t = G.at(1, s)
		rthorn(out, along(p, t), 0.3, 0.14, 0.08, GOLD, M.Metal)
		for _, f in ipairs({0.4, 0.7}) do bandAt(out, G, f, s, G.w + 0.06, 0.05, GOLD, M.Metal) end
	end
	return out
end

SkinTrims.NAMES = {}
for k in pairs(T) do table.insert(SkinTrims.NAMES, k) end
for k in pairs(RT) do if not T[k] then table.insert(SkinTrims.NAMES, k) end end
table.sort(SkinTrims.NAMES)
SkinTrims.RANGED = RT   -- (bows and crossbows: their own trim set)

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
function SkinTrims.clear(tool)
	local old = tool:FindFirstChild("Trim")
	if old then old:Destroy() end
end

function SkinTrims.apply(tool, skin)
	SkinTrims.clear(tool)
	if not (skin and skin.trim) then return false end
	local P = {blade = skin.blade or STEEL, grip = skin.grip or LEATHER, accent = rarityAccent(skin), glow = skin.glow}
	local ok, specs, F
	-- a bow or a crossbow: the ranged set, fitted to its limbs / prod
	if skin.weapon == "Bow" or skin.weapon == "Crossbow" then
		local builder = RT[skin.trim]
		local handle = tool:FindFirstChild("Handle")
		if not (builder and handle and handle:IsA("BasePart")) then return false end
		F = {handle = handle}
		ok, specs = pcall(builder, rangedGeom(skin.weapon == "Crossbow" and "crossbow" or "bow"), P)
	else
		local builder = T[skin.trim]
		if not builder then return false end
		F = SkinTrims.frame(tool)
		if not F then return false end
		ok, specs = pcall(builder, F, P)
	end
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
