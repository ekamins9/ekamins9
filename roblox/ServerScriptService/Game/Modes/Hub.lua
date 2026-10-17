-- HUB — the courtyard: free roam, no clock, no teams, spawn anywhere. Live it
-- never ends; in Studio it ends the moment a mode is requested (GameServer
-- sees NextMode and moves on).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Game = require(script.Parent.Parent:WaitForChild("Game"))

local HubBackdrop = require(script.Parent.Parent:WaitForChild("HubBackdrop"))

local Hub = setmetatable({}, {__index = Game.Mode})
Hub.__index = Hub
function Hub.new(def, id) return setmetatable(Game.Mode.new(def, id), Hub) end

-- the world round the walls (Game ▸ HubBackdrop): hills, a village, woods, a war camp far off
function Hub:start(map)
	Game.Mode.start(self, map)
	local ok, err = pcall(HubBackdrop.build, Game.MapLoader.current)
	if not ok then warn("[Hub] backdrop:", err) end
end
function Hub:stop() HubBackdrop.clear() end

function Hub:objective() return "HUB  ·  press M for the menu" end
function Hub:isOver()
	local nxt = Game.node:GetAttribute("NextMode")
	if nxt ~= nil and nxt ~= "" and nxt ~= "Hub" then return "TO BATTLE" end
	return nil
end
function Hub:result() return "" end

return Hub
