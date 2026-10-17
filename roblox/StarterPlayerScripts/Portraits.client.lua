--[[ PORTRAITS — the portraits watch (the dungeons' paintings: Game ▸ Dungeon P.painting, one
     model each, Props ▸ Painting), on your screen only:
       their eyes   the pupils (PPupilL / PPupilR) turn in their whites toward you wherever you
                    stand in the room
       now and then with your back to one, near it, its eyes burn red a moment and something
                    whispers; turn round and they're only paint again
     Only the portraits within 40 studs. Nothing here is sent to the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))

local NEAR = 40
local LOOK = Vector3.new(0.07, 0.035, 0)   -- how far a pupil can turn in its white
local RED = Color3.fromRGB(255, 40, 30)

local portraits = {}   -- [model] = {frame, eyes = {{white, pupil, color}}, redUntil, nextScare}

local function add(m)
	if portraits[m] or not m:IsA("Model") or m.Name ~= "Painting" then return end
	task.defer(function()
		local frame = m:FindFirstChild("Frame")
		local eyes = {}
		for _, s in ipairs({"L", "R"}) do
			local w, p = m:FindFirstChild("PEye" .. s), m:FindFirstChild("PPupil" .. s)
			if w and p then table.insert(eyes, {white = w, pupil = p, color = p.Color, mat = p.Material}) end
		end
		if frame and #eyes > 0 then portraits[m] = {frame = frame, eyes = eyes, nextScare = os.clock() + 10 + math.random() * 30} end
	end)
end
local function watchMap(map)
	for _, d in ipairs(map:GetDescendants()) do add(d) end
	map.DescendantAdded:Connect(add)
end
workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then watchMap(c) end end)
if workspace:FindFirstChild("Map") then watchMap(workspace.Map) end

local function setRed(p, on)
	for _, e in ipairs(p.eyes) do
		if on then
			e.pupil.Color, e.pupil.Material = RED, Enum.Material.Neon
			e.pupil.Size = Vector3.new(0.12, 0.12, 0.05)
		else
			e.pupil.Color, e.pupil.Material = e.color, e.mat
			e.pupil.Size = Vector3.new(0.09, 0.09, 0.05)
		end
	end
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 1 / 20 then return end
	acc = 0
	local cam = workspace.CurrentCamera
	if not cam then return end
	local eye = cam.CFrame.Position
	local now = os.clock()
	local parts, cfs = {}, {}
	for m, p in pairs(portraits) do
		if not m.Parent then portraits[m] = nil
		else
			local fc = p.frame.CFrame
			local to = eye - fc.Position
			if to.Magnitude < NEAR then
				-- (the pupils turn toward you)
				local lp = fc:PointToObjectSpace(eye)
				local depth = math.max(lp.Z, 1)
				local dx = math.clamp(lp.X / depth, -1, 1) * LOOK.X
				local dy = math.clamp(lp.Y / depth, -1, 1) * LOOK.Y
				for _, e in ipairs(p.eyes) do
					table.insert(parts, e.pupil)
					table.insert(cfs, e.white.CFrame * CFrame.new(dx, dy, 0.03))
				end
				-- (your back to it, near: now and then its eyes burn)
				if p.redUntil then
					local facing = cam.CFrame.LookVector:Dot(-to.Unit)
					if now > p.redUntil or facing > 0.75 then p.redUntil = nil; setRed(p, false) end
				elseif now > p.nextScare and to.Magnitude < 18 and lp.Z > 0 then
					local facing = cam.CFrame.LookVector:Dot(-to.Unit)
					if facing < -0.2 then
						p.nextScare = now + 40 + math.random() * 60
						if math.random() < 0.35 then
							p.redUntil = now + 2.2
							setRed(p, true)
							WarFX.sound("Whisper", fc.Position, {volume = 0.5, speed = 1.1, near = 6, range = 40})
						end
					else
						p.nextScare = now + 2
					end
				end
			end
		end
	end
	if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
end)
