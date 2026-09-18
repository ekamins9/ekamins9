--[[ CHARACTER SYSTEMS — per-character server wiring that isn't tied to a
     weapon: ragdoll on death, bleed-out ticking, death sound.
     Covers every player character plus any humanoid Model placed in a
     workspace.NPCs folder. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local Ragdoll     = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Ragdoll"))
local Injury      = require(ServerScriptService.Combat:WaitForChild("Injury"))
local Sounds      = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))

local function setup(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	hum.BreakJointsOnDeath = false   -- Ragdoll needs the joints intact

	hum.Died:Once(function()
		Ragdoll.enable(char)
		Sounds.play(SoundConfig.Death, char:FindFirstChild("Head") or char:FindFirstChild("Torso"))
	end)

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not (char.Parent and hum.Parent) then
			conn:Disconnect()
			return
		end
		Injury.tick(char, dt)
	end)
end

local function onPlayer(p)
	p.CharacterAdded:Connect(setup)
	if p.Character then setup(p.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end

local npcs = workspace:FindFirstChild("NPCs")
if npcs then
	for _, m in ipairs(npcs:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then setup(m) end
	end
	npcs.ChildAdded:Connect(function(m)
		if m:IsA("Model") then setup(m) end
	end)
end
