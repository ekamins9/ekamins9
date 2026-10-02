-- THE LISTS — arena brackets. Two sides from the teleport data (Game.server
-- sides), best of 5 rounds (roundsToWin 3), no respawns, 90 s rounds. Honor
-- rules: a hit on someone already engaged by your teammate is a warning the
-- first time and loses the round the second (CombatServer reports through
-- _G.HonorHook). Ranked results are written by Scoreboard (ratings + boards).
local Players = game:GetService("Players")
local Game  = require(script.Parent.Parent:WaitForChild("Game"))
local Teams = Game.Teams
local LTS = require(script.Parent:WaitForChild("LTS"))

local Lists = setmetatable({}, {__index = LTS})
Lists.__index = Lists
function Lists.new(def, id)
	local self = setmetatable(LTS.new(def, id), Lists)
	self.honor = {}   -- [plr] = warnings
	return self
end

function Lists:start(map)
	Game.Mode.start(self, map)
	-- sides come from the matchmaker, never balanced by count
	local sides = Game.server.sides
	if sides then
		for _, p in ipairs(Players:GetPlayers()) do
			local key = (sides.A and sides.A[p.UserId]) and "A" or ((sides.B and sides.B[p.UserId]) and "B" or nil)
			Teams.set(p, key or Teams.assign(p))
		end
	else
		Teams.assignAll()
	end
	self.startedAt = os.clock()
	self.spawnedOnce = {}
	self.scores = {A = self.roundWins.A, B = self.roundWins.B}
	self:publishScores()
end
function Lists:objective()
	return string.format("THE LISTS  ·  %s%s  ·  first to %d", Game.server.bracket or "duel", Game.server.ranked and "  ·  RANKED" or "", self.def.roundsToWin or 3)
end
-- a side with nobody left (a leaver) forfeits
function Lists:isOver()
	local before = self.roundWins
	local text = LTS.isOver(self)
	if text and self.roundWins ~= before then self.matchDone = true end   -- LTS swaps in a fresh table when the match is won
	if text then return text end
	if self.startedAt and os.clock() - self.startedAt > 5 then
		if Teams.count("A") == 0 and Teams.count("B") > 0 then self.matchDone = true; return self:teamResult("B") .. " BY FORFEIT" end
		if Teams.count("B") == 0 and Teams.count("A") > 0 then self.matchDone = true; return self:teamResult("A") .. " BY FORFEIT" end
	end
	return nil
end
-- the clock ran out: the round goes to the side with more alive; that may end the match too
function Lists:result()
	local text = LTS.result(self)
	local need = self.def.roundsToWin or 3
	if self.roundWins.A >= need or self.roundWins.B >= need then
		self.matchDone = true
		text = text:gsub("THE ROUND", "THE MATCH")
	end
	return text
end
-- after the match the server is done: everyone is sent home by HubServer (MatchOver attribute)
function Lists:stop()
	if self.matchDone then Game.node:SetAttribute("MatchOver", true) end
end
return Lists
