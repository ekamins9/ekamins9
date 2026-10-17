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
	-- WAR (Game ▸ Modes ▸ War): the big battle, armies of bots beside the players, siege engines
	War       = {name = "War", mode = "War", access = "Public", maxPlayers = 24, matchmade = true,
		blurb = "Two armies, five banners, trebuchets, volleys and battle-mages. Hold the line."},
	Warfront  = {name = "Warfront",  modes = {"Siege", "TDM", "KOTH", "FFA", "LTS"}, access = "Public", vote = true,
		blurb = "The big fight. The mode changes between rounds by vote."},
	Horde     = {name = "Horde",     mode = "Horde",    access = "Friends", maxPlayers = 6,
		blurb = "You and your party defend the camp against waves of bots: keep the fire burning, the caravan whole, the villagers safe."},
	Lists     = {name = "The Lists", mode = "Lists",    access = "Locked",  brackets = {"1v1", "2v2", "3v3"},
		blurb = "1v1, 2v2, 3v3. Casual or ranked. Honor rules."},
	-- THE ADVENTURES (the Play screen's second page). party: your party's own server ·
	-- matchmade: a public server for that mode (HubServer)
	Depths    = {name = "The Depths", mode = "Depths",  access = "Friends", maxPlayers = 4, party = true, page = 2,
		blurb = "A dungeon built fresh every run. Three floors, chests, relics, a boss at the bottom."},
	-- THE DUNGEON GAME's own world (Game ▸ Modes ▸ Tavern): Deadvault and The Depths start there
	Tavern    = {name = "The Gilded Rat", mode = "Tavern", access = "Public", maxPlayers = 24, matchmade = true, page = 2,
		blurb = "The dungeon game's own lodge: your stash, the merchants, your party, the gate down into the dark."},
	Deadvault = {name = "Deadvault", mode = "Deadvault", access = "Public", maxPlayers = 12, matchmade = true, page = 2,
		blurb = "Raid a vast dark dungeon with your party. Search it, sneak past what sleeps, get out with the loot. Die, and lose it all."},
	Crownfall = {name = "Crownfall", mode = "Crownfall", access = "Public", maxPlayers = 16, matchmade = true, page = 2,
		blurb = "A battle royale on an island built fresh every match. Drop in, loot, outlast the ring."},
	Kingslayer = {name = "Kingslayer", mode = "Kingslayer", access = "Public", maxPlayers = 16, matchmade = true, page = 2,
		blurb = "Take the crown. Kill the king to be the king. Hold it to win."},
	Plague    = {name = "Plague Night", mode = "Plague", access = "Public", maxPlayers = 16, matchmade = true, page = 2,
		blurb = "Survive until dawn. The fallen rise as ghouls and hunt the living."},
	-- THE PROLOGUE (Game ▸ Modes ▸ Prologue): a brand-new player's first minutes, on a server of their own
	Prologue = {name = "The Siege of Stormwatch", mode = "Prologue", access = "Friends", maxPlayers = 1, party = true,
		blurb = "A stormy night. The Iron Host is at the gate. Learn to fight in the middle of the battle."},
	Dragonfall = {name = "Dragonfall", mode = "Dragonfall", access = "Friends", maxPlayers = 6, party = true, page = 2,
		blurb = "You and your party against Cindermaw, the Ashen Wyrm, in its burning caldera. Ballistae to bring it down, ward stones against its fire."},
	Invasion  = {name = "Invasions", mode = "InvGoblin", modes = {"InvGoblin", "InvElf", "InvUndead", "InvOrc"}, access = "Friends", maxPlayers = 6, party = true, page = 2,
		blurb = "A themed horde: goblins after your gold, the elven host, the dead at night, an orc warband."},
}
GameConfig.DOOR_ORDER = {"Courtyard", "Tiltyard", "War", "Warfront", "Horde", "Lists"}
GameConfig.ADVENTURE_ORDER = {"Depths", "Deadvault", "Crownfall", "Invasion", "Dragonfall", "Kingslayer", "Plague"}
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
		maps = {"RoseCourt", "Sandpit", "Colosseum", "Bloodpit", "Moonring", "Dustbowl", "Thornpit", "Mirepit", "Abbeyfield", "Blackwater",
			"Redmeadow", "Ironvale", "Grimfield", "Sunfall", "Ravenfield"}, roundLength = 90, intermission = 6, respawnDelay = 0, roundsToWin = 3, hidden = true,
	},
	-- the dungeon game's lodge (Game ▸ Modes ▸ Tavern): walk about, trade, ready up
	Tavern = {
		name = "The Gilded Rat", category = "Hub", teams = 0, maxPlayers = 24,
		description = "The dungeon game's lodge: your stash, the merchants, your party, and the gate down into the dark.",
		maps = {"Tavern"}, procedural = true, roundLength = 0, intermission = 0, hidden = true, respawnDelay = 1,
		pvp = false, ownSpawn = true,
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
		description = "You and your party defend the camp against waves of bots: keep the campfire burning, the caravan whole, the villagers safe. Each wave is bigger and better trained; every fifth brings a Warlord. Lose what you're defending and the horde wins.",
		maps = {"Wildwood", "Colosseum", "Ravenhold", "Stormbreak", "HollowGrove", "Pinewatch", "Marshfen", "Cinderfall", "Bloodpit", "Frosthollow"}, roundLength = 0, intermission = 15, respawnDelay = 3, hidden = true,
		pvp = false,   -- the party can't hurt each other; the bots can hurt you
		-- what you defend on each map (Game ▸ HordeObjective: "Campfire" | "Caravan" | "Villagers";
		-- a map's own Spots ▸ HordeObjective with a Kind attribute wins), and how much it takes
		objectives = {Wildwood = "Campfire", Colosseum = "Villagers", Ravenhold = "Caravan", Stormbreak = "Villagers", HollowGrove = "Campfire",
			Pinewatch = "Campfire", Marshfen = "Caravan", Cinderfall = "Villagers", Bloodpit = "Campfire", Frosthollow = "Caravan"},
		objectiveHealth = 1500,
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
	-- THE DEPTHS (Game ▸ Modes ▸ Depths): the "maps" are the dungeon's themes (Catalog ▸ Dungeons),
	-- each run built fresh (procedural: GameServer asks the mode to build the picked one)
	Depths = {
		name = "The Depths", category = "Adventure", teams = 0, maxPlayers = 4, minPlayers = 1,
		description = "A party crawl through a dungeon built fresh every run: three floors, rooms that seal you in, chests of weapons, relics and tomes, and the theme's boss at the bottom.",
		maps = {"BoneCrypt", "GoblinWarrens", "CrimsonManor", "FrozenDepths", "EmberForge"}, procedural = true,
		roundLength = 0, intermission = 15, respawnDelay = 3, hidden = true,
		pvp = false, ownSpawn = true,
	},
	-- DEADVAULT (Game ▸ Modes ▸ Deadvault, Game ▸ Vault): an extraction raid, after Dark and Darker
	Deadvault = {
		name = "Deadvault", category = "Adventure", teams = 0, maxPlayers = 12, minPlayers = 1,
		description = "Go in with your party and the kit you dare to risk. Search a great dark dungeon for weapons, armour and valuables, keep quiet past what sleeps there, watch for other raiders, and get out by the escape stairs or a blue portal. Fall, or stay too long, and it's gone.",
		maps = {"BoneCrypt", "GoblinWarrens", "CrimsonManor", "FrozenDepths", "EmberForge"}, procedural = true,
		roundLength = 15 * 60, intermission = 15, respawnDelay = 3, hidden = true, ownSpawn = true,
	},
	-- CROWNFALL (Game ▸ Modes ▸ Crownfall): a battle royale on an island built fresh (Game ▸ Realm)
	Crownfall = {
		name = "Crownfall", category = "Adventure", teams = 0, maxPlayers = 16, minPlayers = 1,
		description = "Drop onto an island built fresh every match with only a plain weapon. Loot its chests for weapons, armour, potions and tomes; the ring of fire closes in. Last one standing takes the crown.",
		maps = {"Crownlands"}, procedural = true,
		roundLength = 10 * 60, intermission = 15, respawnDelay = 0, hidden = true, botFill = 12, fillAnywhere = true,
	},
	-- KINGSLAYER (Game ▸ Modes ▸ Kingslayer): everyone against the King
	Kingslayer = {
		name = "Kingslayer", category = "Adventure", teams = 0, maxPlayers = 16, minPlayers = 1,
		description = "Take the crown and you're the King: tough, gold, and everyone's target. Kill the King to take it. A point a second while you hold it; first to 150.",
		maps = {"Sandpit", "Millfield", "Highbridge", "Colosseum", "Moonring", "Dustbowl", "Cinderfall", "Duneshrine", "HollowGrove", "Harvestvale", "Abbeyfield", "Pinewatch"},
		roundLength = 6 * 60, intermission = 15, respawnDelay = 4, hidden = true, botFill = 6, fillAnywhere = true, pointsToWin = 150,
	},
	-- PLAGUE NIGHT (Game ▸ Modes ▸ Plague): the living against the plague, till dawn
	Plague = {
		name = "Plague Night", category = "Adventure", teams = 2, maxPlayers = 16, minPlayers = 1,
		description = "Night. The fallen rise as ghouls and hunt the living; more come out of the dark as the night deepens. Survive until dawn.",
		maps = {"Millfield", "Harvestvale", "Abbeyfield", "Blackwater", "Marshfen", "Mistbridge", "HollowGrove", "Pinewatch", "Frosthollow", "Redgorge"},
		roundLength = 5 * 60, intermission = 15, respawnDelay = 3, hidden = true,
	},
	-- THE INVASIONS (Game ▸ Modes ▸ Invasion, on the Horde's rules): an army, what you defend
	InvGoblin = {
		name = "Goblin Raid", category = "Horde", impl = "Invasion", army = "Goblin", objective = "Hoard", objectiveHealth = 1500,
		teams = 0, maxPlayers = 6, minPlayers = 1, roundLength = 0, intermission = 15, respawnDelay = 3, hidden = true, pvp = false,
		description = "Goblins want your gold. Thieves grab a sack and run for their gate: cut them down and it comes back. Every fifth wave, the Goblin King.",
		maps = {"Wildwood", "Colosseum", "Ravenhold", "Stormbreak", "HollowGrove", "Pinewatch", "Marshfen", "Cinderfall", "Bloodpit", "Frosthollow"},
	},
	InvElf = {
		name = "The Elven Host", category = "Horde", impl = "Invasion", army = "Elf", objective = "Camp", objectiveHealth = 1500,
		teams = 0, maxPlayers = 6, minPlayers = 1, roundLength = 0, intermission = 15, respawnDelay = 3, hidden = true, pvp = false,
		description = "Arrows from every tree. Archers and rangers by the dozen, blademasters to run you down. Hold the logging camp. Every fifth wave, their Queen.",
		maps = {"Wildwood", "HollowGrove", "Pinewatch", "Marshfen", "Ravenhold", "Stormbreak", "Frosthollow"},
	},
	InvUndead = {
		name = "Undead Night", category = "Horde", impl = "Invasion", army = "Undead", objective = "Flame", objectiveHealth = 1500,
		teams = 0, maxPlayers = 6, minPlayers = 1, roundLength = 0, intermission = 15, respawnDelay = 3, hidden = true, pvp = false,
		description = "Night falls and the dead walk. Skeletons stand back up, necromancers raise more. Keep the chapel's holy flame alight. Every fifth wave, a lord of the dead.",
		maps = {"Ravenhold", "Colosseum", "Bloodpit", "Stormbreak", "HollowGrove", "Marshfen", "Cinderfall", "Frosthollow"},
	},
	InvOrc = {
		name = "The Orc Warband", category = "Horde", impl = "Invasion", army = "Orc", objective = "Villagers", objectiveHealth = 1500,
		teams = 0, maxPlayers = 6, minPlayers = 1, roundLength = 0, intermission = 15, respawnDelay = 3, hidden = true, pvp = false,
		description = "Brutes, berserkers and war-drummers who drive the rest on: kill the drummers first. Save the villagers. Every fifth wave, the Warchief.",
		maps = {"Colosseum", "Stormbreak", "Wildwood", "Pinewatch", "Cinderfall", "Bloodpit", "Ravenhold", "Marshfen"},
	},
	-- THE PROLOGUE (Game ▸ Modes ▸ Prologue): the Siege of Stormwatch, the newcomer's tutorial
	Prologue = {
		name = "The Siege of Stormwatch", category = "Tutorial", teams = 0, maxPlayers = 1, minPlayers = 1,
		description = "A dark, stormy night. The Iron Host is at Stormwatch's gate, and you learn to fight in the middle of the battle.",
		maps = {"Stormwatch"}, procedural = true,
		roundLength = 0, intermission = 0, respawnDelay = 3, hidden = true, pvp = false, ownSpawn = true,
	},
	-- DRAGONFALL (Game ▸ Modes ▸ Dragonfall, Combat ▸ Dragon): you and your party against a dragon
	Dragonfall = {
		name = "Dragonfall", category = "Adventure", teams = 0, maxPlayers = 6, minPlayers = 1,
		description = "Cindermaw, the Ashen Wyrm, in its burning caldera. Get to its side, man the ballistae when it takes to the sky, shelter behind the ward stones from its inferno. Bring it down.",
		maps = {"Caldera"}, procedural = true,
		roundLength = 14 * 60, intermission = 15, respawnDelay = 8, hidden = true, pvp = false,
	},
	-- WAR (Game ▸ Modes ▸ War, Game ▸ WarMap): the maps are themes, each battlefield built fresh.
	-- tickets: each side's reinforcements · botFill: fighters the bots make up (fillAnywhere: on
	-- War's own servers too); War lowers it while the server struggles
	War = {
		name = "War", category = "Battlefield", teams = 2, maxPlayers = 24, minPlayers = 1,
		description = "Two armies meet: take the five banners one by one as a front, while trebuchets, archers and battle-mages pound the field and the rest of both armies clash on the flanks.",
		maps = {"Redfield", "Ironridge", "Frostmere", "Ashvale", "Kingsbridge", "Nightfall", "Sunreach", "Stormvale", "Duskmoor"}, procedural = true,
		roundLength = 15 * 60, intermission = 15, respawnDelay = 6, waveSpawn = 8, waveGrace = 20,
		botFill = 32, fillAnywhere = true, tickets = 300,
	},
	KOTH = {
		name = "King of the Hill", category = "Battlefield", teams = 2, maxPlayers = 32, minPlayers = 2,
		description = "Hold the hill. Points tick for the team that owns it.",
		maps = {"Millfield", "Colosseum", "Harvestvale", "Frosthollow", "Marshfen", "Duneshrine", "Cinderfall", "HollowGrove", "Pinewatch", "Abbeyfield", "Moonring"}, roundLength = 8 * 60, intermission = 15, respawnDelay = 6, botFill = 10,
		pointsToWin = 200, waveSpawn = 8,
	},
}
-- a map's name on screen (the key is its name in ServerStorage ▸ Maps)
GameConfig.MAP_TITLES = {TrainingYard = "The Training Yard", Courtyard = "The Courtyard", Tavern = "The Gilded Rat", Frostgate = "Frostgate",
	Sandpit = "The Sandpit", Highbridge = "Highbridge", Millfield = "Millfield", Colosseum = "The Colosseum", RoseCourt = "The Rose Court",
	Wildwood = "The Wildwood", Ravenhold = "Ravenhold", Stormbreak = "Stormbreak",
	-- the themed maps (Build ▸ MapForge)
	Emberkeep = "Emberkeep", Sunspire = "Sunspire", Thornwall = "Thornwall", Mistmoor = "Mistmoor", Greenhollow = "Greenhollow",
	Stormhold = "Stormhold", Ashenford = "Ashenford", Rimeholt = "Rimeholt", Blossomgate = "Blossomgate",
	Bloodpit = "The Bloodpit", Moonring = "Moonring", Dustbowl = "The Dustbowl", Thornpit = "Thornpit", Mirepit = "Mirepit",
	Abbeyfield = "Abbeyfield", Blackwater = "Blackwater", Harvestvale = "Harvestvale", Frosthollow = "Frosthollow", Marshfen = "Marshfen",
	Redgorge = "Redgorge", Mistbridge = "Mistbridge", Cinderfall = "Cinderfall", Duneshrine = "Duneshrine", HollowGrove = "Hollow Grove", Pinewatch = "Pinewatch",
	-- the warfields: a duel ring in the middle of a battle (MapForge "warfield", Warfield.client)
	Redmeadow = "Redmeadow", Ironvale = "Ironvale", Grimfield = "Grimfield", Sunfall = "Sunfall", Ravenfield = "Ravenfield",
	-- the dungeons' themes (Catalog ▸ Dungeons: The Depths, Deadvault)
	Crownlands = "The Crownlands", Caldera = "The Ashen Caldera", Stormwatch = "Stormwatch",
	-- War's battlefields (Game ▸ WarMap)
	Redfield = "Redfield", Ironridge = "Ironridge", Frostmere = "Frostmere", Ashvale = "Ashvale", Kingsbridge = "Kingsbridge",
	Nightfall = "Nightfall", Sunreach = "Sunreach", Stormvale = "Stormvale", Duskmoor = "Duskmoor",
	BoneCrypt = "The Bone Crypt", GoblinWarrens = "Goblin Warrens", CrimsonManor = "Crimson Manor", FrozenDepths = "The Frozen Depths", EmberForge = "The Ember Forge"}
function GameConfig.mapTitle(key) return GameConfig.MAP_TITLES[key] or key end

-- THE WEATHER on each map (StarterPlayerScripts ▸ Weather, drawn by ReplicatedStorage ▸ WarFX: rain
-- and snow stop under a roof): "rain" · "storm" (rain, lightning, heavy cloud) · "snow" · "embers" ·
-- "petals". A mode's own (MODE_WEATHER) wins over the map's. War and the Prologue draw their own.
GameConfig.MAP_WEATHER = {
	Frostgate = "snow", Rimeholt = "snow", Frosthollow = "snow", Ironvale = "snow",
	Stormhold = "storm", Stormbreak = "storm", Ravenfield = "storm", Mistmoor = "rain", Marshfen = "rain", Mistbridge = "rain", Blackwater = "rain",
	Emberkeep = "embers", Ashenford = "embers", Cinderfall = "embers", Grimfield = "embers",
	Blossomgate = "petals", RoseCourt = "petals",
}
GameConfig.MODE_WEATHER = {Plague = "storm", InvUndead = "rain"}

-- how many fighters (players and bots together) a map suits: {fewest, most}. A
-- match picks among the maps that suit its numbers, and bots never fill a map past
-- its most (Game ▸ GameServer, BotFill). A map not listed suits anything
GameConfig.MAP_FIGHTERS = {
	RoseCourt = {2, 6},                                  -- a garden court: 1v1 to 3v3
	Redmeadow = {2, 6}, Ironvale = {2, 6}, Grimfield = {2, 6}, Sunfall = {2, 6}, Ravenfield = {2, 6},   -- a duel ring in a battle: 1v1 to 3v3
	Colosseum = {2, 12}, Bloodpit = {2, 12}, Moonring = {2, 12}, Dustbowl = {2, 12}, Thornpit = {2, 12}, Mirepit = {2, 12},
	Sandpit = {2, 16},
	Highbridge = {4, 20},
	Abbeyfield = {6, 24}, Blackwater = {6, 24}, Redgorge = {6, 24}, Mistbridge = {6, 24},
	Millfield = {8, 32}, Harvestvale = {8, 32}, Frosthollow = {8, 32}, Marshfen = {8, 32},
	Cinderfall = {8, 32}, Duneshrine = {8, 32}, HollowGrove = {8, 32}, Pinewatch = {8, 32},
	Frostgate = {8, 40}, Emberkeep = {8, 40}, Sunspire = {8, 40}, Thornwall = {8, 40}, Mistmoor = {8, 40},
	Greenhollow = {8, 40}, Stormhold = {8, 40}, Ashenford = {8, 40}, Rimeholt = {8, 40}, Blossomgate = {8, 40},
	Redfield = {8, 48}, Ironridge = {8, 48}, Frostmere = {8, 48}, Ashvale = {8, 48}, Kingsbridge = {8, 48}, Nightfall = {8, 48}, Sunreach = {8, 48},
	Stormvale = {8, 48}, Duskmoor = {8, 48},
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
	-- (starter: the Bowman, ServerStorage ▸ Armor ▸ Bowman: theirs with the class)
	Archer   = {name = "Archer",   weight = "Light",  armorType = "Light",  weapons = "any", primary = "Bow", secondary = "Shortsword",
		ranged = true, health = -15, prot = 0, speed = 1.04, starter = "Bowman", unlock = {level = 5}, tutor = "archer",
		description = "A bow or a crossbow, and a sidearm for when they get close. The lightest armor of all (85 health, nothing to stop a blade): stay back, aim for the head."},
	Vanguard = {name = "Vanguard", weight = "Light",  armorType = "Light",  weapons = "any", primary = "ArmingSword", secondary = "Shortsword",
		description = "No armor to speak of: the fastest on their feet, the most stamina and the quickest to get it back, long cheap dodges. One mistake from death."},
	-- the Mage: a staff (MagicSpells: fire, lightning, frost, mending; a ward of mana) and a
	-- wand at the hip (little spells: no blade — a staff's weak melee self is all the steel a
	-- Mage has). Robes, not armor (weight "Robe": only a Mage wears them, and nothing else): far
	-- less than the Archer (65 health, nothing to stop a blade),
	-- and a mana bar beside the stamina. Starts in the Apprentice's robes (starter = a set).
	Mage     = {name = "Mage",     weight = "Robe",   armorType = "Light",  weapons = "any", primary = "Staff", secondary = "Wand",
		magic = true, health = -35, prot = 0, speed = 1.0, starter = "ApprenticeRobes", unlock = {level = 5}, tutor = "mage",
		description = "A staff of fire, lightning, frost and mending, and a ward that turns blows into lost mana. The least health of anyone (65, no armor), and only a wand at the hip: keep your distance, cast, and never let them close."},
}
GameConfig.CLASS_ORDER = {"Knight", "Footman", "Vanguard", "Archer", "Mage"}
-- a new player's class (the intro, their training and their first battle are fought in it)
GameConfig.DEFAULT_CLASS = "Knight"

-- the game's name and line, wherever the game introduces itself (the intro's title card)
GameConfig.GAME_NAME = "Steel & Glory"
GameConfig.TAGLINE = "Every swing is yours to aim."

-- MILD (Roblox's content maturity label for all ages: Roblox Kids 5-8, Select 9-15 and
-- everyone older). Off, nothing comes off and nothing bleeds:
--   • a killing blow drops them, never takes off a head or a limb or leaves a blade in them;
--   • no blood: a clean hit flashes white and gold;
--   • nobody bleeds out, screaming;
--   • arrows don't stay in a body;
--   • a body lies a few seconds and fades.
-- (docs/LAUNCH.md has the questionnaire answers that go with it.)
-- On, the old gore comes back, and the honest answers change to Strong violence. That label
-- is Restricted (age-verified 18+ only), which can't be retaken once given: never ship it on
-- by accident.
GameConfig.GORE = false

-- Studio plays on its own saved data (Safety ▸ Stores: "Studio_" copies of every data store),
-- so tests and cheats never touch a live save. True points Studio at the live game's stores:
-- only on purpose (looking at real data), and never leave it on
GameConfig.STUDIO_LIVE_DATA = false

-- true: every Studio Play is a brand-new player sent through basic training, never saved (test
-- the newcomer's path); false: Studio's saved test player, with training skipped
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
