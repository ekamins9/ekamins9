--[[ PROFILE v2 — one saved record per player (DataStore "Profiles_v2"):
       wallet      {marks, crowns}
       level, xp   account level (Catalog.ECONOMY.levels)
       appearance  {skin, hair, hairColor, beard, face, title}
       owned       {pieces = {id=true}, skins = {}, weapons = {}, colors = {}, hairColors = {}, beards = {}, titles = {}}
       classes     {[classId] = {helmet, top, bottom, colors = {Primary, Secondary, Accent, Metal}, weapon, weaponSkin, secondary, secondarySkin}}
       active      classId
       stats       counters ("kill", "parry", "kill_TwoHanded", "win_1v1", …) and byWeapon = {Greatsword = kills}
       rating      {["1v1"] = 1500, …}, placements = {["1v1"] = n}
       crates      {[crateId] = {opens, sinceLegendary}}
       contracts   {day = "2026-10-02", items = {{id, n, done}}, week = "2026-W40", weekly = {id, n, done}}
       receipts    {[receiptId] = true}       lastWinDay
     Loaded on join, saved on leave and every AUTOSAVE seconds while dirty.
     A v1 profile (classes with armor = set id) is migrated on first load. ]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Catalog    = require(ReplicatedStorage:WaitForChild("Catalog"))

local Profile = {}
local STORE, OLD_STORE = "Profiles_v2", "Profiles_v1"
local AUTOSAVE = 60

local store, oldStore
local warned = false
local function getStore()
	if store then return store end
	local ok, s = pcall(DataStoreService.GetDataStore, DataStoreService, STORE)
	if ok then store = s; pcall(function() oldStore = DataStoreService:GetDataStore(OLD_STORE) end)
	elseif not warned then warned = true; warn("[Profile] DataStore unavailable:", s) end
	return store
end

local cache, dirty = {}, {}

function Profile.defaultLoadout(classId)
	local cls = GameConfig.CLASSES[classId]
	local w = cls and cls.weight or "Light"
	local function d(slot) local p = Catalog.defaultPiece(slot, w); return p and p.id or nil end
	local weapon
	for _, wd in ipairs(Catalog.WEAPONS) do if wd.unlock.free then weapon = wd.id; break end end
	return {helmet = d("helmet"), top = d("top"), bottom = d("bottom"),
		colors = {Primary = "Navy", Secondary = "Slate", Accent = "Ochre", Metal = "Ash"},
		weapon = weapon, weaponSkin = weapon and (weapon .. ":Default") or nil, secondary = nil, secondarySkin = nil}
end

local function default()
	local p = {version = 2, wallet = {marks = 500, crowns = 0}, level = 1, xp = 0,
		appearance = {}, owned = {pieces = {}, skins = {}, weapons = {}, colors = {}, hairColors = {}, beards = {}, titles = {}},
		classes = {}, active = GameConfig.DEFAULT_CLASS, stats = {byWeapon = {}}, rating = {}, placements = {},
		crates = {}, contracts = {}, receipts = {}, lastWinDay = "", queueLock = {}}
	for k, v in pairs(Catalog.BODY.defaults) do p.appearance[k] = v end
	for id in pairs(GameConfig.CLASSES) do p.classes[id] = Profile.defaultLoadout(id) end
	return p
end

-- v1 → v2: armor set id → the auto pieces of that set
local function migrate(old)
	local p = default()
	if type(old.classes) == "table" then
		for id, lo in pairs(old.classes) do
			if p.classes[id] and type(lo) == "table" then
				local set = lo.armor
				if set and Catalog.PIECE[set .. "_Helm"] then p.classes[id].helmet = set .. "_Helm" end
				if set and Catalog.PIECE[set .. "_Top"] then p.classes[id].top = set .. "_Top" end
				if set and Catalog.PIECE[set .. "_Legs"] then p.classes[id].bottom = set .. "_Legs" end
				if lo.weapon and Catalog.WEAPON[lo.weapon] then p.classes[id].weapon = lo.weapon; p.classes[id].weaponSkin = lo.weapon .. ":Default" end
				if lo.secondary and Catalog.WEAPON[lo.secondary] then p.classes[id].secondary = lo.secondary; p.classes[id].secondarySkin = lo.secondary .. ":Default" end
			end
		end
	end
	if GameConfig.CLASSES[old.active] then p.active = old.active end
	if type(old.stats) == "table" then for k, v in pairs(old.stats) do if type(v) == "number" then p.stats[k] = v end end end
	return p
end

local function fill(p)
	-- new fields on old v2 saves
	local d = default()
	for k, v in pairs(d) do if p[k] == nil then p[k] = v end end
	for k, v in pairs(d.owned) do if p.owned[k] == nil then p.owned[k] = v end end
	for id in pairs(GameConfig.CLASSES) do if not p.classes[id] then p.classes[id] = Profile.defaultLoadout(id) end end
	for k, v in pairs(Catalog.BODY.defaults) do if p.appearance[k] == nil then p.appearance[k] = v end end
	if not GameConfig.CLASSES[p.active] then p.active = GameConfig.DEFAULT_CLASS end
	p.stats.byWeapon = p.stats.byWeapon or {}
	return p
end

local function load(plr)
	local data
	local s = getStore()
	if s then
		local ok, v = pcall(s.GetAsync, s, "u" .. plr.UserId)
		if ok and type(v) == "table" then data = fill(v)
		elseif ok and oldStore then
			local ok2, old = pcall(oldStore.GetAsync, oldStore, "u" .. plr.UserId)
			if ok2 and type(old) == "table" then data = migrate(old); dirty[plr] = true end
		elseif not ok and not warned then warned = true; warn("[Profile] load failed:", v) end
	end
	data = data or default()
	cache[plr] = data
	return data
end

function Profile.get(plr) return cache[plr] or load(plr) end
function Profile.markDirty(plr) dirty[plr] = true end

local function save(plr)
	local data = cache[plr]
	local s = getStore()
	if not (data and s) then return end
	local ok, err = pcall(s.SetAsync, s, "u" .. plr.UserId, data)
	if not ok and not warned then warned = true; warn("[Profile] save failed:", err) end
	dirty[plr] = nil
end
Profile.save = save

--------------------------------------------------------------------
--  OWNERSHIP
--------------------------------------------------------------------
function Profile.has(plr, kind, id)
	local p = Profile.get(plr)
	if kind == "pieces" then local pc = Catalog.PIECE[id]; if pc and Catalog.isFree(pc) then return true end end
	if kind == "skins" and type(id) == "string" and id:match(":Default$") then return true end
	if kind == "weapons" then
		local w = Catalog.WEAPON[id]
		if w and w.unlock.free then return true end
		if w and w.unlock.level and p.level >= w.unlock.level then return true end
		if w and w.unlock.kills and (p.stats["kill_" .. (w.unlock.family or "")] or 0) >= w.unlock.kills then return true end
	end
	if kind == "colors" then local c = Catalog.COLOR[id]; if c and not c.crowns then return true end end
	if kind == "hairColors" then for _, h in ipairs(Catalog.BODY.hairColors) do if h.name == id and not h.crowns then return true end end end
	if kind == "beards" then for _, b in ipairs(Catalog.BODY.beards) do if b.id == id and not b.crowns then return true end end end
	if kind == "titles" then for _, t in ipairs(Catalog.BODY.titles) do if t == id then return true end end end
	return p.owned[kind] and p.owned[kind][id] == true
end
function Profile.grant(plr, kind, id)
	local p = Profile.get(plr)
	p.owned[kind] = p.owned[kind] or {}
	p.owned[kind][id] = true
	dirty[plr] = true
end

--------------------------------------------------------------------
--  LOADOUT VALIDATION (what the player may actually wear)
--------------------------------------------------------------------
function Profile.validateLoadout(plr, classId, lo)
	local cls = GameConfig.CLASSES[classId]
	if not cls then return nil, "no such class" end
	lo = type(lo) == "table" and lo or {}
	local out = Profile.defaultLoadout(classId)
	for _, slot in ipairs(Catalog.SLOTS) do
		local id = lo[slot]
		local piece = id and Catalog.PIECE[id]
		if piece and piece.slot == slot and piece.weight == cls.weight and Profile.has(plr, "pieces", id) then out[slot] = id end
	end
	out.colors = {}
	for _, s in ipairs({"Primary", "Secondary", "Accent", "Metal"}) do
		local c = type(lo.colors) == "table" and lo.colors[s]
		out.colors[s] = (c and Catalog.COLOR[c] and Profile.has(plr, "colors", c)) and c or Profile.defaultLoadout(classId).colors[s]
	end
	local function allowed(wid)
		local w = Catalog.WEAPON[wid]
		if not w or not Profile.has(plr, "weapons", wid) then return false end
		if w.weights then local ok = false; for _, x in ipairs(w.weights) do if x == cls.weight then ok = true end end; if not ok then return false end end
		if cls.weapons and cls.weapons ~= "any" then local ok = false; for _, x in ipairs(cls.weapons) do if x == wid then ok = true end end; if not ok then return false end end
		return true
	end
	if lo.weapon and allowed(lo.weapon) then out.weapon = lo.weapon end
	out.weaponSkin = (lo.weaponSkin and Catalog.SKIN[lo.weaponSkin] and Catalog.SKIN[lo.weaponSkin].weapon == out.weapon and Profile.has(plr, "skins", lo.weaponSkin)) and lo.weaponSkin or (out.weapon and out.weapon .. ":Default" or nil)
	if lo.secondary and lo.secondary ~= out.weapon and allowed(lo.secondary) and Catalog.WEAPON[lo.secondary].secondary then
		out.secondary = lo.secondary
		out.secondarySkin = (lo.secondarySkin and Catalog.SKIN[lo.secondarySkin] and Catalog.SKIN[lo.secondarySkin].weapon == out.secondary and Profile.has(plr, "skins", lo.secondarySkin)) and lo.secondarySkin or (out.secondary .. ":Default")
	else out.secondary, out.secondarySkin = nil, nil end
	return out
end

function Profile.validateAppearance(plr, app)
	local p = Profile.get(plr)
	local out = {}
	for k, v in pairs(p.appearance) do out[k] = v end
	app = type(app) == "table" and app or {}
	if type(app.skin) == "number" and Catalog.BODY.skins[app.skin] then out.skin = app.skin end
	for _, h in ipairs(Catalog.BODY.hair) do if h.id == app.hair then out.hair = app.hair end end
	for _, f in ipairs(Catalog.BODY.faces) do if f.id == app.face then out.face = app.face end end
	for _, h in ipairs(Catalog.BODY.hairColors) do if h.name == app.hairColor and Profile.has(plr, "hairColors", app.hairColor) then out.hairColor = app.hairColor end end
	for _, b in ipairs(Catalog.BODY.beards) do if b.id == app.beard and Profile.has(plr, "beards", app.beard) then out.beard = app.beard end end
	if type(app.title) == "string" and Profile.has(plr, "titles", app.title) then out.title = app.title end
	return out
end

--------------------------------------------------------------------
--  SETTERS
--------------------------------------------------------------------
function Profile.setClass(plr, classId, loadout) Profile.get(plr).classes[classId] = loadout; dirty[plr] = true end
function Profile.setActive(plr, classId) if GameConfig.CLASSES[classId] then Profile.get(plr).active = classId; dirty[plr] = true end end
function Profile.setAppearance(plr, app) Profile.get(plr).appearance = app; dirty[plr] = true end
function Profile.addStat(plr, key, n)
	local p = cache[plr]; if not p then return end
	p.stats[key] = (p.stats[key] or 0) + (n or 1); dirty[plr] = true
end
function Profile.rating(plr, bracket) return Profile.get(plr).rating[bracket] or Catalog.ECONOMY.ratingStart end
function Profile.setRating(plr, bracket, r) Profile.get(plr).rating[bracket] = r; dirty[plr] = true end

-- summary a client may see (no receipts)
function Profile.summary(plr)
	local p = Profile.get(plr)
	return {wallet = p.wallet, level = p.level, xp = p.xp, appearance = p.appearance, owned = p.owned,
		classes = p.classes, active = p.active, stats = p.stats, rating = p.rating, placements = p.placements, crates = p.crates, contracts = p.contracts}
end

Players.PlayerAdded:Connect(function(plr) task.spawn(load, plr) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(load, p) end
Players.PlayerRemoving:Connect(function(plr)
	if dirty[plr] then save(plr) end
	cache[plr], dirty[plr] = nil, nil
end)
task.spawn(function()
	while true do
		task.wait(AUTOSAVE)
		for plr in pairs(dirty) do if plr.Parent then task.spawn(save, plr) end end
	end
end)
game:BindToClose(function() for plr in pairs(dirty) do save(plr) end end)

return Profile
