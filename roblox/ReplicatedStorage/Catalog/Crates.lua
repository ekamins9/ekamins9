--[[ CRATES — a named loot table of weapon skins. A skin joins a crate by
     naming it (crate = "Bladesmith" in Skins) or by being listed in `skins`.
       name, description   shown on the card
       cost      Crowns per open
       odds      per-rarity percentages, must sum to 100 (shown to the player)
       pity      a Legendary is guaranteed within this many opens
       refund    Marks paid back for a duplicate, per rarity
     Add a crate: add a key here and point some skins at it. That's it. ]]
return {
	Bladesmith = {
		name = "Bladesmith's Crate", description = "Sword skins: shortsword, greatsword.",
		cost = 60, odds = {Common = 60, Rare = 28, Epic = 10, Legendary = 2}, pity = 20,
		refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000},
	},
	Hafted = {
		name = "Hafted Crate", description = "Hammer and polearm skins.",
		cost = 60, odds = {Common = 60, Rare = 28, Epic = 10, Legendary = 2}, pity = 20,
		refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000},
	},
}
