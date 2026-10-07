--[[ PIECES — helmets, tops and bottoms.

     YOU USUALLY DON'T NEED TO LIST ANYTHING HERE. With AUTO_FROM_SETS on,
     every armor set folder (ReplicatedStorage ▸ Cosmetics ▸ Armor ▸ <Set>, the
     same layout as your ServerStorage ▸ Armor sets: Config + HeadClothing /
     TorsoClothing / …Clothing models around a Middle part) becomes three
     pieces named <Set>_Helm, <Set>_Top, <Set>_Legs. The set's Config decides:
        Type        = "Heavy"            -- the weight (required)
        Name        = "Iron Crow"        -- piece names become "Iron Crow Helm" …
        Pack        = "IronCrow"         -- a key in Packs (default Starter_<Type>)
        Rarity      = "Rare"             -- Common | Rare | Epic | Legendary
        PriceMarks  = 700                -- 0 (default) = free
        PriceCrowns = 35
        Covers      = {"Hair"}           -- what the helmet hides: "Hair", "Face" (face and beard), "Beard", or {}
        HelmName / TopName / LegsName    -- optional per-piece names
     Color blocks: give any part in the models an attribute ColorSlot =
     "Primary" | "Secondary" | "Accent" | "Metal" and the player's colors paint
     it (Primary turns team-colored in team modes). Parts without it keep
     their own color.

     EXPLICIT PIECES below are for one-off pieces that are not a whole set:
     put a folder Cosmetics ▸ Pieces ▸ <id> holding just the models that slot
     wears (helmet: HeadClothing · top: TorsoClothing, LeftArmClothing,
     RightArmClothing · bottom: LeftLegClothing, RightLegClothing). Fields:
        id, name, slot ("helmet"|"top"|"bottom"), weight, pack, rarity, marks, crowns,
        covers (helmets), model (folder name if not the id), description,
        unlock   = {level = n} | {kills = n[, family = "Polearm" | weapon = "Hammer"]}
                 | {wins = n[, bracket = "1v1"]} | {stat = "parry", n = 200}
                   → EARNED, never sold (put it in pack "Earned")
     An explicit entry with the same id as an auto piece overrides its fields
     (so you can reprice one auto piece without touching the set). ]]

return {
	AUTO_FROM_SETS = true,
	PIECES = {
		-- EARNED IN BATTLE (Cosmetics ▸ Pieces ▸ <id>)
		{id = "WolfPeltHood",       name = "Wolf Pelt Hood",        slot = "helmet", weight = "Light",  pack = "Earned", rarity = "Epic",      covers = {"Hair"},
		 unlock = {kills = 100, family = "Polearm"},  description = "The pelt of the first wolf you ever ran down with a fork."},
		{id = "RunnersWraps",       name = "Runner's Wraps",        slot = "bottom", weight = "Light",  pack = "Earned", rarity = "Rare",
		 unlock = {stat = "parry", n = 200},          description = "Wrapped legs of a fighter who turns every blade aside."},
		{id = "HuntersCloak",       name = "Hunter's Cloak",        slot = "top",    weight = "Light",  pack = "Earned", rarity = "Epic",
		 unlock = {level = 10},                       description = "A fur-collared hunting cloak, a horn at the hip. Level 10."},
		{id = "BloodiedKettle",     name = "Bloodied Kettle Helm",  slot = "helmet", weight = "Medium", pack = "Earned", rarity = "Epic",      covers = {"Hair"},
		 unlock = {kills = 150, family = "OneHanded"}, description = "A kettle hat that has seen too many swords."},
		{id = "SergeantsSurcoat",   name = "Sergeant's Surcoat",    slot = "top",    weight = "Medium", pack = "Earned", rarity = "Rare",
		 unlock = {wins = 25},                        description = "Worn by those who have carried a round to its end, twenty-five times."},
		{id = "DuelistsSallet",     name = "Duelist's Sallet",      slot = "helmet", weight = "Medium", pack = "Earned", rarity = "Legendary", covers = {"Hair", "Face"},
		 unlock = {wins = 10, bracket = "1v1"},       description = "Visored and silent. Ten wins alone in The Lists."},
		{id = "ChampionsGreatHelm", name = "Champion's Great Helm", slot = "helmet", weight = "Heavy",  pack = "Earned", rarity = "Legendary", covers = {"Hair", "Face"},
		 unlock = {kills = 200, family = "TwoHanded"}, description = "A sugarloaf helm crowned in gold, for the two-hander who has felled two hundred."},
		{id = "BanneretsTabard",    name = "Banneret's Tabard",     slot = "top",    weight = "Heavy",  pack = "Earned", rarity = "Epic",
		 unlock = {level = 25},                       description = "Plate under a banner-cloth. Level 25."},
		{id = "VeteransChausses",   name = "Veteran's Chausses",    slot = "bottom", weight = "Heavy",  pack = "Earned", rarity = "Epic",
		 unlock = {kills = 500},                      description = "Scarred mail legs. Five hundred kills, any weapon."},
	},
}
