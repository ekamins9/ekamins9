--[[ EMOTE FX — what an emote does besides move: the rarer it is, the more it
     does. A Common glints, a Rare kicks up dust and leaves a trail, an Epic
     sends out shockwaves and music, a Legendary raises a whirlwind or a pillar
     of light, and a Mythic calls lightning down or lifts you on wings.

     Every effect is a function of the emote's clock, built from glowing parts,
     so it plays the same on a character in the world (every client, in step
     with ReplicatedStorage ▸ Emotes) and in a menu preview (a ViewportFrame,
     looping). Sounds, lights, music notes and the blade's trail only exist in
     the world.

       EmoteFX.new(model, id, container, preview) -> fx   fx:update(t) · fx:destroy()
       EmoteFX.attach(character, id)   a live emote: runs until Emotes.playing(character) changes
       EmoteFX.DEF[id] = {cues}        the cues below; an emote with none does nothing extra

     A CUE: {kind, t = start (s), d = duration (s), at = where, color = Color3, …}
       at:     feet · chest · head · tip (the blade's tip) · hand · lhand · sky (above the tip)
       ring    a shockwave on the ground (r0 → r1 studs, thick)
       pillar  a column of light (w wide, h tall)
       burst   bits flung out and falling (n, speed, size, grav)
       motes   embers / dust rising round you (n, r, h, speed)
       orbit   streaks whirling round you (rings = {{height, radius}…}, n, speed)
       bolt    lightning from the sky (to = tip / feet)
       spark   electricity crawling over the blade
       glint   a four-pointed star flashing
       wings   two fans of light from the back (span)
       halo    a ring of light over the head
       cloud   a storm cloud gathering above
       scorch  a burnt patch on the ground
       confetti, notes (♪ in the world, motes in a preview)
       light   (world) a glow · sound (world) {id, vol, speed, cut} · trail (world) the blade's
     Licensed library sounds only (Pro Sound Effects, APM). ]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EmoteFX = {}

local C = Color3.fromRGB
local WHITE, GOLD, HOLY, STORM, EMBER, DUST, BLOOD = C(255, 255, 255), C(255, 206, 90), C(255, 240, 200), C(150, 205, 255), C(255, 130, 50), C(196, 178, 150), C(220, 60, 50)
local PARTY = {C(255, 80, 80), C(255, 200, 60), C(80, 220, 120), C(80, 170, 255), C(200, 110, 255)}
-- sounds (Pro Sound Effects / APM)
local SHING, WHOOSH, THUD, BOOM, HORN, SWIRL, HUM = 9119742466, 9120709477, 9046338796, 1835337001, 9114821239, 9125899162, 9112889082
local ZAP1, ZAP2, ZAP3, CHOIR, STING = 9116279560, 9116275998, 9116277954, 1846902441, 1835295052

-- the jig's stamps: every half-swing of its legs (sin(13t) peaks)
local function stamps(from, to)
	local out = {}
	local k = 0
	while true do
		local t = (math.pi / 2 + math.pi * k) / 13
		if t > to then break end
		if t >= from then table.insert(out, t) end
		k += 1
	end
	return out
end

EmoteFX.DEF = {
	-- COMMON: a touch
	Salute = {
		{"glint", t = 0.36, d = 0.45, at = "tip", color = WHITE, size = 1.8},
		{"sound", t = 0.32, id = SHING, vol = 0.25, speed = 1.35, cut = 0.8},
	},
	Bow = {
		{"glint", t = 0.2, d = 0.35, at = "lhand", color = GOLD, size = 1.0},
		{"ring", t = 0.8, d = 0.7, at = "feet", color = DUST, r0 = 0.6, r1 = 3.4, thick = 0.12, alpha = 0.45},
	},
	Cheer = {
		{"confetti", t = 0.36, d = 1.6, at = "hand", n = 16},
		{"confetti", t = 0.36, d = 1.6, at = "lhand", n = 16},
	},
	Wave = {
		{"glint", t = 0.55, d = 0.3, at = "lhand", color = GOLD, size = 0.9},
		{"glint", t = 1.1, d = 0.3, at = "lhand", color = GOLD, size = 0.9},
	},
	Shrug = {
		{"glint", t = 0.4, d = 0.3, at = "hand", color = STORM, size = 0.8},
		{"glint", t = 0.4, d = 0.3, at = "lhand", color = STORM, size = 0.8},
	},
	-- RARE: dust, trails, rings
	Flourish = {
		{"trail", t = 0.3, d = 1.0, color = STORM},
		{"glint", t = 0.6, d = 0.25, at = "tip", color = STORM, size = 1.2},
		{"glint", t = 0.9, d = 0.25, at = "tip", color = STORM, size = 1.2},
		{"glint", t = 1.42, d = 0.5, at = "tip", color = WHITE, size = 2.4},
		{"ring", t = 1.42, d = 0.6, at = "chest", color = STORM, r0 = 0.5, r1 = 2.6, thick = 0.08, alpha = 0.3},
		{"sound", t = 0.35, id = WHOOSH, vol = 0.3, speed = 1.2},
		{"sound", t = 0.75, id = WHOOSH, vol = 0.3, speed = 1.3},
		{"sound", t = 1.4, id = SHING, vol = 0.35, speed = 1.25, cut = 1},
	},
	Beckon = {
		{"motes", t = 0.25, d = 1.6, at = "feet", color = DUST, n = 12, r = 1.6, h = 2.5, speed = 0.9, size = 0.22},
		{"glint", t = 0.5, d = 0.25, at = "lhand", color = EMBER, size = 0.9},
		{"glint", t = 1.02, d = 0.25, at = "lhand", color = EMBER, size = 0.9},
		{"glint", t = 1.54, d = 0.25, at = "lhand", color = EMBER, size = 0.9},
	},
	Kneel = {
		{"ring", t = 0.4, d = 0.8, at = "feet", color = DUST, r0 = 0.8, r1 = 4.5, thick = 0.15, alpha = 0.35},
		{"burst", t = 0.4, d = 0.8, at = "feet", color = DUST, n = 12, speed = 7, size = 0.3, grav = 30},
		{"motes", t = 0.7, d = 2.2, at = "feet", color = GOLD, n = 14, r = 1.8, h = 5, speed = 0.5, size = 0.2},
		{"glint", t = 2.1, d = 0.5, at = "tip", color = GOLD, size = 1.6},
		{"sound", t = 0.38, id = THUD, vol = 0.45, speed = 0.55, cut = 0.8},
	},
	Laugh = {
		{"burst", t = 0.25, d = 0.9, at = "head", color = GOLD, n = 8, speed = 6, size = 0.2, grav = 10},
		{"burst", t = 1.25, d = 0.7, at = "lhand", color = GOLD, n = 6, speed = 5, size = 0.18, grav = 10},
	},
	-- EPIC: shockwaves, music, a horn
	Jig = (function()
		local cues = {{"notes", t = 0.25, d = 3.1, at = "head", color = GOLD}, {"confetti", t = 3.0, d = 1.2, at = "chest", n = 26},
			{"orbit", t = 1.5, d = 0.65, at = "feet", color = GOLD, rings = {{1.2, 2.2}}, n = 10, speed = 9}}
		for i, st in ipairs(stamps(0.3, 3.2)) do
			table.insert(cues, {"ring", t = st, d = 0.45, at = "feet", color = PARTY[(i - 1) % #PARTY + 1], r0 = 0.5, r1 = 2.8, thick = 0.1, alpha = 0.2})
			table.insert(cues, {"sound", t = st, id = THUD, vol = 0.22, speed = 0.9 + (i % 3) * 0.08, cut = 0.3})
		end
		return cues
	end)(),
	HelmetToss = {
		{"glint", t = 0.5, d = 0.3, at = "head", color = WHITE, size = 1.4},
		{"sound", t = 0.5, id = SHING, vol = 0.22, speed = 0.8, cut = 0.6},
		{"sound", t = 1.1, id = WHOOSH, vol = 0.4, speed = 0.85},
		{"burst", t = 2.05, d = 0.6, at = "head", color = WHITE, n = 8, speed = 5, size = 0.18, grav = 8},
	},
	WarCry = {
		{"ring", t = 0.5, d = 0.7, at = "feet", color = EMBER, r0 = 0.8, r1 = 9, thick = 0.25, alpha = 0.1},
		{"ring", t = 0.64, d = 0.6, at = "feet", color = BLOOD, r0 = 0.6, r1 = 6, thick = 0.18, alpha = 0.2},
		{"burst", t = 0.5, d = 0.9, at = "feet", color = DUST, n = 18, speed = 12, size = 0.35, grav = 35},
		{"motes", t = 0.55, d = 1.6, at = "feet", color = EMBER, n = 18, r = 2.2, h = 7, speed = 1.4, size = 0.22},
		{"light", t = 0.5, d = 1.6, at = "chest", color = EMBER, brightness = 3, range = 16},
		{"sound", t = 0.48, id = HORN, vol = 0.45, speed = 1.0, cut = 2.2},
		{"sound", t = 0.5, id = BOOM, vol = 0.35, speed = 0.8, cut = 1.6},
	},
	BladeToss = {
		{"trail", t = 0.38, d = 1.2, color = GOLD},
		{"glint", t = 0.9, d = 0.35, at = "tip", color = WHITE, size = 2.2},
		{"burst", t = 1.58, d = 0.7, at = "hand", color = GOLD, n = 12, speed = 8, size = 0.22, grav = 18},
		{"ring", t = 1.58, d = 0.5, at = "hand", color = GOLD, r0 = 0.3, r1 = 2.2, thick = 0.08, alpha = 0.2},
		{"sound", t = 0.4, id = WHOOSH, vol = 0.35, speed = 0.9},
		{"sound", t = 1.56, id = SHING, vol = 0.4, speed = 1.15, cut = 1},
	},
	-- LEGENDARY: a whirlwind, a pillar of light
	Windmill = {
		{"orbit", t = 0.3, d = 2.55, at = "feet", color = C(220, 240, 255), rings = {{0.6, 3.4}, {2.6, 2.8}, {4.6, 2.2}}, n = 9, speed = 7},
		{"motes", t = 0.4, d = 2.4, at = "feet", color = C(150, 200, 120), n = 14, r = 3, h = 6, speed = 1.2, size = 0.24, swirl = 4},
		{"spark", t = 0.7, d = 1.9, at = "tip", color = STORM},
		{"light", t = 0.4, d = 2.5, at = "chest", color = STORM, brightness = 2.5, range = 18},
		{"ring", t = 2.95, d = 0.6, at = "feet", color = WHITE, r0 = 0.8, r1 = 8, thick = 0.2, alpha = 0.15},
		{"burst", t = 2.95, d = 0.8, at = "feet", color = DUST, n = 14, speed = 10, size = 0.3, grav = 30},
		{"sound", t = 0.3, id = SWIRL, vol = 0.45, speed = 1.25, cut = 2.6},
		{"sound", t = 0.6, id = WHOOSH, vol = 0.3, speed = 0.9},
		{"sound", t = 1.3, id = WHOOSH, vol = 0.32, speed = 1.0},
		{"sound", t = 2.0, id = WHOOSH, vol = 0.34, speed = 1.1},
		{"sound", t = 2.95, id = BOOM, vol = 0.3, speed = 1.1, cut = 1.2},
	},
	Champion = {
		{"ring", t = 0.75, d = 0.9, at = "feet", color = GOLD, r0 = 1, r1 = 11, thick = 0.25, alpha = 0.05},
		{"burst", t = 0.75, d = 1.0, at = "tip", color = GOLD, n = 22, speed = 13, size = 0.28, grav = 28},
		{"scorch", t = 0.75, d = 3.0, at = "tip", color = C(40, 30, 20), r = 1.6},
		{"pillar", t = 0.78, d = 2.6, at = "tip", color = GOLD, w = 1.4, h = 60, alpha = 0.6},
		{"motes", t = 0.85, d = 2.6, at = "feet", color = GOLD, n = 20, r = 2.6, h = 8, speed = 0.7, size = 0.24},
		{"halo", t = 1.0, d = 2.5, color = GOLD},
		{"light", t = 0.75, d = 2.7, at = "chest", color = GOLD, brightness = 3, range = 20},
		{"sound", t = 0.75, id = BOOM, vol = 0.45, speed = 0.9, cut = 2},
		{"sound", t = 0.82, id = STING, vol = 0.4, cut = 3},
	},
	-- MYTHIC: the storm, the wings
	Thunderlord = {
		{"cloud", t = 0.35, d = 3.4, at = "sky", color = C(46, 50, 62)},
		{"spark", t = 0.8, d = 2.3, at = "tip", color = STORM},
		{"bolt", t = 1.25, d = 0.24, to = "tip", color = C(210, 235, 255)},
		{"bolt", t = 1.95, d = 0.24, to = "tip", color = C(210, 235, 255)},
		{"bolt", t = 2.65, d = 0.28, to = "tip", color = C(210, 235, 255)},
		{"glint", t = 1.27, d = 0.3, at = "tip", color = WHITE, size = 3},
		{"glint", t = 1.97, d = 0.3, at = "tip", color = WHITE, size = 3},
		{"glint", t = 2.67, d = 0.35, at = "tip", color = WHITE, size = 3.6},
		{"bolt", t = 3.5, d = 0.35, to = "feet", color = WHITE},
		{"ring", t = 3.5, d = 0.9, at = "feet", color = STORM, r0 = 1, r1 = 13, thick = 0.3, alpha = 0.05},
		{"ring", t = 3.6, d = 0.8, at = "feet", color = WHITE, r0 = 0.6, r1 = 8, thick = 0.2, alpha = 0.2},
		{"scorch", t = 3.5, d = 3.5, at = "feet", color = C(25, 25, 30), r = 4},
		{"burst", t = 3.5, d = 1.0, at = "feet", color = STORM, n = 26, speed = 16, size = 0.25, grav = 30},
		{"light", t = 0.8, d = 2.4, at = "tip", color = STORM, brightness = 2, range = 14, flicker = true},
		{"light", t = 3.5, d = 0.6, at = "feet", color = WHITE, brightness = 8, range = 30},
		{"sound", t = 0.8, id = HUM, vol = 0.18, speed = 1.4, cut = 2.4},
		{"sound", t = 1.25, id = ZAP1, vol = 0.5},
		{"sound", t = 1.3, id = BOOM, vol = 0.5, speed = 0.55, cut = 2.2},
		{"sound", t = 1.95, id = ZAP2, vol = 0.5},
		{"sound", t = 2.0, id = BOOM, vol = 0.5, speed = 0.6, cut = 2.2},
		{"sound", t = 2.65, id = ZAP1, vol = 0.55, speed = 0.9},
		{"sound", t = 2.7, id = BOOM, vol = 0.55, speed = 0.52, cut = 2.2},
		{"sound", t = 3.5, id = ZAP3, vol = 0.6},
		{"sound", t = 3.5, id = BOOM, vol = 0.8, speed = 0.45, cut = 3},
	},
	Ascension = {
		{"ring", t = 0.5, d = 0.8, at = "feet", color = GOLD, r0 = 0.6, r1 = 5, thick = 0.12, alpha = 0.2},
		{"pillar", t = 1.0, d = 3.5, at = "feet", color = HOLY, w = 3.6, h = 70, alpha = 0.82},
		{"wings", t = 1.0, d = 3.6, color = HOLY, span = 1.8},
		{"halo", t = 1.2, d = 3.4, color = GOLD},
		{"motes", t = 1.0, d = 3.4, at = "feet", color = HOLY, n = 24, r = 2.4, h = 9, speed = 0.6, size = 0.22},
		{"light", t = 1.0, d = 3.6, at = "chest", color = HOLY, brightness = 3, range = 22},
		{"ring", t = 4.55, d = 0.8, at = "feet", color = WHITE, r0 = 0.8, r1 = 10, thick = 0.2, alpha = 0.1},
		{"burst", t = 4.55, d = 1.0, at = "feet", color = HOLY, n = 20, speed = 11, size = 0.24, grav = 20},
		{"sound", t = 1.0, id = CHOIR, vol = 0.45, cut = 4.2},
		{"sound", t = 4.55, id = BOOM, vol = 0.35, speed = 1.2, cut = 1.4},
	},
}

--------------------------------------------------------------------
--  BUILDING BLOCKS
--------------------------------------------------------------------
local function part(fx, size, color, shape, material)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = material or Enum.Material.Neon
	p.Color = color or WHITE
	p.Size = size
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = fx.container
	return p
end
local function ease(k) return 1 - (1 - k) ^ 3 end
local function fadeInOut(k, inn, out) return math.clamp(k / inn, 0, 1) * math.clamp((1 - k) / out, 0, 1) end
local UP = Vector3.yAxis

-- the blade's tip: the weapon in hand (a Tool, or a preview's WeaponPreview),
-- never a copy worn on the hip or back
local function findTip(m)
	local held = m:FindFirstChildOfClass("Tool") or m:FindFirstChild("WeaponPreview")
	for _, d in ipairs(held and held:GetDescendants() or {}) do
		if d:IsA("Attachment") and d.Name == "TrailTip" then return d end
	end
	return nil
end

-- where things are this frame, from the model's parts (a live character or a posed preview rig)
local function anchors(m, fx)
	local root = m:FindFirstChild("HumanoidRootPart")
	local torso = m:FindFirstChild("Torso")
	if not (root and torso) then return nil end
	local head = m:FindFirstChild("Head")
	local arm, larm = m:FindFirstChild("Right Arm"), m:FindFirstChild("Left Arm")
	local hand = arm and (arm.CFrame * Vector3.new(0, -1, 0)) or torso.Position
	if not (fx.tipAtt and fx.tipAtt:IsDescendantOf(m)) and (os.clock() - (fx.tipLook or 0) > 0.5) then
		fx.tipLook = os.clock()
		fx.tipAtt = findTip(m)
	end
	local tip = (fx.tipAtt and fx.tipAtt.Parent) and fx.tipAtt.WorldPosition or (hand + (arm and -arm.CFrame.UpVector or UP) * 3)
	return {
		root = root.CFrame, torso = torso.CFrame, feet = root.Position - Vector3.new(0, 2.95, 0), chest = torso.Position,
		head = head and head.Position or torso.Position + UP * 1.5, hand = hand, lhand = larm and (larm.CFrame * Vector3.new(0, -1, 0)) or hand,
		tip = tip, sky = tip + UP * 16,
	}
end

--------------------------------------------------------------------
--  THE CUES: each is make(fx, cue, rng) -> state, and draw(state, k, a, t)
--  (k = 0..1 through the cue, a = this frame's anchors, t = seconds into the cue)
--------------------------------------------------------------------
local KIND = {}

-- a shockwave: a circle of short glowing segments growing and fading
KIND.ring = {
	make = function(fx, cue)
		local n = 22
		local segs = {}
		for i = 1, n do segs[i] = part(fx, Vector3.new(1, cue.thick or 0.15, 0.18), cue.color) end
		return {segs = segs, n = n}
	end,
	draw = function(st, cue, k, a)
		local c = a[cue.at or "feet"] + UP * 0.1
		local r = (cue.r0 or 0.5) + ((cue.r1 or 4) - (cue.r0 or 0.5)) * ease(k)
		local len = 2 * math.pi * r / st.n * 1.08
		local tr = (cue.alpha or 0.2) + (1 - (cue.alpha or 0.2)) * k ^ 1.5
		for i, s in ipairs(st.segs) do
			local ang = (i / st.n) * math.pi * 2
			s.Size = Vector3.new(len, cue.thick or 0.15, 0.18 * (1 - 0.6 * k) + 0.05)
			s.CFrame = CFrame.new(c + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)) * CFrame.Angles(0, -ang + math.pi / 2, 0)
			s.Transparency = tr
		end
	end,
}

-- a column of light: rises fast, holds, fades
KIND.pillar = {
	make = function(fx, cue)
		return {outer = part(fx, Vector3.new(1, 1, 1), cue.color, Enum.PartType.Cylinder), core = part(fx, Vector3.new(1, 1, 1), WHITE, Enum.PartType.Cylinder)}
	end,
	draw = function(st, cue, k, a)
		local base = a[cue.at or "feet"]
		local grow = ease(math.clamp(k / 0.15, 0, 1))
		local h = (cue.h or 40) * grow
		local w = (cue.w or 1.5) * (1 + 0.05 * math.sin(k * 40))
		local fade = fadeInOut(k, 0.08, 0.3)
		local cf = CFrame.new(base + UP * h / 2) * CFrame.Angles(0, 0, math.pi / 2)
		st.outer.Size, st.outer.CFrame = Vector3.new(math.max(h, 0.1), w, w), cf
		st.outer.Transparency = 1 - fade * (1 - (cue.alpha or 0.7))
		st.core.Size, st.core.CFrame = Vector3.new(math.max(h, 0.1), w * 0.3, w * 0.3), cf
		st.core.Transparency = 1 - fade * 0.45
	end,
}

-- bits flung out and falling
KIND.burst = {
	make = function(fx, cue, rng)
		local bits = {}
		for i = 1, cue.n or 10 do
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.3, 1.2), rng:NextNumber(-1, 1)).Unit
			local col = type(cue.color) == "table" and cue.color[rng:NextInteger(1, #cue.color)] or cue.color
			bits[i] = {p = part(fx, Vector3.one * (cue.size or 0.25), col, Enum.PartType.Ball), v = dir * (cue.speed or 8) * rng:NextNumber(0.5, 1)}
		end
		return {bits = bits}
	end,
	draw = function(st, cue, k, a, t)
		if not st.origin then st.origin = a[cue.at or "chest"] end   -- (flung from where it started)
		local g = cue.grav or 25
		for _, b in ipairs(st.bits) do
			b.p.Position = st.origin + b.v * t - UP * (0.5 * g * t * t)
			b.p.Size = Vector3.one * (cue.size or 0.25) * (1 - 0.7 * k)
			b.p.Transparency = k ^ 1.4
		end
	end,
}

-- embers / dust rising round you, round and round
KIND.motes = {
	make = function(fx, cue, rng)
		local m = {}
		for i = 1, cue.n or 12 do
			m[i] = {p = part(fx, Vector3.one * (cue.size or 0.2), cue.color, Enum.PartType.Ball), ang = rng:NextNumber(0, math.pi * 2), r = rng:NextNumber(0.4, 1) * (cue.r or 2), phase = rng:NextNumber()}
		end
		return {m = m}
	end,
	draw = function(st, cue, k, a, t)
		local base = a[cue.at or "feet"]
		local fade = fadeInOut(k, 0.12, 0.25)
		for _, m in ipairs(st.m) do
			local y = (t * (cue.speed or 0.6) + m.phase) % 1
			local ang = m.ang + t * (cue.swirl or 0.8)
			m.p.Position = base + Vector3.new(math.cos(ang) * m.r, y * (cue.h or 5), math.sin(ang) * m.r)
			m.p.Transparency = 1 - fade * (1 - y) * 0.95
		end
	end,
}

-- streaks whirling round you (a whirlwind)
KIND.orbit = {
	make = function(fx, cue)
		local s = {}
		for j, ring in ipairs(cue.rings or {{1, 2}}) do
			for i = 1, cue.n or 8 do table.insert(s, {p = part(fx, Vector3.new(1.4, 0.1, 0.1), cue.color), h = ring[1], r = ring[2], off = (i / (cue.n or 8)) * math.pi * 2, dir = j % 2 == 0 and -1 or 1}) end
		end
		return {s = s}
	end,
	draw = function(st, cue, k, a, t)
		local base = a[cue.at or "feet"]
		local fade = fadeInOut(k, 0.15, 0.2)
		for _, s in ipairs(st.s) do
			local ang = s.off + s.dir * t * (cue.speed or 6)
			local pos = base + Vector3.new(math.cos(ang) * s.r, s.h + 0.3 * math.sin(t * 5 + s.off), math.sin(ang) * s.r)
			s.p.Size = Vector3.new(1.2 + s.r * 0.4, 0.09, 0.09)
			s.p.CFrame = CFrame.new(pos) * CFrame.Angles(0, -ang + (s.dir > 0 and 0 or math.pi), 0)
			s.p.Transparency = 1 - fade * 0.65
		end
	end,
}

-- lightning: a jagged line from the sky, flickering
KIND.bolt = {
	make = function(fx, cue)
		local segs = {}
		for i = 1, 12 do segs[i] = part(fx, Vector3.new(0.3, 0.3, 1), cue.color) end
		return {segs = segs, rng = Random.new(), seedAt = -1}
	end,
	draw = function(st, cue, k, a, t)
		local to = a[cue.to or "tip"]
		local from = to + Vector3.new(2.5, 26, -1.5)
		local frame = math.floor(t * 30)
		if frame ~= st.seedAt then
			st.seedAt = frame
			st.pts = {from}
			for i = 1, #st.segs - 1 do
				local f = i / #st.segs
				local jit = (1 - math.abs(f - 0.5) * 2) * 1.8 + 0.3
				table.insert(st.pts, from:Lerp(to, f) + Vector3.new(st.rng:NextNumber(-jit, jit), 0, st.rng:NextNumber(-jit, jit)))
			end
			table.insert(st.pts, to)
		end
		local on = (frame % 4) ~= 3
		local w = 0.35 * (1 - 0.5 * k)
		for i, s in ipairs(st.segs) do
			local p0, p1 = st.pts[i], st.pts[i + 1]
			local len = (p1 - p0).Magnitude
			s.Size = Vector3.new(w, w, len)
			s.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
			s.Transparency = on and (k * 0.6) or 1
		end
	end,
}

-- electricity crawling round the blade's tip
KIND.spark = {
	make = function(fx, cue)
		local s = {}
		for i = 1, 6 do s[i] = part(fx, Vector3.new(0.08, 0.08, 1), cue.color) end
		return {s = s, rng = Random.new()}
	end,
	draw = function(st, cue, k, a, t)
		local c = a[cue.at or "tip"]
		local fade = fadeInOut(k, 0.1, 0.15)
		for i, s in ipairs(st.s) do
			local p0 = c + Vector3.new(st.rng:NextNumber(-0.8, 0.8), st.rng:NextNumber(-1.6, 0.4), st.rng:NextNumber(-0.8, 0.8))
			local p1 = p0 + Vector3.new(st.rng:NextNumber(-0.9, 0.9), st.rng:NextNumber(-0.9, 0.9), st.rng:NextNumber(-0.9, 0.9))
			s.Size = Vector3.new(0.08, 0.08, (p1 - p0).Magnitude)
			s.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
			s.Transparency = (st.rng:NextNumber() < 0.35) and 1 or (1 - fade * 0.9)
		end
	end,
}

-- a four-pointed star flashing (two thin crossed blades of light, turning)
KIND.glint = {
	make = function(fx, cue)
		return {a = part(fx, Vector3.new(0.1, 1, 0.1), cue.color), b = part(fx, Vector3.new(1, 0.1, 0.1), cue.color), c = part(fx, Vector3.one * 0.3, WHITE, Enum.PartType.Ball)}
	end,
	draw = function(st, cue, k, a, t, fx)
		local p = a[cue.at or "tip"]
		local s = (cue.size or 1.4) * math.sin(math.clamp(k, 0, 1) * math.pi)
		-- (faces the camera, so it reads as a star from anywhere)
		local cam = fx.camera and fx.camera.CFrame or CFrame.new()
		local cf = CFrame.lookAt(p, p + cam.LookVector) * CFrame.Angles(0, 0, t * 3)
		st.a.Size, st.a.CFrame = Vector3.new(0.09, math.max(s, 0.01), 0.05), cf
		st.b.Size, st.b.CFrame = Vector3.new(math.max(s * 0.7, 0.01), 0.09, 0.05), cf
		st.c.Size, st.c.Position = Vector3.one * math.max(s * 0.22, 0.01), p
		st.a.Transparency, st.b.Transparency, st.c.Transparency = 0.05, 0.05, 0.2
	end,
}

-- two fans of light from the back, opening
KIND.wings = {
	make = function(fx, cue)
		local f = {}
		for side = -1, 1, 2 do
			for i = 1, 9 do table.insert(f, {p = part(fx, Vector3.new(0.3, 1, 0.08), cue.color), side = side, i = i}) end
		end
		return {f = f}
	end,
	draw = function(st, cue, k, a, t)
		local open = ease(math.clamp(k / 0.25, 0, 1)) * math.clamp((1 - k) / 0.12, 0, 1)
		local flap = 1 + 0.08 * math.sin(t * 3)
		for _, f in ipairs(st.f) do
			local frac = (f.i - 1) / 8
			local ang = math.rad(-30 + 110 * frac) * open * flap
			local len = (3.2 - math.abs(frac - 0.45) * 2.2) * (cue.span or 1) * (0.3 + 0.7 * open)
			local base = a.torso * Vector3.new(f.side * 0.35, 0.4, 0.6)
			local dir = a.torso:VectorToWorldSpace(Vector3.new(f.side * math.cos(ang), math.sin(ang), 0.35).Unit)
			f.p.Size = Vector3.new(0.32 - 0.12 * frac, math.max(len, 0.05), 0.08)
			f.p.CFrame = CFrame.lookAt(base + dir * len / 2, base + dir * len / 2 + a.torso.LookVector, dir)
			f.p.Transparency = 1 - open * 0.75
		end
	end,
}

-- a ring of light over the head
KIND.halo = {
	make = function(fx, cue)
		local b = {}
		for i = 1, 12 do b[i] = part(fx, Vector3.one * 0.22, cue.color, Enum.PartType.Ball) end
		return {b = b}
	end,
	draw = function(st, cue, k, a, t)
		local c = a.head + UP * 1.25
		local fade = fadeInOut(k, 0.15, 0.2)
		for i, b in ipairs(st.b) do
			local ang = i / #st.b * math.pi * 2 + t * 1.2
			b.Position = c + Vector3.new(math.cos(ang) * 0.95, 0, math.sin(ang) * 0.95)
			b.Transparency = 1 - fade * 0.85
		end
	end,
}

-- a storm cloud gathering overhead
KIND.cloud = {
	make = function(fx, cue, rng)
		local b = {}
		for i = 1, 14 do b[i] = {p = part(fx, Vector3.one, cue.color, Enum.PartType.Ball, Enum.Material.SmoothPlastic), o = Vector3.new(rng:NextNumber(-5, 5), rng:NextNumber(-1, 1), rng:NextNumber(-5, 5)), s = rng:NextNumber(2.5, 4.5)} end
		return {b = b}
	end,
	draw = function(st, cue, k, a, t)
		local c = a.root.Position + UP * 18
		local grow = ease(math.clamp(k / 0.3, 0, 1))
		local fade = math.clamp((1 - k) / 0.2, 0, 1)
		for i, b in ipairs(st.b) do
			b.p.Size = Vector3.one * b.s * grow
			b.p.Position = c + b.o * grow + Vector3.new(math.sin(t + i), 0, math.cos(t * 0.7 + i)) * 0.3
			b.p.Transparency = 1 - fade * 0.7
		end
	end,
}

-- a burnt patch on the ground
KIND.scorch = {
	make = function(fx, cue)
		return {d = part(fx, Vector3.new(0.06, 1, 1), cue.color, Enum.PartType.Cylinder, Enum.Material.SmoothPlastic)}
	end,
	draw = function(st, cue, k, a)
		if not st.at then local p = a[cue.at or "feet"]; st.at = Vector3.new(p.X, a.feet.Y + 0.04, p.Z) end
		local r = (cue.r or 2) * ease(math.clamp(k / 0.1, 0, 1))
		st.d.Size = Vector3.new(0.06, r * 2, r * 2)
		st.d.CFrame = CFrame.new(st.at) * CFrame.Angles(0, 0, math.pi / 2)
		st.d.Transparency = 0.25 + 0.75 * math.clamp((k - 0.5) / 0.5, 0, 1)
	end,
}

-- confetti: bright slips shot up, fluttering down
KIND.confetti = {
	make = function(fx, cue, rng)
		local c = {}
		for i = 1, cue.n or 16 do
			c[i] = {p = part(fx, Vector3.new(0.32, 0.04, 0.16), PARTY[rng:NextInteger(1, #PARTY)], nil, Enum.Material.SmoothPlastic),
				v = Vector3.new(rng:NextNumber(-4, 4), rng:NextNumber(7, 12), rng:NextNumber(-4, 4)), spin = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8))}
		end
		return {c = c}
	end,
	draw = function(st, cue, k, a, t)
		if not st.origin then st.origin = a[cue.at or "chest"] end
		for _, c in ipairs(st.c) do
			-- (they float: drag slows them, a gentle fall after)
			local tt = math.min(t, 0.5)
			local pos = st.origin + c.v * tt - UP * (6 * tt * tt) + Vector3.new(c.v.X * 0.1, -2.2, c.v.Z * 0.1) * math.max(t - 0.5, 0)
			c.p.CFrame = CFrame.new(pos) * CFrame.Angles(c.spin.X * t, c.spin.Y * t, c.spin.Z * t)
			c.p.Transparency = math.clamp((k - 0.7) / 0.3, 0, 1)
		end
	end,
}

-- music notes rising (the world: ♪ ♫ that sway; a preview: little lights)
KIND.notes = {
	make = function(fx, cue, rng)
		local n = {}
		for i = 1, 8 do
			local holder = part(fx, Vector3.one * (fx.preview and 0.3 or 0.1), PARTY[(i - 1) % #PARTY + 1], fx.preview and Enum.PartType.Ball or nil)
			if not fx.preview then
				holder.Transparency = 1
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.fromOffset(40, 40); bb.AlwaysOnTop = false; bb.LightInfluence = 0; bb.MaxDistance = 80
				local l = Instance.new("TextLabel")
				l.BackgroundTransparency = 1; l.Size = UDim2.fromScale(1, 1); l.Text = i % 2 == 0 and "♫" or "♪"; l.TextScaled = true
				l.Font = Enum.Font.GothamBlack; l.TextColor3 = PARTY[(i - 1) % #PARTY + 1]
				local s = Instance.new("UIStroke", l); s.Color = Color3.new(0, 0, 0); s.Thickness = 2
				l.Parent = bb; bb.Parent = holder
				n[i] = {p = holder, l = l, phase = (i - 1) / 8, side = rng:NextNumber(-1, 1)}
			else
				n[i] = {p = holder, phase = (i - 1) / 8, side = rng:NextNumber(-1, 1)}
			end
		end
		return {n = n}
	end,
	draw = function(st, cue, k, a, t)
		local fade = fadeInOut(k, 0.1, 0.15)
		for _, n in ipairs(st.n) do
			local y = (t * 0.7 + n.phase) % 1
			n.p.Position = a.head + Vector3.new(n.side * 1.6 + math.sin(t * 3 + n.phase * 6) * 0.5, 0.6 + y * 3, 0)
			local tr = 1 - fade * (1 - y)
			if n.l then n.l.TextTransparency = tr; n.l.UIStroke.Transparency = tr else n.p.Transparency = tr end
		end
	end,
}

-- (the world only) a glow
KIND.light = {
	world = true,
	make = function(fx, cue)
		local holder = part(fx, Vector3.one * 0.1, cue.color); holder.Transparency = 1
		local l = Instance.new("PointLight"); l.Color = cue.color; l.Range = cue.range or 14; l.Brightness = 0; l.Shadows = false; l.Parent = holder
		return {holder = holder, l = l, rng = Random.new()}
	end,
	draw = function(st, cue, k, a)
		st.holder.Position = a[cue.at or "chest"]
		local b = (cue.brightness or 2) * fadeInOut(k, 0.1, 0.3)
		if cue.flicker and st.rng:NextNumber() < 0.3 then b *= st.rng:NextNumber(0.2, 2) end
		st.l.Brightness = b
	end,
}

-- (the world only) the blade's trail
KIND.trail = {
	world = true,
	make = function(fx, cue)
		local tip = findTip(fx.model)
		local handle = tip and tip.Parent
		if not (tip and handle and handle:IsA("BasePart")) then return {} end
		local a0 = Instance.new("Attachment"); a0.Name = "EmoteTrailBase"; a0.Parent = handle
		local tr = Instance.new("Trail")
		tr.Attachment0, tr.Attachment1 = a0, tip
		tr.Color = ColorSequence.new(cue.color or WHITE)
		tr.Transparency = NumberSequence.new(0.2, 1)
		tr.Lifetime = 0.25; tr.LightEmission = 1; tr.FaceCamera = true
		tr.Parent = handle
		return {objs = {a0, tr}}
	end,
	draw = function() end,
}

-- (the world only) a sound, once, where you stand
KIND.sound = {
	world = true, once = true,
	make = function(fx, cue)
		local root = fx.model:FindFirstChild("HumanoidRootPart")
		if not root then return {} end
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://" .. tostring(cue.id)
		s.Volume = cue.vol or 0.4
		s.PlaybackSpeed = cue.speed or 1
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 10
		s.RollOffMaxDistance = 120
		s.Parent = root
		s:Play()
		local cut = cue.cut
		task.delay((cut or 8) / (cue.speed or 1), function()
			if not s.Parent then return end
			for i = 1, 6 do if s.Parent then s.Volume *= 0.6; task.wait(0.03) end end
			s:Destroy()
		end)
		return {}
	end,
	draw = function() end,
}

--------------------------------------------------------------------
--  RUNNING ONE
--------------------------------------------------------------------
local FX = {}
FX.__index = FX

-- model: a character or a preview rig; container: where its parts go (a world
-- folder or a preview's WorldModel); preview: no sounds, lights or trails
function EmoteFX.new(model, id, container, preview)
	local def = EmoteFX.DEF[id]
	local self = setmetatable({model = model, id = id, container = container, preview = preview == true, cues = def or {}, states = {}, last = -1}, FX)
	return self
end

local function clearState(st)
	if not st then return end
	for _, v in pairs(st) do
		if typeof(v) == "Instance" then v:Destroy()
		elseif type(v) == "table" then
			for _, w in pairs(v) do
				if typeof(w) == "Instance" then w:Destroy()
				elseif type(w) == "table" and typeof(w.p) == "Instance" then w.p:Destroy() end
			end
		end
	end
end

function FX:update(t)
	if not self.model.Parent then return end
	local a = anchors(self.model, self)
	if not a then return end
	self.camera = self.camera or (self.preview and self.container.Parent and self.container.Parent:IsA("ViewportFrame") and self.container.Parent.CurrentCamera) or workspace.CurrentCamera
	-- (a preview loops: the clock went back, everything starts again)
	if t < self.last then for i, st in pairs(self.states) do clearState(st); self.states[i] = nil end; self.fired = {} end
	self.fired = self.fired or {}
	for i, cue in ipairs(self.cues) do
		local kind = KIND[cue[1]]
		if kind and not (kind.world and self.preview) then
			local d = cue.d or 0.5
			local live = t >= cue.t and t <= cue.t + d
			if kind.once then
				if t >= cue.t and not self.fired[i] and t - cue.t < 0.5 then self.fired[i] = true; kind.make(self, cue) end
			elseif live then
				if not self.states[i] then self.states[i] = kind.make(self, cue, Random.new(i * 7919 + #self.id)) end
				kind.draw(self.states[i], cue, (t - cue.t) / d, a, t - cue.t, self)
			elseif self.states[i] then
				clearState(self.states[i]); self.states[i] = nil
			end
		end
	end
	self.last = t
end

function FX:destroy()
	for i, st in pairs(self.states) do clearState(st); self.states[i] = nil end
	self.dead = true
end

--------------------------------------------------------------------
--  LIVE EMOTES (every client: Cosmetics attaches one when an emote starts)
--------------------------------------------------------------------
local Emotes   -- (required lazily: Emotes doesn't need this module)
local live = {}   -- [character] = fx
local folder
local function worldFolder()
	if folder and folder.Parent then return folder end
	folder = workspace:FindFirstChild("EmoteFX") or Instance.new("Folder")
	folder.Name = "EmoteFX"
	folder.Parent = workspace
	return folder
end

function EmoteFX.attach(char, id)
	if not (char and EmoteFX.DEF[id]) then return end
	Emotes = Emotes or require(ReplicatedStorage:WaitForChild("Emotes"))
	if live[char] then live[char]:destroy() end
	live[char] = EmoteFX.new(char, id, worldFolder(), false)
end

if RunService:IsClient() then
	RunService.RenderStepped:Connect(function()
		if not Emotes then return end
		for char, fx in pairs(live) do
			local t = Emotes.elapsed(char)
			if not char.Parent or Emotes.playing(char) ~= fx.id or not t then
				fx:destroy(); live[char] = nil
			else
				local cam = workspace.CurrentCamera
				-- (far away: not drawn; a sound still plays where it's heard)
				local root = char:FindFirstChild("HumanoidRootPart")
				if root and cam and (root.Position - cam.CFrame.Position).Magnitude < 220 then fx:update(t) end
			end
		end
	end)
end

return EmoteFX
