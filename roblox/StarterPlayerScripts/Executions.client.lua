--[[ EXECUTIONS (client) — with a weapon in hand, an enemy you could finish
     (ReplicatedStorage ▸ ExecuteRule: bleeding out, or nearly dead with their
     guard down, close and in front of you) gets a "R  EXECUTE" tag over their
     head; the Execute key (Settings ▸ Controls, R by default) asks your weapon's
     server to do it. The server checks the same rule again and decides. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rule = require(ReplicatedStorage:WaitForChild("ExecuteRule"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local player = Players.LocalPlayer

local function weaponRemote()
	local char = player.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	return tool and tool:FindFirstChild("CombatRemote")
end

--------------------------------------------------------------------
--  THE TAG
--------------------------------------------------------------------
local bb = Instance.new("BillboardGui")
bb.Name = "ExecuteHint"
bb.Size = UDim2.fromOffset(150, 34)
bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
bb.AlwaysOnTop = true
bb.LightInfluence = 0
bb.MaxDistance = 40
bb.Enabled = false
bb.ResetOnSpawn = false
bb.Parent = player:WaitForChild("PlayerGui")   -- (a BillboardGui inside a ScreenGui doesn't draw)

local row = Instance.new("Frame")
row.AnchorPoint = Vector2.new(0.5, 0.5)
row.Position = UDim2.fromScale(0.5, 0.5)
row.Size = UDim2.fromOffset(132, 30)
row.BackgroundColor3 = Theme.GLASS
row.BackgroundTransparency = 0.15
row.Parent = bb
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
local rim = Instance.new("UIStroke", row)
rim.Color = Theme.BAD
rim.Thickness = 2

local cap = Instance.new("TextLabel")
cap.Position = UDim2.fromOffset(4, 3)
cap.Size = UDim2.fromOffset(24, 24)
cap.BackgroundColor3 = Theme.TEXT
cap.Font = Theme.FONT
cap.TextSize = 15
cap.TextColor3 = Theme.INK
cap.Parent = row
Instance.new("UICorner", cap).CornerRadius = UDim.new(0, 5)

local word = Instance.new("TextLabel")
word.Position = UDim2.fromOffset(32, 0)
word.Size = UDim2.new(1, -36, 1, 0)
word.BackgroundTransparency = 1
word.Font = Theme.FONT_TITLE
word.TextSize = 17
word.Text = "EXECUTE"
word.TextColor3 = Theme.TEXT
word.TextStrokeColor3 = Theme.OUTLINE
word.TextStrokeTransparency = 0.4
word.TextXAlignment = Enum.TextXAlignment.Left
word.Parent = row

local function keyName()
	local name = ClientSettings.get("Key_Execute") or "R"
	return #name <= 2 and name or name:sub(1, 2)
end

--------------------------------------------------------------------
--  WHO, EVERY FEW FRAMES
--------------------------------------------------------------------
local target = nil
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then
		if bb.Enabled then rim.Transparency = 0.3 + 0.3 * math.sin(os.clock() * 8) end
		return
	end
	acc = 0
	local char = player.Character
	local t = (char and weaponRemote()) and Rule.best(char) or nil
	target = t
	local head = t and (t:FindFirstChild("Head") or t:FindFirstChild("HumanoidRootPart"))
	bb.Adornee = head
	bb.Enabled = head ~= nil
	if head then cap.Text = keyName() end
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp or not target then return end
	if ClientSettings.actionForInput(input) ~= "Execute" then return end
	local remote = weaponRemote()
	if remote then remote:FireServer("Execute", target) end
end)
