# Updated scripts: the Prologue's Iron Host is a real army

- **The first thing a new player sees** is now an army: the Iron Host drawn up in the rain among its torches before Stormwatch (foot, pikes, knights, archers), the garrison's archers on the north walls. Volleys cut men down on both sides, the Host roars, closes on the gate as the story goes on, and at dawn turns and runs while the walls cheer.
- **Cleanup**: the old block-figure armies in WarFX (replaced by WarCrowd everywhere) are gone.
- **Checked in Play**: the Prologue's opening, from the walls and from over the Host.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Prologue.client.lua](StarterPlayerScripts/Prologue.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the Host and the garrison |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | old armies removed |
| [README.md](README.md) | | doc | |

---

## Before that: Siege's champion and the Horde's Warlord make an entrance too

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
