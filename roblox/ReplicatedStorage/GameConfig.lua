--[[ GAME CONFIG — the one file that describes the GAME around the combat:
     places, game modes and their maps, classes. Server and client both read it.

     PLACES: one Roblox place per MODE, by place id. A place runs its mode
     forever — nothing ever switches mode inside a server. The Hub place is
     the game's start place: everyone lands there, PLAY teleports them to the
     mode's place (Roblox joins a server with room or starts a new one), and
     RETURN TO HUB brings them back. 0 = not published yet (PLAY says so).
     In Studio there are no teleports: the place runs STUDIO_MODE and PLAY
     switches the mode locally so everything can still be tested.

     MODES: each is a plugin in ServerScriptService.Game.Modes/<id>. `maps`
     names Models in ServerStorage.Maps (see MapLoader for what a map needs).

     CLASSES: what the Armory lets a player build. `armorType` picks which
     ServerStorage.Armor sets qualify (their Config.Type); `weapons` is a list
     of Tool names in ServerStorage.Weapons or "any". Players save one loadout
     per class and pick a class when they spawn. ]]

local GameConfig = {}

GameConfig.PLACES = {
	Hub  = 0,   -- the start place
	FFA  = 0,
	Duel = 0,
	TDM  = 0,
	LTS  = 0,
	KOTH = 0,
}
GameConfig.STUDIO_MODE = "Hub"   -- what an unpublished place (Studio) starts in

GameConfig.MODES = {
	Hub = {
		name = "Hub", category = "Hub", teams = 0, maxPlayers = 40,
		description = "The courtyard: walk around, talk, practice on the dummies. Pick a mode to fight.",
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

-- the mode THIS server runs: the mode whose place id this is; an unknown /
-- unpublished place runs STUDIO_MODE in Studio and the Hub live
function GameConfig.thisMode()
	for modeId, id in pairs(GameConfig.PLACES) do
		if id ~= 0 and id == game.PlaceId and GameConfig.MODES[modeId] then return modeId end
	end
	if game:GetService("RunService"):IsStudio() and GameConfig.MODES[GameConfig.STUDIO_MODE] then return GameConfig.STUDIO_MODE end
	return "Hub"
end

-- the place id a mode runs in, or nil when it isn't published yet
function GameConfig.placeFor(modeId)
	local id = GameConfig.PLACES[modeId]
	if not id or id == 0 then return nil end
	return id
end

-- are all the places published (ids pasted in)?
function GameConfig.placesReady()
	for _, id in pairs(GameConfig.PLACES) do if id == 0 then return false end end
	return true
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
