--[[ TRAPS (client) — the dungeon's traps moving, on your screen (Game ▸ Traps decides every hit;
     this only draws them, from what each trap Model in Map ▸ Traps carries):

       blade    swings on the server's clock (workspace:GetServerTimeNow()), so every screen sees
                it in the same place the server judges it; a heavy whoosh each pass when near
       spikes   the click when someone steps on it (FiredAt), then the spikes punch up through
                the grate with a ring of steel, stand, and sink back
       darts    the click, then darts hiss out of the holes and across the corridor

     Only traps near the camera are moved. Nothing here is sent to the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Sounds = require(ReplicatedStorage:WaitForChild("Sounds"))

local V3, CF = Vector3.new, CFrame.new
local UP = V3(0, 1, 0)
local NEAR = 140
local RISE, HOLD = 0.5, 1.6   -- (Game ▸ Traps.SPIKES: up at +rise, down at +hold)

local blades = {}   -- model -> {pivot, cross, arm, amp, period, phase, parts, offs, lastSign}
local function clock() return workspace:GetServerTimeNow() end

local function sound(pool, part, vol, speed)
	if part and part.Parent then Sounds.bank(pool, part, {Volume = vol, Speed = speed}) end
end

--------------------------------------------------------------------
--  BLADES
--------------------------------------------------------------------
local function addBlade(m)
	local pivot, cross = m:GetAttribute("Pivot"), m:GetAttribute("Cross")
	if typeof(pivot) ~= "Vector3" or typeof(cross) ~= "Vector3" then return end
	local frame = CFrame.fromMatrix(pivot, cross, UP)
	local b = {pivot = pivot, frame = frame, arm = m:GetAttribute("Arm") or 10, amp = m:GetAttribute("Amp") or 0.5,
		period = m:GetAttribute("Period") or 3, phase = m:GetAttribute("Phase") or 0, parts = {}, offs = {}, lastSign = 0}
	for _, p in ipairs(m:GetChildren()) do
		-- (the slot in the ceiling stays; everything else swings)
		if p:IsA("BasePart") and p.Name ~= "Slot" then
			table.insert(b.parts, p)
			table.insert(b.offs, frame:ToObjectSpace(p.CFrame))
		end
	end
	b.blade = m:FindFirstChild("Blade")
	blades[m] = b
end

local ps, cfs = {}, {}
RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam or not next(blades) then return end
	local eye = cam.CFrame.Position
	local now = clock()
	local n = 0
	for m, b in pairs(blades) do
		if not m.Parent then
			blades[m] = nil
		elseif (b.pivot - eye).Magnitude < NEAR then
			local w = now / b.period * math.pi * 2 + b.phase
			local th = b.amp * math.sin(w)
			local swing = b.frame * CFrame.Angles(0, 0, th)
			for i, p in ipairs(b.parts) do
				n += 1
				ps[n] = p
				cfs[n] = swing * b.offs[i]
			end
			-- (a heavy whoosh as it passes the bottom, when you're near enough to hear it)
			local sign = math.sin(w) >= 0 and 1 or -1
			if sign ~= b.lastSign then
				b.lastSign = sign
				if (b.pivot - eye).Magnitude < 45 then sound("SwingHeavy", b.blade, 0.9, 0.62 + math.random() * 0.1) end
			end
		end
	end
	for i = n + 1, #ps do ps[i] = nil; cfs[i] = nil end
	if n > 0 then workspace:BulkMoveTo(ps, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
end)

--------------------------------------------------------------------
--  SPIKES
--------------------------------------------------------------------
local function addSpikes(m)
	local spikes = {}
	for _, p in ipairs(m:GetChildren()) do
		if p.Name == "Spike" and p:IsA("BasePart") then table.insert(spikes, {p, p.CFrame}) end
	end
	local grate = m:FindFirstChild("Grate")
	m:GetAttributeChangedSignal("FiredAt"):Connect(function()
		local at = m:GetAttribute("FiredAt")
		if type(at) ~= "number" or not grate then return end
		sound("WallMetal", grate, 0.5, 1.7)
		task.spawn(function()
			-- (wait for the rise on the server's clock)
			local wait = at + RISE - clock()
			if wait > 0 then task.wait(wait) end
			if not m.Parent then return end
			sound("HitPlate", grate, 0.9, 0.8)
			local t0 = os.clock()
			local up = 2.9
			while m.Parent do
				local t = os.clock() - t0
				local h
				if t < 0.07 then h = up * (t / 0.07)
				elseif t < HOLD - RISE then h = up
				elseif t < HOLD - RISE + 0.45 then h = up * (1 - (t - (HOLD - RISE)) / 0.45)
				else h = 0 end
				for _, s in ipairs(spikes) do
					if s[1].Parent then s[1].CFrame = s[2] + UP * h end
				end
				if h == 0 and t > 0.1 then break end
				task.wait()
			end
		end)
	end)
end

--------------------------------------------------------------------
--  DARTS
--------------------------------------------------------------------
local function addDarts(m)
	local plate = m:FindFirstChild("Plate")
	m:GetAttributeChangedSignal("FiredAt"):Connect(function()
		local at = m:GetAttribute("FiredAt")
		local cross, side = m:GetAttribute("Cross"), m:GetAttribute("Side") or 1
		if type(at) ~= "number" or typeof(cross) ~= "Vector3" or not plate then return end
		sound("WallMetal", plate, 0.5, 1.8)
		task.delay(math.max(0, at + 0.15 - clock()), function()
			if not m.Parent then return end
			local dir = -cross * side
			for _, hole in ipairs(m:GetChildren()) do
				if hole.Name == "DartHole" and hole:IsA("BasePart") then
					local d = Instance.new("Part")
					d.Name = "Dart"
					d.Size = V3(0.12, 0.12, 1.1)
					d.Color = Color3.fromRGB(60, 46, 34)
					d.Material = Enum.Material.Wood
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = true, false, false, false, false
					local from = hole.Position
					d.CFrame = CFrame.lookAt(from, from + dir)
					d.Parent = workspace.Terrain
					sound("SwingLight", d, 0.4, 1.6 + math.random() * 0.3)
					task.spawn(function()
						local t0 = os.clock()
						while d.Parent do
							local u = math.min((os.clock() - t0) / 0.16, 1)
							d.CFrame = CFrame.lookAt(from + dir * 11.6 * u, from + dir * (11.6 * u + 1))
							if u >= 1 then break end
							task.wait()
						end
						sound("WallWood", d, 0.5, 1.2)
						Debris:AddItem(d, 2.5)
					end)
				end
			end
		end)
	end)
end

--------------------------------------------------------------------
--  FINDING THEM
--------------------------------------------------------------------
-- the part each kind can't do without (a trap streams whole, but wait for it to be sure)
local KEY = {blade = "Blade", spikes = "Grate", darts = "Plate"}
local function add(m)
	if not m:IsA("Model") then return end
	local kind = m:GetAttribute("Trap")
	if KEY[kind] and not m:WaitForChild(KEY[kind], 10) then return end
	task.wait(0.1)
	if kind == "blade" then addBlade(m)
	elseif kind == "spikes" then addSpikes(m)
	elseif kind == "darts" then addDarts(m) end
end
local function watchFolder(f)
	for _, m in ipairs(f:GetChildren()) do task.spawn(add, m) end
	f.ChildAdded:Connect(function(m) task.spawn(add, m) end)
end
local function watchMap(map)
	local f = map:FindFirstChild("Traps")
	if f then watchFolder(f) end
	map.ChildAdded:Connect(function(c) if c.Name == "Traps" then watchFolder(c) end end)
end
local map = workspace:FindFirstChild("Map")
if map then watchMap(map) end
workspace.ChildAdded:Connect(function(c) if c.Name == "Map" and c:IsA("Model") then watchMap(c) end end)
