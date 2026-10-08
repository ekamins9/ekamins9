--[[ MAGIC SPELLS — every spell a Mage can carry. A Mage picks their ARSENAL in the
     loadout (LOADOUT ▸ SPELLS: as many as their weapon holds, Tools ▸ <Staff/Tome>
     ▸ Config.SLOTS); Combat ▸ MagicServer casts them, ReplicatedStorage ▸ MagicFX
     draws them, Combat ▸ MagicClient picks and aims them. Balanced against steel:
     a Mage has little health and no armor, every spell costs mana and takes a moment
     to cast — walking at a crawl, no sprint — and a hit breaks the cast. MANA COMES
     BACK ONLY BY MEDITATING (hold R / Y, standing still): a Mage fights from behind
     the line, then has to stop.

       name, glyph (the spell bar's symbol), desc
       mana · cast (s of casting) · cooldown (s after it goes off)
       kind      bolt (projectiles: count, spread) · chain (lightning, leaping on) ·
                 nova (a burst round you) · heal (you, or the ally aimed at) ·
                 meteor (falls where you aim, after a delay) · cloud (a lingering
                 zone where you aim) · buff (haste / barrier on you or the ally aimed
                 at) · hex (a curse on whoever you aim at) · blink (a jump through space)
       target    what the crosshair says: aim · ground · ally · self
       unlock    {free = true} or {level = N}: Catalog.unlocked decides
       color, glow   its colours (a spell skin changes them: Catalog ▸ SpellSkins)
       … and its own numbers below ]]

local C = Color3.fromRGB

local S = {}
S.MAX_MANA = 100
S.MANA_REGEN = 0           -- (none: meditate)
S.CAST_WALK = 0.2          -- WalkSpeed while casting, × the weapon's (a Tome walks faster)
S.WARD = {absorb = 0.6, cone = 70, manaPerDamage = 1.3, walk = 0.5}   -- the Staff's Ward (right mouse): frontal hits
-- MEDITATE (every magic weapon, hold R / Y): stand still and breathe; after `windup` mana
-- comes back `rate` a second. Moving (faster than `still` studs/s), casting, warding, a hit:
-- it ends. Everyone sees you sit and glow.
S.MEDITATE = {rate = 16, windup = 0.7, still = 1.5}

-- OFFENCE
S.Firebolt = {
	name = "Firebolt", glyph = "🔥", kind = "bolt", target = "aim", unlock = {free = true},
	mana = 20, cast = 0.7, cooldown = 1.1,
	speed = 110, range = 260, radius = 0.7, damage = 15, headMult = 1.5,
	burn = {dps = 2, time = 3}, splash = 4, splashDamage = 4,
	color = C(255, 120, 40), glow = C(255, 214, 120),
	desc = "A bolt of fire that burns for three seconds and splashes where it lands. Slow enough to dodge.",
}
S.IceLance = {
	name = "Ice Lance", glyph = "🧊", kind = "bolt", target = "aim", unlock = {level = 2},
	mana = 16, cast = 0.5, cooldown = 1.3,
	speed = 175, range = 220, radius = 0.45, damage = 10, headMult = 1.6, chill = {slow = 0.3, time = 1.5},
	color = C(150, 220, 255), glow = C(235, 250, 255), shape = "lance",
	desc = "A quick shard of ice: less damage than fire, but it flies fast and slows whoever it hits.",
}
S.ChainLightning = {
	name = "Chain Lightning", glyph = "⚡", kind = "chain", target = "aim", unlock = {free = true},
	mana = 30, cast = 0.85, cooldown = 5,
	range = 48, width = 1.6, damage = 12, chain = 1, chainRange = 14, chainDamage = 7,
	color = C(150, 210, 255), glow = C(235, 248, 255),
	desc = "Lightning to whoever you aim at, leaping to one more nearby. You can't dodge it: just don't be there.",
}
S.ArcaneMissiles = {
	name = "Arcane Missiles", glyph = "✨", kind = "bolt", target = "aim", unlock = {level = 4},
	mana = 24, cast = 0.8, cooldown = 3.5,
	count = 3, spread = 5, speed = 95, range = 160, radius = 0.5, damage = 6, headMult = 1.2, seek = 2.2,
	color = C(200, 120, 255), glow = C(250, 220, 255), shape = "wisp",
	desc = "Three bolts of raw magic that curve after whoever's under your crosshair.",
}
S.Meteor = {
	name = "Meteor", glyph = "🌠", kind = "meteor", target = "ground", unlock = {level = 8},
	mana = 45, cast = 1.5, cooldown = 16,
	range = 70, radius = 9, delay = 1.1, damage = 30, edgeDamage = 12, burn = {dps = 2, time = 2},
	color = C(255, 110, 30), glow = C(255, 220, 140),
	desc = "Call a burning rock down where you aim. It takes its time, so does everyone's running.",
}
S.Miasma = {
	name = "Miasma", glyph = "🦠", kind = "cloud", target = "ground", unlock = {level = 6},
	mana = 32, cast = 0.9, cooldown = 11,
	range = 55, radius = 7, time = 5, dps = 3, slow = 0.15,
	color = C(130, 230, 90), glow = C(210, 255, 160),
	desc = "A choking green cloud where you aim. It doesn't do much at once; it does a lot if they stay.",
}
S.FrostNova = {
	name = "Frost Nova", glyph = "❄", kind = "nova", target = "self", unlock = {free = true},
	mana = 35, cast = 0.4, cooldown = 10,
	radius = 11, damage = 6, slow = 0.4, slowTime = 2,
	color = C(170, 230, 255), glow = C(240, 252, 255),
	desc = "A ring of ice bursts out round you: a little damage and a heavy slow. For when they get too close.",
}
-- SUPPORT
S.Mend = {
	name = "Mend", glyph = "✚", kind = "heal", target = "ally", unlock = {free = true},
	mana = 40, cast = 1.1, cooldown = 12,
	range = 42, width = 2, heal = 25, healTime = 2,
	color = C(140, 255, 150), glow = C(230, 255, 230),
	desc = "Heals you, or the ally you're aiming at, over two seconds.",
}
S.Haste = {
	name = "Haste", glyph = "💨", kind = "buff", target = "ally", unlock = {level = 3},
	mana = 20, cast = 0.5, cooldown = 14,
	range = 42, width = 2, buff = "haste", amount = 0.25, time = 6,
	color = C(120, 220, 255), glow = C(220, 250, 255),
	desc = "You, or the ally you aim at, run a quarter faster for six seconds.",
}
S.Barrier = {
	name = "Barrier", glyph = "🛡", kind = "buff", target = "ally", unlock = {level = 7},
	mana = 30, cast = 0.6, cooldown = 16,
	range = 42, width = 2, buff = "barrier", amount = 25, time = 6,
	color = C(255, 214, 100), glow = C(255, 245, 210),
	desc = "A shell of light round you or an ally that soaks the next 25 damage (for six seconds).",
}
S.Hex = {
	name = "Hex", glyph = "☠", kind = "hex", target = "aim", unlock = {level = 9},
	mana = 26, cast = 0.75, cooldown = 13,
	range = 45, width = 1.6, time = 5, weaken = 0.25, expose = 0.15,
	color = C(180, 80, 255), glow = C(230, 190, 255),
	desc = "Curse whoever you aim at: for five seconds they deal a quarter less and take more from everyone.",
}
S.Blink = {
	name = "Blink", glyph = "🌀", kind = "blink", target = "aim", unlock = {level = 10},
	mana = 25, cast = 0.2, cooldown = 10,
	distance = 18,
	color = C(160, 140, 255), glow = C(235, 230, 255),
	desc = "Vanish and step out of the air up to 18 studs where you're looking. The way out, not the way in.",
}
-- THE WAND'S (it carries nothing else and needs no mana: a sidearm for when you're dry)
S.Spark = {
	name = "Spark", glyph = "💫", kind = "bolt", target = "aim", unlock = {free = true}, fixed = true,
	mana = 0, cast = 0.15, cooldown = 0.55,
	speed = 150, range = 120, radius = 0.35, damage = 5, headMult = 1.4,
	color = C(255, 230, 140), glow = C(255, 250, 225), shape = "spark",
	desc = "A snap of light off the wand's tip. Weak, quick, free.",
}

-- every spell a Mage can pick (the LOADOUT's order), and the starting four
S.ORDER = {"Firebolt", "IceLance", "ChainLightning", "ArcaneMissiles", "Meteor", "Miasma", "FrostNova",
	"Mend", "Haste", "Barrier", "Hex", "Blink"}
S.DEFAULT = {"Firebolt", "ChainLightning", "FrostNova", "Mend"}
for id, sp in pairs(S) do if type(sp) == "table" and sp.kind then sp.id = id end end
return S
