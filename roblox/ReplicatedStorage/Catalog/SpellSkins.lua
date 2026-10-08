--[[ SPELL SKINS — what a Mage's spell looks like, the way a skin dresses a weapon:
     one Mage's Firebolt is a ball of fire, another's is a dragon's head. Looks only,
     never numbers (the spell flies, hits and costs the same). A Mage picks one per
     spell they carry (LOADOUT ▸ SPELLS ▸ LOOKS); everyone sees it (MagicFX: the
     server passes the caster's skin with every spell). They come out of the ARCANA
     CRATE as copies of their own ("spell:" .. id): trade the spare, scrap it, or keep it.

       id (unique), spell (a MagicSpells id), name, rarity, crate, description
       look = {
         color, glow          the spell's two colours (the fire and its heart)
         shape                a bolt's (or a meteor's) body: orb lance wisp spark comet star
                              crescent skull phoenix dragon wyrm (MagicFX ▸ SHAPES)
         forks = true         lightning splits as it leaps · thick = k: k times as wide
         pillar = true        lightning also falls out of the sky on whoever it strikes
         petals = true        a nova's shards glow instead of ice · shard = "Glass": their material
         halo = true          a heal crowns its target with a ring of light
         smoke = true         a blink leaves smoke where you were and where you land
       } ]]

local C = Color3.fromRGB

return {
	-- RARE: new colours
	{id = "Bluefire", spell = "Firebolt", name = "Bluefire", rarity = "Rare", crate = "Arcana",
	 description = "Fire that burns blue. Hotter, they say, and nobody who's been hit by it argues.",
	 look = {color = C(60, 140, 255), glow = C(200, 235, 255)}},
	{id = "Bloodlance", spell = "IceLance", name = "Bloodlance", rarity = "Rare", crate = "Arcana",
	 description = "A shard of frozen blood. Whose, nobody asks.",
	 look = {color = C(190, 24, 36), glow = C(255, 170, 170)}},
	{id = "RedStorm", spell = "ChainLightning", name = "Red Storm", rarity = "Rare", crate = "Arcana",
	 description = "Crimson lightning that forks as it leaps.",
	 look = {color = C(255, 50, 50), glow = C(255, 205, 195), forks = true}},
	{id = "Moonmotes", spell = "ArcaneMissiles", name = "Moonmotes", rarity = "Rare", crate = "Arcana",
	 description = "Three pale motes of moonlight, curving in the dark.",
	 look = {color = C(140, 180, 255), glow = C(240, 246, 255)}},
	{id = "GoldenGrace", spell = "Mend", name = "Golden Grace", rarity = "Rare", crate = "Arcana",
	 description = "Healing light the colour of an altar's gold.",
	 look = {color = C(255, 205, 80), glow = C(255, 248, 215)}},
	{id = "PlagueFog", spell = "Miasma", name = "Plague Fog", rarity = "Rare", crate = "Arcana",
	 description = "A violet fog that smells of old graves.",
	 look = {color = C(130, 60, 170), glow = C(205, 160, 255)}},
	{id = "Quicksilver", spell = "Haste", name = "Quicksilver", rarity = "Rare", crate = "Arcana",
	 description = "Silver wind at your heels.",
	 look = {color = C(200, 210, 228), glow = C(255, 255, 255)}},
	{id = "Thornwall", spell = "Barrier", name = "Thornwall", rarity = "Rare", crate = "Arcana",
	 description = "A shell of living green: the forest stands between you and the blade.",
	 look = {color = C(80, 200, 80), glow = C(205, 255, 185)}},

	-- EPIC: a new shape
	{id = "Hellfire", spell = "Firebolt", name = "Hellfire", rarity = "Epic", crate = "Arcana",
	 description = "A burning skull in green fire, grinning all the way to its target.",
	 look = {color = C(80, 255, 90), glow = C(205, 255, 170), shape = "skull"}},
	{id = "Starfall", spell = "ArcaneMissiles", name = "Starfall", rarity = "Epic", crate = "Arcana",
	 description = "Three spinning stars, pulled out of the night sky and thrown.",
	 look = {color = C(255, 205, 80), glow = C(255, 250, 225), shape = "star"}},
	{id = "Moonblade", spell = "IceLance", name = "Moonblade", rarity = "Epic", crate = "Arcana",
	 description = "A crescent of cold moonlight, spinning edge-first.",
	 look = {color = C(160, 170, 255), glow = C(245, 245, 255), shape = "crescent"}},
	{id = "CrystalBloom", spell = "FrostNova", name = "Crystal Bloom", rarity = "Epic", crate = "Arcana",
	 description = "Not ice: pink crystal, blooming out of the ground round you like a flower.",
	 look = {color = C(255, 110, 200), glow = C(255, 225, 245), petals = true, shard = "Glass"}},
	{id = "Shadowstep", spell = "Blink", name = "Shadowstep", rarity = "Epic", crate = "Arcana",
	 description = "You go up in black smoke and step out of more of it.",
	 look = {color = C(80, 30, 120), glow = C(195, 140, 255), smoke = true}},
	{id = "Witchmark", spell = "Hex", name = "Witchmark", rarity = "Epic", crate = "Arcana",
	 description = "An old witch's curse, sickly green.",
	 look = {color = C(110, 255, 110), glow = C(225, 255, 205)}},

	-- LEGENDARY: it's alive
	{id = "Phoenix", spell = "Firebolt", name = "Phoenix", rarity = "Legendary", crate = "Arcana",
	 description = "A firebird, wings beating, trailing flame across the field.",
	 look = {color = C(255, 120, 30), glow = C(255, 232, 130), shape = "phoenix"}},
	{id = "Dragonfire", spell = "Firebolt", name = "Dragonfire", rarity = "Legendary", crate = "Arcana",
	 description = "Not a fireball: a dragon's head of fire, jaws open, roaring as it comes.",
	 look = {color = C(255, 84, 20), glow = C(255, 214, 96), shape = "dragon"}},
	{id = "Godstrike", spell = "ChainLightning", name = "Godstrike", rarity = "Legendary", crate = "Arcana",
	 description = "Golden lightning, twice as thick, and the sky strikes whoever it touches.",
	 look = {color = C(255, 205, 70), glow = C(255, 252, 230), forks = true, thick = 1.8, pillar = true}},
	{id = "Moonfall", spell = "Meteor", name = "Moonfall", rarity = "Legendary", crate = "Arcana",
	 description = "Pull a piece of the moon down on them: pale, cold and very heavy.",
	 look = {color = C(150, 190, 255), glow = C(240, 248, 255), shape = "comet"}},
	{id = "SeraphsKiss", spell = "Mend", name = "Seraph's Kiss", rarity = "Legendary", crate = "Arcana",
	 description = "Heaven's own light, and a halo for whoever it heals.",
	 look = {color = C(255, 236, 160), glow = C(255, 255, 245), halo = true}},

	-- MYTHIC: the one everyone stops to watch
	{id = "Wyrmfall", spell = "Meteor", name = "Wyrmfall", rarity = "Mythic", crate = "Arcana",
	 description = "No rock: a dragon of violet fire dives out of the sky, wings spread, and lands on them.",
	 look = {color = C(170, 60, 255), glow = C(255, 190, 255), shape = "wyrm"}},
}
