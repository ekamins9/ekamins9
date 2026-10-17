--[[ MATCH INTRO — a battle's opening, on your first body of a round in Siege, Team Deathmatch, King
     of the Hill, Free-for-All, Last Team Standing and Horde: black bars slide in, the camera flies
     from the map's own shot (MapLoader's Shot1… on the Map) down to just behind you, the mode and
     the map come up as a title with what you're there to do, and a horn. About four seconds; any
     key skips it. Not for a newcomer's first battle (Intro briefs them), nor while anything else
     has the camera. War flies its own (War.client). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local round = ReplicatedStorage:WaitForChild("Round")

local MODES = {Siege = true, TDM = true, KOTH = true, FFA = true, LTS = true, Horde = true}
local GOAL = {
	TDM = "MORE KILLS THAN THE ENEMY", KOTH = "TAKE THE HILL  ·  HOLD IT", FFA = "EVERY BLADE FOR ITSELF",
	LTS = "ONE LIFE  ·  LAST TEAM STANDING", Horde = "HOLD THE CAMP  ·  WAVE AFTER WAVE",
}
local LEN = 4.2

local gui = Instance.new("ScreenGui")
gui.Name = "MatchIntro"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 45
gui.Enabled = false
gui.Parent = playerGui
local function bar(anchorY)
	local f = Instance.new("Frame")
	f.BackgroundColor3, f.BorderSizePixel = Color3.new(), 0
	f.AnchorPoint = Vector2.new(0, anchorY)
	f.Position = UDim2.fromScale(0, anchorY)
	f.Size = UDim2.new(1, 0, 0, 0)
	f.Parent = gui
	return f
end
local top, bottom = bar(0), bar(1)
local function text(size, font, color, y)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font, l.TextSize, l.TextColor3 = font, size, color
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.new(0.9, 0, 0, size + 8)
	l.TextScaled = size > 40
	if size > 40 then local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = size; c.Parent = l end
	local s = Instance.new("UIStroke"); s.Color = Theme.OUTLINE; s.Thickness = size > 30 and 3 or 1.8; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual; s.Parent = l
	l.Parent = gui
	return l
end
local kicker = text(18, Theme.FONT, Color3.fromRGB(255, 200, 70), 0.4)
local title = text(64, Theme.FONT_TITLE, Color3.new(1, 1, 1), 0.48)
local goal = text(18, Theme.FONT, Color3.fromRGB(226, 232, 245), 0.56)

local function mySide()
	local c = player.Character
	local t = c and c:GetAttribute("Team")
	return (t == "A" or t == "B") and t or nil
end
local function fadeAll(to, t)
	for _, l in ipairs({kicker, title, goal}) do
		TweenService:Create(l, TweenInfo.new(t), {TextTransparency = to}):Play()
		TweenService:Create(l:FindFirstChildOfClass("UIStroke"), TweenInfo.new(t), {Transparency = to}):Play()
	end
end

local playing = nil
local function stop()
	if not playing then return end
	playing = nil
	_G.CinematicUp = nil
	pcall(function() RunService:UnbindFromRenderStep("MatchIntro") end)
	fadeAll(1, 0.3)
	TweenService:Create(top, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0, 0)}):Play()
	TweenService:Create(bottom, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0, 0)}):Play()
	task.delay(0.45, function() if not playing then gui.Enabled = false end end)
end

local function play()
	local modeId = round:GetAttribute("Mode")
	local map = workspace:FindFirstChild("Map")
	local c = player.Character
	local head = c and c:FindFirstChild("Head")
	if not (map and head) then return end
	local shot = map:GetAttribute("Shot1")
	local centre = map:GetAttribute("Centre")
	if typeof(shot) ~= "CFrame" then
		if typeof(centre) ~= "Vector3" then return end
		local r = math.clamp(map:GetAttribute("Radius") or 80, 40, 200)
		shot = CFrame.lookAt(centre + Vector3.new(r * 0.7, r * 0.5, r * 0.7), centre)
	end
	-- (just behind you, looking where you face)
	local look = head.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z).Unit
	local endAt = head.Position - look * 10 + Vector3.new(0, 4, 0)
	local finish = CFrame.lookAt(endAt, head.Position + look * 20)
	local token = {}
	playing = token
	_G.CinematicUp = true
	gui.Enabled = true
	kicker.Text = string.upper(round:GetAttribute("ModeName") or "")
	title.Text = string.upper(round:GetAttribute("MapName") or "")
	local g = GOAL[modeId] or ""
	if modeId == "Siege" then
		g = (round:GetAttribute("Attackers") == mySide()) and "TAKE THE CASTLE  ·  STAGE BY STAGE" or "HOLD THE CASTLE  ·  TILL THE BELL"
	end
	goal.Text = g
	for _, l in ipairs({kicker, title, goal}) do l.TextTransparency = 1; l:FindFirstChildOfClass("UIStroke").Transparency = 1 end
	fadeAll(0, 0.5)
	TweenService:Create(top, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0.1, 0)}):Play()
	TweenService:Create(bottom, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0.1, 0)}):Play()
	WarFX.sound("Horn", nil, {volume = 0.7})
	task.delay(LEN - 1.2, function() if playing == token then fadeAll(1, 0.6) end end)
	local t0 = os.clock()
	RunService:BindToRenderStep("MatchIntro", Enum.RenderPriority.Camera.Value + 5, function()
		local u = math.clamp((os.clock() - t0) / LEN, 0, 1)
		u = u * u * (3 - 2 * u)
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = shot:Lerp(finish, u)
		if u >= 1 then stop() end
	end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if playing and not gp and input.UserInputType ~= Enum.UserInputType.MouseMovement then stop() end
end)

-- your first body of a round
local seen = nil
player.CharacterAdded:Connect(function(char)
	local modeId = round:GetAttribute("Mode")
	if not MODES[modeId] then return end
	local key = tostring(round:GetAttribute("Number")) .. ":" .. tostring(modeId)
	if seen == key then return end
	seen = key
	if (player:GetAttribute("Tutorial") or 2) < 2 or _G.IntroActive or _G.CinematicUp then return end
	char:WaitForChild("Head", 5)
	task.wait(0.4)
	if round:GetAttribute("State") == "Round" and player.Character == char then pcall(play) end
end)
