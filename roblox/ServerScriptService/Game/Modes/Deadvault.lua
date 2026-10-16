--[[ DEADVAULT — raid it, loot it, get out alive (GameConfig.MODES.Deadvault), after Dark and
     Darker. A big dungeon built fresh every raid (Game ▸ Dungeon, the vote's theme), its rooms
     guarded by the theme's monsters (they stay by their room unless you come close), its
     chests full of the raids' loot (Game ▸ Loot, CHESTS.vault: weapons, armour, relics, potions,
     gold), and other raiders, who want it too.

     YOU GO IN with your KIT from your vault (Game ▸ Vault: what you chose to risk), or, with no
     kit, the free one: your class and a plain weapon. ONE LIFE. Everything you find goes into
     your BAG (BAG_MAX), or straight on (a better weapon, armour, a relic); potions are drunk from
     the bag (your relic bar: click one).
     THE WAYS OUT (the exit rooms' blue portals) open after OPEN_AT seconds: hold E… (your pickup
     key) at one to EXTRACT: everything you carry goes into your vault, with your gold, and you're
     out. FALL and it all spills where you fell, for whoever finds it. Still inside when the
     dungeon COLLAPSES (the round's end)? Lost, with all of it.

     Pay: Marks only for getting out (`vault_extract`, once a raid, under the daily cap), and a
     monster's kill by its rank, like any battle; the vault gold is the raids' own coin. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local Loot = require(script.Parent.Parent:WaitForChild("Loot"))
local Vault = require(script.Parent.Parent:WaitForChild("Vault"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Monsters = require(Combat:WaitForChild("Monsters"))
local Powers = require(Combat:WaitForChild("Powers"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local MapLoader = Game.MapLoader
local node = Game.node

local OPEN_AT = 4 * 60
local BAG_MAX = 12
local LEASH = 34          -- a guard leaves you be past this from its room
local GOLD_OF = {4, 10, 26, 80}
local BASIC = {Knight = "Shortsword", Footman = "Shortsword", Vanguard = "Shortsword", Archer = "Bow", Mage = "Staff"}

local Deadvault = setmetatable({}, {__index = Game.Mode})
Deadvault.__index = Deadvault
function Deadvault.new(def, id) return setmetatable(Game.Mode.new(def, id), Deadvault) end

local function humOf(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function rootOf(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function alive(c) local h = humOf(c); return h ~= nil and h.Health > 0 end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function banner(t, plr) local e = event(); if e then if plr then e:FireClient(plr, "Banner", t) else e:FireAllClients("Banner", t) end end end

--------------------------------------------------------------------
--  THE DUNGEON
--------------------------------------------------------------------
function Deadvault:buildMap(theme)
	self.theme = Catalog.DUNGEONS[theme] and theme or "BoneCrypt"
	local name, layout = Dungeon.build(self.theme, {rooms = 16, grid = {5, 5}, final = "none", exits = 3, loops = 3,
		special = {treasure = 2, shrine = 0, fountain = 1, elite = 2}})
	self.layout = layout
	-- three HAVENS beside the start (no guards): where raiders come in, far from each other
	local havens = {layout.rooms[layout.start]}
	for _ = 1, 3 do
		local best, bestD
		for _, r in ipairs(layout.rooms) do
			if r.kind == "combat" and not r.haven then
				local d = math.huge
				for _, h in ipairs(havens) do d = math.min(d, math.abs(h.gx - r.gx) + math.abs(h.gy - r.gy)) end
				for _, e in ipairs(layout.exits or {}) do local x = layout.rooms[e]; d = math.min(d, (math.abs(x.gx - r.gx) + math.abs(x.gy - r.gy)) * 1.5) end
				if not bestD or d > bestD then best, bestD = r, d end
			end
		end
		if best then best.haven = true; table.insert(havens, best) end
	end
	self.havens = havens
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
		if kind == "exit" and not self.open then kind = "combat" end
		rooms[r.id] = {id = r.id, cx = r.cx, cz = r.cz, w = r.w, d = r.d, kind = kind, state = "clear", doors = doors}
	end
	local data = {rooms = rooms, floor = 1, theme = self.theme, themeName = "DEADVAULT  ·  " .. string.upper(Catalog.DUNGEONS[self.theme].name)}
	local e = event()
	if e then if plr then e:FireClient(plr, "Layout", data) else e:FireAllClients("Layout", data) end end
end

-- every room's guards and chests, from the start
function Deadvault:populate()
	local th = Catalog.DUNGEONS[self.theme]
	local players = math.max(1, #Players:GetPlayers())
	for _, room in ipairs(self.layout.rooms) do
		if room.kind ~= "start" and room.kind ~= "exit" and not room.haven then
			local home = Vector3.new(room.cx, 3, room.cz)
			local opts = {team = "B", startDelay = 1, corpseTime = 4, hpMult = 1 + (players - 1) * 0.12,
				goal = function(b)
					local r = b.hrp
					if r and flat(r.Position - home).Magnitude > 6 then return home end
					return nil
				end,
				engage = function(b, foe)
					local fr = foe:FindFirstChild("HumanoidRootPart")
					return fr ~= nil and flat(fr.Position - home).Magnitude < LEASH and math.abs(fr.Position.Y - b.hrp.Position.Y) < 8
				end,
				arena = {centre = home, radius = math.max(room.w, room.d) / 2 + 6},
				onDeath = function(mob, killer)
					self.mobs[mob] = nil
					local r = mob.model and rootOf(mob.model)
					local at = r and r.Position or home
					local tier = mob.def.tier or 1
					self:dropItem(Loot.gold((GOLD_OF[tier] or 4) * (0.7 + math.random() * 0.6)), at)
					if tier >= 3 or mob.elite then self:dropItem(Loot.roll("elite", "Knight", 1.5), at) end
					if killer and _G.RoundBump then _G.RoundBump(killer, "kill_" .. (tier >= 3 and "Champion" or (tier == 2 and "Knight" or "Squire"))) end
				end,
				onSpawn = function(m) self.mobs[m] = true end}
			local list = {}
			if room.kind == "elite" then
				table.insert(list, {id = th.monsters.elite[math.random(#th.monsters.elite)], elite = true})
				table.insert(list, {id = th.monsters.common[math.random(#th.monsters.common)]})
			elseif room.kind == "combat" or room.kind == "treasure" then
				for _ = 1, math.random(2, 3) do
					local pool = math.random() < 0.3 and th.monsters.ranged or th.monsters.common
					table.insert(list, {id = pool[math.random(#pool)], elite = math.random() < 0.06})
				end
			end
			for i, e in ipairs(list) do
				local spot = room.spots[((i - 1) % #room.spots) + 1]
				local m = Monsters.spawn(e.id, opts, {at = CFrame.new(spot, home), elite = e.elite})
				if m then self.mobs[m] = true end
			end
			-- chests: a treasure room's two, an elite's one, now and then elsewhere
			local nChests = (room.kind == "treasure" and 2) or (room.kind == "elite" and 1) or (math.random() < 0.45 and 1 or 0)
			for c = 1, nChests do
				local at = Vector3.new(room.cx + (c == 1 and -6 or 6), 0.5, room.cz + room.d / 2 - 5)
				local rarity = room.kind == "treasure" and "Epic" or (room.kind == "elite" and "Rare" or "Uncommon")
				Loot.chest(CFrame.lookAt(at, Vector3.new(room.cx, 0.5, room.cz)), {rarity = rarity, gilded = rarity ~= "Uncommon", label = "Chest",
					onOpen = function(plr)
						local char = plr.Character
						if not alive(char) then return false end
						local classId = char:GetAttribute("Class") or "Knight"
						local luck = (rarity == "Epic" and 2) or (rarity == "Rare" and 1.2) or 0.4
						for i = 1, 3 do
							local a = (i / 3) * math.pi * 2
							task.delay(0.15 * i, function()
								self:dropItem(Loot.roll("vault", classId, luck + Loot.luckOf(char), {goldBase = 18}), at + Vector3.new(math.cos(a) * 3, 0, -2.5 + math.sin(a) * 1.5))
							end)
						end
						return true
					end})
			end
		end
	end
end

-- the exits: shut portals until OPEN_AT, then a prompt each
function Deadvault:exits(open)
	local m = MapLoader.current
	local geo = m and m:FindFirstChild("Props")
	for _, d in ipairs(geo and geo:GetChildren() or {}) do
		if d.Name == "ExitPortal" then
			d.Transparency = open and 0.25 or 0.9
			local l = d:FindFirstChildOfClass("PointLight"); if l then l.Enabled = open end
			local pe = d:FindFirstChildOfClass("ParticleEmitter"); if pe then pe.Enabled = open end
			if open and not d:FindFirstChild("ExtractPrompt") then
				local pr = Instance.new("ProximityPrompt")
				pr.Name = "ExtractPrompt"
				pr.ActionText = "Extract"; pr.ObjectText = "The way out"
				pr.HoldDuration = 3; pr.MaxActivationDistance = 10; pr.RequiresLineOfSight = false
				pr:SetAttribute("PickupKey", true)
				pr.Parent = d
				pr.Triggered:Connect(function(plr) self:extract(plr) end)
			end
		end
	end
end

--------------------------------------------------------------------
--  A RAIDER: what they carry
--------------------------------------------------------------------
function Deadvault:runOf(plr)
	local r = self.runs[plr]
	if not r then r = {weapons = {}, armor = nil, relics = {}, bag = {}, gold = 0, power = nil}; self.runs[plr] = r end
	return r
end
local function relicIds(r) local out = {}; for _, it in ipairs(r.relics) do table.insert(out, it.relic) end; return out end

function Deadvault:sendRun(plr)
	local r = self:runOf(plr)
	local items = {}
	local function add(it, where)
		local c = Loot.card(it)
		local text = table.concat(c.lines or {}, " · ")
		table.insert(items, {uid = it.uid, name = it.name, glyph = c.glyph, rarity = it.rarity, text = (where and (where .. " · ") or "") .. text, use = it.kind == "potion"})
	end
	for _, it in pairs(r.weapons) do add(it, "in hand") end
	if r.armor then add(r.armor, "worn") end
	for _, it in ipairs(r.relics) do add(it, "carried") end
	for _, it in ipairs(r.bag) do add(it, it.kind == "potion" and "click to drink" or "in your bag") end
	local e = event()
	if e then e:FireClient(plr, "Run", {gold = r.gold, relics = items, kind = "bag"}) end
	plr:SetAttribute("AdvChip", string.format("💰 %d  ·  🎒 %d/%d", r.gold, #r.bag, BAG_MAX))
end

-- the kit, or the free one
function Deadvault:adjustLoadout(plr, lo, classId)
	local r = self:runOf(plr)
	if not r.kitTaken then
		r.kitTaken = true
		local kit = Vault.takeKit(plr)
		if kit.weapon1 then r.weapons[kit.weapon1.slot or 1] = kit.weapon1 end
		if kit.weapon2 then r.weapons[kit.weapon2.slot or 2] = kit.weapon2 end
		r.armor = kit.armor
		for _, it in ipairs(kit.relics or {}) do table.insert(r.relics, it) end
		for _, it in ipairs(kit.potions or {}) do table.insert(r.bag, it) end
	end
	local w1, w2 = r.weapons[1], r.weapons[2]
	lo.weapon, lo.weaponSkin = w1 and w1.weapon or (BASIC[classId] or "Shortsword"), w1 and w1.skin or nil
	lo.secondary, lo.secondarySkin = w2 and w2.weapon or nil, w2 and w2.skin or nil
	if lo.secondary == lo.weapon then lo.secondary, lo.secondarySkin = nil, nil end
	lo.shield, lo.shieldSkin = nil, nil
	lo.power = r.power and r.power.power or nil
	lo.thirdKind, lo.thirdId = r.power and "power" or "none", r.power and r.power.power or nil
	lo.throwable = nil
end
function Deadvault:noteSpawn(plr)
	self.entered[plr] = true
	local char = plr.Character
	local r = self:runOf(plr)
	task.defer(function()
		if not char then return end
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

local function CFG_RANK(item) return Catalog.LOOT.RANK[item.rarity or "Common"] or 1 end

-- something picked up
function Deadvault:take(plr, item, at)
	local char = plr.Character
	if not alive(char) then return false end
	local r = self:runOf(plr)
	local here = rootOf(char) and rootOf(char).Position or at
	local function toBag(it)
		if #r.bag >= BAG_MAX then return false end
		table.insert(r.bag, it)
		return true
	end
	if item.kind == "gold" then r.gold += item.gold
	elseif item.kind == "weapon" then
		-- (a free slot, else the one in your hand is swapped out: into the bag, or dropped)
		local slot = Loot.slotFor(plr)
		local old = r.weapons[slot]
		Loot.giveWeapon(plr, item)
		r.weapons[item.slot] = item
		if old and not toBag(old) then self:dropItem(old, here) end
	elseif item.kind == "armor" then
		local better = not r.armor or (CFG_RANK(item) > CFG_RANK(r.armor))
		if better then
			local old = r.armor
			r.armor = item
			Loot.setArmor(char, item.armor)
			if old and not toBag(old) then self:dropItem(old, here) end
		elseif not toBag(item) then banner({text = "YOUR BAG IS FULL", kind = "fight"}, plr); return false end
	elseif item.kind == "relic" then
		if #r.relics < 3 then table.insert(r.relics, item); Loot.setRelics(char, relicIds(r))
		elseif not toBag(item) then banner({text = "YOUR BAG IS FULL", kind = "fight"}, plr); return false end
	elseif item.kind == "tome" then
		local old = r.power
		r.power = item
		Powers.equip(char, plr, {power = item.power})
		if old and not toBag(old) then self:dropItem(old, here) end
	elseif not toBag(item) then banner({text = "YOUR BAG IS FULL", kind = "fight"}, plr); return false end
	self:sendRun(plr)
	return true
end

function Deadvault:dropItem(item, pos)
	Loot.drop(item, pos - Vector3.new(0, 2.5, 0), {life = 600, onTake = function(plr, it) return self:take(plr, it, pos) end})
end

-- a potion from the bag
function Deadvault:use(plr, id)
	local r = self.runs[plr]
	local char = plr.Character
	if not (r and alive(char)) then return end
	for i, it in ipairs(r.bag) do
		if it.uid == id and it.kind == "potion" then
			table.remove(r.bag, i)
			Loot.drink(char, it.potion)
			self:sendRun(plr)
			return
		end
	end
end

-- everything they carry
local function carried(r)
	local all = {}
	for _, it in pairs(r.weapons) do table.insert(all, it) end
	if r.armor then table.insert(all, r.armor) end
	if r.power then table.insert(all, r.power) end
	for _, it in ipairs(r.relics) do table.insert(all, it) end
	for _, it in ipairs(r.bag) do table.insert(all, it) end
	return all
end

-- OUT: into the vault
function Deadvault:extract(plr)
	local char = plr.Character
	local r = self.runs[plr]
	if not (r and alive(char)) or self.out[plr] then return end
	self.out[plr] = true
	local items = carried(r)
	local sold = Vault.bank(plr, items, r.gold)
	if _G.RoundBump then _G.RoundBump(plr, "vault_extract") end
	local st = Profile.get(plr).stats
	st.vaultOut = (st.vaultOut or 0) + 1
	banner({text = "EXTRACTED", sub = string.format("%d THINGS AND %d GOLD INTO YOUR VAULT%s", #items, r.gold, sold > 0 and string.format(" (A FULL STASH: %d SOLD)", sold) or ""), kind = "victory"}, plr)
	banner({text = string.upper(plr.DisplayName) .. " GOT OUT", kind = "clear"})
	self.runs[plr] = {weapons = {}, relics = {}, bag = {}, gold = 0, kitTaken = true}
	-- off the field: back to the courtyard (Studio: they stay out of it, watching)
	char:Destroy()
	plr:SetAttribute("AdvChip", "🚪 EXTRACTED")
	if not game:GetService("RunService"):IsStudio() and _G.HubTravel then
		task.delay(3, function() if plr.Parent then pcall(_G.HubTravel, plr, "Courtyard", {}) end end)
	end
end

--------------------------------------------------------------------
--  THE ROUND
--------------------------------------------------------------------
function Deadvault:start(map)
	Game.Mode.start(self, map)
	node:SetAttribute("FriendlyFire", true)
	self.runs, self.mobs, self.out, self.entered = {}, {}, {}, {}
	self.open = false
	self.startedAt = os.clock()
	if not self.layout or self.layout.theme ~= (Catalog.DUNGEONS[map] and map or self.theme) then
		local name = self:buildMap(map)
		MapLoader.load(name)
	end
	self:exits(false)
	self:populate()
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("ObjKind", "Deadvault")
	self:sendLayout()
	if not self.useConn and event() then
		self.useConn = event().OnServerEvent:Connect(function(plr, kind, a)
			if Game.current ~= self then return end
			if kind == "Use" and type(a) == "string" then self:use(plr, a)
			elseif kind == "Hello" then self:sendLayout(plr); if self.runs[plr] then self:sendRun(plr) end end
		end)
	end
	task.delay(2, function() banner({text = "DEADVAULT", sub = "LOOT IT, AND GET OUT ALIVE  ·  THE WAYS OUT OPEN IN " .. math.floor(OPEN_AT / 60) .. ":00", kind = "floor"}) end)
end

function Deadvault:stop()
	-- (still inside when it collapses: lost)
	for plr, r in pairs(self.runs or {}) do
		if not self.out[plr] and plr.Parent and #carried(r) > 0 then banner({text = "LOST IN THE DARK", sub = "THE DEADVAULT KEEPS WHAT YOU CARRIED", kind = "boss"}, plr) end
	end
	for m in pairs(self.mobs or {}) do Monsters.despawn(m) end
	Loot.clear()
	for _, k in ipairs({"OwnHud", "ObjKind", "ObjLabel", "ObjNote"}) do node:SetAttribute(k, nil) end
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("AdvChip", nil)
		local c = p.Character
		if c then Loot.setRelics(c, {}); Loot.setArmor(c, nil) end
	end
	self.layout = nil
	local e = event()
	if e then e:FireAllClients("Layout", nil) end
end

-- in at a room far from the other raiders
function Deadvault:spawnCFrame(plr)
	local L = self.layout
	if not L then return Game.Mode.spawnCFrame(self, plr) end
	local others = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local r = p ~= plr and p.Character and rootOf(p.Character)
		if r then table.insert(others, r.Position) end
	end
	local best, bestD
	for _, room in ipairs(self.havens or L.rooms) do
		do
			local c = Vector3.new(room.cx + math.random(-6, 6), 4, room.cz + math.random(-6, 6))
			local d = math.huge
			for _, o in ipairs(others) do d = math.min(d, (o - c).Magnitude) end
			d += math.random() * 5
			if not bestD or d > bestD then best, bestD = c, d end
		end
	end
	return CFrame.new(best or Vector3.new(0, 4, 0))
end

function Deadvault:canSpawn(plr)
	if self.out[plr] then return false, "You got out: your finds are in your vault" end
	if self.entered[plr] then return false, "One life in the Deadvault: watch, or leave for the courtyard" end
	return true
end

-- a raider falls: it all spills out
function Deadvault:onDeath(victimPlr)
	if self.out[victimPlr] then return end
	local r = self.runs[victimPlr]
	local char = victimPlr.Character
	local at = rootOf(char) and rootOf(char).Position
	if r and at then
		for _, it in ipairs(carried(r)) do self:dropItem(it, at + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))) end
		if r.gold > 0 then self:dropItem(Loot.gold(r.gold), at) end
		self.runs[victimPlr] = {weapons = {}, relics = {}, bag = {}, gold = 0, kitTaken = true}
		banner({text = "YOU FELL", sub = "WHAT YOU CARRIED LIES WHERE YOU FELL", kind = "boss"}, victimPlr)
		victimPlr:SetAttribute("AdvChip", "💀 FALLEN")
	end
end

function Deadvault:tick(dt)
	local now = os.clock()
	local t = now - self.startedAt
	if not self.open and t >= OPEN_AT then
		self.open = true
		self:exits(true)
		self:sendLayout()
		banner({text = "THE WAYS OUT ARE OPEN", sub = "FIND A BLUE PORTAL AND EXTRACT", kind = "descend"})
	end
	local left = node:GetAttribute("TimeLeft") or 0
	local inside = 0
	for _, p in ipairs(Players:GetPlayers()) do if alive(p.Character) and not self.out[p] then inside += 1 end end
	node:SetAttribute("ObjLabel", string.format("DEADVAULT  ·  %d:%02d UNTIL IT COLLAPSES", math.floor(left / 60), left % 60))
	node:SetAttribute("ObjNote", self.open and string.format("THE WAYS OUT ARE OPEN  ·  %d RAIDER%s INSIDE", inside, inside == 1 and "" or "S")
		or string.format("THE WAYS OUT OPEN IN %d:%02d", math.floor(math.max(0, OPEN_AT - t) / 60), math.floor(math.max(0, OPEN_AT - t)) % 60))
	node:SetAttribute("Objective", self:objective())
end

function Deadvault:isOver()
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
