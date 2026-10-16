--[[ DEVICE — what this player is holding, and how big the game's screens should be drawn on it.

       Device.kind()        "phone" | "tablet" | "console" | "desktop"
       Device.touch()       a touch screen (no keyboard), or Studio's phone preview
       Device.console()     a TV (Roblox's ten-foot interface)
       Device.viewport()    the screen in points (Studio's preview: a phone's, see below)
       Device.pixel()       real pixels per point of that screen (1, except in the preview)
       Device.hudScale()    the UIScale every game screen is drawn at (StarterPlayerScripts ▸
                            UIFit puts it on each): 1 on a desktop; a phone's is smaller, so
                            things fit and the fight shows through; a TV's a little bigger, for
                            the couch
       Device.touchScale()  the touch buttons' size (TouchControls), × the Button size setting
       Device.changed       :Connect(fn) when the screen or the setting changes

     STUDIO'S PHONE PREVIEW: ReplicatedStorage attribute PhoneSim = true makes this client
     behave as a phone held sideways (390 points tall: an iPhone's), the touch controls on,
     everything drawn at a phone's proportions (narrower than a real phone, so what fits here
     fits there). HubMenu letterboxes itself the same way. ]]

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Device = {}
local ev = Instance.new("BindableEvent")
Device.changed = ev.Event

local PHONE_H = 390   -- a phone on its side, in points

function Device.sim()
	return RunService:IsStudio() and ReplicatedStorage:GetAttribute("PhoneSim") == true
end
local function realViewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1600, 900)
end
function Device.pixel()
	if not Device.sim() then return 1 end
	return math.max(realViewport().Y / PHONE_H, 0.1)
end
function Device.viewport()
	local v = realViewport()
	if Device.sim() then return v / Device.pixel() end
	return v
end
function Device.touch()
	return Device.sim() or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
end
function Device.console()
	local ok, on = pcall(function() return GuiService:IsTenFootInterface() end)
	return ok and on == true
end
function Device.kind()
	if Device.console() then return "console" end
	local v = Device.viewport()
	if Device.touch() then return math.min(v.X, v.Y) < 500 and "phone" or "tablet" end
	return "desktop"
end

local settings
local function setting(key, default)
	settings = settings or (function()
		local ok, m = pcall(function() return require(ReplicatedStorage:WaitForChild("ClientSettings", 5)) end)
		return ok and m or false
	end)()
	if not settings then return default end
	local ok, v = pcall(settings.get, key)
	return (ok and v ~= nil) and v or default
end

function Device.hudScale()
	local v = Device.viewport()
	local k = Device.kind()
	local s = 1
	if k == "console" then s = 1.15
	elseif k == "phone" then s = math.clamp(v.Y / 560, 0.6, 0.8)
	elseif k == "tablet" or v.Y < 700 then s = math.clamp(v.Y / 780, 0.8, 1) end
	return s * Device.pixel()
end
function Device.touchScale()
	local v = Device.viewport()
	return math.clamp(v.Y / PHONE_H, 0.85, 1.35) * (setting("TouchSize", 1) or 1) * Device.pixel()
end

-- (the screen turned, the preview switched, a setting moved: say so)
local function fire() ev:Fire() end
local function watchCam()
	local cam = workspace.CurrentCamera
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fire) end
end
watchCam()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() watchCam(); fire() end)
ReplicatedStorage:GetAttributeChangedSignal("PhoneSim"):Connect(fire)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(fire)
task.spawn(function()
	local ok, m = pcall(function() return require(ReplicatedStorage:WaitForChild("ClientSettings", 10)) end)
	if ok and m and m.onChanged then m.onChanged(function(key) if key == "TouchSize" then fire() end end) end
end)

return Device
