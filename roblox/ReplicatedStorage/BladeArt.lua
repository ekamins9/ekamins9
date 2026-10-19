--[[ BLADE ART — a weapon skin's etching: a picture laid down the flat of the blade, on both
     sides (runes, flames, frost, filigree, a winding dragon, a laurel vine, waves, thunder).
     Which one comes from the skin's trim (ETCH below), or its own `etch`; plain trims get a
     maker's runes at Rare and gold filigree from Epic, Common blades stay plain. Magic trims
     glow in the skin's glow colour; the rest are inlaid in its accent (gold from Epic), or
     etched dark into the steel below that.

     The pictures live only in Studio, like the shields' (ReplicatedStorage ▸ SkinArt: a
     StringValue per picture, its image, named etch_<name>); a picture that isn't there is left
     off. Only long blades are etched (a sword's, a dagger's, a spear's head: longer than 3×
     their width), never a bow.

       BladeArt.apply(tool, skin) -> bool     BladeArt.clear(tool)
       BladeArt.ETCH                          trim → picture ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BladeArt = {}
local TAG = "BladeArt"

BladeArt.ETCH = {
	runes = "runes", runic = "runes", void = "runes", skull = "runes", bone = "runes",
	flame = "flames", ember = "flames", blood = "flames",
	frost = "frost", crystal = "frost",
	thunder = "thunder", storm = "thunder",
	serpent = "serpent", venom = "serpent", dragon = "serpent",
	wave = "waves",
	laurel = "vines", feather = "vines", wing = "vines", thorn = "vines",
	royal = "filigree", crown = "filigree", halo = "filigree", gilded = "filigree",
}
-- (the ones that glow, in the skin's glow colour)
local GLOWS = {runes = true, flames = true, frost = true, thunder = true}
local RANK = {Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Unique = 6}
local GOLD = Color3.fromRGB(232, 184, 74)
local ETCHED = Color3.fromRGB(46, 48, 54)

local function art(name)
	local f = ReplicatedStorage:FindFirstChild("SkinArt")
	local v = f and f:FindFirstChild("etch_" .. name)
	return v and v.Value ~= "" and v.Value or nil
end
local function scale(c, k) return Color3.new(c.R * k, c.G * k, c.B * k) end

function BladeArt.clear(tool)
	for _, d in ipairs(tool:GetDescendants()) do
		if (d:IsA("Decal") or d:IsA("BasePart")) and d:GetAttribute(TAG) then d:Destroy() end
	end
end

-- which picture, and in what colour
local function pick(skin)
	local rank = RANK[skin.rarity or "Common"] or 1
	local name = skin.etch or BladeArt.ETCH[skin.trim or ""] or BladeArt.ETCH[skin.trim2 or ""]
	if not name then
		if rank >= 3 then name = "filigree" elseif rank == 2 then name = "runes" else return nil end
		-- (a plain trim's mark: never glowing)
		return name, rank >= 3 and (skin.accent or GOLD) or ETCHED, 0.08
	end
	if GLOWS[name] and skin.glow then return name, scale(skin.glow, 1.7), 0.05 end
	if GLOWS[name] then return name, rank >= 3 and scale(GOLD, 1.3) or ETCHED, 0.1 end
	return name, (skin.accent or (rank >= 3 and GOLD or ETCHED)), 0.02
end

-- THE BLADE to etch: the skin model's own (when it has one), else the weapon's; its longest
-- part that's long along its own Y and thin through X or Z (the flats face that way)
local function blade(tool)
	local model = tool:FindFirstChild("Skin")
	local best, faces, bestLen = nil, nil, 0
	local function scan(root, needTag)
		for _, p in ipairs(root:GetDescendants()) do
			if p:IsA("BasePart") and p.Transparency < 0.9 and (not needTag or p:GetAttribute("SkinPart") == "Blade") then
				local s = p.Size
				local thin, wide = math.min(s.X, s.Z), math.max(s.X, s.Z)
				if s.Y >= 3 * wide and s.Y > 0.6 and thin <= wide * 0.75 and s.Y > bestLen then
					best, bestLen = p, s.Y
					faces = s.Z <= s.X and {Enum.NormalId.Front, Enum.NormalId.Back} or {Enum.NormalId.Left, Enum.NormalId.Right}
				end
			end
		end
	end
	if model and model:IsA("Model") then
		scan(model, true)
		if not best then scan(model, false) end
		-- (a skin model all in one mesh, guard and grip and all: the etching goes on a clear plate
		-- where the weapon's own blade is, a little inside its edges)
		if not best then
			local src
			for _, p in ipairs(tool:GetDescendants()) do
				if p:IsA("BasePart") and p:GetAttribute("SkinPart") == "Blade" and not p:IsDescendantOf(model) then src = p end
			end
			local s = src and src.Size
			if s and s.Y >= 3 * math.max(s.X, s.Z) then
				local plate = Instance.new("Part")
				plate.Name = "EtchPlate"
				plate.Transparency = 1
				plate.CanCollide, plate.CanQuery, plate.CanTouch, plate.CastShadow, plate.Massless = false, false, false, false, true
				local flatZ = s.Z <= s.X
				plate.Size = flatZ and Vector3.new(s.X * 0.6, s.Y * 0.9, s.Z + 0.05) or Vector3.new(s.X + 0.05, s.Y * 0.9, s.Z * 0.6)
				plate.CFrame = src.CFrame * CFrame.new(0, s.Y * 0.03, 0)
				plate:SetAttribute(TAG, true)
				if src.Anchored then plate.Anchored = true
				else
					local w = Instance.new("Weld"); w.Part0, w.Part1, w.C0 = src, plate, src.CFrame:ToObjectSpace(plate.CFrame); w.Parent = plate
				end
				plate.Parent = src.Parent
				best = plate
				faces = flatZ and {Enum.NormalId.Front, Enum.NormalId.Back} or {Enum.NormalId.Left, Enum.NormalId.Right}
			end
		end
	else
		scan(tool, true)
	end
	return best, faces
end

function BladeArt.apply(tool, skin)
	BladeArt.clear(tool)
	if not (tool and skin) then return false end
	local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
	local w = Catalog.WEAPON[skin.weapon or ""]
	if w and (w.ranged or w.shield) then return false end
	local name, color, tr = pick(skin)
	local tex = name and art(name)
	if not tex then return false end
	local p, faces = blade(tool)
	if not p then return false end
	for _, face in ipairs(faces) do
		local d = Instance.new("Decal")
		d.Face = face
		d.Texture = tex
		d.Color3 = color
		d.Transparency = tr
		d.ZIndex = 2
		d:SetAttribute(TAG, true)
		d.Parent = p
	end
	return true
end

return BladeArt
