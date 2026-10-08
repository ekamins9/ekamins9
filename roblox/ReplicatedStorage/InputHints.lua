--[[ INPUT HINTS — what to call a control on screen, for whatever the player
     holds: a keyboard and mouse (their own binds), a controller (the layout
     below, Xbox letters or PlayStation shapes), or a touch screen (the name on
     the button). Every hint in the game asks here, so "press [F]" becomes
     "press [B]" the moment a controller is picked up.

       InputHints.mode()          "Keyboard" | "Gamepad" | "Touch"
       InputHints.name(action)    "F" · "B" · "DODGE"
       InputHints.say(action)     "[F]" · "[B]" · "the DODGE button"
       InputHints.fill(text)      "{Dodge} to dodge" → "[F] to dodge" (any action in braces)
       InputHints.changed         :Connect(fn(mode)) when the player switches
       InputHints.PAD             action → KeyCode: the controller layout
                                  (StarterPlayerScripts ▸ GamepadControls reads it)

     Actions are ClientSettings.KEYS' (Swing, Stab, Overhead, Underhand, Feint,
     Kick, Sprint, Dodge, Jump, Crouch, View, Pickup, Emote, Cursor, Reload…)
     plus Block, Menu, Board (the scoreboard) and Weapons (switching). ]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputHints = {}
local K = Enum.KeyCode

-- THE CONTROLLER LAYOUT (Mordhau-ish): attacks on the triggers and bumpers, the
-- face buttons move you, the sticks click for sprint and the view
InputHints.PAD = {
	Swing = K.ButtonR2, Stab = K.ButtonR1, Overhead = K.ButtonL1, Block = K.ButtonL2,
	Jump = K.ButtonA, Dodge = K.ButtonB, Kick = K.ButtonX, Feint = K.ButtonY,
	Sprint = K.ButtonL3, View = K.ButtonR3, Emote = K.DPadUp, Crouch = K.DPadDown,
	Menu = K.ButtonSelect, Board = K.ButtonSelect, Pickup = K.ButtonX, Reload = K.ButtonR2, Stance = K.DPadLeft,
}
-- what the button is called (Xbox / PlayStation)
local XBOX = {ButtonA = "A", ButtonB = "B", ButtonX = "X", ButtonY = "Y", ButtonL1 = "LB", ButtonR1 = "RB", ButtonL2 = "LT", ButtonR2 = "RT",
	ButtonL3 = "LS", ButtonR3 = "RS", DPadUp = "D-PAD ↑", DPadDown = "D-PAD ↓", DPadLeft = "D-PAD ←", DPadRight = "D-PAD →", ButtonSelect = "VIEW"}
local PS = {ButtonA = "✕", ButtonB = "○", ButtonX = "□", ButtonY = "△", ButtonL1 = "L1", ButtonR1 = "R1", ButtonL2 = "L2", ButtonR2 = "R2",
	ButtonL3 = "L3", ButtonR3 = "R3", DPadUp = "D-PAD ↑", DPadDown = "D-PAD ↓", DPadLeft = "D-PAD ←", DPadRight = "D-PAD →", ButtonSelect = "TOUCHPAD"}
-- (special cases said in words)
local PAD_WORDS = {Underhand = "%s + RIGHT STICK ↓", SideFlip = "RIGHT STICK ← →", Weapons = "D-PAD ← →", Board = "HOLD %s", Cursor = "SELECT"}
-- the touch buttons' names (StarterPlayerScripts ▸ TouchControls)
local TOUCH = {Swing = "SWING", Stab = "STAB", Overhead = "OVERHEAD", Underhand = "SWING", Block = "BLOCK", Feint = "FEINT", Kick = "KICK",
	Dodge = "DODGE", Jump = "JUMP", Sprint = "SPRINT", Crouch = "CROUCH", View = "VIEW", Emote = "EMOTE", Menu = "MENU", Board = "SCORES",
	Pickup = "PICK UP", Weapons = "weapon", Cursor = "MENU", Reload = "SWING"}
-- keyboard binds, the way a player says them
local NICE = {MouseButton1 = "LEFT MOUSE", MouseButton3 = "MIDDLE MOUSE", MouseWheelUp = "SCROLL UP", MouseWheelDown = "SCROLL DOWN",
	LeftAlt = "LEFT ALT", RightAlt = "RIGHT ALT", LeftShift = "LEFT SHIFT", LeftControl = "LEFT CTRL", Space = "SPACE"}
local FIXED_KEYS = {Block = "RIGHT MOUSE", Menu = "M", Board = "TAB", Weapons = "1 · 2"}

local settings
local function key(action)
	settings = settings or require(ReplicatedStorage:WaitForChild("ClientSettings"))
	return settings.get("Key_" .. action)
end

-- PlayStation or Xbox: Roblox names a PlayStation pad's buttons by their shapes
local playstation = nil
local function isPlayStation()
	if playstation == nil then
		local ok, s = pcall(function() return UserInputService:GetStringForKeyCode(K.ButtonA) end)
		playstation = ok and type(s) == "string" and (s:find("Cross") ~= nil or s == "✕")
	end
	return playstation
end

local mode = "Keyboard"
local function decide(t)
	if t == nil then return end
	local n = t.Name
	if n:find("^Gamepad") then return "Gamepad" end
	if t == Enum.UserInputType.Touch then return "Touch" end
	if t == Enum.UserInputType.Keyboard or n:find("^Mouse") then return "Keyboard" end
	return nil
end
do
	local first = decide(UserInputService:GetLastInputType())
	if first then mode = first
	elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then mode = "Touch"
	elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then mode = "Gamepad" end
end
local ev = Instance.new("BindableEvent")
InputHints.changed = ev.Event
UserInputService.LastInputTypeChanged:Connect(function(t)
	local m = decide(t)
	-- (a mouse twitch on a touch laptop doesn't flip it; a real key or click does)
	if m and m ~= mode then mode = m; ev:Fire(mode) end
end)

function InputHints.mode() return mode end

function InputHints.name(action)
	if mode == "Gamepad" then
		local names = isPlayStation() and PS or XBOX
		local code = InputHints.PAD[action]
		local btn = code and (names[code.Name] or code.Name) or nil
		local words = PAD_WORDS[action]
		if words then return string.format(words, btn or (names.ButtonR2)) end
		return btn or string.upper(action)
	elseif mode == "Touch" then
		return TOUCH[action] or string.upper(action)
	end
	if FIXED_KEYS[action] then return FIXED_KEYS[action] end
	local n = key(action) or action
	return NICE[n] or string.upper(n)
end

function InputHints.say(action)
	if mode == "Touch" then return "the " .. InputHints.name(action) .. " button" end
	return "[" .. InputHints.name(action) .. "]"
end

function InputHints.fill(text)
	return (string.gsub(text, "{(%a+)}", function(a) return InputHints.say(a) end))
end

return InputHints
