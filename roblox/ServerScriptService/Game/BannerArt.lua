--[[ BANNER ART — the arms of the two houses at war, painted on every banner of a map as it loads
     (MapLoader: the map, and the land round it, Game ▸ Horizon): each cloth (Banner, KeepBanner,
     HallBanner, WallBanner, PodiumBanner) gets its house's emblem on both faces, gold on a dark or
     bright cloth, dark on a pale one, with its outline and shadow. The blue banners of a map all
     share one house's arms and the red ones the other's (picked by the map's name, so a map always
     flies the same), a green or a gold or a black cloth its own. The pictures are the shields'
     (ReplicatedStorage ▸ ShieldArt; none there, nothing painted). The plates are named BannerArt so
     the wind swings them with their cloth (StarterPlayerScripts ▸ BannerWind).

       BannerArt.dress(container, seedName) ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BannerArt = {}
local CLOTH = {Banner = true, KeepBanner = true, HallBanner = true, WallBanner = true, PodiumBanner = true}
-- each kind of cloth's houses: what a cloth of that colour may fly
local HOUSES = {
	blue = {"eagle", "lion", "griffin", "fleur", "horse"},
	red = {"dragon", "wolf", "boar", "bear", "phoenix"},
	green = {"stag", "tree", "serpent", "knot"},
	gold = {"sun", "lion", "tower"},
	purple = {"fleur", "moon", "rose"},
	dark = {"raven", "tower", "moon", "swords"},
	pale = {"cross", "rose", "tower"},
}
local GILT = Color3.new(1.06, 0.84, 0.4)
local INK = Color3.fromRGB(28, 22, 20)

local function art(name)
	local f = ReplicatedStorage:FindFirstChild("ShieldArt")
	local v = f and f:FindFirstChild(name)
	return v and v.Value ~= "" and v.Value or nil
end

-- which house's colours a cloth is
local function kindOf(c)
	local h, s, v = c:ToHSV()
	if v < 0.22 then return "dark" end
	if s < 0.22 then return v > 0.7 and "pale" or "dark" end
	if h < 0.05 or h > 0.92 then return "red" end
	if h < 0.17 then return "gold" end
	if h < 0.45 then return "green" end
	if h < 0.72 then return "blue" end
	return "purple"
end

-- layers = {{texture, colour, transparency}, …} from the back (its shadow) to the front (itself)
local function plate(cloth, cf, side, layers)
	local p = Instance.new("Part")
	p.Name = "BannerArt"
	p.Size = Vector3.new(side, side, 0.01)
	p.CFrame = cf
	p.Transparency = 1
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for i, l in ipairs(layers) do
		local d = Instance.new("Decal")
		d.Face = Enum.NormalId.Front
		d.Texture = l[1]
		d.Color3 = l[2]
		d.Transparency = l[3] or 0
		d.ZIndex = i
		d.Parent = p
	end
	p.Parent = cloth.Parent
	return p
end

function BannerArt.dress(container, seedName)
	if not container or not ReplicatedStorage:FindFirstChild("ShieldArt") then return 0 end
	-- the houses of this map: one emblem per kind of cloth, the same every time it's played
	local r = Random.new(#(seedName or container.Name) * 7919 + 3)
	local pick = {}
	for kind, list in pairs(HOUSES) do pick[kind] = list[r:NextInteger(1, #list)] end
	-- (the blue houses' beasts and the red houses' never overlap, so the two sides never fly the same)
	local n = 0
	for _, cloth in ipairs(container:GetDescendants()) do
		if cloth:IsA("BasePart") and CLOTH[cloth.Name] and cloth.Transparency < 0.5 and not cloth:GetAttribute("BannerArt") then
			local cf, s = cloth.CFrame, cloth.Size
			-- its thin side is the cloth's thickness; of the other two, the one nearest upright is up
			local axes = {{cf.RightVector, s.X}, {cf.UpVector, s.Y}, {cf.LookVector, s.Z}}
			table.sort(axes, function(a, b) return a[2] < b[2] end)
			local thin, a1, a2 = axes[1], axes[2], axes[3]
			local upA, acrossA = a1, a2
			if math.abs(a2[1].Y) > math.abs(a1[1].Y) then upA, acrossA = a2, a1 end
			local up = upA[1].Y >= 0 and upA[1] or -upA[1]
			local w, h = acrossA[2], upA[2]
			local side = math.min(w, h) * 0.78
			local emblem = pick[kindOf(cloth.Color)]
			local tex = emblem and art(emblem)
			if side >= 1.2 and thin[2] < 1.5 and tex then
				local light = select(3, cloth.Color:ToHSV()) > 0.72 and select(2, cloth.Color:ToHSV()) < 0.35
				local color = light and INK or GILT
				local edge = light and Color3.fromRGB(200, 160, 70) or INK
				local layers = {}
				if art(emblem .. "_s") then table.insert(layers, {art(emblem .. "_s"), Color3.new(0, 0, 0), 0.25}) end
				if art(emblem .. "_o") then table.insert(layers, {art(emblem .. "_o"), edge}) end
				table.insert(layers, {tex, color})
				-- (a banner's arms sit a little high on it)
				local lift = (h - side) / 2 * 0.35
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = {cloth}
				for _, sgn in ipairs({1, -1}) do
					local nrm = thin[1] * sgn
					local back = -nrm
					local right = up:Cross(back)
					local pos = cf.Position + nrm * (thin[2] / 2 + 0.03) + up * lift
					-- (not the side that hangs flat against a wall)
					if not workspace:Raycast(pos - nrm * 0.02, nrm * 0.8, params) then
						plate(cloth, CFrame.fromMatrix(pos, right, up, back), side, layers)
					end
				end
				cloth:SetAttribute("BannerArt", emblem)
				n += 1
			end
		end
	end
	return n
end

return BannerArt
