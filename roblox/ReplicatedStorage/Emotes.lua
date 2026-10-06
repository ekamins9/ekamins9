--[[ EMOTES — procedural emote motions for R6 characters (Catalog ▸ Emotes
     lists them). An emote is keyframed joint rotations plus the weapon in the
     hand (a spin about the grip, or a toss through the air). Every client runs
     the emotes it is told about (Hub ▸ Cosmetics relays them), on top of the
     rig's procedural pose: RigPose.apply asks Emotes.modify for the joint
     targets, and while an emote plays the joints it drives ignore the
     Animator (their Transform is zeroed before each render).

       Emotes.play(character, id [, startedAt])   start (or restart) an emote
       Emotes.stop(character)                     end it, restore the grip
       Emotes.playing(character)                  the id, or nil
       Emotes.isUpper(id)                         an arms-only emote (you can walk)
       Emotes.modify(character, targets)          used by RigPose.apply
       Emotes.sample(id, t)                       the pose at time t (previews)
       Emotes.poseRig(rig, id, t, origins)        pose an anchored preview rig
       Emotes.DURATION[id]

     UPPER emotes (upper = true) drive only the arms, the neck and the waist:
     the legs keep walking, so they play on the move. The others are whole-body
     and end when you move. Attacking, blocking, kicking or dodging ends any
     emote (the character's Acting / Blocking attributes, for every player).

     A pose, all in degrees, each joint turned in its parent's frame about the
     joint (x+ swings a limb forward, z+ lifts the right arm out, z- the left):
       rs ls neck     arms and head
       waist          the upper body bends at the hips; the legs stay planted
       rh lh          legs (dances, kneels), in the torso's frame
       root           the whole body turns about its middle (a spin)
       rootY          the whole body rises / sinks (studs)
       hopY           a hop added only while standing still
       grip           the weapon turned about the hand
       blade          where the blade points, in the body's frame (+y up, -z
                      ahead, +x right): the hand turns the weapon to it, so a
                      dagger and a greatsword both salute upright
       plantW         0..1: the tip goes to the ground ahead (any blade length)
       twirl          the weapon turns like a wheel beside the body (degrees)
       rotor          the weapon turns flat about the hand, like a rotor (degrees)
       toss, tossW, tossSpin   the weapon flies free of the hand: a point in
                      the torso's frame, how free (0..1), its spin ]]

local RunService = game:GetService("RunService")

local Emotes = {}
local rad = math.rad

local JOINT = {rs = "Right Shoulder", ls = "Left Shoulder", rh = "Right Hip", lh = "Left Hip", neck = "Neck", root = "RootJoint"}
local KEYS = {"rs", "ls", "rh", "lh", "neck", "root", "waist"}
local Z3 = {0, 0, 0}
local HIP_LINE = Vector3.new(0, -1, 0)   -- where the waist bends, in the root part's frame

local function ease(t) return t * t * (3 - 2 * t) end
local function lerp(a, b, t) return a + (b - a) * t end
local function lerp3(a, b, t) a, b = a or Z3, b or Z3; return {lerp(a[1], b[1], t), lerp(a[2], b[2], t), lerp(a[3], b[3], t)} end
local function zero(v) return v == nil or (v[1] == 0 and v[2] == 0 and v[3] == 0) end

-- keyframes {{t, pose}, ...} → pose at t (smoothstep between keys)
local function track(keys)
	return function(t)
		if t <= keys[1][1] then return keys[1][2] end
		for i = 1, #keys - 1 do
			local a, b = keys[i], keys[i + 1]
			if t <= b[1] then
				local f = ease((t - a[1]) / math.max(b[1] - a[1], 1e-3))
				local pa, pb = a[2], b[2]
				local out = {}
				for _, k in ipairs(KEYS) do out[k] = lerp3(pa[k], pb[k], f) end
				out.rootY = lerp(pa.rootY or 0, pb.rootY or 0, f)
				out.hopY = lerp(pa.hopY or 0, pb.hopY or 0, f)
				out.grip = lerp3(pa.grip, pb.grip, f)
				if pa.blade or pb.blade then
					out.blade = lerp3(pa.blade or pb.blade, pb.blade or pa.blade, f)
					out.bladeW = lerp(pa.blade and (pa.bladeW or 1) or 0, pb.blade and (pb.bladeW or 1) or 0, f)
				end
				out.plantW = lerp(pa.plantW or 0, pb.plantW or 0, f)
				out.twirl = lerp(pa.twirl or 0, pb.twirl or 0, f)
				out.rotor = lerp(pa.rotor or 0, pb.rotor or 0, f)
				out.tossW = lerp(pa.tossW or 0, pb.tossW or 0, f)
				out.tossSpin = lerp(pa.tossSpin or 0, pb.tossSpin or 0, f)
				if pa.toss or pb.toss then out.toss = (pa.toss or pb.toss):Lerp(pb.toss or pa.toss, f) end
				return out
			end
		end
		return keys[#keys][2]
	end
end
-- add motion on top of a track: fn(t, pose, reach) edits a copy (reach = the
-- weapon's length, for moves that must clear the floor with any blade)
local function with(base, extra)
	return function(t, reach)
		local p = base(t)
		local q = {}
		for k, v in pairs(p) do q[k] = (type(v) == "table") and {v[1], v[2], v[3]} or v end
		for _, k in ipairs(KEYS) do q[k] = q[k] or {0, 0, 0} end
		extra(t, q, reach or 3)
		return q
	end
end
-- 0 → 1 → 0 over [a, b] with `ramp` seconds each side (for wobbles inside a hold)
local function window(t, a, b, ramp)
	ramp = ramp or 0.2
	return math.clamp((t - a) / ramp, 0, 1) * math.clamp((b - t) / ramp, 0, 1)
end

--------------------------------------------------------------------
--  THE EMOTES: duration, upper?, pose(t)
--------------------------------------------------------------------
local DEF = {}

-- blade to the brow
local SALUTE = {rs = {132, 0, -27}, blade = {0, 1, 0.05}, neck = {4, 0, 0}, waist = {4, 0, 0}}
DEF.Salute = {d = 2.0, upper = true, pose = track({
	{0, {}}, {0.35, SALUTE}, {1.45, SALUTE}, {2.0, {}},
})}

-- a courtly bow: hand to the heart, the sword swept out behind
local BOW = {waist = {-42, 0, 0}, neck = {-12, 0, 0}, ls = {80, 0, 44}, rs = {-30, 0, 30}, blade = {0.35, 0.05, 1}}
-- (the blade swings out to the side and round, never through the floor)
local REST = {blade = {0, 0, -1}}
DEF.Bow = {d = 2.3, pose = track({
	{0, REST}, {0.25, {ls = {60, 0, 30}, rs = {-10, 0, 20}, blade = {1, 0.05, -0.3}}}, {0.65, BOW}, {1.55, BOW},
	{1.95, {ls = {30, 0, 10}, rs = {-10, 0, 15}, blade = {1, 0.05, -0.2}}}, {2.3, REST},
})}

-- both arms up, pumping (and hopping, when you stand still)
local CHEER = {rs = {165, 0, 22}, ls = {165, 0, -22}, neck = {18, 0, 0}, waist = {6, 0, 0}, blade = {0.15, 1, 0.1}}
DEF.Cheer = {d = 2.0, upper = true, pose = with(track({
	{0, {}}, {0.25, CHEER}, {1.6, CHEER}, {2.0, {}},
}), function(t, p)
	local w = window(t, 0.25, 1.6, 0.15)
	local s = math.sin((t - 0.25) * 10)
	p.rs[1] += 10 * s * w; p.ls[1] += 10 * s * w
	p.hopY = math.abs(math.sin((t - 0.25) * 5)) * 0.4 * w
end)}

-- twirl the sword twice at your side, then salute. The arm rises with the
-- blade's length, so even a greatsword's tip clears the floor.
DEF.Flourish = {d = 2.4, upper = true, pose = with(track({
	{0, {blade = {0, 0, -1}}},
	{0.3, {rs = {20, 0, 70}, blade = {0, 0, -1}, neck = {0, -10, 0}}},
	{1.2, {rs = {20, 0, 70}, blade = {0, 0, -1}, twirl = 720, neck = {0, -10, 0}}},
	{1.55, {rs = {132, 0, -27}, blade = {0, 1, 0.05}, twirl = 720, neck = {4, 0, 0}}},
	{1.9, {rs = {132, 0, -27}, blade = {0, 1, 0.05}, twirl = 720, neck = {4, 0, 0}}},
	{2.4, {blade = {0, 0, -1}, twirl = 720}},
}), function(t, p, reach)
	-- the hand must stand higher than the blade is long: lift the arm out
	local need = math.deg(math.acos(math.clamp((3.1 - reach) / 2, -1, 1)))
	local w = window(t, 0.05, 1.45, 0.3)
	p.rs[3] += math.max(0, need - 70) * w
	if t > 0.3 and t < 1.2 then
		local k = math.sin((t - 0.3) / 0.9 * math.pi)
		p.rs[1] += 8 * math.sin(t * 15) * k
	end
end)}

-- the free hand waves
local WAVE = {ls = {140, 0, -30}, neck = {0, 0, -6}}
DEF.Wave = {d = 1.8, upper = true, pose = with(track({
	{0, {}}, {0.25, WAVE}, {1.4, WAVE}, {1.8, {}},
}), function(t, p) p.ls[3] += 20 * math.sin((t - 0.25) * 13) * window(t, 0.25, 1.4, 0.12) end)}

local SHRUG = {rs = {34, 0, 34}, ls = {34, 0, -34}, neck = {4, 0, 14}, waist = {5, 0, 0}}
DEF.Shrug = {d = 1.6, upper = true, pose = track({
	{0, {}}, {0.3, SHRUG}, {1.15, SHRUG}, {1.6, {}},
})}

-- "come here"
local BECKON = {ls = {84, 0, -6}, neck = {4, 8, -6}}
DEF.Beckon = {d = 2.0, upper = true, pose = with(track({
	{0, {}}, {0.25, BECKON}, {1.6, BECKON}, {2.0, {}},
}), function(t, p) p.ls[1] += 24 * math.sin((t - 0.25) * 12) * window(t, 0.25, 1.6, 0.1) end)}

-- the arms' forward raise that puts the hands `h` studs above the floor
-- (the shoulder pivot stands `pivot` high; the hand hangs 1.5 below it)
local function raiseFor(h, pivot) return math.deg(math.acos(math.clamp((pivot - h) / 1.5, -1, 1))) end

-- down on one knee, both hands on the planted sword (higher for a longer one)
local KNEEL = {rootY = -0.6, lh = {58, 0, 0}, rh = {-55, 0, 0}, rs = {0, 0, -14}, ls = {0, 0, 22}, neck = {-16, 0, 0}, plantW = 1}
DEF.Kneel = {d = 3.2, pose = with(track({
	{0, REST}, {0.45, KNEEL}, {2.6, KNEEL}, {3.2, REST},
}), function(t, p, reach)
	local k = ease(window(t, 0, 3.2, 0.5))
	local x = math.min(95, math.max(55, raiseFor(0.8 * reach, 2.9)))
	p.rs[1] += x * k; p.ls[1] += (x - 4) * k
end)}

local LAUGH = {waist = {-16, 0, 0}, neck = {24, 0, 0}, ls = {42, 0, 30}, rs = {28, 0, -8}}
DEF.Laugh = {d = 2.4, upper = true, pose = with(track({
	{0, {}}, {0.25, LAUGH}, {2.0, LAUGH}, {2.4, {}},
}), function(t, p)
	local s = math.sin(t * 26) * 5 * window(t, 0.25, 2.0, 0.15)
	p.waist[1] += s; p.neck[1] += s * 0.6
end)}

-- a tavern jig: one leg kicks at a time, the other stays down
DEF.Jig = {d = 3.2, pose = with(track({
	{0, {}}, {3.2, {}},
}), function(t, p)
	local w = window(t, 0.2, 2.9, 0.2)
	local s = math.sin(t * 13)
	p.rh = {40 * math.max(0, s) * w, 0, 0}
	p.lh = {40 * math.max(0, -s) * w, 0, 0}
	p.rs = {(-40 * s + 40) * w, 0, 30 * w}
	p.ls = {(40 * s + 40) * w, 0, -30 * w}
	p.waist = {0, 16 * math.sin(t * 6.5) * w, 0}
	p.rootY = math.abs(s) * 0.3 * w
end)}

local CRY = {rs = {160, 0, 30}, ls = {160, 0, -30}, neck = {30, 0, 0}, waist = {14, 0, 0}, blade = {0.2, 1, -0.15}}
DEF.WarCry = {d = 2.4, upper = true, pose = with(track({
	{0, {}}, {0.3, CRY}, {1.9, CRY}, {2.4, {}},
}), function(t, p)
	local s = math.sin(t * 40) * 3 * window(t, 0.3, 1.9, 0.1)
	p.rs[3] += s; p.ls[3] -= s; p.neck[3] += s
end)}

-- up it goes, spinning, and back into the hand
DEF.BladeToss = {d = 2.7, upper = true, pose = track({
	{0, {}}, {0.3, {rs = {128, 0, 8}}},
	{0.38, {rs = {150, 0, 8}, tossW = 1, toss = Vector3.new(1.5, 3.2, -0.6), tossSpin = 0}},
	{0.95, {rs = {60, 0, 10}, tossW = 1, toss = Vector3.new(1.5, 9.5, -0.8), tossSpin = 540, neck = {30, 0, 0}}},
	{1.5, {rs = {120, 0, 8}, tossW = 1, toss = Vector3.new(1.5, 3.2, -0.6), tossSpin = 1080}},
	{1.58, {rs = {118, 0, 8}, tossW = 0, toss = Vector3.new(1.5, 3.2, -0.6), tossSpin = 1080}},
	{2.0, SALUTE}, {2.25, SALUTE}, {2.7, {}},
})}

-- the sword spins flat over your head like a rotor while you turn on the spot
local MILL = {rs = {172, 0, 4}, ls = {24, 0, -24}, neck = {14, 0, 0}, blade = {0, 0.05, -1}}
DEF.Windmill = {d = 3.2, pose = with(track({
	{0, REST}, {0.3, MILL}, {2.8, MILL}, {3.2, REST},
}), function(t, p)
	-- six whole turns, winding up and easing down, so the blade lands where it started
	local k = math.clamp((t - 0.3) / 2.5, 0, 1)
	p.rotor = 6 * 360 * ease(k)
	p.root = {0, 360 * ease(k), 0}
end)}

-- the sword planted upright before you, both hands on the pommel: the hands
-- stand as high as the blade is long, so its tip just meets the ground
local CHAMP = {rs = {0, 0, -24}, ls = {0, 0, 26}, plantW = 1, neck = {10, 0, 0}, waist = {4, 0, 0}}
DEF.Champion = {d = 3.4, pose = with(track({
	{0, REST}, {0.45, CHAMP}, {2.9, CHAMP}, {3.4, REST},
}), function(t, p, reach)
	local k = ease(window(t, 0, 3.4, 0.45))
	local x = math.min(125, math.max(35, raiseFor(0.92 * reach, 3.5)))
	p.rs[1] += x * k; p.ls[1] += (x + 2) * k
end)}

Emotes.DURATION = {}
for id, d in pairs(DEF) do Emotes.DURATION[id] = d.d end
function Emotes.has(id) return DEF[id] ~= nil end
function Emotes.isUpper(id) return DEF[id] ~= nil and DEF[id].upper == true end

function Emotes.sample(id, t, reach)
	local d = DEF[id]
	if not d then return nil end
	return d.pose(math.clamp(t, 0, d.d), reach)
end

--------------------------------------------------------------------
--  A POSE ON A SET OF C0s (shared by live characters and previews)
--------------------------------------------------------------------
local function rotAbout(c0, deg)
	if zero(deg) then return c0 end
	return CFrame.new(c0.Position) * CFrame.Angles(rad(deg[1]), rad(deg[2]), rad(deg[3])) * c0.Rotation
end

-- base = {[joint name] = C0}; rootC1 = the RootJoint's C1; standing = not moving
local function posed(p, base, rootC1, standing)
	local out = {}
	for k, v in pairs(base) do out[k] = v end
	for _, k in ipairs({"rs", "ls", "neck"}) do
		local name = JOINT[k]
		if out[name] then out[name] = rotAbout(out[name], p[k]) end
	end
	local R = out.RootJoint
	if R then
		-- the waist: the upper body bends about the hip line, and the legs are
		-- posed back to exactly where they were (torso' * hip' = torso * hip)
		if not zero(p.waist) then
			local W = CFrame.new(HIP_LINE) * CFrame.Angles(rad(p.waist[1]), rad(p.waist[2]), rad(p.waist[3])) * CFrame.new(-HIP_LINE)
			local keep = rootC1 * R:Inverse() * W:Inverse() * R * rootC1:Inverse()
			for _, hip in ipairs({"Left Hip", "Right Hip"}) do
				if out[hip] then out[hip] = keep * out[hip] end
			end
			out.RootJoint = W * R
		end
		-- the whole body: a turn about its middle, a rise or a sink
		out.RootJoint = rotAbout(out.RootJoint, p.root)
		local y = (p.rootY or 0) + ((standing and p.hopY) or 0)
		if y ~= 0 then out.RootJoint = CFrame.new(0, y, 0) * out.RootJoint end
	end
	for _, k in ipairs({"rh", "lh"}) do
		local name = JOINT[k]
		if out[name] then out[name] = rotAbout(out[name], p[k]) end
	end
	return out
end

-- the weapon in the hand: the grip's C0 for this pose. armCF / rootCF = where
-- the arm and the body are this frame; base = the grip's resting C0; reach =
-- the blade's length (studs from the grip to the tip). Everything is done in
-- the GRIP's frame (arm * C0): every weapon's blade runs along its Y axis
-- there (that is what points it forward at rest), whatever a tool's own
-- handle part or C1 look like. `plant` aims the tip at the ground ahead
-- (steeper for short blades, flatter for long ones, so every weapon just
-- touches it); `twirl` turns it like a wheel beside the body.
local function gripC0(p, armCF, rootCF, base, reach)
	local g = p.grip
	local natural = base * (g and CFrame.Angles(rad(g[1]), rad(g[2]), rad(g[3])) or CFrame.identity)
	local held = armCF * natural
	-- where the blade should point: the planted direction and the posed one, blended
	local want = Vector3.zero
	local wp = p.plantW or 0
	local wb = (p.blade and p.bladeW) or 0
	if wp > 0.001 then
		local h = math.max(0.1, held.Position.Y - (rootCF.Position.Y - 3))
		local down = math.min(1, h / math.max(reach or 3, 0.5))
		want += rootCF:VectorToWorldSpace(Vector3.new(0, -down, -math.sqrt(math.max(0, 1 - down * down)))) * wp
	end
	if wb > 0.001 then
		local b = Vector3.new(p.blade[1], p.blade[2], p.blade[3])
		if b.Magnitude > 1e-3 then want += rootCF:VectorToWorldSpace(b.Unit) * wb end
	end
	local w = math.min(1, wp + wb)
	if w <= 0.001 then want = nil end
	local H = held
	if want and want.Magnitude > 1e-3 then
		want = want.Unit
		local up = held.UpVector
		local dot = math.clamp(up:Dot(want), -1, 1)
		local axis = up:Cross(want)
		axis = axis.Magnitude > 1e-4 and axis.Unit or armCF.RightVector
		local turned = CFrame.new(held.Position) * CFrame.fromAxisAngle(axis, math.acos(dot)) * held.Rotation
		H = held:Lerp(turned, math.clamp(w, 0, 1))
	end
	if (p.twirl or 0) ~= 0 then
		-- a wheel beside the body, leaning out at the bottom so the blade
		-- passes outside the arm below and over the head above
		local axis = (rootCF.RightVector * math.cos(rad(35)) + rootCF.UpVector * math.sin(rad(35))).Unit
		H = CFrame.new(H.Position) * CFrame.fromAxisAngle(axis, rad(p.twirl)) * H.Rotation
	end
	if (p.rotor or 0) ~= 0 then
		-- flat, like a rotor, about the body's up axis through the hand
		H = CFrame.new(H.Position) * CFrame.fromAxisAngle(rootCF.UpVector, rad(p.rotor)) * H.Rotation
	end
	return armCF:Inverse() * H
end

-- how far a weapon reaches past the grip: the furthest visible point along
-- the grip frame's Y (c1 = the grip joint's C1: grip frame = handle * c1)
local function reachOf(handle, container, c1)
	local best = 1
	local frame = handle.CFrame * (c1 or CFrame.identity)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local rel = frame:ToObjectSpace(d.CFrame)
			local s = d.Size / 2
			for _, c in ipairs({Vector3.new(s.X, s.Y, s.Z), Vector3.new(-s.X, s.Y, s.Z), Vector3.new(s.X, -s.Y, s.Z), Vector3.new(s.X, s.Y, -s.Z),
				Vector3.new(-s.X, -s.Y, s.Z), Vector3.new(-s.X, s.Y, -s.Z), Vector3.new(s.X, -s.Y, -s.Z), Vector3.new(-s.X, -s.Y, -s.Z)}) do
				best = math.max(best, (rel * c).Y)
			end
		end
	end
	return best
end

--------------------------------------------------------------------
--  PLAYING ON CHARACTERS
--------------------------------------------------------------------
local active = setmetatable({}, {__mode = "k"})   -- character → {id, t0, gripC0}

function Emotes.playing(char)
	local a = char and active[char]
	return a and a.id or nil
end

-- the weld that holds the weapon: this game's ToolGrip Motor6D (attack
-- animations move the blade with it), or Roblox's own RightGrip
local function gripOf(arm)
	return arm and (arm:FindFirstChild("ToolGrip") or arm:FindFirstChild("RightGrip"))
end

local function restoreGrip(char, rec)
	local arm = char:FindFirstChild("Right Arm")
	local grip = gripOf(arm)
	if grip and rec.gripC0 and rec.gripOf == grip then grip.C0 = rec.gripC0 end
end

function Emotes.stop(char)
	local rec = char and active[char]
	if not rec then return end
	active[char] = nil
	restoreGrip(char, rec)
end

-- the length of the weapon in a character's hand (cached per tool)
local reachCache = setmetatable({}, {__mode = "k"})
local function reachIn(char)
	local tool = char:FindFirstChildOfClass("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	if not handle then return 3 end
	local r = reachCache[tool]
	if not r then
		local grip = gripOf(char:FindFirstChild("Right Arm"))
		r = reachOf(handle, tool, grip and grip.C1 or CFrame.identity)
		reachCache[tool] = r
	end
	return r
end

-- busy fighting: no emote starts, and a running one ends
local function busy(char)
	return char:GetAttribute("Acting") == true or char:GetAttribute("Blocking") == true
end
Emotes.busy = busy

function Emotes.play(char, id, startedAt)
	if not (char and DEF[id]) or busy(char) then return false end
	Emotes.stop(char)
	active[char] = {id = id, t0 = os.clock() - math.max(0, (startedAt and (workspace:GetServerTimeNow() - startedAt)) or 0)}
	return true
end

local function moving(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local v = hrp.AssemblyLinearVelocity
	return v.X * v.X + v.Z * v.Z > 4
end

-- RigPose.apply hands its joint targets here every frame
function Emotes.modify(char, targets)
	local rec = active[char]
	if not rec then return nil end
	local t = os.clock() - rec.t0
	local d = DEF[rec.id]
	if t >= d.d then Emotes.stop(char); return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local rj = hrp and hrp:FindFirstChild("RootJoint")
	return posed(d.pose(t, reachIn(char)), targets, rj and rj.C1 or CFrame.identity, not moving(char))
end

-- every frame, after the Animator: the joints an emote drives drop the
-- animation (an upper emote leaves the legs and the root to the walk), and
-- the weapon spins / flies
local JOINT_PARENT = {["Right Shoulder"] = "Torso", ["Left Shoulder"] = "Torso", ["Right Hip"] = "Torso", ["Left Hip"] = "Torso", Neck = "Torso", RootJoint = "HumanoidRootPart"}
local UPPER_PARENT = {["Right Shoulder"] = "Torso", ["Left Shoulder"] = "Torso", Neck = "Torso"}
-- (clients only: the server just poses statues with poseRig)
if RunService:IsClient() then RunService.RenderStepped:Connect(function()
	for char, rec in pairs(active) do
		if not char.Parent then active[char] = nil; continue end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if busy(char) or (hum and hum.Health <= 0) then Emotes.stop(char); continue end
		local d = DEF[rec.id]
		local t = os.clock() - rec.t0
		if t >= d.d then Emotes.stop(char); continue end
		-- the animation (the weapon's idle guard, the walk's arm swing) fades
		-- out over the first 0.2 s and back in over the last, so nothing snaps
		local fade = ease(math.clamp(math.min(t, d.d - t) / 0.2, 0, 1))
		for joint, parentName in pairs(d.upper and UPPER_PARENT or JOINT_PARENT) do
			local parent = char:FindFirstChild(parentName)
			local m = parent and parent:FindFirstChild(joint)
			if m and m:IsA("Motor6D") then m.Transform = m.Transform:Lerp(CFrame.identity, fade) end
		end
		local reach = reachIn(char)
		local p = d.pose(t, reach)
		local arm = char:FindFirstChild("Right Arm")
		local grip = gripOf(arm)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local torso = char:FindFirstChild("Torso")
		local rj = hrp and hrp:FindFirstChild("RootJoint")
		local sh = torso and torso:FindFirstChild("Right Shoulder")
		if grip and grip:IsA("JointInstance") and rj and sh then
			if rec.gripOf ~= grip then rec.gripOf = grip; rec.gripC0 = grip.C0 end
			if grip:IsA("Motor6D") then grip.Transform = grip.Transform:Lerp(CFrame.identity, fade) end
			-- the arm as it is drawn this frame, down the joint chain (the parts'
			-- own CFrames still hold the animated pose of the physics step)
			local torsoCF = hrp.CFrame * rj.C0 * rj.Transform * rj.C1:Inverse()
			local armCF = torsoCF * sh.C0 * sh.Transform * sh.C1:Inverse()
			local c0 = gripC0(p, armCF, hrp.CFrame, rec.gripC0, reach)
			if (p.tossW or 0) > 0 and p.toss then
				local want = torsoCF * CFrame.new(p.toss) * CFrame.Angles(rad(p.tossSpin or 0), 0, 0) * CFrame.Angles(math.pi / 2, 0, 0)
				local free = armCF:Inverse() * want * grip.C1
				c0 = c0:Lerp(free, math.clamp(p.tossW, 0, 1))
			end
			grip.C0 = c0
		end
	end
end) end

--------------------------------------------------------------------
--  PREVIEWS (anchored rigs in a ViewportFrame)
--------------------------------------------------------------------
-- origins = {[Motor6D] = original C0}; afterwards call the menu's settle()
function Emotes.poseRig(rig, id, t, origins)
	local wp = rig:FindFirstChild("WeaponPreview")
	local wh = wp and wp:FindFirstChild("Handle", true)
	if wh and not origins.reach then origins.reach = reachOf(wh, wp, CFrame.identity) end
	local p = Emotes.sample(id, t, origins.reach)
	if not p then return end
	local motors, base = {}, {}
	for _, joint in pairs(JOINT) do
		local parent = rig:FindFirstChild(JOINT_PARENT[joint])
		local m = parent and parent:FindFirstChild(joint)
		if m and m:IsA("Motor6D") then
			origins[m] = origins[m] or m.C0
			motors[joint] = m
			base[joint] = origins[m]
		end
	end
	local rj = motors.RootJoint
	local out = posed(p, base, rj and rj.C1 or CFrame.identity, true)
	for joint, m in pairs(motors) do m.C0 = out[joint] end
	-- the preview weapon (Dresser.attachWeapon welds carry their grip offset)
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	local sh = motors["Right Shoulder"]
	if wp and hrp and rj and sh then
		local torsoCF = hrp.CFrame * out.RootJoint * rj.C1:Inverse()
		local armCF = torsoCF * out["Right Shoulder"] * sh.C1:Inverse()
		local held
		for _, w in ipairs(wp:GetDescendants()) do
			if w:IsA("Weld") then
				local gb, off = w:GetAttribute("GripBase"), w:GetAttribute("GripOffset")
				if typeof(gb) == "CFrame" and typeof(off) == "CFrame" then
					held = held or gripC0(p, armCF, hrp.CFrame, gb, origins.reach)
					w.C0 = held * off
				end
			end
		end
	end
end

return Emotes
