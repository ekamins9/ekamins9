--[[ PASTIMES (server) — the clock and the place behind Economy ▸ Pastimes.
       • Playtime: every server (the Courtyard and every match) adds the
         minutes you play to today's playtime gifts.
       • The Hatchery: built into the Courtyard (Hub mode) next to the open
         square. Standing within Catalog ▸ Eggs ▸ radius of it makes your
         eggs incubate `boost` times as fast.
       • Player attributes the clients read (no remote polling):
           PlaySeconds, GiftsClaimed ("1,3"), GiftDay     the gift chip
           AtHatchery                                       the "×2" line
           Nests ("Speckled,1760000000;;Mossy,1760001234")  egg, ready at (server time)
           EggCount                                         eggs waiting for a nest
           Companion, CompanionStars                        who follows you
     Where the Hatchery stands: a part named "HatcherySpot" in the map (its
     position and facing), else Catalog ▸ Eggs ▸ spot (an offset from the
     map's Floor part, per map name). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Pastimes = require(ServerScriptService:WaitForChild("Economy"):WaitForChild("Pastimes"))
local K = require(ServerScriptService:WaitForChild("Build"):WaitForChild("MapKit"))

local EGGS = Catalog.EGGS
local roundNode = ReplicatedStorage:WaitForChild("Round")
local function inHub() return roundNode:GetAttribute("Mode") == "Hub" end

--------------------------------------------------------------------
--  THE HATCHERY (built from parts, like the maps)
--------------------------------------------------------------------
local hatchery, centre = nil, nil

local function build(at, facing)
	local m = Instance.new("Model")
	m.Name = "Hatchery"
	local ctx = {name = "Hatchery", model = m, n = 0, Geometry = m, Props = m}
	local C, M = K.C, K.M
	local look = (facing - at) * Vector3.new(1, 0, 1)
	look = look.Magnitude > 0.1 and look.Unit or Vector3.new(0, 0, -1)
	local base = CFrame.lookAt(at, at + look)          -- -Z faces the open square
	local function p(x, y, z) return (base * CFrame.new(x, y, z)).Position end
	-- the dais, a straw bed, a low wooden rim
	K.cyl(ctx, "Dais", 24, 0.4, CFrame.new(p(0, 0.2, 0)), C.STONE, M.Slate)
	K.nocollide(K.cyl(ctx, "Straw", 20.5, 0.06, CFrame.new(p(0, 0.43, 0)), C.THATCH, M.Grass))
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		local rim = K.box(ctx, "Rim", Vector3.new(0.5, 0.7, 4.7), base * CFrame.Angles(0, a, 0) * CFrame.new(11.7, 0.75, 0), C.WOOD, M.Wood)
		if i == 4 then rim:Destroy() end   -- the way in, facing the square (-Z after the turn below)
	end
	-- three nests on stone pedestals along the back, facing the square
	for i, ang in ipairs({-42, 0, 42}) do
		local cf = base * CFrame.Angles(0, math.rad(ang), 0) * CFrame.new(0, 0, 6.2)
		local foot = cf.Position
		K.cyl(ctx, "Pedestal", 4.8, 1.3, CFrame.new(foot + Vector3.new(0, 0.4 + 0.65, 0)), C.STONEDARK, M.Slate)
		K.cyl(ctx, "Nest", 4.4, 0.9, CFrame.new(foot + Vector3.new(0, 1.7 + 0.45, 0)), C.THATCH, M.Grass)
		K.nocollide(K.cyl(ctx, "NestHollow", 3.1, 0.92, CFrame.new(foot + Vector3.new(0, 1.7 + 0.5, 0)), Color3.fromRGB(150, 116, 60), M.Grass))
		for t = 0, 9 do
			local a = t / 10 * math.pi * 2
			local twig = K.box(ctx, "Twig", Vector3.new(0.22, 0.22, 1.5), CFrame.new(foot + Vector3.new(0, 2.55, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(2.0, 0, 0) * CFrame.Angles(0, math.rad(20), math.rad(25)), C.DARKWOOD, M.Wood)
			twig.CanCollide = false
		end
		-- where your egg sits (each player sees their own, locally)
		local mark = Instance.new("Part")
		mark.Name = "Nest" .. i
		mark.Anchored, mark.CanCollide, mark.CanQuery, mark.CanTouch = true, false, false, false
		mark.Transparency = 1
		mark.Size = Vector3.new(1, 1, 1)
		mark.CFrame = CFrame.lookAt(foot + Vector3.new(0, 2.45, 0), foot + Vector3.new(0, 2.45, 0) - (cf.LookVector * Vector3.new(1, 0, 1)))
		mark.Parent = m
	end
	-- a brazier in the middle keeps them warm
	K.cyl(ctx, "BrazierPole", 0.5, 2.2, CFrame.new(p(0, 0.4 + 1.1, 0)), C.IRON, M.Metal)
	local bowl = K.cyl(ctx, "Brazier", 2.6, 0.8, CFrame.new(p(0, 2.9, 0)), C.IRON, M.Metal)
	local coals = K.cyl(ctx, "Coals", 2.1, 0.2, CFrame.new(p(0, 3.25, 0)), Color3.fromRGB(255, 120, 40), M.Neon)
	coals.CanCollide = false
	local fire = Instance.new("Fire"); fire.Size = 4; fire.Heat = 6; fire.Color = Color3.fromRGB(255, 150, 60); fire.SecondaryColor = Color3.fromRGB(255, 60, 20); fire.Parent = coals
	local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(255, 170, 90); light.Range = 20; light.Brightness = 1.6; light.Parent = coals
	-- the thatched canopy on six posts
	for i = 0, 5 do
		local a = (i + 0.5) / 6 * math.pi * 2
		K.cyl(ctx, "Post", 0.7, 9.2, base * CFrame.Angles(0, a, 0) * CFrame.new(10.6, 0.4 + 4.6, 0), C.DARKWOOD, M.Wood)
	end
	K.cyl(ctx, "Ring", 22.4, 0.5, CFrame.new(p(0, 9.6, 0)), C.DARKWOOD, M.Wood).CanCollide = false
	K.cone(ctx, "Roof", p(0, 9.8, 0), 13.4, 5.6, C.THATCH, M.Grass, m, true, 10)
	-- the sign by the way in
	local signCF = base * CFrame.new(5.2, 0, -12.6)
	for _, x in ipairs({-3.2, 3.2}) do K.box(ctx, "SignPost", Vector3.new(0.4, 4.8, 0.4), signCF * CFrame.new(x, 2.4, 0), C.DARKWOOD, M.Wood) end
	local board = K.box(ctx, "Sign", Vector3.new(7.4, 2.6, 0.3), signCF * CFrame.new(0, 3.6, 0), C.WOOD, M.WoodPlanks)
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.CanvasSize = Vector2.new(370, 130); sg.LightInfluence = 0.4; sg.Parent = board
	local function text(t, y, h, size, color)
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -20, 0, h); l.Position = UDim2.fromOffset(10, y)
		l.Font = Enum.Font.FredokaOne; l.TextScaled = true; l.TextColor3 = color; l.Text = t; l.Parent = sg
		local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(40, 24, 10); s.Thickness = 2; s.Parent = l
	end
	text("THE HATCHERY", 8, 64, 48, Color3.fromRGB(255, 226, 150))
	text(string.format("stay here: your eggs hatch %d× faster", EGGS.boost or 2), 78, 40, 22, Color3.fromRGB(255, 255, 255))
	-- hay about the place
	for _, xz in ipairs({{-13.5, 3}, {-12.5, 7}, {13.5, 5}}) do K.hay(ctx, p(xz[1], 0, xz[2])) end
	m:SetAttribute("Radius", EGGS.radius or 20)
	return m
end

local function spotFor(map)
	local mark = map:FindFirstChild("HatcherySpot", true)
	if mark and mark:IsA("BasePart") then
		mark.Transparency, mark.CanCollide, mark.CanQuery = 1, false, false
		return mark.Position - Vector3.new(0, mark.Size.Y / 2, 0), mark.Position + mark.CFrame.LookVector * 10
	end
	local floor = map:FindFirstChild("Floor")
	local name = roundNode:GetAttribute("Map") or ""
	local off = EGGS.spot and (EGGS.spot[name] or EGGS.spot.default)
	if floor and floor:IsA("BasePart") and off then
		local top = floor.Position + Vector3.new(0, floor.Size.Y / 2, 0)
		return top + off, top
	end
	return nil
end

local function ensureHatchery()
	if not inHub() then return end
	if hatchery and hatchery.Parent then return end
	local map = workspace:FindFirstChild("Map")
	if not map then return end
	local at, facing = spotFor(map)
	if not at then return end
	hatchery = build(at, facing)
	hatchery.Parent = map
	centre = at
end

--------------------------------------------------------------------
--  THE CLOCK
--------------------------------------------------------------------
local function set(plr, k, v) if plr:GetAttribute(k) ~= v then plr:SetAttribute(k, v) end end

local function nestsText(plr)
	local h = Pastimes.hatchery(plr)
	local now = os.time()
	local bits, eggs = {}, 0
	for i = 1, h.count do
		local n = h.nests[tostring(i)]
		bits[i] = n and string.format("%s,%d", n.egg, now + math.ceil(n.left)) or ""
	end
	for _, c in pairs(h.eggs) do eggs += c end
	return table.concat(bits, ";"), eggs
end

local PLAY_STEP = 15
local tick = 0
task.spawn(function()
	while true do
		task.wait(1)
		tick += 1
		ensureHatchery()
		local hub = inHub() and centre ~= nil and hatchery ~= nil and hatchery.Parent ~= nil
		for _, plr in ipairs(Players:GetPlayers()) do
			local ok, err = pcall(function()
				-- by the Hatchery: the eggs gain time
				local at = false
				if hub then
					local char = plr.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hrp and hum and hum.Health > 0 and (hrp.Position - centre).Magnitude <= (EGGS.radius or 20) then at = true end
				end
				if at then Pastimes.boost(plr, (EGGS.boost or 2) - 1) end
				set(plr, "AtHatchery", at)
				-- the playtime clock
				if tick % PLAY_STEP == 0 then Pastimes.addPlaytime(plr, PLAY_STEP) end
				local g = Pastimes.gifts(plr)
				set(plr, "PlaySeconds", g.seconds)
				local claimed = {}
				for k in pairs(g.claimed) do table.insert(claimed, k) end
				table.sort(claimed)
				set(plr, "GiftsClaimed", table.concat(claimed, ","))
				set(plr, "GiftDay", g.day)
				-- the nests and the companion
				if tick % 2 == 0 or at then
					local text, eggs = nestsText(plr)
					set(plr, "Nests", text)
					set(plr, "EggCount", eggs)
				end
				local p = Profile.get(plr)
				local comp = type(p.companion) == "string" and p.companion or ""
				if comp ~= "" and not Profile.has(plr, "companions", comp) then comp = "" end
				set(plr, "Companion", comp)
				set(plr, "CompanionStars", comp ~= "" and (p.stars and p.stars[comp] or 1) or 0)
			end)
			if not ok then warn("[Pastimes]", plr.Name, err) end
		end
	end
end)
