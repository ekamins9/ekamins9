--[[ COMPANIONS — little creatures that follow you around the Courtyard and
     your matches. They hatch from eggs (Catalog ▸ Eggs); one is out at a time
     (HATCHERY ▸ COMPANIONS). Looks only, never stats.
       id, name, rarity, description
       body     the shape, built from parts by ReplicatedStorage ▸ Companions:
                bird · beast · hopper · wisp · drake
       size     scale (1 = about knee high)
       main / second / accent   colours (body; belly, wings, mane; eyes, beak, horns)
       glow     a Neon colour for glowing bits (optional)
       style    a twist on the body: walker (a bird that walks), owl, mane,
                antlers, longears, crown, beak (a drake with a beak: a griffin)
       fx       world-only particles: embers · frost · spirit · sparkle
       egg      only that egg hatches it (default: any egg, by rarity)
       pass     a season-pass reward (never hatched)
     Duplicates add a star (up to Catalog ▸ Eggs ▸ stars); five stars sparkle. ]]
local C = Color3.fromRGB
return {
	-- Common
	{id = "Sparrow", name = "Sparrow", rarity = "Common", body = "bird", size = 0.8,
		main = C(124, 92, 62), second = C(228, 208, 176), accent = C(232, 160, 60), description = "Small, loud, everywhere."},
	{id = "Hen", name = "Barn Hen", rarity = "Common", body = "bird", size = 1, style = "walker",
		main = C(242, 238, 228), second = C(222, 212, 192), accent = C(214, 56, 44), description = "Struts behind you like she owns the yard."},
	{id = "Rat", name = "Cellar Rat", rarity = "Common", body = "beast", size = 0.65,
		main = C(124, 118, 112), second = C(224, 166, 166), accent = C(24, 24, 28), description = "Knows every crack in the castle wall."},
	{id = "Toad", name = "Pond Toad", rarity = "Common", body = "hopper", size = 0.8,
		main = C(110, 130, 72), second = C(204, 194, 134), accent = C(30, 30, 20), description = "Ribbit."},
	{id = "Piglet", name = "Piglet", rarity = "Common", body = "beast", size = 0.8,
		main = C(242, 172, 172), second = C(222, 140, 140), accent = C(40, 30, 30), description = "Muddy and proud of it."},
	-- Rare
	{id = "Raven", name = "Raven", rarity = "Rare", body = "bird", size = 0.95,
		main = C(38, 38, 46), second = C(64, 66, 86), accent = C(70, 70, 76), description = "Watches every duel. Remembers every face."},
	{id = "Owl", name = "Barn Owl", rarity = "Rare", body = "bird", size = 0.95, style = "owl",
		main = C(176, 128, 80), second = C(240, 226, 196), accent = C(255, 196, 40), description = "Wide awake at the night watch."},
	{id = "FoxKit", name = "Fox Kit", rarity = "Rare", body = "beast", size = 0.85,
		main = C(222, 112, 40), second = C(246, 240, 230), accent = C(30, 26, 24), description = "Quick paws, quicker grin."},
	{id = "BlackCat", name = "Black Cat", rarity = "Rare", body = "beast", size = 0.8,
		main = C(34, 34, 40), second = C(58, 58, 70), accent = C(130, 224, 96), description = "Unlucky for your enemies."},
	{id = "Hare", name = "Field Hare", rarity = "Rare", body = "hopper", size = 0.85, style = "longears",
		main = C(176, 146, 108), second = C(240, 232, 216), accent = C(30, 24, 20), description = "Hops ahead, waits, hops again."},
	-- Epic
	{id = "WolfPup", name = "Wolf Pup", rarity = "Epic", body = "beast", size = 1,
		main = C(132, 136, 144), second = C(224, 228, 232), accent = C(110, 176, 255), description = "Will grow into a legend. Not yet."},
	{id = "MossDrake", name = "Moss Drake", rarity = "Epic", body = "drake", size = 0.9,
		main = C(84, 132, 64), second = C(194, 204, 122), accent = C(232, 222, 190), description = "A forest dragon, pocket-sized."},
	{id = "Wisp", name = "Ghost Wisp", rarity = "Epic", body = "wisp", size = 0.9, fx = "spirit",
		main = C(150, 214, 255), second = C(236, 248, 255), accent = C(40, 60, 90), glow = C(120, 200, 255), description = "A friendly light from the old crypts."},
	{id = "Falcon", name = "Hunting Falcon", rarity = "Epic", body = "bird", size = 1,
		main = C(112, 92, 72), second = C(176, 176, 186), accent = C(250, 196, 60), description = "Hooded, belled, and very fast."},
	{id = "FrostFox", name = "Frost Fox", rarity = "Epic", body = "beast", size = 0.9, fx = "frost", egg = "Royal",
		main = C(226, 238, 255), second = C(166, 204, 244), accent = C(70, 130, 220), description = "Leaves a little snow wherever it sits."},
	-- Legendary
	{id = "Phoenix", name = "Phoenix Chick", rarity = "Legendary", body = "bird", size = 0.95, fx = "embers",
		main = C(255, 132, 40), second = C(255, 212, 84), accent = C(255, 236, 160), glow = C(255, 150, 50), description = "Reborn every morning. Slightly singed."},
	{id = "EmberDrake", name = "Ember Drake", rarity = "Legendary", body = "drake", size = 1, fx = "embers",
		main = C(150, 32, 30), second = C(242, 162, 64), accent = C(40, 30, 30), glow = C(255, 120, 40), description = "Breathes sparks when it's happy."},
	{id = "LionCub", name = "Lion Cub", rarity = "Legendary", body = "beast", size = 1, style = "mane",
		main = C(222, 172, 82), second = C(172, 92, 40), accent = C(36, 26, 20), description = "A king's crest in miniature."},
	{id = "SpiritStag", name = "Spirit Stag", rarity = "Legendary", body = "beast", size = 1.05, style = "antlers", fx = "spirit",
		main = C(232, 240, 255), second = C(196, 214, 240), accent = C(60, 90, 140), glow = C(140, 220, 255), description = "Walks without a sound. Glows a little."},
	{id = "Griffin", name = "Griffin", rarity = "Legendary", body = "drake", size = 1.05, style = "beak", egg = "Royal",
		main = C(196, 142, 78), second = C(244, 240, 228), accent = C(250, 196, 60), description = "Half eagle, half lion, all attitude."},
	-- the season pass
	{id = "IronHound", name = "Iron Hound", rarity = "Legendary", body = "beast", size = 1, style = "crown", pass = true,
		main = C(112, 114, 122), second = C(70, 72, 80), accent = C(230, 182, 60), description = "The Iron Crown's own hound. Season 1."},
}
