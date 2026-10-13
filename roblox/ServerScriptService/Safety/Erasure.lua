--[[ ERASURE — a player's "right to be forgotten". Roblox forwards these requests to the
     creator (a message in your Roblox inbox naming a user id), and the law says every bit of
     that player's data goes: their keys, and their id inside anything else.

     The keys Roblox can delete by itself if you set up deletion templates (Creator Hub ▸
     Configurations ▸ Data stores manager ▸ RTBF Deletion; docs/LAUNCH.md lists them):
       Profiles_v2 / Profiles_v1 / AdminQueue_v1 / Bans_v1    key  u{UserId}
       LB_Warfront / LB_1v1 / LB_2v2 / LB_3v3 (ordered)       key  {UserId}
     What no template can reach, their id INSIDE shared records, this does (and the keys
     too, so one button is enough):
       Staff_v1 "roles" · Bans_v1 "index" · AdminLog_v1 "log" · TradeLog_v1 (each trade's key
       carries both ids)

       Erasure.erase(userId) -> ok, report     (yields; the Owner's ERASE DATA in the admin panel)

     They're kicked from every server first and their last save is let go, so nothing
     writes them back. ]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Erasure = {}

local function store(name)
	local ok, s = pcall(DataStoreService.GetDataStore, DataStoreService, name)
	return ok and s or nil
end
local function ordered(name)
	local ok, s = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, name)
	return ok and s or nil
end

local KEYED = {"Profiles_v2", "Profiles_v1", "AdminQueue_v1", "Bans_v1"}   -- key "u<id>"
local function boards()
	local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
	local season = Catalog.PASS and Catalog.PASS.season or "S1"
	local out = {}
	for _, which in ipairs({"Warfront", "1v1", "2v2", "3v3"}) do
		table.insert(out, "LB_" .. which)
		if season ~= "S1" then table.insert(out, "LB_" .. season .. "_" .. which) end
	end
	return out
end

function Erasure.erase(userId)
	userId = tonumber(userId)
	if not userId or userId <= 0 then return false, "which user id?" end
	local report = {}
	local function note(fmt, ...) table.insert(report, string.format(fmt, ...)) end

	-- off every server first, so no session saves them back after we delete
	local here = Players:GetPlayerByUserId(userId)
	if here then here:Kick("Your Steel & Glory data is being deleted, as asked.") end
	pcall(MessagingService.PublishAsync, MessagingService, "Admin", {kind = "kick", userId = userId, text = "Your Steel & Glory data is being deleted, as asked."})
	task.wait(8)

	local key = "u" .. userId
	for _, name in ipairs(KEYED) do
		local s = store(name)
		local ok = s and pcall(s.RemoveAsync, s, key)
		note("%s %s: %s", name, key, ok and "deleted" or "couldn't reach")
	end
	for _, name in ipairs(boards()) do
		local s = ordered(name)
		local ok = s and pcall(s.RemoveAsync, s, tostring(userId))
		note("%s %d: %s", name, userId, ok and "deleted" or "couldn't reach")
	end

	-- their id inside shared records
	local staff = store("Staff_v1")
	if staff then
		local ok = pcall(staff.UpdateAsync, staff, "roles", function(old)
			if type(old) ~= "table" then return nil end
			old[tostring(userId)] = nil
			return old
		end)
		note("Staff_v1 roles: %s", ok and "scrubbed" or "couldn't reach")
	end
	local bans = store("Bans_v1")
	if bans then
		local ok = pcall(bans.UpdateAsync, bans, "index", function(old)
			if type(old) ~= "table" then return nil end
			local out = {}
			for _, b in ipairs(old) do if b.id ~= userId then table.insert(out, b) end end
			return out
		end)
		note("Bans_v1 index: %s", ok and "scrubbed" or "couldn't reach")
	end
	local log = store("AdminLog_v1")
	if log then
		local ok = pcall(log.UpdateAsync, log, "log", function(old)
			if type(old) ~= "table" then return nil end
			local out = {}
			for _, e in ipairs(old) do if e.by ~= userId and e.target ~= userId then table.insert(out, e) end end
			return out
		end)
		note("AdminLog_v1: %s", ok and "scrubbed" or "couldn't reach")
	end
	-- trades: "t<time>_<a>_<b>"
	local trades = store("TradeLog_v1")
	if trades then
		local n, ok = 0, pcall(function()
			local pages = trades:ListKeysAsync("t")
			while true do
				for _, k in ipairs(pages:GetCurrentPage()) do
					local _, a, b = k.KeyName:match("^t(%d+)_(%d+)_(%d+)$")
					if tonumber(a) == userId or tonumber(b) == userId then
						trades:RemoveAsync(k.KeyName)
						n += 1
					end
				end
				if pages.IsFinished then break end
				pages:AdvanceToNextPageAsync()
			end
		end)
		note("TradeLog_v1: %s", ok and (n .. " trades deleted") or "couldn't reach")
	end
	return true, report
end

return Erasure
