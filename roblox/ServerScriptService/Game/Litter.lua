--[[ LITTER — what earlier fighting leaves on a field, set down on whatever ground is there: dropped
     shields in both sides' colours, broken spears, clusters of arrows stuck in the ground leaning
     the way they came, fallen banners, helmets. Looks only (no collision, no queries, no touches).

       Litter.scatter(parent, sample, counts)
           sample()   -> a Vector3 (x, z where it goes; y is found by a ray down onto the ground),
                         or nil to skip one
           counts     {shields, spears, arrows (clusters), banners, helms} (any left out: none)

     War's fields have their own (Game ▸ WarMap ▸ debris); Siege uses this for the field before
     its castle (Game ▸ Modes ▸ Siege). ]]

local Litter = {}

local V3, CF, DEG = Vector3.new, CFrame.new, math.rad
local WOOD, DARK = Color3.fromRGB(96, 74, 52), Color3.fromRGB(62, 44, 30)
local SHIELD = {Color3.fromRGB(56, 92, 206), Color3.fromRGB(190, 50, 44), Color3.fromRGB(120, 92, 62)}

local function piece(parent, name, size, cf, color, mat, ball, cyl)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	if ball then p.Shape = Enum.PartType.Ball elseif cyl then p.Shape = Enum.PartType.Cylinder end
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Litter.scatter(parent, sample, counts)
	counts = counts or {}
	local folder = Instance.new("Folder")
	folder.Name = "Litter"
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = {folder, workspace:FindFirstChild("NPCs") or folder}
	local rng = Random.new()
	local function ground()
		local at = sample()
		if not at then return nil end
		local r = workspace:Raycast(V3(at.X, at.Y + 80, at.Z), V3(0, -200, 0), ray)
		-- (only open, level-ish ground: not a roof, a wall top, a cliff)
		if not r or r.Normal.Y < 0.85 then return nil end
		return r.Position
	end
	for _ = 1, counts.shields or 0 do
		local at = ground()
		if at then
			piece(folder, "DroppedShield", V3(0.3, rng:NextNumber(2.4, 3), rng:NextNumber(2.4, 3)), CF(at + V3(0, 0.12, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), DEG(90 + rng:NextNumber(-10, 10))),
				SHIELD[rng:NextInteger(1, #SHIELD)], Enum.Material.Wood, false, true)
		end
	end
	for _ = 1, counts.spears or 0 do
		local at = ground()
		if at then
			piece(folder, "BrokenSpear", V3(rng:NextNumber(3, 7), 0.25, 0.25), CF(at + V3(0, 0.15, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), DARK, Enum.Material.Wood, false, true)
		end
	end
	for _ = 1, counts.arrows or 0 do
		local at = ground()
		if at then
			local lean = CFrame.Angles(DEG(rng:NextNumber(20, 35)), rng:NextNumber(0, 6), 0)
			for _ = 1, rng:NextInteger(4, 9) do
				local p = at + V3(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
				local cf = CF(p) * lean * CF(0, 1.2, 0)
				piece(folder, "SpentArrow", V3(0.12, 2.6, 0.12), cf, WOOD, Enum.Material.Wood)
				piece(folder, "SpentFletch", V3(0.05, 0.6, 0.3), cf * CF(0, 1.1, 0), Color3.fromRGB(226, 220, 206), Enum.Material.SmoothPlastic)
			end
		end
	end
	for _ = 1, counts.banners or 0 do
		local at = ground()
		if at then
			piece(folder, "FallenBanner", V3(2.6, 0.1, 3.8), CF(at + V3(0, 0.06, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), SHIELD[rng:NextInteger(1, 2)], Enum.Material.Fabric)
		end
	end
	for _ = 1, counts.helms or 0 do
		local at = ground()
		if at then
			piece(folder, "DroppedHelm", V3(1.3, 1.3, 1.3), CF(at + V3(0, 0.4, 0)) * CFrame.Angles(rng:NextNumber(-1, 1), rng:NextNumber(0, 6), rng:NextNumber(-1, 1)), Color3.fromRGB(150, 152, 158), Enum.Material.Metal, true)
		end
	end
	folder.Parent = parent
	return folder
end

return Litter
