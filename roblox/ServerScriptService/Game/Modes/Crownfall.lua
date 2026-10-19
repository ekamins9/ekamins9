--[[ CROWNFALL — a battle royale (GameConfig.MODES.Crownfall). An island built fresh every match
     (Game ▸ Realm): the Crown Keep on its hill in the middle, villages, a harbour, farms, a mill,
     towers, a mine, a lodge, a fort, a chapel, ruins, camps, each with its name and its chests;
     roads, a river, a lake and forests between.

     NOTHING COMES IN WITH YOU. No class to pick, no armour, no power, no throwable, no skins:
     everyone is the same plain body (GameConfig forceClass, the Vanguard's: no stats of its own)
     in plain clothes with an old dagger (FREE_WEAPON). Everything else is found.
     THE DRAGON. Everyone rides in on the back of a great dragon flying across the island, high
     up (BUS_*). Leap off where you like (the Jump key, "Leap"); at the far shore it shakes off
     whoever's still aboard. You fall steering, look down to dive faster, and land like a hero
     (StarterPlayerScripts ▸ Skyfall.client: the ride, the dive, the landing; "Landed").
     THE LOOT. A chest spills three things (Catalog ▸ Loot CHESTS.crownfall): a weapon (rarities,
     skins, affixes), armour (a real set on your body: the heavier, the tougher and the slower;
     Catalog ▸ Loot ARMOR) or a potion; more lies on the ground about the places. Walk over and
     take it: a weapon into a free hand (the old dagger gives way), armour on if it's better, a
     potion onto your belt, anything else into your bag.
     YOUR INVENTORY (RaidInventory.client: the bag key): two weapons, your armour, a belt of BELT
     potions (keys 3 – 6 drink one: a moment with the bottle at your lips, slowed) and a bag of
     BAG_MAX; equip, take off, drink, drop. Whoever falls drops everything they found.
     THE RING. A ring of fire closes in phases (RING), each tighter and hotter: outside it you burn.
     The next ring shows on your map before it moves. Bots fill the island (BotFill, fillAnywhere):
     they were there before you, with what they'd found (a weapon, armour now and then).
     ROYAL CACHES. As each of the first rings starts to close, a gilded chest comes down out of
     the sky under a canopy somewhere inside the next ring, a gold flare over it the whole way (and
     till someone opens it): four things inside, rolled with a king's luck. Worth the fight.
     No coming back: the last one standing wins the crown (stats.crownfallWins).

     On screen (Adventure.client, OwnHud): how many are left, the ring's clock, the island's map
     with its places, the ring and the next one, and the place you're in.

       client → server (AdventureEvent)  "Leap" (off the dragon) · "Landed" (on the ground) ·
                                         "Inv", Equip | Unequip | Use | Drop, uid | slot ·
                                         "Belt", 1 – 4 · "Hello"
       server → client                   "Inv", {royale = true, equip, bag, belt, beltMax, max} | nil
       character attributes              Riding (on the dragon) · Diving (server time it leapt) ·
                                         HeroLand (server time it landed): Skyfall.client draws them ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Realm = require(script.Parent.Parent:WaitForChild("Realm"))
local Loot = require(script.Parent.Parent:WaitForChild("Loot"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Powers = require(Combat:WaitForChild("Powers"))
local Dragon = require(Combat:WaitForChild("Dragon"))
local LoadoutF = ServerScriptService:WaitForChild("Loadout")
local Profile = require(LoadoutF:WaitForChild("Profile"))
local Avatars = require(LoadoutF:WaitForChild("Avatars"))
local MapLoader = Game.MapLoader
local node = Game.node
local LOOT = Catalog.LOOT

local ISLAND = 520
local CLASS = "Vanguard"        -- the body everyone gets (GameConfig MODES.Crownfall forceClass)
local FREE_WEAPON = "Dagger"
local PLAIN_SET = "PeasantSkin" -- plain clothes (its top and its legs; your own head bare)
local BAG_MAX = 6
local BELT = 4
-- THE DRAGON: across the island at BUS_ALT, BUS_SPEED studs a second, from BUS_OUT out past one
-- shore to BUS_OUT past the other, BUS_SCALE times Dragonfall's wyrm
local BUS_ALT = 235
local BUS_SPEED = 50
local BUS_OUT = 150
local BUS_SCALE = 2
local DIVE_MAX = 40             -- a dive that never lands is over after this (seconds)
-- the ring's phases: wait, then shrink over `shrink` s to `to` of the island; outside, `dps`
-- (the first wait counts from the round's start: the ride and the fall come first)
local RING = {
	{wait = 85, shrink = 35, to = 0.62, dps = 3},
	{wait = 40, shrink = 30, to = 0.4, dps = 5},
	{wait = 35, shrink = 25, to = 0.22, dps = 8},
	{wait = 30, shrink = 22, to = 0.1, dps = 12},
	{wait = 25, shrink = 20, to = 0.0, dps = 18},
}
local SEGMENTS = 64
local CACHES = 3           -- royal caches: one as each of the first rings closes
local CACHE_FALL = 9       -- seconds it takes to come down
local CHEST_KIND = "crownfall"
local GROUND_LOOT = {weapon = 44, armor = 30, potion = 26}
-- the bots' finds before you landed: their armour (nil: plain clothes)
local BOT_ARMOR = {{w = 30}, {w = 34, id = "Padded"}, {w = 24, id = "Mail"}, {w = 9, id = "Brigandine"}, {w = 3, id = "Plate"}}
local ROAR = "rbxasset://sounds/HalloweenGhost.wav"
-- the cloth of what you wear (Catalog ▸ Palette names): plain clothes in the first; a find in one
-- of these by its own (the same piece, the same colours, whoever wears it); the rarest in gold
local PALETTES = {
	{Primary = "Umber", Secondary = "Sand", Accent = "Olive", Metal = "Ash"},
	{Primary = "Forest", Secondary = "Bone", Accent = "Umber", Metal = "Steel"},
	{Primary = "Wine", Secondary = "Bone", Accent = "Ochre", Metal = "Steel"},
	{Primary = "Navy", Secondary = "Slate", Accent = "Ochre", Metal = "Steel"},
	{Primary = "Moss", Secondary = "Sand", Accent = "Rust", Metal = "Ash"},
	{Primary = "Slate", Secondary = "Ash", Accent = "Crimson", Metal = "Steel"},
	{Primary = "Rust", Secondary = "Umber", Accent = "Bone", Metal = "Ash"},
}
local ROYAL = {Primary = "Crimson", Secondary = "Gold", Accent = "White", Metal = "Gold"}

local Crownfall = setmetatable({}, {__index = Game.Mode})
Crownfall.__index = Crownfall
function Crownfall.new(def, id) return setmetatable(Game.Mode.new(def, id), Crownfall) end

local function humOf(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function rootOf(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function alive(c) local h = humOf(c); return h ~= nil and h.Health > 0 end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function uid() return HttpService:GenerateGUID(false):sub(1, 8) end
local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function banner(t, plr) local e = event(); if e then if plr then e:FireClient(plr, "Banner", t) else e:FireAllClients("Banner", t) end end end
local function rank(item) return LOOT.RANK[item and item.rarity or ""] or 0 end

local function plainLook()
	local lo = {colors = PALETTES[1]}
	for _, pc in ipairs(Catalog.setPieces(PLAIN_SET)) do if pc.slot ~= "helmet" then lo[pc.slot] = pc.id end end
	return lo
end
local function paletteOf(item)
	if item.rarity == "Legendary" then return ROYAL end
	local h = 0
	for i = 1, #(item.uid or "") do h = (h * 31 + string.byte(item.uid, i)) % 9973 end
	return PALETTES[2 + h % (#PALETTES - 1)]
end
local function freeDagger()
	local w = Catalog.WEAPON[FREE_WEAPON]
	return {kind = "weapon", uid = uid(), weapon = FREE_WEAPON, rarity = "Common", name = "Old " .. ((w and w.name) or FREE_WEAPON),
		power = 0, affixes = {}, slot = 1, free = true}
end
local function pickWeighted(list)
	local total = 0
	for _, e in ipairs(list) do total += e.w end
	local x = math.random() * total
	for _, e in ipairs(list) do x -= e.w; if x <= 0 then return e end end
	return list[#list]
end
local function pickKind(weights)
	local list = {}
	for k, w in pairs(weights) do table.insert(list, {w = w, k = k}) end
	return pickWeighted(list).k
end

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
--  WHAT YOU CARRY
--------------------------------------------------------------------
function Crownfall:runOf(plr)
	local r = self.runs[plr]
	if not r then r = {weapons = {}, armor = nil, bag = {}, belt = {}}; self.runs[plr] = r end
	return r
end
local function carried(r)
	local all = {}
	for _, k in ipairs({1, 2}) do if r.weapons[k] then table.insert(all, r.weapons[k]) end end
	if r.armor then table.insert(all, r.armor) end
	for _, it in ipairs(r.belt) do table.insert(all, it) end
	for _, it in ipairs(r.bag) do table.insert(all, it) end
	return all
end
local function removeTools(plr, slot)
	for _, holder in ipairs({plr.Character, plr:FindFirstChildOfClass("Backpack")}) do
		for _, t in ipairs(holder and holder:GetChildren() or {}) do
			if t:IsA("Tool") and t:GetAttribute("Slot") == slot then t:Destroy() end
		end
	end
end
local function findIn(list, id)
	for i, it in ipairs(list) do if it.uid == id then return i, it end end
	return nil
end
local function heldSlot(plr)
	local t = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
	local s = t and t:GetAttribute("Slot")
	return (s == 1 or s == 2) and s or nil
end

-- the inventory screen's picture of you
function Crownfall:sendRun(plr)
	local r = self:runOf(plr)
	local function card(it, slot)
		local c = Loot.card(it)
		c.slot, c.free = slot, it.free
		return c
	end
	local equip = {}
	if r.weapons[1] then equip.weapon1 = card(r.weapons[1], "weapon1") end
	if r.weapons[2] then equip.weapon2 = card(r.weapons[2], "weapon2") end
	if r.armor then equip.armor = card(r.armor, "armor") end
	local bag, belt = {}, {}
	for _, it in ipairs(r.bag) do table.insert(bag, card(it, "bag")) end
	for i, it in ipairs(r.belt) do table.insert(belt, card(it, "belt" .. i)) end
	local e = event()
	if e then e:FireClient(plr, "Inv", {royale = true, equip = equip, bag = bag, belt = belt, beltMax = BELT, max = BAG_MAX}) end
end

-- THE PLAIN START: the Vanguard's body, plain clothes, the old dagger; nothing else of yours
function Crownfall:adjustLoadout(plr, lo, classId)
	local plain = plainLook()
	lo.helmet, lo.top, lo.bottom, lo.noHelm = nil, plain.top, plain.bottom, nil
	lo.colors, lo.armorFx, lo.spellSkins = plain.colors, "", {}
	lo.weapon, lo.weaponSkin = FREE_WEAPON, nil
	lo.secondary, lo.secondarySkin = nil, nil
	lo.shield, lo.shieldSkin = nil, nil
	lo.power, lo.throwable, lo.throwableSkin = "none", "none", nil
	lo.thirdKind, lo.thirdId, lo.thirdSkin = "none", nil, nil
	lo.lootOnly = true
end

-- a weapon into a hand (slot 1 or 2), the one there before gone
function Crownfall:arm(plr, item, slot, equip)
	local r = self:runOf(plr)
	item.slot = slot
	r.weapons[slot] = item
	if _G.GiveWeapon then
		local tool, twin = _G.GiveWeapon(plr, item.weapon, item.skin, slot, equip)
		Loot.tagTool(tool, item)
		if twin then Loot.tagTool(twin, item) end
	end
end

-- ARMOUR ON YOUR BODY: the set it is (Catalog ▸ Loot ARMOR set / weight), or plain clothes
-- again; its weight's stats from the Dresser, its own (less taken, more health) from Loot.
-- Dressing starts health afresh: the wounds you had stay
function Crownfall:wear(plr, item)
	local char = plr.Character
	local hum = humOf(char)
	if not hum then return end
	local a = item and LOOT.ARMOR_BY[item.armor]
	local hurt = math.max(0, hum.MaxHealth - hum.Health)
	local lo = plainLook()
	if a then
		for _, pc in ipairs(Catalog.setPieces(a.set)) do lo[pc.slot] = pc.id end
		lo.colors = paletteOf(item)
	end
	Loot.setArmor(char, nil)
	local st = Loot.stateOf(char)
	st.bonus = nil
	local ok, err = pcall(Dresser.dress, char, {loadout = lo, appearance = Avatars.appearanceOf(plr), weight = a and a.weight or "Light"})
	if not ok then warn("[Crownfall] dress:", err) end
	Loot.setArmor(char, a and a.id or nil)
	hum.Health = math.max(1, hum.MaxHealth - hurt)
end

local function full(plr)
	banner({text = "YOUR BAG IS FULL", sub = "DROP SOMETHING TO MAKE ROOM  ·  YOUR BAG {Bag}", kind = "fight"}, plr)
	return false
end

-- SOMETHING TAKEN off the ground: worn or held if it should be, else into the bag
function Crownfall:take(plr, item)
	local char = plr.Character
	if not alive(char) then return false end
	local r = self:runOf(plr)
	local function bagged()
		if #r.bag >= BAG_MAX then return false end
		table.insert(r.bag, item)
		return true
	end
	local said
	if item.kind == "weapon" then
		local slot = not r.weapons[1] and 1 or (not r.weapons[2] and 2 or nil)
		-- (both hands full: the old dagger gives way to a find, into the bag if there's room)
		if not slot then
			for s = 1, 2 do if r.weapons[s] and r.weapons[s].free then slot = s end end
			if slot then
				local old = r.weapons[slot]
				if #r.bag < BAG_MAX then table.insert(r.bag, old) end
			end
		end
		if slot then
			self:arm(plr, item, slot, true)
		elseif bagged() then
			said = "INTO YOUR BAG"
		else
			return full(plr)
		end
	elseif item.kind == "armor" then
		if not r.armor or rank(item) > rank(r.armor) then
			local old = r.armor
			r.armor = item
			self:wear(plr, item)
			if old then
				if #r.bag < BAG_MAX then table.insert(r.bag, old) else self:dropItem(old, rootOf(char).Position) end
			end
		elseif bagged() then
			said = "INTO YOUR BAG"
		else
			return full(plr)
		end
	elseif item.kind == "potion" then
		if #r.belt < BELT then
			table.insert(r.belt, item)
			said = "ON YOUR BELT"
		elseif bagged() then
			said = "INTO YOUR BAG"
		else
			return full(plr)
		end
	elseif not bagged() then
		return full(plr)
	end
	local c = Loot.card(item) or {}
	banner({text = string.upper(item.name or ""), sub = said and (said .. "  ·  " .. (c.sub or "")) or c.sub, kind = "clear"}, plr)
	self:sendRun(plr)
	return true
end

function Crownfall:dropItem(item, pos, i, n)
	if not item then return end
	local a = ((i or math.random(1, 8)) / (n or 8)) * math.pi * 2
	local d = 2.5 + (n or 1) * 0.35
	local at = pos + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
	Loot.drop(item, at - Vector3.new(0, 2.5, 0), {life = 300, onTake = function(plr, it) return self:take(plr, it) end})
end

-- THE INVENTORY'S ASKS: equip from the bag, take off into it, drink, drop at your feet
function Crownfall:inv(plr, what, a)
	local r = self.runs and self.runs[plr]
	local char = plr.Character
	if not (r and alive(char)) or type(a) ~= "string" then return end
	if what == "Equip" then
		local i, it = findIn(r.bag, a)
		if not it then return end
		if it.kind == "weapon" then
			table.remove(r.bag, i)
			-- (a free hand first; else in place of the one you hold, which goes into the bag)
			local slot = not r.weapons[1] and 1 or (not r.weapons[2] and 2 or (heldSlot(plr) or 1))
			local old = r.weapons[slot]
			if old then table.insert(r.bag, i, old) end
			self:arm(plr, it, slot, true)
		elseif it.kind == "armor" then
			table.remove(r.bag, i)
			if r.armor then table.insert(r.bag, i, r.armor) end
			r.armor = it
			self:wear(plr, it)
		elseif it.kind == "potion" then
			-- (onto your belt, if there's room on it; else drunk)
			if #r.belt < BELT then table.remove(r.bag, i); table.insert(r.belt, it)
			else return self:inv(plr, "Use", a) end
		end
	elseif what == "Unequip" then
		if #r.bag >= BAG_MAX then full(plr); return end
		local bn = tonumber(a:match("^belt(%d)$") or "")
		if bn and r.belt[bn] then
			table.insert(r.bag, table.remove(r.belt, bn))
		elseif a == "weapon1" or a == "weapon2" then
			local slot = a == "weapon1" and 1 or 2
			local it = r.weapons[slot]
			if not it then return end
			removeTools(plr, slot)
			r.weapons[slot] = nil
			table.insert(r.bag, it)
		elseif a == "armor" and r.armor then
			table.insert(r.bag, r.armor)
			r.armor = nil
			self:wear(plr, nil)
		end
	elseif what == "Use" then
		-- (a potion: from your belt or your bag; a moment to drink it, slowed)
		local list = r.bag
		local i, it = findIn(r.belt, a)
		if it then list = r.belt else i, it = findIn(r.bag, a) end
		if it and it.kind == "potion" and Loot.drinkSlow(char, it.potion) then table.remove(list, i) end
	elseif what == "Drop" then
		local root = rootOf(char)
		local here = root.Position + root.CFrame.LookVector * 3
		local i, it = findIn(r.bag, a)
		local bi, bt = findIn(r.belt, a)
		if it then
			table.remove(r.bag, i)
			self:dropItem(it, here)
		elseif bt then
			table.remove(r.belt, bi)
			self:dropItem(bt, here)
		else
			for s = 1, 2 do
				local w = r.weapons[s]
				if w and w.uid == a then removeTools(plr, s); r.weapons[s] = nil; self:dropItem(w, here) end
			end
			if r.armor and r.armor.uid == a then
				local old = r.armor
				r.armor = nil
				self:wear(plr, nil)
				self:dropItem(old, here)
			end
		end
	end
	self:sendRun(plr)
end

--------------------------------------------------------------------
--  THE LOOT ON THE ISLAND
--------------------------------------------------------------------
-- a chest spills three things (different kinds where it can), rolled for whoever opened it
function Crownfall:placeChests()
	for _, cf in ipairs(self.layout.chests) do
		-- (the island put it exactly on the ground, facing out: Realm)
		local spot = cf
		local ground = cf.Position
		local rarity = (math.random() < 0.12) and "Epic" or ((math.random() < 0.3) and "Rare" or "Common")
		Loot.chest(spot, {rarity = rarity, gilded = rarity ~= "Common", label = rarity == "Common" and "Chest" or (rarity .. " chest"),
			onOpen = function(plr)
				if not alive(plr.Character) then return false end
				local luck = (rarity == "Epic" and 2.5) or (rarity == "Rare" and 1.2) or 0.3
				-- (two of different kinds, and one of anything)
				local items = Loot.choices(CHEST_KIND, CLASS, luck + Loot.luckOf(plr.Character), 2)
				table.insert(items, Loot.roll(CHEST_KIND, CLASS, luck + Loot.luckOf(plr.Character)))
				for i, item in ipairs(items) do
					local a = (i / 3) * math.pi * 2
					local at = ground + spot:VectorToWorldSpace(Vector3.new(math.cos(a) * 3.2, 0, -2.4 + math.sin(a) * 1.4))
					task.delay(0.15 * i, function()
						if Game.current ~= self then return end
						Loot.drop(item, at, {life = 300, onTake = function(p2, it) return self:take(p2, it) end})
					end)
				end
				return true
			end})
	end
	-- and things lying about the places (a weapon dropped, a mail shirt, a bottle)
	for _, pos in ipairs(self.layout.loot or {}) do
		local item = Loot.roll(nil, CLASS, 0.2, {kind = pickKind(GROUND_LOOT)})
		if item then Loot.drop(item, pos, {onTake = function(plr, it) return self:take(plr, it) end}) end
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
			onOpen = function(plr)
				local char = plr.Character
				if not alive(char) then return false end
				flare:Destroy()
				for i, item in ipairs(Loot.choices(CHEST_KIND, CLASS, 4.5 + Loot.luckOf(char), 4)) do
					local a = (i / 4) * math.pi * 2
					local at = ground + Vector3.new(math.cos(a) * 3.4, 0, math.sin(a) * 3.4)
					task.delay(0.15 * i, function()
						Loot.drop(item, at, {life = 300, onTake = function(p2, it) return self:take(p2, it) end})
					end)
				end
				banner({text = string.upper(plr.DisplayName) .. " TOOK A ROYAL CACHE", kind = "elite"})
				return true
			end})
	end)
	table.insert(self.cacheParts, flare)
end

--------------------------------------------------------------------
--  THE DRAGON
--------------------------------------------------------------------
-- the top of its back at (x, z), unscaled (Combat ▸ Dragon: Chest, Belly, Hips)
local BACK = {
	{c = Vector3.new(0, 1, -5), h = Vector3.new(5, 4.5, 6)},
	{c = Vector3.new(0, 0, 5), h = Vector3.new(5.5, 4.25, 6.5)},
	{c = Vector3.new(0, 0.6, 11.5), h = Vector3.new(4.5, 4, 4.5)},
}
local function backTop(x, z)
	local best = 0
	for _, e in ipairs(BACK) do
		local u = 1 - ((x - e.c.X) / e.h.X) ^ 2 - ((z - e.c.Z) / e.h.Z) ^ 2
		if u > 0 then best = math.max(best, e.c.Y + e.h.Y * math.sqrt(u)) end
	end
	return best
end

-- its way: from out over the sea, across the island near its middle, out over the sea again
function Crownfall:busPath()
	local a = math.random() * math.pi * 2
	local off = math.random() * ISLAND * 0.25
	local b = a + math.pi / 2
	local through = Vector3.new(math.cos(b) * off, 0, math.sin(b) * off)
	local dir = Vector3.new(math.cos(a), 0, math.sin(a))
	local from = through - dir * (ISLAND + BUS_OUT)
	local to = through + dir * (ISLAND + BUS_OUT)
	return Vector3.new(from.X, BUS_ALT, from.Z), Vector3.new(to.X, BUS_ALT, to.Z), dir
end

function Crownfall:launchBus()
	local m = Dragon.build()
	m.Name = "BattleDragon"
	m:ScaleTo(BUS_SCALE)
	local root = m.HumanoidRootPart
	-- seats down its back, two by two between the wings (riders face its head)
	local seats = {}
	for row = 0, 8 do
		for _, sx in ipairs({-1.7, 1.7}) do
			local z = -8 + row * 2.4
			local s = Instance.new("Seat")
			s.Name = "Ride" .. (#seats + 1)
			s.Size = Vector3.new(2, 0.4, 2)
			s.Transparency = 1
			s.CanCollide, s.CanTouch, s.CanQuery, s.Massless = false, false, false, true
			s.CFrame = root.CFrame * CFrame.new(sx * BUS_SCALE, backTop(sx, z) * BUS_SCALE + 0.2, z * BUS_SCALE)
			local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = root, s; w.Parent = s
			s.Parent = m
			table.insert(seats, s)
		end
	end
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false; if p ~= root then p.Massless = true end end
	end
	-- flown by the server, smooth on every screen (physics carries it, as Dragonfall's)
	root.Anchored = false
	local att = Instance.new("Attachment"); att.Name = "Drive"; att.Parent = root
	local ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment; ap.Attachment0 = att; ap.RigidityEnabled = true; ap.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; ao.Attachment0 = att; ao.RigidityEnabled = true; ao.Parent = root
	local from, to, dir = self:busPath()
	local yaw = math.atan2(-dir.X, -dir.Z)
	local cf0 = CFrame.new(from) * CFrame.Angles(0, yaw, 0)
	m:PivotTo(cf0)
	ap.Position = from
	ao.CFrame = cf0.Rotation
	-- (Dragon.client beats its wings)
	m:SetAttribute("DragonState", "sky")
	m:SetAttribute("Fly", true)
	m:SetAttribute("BattleBus", true)
	pcall(function() m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent end)
	local folder = workspace:FindFirstChild("Steeds")
	if not folder then folder = Instance.new("Folder"); folder.Name = "Steeds"; folder.Parent = workspace end
	m.Parent = folder
	pcall(function() root:SetNetworkOwner(nil) end)
	local length = (to - from).Magnitude
	-- (it shakes riders off as it reaches the far shore)
	local shakeAt = (BUS_OUT + ISLAND * 1.85) / length
	local bus = {model = m, root = root, seats = seats, taken = {}, from = from, to = to, dir = dir, yaw = yaw,
		t0 = os.clock(), dur = length / BUS_SPEED, k = 0, ap = ap, ao = ao, shakeAt = shakeAt}
	self.bus = bus
	node:SetAttribute("BusFrom", from)
	node:SetAttribute("BusTo", to)
	for _, s in ipairs(seats) do
		s:GetPropertyChangedSignal("Occupant"):Connect(function()
			local who = bus.taken[s]
			if who and not s.Occupant then
				bus.taken[s] = nil
				if self.riders[who] == s then self:leap(who) end
			end
		end)
	end
	local snd = Instance.new("Sound")
	snd.SoundId = ROAR; snd.Volume = 2.5; snd.PlaybackSpeed = 0.45; snd.RollOffMaxDistance = 900
	snd.Parent = root
	snd:Play()
	bus.conn = RunService.Heartbeat:Connect(function() self:flyBus() end)
end

function Crownfall:flyBus()
	local bus = self.bus
	if not bus then return end
	local t = os.clock() - bus.t0
	local k = t / bus.dur
	bus.k = k
	-- along its way, a slow rise and fall with its wingbeats, a lean in the wind
	local pos = bus.from:Lerp(bus.to, k) + Vector3.new(0, math.sin(t * 1.1) * 2.2 + math.max(0, k - 1) * 120, 0)
	bus.ap.Position = pos
	bus.ao.CFrame = CFrame.Angles(0, bus.yaw, 0) * CFrame.Angles(math.sin(t * 1.1 + 1.2) * 0.025 + math.max(0, k - 1) * 0.5, 0, math.sin(t * 0.33) * 0.05)
	-- (riders are part of it while they sit: the server holds them; and their weapons stay away)
	if math.floor(t * 4) ~= bus.ownTick then
		bus.ownTick = math.floor(t * 4)
		pcall(function() bus.root:SetNetworkOwner(nil) end)
		for plr in pairs(self.riders) do
			local c = plr.Character
			local hum = humOf(c)
			if hum and c:FindFirstChildOfClass("Tool") then hum:UnequipTools() end
		end
	end
	-- the far shore: off you get
	if k >= bus.shakeAt and not bus.shaken then
		bus.shaken = true
		local any = false
		for plr in pairs(self.riders) do
			any = true
			banner({text = "THE DRAGON SHAKES YOU OFF", sub = "STEER AS YOU FALL", kind = "descend"}, plr)
			self:leap(plr)
		end
		if any then
			local snd = Instance.new("Sound")
			snd.SoundId = ROAR; snd.Volume = 2.5; snd.PlaybackSpeed = 0.5; snd.RollOffMaxDistance = 900
			snd.Parent = bus.root
			snd:Play()
		end
	end
	-- and away, up into the clouds
	if k >= 1.35 then self:endBus() end
end

function Crownfall:endBus()
	local bus = self.bus
	if not bus then return end
	self.bus = nil
	if bus.conn then bus.conn:Disconnect() end
	for plr in pairs(self.riders or {}) do self:leap(plr) end
	if bus.model then bus.model:Destroy() end
	node:SetAttribute("BusFrom", nil)
	node:SetAttribute("BusTo", nil)
end

-- up onto the dragon's back (false: it's gone, or full)
function Crownfall:board(plr)
	local bus = self.bus
	if not (bus and bus.model.Parent and bus.k < bus.shakeAt - 0.08) then return false end
	local char = plr.Character
	local hum = humOf(char)
	if not (hum and rootOf(char)) then return false end
	local seat
	for _, s in ipairs(bus.seats) do if not s.Occupant and not bus.taken[s] then seat = s; break end end
	if not seat then return false end
	bus.taken[seat] = plr
	self.riders[plr] = seat
	-- (weapons away while you ride: a hand's grip doesn't hold on a dragon's back, and a blade
	-- let go of falls into the sea)
	hum:UnequipTools()
	char:PivotTo(seat.CFrame * CFrame.new(0, 2.6, 0))
	seat:Sit(hum)
	char:SetAttribute("ViewWant", "Far")
	char:SetAttribute("Riding", true)
	pcall(function() bus.root:SetNetworkOwner(nil) end)
	return true
end

-- out of the sky over a place (the dragon's gone, or no seat)
function Crownfall:skyDrop(plr)
	local char = plr.Character
	local L = self.layout
	local over = (L and #L.drops > 0) and L.drops[math.random(#L.drops)] or Vector3.zero
	local a, d = math.random() * math.pi * 2, math.random(20, 80)
	char:PivotTo(CFrame.new(over.X + math.cos(a) * d, BUS_ALT, over.Z + math.sin(a) * d))
	char:SetAttribute("ViewWant", "Far")
	char:SetAttribute("Diving", workspace:GetServerTimeNow())
	self.divers[plr] = os.clock()
end

-- OFF THE DRAGON: the seat lets go, your body is yours again, and you fall (Skyfall.client steers)
function Crownfall:leap(plr)
	local seat = self.riders[plr]
	if not seat then return end
	self.riders[plr] = nil
	if self.bus then self.bus.taken[seat] = nil end
	local sw = seat:FindFirstChild("SeatWeld")
	if sw then sw:Destroy() end
	local char = plr.Character
	if not alive(char) then return end
	local hum = humOf(char)
	hum.Sit = false
	char:SetAttribute("Riding", nil)
	char:SetAttribute("Diving", workspace:GetServerTimeNow())
	self.divers[plr] = os.clock()
	local r = rootOf(char)
	pcall(function() r:SetNetworkOwner(plr) end)
end

-- ON THE GROUND: a hero's landing (everyone's screen: HeroLand); a beat before you can move
function Crownfall:landed(plr)
	if not self.divers[plr] then return end
	self.divers[plr] = nil
	local char = plr.Character
	if not alive(char) then return end
	char:SetAttribute("Diving", nil)
	char:SetAttribute("HeroLand", workspace:GetServerTimeNow())
	Powers.addMods(char, {speed = 0.05}, 0.8, "HeroLand")
	-- (your first weapon back in your hand as you rise)
	task.delay(1.1, function()
		local hum = humOf(char)
		if not (hum and hum.Health > 0) or char:FindFirstChildOfClass("Tool") then return end
		local bp = plr:FindFirstChildOfClass("Backpack")
		for _, s in ipairs({1, 2}) do
			for _, t in ipairs(bp and bp:GetChildren() or {}) do
				if t:IsA("Tool") and t:GetAttribute("Slot") == s and not t:GetAttribute("TwinHidden") then hum:EquipTool(t); return end
			end
		end
	end)
	task.delay(1.5, function()
		local ff = char:FindFirstChild("DropShield")
		if ff then ff:Destroy() end
	end)
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
	self.runs, self.spawned, self.riders, self.divers = {}, {}, {}, {}
	self.caches, self.cacheParts = 0, {}
	self.startedAt = os.clock()
	self.dropAt = self.startedAt
	self.dropped = true
	self.over = nil
	self.ringC, self.ringR = Vector3.new(0, 0, 0), ISLAND + 30
	self.phase = 1
	self.wall = nil
	self:ringParts()
	self:planNext()
	self:drawRing()
	self:placeChests()
	self:launchBus()
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("ObjKind", "Crownfall")
	self:sendLayout()
	if not self.evConn and event() then
		self.evConn = event().OnServerEvent:Connect(function(plr, kind, a, b)
			if Game.current ~= self or not self.runs then return end
			if kind == "Hello" then
				self:sendLayout(plr)
				if self.runs[plr] then self:sendRun(plr) end
			elseif kind == "Leap" then self:leap(plr)
			elseif kind == "Landed" then self:landed(plr)
			elseif kind == "Inv" and type(a) == "string" then self:inv(plr, a, b)
			elseif kind == "Use" and type(a) == "string" then self:inv(plr, "Use", a)
			elseif kind == "Belt" and type(a) == "number" then
				local r = self.runs[plr]
				local it = r and r.belt[math.floor(a)]
				if it then self:inv(plr, "Use", it.uid) end
			end
		end)
	end
	banner({text = "CROWNFALL", sub = "RIDE THE DRAGON  ·  LEAP OFF WHERE YOU LIKE  ·  LAST ONE STANDING TAKES THE CROWN", kind = "floor"})
end

function Crownfall:stop()
	self:endBus()
	Loot.clear()
	for _, p in ipairs(self.cacheParts or {}) do if p.Parent then p:Destroy() end end
	self.cacheParts = {}
	for _, k in ipairs({"OwnHud", "ObjKind", "ObjLabel", "ObjNote", "RingCentre", "RingRadius", "RingNextCentre", "RingNextRadius"}) do node:SetAttribute(k, nil) end
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("AdvChip", nil)
		local c = p.Character
		if c then
			Loot.setRelics(c, {}); Loot.setArmor(c, nil)
			for _, k in ipairs({"Burning", "Riding", "Diving", "HeroLand"}) do c:SetAttribute(k, nil) end
		end
	end
	self.layout = nil
	self.wall = nil
	self.runs = nil
	self.riders, self.divers = {}, {}
	local e = event()
	if e then e:FireAllClients("Layout", nil); e:FireAllClients("Inv", nil) end
end

-- THE ISLAND'S BOTS (BotFill asks): there before you, with what they'd found; outside the ring,
-- they head in
function Crownfall:botOpts(opts)
	opts.startDelay = 8 + math.random() * 14
	opts.class, opts.power, opts.powerSkin = nil, nil, nil
	local w = Loot.weapon(CLASS, math.random() * 0.6)
	opts.weapon = w and w.weapon or FREE_WEAPON
	local pick = pickWeighted(BOT_ARMOR)
	local a = pick.id and LOOT.ARMOR_BY[pick.id]
	local lo = plainLook()
	if a then
		for _, pc in ipairs(Catalog.setPieces(a.set)) do lo[pc.slot] = pc.id end
		lo.colors = PALETTES[math.random(2, #PALETTES)]
	end
	opts.loadout = lo
	opts.weight = a and a.weight or "Light"
	opts.attrs = opts.attrs or {}
	opts.attrs.CfArmor = a and a.id or nil
	opts.goal = function(b)
		local r = b.hrp
		if not (r and self.ringC) then return nil end
		local d = flat(r.Position - self.ringC).Magnitude
		local inner = math.min(self.ringR, self.nextR or self.ringR)
		if d > inner - 8 then return self.nextC or self.ringC end
		return nil
	end
end

-- a bot that falls drops what it had: a weapon, its armour, maybe a bottle
function Crownfall:onBotDeath(_, model)
	local r = rootOf(model)
	if not (r and self.runs) then return end
	local at = r.Position
	local items = {Loot.roll(nil, CLASS, 0.3, {kind = "weapon"})}
	local aid = model:GetAttribute("CfArmor")
	local a = aid and LOOT.ARMOR_BY[aid]
	if a then table.insert(items, {kind = "armor", uid = uid(), armor = a.id, rarity = a.rarity, name = a.name}) end
	if math.random() < 0.45 then table.insert(items, Loot.roll(nil, CLASS, 0.3, {kind = "potion"})) end
	for i, it in ipairs(items) do self:dropItem(it, at, i, #items) end
end

-- where a bot comes in: one of the places, on the ground (a player is put on the dragon)
function Crownfall:spawnCFrame(plr)
	local L = self.layout
	if not L or #L.drops == 0 then return Game.Mode.spawnCFrame(self, plr) end
	local p = L.drops[math.random(#L.drops)]
	local x, z = p.X + math.random(-10, 10), p.Z + math.random(-10, 10)
	return CFrame.new(x, (L.height and L.height(x, z) or p.Y) + 4, z)
end

function Crownfall:canSpawn(plr)
	if self.spawned and self.spawned[plr] then return false, "No coming back in Crownfall: watch the rest, the next match is yours" end
	if os.clock() > (self.startedAt or 0) + 50 then return false, "The drop has gone: the next match is yours" end
	return true
end

-- the HUD's chip (Adventure.client): your kills this round
function Crownfall:onKill(killerPlr, victimPlr, victimChar)
	Game.Mode.onKill(self, killerPlr, victimPlr, victimChar)
	if killerPlr then killerPlr:SetAttribute("AdvChip", "⚔ " .. tostring(self.kills[killerPlr] or 0)) end
end

-- your one body: the old dagger tagged as yours, up onto the dragon (or out of the sky)
function Crownfall:noteSpawn(plr)
	self.spawned[plr] = true
	plr:SetAttribute("AdvChip", "⚔ " .. tostring(self.kills and self.kills[plr] or 0))
	local char = plr.Character
	local r = self:runOf(plr)
	r.weapons[1] = r.weapons[1] or freeDagger()
	task.defer(function()
		if not alive(char) then return end
		for _, holder in ipairs({char, plr:FindFirstChildOfClass("Backpack")}) do
			for _, t in ipairs(holder and holder:GetChildren() or {}) do
				local it = t:IsA("Tool") and r.weapons[t:GetAttribute("Slot") or 0]
				if it then Loot.tagTool(t, it) end
			end
		end
		-- (no blade touches you till you're down: the spawn's bubble swapped for an unseen one)
		for _, f in ipairs(char:GetChildren()) do if f:IsA("ForceField") then f:Destroy() end end
		local ff = Instance.new("ForceField"); ff.Name = "DropShield"; ff.Visible = false; ff.Parent = char
		if not self:board(plr) then self:skyDrop(plr) end
		self:sendRun(plr)
	end)
	self:sendLayout(plr)
end

function Crownfall:onDeath(victimPlr)
	-- what they found falls where they fell (not the old dagger)
	local r = self.runs and self.runs[victimPlr]
	local char = victimPlr.Character
	local at = rootOf(char) and rootOf(char).Position
	if r and at then
		local list = {}
		for _, it in ipairs(carried(r)) do if not it.free then table.insert(list, it) end end
		for i, it in ipairs(list) do self:dropItem(it, at, i, #list) end
		self.runs[victimPlr] = {weapons = {}, bag = {}, belt = {}}
	end
	if self.riders then self.riders[victimPlr] = nil end
	if self.divers then self.divers[victimPlr] = nil end
	local e = event()
	if e then e:FireClient(victimPlr, "Inv", nil) end
	local left = self:fighters()
	if left > 1 then banner({text = string.format("%d LEFT", left), sub = string.upper(victimPlr.DisplayName) .. " IS OUT", kind = "fight"}) end
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
	-- a dive that's down (its client never said: the ground did) or that never ends
	for plr, t0 in pairs(self.divers) do
		local hum = humOf(plr.Character)
		if not hum or hum.Health <= 0 then self.divers[plr] = nil
		elseif (now - t0 > 2 and hum.FloorMaterial ~= Enum.Material.Air) or now - t0 > DIVE_MAX then self:landed(plr) end
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
			if r and h and h.Health > 0 and not c:GetAttribute("Riding") and not c:GetAttribute("Diving") and flat(r.Position - self.ringC).Magnitude > self.ringR then
				h:TakeDamage(dps)
				c:SetAttribute("Burning", true)
				c:SetAttribute("RingBurnAt", now)
			elseif c:GetAttribute("RingBurnAt") and now - c:GetAttribute("RingBurnAt") > 1.2 then
				c:SetAttribute("Burning", nil); c:SetAttribute("RingBurnAt", nil)
			end
		end
		for _, p in ipairs(Players:GetPlayers()) do if p.Character then burn(p.Character) end end
		local npcs = workspace:FindFirstChild("NPCs")
		for _, m in ipairs(npcs and npcs:GetChildren() or {}) do if m:IsA("Model") then burn(m) end end
	end
	-- the screen
	local n = self:fighters()
	node:SetAttribute("ObjLabel", string.format("CROWNFALL  ·  %d LEFT", n))
	local note
	if self.bus and next(self.riders) then note = "ON THE DRAGON'S BACK"
	elseif not RING[self.phase] then note = "THE LAST RING"
	elseif self.shrinking then note = "THE RING IS CLOSING"
	else note = string.format("THE RING CLOSES IN %d:%02d", math.floor(math.max(0, self.waitUntil - now) / 60), math.floor(math.max(0, self.waitUntil - now)) % 60) end
	node:SetAttribute("ObjNote", note)
	node:SetAttribute("Objective", self:objective())
end

function Crownfall:isOver()
	if os.clock() < (self.startedAt or 0) + 12 then return nil end
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
	local n = self:fighters()
	node:SetAttribute("Winner", "")
	return string.format("THE CLOCK RAN OUT  ·  %d STILL STANDING", n)
end
function Crownfall:objective() return "CROWNFALL  ·  THE LAST ONE STANDING TAKES THE CROWN" end

return Crownfall
