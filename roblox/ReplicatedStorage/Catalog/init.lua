--[[ CATALOG — everything the game can sell, equip or roll, read from the
     config ModuleScripts INSIDE this module (Catalog ▸ Weights, Packs, Pieces,
     Weapons, Skins, Body, Palette, Crates, Economy, Contracts). Server and
     client both require it. To add content you edit those children and drop
     models into ReplicatedStorage ▸ Cosmetics — never this file.

       Catalog.WEIGHTS / PACKS / PIECES / WEAPONS / SKINS / BODY / PALETTE /
       CRATES / ECONOMY / CONTRACTS          the tables, validated
       Catalog.PIECE[id]  Catalog.WEAPON[id]  Catalog.SKIN[id]  Catalog.COLOR[name]
       Catalog.piecesFor(slot, weight)       list, free first
       Catalog.pieceModels(id)               {ModelName = Model} to weld on (see Dresser)
       Catalog.skinModel(skinId) / weaponModel(weaponId) / bodyModel(kind, id)
       Catalog.rig()                         the preview rig template (Cosmetics.Rig) or nil
       Catalog.unlocked(unlock, profile) / unlockProgress / unlockText   kill / level / win / task unlocks
       Catalog.skinSource(skin)              "crate" | "earned" | "pack" | "shop" | "free"
       Catalog.skinOffers(day) / skinOnSale(id, day)   the store's daily WEAPONS section

     SKINS ARE NEVER SOLD AT WILL: a skin comes out of a crate, is earned
     (kills with the weapon, daily tasks done: its `unlock`), comes with a pack
     on the days the pack is in the store, or is one of the day's WEAPONS
     offers (a priced skin with no crate / pack / unlock; Catalog ▸ Store).

     ARMOR SETS ARE AUTO-IMPORTED: every set folder in Cosmetics ▸ Armor (the
     server mirrors ServerStorage ▸ Armor there) becomes three pieces —
     <Set>_Helm, <Set>_Top, <Set>_Legs — of the set's Config.Type weight, in
     the pack its Config names (default: the free starter pack of that
     weight). So your existing sets need no entry in Pieces at all. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Catalog = {}
local function child(name) return require(script:WaitForChild(name)) end

Catalog.WEIGHTS   = child("Weights")
Catalog.PACKS     = child("Packs")
local PiecesCfg   = child("Pieces")
Catalog.WEAPONS   = child("Weapons")
Catalog.SKINS     = child("Skins")
Catalog.BODY      = child("Body")
Catalog.PALETTE   = child("Palette")
Catalog.CRATES    = child("Crates")
Catalog.ECONOMY   = child("Economy")
Catalog.CONTRACTS = child("Contracts")
Catalog.STORE     = child("Store")

Catalog.SLOTS = {"helmet", "top", "bottom"}
Catalog.SLOT_MODELS = {   -- which clothing models (Armor.lua names) each slot wears
	helmet = {"HeadClothing"},
	top    = {"TorsoClothing", "LeftArmClothing", "RightArmClothing"},
	bottom = {"LeftLegClothing", "RightLegClothing"},
}
Catalog.RARITIES = {"Common", "Rare", "Epic", "Legendary"}

--------------------------------------------------------------------
--  ASSET FOLDERS (ReplicatedStorage ▸ Cosmetics ▸ …)
--------------------------------------------------------------------
function Catalog.assets()
	return ReplicatedStorage:FindFirstChild("Cosmetics")
end
local function sub(name)
	local a = Catalog.assets()
	return a and a:FindFirstChild(name) or nil
end
function Catalog.rig()
	local r = sub("Rig")
	return r and r:IsA("Model") and r or nil
end

--------------------------------------------------------------------
--  PIECES: explicit entries + auto-imported sets
--------------------------------------------------------------------
local function setConfig(folder)
	local cfg = {Type = "Light"}
	local mod = folder:FindFirstChild("Config")
	if mod and mod:IsA("ModuleScript") then
		local ok, t = pcall(require, mod)
		if ok and type(t) == "table" then for k, v in pairs(t) do cfg[k] = v end end
	end
	return cfg
end

local function autoPieces()
	local out = {}
	local armor = sub("Armor")
	if not (PiecesCfg.AUTO_FROM_SETS and armor) then return out end
	for _, set in ipairs(armor:GetChildren()) do
		local cfg = setConfig(set)
		local weight = Catalog.WEIGHTS[cfg.Type] and cfg.Type or "Light"
		local pack = cfg.Pack or ("Starter_" .. weight)
		local base = cfg.Name or set.Name
		local defs = {
			{suffix = "Helm", slot = "helmet", label = cfg.HelmName or (base .. " Helm"), covers = cfg.Covers or {"Hair"}},
			{suffix = "Top",  slot = "top",    label = cfg.TopName or (base .. " Top")},
			{suffix = "Legs", slot = "bottom", label = cfg.LegsName or (base .. " Legs")},
		}
		for _, d in ipairs(defs) do
			-- only slots the set actually has models for
			local has = false
			for _, mn in ipairs(Catalog.SLOT_MODELS[d.slot]) do if set:FindFirstChild(mn) then has = true end end
			if has then
				table.insert(out, {
					id = set.Name .. "_" .. d.suffix, name = d.label, slot = d.slot, weight = weight, pack = pack,
					rarity = cfg.Rarity or "Common", marks = cfg.PriceMarks or 0, crowns = cfg.PriceCrowns or 0,
					covers = d.slot == "helmet" and d.covers or nil, set = set.Name, setName = base, auto = true,
					description = cfg.Description,
				})
			end
		end
	end
	return out
end

function Catalog.rebuild()
	local list, byId = {}, {}
	for _, p in ipairs(autoPieces()) do table.insert(list, p); byId[p.id] = p end
	for _, p in ipairs(PiecesCfg.PIECES or {}) do
		if byId[p.id] then
			for k, v in pairs(p) do byId[p.id][k] = v end     -- an explicit entry overrides an auto one
		else
			p.weight = p.weight or (Catalog.PACKS[p.pack] and Catalog.PACKS[p.pack].weight) or "Light"
			p.marks, p.crowns = p.marks or 0, p.crowns or 0
			p.rarity = p.rarity or "Common"
			table.insert(list, p); byId[p.id] = p
		end
	end
	-- packs that only exist through auto pieces get a default entry
	for _, p in ipairs(list) do
		if not Catalog.PACKS[p.pack] then
			Catalog.PACKS[p.pack] = {name = p.pack:gsub("_", " "), weight = p.weight, free = true}
		end
	end
	Catalog.PIECES, Catalog.PIECE = list, byId
end
Catalog.rebuild()

Catalog.WEAPON = {} for _, w in ipairs(Catalog.WEAPONS) do Catalog.WEAPON[w.id] = w end
Catalog.SKIN = {}
for _, s in ipairs(Catalog.SKINS) do
	s.id = s.weapon .. ":" .. s.name
	-- kill-count skins are unlocks like any other earned thing
	if s.crate == "earned" and not s.unlock then s.unlock = {kills = s.kills or 100, weapon = s.weapon} end
	Catalog.SKIN[s.id] = s
end
Catalog.COLOR = {}  for _, c in ipairs(Catalog.PALETTE) do Catalog.COLOR[c.name] = c end

--------------------------------------------------------------------
--  QUERIES
--------------------------------------------------------------------
-- free = costs nothing and is not earned (earned pieces carry an `unlock`)
function Catalog.isFree(piece) return (piece.marks or 0) == 0 and (piece.crowns or 0) == 0 and piece.unlock == nil end

--------------------------------------------------------------------
--  UNLOCKS — shared by weapons, earned pieces and earned titles
--    {free = true} | {level = n} | {kills = n[, family = F | weapon = W]}
--    | {wins = n[, bracket = "1v1"]} | {stat = "parry", n = 500}
--  p is a profile (server) or its summary (client): level + stats
--------------------------------------------------------------------
local function unlockKey(u)
	if u.kills then
		if u.weapon then return nil, u.kills end
		return u.family and ("kill_" .. u.family) or "kill", u.kills
	elseif u.wins then return u.bracket and ("win_" .. u.bracket) or "win", u.wins
	elseif u.stat then return u.stat, u.n or 1 end
	return nil, nil
end
-- have, need (need = nil for free / level unlocks)
function Catalog.unlockProgress(u, p)
	if not u or u.free then return 1, nil end
	local stats = p and p.stats or {}
	if u.level then return p and p.level or 1, u.level end
	local key, need = unlockKey(u)
	if u.kills and u.weapon then return (stats.byWeapon or {})[u.weapon] or 0, need end
	return key and (stats[key] or 0) or 0, need
end
function Catalog.unlocked(u, p)
	if not u or u.free then return true end
	if not p then return false end
	local have, need = Catalog.unlockProgress(u, p)
	return need ~= nil and have >= need
end
local FAMILY_WORD = {OneHanded = "one-handed", TwoHanded = "two-handed", Polearm = "polearm"}
local STAT_WORD = {contract = "daily tasks done", parry = "parries", chamber = "chambers", drill = "Tiltyard drills",
	round = "rounds played", hill = "seconds holding the hill", win = "round wins", kill = "kills"}
function Catalog.unlockText(u)
	if not u or u.free then return "free" end
	if u.level then return "level " .. u.level end
	if u.kills then
		if u.weapon then return string.format("%d kills with the %s", u.kills, Catalog.WEAPON and Catalog.WEAPON[u.weapon] and Catalog.WEAPON[u.weapon].name or u.weapon) end
		return string.format("%d %skills", u.kills, u.family and (FAMILY_WORD[u.family] or string.lower(u.family)) .. " " or "")
	end
	if u.wins then return string.format("%d %swins", u.wins, u.bracket and (u.bracket .. " ") or "round ") end
	if u.stat then return string.format("%d %s", u.n or 1, STAT_WORD[u.stat] or ("× " .. u.stat)) end
	return "?"
end

function Catalog.piecesFor(slot, weight)
	local out = {}
	for _, p in ipairs(Catalog.PIECES) do if p.slot == slot and p.weight == weight then table.insert(out, p) end end
	table.sort(out, function(a, b)
		local fa, fb = Catalog.isFree(a), Catalog.isFree(b)
		if fa ~= fb then return fa end
		return a.name < b.name
	end)
	return out
end

-- the first free piece for a slot and weight (what a new player wears)
function Catalog.defaultPiece(slot, weight)
	for _, p in ipairs(Catalog.piecesFor(slot, weight)) do if Catalog.isFree(p) then return p end end
	return Catalog.piecesFor(slot, weight)[1]
end

-- {ModelName = Model} for a piece: from its set folder (auto) or its own
-- folder in Cosmetics ▸ Pieces ▸ <id> (explicit)
function Catalog.pieceModels(id)
	local p = Catalog.PIECE[id]
	if not p then return {} end
	local folder
	if p.set then folder = sub("Armor") and sub("Armor"):FindFirstChild(p.set)
	else local pf = sub("Pieces"); folder = pf and pf:FindFirstChild(p.model or p.id) end
	local out = {}
	if folder then
		for _, mn in ipairs(Catalog.SLOT_MODELS[p.slot]) do
			local m = folder:FindFirstChild(mn)
			if m then out[mn] = m end
		end
	end
	return out
end

function Catalog.skinModel(skinId)
	local s = Catalog.SKIN[skinId]
	local f = s and sub("Skins")
	local wf = f and f:FindFirstChild(s.weapon)
	local m = wf and wf:FindFirstChild(s.model or s.name)
	return m
end
function Catalog.weaponModel(weaponId)
	local f = sub("Weapons")
	return f and f:FindFirstChild(weaponId) or nil
end
function Catalog.bodyModel(kind, id)   -- kind: "Hair" | "Beard"
	local f = sub("Body")
	local kf = f and f:FindFirstChild(kind)
	return kf and kf:FindFirstChild(id) or nil
end

function Catalog.skinsFor(weaponId)
	local out = {}
	for _, s in ipairs(Catalog.SKINS) do if s.weapon == weaponId then table.insert(out, s) end end
	return out
end

--------------------------------------------------------------------
--  STORE — which packs are on sale on a given UTC day (Catalog ▸ Store)
--------------------------------------------------------------------
local function dayNumber(dateKey)   -- "YYYY-MM-DD" → days since 1970 (UTC)
	local y, m, d = dateKey:match("^(%d+)%-(%d+)%-(%d+)$")
	if not y then return 0 end
	return math.floor(os.time({year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12}) / 86400)
end
-- the packs on sale on `dateKey` (default: today, UTC) and when that day ends
function Catalog.storeFor(dateKey)
	dateKey = dateKey or os.date("!%Y-%m-%d")
	local S = Catalog.STORE or {}
	local retired = {}
	for _, k in ipairs(S.retired or {}) do retired[k] = true end
	local out, seen = {}, {}
	local function add(k) if Catalog.PACKS[k] and not retired[k] and not seen[k] then seen[k] = true; table.insert(out, k) end end
	for _, k in ipairs(S.always or {}) do add(k) end
	local pinned = S.pins and S.pins[dateKey]
	if pinned then
		for _, k in ipairs(pinned) do add(k) end
	else
		local queue = {}
		for _, k in ipairs(S.queue or {}) do if not retired[k] then table.insert(queue, k) end end
		local n, slots = #queue, math.max(1, S.slots or 3)
		if n > 0 then
			local day = dayNumber(dateKey) - dayNumber(S.epoch or "2026-01-01")
			local start = (day * slots) % n
			for i = 0, math.min(slots, n) - 1 do add(queue[(start + i) % n + 1]) end
		end
	end
	-- the day ends at the next UTC midnight
	local now = os.time()
	local endsAt = (math.floor(now / 86400) + 1) * 86400
	return out, dateKey, endsAt
end
function Catalog.onSale(packKey, dateKey)
	local pk = Catalog.PACKS[packKey]
	if not pk then return false end
	if pk.free or pk.earned then return true end
	for _, k in ipairs((Catalog.storeFor(dateKey))) do if k == packKey then return true end end
	return false
end

--------------------------------------------------------------------
--  SKIN SOURCES + the store's daily WEAPONS section
--------------------------------------------------------------------
function Catalog.skinSource(s)
	if not s then return "free" end
	if s.unlock then return "earned" end
	if s.crate then return "crate" end
	if s.pack then return "pack" end
	if (s.marks or 0) > 0 or (s.crowns or 0) > 0 then return "shop" end
	return "free"
end

-- today's WEAPONS offers (skin ids; the first is the headliner, Epic or
-- better when the pool has one). Drawn by the date from the shop skins, one
-- per weapon, so everyone sees the same; Store.skinPins fixes a day.
function Catalog.skinOffers(dateKey)
	dateKey = dateKey or os.date("!%Y-%m-%d")
	local S = Catalog.STORE or {}
	local retired = {}
	for _, id in ipairs(S.skinRetired or {}) do retired[id] = true end
	local out = {}
	local pinned = S.skinPins and S.skinPins[dateKey]
	if pinned then
		for _, id in ipairs(pinned) do if Catalog.SKIN[id] and not retired[id] then table.insert(out, id) end end
		return out
	end
	local pool = {}
	for _, s in ipairs(Catalog.SKINS) do
		if Catalog.skinSource(s) == "shop" and not retired[s.id] then table.insert(pool, s) end
	end
	table.sort(pool, function(a, b) return a.id < b.id end)
	local rng = Random.new(dayNumber(dateKey) * 7919 + 17)
	for i = #pool, 2, -1 do local j = rng:NextInteger(1, i); pool[i], pool[j] = pool[j], pool[i] end
	local slots = math.max(1, S.skinSlots or 4)
	-- one weapon and one style each, so the shelf is never four of a kind
	local usedWeapon, usedName = {}, {}
	local function take(s) table.insert(out, s.id); usedWeapon[s.weapon] = true; usedName[s.name] = true end
	for _, s in ipairs(pool) do
		if s.rarity == "Legendary" or s.rarity == "Epic" then take(s); break end
	end
	for _, s in ipairs(pool) do
		if #out >= slots then break end
		if not usedWeapon[s.weapon] and not usedName[s.name] then take(s) end
	end
	return out
end

-- can this skin be bought today (alone, or as part of its pack)?
function Catalog.skinOnSale(skinId, dateKey)
	local s = Catalog.SKIN[skinId]
	if not s then return false end
	local src = Catalog.skinSource(s)
	if src == "pack" then return Catalog.onSale(s.pack, dateKey) end
	if src == "shop" then
		for _, id in ipairs(Catalog.skinOffers(dateKey)) do if id == skinId then return true end end
	end
	return false
end

function Catalog.crateSkins(crateId)
	local c = Catalog.CRATES[crateId]
	local out = {}
	if not c then return out end
	for _, s in ipairs(Catalog.SKINS) do
		if s.crate == crateId then table.insert(out, s) end
	end
	for _, id in ipairs(c.skins or {}) do if Catalog.SKIN[id] then table.insert(out, Catalog.SKIN[id]) end end
	return out
end

--------------------------------------------------------------------
--  VALIDATION (warns once, server only)
--------------------------------------------------------------------
if RunService:IsServer() then
	task.defer(function()
		for _, p in ipairs(Catalog.PIECES) do
			if not Catalog.WEIGHTS[p.weight] then warn("[Catalog] piece", p.id, "has unknown weight", p.weight) end
			if not Catalog.PACKS[p.pack] then warn("[Catalog] piece", p.id, "names unknown pack", p.pack) end
			if next(Catalog.pieceModels(p.id)) == nil then warn("[Catalog] piece", p.id, "has no models (Cosmetics ▸ Pieces ▸ " .. (p.model or p.id) .. " or its set folder)") end
		end
		local okT, SkinTrims = pcall(require, ReplicatedStorage:WaitForChild("SkinTrims", 5))
		local trims = {}
		if okT and SkinTrims then for _, n in ipairs(SkinTrims.NAMES) do trims[n] = true end end
		local seen = {}
		for _, s in ipairs(Catalog.SKINS) do
			if not Catalog.WEAPON[s.weapon] then warn("[Catalog] skin", s.id, "names unknown weapon", s.weapon) end
			if s.crate and s.crate ~= "earned" and not Catalog.CRATES[s.crate] then warn("[Catalog] skin", s.id, "names unknown crate", s.crate) end
			if s.trim and okT and not trims[s.trim] then warn("[Catalog] skin", s.id, "names unknown trim", s.trim) end
			if seen[s.id] then warn("[Catalog] skin", s.id, "is listed twice") end
			seen[s.id] = true
		end
		for _, p in ipairs(Catalog.PIECES) do
			if p.unlock and ((p.marks or 0) > 0 or (p.crowns or 0) > 0) then warn("[Catalog] piece", p.id, "is both earned and priced; the unlock wins") end
		end
		for _, t in ipairs(Catalog.BODY.earnedTitles or {}) do
			if not t.title or not t.unlock then warn("[Catalog] earned title needs title + unlock") end
		end
	end)
end

return Catalog
