--[[ VAULT — Deadvault's persistent side (Game ▸ Modes ▸ Deadvault): what you've brought out of
     the raids, kept in your profile (Profile ▸ vault). Nothing in it touches your collection:
     these are the raids' own things (Catalog ▸ Loot), and vault gold is its own coin.

       vault.stash   up to STASH_MAX items (Loot items: weapons, armour, relics, potions, tomes)
       vault.kit     what you'll take in next time: weapon1, weapon2, armor, relics (3), potions (3)
       vault.gold    the merchant's coin (sell finds, buy a kit)
       vault.raids / vault.out   raids gone into / got out of

       Vault.view(plr)              everything a screen shows (cards: Game ▸ Loot.card)
       Vault.equip(plr, uid)        stash → kit (what was in the slot goes back to the stash)
       Vault.unequip(plr, uid)      kit → stash
       Vault.sell(plr, uid)         stash → gold (Catalog ▸ Loot VALUE by rarity)
       Vault.buy(plr, id)           the merchant's (SHOP) → stash, for gold
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
Vault.STASH_MAX = 30
Vault.RELICS, Vault.POTIONS = 3, 3
local CFG = Catalog.LOOT
local KIND_VALUE = {weapon = 1, armor = 1, relic = 1.5, potion = 0.4, tome = 1.2}

-- THE MERCHANT: plain things for a kit (gold)
Vault.SHOP = {
	{id = "Healing", name = "Healing Draught", price = 25, make = function() return Loot.potion(0) end, potion = "Healing"},
	{id = "Fury", name = "Elixir of Fury", price = 60, potion = "Fury"},
	{id = "Padded", name = "Padded Jack", price = 50, armor = "Padded"},
	{id = "Mail", name = "Mail Hauberk", price = 140, armor = "Mail"},
	{id = "Steel", name = "A plain weapon for your class", price = 40, weapon = "Common"},
	{id = "Fine", name = "A fine weapon for your class", price = 160, weapon = "Uncommon"},
}

local function uid() return HttpService:GenerateGUID(false):sub(1, 8) end

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

function Vault.value(item)
	return math.floor((CFG.VALUE[item.rarity or "Common"] or 10) * (KIND_VALUE[item.kind] or 1) + (item.kind == "gold" and (item.gold or 0) or 0))
end

local function kitList(v)
	local out = {}
	for _, k in ipairs({"weapon1", "weapon2", "armor"}) do if v.kit[k] then table.insert(out, {slot = k, item = v.kit[k]}) end end
	for i, it in ipairs(v.kit.relics) do table.insert(out, {slot = "relic" .. i, item = it}) end
	for i, it in ipairs(v.kit.potions) do table.insert(out, {slot = "potion" .. i, item = it}) end
	return out
end

function Vault.view(plr)
	local v = Vault.of(plr)
	local stash = {}
	for _, it in ipairs(v.stash) do local c = Loot.card(it); c.value = Vault.value(it); table.insert(stash, c) end
	local kit = {}
	for _, e in ipairs(kitList(v)) do local c = Loot.card(e.item); c.slot = e.slot; c.value = Vault.value(e.item); table.insert(kit, c) end
	local shop = {}
	for _, s in ipairs(Vault.SHOP) do table.insert(shop, {id = s.id, name = s.name, price = s.price}) end
	return {stash = stash, kit = kit, gold = v.gold, raids = v.raids, out = v.out, max = Vault.STASH_MAX, shop = shop,
		class = Profile.get(plr).active}
end

local function findStash(v, id)
	for i, it in ipairs(v.stash) do if it.uid == id then return i, it end end
	return nil
end

function Vault.equip(plr, id)
	local v = Vault.of(plr)
	local i, it = findStash(v, id)
	if not it then return false, "not in your stash" end
	local back
	if it.kind == "weapon" then
		local k = (it.slot == 2) and "weapon2" or "weapon1"
		-- (a weapon your class can't carry stays put)
		local cls = GameConfig.CLASSES[Profile.get(plr).active]
		local w = Catalog.WEAPON[it.weapon]
		if cls and w and not (Catalog.weaponFits(cls, w, "primary") or Catalog.weaponFits(cls, w, "secondary")) then return false, "your class can't carry that" end
		back = v.kit[k]; v.kit[k] = it
	elseif it.kind == "armor" then back = v.kit.armor; v.kit.armor = it
	elseif it.kind == "relic" then
		if #v.kit.relics >= Vault.RELICS then return false, "three relics at most" end
		table.insert(v.kit.relics, it)
	elseif it.kind == "potion" then
		if #v.kit.potions >= Vault.POTIONS then return false, "three potions at most" end
		table.insert(v.kit.potions, it)
	else return false, "that can't be taken in" end
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
	table.remove(v.stash, i)
	local g = Vault.value(it)
	v.gold += g
	Profile.markDirty(plr)
	return true, g
end

function Vault.buy(plr, id)
	local v = Vault.of(plr)
	local s
	for _, x in ipairs(Vault.SHOP) do if x.id == id then s = x end end
	if not s then return false, "no such thing" end
	if v.gold < s.price then return false, "not enough gold" end
	if #v.stash >= Vault.STASH_MAX then return false, "your stash is full" end
	local item
	if s.potion then
		local p = CFG.POTION[s.potion]
		item = {kind = "potion", uid = uid(), potion = s.potion, rarity = p and p.rarity or "Common", name = p and p.name or s.name}
	elseif s.armor then item = Loot.armor(0, CFG.ARMOR_BY[s.armor] and CFG.ARMOR_BY[s.armor].rarity or "Common")
	elseif s.weapon then item = Loot.weapon(Profile.get(plr).active, 0, s.weapon) end
	if not item then return false, "the merchant has none" end
	v.gold -= s.price
	table.insert(v.stash, item)
	Profile.markDirty(plr)
	return true, item
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
