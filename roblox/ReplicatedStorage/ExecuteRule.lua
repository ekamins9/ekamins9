--[[ EXECUTE RULE — who you may execute, shared so the server's check
     (CombatServer, Execute action) and the client's "R  EXECUTE" hint
     (Executions.client) are the same rule. Everything it reads replicates
     (health, attributes, positions).

     A target is executable when it is alive, not a boss, not a teammate, not
     already being executed, not knocked down, close and in front of you, and
     done for: bleeding out, or at LOW_HP or less with no guard up and no swing
     going. In a peaceful place (Round.Peaceful) players can't execute players. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Rule = {}

Rule.CONFIG = {
	RANGE  = 6.5,   -- studs (flat) to the target
	FACING = 0.4,   -- how square in front of you they must be (dot of your look and the way to them)
	LOW_HP = 0.2,   -- ...or at or under this share of their health, guard down, not swinging
	DIST   = 3.4,   -- where they're held, studs in front of you
	AFTER  = 0.25,  -- after the clip ends, before you can act again
}

function Rule.can(attacker, target)
	local C = Rule.CONFIG
	if not (attacker and target and target ~= attacker and target.Parent) then return false end
	local hum = target:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	local me = attacker:FindFirstChildOfClass("Humanoid")
	if not me or me.Health <= 0 then return false end
	if target:GetAttribute("Boss") or target:GetAttribute("BeingExecuted") or target:GetAttribute("Executing") then return false end
	if attacker:GetAttribute("Executing") or attacker:GetAttribute("BeingExecuted") then return false end
	if target:FindFirstChild("RagdollJoints") or attacker:FindFirstChild("RagdollJoints") then return false end
	local round = ReplicatedStorage:FindFirstChild("Round")
	if round and round:GetAttribute("Peaceful") and Players:GetPlayerFromCharacter(attacker) and Players:GetPlayerFromCharacter(target) then
		return false
	end
	local ta = attacker:GetAttribute("Team")
	if ta ~= nil and ta ~= "" and ta == target:GetAttribute("Team") then return false end
	local a, b = attacker:FindFirstChild("HumanoidRootPart"), target:FindFirstChild("HumanoidRootPart")
	if not (a and b) then return false end
	local d = (b.Position - a.Position) * Vector3.new(1, 0, 1)
	if d.Magnitude > C.RANGE or d.Magnitude < 0.1 then return false end
	local look = a.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 or look.Unit:Dot(d.Unit) < C.FACING then return false end
	if target:GetAttribute("Bleeding") == true then return true end
	return hum.Health <= hum.MaxHealth * C.LOW_HP and target:GetAttribute("Blocking") ~= true
		and target:GetAttribute("SpeedMult_Swing") == nil
end

-- the best target in reach (the nearest executable one), or nil
function Rule.best(attacker)
	local best, bestD = nil, math.huge
	local root = attacker and attacker:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local function consider(m)
		if Rule.can(attacker, m) then
			local d = (m.HumanoidRootPart.Position - root.Position).Magnitude
			if d < bestD then best, bestD = m, d end
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character ~= attacker then consider(p.Character) end
	end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then
		for _, m in ipairs(npcs:GetChildren()) do
			if m:IsA("Model") then consider(m) end
		end
	end
	return best
end

return Rule
