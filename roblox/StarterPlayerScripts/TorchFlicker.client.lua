--[[ TORCH FLICKER — fire lights breathe. Any PointLight named "Flicker" (a dungeon's sconces,
     braziers and candles: Game ▸ Dungeon; the Gilded Rat's torches: Game ▸ TavernMap) wavers
     about the brightness and range it was built with, each on its own rhythm. Only the lights
     near the camera are touched, a dozen times a second; nothing here is sent to the server.

     The Depths' Shade (Game ▸ Shade, on the Round node): as the dark stirs every torch sputters a
     few seconds, and while it's about, the torches round it gutter low as it passes. ]]

local RunService = game:GetService("RunService")
local round = game:GetService("ReplicatedStorage"):WaitForChild("Round")

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
local stirAt = nil
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < RATE then return end
	acc = 0
	local cam = workspace.CurrentCamera
	if not cam then return end
	local eye = cam.CFrame.Position
	local t = os.clock()
	-- (the Shade: where it is, and whether the dark has only just stirred)
	local state = round:GetAttribute("ShadeState")
	local shade = (state == "hunt" or state == "wait") and round:GetAttribute("ShadePos") or nil
	if typeof(shade) ~= "Vector3" then shade = nil end
	if state == "stir" and not stirAt then stirAt = t elseif state ~= "stir" then stirAt = nil end
	local stir = stirAt and t - stirAt < 5 and (1 - (t - stirAt) / 5) or 0
	for l, base in pairs(lights) do
		local p = l.Parent
		if p and p:IsA("BasePart") and (p.Position - eye).Magnitude < NEAR then
			-- a slow sway and a quick shiver (smooth noise, never a strobe)
			local n = math.noise(t * 1.3, base.seed) * 0.6 + math.noise(t * 6.5, base.seed + 50) * 0.4
			local k = 1
			if stir > 0 then k = 1 - stir * (0.45 + 0.4 * math.noise(t * 9, base.seed + 90)) end
			if shade then
				local d = (p.Position - shade).Magnitude
				if d < 26 then
					local u = math.clamp((d - 7) / 19, 0, 1)
					k = math.min(k, 0.06 + 0.94 * u * u + math.max(0, math.noise(t * 11, base.seed + 20)) * 0.15 * (1 - u))
				end
			end
			l.Brightness = base.b * (1 + n * 0.32) * k
			l.Range = base.r * (1 + n * 0.08) * (0.6 + 0.4 * k)
		end
	end
end)
