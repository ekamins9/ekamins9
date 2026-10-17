--[[ DUNGEON MOOD — what being down there feels like, on your screen only, on any floor Game ▸
     Dungeon built (The Depths, Deadvault: the Map carries Generated and its Theme), and on Plague
     Night and the Undead invasion (the dread, the sounds, the apparitions and bats; not the
     lanterns or the arrivals):

       your lantern     a warm light on every adventurer's chest (yours and your party's): the
                        floors are dark now, the torches only pools on the walls
       the air          dust drifting through the light round you; colder colours, a darker edge
                        to the screen
       the sounds       a low drone under everything; now and then, somewhere in the dark near
                        you, a whisper, an iron clank, a deep thud from far below, stone settling
       what comes       a monster doesn't just appear: it takes shape out of the dark over most
                        of a second as grave-dust bursts up round it (and some of the dead whisper
                        as they come)
       what lurks       a monster near you (within 70 studs) groans or growls now and then, from
                        where it stands: the dead groan (WarAudio ▸ Groan), the rest growl (Growl)
       a boss near      while a boss is alive near you (Boss, within 90 studs) the colours turn
                        a darker, blood-tinged, harder grade, easing back when it falls
       bats             now and then a swarm bursts out of the dark ahead and flits past over your
                        head (WarAudio ▸ Bats)
       what's there     now and then, well ahead of you in the dark, a pale see-through figure
                        walks a few steps across your path and is gone (WarCrowd.ghost; never a
                        fighter, nothing anyone else sees)

     The sounds are ReplicatedStorage ▸ WarAudio's (Drone, Whisper, Gate, Impact; one missing is
     just quiet). Nothing here is sent to the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local WarCrowd = require(ReplicatedStorage:WaitForChild("WarCrowd"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))

local player = Players.LocalPlayer
local V3 = Vector3.new

-- each theme's grade: the tint over everything, how much colour is left
local GRADE = {
	BoneCrypt = {tint = Color3.fromRGB(214, 232, 226), sat = -0.32},
	Plague = {tint = Color3.fromRGB(214, 228, 206), sat = -0.3},
	GoblinWarrens = {tint = Color3.fromRGB(240, 226, 206), sat = -0.18},
	CrimsonManor = {tint = Color3.fromRGB(240, 214, 220), sat = -0.15},
	FrozenDepths = {tint = Color3.fromRGB(206, 224, 246), sat = -0.28},
	EmberForge = {tint = Color3.fromRGB(250, 222, 200), sat = -0.12},
}
local LANTERN = Color3.fromRGB(255, 190, 130)

local mood = {on = false, token = 0}

-- a dungeon floor (Generated) — or Plague Night, which gets the dread without the lanterns (it
-- lights its living itself) and without the monsters' arrival (its dead claw up out of the ground)
local round = ReplicatedStorage:WaitForChild("Round")
local function inDungeon()
	local m = workspace:FindFirstChild("Map")
	local mode = round:GetAttribute("Mode")
	if (mode == "Plague" or mode == "InvUndead") and m then return true, "Plague" end
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
-- a boss near: the grade darkens and reddens while it lives, eases back after
local function bossWatch(token, theme)
	local g = GRADE[theme or ""] or {tint = Color3.fromRGB(226, 228, 232), sat = -0.22}
	local up = false
	while mood.on and mood.token == token do
		task.wait(1)
		local npcs = workspace:FindFirstChild("NPCs")
		local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local near = false
		if npcs and me then
			for _, m in ipairs(npcs:GetChildren()) do
				local h = m:FindFirstChildOfClass("Humanoid")
				local r = m:FindFirstChild("HumanoidRootPart")
				if m:GetAttribute("Boss") and h and h.Health > 0 and r and (r.Position - me.Position).Magnitude < 90 then near = true; break end
			end
		end
		if near ~= up and mood.grade then
			up = near
			local info = TweenInfo.new(near and 2 or 4, Enum.EasingStyle.Sine)
			if near then
				TweenService:Create(mood.grade, info, {TintColor = Color3.fromRGB(240, 196, 190), Saturation = g.sat + 0.12, Contrast = 0.28, Brightness = -0.05}):Play()
			else
				TweenService:Create(mood.grade, info, {TintColor = g.tint, Saturation = g.sat, Contrast = 0.14, Brightness = -0.02}):Play()
			end
		end
	end
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
--  WHAT'S THERE: an apparition crossing the dark ahead of you
--------------------------------------------------------------------
local GHOST = {FrozenDepths = Color3.fromRGB(180, 220, 255), CrimsonManor = Color3.fromRGB(236, 200, 214), EmberForge = Color3.fromRGB(255, 200, 160)}
local ghostRay = RaycastParams.new()
ghostRay.FilterType = Enum.RaycastFilterType.Exclude
local function apparition()
	local cam = workspace.CurrentCamera
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (cam and root) then return end
	ghostRay.FilterDescendantsInstances = {char, cam, workspace:FindFirstChild("NPCs")}
	local look = cam.CFrame.LookVector
	local fwd = V3(look.X, 0, look.Z)
	if fwd.Magnitude < 0.2 then return end
	fwd = fwd.Unit
	local eye = root.Position + V3(0, 2, 0)
	-- (well ahead, in the open dark: past 26 studs, short of whatever wall is there)
	local hit = workspace:Raycast(eye, fwd * 80, ghostRay)
	local d = hit and (hit.Position - eye).Magnitude - 5 or 60
	if d < 26 then return end
	d = math.min(d, 55)
	local at = eye + fwd * d
	local floor = workspace:Raycast(at + V3(0, 4, 0), V3(0, -30, 0), ghostRay)
	if not floor then return end
	local across = V3(-fwd.Z, 0, fwd.X) * (math.random() < 0.5 and -1 or 1)
	local secs, speed = 3.6, 3.2
	local start = floor.Position - across * speed * secs / 2
	WarCrowd.ghost(CFrame.new(start), {dir = across, speed = speed, secs = secs, color = GHOST[mood.theme or ""], kind = math.random() < 0.5 and "foot" or "knight"})
	WarFX.sound("Whisper", floor.Position + V3(0, 3, 0), {volume = 0.45, speed = 0.7 + math.random() * 0.2, near = 12, range = 90})
end
local function bats()
	local cam = workspace.CurrentCamera
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (cam and root) then return end
	ghostRay.FilterDescendantsInstances = {char, cam, workspace:FindFirstChild("NPCs")}
	local look = cam.CFrame.LookVector
	local fwd = V3(look.X, 0, look.Z)
	if fwd.Magnitude < 0.2 then return end
	fwd = fwd.Unit
	local head = root.Position + V3(0, 4, 0)
	-- (out of the dark ahead, short of the wall; over your head and away behind you)
	local hit = workspace:Raycast(head, fwd * 60, ghostRay)
	local d = hit and (hit.Position - head).Magnitude - 3 or 45
	if d < 14 then return end
	local from = head + fwd * math.min(d, 40) + V3(0, 3, 0)
	local back = workspace:Raycast(head, -fwd * 40, ghostRay)
	local to = head - fwd * ((back and (back.Position - head).Magnitude - 2) or 30) + V3((math.random() - 0.5) * 8, 2, (math.random() - 0.5) * 8)
	WarFX.bats(from, to, 9 + math.random(5))
	WarFX.sound("Bats", head, {volume = 0.8, near = 10, range = 80, speed = 0.95 + math.random() * 0.1})
end
local function haunt(token)
	task.wait(30 + math.random() * 30)
	while mood.on and mood.token == token do
		local r = math.random()
		if r < 0.35 then pcall(apparition) elseif r < 0.65 then pcall(bats) end
		task.wait(40 + math.random() * 45)
	end
end

--------------------------------------------------------------------
--  WHAT COMES OUT OF THE DARK
--------------------------------------------------------------------
local DUST = {Undead = Color3.fromRGB(110, 120, 112), Frost = Color3.fromRGB(190, 210, 230), Infernal = Color3.fromRGB(90, 70, 60)}
local function arrives(m)
	if not mood.on or not m:IsA("Model") then return end
	task.wait(0.15)
	if not m.Parent or not m:GetAttribute("Monster") then return end
	local root = m:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local faction = m:GetAttribute("Faction")
	-- (it takes shape out of the dark: from nothing to solid over most of a second)
	local parts = {}
	for _, d in ipairs(m:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Decal")) and d.LocalTransparencyModifier == 0 then
			d.LocalTransparencyModifier = 1
			table.insert(parts, d)
		end
	end
	task.spawn(function()
		local t0 = os.clock()
		while true do
			local u = math.clamp((os.clock() - t0) / 0.9, 0, 1)
			for _, d in ipairs(parts) do if d.Parent then d.LocalTransparencyModifier = 1 - u * u end end
			if u >= 1 then break end
			task.wait()
		end
	end)
	local feet = root.Position - Vector3.new(0, 2.6 * (m:GetAttribute("MonsterScale") or 1), 0)
	WarFX.dust(feet + Vector3.new(0, 0.6, 0), 1.4 * (m:GetAttribute("MonsterScale") or 1), DUST[faction or ""] or Color3.fromRGB(96, 90, 84))
	if faction == "Undead" and os.clock() - (mood.lastWhisper or 0) > 4 and math.random() < 0.5 then
		mood.lastWhisper = os.clock()
		WarFX.sound("Whisper", root.Position, {volume = 0.5, speed = 0.75 + math.random() * 0.2, near = 10, range = 70})
	end
end
-- what lurks: the nearest monsters groan or growl now and then, from where they stand
local function lurk(token)
	while mood.on and mood.token == token do
		task.wait(2.5 + math.random() * 3)
		local npcs = workspace:FindFirstChild("NPCs")
		local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if npcs and me then
			local near = {}
			for _, m in ipairs(npcs:GetChildren()) do
				local r = m:FindFirstChild("HumanoidRootPart")
				local h = m:FindFirstChildOfClass("Humanoid")
				if r and h and h.Health > 0 and m:GetAttribute("Monster") and (r.Position - me.Position).Magnitude < 70 then table.insert(near, m) end
			end
			if #near > 0 then
				local m = near[math.random(#near)]
				local scale = m:GetAttribute("MonsterScale") or 1
				local undead = m:GetAttribute("Faction") == "Undead"
				WarFX.sound(undead and "Groan" or "Growl", m.HumanoidRootPart.Position, {volume = 0.7, speed = (0.95 + math.random() * 0.15) / math.sqrt(scale), near = 10, range = 80})
			end
		end
	end
end

local function watchMonsters()
	local function hook(npcs)
		table.insert(mood.conns, npcs.ChildAdded:Connect(function(m) task.spawn(arrives, m) end))
	end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then hook(npcs) end
	table.insert(mood.conns, workspace.ChildAdded:Connect(function(c) if c.Name == "NPCs" then hook(c) end end))
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
	local plague = theme == "Plague"
	-- every adventurer carries a light
	if not plague then
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then task.spawn(lantern, p.Character) end
			table.insert(mood.conns, p.CharacterAdded:Connect(function(c) task.wait(0.3); lantern(c) end))
		end
		table.insert(mood.conns, Players.PlayerAdded:Connect(function(p)
			table.insert(mood.conns, p.CharacterAdded:Connect(function(c) task.wait(0.3); lantern(c) end))
		end))
	end
	task.spawn(dark, token)
	task.spawn(haunt, token)
	task.spawn(bossWatch, token, theme)
	task.spawn(lurk, token)
	if not plague then watchMonsters() end
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
round:GetAttributeChangedSignal("Mode"):Connect(refresh)
refresh()
