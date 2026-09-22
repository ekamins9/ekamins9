-- ServerStorage/Armor/KnightSkin/Config  (ModuleScript inside the armor set)
-- Only list what differs from Armor.DEFAULTS. This example is the heavy set;
-- copy it into each of your sets and tune. Type is display + menu ordering.
return {
	Name        = "Knight Skin",
	Description = "A beautiful shiny suit of armor, worn only by the finest of knights. Slow, heavy, and very hard to cut.",
	Type        = "Heavy",       -- Light | Medium | Heavy
	Health      = 50,            -- extra max health
	SpeedMult   = 0.75,          -- 25% slower
	ClunkMult   = 1.8,           -- much heavier footsteps
	Protection  = 0.35,          -- 35% less damage on every limb this set covers
}
