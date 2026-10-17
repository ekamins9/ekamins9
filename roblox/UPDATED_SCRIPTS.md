# Updated scripts: the weight of your swing, and the battle beyond every team fight

- **Your swings have weight**: the view leans back as you draw a blow, then is dragged along the blade's path as it goes (a side swing turns and rolls it, an overhead nods it down, a stab punches in). Small, quick, and scaled by the Shake setting.
- **A bigger battle round every team fight** (Team Deathmatch, King of the Hill, Last Team Standing): smoke columns beyond the map's edge, the din of battle and an army's roar off to one side, volleys arcing high over the whole field, a trebuchet's fire streaking across, a distant horn.
- **Checked in Play** on Abbeyfield (TDM): the drag measured on the camera; the burning column on the horizon.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts | LocalScript | swing drag |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat | ModuleScript | marks wind-up and release |
| [BattleAmbience.client.lua](StarterPlayerScripts/BattleAmbience.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [README.md](README.md) | | doc | |

---

## Before that: the dungeons are dark now

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
