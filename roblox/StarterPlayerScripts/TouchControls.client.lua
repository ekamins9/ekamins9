--[[ TOUCH CONTROLS — on a phone or a tablet (a touch screen, no keyboard), the
     fight on buttons under your right thumb; Roblox's own stick under your left
     moves you. Everything goes through ReplicatedStorage ▸ TouchInput, so a
     button does exactly what its key does.

       right thumb   BLOCK (hold) in the corner, with ◀ SWING and SWING ▶ (the
                     side of the swing), STAB, OVERHEAD, KICK, FEINT and DODGE
                     around it
       left side     SPRINT (hold) and JUMP above the stick
       top left      MENU (the M key)
       a drag anywhere else on the screen turns the camera

     Shown only while you have a body and the menu is closed. Roblox's own jump
     button is hidden (ours sits where it can't be hit by mistake). ]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TouchInput = require(ReplicatedStorage:WaitForChild("TouchInput"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local player = Players.LocalPlayer

local LOOK_SENS = 1.0   -- a finger's drag against a mouse's (CameraRig scales both the same)

local gui = Instance.new("ScreenGui")
gui.Name = "TouchControls"
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Parent = gui

local COL = {
	block = Theme.BLUE, swing = Color3.fromRGB(214, 70, 60), move = Color3.fromRGB(60, 66, 90),
	other = Color3.fromRGB(40, 46, 70),
}

local function pad(anchor, pos, size)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.AnchorPoint = anchor
	f.Position = pos
	f.Size = size
	f.Parent = gui
	return f
end

-- a round button: centre (x, y) in its pad, diameter d; hold = it reports
-- being let go too (BLOCK, SPRINT)
local function round(parent, label, x, y, d, color, action, side, hold)
	local b = Instance.new("TextButton")
	b.Name = label
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(d, d)
	b.BackgroundColor3 = color
	b.BackgroundTransparency = 0.25
	b.AutoButtonColor = false
	b.Text = label
	b.Font = Theme.FONT_TITLE
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b:SetAttribute("Silent", true)   -- (no menu click sound: UIClicks)
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0.5, 0)
	local pad2 = Instance.new("UIPadding", b)
	pad2.PaddingLeft, pad2.PaddingRight = UDim.new(0.16, 0), UDim.new(0.16, 0)
	pad2.PaddingTop, pad2.PaddingBottom = UDim.new(0.3, 0), UDim.new(0.3, 0)
	local stroke = Instance.new("UIStroke", b)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.55
	stroke.Thickness = 2
	local down = false
	local function set(on)
		if on == down then return end
		down = on
		b.BackgroundTransparency = on and 0.05 or 0.25
		stroke.Transparency = on and 0.1 or 0.55
		if on or hold then TouchInput.press(action, on, side) end
	end
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then set(true) end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then set(false) end
	end)
	return b
end

-- the right thumb's pad (bottom right): BLOCK in the corner, the rest around it
local right = pad(Vector2.new(1, 1), UDim2.new(1, -8, 1, -8), UDim2.fromOffset(340, 330))
round(right, "BLOCK", 285, 270, 96, COL.block, "Block", nil, true)
-- (held: a bow is drawn while a SWING button is down and loosed when it's let go)
round(right, "◀ SWING", 178, 272, 76, COL.swing, "Swing", "Left", true)
round(right, "SWING ▶", 283, 163, 76, COL.swing, "Swing", "Right", true)
round(right, "STAB", 205, 190, 62, COL.swing, "Stab")
round(right, "OVER HEAD", 85, 275, 62, COL.swing, "Overhead")
round(right, "KICK", 110, 185, 56, COL.other, "Kick")
round(right, "FEINT", 180, 105, 52, COL.other, "Feint")
round(right, "DODGE", 283, 68, 56, COL.move, "Dodge")

-- the left: SPRINT and JUMP above the stick
local left = pad(Vector2.new(0, 1), UDim2.new(0, 12, 1, -230), UDim2.fromOffset(170, 80))
round(left, "SPRINT", 40, 40, 64, COL.move, "Sprint", nil, true)
round(left, "JUMP", 120, 40, 58, COL.move, "Jump")

-- MENU, top left under the Roblox buttons
local menu = Instance.new("TextButton")
menu.Name = "Menu"
menu.Size = UDim2.fromOffset(96, 40)
menu.Position = UDim2.fromOffset(12, 8)
menu.BackgroundColor3 = Theme.GLASS
menu.BackgroundTransparency = 0.15
menu.Text = "☰ MENU"
menu.Font = Theme.FONT_TITLE
menu.TextSize = 18
menu.TextColor3 = Color3.new(1, 1, 1)
menu.Parent = gui
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 10)
menu.Activated:Connect(function() if _G.HubMenuToggle then _G.HubMenuToggle() end end)

--------------------------------------------------------------------
--  THE CAMERA: a drag on open screen (not on a button, not the stick's half)
--------------------------------------------------------------------
local looking = {}   -- [touch] = true
UserInputService.TouchStarted:Connect(function(touch, gp)
	if gp or not gui.Enabled then return end
	local w = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	-- the left ~40% belongs to Roblox's movement stick
	if touch.Position.X > w * 0.4 then looking[touch] = true end
end)
UserInputService.TouchMoved:Connect(function(touch)
	if looking[touch] then TouchInput.addLook(touch.Delta.X * LOOK_SENS, touch.Delta.Y * LOOK_SENS) end
end)
UserInputService.TouchEnded:Connect(function(touch) looking[touch] = nil end)

--------------------------------------------------------------------
--  WHEN TO SHOW: a touch screen, a living body, the menu shut
--------------------------------------------------------------------
local function hideRobloxJump()
	local tg = player.PlayerGui:FindFirstChild("TouchGui")
	local frame = tg and tg:FindFirstChild("TouchControlFrame")
	local jb = frame and frame:FindFirstChild("JumpButton")
	if jb and jb.Visible then jb.Visible = false end
end

local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 0.2 then return end
	acc = 0
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local menuOpen = _G.HubMenuOpen and _G.HubMenuOpen() or false
	local on = TouchInput.active() and hum ~= nil and hum.Health > 0 and not menuOpen
	gui.Enabled = TouchInput.active()
	right.Visible, left.Visible = on, on
	menu.Visible = TouchInput.active() and not menuOpen
	if not on then
		-- nothing stays held down while hidden
		for t in pairs(looking) do looking[t] = nil end
	end
	-- bigger thumbs on bigger screens, a little smaller on small phones
	local cam = workspace.CurrentCamera
	if cam then scale.Scale = math.clamp(cam.ViewportSize.Y / 430, 0.72, 1.35) end
	if TouchInput.active() then hideRobloxJump() end
end)
