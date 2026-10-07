--[[ CHARACTER SYSTEMS — per-character server wiring that isn't tied to a
     weapon: ragdoll on death, bleed-out ticking, death sound, STAMINA REGEN
     (it used to live in the weapon script, so a disarmed player never
     regenerated), dropping your weapons when you die, and no jumping.
     Covers every player character plus any humanoid Model placed in a
     workspace.NPCs folder. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local Ragdoll     = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Ragdoll"))
local Injury      = require(ServerScriptService.Combat:WaitForChild("Injury"))
local Pickup      = require(ServerScriptService.Combat:WaitForChild("Pickup"))
local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local Sounds      = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local DebugFlags  = require(ReplicatedStorage:WaitForChild("DebugFlags"))

local DEATH_SHOVE = 10   -- studs/s the corpse falls away from the last hit
-- stamina (the BlockMeter attribute) — a weapon overrides these through the
-- BlockMax / StaminaRegen / StaminaRegenDelay attributes it publishes on equip
local STAMINA_MAX   = 100
local STAMINA_REGEN = 17    -- per second…
local STAMINA_DELAY = 1.3   -- …at full rate this long after the last combat event
local COMBAT_REGEN  = 0.35  -- …and this share of it before that (weapons publish CombatRegenMult)
local HOLD_DRAIN    = 3     -- stamina per second while the guard is held (weapon overrides via BlockHoldDrain)
-- health regen: slow, and only when you are truly out of the fight — full stamina,
-- not blocking / attacking / sprinting, nothing happened for HEALTH_DELAY
local HEALTH_REGEN  = 2.5   -- health per second
local HEALTH_DELAY  = 5.0   -- seconds after the last combat event
local DROWN_TIME    = 1.2   -- seconds under a map's DrownY before you're gone

local function setup(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	hum.BreakJointsOnDeath = false   -- Ragdoll needs the joints intact
	hum.RequiresNeck = false         -- disabling the Neck motor for a ragdoll must not count as death
	-- the short hop (the client keeps Roblox's own jump switched off between hops)
	hum.UseJumpPower = true
	hum.JumpPower = MovementConfig.JUMP_POWER or 0
	if char:GetAttribute("BlockMeter") == nil then char:SetAttribute("BlockMeter", STAMINA_MAX) end
	if char:GetAttribute("BlockMax")   == nil then char:SetAttribute("BlockMax",   STAMINA_MAX) end
	DebugFlags.log("CharacterSystems", "setup", char.Name)

	hum.Died:Once(function()
		DebugFlags.log("CharacterSystems", char.Name, "died -> ragdoll")
		local dir = char:GetAttribute("HitDir")
		Pickup.dropAll(char)   -- weapons hit the floor next to the body, for anyone to take
		Ragdoll.enable(char, typeof(dir) == "Vector3" and dir or nil, DEATH_SHOVE)
		Sounds.play(SoundConfig.Death, char:FindFirstChild("Head") or char:FindFirstChild("Torso"))
		-- a last cry (not from a body that has lost its head), then the body hits the ground
		if char:GetAttribute("LimbLost_Head") ~= true then
			Sounds.voice("Death", char:FindFirstChild("Head") or char:FindFirstChild("Torso"), {Who = char})
		end
		task.delay(0.55, function()
			local torso = char.Parent and char:FindFirstChild("Torso")
			if torso then Sounds.bank(char:GetAttribute("ArmorType") == "Heavy" and "BodyFallArmor" or "BodyFall", torso) end
		end)
	end)

	local drowning = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not (char.Parent and hum.Parent) then
			conn:Disconnect()
			return
		end
		Injury.tick(char, dt)
		-- a map with water to fall into (attribute DrownY: Highbridge's river) takes
		-- whoever is under that height for a moment; a knock-off still credits the
		-- last one to hit them (LastHitBy)
		local map = workspace:FindFirstChild("Map")
		local drownY = map and map:GetAttribute("DrownY")
		local root = char:FindFirstChild("HumanoidRootPart")
		if drownY and root and hum.Health > 0 and root.Position.Y < drownY then
			drowning += dt
			if drowning > DROWN_TIME then hum.Health = 0 end
		else
			drowning = 0
		end
		-- holding the guard costs stamina (a timed parry is free): the turtle tax
		if hum.Health > 0 and char:GetAttribute("Blocking") then
			local drain = char:GetAttribute("BlockHoldDrain") or HOLD_DRAIN
			if drain > 0 then
				local m = char:GetAttribute("BlockMeter") or (char:GetAttribute("BlockMax") or STAMINA_MAX)
				if m > 0 then char:SetAttribute("BlockMeter", math.max(0, m - drain * dt)) end
			end
		end
		-- health regen: full stamina, idle, out of combat for HEALTH_DELAY
		if hum.Health > 0 and hum.Health < hum.MaxHealth
			and not char:GetAttribute("Blocking") and not char:GetAttribute("Acting")
			and char:GetAttribute("SpeedMult_Sprint") == nil
			and (char:GetAttribute("BlockMeter") or 0) >= (char:GetAttribute("BlockMax") or STAMINA_MAX) - 0.01
			and os.clock() - (char:GetAttribute("LastCombatAt") or -1e9) >= HEALTH_DELAY then
			hum.Health = math.min(hum.MaxHealth, hum.Health + HEALTH_REGEN * dt)
		end
		-- stamina regen: not while blocking, mid-action, stunned or dead; within
		-- the delay of a combat event (attack, dodge, hit taken…) only a trickle
		-- (CombatRegenMult), so a long fight you're winning doesn't run you dry
		if hum.Health > 0
			and not char:GetAttribute("Blocking") and not char:GetAttribute("Acting")
			and (char:GetAttribute("StunnedUntil") or 0) <= os.clock() then
			local calm = os.clock() - (char:GetAttribute("LastCombatAt") or -1e9) >= (char:GetAttribute("StaminaRegenDelay") or STAMINA_DELAY)
			local rate = (char:GetAttribute("StaminaRegen") or STAMINA_REGEN) * (calm and 1 or (char:GetAttribute("CombatRegenMult") or COMBAT_REGEN))
			local max = char:GetAttribute("BlockMax") or STAMINA_MAX
			local m = char:GetAttribute("BlockMeter") or max
			if m < max and rate > 0 then
				char:SetAttribute("BlockMeter", math.min(max, m + rate * dt))
			end
		end
	end)
end

local function onPlayer(p)
	p.CharacterAdded:Connect(setup)
	if p.Character then setup(p.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end

-- Own the NPCs folder rather than only hooking it when it already exists:
-- TestDummies also creates it, and whichever script loads second used to lose
-- the ChildAdded connection entirely — leaving dummies with no Died handler
-- (no ragdoll) and no BreakJointsOnDeath/RequiresNeck setup.
local npcs = workspace:FindFirstChild("NPCs")
if not npcs then
	npcs = Instance.new("Folder")
	npcs.Name = "NPCs"
	npcs.Parent = workspace
end
for _, m in ipairs(npcs:GetChildren()) do
	if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then setup(m) end
end
npcs.ChildAdded:Connect(function(m)
	if m:IsA("Model") then task.defer(setup, m) end
end)
