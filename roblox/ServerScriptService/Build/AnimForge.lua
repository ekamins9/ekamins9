--[[ ANIM FORGE — every combat animation, written as data and solved into R6
     KeyframeSequences (the way Build ▸ Weapons writes weapons as data).

     A clip is a few CONTROL POSES on a timeline. Each says where the BLADE
     points (az = degrees round from straight ahead, + to the right; el =
     degrees up), how far the torso TWISTs (+ = turned to the right), LEANs
     (+ = forward) and TILTs (+ = to the right). The forge samples between them
     about 30 times a second with proper easing, so the blade travels a real
     arc round the body instead of a straight blend between two poses, and
     solves the body for every sample:
       • the right arm aims at a point along the blade from the class's pivot
         (an R6 arm is a straight 1.58-stud lever: the hand rides that sphere)
       • the weapon (the ToolGrip joint) turns so its blade points where the
         pose says, with the EDGE leading the strike — winding up included,
         so the edge already faces the target when the swing comes round
       • the left hand holds the hilt below the right (two-handers, polearms)
         or swings opposite the blade for balance (one-handers)
       • the head stays on the target while the torso turns under it

     Every attack clip has three named keyframes the game times by:
       Load     end of the windup (the telegraph: held, readable)
       Through  end of the strike (Load → Through is exactly STRIKE seconds,
                the old clips' 0.3, so the balance is unchanged)
       Settle   the follow-through comes back to guard (plays over recovery)
     The live hitbox is whatever the blade really sweeps.

     Classes (AnimSets.CLASS says which weapon uses which):
       Blade1H, Blunt1H, Dagger, Blade2H, Heavy2H, Polearm

     Studio:  require(ServerScriptService.Build.AnimForge).build()    → ServerStorage ▸ AnimForge ▸ <Class> ▸ <Clip>
              .preview("Blade2H", "RightSwing")                      → an onion-skin row of posed dummies to look at
     Upload:  scripts/upload_anims.py (serialises, uploads, writes the Animation ids
              Studio-side into ReplicatedStorage ▸ Animations — never into code) ]]

local AF = {}

local rad, sin, cos, clamp = math.rad, math.sin, math.cos, math.clamp
local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
local PI = math.pi

AF.FPS    = 30      -- samples per second written into each clip
AF.STRIKE = 0.30    -- Load → Through (seconds at speed 1)
AF.WINDUP = 0.30    -- Ready → Load (rescaled by the game to the real windup)
AF.FOLLOW = 0.45    -- Through → Settle (rescaled to the recovery)

--------------------------------------------------------------------
--  THE R6 RIG — Part1 = Part0 * C0 * Transform * C1:Inverse()
--------------------------------------------------------------------
local J = {
	Root  = {C0 = ANG(-PI / 2, 0, PI), C1 = ANG(-PI / 2, 0, PI)},
	Neck  = {C0 = CF(0, 1, 0) * ANG(-PI / 2, 0, PI), C1 = CF(0, -0.5, 0) * ANG(-PI / 2, 0, PI)},
	RS    = {C0 = CF(1, 0.5, 0) * ANG(0, PI / 2, 0), C1 = CF(-0.5, 0.5, 0) * ANG(0, PI / 2, 0)},
	LS    = {C0 = CF(-1, 0.5, 0) * ANG(0, -PI / 2, 0), C1 = CF(0.5, 0.5, 0) * ANG(0, -PI / 2, 0)},
	RH    = {C0 = CF(1, -1, 0) * ANG(0, PI / 2, 0), C1 = CF(0.5, 1, 0) * ANG(0, PI / 2, 0)},
	LH    = {C0 = CF(-1, -1, 0) * ANG(0, -PI / 2, 0), C1 = CF(-0.5, 1, 0) * ANG(0, -PI / 2, 0)},
	-- the weapon: this game's ToolGrip Motor6D (C1 = Tool.Grip with CombatServer GRIP_ROLL -90)
	Grip  = {C0 = CF(0, -1, 0) * ANG(-PI / 2, 0, 0), C1 = ANG(0, -PI / 2, 0)},
}
AF.JOINTS = J
local HAND = V3(0, -1, 0)     -- grip point in arm space
local FOOT = V3(0, -1, 0)     -- sole centre in leg space
local ARM_LEN = (HAND - V3(0.5, 0.5, 0)).Magnitude   -- shoulder joint → hand, 1.58

-- the arm's front for an arm aimed along `aim`: its rest front (the torso's
-- forward) carried by the smallest turn from hanging straight down. Raise an arm
-- ahead and its front faces up; out to the side, it stays forward — no sudden
-- flips of the arm about its own length, whatever the blade does.
local function naturalFront(torso, aim)
	local down, fwd = -torso.UpVector, torso.LookVector
	local axis = down:Cross(aim)
	local d = clamp(down:Dot(aim), -1, 1)
	if axis.Magnitude < 1e-4 then return d > 0 and fwd or -fwd end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(d)):VectorToWorldSpace(fwd)
end

-- carry a limb's front from its last aim to its new one by the smallest turn
-- (parallel transport): the limb never spins about its own length
local function transport(front, fromAim, toAim)
	local axis = fromAim:Cross(toAim)
	if axis.Magnitude < 1e-6 then return front end
	local a = math.acos(clamp(fromAim:Dot(toAim), -1, 1))
	return CFrame.fromAxisAngle(axis.Unit, a):VectorToWorldSpace(front)
end

-- turn `from` toward `to` by at most `cap` radians (an arm can only swing so fast)
local function capTurn(from, to, cap)
	local a = math.acos(clamp(from:Dot(to), -1, 1))
	if a <= cap then return to end
	local axis = from:Cross(to)
	if axis.Magnitude < 1e-6 then return to end
	return CFrame.fromAxisAngle(axis.Unit, cap):VectorToWorldSpace(from)
end
AF.ARM_CAP = {right = math.rad(40), left = math.rad(38)}   -- per 1/30 s

local function transform(jt, p0, p1) return jt.C0:Inverse() * p0:Inverse() * p1 * jt.C1 end

-- unit vector: az degrees from ahead (-Z) toward the right (+X), el degrees up
local function dir(az, el)
	local a, e = rad(az), rad(el)
	return V3(sin(a) * cos(e), sin(e), -cos(a) * cos(e))
end
AF.dir = dir

local function orth(v, n)   -- v with its n component removed, unit (or nil)
	local w = v - n * v:Dot(n)
	return w.Magnitude > 1e-4 and w.Unit or nil
end

-- a straight limb: the joint stays at `joint` (world), the limb points along
-- `aim`, rolled so its front (-Z) faces `front`; slide moves it along aim
-- (a shrug / a reach) — returns the limb CFrame and where its end point is
local function limb(joint, aim, front, jLocal, endLocal, slide)
	local v = (endLocal - jLocal).Unit
	local e2 = V3(0, 0, -1)
	local E = CFrame.fromMatrix(Vector3.zero, v, e2, v:Cross(e2))
	local f2 = orth(front, aim) or orth(V3(0, 0, -1), aim) or orth(V3(0, 1, 0), aim)
	local F = CFrame.fromMatrix(Vector3.zero, aim, f2, aim:Cross(f2))
	local R = F * E:Inverse()
	local p = joint + aim * (slide or 0) - R:VectorToWorldSpace(jLocal)
	local cf = CF(p) * R
	return cf, cf:PointToWorldSpace(endLocal)
end

--------------------------------------------------------------------
--  EASING
--------------------------------------------------------------------
local EASE = {
	linear  = function(x) return x end,
	sineIn  = function(x) return 1 - cos(x * PI / 2) end,
	sineOut = function(x) return sin(x * PI / 2) end,
	sine    = function(x) return -(cos(PI * x) - 1) / 2 end,
	quadIn  = function(x) return x * x end,
	quadOut = function(x) return 1 - (1 - x) * (1 - x) end,
	cubicIn = function(x) return x * x * x end,
	cubicOut = function(x) return 1 - (1 - x) ^ 3 end,
	expoOut = function(x) return x >= 1 and 1 or 1 - 2 ^ (-9 * x) end,
	backOut = function(x) local c = 1.4; return 1 + (c + 1) * (x - 1) ^ 3 + c * (x - 1) ^ 2 end,
}

--------------------------------------------------------------------
--  CLASSES — how each kind of weapon is held and carried
--------------------------------------------------------------------
--   twoHanded   left hand on the grip `gap` studs below the right
--   pivot       the point the swing turns round (right-side attacks; mirrored for left)
--   reach       how far along the blade from the pivot the right arm aims
--   twistK      torso twist per degree of blade azimuth, capped at twistMax
--   len         blade length the edge is reckoned at (for the leading-edge solve)
--   doubleEdge  a sword: either edge may lead (no half-turn of the wrist to bring one round)
--   guard       the ready pose {az, el, twist, lean}: blades held UP (el ~75), the edge
--               toward the enemy, never levelled at them; stance = feet
local CLASSES = {
	Blade1H = {doubleEdge = true, guardAt = V3(0.55, -0.2, -1.15), twoHanded = false, pivot = V3(0.45, 0.2, -0.25), reach = 1.6, twistK = 0.36, twistMax = 52, len = 2.6,
		guard = {az = 14, el = 74, twist = 18, lean = 4}, stance = 0.55, backhand = 0.55, leftFree = true},
	Blunt1H = {guardAt = V3(0.55, -0.15, -1.1), twoHanded = false, pivot = V3(0.5, 0.3, -0.2), reach = 1.5, twistK = 0.4, twistMax = 58, len = 1.8,
		guard = {az = 16, el = 76, twist = 20, lean = 5}, stance = 0.6, backhand = 0.5, leftFree = true, chop = 1.2},
	Dagger  = {doubleEdge = true, guardAt = V3(0.5, -0.05, -1.25), twoHanded = false, pivot = V3(0.4, 0.05, -0.35), reach = 1.7, twistK = 0.3, twistMax = 40, len = 1.1,
		guard = {az = 8, el = 55, twist = 25, lean = 10}, stance = 0.65, backhand = 0.6, leftFree = true, quick = true},
	Blade2H = {doubleEdge = true, guardAt = V3(0.2, -0.3, -1.05), twoHanded = true, gap = 0.62, pivot = V3(0.18, 0.1, -0.35), reach = 1.25, twistK = 0.4, twistMax = 55, len = 3.4,
		guard = {az = 8, el = 76, twist = 12, lean = 4}, stance = 0.6},
	Heavy2H = {guardAt = V3(0.25, -0.35, -1.0), twoHanded = true, gap = 0.95, slack = 0.3, pivot = V3(0.2, 0.15, -0.25), reach = 1.15, twistK = 0.46, twistMax = 62, len = 2.8,
		guard = {az = 12, el = 72, twist = 18, lean = 6}, stance = 0.7, chop = 1.3, heavy = true},
	Polearm = {guardAt = V3(0.35, -0.3, -0.95), twoHanded = true, gap = 1.35, slack = 0.6, pivot = V3(0.25, -0.1, -0.2), reach = 1.05, twistK = 0.42, twistMax = 55, len = 4.2,
		guard = {az = 8, el = 62, twist = 22, lean = 6}, stance = 0.75, low = true},
}
AF.CLASSES = CLASSES

--------------------------------------------------------------------
--  CHOREOGRAPHY — the RIGHT-side attacks as control poses; LEFT mirrors.
--  u: 0..1 within its phase (windup / strike / follow); ease: into this pose
--------------------------------------------------------------------
-- az/el = blade; tw = torso twist (nil → from az by the class's twistK);
-- ln = lean, tl = tilt; hand = extra offset of the aim point; stab = hand
-- position given directly (thrusts move the hand, not the blade)
local MOVES = {
	Swing = {
		windup = {
			{u = 0.55, az = 75,  el = 48, ease = "sine"},
			{u = 1.0,  az = 138, el = 30, ln = -4, ease = "sineOut"},        -- loaded: blade back over the right shoulder
		},
		strike = {
			{u = 0.30, az = 100, el = 14, ease = "quadIn"},                    -- the release accelerates…
			{u = 0.58, az = 8,   el = 2,  ln = 8, ease = "linear"},            -- …full speed through the front (contact)
			{u = 1.0,  az = -78, el = -8, ln = 6, ease = "quadOut"},           -- carries through to the left
		},
		follow = {
			{u = 0.45, az = -105, el = -28, ln = 4, ease = "cubicOut"},       -- the weight pulls the blade down and round
			{u = 1.0,  guard = true, ease = "sine"},                           -- back to guard
		},
	},
	Overhead = {   -- the hands go up ABOVE and in front of the head (never through it); the blade hangs back over it
		windup = {
			{u = 0.5, az = 22, el = 100, at = V3(0.85, 1.45, -0.8), tw = 12, ln = -2, ease = "sine"},
			{u = 1.0, az = 18, el = 152, at = V3(0.75, 2.2, -0.5), tw = 22, ln = -8, ease = "sineOut"},   -- loaded: hands high, the tip behind the head
		},
		strike = {
			{u = 0.32, az = 14, el = 108, at = V3(0.62, 2.1, -0.9), tw = 12, ln = -2, ease = "quadIn"},
			{u = 0.6,  az = 4,  el = 22,  at = V3(0.35, 0.8, -1.65), tw = -4, ln = 12, ease = "linear"},  -- chops down through head height
			{u = 1.0,  az = -8, el = -36, at = V3(0.25, -0.3, -1.35), tw = -12, ln = 16, ease = "quadOut"},
		},
		follow = {
			{u = 0.45, az = -14, el = -58, at = V3(0.2, -0.55, -1.05), tw = -14, ln = 12, ease = "cubicOut"},
			{u = 1.0,  guard = true, ease = "sine"},
		},
	},
	Underhand = {
		windup = {
			{u = 0.5, az = 70,  el = -5,  ease = "sine"},
			{u = 1.0, az = 145, el = -38, ln = 10, tw = 38, ease = "sineOut"},  -- loaded: low behind the right hip
		},
		strike = {
			{u = 0.30, az = 112, el = -34, ln = 8, ease = "quadIn"},
			{u = 0.58, az = 14,  el = -6,  ln = 4, ease = "linear"},            -- rising through the hips
			{u = 1.0,  az = -62, el = 42,  ln = -6, ease = "quadOut"},          -- out high to the left
		},
		follow = {
			{u = 0.45, az = -72, el = 62, ln = -6, ease = "cubicOut"},
			{u = 1.0,  guard = true, ease = "sine"},
		},
	},
	Stab = {   -- the whole body coils to the right (the head stays on the target), then unwinds as the arms drive the point out
		windup = {
			{u = 0.5, az = 6, el = 12, at = V3(0.95, -0.05, -0.3), tw = 30, ln = -2, ease = "sine"},
			{u = 1.0, az = 4, el = 6,  at = V3(1.0, -0.1, 0.35), tw = 48, ln = -5, ease = "sineOut"},   -- coiled: drawn back past the hip
		},
		strike = {
			{u = 0.32, az = 3, el = 5, at = V3(0.8, 0.0, -0.5), tw = 22, ln = 4, ease = "quadIn"},
			{u = 0.6,  az = 1, el = 4, at = V3(0.35, 0.1, -1.6), tw = -14, ln = 12, ease = "linear"},   -- the drive
			{u = 1.0,  az = 0, el = 3, at = V3(0.2, 0.1, -1.9), tw = -22, ln = 15, ease = "expoOut"},
		},
		follow = {
			{u = 0.4, az = 2, el = 10, at = V3(0.35, 0.0, -1.5), tw = -14, ln = 10, ease = "sine"},
			{u = 1.0, guard = true, ease = "sine"},
		},
	},
}
AF.MOVES = MOVES

--------------------------------------------------------------------
--  SOLVING A POSE
--------------------------------------------------------------------
-- p: {az, el, tw, ln, tl, stab (Vector3), hand (Vector3 offset), edge (Vector3), left (Vector3 target)}
-- side: 1 = right attack, -1 = left (mirrored); returns world CFrames
AF.FLOOR = -2.75   -- the tip never goes below this (feet are at -3): the blade stops at the ground

local solveRaw
function AF.solve(cls, p, side, edgeHint, legs, prev)
	local w = solveRaw(cls, p, side, edgeHint, legs, prev)
	local tries = 0
	while (w.rHand + w.blade * cls.len).Y < AF.FLOOR and tries < 30 do
		p = table.clone(p); p.el = (p.el or 0) + 3
		w = solveRaw(cls, p, side, edgeHint, legs, prev)
		tries += 1
	end
	return w
end

solveRaw = function(cls, p, side, edgeHint, legs, prev)
	side = side or 1
	local az, el = p.az * side, p.el
	-- (a thrust is a right-handed move either way: the left one comes from just left of
	-- centre with less turn, not from a mirrored body)
	local sideK = (p.stabbing and side < 0) and (cls.twoHanded and 0.4 or -0.45) or side
	local twist = p.tw and p.tw * sideK or clamp(p.az * cls.twistK, -cls.twistMax, cls.twistMax) * side
	local lean, tilt = p.ln or 0, (p.tl or 0) * side
	local blade = dir(az, el)

	local piv = V3(0, -1, 0)
	local torso = CF(piv) * ANG(0, -rad(twist), 0) * ANG(-rad(lean), 0, 0) * ANG(0, 0, -rad(tilt)) * CF(-piv)
	if cls.heavy then torso = torso + V3(0, -0.04 * math.abs(lean) / 10, 0) end

	-- the head: back on the target whatever the torso does
	local neckPt = torso:PointToWorldSpace(V3(0, 1, 0))
	local headR = ANG(0, -rad(twist * 0.15), 0) * ANG(-rad(lean * 0.2), 0, 0)
	local head = CF(neckPt + headR:VectorToWorldSpace(V3(0, 0.5, 0))) * headR

	-- the right hand: one rule for every frame — a point along the blade from the
	-- class's pivot, plus the pose's hand offset (absolute hand spots are turned
	-- into offsets when the timeline is built, so they interpolate seamlessly)
	local tr = cls.pivot + dir(p.az, p.el) * cls.reach + (p.hand or Vector3.zero)
	local target
	if side > 0 then
		target = tr
	elseif p.stabbing then
		-- a thrust is a right-handed move either way: the left one drives from just
		-- left of centre (two hands: from the same side), not from a mirrored body
		target = V3(tr.X * (cls.twoHanded and 0.6 or -0.25), tr.Y, tr.Z)
	else
		-- backhands come across the body, a little less far
		target = V3(-(tr.X - cls.pivot.X * (1 - (cls.backhand or 1))), tr.Y, tr.Z)
	end
	local rShoulder = torso:PointToWorldSpace(J.RS.C0.Position)
	local rAim = (target - rShoulder)
	local rDist = rAim.Magnitude
	rAim = rAim.Unit
	if prev then rAim = capTurn(prev.rAim, rAim, AF.ARM_CAP.right) end
	local rFront = prev and transport(prev.rFront, prev.rAim, rAim) or naturalFront(torso, rAim)
	local rArm, rHand = limb(rShoulder, rAim, rFront, J.RS.C1.Position, HAND, clamp(rDist - ARM_LEN, -0.15, 0.3))

	-- the weapon: blade where the pose says, edge leading
	-- (held poses: the edge toward the enemy)
	local edge = orth(edgeHint or V3(0, 0, -1), blade) or orth(V3(-side, 0, 0), blade) or orth(V3(1, 0, 0), blade)
	local handle = CFrame.fromMatrix(rHand, edge, blade, edge:Cross(blade))

	-- the left hand: on the grip, or out for balance
	local lShoulder = torso:PointToWorldSpace(J.LS.C0.Position)
	local lTarget, lFront, gripG
	if cls.twoHanded then
		-- the left hand slides along the grip to the nearest point it can hold
		-- (a polearm's haft gives it room; a sword's hilt hardly any)
		-- the point on the grip exactly an arm's length from the shoulder (the root of
		-- |c - b·g| = L nearest the class's gap), clamped to the grip: continuous
		-- frame to frame, so the hand slides instead of jumping
		local slack = cls.slack or 0.15
		local c = rHand - lShoulder
		local bc = blade:Dot(c)
		local disc = bc * bc - c:Dot(c) + ARM_LEN * ARM_LEN
		local g
		if disc >= 0 then
			local r1, r2 = bc + math.sqrt(disc), bc - math.sqrt(disc)
			local ref = (prev and prev.g) or cls.gap   -- stay with last frame's solution
			g = math.abs(r1 - ref) < math.abs(r2 - ref) and r1 or r2
		else
			g = bc
		end
		g = clamp(g, cls.gap - slack, cls.gap + slack)
		lTarget, lFront = rHand - blade * g, blade
		gripG = g
	else
		-- opposite the blade: out front when the blade is back, tucked when it comes through
		local swingAz = clamp(az, -150, 150)
		lTarget = torso:PointToWorldSpace(V3(-1.2, -0.55, -0.55)) + V3(0, 0, 0)
		lTarget += V3(-0.25 * side, 0.15, -0.6 * clamp(swingAz / 140, -1, 1) * side)
		if p.left then lTarget = V3(p.left.X * side, p.left.Y, p.left.Z) end
		lFront = V3(0.3 * side, 0.2, -1).Unit
	end
	local lAim = lTarget - lShoulder
	local lDist = lAim.Magnitude
	if prev then lAim = capTurn(prev.lAim, lAim.Unit, AF.ARM_CAP.left) end
	local lFront2 = prev and transport(prev.lFront, prev.lAim, lAim.Unit) or naturalFront(torso, lAim.Unit)
	local lArm, lHand = limb(lShoulder, lAim.Unit, lFront2, J.LS.C1.Position, HAND, clamp(lDist - ARM_LEN, -0.35, 0.55))

	local out = {Torso = torso, Head = head, ["Right Arm"] = rArm, ["Left Arm"] = lArm, Handle = handle, rHand = rHand, lHand = lHand, lErr = (lHand - lTarget).Magnitude, blade = blade,
		state = {rAim = rAim, rFront = orth(rFront, rAim) or rFront, lAim = lAim.Unit, lFront = orth(lFront2, lAim.Unit) or lFront2, g = gripG}}
	if legs then
		-- feet planted in the stance (idle / block only). Solved against the
		-- UNTURNED torso: in game the hips counter the torso's animated turn
		-- (AnimSets.counterHips), so the legs hang from where the hips would be
		local w = cls.stance or 0.6
		for _, s in ipairs({{"Right Leg", J.RH, V3(0.55, -3, 0.35 * w)}, {"Left Leg", J.LH, V3(-0.55, -3, -0.45 * w)}}) do
			local hip = s[2].C0.Position
			local foot = s[3]
			local legCF = limb(hip, (foot - hip).Unit, V3(0, 0, -1), s[2].C1.Position, FOOT, 0)
			out[s[1]] = legCF
		end
	end
	return out
end

-- world CFrames → Motor6D transforms (Pose CFrames)
function AF.transforms(w)
	local root = CFrame.identity
	local t = {
		Torso = transform(J.Root, root, w.Torso),
		Head = transform(J.Neck, w.Torso, w.Head),
		["Right Arm"] = transform(J.RS, w.Torso, w["Right Arm"]),
		["Left Arm"] = transform(J.LS, w.Torso, w["Left Arm"]),
		Handle = transform(J.Grip, w["Right Arm"], w.Handle),
	}
	if w["Right Leg"] then
		-- (against the unturned torso: see the hip counter in solve)
		t["Right Leg"] = transform(J.RH, CFrame.identity, w["Right Leg"])
		t["Left Leg"] = transform(J.LH, CFrame.identity, w["Left Leg"])
	end
	return t
end

--------------------------------------------------------------------
--  TIMELINES
--------------------------------------------------------------------
-- an absolute hand spot (right side) → the offset from where the blade alone would put the hand
local function offsetFor(cls, az, el, at)
	return at - (cls.pivot + dir(az, el) * cls.reach)
end
AF.offsetFor = offsetFor

local function guardPose(cls)
	local g = cls.guard
	-- the hands sit low (chest / belly), the blade stands up out of them
	local want = cls.guardAt or V3(0.5, -0.15, -1.1)
	return {az = g.az, el = g.el, tw = g.twist, ln = g.lean, hand = offsetFor(cls, g.az, g.el, want)}
end

local function lerpPose(a, b, x)
	local function L(k, def) local va, vb = a[k] or def, b[k] or def; return va + (vb - va) * x end
	local p = {az = L("az", 0), el = L("el", 0), ln = L("ln", 0), tl = L("tl", 0)}
	if a.tw or b.tw then p.tw = L("tw", nil) end
	if a.hand or b.hand then p.hand = (a.hand or Vector3.zero):Lerp(b.hand or Vector3.zero, x) end
	p.stabbing = a.stabbing or b.stabbing
	return p
end

-- fill missing twists so interpolation is continuous
local function withTwist(cls, p)
	if p.tw == nil then p.tw = clamp(p.az * cls.twistK, -cls.twistMax, cls.twistMax) end
	return p
end

-- an attack's control poses on one timeline (seconds)
function AF.timeline(cls, kind)
	local mv = MOVES[kind]
	local g = withTwist(cls, guardPose(cls))
	local keys = {{t = 0, p = g, ease = "linear"}}
	local function add(phase, t0, dur)
		for _, k in ipairs(mv[phase]) do
			local p = k.guard and table.clone(g) or {az = k.az, el = k.el, tw = k.tw, ln = k.ln, tl = k.tl, at = k.at, hand = k.hand}
			-- the heavy classes chop: overheads come further over, underhands lower
			if cls.chop and kind == "Overhead" and not k.guard then p.el = p.el + (p.el > 60 and 6 or -4) * cls.chop end
			-- polearms carry the head lower (the weight is at the far end)
			if cls.low and not k.guard and kind ~= "Overhead" then p.el = p.el - 8 end
			if p.at then
				local at = p.at
				-- daggers stab short and fast; two hands work from the centre line
				if cls.quick and kind == "Stab" then at = at * V3(0.9, 1, 0.85) end
				if cls.twoHanded then at = V3(at.X * 0.55, at.Y, at.Z) end
				p.hand = offsetFor(cls, p.az, p.el, at)
				p.at = nil
			end
			table.insert(keys, {t = t0 + k.u * dur, p = withTwist(cls, p), ease = k.ease or "linear"})
		end
	end
	add("windup", 0, AF.WINDUP)
	add("strike", AF.WINDUP, AF.STRIKE)
	add("follow", AF.WINDUP + AF.STRIKE, AF.FOLLOW)
	-- the whole clip knows it's a thrust (left thrusts stay right-handed, start to finish)
	if kind == "Stab" then for _, k in ipairs(keys) do k.p.stabbing = true end end
	return keys, {Load = AF.WINDUP, Through = AF.WINDUP + AF.STRIKE, Settle = AF.WINDUP + AF.STRIKE + AF.FOLLOW}
end

local function sample(keys, t)
	for i = 2, #keys do
		local a, b = keys[i - 1], keys[i]
		if t <= b.t + 1e-6 then
			local x = (t - a.t) / math.max(b.t - a.t, 1e-6)
			x = (EASE[b.ease] or EASE.linear)(clamp(x, 0, 1))
			local p = lerpPose(a.p, b.p, x)
			return p
		end
	end
	return keys[#keys].p
end

-- every sample of an attack: world CFrames + the edge, leading the STRIKE
function AF.frames(className, attack)
	local cls = CLASSES[className]
	local side = attack:sub(1, 4) == "Left" and -1 or 1
	local kind = attack:gsub("^Left", ""):gsub("^Right", "")
	local keys, marks = AF.timeline(cls, kind)
	local n = math.floor(marks.Settle * AF.FPS + 0.5)
	local poses = {}
	for i = 0, n do
		local t = i / AF.FPS
		poses[i] = {t = t, p = sample(keys, t)}
	end
	-- THE EDGE. The strike turns the blade about an axis (its swing plane's
	-- normal); the edge that leads is that axis × the blade — it turns smoothly
	-- with the blade, never jitters. Thrusts keep the edges level (flat to the
	-- ground). From the guard it rolls into place over the first part of the
	-- windup and back again as the follow-through returns to guard.
	local function bladeAt(t) return AF.solve(cls, sample(keys, t), side).blade end
	local axis
	if kind == "Stab" then
		axis = V3(0, 1, 0)
	else
		local b1, b2 = bladeAt(marks.Load + AF.STRIKE * 0.3), bladeAt(marks.Load + AF.STRIKE * 0.58)
		axis = b1:Cross(b2)
		axis = axis.Magnitude > 1e-4 and axis.Unit or V3(0, side, 0)
	end
	local function smooth(a, b, x) local k = clamp((x - a) / math.max(b - a, 1e-6), 0, 1); return k * k * (3 - 2 * k) end
	-- The edge is CARRIED along the blade's path frame to frame (the smallest
	-- turn that keeps it square to the blade), then turned toward where it
	-- wants to be at a capped rate: the strike's leading edge through windup and
	-- strike, the guard's (toward the enemy) on the way back. A sword takes
	-- whichever of its two edges is nearer. No reference that can go undefined
	-- mid-swing, no snaps.
	local fwd = V3(0, 0, -1)
	local function wantAt(t, blade)
		if t <= marks.Through then return orth(axis:Cross(blade), blade) end
		if math.abs(blade:Dot(fwd)) < 0.9 then return orth(fwd, blade) end
		return nil
	end
	local function stepCap(t)
		if t <= marks.Load then return rad(14) end
		if t <= marks.Through then return rad(25) end
		return rad(12)
	end
	local out, state = {}, nil
	local prevBlade = bladeAt(0)
	local edge = orth(fwd, prevBlade) or orth(V3(-1, 0, 0), prevBlade)
	for i = 0, n do
		local t = poses[i].t
		local blade = bladeAt(t)
		edge = orth(transport(edge, prevBlade, blade), blade) or edge
		local want = wantAt(t, blade)
		if want then
			if cls.doubleEdge and want:Dot(edge) < 0 then want = -want end
			local a = math.atan2(blade:Dot(edge:Cross(want)), edge:Dot(want))
			local cap = stepCap(t)
			edge = CFrame.fromAxisAngle(blade, clamp(a, -cap, cap)):VectorToWorldSpace(edge)
			edge = orth(edge, blade) or edge
		end
		prevBlade = blade
		local wf = AF.solve(cls, poses[i].p, side, edge, nil, state)
		state = wf.state
		out[#out + 1] = {t = t, w = wf}
	end
	return out, marks
end

-- a held / looping pose: idle (breathing), block, hit flinch. None of them key the legs:
-- Roblox's walk cycle plays at Core priority, below Idle, so legs keyed here would
-- freeze the walk (the hips' counter keeps the legs planted instead)
local HELD = {
	Idle = function(cls)
		local g = withTwist(cls, guardPose(cls))
		local up = table.clone(g); up.el += 3; up.ln -= 1.5
		return {{t = 0, p = g}, {t = 1.3, p = up}, {t = 2.6, p = g}}, true, false
	end,
	Block = function(cls)
		-- 1H / 2H: the blade across the face, edge out; polearms: the haft across
		-- the blade laid across the body on a diagonal, hands low to the right,
		-- the tip up to the left: it covers the body without filling your view
		local p
		if cls.twoHanded and cls.low then
			p = {az = -78, el = 22, tw = 10, ln = 3, at = V3(0.6, -0.1, -1.0)}
		elseif cls.twoHanded then
			p = {az = -70, el = 32, tw = 8, ln = 3, at = V3(0.45, 0.22, -1.2)}
		else
			p = {az = -62, el = 36, tw = 14, ln = 4, at = V3(0.75, 0.28, -1.3)}
		end
		p.hand = offsetFor(cls, p.az, p.el, p.at); p.at = nil
		local q = table.clone(p); q.el += 2; q.ln -= 1
		return {{t = 0, p = p}, {t = 1.2, p = q, ease = "sine"}, {t = 2.4, p = table.clone(p), ease = "sine"}}, true, false
	end,
	Hit = function(cls)
		local g = withTwist(cls, guardPose(cls))
		local jolt = {az = g.az + 25, el = g.el + 12, tw = g.tw - 14, ln = -14, tl = 6}
		local back = {az = g.az + 10, el = g.el + 4, tw = g.tw - 5, ln = -5, tl = 2}
		return {{t = 0, p = g}, {t = 0.07, p = jolt, ease = "expoOut"}, {t = 0.2, p = back, ease = "sine"}, {t = 0.42, p = g, ease = "sine"}}, false, false
	end,
}

function AF.heldFrames(className, name)
	local cls = CLASSES[className]
	local keys, looped, legs = HELD[name](cls)
	for _, k in ipairs(keys) do withTwist(cls, k.p) end
	local out, state = {}, nil
	local n = math.floor(keys[#keys].t * AF.FPS + 0.5)
	for i = 0, n do
		local t = i / AF.FPS
		local p = sample(keys, t)
		local w = AF.solve(cls, p, 1, nil, legs, state)
		state = w.state
		out[#out + 1] = {t = t, w = w}
	end
	return out, looped
end

--------------------------------------------------------------------
--  KEYFRAMESEQUENCES
--------------------------------------------------------------------
local ORDER = {"Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}

local function kfFrom(t, tr, name)
	local kf = Instance.new("Keyframe")
	kf.Time = t
	if name then kf.Name = name end
	local root = Instance.new("Pose"); root.Name = "HumanoidRootPart"; root.Weight = 0; root.Parent = kf
	local torso = Instance.new("Pose"); torso.Name = "Torso"; torso.CFrame = tr.Torso; torso.Parent = root
	for _, n in ipairs(ORDER) do
		if tr[n] then
			local p = Instance.new("Pose"); p.Name = n; p.CFrame = tr[n]; p.Parent = torso
			if n == "Right Arm" then
				local h = Instance.new("Pose"); h.Name = "Handle"; h.CFrame = tr.Handle; h.Parent = p
			end
		end
	end
	return kf
end

function AF.sequence(className, clip)
	local ks = Instance.new("KeyframeSequence")
	ks.Name = clip
	local frames, marks, looped
	if HELD[clip] then
		frames, looped = AF.heldFrames(className, clip)
		ks.Loop = looped
		ks.Priority = clip == "Idle" and Enum.AnimationPriority.Idle or (clip == "Hit" and Enum.AnimationPriority.Action2 or Enum.AnimationPriority.Action)
	else
		frames, marks = AF.frames(className, clip)
		ks.Loop = false
		ks.Priority = Enum.AnimationPriority.Action
	end
	-- an attack starts and ends EXACTLY on the idle's pose (blended over the
	-- first and last moments), so handing back to idle never spins the weapon
	local guardT = marks and AF.transforms(AF.heldFrames(className, "Idle")[1].w) or nil
	local last = frames[#frames].t
	for _, f in ipairs(frames) do
		local name
		if marks then
			for mk, mt in pairs(marks) do if math.abs(f.t - mt) < 0.5 / AF.FPS then name = mk end end
		end
		local tr = AF.transforms(f.w)
		if guardT then
			local function sm(a, b, x) local k = clamp((x - a) / (b - a), 0, 1); return k * k * (3 - 2 * k) end
			local w = math.max(1 - sm(0, 0.08, f.t), sm(last - 0.22, last, f.t))
			if w > 0 then for j, cf in pairs(tr) do if guardT[j] then tr[j] = cf:Lerp(guardT[j], w) end end end
		end
		kfFrom(f.t, tr, name).Parent = ks
	end
	if marks then for k, v in pairs(marks) do ks:SetAttribute(k, v) end end
	ks:SetAttribute("Class", className)
	return ks
end

AF.ATTACKS = {"RightSwing", "LeftSwing", "RightOverhead", "LeftOverhead", "RightUnderhand", "LeftUnderhand", "RightStab", "LeftStab"}
AF.HELD = {"Idle", "Block", "Hit"}

-- everything into ServerStorage ▸ AnimForge ▸ <Class> ▸ <Clip> (KeyframeSequences)
function AF.build(only)
	local root = game:GetService("ServerStorage"):FindFirstChild("AnimForge") or Instance.new("Folder")
	root.Name = "AnimForge"
	root.Parent = game:GetService("ServerStorage")
	local n = 0
	for className in pairs(CLASSES) do
		if not only or only == className then
			local f = root:FindFirstChild(className) or Instance.new("Folder")
			f.Name = className
			f.Parent = root
			for _, clip in ipairs(AF.ATTACKS) do
				local old = f:FindFirstChild(clip); if old then old:Destroy() end
				AF.sequence(className, clip).Parent = f; n += 1
			end
			for _, clip in ipairs(AF.HELD) do
				local old = f:FindFirstChild(clip); if old then old:Destroy() end
				AF.sequence(className, clip).Parent = f; n += 1
			end
		end
	end
	return n
end

--------------------------------------------------------------------
--  PREVIEW — a row of posed dummies (anchored copies) for screenshots
--------------------------------------------------------------------
local function dummy()
	return game:GetService("Players"):CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
end

-- poses one anchored copy of the rig + weapon at world CFrames w, origin at base
local function place(rig, tool, w, base)
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("JointInstance") then d:Destroy() end
	end
	for _, name in ipairs({"Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}) do
		local part = rig:FindFirstChild(name)
		if part then
			part.Anchored = true
			local cf = w[name]
			if not cf then
				-- legs not keyed: they hang under the unturned hips (the hip counter)
				local jt = name == "Right Leg" and J.RH or J.LH
				cf = jt.C0 * jt.C1:Inverse()
			end
			part.CFrame = base * cf
		end
	end
	rig.HumanoidRootPart.Anchored = true
	rig.HumanoidRootPart.CFrame = base
	rig.HumanoidRootPart.Transparency = 1
	if tool then
		local h = tool:FindFirstChild("Handle")
		local target = base * w.Handle
		local rel = {}
		for _, p in ipairs(tool:GetDescendants()) do if p:IsA("BasePart") then rel[p] = h.CFrame:ToObjectSpace(p.CFrame) end end
		for p, r in pairs(rel) do p.Anchored = true; p.CFrame = target * r end
	end
end

AF.PREVIEW_WEAPON = {Blade1H = "ArmingSword", Blunt1H = "Mace", Dagger = "Dagger", Blade2H = "Longsword", Heavy2H = "BattleAxe", Polearm = "Halberd"}

-- clip: an attack or held clip; times: list of seconds (default: the key moments)
function AF.preview(className, clip, times, origin)
	local folder = workspace:FindFirstChild("_AnimPreview")
	if folder then folder:Destroy() end
	folder = Instance.new("Folder"); folder.Name = "_AnimPreview"; folder.Parent = workspace
	origin = origin or CF(0, 300, 0)
	local frames, marks
	if HELD[clip] then frames = AF.heldFrames(className, clip) else frames, marks = AF.frames(className, clip) end
	if not times then
		if marks then
			local s = AF.STRIKE
			times = {0, marks.Load * 0.5, marks.Load, marks.Load + s * 0.3, marks.Load + s * 0.58, marks.Through, marks.Through + AF.FOLLOW * 0.45}
		else
			times = {0}
		end
	end
	local weapon = game:GetService("ServerStorage").Weapons:FindFirstChild(AF.PREVIEW_WEAPON[className])
	for i, t in ipairs(times) do
		local best = frames[1]
		for _, f in ipairs(frames) do if math.abs(f.t - t) < math.abs(best.t - t) then best = f end end
		local rig = dummy()
		rig.Name = string.format("%02d_%.2f", i, best.t)
		local tool = weapon and weapon:Clone()
		if tool then
			for _, d in ipairs(tool:GetDescendants()) do if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end end
		end
		local base = origin * CF((i - 1) * 6, 0, 0)
		for _, d in ipairs(rig:GetDescendants()) do
			if d:IsA("BodyColors") or d:IsA("Shirt") or d:IsA("Pants") then d:Destroy() end
		end
		for _, d in ipairs(rig:GetChildren()) do
			if d:IsA("BasePart") then d.Color = d.Name == "Torso" and Color3.fromRGB(60, 80, 130) or (d.Name:match("Leg") and Color3.fromRGB(70, 60, 50) or Color3.fromRGB(225, 190, 160)) end
		end
		rig.Parent = folder
		if tool then tool.Parent = rig end
		place(rig, tool, best.w, base)
		if tool then
			for _, p in ipairs(tool:GetDescendants()) do if p:IsA("BasePart") and p.Name == "Hitbox" then p.Transparency = 0.8; p.Color = Color3.new(1, 0.2, 0.2) end end
		end
	end
	return folder, #times
end

return AF
