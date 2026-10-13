--[[ BADGES — Roblox badges for the big moments, shown on players' Roblox profiles.
     The badges themselves are made on the Creator Dashboard (Monetization ▸ Badges);
     their ids live in the place, never in code: ServerStorage ▸ BadgeIds ▸ <key>, an
     IntValue per badge (0 = not made yet: that badge is simply skipped).

       Badges.award(plr, key)     once per player per server (Roblox keeps the rest)
       Badges.check(plr)          the ones a profile has already earned (on join: a
                                  badge made later reaches everyone who earned it)
     The keys, and what to name each badge on the dashboard: Badges.LIST. ]]

local BadgeService = game:GetService("BadgeService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Badges = {}

Badges.LIST = {
	{key = "Welcome",    name = "Welcome to Steel & Glory", desc = "You came to fight."},
	{key = "Graduate",   name = "Graduate",                 desc = "Finished basic training with Sir Aldric."},
	{key = "FirstBlood", name = "First Blood",              desc = "Your first kill in battle."},
	{key = "FirstWin",   name = "First Victory",            desc = "Your first round won."},
	{key = "Level5",     name = "Bow and Staff",            desc = "Reached level 5: the Archer and the Mage are yours."},
	{key = "Level25",    name = "Veteran",                  desc = "Reached level 25."},
	{key = "Champion",   name = "Champion Slayer",          desc = "Beat a Champion in the sparring ring."},
	{key = "Gauntlet10", name = "Iron Will",                desc = "Survived ten waves of the Gauntlet."},
	{key = "Mythic",     name = "Touched by Legend",        desc = "Pulled a Mythic out of a crate."},
	{key = "BetaTester", name = "Beta Tester",              desc = "Played Steel & Glory before the gates opened."},
}

local given = {}   -- [plr] = {[key] = true}

local function idOf(key)
	local f = ServerStorage:FindFirstChild("BadgeIds")
	local v = f and f:FindFirstChild(key)
	return v and v:IsA("IntValue") and v.Value > 0 and v.Value or nil
end

function Badges.award(plr, key)
	if not (plr and plr.Parent) then return end
	given[plr] = given[plr] or {}
	if given[plr][key] then return end
	local id = idOf(key)
	if not id then return end
	given[plr][key] = true
	task.spawn(function()
		local okHas, has = pcall(BadgeService.UserHasBadgeAsync, BadgeService, plr.UserId, id)
		if okHas and has then return end
		local ok, err = pcall(BadgeService.AwardBadge, BadgeService, plr.UserId, id)
		if not ok then given[plr][key] = nil; warn("[Badges]", key, err) end
	end)
end

-- (what the profile already shows: levels, the beta, training; the stats' firsts)
function Badges.check(plr, p)
	if not p then return end
	Badges.award(plr, "Welcome")
	if (p.tutorial or 0) >= 1 then Badges.award(plr, "Graduate") end
	if (p.level or 1) >= 5 then Badges.award(plr, "Level5") end
	if (p.level or 1) >= 25 then Badges.award(plr, "Level25") end
	if p.beta then Badges.award(plr, "BetaTester") end
	local st = p.stats or {}
	if (st.kill or 0) >= 1 then Badges.award(plr, "FirstBlood") end
	if (st.win or 0) >= 1 then Badges.award(plr, "FirstWin") end
	if (p.gauntlet or 0) >= 10 then Badges.award(plr, "Gauntlet10") end
	if (p.spars and p.spars.Champion or 0) >= 1 then Badges.award(plr, "Champion") end
end

Players.PlayerRemoving:Connect(function(plr) given[plr] = nil end)

return Badges
