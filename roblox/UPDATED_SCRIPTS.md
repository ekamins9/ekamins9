# Updated scripts: Siege's champion and the Horde's Warlord make an entrance too

- **The boss entrance is shared** now (a module): the Depths' lords, Siege's champion on his throne ("JARL HROLF · THE CHAMPION OF FROSTGATE · SLAY HIM"), and the Horde's Warlord.
- **Checked in Play**: Siege on Frostgate, skipped to the last stage: the champion's shot and title.

| File | Studio location | Type | Change |
|---|---|---|---|
| [BossIntro.lua](ReplicatedStorage/BossIntro.lua) | ReplicatedStorage | ModuleScript | new (the entrance) |
| [BossEntrance.client.lua](StarterPlayerScripts/BossEntrance.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new (Siege, Horde) |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | uses the module |
| [README.md](README.md) | | doc | |

---

## Before that: bosses make an entrance; monsters come out of the dark

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
