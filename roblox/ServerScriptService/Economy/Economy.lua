--[[ ECONOMY — every way Marks and Crowns move, all server-side:
       Economy.award(plr, events)        round-end pay: {round=1, win=1, kill=n, parry=n, chamber=n, drill=n}
       Economy.spend(plr, marks, crowns) -> ok, msg
       Economy.buy(plr, kind, id, currency)   kind: piece | pack | color | hairColor | beard | weapon
       Economy.openCrate(plr, crateId, free, payWith)   -> result {skinId, name, rarity, dup, refund,
                                          variant, serial} | nil, msg   payWith "keys" | "crowns"
       Economy.exchange(plr, tier)       Crowns -> Marks
       Economy.grantProduct(plr, productId, receiptId)   Robux Crown bundles (EconomyServer's ProcessReceipt)
       Economy.levelFor(xp)
       Economy.grantReward(plr, reward)  {marks | crowns | skin | title | crate | piece | color |
                                          killfx | emote | egg | companion} (pass, login, gifts)
       Economy.passState(plr) / addPassXP(plr, n) / passClaim(plr, tier, track) / passBuy(plr)
       Economy.loginStatus(plr) / loginClaim(plr)
     Nothing here trusts a client: prices and odds come from Catalog, results
     are decided before the client is told. A server flagged noRewards
     (cheats on) pays nothing. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Drops = require(ReplicatedStorage:WaitForChild("Drops"))

local Economy = {}
local Collection   -- (requires Economy back: loaded on first use)
local function collection()
	Collection = Collection or require(script.Parent:WaitForChild("Collection"))
	return Collection
end
Economy.collection = collection
local E = Catalog.ECONOMY
local function log(...) DebugFlags.log("Economy", ...) end
Economy.changed = Instance.new("BindableEvent")   -- (plr) wallet / inventory changed → HubServer pushes to the client

local function noRewards()
	local gf = ServerScriptService:FindFirstChild("Game")
	local gm = gf and gf:FindFirstChild("Game")
	if not gm then return false end
	local ok, Game = pcall(require, gm)
	return ok and Game.server and Game.server.noRewards == true
end

function Economy.levelFor(xp)
	local lvl = 1
	for i = 2, 200 do
		local need = E.levels[i] or E.levels[#E.levels]
		if xp >= need then lvl = i else break end
		xp -= need
	end
	return lvl
end

function Economy.addXP(plr, xp)
	local p = Profile.get(plr)
	p.xp += xp
	local leveled = 0
	while true do
		local need = E.levels[p.level + 1] or E.levels[#E.levels]
		if p.xp >= need then p.xp -= need; p.level += 1; leveled += 1; p.wallet.marks += E.levelMarks else break end
	end
	-- a Key per level, earned only
	if leveled > 0 then p.wallet.keys = (p.wallet.keys or 0) + leveled * ((E.keys or {}).levelUp or 0) end
	Profile.markDirty(plr)
	return leveled
end

-- forward: round XP also climbs the pass
local addPassXP

function Economy.award(plr, events)
	if noRewards() then return {marks = 0, xp = 0, levels = 0, blocked = true} end
	local p = Profile.get(plr)
	local marks, xp = 0, 0
	for key, n in pairs(events or {}) do
		local e = E.earn[key]
		if e and type(n) == "number" and n > 0 then marks += e.marks * n; xp += e.xp * n end
	end
	-- the Calendar's events: double XP weekends, raid weekends (per mode)
	local round = ReplicatedStorage:FindFirstChild("Round")
	local mode = round and round:GetAttribute("Mode")
	marks = math.floor(marks * Drops.earnMult("marks", mode))
	xp = math.floor(xp * Drops.earnMult("xp", mode))
	local today = os.date("!%Y-%m-%d")
	local firstWin = false
	if events and (events.win or 0) > 0 and p.lastWinDay ~= today then
		p.lastWinDay = today; marks += E.earn.firstWinOfDay.marks; firstWin = true
		p.wallet.keys = (p.wallet.keys or 0) + ((E.keys or {}).firstWin or 0)
	end
	p.wallet.marks += marks
	local levels = Economy.addXP(plr, xp)
	addPassXP(plr, xp)
	Profile.markDirty(plr)
	Economy.changed:Fire(plr)
	return {marks = marks, xp = xp, levels = levels, firstWin = firstWin, level = p.level}
end

function Economy.spend(plr, marks, crowns)
	local p = Profile.get(plr)
	marks, crowns = marks or 0, crowns or 0
	if p.wallet.marks < marks then return false, string.format("not enough Marks (you need %d, you have %d)", marks, p.wallet.marks) end
	if p.wallet.crowns < crowns then return false, string.format("not enough Crowns (you need %d, you have %d)", crowns, p.wallet.crowns) end
	p.wallet.marks -= marks; p.wallet.crowns -= crowns
	Profile.markDirty(plr)
	return true
end

local function price(marks, crowns, currency)
	if currency == "crowns" then
		if (crowns or 0) <= 0 then return nil, "not sold for Crowns" end
		return 0, crowns
	end
	if (marks or 0) <= 0 then return nil, "not sold for Marks" end
	return marks, 0
end

function Economy.buy(plr, kind, id, currency)
	currency = currency == "crowns" and "crowns" or "marks"
	if kind == "piece" then
		local pc = Catalog.PIECE[id]; if not pc then return false, "no such piece" end
		if Profile.has(plr, "pieces", id) then return false, "already owned" end
		if pc.crate then return false, "this one only comes out of the " .. ((Catalog.CRATES[pc.crate] or {}).name or "crate") end
		if not Catalog.isFree(pc) and not Catalog.onSale(pc.pack) then return false, "not in today's store" end
		local m, c = price(pc.marks, pc.crowns, currency); if not m then return false, c end
		local ok, msg = Economy.spend(plr, m, c); if not ok then return false, msg end
		Profile.grant(plr, "pieces", id); Economy.changed:Fire(plr); return true, pc.name .. " bought"
	elseif kind == "pack" then
		local pk = Catalog.PACKS[id]; if not pk then return false, "no such pack" end
		if not Catalog.onSale(id) then return false, "not in today's store" end
		local m, c, list = 0, 0, {}
		for _, pc in ipairs(Catalog.PIECES) do
			if pc.pack == id and not pc.crate and not Profile.has(plr, "pieces", pc.id) then table.insert(list, pc); m += pc.marks; c += pc.crowns end
		end
		for _, sk in ipairs(Catalog.SKINS) do
			if sk.pack == id and not Profile.has(plr, "skins", sk.id) then table.insert(list, sk); m += sk.marks or 0; c += sk.crowns or 0 end
		end
		if #list == 0 then return false, "you own all of it" end
		local disc = 1 - (pk.bundle or 0)
		local pm, pcn = price(math.floor(m * disc + 0.5), math.floor(c * disc + 0.5), currency); if not pm then return false, pcn end
		local ok, msg = Economy.spend(plr, pm, pcn); if not ok then return false, msg end
		for _, it in ipairs(list) do Profile.grant(plr, it.slot and "pieces" or "skins", it.id) end
		Economy.changed:Fire(plr); return true, pk.name .. " bought"
	elseif kind == "color" then
		local col = Catalog.COLOR[id]; if not col then return false, "no such color" end
		if Profile.has(plr, "colors", id) then return false, "already owned" end
		local ok, msg = Economy.spend(plr, 0, col.crowns or 0); if not ok then return false, msg end
		Profile.grant(plr, "colors", id); Economy.changed:Fire(plr); return true, id .. " is yours"
	elseif kind == "hairColor" then
		local hc; for _, h in ipairs(Catalog.BODY.hairColors) do if h.name == id then hc = h end end
		if not hc then return false, "no such color" end
		if Profile.has(plr, "hairColors", id) then return false, "already owned" end
		local ok, msg = Economy.spend(plr, 0, hc.crowns or 0); if not ok then return false, msg end
		Profile.grant(plr, "hairColors", id); Economy.changed:Fire(plr); return true, id .. " hair is yours"
	elseif kind == "beard" then
		local bd; for _, b in ipairs(Catalog.BODY.beards) do if b.id == id then bd = b end end
		if not bd then return false, "no such beard" end
		if Profile.has(plr, "beards", id) then return false, "already owned" end
		local ok, msg = Economy.spend(plr, 0, bd.crowns or 0); if not ok then return false, msg end
		Profile.grant(plr, "beards", id); Economy.changed:Fire(plr); return true, bd.name .. " beard is yours"
	elseif kind == "weapon" then
		local w = Catalog.WEAPON[id]; if not w then return false, "no such weapon" end
		if Profile.has(plr, "weapons", id) then return false, "already unlocked" end
		if not w.marks or w.marks <= 0 then return false, "this weapon is earned, not bought" end
		local ok, msg = Economy.spend(plr, w.marks, 0); if not ok then return false, msg end
		Profile.grant(plr, "weapons", id); Economy.changed:Fire(plr); return true, w.name .. " unlocked"
	elseif kind == "skin" then
		-- skins are never sold at will: only today's WEAPONS offers and the
		-- skins of a pack that is in the store today (Catalog.skinOnSale)
		local sk = Catalog.SKIN[id]; if not sk then return false, "no such skin" end
		if Profile.has(plr, "skins", id) then return false, "already owned" end
		local src = Catalog.skinSource(sk)
		if src == "earned" then return false, "that skin is earned by playing" end
		if src == "pass" then return false, "that skin comes from the season pass" end
		if src == "crate" then return false, "that skin comes from a crate" end
		if not Catalog.skinOnSale(id) then return false, Catalog.soldOut(sk) and "sold out: every one has been made" or "not in today's shop" end
		local m, c = price(sk.marks, sk.crowns, currency); if not m then return false, c end
		local p = Profile.get(plr)
		if p.wallet.marks < m then return false, string.format("not enough Marks (you need %d, you have %d)", m, p.wallet.marks) end
		if p.wallet.crowns < c then return false, string.format("not enough Crowns (you need %d, you have %d)", c, p.wallet.crowns) end
		-- a numbered one takes its number first (a limited one may just have sold out)
		local it, why = collection().grantNumbered(plr, id, "the shop")
		if not it then return false, why or "sold out" end
		local ok, msg = Economy.spend(plr, m, c)
		if not ok then log("paid after numbering failed", plr.Name, id, msg) end
		Economy.changed:Fire(plr)
		return true, sk.name .. (it.n and (" #" .. it.n) or "") .. " bought"
	end
	return false, "unknown purchase"
end

--------------------------------------------------------------------
--  CRATES
--------------------------------------------------------------------
-- the odds a player faces on their next open: the crate's, or — when the pity
-- is due — Legendary-or-better, split as the crate splits them (shown to the player)
function Economy.crateOdds(crate, since)
	if since >= (crate.pity or 20) - 1 then
		local l, m = crate.odds.Legendary or 0, crate.odds.Mythic or 0
		if l + m <= 0 then return {Legendary = 100}, true end
		return {Legendary = 100 * l / (l + m), Mythic = 100 * m / (l + m)}, true
	end
	return crate.odds, false
end

function Economy.openCrate(plr, crateId, free, payWith)
	local crate = Catalog.CRATES[crateId]
	if not crate then return nil, "no such crate" end
	local pool = Catalog.crateItems(crateId)
	if #pool == 0 then return nil, "this crate is empty (nothing names it)" end
	local p = Profile.get(plr)
	p.crates[crateId] = p.crates[crateId] or {opens = 0, sinceLegendary = 0}
	local cc = p.crates[crateId]
	local from = crate.name
	if not free then
		if not Drops.crateLive(crateId) then return nil, crate.name .. " isn't in rotation right now" end
		if payWith == "crowns" then
			-- paid random items: never for a player whose region bars them
			if collection().restricted(plr) then return nil, "Crates open with Keys in your region (earn them by playing)" end
			local ok, msg = Economy.spend(plr, 0, crate.cost); if not ok then return nil, msg end
		else
			local need = crate.keys or 1
			if (p.wallet.keys or 0) < need then return nil, string.format("you need %d Key%s (earned: level-ups, the first win of the day, tasks)", need, need > 1 and "s" or "") end
			p.wallet.keys -= need
		end
	elseif collection().restricted(plr) and free == "paid" then
		-- a crate inside something bought with Robux (the premium pass): a fixed reward instead
		local marks = (crate.cost or 60) * 10
		p.wallet.marks += marks
		Profile.markDirty(plr); Economy.changed:Fire(plr)
		return {kind = "marks", name = string.format("%d Marks (in place of a %s)", marks, crate.name), rarity = "Rare", dup = false, refund = 0, opens = cc.opens}
	end
	-- rarity by odds (the pity, when due, is Legendary or better)
	local odds = Economy.crateOdds(crate, cc.sinceLegendary)
	local rarity
	local r, acc = math.random() * 100, 0
	for _, name in ipairs({"Mythic", "Legendary", "Epic", "Rare", "Common"}) do
		acc += odds[name] or 0
		if r < acc then rarity = name; break end
	end
	rarity = rarity or "Common"
	local picks = {}
	for _, s in ipairs(pool) do if s.rarity == rarity then table.insert(picks, s) end end
	if #picks == 0 then picks = pool end
	local win = picks[math.random(#picks)]
	cc.opens += 1
	cc.sinceLegendary = (win.rarity == "Legendary" or win.rarity == "Mythic") and 0 or cc.sinceLegendary + 1
	local OWN = {skin = "skins", killfx = "killfx", emote = "emotes", piece = "pieces", armorfx = "armorfx"}
	local ownKind = OWN[win.kind] or "emotes"
	local dup = Profile.has(plr, ownKind, win.id)
	local refund = 0
	local variant, serial
	if win.kind == "skin" then variant = collection().rollSkinVariant() end
	local copies
	if win.kind == "skin" then
		-- every skin is a copy of its own: a duplicate is kept (trade, scrap or forge it)
		local it = collection().grantNumbered(plr, win.id, from, variant)
		serial = it and it.n
		copies = Profile.copyCount(p, win.id)
	else
		-- a kill effect, an emote, an armor piece or a finish too: kept as a copy of
		-- its own, never paid back (a Mythic one numbered); trade the spare, or scrap it
		local PREFIX = {killfx = "fx:", emote = "emote:", piece = "armor:", armorfx = "finish:"}
		local key = (PREFIX[win.kind] or "emote:") .. win.id
		if win.rarity == "Mythic" then serial = collection().serial(key) end
		Profile.addCopy(plr, key, {n = serial, from = from, bound = not collection().tradable(key)})
		copies = Profile.copyCount(p, key)
	end
	Profile.markDirty(plr)
	Economy.changed:Fire(plr)
	log(plr.Name, "opened", crateId, "->", win.kind, win.id, win.rarity, dup and ("dup +" .. refund) or "")
	local KIND_LABEL = {killfx = "Kill effect · ", emote = "Emote · ", piece = "Armor · ", armorfx = "Armor finish · "}
	local label = win.kind == "skin" and (Catalog.WEAPON[win.weapon].name .. " · " .. win.name)
		or ((KIND_LABEL[win.kind] or "") .. win.name)
	return {crate = crateId, kind = win.kind, itemId = win.id, skinId = win.kind == "skin" and win.id or nil, weapon = win.weapon, name = label, rarity = win.rarity,
		dup = dup, refund = refund, sinceLegendary = cc.sinceLegendary, opens = cc.opens, variant = variant, serial = serial,
		copies = copies}
end

--------------------------------------------------------------------
--  REWARDS (the pass, login gifts)
--------------------------------------------------------------------
-- eggs and companions live in Economy ▸ Pastimes (which requires this module)
local function pastimes() return require(script.Parent:WaitForChild("Pastimes")) end

-- grant one reward; returns a line for the toast and, for a crate, its result
function Economy.grantReward(plr, r)
	local p = Profile.get(plr)
	local bits, crateResult = {}, nil
	if r.marks then p.wallet.marks += r.marks; table.insert(bits, string.format("+%d Marks", r.marks)) end
	if r.crowns then p.wallet.crowns += r.crowns; table.insert(bits, string.format("+%d Crowns", r.crowns)) end
	if r.keys then p.wallet.keys = (p.wallet.keys or 0) + r.keys; table.insert(bits, string.format("+%d Key%s", r.keys, r.keys > 1 and "s" or "")) end
	if r.skin and Catalog.SKIN[r.skin] then
		local s = Catalog.SKIN[r.skin]
		local wname = (Catalog.WEAPON[s.weapon] and Catalog.WEAPON[s.weapon].name or s.weapon) .. " · " .. s.name
		if collection().wantsSerial(s) then
			-- a numbered one (a Mythic, a Unique: one of one) is a copy of its own
			local it, why = collection().grantNumbered(plr, r.skin, r.from or "a reward")
			if it then table.insert(bits, wname .. (s.unique and " (UNIQUE: the only one)" or (it.n and (" #" .. it.n) or "")))
			elseif r.from then
				-- (a reward of a Unique someone already has: Marks instead)
				p.wallet.marks += 20000
				table.insert(bits, "+20000 Marks (" .. tostring(why) .. ")")
			else
				table.insert(bits, "not given: " .. tostring(why))
			end
		else
			Profile.grant(plr, "skins", r.skin)
			table.insert(bits, wname .. " skin")
		end
	end
	if r.title then Profile.grant(plr, "titles", r.title); table.insert(bits, "the title " .. r.title) end
	if r.piece and Catalog.PIECE[r.piece] then Profile.grant(plr, "pieces", r.piece); table.insert(bits, Catalog.PIECE[r.piece].name) end
	if r.color and Catalog.COLOR[r.color] then Profile.grant(plr, "colors", r.color); table.insert(bits, r.color) end
	if r.killfx and Catalog.KILLFX_BY[r.killfx] then Profile.grant(plr, "killfx", r.killfx); table.insert(bits, "the kill effect " .. Catalog.KILLFX_BY[r.killfx].name) end
	if r.emote and Catalog.EMOTE[r.emote] then Profile.grant(plr, "emotes", r.emote); table.insert(bits, "the emote " .. Catalog.EMOTE[r.emote].name) end
	if r.egg and Catalog.EGG[r.egg] then
		if r.paid and collection().restricted(plr) then
			-- an egg inside something bought (a random hatch): Marks instead, where paid random items are barred
			local m = 600 * (r.n or 1)
			p.wallet.marks += m; table.insert(bits, string.format("+%d Marks (in place of the %s)", m, Catalog.EGG[r.egg].name))
		else
			pastimes().grantEgg(plr, r.egg, r.n or 1); table.insert(bits, Catalog.EGG[r.egg].name)
		end
	end
	if r.companion and Catalog.COMPANION[r.companion] then
		local res = pastimes().grantCompanion(plr, r.companion)
		table.insert(bits, "the companion " .. Catalog.COMPANION[r.companion].name .. ((res and res.dup) and " (★ up)" or ""))
	end
	if r.crate then
		crateResult = Economy.openCrate(plr, r.crate, r.paid and "paid" or true)
		if crateResult then table.insert(bits, crateResult.name .. (crateResult.dup and " (another copy)" or "")) end
	end
	Profile.markDirty(plr)
	Economy.changed:Fire(plr)
	return table.concat(bits, "  ·  "), crateResult
end

-- the pass record for this season (a new season starts it over)
local function passRecord(plr)
	local p = Profile.get(plr)
	local P = Catalog.PASS
	if type(p.pass) ~= "table" or p.pass.season ~= P.season then
		p.pass = {season = P.season, xp = 0, premium = false, claimed = {free = {}, premium = {}}}
		Profile.markDirty(plr)
	end
	p.pass.claimed = p.pass.claimed or {free = {}, premium = {}}
	p.pass.claimed.free = p.pass.claimed.free or {}
	p.pass.claimed.premium = p.pass.claimed.premium or {}
	return p.pass
end
function Economy.passState(plr)
	local P = Catalog.PASS
	local rec = passRecord(plr)
	local tier = math.min(#P.tiers, math.floor(rec.xp / P.tierXP))
	-- claimed tiers are kept under string keys ("3" = true): DataStore JSON and remotes both need that
	local cf, cp = {}, {}
	for k in pairs(rec.claimed.free) do cf[tostring(k)] = true end
	for k in pairs(rec.claimed.premium) do cp[tostring(k)] = true end
	return {season = P.season, xp = rec.xp, tier = tier, premium = rec.premium == true, claimedFree = cf, claimedPremium = cp}
end
addPassXP = function(plr, n)
	if (n or 0) <= 0 then return end
	local P = Catalog.PASS
	local rec = passRecord(plr)
	local before = math.floor(rec.xp / P.tierXP)
	rec.xp = math.min(rec.xp + n, #P.tiers * P.tierXP)
	Profile.markDirty(plr)
	return math.floor(rec.xp / P.tierXP) - before
end
Economy.addPassXP = addPassXP
function Economy.passClaim(plr, tier, track)
	local P = Catalog.PASS
	tier = tonumber(tier)
	local t = tier and P.tiers[tier]
	if not t then return false, "no such tier" end
	track = track == "premium" and "premium" or "free"
	local rec = passRecord(plr)
	if math.floor(rec.xp / P.tierXP) < tier then return false, "reach tier " .. tier .. " first" end
	if track == "premium" and not rec.premium then return false, "the premium track needs the pass" end
	if rec.claimed[track][tostring(tier)] then return false, "already claimed" end
	local reward = t[track]
	if not reward then return false, "nothing on that tier" end
	if track == "premium" then reward = table.clone(reward); reward.paid = true end   -- (bought with Crowns)
	rec.claimed[track][tostring(tier)] = true
	local line, crate = Economy.grantReward(plr, reward)
	return true, "TIER " .. tier .. "  ·  " .. line, crate
end
-- every reward you reached and haven't taken, in one go
function Economy.passClaimAll(plr)
	local P = Catalog.PASS
	local rec = passRecord(plr)
	local reached = math.min(#P.tiers, math.floor(rec.xp / P.tierXP))
	local lines, crates = {}, {}
	for tier = 1, reached do
		for _, track in ipairs({"free", "premium"}) do
			local reward = P.tiers[tier][track]
			if reward and not rec.claimed[track][tostring(tier)] and (track == "free" or rec.premium) then
				if track == "premium" then reward = table.clone(reward); reward.paid = true end
				rec.claimed[track][tostring(tier)] = true
				local line, crate = Economy.grantReward(plr, reward)
				table.insert(lines, line)
				if crate then table.insert(crates, crate) end
			end
		end
	end
	if #lines == 0 then return false, "nothing to claim yet", {}, {} end
	return true, string.format("%d rewards claimed", #lines), lines, crates
end

function Economy.passBuy(plr)
	local P = Catalog.PASS
	local rec = passRecord(plr)
	if rec.premium then return false, "you already have the pass" end
	local ok, msg = Economy.spend(plr, 0, P.price); if not ok then return false, msg end
	rec.premium = true
	Profile.markDirty(plr); Economy.changed:Fire(plr)
	return true, P.name .. "  ·  premium unlocked"
end

-- login gifts: one a day; a missed day pauses the run (you pick up where you
-- left off) instead of starting it over
local function dayKey(offsetDays) return os.date("!%Y-%m-%d", os.time() + (offsetDays or 0) * 86400) end
function Economy.loginStatus(plr)
	local p = Profile.get(plr)
	local L = p.login or {}
	p.login = L
	local today = dayKey(0)
	local streak = L.streak or 0
	local claimed = L.claimed == today
	local nextStreak = claimed and streak or streak + 1
	local n = #Catalog.LOGIN.days
	return {day = (nextStreak - 1) % n + 1, claimed = claimed, streak = nextStreak}
end
function Economy.loginClaim(plr)
	local st = Economy.loginStatus(plr)
	if st.claimed then return false, "already claimed today: come back tomorrow" end
	local reward = Catalog.LOGIN.days[st.day]
	if not reward then return false, "no reward today" end
	local p = Profile.get(plr)
	p.login.streak = st.streak
	p.login.claimed = dayKey(0)
	local line, crate = Economy.grantReward(plr, reward)
	return true, "DAY " .. st.day .. "  ·  " .. line, crate
end

function Economy.exchange(plr, tier)
	local t = E.exchange[tier]
	if not t then return false, "no such tier" end
	local ok, msg = Economy.spend(plr, 0, t.crowns); if not ok then return false, msg end
	Profile.get(plr).wallet.marks += t.marks
	Profile.markDirty(plr); Economy.changed:Fire(plr)
	return true, string.format("+%d Marks for %d Crowns", t.marks, t.crowns)
end

-- Developer Product receipt: credit once per receipt id
function Economy.grantProduct(plr, productId, receiptId)
	local p = Profile.get(plr)
	if receiptId and p.receipts[receiptId] then return true end
	for _, prod in ipairs(E.products) do
		if prod.id ~= 0 and prod.id == productId then
			p.wallet.crowns += prod.crowns
			if receiptId then p.receipts[receiptId] = true end
			Profile.markDirty(plr); Profile.save(plr); Economy.changed:Fire(plr)
			log(plr.Name, "bought", prod.crowns, "Crowns")
			return true
		end
	end
	return false
end

return Economy
