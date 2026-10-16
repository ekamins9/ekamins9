--[[ UI FIT — every game screen drawn at the size this device wants (ReplicatedStorage ▸
     Device.hudScale): the same on a desktop, smaller on a phone (so it all fits on the screen
     and the fight shows through), a little bigger on a TV. A UIScale named "UIFit" on each of
     our ScreenGuis zooms its whole canvas (positions too: a thing anchored to a corner stays in
     it). Left alone: the menu (HubMenu fits itself), the touch buttons (TouchControls sizes
     itself), Roblox's own, and any ScreenGui with the attribute NoFit. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Device = require(ReplicatedStorage:WaitForChild("Device"))
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local SKIP = {HubMenu = true, TouchControls = true, TouchGui = true, Freecam = true, Chat = true, BubbleChat = true,
	ExperienceChat = true, ProximityPrompts = true}

local scale = Device.hudScale()
local function fit(g)
	if not g:IsA("ScreenGui") or SKIP[g.Name] or g:GetAttribute("NoFit") then return end
	local s = g:FindFirstChild("UIFit")
	if math.abs(scale - 1) < 0.001 then
		if s then s:Destroy() end
		return
	end
	if not s then
		-- (a ScreenGui that already zooms itself with a UIScale of its own is left to it)
		for _, c in ipairs(g:GetChildren()) do if c:IsA("UIScale") then return end end
		s = Instance.new("UIScale")
		s.Name = "UIFit"
		s.Parent = g
	end
	s.Scale = scale
end
local function all()
	scale = Device.hudScale()
	for _, g in ipairs(playerGui:GetChildren()) do fit(g) end
end
playerGui.ChildAdded:Connect(function(g) task.defer(fit, g) end)
Device.changed:Connect(all)
all()
