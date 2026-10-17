--[[ WARFIELD — a duel in the middle of a battle, on your screen only (ReplicatedStorage ▸
     WarCrowd and WarFX: never fighters, nothing replicated). On any map whose Map model carries
     a Warfield attribute (the duel ring's radius: MapForge's "warfield" layout, The Lists'
     Redmeadow, Ironvale, Grimfield) two armies fight all round the ring:

       either side of it   their battle lines meet: three lanes a side (foot, pikes, knights),
                           wavering, pulling apart, charging again, men falling and flung
       behind them         each side's archers, whose volleys arc right over the ring onto the
                           enemy's lines, its battle-mages' fire, deep reserves, the standards
       all round           the opening charge with horns and drums, cavalry riding down a flank,
                           dust over the melee, smoke from burning wagons, the din of it all

     The side in blue (A) stands to the south (towards -z), red (B) to the north. The winners of
     a round cheer. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local WarCrowd = require(ReplicatedStorage:WaitForChild("WarCrowd"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))

local player = Players.LocalPlayer
local round = ReplicatedStorage:WaitForChild("Round")

local V3 = Vector3.new
local DUST = Color3.fromRGB(150, 136, 116)
local SIDE = {A = Color3.fromRGB(70, 120, 240), B = Color3.fromRGB(226, 66, 54)}
local KINDS = {"foot", "pike", "knight"}

local function phone() return Device.kind() == "phone" end
local function myPos()
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return r and r.Position or nil
end
local function ringOf()
	local m = workspace:FindFirstChild("Map")
	local a = m and m:GetAttribute("Warfield")
	return type(a) == "number" and a or nil
end

local field = {on = false, token = 0}

--------------------------------------------------------------------
--  THE ARMIES
--------------------------------------------------------------------
local function build(A)
	local small = phone()
	WarCrowd.SCALE = small and 0.6 or 1
	local crowd = WarCrowd.new()
	field.crowd = crowd
	field.A = A
	-- the lanes either side of the ring (the nearest just past its shields)
	field.lanes = {}
	for li = 1, small and 2 or 3 do table.insert(field.lanes, A + 22 + (li - 1) * 44) end
	for _, s in ipairs({-1, 1}) do
		for li, x in ipairs(field.lanes) do
			for _, side in ipairs({"A", "B"}) do
				local f = side == "A" and 1 or -1
				-- (they start well apart: the opening charge brings them together)
				crowd:regiment(side .. s .. li, {side = side, kind = KINDS[li], at = V3(s * x, 0, -f * 46), facing = f,
					cols = 12, ranks = li == 1 and 5 or 6, spacing = 3.1, detail = li == 1 and "full" or (li == 2 and "lite" or "mass")})
			end
		end
	end
	for _, side in ipairs({"A", "B"}) do
		local f = side == "A" and 1 or -1
		-- the archers straight behind the ring: their arrows fly over it
		crowd:regiment("arch" .. side, {side = side, kind = "archer", at = V3(0, 0, -f * (A + 42)), facing = f, cols = 12, ranks = 3, spacing = 2.8, detail = "lite"})
		crowd:regiment("mage" .. side, {side = side, kind = "mage", at = V3(f * 34, 0, -f * (A + 52)), facing = f, cols = 4, ranks = 2, spacing = 3.4, detail = "lite", banner = false})
		if not small then
			for _, s in ipairs({-1, 1}) do
				crowd:regiment("res" .. side .. s, {side = side, kind = "pike", at = V3(s * 66, 0, -f * (A + 86)), facing = f, cols = 14, ranks = 6, spacing = 3, detail = "mass"})
			end
		end
	end
	-- the din, the dust, the smoke
	field.loops, field.hazes, field.columns = {}, {}, {}
	for _, s in ipairs({-1, 1}) do
		field.loops["melee" .. s] = WarFX.loop3D("Melee", V3(s * field.lanes[1], 3, 0), {volume = 1.2, near = 45, range = 500})
		field.loops["roar" .. s] = WarFX.loop3D("Roar", V3(s * (field.lanes[2] or field.lanes[1]), 6, 0), {volume = 0.9, near = 90, range = 1000})
		for li, x in ipairs(field.lanes) do field.hazes[s .. ":" .. li] = WarFX.haze(V3(s * x, 2, 0), {width = 46, depth = 14, rate = small and 2 or 5}) end
	end
	field.loops.drums = WarFX.loop("Drums", 0.45)
	field.crows = WarFX.crows(V3(0, 0, 0), {n = small and 8 or 14, radius = 110, height = 75})
	field.battle = WarFX.loop("Battle", 0.5)
	for k = 1, small and 2 or 4 do
		local sx = k % 2 == 0 and 1 or -1
		local sz = k <= 2 and 1 or -1
		table.insert(field.columns, WarFX.column(WarFX.ground(V3(sx * (110 + math.random() * 60), 0, sz * (120 + math.random() * 50))), {fire = k <= 2, scale = 0.9 + math.random() * 0.6}))
	end
	field.charged = false
	field.chargeAt = os.clock() + 5
	field.nextVolley = os.clock() + 9
	field.nextFire = os.clock() + 16
	field.nextRiders = os.clock() + 40
end

-- the opening charge
local function charge()
	field.charged = true
	WarFX.sound("Horn", nil, {volume = 0.9})
	task.delay(0.8, function() if field.on then WarFX.sound("Charge", nil, {volume = 0.9}) end end)
end

-- every half second: the lines fight, the archers loose over the ring, fire falls, riders charge
local function life(now)
	local crowd = field.crowd
	if not crowd then return end
	if not field.charged then
		if now < field.chargeAt then return end
		charge()
	end
	for _, s in ipairs({-1, 1}) do
		for li in ipairs(field.lanes) do
			local crash, at = crowd:lane("A" .. s .. li, "B" .. s .. li, 0, now, 1)
			if crash then
				WarFX.dust(crash + V3(0, 1, 0), 3, DUST)
				WarFX.sound("Gate", crash, {range = 450, near = 40, speed = 1.3, volume = 0.6})
				local me = myPos()
				if me and (me - crash).Magnitude < 90 then WarFX.shake(0.6 * (1 - (me - crash).Magnitude / 90) + 0.08, 0.45) end
				for _ = 1, 3 do crowd:blast(crash + V3((math.random() - 0.5) * 30, 0, 0), 2.5) end
			end
			local hz = field.hazes[s .. ":" .. li]
			if hz and at then hz.move(at + V3(0, 2, 0)) end
		end
	end
	-- the archers: a volley over the ring onto the enemy's line on a flank
	if now >= field.nextVolley then
		field.nextVolley = now + 5 + math.random() * 4
		local side = math.random() < 0.5 and "A" or "B"
		local reg = crowd.regs["arch" .. side]
		if reg then
			crowd:loose("arch" .. side)
			local f = side == "A" and 1 or -1
			local s = math.random() < 0.5 and -1 or 1
			local x = field.lanes[math.random(#field.lanes)]
			local to = WarFX.ground(V3(s * x + (math.random() - 0.5) * 24, 0, f * (10 + math.random() * 10)))
			task.delay(0.9, function()
				if not field.on or field.crowd ~= crowd then return end
				WarFX.volley(V3(reg.x, (reg.y0 or 0) + 6, reg.z), to, 90, {flight = 3, spread = 12, stick = false, range = 300, height = 60})
				task.delay(3, function() if field.crowd == crowd then crowd:hit(to, 12, 5) end end)
			end)
		end
	end
	-- the battle-mages: fire arcing high over the field onto the enemy's lines
	if now >= field.nextFire then
		field.nextFire = now + 10 + math.random() * 8
		local side = math.random() < 0.5 and "A" or "B"
		local reg = crowd.regs["mage" .. side]
		if reg then
			crowd:loose("mage" .. side)
			local f = side == "A" and 1 or -1
			for k = 1, 3 do
				task.delay(0.6 + k * 0.45, function()
					if not field.on or field.crowd ~= crowd then return end
					local s = math.random() < 0.5 and -1 or 1
					local to = WarFX.ground(V3(s * field.lanes[math.random(#field.lanes)] + (math.random() - 0.5) * 20, 0, f * (8 + math.random() * 16)))
					WarFX.fireball(V3(reg.x, (reg.y0 or 0) + 8, reg.z), to, 3.4, {big = k == 2, color = side == "A" and Color3.fromRGB(110, 150, 255) or nil,
						onLand = function(p) if field.crowd == crowd then crowd:blast(p, 9) end end})
				end)
			end
		end
	end
	-- the cavalry rides down a flank (outside the lanes) and ploughs into the enemy's line
	if now >= field.nextRiders then
		field.nextRiders = now + 50 + math.random() * 40
		local side = math.random() < 0.5 and "A" or "B"
		local f = side == "A" and 1 or -1
		local s = math.random() < 0.5 and -1 or 1
		local x = s * (field.lanes[#field.lanes] + 30)
		local path = {WarFX.ground(V3(x, 0, -f * 160)), WarFX.ground(V3(x, 0, -f * 20)), WarFX.ground(V3(x - s * 30, 0, f * 40))}
		WarFX.riders(path, phone() and 8 or 14, {color = SIDE[side], speed = 52})
		WarFX.sound("Horn", path[1], {volume = 0.8, range = 900})
		local dist = (path[2] - path[1]).Magnitude
		for k = 0, 4 do
			task.delay(dist / 52 + k * 0.35, function()
				if field.on and field.crowd == crowd then crowd:blast(V3(x - s * k * 5, 0, f * (k * 8)), 9) end
			end)
		end
	end
end

--------------------------------------------------------------------
--  COMING AND GOING
--------------------------------------------------------------------
local function leave()
	if not field.on then return end
	field.on = false
	field.token += 1
	if field.crowd then field.crowd:stop(); field.crowd = nil end
	if field.crows then field.crows.stop(); field.crows = nil end
	-- (a 2D loop is the Sound itself; a placed one a handle)
	for _, l in pairs(field.loops or {}) do if typeof(l) == "Instance" then WarFX.stopLoop(l, 1) elseif l then l.stop(1) end end
	for _, h in pairs(field.hazes or {}) do h.stop() end
	for _, c in ipairs(field.columns or {}) do c.stop() end
	WarFX.stopLoop(field.battle, 1)
	field.loops, field.hazes, field.columns, field.battle = {}, {}, {}, nil
end

local function enter()
	if field.on then return end
	local A = ringOf()
	if not A then return end
	field.on = true
	field.token += 1
	local token = field.token
	task.spawn(function()
		-- (the field before the ring streams in first: the men stand on it)
		for _ = 1, 40 do
			if workspace:Raycast(V3(A + 22, 200, 0), V3(0, -400, 0)) or field.token ~= token then break end
			task.wait(0.5)
		end
		if field.token ~= token then return end
		build(A)
		while field.on and field.token == token do
			local ok, err = pcall(life, os.clock())
			if not ok then warn("[Warfield] " .. tostring(err)) end
			task.wait(0.5)
		end
	end)
end

-- a round won: the winners cheer
round:GetAttributeChangedSignal("State"):Connect(function()
	if not (field.on and field.crowd) or round:GetAttribute("State") ~= "Intermission" then return end
	local winner = round:GetAttribute("Winner") or ""
	for k, d in pairs(GameConfig.TEAMS) do
		if d.name == winner then field.crowd:cheer(k) end
	end
end)
-- a new map: the battle again (or none)
local want = 0
local function refresh()
	want += 1
	local w = want
	task.delay(0.8, function()
		if want ~= w then return end
		if field.on and ringOf() then return end
		leave()
		enter()
	end)
end
round:GetAttributeChangedSignal("Map"):Connect(function()
	leave()
	refresh()
end)
workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then refresh() end end)
refresh()
