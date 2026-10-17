--[[ POWERS — every class's magic: ten each, worn in the THIRD SLOT and used with the Power
     key (E; a controller's Y; the ✦ button on a phone). A power is unlocked by CLASS LEVEL
     (Catalog ▸ Mastery: the XP you earn as that class), short, and slow to come back. Combat ▸
     Powers runs them; every one is plain data here (config only: add one by adding a line).

       id, class, name, glyph, level (class level), cooldown (s), cast (s of wind-up, 0 = instant)
       color, glow    its two colours (a power skin changes them: Catalog ▸ PowerSkins)
       aura           how it looks ON YOU while it lasts (ReplicatedStorage ▸ PowerAuras: stone,
                      juggernaut, holy, wind, tempest, night, arcane, avatar, rally, renew, glow;
                      a shout's `allies.aura` on everyone it lifts)
       pose           the gesture it plays (ReplicatedStorage ▸ PowerPoses: Ignite, Envenom, Vow,
                      Roar, Brace, Surge, Haste, Breath, Scout, Cast, Conjure, Sky, Slam, Spin,
                      Lunge, Leap, Vanish, Nock); left out, one that fits its kind
       desc           what it does, as the loadout says it
       kind and its numbers:
         imbue   the weapon in your hand burns / freezes / … for `time` s (or `hits` blows):
                 bonus (damage a hit), burn / poison {dps, time}, chill {slow, time}, shock
                 {damage, range} (arcs to the next foe), lifesteal (share of the hit healed),
                 heal (a hit), shove (studs/s), hex {weaken, expose, time}, behind (× from behind)
         buff    on you for `time` s: mods {speed, taken (× damage taken), dealt (× dealt),
                 regen (hp/s), stamina (× stamina regen), dodgeCost, dodgeCooldown, unflinching,
                 draw (× bow draw time), cast (× cast time), manaFree}; barrier (points soaked);
                 instant {stamina, heal, mana}
         spell   a Mage's kind of spell, cast free (MagicSpells kinds: bolt chain nova heal
                 meteor cloud buff hex blink): `spell` holds its numbers; aimed where you look
         shout   round you (radius): allies {time, mods} · foes {time, slow, weaken, expose,
                 damage, shove}
         dash    a rush forward (distance in `time` s); who you run into: hit {damage, shove,
                 stun}; then `after` {time, mods} on you
         leap    up and forward (up, forward studs/s); where you land: slam {radius, damage,
                 shove, slow}
         zone    a circle (radius, time) at you or where you aim (at = "aim"): allies {heal (hp/s),
                 taken} · foes {dps, slow, pull}
         summon  a familiar for `time` s: every `interval` s a bolt {damage, speed} at the
                 nearest foe within `range`
         stealth you fade for `time` s (foes lose you unless they're right on you; striking ends
                 it); decoy = a shimmering double left where you stood
         arrows  your next `count` arrows are enchanted: fx (ArrowFX look), burn, chill, shock
                 {damage, range}, explode {radius, damage}, split {n, spread}, seek (homing),
                 snare {time}, mark {expose, time}
     Ultimates (the tenth) are long, loud and rare: 90 s or more between them. ]]

local C = Color3.fromRGB

-- the elements' colours (the default look)
local FIRE   = {C(255, 120, 40),  C(255, 220, 140)}
local FROST  = {C(150, 220, 255), C(240, 252, 255)}
local STORM  = {C(150, 200, 255), C(235, 248, 255)}
local HOLY   = {C(255, 210, 90),  C(255, 248, 215)}
local VENOM  = {C(120, 220, 80),  C(210, 255, 170)}
local BLOOD  = {C(200, 30, 45),   C(255, 150, 150)}
local WIND   = {C(190, 240, 225), C(255, 255, 255)}
local SHADOW = {C(120, 70, 200),  C(215, 185, 255)}
local STONE  = {C(150, 140, 128), C(230, 220, 200)}
local ARCANE = {C(170, 120, 255), C(240, 225, 255)}
local NATURE = {C(90, 200, 90),   C(220, 255, 200)}
local function col(t) return t[1], t[2] end

local P = {}
local function add(t)
	t.color, t.glow = t.color or col(t.el or ARCANE), t.glow or (t.el or ARCANE)[2]
	t.el = nil
	-- (an imbue's wind-up is the weapon going up before it catches; an ultimate's, the gathering)
	t.cast = t.cast or (t.kind == "imbue" and 0.35) or (t.ultimate and 0.45) or 0.2
	table.insert(P, t)
end

-- the class levels the ten open at (Catalog ▸ Mastery)
local AT = {1, 2, 4, 6, 8, 10, 13, 16, 19, 22}

--------------------------------------------------------------------
--  KNIGHT — OATHS: iron and holy fire
--------------------------------------------------------------------
add{id = "Flameblade", class = "Knight", name = "Flameblade", glyph = "🔥", level = AT[1], cooldown = 28, el = FIRE,
	kind = "imbue", time = 8, element = "fire", bonus = 4, burn = {dps = 3, time = 3},
	desc = "Your blade bursts into flame for 8 seconds: every hit deals 4 more and sets them burning."}
add{id = "IronSkin", class = "Knight", name = "Iron Skin", glyph = "🛡", level = AT[2], cooldown = 34, el = STONE,
	kind = "buff", time = 6, mods = {taken = 0.7, speed = 0.9}, aura = "stone",
	desc = "Your skin turns to iron for 6 seconds: you take 30% less damage, but move a little slower."}
add{id = "ShieldOfFaith", class = "Knight", name = "Shield of Faith", glyph = "✝", level = AT[3], cooldown = 30, el = HOLY, pose = "Vow",
	kind = "buff", time = 8, barrier = 35, aura = "holy",
	desc = "A shell of golden light soaks the next 35 damage you'd take (8 seconds)."}
add{id = "WarCry", class = "Knight", name = "War Cry", glyph = "📯", level = AT[4], cooldown = 40, el = FIRE,
	kind = "shout", radius = 20, allies = {time = 6, mods = {speed = 1.15, stamina = 1.5}, aura = "rally"}, foes = {time = 2.5, slow = 0.25},
	desc = "A roar that drives your side on (faster, quicker breath, 6 s) and staggers foes close by."}
add{id = "Juggernaut", class = "Knight", name = "Juggernaut", glyph = "🐂", level = AT[5], cooldown = 40, el = STONE,
	kind = "buff", time = 6, mods = {unflinching = true, taken = 0.85}, aura = "juggernaut",
	desc = "For 6 seconds no blow makes you flinch: swing straight through theirs."}
add{id = "HolySmite", class = "Knight", name = "Holy Smite", glyph = "⚔", level = AT[6], cooldown = 24, el = HOLY, pose = "Vow",
	kind = "imbue", time = 6, hits = 1, element = "holy", bonus = 22, shove = 34, heal = 10,
	desc = "Your next hit (within 6 s) lands with heaven's weight: 22 more damage, a shove, and it heals you 10."}
add{id = "Consecrate", class = "Knight", name = "Consecrate", glyph = "☀", level = AT[7], cooldown = 45, el = HOLY, cast = 0.4,
	kind = "zone", at = "self", radius = 10, time = 6, allies = {heal = 4}, foes = {dps = 3},
	desc = "Hallow the ground round you for 6 seconds: allies there heal, foes there burn."}
add{id = "Charge", class = "Knight", name = "Charge", glyph = "🏇", level = AT[8], cooldown = 20, el = FIRE,
	kind = "dash", distance = 24, time = 0.45, hit = {damage = 12, shove = 40, stun = 0.6},
	desc = "Rush 24 studs straight ahead, bowling over (12 damage, staggered) whoever you hit."}
add{id = "ThunderSlam", class = "Knight", name = "Thunder Slam", glyph = "💥", level = AT[9], cooldown = 30, el = STORM, cast = 0.4,
	kind = "spell", spell = {kind = "nova", radius = 10, damage = 12, slow = 0.35, slowTime = 2, shove = 0},
	desc = "Strike the ground: a ring of thunder 10 studs round you, 12 damage and a heavy slow."}
add{id = "AvatarOfWar", class = "Knight", name = "Avatar of War", glyph = "👑", level = AT[10], cooldown = 100, el = HOLY, ultimate = true,
	kind = "buff", time = 10, mods = {dealt = 1.2, speed = 1.15, unflinching = true, taken = 0.85}, aura = "avatar",
	desc = "ULTIMATE. Golden wings and a crown of light for 10 seconds: 20% more damage, faster, unflinching, harder to hurt."}

--------------------------------------------------------------------
--  FOOTMAN — GAMBITS: wind and speed
--------------------------------------------------------------------
add{id = "Quickstep", class = "Footman", name = "Quickstep", glyph = "💨", level = AT[1], cooldown = 22, el = WIND,
	kind = "buff", time = 6, mods = {speed = 1.3}, aura = "wind",
	desc = "Run 30% faster for 6 seconds."}
add{id = "SecondWind", class = "Footman", name = "Second Wind", glyph = "💨", level = AT[2], cooldown = 32, el = WIND, cast = 0,
	kind = "buff", time = 3, instant = {stamina = 60}, mods = {regen = 5}, aura = "renew",
	desc = "Catch your breath at once: 60 stamina back, and 15 health over 3 seconds."}
add{id = "Windstep", class = "Footman", name = "Windstep", glyph = "🌀", level = AT[3], cooldown = 30, el = WIND,
	kind = "buff", time = 7, mods = {dodgeCost = 0, dodgeCooldown = 0.45}, aura = "wind",
	desc = "For 7 seconds your dodges cost nothing and come twice as often."}
add{id = "GaleLunge", class = "Footman", name = "Gale Lunge", glyph = "🌬", level = AT[4], cooldown = 15, el = WIND,
	kind = "dash", distance = 16, time = 0.3, after = {time = 2, imbue = {bonus = 10, element = "wind", hits = 1}},
	desc = "Ride the wind 16 studs forward; your next hit within 2 seconds deals 10 more."}
add{id = "CycloneEdge", class = "Footman", name = "Cyclone Edge", glyph = "🌪", level = AT[5], cooldown = 28, el = WIND,
	kind = "imbue", time = 7, element = "wind", shove = 30, chill = {slow = 0.2, time = 1.5},
	desc = "Wind wraps your weapon for 7 seconds: every hit throws them back and slows them."}
add{id = "Mirage", class = "Footman", name = "Mirage", glyph = "👥", level = AT[6], cooldown = 38, el = WIND,
	kind = "stealth", time = 3, decoy = true, mods = {speed = 1.2},
	desc = "Leave a shimmering double behind and fade for 3 seconds: foes lose you."}
add{id = "Tailwind", class = "Footman", name = "Tailwind", glyph = "🍃", level = AT[7], cooldown = 34, el = WIND,
	kind = "shout", radius = 22, allies = {time = 6, mods = {speed = 1.2, dodgeCost = 0.5}, aura = "wind"},
	desc = "A wind at everyone's back: your side (you too) runs 20% faster and dodges cheaper for 6 seconds."}
add{id = "Whirlwind", class = "Footman", name = "Whirlwind", glyph = "🌀", level = AT[8], cooldown = 20, el = WIND,
	kind = "spell", spell = {kind = "nova", radius = 9, damage = 9, shove = 30, slow = 0, slowTime = 0},
	desc = "Spin in a gust of steel and wind: 9 damage to everyone close, thrown back."}
add{id = "Skybound", class = "Footman", name = "Skybound", glyph = "🦅", level = AT[9], cooldown = 18, el = WIND,
	kind = "leap", up = 60, forward = 46, slam = {radius = 8, damage = 10, shove = 26},
	desc = "Leap high and far, and come down in a burst of wind (10 damage round where you land)."}
add{id = "Tempest", class = "Footman", name = "Tempest", glyph = "⛈", level = AT[10], cooldown = 95, el = STORM, ultimate = true,
	kind = "buff", time = 9, mods = {speed = 1.4, dodgeCost = 0, dodgeCooldown = 0.4, stamina = 2}, aura = "tempest",
	imbue = {element = "storm", shock = {damage = 6, range = 12}},
	desc = "ULTIMATE. Become the storm for 9 seconds: 40% faster, free dodges, double breath, and lightning leaps off every hit."}

--------------------------------------------------------------------
--  VANGUARD — TRICKS: shadow and venom
--------------------------------------------------------------------
add{id = "VenomEdge", class = "Vanguard", name = "Venom Edge", glyph = "🐍", level = AT[1], cooldown = 26, el = VENOM, pose = "Envenom",
	kind = "imbue", time = 8, element = "venom", poison = {dps = 3, time = 4},
	desc = "Coat your blade for 8 seconds: every hit poisons them (12 damage over 4 seconds)."}
add{id = "Shadowstep", class = "Vanguard", name = "Shadowstep", glyph = "🌑", level = AT[2], cooldown = 13, el = SHADOW, cast = 0,
	kind = "spell", spell = {kind = "blink", distance = 18},
	desc = "Step through the shadows up to 18 studs where you look."}
add{id = "SmokeVeil", class = "Vanguard", name = "Smoke Veil", glyph = "🌫", level = AT[3], cooldown = 34, el = SHADOW,
	kind = "zone", at = "self", radius = 9, time = 5, smoke = true, foes = {slow = 0.15},
	desc = "A cloud of black smoke round you for 5 seconds: no one sees in or out, and foes in it stumble."}
add{id = "Bloodlust", class = "Vanguard", name = "Bloodlust", glyph = "🩸", level = AT[4], cooldown = 38, el = BLOOD,
	kind = "imbue", time = 8, element = "blood", lifesteal = 0.35,
	desc = "For 8 seconds every hit heals you a third of the damage it deals."}
add{id = "MarkedForDeath", class = "Vanguard", name = "Marked for Death", glyph = "🎯", level = AT[5], cooldown = 24, el = BLOOD,
	kind = "spell", spell = {kind = "hex", range = 45, width = 2, time = 6, weaken = 0, expose = 0.25},
	desc = "Mark whoever you aim at: for 6 seconds they take 25% more from everyone."}
add{id = "PhantomBlades", class = "Vanguard", name = "Phantom Blades", glyph = "🗡", level = AT[6], cooldown = 16, el = SHADOW,
	kind = "spell", spell = {kind = "bolt", count = 3, spread = 6, speed = 120, range = 120, radius = 0.5, damage = 8, headMult = 1.5, shape = "lance"},
	desc = "Flick three spectral daggers where you aim (8 damage each)."}
add{id = "Vanish", class = "Vanguard", name = "Vanish", glyph = "👻", level = AT[7], cooldown = 42, el = SHADOW,
	kind = "stealth", time = 4, mods = {speed = 1.15}, ambush = 1.5,
	desc = "Fade from sight for 4 seconds. Striking from it ends it, with half again the damage."}
add{id = "Ambush", class = "Vanguard", name = "Ambush", glyph = "🔪", level = AT[8], cooldown = 22, el = BLOOD, pose = "Envenom",
	kind = "imbue", time = 6, hits = 1, element = "blood", bonus = 10, behind = 2,
	desc = "Your next hit (within 6 s) deals 10 more, and double from behind."}
add{id = "ShadowChain", class = "Vanguard", name = "Shadow Chain", glyph = "⛓", level = AT[9], cooldown = 20, el = SHADOW,
	kind = "spell", spell = {kind = "chain", range = 36, width = 1.6, damage = 10, chain = 1, chainRange = 12, chainDamage = 6, slowOnHit = {slow = 0.35, time = 2}},
	desc = "A chain of shadow lashes whoever you aim at and one more beside them, slowing both."}
add{id = "Nightfall", class = "Vanguard", name = "Nightfall", glyph = "🌘", level = AT[10], cooldown = 95, el = SHADOW, ultimate = true,
	kind = "buff", time = 9, mods = {speed = 1.25}, aura = "night", imbue = {element = "shadow", lifesteal = 0.2},
	pulse = {radius = 14, every = 1, foes = {weaken = 0.25, time = 1.2}},
	desc = "ULTIMATE. Night falls round you for 9 seconds: foes near you hit 25% softer, and you move faster and drink from every hit."}

--------------------------------------------------------------------
--  ARCHER — ENCHANTMENTS: arrows that do more than fly
--------------------------------------------------------------------
add{id = "FlameArrows", class = "Archer", name = "Flame Arrows", glyph = "🔥", level = AT[1], cooldown = 24, el = FIRE,
	kind = "arrows", count = 3, enchant = {fx = "fire", burn = {dps = 3, time = 3}, splash = {radius = 4, damage = 4}},
	desc = "Your next 3 arrows burn: they set whoever they hit alight and splash fire where they land."}
add{id = "FrostArrows", class = "Archer", name = "Frost Arrows", glyph = "❄", level = AT[2], cooldown = 24, el = FROST,
	kind = "arrows", count = 3, enchant = {fx = "frost", chill = {slow = 0.4, time = 2}},
	desc = "Your next 3 arrows are ice: they slow whoever they hit by 40%."}
add{id = "StormArrow", class = "Archer", name = "Storm Arrow", glyph = "⚡", level = AT[3], cooldown = 20, el = STORM,
	kind = "arrows", count = 1, enchant = {fx = "storm", shock = {damage = 12, range = 14, jumps = 2}},
	desc = "Your next arrow carries a storm: lightning leaps from whoever it hits to two more."}
add{id = "Volley", class = "Archer", name = "Volley", glyph = "🏹", level = AT[4], cooldown = 18, el = NATURE,
	kind = "arrows", count = 1, enchant = {split = {n = 3, spread = 6}},
	desc = "Your next shot splits into three arrows, fanned out."}
add{id = "BlastArrow", class = "Archer", name = "Blast Arrow", glyph = "💣", level = AT[5], cooldown = 28, el = FIRE,
	kind = "arrows", count = 1, enchant = {fx = "fire", explode = {radius = 8, damage = 18}},
	desc = "Your next arrow bursts where it lands: 18 damage 8 studs round, and a shove."}
add{id = "HuntersMark", class = "Archer", name = "Hunter's Mark", glyph = "🎯", level = AT[6], cooldown = 24, el = NATURE,
	kind = "arrows", count = 2, enchant = {fx = "holy", mark = {expose = 0.2, time = 6}},
	desc = "Your next 2 arrows mark whoever they hit: 20% more damage taken from everyone, 6 seconds."}
add{id = "SeekerArrows", class = "Archer", name = "Seeker Arrows", glyph = "🧭", level = AT[7], cooldown = 30, el = ARCANE,
	kind = "arrows", count = 3, enchant = {fx = "spirit", seek = 2.4},
	desc = "Your next 3 arrows curve after whoever's nearest your aim."}
add{id = "VineSnare", class = "Archer", name = "Vine Snare", glyph = "🌿", level = AT[8], cooldown = 24, el = NATURE,
	kind = "arrows", count = 1, enchant = {fx = "toxic", snare = {time = 1.6}},
	desc = "Your next arrow sprouts vines: whoever it hits is rooted for a moment and a half."}
add{id = "EagleEye", class = "Archer", name = "Eagle Eye", glyph = "🦅", level = AT[9], cooldown = 34, el = HOLY, pose = "Scout",
	kind = "buff", time = 8, mods = {draw = 0.6, speed = 1.1}, aura = "holy",
	desc = "For 8 seconds you draw 40% faster and move lighter."}
add{id = "ArrowRain", class = "Archer", name = "Rain of Arrows", glyph = "🌧", level = AT[10], cooldown = 85, el = NATURE, ultimate = true,
	kind = "zone", at = "aim", range = 70, radius = 11, time = 3.5, delay = 1, arrows = true, foes = {dps = 9, slow = 0.2},
	desc = "ULTIMATE. Call a storm of arrows down where you aim: everyone under it for 3.5 seconds."}

--------------------------------------------------------------------
--  MAGE — RITUALS: the great spells
--------------------------------------------------------------------
add{id = "Familiar", class = "Mage", name = "Arcane Familiar", glyph = "🦉", level = AT[1], cooldown = 40, el = ARCANE,
	kind = "summon", time = 15, interval = 1.4, range = 42, bolt = {damage = 5, speed = 110},
	desc = "Summon a familiar of living light for 15 seconds: it flies at your shoulder and shoots at the nearest foe."}
add{id = "ManaSurge", class = "Mage", name = "Mana Surge", glyph = "🔷", level = AT[2], cooldown = 45, el = ARCANE, cast = 0,
	kind = "buff", time = 0.1, instant = {mana = 50},
	desc = "Half your mana back at once."}
add{id = "TimeWarp", class = "Mage", name = "Time Warp", glyph = "⏳", level = AT[3], cooldown = 38, el = ARCANE,
	kind = "zone", at = "aim", range = 50, radius = 9, time = 5, foes = {slow = 0.5},
	desc = "Slow time where you aim for 5 seconds: foes inside move at half speed."}
add{id = "MirrorImage", class = "Mage", name = "Mirror Image", glyph = "🎭", level = AT[4], cooldown = 34, el = ARCANE,
	kind = "stealth", time = 3, decoy = true,
	desc = "Leave an image of yourself and vanish for 3 seconds."}
add{id = "WardDome", class = "Mage", name = "Ward Dome", glyph = "🔮", level = AT[5], cooldown = 50, el = ARCANE,
	kind = "zone", at = "self", radius = 9, time = 6, dome = true, allies = {taken = 0.6},
	desc = "Raise a dome of force round you for 6 seconds: everyone of yours inside takes 40% less."}
add{id = "Spellsurge", class = "Mage", name = "Spellsurge", glyph = "✴", level = AT[6], cooldown = 45, el = ARCANE,
	kind = "buff", time = 8, mods = {cast = 0.6, manaFree = true}, aura = "arcane",
	desc = "For 8 seconds your spells cast 40% faster and cost no mana."}
add{id = "GravityWell", class = "Mage", name = "Gravity Well", glyph = "🌌", level = AT[7], cooldown = 40, el = SHADOW,
	kind = "zone", at = "aim", range = 50, radius = 10, time = 4, foes = {dps = 4, pull = 14, slow = 0.3},
	desc = "Tear open a well where you aim: for 4 seconds it drags foes to its heart and grinds them."}
add{id = "Levitate", class = "Mage", name = "Levitate", glyph = "☁", level = AT[8], cooldown = 18, el = WIND,
	kind = "leap", up = 52, forward = 24, float = 1.6,
	desc = "Lift off and drift: a high, slow leap out of trouble."}
add{id = "SoulSiphon", class = "Mage", name = "Soul Siphon", glyph = "💀", level = AT[9], cooldown = 24, el = BLOOD,
	kind = "spell", spell = {kind = "chain", range = 34, width = 1.8, damage = 16, chain = 0, siphon = 1},
	desc = "Draw the life out of whoever you aim at: 16 damage, and you heal as much."}
add{id = "Starfall", class = "Mage", name = "Starfall", glyph = "🌠", level = AT[10], cooldown = 100, el = ARCANE, ultimate = true,
	kind = "spell", spell = {kind = "meteor", range = 70, radius = 8, delay = 1.0, damage = 22, edgeDamage = 9, count = 5, spread = 9, every = 0.45},
	desc = "ULTIMATE. Five stars fall where you aim, one after another."}

local BY = {}
for _, p in ipairs(P) do BY[p.id] = p end
local BYCLASS = {}
for _, p in ipairs(P) do BYCLASS[p.class] = BYCLASS[p.class] or {}; table.insert(BYCLASS[p.class], p) end

-- the class's flavour of magic, as the loadout titles it
local NAMES = {Knight = "OATHS", Footman = "GAMBITS", Vanguard = "TRICKS", Archer = "ENCHANTMENTS", Mage = "RITUALS"}

return {list = P, by = BY, byClass = BYCLASS, names = NAMES, unlockAt = AT}
