--[[ WEATHER — rain, storms, snow, embers and petals on the maps that have them (GameConfig ▸
     MAP_WEATHER, a mode's own MODE_WEATHER first), drawn round your camera by ReplicatedStorage ▸
     WarFX (none in your face under a roof). Changes with the map; War and the Prologue draw their
     own, the Hub and the dungeon game have none. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local round = ReplicatedStorage:WaitForChild("Round")

local OWN = {War = true, Prologue = true, Hub = true, Tavern = true, Deadvault = true, Depths = true}
local current = nil

local function want()
	local mode = round:GetAttribute("Mode") or ""
	if OWN[mode] then return false end
	return GameConfig.MODE_WEATHER[mode] or GameConfig.MAP_WEATHER[round:GetAttribute("Map") or ""]
end

local function apply()
	local w = want()
	if w == false then
		-- (a mode with its own weather: leave it be, only let go of ours)
		-- (only if what's up is still ours: the Prologue may have set its storm already)
		if current and WarFX.weatherKind() == current then WarFX.weather(nil, 2) end
		current = nil
		return
	end
	-- (still up? leaving War, say, clears all of WarFX's weather)
	if w == current and WarFX.weatherKind() == w then return end
	current = w
	WarFX.weather(w, 2)
end
round:GetAttributeChangedSignal("Map"):Connect(apply)
round:GetAttributeChangedSignal("Mode"):Connect(apply)
apply()
