--[[ VAULT — Deadvault's persistent side (Game ▸ Modes ▸ Deadvault): what you've brought out of
     the raids, kept in your profile (Profile ▸ vault), and the merchants who trade in it. Nothing
     in it touches your collection: these are the raids' own things (Catalog ▸ Loot), and vault
     gold is its own coin.

       vault.stash   up to STASH_MAX items (weapons, armour, relics, potions, tomes, valuables)
       vault.kit     what you take in next time: weapon1, weapon2, armor, relics (RELICS),
                     potions (POTIONS). An empty weapon slot: the free kit's plain weapon for
                     your class (never lost, never sold)
       vault.gold    the merchants' coin
       vault.stock   today's wares at the Smith (rolled for your class, each sold once)
       vault.raids / vault.out   raids gone into / got out of

     THE MERCHANTS (MERCHANTS): the Smith (weapons for your class, today's four; and his work:
     REFORGE a weapon's affixes, TEMPER it up a rarity), the Armourer (armour), the Alchemist
     (draughts and elixirs), the Treasurer (buys anything; valuables at their full worth).

       Vault.view(plr)              everything a screen shows (cards: Game ▸ Loot.card)
       Vault.equip(plr, uid)        stash → kit (what was in the slot goes back to the stash)
       Vault.unequip(plr, uid)      kit → stash
       Vault.sell(plr, uid)         stash → gold (Vault.value)
       Vault.buy(plr, merchant, i)  a merchant's i-th ware → stash, for gold
       Vault.work(plr, uid, kind)   the Smith's: "reforge" | "temper" (stash or kit), for gold
       Vault.takeKit(plr)           the kit, out of the vault (into the raid: risked)
       Vault.bank(plr, items, gold) what came out with you: into the stash (no room: sold) ]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Loot = require(script.Parent:WaitForChild("Loot"))

local Vault = {}
Vault.STASH_MAX = 60
Vault.RELICS, Vault.POTIONS = 3, 4
local CFG = Catalog.LOOT
local KIND_VALUE = {weapon = 1, armor = 1, relic = 1.5, potion = 0.4, tome = 1.2}

-- THE MERCHANTS: who sells what (gold). A weapon line is rolled fresh each day for your class
Vault.MERCHANTS = {
	{id = "Smith", name = "Hrothgar the Smith", glyph = "🔨", line = "Steel for your hands. Bring me a blade and gold, and I'll make it sing.",
		wares = {{weapon = "Common", price = 45}, {weapon = "Uncommon", price = 160}, {weapon = "Uncommon", price = 160}, {weapon = "Rare", price = 450}}},
	{id = "Armourer", name = "Old Brenna", glyph = "🛡️", line = "It won't stop everything. It'll stop enough.",
		wares = {{armor = "Padded", price = 55}, {armor = "Mail", price = 160}, {armor = "Brigandine", price = 460}}},
	{id = "Alchemist", name = "Wendel the Alchemist", glyph = "🧪", line = "Drink before you need it, not after.",
		wares = {{potion = "Healing", price = 30}, {potion = "Greater", price = 140}, {potion = "Swift", price = 60}, {potion = "Stone", price = 70}, {potion = "Fury", price = 70}}},
	{id = "Treasurer", name = "The Treasurer", glyph = "💰", line = "Anything that glitters, at its full worth. Everything else, at what it's worth to me.",
		wares = {}},
}
Vault.MERCHANT = {}
for _, m in ipairs(Vault.MERCHANTS) do Vault.MERCHANT[m.id] = m end
-- the Smith's work, by the weapon's rarity now
Vault.WORK = {
	reforge = {Uncommon = 60, Rare = 160, Epic = 380, Legendary = 900},
	temper = {Common = 120, Uncommon = 320, Rare = 850},
}

local function uid() return HttpService:GenerateGUID(false):sub(1, 8) end
local function today() return math.floor(os.time() / 86400) end

function Vault.of(plr)
	local p = Profile.get(plr)
	local v = p.vault
	if type(v) ~= "table" then v = {}; p.vault = v end
	v.stash = type(v.stash) == "table" and v.stash or {}
	v.kit = type(v.kit) == "table" and v.kit or {}
	v.kit.relics = type(v.kit.relics) == "table" and v.kit.relics or {}
	v.kit.potions = type(v.kit.potions) == "table" and v.kit.potions or {}
	v.gold = tonumber(v.gold) or 0
	v.raids = tonumber(v.raids) or 0
	v.out = tonumber(v.out) or 0
	return v
end

-- what something is worth to the merchants (a valuable: its own worth; the free kit: nothing)
function Vault.value(item)
	if not item or item.free then return 0 end
	if item.kind == "treasure" then
		local t = CFG.TREASURE and CFG.TREASURE[item.treasure]
		return t and t.value or 10
	end
	if item.kind == "gold" then return item.gold or 0 end
	return math.floor((CFG.VALUE[item.rarity or "Common"] or 10) * (KIND_VALUE[item.kind] or 1))
end

-- today's wares at the Smith (for your class), rolled once a day
local function stockOf(plr, v)
	local classId = Profile.get(plr).active
	if type(v.stock) ~= "table" or v.stock.day ~= today() or v.stock.class ~= classId then
		local items = {}
		for _, w in ipairs(Vault.MERCHANT.Smith.wares) do
			local it = Loot.weapon(classId, 0, w.weapon)
			if it then table.insert(items, {item = it, price = w.price}) end
		end
		v.stock = {day = today(), class = classId, items = items}
		Profile.markDirty(plr)
	end
	return v.stock
end

local function kitList(v)
	local out = {}
	for _, k in ipairs({"weapon1", "weapon2", "armor"}) do if v.kit[k] then table.insert(out, {slot = k, item = v.kit[k]}) end end
	for i, it in ipairs(v.kit.relics) do table.insert(out, {slot = "relic" .. i, item = it}) end
	for i, it in ipairs(v.kit.potions) do table.insert(out, {slot = "potion" .. i, item = it}) end
	return out
end
local function card(it)
	local c = Loot.card(it)
	c.value = Vault.value(it)
	if it.kind == "weapon" then
		c.reforge = Vault.WORK.reforge[it.rarity or "Common"]
		c.temper = Vault.WORK.temper[it.rarity or "Common"]
	end
	return c
end

function Vault.view(plr)
	local v = Vault.of(plr)
	local stash = {}
	for _, it in ipairs(v.stash) do table.insert(stash, card(it)) end
	local kit = {}
	for _, e in ipairs(kitList(v)) do local c = card(e.item); c.slot = e.slot; table.insert(kit, c) end
	local merchants = {}
	local stock = stockOf(plr, v)
	for _, m in ipairs(Vault.MERCHANTS) do
		local wares = {}
		if m.id == "Smith" then
			for i, s in ipairs(stock.items) do
				local c = card(s.item); c.price = s.price; c.sold = s.sold == true; c.index = i
				table.insert(wares, c)
			end
		else
			for i, w in ipairs(m.wares) do
				local it = w.potion and {kind = "potion", potion = w.potion, rarity = CFG.POTION[w.potion] and CFG.POTION[w.potion].rarity or "Common", name = CFG.POTION[w.potion] and CFG.POTION[w.potion].name or w.potion}
					or (w.armor and {kind = "armor", armor = w.armor, rarity = CFG.ARMOR_BY[w.armor] and CFG.ARMOR_BY[w.armor].rarity or "Common", name = CFG.ARMOR_BY[w.armor] and CFG.ARMOR_BY[w.armor].name or w.armor})
				if it then local c = Loot.card(it); c.price = w.price; c.index = i; table.insert(wares, c) end
			end
		end
		table.insert(merchants, {id = m.id, name = m.name, glyph = m.glyph, line = m.line, wares = wares})
	end
	local p = Profile.get(plr)
	local classes = {}
	for _, id in ipairs(GameConfig.CLASS_ORDER) do
		table.insert(classes, {id = id, name = GameConfig.CLASSES[id].name, open = not Catalog.classOpen or Catalog.classOpen(id, p)})
	end
	local cls = GameConfig.CLASSES[p.active]
	local function wname(id) local w = id and Catalog.WEAPON[id]; return w and (w.name or id) or nil end
	return {stash = stash, kit = kit, gold = v.gold, raids = v.raids, out = v.out, max = Vault.STASH_MAX, merchants = merchants,
		class = p.active, classes = classes, relicsMax = Vault.RELICS, potionsMax = Vault.POTIONS,
		free = cls and {wname(cls.primary), wname(cls.secondary)} or {}}
end

local function findStash(v, id)
	for i, it in ipairs(v.stash) do if it.uid == id then return i, it end end
	return nil
end
local function findKit(v, id)
	for _, k in ipairs({"weapon1", "weapon2", "armor"}) do if v.kit[k] and v.kit[k].uid == id then return v.kit[k] end end
	for _, list in ipairs({v.kit.relics, v.kit.potions}) do for _, it in ipairs(list) do if it.uid == id then return it end end end
	return nil
end

function Vault.equip(plr, id)
	local v = Vault.of(plr)
	local i, it = findStash(v, id)
	if not it then return false, "not in your stash" end
	local back
	if it.kind == "weapon" then
		-- (the first free hand; both full: in place of the sidearm)
		local k = not v.kit.weapon1 and "weapon1" or (not v.kit.weapon2 and "weapon2" or "weapon2")
		back = v.kit[k]; v.kit[k] = it
	elseif it.kind == "armor" then back = v.kit.armor; v.kit.armor = it
	elseif it.kind == "relic" then
		if #v.kit.relics >= Vault.RELICS then return false, "three relics at most" end
		table.insert(v.kit.relics, it)
	elseif it.kind == "potion" then
		if #v.kit.potions >= Vault.POTIONS then return false, Vault.POTIONS .. " draughts at most" end
		table.insert(v.kit.potions, it)
	else return false, "that only sells" end
	table.remove(v.stash, i)
	if back then table.insert(v.stash, back) end
	Profile.markDirty(plr)
	return true
end

function Vault.unequip(plr, id)
	local v = Vault.of(plr)
	if #v.stash >= Vault.STASH_MAX then return false, "your stash is full" end
	for _, k in ipairs({"weapon1", "weapon2", "armor"}) do
		if v.kit[k] and v.kit[k].uid == id then table.insert(v.stash, v.kit[k]); v.kit[k] = nil; Profile.markDirty(plr); return true end
	end
	for _, list in ipairs({v.kit.relics, v.kit.potions}) do
		for i, it in ipairs(list) do
			if it.uid == id then table.insert(v.stash, it); table.remove(list, i); Profile.markDirty(plr); return true end
		end
	end
	return false, "not in your kit"
end

function Vault.sell(plr, id)
	local v = Vault.of(plr)
	local i, it = findStash(v, id)
	if not it then return false, "not in your stash" end
	local g = Vault.value(it)
	if g <= 0 then return false, "nobody pays for that" end
	table.remove(v.stash, i)
	v.gold += g
	Profile.markDirty(plr)
	return true, g
end

function Vault.buy(plr, merchantId, index)
	local v = Vault.of(plr)
	local m = Vault.MERCHANT[merchantId]
	if not m or type(index) ~= "number" then return false, "no such thing" end
	if #v.stash >= Vault.STASH_MAX then return false, "your stash is full" end
	local item, price
	if m.id == "Smith" then
		local s = stockOf(plr, v).items[index]
		if not s then return false, "no such thing" end
		if s.sold then return false, "sold: more tomorrow" end
		if v.gold < s.price then return false, "not enough gold" end
		s.sold = true
		item, price = table.clone(s.item), s.price
		item.uid = uid()
	else
		local w = m.wares[index]
		if not w then return false, "no such thing" end
		if v.gold < w.price then return false, "not enough gold" end
		price = w.price
		if w.potion then
			local p = CFG.POTION[w.potion]
			item = {kind = "potion", uid = uid(), potion = w.potion, rarity = p and p.rarity or "Common", name = p and p.name or w.potion}
		elseif w.armor then
			local a = CFG.ARMOR_BY[w.armor]
			item = {kind = "armor", uid = uid(), armor = w.armor, rarity = a and a.rarity or "Common", name = a and a.name or w.armor}
		end
	end
	if not item then return false, "the merchant has none" end
	v.gold -= price
	table.insert(v.stash, item)
	Profile.markDirty(plr)
	return true, item
end

-- the Smith's work on a weapon in your stash or kit
function Vault.work(plr, id, kind)
	local v = Vault.of(plr)
	local _, it = findStash(v, id)
	it = it or findKit(v, id)
	if not (it and it.kind == "weapon") then return false, "bring him a weapon" end
	if it.free then return false, "not worth his time" end
	local cost = Vault.WORK[kind] and Vault.WORK[kind][it.rarity or "Common"]
	if not cost then return false, kind == "temper" and "it's as fine as he can make it" or "nothing to reforge" end
	if v.gold < cost then return false, "not enough gold" end
	v.gold -= cost
	Loot.reforge(it, kind == "temper")
	Profile.markDirty(plr)
	return true, it
end

-- the class you raid as (the spawn screen asks too)
function Vault.setClass(plr, classId)
	local p = Profile.get(plr)
	if not GameConfig.CLASSES[classId] then return false, "no such class" end
	if Catalog.classOpen and not Catalog.classOpen(classId, p) then return false, "not open to you yet" end
	p.active = classId
	Profile.markDirty(plr)
	return true
end

-- into the raid: the kit leaves the vault (what you bring, you can lose)
function Vault.takeKit(plr)
	local v = Vault.of(plr)
	local kit = v.kit
	v.kit = {relics = {}, potions = {}}
	v.raids += 1
	Profile.markDirty(plr)
	return kit
end

-- out of the raid alive: everything carried goes in (what doesn't fit is sold)
function Vault.bank(plr, items, gold)
	local v = Vault.of(plr)
	local sold = 0
	for _, it in ipairs(items or {}) do
		if it.kind == "gold" then v.gold += it.gold or 0
		elseif #v.stash < Vault.STASH_MAX then table.insert(v.stash, it)
		else sold += Vault.value(it) end
	end
	v.gold += (gold or 0) + sold
	v.out += 1
	Profile.markDirty(plr)
	return sold
end

return Vault
