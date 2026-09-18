--[[ DEBUG FLAGS — runtime-toggleable debug switches shared by every script.
     Backed by attributes on ReplicatedStorage.Debug (a Configuration
     instance), so they replicate server → client and can be flipped live
     without touching code:

       • Studio:  select ReplicatedStorage.Debug, tick boxes under
                  Properties → Attributes
       • F9 console, SERVER tab (everyone sees it):
             game.ReplicatedStorage.Debug:SetAttribute("Rays", true)
       • F9 console, CLIENT tab (only you; client-side flags like Rays):
             same line

     Flags:
       Logs       print() chatter from combat scripts
       Rays       draw blade sweep rays (client-side visual)
       GuardHull  show the block hull around weapons
       Hitbox     show weapon Hitbox parts
       TurnCap    print when the camera turn cap engages

     The instance is created with defaults the first time a SERVER script
     requires this module (WalkSpeedGovernor does, at startup). Missing
     attributes are filled in, existing ones are left alone, so values you
     set in Studio persist. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local DEFAULTS = {
	Logs      = true,
	Rays      = false,
	GuardHull = true,
	Hitbox    = false,
	TurnCap   = false,
}

local node = ReplicatedStorage:FindFirstChild("Debug")
if RunService:IsServer() then
	if not node then
		node = Instance.new("Configuration")
		node.Name = "Debug"
		node.Parent = ReplicatedStorage
	end
	for k, v in pairs(DEFAULTS) do
		if node:GetAttribute(k) == nil then node:SetAttribute(k, v) end
	end
else
	node = node or ReplicatedStorage:WaitForChild("Debug")
end

local DebugFlags = {}

function DebugFlags.get(name)
	local v = node:GetAttribute(name)
	if v == nil then return DEFAULTS[name] end
	return v
end

function DebugFlags.set(name, value)
	node:SetAttribute(name, value)
end

function DebugFlags.log(tag, ...)
	if DebugFlags.get("Logs") then print("[" .. tag .. "]", ...) end
end

-- calls fn(value) now and again whenever the flag changes; returns the connection
function DebugFlags.onChanged(name, fn)
	fn(DebugFlags.get(name))
	return node:GetAttributeChangedSignal(name):Connect(function()
		fn(DebugFlags.get(name))
	end)
end

return DebugFlags
