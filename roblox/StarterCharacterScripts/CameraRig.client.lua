--[[ R6 UNIFIED FIRST/THIRD PERSON CAMERA + aim rig + immersion + turn cap.
     Owns the camera in BOTH views. Scroll in/out = FP/TP. Shift-lock in TP.
     Turn cap reads the LOCAL cap timer (set by our own client on our own
     clock) so it works in live servers, not just Studio. FP camera follows
     the head/torso rig via forward kinematics (no physics-step lag), so the
     crisp clunk stays crisp AND the camera still tracks neck/torso pose.
     FP gets its own clunk boost (translation + a small rotational kick per
     step) so it reads heavier than TP without changing TP's tuned feel.

     Inputs published by other systems (all optional, all on the character):
       ClunkMult       (server, gear)  footstep weight multiplier, 1 = base
       LocalTurnCapUntil (client, weapon) os.clock() deadline for the turn cap
       LocalKickAt / LocalKickRise (client, weapon) procedural leg kick ]]

local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Players    = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local GameSettings   = UserSettings():GetService("UserGameSettings")

local player    = Players.LocalPlayer
local character = script.Parent
local Camera    = workspace.CurrentCamera

local Humanoid = character:WaitForChild("Humanoid")
if Humanoid.RigType ~= Enum.HumanoidRigType.R6 then return end

local Head          = character:WaitForChild("Head")
local Torso         = character:WaitForChild("Torso")
local HRP           = character:WaitForChild("HumanoidRootPart")
local LeftArm       = character:WaitForChild("Left Arm")
local RightArm      = character:WaitForChild("Right Arm")
local Neck          = Torso:WaitForChild("Neck")
local RootJoint     = HRP:WaitForChild("RootJoint")
local LeftHip       = Torso:WaitForChild("Left Hip")
local RightHip      = Torso:WaitForChild("Right Hip")
local LeftShoulder  = Torso:WaitForChild("Left Shoulder")
local RightShoulder = Torso:WaitForChild("Right Shoulder")

local NeckOrigin = Neck.C0
local RootOrigin = RootJoint.C0
local LHipOrigin = LeftHip.C0
local RHipOrigin = RightHip.C0
local LShOrigin  = LeftShoulder.C0
local RShOrigin  = RightShoulder.C0

-- C1 values are never modified by this script, so they're stable to read
-- back for forward-kinematics (unlike Part.CFrame, which lags a frame)
local RootC1 = RootJoint.C1
local NeckC1 = Neck.C1

--------------------------------------------------------------------
--  SETTINGS
--------------------------------------------------------------------
local SENSITIVITY = 0.003   -- multiplied by the player's Roblox mouse-sensitivity setting
local PITCH_LIMIT = math.rad(75)

local TURN_CAP_DPS = 400
local TURN_DEBUG   = true

-- framing
local ANCHOR_UP   = 1.5
local EYE_FWD     = 0.6
local EYE_UP      = 0.0
local FP_FOV      = 100
local TP_FOV      = 70
local FOV_BOOST   = 1
local CAM_SMOOTH  = 100

-- third-person / zoom
local TP_MAX_DIST = 14
local DEFAULT_DIST= 10
local FP_ENTER    = 0.75
local ZOOM_STEP   = 1.5
local ZOOM_SMOOTH = 14
local SHOULDER_X  = 1
local SHOULDER_Y  = 0.0

local ACCESSORY_TRANSPARENCY = 1

-- aim rig
local PITCH_DIR   = -1
local NECK_PITCH  = 0.7
local TORSO_PITCH = 0.5
local TORSO_PIVOT = 1.0
local ARM_PITCH   = 0.7
local RIGHT_ARM_DIR = 1
local LEFT_ARM_DIR  = -1
local LEAN_DIR        = 1
local MOMENTUM_FACTOR = 0.008
local BEND_SPEED      = 16

-- kick: procedural pose layered on the hip joint, so it never fights weapon idles.
-- Rise time comes from the server's KICK_WINDUP so the leg peaks on the hit frame.
local KICK_ANGLE    = math.rad(80)  -- how far the right leg swings forward
local KICK_DIR      = 1             -- flip to -1 if the leg swings backward
local KICK_FALL     = 0.30          -- retract time after the peak
local KICK_SNAP     = 40            -- joint lerp speed during the kick (BEND_SPEED is too mushy)
local KICK_LEAN     = 0.12          -- torso lean-back at full extension
local KICK_LEAN_DIR = -1            -- flip if the torso leans forward instead of back
local KICK_CAM      = 0.04          -- FP head bump at kick start

-- walk bob (stepped/clunky, not a smooth wave) — scales with Humanoid.WalkSpeed:
-- slower than BASE_WALKSPEED (e.g. heavy armor) = heavier, slower clunks;
-- faster = lighter, quicker ones.
local BOB_CAM_X, BOB_CAM_Y, BOB_TORSO = 0.20, 0.34, 0.16
local STEP_RATE_HZ   = 2.25   -- footsteps/sec at BASE_WALKSPEED, full stride
local BASE_WALKSPEED = MovementConfig.BASE_SPEED
local HEAVINESS_MIN, HEAVINESS_MAX = 0.6, 1.5
local BOB_SMOOTH     = 8
local BOB_DIR_FWD, BOB_DIR_SIDE = 0.05, 0.10
local STEP_STIFF, STEP_DAMP = 420, 24  -- stiff+damped = snap-and-settle "clunk"

-- FP-only clunk boost: FP fills the whole screen so the same offsets read
-- weaker than in TP, so amplify translation there, plus a small extra
-- rotational "head kick" per step. TP is untouched by these.
local FP_CLUNK_MULT = 1.8
local FP_ROLL_MULT  = 1.6
local FP_KICK_AMT   = 0.05   -- radians of extra pitch dip per step

-- immersion springs
local ROLL_TURN, ROLL_STRAFE, ROLL_MAX = 0.06, 0.05, 0.10
local LAND_FORCE   = 0.11
local SWAY_AMOUNT, SWAY_MAX = 0.035, 0.12
local BREATHE_AMOUNT, BREATHE_HZ = 0.03, 1.1
local MOMENTUM_LEAN = 0.05
local SPRING_STIFF, SPRING_DAMP = 120, 16

-- global clunk baseline — this IS your tuned "0.5" feel.
-- ClunkMult (character attribute, set by armor/gear) multiplies on top of
-- it at runtime; 1 = base/no-armor, reproducing this exact value.
local BASE_CLUNK = 0.5
--------------------------------------------------------------------

local function newSpring() return {p=0, v=0} end
local function springC(s, target, dt, stiff, damp)
	local f = stiff*(target - s.p) - damp*s.v
	s.v = s.v + f*dt; s.p = s.p + s.v*dt
	return s.p
end
local function spring(s, target, dt) return springC(s, target, dt, SPRING_STIFF, SPRING_DAMP) end

local sRoll, sLand, sSwayX, sSwayY, sLean, sStepY, sStepX, sKick =
	newSpring(), newSpring(), newSpring(), newSpring(), newSpring(), newSpring(), newSpring(), newSpring()

local rot = Vector2.new(0, select(2, HRP.CFrame:ToOrientation()))
local camDist       = DEFAULT_DIST
local camDistTarget = DEFAULT_DIST
local bobAmt = 0
local stepPhase, stepSide = 0, 1
local lastSpeed, lastVY = 0, 0
local mouseDX, mouseDY = 0, 0
local roll, leanPitch = 0, 0
local lastInFP = nil
local eyePos = nil
local lastKickAt = 0
local wasCapped = false

local camRay = RaycastParams.new()
camRay.FilterType = Enum.RaycastFilterType.Exclude

player.CameraMode = Enum.CameraMode.Classic

--------------------------------------------------------------------
--  VISIBILITY
--------------------------------------------------------------------
local function applyVisibility(d, inFP)
	if d:IsA("BasePart") then
		if d.Name == "Head" then
			-- handled per-frame below
		elseif d.Parent:IsA("Accessory") then
			d.LocalTransparencyModifier = inFP and ACCESSORY_TRANSPARENCY or 0
			d.CastShadow = true
		else
			d.LocalTransparencyModifier = 0
		end
	elseif d:IsA("Decal") and d.Parent and d.Parent.Name == "Head" then
		d.LocalTransparencyModifier = inFP and 1 or 0
	end
end

local function setBodyForFP(inFP)
	for _, d in ipairs(character:GetDescendants()) do applyVisibility(d, inFP) end
end

-- gear equipped after entering FP (hats, tools) gets the same treatment
character.DescendantAdded:Connect(function(d)
	if lastInFP == nil then return end
	task.defer(function()
		if d.Parent then applyVisibility(d, lastInFP) end
	end)
end)

--------------------------------------------------------------------
--  INPUT
--------------------------------------------------------------------
UIS.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		mouseDX = mouseDX + input.Delta.X
		mouseDY = mouseDY + input.Delta.Y
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		camDistTarget = math.clamp(camDistTarget - input.Position.Z * ZOOM_STEP, 0, TP_MAX_DIST)
	end
end)

--------------------------------------------------------------------
--  MAIN
--------------------------------------------------------------------
local CAM = Enum.RenderPriority.Camera.Value
pcall(function() RunService:UnbindFromRenderStep("FPRig") end)

RunService:BindToRenderStep("FPRig", CAM, function(dt)
	if not (Neck.Parent and RootJoint.Parent) then return end
	local a   = math.clamp(dt*BEND_SPEED, 0, 1)
	local dtc = math.min(dt, 1/30)
	local now = os.clock()

	-- typing in chat / a TextBox: release the mouse and ignore look input
	local typing = UIS:GetFocusedTextBox() ~= nil
	Camera.CameraType   = Enum.CameraType.Scriptable
	UIS.MouseBehavior   = typing and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
	Humanoid.AutoRotate = false

	-- turn cap: LOCAL timer only. The server's TurnCapUntil is on the
	-- server's os.clock(), which is a different clock — never compare it here.
	local capped = now < (character:GetAttribute("LocalTurnCapUntil") or 0)
	if TURN_DEBUG and capped and not wasCapped then print("[TurnCap] active") end
	wasCapped = capped

	local rawDX, rawDY = mouseDX, mouseDY
	mouseDX, mouseDY = 0, 0
	if typing then rawDX, rawDY = 0, 0 end
	local sens   = SENSITIVITY * GameSettings.MouseSensitivity
	local dYaw   = -rawDX * sens
	local dPitch = -rawDY * sens
	if capped then
		local maxStep = math.rad(TURN_CAP_DPS) * dt
		local mag = math.sqrt(dYaw*dYaw + dPitch*dPitch)
		if mag > maxStep and mag > 1e-6 then
			local s = maxStep / mag
			dYaw, dPitch = dYaw*s, dPitch*s
		end
	end
	rot = Vector2.new(math.clamp(rot.X + dPitch, -PITCH_LIMIT, PITCH_LIMIT), rot.Y + dYaw)
	local appliedDX = (sens ~= 0) and (-dYaw / sens) or 0
	local appliedDY = (sens ~= 0) and (-dPitch / sens) or 0

	-- zoom + mode
	camDist = camDist + (camDistTarget - camDist) * math.clamp(dt*ZOOM_SMOOTH, 0, 1)
	local inFP = camDist <= FP_ENTER

	-- body faces camera yaw (capped via rot.Y) — unless physics owns the body
	-- (knocked down / seated), in which case forcing it upright every frame
	-- would fight the ragdoll or the seat
	local bodyFree = Humanoid.PlatformStand or Humanoid.Sit
	if not bodyFree then
		HRP.CFrame = CFrame.new(HRP.Position) * CFrame.Angles(0, rot.Y, 0)
	end

	local p = rot.X * PITCH_DIR

	-- movement
	local flatVel = HRP.AssemblyLinearVelocity * Vector3.new(1,0,1)
	local speed   = flatVel.Magnitude
	local walkFrac = math.clamp(speed / math.max(Humanoid.WalkSpeed, 1), 0, 1)
	local vy = HRP.AssemblyLinearVelocity.Y
	local moveDir = HRP.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
	local relVel  = HRP.CFrame:VectorToObjectSpace(flatVel)
	local grounded = Humanoid.FloorMaterial ~= Enum.Material.Air

	-- bob: smooth walkFrac so intensity fades in/out, but the motion itself
	-- is a discrete per-step impulse, not a continuous wave. Cadence and
	-- weight both scale off actual WalkSpeed (heavy armor = slower WalkSpeed
	-- = longer waits between heavier clunks), PLUS the ClunkMult attribute
	-- for direct per-gear control independent of the speed change.
	bobAmt = bobAmt + (walkFrac - bobAmt) * math.clamp(dt*BOB_SMOOTH, 0, 1)

	local speedRatio = math.max(Humanoid.WalkSpeed, 0.01) / BASE_WALKSPEED
	local heaviness  = math.clamp(1 / speedRatio, HEAVINESS_MIN, HEAVINESS_MAX)
	local clunkMult  = BASE_CLUNK * (character:GetAttribute("ClunkMult") or 1)

	local stepped = false
	if grounded and walkFrac > 0.05 then
		stepPhase = stepPhase + dt * STEP_RATE_HZ * walkFrac * speedRatio
		if stepPhase >= 1 then
			stepPhase = stepPhase % 1
			stepSide = -stepSide
			stepped = true
		end
	else
		stepPhase = 0
	end

	if stepped then
		sStepY.v = sStepY.v - BOB_CAM_Y * 26 * bobAmt * heaviness * clunkMult
		sStepX.v = sStepX.v + stepSide * BOB_CAM_X * 20 * bobAmt * heaviness * clunkMult
		sKick.v  = sKick.v  - FP_KICK_AMT * 26 * bobAmt * heaviness * clunkMult
	end

	local bobY = springC(sStepY, 0, dtc, STEP_STIFF, STEP_DAMP)
	local bobX = springC(sStepX, 0, dtc, STEP_STIFF, STEP_DAMP)
	local kick = springC(sKick,  0, dtc, STEP_STIFF, STEP_DAMP)
	local torsoBobY = math.abs(bobY) * (BOB_TORSO / math.max(BOB_CAM_Y, 0.001))
	local dirFwd  = -moveDir.Z * BOB_DIR_FWD  * bobAmt * math.abs(bobY)
	local dirSide =  moveDir.X * BOB_DIR_SIDE * bobAmt * math.abs(bobY)

	-- immersion springs
	local turnRate = math.clamp(-appliedDX * 0.9, -3, 3)
	local rollTarget = math.clamp(turnRate*ROLL_TURN + moveDir.X*ROLL_STRAFE, -ROLL_MAX, ROLL_MAX)
	roll = spring(sRoll, rollTarget, dtc)

	if grounded and lastVY < -5 then sLand.v = sLand.v - (-lastVY)*LAND_FORCE end
	local landDip = spring(sLand, 0, dtc)

	local accel = (speed - lastSpeed) / math.max(dt, 1e-3)
	leanPitch = spring(sLean, math.clamp(accel*MOMENTUM_LEAN*0.02, -0.15, 0.15), dtc)

	local swayX = math.clamp(spring(sSwayX, -appliedDX*SWAY_AMOUNT*0.02, dtc), -SWAY_MAX, SWAY_MAX)
	local swayY = math.clamp(spring(sSwayY, -appliedDY*SWAY_AMOUNT*0.02, dtc), -SWAY_MAX, SWAY_MAX)

	local idle = 1 - walkFrac
	local breatheX = math.sin(now*BREATHE_HZ) * BREATHE_AMOUNT * idle
	local breatheY = math.sin(now*BREATHE_HZ*2) * BREATHE_AMOUNT * 0.5 * idle

	-- KICK pose: snaps out over the server windup, eases back over KICK_FALL
	local kickAt   = character:GetAttribute("LocalKickAt") or 0
	local kickRise = character:GetAttribute("LocalKickRise") or 0.22
	local kickT    = now - kickAt
	local kickPose = 0
	if kickAt > 0 and kickT < kickRise + KICK_FALL then
		if kickT < kickRise then
			local q = kickT / kickRise
			kickPose = 1 - (1 - q)^3
		else
			local q = (kickT - kickRise) / KICK_FALL
			kickPose = (1 - q)^2
		end
	end
	if kickAt ~= lastKickAt then
		lastKickAt = kickAt
		sKick.v = sKick.v - KICK_CAM * 26
	end
	local kickLean = CFrame.Angles(KICK_LEAN * KICK_LEAN_DIR * kickPose, 0, 0)

	-- HEAD
	Neck.C0 = Neck.C0:Lerp(NeckOrigin * CFrame.Angles(p*NECK_PITCH, 0, 0), a)

	-- TORSO aim + walk lean + kick lean + bob
	local x = moveDir.X * math.abs(relVel.X) * MOMENTUM_FACTOR
	local z = moveDir.Z * math.abs(relVel.Z) * MOMENTUM_FACTOR
	local walkLean = CFrame.Angles(z*LEAN_DIR, 0, x*LEAN_DIR)
	local aim = CFrame.new(0,0,-TORSO_PIVOT) * CFrame.Angles(p*TORSO_PITCH,0,0) * CFrame.new(0,0,TORSO_PIVOT)
	local rootBend = RootOrigin * aim * walkLean * kickLean
	RootJoint.C0 = RootJoint.C0:Lerp(CFrame.new(0, torsoBobY, 0) * rootBend, a)

	-- LEGS stay straight/planted; right leg swings for the kick
	local counter = RootOrigin * rootBend:Inverse()
	local legA = kickPose > 0 and math.clamp(dt*KICK_SNAP, 0, 1) or a
	LeftHip.C0  = LeftHip.C0:Lerp(counter * LHipOrigin, legA)
	RightHip.C0 = RightHip.C0:Lerp(counter * RHipOrigin * CFrame.Angles(0, 0, KICK_DIR * KICK_ANGLE * kickPose), legA)

	-- ARMS aim + sway
	local armAng = character:FindFirstChildOfClass("Tool") and (rot.X*ARM_PITCH) or 0
	local swayCF = CFrame.Angles(swayY, swayX, 0)
	RightShoulder.C0 = RightShoulder.C0:Lerp(swayCF * RShOrigin * CFrame.Angles(0,0,armAng*RIGHT_ARM_DIR), a)
	LeftShoulder.C0  = LeftShoulder.C0:Lerp( swayCF * LShOrigin * CFrame.Angles(0,0,armAng*LEFT_ARM_DIR),  a)

	-- CAMERA
	local vOff = bobY + breatheY + landDip
	local hOff = bobX + breatheX + dirSide
	local zOff = dirFwd

	if inFP then
		Camera.FieldOfView = FP_FOV + FOV_BOOST*walkFrac
		-- forward-kinematics the head's world position from the C0s we just
		-- set this frame — same "follows the head" feel as reading
		-- Head.Position, but synchronous (no one-frame joint-solver lag)
		local torsoCF = HRP.CFrame * RootJoint.C0 * RootC1:Inverse()
		local headCF  = torsoCF * Neck.C0 * NeckC1:Inverse()
		local target  = headCF.Position
		eyePos = eyePos and eyePos:Lerp(target, math.clamp(dt*CAM_SMOOTH, 0, 1)) or target
		Camera.CFrame = CFrame.new(eyePos)
			* CFrame.Angles(0, rot.Y, 0)
			* CFrame.Angles(rot.X + leanPitch + kick, 0, roll*FP_ROLL_MULT)
			* CFrame.new(hOff*FP_CLUNK_MULT, EYE_UP + vOff*FP_CLUNK_MULT, -EYE_FWD + zOff*FP_CLUNK_MULT)
	else
		eyePos = nil
		Camera.FieldOfView = TP_FOV + FOV_BOOST*walkFrac
		local focus = HRP.Position + Vector3.new(0, ANCHOR_UP, 0)
		camRay.FilterDescendantsInstances = {character}
		local orbit = CFrame.new(focus) * CFrame.Angles(0, rot.Y, 0) * CFrame.Angles(rot.X, 0, 0)
		local back = orbit.LookVector * -1
		local res = workspace:Raycast(focus, back * camDist, camRay)
		local distNow = camDist
		if res then distNow = math.max(0.6, (res.Position - focus).Magnitude - 0.4) end
		Camera.CFrame = CFrame.new(focus)
			* CFrame.Angles(0, rot.Y, 0)
			* CFrame.Angles(rot.X + leanPitch, 0, roll)
			* CFrame.new(SHOULDER_X + hOff, SHOULDER_Y + vOff, distNow + zOff)
	end
	Humanoid.CameraOffset = Vector3.zero

	-- visibility
	if inFP ~= lastInFP then setBodyForFP(inFP); lastInFP = inFP end
	if inFP then
		Head.LocalTransparencyModifier     = 1
		LeftArm.LocalTransparencyModifier  = 0
		RightArm.LocalTransparencyModifier = 0
	else
		Head.LocalTransparencyModifier = 0
	end

	lastSpeed = speed
	lastVY = grounded and 0 or vy
end)

local function stop()
	pcall(function() RunService:UnbindFromRenderStep("FPRig") end)
	Camera.CameraType    = Enum.CameraType.Custom
	Humanoid.AutoRotate  = true
	UIS.MouseBehavior    = Enum.MouseBehavior.Default
	Head.LocalTransparencyModifier = 0
	Humanoid.CameraOffset = Vector3.zero
end
Humanoid.Died:Connect(stop)
script.Destroying:Connect(stop)
