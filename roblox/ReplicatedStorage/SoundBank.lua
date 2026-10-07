--[[ SOUND BANK — the fight's sounds, from Roblox's licensed sound library
     (Pro Sound Effects: free to use in any experience). A pool holds a few
     takes of one sound; Sounds.bank(pool, part) plays one at random (never the
     same take twice in a row) at the pool's volume, its pitch spread a little so
     repeats don't sound canned. Voices (Sounds.voice) come from the Voice pools,
     pitched per fighter so everyone keeps one voice.

       POOLS[name] = {volume, speed = {lo, hi}, near, far (roll-off, studs), cut,
                      takes = {id | {id, vol =, speed =, cut =}}}
       cut = seconds into the take where it fades out (keeps the first hit of a
             file that has several, trims a long ring)

     Which pools a weapon uses: WEAPONS below (blunt or edged; a heavy swing for
     two-handers and polearms). A Tool whose Config has its own SOUNDS[slot]
     keeps that sound for the slot. Add a take: put its id in the pool. ]]

local SoundBank = {}

SoundBank.POOLS = {
	-- SWINGS -------------------------------------------------------------
	SwingLight = {volume = 0.55, speed = {0.95, 1.12}, takes = {   -- sword swishes: one-handed blades
		9119750447, 9119749812, 9119749641,
		9126014020, 9126013811, 9126013477, 9126013644, 9126013302, 9126014082,
	}},
	SwingHeavy = {volume = 0.7, speed = {0.76, 0.9}, takes = {     -- deep whooshes: two-handers, polearms
		9120728815, 9120728883, 9120729007, 9120729005, 9120729337,
		9120729339, 9120729412, 9120729568, 9120729647,
	}},
	SwingGreat = {volume = 0.72, speed = {0.78, 0.9}, takes = {    -- big blades: the sword swishes, deeper and fuller
		9119750447, 9119749812, 9119749641,
		9126014020, 9126013811, 9126013477, 9126013644, 9126013302, 9126014082,
	}},
	SwingKick = {volume = 0.45, speed = {1.0, 1.15}, takes = {9120728815, 9120729007, 9120729339, 9120729568}},

	-- A BLOW THAT LANDS --------------------------------------------------
	HitCut = {volume = 0.8, speed = {0.9, 1.05}, takes = {         -- an edge through flesh
		{9119028728, vol = 1.1}, {9119028721, vol = 1.1},           -- sword slice, body chop
		9125619646, 9125619670, 9125619811, 9125619589, 9125619782, 9125619701,   -- wet slices
	}},
	HitStab = {volume = 0.85, speed = {0.92, 1.05}, takes = {       -- a point going in
		9116197520, 9116197517, 9116197790, 9114486901, 9114487369,
		{9119748927, cut = 0.7},                                    -- sword stab, juicy
	}},
	HitBlunt = {volume = 0.95, speed = {0.68, 0.82}, takes = {      -- a heavy head landing on a body
		9113570867, 9113568548, 9113571074,
	}},
	HitBone = {volume = 0.55, speed = {0.9, 1.1}, takes = {         -- bones giving way (blunt blows, killing blows)
		9113542765, 9113542951, 9113542948, 9113543050, 9113543057,
	}},
	HitPlate = {volume = 0.55, speed = {0.9, 1.08}, takes = {       -- plate ringing under the blow
		{9119072660}, {9119072674, cut = 0.8}, {9113157206}, {9113157053, cut = 0.8},
	}},
	HitMail = {volume = 0.45, speed = {0.95, 1.1}, cut = 0.55, takes = {   -- mail jingling
		9113759010, 9113759193, 9113759325, 9113759326,
	}},

	-- STEEL ON STEEL -----------------------------------------------------
	-- real blade-on-blade recordings (Pro Sound Effects, Weapons - Knives & Swords:
	-- two sabres fighting, sharp metallic clinks), not hammers on pipes
	Parry = {volume = 0.85, speed = {0.97, 1.1}, takes = {          -- a bright, sharp clash: the blade turned aside
		9119742980, 9119743250, 9119743392, 9119744251, 9119744452,
		9119744642, 9119744718, {9119742967, cut = 0.5}, {9119743888, cut = 0.5},
		{5763723309, vol = 0.9},
	}},
	Block = {volume = 0.8, speed = {0.82, 0.94}, takes = {          -- heavier and duller: the guard soaks the blow
		{9119747120, cut = 0.55}, {9119747138, cut = 0.6},          -- sword impacts
		{9119743802, vol = 0.9}, {9119742967, vol = 0.9, cut = 0.45}, {9119743888, vol = 0.9, cut = 0.45},
		{9119743392, speed = 0.85}, {9119744718, speed = 0.85},
	}},
	Clash = {volume = 0.6, speed = {0.95, 1.08}, cut = 0.9, takes = { -- blades meeting and scraping along (a chamber)
		9119743464, 9119743648, 9119742690, 9119744031,
	}},

	-- THE BLADE MEETS THE WORLD (two layers: the edge striking it, the surface giving)
	WallStone = {volume = 0.75, speed = {0.9, 1.08}, cut = 0.55, takes = {   -- steel on stone: a hard strike, a short ring
		9118604471, 9118604463, 9118603081, 9118604769, 9118599252, 9118600998,
	}},
	WallGrit = {volume = 0.45, speed = {0.85, 1.05}, takes = {                -- the stone: a knock and grit
		9118629282, 9118629789, 9118629291, 9118629156,
	}},
	WallWood = {volume = 0.85, speed = {0.85, 1.0}, takes = {                 -- iron biting oak: solid thunks, a slight ring
		9126266458, 9126265255, 9126267209, 9126267366, 9126266882,
	}},
	WallWoodChip = {volume = 0.4, speed = {0.95, 1.1}, cut = 0.32, takes = {9116333353, 9116333375, 9116333519}},   -- the chop
	WallMetal = {volume = 0.7, speed = {0.95, 1.1}, takes = {{9116750726}, {9116751108}, {9119072660, vol = 0.8}}},
	WallGround = {volume = 0.9, speed = {0.9, 1.05}, takes = {               -- hard chops into earth, gritty scatter
		9118688006, 9118686408, 9118686201, 9118684997, 9118687440,
		9118687051, 9118688017, 9118688358, 9118686853, 9118685591,
	}},
	WallGlass = {volume = 0.6, speed = {1.25, 1.4}, cut = 0.45, takes = {9118604471, 9118604463, 9118603081}},

	-- BODIES -------------------------------------------------------------
	KickHit = {volume = 0.9, speed = {0.85, 1.0}, takes = {9113568548, 9113571074, 9113570867}},
	BodyFall = {volume = 0.7, speed = {0.9, 1.05}, takes = {9113480917, 9113480915, 9113481039, 9113481839}},
	BodyFallArmor = {volume = 0.6, speed = {0.9, 1.05}, takes = {9113157481, 9113157625}},
	Dismember = {volume = 0.9, speed = {0.9, 1.05}, takes = {9119028728, 9119028721}},
	Impale = {volume = 0.9, speed = {0.95, 1.05}, takes = {9119748927}},
	Disarm = {volume = 0.5, speed = {0.95, 1.1}, cut = 1.4, takes = {9114006693, 9114009113}},
	Dodge = {volume = 0.35, speed = {1.0, 1.15}, takes = {9120709477}},

	-- VOICES (Sounds.voice: per-fighter pitch, never two at once) --------
	VoiceSwing = {volume = 0.5, speed = {0.97, 1.03}, far = 60, takes = {   -- efforts
		9120417141, 9120415873, 9120415958, 9120415608, 9120417632, 9120417872, 9120415788, 9120417581,
	}},
	VoiceHurt = {volume = 0.65, speed = {0.97, 1.03}, far = 70, takes = {   -- pained grunts
		9120415670, 9120416894, 9120416959, 9120416464, 9120416468, 9120416068, 9120416261,
		9125651364, 9125652675, 9125652949, 9125652139, 9125651619, 9125652427, 9125652662,
	}},
	VoiceDeath = {volume = 0.75, speed = {0.97, 1.03}, far = 90, takes = {  -- death cries and last gasps
		9125651099, 9125652466, 9125652133, 9125652943, 9125651079, 9125652963,
		9114029789, 9114029889, 9114030161, 9114029818,
	}},
	VoiceScream = {volume = 0.8, speed = {0.96, 1.03}, far = 110, takes = {   -- bleeding out: long cries of agony
		9116454870, 9116454942, 9116454961, 9116455473, 9116455235, 9116455270,
	}},
	VoiceGasp = {volume = 0.6, speed = {0.95, 1.02}, far = 60, takes = {     -- …and at the end, gasps
		9114029789, 9114029889, 9114030161, 9114029818,
	}},
}
-- kicks and a parry's effort borrow the swing efforts
SoundBank.POOLS.VoiceKick = SoundBank.POOLS.VoiceSwing
SoundBank.POOLS.VoiceParry = SoundBank.POOLS.VoiceSwing

-- how often a voice speaks up (the rest of the time the fighter keeps quiet)
SoundBank.VOICE_CHANCE = {Swing = 0.4, SwingHeavy = 0.6, Kick = 0.7, Parry = 0.3, Hurt = 0.9, Death = 1}
SoundBank.VOICE_GAP = 0.45     -- seconds: one fighter never grunts twice inside this
SoundBank.VOICE_PITCH = {0.88, 1.06}   -- the spread of fighters' voices

-- what a blade striking the world plays, by the material's family (CombatServer.clang)
SoundBank.WALL = {Stone = {"WallStone", "WallGrit"}, Wood = {"WallWood", "WallWoodChip"}, Metal = {"WallMetal"},
	Ground = {"WallGround"}, Glass = {"WallGlass"}}

-- weapons whose head lands blunt (thud and crack instead of a cut)
SoundBank.BLUNT = {Hammer = true, Mace = true, MorningStar = true, Maul = true, Quarterstaff = true}
-- two-handed SWORDS cut the air like a blade (the sword swish, deeper), not a haft's whoosh
SoundBank.GREATSWORD = {Longsword = true, Greatsword = true, Zweihander = true, Estoc = true, Executioner = true}
-- weapons that swing heavy: Catalog ▸ Weapons families TwoHanded and Polearm
local HEAVY_FAMILY = {TwoHanded = true, Polearm = true}

-- {swing = pool, hit = pool, blunt, heavy} for a weapon id
function SoundBank.classOf(weaponId)
	local heavy = false
	local ok, Catalog = pcall(function() return require(script.Parent:WaitForChild("Catalog")) end)
	local w = ok and Catalog.WEAPON and Catalog.WEAPON[weaponId]
	if w then heavy = HEAVY_FAMILY[w.family] == true end
	local blunt = SoundBank.BLUNT[weaponId] == true
	local swing = SoundBank.GREATSWORD[weaponId] and "SwingGreat" or (heavy and "SwingHeavy" or "SwingLight")
	return {swing = swing, hit = blunt and "HitBlunt" or "HitCut", blunt = blunt, heavy = heavy}
end

return SoundBank
