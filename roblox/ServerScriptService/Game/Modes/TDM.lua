-- TEAM DEATHMATCH — each side starts with `tickets`; a death costs the dead
-- player's team one. First to zero loses; on the clock, more tickets wins.
local Game  = require(script.Parent.Parent:WaitForChild("Game"))
local Teams = Game.Teams

local TDM = setmetatable({}, {__index = Game.Mode})
TDM.__index = TDM
function TDM.new(def, id) return setmetatable(Game.Mode.new(def, id), TDM) end

function TDM:start(map)
	Game.Mode.start(self, map)
	self.scores = {A = self.def.tickets or 60, B = self.def.tickets or 60}
	self:publishScores()
end
function TDM:onDeath(victimPlr)
	local t = Teams.keyOf(victimPlr)
	if t and self.scores[t] > 0 then self.scores[t] -= 1 end
end
function TDM:onBotDeath(team)
	if team and (self.scores[team] or 0) > 0 then self.scores[team] -= 1 end
end
function TDM:objective() return "TEAM DEATHMATCH  ·  tickets" end
function TDM:isOver()
	if self.scores.A <= 0 then return self:teamResult("B") end
	if self.scores.B <= 0 then return self:teamResult("A") end
	return nil
end
function TDM:result()
	if self.scores.A == self.scores.B then return self:teamResult(nil) end
	return self:teamResult(self.scores.A > self.scores.B and "A" or "B")
end
return TDM
