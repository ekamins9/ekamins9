-- DUEL YARD — FFA rules on a small map, honour expected. Same scoring; a
-- longer respawn keeps fights one-on-one.
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Duel = setmetatable({}, {__index = Game.Mode})
Duel.__index = Duel
function Duel.new(def, id) return setmetatable(Game.Mode.new(def, id), Duel) end
function Duel:objective() return "DUEL YARD  ·  one on one, stay out of other fights" end
return Duel
