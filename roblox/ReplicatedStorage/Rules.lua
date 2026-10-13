--[[ RULES — Steel & Glory's own rules (Roblox calls them Experience Rules), and what happens to
     those who break them. Roblox's Terms require them "clearly and conspicuously posted within
     an Experience" when a game enforces its own rules, as this one does (staff kick, ban and
     take back items: Admin ▸ AdminServer). They may add to Roblox's rules but never contradict
     them.

     Shown in three places, all from this one module:
       • the rules board beside the Notice Board in the Courtyard, where everyone arrives
         (Hub ▸ Courtyard; its Read opens the menu's page);
       • MENU › SETTINGS › THE RULES (HubMenu's RULES screen);
       • the kick and ban messages themselves (Admin ▸ AdminServer).
     Edit the words here; keep them short, plain and kind (younger players read them too).
     APPEAL is how a banned player reaches you: change it if you set up a group or a
     support page. ]]

local Rules = {}

Rules.TITLE = "THE RULES"

Rules.LIST = {
	{"Be a good sport", "No bullying, harassment, hate or threats. Roblox's Community Standards apply everywhere in the game."},
	{"No cheating", "No exploits, hacks, macros or auto-clickers, and no abusing bugs. Found a bug? Tell us instead."},
	{"No farming", "No alt accounts, AFK farming, or setting up kills with friends to farm Marks, XP or rewards."},
	{"Trade fair", "No scams, and no trading for anything outside the game: real money, Robux or other games' items."},
	{"Play the mode", "No teaming in Free for All or duels, and no camping where new players spawn."},
	{"Respect staff", "Never pretend to be staff. Real staff will never ask for your password."},
}

Rules.CONSEQUENCES = "Break a rule and, depending on how serious it is and how often: a warning, a kick, a ban "
	.. "of up to 3 days, or a permanent ban from Steel & Glory. Items, Marks or progress gained by cheating, "
	.. "farming or scamming can be taken away."

Rules.APPEAL = "Think we got it wrong? Message the game's creator on Roblox (their profile is on the game page). "
	.. "Roblox's own rules, and its Report button, still apply too."

-- one block of plain text (a kick message, the docs)
function Rules.text()
	local lines = {Rules.TITLE}
	for i, r in ipairs(Rules.LIST) do table.insert(lines, string.format("%d. %s: %s", i, r[1], r[2])) end
	table.insert(lines, Rules.CONSEQUENCES)
	table.insert(lines, Rules.APPEAL)
	return table.concat(lines, "\n")
end

return Rules
