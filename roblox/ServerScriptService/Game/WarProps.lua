--[[ WAR PROPS — the made battlefield props (ServerStorage ▸ WarProps, Studio-only, generated models):
     Pavilion, SiegeTower, Ballista, Barricade. War's battlefields (Game ▸ WarMap) and Siege's war
     round its castle (Game ▸ Modes ▸ Siege) set them down.

       WarProps.place(name, cf, height, parent, collide) -> Model | nil
           `height` studs tall, its lowest point on cf's height, facing cf's look turned by the
           template's own Yaw attribute (degrees: how its mesh was made); anchored; nil when
           there's no such prop (the place simply goes without) ]]

local ServerStorage = game:GetService("ServerStorage")

local WarProps = {}

function WarProps.place(name, cf, height, parent, collide)
	local f = ServerStorage:FindFirstChild("WarProps")
	local tpl = f and f:FindFirstChild(name)
	if not tpl then return nil end
	local m = tpl:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = collide ~= false end
	end
	local _, size = m:GetBoundingBox()
	if size.Y > 0 and height then pcall(function() m:ScaleTo(m:GetScale() * height / size.Y) end) end
	m.Parent = parent
	local yaw = math.rad(tpl:GetAttribute("Yaw") or 0)
	m:PivotTo(cf * CFrame.Angles(0, yaw, 0))
	-- (its lowest point onto the ground)
	local bcf, bsize = m:GetBoundingBox()
	local bottom = bcf.Position.Y - bsize.Y / 2
	m:PivotTo(m:GetPivot() + Vector3.new(0, cf.Position.Y - bottom, 0))
	return m
end

return WarProps
