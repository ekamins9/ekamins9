--[[ ADMIN (server) — everything the admin panel does is decided here: who you
     are (Admin ▸ Roles), whether your role may, and whether you outrank the
     player you're acting on. The client only asks.

       AdminRemote (RemoteFunction)  client → server
         "Me"                     -> {role, rank, perms, roles = {name = {rank, color}}, order}
         "Players"                -> players in this server, with their details
         "Lookup", nameOrId       -> {userId, name, role, here, ban}
         "Staff" · "Bans" · "Log" -> lists
         "Act", action, args      -> {ok, msg}
           kick {userId, reason}            ban {userId, name, hours (0 = for good), reason}
           unban {userId}                   goto / bring {userId}    freeze {userId, on}
           heal / kill {userId}             announce {text, all}
           endround {}                      nextmode {mode}          nextmap {map}
           bots {skill, count}              clearbots {}
           currency {userId, kind = "marks"|"crowns", amount (negative takes)}
           item {userId, kind, id, take}    unlockall {userId}       level {userId, level}
           reset {userId}                   setrole {userId, name, role ("" takes it away)}
           shutdown {reason}
       AdminEvent (RemoteEvent)  server → client: "Announce", text, byName, roleName

     A change to someone who isn't in this server (Marks, items, level, reset)
     waits in AdminQueue_v1 and is applied by whichever server has them: right
     away (MessagingService "Admin") or the next time they join. Bans live in
     Bans_v1 and are checked as players join; roles in Staff_v1; every action
     goes in AdminLog_v1 (the LOG tab). ]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Roles = require(script.Parent:WaitForChild("Roles"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Economy = require(ServerScriptService:WaitForChild("Economy"):WaitForChild("Economy"))
local Game = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Game"))

local STUDIO = RunService:IsStudio()
local TOPIC = "Admin"

local remote = Instance.new("RemoteFunction"); remote.Name = "AdminRemote"; remote.Parent = ReplicatedStorage
local event = Instance.new("RemoteEvent"); event.Name = "AdminEvent"; event.Parent = ReplicatedStorage

local function store(name)
	local ok, s = pcall(DataStoreService.GetDataStore, DataStoreService, name)
	return ok and s or nil
end
local staffStore, banStore, queueStore, logStore = store("Staff_v1"), store("Bans_v1"), store("AdminQueue_v1"), store("AdminLog_v1")
local function publish(msg) task.spawn(function() pcall(MessagingService.PublishAsync, MessagingService, TOPIC, msg) end) end

--------------------------------------------------------------------
--  WHO IS WHO
--------------------------------------------------------------------
local staff = {}   -- [userId] = {role, name, by, at}

local function loadStaff()
	if not staffStore then return end
	local ok, data = pcall(staffStore.GetAsync, staffStore, "roles")
	if ok and type(data) == "table" then
		local fresh = {}
		for k, v in pairs(data) do if type(v) == "table" and Roles.roles[v.role] then fresh[tonumber(k)] = v end end
		staff = fresh
	end
end

local function isOwner(userId)
	if game.CreatorType == Enum.CreatorType.User and userId == game.CreatorId then return true end
	for _, id in ipairs(Roles.owners or {}) do if id == userId then return true end end
	if STUDIO and game.CreatorId == 0 then return true end   -- an unpublished place: whoever tests it
	return false
end

local groupRank = {}   -- [userId] = rank in the owning group (looked up as players join)
local function roleOf(userId)
	if isOwner(userId) then return "Owner" end
	if game.CreatorType == Enum.CreatorType.Group and groupRank[userId] == 255 then return "Owner" end
	local s = staff[userId]
	return s and s.role or nil
end
local function rankOf(role) local r = role and Roles.roles[role]; return r and r.rank or 0 end
local function can(role, perm)
	local r = role and Roles.roles[role]
	if not r then return false end
	if r.perms == "*" then return true end
	for _, p in ipairs(r.perms) do if p == perm then return true end end
	return false
end
local function permsOf(role)
	local r = role and Roles.roles[role]
	if not r then return {} end
	if r.perms == "*" then
		return {"view", "kick", "tempban", "ban", "teleport", "health", "announce", "announce_all", "rounds", "bots", "currency", "items", "unlock", "progress", "reset", "staff", "shutdown", "log"}
	end
	return r.perms
end

local function markPlayer(plr)
	local role = roleOf(plr.UserId)
	plr:SetAttribute("StaffRole", role or nil)
end

--------------------------------------------------------------------
--  THE LOG
--------------------------------------------------------------------
-- (kept in memory too: Studio without data store access, or a store hiccup, still shows it)
local memLog = {}
local function logAction(actor, action, targetId, targetName, detail)
	local entry = {at = os.time(), by = actor.UserId, byName = actor.Name, action = action, target = targetId, targetName = targetName, detail = detail}
	print(string.format("[Admin] %s: %s %s %s", actor.Name, action, tostring(targetName or ""), tostring(detail or "")))
	table.insert(memLog, 1, entry)
	while #memLog > 100 do table.remove(memLog) end
	if not logStore then return end
	task.spawn(function()
		pcall(logStore.UpdateAsync, logStore, "log", function(old)
			local list = type(old) == "table" and old or {}
			table.insert(list, 1, entry)
			while #list > 300 do table.remove(list) end
			return list
		end)
	end)
end

--------------------------------------------------------------------
--  CHANGES TO A PLAYER'S DATA (here, or waiting for them)
--------------------------------------------------------------------
local function everything(plr)
	local n = 0
	for _, pc in ipairs(Catalog.PIECES) do Profile.grant(plr, "pieces", pc.id); n += 1 end
	for _, s in ipairs(Catalog.SKINS) do Profile.grant(plr, "skins", s.id); n += 1 end
	for _, w in ipairs(Catalog.WEAPONS) do Profile.grant(plr, "weapons", w.id); n += 1 end
	for _, f in ipairs(Catalog.KILLFX) do Profile.grant(plr, "killfx", f.id); n += 1 end
	for _, e in ipairs(Catalog.EMOTES) do Profile.grant(plr, "emotes", e.id); n += 1 end
	for _, c in ipairs(Catalog.PALETTE) do Profile.grant(plr, "colors", c.name); n += 1 end
	for _, h in ipairs(Catalog.BODY.hairColors or {}) do Profile.grant(plr, "hairColors", h.name); n += 1 end
	for _, b in ipairs(Catalog.BODY.beards or {}) do Profile.grant(plr, "beards", b.id); n += 1 end
	for _, t in ipairs(Catalog.BODY.earnedTitles or {}) do Profile.grant(plr, "titles", t.title); n += 1 end
	for _, c in ipairs(Catalog.COMPANIONS) do if not Profile.has(plr, "companions", c.id) then Profile.grant(plr, "companions", c.id); n += 1 end end
	return n
end

local ITEM_KINDS = {piece = "pieces", skin = "skins", weapon = "weapons", emote = "emotes", killfx = "killfx", companion = "companions", title = "titles", color = "colors"}

-- one change, on a player who is here; returns a line for the toast / log
local function apply(plr, op)
	local p = Profile.get(plr)
	if op.op == "currency" then
		local key = op.kind == "crowns" and "crowns" or "marks"
		p.wallet[key] = math.max(0, (p.wallet[key] or 0) + op.amount)
		Profile.markDirty(plr); Economy.changed:Fire(plr)
		return string.format("%s%d %s", op.amount >= 0 and "+" or "", op.amount, key == "crowns" and "Crowns" or "Marks")
	elseif op.op == "item" then
		if op.take then
			local k = ITEM_KINDS[op.kind]
			if k and p.owned[k] then p.owned[k][op.id] = nil end
			Profile.markDirty(plr); Economy.changed:Fire(plr)
			return "took " .. tostring(op.id)
		end
		if op.kind == "weapon" then Profile.grant(plr, "weapons", op.id); Economy.changed:Fire(plr); return "the weapon " .. op.id end
		local line = Economy.grantReward(plr, {[op.kind] = op.id})
		return line
	elseif op.op == "unlockall" then
		local n = everything(plr)
		Profile.markDirty(plr); Economy.changed:Fire(plr)
		return string.format("unlocked everything (%d things)", n)
	elseif op.op == "level" then
		p.level = math.clamp(math.floor(op.level), 1, 200)
		p.xp = 0
		Profile.markDirty(plr); Economy.changed:Fire(plr)
		return "level " .. p.level
	elseif op.op == "reset" then
		Profile.reset(plr)
		Economy.changed:Fire(plr)
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0 end
		return "saved data wiped"
	end
	return "?"
end

local function applyQueue(plr)
	if not queueStore then return end
	local ops
	pcall(queueStore.UpdateAsync, queueStore, "u" .. plr.UserId, function(old)
		ops = type(old) == "table" and old or nil
		return nil   -- taken: the queue is emptied
	end)
	for _, op in ipairs(ops or {}) do
		local ok, line = pcall(apply, plr, op)
		local ev = ReplicatedStorage:FindFirstChild("HubEvent")
		if ok and ev then ev:FireClient(plr, "Toast", "FROM STAFF  ·  " .. tostring(line)) end
	end
end

-- a change for someone not in this server: it waits for them
local function queue(userId, op)
	if not queueStore then return false end
	local ok = pcall(queueStore.UpdateAsync, queueStore, "u" .. userId, function(old)
		local list = type(old) == "table" and old or {}
		table.insert(list, op)
		return list
	end)
	if ok then publish({kind = "queue", userId = userId}) end
	return ok
end

-- do it now (here) or later (wherever they are)
local function change(userId, op)
	local plr = Players:GetPlayerByUserId(userId)
	if plr then
		local ok, line = pcall(apply, plr, op)
		local ev = ReplicatedStorage:FindFirstChild("HubEvent")
		if ok and ev then ev:FireClient(plr, "Toast", "FROM STAFF  ·  " .. tostring(line)) end
		return ok, ok and line or tostring(line)
	end
	if queue(userId, op) then return true, "they're not here: it'll reach them in their server, or when they next join" end
	return false, "couldn't reach the data store"
end

--------------------------------------------------------------------
--  BANS
--------------------------------------------------------------------
local memBans = {}   -- [userId] = ban (this server; used when the store can't be reached)
local function live(b) return type(b) == "table" and (b["until"] == 0 or b["until"] > os.time()) end
local function banOf(userId)
	if live(memBans[userId]) then return memBans[userId] end
	if not banStore then return nil end
	local ok, b = pcall(banStore.GetAsync, banStore, "u" .. userId)
	if ok and live(b) then return b end
	return nil
end
local function banText(b)
	local when = b["until"] == 0 and "for good" or ("until " .. os.date("!%Y-%m-%d %H:%M UTC", b["until"]))
	return string.format("You're banned %s. Reason: %s", when, b.reason ~= "" and b.reason or "(none given)")
end

local function setBan(userId, name, b)
	memBans[userId] = b
	if b then b.id = userId; b.name = b.name or name end
	if not banStore then return true end
	local ok = pcall(banStore.SetAsync, banStore, "u" .. userId, b)
	pcall(banStore.UpdateAsync, banStore, "index", function(old)
		local list = type(old) == "table" and old or {}
		for i = #list, 1, -1 do if list[i].id == userId then table.remove(list, i) end end
		if b then table.insert(list, 1, {id = userId, name = name, ["until"] = b["until"], reason = b.reason, by = b.byName, at = b.at}) end
		while #list > 200 do table.remove(list) end
		return list
	end)
	return true   -- (the memory copy holds it for this server even if the store failed)
end

--------------------------------------------------------------------
--  ACTIONS
--------------------------------------------------------------------
local function charOf(userId)
	local p = Players:GetPlayerByUserId(userId)
	return p and p.Character, p
end

local NEEDS = {kick = "kick", unban = "ban", ["goto"] = "teleport", bring = "teleport", freeze = "teleport", heal = "health", kill = "health",
	endround = "rounds", nextmode = "rounds", nextmap = "rounds", bots = "bots", clearbots = "bots", currency = "currency", item = "items",
	unlockall = "unlock", level = "progress", reset = "reset", setrole = "staff", shutdown = "shutdown"}
-- actions done to another player: you must outrank them (on yourself it's fine)
local ON_PLAYER = {kick = true, ban = true, ["goto"] = false, bring = true, freeze = true, heal = false, kill = true, currency = true, item = true,
	unlockall = true, level = true, reset = true, setrole = true}

local function act(plr, action, a)
	local role = roleOf(plr.UserId)
	if not role then return false, "you're not staff" end
	a = type(a) == "table" and a or {}
	-- the right
	local need = NEEDS[action]
	if action == "ban" then
		local hours = tonumber(a.hours) or 0
		need = (hours > 0 and hours <= Roles.TEMPBAN_HOURS) and (can(role, "ban") and "ban" or "tempban") or "ban"
	elseif action == "announce" then
		need = a.all and "announce_all" or "announce"
	end
	if not need or not can(role, need) then return false, "your role can't do that" end
	-- the target
	local targetId = tonumber(a.userId)
	if ON_PLAYER[action] ~= nil then
		if not targetId then return false, "pick a player" end
		if targetId ~= plr.UserId or ON_PLAYER[action] then
			if targetId == plr.UserId and (action == "kick" or action == "ban" or action == "setrole") then return false, "not on yourself" end
			if targetId ~= plr.UserId and rankOf(roleOf(targetId)) >= rankOf(role) then return false, "they rank as high as you" end
		end
	end
	local target = targetId and Players:GetPlayerByUserId(targetId)
	local tname = (target and target.Name) or a.name or (targetId and tostring(targetId)) or ""

	if action == "kick" then
		local reason = tostring(a.reason or ""):sub(1, 200)
		if target then target:Kick("Kicked by staff. " .. reason) else publish({kind = "kick", userId = targetId, text = "Kicked by staff. " .. reason}) end
		logAction(plr, "kick", targetId, tname, reason)
		return true, "kicked " .. tname
	elseif action == "ban" then
		if isOwner(targetId) then return false, "the owner can't be banned" end
		local hours = math.max(0, tonumber(a.hours) or 0)
		local b = {["until"] = hours > 0 and (os.time() + math.floor(hours * 3600)) or 0, reason = tostring(a.reason or ""):sub(1, 200), by = plr.UserId, byName = plr.Name, at = os.time(), name = tname}
		if not setBan(targetId, tname, b) then return false, "couldn't save the ban" end
		if target then target:Kick(banText(b)) else publish({kind = "kick", userId = targetId, text = banText(b)}) end
		logAction(plr, "ban", targetId, tname, hours > 0 and (hours .. " h: " .. b.reason) or ("for good: " .. b.reason))
		return true, string.format("banned %s %s", tname, hours > 0 and ("for " .. hours .. " h") or "for good")
	elseif action == "unban" then
		if not targetId then return false, "pick a player" end
		setBan(targetId, tname, nil)
		if banStore then pcall(banStore.RemoveAsync, banStore, "u" .. targetId) end
		logAction(plr, "unban", targetId, tname)
		return true, "unbanned " .. tname
	elseif action == "goto" or action == "bring" or action == "freeze" or action == "heal" or action == "kill" then
		local tc = charOf(targetId)
		local mine = plr.Character
		local thrp = tc and tc:FindFirstChild("HumanoidRootPart")
		if not thrp then return false, "they have no body right now" end
		if action == "goto" then
			if not (mine and mine:FindFirstChild("HumanoidRootPart")) then return false, "spawn first" end
			mine:PivotTo(thrp.CFrame * CFrame.new(0, 0, 4))
		elseif action == "bring" then
			local mhrp = mine and mine:FindFirstChild("HumanoidRootPart")
			if not mhrp then return false, "spawn first" end
			tc:PivotTo(mhrp.CFrame * CFrame.new(0, 0, -4))
		elseif action == "freeze" then
			thrp.Anchored = a.on ~= false
		elseif action == "heal" then
			local hum = tc:FindFirstChildOfClass("Humanoid"); if hum then hum.Health = hum.MaxHealth end
		elseif action == "kill" then
			local hum = tc:FindFirstChildOfClass("Humanoid"); if hum then hum.Health = 0 end
		end
		logAction(plr, action, targetId, tname, action == "freeze" and tostring(a.on ~= false) or nil)
		return true, action .. "  ·  " .. tname
	elseif action == "announce" then
		local text = tostring(a.text or ""):gsub("^%s+", ""):sub(1, 200)
		if text == "" then return false, "say something" end
		if a.all then publish({kind = "announce", text = text, by = plr.Name, role = role}) end
		event:FireAllClients("Announce", text, plr.Name, role)
		logAction(plr, a.all and "announce_all" or "announce", nil, nil, text)
		return true, "announced"
	elseif action == "endround" then
		Game.adminEnd = "THE ROUND WAS ENDED BY STAFF"
		logAction(plr, "endround")
		return true, "ending the round"
	elseif action == "nextmode" then
		if not GameConfig.MODES[a.mode] then return false, "no such mode" end
		Game.node:SetAttribute("NextMode", a.mode)
		logAction(plr, "nextmode", nil, nil, a.mode)
		return true, "next mode: " .. GameConfig.MODES[a.mode].name .. " (end the round to go now)"
	elseif action == "nextmap" then
		local maps = ServerStorage:FindFirstChild("Maps")
		if not (maps and maps:FindFirstChild(tostring(a.map))) then return false, "no such map" end
		Game.adminNextMap = a.map
		logAction(plr, "nextmap", nil, nil, a.map)
		return true, "next map: " .. GameConfig.mapTitle(a.map) .. " (end the round to go now)"
	elseif action == "bots" then
		local Bots = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots"))
		local skill = Bots.SKILLS[a.skill] and a.skill or "Knight"
		local count = math.clamp(math.floor(tonumber(a.count) or 1), 1, 10)
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return false, "spawn first: they come where you stand" end
		local weapons = {"Longsword", "ArmingSword", "Mace", "Spear", "WarAxe", "Halberd"}
		for i = 1, count do
			local ang = (i / count) * math.pi * 2
			Bots.spawn({at = hrp.CFrame * CFrame.new(math.cos(ang) * 12, 0, math.sin(ang) * 12 - 6), skill = skill, weapon = weapons[math.random(#weapons)], name = skill, startDelay = 1.5})
		end
		logAction(plr, "bots", nil, nil, count .. " " .. skill)
		return true, string.format("%d %s%s", count, skill, count > 1 and "s" or "")
	elseif action == "clearbots" then
		local Bots = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots"))
		local n = 0
		for _, b in ipairs(Bots.list()) do if not b.model:GetAttribute("Boss") then b:destroy(); n += 1 end end
		logAction(plr, "clearbots", nil, nil, n)
		return true, n .. " bots cleared"
	elseif action == "currency" then
		local amount = math.floor(tonumber(a.amount) or 0)
		if amount == 0 then return false, "how much?" end
		local ok, msg = change(targetId, {op = "currency", kind = a.kind == "crowns" and "crowns" or "marks", amount = amount})
		logAction(plr, "currency", targetId, tname, string.format("%d %s", amount, a.kind or "marks"))
		return ok, msg
	elseif action == "item" then
		local kind, id = tostring(a.kind or ""), tostring(a.id or "")
		local valid = (kind == "piece" and Catalog.PIECE[id]) or (kind == "skin" and Catalog.SKIN[id]) or (kind == "weapon" and Catalog.WEAPON[id])
			or (kind == "emote" and Catalog.EMOTE[id]) or (kind == "killfx" and Catalog.KILLFX_BY[id]) or (kind == "companion" and Catalog.COMPANION[id])
			or (kind == "egg" and Catalog.EGG[id]) or (kind == "color" and Catalog.COLOR[id]) or (kind == "title" and id ~= "")
		if kind == "crate" then for _, c in ipairs(Catalog.CRATES) do if c.id == id then valid = c end end end
		if not valid then return false, "no such " .. kind end
		if a.take and (kind == "egg" or kind == "crate") then return false, "eggs and crates can't be taken back" end
		local ok, msg = change(targetId, {op = "item", kind = kind, id = id, take = a.take == true})
		logAction(plr, a.take and "take_item" or "give_item", targetId, tname, kind .. " " .. id)
		return ok, msg
	elseif action == "unlockall" then
		local ok, msg = change(targetId, {op = "unlockall"})
		logAction(plr, "unlockall", targetId, tname)
		return ok, msg
	elseif action == "level" then
		local lvl = tonumber(a.level)
		if not lvl then return false, "which level?" end
		local ok, msg = change(targetId, {op = "level", level = lvl})
		logAction(plr, "level", targetId, tname, lvl)
		return ok, msg
	elseif action == "reset" then
		local ok, msg = change(targetId, {op = "reset"})
		logAction(plr, "reset", targetId, tname)
		return ok, msg
	elseif action == "setrole" then
		local newRole = a.role ~= "" and a.role or nil
		if newRole and not Roles.roles[newRole] then return false, "no such role" end
		if newRole and rankOf(newRole) >= rankOf(role) then return false, "you can only give roles below your own" end
		if isOwner(targetId) then return false, "the owner is always the owner" end
		local ok = staffStore ~= nil and pcall(staffStore.UpdateAsync, staffStore, "roles", function(old)
			local t = type(old) == "table" and old or {}
			t[tostring(targetId)] = newRole and {role = newRole, name = tname, by = plr.Name, at = os.time()} or nil
			return t
		end)
		staff[targetId] = newRole and {role = newRole, name = tname, by = plr.Name, at = os.time()} or nil
		local note = ok and "" or "  (this server only: the data store couldn't be reached)"
		if target then markPlayer(target) end
		publish({kind = "staff"})
		logAction(plr, "setrole", targetId, tname, newRole or "none")
		return true, (newRole and (tname .. " is now " .. newRole) or (tname .. " is no longer staff")) .. note
	elseif action == "shutdown" then
		local reason = tostring(a.reason or ""):sub(1, 120)
		logAction(plr, "shutdown", nil, nil, reason)
		for _, p in ipairs(Players:GetPlayers()) do p:Kick("This server was closed by staff. " .. reason) end
		return true, "closing"
	end
	return false, "unknown action"
end

--------------------------------------------------------------------
--  QUERIES
--------------------------------------------------------------------
local function playerRow(p)
	local pr = Profile.get(p)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	return {userId = p.UserId, name = p.Name, display = p.DisplayName, role = roleOf(p.UserId), level = pr.level, marks = pr.wallet.marks,
		crowns = pr.wallet.crowns, team = p.Team and p.Team.Name or "", alive = hum ~= nil and hum.Health > 0,
		frozen = p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.HumanoidRootPart.Anchored or false,
		kills = pr.stats.kill or 0, rounds = pr.stats.round or 0}
end

-- a little burst is fine (opening the panel asks a few things at once): 8 calls, refilled 8 a second
local bucket = {}
remote.OnServerInvoke = function(plr, op, a, b)
	local now = os.clock()
	local bk = bucket[plr] or {n = 8, t = now}
	bk.n = math.min(8, bk.n + (now - bk.t) * 8)
	bk.t = now
	bucket[plr] = bk
	if bk.n < 1 then return {ok = false, msg = "slow down"} end
	bk.n -= 1
	local role = roleOf(plr.UserId)
	if op == "Me" then
		local roles = {}
		for name, r in pairs(Roles.roles) do roles[name] = {rank = r.rank, color = r.color} end
		return {ok = true, role = role, rank = rankOf(role), perms = permsOf(role), roles = roles, order = Roles.order, tempbanHours = Roles.TEMPBAN_HOURS, studio = STUDIO}
	end
	if not (role and can(role, "view")) then return {ok = false, msg = "not staff"} end
	if op == "Players" then
		local rows = {}
		for _, p in ipairs(Players:GetPlayers()) do table.insert(rows, playerRow(p)) end
		return {ok = true, players = rows, mode = Game.node:GetAttribute("Mode"), map = Game.node:GetAttribute("Map")}
	elseif op == "Lookup" then
		local q = tostring(a or "")
		local id = tonumber(q)
		local name = q
		if not id then
			local ok, res = pcall(Players.GetUserIdFromNameAsync, Players, q)
			if not ok then return {ok = false, msg = "no player called " .. q} end
			id = res
		else
			local ok, res = pcall(Players.GetNameFromUserIdAsync, Players, id)
			name = ok and res or q
		end
		local here = Players:GetPlayerByUserId(id)
		return {ok = true, userId = id, name = here and here.Name or name, role = roleOf(id), here = here ~= nil, ban = banOf(id),
			row = here and playerRow(here) or nil}
	elseif op == "Staff" then
		local rows = {}
		for id, s in pairs(staff) do table.insert(rows, {userId = id, name = s.name, role = s.role, by = s.by, at = s.at}) end
		table.insert(rows, {userId = game.CreatorId, name = "(the game's creator)", role = "Owner"})
		table.sort(rows, function(x, y) return rankOf(x.role) > rankOf(y.role) end)
		return {ok = true, staff = rows}
	elseif op == "Bans" then
		if not (can(role, "ban") or can(role, "tempban")) then return {ok = false, msg = "your role can't see bans"} end
		local list, seen = {}, {}
		for id, b in pairs(memBans) do if live(b) then table.insert(list, b); seen[id] = true end end
		if banStore then
			local ok, v = pcall(banStore.GetAsync, banStore, "index")
			if ok and type(v) == "table" then for _, b in ipairs(v) do if live(b) and not seen[b.id] then table.insert(list, b) end end end
		end
		return {ok = true, bans = list}
	elseif op == "Log" then
		if not can(role, "log") then return {ok = false, msg = "your role can't read the log"} end
		local list = memLog
		if logStore then local ok, v = pcall(logStore.GetAsync, logStore, "log"); if ok and type(v) == "table" and #v >= #memLog then list = v end end
		return {ok = true, log = list}
	elseif op == "Act" then
		local ok, res, msg = pcall(act, plr, a, b)
		if not ok then return {ok = false, msg = "error: " .. tostring(res)} end
		return {ok = res, msg = msg}
	end
	return {ok = false, msg = "?"}
end

--------------------------------------------------------------------
--  JOINING: bans, roles, changes waiting
--------------------------------------------------------------------
local function onJoin(plr)
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, r = pcall(plr.GetRankInGroup, plr, game.CreatorId)
		if ok then groupRank[plr.UserId] = r end
	end
	if not isOwner(plr.UserId) then
		local b = banOf(plr.UserId)
		if b then plr:Kick(banText(b)); return end
	end
	markPlayer(plr)
	Profile.get(plr)
	applyQueue(plr)
end
Players.PlayerAdded:Connect(onJoin)
Players.PlayerRemoving:Connect(function(p) groupRank[p.UserId] = nil; bucket[p] = nil end)

task.spawn(function()
	loadStaff()
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(onJoin, p) end
	-- other servers' news
	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(m)
			local d = m.Data
			if type(d) ~= "table" then return end
			if d.kind == "kick" then
				local p = Players:GetPlayerByUserId(d.userId or 0)
				if p then p:Kick(tostring(d.text or "Removed by staff.")) end
			elseif d.kind == "announce" then
				event:FireAllClients("Announce", tostring(d.text or ""), tostring(d.by or ""), tostring(d.role or ""))
			elseif d.kind == "staff" then
				loadStaff()
				for _, p in ipairs(Players:GetPlayers()) do markPlayer(p) end
			elseif d.kind == "queue" then
				local p = Players:GetPlayerByUserId(d.userId or 0)
				if p then applyQueue(p) end
			end
		end)
	end)
	-- roles given elsewhere reach this server in time even without messages
	while true do
		task.wait(120)
		loadStaff()
		for _, p in ipairs(Players:GetPlayers()) do markPlayer(p) end
	end
end)
