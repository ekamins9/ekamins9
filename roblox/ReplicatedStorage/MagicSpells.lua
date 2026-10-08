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
S.MANA_REGEN = 7           -- a second…
S.REGEN_DELAY = 1.5        -- …once this long has passed since the last cast
S.CAST_WALK = 0.4          -- WalkSpeed while casting (and no sprint): a caster stands and delivers
S.WARD = {absorb = 0.6, cone = 70, manaPerDamage = 1.3, walk = 0.55}   -- the Ward (right mouse): frontal hits; no sprint

S.Firebolt = {
	name = "Firebolt", glyph = "🔥", kind = "bolt",
	mana = 20, cast = 0.6, cooldown = 1.0,
	speed = 110, range = 260, radius = 0.7, damage = 15, headMult = 1.5,
	burn = {dps = 2, time = 3}, splash = 4, splashDamage = 4,
	color = C(255, 120, 40), glow = C(255, 214, 120),
	desc = "A bolt of fire that burns for three seconds and splashes where it lands.",
}
S.ChainLightning = {
	name = "Chain Lightning", glyph = "⚡", kind = "chain",
	mana = 30, cast = 0.75, cooldown = 5,
	range = 48, width = 1.6, damage = 12, chain = 1, chainRange = 14, chainDamage = 7,
	color = C(150, 210, 255), glow = C(235, 248, 255),
	desc = "Lightning to whoever you aim at, leaping to one more nearby. You can't dodge it: just don't be there.",
}
S.FrostNova = {
	name = "Frost Nova", glyph = "❄", kind = "nova",
	mana = 35, cast = 0.4, cooldown = 10,
	radius = 11, damage = 6, slow = 0.4, slowTime = 2,
	color = C(170, 230, 255), glow = C(240, 252, 255),
	desc = "A ring of ice bursts out round you: damage and a heavy slow. For when they get too close.",
}
S.Mend = {
	name = "Mend", glyph = "✚", kind = "heal",
	mana = 40, cast = 1.1, cooldown = 12,
	range = 42, width = 2, heal = 25, healTime = 2,
	color = C(140, 255, 150), glow = C(230, 255, 230),
	desc = "Heals you, or the ally you're aiming at, over two seconds.",
}

S.ORDER = {"Firebolt", "ChainLightning", "FrostNova", "Mend"}
return S
