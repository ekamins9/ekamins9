-- KING OF THE HILL — Zones/Hill on the map; while only one team has living
-- players on it, that team gains a point a second. First to pointsToWin.
-- The hill is the Hill part's disc (a Cylinder's round face, or the circle
-- inscribed in a block's footprint); the part itself is hidden — every client draws the hill
-- as a glowing ring on the ground (StarterPlayerScripts ▸ ObjectiveFX) from the
-- Round attributes published here:
--   ObjKind "Hill" · ObjPos · ObjRadius · ObjOwner "A"|"B"|"" ·
--   ObjState "held" | "contested" | "idle" · ObjCountA / ObjCountB
local Players = game:GetService("Players")
local Game  = require(script.Parent.Parent:WaitForChild("Game"))
local Teams, MapLoader = Game.Teams, Game.MapLoader
local node = Game.node

local KOTH = setmetatable({}, {__index = Game.Mode})
KOTH.__index = KOTH
function KOTH.new(def, id) return setmetatable(Game.Mode.new(def, id), KOTH) end

local ATTRS = {"ObjKind", "ObjPos", "ObjRadius", "ObjOwner", "ObjState", "ObjCountA", "ObjCountB"}

-- the hill's disc: a Cylinder part stands on its X axis (diameter = Size.Y/Z),
-- a block on Y (the circle inscribed in its footprint)
local function shapeOf(hill)
	if hill:IsA("Part") and hill.Shape == Enum.PartType.Cylinder then
		return math.min(hill.Size.Y, hill.Size.Z) / 2, hill.Size.X, "X"
	end
	return math.min(hill.Size.X, hill.Size.Z) / 2, hill.Size.Y, "Y"
end

function KOTH:start(map)
	Game.Mode.start(self, map)
	self.scores = {A = 0, B = 0}
	self.acc = 0
	self.owner = nil
	self:publishScores()
	local hill = MapLoader.zone("Hill")
	if hill then
		hill.Transparency = 1   -- the ring on the ground replaces the box
		node:SetAttribute("ObjKind", "Hill")
		local r, h = shapeOf(hill)
		node:SetAttribute("ObjPos", hill.Position - Vector3.new(0, h / 2, 0))
		node:SetAttribute("ObjRadius", r)
		node:SetAttribute("ObjOwner", "")
		node:SetAttribute("ObjState", "idle")
	end
end

function KOTH:stop()
	for _, k in ipairs(ATTRS) do node:SetAttribute(k, nil) end
end

-- living players of each team on the hill (a disc, flat distance; a little height either way)
local function insideHill(hill)
	local a, b = 0, 0
	local r, h, axis = shapeOf(hill)
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local l = hill.CFrame:PointToObjectSpace(hrp.Position)
			local along = axis == "X" and l.X or l.Y
			local across = axis == "X" and Vector2.new(l.Y, l.Z).Magnitude or Vector2.new(l.X, l.Z).Magnitude
			if across <= r and math.abs(along) <= h / 2 + 4 then
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
	self.owner = owner
	node:SetAttribute("ObjCountA", a)
	node:SetAttribute("ObjCountB", b)
	node:SetAttribute("ObjOwner", owner or "")
	node:SetAttribute("ObjState", owner and "held" or ((a > 0 and b > 0) and "contested" or "idle"))
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
