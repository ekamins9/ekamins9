# Updated scripts: the Siege ram has a crew

- **Six attackers under the ram's roof** walk it up the road with the players and lean into it when it stops; they cheer when the gate falls.
- **Checked in Play** on Emberkeep.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the ram's crew |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `crew`, `crewCheer` |
| [README.md](README.md) | | doc | |

---

## Before that: monsters take shape out of the dark

- **In the dungeons a monster fades in** from nothing to solid over most of a second as the grave-dust bursts up, instead of popping into view.
- **Checked in Play** in the Bone Crypt: a skeleton knight materialising; fully solid after.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the fade-in |
| [README.md](README.md) | | doc | |

---

## Before that: torches in the night battles

- **At night the armies carry torches**: on night maps (Nightfall in War, the night castles in Siege, Ravenfield) the battle lines show as firelight in the dark.
- **Checked in Play** on Ravenfield: 52 torches, 52–58 fps in Studio play.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `torches`, `WarCrowd.night()` |
| [War.client.lua](StarterPlayerScripts/War.client.lua), [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua), [Warfield.client.lua](StarterPlayerScripts/Warfield.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | torches at night |
| [README.md](README.md) | | doc | |
