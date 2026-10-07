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
	-- forged weapons AIM: the arms and weapon turn with the camera's pitch about
	-- the eyes, so a swing or a thrust goes where the crosshair points
	AIM_EYE     = Vector3.new(0, 1.5, 0),   -- the eyes, in root space
	AIM_DIST    = 7,                         -- (third person) studs past you where the attack meets the crosshair
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
	-- aiming (a forged weapon out): RigPose.apply turns the arms about the eyes
	local aim = (i.aim or 0) > 0.5 and {pitch = i.aimP or i.pitch, yaw = i.aimY or 0, rootC0 = o.RootJoint,
		rs = swayCF * o["Right Shoulder"], ls = swayCF * o["Left Shoulder"]} or nil
	return {
		_aim = aim,
		Neck      = o.Neck * CFrame.Angles(p * C.NECK_PITCH, 0, 0),
		RootJoint = CFrame.new(0, i.bob - C.CROUCH_DROP * i.crouch, 0) * rootBend,
		["Left Hip"]  = counter * o["Left Hip"]  * CFrame.Angles(0, 0, -legFold),
		["Right Hip"] = counter * o["Right Hip"] * CFrame.Angles(0, 0, C.KICK_DIR * C.KICK_ANGLE * i.kick + legFold),
		["Right Shoulder"] = swayCF * o["Right Shoulder"] * CFrame.Angles(0, 0, i.arm * C.RIGHT_ARM_DIR),
		["Left Shoulder"]  = swayCF * o["Left Shoulder"]  * CFrame.Angles(0, 0, i.arm * C.LEFT_ARM_DIR),
	}
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

local AnimSetsMod = nil
local function animSets()
	if AnimSetsMod == nil then
		local ok, m = pcall(function() return require(script.Parent:WaitForChild("Combat", 2):WaitForChild("AnimSets", 2)) end)
		AnimSetsMod = ok and m or false
	end
	return AnimSetsMod
end

-- AIM: the shoulders' C0s that turn the arms (and the weapon in the hand) by
-- `pitch` about the eyes, whatever the torso's own bend and animated turn —
-- so the weapon's path crosses the line of sight exactly as the clip has it
-- crossing straight ahead. rootC0 / rs / ls are the rest C0s (origins).
function RigPose.aimArms(j, rootC0, rs, ls, pitch, yaw)
	local rj = j.RootJoint
	if not (rj and j["Right Shoulder"] and j["Left Shoulder"]) then return end
	local c1r, ttor = rj.C1, rj.Transform
	local E = C.AIM_EYE
	local turn = CFrame.new(E) * CFrame.Angles(0, yaw or 0, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(-E)
	local k = (c1r * ttor:Inverse() * rj.C0:Inverse()) * turn * (rootC0 * ttor * c1r:Inverse())
	j["Right Shoulder"].C0 = k * rs
	j["Left Shoulder"].C0 = k * ls
end

-- where an attack should meet the crosshair: the pitch and yaw (root space,
-- about the eyes) toward the point on the camera's ray AIM_DIST studs past the
-- character. First person this is just the camera's pitch; third person (camera
-- behind and over the shoulder) it converges the swing on the crosshair.
function RigPose.aimAngles(rootCF, camCF)
	local eye = rootCF:PointToWorldSpace(C.AIM_EYE)
	local along = math.max((eye - camCF.Position):Dot(camCF.LookVector), 0)
	local p = camCF.Position + camCF.LookVector * (along + C.AIM_DIST)
	local rel = rootCF:PointToObjectSpace(p) - C.AIM_EYE
	local flat = math.sqrt(rel.X * rel.X + rel.Z * rel.Z)
	return math.atan2(rel.Y, math.max(flat, 1e-3)), math.atan2(-rel.X, -rel.Z)
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
	-- forged animations turn the torso freely; the hips counter that turn so
	-- the legs (walking or standing) stay planted under the hips (AnimSets)
	local S = animSets()
	local counter = S and S.forged() and j.RootJoint and S.counterHips(j.RootJoint) or nil
	j._base = j._base or {}
	for name, cf in pairs(target) do
		local m = j[name]
		if m and m.Parent and type(name) == "string" and name:sub(1, 1) ~= "_" then
			local hip = name == "Left Hip" or name == "Right Hip"
			local a = hip and legAlpha or alpha
			if hip then
				local base = (j._base[name] or m.C0):Lerp(cf, a)
				j._base[name] = base
				m.C0 = counter and counter * base or base
			else
				m.C0 = m.C0:Lerp(cf, a)
			end
		end
	end
	local aim = target._aim
	if aim then RigPose.aimArms(j, aim.rootC0, aim.rs, aim.ls, aim.pitch, aim.yaw) end
end

-- wire format: a flat array of 9 numbers
local KEYS = {"pitch", "bob", "leanX", "leanZ", "kick", "crouch", "arm", "swayX", "swayY", "hitX", "hitZ", "aim", "aimP", "aimY"}
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

RigPose.ZERO = {pitch = 0, bob = 0, leanX = 0, leanZ = 0, kick = 0, crouch = 0, arm = 0, swayX = 0, swayY = 0, hitX = 0, hitZ = 0}

return RigPose
