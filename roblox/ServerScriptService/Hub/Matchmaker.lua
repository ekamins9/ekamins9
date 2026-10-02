--[[ MATCHMAKER — The Lists queue (1v1 / 2v2 / 3v3, casual or ranked).
     Every public (Hub) server runs this. A party that presses FIND MATCH
     becomes a TICKET in a MemoryStore queue per bracket+kind; one server at a
     time (a lock key) pairs tickets whose ratings are close enough — the
     window widens the longer a ticket waits — and writes a MATCH RECORD for
     each player (keyed by user id) holding a freshly reserved server code and
     the sides. Each server polls the records for its own queued players and
     teleports them (HubServer does the teleport through Matchmaker.onMatch).

       Matchmaker.enqueue(ticket)   ticket = {id=, bracket="1v1", ranked=bool, players={ids}, rating=, jobId=}
       Matchmaker.dequeue(ticketId)
       Matchmaker.status(ticketId)  -> {waiting=seconds, window=rating} | nil
       Matchmaker.onMatch = function(ticketId, match) end   -- match = {code=, bracket=, ranked=, sides={A={ids},B={ids}}, players={ids}}

     Studio (no MemoryStore / teleports): FIND MATCH matches against nobody —
     the ticket is answered at once with sides A = the party, B = empty, so
     the flow can be seen end to end (Game.requestMode switches to Lists). ]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local Matchmaker = {}
Matchmaker.onMatch = nil
local STUDIO = RunService:IsStudio()
local function log(...) DebugFlags.log("Matchmaker", ...) end

local POLL = 4              -- seconds between pairing / record checks
local TICKET_TTL = 15 * 60  -- a ticket dies after this (the client re-queues)
local RECORD_TTL = 120      -- a match record waits this long to be collected
local WINDOW0, WIDEN, WINDOW_MAX = 100, 40, 1000   -- rating window: start, +per POLL, cap

local function sizeOf(bracket) return tonumber(bracket:match("^(%d)v%d$")) or 1 end
local function queueName(bracket, ranked) return "MMQ_" .. bracket .. (ranked and "_R" or "_C") end

local queues, records, lock = {}, nil, nil
pcall(function()
	records = MemoryStoreService:GetSortedMap("MMRecords")
	lock = MemoryStoreService:GetSortedMap("MMLock")
end)
local function queueFor(bracket, ranked)
	local name = queueName(bracket, ranked)
	if not queues[name] then pcall(function() queues[name] = MemoryStoreService:GetSortedMap(name) end) end
	return queues[name]
end

local local_ = {}   -- [ticketId] = ticket (the ones queued from THIS server)

--------------------------------------------------------------------
--  TICKETS
--------------------------------------------------------------------
function Matchmaker.enqueue(t)
	t.at = os.time()
	t.jobId = game.JobId
	local_[t.id] = t
	if STUDIO or not queueFor(t.bracket, t.ranked) then
		-- no matchmaking pool: answer at once (dev flow)
		task.delay(1.5, function()
			if local_[t.id] and Matchmaker.onMatch then
				local_[t.id] = nil
				Matchmaker.onMatch(t.id, {code = nil, bracket = t.bracket, ranked = t.ranked, sides = {A = t.players, B = {}}, players = t.players, studio = true})
			end
		end)
		return true
	end
	local ok, err = pcall(function() queueFor(t.bracket, t.ranked):SetAsync(t.id, t, TICKET_TTL) end)
	if not ok then warn("[Matchmaker] enqueue failed:", err); local_[t.id] = nil; return false, "matchmaking is unavailable right now" end
	log("queued", t.id, t.bracket, t.ranked and "ranked" or "casual", "rating", t.rating)
	return true
end

function Matchmaker.dequeue(id)
	local t = local_[id]
	local_[id] = nil
	if t and queueFor(t.bracket, t.ranked) then pcall(function() queueFor(t.bracket, t.ranked):RemoveAsync(id) end) end
end

function Matchmaker.status(id)
	local t = local_[id]
	if not t then return nil end
	local waited = os.time() - t.at
	return {waiting = waited, window = math.min(WINDOW_MAX, WINDOW0 + WIDEN * math.floor(waited / POLL))}
end

--------------------------------------------------------------------
--  PAIRING (one server holds the lock for a pass)
--------------------------------------------------------------------
local function window(t) return math.min(WINDOW_MAX, WINDOW0 + WIDEN * math.floor((os.time() - t.at) / POLL)) end

-- greedy: oldest ticket first, fill two sides of `size` with compatible tickets
local function pair(tickets, size)
	table.sort(tickets, function(a, b) return a.at < b.at end)
	local used = {}
	local matches = {}
	for i, anchor in ipairs(tickets) do
		if not used[anchor.id] then
			local sides = {A = {}, B = {}}
			local picked = {anchor}
			local countA, countB = #anchor.players, 0
			for _, p in ipairs(anchor.players) do table.insert(sides.A, p) end
			for j = i + 1, #tickets do
				local t = tickets[j]
				if not used[t.id] and math.abs(t.rating - anchor.rating) <= math.min(window(t), window(anchor)) then
					local n = #t.players
					if countA + n <= size then
						for _, p in ipairs(t.players) do table.insert(sides.A, p) end; countA += n; table.insert(picked, t)
					elseif countB + n <= size then
						for _, p in ipairs(t.players) do table.insert(sides.B, p) end; countB += n; table.insert(picked, t)
					end
					if countA == size and countB == size then break end
				end
			end
			if countA == size and countB == size then
				for _, t in ipairs(picked) do used[t.id] = true end
				table.insert(matches, {sides = sides, tickets = picked})
			end
		end
	end
	return matches
end

local function pass(bracket, ranked)
	local q = queueFor(bracket, ranked)
	if not q then return end
	local ok, items = pcall(function() return q:GetRangeAsync(Enum.SortDirection.Ascending, 100) end)
	if not ok or not items then return end
	local tickets = {}
	for _, it in ipairs(items) do if type(it.value) == "table" and it.value.players then table.insert(tickets, it.value) end end
	if #tickets < 2 then return end
	for _, m in ipairs(pair(tickets, sizeOf(bracket))) do
		local okR, code = pcall(TeleportService.ReserveServer, TeleportService, game.PlaceId)
		if okR then
			local players = {}
			for _, id in ipairs(m.sides.A) do table.insert(players, id) end
			for _, id in ipairs(m.sides.B) do table.insert(players, id) end
			local record = {code = code, bracket = bracket, ranked = ranked, sides = m.sides, players = players, at = os.time()}
			for _, t in ipairs(m.tickets) do
				pcall(function() q:RemoveAsync(t.id) end)
				pcall(function() records:SetAsync("t:" .. t.id, record, RECORD_TTL) end)
			end
			log("matched", bracket, ranked and "ranked" or "casual", #players, "players")
		else
			warn("[Matchmaker] ReserveServer failed:", code)
		end
	end
end

-- collect records for the tickets this server queued
local function collect()
	for id, t in pairs(local_) do
		local ok, rec = pcall(function() return records:GetAsync("t:" .. id) end)
		if ok and type(rec) == "table" then
			local_[id] = nil
			pcall(function() records:RemoveAsync("t:" .. id) end)
			if Matchmaker.onMatch then Matchmaker.onMatch(id, rec) end
		end
	end
end

if not STUDIO and records and lock then
	task.spawn(function()
		local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
		local brackets = (GameConfig.DOORS.Lists and GameConfig.DOORS.Lists.brackets) or {"1v1", "2v2", "3v3"}
		while true do
			task.wait(POLL)
			if next(local_) then
				-- refresh our tickets' TTL and look for answers
				for id, t in pairs(local_) do pcall(function() queueFor(t.bracket, t.ranked):SetAsync(id, t, TICKET_TTL) end) end
				collect()
			end
			-- one pairing pass per POLL across the whole game: whoever takes the lock
			local got = false
			pcall(function()
				lock:UpdateAsync("pairing", function(old)
					if old and os.time() - old < POLL - 1 then return nil end   -- someone else has it
					got = true
					return os.time()
				end, POLL * 2)
			end)
			if got then
				for _, b in ipairs(brackets) do pass(b, false); pass(b, true) end
			end
		end
	end)
end

return Matchmaker
