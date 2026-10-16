--[[ THE DEPTHS — a roguelike crawl for a party of 1–4 (GameConfig.MODES.Depths). Three floors of
     a dungeon built fresh every run (Game ▸ Dungeon) in the theme the vote picked: the Bone
     Crypt, the Goblin Warrens, Crimson Manor, the Frozen Depths, the Ember Forge (Catalog ▸
     Dungeons). You go in as your class with your own gear; you come out (if you do) carrying
     whatever the dungeon gave you.

     THE ROOMS. Step into one and its gates slam shut: whoever's left in the corridor is pulled
     in after you, and its monsters (Combat ▸ Monsters, from the theme's Bestiary) come for you.
     Kill them all and the gates rise. Some rooms are kinder:
       treasure   a chest that's yours alone (everyone gets their own pick)
       shrine     a blessing: one of three relics, rarer than a chest's
       fountain   drink: whole again, once each
       elite      a champion of the theme (an affix: Blazing, Vampiric…) and its guard; a chest
       stairs     its guardians, then the way down (anyone starts it: everyone goes)
       boss       floor 3's: the theme's boss, in a great hall
     A CHEST offers each player three cards (Game ▸ Loot): a weapon your class carries, with a
     skin and affixes; a relic (carried: buffs, on-hit fire, frost, lifesteal…); a tome (your
     power, swapped for any class's for the run); gold. Pick one. A cleared room sometimes
     leaves a chest too.

     DOWN, NOT OUT. Fall in a fight and you watch until the room is cleared; then you're back on
     your feet in it (with what you carried). Everyone down at once: the run is over. A Phoenix
     Plume brings you back where you fell, once.

     PAY: like the Horde: a monster's kill by its rank (kill_<rank>), every room the party clears
     (depths_room), every floor (depths_floor), the boss (depths_boss): Catalog ▸ Economy, under
     the daily cap. Your deepest floor and your clears are kept (stats.depthsBest, depthsClears).

     For the screen (StarterPlayerScripts ▸ Adventure.client): AdventureEvent "Layout" (the map),
     "Room" (a room's state), "Choice" (a chest's cards), "Run" (your relics, gold, power),
     "Banner"; Round attributes ObjKind "Depths", ObjLabel, ObjNote, DepthsFloor. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local Loot = require(script.Parent.Parent:WaitForChild("Loot"))
local MapLoader = Game.MapLoader
local Combat = ServerScriptService:WaitForChild("Combat")
local Monsters = require(Combat:WaitForChild("Monsters"))
local Powers = require(Combat:WaitForChild("Powers"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))

local node = Game.node
local FLOORS = 3
local ATTRS = {"ObjKind", "ObjLabel", "ObjNote", "ObjState", "DepthsFloor", "DepthsTheme", "OwnHud"}
local KILL_GOLD = {2, 5, 14, 60}

local event = ReplicatedStorage:FindFirstChild("AdventureEvent")
if not event then event = Instance.new("RemoteEvent"); event.Name = "AdventureEvent"; event.Parent = ReplicatedStorage end

local Depths = setmetatable({}, {__index = Game.Mode})
Depths.__index = Depths
function Depths.new(def, id)
	local self = setmetatable(Game.Mode.new(def, id), Depths)
	return self
end

local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function aliveChar(p)
	local c = p.Character
	local h = humOf(c)
	return h and h.Health > 0 and c or nil
end
local function playersN() return math.max(1, #Players:GetPlayers()) end

--------------------------------------------------------------------
--  THE MAP (GameServer asks for it: a procedural mode)
--------------------------------------------------------------------
local function floorOpts(floor, players)
	local rooms = 7 + floor + math.min(players - 1, 2)
	return {
		rooms = rooms,
		grid = floor >= 3 and {5, 4} or {4, 4},
		final = floor >= FLOORS and "boss" or "stairs",
		special = {treasure = 1, shrine = (floor == 2) and 1 or (math.random() < 0.6 and 1 or 0), fountain = 1, elite = floor >= 2 and 1 or (math.random() < 0.5 and 1 or 0)},
		loops = 1,
	}
end
function Depths:buildMap(theme)
	self.theme = Catalog.DUNGEONS[theme] and theme or "BoneCrypt"
	self.floor = 1
	local name, layout = Dungeon.build(self.theme, floorOpts(1, playersN()))
	self.layout = layout
	Dungeon.sweep(name)
	return name
end

--------------------------------------------------------------------
--  A PLAYER'S RUN: what the dungeon gave them
--------------------------------------------------------------------
function Depths:runOf(plr)
	local r = self.runs[plr]
	if not r then
		r = {weapons = {}, relics = {}, power = nil, gold = 0, kills = 0, picked = 0, fountain = {}, risen = false}
		self.runs[plr] = r
	end
	return r
end
function Depths:sendRun(plr)
	local r = self:runOf(plr)
	local relics = {}
	for _, id in ipairs(r.relics) do
		local rel = Loot.CFG.RELIC[id]
		if rel then table.insert(relics, {id = id, name = rel.name, glyph = rel.glyph, rarity = rel.rarity, text = rel.text}) end
	end
	local weapons = {primary = r.weapons[1] and Loot.card(r.weapons[1]) or nil, sidearm = r.weapons[2] and Loot.card(r.weapons[2]) or nil}
	event:FireClient(plr, "Run", {gold = r.gold, relics = relics, power = r.power, weapons = weapons, kills = r.kills})
end

-- a new body takes on the run (LoadoutServer asks before dressing it)
function Depths:adjustLoadout(plr, lo, classId)
	local r = self.runs and self.runs[plr]
	if not r then return end
	local w1, w2 = r.weapons[1], r.weapons[2]
	if w1 then lo.weapon, lo.weaponSkin = w1.weapon, w1.skin end
	if w2 then lo.secondary, lo.secondarySkin = w2.weapon, w2.skin end
	if lo.secondary == lo.weapon then lo.secondary, lo.secondarySkin = nil, nil end
	if r.power then lo.power = r.power; lo.thirdKind = "power"; lo.thirdId = r.power end
	-- (a looted two-hander can't share the arm with a shield)
	if w1 and lo.shield and not Catalog.shieldFits(GameConfig.CLASSES[classId], lo.weapon, lo.shield) then lo.shield, lo.shieldSkin = nil, nil end
end
-- …and once it's dressed: the loot's own names and affixes, the relics
function Depths:noteSpawn(plr)
	local r = self.runs and self.runs[plr]
	local char = plr.Character
	if not (r and char) then return end
	task.defer(function()
		for _, holder in ipairs({char, plr:FindFirstChildOfClass("Backpack")}) do
			for _, t in ipairs(holder and holder:GetChildren() or {}) do
				local item = t:IsA("Tool") and r.weapons[t:GetAttribute("Slot") or 0]
				-- (a staff's melee self is its twin: tagged the same)
				if item and (t.Name == item.weapon or t:GetAttribute("Twin") == item.weapon) then Loot.tagTool(t, item) end
			end
		end
		Loot.setRelics(char, r.relics)
		local s = Loot.stateOf(char)
		s.risen = r.risen
		self:sendRun(plr)
	end)
end

-- the power slot again (a tome read)
local function reequip(self, plr)
	local char = aliveChar(plr)
	if not char then return end
	local classId = char:GetAttribute("Class") or Profile.get(plr).active
	local lo = Profile.validateLoadout(plr, classId, Profile.get(plr).classes[classId])
	self:adjustLoadout(plr, lo, classId)
	Powers.equip(char, plr, lo)
end

-- a card taken
function Depths:grant(plr, item)
	local r = self:runOf(plr)
	local char = aliveChar(plr)
	if item.kind == "weapon" then
		-- (into a free slot, else in place of the one in your hand: Loot.slotFor)
		if char then Loot.giveWeapon(plr, item) else item.slot = item.slot or 1 end
		r.weapons[item.slot] = item
	elseif item.kind == "relic" then
		table.insert(r.relics, item.relic)
		if char then Loot.setRelics(char, r.relics) end
	elseif item.kind == "tome" then
		r.power = item.power
		reequip(self, plr)
	elseif item.kind == "gold" then
		r.gold += item.gold
	elseif item.kind == "potion" then
		if char then Loot.drink(char, item.potion) end
	end
	r.picked += 1
	self:sendRun(plr)
end

-- A CHOICE: three cards (one pick), from a chest / a shrine
function Depths:offer(plr, cards, title, sub)
	self.offerN += 1
	local id = self.offerN
	self.offers[id] = {plr = plr, cards = cards}
	local show = {}
	for i, c in ipairs(cards) do show[i] = Loot.card(c) end
	event:FireClient(plr, "Choice", {id = id, title = title, sub = sub, cards = show})
end
function Depths:pick(plr, id, idx)
	local o = self.offers[id]
	if not (o and o.plr == plr) then return end
	self.offers[id] = nil
	local item = type(idx) == "number" and o.cards[math.floor(idx)] or nil
	if item then self:grant(plr, item) end
end

local function haveRelics(r)
	local have = {}
	for _, id in ipairs(r.relics) do have[id] = true end
	return have
end

function Depths:chestFor(plr, kind, luckBonus)
	local char = plr.Character
	local classId = char and char:GetAttribute("Class") or Profile.get(plr).active
	local r = self:runOf(plr)
	local luck = (self.floor - 1) * 0.7 + (luckBonus or 0) + (char and Loot.luckOf(char) or 0)
	local floor = kind == "boss" and "Rare" or nil
	local cards = Loot.choices(kind, classId, luck, 3, {have = haveRelics(r), floor = floor, goldBase = 18 + self.floor * 10})
	self:offer(plr, cards, kind == "boss" and "THE BOSS'S HOARD" or (kind == "elite" and "A CHAMPION'S CHEST" or "A CHEST"), "Pick one")
end

function Depths:placeChest(room, kind, luck)
	local cf = CFrame.new(room.chest or room.feature) * CFrame.Angles(0, math.rad(math.random(0, 3) * 90), 0)
	local rarity = kind == "boss" and "Legendary" or (kind == "elite" and "Epic" or (kind == "treasure" and "Rare" or "Uncommon"))
	Loot.chest(cf, {rarity = rarity, perPlayer = true, gilded = kind ~= "depths", label = kind == "boss" and "The Hoard" or "Chest",
		onOpen = function(plr)
			if not aliveChar(plr) then return false end
			self:chestFor(plr, kind, luck)
			return true
		end})
end

--------------------------------------------------------------------
--  ROOMS
--------------------------------------------------------------------
function Depths:gateModels(room)
	local out = {}
	local m = MapLoader.current
	local g = m and m:FindFirstChild("Gates")
	for _, name in ipairs(room.gates or {}) do
		local gm = g and g:FindFirstChild(name)
		if gm then table.insert(out, gm) end
	end
	return out
end
function Depths:shut(room, down)
	for _, gm in ipairs(self:gateModels(room)) do Dungeon.setGate(gm, down) end
end

function Depths:sendRoom(room)
	event:FireAllClients("Room", {id = room.id, state = room.state, kind = room.kind})
end

-- who's coming at you in this room
function Depths:roster(room)
	local th = Catalog.DUNGEONS[self.theme]
	local mons = th.monsters
	local players = playersN()
	local out = {}
	local function add(id, opts) table.insert(out, {id = id, elite = opts and opts.elite, boss = opts and opts.boss}) end
	if room.kind == "boss" then
		add(th.boss, {boss = true})
		for _ = 1, 1 + math.floor(players / 2) do add(mons.common[math.random(#mons.common)]) end
		return out
	end
	local budget = (3 + self.floor * 1.3 + math.min(room.depth, 6) * 0.45) * (1 + (players - 1) * 0.55)
	if room.kind == "elite" then
		add(mons.elite[math.random(#mons.elite)], {elite = true})
		budget *= 0.55
	elseif room.kind == "stairs" then
		budget *= 1.15
		if self.floor >= 2 then add(mons.elite[math.random(#mons.elite)]); budget -= 3 end
	end
	local eliteChance = (self.floor - 1) * 0.08
	while budget >= 1 and #out < 12 do
		local ranged = math.random() < 0.28
		local pool = ranged and mons.ranged or mons.common
		local id = pool[math.random(#pool)]
		local def = Monsters.def(id)
		local cost = def and ({1, 1.6, 3.2, 8})[def.tier or 1] or 1
		add(id, {elite = math.random() < eliteChance})
		budget -= cost
	end
	return out
end

function Depths:engage(room)
	room.state = "fight"
	self.active = room
	self:shut(room, true)
	self:sendRoom(room)
	-- the stragglers are drawn in after you
	for _, p in ipairs(Players:GetPlayers()) do
		local c = aliveChar(p)
		local r = c and rootOf(c)
		if r and Dungeon.roomAt(self.layout, r.Position) ~= room then
			local inside = Vector3.new(room.cx, 3, room.cz) + Vector3.new(math.random(-4, 4), 0, room.d / 2 - 8)
			c:PivotTo(CFrame.new(inside, Vector3.new(room.cx, 3, room.cz)))
		end
	end
	local players = playersN()
	local hpMult = (1 + (self.floor - 1) * 0.22) * (1 + (players - 1) * 0.3)
	local dealt = 1 + (self.floor - 1) * 0.08
	local opts = {team = "B", startDelay = 1.2, corpseTime = 3,
		hpMult = hpMult, dealt = dealt,
		arena = {centre = Vector3.new(room.cx, 0, room.cz), radius = math.max(room.w, room.d) / 2 + 4},
		bounds = {centre = Vector3.new(room.cx, 0, room.cz), hw = room.w / 2, hd = room.d / 2},
		onSpawn = function(mob) room.mobs[mob] = true end,
		onDeath = function(mob, killer)
			room.mobs[mob] = nil
			local tier = mob.def.tier or 1
			if killer then
				local r = self:runOf(killer)
				r.kills += 1
				r.gold += KILL_GOLD[tier] or 2
				Loot.onKill(killer)
				if _G.RoundBump then _G.RoundBump(killer, "kill_" .. (tier >= 3 and "Champion" or (tier == 2 and "Knight" or "Squire"))) end
				self:sendRun(killer)
			end
			if mob.boss then self.bossDown = true end
		end}
	room.opts = opts
	room.mobs = {}
	local list = self:roster(room)
	for i, e in ipairs(list) do
		local spot = room.spots[((i - 1) % #room.spots) + 1]
		if e.boss then spot = room.feature + Vector3.new(0, 3, 0) end
		local o2 = {at = CFrame.new(spot, Vector3.new(room.cx, spot.Y, room.cz)), elite = e.elite}
		if e.boss then o2.hpMult = (1 + (players - 1) * 0.6) * (1 + (self.floor - 1) * 0.1) end
		local mob = Monsters.spawn(e.id, opts, o2)
		if mob then
			room.mobs[mob] = true
			if e.boss then
				self.boss = mob
				node:SetAttribute("BossName", mob.def.name)
			end
		end
	end
	if room.kind == "boss" then
		local th = Catalog.DUNGEONS[self.theme]
		event:FireAllClients("Banner", {text = string.upper(th.bossName or "THE BOSS"), sub = "THE LORD OF " .. string.upper(th.name), kind = "boss"})
	elseif room.kind == "elite" then
		event:FireAllClients("Banner", {text = "A CHAMPION", sub = "THE GATES SLAM SHUT", kind = "elite"})
	else
		event:FireAllClients("Banner", {text = "THE GATES SLAM SHUT", sub = string.format("%d FOES", #list), kind = "fight"})
	end
end

function Depths:clear(room)
	room.state = "clear"
	self.active = nil
	self:shut(room, false)
	self:sendRoom(room)
	for _, p in ipairs(Players:GetPlayers()) do if _G.RoundBump then _G.RoundBump(p, "depths_room") end end
	-- the fallen are back on their feet, everyone a little mended
	for _, p in ipairs(Players:GetPlayers()) do
		local c = aliveChar(p)
		if c then
			local h = humOf(c)
			h.Health = math.min(h.MaxHealth, h.Health + h.MaxHealth * 0.25)
		else
			local at = CFrame.new(Vector3.new(room.cx + math.random(-5, 5), 3, room.cz + math.random(-5, 5)))
			self:revive(p, at)
		end
	end
	if room.kind == "boss" then
		self:placeChest(room, "boss", 2.5)
		self.won = true
		self.wonAt = os.clock()
		for _, p in ipairs(Players:GetPlayers()) do
			if _G.RoundBump then _G.RoundBump(p, "depths_boss"); _G.RoundBump(p, "depths_floor") end
			local st = Profile.get(p).stats
			st.depthsClears = (st.depthsClears or 0) + 1
			st.depthsBest = math.max(st.depthsBest or 0, FLOORS + 1)
		end
		event:FireAllClients("Banner", {text = "VICTORY", sub = "THE " .. string.upper(Catalog.DUNGEONS[self.theme].name) .. " IS CLEANSED", kind = "victory"})
		node:SetAttribute("BossName", nil)
		return
	end
	event:FireAllClients("Banner", {text = "ROOM CLEARED", sub = room.kind == "stairs" and "THE WAY DOWN IS OPEN" or nil, kind = "clear"})
	if room.kind == "elite" then self:placeChest(room, "elite", 1.2)
	elseif room.kind == "stairs" then self:openStairs(room)
	elseif math.random() < 0.38 then self:placeChest(room, "depths", 0) end
end

-- the kind rooms' things to use
function Depths:dressRooms()
	for _, room in ipairs(self.layout.rooms) do
		room.state = (room.kind == "combat" or room.kind == "elite" or room.kind == "stairs" or room.kind == "boss") and "sealed" or "clear"
		if room.kind == "start" then room.state = "clear" end
		if room.kind == "treasure" then self:placeChest(room, "depths", 1) end
		if room.kind == "shrine" then
			local p = Instance.new("Part")
			p.Name = "ShrinePrompt"; p.Anchored, p.CanCollide, p.Transparency = true, false, 1
			p.Size = Vector3.new(2, 2, 2); p.Position = room.feature + Vector3.new(0, 4, 0)
			p.Parent = MapLoader.current
			local pr = Instance.new("ProximityPrompt")
			pr.ActionText = "Pray"; pr.ObjectText = "Shrine"; pr.HoldDuration = 1; pr.MaxActivationDistance = 12; pr.RequiresLineOfSight = false
			pr:SetAttribute("PickupKey", true)
			pr.Parent = p
			local used = {}
			pr.Triggered:Connect(function(plr)
				if used[plr] or not aliveChar(plr) then return end
				used[plr] = true
				p:SetAttribute("OpenedBy_" .. plr.UserId, true)
				local r = self:runOf(plr)
				local have = haveRelics(r)
				local cards = {}
				for _ = 1, 3 do
					local rel = Loot.relic(2 + self.floor * 0.6, have)
					if rel then have[rel.relic] = true; table.insert(cards, rel) end
				end
				self:offer(plr, cards, "A BLESSING", "The shrine offers you one")
			end)
		elseif room.kind == "fountain" then
			local p = Instance.new("Part")
			p.Name = "FountainPrompt"; p.Anchored, p.CanCollide, p.Transparency = true, false, 1
			p.Size = Vector3.new(2, 2, 2); p.Position = room.feature + Vector3.new(0, 3, 0)
			p.Parent = MapLoader.current
			local pr = Instance.new("ProximityPrompt")
			pr.ActionText = "Drink"; pr.ObjectText = "Fountain"; pr.HoldDuration = 0.8; pr.MaxActivationDistance = 12; pr.RequiresLineOfSight = false
			pr:SetAttribute("PickupKey", true)
			pr.Parent = p
			pr.Triggered:Connect(function(plr)
				local r = self:runOf(plr)
				local c = aliveChar(plr)
				if r.fountain[self.floor] or not c then return end
				r.fountain[self.floor] = true
				p:SetAttribute("OpenedBy_" .. plr.UserId, true)
				local h = humOf(c)
				h.Health = h.MaxHealth
				for _, a in ipairs({"Burning", "Poisoned", "Frosted"}) do c:SetAttribute(a, nil) end
				Loot.sparkle(room.feature + Vector3.new(0, 3, 0), Color3.fromRGB(120, 255, 210))
				event:FireClient(plr, "Banner", {text = "REFRESHED", sub = "WHOLE AGAIN", kind = "clear"})
			end)
		end
	end
end

function Depths:openStairs(room)
	local p = Instance.new("Part")
	p.Name = "StairsPrompt"; p.Anchored, p.CanCollide, p.Transparency = true, false, 1
	p.Size = Vector3.new(2, 2, 2); p.Position = room.feature + Vector3.new(0, 4, 0)
	p.Parent = MapLoader.current
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = "Descend"; pr.ObjectText = "Floor " .. (self.floor + 1); pr.HoldDuration = 1; pr.MaxActivationDistance = 14; pr.RequiresLineOfSight = false
	pr:SetAttribute("PickupKey", true)
	pr.Parent = p
	pr.Triggered:Connect(function(plr)
		if self.descendAt or not aliveChar(plr) then return end
		self.descendAt = os.clock() + 5
		pr.Enabled = false
		event:FireAllClients("Banner", {text = "DESCENDING", sub = plr.DisplayName .. " TAKES THE STAIRS  ·  5", kind = "descend", countdown = 5})
	end)
end

-- the next floor: built, loaded, everyone (the fallen too) at its start
function Depths:descend()
	self.descendAt = nil
	self.floor += 1
	for _, p in ipairs(Players:GetPlayers()) do if _G.RoundBump then _G.RoundBump(p, "depths_floor") end
		local st = Profile.get(p).stats
		st.depthsBest = math.max(st.depthsBest or 0, self.floor)
	end
	event:FireAllClients("Fade", {on = true})
	task.wait(0.6)
	-- hold everyone still while the floor is swapped
	for _, p in ipairs(Players:GetPlayers()) do local r = p.Character and rootOf(p.Character); if r then r.Anchored = true end end
	Loot.clear()
	local name, layout = Dungeon.build(self.theme, floorOpts(self.floor, playersN()))
	self.layout = layout
	MapLoader.load(name)
	Dungeon.sweep(name)
	self:dressRooms()
	local spawns = MapLoader.spawns(nil)
	local i = 0
	for _, p in ipairs(Players:GetPlayers()) do
		i += 1
		local cf = spawns[((i - 1) % #spawns) + 1]
		local c = aliveChar(p)
		if c then
			c:PivotTo(CFrame.new(cf.Position + Vector3.new(0, 3, 0)) * cf.Rotation)
			local r = rootOf(c); if r then r.Anchored = false end
		else
			self:revive(p, CFrame.new(cf.Position + Vector3.new(0, 3, 0)))
		end
	end
	self:sendLayout()
	node:SetAttribute("DepthsFloor", self.floor)
	event:FireAllClients("Fade", {on = false})
	local th = Catalog.DUNGEONS[self.theme]
	event:FireAllClients("Banner", {text = "FLOOR " .. self.floor, sub = self.floor >= FLOORS and ("THE LAIR OF " .. string.upper(th.bossName or "THE BOSS")) or string.upper(th.name), kind = "floor"})
end

function Depths:sendLayout(plr)
	local L = self.layout
	if not L then return end
	local rooms = {}
	for _, r in ipairs(L.rooms) do
		local doors = {}
		for d, nid in pairs(r.doors) do doors[d] = nid end
		rooms[r.id] = {id = r.id, cx = r.cx, cz = r.cz, w = r.w, d = r.d, kind = r.kind, state = r.state, doors = doors}
	end
	local data = {rooms = rooms, floor = self.floor, floors = FLOORS, theme = self.theme, themeName = Catalog.DUNGEONS[self.theme].name}
	if plr then event:FireClient(plr, "Layout", data) else event:FireAllClients("Layout", data) end
end

--------------------------------------------------------------------
--  THE ROUND
--------------------------------------------------------------------
function Depths:start(map)
	Game.Mode.start(self, map)
	node:SetAttribute("FriendlyFire", false)
	self.runs, self.offers, self.offerN, self.reviving = {}, {}, 0, {}
	self.theme = Catalog.DUNGEONS[map] and map or (self.theme or "BoneCrypt")
	self.floor = 1
	self.won, self.wiped, self.boss, self.bossDown, self.active, self.descendAt = false, false, nil, false, nil, nil
	self.everUp = false
	if not self.layout or self.layout.theme ~= self.theme then
		-- (no procedural build happened: Studio's switch onto a map name; build it now)
		local name = self:buildMap(self.theme)
		MapLoader.load(name)
	end
	self:dressRooms()
	node:SetAttribute("ObjKind", "Depths")
	node:SetAttribute("OwnHud", true)   -- (Adventure.client draws it; Objectives steps aside)
	node:SetAttribute("DepthsFloor", 1)
	node:SetAttribute("DepthsTheme", self.theme)
	self:sendLayout()
	for _, p in ipairs(Players:GetPlayers()) do self:sendRun(p) end
	local th = Catalog.DUNGEONS[self.theme]
	task.delay(2, function()
		event:FireAllClients("Banner", {text = string.upper(th.name), sub = "FLOOR 1 OF " .. FLOORS .. "  ·  " .. string.upper(th.sub or ""), kind = "floor"})
	end)
	if not self.pickConn then
		self.pickConn = event.OnServerEvent:Connect(function(plr, kind, a, b)
			local mode = Game.current
			if mode ~= self then return end
			if kind == "Pick" then self:pick(plr, a, b)
			elseif kind == "Hello" then self:sendLayout(plr); self:sendRun(plr) end
		end)
	end
	self:publishScores()
end

function Depths:stop()
	if self.active and self.active.opts then Monsters.halt(self.active.opts) end
	for _, room in ipairs(self.layout and self.layout.rooms or {}) do
		for mob in pairs(room.mobs or {}) do Monsters.despawn(mob) end
		if room.opts then Monsters.halt(room.opts) end
	end
	Loot.clear()
	for _, k in ipairs(ATTRS) do node:SetAttribute(k, nil) end
	node:SetAttribute("BossName", nil)
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c then Loot.setRelics(c, {}) end
	end
	self.layout = nil
	event:FireAllClients("Layout", nil)
end

-- back on their feet at `at` (the run comes with them: adjustLoadout / noteSpawn); while the
-- body is on its way they count as up (no wipe in the gap)
function Depths:revive(plr, at)
	self.reviving[plr] = true
	if _G.Respawn then _G.Respawn(plr, Profile.get(plr).active, at, {}) end
	task.delay(5, function() if self.reviving then self.reviving[plr] = nil end end)
end

function Depths:canSpawn(plr)
	if self.reviving and self.reviving[plr] then return true end
	if self.active and self.everUp then return false, "Your party is fighting: you're back on your feet when the room is cleared" end
	return true
end

function Depths:onDeath(victimPlr)
	-- the Phoenix Plume: up again where you fell
	local c = victimPlr.Character
	if c and Loot.tryRise(c) then
		local r = self:runOf(victimPlr)
		r.risen = true
		local at = rootOf(c) and CFrame.new(rootOf(c).Position + Vector3.new(0, 2, 0)) or nil
		self.reviving[victimPlr] = true
		task.delay(2, function()
			self:revive(victimPlr, at)
			event:FireAllClients("Banner", {text = "RISEN", sub = string.upper(victimPlr.DisplayName) .. "'S PHOENIX PLUME BURNS", kind = "clear"})
		end)
	end
end

function Depths:tick(dt)
	if not self.layout then return end
	local now = os.clock()
	local up = 0
	for _, p in ipairs(Players:GetPlayers()) do if aliveChar(p) then up += 1 end end
	if up > 0 then self.everUp = true end
	if self.descendAt and now >= self.descendAt then self:descend(); return end
	-- the party fell
	if self.everUp and up == 0 and not next(self.reviving) then
		self.wiped = true
		return
	end
	local room = self.active
	if room then
		local left = 0
		for mob in pairs(room.mobs) do
			-- (one that fell out of the world, or lost its body, is put back in the room's middle)
			local r = mob.alive and mob.model and rootOf(mob.model)
			-- (one outside the room's walls, behind its gates, is put back in: it could never be reached)
			if r and r.Position.Y > -30 and (math.abs(r.Position.X - room.cx) > room.w / 2 + 1.5 or math.abs(r.Position.Z - room.cz) > room.d / 2 + 1.5) then
				mob.outsideSince = mob.outsideSince or now
				if now - mob.outsideSince > 1.5 then
					mob.outsideSince = nil
					local spot = room.spots[math.random(#room.spots)]
					local sc = mob.model:GetAttribute("MonsterScale") or 1
					local at = spot + Vector3.new(0, 3 * (sc - 1) + 0.5, 0)
					mob.model:PivotTo(CFrame.new(at, Vector3.new(room.cx, at.Y, room.cz)))
				end
			else
				mob.outsideSince = nil
			end
			if mob.alive and (not r or r.Position.Y < -30) then
				if r then mob.model:PivotTo(CFrame.new(room.cx, 6, room.cz))
				else
					-- (no body left at all: a fresh one, in the middle)
					Monsters.despawn(mob); room.mobs[mob] = nil
					local over = table.clone(mob.over or {})
					over.at = CFrame.new(room.cx, 4, room.cz)
					local again = Monsters.spawn(mob.id, room.opts, over)
					if again then room.mobs[again] = true; if mob.boss then self.boss = again end end
				end
			end
			if mob.alive then left += 1 else room.mobs[mob] = nil end
		end
		left += Monsters.pending(room.opts)
		node:SetAttribute("ObjLabel", "FLOOR " .. self.floor .. "  ·  " .. string.upper(room.kind == "boss" and "THE BOSS" or (room.kind == "elite" and "A CHAMPION" or "FIGHT")))
		node:SetAttribute("ObjNote", string.format("%d FOE%s LEFT", left, left == 1 and "" or "S"))
		node:SetAttribute("ObjState", "fight")
		if left == 0 and (now - (room.engagedAt or 0)) > 2 then self:clear(room) end
	else
		-- step into a sealed room (well inside: not just its doorway) and it begins
		for _, p in ipairs(Players:GetPlayers()) do
			local c = aliveChar(p)
			local r = c and rootOf(c)
			if r then
				local rm = Dungeon.roomAt(self.layout, r.Position)
				if rm and rm.state == "sealed" and math.abs(r.Position.X - rm.cx) < rm.w / 2 - 6 and math.abs(r.Position.Z - rm.cz) < rm.d / 2 - 6 then
					rm.engagedAt = now
					self:engage(rm)
					break
				end
			end
		end
		node:SetAttribute("ObjLabel", "FLOOR " .. self.floor .. " OF " .. FLOORS)
		node:SetAttribute("ObjNote", self.descendAt and string.format("DESCENDING IN %d", math.max(0, math.ceil(self.descendAt - now))) or "EXPLORE")
		node:SetAttribute("ObjState", "explore")
	end
	node:SetAttribute("Objective", self:objective())
end

function Depths:isOver()
	if self.wiped then
		return string.format("YOUR PARTY FELL ON FLOOR %d OF %s", self.floor, string.upper(Catalog.DUNGEONS[self.theme].name))
	end
	if self.won and os.clock() - (self.wonAt or 0) > 25 then
		return string.format("VICTORY  ·  %s SLAIN", string.upper(Catalog.DUNGEONS[self.theme].bossName or "THE BOSS"))
	end
	return nil
end
function Depths:result() return "THE RUN IS OVER" end
function Depths:objective()
	local th = self.theme and Catalog.DUNGEONS[self.theme]
	return string.format("THE DEPTHS  ·  %s  ·  FLOOR %d OF %d", th and string.upper(th.name) or "", self.floor or 1, FLOORS)
end

return Depths
