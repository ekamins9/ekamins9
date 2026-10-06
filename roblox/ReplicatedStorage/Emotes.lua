--[[ EMOTES — procedural emote motions for R6 characters (Catalog ▸ Emotes
     lists them). An emote is keyframed joint rotations plus the weapon in the
     hand (a spin about the grip, or a toss through the air). Every client runs
     the emotes it is told about (HubServer relays them), on top of the rig's
     procedural pose: RigPose.apply asks Emotes.modify for the joint targets,
     and while an emote plays its joints ignore the Animator (their Transform is
     zeroed before each render), so the pose is exactly the emote's.

       Emotes.play(character, id [, startedAt])   start (or restart) an emote
       Emotes.stop(character)                     end it, restore the grip
       Emotes.playing(character)                  the id, or nil
       Emotes.modify(character, targets)          used by RigPose.apply
       Emotes.sample(id, t)                       the pose at time t (previews)
       Emotes.poseRig(rig, id, t, origins)        pose an anchored preview rig
       Emotes.DURATION[id]

     A pose: rs / ls / rh / lh / neck / root = {x, y, z} degrees, turned in the
     joint's parent (torso) frame about the joint (x+ swings a limb forward, z+
     lifts the right arm out, z- the left), rootY (studs), grip = {x, y, z}
     degrees about the hand, toss = Vector3 (torso frame) + tossW (0..1) +
     tossSpin (degrees): the weapon flies free of the hand. ]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Emotes = {}
local rad = math.rad

local JOINT = {rs = "Right Shoulder", ls = "Left Shoulder", rh = "Right Hip", lh = "Left Hip", neck = "Neck", root = "RootJoint"}
local KEYS = {"rs", "ls", "rh", "lh", "neck", "root"}
local Z3 = {0, 0, 0}

local function ease(t) return t * t * (3 - 2 * t) end
local function lerp(a, b, t) return a + (b - a) * t end
local function lerp3(a, b, t) a, b = a or Z3, b or Z3; return {lerp(a[1], b[1], t), lerp(a[2], b[2], t), lerp(a[3], b[3], t)} end

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
				out.grip = lerp3(pa.grip, pb.grip, f)
				out.tossW = lerp(pa.tossW or 0, pb.tossW or 0, f)
				out.tossSpin = lerp(pa.tossSpin or 0, pb.tossSpin or 0, f)
				if pa.toss or pb.toss then out.toss = (pa.toss or pb.toss):Lerp(pb.toss or pa.toss, f) end
				return out
			end
		end
		return keys[#keys][2]
	end
end
-- add a wobble on top of a track: fn(t, pose)
local function with(base, extra) return function(t) local p = base(t); local q = {}; for k, v in pairs(p) do q[k] = (type(v) == "table") and {v[1], v[2], v[3]} or v end; extra(t, q); return q end end

--------------------------------------------------------------------
--  THE EMOTES: duration + pose(t)
--------------------------------------------------------------------
local DEF = {}
DEF.Salute = {d = 1.9, pose = track({
	{0, {}}, {0.3, {rs = {98, 0, -32}, neck = {6, 0, 0}}}, {1.4, {rs = {98, 0, -32}, neck = {6, 0, 0}}}, {1.9, {}},
})}
DEF.Bow = {d = 2.1, pose = track({
	{0, {}}, {0.45, {root = {-38, 0, 0}, neck = {-18, 0, 0}, rs = {-12, 0, 6}, ls = {62, 0, -38}}}, {1.5, {root = {-38, 0, 0}, neck = {-18, 0, 0}, rs = {-12, 0, 6}, ls = {62, 0, -38}}}, {2.1, {}},
})}
DEF.Cheer = {d = 1.9, pose = with(track({
	{0, {}}, {0.25, {rs = {172, 0, 12}, ls = {150, 0, -18}, neck = {16, 0, 0}}}, {1.5, {rs = {172, 0, 12}, ls = {150, 0, -18}, neck = {16, 0, 0}}}, {1.9, {}},
}), function(t, p) if t > 0.25 and t < 1.5 then p.rootY = math.abs(math.sin((t - 0.25) * 9)) * 0.35 end end)}
DEF.Flourish = {d = 2.1, pose = with(track({
	{0, {}}, {0.25, {rs = {72, 0, -10}}}, {1.1, {rs = {72, 0, -10}, grip = {720, 0, 0}}},
	{1.45, {rs = {100, 0, -26}, grip = {720, 0, 0}, neck = {6, 0, 0}}}, {2.1, {grip = {720, 0, 0}}},
}), function(t, p) if t > 0.25 and t < 1.1 then local w = math.sin((t - 0.25) / 0.85 * math.pi); p.rs[2] += 14 * math.sin(t * 15) * w; p.rs[1] += 10 * math.cos(t * 15) * w end end)}
DEF.Wave = {d = 1.7, pose = with(track({
	{0, {}}, {0.25, {rs = {0, 0, 150}}}, {1.35, {rs = {0, 0, 150}}}, {1.7, {}},
}), function(t, p) if t > 0.25 and t < 1.35 then p.rs[3] += 22 * math.sin((t - 0.25) * 14) end end)}
DEF.Shrug = {d = 1.5, pose = track({
	{0, {}}, {0.3, {rs = {18, 0, 34}, ls = {18, 0, -34}, neck = {0, 0, 12}, rootY = 0.1}}, {1.1, {rs = {18, 0, 34}, ls = {18, 0, -34}, neck = {0, 0, 12}, rootY = 0.1}}, {1.5, {}},
})}
DEF.Beckon = {d = 2.0, pose = with(track({
	{0, {}}, {0.25, {ls = {82, 0, 0}, rs = {28, 0, 10}, neck = {4, 0, -8}}}, {1.6, {ls = {82, 0, 0}, rs = {28, 0, 10}, neck = {4, 0, -8}}}, {2.0, {}},
}), function(t, p) if t > 0.25 and t < 1.6 then p.ls[1] += 26 * math.sin((t - 0.25) * 12) end end)}
DEF.Kneel = {d = 3.2, pose = track({
	{0, {}}, {0.45, {root = {-6, 0, 0}, rootY = -1.25, lh = {88, 0, 0}, rh = {-28, 0, 0}, rs = {62, 0, -6}, ls = {40, 0, -12}, neck = {-10, 0, 0}, grip = {-120, 0, 0}}},
	{2.6, {root = {-6, 0, 0}, rootY = -1.25, lh = {88, 0, 0}, rh = {-28, 0, 0}, rs = {62, 0, -6}, ls = {40, 0, -12}, neck = {-10, 0, 0}, grip = {-120, 0, 0}}}, {3.2, {}},
})}
DEF.Laugh = {d = 2.3, pose = with(track({
	{0, {}}, {0.25, {root = {-18, 0, 0}, neck = {22, 0, 0}, rs = {44, 0, -14}, ls = {48, 0, 18}}}, {1.9, {root = {-18, 0, 0}, neck = {22, 0, 0}, rs = {44, 0, -14}, ls = {48, 0, 18}}}, {2.3, {}},
}), function(t, p) if t > 0.25 and t < 1.9 then local s = math.sin(t * 28) * 6; p.root[1] += s; p.neck[1] += s * 0.6 end end)}
DEF.Jig = {d = 3.2, pose = with(track({
	{0, {}}, {0.2, {}}, {2.9, {}}, {3.2, {}},
}), function(t, p)
	if t > 0.2 and t < 2.9 then
		local w = math.clamp((t - 0.2) / 0.2, 0, 1) * math.clamp((2.9 - t) / 0.2, 0, 1)
		local s = math.sin(t * 13)
		p.rh = {38 * s * w, 0, 0}; p.lh = {-38 * s * w, 0, 0}
		p.rs = {(-50 * s + 30) * w, 0, 28 * w}; p.ls = {(50 * s + 30) * w, 0, -28 * w}
		p.root = {0, 14 * math.sin(t * 6.5) * w, 8 * s * w}
		p.rootY = math.abs(s) * 0.35 * w
	end
end)}
DEF.WarCry = {d = 2.3, pose = with(track({
	{0, {}}, {0.3, {rs = {158, 0, 34}, ls = {158, 0, -34}, neck = {32, 0, 0}, root = {12, 0, 0}}}, {1.8, {rs = {158, 0, 34}, ls = {158, 0, -34}, neck = {32, 0, 0}, root = {12, 0, 0}}}, {2.3, {}},
}), function(t, p) if t > 0.3 and t < 1.8 then local s = math.sin(t * 40) * 3; p.rs[3] += s; p.ls[3] -= s; p.neck[3] = s end end)}
DEF.BladeToss = {d = 2.6, pose = track({
	{0, {}}, {0.3, {rs = {128, 0, 8}}},
	{0.38, {rs = {150, 0, 8}, tossW = 1, toss = Vector3.new(1.5, 3.2, -0.6), tossSpin = 0}},
	{0.95, {rs = {60, 0, 10}, tossW = 1, toss = Vector3.new(1.5, 9.5, -0.8), tossSpin = 540}},
	{1.5, {rs = {120, 0, 8}, tossW = 1, toss = Vector3.new(1.5, 3.2, -0.6), tossSpin = 1080}},
	{1.58, {rs = {118, 0, 8}, tossW = 0, toss = Vector3.new(1.5, 3.2, -0.6), tossSpin = 1080}},
	{2.0, {rs = {98, 0, -30}, neck = {6, 0, 0}}}, {2.6, {}},
})}
DEF.Windmill = {d = 3.2, pose = with(track({
	{0, {}}, {0.3, {rs = {168, 0, 4}, ls = {20, 0, -20}, neck = {14, 0, 0}}}, {2.8, {rs = {168, 0, 4}, ls = {20, 0, -20}, neck = {14, 0, 0}}}, {3.2, {}},
}), function(t, p)
	local spin = 0
	if t > 0.3 then spin = (math.min(t, 2.8) - 0.3) ^ 1.6 * 520 end
	-- end on a whole number of turns so the blade lands where it started
	if t >= 2.8 then spin = math.floor(((2.5) ^ 1.6 * 520) / 360 + 0.5) * 360 end
	p.grip = {spin, 0, 0}
	if t > 0.3 and t < 2.8 then p.root = {0, (t - 0.3) / 2.5 * 360, 0} elseif t >= 2.8 then p.root = {0, 360, 0} end
end)}
DEF.Champion = {d = 3.4, pose = track({
	{0, {}}, {0.45, {rs = {40, 0, -24}, ls = {42, 0, 26}, grip = {-130, 0, 0}, neck = {10, 0, 0}, root = {4, 0, 0}}},
	{2.9, {rs = {40, 0, -24}, ls = {42, 0, 26}, grip = {-130, 0, 0}, neck = {10, 0, 0}, root = {4, 0, 0}}}, {3.4, {}},
})}

Emotes.DURATION = {}
for id, d in pairs(DEF) do Emotes.DURATION[id] = d.d end
function Emotes.has(id) return DEF[id] ~= nil end

function Emotes.sample(id, t)
	local d = DEF[id]
	if not d then return nil end
	return d.pose(math.clamp(t, 0, d.d))
end

--------------------------------------------------------------------
--  PLAYING ON CHARACTERS
--------------------------------------------------------------------
local active = setmetatable({}, {__mode = "k"})   -- character → {id, t0, gripC0}

local function rotAbout(c0, deg)
	if not deg or (deg[1] == 0 and deg[2] == 0 and deg[3] == 0) then return c0 end
	return CFrame.new(c0.Position) * CFrame.Angles(rad(deg[1]), rad(deg[2]), rad(deg[3])) * c0.Rotation
end

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

function Emotes.play(char, id, startedAt)
	if not (char and DEF[id]) then return false end
	Emotes.stop(char)
	active[char] = {id = id, t0 = os.clock() - math.max(0, (startedAt and (workspace:GetServerTimeNow() - startedAt)) or 0)}
	return true
end

-- RigPose.apply hands its joint targets here every frame
function Emotes.modify(char, targets)
	local rec = active[char]
	if not rec then return nil end
	local t = os.clock() - rec.t0
	local d = DEF[rec.id]
	if t >= d.d then Emotes.stop(char); return nil end
	local p = d.pose(t)
	local out = {}
	for name, cf in pairs(targets) do out[name] = cf end
	for k, joint in pairs(JOINT) do
		if out[joint] then out[joint] = rotAbout(out[joint], p[k]) end
	end
	if out.RootJoint and (p.rootY or 0) ~= 0 then out.RootJoint = CFrame.new(0, p.rootY, 0) * out.RootJoint end
	return out
end

-- every frame, after the Animator: the emoting joints drop the animation, and
-- the weapon spins / flies
local JOINT_PARENT = {["Right Shoulder"] = "Torso", ["Left Shoulder"] = "Torso", ["Right Hip"] = "Torso", ["Left Hip"] = "Torso", Neck = "Torso", RootJoint = "HumanoidRootPart"}
RunService.RenderStepped:Connect(function()
	for char, rec in pairs(active) do
		if not char.Parent then active[char] = nil; continue end
		local d = DEF[rec.id]
		local t = os.clock() - rec.t0
		if t >= d.d then Emotes.stop(char); continue end
		for joint, parentName in pairs(JOINT_PARENT) do
			local parent = char:FindFirstChild(parentName)
			local m = parent and parent:FindFirstChild(joint)
			if m and m:IsA("Motor6D") then m.Transform = CFrame.identity end
		end
		local p = d.pose(t)
		local arm = char:FindFirstChild("Right Arm")
		local grip = gripOf(arm)
		if grip and grip:IsA("JointInstance") then
			if rec.gripOf ~= grip then rec.gripOf = grip; rec.gripC0 = grip.C0 end
			if grip:IsA("Motor6D") then grip.Transform = CFrame.identity end
			local c0 = rec.gripC0 * CFrame.Angles(rad(p.grip and p.grip[1] or 0), rad(p.grip and p.grip[2] or 0), rad(p.grip and p.grip[3] or 0))
			if (p.tossW or 0) > 0 and p.toss then
				local torso = char:FindFirstChild("Torso")
				if torso then
					local want = torso.CFrame * CFrame.new(p.toss) * CFrame.Angles(rad(p.tossSpin or 0), 0, 0) * CFrame.Angles(math.pi / 2, 0, 0)
					local free = arm.CFrame:Inverse() * want * grip.C1
					c0 = c0:Lerp(free, math.clamp(p.tossW, 0, 1))
				end
			end
			grip.C0 = c0
		end
	end
end)

--------------------------------------------------------------------
--  PREVIEWS (anchored rigs in a ViewportFrame)
--------------------------------------------------------------------
-- origins = {[Motor6D] = original C0}; afterwards call the menu's settle()
function Emotes.poseRig(rig, id, t, origins)
	local p = Emotes.sample(id, t)
	if not p then return end
	for k, joint in pairs(JOINT) do
		local parent = rig:FindFirstChild(JOINT_PARENT[joint])
		local m = parent and parent:FindFirstChild(joint)
		if m and m:IsA("Motor6D") then
			origins[m] = origins[m] or m.C0
			local c0 = rotAbout(origins[m], p[k])
			if joint == "RootJoint" and (p.rootY or 0) ~= 0 then c0 = CFrame.new(0, p.rootY, 0) * c0 end
			m.C0 = c0
		end
	end
	-- the preview weapon (Dresser.attachWeapon welds carry their grip offset)
	local wp = rig:FindFirstChild("WeaponPreview")
	if wp then
		local spin = CFrame.Angles(rad(p.grip and p.grip[1] or 0), rad(p.grip and p.grip[2] or 0), rad(p.grip and p.grip[3] or 0))
		for _, w in ipairs(wp:GetDescendants()) do
			if w:IsA("Weld") then
				local base, off = w:GetAttribute("GripBase"), w:GetAttribute("GripOffset")
				if typeof(base) == "CFrame" and typeof(off) == "CFrame" then w.C0 = base * spin * off end
			end
		end
	end
end

return Emotes
