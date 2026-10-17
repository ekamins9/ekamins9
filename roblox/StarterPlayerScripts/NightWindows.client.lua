--[[ NIGHT WINDOWS — after dark, the windows of a map's houses and towers glow with the warm light
     of the rooms behind them (about two in three: the rest are dark, their people asleep or
     fled), on your screen only. Which ones is fixed by where each window is, so every screen
     agrees, and each spills a little warm light onto the ground outside (not on a phone). When the
     sun comes up (Plague Night's dawn) they go dark again; a new map starts over.

     A window is a small part named "Window" under workspace ▸ Map (Build ▸ MapKit's houses and
     towers). Nothing here is sent to the server. ]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Device = require(ReplicatedStorage:WaitForChild("Device"))
local SPILL = Device.kind() ~= "phone"

local LIT = {Color3.fromRGB(255, 176, 96), Color3.fromRGB(255, 196, 120), Color3.fromRGB(250, 160, 80)}

local was = setmetatable({}, {__mode = "k"})   -- window -> {color, material}
local on = false
local conn

local function night()
	local t = Lighting.ClockTime
	return t < 5.8 or t > 18.6
end

-- (a stable pick from where it stands)
local function lit(p)
	local q = p.Position
	local h = math.abs(math.floor(q.X * 7.31 + q.Y * 3.17 + q.Z * 5.13))
	return h % 3 ~= 0, LIT[h % #LIT + 1]
end

local function light(p)
	if not (p:IsA("BasePart") and p.Name == "Window") or was[p] then return end
	if math.max(p.Size.X, p.Size.Y, p.Size.Z) > 3 then return end
	local yes, color = lit(p)
	if not yes then return end
	local glow
	if SPILL then
		glow = Instance.new("PointLight")
		glow.Name = "NightWindow"
		glow.Color, glow.Range, glow.Brightness, glow.Shadows = color, 9, 0.7, false
		glow.Parent = p
	end
	was[p] = {p.Color, p.Material, glow}
	p.Color, p.Material = color, Enum.Material.Neon
end

local function douse()
	for p, v in pairs(was) do
		if p.Parent then p.Color, p.Material = v[1], v[2] end
		if v[3] then v[3]:Destroy() end
	end
	table.clear(was)
end

local function refresh()
	local map = workspace:FindFirstChild("Map")
	local want = map ~= nil and night()
	if want == on and conn then return end
	if conn then conn:Disconnect(); conn = nil end
	douse()
	on = want
	if not want then return end
	for _, d in ipairs(map:GetDescendants()) do light(d) end
	-- (what streams in later)
	conn = map.DescendantAdded:Connect(light)
end

workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then on = false; task.delay(1, refresh) end end)
workspace.ChildRemoved:Connect(function(c) if c.Name == "Map" then on = false; if conn then conn:Disconnect(); conn = nil end; table.clear(was) end end)
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	-- (only when it crosses dusk or dawn)
	if night() ~= on then refresh() end
end)
task.delay(2, refresh)
