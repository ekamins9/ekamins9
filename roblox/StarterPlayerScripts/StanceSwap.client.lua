--[[ STANCE SWAP — a staff's other self. With a weapon that has a twin in hand (the
     Arcane Staff and its melee self, Tools ▸ StaffMelee: the Tool's Twin attribute),
     the Stance bind (H, rebindable · a controller's D-pad ← · the touch STANCE action)
     asks the server to swap them (LoadoutServer: StanceSwap). In melee the staff fights
     with every swing a quarterstaff has; in magic it casts. A short hint says which. ]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local TouchInput = require(ReplicatedStorage:WaitForChild("TouchInput"))
local InputHints = require(ReplicatedStorage:WaitForChild("InputHints"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player = Players.LocalPlayer
local swap = ReplicatedStorage:WaitForChild("StanceSwap", 30)

local function held()
	local c = player.Character
	local t = c and c:FindFirstChildOfClass("Tool")
	return (t and t:GetAttribute("Twin")) and t or nil
end

-- the hint: which self you're holding, and the key for the other
local gui = Instance.new("ScreenGui")
gui.Name = "StanceHint"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 28
gui.Parent = player:WaitForChild("PlayerGui")
local hint = Instance.new("TextLabel")
-- (over the weapon chip at the bottom right, clear of the spell bar and the health bars)
hint.AnchorPoint = Vector2.new(1, 1); hint.Position = UDim2.new(1, -24, 1, -152)
hint.Size = UDim2.fromOffset(260, 22); hint.BackgroundTransparency = 1
hint.Font = Theme.FONT_TITLE; hint.TextSize = 13; hint.TextXAlignment = Enum.TextXAlignment.Right
hint.TextColor3 = Color3.fromRGB(220, 230, 255); hint.Text = ""; hint.Parent = gui
do local s = Instance.new("UIStroke", hint); s.Color = Theme.OUTLINE; s.Thickness = 1.6 end

local function keyName()
	local m = InputHints.mode()
	if m == "Gamepad" then return InputHints.name("Stance") end
	if m == "Touch" then return "STANCE" end
	return InputHints.name("Stance")
end
local function refresh()
	local t = held()
	if not t then hint.Text = ""; return end
	local melee = t:GetAttribute("TwinHidden") == true
	hint.Text = (melee and "⚔ MELEE" or "✦ MAGIC") .. "  ·  " .. keyName() .. " FOR " .. (melee and "MAGIC" or "MELEE")
end

local function ask()
	if not (swap and held()) then return end
	swap:FireServer()
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.DPadLeft then ask(); return end
	if input.UserInputType.Name:find("^Gamepad") then return end
	if ClientSettings.actionForInput(input) == "Stance" then ask() end
end)
TouchInput.changed:Connect(function(action, down) if action == "Stance" and down then ask() end end)

local function watch(c)
	if not c then return end
	c.ChildAdded:Connect(function(x) if x:IsA("Tool") then task.defer(refresh) end end)
	c.ChildRemoved:Connect(function(x) if x:IsA("Tool") then task.defer(refresh) end end)
	refresh()
end
player.CharacterAdded:Connect(watch)
if player.Character then watch(player.Character) end
InputHints.changed:Connect(refresh)
