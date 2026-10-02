-- TILTYARD — your own training yard: free roam like the Hub, dummies via the
-- drill board (/spawn commands from TestDummies work too). Never ends on its
-- own; RETURN TO COURTYARD leaves it.
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Hub = require(script.Parent:WaitForChild("Hub"))
local Tiltyard = setmetatable({}, {__index = Hub})
Tiltyard.__index = Tiltyard
function Tiltyard.new(def, id) return setmetatable(Hub.new(def, id), Tiltyard) end
function Tiltyard:objective() return "TILTYARD  ·  drills pay Marks once each  ·  M for the menu" end
function Tiltyard:isOver() return nil end
return Tiltyard
