--[[ LOOT — a run's or a raid's gear (ReplicatedStorage ▸ Catalog ▸ Loot): rolled here, handed
     over here, and its effects run here. Nothing touches anyone's collection: The Depths and
     Crownfall keep it for the run; Deadvault keeps it in your vault (if you get out).

     ROLLING
       Loot.rarity(luck) -> rarity def           luck 0 plain … 3+ generous (deeper floors, Lucky Coin)
       Loot.weapon(classId, luck[, rarity])      a weapon your class carries, a skin that fits its
                                                 rarity (any skin: the run's, not yours to keep),
                                                 affixes by rarity, a name ("Blazing Longsword of
                                                 Giants"; a Legendary has its own)
       Loot.relic(luck[, have]) · Loot.tome(classId, luck) · Loot.potion(luck) · Loot.armor(luck)
       Loot.gold(n)
       Loot.roll(chestKind, classId, luck) -> item          (Catalog ▸ Loot CHESTS)
       Loot.choices(chestKind, classId, luck, n[, have]) -> {item…}   n different cards
       Loot.card(item) -> {kind, name, rarity, color, glyph, lines, weapon, skin}   (what a screen shows)

     HANDING IT OVER
       Loot.giveWeapon(plr, item) -> Tool         into its slot (LoadoutServer ▸ _G.GiveWeapon), tagged
       Loot.tagTool(tool, item)                   LootRarity / LootName / LootAffixes / LootPower
       Loot.setRelics(char, {ids}) · Loot.setArmor(char, armorId) · Loot.drink(char, potionId)
       Loot.onKill(killerPlayer)                  a kill's heal (Thirst, the Saint's Tear)
       Loot.tryRise(char) -> bool                 the Phoenix Plume, once
       Loot.luckOf(char)

     IN THE WORLD (workspace ▸ LootDrops)
       Loot.drop(item, pos, opts) -> drop         a glowing thing on the floor, a beam of its
                                                 rarity's colour; opts.onTake(plr, item, drop) ->
                                                 true takes it; opts.life seconds
       Loot.chest(cf, opts) -> chest              opts.rarity (its glow) · opts.perPlayer (each
                                                 player opens it once: OpenedBy_<id>, the client
                                                 hides the prompt) · opts.onOpen(plr, chest)
       Loot.clear()                               every drop and chest gone ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Powers = require(Combat:WaitForChild("Powers"))
local MagicServer = require(Combat:WaitForChild("MagicServer"))

local CFG = Catalog.LOOT
local Loot = {CFG = CFG}
local FOREVER = 1e6

local function humOf(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function uid() return HttpService:GenerateGUID(false):sub(1, 8) end

--------------------------------------------------------------------
--  ROLLING
--------------------------------------------------------------------
function Loot.rarity(luck)
	luck = math.max(0, luck or 0)
	local total, ws = 0, {}
	for i, r in ipairs(CFG.RARITIES) do
		local w = r.weight * (1 + luck * 0.45) ^ (i - 1)
		ws[i] = w
		total += w
	end
	local x = math.random() * total
	for i, r in ipairs(CFG.RARITIES) do
		x -= ws[i]
		if x <= 0 then return r end
	end
	return CFG.RARITIES[1]
end
local function rarityOf(r) return type(r) == "table" and r or CFG[r] or CFG.RARITIES[1] end
-- a rarity at least `floor` (a boss's chest never hands you a Common)
local function atLeast(r, floor)
	if not floor then return r end
	return (CFG.RANK[r.id] or 1) >= (CFG.RANK[floor] or 1) and r or CFG[floor]
end

local function findWeapon(name)
	local f = ServerStorage:FindFirstChild("Weapons")
	local t = f and f:FindFirstChild(name, true)
	return t and t:IsA("Tool") and t or nil
end

local skinPool = {}   -- [weaponId] = {skins by rarity}
local function skinsFor(weaponId)
	local cached = skinPool[weaponId]
	if cached then return cached end
	local out = {all = {}}
	for _, s in ipairs(Catalog.SKINS or {}) do
		if s.weapon == weaponId and (not Catalog.released or Catalog.released(s)) and not (s.id or ""):match(":Default$") then
			out[s.rarity or "Common"] = out[s.rarity or "Common"] or {}
			table.insert(out[s.rarity or "Common"], s.id)
			table.insert(out.all, s.id)
		end
	end
	skinPool[weaponId] = out
	return out
end

local function fmt(a, v)
	if a.pct then return string.format("%d%%", math.floor(v * 100 + 0.5)) end
	return tostring(math.floor(v + 0.5))
end
Loot.fmt = fmt

-- the weapons a class carries (that exist as Tools)
local function classWeapons(classId)
	local cls = GameConfig.CLASSES[classId or ""] or GameConfig.CLASSES.Knight
	local out = {}
	for _, w in ipairs(Catalog.WEAPONS) do
		local prim, sec = Catalog.weaponFits(cls, w, "primary"), Catalog.weaponFits(cls, w, "secondary")
		if (prim or sec) and not w.wand and findWeapon(w.id) then table.insert(out, {def = w, slot = prim and 1 or 2}) end
	end
	return out
end

function Loot.weapon(classId, luck, rarity)
	local r = rarity and rarityOf(rarity) or Loot.rarity(luck)
	local pool = classWeapons(classId)
	if #pool == 0 then return nil end
	local pickd = pool[math.random(#pool)]
	local w = pickd.def
	-- its looks: a skin of the weapon from its rarity's tiers
	local sk = skinsFor(w.id)
	local choices = {}
	for _, tier in ipairs(r.skin) do for _, id in ipairs(sk[tier] or {}) do table.insert(choices, id) end end
	if #choices == 0 and (CFG.RANK[r.id] or 1) >= 2 then choices = sk.all end
	local skin = #choices > 0 and choices[math.random(#choices)] or nil
	-- its affixes: different kinds; the rarer, the higher they roll
	local affixes, used = {}, {}
	local rank = CFG.RANK[r.id] or 1
	for _ = 1, r.affixes do
		for _try = 1, 12 do
			local a = CFG.AFFIXES[math.random(#CFG.AFFIXES)]
			-- (a bow's or a staff's blows aren't a blade's: no on-hit kinds that need the blade)
			local blade = not (w.ranged or w.magic)
			local fits = blade or not (a.kind == "burn" or a.kind == "chill" or a.kind == "poison" or a.kind == "lifesteal" or a.kind == "storm" or a.kind == "stagger")
			if not used[a.kind] and fits then
				used[a.kind] = true
				local q = math.random() ^ (1 / rank)
				if r.id == "Legendary" then q = 0.7 + 0.3 * math.random() end
				local v = a.roll[1] + (a.roll[2] - a.roll[1]) * q
				table.insert(affixes, {id = a.id, v = v})
				break
			end
		end
	end
	-- its name
	local name
	if r.id == "Legendary" then
		name = CFG.LEGENDARY_NAMES[math.random(#CFG.LEGENDARY_NAMES)]
	else
		local prefix, suffix
		for _, af in ipairs(affixes) do
			local a = CFG.AFFIX[af.id]
			if a.suffix then suffix = suffix or a.suffix else prefix = prefix or a.id end
		end
		name = (prefix and (prefix .. " ") or "") .. (w.name or w.id) .. (suffix and (" " .. suffix) or "")
	end
	return {kind = "weapon", uid = uid(), weapon = w.id, skin = skin, slot = pickd.slot, rarity = r.id, affixes = affixes, name = name, power = r.power}
end

function Loot.relic(luck, have, rarity)
	local r = rarity and rarityOf(rarity) or Loot.rarity(luck)
	local pool = {}
	for _, rel in ipairs(CFG.RELICS) do
		if not (have and have[rel.id]) and math.abs((CFG.RANK[rel.rarity] or 1) - (CFG.RANK[r.id] or 1)) <= 1 then table.insert(pool, rel) end
	end
	if #pool == 0 then for _, rel in ipairs(CFG.RELICS) do if not (have and have[rel.id]) then table.insert(pool, rel) end end end
	if #pool == 0 then return nil end
	local rel = pool[math.random(#pool)]
	return {kind = "relic", uid = uid(), relic = rel.id, rarity = rel.rarity, name = rel.name}
end

function Loot.tome(classId, luck)
	local r = Loot.rarity(luck)
	local pool = {}
	for _, p in ipairs(Catalog.POWERS or {}) do
		if not p.throw and p.class and math.abs((CFG.RANK[CFG.TOME_RARITY(p.level or 1)] or 1) - (CFG.RANK[r.id] or 1)) <= 1 then table.insert(pool, p) end
	end
	if #pool == 0 then for _, p in ipairs(Catalog.POWERS or {}) do if not p.throw and p.class then table.insert(pool, p) end end end
	if #pool == 0 then return nil end
	local p = pool[math.random(#pool)]
	return {kind = "tome", uid = uid(), power = p.id, rarity = CFG.TOME_RARITY(p.level or 1), name = "Tome of " .. (p.name or p.id)}
end

function Loot.potion(luck)
	local r = Loot.rarity(luck)
	local pool = {}
	for _, p in ipairs(CFG.POTIONS) do if (CFG.RANK[p.rarity] or 1) <= (CFG.RANK[r.id] or 1) + 1 then table.insert(pool, p) end end
	local p = pool[math.random(#pool)]
	return {kind = "potion", uid = uid(), potion = p.id, rarity = p.rarity, name = p.name}
end

function Loot.armor(luck, rarity)
	local r = rarity and rarityOf(rarity) or Loot.rarity(luck)
	local a = CFG.ARMOR[math.clamp(CFG.RANK[r.id] or 1, 1, #CFG.ARMOR)]
	return {kind = "armor", uid = uid(), armor = a.id, rarity = a.rarity, name = a.name}
end

function Loot.gold(n)
	n = math.max(1, math.floor(n))
	local rarity = n >= 120 and "Epic" or (n >= 60 and "Rare" or (n >= 25 and "Uncommon" or "Common"))
	return {kind = "gold", uid = uid(), gold = n, rarity = rarity, name = n .. " Gold"}
end

local function pickKind(weights, skip)
	local total = 0
	for k, w in pairs(weights) do if not (skip and skip[k]) then total += w end end
	if total <= 0 then return nil end
	local x = math.random() * total
	for k, w in pairs(weights) do
		if not (skip and skip[k]) then
			x -= w
			if x <= 0 then return k end
		end
	end
	return nil
end

-- one item from a chest of this kind
function Loot.roll(chestKind, classId, luck, opts)
	opts = opts or {}
	local weights = CFG.CHESTS[chestKind] or CFG.CHESTS.depths
	local kind = opts.kind or pickKind(weights, opts.skip)
	local floor = opts.floor
	local item
	if kind == "weapon" then item = Loot.weapon(classId, luck, floor and atLeast(Loot.rarity(luck), floor) or nil)
	elseif kind == "relic" then item = Loot.relic(luck, opts.have, floor and atLeast(Loot.rarity(luck), floor) or nil)
	elseif kind == "tome" then item = Loot.tome(classId, luck)
	elseif kind == "potion" then item = Loot.potion(luck)
	elseif kind == "armor" then item = Loot.armor(luck, floor and atLeast(Loot.rarity(luck), floor) or nil)
	elseif kind == "gold" then item = Loot.gold((opts.goldBase or 20) * (1 + (luck or 0) * 0.5) * (0.6 + math.random() * 0.8)) end
	return item or Loot.gold(10)
end

-- n cards, each a different kind where it can be (a weapon, a relic, a tome…)
function Loot.choices(chestKind, classId, luck, n, opts)
	opts = opts or {}
	local out, used = {}, {}
	for k, v in pairs(opts.skip or {}) do used[k] = v end
	for _ = 1, n do
		local weights = CFG.CHESTS[chestKind] or CFG.CHESTS.depths
		local kind = pickKind(weights, used) or pickKind(weights, opts.skip)
		used[kind or ""] = true
		local o2 = table.clone(opts)
		o2.kind = kind
		table.insert(out, Loot.roll(chestKind, classId, luck, o2))
	end
	return out
end

-- WHAT A SCREEN SHOWS of an item
function Loot.card(item)
	if not item then return nil end
	local r = CFG[item.rarity] or CFG.RARITIES[1]
	local c = {kind = item.kind, uid = item.uid, name = item.name, rarity = r.id, color = r.color, lines = {}}
	if item.kind == "weapon" then
		local w = Catalog.WEAPON[item.weapon]
		c.weapon, c.skin = item.weapon, item.skin
		c.sub = r.id .. " " .. ((w and w.name) or item.weapon) .. (item.slot == 2 and "  ·  sidearm" or "")
		if (item.power or 0) > 0 then table.insert(c.lines, string.format("+%d%% damage", math.floor(item.power * 100 + 0.5))) end
		for _, af in ipairs(item.affixes or {}) do
			local a = CFG.AFFIX[af.id]
			if a then table.insert(c.lines, string.format(a.text, fmt(a, af.v))) end
		end
		local sk = item.skin and Catalog.SKIN and Catalog.SKIN[item.skin]
		if sk then table.insert(c.lines, "Wears " .. (sk.name or item.skin)) end
		c.glyph = "⚔️"
	elseif item.kind == "relic" then
		local rel = CFG.RELIC[item.relic]
		c.sub = r.id .. " relic"
		c.glyph = rel and rel.glyph or "💎"
		table.insert(c.lines, rel and rel.text or "")
	elseif item.kind == "tome" then
		local p = Catalog.POWER and Catalog.POWER[item.power]
		c.sub = r.id .. " tome  ·  a power for the run"
		c.glyph = p and p.glyph or "📖"
		c.power = item.power
		table.insert(c.lines, "Your power becomes " .. ((p and p.name) or item.power))
		if p and p.description then table.insert(c.lines, p.description) end
	elseif item.kind == "potion" then
		local p = CFG.POTION[item.potion]
		c.sub = r.id .. " potion"
		c.glyph = p and p.glyph or "🧪"
		table.insert(c.lines, p and p.text or "")
	elseif item.kind == "armor" then
		local a = CFG.ARMOR_BY[item.armor]
		c.sub = r.id .. " armor"
		c.glyph = "🛡️"
		if a then
			table.insert(c.lines, string.format("You take %d%% less damage", math.floor((1 - a.taken) * 100 + 0.5)))
			if (a.health or 0) > 0 then table.insert(c.lines, "+" .. a.health .. " health") end
		end
	elseif item.kind == "gold" then
		c.sub = "Gold"
		c.glyph = "💰"
		table.insert(c.lines, item.gold .. " gold for the run")
	end
	return c
end

--------------------------------------------------------------------
--  HANDING IT OVER
--------------------------------------------------------------------
local function affixString(item)
	local parts = {}
	for _, af in ipairs(item.affixes or {}) do table.insert(parts, af.id .. "=" .. string.format("%.3f", af.v)) end
	return table.concat(parts, ";")
end
function Loot.tagTool(tool, item)
	if not tool then return end
	tool:SetAttribute("LootRarity", item.rarity)
	tool:SetAttribute("LootName", item.name)
	tool:SetAttribute("LootAffixes", affixString(item))
	tool:SetAttribute("LootPower", item.power or 0)
	tool:SetAttribute("LootUid", item.uid)
	-- (the weapon bar's chip: the rarity's colour, its name: Hotbar)
	tool:SetAttribute("DisplayName", item.name)
end

function Loot.giveWeapon(plr, item)
	if not (_G.GiveWeapon and item and item.kind == "weapon") then return nil end
	local tool, twin = _G.GiveWeapon(plr, item.weapon, item.skin, item.slot or 1, item.slot == 1)
	Loot.tagTool(tool, item)
	if twin then Loot.tagTool(twin, item) end
	return tool
end

-- what's on a character (relics, armor, a rise used)
local state = setmetatable({}, {__mode = "k"})
local function st(char)
	local s = state[char]
	if not s then s = {relics = {}, effects = {}, health = 0, luck = 0}; state[char] = s end
	return s
end
Loot.stateOf = st

local function setBonusHealth(char, key, amount)
	local hum = humOf(char)
	if not hum then return end
	local s = st(char)
	s.bonus = s.bonus or {}
	local before = 0
	for _, v in pairs(s.bonus) do before += v end
	s.bonus[key] = amount
	local after = 0
	for _, v in pairs(s.bonus) do after += v end
	local d = after - before
	if d ~= 0 then
		hum.MaxHealth = math.max(10, hum.MaxHealth + d)
		if d > 0 then hum.Health = math.min(hum.MaxHealth, hum.Health + d) end
	end
end

function Loot.setRelics(char, ids)
	local s = st(char)
	s.relics, s.effects, s.luck = {}, {}, 0
	local mods, health = {}, 0
	local names = {}
	for _, id in ipairs(ids or {}) do
		local rel = CFG.RELIC[id]
		if rel then
			s.relics[id] = true
			table.insert(names, id)
			for k, v in pairs(rel.mods or {}) do mods[k] = (mods[k] or 1) * v end
			health += rel.health or 0
			if rel.effect then s.effects[rel.effect] = true end
			if rel.effect == "luck" then s.luck += 1 end
		end
	end
	if next(mods) then Powers.addMods(char, mods, FOREVER, "Relics") else Powers.clearMods(char, "Relics") end
	setBonusHealth(char, "relics", health)
	char:SetAttribute("Relics", table.concat(names, ","))
end

function Loot.setArmor(char, armorId)
	local a = armorId and CFG.ARMOR_BY[armorId]
	local s = st(char)
	s.armor = a and a.id or nil
	if a then Powers.addMods(char, {taken = a.taken}, FOREVER, "LootArmor") else Powers.clearMods(char, "LootArmor") end
	setBonusHealth(char, "armor", a and a.health or 0)
	char:SetAttribute("LootArmor", a and a.id or nil)
	char:SetAttribute("LootArmorRarity", a and a.rarity or nil)
end

function Loot.drink(char, potionId)
	local p = CFG.POTION[potionId]
	local hum = humOf(char)
	if not (p and hum and hum.Health > 0) then return false end
	if p.heal then MagicServer.heal(char, hum.MaxHealth * p.heal, 1.5) end
	if p.mods then Powers.addMods(char, p.mods, p.time or 30, "Potion_" .. p.id) end
	local r = rootOf(char)
	if r then Loot.sparkle(r.Position, (CFG[p.rarity] or CFG.Common).color) end
	return true
end

function Loot.luckOf(char) return state[char] and state[char].luck or 0 end

function Loot.tryRise(char)
	local s = state[char]
	if not (s and s.effects.rise and not s.risen) then return false end
	s.risen = true
	return true
end
-- a new body for the same run: what it carried comes back on (the mode calls it on a spawn)
function Loot.carryOver(fromChar, toChar)
	local s = state[fromChar]
	if s then state[toChar] = s; s.bonus = {} end
end

-- THE HELD WEAPON's own bonus: its damage, its speed (while it's in your hand)
local parsed = setmetatable({}, {__mode = "k"})
local function affixesOf(tool)
	if not tool then return nil end
	local raw = tool:GetAttribute("LootAffixes")
	if not raw or raw == "" then return nil end
	local p = parsed[tool]
	if p and p.raw == raw then return p.t end
	local t = {}
	for id, v in raw:gmatch("(%w+)=([%d%.%-]+)") do
		local a = CFG.AFFIX[id]
		if a then t[a.kind] = (t[a.kind] or 0) + tonumber(v) end
	end
	parsed[tool] = {raw = raw, t = t}
	return t
end
Loot.affixesOf = affixesOf

local function heldChanged(char)
	local tool = char:FindFirstChildOfClass("Tool")
	local power = tool and tool:GetAttribute("LootPower")
	if not power then Powers.clearMods(char, "LootWeapon"); return end
	local aff = affixesOf(tool) or {}
	Powers.addMods(char, {dealt = 1 + power + (aff.damage or 0), speed = 1 + (aff.speed or 0)}, FOREVER, "LootWeapon")
end
local watched = setmetatable({}, {__mode = "k"})
local function watch(char)
	if watched[char] then return end
	watched[char] = true
	char.ChildAdded:Connect(function(c) if c:IsA("Tool") then heldChanged(char) end end)
	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then heldChanged(char) end end)
	heldChanged(char)
end
local function hookPlayer(plr)
	plr.CharacterAdded:Connect(watch)
	if plr.Character then watch(plr.Character) end
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end

-- A BOLT from the sky onto a target (the Thundering affix, the Ring of Storms)
local fxFolder = workspace:FindFirstChild("LootFX") or Instance.new("Folder")
fxFolder.Name = "LootFX"; fxFolder.Parent = workspace
local function bolt(at)
	local top = at + Vector3.new(math.random(-3, 3), 26, math.random(-3, 3))
	local prev = top
	for i = 1, 5 do
		local nxt = (i == 5) and at or top:Lerp(at, i / 5) + Vector3.new(math.random(-15, 15) / 10, 0, math.random(-15, 15) / 10)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(170, 210, 255)
		local len = (nxt - prev).Magnitude
		p.Size = Vector3.new(0.25, 0.25, len)
		p.CFrame = CFrame.lookAt((prev + nxt) / 2, nxt)
		p.Parent = fxFolder
		game:GetService("Debris"):AddItem(p, 0.18)
		prev = nxt
	end
end

-- THE HIT: a looted weapon's affixes, the relics of whoever strikes and whoever's struck
Powers.meleeHooks = Powers.meleeHooks or {}
table.insert(Powers.meleeHooks, function(attacker, target, dmg)
	local sa, stt = state[attacker], state[target]
	local tool = attacker:FindFirstChildOfClass("Tool")
	local aff = affixesOf(tool)
	if not (aff or sa or stt) then return dmg end
	aff = aff or {}
	local eff = sa and sa.effects or {}
	local th = humOf(target)
	local mult = 1
	if aff.execute and th and th.Health < th.MaxHealth / 3 then mult += aff.execute end
	if aff.giant and (target:GetAttribute("Boss") or target:GetAttribute("Elite") or (target:GetAttribute("Tier") or 0) >= 3) then mult += aff.giant end
	if aff.holy and target:GetAttribute("Faction") == "Undead" then mult += aff.holy end
	local ah = humOf(attacker)
	if eff.berserk and ah and ah.Health < ah.MaxHealth * 0.5 then mult += 0.25 end
	dmg *= mult
	local name = tool and tool:GetAttribute("LootName") or "Relic"
	task.defer(function()
		if not target.Parent then return end
		local burn = aff.burn or (eff.burn and 5)
		if burn then MagicServer.burn(attacker, target, {dps = burn, time = 3}, name) end
		local chill = aff.chill or (eff.chill and 0.3)
		if chill then MagicServer.chill(attacker, target, chill, 2) end
		if aff.poison then Powers.poison(attacker, target, {dps = aff.poison, time = 4}, name) end
		local steal = (aff.lifesteal or 0) + (eff.lifesteal and 0.08 or 0)
		if steal > 0 and ah and ah.Health > 0 then ah.Health = math.min(ah.MaxHealth, ah.Health + dmg * steal) end
		local storm = (aff.storm or 0) + (eff.storm and 0.2 or 0)
		if storm > 0 and math.random() < storm then
			local tr = rootOf(target)
			if tr then bolt(tr.Position) end
			MagicServer.hurt(attacker, target, 18, "Lightning")
		end
		if aff.stagger and math.random() < aff.stagger then Powers.stun(target, 0.5) end
		-- thorns: whoever hit someone wearing the Thorned Mantle
		if stt and stt.effects.thorns and attacker.Parent then MagicServer.hurt(target, attacker, dmg * 0.2, "Thorned Mantle") end
	end)
	return dmg
end)

-- a kill's heal
function Loot.onKill(plr)
	local char = plr and plr.Character
	local hum = humOf(char)
	if not (hum and hum.Health > 0) then return end
	local heal = 0
	local aff = affixesOf(char:FindFirstChildOfClass("Tool"))
	if aff and aff.thirst then heal += aff.thirst end
	local s = state[char]
	if s and s.effects.thirst then heal += 15 end
	if heal > 0 then hum.Health = math.min(hum.MaxHealth, hum.Health + heal) end
end

-- the slow things: the Troll Heart's mending, the Berserker's pace
task.spawn(function()
	while true do
		task.wait(0.5)
		for char, s in pairs(state) do
			local hum = humOf(char)
			if hum and hum.Health > 0 and char.Parent then
				if s.effects.regen and os.clock() - (char:GetAttribute("LastCombatAt") or 0) > 4 then
					hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * 0.02)
				end
				if s.effects.berserk then
					local low = hum.Health < hum.MaxHealth * 0.5
					if low ~= (s.berserkOn == true) then
						s.berserkOn = low
						if low then Powers.addMods(char, {speed = 1.1}, FOREVER, "Berserk") else Powers.clearMods(char, "Berserk") end
					end
				end
			end
		end
	end
end)

--------------------------------------------------------------------
--  IN THE WORLD: drops and chests
--------------------------------------------------------------------
local dropsFolder = workspace:FindFirstChild("LootDrops") or Instance.new("Folder")
dropsFolder.Name = "LootDrops"; dropsFolder.Parent = workspace

local function quiet(p)
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = true, false, false, false, true
end

function Loot.sparkle(pos, color)
	local a = Instance.new("Part")
	quiet(a); a.Transparency = 1; a.Size = Vector3.new(1, 1, 1); a.Position = pos
	a.Parent = fxFolder
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color)
	pe.LightEmission = 1
	pe.Speed = NumberRange.new(4, 10)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.5, 1)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	pe.Rate = 0
	pe.Parent = a
	pe:Emit(30)
	game:GetService("Debris"):AddItem(a, 1.5)
end

-- the thing itself, small, to sit on the floor
local function shapeOf(item)
	local m = Instance.new("Model")
	m.Name = "Shape"
	local r = CFG[item.rarity] or CFG.Common
	if item.kind == "weapon" then
		local t = findWeapon(item.weapon)
		if t then
			local tool = t:Clone()
			if item.skin then pcall(Dresser.applySkin, tool, item.skin, nil) end
			for _, d in ipairs(tool:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("ProximityPrompt") then d:Destroy() end
			end
			for _, d in ipairs(tool:GetChildren()) do d.Parent = m end
			tool:Destroy()
			for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then quiet(d) end end
		end
	end
	if not m:FindFirstChildWhichIsA("BasePart", true) then
		local p = Instance.new("Part")
		quiet(p)
		p.Name = "Orb"
		if item.kind == "gold" then
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(0.35, 1.6, 1.6)
			p.Color = Color3.fromRGB(240, 196, 70); p.Material = Enum.Material.Metal
		elseif item.kind == "potion" then
			p.Shape = Enum.PartType.Ball; p.Size = Vector3.new(1.1, 1.1, 1.1)
			p.Color = r.color; p.Material = Enum.Material.Glass; p.Transparency = 0.15
			local neck = Instance.new("Part"); quiet(neck); neck.Size = Vector3.new(0.35, 0.5, 0.35); neck.Color = Color3.fromRGB(120, 90, 60); neck.Material = Enum.Material.Wood
			neck.CFrame = CFrame.new(0, 0.7, 0); neck.Parent = m
		elseif item.kind == "tome" then
			p.Size = Vector3.new(1.3, 0.4, 1.7); p.Color = Color3.fromRGB(70, 40, 90); p.Material = Enum.Material.Fabric
			local pages = Instance.new("Part"); quiet(pages); pages.Size = Vector3.new(1.15, 0.3, 1.6); pages.Color = Color3.fromRGB(240, 230, 200)
			pages.CFrame = CFrame.new(0.05, 0, 0); pages.Parent = m
			local rune = Instance.new("Part"); quiet(rune); rune.Size = Vector3.new(0.5, 0.42, 0.5); rune.Color = r.color; rune.Material = Enum.Material.Neon
			rune.CFrame = CFrame.new(0, 0.02, 0) * CFrame.Angles(0, math.rad(45), 0); rune.Parent = m
		elseif item.kind == "armor" then
			p.Size = Vector3.new(1.8, 1.8, 0.8); p.Color = Color3.fromRGB(150, 156, 166); p.Material = Enum.Material.Metal
			local trim = Instance.new("Part"); quiet(trim); trim.Size = Vector3.new(1.9, 0.25, 0.9); trim.Color = r.color; trim.Material = Enum.Material.Neon
			trim.CFrame = CFrame.new(0, 0.5, 0); trim.Parent = m
		else   -- a relic: a gem
			p.Size = Vector3.new(0.9, 0.9, 0.9); p.Color = r.color; p.Material = Enum.Material.Neon
			p.CFrame = CFrame.Angles(math.rad(45), 0, math.rad(45))
			local ringP = Instance.new("Part"); quiet(ringP); ringP.Shape = Enum.PartType.Cylinder; ringP.Size = Vector3.new(0.12, 1.6, 1.6)
			ringP.Color = Color3.fromRGB(230, 190, 90); ringP.Material = Enum.Material.Metal; ringP.Parent = m
		end
		p.Parent = m
	end
	return m
end

local drops = {}
function Loot.drop(item, pos, opts)
	opts = opts or {}
	local r = CFG[item.rarity] or CFG.Common
	local model = Instance.new("Model")
	model.Name = "LootDrop"
	model:SetAttribute("Rarity", item.rarity)
	model:SetAttribute("Spin", true)
	local shape = shapeOf(item)
	shape.Parent = model
	-- it floats a little above the floor; the client spins it (Adventure.client)
	local ok, cf, size = pcall(function() return shape:GetBoundingBox() end)
	local base = CFrame.new(pos + Vector3.new(0, 1.6, 0))
	if ok then
		local tilt = item.kind == "weapon" and CFrame.Angles(0, 0, math.rad(70)) or CFrame.new()
		shape:PivotTo(base * tilt)
		if item.kind == "weapon" and size.Magnitude > 7 then pcall(function() shape:ScaleTo(7 / size.Magnitude) end) end
	end
	local anchor = Instance.new("Part")
	quiet(anchor)
	anchor.Name = "Anchor"
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = base
	anchor.Parent = model
	model.PrimaryPart = anchor
	-- a beam of its colour (taller for the rarer)
	local rank = CFG.RANK[item.rarity] or 1
	local beam = Instance.new("Part")
	quiet(beam)
	beam.Name = "Beam"
	beam.Shape = Enum.PartType.Cylinder
	beam.Material = Enum.Material.Neon
	beam.Color = r.color
	beam.Transparency = 0.55
	beam.CastShadow = false
	local h = 3 + rank * 3
	beam.Size = Vector3.new(h, 0.18 + rank * 0.04, 0.18 + rank * 0.04)
	beam.CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	beam.Parent = model
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = r.color, 6 + rank * 2, 1.2, false
	light.Parent = anchor
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LootPrompt"
	prompt.ActionText = opts.action or "Take"
	prompt.ObjectText = item.name
	prompt.KeyboardKeyCode = Enum.KeyCode.V
	prompt:SetAttribute("PickupKey", true)
	prompt.HoldDuration = opts.hold or 0.2
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	model.Parent = opts.parent or dropsFolder
	local drop = {item = item, model = model, prompt = prompt}
	drops[drop] = true
	prompt.Triggered:Connect(function(plr)
		if not drops[drop] then return end
		local okT, taken = pcall(function() return opts.onTake and opts.onTake(plr, item, drop) end)
		if not okT then warn("[Loot] onTake:", taken) end
		if taken then
			Loot.sparkle(pos + Vector3.new(0, 1.5, 0), r.color)
			Loot.removeDrop(drop)
		end
	end)
	if opts.life then
		task.delay(opts.life, function() if drops[drop] then Loot.removeDrop(drop) end end)
	end
	return drop
end
function Loot.removeDrop(drop)
	drops[drop] = nil
	if drop.model then drop.model:Destroy() end
end

-- A CHEST: wood, iron bands, a glowing seam of its rarity's colour
local chests = {}
function Loot.chest(cf, opts)
	opts = opts or {}
	local r = CFG[opts.rarity or "Common"] or CFG.Common
	local m = Instance.new("Model")
	m.Name = "Chest"
	local wood = Color3.fromRGB(110, 72, 40)
	local iron = opts.gilded and Color3.fromRGB(226, 182, 70) or Color3.fromRGB(70, 70, 76)
	local function part(name, size, color, mat, off, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, true, true, false
		if shape then p.Shape = shape end
		p.Size, p.Color, p.Material = size, color, mat or Enum.Material.Wood
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CFrame = cf * off
		p.Parent = m
		return p
	end
	local body = part("Body", Vector3.new(3.6, 1.8, 2.3), wood, Enum.Material.WoodPlanks, CFrame.new(0, 0.9, 0))
	for _, x in ipairs({-1.3, 1.3}) do part("Band", Vector3.new(0.25, 1.85, 2.35), iron, Enum.Material.Metal, CFrame.new(x, 0.9, 0)) end
	local lid = Instance.new("Model"); lid.Name = "Lid"; lid.Parent = m
	local hinge = cf * CFrame.new(0, 1.8, 1.15)
	local function lidPart(name, size, color, mat, off, shape)
		local p = part(name, size, color, mat, off, shape)
		p.Parent = lid
		return p
	end
	lidPart("LidTop", Vector3.new(3.6, 0.7, 2.3), wood, Enum.Material.WoodPlanks, CFrame.new(0, 2.15, 0))
	for _, x in ipairs({-1.3, 1.3}) do lidPart("LidBand", Vector3.new(0.25, 0.75, 2.35), iron, Enum.Material.Metal, CFrame.new(x, 2.15, 0)) end
	lidPart("Lock", Vector3.new(0.5, 0.6, 0.2), iron, Enum.Material.Metal, CFrame.new(0, 1.85, -1.2))
	local seam = part("Seam", Vector3.new(3.5, 0.12, 2.2), r.color, Enum.Material.Neon, CFrame.new(0, 1.82, 0))
	seam.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = r.color, 8, 1.4, false
	light.Parent = seam
	local glow = Instance.new("ParticleEmitter")
	glow.Color = ColorSequence.new(r.color)
	glow.LightEmission = 1
	glow.Rate = 4 + (CFG.RANK[r.id] or 1) * 2
	glow.Lifetime = NumberRange.new(1, 1.6)
	glow.Speed = NumberRange.new(0.5, 1.5)
	glow.Acceleration = Vector3.new(0, 2, 0)
	glow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0)})
	glow.Parent = seam
	m.PrimaryPart = body
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChestPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = opts.label or "Chest"
	prompt.KeyboardKeyCode = Enum.KeyCode.V
	prompt:SetAttribute("PickupKey", true)
	prompt.HoldDuration = opts.hold or 0.6
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	m:SetAttribute("Rarity", r.id)
	m.Parent = opts.parent or dropsFolder
	local chest = {model = m, prompt = prompt, opened = {}, cf = cf, seam = seam}
	chests[chest] = true
	local open = false
	local function swing()
		if open then return end
		open = true
		-- the lid swings up about its hinge
		local TweenService = game:GetService("TweenService")
		local start = hinge
		local value = Instance.new("NumberValue")
		value.Changed:Connect(function(a)
			for _, p in ipairs(lid:GetChildren()) do
				local rel = p:GetAttribute("Rel")
				if not rel then rel = start:ToObjectSpace(p.CFrame); p:SetAttribute("Rel", rel) end
				p.CFrame = start * CFrame.Angles(math.rad(-a), 0, 0) * rel
			end
		end)
		TweenService:Create(value, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Value = 105}):Play()
		task.delay(0.6, function() value:Destroy() end)
		Loot.sparkle(cf.Position + Vector3.new(0, 2, 0), r.color)
	end
	chest.swing = swing
	prompt.Triggered:Connect(function(plr)
		if not chests[chest] then return end
		if opts.perPlayer then
			if chest.opened[plr.UserId] then return end
		elseif open then return end
		local okO, allowed = pcall(function() return opts.onOpen and opts.onOpen(plr, chest) end)
		if not okO then warn("[Loot] onOpen:", allowed) end
		if allowed == false then return end
		chest.opened[plr.UserId] = true
		m:SetAttribute("OpenedBy_" .. plr.UserId, true)
		swing()
		if not opts.perPlayer then prompt.Enabled = false; seam.Transparency = 1; light.Enabled = false; glow.Enabled = false end
	end)
	return chest
end

function Loot.clear()
	for d in pairs(drops) do Loot.removeDrop(d) end
	for c in pairs(chests) do if c.model then c.model:Destroy() end end
	drops, chests = {}, {}
	dropsFolder:ClearAllChildren()
end

return Loot
