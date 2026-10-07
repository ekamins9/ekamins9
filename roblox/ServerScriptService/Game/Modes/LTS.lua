-- LAST TEAM STANDING — nobody respawns; wipe the other side to take the
-- round. Rounds are counted across the framework's rounds (the mode instance
-- lives as long as the mode is selected); first to `roundsToWin`.
local Players = game:GetService("Players")
local Game  = require(script.Parent.Parent:WaitForChild("Game"))
local Teams = Game.Teams

local LTS = setmetatable({}, {__index = Game.Mode})
LTS.__index = LTS
function LTS.new(def, id)
	local self = setmetatable(Game.Mode.new(def, id), LTS)
	self.roundWins = {A = 0, B = 0}
	return self
end

function LTS:start(map)
	Game.Mode.start(self, map)
	self.startedAt = os.clock()
	self.spawnedOnce = {}
	self.scores = {A = self.roundWins.A, B = self.roundWins.B}
	self:publishScores()
end
-- one life per round: you may spawn only until the first GRACE seconds are up
function LTS:canSpawn(plr)
	if self.spawnedOnce and self.spawnedOnce[plr] then return false, "No respawns — wait for the next round" end
	if self.startedAt and os.clock() - self.startedAt > 20 then return false, "The round is under way — wait for the next one" end
	return true
end
function LTS:noteSpawn(plr) if self.spawnedOnce then self.spawnedOnce[plr] = true end end
function LTS:objective() return string.format("LAST TEAM STANDING  ·  first to %d rounds", self.def.roundsToWin or 4) end
function LTS:isOver()
	if not self.startedAt or os.clock() - self.startedAt < 8 then return nil end
	-- (fill bots fight and fall like anyone: Game ▸ BotFill)
	local a, b = Teams.aliveCount("A") + Teams.botsAlive("A"), Teams.aliveCount("B") + Teams.botsAlive("B")
	local hasA = Teams.count("A") > 0 or (Game.fielded.A or 0) > 0
	local hasB = Teams.count("B") > 0 or (Game.fielded.B or 0) > 0
	if not (hasA and hasB) then return nil end
	local winner
	if a == 0 and b > 0 then winner = "B" elseif b == 0 and a > 0 then winner = "A" elseif a == 0 and b == 0 then winner = false end
	if winner == nil then return nil end
	if winner then
		self.roundWins[winner] += 1
		self.scores[winner] = self.roundWins[winner]
		self:publishScores()
		if self.roundWins[winner] >= (self.def.roundsToWin or 4) then
			local text = self:teamResult(winner) .. " THE MATCH"
			self.roundWins = {A = 0, B = 0}
			return text
		end
		return self:teamResult(winner) .. " THE ROUND"
	end
	return "DRAW"
end
function LTS:result()
	local a, b = Teams.aliveCount("A") + Teams.botsAlive("A"), Teams.aliveCount("B") + Teams.botsAlive("B")
	if a == b then return self:teamResult(nil) end
	local winner = a > b and "A" or "B"
	self.roundWins[winner] += 1
	return self:teamResult(winner) .. " THE ROUND"
end
return LTS
