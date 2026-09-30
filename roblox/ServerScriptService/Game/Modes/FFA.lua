-- FREE-FOR-ALL — most kills when the clock runs out. Everything here is the
-- base behaviour; the module exists so the mode has a home for tweaks.
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local FFA = setmetatable({}, {__index = Game.Mode})
FFA.__index = FFA
function FFA.new(def, id) return setmetatable(Game.Mode.new(def, id), FFA) end
function FFA:objective() return "FREE-FOR-ALL  ·  most kills wins" end
return FFA
