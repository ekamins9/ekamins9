--[[ COMPANIONS — builds the little creatures of Catalog ▸ Companions (and the
     Hatchery's eggs) out of parts, and moves them. Every part is anchored and
     placed by hand each frame (no physics), so the same rig works in the world
     and inside a menu ViewportFrame.

       Companions.build(id, opts)            -> rig   opts.world = particles, opts.stars
       Companions.pose(rig, cf, t, moving)   place the rig with its root at cf;
                                             moving 0..1 drives the walk / hop / flap
       rig.model  rig.flying  rig.foot (studs from the root down to the ground)
       Companions.egg(eggId, opts)           -> egg rig (an egg-shaped shell drawn in its look:
                                             speckled · mossy · ember · royal)
       Companions.poseEgg(egg, cf, t, wobble)  cf = the egg's bottom; wobble 0..1
       Companions.BODIES                     the body names a companion may use

     Bodies: bird (flies; style walker walks), beast (four legs), hopper (hops),
     wisp (floats, sparks circle it), drake (flies on bat wings). ]]

local Catalog = require(script.Parent:WaitForChild("Catalog"))

local Companions = {}
local SCALE = 1.25          -- a size-1 companion is about knee to waist high
local DARK = Color3.fromRGB(22, 22, 28)
local rad = math.rad
local sin, cos, abs = math.sin, math.cos, math.abs

local TEX = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
}

--------------------------------------------------------------------
--  PART SPECS: {name, shape, size, offset CFrame, colour, opts}
--  shape: block · ball (a sphere mesh, any proportions) · wedge
--  opts.hinge (Vector3, root space) + opts.ch (animation channel)
--------------------------------------------------------------------
local function S(list, name, shape, size, offset, color, o)
	o = o or {}
	table.insert(list, {name = name, shape = shape, size = size, offset = typeof(offset) == "Vector3" and CFrame.new(offset) or offset,
		color = color, neon = o.neon, transp = o.transp, hinge = o.hinge, ch = o.ch, phase = o.phase, glass = o.glass})
end
local V = Vector3.new
local CF = CFrame.new
local A = CFrame.Angles

local BODY = {}
local SHINE = Color3.fromRGB(255, 255, 255)
-- a dark eye with a white glint (it looks out along -Z)
local function eye(L, x, y, z, d, color, h)
	S(L, "Eye", "ball", V(d, d * 1.1, d * 0.6), V(x, y, z), color or DARK, h)
	S(L, "Shine", "ball", V(d * 0.34, d * 0.34, d * 0.2), V(x + d * 0.16, y + d * 0.2, z - d * 0.26), SHINE, h)
end

-- a round little bird: flaps (or, a walker, struts)
BODY.bird = function(d)
	local L = {}
	local main, second, accent = d.main, d.second, d.accent
	local owl, walker = d.style == "owl", d.style == "walker"
	S(L, "Body", "ball", V(1.0, 0.92, 1.25), V(0, 0, 0), main)
	S(L, "Belly", "ball", V(0.82, 0.72, 0.9), V(0, -0.12, -0.16), second)
	local headY, headZ, headS = owl and 0.5 or 0.55, owl and -0.28 or -0.5, owl and 0.98 or 0.72
	S(L, "Head", "ball", V(headS, headS * (owl and 0.92 or 1), headS), V(0, headY, headZ), main, {ch = "head", hinge = V(0, headY - 0.2, headZ)})
	if owl then
		S(L, "Face", "ball", V(0.78, 0.64, 0.3), V(0, headY - 0.02, headZ - 0.38), second, {ch = "head", hinge = V(0, headY - 0.2, headZ)})
		for _, x in ipairs({-0.18, 0.18}) do
			S(L, "Eye", "ball", V(0.24, 0.24, 0.1), V(x, headY + 0.04, headZ - 0.53), accent, {ch = "head", hinge = V(0, headY - 0.2, headZ)})
			S(L, "Pupil", "ball", V(0.11, 0.11, 0.06), V(x, headY + 0.04, headZ - 0.58), DARK, {ch = "head", hinge = V(0, headY - 0.2, headZ)})
		end
		S(L, "Beak", "wedge", V(0.12, 0.14, 0.12), CF(0, headY - 0.14, headZ - 0.56), Color3.fromRGB(230, 190, 90), {ch = "head", hinge = V(0, headY - 0.2, headZ)})
	else
		for _, x in ipairs({-0.2, 0.2}) do
			eye(L, x, headY + 0.08, headZ - 0.31, 0.15, DARK, {ch = "head", hinge = V(0, headY - 0.2, headZ)})
		end
		local beakCol = walker and Color3.fromRGB(240, 192, 64) or accent
		S(L, "Beak", "wedge", V(0.18, 0.18, 0.32), CF(0, headY - 0.04, headZ - 0.46), beakCol, {ch = "head", hinge = V(0, headY - 0.2, headZ)})
	end
	if walker then
		-- the comb and wattle
		S(L, "Comb", "block", V(0.08, 0.2, 0.34), CF(0, headY + 0.42, headZ + 0.02), accent, {ch = "head", hinge = V(0, headY - 0.2, headZ)})
		S(L, "Wattle", "ball", V(0.1, 0.18, 0.1), V(0, headY - 0.22, headZ - 0.36), accent, {ch = "head", hinge = V(0, headY - 0.2, headZ)})
	end
	for _, side in ipairs({-1, 1}) do
		S(L, side < 0 and "WingL" or "WingR", "ball", V(0.16, 0.62, 0.92), CF(side * 0.52, 0.06, 0.06), second,
			{ch = side < 0 and "wingL" or "wingR", hinge = V(side * 0.42, 0.3, 0.06)})
		S(L, "Leg", "block", V(0.09, 0.42, 0.09), V(side * 0.2, -0.6, 0.02), Color3.fromRGB(230, 170, 70),
			{ch = side < 0 and "legL" or "legR", hinge = V(side * 0.2, -0.4, 0.02)})
		S(L, "Foot", "block", V(0.18, 0.06, 0.24), V(side * 0.2, -0.8, -0.06), Color3.fromRGB(230, 170, 70),
			{ch = side < 0 and "legL" or "legR", hinge = V(side * 0.2, -0.4, 0.02)})
	end
	S(L, "Tail", "wedge", V(0.5, 0.14, 0.56), CF(0, 0.14, 0.78) * A(rad(-20), math.pi, 0), second, {ch = "tailBob", hinge = V(0, 0.1, 0.55)})
	return L, {flying = not walker, foot = 0.83, flap = walker and 0 or 1}
end

-- four legs, a tail that wags
BODY.beast = function(d)
	local L = {}
	local main, second, accent = d.main, d.second, d.accent
	S(L, "Body", "ball", V(0.98, 0.86, 1.56), V(0, 0, 0), main)
	S(L, "Chest", "ball", V(0.84, 0.8, 0.7), V(0, 0.06, -0.5), main)
	S(L, "Belly", "ball", V(0.72, 0.46, 1.2), V(0, -0.24, -0.02), second)
	local hy, hz = 0.52, -0.95
	local H = {ch = "head", hinge = V(0, hy - 0.2, hz + 0.25)}
	S(L, "Head", "ball", V(0.86, 0.8, 0.82), V(0, hy, hz), main, H)
	S(L, "Cheeks", "ball", V(0.9, 0.5, 0.6), V(0, hy - 0.14, hz - 0.12), main, H)
	S(L, "Snout", "ball", V(0.48, 0.36, 0.5), V(0, hy - 0.14, hz - 0.42), second, H)
	S(L, "Nose", "ball", V(0.2, 0.15, 0.12), V(0, hy - 0.04, hz - 0.67), DARK, H)
	for _, side in ipairs({-1, 1}) do
		eye(L, side * 0.21, hy + 0.1, hz - 0.36, 0.17, DARK, H)
		S(L, "Iris", "ball", V(0.1, 0.1, 0.05), V(side * 0.21, hy + 0.08, hz - 0.45), accent, H)
		if d.style == "round" then
			S(L, "Ear", "ball", V(0.26, 0.26, 0.14), V(side * 0.3, hy + 0.4, hz + 0.08), main, H)
			S(L, "EarIn", "ball", V(0.14, 0.14, 0.06), V(side * 0.3, hy + 0.4, hz + 0.02), second, H)
		elseif d.style ~= "antlers" and d.style ~= "reindeer" then
			S(L, "Ear", "wedge", V(0.22, 0.38, 0.28), CF(side * 0.27, hy + 0.52, hz + 0.06) * A(0, rad(side * 90), rad(side * -10)), main, H)
			S(L, "EarIn", "wedge", V(0.12, 0.24, 0.14), CF(side * 0.27, hy + 0.5, hz) * A(0, rad(side * 90), rad(side * -10)), second, H)
		else
			S(L, "Ear", "wedge", V(0.12, 0.22, 0.3), CF(side * 0.42, hy + 0.3, hz + 0.1) * A(0, rad(side * 90), rad(side * -40)), main, H)
		end
		-- legs: front pair at -z, back pair at +z
		for _, z in ipairs({-0.5, 0.5}) do
			local ch = (z < 0 and "legF" or "legB") .. (side < 0 and "L" or "R")
			S(L, "Leg", "ball", V(0.3, 0.7, 0.32), V(side * 0.3, -0.58, z), main, {ch = ch, hinge = V(side * 0.3, -0.34, z)})
			S(L, "Paw", "ball", V(0.32, 0.16, 0.38), V(side * 0.3, -0.9, z - 0.05), second, {ch = ch, hinge = V(side * 0.3, -0.34, z)})
		end
	end
	S(L, "Tail", "ball", V(0.24, 0.24, 0.6), CF(0, 0.2, 0.92) * A(rad(32), 0, 0), main, {ch = "tail", hinge = V(0, 0.18, 0.74)})
	S(L, "Tail", "ball", V(0.26, 0.26, 0.5), CF(0, 0.42, 1.22) * A(rad(40), 0, 0), main, {ch = "tail", hinge = V(0, 0.18, 0.74)})
	S(L, "TailTip", "ball", V(0.3, 0.3, 0.36), CF(0, 0.62, 1.44) * A(rad(40), 0, 0), second, {ch = "tail", hinge = V(0, 0.18, 0.74)})
	if d.style == "mane" then
		S(L, "Mane", "ball", V(1.24, 1.16, 0.6), V(0, hy + 0.02, hz + 0.38), second, H)
		S(L, "Mane", "ball", V(1.0, 0.9, 0.5), V(0, hy - 0.1, hz + 0.6), second, H)
		S(L, "Tuft", "ball", V(0.5, 0.3, 0.5), V(0, hy + 0.44, hz + 0.1), second, H)
	elseif d.style == "antlers" then
		local g = d.glow or accent
		for _, side in ipairs({-1, 1}) do
			S(L, "Antler", "block", V(0.1, 0.62, 0.1), CF(side * 0.24, hy + 0.66, hz + 0.08) * A(0, 0, rad(side * -24)), g, {neon = true, ch = "head", hinge = H.hinge})
			S(L, "Tine", "block", V(0.08, 0.36, 0.08), CF(side * 0.4, hy + 0.92, hz - 0.04) * A(rad(-30), 0, rad(side * -50)), g, {neon = true, ch = "head", hinge = H.hinge})
			S(L, "Tine", "block", V(0.08, 0.3, 0.08), CF(side * 0.32, hy + 1.02, hz + 0.18) * A(rad(30), 0, rad(side * -10)), g, {neon = true, ch = "head", hinge = H.hinge})
		end
	elseif d.style == "reindeer" then
		-- plain antlers (not glowing) and, given a glow, a shining nose
		for _, side in ipairs({-1, 1}) do
			S(L, "Antler", "block", V(0.08, 0.5, 0.08), CF(side * 0.22, hy + 0.6, hz + 0.08) * A(0, 0, rad(side * -22)), accent, H)
			S(L, "Tine", "block", V(0.06, 0.26, 0.06), CF(side * 0.34, hy + 0.8, hz) * A(rad(-30), 0, rad(side * -50)), accent, H)
		end
		if d.glow then S(L, "RedNose", "ball", V(0.2, 0.17, 0.14), V(0, hy - 0.06, hz - 0.7), d.glow, {neon = true, ch = "head", hinge = H.hinge}) end
		for i = 1, 5 do   -- the fawn's spots
			S(L, "Spot", "ball", V(0.16, 0.06, 0.16), V(((i * 37) % 7 - 3) * 0.1, 0.42, -0.4 + i * 0.18), second)
		end
	elseif d.style == "tusks" then
		for _, side in ipairs({-1, 1}) do
			S(L, "Tusk", "wedge", V(0.06, 0.2, 0.08), CF(side * 0.16, hy - 0.12, hz - 0.62) * A(0, 0, rad(side * 15)), accent, H)
		end
		S(L, "Ridge", "ball", V(0.22, 0.24, 1.3), V(0, 0.42, -0.1), second)
	elseif d.style == "bones" then
		-- a skeleton: dark ribs across the body, glowing eyes
		for i = 0, 4 do
			S(L, "Rib", "block", V(1.0, 0.07, 0.07), V(0, 0.1, -0.5 + i * 0.22), d.second)
		end
		S(L, "Spine", "block", V(0.1, 0.08, 1.4), V(0, 0.44, 0), d.second)
		if d.glow then
			for _, side in ipairs({-1, 1}) do
				S(L, "GlowEye", "ball", V(0.12, 0.12, 0.06), V(side * 0.21, hy + 0.1, hz - 0.47), d.glow, {neon = true, ch = "head", hinge = H.hinge})
			end
		end
	elseif d.style == "crown" then
		S(L, "Collar", "ball", V(0.9, 0.16, 0.5), V(0, hy - 0.34, hz + 0.36), accent, H)
		S(L, "CrownBand", "block", V(0.5, 0.12, 0.5), V(0, hy + 0.44, hz + 0.02), accent, H)
		for _, x in ipairs({-0.18, 0, 0.18}) do S(L, "CrownTip", "wedge", V(0.12, 0.2, 0.12), CF(x, hy + 0.6, hz - 0.2) * A(0, math.pi, 0), accent, H) end
	end
	return L, {flying = false, foot = 0.96 * 1, flap = 0}
end

-- hops: a round body, big back legs
BODY.hopper = function(d)
	local L = {}
	local main, second, accent = d.main, d.second, d.accent
	local hare = d.style == "longears"
	S(L, "Body", "ball", V(1.0, 0.78, 1.12), V(0, 0, 0.05), main)
	S(L, "Belly", "ball", V(0.78, 0.52, 0.82), V(0, -0.14, -0.14), second)
	if hare then
		local H = {ch = "head", hinge = V(0, 0.3, -0.45)}
		S(L, "Head", "ball", V(0.62, 0.6, 0.66), V(0, 0.48, -0.56), main, H)
		for _, side in ipairs({-1, 1}) do
			S(L, "Ear", "block", V(0.15, 0.68, 0.08), CF(side * 0.14, 1.02, -0.44) * A(rad(-12), 0, rad(side * -8)), main, H)
			S(L, "EarIn", "block", V(0.08, 0.5, 0.04), CF(side * 0.14, 1.0, -0.49) * A(rad(-12), 0, rad(side * -8)), second, H)
			eye(L, side * 0.19, 0.56, -0.83, 0.13, DARK, H)
		end
		S(L, "Nose", "ball", V(0.1, 0.08, 0.06), V(0, 0.44, -0.89), Color3.fromRGB(220, 150, 150), H)
		S(L, "Tail", "ball", V(0.3, 0.3, 0.3), V(0, 0.12, 0.62), second)
	else
		for _, side in ipairs({-1, 1}) do
			S(L, "EyeBump", "ball", V(0.3, 0.3, 0.3), V(side * 0.24, 0.38, -0.36), main, {ch = "head", hinge = V(0, 0.2, -0.3)})
			eye(L, side * 0.26, 0.44, -0.49, 0.17, accent, {ch = "head", hinge = V(0, 0.2, -0.3)})
		end
		S(L, "Mouth", "block", V(0.62, 0.04, 0.04), V(0, 0.06, -0.55), DARK)
	end
	for _, side in ipairs({-1, 1}) do
		S(L, "BackLeg", "ball", V(0.32, 0.32, 0.66), V(side * 0.44, -0.28, 0.2), main, {ch = "hopLeg", hinge = V(side * 0.44, -0.2, 0)})
		S(L, "BackFoot", "block", V(0.26, 0.08, 0.42), V(side * 0.46, -0.4, -0.06), second, {ch = "hopLeg", hinge = V(side * 0.44, -0.2, 0)})
		S(L, "FrontLeg", "block", V(0.14, 0.32, 0.14), V(side * 0.26, -0.3, -0.4), main)
	end
	return L, {flying = false, foot = 0.44, flap = 0, hop = true}
end

-- a floating light; sparks circle it
BODY.wisp = function(d)
	local L = {}
	local g = d.glow or d.main
	S(L, "Core", "ball", V(0.74, 0.74, 0.74), V(0, 0, 0), g, {neon = true})
	S(L, "Shell", "ball", V(1.18, 1.18, 1.18), V(0, 0, 0), d.second, {transp = 0.62, glass = true})
	S(L, "Tail", "ball", V(0.5, 0.5, 0.8), V(0, -0.22, 0.52), d.second, {transp = 0.55, glass = true, ch = "tailBob", hinge = V(0, -0.1, 0.2)})
	for _, side in ipairs({-1, 1}) do S(L, "Eye", "ball", V(0.12, 0.17, 0.06), V(side * 0.15, 0.08, -0.6), d.accent) end
	for i = 1, 3 do S(L, "Spark", "ball", V(0.17, 0.17, 0.17), V(0.95, 0, 0), g, {neon = true, ch = "orbit", hinge = V(0, 0, 0), phase = i * 2.094}) end
	if d.style == "pumpkin" then
		-- a carved pumpkin round the light: ribbed shell, a stem, a face lit from inside
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			S(L, "Rib", "ball", V(0.62, 1.0, 0.62), V(cos(a) * 0.28, 0, sin(a) * 0.28), d.main)
		end
		S(L, "Stem", "block", V(0.12, 0.28, 0.12), CF(0, 0.6, 0) * A(0, 0, rad(12)), Color3.fromRGB(70, 90, 40))
		for _, side in ipairs({-1, 1}) do
			S(L, "FaceEye", "wedge", V(0.16, 0.16, 0.06), CF(side * 0.17, 0.12, -0.62), g, {neon = true})
		end
		S(L, "FaceGrin", "block", V(0.42, 0.08, 0.06), V(0, -0.14, -0.6), g, {neon = true})
	elseif d.style == "kraken" then
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			S(L, "Arm", "ball", V(0.16, 0.7, 0.16), CF(cos(a) * 0.3, -0.62, sin(a) * 0.3) * A(sin(a) * rad(25), 0, -cos(a) * rad(25)), d.main,
				{ch = "tailBob", hinge = V(cos(a) * 0.25, -0.3, sin(a) * 0.25)})
		end
		S(L, "Mantle", "ball", V(0.9, 1.1, 0.9), V(0, 0.18, 0.05), d.main, {transp = 0.15})
	end
	return L, {flying = true, foot = 0.6, flap = 0, float = true}
end

-- a small dragon on bat wings (style beak: a griffin)
BODY.drake = function(d)
	local L = {}
	local main, second, accent = d.main, d.second, d.accent
	local griffin = d.style == "beak"
	S(L, "Body", "ball", V(0.9, 0.82, 1.36), V(0, 0, 0), main)
	S(L, "Belly", "ball", V(0.66, 0.5, 1.0), V(0, -0.2, -0.06), second, {neon = d.glow ~= nil and not griffin})
	local hy, hz = 0.6, -0.92
	local H = {ch = "head", hinge = V(0, hy - 0.3, hz + 0.3)}
	S(L, "Neck", "ball", V(0.4, 0.62, 0.4), CF(0, hy - 0.26, hz + 0.32) * A(rad(-30), 0, 0), griffin and second or main, H)
	S(L, "Head", "ball", V(0.64, 0.56, 0.78), V(0, hy, hz), griffin and second or main, H)
	if griffin then
		S(L, "Beak", "wedge", V(0.26, 0.3, 0.36), CF(0, hy - 0.06, hz - 0.5), accent, H)
	elseif d.style == "bat" then
		S(L, "Snout", "ball", V(0.3, 0.22, 0.3), V(0, hy - 0.1, hz - 0.36), main, H)
		for _, side in ipairs({-1, 1}) do
			S(L, "Ear", "wedge", V(0.1, 0.46, 0.26), CF(side * 0.22, hy + 0.42, hz + 0.06) * A(0, rad(side * 90), rad(side * -14)), main, H)
			S(L, "Fang", "wedge", V(0.04, 0.08, 0.04), CF(side * 0.06, hy - 0.24, hz - 0.46) * A(0, 0, math.pi), accent, H)
		end
	else
		S(L, "Snout", "ball", V(0.44, 0.3, 0.5), V(0, hy - 0.08, hz - 0.46), main, H)
		for _, side in ipairs({-1, 1}) do S(L, "Nostril", "ball", V(0.06, 0.05, 0.04), V(side * 0.09, hy - 0.02, hz - 0.71), DARK, H) end
		for _, side in ipairs({-1, 1}) do
			S(L, "Horn", "wedge", V(0.12, 0.38, 0.14), CF(side * 0.18, hy + 0.4, hz + 0.24) * A(rad(-35), math.pi, 0), accent, H)
		end
	end
	for _, side in ipairs({-1, 1}) do
		if d.glow then
			S(L, "Eye", "ball", V(0.13, 0.13, 0.07), V(side * 0.18, hy + 0.08, hz - 0.36), d.glow, {neon = true, ch = "head", hinge = H.hinge})
		else
			eye(L, side * 0.18, hy + 0.08, hz - 0.35, 0.14, DARK, {ch = "head", hinge = H.hinge})
		end
		local wch = side < 0 and "wingL" or "wingR"
		local hinge = V(side * 0.38, 0.32, 0.0)
		-- the arm along the front edge, the membrane a flat triangle swept back to the tip
		S(L, "WingArm", "ball", V(0.94, 0.12, 0.14), V(side * 0.82, 0.34, -0.26), main, {ch = wch, hinge = hinge})
		S(L, "WingClaw", "wedge", V(0.06, 0.16, 0.1), CF(side * 1.28, 0.38, -0.3), accent, {ch = wch, hinge = hinge})
		S(L, "Wing", "wedge", V(0.05, 0.95, 0.85), CF(side * 0.85, 0.3, 0.14) * A(0, 0, rad(-side * 90)), second, {ch = wch, hinge = hinge})
		for _, z in ipairs({-0.38, 0.38}) do
			local lch = (z < 0 and "legF" or "legB") .. (side < 0 and "L" or "R")
			S(L, "Leg", "ball", V(0.24, 0.42, 0.26), V(side * 0.3, -0.48, z), main, {ch = lch, hinge = V(side * 0.3, -0.34, z)})
			S(L, "Claw", "ball", V(0.26, 0.1, 0.3), V(side * 0.3, -0.68, z - 0.04), accent, {ch = lch, hinge = V(side * 0.3, -0.34, z)})
		end
	end
	S(L, "Tail1", "ball", V(0.34, 0.3, 0.8), CF(0, 0.02, 0.92) * A(rad(10), 0, 0), main, {ch = "tail", hinge = V(0, 0.05, 0.6)})
	S(L, "Tail2", "ball", V(0.22, 0.2, 0.7), CF(0, -0.06, 1.5) * A(rad(4), 0, 0), main, {ch = "tail", hinge = V(0, 0.05, 0.6)})
	for i = 0, 3 do   -- a row of spines down the back (a bat has none)
		if d.style ~= "bat" then S(L, "Spine", "wedge", V(0.06, 0.16, 0.16), CF(0, 0.42 - i * 0.03, -0.2 + i * 0.3), accent) end
	end
	S(L, "TailTip", "wedge", V(0.34, 0.08, 0.3), CF(0, -0.08, 1.88), griffin and second or accent, {ch = "tail", hinge = V(0, 0.05, 0.6)})
	return L, {flying = true, foot = 0.7, flap = 0.6}
end

Companions.BODIES = {}
for k in pairs(BODY) do table.insert(Companions.BODIES, k) end
table.sort(Companions.BODIES)

--------------------------------------------------------------------
--  BUILD
--------------------------------------------------------------------
local function makePart(spec, scale, parent)
	local p = Instance.new(spec.shape == "wedge" and "WedgePart" or "Part")
	p.Name = spec.name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = spec.neon ~= true
	p.Massless = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Color = spec.color or Color3.new(1, 1, 1)
	p.Material = spec.neon and Enum.Material.Neon or (spec.glass and Enum.Material.Glass or Enum.Material.SmoothPlastic)
	p.Transparency = spec.transp or 0
	if spec.shape == "ball" then
		p.Size = Vector3.new(1, 1, 1) * 0.2
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Scale = spec.size * scale / 0.2
		m.Parent = p
	else
		p.Size = spec.size * scale
	end
	p.Parent = parent
	return p
end

local function scaled(cf, k) return CFrame.new(cf.Position * k) * cf.Rotation end

local function addFx(root, kind, scale)
	local a = Instance.new("Attachment"); a.Parent = root
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 0.6
	e.Rate = 6
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(0.3, 1)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25 * scale), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new(0.2, 1)
	if kind == "embers" then
		e.Texture = TEX.fire; e.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 80, 30)); e.Acceleration = Vector3.new(0, 2, 0); e.Rate = 10
	elseif kind == "frost" then
		e.Texture = TEX.spark; e.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255)); e.Acceleration = Vector3.new(0, -1.5, 0)
	elseif kind == "spirit" then
		e.Texture = TEX.spark; e.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255), Color3.fromRGB(255, 255, 255)); e.Acceleration = Vector3.new(0, 1, 0)
	else -- sparkle (five stars)
		e.Texture = TEX.spark; e.Color = ColorSequence.new(Color3.fromRGB(255, 220, 110)); e.Rate = 4
	end
	e.Parent = a
	return e
end

-- VARIANTS (rolled on hatching, Catalog ▸ Eggs ▸ variants): Golden gilds every
-- part and sparkles; Spectral turns it into a glowing, see-through ghost
local GOLD = Color3.fromRGB(255, 198, 64)
local GHOST = Color3.fromRGB(150, 235, 255)
local function applyVariant(model, root, variant, scale)
	if variant == "Golden" then
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and p ~= root and p.Material ~= Enum.Material.Neon then
				local h, s, v = p.Color:ToHSV()
				p.Color = GOLD:Lerp(Color3.fromHSV(h, s * 0.3, math.max(v, 0.35)), 0.25)
				p.Material = Enum.Material.Foil
				p.Reflectance = 0.15
			end
		end
	elseif variant == "Spectral" then
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and p ~= root then
				local _, _, v = p.Color:ToHSV()
				p.Color = GHOST:Lerp(Color3.new(v, v, v), 0.25)
				p.Material = Enum.Material.Neon
				p.Transparency = math.max(p.Transparency, 0.45)
			end
		end
	end
end
Companions.applyVariant = applyVariant

function Companions.build(id, opts)
	opts = opts or {}
	local d = Catalog.COMPANION and Catalog.COMPANION[id]
	if not d then return nil end
	local maker = BODY[d.body] or BODY.beast
	local specs, info = maker(d)
	local scale = (d.size or 1) * SCALE * (opts.scale or 1)
	local model = Instance.new("Model")
	model.Name = "Companion_" .. id
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Transparency = 1
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Anchored, root.CanCollide, root.CanTouch, root.CanQuery = true, false, false, false
	root.Parent = model
	model.PrimaryPart = root
	local parts, list = {}, {root}
	for _, s in ipairs(specs) do
		local p = makePart(s, scale, model)
		table.insert(parts, {part = p, rest = scaled(s.offset, scale), hinge = s.hinge and s.hinge * scale or nil, ch = s.ch, phase = s.phase or 0})
		table.insert(list, p)
	end
	applyVariant(model, root, opts.variant, scale)
	if opts.world then
		if d.fx then addFx(root, d.fx, scale) end
		if (opts.stars or 0) >= 5 or opts.variant == "Golden" then addFx(root, "sparkle", scale) end
		if opts.variant == "Spectral" then addFx(root, "spirit", scale) end
		if d.glow then
			local l = Instance.new("PointLight"); l.Color = d.glow; l.Range = 7; l.Brightness = 0.8; l.Parent = root
		end
	end
	return {model = model, root = root, parts = parts, list = list, def = d, flying = info.flying, foot = info.foot * scale,
		flap = info.flap or 0, hop = info.hop, float = info.float, scale = scale, seed = math.random() * 10}
end

--------------------------------------------------------------------
--  POSE: every channel's angle at time t
--------------------------------------------------------------------
local function channel(rig, ch, t, moving, phase)
	if ch == "wingL" or ch == "wingR" then
		local s = ch == "wingL" and 1 or -1
		local a
		if rig.flying then
			local speed = rig.def.body == "drake" and 9 or 16
			a = rad(18) + sin(t * speed) * rad(rig.def.body == "drake" and 38 or 52)
		else
			a = rad(6) + sin(t * 3) * rad(4) * (1 + moving)
		end
		return A(0, 0, s * a)
	elseif ch == "legL" or ch == "legR" then
		if rig.flying then return A(rad(30), 0, 0) end
		local s = ch == "legL" and 1 or -1
		return A(s * sin(t * 12) * rad(34) * moving, 0, 0)
	elseif ch == "legFL" or ch == "legBR" or ch == "legFR" or ch == "legBL" then
		if rig.flying then return A(rad(ch:sub(4, 4) == "F" and -40 or 40), 0, 0) end
		local s = (ch == "legFL" or ch == "legBR") and 1 or -1
		return A(s * sin(t * 11) * rad(32) * moving, 0, 0)
	elseif ch == "tail" then
		return A(0, sin(t * (moving > 0.2 and 9 or 4)) * rad(moving > 0.2 and 22 or 14), 0)
	elseif ch == "tailBob" then
		return A(sin(t * 4) * rad(10), 0, 0)
	elseif ch == "head" then
		return A(sin(t * 1.7) * rad(5) + (moving > 0.2 and sin(t * 11) * rad(4) or 0), sin(t * 0.6) * rad(10), 0)
	elseif ch == "hopLeg" then
		local k = rig.hopK or 0
		return A(rad(-50) * k, 0, 0)
	elseif ch == "orbit" then
		return A(0, t * 2.4 + phase, 0) * A(0, 0, sin(t * 1.3 + phase) * 0.35)
	end
	return CFrame.identity
end

local cfs = {}
function Companions.pose(rig, cf, t, moving)
	moving = math.clamp(moving or 0, 0, 1)
	t = t + rig.seed
	local base = cf
	if rig.flying then
		base = base * CF(0, sin(t * (rig.float and 1.6 or 2.4)) * 0.18 * rig.scale, 0)
	elseif rig.hop then
		-- hop while moving; a small hop now and then while idle
		local k
		if moving > 0.15 then k = abs(sin(t * 7)) else k = math.max(0, sin(t * 2.2)) ^ 18 end
		rig.hopK = k
		base = base * CF(0, k * 0.7 * rig.scale, 0) * A(rad(-12) * k, 0, 0)
	elseif moving > 0.2 then
		base = base * CF(0, abs(sin(t * 11)) * 0.06 * rig.scale, 0)
	end
	local n = 0
	table.clear(cfs)
	n += 1; cfs[n] = base
	for _, p in ipairs(rig.parts) do
		local rel = p.rest
		if p.ch then
			local r = channel(rig, p.ch, t, moving, p.phase)
			local h = p.hinge or Vector3.zero
			rel = CF(h) * r * CF(-h) * rel
		end
		n += 1; cfs[n] = base * rel
	end
	if rig.model:IsDescendantOf(workspace) then
		workspace:BulkMoveTo(rig.list, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	else
		for i, p in ipairs(rig.list) do p.CFrame = cfs[i] end
	end
end

--------------------------------------------------------------------
--  EGGS
--------------------------------------------------------------------
-- the shell: a round lower half and a narrower, taller upper half, bottom at
-- y = 0, 1.7 tall, widest (1.2) a little below the middle, like a real egg; the
-- two meet at a shallow angle so the join doesn't show
local EGG_HALVES = {{a = 0.6, b = 0.8, c = 0.8}, {a = 0.55, b = 0.84, c = 0.86}}   -- semi-axes across / up, centre height
local EGG_TOP = 1.7
local function eggHalf(y)
	local best, r = EGG_HALVES[1], 0
	for _, h in ipairs(EGG_HALVES) do
		local t = (y - h.c) / h.b
		if abs(t) < 1 and h.a * math.sqrt(1 - t * t) > r then best, r = h, h.a * math.sqrt(1 - t * t) end
	end
	return best, r
end
local function eggRadius(y) local _, r = eggHalf(y); return r end
-- a point on the shell (height y, round by yaw), lifted along the outward normal
local function onEgg(y, yaw, lift)
	local h, r = eggHalf(y)
	local dir = V(cos(yaw), 0, sin(yaw))
	local n = V(dir.X * r / (h.a * h.a), (y - h.c) / (h.b * h.b), dir.Z * r / (h.a * h.a)).Unit
	return dir * r + V(0, y, 0) + n * (lift or 0), n
end
-- a frame on the shell: -Z out along the normal, X round the egg, Y up the egg
local function face(pos, n)
	return CFrame.lookAt(pos, pos + n, abs(n.Y) > 0.95 and Vector3.zAxis or Vector3.yAxis)
end
-- a thin strip from a to b lying on the shell (a crack, a seam)
local function strip(add, a, b, w, color, neon)
	local mid = (a + b) / 2
	local _, n = onEgg(mid.Y, math.atan2(mid.Z, mid.X))
	add("block", V(w, w * 0.6, (b - a).Magnitude + w * 0.5), CFrame.lookAt(mid, b, n), color, neon)
end
-- a band of segments round the shell at height y
local function band(add, y, height, count, color, mat, lift)
	local arc = 2 * math.pi * eggRadius(y) / count
	for i = 0, count - 1 do
		local pos, n = onEgg(y, i / count * math.pi * 2, lift or 0)
		add("block", V(arc * 1.08, height, 0.05), face(pos, n), color, false, mat)
	end
end

-- what is drawn on each egg (Catalog ▸ Eggs `look`; default speckled).
-- Every look is seeded by the egg's id, so an egg looks the same every time.
local EGG_LOOKS = {}
EGG_LOOKS.speckled = function(add, e, rng)
	local dark = e.spots:Lerp(Color3.new(0, 0, 0), 0.35)
	for i = 1, 18 do
		local pos, n = onEgg(rng:NextNumber(0.22, 1.5), rng:NextNumber(0, math.pi * 2))
		local s = i <= 6 and rng:NextNumber(0.2, 0.3) or rng:NextNumber(0.07, 0.15)
		add("ball", V(s, s * rng:NextNumber(0.65, 1), 0.06), face(pos, n) * A(0, 0, rng:NextNumber(0, math.pi)), i % 3 == 0 and dark or e.spots, e.glow)
	end
end
EGG_LOOKS.mossy = function(add, e, rng)
	-- lumps of moss, thickest low down
	local pale = e.shell:Lerp(e.spots, 0.5)
	for i = 1, 15 do
		local y = rng:NextNumber(0.1, 1.2)
		local pos, n = onEgg(y, rng:NextNumber(0, math.pi * 2))
		local s = rng:NextNumber(0.22, 0.42) * (1.25 - y * 0.45)
		add("ball", V(s, s * 0.7, s * 0.45), face(pos, n) * A(0, 0, rng:NextNumber(0, math.pi)), i % 4 == 0 and pale or e.spots)
	end
	-- a sprout on the top: a stem and two leaves
	local leaf = e.shell:Lerp(Color3.fromRGB(150, 225, 95), 0.6)
	add("ball", V(0.07, 0.34, 0.07), CF(0.02, EGG_TOP + 0.1, 0) * A(0, 0, rad(-12)), e.spots)
	add("ball", V(0.32, 0.05, 0.15), CF(0.16, EGG_TOP + 0.25, 0) * A(0, 0, rad(28)), leaf)
	add("ball", V(0.26, 0.05, 0.13), CF(-0.1, EGG_TOP + 0.2, 0.03) * A(0, rad(25), rad(-34)), leaf)
end
EGG_LOOKS.ember = function(add, e, rng)
	-- the cooled crust: dark blotches
	local crust = e.shell:Lerp(Color3.fromRGB(20, 10, 8), 0.6)
	for _ = 1, 9 do
		local pos, n = onEgg(rng:NextNumber(0.2, 1.45), rng:NextNumber(0, math.pi * 2))
		local s = rng:NextNumber(0.3, 0.5)
		add("ball", V(s, s * 0.8, 0.05), face(pos, n) * A(0, 0, rng:NextNumber(0, math.pi)), crust)
	end
	-- glowing cracks running down from the top, with a fork here and there
	for c = 1, 4 do
		local yaw, y = c * math.pi / 2 + rng:NextNumber(-0.4, 0.4), EGG_TOP - 0.1
		local prev = onEgg(y, yaw, 0.012)
		while y > 0.4 do
			y -= rng:NextNumber(0.15, 0.25)
			yaw += rng:NextNumber(-0.32, 0.32)
			local p = onEgg(y, yaw, 0.012)
			strip(add, prev, p, 0.07, e.spots, true)
			if rng:NextNumber() < 0.3 then
				local fy, fyaw = y - rng:NextNumber(0.1, 0.18), yaw + (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(0.25, 0.4)
				strip(add, p, onEgg(fy, fyaw, 0.012), 0.05, e.spots, true)
			end
			prev = p
		end
	end
end
EGG_LOOKS.royal = function(add, e, rng)
	local gold, metal = e.spots, Enum.Material.Metal
	-- a gold band round the waist, set with gems
	band(add, 0.74, 0.15, 18, gold, metal)
	for i = 0, 3 do
		local pos, n = onEgg(0.74, i * math.pi / 2 + math.pi / 4, 0.04)
		add("ball", V(0.15, 0.15, 0.09), face(pos, n), i % 2 == 0 and Color3.fromRGB(205, 30, 55) or Color3.fromRGB(235, 235, 250), true)
	end
	-- a thin band above, and gold flecks between
	band(add, 1.22, 0.06, 14, gold, metal)
	for _ = 1, 10 do
		local pos, n = onEgg(rng:NextNumber(0.25, 1.4), rng:NextNumber(0, math.pi * 2))
		local s = rng:NextNumber(0.07, 0.12)
		add("block", V(s, s, 0.03), face(pos, n) * A(0, 0, math.pi / 4), gold, true)
	end
	-- a little crown on the top: a circlet and six points, each with a pearl
	local cy = 1.48
	band(add, cy, 0.1, 12, gold, metal, 0.01)
	local cr = eggRadius(cy) + 0.02
	for i = 0, 5 do
		local yaw = i / 6 * math.pi * 2
		local d = V(cos(yaw), 0, sin(yaw))
		local base = d * cr + V(0, cy + 0.12, 0)
		add("block", V(0.06, 0.2, 0.06), CFrame.lookAt(base, base + d) * A(rad(-12), 0, 0), gold, false, metal)
		add("ball", V(0.08, 0.08, 0.08), CF(base + d * 0.03 + V(0, 0.12, 0)), Color3.fromRGB(245, 240, 225))
	end
end

function Companions.egg(eggId, opts)
	opts = opts or {}
	local e = Catalog.EGG and Catalog.EGG[eggId]
	if not e then return nil end
	local k = opts.scale or 1
	local model = Instance.new("Model")
	model.Name = "Egg_" .. eggId
	local list, rests = {}, {}
	local function add(shape, size, rel, color, neon, mat)
		local p = makePart({name = "Shell", shape = shape, size = size, color = color, neon = neon}, k, model)
		if mat and not neon then p.Material = mat end
		p.CastShadow = not neon
		table.insert(list, p)
		table.insert(rests, scaled(rel, k))
		return p
	end
	for _, h in ipairs(EGG_HALVES) do add("ball", V(h.a * 2, h.b * 2, h.a * 2), CF(0, h.c, 0), e.shell) end
	local look = EGG_LOOKS[e.look or ""] or EGG_LOOKS[eggId:lower()] or EGG_LOOKS.speckled
	look(add, e, Random.new(#eggId * 7919))
	if e.glow and opts.world then
		local l = Instance.new("PointLight"); l.Color = e.spots; l.Range = 6; l.Brightness = 0.7; l.Parent = list[1]
		addFx(list[1], (e.look or eggId:lower()) == "ember" and "embers" or "sparkle", k * 0.6)
	end
	return {model = model, list = list, rests = rests, def = e, scale = k}
end

function Companions.poseEgg(egg, cf, t, wobble)
	wobble = wobble or 0
	local tilt = A(0, 0, sin(t * 9) * rad(14) * wobble) * A(sin(t * 7.3) * rad(6) * wobble, 0, 0)
	local base = cf * tilt
	table.clear(cfs)
	for i, rel in ipairs(egg.rests) do cfs[i] = base * rel end
	if egg.model:IsDescendantOf(workspace) then
		workspace:BulkMoveTo(egg.list, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	else
		for i, p in ipairs(egg.list) do p.CFrame = cfs[i] end
	end
end

return Companions
