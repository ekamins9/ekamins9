--[[ SKIN FX — the third layer of a weapon skin, after the colours and the
     trim: a swing TRAIL and an AURA of particles around the blade.
       • Epic and Legendary skins leave a trail when the weapon moves (its
         colour is the skin's glow, else its accent, else the rarity colour);
         a skin can opt out with trail = false or in with trail = true.
       • A skin with fx = "<aura>" sheds that aura: embers frost holy shadow
         storm toxic petals gold blood (Legendary skins have one each).
     World-only: trails and particles don't render inside ViewportFrames, so
     the menu names them instead (SkinFX.describe).

       SkinFX.apply(tool, skin)   (re)builds the Handle's "SkinFX" folder
       SkinFX.clear(tool)
       SkinFX.describe(skin)      "Trail · Embers" (or nil)
       SkinFX.AURAS               every aura name ]]

local SkinTrims = require(script.Parent:WaitForChild("SkinTrims"))

local SkinFX = {}

local TEX = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
}
local RARITY = {Common = Color3.fromRGB(150, 160, 175), Rare = Color3.fromRGB(70, 150, 255), Epic = Color3.fromRGB(180, 90, 255), Legendary = Color3.fromRGB(255, 186, 60)}

local function seq(a, b) return ColorSequence.new(a, b or a) end
local function nseq(points)
	local kp = {}
	for _, p in ipairs(points) do table.insert(kp, NumberSequenceKeypoint.new(p[1], p[2])) end
	return NumberSequence.new(kp)
end

-- an aura is one or two emitters: {texture, color(s), size, rate, life, speed, accel, spread, light, transparency, rot}
local AURAS = {
	embers = {
		{tex = TEX.spark, c0 = Color3.fromRGB(255, 200, 80), c1 = Color3.fromRGB(255, 70, 20), size = {{0, 0.16}, {1, 0}}, rate = 14, life = {0.6, 1.2}, speed = {0.4, 1.4}, accel = Vector3.new(0, 4, 0), spread = 60, light = 1},
		{tex = TEX.fire, c0 = Color3.fromRGB(255, 140, 40), c1 = Color3.fromRGB(200, 40, 10), size = {{0, 0.35}, {1, 0.05}}, rate = 6, life = {0.25, 0.45}, speed = {0.2, 0.6}, accel = Vector3.new(0, 3, 0), spread = 20, light = 1, transp = {{0, 0.4}, {1, 1}}},
	},
	frost = {
		{tex = TEX.spark, c0 = Color3.fromRGB(230, 248, 255), c1 = Color3.fromRGB(150, 210, 255), size = {{0, 0.14}, {1, 0.02}}, rate = 10, life = {0.8, 1.6}, speed = {0.1, 0.5}, accel = Vector3.new(0, -1.2, 0), spread = 180, light = 0.8, rot = 60},
		{tex = TEX.smoke, c0 = Color3.fromRGB(200, 235, 255), size = {{0, 0.3}, {1, 0.8}}, rate = 3, life = {0.8, 1.2}, speed = {0.05, 0.2}, accel = Vector3.new(0, -0.3, 0), spread = 180, light = 0.2, transp = {{0, 0.75}, {1, 1}}},
	},
	holy = {
		{tex = TEX.spark, c0 = Color3.fromRGB(255, 250, 220), c1 = Color3.fromRGB(255, 210, 110), size = {{0, 0.2}, {0.5, 0.12}, {1, 0}}, rate = 10, life = {0.9, 1.5}, speed = {0.2, 0.6}, accel = Vector3.new(0, 1.5, 0), spread = 180, light = 1},
	},
	shadow = {
		{tex = TEX.smoke, c0 = Color3.fromRGB(40, 20, 60), c1 = Color3.fromRGB(10, 5, 20), size = {{0, 0.25}, {1, 0.7}}, rate = 9, life = {0.7, 1.2}, speed = {0.1, 0.4}, accel = Vector3.new(0, 0.8, 0), spread = 180, light = 0, transp = {{0, 0.45}, {1, 1}}},
		{tex = TEX.spark, c0 = Color3.fromRGB(170, 90, 255), size = {{0, 0.1}, {1, 0}}, rate = 6, life = {0.5, 0.9}, speed = {0.2, 0.6}, accel = Vector3.new(0, 1, 0), spread = 180, light = 1},
	},
	storm = {
		{tex = TEX.spark, c0 = Color3.fromRGB(220, 245, 255), c1 = Color3.fromRGB(90, 170, 255), size = {{0, 0.22}, {1, 0}}, rate = 20, life = {0.08, 0.2}, speed = {3, 6}, accel = Vector3.zero, spread = 180, light = 1, drag = 6},
	},
	toxic = {
		{tex = TEX.spark, c0 = Color3.fromRGB(170, 255, 120), c1 = Color3.fromRGB(60, 200, 60), size = {{0, 0.15}, {1, 0.02}}, rate = 10, life = {0.7, 1.2}, speed = {0.2, 0.6}, accel = Vector3.new(0, 1.5, 0), spread = 180, light = 0.9},
		{tex = TEX.smoke, c0 = Color3.fromRGB(90, 200, 70), size = {{0, 0.2}, {1, 0.6}}, rate = 3, life = {0.6, 1}, speed = {0.1, 0.3}, accel = Vector3.new(0, 0.6, 0), spread = 180, light = 0.3, transp = {{0, 0.7}, {1, 1}}},
	},
	petals = {
		{tex = TEX.spark, c0 = Color3.fromRGB(255, 160, 200), c1 = Color3.fromRGB(230, 60, 110), size = {{0, 0.18}, {1, 0.1}}, rate = 7, life = {1.2, 2}, speed = {0.3, 0.8}, accel = Vector3.new(0, -0.8, 0), spread = 180, light = 0.4, rot = 120},
	},
	gold = {
		{tex = TEX.spark, c0 = Color3.fromRGB(255, 230, 140), c1 = Color3.fromRGB(230, 170, 40), size = {{0, 0.16}, {1, 0}}, rate = 9, life = {0.6, 1.1}, speed = {0.2, 0.7}, accel = Vector3.new(0, 0.6, 0), spread = 180, light = 1},
	},
	blood = {
		{tex = TEX.smoke, c0 = Color3.fromRGB(140, 10, 20), c1 = Color3.fromRGB(60, 0, 8), size = {{0, 0.2}, {1, 0.5}}, rate = 6, life = {0.6, 1}, speed = {0.05, 0.3}, accel = Vector3.new(0, -1, 0), spread = 180, light = 0, transp = {{0, 0.5}, {1, 1}}},
		{tex = TEX.spark, c0 = Color3.fromRGB(255, 60, 60), size = {{0, 0.1}, {1, 0}}, rate = 5, life = {0.4, 0.8}, speed = {0.2, 0.5}, accel = Vector3.new(0, -2, 0), spread = 180, light = 1},
	},
}
SkinFX.AURAS = {}
for k in pairs(AURAS) do table.insert(SkinFX.AURAS, k) end
table.sort(SkinFX.AURAS)

local NAME = {embers = "Embers", frost = "Frost", holy = "Holy light", shadow = "Shadow", storm = "Storm", toxic = "Venom", petals = "Petals", gold = "Gold dust", blood = "Blood mist"}

local function wantsTrail(skin)
	if skin.trail ~= nil then return skin.trail == true end
	return skin.rarity == "Epic" or skin.rarity == "Legendary"
end

function SkinFX.describe(skin)
	if not skin then return nil end
	local bits = {}
	if wantsTrail(skin) then table.insert(bits, "Trail") end
	if skin.fx and NAME[skin.fx] then table.insert(bits, NAME[skin.fx]) end
	return #bits > 0 and table.concat(bits, " · ") or nil
end

function SkinFX.clear(tool)
	local h = tool:FindFirstChild("Handle")
	local old = h and h:FindFirstChild("SkinFX")
	if old then old:Destroy() end
	if h then
		for _, a in ipairs(h:GetChildren()) do
			if a:IsA("Attachment") and a:GetAttribute("SkinFX") then a:Destroy() end
		end
	end
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("ParticleEmitter") and d:GetAttribute("SkinFX") then d:Destroy() end
	end
end

-- the biggest Blade part: auras emit from its whole volume
local function bladePart(tool)
	local best, vol = nil, 0
	for _, p in ipairs(tool:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("SkinPart") == "Blade" and p.Transparency < 1 then
			local v = p.Size.X * p.Size.Y * p.Size.Z
			if v > vol then best, vol = p, v end
		end
	end
	return best
end

function SkinFX.apply(tool, skin)
	SkinFX.clear(tool)
	if not skin or skin.name == "Default" then return false end
	local handle = tool:FindFirstChild("Handle")
	local F = SkinTrims.frame(tool)
	if not (handle and F) then return false end
	local any = false
	if wantsTrail(skin) then
		local a0 = Instance.new("Attachment")
		a0.Name = "TrailBase"; a0:SetAttribute("SkinFX", true)
		a0.Position = Vector3.new(F.bX, F.guard + math.min(0.25, F.bLen * 0.15), 0)
		a0.Parent = handle
		local a1 = Instance.new("Attachment")
		a1.Name = "TrailTip"; a1:SetAttribute("SkinFX", true)
		a1.Position = Vector3.new(F.bX, F.tip - 0.05, 0)
		a1.Parent = handle
		local col = skin.glow or skin.accent or RARITY[skin.rarity] or RARITY.Epic
		local t = Instance.new("Trail")
		t.Name = "SkinTrail"
		t.Attachment0, t.Attachment1 = a0, a1
		t.Color = seq(col, col:Lerp(Color3.new(1, 1, 1), 0.35))
		t.Transparency = nseq({{0, skin.rarity == "Legendary" and 0.15 or 0.35}, {1, 1}})
		t.WidthScale = nseq({{0, 1}, {1, 0.35}})
		t.Lifetime = skin.rarity == "Legendary" and 0.26 or 0.18
		t.MinLength = 0.05
		t.LightEmission = skin.rarity == "Legendary" and 0.9 or 0.6
		t.LightInfluence = 0.2
		t.FaceCamera = false
		t:SetAttribute("SkinFX", true)
		t.Parent = handle
		any = true
	end
	local aura = skin.fx and AURAS[skin.fx]
	local part = aura and bladePart(tool)
	if aura and part then
		for i, e in ipairs(aura) do
			local pe = Instance.new("ParticleEmitter")
			pe.Name = "SkinAura" .. i
			pe.Texture = e.tex
			pe.Color = seq(e.c0, e.c1)
			pe.Size = nseq(e.size)
			pe.Transparency = e.transp and nseq(e.transp) or nseq({{0, 0.1}, {1, 1}})
			pe.Rate = e.rate
			pe.Lifetime = NumberRange.new(e.life[1], e.life[2])
			pe.Speed = NumberRange.new(e.speed[1], e.speed[2])
			pe.Acceleration = e.accel or Vector3.zero
			pe.SpreadAngle = Vector2.new(e.spread or 180, e.spread or 180)
			pe.LightEmission = e.light or 0
			pe.Drag = e.drag or 0
			if e.rot then pe.RotSpeed = NumberRange.new(-e.rot, e.rot); pe.Rotation = NumberRange.new(0, 360) end
			pe.LockedToPart = false
			pe:SetAttribute("SkinFX", true)
			pe.Parent = part
		end
		any = true
	end
	return any
end

return SkinFX
