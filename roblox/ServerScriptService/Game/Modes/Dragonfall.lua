--[[ DRAGONFALL — you and your party against a dragon (GameConfig.MODES.Dragonfall, DOORS.Dragonfall).
     The Ashen Caldera (Game ▸ CalderaMap, built fresh) is CINDERMAW's nest (Combat ▸ Dragon: its
     body, its blows, its brain). A few seconds in it comes down out of the burning sky.

     ON THE GROUND it fights in PATTERNS you can learn (Combat ▸ Dragon COMBOS: claw then bite,
     tail then stomp, wing buffet then fire breath…), every blow called over its head as it winds
     up, what to do the first few times; after each pattern it's OPEN a moment (more damage from
     every blow; after its fire, its belly glows: double). MORE WAYS TO HURT IT:
       THE BALLISTAE (four, on platforms near the rim: hold to fire, a few seconds to wind again)
         fire at it on the ground too: a heavy wound, and two bolts close together PIN it
         (staggered and open). In the sky: enough bolts (3, one more for every two of you past
         that) and it CRASHES, DOWNED for a while: everyone strike.
       THE ROCKFALLS (three, under great shelves of rock at the rim, ROCK_*): boulders hung on
         chains; lure it under one and cut the chains at the lever: a crushing wound, and it's
         FELLED a while. Whoever stands under them is hurt too. They hang again after REARM.
     At two thirds it TAKES TO THE SKY: strafing runs and fireballs, and its BROOD climbs out of
     the lava pools. Under a third it's ENRAGED: quicker, fire rains,
     and now and then it rises over the middle and breathes an INFERNO over everything: get
     behind a WARD STONE (the runes light up when it's coming). The lava burns.

     Kill it: everyone here is paid `dragon_slain` (Catalog ▸ Economy), stats.dragonsSlain and your
     fastest (stats.dragonBest, seconds). The clock runs out first: it holds the caldera. You come
     back (respawnDelay) at the south rim.
     On screen: the boss bar (its health, ENRAGED), the mode's line and hint (OwnHud), guides over
     the ballistae when it's up there and over the ward stones before an Inferno (Adventure.client
     reads GuideText on Map ▸ Ballistae / Wards). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Game = require(script.Parent.Parent:WaitForChild("Game"))
local CalderaMap = require(script.Parent.Parent:WaitForChild("CalderaMap"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Dragon = require(Combat:WaitForChild("Dragon"))
local Monsters = require(Combat:WaitForChild("Monsters"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local MapLoader = Game.MapLoader
local node = Game.node

local FIRST = 14          -- seconds before it comes
local RELOAD = 6          -- a ballista's wind
-- THE ROCKFALLS: where (angles round the rim, how far out), how big the drop, when they hang again
local ROCK_ANGLES = {1.45, 2.95, 4.45}
local ROCK_R = 90
local ROCK_ZONE = 14
local REARM = 45
local Moves = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("BossMoves"))
local LAVA_DPS = 12
local GOLD = Color3.fromRGB(255, 190, 60)
local FIRE = Color3.fromRGB(255, 130, 40)

local Dragonfall = setmetatable({}, {__index = Game.Mode})
Dragonfall.__index = Dragonfall
function Dragonfall.new(def, id) return setmetatable(Game.Mode.new(def, id), Dragonfall) end

local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function banner(t, plr) local e = event(); if e then if plr then e:FireClient(plr, "Banner", t) else e:FireAllClients("Banner", t) end end end
local function humOf(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function rootOf(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function sound(id, at, vol, speed)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one; p.Position = at; p.Parent = workspace
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol or 1; s.PlaybackSpeed = speed or 1; s.RollOffMaxDistance = 300
	s.Parent = p; s:Play()
	Debris:AddItem(p, 4)
end

function Dragonfall:buildMap()
	local name, layout = CalderaMap.build()
	self.layout = layout
	Dungeon.sweep(name)
	return name
end

--------------------------------------------------------------------
--  THE BALLISTAE
--------------------------------------------------------------------
-- a ballista can shoot it when it's on the ground, down, or up in the sky (not mid-turn: taking
-- off, crashing, landing, its Inferno)
local SHOOTABLE = {ground = true, downed = true, sky = true}
function Dragonfall:canShoot()
	local d = self.dragon
	return d ~= nil and d.alive and SHOOTABLE[d.state] == true
end
function Dragonfall:setBallistae()
	local on = self:canShoot()
	local sky = on and self.dragon.state == "sky"
	for _, b in ipairs(self.ballistae or {}) do
		local ready = os.clock() >= b.readyAt
		b.prompt.Enabled = on and ready
		-- (the guides: while it's in the sky, where they bring it down)
		b.model:SetAttribute("GuideText", sky and ready and "BALLISTA" or nil)
	end
end

function Dragonfall:fire(b, plr)
	local d = self.dragon
	if not self:canShoot() then return end
	if os.clock() < b.readyAt then return end
	local char = plr.Character
	local h = humOf(char)
	if not (h and h.Health > 0) then return end
	b.readyAt = os.clock() + RELOAD
	b.model:SetAttribute("GuideText", nil)
	b.prompt.Enabled = false
	-- it swings onto the dragon and looses
	local turret = b.turret
	local pivot = turret.PrimaryPart
	local target = d.root.Position
	turret:PivotTo(CFrame.lookAt(pivot.Position, target) * CFrame.Angles(math.rad(-28), 0, 0))
	local loaded = turret:FindFirstChild("Bolt")
	local tip = turret:FindFirstChild("BoltTip")
	if loaded then loaded.Transparency = 1 end
	if tip then tip.Transparency = 1 end
	if b.fire then b.fire.Enabled = false end
	local from = (loaded and loaded.Position) or pivot.Position
	sound("rbxasset://sounds/swordlunge.wav", from, 1.2, 0.45)
	local bolt = Instance.new("Part")
	bolt.Name = "BallistaBolt"
	bolt.Anchored, bolt.CanCollide, bolt.CanQuery, bolt.CanTouch = true, false, false, false
	bolt.Size = Vector3.new(0.5, 0.5, 7.5)
	bolt.Color, bolt.Material = Color3.fromRGB(120, 90, 60), Enum.Material.Wood
	bolt.CFrame = CFrame.lookAt(from, target)
	bolt.Parent = workspace
	local trail0 = Instance.new("Attachment"); trail0.Position = Vector3.new(0, 0.3, 3); trail0.Parent = bolt
	local trail1 = Instance.new("Attachment"); trail1.Position = Vector3.new(0, -0.3, 3); trail1.Parent = bolt
	local tr = Instance.new("Trail"); tr.Attachment0, tr.Attachment1 = trail0, trail1; tr.Lifetime = 0.25
	tr.Color = ColorSequence.new(Color3.fromRGB(255, 230, 190)); tr.LightEmission = 1; tr.Parent = bolt
	local dur = math.clamp((target - from).Magnitude / 160, 0.25, 0.8)
	TweenService:Create(bolt, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = CFrame.lookAt(target, target + (target - from).Unit)}):Play()
	Debris:AddItem(bolt, dur + 0.05)
	task.delay(dur, function()
		if self.dragon == d and self:canShoot() then
			sound("rbxasset://sounds/impact_explosion_03.mp3", target, 0.8, 1.3)
			d:harpoon(plr)
		end
	end)
	-- winding again
	task.delay(RELOAD, function()
		if Game.current ~= self then return end
		if loaded then loaded.Transparency = 0 end
		if tip then tip.Transparency = 0 end
		if b.fire then b.fire.Enabled = true end
		self:setBallistae()
	end)
end

function Dragonfall:rigBallistae()
	self.ballistae = {}
	local f = MapLoader.current and MapLoader.current:FindFirstChild("Ballistae")
	for _, m in ipairs(f and f:GetChildren() or {}) do
		local turret = m:FindFirstChild("Turret")
		local pivot = turret and turret.PrimaryPart
		if pivot then
			local pr = Instance.new("ProximityPrompt")
			pr.ActionText, pr.ObjectText = "Fire", "Ballista"
			pr.KeyboardKeyCode = Enum.KeyCode.E
			pr.HoldDuration = 0.3
			pr.MaxActivationDistance = 11
			pr.RequiresLineOfSight = false
			pr.Enabled = false
			pr.Parent = pivot
			local coals = m:FindFirstChild("Coals")
			local b = {model = m, turret = turret, prompt = pr, readyAt = 0, fire = coals and coals:FindFirstChild("ReadyFire")}
			pr.Triggered:Connect(function(plr) self:fire(b, plr) end)
			table.insert(self.ballistae, b)
		end
	end
end

--------------------------------------------------------------------
--  THE ROCKFALLS: boulders hung on chains under a shelf of rock at the rim
--------------------------------------------------------------------
local ROCK = Color3.fromRGB(52, 44, 42)
local IRON = Color3.fromRGB(46, 44, 48)
local function part(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Material = mat or Enum.Material.Basalt
	if shape then p.Shape = shape end
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
function Dragonfall:hang(t)
	for _, b in ipairs(t.boulders) do
		b.part.CFrame = b.home
		b.part.Transparency = 0
		b.part.CanCollide = false
	end
	for _, c in ipairs(t.chains) do c.Transparency = 0 end
	t.prompt.Enabled = true
	t.armed = true
end
function Dragonfall:rigRockfalls()
	self.traps = {}
	local map = MapLoader.current
	if not map then return end
	local folder = Instance.new("Folder"); folder.Name = "Rockfalls"; folder.Parent = map
	for i, a in ipairs(ROCK_ANGLES) do
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local side = Vector3.new(-out.Z, 0, out.X)
		local zone = out * ROCK_R
		local m = Instance.new("Model"); m.Name = "Rockfall" .. i; m.Parent = folder
		-- the shelf of rock out from the cliff, over the drop; buttresses under it at the cliff
		local shelfAt = zone + out * 14 + Vector3.new(0, 44, 0)
		part(m, "Shelf", Vector3.new(34, 9, 42), CFrame.lookAt(shelfAt, shelfAt - out), ROCK)
		part(m, "Lip", Vector3.new(26, 5, 8), CFrame.lookAt(shelfAt - out * 19 - Vector3.new(0, 5, 0), shelfAt - out * 30 - Vector3.new(0, 5, 0)) * CFrame.Angles(math.rad(10), 0, 0), ROCK)
		for _, s in ipairs({-1, 1}) do
			local w = Instance.new("WedgePart")
			w.Name = "Buttress"; w.Anchored = true; w.Material = Enum.Material.Basalt; w.Color = ROCK
			w.Size = Vector3.new(8, 38, 16)
			w.CFrame = CFrame.lookAt(zone + out * 30 + side * s * 12 + Vector3.new(0, 20, 0), zone + side * s * 12 + Vector3.new(0, 20, 0))
			w.Parent = m
		end
		-- the boulders on their chains
		local boulders, chains = {}, {}
		for j, off in ipairs({side * -5.5, side * 5.5 + out * 1.5, out * -3}) do
			local s = 9 + (j % 2) * 2
			local at = zone + off + Vector3.new(0, 39.5 - 6 - s / 2, 0)
			local home = CFrame.new(at) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
			local b = part(m, "Boulder", Vector3.new(s, s, s), home, Color3.fromRGB(70 + j * 6, 62, 58), Enum.Material.Slate, Enum.PartType.Ball)
			b.CanCollide = false
			table.insert(boulders, {part = b, home = home, size = s})
			local top, hook = at + Vector3.new(0, s / 2 - 0.5, 0), at + Vector3.new(0, 39.5 - at.Y, 0)
			local len = (hook - top).Magnitude
			local ch = part(m, "Chain", Vector3.new(len, 0.7, 0.7), CFrame.new((top + hook) / 2) * CFrame.Angles(0, 0, math.pi / 2), IRON, Enum.Material.Metal, Enum.PartType.Cylinder)
			ch.CanCollide, ch.CanQuery = false, false
			table.insert(chains, ch)
		end
		-- where it falls: a dark ring on the ground (it glows when the dragon's under it)
		local ring = part(m, "DropZone", Vector3.new(0.2, ROCK_ZONE * 2, ROCK_ZONE * 2), CFrame.new(zone + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(150, 40, 20), Enum.Material.Neon, Enum.PartType.Cylinder)
		ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.Transparency = false, false, false, 0.88
		-- the lever at the cliff's foot, its rope running up to the shelf
		local leverAt = zone + side * 21 + out * 10
		local post = part(m, "Lever", Vector3.new(1.2, 5, 1.2), CFrame.new(leverAt + Vector3.new(0, 2.5, 0)), Color3.fromRGB(92, 62, 38), Enum.Material.Wood)
		part(m, "Handle", Vector3.new(0.5, 3, 0.5), CFrame.new(leverAt + Vector3.new(0, 5.2, 0)) * CFrame.Angles(0, 0, math.rad(35)), IRON, Enum.Material.Metal)
		local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 2.4, 0); a0.Parent = post
		local anchor = m:FindFirstChild("Lip")
		local a1 = Instance.new("Attachment"); a1.Parent = anchor
		local rope = Instance.new("Beam")
		rope.Attachment0, rope.Attachment1 = a0, a1
		rope.Width0, rope.Width1 = 0.3, 0.3
		rope.Color = ColorSequence.new(Color3.fromRGB(120, 90, 60))
		rope.FaceCamera = true
		rope.Segments = 1
		rope.Parent = post
		m.PrimaryPart = post
		-- (fire light: the hanging rocks lit from the shelf, and a torch on the lever, so both read in the gloom)
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom; spot.Range = 48; spot.Angle = 75; spot.Brightness = 3.2
		spot.Color = Color3.fromRGB(255, 150, 80); spot.Shadows = false
		spot.Parent = anchor
		local torch = Instance.new("PointLight")
		torch.Range = 14; torch.Brightness = 2; torch.Color = Color3.fromRGB(255, 160, 80); torch.Shadows = false
		torch.Parent = post
		local flame = Instance.new("Fire"); flame.Size = 2.5; flame.Heat = 4; flame.Parent = m:FindFirstChild("Handle") or post
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText, pr.ObjectText = "Cut the chains", "Rockfall"
		pr.KeyboardKeyCode = Enum.KeyCode.E
		pr.HoldDuration = 0.4
		pr.MaxActivationDistance = 10
		pr.RequiresLineOfSight = false
		pr.Parent = post
		local t = {model = m, zone = zone, boulders = boulders, chains = chains, ring = ring, prompt = pr, armed = true}
		pr.Triggered:Connect(function(plr) self:dropRocks(t, plr) end)
		table.insert(self.traps, t)
	end
end
function Dragonfall:dropRocks(t, plr)
	if not t.armed or Game.current ~= self then return end
	t.armed = false
	t.prompt.Enabled = false
	t.model:SetAttribute("GuideText", nil)
	sound("rbxasset://sounds/swordslash.wav", t.zone + Vector3.new(0, 38, 0), 1.4, 0.35)
	for _, c in ipairs(t.chains) do c.Transparency = 1 end
	for _, b in ipairs(t.boulders) do
		local p = b.part.Position
		local land = CFrame.new(p.X, b.size / 2 - 0.6, p.Z) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		TweenService:Create(b.part, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame = land}):Play()
	end
	task.delay(0.55, function()
		if Game.current ~= self then return end
		sound("rbxasset://sounds/impact_explosion_03.mp3", t.zone, 2, 0.5)
		Moves.remote:FireAllClients("Shake", t.zone, 2.2)
		for _, b in ipairs(t.boulders) do b.part.CanCollide = true end
		-- whoever stood under it
		for _, p in ipairs(Players:GetPlayers()) do
			local r, h = rootOf(p.Character), humOf(p.Character)
			if r and h and h.Health > 0 and Vector3.new(r.Position.X - t.zone.X, 0, r.Position.Z - t.zone.Z).Magnitude < ROCK_ZONE then h:TakeDamage(30) end
		end
		local d = self.dragon
		if d and d:rockfall(plr, t.zone) then
			banner({text = "FELLED!", sub = string.upper(plr.DisplayName) .. " BROUGHT THE ROCKS DOWN ON IT  ·  STRIKE", kind = "victory"})
		else
			banner({text = "THE ROCKS MISSED", sub = "LURE IT UNDER THE SHELF FIRST  ·  THEN CUT THE CHAINS", kind = "fight"}, plr)
		end
	end)
	-- (the rocks crumble away, and new ones are hung)
	task.delay(8, function()
		for _, b in ipairs(t.boulders) do
			TweenService:Create(b.part, TweenInfo.new(1.5), {Transparency = 1}):Play()
			b.part.CanCollide = false
		end
	end)
	task.delay(REARM, function() if Game.current == self and t.model.Parent then self:hang(t) end end)
end
-- the guides: a rockfall's lever lit while the dragon stands near its drop
function Dragonfall:rockGuides()
	local d = self.dragon
	local feet = d and d.alive and d.state == "ground" and d:feet()
	for _, t in ipairs(self.traps or {}) do
		local near = feet and t.armed and Vector3.new(feet.X - t.zone.X, 0, feet.Z - t.zone.Z).Magnitude < ROCK_ZONE + 12
		t.model:SetAttribute("GuideText", near and "CUT THE CHAINS" or nil)
		t.ring.Transparency = near and 0.55 or 0.88
	end
end

-- the ward stones: lit and marked while an Inferno is coming
function Dragonfall:wards(on)
	local f = MapLoader.current and MapLoader.current:FindFirstChild("Wards")
	for _, m in ipairs(f and f:GetChildren() or {}) do
		m:SetAttribute("GuideText", on and "SHELTER" or nil)
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("PointLight") then d.Range = on and 26 or 14; d.Brightness = on and 2.4 or 0.9 end
			if d.Name == "Rune" then d.Color = on and Color3.fromRGB(200, 250, 255) or Color3.fromRGB(110, 220, 255) end
		end
	end
end

--------------------------------------------------------------------
--  ITS BROOD (out of the lava, while it's in the sky)
--------------------------------------------------------------------
function Dragonfall:brood(n)
	local pools = self.layout and self.layout.lava or {}
	if #pools == 0 then return end
	for i = 1, n do
		task.delay(i * 0.5, function()
			if Game.current ~= self or not (self.dragon and self.dragon.alive) then return end
			local p = pools[math.random(#pools)]
			local a = math.random() * math.pi * 2
			local at = p.pos + Vector3.new(math.cos(a) * (p.r + 2), 3, math.sin(a) * (p.r + 2))
			local m = Monsters.spawn("Cinderling", self.mobOpts, {at = CFrame.lookAt(at, Vector3.new(0, at.Y, 0)), hpMult = 1 + #Players:GetPlayers() * 0.1})
			if m then self.mobs[m] = true end
		end)
	end
end

--------------------------------------------------------------------
--  THE FIGHT
--------------------------------------------------------------------
function Dragonfall:hint()
	local d = self.dragon
	if self.slain then return "CINDERMAW IS SLAIN" end
	if not d then return "IT'S COMING  ·  " .. math.max(0, math.ceil((self.comeAt or 0) - os.clock())) end
	local s = d.state
	if s == "sky" or s == "takeoff" then
		return string.format("IT'S IN THE SKY  ·  MAN THE BALLISTAE  ·  %d / %d", d.hits or 0, d.need or 3)
	elseif s == "crash" or s == "downed" then return "IT'S DOWN  ·  STRIKE NOW"
	elseif s == "inferno" then return "INFERNO  ·  GET BEHIND A WARD STONE"
	elseif d.enraged then return "ENRAGED  ·  WHEN IT RISES, GET BEHIND A WARD STONE"
	end
	return "STRIKE IN ITS OPENINGS  ·  BALLISTAE  ·  ROCKFALLS"
end

function Dragonfall:onState(s, d)
	if Game.current ~= self or self.dragon ~= d then return end
	if s == "sky" then
		d.need = 3 + math.floor(math.max(0, #Players:GetPlayers() - 1) / 2)
		self:setBallistae()
		self:brood(2 + #Players:GetPlayers())
		banner({text = "IT TAKES TO THE SKY", sub = "MAN THE BALLISTAE  ·  BRING IT DOWN", kind = "boss"})
	elseif s == "crash" then
		self:setBallistae()
		banner({text = "IT'S DOWN!", sub = "EVERYONE STRIKE  ·  NOW", kind = "victory"})
	elseif s == "land" or s == "ground" or s == "downed" or s == "takeoff" then
		self:setBallistae()
		if s ~= "downed" then self:wards(false) end
	elseif s == "enraged" then
		banner({text = "CINDERMAW IS ENRAGED", sub = "WHEN IT RISES OVER THE MIDDLE: GET BEHIND A WARD STONE", kind = "boss"})
	elseif s == "inferno" then
		self:setBallistae()
		self:wards(true)
		banner({text = "INFERNO", sub = "GET BEHIND A WARD STONE!", kind = "boss"})
	end
end

function Dragonfall:summon()
	local L = self.layout
	local c = L and L.centre or Vector3.zero
	local n = #Players:GetPlayers()
	local d = Dragon.spawn({
		at = CFrame.lookAt(c + Vector3.new(0, 0, -16), c + Vector3.new(0, 0, 60)),
		arena = {centre = c, radius = L and L.radius or 110},
		hp = 3000 + 1800 * math.max(1, n),
		onState = function(s, dd) self:onState(s, dd) end,
		onBolt = function(plr, pinned)
			if pinned then
				banner({text = "PINNED!", sub = (plr and (string.upper(plr.DisplayName) .. "'S BOLT  ·  ") or "") .. "IT CAN'T MOVE  ·  STRIKE", kind = "victory"})
			else
				banner({text = "A BOLT STRIKES HOME", sub = "ANOTHER, QUICK, AND IT'S PINNED", kind = "elite"})
			end
		end,
		onHarpoon = function(hits, need, plr)
			banner({text = hits >= need and "IT'S COMING DOWN!" or "A BOLT STRIKES HOME", sub = string.format("%s  ·  %d / %d", plr and string.upper(plr.DisplayName) or "", hits, need), kind = hits >= need and "victory" or "elite"})
		end,
		onDeath = function(killer) self:slay(killer) end,
	})
	self.dragon = d
	self.fightAt = os.clock()
	banner({text = string.upper(Dragon.NAME), sub = Dragon.TITLE, kind = "boss", intro = true})
end

function Dragonfall:slay(killer)
	if self.slain then return end
	self.slain = true
	self.slainAt = os.clock()
	self:setBallistae()
	self:wards(false)
	Monsters.halt(self.mobOpts)
	for m in pairs(self.mobs) do Monsters.despawn(m) end
	local secs = math.floor(os.clock() - (self.fightAt or os.clock()))
	for _, p in ipairs(Players:GetPlayers()) do
		if _G.RoundBump then _G.RoundBump(p, "dragon_slain") end
		local ok, prof = pcall(Profile.get, p)
		if ok and prof and prof.stats then
			prof.stats.dragonsSlain = (prof.stats.dragonsSlain or 0) + 1
			if not prof.stats.dragonBest or secs < prof.stats.dragonBest then prof.stats.dragonBest = secs end
		end
	end
	banner({text = "CINDERMAW IS SLAIN", sub = string.format("%sIN %d:%02d", killer and (string.upper(killer.DisplayName) .. " LANDED THE LAST BLOW  ·  ") or "", secs // 60, secs % 60), kind = "victory"})
	node:SetAttribute("Winner", killer and killer.DisplayName or "")
end

function Dragonfall:start(map)
	Game.Mode.start(self, map)
	if not self.layout then
		local name = self:buildMap()
		MapLoader.load(name)
	end
	self.mobs = {}
	self.mobOpts = {team = "B", startDelay = 0.6, corpseTime = 3, onDeath = function(m) self.mobs[m] = nil end}
	self.dragon, self.slain, self.slainAt = nil, false, nil
	self.comeAt = os.clock() + FIRST
	node:SetAttribute("FriendlyFire", false)
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("ObjKind", "Dragon")
	self:rigBallistae()
	self:rigRockfalls()
	self:wards(false)
	task.delay(2, function() if Game.current == self then banner({text = "DRAGONFALL", sub = "THE ASHEN CALDERA  ·  SOMETHING IS COMING", kind = "floor"}) end end)
end

function Dragonfall:stop()
	if self.dragon then self.dragon:destroy(); self.dragon = nil end
	if self.mobOpts then Monsters.halt(self.mobOpts) end
	for m in pairs(self.mobs or {}) do Monsters.despawn(m) end
	self.mobs = {}
	self.layout = nil
	for _, k in ipairs({"OwnHud", "ObjKind", "ObjLabel", "ObjNote"}) do node:SetAttribute(k, nil) end
end

function Dragonfall:tick(dt)
	local now = os.clock()
	if not self.dragon and not self.slain and now >= (self.comeAt or math.huge) then self:summon() end
	-- the lava burns
	self.lavaT = (self.lavaT or 0) + dt
	if self.lavaT >= 0.5 then
		self.lavaT = 0
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			local r, h = rootOf(c), humOf(c)
			if r and h and h.Health > 0 then
				for _, pool in ipairs(self.layout and self.layout.lava or {}) do
					local off = Vector3.new(r.Position.X - pool.pos.X, 0, r.Position.Z - pool.pos.Z)
					if off.Magnitude < pool.r and r.Position.Y < pool.pos.Y + 5 then
						h:TakeDamage(LAVA_DPS * 0.5)
						c:SetAttribute("Burning", true)
						c:SetAttribute("LavaAt", now)
						break
					end
				end
				if c:GetAttribute("LavaAt") and now - c:GetAttribute("LavaAt") > 1 then c:SetAttribute("Burning", nil); c:SetAttribute("LavaAt", nil) end
			end
		end
	end
	local d = self.dragon
	self:rockGuides()
	node:SetAttribute("ObjLabel", d and string.format("%s  ·  %d%%", string.upper(Dragon.NAME), math.ceil(100 * math.max(0, d.hum.Health) / d.hum.MaxHealth)) or "DRAGONFALL")
	node:SetAttribute("ObjNote", self:hint())
	node:SetAttribute("Objective", self:objective())
end

function Dragonfall:isOver()
	if self.slain and os.clock() - (self.slainAt or 0) > 7 then
		local secs = math.floor((self.slainAt or 0) - (self.fightAt or 0))
		return string.format("CINDERMAW IS SLAIN  ·  %d:%02d", secs // 60, secs % 60)
	end
	return nil
end
function Dragonfall:result()
	node:SetAttribute("Winner", "")
	return "CINDERMAW HOLDS THE CALDERA"
end
function Dragonfall:objective() return "DRAGONFALL  ·  BRING DOWN CINDERMAW" end

return Dragonfall
