-- KING OF THE HILL — Zones/Hill on the map; while only one team has living
-- players inside it, that team gains a point a second. First to pointsToWin.
local Players = game:GetService("Players")
local Game  = require(script.Parent.Parent:WaitForChild("Game"))
local Teams, MapLoader = Game.Teams, Game.MapLoader

local KOTH = setmetatable({}, {__index = Game.Mode})
KOTH.__index = KOTH
function KOTH.new(def, id) return setmetatable(Game.Mode.new(def, id), KOTH) end

function KOTH:start(map)
	Game.Mode.start(self, map)
	self.scores = {A = 0, B = 0}
	self.acc = 0
	self.owner = nil
	self:publishScores()
end

local params = OverlapParams.new()
local function insideHill(hill)
	local a, b = 0, 0
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local l = hill.CFrame:PointToObjectSpace(hrp.Position)
			local h = hill.Size * 0.5
			if math.abs(l.X) <= h.X and math.abs(l.Y) <= h.Y + 2 and math.abs(l.Z) <= h.Z then
				local t = Teams.keyOf(p)
				if t == "A" then a += 1 elseif t == "B" then b += 1 end
			end
		end
	end
	return a, b
end

function KOTH:tick(dt)
	local hill = MapLoader.zone("Hill")
	if not hill then return end
	local a, b = insideHill(hill)
	local owner = (a > 0 and b == 0) and "A" or ((b > 0 and a == 0) and "B" or nil)
	if owner ~= self.owner then
		self.owner = owner
		hill.Color = owner and Teams.def(owner).rgb or Color3.fromRGB(200, 200, 200)
		hill.Transparency = 0.7
	end
	if owner then
		self.acc += dt
		while self.acc >= 1 do
			self.acc -= 1
			self.scores[owner] += 1
		end
		self:publishScores()
	end
end
function KOTH:objective()
	local who = self.owner and (Teams.def(self.owner).name .. " hold the hill") or "the hill is open"
	return string.format("KING OF THE HILL  ·  %s  ·  first to %d", who, self.def.pointsToWin or 200)
end
function KOTH:isOver()
	local goal = self.def.pointsToWin or 200
	if self.scores.A >= goal then return self:teamResult("A") end
	if self.scores.B >= goal then return self:teamResult("B") end
	return nil
end
function KOTH:result()
	if self.scores.A == self.scores.B then return self:teamResult(nil) end
	return self:teamResult(self.scores.A > self.scores.B and "A" or "B")
end
return KOTH
