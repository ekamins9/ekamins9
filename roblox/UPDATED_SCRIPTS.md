# Updated scripts: the armies answer your war cry

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

---

## Before that: War's armies stand deeper

- **Each army's host**: great blocks of men drawn up on the flanks by each camp (four blocks of 128), standing on the slopes properly (each man on the ground under him). They never march, so they cost nothing a frame after they're placed. About 20,400 crowd parts in War now; 42–48 fps in Studio play.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the hosts |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `still` regiments (each man on his own ground) |
| [README.md](README.md) | | doc | |
