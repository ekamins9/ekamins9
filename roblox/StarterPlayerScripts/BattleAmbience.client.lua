--[[ BATTLE AMBIENCE — the war going on round a fight, on your screen only (Team Deathmatch,
     King of the Hill, Last Team Standing, Free-for-all, Kingslayer: War, Siege and the warfields
     draw their own): your fight is one corner of a bigger battle.

       the horizon      columns of smoke rising beyond the map's edge, a fire under one
       the sky          now and then a volley arcs high over the whole field from one side to the
                        other (it lands far beyond it), a trebuchet's fire streaks across
       the din          the battle beyond, low under everything; the roar of an army off to one
                        side; a distant horn

     Reads the Map's Centre and Radius (MapLoader). ReplicatedStorage ▸ WarFX does the drawing. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))

local round = ReplicatedStorage:WaitForChild("Round")
local V3 = Vector3.new
local MODES = {TDM = true, KOTH = true, LTS = true, FFA = true, Kingslayer = true}

local amb = {on = false, token = 0}

local function fits()
	if not MODES[round:GetAttribute("Mode") or ""] then return nil end
	local m = workspace:FindFirstChild("Map")
	if not m or m:GetAttribute("Warfield") or m:GetAttribute("Generated") then return nil end
	local c, r = m:GetAttribute("Centre"), m:GetAttribute("Radius")
	if typeof(c) ~= "Vector3" or type(r) ~= "number" then return nil end
	return c, r
end

-- a point out past the map's edge, at an angle
local function beyond(c, r, a, extra)
	return V3(c.X + math.cos(a) * (r + extra), c.Y, c.Z + math.sin(a) * (r + extra))
end

-- the ground out there (or below the horizon, where nothing's built: it lands out of sight)
local function groundBeyond(c, p)
	local g = WarFX.ground(p + V3(0, 80, 0))
	if g.Y > c.Y + 40 then g = V3(p.X, c.Y - 8, p.Z) end
	return g
end

local function leave()
	if not amb.on then return end
	amb.on = false
	amb.token += 1
	for _, h in ipairs(amb.columns or {}) do h.stop() end
	if amb.roar then amb.roar.stop(2) end
	if amb.din then WarFX.stopLoop(amb.din, 2) end
	if amb.crows then amb.crows.stop(); amb.crows = nil end
	amb.columns, amb.roar, amb.din = {}, nil, nil
end

local function enter(c, r)
	if amb.on then return end
	amb.on = true
	amb.token += 1
	local token = amb.token
	local small = Device.kind() == "phone"
	-- the horizon: smoke beyond the edge, one with its fire showing
	amb.columns = {}
	local base = math.random() * math.pi * 2
	for k = 1, small and 2 or 3 do
		local a = base + k * 2.1 + (math.random() - 0.5) * 0.6
		local at = groundBeyond(c, beyond(c, r, a, 90 + math.random() * 90))
		table.insert(amb.columns, WarFX.column(at, {scale = 1.4 + math.random() * 0.9, fire = k == 1}))
	end
	-- the din: the battle beyond, low; an army roaring off to one side
	amb.din = WarFX.loop("Battle", 0.2)
	amb.crows = WarFX.crows(c, {n = small and 6 or 10, radius = math.clamp(r * 0.8, 50, 140), height = 70})
	amb.side = base + math.pi
	amb.roar = WarFX.loop3D("Roar", beyond(c, r, amb.side, 160) + V3(0, 10, 0), {volume = 0.6, near = 120, range = 1400})
	task.spawn(function()
		local nextVolley = os.clock() + 15 + math.random() * 15
		local nextFire = os.clock() + 30 + math.random() * 20
		local nextHorn = os.clock() + 20 + math.random() * 30
		while amb.on and amb.token == token do
			local now = os.clock()
			-- a volley high over the whole field, from beyond one edge to beyond the other
			if now >= nextVolley then
				nextVolley = now + 25 + math.random() * 25
				local a = amb.side + (math.random() - 0.5) * 1.2
				local from = beyond(c, r, a, 120) + V3(0, 8, 0)
				local to = groundBeyond(c, beyond(c, r, a + math.pi + (math.random() - 0.5) * 0.4, 150))
				WarFX.volley(from, to, small and 40 or 70, {flight = 5, spread = 20, stick = false, height = math.clamp(r * 0.9, 90, 170), range = 500})
			end
			-- a trebuchet's fire streaking over, landing far off with a deep boom
			if now >= nextFire then
				nextFire = now + 40 + math.random() * 30
				local a = amb.side + (math.random() - 0.5) * 0.8
				local from = beyond(c, r, a, 220) + V3(0, 40, 0)
				local to = groundBeyond(c, beyond(c, r, a + math.pi + (math.random() - 0.5) * 0.6, 170))
				WarFX.fireball(from, to, 6, {big = true, far = true, scorch = false})
			end
			if now >= nextHorn then
				nextHorn = now + 50 + math.random() * 40
				WarFX.sound("Horn", beyond(c, r, amb.side + (math.random() - 0.5), 200), {volume = 0.45, range = 2000, near = 200, speed = 0.9 + math.random() * 0.15})
			end
			task.wait(1)
		end
	end)
end

local want = 0
local function refresh()
	want += 1
	local w = want
	task.delay(1, function()
		if want ~= w then return end
		local c, r = fits()
		if c and amb.on and (amb.c ~= c) then leave() end
		if c and not amb.on then amb.c = c; enter(c, r)
		elseif not c then leave() end
	end)
end
round:GetAttributeChangedSignal("Mode"):Connect(refresh)
round:GetAttributeChangedSignal("Map"):Connect(refresh)
workspace.ChildAdded:Connect(function(ch) if ch.Name == "Map" then refresh() end end)
refresh()
