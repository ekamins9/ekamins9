--[[ EXECUTIONS — the finisher YOU play on an enemy who is bleeding out (press
     R / the Execute key near one, in front of you). One equipped at a time
     (ARMORY ▸ EXECUTIONS); looks only, never stats: every execution kills at
     its blow and locks both fighters for its length, so a longer one is a
     bolder one (a teammate can still save the victim by hitting you).
     The clips are ReplicatedStorage ▸ ExecutionAnims ▸ <id> (Animation, attribute
     Impact = seconds to the blow), built by ServerScriptService ▸ Build ▸
     ExecutionAnims from the game's own clips.
       id, name, rarity, description
       finish      how the blow kills: "behead" (default) or "stab" (run through)
     WHERE IT COMES FROM: free = true · crate = "Relic" · pass · unlock = {...} ]]
return {
	{id = "Finisher",     name = "Finisher",       rarity = "Common",    free = true,     description = "Raised high, a breath, brought down hard."},
	{id = "Skewer",       name = "Skewer",         rarity = "Rare",      crate = "Relic", finish = "stab", description = "Drawn back, driven through, twisted, pulled free."},
	{id = "HeadsmansDue", name = "Headsman's Due", rarity = "Epic",      crate = "Relic", description = "The long pause before the drop. Everyone watches."},
	{id = "Kingslayer",   name = "Kingslayer",     rarity = "Legendary", crate = "Relic", description = "A cut across to bring them down, then the end."},
}
