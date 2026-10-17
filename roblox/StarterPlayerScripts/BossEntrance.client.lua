--[[ BOSS ENTRANCE — Siege's champion on his throne and the Horde's Warlord get the entrance the
     Depths' lords have (ReplicatedStorage ▸ BossIntro): when a bot in workspace ▸ NPCs becomes a
     Boss in one of those modes, the bars, the camera on it, its name, a boom. Once each.
     War's champions (Game ▸ Modes ▸ War:champion) get the bars and the name only: in the thick of
     a battle the camera stays yours.

     A BOSS FALLS (any boss in workspace ▸ NPCs, in any mode, within 200 studs of you): a deep
     boom and the ground shaking, a pillar of light where it stood, a ring of force rolling out
     over the floor, a cloud of dust, the world washing white for a moment. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossIntro = require(ReplicatedStorage:WaitForChild("BossIntro"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local round = ReplicatedStorage:WaitForChild("Round")
local seen = setmetatable({}, {__mode = "k"})

-- what the bars say, by mode
local SAYS = {
	Siege = function(m)
		local title = round:GetAttribute("MapName") or round:GetAttribute("Map") or "the castle"
		return string.upper(m:GetAttribute("TagName") or m.Name), "THE CHAMPION OF " .. string.upper(title) .. "  ·  SLAY HIM"
	end,
	Horde = function(m)
		return string.upper(m:GetAttribute("TagName") or "THE WARLORD"), "THE WARLORD LEADS THIS WAVE  ·  HOLD THE CAMP"
	end,
	War = function(m)
		local me = game:GetService("Players").LocalPlayer.Character
		local ours = me and me:GetAttribute("Team") ~= nil and me:GetAttribute("Team") == m:GetAttribute("Team")
		return string.upper(m:GetAttribute("TagName") or m.Name), ours and "YOUR CHAMPION TAKES THE FIELD" or "THEIR CHAMPION TAKES THE FIELD  ·  BRING HIM DOWN", true
	end,
}

local function check(m)
	local say = SAYS[round:GetAttribute("Mode") or ""]
	if not say or seen[m] or not m:GetAttribute("Boss") then return end
	if round:GetAttribute("State") ~= "Round" then return end
	seen[m] = true
	task.wait(0.4)   -- (dressed and standing first)
	if not m.Parent then return end
	local text, sub, nameOnly = say(m)
	BossIntro.play(not nameOnly and m or nil, text, sub)
end

-- A BOSS FALLS
local fallen = setmetatable({}, {__mode = "k"})
local function falls(m)
	if fallen[m] then return end
	fallen[m] = true
	local root = m:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	if not (root and cam) or (cam.CFrame.Position - root.Position).Magnitude > 200 then return end
	local scale = m:GetAttribute("MonsterScale") or 1
	local feet = root.Position - Vector3.new(0, 3 * scale, 0)
	local near = (cam.CFrame.Position - root.Position).Magnitude
	WarFX.sound("Impact", root.Position, {volume = 1, speed = 0.38, near = 30, range = 400})
	WarFX.shake(math.clamp(1.2 - near / 160, 0.25, 1), 1.2)
	WarFX.dust(feet + Vector3.new(0, 1, 0), 3 * scale, Color3.fromRGB(150, 140, 126))
	local folder = Instance.new("Folder")
	folder.Name = "BossFalls"
	folder.Parent = workspace.Terrain
	local function glow(size, cf, shape, color)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Shape = shape
		p.Size = size
		p.CFrame = cf
		p.Parent = folder
		return p
	end
	local light = Color3.fromRGB(255, 236, 190)
	-- the pillar of light where it stood
	local pillar = glow(Vector3.new(80, 6 * scale, 6 * scale), CFrame.new(feet + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder, light)
	pillar.Transparency = 0.35
	TweenService:Create(pillar, TweenInfo.new(2.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1, Size = Vector3.new(80, 0.5, 0.5)}):Play()
	local pl = Instance.new("PointLight"); pl.Color = light; pl.Range = 40; pl.Brightness = 4; pl.Parent = pillar
	TweenService:Create(pl, TweenInfo.new(2.4), {Brightness = 0}):Play()
	-- the ring of force rolling out over the floor
	local ring = glow(Vector3.new(0.2, 2, 2), CFrame.new(feet + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder, light)
	ring.Transparency = 0.3
	TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.2, 46 * scale, 46 * scale), Transparency = 1}):Play()
	-- the world washes white for a moment
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "BossFallsFlash"
	cc.Brightness, cc.Saturation, cc.TintColor = 0.35, -0.5, Color3.fromRGB(255, 246, 230)
	cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(1.6, Enum.EasingStyle.Quad), {Brightness = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1)}):Play()
	Debris:AddItem(cc, 1.7)
	Debris:AddItem(folder, 2.6)
end

local function watch(npcs)
	local function hook(m)
		if not m:IsA("Model") then return end
		task.spawn(function()
			local h = m:FindFirstChildOfClass("Humanoid") or m:WaitForChild("Humanoid", 5)
			if h then h.Died:Connect(function() if m:GetAttribute("Boss") then falls(m) end end) end
		end)
		m:GetAttributeChangedSignal("Boss"):Connect(function() task.spawn(check, m) end)
		if m:GetAttribute("Boss") then task.spawn(check, m) end
	end
	for _, m in ipairs(npcs:GetChildren()) do hook(m) end
	npcs.ChildAdded:Connect(hook)
end
local npcs = workspace:FindFirstChild("NPCs")
if npcs then watch(npcs) end
workspace.ChildAdded:Connect(function(c) if c.Name == "NPCs" then watch(c) end end)
