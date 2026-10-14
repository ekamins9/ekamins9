--[[ REMINDERS (server) — Roblox's experience notifications: a phone/desktop notification that
     brings a player back. Players opt in themselves (Roblox's prompt, which the menu shows
     right after they claim the day's gift: HubMenu's HX.askReminders); Roblox lets a game send
     each of them at most one a day, only to players 13+.

     Two kinds, each a notification string you make on the Creator Dashboard (your game ›
     Engagement › Notifications), its id typed into Studio › ServerStorage › NotifyIds:
       Weekend   "{event} is on in Steel & Glory: come and fight!"        (parameter: event)
                 sent once, as a weekend event (or a dated one) begins, to everyone seen in
                 the last two weeks
       Daily     "Your day {day} gift is waiting in the Courtyard."      (parameter: day)
                 about a day after someone's last visit, when their streak has a gift waiting

     Sending goes through Roblox's Open Cloud from inside the game (HttpService): it needs
     Game Settings › Security › Allow HTTP Requests ON, and an Open Cloud API key with
     "user.user-notification: write" for this experience, saved as a secret named
     "notifications" (Creator Dashboard › your game › Secrets). Until all of that is there,
     nothing is sent and nothing breaks (one line in the output says why).

     Who to remind: OrderedDataStore RecentPlayers_v1 (key = user id, value = the last time
     they left). It's personal data: the right-to-erasure templates and Safety › Erasure
     cover it. Only one server sends each batch (a MemoryStore lock). ]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Stores = require(game:GetService("ServerScriptService"):WaitForChild("Safety"):WaitForChild("Stores"))
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Drops = require(ReplicatedStorage:WaitForChild("Drops"))

local RECENT_DAYS = 14          -- a weekend notice goes to players seen in this many days
local DAILY_AFTER = {20, 30}    -- hours since they left: the window for the daily-gift notice
local BATCH = 200               -- at most this many sends a batch

local recent, profiles
pcall(function() recent = Stores.ordered("RecentPlayers_v1") end)
pcall(function() profiles = Stores.get("Profiles_v2") end)
local locks
pcall(function() locks = MemoryStoreService:GetSortedMap("ReminderLocks") end)

-- when they leave: when they were last here (who to remind)
Players.PlayerRemoving:Connect(function(plr)
	if not recent or RunService:IsStudio() then return end
	task.spawn(function() pcall(recent.SetAsync, recent, tostring(plr.UserId), os.time()) end)
end)

--------------------------------------------------------------------
--  SENDING
--------------------------------------------------------------------
local function messageId(kind)
	local f = ServerStorage:FindFirstChild("NotifyIds")
	local v = f and f:FindFirstChild(kind)
	return v and v:IsA("StringValue") and v.Value ~= "" and v.Value or nil
end

local secret
local warned = false
local function ready()
	if not HttpService.HttpEnabled then
		if not warned then warned = true; print("[Reminders] off: Allow HTTP Requests is off in Game Settings") end
		return false
	end
	if not secret then
		local ok, s = pcall(HttpService.GetSecret, HttpService, "notifications")
		if ok then secret = s
		else
			if not warned then warned = true; print("[Reminders] off: no secret named \"notifications\" (an Open Cloud key)") end
			return false
		end
	end
	return true
end

-- one notification to one player; params = {name = string | number}
local function send(userId, kind, params, launch)
	local id = messageId(kind)
	if not id or not ready() then return false end
	local parameters = {}
	for k, v in pairs(params or {}) do
		parameters[k] = type(v) == "number" and {int64Value = v} or {stringValue = tostring(v)}
	end
	local body = HttpService:JSONEncode({
		source = {universe = "universes/" .. game.GameId},
		payload = {messageId = id, type = "MOMENT", parameters = parameters,
			joinExperience = {launchData = launch or kind}},
		analyticsData = {category = kind},
	})
	local ok, res = pcall(HttpService.RequestAsync, HttpService, {
		Url = string.format("https://apis.roblox.com/cloud/v2/users/%d/notifications", userId),
		Method = "POST",
		Headers = {["Content-Type"] = "application/json", ["x-api-key"] = secret},
		Body = body,
	})
	return ok and res and res.Success
end

-- only one server sends a batch: whoever takes the lock first
local function claim(key, seconds)
	if not locks then return false end
	local mine = false
	pcall(function()
		locks:UpdateAsync(key, function(old)
			if old then return nil end
			mine = true
			return game.JobId
		end, seconds)
	end)
	return mine
end

-- players last seen within `fromHours`..`toHours` ago (newest first)
local function seen(fromHours, toHours)
	local out = {}
	if not recent then return out end
	local now = os.time()
	pcall(function()
		local pages = recent:GetSortedAsync(false, 100, now - toHours * 3600, now - fromHours * 3600)
		while #out < BATCH do
			for _, e in ipairs(pages:GetCurrentPage()) do
				table.insert(out, tonumber(e.key))
				if #out >= BATCH then break end
			end
			if pages.IsFinished then break end
			pages:AdvanceToNextPageAsync()
		end
	end)
	return out
end

local function here(userId) return Players:GetPlayerByUserId(userId) ~= nil end

-- a weekend (or dated) event has begun: tell everyone recent, once
local function weekendCheck()
	if not messageId("Weekend") then return end
	for _, e in ipairs(Drops.events()) do
		local key = "event:" .. tostring(e.id) .. ":" .. tostring(e.from)
		local started = Drops.time(e.from)
		if started and os.time() - started < 6 * 3600 and claim(key, 7 * 86400) then
			local name = e.name or e.title or "A weekend event"
			local n = 0
			for _, uid in ipairs(seen(0, RECENT_DAYS * 24)) do
				if not here(uid) and send(uid, "Weekend", {event = name}, "event") then n += 1 end
				task.wait(0.2)
			end
			print(string.format("[Reminders] %s: %d notified", name, n))
		end
	end
end

-- the daily gift: a day after they left, if a gift is waiting
local function dailyCheck()
	if not messageId("Daily") then return end
	local hour = math.floor(os.time() / 3600)
	if not claim("daily:" .. hour, 2 * 3600) then return end
	local n = 0
	for _, uid in ipairs(seen(DAILY_AFTER[1], DAILY_AFTER[2])) do
		-- (one a day per player whatever we do: this lock keeps us from asking twice)
		if not here(uid) and claim("daily:" .. uid, 22 * 3600) then
			-- (the gift they'd get next: their saved run, as Economy.loginStatus counts it)
			local day = 1
			local ok, p = pcall(function() return profiles and profiles:GetAsync("u" .. uid) end)
			if ok and type(p) == "table" and type(p.login) == "table" then day = (tonumber(p.login.streak) or 0) % 7 + 1 end
			if send(uid, "Daily", {day = day}, "daily") then n += 1 end
			task.wait(0.2)
		end
	end
	if n > 0 then print(string.format("[Reminders] daily gift: %d notified", n)) end
end

-- a gift waiting in their box (Economy ▸ Gifting), when they're not in this server: "Gift", a
-- notification string "{name} sent you a gift in Steel & Glory!" (parameter: name)
_G.NotifyGift = function(userId, fromName)
	if RunService:IsStudio() or not messageId("Gift") then return end
	-- (one a day per player whatever we do: this lock keeps us from asking more than once an hour)
	if not claim("gift:" .. tostring(userId), 3600) then return end
	send(userId, "Gift", {name = tostring(fromName or "Someone")}, "gift")
end

if not RunService:IsStudio() then
	task.spawn(function()
		task.wait(60)
		while true do
			pcall(weekendCheck)
			pcall(dailyCheck)
			task.wait(15 * 60)
		end
	end)
end
