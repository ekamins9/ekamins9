--[[ RIG POSE — the R6 procedural pose (aim bend, walk lean, step bob, kick,
     crouch, arm sway) as pure math, shared by:
       • CameraRig (your own character, every frame)
       • RigReplicator (everyone else's characters, from relayed inputs)
     so what you see of yourself and what others see of you is the same rig.
     Motor6D C0 changes never replicate on their own; the relay of these
     INPUTS is what makes a lean or a crouch a real dodge on other screens. ]]

local RigPose = {}

RigPose.CONFIG = {
	-- aim
	PITCH_DIR   = -1,
	NECK_PITCH  = 0.7,
	TORSO_PITCH = 0.5,
	TORSO_PIVOT = 1.0,
	ARM_PITCH   = 0.7,
	RIGHT_ARM_DIR = 1,
	LEFT_ARM_DIR  = -1,
	LEAN_DIR      = 1,
	-- kick (procedural pose layered on the right hip)
	KICK_ANGLE    = math.rad(80),  -- how far the right leg swings forward
	KICK_DIR      = 1,             -- flip to -1 if the leg swings backward
	KICK_LEAN     = 0.12,          -- torso lean-back at full extension
	KICK_LEAN_DIR = -1,            -- flip if the torso leans forward instead of back
	-- crouch (the height drop itself is physical — CameraRig lowers
	-- Humanoid.HipHeight — so it replicates and hitboxes move with it;
	-- this pose only adds the lean and the leg fold)
	CROUCH_DROP     = 0.0,          -- extra torso sink in the pose, on top of the HipHeight drop
	CROUCH_LEAN     = 0.25,         -- forward tilt (radians) at full crouch
	CROUCH_LEAN_DIR = 1,            -- flip if it leans back instead
	CROUCH_LEG      = math.rad(60), -- how far the thighs fold forward (a 2-stud R6 leg at 60° is
	                                --   1 stud tall, so CameraRig's CROUCH_HIP_DROP ≈ 0.95 keeps feet on the floor)
	CROUCH_LEG_DIR  = 1,            -- flip if the legs fold backward
	-- dodge: a lean impulse into the dodge direction, fed through the lean inputs
	DODGE_LEAN      = 0.35,
	-- hit reaction: torso jolt away from the blow (hitX/hitZ inputs, radians)
	HIT_JOLT        = 0.22,
	HIT_JOLT_DIR    = 1,
	-- ranged (bows, crossbows: the inputs ranged / aim / draw / reload)
	BOW_TWIST       = 0.85,          -- the archer turns side-on to the target (radians)…
	BOW_TWIST_DRAW  = 0.5,           -- …and further as the string comes back: the shoulders on the line
	TWIST_DIR       = 1,             -- flip if the wrong shoulder comes forward (the bow's, the right, leads:
	                                 --   the body turns off the over-the-shoulder camera's line)
	SWING_DIR       = 1,             -- flip if "across the chest" swings the arms outward
	-- a bow at the ready (not drawing): raise / across (radians) for each arm, a little turn
	BOW_READY       = {bowRaise = 0.6, bowAcross = 0.35, stringRaise = 0.85, stringAcross = 1.0, twist = 0.2},
	-- the crossbow (RigPose.ranged): at ease, raised (twist: the left shoulder a little forward), spanning
	XBOW            = {easeRightRaise = 0.6, easeRightAcross = 1.2, easeLeftRaise = 0.65, easeLeftAcross = 0.8,
	                   twist = -0.3, aimRightAcross = 0.1, aimLeftAcross = 1.6, aimLeftRaise = 0.05,
	                   bend = 0.85, bendPull = 0.3, strokes = 3,
	                   spanRight = 0.65, spanRightAcross = 0.25, spanLeft = 0.75, spanLeftPull = 0.35, spanLeftAcross = 1.6},
	-- the staff (RigPose.staff): at ease the right arm out level-ish (the staff upright), casting
	-- the right arm lower (the staff tips forward) and the left hand out at the target
	STAFF           = {easeRaise = 1.3, easeAcross = 0.15, easeLeftRaise = 0.15, easeLeftAcross = 0.1,
	                   castRaise = 0.85, castAcross = 0.3, drawLift = 0.5, castLeftAcross = 0.45, twist = 0.25},
}
local C = RigPose.CONFIG

RigPose.JOINTS = {"Neck", "RootJoint", "Left Hip", "Right Hip", "Left Shoulder", "Right Shoulder"}

local function joints(character)
	local torso, hrp = character:FindFirstChild("Torso"), character:FindFirstChild("HumanoidRootPart")
	if not (torso and hrp) then return nil end
	local j = {
		Neck = torso:FindFirstChild("Neck"), RootJoint = hrp:FindFirstChild("RootJoint"),
		["Left Hip"] = torso:FindFirstChild("Left Hip"), ["Right Hip"] = torso:FindFirstChild("Right Hip"),
		["Left Shoulder"] = torso:FindFirstChild("Left Shoulder"), ["Right Shoulder"] = torso:FindFirstChild("Right Shoulder"),
	}
	for _, name in ipairs(RigPose.JOINTS) do
		if not (j[name] and j[name]:IsA("Motor6D")) then return nil end
	end
	return j
end
RigPose.joints = joints

-- rest-pose C0s; capture BEFORE the first apply
function RigPose.origins(character)
	local j = joints(character)
	if not j then return nil end
	local o = {}
	for name, m in pairs(j) do o[name] = m.C0 end
	return o
end

-- inputs: pitch (camera pitch, radians), bob (torso Y), leanX, leanZ,
--         kick (0..1), crouch (0..1), arm (radians), swayX, swayY,
--         hitX, hitZ (hit-reaction jolt, radians)
function RigPose.compute(i, o)
	local p = i.pitch * C.PITCH_DIR
	local hx, hz = (i.hitX or 0) * C.HIT_JOLT_DIR, (i.hitZ or 0) * C.HIT_JOLT_DIR
	local walkLean   = CFrame.Angles(i.leanZ * C.LEAN_DIR + hz, 0, i.leanX * C.LEAN_DIR + hx)
	local kickLean   = CFrame.Angles(C.KICK_LEAN * C.KICK_LEAN_DIR * i.kick, 0, 0)
	local crouchLean = CFrame.Angles(C.CROUCH_LEAN * C.CROUCH_LEAN_DIR * i.crouch, 0, 0)
	local aim = CFrame.new(0, 0, -C.TORSO_PIVOT) * CFrame.Angles(p * C.TORSO_PITCH, 0, 0) * CFrame.new(0, 0, C.TORSO_PIVOT)
	local rootBend = o.RootJoint * aim * walkLean * kickLean * crouchLean
	local counter  = o.RootJoint * rootBend:Inverse()   -- legs stay planted under the bent torso
	local legFold  = C.CROUCH_LEG * C.CROUCH_LEG_DIR * i.crouch
	local swayCF   = CFrame.Angles(i.swayY, i.swayX, 0)
	local out = {
		Neck      = o.Neck * CFrame.Angles(p * C.NECK_PITCH, 0, 0),
		RootJoint = CFrame.new(0, i.bob - C.CROUCH_DROP * i.crouch, 0) * rootBend,
		["Left Hip"]  = counter * o["Left Hip"]  * CFrame.Angles(0, 0, -legFold),
		["Right Hip"] = counter * o["Right Hip"] * CFrame.Angles(0, 0, C.KICK_DIR * C.KICK_ANGLE * i.kick + legFold),
		["Right Shoulder"] = swayCF * o["Right Shoulder"] * CFrame.Angles(0, 0, i.arm * C.RIGHT_ARM_DIR),
		["Left Shoulder"]  = swayCF * o["Left Shoulder"]  * CFrame.Angles(0, 0, i.arm * C.LEFT_ARM_DIR),
	}
	local rk = i.ranged or 0
	if rk > 2.5 then RigPose.staff(out, i, o)
	elseif rk > 0.5 then RigPose.ranged(out, i, o, rk > 1.5) end
	return out
end

-- BOWS AND CROSSBOWS: arms and stance laid over the pose (CameraRig and
-- RigReplicator feed the inputs; RangedClient sets them): aim 0..1 raises the
-- weapon, draw 0..1 pulls a bow's string to the face, reload 0..1 is a
-- crossbow's windlass. An arm: raised forward by `raise` (½π = level), swung
-- across the chest by `across` (radians; negative swings it out).
local function arm(o, name, raise, across)
	local dir = name == "Right Shoulder" and C.RIGHT_ARM_DIR or C.LEFT_ARM_DIR
	local side = name == "Right Shoulder" and 1 or -1
	local base = o[name]
	return CFrame.new(base.Position) * CFrame.Angles(0, across * side * C.SWING_DIR, 0) * base.Rotation * CFrame.Angles(0, 0, raise * dir)
end
function RigPose.ranged(out, i, o, crossbow)
	local aim, draw, reload = math.clamp(i.aim or 0, 0, 1), math.clamp(i.draw or 0, 0, 1), math.clamp(i.reload or 0, 0, 1)
	local level = math.pi / 2
	local pitch = i.arm or 0
	if not crossbow and reload > 0 and draw <= 0 then
		-- nocking: the string hand (the left) goes back over the shoulder to the quiver and down to the string
		local reach = math.sin(math.min(reload, 1) * math.pi)
		out["Right Shoulder"] = arm(o, "Right Shoulder", 0.9 + 0.3 * (1 - reach), 0.25)
		out["Left Shoulder"] = arm(o, "Left Shoulder", 0.4 + 2.2 * reach, -0.35 * reach + 0.3 * (1 - reach))
	elseif not crossbow then
		-- side-on: the shoulders turn onto the line to the target (the right, the bow's, in front,
		-- the left behind the head), the bow arm straight out along it. (The bow is in the RIGHT
		-- hand and the left draws: the camera sits over the right shoulder, so the body turns
		-- away from its line instead of across it, and the bow stands where you aim.) Each arm turns back by the
		-- torso's twist, so both point at the target. THE DRAW: the string hand starts across at the
		-- bow and comes straight back along the line to the jaw, the shoulders turning further as
		-- it comes; the arrow ends up running straight out under your eye.
		-- AT THE READY (aim 0): the bow low and forward in the right hand, slanted across
		-- the body, the left hand across on the string by the nock; it blends into the
		-- aim as the draw starts.
		local R = C.BOW_READY
		local twist = (R.twist + (C.BOW_TWIST - R.twist + C.BOW_TWIST_DRAW * draw) * aim) * C.TWIST_DIR
		out.RootJoint = out.RootJoint * CFrame.Angles(0, 0, twist)
		out.Neck = out.Neck * CFrame.Angles(0, 0, -twist)
		local up = level + pitch
		local function mix(a, b) return a + (b - a) * aim end
		out["Right Shoulder"] = arm(o, "Right Shoulder", mix(R.bowRaise, up), mix(R.bowAcross, -twist))
		out["Left Shoulder"] = arm(o, "Left Shoulder", mix(R.stringRaise, up * (1 - 0.05 * draw)),
			mix(R.stringAcross, twist + 0.6 * (1 - draw)))
	else
		-- THE CROSSBOW, always in both hands. AT EASE (aim 0): low across the body, the
		-- stock at the right hip, the left hand under the front. RAISED (aim 1, right mouse
		-- held): shouldered, a little side-on, the tiller along the line of sight (the
		-- right arm's raise follows the camera's pitch, so it points where you look), the
		-- left hand under it. SPANNING (reload 0..1): nose down at the right foot in the
		-- stirrup, bent over the stock, hauling the string up in strokes; the back
		-- straightens with each pull. The tiller runs along the right arm, so an arm
		-- hanging down points it at the ground.
		local X = C.XBOW
		local up = level + pitch
		local function mix(a, b, t) return a + (b - a) * t end
		local tw = X.twist * aim * C.TWIST_DIR
		local rR = mix(X.easeRightRaise, up, aim)
		local rA = mix(X.easeRightAcross, -tw + X.aimRightAcross, aim)
		local lR = mix(X.easeLeftRaise, up + X.aimLeftRaise, aim)
		local lA = mix(X.easeLeftAcross, tw + X.aimLeftAcross, aim)
		local bend = 0
		if reload > 0 then
			local function smooth(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
			local env = smooth(reload / 0.14) * (1 - smooth((reload - 0.86) / 0.14))
			local stroke = math.clamp((reload - 0.14) / 0.72, 0, 1)
			local pull = math.abs(math.sin(math.pi * X.strokes * stroke))
			bend = env * (X.bend - X.bendPull * pull)          -- deepest as a stroke starts, straighter as it hauls
			rR, rA = mix(rR, bend + X.spanRight, env), mix(rA, X.spanRightAcross, env)
			lR, lA = mix(lR, bend + X.spanLeft + X.spanLeftPull * pull, env), mix(lA, X.spanLeftAcross, env)
			tw = tw * (1 - env)
			out["Right Hip"] = out["Right Hip"] * CFrame.Angles(0, 0, C.KICK_DIR * 0.3 * env)   -- the foot forward, in the stirrup
		end
		if tw ~= 0 then
			out.RootJoint = out.RootJoint * CFrame.Angles(0, 0, tw)
			out.Neck = out.Neck * CFrame.Angles(0, 0, -tw)
		end
		if bend > 0 then
			-- bent over at the waist; the legs stay planted under it
			local S = CFrame.Angles(bend * C.CROUCH_LEAN_DIR, 0, 0)
			out.RootJoint = out.RootJoint * S
			local keep = o.RootJoint * S:Inverse() * o.RootJoint:Inverse()
			out["Left Hip"] = keep * out["Left Hip"]
			out["Right Hip"] = keep * out["Right Hip"]
			out.Neck = out.Neck * CFrame.Angles(-bend * 0.4 * C.CROUCH_LEAN_DIR, 0, 0)   -- (eyes on the work)
		end
		out["Right Shoulder"] = arm(o, "Right Shoulder", rR, rA)
		out["Left Shoulder"] = arm(o, "Left Shoulder", lR, lA)
	end
end

-- THE STAFF (ranged = 3: MagicClient). The staff rides in the right fist like any weapon, so an
-- arm held out level stands it upright. AT EASE (aim 0): out in front, upright, the left hand
-- loose. CASTING / WARDING (aim 1): the left hand thrust out at the target (it follows the
-- camera's pitch), the staff tipped forward over it, the orb leading; the cast (draw 0..1)
-- draws the staff back and up, and it snaps forward as the spell goes.
function RigPose.staff(out, i, o)
	local S = C.STAFF
	local aim, draw = math.clamp(i.aim or 0, 0, 1), math.clamp(i.draw or 0, 0, 1)
	local level = math.pi / 2
	local pitch = i.arm or 0
	local function mix(a, b) return a + (b - a) * aim end
	local rR = mix(S.easeRaise, S.castRaise + S.drawLift * draw + pitch * 0.5)
	local rA = mix(S.easeAcross, S.castAcross)
	local lR = mix(S.easeLeftRaise, level + pitch)
	local lA = mix(S.easeLeftAcross, S.castLeftAcross)
	local tw = S.twist * aim * C.TWIST_DIR
	if tw ~= 0 then
		out.RootJoint = out.RootJoint * CFrame.Angles(0, 0, tw)
		out.Neck = out.Neck * CFrame.Angles(0, 0, -tw)
	end
	out["Right Shoulder"] = arm(o, "Right Shoulder", rR, rA - tw)
	out["Left Shoulder"] = arm(o, "Left Shoulder", lR, lA + tw)
end

-- an emote (ReplicatedStorage ▸ Emotes) layers its pose over the targets and
-- snaps to it; required lazily (Emotes is a sibling module)
local Emotes = nil
local function emotes()
	if Emotes == nil then
		local ok, m = pcall(function() return require(script.Parent:WaitForChild("Emotes", 2)) end)
		Emotes = ok and m or false
	end
	return Emotes
end

-- an emote owns the body: the look's bend (the torso, head and arms following the camera's
-- pitch) and a weapon's stance are let go while one plays, so a salute is a salute and a
-- tossed blade goes straight up wherever you're looking. Returns the inputs to pose with.
function RigPose.calm(char, inputs)
	local E = emotes()
	if not (E and char and E.playing(char)) then return inputs end
	local out = table.clone(inputs)
	out.pitch, out.arm, out.ranged, out.aim, out.draw, out.reload = 0, 0, 0, 0, 0, 0
	return out
end

-- lerps each joint's C0 toward the target; legAlpha lets kicks snap faster
function RigPose.apply(j, target, alpha, legAlpha)
	legAlpha = legAlpha or alpha
	local E = emotes()
	local char = j.Neck and j.Neck.Parent and j.Neck.Parent.Parent
	if E and char then
		local t2 = E.modify(char, target)
		if t2 then target = t2; alpha = 1; legAlpha = 1 end
	end
	for name, cf in pairs(target) do
		local m = j[name]
		if m and m.Parent then
			local a = (name == "Left Hip" or name == "Right Hip") and legAlpha or alpha
			m.C0 = m.C0:Lerp(cf, a)
		end
	end
end

-- wire format: a flat array of 9 numbers
local KEYS = {"pitch", "bob", "leanX", "leanZ", "kick", "crouch", "arm", "swayX", "swayY", "hitX", "hitZ", "ranged", "aim", "draw", "reload"}
local LIMIT = 4   -- sanity clamp on every input

function RigPose.pack(i)
	local a = table.create(#KEYS)
	for n, k in ipairs(KEYS) do a[n] = i[k] or 0 end
	return a
end

function RigPose.unpack(a)
	if type(a) ~= "table" or #a ~= #KEYS then return nil end
	local i = {}
	for n, k in ipairs(KEYS) do
		local v = a[n]
		if type(v) ~= "number" or v ~= v then return nil end
		i[k] = math.clamp(v, -LIMIT, LIMIT)
	end
	return i
end

function RigPose.lerpInputs(from, to, alpha)
	local i = {}
	for _, k in ipairs(KEYS) do i[k] = from[k] + (to[k] - from[k]) * alpha end
	i.ranged = to.ranged   -- (a stance, not an amount: never half a bow on the way to a staff)
	return i
end

RigPose.ZERO = {pitch = 0, bob = 0, leanX = 0, leanZ = 0, kick = 0, crouch = 0, arm = 0, swayX = 0, swayY = 0, hitX = 0, hitZ = 0, ranged = 0, aim = 0, draw = 0, reload = 0}

return RigPose
