--[[ CONTRACTS — daily goals that pay Marks. Three are drawn per day from this
     pool (seeded by the date, so everyone has the same three), one weekly.
       stat   a counter the server keeps: "kill", "parry", "chamber", "win",
              "round", "drill", "kill_OneHanded", "kill_TwoHanded", "kill_Polearm",
              "win_2v2", "win_3v3", "win_1v1", "hill" (seconds on the hill)
       goal   how many        pay   Marks        weekly  true = in the weekly pool ]]
return {
	{id = "parry20",   text = "Land 20 parries",              stat = "parry",          goal = 20, pay = 150},
	{id = "parry50",   text = "Land 50 parries",              stat = "parry",          goal = 50, pay = 300},
	{id = "kill15",    text = "Kill 15 players",              stat = "kill",           goal = 15, pay = 150},
	{id = "kill30",    text = "Kill 30 players",              stat = "kill",           goal = 30, pay = 300},
	{id = "pole10",    text = "Kill 10 with a polearm",       stat = "kill_Polearm",   goal = 10, pay = 200},
	{id = "two10",     text = "Kill 10 with a two-hander",    stat = "kill_TwoHanded", goal = 10, pay = 200},
	{id = "one10",     text = "Kill 10 with a one-hander",    stat = "kill_OneHanded", goal = 10, pay = 200},
	{id = "chamber5",  text = "Chamber 5 attacks",            stat = "chamber",        goal = 5,  pay = 250},
	{id = "chamber12", text = "Chamber 12 attacks",           stat = "chamber",        goal = 12, pay = 450},
	{id = "rounds3",   text = "Finish 3 rounds",              stat = "round",          goal = 3,  pay = 150},
	{id = "rounds6",   text = "Finish 6 rounds",              stat = "round",          goal = 6,  pay = 280},
	{id = "win2",      text = "Win 2 rounds",                 stat = "win",            goal = 2,  pay = 200},
	{id = "win4",      text = "Win 4 rounds",                 stat = "win",            goal = 4,  pay = 380},
	{id = "hill120",   text = "Hold the hill for 2 minutes",  stat = "hill",           goal = 120, pay = 250},
	{id = "drill1",    text = "Finish a Tiltyard drill",      stat = "drill",          goal = 1,  pay = 80},
	{id = "drill3",    text = "Finish 3 Tiltyard drills",     stat = "drill",          goal = 3,  pay = 150},
	{id = "duel1",     text = "Win a 1v1 in The Lists",       stat = "win_1v1",        goal = 1,  pay = 300},
	{id = "pair1",     text = "Win a 2v2 in The Lists",       stat = "win_2v2",        goal = 1,  pay = 300},
	{id = "trio1",     text = "Win a 3v3 in The Lists",       stat = "win_3v3",        goal = 1,  pay = 300},
	{id = "weekKills", text = "Kill 100 players this week",   stat = "kill",           goal = 100, pay = 1000, weekly = true},
	{id = "weekWins",  text = "Win 10 rounds this week",      stat = "win",            goal = 10,  pay = 1000, weekly = true},
	{id = "weekParry", text = "Land 150 parries this week",   stat = "parry",          goal = 150, pay = 1000, weekly = true},
	{id = "weekDuels", text = "Win 5 duels in The Lists this week", stat = "win_1v1",  goal = 5,   pay = 1200, weekly = true},
	{id = "weekChamber", text = "Chamber 30 attacks this week", stat = "chamber",      goal = 30,  pay = 1200, weekly = true},
}
