--[[ GAMEPAD CONTROLS — Xbox and PlayStation controllers. Every button fires
     the same action a key does, through ReplicatedStorage ▸ TouchInput (the
     action bus the touch buttons use too), so the fight code needs nothing new.
     The layout lives in ReplicatedStorage ▸ InputHints.PAD (hints read it too):

       RT / R2   swing — aim it with the right stick: ← → that side, ↑ an
                 overhead, ↓ an underhand; centred, the sides alternate
       RB / R1   stab            LB / L1   overhead        LT / L2   block (hold)
       A / ✕     jump            B / ○     dodge           X / □     kick (or pick up,
       Y / △     feint                                               when a prompt shows)
       LS click  sprint (on until you stop)                RS click  first / third person
       D-pad ↑   emote wheel (hold, aim with the right stick, let go)
       D-pad ↓   crouch (toggle)        D-pad ← →  weapons (Hotbar)
       VIEW / TOUCHPAD   tap: the menu · hold: the scoreboard
       right stick       look

     Menus (the hub, the class screen, the vote, any pop-up that frees the
     mouse) get Roblox's virtual cursor: the left stick moves it, A clicks. ]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local GamepadService = game:GetService("GamepadService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TouchInput = require(ReplicatedStorage:WaitForChild("TouchInput"))
local InputHints = require(ReplicatedStorage:WaitForChild("InputHints"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local PAD = InputHints.PAD
local K = Enum.KeyCode
local player = Players.LocalPlayer

local DEADZONE = 0.14
local YAW_RATE = 270     -- degrees a second at full tilt…
local PITCH_RATE = 170   -- …and up / down
local CURVE = 1.7        -- small tilts aim finely, full tilts turn fast
local AIM_ZONE = 0.45    -- how far the right stick must lean to aim a swing
local SENS = 0.003       -- CameraRig's mouse sensitivity (a look delta is in mouse pixels)
local HOLD_BOARD = 0.28  -- seconds on SELECT before it's the scoreboard, not the menu

-- Select is ours (the menu): not Roblox's UI-selection toggle
pcall(function() GuiService.AutoSelectGuiEnabled = false end)

local function menuUp()
	return (_G.HubMenuOpen and _G.HubMenuOpen()) or false
end
local function stick()
	local ok, state = pcall(function() return UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) end)
	if not ok then return Vector2.zero, Vector2.zero end
	local l, r = Vector2.zero, Vector2.zero
	for _, s in ipairs(state) do
		if s.KeyCode == K.Thumbstick1 then l = Vector2.new(s.Position.X, s.Position.Y)
		elseif s.KeyCode == K.Thumbstick2 then r = Vector2.new(s.Position.X, s.Position.Y) end
	end
	return l, r
end
local function shaped(v)
	local m = v.Magnitude
	if m < DEADZONE then return Vector2.zero end
	local k = ((m - DEADZONE) / (1 - DEADZONE)) ^ CURVE
	return v.Unit * math.min(k, 1)
end

-- the swing, aimed with the right stick
local lastSide = "Left"
local swingAs = nil   -- what the held trigger started (its release goes with it)
local function swingDown()
	local _, r = stick()
	if r.Magnitude >= AIM_ZONE and math.abs(r.Y) > math.abs(r.X) then
		swingAs = r.Y > 0 and "Overhead" or "Underhand"
		TouchInput.press(swingAs, true)
		return
	end
	local side
	if r.Magnitude >= AIM_ZONE then side = r.X < 0 and "Left" or "Right"
	else side = lastSide == "Left" and "Right" or "Left" end
	lastSide = side
	swingAs = "Swing"
	TouchInput.press("Swing", true, side)
end
local function swingUp()
	TouchInput.press(swingAs or "Swing", false)
	swingAs = nil
end

-- toggles
local sprintOn, crouchOn = false, false
local selectAt = nil
local boardUp = false

local BY_CODE = {}
for action, code in pairs(PAD) do BY_CODE[code] = BY_CODE[code] or {}; table.insert(BY_CODE[code], action) end

UserInputService.InputBegan:Connect(function(input, gp)
	if not input.UserInputType.Name:find("^Gamepad") then return end
	local code = input.KeyCode
	-- the menu / scoreboard button works everywhere
	if code == PAD.Menu then selectAt = os.clock(); return end
	if menuUp() or UserInputService:GetFocusedTextBox() then return end
	-- (a prompt shown on X takes X: that's the pickup, not a kick)
	if gp and (code == K.ButtonX or code == K.ButtonA or code == K.ButtonB) then return end
	if code == PAD.Swing then swingDown()
	elseif code == PAD.Block then TouchInput.press("Block", true)
	elseif code == PAD.Sprint then sprintOn = not sprintOn; TouchInput.press("Sprint", sprintOn)
	elseif code == PAD.Crouch then crouchOn = not crouchOn; TouchInput.press("Crouch", crouchOn)
	elseif code == PAD.Emote then TouchInput.press("Emote", true)
	else
		for _, action in ipairs(BY_CODE[code] or {}) do
			if action ~= "Pickup" and action ~= "Reload" and action ~= "Board" then TouchInput.press(action, true) end
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if not input.UserInputType.Name:find("^Gamepad") then return end
	local code = input.KeyCode
	if code == PAD.Menu then
		if boardUp then TouchInput.press("Board", false); boardUp = false
		elseif selectAt and os.clock() - selectAt < HOLD_BOARD then
			if _G.HubMenuToggle then _G.HubMenuToggle() end
		end
		selectAt = nil
		return
	end
	if code == PAD.Swing then swingUp()
	elseif code == PAD.Block then TouchInput.press("Block", false)
	elseif code == PAD.Emote then TouchInput.press("Emote", false) end
end)

-- every frame: look with the right stick, sprint ends when you stop, the
-- scoreboard on a held SELECT, and the cursor for menus
local cursorWanted = false
local lastPadAt = 0
UserInputService.InputChanged:Connect(function(input) if input.UserInputType.Name:find("^Gamepad") then lastPadAt = os.clock() end end)
UserInputService.InputBegan:Connect(function(input) if input.UserInputType.Name:find("^Gamepad") then lastPadAt = os.clock() end end)

RunService:BindToRenderStep("GamepadControls", Enum.RenderPriority.Input.Value, function(dt)
	if not UserInputService.GamepadEnabled then return end
	local l, r = stick()
	-- the scoreboard: SELECT held past a tap
	if selectAt and not boardUp and os.clock() - selectAt >= HOLD_BOARD and not menuUp() then
		boardUp = true; TouchInput.press("Board", true)
	end
	-- look (not while the emote wheel aims with the same stick)
	local wheel = player.PlayerGui:FindFirstChild("EmoteWheel")
	if not menuUp() and not (wheel and wheel.Enabled) then
		local v = shaped(r)
		if v.Magnitude > 0 then
			local ok, gs = pcall(function() return UserSettings():GetService("UserGameSettings") end)
			local ms = (ok and gs and gs.MouseSensitivity) or 1
			local k = (ClientSettings.get("PadLook") or 1) / math.max(SENS * ms, 1e-4)
			TouchInput.addLook(v.X * math.rad(YAW_RATE) * dt * k, -v.Y * math.rad(PITCH_RATE) * dt * k)
		end
	end
	-- sprint switches itself off when you stop moving
	if sprintOn and l.Magnitude < 0.2 then sprintOn = false; TouchInput.press("Sprint", false) end
	-- the virtual cursor wherever the game frees the mouse (menus, the vote, pop-ups)
	local free = UserInputService.MouseIconEnabled and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter and not (wheel and wheel.Enabled)
	local want = free and os.clock() - lastPadAt < 30
	local ok, on = pcall(function() return GamepadService.GamepadCursorEnabled end)
	on = ok and on
	if want and not on and (not cursorWanted or os.clock() - lastPadAt < 0.2) then
		pcall(function() GamepadService:EnableGamepadCursor(nil) end)
	elseif not free and on then
		pcall(function() GamepadService:DisableGamepadCursor() end)
	end
	cursorWanted = want
end)

-- a fresh body: nothing stays toggled
player.CharacterAdded:Connect(function()
	sprintOn, crouchOn = false, false
	TouchInput.press("Crouch", false)
end)
