--[[ UNDERTOW — something in the Drowned Halls' water, on your screen only. Where the water has come
     in across a room's floor (Game ▸ Dungeon: StandingWater), now and then a long dark shape glides
     just under the surface, ripples spreading off its head as it goes; come near and it darts
     away with a splash and is gone. Once in a while, as it sinks, a pale hand breaks the surface,
     hangs there a moment, and slides back under.

     Only on a Drowned Halls floor (the Map's Theme), only water within 60 studs of you and not
     right under you. Nothing here is sent to the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local player = Players.LocalPlayer

local V3, CF = Vector3.new, CFrame.new
local SHADOW = Color3.fromRGB(10, 26, 28)
local HAND = Color3.fromRGB(150, 168, 160)

local busy = false

local function part(size, color, mat, parent, round)
	local p = Instance.new("Part")
	p.Size, p.Color, p.Material = size, color, mat or Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	if round then local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p end
	p.Parent = parent
	return p
end

-- a ring of ripple spreading from a point on the water, fading as it goes
local function ripple(at, home)
	local r = part(V3(0.04, 1, 1), Color3.fromRGB(160, 200, 196), Enum.Material.Glass, home)
	r.Shape = Enum.PartType.Cylinder
	r.Transparency = 0.45
	r.CFrame = CF(at) * CFrame.Angles(0, 0, math.pi / 2)
	TweenService:Create(r, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = V3(0.04, 5, 5), Transparency = 1}):Play()
	task.delay(1.7, function() r:Destroy() end)
end

local function me()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

-- the hand: up through the surface, open, a moment, and back under
local function hand(at, home)
	local base = CF(at - V3(0, 1.4, 0))
	local parts = {}
	local palm = part(V3(0.5, 0.75, 0.18), HAND, nil, home)
	table.insert(parts, {palm, CF(0, 0, 0)})
	for i = 1, 4 do table.insert(parts, {part(V3(0.09, 0.62, 0.09), HAND, nil, home), CF(-0.2 + (i - 1) * 0.13, 0.66, 0) * CFrame.Angles(0, 0, math.rad((i - 2.5) * 6))}) end
	table.insert(parts, {part(V3(0.1, 0.42, 0.1), HAND, nil, home), CF(0.32, 0.12, 0) * CFrame.Angles(0, 0, math.rad(-38))})
	table.insert(parts, {part(V3(0.42, 0.9, 0.36), HAND, nil, home), CF(0, -0.8, 0)})
	local yaw = CFrame.Angles(0, math.random() * math.pi * 2, math.rad(math.random(-10, 10)))
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		-- (0.7 s up, 1.1 s held, its fingers curling a little, 0.9 s down)
		local lift = t < 0.7 and (t / 0.7) or (t < 1.8 and 1 or math.max(0, 1 - (t - 1.8) / 0.9))
		lift = lift * lift * (3 - 2 * lift)
		local cf = base * CF(0, lift * 1.6, 0) * yaw
		for _, e in ipairs(parts) do e[1].CFrame = cf * e[2] end
		if t > 2.7 then conn:Disconnect(); for _, e in ipairs(parts) do e[1]:Destroy() end end
	end)
	ripple(at, home)
	task.delay(1.9, function() ripple(at, home) end)
end

local function glide(sheet, home)
	local r = me()
	if not r then busy = false; return end
	local cf, sz = sheet.CFrame, sheet.Size
	-- along the water's long side, from near one end to near the other
	local long = sz.X >= sz.Z and cf.RightVector or cf.LookVector
	local half = (sz.X >= sz.Z and sz.X or sz.Z) / 2 - 2
	local acrossV = sz.X >= sz.Z and cf.LookVector or cf.RightVector
	local acrossH = (sz.X >= sz.Z and sz.Z or sz.X) / 2 - 1.2
	if half < 3 or acrossH < 0.5 then busy = false; return end
	local top = cf.Position.Y + sz.Y / 2
	local s = math.random() < 0.5 and 1 or -1
	local o = math.random() * 2 - 1
	local a = cf.Position + long * (-half * s) + acrossV * (o * acrossH)
	local b = cf.Position + long * (half * s) + acrossV * (-o * acrossH * 0.6)
	-- (a hair above the sheet: two see-through surfaces one inside the other draw in no fixed
	-- order, and the water would hide it; a dim patch on clear water reads as a shape beneath)
	a, b = V3(a.X, top + 0.012, a.Z), V3(b.X, top + 0.012, b.Z)
	-- (a long dim shape seen through the water: a body, and a tail that sweeps behind it)
	local body = part(V3(2.8, 0.04, 8), SHADOW, Enum.Material.SmoothPlastic, home, true)
	local tail = part(V3(1.3, 0.04, 4.5), SHADOW, Enum.Material.SmoothPlastic, home, true)
	body.Transparency, tail.Transparency = 1, 1
	local secs = 5 + math.random() * 3
	local t0, lastRipple = os.clock(), 0
	local fled = false
	WarFX.sound("Splash", a, {volume = 0.35, speed = 0.7, near = 8, range = 60})
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - t0
		local u = math.clamp(t / secs, 0, 1)
		-- (a slow S through the water)
		local p = a:Lerp(b, u) + acrossV * math.sin(u * math.pi * 2) * 0.8
		local ahead = a:Lerp(b, math.min(u + 0.02, 1)) + acrossV * math.sin(math.min(u + 0.02, 1) * math.pi * 2) * 0.8
		local dir = (ahead - p).Magnitude > 0.01 and (ahead - p).Unit or (b - a).Unit
		body.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, math.sin(t * 3) * 0.08)
		tail.CFrame = body.CFrame * CFrame.new(0, -0.005, 4.6) * CFrame.Angles(0, math.sin(t * 4.5) * 0.45, 0) * CFrame.new(0, 0, 1.6)
		local fade = math.min(1, t / 0.8, (secs - t) / 0.8)
		body.Transparency = 1 - 0.5 * math.max(0, fade)
		tail.Transparency = 1 - 0.4 * math.max(0, fade)
		if t - lastRipple > 0.6 then lastRipple = t; ripple(p + dir * 3 + V3(0, 0.05, 0), home) end
		-- (come near and it's gone, with a splash)
		local mr = me()
		if not fled and mr and (V3(mr.Position.X, 0, mr.Position.Z) - V3(p.X, 0, p.Z)).Magnitude < 7 then
			-- (a quick dart on along its way, and under)
			fled = true
			WarFX.sound("Splash", p, {volume = 0.8, speed = 1.1, near = 10, range = 70})
			ripple(p, home); ripple(p + dir, home)
			a, b = p, p + dir * 6
			t0, secs = os.clock(), 0.5
		end
		if t >= secs then
			conn:Disconnect()
			body:Destroy(); tail:Destroy()
			if not fled and math.random() < 0.18 then hand(p, home) end
			busy = false
		end
	end)
end

local function drowned()
	local m = workspace:FindFirstChild("Map")
	return m and m:GetAttribute("Theme") == "DrownedHalls" and m or nil
end

local home = nil
task.spawn(function()
	while true do
		task.wait(18 + math.random() * 22)
		local map = drowned()
		local r = me()
		if map and r and not busy then
			if not (home and home.Parent) then home = Instance.new("Folder"); home.Name = "Undertow"; home.Parent = workspace end
			local pick, list = nil, {}
			for _, d in ipairs(map:GetDescendants()) do
				if d:IsA("BasePart") and d.Name == "StandingWater" then
					local dist = (V3(d.Position.X, 0, d.Position.Z) - V3(r.Position.X, 0, r.Position.Z)).Magnitude
					if dist < 60 and dist > 9 then table.insert(list, d) end
				end
			end
			pick = list[math.random(math.max(#list, 1))]
			if pick then
				busy = true
				task.spawn(function()
					local ok = pcall(glide, pick, home)
					if not ok then busy = false end
				end)
			end
		end
	end
end)
