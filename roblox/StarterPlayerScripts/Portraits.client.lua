--[[ PORTRAITS — the portraits watch (the dungeons' paintings: Game ▸ Dungeon P.painting, one
     model each, Props ▸ Painting), on your screen only:
       their eyes   the pupils (PPupilL / PPupilR) turn in their whites toward you wherever you
                    stand in the room
       now and then with your back to one, near it, its eyes burn red a moment and something
                    whispers; turn round and they're only paint again
     And the Frozen Depths' dead in their ice (P.frozen: a figure sealed in an IceBlock): come
     within 12 studs and its eyes open in the ice, pale and cold, with a creak of ice; they follow
     you while you're near and close again when you've gone (22 studs).

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
local frozen = {}      -- [ice block] = {eyes = {part, part}, open = bool}
local ICE_EYE = Color3.fromRGB(150, 220, 255)

local function addIce(b)
	if frozen[b] then return end
	local eyes = {}
	for _ = 1, 2 do
		local e = Instance.new("Part")
		e.Name = "IceEye"
		e.Shape = Enum.PartType.Ball
		e.Size = Vector3.new(0.18, 0.18, 0.18)
		e.Color, e.Material = ICE_EYE, Enum.Material.Neon
		e.Anchored, e.CanCollide, e.CanQuery, e.CanTouch, e.CastShadow = true, false, false, false, false
		e.Transparency = 1
		e.Parent = b
		table.insert(eyes, e)
	end
	frozen[b] = {eyes = eyes, open = false}
end

local function add(m)
	if m:IsA("BasePart") and m.Name == "IceBlock" then task.defer(addIce, m); return end
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
	-- the dead in the ice: eyes that open as you come by, and watch you
	local me = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	for b, f in pairs(frozen) do
		if not b.Parent then frozen[b] = nil
		elseif me then
			local head = b.Position + Vector3.new(0, 2.7, 0)
			local d = (me.Position - head).Magnitude
			if not f.open and d < 12 then
				f.open = true
				for _, e in ipairs(f.eyes) do TweenService:Create(e, TweenInfo.new(0.35), {Transparency = 0}):Play() end
				WarFX.sound("Creak", head, {volume = 0.45, speed = 1.7, near = 6, range = 40})
			elseif f.open and d > 22 then
				f.open = false
				for _, e in ipairs(f.eyes) do TweenService:Create(e, TweenInfo.new(0.6), {Transparency = 1}):Play() end
			end
			if f.open or f.eyes[1].Transparency < 1 then
				-- (they turn a little toward you as you pass)
				local face = b.CFrame.LookVector
				local look = Vector3.new(me.Position.X - head.X, 0, me.Position.Z - head.Z)
				look = look.Magnitude > 0.1 and look.Unit or face
				local dir = (face * 0.75 + look * 0.25).Unit
				local right = dir:Cross(Vector3.yAxis).Unit
				for i, e in ipairs(f.eyes) do
					table.insert(parts, e)
					table.insert(cfs, CFrame.new(head + dir * 0.6 + right * (i == 1 and -0.24 or 0.24) + Vector3.new(0, 0.08, 0)))
				end
			end
		end
	end
	if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
end)
