--[[ DUNGEONS — the themes a procedural dungeon is built in (Game ▸ Dungeon ▸ Generator), for
     The Depths (the roguelike) and Deadvault (the extraction raids). Config only: a new theme
     is a new entry here. The key is also its "map" name: the vote card, the title
     (GameConfig.MAP_TITLES) and the vote picture (ReplicatedStorage ▸ MapShots ▸ <key>).

       name, sub           what the vote card and the banner say
       floor / wall / trim colours and materials; accent (the theme's glow: braziers, runes)
       light               the map's lighting (Light_* attributes: MapLoader)
       props               which prop kinds dress its rooms (Generator's PROPS: coffin, bones,
                           cobweb, candles, mushroom, scaffold, goldpile, crates, carpet, painting,
                           bookcase, chandelier, icicle, snowpile, frozen, lava, anvil, chains,
                           brazier, pillar, statue, banner, barrel, table, rubble, crystal)
       monsters            the Bestiary ids that live there: `common` (any room), `ranged`
                           (archers and casters), `elite` (an elite room's champion), `boss`
       music               the score while you're down there (MusicConfig key)
       boss / bossName     the floor-3 boss (Bestiary id) and its title
       wet                 true: water everywhere (more and bigger puddles, standing water across
                           its floors, the drip of it close by) ]]

local C = Color3.fromRGB

return {
	BoneCrypt = {
		name = "The Bone Crypt", sub = "The dead don't stay down here",
		floor = C(88, 86, 82), floorMat = "Slate", wall = C(110, 106, 100), wallMat = "Cobblestone", trim = C(70, 68, 66), trimMat = "Slate",
		accent = C(120, 255, 170), torch = C(170, 240, 200),
		light = {ClockTime = 0, Ambient = C(78, 82, 90), OutdoorAmbient = C(72, 76, 84), Brightness = 0.7, FogColor = C(20, 26, 28), FogEnd = 260, FogStart = 60},
		props = {"coffin", "bones", "cobweb", "candles", "pillar", "statue", "rubble", "brazier"},
		monsters = {common = {"Skeleton", "Skeleton", "Ghoul", "SkeletonKnight", "CaveSpider"}, ranged = {"SkeletonArcher", "Necromancer"}, elite = {"DeathKnight", "Wraith"}},
		boss = "LichKing", bossName = "Malgrath, the Lich King",
	},
	GoblinWarrens = {
		name = "Goblin Warrens", sub = "Mind your purse",
		floor = C(92, 72, 52), floorMat = "Ground", wall = C(104, 82, 60), wallMat = "Slate", trim = C(82, 58, 36), trimMat = "Wood",
		accent = C(255, 170, 70), torch = C(255, 150, 60),
		light = {ClockTime = 0, Ambient = C(78, 66, 54), OutdoorAmbient = C(72, 60, 50), Brightness = 0.6, FogColor = C(30, 22, 16), FogEnd = 260, FogStart = 60},
		props = {"mushroom", "scaffold", "goldpile", "crates", "barrel", "rubble", "brazier", "banner"},
		monsters = {common = {"Goblin", "Goblin", "GoblinSpearman", "GoblinBrute", "CaveSpider", "CaveSpider"}, ranged = {"GoblinArcher", "GoblinShaman", "GoblinBomber"}, elite = {"GoblinWarboss", "Ogre", "Broodmother"}},
		boss = "GoblinKing", bossName = "Grubnak the Goblin King",
	},
	CrimsonManor = {
		name = "Crimson Manor", sub = "The Countess is receiving guests",
		floor = C(118, 74, 52), floorMat = "WoodPlanks", wall = C(92, 50, 42), wallMat = "WoodPlanks", trim = C(130, 36, 46), trimMat = "Fabric",
		accent = C(255, 70, 90), torch = C(255, 190, 120),
		light = {ClockTime = 0, Ambient = C(108, 84, 92), OutdoorAmbient = C(100, 78, 86), Brightness = 0.85, FogColor = C(40, 18, 26), FogEnd = 300, FogStart = 80},
		props = {"carpet", "painting", "bookcase", "chandelier", "candles", "table", "statue", "pillar"},
		monsters = {common = {"Thrall", "Thrall", "Vampire", "CrimsonKnight"}, ranged = {"CrimsonWitch", "Crossbowman"}, elite = {"VampireLord", "Gargoyle"}},
		boss = "Countess", bossName = "Countess Varnya",
	},
	FrozenDepths = {
		name = "The Frozen Depths", sub = "Nothing down here has been warm for a thousand years",
		floor = C(130, 160, 184), floorMat = "Glacier", wall = C(104, 134, 164), wallMat = "Ice", trim = C(86, 104, 124), trimMat = "Slate",
		accent = C(140, 220, 255), torch = C(140, 220, 255),
		light = {ClockTime = 0, Ambient = C(66, 80, 100), OutdoorAmbient = C(62, 76, 96), Brightness = 0.5, FogColor = C(24, 34, 48), FogEnd = 280, FogStart = 70},
		props = {"icicle", "snowpile", "frozen", "crystal", "pillar", "rubble", "brazier", "statue"},
		monsters = {common = {"IceWraith", "FrostSkeleton", "Yeti", "FrostSkeleton"}, ranged = {"FrostArcher", "FrostWitch"}, elite = {"FrostTroll", "IceKnight"}},
		boss = "FrostGiant", bossName = "Hrimvald the Frost Giant",
	},
	EmberForge = {
		name = "The Ember Forge", sub = "Hot work, and the workers bite",
		floor = C(58, 50, 48), floorMat = "Basalt", wall = C(74, 62, 58), wallMat = "Basalt", trim = C(40, 34, 32), trimMat = "CorrodedMetal",
		accent = C(255, 120, 40), torch = C(255, 130, 50),
		light = {ClockTime = 0, Ambient = C(84, 60, 50), OutdoorAmbient = C(80, 56, 46), Brightness = 0.6, FogColor = C(36, 16, 10), FogEnd = 260, FogStart = 60},
		props = {"lava", "anvil", "chains", "brazier", "crates", "rubble", "pillar", "crystal"},
		monsters = {common = {"Cinderling", "Cinderling", "ForgeGuard", "MagmaBrute"}, ranged = {"FlameCaster", "Crossbowman"}, elite = {"MoltenKnight", "Ogre"}},
		boss = "AshenWarlord", bossName = "Vulkar the Ashen Warlord",
	},
	DrownedHalls = {
		name = "The Drowned Halls", sub = "The sea came in, and the dead stayed",
		floor = C(70, 84, 82), floorMat = "Slate", wall = C(82, 98, 92), wallMat = "Cobblestone", trim = C(60, 76, 70), trimMat = "CorrodedMetal",
		accent = C(110, 240, 210), torch = C(150, 236, 214),
		light = {ClockTime = 0, Ambient = C(62, 82, 84), OutdoorAmbient = C(58, 78, 80), Brightness = 0.55, FogColor = C(18, 34, 36), FogEnd = 260, FogStart = 60},
		props = {"chains", "bones", "rubble", "pillar", "statue", "mushroom", "barrel", "cobweb"},
		wet = true,
		monsters = {common = {"Drowned", "Drowned", "DrownedSkeleton", "DeepGuard"}, ranged = {"DrownedArcher", "TideCaller"}, elite = {"DrownedKnight", "BrineHulk"}},
		boss = "DrownedKing", bossName = "Thalassar, the Drowned King",
	},
	HollowAbbey = {
		name = "The Hollow Abbey", sub = "The monks still keep the hours",
		floor = C(92, 86, 96), floorMat = "Slate", wall = C(112, 104, 112), wallMat = "Cobblestone", trim = C(70, 52, 76), trimMat = "Wood",
		accent = C(190, 120, 255), torch = C(214, 170, 255),
		light = {ClockTime = 0, Ambient = C(82, 74, 96), OutdoorAmbient = C(76, 68, 90), Brightness = 0.6, FogColor = C(28, 20, 38), FogEnd = 260, FogStart = 60},
		props = {"candles", "statue", "pillar", "bookcase", "banner", "carpet", "cobweb", "bones"},
		monsters = {common = {"HollowMonk", "HollowMonk", "Penitent", "AbbeyGuard"}, ranged = {"Cultist", "Crossbowman"}, elite = {"Wraith", "Gargoyle"}},
		boss = "BlackAbbot", bossName = "Malachai, the Black Abbot",
	},
}
