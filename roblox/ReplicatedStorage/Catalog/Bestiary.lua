--[[ BESTIARY — every monster (Combat ▸ Monsters spawns them: a bot on the real combat system,
     dressed and built into its shape). Config only: a new monster is a new line.

       name           over its head
       faction        Undead · Goblin · Vampire · Frost · Infernal · Elf · Orc · Human
       skill          its fighting brain (Combat ▸ Bots.SKILLS: Squire / Knight / Champion)
       class          nil (steel) · "Archer" · "Mage"
       weapon         a Tool name, or a list (one at random)
       hp             its health
       scale          its size (0.75 a goblin, 1.8 a giant)
       speed          × the walk of its weight (a goblin scurries)
       weight         Light / Medium / Heavy (its armor's, its pace)
       look           body: the shape it's built into (skeleton goblin vampire ghoul wraith orc elf
                      troll golem cinder human) · skin · eyes (a glow) · set (a crate armor set it
                      wears: <set>_Helm / _Top / _Legs) · armor ("none" bare, or its weight's
                      plain pieces) · colors (palette names) · extras (crown cape horns hood
                      tusks fangs ears beard belly crystals cracks ribs spikes wings mask antlers
                      halo collar rags claws loincloth fur warpaint drum sack goggles) · aura (ghost frost ember crimson shadow toxic holy)
       traits         reassemble (a skeleton stands back up once) · lifesteal (heals off its hits)
                      · enrage (faster under half health) · explode (bursts when it dies) ·
                      summon (calls up its kind) · frostbite (its hits chill) · burning (its hits
                      burn) · thief (Horde: steals gold) · drummer (Horde: hastens its side) ·
                      regen (mends itself)
       burst          the colour of an explode's blast (default: embers; a Bloater's is grave-green)
       power          a power it uses (Catalog ▸ Powers)
       moves          its big moves (Combat ▸ BossMoves: telegraphed slams, charges, leaps,
                      shockwaves, eruptions, rains, beams, blinks, barrages), moveFx their look ·
       hazard         a boss's second phase: the arena turns on you · phaseLine: its banner
       noHelm         a set's pieces without the helmet (the face shows)
       cloth          a palette colour for a set's unpainted cloth (worn as the monster's clothes)
       tier           1 fodder · 2 soldier · 3 elite · 4 boss (what it pays, how it's counted) ]]

local C = Color3.fromRGB
local BONE, BONE_DARK = C(222, 214, 190), C(170, 162, 140)
local GOB = C(110, 150, 70)
local PALE = C(190, 184, 202)
local ICE = C(170, 210, 236)
local ASH = C(52, 46, 44)
local ORC = C(96, 120, 76)
local ELF = C(240, 222, 196)

local M = {}
local function add(id, t) t.id = id; M[id] = t end

--------------------------------------------------------------------
--  UNDEAD (the Bone Crypt, Undead Night)
--------------------------------------------------------------------
add("Skeleton", {name = "Skeleton", faction = "Undead", skill = "Squire", weapon = {"Shortsword", "Falchion", "Cleaver", "Mace"}, hp = 70, scale = 1, weight = "Light",
	look = {body = "skeleton", skin = BONE, eyes = C(120, 255, 170), armor = "none", extras = {"ribs"}}, traits = {"reassemble"}, tier = 1})
add("SkeletonKnight", {name = "Skeleton Knight", faction = "Undead", skill = "Knight", weapon = {"ArmingSword", "WarAxe", "MorningStar"}, hp = 110, weight = "Medium",
	look = {body = "skeleton", skin = BONE_DARK, eyes = C(120, 255, 170), armor = "medium", colors = {Primary = "Jet", Secondary = "Ash", Accent = "Verdigris", Metal = "Steel"}}, traits = {"reassemble"}, tier = 2})
add("SkeletonArcher", {name = "Skeleton Archer", faction = "Undead", skill = "Squire", class = "Archer", weapon = "Bow", hp = 60,
	look = {body = "skeleton", skin = BONE, eyes = C(120, 255, 170), armor = "none", extras = {"hood", "ribs"}, colors = {Primary = "Jet"}}, traits = {"reassemble"}, tier = 1})
add("Necromancer", {name = "Necromancer", faction = "Undead", skill = "Knight", class = "Mage", weapon = "Staff", hp = 80,
	look = {body = "human", skin = C(150, 156, 150), eyes = C(150, 255, 150), set = "Necromancer", aura = "toxic"}, traits = {"summon"}, power = "SoulSiphon", moveFx = "bone", moves = {
			{kind = "eruption", name = "Grasping Bones", dmg = 14, cd = 14, count = 7},
		},
		tier = 2})
add("Ghoul", {name = "Ghoul", faction = "Undead", skill = "Squire", weapon = {"Cleaver", "Dagger"}, hp = 90, speed = 1.18, weight = "Light",
	look = {body = "ghoul", skin = C(128, 144, 120), eyes = C(200, 255, 120), set = "PeasantSkin", noHelm = true, cloth = "Ash", extras = {"claws", "ribs", "rags"}}, traits = {"regen"}, tier = 1})
add("DeathKnight", {name = "Death Knight", faction = "Undead", skill = "Champion", weapon = {"Zweihander", "Executioner", "Greatsword"}, hp = 260, scale = 1.25, weight = "Heavy",
	look = {body = "skeleton", skin = BONE_DARK, eyes = C(90, 200, 255), set = "Deathless", aura = "ghost"}, traits = {"enrage"}, power = "ThunderSlam", moveFx = "ghost", moves = {
			{kind = "sweep", name = "Death's Arc", dmg = 28, cd = 8, angle = 80, range = {0, 15}},
			{kind = "charge", name = "Grave Charge", dmg = 26, cd = 12, range = {10, 40}},
		},
		tier = 3})
add("Wraith", {name = "Wraith", faction = "Undead", skill = "Champion", class = "Mage", weapon = "Staff", hp = 180, scale = 1.15,
	look = {body = "wraith", skin = C(40, 50, 60), eyes = C(120, 220, 255), aura = "ghost", extras = {"hood"}}, traits = {"frostbite"}, power = "Shadowstep", moveFx = "ghost", moves = {
			{kind = "blink", name = "Shade Step", dmg = 22, cd = 9, range = {8, 60}},
			{kind = "nova", name = "Chill of the Grave", dmg = 18, cd = 12, radius = 5, chill = 0.3},
		},
		tier = 3})
add("LichKing", {name = "Malgrath, the Lich King", faction = "Undead", skill = "Champion", class = "Mage", weapon = "Staff", hp = 900, scale = 1.6,
	look = {body = "skeleton", skin = BONE, eyes = C(120, 255, 200), set = "Necromancer", extras = {"crown", "cape"}, aura = "ghost"}, traits = {"summon", "enrage"}, power = "Starfall", moveFx = "ghost", phaseLine = "THE DEAD ANSWER HIS CALL",
		moves = {
			{kind = "nova", name = "Soul Nova", dmg = 26, cd = 9, radius = 6},
			{kind = "eruption", name = "Grave Hands", dmg = 22, cd = 8, fx = "bone", count = 9},
			{kind = "barrage", name = "Soul Bolts", dmg = 12, cd = 7, count = 5, volleys = 3, spread = 46},
			{kind = "blink", name = "Phase Step", dmg = 26, cd = 11, range = {14, 90}},
			{kind = "beam", name = "Death Ray", dmg = 11, cd = 14, phase = 2, time = 2.6, sweep = 130},
			{kind = "eruption", name = "Field of Graves", dmg = 22, cd = 12, phase = 2, fx = "bone", lines = 3, count = 8},
			{kind = "shockwave", name = "Wail of the Dead", dmg = 20, cd = 12, phase = 2, count = 2},
		},
		hazard = {kind = "rain", name = "Falling Souls", every = 8, count = 6, dmg = 16, radius = 4, fx = "ghost"},
		tier = 4})
add("BoneColossus", {name = "The Bone Colossus", faction = "Undead", skill = "Champion", weapon = "Maul", hp = 1100, scale = 2.3, weight = "Heavy", speed = 0.85,
	look = {body = "skeleton", skin = BONE, eyes = C(120, 255, 170), armor = "none", extras = {"ribs", "spikes"}}, traits = {"enrage"}, power = "ThunderSlam", moveFx = "bone", phaseLine = "THE BONES GRIND AND RISE",
		moves = {
			{kind = "slam", name = "Colossal Slam", dmg = 44, cd = 8, radius = 11, range = {0, 24}},
			{kind = "shockwave", name = "Earthshaker", dmg = 24, cd = 10, count = 2},
			{kind = "charge", name = "Bone Avalanche", dmg = 36, cd = 11, range = {12, 55}},
			{kind = "rain", name = "Rain of Bones", dmg = 18, cd = 12, phase = 2, count = 10},
		},
		tier = 4})

--------------------------------------------------------------------
--  GOBLINS (Goblin Warrens, the Goblin Raid)
--------------------------------------------------------------------
add("Goblin", {name = "Goblin", faction = "Goblin", skill = "Squire", weapon = {"Dagger", "Shortsword", "Cleaver"}, hp = 55, scale = 0.75, speed = 1.22, weight = "Light",
	look = {body = "goblin", skin = GOB, eyes = C(255, 220, 60), set = "RoadLevy", noHelm = true, cloth = "Umber", colors = {Primary = "Umber", Secondary = "Moss"}, extras = {"ears"}}, tier = 1})
add("GoblinSpearman", {name = "Goblin Spearman", faction = "Goblin", skill = "Squire", weapon = {"Spear", "Pitchfork"}, hp = 65, scale = 0.8, speed = 1.15, weight = "Light",
	look = {body = "goblin", skin = C(96, 140, 64), eyes = C(255, 220, 60), armor = "light", colors = {Primary = "Rust", Secondary = "Umber"}, extras = {"ears"}}, tier = 1})
add("GoblinBrute", {name = "Goblin Brute", faction = "Goblin", skill = "Knight", weapon = {"Maul", "BattleAxe"}, hp = 150, scale = 1.05, weight = "Medium",
	look = {body = "goblin", skin = C(90, 128, 58), eyes = C(255, 120, 40), armor = "none", extras = {"ears", "belly", "spikes", "loincloth"}}, traits = {"enrage"}, tier = 2})
add("GoblinArcher", {name = "Goblin Archer", faction = "Goblin", skill = "Squire", class = "Archer", weapon = {"Bow", "Crossbow"}, hp = 50, scale = 0.75, speed = 1.2,
	look = {body = "goblin", skin = GOB, eyes = C(255, 220, 60), set = "RoadLevy", noHelm = true, cloth = "Moss", extras = {"ears", "hood"}, colors = {Primary = "Moss"}}, tier = 1})
add("GoblinShaman", {name = "Goblin Shaman", faction = "Goblin", skill = "Knight", class = "Mage", weapon = "Staff", hp = 70, scale = 0.8,
	look = {body = "goblin", skin = C(120, 150, 80), eyes = C(180, 120, 255), armor = "none", extras = {"ears", "mask", "antlers", "loincloth", "rags"}, aura = "toxic"}, power = "VineSnare", moveFx = "nature", moves = {
			{kind = "nova", name = "Hex Bloom", dmg = 14, cd = 14, radius = 5},
		},
		tier = 2})
add("GoblinBomber", {name = "Goblin Bomber", faction = "Goblin", skill = "Squire", weapon = "Dagger", hp = 50, scale = 0.75, speed = 1.15, weight = "Light",
	look = {body = "goblin", skin = C(116, 150, 72), eyes = C(255, 150, 40), set = "RoadLevy", noHelm = true, cloth = "Umber", colors = {Primary = "Rust", Secondary = "Umber"}, extras = {"ears", "sack", "goggles"}},
	moveFx = "ember", moves = {{kind = "barrage", name = "Firepot Toss", dmg = 12, cd = 6, count = 1, volleys = 3, spread = 0, speed = 42, burn = 4, range = {8, 60}, first = 2}},
	tier = 1})
add("GoblinThief", {name = "Goblin Thief", faction = "Goblin", skill = "Squire", weapon = "Dagger", hp = 45, scale = 0.72, speed = 1.35, weight = "Light",
	look = {body = "goblin", skin = C(100, 150, 80), eyes = C(255, 230, 80), set = "RoadLevy", noHelm = true, cloth = "Slate", extras = {"ears", "hood", "sack"}, colors = {Primary = "Jet"}}, traits = {"thief"}, tier = 1})
add("GoblinWarboss", {name = "Goblin Warboss", faction = "Goblin", skill = "Champion", weapon = {"Halberd", "Poleaxe"}, hp = 240, scale = 1.1, weight = "Heavy",
	look = {body = "goblin", skin = C(84, 120, 52), eyes = C(255, 90, 40), set = "Berserker", extras = {"ears", "spikes"}}, traits = {"enrage"}, power = "WarCry", moveFx = "gold", moves = {
			{kind = "spin", name = "Warboss Whirl", dmg = 10, cd = 11, time = 2.5, range = {0, 18}},
			{kind = "leap", name = "Boss Drop", dmg = 26, cd = 12, range = {10, 45}},
		},
		tier = 3})
add("Ogre", {name = "Ogre", faction = "Goblin", skill = "Knight", weapon = {"Maul", "Hammer"}, hp = 320, scale = 1.75, weight = "Heavy", speed = 0.85,
	look = {body = "troll", skin = C(140, 130, 96), eyes = C(255, 200, 80), armor = "none", extras = {"belly", "tusks", "loincloth", "fur"}}, traits = {"enrage"}, power = "ThunderSlam", moveFx = "stone", moves = {
			{kind = "charge", name = "Ogre Rush", dmg = 30, cd = 10, range = {8, 45}},
			{kind = "slam", name = "Club Smash", dmg = 32, cd = 9, radius = 7, range = {0, 14}},
		},
		tier = 3})
add("GoblinKing", {name = "Grubnak the Goblin King", faction = "Goblin", skill = "Champion", weapon = "Bardiche", hp = 950, scale = 1.55, weight = "Heavy",
	look = {body = "goblin", skin = C(92, 140, 60), eyes = C(255, 210, 60), set = "Corsair", extras = {"ears", "crown", "belly", "cape"}, aura = "holy"}, traits = {"summon", "enrage"}, power = "Charge", moveFx = "gold", phaseLine = "HE CALLS FOR HIS BOMBS",
		moves = {
			{kind = "leap", name = "Belly Flop", dmg = 40, cd = 9, radius = 9, range = {8, 60}},
			{kind = "charge", name = "Royal Stampede", dmg = 34, cd = 10, range = {10, 50}},
			{kind = "spin", name = "Bardiche Whirl", dmg = 12, cd = 12, time = 3, range = {0, 25}},
			{kind = "rain", name = "Gold Rush", dmg = 16, cd = 13, count = 10, radius = 4},
			{kind = "barrage", name = "Powder Kegs", dmg = 16, cd = 9, phase = 2, fx = "ember", count = 3, volleys = 3, spread = 30, speed = 45, burn = 4},
			{kind = "shockwave", name = "Kingly Stomp", dmg = 20, cd = 11, phase = 2, count = 2},
		},
		hazard = {kind = "rain", name = "Goblin Bombs", every = 7, count = 5, dmg = 16, radius = 4, fx = "ember", burn = 4},
		tier = 4})

--------------------------------------------------------------------
--  VAMPIRES (Crimson Manor)
--------------------------------------------------------------------
add("Thrall", {name = "Thrall", faction = "Vampire", skill = "Squire", weapon = {"Cleaver", "Pitchfork", "Shortsword"}, hp = 70, weight = "Light",
	look = {body = "human", skin = C(190, 178, 172), eyes = C(255, 80, 80), set = "RoadLevy", noHelm = true, cloth = "Umber", extras = {"rags"}, colors = {Primary = "Wine", Secondary = "Jet"}}, tier = 1})
add("Vampire", {name = "Vampire", faction = "Vampire", skill = "Knight", weapon = {"Rapier", "Messer", "ArmingSword"}, hp = 120, speed = 1.12, weight = "Light",
	look = {body = "vampire", skin = PALE, eyes = C(255, 40, 60), set = "GildedCourt", noHelm = true, cloth = "Jet", extras = {"cape", "fangs", "collar"}, colors = {Primary = "Wine", Secondary = "Jet", Accent = "Gold", Metal = "Jet"}, aura = "crimson"}, traits = {"lifesteal"}, tier = 2})
add("CrimsonKnight", {name = "Crimson Knight", faction = "Vampire", skill = "Knight", weapon = {"Longsword", "Glaive"}, hp = 160, weight = "Heavy",
	look = {body = "vampire", skin = PALE, eyes = C(255, 40, 60), armor = "heavy", colors = {Primary = "Blood", Secondary = "Jet", Accent = "Gold", Metal = "Jet"}}, traits = {"lifesteal"}, tier = 2})
add("CrimsonWitch", {name = "Crimson Witch", faction = "Vampire", skill = "Knight", class = "Mage", weapon = "Staff", hp = 80,
	look = {body = "vampire", skin = PALE, eyes = C(255, 60, 90), set = "Pyromancer", aura = "crimson"}, traits = {"lifesteal"}, moveFx = "crimson", moves = {
			{kind = "nova", name = "Crimson Bloom", dmg = 14, cd = 14, radius = 5},
		},
		tier = 2})
add("Crossbowman", {name = "Crossbowman", faction = "Human", skill = "Squire", class = "Archer", weapon = "Crossbow", hp = 70,
	look = {body = "human", armor = "medium", colors = {Primary = "Wine", Secondary = "Slate"}}, tier = 1})
add("VampireLord", {name = "Vampire Lord", faction = "Vampire", skill = "Champion", weapon = {"Executioner", "Estoc"}, hp = 280, scale = 1.2, speed = 1.1, weight = "Medium",
	look = {body = "vampire", skin = PALE, eyes = C(255, 30, 50), set = "Shadowveil", noHelm = true, extras = {"cape", "fangs", "collar"}, aura = "crimson"}, traits = {"lifesteal", "enrage"}, power = "Shadowstep", moveFx = "crimson", moves = {
			{kind = "blink", name = "Night Step", dmg = 24, cd = 9, range = {10, 70}},
			{kind = "barrage", name = "Bat Cloud", dmg = 9, cd = 11, count = 5, volleys = 2, spread = 50},
		},
		tier = 3})
add("Gargoyle", {name = "Gargoyle", faction = "Vampire", skill = "Knight", weapon = {"Maul", "MorningStar"}, hp = 300, scale = 1.4, weight = "Heavy", speed = 0.9,
	look = {body = "golem", skin = C(110, 112, 118), eyes = C(255, 120, 60), armor = "none", extras = {"horns", "wings"}}, power = "Juggernaut", moveFx = "stone", moves = {
			{kind = "leap", name = "Stone Dive", dmg = 30, cd = 10, range = {8, 50}},
		},
		tier = 3})
add("Countess", {name = "Countess Varnya", faction = "Vampire", skill = "Champion", weapon = "Estoc", hp = 900, scale = 1.35, speed = 1.15, weight = "Medium",
	look = {body = "vampire", skin = C(206, 198, 214), eyes = C(255, 20, 60), set = "Obsidian", noHelm = true, extras = {"cape", "crown", "fangs", "wings", "collar"}, colors = {Primary = "Blood", Secondary = "Jet", Accent = "Gold"}, aura = "crimson"}, traits = {"lifesteal", "summon", "enrage"}, power = "Nightfall", moveFx = "crimson", phaseLine = "THE MOON TURNS RED",
		moves = {
			{kind = "blink", name = "Crimson Step", dmg = 28, cd = 7, range = {10, 90}},
			{kind = "sweep", name = "Rapier Flourish", dmg = 26, cd = 6, angle = 60, range = {0, 16}},
			{kind = "barrage", name = "Bat Swarm", dmg = 10, cd = 9, count = 7, volleys = 2, spread = 60, speed = 50},
			{kind = "nova", name = "Moonlit Bloom", dmg = 24, cd = 11, radius = 6},
			{kind = "beam", name = "Crimson Lance", dmg = 11, cd = 14, phase = 2, time = 2.2, sweep = 100},
			{kind = "eruption", name = "Thorn Rose", dmg = 20, cd = 10, phase = 2, lines = 3, count = 8},
		},
		hazard = {kind = "rain", name = "Crimson Moon", every = 9, count = 6, dmg = 16, radius = 4, fx = "crimson"},
		tier = 4})

--------------------------------------------------------------------
--  FROST (the Frozen Depths)
--------------------------------------------------------------------
add("FrostSkeleton", {name = "Frost Skeleton", faction = "Frost", skill = "Squire", weapon = {"WarAxe", "Spear", "Falchion"}, hp = 80, weight = "Light",
	look = {body = "skeleton", skin = C(200, 226, 240), eyes = C(140, 220, 255), armor = "none", extras = {"crystals", "ribs"}, aura = "frost"}, traits = {"reassemble", "frostbite"}, tier = 1})
add("IceWraith", {name = "Ice Wraith", faction = "Frost", skill = "Knight", weapon = {"Glaive", "Rapier"}, hp = 100, speed = 1.12,
	look = {body = "wraith", skin = C(150, 200, 230), eyes = C(200, 245, 255), aura = "frost", extras = {"hood"}}, traits = {"frostbite"}, tier = 2})
add("Yeti", {name = "Yeti", faction = "Frost", skill = "Knight", weapon = {"Maul", "Hammer"}, hp = 220, scale = 1.45, weight = "Heavy",
	look = {body = "troll", skin = C(236, 240, 244), eyes = C(120, 200, 255), armor = "none", extras = {"horns", "belly", "fur"}}, traits = {"enrage"}, moveFx = "ice", moves = {
			{kind = "leap", name = "Avalanche Pounce", dmg = 26, cd = 11, range = {8, 45}, chill = 0.3},
		},
		tier = 2})
add("FrostArcher", {name = "Frost Archer", faction = "Frost", skill = "Knight", class = "Archer", weapon = "Bow", hp = 75,
	look = {body = "skeleton", skin = C(200, 226, 240), eyes = C(140, 220, 255), armor = "none", extras = {"hood", "crystals"}, aura = "frost"}, traits = {"frostbite"}, tier = 1})
add("FrostWitch", {name = "Frost Witch", faction = "Frost", skill = "Knight", class = "Mage", weapon = "Staff", hp = 85,
	look = {body = "human", skin = ICE, eyes = C(200, 245, 255), set = "FrostWitch", aura = "frost"}, traits = {"frostbite"}, moveFx = "ice", moves = {
			{kind = "rain", name = "Icicle Fall", dmg = 12, cd = 14, count = 3, radius = 4, chill = 0.3},
		},
		tier = 2})
add("FrostTroll", {name = "Frost Troll", faction = "Frost", skill = "Champion", weapon = {"Maul", "BattleAxe"}, hp = 360, scale = 1.8, weight = "Heavy", speed = 0.85,
	look = {body = "troll", skin = C(140, 180, 210), eyes = C(200, 245, 255), armor = "none", extras = {"crystals", "tusks", "belly", "loincloth"}, aura = "frost"}, traits = {"frostbite", "regen"}, power = "ThunderSlam", moveFx = "ice", moves = {
			{kind = "slam", name = "Frost Smash", dmg = 32, cd = 9, radius = 8, range = {0, 16}, chill = 0.4},
			{kind = "shockwave", name = "Ice Quake", dmg = 18, cd = 12, count = 1, chill = 0.4},
		},
		tier = 3})
add("IceKnight", {name = "Ice Knight", faction = "Frost", skill = "Champion", weapon = {"Longsword", "Zweihander"}, hp = 250, scale = 1.15, weight = "Heavy",
	look = {body = "human", skin = ICE, eyes = C(160, 230, 255), set = "Frostwarden", aura = "frost"}, traits = {"frostbite", "enrage"}, power = "Juggernaut", moveFx = "ice", moves = {
			{kind = "sweep", name = "Frozen Arc", dmg = 26, cd = 8, angle = 70, range = {0, 15}, chill = 0.35},
			{kind = "eruption", name = "Ice Spears", dmg = 18, cd = 11, count = 8, chill = 0.3},
		},
		tier = 3})
add("FrostGiant", {name = "Hrimvald the Frost Giant", faction = "Frost", skill = "Champion", weapon = "Maul", hp = 1150, scale = 2.4, weight = "Heavy", speed = 0.85,
	look = {body = "troll", skin = C(150, 196, 226), eyes = C(220, 250, 255), set = "Frostwarden", extras = {"crown", "crystals", "beard"}, aura = "frost"}, traits = {"frostbite", "enrage"}, power = "ThunderSlam", moveFx = "ice", phaseLine = "THE BLIZZARD HOWLS",
		moves = {
			{kind = "slam", name = "Glacier Fist", dmg = 40, cd = 8, radius = 10, range = {0, 22}, chill = 0.4},
			{kind = "shockwave", name = "Frozen Quake", dmg = 22, cd = 10, count = 2, chill = 0.4},
			{kind = "eruption", name = "Ice Spears", dmg = 22, cd = 7, count = 10, chill = 0.3},
			{kind = "rain", name = "Avalanche", dmg = 20, cd = 12, count = 9, radius = 5},
			{kind = "leap", name = "Mountain Fall", dmg = 44, cd = 12, phase = 2, radius = 11, range = {10, 70}},
			{kind = "eruption", name = "Glacial Field", dmg = 22, cd = 11, phase = 2, lines = 3, count = 9, chill = 0.3},
		},
		hazard = {kind = "rain", name = "Blizzard", every = 8, count = 7, dmg = 14, radius = 4, fx = "ice", chill = 0.3},
		tier = 4})

--------------------------------------------------------------------
--  THE FORGE (the Ember Forge)
--------------------------------------------------------------------
add("Cinderling", {name = "Cinderling", faction = "Infernal", skill = "Squire", weapon = {"Dagger", "Cleaver"}, hp = 55, scale = 0.8, speed = 1.2, weight = "Light",
	look = {body = "cinder", skin = ASH, eyes = C(255, 160, 40), armor = "none", extras = {"horns", "cracks", "loincloth"}, aura = "ember"}, traits = {"burning", "explode"}, tier = 1})
add("ForgeGuard", {name = "Forge Guard", faction = "Infernal", skill = "Knight", weapon = {"Hammer", "WarAxe", "Mace"}, hp = 130, weight = "Heavy",
	look = {body = "cinder", skin = ASH, eyes = C(255, 140, 40), armor = "heavy", colors = {Primary = "Rust", Secondary = "Jet", Accent = "Ochre", Metal = "Jet"}, extras = {"cracks"}}, traits = {"burning"}, tier = 2})
add("MagmaBrute", {name = "Magma Brute", faction = "Infernal", skill = "Knight", weapon = {"Maul", "Hammer"}, hp = 240, scale = 1.5, weight = "Heavy", speed = 0.9,
	look = {body = "golem", skin = C(62, 50, 46), eyes = C(255, 130, 30), armor = "none", extras = {"cracks", "spikes"}, aura = "ember"}, traits = {"burning", "explode"}, power = "IronSkin", moveFx = "ember", moves = {
			{kind = "slam", name = "Magma Slam", dmg = 28, cd = 10, radius = 7, range = {0, 14}, burn = 5},
		},
		tier = 2})
add("FlameCaster", {name = "Flame Caster", faction = "Infernal", skill = "Knight", class = "Mage", weapon = "Staff", hp = 80,
	look = {body = "cinder", skin = ASH, eyes = C(255, 200, 60), set = "Pyromancer", extras = {"horns"}, aura = "ember"}, traits = {"burning"}, moveFx = "ember", moves = {
			{kind = "eruption", name = "Fire Line", dmg = 14, cd = 13, count = 7, burn = 4},
		},
		tier = 2})
add("MoltenKnight", {name = "Molten Knight", faction = "Infernal", skill = "Champion", weapon = {"Greatsword", "Executioner"}, hp = 280, scale = 1.2, weight = "Heavy",
	look = {body = "cinder", skin = ASH, eyes = C(255, 120, 30), set = "Dragonscale", extras = {"cracks", "horns"}, aura = "ember"}, traits = {"burning", "enrage"}, power = "Flameblade", moveFx = "ember", moves = {
			{kind = "charge", name = "Molten Rush", dmg = 28, cd = 10, range = {8, 45}, burn = 5},
			{kind = "sweep", name = "Searing Arc", dmg = 26, cd = 8, angle = 70, range = {0, 15}, burn = 4},
		},
		tier = 3})
add("AshenWarlord", {name = "Vulkar the Ashen Warlord", faction = "Infernal", skill = "Champion", weapon = "Zweihander", hp = 1050, scale = 1.9, weight = "Heavy",
	look = {body = "cinder", skin = C(40, 34, 32), eyes = C(255, 110, 20), set = "Dragonscale", extras = {"horns", "cracks", "crown", "cape"}, aura = "ember"}, traits = {"burning", "summon", "enrage"}, power = "AvatarOfWar", moveFx = "ember", phaseLine = "THE FORGE ERUPTS",
		moves = {
			{kind = "charge", name = "Burning Charge", dmg = 34, cd = 9, burn = 6, range = {10, 50}},
			{kind = "sweep", name = "Ashen Cleave", dmg = 32, cd = 6, angle = 80, range = {0, 18}, burn = 4},
			{kind = "eruption", name = "Magma Line", dmg = 22, cd = 8, count = 10, burn = 5},
			{kind = "rain", name = "Meteor Shower", dmg = 22, cd = 12, count = 8, radius = 5, burn = 5},
			{kind = "leap", name = "Volcanic Leap", dmg = 42, cd = 11, phase = 2, radius = 10, range = {10, 70}, burn = 6},
			{kind = "shockwave", name = "Flame Wave", dmg = 22, cd = 10, phase = 2, count = 3, burn = 4},
		},
		hazard = {kind = "rain", name = "Lava Vents", every = 7, count = 6, dmg = 16, radius = 4, fx = "ember", burn = 4},
		tier = 4})

--------------------------------------------------------------------
--  ELVES (the Elven Host)
--------------------------------------------------------------------
add("ElfArcher", {name = "Elven Archer", faction = "Elf", skill = "Knight", class = "Archer", weapon = "Bow", hp = 70, speed = 1.08,
	look = {body = "elf", skin = ELF, set = "Greenwood", extras = {"ears"}}, tier = 1})
add("ElfRanger", {name = "Elven Ranger", faction = "Elf", skill = "Champion", class = "Archer", weapon = "Bow", hp = 95, speed = 1.1,
	look = {body = "elf", skin = C(226, 206, 180), set = "FalconWardens", extras = {"ears"}}, tier = 2})
add("ElfBlademaster", {name = "Elven Blademaster", faction = "Elf", skill = "Champion", weapon = {"Glaive", "Rapier", "Estoc"}, hp = 120, speed = 1.12, weight = "Light",
	look = {body = "elf", skin = ELF, set = "Moonshadow", extras = {"ears"}}, power = "GaleLunge", tier = 2})
add("ElfSpellweaver", {name = "Elven Spellweaver", faction = "Elf", skill = "Knight", class = "Mage", weapon = "Staff", hp = 80,
	look = {body = "elf", skin = ELF, set = "Druid", extras = {"ears"}, aura = "holy"}, tier = 2})
add("ElfWarden", {name = "Elven Warden", faction = "Elf", skill = "Champion", weapon = {"Glaive", "Halberd"}, hp = 260, scale = 1.2, weight = "Medium",
	look = {body = "elf", skin = C(236, 216, 186), set = "Moonshadow", extras = {"ears", "antlers"}, aura = "holy"}, traits = {"enrage"}, power = "CycloneEdge", moveFx = "nature", moves = {
			{kind = "sweep", name = "Warden's Arc", dmg = 26, cd = 8, angle = 80, range = {0, 15}},
			{kind = "eruption", name = "Thornline", dmg = 18, cd = 11, count = 8},
		},
		tier = 3})
add("ElfQueen", {name = "Sylvara, Queen of the Wood", faction = "Elf", skill = "Champion", class = "Archer", weapon = "Bow", hp = 700, scale = 1.35,
	look = {body = "elf", skin = C(244, 230, 206), set = "Phoenix", extras = {"ears", "crown", "antlers"}, aura = "holy"}, traits = {"summon"}, power = "ArrowRain", moveFx = "nature", phaseLine = "THE WOOD ITSELF RISES",
		moves = {
			{kind = "barrage", name = "Arrow Storm", dmg = 12, cd = 7, count = 7, volleys = 3, spread = 50, speed = 70},
			{kind = "rain", name = "Starfall Volley", dmg = 18, cd = 11, count = 9, fx = "holy"},
			{kind = "eruption", name = "Thornline", dmg = 20, cd = 9, lines = 2, count = 9},
			{kind = "blink", name = "Glade Step", dmg = 24, cd = 10, range = {0, 14}},
			{kind = "beam", name = "Moonbeam", dmg = 10, cd = 14, phase = 2, fx = "holy"},
		},
		hazard = {kind = "rain", name = "Falling Boughs", every = 9, count = 6, dmg = 14, radius = 4, fx = "nature"},
		tier = 4})

--------------------------------------------------------------------
--  ORCS (the Orc Warband)
--------------------------------------------------------------------
add("OrcGrunt", {name = "Orc Grunt", faction = "Orc", skill = "Knight", weapon = {"WarAxe", "Cleaver", "Mace"}, hp = 130, scale = 1.2, weight = "Medium",
	look = {body = "orc", skin = ORC, eyes = C(255, 80, 40), armor = "light", colors = {Primary = "Rust", Secondary = "Umber"}, extras = {"tusks"}}, tier = 1})
add("OrcBerserker", {name = "Orc Berserker", faction = "Orc", skill = "Champion", weapon = {"BattleAxe", "Bardiche"}, hp = 170, scale = 1.25, speed = 1.12, weight = "Light",
	look = {body = "orc", skin = C(86, 110, 66), eyes = C(255, 40, 40), armor = "none", extras = {"tusks", "spikes", "loincloth", "warpaint"}}, traits = {"enrage"}, power = "Bloodlust", moveFx = "stone", moves = {
			{kind = "spin", name = "Berserk Whirl", dmg = 9, cd = 12, time = 2.4, range = {0, 16}},
		},
		tier = 2})
add("OrcArcher", {name = "Orc Crossbow", faction = "Orc", skill = "Knight", class = "Archer", weapon = "Crossbow", hp = 110, scale = 1.15,
	look = {body = "orc", skin = ORC, eyes = C(255, 120, 40), armor = "medium", colors = {Primary = "Umber", Secondary = "Jet"}, extras = {"tusks"}}, tier = 1})
add("OrcDrummer", {name = "Orc War-Drummer", faction = "Orc", skill = "Squire", weapon = "Hammer", hp = 140, scale = 1.3, speed = 0.9, weight = "Medium",
	look = {body = "orc", skin = C(100, 124, 80), eyes = C(255, 160, 40), armor = "none", extras = {"tusks", "horns", "belly", "loincloth", "drum"}}, traits = {"drummer"}, tier = 2})
add("OrcWarchief", {name = "Gorzak the Warchief", faction = "Orc", skill = "Champion", weapon = "Poleaxe", hp = 800, scale = 1.7, weight = "Heavy",
	look = {body = "orc", skin = C(80, 104, 62), eyes = C(255, 60, 30), set = "Berserker", extras = {"tusks", "horns", "cape", "spikes"}}, traits = {"enrage", "summon"}, power = "WarCry", moveFx = "stone", phaseLine = "THE WARBAND HOWLS FOR BLOOD-PRICE",
		moves = {
			{kind = "charge", name = "Warchief's Rush", dmg = 34, cd = 9, range = {10, 50}},
			{kind = "leap", name = "Skullsplitter Leap", dmg = 40, cd = 10, radius = 9, range = {10, 60}},
			{kind = "spin", name = "Poleaxe Whirl", dmg = 12, cd = 11, time = 3, range = {0, 22}},
			{kind = "slam", name = "Earth Breaker", dmg = 38, cd = 9, radius = 9, range = {0, 20}},
			{kind = "shockwave", name = "War Stomp", dmg = 20, cd = 11, phase = 2, count = 3},
		},
		tier = 4})

--------------------------------------------------------------------
--  THE PLAGUE (Plague Night's ghouls are players, dressed by this)
--------------------------------------------------------------------
add("PlagueGhoul", {name = "Ghoul", faction = "Undead", skill = "Knight", weapon = "Cleaver", hp = 150, speed = 1.1, weight = "Light",
	look = {body = "ghoul", skin = C(118, 140, 104), eyes = C(170, 255, 90), armor = "none", aura = "toxic"}, traits = {"regen"}, tier = 2})
-- what else comes up out of the ground on Plague Night (Game ▸ Modes ▸ Plague picks them as the night deepens)
add("PlagueRunner", {name = "Plague Runner", faction = "Undead", skill = "Squire", weapon = {"Dagger", "Cleaver"}, hp = 75, speed = 1.32, weight = "Light",
	look = {body = "ghoul", skin = C(134, 152, 112), eyes = C(200, 255, 110), armor = "none", extras = {"claws", "rags"}, aura = "toxic"}, traits = {"regen"}, tier = 1})
add("PlagueBloater", {name = "Bloater", faction = "Undead", skill = "Squire", weapon = "Cleaver", hp = 190, scale = 1.3, speed = 0.82, weight = "Heavy",
	look = {body = "ghoul", skin = C(146, 156, 98), eyes = C(220, 255, 80), armor = "none", extras = {"belly", "rags"}, aura = "toxic"},
	traits = {"explode"}, burst = C(150, 230, 80), tier = 2})
add("PlagueBrute", {name = "Plague Brute", faction = "Undead", skill = "Knight", weapon = {"Maul", "BattleAxe"}, hp = 330, scale = 1.55, speed = 0.9, weight = "Heavy",
	look = {body = "ghoul", skin = C(98, 122, 90), eyes = C(170, 255, 90), armor = "none", extras = {"claws", "ribs", "spikes", "rags"}, aura = "toxic"},
	traits = {"regen", "enrage"}, tier = 3})

return M
