--[[ ARMOR FX (client) — brings an armor finish's glowing trims to life (the
     parts ReplicatedStorage ▸ ArmorFX tags "ArmorGlow"): Mode "pulse" breathes,
     "flicker" crackles like a storm, "radiant" walks the rainbow. Anyone's
     armor, in the world and in the menu's previews. Looks only, local only. ]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local parts = {}   -- [part] = {base = Color3, seed}
local rng = Random.new()

local function add(p)
	if not p:IsA("BasePart") then return end
	local c = p:GetAttribute("GlowColor")
	parts[p] = {base = typeof(c) == "Color3" and c or p.Color, seed = rng:NextNumber(0, 6.28), mode = p:GetAttribute("Mode")}
end
CollectionService:GetInstanceAddedSignal("ArmorGlow"):Connect(add)
CollectionService:GetInstanceRemovedSignal("ArmorGlow"):Connect(function(p) parts[p] = nil end)
for _, p in ipairs(CollectionService:GetTagged("ArmorGlow")) do add(p) end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then return end
	acc = 0
	local now = os.clock()
	local cam = workspace.CurrentCamera
	local eye = cam and cam.CFrame.Position
	for p, st in pairs(parts) do
		if not p.Parent then parts[p] = nil; continue end
		-- (far away in the world: left as it is)
		if eye and p:IsDescendantOf(workspace) and (p.Position - eye).Magnitude > 160 then continue end
		if st.mode == "radiant" then
			p.Color = Color3.fromHSV((now * 0.15 + st.seed) % 1, 0.6, 0.72)
		elseif st.mode == "flicker" then
			local k = rng:NextNumber() < 0.12 and rng:NextNumber(0.3, 0.7) or 1
			p.Color = st.base:Lerp(Color3.new(1, 1, 1), (1 - k) * 0.6)
			p.Transparency = (k < 1) and 0.25 or 0
		else   -- pulse
			local k = 0.5 + 0.5 * math.sin(now * 2.4 + st.seed)
			p.Color = st.base:Lerp(Color3.new(0, 0, 0), 0.35 * (1 - k))
		end
	end
end)
