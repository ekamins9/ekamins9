--[[ PLAYTIME GIFTS — six gifts a day for the minutes you play. Every server
     counts (the Courtyard and every match); the clock and the gifts start over
     at 00:00 UTC. A gift waits until it is claimed: the gift chip at the top
     of the screen, or the lobby's PLAYTIME GIFTS panel.
       gifts   {minutes = played today, reward = …}, in order. A reward is the
               same as a pass reward: {marks = n} · {crowns = n} · {egg = "Speckled"}
               · {crate = "Bladesmith"} (one free open) · {skin} · {title} ·
               {killfx} · {emote} · {companion} ]]
return {
	gifts = {
		{minutes = 5,  reward = {marks = 100}},
		{minutes = 10, reward = {egg = "Speckled"}},
		{minutes = 20, reward = {marks = 250}},
		{minutes = 30, reward = {crate = "Bladesmith"}},
		{minutes = 45, reward = {egg = "Mossy"}},
		{minutes = 60, reward = {crowns = 10}},
	},
}
