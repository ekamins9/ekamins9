--[[ BANNER ART — the arms of the two houses at war, painted on every banner of a map as it loads
     (MapLoader: the map, and the land round it, Game ▸ Horizon): each cloth (Banner, KeepBanner,
     HallBanner, WallBanner, PodiumBanner) gets its house's emblem on both faces, gold on a dark or
     bright cloth, dark on a pale one, with its outline and shadow; not on a side hanging against a
     wall. Which house flies which colour on a map is ReplicatedStorage ▸ Houses (the blue banners
     all share one house's arms, the red the other's; the sides' plain shields carry the same:
     ShieldPaint.house). The pictures are the shields' (ReplicatedStorage ▸ ShieldArt; none there,
     nothing painted). The plates are the cloth's children, named BannerArt, so the wind swings them
     with it (StarterPlayerScripts ▸ BannerWind).

       BannerArt.dress(container, seedName)          every cloth in it, its house's arms
       BannerArt.fly(cloth, arms, name, seedName)    one cloth: a player's arms (ShieldPaint.armsOf:
                                                     emblem, metal, edge, field) with their name
                                                     embroidered under them; arms nil: the house's
                                                     again (the Courtyard's Hall of Arms: Modes ▸ Hub) ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BannerArt = {}
local Houses = require(ReplicatedStorage:WaitForChild("Houses"))
local CLOTH = {Banner = true, KeepBanner = true, HallBanner = true, WallBanner = true, PodiumBanner = true}
local GILT = Color3.new(1.06, 0.84, 0.4)
local INK = Color3.fromRGB(28, 22, 20)

local function art(name)
	local f = ReplicatedStorage:FindFirstChild("ShieldArt")
	local v = f and f:FindFirstChild(name)
	return v and v.Value ~= "" and v.Value or nil
end

local function plateAt(cloth, cf, w, h)
	local p = Instance.new("Part")
	p.Name = "BannerArt"
	p.Size = Vector3.new(w, h, 0.01)
	p.CFrame = cf
	p.Transparency = 1
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = true, false, false, false, false, true
	return p
end

-- the cloth's faces: its thin side is its thickness; of the other two, the one nearest upright is up
local function frameOf(cloth)
	local cf, s = cloth.CFrame, cloth.Size
	local axes = {{cf.RightVector, s.X}, {cf.UpVector, s.Y}, {cf.LookVector, s.Z}}
	table.sort(axes, function(a, b) return a[2] < b[2] end)
	local thin, a1, a2 = axes[1], axes[2], axes[3]
	local upA, acrossA = a1, a2
	if math.abs(a2[1].Y) > math.abs(a1[1].Y) then upA, acrossA = a2, a1 end
	local up = upA[1].Y >= 0 and upA[1] or -upA[1]
	return thin, up, acrossA[2], upA[2]
end

-- paint one cloth: o = {emblem, color, edge, label}; the old plates go first
local function paintCloth(cloth, o)
	for _, c in ipairs(cloth:GetChildren()) do if c.Name == "BannerArt" then c:Destroy() end end
	local tex = o.emblem and art(o.emblem)
	if not tex then return false end
	local thin, up, w, h = frameOf(cloth)
	local side = math.min(w, h) * 0.78
	if side < 1.2 or thin[2] >= 1.5 then return false end
	local layers = {}
	if art(o.emblem .. "_s") then table.insert(layers, {art(o.emblem .. "_s"), Color3.new(0, 0, 0), 0.25}) end
	if art(o.emblem .. "_o") then table.insert(layers, {art(o.emblem .. "_o"), o.edge}) end
	table.insert(layers, {tex, o.color})
	-- (a banner's arms sit a little high on it; a name under them)
	local lift = (h - side) / 2 * (o.label and 0.55 or 0.35)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {cloth}
	local cf = cloth.CFrame
	for _, sgn in ipairs({1, -1}) do
		local nrm = thin[1] * sgn
		local back = -nrm
		local right = up:Cross(back)
		local pos = cf.Position + nrm * (thin[2] / 2 + 0.03) + up * lift
		-- (not the side that hangs flat against a wall)
		if not workspace:Raycast(pos - nrm * 0.02, nrm * 2, params) then
			local p = plateAt(cloth, CFrame.fromMatrix(pos, right, up, back), side, side)
			for i, l in ipairs(layers) do
				local d = Instance.new("Decal")
				d.Face = Enum.NormalId.Front
				d.Texture = l[1]
				d.Color3 = l[2]
				d.Transparency = l[3] or 0
				d.ZIndex = i
				d.Parent = p
			end
			p.Parent = cloth
			if o.label then
				-- the name, stitched under the arms
				local lh = side * 0.26
				local lp = plateAt(cloth, CFrame.fromMatrix(pos - up * (side / 2 + lh * 0.75), right, up, back), w * 0.92, lh)
				local sg = Instance.new("SurfaceGui")
				sg.Face = Enum.NormalId.Front
				sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				sg.PixelsPerStud = 60
				sg.LightInfluence = 1
				local t = Instance.new("TextLabel")
				t.BackgroundTransparency = 1
				t.Size = UDim2.fromScale(1, 1)
				t.Font = Enum.Font.Fantasy
				t.TextScaled = true
				t.TextColor3 = o.color.R > 1 and Color3.fromRGB(240, 200, 100) or o.color
				t.Text = string.upper(o.label)
				local st = Instance.new("UIStroke"); st.Color = o.edge; st.Thickness = 1.5; st.Parent = t
				t.Parent = sg
				sg.Parent = lp
				lp.Parent = cloth
			end
		end
	end
	cloth:SetAttribute("BannerArt", o.emblem)
	return true
end

-- the house's arms for this cloth's colour, gold on dark or bright, dark on pale
local function houseLook(color, mapName)
	local _, s, v = color:ToHSV()
	local light = v > 0.72 and s < 0.35
	return {emblem = Houses.forColor(color, mapName), color = light and INK or GILT, edge = light and Color3.fromRGB(200, 160, 70) or INK}
end

function BannerArt.dress(container, seedName)
	if not container or not ReplicatedStorage:FindFirstChild("ShieldArt") then return 0 end
	local mapName = seedName or container.Name
	local n = 0
	for _, cloth in ipairs(container:GetDescendants()) do
		if cloth:IsA("BasePart") and CLOTH[cloth.Name] and cloth.Transparency < 0.5 and not cloth:GetAttribute("BannerArt") then
			if paintCloth(cloth, houseLook(cloth.Color, mapName)) then n += 1 end
		end
	end
	return n
end

function BannerArt.fly(cloth, arms, name, seedName)
	if not cloth or not ReplicatedStorage:FindFirstChild("ShieldArt") then return false end
	if cloth:GetAttribute("HouseCloth") == nil then cloth:SetAttribute("HouseCloth", cloth.Color) end
	local house = cloth:GetAttribute("HouseCloth")
	local color = arms and arms.field or house
	cloth.Color = color
	-- (its swallowtail tips, hung off its foot, take the colour too)
	for _, p in ipairs(cloth.Parent and cloth.Parent:GetChildren() or {}) do
		if p:IsA("BasePart") and p.Name == "BannerTip" and (p.Position - cloth.Position).Magnitude < cloth.Size.Y * 0.75 + 1 then p.Color = color end
	end
	if arms then return paintCloth(cloth, {emblem = arms.emblem, color = arms.metal, edge = arms.edge, label = name}) end
	return paintCloth(cloth, houseLook(house, seedName))
end

return BannerArt
