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
	BOW_TWIST       = 0.55,          -- the archer turns side-on to the target (radians)
	TWIST_DIR       = -1,            -- flip if the wrong shoulder comes forward (the bow's, the left, leads)
	SWING_DIR       = 1,             -- flip if "across the chest" swings the arms outward
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
	if rk > 0.5 then RigPose.ranged(out, i, o, rk > 1.5) end
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
		-- nocking: the string hand goes back over the shoulder to the quiver and down to the string
		local reach = math.sin(math.min(reload, 1) * math.pi)
		out["Left Shoulder"] = arm(o, "Left Shoulder", 0.9 + 0.3 * (1 - reach), 0.25)
		out["Right Shoulder"] = arm(o, "Right Shoulder", 0.4 + 2.2 * reach, -0.35 * reach + 0.3 * (1 - reach))
	elseif not crossbow then
		-- side-on, the bow arm straight out at the target, the string hand drawn back to the jaw
		-- (the torso turns by `twist`; each arm turns back by as much, so both still point at the target)
		local twist = C.BOW_TWIST * aim * C.TWIST_DIR
		out.RootJoint = out.RootJoint * CFrame.Angles(0, 0, twist)
		out.Neck = out.Neck * CFrame.Angles(0, 0, -twist)
		out["Left Shoulder"] = arm(o, "Left Shoulder", aim * (level + pitch) + (1 - aim) * 0.35, twist)
		out["Right Shoulder"] = arm(o, "Right Shoulder",
			aim * (level + pitch) * (1 - 0.1 * draw) + (1 - aim) * 0.1,
			-twist + aim * (0.2 + 0.55 * draw))
	elseif reload > 0 and aim < 0.5 then
		-- the windlass: the crossbow points down, the left hand cranks
		local crank = math.abs(math.sin(reload * math.pi * 4))
		out["Right Shoulder"] = arm(o, "Right Shoulder", 0.45, 0.15)
		out["Left Shoulder"] = arm(o, "Left Shoulder", 0.35 + 0.7 * crank, 0.55)
	else
		-- shouldered: the trigger hand and the hand under the tiller
		out["Right Shoulder"] = arm(o, "Right Shoulder", aim * (level + pitch) + (1 - aim) * 0.4, aim * 0.12)
		out["Left Shoulder"] = arm(o, "Left Shoulder", aim * (level + pitch) * 0.97 + (1 - aim) * 0.3, aim * 0.62)
	end
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
	return i
end

RigPose.ZERO = {pitch = 0, bob = 0, leanX = 0, leanZ = 0, kick = 0, crouch = 0, arm = 0, swayX = 0, swayY = 0, hitX = 0, hitZ = 0, ranged = 0, aim = 0, draw = 0, reload = 0}

return RigPose
