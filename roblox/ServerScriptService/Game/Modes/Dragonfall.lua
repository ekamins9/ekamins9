--[[ DRAGONFALL — you and your party against a dragon (GameConfig.MODES.Dragonfall, DOORS.Dragonfall).
     The Ashen Caldera (Game ▸ CalderaMap, built fresh) is CINDERMAW's nest (Combat ▸ Dragon: its
     body, its blows, its brain). A few seconds in it comes down out of the burning sky.

     ON THE GROUND it fights like the boss it is (bite, claw, tail, wing buffet, stomp, a charge,
     fire breath swept across the ground): get to its side, mind its tail, get under the fire.
     At two thirds it TAKES TO THE SKY: strafing runs and fireballs, and its BROOD climbs out of
     the lava pools. MAN THE BALLISTAE (four, on platforms near the rim: hold to fire, a few
     seconds to wind again): enough bolts (3, one more for every two of you past that) and it
     CRASHES, DOWNED for a while: everyone strike. Under a third it's ENRAGED: quicker, fire rains,
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
function Dragonfall:setBallistae(on)
	for _, b in ipairs(self.ballistae or {}) do
		b.prompt.Enabled = on
		b.model:SetAttribute("GuideText", on and os.clock() >= b.readyAt and "BALLISTA" or nil)
	end
end

function Dragonfall:fire(b, plr)
	local d = self.dragon
	if not (d and d.alive and d.state == "sky") then return end
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
		if self.dragon == d and d.alive and d.state == "sky" then
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
		local up = self.dragon and self.dragon.alive and self.dragon.state == "sky"
		b.prompt.Enabled = up
		b.model:SetAttribute("GuideText", up and "BALLISTA" or nil)
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
	return "GET TO ITS SIDE  ·  MIND THE TAIL  ·  GET UNDER THE FIRE"
end

function Dragonfall:onState(s, d)
	if Game.current ~= self or self.dragon ~= d then return end
	if s == "sky" then
		d.need = 3 + math.floor(math.max(0, #Players:GetPlayers() - 1) / 2)
		self:setBallistae(true)
		self:brood(2 + #Players:GetPlayers())
		banner({text = "IT TAKES TO THE SKY", sub = "MAN THE BALLISTAE  ·  BRING IT DOWN", kind = "boss"})
	elseif s == "crash" then
		self:setBallistae(false)
		banner({text = "IT'S DOWN!", sub = "EVERYONE STRIKE  ·  NOW", kind = "victory"})
	elseif s == "land" or s == "ground" then
		self:setBallistae(false)
		self:wards(false)
	elseif s == "enraged" then
		banner({text = "CINDERMAW IS ENRAGED", sub = "WHEN IT RISES OVER THE MIDDLE: GET BEHIND A WARD STONE", kind = "boss"})
	elseif s == "inferno" then
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
		onHarpoon = function(hits, need, plr)
			banner({text = hits >= need and "IT'S COMING DOWN!" or "A BOLT STRIKES HOME", sub = string.format("%s  ·  %d / %d", plr and string.upper(plr.DisplayName) or "", hits, need), kind = hits >= need and "victory" or "elite"})
		end,
		onDeath = function(killer) self:slay(killer) end,
	})
	self.dragon = d
	self.fightAt = os.clock()
	banner({text = string.upper(Dragon.NAME), sub = Dragon.TITLE, kind = "boss"})
end

function Dragonfall:slay(killer)
	if self.slain then return end
	self.slain = true
	self.slainAt = os.clock()
	self:setBallistae(false)
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
