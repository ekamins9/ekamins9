--[[ BANNER WIND — the cloth on every map moves, on your screen only: banners, pennants and
     standards (Banner, Pennant, KeepBanner, HallBanner, WallBanner, PodiumBanner, with their tips,
     trims and crests swinging along) sway from their top edge in the wind, each on its own
     rhythm; harder in a storm. Only cloth near the camera is touched, a dozen times a second.
     Nothing here is sent to the server. ]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))

local CLOTH = {Banner = true, Pennant = true, KeepBanner = true, HallBanner = true, WallBanner = true, PodiumBanner = true}
local HANGERS = {BannerTip = true, KeepBannerTrim = true, KeepBannerCrest = true, HallBannerStar = true, WallBannerStar = true}
local NEAR = 160
local RATE = 1 / 12

local cloths = {}   -- part -> {base = CFrame, pivot = CFrame (its top edge, world), seed, kids = {{part, off}}}
local pending = {}  -- hangers not yet matched to a cloth

-- a part's top edge (its highest face's middle), and its height along world up
local function topOf(p)
	local cf, s = p.CFrame, p.Size
	local best, h = nil, 0
	for _, a in ipairs({{cf.RightVector, s.X}, {cf.UpVector, s.Y}, {cf.LookVector, s.Z}}) do
		if not best or math.abs(a[1].Y) > math.abs(best.Y) then best, h = a[1], a[2] end
	end
	local up = best.Y >= 0 and best or -best
	return cf.Position + up * h / 2, h
end

local function adopt(h)
	-- (a hanger swings with the cloth it hangs off: the nearest one, close by)
	local best, bestD = nil, 4
	for c in pairs(cloths) do
		local d = (c.Position - h.Position).Magnitude
		if d < bestD then best, bestD = c, d end
	end
	if not best then return false end
	local e = cloths[best]
	table.insert(e.kids, {h, e.pivot:ToObjectSpace(h.CFrame)})
	return true
end

local function add(p)
	if not p:IsA("BasePart") then return end
	if CLOTH[p.Name] and not cloths[p] then
		local top = topOf(p)
		local pivot = CFrame.new(top) * (p.CFrame - p.CFrame.Position)
		cloths[p] = {pivot = pivot, off = pivot:ToObjectSpace(p.CFrame), seed = math.random() * 100, kids = {}}
		for i = #pending, 1, -1 do if adopt(pending[i]) then table.remove(pending, i) end end
	elseif HANGERS[p.Name] then
		if not adopt(p) then table.insert(pending, p) end
	end
end

local function watchMap(m)
	for _, d in ipairs(m:GetDescendants()) do add(d) end
	m.DescendantAdded:Connect(add)
end
local m = workspace:FindFirstChild("Map")
if m then watchMap(m) end
workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then watchMap(c) end end)
workspace.DescendantRemoving:Connect(function(d) cloths[d] = nil end)

local acc = 0
local ps, cfs = {}, {}
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < RATE then return end
	acc = 0
	local cam = workspace.CurrentCamera
	if not cam then return end
	local eye = cam.CFrame.Position
	local t = os.clock()
	local w = WarFX.weatherKind()
	local gust = (w == "storm" and 2.2) or (w == "rain" and 1.4) or 1
	local n = 0
	for p, e in pairs(cloths) do
		if p.Parent and (e.pivot.Position - eye).Magnitude < NEAR then
			-- (a slow swell and a quick flutter, each cloth its own)
			local a = (math.noise(t * 0.6, e.seed) * 0.16 + math.sin(t * 3.1 + e.seed) * 0.035) * gust
			local b = math.noise(t * 0.9, e.seed + 40) * 0.08 * gust
			local swing = e.pivot * CFrame.Angles(a, 0, b)
			n += 1; ps[n] = p; cfs[n] = swing * e.off
			for _, k in ipairs(e.kids) do
				if k[1].Parent then n += 1; ps[n] = k[1]; cfs[n] = swing * k[2] end
			end
		end
	end
	for i = n + 1, #ps do ps[i] = nil; cfs[i] = nil end
	if n > 0 then workspace:BulkMoveTo(ps, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
end)
