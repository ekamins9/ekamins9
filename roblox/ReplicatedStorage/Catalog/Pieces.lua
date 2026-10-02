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
        Covers      = {"Hair"}           -- what the helmet hides: "Hair", "Face", both, or {}
        HelmName / TopName / LegsName    -- optional per-piece names
     Color blocks: give any part in the models an attribute ColorSlot =
     "Primary" | "Secondary" | "Accent" | "Metal" and the player's colors paint
     it (Primary turns team-colored in team modes). Parts without it keep
     their own color.

     EXPLICIT PIECES below are for one-off pieces that are not a whole set:
     put a folder Cosmetics ▸ Pieces ▸ <id> holding just the models that slot
     wears (helmet: HeadClothing · top: TorsoClothing, LeftArmClothing,
     RightArmClothing · bottom: LeftLegClothing, RightLegClothing). Fields:
        id, name, slot ("helmet"|"top"|"bottom"), pack, rarity, marks, crowns,
        covers (helmets), model (folder name if not the id), description
     An explicit entry with the same id as an auto piece overrides its fields
     (so you can reprice one auto piece without touching the set). ]]

return {
	AUTO_FROM_SETS = true,
	PIECES = {
		-- {id = "Sallet", name = "Sallet", slot = "helmet", pack = "IronCrow", rarity = "Epic", marks = 900, crowns = 45, covers = {"Hair"}},
	},
}
