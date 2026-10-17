--[[ DEADVAULT — go in with your party, loot it, get out alive (GameConfig.MODES.Deadvault), after
     Dark and Darker. A great dungeon built fresh every raid (Game ▸ Dungeon, opts.raid: thirty
     rooms that were something once — great halls, crypts, cells, libraries, armouries, chapels,
     caverns, treasure vaults, a lair), dark between its torches.

     THE DARK IS QUIET until you make it loud. Its monsters (Combat ▸ Monsters) keep to their
     rooms, some asleep, a few walking the halls in pairs; they come for you when they SEE or
     HEAR you (Combat ▸ Perception: a run is loud, a fight louder, a crouch is quiet), shout for
     their friends, and hunt where they last saw you. Many rooms hold nothing but what's worth
     taking. The lair holds the theme's lord and its hoard.

     EVERYTHING IS IN SOMETHING (Game ▸ Containers): crates, barrels, sacks, urns, weapon racks,
     armour stands, shelves, sarcophagi, the remains of those who came before, chests. Search
     one and its things show in a window: take what you want into your BAG (BAG_MAX), or wear it.
     VALUABLES (cups, rings, idols, gems) are worth gold to the Treasurer, if you get them out.
     Your inventory (I): what you wear, what you carry; equip, drink, drop.

     YOU GO IN with your KIT from the vault (Game ▸ Vault: what you chose to risk), or the free
     one (your class's plain weapons and a draught: never lost, never sold). ONE LIFE: fall and
     everything you carry lies in your pack where you fell, for whoever finds it. A PARTY goes in
     together, from one haven, and fights side by side (their blows barely touch each other).

     THE WAYS OUT: the ESCAPE STAIRS (two, on the map from the start) open after STAIRS_AT;
     BLUE PORTALS open in waves (PORTALS) about the dungeon. Hold your pickup key at one: out, and
     everything you carry and your gold go into your vault. Still inside when it COLLAPSES (the
     round's end)? Lost.

     TRAPS in a third of its corridors (Game ▸ Traps: spike grates, swinging blades, dart plates,
     fire grates); none by a haven.

     NOT EVERY DEAD RESTS: search a sarcophagus and now and then (WAKE_CHANCE) the lid is thrown off
     and its dead climbs out at you (Deadvault:waken, for Game ▸ Containers).

     Pay: Marks for getting out (`vault_extract`, once a raid, under the daily cap) and a
     monster's kill by its rank; the vault gold is the raids' own coin. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local Loot = require(script.Parent.Parent:WaitForChild("Loot"))
local Traps = require(script.Parent.Parent:WaitForChild("Traps"))
local Vault = require(script.Parent.Parent:WaitForChild("Vault"))
local Containers = require(script.Parent.Parent:WaitForChild("Containers"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Monsters = require(Combat:WaitForChild("Monsters"))
local Powers = require(Combat:WaitForChild("Powers"))
local Perception = require(Combat:WaitForChild("Perception"))
local Perks = require(script.Parent.Parent:WaitForChild("Perks"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local MapLoader = Game.MapLoader
local node = Game.node

local BAG_MAX = 20
local BELT = 4            -- draughts on your belt: keys 3–6 (RaidInventory.client)
local RELICS = 3
local STAIRS_AT = 2 * 60
local PORTALS = {{at = 5 * 60, n = 2}, {at = 9 * 60, n = 2}, {at = 12 * 60, n = 3}}
local GOLD_OF = {3, 8, 20, 70}
local KILL_RANK = {"Squire", "Knight", "Champion", "Champion"}

local Deadvault = setmetatable({}, {__index = Game.Mode})
Deadvault.__index = Deadvault
function Deadvault.new(def, id) return setmetatable(Game.Mode.new(def, id), Deadvault) end

local function humOf(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function rootOf(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function alive(c) local h = humOf(c); return h ~= nil and h.Health > 0 end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function banner(t, plr) local e = event(); if e then if plr then e:FireClient(plr, "Banner", t) else e:FireAllClients("Banner", t) end end end
local function uid() return HttpService:GenerateGUID(false):sub(1, 8) end
local function clock(t) t = math.max(0, math.floor(t)); return string.format("%d:%02d", t // 60, t % 60) end

--------------------------------------------------------------------
--  THE DUNGEON
--------------------------------------------------------------------
function Deadvault:buildMap(theme)
	self.theme = Catalog.DUNGEONS[theme] and theme or "BoneCrypt"
	local name, layout = Dungeon.build(self.theme, {rooms = 30, grid = {7, 6}, final = "boss", exits = 2, havens = 3, loops = 6, raid = true,
		special = {treasure = 3, shrine = 1, fountain = 1, elite = 3}})
	self.layout = layout
	self.havens = {}
	for _, r in ipairs(layout.rooms) do if r.kind == "start" then table.insert(self.havens, r) end end
	Dungeon.sweep(name)
	return name
end

function Deadvault:sendLayout(plr)
	local L = self.layout
	if not L then return end
	local rooms = {}
	for _, r in ipairs(L.rooms) do
		local doors = {}
		for d, nid in pairs(r.doors) do doors[d] = nid end
		local kind = r.kind
		if r.portal then kind = "exit" end
		rooms[r.id] = {id = r.id, cx = r.cx, cz = r.cz, w = r.w, d = r.d, kind = kind, state = "clear", doors = doors,
			known = r.kind == "exit" or r.portal ~= nil, name = r.arch and Dungeon.ARCH_NAMES[r.arch] or nil,
			open = (r.kind == "exit" and self.stairsOpen) or r.portal == "open"}
	end
	local data = {rooms = rooms, floor = 1, theme = self.theme, themeName = "DEADVAULT  ·  " .. string.upper(Catalog.DUNGEONS[self.theme].name)}
	local e = event()
	if e then if plr then e:FireClient(plr, "Layout", data) else e:FireAllClients("Layout", data) end end
end

--------------------------------------------------------------------
--  ITS MONSTERS: in their rooms (some asleep), pairs on patrol, the lord in its lair
--------------------------------------------------------------------
function Deadvault:mobOpts(extra)
	local players = math.max(1, #Players:GetPlayers())
	local o = {team = "B", startDelay = 1, corpseTime = 600, hpMult = 1 + (players - 1) * 0.04, dealt = 0.9,
		engage = self.senses.engage, goal = self.senses.goal,
		onSpawn = function(mob)
			self.mobs[mob] = true
			local how = mob.over and mob.over.sense
			if how and mob.bot then self.senses:add(mob.bot, how) end
		end,
		onDeath = function(mob, killer)
			self.mobs[mob] = nil
			if mob.bot then self.senses:remove(mob.bot) end
			local r = mob.model and rootOf(mob.model)
			local at = r and r.Position or Vector3.zero
			local tier = mob.def.tier or 1
			-- WHAT IT CARRIED stays on its body: search the corpse (Game ▸ Containers), fitted to
			-- whoever felled it (an Archer's kill, an Archer's find)
			local kc = typeof(killer) == "Instance" and killer:IsA("Player") and killer.Character or nil
			local classId = (kc and kc:GetAttribute("Class")) or "Knight"
			local items = {Loot.gold((GOLD_OF[tier] or 3) * (0.7 + math.random() * 0.6))}
			if mob.boss then
				for _ = 1, 3 do table.insert(items, Loot.roll("boss", classId, 2.5)) end
				table.insert(items, Loot.treasure(2.5, "Epic"))
				banner({text = string.upper(mob.def.name or "THE LORD") .. " IS SLAIN", sub = "LOOT ITS BODY  ·  ITS HOARD IS UNGUARDED", kind = "victory"})
			elseif tier >= 3 or mob.elite then
				table.insert(items, Loot.roll("elite", classId, 1.5))
				if math.random() < 0.5 then table.insert(items, Loot.treasure(1)) end
			else
				if math.random() < 0.3 then table.insert(items, Loot.treasure(0.3)) end
				if math.random() < 0.12 then table.insert(items, Loot.roll("vault", classId, 0.3, {skip = {gold = true}})) end
			end
			if math.random() < 0.18 then table.insert(items, Loot.potion(0)) end
			local ground = workspace:Raycast(at + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), self.groundParams)
			local y = ground and ground.Position.Y or (at.Y - 3)
			self.boxes:add("corpse", CFrame.new(at.X, y, at.Z), {items = items, name = mob.def.name or "Body"})
			if killer and _G.RoundBump then _G.RoundBump(killer, "kill_" .. (KILL_RANK[tier] or "Squire")) end
		end}
	for k, v in pairs(extra or {}) do o[k] = v end
	return o
end

function Deadvault:spawnMob(id, at, how, extra)
	local over = {at = at, elite = extra and extra.elite or nil, sense = how}
	local mob = Monsters.spawn(id, self.opts, over)
	if mob then
		self.mobs[mob] = true
		if mob.bot and not self.senses.bots[mob.bot] then self.senses:add(mob.bot, how) end
	end
	return mob
end

-- NOT EVERY DEAD RESTS (Game ▸ Containers, the first look into a sarcophagus): now and then its
-- dead climbs out of it, on the far side from whoever opened it, already coming for them (the
-- Rising attribute: a bigger cloud of grave-dust, StarterPlayerScripts ▸ DungeonMood). Its own
-- kind where the dungeon's are dead things; else a skeleton.
Deadvault.WAKE_CHANCE = 0.3
local WAKERS = {BoneCrypt = {"Skeleton", "Ghoul", "SkeletonKnight"}, CrimsonManor = {"Vampire", "Thrall"}, FrozenDepths = {"FrostSkeleton", "IceWraith"}}
function Deadvault:waken(box, char)
	if math.random() >= Deadvault.WAKE_CHANCE then return false end
	local pool = WAKERS[self.theme] or {"Skeleton", "Ghoul"}
	local id = pool[math.random(#pool)]
	if not Monsters.def(id) then return false end
	local r = rootOf(char)
	local side = box.cf.RightVector
	if r and (r.Position - box.pos):Dot(side) > 0 then side = -side end
	local at = box.pos + side * 3.4 + Vector3.new(0, 3, 0)
	local plr = Players:GetPlayerFromCharacter(char)
	if plr then banner({text = "IT WAKES", sub = "NOT EVERY DEAD RESTS", kind = "fight"}, plr) end
	task.delay(0.3, function()
		local look = r and Vector3.new(r.Position.X, at.Y, r.Position.Z) or at + box.cf.LookVector
		local mob = self:spawnMob(id, CFrame.new(at, look), {home = box.pos})
		if mob and mob.model then
			mob.model:SetAttribute("Rising", true)
			-- (it knows who woke it)
			if char.Parent then Perception.noise(at, 12, char) end
		end
	end)
	return true
end

-- a walk of a few rooms, there and back (corridor to corridor)
local function route(L, from, rng)
	local path = {from}
	local cur = from
	for _ = 1, 3 do
		local opts = {}
		for _, nid in pairs(cur.doors) do
			local o = L.rooms[nid]
			if o and o.kind ~= "start" and o.kind ~= "exit" and o.kind ~= "boss" and not table.find(path, o) then table.insert(opts, o) end
		end
		if #opts == 0 then break end
		cur = opts[rng:NextInteger(1, #opts)]
		table.insert(path, cur)
	end
	local pts = {}
	for _, r in ipairs(path) do table.insert(pts, Vector3.new(r.cx, 3, r.cz)) end
	for i = #path - 1, 2, -1 do table.insert(pts, Vector3.new(path[i].cx, 3, path[i].cz)) end
	return pts
end

function Deadvault:populate()
	local th = Catalog.DUNGEONS[self.theme]
	local L = self.layout
	local rng = Random.new()
	self.opts = self:mobOpts()
	local function pick(pool) return pool[rng:NextInteger(1, #pool)] end
	for _, room in ipairs(L.rooms) do
		local home = Vector3.new(room.cx, 3, room.cz)
		local face = function(spot) return CFrame.new(spot, Vector3.new(room.cx + rng:NextNumber(-6, 6), spot.Y, room.cz + rng:NextNumber(-6, 6))) end
		local function spot(i) return room.spots[((i - 1) % #room.spots) + 1] end
		if room.kind == "boss" then
			-- the lord of the place, in its lair: it fights whoever comes in
			local bounds = {centre = home, hw = room.w / 2, hd = room.d / 2}
			local bossOpts = self:mobOpts({hpMult = 0.85 * (1 + (math.max(1, #Players:GetPlayers()) - 1) * 0.2), skillCap = "Knight",
				arena = {centre = Vector3.new(room.cx, 0, room.cz), radius = math.max(room.w, room.d) / 2 + 4}, bounds = bounds,
				engage = function(_, foe)
					local fr = rootOf(foe)
					return fr ~= nil and math.abs(fr.Position.X - room.cx) < room.w / 2 + 2 and math.abs(fr.Position.Z - room.cz) < room.d / 2 + 2
				end, goal = function(b) if b.hrp and flat(b.hrp.Position - home).Magnitude > 6 then return home end; return nil end})
			local boss = Monsters.spawn(th.boss, bossOpts, {at = CFrame.new(room.feature + Vector3.new(0, 3, 0))})
			if boss then self.mobs[boss] = true; boss.model:SetAttribute("BossName", th.bossName) end
			for i = 1, 2 do self:spawnMob(pick(th.monsters.common), face(spot(i * 3)), {home = home}) end
		elseif room.kind ~= "start" and room.kind ~= "exit" then
			local list = {}
			if room.kind == "elite" then
				table.insert(list, {id = pick(th.monsters.elite), elite = true})
				table.insert(list, {id = pick(th.monsters.common)})
				if rng:NextNumber() < 0.5 then table.insert(list, {id = pick(th.monsters.ranged)}) end
			elseif room.kind == "treasure" then
				for _ = 1, rng:NextInteger(2, 3) do table.insert(list, {id = pick(rng:NextNumber() < 0.3 and th.monsters.ranged or th.monsters.common), elite = rng:NextNumber() < 0.15}) end
			elseif room.kind == "combat" then
				-- many rooms are empty: the dark is quiet till it isn't
				local x = rng:NextNumber()
				local n = (x < 0.42 and 0) or (x < 0.8 and 1) or 2
				for _ = 1, n do table.insert(list, {id = pick(rng:NextNumber() < 0.3 and th.monsters.ranged or th.monsters.common), elite = rng:NextNumber() < 0.05}) end
			end
			local sleepy = rng:NextNumber() < 0.35
			for i, e in ipairs(list) do
				self:spawnMob(e.id, face(spot(i * 2)), {home = home, asleep = sleepy and not e.elite}, {elite = e.elite})
			end
		end
		-- its containers
		for _, k in ipairs(room.containers or {}) do
			local luck = (room.kind == "treasure" and 0.8) or (room.kind == "elite" and 0.5) or (room.kind == "boss" and 1) or 0
			self.boxes:add(k.kind, k.cf, {luck = luck})
		end
	end
	-- patrols: pairs walking the halls
	local starts = {}
	for _, r in ipairs(L.rooms) do if r.kind == "combat" then table.insert(starts, r) end end
	local players = math.max(1, #Players:GetPlayers())
	for _ = 1, math.min(#starts, 3 + math.floor(players / 3)) do
		local r = table.remove(starts, rng:NextInteger(1, #starts))
		local pts = route(L, r, rng)
		if #pts >= 3 then
			for k = 1, 2 do
				local at = Vector3.new(r.cx + (k == 1 and -3 or 3), 3, r.cz)
				self:spawnMob(pick(k == 2 and rng:NextNumber() < 0.4 and th.monsters.ranged or th.monsters.common), CFrame.new(at), {patrol = pts, sight = 52})
			end
		end
	end
end

-- the kind rooms: a fountain (whole again, once), a shrine (a blessing, once)
function Deadvault:dressRooms()
	for _, room in ipairs(self.layout.rooms) do
		if room.kind == "fountain" or room.kind == "shrine" then
			local p = Instance.new("Part")
			p.Name = room.kind == "fountain" and "FountainPrompt" or "ShrinePrompt"
			p.Anchored, p.CanCollide, p.Transparency = true, false, 1
			p.Size = Vector3.new(2, 2, 2); p.Position = room.feature + Vector3.new(0, 4, 0)
			p.Parent = MapLoader.current
			local pr = Instance.new("ProximityPrompt")
			pr.ActionText = room.kind == "fountain" and "Drink" or "Pray"; pr.ObjectText = room.kind == "fountain" and "Fountain" or "Shrine"
			pr.HoldDuration = 1; pr.MaxActivationDistance = 12; pr.RequiresLineOfSight = false
			pr:SetAttribute("PickupKey", true)
			pr.Parent = p
			local used = {}
			pr.Triggered:Connect(function(plr)
				local c = plr.Character
				if used[plr] or not alive(c) then return end
				used[plr] = true
				p:SetAttribute("OpenedBy_" .. plr.UserId, true)
				local h = humOf(c)
				if room.kind == "fountain" then
					h.Health = h.MaxHealth
					for _, a in ipairs({"Burning", "Poisoned", "Frosted"}) do c:SetAttribute(a, nil) end
					Loot.sparkle(room.feature + Vector3.new(0, 3, 0), Color3.fromRGB(120, 255, 210))
					banner({text = "REFRESHED", sub = "WHOLE AGAIN", kind = "clear"}, plr)
				else
					h.Health = math.min(h.MaxHealth, h.Health + h.MaxHealth * 0.3)
					Powers.addMods(c, {dealt = 1.15, taken = 0.88}, 120, "Blessed")
					Loot.sparkle(room.feature + Vector3.new(0, 3, 0), Color3.fromRGB(255, 226, 130))
					banner({text = "BLESSED", sub = "STRONGER AND HARDER TO HURT, FOR TWO MINUTES", kind = "clear"}, plr)
				end
			end)
		end
	end
end

--------------------------------------------------------------------
--  THE WAYS OUT
--------------------------------------------------------------------
local function extractPrompt(self, part, text, hold)
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "ExtractPrompt"
	pr.ActionText = "Extract"; pr.ObjectText = text
	pr.HoldDuration = hold; pr.MaxActivationDistance = 11; pr.RequiresLineOfSight = true
	pr:SetAttribute("PickupKey", true)
	pr.Enabled = false
	pr.Parent = part
	pr.Triggered:Connect(function(plr) self:extract(plr) end)
	return pr
end

-- the escape stairs (built shut: their prompts wake at STAIRS_AT)
function Deadvault:stairs()
	self.exitParts = {}
	for _, room in ipairs(self.layout.rooms) do
		if room.kind == "exit" and room.escape then
			local p = Instance.new("Part")
			p.Name = "ExitPortal"
			p.Anchored, p.CanCollide, p.CanQuery, p.Transparency = true, false, false, 1
			p.Size = Vector3.new(4, 6, 4); p.Position = room.escape + Vector3.new(0, 3, 0)
			p:SetAttribute("Escape", true)
			local props = MapLoader.current and MapLoader.current:FindFirstChild("Props")
			p.Parent = props or MapLoader.current
			room.exitPrompt = extractPrompt(self, p, "The escape stairs", 4)
			table.insert(self.exitParts, p)
		end
	end
end
function Deadvault:openStairs()
	self.stairsOpen = true
	for _, room in ipairs(self.layout.rooms) do if room.exitPrompt then room.exitPrompt.Enabled = true end end
	self:sendLayout()
	banner({text = "THE STAIRS ARE OPEN", sub = "THE ESCAPE STAIRS ARE ON YOUR MAP", kind = "descend"})
end

-- a blue portal: an oval of light on the floor of a room
function Deadvault:portal(room)
	local m = MapLoader.current
	local props = m and m:FindFirstChild("Props")
	local spot = room.spots[math.random(#room.spots)]
	local base = CFrame.lookAt(Vector3.new(spot.X, 0, spot.Z), Vector3.new(room.cx, 0, room.cz))
	local f = Instance.new("Model")
	f.Name = "PortalModel"
	local glow = Color3.fromRGB(90, 160, 255)
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		local seg = Instance.new("Part")
		seg.Anchored, seg.CanCollide, seg.CanQuery = true, false, false
		seg.Material, seg.Color = Enum.Material.Neon, glow
		seg.Size = Vector3.new(0.5, 1.4, 0.5)
		seg.CFrame = base * CFrame.new(math.cos(a) * 3.2, 5 + math.sin(a) * 4.6, 0) * CFrame.Angles(0, 0, a)
		seg.Parent = f
	end
	-- (its face: an oval of blue light inside the ring; the guides look for it in Props)
	local core = Instance.new("Part")
	core.Name = "ExitPortal"
	core.Anchored, core.CanCollide, core.CanQuery = true, false, false
	core.Material, core.Color, core.Transparency = Enum.Material.Neon, Color3.fromRGB(60, 110, 230), 0.45
	core.Size = Vector3.new(6.2, 9, 0.3)
	core.CFrame = base * CFrame.new(0, 5, 0)
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = core
	core.Parent = props or m
	local l = Instance.new("PointLight"); l.Color = glow; l.Range = 28; l.Brightness = 2.4; l.Parent = core
	local pe = Instance.new("ParticleEmitter"); pe.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255)); pe.LightEmission = 1
	pe.Rate = 24; pe.Speed = NumberRange.new(0.5, 2); pe.Lifetime = NumberRange.new(1, 2); pe.Size = NumberSequence.new(0.35, 0)
	pe.SpreadAngle = Vector2.new(180, 180); pe.Parent = core
	local s = Instance.new("Sound"); s.SoundId = "rbxasset://sounds/electronicpingshort.wav"; s.Volume = 0.8; s.PlaybackSpeed = 0.5
	s.RollOffMaxDistance = 180; s.Parent = core; s:Play()
	f.Parent = props or m
	local pr = extractPrompt(self, core, "A blue portal", 3)
	pr.Enabled = true
	room.portal = "open"
	Perception.noise(core.Position, 40)
	return core
end
function Deadvault:openPortals(n)
	local L = self.layout
	local cands = {}
	for _, r in ipairs(L.rooms) do
		if not r.portal and r.kind ~= "start" and r.kind ~= "exit" and r.kind ~= "boss" then table.insert(cands, r) end
	end
	-- spread apart, away from where portals already are
	local opened = 0
	for _ = 1, n do
		local best, bestS
		for _, r in ipairs(cands) do
			if not r.portal then
				local s = math.random() * 2
				for _, o in ipairs(L.rooms) do if o.portal or o.kind == "exit" then s += math.min(6, math.abs(o.gx - r.gx) + math.abs(o.gy - r.gy)) end end
				if not bestS or s > bestS then best, bestS = r, s end
			end
		end
		if best then self:portal(best); opened += 1 end
	end
	self:sendLayout()
	if opened > 0 then banner({text = opened == 1 and "A PORTAL OPENS" or (opened .. " PORTALS OPEN"), sub = "BLUE LIGHT ON YOUR MAP: A WAY OUT", kind = "descend"}) end
end

--------------------------------------------------------------------
--  A RAIDER: what they wear, what they carry
--------------------------------------------------------------------
function Deadvault:runOf(plr)
	local r = self.runs[plr]
	if not r then r = {weapons = {}, armor = nil, relics = {}, bag = {}, belt = {}, gold = 0, power = nil}; self.runs[plr] = r end
	r.belt = r.belt or {}
	return r
end
local function relicIds(r) local out = {}; for _, it in ipairs(r.relics) do table.insert(out, it.relic) end; return out end
local function carried(r)
	local all = {}
	for _, k in ipairs({1, 2}) do if r.weapons[k] then table.insert(all, r.weapons[k]) end end
	if r.armor then table.insert(all, r.armor) end
	if r.power then table.insert(all, r.power) end
	for _, it in ipairs(r.relics) do table.insert(all, it) end
	for _, it in ipairs(r.belt or {}) do table.insert(all, it) end
	for _, it in ipairs(r.bag) do table.insert(all, it) end
	return all
end

-- the inventory screen's picture of you, and the relic bar's
function Deadvault:sendRun(plr)
	local r = self:runOf(plr)
	local function card(it, slot)
		local c = Loot.card(it)
		c.slot, c.value, c.free = slot, it.free and 0 or Vault.value(it), it.free
		return c
	end
	local equip = {}
	if r.weapons[1] then equip.weapon1 = card(r.weapons[1], "weapon1") end
	if r.weapons[2] then equip.weapon2 = card(r.weapons[2], "weapon2") end
	if r.armor then equip.armor = card(r.armor, "armor") end
	if r.power then equip.power = card(r.power, "power") end
	for i, it in ipairs(r.relics) do equip["relic" .. i] = card(it, "relic" .. i) end
	local bag, belt, worth = {}, {}, 0
	for _, it in ipairs(r.bag) do table.insert(bag, card(it, "bag")) end
	for i, it in ipairs(r.belt) do table.insert(belt, card(it, "belt" .. i)) end
	for _, it in ipairs(carried(r)) do if not it.free then worth += Vault.value(it) end end
	local e = event()
	if e then
		e:FireClient(plr, "Inv", {equip = equip, bag = bag, belt = belt, beltMax = BELT, gold = r.gold, max = r.bagMax or BAG_MAX, worth = worth + r.gold})
		-- (the relic bar: what you wear)
		local bar = {}
		for _, it in ipairs(r.relics) do local c = Loot.card(it); table.insert(bar, {uid = it.uid, name = it.name, glyph = c.glyph, rarity = it.rarity, text = "worn · " .. table.concat(c.lines or {}, " · ")}) end
		e:FireClient(plr, "Run", {gold = r.gold, relics = bar, kind = "bag"})
	end
	plr:SetAttribute("AdvChip", string.format("💰 %d  ·  BAG %d/%d", r.gold, #r.bag, r.bagMax or BAG_MAX))
end

-- THE FREE KIT: your class's plain weapons and a draught (never lost, never sold)
local function freeWeapon(id, slot)
	local w = Catalog.WEAPON[id]
	if not w then return nil end
	return {kind = "weapon", uid = uid(), weapon = id, rarity = "Common", name = "Plain " .. (w.name or id), power = 0, affixes = {}, slot = slot, free = true}
end
function Deadvault:adjustLoadout(plr, lo, classId)
	local r = self:runOf(plr)
	if not r.kitTaken then
		r.kitTaken = true
		local kit = Vault.takeKit(plr)
		if kit.weapon1 then r.weapons[1] = kit.weapon1; kit.weapon1.slot = 1 end
		if kit.weapon2 then r.weapons[2] = kit.weapon2; kit.weapon2.slot = 2 end
		r.armor = kit.armor
		for _, it in ipairs(kit.relics or {}) do if #r.relics < RELICS then table.insert(r.relics, it) else table.insert(r.bag, it) end end
		for _, it in ipairs(kit.potions or {}) do if #r.belt < BELT then table.insert(r.belt, it) else table.insert(r.bag, it) end end
		local cls = GameConfig.CLASSES[classId]
		if not r.weapons[1] and cls then r.weapons[1] = freeWeapon(cls.primary, 1) end
		if not r.weapons[2] and cls and cls.secondary and cls.secondary ~= (r.weapons[1] and r.weapons[1].weapon) then r.weapons[2] = freeWeapon(cls.secondary, 2) end
		if #r.belt == 0 then table.insert(r.belt, {kind = "potion", uid = uid(), potion = "Healing", rarity = "Common", name = "Healing Draught", free = true}) end
	end
	local w1, w2 = r.weapons[1], r.weapons[2]
	lo.weapon, lo.weaponSkin = w1 and w1.weapon or nil, w1 and w1.skin or nil
	lo.secondary, lo.secondarySkin = w2 and w2.weapon or nil, w2 and w2.skin or nil
	if lo.secondary == lo.weapon then lo.secondary, lo.secondarySkin = nil, nil end
	lo.shield, lo.shieldSkin = nil, nil
	-- (your class's own power goes in with you; a tome found inside takes its place)
	r.classPower = lo.power
	if r.power then lo.power = r.power.power; lo.thirdKind, lo.thirdId = "power", r.power.power end
	lo.throwable = nil
end

local function partyKey(plr)
	local p = plr:GetAttribute("Party")
	return p and ("P" .. tostring(p)) or nil
end

function Deadvault:noteSpawn(plr)
	self.entered[plr] = true
	local char = plr.Character
	local r = self:runOf(plr)
	task.defer(function()
		if not char then return end
		-- a party fights side by side (CombatServer.friendlyMult: their blows barely touch)
		char:SetAttribute("Team", partyKey(plr))
		-- your class's perks (the lobby's CLASS tab)
		local pk = Perks.apply(plr, char, char:GetAttribute("Class") or Profile.get(plr).active)
		r.bagMax = BAG_MAX + (pk.bag or 0)
		for _, holder in ipairs({char, plr:FindFirstChildOfClass("Backpack")}) do
			for _, t in ipairs(holder and holder:GetChildren() or {}) do
				local it = t:IsA("Tool") and r.weapons[t:GetAttribute("Slot") or 0]
				if it and (t.Name == it.weapon or t:GetAttribute("Twin") == it.weapon) then Loot.tagTool(t, it) end
			end
		end
		if r.armor then Loot.setArmor(char, r.armor.armor) end
		Loot.setRelics(char, relicIds(r))
		self:sendRun(plr)
	end)
	self:sendLayout(plr)
end

local function bagFull(self, plr, quiet)
	if not quiet then banner({text = "YOUR BAG IS FULL", sub = "DROP SOMETHING (I) TO MAKE ROOM", kind = "fight"}, plr) end
	return false
end

-- something taken (off the floor, out of a container): worn if there's room on you, else bagged
function Deadvault:take(plr, item, at, quiet)
	local char = plr.Character
	if not alive(char) then return false end
	local r = self:runOf(plr)
	local function toBag(it)
		if #r.bag >= (r.bagMax or BAG_MAX) then return false end
		table.insert(r.bag, it)
		return true
	end
	if item.kind == "gold" then
		r.gold += item.gold
	elseif item.kind == "weapon" and (not r.weapons[1] or not r.weapons[2]) then
		local slot = not r.weapons[1] and 1 or 2
		item.slot = slot
		Loot.giveWeapon(plr, item)
		r.weapons[item.slot or slot] = item
	elseif item.kind == "armor" and not r.armor then
		r.armor = item
		Loot.setArmor(char, item.armor)
	elseif item.kind == "relic" and #r.relics < RELICS then
		table.insert(r.relics, item)
		Loot.setRelics(char, relicIds(r))
	elseif item.kind == "tome" and not r.power then
		r.power = item
		Powers.equip(char, plr, {power = item.power})
	elseif item.kind == "potion" and #r.belt < BELT then
		table.insert(r.belt, item)
	elseif not toBag(item) then
		return bagFull(self, plr, quiet)
	end
	self:sendRun(plr)
	return true
end

function Deadvault:dropItem(item, pos)
	if not item then return end
	Loot.drop(item, pos - Vector3.new(0, 2.5, 0), {life = 900, los = true, onTake = function(plr, it) return self:take(plr, it, pos) end})
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

-- THE INVENTORY'S ASKS (AdventureEvent "Inv", what, a): equip from the bag, take off into it, drink,
-- drop at your feet
function Deadvault:inv(plr, what, a)
	local r = self.runs[plr]
	local char = plr.Character
	if not (r and alive(char)) or self.out[plr] or type(a) ~= "string" then return end
	if what == "Equip" then
		local i, it = findIn(r.bag, a)
		if not it then return end
		if it.kind == "weapon" then
			table.remove(r.bag, i)
			-- (a free hand first; else in place of the one you hold, which goes into the bag)
			local slot = not r.weapons[1] and 1 or (not r.weapons[2] and 2 or nil)
			if slot then
				it.slot = slot
				Loot.giveWeapon(plr, it)
				r.weapons[it.slot or slot] = it
			else
				local _, old = Loot.giveWeapon(plr, it)
				local oldItem = r.weapons[it.slot]
				r.weapons[it.slot] = it
				table.insert(r.bag, oldItem or old)
			end
		elseif it.kind == "armor" then
			table.remove(r.bag, i)
			if r.armor then table.insert(r.bag, r.armor) end
			r.armor = it
			Loot.setArmor(char, it.armor)
		elseif it.kind == "relic" then
			if #r.relics >= RELICS then banner({text = "THREE RELICS AT MOST", sub = "TAKE ONE OFF FIRST", kind = "fight"}, plr); return end
			table.remove(r.bag, i)
			table.insert(r.relics, it)
			Loot.setRelics(char, relicIds(r))
		elseif it.kind == "tome" then
			table.remove(r.bag, i)
			if r.power then table.insert(r.bag, r.power) end
			r.power = it
			Powers.equip(char, plr, {power = it.power})
		elseif it.kind == "potion" then
			-- (onto your belt, if there's room on it; else drunk)
			if #r.belt < BELT then table.remove(r.bag, i); table.insert(r.belt, it)
			else return self:inv(plr, "Use", a) end
		end
	elseif what == "Unequip" then
		if #r.bag >= (r.bagMax or BAG_MAX) then bagFull(self, plr); return end
		local bn = tonumber(a:match("^belt(%d)$") or "")
		if bn and r.belt[bn] then table.insert(r.bag, table.remove(r.belt, bn)); self:sendRun(plr); return end
		if a == "weapon1" or a == "weapon2" then
			local slot = a == "weapon1" and 1 or 2
			local it = r.weapons[slot]
			if not it then return end
			removeTools(plr, slot)
			r.weapons[slot] = nil
			table.insert(r.bag, it)
		elseif a == "armor" and r.armor then
			table.insert(r.bag, r.armor); r.armor = nil
			Loot.setArmor(char, nil)
		elseif a == "power" and r.power then
			table.insert(r.bag, r.power); r.power = nil
			Powers.equip(char, plr, {power = r.classPower})
		else
			local n = tonumber(a:match("^relic(%d)$") or "")
			if n and r.relics[n] then
				table.insert(r.bag, table.remove(r.relics, n))
				Loot.setRelics(char, relicIds(r))
			end
		end
	elseif what == "Use" then
		-- (a draught: from your belt or your bag; a moment to drink it, slowed)
		local list = r.bag
		local i, it = findIn(r.belt, a)
		if it then list = r.belt else i, it = findIn(r.bag, a) end
		if it and it.kind == "potion" and Loot.drinkSlow(char, it.potion) then
			table.remove(list, i)
		end
	elseif what == "Drop" then
		local here = rootOf(char).Position + rootOf(char).CFrame.LookVector * 3
		local i, it = findIn(r.bag, a)
		local bi, bt = findIn(r.belt, a)
		if it then
			table.remove(r.bag, i)
			self:dropItem(it, here)
		elseif bt then
			table.remove(r.belt, bi)
			self:dropItem(bt, here)
		else
			-- (something worn: off, and down)
			for _, k in ipairs({"weapon1", "weapon2", "armor", "power", "relic1", "relic2", "relic3"}) do
				local worn = (k == "weapon1" and r.weapons[1]) or (k == "weapon2" and r.weapons[2]) or (k == "armor" and r.armor) or (k == "power" and r.power) or r.relics[tonumber(k:match("%d") or "") or 0]
				if worn and worn.uid == a then
					if k == "weapon1" or k == "weapon2" then removeTools(plr, k == "weapon1" and 1 or 2); r.weapons[k == "weapon1" and 1 or 2] = nil
					elseif k == "armor" then r.armor = nil; Loot.setArmor(char, nil)
					elseif k == "power" then r.power = nil; Powers.equip(char, plr, {power = r.classPower})
					else table.remove(r.relics, tonumber(k:match("%d"))); Loot.setRelics(char, relicIds(r)) end
					self:dropItem(worn, here)
					break
				end
			end
		end
	end
	self:sendRun(plr)
end

-- OUT: into the vault
function Deadvault:extract(plr)
	local char = plr.Character
	local r = self.runs[plr]
	if not (r and alive(char)) or self.out[plr] then return end
	-- (struck while you held on: not yet)
	if os.clock() - (char:GetAttribute("LastHitAt") or -1e9) < 2 then banner({text = "INTERRUPTED", sub = "YOU WERE STRUCK: HOLD AGAIN", kind = "fight"}, plr); return end
	self.out[plr] = true
	local items = {}
	for _, it in ipairs(carried(r)) do if not it.free then table.insert(items, it) end end
	local sold = Vault.bank(plr, items, r.gold)
	if _G.RoundBump then _G.RoundBump(plr, "vault_extract") end
	local st = Profile.get(plr).stats
	st.vaultOut = (st.vaultOut or 0) + 1
	local worth = r.gold
	for _, it in ipairs(items) do worth += Vault.value(it) end
	banner({text = "EXTRACTED", sub = string.format("%d THINGS AND %d GOLD INTO YOUR VAULT  ·  WORTH %d%s", #items, r.gold, worth, sold > 0 and string.format("  ·  A FULL STASH: %d SOLD", sold) or ""), kind = "victory"}, plr)
	banner({text = string.upper(plr.DisplayName) .. " GOT OUT", kind = "clear"})
	self.runs[plr] = {weapons = {}, relics = {}, bag = {}, belt = {}, gold = 0, kitTaken = true}
	char:Destroy()
	plr:SetAttribute("AdvChip", "🚪 EXTRACTED")
	plr:SetAttribute("RaidFate", "out")   -- (the round's end screen: RoundResult.client)
	local e = event()
	if e then e:FireClient(plr, "Inv", nil) end
	if not game:GetService("RunService"):IsStudio() and _G.HubTravel then
		task.delay(4, function() if plr.Parent then pcall(_G.HubTravel, plr, "Tavern", {}) end end)
	end
end

--------------------------------------------------------------------
--  THE ROUND
--------------------------------------------------------------------
function Deadvault:start(map)
	for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("RaidFate", nil) end
	Game.Mode.start(self, map)
	node:SetAttribute("FriendlyFire", true)
	self.runs, self.mobs, self.out, self.entered, self.havenOf = {}, {}, {}, {}, {}
	self.stairsOpen = false
	self.wave = 1
	self.startedAt = os.clock()
	if not self.layout or self.layout.theme ~= (Catalog.DUNGEONS[map] and map or self.theme) then
		local name = self:buildMap(map)
		MapLoader.load(name)
	end
	self.senses = Perception.new({sight = 46, hearing = 12, memory = 8, shout = 30, leash = 170})
	self.groundParams = RaycastParams.new()
	self.groundParams.FilterType = Enum.RaycastFilterType.Include
	self.groundParams.FilterDescendantsInstances = {MapLoader.current}
	self.boxes = Containers.new(self)
	self:stairs()
	self:dressRooms()
	do
		-- (a third of the corridors trapped; none by a way in)
		local skip = {}
		for _, r in ipairs(self.layout.rooms) do if r.kind == "start" then skip[r.id] = true end end
		Traps.arm(MapLoader.current, self.layout, {count = math.floor(#(self.layout.corridors or {}) * 0.3), theme = self.layout.theme, skip = skip})
	end
	self:populate()
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("ObjKind", "Deadvault")
	self:sendLayout()
	if not self.useConn and event() then
		self.useConn = event().OnServerEvent:Connect(function(plr, kind, a, b)
			local mode = Game.current
			if mode ~= self or not mode.boxes then return end
			if kind == "Use" and type(a) == "string" then mode:inv(plr, "Use", a)
			elseif kind == "Belt" and type(a) == "number" then
				local r = mode.runs[plr]
				local it = r and r.belt and r.belt[math.floor(a)]
				if it then mode:inv(plr, "Use", it.uid) end
			elseif kind == "Inv" and type(a) == "string" then mode:inv(plr, a, b)
			elseif kind == "Take" and type(a) == "number" and type(b) == "string" then mode.boxes:take(plr, a, b)
			elseif kind == "TakeAll" and type(a) == "number" then mode.boxes:takeAll(plr, a)
			elseif kind == "CloseLoot" and type(a) == "number" then mode.boxes:close(plr, a)
			elseif kind == "Hello" then mode:sendLayout(plr); if mode.runs[plr] then mode:sendRun(plr) end end
		end)
	end
	task.delay(2, function()
		banner({text = "DEADVAULT", sub = "LOOT IT, AND GET OUT ALIVE  ·  THE STAIRS OPEN IN " .. clock(STAIRS_AT) .. "  ·  (I) YOUR BAG", kind = "floor"})
	end)
end

function Deadvault:stop()
	Traps.disarm()
	-- (still inside when it collapses: lost)
	for plr, r in pairs(self.runs or {}) do
		if not self.out[plr] and plr.Parent and #carried(r) > 0 then banner({text = "LOST IN THE DARK", sub = "THE DEADVAULT KEEPS WHAT YOU CARRIED", kind = "boss"}, plr) end
	end
	for m in pairs(self.mobs or {}) do Monsters.despawn(m) end
	if self.opts then Monsters.halt(self.opts) end
	if self.boxes then self.boxes:clear() end
	Loot.clear()
	for _, k in ipairs({"OwnHud", "ObjKind", "ObjLabel", "ObjNote", "RaidersInside"}) do node:SetAttribute(k, nil) end
	local e = event()
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("AdvChip", nil)
		local c = p.Character
		if c then Loot.setRelics(c, {}); Loot.setArmor(c, nil); c:SetAttribute("Team", nil) end
		if e then e:FireClient(p, "Inv", nil) end
	end
	self.layout = nil
	if e then e:FireAllClients("Layout", nil) end
end

-- in at a haven: your party's, else the one farthest from the other raiders
function Deadvault:spawnCFrame(plr)
	local L = self.layout
	if not L then return Game.Mode.spawnCFrame(self, plr) end
	local key = partyKey(plr) or ("U" .. plr.UserId)
	local haven = self.havenOf[key]
	if not haven then
		local best, bestD
		for _, h in ipairs(self.havens or {}) do
			local d = 0
			for _, o in pairs(self.havenOf) do d += (o == h) and -1000 or (math.abs(o.gx - h.gx) + math.abs(o.gy - h.gy)) end
			d += math.random()
			if not bestD or d > bestD then best, bestD = h, d end
		end
		haven = best or L.rooms[1]
		self.havenOf[key] = haven
	end
	local c = Vector3.new(haven.cx + math.random(-7, 7), 4, haven.cz + math.random(-7, 7))
	return CFrame.new(c, Vector3.new(haven.cx, 4, haven.cz))
end

function Deadvault:canSpawn(plr)
	if self.out[plr] then return false, "You got out: your finds are in your vault" end
	if self.entered[plr] then return false, "One life in the Deadvault: watch, or go back to the Gilded Rat" end
	return true
end

-- a raider falls: everything they carried is in their pack where they fell
function Deadvault:onDeath(victimPlr)
	if self.out[victimPlr] then return end
	local r = self.runs[victimPlr]
	local char = victimPlr.Character
	local at = rootOf(char) and rootOf(char).Position
	if r and at then
		local items = carried(r)
		if r.gold > 0 then table.insert(items, Loot.gold(r.gold)) end
		if #items > 0 then
			local ground = workspace:Raycast(at, Vector3.new(0, -12, 0))
			local y = ground and ground.Position.Y or (at.Y - 3)
			self.boxes:add("pack", CFrame.new(at.X, y, at.Z), {items = items, name = victimPlr.DisplayName .. "'s pack"})
		end
		self.runs[victimPlr] = {weapons = {}, relics = {}, bag = {}, belt = {}, gold = 0, kitTaken = true}
		banner({text = "YOU FELL", sub = "EVERYTHING YOU CARRIED LIES IN YOUR PACK WHERE YOU FELL", kind = "boss"}, victimPlr)
		victimPlr:SetAttribute("AdvChip", "💀 FALLEN")
		victimPlr:SetAttribute("RaidFate", "fell")
		local e = event()
		if e then e:FireClient(victimPlr, "Inv", nil) end
	end
end

function Deadvault:tick(dt)
	if not self.layout then return end
	local t = os.clock() - self.startedAt
	if not self.stairsOpen and t >= STAIRS_AT then self:openStairs() end
	local wave = PORTALS[self.wave]
	if wave and t >= wave.at then
		self.wave += 1
		self:openPortals(wave.n)
	end
	local left = node:GetAttribute("TimeLeft") or 0
	local inside = 0
	for _, p in ipairs(Players:GetPlayers()) do if alive(p.Character) and not self.out[p] then inside += 1 end end
	local ways = (self.stairsOpen and 2 or 0)
	for _, r in ipairs(self.layout.rooms) do if r.portal == "open" then ways += 1 end end
	node:SetAttribute("ObjLabel", string.format("IT COLLAPSES IN %s", clock(left)))
	local nextWave = PORTALS[self.wave]
	local note
	if not self.stairsOpen then note = "THE STAIRS OPEN IN " .. clock(STAIRS_AT - t)
	else note = string.format("%d WAY%s OUT", ways, ways == 1 and "" or "S") .. (nextWave and ("  ·  PORTALS IN " .. clock(nextWave.at - t)) or "") end
	node:SetAttribute("ObjNote", note)
	node:SetAttribute("RaidersInside", inside)
	node:SetAttribute("Objective", self:objective())
	-- the dark's last minute: it hunts
	if left > 0 and left <= 60 and not self.lastCall then
		self.lastCall = true
		banner({text = "IT IS COLLAPSING", sub = "ONE MINUTE: GET OUT", kind = "boss"})
	end
end

function Deadvault:isOver()
	-- (Studio has no teleports: someone asked to leave, so the raid ends here)
	local nxt = node:GetAttribute("NextMode")
	if nxt and nxt ~= "" and nxt ~= "Deadvault" then return "BACK TO THE GILDED RAT" end
	-- everyone out or down (after the start): nothing left to wait for
	if os.clock() - self.startedAt < 30 then return nil end
	local any = false
	for p in pairs(self.entered) do if p.Parent and alive(p.Character) and not self.out[p] then any = true end end
	if not any and next(self.entered) then return "THE DEADVAULT IS QUIET AGAIN" end
	return nil
end
function Deadvault:result() return "THE DEADVAULT COLLAPSES" end
function Deadvault:objective() return "DEADVAULT  ·  LOOT IT, AND GET OUT ALIVE" end

return Deadvault
