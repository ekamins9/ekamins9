# Updated scripts: bosses make an entrance; monsters come out of the dark

- **A boss's entrance** (The Depths' lords): black bars close in, the HUD steps aside, the camera finds the boss and creeps towards it while its name comes up big, a deep boom and a shake; about three seconds, then back to you.
- **Monsters come out of the dark**: grave-dust bursts up where each one appears, and some of the dead whisper as they come.
- **Checked in Play** in the Bone Crypt with Malgrath, the Lich King: the shot, the title on the bars, the HUD back afterwards.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the boss's entrance |
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | monsters' arrival |
| [README.md](README.md) | | doc | |

---

## Before that: the weight of your swing, and the battle beyond every team fight

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
