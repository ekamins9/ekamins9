--[[ GUISE — fill bots that pass for players (GameConfig.BOT_GUISE): a quiet server still feels
     full. A guised bot gets
       a player's kind of name     invented from the parts below (never a real account's), the
                                   way people name themselves: ShadowFang27, Lukas2011, mira_frost
       a body of its own           skin, hair and its colour, beard, face, eyes (Catalog ▸ Body)
       a level                     most low, a few high; with it, now and then a title it could
                                   have earned (Catalog ▸ Body earnedTitles) and a coat of arms
                                   (Catalog ▸ Arms), so its shield and surcoat wear one
       a kit of its own choosing   pieces of its weight, mixed now and then, in colours off the
                                   palette; often a weapon skin (never a numbered Mythic or a
                                   one-of-one: nothing that tells a lie about who owns what)
     and the board and the name tags show it as they show a player (Scoreboard, NameTags: the
     attribute Guise; Level, Title, Arms on the model, Guise / Level / Title on its seat). How it
     fights, what it pays and where it's allowed are unchanged (BotFill; never in ranked).

       Guise.name() -> string
       Guise.dress(opts, kind)     fills Bots.spawn's opts (appearance, loadout, skin, attrs) ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Guise = {}

local FIRST = {"Lukas", "Mira", "Jayden", "Ava", "Noah", "Ethan", "Lily", "Leo", "Zoe", "Max", "Ella", "Finn", "Kai",
	"Ruby", "Owen", "Nora", "Eli", "Isla", "Theo", "Maya", "Liam", "Emma", "Oscar", "Freya", "Jonas", "Sofia", "Mateo",
	"Elena", "Aiden", "Chloe", "Ryan", "Hana", "Felix", "Ivy", "Dylan", "Sara", "Hugo", "Lena", "Caleb", "Nina", "Arlo",
	"Jude", "Sami", "Tobi", "Remy", "Ezra", "Luca", "Wren", "Milo", "Rhys"}
local A = {"Shadow", "Iron", "Night", "Storm", "Frost", "Blaze", "Wolf", "Raven", "Dragon", "Steel", "Crimson", "Silent",
	"Swift", "Grim", "Golden", "Dark", "Lucky", "Wild", "Red", "Blue", "Ghost", "Stone", "Thunder", "Ember", "Hollow",
	"Brave", "Rusty", "Silver", "Lone", "Mad", "Sneaky", "Epic", "Mega", "Turbo", "Noble", "Feral", "Cursed", "Royal"}
local B = {"Blade", "Knight", "Slayer", "Fang", "Wolf", "Hawk", "Storm", "Fury", "Bane", "Heart", "Strike", "Guard",
	"Rider", "Warden", "Edge", "Claw", "Shield", "Arrow", "Sword", "Crow", "Lion", "Bear", "Fox", "Viper", "Duck",
	"Goose", "Squire", "Baron", "Paladin", "Ronin"}
local TAG = {"YT", "TV", "Pro", "GG", "Plays", "Main", "Real", "Gamer", "Official", "XD"}

local function pick(t) return t[math.random(#t)] end
local used = {}

local PATTERNS = {
	{w = 22, f = function() return pick(A) .. pick(B) end},
	{w = 20, f = function() return pick(A) .. pick(B) .. tostring(math.random(2, 99)) end},
	{w = 10, f = function() return pick(A) .. "_" .. pick(B) end},
	{w = 14, f = function() return pick(FIRST) .. tostring(math.random(2008, 2016)) end},
	{w = 8, f = function() return pick(FIRST) .. "_" .. pick(A) end},
	{w = 8, f = function() return string.lower(pick(FIRST) .. pick(B)) end},
	{w = 5, f = function() return "x" .. pick(A) .. pick(B) .. "x" end},
	{w = 7, f = function() return pick(FIRST) .. pick(TAG) end},
	{w = 6, f = function() return string.lower(pick(A)) .. "_" .. string.lower(pick(B)) .. tostring(math.random(1, 9)) end},
}
local TOTAL = 0
for _, p in ipairs(PATTERNS) do TOTAL += p.w end

function Guise.name()
	for _ = 1, 20 do
		local x = math.random() * TOTAL
		local n
		for _, p in ipairs(PATTERNS) do
			x -= p.w
			if x <= 0 then n = p.f(); break end
		end
		n = n or (pick(A) .. pick(B))
		if #n <= 20 and not used[n] then used[n] = true; return n end
	end
	return pick(A) .. pick(B) .. tostring(math.random(100, 999))
end

-- free things only, mostly (a few crowns-bought looks, as on anyone)
local function pickFree(list, crownsChance)
	local pool = {}
	for _, e in ipairs(list) do
		if not e.none and ((e.crowns or 0) == 0 or math.random() < (crownsChance or 0.15)) then table.insert(pool, e) end
	end
	return #pool > 0 and pick(pool) or list[1]
end

local function body()
	local Bd = Catalog.BODY
	local app = table.clone(Bd.defaults)
	app.skin = math.random(#Bd.skins)
	local hair = math.random() < 0.08 and {id = "Bald"} or pickFree(Bd.hair)
	app.hair = hair.id
	app.hairColor = pickFree(Bd.hairColors).name
	app.beard = math.random() < 0.55 and "None" or pickFree(Bd.beards).id
	local face = pick(Bd.faces)
	app.face = face.id
	for k, v in pairs(face.parts or {}) do app[k] = v end
	app.eyeColor = pickFree(Bd.eyeColors, 0.05).name
	return app
end

-- a level like the people who play: most low, some middling, a few high
local function level()
	local r = math.random()
	return math.floor(1 + 46 * r ^ 1.9)
end

local function titleFor(lvl)
	if math.random() > 0.4 then return nil end
	local can = {}
	for _, t in ipairs(Catalog.BODY.earnedTitles or {}) do
		local u = t.unlock or {}
		if (u.level and lvl >= u.level) or (u.kills and lvl >= 12 and math.random() < 0.3) then table.insert(can, t.title) end
	end
	return #can > 0 and pick(can) or nil
end

local function palette()
	local names = {}
	for _, c in ipairs(Catalog.PALETTE or {}) do
		-- (the free colours and the common ones: no premium shades)
		if not c.crowns then table.insert(names, c.name) end
	end
	if #names == 0 then return nil end
	return {Primary = pick(names), Secondary = pick(names), Accent = pick(names), Metal = pick({"Steel", "Ash", "Gold", "Steel"})}
end

local function arms(lvl)
	if math.random() > 0.45 then return nil end
	local Ar = Catalog.ARMS
	local open = {}
	for _, e in ipairs(Ar.EMBLEMS) do if (e.level or 1) <= lvl then table.insert(open, e.id) end end
	local pal = {}
	for _, c in ipairs(Catalog.PALETTE or {}) do if not c.crowns then table.insert(pal, c.name) end end
	if #open == 0 or #pal == 0 then return nil end
	local a = {armsEmblem = pick(open), armsMetal = pick(Ar.METALS).id, armsField = pick(pal)}
	if math.random() < 0.5 then a.armsDivision = pick(Ar.DIVISIONS); a.armsColor2 = pick(pal) end
	return a
end

-- pieces of this weight, for each slot (now and then from two sets)
local function kit(weight)
	local bySlot = {}
	for _, pc in ipairs(Catalog.PIECES or {}) do
		if pc.weight == weight and not pc.unique then
			bySlot[pc.slot] = bySlot[pc.slot] or {}
			table.insert(bySlot[pc.slot], pc)
		end
	end
	local lo = {}
	local set
	local top = bySlot.top and pick(bySlot.top)
	if top then lo.top = top.id; set = top.set end
	for _, slot in ipairs({"helmet", "bottom"}) do
		local list = bySlot[slot] or {}
		local same
		for _, pc in ipairs(list) do if set and pc.set == set then same = pc end end
		local pc = (same and math.random() < 0.7) and same or (#list > 0 and pick(list) or nil)
		lo[slot] = pc and pc.id or nil
	end
	if math.random() < 0.18 then lo.noHelm = true end
	return lo
end

-- a weapon skin: often the plain one; Common to Legendary, never a numbered or one-of-one
local SKIN_ODDS = {Common = 30, Rare = 20, Epic = 8, Legendary = 2}
local function skinFor(weaponId)
	if not weaponId or math.random() < 0.4 then return nil end
	local pool, total = {}, 0
	for _, s in ipairs(Catalog.skinsFor and Catalog.skinsFor(weaponId) or {}) do
		local w = SKIN_ODDS[s.rarity or ""]
		if w and not s.limited and not s.unique and not s.founder then table.insert(pool, {s = s, w = w}); total += w end
	end
	if total == 0 then return nil end
	local x = math.random() * total
	for _, e in ipairs(pool) do x -= e.w; if x <= 0 then return e.s.id end end
	return pool[1].s.id
end

-- Bots.spawn's opts, dressed as a player would be (kind: BotFill's: a rank or a class)
function Guise.dress(opts, kind)
	local lvl = level()
	local app = body()
	local a = arms(lvl)
	for k, v in pairs(a or {}) do app[k] = v end
	opts.appearance = app
	local cls = opts.class and GameConfig.CLASSES[opts.class]
	-- (a Mage keeps its robes for its rank; everyone else picks their own pieces)
	if not (cls and cls.magic) then
		local weight = opts.weight or (cls and cls.weight) or ({Squire = "Light", Knight = "Medium", Champion = "Heavy"})[opts.skill or ""] or "Medium"
		local lo = kit(weight)
		lo.colors = palette()
		if lo.top then opts.loadout = lo; opts.weight = weight end
	end
	opts.skin = skinFor(opts.weapon)
	opts.attrs = opts.attrs or {}
	opts.attrs.Guise = true
	opts.attrs.Level = lvl
	opts.attrs.Title = titleFor(lvl)
	opts.attrs.Arms = a and string.format("%s|%s|%s", a.armsEmblem, a.armsMetal, a.armsField) or nil
	return lvl, opts.attrs.Title
end

return Guise
