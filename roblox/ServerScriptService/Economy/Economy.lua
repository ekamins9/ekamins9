--[[ ECONOMY — every way Marks and Crowns move, all server-side:
       Economy.award(plr, events)        round-end pay: {round=1, win=1, kill=n, parry=n, chamber=n, drill=n}
       Economy.spend(plr, marks, crowns) -> ok, msg
       Economy.buy(plr, kind, id, currency)   kind: piece | pack | color | hairColor | beard | weapon
       Economy.openCrate(plr, crateId)   -> result {skinId, name, rarity, dup, refund} | nil, msg
       Economy.exchange(plr, tier)       Crowns -> Marks
       Economy.grantProduct(plr, productId, receiptId)   Robux Crown bundles (EconomyServer's ProcessReceipt)
       Economy.levelFor(xp)
     Nothing here trusts a client: prices and odds come from Catalog, results
     are decided before the client is told. A server flagged noRewards
     (cheats on) pays nothing. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local Economy = {}
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
	Profile.markDirty(plr)
	return leveled
end

function Economy.award(plr, events)
	if noRewards() then return {marks = 0, xp = 0, levels = 0, blocked = true} end
	local p = Profile.get(plr)
	local marks, xp = 0, 0
	for key, n in pairs(events or {}) do
		local e = E.earn[key]
		if e and type(n) == "number" and n > 0 then marks += e.marks * n; xp += e.xp * n end
	end
	local today = os.date("!%Y-%m-%d")
	local firstWin = false
	if events and (events.win or 0) > 0 and p.lastWinDay ~= today then
		p.lastWinDay = today; marks += E.earn.firstWinOfDay.marks; firstWin = true
	end
	p.wallet.marks += marks
	local levels = Economy.addXP(plr, xp)
	Profile.markDirty(plr)
	Economy.changed:Fire(plr)
	return {marks = marks, xp = xp, levels = levels, firstWin = firstWin, level = p.level}
end

function Economy.spend(plr, marks, crowns)
	local p = Profile.get(plr)
	marks, crowns = marks or 0, crowns or 0
	if p.wallet.marks < marks then return false, "not enough Marks" end
	if p.wallet.crowns < crowns then return false, "not enough Crowns" end
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
		if not Catalog.isFree(pc) and not Catalog.onSale(pc.pack) then return false, "not in today's store" end
		local m, c = price(pc.marks, pc.crowns, currency); if not m then return false, c end
		local ok, msg = Economy.spend(plr, m, c); if not ok then return false, msg end
		Profile.grant(plr, "pieces", id); Economy.changed:Fire(plr); return true, pc.name .. " bought"
	elseif kind == "pack" then
		local pk = Catalog.PACKS[id]; if not pk then return false, "no such pack" end
		if not Catalog.onSale(id) then return false, "not in today's store" end
		local m, c, list = 0, 0, {}
		for _, pc in ipairs(Catalog.PIECES) do
			if pc.pack == id and not Profile.has(plr, "pieces", pc.id) then table.insert(list, pc); m += pc.marks; c += pc.crowns end
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
		local sk = Catalog.SKIN[id]; if not sk then return false, "no such skin" end
		if sk.crate then return false, "that skin comes from a crate" end
		if sk.pack and not Catalog.onSale(sk.pack) then return false, "not in today's store" end
		if Profile.has(plr, "skins", id) then return false, "already owned" end
		local m, c = price(sk.marks, sk.crowns, currency); if not m then return false, c end
		local ok, msg = Economy.spend(plr, m, c); if not ok then return false, msg end
		Profile.grant(plr, "skins", id); Economy.changed:Fire(plr); return true, sk.name .. " bought"
	end
	return false, "unknown purchase"
end

--------------------------------------------------------------------
--  CRATES
--------------------------------------------------------------------
function Economy.openCrate(plr, crateId)
	local crate = Catalog.CRATES[crateId]
	if not crate then return nil, "no such crate" end
	local pool = Catalog.crateSkins(crateId)
	if #pool == 0 then return nil, "this crate is empty (no skins name it)" end
	local p = Profile.get(plr)
	p.crates[crateId] = p.crates[crateId] or {opens = 0, sinceLegendary = 0}
	local cc = p.crates[crateId]
	local ok, msg = Economy.spend(plr, 0, crate.cost); if not ok then return nil, msg end
	-- rarity by odds, pity overrides
	local rarity
	if cc.sinceLegendary >= (crate.pity or 20) - 1 then rarity = "Legendary"
	else
		local r, acc = math.random() * 100, 0
		for _, name in ipairs({"Legendary", "Epic", "Rare", "Common"}) do
			acc += crate.odds[name] or 0
			if r < acc then rarity = name; break end
		end
		rarity = rarity or "Common"
	end
	local picks = {}
	for _, s in ipairs(pool) do if s.rarity == rarity then table.insert(picks, s) end end
	if #picks == 0 then picks = pool end
	local win = picks[math.random(#picks)]
	cc.opens += 1
	cc.sinceLegendary = win.rarity == "Legendary" and 0 or cc.sinceLegendary + 1
	local dup = Profile.has(plr, "skins", win.id)
	local refund = 0
	if dup then refund = (crate.refund or {})[win.rarity] or 0; p.wallet.marks += refund
	else Profile.grant(plr, "skins", win.id) end
	Profile.markDirty(plr)
	Economy.changed:Fire(plr)
	log(plr.Name, "opened", crateId, "->", win.id, win.rarity, dup and ("dup +" .. refund) or "")
	return {skinId = win.id, weapon = win.weapon, name = Catalog.WEAPON[win.weapon].name .. " · " .. win.name, rarity = win.rarity, dup = dup, refund = refund,
		sinceLegendary = cc.sinceLegendary, opens = cc.opens}
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
