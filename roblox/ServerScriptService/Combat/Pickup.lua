--[[ PICKUP — weapons on the floor. A Tool that leaves a hand (disarm,
     death, or a swap) is dropped here: thrown clear, made solid, given a
     ProximityPrompt, and despawned after DESPAWN seconds. Anyone alive can
     pick it up.

     Slots: one PRIMARY plus one SECONDARY (a weapon whose Config has
     SECONDARY = true), MAX_WEAPONS in total. Picking up past a full slot
     drops what was in it right there, so you can always swap by walking
     over something better.

     Dropped tools keep their Server script running (workspace is a valid
     run context) so the CombatServer controller survives the trip; their
     LocalScript restarts on the way back into a Backpack. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugFlags  = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Sounds      = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local Janitor     = require(script.Parent:WaitForChild("Janitor"))

local Pickup = {}

Pickup.CONFIG = {
	MAX_WEAPONS  = 2,     -- primary + secondary
	DESPAWN      = 25,    -- seconds a dropped weapon lies around (Janitor: at most 8 at once, oldest first)
	PROMPT_RANGE = 7,     -- studs
	PROMPT_HOLD  = 0.3,   -- seconds the key is held
	DROP_SPEED   = 6,     -- gentle toss on death / swap (a disarm passes its own)
}
local C = Pickup.CONFIG

local function log(...) DebugFlags.log("Pickup", ...) end

local function folder()
	local f = workspace:FindFirstChild("DroppedWeapons")
	if not f then
		f = Instance.new("Folder")
		f.Name = "DroppedWeapons"
		f.Parent = workspace
	end
	return f
end

function Pickup.config(tool)
	local mod = tool:FindFirstChild("Config")
	if not (mod and mod:IsA("ModuleScript")) then return {} end
	local ok, t = pcall(require, mod)
	return (ok and type(t) == "table") and t or {}
end

function Pickup.isSecondary(tool)
	return Pickup.config(tool).SECONDARY == true
end

function Pickup.isDropped(tool)
	return tool:GetAttribute("Dropped") == true
end

-- every Tool a character owns (in hand + backpack)
function Pickup.owned(plr, char)
	local out = {}
	if char then
		for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(out, t) end end
	end
	local bp = plr and plr:FindFirstChild("Backpack")
	if bp then
		for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(out, t) end end
	end
	return out
end

--------------------------------------------------------------------
--  DROP
--------------------------------------------------------------------
local function handleOf(tool)
	return tool:FindFirstChild("Handle") or tool.PrimaryPart or tool:FindFirstChildWhichIsA("BasePart", true)
end

-- tool: the Tool; char: who had it (may be nil); dir/speed: fling (optional)
function Pickup.drop(tool, char, dir, speed)
	if not tool or not tool:IsA("Tool") or Pickup.isDropped(tool) then return false end
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local handle = handleOf(tool)

	if char then
		char:SetAttribute("Blocking", false)
		if hum and tool.Parent == char then hum:UnequipTools() end
		-- Sever every joint still tying the weapon to the body BEFORE moving it.
		-- Tool.Unequipped fires deferred, so the ToolGrip Motor6D is still live
		-- here — and while it is, the weapon shares the body's assembly, so
		-- throwing the handle would throw the whole body with it.
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("JointInstance")
				and ((d.Part0 and d.Part0:IsDescendantOf(tool)) or (d.Part1 and d.Part1:IsDescendantOf(tool))) then
				d:Destroy()
			end
		end
	end

	tool:SetAttribute("Dropped", true)
	tool.Parent = folder()

	-- solid on the floor (every part, or the blade pivots on the grip and
	-- sinks through). No Touched pickup: the prompt is the only way back.
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") then
			if d:GetAttribute("PU_Collide") == nil then
				d:SetAttribute("PU_Collide", d.CanCollide)
				d:SetAttribute("PU_Massless", d.Massless)
				d:SetAttribute("PU_Touch", d.CanTouch)
			end
			d.CanTouch = false
			d.CanCollide = d.Name ~= "GuardHull"
			d.Massless = false
			d.Anchored = false
		end
	end

	if handle then
		if hrp then
			handle.CFrame = hrp.CFrame * CFrame.new(1.5, 1.5, -1)
			local fling = (dir or hrp.CFrame.LookVector) + Vector3.new(0, 0.6, 0)
			handle.AssemblyLinearVelocity  = fling.Unit * (speed or C.DROP_SPEED)
			handle.AssemblyAngularVelocity = Vector3.new(math.random() * 8, math.random() * 8, math.random() * 8)
		end
		local cfg = Pickup.config(tool)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PickupPrompt"
		prompt.ActionText = "Pick up"
		prompt.ObjectText = (cfg.Name or tool.Name) .. (cfg.SECONDARY and "  (secondary)" or "")
		prompt.KeyboardKeyCode = Enum.KeyCode.V   -- the client swaps in its own keybind
		prompt.HoldDuration = C.PROMPT_HOLD
		prompt.MaxActivationDistance = C.PROMPT_RANGE
		prompt.RequiresLineOfSight = false
		prompt.Parent = handle
		prompt.Triggered:Connect(function(plr) Pickup.take(plr, tool) end)
	end

	-- the janitor fades it out after DESPAWN (or sooner, when too many lie around),
	-- but only if it's STILL lying here: one someone picked up is theirs
	local stamp = os.clock()
	tool:SetAttribute("DropStamp", stamp)
	Janitor.add(tool, "Weapon", {life = C.DESPAWN,
		still = function() return tool.Parent ~= nil and Pickup.isDropped(tool) and tool:GetAttribute("DropStamp") == stamp end})
	log("dropped", tool.Name, char and ("by " .. char.Name) or "")
	return true
end

-- everything a character carries hits the floor (death)
function Pickup.dropAll(char)
	local plr = Players:GetPlayerFromCharacter(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	for i, t in ipairs(Pickup.owned(plr, char)) do
		local dir = hrp and (hrp.CFrame.LookVector + hrp.CFrame.RightVector * (i - 1.5)) or nil
		Pickup.drop(t, char, dir, C.DROP_SPEED)
	end
end

--------------------------------------------------------------------
--  TAKE
--------------------------------------------------------------------
local function restore(tool)
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("PU_Collide") ~= nil then
			d.CanCollide = d:GetAttribute("PU_Collide")
			d.Massless   = d:GetAttribute("PU_Massless")
			d.CanTouch   = d:GetAttribute("PU_Touch")
			d.AssemblyLinearVelocity = Vector3.zero
			d:SetAttribute("PU_Collide", nil)
			d:SetAttribute("PU_Massless", nil)
			d:SetAttribute("PU_Touch", nil)
		end
	end
	local prompt = tool:FindFirstChild("PickupPrompt", true)
	if prompt then prompt:Destroy() end
	tool:SetAttribute("Dropped", nil)
	tool:SetAttribute("DropStamp", nil)
end

function Pickup.take(plr, tool)
	if not (plr and tool and tool.Parent and Pickup.isDropped(tool)) then return false end
	local char = plr.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then return false end
	if char:GetAttribute("Ragdolled") or (char:GetAttribute("StunnedUntil") or 0) > os.clock() then return false end
	local handle = handleOf(tool)
	if handle and (handle.Position - hrp.Position).Magnitude > C.PROMPT_RANGE + 4 then return false end
	local bp = plr:FindFirstChild("Backpack")
	if not bp then return false end

	-- make room: a primary replaces the primary, a secondary the secondary;
	-- over MAX_WEAPONS the equipped one (or the last one) goes
	local secondary = Pickup.isSecondary(tool)
	local owned = Pickup.owned(plr, char)
	local toDrop
	for _, t in ipairs(owned) do
		if Pickup.isSecondary(t) == secondary then toDrop = t; break end
	end
	if not toDrop and #owned >= C.MAX_WEAPONS then
		toDrop = char:FindFirstChildOfClass("Tool") or owned[#owned]
	end
	if toDrop then
		Pickup.drop(toDrop, char, hrp.CFrame.LookVector, C.DROP_SPEED)
	end

	restore(tool)
	tool.Parent = bp
	-- straight into the hand when it was empty
	if not char:FindFirstChildOfClass("Tool") then
		task.defer(function() if tool.Parent == bp and hum.Health > 0 then hum:EquipTool(tool) end end)
	end
	Sounds.play(SoundConfig.Pickup, hrp)
	log(plr.Name, "picked up", tool.Name, toDrop and ("(dropped " .. toDrop.Name .. ")") or "")
	return true
end

-- a bot (no Backpack) takes a weapon off the floor straight into its hand;
-- whatever it held goes down in its place
function Pickup.takeNpc(char, tool)
	if not (char and tool and tool.Parent and Pickup.isDropped(tool)) then return false end
	if Players:GetPlayerFromCharacter(char) then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then return false end
	if char:GetAttribute("Ragdolled") or (char:GetAttribute("StunnedUntil") or 0) > os.clock() then return false end
	local handle = handleOf(tool)
	if handle and (handle.Position - hrp.Position).Magnitude > C.PROMPT_RANGE + 4 then return false end
	local held = char:FindFirstChildOfClass("Tool")
	if held then Pickup.drop(held, char, hrp.CFrame.LookVector, C.DROP_SPEED) end
	restore(tool)
	tool.Parent = char
	Sounds.play(SoundConfig.Pickup, hrp)
	log(char.Name, "picked up", tool.Name)
	return true
end

-- the nearest weapon lying on the floor within `range` of pos (and its distance)
function Pickup.nearest(pos, range)
	local best, bestD = nil, range or math.huge
	local f = workspace:FindFirstChild("DroppedWeapons")
	for _, t in ipairs(f and f:GetChildren() or {}) do
		if t:IsA("Tool") and Pickup.isDropped(t) then
			local h = handleOf(t)
			local d = h and (h.Position - pos).Magnitude
			if d and d < bestD then best, bestD = t, d end
		end
	end
	return best, best and bestD or nil
end

-- rules for the loadout menu: can this pair be carried together?
function Pickup.validLoadout(primaryTool, secondaryTool)
	if secondaryTool and not Pickup.isSecondary(secondaryTool) then return false, "that weapon can't be a secondary" end
	if primaryTool and secondaryTool and primaryTool == secondaryTool then return false, "same weapon twice" end
	return true
end

return Pickup
