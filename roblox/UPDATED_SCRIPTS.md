# Updated scripts: the dungeons are dark now

- **Dark floors** (The Depths, Deadvault): low ambient light and close fog; torches throw pools of light on the walls with darkness between, and in a raid some have guttered out.
- **Your lantern**: every adventurer carries a warm light, so you see what's around you and not much more.
- **The air**: dust drifting through the light, colder colours per theme, darker screen edges.
- **The sounds of the dark**: a low drone; now and then a whisper, an iron clank or a deep thud somewhere behind or beside you.
- **Checked in Play** in the Bone Crypt (Deadvault): about 40 fps in Studio play, the mood costing ~3.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | dark lighting, pooled torches, guttered sconces |
| [README.md](README.md) | | doc | |

---

## Before that: duels in the middle of a battle (three new Lists maps)

- **Redmeadow, Ironvale, Grimfield** (The Lists, 1v1 to 3v3): a duel ring of painted pavises and planted spears in an open field where two whole armies fight all round you. Battle lines meet either side of the ring, archers behind it loose volleys right over your heads, battle-mages' fire crosses the sky, cavalry rides down a flank, wagons burn. The winners of a round cheer.
- **A new map layout** (`warfield` in MapForge): any map built with it gets the battle by itself.
- **Fixed**: leaving War (or the new maps) threw an error while stopping the drums, so some battle sounds and effects could keep going after you left.
- **Checked in Play**: all three maps, from inside the ring and from above, 52–56 fps in Studio play. Vote pictures shot with the battle running.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Warfield.client.lua](StarterPlayerScripts/Warfield.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [MapForge.lua](ServerScriptService/Build/MapForge.lua) | ServerScriptService ▸ Build | ModuleScript | warfield layout; Redmeadow, Ironvale, Grimfield |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | the maps in The Lists, titles, sizes, weather |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `lane()`: two lines fighting |
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | uses `lane()`; stops its loops cleanly |
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | stops its drums cleanly |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | |

Studio-only (save the place): ServerStorage ▸ Maps ▸ Redmeadow, Ironvale, Grimfield (built with `require(game.ServerScriptService.Build.Maps).build(name)`); ReplicatedStorage ▸ MapShots ▸ Redmeadow, Ironvale, Grimfield.

---

## Before that: the Siege is a real siege now

- **Defenders' archers line the castle walls** and loose on the field; the attackers' archers loose back.
- **Ladders against the walls** with men swarming up them under a block of raised shields: some go over the top and fight on the walk, some are thrown off.
- **Battles on both flanks** of the castle: the defenders' sally against the attackers' lines, with a charge, the crash, and fresh charges.
- **The castle burns**: towers on fire with smoke rising high, villages burning beyond, stones and fire falling on the towers and walls.
- **It follows the fight**: the gate falls → the attackers cheer, the wall archers are cut down, the ladders all go over, the reserves charge the walls; the great hall stormed → its roof catches fire; the winners cheer.
- **Fixed**: the "split arrow" power crashed its extra arrows (they left after the draw had ended), so they never flew. Fireballs that hit a roof no longer leave a burn mark hanging in the air.
- **Checked in Play** on Frostgate: from the spawn, from the wall, the gate breaking, the hall burning. About 45 fps in Studio play with 40 bots.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | describes the castle on the map |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | ladders, shields overhead, rout, men on walls |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | blasts without a burn mark |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat | ModuleScript | split-arrow fix |
| [README.md](README.md) | | doc | |
