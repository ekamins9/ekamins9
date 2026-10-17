# Updated scripts: torches in the night battles

- **At night the armies carry torches**: on night maps (Nightfall in War, the night castles in Siege, Ravenfield) the battle lines show as firelight in the dark.
- **Checked in Play** on Ravenfield: 52 torches, 52–58 fps in Studio play.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `torches`, `WarCrowd.night()` |
| [War.client.lua](StarterPlayerScripts/War.client.lua), [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua), [Warfield.client.lua](StarterPlayerScripts/Warfield.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | torches at night |
| [README.md](README.md) | | doc | |

---

## Before that: the armies answer your war cry

- **War Cry / Cheer in a battle**: your side's regiments nearby (within 140 studs) raise their weapons and roar back. Works in War, Siege, the warfields and anywhere the armies stand.
- **Checked in Play** on Redfield (War): the cry by the Crown's lines; 90 s soak with no errors.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | a rally on War Cry / Cheer |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `WarCrowd.answer` |
| [README.md](README.md) | | doc | |

---

## Before that: the monsters groan and growl in the dark

- **What lurks**: in the dungeons, monsters near you groan (the undead) or growl (everything else) now and then from where they stand, the big ones deeper. Two new generated sounds.
- **Siege**: once the fight is inside the walls, smoke from the burning castle drifts through the yard being fought over.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DungeonMood.client.lua](StarterPlayerScripts/DungeonMood.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | groans and growls |
| [SiegeEpic.client.lua](StarterPlayerScripts/SiegeEpic.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | smoke in the bailey |
| [README.md](README.md) | | doc | |

Studio-only (save the place): ReplicatedStorage ▸ WarAudio ▸ Groan, Growl.
