--[[ R6 UNIFIED FIRST/THIRD PERSON CAMERA + aim rig + immersion + turn cap.
     Owns the camera in BOTH views. The View key (Z) toggles FP/TP. Shift-lock in TP.
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
local SoundService      = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local DebugFlags     = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Modifiers      = require(ReplicatedStorage:WaitForChild("Modifiers"))
local Sounds         = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig    = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local RigPose        = require(ReplicatedStorage:WaitForChild("RigPose"))
local TouchInput = require(game:GetService("ReplicatedStorage"):WaitForChild("TouchInput"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local GameSettings   = UserSettings():GetService("UserGameSettings")
ClientSettings.load()

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
if not (Joints and Origins) then
	warn("[CameraRig] R6 joints not found on", character:GetFullName())
	return
end

-- startup report: where this copy runs from, and any OTHER local scripts that
-- could be fighting it (an older camera script left in the character or in
-- StarterPlayerScripts is the usual reason a new feature "does nothing")
local VERSION = "v4"
if DebugFlags.get("Logs") then print(string.format("[CameraRig %s] running from %s", VERSION, script:GetFullName())) end
for _, s in ipairs(character:GetDescendants()) do
	if s:IsA("LocalScript") and s ~= script then
		if DebugFlags.get("Logs") then print("[CameraRig] other LocalScript in character:", s:GetFullName()) end
	end
end
local ps = player:FindFirstChild("PlayerScripts")
if ps then
	for _, s in ipairs(ps:GetChildren()) do
		if s:IsA("LocalScript") and s.Name ~= "PlayerScriptsLoader" and s.Name ~= "RbxCharacterSounds" then
			if DebugFlags.get("Logs") then print("[CameraRig] LocalScript in PlayerScripts:", s.Name) end
		end
	end
end

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

-- third-person: the View key (settings, default Z) toggles first / third
-- person; the scroll wheel is for attacks now, so there's no zooming
local DEFAULT_DIST= 9
local FP_ENTER    = 0.75
local ZOOM_SMOOTH = 14
local SHOULDER_X  = 2.2   -- over the right shoulder
local SHOULDER_Y  = 0.9   -- …and a bit above it

local ACCESSORY_TRANSPARENCY = 1

-- rig response (pose shapes live in RigPose.CONFIG so other clients match)
local MOMENTUM_FACTOR = 0.008
local BEND_SPEED      = 16
local KICK_FALL       = 0.30   -- retract time after the kick peak
local KICK_SNAP       = 40     -- joint lerp speed during the kick (BEND_SPEED is too mushy)
local KICK_CAM        = 0.04   -- FP head bump at kick start
local CROUCH_KEYS     = {ClientSettings.key("Crouch"), Enum.KeyCode.C}   -- rebindable in settings (+ C)
local CROUCH_TOGGLE   = false  -- hold to crouch; true = press to toggle
local CROUCH_DEBOUNCE = 0.2    -- crouch state can't flip faster than this (no spam)
local CROUCH_SPEED    = 9      -- how fast the crouch settles
local CROUCH_HIP_DROP = 0.95   -- studs the whole body sinks (HipHeight) — matches the leg fold so feet stay on the floor
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

-- sprint / dodge feel
local SPRINT_FOV_ADD = 8      -- degrees while SpeedMult_Sprint is published
local FOV_SMOOTH     = 6      -- how fast the FOV eases between values
-- The FOV setting (70..110) is a "wideness" dial, not degrees. Roblox caps the
-- real FOV at 120, so 70 already maps to a wide 116° and the rest of the range
-- widens the picture by pulling the eye BACK (more of the sword in frame).
local FP_FOV_MIN, FP_FOV_MAX = 116, 120      -- real FOV at setting 70 / 110
local EYE_PULL_MAX = 0.75                    -- studs the eye moves back at setting 110
-- LOOKING DOWN: the pulled-back eye sits over the torso, so a downward glance
-- would show the TOP of the chest and tabard. Instead, as the pitch drops the
-- pull-back fades out and the eye slides FORWARD past the chest (the "nose"),
-- so only front faces are in view — chest front, tabard, legs, feet. The
-- torso itself stays hidden while looking level (only its top face could
-- show at the bottom of a wide frame) and fades in between the two angles.
local LOOKDOWN_ANGLE = math.rad(40)          -- pitch at which the pull-back is fully gone
local LOOKDOWN_FWD   = 0.6                   -- studs the eye moves forward (horizontal) by then
local TORSO_SHOW_FROM, TORSO_SHOW_TO = math.rad(18), math.rad(34)   -- torso fades in over this pitch range
local fovNow         = FP_FOV
local DODGE_ROLL     = 0.35   -- roll impulse into a side dodge
local DODGE_DIP      = 0.06   -- pitch dip on any dodge

-- Every tuned value above is the "1.0" the player's settings scale:
-- ClientSettings Bob / Sway / Roll / Shake / Breathe / FPClunk / FOV
-- (the ⚙ on the loadout menu). Read every frame, so changes apply live.
local function S(key) return ClientSettings.get(key) end
local function fovDial() return math.clamp((S("FOV") - 70) / 40, 0, 1) end
ClientSettings.onChanged(function(key, v)
	if DebugFlags.get("Logs") then print("[CameraRig] setting", key, "=", v) end
end)

-- hit feedback (both views)
local HIT_FLINCH  = 0.07   -- pitch kick when we take a hit
local HIT_ROLL    = 0.5    -- roll impulse away from the side we were hit on
local IMPACT_KICK = {hit = 0.025, heavy = 0.045, kill = 0.075, block = 0.05, wall = 0.05, parry = 0.06, chamber = 0.06, feint = 0.015, perfect = 0.07}   -- our own swing landing / being stopped / pulled
local FOV_PUNCH = {kill = -7, perfect = -5, chamber = -3, heavy = -1.5}   -- degrees the view snaps in for a big moment (then eases back)

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
local sFov = newSpring()   -- the FOV punch

-- taking a hit: flinch down and roll away from the blow
-- body jolt away from the blow (relayed, so everyone sees the reaction)
local sJoltX, sJoltZ = newSpring(), newSpring()
character:GetAttributeChangedSignal("HitTick"):Connect(function()
	sHit.v = sHit.v - HIT_FLINCH * 26 * S("Shake")
	local dir = character:GetAttribute("HitDir")
	if typeof(dir) == "Vector3" then
		sRoll.v = sRoll.v + HRP.CFrame.RightVector:Dot(dir) * HIT_ROLL * S("Shake")
		local J = RigPose.CONFIG.HIT_JOLT * 6
		sJoltX.v = sJoltX.v + HRP.CFrame.RightVector:Dot(dir) * J
		sJoltZ.v = sJoltZ.v + HRP.CFrame.LookVector:Dot(dir) * J
	end
end)
-- our own swing landing, or clanging off a guard
character:GetAttributeChangedSignal("LocalImpactAt"):Connect(function()
	local kind = character:GetAttribute("LocalImpactKind")
	local k = IMPACT_KICK[kind] or IMPACT_KICK.hit
	sHit.v = sHit.v - k * 26 * S("Shake")
	if FOV_PUNCH[kind] then sFov.v = sFov.v + FOV_PUNCH[kind] * 22 * S("Shake") end
end)
-- our perfect parry (the server stamps it): a sharp punch, the moment reads
character:GetAttributeChangedSignal("PerfectParryAt"):Connect(function()
	sHit.v = sHit.v - IMPACT_KICK.perfect * 26 * S("Shake")
	sFov.v = sFov.v + FOV_PUNCH.perfect * 22 * S("Shake")
end)
-- a dodge (Movement.client): lean the body into it, roll the camera
local sDodgeX, sDodgeZ = newSpring(), newSpring()
character:GetAttributeChangedSignal("LocalDodgeAt"):Connect(function()
	local dx = character:GetAttribute("LocalDodgeX") or 0
	local dz = character:GetAttribute("LocalDodgeZ") or 0
	sDodgeX.v = sDodgeX.v + dx * RigPose.CONFIG.DODGE_LEAN * 6   -- peaks ≈ DODGE_LEAN·0.55 rad, settles in ~0.4 s
	sDodgeZ.v = sDodgeZ.v + dz * RigPose.CONFIG.DODGE_LEAN * 6
	sRoll.v = sRoll.v + dx * DODGE_ROLL * S("Roll")
	sHit.v  = sHit.v - DODGE_DIP * 26 * S("Shake")
end)

local rot = Vector2.new(0, select(2, HRP.CFrame:ToOrientation()))
-- the server put us somewhere, facing something (basic training: in front of
-- the next dummy): the camera turns with us
character:GetAttributeChangedSignal("FaceTick"):Connect(function()
	local y = character:GetAttribute("FaceYaw")
	if type(y) == "number" then rot = Vector2.new(0, y) end
end)
-- (placed before this script was up: take it now)
if type(character:GetAttribute("FaceYaw")) == "number" then rot = Vector2.new(0, character:GetAttribute("FaceYaw")) end
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
local crouchWanted, lastCrouchChange = false, -1e9
local lastPoseSent = 0
local baseHipHeight = Humanoid.HipHeight
local lastCrouchLog = 0
local lastAliveLog  = 0

local camRay = RaycastParams.new()
camRay.FilterType = Enum.RaycastFilterType.Exclude

--------------------------------------------------------------------
--  FOOTSTEPS — per-material, one shot per step (the clunk drives the
--  timing, so these are fired on the step impulse rather than looped).
--  The sounds live in ReplicatedStorage.Footsteps; Roblox's own looping
--  run sound is muted by StarterPlayerScripts.Footsteps. (Jumping is
--  Movement's: a short hop on its own key.)
--------------------------------------------------------------------
local Footsteps = require(ReplicatedStorage:WaitForChild("Footsteps"))

player.CameraMode = Enum.CameraMode.Classic

--------------------------------------------------------------------
--  VISIBILITY
--------------------------------------------------------------------
local torsoPieces = {}   -- torso armor parts, faded with the torso in first person
local armPieces = {}     -- arm armor parts: shown in first person (your sleeves and gauntlets on the
                         -- weapon), hidden only while one is right up against the camera
local ARM_HIDE = 0.1     -- studs between the camera and a piece's box before it hides…
local ARM_SHOW = 0.3     -- …and how far it must be again before it shows (no flicker at the edge)
local setTorsoAlpha
local function applyVisibility(d, inFP)
	if d:IsA("BasePart") then
		if d.Name == "Head" then
			-- handled per-frame below
		elseif d.Parent:IsA("Accessory") then
			-- hats sit in front of the camera in first person
			d.LocalTransparencyModifier = inFP and ACCESSORY_TRANSPARENCY or 0
			d.CastShadow = true
		elseif d:FindFirstAncestor("Armor") and d:FindFirstAncestor("Armor").Parent == character then
			-- armor: leg and arm pieces show in first person (an arm piece hides
			-- only while it's in the camera's face, see the loop); torso pieces
			-- follow the torso (visible only when looking down, see setTorsoAlpha);
			-- the helmet would fill the camera (Middle is invisible anyway)
			local piece = d:FindFirstAncestorOfClass("Model")
			local isLeg = piece and piece.Name:find("LegClothing") ~= nil
			local isArm = piece and piece.Name:find("ArmClothing") ~= nil
			local isTorso = piece and piece.Name:find("TorsoClothing") ~= nil
			d.LocalTransparencyModifier = (inFP and not isLeg and not isArm) and 1 or 0
			if isTorso then torsoPieces[d] = inFP or nil end
			if isArm then armPieces[d] = inFP or nil end
			d.CastShadow = true
		elseif d:FindFirstAncestor("Body") and d:FindFirstAncestor("Body").Parent == character then
			-- hair, beard and the face overlay sit on the head: they would fill
			-- the camera in first person
			d.LocalTransparencyModifier = inFP and 1 or 0
			d.CastShadow = true
		else
			d.LocalTransparencyModifier = 0
		end
	elseif d:IsA("Decal") and d.Parent and d.Parent.Name == "Head" then
		d.LocalTransparencyModifier = inFP and 1 or 0
	end
end

local function setBodyForFP(inFP)
	torsoPieces = {}
	armPieces = {}
	for _, d in ipairs(character:GetDescendants()) do applyVisibility(d, inFP) end
end
-- first person: an arm piece swung up into the camera hides until it's clear again.
-- The gap is to the piece's own box, not a sphere round it: a sleeve is one
-- mesh as long as the arm, and a sphere that big hid the whole sleeve on every swing.
local function boxGap(part, eye)
	local p = part.CFrame:PointToObjectSpace(eye)
	local h = part.Size / 2
	return Vector3.new(math.max(math.abs(p.X) - h.X, 0), math.max(math.abs(p.Y) - h.Y, 0), math.max(math.abs(p.Z) - h.Z, 0)).Magnitude
end
-- the limb an armor piece is on (its model carries Limb)
local function limbOf(part)
	local p = part
	while p and p ~= character do
		local l = p:GetAttribute("Limb")
		if l then return l end
		p = p.Parent
	end
	return nil
end
local function fadeArmPieces()
	local eye = Camera.CFrame.Position
	for part in pairs(armPieces) do
		if part.Parent then
			local gap = boxGap(part, eye)
			if part.LocalTransparencyModifier > 0.5 then
				if gap > ARM_SHOW then part.LocalTransparencyModifier = 0 end
			elseif gap < ARM_HIDE then
				part.LocalTransparencyModifier = 1
			end
		else
			armPieces[part] = nil
		end
	end
end

-- 1 = torso hidden (looking level), 0 = fully shown (looking down)
function setTorsoAlpha(a)
	Torso.LocalTransparencyModifier = a
	local tab = character:FindFirstChild("Tabard")
	if tab then tab.LocalTransparencyModifier = a end
	for part in pairs(torsoPieces) do
		if part.Parent then part.LocalTransparencyModifier = a else torsoPieces[part] = nil end
	end
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
	end
end)
-- FREE MOUSE (the Cursor bind, T): the cursor is let go so the screen can be
-- clicked (the gift, the boards); the camera holds still and the body turns
-- the way it walks. Any fight input locks it again with the camera snapped
-- behind the body, never the body spun to the camera: a free mouse can't be
-- used to whip a swing round by tapping the move keys.
local cursorFree = false
local freeHint
local function showFreeHint(on)
	if on and not freeHint then
		local g = Instance.new("ScreenGui")
		g.Name = "FreeMouseHint"
		g.ResetOnSpawn = true
		local l = Instance.new("TextLabel")
		l.AnchorPoint = Vector2.new(0.5, 1)
		l.Position = UDim2.new(0.5, 0, 1, -150)
		l.Size = UDim2.fromOffset(300, 28)
		l.BackgroundColor3 = Color3.fromRGB(20, 18, 16)
		l.BackgroundTransparency = 0.35
		l.Font = Enum.Font.GothamBold
		l.TextSize = 14
		l.TextColor3 = Color3.fromRGB(240, 232, 214)
		l.Parent = g
		Instance.new("UICorner", l).CornerRadius = UDim.new(0, 8)
		g.Parent = player:WaitForChild("PlayerGui")
		freeHint = g
	end
	if freeHint then
		freeHint.Enabled = on
		local key = ClientSettings.get("Key_Cursor")
		freeHint.TextLabel.Text = string.format("MOUSE FREE  ·  %s TO LOCK THE CAMERA", string.upper(tostring(key)))
	end
end
local function setCursorFree(on)
	if cursorFree == on then return end
	cursorFree = on
	if not on then
		-- the camera swings round behind the body (the body stays put)
		local lv = HRP.CFrame.LookVector
		rot = Vector2.new(rot.X, math.atan2(-lv.X, -lv.Z))
		mouseDX, mouseDY = 0, 0
	end
	showFreeHint(on)
end
local FIGHT_ACTIONS = {Swing = true, Stab = true, Overhead = true, Underhand = true, Feint = true, Kick = true, Dodge = true, Pickup = true}
UIS.InputBegan:Connect(function(input, gp)
	if UIS:GetFocusedTextBox() then return end
	local action = ClientSettings.actionForInput(input)
	if action == "Cursor" and not gp then setCursorFree(not cursorFree); return end
	if not cursorFree or gp then return end
	if FIGHT_ACTIONS[action] or input.UserInputType == Enum.UserInputType.MouseButton2 then setCursorFree(false) end
end)
UIS.InputChanged:Connect(function(input, gp)
	if cursorFree and not gp and input.UserInputType == Enum.UserInputType.MouseWheel and FIGHT_ACTIONS[ClientSettings.actionForInput(input) or ""] then setCursorFree(false) end
end)
-- a swing or a guard that started some other way locks it too
for _, attr in ipairs({"Acting", "Blocking"}) do
	character:GetAttributeChangedSignal(attr):Connect(function()
		if cursorFree and character:GetAttribute(attr) then setCursorFree(false) end
	end)
end
script.Destroying:Connect(function() if freeHint then freeHint:Destroy() end end)

-- first / third person toggle (rebindable; any bind type)
local function viewInput(input, gp)
	if gp or UIS:GetFocusedTextBox() then return end
	if ClientSettings.actionForInput(input) == "View" then
		camDistTarget = (camDistTarget <= FP_ENTER) and DEFAULT_DIST or 0
	end
end
UIS.InputBegan:Connect(viewInput)
UIS.InputChanged:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseWheel then viewInput(input, gp) end
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
	-- only records what the player WANTS; the loop applies it, rate-limited by CROUCH_DEBOUNCE
	if state == Enum.UserInputState.Begin then
		if CROUCH_TOGGLE then crouchWanted = not crouchWanted else crouchWanted = true end
	elseif not CROUCH_TOGGLE and (state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel) then
		crouchWanted = false
	end
	return Enum.ContextActionResult.Sink
end, false, table.unpack(CROUCH_KEYS))
-- rebinding crouch in settings takes effect without a respawn
ClientSettings.onChanged(function(key)
	if key ~= "Key_Crouch" then return end
	CAS:UnbindAction("Crouch")
	CROUCH_KEYS = {ClientSettings.key("Crouch"), Enum.KeyCode.C}
	crouchWanted = false
	CAS:BindAction("Crouch", function(_, state)
		if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
		if state == Enum.UserInputState.Begin then
			if CROUCH_TOGGLE then crouchWanted = not crouchWanted else crouchWanted = true end
		elseif not CROUCH_TOGGLE and (state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel) then
			crouchWanted = false
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(CROUCH_KEYS))
end)

--------------------------------------------------------------------
--  MAIN
--------------------------------------------------------------------
local CAM = Enum.RenderPriority.Camera.Value
-- unique per copy: an older camera script unbinding "FPRig" can't take this loop away
local LOOP_NAME = "CameraRig_" .. VERSION .. "_" .. tostring(math.random(1, 1e9))
local lastLoopError = 0
local function loopBody(dt)
	if not (Neck.Parent and RootJoint.Parent) then return end
	local a   = math.clamp(dt*BEND_SPEED, 0, 1)
	local dtc = math.min(dt, 1/30)
	local now = os.clock()

	-- typing in chat / a TextBox, or the mouse set free: release the mouse and ignore look input
	local typing = UIS:GetFocusedTextBox() ~= nil
	local loose = typing or cursorFree
	Camera.CameraType   = Enum.CameraType.Scriptable
	UIS.MouseBehavior   = loose and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
	UIS.MouseIconEnabled = loose   -- no cursor over the crosshair-less view while we're alive
	-- a free mouse: the body turns the way it walks; locked: it faces the camera (below)
	Humanoid.AutoRotate = cursorFree

	-- turn cap: LOCAL timer only. The server's TurnCapUntil is on the
	-- server's os.clock(), which is a different clock — never compare it here.
	local capped = now < (character:GetAttribute("LocalTurnCapUntil") or 0)
	if capped and not wasCapped and DebugFlags.get("TurnCap") then print("[TurnCap] active") end
	wasCapped = capped

	local rawDX, rawDY = mouseDX, mouseDY
	mouseDX, mouseDY = 0, 0
	-- a drag on a touch screen turns the camera too (TouchControls)
	local tdx, tdy = TouchInput.takeLook()
	rawDX, rawDY = rawDX + tdx, rawDY + tdy
	if loose then rawDX, rawDY = 0, 0 end
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
	local bodyFree = Humanoid.PlatformStand or Humanoid.Sit or character:GetAttribute("Ragdolled") == true or cursorFree
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

	-- heaviness comes from WEIGHT (weapon, armor, lost legs) — not from backing
	-- up, strafing, sprinting or crouching, which only change how fast you move
	local weightRatio = 1
	for name, v in pairs(character:GetAttributes()) do
		if type(v) == "number" and (name == "SpeedMult" or name == "SpeedMult_Weapon" or name == "SpeedMult_Armor" or name == "SpeedMult_Limbs") then
			weightRatio = weightRatio * v
		end
	end
	local heaviness  = math.clamp(1 / math.max(weightRatio, 0.05), HEAVINESS_MIN, HEAVINESS_MAX)
	local clunkMult  = BASE_CLUNK * Modifiers.product(character, "ClunkMult")

	-- cadence follows how fast the feet actually move
	local stepped = false
	if grounded and walkFrac > 0.05 then
		stepPhase = stepPhase + dt * STEP_RATE_HZ * (speed / BASE_WALKSPEED)
		if stepPhase >= 1 then
			stepPhase = stepPhase % 1
			stepSide = -stepSide
			stepped = true
		end
	else
		stepPhase = 0
	end

	if stepped then
		local bobS = S("Bob")
		sStepY.v = sStepY.v - BOB_CAM_Y * 26 * bobAmt * heaviness * clunkMult * bobS
		sStepX.v = sStepX.v + stepSide * BOB_CAM_X * 20 * bobAmt * heaviness * clunkMult * bobS
		sKick.v  = sKick.v  - FP_KICK_AMT * 26 * bobAmt * heaviness * clunkMult * bobS * S("FPClunk")
		-- one shot per step, using the sound for whatever we're standing on
		Footsteps.play(HRP, Humanoid.FloorMaterial, {
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
	local rollTarget = math.clamp(turnRate*ROLL_TURN + moveDir.X*ROLL_STRAFE, -ROLL_MAX, ROLL_MAX) * S("Roll")
	roll = spring(sRoll, rollTarget, dtc)

	if grounded and lastVY < -5 then sLand.v = sLand.v - (-lastVY)*LAND_FORCE end
	local landDip = spring(sLand, 0, dtc)

	local accel = (speed - lastSpeed) / math.max(dt, 1e-3)
	leanPitch = spring(sLean, math.clamp(accel*MOMENTUM_LEAN*0.02, -0.15, 0.15), dtc)

	local swayS = S("Sway")
	local swayX = math.clamp(spring(sSwayX, -appliedDX*SWAY_AMOUNT*0.02*swayS, dtc), -SWAY_MAX, SWAY_MAX)
	local swayY = math.clamp(spring(sSwayY, -appliedDY*SWAY_AMOUNT*0.02*swayS, dtc), -SWAY_MAX, SWAY_MAX)

	local idle = (1 - walkFrac) * S("Breathe")
	local breatheX = math.sin(now*BREATHE_HZ) * BREATHE_AMOUNT * idle
	local breatheY = math.sin(now*BREATHE_HZ*2) * BREATHE_AMOUNT * 0.5 * idle
	local dodgeLX = spring(sDodgeX, 0, dtc)
	local dodgeLZ = spring(sDodgeZ, 0, dtc)
	local joltX = spring(sJoltX, 0, dtc)
	local joltZ = spring(sJoltZ, 0, dtc)

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
		if kickAt > 0 then sKick.v = sKick.v - KICK_CAM * 26 * S("Shake") end   -- 0 means cancelled, not kicked
	end

	-- CROUCH: follows the key, but can't flip faster than CROUCH_DEBOUNCE
	local wanted = crouchWanted
	if wanted ~= crouchHeld and now - lastCrouchChange >= CROUCH_DEBOUNCE then
		lastCrouchChange = now
		setCrouch(wanted)
	end
	crouchAmt = crouchAmt + ((crouchHeld and 1 or 0) - crouchAmt) * math.clamp(dt*CROUCH_SPEED, 0, 1)
	Humanoid.HipHeight = baseHipHeight - CROUCH_HIP_DROP * crouchAmt

	-- BODY POSE (shared math; the same inputs are relayed to other clients)
	local inputs = {
		pitch  = rot.X,
		bob    = torsoBobY,
		leanX  = moveDir.X * math.abs(relVel.X) * MOMENTUM_FACTOR + dodgeLX,
		leanZ  = moveDir.Z * math.abs(relVel.Z) * MOMENTUM_FACTOR + dodgeLZ,
		kick   = kickPose,
		crouch = crouchAmt,
		arm    = character:FindFirstChildOfClass("Tool") and (rot.X * RigPose.CONFIG.ARM_PITCH) or 0,
		swayX  = swayX,
		swayY  = swayY,
		hitX   = joltX,
		hitZ   = joltZ,
		-- a bow or a crossbow in hand (RangedClient): its stance, everyone sees it
		ranged = character:GetAttribute("LocalRanged") or 0,
		aim    = character:GetAttribute("LocalAim") or 0,
		draw   = character:GetAttribute("LocalDraw") or 0,
		reload = character:GetAttribute("LocalReload") or 0,
	}
	local legA = kickPose > 0 and math.clamp(dt*KICK_SNAP, 0, 1) or a
	RigPose.apply(Joints, RigPose.compute(inputs, Origins), a, legA)
	-- heartbeat: proves THIS loop is the one drawing the body
	if DebugFlags.get("Logs") and now - lastAliveLog > 3 then
		lastAliveLog = now
		print(string.format("[CameraRig %s] loop ok | %s | crouchHeld=%s amt=%.2f HipHeight=%.2f bodyFree=%s",
			VERSION, inFP and "FP" or "TP", tostring(crouchHeld), crouchAmt, Humanoid.HipHeight, tostring(bodyFree)))
	end
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
	-- FP clunk boost: 1 + (FP_CLUNK_MULT-1) × setting, so 0 = plain TP-strength bob
	local fpClunk = 1 + (FP_CLUNK_MULT - 1) * S("FPClunk")
	local vOff = bobY + breatheY + landDip
	local hOff = bobX + breatheX + dirSide
	local zOff = dirFwd

	-- FOV: the setting is what the player sees; FP_FOV_HIDDEN widens it behind
	-- the scenes so the whole sword stays in frame. Sprint adds and smooths.
	local sprinting = character:GetAttribute("SpeedMult_Sprint") ~= nil
	local dial = fovDial()
	local fovTarget = inFP
		and (FP_FOV_MIN + (FP_FOV_MAX - FP_FOV_MIN) * dial + FOV_BOOST*walkFrac + (sprinting and SPRINT_FOV_ADD or 0))
		or  (TP_FOV + dial * 12 + FOV_BOOST*walkFrac + (sprinting and SPRINT_FOV_ADD * 0.6 or 0))
	fovNow = fovNow + (fovTarget - fovNow) * math.clamp(dt * FOV_SMOOTH, 0, 1)
	local punch = springC(sFov, 0, dtc, 220, 22)   -- snaps in, eases back in about a quarter second
	-- a bow at full draw / a crossbow aimed down the tiller: a little zoom (RangedClient)
	Camera.FieldOfView = math.clamp(fovNow + punch - 20 * (character:GetAttribute("LocalZoom") or 0), 40, 120)
	if inFP then
		-- forward-kinematics the head's world position from the C0s we just
		-- set this frame — same "follows the head" feel as reading
		-- Head.Position, but synchronous (no one-frame joint-solver lag)
		-- (while ragdolled the joints are off, so ride the real head instead)
		local torsoCF = HRP.CFrame * RootJoint.C0 * RootC1:Inverse()
		local headCF  = torsoCF * Neck.C0 * NeckC1:Inverse()
		local target  = bodyFree and Head.Position or headCF.Position
		eyePos = eyePos and eyePos:Lerp(target, math.clamp(dt*CAM_SMOOTH, 0, 1)) or target
		local downFrac = math.clamp(-rot.X / LOOKDOWN_ANGLE, 0, 1)
		local pull = EYE_PULL_MAX * dial * (1 - downFrac)
		local nose = LOOKDOWN_FWD * downFrac
		Camera.CFrame = CFrame.new(eyePos)
			* CFrame.Angles(0, rot.Y, 0)
			* CFrame.new(0, 0, -nose)   -- horizontal, past the chest, when looking down
			* CFrame.Angles(rot.X + leanPitch + kick + hitKick, 0, roll*FP_ROLL_MULT)
			* CFrame.new(hOff*fpClunk, EYE_UP + vOff*fpClunk, -EYE_FWD + pull + zOff*fpClunk)
	else
		eyePos = nil
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
		-- torso (+ tabard, + torso armor): only when looking down enough that the
		-- eye is already in front of the chest, so its top face never shows
		local show = math.clamp((-rot.X - TORSO_SHOW_FROM) / (TORSO_SHOW_TO - TORSO_SHOW_FROM), 0, 1)
		setTorsoAlpha(1 - show)
		fadeArmPieces()
		-- a bow or a crossbow up in first person: an arm by the face would fill the view.
		-- A bow: the string hand (the left, at the jaw) goes; the bow arm stays, out in
		-- front holding the bow. A crossbow: both (only the weapon shows). (RangedClient)
		local ranged = character:GetAttribute("LocalRanged") or 0
		if ranged > 0.5 then
			local bow = ranged < 1.5
			LeftArm.LocalTransparencyModifier = 1
			if not bow then RightArm.LocalTransparencyModifier = 1 end
			for part in pairs(armPieces) do
				if part.Parent and (not bow or limbOf(part) == "Left Arm") then part.LocalTransparencyModifier = 1 end
			end
		end
	else
		Head.LocalTransparencyModifier = 0
		setTorsoAlpha(0)
	end

	lastSpeed = speed
	lastVY = grounded and 0 or vy
end

RunService:BindToRenderStep(LOOP_NAME, CAM, function(dt)
	local ok, err = pcall(loopBody, dt)
	if not ok and os.clock() - lastLoopError > 1 then
		lastLoopError = os.clock()
		warn("[CameraRig] LOOP ERROR (repeating every frame): " .. tostring(err))
	end
end)
if DebugFlags.get("Logs") then print("[CameraRig " .. VERSION .. "] loop bound as " .. LOOP_NAME) end

--------------------------------------------------------------------
--  DEATH — first person from inside the head, wherever it ends up
--------------------------------------------------------------------
local function onDied()
	pcall(function() RunService:UnbindFromRenderStep(LOOP_NAME) end)
	setCrouch(false)
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true
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
		-- fully black: stop steering the camera so the loadout menu can take
		-- it over (LoadoutMenu clears DeathFade when it opens)
		if t > DEATH_FADE then
			pcall(function() RunService:UnbindFromRenderStep("DeathCam") end)
		end
	end)
end

local function stop()
	pcall(function() RunService:UnbindFromRenderStep(LOOP_NAME) end)
	pcall(function() RunService:UnbindFromRenderStep("DeathCam") end)
	pcall(function() CAS:UnbindAction("Crouch") end)
	Humanoid.HipHeight = baseHipHeight
	Camera.CameraType    = Enum.CameraType.Custom
	Humanoid.AutoRotate  = true
	UIS.MouseBehavior    = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true
	Head.LocalTransparencyModifier = 0
	Humanoid.CameraOffset = Vector3.zero
end
Humanoid.Died:Once(onDied)
script.Destroying:Connect(stop)

-- the server can't change a player-owned humanoid's state or push our parts
-- (we own the physics), so Ragdoll asks us to do both
ReplicatedStorage:WaitForChild("RagdollRemote").OnClientEvent:Connect(function(ragdolled, shoveDir, shoveSpeed)
	if DebugFlags.get("Logs") then print("[CameraRig] ragdoll", ragdolled, shoveDir, shoveSpeed) end
	-- Physics state still matters when dead (that's the death ragdoll);
	-- only standing back up requires being alive
	if ragdolled then
		Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	elseif Humanoid.Health > 0 then
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	if ragdolled and typeof(shoveDir) == "Vector3" and Torso.Parent then
		Torso.AssemblyLinearVelocity = Torso.AssemblyLinearVelocity + shoveDir * (shoveSpeed or 0)
	end
end)
