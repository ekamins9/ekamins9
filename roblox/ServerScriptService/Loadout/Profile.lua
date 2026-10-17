--[[ PROFILE v2 — one saved record per player (DataStore "Profiles_v2"):
       wallet      {marks, crowns, keys}   (keys: earned only, open any crate)
       copies      {[skinId | "pet:"..companionId] = {{u = copy id, n = serial, v = variant,
                    at = time, from = source, b = true if bound (never tradable)}, …}}
                   every skin out of a crate / the shop and every hatched companion is
                   its own COPY: duplicates are kept (trade, scrap or forge them)
       tally       {[skinId] = kills with it}
       claims      {[claimId] = time claimed}   founder  Founder number (nil = not a Founder)
       beta        Beta Tester number (nil = not a Beta Tester)
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
       funnel      {["n"] = true}: the newcomer's path steps already counted (Economy ▸ Analytics)
       nests       {["1"] = {egg, started (os.time), boost (seconds gained by the Hatchery)}}
       companion   the companion out with you ("" = none)   stars  {[companionId] = 1..5}
       drills      {[lessonId] = true} the Drill Master's lessons done   spars  {[skill] = wins in the ring}
       wishDay     the last UTC day you wished at the Courtyard's fountain
       gauntlet    the best Gauntlet wave you cleared in the training yard
       askedTraining  a new player was offered the training once (before their first battle)
       unlockSeen     the "Archer and Mage unlocked" pop-up was shown (level 5)
       dropSeen       the drop whose announcement was last shown (each drop once, ever)
       trainTrack     sent to the training yard to learn a class ("archer" / "mage"): read there once
     Loaded on join, saved on leave and every AUTOSAVE seconds.
     A v1 profile (classes with armor = set id) is migrated on first load.

     ONE SERVER AT A TIME (the session lock): a profile is claimed when it's loaded
     (UpdateAsync writes _lockJob = this server's JobId, _lockAt = now) and let go when its
     player leaves. A server that finds it claimed by another waits LOCK_WAIT seconds for
     that one to let go (it's usually saving them on their way here), then takes it over;
     a lock older than LOCK_STALE (its server died) is taken at once. A save never writes
     over a profile another server has taken: that server's session is over (the player
     is told and sent off). So a player hopping servers can't be loaded twice, and an item
     can't be traded away on one server and still be there on another.
     A LOAD THAT FAILS (Roblox's data stores down) never becomes a fresh profile that
     overwrites the real one: the session is marked unsafe, never saved, and the player is
     asked to rejoin (in Studio, with its data stores off, you play on a fresh one unsaved).
     Profile.save returns whether the save landed (a purchase is only granted once it has). ]]

local Players = game:GetService("Players")
local Stores = require(game:GetService("ServerScriptService"):WaitForChild("Safety"):WaitForChild("Stores"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Catalog    = require(ReplicatedStorage:WaitForChild("Catalog"))

local Profile = {}
local STORE, OLD_STORE = "Profiles_v2", "Profiles_v1"
local AUTOSAVE = 60
local LOCK_STALE = 200   -- seconds: a lock this old (its server gone) is taken over at once
local LOCK_WAIT = 14     -- seconds a server waits for another to let a profile go
local JOB = game.JobId ~= "" and game.JobId or ("studio-" .. tostring(math.random(1, 1e9)))

local store, oldStore
local warned = false
local function getStore()
	if store then return store end
	local ok, s = pcall(Stores.get, STORE)
	if ok then store = s; pcall(function() oldStore = Stores.get(OLD_STORE) end)
	elseif not warned then warned = true; warn("[Profile] DataStore unavailable:", s) end
	return store
end

local cache, dirty = {}, {}
local state = {}     -- [plr] = "ok" (loaded and ours) | "unsafe" (never save: the load failed) | "lost" (another server took it)
local loading = {}   -- [plr] = true while its load is in flight

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
		secondary = second, secondarySkin = second and (second .. ":Default") or nil,
		-- the POWER (E): the class's first power, open from class level 1 (magic for everyone); the
		-- THROWABLE (C): the free knives; the third slot: a sidearm beside a shield, or nothing
		power = (Catalog.POWERS.byClass[classId] or {})[1] and Catalog.POWERS.byClass[classId][1].id or nil,
		throwable = Catalog.FREE_THROWABLE, throwableSkin = Catalog.FREE_THROWABLE and (Catalog.FREE_THROWABLE .. ":Default") or nil,
		thirdKind = "none"}
end

local function default()
	local p = {version = 2, wallet = {marks = 500, crowns = 0}, level = 1, xp = 0,
		appearance = {}, owned = {pieces = {}, skins = {}, weapons = {}, colors = {}, hairColors = {}, beards = {}, titles = {}, killfx = {}, emotes = {}, companions = {}},
		classes = {}, active = GameConfig.DEFAULT_CLASS, stats = {byWeapon = {}}, rating = {}, placements = {},
		crates = {}, contracts = {}, receipts = {}, lastWinDay = "", queueLock = {},
		pass = {}, login = {}, killfx = "", emotes = {"Salute", "Bow", "Cheer", "Flourish", "Challenge"},
		play = {}, eggs = {}, nests = {}, companion = "", stars = {}, drills = {}, spars = {}, wishDay = "",
		gauntlet = 0, askedTraining = false, unlockSeen = false, dropSeen = "", copies = {}, tally = {}, claims = {}, copySeq = 0,
		tutorial = 0, menuTour = false, starterGift = false, loadoutV = 3, funnel = {},
		giftsIn = {}, giftDay = {},   -- (Economy ▸ Gifting: the gift ids opened, today's sending)
		classXP = {},                 -- (Catalog ▸ Mastery: every class's own XP, its class level)
		vault = {stash = {}, kit = {relics = {}, potions = {}}, gold = 0, raids = 0, out = 0}}   -- (Game ▸ Vault: Deadvault's)
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

-- (the Economy's analytics and badges: required when used, they require this module)
local function econ(name)
	local ok, m = pcall(function() return require(game:GetService("ServerScriptService"):WaitForChild("Economy"):WaitForChild(name)) end)
	return ok and m or nil
end

local function fill(p)
	-- (someone who played before the newcomer's path was counted is past all of it)
	if p.funnel == nil then
		p.funnel = {}
		for i = 1, 8 do p.funnel[tostring(i)] = true end
	end
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
	-- v3: the Archer got an outfit of its own (the Bowman); an Archer still in the plain Light
	-- defaults (never changed) is dressed in it, piece by piece
	if (p.loadoutV or 2) < 3 and type(p.classes) == "table" and type(p.classes.Archer) == "table" then
		local lo, st = p.classes.Archer, GameConfig.CLASSES.Archer and GameConfig.CLASSES.Archer.starter
		for _, slot in ipairs(Catalog.SLOTS) do
			local was, now = Catalog.defaultPiece(slot, "Light"), Catalog.defaultPiece(slot, "Light", st)
			if was and now and was ~= now and lo[slot] == was.id then lo[slot] = now.id end
		end
	end
	p.loadoutV = 3
	-- new fields on old v2 saves
	local d = default()
	for k, v in pairs(d) do if p[k] == nil then p[k] = v end end
	for k, v in pairs(d.owned) do if p.owned[k] == nil then p.owned[k] = v end end
	for id in pairs(GameConfig.CLASSES) do if not p.classes[id] then p.classes[id] = Profile.defaultLoadout(id) end end
	for k, v in pairs(Catalog.BODY.defaults) do if p.appearance[k] == nil then p.appearance[k] = v end end
	if not GameConfig.CLASSES[p.active] then p.active = GameConfig.DEFAULT_CLASS end
	-- (a class that's locked now — the Archer and the Mage wait for level 5 — isn't yours to spawn as)
	if not Catalog.classOpen(p.active, p) then p.active = GameConfig.DEFAULT_CLASS end
	p.stats.byWeapon = p.stats.byWeapon or {}
	p.wallet.keys = p.wallet.keys or 0
	return p
end

-- claim this player's saved profile for this server (see the top: the session lock)
-- → the record (nil: none saved yet), and whether the claim went through
local function claim(s, plr)
	local key = "u" .. plr.UserId
	local deadline = os.clock() + LOCK_WAIT
	local tries = 0
	while plr.Parent do
		local outcome, raw
		local ok, err = pcall(s.UpdateAsync, s, key, function(old)
			if type(old) ~= "table" then outcome = "none"; return nil end
			local owner, at = old._lockJob, tonumber(old._lockAt) or 0
			if owner and owner ~= JOB and os.time() - at < LOCK_STALE and os.clock() < deadline then
				outcome = "busy"; return nil
			end
			old._lockJob, old._lockAt = JOB, os.time()
			outcome, raw = "ok", old
			return old
		end)
		if ok and outcome == "ok" then return raw, true end
		if ok and outcome == "none" then return nil, true end
		if ok and outcome == "busy" then
			task.wait(1.5)   -- (the other server is saving them on their way here)
		else
			tries += 1
			if not warned then warned = true; warn("[Profile] load failed:", err) end
			-- (Studio with its data stores off: no point waiting)
			if tries >= 4 or tostring(err):find("Studio") then return nil, false end
			task.wait(tries)
		end
	end
	return nil, false
end

local function load(plr)
	local data
	local s = getStore()
	if game:GetService("RunService"):IsStudio() and GameConfig.STUDIO_NEWCOMER then s = nil end
	local safe = false
	if s then
		local raw, ok = claim(s, plr)
		if ok and raw then data = fill(raw); safe = true
		elseif ok then
			-- nothing saved yet: an old v1 profile to bring over, or a new player
			safe = true
			if oldStore then
				local ok2, old = pcall(oldStore.GetAsync, oldStore, "u" .. plr.UserId)
				if ok2 and type(old) == "table" then data = migrate(old)
				elseif not ok2 then safe = false end
			end
			dirty[plr] = true
		end
	end
	local brandNew = data == nil and safe
	data = data or default()
	state[plr] = safe and "ok" or "unsafe"
	-- (counted: a newcomer's first step; and the badges this profile has already earned)
	task.defer(function()
		if not plr.Parent or state[plr] ~= "ok" then return end
		local A, B = econ("Analytics"), econ("Badges")
		if brandNew and A then A.onboard(plr, 1) end
		if B then B.check(plr, cache[plr]) end
	end)
	if not safe and not game:GetService("RunService"):IsStudio() and plr.Parent then
		-- (never a fresh profile that would save over the real one: back in a minute)
		task.defer(function()
			if plr.Parent then plr:Kick("We couldn't load your save just now (Roblox's data service is having trouble). Nothing was lost: please rejoin in a minute.") end
		end)
	end
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
	-- (the newcomer's path: ready for battle, then their first battle fought)
	task.defer(function()
		local A, B = econ("Analytics"), econ("Badges")
		if A then A.onboard(plr, n >= 2 and 4 or 3) end
		if B and n >= 1 then B.award(plr, "Graduate") end
	end)
end

function Profile.get(plr)
	if cache[plr] then return cache[plr] end
	-- (one load per player: anyone asking while it's in flight waits for it)
	if loading[plr] then
		while loading[plr] and not cache[plr] do task.wait() end
		return cache[plr] or default()
	end
	loading[plr] = true
	local ok, res = pcall(load, plr)
	loading[plr] = nil
	if not ok then warn("[Profile] load error:", res); state[plr] = "unsafe"; cache[plr] = cache[plr] or default() end
	return cache[plr]
end
-- is this profile loaded and this server's to save? (a purchase waits for it)
function Profile.ready(plr) return state[plr] == "ok" end
function Profile.markDirty(plr) dirty[plr] = true end
-- staff wiped this player's data (Admin): a fresh profile, saved over the old one
function Profile.reset(plr)
	cache[plr] = default()
	dirty[plr] = true
	return cache[plr]
end

-- write it (release: let the lock go, they're leaving) → whether it landed
local function save(plr, release)
	local data = cache[plr]
	local s = getStore()
	if not (data and s) or state[plr] ~= "ok" then return false end
	local taken = false
	local ok, err = pcall(s.UpdateAsync, s, "u" .. plr.UserId, function(old)
		-- (another server has them now: its record is the true one, never written over)
		if type(old) == "table" and old._lockJob and old._lockJob ~= JOB then taken = true; return nil end
		data._lockJob = (not release) and JOB or nil
		data._lockAt = os.time()
		return data
	end)
	if ok and taken then
		state[plr] = "lost"
		warn("[Profile] another server took over " .. plr.Name .. "'s save: this one won't write it again")
		if plr.Parent then plr:Kick("You're playing on another server now: this one has let go of your save.") end
		return false
	end
	if not ok then
		if not warned then warned = true; warn("[Profile] save failed:", err) end
		return false
	end
	dirty[plr] = nil
	return true
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
	local function skinOf(wid, skinId)
		return (skinId and Catalog.SKIN[skinId] and Catalog.SKIN[skinId].weapon == wid and Profile.has(plr, "skins", skinId)) and skinId or (wid .. ":Default")
	end
	if lo.secondary and lo.secondary ~= out.weapon and allowed(lo.secondary, "secondary") then
		out.secondary = lo.secondary
		out.secondarySkin = skinOf(out.secondary, lo.secondarySkin)
	else out.secondary, out.secondarySkin = nil, nil end
	-- A SHIELD in the secondary slot, beside a one-handed primary (Catalog ▸ Arsenal)
	if lo.shield and Catalog.shieldFits(cls, out.weapon, lo.shield) and Profile.has(plr, "weapons", lo.shield) then
		out.shield, out.shieldSkin = lo.shield, skinOf(lo.shield, lo.shieldSkin)
		out.secondary, out.secondarySkin = nil, nil
	end
	-- THE POWER (E) and THE THROWABLE (C): every class carries one of each. (A loadout saved when
	-- they shared the third slot, thirdKind "power" / "throwable", is read into its own slot.)
	do
		local p = Profile.get(plr)
		local open = (p.level or 1) >= (Catalog.MASTERY.thirdSlot or 1)
		local pw = lo.power
		if pw == nil and lo.thirdKind == "power" then pw = lo.thirdId end
		if pw ~= "none" and not (pw and Catalog.powerOpen(p, classId, pw)) then
			-- (nothing valid: the class's first power)
			local first = (Catalog.POWERS.byClass[classId] or {})[1]
			pw = first and first.id or "none"
		end
		out.power = open and pw or "none"
		local th, thSkin = lo.throwable, lo.throwableSkin
		if th == nil and lo.thirdKind == "throwable" then th, thSkin = lo.thirdId, lo.thirdSkin end
		if th ~= "none" then
			local t = Catalog.WEAPON[th or ""]
			if not (t and t.throwable and Profile.has(plr, "weapons", th)) then th, thSkin = Catalog.FREE_THROWABLE or "none", nil end
		end
		out.throwable = open and th or "none"
		out.throwableSkin = out.throwable ~= "none" and skinOf(out.throwable, thSkin) or nil
		-- the third slot is a sidearm's now: beside a shield, on key 3
		local kind, id = lo.thirdKind, lo.thirdId
		if not (kind == "sidearm" and out.shield and id ~= out.weapon and allowed(id, "secondary")) then kind, id = "none", nil end
		out.thirdKind, out.thirdId = kind, id
		if kind == "sidearm" then out.thirdSkin = skinOf(id, lo.thirdSkin) end
	end
	-- every class's POWER LOOKS (Catalog ▸ PowerSkins: spell skins of "Pw_<power>"), kept for every
	-- power of the class (they're there when the power comes back to the slot)
	out.spellSkins = {}
	if type(lo.spellSkins) == "table" then
		for spellId, skinId in pairs(lo.spellSkins) do
			local sk = Catalog.SPELLSKIN_BY and Catalog.SPELLSKIN_BY[skinId]
			local sp = Catalog.SPELLS[spellId]
			if sk and sk.spell == spellId and sp and sp.power and Catalog.POWER[sp.power] and Catalog.POWER[sp.power].class == classId
				and Profile.has(plr, "spellfx", skinId) then out.spellSkins[spellId] = skinId end
		end
	end
	-- A MAGE'S ARSENAL (ReplicatedStorage ▸ MagicSpells): spells they have (free, or their level
	-- reached), no two the same, as many as the weapon carries; and a look for each (a spell
	-- skin they own a copy of: Catalog ▸ SpellSkins)
	if cls.magic then
		local Spells = Catalog.SPELLS
		local slots = (out.weapon and Catalog.WEAPON[out.weapon] and Catalog.WEAPON[out.weapon].slots) or 4
		local list, seen = {}, {}
		local function add(id)
			local sp = type(id) == "string" and Spells[id]
			if sp and sp.kind and not sp.wand and not sp.power and not seen[id] and #list < slots and Profile.has(plr, "spells", id) then seen[id] = true; table.insert(list, id) end
		end
		for _, id in ipairs(type(lo.spells) == "table" and lo.spells or {}) do add(id) end
		if #list == 0 then for _, id in ipairs(Spells.DEFAULT) do add(id) end end
		out.spells = list
		-- the wand's (a sidearm's: wand spells only, as many as it carries)
		local wand = out.secondary and Catalog.WEAPON[out.secondary]
		if wand and wand.wand then
			local wl, wseen = {}, {}
			local function addW(id)
				local sp = type(id) == "string" and Spells[id]
				if sp and sp.wand and not wseen[id] and #wl < (wand.slots or 2) and Profile.has(plr, "spells", id) then wseen[id] = true; table.insert(wl, id); seen[id] = true end
			end
			for _, id in ipairs(type(lo.wandSpells) == "table" and lo.wandSpells or {}) do addW(id) end
			if #wl == 0 then for _, id in ipairs(Spells.WAND_DEFAULT) do addW(id) end end
			out.wandSpells = wl
		end
		if type(lo.spellSkins) == "table" then
			for spellId, skinId in pairs(lo.spellSkins) do
				local sk = Catalog.SPELLSKIN_BY and Catalog.SPELLSKIN_BY[skinId]
				-- (kept for a spell out of the arsenal too: it's there when the spell comes back)
				if sk and sk.spell == spellId and Catalog.SPELLS[spellId] and not Catalog.SPELLS[spellId].power and Profile.has(plr, "spellfx", skinId) then out.spellSkins[spellId] = skinId end
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
	-- your arms (Catalog ▸ Arms): an emblem your level has opened, a metal, colours off the palette
	-- (a premium one owned), a division ("" takes the emblem or the division off)
	local A = Catalog.ARMS
	if A then
		if app.armsEmblem == "" then out.armsEmblem = nil
		elseif type(app.armsEmblem) == "string" and A.open(app.armsEmblem, p) then out.armsEmblem = app.armsEmblem end
		if app.armsMetal == "" then out.armsMetal = nil
		elseif type(app.armsMetal) == "string" and A.METAL[app.armsMetal] then out.armsMetal = app.armsMetal end
		local function colour(name)
			local c = type(name) == "string" and Catalog.COLOR[name]
			return c and (not c.crowns or Profile.has(plr, "colors", name)) and name or nil
		end
		if app.armsField == "" then out.armsField = nil else out.armsField = colour(app.armsField) or out.armsField end
		if app.armsColor2 == "" then out.armsColor2 = nil else out.armsColor2 = colour(app.armsColor2) or out.armsColor2 end
		if app.armsDivision == "" then out.armsDivision = nil
		elseif type(app.armsDivision) == "string" and A.DIVISION[app.armsDivision] then out.armsDivision = app.armsDivision end
	end
	return out
end

--------------------------------------------------------------------
--  SETTERS
--------------------------------------------------------------------
function Profile.setClass(plr, classId, loadout) Profile.get(plr).classes[classId] = loadout; dirty[plr] = true end
-- (a class still locked — the Archer and the Mage before level 5 — can't be made active)
function Profile.setActive(plr, classId)
	if GameConfig.CLASSES[classId] and Catalog.classOpen(classId, Profile.get(plr)) then Profile.get(plr).active = classId; dirty[plr] = true; return true end
	return false
end
function Profile.setAppearance(plr, app) Profile.get(plr).appearance = app; dirty[plr] = true; Profile.publishArms(plr) end
-- your arms where everyone's screen can read them (NameTags' badge): "emblem|metal|field", or none
function Profile.publishArms(plr)
	local a = cache[plr] and cache[plr].appearance
	plr:SetAttribute("Arms", (a and a.armsEmblem) and string.format("%s|%s|%s", a.armsEmblem, a.armsMetal or "Gold", a.armsField or "") or nil)
end
function Profile.addStat(plr, key, n)
	local p = cache[plr]; if not p then return end
	p.stats[key] = (p.stats[key] or 0) + (n or 1); dirty[plr] = true
	-- (firsts worth a badge)
	if key == "kill" or key == "win" then
		local B = econ("Badges")
		if B then B.award(plr, key == "kill" and "FirstBlood" or "FirstWin") end
	end
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
		gauntlet = p.gauntlet, askedTraining = p.askedTraining, unlockSeen = p.unlockSeen, dropSeen = p.dropSeen,
	copies = p.copies, tally = p.tally, claims = p.claims, founder = p.founder, beta = p.beta, classXP = p.classXP,
	trading = Profile.tradingHook and Profile.tradingHook(plr) or nil,
	restricted = Profile.restrictedHook and Profile.restrictedHook(plr) or false,
	armoury = Profile.ratingHook and Profile.ratingHook(p) or 0}
end

Players.PlayerAdded:Connect(function(plr) task.spawn(Profile.get, plr) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(Profile.get, p) end
Players.PlayerRemoving:Connect(function(plr)
	while loading[plr] do task.wait() end
	-- (always written on the way out: it lets the lock go for their next server)
	if state[plr] == "ok" then save(plr, true) end
	cache[plr], dirty[plr], state[plr] = nil, nil, nil
end)
-- every AUTOSAVE seconds: the changed ones saved, and everyone's lock kept fresh
task.spawn(function()
	while true do
		task.wait(AUTOSAVE)
		for plr in pairs(cache) do if plr.Parent and state[plr] == "ok" then task.spawn(save, plr) end end
	end
end)
-- the server closing: everyone saved and let go, all at once, before it's allowed to close
game:BindToClose(function()
	local left = 0
	for plr in pairs(cache) do
		if state[plr] == "ok" then
			left += 1
			task.spawn(function() pcall(save, plr, true); left -= 1 end)
		end
	end
	local t0 = os.clock()
	while left > 0 and os.clock() - t0 < 25 do task.wait() end
end)

return Profile
