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
       Catalog.unlocked(unlock, profile) / unlockProgress / unlockText   kill / level / win unlocks

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
					covers = d.slot == "helmet" and d.covers or nil, set = set.Name, auto = true,
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
Catalog.SKIN = {}   for _, s in ipairs(Catalog.SKINS) do s.id = s.weapon .. ":" .. s.name; Catalog.SKIN[s.id] = s end
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
function Catalog.unlockText(u)
	if not u or u.free then return "free" end
	if u.level then return "level " .. u.level end
	if u.kills then
		if u.weapon then return string.format("%d kills with the %s", u.kills, Catalog.WEAPON and Catalog.WEAPON[u.weapon] and Catalog.WEAPON[u.weapon].name or u.weapon) end
		return string.format("%d %skills", u.kills, u.family and (FAMILY_WORD[u.family] or string.lower(u.family)) .. " " or "")
	end
	if u.wins then return string.format("%d %swins", u.wins, u.bracket and (u.bracket .. " ") or "round ") end
	if u.stat then return string.format("%d × %s", u.n or 1, u.stat) end
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
		for _, s in ipairs(Catalog.SKINS) do
			if not Catalog.WEAPON[s.weapon] then warn("[Catalog] skin", s.id, "names unknown weapon", s.weapon) end
			if s.crate and s.crate ~= "earned" and not Catalog.CRATES[s.crate] then warn("[Catalog] skin", s.id, "names unknown crate", s.crate) end
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
