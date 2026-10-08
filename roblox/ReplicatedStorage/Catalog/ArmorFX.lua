--[[ ARMOR FINISHES — what your armor looks like on top of its set, the way a
     skin dresses a weapon: the plates recoloured, the trims set alight, and
     something coming off it (embers, frost, sparks, smoke, starlight). One per
     class (LOADOUT ▸ FINISH), on any set of any weight: looks only, never stats.
     They come out of the FORGE CRATE as copies of their own ("finish:" .. id):
     trade the spare, scrap it, or keep it. The rarer, the more alive.

       id, name, rarity, crate, description
       look = {
         metal = Color3, metalMaterial = "Foil",  the plates (Metal slot, and any metal part)
         accent = Color3, glow = true,             the trims (Accent slot, gilt bits, rivets): glowing Neon
         tint = {Color3, k},                       cloth and leather pulled towards a colour by k (0..1)
         body = "CrackedLava",                     (optional) a material for the cloth and leather
         aura = "embers",                          particles off the shoulders, arms and legs: an aura of
                                                   ReplicatedStorage ▸ SkinFX (embers, frost, holy, shadow,
                                                   storm, toxic, petals, gold, blood, celestial, inferno…)
         light = Color3,                           a soft glow round you (the world)
         pulse = true · flicker = true · radiant = true   the glowing trims breathe, crackle or walk the rainbow
       }
     A set can wear one built in: Finish = "Infernal" in its Config (worn with its TOP,
     unless the class picked another finish). ]]

local C = Color3.fromRGB

return {
	-- RARE: a new metal
	{id = "Gilded", name = "Gilded", rarity = "Rare", crate = "Forge",
	 description = "Every plate gilt, every rivet bright. Worth a king's ransom, and you'll be asked for one.",
	 look = {metal = C(232, 184, 74), metalMaterial = "Foil", accent = C(255, 246, 214)}},
	{id = "Blackened", name = "Blackened", rarity = "Rare", crate = "Forge",
	 description = "Fire-blackened steel and soot-dark cloth: nobody sees you coming at night.",
	 look = {metal = C(36, 36, 42), accent = C(120, 24, 24), tint = {C(20, 20, 24), 0.45}}},
	{id = "Bloodsteel", name = "Bloodsteel", rarity = "Rare", crate = "Forge",
	 description = "Plate the colour of a bad wound, cut with black.",
	 look = {metal = C(118, 26, 26), accent = C(30, 30, 34), tint = {C(70, 12, 12), 0.2}}},
	{id = "Verdigris", name = "Verdigris", rarity = "Rare", crate = "Forge",
	 description = "Old bronze gone green with the years, still sharp at the edges.",
	 look = {metal = C(86, 150, 128), accent = C(196, 150, 82)}},

	-- EPIC: it glows, and something comes off it
	{id = "Emberforged", name = "Emberforged", rarity = "Epic", crate = "Forge",
	 description = "Pulled from the forge before it cooled: the seams still glow, and sparks drift up off you.",
	 look = {metal = C(46, 40, 38), accent = C(255, 124, 40), glow = true, pulse = true, aura = "embers", light = C(255, 130, 50)}},
	{id = "Frostbound", name = "Frostbound", rarity = "Epic", crate = "Forge",
	 description = "Plate grown over with ice that never melts. Snow falls round you wherever you stand.",
	 look = {metal = C(186, 226, 255), metalMaterial = "Ice", accent = C(120, 200, 255), glow = true, pulse = true, aura = "frost", light = C(150, 210, 255), tint = {C(200, 230, 255), 0.25}}},
	{id = "Verdant", name = "Verdant", rarity = "Epic", crate = "Forge",
	 description = "The forest took the armor back. Moss on the plates, and leaves wherever you walk.",
	 look = {metal = C(72, 110, 62), metalMaterial = "Slate", accent = C(140, 255, 120), glow = true, pulse = true, aura = "toxic", light = C(120, 230, 100), tint = {C(54, 84, 40), 0.35}}},
	{id = "Rosewarden", name = "Rosewarden", rarity = "Epic", crate = "Forge",
	 description = "White plate and red roses, petals drifting off your shoulders. Lovely. Lethal.",
	 look = {metal = C(236, 232, 226), accent = C(232, 64, 114), glow = true, aura = "petals", light = C(255, 150, 190)}},

	-- LEGENDARY: the armor is alive
	{id = "Stormborn", name = "Stormborn", rarity = "Legendary", crate = "Forge",
	 description = "The storm lives in the plates now. It crackles at the seams and arcs off your arms.",
	 look = {metal = C(58, 68, 96), accent = C(150, 215, 255), glow = true, flicker = true, aura = "storm", light = C(140, 200, 255)}},
	{id = "Voidtouched", name = "Voidtouched", rarity = "Legendary", crate = "Forge",
	 description = "Something looked back from the dark and marked the steel. Smoke clings to you, purple light leaks out.",
	 look = {metal = C(22, 18, 30), accent = C(176, 86, 255), glow = true, pulse = true, aura = "shadow", light = C(160, 80, 255), tint = {C(30, 20, 46), 0.55}}},
	{id = "Sunblessed", name = "Sunblessed", rarity = "Legendary", crate = "Forge",
	 description = "White-gold plate in a halo of drifting light. They see you before the sunrise does.",
	 look = {metal = C(252, 244, 226), metalMaterial = "Foil", accent = C(255, 214, 96), glow = true, pulse = true, aura = "holy", light = C(255, 230, 160), tint = {C(255, 246, 228), 0.3}}},

	-- MYTHIC: a story
	{id = "Celestial", name = "Celestial", rarity = "Mythic", crate = "Forge",
	 description = "Plate cut from the night sky itself. Its trims walk every colour there is, and stars fall off you.",
	 look = {metal = C(28, 34, 84), accent = C(190, 150, 255), glow = true, radiant = true, aura = "celestial", light = C(170, 150, 255), tint = {C(36, 28, 90), 0.55}}},
	{id = "Infernal", name = "Infernal", rarity = "Mythic", crate = "Forge",
	 description = "Black rock and molten seams: armor that came up out of a volcano with you still inside it. You burn as you walk.",
	 look = {metal = C(34, 26, 24), metalMaterial = "Basalt", accent = C(255, 96, 20), glow = true, pulse = true, body = "CrackedLava", aura = "inferno", light = C(255, 110, 40)}},
}
