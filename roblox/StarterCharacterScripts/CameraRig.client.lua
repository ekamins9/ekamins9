--[[ R6 UNIFIED FIRST/THIRD PERSON CAMERA + aim rig + immersion + turn cap.
     Owns the camera in BOTH views. Scroll in/out = FP/TP. Shift-lock in TP.
     Turn cap reads the LOCAL cap timer (set by our own client on our own
     clock) so it works in live servers, not just Studio. FP camera follows
     the head/torso rig via forward kinematics (no physics-step lag), so the
     crisp clunk stays crisp AND the camera still tracks neck/torso pose.
     FP gets its own clunk boost (translation + a small rotational kick per
     step) so it reads heavier than TP without changing TP's tuned feel.

     The body pose itself (aim bend, lean, bob, kick, crouch, sway) is
     computed by ReplicatedStorage.RigPose and the INPUTS are sent ~20×/s
     through PoseRelay so every other client renders the same pose on us —
     that is what makes a crouch or a lean-back a real dodge.

     Inputs published by other systems (all optional, all on the character):
       ClunkMult_<Source>  (server: weapon, armor…) footstep weight, composed
                           by ReplicatedStorage.Modifiers, 1 = base
       LocalTurnCapUntil   (client, weapon) os.clock() deadline for the turn cap
       LocalKickAt / LocalKickRise (client, weapon) procedural leg kick
       LocalImpactAt / LocalImpactKind (client, weapon) our swing landed / was stopped
       HitTick / HitDir    (server) we got hit, and from which direction

     On death the camera rides the head (first person, wherever it rolls),
     holds, then fades to black until respawn.

     DEBUG (ReplicatedStorage.Debug attributes, live): TurnCap ]]

local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local CAS        = game:GetService("ContextActionService")
local Players    = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local DebugFlags     = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Modifiers      = require(ReplicatedStorage:WaitForChild("Modifiers"))
local Sounds         = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig    = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local RigPose        = require(ReplicatedStorage:WaitForChild("RigPose"))
local GameSettings   = UserSettings():GetService("UserGameSettings")

local player    = Players.LocalPlayer
local character = script.Parent
local Camera    = workspace.CurrentCamera

local Humanoid = character:WaitForChild("Humanoid")
if Humanoid.RigType ~= Enum.HumanoidRigType.R6 then return end

local Head      = character:WaitForChild("Head")
local Torso     = character:WaitForChild("Torso")
local HRP       = character:WaitForChild("HumanoidRootPart")
local LeftArm   = character:WaitForChild("Left Arm")
local RightArm  = character:WaitForChild("Right Arm")
local Neck      = Torso:WaitForChild("Neck")
local RootJoint = HRP:WaitForChild("RootJoint")
Torso:WaitForChild("Left Hip"); Torso:WaitForChild("Right Hip")
Torso:WaitForChild("Left Shoulder"); Torso:WaitForChild("Right Shoulder")

local Joints  = RigPose.joints(character)
local Origins = RigPose.origins(character)
if not (Joints and Origins) then return end

-- C1 values are never modified by this script, so they're stable to read
-- back for forward-kinematics (unlike Part.CFrame, which lags a frame)
local RootC1 = RootJoint.C1
local NeckC1 = Neck.C1

-- created by ServerScriptService.PoseRelay; the camera must still work without it
local poseRemote   = ReplicatedStorage:WaitForChild("PoseRemote", 5)
local crouchRemote = ReplicatedStorage:WaitForChild("CrouchRemote", 5)
if not (poseRemote and crouchRemote) then
	warn("[CameraRig] PoseRelay remotes missing — is ServerScriptService.PoseRelay in place? Pose replication and crouch slow-down are off.")
end

--------------------------------------------------------------------
--  SETTINGS
--------------------------------------------------------------------
local SENSITIVITY = 0.003   -- multiplied by the player's Roblox mouse-sensitivity setting
local PITCH_LIMIT = math.rad(75)

local TURN_CAP_DPS = 400

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

-- rig response (pose shapes live in RigPose.CONFIG so other clients match)
local MOMENTUM_FACTOR = 0.008
local BEND_SPEED      = 16
local KICK_FALL       = 0.30   -- retract time after the kick peak
local KICK_SNAP       = 40     -- joint lerp speed during the kick (BEND_SPEED is too mushy)
local KICK_CAM        = 0.04   -- FP head bump at kick start
local CROUCH_KEYS     = {Enum.KeyCode.LeftControl, Enum.KeyCode.C}
local CROUCH_TOGGLE   = true   -- press to crouch, press again (or jump) to stand; false = hold
local CROUCH_SPEED    = 9      -- how fast the crouch settles
local CROUCH_HIP_DROP = 1.0    -- studs the whole body sinks (Humanoid.HipHeight — physical, replicated)
local POSE_RATE       = 1/20   -- how often our pose inputs go to other players

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

-- global clunk baseline — this IS your tuned "0.5" feel. Every ClunkMult_*
-- attribute on the character (weapon, armor, …) multiplies on top of it at
-- runtime; with none set that's exactly this value.
local BASE_CLUNK = 0.5
local FOOTSTEP_VOLUME = 0.5

-- hit feedback (both views)
local HIT_FLINCH  = 0.07   -- pitch kick when we take a hit
local HIT_ROLL    = 0.5    -- roll impulse away from the side we were hit on
local IMPACT_KICK = {hit = 0.025, block = 0.05, parry = 0.06}   -- our own swing landing / being stopped

-- death: ride the head as it falls, then fade
local DEATH_HOLD = 2.2
local DEATH_FADE = 1.6
--------------------------------------------------------------------

local function newSpring() return {p=0, v=0} end
local function springC(s, target, dt, stiff, damp)
	local f = stiff*(target - s.p) - damp*s.v
	s.v = s.v + f*dt; s.p = s.p + s.v*dt
	return s.p
end
local function spring(s, target, dt) return springC(s, target, dt, SPRING_STIFF, SPRING_DAMP) end

local sRoll, sLand, sSwayX, sSwayY, sLean, sStepY, sStepX, sKick, sHit =
	newSpring(), newSpring(), newSpring(), newSpring(), newSpring(), newSpring(), newSpring(), newSpring(), newSpring()

-- taking a hit: flinch down and roll away from the blow
character:GetAttributeChangedSignal("HitTick"):Connect(function()
	sHit.v = sHit.v - HIT_FLINCH * 26
	local dir = character:GetAttribute("HitDir")
	if typeof(dir) == "Vector3" then
		sRoll.v = sRoll.v + HRP.CFrame.RightVector:Dot(dir) * HIT_ROLL
	end
end)
-- our own swing landing, or clanging off a guard
character:GetAttributeChangedSignal("LocalImpactAt"):Connect(function()
	local k = IMPACT_KICK[character:GetAttribute("LocalImpactKind")] or IMPACT_KICK.hit
	sHit.v = sHit.v - k * 26
end)

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
local crouchHeld, crouchAmt = false, 0
local lastPoseSent = 0
local baseHipHeight = Humanoid.HipHeight
local lastCrouchLog = 0

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

local function setCrouch(on)
	if crouchHeld == on then return end
	crouchHeld = on
	if DebugFlags.get("Logs") then print("[CameraRig] crouch", on) end
	if crouchRemote then crouchRemote:FireServer(on) end
end
-- ContextActionService gets the key even when something else marks it
-- "game processed", which is what silently ate a plain InputBegan check
CAS:BindAction("Crouch", function(_, state)
	if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if state == Enum.UserInputState.Begin then
		if CROUCH_TOGGLE then setCrouch(not crouchHeld) else setCrouch(true) end
	elseif not CROUCH_TOGGLE and (state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel) then
		setCrouch(false)
	end
	return Enum.ContextActionResult.Sink
end, false, table.unpack(CROUCH_KEYS))

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
	if capped and not wasCapped and DebugFlags.get("TurnCap") then print("[TurnCap] active") end
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
	-- = longer waits between heavier clunks), PLUS the ClunkMult_* attributes
	-- for direct per-gear control independent of the speed change.
	bobAmt = bobAmt + (walkFrac - bobAmt) * math.clamp(dt*BOB_SMOOTH, 0, 1)

	local speedRatio = math.max(Humanoid.WalkSpeed, 0.01) / BASE_WALKSPEED
	local heaviness  = math.clamp(1 / speedRatio, HEAVINESS_MIN, HEAVINESS_MAX)
	local clunkMult  = BASE_CLUNK * Modifiers.product(character, "ClunkMult")

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
		Sounds.play(SoundConfig.Footstep, HRP, {
			Volume = FOOTSTEP_VOLUME * math.clamp(heaviness * clunkMult / BASE_CLUNK, 0.4, 2),
			Speed  = 1 / heaviness ^ 0.3,
		})
	end

	local bobY = springC(sStepY, 0, dtc, STEP_STIFF, STEP_DAMP)
	local bobX = springC(sStepX, 0, dtc, STEP_STIFF, STEP_DAMP)
	local kick = springC(sKick,  0, dtc, STEP_STIFF, STEP_DAMP)
	local hitKick = springC(sHit, 0, dtc, STEP_STIFF, STEP_DAMP)
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

	-- KICK: snaps out over the server windup, eases back over KICK_FALL
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

	-- CROUCH: an actual jump stands us up; the body sinks physically via HipHeight
	if crouchHeld and Humanoid:GetState() == Enum.HumanoidStateType.Jumping then setCrouch(false) end
	crouchAmt = crouchAmt + ((crouchHeld and 1 or 0) - crouchAmt) * math.clamp(dt*CROUCH_SPEED, 0, 1)
	Humanoid.HipHeight = baseHipHeight - CROUCH_HIP_DROP * crouchAmt

	-- BODY POSE (shared math; the same inputs are relayed to other clients)
	local inputs = {
		pitch  = rot.X,
		bob    = torsoBobY,
		leanX  = moveDir.X * math.abs(relVel.X) * MOMENTUM_FACTOR,
		leanZ  = moveDir.Z * math.abs(relVel.Z) * MOMENTUM_FACTOR,
		kick   = kickPose,
		crouch = crouchAmt,
		arm    = character:FindFirstChildOfClass("Tool") and (rot.X * RigPose.CONFIG.ARM_PITCH) or 0,
		swayX  = swayX,
		swayY  = swayY,
	}
	local legA = kickPose > 0 and math.clamp(dt*KICK_SNAP, 0, 1) or a
	RigPose.apply(Joints, RigPose.compute(inputs, Origins), a, legA)
	-- while crouched, report every half second which stage is actually moving
	if crouchHeld and now - lastCrouchLog > 0.5 and DebugFlags.get("Logs") then
		lastCrouchLog = now
		local hipRel = Origins["Right Hip"]:Inverse() * Joints["Right Hip"].C0
		local _, _, hipZ = hipRel:ToEulerAnglesXYZ()
		print(string.format("[CameraRig] crouch amt=%.2f  HipHeight=%.2f  torsoDrop=%.2f  rightHipFold=%.0f°",
			crouchAmt, Humanoid.HipHeight, (Origins.RootJoint.Position - RootJoint.C0.Position).Y, math.deg(hipZ)))
	end
	if poseRemote and now - lastPoseSent >= POSE_RATE then
		lastPoseSent = now
		poseRemote:FireServer(RigPose.pack(inputs))
	end

	-- CAMERA
	local vOff = bobY + breatheY + landDip
	local hOff = bobX + breatheX + dirSide
	local zOff = dirFwd

	if inFP then
		Camera.FieldOfView = FP_FOV + FOV_BOOST*walkFrac
		-- forward-kinematics the head's world position from the C0s we just
		-- set this frame — same "follows the head" feel as reading
		-- Head.Position, but synchronous (no one-frame joint-solver lag)
		-- (while ragdolled the joints are off, so ride the real head instead)
		local torsoCF = HRP.CFrame * RootJoint.C0 * RootC1:Inverse()
		local headCF  = torsoCF * Neck.C0 * NeckC1:Inverse()
		local target  = bodyFree and Head.Position or headCF.Position
		eyePos = eyePos and eyePos:Lerp(target, math.clamp(dt*CAM_SMOOTH, 0, 1)) or target
		Camera.CFrame = CFrame.new(eyePos)
			* CFrame.Angles(0, rot.Y, 0)
			* CFrame.Angles(rot.X + leanPitch + kick + hitKick, 0, roll*FP_ROLL_MULT)
			* CFrame.new(hOff*FP_CLUNK_MULT, EYE_UP + vOff*FP_CLUNK_MULT, -EYE_FWD + zOff*FP_CLUNK_MULT)
	else
		eyePos = nil
		Camera.FieldOfView = TP_FOV + FOV_BOOST*walkFrac
		local focus = HRP.Position + Vector3.new(0, ANCHOR_UP, 0)   -- HRP itself sinks when crouched
		camRay.FilterDescendantsInstances = {character}
		local orbit = CFrame.new(focus) * CFrame.Angles(0, rot.Y, 0) * CFrame.Angles(rot.X, 0, 0)
		local back = orbit.LookVector * -1
		local res = workspace:Raycast(focus, back * camDist, camRay)
		local distNow = camDist
		if res then distNow = math.max(0.6, (res.Position - focus).Magnitude - 0.4) end
		Camera.CFrame = CFrame.new(focus)
			* CFrame.Angles(0, rot.Y, 0)
			* CFrame.Angles(rot.X + leanPitch + hitKick, 0, roll)
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

--------------------------------------------------------------------
--  DEATH — first person from inside the head, wherever it ends up
--------------------------------------------------------------------
local function onDied()
	pcall(function() RunService:UnbindFromRenderStep("FPRig") end)
	setCrouch(false)
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	Humanoid.CameraOffset = Vector3.zero
	setBodyForFP(true)
	Head.LocalTransparencyModifier = 1
	Camera.CameraType  = Enum.CameraType.Scriptable
	Camera.FieldOfView = FP_FOV

	local gui = Instance.new("ScreenGui")
	gui.Name = "DeathFade"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.ResetOnSpawn = true
	local black = Instance.new("Frame")
	black.Size = UDim2.fromScale(1, 1)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BackgroundTransparency = 1
	black.BorderSizePixel = 0
	black.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")

	local t0 = os.clock()
	RunService:BindToRenderStep("DeathCam", CAM, function()
		if Head.Parent then
			Camera.CFrame = Head.CFrame * CFrame.new(0, 0.15, -0.25)
		end
		local t = os.clock() - t0 - DEATH_HOLD
		if t > 0 then
			black.BackgroundTransparency = 1 - math.clamp(t / DEATH_FADE, 0, 1)
		end
	end)
end

local function stop()
	pcall(function() RunService:UnbindFromRenderStep("FPRig") end)
	pcall(function() RunService:UnbindFromRenderStep("DeathCam") end)
	pcall(function() CAS:UnbindAction("Crouch") end)
	Humanoid.HipHeight = baseHipHeight
	Camera.CameraType    = Enum.CameraType.Custom
	Humanoid.AutoRotate  = true
	UIS.MouseBehavior    = Enum.MouseBehavior.Default
	Head.LocalTransparencyModifier = 0
	Humanoid.CameraOffset = Vector3.zero
end
Humanoid.Died:Once(onDied)
script.Destroying:Connect(stop)

-- the server can't change a player-owned humanoid's state, so Ragdoll asks us
ReplicatedStorage:WaitForChild("RagdollRemote").OnClientEvent:Connect(function(ragdolled)
	if Humanoid.Health <= 0 then return end
	Humanoid:ChangeState(ragdolled and Enum.HumanoidStateType.Physics or Enum.HumanoidStateType.GettingUp)
end)
