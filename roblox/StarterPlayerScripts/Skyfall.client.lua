--[[ SKYFALL — Crownfall's way in (Game ▸ Modes ▸ Crownfall): the ride on the dragon's back, the
     leap, the dive and a hero's landing. The server says who is where in character attributes;
     this draws it on every screen, and flies your own fall.

       Riding     on the dragon: your Jump leaps off ("Leap"); the key on screen is yours
                  (InputHints: a key, a pad button or the touch JUMP button); the wind, its wings
       Diving     the server time you leapt. Yours: steered with your move keys, look down to fall
                  faster, look ahead to glide; wind streaks, the wind's roar. Everyone's: body flat,
                  arms spread (CfDive, on every screen through Emotes)
       HeroLand   the server time you came down: one knee and a fist to the ground (CfLand), a
                  ring of dust, stones thrown up, the ground shaking under you. Yours tells the
                  server ("Landed") the moment you touch down. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local Emotes = require(ReplicatedStorage:WaitForChild("Emotes"))
local InputHints = require(ReplicatedStorage:WaitForChild("InputHints"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Sounds = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local event = ReplicatedStorage:WaitForChild("AdventureEvent")

local GOLD = Color3.fromRGB(255, 196, 60)
local WHITE = Color3.new(1, 1, 1)
local DUST = Color3.fromRGB(176, 158, 128)
local WIND = "rbxasset://sounds/action_falling.mp3"
local SLAM = "rbxasset://sounds/impact_explosion_03.mp3"
local THUD = "rbxasset://sounds/action_jump_land.mp3"

--------------------------------------------------------------------
--  THE POSES (Emotes: drawn on every screen, players alike)
--------------------------------------------------------------------
local track, with, window = Emotes.track, Emotes.with, Emotes.window
-- flat out, face down, arms and legs spread to the wind (the arms beat a little in it)
local SPREAD = {root = {-78, 0, 0}, neck = {48, 0, 0}, rs = {30, 0, 78}, ls = {30, 0, -78}, rh = {-12, 0, 14}, lh = {-12, 0, -14}}
Emotes.define("CfDive", {d = 90, gesture = true, pose = with(track({{0, {}}, {0.35, SPREAD}, {90, SPREAD}}), function(t, p)
	local w = window(t, 0.3, 90, 0.2)
	p.rs[3] += math.sin(t * 9) * 5 * w
	p.ls[3] -= math.sin(t * 9 + 0.8) * 5 * w
	p.rh[1] += math.sin(t * 6) * 4 * w
	p.lh[1] -= math.sin(t * 6) * 4 * w
end)})
-- THE HERO'S LANDING: down hard on one knee, a fist to the ground, the other arm thrown back;
-- the head comes up, and you rise
local LAND = {rootY = -1.05, lh = {68, 0, -6}, rh = {-46, 0, 10}, waist = {-34, 0, 0}, rs = {34, 0, -4}, ls = {-28, 0, -58}, neck = {-24, 0, 0}}
local LOOK = {rootY = -1.0, lh = {66, 0, -6}, rh = {-46, 0, 10}, waist = {-26, 0, 0}, rs = {30, 0, -4}, ls = {-24, 0, -52}, neck = {22, 0, 0}}
Emotes.define("CfLand", {d = 1.7, gesture = true, pose = track({
	{0, {rootY = -1.35, lh = {72, 0, -6}, rh = {-48, 0, 10}, waist = {-42, 0, 0}, rs = {40, 0, -4}, ls = {-34, 0, -64}, neck = {-30, 0, 0}}},
	{0.14, LAND}, {0.7, LAND}, {1.0, LOOK}, {1.7, {}},
})})

--------------------------------------------------------------------
--  ON SCREEN: the key that leaps you off, the height while you fall
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Skyfall"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 25
gui.Parent = player:WaitForChild("PlayerGui")
local function label(parent, text, size, font, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.Font = font
	l.TextColor3 = color
	l.Size = UDim2.new(1, 0, 0, size + 6)
	local s = Instance.new("UIStroke"); s.Color = Theme.OUTLINE; s.Thickness = 2; s.Parent = l
	l.Parent = parent
	return l
end
local holder = Instance.new("CanvasGroup")
holder.BackgroundTransparency = 1
holder.AnchorPoint = Vector2.new(0.5, 1)
holder.Position = UDim2.new(0.5, 0, 1, -150)
holder.Size = UDim2.fromOffset(560, 150)
holder.GroupTransparency = 1
holder.Visible = false
holder.Parent = gui
local uiScale = Instance.new("UIScale"); uiScale.Parent = holder
local verb = label(holder, "", 44, Theme.FONT_TITLE, WHITE)
local key = Instance.new("Frame")
key.AnchorPoint = Vector2.new(0.5, 0)
key.Position = UDim2.new(0.5, 0, 0, 54)
key.Size = UDim2.fromOffset(150, 50)
key.BackgroundColor3 = Color3.fromRGB(22, 20, 28)
key.BackgroundTransparency = 0.08
key.Parent = holder
local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 12); kc.Parent = key
local ks = Instance.new("UIStroke"); ks.Color = GOLD; ks.Thickness = 2.5; ks.Parent = key
local keyText = label(key, "", 24, Theme.FONT_TITLE, GOLD)
keyText.Size = UDim2.fromScale(1, 1)
local line = label(holder, "", 18, Theme.FONT_BODY, Color3.fromRGB(226, 232, 245))
line.Position = UDim2.fromOffset(0, 112)

local shown = nil   -- "ride" | "dive" | nil
local function show(what)
	if shown == what then return end
	shown = what
	if not what then
		TweenService:Create(holder, TweenInfo.new(0.3), {GroupTransparency = 1}):Play()
		task.delay(0.32, function() if not shown then holder.Visible = false end end)
		return
	end
	holder.Visible = true
	uiScale.Scale = 1.25
	TweenService:Create(holder, TweenInfo.new(0.22), {GroupTransparency = 0}):Play()
	TweenService:Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end
local function writeHint(height)
	if shown == "ride" then
		local land = ReplicatedStorage:FindFirstChild("Round") and ReplicatedStorage.Round:GetAttribute("BusOverLand") == true
		verb.Text = land and "LEAP OFF" or "HOLD ON"
		keyText.Text = InputHints.name("Jump")
		key.Visible = land
		line.Text = land and "Jump off over where you want to land  ·  the dragon shakes you off at the far shore"
			or "Over the sea: wait for land, then leap off where you like"
	elseif shown == "dive" then
		verb.Text = height and string.format("%d", math.max(0, math.floor(height))) or ""
		key.Visible = false
		line.Text = InputHints.mode() == "Touch" and "Steer with the stick  ·  look down to dive faster" or "Steer as you fall  ·  look down to dive faster, ahead to glide"
	end
	local w = math.max(64, keyText.TextBounds.X + 40)
	key.Size = UDim2.fromOffset(w, 50)
end
InputHints.changed:Connect(function() writeHint() end)

--------------------------------------------------------------------
--  THE RIDE: your Jump leaps you off
--------------------------------------------------------------------
local lastLeap = 0
local function leap()
	local c = player.Character
	if not (c and c:GetAttribute("Riding")) or os.clock() - lastLeap < 0.6 then return end
	lastLeap = os.clock()
	event:FireServer("Leap")
end
UserInputService.JumpRequest:Connect(leap)
local function hookSeat(c)
	local hum = c:WaitForChild("Humanoid", 10)
	if hum then hum.Seated:Connect(function(on) if not on then leap() end end) end
end
if player.Character then task.spawn(hookSeat, player.Character) end
player.CharacterAdded:Connect(hookSeat)

-- the wind (louder as you fall), and the dragon's wings while you ride it
local wind = Instance.new("Sound")
wind.Name = "SkyfallWind"
wind.SoundId = WIND
wind.Looped = true
wind.Volume = 0
wind.Parent = SoundService
local function sound(id, parent, vol, speed)
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol; s.PlaybackSpeed = speed
	s.RollOffMaxDistance = 500
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 5)
	return s
end

--------------------------------------------------------------------
--  YOUR DIVE
--------------------------------------------------------------------
local dive = nil
local landedAt = 0   -- (your own landing: drawn at once, before the server hears of it)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local streaks   -- the wind streaking past (a part ahead of the camera, its emitter blowing at you)
local function makeStreaks()
	local p = Instance.new("Part")
	p.Name = "SkyfallStreaks"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.Size = Vector3.new(46, 34, 1)
	local e = Instance.new("ParticleEmitter")
	e.EmissionDirection = Enum.NormalId.Back
	e.Shape = Enum.ParticleEmitterShape.Box
	e.Orientation = Enum.ParticleOrientation.VelocityParallel
	e.Speed = NumberRange.new(140, 180)
	e.Lifetime = NumberRange.new(0.18, 0.26)
	e.Size = NumberSequence.new(0.07)
	e.Squash = NumberSequence.new(3)
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(1, 1)})
	e.LightEmission = 0.6
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace.CurrentCamera
	return {part = p, emitter = e}
end

local function endDive(landedOnGround)
	local d = dive
	if not d then return end
	dive = nil
	for _, x in ipairs({d.lv, d.ao, d.att}) do if x then x:Destroy() end end
	if d.hum.Parent then d.hum.AutoRotate = true end
	if streaks then streaks.emitter.Rate = 0 end
	TweenService:Create(wind, TweenInfo.new(0.4), {Volume = 0}):Play()
	show(nil)
	if landedOnGround then event:FireServer("Landed") end
	-- (the view back in close as you rise: first person for those who play in it)
	local c = d.char
	task.delay(1.4, function()
		if c.Parent then c:SetAttribute("ViewWant", ClientSettings.get("StartView") == "First person" and "First" or "Third") end
	end)
end

local function startDive(c)
	if dive then return end
	local hum = c:FindFirstChildOfClass("Humanoid")
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) then return end
	local att = Instance.new("Attachment"); att.Name = "SkyfallAtt"; att.Parent = hrp
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.MaxForce = 1e7
	lv.VectorVelocity = Vector3.new(0, -20, 0)
	lv.Parent = hrp
	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = 1e7
	ao.Responsiveness = 14
	local look = workspace.CurrentCamera.CFrame.LookVector
	local f = Vector3.new(look.X, 0, look.Z)
	ao.CFrame = f.Magnitude > 0.05 and CFrame.lookAt(Vector3.zero, f) or hrp.CFrame.Rotation
	ao.Parent = hrp
	hum.AutoRotate = false
	rayParams.FilterDescendantsInstances = {c, workspace:FindFirstChild("Steeds"), workspace.CurrentCamera}
	streaks = streaks or makeStreaks()
	dive = {char = c, hum = hum, hrp = hrp, lv = lv, ao = ao, att = att, vel = Vector3.new(0, -20, 0), t0 = os.clock()}
	wind.Volume = 0
	if not wind.IsPlaying then wind:Play() end
	sound(SoundConfig.Dodge, hrp, 1, 0.8)   -- (the dodge's whoosh, slow: off you go)
	show("dive")
	writeHint(nil)
end

local function landFx(c, big)
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local at = hrp.Position - Vector3.new(0, 3, 0)
	local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -8, 0), rayParams)
	if hit then at = hit.Position end
	if hit and hit.Material == Enum.Material.Water then return end
	local fx = Instance.new("Folder"); fx.Name = "HeroLanding"; fx.Parent = workspace
	Debris:AddItem(fx, 3)
	-- a ring of dust running out across the ground
	local ring = Instance.new("Part")
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = true, false, false, false, false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.SmoothPlastic
	ring.Color = DUST
	ring.Transparency = 0.35
	ring.Size = Vector3.new(0.3, 3, 3)
	ring.CFrame = CFrame.new(at + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = fx
	TweenService:Create(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.1, 30, 30), Transparency = 1}):Play()
	-- dust thrown up and out
	local a = Instance.new("Attachment"); a.WorldPosition = at
	local host = Instance.new("Part")
	host.Anchored, host.CanCollide, host.CanQuery, host.CanTouch, host.Transparency = true, false, false, false, 1
	host.Size = Vector3.new(1, 1, 1); host.CFrame = CFrame.new(at); host.Parent = fx
	a.Parent = host
	a.CFrame = CFrame.new()
	local dust = Instance.new("ParticleEmitter")
	dust.Color = ColorSequence.new(DUST)
	dust.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5)})
	dust.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1)})
	dust.Lifetime = NumberRange.new(0.8, 1.4)
	dust.Speed = NumberRange.new(18, 30)
	dust.Drag = 4
	dust.SpreadAngle = Vector2.new(85, 85)
	dust.EmissionDirection = Enum.NormalId.Top
	dust.Acceleration = Vector3.new(0, -4, 0)
	dust.Rate = 0
	dust.Parent = a
	dust:Emit(big and 46 or 30)
	-- stones kicked up
	for _ = 1, big and 9 or 5 do
		local s = Instance.new("Part")
		s.Size = Vector3.new(0.4, 0.3, 0.4) * (0.7 + math.random() * 1.2)
		s.Color = Color3.fromRGB(100 + math.random(-12, 12), 92, 80)
		s.Material = Enum.Material.Slate
		s.CanCollide, s.CanQuery, s.CanTouch = false, false, false
		s.CFrame = CFrame.new(at + Vector3.new(0, 0.6, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		s.Parent = fx
		local ang = math.random() * math.pi * 2
		s.AssemblyLinearVelocity = Vector3.new(math.cos(ang) * 14, 20 + math.random() * 14, math.sin(ang) * 14)
	end
	sound(SLAM, host, big and 0.9 or 0.6, 0.55)
	sound(THUD, host, 1.4, 0.6)
end

-- the ground shakes under you (after the camera has been placed)
local shakeUntil, shakeAmp = 0, 0
RunService:BindToRenderStep("Skyfall", Enum.RenderPriority.Camera.Value + 30, function()
	local left = shakeUntil - os.clock()
	if left > 0 then
		local k = left / 0.6
		local a = shakeAmp * k * k
		local cam = workspace.CurrentCamera
		cam.CFrame = cam.CFrame * CFrame.Angles(math.rad((math.random() - 0.5) * a), math.rad((math.random() - 0.5) * a), math.rad((math.random() - 0.5) * a * 0.6))
	end
	-- the streaks sit ahead of the camera, blowing at it
	if streaks then
		local cam = workspace.CurrentCamera
		local v = dive and dive.vel or Vector3.zero
		local dir = v.Magnitude > 1 and v.Unit or Vector3.new(0, -1, 0)
		streaks.part.CFrame = CFrame.lookAt(cam.CFrame.Position + dir * 30, cam.CFrame.Position)
	end
end)

local function steer(dt)
	local d = dive
	if not d then return end
	local c = d.char
	if not (c.Parent and d.hum.Health > 0) or not c:GetAttribute("Diving") and os.clock() - d.t0 > 1 then endDive(false); return end
	local cam = workspace.CurrentCamera
	local look = cam.CFrame.LookVector
	-- look down to fall faster, ahead to glide
	local down = math.clamp((-look.Y - 0.05) / 0.75, 0, 1)
	local vs = 36 + down * 84
	local hs = 62 - down * 30
	local move = d.hum.MoveDirection
	local want
	if move.Magnitude > 0.1 then
		want = Vector3.new(move.X * hs, -vs, move.Z * hs)
	else
		local f = Vector3.new(look.X, 0, look.Z)
		f = f.Magnitude > 0.01 and f.Unit * hs * 0.3 or Vector3.zero
		want = Vector3.new(f.X, -vs, f.Z)
	end
	-- the ground below: flare, then slam down
	local hit = workspace:Raycast(d.hrp.Position, Vector3.new(0, -600, 0), rayParams)
	local h = hit and (d.hrp.Position.Y - hit.Position.Y) or 600
	if h < 26 and not d.slam then
		d.slam = true
		sound(SoundConfig.Dodge, d.hrp, 1.2, 0.6)
	end
	if d.slam then want = Vector3.new(d.vel.X * 0.15, -110, d.vel.Z * 0.15) end
	d.vel = d.slam and want or d.vel:Lerp(want, math.min(1, dt * 2.4))
	d.lv.VectorVelocity = d.vel
	local fl = Vector3.new(d.vel.X, 0, d.vel.Z)
	if fl.Magnitude > 4 then d.ao.CFrame = CFrame.lookAt(Vector3.zero, fl) end
	-- the wind and the streaks, by how fast you fall
	local speed = d.vel.Magnitude
	wind.Volume = math.clamp(speed / 120, 0.15, 1) * 0.9
	wind.PlaybackSpeed = 0.8 + math.clamp(speed / 120, 0, 1) * 0.4
	if streaks then streaks.emitter.Rate = math.clamp((speed - 30) * 1.2, 0, 110) end
	if os.clock() - (d.hintAt or 0) > 0.1 then d.hintAt = os.clock(); writeHint(h) end
	-- down
	if h < 3.6 or (os.clock() - d.t0 > 0.8 and d.hum.FloorMaterial ~= Enum.Material.Air) then
		local water = hit and hit.Material == Enum.Material.Water
		d.hrp.AssemblyLinearVelocity = Vector3.zero
		endDive(true)
		if not water then
			Emotes.play(c, "CfLand")
			landedAt = os.clock()
			landFx(c, true)
			shakeUntil, shakeAmp = os.clock() + 0.6, 4
		end
	end
end
RunService.Heartbeat:Connect(steer)

--------------------------------------------------------------------
--  EVERYONE: the pose while they ride, fall and land
--------------------------------------------------------------------
local seenLand = setmetatable({}, {__mode = "k"})
local wingAt = 0
RunService.RenderStepped:Connect(function()
	local me = player.Character
	-- your own: the hint, the dive starting
	if me then
		if me:GetAttribute("Riding") then
			show("ride")
			writeHint()
			-- (the wind up there, and the great wings beating)
			wind.Volume = 0.25
			if not wind.IsPlaying then wind:Play() end
			if os.clock() - wingAt > 1.15 then
				wingAt = os.clock()
				local steeds = workspace:FindFirstChild("Steeds")
				local dragon = steeds and steeds:FindFirstChildWhichIsA("Model")
				local root = dragon and dragon:FindFirstChild("HumanoidRootPart")
				if root then Sounds.bank("SwingHeavy", root, {Speed = 0.4, Volume = 2.2, MaxDistance = 400}) end
			end
		elseif me:GetAttribute("Diving") and not dive then
			local hum = me:FindFirstChildOfClass("Humanoid")
			if hum and not hum.SeatPart then startDive(me) end
		elseif shown == "ride" then
			show(nil)
			if not dive then wind.Volume = 0 end
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c then
			if c:GetAttribute("Diving") and not c:GetAttribute("HeroLand") and not (c == me and os.clock() - landedAt < 3) then
				if Emotes.playing(c) ~= "CfDive" then Emotes.play(c, "CfDive") end
			elseif Emotes.playing(c) == "CfDive" then
				Emotes.stop(c)
			end
			-- someone else's landing (yours is drawn the moment you touch down)
			local land = c:GetAttribute("HeroLand")
			if land and seenLand[c] ~= land then
				seenLand[c] = land
				if c ~= me and workspace:GetServerTimeNow() - land < 1 then
					Emotes.play(c, "CfLand", land)
					local hrp = c:FindFirstChild("HumanoidRootPart")
					local cam = workspace.CurrentCamera
					if hrp and cam and (hrp.Position - cam.CFrame.Position).Magnitude < 260 then
						rayParams.FilterDescendantsInstances = {c, workspace:FindFirstChild("Steeds"), cam}
						landFx(c, false)
						if me and me:FindFirstChild("HumanoidRootPart") and (hrp.Position - me.HumanoidRootPart.Position).Magnitude < 30 then
							shakeUntil, shakeAmp = os.clock() + 0.5, 2
						end
					end
				end
			end
		end
	end
end)

player.CharacterRemoving:Connect(function() endDive(false); show(nil); wind.Volume = 0 end)
