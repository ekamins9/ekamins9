--[[ POWER POSES — the body's part in a power: a short gesture as it goes off. The weapon goes
     up overhead and the flames catch it, a war cry throws the arms wide, a slam drives the blade
     into the ground, a whirlwind spins, an archer draws a charmed arrow from the quiver.

     They are motions for ReplicatedStorage ▸ Emotes (Emotes.define), so they are drawn the way
     emotes are, on every screen, players and bots alike: through RigPose, the animation let go
     of the arms while one plays, the blade turned in the hand to where it should point. All are
     arms-only (you can walk, dash and leap through them) and short; an attack, a block or a hit
     cuts one off, so a power never holds you up.

       PowerPoses.gestureFor(powerDef) -> id    which one a power plays: its own `pose`
                                                (Catalog ▸ Powers), else one for its kind
       PowerPoses.play(character, id[, startedAt])
       PowerPoses.THROW                         a throwable's fling

     Started by Powers.client: as a power winds up (PowerCasting), or as it goes off (PowerTick)
     when it has no wind-up; a throw on ThrowTick.

     Poses are in degrees, as in Emotes: x+ swings a limb forward (the neck: chin up; the waist:
     leaning back), z+ the right arm out to the side, z- the left; blade = where the weapon points
     in the body's frame (+y up, -z ahead, +x right); plantW drives its tip to the ground. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Emotes = require(ReplicatedStorage:WaitForChild("Emotes"))

local PowerPoses = {}
local track, with, window = Emotes.track, Emotes.with, Emotes.window

local function def(name, d, keys, extra)
	local pose = track(keys)
	Emotes.define("Pw" .. name, {d = d, upper = true, gesture = true, pose = extra and with(pose, extra) or pose})
end
-- the strain of holding power: a tremble in the arms
local function tremble(a, b, amt)
	return function(t, p)
		local w = window(t, a, b, 0.1)
		local s = math.sin(t * 46) * (amt or 2.5) * w
		p.rs[3] += s; p.ls[3] -= s; p.neck[3] += s * 0.4
	end
end

-- IGNITE: a dip, then the blade straight up overhead, chin up to it; the free hand sweeps off
-- the blade as the fire (frost, wind, light…) takes it. Imbues.
local IGNITE = {rs = {176, 0, -24}, ls = {66, 0, -64}, blade = {0, 1, 0.04}, neck = {24, 0, 0}, waist = {9, 0, 0}}
def("Ignite", 1.35, {
	{0, {}},
	{0.12, {rs = {-14, 0, 12}, ls = {-8, 0, -6}, waist = {-6, 0, 0}, neck = {-6, 0, 0}, rootY = -0.12}},
	{0.32, {rs = {178, 0, -26}, ls = {158, 0, -16}, blade = {0, 1, 0.04}, neck = {28, 0, 0}, waist = {11, 0, 0}, rootY = 0.06}},
	{0.5, IGNITE}, {1.0, IGNITE}, {1.35, {}},
}, tremble(0.4, 1.0, 2))

-- ENVENOM: the blade drawn across before the face, the free hand along its edge. Venom, ambush.
local ENVENOM = {rs = {96, 0, -46}, ls = {84, 0, -26}, blade = {-1, 0.25, -0.35}, neck = {-6, 0, 0}, waist = {-10, 0, 0}, rootY = -0.18}
def("Envenom", 1.25, {
	{0, {}},
	{0.14, {rs = {40, 0, 14}, waist = {-4, 0, 0}}},
	{0.34, {rs = {98, 0, -50}, ls = {92, 0, 34}, blade = {-1, 0.25, -0.3}, neck = {-8, 0, 0}, waist = {-12, 0, 0}, rootY = -0.2}},
	{0.62, ENVENOM}, {0.95, ENVENOM}, {1.25, {}},
})

-- VOW: the blade upright before the face, head bowed to it, the free hand on the heart, then
-- the chin comes up. Holy powers.
local VOW = {rs = {116, 0, -30}, blade = {0, 1, 0.04}, ls = {58, 0, 46}, neck = {-18, 0, 0}, waist = {-4, 0, 0}}
def("Vow", 1.4, {
	{0, {}}, {0.3, VOW}, {0.85, VOW},
	{1.05, {rs = {124, 0, -30}, blade = {0, 1, 0.04}, ls = {58, 0, 46}, neck = {14, 0, 0}, waist = {6, 0, 0}}},
	{1.4, {}},
})

-- ROAR: gathered in, then flung open: arms wide, chest out, head back. Shouts.
local ROAR = {rs = {24, 0, 100}, ls = {24, 0, -100}, waist = {22, 0, 0}, neck = {38, 0, 0}, rootY = 0.1, blade = {0.7, 0.9, 0}}
def("Roar", 1.35, {
	{0, {}},
	{0.15, {rs = {-12, 0, 18}, ls = {-12, 0, -18}, waist = {-18, 0, 0}, neck = {-14, 0, 0}, rootY = -0.3}},
	{0.32, ROAR}, {0.95, ROAR}, {1.35, {}},
}, tremble(0.32, 0.95, 4))

-- BRACE: arms crossed before the chest, then thrown down and out into a planted stance.
-- Iron Skin, Juggernaut.
local BRACE = {rs = {24, 0, 42}, ls = {24, 0, -42}, waist = {12, 0, 0}, neck = {10, 0, 0}, rootY = -0.35, blade = {0.6, -0.4, -0.6}}
def("Brace", 1.2, {
	{0, {}},
	{0.15, {rs = {72, 0, -42}, ls = {72, 0, 42}, waist = {-8, 0, 0}, neck = {-12, 0, 0}, rootY = -0.1, blade = {-0.3, 1, 0}}},
	{0.34, BRACE}, {0.85, BRACE}, {1.2, {}},
}, tremble(0.34, 0.85, 3))

-- SURGE: crouched and gathering, then exploding upward, arms in a V, head back. Ultimates.
local SURGE = {rs = {166, 0, 54}, ls = {166, 0, -54}, waist = {20, 0, 0}, neck = {40, 0, 0}, rootY = 0.25, blade = {0.3, 1, 0}}
def("Surge", 1.55, {
	{0, {}},
	{0.22, {rs = {10, 0, -22}, ls = {10, 0, 22}, waist = {-24, 0, 0}, neck = {-20, 0, 0}, rootY = -0.45, blade = {0, -0.3, -1}}},
	{0.46, SURGE}, {1.15, SURGE}, {1.55, {}},
}, tremble(0.46, 1.15, 3.5))

-- HASTE: up on the toes, a quick bounce, the arms pumping once. Speed buffs.
def("Haste", 0.95, {
	{0, {}},
	{0.12, {rootY = -0.2, waist = {-10, 0, 0}, rs = {-20, 0, 10}, ls = {30, 0, -10}}},
	{0.3, {rootY = 0.25, waist = {6, 0, 0}, rs = {50, 0, 10}, ls = {-30, 0, -10}, neck = {10, 0, 0}, blade = {0, 0.4, -1}}},
	{0.48, {rootY = 0, waist = {-4, 0, 0}, rs = {-10, 0, 10}, ls = {40, 0, -10}}},
	{0.62, {rootY = 0.12, rs = {35, 0, 10}, ls = {-15, 0, -10}, neck = {6, 0, 0}}},
	{0.95, {}},
})

-- BREATH: a deep breath, chest up and arms open, then let out. Second Wind, Mana Surge.
local BREATH = {waist = {14, 0, 0}, neck = {28, 0, 0}, rs = {26, 0, 32}, ls = {26, 0, -32}, rootY = 0.12}
def("Breath", 1.25, {
	{0, {}}, {0.35, BREATH}, {0.65, BREATH},
	{0.95, {waist = {-8, 0, 0}, neck = {-8, 0, 0}, rs = {6, 0, 8}, ls = {6, 0, -8}, rootY = -0.08}},
	{1.25, {}},
})

-- SCOUT: the free hand shading the eyes, looking out over the field. Eagle Eye.
local SCOUT = {ls = {150, 0, 46}, neck = {8, 0, 0}, waist = {4, 0, 0}}
def("Scout", 1.3, {
	{0, {}}, {0.25, SCOUT}, {1.0, SCOUT}, {1.3, {}},
}, function(t, p)
	p.neck[2] += 18 * math.sin((t - 0.25) * 4) * window(t, 0.25, 1.0, 0.15)
end)

-- CAST: the free hand thrust out at the target, the body turned behind it. Bolts, hexes,
-- chains, a circle where you aim.
local CAST = {ls = {94, 0, -2}, rs = {22, 0, 22}, waist = {0, -16, 0}, neck = {0, 14, 0}}
def("Cast", 0.95, {
	{0, {}},
	{0.1, {ls = {50, 0, 20}, waist = {0, 8, 0}}},
	{0.22, CAST}, {0.6, CAST}, {0.95, {}},
})

-- CONJURE: both hands raised forward, the weapon up between them. Familiars, domes, surges.
local CONJURE = {rs = {132, 0, 22}, ls = {132, 0, -24}, blade = {0, 1, 0.1}, neck = {16, 0, 0}, waist = {6, 0, 0}}
def("Conjure", 1.25, {
	{0, {}}, {0.3, CONJURE}, {0.85, CONJURE}, {1.25, {}},
}, tremble(0.3, 0.85, 2))

-- SKY: the hand raised to the sky, then swept down at where it'll fall. Starfall, a rain of arrows.
def("Sky", 1.3, {
	{0, {}},
	{0.3, {ls = {176, 0, -8}, rs = {30, 0, 22}, neck = {32, 0, 0}, waist = {10, 0, 0}}},
	{0.6, {ls = {176, 0, -8}, rs = {30, 0, 22}, neck = {32, 0, 0}, waist = {10, 0, 0}}},
	{0.8, {ls = {96, 0, 0}, rs = {20, 0, 20}, neck = {0, 0, 0}, waist = {-8, 0, 0}}},
	{1.0, {ls = {92, 0, 0}, rs = {20, 0, 20}, waist = {-6, 0, 0}}},
	{1.3, {}},
})

-- SLAM: both hands up, the blade overhead, then driven down into the ground, crouched over it.
-- Thunder Slam, Consecrate.
local SLAM = {rs = {58, 0, -10}, ls = {54, 0, 12}, plantW = 1, waist = {-28, 0, 0}, neck = {-10, 0, 0}, rootY = -0.5}
def("Slam", 1.3, {
	{0, {}},
	{0.25, {rs = {172, 0, -8}, ls = {162, 0, 8}, blade = {0, 1, 0.2}, neck = {22, 0, 0}, waist = {12, 0, 0}, rootY = 0.12}},
	{0.4, SLAM}, {0.9, SLAM}, {1.3, {}},
})

-- SPIN: arms out, one whole turn, the blade flat outward. Whirlwind.
local SPIN = {rs = {80, 0, 72}, ls = {80, 0, -72}, blade = {1, 0, -0.2}, waist = {-6, 0, 0}}
def("Spin", 0.85, {
	{0, {}}, {0.12, SPIN}, {0.62, SPIN}, {0.85, {}},
}, function(t, p)
	local k = math.clamp((t - 0.1) / 0.5, 0, 1)
	p.root = {0, 360 * k * k * (3 - 2 * k), 0}
end)

-- LUNGE: low and forward, the blade levelled ahead, the free arm back. Dashes.
local LUNGE = {waist = {-26, 0, 0}, rs = {96, 0, -10}, blade = {0, 0, -1}, ls = {-36, 0, -12}, neck = {16, 0, 0}, rootY = -0.2}
def("Lunge", 0.8, {
	{0, {}}, {0.1, LUNGE}, {0.5, LUNGE}, {0.8, {}},
})

-- LEAP: a crouch to spring from, then arms up and knees tucked. Skybound, Levitate.
local LEAP = {rs = {166, 0, 20}, ls = {166, 0, -20}, neck = {20, 0, 0}, waist = {10, 0, 0}, rh = {50, 0, 0}, lh = {22, 0, 0}, blade = {0, 1, 0.3}}
def("Leap", 1.25, {
	{0, {}},
	{0.12, {rootY = -0.4, waist = {-16, 0, 0}, rs = {-24, 0, 14}, ls = {-24, 0, -14}}},
	{0.32, LEAP}, {0.9, LEAP}, {1.25, {}},
})

-- VANISH: the cloak swept across the face, low. Stealth, smoke, shadowstep.
local VANISH = {ls = {108, 0, 56}, rs = {-18, 0, 20}, waist = {-18, 0, 0}, neck = {-14, -10, 0}, rootY = -0.3}
def("Vanish", 0.95, {
	{0, {}}, {0.12, {ls = {60, 0, -50}}}, {0.3, VANISH}, {0.62, VANISH}, {0.95, {}},
})

-- NOCK: the string hand back over the shoulder to the quiver, then the charmed arrow drawn
-- forward across the bow. Enchanted arrows.
local NOCK = {ls = {94, 0, 40}, rs = {84, 0, -30}}
def("Nock", 1.0, {
	{0, {}},
	{0.2, {ls = {166, 0, -6}, rs = {60, 0, -20}, neck = {6, -14, 0}}},
	{0.42, NOCK}, {0.7, NOCK}, {1.0, {}},
})

-- THROW: a snap up behind the head and over, the body turning through it.
def("Throw", 0.65, {
	{0, {}},
	{0.07, {rs = {170, 0, 12}, ls = {60, 0, -12}, waist = {0, 18, 0}, neck = {0, -8, 0}}},
	{0.2, {rs = {70, 0, -24}, ls = {10, 0, -20}, waist = {-14, -14, 0}, neck = {0, 8, 0}}},
	{0.34, {rs = {66, 0, -22}, ls = {10, 0, -20}, waist = {-10, -10, 0}}},
	{0.65, {}},
})
PowerPoses.THROW = "PwThrow"

-- which a power plays: its own (Catalog ▸ Powers `pose`), else by what it does
local BY_KIND = {imbue = "Ignite", shout = "Roar", dash = "Lunge", leap = "Leap", stealth = "Vanish", summon = "Conjure", arrows = "Nock"}
function PowerPoses.gestureFor(d)
	if not d then return nil end
	if d.pose then return "Pw" .. d.pose end
	local k = d.kind
	local g = BY_KIND[k]
	if not g then
		if k == "zone" then
			g = d.at == "aim" and (d.arrows and "Sky" or "Cast") or (d.dome and "Conjure" or (d.smoke and "Vanish" or "Slam"))
		elseif k == "spell" then
			local sk = d.spell and d.spell.kind
			g = sk == "nova" and ((d.spell.shove or 0) > 0 and "Spin" or "Slam") or (sk == "blink" and "Vanish") or (sk == "meteor" and "Sky") or "Cast"
		elseif k == "buff" then
			local m = d.mods or {}
			if d.ultimate then g = "Surge"
			elseif d.instant then g = "Breath"
			elseif m.taken or m.unflinching or d.barrier then g = "Brace"
			elseif (m.speed or 1) > 1 or m.dodgeCost then g = "Haste"
			else g = "Conjure" end
		else
			g = "Cast"
		end
	end
	return "Pw" .. g
end

function PowerPoses.play(char, id, startedAt)
	if not (char and id and Emotes.has(id)) then return false end
	return Emotes.play(char, id, startedAt)
end

return PowerPoses
