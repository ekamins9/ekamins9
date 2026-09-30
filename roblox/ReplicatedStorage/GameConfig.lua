--[[ GAME CONFIG — the one file that describes the GAME around the combat:
     places, game modes and their maps, classes. Server and client both read it.

     PLACES: Roblox place ids of this universe. 0 = "not a separate place":
     with everything at 0 the whole game runs in ONE place (the Hub menu opens
     over the game and Play switches this server's mode at the next
     intermission). Publish the other places later, paste their ids here and
     the same buttons teleport instead. The Hub is the start place.

     MODES: each is a plugin in ServerScriptService.Game.Modes/<id>. `maps`
     names Models in ServerStorage.Maps (see MapLoader for what a map needs).

     CLASSES: what the Armory lets a player build. `armorType` picks which
     ServerStorage.Armor sets qualify (their Config.Type); `weapons` is a list
     of Tool names in ServerStorage.Weapons or "any". Players save one loadout
     per class and pick a class when they spawn. ]]

local GameConfig = {}

GameConfig.PLACES = {
	Hub         = 0,
	Arena       = 0,
	Battlefield = 0,
	Siege       = 0,
}
-- which mode a place runs when nobody chose one (by PLACES key; "Battlefield" here = your current place)
GameConfig.PLACE_DEFAULT_MODE = {Hub = "Hub", Arena = "Duel", Battlefield = "FFA", Siege = "TDM"}
GameConfig.SINGLE_PLACE_DEFAULT = "FFA"   -- with all PLACES at 0, the mode this server starts in

GameConfig.MODES = {
	Hub = {
		name = "Courtyard", category = "Hub", teams = 0, maxPlayers = 40,
		description = "Walk around, talk, practice on the dummies. Pick a mode to fight.",
		maps = {"Courtyard"}, roundLength = 0, intermission = 0, hidden = true,
	},
	FFA = {
		name = "Free-for-All", category = "Battlefield", teams = 0, maxPlayers = 24, minPlayers = 1,
		description = "Everyone for themselves. Most kills when the clock runs out wins.",
		maps = {"Arena", "Village"}, roundLength = 5 * 60, intermission = 15, respawnDelay = 4,
	},
	Duel = {
		name = "Duel Yard", category = "Arena", teams = 0, maxPlayers = 12, minPlayers = 1,
		description = "Honor rules: one on one. Stay out of other people's fights.",
		maps = {"Arena"}, roundLength = 6 * 60, intermission = 15, respawnDelay = 3,
	},
	TDM = {
		name = "Team Deathmatch", category = "Battlefield", teams = 2, maxPlayers = 32, minPlayers = 2,
		description = "Two armies, one ticket pool each. Bleed theirs dry first.",
		maps = {"Village", "Bridge"}, roundLength = 8 * 60, intermission = 15, respawnDelay = 6,
		tickets = 60, waveSpawn = 8,
	},
	LTS = {
		name = "Last Team Standing", category = "Battlefield", teams = 2, maxPlayers = 24, minPlayers = 2,
		description = "No respawns. Win the round by wiping the other side. First to 4 rounds.",
		maps = {"Arena", "Bridge"}, roundLength = 3 * 60, intermission = 12, respawnDelay = 0,
		roundsToWin = 4,
	},
	KOTH = {
		name = "King of the Hill", category = "Battlefield", teams = 2, maxPlayers = 32, minPlayers = 2,
		description = "Hold the hill. Points tick for the team that owns it.",
		maps = {"Village"}, roundLength = 8 * 60, intermission = 15, respawnDelay = 6,
		pointsToWin = 200, waveSpawn = 8,
	},
}
-- order on the Play tab
GameConfig.MODE_ORDER = {"FFA", "Duel", "TDM", "LTS", "KOTH"}

GameConfig.TEAMS = {
	A = {name = "Crown", color = BrickColor.new("Bright blue"), rgb = Color3.fromRGB(70, 110, 220)},
	B = {name = "Iron",  color = BrickColor.new("Bright red"),  rgb = Color3.fromRGB(200, 60, 50)},
}

GameConfig.CLASSES = {
	Knight   = {name = "Knight",   armorType = "Heavy",  weapons = "any",
		description = "Plate from head to toe. Slow, hard to cut, hits like a wall falling on you."},
	Footman  = {name = "Footman",  armorType = "Medium", weapons = "any",
		description = "Mail and gambeson. The all-rounder — quick enough, tough enough."},
	Vanguard = {name = "Vanguard", armorType = "Light",  weapons = "any",
		description = "No armor to speak of. Fast, long reach, one mistake from death."},
}
GameConfig.CLASS_ORDER = {"Knight", "Footman", "Vanguard"}
GameConfig.DEFAULT_CLASS = "Footman"

-- friendly fire: damage dealt to a teammate is multiplied by this (0 = none)
GameConfig.FRIENDLY_FIRE = 0.5

--------------------------------------------------------------------
function GameConfig.mode(id) return GameConfig.MODES[id] end
function GameConfig.class(id) return GameConfig.CLASSES[id] end

-- is this a one-place game right now?
function GameConfig.singlePlace()
	for _, id in pairs(GameConfig.PLACES) do if id ~= 0 then return false end end
	return true
end

-- which PLACES key this server is
function GameConfig.thisPlace()
	for key, id in pairs(GameConfig.PLACES) do if id ~= 0 and id == game.PlaceId then return key end end
	return nil
end

-- the place a mode runs in (by category), or nil when it's this place / single-place
function GameConfig.placeFor(modeId)
	local m = GameConfig.MODES[modeId]
	if not m or GameConfig.singlePlace() then return nil end
	local id = GameConfig.PLACES[m.category]
	if not id or id == 0 or id == game.PlaceId then return nil end
	return id
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
