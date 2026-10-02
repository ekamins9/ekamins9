--[[ CONTRACTS — daily goals that pay Marks. Three are drawn per day from this
     pool (seeded by the date, so everyone has the same three), one weekly.
       stat   a counter the server keeps: "kill", "parry", "chamber", "win",
              "round", "drill", "kill_OneHanded", "kill_TwoHanded", "kill_Polearm",
              "win_2v2", "win_3v3", "win_1v1", "hill" (seconds on the hill)
       goal   how many        pay   Marks        weekly  true = in the weekly pool ]]
return {
	{id = "parry20",   text = "Land 20 parries",              stat = "parry",          goal = 20, pay = 150},
	{id = "kill15",    text = "Kill 15 players",              stat = "kill",           goal = 15, pay = 150},
	{id = "pole10",    text = "Kill 10 with a polearm",       stat = "kill_Polearm",   goal = 10, pay = 200},
	{id = "two10",     text = "Kill 10 with a two-hander",    stat = "kill_TwoHanded", goal = 10, pay = 200},
	{id = "one10",     text = "Kill 10 with a one-hander",    stat = "kill_OneHanded", goal = 10, pay = 200},
	{id = "chamber5",  text = "Chamber 5 attacks",            stat = "chamber",        goal = 5,  pay = 250},
	{id = "rounds3",   text = "Finish 3 rounds",              stat = "round",          goal = 3,  pay = 150},
	{id = "win2",      text = "Win 2 rounds",                 stat = "win",            goal = 2,  pay = 200},
	{id = "drill3",    text = "Finish 3 Tiltyard drills",     stat = "drill",          goal = 3,  pay = 150},
	{id = "duel1",     text = "Win a 1v1 in The Lists",       stat = "win_1v1",        goal = 1,  pay = 300},
	{id = "weekKills", text = "Kill 100 players this week",   stat = "kill",           goal = 100, pay = 1000, weekly = true},
	{id = "weekWins",  text = "Win 10 rounds this week",      stat = "win",            goal = 10,  pay = 1000, weekly = true},
}
