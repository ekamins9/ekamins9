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
		name = "Bladesmith's Crate", description = "Sword skins: every blade from dagger to zweihander.",
		cost = 60, odds = {Common = 55, Rare = 30, Epic = 12, Legendary = 3}, pity = 20,
		refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000},
	},
	Hafted = {
		name = "Hafted Crate", description = "Axe, hammer, mace and polearm skins.",
		cost = 60, odds = {Common = 55, Rare = 30, Epic = 12, Legendary = 3}, pity = 20,
		refund = {Common = 150, Rare = 400, Epic = 900, Legendary = 2000},
	},
	Royal = {
		name = "Royal Armoury", description = "No Commons. Heraldic steel for every weapon and the four crown jewels.",
		cost = 120, odds = {Rare = 50, Epic = 38, Legendary = 12}, pity = 10,
		refund = {Rare = 500, Epic = 1200, Legendary = 3000},
	},
}
