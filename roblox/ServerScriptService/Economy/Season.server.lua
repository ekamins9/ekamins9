--[[ SEASON — the season's end and its rewards (Catalog ▸ Economy ▸ seasonRewards).
     The season ends at 00:00 UTC on Catalog ▸ Pass `ends`. Then:

       THE BOARDS: the first server to notice takes the job (a lease in
       Season_v1), reads each board (LB_Warfront to 1000, LB_1v1 / 2v2 / 3v3 to
       100) and writes every rewarded player's line into SeasonGrants_v1
       ("u<id>": a list), a little at a time (the DataStore budget). A server
       that dies mid-way leaves the lease to run out; the next one starts over
       (a grant already written for that board and season isn't written twice).
       THE TIERS: the ranked tier you finished in (your best bracket, placements
       done) is paid to you the first time you join after the end (the profile
       remembers: seasonPaid[season]).
     Whoever joins with grants waiting gets them (Economy.grantReward) and a
     toast; the list is cleared as it's paid.

       Season.ended() -> bool        Season.endsAt() -> unix time ]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))

local PASS, ECON = Catalog.PASS, Catalog.ECONOMY
local SEASON = PASS.season
local REWARDS = ECON.seasonRewards or {}
local LEASE = 15 * 60          -- seconds a payout job is held
local WRITE_GAP = 0.8          -- seconds between grant writes (the budget)

local function endsAt()
	local y, m, d = tostring(PASS.ends or ""):match("^(%d+)-(%d+)-(%d+)$")
	if not y then return math.huge end
	return DateTime.fromUniversalTime(tonumber(y), tonumber(m), tonumber(d)).UnixTimestamp
end
local function ended() return os.time() >= endsAt() end

local function store(name)
	local ok, ds = pcall(DataStoreService.GetDataStore, DataStoreService, name)
	return ok and ds or nil
end
local function hubEvent() return ReplicatedStorage:FindFirstChild("HubEvent") end

-- the best line of a board's rewards for a place (nil past the last)
local function lineFor(list, rank)
	for _, line in ipairs(list or {}) do
		if rank <= line.top then return line end
	end
	return nil
end

-- the tier a rating sits in (the same steps as the menu)
local function tierOf(r)
	local tiers = ECON.rankTiers or {}
	local step = ECON.rankStep or 250
	local i = math.clamp(math.floor((r - 1000) / step), 0, #tiers - 1) + 1
	return tiers[i], i
end

--------------------------------------------------------------------
--  THE BOARDS' PAYOUT (one server, once)
--------------------------------------------------------------------
local function takeJob()
	local ds = store("Season_v1")
	if not ds then return false end
	local got = false
	pcall(ds.UpdateAsync, ds, SEASON .. ":payout", function(old)
		if type(old) == "table" and (old.done or (old.at and os.time() - old.at < LEASE)) then return nil end
		got = true
		return {at = os.time(), job = game.JobId}
	end)
	return got, ds
end

local function grant(grants, id, board, rank, reward)
	local key = "u" .. id
	pcall(grants.UpdateAsync, grants, key, function(old)
		local list = type(old) == "table" and old or {}
		for _, g in ipairs(list) do
			if g.season == SEASON and g.board == board then return nil end   -- (already written)
		end
		table.insert(list, {season = SEASON, board = board, rank = rank, reward = reward})
		return list
	end)
end

local function payBoards()
	local got, jobs = takeJob()
	if not got then return end
	local grants = store("SeasonGrants_v1")
	if not grants then return end
	local LB = require(ServerScriptService:WaitForChild("Hub"):WaitForChild("Leaderboards"))
	local boards = {{key = LB.key("Warfront"), board = "Warfront", lines = REWARDS.Warfront, depth = 1000}}
	for _, b in ipairs({"1v1", "2v2", "3v3"}) do
		table.insert(boards, {key = LB.key(b), board = b, lines = REWARDS.Lists, depth = 100})
	end
	local written = 0
	for _, b in ipairs(boards) do
		local ok, ods = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, b.key)
		if ok and ods and b.lines then
			local okP, pages = pcall(ods.GetSortedAsync, ods, false, 100)
			local rank = 0
			while okP and pages and rank < b.depth do
				for _, it in ipairs(pages:GetCurrentPage()) do
					rank += 1
					if rank > b.depth then break end
					local line = lineFor(b.lines, rank)
					local id = tonumber(it.key)
					if line and id and (it.value or 0) > 0 then
						-- the champion: this season's Unique on top (one of one)
						local reward = line.reward
						local champ = rank == 1 and REWARDS.champions and REWARDS.champions[SEASON]
						if champ and champ[b.board] then
							reward = table.clone(reward)
							reward.skin, reward.from = champ[b.board], SEASON .. " " .. b.board .. " champion"
						end
						grant(grants, id, b.board, rank, reward)
						written += 1
						task.wait(WRITE_GAP)
						-- keep the lease while the job runs
						if written % 100 == 0 then pcall(jobs.SetAsync, jobs, SEASON .. ":payout", {at = os.time(), job = game.JobId}) end
					end
				end
				if pages.IsFinished or rank >= b.depth then break end
				okP = pcall(pages.AdvanceToNextPageAsync, pages)
			end
		end
	end
	pcall(jobs.SetAsync, jobs, SEASON .. ":payout", {done = true, at = os.time(), job = game.JobId, written = written})
	print(string.format("[Season] %s paid out: %d board rewards written", SEASON, written))
end

--------------------------------------------------------------------
--  A PLAYER JOINS: what's waiting for them
--------------------------------------------------------------------
local function boardName(b) return b == "Warfront" and "the Warfront" or ("the " .. b .. " Lists") end

local function payPlayer(plr)
	task.wait(8)   -- (the profile loads first)
	if not plr.Parent then return end
	local notes = {}
	-- the boards
	local grants = store("SeasonGrants_v1")
	if grants then
		local taken
		pcall(grants.UpdateAsync, grants, "u" .. plr.UserId, function(old)
			if type(old) ~= "table" or #old == 0 then return nil end
			taken = old
			return {}
		end)
		for _, g in ipairs(taken or {}) do
			if type(g.reward) == "table" then
				local text = Economy.grantReward(plr, g.reward)
				table.insert(notes, string.format("#%d on %s: %s", g.rank or 0, boardName(g.board), text))
			end
		end
	end
	-- the tier you finished in
	if ended() then
		local p = Profile.get(plr)
		p.seasonPaid = p.seasonPaid or {}
		if not p.seasonPaid[SEASON] then
			p.seasonPaid[SEASON] = true
			local best
			for bracket, r in pairs(p.rating or {}) do
				if (p.placements and p.placements[bracket] or 0) >= (ECON.placementMatches or 10) then
					local name, i = tierOf(r)
					if not best or i > best.i then best = {name = name, i = i} end
				end
			end
			local reward = best and REWARDS.tiers and REWARDS.tiers[best.name]
			if reward then
				local text = Economy.grantReward(plr, reward)
				table.insert(notes, string.format("finishing as %s: %s", best.name, text))
			end
			Profile.markDirty(plr)
		end
	end
	if #notes > 0 then
		local ev = hubEvent()
		if ev then ev:FireClient(plr, "Toast", "SEASON REWARDS  ·  " .. table.concat(notes, "   ·   ")) end
	end
end

Players.PlayerAdded:Connect(function(plr) task.spawn(payPlayer, plr) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(payPlayer, p) end

-- every few minutes: has the season ended, and is the payout still to do?
task.spawn(function()
	while true do
		if ended() then pcall(payBoards) end
		task.wait(300 + math.random(0, 60))
	end
end)
