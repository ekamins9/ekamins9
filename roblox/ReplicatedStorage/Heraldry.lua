--[[ HERALDRY — paints a shield skin's arms on a shield (Catalog ▸ ArsenalSkins heraldry =
     {pattern, color}). The shield's board carries ShieldFace with its size and where its front
     is in the Handle's frame (FaceW, FaceH, FaceY, FaceZ, FaceRound: Build ▸ ArsenalBlueprints);
     the charges are thin parts just in front of it, welded (or anchored, on an anchored menu
     model). Dresser.applySkin calls it; a new skin clears the old arms first.

       Heraldry.apply(container, skin) -> bool     Heraldry.clear(container)
     patterns: cross saltire chevron pale fess bend quarterly bordure chief sun star lion tower ]]

local Heraldry = {}
local DEPTH = 0.07     -- (raised off the board: embossed, not painted)
local EDGE = 0.07      -- the dark outline round each charge, behind it
local TAG = "HeraldryPart"

function Heraldry.clear(container)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute(TAG) then d:Destroy() end
	end
end

local function faceOf(container)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("ShieldFace") then return d end
	end
	return nil
end

function Heraldry.apply(container, skin)
	Heraldry.clear(container)
	local h = skin and skin.heraldry
	if not h then return false end
	local face = faceOf(container)
	local handle = container:FindFirstChild("Handle")
	if not (face and handle) then return false end
	local W, H = face:GetAttribute("FaceW") or 2, face:GetAttribute("FaceH") or 2
	local Y, Z = face:GetAttribute("FaceY") or 0, (face:GetAttribute("FaceZ") or -0.3) - 0.025
	local round = face:GetAttribute("FaceRound") == true
	local frame = handle.CFrame * CFrame.new(0, Y, Z)
	local color = h.color or Color3.new(1, 1, 1)
	-- (gold-ish charges on the good ones are gold leaf; the rest enamel)
	local rich = skin.rarity == "Epic" or skin.rarity == "Legendary" or skin.rarity == "Mythic"
	local goldish = color.R > 0.7 and color.G > 0.55 and color.B < 0.5
	local mat = (rich and goldish) and Enum.Material.Foil or (rich and Enum.Material.Metal or Enum.Material.SmoothPlastic)
	local edgeColor = h.outline or color:Lerp(Color3.new(0, 0, 0), 0.7)
	local n = 0
	local made = {}
	-- a bar of w × l centred at (x, y) on the board, turned `rot` degrees
	local function piece(size, cf, col, m)
		local p = Instance.new("Part")
		p.Name = "Arms"
		p.Size = size
		p.CFrame = cf
		p.Color, p.Material = col, m
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p:SetAttribute(TAG, true)
		p.Anchored = true
		table.insert(made, p)
		return p
	end
	-- a bar of w × l centred at (x, y) on the board, turned `rot` degrees, with its outline behind
	local function bar(x, y, w, l, rot)
		local cf = frame * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, math.rad(rot or 0))
		piece(Vector3.new(w + EDGE, l + EDGE, DEPTH * 0.6), cf * CFrame.new(0, 0, 0.012), edgeColor, Enum.Material.SmoothPlastic)
		n += 1
		return piece(Vector3.new(w, l, DEPTH), cf * CFrame.new(0, 0, -0.01), color, mat)
	end
	-- a disc of diameter d at (x, y)
	local function disc(x, y, d)
		local cf = frame * CFrame.new(x, y, 0) * CFrame.Angles(0, math.rad(90), 0)
		local back = piece(Vector3.new(DEPTH * 0.6, d + EDGE, d + EDGE), cf * CFrame.new(-0.012, 0, 0), edgeColor, Enum.Material.SmoothPlastic)
		back.Shape = Enum.PartType.Cylinder
		n += 1
		local p = piece(Vector3.new(DEPTH, d, d), cf * CFrame.new(0.01, 0, 0), color, mat)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	local m = math.min(W, H)
	local pat = h.pattern
	if pat == "cross" then
		bar(0, H * 0.04, W * 0.16, H * 0.92)
		bar(0, H * 0.12, W * 0.92, W * 0.16)
	elseif pat == "saltire" then
		bar(0, 0, m * 0.15, m * 1.05, 45)
		bar(0, 0, m * 0.15, m * 1.05, -45)
	elseif pat == "chevron" then
		bar(-W * 0.2, -H * 0.02, W * 0.16, W * 0.62, -42)
		bar(W * 0.2, -H * 0.02, W * 0.16, W * 0.62, 42)
	elseif pat == "pale" then
		bar(0, 0, W * 0.3, H * (round and 0.95 or 0.98))
	elseif pat == "fess" then
		bar(0, H * 0.08, W * (round and 0.95 or 0.98), H * 0.26)
	elseif pat == "bend" then
		bar(0, 0, m * 0.24, m * 1.1, -45)
	elseif pat == "quarterly" then
		bar(-W * 0.22, H * 0.22, W * 0.44, H * 0.44)
		bar(W * 0.22, -H * 0.22, W * 0.44, H * 0.44)
	elseif pat == "bordure" then
		if round then
			for k = 0, 15 do
				local a = k / 16 * math.pi * 2
				bar(math.cos(a) * W * 0.44, math.sin(a) * W * 0.44, W * 0.1, W * 0.2, math.deg(a))
			end
		else
			bar(0, H * 0.45, W * 0.96, H * 0.06); bar(-W * 0.46, H * 0.05, W * 0.06, H * 0.8); bar(W * 0.46, H * 0.05, W * 0.06, H * 0.8)
		end
	elseif pat == "chief" then
		bar(0, H * 0.38, W * 0.96, H * 0.22)
	elseif pat == "sun" then
		disc(0, 0, m * 0.34)
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			bar(math.cos(a) * m * 0.3, math.sin(a) * m * 0.3, m * 0.05, m * (k % 2 == 0 and 0.2 or 0.13), math.deg(a) - 90)
		end
	elseif pat == "star" then
		disc(0, 0, m * 0.14)
		for k = 0, 4 do bar(0, 0, m * 0.07, m * 0.62, k * 36) end
	elseif pat == "lion" then
		-- a crowned beast's head: the mane, the face, the crown
		disc(0, -m * 0.02, m * 0.46)
		bar(0, -m * 0.04, m * 0.18, m * 0.2)
		bar(0, m * 0.25, m * 0.32, m * 0.05)
		for _, x in ipairs({-0.12, 0, 0.12}) do bar(x * m, m * 0.31, m * 0.05, m * 0.1, x == 0 and 0 or (x < 0 and 12 or -12)) end
	elseif pat == "tower" then
		bar(0, -H * 0.05, W * 0.34, H * 0.5)
		for _, x in ipairs({-1, 0, 1}) do bar(x * W * 0.12, H * 0.24, W * 0.08, H * 0.08) end
	end
	-- (welded only once every piece is where it goes: a weld keeps whatever offset it finds)
	for _, p in ipairs(made) do
		if not handle.Anchored then
			p.Anchored = false
			p.Massless = true
			local w2 = Instance.new("WeldConstraint"); w2.Part0, w2.Part1 = handle, p; w2.Parent = p
		end
		p.Parent = face.Parent
	end
	return n > 0
end

return Heraldry
