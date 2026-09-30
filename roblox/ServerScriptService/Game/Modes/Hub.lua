-- HUB — the courtyard: free roam, no clock, no teams, spawn anywhere. Ends
-- the moment a mode is requested (GameServer sees NextMode and moves on).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Game = require(script.Parent.Parent:WaitForChild("Game"))

local Hub = setmetatable({}, {__index = Game.Mode})
Hub.__index = Hub
function Hub.new(def, id) return setmetatable(Game.Mode.new(def, id), Hub) end

function Hub:objective() return "COURTYARD  ·  press M for the menu" end
function Hub:isOver()
	local nxt = Game.node:GetAttribute("NextMode")
	if nxt ~= nil and nxt ~= "" and nxt ~= "Hub" then return "TO BATTLE" end
	return nil
end
function Hub:result() return "" end

return Hub
