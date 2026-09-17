--[[ WALKSPEED GOVERNOR — the ONE place WalkSpeed is set. Everything else
     publishes INPUTS (attributes on the character); this composes them:

        WalkSpeed = BASE_SPEED × healthFactor × swingFactor × speedMult × (future factors…)

     No other script should write Humanoid.WalkSpeed. To add a new modifier
     (sprint, stun, mud, etc.), set an attribute here and multiply it in.

     SpeedMult is the hook for gear: armor, buffs, terrain, etc. set
        character:SetAttribute("SpeedMult", 0.7)   -- 1 = base, no effect
     from a server script when equipped, and clear it (set nil) on unequip.
     Attributes replicate server → client automatically, so the client-side
     camera rig (CameraRig) reads the same authoritative value for free. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))

--------------------------------------------------------------------
local BASE_SPEED   = MovementConfig.BASE_SPEED  -- full-health, no-modifiers walk speed
local MIN_HEALTH_F = 6/16   -- speed factor at near-death (old MIN_SPEED / MAX_SPEED)
--------------------------------------------------------------------

local function govern(char)
	local hum = char:WaitForChild("Humanoid")

	-- input factors, each a 0..1-ish multiplier. Missing attribute = 1 (no effect).
	local function healthFactor()
		local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		return MIN_HEALTH_F + (1 - MIN_HEALTH_F) * frac
	end
	local function swingFactor()
		if char:GetAttribute("Swinging") == true then
			return char:GetAttribute("SwingSlow") or 1
		end
		return 1
	end
	local function speedFactor()
		return char:GetAttribute("SpeedMult") or 1
	end

	-- add future factors here, e.g.:
	-- local function stunFactor() return char:GetAttribute("Stunned") and 0 or 1 end

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not (char.Parent and hum.Parent) then
			conn:Disconnect()
			return
		end
		local wanted = BASE_SPEED * healthFactor() * swingFactor() * speedFactor()
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
