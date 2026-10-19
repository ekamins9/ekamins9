--[[ CROWNFALL — a battle royale (GameConfig.MODES.Crownfall). An island built fresh every match
     (Game ▸ Realm): the Crown Keep in the middle, villages, a mill, watchtowers, camps, a chapel,
     ruins, each with its name and its chests; forests and hills between.

     THE DROP. Everyone comes down out of the sky at once, gliding under a canopy (steer where you
     land). You land as your class with only a plain weapon: no power, no throwable, nothing else.
     THE LOOT. A chest spills three things for whoever opens it (Game ▸ Loot, Catalog ▸ Loot
     CHESTS.crownfall): a weapon your class carries (rarities, skins, affixes), armour (less damage
     taken, more health), potions (drunk on the spot), a tome (a power), a relic. A better weapon
     takes its slot and drops the old one; so does armour. Whoever falls drops everything they found.
     THE RING. A ring of fire closes in phases (RING), each tighter and hotter: outside it you burn.
     The next ring shows on your map before it moves. Bots fill the island (BotFill, fillAnywhere).
     ROYAL CACHES. As each of the first rings starts to close, a gilded chest comes down out of
     the sky under a canopy somewhere inside the next ring, a gold flare over it the whole way (and
     till someone opens it): four things inside, rolled with a king's luck. Worth the fight.
     No coming back: the last one standing wins the crown (stats.crownfallWins).

     On screen (Adventure.client, OwnHud): how many are left, the ring's clock, the island's map
     with its places, the ring and the next one, and the place you're in. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Realm = require(script.Parent.Parent:WaitForChild("Realm"))
local Loot = require(script.Parent.Parent:WaitForChild("Loot"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Powers = require(Combat:WaitForChild("Powers"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local MapLoader = Game.MapLoader
local node = Game.node

local ISLAND = 520
local DROP_AT = 7          -- seconds into the round
local DROP_HEIGHT = 110
local GLIDE = -24          -- how fast you come down under the canopy
-- the ring's phases: wait, then shrink over `shrink` s to `to` of the island; outside, `dps`
local RING = {
	{wait = 55, shrink = 35, to = 0.62, dps = 3},
	{wait = 40, shrink = 30, to = 0.4, dps = 5},
	{wait = 35, shrink = 25, to = 0.22, dps = 8},
	{wait = 30, shrink = 22, to = 0.1, dps = 12},
	{wait = 25, shrink = 20, to = 0.0, dps = 18},
}
local SEGMENTS = 64
local CACHES = 3           -- royal caches: one as each of the first rings closes
local CACHE_FALL = 9       -- seconds it takes to come down
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local BASIC = {Knight = "Shortsword", Footman = "Shortsword", Vanguard = "Shortsword", Archer = "Bow", Mage = "Staff"}
local CHEST_KIND = "crownfall"

local Crownfall = setmetatable({}, {__index = Game.Mode})
Crownfall.__index = Crownfall
function Crownfall.new(def, id) return setmetatable(Game.Mode.new(def, id), Crownfall) end

local function humOf(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function rootOf(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function alive(c) local h = humOf(c); return h ~= nil and h.Health > 0 end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function banner(t, plr) local e = event(); if e then if plr then e:FireClient(plr, "Banner", t) else e:FireAllClients("Banner", t) end end end

--------------------------------------------------------------------
--  THE ISLAND
--------------------------------------------------------------------
function Crownfall:buildMap(_)
	local name, layout = Realm.build({radius = ISLAND})
	self.layout = layout
	Dungeon.sweep(name)
	return name
end

function Crownfall:sendLayout(plr)
	local L = self.layout
	if not L then return end
	local pois = {}
	for _, p in ipairs(L.pois) do table.insert(pois, {name = p.name, kind = p.kind, x = p.pos.X, z = p.pos.Z, r = p.radius}) end
	local data = {kind = "realm", radius = L.radius, pois = pois, themeName = "CROWNFALL"}
	local e = event()
	if e then if plr then e:FireClient(plr, "Layout", data) else e:FireAllClients("Layout", data) end end
end

--------------------------------------------------------------------
--  A PLAYER'S FINDS
--------------------------------------------------------------------
function Crownfall:runOf(plr)
	local r = self.runs[plr]
	if not r then r = {weapons = {}, relics = {}, armor = nil, power = nil}; self.runs[plr] = r end
	return r
end

-- the plain start: your class, a plain weapon, nothing else
function Crownfall:adjustLoadout(plr, lo, classId)
	lo.weapon, lo.weaponSkin = BASIC[classId] or "Shortsword", nil
	lo.secondary, lo.secondarySkin = nil, nil
	lo.shield, lo.shieldSkin = nil, nil
	lo.power, lo.throwable = nil, nil
	lo.thirdKind, lo.thirdId = "none", nil
end

local function itemName(item) return item and item.name or "" end

function Crownfall:grant(plr, item, at)
	local char = plr.Character
	if not alive(char) then return false end
	local r = self:runOf(plr)
	local here = rootOf(char) and rootOf(char).Position or at
	if item.kind == "weapon" then
		-- (a free slot, else the one in your hand is swapped out and dropped)
		local _, old = Loot.giveWeapon(plr, item)
		r.weapons[item.slot] = item
		if old then self:dropItem(old, here) end
	elseif item.kind == "armor" then
		local old = r.armor
		r.armor = item
		Loot.setArmor(char, item.armor)
		if old then self:dropItem(old, here) end
	elseif item.kind == "potion" then
		Loot.drink(char, item.potion)
	elseif item.kind == "relic" then
		table.insert(r.relics, item.relic)
		Loot.setRelics(char, r.relics)
	elseif item.kind == "tome" then
		local old = r.power
		r.power = item
		Powers.equip(char, plr, {power = item.power})
		if old then self:dropItem(old, here) end
	end
	local e = event()
	if e then e:FireClient(plr, "Banner", {text = string.upper(itemName(item)), sub = (Loot.card(item) or {}).sub, kind = "clear"}) end
	return true
end

function Crownfall:dropItem(item, pos)
	local a = math.random() * math.pi * 2
	local at = pos + Vector3.new(math.cos(a) * 3, 0, math.sin(a) * 3)
	Loot.drop(item, at - Vector3.new(0, 2.5, 0), {life = 240, onTake = function(plr, it) return self:grant(plr, it, at) end})
end

-- a chest spills three things, rolled for whoever opened it
function Crownfall:placeChests()
	for _, cf in ipairs(self.layout.chests) do
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = {MapLoader.current, workspace.Terrain}
		local hit = workspace:Raycast(cf.Position + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), rp)
		local ground = hit and hit.Position or cf.Position
		local spot = CFrame.new(ground) * cf.Rotation
		local rarity = (math.random() < 0.12) and "Epic" or ((math.random() < 0.3) and "Rare" or "Common")
		Loot.chest(spot, {rarity = rarity, gilded = rarity ~= "Common", label = rarity == "Common" and "Chest" or (rarity .. " chest"),
			onOpen = function(plr, chest)
				local char = plr.Character
				if not alive(char) then return false end
				local classId = char:GetAttribute("Class") or "Knight"
				local luck = (rarity == "Epic" and 2.5) or (rarity == "Rare" and 1.2) or 0.3
				for i = 1, 3 do
					local item = Loot.roll(CHEST_KIND, classId, luck + Loot.luckOf(char))
					local a = (i / 3) * math.pi * 2
					local at = ground + spot:VectorToWorldSpace(Vector3.new(math.cos(a) * 3.2, 0, -2.4 + math.sin(a) * 1.4))
					task.delay(0.15 * i, function()
						Loot.drop(item, at, {life = 240, onTake = function(p2, it) return self:grant(p2, it, at) end})
					end)
				end
				return true
			end})
	end
end

-- A ROYAL CACHE: down out of the sky inside the next ring under a canopy, a gold flare over it
function Crownfall:cache()
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = {MapLoader.current, workspace.Terrain}
	local c, r = self.nextC or self.ringC, math.max(20, (self.nextR or self.ringR) * 0.6)
	local ground
	for _ = 1, 16 do
		local a, d = math.random() * math.pi * 2, math.random() * r
		local probe = c + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		local hit = workspace:Raycast(Vector3.new(probe.X, 260, probe.Z), Vector3.new(0, -520, 0), rp)
		if hit and hit.Normal.Y > 0.8 and hit.Material ~= Enum.Material.Water then ground = hit.Position; break end
	end
	if not ground then return end
	local GOLD = Color3.fromRGB(255, 190, 60)
	local fx = MapLoader.current or workspace
	-- the flare: a gold column over where it'll land (it stays till the cache is opened)
	local flare = Instance.new("Part")
	flare.Name = "CacheFlare"
	flare.Anchored, flare.CanCollide, flare.CanQuery, flare.CanTouch, flare.CastShadow = true, false, false, false, false
	flare.Shape = Enum.PartType.Cylinder
	flare.Size = Vector3.new(160, 1.4, 1.4)
	flare.CFrame = CFrame.new(ground + Vector3.new(0, 80, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	flare.Color, flare.Material, flare.Transparency = GOLD, Enum.Material.Neon, 0.45
	flare.Parent = fx
	-- the crate under its canopy, coming down
	local top = CFrame.new(ground + Vector3.new(0, 130, 0))
	local crate = Instance.new("Part")
	crate.Name = "FallingCache"
	crate.Anchored, crate.CanCollide, crate.CanQuery, crate.CanTouch = true, false, false, false
	crate.Size = Vector3.new(4, 2.6, 3)
	crate.Color, crate.Material = Color3.fromRGB(110, 72, 40), Enum.Material.WoodPlanks
	crate.CFrame = top
	crate.Parent = fx
	local canopy = Instance.new("Part")
	canopy.Anchored, canopy.CanCollide, canopy.CanQuery, canopy.CanTouch = true, false, false, false
	canopy.Size = Vector3.new(12, 0.5, 9)
	canopy.Color, canopy.Material = Color3.fromRGB(200, 40, 40), Enum.Material.Fabric
	canopy.CFrame = top * CFrame.new(0, 10, 0)
	canopy.Parent = fx
	local stripe = canopy:Clone(); stripe.Size = Vector3.new(12.1, 0.52, 2.2); stripe.Color = GOLD; stripe.Parent = fx
	local spark = Instance.new("ParticleEmitter")
	spark.Color = ColorSequence.new(GOLD); spark.LightEmission = 1; spark.Rate = 30
	spark.Lifetime = NumberRange.new(1, 2); spark.Speed = NumberRange.new(1, 3); spark.Size = NumberSequence.new(0.5, 0)
	spark.Parent = crate
	local info = TweenInfo.new(CACHE_FALL, Enum.EasingStyle.Linear)
	local land = CFrame.new(ground + Vector3.new(0, 1.3, 0))
	TweenService:Create(crate, info, {CFrame = land}):Play()
	TweenService:Create(canopy, info, {CFrame = land * CFrame.new(0, 10, 0)}):Play()
	TweenService:Create(stripe, info, {CFrame = land * CFrame.new(0, 10, 0)}):Play()
	banner({text = "A ROYAL CACHE FALLS", sub = "FOLLOW THE GOLD FLARE  ·  INSIDE THE NEXT RING", kind = "victory"})
	local me = self
	task.delay(CACHE_FALL, function()
		crate:Destroy()
		for _, p in ipairs({canopy, stripe}) do
			p.Anchored = false
			TweenService:Create(p, TweenInfo.new(1.6), {Transparency = 1}):Play()
			Debris:AddItem(p, 1.7)
		end
		if Game.current ~= me then flare:Destroy(); return end
		Loot.sparkle(ground + Vector3.new(0, 2, 0), GOLD)
		Loot.chest(CFrame.new(ground) * CFrame.Angles(0, math.random() * math.pi * 2, 0), {rarity = "Legendary", gilded = true, label = "Royal cache", hold = 1.2,
			onOpen = function(plr, chest)
				local char = plr.Character
				if not alive(char) then return false end
				flare:Destroy()
				local classId = char:GetAttribute("Class") or "Knight"
				for i = 1, 4 do
					local item = Loot.roll(CHEST_KIND, classId, 4.5 + Loot.luckOf(char))
					local a = (i / 4) * math.pi * 2
					local at = ground + Vector3.new(math.cos(a) * 3.4, 0, math.sin(a) * 3.4)
					task.delay(0.15 * i, function()
						Loot.drop(item, at, {life = 240, onTake = function(p2, it) return self:grant(p2, it, at) end})
					end)
				end
				banner({text = string.upper(plr.DisplayName) .. " TOOK A ROYAL CACHE", kind = "elite"})
				return true
			end})
	end)
	table.insert(self.cacheParts, flare)
end

--------------------------------------------------------------------
--  THE RING
--------------------------------------------------------------------
function Crownfall:ringParts()
	if self.wall then return end
	local f = Instance.new("Folder"); f.Name = "BurningRing"; f.Parent = MapLoader.current or workspace
	self.wall = {}
	for i = 1, SEGMENTS do
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 120, 50)
		p.Transparency = 0.78
		p.Parent = f
		self.wall[i] = p
	end
	self.wallFolder = f
end
function Crownfall:drawRing()
	local c, r = self.ringC, math.max(self.ringR, 0.5)
	local seg = 2 * math.pi * r / SEGMENTS + 0.4
	-- (out past the shore the ring is nothing to see: the wall shows once it's on the island)
	local show = r < ISLAND * 0.97
	if self.wallFolder then self.wallFolder.Parent = show and (MapLoader.current or workspace) or nil end
	for i, p in ipairs(self.wall) do
		local a = (i / SEGMENTS) * math.pi * 2
		local pos = c + Vector3.new(math.cos(a) * r, 14, math.sin(a) * r)
		p.Size = Vector3.new(seg, 60, 0.6)
		p.CFrame = CFrame.lookAt(pos, Vector3.new(c.X, 14, c.Z))
	end
	node:SetAttribute("RingCentre", c)
	node:SetAttribute("RingRadius", r)
	node:SetAttribute("RingNextCentre", self.nextC)
	node:SetAttribute("RingNextRadius", self.nextR)
end
-- the next ring: somewhere inside this one
function Crownfall:planNext()
	local ph = RING[self.phase]
	if not ph then return end
	self.nextR = ISLAND * ph.to
	local room = math.max(0, self.ringR - self.nextR)
	local a, d = math.random() * math.pi * 2, math.random() * room * 0.85
	self.nextC = self.ringC + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
	self.waitUntil = os.clock() + ph.wait
	self.shrinkFrom, self.shrinkC = self.ringR, self.ringC
	self.shrinking = false
end

--------------------------------------------------------------------
--  THE ROUND
--------------------------------------------------------------------
function Crownfall:start(map)
	Game.Mode.start(self, map)
	if not self.layout then local name = self:buildMap(map); MapLoader.load(name) end
	self.runs, self.spawned = {}, {}
	self.caches, self.cacheParts = 0, {}
	self.dropAt = os.clock() + DROP_AT
	self.dropped = false
	self.over = nil
	self.ringC, self.ringR = Vector3.new(0, 0, 0), ISLAND + 30
	self.phase = 1
	self.wall = nil
	self:ringParts()
	self:planNext()
	self.waitUntil = os.clock() + DROP_AT + RING[1].wait
	self:drawRing()
	self:placeChests()
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("ObjKind", "Crownfall")
	self:sendLayout()
	if not self.helloConn then
		self.helloConn = (event() and event().OnServerEvent:Connect(function(plr, kind)
			if Game.current == self and kind == "Hello" then self:sendLayout(plr) end
		end))
	end
	banner({text = "CROWNFALL", sub = "THE DROP IN " .. DROP_AT .. "  ·  LAST ONE STANDING TAKES THE CROWN", kind = "floor"})
end

function Crownfall:stop()
	Loot.clear()
	for _, p in ipairs(self.cacheParts or {}) do if p.Parent then p:Destroy() end end
	self.cacheParts = {}
	for _, k in ipairs({"OwnHud", "ObjKind", "ObjLabel", "ObjNote", "RingCentre", "RingRadius", "RingNextCentre", "RingNextRadius"}) do node:SetAttribute(k, nil) end
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c then Loot.setRelics(c, {}); Loot.setArmor(c, nil); c:SetAttribute("Burning", nil) end
	end
	self.layout = nil
	self.wall = nil
	local e = event()
	if e then e:FireAllClients("Layout", nil) end
end

-- THE ISLAND'S BOTS (BotFill asks): still until the drop; then, outside the ring, they head in
function Crownfall:botOpts(opts)
	opts.startDelay = math.max(0.5, (self.dropAt or os.clock()) - os.clock() + 2 + math.random() * 4)
	opts.goal = function(b)
		local r = b.hrp
		if not (r and self.ringC) then return nil end
		local d = flat(r.Position - self.ringC).Magnitude
		local inner = math.min(self.ringR, self.nextR or self.ringR)
		if d > inner - 8 then return self.nextC or self.ringC end
		return nil
	end
end

-- where you land if not the sky: one of the places, on the ground
function Crownfall:spawnCFrame(plr)
	local L = self.layout
	if not L then return Game.Mode.spawnCFrame(self, plr) end
	local p = L.drops[math.random(#L.drops)]
	return CFrame.new(p + Vector3.new(math.random(-10, 10), 4, math.random(-10, 10)))
end

function Crownfall:canSpawn(plr)
	if not self.dropped then return false, string.format("Get ready: the drop in %d", math.max(0, math.ceil((self.dropAt or 0) - os.clock()))) end
	if self.dropped and self.spawned[plr] then return false, "No coming back in Crownfall: watch the rest, the next match is yours" end
	if self.dropped and os.clock() > self.dropAt + 20 then return false, "The drop has gone: the next match is yours" end
	return true
end

-- your first body: up into the sky, under a canopy
function Crownfall:noteSpawn(plr)
	self.spawned[plr] = true
	local char = plr.Character
	local r = rootOf(char)
	if not r then return end
	task.defer(function()
		local L = self.layout
		local over = L and L.drops[math.random(#L.drops)] or Vector3.zero
		local a, d = math.random() * math.pi * 2, math.random(10, 60)
		char:PivotTo(CFrame.new(over + Vector3.new(math.cos(a) * d, DROP_HEIGHT, math.sin(a) * d)))
		local att = Instance.new("Attachment"); att.Name = "GlideAtt"; att.Parent = r
		local lv = Instance.new("LinearVelocity")
		lv.Name = "Glide"
		lv.Attachment0 = att
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		lv.LineDirection = Vector3.yAxis
		lv.LineVelocity = GLIDE
		lv.MaxForce = 1e6
		lv.Parent = r
		-- the canopy
		local canopy = Instance.new("Part")
		canopy.Name = "Canopy"
		canopy.Size = Vector3.new(8, 0.4, 6)
		canopy.Color = Color3.fromRGB(200, 40, 40)
		canopy.Material = Enum.Material.Fabric
		canopy.CanCollide, canopy.CanQuery, canopy.CanTouch, canopy.Massless = false, false, false, true
		canopy.CFrame = r.CFrame * CFrame.new(0, 9, 0)
		local w = Instance.new("Weld"); w.Part0 = r; w.Part1 = canopy; w.C0 = CFrame.new(0, 9, 0); w.Parent = canopy
		local stripe = canopy:Clone(); stripe.Size = Vector3.new(8.1, 0.42, 1.6); stripe.Color = Color3.fromRGB(240, 196, 70)
		stripe:FindFirstChildOfClass("Weld").Part1 = stripe; stripe.Parent = char
		canopy.Parent = char
		local hum = humOf(char)
		local t0 = os.clock()
		while char.Parent and hum and hum.Health > 0 and os.clock() - t0 < 14 do
			task.wait(0.1)
			if os.clock() - t0 > 0.6 and hum.FloorMaterial ~= Enum.Material.Air then break end
		end
		lv:Destroy(); att:Destroy()
		canopy:Destroy(); stripe:Destroy()
	end)
	self:sendLayout(plr)
end

function Crownfall:onDeath(victimPlr)
	-- what they found falls where they fell
	local r = self.runs and self.runs[victimPlr]
	local char = victimPlr.Character
	local at = rootOf(char) and rootOf(char).Position
	if r and at then
		for _, it in pairs(r.weapons) do self:dropItem(it, at) end
		if r.armor then self:dropItem(r.armor, at) end
		if r.power then self:dropItem(r.power, at) end
		r.weapons, r.armor, r.power = {}, nil, nil
	end
	local left = self:fighters()
	if self.dropped and left > 1 then banner({text = string.format("%d LEFT", left), sub = string.upper(victimPlr.DisplayName) .. " IS OUT", kind = "fight"}) end
end

-- who's still in it: players and the island's bots
function Crownfall:fighters()
	local n, last = 0, nil
	for _, p in ipairs(Players:GetPlayers()) do if alive(p.Character) then n += 1; last = p.DisplayName end end
	local npcs = workspace:FindFirstChild("NPCs")
	for _, m in ipairs(npcs and npcs:GetChildren() or {}) do
		if m:GetAttribute("FillBot") and alive(m) then n += 1; last = m:GetAttribute("TagName") or m.Name end
	end
	return n, last
end

function Crownfall:tick(dt)
	local now = os.clock()
	-- the drop: everyone in at once
	if not self.dropped and now >= self.dropAt then
		self.dropped = true
		for _, p in ipairs(Players:GetPlayers()) do if not alive(p.Character) and _G.AutoSpawn then _G.AutoSpawn(p) end end
		banner({text = "THE DROP", sub = "STEER WHERE YOU LAND  ·  FIND A CHEST", kind = "descend"})
	end
	-- the ring: wait, then close in on the next one
	local ph = RING[self.phase]
	if ph then
		if not self.shrinking and now >= self.waitUntil then
			self.shrinking = true
			self.shrinkAt = now
			banner({text = "THE RING CLOSES", sub = "GET INSIDE THE NEXT RING", kind = "boss"})
			if self.caches < CACHES and self.nextR and self.nextR > 12 then
				self.caches += 1
				task.delay(4, function() if Game.current == self then self:cache() end end)
			end
		end
		if self.shrinking then
			local k = math.clamp((now - self.shrinkAt) / ph.shrink, 0, 1)
			self.ringR = self.shrinkFrom + (self.nextR - self.shrinkFrom) * k
			self.ringC = self.shrinkC:Lerp(self.nextC, k)
			if k >= 1 then
				self.phase += 1
				if RING[self.phase] then self:planNext() else self.nextC, self.nextR = self.ringC, self.ringR end
			end
		end
		if now - (self.lastDraw or 0) > 0.2 then self.lastDraw = now; self:drawRing() end
	end
	-- outside it, you burn
	if now - (self.lastBurn or 0) >= 1 then
		self.lastBurn = now
		local dps = (RING[math.min(self.phase, #RING)] or RING[#RING]).dps
		local function burn(c)
			local r = rootOf(c)
			local h = humOf(c)
			if r and h and h.Health > 0 and flat(r.Position - self.ringC).Magnitude > self.ringR then
				h:TakeDamage(dps)
				c:SetAttribute("Burning", true)
				c:SetAttribute("RingBurnAt", now)
			elseif c:GetAttribute("RingBurnAt") and now - c:GetAttribute("RingBurnAt") > 1.2 then
				c:SetAttribute("Burning", nil); c:SetAttribute("RingBurnAt", nil)
			end
		end
		if self.dropped then
			for _, p in ipairs(Players:GetPlayers()) do if p.Character then burn(p.Character) end end
			local npcs = workspace:FindFirstChild("NPCs")
			for _, m in ipairs(npcs and npcs:GetChildren() or {}) do if m:IsA("Model") then burn(m) end end
		end
	end
	-- the screen
	local n = self:fighters()
	node:SetAttribute("ObjLabel", self.dropped and string.format("CROWNFALL  ·  %d LEFT", n) or string.format("CROWNFALL  ·  THE DROP IN %d", math.max(0, math.ceil(self.dropAt - now))))
	local note
	if not RING[self.phase] then note = "THE LAST RING"
	elseif self.shrinking then note = "THE RING IS CLOSING"
	else note = string.format("THE RING CLOSES IN %d:%02d", math.floor(math.max(0, self.waitUntil - now) / 60), math.floor(math.max(0, self.waitUntil - now)) % 60) end
	node:SetAttribute("ObjNote", note)
	node:SetAttribute("Objective", self:objective())
end

function Crownfall:isOver()
	if not self.dropped or os.clock() < self.dropAt + 12 then return nil end
	local n, last = self:fighters()
	if n <= 1 then
		node:SetAttribute("Winner", last or "")
		node:SetAttribute("WinnerKills", 0)
		for _, p in ipairs(Players:GetPlayers()) do
			if p.DisplayName == last and alive(p.Character) then
				local st = Profile.get(p).stats
				st.crownfallWins = (st.crownfallWins or 0) + 1
			end
		end
		return last and string.format("%s IS THE LAST ONE STANDING", string.upper(last)) or "NOBODY IS LEFT STANDING"
	end
	return nil
end
function Crownfall:result()
	local n, last = self:fighters()
	node:SetAttribute("Winner", "")
	return string.format("THE CLOCK RAN OUT  ·  %d STILL STANDING", n)
end
function Crownfall:objective() return "CROWNFALL  ·  THE LAST ONE STANDING TAKES THE CROWN" end

return Crownfall
