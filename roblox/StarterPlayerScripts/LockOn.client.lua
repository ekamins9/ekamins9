--[[ LOCK-ON (client) — the controls and the mark for ReplicatedStorage ▸ LockOn.
       the Lock key (middle mouse by default) · a controller's right-stick click · the LOCK
       button on a touch screen: lock onto the foe in front of you, or let go
       a flick of the right stick / a swipe across the screen while locked: the next foe that way
     The locked foe wears a reticle (brackets turning round them, a dot over the head), red,
     on top of everything; LOCKED · NAME shows under the crosshair a moment. Every attack
     pressed on a touch screen or a controller is the aim assist's moment (LockOn.attacked). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LockOn = require(ReplicatedStorage:WaitForChild("LockOn"))
local TouchInput = require(ReplicatedStorage:WaitForChild("TouchInput"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player = Players.LocalPlayer
local RED = Color3.fromRGB(255, 70, 60)

local function menuUp() return _G.HubMenuOpen and _G.HubMenuOpen() end
local function toggle()
	if menuUp() then return end
	local c = player.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return end
	LockOn.toggle()
end

-- the key (a mouse button or a key, rebindable: Settings)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	local k = ClientSettings.get("Key_Lock") or "MouseButton3"
	if input.KeyCode.Name == k or input.UserInputType.Name == k then toggle() end
end)
-- the touch button and the controller (through the action bus)
local ATTACKS = {Swing = true, Stab = true, Overhead = true, Underhand = true}
TouchInput.changed:Connect(function(action, down, side)
	if action == "Lock" and down then
		if side == "Next" then LockOn.cycle(1) elseif side == "Prev" then LockOn.cycle(-1) else toggle() end
	elseif ATTACKS[action] and down then
		LockOn.attacked()
	end
end)
player.CharacterAdded:Connect(function() LockOn.lock(nil) end)

--------------------------------------------------------------------
--  THE MARK
--------------------------------------------------------------------
local mark = Instance.new("BillboardGui")
mark.Name = "LockOnMark"
mark.AlwaysOnTop = true
mark.LightInfluence = 0
mark.Size = UDim2.fromOffset(110, 110)
mark.ResetOnSpawn = false
mark.Enabled = false
mark.Parent = player:WaitForChild("PlayerGui")
local spin = Instance.new("Frame")
spin.BackgroundTransparency = 1
spin.AnchorPoint = Vector2.new(0.5, 0.5)
spin.Position = UDim2.fromScale(0.5, 0.5)
spin.Size = UDim2.fromScale(1, 1)
spin.Parent = mark
-- four brackets
for k = 0, 3 do
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.Rotation = k * 90
	holder.Parent = spin
	for _, sz in ipairs({UDim2.fromOffset(22, 5), UDim2.fromOffset(5, 22)}) do
		local b = Instance.new("Frame")
		b.BorderSizePixel = 0
		b.BackgroundColor3 = RED
		b.Size = sz
		b.Position = UDim2.fromOffset(8, 8)
		b.Parent = holder
		local st = Instance.new("UIStroke"); st.Color = Color3.new(0, 0, 0); st.Transparency = 0.4; st.Thickness = 1.5; st.Parent = b
	end
end
local dot = Instance.new("Frame")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(10, 10)
dot.BackgroundColor3 = RED
dot.Parent = mark
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
do local st = Instance.new("UIStroke"); st.Color = Color3.new(1, 1, 1); st.Thickness = 2; st.Parent = dot end
local scale = Instance.new("UIScale"); scale.Parent = spin

-- LOCKED · NAME under the crosshair a moment
local gui = Instance.new("ScreenGui")
gui.Name = "LockOnHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.Parent = player.PlayerGui
local tag = Instance.new("TextLabel")
tag.AnchorPoint = Vector2.new(0.5, 0)
tag.Position = UDim2.new(0.5, 0, 0.5, 34)
tag.Size = UDim2.fromOffset(360, 20)
tag.BackgroundTransparency = 1
tag.Font = Theme.FONT_TITLE
tag.TextSize = 15
tag.TextColor3 = RED
tag.TextStrokeTransparency = 0.35
tag.TextTransparency = 1
tag.TextStrokeTransparency = 1
tag.Parent = gui

local function nameOf(m)
	local p = Players:GetPlayerFromCharacter(m)
	if p then return p.DisplayName end
	local hum = m:FindFirstChildOfClass("Humanoid")
	return (hum and hum.DisplayName ~= "" and hum.DisplayName) or m.Name
end
LockOn.changed:Connect(function(m)
	if m then
		mark.Adornee = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
		mark.Enabled = true
		scale.Scale = 1.8
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
		tag.Text = "LOCKED  ·  " .. string.upper(nameOf(m))
	else
		mark.Enabled = false
		mark.Adornee = nil
		tag.Text = "UNLOCKED"
	end
	tag.TextTransparency, tag.TextStrokeTransparency = 0, 0.35
	local mine = os.clock()
	tag:SetAttribute("At", mine)
	task.delay(1.2, function()
		if tag:GetAttribute("At") ~= mine then return end
		TweenService:Create(tag, TweenInfo.new(0.4), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end)
end)
RunService.RenderStepped:Connect(function()
	if mark.Enabled then
		spin.Rotation = (os.clock() * 40) % 360
		local p = 1 + 0.06 * math.sin(os.clock() * 6)
		dot.Size = UDim2.fromOffset(10 * p, 10 * p)
	end
end)
