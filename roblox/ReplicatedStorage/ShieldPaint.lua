--[[ SHIELD PAINT — the painted face of a shield skin (Catalog ▸ ArsenalSkins): the field split
     in a second colour, a great emblem (a lion, a dragon, a tower…) with its outline and its
     shadow, the scratches of the fights it's been through, and the light falling across the
     board. Each layer is a picture (a Decal) on a clear plate just in front of the board, so it
     shows the same in the world and in a menu's ViewportFrame.

     The pictures live only in Studio: ReplicatedStorage ▸ ShieldArt holds a StringValue per
     picture (its image), named
       <emblem>  <emblem>_o (its outline)  <emblem>_s (its shadow)
       <shape>_<division>  <shape>_shade  <shape>_wear     (shape: round heater kite scutum rect)
     A picture that isn't there is just left off.

       ShieldPaint.apply(container, skin) -> bool     ShieldPaint.clear(container)
       ShieldPaint.house(container, emblem, color)    a plain shield in a team fight: its side's
                                                      colour on the board, its house's arms on it
                                                      (ReplicatedStorage ▸ Houses), battered
       ShieldPaint.arms(container, arms, teamColor)   a player's own arms (Catalog ▸ Arms) on a
                                                      plain shield; in a team fight on its side's colour
       ShieldPaint.armsOf(appearance) -> arms | nil   an appearance's arms, its colours looked up
       ShieldPaint.plain(container, appearance, teamKey)  what a plain shield wears: your arms, else
                                                      in a team fight your side's house's, else nothing

     A skin's fields (all optional):
       division      pale fess quarterly bend saltire chevron gyronny paly barry checky chief
                     bordure pile cross: the field split, the second part in divisionColor
       emblem        bear boar cross dragon eagle fleur griffin horse knot kraken lion moon
                     phoenix raven rose serpent skull stag sun swords thunderbolt tower tree wolf
       emblemColor   (else the heraldry colour, else the accent, else gold)
       emblemEdge    the outline's colour (false: none)    emblemGlow  how bright (1.1–1.3: it shines; more blooms it away)
       emblemSize    × the shape's usual size              emblemY     studs up from its usual spot
       emblemCount   2 or 3: that many, one above another (two lions, three leopards)
       keepBoss      keep the boss / spine / ridge an emblem would hide
       wear          0–1, how battered (else by rarity)    shade = false: no painted light ]]

local ShieldPaint = {}
local RS = game:GetService("ReplicatedStorage")
local ShieldDress = require(script.Parent:WaitForChild("ShieldDress"))
local TAG = "ShieldPaintPart"

-- the emblem's usual spot per shape: studs up from FaceY, and its size × the board's width
local SPOT = {round = {0, 0.64}, heater = {0.12, 0.74}, kite = {0.32, 0.76}, scutum = {0, 1.0}, rect = {0.15, 0.8}}
local WEAR = {Common = 0.55, Rare = 0.42, Epic = 0.28, Legendary = 0.14, Mythic = 0}
-- (the shield's own fittings in the middle of the board, hidden under an emblem)
local UNDER = {Boss = true, Spine = true, Ridge = true}
local SCRATCH = Color3.fromRGB(226, 212, 188)

local function art(name)
	local f = RS:FindFirstChild("ShieldArt")
	local v = f and f:FindFirstChild(name)
	return v and v.Value ~= "" and v.Value or nil
end

local function faceOf(container)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("ShieldFace") then return d end
	end
	return nil
end

local function scale(c, k) return Color3.new(c.R * k, c.G * k, c.B * k) end

function ShieldPaint.clear(container)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") then
			if d:GetAttribute(TAG) then d:Destroy()
			else
				if d:GetAttribute("PaintHidden") then
					d.Transparency = d:GetAttribute("PaintHidden")
					d:SetAttribute("PaintHidden", nil)
				end
				if d:GetAttribute("HouseColor") then
					d.Color = d:GetAttribute("HouseColor")
					d:SetAttribute("HouseColor", nil)
				end
			end
		end
	end
end

function ShieldPaint.apply(container, skin)
	ShieldPaint.clear(container)
	if not skin then return false end
	local face = faceOf(container)
	local handle = container:FindFirstChild("Handle", true)
	if not (face and handle) then return false end
	local W = face:GetAttribute("FaceW") or 2
	local Y = face:GetAttribute("FaceY") or 0
	local Z = face:GetAttribute("PaintZ") or face:GetAttribute("FaceZ") or -0.3
	local shape = face:GetAttribute("FaceShape") or (face:GetAttribute("FaceRound") and "round") or "rect"
	-- the outline's box (the pictures cover exactly that)
	local poly = ShieldDress.outline(shape)
	local x0, y0, x1, y1 = -W / 2, -W / 2, W / 2, W / 2
	if poly then
		x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
		for _, p in ipairs(poly) do
			x0, x1 = math.min(x0, p[1]), math.max(x1, p[1])
			y0, y1 = math.min(y0, p[2]), math.max(y1, p[2])
		end
	end
	local F = handle.CFrame * CFrame.new(0, Y, Z)
	local made = {}
	local function plate(cx, cy, w, h, z, name)
		local p = Instance.new("Part")
		p.Name = name or "Paint"
		p.Size = Vector3.new(w, h, 0.01)
		p.CFrame = F * CFrame.new(cx, cy, z)
		p.Transparency = 1
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.Anchored = true
		p:SetAttribute(TAG, true)
		table.insert(made, p)
		return p
	end
	local function decal(p, tex, color, transparency, z)
		if not tex then return nil end
		local d = Instance.new("Decal")
		d.Face = Enum.NormalId.Front
		d.Texture = tex
		d.Color3 = color
		d.Transparency = transparency or 0
		d.ZIndex = z
		d.Parent = p
		return d
	end

	-- THE FIELD: the division, the scratches, the light (one plate the size of the board)
	local wear = skin.wear or WEAR[skin.rarity] or 0.3
	local field = plate((x0 + x1) / 2, (y0 + y1) / 2, x1 - x0, y1 - y0, -0.012)
	local n = 0
	if skin.division and decal(field, art(shape .. "_" .. skin.division), skin.divisionColor or Color3.new(1, 1, 1), 0, 1) then n += 1 end
	-- (the scratches are always laid on, clear when it's new: a fight deepens them, Shields.batter)
	local wd = decal(field, art(shape .. "_wear"), SCRATCH, 1 - math.clamp(wear, 0, 1), 2)
	if wd then wd:SetAttribute("Wear", math.clamp(wear, 0, 1)); if wear > 0 then n += 1 end end
	if skin.shade ~= false and decal(field, art(shape .. "_shade"), Color3.new(1, 1, 1), 0, 3) then n += 1 end

	-- THE EMBLEM: its shadow, its outline, itself (in front of any raised arms)
	local em = skin.emblem
	if em and art(em) then
		local spot = SPOT[shape] or SPOT.rect
		local size = (skin.emblemSize or 1) * spot[2] * (x1 - x0)
		local h = skin.heraldry and skin.heraldry.color
		local color = skin.emblemColor or h or skin.accent or Color3.fromRGB(240, 200, 90)
		local glow = skin.emblemGlow
		local count = math.clamp(skin.emblemCount or 1, 1, 3)
		local each = count == 1 and size or size * (count == 2 and 0.6 or 0.44)
		for i = 1, count do
			local y = spot[1] + (skin.emblemY or 0) + ((count + 1) / 2 - i) * each * 1.02
			local ep = plate(0, y, each, each, skin.heraldry and -0.09 or -0.03, "Emblem")
			decal(ep, art(em .. "_s"), Color3.new(0, 0, 0), glow and 0.5 or 0.1, 1)
			if skin.emblemEdge ~= false then
				decal(ep, art(em .. "_o"), skin.emblemEdge or color:Lerp(Color3.new(0, 0, 0), 0.85), 0, 2)
			end
			decal(ep, art(em), glow and scale(color, glow) or color, 0, 3)
			if glow and i == math.ceil(count / 2) then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = color, 4, 0.35, false
				l.Parent = ep
			end
		end
		n += 1
		-- (the boss, a scutum's spine, a pavise's ridge would stand through it)
		local spiked = container:FindFirstChild("Spike", true) ~= nil
		if not skin.keepBoss and not spiked then
			for _, p in ipairs(container:GetDescendants()) do
				if p:IsA("BasePart") and UNDER[p.Name] and not p:GetAttribute(TAG) and p.Transparency < 1 then
					p:SetAttribute("PaintHidden", p.Transparency)
					p.Transparency = 1
				end
			end
		end
	end

	-- (fixed to the handle by its offset, the same on every machine; anchored on a menu model)
	for _, p in ipairs(made) do
		if not handle.Anchored then
			p.Anchored = false
			p.Massless = true
			local w = Instance.new("Weld")
			w.Part0, w.Part1 = handle, p
			w.C0 = handle.CFrame:ToObjectSpace(p.CFrame)
			w.Parent = p
		end
		p.Parent = face.Parent
	end
	return n > 0
end

-- (the board painted: its first colour kept, for ShieldPaint.clear to put back)
local function tintBoard(container, color)
	for _, p in ipairs(container:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("SkinPart") == "Blade" and not p:GetAttribute(TAG) then
			if p:GetAttribute("HouseColor") == nil then p:SetAttribute("HouseColor", p.Color) end
			p.Color = color:Lerp(Color3.new(0, 0, 0), 0.15)
		end
	end
end

function ShieldPaint.house(container, emblem, color)
	local ok = ShieldPaint.apply(container, {name = "House", rarity = "Rare", emblem = emblem,
		emblemColor = Color3.new(1.06, 0.84, 0.4), emblemEdge = Color3.fromRGB(26, 20, 18), wear = 0.5})
	tintBoard(container, color)
	return ok
end

function ShieldPaint.armsOf(app)
	if type(app) ~= "table" or type(app.armsEmblem) ~= "string" then return nil end
	local Catalog = require(RS:WaitForChild("Catalog"))
	local A = Catalog.ARMS
	if not (A and A.EMBLEM[app.armsEmblem]) then return nil end
	local metal = A.METAL[app.armsMetal or ""] or A.METALS[1]
	local field = Catalog.COLOR[app.armsField or ""]
	local c2 = Catalog.COLOR[app.armsColor2 or ""]
	return {emblem = app.armsEmblem, metal = metal.color, edge = metal.edge, field = field and field.color,
		division = A.DIVISION[app.armsDivision or ""] and app.armsDivision or nil, color2 = c2 and c2.color}
end

function ShieldPaint.arms(container, a, teamColor)
	local ok = ShieldPaint.apply(container, {name = "Arms", rarity = "Rare", emblem = a.emblem, emblemColor = a.metal, emblemEdge = a.edge,
		division = (not teamColor) and a.division or nil, divisionColor = a.color2 or Color3.fromRGB(240, 240, 236), wear = 0.35})
	local field = teamColor or a.field
	if field then tintBoard(container, field) end
	return ok
end

function ShieldPaint.plain(container, app, teamKey)
	local teamColor
	if teamKey == "A" or teamKey == "B" then
		local ok, GameConfig = pcall(require, RS:WaitForChild("GameConfig"))
		teamColor = ok and GameConfig.TEAMS[teamKey] and GameConfig.TEAMS[teamKey].rgb or nil
	end
	local a = ShieldPaint.armsOf(app)
	if a then return ShieldPaint.arms(container, a, teamColor) end
	if teamColor then
		local map = workspace:FindFirstChild("Map")
		local emblem = require(RS:WaitForChild("Houses")).forTeam(teamKey, map and map:GetAttribute("HouseSeed"))
		if emblem then return ShieldPaint.house(container, emblem, teamColor) end
	end
	return false
end

return ShieldPaint
