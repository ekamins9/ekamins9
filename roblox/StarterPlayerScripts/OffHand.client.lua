--[[ OFF HAND — a one-handed weapon is fought with one hand: every clip of it plays as it is,
     but the free (left) arm keeps still at your side (or comes up behind a shield while you
     block: RigPose). Roblox can't mask a limb out of an animation, so on every screen, for every
     body holding a one-handed weapon (Catalog: family "OneHanded"), the left shoulder's
     animated turn (its Motor6D.Transform) is taken back out each frame once the Animator has
     stepped, and again before drawing (as Emotes does for the joints an emote drives). The
     joint's own pose (C0: the look's bend, a gesture, a shield raised) is untouched. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))

local oneHand = setmetatable({}, {__mode = "k"})   -- [tool] = bool
local function oneHanded(tool)
	local v = oneHand[tool]
	if v == nil then
		local w = Catalog.WEAPON[tool.Name]
		v = w ~= nil and w.family == "OneHanded"
		oneHand[tool] = v
	end
	return v
end

local function still(c)
	local tool = c:FindFirstChildOfClass("Tool")
	if not (tool and oneHanded(tool)) or c:GetAttribute("Ragdolled") then return end
	local torso = c:FindFirstChild("Torso")
	local sh = torso and torso:FindFirstChild("Left Shoulder")
	if sh and sh:IsA("Motor6D") then sh.Transform = CFrame.identity end
end
local function everyone()
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then still(p.Character) end end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do if m:IsA("Model") then still(m) end end end
end
RunService.Stepped:Connect(everyone)
RunService.RenderStepped:Connect(everyone)
