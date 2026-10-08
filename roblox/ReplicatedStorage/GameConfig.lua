--[[ GAME CONFIG — the one file that describes the GAME around the combat:
     places, game modes and their maps, classes. Server and client both read it.

     ONE PLACE, MANY SERVERS. A server never changes mode:
       • a PUBLIC server (what Roblox puts you in from the game page) is the
         HUB — the courtyard and the menu;
       • every match is a RESERVED server of this same place
         (TeleportService:ReserveServer), told its mode / access / name by
         the teleport data of its first arrival, and it runs that forever.
     PLAY joins a public match server with room or reserves a fresh one;
     RETURN TO HUB teleports to the place with no code, i.e. a public server.
     Reserved servers can only be entered with their access code, which lives
     in HubServer's registry — never on the Roblox page — so ACCESS is ours:
       Public   listed in the browser, anyone joins
       Friends  unlisted; friends of someone inside may join (custom lobbies)
       Locked   only the user ids the server was made for (ranked matches)
     Studio has no teleports: it starts in STUDIO_MODE and PLAY switches the
     mode locally so everything can still be tested.

     MODES: each is a plugin in ServerScriptService.Game.Modes/<id>. `maps`
     names Models in ServerStorage.Maps (see MapLoader for what a map needs).

     DOORS: the four cards on the Play screen — Courtyard (hub), Tiltyard
     (training), Warfront (big battles, modes rotate by vote), The Lists
     (arena brackets, casual or ranked). Each names the mode(s) its servers
     run and the access level of those servers.

     CLASSES: a class is a WEIGHT (Light / Medium / Heavy — stats in
     Catalog ▸ Weights) plus a saved look (pieces, colors, weapons; see
     Catalog). `weapons` is "any" or a list of weapon ids from Catalog ▸ Weapons. ]]

local GameConfig = {}

GameConfig.STUDIO_MODE = "Hub"   -- what Studio starts in (live: public = Hub, reserved = teleport data)
GameConfig.ACCESS = {Public = "public", Friends = "friends only", Locked = "locked"}

-- the Play screen's doors
GameConfig.DOORS = {
	Courtyard = {name = "Courtyard", mode = "Hub",      access = "Public",  hub = true,
		blurb = "Talk, show off, hit the dummies, duel in the ring."},
	Tiltyard  = {name = "Tiltyard",  mode = "Tiltyard", access = "Friends", maxPlayers = 3,
		blurb = "Your own yard, you and your party. Drills and dummies."},
	Warfront  = {name = "Warfront",  modes = {"Siege", "TDM", "KOTH", "FFA", "LTS"}, access = "Public", vote = true,
		blurb = "The big fight. The mode changes between rounds by vote."},
	Horde     = {name = "Horde",     mode = "Horde",    access = "Friends", maxPlayers = 6,
		blurb = "You and your party against waves of bots. Hold out as long as you can."},
	Lists     = {name = "The Lists", mode = "Lists",    access = "Locked",  brackets = {"1v1", "2v2", "3v3"},
		blurb = "1v1, 2v2, 3v3. Casual or ranked. Honor rules."},
}
GameConfig.DOOR_ORDER = {"Courtyard", "Tiltyard", "Warfront", "Horde", "Lists"}
GameConfig.PARTY_MAX = 3

GameConfig.MODES = {
	Tiltyard = {
		name = "Training Yard", category = "Training", teams = 0, maxPlayers = 3,
		description = "The training yard: the Drill Master's lessons, straw dummies, and bots to spar in the ring.",
		maps = {"TrainingYard"}, roundLength = 0, intermission = 0, hidden = true,
		pvp = false,   -- players can't hurt each other here: dummies and bots only
	},
	Lists = {
		name = "The Lists", category = "Arena", teams = 2, maxPlayers = 6, minPlayers = 2,
		description = "Best of 5 rounds, no respawns, one on one means one on one.",
		maps = {"RoseCourt", "Sandpit", "Colosseum", "Bloodpit", "Moonring", "Dustbowl", "Thornpit", "Mirepit", "Abbeyfield", "Blackwater"}, roundLength = 90, intermission = 6, respawnDelay = 0, roundsToWin = 3, hidden = true,
	},
	Hub = {
		name = "Hub", category = "Hub", teams = 0, maxPlayers = 40,
		description = "The courtyard: walk around, talk, hatch eggs, show off. Pick a mode to fight.",
		maps = {"Courtyard"}, roundLength = 0, intermission = 0, hidden = true,
		pvp = false,   -- a place to talk: no fighting
	},
	FFA = {
		name = "Free-for-All", category = "Battlefield", teams = 0, maxPlayers = 24, minPlayers = 1,
		description = "Everyone for themselves. Most kills when the clock runs out wins.",
		maps = {"Sandpit", "Millfield", "Highbridge", "Colosseum", "Bloodpit", "Moonring", "Dustbowl", "Cinderfall", "Duneshrine", "HollowGrove", "Harvestvale", "Thornpit"}, roundLength = 5 * 60, intermission = 15, respawnDelay = 4,
		botFill = 8,   -- fighters on the field, bots making up the numbers (Game ▸ BotFill)
	},
	Duel = {
		name = "Duel Yard", category = "Arena", teams = 0, maxPlayers = 12, minPlayers = 1,
		description = "Honor rules: one on one. Stay out of other people's fights.",
		maps = {"RoseCourt", "Sandpit", "Millfield", "Colosseum", "Bloodpit", "Moonring", "Dustbowl", "Thornpit", "Mirepit", "Abbeyfield", "Cinderfall"}, roundLength = 6 * 60, intermission = 15, respawnDelay = 3,
		botFill = 4,
	},
	TDM = {
		name = "Team Deathmatch", category = "Battlefield", teams = 2, maxPlayers = 32, minPlayers = 2,
		description = "Two armies, one ticket pool each. Bleed theirs dry first.",
		maps = {"Highbridge", "Millfield", "Sandpit", "RoseCourt", "Abbeyfield", "Blackwater", "Harvestvale", "Frosthollow", "Marshfen", "Redgorge", "Mistbridge", "Cinderfall"}, roundLength = 8 * 60, intermission = 15, respawnDelay = 6,
		tickets = 60, waveSpawn = 8, botFill = 12,
	},
	LTS = {
		name = "Last Team Standing", category = "Battlefield", teams = 2, maxPlayers = 24, minPlayers = 2,
		description = "No respawns. Win the round by wiping the other side. First to 4 rounds.",
		maps = {"Highbridge", "Sandpit", "Millfield", "Colosseum", "Abbeyfield", "Blackwater", "Redgorge", "Mistbridge", "Duneshrine", "Pinewatch", "Bloodpit", "Mirepit"}, roundLength = 3 * 60, intermission = 12, respawnDelay = 0,
		roundsToWin = 4, botFill = 8,
	},
	Horde = {
		name = "Horde", category = "Horde", teams = 0, maxPlayers = 6, minPlayers = 1,
		description = "You and your party against waves of bots, bigger and better trained each time; every fifth wave brings a Warlord. The fallen come back between waves.",
		maps = {"Wildwood", "Colosseum", "Ravenhold", "Stormbreak", "HollowGrove", "Pinewatch", "Marshfen", "Cinderfall", "Bloodpit", "Frosthollow"}, roundLength = 0, intermission = 15, respawnDelay = 3, hidden = true,
		pvp = false,   -- the party can't hurt each other; the bots can hurt you
	},
	Siege = {
		name = "Siege", category = "Objective", teams = 2, maxPlayers = 32, minPlayers = 2,
		description = "Attackers push the ram, break the gate and take the castle stage by stage. Defenders hold until the clock runs out. Every stage taken adds time; sides swap each round.",
		maps = {"Frostgate", "Emberkeep", "Sunspire", "Thornwall", "Mistmoor", "Greenhollow", "Stormhold", "Ashenford", "Rimeholt", "Blossomgate"}, roundLength = 5 * 60, intermission = 15, respawnDelay = 3,
		waveSpawn = 10,   -- reinforcements come in waves (after the first moments of a round)
		botFill = 12,
		-- the attackers' side of it, over the map's own stage numbers (Map ▸ Objectives):
		-- time a stage adds ×, ram speed ×, gate blows ×, capture time ×, champion health ×
		attack = {addTime = 1.3, ramSpeed = 1.3, gateHits = 0.8, captureTime = 0.75, champion = 0.75},
	},
	KOTH = {
		name = "King of the Hill", category = "Battlefield", teams = 2, maxPlayers = 32, minPlayers = 2,
		description = "Hold the hill. Points tick for the team that owns it.",
		maps = {"Millfield", "Colosseum", "Harvestvale", "Frosthollow", "Marshfen", "Duneshrine", "Cinderfall", "HollowGrove", "Pinewatch", "Abbeyfield", "Moonring"}, roundLength = 8 * 60, intermission = 15, respawnDelay = 6, botFill = 10,
		pointsToWin = 200, waveSpawn = 8,
	},
}
-- a map's name on screen (the key is its name in ServerStorage ▸ Maps)
GameConfig.MAP_TITLES = {TrainingYard = "The Training Yard", Courtyard = "The Courtyard", Frostgate = "Frostgate",
	Sandpit = "The Sandpit", Highbridge = "Highbridge", Millfield = "Millfield", Colosseum = "The Colosseum", RoseCourt = "The Rose Court",
	Wildwood = "The Wildwood", Ravenhold = "Ravenhold", Stormbreak = "Stormbreak",
	-- the themed maps (Build ▸ MapForge)
	Emberkeep = "Emberkeep", Sunspire = "Sunspire", Thornwall = "Thornwall", Mistmoor = "Mistmoor", Greenhollow = "Greenhollow",
	Stormhold = "Stormhold", Ashenford = "Ashenford", Rimeholt = "Rimeholt", Blossomgate = "Blossomgate",
	Bloodpit = "The Bloodpit", Moonring = "Moonring", Dustbowl = "The Dustbowl", Thornpit = "Thornpit", Mirepit = "Mirepit",
	Abbeyfield = "Abbeyfield", Blackwater = "Blackwater", Harvestvale = "Harvestvale", Frosthollow = "Frosthollow", Marshfen = "Marshfen",
	Redgorge = "Redgorge", Mistbridge = "Mistbridge", Cinderfall = "Cinderfall", Duneshrine = "Duneshrine", HollowGrove = "Hollow Grove", Pinewatch = "Pinewatch"}
function GameConfig.mapTitle(key) return GameConfig.MAP_TITLES[key] or key end

-- how many fighters (players and bots together) a map suits: {fewest, most}. A
-- match picks among the maps that suit its numbers, and bots never fill a map past
-- its most (Game ▸ GameServer, BotFill). A map not listed suits anything
GameConfig.MAP_FIGHTERS = {
	RoseCourt = {2, 6},                                  -- a garden court: 1v1 to 3v3
	Colosseum = {2, 12}, Bloodpit = {2, 12}, Moonring = {2, 12}, Dustbowl = {2, 12}, Thornpit = {2, 12}, Mirepit = {2, 12},
	Sandpit = {2, 16},
	Highbridge = {4, 20},
	Abbeyfield = {6, 24}, Blackwater = {6, 24}, Redgorge = {6, 24}, Mistbridge = {6, 24},
	Millfield = {8, 32}, Harvestvale = {8, 32}, Frosthollow = {8, 32}, Marshfen = {8, 32},
	Cinderfall = {8, 32}, Duneshrine = {8, 32}, HollowGrove = {8, 32}, Pinewatch = {8, 32},
	Frostgate = {8, 40}, Emberkeep = {8, 40}, Sunspire = {8, 40}, Thornwall = {8, 40}, Mistmoor = {8, 40},
	Greenhollow = {8, 40}, Stormhold = {8, 40}, Ashenford = {8, 40}, Rimeholt = {8, 40}, Blossomgate = {8, 40},
}
function GameConfig.mapFighters(key)
	local r = GameConfig.MAP_FIGHTERS[key]
	if r then return r[1], r[2] end
	return 1, math.huge
end
-- 0 a map that suits this many players with this many bots wanted (bots fill to
-- its most), 1 the players fit but the bots would be cut back, 2 too many players
function GameConfig.mapFit(key, players, bots)
	local lo, hi = GameConfig.mapFighters(key)
	if players > hi then return 2 end
	local fighters = math.max(players, math.min(bots or 0, hi))
	if fighters < lo then return 1 end
	return (bots or 0) > hi and 1 or 0
end

-- order on the Play tab
GameConfig.MODE_ORDER = {"Siege", "FFA", "Duel", "TDM", "LTS", "KOTH"}

GameConfig.TEAMS = {
	A = {name = "Crown", color = BrickColor.new("Bright blue"), rgb = Color3.fromRGB(70, 110, 220)},
	B = {name = "Iron",  color = BrickColor.new("Bright red"),  rgb = Color3.fromRGB(200, 60, 50)},
}

-- primary / secondary: the weapons a class starts with (free ones; the player
-- changes them in LOADOUT)
GameConfig.CLASSES = {
	Knight   = {name = "Knight",   weight = "Heavy",  armorType = "Heavy",  weapons = "any", primary = "Greatsword", secondary = "Hammer",
		description = "Plate from head to toe: the most health and armor. Slow, short of breath (less stamina, slower to get it back) and clumsy, costly dodges."},
	Footman  = {name = "Footman",  weight = "Medium", armorType = "Medium", weapons = "any", primary = "Spear", secondary = "Shortsword",
		description = "Mail and gambeson. The all-rounder — quick enough, tough enough."},
	-- the Archer: a bow or a crossbow and a one-handed sidearm. The lightest of all
	-- (Light pieces, then health / prot / speed on top: LoadoutServer)
	-- (unlock: the Archer and the Mage open at level 5; the Training Yard teaches each:
	-- Catalog ▸ Drills, the Bowmaster's and the Magister's lessons)
	Archer   = {name = "Archer",   weight = "Light",  armorType = "Light",  weapons = "any", primary = "Bow", secondary = "Shortsword",
		ranged = true, health = -15, prot = 0, speed = 1.04, unlock = {level = 5}, tutor = "archer",
		description = "A bow or a crossbow, and a sidearm for when they get close. The lightest armor of all (85 health, nothing to stop a blade): stay back, aim for the head."},
	Vanguard = {name = "Vanguard", weight = "Light",  armorType = "Light",  weapons = "any", primary = "ArmingSword", secondary = "Shortsword",
		description = "No armor to speak of: the fastest on their feet, the most stamina and the quickest to get it back, long cheap dodges. One mistake from death."},
	-- the Mage: a staff (MagicSpells: fire, lightning, frost, mending; a ward of mana) and a
	-- wand at the hip (little free spells: no blade — a staff's weak melee self is all the
	-- steel a Mage has). Robes, not armor: far
	-- less than the Archer (65 health, nothing to stop a blade),
	-- and a mana bar beside the stamina. Starts in the Apprentice's robes (starter = a set).
	Mage     = {name = "Mage",     weight = "Light",  armorType = "Light",  weapons = "any", primary = "Staff", secondary = "Wand",
		magic = true, health = -35, prot = 0, speed = 1.0, starter = "ApprenticeRobes", unlock = {level = 5}, tutor = "mage",
		description = "A staff of fire, lightning, frost and mending, and a ward that turns blows into lost mana. The least health of anyone (65, no armor), and only a wand at the hip: keep your distance, cast, and never let them close."},
}
GameConfig.CLASS_ORDER = {"Knight", "Footman", "Vanguard", "Archer", "Mage"}
-- a new player's class (the intro, their training and their first battle are fought in it)
GameConfig.DEFAULT_CLASS = "Knight"

-- the game's name and line, wherever the game introduces itself (the intro's title card)
GameConfig.GAME_NAME = "Steel & Glory"
GameConfig.TAGLINE = "Every swing is yours to aim."

-- Studio can't load saved profiles, so every Play would be a brand-new player
-- sent through basic training: there, only when this is true (test the path)
GameConfig.STUDIO_NEWCOMER = false

-- friendly fire: damage dealt to a teammate is multiplied by this (0 = none);
-- a custom server's settings may override it (Round attribute FriendlyFire)
-- THE GAME'S TEMPO: every melee attack's windup, swing and recovery run this much faster
-- (on top of each weapon's SPEED_MULT; CombatServer.attackTimes). Movement's is in
-- MovementConfig.BASE_SPEED.
GameConfig.TEMPO = {swing = 1.12}
GameConfig.FRIENDLY_FIRE = 0.5

-- custom server settings a host may choose (defaults; limits enforced server-side)
GameConfig.CUSTOM_DEFAULTS = {door = "Warfront", mode = "FFA", map = "", limit = 12, roundLength = 5 * 60,
	access = "Public", friendlyFire = true, respawns = true, groundWeapons = true, cheats = false,
	-- bots on a custom server (Game ▸ BotFill): on/off, how many fighters in all (players + bots), how good
	bots = true, botCount = 8, botSkill = "Mixed"}
GameConfig.BOT_SKILLS = {"Mixed", "Squire", "Knight", "Champion"}   -- a custom server's bot skill choices

--------------------------------------------------------------------
function GameConfig.mode(id) return GameConfig.MODES[id] end
function GameConfig.class(id) return GameConfig.CLASSES[id] end

-- is this server a reserved one (a match) rather than a public one (the Hub)?
function GameConfig.isReserved()
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

-- can this class carry this weapon (Tool name)?
function GameConfig.classAllowsWeapon(classId, weaponName)
	local c = GameConfig.CLASSES[classId]
	if not c then return false end
	if c.weapons == "any" then return true end
	for _, w in ipairs(c.weapons) do if w == weaponName then return true end end
	return false
end

return GameConfig
