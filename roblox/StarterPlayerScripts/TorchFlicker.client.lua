--[[ TORCH FLICKER — fire lights breathe. Any PointLight named "Flicker" (a dungeon's sconces,
     braziers and candles: Game ▸ Dungeon; the Gilded Rat's torches: Game ▸ TavernMap) wavers
     about the brightness and range it was built with, each on its own rhythm. Only the lights
     near the camera are touched, a dozen times a second; nothing here is sent to the server. ]]

local RunService = game:GetService("RunService")

local NEAR = 140      -- studs from the camera
local RATE = 1 / 14   -- seconds between steps

local lights = {}     -- light -> {b = brightness, r = range, seed = n}

local function add(d)
	if d:IsA("PointLight") and d.Name == "Flicker" and not lights[d] then
		lights[d] = {b = d.Brightness, r = d.Range, seed = math.random() * 1000}
	end
end
for _, d in ipairs(workspace:GetDescendants()) do add(d) end
workspace.DescendantAdded:Connect(add)
workspace.DescendantRemoving:Connect(function(d) lights[d] = nil end)

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < RATE then return end
	acc = 0
	local cam = workspace.CurrentCamera
	if not cam then return end
	local eye = cam.CFrame.Position
	local t = os.clock()
	for l, base in pairs(lights) do
		local p = l.Parent
		if p and p:IsA("BasePart") and (p.Position - eye).Magnitude < NEAR then
			-- a slow sway and a quick shiver (smooth noise, never a strobe)
			local n = math.noise(t * 1.3, base.seed) * 0.6 + math.noise(t * 6.5, base.seed + 50) * 0.4
			l.Brightness = base.b * (1 + n * 0.32)
			l.Range = base.r * (1 + n * 0.08)
		end
	end
end)
