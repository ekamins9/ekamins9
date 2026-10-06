--[[ LEADERBOARDS — the season's boards (Scoreboard writes LB_Warfront kills
     and LB_<bracket> ratings), for the menu's board and the Courtyard's Hall of
     Champions.
       Leaderboards.top(which, n)   -> {{rank, id, name, value}} ("Warfront", "1v1", …)
       Leaderboards.nameOf(userId)
       Leaderboards.lookOf(userId)  -> {loadout, appearance, weight} | nil
                                       (a statue's look: the player's active class,
                                       read from their saved profile when they're away)
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
	local key = "LB_" .. which
	local c = boards[key]
	if c and os.time() - c.at < 60 and #c.rows >= math.min(n, #c.rows) then
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
			local v = which == "Warfront" and (pr.stats.kill or 0) or (pr.rating[which] or Catalog.ECONOMY.ratingStart)
			table.insert(rows, {id = p.UserId, name = p.DisplayName, value = v})
		end
		table.sort(rows, function(a, b) return a.value > b.value end)
		for i, r in ipairs(rows) do r.rank = i end
	end
	boards[key] = {at = os.time(), rows = rows}
	local out = {}
	for i = 1, math.min(n, #rows) do out[i] = rows[i] end
	return out
end

local function lookFrom(p)
	if type(p) ~= "table" or type(p.classes) ~= "table" then return nil end
	local active = GameConfig.CLASSES[p.active] and p.active or GameConfig.DEFAULT_CLASS
	local lo = p.classes[active]
	if type(lo) ~= "table" then return nil end
	return {loadout = lo, appearance = p.appearance, weight = GameConfig.CLASSES[active].weight}
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
