--[[ PLAYTIME GIFTS — six gifts a day for the minutes you play. Every server
     counts (the Courtyard and every match); the clock and the gifts start over
     at 00:00 UTC. A gift waits until it is claimed: the gift chip at the top
     of the screen, or the lobby's PLAYTIME GIFTS panel.
       gifts   {minutes = played today, reward = …}, in order. A reward is the
               same as a pass reward: {marks = n} · {crowns = n} · {egg = "Speckled"}
               · {crate = "Bladesmith"} (one free open) · {skin} · {title} ·
               {killfx} · {emote} · {companion}
       wishes  the Courtyard's wishing fountain: one wish a day, a reward drawn
               by weight ]]
return {
	gifts = {
		{minutes = 5,  reward = {marks = 100}},
		{minutes = 10, reward = {egg = "Speckled"}},
		{minutes = 20, reward = {marks = 250}},
		{minutes = 30, reward = {crate = "Bladesmith"}},
		{minutes = 45, reward = {egg = "Mossy"}},
		{minutes = 60, reward = {crowns = 10}},
	},
	wishes = {
		{weight = 40, reward = {marks = 60}},
		{weight = 25, reward = {marks = 120}},
		{weight = 12, reward = {marks = 250}},
		{weight = 10, reward = {egg = "Speckled"}},
		{weight = 6,  reward = {egg = "Mossy"}},
		{weight = 5,  reward = {crowns = 5}},
		{weight = 2,  reward = {egg = "Ember"}},
	},
}
