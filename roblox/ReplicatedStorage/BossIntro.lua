--[[ BOSS INTRO — a boss's entrance, on this screen: black bars close in and the rest of the HUD
     steps aside, the camera finds the boss and creeps towards it while its name comes up big on
     the bars, a deep boom and the ground shaking; about three seconds, then back to you.
     (Client only. The Depths' lords: Adventure.client on the boss banner; Siege's champion and
     the Horde's Warlord: BossEntrance.client.)

       BossIntro.play(model | nil, title, sub, color?)   model: the boss (nil: the bars and the
                                                         name only); one at a time ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))

local player = Players.LocalPlayer
local BossIntro = {}
local busy = false
local DUR = 3

-- (its own screen, over every other)
local gui, bars, title, sub
local function build()
	if gui and gui.Parent then return end
	gui = Instance.new("ScreenGui")
	gui.Name = "BossIntro"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 60
	gui.Parent = player:WaitForChild("PlayerGui")
	bars = {}
	for i = 1, 2 do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.AnchorPoint = Vector2.new(0, i - 1)
		f.Position = UDim2.fromScale(0, i - 1)
		f.Size = UDim2.fromScale(1, 0)
		f.ZIndex = 90
		f.Visible = false
		f.Parent = gui
		bars[i] = f
	end
	local function label(size, font, y)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(0.5, y)
		l.Size = UDim2.new(1, 0, 0, size + 8)
		l.Font = font
		l.TextSize = size
		l.TextTransparency = 1
		l.TextStrokeTransparency = 1
		l.TextStrokeColor3 = Theme.OUTLINE
		l.ZIndex = 91
		l.Text = ""
		l.Parent = gui
		return l
	end
	title = label(64, Theme.FONT_TITLE, 0.885)
	title.TextScaled = true
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 64
	cap.Parent = title
	sub = label(20, Theme.FONT, 0.955)
	sub.TextColor3 = Theme.DIM
end

function BossIntro.play(model, text, subText, color)
	if busy then return false end
	busy = true
	build()
	task.spawn(function()
		local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local head = model and model:FindFirstChild("Head")
		for _, f in ipairs(bars) do
			f.Visible = true
			TweenService:Create(f, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 0.16)}):Play()
		end
		local hidden = {}
		for _, g in ipairs(player.PlayerGui:GetChildren()) do
			if g:IsA("ScreenGui") and g ~= gui and g.Enabled then g.Enabled = false; table.insert(hidden, g) end
		end
		title.Text = text or ""
		title.TextColor3 = color or Color3.fromRGB(255, 96, 80)
		sub.Text = subText or ""
		task.delay(0.5, function()
			TweenService:Create(title, TweenInfo.new(0.6), {TextTransparency = 0, TextStrokeTransparency = 0.3}):Play()
			TweenService:Create(sub, TweenInfo.new(0.9), {TextTransparency = 0}):Play()
			WarFX.sound("Impact", nil, {volume = 0.9, speed = 0.45})
			WarFX.shake(1.1, 0.9)
		end)
		_G.CinematicUp = true
		if head and me then
			local scale = model:GetAttribute("MonsterScale") or 1
			local away = Vector3.new(me.Position.X - head.Position.X, 0, me.Position.Z - head.Position.Z)
			away = away.Magnitude > 0.5 and away.Unit or Vector3.new(0, 0, 1)
			local side = Vector3.new(-away.Z, 0, away.X)
			local t0 = os.clock()
			RunService:BindToRenderStep("BossIntro", Enum.RenderPriority.Last.Value + 100, function()
				local cam = workspace.CurrentCamera
				if not (cam and head.Parent) then return end
				local u = math.clamp((os.clock() - t0) / DUR, 0, 1)
				local e = 1 - (1 - u) ^ 2
				local at = head.Position
				local from = at + away * (22 - 9 * e) * scale + side * 5 * scale + Vector3.new(0, (3 - 2.5 * e) * scale, 0)
				cam.CameraType = Enum.CameraType.Scriptable
				cam.CFrame = CFrame.lookAt(from, at + Vector3.new(0, 0.6 * scale, 0))
				cam.FieldOfView = 55 - 6 * e
			end)
		end
		task.wait(DUR)
		pcall(function() RunService:UnbindFromRenderStep("BossIntro") end)
		for _, g in ipairs(hidden) do if g.Parent then g.Enabled = true end end
		local cam = workspace.CurrentCamera
		if cam then cam.CameraType = Enum.CameraType.Custom end
		_G.CinematicUp = nil
		TweenService:Create(title, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		TweenService:Create(sub, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		for _, f in ipairs(bars) do TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 0)}):Play() end
		task.wait(0.55)
		for _, f in ipairs(bars) do f.Visible = false end
		busy = false
	end)
	return true
end

return BossIntro
