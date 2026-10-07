--[[ LEADERBOARDS — the season's boards (Scoreboard writes LB_Warfront kills
     and LB_<bracket> ratings), for the menu's board and the Courtyard's Hall of
     Champions.
       Leaderboards.top(which, n)   -> {{rank, id, name, value}} ("Warfront", "1v1", …)
       Leaderboards.nameOf(userId)
       Leaderboards.lookOf(userId)  -> {loadout, appearance, weight} | nil
                                       (a statue's look: the player's active class,
                                       read from their saved profile when they're away)
       Leaderboards.place(which, userId) -> rank within the top 100 | nil
       Leaderboards.key(which)      the board's OrderedDataStore: "LB_<which>" in
                                    Season 1, "LB_<season>_<which>" after (a new season, new boards)
       Leaderboards.seasonKills(profile)  the Warfront board's value: kills since the season began
     Cached for a minute (looks for ten). In Studio, or while a board is still
     empty, the players in this server stand in. ]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))

local Leaderboards = {}
local boards, names, looks = {}, {}, {}
local SEASON = Catalog.PASS and Catalog.PASS.season or "S1"

function Leaderboards.key(which)
	return SEASON == "S1" and ("LB_" .. which) or ("LB_" .. SEASON .. "_" .. which)
end
-- kills this season: the lifetime count less where it stood when the season began
-- (Season 1 began at zero)
function Leaderboards.seasonKills(p)
	local total = p.stats and p.stats.kill or 0
	if SEASON == "S1" then return total end
	if type(p.seasonBase) ~= "table" or p.seasonBase.season ~= SEASON then p.seasonBase = {season = SEASON, kill = total} end
	return math.max(0, total - (p.seasonBase.kill or 0))
end

function Leaderboards.nameOf(userId)
	if names[userId] then return names[userId] end
	local here = Players:GetPlayerByUserId(userId)
	local name = here and here.DisplayName
	if not name then local ok, n = pcall(Players.GetNameFromUserIdAsync, Players, userId); name = ok and n or ("#" .. tostring(userId)) end
	names[userId] = name
	return name
end

function Leaderboards.top(which, n)
	which = type(which) == "string" and which:gsub("[^%w]", ""):sub(1, 12) or "Warfront"
	n = n or 10
	local key = Leaderboards.key(which)
	local c = boards[key]
	if c and os.time() - c.at < 60 and (c.n or 0) >= n then
		local out = {}
		for i = 1, math.min(n, #c.rows) do out[i] = c.rows[i] end
		return out
	end
	local rows = {}
	pcall(function()
		local ds = DataStoreService:GetOrderedDataStore(key)
		local page = ds:GetSortedAsync(false, math.max(n, 10))
		for i, it in ipairs(page:GetCurrentPage()) do
			local id = tonumber(it.key) or 0
			table.insert(rows, {rank = i, id = id, name = Leaderboards.nameOf(id), value = it.value})
		end
	end)
	-- Studio / empty boards: the players here stand in so nothing is blank
	if #rows == 0 then
		for _, p in ipairs(Players:GetPlayers()) do
			local pr = Profile.get(p)
			local v = which == "Warfront" and Leaderboards.seasonKills(pr) or (pr.rating[which] or Catalog.ECONOMY.ratingStart)
			table.insert(rows, {id = p.UserId, name = p.DisplayName, value = v})
		end
		table.sort(rows, function(a, b) return a.value > b.value end)
		for i, r in ipairs(rows) do r.rank = i end
	end
	boards[key] = {at = os.time(), rows = rows, n = math.max(n, 10)}
	local out = {}
	for i = 1, math.min(n, #rows) do out[i] = rows[i] end
	return out
end

function Leaderboards.place(which, userId)
	for _, r in ipairs(Leaderboards.top(which, 100)) do
		if r.id == userId then return r.rank end
	end
	return nil
end

local function lookFrom(p)
	if type(p) ~= "table" or type(p.classes) ~= "table" then return nil end
	local active = GameConfig.CLASSES[p.active] and p.active or GameConfig.DEFAULT_CLASS
	local lo = p.classes[active]
	if type(lo) ~= "table" then return nil end
	return {loadout = lo, appearance = p.appearance, weight = GameConfig.CLASSES[active].weight}
end

-- a player's saved profile (here: the live one), cached five minutes; nil if unknown
local saved = {}
function Leaderboards.profileOf(userId)
	local here = Players:GetPlayerByUserId(userId)
	if here then return Profile.get(here), here end
	local c = saved[userId]
	if c and os.time() - c.at < 300 then return c.p, nil end
	local p
	pcall(function()
		local ds = DataStoreService:GetDataStore("Profiles_v2")
		p = ds:GetAsync("u" .. userId)
	end)
	if type(p) ~= "table" then p = nil end
	saved[userId] = {at = os.time(), p = p}
	return p, nil
end

function Leaderboards.lookOf(userId)
	local here = Players:GetPlayerByUserId(userId)
	if here then return lookFrom(Profile.get(here)) end
	local c = looks[userId]
	if c and os.time() - c.at < 600 then return c.look end
	local look
	pcall(function()
		local ds = DataStoreService:GetDataStore("Profiles_v2")
		look = lookFrom(ds:GetAsync("u" .. userId))
	end)
	looks[userId] = {at = os.time(), look = look}
	return look
end

return Leaderboards
