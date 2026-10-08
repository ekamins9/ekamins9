--[[ SKIN FX — the third layer of a weapon skin, after the colours and the
     trim: a swing TRAIL and an AURA around the blade.
       • Epic and Legendary skins leave a trail when the weapon moves: a bright
         core and a wide soft glow behind it (its colour is the skin's glow, else
         its accent, else the rarity colour); Legendary trails shimmer. A skin can
         opt out with trail = false or in with trail = true.
       • A skin with fx = "<aura>" wears that aura: embers frost holy shadow
         storm toxic petals gold blood (Legendary skins have one each), and the
         Mythics' own: celestial inferno sovereign phoenix. An aura is a few
         layers of particles off the blade, a light on it, sparks that fly off the
         tip when it swings, and the sound of the swing.
       • MYTHIC: the longest, brightest trail, the strongest light, and stars
         twinkling along the blade. UNIQUE (one of one): all that, and its glow,
         its trail and a shimmer walk through the rainbow (like a Radiant finish,
         always).
     Alive in the world: the client's SkinFX driver (StarterPlayerScripts ▸
     SkinFX) makes the aura flare and the light swell while the blade moves, throws
     the sparks and plays the swing sound. Trails and particles don't render
     inside ViewportFrames, so the menu names them instead (SkinFX.describe).

       SkinFX.apply(tool, skin)   (re)builds the skin's effects on the Tool
       SkinFX.clear(tool)
       SkinFX.describe(skin)      "Trail · Embers" (or nil)
       SkinFX.AURAS               every aura name
       SkinFX.SWING               [aura] = {sound, pitch, volume, burst = {...}} (the driver reads it)
       SkinFX.HUM                 [aura] = {sound, pitch, volume}: the quiet loop an aura makes
                                  while the weapon is in someone's hands (a crackle of fire, an
                                  electric hum, a shimmer; only heard up close) ]]

local CollectionService = game:GetService("CollectionService")
local SkinTrims = require(script.Parent:WaitForChild("SkinTrims"))

local SkinFX = {}

local TEX = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
}
local RARITY = {Common = Color3.fromRGB(150, 160, 175), Rare = Color3.fromRGB(70, 150, 255), Epic = Color3.fromRGB(180, 90, 255), Legendary = Color3.fromRGB(255, 186, 60),
	Mythic = Color3.fromRGB(255, 60, 90), Unique = Color3.fromRGB(255, 244, 214)}
local C = Color3.fromRGB

local function seq(a, b) return ColorSequence.new(a, b or a) end
local function nseq(points)
	local kp = {}
	for _, p in ipairs(points) do table.insert(kp, NumberSequenceKeypoint.new(p[1], p[2])) end
	return NumberSequence.new(kp)
end

-- an aura: emit = layers {texture, colour(s), size, rate, life, speed, accel, spread,
-- light emission, transparency, rotation}; light = the blade's glow; swing = what a
-- swing sheds (sparks off the tip: burst; and a sound from Roblox's licensed library)
local AURAS = {
	embers = {
		emit = {
			{tex = TEX.spark, c0 = C(255, 214, 96), c1 = C(255, 70, 20), size = {{0, 0.24}, {1, 0}}, rate = 34, life = {0.5, 1.2}, speed = {0.6, 2.2}, accel = Vector3.new(0, 7, 0), spread = 70, light = 1},
			{tex = TEX.fire, c0 = C(255, 156, 44), c1 = C(210, 44, 10), size = {{0, 0.6}, {0.5, 0.38}, {1, 0.05}}, rate = 18, life = {0.25, 0.5}, speed = {0.3, 1}, accel = Vector3.new(0, 5, 0), spread = 25, light = 1, transp = {{0, 0.25}, {1, 1}}},
			{tex = TEX.smoke, c0 = C(70, 46, 34), size = {{0, 0.3}, {1, 1.1}}, rate = 4, life = {0.8, 1.4}, speed = {0.3, 0.8}, accel = Vector3.new(0, 2.5, 0), spread = 40, light = 0, transp = {{0, 0.7}, {1, 1}}},
		},
		light = C(255, 140, 50),
		swing = {sound = 9120696702, pitch = 1.45, volume = 0.32,
			burst = {tex = TEX.spark, c0 = C(255, 236, 130), c1 = C(255, 80, 20), size = {{0, 0.32}, {1, 0}}, count = 5, life = {0.25, 0.6}, speed = {5, 11}, accel = Vector3.new(0, -12, 0), spread = 45, light = 1}},
	},
	frost = {
		emit = {
			{tex = TEX.spark, c0 = C(235, 250, 255), c1 = C(150, 214, 255), size = {{0, 0.2}, {1, 0.02}}, rate = 26, life = {0.8, 1.6}, speed = {0.1, 0.6}, accel = Vector3.new(0, -1.4, 0), spread = 180, light = 0.9, rot = 80},
			{tex = TEX.smoke, c0 = C(205, 238, 255), size = {{0, 0.35}, {1, 1}}, rate = 8, life = {0.8, 1.3}, speed = {0.05, 0.25}, accel = Vector3.new(0, -0.6, 0), spread = 180, light = 0.25, transp = {{0, 0.65}, {1, 1}}},
			{tex = TEX.spark, c0 = C(255, 255, 255), size = {{0, 0.08}, {0.5, 0.14}, {1, 0}}, rate = 30, life = {0.2, 0.45}, speed = {0, 0.1}, spread = 180, light = 1, locked = true},
		},
		light = C(150, 210, 255),
		swing = {sound = 9118762653, pitch = 2.2, volume = 0.22, cut = 0.45,
			burst = {tex = TEX.spark, c0 = C(255, 255, 255), c1 = C(150, 214, 255), size = {{0, 0.28}, {1, 0}}, count = 6, life = {0.3, 0.7}, speed = {3, 8}, accel = Vector3.new(0, -9, 0), spread = 60, light = 1, rot = 200}},
	},
	holy = {
		emit = {
			{tex = TEX.spark, c0 = C(255, 252, 226), c1 = C(255, 212, 110), size = {{0, 0.26}, {0.5, 0.16}, {1, 0}}, rate = 26, life = {0.9, 1.6}, speed = {0.2, 0.7}, accel = Vector3.new(0, 2, 0), spread = 180, light = 1},
			{tex = TEX.spark, c0 = C(255, 255, 255), size = {{0, 0.1}, {0.5, 0.18}, {1, 0}}, rate = 34, life = {0.2, 0.5}, speed = {0, 0.1}, spread = 180, light = 1, locked = true},
			{tex = TEX.smoke, c0 = C(255, 236, 170), size = {{0, 0.4}, {1, 1.2}}, rate = 5, life = {0.6, 1}, speed = {0.1, 0.4}, accel = Vector3.new(0, 1.5, 0), spread = 180, light = 1, transp = {{0, 0.8}, {1, 1}}},
		},
		light = C(255, 236, 170),
		swing = {sound = 9120726501, pitch = 1.6, volume = 0.25, cut = 0.8,
			burst = {tex = TEX.spark, c0 = C(255, 255, 230), c1 = C(255, 200, 90), size = {{0, 0.36}, {1, 0}}, count = 5, life = {0.4, 0.8}, speed = {3, 7}, accel = Vector3.new(0, 3, 0), spread = 90, light = 1}},
	},
	shadow = {
		emit = {
			{tex = TEX.smoke, c0 = C(46, 22, 70), c1 = C(10, 5, 20), size = {{0, 0.3}, {1, 0.95}}, rate = 18, life = {0.7, 1.3}, speed = {0.1, 0.5}, accel = Vector3.new(0, 1, 0), spread = 180, light = 0, transp = {{0, 0.35}, {1, 1}}},
			{tex = TEX.spark, c0 = C(190, 110, 255), c1 = C(110, 40, 200), size = {{0, 0.16}, {1, 0}}, rate = 18, life = {0.5, 1}, speed = {0.2, 0.8}, accel = Vector3.new(0, 1.4, 0), spread = 180, light = 1},
			{tex = TEX.smoke, c0 = C(0, 0, 0), size = {{0, 0.2}, {1, 0.5}}, rate = 8, life = {0.3, 0.6}, speed = {0, 0.2}, spread = 180, light = 0, transp = {{0, 0.5}, {1, 1}}, locked = true},
		},
		light = C(150, 70, 255),
		swing = {sound = 9119805147, pitch = 0.75, volume = 0.22, cut = 0.7,
			burst = {tex = TEX.smoke, c0 = C(60, 20, 100), c1 = C(10, 0, 20), size = {{0, 0.5}, {1, 1.2}}, count = 4, life = {0.3, 0.6}, speed = {2, 5}, spread = 70, light = 0, transp = {{0, 0.3}, {1, 1}}}},
	},
	storm = {
		emit = {
			{tex = TEX.spark, c0 = C(225, 248, 255), c1 = C(90, 170, 255), size = {{0, 0.26}, {1, 0}}, rate = 40, life = {0.06, 0.16}, speed = {4, 9}, spread = 180, light = 1, drag = 8},
			{tex = TEX.spark, c0 = C(255, 255, 255), size = {{0, 0.12}, {0.3, 0.3}, {1, 0}}, rate = 22, life = {0.05, 0.12}, speed = {0, 0.2}, spread = 180, light = 1, locked = true},
			{tex = TEX.smoke, c0 = C(120, 170, 255), size = {{0, 0.3}, {1, 0.7}}, rate = 4, life = {0.4, 0.7}, speed = {0.1, 0.3}, spread = 180, light = 1, transp = {{0, 0.8}, {1, 1}}},
		},
		light = C(140, 200, 255), flicker = true,
		swing = {sound = 9119594928, pitch = 1.5, volume = 0.18, cut = 0.35,
			burst = {tex = TEX.spark, c0 = C(255, 255, 255), c1 = C(90, 170, 255), size = {{0, 0.3}, {1, 0}}, count = 8, life = {0.08, 0.22}, speed = {10, 20}, spread = 180, light = 1, drag = 6}},
	},
	toxic = {
		emit = {
			{tex = TEX.spark, c0 = C(180, 255, 120), c1 = C(60, 200, 60), size = {{0, 0.2}, {1, 0.02}}, rate = 24, life = {0.7, 1.3}, speed = {0.2, 0.7}, accel = Vector3.new(0, 1.8, 0), spread = 180, light = 0.9},
			{tex = TEX.smoke, c0 = C(96, 210, 74), size = {{0, 0.3}, {1, 0.9}}, rate = 8, life = {0.6, 1.1}, speed = {0.1, 0.35}, accel = Vector3.new(0, 0.8, 0), spread = 180, light = 0.3, transp = {{0, 0.6}, {1, 1}}},
			{tex = TEX.spark, c0 = C(120, 255, 90), size = {{0, 0.14}, {1, 0}}, rate = 10, life = {0.5, 0.9}, speed = {0.4, 1}, accel = Vector3.new(0, -5, 0), spread = 30, light = 1},
		},
		light = C(110, 230, 90),
		swing = {sound = 9120696702, pitch = 0.9, volume = 0.18, cut = 0.6,
			burst = {tex = TEX.spark, c0 = C(190, 255, 120), c1 = C(60, 200, 60), size = {{0, 0.28}, {1, 0}}, count = 6, life = {0.4, 0.8}, speed = {3, 7}, accel = Vector3.new(0, -14, 0), spread = 50, light = 1}},
	},
	petals = {
		emit = {
			{tex = TEX.spark, c0 = C(255, 170, 205), c1 = C(232, 64, 114), size = {{0, 0.24}, {1, 0.14}}, rate = 16, life = {1.2, 2.2}, speed = {0.3, 0.9}, accel = Vector3.new(0, -0.9, 0), spread = 180, light = 0.45, rot = 160},
			{tex = TEX.spark, c0 = C(255, 240, 248), size = {{0, 0.08}, {0.5, 0.14}, {1, 0}}, rate = 18, life = {0.3, 0.6}, speed = {0, 0.1}, spread = 180, light = 1, locked = true},
		},
		light = C(255, 150, 190),
		swing = {sound = 9120726501, pitch = 1.9, volume = 0.18, cut = 0.6,
			burst = {tex = TEX.spark, c0 = C(255, 190, 215), c1 = C(232, 64, 114), size = {{0, 0.3}, {1, 0.18}}, count = 7, life = {0.8, 1.4}, speed = {2, 5}, accel = Vector3.new(0, -2, 0), spread = 90, light = 0.5, rot = 200}},
	},
	gold = {
		emit = {
			{tex = TEX.spark, c0 = C(255, 234, 146), c1 = C(232, 172, 40), size = {{0, 0.22}, {1, 0}}, rate = 24, life = {0.6, 1.2}, speed = {0.2, 0.8}, accel = Vector3.new(0, 0.8, 0), spread = 180, light = 1},
			{tex = TEX.spark, c0 = C(255, 255, 220), size = {{0, 0.1}, {0.5, 0.2}, {1, 0}}, rate = 30, life = {0.2, 0.45}, speed = {0, 0.1}, spread = 180, light = 1, locked = true},
		},
		light = C(255, 210, 110),
		swing = {sound = 9113760225, pitch = 1.6, volume = 0.2, cut = 0.5,
			burst = {tex = TEX.spark, c0 = C(255, 240, 150), c1 = C(230, 170, 40), size = {{0, 0.34}, {1, 0}}, count = 6, life = {0.4, 0.8}, speed = {4, 9}, accel = Vector3.new(0, -16, 0), spread = 60, light = 1}},
	},
	-- THE MYTHICS' OWN
	celestial = {
		emit = {
			{tex = TEX.smoke, c0 = C(70, 56, 160), c1 = C(20, 30, 96), size = {{0, 0.5}, {1, 1.5}}, rate = 6, life = {1.2, 2}, speed = {0.05, 0.25}, spread = 180, light = 0.45, transp = {{0, 0.6}, {1, 1}}},
			{tex = TEX.spark, c0 = C(255, 255, 255), c1 = C(170, 190, 255), size = {{0, 0.05}, {0.5, 0.2}, {1, 0}}, rate = 36, life = {0.3, 0.7}, speed = {0, 0.05}, spread = 180, light = 1, locked = true},
			{tex = TEX.spark, c0 = C(200, 215, 255), c1 = C(120, 140, 255), size = {{0, 0.2}, {1, 0}}, rate = 14, life = {1, 2}, speed = {0.2, 0.6}, accel = Vector3.new(0, 0.6, 0), spread = 180, light = 1, rot = 90},
		},
		light = C(140, 150, 255),
		swing = {sound = 1846902441, pitch = 1.8, volume = 0.12, cut = 0.6,
			burst = {tex = TEX.spark, c0 = C(255, 255, 255), c1 = C(150, 170, 255), size = {{0, 0.3}, {1, 0}}, count = 9, life = {0.4, 0.9}, speed = {4, 9}, accel = Vector3.new(0, -4, 0), spread = 70, light = 1}},
	},
	inferno = {
		emit = {
			{tex = TEX.fire, c0 = C(255, 170, 60), c1 = C(220, 40, 10), size = {{0, 0.8}, {0.5, 0.5}, {1, 0.05}}, rate = 30, life = {0.3, 0.6}, speed = {0.4, 1.4}, accel = Vector3.new(0, 7, 0), spread = 25, light = 1, transp = {{0, 0.2}, {1, 1}}},
			{tex = TEX.spark, c0 = C(255, 200, 80), c1 = C(255, 60, 10), size = {{0, 0.2}, {1, 0.1}}, rate = 10, life = {0.5, 0.9}, speed = {0.1, 0.4}, accel = Vector3.new(0, -22, 0), spread = 20, light = 1},
			{tex = TEX.spark, c0 = C(255, 220, 120), c1 = C(255, 80, 20), size = {{0, 0.16}, {1, 0}}, rate = 30, life = {0.8, 1.6}, speed = {0.6, 2}, accel = Vector3.new(0, 8, 0), spread = 70, light = 1},
			{tex = TEX.smoke, c0 = C(50, 30, 25), size = {{0, 0.4}, {1, 1.6}}, rate = 6, life = {1, 1.6}, speed = {0.3, 0.9}, accel = Vector3.new(0, 3, 0), spread = 40, light = 0, transp = {{0, 0.6}, {1, 1}}},
		},
		light = C(255, 110, 30),
		flicker = true,
		swing = {sound = 9120696702, pitch = 1.0, volume = 0.35,
			burst = {tex = TEX.spark, c0 = C(255, 230, 130), c1 = C(255, 60, 10), size = {{0, 0.36}, {1, 0}}, count = 10, life = {0.3, 0.7}, speed = {6, 13}, accel = Vector3.new(0, -16, 0), spread = 50, light = 1}},
	},
	sovereign = {
		emit = {
			{tex = TEX.spark, c0 = C(255, 236, 160), c1 = C(232, 172, 40), size = {{0, 0.22}, {1, 0}}, rate = 26, life = {0.7, 1.4}, speed = {0.2, 0.7}, accel = Vector3.new(0, 1.2, 0), spread = 180, light = 1},
			{tex = TEX.spark, c0 = C(255, 255, 235), size = {{0, 0.1}, {0.5, 0.32}, {1, 0}}, rate = 22, life = {0.3, 0.6}, speed = {0, 0.05}, spread = 180, light = 1, locked = true},
			{tex = TEX.smoke, c0 = C(255, 245, 220), size = {{0, 0.4}, {1, 1.2}}, rate = 5, life = {1, 1.6}, speed = {0.05, 0.2}, accel = Vector3.new(0, 0.8, 0), spread = 180, light = 0.6, transp = {{0, 0.7}, {1, 1}}},
		},
		light = C(255, 225, 150),
		swing = {sound = 1846902441, pitch = 1.3, volume = 0.14, cut = 0.7,
			burst = {tex = TEX.spark, c0 = C(255, 250, 200), c1 = C(232, 172, 40), size = {{0, 0.34}, {1, 0}}, count = 9, life = {0.4, 0.9}, speed = {4, 9}, accel = Vector3.new(0, -10, 0), spread = 60, light = 1}},
	},
	phoenix = {
		emit = {
			{tex = TEX.spark, c0 = C(255, 210, 90), c1 = C(230, 50, 20), size = {{0, 0.3}, {1, 0.12}}, rate = 20, life = {0.6, 1.2}, speed = {0.5, 1.5}, accel = Vector3.new(0, 4, 0), spread = 50, light = 1, rot = 140},
			{tex = TEX.fire, c0 = C(255, 190, 70), c1 = C(230, 60, 20), size = {{0, 0.6}, {1, 0.05}}, rate = 20, life = {0.25, 0.5}, speed = {0.3, 1}, accel = Vector3.new(0, 6, 0), spread = 25, light = 1, transp = {{0, 0.25}, {1, 1}}},
			{tex = TEX.spark, c0 = C(255, 250, 200), size = {{0, 0.08}, {0.5, 0.16}, {1, 0}}, rate = 20, life = {0.2, 0.4}, speed = {0, 0.1}, spread = 180, light = 1, locked = true},
		},
		light = C(255, 140, 40),
		swing = {sound = 9125386714, pitch = 1.4, volume = 0.2, cut = 0.6,
			burst = {tex = TEX.spark, c0 = C(255, 220, 110), c1 = C(230, 50, 20), size = {{0, 0.36}, {1, 0.1}}, count = 8, life = {0.5, 1}, speed = {4, 9}, accel = Vector3.new(0, -6, 0), spread = 70, light = 1, rot = 180}},
	},
	blood = {
		emit = {
			{tex = TEX.smoke, c0 = C(150, 12, 24), c1 = C(60, 0, 8), size = {{0, 0.26}, {1, 0.7}}, rate = 12, life = {0.6, 1.1}, speed = {0.05, 0.35}, accel = Vector3.new(0, -1.2, 0), spread = 180, light = 0, transp = {{0, 0.4}, {1, 1}}},
			{tex = TEX.spark, c0 = C(255, 70, 70), c1 = C(160, 0, 20), size = {{0, 0.14}, {1, 0}}, rate = 14, life = {0.4, 0.9}, speed = {0.2, 0.6}, accel = Vector3.new(0, -3, 0), spread = 180, light = 1},
			{tex = TEX.spark, c0 = C(200, 0, 20), size = {{0, 0.12}, {1, 0.05}}, rate = 8, life = {0.5, 0.9}, speed = {0.3, 0.8}, accel = Vector3.new(0, -14, 0), spread = 20, light = 0.4},
		},
		light = C(220, 30, 50),
		swing = {sound = 9120706422, pitch = 1.3, volume = 0.16, cut = 0.5,
			burst = {tex = TEX.spark, c0 = C(220, 20, 40), c1 = C(100, 0, 10), size = {{0, 0.26}, {1, 0.05}}, count = 7, life = {0.4, 0.8}, speed = {4, 9}, accel = Vector3.new(0, -22, 0), spread = 50, light = 0.6}},
	},
}
-- THE HUM: a quiet loop while it's held (Pro Sound Effects). Never more than a
-- lightsaber's hum: you hear it standing next to them, it's gone a few steps away
local FIRE_LOOP, ELECTRIC_HUM, SWIRL, LOW_PULSE = 9118030782, 9112889082, 9125899162, 9119845261
SkinFX.HUM = {
	embers = {sound = FIRE_LOOP, pitch = 0.8, volume = 0.06}, inferno = {sound = FIRE_LOOP, pitch = 0.7, volume = 0.09},
	phoenix = {sound = FIRE_LOOP, pitch = 0.95, volume = 0.07}, storm = {sound = ELECTRIC_HUM, pitch = 1.3, volume = 0.05},
	holy = {sound = SWIRL, pitch = 1.6, volume = 0.04}, sovereign = {sound = SWIRL, pitch = 1.4, volume = 0.05},
	celestial = {sound = SWIRL, pitch = 1.2, volume = 0.06}, gold = {sound = SWIRL, pitch = 1.8, volume = 0.03},
	frost = {sound = SWIRL, pitch = 2.2, volume = 0.03}, shadow = {sound = LOW_PULSE, pitch = 1, volume = 0.05},
	blood = {sound = LOW_PULSE, pitch = 1.2, volume = 0.04},
}
SkinFX.AURAS = {}
SkinFX.SWING = {}
for k, a in pairs(AURAS) do table.insert(SkinFX.AURAS, k); SkinFX.SWING[k] = a.swing end
table.sort(SkinFX.AURAS)

local NAME = {embers = "Embers", frost = "Frost", holy = "Holy light", shadow = "Shadow", storm = "Storm", toxic = "Venom", petals = "Petals", gold = "Gold dust", blood = "Blood mist",
	celestial = "Starlight", inferno = "Inferno", sovereign = "Sovereign light", phoenix = "Phoenix fire"}

local function wantsTrail(skin, variant)
	if variant then return true end
	if skin.trail ~= nil then return skin.trail == true end
	return skin.rarity == "Epic" or skin.rarity == "Legendary" or skin.rarity == "Mythic" or skin.rarity == "Unique"
end

function SkinFX.describe(skin)
	if not skin then return nil end
	local bits = {}
	if wantsTrail(skin, variant) then table.insert(bits, "Trail") end
	if skin.fx and NAME[skin.fx] then table.insert(bits, NAME[skin.fx]) end
	if skin.rarity == "Unique" then table.insert(bits, "Prismatic") end
	-- a bow's or a crossbow's arrows (ReplicatedStorage ▸ ArrowFX)
	if skin.arrow then
		local ok, ArrowFX = pcall(require, script.Parent:WaitForChild("ArrowFX", 2))
		local k = ok and ArrowFX and ArrowFX.KINDS[skin.arrow]
		if k then table.insert(bits, k.name) end
	end
	return #bits > 0 and table.concat(bits, " · ") or nil
end

function SkinFX.clear(tool)
	local h = tool:FindFirstChild("Handle")
	local old = h and h:FindFirstChild("SkinFX")
	if old then old:Destroy() end
	if h then
		for _, a in ipairs(h:GetChildren()) do
			if a:GetAttribute("SkinFX") then a:Destroy() end
		end
		CollectionService:RemoveTag(h, "SkinFX")
		for _, k in ipairs({"SkinAura", "SkinRarity", "SkinVariant"}) do h:SetAttribute(k, nil) end
	end
	for _, d in ipairs(tool:GetDescendants()) do
		if (d:IsA("ParticleEmitter") or d:IsA("PointLight")) and d:GetAttribute("SkinFX") then d:Destroy() end
	end
end

-- the biggest Blade part: auras emit from its whole volume
local function bladePart(tool)
	local best, vol = nil, 0
	for _, p in ipairs(tool:GetDescendants()) do
		-- (a Forge model's body counts as the blade: it is what is seen)
		if p:IsA("BasePart") and (p:GetAttribute("SkinPart") == "Blade" or p:GetAttribute("SkinBody")) and p.Transparency < 1 then
			local v = p.Size.X * p.Size.Y * p.Size.Z
			if v > vol then best, vol = p, v end
		end
	end
	return best
end

local function emitter(e, name)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = name
	pe.Texture = e.tex
	pe.Color = seq(e.c0, e.c1)
	pe.Size = nseq(e.size)
	pe.Transparency = e.transp and nseq(e.transp) or nseq({{0, 0.1}, {1, 1}})
	pe.Rate = e.rate or 0
	pe.Lifetime = NumberRange.new(e.life[1], e.life[2])
	pe.Speed = NumberRange.new(e.speed[1], e.speed[2])
	pe.Acceleration = e.accel or Vector3.zero
	pe.SpreadAngle = Vector2.new(e.spread or 180, e.spread or 180)
	pe.LightEmission = e.light or 0
	pe.Drag = e.drag or 0
	if e.rot then pe.RotSpeed = NumberRange.new(-e.rot, e.rot); pe.Rotation = NumberRange.new(0, 360) end
	pe.LockedToPart = e.locked == true
	pe:SetAttribute("SkinFX", true)
	pe:SetAttribute("BaseRate", e.rate or 0)   -- the driver flares it from here while the blade swings
	return pe
end

local function attachment(handle, name, pos)
	local a = Instance.new("Attachment")
	a.Name = name; a:SetAttribute("SkinFX", true)
	a.Position = pos
	a.Parent = handle
	return a
end

function SkinFX.apply(tool, skin, variant)
	SkinFX.clear(tool)
	if not skin or skin.name == "Default" then return false end
	local handle = tool:FindFirstChild("Handle")
	local F = SkinTrims.frame(tool)
	if not (handle and F) then return false end
	local any = false
	local mythic = skin.rarity == "Mythic" or skin.rarity == "Unique"
	local legendary = mythic or skin.rarity == "Legendary" or variant == "Radiant"
	local col = skin.glow or skin.accent or RARITY[skin.rarity] or RARITY.Epic
	-- the blade's line, guard to tip, in the Handle's space
	local base = Vector3.new(F.bX, F.guard + math.min(0.25, F.bLen * 0.15), 0)
	local tipPos = Vector3.new(F.bX, F.tip - 0.05, 0)
	local tip = attachment(handle, "TrailTip", tipPos)
	if wantsTrail(skin, variant) then
		local a0 = attachment(handle, "TrailBase", base)
		-- the core: a bright ribbon along the blade
		local t = Instance.new("Trail")
		t.Name = "SkinTrail"
		t.Attachment0, t.Attachment1 = a0, tip
		t.Color = seq(col:Lerp(Color3.new(1, 1, 1), 0.25), col)
		t.Transparency = nseq({{0, legendary and 0.05 or 0.25}, {0.5, legendary and 0.4 or 0.6}, {1, 1}})
		t.WidthScale = nseq({{0, 1}, {1, 0.3}})
		t.Lifetime = mythic and 0.42 or (legendary and 0.3 or 0.2)
		t.MinLength = 0.04
		t.LightEmission = legendary and 1 or 0.7
		t.LightInfluence = 0
		t.FaceCamera = false
		if legendary then t.Texture = TEX.spark; t.TextureMode = Enum.TextureMode.Wrap; t.TextureLength = 1.2 end
		t:SetAttribute("SkinFX", true)
		t.Parent = handle
		-- the glow: wider and softer, past both ends of the blade, lingering longer
		local over = math.max(0.4, F.bLen * (mythic and 0.3 or 0.18))
		local g0 = attachment(handle, "TrailGlowBase", base - Vector3.new(0, over * 0.6, 0))
		local g1 = attachment(handle, "TrailGlowTip", tipPos + Vector3.new(0, over, 0))
		local g = Instance.new("Trail")
		g.Name = "SkinTrailGlow"
		g.Attachment0, g.Attachment1 = g0, g1
		g.Color = seq(col)
		g.Transparency = nseq({{0, legendary and 0.55 or 0.7}, {1, 1}})
		g.WidthScale = nseq({{0, 1}, {1, 0.5}})
		g.Lifetime = mythic and 0.65 or (legendary and 0.45 or 0.3)
		g.MinLength = 0.04
		g.LightEmission = 1
		g.LightInfluence = 0
		g:SetAttribute("SkinFX", true)
		g.Parent = handle
		any = true
	end
	local aura = skin.fx and AURAS[skin.fx]
	local part = aura and bladePart(tool)
	if aura and part then
		for i, e in ipairs(aura.emit) do emitter(e, "SkinAura" .. i).Parent = part end
		-- the blade glows
		local l = Instance.new("PointLight")
		l.Name = "SkinLight"
		l.Color = aura.light or col
		l.Range = mythic and 13 or (legendary and 9 or 6)
		l.Brightness = mythic and 2.1 or (legendary and 1.4 or 0.8)
		l.Shadows = false
		l:SetAttribute("SkinFX", true)
		l:SetAttribute("BaseBrightness", l.Brightness)
		if aura.flicker then l:SetAttribute("Flicker", true) end
		l.Parent = part
		-- what a swing throws off the tip (the driver emits it)
		if aura.swing and aura.swing.burst then
			local b = emitter(aura.swing.burst, "SkinBurst")
			b.Rate = 0
			b:SetAttribute("Count", aura.swing.burst.count or 5)
			b.Parent = tip
		end
		handle:SetAttribute("SkinAura", skin.fx)
		any = true
	end
	-- MYTHIC and UNIQUE: stars twinkle along the blade in its glow; a Unique's glow,
	-- trails and a shimmer walk through the rainbow, always (the client driver turns them)
	if mythic then
		local body0 = bladePart(tool) or handle
		local glint = emitter({tex = TEX.spark, c0 = Color3.new(1, 1, 1), c1 = col, size = {{0, 0.06}, {0.5, 0.26}, {1, 0}},
			rate = 16, life = {0.4, 0.9}, speed = {0, 0.05}, spread = 180, light = 1, locked = true}, "SkinMythic")
		glint.Parent = body0
		if skin.rarity == "Unique" then
			local prism = emitter({tex = TEX.spark, c0 = C(255, 120, 220), c1 = C(120, 220, 255), size = {{0, 0.2}, {0.5, 0.34}, {1, 0}},
				rate = 18, life = {0.7, 1.4}, speed = {0.1, 0.5}, accel = Vector3.new(0, 0.8, 0), spread = 180, light = 1}, "SkinUnique")
			prism:SetAttribute("Radiant", true)
			prism.Parent = body0
			for _, d in ipairs(tool:GetDescendants()) do
				if (d:IsA("Trail") and d:GetAttribute("SkinFX")) or (d:IsA("BasePart") and d.Material == Enum.Material.Neon) or (d:IsA("PointLight") and d:GetAttribute("SkinFX")) then
					d:SetAttribute("Radiant", true)
				end
			end
		end
		any = true
	end
	-- THE FINISH: Masterwork glints gold along the blade; Radiant cycles every
	-- colour through its glow, its trail and an aura (the client driver turns
	-- the hue: everything tagged with the Radiant attribute)
	local body = bladePart(tool) or handle
	if variant == "Masterwork" then
		local e = emitter({tex = TEX.spark, c0 = C(255, 236, 160), c1 = C(232, 170, 50), size = {{0, 0.16}, {0.5, 0.22}, {1, 0}},
			rate = 6, life = {0.5, 1.0}, speed = {0.02, 0.15}, spread = 180, light = 1}, "SkinMasterwork")
		e.Parent = body
		any = true
	elseif variant == "Radiant" then
		local e = emitter({tex = TEX.spark, c0 = C(255, 120, 220), c1 = C(120, 220, 255), size = {{0, 0.22}, {0.5, 0.3}, {1, 0}},
			rate = 14, life = {0.6, 1.2}, speed = {0.1, 0.4}, spread = 180, light = 1}, "SkinRadiant")
		e:SetAttribute("Radiant", true)
		e.Parent = body
		for _, d in ipairs(tool:GetDescendants()) do
			if (d:IsA("Trail") and d:GetAttribute("SkinFX")) or (d:IsA("BasePart") and d.Material == Enum.Material.Neon) or (d:IsA("PointLight") and d:GetAttribute("SkinFX")) then
				d:SetAttribute("Radiant", true)
			end
		end
		any = true
	end
	if any then
		handle:SetAttribute("SkinRarity", skin.rarity)
		handle:SetAttribute("SkinVariant", variant)
		CollectionService:AddTag(handle, "SkinFX")
	end
	return any
end

return SkinFX
