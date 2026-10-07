-- TILTYARD — the training yard: your own yard to learn in (Game ▸ Training
-- runs it: the Drill Master's lessons, straw dummies, the sparring ring).
-- Peaceful between players. Never ends on its own; RETURN TO COURTYARD leaves.
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Hub = require(script.Parent:WaitForChild("Hub"))
local Training = require(script.Parent.Parent:WaitForChild("Training"))
local Tiltyard = setmetatable({}, {__index = Hub})
Tiltyard.__index = Tiltyard
function Tiltyard.new(def, id) return setmetatable(Hub.new(def, id), Tiltyard) end
function Tiltyard:start(map)
	Hub.start(self, map)
	Training.start(Game.MapLoader.current)
end
function Tiltyard:stop()
	Training.stop()
	Hub.stop(self)
end
function Tiltyard:objective() return "TRAINING YARD  ·  E at the Drill Master for lessons  ·  E at the ring sign to spar" end
-- (Studio has no teleports: it ends the moment another mode is asked for, like the Hub)
function Tiltyard:isOver()
	local nxt = Game.node:GetAttribute("NextMode")
	if nxt ~= nil and nxt ~= "" and nxt ~= "Tiltyard" then return "TO BATTLE" end
	return nil
end
return Tiltyard
