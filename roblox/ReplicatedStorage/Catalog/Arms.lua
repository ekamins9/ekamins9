--[[ ARMS — your own coat of arms: an emblem in a metal on a field of your colour, split if you like
     with a second. A plain (Default) shield carries it; in a team fight its field is your side's
     colour (ReplicatedStorage ▸ ShieldPaint.arms; with no arms of your own, your side's house's:
     ReplicatedStorage ▸ Houses). Chosen in LOOK ▸ YOUR ARMS, kept in your appearance (armsEmblem,
     armsMetal, armsField, armsDivision, armsColor2: Profile.validateAppearance). Config only.

       EMBLEMS    {id, name, level}: the pictures (ReplicatedStorage ▸ ShieldArt); level = the player
                  level that opens it (earned, never bought)
       METALS     the emblem's metal (heraldry's tinctures: or, argent, sable)
       DIVISIONS  how the field may be split (ShieldPaint's pictures) ]]

local Arms = {}
Arms.EMBLEMS = {
	{id = "lion", name = "Lion", level = 1}, {id = "eagle", name = "Eagle", level = 1}, {id = "cross", name = "Cross", level = 1},
	{id = "tower", name = "Tower", level = 1}, {id = "sun", name = "Sun", level = 1}, {id = "fleur", name = "Fleur-de-lis", level = 1},
	{id = "wolf", name = "Wolf", level = 1}, {id = "stag", name = "Stag", level = 1}, {id = "boar", name = "Boar", level = 1},
	{id = "horse", name = "Horse", level = 1}, {id = "rose", name = "Rose", level = 1}, {id = "moon", name = "Moon", level = 1},
	{id = "swords", name = "Crossed Swords", level = 1}, {id = "knot", name = "Knotwork", level = 1},
	{id = "bear", name = "Bear", level = 5}, {id = "raven", name = "Raven", level = 5}, {id = "serpent", name = "Serpent", level = 5},
	{id = "tree", name = "World Tree", level = 5},
	{id = "griffin", name = "Griffin", level = 10}, {id = "thunderbolt", name = "Thunderbolt", level = 10}, {id = "skull", name = "Crowned Skull", level = 10},
	{id = "dragon", name = "Dragon", level = 15}, {id = "phoenix", name = "Phoenix", level = 15}, {id = "kraken", name = "Kraken", level = 15},
}
Arms.EMBLEM = {}
for _, e in ipairs(Arms.EMBLEMS) do Arms.EMBLEM[e.id] = e end

Arms.METALS = {
	{id = "Gold", name = "Or", color = Color3.new(1.06, 0.84, 0.4), edge = Color3.fromRGB(26, 20, 18)},
	{id = "Silver", name = "Argent", color = Color3.new(1, 1, 1.03), edge = Color3.fromRGB(22, 24, 30)},
	{id = "Black", name = "Sable", color = Color3.fromRGB(26, 24, 26), edge = Color3.fromRGB(214, 178, 96)},
}
Arms.METAL = {}
for _, m in ipairs(Arms.METALS) do Arms.METAL[m.id] = m end

Arms.DIVISIONS = {"pale", "fess", "quarterly", "bend", "saltire", "chevron", "gyronny", "paly", "barry", "checky", "chief", "bordure", "pile", "cross"}
Arms.DIVISION = {}
for _, d in ipairs(Arms.DIVISIONS) do Arms.DIVISION[d] = true end

-- may this player bear it (their level)
function Arms.open(id, profile)
	local e = Arms.EMBLEM[id]
	return e ~= nil and ((profile and profile.level) or 1) >= (e.level or 1)
end

return Arms
