--[[ STATS — counters and contracts.
       Stats.add(plr, key, n)        "kill", "parry", "chamber", "win", "round", "drill", "kill_<Family>", "win_<bracket>", "hill"
       Stats.contracts(plr)          today's three + the weekly, with progress (generated on first call each day)
       Stats.weaponKill(plr, weaponId)   counts kill, kill_<family> and byWeapon
     Contracts pay through Economy when they complete. Combat code reports
     parries and chambers through _G.StatHook(character, key). ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Economy = require(script.Parent:WaitForChild("Economy"))

local Stats = {}
Stats.changed = Instance.new("BindableEvent")   -- (plr, contractText) when a contract completes

local function dayKey() return os.date("!%Y-%m-%d") end
-- week of the year, Sunday-based: Roblox os.date has no %V (ISO week); it errors on it
local function weekKey() return os.date("!%Y-W%U") end

-- deterministic pick of N contract ids for a date
local function pick(seedStr, n, weekly)
	local pool = {}
	for _, c in ipairs(Catalog.CONTRACTS) do if (c.weekly == true) == weekly then table.insert(pool, c) end end
	local seed = 0
	for i = 1, #seedStr do seed = (seed * 31 + seedStr:byte(i)) % 2147483647 end
	local rng = Random.new(seed)
	local out = {}
	while #out < n and #pool > 0 do table.insert(out, table.remove(pool, rng:NextInteger(1, #pool)).id) end
	return out
end

function Stats.contracts(plr)
	local p = Profile.get(plr)
	local c = p.contracts
	if c.day ~= dayKey() then
		c.day = dayKey(); c.items = {}
		for _, id in ipairs(pick(c.day, 3, false)) do table.insert(c.items, {id = id, n = 0, done = false}) end
		Profile.markDirty(plr)
	end
	if c.week ~= weekKey() then
		c.week = weekKey(); local ids = pick(c.week, 1, true); c.weekly = ids[1] and {id = ids[1], n = 0, done = false} or nil
		Profile.markDirty(plr)
	end
	local out = {}
	local function row(it)
		local def; for _, d in ipairs(Catalog.CONTRACTS) do if d.id == it.id then def = d end end
		if def then table.insert(out, {id = it.id, text = def.text, n = it.n, goal = def.goal, pay = def.pay, done = it.done, weekly = def.weekly == true}) end
	end
	for _, it in ipairs(c.items or {}) do row(it) end
	if c.weekly then row(c.weekly) end
	return out
end

local function progress(plr, key, n)
	local p = Profile.get(plr)
	Stats.contracts(plr)   -- ensure today's exist
	local list = {}
	for _, it in ipairs(p.contracts.items or {}) do table.insert(list, it) end
	if p.contracts.weekly then table.insert(list, p.contracts.weekly) end
	for _, it in ipairs(list) do
		local def; for _, d in ipairs(Catalog.CONTRACTS) do if d.id == it.id then def = d end end
		if def and not it.done and def.stat == key then
			it.n = math.min(def.goal, it.n + n)
			if it.n >= def.goal then
				it.done = true
				p.wallet.marks += def.pay
				Stats.changed:Fire(plr, def.text, def.pay)
			end
			Profile.markDirty(plr)
		end
	end
end

function Stats.add(plr, key, n)
	n = n or 1
	Profile.addStat(plr, key, n)
	progress(plr, key, n)
end

function Stats.weaponKill(plr, weaponId)
	local p = Profile.get(plr)
	local w = Catalog.WEAPON[weaponId]
	Stats.add(plr, "kill", 1)
	if w then Stats.add(plr, "kill_" .. w.family, 1); p.stats.byWeapon[weaponId] = (p.stats.byWeapon[weaponId] or 0) + 1 end
	-- earned skins
	for _, s in ipairs(Catalog.SKINS) do
		if s.crate == "earned" and s.weapon == weaponId and (p.stats.byWeapon[weaponId] or 0) >= (s.kills or 1e9) and not Profile.has(plr, "skins", s.id) then
			Profile.grant(plr, "skins", s.id)
			Stats.changed:Fire(plr, "Skin earned: " .. w.name .. " · " .. s.name, 0)
		end
	end
end

-- combat reports through this (CombatServer: _G.StatHook(targetChar, "parry"))
_G.StatHook = function(char, key)
	local plr = Players:GetPlayerFromCharacter(char)
	if plr then Stats.add(plr, key, 1) end
end

return Stats
