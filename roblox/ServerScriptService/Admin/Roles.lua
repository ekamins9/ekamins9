--[[ ROLES — the admin panel's roles and what each may do. Edit this file to
     change them. The game's creator (game.CreatorId, or a group game's owner)
     is always Owner, and so is anyone listed in `owners`. Everyone else gets a
     role in the panel (STAFF tab); roles are saved (DataStore Staff_v1) and
     reach every server.

       rank   a role acts only on players and staff below it, and gives only
              roles below its own
       perms  "*" (everything) or a list of:
         view          open the panel; see players' details
         kick          kick a player
         tempban       ban for up to TEMPBAN_HOURS
         ban           ban for any length or for good; unban
         teleport      go to a player, bring one, freeze and unfreeze
         health        heal or kill a player
         announce      a banner in this server     announce_all   in every server
         rounds        end the round now, pick the next mode and map
         bots          spawn and clear bots
         currency      give and take Marks and Crowns
         items         give and take items (pieces, skins, weapons, emotes,
                       kill effects, companions, eggs, crates, titles, colours)
         unlock        unlock everything for a player
         progress      set a player's level
         reset         wipe a player's saved data
         staff         give and take roles (below your own)
         shutdown      close this server
         log           read the action log ]]
return {
	TEMPBAN_HOURS = 72,
	owners = {},        -- more owners, by user id (the creator is one already)
	order = {"Owner", "Admin", "Moderator", "Helper"},
	roles = {
		Owner     = {rank = 100, color = Color3.fromRGB(255, 196, 60), perms = "*"},
		Admin     = {rank = 60, color = Color3.fromRGB(235, 84, 72),
			perms = {"view", "kick", "tempban", "ban", "teleport", "health", "announce", "announce_all", "rounds", "bots", "drops",
				"currency", "items", "unlock", "progress", "staff", "log"}},
		Moderator = {rank = 40, color = Color3.fromRGB(84, 150, 245),
			perms = {"view", "kick", "tempban", "teleport", "health", "announce", "rounds", "log"}},
		Helper    = {rank = 20, color = Color3.fromRGB(110, 205, 120),
			perms = {"view", "kick", "teleport", "announce"}},
	},
}
