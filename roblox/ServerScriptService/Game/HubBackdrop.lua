--[[ HUB BACKDROP — the world round the Courtyard's walls, built when the Hub starts (Game ▸ Modes ▸
     Hub) into workspace ▸ MapBackdrop, beside the map, not in it (the menu frames the map by its
     size: a world inside it would push the camera a mile out); the Hub clears it when it ends: grassland to the horizon with hills all round, the road
     out of the gate down through a village with a windmill and fields, woods, and on the far side a
     war camp with its trebuchets (the hub's client, HubAmbience.client, lobs their fire now and then
     far off: there's a war out there, and WAR on the Play screen).

       HubBackdrop.build(map)    once (workspace ▸ MapBackdrop says it's done)
       HubBackdrop.clear()
     Map attributes for the client: BD_Treb1/2 (the engines' arms), BD_Camp (the camp). ]]

local ServerScriptService = game:GetService("ServerScriptService")
local K = require(ServerScriptService:WaitForChild("Build"):WaitForChild("MapKit"))
if not K.campfire then require(ServerScriptService.Build:WaitForChild("MapProps"))(K) end
local WarProps = require(script.Parent:WaitForChild("WarProps"))

local HubBackdrop = {}
local V3, CF, DEG = Vector3.new, CFrame.new, math.rad
local M = Enum.Material
local GRASS = Color3.fromRGB(96, 146, 66)
local rnd = Random.new(11)

function HubBackdrop.build(map)
	if not map or workspace:FindFirstChild("MapBackdrop") then return end
	local ctx = K.new("Backdrop")
	-- the land: a plain under it all, a little below the courtyard's own ground
	K.box(ctx, "Land", V3(2000, 1, 2000), CF(0, -2.6, 0), GRASS, M.Grass)
	-- hills all round, half sunk
	for i = 1, 26 do
		local a = i / 26 * math.pi * 2 + rnd:NextNumber(0, 0.15)
		local r = rnd:NextNumber(520, 760)
		local d = rnd:NextNumber(220, 380)
		K.ball(ctx, "Hill", d, CF(math.cos(a) * r, -d * rnd:NextNumber(0.3, 0.42), math.sin(a) * r), Color3.fromRGB(84, 132, 60), M.Grass, ctx.Props)
	end
	-- the road south from the gate, the village along it, its fields and windmill
	K.box(ctx, "Road", V3(14, 0.4, 420), CF(0, -2, 300), Color3.fromRGB(132, 110, 82), M.Ground)
	for k = 1, 10 do
		local s = k % 2 == 0 and 1 or -1
		local z = 170 + math.floor((k - 1) / 2) * 40 + rnd:NextNumber(-6, 6)
		local x = s * rnd:NextNumber(26, 48)
		K.house(ctx, CF(x, -2.1, z) * CFrame.Angles(0, DEG(s > 0 and -90 or 90), 0), 12, 14, 8,
			Color3.fromRGB(226, 214, 190), (k % 3 == 0) and Color3.fromRGB(70, 74, 86) or Color3.fromRGB(150, 96, 56))
	end
	local mill = V3(-110, -2, 260)
	K.cyl(ctx, "MillBody", 12, 24, mill + V3(0, 12, 0), Color3.fromRGB(214, 204, 186), M.Concrete, ctx.Props)
	for k = 0, 3 do
		K.box(ctx, "MillSail", V3(1, 20, 4), CF(mill + V3(0, 22, 6.6)) * CFrame.Angles(0, 0, DEG(k * 90 + 15)) * CF(0, 10, 0), Color3.fromRGB(224, 216, 196), M.Fabric, ctx.Props)
	end
	for k = 1, 10 do
		local x = (k % 2 == 0 and 1 or -1) * rnd:NextNumber(80, 230)
		local z = rnd:NextNumber(160, 460)
		local gold = rnd:NextNumber(0, 1) < 0.5
		K.box(ctx, "Field", V3(rnd:NextNumber(50, 90), 0.4, rnd:NextNumber(50, 90)), CF(x, -2.1, z) * CFrame.Angles(0, rnd:NextNumber(-0.3, 0.3), 0),
			gold and Color3.fromRGB(206, 178, 92) or Color3.fromRGB(116, 160, 70), M.Grass)
	end
	-- woods to the west and north
	for _ = 1, 44 do
		local a = rnd:NextNumber(math.rad(100), math.rad(260))
		local r = rnd:NextNumber(200, 420)
		K.oak(ctx, V3(math.cos(a) * r, -2, math.sin(a) * r), rnd:NextNumber(12, 22))
	end
	-- THE WAR CAMP far off to the east: tents, red banners, fires, two trebuchets
	local camp = V3(470, -2, -60)
	for k = 1, 12 do
		local at = camp + V3(rnd:NextNumber(-60, 60), 0, rnd:NextNumber(-80, 80))
		K.tent(ctx, CF(at) * CFrame.Angles(0, rnd:NextNumber(0, 6.28), 0), 9, 11, 7, k % 3 == 0 and Color3.fromRGB(150, 40, 36) or Color3.fromRGB(200, 186, 160))
	end
	for k = 1, 6 do K.banner(ctx, camp + V3(-70, 0, -60 + k * 20), 16, Color3.fromRGB(176, 40, 36)) end
	for _ = 1, 4 do pcall(K.campfire, ctx, camp + V3(rnd:NextNumber(-50, 50), 0, rnd:NextNumber(-60, 60))) end
	local arms = {}
	for k, z in ipairs({-110, 20}) do
		local at = camp + V3(70, 0, z)
		local m = WarProps.place("Trebuchet", CFrame.lookAt(at, at + V3(1, 0, 0)), 26, ctx.Props)
		if not m then
			-- (the made trebuchet lives with the prologue's props: borrow it)
			local props = game:GetService("ServerStorage"):FindFirstChild("PrologueProps")
			local tpl = props and props:FindFirstChild("Trebuchet")
			if tpl then
				m = tpl:Clone()
				for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
				m.Parent = ctx.Props
				local cf, size = m:GetBoundingBox()
				m:PivotTo(CF(at + V3(0, size.Y / 2 - (cf.Position.Y - m:GetPivot().Position.Y), 0)) * CFrame.Angles(0, DEG(90), 0))
			end
		end
		arms[k] = at + V3(0, 24, 0)
		map:SetAttribute("BD_Treb" .. k, arms[k])
	end
	map:SetAttribute("BD_Camp", camp)
	ctx.model.Name = "MapBackdrop"
	ctx.model.Parent = workspace
end

function HubBackdrop.clear()
	local m = workspace:FindFirstChild("MapBackdrop")
	if m then m:Destroy() end
end

return HubBackdrop
