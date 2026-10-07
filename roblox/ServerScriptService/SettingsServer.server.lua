--[[ SETTINGS SERVER — saves each player's ClientSettings (camera feel,
     keybinds) in a DataStore so they survive between sessions. Values are
     type-checked against ClientSettings' own rules; nothing here affects
     gameplay on the server, it's storage only.

       ReplicatedStorage.SettingsRemote  (RemoteFunction) client -> "Load"  -> table|nil
       ReplicatedStorage.SettingsEvent   (RemoteEvent)    client -> "Save", table

     In Studio, enable "Allow Studio access to API services" (Game Settings →
     Security) or saving silently no-ops (a warning is printed once). ]]

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))

local STORE_NAME = "PlayerSettings_v1"
local SAVE_MIN_INTERVAL = 6   -- seconds between writes per player (DataStore budget)

local remote = Instance.new("RemoteFunction")
remote.Name = "SettingsRemote"
remote.Parent = ReplicatedStorage
local event = Instance.new("RemoteEvent")
event.Name = "SettingsEvent"
event.Parent = ReplicatedStorage

local store
local warned = false
local function getStore()
	if store then return store end
	local ok, s = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
	if ok then store = s else
		if not warned then warned = true; warn("[Settings] DataStore unavailable:", s) end
	end
	return store
end

-- privacy is the server's business: each choice goes on the player as Priv_<key>
-- (HubServer's party invites and Trading check it)
local function applyPrivacy(plr, t)
	for _, k in ipairs(ClientSettings.PRIVACY or {}) do
		local v = t and t[k]
		plr:SetAttribute("Priv_" .. k, ClientSettings.valid(k, v) and v or ClientSettings.DEFAULTS[k])
	end
end

local cache    = {}   -- [player] = last known good table
local lastSave = {}   -- [player] = os.clock()
local dirty    = {}   -- [player] = table waiting to be written

local function clean(t)
	if type(t) ~= "table" then return nil end
	local out, n = {}, 0
	for k, v in pairs(t) do
		if type(k) == "string" and ClientSettings.valid(k, v) then
			out[k] = v
			n += 1
			if n > 64 then break end
		end
	end
	return out
end

local function write(plr, data)
	local s = getStore()
	if not s then return end
	local ok, err = pcall(s.SetAsync, s, "u" .. plr.UserId, data)
	if not ok and not warned then warned = true; warn("[Settings] save failed:", err) end
end

remote.OnServerInvoke = function(plr, what)
	if what ~= "Load" then return nil end
	if cache[plr] then return cache[plr] end
	local s = getStore()
	if not s then return nil end
	local ok, data = pcall(s.GetAsync, s, "u" .. plr.UserId)
	if ok then
		cache[plr] = clean(data)
		applyPrivacy(plr, cache[plr])
		return cache[plr]
	end
	if not warned then warned = true; warn("[Settings] load failed:", data) end
	return nil
end

event.OnServerEvent:Connect(function(plr, what, data)
	if what ~= "Save" then return end
	local t = clean(data)
	if not t then return end
	cache[plr] = t
	applyPrivacy(plr, t)
	local now = os.clock()
	if now - (lastSave[plr] or -1e9) >= SAVE_MIN_INTERVAL then
		lastSave[plr] = now
		task.spawn(write, plr, t)
	else
		-- coalesce a burst of slider drags into one write
		if not dirty[plr] then
			dirty[plr] = true
			task.delay(SAVE_MIN_INTERVAL, function()
				dirty[plr] = nil
				if plr.Parent and cache[plr] then
					lastSave[plr] = os.clock()
					write(plr, cache[plr])
				end
			end)
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	if cache[plr] and dirty[plr] then write(plr, cache[plr]) end
	cache[plr], lastSave[plr], dirty[plr] = nil, nil, nil
end)
