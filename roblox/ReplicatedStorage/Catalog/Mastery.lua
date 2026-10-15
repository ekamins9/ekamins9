--[[ MASTERY — every class has a level of its own (CLASS LEVEL), on top of your overall
     level. Every bit of XP you earn while you fight as a class goes to it too (Economy.addXP
     reads your character's class). A class's level opens its POWERS (Catalog ▸ Powers: the
     levels each opens at), its titles and its mastery skins (Catalog ▸ PowerSkins mastery),
     and a Key every `keyEvery` levels. Config only.

       need(level)   XP from that class level to the next
       max           the top class level
       titles        [class][level] = a title (bound, on your player card)
       keyEvery      a Key every this many class levels
       thirdSlot     the OVERALL level the third slot opens at (powers, throwables) ]]

local M = {
	max = 30,
	keyEvery = 5,
	thirdSlot = 1,
	titles = {
		Knight   = {[10] = "Oathsworn",  [20] = "Paladin",     [30] = "Knight-Commander"},
		Footman  = {[10] = "Swiftblade", [20] = "Windrunner",  [30] = "Stormstrider"},
		Vanguard = {[10] = "Shadowblade", [20] = "Nightstalker", [30] = "Phantom"},
		Archer   = {[10] = "Marksman",   [20] = "Hawkeye",     [30] = "Ranger-Lord"},
		Mage     = {[10] = "Adept",      [20] = "Archmage",    [30] = "Magister"},
	},
}

-- XP from one class level to the next: quick at first (a power every round or two), then a
-- long road to the ultimate (class level 22)
function M.need(level)
	return math.min(2600, 250 + 100 * math.max(0, level - 1))
end

-- level and progress from a class's XP total -> level, xp into it, xp it needs
function M.levelOf(total)
	total = math.max(0, tonumber(total) or 0)
	local lvl = 1
	while lvl < M.max do
		local need = M.need(lvl)
		if total < need then return lvl, total, need end
		total -= need
		lvl += 1
	end
	return M.max, 0, 0
end

return M
