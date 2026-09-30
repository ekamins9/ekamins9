--[[ PROFILE — one saved record per player (DataStore "Profiles_v1"):
       classes = { [classId] = {armor = setId, weapon = toolName, secondary = toolName|nil} }
       active  = classId              the class the spawn screen preselects
       stats   = {kills, deaths, wins, parries, chambers}   (Scoreboard adds)
     Loaded on join, saved on leave and every AUTOSAVE seconds while dirty.
     Without DataStore access (Studio with API access off) it lives for the
     session and warns once. ]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Profile = {}
local STORE = "Profiles_v1"
local AUTOSAVE = 60

local store
local warned = false
local function getStore()
	if store then return store end
	local ok, s = pcall(DataStoreService.GetDataStore, DataStoreService, STORE)
	if ok then store = s elseif not warned then warned = true; warn("[Profile] DataStore unavailable:", s) end
	return store
end

local cache, dirty = {}, {}   -- [player] = table / true

local function default()
	return {version = 1, classes = {}, active = GameConfig.DEFAULT_CLASS,
		stats = {kills = 0, deaths = 0, wins = 0, parries = 0, chambers = 0}}
end

local function load(plr)
	local data
	local s = getStore()
	if s then
		local ok, v = pcall(s.GetAsync, s, "u" .. plr.UserId)
		if ok and type(v) == "table" then data = v elseif not ok and not warned then warned = true; warn("[Profile] load failed:", v) end
	end
	data = data or default()
	data.classes = type(data.classes) == "table" and data.classes or {}
	data.stats = type(data.stats) == "table" and data.stats or default().stats
	if not GameConfig.CLASSES[data.active] then data.active = GameConfig.DEFAULT_CLASS end
	cache[plr] = data
	return data
end

function Profile.get(plr)
	return cache[plr] or load(plr)
end

function Profile.markDirty(plr) dirty[plr] = true end

local function save(plr)
	local data = cache[plr]
	local s = getStore()
	if not (data and s) then return end
	local ok, err = pcall(s.SetAsync, s, "u" .. plr.UserId, data)
	if not ok and not warned then warned = true; warn("[Profile] save failed:", err) end
	dirty[plr] = nil
end
Profile.save = save

function Profile.setClass(plr, classId, loadout)
	local p = Profile.get(plr)
	p.classes[classId] = loadout
	dirty[plr] = true
end
function Profile.setActive(plr, classId)
	if not GameConfig.CLASSES[classId] then return end
	Profile.get(plr).active = classId
	dirty[plr] = true
end
function Profile.addStat(plr, key, n)
	local p = cache[plr]
	if not p then return end
	p.stats[key] = (p.stats[key] or 0) + (n or 1)
	dirty[plr] = true
end

Players.PlayerAdded:Connect(function(plr) task.spawn(load, plr) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(load, p) end
Players.PlayerRemoving:Connect(function(plr)
	if dirty[plr] then save(plr) end
	cache[plr], dirty[plr] = nil, nil
end)
task.spawn(function()
	while true do
		task.wait(AUTOSAVE)
		for plr in pairs(dirty) do if plr.Parent then task.spawn(save, plr) end end
	end
end)
game:BindToClose(function()
	for plr in pairs(dirty) do save(plr) end
end)

return Profile
