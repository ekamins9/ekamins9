--[[ ARROW FLIGHT (client) — the arrows you SEE fly. The server's arrow is the
     one that hits (Combat ▸ RangedServer); this draws its flight from the same
     start, speed and gravity, and stops where the server says it hit (where the
     server's stuck arrow takes over). Your own shot starts here the moment you
     loose it, before the server has heard.

       ArrowFlight.fly(id, origin, velocity, gravity, kind, mine, fx)
     fx: the skin's arrow effect (ArrowFX): it wears it in flight and bursts with it.
     Someone else's arrow passing close by WHIZZES past your ears (louder the
     closer it comes; once per arrow).
       ArrowFlight.stop(id, position?)
       ArrowFlight.has(id) ]]

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ArrowFX = require(script.Parent:WaitForChild("ArrowFX"))

local WHIZ = {"rbxassetid://9114156616", "rbxassetid://9114159112", "rbxassetid://9114159981"}   -- doppler whooshes (Pro Sound Effects)
local WHIZ_RANGE = 9      -- studs from your camera an arrow must pass within
local function whiz(closeness)
	local s = Instance.new("Sound")
	s.SoundId = WHIZ[math.random(#WHIZ)]
	s.Volume = 0.25 + 0.55 * closeness
	s.PlaybackSpeed = 1.5 + math.random() * 0.3
	s.Parent = SoundService
	s:Play()
	task.delay(2, function() s:Destroy() end)
end
-- the nearest the stretch a → b comes to p
local function nearest(p, a, b)
	local ab = b - a
	local t = ab.Magnitude > 1e-4 and math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1) or 0
	return (a + ab * t - p).Magnitude
end

local ArrowFlight = {}
local live = {}   -- [id] = {model, pos, vel, g, t}

local folder
local function holder()
	if folder and folder.Parent then return folder end
	folder = Instance.new("Folder")
	folder.Name = "ArrowFlights"
	folder.Parent = workspace
	return folder
end

local function model(kind)
	local len = kind == "crossbow" and 1.5 or 2.6
	local m = Instance.new("Model")
	m.Name = "FlyingArrow"
	local shaft = Instance.new("Part")
	shaft.Size = Vector3.new(0.09, 0.09, len)
	shaft.Color = Color3.fromRGB(150, 110, 66)
	shaft.Material = Enum.Material.Wood
	shaft.Anchored, shaft.CanCollide, shaft.CanQuery, shaft.CanTouch, shaft.CastShadow = true, false, false, false, false
	shaft.Parent = m
	local head = Instance.new("Part")
	head.Size = Vector3.new(0.12, 0.12, 0.3)
	head.Color = Color3.fromRGB(70, 72, 78)
	head.Material = Enum.Material.Metal
	head.Anchored, head.CanCollide, head.CanQuery, head.CanTouch, head.CastShadow = true, false, false, false, false
	head.Parent = m
	local fl = Instance.new("Part")
	fl.Size = Vector3.new(0.3, 0.02, 0.4)
	fl.Color = Color3.fromRGB(235, 232, 220)
	fl.Anchored, fl.CanCollide, fl.CanQuery, fl.CanTouch, fl.CastShadow = true, false, false, false, false
	fl.Parent = m
	-- a faint streak behind it
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0, len / 2); a0.Parent = shaft
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, 0, -len / 2); a1.Parent = shaft
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime = 0.12
	trail.Transparency = NumberSequence.new(0.6, 1)
	trail.Color = ColorSequence.new(Color3.fromRGB(240, 236, 220))
	trail.LightEmission = 0.3
	trail.FaceCamera = true
	trail.Parent = shaft
	m.PrimaryPart = shaft
	return m, shaft, head, fl, len
end

local function place(e)
	local dir = e.vel.Magnitude > 0.1 and e.vel.Unit or Vector3.new(0, 0, -1)
	local cf = CFrame.lookAt(e.pos, e.pos + dir)
	e.shaft.CFrame = cf
	e.head.CFrame = cf * CFrame.new(0, 0, -e.len / 2 - 0.12)
	e.fl.CFrame = cf * CFrame.new(0, 0, e.len / 2 - 0.25)
end

function ArrowFlight.fly(id, origin, velocity, gravity, kind, mine, fx)
	if live[id] then return end
	local m, shaft, head, fl, len = model(kind)
	m.Parent = holder()
	if fx then ArrowFX.decorate(shaft, head, fx) end
	local e = {model = m, shaft = shaft, head = head, fl = fl, len = len, pos = origin, vel = velocity, g = gravity or 30, t = 0, mine = mine == true, fx = fx}
	live[id] = e
	place(e)
	-- (a lost arrow: gone after a while whatever happens)
	task.delay(5, function() if live[id] == e then ArrowFlight.stop(id) end end)
end

function ArrowFlight.stop(id, at)
	local e = live[id]
	if not e then return end
	live[id] = nil
	if at then
		e.pos = at
		place(e)
		if e.fx then ArrowFX.burst(at, e.fx, holder()) end
		-- the server's stuck arrow takes its place a moment later
		task.delay(0.15, function() e.model:Destroy() end)
	else
		e.model:Destroy()
	end
end

function ArrowFlight.has(id) return live[id] ~= nil end

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local ear = cam and cam.CFrame.Position
	for _, e in pairs(live) do
		local nextVel = e.vel - Vector3.new(0, e.g * dt, 0)
		local from = e.pos
		e.pos += (e.vel + nextVel) * 0.5 * dt
		e.vel = nextVel
		place(e)
		if ear and not e.mine and not e.whizzed then
			local d = nearest(ear, from, e.pos)
			if d < WHIZ_RANGE then e.whizzed = true; whiz(1 - d / WHIZ_RANGE) end
		end
	end
end)

return ArrowFlight
