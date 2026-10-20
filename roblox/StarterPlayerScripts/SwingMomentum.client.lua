--[[ SWING MOMENTUM (client) — a swing carries the body. Every fighter near you (other players,
     you, the bots) is watched while they fight (Acting: a swing, a kick): the tip of their blade,
     measured in their own frame so walking and turning don't count, says where the swing is
     going, and the body goes with it. Laid over the animation (the joints' Transform after the
     Animator: ReplicatedStorage ▸ JointLayer), so the clips themselves are untouched:

       THE TWIST   the torso turns with the blade: it coils as the windup draws the blade back,
                   throws round into the swing, carries on past its end and settles back with a
                   little overshoot (a spring: the swing's momentum)
       THE LEAN    an overhead or a thrust pitches the body into it; an underhand lifts it a little
       THE REST    the hips turn most of the way back (the feet stay put); the sword arm keeps the
                   blade where the clip has it (its path, and so what it hits, are the same); the
                   head keeps its eyes on the foe (yours stays dead level in first person); the
                   free arm swings on a little further (the counterweight), unless it holds a
                   shield or the other end of the hilt

     Within 90 studs (60 on a phone). Nothing here is sent to the server.
     Tuning: the constants below. Studio tests: the local player's attribute SwingMomentumOff
     turns it off, SwingMomentumDebug writes each fighter's twist and lean (degrees) onto it as
     SM_Yaw / SM_Lean. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local JointLayer = require(ReplicatedStorage:WaitForChild("JointLayer"))

local PHONE = Device.kind() == "phone"
local NEAR = PHONE and 60 or 90

local K_YAW = 0.08             -- radians of twist per rad/s the blade turns round the body
local YAW_MAX = math.rad(24)
local K_DROP = 0.011           -- forward lean per stud/s the tip falls (an overhead)
local K_THRUST = 0.009         -- …and per stud/s it drives forward (a thrust)
local K_RISE = 0.004           -- the lean back per stud/s it climbs (an underhand)
local LEAN_MAX, LEAN_BACK = math.rad(13), math.rad(5)
local W, ZETA = 11, 0.5        -- the spring: how quick the body answers, how far it overshoots
local HIPS_BACK = 0.75         -- how much of the twist the hips turn back (the feet stay put)
local NECK_BACK = 0.6          -- how much the head turns back to the foe (yours in first person: all)
local OFFHAND = 0.25           -- the free arm swings on this much further than the body
local MIN_TURN = 1.6           -- rad/s: slower than this the blade isn't swinging (idle, walk sway)

local me = Players.LocalPlayer
local STUDIO = RunService:IsStudio()
local states = {}   -- [model] = state

--------------------------------------------------------------------
--  WHO: everyone with a body and a blade near the camera
--------------------------------------------------------------------
local function bladeOf(model)
	local tool = model:FindFirstChildOfClass("Tool")
	if not tool then return nil, nil end
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Hitbox" then return d, tool end
	end
	return nil, tool
end

local function newState(model)
	local root, torso = model:FindFirstChild("HumanoidRootPart"), model:FindFirstChild("Torso")
	local function m(parent, name)
		local j = parent and parent:FindFirstChild(name)
		return (j and j:IsA("Motor6D")) and j or nil
	end
	local st = {
		model = model, root = root, torso = torso, hum = model:FindFirstChildOfClass("Humanoid"),
		rootJoint = m(root, "RootJoint"), neck = m(torso, "Neck"),
		rs = m(torso, "Right Shoulder"), ls = m(torso, "Left Shoulder"),
		rh = m(torso, "Right Hip"), lh = m(torso, "Left Hip"),
		yaw = 0, yawV = 0, lean = 0, leanV = 0, checkAt = 0,
	}
	if not (root and torso and st.hum and st.rootJoint and st.rs) then return nil end
	return st
end

local function refreshGear(st, now)
	if now < st.checkAt then return end
	st.checkAt = now + 0.5
	local hb, tool = bladeOf(st.model)
	st.hitbox = hb
	local w = tool and Catalog.WEAPON and Catalog.WEAPON[tool.Name]
	st.twoH = w ~= nil and (w.family == "TwoHanded" or w.family == "Polearm")
	st.shield = st.model:FindFirstChild("ShieldModel", true) ~= nil or st.model:GetAttribute("ShieldId") ~= nil
end

-- the blade's tip: the end of its long axis farthest from the torso
local function tipOf(st)
	local hb = st.hitbox
	if not (hb and hb.Parent) then return nil end
	local s, cf = hb.Size, hb.CFrame
	local axis, h
	if s.Y >= s.X and s.Y >= s.Z then axis, h = cf.UpVector, s.Y / 2
	elseif s.X >= s.Z then axis, h = cf.RightVector, s.X / 2
	else axis, h = cf.LookVector, s.Z / 2 end
	local a, b = cf.Position + axis * h, cf.Position - axis * h
	local t = st.torso.Position
	return ((a - t).Magnitude >= (b - t).Magnitude) and a or b
end

local acc = 0
local function gather(now)
	local cam = workspace.CurrentCamera
	local eye = cam and cam.CFrame.Position
	if not eye then return end
	local seen = {}
	local function consider(model)
		if not (model and model.Parent) then return end
		local root = model:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - eye).Magnitude > NEAR then return end
		seen[model] = true
		if not states[model] then states[model] = newState(model) end
	end
	for _, p in ipairs(Players:GetPlayers()) do consider(p.Character) end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do if m:IsA("Model") then consider(m) end end end
	for model in pairs(states) do if not seen[model] then states[model] = nil end end
end

--------------------------------------------------------------------
--  THE LAYER
--------------------------------------------------------------------
-- turn a joint by a world rotation `q` (about its own pivot, or about `pivot` given in the
-- joint's frame), laid on its Transform
local function lay(motor, frame, q, pivot)
	if not (motor and frame) then return end
	local jr = (frame.CFrame * motor.C0).Rotation
	local r = jr:Inverse() * q * jr
	if pivot then r = CFrame.new(pivot) * r * CFrame.new(-pivot) end
	JointLayer.turn(motor, r)
end

local function spring(x, v, target, dt)
	local steps = math.max(1, math.ceil(dt / (1 / 120)))
	local h = dt / steps
	for _ = 1, steps do
		v += (W * W * (target - x) - 2 * ZETA * W * v) * h
		x += v * h
	end
	return x, v
end

local function firstPerson(st)
	if st.model ~= (me and me.Character) then return false end
	local cam, head = workspace.CurrentCamera, st.model:FindFirstChild("Head")
	return cam ~= nil and head ~= nil and (cam.CFrame.Position - head.Position).Magnitude < 1.6
end

local function step(st, dt, now)
	local model = st.model
	if not (st.root.Parent and st.torso.Parent) then states[model] = nil; return end
	refreshGear(st, now)
	local alive = st.hum.Health > 0 and not st.hum.PlatformStand and not model:GetAttribute("Ragdolled")
	local acting = alive and model:GetAttribute("Acting") == true
	-- where the blade's going, in the fighter's own frame
	local yawT, leanT = 0, 0
	local tip = acting and tipOf(st)
	if tip then
		local L = st.root.CFrame:PointToObjectSpace(tip)
		local P = st.prevL
		if P then
			local d = math.max(dt, 1 / 240)
			local a, pa = math.atan2(L.X, -L.Z), math.atan2(P.X, -P.Z)
			local da = a - pa
			if da > math.pi then da -= 2 * math.pi elseif da < -math.pi then da += 2 * math.pi end
			local rh = math.sqrt(L.X * L.X + L.Z * L.Z)
			local w = math.clamp(da / d, -25, 25) * math.clamp((rh - 0.6) / 1.4, 0, 1)
			if math.abs(w) > MIN_TURN then yawT = math.clamp(-K_YAW * w, -YAW_MAX, YAW_MAX) end
			local vy = math.clamp((L.Y - P.Y) / d, -60, 60)
			local vf = math.clamp(-(L.Z - P.Z) / d, -60, 60)
			leanT = math.clamp(K_DROP * math.max(0, -vy) + K_THRUST * math.max(0, vf) - K_RISE * math.max(0, vy), -LEAN_BACK, LEAN_MAX)
		end
		st.prevL = L
	else
		st.prevL = nil
	end
	st.yaw, st.yawV = spring(st.yaw, st.yawV, alive and yawT or 0, dt)
	st.lean, st.leanV = spring(st.lean, st.leanV, alive and leanT or 0, dt)
	if STUDIO and me:GetAttribute("SwingMomentumDebug") then
		model:SetAttribute("SM_Yaw", math.deg(st.yaw))
		model:SetAttribute("SM_Lean", math.deg(st.lean))
	end
	if not alive or (math.abs(st.yaw) < 0.002 and math.abs(st.lean) < 0.002 and math.abs(st.yawV) < 0.02 and math.abs(st.leanV) < 0.02) then return end

	local fp = firstPerson(st)
	local yaw, lean = st.yaw, st.lean * (fp and 0.4 or 1)
	local up, right = st.root.CFrame.UpVector, st.root.CFrame.RightVector
	local Q = CFrame.fromAxisAngle(up, yaw) * CFrame.fromAxisAngle(right, -lean)
	local Qinv = CFrame.fromAxisAngle(right, lean) * CFrame.fromAxisAngle(up, -yaw)
	-- the torso, about the middle of its hips (the waist)
	local waist = st.rootJoint.C0:PointToObjectSpace(Vector3.new(0, -1, 0))
	lay(st.rootJoint, st.root, Q, waist)
	-- the legs turn most of the way back and stand upright again
	local legBack = CFrame.fromAxisAngle(right, lean) * CFrame.fromAxisAngle(up, -yaw * HIPS_BACK)
	lay(st.rh, st.torso, legBack)
	lay(st.lh, st.torso, legBack)
	-- the sword arm keeps the blade where it was (both arms, on a two-handed hilt)
	lay(st.rs, st.torso, Qinv)
	if st.twoH then
		lay(st.ls, st.torso, Qinv)
	elseif not st.shield then
		lay(st.ls, st.torso, CFrame.fromAxisAngle(up, yaw * OFFHAND))
	end
	-- the head stays on the foe
	local n = fp and 1 or NECK_BACK
	lay(st.neck, st.torso, CFrame.fromAxisAngle(right, lean * n) * CFrame.fromAxisAngle(up, -yaw * n))
end

JointLayer.bind("SwingMomentum", function(dt)
	if _G.SwingMomentumOff or (STUDIO and me:GetAttribute("SwingMomentumOff")) then return end
	local now = os.clock()
	acc += dt
	if acc > 0.4 then acc = 0; gather(now) end
	for _, st in pairs(states) do
		local ok, err = pcall(step, st, dt, now)
		if not ok then states[st.model] = nil; warn("[SwingMomentum]", err) end
	end
end)
gather(os.clock())
