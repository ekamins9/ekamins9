--[[ DODGE FX — a dodge kicks up the ground. Whenever anyone dodges (MovementServer stamps
     LastDodgeAt on them; bots too), every screen near them shows a burst of dust at their feet,
     thrown back against the way they went, the colour of what they stand on (grass, sand, mud,
     snow, stone). Within 100 studs of your camera. Nothing is sent to the server. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local NEAR = 100
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- the dust's colour: what's underfoot, paled and browned a little
local TERRAIN = {
	[Enum.Material.Grass] = Color3.fromRGB(128, 120, 86), [Enum.Material.LeafyGrass] = Color3.fromRGB(122, 116, 82),
	[Enum.Material.Sand] = Color3.fromRGB(214, 196, 150), [Enum.Material.Snow] = Color3.fromRGB(236, 240, 246),
	[Enum.Material.Mud] = Color3.fromRGB(104, 88, 68), [Enum.Material.Ground] = Color3.fromRGB(132, 112, 86),
	[Enum.Material.Rock] = Color3.fromRGB(150, 146, 140), [Enum.Material.Glacier] = Color3.fromRGB(220, 234, 244),
}
local DUST = Color3.fromRGB(150, 136, 112)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local function puff(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	if not root or (cam and (cam.CFrame.Position - root.Position).Magnitude > NEAR) then return end
	params.FilterDescendantsInstances = {model}
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), params)
	if not hit then return end
	local col = TERRAIN[hit.Material] or (hit.Instance ~= workspace.Terrain and hit.Instance.Color:Lerp(DUST, 0.5)) or DUST
	-- (which way they went: a frame on, the body's moving)
	task.wait(0.05)
	if not root.Parent then return end
	local v = root.AssemblyLinearVelocity
	local flat = Vector3.new(v.X, 0, v.Z)
	local back = flat.Magnitude > 2 and -flat.Unit or -root.CFrame.LookVector
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	-- (the emitter shoots along the part's front: back the way they came, a little up)
	p.CFrame = CFrame.lookAt(hit.Position + Vector3.new(0, 0.3, 0), hit.Position + Vector3.new(0, 0.3, 0) + back + Vector3.new(0, 0.35, 0))
	local e = Instance.new("ParticleEmitter")
	e.Texture = SMOKE
	e.Color = ColorSequence.new(col)
	e.LightInfluence = 1
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.8)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(0.45, 0.9)
	e.Speed = NumberRange.new(4, 10)
	e.SpreadAngle = Vector2.new(55, 18)
	e.EmissionDirection = Enum.NormalId.Front
	e.Drag = 3.5
	e.Acceleration = Vector3.new(0, 1.5, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-40, 40)
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace
	e:Emit(14)
	Debris:AddItem(p, 1.4)
end

local watched = setmetatable({}, {__mode = "k"})
local function watch(model)
	if watched[model] or not model:IsA("Model") then return end
	watched[model] = true
	model:GetAttributeChangedSignal("LastDodgeAt"):Connect(function() task.spawn(puff, model) end)
end
local function watchPlayer(p)
	if p.Character then watch(p.Character) end
	p.CharacterAdded:Connect(watch)
end
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
task.spawn(function()
	local npcs = workspace:WaitForChild("NPCs", 1e9)
	for _, m in ipairs(npcs:GetChildren()) do watch(m) end
	npcs.ChildAdded:Connect(watch)
end)
