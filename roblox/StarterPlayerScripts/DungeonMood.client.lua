--[[ DUNGEON MOOD — what being down there feels like, on your screen only, on any floor Game ▸
     Dungeon built (The Depths, Deadvault: the Map carries Generated and its Theme):

       your lantern     a warm light on every adventurer's chest (yours and your party's): the
                        floors are dark now, the torches only pools on the walls
       the air          dust drifting through the light round you; colder colours, a darker edge
                        to the screen
       the sounds       a low drone under everything; now and then, somewhere in the dark near
                        you, a whisper, an iron clank, a deep thud from far below, stone settling

     The sounds are ReplicatedStorage ▸ WarAudio's (Drone, Whisper, Gate, Impact; one missing is
     just quiet). Nothing here is sent to the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))

local player = Players.LocalPlayer
local V3 = Vector3.new

-- each theme's grade: the tint over everything, how much colour is left
local GRADE = {
	BoneCrypt = {tint = Color3.fromRGB(214, 232, 226), sat = -0.32},
	GoblinWarrens = {tint = Color3.fromRGB(240, 226, 206), sat = -0.18},
	CrimsonManor = {tint = Color3.fromRGB(240, 214, 220), sat = -0.15},
	FrozenDepths = {tint = Color3.fromRGB(206, 224, 246), sat = -0.28},
	EmberForge = {tint = Color3.fromRGB(250, 222, 200), sat = -0.12},
}
local LANTERN = Color3.fromRGB(255, 190, 130)

local mood = {on = false, token = 0}

local function inDungeon()
	local m = workspace:FindFirstChild("Map")
	return m and m:GetAttribute("Generated") == true, m and m:GetAttribute("Theme")
end

--------------------------------------------------------------------
--  THE LANTERNS
--------------------------------------------------------------------
local function lantern(char)
	if not mood.on or not char then return end
	local torso = char:WaitForChild("Torso", 5) or char:FindFirstChild("UpperTorso")
	if not torso or torso:FindFirstChild("MoodLantern") then return end
	local l = Instance.new("PointLight")
	l.Name = "MoodLantern"
	l.Color = LANTERN
	l.Range = char == player.Character and 17 or 13
	l.Brightness = char == player.Character and 1.15 or 0.8
	l.Shadows = false
	l.Parent = torso
	table.insert(mood.lights, l)
end
local function dropLanterns()
	for _, l in ipairs(mood.lights or {}) do if l.Parent then l:Destroy() end end
	mood.lights = {}
end

--------------------------------------------------------------------
--  THE AIR: dust round the camera, the grade, the dark edge
--------------------------------------------------------------------
local function airOn(theme)
	local g = GRADE[theme or ""] or {tint = Color3.fromRGB(226, 228, 232), sat = -0.22}
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "DungeonGrade"
	cc.TintColor, cc.Saturation, cc.Contrast, cc.Brightness = Color3.new(1, 1, 1), 0, 0, 0
	cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(2.5), {TintColor = g.tint, Saturation = g.sat, Contrast = 0.14, Brightness = -0.02}):Play()
	mood.grade = cc
	-- dust motes drifting in whatever light there is (a box of them that goes where the camera goes)
	local a = Instance.new("Part")
	a.Name = "DungeonDust"
	a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.CastShadow = true, false, false, false, false
	a.Transparency = 1
	a.Size = V3(46, 18, 46)
	a.Parent = workspace.CurrentCamera
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Rate = Device.kind() == "phone" and 14 or 30
	e.Lifetime = NumberRange.new(6, 10)
	e.Speed = NumberRange.new(0.1, 0.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = V3(0.15, -0.05, 0.1)
	e.Size = NumberSequence.new(0.07, 0.11)
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(0.7, 0.45), NumberSequenceKeypoint.new(1, 1)})
	e.Color = ColorSequence.new(Color3.fromRGB(255, 236, 200))
	e.LightInfluence = 1
	e.LightEmission = 0.1
	e.Parent = a
	mood.dust = a
	mood.dustConn = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if cam and a.Parent then a.CFrame = CFrame.new(cam.CFrame.Position + cam.CFrame.LookVector * 10) end
	end)
	-- the dark edge of the screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "DungeonVignette"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -5
	gui.Parent = player:WaitForChild("PlayerGui")
	-- (four soft bands, each darkest at its own edge: {size, position, the gradient's turn})
	for _, side in ipairs({{UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0, 0), 90}, {UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0.7, 0), -90},
		{UDim2.new(0.22, 0, 1, 0), UDim2.new(0, 0, 0, 0), 0}, {UDim2.new(0.22, 0, 1, 0), UDim2.new(0.78, 0, 0, 0), 180}}) do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.Size, f.Position = side[1], side[2]
		local gr = Instance.new("UIGradient")
		gr.Rotation = side[3]
		gr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1)})
		gr.Parent = f
		f.Parent = gui
	end
	mood.vignette = gui
end
local function airOff()
	if mood.grade then
		local cc = mood.grade
		TweenService:Create(cc, TweenInfo.new(1), {TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0, Brightness = 0}):Play()
		task.delay(1.1, function() cc:Destroy() end)
		mood.grade = nil
	end
	if mood.dustConn then mood.dustConn:Disconnect(); mood.dustConn = nil end
	if mood.dust then mood.dust:Destroy(); mood.dust = nil end
	if mood.vignette then mood.vignette:Destroy(); mood.vignette = nil end
end

--------------------------------------------------------------------
--  THE SOUNDS OF THE DARK
--------------------------------------------------------------------
-- somewhere near you, out of sight (behind you, or off to a side), on the floor you're on
local function somewhereNear(minD, maxD)
	local cam = workspace.CurrentCamera
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if not (cam and r) then return nil end
	local look = cam.CFrame.LookVector
	local a = math.atan2(-look.X, -look.Z) + math.pi * (0.5 + math.random())   -- (not in front of you)
	local d = minD + math.random() * (maxD - minD)
	return r.Position + V3(-math.sin(a) * d, 2 + math.random() * 4, -math.cos(a) * d)
end
local SOUNDS = {
	{"Whisper", 1.0, function() return {volume = 0.55 + math.random() * 0.3, speed = 0.9 + math.random() * 0.2, near = 8, range = 60} end, 16, 30},
	{"Gate", 0.6, function() return {volume = 0.25, speed = 0.55 + math.random() * 0.15, near = 20, range = 160} end, 40, 90},
	{"Impact", 0.5, function() return {volume = 0.3, speed = 0.4 + math.random() * 0.15, near = 60, range = 400} end, 70, 140},
}
local function dark(token)
	local nextAt = os.clock() + 12 + math.random() * 12
	while mood.on and mood.token == token do
		if os.clock() >= nextAt then
			nextAt = os.clock() + 18 + math.random() * 30
			-- (a sound by weight)
			local total = 0
			for _, s in ipairs(SOUNDS) do total += s[2] end
			local pick, roll = SOUNDS[1], math.random() * total
			for _, s in ipairs(SOUNDS) do roll -= s[2]; if roll <= 0 then pick = s; break end end
			local at = somewhereNear(pick[4], pick[5])
			if at then WarFX.sound(pick[1], at, pick[3]()) end
		end
		task.wait(1)
	end
end

--------------------------------------------------------------------
--  COMING AND GOING
--------------------------------------------------------------------
local function leave()
	if not mood.on then return end
	mood.on = false
	mood.token += 1
	for _, c in ipairs(mood.conns or {}) do c:Disconnect() end
	mood.conns = {}
	dropLanterns()
	airOff()
	if mood.drone then WarFX.stopLoop(mood.drone, 2); mood.drone = nil end
end

local function enter(theme)
	if mood.on then return end
	mood.on = true
	mood.token += 1
	mood.lights, mood.conns = {}, {}
	local token = mood.token
	airOn(theme)
	mood.drone = WarFX.loop("Drone", 0.45)
	-- every adventurer carries a light
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then task.spawn(lantern, p.Character) end
		table.insert(mood.conns, p.CharacterAdded:Connect(function(c) task.wait(0.3); lantern(c) end))
	end
	table.insert(mood.conns, Players.PlayerAdded:Connect(function(p)
		table.insert(mood.conns, p.CharacterAdded:Connect(function(c) task.wait(0.3); lantern(c) end))
	end))
	task.spawn(dark, token)
end

local want = 0
local function refresh()
	want += 1
	local w = want
	task.delay(0.6, function()
		if want ~= w then return end
		local yes, theme = inDungeon()
		if yes and not mood.on then enter(theme)
		elseif not yes and mood.on then leave()
		elseif yes and mood.on and theme ~= mood.theme then leave(); enter(theme) end
		mood.theme = theme
	end)
end
workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then refresh() end end)
workspace.ChildRemoved:Connect(function(c) if c.Name == "Map" then refresh() end end)
refresh()
