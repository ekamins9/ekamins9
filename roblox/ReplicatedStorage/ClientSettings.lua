--[[ CLIENT SETTINGS — per-player camera feel + keybinds, shared by every
     client script (CameraRig, CombatClient, Movement, LoadoutMenu). All of
     those require this ONE module, so a change in the settings panel is
     seen everywhere the same frame.

       ClientSettings.get("Bob")            -> number (multiplier, 1 = default feel)
       ClientSettings.key("Sprint")         -> Enum.KeyCode
       ClientSettings.actionFor(keyCode)    -> "Sprint" | "Dodge" | "LeftSwing" | … | nil
       ClientSettings.set("Bob", 0)         -- fires onChanged, queues a save
       ClientSettings.onChanged(fn)         -- fn(key, value)
       ClientSettings.load()                -- pull saved values from the server (once)

     SLIDERS and KEYS below are what the settings panel renders, so adding
     a row here is all a new setting needs. Saved through SettingsServer
     (DataStore) when one exists; otherwise they last the session. ]]

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientSettings = {}

-- camera / feel multipliers (1 = the tuned default; 0 turns the effect off)
ClientSettings.SLIDERS = {
	{key = "Bob",     label = "Head bob",       min = 0,  max = 2,   hint = "footstep clunk on the camera and torso"},
	{key = "Sway",    label = "Weapon sway",    min = 0,  max = 2,   hint = "arms lag behind the mouse"},
	{key = "Roll",    label = "Camera roll",    min = 0,  max = 2,   hint = "tilt when turning and strafing"},
	{key = "Shake",   label = "Impact shake",   min = 0,  max = 2,   hint = "flinch on hits, kick on swings"},
	{key = "Breathe", label = "Idle breathing", min = 0,  max = 2,   hint = "slow drift while standing still"},
	{key = "FPClunk", label = "First-person clunk boost", min = 0, max = 2, hint = "extra step weight in first person"},
	{key = "Music",   label = "Music volume",   min = 0,  max = 2,   hint = "the score: the courtyard, battles, the horde, bosses"},
	{key = "UISounds", label = "Menu sounds",   min = 0,  max = 2,   hint = "clicks, crate spins, eggs cracking, reveals"},
	{key = "PadLook", label = "Controller look speed", min = 0.3, max = 2.5, hint = "how fast the right stick turns you (a controller)"},
	{key = "FOV",     label = "First-person FOV", min = 70, max = 110, step = 1, hint = "70 is already wide; higher pulls the view back to show more of the sword (looking down slides the eye forward again, so you see your front, never the top of your chest)"},
}

-- rebindable actions. Block stays on right mouse. The SIDE of an attack
-- (left/right swing, stab, overhead, underhand) is your DefaultSide, flipped
-- while the SideFlip key is held (Modifier mode) — or, in Mouse mode, the way
-- the mouse was moving when you pressed.
-- A bind is a KeyCode name ("Q", "LeftAlt"…) or a mouse name: "MouseButton1"
-- (left), "MouseButton3" (middle), "MouseWheelUp", "MouseWheelDown". Right
-- mouse is always block. Roblox does NOT expose the side buttons (Mouse 4/5)
-- to games — bind them to a key in your mouse software (e.g. Mouse4 → X) and
-- bind that key here.
ClientSettings.KEYS = {
	{key = "Swing",      label = "Swing",            default = "MouseButton1"},
	{key = "Stab",       label = "Stab",             default = "MouseWheelUp"},
	{key = "Overhead",   label = "Overhead",         default = "MouseWheelDown"},
	{key = "Underhand",  label = "Underhand",        default = "X"},
	{key = "Feint",      label = "Feint (cancel windup)", default = "Q"},
	{key = "SideFlip",   label = "Opposite side (hold)", default = "LeftAlt"},
	{key = "Kick",       label = "Kick",             default = "G"},
	{key = "Sprint",     label = "Sprint",           default = "LeftShift"},
	{key = "Dodge",      label = "Dodge",            default = "F"},
	{key = "Jump",       label = "Jump / stand up",  default = "Space"},
	{key = "Crouch",     label = "Crouch",           default = "LeftControl"},
	{key = "View",       label = "First / third person", default = "Z"},
	{key = "Pickup",     label = "Pick up weapon",   default = "V"},
	{key = "Emote",      label = "Emote wheel",      default = "B"},
	{key = "Cursor",     label = "Free the mouse (toggle)", default = "T"},
	{key = "Profile",    label = "Profile of who you look at", default = "P"},
	{key = "Reload",     label = "Reload the crossbow · meditate (hold)", default = "R"},
	{key = "Stance",     label = "Staff: magic / melee", default = "H"},
}
ClientSettings.MOUSE_NAMES = {MouseButton1 = true, MouseButton3 = true, MouseWheelUp = true, MouseWheelDown = true}

-- multiple-choice settings (rendered as cycling buttons)
ClientSettings.CHOICES = {
	{key = "SideMode",    label = "Attack side", options = {"Mouse", "Modifier"},
		hint = "Mouse: the way your mouse was moving when you pressed picks left/right (still = alternate). Modifier: always your default side; hold the Opposite-side key for the other."},
	{key = "DefaultSide", label = "Default side", options = {"Right", "Left"},
		hint = "Modifier mode: the side you get without the Opposite-side key held. Mouse mode: what a held Opposite-side key flips away from."},
	{key = "Companions", label = "Companions", options = {"All", "Mine", "None"},
		hint = "Whose companions you see following them around: everyone's, only yours, or none."},
	{key = "DodgeTap",   label = "Double-tap dodge", options = {"On", "Off"},
		hint = "Double-tap A, D or S to dodge that way (the Dodge key works either way)."},
	-- PRIVACY: the server checks these (SettingsServer puts them on the player as Priv_<key>)
	{key = "PartyInvites", label = "Party invites from", options = {"Everyone", "Friends", "Nobody"},
		hint = "Who can invite you to their party: anyone, only your Roblox friends, or nobody."},
	{key = "TradeRequests", label = "Trade requests from", options = {"Everyone", "Friends", "Nobody"},
		hint = "Who can ask you to trade: anyone, only your Roblox friends, or nobody."},
}
-- the settings the server enforces (who may invite you, trade with you)
ClientSettings.PRIVACY = {"PartyInvites", "TradeRequests"}

ClientSettings.DEFAULTS = {
	Bob = 1, Sway = 1, Roll = 1, Shake = 1, Breathe = 1, FPClunk = 1, FOV = 70, Music = 1, UISounds = 1, PadLook = 1,
	SideMode = "Modifier", DefaultSide = "Right", Companions = "All", DodgeTap = "On",
	PartyInvites = "Everyone", TradeRequests = "Everyone",
}
for _, k in ipairs(ClientSettings.KEYS) do ClientSettings.DEFAULTS["Key_" .. k.key] = k.default end

local values = {}
for k, v in pairs(ClientSettings.DEFAULTS) do values[k] = v end
local listeners = {}
local loaded = false
local saveQueued = false

local function sliderSpec(key)
	for _, s in ipairs(ClientSettings.SLIDERS) do if s.key == key then return s end end
	return nil
end

local function choiceSpec(key)
	for _, c in ipairs(ClientSettings.CHOICES) do if c.key == key then return c end end
	return nil
end

local function isKeyName(v)
	if ClientSettings.MOUSE_NAMES[v] then return true end
	local ok, kc = pcall(function() return Enum.KeyCode[v] end)
	return ok and kc ~= nil
end

local function valid(key, v)
	local s = sliderSpec(key)
	if s then
		return type(v) == "number" and v == v and v >= s.min and v <= s.max
	end
	local c = choiceSpec(key)
	if c then
		for _, o in ipairs(c.options) do if o == v then return true end end
		return false
	end
	if key:sub(1, 4) == "Key_" then
		return type(v) == "string" and isKeyName(v)
	end
	return false
end
ClientSettings.valid = valid

-- the bind name an input event corresponds to (InputBegan for keys / mouse
-- buttons, InputChanged for the wheel), or nil
function ClientSettings.inputName(input)
	local t = input.UserInputType
	if t == Enum.UserInputType.Keyboard then return input.KeyCode.Name end
	if t == Enum.UserInputType.MouseButton1 then return "MouseButton1" end
	if t == Enum.UserInputType.MouseButton3 then return "MouseButton3" end
	if t == Enum.UserInputType.MouseWheel then
		if input.Position.Z > 0 then return "MouseWheelUp" elseif input.Position.Z < 0 then return "MouseWheelDown" end
	end
	return nil
end

-- is the bind for this action currently held (keys and middle mouse only)
function ClientSettings.isDown(action)
	local name = ClientSettings.get("Key_" .. action)
	if name == "MouseButton1" or name == "MouseButton3" then
		return game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType[name])
	end
	if ClientSettings.MOUSE_NAMES[name] then return false end
	local ok, kc = pcall(function() return Enum.KeyCode[name] end)
	return ok and kc ~= nil and game:GetService("UserInputService"):IsKeyDown(kc)
end

function ClientSettings.get(key)
	local v = values[key]
	if v == nil then v = ClientSettings.DEFAULTS[key] end
	return v
end

-- the KeyCode for an action (Unknown when it's bound to the mouse)
function ClientSettings.key(action)
	local name = ClientSettings.get("Key_" .. action)
	if ClientSettings.MOUSE_NAMES[name] then return Enum.KeyCode.Unknown end
	local ok, kc = pcall(function() return Enum.KeyCode[name] end)
	return ok and kc or Enum.KeyCode.Unknown
end

local function actionForName(name)
	if not name then return nil end
	for _, k in ipairs(ClientSettings.KEYS) do
		if ClientSettings.get("Key_" .. k.key) == name then return k.key end
	end
	return nil
end

-- which action a pressed key means, if any
function ClientSettings.actionFor(keyCode)
	return actionForName(keyCode.Name)
end

-- same, from a raw InputObject (handles the wheel and middle mouse too)
function ClientSettings.actionForInput(input)
	return actionForName(ClientSettings.inputName(input))
end

-- is the mouse wheel bound to anything (then the camera must not zoom on it)
function ClientSettings.wheelBound()
	return actionForName("MouseWheelUp") ~= nil or actionForName("MouseWheelDown") ~= nil
end

function ClientSettings.onChanged(fn)
	table.insert(listeners, fn)
	return {Disconnect = function()
		for i, f in ipairs(listeners) do if f == fn then table.remove(listeners, i); break end end
	end}
end

local function queueSave()
	if saveQueued or RunService:IsServer() then return end
	saveQueued = true
	task.delay(1.5, function()
		saveQueued = false
		local ev = ReplicatedStorage:FindFirstChild("SettingsEvent")
		if ev then
			local out = {}
			for k, v in pairs(values) do out[k] = v end
			ev:FireServer("Save", out)
		end
	end)
end

function ClientSettings.set(key, v)
	if not valid(key, v) then return false end
	local s = sliderSpec(key)
	if s and s.step then v = math.floor(v / s.step + 0.5) * s.step end
	if values[key] == v then return true end
	values[key] = v
	for _, fn in ipairs(listeners) do task.spawn(fn, key, v) end
	queueSave()
	return true
end

function ClientSettings.reset()
	for k, v in pairs(ClientSettings.DEFAULTS) do ClientSettings.set(k, v) end
end

-- pull saved values once; safe to call from several scripts
function ClientSettings.load()
	if loaded or RunService:IsServer() then return end
	loaded = true
	local rf = ReplicatedStorage:FindFirstChild("SettingsRemote")
	if not rf then return end
	local ok, saved = pcall(rf.InvokeServer, rf, "Load")
	if ok and type(saved) == "table" then
		-- settings saved before there was a jump had dodge on Space: Space is the jump now
		if saved.Key_Jump == nil and saved.Key_Dodge == "Space" then saved.Key_Dodge = ClientSettings.DEFAULTS.Key_Dodge end
		for k, v in pairs(saved) do
			if valid(k, v) then
				values[k] = v
				for _, fn in ipairs(listeners) do task.spawn(fn, k, v) end
			end
		end
	end
end

return ClientSettings
