--[[ HOUSES — the two houses at war on a map: which arms each colour of cloth flies there. The blue
     side's banners and its plain shields carry one house's emblem, the red side's the other's
     (never the same beast), and a green, gold, purple, black or white cloth its own; picked from
     the map's name, so a map always flies the same arms, on the server and on every screen alike.
     The pictures are the shields' (ReplicatedStorage ▸ ShieldArt).

       Houses.kindOf(color) -> "blue" | "red" | "green" | "gold" | "purple" | "dark" | "pale"
       Houses.emblem(kind, mapName) -> an emblem's name
       Houses.forColor(color, mapName) -> an emblem's name
       Houses.forTeam(teamKey, mapName) -> an emblem's name (GameConfig.TEAMS' colours) ]]

local Houses = {}
Houses.LIST = {
	blue = {"eagle", "lion", "griffin", "fleur", "horse"},
	red = {"dragon", "wolf", "boar", "bear", "phoenix"},
	green = {"stag", "tree", "serpent", "knot"},
	gold = {"sun", "lion", "tower"},
	purple = {"fleur", "moon", "rose"},
	dark = {"raven", "tower", "moon", "swords"},
	pale = {"cross", "rose", "tower"},
}

function Houses.kindOf(c)
	local h, s, v = c:ToHSV()
	if v < 0.22 then return "dark" end
	if s < 0.22 then return v > 0.7 and "pale" or "dark" end
	if h < 0.05 or h > 0.92 then return "red" end
	if h < 0.17 then return "gold" end
	if h < 0.45 then return "green" end
	if h < 0.72 then return "blue" end
	return "purple"
end

-- (a number from a string, the same everywhere: the seed for that map's houses)
local function hash(s)
	local n = 7
	for i = 1, #s do n = (n * 31 + string.byte(s, i)) % 2147483647 end
	return n
end

function Houses.emblem(kind, mapName)
	local list = Houses.LIST[kind]
	if not list then return nil end
	local r = Random.new(hash((mapName or "") .. "|" .. kind))
	return list[r:NextInteger(1, #list)]
end

function Houses.forColor(c, mapName) return Houses.emblem(Houses.kindOf(c), mapName) end

function Houses.forTeam(teamKey, mapName)
	local ok, GameConfig = pcall(require, script.Parent:WaitForChild("GameConfig"))
	local def = ok and GameConfig.TEAMS and GameConfig.TEAMS[teamKey]
	return def and Houses.forColor(def.rgb, mapName) or nil
end

return Houses
