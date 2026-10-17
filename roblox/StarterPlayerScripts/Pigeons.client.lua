--[[ PIGEONS — a flock about the Courtyard's fountain, on your screen only: they peck at the
     cobbles and the fountain's rim, hop a step now and then, and when anyone comes hurrying through
     them (a player or a bot, faster than a stroll, within a few studs of one) the whole flock goes
     up at once in a clatter of wings (WarAudio ▸ Pigeons), off over the walls; a while later they
     drift back down by twos and threes to new spots.

     Only in the Hub, round Map ▸ Spots ▸ WellSpot (Build ▸ MapCourtyard). Fewer on a phone.
     Nothing here is sent to the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local round = ReplicatedStorage:WaitForChild("Round")

local V3, CF = Vector3.new, CFrame.new
local N = Device.kind() == "phone" and 6 or 11
local K = 1.3   -- (their size)
local SCARE_R, SCARE_SPEED = 8, 7
local GREYS = {Color3.fromRGB(128, 132, 142), Color3.fromRGB(150, 152, 160), Color3.fromRGB(96, 98, 108), Color3.fromRGB(176, 170, 166)}

local flock = nil   -- {birds, centre, home folder, conn, scaredAt}

local function part(home, size, color, ball)
	local p = Instance.new("Part")
	p.Size, p.Color, p.Material = size, color, Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	if ball then
		local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
	end
	p.Parent = home
	return p
end

-- a spot to stand: on the cobbles round the basin, or up on its rim
local function spot(c, rng)
	if rng:NextNumber() < 0.3 then
		local a = rng:NextNumber(0, math.pi * 2)
		return c + V3(math.cos(a) * 11.7, 4.75, math.sin(a) * 11.7)
	end
	local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(14.5, 24)
	return c + V3(math.cos(a) * r, 0.05, math.sin(a) * r)
end

local function stop()
	if not flock then return end
	if flock.conn then flock.conn:Disconnect() end
	flock.home:Destroy()
	flock = nil
end

local function start(map)
	stop()
	-- (the map streams in: wait a little for its spot)
	local spots = map:WaitForChild("Spots", 15)
	local well = spots and spots:WaitForChild("WellSpot", 15)
	if not well or workspace:FindFirstChild("Map") ~= map then return end
	local c = V3(well.Position.X, 0, well.Position.Z)
	-- (the ground under the courtyard: the fountain's step stands at its foot)
	local ray = RaycastParams.new(); ray.FilterType = Enum.RaycastFilterType.Include; ray.FilterDescendantsInstances = {map}
	local g = workspace:Raycast(c + V3(0, 50, 26), V3(0, -100, 0), ray)
	c = V3(c.X, g and g.Position.Y or 0, c.Z)
	local home = Instance.new("Folder")
	home.Name = "Pigeons"
	home.Parent = workspace
	local rng = Random.new()
	local birds = {}
	for i = 1, N do
		local col = GREYS[rng:NextInteger(1, #GREYS)]
		local b = {
			body = part(home, V3(0.62, 0.5, 0.9) * K, col, true),
			head = part(home, V3(0.36, 0.36, 0.36) * K, col:Lerp(Color3.fromRGB(70, 90, 110), 0.3), true),
			beak = part(home, V3(0.08, 0.08, 0.2) * K, Color3.fromRGB(60, 54, 50)),
			wl = part(home, V3(0.08, 0.36, 0.7) * K, col:Lerp(Color3.new(0, 0, 0), 0.15)),
			wr = part(home, V3(0.08, 0.36, 0.7) * K, col:Lerp(Color3.new(0, 0, 0), 0.15)),
			tail = part(home, V3(0.36, 0.06, 0.4) * K, col:Lerp(Color3.new(0, 0, 0), 0.25)),
			pos = spot(c, rng), yaw = rng:NextNumber(0, math.pi * 2), mode = "ground",
			ph = rng:NextNumber(0, 6), nextHop = os.clock() + rng:NextNumber(1, 6),
		}
		table.insert(birds, b)
	end
	flock = {birds = birds, centre = c, home = home, scaredAt = -1e9}
	local parts, cfs = {}, {}
	local function hide(b)
		for _, p in ipairs({b.body, b.head, b.beak, b.wl, b.wr, b.tail}) do p.Transparency = 1 end
	end
	local function show(b)
		for _, p in ipairs({b.body, b.head, b.beak, b.wl, b.wr, b.tail}) do p.Transparency = 0 end
	end
	local function scare(from)
		local now = os.clock()
		if now - flock.scaredAt < 4 then return end
		flock.scaredAt = now
		WarFX.sound("Pigeons", c + V3(0, 3, 0), {volume = 0.8, near = 15, range = 120, speed = 0.95 + math.random() * 0.1})
		for _, b in ipairs(birds) do
			if b.mode == "ground" or b.mode == "hop" then
				local away = V3(b.pos.X - from.X, 0, b.pos.Z - from.Z)
				away = away.Magnitude > 0.1 and away.Unit or V3(math.random() - 0.5, 0, math.random() - 0.5).Unit
				local out = (away + V3(math.random() - 0.5, 0, math.random() - 0.5) * 0.8).Unit
				b.mode, b.t0, b.wait = "up", now + math.random() * 0.25, 0
				b.from = b.pos
				-- (up and away over the walls: gone past them)
				b.to = b.pos + out * (70 + math.random() * 40) + V3(0, 32 + math.random() * 16, 0)
				b.yaw = math.atan2(-out.X, -out.Z)
			end
		end
	end
	flock.conn = RunService.RenderStepped:Connect(function(dt)
		local cam = workspace.CurrentCamera
		if not cam or (cam.CFrame.Position - c).Magnitude > 220 then return end
		local now = os.clock()
		-- who's hurrying through them
		local movers = {}
		for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(movers, p.Character) end end
		local npcs = workspace:FindFirstChild("NPCs")
		for _, m in ipairs(npcs and npcs:GetChildren() or {}) do table.insert(movers, m) end
		for _, m in ipairs(movers) do
			local r = m:FindFirstChild("HumanoidRootPart")
			if r and V3(r.AssemblyLinearVelocity.X, 0, r.AssemblyLinearVelocity.Z).Magnitude > SCARE_SPEED then
				for _, b in ipairs(birds) do
					if (b.mode == "ground" or b.mode == "hop") and (V3(r.Position.X, b.pos.Y, r.Position.Z) - b.pos).Magnitude < SCARE_R then scare(r.Position); break end
				end
			end
		end
		table.clear(parts); table.clear(cfs)
		for _, b in ipairs(birds) do
			local flap, peck, lift = 0, 0, 0
			if b.mode == "ground" then
				-- (pecking: the head dips now and then)
				peck = math.max(0, math.sin(now * 3.1 + b.ph)) ^ 6
				if now > b.nextHop then
					b.mode, b.t0 = "hop", now
					b.from = b.pos
					local a = math.random() * math.pi * 2
					local to = b.pos + V3(math.cos(a), 0, math.sin(a)) * (0.8 + math.random() * 1.2)
					b.to = (to - V3(c.X, to.Y, c.Z)).Magnitude < 13.5 and b.pos.Y < 3 and b.pos or to
					b.yaw = math.atan2(-(b.to.X - b.from.X), -(b.to.Z - b.from.Z))
				end
			elseif b.mode == "hop" then
				local u = math.clamp((now - b.t0) / 0.35, 0, 1)
				b.pos = b.from:Lerp(b.to, u)
				lift = math.sin(u * math.pi) * 0.35
				if u >= 1 then b.mode, b.nextHop = "ground", now + 2 + math.random() * 6 end
			elseif b.mode == "up" then
				local u = math.clamp((now - b.t0) / 3.2, 0, 1)
				if u > 0 then
					local e = u * u * (3 - 2 * u)
					b.pos = b.from:Lerp(b.to, e) + V3(0, math.sin(u * math.pi) * 6, 0)
					flap = 1
				end
				if u >= 1 then
					b.mode, b.wait = "away", now + 12 + math.random() * 14
					hide(b)
				end
			elseif b.mode == "away" then
				if now > b.wait then
					-- (back in, gliding down to a new spot)
					b.mode, b.t0 = "down", now
					b.to = spot(c, rng)
					local a = math.random() * math.pi * 2
					b.from = b.to + V3(math.cos(a) * 60, 30 + math.random() * 10, math.sin(a) * 60)
					b.pos = b.from
					b.yaw = math.atan2(-(b.to.X - b.from.X), -(b.to.Z - b.from.Z))
					show(b)
				end
			elseif b.mode == "down" then
				local u = math.clamp((now - b.t0) / 3, 0, 1)
				local e = 1 - (1 - u) ^ 2
				b.pos = b.from:Lerp(b.to, e)
				flap = u < 0.7 and 0.5 or 1
				if u >= 1 then b.mode, b.nextHop = "ground", now + 2 + math.random() * 5 end
			end
			if b.mode ~= "away" then
				local base = CF(b.pos + V3(0, 0.32 * K + lift, 0)) * CFrame.Angles(0, b.yaw, 0) * CFrame.Angles(flap > 0 and -0.25 or 0, 0, 0)
				local beat = flap > 0 and math.sin(now * 30 + b.ph) * 1.1 * flap or 0
				table.insert(parts, b.body); table.insert(cfs, base)
				local hc = base * CF(0, (0.32 - peck * 0.42) * K, (-0.42 - peck * 0.12) * K)
				table.insert(parts, b.head); table.insert(cfs, hc)
				table.insert(parts, b.beak); table.insert(cfs, hc * CF(0, -0.03 * K, -0.24 * K) * CFrame.Angles(math.rad(peck * 40), 0, 0))
				table.insert(parts, b.wl); table.insert(cfs, base * CF(-0.3 * K, 0.08 * K, 0.05 * K) * CFrame.Angles(0, 0, beat) * CF(-0.02, 0, 0))
				table.insert(parts, b.wr); table.insert(cfs, base * CF(0.3 * K, 0.08 * K, 0.05 * K) * CFrame.Angles(0, 0, -beat) * CF(0.02, 0, 0))
				table.insert(parts, b.tail); table.insert(cfs, base * CF(0, 0.05 * K, 0.55 * K) * CFrame.Angles(math.rad(-12), 0, 0))
			end
		end
		if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	end)
end

local want = 0
local function refresh()
	want += 1
	local w = want
	task.delay(1.5, function()
		if want ~= w then return end
		local map = workspace:FindFirstChild("Map")
		if round:GetAttribute("Mode") == "Hub" and map then start(map) else stop() end
	end)
end
workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then refresh() end end)
workspace.ChildRemoved:Connect(function(c) if c.Name == "Map" then stop() end end)
round:GetAttributeChangedSignal("Mode"):Connect(refresh)
refresh()
