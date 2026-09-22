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
	{key = "FOV",     label = "First-person FOV", min = 70, max = 110, step = 1, hint = "degrees"},
}

-- rebindable actions (block stays on right mouse; left click cycles attacks)
ClientSettings.KEYS = {
	{key = "Sprint",     label = "Sprint",        default = "LeftShift"},
	{key = "Dodge",      label = "Dodge",         default = "Space"},
	{key = "Crouch",     label = "Crouch",        default = "LeftControl"},
	{key = "Kick",       label = "Kick",          default = "G"},
	{key = "Pickup",     label = "Pick up weapon",default = "V"},
	{key = "LeftSwing",  label = "Left swing",    default = "Q"},
	{key = "RightSwing", label = "Right swing",   default = "E"},
	{key = "Overhead",   label = "Overhead",      default = "F"},
	{key = "Stab",       label = "Stab",          default = "X"},
}

ClientSettings.DEFAULTS = {
	Bob = 1, Sway = 1, Roll = 1, Shake = 1, Breathe = 1, FPClunk = 1, FOV = 100,
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

local function valid(key, v)
	local s = sliderSpec(key)
	if s then
		return type(v) == "number" and v == v and v >= s.min and v <= s.max
	end
	if key:sub(1, 4) == "Key_" then
		return type(v) == "string" and Enum.KeyCode[v] ~= nil
	end
	return false
end
ClientSettings.valid = valid

function ClientSettings.get(key)
	local v = values[key]
	if v == nil then v = ClientSettings.DEFAULTS[key] end
	return v
end

function ClientSettings.key(action)
	local name = ClientSettings.get("Key_" .. action)
	local ok, kc = pcall(function() return Enum.KeyCode[name] end)
	return ok and kc or Enum.KeyCode.Unknown
end

-- which action a pressed key means, if any
function ClientSettings.actionFor(keyCode)
	for _, k in ipairs(ClientSettings.KEYS) do
		if ClientSettings.get("Key_" .. k.key) == keyCode.Name then return k.key end
	end
	return nil
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
		for k, v in pairs(saved) do
			if valid(k, v) then
				values[k] = v
				for _, fn in ipairs(listeners) do task.spawn(fn, k, v) end
			end
		end
	end
end

return ClientSettings
