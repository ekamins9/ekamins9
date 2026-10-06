--[[ GAME — the mode runner every other system talks to. Holds the current
     GameMode, publishes its state on ReplicatedStorage.Round (attributes the
     HUD / scoreboard / menus read), and answers the questions the rest of the
     server asks: may this player spawn, where, whose team, who scored.

       Round attributes: State ("Round"|"Intermission"), TimeLeft, Number,
       Mode, ModeName, Category, Map, Teams (0|2), ScoreA, ScoreB, Objective,
       Winner, WinnerKills, NextMode, Vote1..3 / Votes1..3 (map vote)

     A MODE is a table built by Game.Mode.new(def, id) (see Modes/*): override
     any of start / stop / tick / onKill / onDeath / canSpawn / spawnCFrame /
     isOver / objective / result. GameServer drives the loop. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DebugFlags = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local MapLoader  = require(script.Parent:WaitForChild("MapLoader"))
local Teams      = require(script.Parent:WaitForChild("Teams"))

local Game = {}
Game.current = nil       -- mode instance
Game.modeId  = nil
Game.MapLoader, Game.Teams = MapLoader, Teams

local function log(...) DebugFlags.log("Game", ...) end

local node = ReplicatedStorage:FindFirstChild("Round")
if not node then
	node = Instance.new("Configuration")
	node.Name = "Round"
	node.Parent = ReplicatedStorage
end
Game.node = node
for k, v in pairs({State = "Intermission", TimeLeft = 0, Number = 0, Mode = "", ModeName = "", Category = "",
	Map = "", Teams = 0, ScoreA = 0, ScoreB = 0, Objective = "", Winner = "", WinnerKills = 0, NextMode = ""}) do
	if node:GetAttribute(k) == nil then node:SetAttribute(k, v) end
end

--------------------------------------------------------------------
--  SERVER IDENTITY — what this server is, fixed by its first arrival
--------------------------------------------------------------------
-- A public server is the Hub. A reserved server (ReserveServer) reads mode /
-- access / name / allowed ids from the teleport data HubServer gave its first
-- arrival, and keeps them forever. Game.mayJoin enforces the access level.
Game.server = {
	reserved = GameConfig.isReserved(), mode = nil, access = "Public", name = "", custom = false,
	hostId = 0, allowed = nil,   -- allowed: set of user ids (Friends / Locked)
	door = "Courtyard", bracket = nil, ranked = false, sides = nil,   -- sides = {A = {id=true}, B = {…}} (The Lists)
	settings = nil, noRewards = false,                                -- custom server settings (GameConfig.CUSTOM_DEFAULTS)
}
local STUDIO = game:GetService("RunService"):IsStudio()

function Game.identify(plr)
	local sv = Game.server
	if sv.mode then return sv end
	-- a public server needs nobody to know what it is: the Hub (Studio: STUDIO_MODE)
	if not sv.reserved then
		sv.mode = (STUDIO and GameConfig.MODES[GameConfig.STUDIO_MODE]) and GameConfig.STUDIO_MODE or "Hub"
		sv.door = sv.mode == "Hub" and "Courtyard" or (sv.mode == "Tiltyard" and "Tiltyard" or (sv.mode == "Lists" and "Lists" or "Warfront"))
		log("this server:", sv.mode, "(public)")
		return sv
	end
	if not plr then return sv end
	local ok, data = pcall(plr.GetJoinData, plr)
	local td = ok and data and data.TeleportData
	if sv.reserved and type(td) == "table" and GameConfig.MODES[td.mode] and td.mode ~= "Hub" then
		sv.mode = td.mode
		sv.access = GameConfig.ACCESS[td.access] and td.access or "Public"
		sv.name = type(td.name) == "string" and td.name:sub(1, 32) or ""
		sv.custom = td.custom == true
		sv.hostId = tonumber(td.host) or plr.UserId
		if type(td.allowed) == "table" then
			sv.allowed = {}
			for _, id in ipairs(td.allowed) do if type(id) == "number" then sv.allowed[id] = true end end
			sv.allowed[sv.hostId] = true
		end
		sv.door = GameConfig.DOORS[td.door] and td.door or "Warfront"
		sv.bracket = type(td.bracket) == "string" and td.bracket or nil
		sv.ranked = td.ranked == true
		if type(td.sides) == "table" then
			sv.sides = {A = {}, B = {}}
			for _, id in ipairs(td.sides.A or {}) do sv.sides.A[id] = true end
			for _, id in ipairs(td.sides.B or {}) do sv.sides.B[id] = true end
		end
		if type(td.settings) == "table" then
			sv.settings = {}
			for k, v in pairs(GameConfig.CUSTOM_DEFAULTS) do sv.settings[k] = td.settings[k] ~= nil and td.settings[k] or v end
			sv.noRewards = sv.settings.cheats == true
		end
	else
		sv.mode = (STUDIO and GameConfig.MODES[GameConfig.STUDIO_MODE]) and GameConfig.STUDIO_MODE or "Hub"
	end
	log("this server:", sv.mode, sv.access, sv.reserved and "(reserved)" or "(public)", sv.name ~= "" and ("'" .. sv.name .. "'") or "")
	return sv
end

-- may this player be here? (HubServer kicks on false)
function Game.mayJoin(plr)
	local sv = Game.identify(plr)
	local def = GameConfig.MODES[sv.mode]
	local limit = (sv.settings and tonumber(sv.settings.limit)) or (def and def.maxPlayers)
	if limit and #Players:GetPlayers() > limit then return false, "This server is full." end
	if sv.access == "Locked" then
		if sv.allowed and sv.allowed[plr.UserId] then return true end
		return false, "That match is locked."
	elseif sv.access == "Friends" then
		if sv.allowed and sv.allowed[plr.UserId] then return true end
		if plr:GetAttribute("Party") then return true end   -- arrived with a party that is allowed
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= plr then
				local ok, isFriend = pcall(plr.IsFriendsWith, plr, other.UserId)
				if ok and isFriend then return true end
			end
		end
		return false, "That server is friends only."
	end
	return true
end

Players.PlayerAdded:Connect(function(plr) Game.identify(plr) end)
for _, p in ipairs(Players:GetPlayers()) do Game.identify(p) end
Game.identify(nil)   -- a public server identifies itself at once (the map loads before anyone arrives)

-- server-side signals (BindableEvents) other scripts subscribe to
Game.roundStarted        = Instance.new("BindableEvent")   -- (modeId, mapName)
Game.roundEnded          = Instance.new("BindableEvent")   -- (modeId, resultText)
Game.intermissionStarted = Instance.new("BindableEvent")   -- (seconds)

--------------------------------------------------------------------
--  MODE BASE
--------------------------------------------------------------------
local Mode = {}
Mode.__index = Mode
Game.Mode = Mode

function Mode.new(def, id)
	local self = setmetatable({}, Mode)
	self.def, self.id = def, id
	self.scores = {A = 0, B = 0}
	self.roundNumber = 0
	return self
end

-- a round begins on a loaded map
function Mode:start(mapName)
	self.roundNumber += 1
	self.kills = {}
	self.startedAt = os.clock()
	if self.def.teams == 2 then Teams.assignAll() else Teams.clearAll() end
end
function Mode:stop() end
function Mode:tick(dt) end
function Mode:onKill(killerPlr, victimPlr, victimChar)
	if killerPlr then self.kills[killerPlr] = (self.kills[killerPlr] or 0) + 1 end
end
function Mode:onDeath(victimPlr) end
-- may this player (re)spawn right now? false, reason otherwise
function Mode:canSpawn(plr) return true end
-- seconds this player waits for their side's next reinforcement wave
-- (def.waveSpawn): free for the first waveGrace s of a round, then waves on a
-- fixed beat, the two sides half a beat apart
function Mode:waveWait(plr)
	local w = self.def.waveSpawn
	if not w or w <= 0 or not self.startedAt then return 0 end
	local t = os.clock() - self.startedAt
	if t < (self.def.waveGrace or 12) then return 0 end
	local offset = Teams.keyOf(plr) == "B" and w / 2 or 0
	return (w - ((t - offset) % w)) % w
end
-- where; default = the team's spawn farthest from enemies
function Mode:spawnCFrame(plr)
	local team = self.def.teams == 2 and Teams.keyOf(plr) or nil
	local enemies = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local hrp = p ~= plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if hrp and (team == nil or Teams.keyOf(p) ~= team) then table.insert(enemies, hrp.Position) end
	end
	return MapLoader.pickSpawn(team, enemies)
end
-- text | nil: the round ends now with this result
function Mode:isOver() return nil end
-- one line for the top of the screen
function Mode:objective() return "" end
-- result when the clock runs out
function Mode:result()
	local best, bestK = nil, 0
	for p, k in pairs(self.kills or {}) do if k > bestK then best, bestK = p, k end end
	node:SetAttribute("Winner", best and best.DisplayName or "")
	node:SetAttribute("WinnerKills", bestK)
	return best and string.format("%s WINS WITH %d KILLS", string.upper(best.DisplayName), bestK) or "NO KILLS"
end
function Mode:publishScores()
	node:SetAttribute("ScoreA", self.scores.A or 0)
	node:SetAttribute("ScoreB", self.scores.B or 0)
	node:SetAttribute("Objective", self:objective())
end
function Mode:teamResult(key)
	local def = key and GameConfig.TEAMS[key]
	node:SetAttribute("Winner", def and def.name or "")
	node:SetAttribute("WinnerKills", 0)
	return def and string.upper(def.name) .. " WINS" or "DRAW"
end

--------------------------------------------------------------------
--  RUNNER API
--------------------------------------------------------------------
function Game.load(id)
	local def = GameConfig.MODES[id]
	if not def then return nil end
	local mod = script.Parent:FindFirstChild("Modes") and script.Parent.Modes:FindFirstChild(id)
	local impl = mod and require(mod) or nil
	local mode = impl and impl.new(def, id) or Mode.new(def, id)
	Game.current, Game.modeId = mode, id
	node:SetAttribute("Mode", id)
	node:SetAttribute("ModeName", def.name)
	node:SetAttribute("Category", def.category)
	node:SetAttribute("Teams", def.teams or 0)
	-- peaceful: players can't hurt each other (the Courtyard, the training yard)
	node:SetAttribute("Peaceful", def.pvp == false)
	return mode
end

-- STUDIO ONLY: ask this server to switch mode (there are no teleports in
-- Studio). The Hub switches at once; a match switches at the intermission
-- when more than half the server asked. Live, a place never changes mode.
local requests = {}   -- [player] = modeId
function Game.requestMode(plr, id)
	if not GameConfig.MODES[id] then return false, "no such mode" end
	if not game:GetService("RunService"):IsStudio() then return false, "a server never changes mode — travel from the Hub" end
	if id == Game.modeId then return false, "already here" end
	requests[plr] = id
	local counts = {}
	for p, m in pairs(requests) do if p.Parent then counts[m] = (counts[m] or 0) + 1 end end
	local n = #Players:GetPlayers()
	local chosen
	for m, c in pairs(counts) do
		if Game.modeId == "Hub" or c * 2 > n or n <= 2 then chosen = m end
	end
	if chosen then
		node:SetAttribute("NextMode", chosen)
		log("next mode ->", chosen, "(asked by", plr.Name .. ")")
		return true, Game.modeId == "Hub" and "starting" or "at the intermission"
	end
	return true, string.format("vote noted (%d/%d)", counts[id] or 1, math.floor(n / 2) + 1)
end
function Game.clearRequests() requests = {} end
Players.PlayerRemoving:Connect(function(p) requests[p] = nil end)

local spawnedThisRound = {}
function Game.canSpawn(plr)
	if node:GetAttribute("State") ~= "Round" then return false, "Waiting for the next round" end
	if Game.server.settings and Game.server.settings.respawns == false and spawnedThisRound[plr] then return false, "No respawns on this server — wait for the next round" end
	if Game.current then return Game.current:canSpawn(plr) end
	return true
end
function Game.noteSpawn(plr) spawnedThisRound[plr] = true end
function Game.resetSpawns() spawnedThisRound = {} end

function Game.spawnCFrame(plr)
	if Game.current then return Game.current:spawnCFrame(plr) end
	return MapLoader.pickSpawn(nil, {})
end

-- Scoreboard reports every death here; killerPlr may be nil
function Game.onDeath(victimPlr, killerPlr, victimChar)
	if not Game.current then return end
	if killerPlr and killerPlr ~= victimPlr then Game.current:onKill(killerPlr, victimPlr, victimChar) end
	Game.current:onDeath(victimPlr)
	Game.current:publishScores()
end

function Game.waveWait(plr)
	if Game.current and Game.current.waveWait then return Game.current:waveWait(plr) end
	return 0
end

function Game.respawnDelay()
	return Game.current and Game.current.def.respawnDelay or 4
end
-- the round length this server runs (custom settings may override the mode's)
function Game.roundLength(def)
	local s = Game.server.settings
	if s and s.roundLength ~= nil and Game.server.door == "Warfront" then return tonumber(s.roundLength) or def.roundLength or 0 end
	return def.roundLength or 0
end

function Game.teamOf(plr) return Teams.keyOf(plr) end

return Game
