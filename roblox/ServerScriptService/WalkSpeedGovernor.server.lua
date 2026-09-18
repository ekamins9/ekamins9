--[[ WALKSPEED GOVERNOR — the ONE place WalkSpeed is set. Everything else
     publishes INPUTS (attributes on the character); this composes them:

        WalkSpeed = BASE_SPEED × healthFactor × Π(SpeedMult_*)

     No other script should write Humanoid.WalkSpeed. To slow or speed a
     player from any system, publish a SpeedMult_<Source> attribute on the
     character and clear it when done (see ReplicatedStorage.Modifiers):
        character:SetAttribute("SpeedMult_Armor", 0.7)   -- 1 = no effect
     Weapons publish SpeedMult_Weapon while equipped and SpeedMult_Swing
     while attacking; armor will publish SpeedMult_Armor. They all stack. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local Modifiers      = require(ReplicatedStorage:WaitForChild("Modifiers"))
require(ReplicatedStorage:WaitForChild("DebugFlags"))  -- creates ReplicatedStorage.Debug at startup so clients never wait on it

--------------------------------------------------------------------
local BASE_SPEED   = MovementConfig.BASE_SPEED  -- full-health, no-modifiers walk speed
local MIN_HEALTH_F = 6/16   -- speed factor at near-death (old MIN_SPEED / MAX_SPEED)
--------------------------------------------------------------------

local function govern(char)
	local hum = char:WaitForChild("Humanoid")

	local function healthFactor()
		local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		return MIN_HEALTH_F + (1 - MIN_HEALTH_F) * frac
	end

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not (char.Parent and hum.Parent) then
			conn:Disconnect()
			return
		end
		local wanted = BASE_SPEED * healthFactor() * Modifiers.product(char, "SpeedMult")
		if math.abs(hum.WalkSpeed - wanted) > 0.01 then
			hum.WalkSpeed = wanted
		end
	end)
end

local function onPlayer(p)
	p.CharacterAdded:Connect(govern)
	if p.Character then govern(p.Character) end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
