--[[ SWING ARCS — everyone's blade leaves a faint arc as it swings, on your screen. Your own weapon
     draws its trail itself (Combat ▸ CombatClient, TRAIL), and only for you; this draws the same
     kind of arc behind every OTHER fighter's blade — other players and the bots — so a swing coming
     at you reads as a swing, and a melee looks like one.

     The arc runs along the outer half of the weapon's Hitbox (its long axis: the blade), lit only
     while the blade's tip is really moving (faster than LIVE studs a second) during someone's
     action (their Acting attribute: a swing or a kick), so a weapon carried or waved in an idle
     never trails. A riposte's arc is gold. Within NEAR studs of your camera. Nothing is sent to the
     server. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local NEAR = 140
local LIVE = 26          -- studs a second the tip must move for the arc to draw
local SILVER = ColorSequence.new(Color3.fromRGB(236, 240, 255), Color3.fromRGB(196, 206, 230))
local GOLD = ColorSequence.new(Color3.fromRGB(255, 236, 160), Color3.fromRGB(255, 196, 80))

local arcs = setmetatable({}, {__mode = "k"})   -- [Tool] = {trail, tipA, hitbox, last}

-- the blade's two ends: the Hitbox's long axis
local function ends(box)
	local s = box.Size
	if s.X >= s.Y and s.X >= s.Z then return Vector3.new(s.X / 2, 0, 0) end
	if s.Y >= s.Z then return Vector3.new(0, s.Y / 2, 0) end
	return Vector3.new(0, 0, s.Z / 2)
end

local function arcFor(tool)
	local a = arcs[tool]
	if a ~= nil then return a or nil end
	local box = tool:FindFirstChild("Hitbox", true)
	if not (box and box:IsA("BasePart")) then arcs[tool] = false; return nil end
	local half = ends(box)
	local a0 = Instance.new("Attachment"); a0.Name = "ArcA0"; a0.Position = half * 0.1; a0.Parent = box
	local a1 = Instance.new("Attachment"); a1.Name = "ArcA1"; a1.Position = half; a1.Parent = box
	local t = Instance.new("Trail")
	t.Name = "SwingArc"
	t.Attachment0, t.Attachment1 = a0, a1
	t.Lifetime = 0.1
	t.MinLength = 0.05
	t.Color = SILVER
	t.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.62), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 1)})
	t.WidthScale = NumberSequence.new(1, 0.1)
	t.LightEmission = 0.25
	t.FaceCamera = false
	t.Enabled = false
	t.Parent = box
	a = {trail = t, box = box, tip = half, last = nil}
	arcs[tool] = a
	-- (gone with the weapon)
	tool.Destroying:Connect(function() arcs[tool] = nil end)
	return a
end

-- the fighters: other players' bodies, and everyone under workspace ▸ NPCs
local fighters = {}
local function track(model)
	if model == player.Character or not model:IsA("Model") then return end
	fighters[model] = true
	model.AncestryChanged:Connect(function(_, parent) if not parent then fighters[model] = nil end end)
end
local function watchPlayer(p)
	if p == player then return end
	if p.Character then track(p.Character) end
	p.CharacterAdded:Connect(track)
end
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
task.spawn(function()
	local npcs = workspace:WaitForChild("NPCs", 1e9)
	for _, m in ipairs(npcs:GetChildren()) do track(m) end
	npcs.ChildAdded:Connect(track)
end)

RunService.Heartbeat:Connect(function(dt)
	if dt <= 0 then return end
	local cam = workspace.CurrentCamera
	local eye = cam and cam.CFrame.Position
	for model in pairs(fighters) do
		local tool = model.Parent and model:FindFirstChildOfClass("Tool")
		local a = tool and arcFor(tool)
		if a then
			local acting = model:GetAttribute("Acting") == true
			local root = model:FindFirstChild("HumanoidRootPart")
			local near = root and eye and (root.Position - eye).Magnitude < NEAR
			local tip = a.box.CFrame:PointToWorldSpace(a.tip)
			local on = false
			if acting and near and a.last then
				on = (tip - a.last).Magnitude / dt > LIVE
			end
			a.last = tip
			if on then
				local gold = (model:GetAttribute("RiposteUntil") or 0) > workspace:GetServerTimeNow()
				a.trail.Color = gold and GOLD or SILVER
			end
			if a.trail.Enabled ~= on then a.trail.Enabled = on end
		end
	end
end)
