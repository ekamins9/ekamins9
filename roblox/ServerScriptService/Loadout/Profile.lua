--[[ PROFILE v2 — one saved record per player (DataStore "Profiles_v2"):
       wallet      {marks, crowns, keys}   (keys: earned only, open any crate)
       copies      {[skinId | "pet:"..companionId] = {{u = copy id, n = serial, v = variant,
                    at = time, from = source, b = true if bound (never tradable)}, …}}
                   every skin out of a crate / the shop and every hatched companion is
                   its own COPY: duplicates are kept (trade, scrap or forge them)
       tally       {[skinId] = kills with it}
       claims      {[claimId] = time claimed}   founder  Founder number (nil = not a Founder)
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
       pass        {season, xp, premium, claimed = {free = {["3"] = true}, premium = {}}}
       login       {streak, claimed = "YYYY-MM-DD"}
       killfx      the equipped kill effect id ("" = none: a plain fall; everyone starts so)
       emotes      the emote wheel (up to 6 ids)
       tutorial    0 = brand new (the intro: train or straight to battle) · 1 = trained or
                   skipped (first match next) · 2 = done (the full menu). Player attribute
                   Tutorial mirrors it.
       menuTour    the menu tour was offered (back in the Courtyard after the first battle);
                   attribute MenuTour mirrors it   starterGift  the recruit's gift was given
       play        {day = "YYYY-MM-DD", seconds, claimed = {["1"] = true}}   today's playtime gifts
       eggs        {[eggId] = count}  waiting to be set in a nest
       nests       {["1"] = {egg, started (os.time), boost (seconds gained by the Hatchery)}}
       companion   the companion out with you ("" = none)   stars  {[companionId] = 1..5}
       drills      {[lessonId] = true} the Drill Master's lessons done   spars  {[skill] = wins in the ring}
       wishDay     the last UTC day you wished at the Courtyard's fountain
       gauntlet    the best Gauntlet wave you cleared in the training yard
       askedTraining  a new player was offered the training once (before their first battle)
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
	local function d(slot) local p = Catalog.defaultPiece(slot, w, cls and cls.starter); return p and p.id or nil end
	-- the class's own pair (GameConfig.CLASSES primary / secondary), else the first free weapon
	local function free(id) local wd = id and Catalog.WEAPON[id]; return wd and wd.unlock and wd.unlock.free and id or nil end
	local weapon = free(cls and cls.primary)
	if not weapon then for _, wd in ipairs(Catalog.WEAPONS) do if wd.unlock.free then weapon = wd.id; break end end end
	local second = free(cls and cls.secondary)
	if second and (second == weapon or not Catalog.WEAPON[second].secondary) then second = nil end
	return {helmet = d("helmet"), top = d("top"), bottom = d("bottom"),
		colors = {Primary = "Navy", Secondary = "Slate", Accent = "Ochre", Metal = "Ash"},
		weapon = weapon, weaponSkin = weapon and (weapon .. ":Default") or nil,
		secondary = second, secondarySkin = second and (second .. ":Default") or nil}
end

local function default()
	local p = {version = 2, wallet = {marks = 500, crowns = 0}, level = 1, xp = 0,
		appearance = {}, owned = {pieces = {}, skins = {}, weapons = {}, colors = {}, hairColors = {}, beards = {}, titles = {}, killfx = {}, emotes = {}, companions = {}},
		classes = {}, active = GameConfig.DEFAULT_CLASS, stats = {byWeapon = {}}, rating = {}, placements = {},
		crates = {}, contracts = {}, receipts = {}, lastWinDay = "", queueLock = {},
		pass = {}, login = {}, killfx = "", emotes = {"Salute", "Bow", "Cheer", "Flourish"},
		play = {}, eggs = {}, nests = {}, companion = "", stars = {}, drills = {}, spars = {}, wishDay = "",
		gauntlet = 0, askedTraining = false, copies = {}, tally = {}, claims = {}, copySeq = 0,
		tutorial = 0, menuTour = false, starterGift = false, loadoutV = 2}
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
	-- someone who has played before isn't sent through the newcomer's path
	if p.tutorial == nil then p.tutorial = (((p.level or 1) > 1) or p.askedTraining == true) and 2 or 0 end
	-- (the menu tour and the recruit's gift are for newcomers: not for anyone already through)
	if p.menuTour == nil then p.menuTour = (p.tutorial or 0) >= 2 end
	if p.starterGift == nil then p.starterGift = (p.tutorial or 0) >= 2 end
	-- Shatter used to be everyone's free kill effect: whoever has it on keeps it
	if p.killfx == "Shatter" and type(p.owned) == "table" then
		p.owned.killfx = p.owned.killfx or {}
		p.owned.killfx.Shatter = true
	end
	-- a newcomer who never picked a class starts as the new default (a Knight)
	if (p.tutorial or 0) == 0 and p.active == "Footman" then p.active = GameConfig.DEFAULT_CLASS end
	-- every class used to start with the same lone sword: an untouched one gets its class's pair
	if p.loadoutV == nil and type(p.classes) == "table" then
		for id, lo in pairs(p.classes) do
			if type(lo) == "table" and GameConfig.CLASSES[id] and lo.weapon == "Shortsword" and lo.secondary == nil then
				local fresh = Profile.defaultLoadout(id)
				lo.weapon, lo.weaponSkin, lo.secondary, lo.secondarySkin = fresh.weapon, fresh.weaponSkin, fresh.secondary, fresh.secondarySkin
			end
		end
	end
	p.loadoutV = 2
	-- new fields on old v2 saves
	local d = default()
	for k, v in pairs(d) do if p[k] == nil then p[k] = v end end
	for k, v in pairs(d.owned) do if p.owned[k] == nil then p.owned[k] = v end end
	for id in pairs(GameConfig.CLASSES) do if not p.classes[id] then p.classes[id] = Profile.defaultLoadout(id) end end
	for k, v in pairs(Catalog.BODY.defaults) do if p.appearance[k] == nil then p.appearance[k] = v end end
	if not GameConfig.CLASSES[p.active] then p.active = GameConfig.DEFAULT_CLASS end
	p.stats.byWeapon = p.stats.byWeapon or {}
	p.wallet.keys = p.wallet.keys or 0
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
	if game:GetService("RunService"):IsStudio() and not GameConfig.STUDIO_NEWCOMER then
		data.tutorial, data.menuTour, data.starterGift = 2, true, true
	end
	cache[plr] = data
	plr:SetAttribute("Tutorial", data.tutorial or 2)
	plr:SetAttribute("MenuTour", data.menuTour == true)
	return data
end

-- the newcomer's path moves on (0 → 1 → 2); never back
function Profile.setTutorial(plr, n)
	local p = Profile.get(plr)
	if (p.tutorial or 2) >= n then return end
	p.tutorial = n
	if n >= 2 then p.askedTraining = true end
	plr:SetAttribute("Tutorial", n)
	Profile.markDirty(plr)
end

function Profile.get(plr) return cache[plr] or load(plr) end
function Profile.markDirty(plr) dirty[plr] = true end
-- staff wiped this player's data (Admin): a fresh profile, saved over the old one
function Profile.reset(plr)
	cache[plr] = default()
	dirty[plr] = true
	return cache[plr]
end

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
	if kind == "pieces" then
		local pc = Catalog.PIECE[id]
		if pc and Catalog.isFree(pc) then return true end
		if pc and pc.unlock and Catalog.unlocked(pc.unlock, p) then return true end
	end
	if kind == "skins" and type(id) == "string" and id:match(":Default$") then return true end
	if kind == "skins" then local s = Catalog.SKIN[id]; if s and s.unlock and Catalog.unlocked(s.unlock, p) then return true end end
	if kind == "killfx" then local f = Catalog.KILLFX_BY[id]; if f and (f.free or (f.unlock and Catalog.unlocked(f.unlock, p))) then return true end end
	if kind == "emotes" then local e = Catalog.EMOTE[id]; if e and (e.free or (e.unlock and Catalog.unlocked(e.unlock, p))) then return true end end
	-- (out of a crate: a copy of its own, "fx:" / "emote:", tradable like a skin)
	if kind == "killfx" and Profile.copyCount(p, "fx:" .. tostring(id)) > 0 then return true end
	if kind == "emotes" and Profile.copyCount(p, "emote:" .. tostring(id)) > 0 then return true end
	-- (armor out of the Forge Crate: a piece of a crate-only set, "armor:", and a finish, "finish:")
	if kind == "pieces" and Profile.copyCount(p, "armor:" .. tostring(id)) > 0 then return true end
	if kind == "armorfx" and Profile.copyCount(p, "finish:" .. tostring(id)) > 0 then return true end
	if kind == "weapons" then local w = Catalog.WEAPON[id]; if w and Catalog.unlocked(w.unlock, p) then return true end end
	if kind == "spells" then local sp = Catalog.SPELLS[id]; if sp and sp.kind and Catalog.unlocked(sp.unlock or {free = true}, p) then return true end end
	if kind == "spellfx" and Profile.copyCount(p, "spell:" .. tostring(id)) > 0 then return true end
	if kind == "colors" then local c = Catalog.COLOR[id]; if c and not c.crowns then return true end end
	if kind == "hairColors" then for _, h in ipairs(Catalog.BODY.hairColors) do if h.name == id and not h.crowns then return true end end end
	if kind == "beards" then for _, b in ipairs(Catalog.BODY.beards) do if b.id == id and not b.crowns then return true end end end
	if kind == "titles" then
		for _, t in ipairs(Catalog.BODY.titles) do if t == id then return true end end
		for _, t in ipairs(Catalog.BODY.earnedTitles or {}) do if t.title == id and Catalog.unlocked(t.unlock, p) then return true end end
	end
	if kind == "skins" and Profile.copyCount(p, id) > 0 then return true end
	if kind == "companions" and Profile.copyCount(p, "pet:" .. tostring(id)) > 0 then return true end
	return p.owned[kind] and p.owned[kind][id] == true
end

--------------------------------------------------------------------
--  COPIES: each skin / companion you hold, one by one
--------------------------------------------------------------------
local VARIANT_RANK = {Masterwork = 1, Radiant = 2, Golden = 1, Spectral = 2}
Profile.VARIANT_RANK = VARIANT_RANK
function Profile.copies(p, key)
	p.copies = p.copies or {}
	return p.copies[key] or {}
end
function Profile.copyCount(p, key) return #Profile.copies(p, key) end
-- the copy that shows: the best finish, then the lowest number
function Profile.bestCopy(p, key)
	local best
	for _, c in ipairs(Profile.copies(p, key)) do
		local rb, rc = best and (VARIANT_RANK[best.v] or 0) or -1, VARIANT_RANK[c.v] or 0
		if not best or rc > rb or (rc == rb and (c.n or math.huge) < (best.n or math.huge)) then best = c end
	end
	return best
end
function Profile.addCopy(plr, key, info)
	local p = Profile.get(plr)
	p.copies = p.copies or {}
	p.copySeq = (p.copySeq or 0) + 1
	local c = {u = tostring(plr.UserId) .. "-" .. p.copySeq, n = info.n, v = info.v, at = info.at or os.time(), from = info.from, b = info.bound or nil}
	p.copies[key] = p.copies[key] or {}
	table.insert(p.copies[key], c)
	dirty[plr] = true
	return c
end
function Profile.findCopy(p, uid)
	for key, list in pairs(p.copies or {}) do
		for i, c in ipairs(list) do if c.u == uid then return key, c, i end end
	end
	return nil
end
function Profile.takeCopy(plr, uid)
	local p = Profile.get(plr)
	local key, c, i = Profile.findCopy(p, uid)
	if not key then return nil end
	table.remove(p.copies[key], i)
	if #p.copies[key] == 0 then p.copies[key] = nil end
	dirty[plr] = true
	return key, c
end
function Profile.giveCopy(plr, key, c)
	local p = Profile.get(plr)
	p.copies = p.copies or {}
	p.copies[key] = p.copies[key] or {}
	table.insert(p.copies[key], c)
	dirty[plr] = true
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
	-- bareheaded: no helmet worn (your face shows; the head has no armor's protection)
	if lo.noHelm == true then out.noHelm = true end
	-- the armor's finish (Catalog ▸ ArmorFX): one you own, or none ("")
	out.armorFx = (type(lo.armorFx) == "string" and Catalog.ARMORFX_BY[lo.armorFx] and Profile.has(plr, "armorfx", lo.armorFx)) and lo.armorFx or ""
	out.colors = {}
	for _, s in ipairs({"Primary", "Secondary", "Accent", "Metal"}) do
		local c = type(lo.colors) == "table" and lo.colors[s]
		out.colors[s] = (c and Catalog.COLOR[c] and Profile.has(plr, "colors", c)) and c or Profile.defaultLoadout(classId).colors[s]
	end
	local function allowed(wid, slot)
		local w = Catalog.WEAPON[wid]
		if not w or not Profile.has(plr, "weapons", wid) then return false end
		return Catalog.weaponFits(cls, w, slot or "primary")
	end
	if lo.weapon and allowed(lo.weapon, "primary") then out.weapon = lo.weapon end
	out.weaponSkin = (lo.weaponSkin and Catalog.SKIN[lo.weaponSkin] and Catalog.SKIN[lo.weaponSkin].weapon == out.weapon and Profile.has(plr, "skins", lo.weaponSkin)) and lo.weaponSkin or (out.weapon and out.weapon .. ":Default" or nil)
	if lo.secondary and lo.secondary ~= out.weapon and allowed(lo.secondary, "secondary") then
		out.secondary = lo.secondary
		out.secondarySkin = (lo.secondarySkin and Catalog.SKIN[lo.secondarySkin] and Catalog.SKIN[lo.secondarySkin].weapon == out.secondary and Profile.has(plr, "skins", lo.secondarySkin)) and lo.secondarySkin or (out.secondary .. ":Default")
	else out.secondary, out.secondarySkin = nil, nil end
	-- A MAGE'S ARSENAL (ReplicatedStorage ▸ MagicSpells): spells they have (free, or their level
	-- reached), no two the same, as many as the weapon carries; and a look for each (a spell
	-- skin they own a copy of: Catalog ▸ SpellSkins)
	if cls.magic then
		local Spells = Catalog.SPELLS
		local slots = (out.weapon and Catalog.WEAPON[out.weapon] and Catalog.WEAPON[out.weapon].slots) or 4
		local list, seen = {}, {}
		local function add(id)
			local sp = type(id) == "string" and Spells[id]
			if sp and sp.kind and not sp.fixed and not seen[id] and #list < slots and Profile.has(plr, "spells", id) then seen[id] = true; table.insert(list, id) end
		end
		for _, id in ipairs(type(lo.spells) == "table" and lo.spells or {}) do add(id) end
		if #list == 0 then for _, id in ipairs(Spells.DEFAULT) do add(id) end end
		out.spells = list
		out.spellSkins = {}
		if type(lo.spellSkins) == "table" then
			for spellId, skinId in pairs(lo.spellSkins) do
				local sk = Catalog.SPELLSKIN_BY and Catalog.SPELLSKIN_BY[skinId]
				-- (kept for a spell out of the arsenal too: it's there when the spell comes back)
				if sk and sk.spell == spellId and Catalog.SPELLS[spellId] and Profile.has(plr, "spellfx", skinId) then out.spellSkins[spellId] = skinId end
			end
		end
	end
	return out
end

function Profile.validateAppearance(plr, app)
	local p = Profile.get(plr)
	local out = {}
	for k, v in pairs(p.appearance) do out[k] = v end
	app = type(app) == "table" and app or {}
	if type(app.skin) == "number" and Catalog.BODY.skins[app.skin] then out.skin = app.skin end
	for _, h in ipairs(Catalog.BODY.hair) do if h.id == app.hair and (not h.crowns or Profile.has(plr, "hairs", h.id)) then out.hair = app.hair end end
	for _, f in ipairs(Catalog.BODY.faces) do if f.id == app.face then out.face = app.face end end
	for _, h in ipairs(Catalog.BODY.hairColors) do if h.name == app.hairColor and Profile.has(plr, "hairColors", app.hairColor) then out.hairColor = app.hairColor end end
	for _, b in ipairs(Catalog.BODY.beards) do if b.id == app.beard and Profile.has(plr, "beards", app.beard) then out.beard = app.beard end end
	if type(app.title) == "string" and Profile.has(plr, "titles", app.title) then out.title = app.title end
	-- the face builder: every part a real one (a premium one owned), the colours from their lists
	local FP = Catalog.BODY.faceParts or {}
	for _, layer in ipairs({"eyes", "brows", "mouth", "mark", "paint"}) do
		for _, it in ipairs(FP[layer] or {}) do
			if it.id == app[layer] and (not it.crowns or Profile.has(plr, "faceParts", layer .. "_" .. it.id)) then out[layer] = app[layer] end
		end
	end
	for _, c in ipairs(Catalog.BODY.eyeColors or {}) do if c.name == app.eyeColor and (not c.crowns or Profile.has(plr, "eyeColors", c.name)) then out.eyeColor = c.name end end
	for _, c in ipairs(Catalog.BODY.paintColors or {}) do if c.name == app.paintColor then out.paintColor = c.name end end
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
		classes = p.classes, active = p.active, stats = p.stats, rating = p.rating, placements = p.placements, crates = p.crates, contracts = p.contracts,
		login = p.login, killfx = p.killfx, emotes = p.emotes, tutorial = p.tutorial, menuTour = p.menuTour,
		eggs = p.eggs, nests = p.nests, companion = p.companion, stars = p.stars, drills = p.drills, spars = p.spars,
		gauntlet = p.gauntlet, askedTraining = p.askedTraining,
	copies = p.copies, tally = p.tally, claims = p.claims, founder = p.founder,
	trading = Profile.tradingHook and Profile.tradingHook(plr) or nil,
	restricted = Profile.restrictedHook and Profile.restrictedHook(plr) or false,
	armoury = Profile.ratingHook and Profile.ratingHook(p) or 0}
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
