--[[ CLINGERS — LOOK UP: a dungeon monster of a kind that climbs (spiders, ghouls, goblins,
     vampires, wraiths) can wait on the ceiling over its spot instead of standing about,
     upside down in the dark, eyes glinting. Dropped, it shrieks, falls (righting itself as it
     comes), lands in a thud and a cloud of grit, and fights as any other. Killed up there (an
     arrow, a spell), it falls.

     The Depths (Modes ▸ Depths) drops a room's clingers when the room wakes, or on whoever walks
     right under one; Deadvault drops each when it notices you, or you walk under it.

       Clingers.BODY[body]          the kinds that climb (a Bestiary look.body)
       Clingers.can(id)             a Bestiary id of a kind that climbs?
       Clingers.cling(mob, map)     up onto the ceiling over where it stands (false: no ceiling
                                    near enough above it)
       Clingers.drop(mob)           down (AdventureEvent "Drop": StarterPlayerScripts ▸ DungeonMood
                                    draws the grit, the cry, the thud)
       Clingers.under(mob, r)       is anyone alive within r studs (across) of being under it? ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))

local Clingers = {}
Clingers.BODY = {spider = true, ghoul = true, goblin = true, vampire = true, wraith = true}
Clingers.FALL = 0.5   -- seconds from the ceiling to the floor

local function rootOf(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end

function Clingers.can(id)
	local def = Catalog.BESTIARY and Catalog.BESTIARY[id]
	return def ~= nil and def.look ~= nil and Clingers.BODY[def.look.body] == true
end

function Clingers.cling(mob, map)
	local m = mob.model
	local r = m and rootOf(m)
	if not (r and map) then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {map}
	local hit = workspace:Raycast(r.Position, Vector3.new(0, 60, 0), params)
	if not hit or hit.Position.Y - r.Position.Y < 8 then return false end
	local sc = m:GetAttribute("MonsterScale") or 1
	local yaw = math.random() * math.pi * 2
	mob.cling = {floorY = r.Position.Y - 3 * sc, yaw = yaw}
	r.Anchored = true
	m:PivotTo(CFrame.new(hit.Position - Vector3.new(0, 3 * sc, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.pi, 0, 0))
	m:SetAttribute("Clinging", true)
	local h = m:FindFirstChildOfClass("Humanoid")
	if h then h.Died:Connect(function() if r.Parent then r.Anchored = false end end) end
	return true
end

function Clingers.drop(mob)
	local c = mob.cling
	if not c then return end
	mob.cling = nil
	local m = mob.model
	local r = m and rootOf(m)
	if not (mob.alive and r and m.Parent) then return end
	m:SetAttribute("Clinging", nil)
	local from = m:GetPivot()
	local sc = m:GetAttribute("MonsterScale") or 1
	local land = CFrame.new(from.Position.X, c.floorY + 3 * sc + 0.2, from.Position.Z) * CFrame.Angles(0, c.yaw, 0)
	local e = event()
	if e then e:FireAllClients("Drop", {at = from.Position, land = land.Position - Vector3.new(0, 3 * sc, 0), body = mob.def and mob.def.look and mob.def.look.body}) end
	task.spawn(function()
		local t0 = os.clock()
		while m.Parent do
			local u = math.min((os.clock() - t0) / Clingers.FALL, 1)
			m:PivotTo(from:Lerp(land, u * u))
			if u >= 1 then break end
			task.wait()
		end
		if r.Parent then r.Anchored = false end
	end)
end

function Clingers.under(mob, radius)
	local mr = mob.cling and mob.alive and mob.model and rootOf(mob.model)
	if not mr then return false end
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local r = rootOf(c)
		if h and h.Health > 0 and r and r.Position.Y < mr.Position.Y
			and Vector3.new(r.Position.X - mr.Position.X, 0, r.Position.Z - mr.Position.Z).Magnitude < radius then
			return true
		end
	end
	return false
end

return Clingers
