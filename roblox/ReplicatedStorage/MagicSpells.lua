--[[ MAGIC SPELLS — the Mage's spells (a staff's Config lists which it casts;
     Combat ▸ MagicServer casts them, ReplicatedStorage ▸ MagicFX draws them,
     Combat ▸ MagicClient picks and aims them). Balanced against steel: a Mage
     has little health and no armor, every spell costs mana and takes a moment
     to cast (a hit while casting breaks it), and bolts fly slow enough to dodge.

       name, glyph (the spell bar's symbol), desc
       mana       cost (MAX_MANA 100, back MANA_REGEN a second once you stop casting)
       cast       seconds of casting before it goes off (the magic circle, the voice)
       cooldown   seconds after it goes off before it can be cast again
       kind       bolt (a projectile) · chain (lightning to whoever's aimed at, leaping on)
                  · nova (a burst round you) · heal (you, or the ally aimed at)
       color, glow          its colours (a spell skin may change them: MagicFX)
       … and its own numbers below ]]

local C = Color3.fromRGB

local S = {}
S.MAX_MANA = 100
S.MANA_REGEN = 11          -- a second…
S.REGEN_DELAY = 1.1        -- …once this long has passed since the last cast
S.WARD = {absorb = 0.7, cone = 70, manaPerDamage = 1.0, walk = 0.75}   -- the Ward (right mouse): frontal hits

S.Firebolt = {
	name = "Firebolt", glyph = "🔥", kind = "bolt",
	mana = 16, cast = 0.42, cooldown = 0.55,
	speed = 120, range = 280, radius = 0.7, damage = 18, headMult = 1.5,
	burn = {dps = 3, time = 3}, splash = 4, splashDamage = 6,
	color = C(255, 120, 40), glow = C(255, 214, 120),
	desc = "A bolt of fire that burns for three seconds and splashes where it lands.",
}
S.ChainLightning = {
	name = "Chain Lightning", glyph = "⚡", kind = "chain",
	mana = 28, cast = 0.6, cooldown = 3,
	range = 48, width = 1.6, damage = 14, chain = 1, chainRange = 14, chainDamage = 9,
	color = C(150, 210, 255), glow = C(235, 248, 255),
	desc = "Lightning to whoever you aim at, leaping to one more nearby. You can't dodge it: just don't be there.",
}
S.FrostNova = {
	name = "Frost Nova", glyph = "❄", kind = "nova",
	mana = 34, cast = 0.3, cooldown = 7,
	radius = 12, damage = 8, slow = 0.45, slowTime = 2.5,
	color = C(170, 230, 255), glow = C(240, 252, 255),
	desc = "A ring of ice bursts out round you: damage and a heavy slow. For when they get too close.",
}
S.Mend = {
	name = "Mend", glyph = "✚", kind = "heal",
	mana = 38, cast = 0.85, cooldown = 9,
	range = 42, width = 2, heal = 32, healTime = 2,
	color = C(140, 255, 150), glow = C(230, 255, 230),
	desc = "Heals you, or the ally you're aiming at, over two seconds.",
}

S.ORDER = {"Firebolt", "ChainLightning", "FrostNova", "Mend"}
return S
