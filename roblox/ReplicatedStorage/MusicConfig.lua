--[[ MUSIC CONFIG — the score, by situation (StarterPlayerScripts ▸ Music plays it).
     Every track is from APM Music, licensed for every Roblox experience. A
     list plays shuffled, crossfading from one track to the next; a track that
     won't load is skipped. Swap ids here: nothing else needs touching.

       Hub          the Courtyard and the menus: calm, courtly
       Intermission between rounds (the vote): low and tense
       Battle       any match
       HordeWave    the horde is coming / on you
       HordeBreak   between waves: breathe, but don't relax
       Boss         a warlord / champion is alive (Bot attribute Boss)
       Win / Lose   a short sting when a round ends, by whether you won ]]

return {
	VOLUME = 0.32,          -- × the player's Music slider
	FADE = 2.2,             -- seconds a crossfade takes
	TRACKS = {
		Hub          = {1837300629, 9039609965, 1837143003},
		Intermission = {9046505640, 9046506025},
		Battle       = {1845349070, 1836104000, 9046503137, 1842059120, 1836104037},
		HordeWave    = {1835323368, 1846799749, 1836763823, 1836763514},
		HordeBreak   = {9046506025, 9046505640},
		Boss         = {1843640242, 9046496901},
	},
	STINGS = {
		Win  = {1835324771, 1840296036, 1835295052, 136010378542579},
		Lose = {115055593775910},
	},
}
