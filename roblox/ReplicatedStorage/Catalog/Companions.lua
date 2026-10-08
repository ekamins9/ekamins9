--[[ COMPANIONS — little creatures that follow you around the Courtyard and
     your matches. They hatch from eggs (Catalog ▸ Eggs); one is out at a time
     (HATCHERY ▸ COMPANIONS). Looks only, never stats.
       id, name, rarity, description
       body     the shape, built from parts by ReplicatedStorage ▸ Companions:
                bird · beast · hopper · wisp · drake · snake · turtle · crab
       size     scale (1 = about knee high)
       main / second / accent   colours (body; belly, wings, mane; eyes, beak, horns)
       glow     a Neon colour for glowing bits (optional)
       style    a twist on the body: walker (a bird that walks), owl, mane,
                antlers, longears, crown, beak (a drake with a beak: a griffin)
       fx       world-only particles: embers · frost · spirit · sparkle
       egg      the egg that hatches it: every egg has its own companions (themed:
                Speckled farm and shore, Mossy woods and marsh, Ember fire and night,
                Royal the crown's beasts), so none of them hatch from every egg
       pass     a season-pass reward (never hatched)
       drop     hidden until that drop of Catalog ▸ Calendar is out
       style    (more) bat (a drake as a bat) · pumpkin (a wisp) · bones (a skeleton
                beast) · tusks · reindeer · round (round ears) · kraken (a wisp with arms) ·
                spines (a hedgehog beast) · horn (a unicorn beast) · hood (a cobra snake) ·
                grove (a tree on a turtle's shell)
     Every hatch also rolls a VARIANT (Catalog ▸ Eggs ▸ variants): Golden or Spectral.
     Duplicates add a star (up to Catalog ▸ Eggs ▸ stars); five stars sparkle. ]]
local C = Color3.fromRGB
return {
	-- Common
	{id = "Sparrow", name = "Sparrow", rarity = "Common", egg = "Speckled", body = "bird", size = 0.8,
		main = C(124, 92, 62), second = C(228, 208, 176), accent = C(232, 160, 60), description = "Small, loud, everywhere."},
	{id = "Hen", name = "Barn Hen", rarity = "Common", egg = "Speckled", body = "bird", size = 1, style = "walker",
		main = C(242, 238, 228), second = C(222, 212, 192), accent = C(214, 56, 44), description = "Struts behind you like she owns the yard."},
	{id = "Rat", name = "Cellar Rat", rarity = "Common", egg = "Mossy", body = "beast", size = 0.65,
		main = C(124, 118, 112), second = C(224, 166, 166), accent = C(24, 24, 28), description = "Knows every crack in the castle wall."},
	{id = "Toad", name = "Pond Toad", rarity = "Common", egg = "Mossy", body = "hopper", size = 0.8,
		main = C(110, 130, 72), second = C(204, 194, 134), accent = C(30, 30, 20), description = "Ribbit."},
	{id = "Piglet", name = "Piglet", rarity = "Common", egg = "Speckled", body = "beast", size = 0.8,
		main = C(242, 172, 172), second = C(222, 140, 140), accent = C(40, 30, 30), description = "Muddy and proud of it."},
	-- Rare
	{id = "Raven", name = "Raven", rarity = "Rare", egg = "Ember", body = "bird", size = 0.95,
		main = C(38, 38, 46), second = C(64, 66, 86), accent = C(70, 70, 76), description = "Watches every duel. Remembers every face."},
	{id = "Owl", name = "Barn Owl", rarity = "Rare", egg = "Mossy", body = "bird", size = 0.95, style = "owl",
		main = C(176, 128, 80), second = C(240, 226, 196), accent = C(255, 196, 40), description = "Wide awake at the night watch."},
	{id = "FoxKit", name = "Fox Kit", rarity = "Rare", egg = "Mossy", body = "beast", size = 0.85,
		main = C(222, 112, 40), second = C(246, 240, 230), accent = C(30, 26, 24), description = "Quick paws, quicker grin."},
	{id = "BlackCat", name = "Black Cat", rarity = "Rare", egg = "Ember", body = "beast", size = 0.8,
		main = C(34, 34, 40), second = C(58, 58, 70), accent = C(130, 224, 96), description = "Unlucky for your enemies."},
	{id = "Hare", name = "Field Hare", rarity = "Rare", egg = "Speckled", body = "hopper", size = 0.85, style = "longears",
		main = C(176, 146, 108), second = C(240, 232, 216), accent = C(30, 24, 20), description = "Hops ahead, waits, hops again."},
	-- Epic
	{id = "WolfPup", name = "Wolf Pup", rarity = "Epic", egg = "Speckled", body = "beast", size = 1,
		main = C(132, 136, 144), second = C(224, 228, 232), accent = C(110, 176, 255), description = "Will grow into a legend. Not yet."},
	{id = "MossDrake", name = "Moss Drake", rarity = "Epic", egg = "Mossy", body = "drake", size = 0.9,
		main = C(84, 132, 64), second = C(194, 204, 122), accent = C(232, 222, 190), description = "A forest dragon, pocket-sized."},
	{id = "Wisp", name = "Ghost Wisp", rarity = "Epic", egg = "Ember", body = "wisp", size = 0.9, fx = "spirit",
		main = C(150, 214, 255), second = C(236, 248, 255), accent = C(40, 60, 90), glow = C(120, 200, 255), description = "A friendly light from the old crypts."},
	{id = "Falcon", name = "Hunting Falcon", rarity = "Epic", egg = "Mossy", body = "bird", size = 1,
		main = C(112, 92, 72), second = C(176, 176, 186), accent = C(250, 196, 60), description = "Hooded, belled, and very fast."},
	{id = "FrostFox", name = "Frost Fox", rarity = "Epic", body = "beast", size = 0.9, fx = "frost", egg = "Royal",
		main = C(226, 238, 255), second = C(166, 204, 244), accent = C(70, 130, 220), description = "Leaves a little snow wherever it sits."},
	-- Legendary
	{id = "Phoenix", name = "Phoenix Chick", rarity = "Legendary", egg = "Ember", body = "bird", size = 0.95, fx = "embers",
		main = C(255, 132, 40), second = C(255, 212, 84), accent = C(255, 236, 160), glow = C(255, 150, 50), description = "Reborn every morning. Slightly singed."},
	{id = "EmberDrake", name = "Ember Drake", rarity = "Legendary", egg = "Ember", body = "drake", size = 1, fx = "embers",
		main = C(150, 32, 30), second = C(242, 162, 64), accent = C(40, 30, 30), glow = C(255, 120, 40), description = "Breathes sparks when it's happy."},
	{id = "LionCub", name = "Lion Cub", rarity = "Legendary", egg = "Speckled", body = "beast", size = 1, style = "mane",
		main = C(222, 172, 82), second = C(172, 92, 40), accent = C(36, 26, 20), description = "A king's crest in miniature."},
	{id = "SpiritStag", name = "Spirit Stag", rarity = "Legendary", egg = "Mossy", body = "beast", size = 1.05, style = "antlers", fx = "spirit",
		main = C(232, 240, 255), second = C(196, 214, 240), accent = C(60, 90, 140), glow = C(140, 220, 255), description = "Walks without a sound. Glows a little."},
	{id = "Griffin", name = "Griffin", rarity = "Legendary", body = "drake", size = 1.05, style = "beak", egg = "Royal",
		main = C(196, 142, 78), second = C(244, 240, 228), accent = C(250, 196, 60), description = "Half eagle, half lion, all attitude."},
	-- MORE: snakes, tortoises, crabs and friends (any of the Hatchery's own eggs)
	{id = "Duckling", name = "Duckling", rarity = "Common", egg = "Speckled", body = "bird", style = "walker", size = 0.7,
		main = C(255, 214, 70), second = C(255, 236, 140), accent = C(255, 140, 40), description = "Follows the first knight it saw. That's you."},
	{id = "Tortoise", name = "Tortoise", rarity = "Common", egg = "Mossy", body = "turtle", size = 0.9,
		main = C(112, 92, 60), second = C(150, 160, 100), accent = C(140, 116, 74), description = "In no hurry. Gets there anyway."},
	{id = "ShoreCrab", name = "Shore Crab", rarity = "Common", egg = "Speckled", body = "crab", size = 0.75,
		main = C(210, 90, 60), second = C(240, 170, 130), accent = C(230, 80, 50), description = "Walks sideways into every fight."},
	{id = "GrassSnake", name = "Grass Snake", rarity = "Common", egg = "Mossy", body = "snake", size = 0.9,
		main = C(100, 140, 70), second = C(220, 210, 120), accent = C(220, 60, 60), description = "Harmless. Mostly."},
	{id = "Hedgehog", name = "Hedgehog", rarity = "Common", egg = "Speckled", body = "beast", style = "spines", size = 0.6,
		main = C(176, 140, 104), second = C(96, 74, 58), accent = C(30, 24, 20), description = "Prickly on the outside. Also on the inside."},
	{id = "Corgi", name = "Corgi", rarity = "Rare", egg = "Speckled", body = "beast", size = 0.75,
		main = C(226, 150, 70), second = C(250, 244, 236), accent = C(30, 24, 20), description = "Short legs, long loyalty."},
	{id = "Adder", name = "Adder", rarity = "Rare", egg = "Mossy", body = "snake", size = 1,
		main = C(110, 96, 80), second = C(40, 34, 30), accent = C(200, 40, 40), description = "Zig-zag back, bad temper."},
	{id = "SnapTurtle", name = "Snapping Turtle", rarity = "Rare", egg = "Mossy", body = "turtle", size = 1,
		main = C(70, 80, 60), second = C(120, 124, 92), accent = C(56, 64, 48), description = "Bites first. Asks never."},
	{id = "RedPanda", name = "Red Panda", rarity = "Rare", egg = "Speckled", body = "beast", style = "round", size = 0.75,
		main = C(200, 90, 40), second = C(250, 240, 230), accent = C(40, 26, 20), description = "Rings on its tail, mischief in its eyes."},
	{id = "Cobra", name = "Royal Cobra", rarity = "Epic", egg = "Royal", body = "snake", style = "hood", size = 1.05,
		main = C(180, 150, 70), second = C(236, 214, 150), accent = C(230, 60, 40), description = "Spreads its hood at anyone who blocks."},
	{id = "EmberToad", name = "Ember Toad", rarity = "Epic", egg = "Ember", body = "hopper", size = 0.85, fx = "embers",
		main = C(120, 40, 30), second = C(240, 140, 60), accent = C(255, 200, 80), glow = C(255, 120, 40), description = "Warm to the touch. Very warm."},
	{id = "CoralCrab", name = "Coral Crab", rarity = "Epic", egg = "Speckled", body = "crab", size = 0.9, fx = "sparkle",
		main = C(240, 110, 150), second = C(255, 200, 210), accent = C(255, 170, 90), glow = C(120, 255, 230), description = "Wears a reef on its back and glows in the dark."},
	{id = "JadeSerpent", name = "Jade Serpent", rarity = "Legendary", egg = "Mossy", body = "snake", size = 1.3, fx = "spirit",
		main = C(60, 170, 120), second = C(200, 240, 210), accent = C(240, 210, 90), glow = C(110, 255, 190), description = "Coiled round the old shrines for a thousand years. Now round you."},
	{id = "GroveTortoise", name = "Grove Tortoise", rarity = "Legendary", egg = "Mossy", body = "turtle", style = "grove", size = 1.1, fx = "spirit",
		main = C(90, 110, 70), second = C(160, 170, 110), accent = C(100, 140, 70), glow = C(150, 255, 130), description = "Carries a whole little forest. Never hurries it."},
	{id = "UnicornFoal", name = "Unicorn Foal", rarity = "Legendary", egg = "Royal", body = "beast", style = "horn", size = 1, fx = "sparkle",
		main = C(250, 250, 255), second = C(200, 170, 255), accent = C(60, 60, 80), glow = C(255, 220, 120), description = "Wobbly, sparkly, unstoppable."},
	{id = "Basilisk", name = "Basilisk", rarity = "Legendary", body = "snake", style = "hood", size = 1.2, fx = "embers", egg = "Royal",
		main = C(40, 44, 40), second = C(110, 30, 30), accent = C(255, 210, 60), glow = C(255, 80, 40), description = "Don't meet its eyes. It's fine. It likes you."},
	-- the season pass
	{id = "IronHound", name = "Iron Hound", rarity = "Legendary", body = "beast", size = 1, style = "crown", pass = true,
		main = C(112, 114, 122), second = C(70, 72, 80), accent = C(230, 182, 60), description = "The Iron Crown's own hound. Season 1."},

	-- THE DROPS' EGGS (Catalog ▸ Calendar): each egg's own, gone when the egg is
	-- GRAVE EGG — The Hollow Night
	{id = "Bat", name = "Belfry Bat", rarity = "Common", body = "drake", style = "bat", size = 0.6, egg = "Grave", drop = "HollowNight",
		main = C(40, 34, 44), second = C(70, 56, 76), accent = C(230, 210, 200), description = "Hangs upside down from your shoulder. Squeaks at owls."},
	{id = "PumpkinWisp", name = "Pumpkin Wisp", rarity = "Rare", body = "wisp", style = "pumpkin", size = 0.8, egg = "Grave", drop = "HollowNight",
		main = C(232, 118, 30), second = C(255, 190, 90), accent = C(30, 20, 10), glow = C(255, 150, 40), description = "Carved, lit, and following you home."},
	{id = "SkeletonCat", name = "Skeleton Cat", rarity = "Epic", body = "beast", style = "bones", size = 0.8, egg = "Grave", drop = "HollowNight",
		main = C(222, 214, 196), second = C(150, 144, 132), accent = C(120, 255, 170), glow = C(120, 255, 170), description = "Nine lives. Used all of them."},
	{id = "CryptRaven", name = "Crypt Raven", rarity = "Epic", body = "bird", size = 0.95, fx = "spirit", egg = "Grave", drop = "HollowNight",
		main = C(26, 24, 34), second = C(70, 50, 100), accent = C(190, 110, 255), description = "Nevermore. Mostly."},
	{id = "JackOWisp", name = "Jack o' Wisp", rarity = "Legendary", body = "wisp", style = "pumpkin", size = 1.05, fx = "embers", egg = "Grave", drop = "HollowNight",
		main = C(255, 120, 20), second = C(255, 210, 120), accent = C(20, 10, 4), glow = C(255, 120, 20), description = "The lantern that walks the Hollow Night."},
	{id = "WraithHound", name = "Wraith Hound", rarity = "Mythic", body = "beast", style = "bones", size = 1.1, fx = "spirit", egg = "Grave", drop = "HollowNight",
		main = C(60, 70, 80), second = C(30, 34, 40), accent = C(120, 255, 200), glow = C(120, 255, 200), description = "Hollow Night 2026. It never hatches again."},
	-- STAG EGG — The Wild Hunt
	{id = "BoarPiglet", name = "Boar Piglet", rarity = "Common", body = "beast", style = "tusks", size = 0.75, egg = "Stag", drop = "WildHunt",
		main = C(110, 80, 56), second = C(150, 116, 84), accent = C(240, 232, 214), description = "Snuffles truffles. Charges ankles."},
	{id = "Hawk", name = "Goshawk", rarity = "Rare", body = "bird", size = 0.95, egg = "Stag", drop = "WildHunt",
		main = C(96, 84, 72), second = C(220, 214, 200), accent = C(250, 196, 60), description = "Returns to the glove. Mostly yours."},
	{id = "Badger", name = "Badger", rarity = "Rare", body = "beast", style = "round", size = 0.8, egg = "Stag", drop = "WildHunt",
		main = C(70, 70, 76), second = C(236, 236, 236), accent = C(20, 20, 24), description = "Grumpy. Fearless. Correct."},
	{id = "Fawn", name = "Spotted Fawn", rarity = "Epic", body = "beast", style = "reindeer", size = 0.9, egg = "Stag", drop = "WildHunt",
		main = C(176, 120, 72), second = C(246, 236, 220), accent = C(120, 90, 60), description = "Wobbly legs, brave heart."},
	{id = "ElderStag", name = "Elder Stag", rarity = "Legendary", body = "beast", style = "antlers", size = 1.15, fx = "spirit", egg = "Stag", drop = "WildHunt",
		main = C(120, 96, 70), second = C(200, 186, 150), accent = C(30, 60, 30), glow = C(140, 255, 120), description = "Old as the Wildwood. The Hunt follows it."},
	-- FJORD EGG — Northmen
	{id = "Puffin", name = "Puffin", rarity = "Common", body = "bird", style = "walker", size = 0.75, egg = "Fjord", drop = "Northmen",
		main = C(28, 28, 34), second = C(246, 246, 246), accent = C(255, 120, 40), description = "A sea-parrot in a dinner jacket."},
	{id = "BearCub", name = "Bear Cub", rarity = "Rare", body = "beast", style = "round", size = 1.0, egg = "Fjord", drop = "Northmen",
		main = C(96, 66, 44), second = C(150, 112, 80), accent = C(20, 16, 14), description = "Rolls more than it walks."},
	{id = "NorthRaven", name = "Raven of the North", rarity = "Epic", body = "bird", size = 1.0, fx = "frost", egg = "Fjord", drop = "Northmen",
		main = C(60, 70, 90), second = C(120, 140, 170), accent = C(170, 220, 255), description = "Thought or Memory. It won't say which."},
	{id = "SeaSerpent", name = "Sea Serpent", rarity = "Legendary", body = "drake", size = 1.05, egg = "Fjord", drop = "Northmen",
		main = C(40, 120, 130), second = C(140, 220, 210), accent = C(232, 210, 120), glow = C(90, 255, 230), description = "Coiled under the longships. Now under your bed."},
	-- FROST EGG — Frostfall
	{id = "ArcticHare", name = "Arctic Hare", rarity = "Common", body = "hopper", style = "longears", size = 0.85, egg = "Frost", drop = "Frostfall",
		main = C(246, 248, 252), second = C(220, 230, 240), accent = C(30, 30, 40), description = "Invisible until it blinks."},
	{id = "SnowOwl", name = "Snow Owl", rarity = "Rare", body = "bird", style = "owl", size = 0.95, egg = "Frost", drop = "Frostfall",
		main = C(244, 246, 250), second = C(255, 255, 255), accent = C(255, 210, 60), description = "Silent wings, cold stare."},
	{id = "Stoat", name = "Winter Stoat", rarity = "Epic", body = "beast", size = 0.7, fx = "frost", egg = "Frost", drop = "Frostfall",
		main = C(246, 246, 250), second = C(255, 255, 255), accent = C(20, 20, 24), description = "Ermine for a king's collar. It disagrees."},
	{id = "IceDrake", name = "Ice Drake", rarity = "Legendary", body = "drake", size = 1.0, fx = "frost", egg = "Frost", drop = "Frostfall",
		main = C(180, 220, 250), second = C(230, 246, 255), accent = C(110, 170, 240), glow = C(150, 230, 255), description = "Breathes snow. Melts nothing."},
	-- YULE EGG — Yuletide
	{id = "Robin", name = "Robin", rarity = "Common", body = "bird", size = 0.75, egg = "Yule", drop = "Yuletide",
		main = C(120, 92, 70), second = C(230, 90, 50), accent = C(240, 190, 80), description = "First on the snow, loudest in the yard."},
	{id = "GingerHen", name = "Gingerbread Hen", rarity = "Rare", body = "bird", style = "walker", size = 0.95, egg = "Yule", drop = "Yuletide",
		main = C(176, 110, 60), second = C(250, 246, 240), accent = C(220, 40, 50), description = "Do not dunk."},
	{id = "Reindeer", name = "Reindeer Fawn", rarity = "Epic", body = "beast", style = "reindeer", size = 0.95, egg = "Yule", drop = "Yuletide",
		main = C(150, 104, 66), second = C(236, 224, 206), accent = C(110, 76, 50), glow = C(255, 40, 40), description = "That nose, though."},
	{id = "YuleWisp", name = "Yule Wisp", rarity = "Legendary", body = "wisp", size = 0.95, fx = "sparkle", egg = "Yule", drop = "Yuletide",
		main = C(60, 200, 90), second = C(220, 255, 230), accent = C(200, 30, 40), glow = C(90, 255, 120), description = "A candle from the Yule log that refused to go out."},
	{id = "Krampling", name = "Krampling", rarity = "Mythic", body = "drake", size = 0.9, fx = "embers", egg = "Yule", drop = "Yuletide",
		main = C(40, 26, 26), second = C(120, 20, 20), accent = C(230, 220, 200), glow = C(255, 50, 40), description = "Yuletide 2026. Naughty list only."},
	-- TIDE EGG — Black Sails
	{id = "Gull", name = "Harbour Gull", rarity = "Common", body = "bird", size = 0.85, egg = "Tide", drop = "BlackSails",
		main = C(236, 238, 242), second = C(170, 176, 186), accent = C(250, 200, 60), description = "Steals chips. Steals swords."},
	{id = "Parrot", name = "Parrot", rarity = "Rare", body = "bird", size = 0.9, egg = "Tide", drop = "BlackSails",
		main = C(220, 40, 40), second = C(50, 110, 230), accent = C(255, 210, 40), description = "Says one word. You won't like it."},
	{id = "KrakenPup", name = "Kraken Pup", rarity = "Epic", body = "wisp", style = "kraken", size = 0.9, egg = "Tide", drop = "BlackSails",
		main = C(110, 60, 140), second = C(170, 110, 200), accent = C(250, 220, 120), glow = C(200, 120, 255), description = "Eight arms, all of them hugs."},
	{id = "SeaDrake", name = "Sea Drake", rarity = "Legendary", body = "drake", size = 1.0, egg = "Tide", drop = "BlackSails",
		main = C(30, 90, 100), second = C(90, 200, 190), accent = C(200, 170, 90), glow = C(90, 255, 210), description = "Smells of salt and old treasure."},
}
